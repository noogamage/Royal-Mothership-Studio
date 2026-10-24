-- ============================================================================
-- FILE: UI_ArmoryVideoAndPoses.lua (MODULE 1 OF 3 FOR TAB 1 VISUAL ARMORY)
-- BLOCK HEADING: 1920x1009 CONSTANTS, 32 POSES & 16-SHEET GPU VIDEO STACK ENGINE
-- ============================================================================
local addonName, ns = ...
local MainPanel = _G.AltVaultMainPanel
if not MainPanel then return end

local Armory = ns.Armory or {}
ns.Armory = Armory

local CreateBackdrop = (ns.Compat and ns.Compat.CreateBackdropFrame) or function(fType, fName, parent, extraTpl)
    if _G.BackdropTemplateMixin then
        local tpl = extraTpl and (extraTpl .. ", BackdropTemplate") or "BackdropTemplate"
        local ok, f = pcall(CreateFrame, fType, fName, parent, tpl)
        if ok and f then return f end
    end
    return CreateFrame(fType or "Frame", fName, parent, extraTpl)
end

local SetSolid = (ns.Compat and ns.Compat.SetSolidColor) or function(tex, r, g, b, a)
    if not tex then return end
    if tex.SetColorTexture then
        tex:SetColorTexture(r, g, b, a or 1.0)
    elseif tex.SetTexture then
        tex:SetTexture(r, g, b, a or 1.0)
    end
end

local STANDARD_FONT = "Fonts\\FRIZQT__.TTF"
local BASE_PANEL_W = 960
local BASE_PANEL_H = 700
local SNAPSHOT_FOLDER = "Interface\\AddOns\\" .. tostring(addonName or "AltVault") .. "\\Snapshots\\"
local MAX_REEL_SHEETS = 16

-- Exact Master Render Aspect Ratio: 1920 x 1009 (1.90287 : 1)
local MASTER_RENDER_W = 1920
local MASTER_RENDER_H = 1009
local MASTER_ASPECT_RATIO = MASTER_RENDER_W / MASTER_RENDER_H

Armory.CreateBackdrop = CreateBackdrop
Armory.SetSolid = SetSolid
Armory.STANDARD_FONT = STANDARD_FONT
Armory.BASE_PANEL_W = BASE_PANEL_W
Armory.BASE_PANEL_H = BASE_PANEL_H
Armory.SNAPSHOT_FOLDER = SNAPSHOT_FOLDER
Armory.MAX_REEL_SHEETS = MAX_REEL_SHEETS
Armory.MASTER_RENDER_W = MASTER_RENDER_W
Armory.MASTER_RENDER_H = MASTER_RENDER_H
Armory.MASTER_ASPECT_RATIO = MASTER_ASPECT_RATIO

Armory.state = Armory.state or {
    showAllBagItemsInBox = false,
    showAllBankItemsInBox = false,
    activeDisplayedCharName = nil,
    activeDisplayedCharData = nil,
    isModelDancing = false,
    isUpdatingZoomSlider = false,
    currentPoseIndex = 1,
    currentRotation = 0,
    currentPanX = 0,
    currentPanY = 0,
    isFullScreenStage = false,
}

local function SanitizeCharTag(charName)
    local raw = tostring(charName or "Player")
    raw = string.gsub(raw, "%s+", "")
    raw = string.gsub(raw, "[^%w_%-]", "")
    if raw == "" then raw = "Player" end
    return raw
end

Armory.SanitizeCharTag = SanitizeCharTag

local CLASS_COLOR_RGB = {
    WARRIOR     = { 0.78, 0.61, 0.43, "c79c6e" },
    PALADIN     = { 0.96, 0.55, 0.73, "f58cba" },
    HUNTER      = { 0.67, 0.83, 0.45, "abd473" },
    ROGUE       = { 1.00, 0.96, 0.41, "fff569" },
    PRIEST      = { 1.00, 1.00, 1.00, "ffffff" },
    DEATHKNIGHT = { 0.77, 0.12, 0.23, "c41f3b" },
    SHAMAN      = { 0.00, 0.44, 0.87, "0070de" },
    MAGE        = { 0.25, 0.78, 0.92, "40c7eb" },
    WARLOCK     = { 0.53, 0.53, 0.93, "8787ed" },
    DRUID       = { 1.00, 0.49, 0.04, "ff7d0a" },
    MONK        = { 0.00, 1.00, 0.60, "00ff98" },
}

local QUALITY_RGB = {
    [0] = { 0.62, 0.62, 0.62 },
    [1] = { 0.85, 0.85, 0.85 },
    [2] = { 0.12, 1.00, 0.00 },
    [3] = { 0.00, 0.44, 0.87 },
    [4] = { 0.64, 0.21, 0.93 },
    [5] = { 0.99, 0.50, 0.00 },
}

local function GetItemIconTexture(linkOrID)
    if not linkOrID then return nil end
    if C_Item and C_Item.GetItemIconByID then return C_Item.GetItemIconByID(linkOrID)
    elseif GetItemIcon then return GetItemIcon(linkOrID) end
    local _, _, _, _, _, _, _, _, _, icon = ns.Scanner.FetchItemInfo(linkOrID)
    return icon
end

Armory.CLASS_COLOR_RGB = CLASS_COLOR_RGB
Armory.QUALITY_RGB = QUALITY_RGB
Armory.GetItemIconTexture = GetItemIconTexture

-- ============================================================================
-- BLOCK HEADING: 32 DANCE & POSE ROUTINES (FOR LIVE SCREENSHOT POSING)
-- ============================================================================
local SNAPSHOT_POSES = {
    { name = "1. Stand (Idle)",         anim = 0,   loopSec = 2.5 },
    { name = "2. Dance Routine",        anim = 69,  loopSec = 3.0 },
    { name = "3. Flex / Muscle",        anim = 82,  loopSec = 2.0 },
    { name = "4. Victory Cheer",        anim = 68,  loopSec = 2.0 },
    { name = "5. Battle Roar",          anim = 74,  loopSec = 2.2 },
    { name = "6. Salute",               anim = 66,  loopSec = 2.0 },
    { name = "7. Combat Ready (1H)",    anim = 26,  loopSec = 1.8 },
    { name = "8. Combat Ready (2H)",    anim = 27,  loopSec = 1.8 },
    { name = "9. Combat Ready (2HL)",   anim = 28,  loopSec = 1.8 },
    { name = "10. Bow / Rifle Ready",   anim = 29,  loopSec = 1.8 },
    { name = "11. Unarmed / Brawl",     anim = 25,  loopSec = 1.8 },
    { name = "12. Spell Omni Cast",     anim = 53,  loopSec = 1.6 },
    { name = "13. Spell Directed Cast", anim = 52,  loopSec = 1.6 },
    { name = "14. Channeling Spell",    anim = 124, loopSec = 2.0 },
    { name = "15. Special 1H Attack",   anim = 61,  loopSec = 1.5 },
    { name = "16. Special 2H Cleave",   anim = 62,  loopSec = 1.6 },
    { name = "17. Whirlwind Spin",      anim = 126, loopSec = 1.2 },
    { name = "18. Stealth Crouch",      anim = 120, loopSec = 2.0 },
    { name = "19. Walk Stride",         anim = 4,   loopSec = 1.5 },
    { name = "20. Run Sprint",          anim = 5,   loopSec = 1.2 },
    { name = "21. Laugh",               anim = 70,  loopSec = 2.0 },
    { name = "22. Applaud / Clap",      anim = 80,  loopSec = 2.0 },
    { name = "23. Point Forward",       anim = 84,  loopSec = 2.0 },
    { name = "24. Wave Greeting",       anim = 67,  loopSec = 2.0 },
    { name = "25. Rude Gesture",        anim = 73,  loopSec = 2.0 },
    { name = "26. Shy / Blush",         anim = 76,  loopSec = 2.2 },
    { name = "27. Blow a Kiss",         anim = 77,  loopSec = 2.0 },
    { name = "28. Cry / Sob",           anim = 78,  loopSec = 2.2 },
    { name = "29. Chicken Flap",        anim = 79,  loopSec = 2.0 },
    { name = "30. Kneel Down",          anim = 119, loopSec = 2.5 },
    { name = "31. Sit Ground",          anim = 97,  loopSec = 2.5 },
    { name = "32. Sleep Lie Down",      anim = 100, loopSec = 2.5 },
}
Armory.SNAPSHOT_POSES = SNAPSHOT_POSES

local function SetModelLoopingPose(modelFrame, poseIdx)
    if not modelFrame then return end
    local idx = tonumber(poseIdx) or 1
    local pose = SNAPSHOT_POSES[idx] or SNAPSHOT_POSES[1]
    modelFrame.avLoopPoseIdx = idx
    modelFrame.avLoopAnimID = pose.anim
    modelFrame.avLoopInterval = pose.loopSec or 1.8
    modelFrame.avLoopElapsed = 0
    if modelFrame.SetAnimation then
        pcall(modelFrame.SetAnimation, modelFrame, pose.anim)
    end
end

local function TickModelLoopingPose(modelFrame, elapsed)
    if not modelFrame or not modelFrame:IsShown() then return end
    local animID = modelFrame.avLoopAnimID
    if animID == nil then return end
    modelFrame.avLoopElapsed = (modelFrame.avLoopElapsed or 0) + (elapsed or 0.016)
    if modelFrame.avLoopElapsed >= (modelFrame.avLoopInterval or 1.8) then
        modelFrame.avLoopElapsed = 0
        if modelFrame.SetAnimation then
            pcall(modelFrame.SetAnimation, modelFrame, animID)
        end
    end
end

Armory.SetModelLoopingPose = SetModelLoopingPose
Armory.TickModelLoopingPose = TickModelLoopingPose

local PoseDropdownPopup = nil

local function HidePoseDropdownMenu()
    if PoseDropdownPopup then
        PoseDropdownPopup:Hide()
    end
end

local function TogglePoseDropdownMenu(anchorBtn, currentPoseIdx, onSelectCallback)
    if not PoseDropdownPopup then
        PoseDropdownPopup = CreateBackdrop("Frame", "AltVaultPoseDropdownMenu", UIParent)
        PoseDropdownPopup:SetSize(210, 260)
        PoseDropdownPopup:SetFrameStrata("TOOLTIP")
        PoseDropdownPopup:SetFrameLevel(500)
        PoseDropdownPopup:EnableMouse(true)
        PoseDropdownPopup:SetClampedToScreen(true)
        if PoseDropdownPopup.SetBackdrop then
            PoseDropdownPopup:SetBackdrop({
                bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
                edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
                tile = true, tileSize = 32, edgeSize = 16,
                insets = { left = 4, right = 4, top = 4, bottom = 4 }
            })
            PoseDropdownPopup:SetBackdropColor(0.03, 0.04, 0.08, 0.98)
        end

        local title = PoseDropdownPopup:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        title:SetPoint("TOP", PoseDropdownPopup, "TOP", 0, -8)
        title:SetFont(STANDARD_FONT, 11, "OUTLINE")
        title:SetText("|cffffd100Select Dance / Pose Routine|r")

        local scroll = CreateFrame("ScrollFrame", "AltVaultPoseDropdownScroll", PoseDropdownPopup, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", PoseDropdownPopup, "TOPLEFT", 6, -24)
        scroll:SetPoint("BOTTOMRIGHT", PoseDropdownPopup, "BOTTOMRIGHT", -26, 6)

        local child = CreateFrame("Frame", nil, scroll)
        child:SetSize(172, #SNAPSHOT_POSES * 22 + 6)
        scroll:SetScrollChild(child)
        PoseDropdownPopup.Child = child
        PoseDropdownPopup.Buttons = {}

        for idx, pose in ipairs(SNAPSHOT_POSES) do
            local b = CreateFrame("Button", nil, child, "UIPanelButtonTemplate")
            b:SetSize(170, 20)
            b:SetPoint("TOPLEFT", child, "TOPLEFT", 2, -((idx - 1) * 22))
            b:SetText(pose.name)
            if b:GetFontString() then
                b:GetFontString():SetFont(STANDARD_FONT, 10, "OUTLINE")
                b:GetFontString():SetJustifyH("LEFT")
            end
            b.poseIndex = idx
            b:SetScript("OnClick", function(self)
                PoseDropdownPopup:Hide()
                if PoseDropdownPopup.onSelect then
                    PoseDropdownPopup.onSelect(self.poseIndex, SNAPSHOT_POSES[self.poseIndex])
                end
            end)
            PoseDropdownPopup.Buttons[idx] = b
        end
        PoseDropdownPopup:Hide()
    end

    if PoseDropdownPopup:IsShown() and PoseDropdownPopup.anchorBtn == anchorBtn then
        PoseDropdownPopup:Hide()
        return
    end

    PoseDropdownPopup.anchorBtn = anchorBtn
    PoseDropdownPopup.onSelect = onSelectCallback
    for idx, b in ipairs(PoseDropdownPopup.Buttons) do
        if idx == (currentPoseIdx or 1) then b:LockHighlight() else b:UnlockHighlight() end
    end

    PoseDropdownPopup:ClearAllPoints()
    PoseDropdownPopup:SetPoint("BOTTOMLEFT", anchorBtn, "TOPLEFT", 0, 4)
    PoseDropdownPopup:Show()
end

Armory.HidePoseDropdownMenu = HidePoseDropdownMenu
Armory.TogglePoseDropdownMenu = TogglePoseDropdownMenu

-- ============================================================================
-- BLOCK HEADING: OPTION A — PRELOADED 16-SHEET GPU TEXTURE STACK ENGINE
-- Preloads _V01.._V16 into separate GPU textures when the view opens!
-- During playback, NEVER calls SetTexture() — only toggles SetAlpha(1) / SetAlpha(0.005)!
-- ============================================================================
local function EnsureTextureStack(parentFrame, primaryTex, insetPx)
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

local function PreloadTextureStackForSnap(primaryTex, snap)
    if not primaryTex then return end
    local stack = primaryTex.avSheetStack or { [1] = primaryTex }
    if not snap or snap.cleared then
        stack[1]:SetTexture("Interface\\PaperDoll\\UI-Backpack-EmptySlot")
        stack[1]:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        stack[1]:SetAlpha(1)
        for s = 2, #stack do
            stack[s]:SetAlpha(0)
        end
        return
    end

    local tag = SanitizeCharTag(snap.author)
    local fSlot = math.max(1, math.min(12, tonumber(snap.fileSlot) or tonumber(snap.slotIndex) or 1))
    local basePath = SNAPSHOT_FOLDER .. string.format("%s_Slot%02d", tag, fSlot)

    if not snap.isFlipbook then
        stack[1]:SetTexture(basePath)
        stack[1]:SetAlpha(1)
        for s = 2, #stack do
            stack[s]:SetAlpha(0)
        end
        return
    end

    local numSheets = math.max(1, math.min(MAX_REEL_SHEETS, tonumber(snap.reelSheets) or 15))
    -- Sheet 1 uses the base path (or _V01), Sheets 2..N preload _V02.._V16 into GPU VRAM!
    -- Setting alpha to 0.005 keeps DX12 from evicting the texture from VRAM while making it invisible!
    for s = 1, #stack do
        local t = stack[s]
        if s <= numSheets then
            local sheetPath = (s == 1) and basePath or (SNAPSHOT_FOLDER .. string.format("%s_Slot%02d_V%02d", tag, fSlot, s))
            t:SetTexture(sheetPath)
            t:SetTexCoord(0, 0.25, 0, 0.125)
            t:SetAlpha((s == 1) and 1.0 or 0.005)
        else
            t:SetAlpha(0)
        end
    end
end

local function ResolveFlipbookGlobalFrameIndex(snap)
    local numSheets = math.max(1, math.min(MAX_REEL_SHEETS, tonumber(snap and snap.reelSheets) or 15))
    local totalFrames = numSheets * 32
    local fps = math.max(8, math.min(60, tonumber(snap and snap.fps) or 24))
    local now = (GetTime and GetTime()) or 0
    if snap and snap.pingPong and totalFrames > 2 then
        local span = (totalFrames - 1) * 2
        local cycle = math.floor((now * fps) % span)
        if cycle < totalFrames then
            return cycle
        else
            return span - cycle
        end
    end
    return math.floor((now * fps) % totalFrames)
end

local function Apply2DCropAndZoomToTexture(primaryTex, snap, explicitGlobalFrame)
    if not primaryTex then return end
    local stack = primaryTex.avSheetStack or { [1] = primaryTex }
    if not snap or snap.cleared then
        stack[1]:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        stack[1]:SetAlpha(1)
        for s = 2, #stack do stack[s]:SetAlpha(0) end
        return
    end

    local zoom = math.max(100, math.min(500, tonumber(snap.zoom) or 100)) / 100
    local panX = math.max(-100, math.min(100, tonumber(snap.panX) or 0))
    local panY = math.max(-100, math.min(100, tonumber(snap.panY) or 0))
    local stretchX = math.max(50, math.min(200, tonumber(snap.stretchX) or 100)) / 100

    local baseHalf = math.max(0.05, math.min(0.50, 0.50 / zoom))
    local halfU = math.max(0.05, math.min(0.50, baseHalf * stretchX))
    local halfV = baseHalf

    local cx = 0.50 + (panX * 0.0040)
    local cy = 0.50 - (panY * 0.0040)

    local u1 = math.max(0.0, math.min(1.0 - (halfU * 2), cx - halfU))
    local u2 = math.min(1.0, u1 + (halfU * 2))
    local v1 = math.max(0.0, math.min(1.0 - (halfV * 2), cy - halfV))
    local v2 = math.min(1.0, v1 + (halfV * 2))

    if snap.isFlipbook then
        local numSheets = math.max(1, math.min(MAX_REEL_SHEETS, tonumber(snap.reelSheets) or 15))
        local totalFrames = numSheets * 32
        local globalFrame = (tonumber(explicitGlobalFrame) or ResolveFlipbookGlobalFrameIndex(snap)) % totalFrames
        local activeSheet = math.floor(globalFrame / 32) + 1
        local localFrame = globalFrame % 32

        local cols = 4
        local col = localFrame % cols
        local row = math.floor(localFrame / cols)
        local spanU = 0.25  -- 1 / 4 columns
        local spanV = 0.125 -- 1 / 8 rows
        local inset = 0.0005
        local innerU = spanU - (inset * 2)
        local innerV = spanV - (inset * 2)
        local cellU = (col * spanU) + inset
        local cellV = (row * spanV) + inset

        local cu1 = cellU + (u1 * innerU)
        local cu2 = cellU + (u2 * innerU)
        local cv1 = cellV + (v1 * innerV)
        local cv2 = cellV + (v2 * innerV)

        for s = 1, #stack do
            local t = stack[s]
            if s == activeSheet then
                t:SetTexCoord(cu1, cu2, cv1, cv2)
                t:SetAlpha(1.0)
            elseif s <= numSheets then
                t:SetAlpha(0.005)
            else
                t:SetAlpha(0)
            end
        end
    else
        stack[1]:SetTexCoord(u1, u2, v1, v2)
        stack[1]:SetAlpha(1.0)
        for s = 2, #stack do
            stack[s]:SetAlpha(0)
        end
    end
end

Armory.EnsureTextureStack = EnsureTextureStack
Armory.PreloadTextureStackForSnap = PreloadTextureStackForSnap
Armory.ResolveFlipbookGlobalFrameIndex = ResolveFlipbookGlobalFrameIndex
Armory.Apply2DCropAndZoomToTexture = Apply2DCropAndZoomToTexture

-- ============================================================================
-- BLOCK HEADING: 3D CAMERA TRANSFORM, LIVE UNIT RESOLVER & FEATURED SNAPSHOT
-- ============================================================================
local function ApplyCameraTransformToModel(modelFrame, zoomPct, rotationRad, panX, panY, poseIdx)
    if not modelFrame then return end
    zoomPct = math.max(50, math.min(220, tonumber(zoomPct) or 100))
    rotationRad = tonumber(rotationRad) or 0
    panX = math.max(-100, math.min(100, tonumber(panX) or 0))
    panY = math.max(-100, math.min(100, tonumber(panY) or 0))

    local scaleFactor = zoomPct / 100
    if modelFrame.SetModelScale then
        pcall(modelFrame.SetModelScale, modelFrame, scaleFactor)
    end
    if modelFrame.SetCamDistanceScale then
        local camDist = 1.25 / math.max(0.45, scaleFactor)
        pcall(modelFrame.SetCamDistanceScale, modelFrame, camDist)
    end
    if modelFrame.SetPortraitZoom then
        local pZoom = math.max(0.0, math.min(1.0, (zoomPct - 60) / 120))
        pcall(modelFrame.SetPortraitZoom, modelFrame, pZoom)
    end
    if modelFrame.SetPosition then
        local yOffset = panX * 0.012
        local zOffset = (panY * 0.012) + ((scaleFactor < 1.0) and ((1.0 - scaleFactor) * -0.30) or 0)
        pcall(modelFrame.SetPosition, modelFrame, 0, yOffset, zOffset)
    end
    if modelFrame.SetFacing then
        pcall(modelFrame.SetFacing, modelFrame, rotationRad)
    elseif modelFrame.SetRotation then
        pcall(modelFrame.SetRotation, modelFrame, rotationRad)
    end
    if poseIdx ~= nil then
        SetModelLoopingPose(modelFrame, poseIdx)
    end
end

local function FindLiveUnitTokenForName(charName)
    if not charName then return nil end
    if charName == UnitName("player") then return "player" end
    if UnitExists("target") and UnitIsPlayer("target") and UnitName("target") == charName then
        return "target"
    end
    for i = 1, 4 do
        local u = "party" .. i
        if UnitExists(u) and UnitName(u) == charName then return u end
    end
    for i = 1, 40 do
        local u = "raid" .. i
        if UnitExists(u) and UnitName(u) == charName then return u end
    end
    return nil
end

local function GetSavedModelZoom(charName)
    if AltVaultDB and AltVaultDB.ModelZoomByChar and charName and AltVaultDB.ModelZoomByChar[charName] then
        return AltVaultDB.ModelZoomByChar[charName]
    end
    return (AltVaultDB and AltVaultDB.ModelZoomPct) or 95
end

local function ResolveFeaturedSnapshotForCharacter(charName)
    if not charName then return nil end
    local tag = SanitizeCharTag(charName)

    if ns.NetUI and ns.NetUI.EnsureCharacterAlbumSlotsPopulated then
        ns.NetUI.EnsureCharacterAlbumSlotsPopulated(charName)
    end

    local album = (AltVaultDB and AltVaultDB.PhotoAlbum) or {}
    local avatars = (AltVaultDB and AltVaultDB.CharacterAvatars) or {}

    local featuredID = avatars[charName]
    if featuredID and album[featuredID] and album[featuredID].author == charName then
        return album[featuredID]
    end

    local cData = AltVaultDB and AltVaultDB.Characters and AltVaultDB.Characters[charName]
    if cData and cData.profileSnapshot and cData.profileSnapshot.author == charName then
        cData.profileSnapshot.filePath = SNAPSHOT_FOLDER .. string.format("%s_Slot%02d", tag, tonumber(cData.profileSnapshot.fileSlot) or 1)
        cData.profileSnapshot.canvasFile = string.format("%s_Slot%02d.tga", tag, tonumber(cData.profileSnapshot.fileSlot) or 1)
        return cData.profileSnapshot
    end

    local slot1Key = string.format("%s_Slot1", charName)
    if album[slot1Key] then
        return album[slot1Key]
    end

    return {
        id = slot1Key,
        author = charName,
        slotIndex = 1,
        fileSlot = 1,
        canvasFile = string.format("%s_Slot01.tga", tag),
        filePath = SNAPSHOT_FOLDER .. string.format("%s_Slot01", tag),
        zoom = 100,
        panX = 0,
        panY = 0,
        stretchX = 100,
        isFlipbook = false,
        reelSheets = 15,
        pingPong = false,
        fps = 24,
        caption = charName .. "'s Profile Photo",
    }
end

Armory.ApplyCameraTransformToModel = ApplyCameraTransformToModel
Armory.FindLiveUnitTokenForName = FindLiveUnitTokenForName
Armory.GetSavedModelZoom = GetSavedModelZoom
Armory.ResolveFeaturedSnapshotForCharacter = ResolveFeaturedSnapshotForCharacter