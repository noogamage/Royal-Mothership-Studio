-- ============================================================================
-- FILE: UI_NetTab_PhotoAlbum.lua (MODULE 2 OF 2 FOR TAB 12 PHOTO ALBUM)
-- BLOCK HEADING: SNAPSHOT CAPTURE, NETWORK SYNC & TAB 12 12-SLOT GALLERY UI
-- ============================================================================
local addonName, ns = ...
local MainPanel = _G.AltVaultMainPanel
local NetUI = ns.NetUI
if not MainPanel or not NetUI then return end

local Armory = ns.Armory or {}

local CreateBackdrop = NetUI.CreateBackdrop
local STANDARD_FONT = NetUI.STANDARD_FONT
local MAX_FEATURED_SLOTS = NetUI.MAX_FEATURED_SLOTS or 12
local MAX_REEL_SHEETS = NetUI.MAX_REEL_SHEETS or 16
local MASTER_ASPECT_RATIO = NetUI.MASTER_ASPECT_RATIO or (1920 / 1009)

local FormatCharacterSlotFilename = NetUI.FormatCharacterSlotFilename
local FormatCharacterSlotTexturePath = NetUI.FormatCharacterSlotTexturePath
local EnsureCharacterAlbumSlotsPopulated = NetUI.EnsureCharacterAlbumSlotsPopulated
local SaveCharacterSlotsToCharacterTable = NetUI.SaveCharacterSlotsToCharacterTable
local EnsureAlbumTables = NetUI.EnsureAlbumTables

local EnsureStack = NetUI.EnsureStack
local ResolveGlobalFlipFrame = NetUI.ResolveGlobalFlipFrame
local Apply2DCrop = NetUI.Apply2DCrop
local Load2DScreenshotIntoTexture = NetUI.Load2DScreenshotIntoTexture

local ClearAlbumSlotInGame = NetUI.ClearAlbumSlotInGame
local GetPhotoVoteSummary = NetUI.GetPhotoVoteSummary
local BroadcastSnapshotToGuild = NetUI.BroadcastSnapshotToGuild
local CastPhotoCompetitionVote = NetUI.CastPhotoCompetitionVote
local OpenPersonalPicVaultPicker = NetUI.OpenPersonalPicVaultPicker
local OpenPhotoEditFlyout = NetUI.OpenPhotoEditFlyout

-- ============================================================================
-- BLOCK HEADING: CAPTURE / ASSIGN FILE #<FILESLOT> INTO ALBUM SLOT #<SLOTIDX>
-- ============================================================================
function NetUI.CaptureCharacterSnapshot(sourceTag, overrideCharName, explicitSlotIdx, explicitFileSlot)
    if not EnsureAlbumTables() then return nil end

    local now = GetTime and GetTime() or time()
    if sourceTag ~= "MANUAL_SLOT" and sourceTag ~= "VAULT_PICKER" and (now - (NetUI.albumState.lastCaptureTimestamp or 0)) < 1.5 then
        return NetUI.albumState.selectedSnapshotID
    end
    NetUI.albumState.lastCaptureTimestamp = now

    local author = (sourceTag == "MANUAL_SLOT" or sourceTag == "VAULT_PICKER") and overrideCharName or UnitName("player") or overrideCharName or "Unknown"

    local slotIdx = math.max(1, math.min(MAX_FEATURED_SLOTS, tonumber(explicitSlotIdx) or 1))
    local fileSlot = math.max(1, math.min(MAX_FEATURED_SLOTS, tonumber(explicitFileSlot) or slotIdx))
    local canvasFile = FormatCharacterSlotFilename(author, fileSlot)
    local snapshotID = string.format("%s_Slot%d", author, slotIdx)
    local filePath = FormatCharacterSlotTexturePath(author, fileSlot)
    local zoneName = GetRealZoneText() or GetZoneText() or "Azeroth"

    AltVaultDB.HiddenPhotoSlots[snapshotID] = nil

    local prevSnap = AltVaultDB.PhotoAlbum[snapshotID]
    local snap = {
        id = snapshotID,
        author = author,
        slotIndex = slotIdx,
        fileSlot = fileSlot,
        canvasFile = canvasFile,
        filePath = filePath,
        zone = zoneName,
        timestamp = time(),
        zoom = (prevSnap and prevSnap.zoom) or 100,
        panX = (prevSnap and prevSnap.panX) or 0,
        panY = (prevSnap and prevSnap.panY) or 0,
        stretchX = (prevSnap and prevSnap.stretchX) or 100,
        isFlipbook = (prevSnap and prevSnap.isFlipbook) or false,
        reelSheets = (prevSnap and tonumber(prevSnap.reelSheets)) or 15,
        pingPong = (prevSnap and prevSnap.pingPong ~= nil) and prevSnap.pingPong or false,
        fps = (prevSnap and tonumber(prevSnap.fps)) or 24,
        cleared = false,
        locked = true,
        votes = (prevSnap and prevSnap.votes) or 0,
        voters = (prevSnap and prevSnap.voters) or {},
        caption = (prevSnap and prevSnap.caption) or string.format("%s Slot #%d (%s)", author, slotIdx, canvasFile)
    }

    AltVaultDB.PhotoAlbum[snapshotID] = snap
    NetUI.albumState.selectedSnapshotID = snapshotID
    if not AltVaultDB.CharacterAvatars[author] then
        AltVaultDB.CharacterAvatars[author] = snapshotID
    end

    SaveCharacterSlotsToCharacterTable(author)
    BroadcastSnapshotToGuild(snap, AltVaultDB.CharacterAvatars[author] == snapshotID)

    if Armory.state and Armory.state.isFullScreenStage and sourceTag == "SCREENSHOT_EVENT" then
        return snapshotID
    end

    print(string.format("|cff00ff00[AltVault Photo Album]:|r Loaded File |cffffff00%s|r into %s's Album Slot #%d!",
        canvasFile, author, slotIdx))

    if MainPanel:IsShown() then
        if MainPanel:GetActiveViewMode() == "PHOTO_ALBUM" then
            NetUI.RenderPhotoAlbumTab(MainPanel)
        elseif not (Armory.state and Armory.state.isFullScreenStage) then
            MainPanel:RenderActivePane()
        end
    end
    return snapshotID
end

function NetUI.SetAsOfflineAvatar(snapshotID, overrideAuthor)
    if not EnsureAlbumTables() or not snapshotID or not AltVaultDB.PhotoAlbum[snapshotID] then return end
    local snap = AltVaultDB.PhotoAlbum[snapshotID]
    local owner = overrideAuthor or snap.author or UnitName("player")
    snap.cleared = false
    AltVaultDB.HiddenPhotoSlots[snapshotID] = nil
    AltVaultDB.CharacterAvatars[owner] = snapshotID
    SaveCharacterSlotsToCharacterTable(owner)
    BroadcastSnapshotToGuild(snap, true)
    print(string.format("|cff00ff00[AltVault Album]:|r Set |cffffff00\"%s\"|r (%s) as %s's Tab 1 Profile Photo!",
        snap.caption or snapshotID, snap.canvasFile or "Slot01", owner))
    if MainPanel:IsShown() then
        if MainPanel:GetActiveViewMode() == "PHOTO_ALBUM" then
            NetUI.RenderPhotoAlbumTab(MainPanel)
        elseif not (Armory.state and Armory.state.isFullScreenStage) then
            MainPanel:RenderActivePane()
        end
    end
end

-- ============================================================================
-- BLOCK HEADING: SINGLE SCREENSHOT & NETWORK EVENT HANDLER
-- ============================================================================
local AlbumEventFrame = CreateFrame("Frame")
if ns.Compat and ns.Compat.SafeRegisterEvent then
    ns.Compat.SafeRegisterEvent(AlbumEventFrame, "SCREENSHOT_SUCCEEDED")
    ns.Compat.SafeRegisterEvent(AlbumEventFrame, "CHAT_MSG_ADDON")
end

AlbumEventFrame:SetScript("OnEvent", function(_, event, prefix, message, _, sender)
    if event == "SCREENSHOT_SUCCEEDED" then
        local newID = NetUI.CaptureCharacterSnapshot("SCREENSHOT_EVENT", UnitName("player"))
        if newID and NetUI.albumState.openEditorAfterNextShot then
            NetUI.albumState.openEditorAfterNextShot = false
            if OpenPhotoEditFlyout then OpenPhotoEditFlyout(newID) end
        end
    elseif event == "CHAT_MSG_ADDON" and prefix == (ns.GuildNet and ns.GuildNet.PREFIX or "AV_Net") and message then
        if not EnsureAlbumTables() then return end
        local cleanSender = (ns.GuildNet and ns.GuildNet.StripRealm and ns.GuildNet.StripRealm(sender)) or sender
        if cleanSender == UnitName("player") then return end

        local cmd, payload = string.match(message, "^([^|]+)|(.*)$")
        if cmd == "PVOTE" then
            local pID, vName = string.match(payload or "", "^([^|]+)|([^|]+)$")
            if pID and vName then
                local snap = AltVaultDB.PhotoAlbum[pID]
                if not snap or snap.author ~= vName then
                    AltVaultDB.PhotoVotes[pID] = AltVaultDB.PhotoVotes[pID] or {}
                    AltVaultDB.PhotoVotes[pID][vName] = 1
                    if snap then snap.votes = GetPhotoVoteSummary(pID) end
                    if MainPanel:IsShown() and MainPanel:GetActiveViewMode() == "PHOTO_ALBUM" then
                        NetUI.RenderPhotoAlbumTab(MainPanel)
                    end
                end
            end
        elseif cmd == "PSNAP" then
            local parts = {}
            for tok in string.gmatch((payload or "") .. "|", "([^|]*)|") do table.insert(parts, tok) end
            local id, auth, sIdx, fSlot, zm, px, py, avFlag, zn, cap, flipFlag =
                parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8], parts[9], parts[10], parts[11]
            if id and id ~= "" and auth and auth ~= "" then
                local slotNum = tonumber(sIdx) or 1
                local fileSlot = tonumber(fSlot) or slotNum
                local stdID = string.format("%s_Slot%d", auth, slotNum)
                local existing = AltVaultDB.PhotoAlbum[stdID] or {}
                existing.id = stdID
                existing.author = auth
                existing.slotIndex = slotNum
                existing.fileSlot = fileSlot
                existing.canvasFile = FormatCharacterSlotFilename(auth, fileSlot)
                existing.filePath = FormatCharacterSlotTexturePath(auth, fileSlot)
                existing.zoom = tonumber(zm) or 100
                existing.panX = tonumber(px) or 0
                existing.panY = tonumber(py) or 0
                existing.zone = (zn and zn ~= "") and zn or "Azeroth"
                existing.caption = (cap and cap ~= "") and cap or (auth .. "'s Photo")
                existing.cleared = false
                if flipFlag ~= nil and flipFlag ~= "" and flipFlag ~= "0" then
                    local shStr, fpsStr = string.match(flipFlag, "^(%d+):(%d+)$")
                    existing.isFlipbook = true
                    existing.reelSheets = math.max(1, math.min(MAX_REEL_SHEETS, tonumber(shStr) or 15))
                    existing.fps = math.max(8, math.min(60, tonumber(fpsStr) or 24))
                else
                    existing.isFlipbook = false
                end
                existing.timestamp = existing.timestamp or time()
                AltVaultDB.PhotoAlbum[stdID] = existing
                if avFlag == "1" then
                    AltVaultDB.CharacterAvatars[auth] = stdID
                end
            end
        end
    end
end)

-- ============================================================================
-- BLOCK HEADING: TAB 12 LARGE 2D PHOTO GALLERY (ALL 12 CARDS LOCKED TO 1920:1009)
-- ============================================================================
function NetUI.RenderPhotoAlbumTab(panel)
    EnsureAlbumTables()
    panel:HideListAndDBFrames()
    if Armory.ArmoryCanvas then Armory.ArmoryCanvas:Hide() end
    if NetUI.ConfigureHeaderForMode then NetUI.ConfigureHeaderForMode("PHOTO_ALBUM") end

    local activeAuthor = panel:GetSelectedSyncedPeer() or panel:GetSelectedCharacter() or UnitName("player")
    EnsureCharacterAlbumSlotsPopulated(activeAuthor)

    if NetUI.PicVaultPickerFrame and NetUI.PicVaultPickerFrame:IsShown() and NetUI.PicVaultPickerFrame.activeChar ~= activeAuthor then
        OpenPersonalPicVaultPicker(activeAuthor, NetUI.albumState.vaultTargetSlot or 1)
    end

    local leftX = panel:GetLeftColumnOffset()
    local baseTopY = panel:GetBaseContentTopY()

    if not NetUI.AlbumCanvas then
        local canvas = CreateFrame("Frame", "AltVaultPhotoAlbumCanvas", panel)
        NetUI.AlbumCanvas = canvas

        local topBar = CreateBackdrop("Frame", nil, canvas)
        topBar:SetPoint("TOPLEFT", canvas, "TOPLEFT", 0, 0)
        topBar:SetPoint("TOPRIGHT", canvas, "TOPRIGHT", -4, 0)
        topBar:SetHeight(50)
        if topBar.SetBackdrop then
            topBar:SetBackdrop({
                bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
                edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
                tile = true, tileSize = 32, edgeSize = 14,
                insets = { left = 3, right = 3, top = 3, bottom = 3 }
            })
            topBar:SetBackdropColor(0.05, 0.07, 0.12, 0.96)
        end
        canvas.TopBar = topBar

        local function MakeTopBtn(label, w, leftAnchor, offsetX, onClick)
            local b = CreateFrame("Button", nil, topBar, "UIPanelButtonTemplate")
            b:SetSize(w, 30)
            if not leftAnchor then b:SetPoint("LEFT", topBar, "LEFT", offsetX, 0)
            else b:SetPoint("LEFT", leftAnchor, "RIGHT", offsetX, 0) end
            b:SetText(label)
            if b:GetFontString() then b:GetFontString():SetFont(STANDARD_FONT, 11, "OUTLINE") end
            b:SetScript("OnClick", onClick)
            return b
        end

        canvas.SnapBtn = MakeTopBtn("|cff00ff96+ Fullscreen Studio|r", 132, nil, 8, function()
            panel:SwitchToTab("ARMORY")
            if Armory.EnterFullScreenStageMode then
                Armory.EnterFullScreenStageMode()
            end
        end)

        canvas.VaultBtn = MakeTopBtn("|cffffd100📁 Pic Vault|r", 105, canvas.SnapBtn, 5, function()
            local curChar = panel:GetSelectedSyncedPeer() or panel:GetSelectedCharacter() or UnitName("player")
            OpenPersonalPicVaultPicker(curChar, NetUI.albumState.vaultTargetSlot or 1)
        end)

        canvas.MyAlbumBtn = MakeTopBtn("Character Album", 135, canvas.VaultBtn, 5, function()
            NetUI.albumState.viewFilter = "MY_ALBUM"
            NetUI.RenderPhotoAlbumTab(panel)
        end)

        canvas.CompBtn = MakeTopBtn("|cffffd100🏆 Competition|r", 125, canvas.MyAlbumBtn, 5, function()
            NetUI.albumState.viewFilter = "COMPETITION"
            NetUI.RenderPhotoAlbumTab(panel)
        end)

        canvas.RestoreAllBtn = MakeTopBtn("|cff00ff96Mount All 12|r", 96, canvas.CompBtn, 5, function()
            local curChar = panel:GetSelectedSyncedPeer() or panel:GetSelectedCharacter() or UnitName("player")
            AltVaultDB.HiddenPhotoSlots = {}
            for sIdx = 1, MAX_FEATURED_SLOTS do
                local k = string.format("%s_Slot%d", curChar, sIdx)
                if AltVaultDB.PhotoAlbum[k] then
                    AltVaultDB.PhotoAlbum[k].cleared = false
                end
            end
            EnsureCharacterAlbumSlotsPopulated(curChar)
            SaveCharacterSlotsToCharacterTable(curChar)
            NetUI.RenderPhotoAlbumTab(panel)
        end)

        local scrollFrame = CreateFrame("ScrollFrame", "AltVaultAlbumScrollFrame", canvas, "UIPanelScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT", topBar, "BOTTOMLEFT", 0, -6)
        scrollFrame:SetPoint("BOTTOMRIGHT", canvas, "BOTTOMRIGHT", -26, 4)

        local scrollChild = CreateFrame("Frame", nil, scrollFrame)
        scrollChild:SetSize(600, 600)
        scrollFrame:SetScrollChild(scrollChild)
        canvas.ScrollFrame = scrollFrame
        canvas.ScrollChild = scrollChild

        canvas.EmptyNotice = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        canvas.EmptyNotice:SetPoint("TOP", scrollChild, "TOP", 0, -60)
        canvas.EmptyNotice:SetWidth(520)
        canvas.EmptyNotice:SetJustifyH("CENTER")
        canvas.EmptyNotice:Hide()

        canvas.Cards = {}

        -- Preloaded 16-Sheet 20s HD Animator for all visible Tab 12 Album Cards!
        canvas:SetScript("OnUpdate", function(self)
            if not AltVaultDB or not AltVaultDB.PhotoAlbum then return end
            for _, card in ipairs(self.Cards) do
                if card:IsShown() and card.snapID then
                    local s = AltVaultDB.PhotoAlbum[card.snapID]
                    if s and s.isFlipbook and not s.cleared then
                        local fIdx = ResolveGlobalFlipFrame(s)
                        if card.lastFlipFrame ~= fIdx then
                            card.lastFlipFrame = fIdx
                            Apply2DCrop(card.PhotoTex, s, fIdx)
                        end
                    end
                end
            end
        end)
    end

    local canvas = NetUI.AlbumCanvas
    canvas:ClearAllPoints()
    canvas:SetPoint("TOPLEFT", panel, "TOPLEFT", leftX, baseTopY)
    canvas:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -12, 14)
    canvas:Show()

    canvas.MyAlbumBtn:SetText(activeAuthor .. "'s Album")
    local isComp = (NetUI.albumState.viewFilter == "COMPETITION")
    if isComp then canvas.CompBtn:LockHighlight(); canvas.MyAlbumBtn:UnlockHighlight()
    else canvas.MyAlbumBtn:LockHighlight(); canvas.CompBtn:UnlockHighlight() end

    local list = {}
    local bySlot = {}
    for _, snap in pairs(AltVaultDB.PhotoAlbum) do
        if snap and not snap.cleared then
            local vCount = GetPhotoVoteSummary(snap.id)
            if isComp then
                if vCount >= 1 then table.insert(list, snap) end
            elseif snap.author == activeAuthor and not AltVaultDB.HiddenPhotoSlots[snap.id] then
                bySlot[snap.slotIndex or 1] = snap
            end
        end
    end

    if isComp then
        table.sort(list, function(a, b)
            local vA = GetPhotoVoteSummary(a.id)
            local vB = GetPhotoVoteSummary(b.id)
            if vA ~= vB then return vA > vB end
            return (a.timestamp or 0) < (b.timestamp or 0)
        end)
    end

    for _, c in ipairs(canvas.Cards) do c:Hide() end

    if isComp and #list == 0 then
        canvas.EmptyNotice:SetText("|cffffd100No Photos Have Been Voted On Yet!|r\n\n|cffccccccSwitch to [" .. activeAuthor .. "'s Album] or click a guildmate on the left sidebar and click the |cff00ff00[Vote]|r button on your favorite screenshots to enter them into the Competition Leaderboard!|r")
        canvas.EmptyNotice:Show()
        canvas.ScrollChild:SetHeight(240)
        return
    else
        canvas.EmptyNotice:Hide()
    end

    local gridW = math.max(460, (canvas:GetWidth() or 700) - 34)
    canvas.ScrollChild:SetWidth(gridW)
    local cols = 3
    local cardW = math.floor((gridW - 20) / cols)
    local photoBoxW = cardW - 16
    local photoBoxH = math.floor((photoBoxW / MASTER_ASPECT_RATIO) + 0.5)
    local cardH = photoBoxH + 86

    local totalSlots = isComp and #list or MAX_FEATURED_SLOTS
    for i = 1, totalSlots do
        local snap = isComp and list[i] or bySlot[i]
        local card = canvas.Cards[i]
        if not card then
            card = CreateBackdrop("Button", nil, canvas.ScrollChild)
            card.HeaderFS = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            card.HeaderFS:SetPoint("TOPLEFT", card, "TOPLEFT", 8, -7)
            card.HeaderFS:SetPoint("TOPRIGHT", card, "TOPRIGHT", -8, -7)
            card.HeaderFS:SetJustifyH("LEFT")
            card.HeaderFS:SetFont(STANDARD_FONT, 12, "OUTLINE")

            card.PhotoBox = CreateBackdrop("Button", nil, card)
            card.PhotoBox:SetPoint("TOPLEFT", card, "TOPLEFT", 8, -26)
            card.PhotoBox:SetPoint("TOPRIGHT", card, "TOPRIGHT", -8, -26)
            card.PhotoBox:SetClipsChildren(true)
            if card.PhotoBox.SetBackdrop then
                card.PhotoBox:SetBackdrop({
                    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
                    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                    tile = true, tileSize = 16, edgeSize = 10,
                    insets = { left = 2, right = 2, top = 2, bottom = 2 }
                })
                card.PhotoBox:SetBackdropColor(0.02, 0.02, 0.04, 0.95)
            end

            card.PhotoTex = card.PhotoBox:CreateTexture(nil, "ARTWORK")
            card.PhotoTex:SetPoint("TOPLEFT", card.PhotoBox, "TOPLEFT", 2, -2)
            card.PhotoTex:SetPoint("BOTTOMRIGHT", card.PhotoBox, "BOTTOMRIGHT", -2, 2)
            EnsureStack(card.PhotoBox, card.PhotoTex, 2)

            card.CapFS = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            card.CapFS:SetPoint("TOPLEFT", card.PhotoBox, "BOTTOMLEFT", 2, -4)
            card.CapFS:SetPoint("TOPRIGHT", card.PhotoBox, "BOTTOMRIGHT", -2, -4)
            card.CapFS:SetJustifyH("CENTER")
            card.CapFS:SetFont(STANDARD_FONT, 11, "OUTLINE")

            local function MakeCardBtn(w)
                local b = CreateFrame("Button", nil, card, "UIPanelButtonTemplate")
                b:SetSize(w, 24)
                if b:GetFontString() then b:GetFontString():SetFont(STANDARD_FONT, 10, "OUTLINE") end
                return b
            end

            card.EditBtn = MakeCardBtn(66)
            card.EditBtn:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", 7, 7)

            card.AvatarBtn = MakeCardBtn(74)
            card.AvatarBtn:SetPoint("BOTTOM", card, "BOTTOM", 0, 7)

            card.VoteBtn = MakeCardBtn(68)
            card.VoteBtn:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -7, 7)

            canvas.Cards[i] = card
        end

        local rIdx = math.floor((i - 1) / cols)
        local cIdx = (i - 1) % cols
        card:SetSize(cardW, cardH)
        card.PhotoBox:SetHeight(photoBoxH)
        card:ClearAllPoints()
        card:SetPoint("TOPLEFT", canvas.ScrollChild, "TOPLEFT", 4 + cIdx * (cardW + 6), -4 - rIdx * (cardH + 8))

        local btnW = math.max(58, math.floor((cardW - 22) / 3))
        card.EditBtn:SetWidth(btnW)
        card.AvatarBtn:SetWidth(btnW)
        card.VoteBtn:SetWidth(btnW)

        local slotIdx = i
        if snap and not snap.cleared then
            card.snapID = snap.id
            card.lastFlipFrame = -1
            local isSel = (NetUI.albumState.selectedSnapshotID == snap.id)
            local isAv = (AltVaultDB.CharacterAvatars[snap.author] == snap.id)
            local votes, myVote = GetPhotoVoteSummary(snap.id)

            if card.SetBackdrop then
                card:SetBackdrop({
                    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
                    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
                    tile = true, tileSize = 16, edgeSize = 14,
                    insets = { left = 3, right = 3, top = 3, bottom = 3 }
                })
                card:SetBackdropColor(0.06, 0.08, 0.13, 0.96)
                card:SetBackdropBorderColor(isSel and 1.0 or 0.45, isSel and 0.85 or 0.48, isSel and 0.20 or 0.55, 1.0)
            end

            Load2DScreenshotIntoTexture(card.PhotoTex, snap)

            local slotTitle = isComp and string.format("|cffffd100#%d|r ", i) or string.format("|cff88ccffSlot %d:|r ", i)
            local avBadge = isAv and " |cff00ff00[TAB 1]|r" or ""
            local lockBadge = snap.locked and " |cffffd100[🔒]|r" or ""
            local nSheets = tonumber(snap.reelSheets) or 15
            local flipBadge = snap.isFlipbook and string.format(" |cff00ff96[🎬 %dS %dFPS]|r", nSheets, tonumber(snap.fps) or 24) or ""
            card.HeaderFS:SetText(slotTitle .. "|cffffff00" .. (snap.author or "?") .. "|r" .. lockBadge .. flipBadge .. avBadge)
            card.CapFS:SetText(string.format("\"%s\" |cff88ccff[%s]|r |cffffd100(★ %d)|r",
                snap.caption or "Photo", snap.canvasFile or "Slot01", votes))

            card.EditBtn:Show()
            card.EditBtn:SetText("Edit/Swap")
            card.EditBtn:SetScript("OnClick", function() OpenPhotoEditFlyout(snap.id) end)
            card.PhotoBox:SetScript("OnClick", function() OpenPhotoEditFlyout(snap.id) end)

            card.AvatarBtn:Show()
            card.AvatarBtn:SetText(isAv and "|cff00ff00On Tab 1|r" or "Tab 1 Pic")
            card.AvatarBtn:SetScript("OnClick", function() NetUI.SetAsOfflineAvatar(snap.id) end)

            card.VoteBtn:Show()
            local isOwn = (snap.author == UnitName("player")) or (AltVaultDB.Characters and AltVaultDB.Characters[snap.author] ~= nil)
            if isOwn and not isComp then
                card.VoteBtn:SetText("|cffff5555Clear Slot|r")
                card.VoteBtn:SetScript("OnClick", function()
                    ClearAlbumSlotInGame(activeAuthor, slotIdx)
                end)
            elseif myVote then
                card.VoteBtn:SetText("|cff00ff00Voted (" .. votes .. ")|r")
                card.VoteBtn:SetScript("OnClick", function() CastPhotoCompetitionVote(snap.id) end)
            else
                card.VoteBtn:SetText("|cffffd100Vote (" .. votes .. ")|r")
                card.VoteBtn:SetScript("OnClick", function() CastPhotoCompetitionVote(snap.id) end)
            end
        else
            card.snapID = nil
            card.lastFlipFrame = -1
            if card.SetBackdrop then
                card:SetBackdrop({
                    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
                    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                    tile = true, tileSize = 16, edgeSize = 12,
                    insets = { left = 3, right = 3, top = 3, bottom = 3 }
                })
                card:SetBackdropColor(0.03, 0.04, 0.06, 0.75)
                card:SetBackdropBorderColor(0.25, 0.28, 0.35, 0.75)
            end
            Load2DScreenshotIntoTexture(card.PhotoTex, nil)
            card.HeaderFS:SetText(string.format("|cff666666%s Slot #%d (Empty)|r", activeAuthor, slotIdx))
            card.CapFS:SetText("|cff00ff96Click to pick a picture from Pic Vault for Slot #" .. slotIdx .. "|r")
            card.EditBtn:Show()
            card.EditBtn:SetText("|cffffd100Pic Vault|r")
            card.EditBtn:SetScript("OnClick", function()
                OpenPersonalPicVaultPicker(activeAuthor, slotIdx)
            end)
            card.AvatarBtn:Hide()
            card.VoteBtn:Hide()
            card.PhotoBox:SetScript("OnClick", function()
                OpenPersonalPicVaultPicker(activeAuthor, slotIdx)
            end)
        end
        card:Show()
    end

    local numRows = math.ceil(totalSlots / cols)
    canvas.ScrollChild:SetHeight(math.max(260, numRows * (cardH + 8) + 20))
end

local function EnsurePhotoAlbumTabRegistered()
    if not MainPanel or not MainPanel.RegisterExternalTab then return end
    if MainPanel.externalTabRenderers and MainPanel.externalTabRenderers["PHOTO_ALBUM"] then return end
    MainPanel:RegisterExternalTab(
        "PHOTO_ALBUM",
        "Photo Album",
        "1920x1009 Synchronized 12-Slot Photo Album, 20-Second Preloaded HD Videos, Pic Vault & Competition!",
        function(panel) NetUI.RenderPhotoAlbumTab(panel) end
    )
    if MainPanel.ApplyGlobalButtonScaling then
        MainPanel:ApplyGlobalButtonScaling(false)
    end
end

C_Timer.After(0.05, EnsurePhotoAlbumTabRegistered)