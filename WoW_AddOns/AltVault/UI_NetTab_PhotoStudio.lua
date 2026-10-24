-- ============================================================================
-- FILE: UI_NetTab_PhotoStudio.lua (MODULE 1 OF 2 FOR TAB 12 PHOTO ALBUM)
-- BLOCK HEADING: ALBUM DATA HELPERS, PIC VAULT PICKER & 20s VIDEO CROP STUDIO
-- ============================================================================
local addonName, ns = ...
local MainPanel = _G.AltVaultMainPanel
if not MainPanel then return end

ns.NetUI = ns.NetUI or {}
local NetUI = ns.NetUI
local Armory = ns.Armory or {}

local CreateBackdrop = (ns.Compat and ns.Compat.CreateBackdropFrame) or function(fType, fName, parent, extraTpl)
    if _G.BackdropTemplateMixin then
        local tpl = extraTpl and (extraTpl .. ", BackdropTemplate") or "BackdropTemplate"
        local ok, f = pcall(CreateFrame, fType, fName, parent, tpl)
        if ok and f then return f end
    end
    return CreateFrame(fType or "Frame", fName, parent, extraTpl)
end

local STANDARD_FONT = "Fonts\\FRIZQT__.TTF"
local MAX_FEATURED_SLOTS = 12
local MAX_REEL_SHEETS = 16
local SNAPSHOT_FOLDER = "Interface\\AddOns\\" .. tostring(addonName or "AltVault") .. "\\Snapshots\\"
local MASTER_ASPECT_RATIO = 1920 / 1009
local SYNC_MACRO_NAME = "AV_SlotSync"

NetUI.CreateBackdrop = CreateBackdrop
NetUI.STANDARD_FONT = STANDARD_FONT
NetUI.MAX_FEATURED_SLOTS = MAX_FEATURED_SLOTS
NetUI.MAX_REEL_SHEETS = MAX_REEL_SHEETS
NetUI.SNAPSHOT_FOLDER = SNAPSHOT_FOLDER
NetUI.MASTER_ASPECT_RATIO = MASTER_ASPECT_RATIO

NetUI.albumState = NetUI.albumState or {
    selectedSnapshotID = nil,
    viewFilter = "MY_ALBUM",
    lastCaptureTimestamp = 0,
    openEditorAfterNextShot = false,
    vaultTargetSlot = 1,
}

local function SanitizeCharacterTag(charName)
    local raw = tostring(charName or UnitName("player") or "Player")
    raw = string.gsub(raw, "%s+", "")
    raw = string.gsub(raw, "[^%w_%-]", "")
    if raw == "" then raw = "Player" end
    return raw
end

local function FormatCharacterSlotFilename(charName, fileSlotNum)
    local tag = SanitizeCharacterTag(charName)
    local n = math.max(1, math.min(MAX_FEATURED_SLOTS, tonumber(fileSlotNum) or 1))
    return string.format("%s_Slot%02d.tga", tag, n)
end

local function FormatCharacterSlotTexturePath(charName, fileSlotNum)
    local tag = SanitizeCharacterTag(charName)
    local n = math.max(1, math.min(MAX_FEATURED_SLOTS, tonumber(fileSlotNum) or 1))
    return SNAPSHOT_FOLDER .. string.format("%s_Slot%02d", tag, n)
end

NetUI.SanitizeCharacterTag = SanitizeCharacterTag
NetUI.FormatCharacterSlotFilename = FormatCharacterSlotFilename
NetUI.FormatCharacterSlotTexturePath = FormatCharacterSlotTexturePath

-- Writes AVSYNC|<CharTag>|1=1,2=0,3=5... to AV_SlotSync macro so the Companion's
-- [Sync In-Game Slots] button knows which slots were cleared or reassigned in-game!
local function WriteHelperSlotSyncMacro(charName)
    if InCombatLockdown() or not AltVaultDB or not charName then return end
    if not GetMacroIndexByName or not EditMacro or not CreateMacro then return end

    local tag = SanitizeCharacterTag(charName)
    local pairsList = {}
    for sIdx = 1, MAX_FEATURED_SLOTS do
        local key = string.format("%s_Slot%d", charName, sIdx)
        local snap = AltVaultDB.PhotoAlbum and AltVaultDB.PhotoAlbum[key]
        local isHidden = AltVaultDB.HiddenPhotoSlots and AltVaultDB.HiddenPhotoSlots[key]
        if isHidden or not snap or snap.cleared then
            table.insert(pairsList, sIdx .. "=0")
        else
            table.insert(pairsList, sIdx .. "=" .. tostring(tonumber(snap.fileSlot) or sIdx))
        end
    end

    local record = string.format("AVSYNC|%s|%s", tag, table.concat(pairsList, ","))
    local okIdx, idx = pcall(GetMacroIndexByName, SYNC_MACRO_NAME)
    if not okIdx then idx = 0 end

    local body = record
    if idx and idx > 0 and GetMacroInfo then
        local okInfo, _, _, oldBody = pcall(GetMacroInfo, idx)
        if okInfo and oldBody and oldBody ~= "" then
            local kept = {}
            for line in string.gmatch(oldBody, "[^\r\n]+") do
                if not string.find(line, "^AVSYNC|" .. tag .. "|") then
                    table.insert(kept, line)
                end
            end
            table.insert(kept, record)
            local candidate = table.concat(kept, "\n")
            if #candidate <= 250 then
                body = candidate
            end
        end
        pcall(EditMacro, idx, SYNC_MACRO_NAME, "INV_Misc_Note_01", body)
    else
        local numGlobal = GetNumMacros and GetNumMacros() or 0
        if numGlobal < 36 then
            pcall(CreateMacro, SYNC_MACRO_NAME, "INV_Misc_Note_01", body, nil)
        end
    end
end

local function EnsureCharacterAlbumSlotsPopulated(charName)
    if not AltVaultDB or not charName or charName == "" then return end
    AltVaultDB.PhotoAlbum = AltVaultDB.PhotoAlbum or {}
    AltVaultDB.CharacterAvatars = AltVaultDB.CharacterAvatars or {}
    AltVaultDB.HiddenPhotoSlots = AltVaultDB.HiddenPhotoSlots or {}

    local cData = AltVaultDB.Characters and AltVaultDB.Characters[charName]
    local savedProfileSnap = cData and cData.profileSnapshot

    for slotIdx = 1, MAX_FEATURED_SLOTS do
        local stdKey = string.format("%s_Slot%d", charName, slotIdx)
        if not AltVaultDB.HiddenPhotoSlots[stdKey] then
            local existing = AltVaultDB.PhotoAlbum[stdKey]
            if not existing or existing.author ~= charName then
                local fSlot = slotIdx
                local zm, px, py, sx = 100, 0, 0, 100
                local isFlip = false
                local rSheets = 15
                local pPong = false
                local rFps = 24
                local cap = string.format("%s Photo #%d", charName, slotIdx)

                if slotIdx == 1 and savedProfileSnap and savedProfileSnap.author == charName then
                    fSlot = tonumber(savedProfileSnap.fileSlot) or 1
                    zm = tonumber(savedProfileSnap.zoom) or 100
                    px = tonumber(savedProfileSnap.panX) or 0
                    py = tonumber(savedProfileSnap.panY) or 0
                    sx = tonumber(savedProfileSnap.stretchX) or 100
                    isFlip = savedProfileSnap.isFlipbook and true or false
                    rSheets = math.max(1, math.min(MAX_REEL_SHEETS, tonumber(savedProfileSnap.reelSheets) or 15))
                    if savedProfileSnap.pingPong ~= nil then
                        pPong = savedProfileSnap.pingPong and true or false
                    end
                    rFps = tonumber(savedProfileSnap.fps) or 24
                    cap = savedProfileSnap.caption or cap
                end

                AltVaultDB.PhotoAlbum[stdKey] = {
                    id = stdKey,
                    author = charName,
                    slotIndex = slotIdx,
                    fileSlot = fSlot,
                    canvasFile = FormatCharacterSlotFilename(charName, fSlot),
                    filePath = FormatCharacterSlotTexturePath(charName, fSlot),
                    zone = "Azeroth",
                    timestamp = time(),
                    zoom = zm,
                    panX = px,
                    panY = py,
                    stretchX = sx,
                    isFlipbook = isFlip,
                    reelSheets = rSheets,
                    pingPong = pPong,
                    fps = rFps,
                    cleared = false,
                    locked = true,
                    votes = 0,
                    voters = {},
                    caption = cap,
                }
            else
                local fSlot = math.max(1, math.min(MAX_FEATURED_SLOTS, tonumber(existing.fileSlot) or slotIdx))
                existing.author = charName
                existing.slotIndex = slotIdx
                existing.fileSlot = fSlot
                existing.canvasFile = FormatCharacterSlotFilename(charName, fSlot)
                existing.filePath = FormatCharacterSlotTexturePath(charName, fSlot)
                if existing.pingPong == nil then existing.pingPong = false end
                existing.reelSheets = math.max(1, math.min(MAX_REEL_SHEETS, tonumber(existing.reelSheets) or 15))
                existing.fps = math.max(8, math.min(60, tonumber(existing.fps) or 24))
            end
        end
    end

    local curAv = AltVaultDB.CharacterAvatars[charName]
    if not curAv or not AltVaultDB.PhotoAlbum[curAv] or AltVaultDB.PhotoAlbum[curAv].author ~= charName then
        AltVaultDB.CharacterAvatars[charName] = string.format("%s_Slot1", charName)
    end
end

local function SaveCharacterSlotsToCharacterTable(charName)
    if not AltVaultDB or not charName then return end
    local cData = AltVaultDB.Characters and AltVaultDB.Characters[charName]
    if cData then
        local avID = AltVaultDB.CharacterAvatars and AltVaultDB.CharacterAvatars[charName]
        if avID and AltVaultDB.PhotoAlbum and AltVaultDB.PhotoAlbum[avID] then
            cData.profileSnapshot = AltVaultDB.PhotoAlbum[avID]
        end
    end
    WriteHelperSlotSyncMacro(charName)
    if ns.DB and ns.DB.SaveToBetaMacro then
        pcall(ns.DB.SaveToBetaMacro)
    end
end

local function EnsureAlbumTables()
    if not AltVaultDB then return false end
    AltVaultDB.PhotoAlbum = AltVaultDB.PhotoAlbum or {}
    AltVaultDB.CharacterAvatars = AltVaultDB.CharacterAvatars or {}
    AltVaultDB.PhotoVotes = AltVaultDB.PhotoVotes or {}
    AltVaultDB.HiddenPhotoSlots = AltVaultDB.HiddenPhotoSlots or {}
    if AltVaultDB.Characters then
        for cName, _ in pairs(AltVaultDB.Characters) do
            EnsureCharacterAlbumSlotsPopulated(cName)
        end
    end
    return true
end

NetUI.WriteHelperSlotSyncMacro = WriteHelperSlotSyncMacro
NetUI.EnsureCharacterAlbumSlotsPopulated = EnsureCharacterAlbumSlotsPopulated
NetUI.SaveCharacterSlotsToCharacterTable = SaveCharacterSlotsToCharacterTable
NetUI.EnsureAlbumTables = EnsureAlbumTables

function NetUI.HidePhotoAlbumFrames()
    if NetUI.AlbumCanvas and MainPanel:GetActiveViewMode() ~= "PHOTO_ALBUM" then
        NetUI.AlbumCanvas:Hide()
    end
    if NetUI.PicVaultPickerFrame then
        NetUI.PicVaultPickerFrame:Hide()
    end
end

MainPanel:HookScript("OnHide", function()
    if NetUI.PhotoEditFlyout then NetUI.PhotoEditFlyout:Hide() end
    if NetUI.PicVaultPickerFrame then NetUI.PicVaultPickerFrame:Hide() end
    if _G.AltVaultPoseDropdownMenu then _G.AltVaultPoseDropdownMenu:Hide() end
end)

-- ============================================================================
-- BLOCK HEADING: OPTION A — PRELOADED 16-SHEET GPU TEXTURE STACK BRIDGES
-- ============================================================================
local function EnsureStack(parentFrame, primaryTex, insetPx)
    if Armory.EnsureTextureStack then
        return Armory.EnsureTextureStack(parentFrame, primaryTex, insetPx)
    end
    if primaryTex.avSheetStack then return primaryTex.avSheetStack end
    local stack = { [1] = primaryTex }
    local ins = tonumber(insetPx) or 0
    for s = 2, MAX_REEL_SHEETS do
        local t = parentFrame:CreateTexture(nil, "ARTWORK")
        if ins > 0 then
            t:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", ins, -ins)
            t:SetPoint("BOTTOMRIGHT", parentFrame, "BOTTOMRIGHT", -ins, ins)
        else
            t:SetAllPoints(primaryTex)
        end
        t:SetAlpha(0)
        stack[s] = t
    end
    primaryTex.avSheetStack = stack
    return stack
end

local function ResolveGlobalFlipFrame(snap)
    if Armory.ResolveFlipbookGlobalFrameIndex then
        return Armory.ResolveFlipbookGlobalFrameIndex(snap)
    end
    local numSheets = math.max(1, math.min(MAX_REEL_SHEETS, tonumber(snap and snap.reelSheets) or 15))
    local totalFrames = numSheets * 32
    local fps = math.max(8, math.min(60, tonumber(snap and snap.fps) or 24))
    local now = (GetTime and GetTime()) or 0
    if snap and snap.pingPong and totalFrames > 2 then
        local span = (totalFrames - 1) * 2
        local cycle = math.floor((now * fps) % span)
        return (cycle < totalFrames) and cycle or (span - cycle)
    end
    return math.floor((now * fps) % totalFrames)
end

local function Apply2DCrop(primaryTex, snap, explicitGlobalFrame)
    if Armory.Apply2DCropAndZoomToTexture then
        Armory.Apply2DCropAndZoomToTexture(primaryTex, snap, explicitGlobalFrame)
        return
    end
end

local function Load2DScreenshotIntoTexture(texWidget, snap)
    if not texWidget then return end
    if snap and not snap.cleared then
        local fSlot = tonumber(snap.fileSlot) or tonumber(snap.slotIndex) or 1
        snap.fileSlot = fSlot
        snap.canvasFile = FormatCharacterSlotFilename(snap.author, fSlot)
        snap.filePath = FormatCharacterSlotTexturePath(snap.author, fSlot)
    end
    if Armory.PreloadTextureStackForSnap then
        Armory.PreloadTextureStackForSnap(texWidget, snap)
    end
    Apply2DCrop(texWidget, snap)
end

NetUI.EnsureStack = EnsureStack
NetUI.ResolveGlobalFlipFrame = ResolveGlobalFlipFrame
NetUI.Apply2DCrop = Apply2DCrop
NetUI.Load2DScreenshotIntoTexture = Load2DScreenshotIntoTexture

-- ============================================================================
-- BLOCK HEADING: CLEAR SLOT IN-GAME & 1-VOTE-PER-PHOTO COMPETITION ENGINE
-- ============================================================================
local function ClearAlbumSlotInGame(charName, slotIdx)
    if not EnsureAlbumTables() or not charName then return end
    local sIdx = math.max(1, math.min(MAX_FEATURED_SLOTS, tonumber(slotIdx) or 1))
    local key = string.format("%s_Slot%d", charName, sIdx)
    AltVaultDB.HiddenPhotoSlots[key] = true
    if AltVaultDB.PhotoAlbum[key] then
        AltVaultDB.PhotoAlbum[key].cleared = true
        AltVaultDB.PhotoAlbum[key].isFlipbook = false
    end
    SaveCharacterSlotsToCharacterTable(charName)
    print(string.format("|cffff8800[AltVault Album]:|r Cleared %s's Slot #%d! Click another picture in [Pic Vault] to load into Slot #%d, or click [Sync In-Game Slots] in the Helper!",
        charName, sIdx, sIdx))
    if MainPanel:IsShown() then
        if MainPanel:GetActiveViewMode() == "PHOTO_ALBUM" and NetUI.RenderPhotoAlbumTab then
            NetUI.RenderPhotoAlbumTab(MainPanel)
        elseif not (Armory.state and Armory.state.isFullScreenStage) then
            MainPanel:RenderActivePane()
        end
    end
end

local function GetPhotoVoteSummary(photoID)
    if not EnsureAlbumTables() or not photoID then return 0, false end
    local snap = AltVaultDB.PhotoAlbum[photoID]
    local voterMap = AltVaultDB.PhotoVotes[photoID] or (snap and snap.voters) or {}
    local count = 0
    local myVote = false
    local curPlayer = UnitName("player")
    local myChars = AltVaultDB.Characters or {}

    for voterName, val in pairs(voterMap) do
        if val == true or val == 1 then
            count = count + 1
            if voterName == curPlayer or myChars[voterName] then
                myVote = true
            end
        end
    end
    if snap and (snap.votes or 0) > count then
        count = snap.votes
    end
    return count, myVote
end

if ns.GuildNet then
    ns.GuildNet.GetPhotoVoteCount = function(photoID)
        local cnt = GetPhotoVoteSummary(photoID)
        return cnt
    end
end

local function SendMeshPhotoPacket(pkt)
    if not pkt or #pkt > 248 or not ns.GuildNet then return end
    if ns.GuildNet.DispatchMeshPacket then
        ns.GuildNet.DispatchMeshPacket(pkt)
        return
    end
    if ns.GuildNet.EnqueuePacket then
        ns.GuildNet.EnqueuePacket(pkt)
        local playerName = UnitName("player")
        local faction = UnitFactionGroup("player") or "Alliance"
        for peerName, peerData in pairs((AltVaultDB and AltVaultDB.GuildNetwork) or {}) do
            if peerName ~= playerName and not (AltVaultDB.Characters and AltVaultDB.Characters[peerName]) then
                if not peerData.faction or peerData.faction == faction then
                    if peerData.isOnline ~= false then
                        ns.GuildNet.EnqueuePacket(pkt, "WHISPER", peerName)
                    end
                end
            end
        end
    end
end

local function BroadcastSnapshotToGuild(snap, isAvatar)
    if not snap or snap.cleared or not ns.GuildNet then return end
    local cleanCap = string.gsub(snap.caption or "Screenshot", "[|~]", " ")
    local cleanZone = string.gsub(snap.zone or "Azeroth", "[|~]", " ")
    local avFlag = isAvatar and "1" or "0"
    local rSheets = math.max(1, math.min(MAX_REEL_SHEETS, tonumber(snap.reelSheets) or 15))
    local flipFlag = snap.isFlipbook and string.format("%d:%d", rSheets, tonumber(snap.fps) or 24) or "0"
    local pkt = string.format("PSNAP|%s|%s|%d|%d|%d|%d|%d|%s|%s|%s|%s",
        snap.id,
        snap.author or "Player",
        snap.slotIndex or 1,
        snap.fileSlot or snap.slotIndex or 1,
        snap.zoom or 100,
        snap.panX or 0,
        snap.panY or 0,
        avFlag,
        cleanZone,
        cleanCap,
        flipFlag
    )
    SendMeshPhotoPacket(pkt)
end

local function CastPhotoCompetitionVote(photoID)
    if not EnsureAlbumTables() or not photoID then return end
    local snap = AltVaultDB.PhotoAlbum[photoID]
    if not snap then return end

    local voter = UnitName("player") or "Unknown"
    if snap.author == voter or (AltVaultDB.Characters and AltVaultDB.Characters[snap.author]) then
        print("|cffffcc00[AltVault Photo Competition]:|r You cannot vote on your own photos!")
        return
    end

    local _, alreadyVoted = GetPhotoVoteSummary(photoID)
    if alreadyVoted then
        print("|cffffcc00[AltVault Photo Competition]:|r You have already cast your 1 permanent vote for this photo!")
        return
    end

    AltVaultDB.PhotoVotes[photoID] = AltVaultDB.PhotoVotes[photoID] or {}
    AltVaultDB.PhotoVotes[photoID][voter] = 1
    snap.voters = AltVaultDB.PhotoVotes[photoID]
    snap.votes = GetPhotoVoteSummary(photoID)

    SendMeshPhotoPacket(string.format("PVOTE|%s|%s", photoID, voter))
    if PlaySound then pcall(PlaySound, 856) end
    print(string.format("|cff00ff00[AltVault Photo Competition]:|r Cast your +1 vote for |cffffff00%s|r's photo!", snap.author or "Player"))
    if MainPanel:IsShown() and MainPanel:GetActiveViewMode() == "PHOTO_ALBUM" and NetUI.RenderPhotoAlbumTab then
        NetUI.RenderPhotoAlbumTab(MainPanel)
    end
end

NetUI.ClearAlbumSlotInGame = ClearAlbumSlotInGame
NetUI.GetPhotoVoteSummary = GetPhotoVoteSummary
NetUI.BroadcastSnapshotToGuild = BroadcastSnapshotToGuild
NetUI.CastPhotoCompetitionVote = CastPhotoCompetitionVote

-- ============================================================================
-- BLOCK HEADING: WORKING IN-GAME PERSONAL PIC VAULT WITH 1-12 SLOT SELECTOR!
-- ============================================================================
local OpenPhotoEditFlyout -- forward declaration

local function OpenPersonalPicVaultPicker(targetCharName, targetAlbumSlot)
    EnsureAlbumTables()
    local charName = targetCharName or MainPanel:GetSelectedSyncedPeer() or MainPanel:GetSelectedCharacter() or UnitName("player")
    EnsureCharacterAlbumSlotsPopulated(charName)

    if targetAlbumSlot and tonumber(targetAlbumSlot) then
        NetUI.albumState.vaultTargetSlot = math.max(1, math.min(MAX_FEATURED_SLOTS, tonumber(targetAlbumSlot)))
    end
    local activeTargetSlot = NetUI.albumState.vaultTargetSlot or 1

    if not NetUI.PicVaultPickerFrame then
        local vf = CreateBackdrop("Frame", "AltVaultPersonalPicVaultPicker", UIParent)
        vf:SetSize(650, 535)
        vf:SetPoint("CENTER", UIParent, "CENTER", 0, 20)
        vf:SetFrameStrata("FULLSCREEN_DIALOG")
        vf:SetFrameLevel(260)
        vf:SetToplevel(true)
        vf:EnableMouse(true)
        vf:SetMovable(true)
        vf:SetClampedToScreen(true)
        vf:RegisterForDrag("LeftButton")
        vf:SetScript("OnDragStart", function(self) self:Raise(); self:StartMoving() end)
        vf:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

        if vf.SetBackdrop then
            vf:SetBackdrop({
                bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
                edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
                tile = true, tileSize = 32, edgeSize = 24,
                insets = { left = 5, right = 5, top = 5, bottom = 5 }
            })
            vf:SetBackdropColor(0.03, 0.04, 0.08, 0.98)
        end
        NetUI.PicVaultPickerFrame = vf

        vf.CloseBtn = CreateFrame("Button", nil, vf, "UIPanelCloseButton")
        vf.CloseBtn:SetPoint("TOPRIGHT", vf, "TOPRIGHT", -4, -4)

        vf.Title = vf:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        vf.Title:SetPoint("TOP", vf, "TOP", 0, -12)
        vf.Title:SetFont(STANDARD_FONT, 15, "OUTLINE")

        vf.SlotBarTitle = vf:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        vf.SlotBarTitle:SetPoint("TOPLEFT", vf, "TOPLEFT", 18, -36)
        vf.SlotBarTitle:SetFont(STANDARD_FONT, 11, "OUTLINE")
        vf.SlotBarTitle:SetText("|cffffd1001. Choose Target Album Slot (1-12):|r")

        vf.ClearTargetSlotBtn = CreateFrame("Button", nil, vf, "UIPanelButtonTemplate")
        vf.ClearTargetSlotBtn:SetSize(165, 22)
        vf.ClearTargetSlotBtn:SetPoint("TOPRIGHT", vf, "TOPRIGHT", -18, -33)
        vf.ClearTargetSlotBtn:SetText("|cffff5555Clear Target Slot|r")
        if vf.ClearTargetSlotBtn:GetFontString() then
            vf.ClearTargetSlotBtn:GetFontString():SetFont(STANDARD_FONT, 10, "OUTLINE")
        end

        vf.SlotSelectorBtns = {}
        for s = 1, 12 do
            local sb = CreateFrame("Button", nil, vf, "UIPanelButtonTemplate")
            sb:SetSize(48, 24)
            sb:SetPoint("TOPLEFT", vf, "TOPLEFT", 18 + (s - 1) * 51, -56)
            sb:SetText("Slot " .. s)
            if sb:GetFontString() then sb:GetFontString():SetFont(STANDARD_FONT, 10, "OUTLINE") end
            local slotNum = s
            sb:SetScript("OnClick", function()
                NetUI.albumState.vaultTargetSlot = slotNum
                OpenPersonalPicVaultPicker(vf.activeChar, slotNum)
            end)
            vf.SlotSelectorBtns[s] = sb
        end

        vf.SubTitle = vf:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        vf.SubTitle:SetPoint("TOPLEFT", vf, "TOPLEFT", 18, -84)
        vf.SubTitle:SetFont(STANDARD_FONT, 11, "OUTLINE")

        vf.Cells = {}
        local cols = 4
        local cellW, cellH = 148, 128
        for i = 1, 12 do
            local cell = CreateBackdrop("Button", nil, vf)
            local r = math.floor((i - 1) / cols)
            local c = (i - 1) % cols
            cell:SetSize(cellW, cellH)
            cell:SetPoint("TOPLEFT", vf, "TOPLEFT", 18 + c * (cellW + 7), -104 - r * (cellH + 8))
            if cell.SetBackdrop then
                cell:SetBackdrop({
                    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
                    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                    tile = true, tileSize = 16, edgeSize = 12,
                    insets = { left = 2, right = 2, top = 2, bottom = 2 }
                })
                cell:SetBackdropColor(0.05, 0.07, 0.12, 0.95)
            end

            cell.Label = cell:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            cell.Label:SetPoint("TOP", cell, "TOP", 0, -5)
            cell.Label:SetFont(STANDARD_FONT, 10, "OUTLINE")

            cell.Tex = cell:CreateTexture(nil, "ARTWORK")
            cell.Tex:SetSize(135, 71)
            cell.Tex:SetPoint("TOP", cell, "TOP", 0, -20)

            cell.SelectBtn = CreateFrame("Button", nil, cell, "UIPanelButtonTemplate")
            cell.SelectBtn:SetSize(78, 22)
            cell.SelectBtn:SetPoint("BOTTOMLEFT", cell, "BOTTOMLEFT", 5, 5)
            if cell.SelectBtn:GetFontString() then cell.SelectBtn:GetFontString():SetFont(STANDARD_FONT, 10, "OUTLINE") end

            cell.Tab1QuickBtn = CreateFrame("Button", nil, cell, "UIPanelButtonTemplate")
            cell.Tab1QuickBtn:SetSize(56, 22)
            cell.Tab1QuickBtn:SetPoint("BOTTOMRIGHT", cell, "BOTTOMRIGHT", -5, 5)
            cell.Tab1QuickBtn:SetText("|cffffd100Tab 1|r")
            if cell.Tab1QuickBtn:GetFontString() then cell.Tab1QuickBtn:GetFontString():SetFont(STANDARD_FONT, 10, "OUTLINE") end

            vf.Cells[i] = cell
        end
    end

    local vf = NetUI.PicVaultPickerFrame
    vf.activeChar = charName
    vf.targetSlot = activeTargetSlot
    vf.Title:SetText(string.format("|cffffd100%s's In-Game Pic Vault & Slot Manager|r", charName))
    vf.SubTitle:SetText(string.format("|cff00ff962. Click [-> Slot #%d] below on ANY stored .TGA file to load it into %s's Album Slot #%d:|r",
        activeTargetSlot, charName, activeTargetSlot))

    vf.ClearTargetSlotBtn:SetText(string.format("|cffff5555Clear Album Slot #%d|r", activeTargetSlot))
    vf.ClearTargetSlotBtn:SetScript("OnClick", function()
        ClearAlbumSlotInGame(charName, activeTargetSlot)
    end)

    for s = 1, 12 do
        local sb = vf.SlotSelectorBtns[s]
        if s == activeTargetSlot then
            sb:LockHighlight()
            sb:SetText("|cff00ff00#" .. s .. "|r")
        else
            sb:UnlockHighlight()
            sb:SetText("Slot " .. s)
        end
    end

    for i = 1, 12 do
        local cell = vf.Cells[i]
        local fName = FormatCharacterSlotFilename(charName, i)
        local fPath = FormatCharacterSlotTexturePath(charName, i)
        local slotKey = string.format("%s_Slot%d", charName, i)
        local existingSnap = AltVaultDB.PhotoAlbum[slotKey]

        cell.Label:SetText("|cffffff00File #" .. i .. ": " .. fName .. "|r")
        cell.Tex:SetTexture(fPath)
        if existingSnap and existingSnap.isFlipbook then
            cell.Tex:SetTexCoord(0, 0.25, 0, 0.125)
        else
            Apply2DCrop(cell.Tex, existingSnap, 0)
        end

        local fileIdx = i
        local destSlot = activeTargetSlot
        cell.SelectBtn:SetText(string.format("|cff00ff00-> Slot #%d|r", destSlot))
        cell.SelectBtn:SetScript("OnClick", function()
            local newID = NetUI.CaptureCharacterSnapshot and NetUI.CaptureCharacterSnapshot("VAULT_PICKER", charName, destSlot, fileIdx)
            if newID and OpenPhotoEditFlyout then
                OpenPhotoEditFlyout(newID)
            end
        end)

        cell.Tab1QuickBtn:SetScript("OnClick", function()
            local newID = NetUI.CaptureCharacterSnapshot and NetUI.CaptureCharacterSnapshot("VAULT_PICKER", charName, destSlot, fileIdx)
            if newID and NetUI.SetAsOfflineAvatar then
                NetUI.SetAsOfflineAvatar(newID, charName)
            end
        end)
    end

    vf:Show()
    vf:Raise()
end

NetUI.OpenPersonalPicVaultPicker = OpenPersonalPicVaultPicker

-- ============================================================================
-- BLOCK HEADING: 1920x1009 PRELOADED 16-SHEET GPU STACK 20s VIDEO STUDIO
-- ============================================================================
local function RefreshLiveGalleryCardForSnapshot(snapID)
    local snap = snapID and AltVaultDB and AltVaultDB.PhotoAlbum and AltVaultDB.PhotoAlbum[snapID]
    if snap then
        SaveCharacterSlotsToCharacterTable(snap.author)
    end
    if not NetUI.AlbumCanvas or not NetUI.AlbumCanvas:IsShown() or not NetUI.AlbumCanvas.Cards or not snap then return end
    for _, card in ipairs(NetUI.AlbumCanvas.Cards) do
        if card:IsShown() and card.snapID == snapID then
            Load2DScreenshotIntoTexture(card.PhotoTex, snap)
            local votes = GetPhotoVoteSummary(snap.id)
            local lockIcon = snap.locked and "|cffffd100[🔒]|r " or ""
            local nSheets = tonumber(snap.reelSheets) or 15
            local flipIcon = snap.isFlipbook and string.format("|cff00ff96[🎬 %dS %dFPS]|r ", nSheets, tonumber(snap.fps) or 24) or ""
            card.CapFS:SetText(string.format("%s%s\"%s\" |cff88ccff[%s]|r |cffffd100(★ %d)|r",
                lockIcon, flipIcon, snap.caption or "Photo", snap.canvasFile or "Slot01", votes))
        end
    end
end

NetUI.RefreshLiveGalleryCardForSnapshot = RefreshLiveGalleryCardForSnapshot

local function UpdateFloatingEditorLayout(fly)
    if not fly then return end
    local w = fly:GetWidth() or 486
    local pad = 16
    local innerW = math.max(300, w - (pad * 2))
    local viewBoxH = math.floor((innerW / MASTER_ASPECT_RATIO) + 0.5)
    local requiredTotalH = viewBoxH + 365
    if math.abs((fly:GetHeight() or 0) - requiredTotalH) > 4 then
        fly:SetHeight(requiredTotalH)
    end

    fly.ViewBox:SetSize(innerW, viewBoxH)
    fly.ViewBox:ClearAllPoints()
    fly.ViewBox:SetPoint("TOP", fly, "TOP", 0, -38)

    local thirdW = math.floor((innerW - 10) / 3)
    local fourthW = math.floor((innerW - 15) / 4)

    fly.ZoomInBtn:SetSize(thirdW, 24)
    fly.ZoomInBtn:ClearAllPoints()
    fly.ZoomInBtn:SetPoint("TOPLEFT", fly.ViewBox, "BOTTOMLEFT", 0, -22)

    fly.ZoomOutBtn:SetSize(thirdW, 24)
    fly.ZoomOutBtn:ClearAllPoints()
    fly.ZoomOutBtn:SetPoint("LEFT", fly.ZoomInBtn, "RIGHT", 5, 0)

    fly.ResetBtn:SetSize(thirdW, 24)
    fly.ResetBtn:ClearAllPoints()
    fly.ResetBtn:SetPoint("LEFT", fly.ZoomOutBtn, "RIGHT", 5, 0)

    fly.PanLeftBtn:SetSize(fourthW, 24)
    fly.PanLeftBtn:ClearAllPoints()
    fly.PanLeftBtn:SetPoint("TOPLEFT", fly.ZoomInBtn, "BOTTOMLEFT", 0, -5)

    fly.PanRightBtn:SetSize(fourthW, 24)
    fly.PanRightBtn:ClearAllPoints()
    fly.PanRightBtn:SetPoint("LEFT", fly.PanLeftBtn, "RIGHT", 5, 0)

    fly.PanUpBtn:SetSize(fourthW, 24)
    fly.PanUpBtn:ClearAllPoints()
    fly.PanUpBtn:SetPoint("LEFT", fly.PanRightBtn, "RIGHT", 5, 0)

    fly.PanDownBtn:SetSize(fourthW, 24)
    fly.PanDownBtn:ClearAllPoints()
    fly.PanDownBtn:SetPoint("LEFT", fly.PanUpBtn, "RIGHT", 5, 0)

    fly.NarrowBtn:SetSize(thirdW, 24)
    fly.NarrowBtn:ClearAllPoints()
    fly.NarrowBtn:SetPoint("TOPLEFT", fly.PanLeftBtn, "BOTTOMLEFT", 0, -5)

    fly.SquareLockBtn:SetSize(thirdW, 24)
    fly.SquareLockBtn:ClearAllPoints()
    fly.SquareLockBtn:SetPoint("LEFT", fly.NarrowBtn, "RIGHT", 5, 0)

    fly.WidenBtn:SetSize(thirdW, 24)
    fly.WidenBtn:ClearAllPoints()
    fly.WidenBtn:SetPoint("LEFT", fly.SquareLockBtn, "RIGHT", 5, 0)

    fly.PrevCanvasBtn:SetSize(thirdW, 24)
    fly.PrevCanvasBtn:ClearAllPoints()
    fly.PrevCanvasBtn:SetPoint("TOPLEFT", fly.NarrowBtn, "BOTTOMLEFT", 0, -5)

    fly.CanvasLabelBtn:SetSize(thirdW, 24)
    fly.CanvasLabelBtn:ClearAllPoints()
    fly.CanvasLabelBtn:SetPoint("LEFT", fly.PrevCanvasBtn, "RIGHT", 5, 0)

    fly.NextCanvasBtn:SetSize(thirdW, 24)
    fly.NextCanvasBtn:ClearAllPoints()
    fly.NextCanvasBtn:SetPoint("LEFT", fly.CanvasLabelBtn, "RIGHT", 5, 0)

    -- Video Row 1: [Video: OFF / ON] [Loop: 1..N / Ping-Pong] [Sheets -] [Sheets +]
    fly.FlipbookBtn:SetSize(fourthW, 24)
    fly.FlipbookBtn:ClearAllPoints()
    fly.FlipbookBtn:SetPoint("TOPLEFT", fly.PrevCanvasBtn, "BOTTOMLEFT", 0, -5)

    fly.PingPongBtn:SetSize(fourthW, 24)
    fly.PingPongBtn:ClearAllPoints()
    fly.PingPongBtn:SetPoint("LEFT", fly.FlipbookBtn, "RIGHT", 5, 0)

    fly.SheetMinusBtn:SetSize(fourthW, 24)
    fly.SheetMinusBtn:ClearAllPoints()
    fly.SheetMinusBtn:SetPoint("LEFT", fly.PingPongBtn, "RIGHT", 5, 0)

    fly.SheetPlusBtn:SetSize(fourthW, 24)
    fly.SheetPlusBtn:ClearAllPoints()
    fly.SheetPlusBtn:SetPoint("LEFT", fly.SheetMinusBtn, "RIGHT", 5, 0)

    -- Video Row 2: [FPS -] [FPS +] + Duration Status
    fly.FpsMinusBtn:SetSize(thirdW, 24)
    fly.FpsMinusBtn:ClearAllPoints()
    fly.FpsMinusBtn:SetPoint("TOPLEFT", fly.FlipbookBtn, "BOTTOMLEFT", 0, -5)

    fly.FpsPlusBtn:SetSize(thirdW, 24)
    fly.FpsPlusBtn:ClearAllPoints()
    fly.FpsPlusBtn:SetPoint("LEFT", fly.FpsMinusBtn, "RIGHT", 5, 0)

    fly.DurationBtn:SetSize(thirdW, 24)
    fly.DurationBtn:ClearAllPoints()
    fly.DurationBtn:SetPoint("LEFT", fly.FpsPlusBtn, "RIGHT", 5, 0)

    local saveW = 92
    fly.CapBox:SetSize(math.max(120, innerW - saveW - 10), 24)
    fly.CapBox:ClearAllPoints()
    fly.CapBox:SetPoint("TOPLEFT", fly.FpsMinusBtn, "BOTTOMLEFT", 4, -7)

    fly.SaveTitleBtn:SetSize(saveW, 24)
    fly.SaveTitleBtn:ClearAllPoints()
    fly.SaveTitleBtn:SetPoint("LEFT", fly.CapBox, "RIGHT", 6, 0)

    fly.Tab1Btn:SetSize(thirdW, 28)
    fly.Tab1Btn:ClearAllPoints()
    fly.Tab1Btn:SetPoint("TOPLEFT", fly.FpsMinusBtn, "BOTTOMLEFT", 0, -37)

    fly.LockSlotBtn:SetSize(thirdW, 28)
    fly.LockSlotBtn:ClearAllPoints()
    fly.LockSlotBtn:SetPoint("LEFT", fly.Tab1Btn, "RIGHT", 5, 0)

    fly.DeleteBtn:SetSize(thirdW, 28)
    fly.DeleteBtn:ClearAllPoints()
    fly.DeleteBtn:SetPoint("LEFT", fly.LockSlotBtn, "RIGHT", 5, 0)

    local s = AltVaultDB and AltVaultDB.PhotoAlbum and AltVaultDB.PhotoAlbum[NetUI.albumState.selectedSnapshotID]
    if s then
        Apply2DCrop(fly.PreviewTex, s)
    end
end

local function UpdateFlyoutVideoButtons(fly, snap)
    if not fly or not snap then return end
    local nSheets = math.max(1, math.min(MAX_REEL_SHEETS, tonumber(snap.reelSheets) or 15))
    local fps = math.max(8, math.min(60, tonumber(snap.fps) or 24))
    local totalFrames = nSheets * 32
    local sec = totalFrames / fps
    if not snap.isFlipbook then
        fly.FlipbookBtn:SetText("|cffaaaaaa🎬 Video: OFF|r")
    else
        fly.FlipbookBtn:SetText("|cff00ff96🎬 Video: ON|r")
    end
    fly.PingPongBtn:SetText(snap.pingPong and "|cff00ff96↔ Ping-Pong|r" or "|cffffd100↻ Loop 1-" .. totalFrames .. "|r")
    fly.SheetMinusBtn:SetText(string.format("Sheets - (%d)", nSheets))
    fly.SheetPlusBtn:SetText(string.format("Sheets + (%d)", nSheets))
    fly.FpsMinusBtn:SetText(string.format("FPS - (%d)", fps))
    fly.FpsPlusBtn:SetText(string.format("FPS + (%d)", fps))
    fly.DurationBtn:SetText(string.format("|cff88ccff%df = %.1fs|r", totalFrames, sec))
end

OpenPhotoEditFlyout = function(snapID)
    if not EnsureAlbumTables() or not snapID or not AltVaultDB.PhotoAlbum[snapID] then return end
    NetUI.albumState.selectedSnapshotID = snapID

    if not NetUI.PhotoEditFlyout then
        local fly = CreateBackdrop("Frame", "AltVaultPhotoEditFlyout", UIParent)
        fly:SetSize(486, 605)
        fly:SetPoint("CENTER", UIParent, "CENTER", -280, 0)
        fly:SetFrameStrata("FULLSCREEN_DIALOG")
        fly:SetFrameLevel(220)
        fly:SetToplevel(true)
        fly:SetClampedToScreen(true)
        fly:EnableMouse(true)
        fly:SetMovable(true)
        if fly.SetResizable then fly:SetResizable(true) end
        if fly.SetResizeBounds then
            fly:SetResizeBounds(380, 540, 860, 900)
        end

        fly:RegisterForDrag("LeftButton")
        fly:SetScript("OnDragStart", function(self) self:Raise(); self:StartMoving() end)
        fly:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
        fly:SetScript("OnMouseDown", function(self) self:Raise() end)

        if fly.SetBackdrop then
            fly:SetBackdrop({
                bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
                edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
                tile = true, tileSize = 32, edgeSize = 24,
                insets = { left = 5, right = 5, top = 5, bottom = 5 }
            })
            fly:SetBackdropColor(0.04, 0.05, 0.09, 0.98)
        end
        NetUI.PhotoEditFlyout = fly

        fly.CloseBtn = CreateFrame("Button", nil, fly, "UIPanelCloseButton")
        fly.CloseBtn:SetPoint("TOPRIGHT", fly, "TOPRIGHT", -4, -4)

        fly.Title = fly:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        fly.Title:SetPoint("TOP", fly, "TOP", 0, -13)
        fly.Title:SetFont(STANDARD_FONT, 14, "OUTLINE")
        fly.Title:SetText("|cffffd1001920x1009 Preloaded 16-Sheet GPU Stack 20s Video Studio|r")

        local viewBox = CreateBackdrop("Frame", nil, fly)
        viewBox:SetSize(454, 239)
        viewBox:SetPoint("TOP", fly, "TOP", 0, -38)
        viewBox:SetClipsChildren(true)
        viewBox:EnableMouse(true)
        viewBox:EnableMouseWheel(true)
        if viewBox.SetBackdrop then
            viewBox:SetBackdrop({
                bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
                edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
                tile = true, tileSize = 16, edgeSize = 14,
                insets = { left = 3, right = 3, top = 3, bottom = 3 }
            })
            viewBox:SetBackdropColor(0.01, 0.01, 0.02, 0.96)
        end
        fly.ViewBox = viewBox

        fly.PreviewTex = viewBox:CreateTexture(nil, "ARTWORK")
        fly.PreviewTex:SetPoint("TOPLEFT", viewBox, "TOPLEFT", 3, -3)
        fly.PreviewTex:SetPoint("BOTTOMRIGHT", viewBox, "BOTTOMRIGHT", -3, 3)
        EnsureStack(viewBox, fly.PreviewTex, 3)

        local isPanning = false
        local lastX, lastY = 0, 0
        local lastFlyFlipFrame = -1
        viewBox:SetScript("OnMouseDown", function(_, btn)
            fly:Raise()
            if btn == "LeftButton" or btn == "RightButton" then
                isPanning = true
                lastX, lastY = GetCursorPosition()
            end
        end)
        viewBox:SetScript("OnMouseUp", function()
            isPanning = false
            local id = NetUI.albumState.selectedSnapshotID
            local s = id and AltVaultDB.PhotoAlbum[id]
            if s then
                RefreshLiveGalleryCardForSnapshot(id)
                BroadcastSnapshotToGuild(s, AltVaultDB.CharacterAvatars[s.author] == s.id)
            end
        end)
        viewBox:SetScript("OnUpdate", function()
            local s = AltVaultDB.PhotoAlbum[NetUI.albumState.selectedSnapshotID]
            if not s or s.cleared then return end
            if isPanning then
                local cx, cy = GetCursorPosition()
                local dx, dy = cx - lastX, cy - lastY
                lastX, lastY = cx, cy
                s.panX = math.max(-100, math.min(100, (s.panX or 0) - (dx * 0.35)))
                s.panY = math.max(-100, math.min(100, (s.panY or 0) - (dy * 0.35)))
                Apply2DCrop(fly.PreviewTex, s)
                RefreshLiveGalleryCardForSnapshot(s.id)
            elseif s.isFlipbook then
                local fIdx = ResolveGlobalFlipFrame(s)
                if fIdx ~= lastFlyFlipFrame then
                    lastFlyFlipFrame = fIdx
                    Apply2DCrop(fly.PreviewTex, s, fIdx)
                end
            end
        end)
        viewBox:SetScript("OnMouseWheel", function(_, delta)
            local s = AltVaultDB.PhotoAlbum[NetUI.albumState.selectedSnapshotID]
            if not s then return end
            s.zoom = math.max(100, math.min(500, (s.zoom or 100) + (delta * 15)))
            Apply2DCrop(fly.PreviewTex, s)
            RefreshLiveGalleryCardForSnapshot(s.id)
        end)

        local helpFS = fly:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        helpFS:SetPoint("TOP", viewBox, "BOTTOM", 0, -4)
        helpFS:SetText("|cff00ff9620-Sec Preloaded HD Stack:|r Match [Sheets] & [FPS] to your Companion Helper import!")

        local function MakeFlyBtn(label, onClick)
            local b = CreateFrame("Button", nil, fly, "UIPanelButtonTemplate")
            b:SetText(label)
            if b:GetFontString() then b:GetFontString():SetFont(STANDARD_FONT, 10, "OUTLINE") end
            b:SetScript("OnClick", function(self) fly:Raise(); onClick(self) end)
            return b
        end

        local function AdjustSnap(field, delta, minV, maxV)
            local s = AltVaultDB.PhotoAlbum[NetUI.albumState.selectedSnapshotID]
            if not s then return end
            s.cleared = false
            s[field] = math.max(minV, math.min(maxV, (tonumber(s[field]) or 0) + delta))
            Apply2DCrop(fly.PreviewTex, s)
            RefreshLiveGalleryCardForSnapshot(s.id)
            BroadcastSnapshotToGuild(s, AltVaultDB.CharacterAvatars[s.author] == s.id)
        end

        fly.ZoomInBtn  = MakeFlyBtn("Zoom In (+)",  function() AdjustSnap("zoom",  25, 100, 500) end)
        fly.ZoomOutBtn = MakeFlyBtn("Zoom Out (-)", function() AdjustSnap("zoom", -25, 100, 500) end)
        fly.ResetBtn   = MakeFlyBtn("Full 1920x1009", function()
            local s = AltVaultDB.PhotoAlbum[NetUI.albumState.selectedSnapshotID]
            if s then
                s.zoom = 100; s.panX = 0; s.panY = 0; s.stretchX = 100
                Apply2DCrop(fly.PreviewTex, s)
                RefreshLiveGalleryCardForSnapshot(s.id)
            end
        end)

        fly.PanLeftBtn  = MakeFlyBtn("◄ Left",  function() AdjustSnap("panX", -10, -100, 100) end)
        fly.PanRightBtn = MakeFlyBtn("Right ►", function() AdjustSnap("panX",  10, -100, 100) end)
        fly.PanUpBtn    = MakeFlyBtn("▲ Up",    function() AdjustSnap("panY",  10, -100, 100) end)
        fly.PanDownBtn  = MakeFlyBtn("▼ Down",  function() AdjustSnap("panY", -10, -100, 100) end)

        fly.NarrowBtn     = MakeFlyBtn("Slimmer (-W)", function()
            local s = AltVaultDB.PhotoAlbum[NetUI.albumState.selectedSnapshotID]
            if s then s.stretchX = (tonumber(s.stretchX) or 100); AdjustSnap("stretchX", 8, 50, 200) end
        end)
        fly.SquareLockBtn = MakeFlyBtn("|cff00ff961920:1009 Lock|r", function()
            local s = AltVaultDB.PhotoAlbum[NetUI.albumState.selectedSnapshotID]
            if s then
                s.stretchX = 100
                Apply2DCrop(fly.PreviewTex, s)
                RefreshLiveGalleryCardForSnapshot(s.id)
            end
        end)
        fly.WidenBtn      = MakeFlyBtn("Wider (+W)", function()
            local s = AltVaultDB.PhotoAlbum[NetUI.albumState.selectedSnapshotID]
            if s then s.stretchX = (tonumber(s.stretchX) or 100); AdjustSnap("stretchX", -8, 50, 200) end
        end)

        local function CycleCharacterFileSlot(delta)
            local s = AltVaultDB.PhotoAlbum[NetUI.albumState.selectedSnapshotID]
            if not s then return end
            s.cleared = false
            local fSlot = (((tonumber(s.fileSlot) or tonumber(s.slotIndex) or 1) - 1 + delta) % MAX_FEATURED_SLOTS) + 1
            s.fileSlot = fSlot
            s.canvasFile = FormatCharacterSlotFilename(s.author, fSlot)
            s.filePath = FormatCharacterSlotTexturePath(s.author, fSlot)
            fly.CanvasLabelBtn:SetText("|cffffd100Vault (" .. s.canvasFile .. ")|r")
            Load2DScreenshotIntoTexture(fly.PreviewTex, s)
            RefreshLiveGalleryCardForSnapshot(s.id)
            BroadcastSnapshotToGuild(s, AltVaultDB.CharacterAvatars[s.author] == s.id)
        end

        fly.PrevCanvasBtn  = MakeFlyBtn("◄ Prev File", function() CycleCharacterFileSlot(-1) end)
        fly.CanvasLabelBtn = MakeFlyBtn("|cffffd100Pic Vault|r", function()
            local s = AltVaultDB.PhotoAlbum[NetUI.albumState.selectedSnapshotID]
            if s then OpenPersonalPicVaultPicker(s.author, s.slotIndex) end
        end)
        fly.NextCanvasBtn  = MakeFlyBtn("Next File ►", function() CycleCharacterFileSlot(1) end)

        fly.FlipbookBtn = MakeFlyBtn("|cffaaaaaa🎬 Video: OFF|r", function()
            local s = AltVaultDB.PhotoAlbum[NetUI.albumState.selectedSnapshotID]
            if s then
                s.cleared = false
                s.isFlipbook = not s.isFlipbook
                s.reelSheets = math.max(1, math.min(MAX_REEL_SHEETS, tonumber(s.reelSheets) or 15))
                if s.isFlipbook then
                    s.zoom = 100; s.panX = 0; s.panY = 0; s.stretchX = 100
                end
                if s.pingPong == nil then s.pingPong = false end
                s.fps = math.max(8, math.min(60, tonumber(s.fps) or 24))
                UpdateFlyoutVideoButtons(fly, s)
                Load2DScreenshotIntoTexture(fly.PreviewTex, s)
                RefreshLiveGalleryCardForSnapshot(s.id)
                BroadcastSnapshotToGuild(s, AltVaultDB.CharacterAvatars[s.author] == s.id)
                if MainPanel:IsShown() and MainPanel:GetActiveViewMode() == "PHOTO_ALBUM" and NetUI.RenderPhotoAlbumTab then
                    NetUI.RenderPhotoAlbumTab(MainPanel)
                end
            end
        end)

        fly.PingPongBtn = MakeFlyBtn("|cffffd100↻ Loop|r", function()
            local s = AltVaultDB.PhotoAlbum[NetUI.albumState.selectedSnapshotID]
            if s then
                s.pingPong = not s.pingPong
                UpdateFlyoutVideoButtons(fly, s)
                RefreshLiveGalleryCardForSnapshot(s.id)
            end
        end)

        fly.SheetMinusBtn = MakeFlyBtn("Sheets -", function()
            local s = AltVaultDB.PhotoAlbum[NetUI.albumState.selectedSnapshotID]
            if s then
                s.reelSheets = math.max(1, (tonumber(s.reelSheets) or 15) - 1)
                UpdateFlyoutVideoButtons(fly, s)
                Load2DScreenshotIntoTexture(fly.PreviewTex, s)
                RefreshLiveGalleryCardForSnapshot(s.id)
            end
        end)

        fly.SheetPlusBtn = MakeFlyBtn("Sheets +", function()
            local s = AltVaultDB.PhotoAlbum[NetUI.albumState.selectedSnapshotID]
            if s then
                s.reelSheets = math.min(MAX_REEL_SHEETS, (tonumber(s.reelSheets) or 15) + 1)
                UpdateFlyoutVideoButtons(fly, s)
                Load2DScreenshotIntoTexture(fly.PreviewTex, s)
                RefreshLiveGalleryCardForSnapshot(s.id)
            end
        end)

        fly.FpsMinusBtn = MakeFlyBtn("FPS -", function()
            local s = AltVaultDB.PhotoAlbum[NetUI.albumState.selectedSnapshotID]
            if s then
                s.fps = math.max(8, (tonumber(s.fps) or 24) - 2)
                UpdateFlyoutVideoButtons(fly, s)
                RefreshLiveGalleryCardForSnapshot(s.id)
            end
        end)

        fly.FpsPlusBtn = MakeFlyBtn("FPS +", function()
            local s = AltVaultDB.PhotoAlbum[NetUI.albumState.selectedSnapshotID]
            if s then
                s.fps = math.min(60, (tonumber(s.fps) or 24) + 2)
                UpdateFlyoutVideoButtons(fly, s)
                RefreshLiveGalleryCardForSnapshot(s.id)
            end
        end)

        fly.DurationBtn = MakeFlyBtn("Duration", function() end)

        local capBox = CreateFrame("EditBox", "AltVaultFlyoutCaptionBox", fly, "InputBoxTemplate")
        capBox:SetAutoFocus(false)
        capBox:SetMaxLetters(50)
        fly.CapBox = capBox

        fly.SaveTitleBtn = MakeFlyBtn("Save Title", function()
            capBox:ClearFocus()
            local s = AltVaultDB.PhotoAlbum[NetUI.albumState.selectedSnapshotID]
            if s then
                s.caption = capBox:GetText() or s.caption
                RefreshLiveGalleryCardForSnapshot(s.id)
                BroadcastSnapshotToGuild(s, AltVaultDB.CharacterAvatars[s.author] == s.id)
            end
        end)

        fly.Tab1Btn = MakeFlyBtn("|cff00ff00Set Tab 1 Pic|r", function()
            local s = AltVaultDB.PhotoAlbum[NetUI.albumState.selectedSnapshotID]
            if s and NetUI.SetAsOfflineAvatar then NetUI.SetAsOfflineAvatar(s.id, s.author) end
        end)

        fly.LockSlotBtn = MakeFlyBtn("|cffffd100Locked|r", function(self)
            local s = AltVaultDB.PhotoAlbum[NetUI.albumState.selectedSnapshotID]
            if s then
                s.locked = not s.locked
                self:SetText(s.locked and "|cffffd100🔒 Locked|r" or "|cffaaaaaa🔓 Unlocked|r")
                RefreshLiveGalleryCardForSnapshot(s.id)
                if MainPanel:IsShown() and MainPanel:GetActiveViewMode() == "PHOTO_ALBUM" and NetUI.RenderPhotoAlbumTab then
                    NetUI.RenderPhotoAlbumTab(MainPanel)
                end
            end
        end)

        fly.DeleteBtn = MakeFlyBtn("|cffff5555🗑️ Clear Slot|r", function()
            local id = NetUI.albumState.selectedSnapshotID
            local s = id and AltVaultDB.PhotoAlbum[id]
            if s then
                local owner = s.author
                local sIdx = s.slotIndex or 1
                ClearAlbumSlotInGame(owner, sIdx)
            end
            fly:Hide()
        end)

        local grip = CreateFrame("Button", nil, fly)
        grip:SetSize(22, 22)
        grip:SetPoint("BOTTOMRIGHT", fly, "BOTTOMRIGHT", -4, 4)
        grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
        grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
        grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
        grip:SetScript("OnMouseDown", function(_, btn)
            if btn == "LeftButton" and fly.StartSizing then
                fly:Raise()
                pcall(fly.StartSizing, fly, "BOTTOMRIGHT")
            end
        end)
        grip:SetScript("OnMouseUp", function()
            fly:StopMovingOrSizing()
            UpdateFloatingEditorLayout(fly)
        end)
        fly:SetScript("OnSizeChanged", function(self) UpdateFloatingEditorLayout(self) end)
    end

    local fly = NetUI.PhotoEditFlyout
    local snap = AltVaultDB.PhotoAlbum[snapID]
    fly.CapBox:SetText(snap.caption or "")
    fly.CanvasLabelBtn:SetText("|cffffd100Vault (" .. (snap.canvasFile or FormatCharacterSlotFilename(snap.author, snap.fileSlot or 1)) .. ")|r")
    UpdateFlyoutVideoButtons(fly, snap)
    fly.LockSlotBtn:SetText(snap.locked and "|cffffd100🔒 Locked|r" or "|cffaaaaaa🔓 Unlocked|r")
    UpdateFloatingEditorLayout(fly)
    fly:Show()
    fly:Raise()
    Load2DScreenshotIntoTexture(fly.PreviewTex, snap)
end

NetUI.OpenPhotoEditFlyout = OpenPhotoEditFlyout