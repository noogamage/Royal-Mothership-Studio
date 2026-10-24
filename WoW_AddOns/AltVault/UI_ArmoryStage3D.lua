-- ============================================================================
-- FILE: UI_ArmoryStage3D.lua (MODULE 2 OF 3 FOR TAB 1 VISUAL ARMORY)
-- BLOCK HEADING: 1920x1009 DUAL STAGE, OFFLINE/PEER 3D DRESSER & 19 SLOTS
-- ============================================================================
local addonName, ns = ...
local MainPanel = _G.AltVaultMainPanel
local Armory = ns.Armory
if not MainPanel or not Armory then return end

local CreateBackdrop = Armory.CreateBackdrop
local SetSolid = Armory.SetSolid
local STANDARD_FONT = Armory.STANDARD_FONT
local MASTER_ASPECT_RATIO = Armory.MASTER_ASPECT_RATIO

local SetModelLoopingPose = Armory.SetModelLoopingPose
local TickModelLoopingPose = Armory.TickModelLoopingPose
local HidePoseDropdownMenu = Armory.HidePoseDropdownMenu
local TogglePoseDropdownMenu = Armory.TogglePoseDropdownMenu

local EnsureTextureStack = Armory.EnsureTextureStack
local PreloadTextureStackForSnap = Armory.PreloadTextureStackForSnap
local ResolveFlipbookGlobalFrameIndex = Armory.ResolveFlipbookGlobalFrameIndex
local Apply2DCropAndZoomToTexture = Armory.Apply2DCropAndZoomToTexture

local ApplyCameraTransformToModel = Armory.ApplyCameraTransformToModel
local FindLiveUnitTokenForName = Armory.FindLiveUnitTokenForName
local GetSavedModelZoom = Armory.GetSavedModelZoom
local ResolveFeaturedSnapshotForCharacter = Armory.ResolveFeaturedSnapshotForCharacter

-- ============================================================================
-- BLOCK HEADING: WOW RACE & GENDER ID MAP FOR OFFLINE / PEER 3D STAGING
-- ============================================================================
local RACE_TO_CUSTOM_MODEL_ID = {
    ["Human"]               = 1,
    ["Orc"]                 = 2,
    ["Dwarf"]               = 3,
    ["Night Elf"]           = 4,
    ["NightElf"]            = 4,
    ["Undead"]              = 5,
    ["Scourge"]             = 5,
    ["Tauren"]              = 6,
    ["Gnome"]               = 7,
    ["Troll"]               = 8,
    ["Goblin"]              = 9,
    ["Blood Elf"]           = 10,
    ["BloodElf"]            = 10,
    ["Draenei"]             = 11,
    ["Worgen"]              = 22,
    ["Pandaren"]            = 24,
    ["High Elf"]            = 95,
    ["HighElf"]             = 95,
    ["High Order Skyborne"] = 95,
    ["HighOrderSkyborne"]   = 95,
    ["Void Elf"]            = 10,
    ["Nightborne"]          = 4,
    ["Windshaper Skyborne"] = 96,
    ["WindshaperSkyborne"]  = 96,
    ["Skyborne"]            = 95,
    ["Lightforged Draenei"] = 11,
    ["Dark Iron Dwarf"]     = 3,
    ["Highmountain Tauren"] = 6,
    ["Zandalari Troll"]     = 8,
    ["Mag'har Orc"]         = 2,
}

local RACE_MANNEQUIN_NPCS = {
    [1]  = { male = 1976,  female = 1423  }, -- Human
    [2]  = { male = 3296,  female = 14304 }, -- Orc
    [3]  = { male = 5595,  female = 13076 }, -- Dwarf
    [4]  = { male = 4262,  female = 4261  }, -- Night Elf
    [5]  = { male = 5624,  female = 14910 }, -- Undead
    [6]  = { male = 3084,  female = 14720 }, -- Tauren
    [7]  = { male = 7937,  female = 7954  }, -- Gnome
    [8]  = { male = 5973,  female = 14567 }, -- Troll
    [9]  = { male = 34668, female = 34673 }, -- Goblin
    [10] = { male = 16222, female = 15298 }, -- Blood Elf / High Elf / Skyborne
    [11] = { male = 16733, female = 16734 }, -- Draenei
    [22] = { male = 34913, female = 35378 }, -- Worgen
    [24] = { male = 53566, female = 53565 }, -- Pandaren
}

local VISIBLE_DRESS_SLOTS = { 1, 3, 4, 5, 6, 7, 8, 9, 10, 15, 16, 17, 19 }

-- ============================================================================
-- BLOCK HEADING: PAPERDOLL STAGE & SAFE TAB HIDER
-- ============================================================================
local ArmoryCanvas = CreateFrame("Frame", "AltVaultArmoryCanvas", MainPanel)
ArmoryCanvas:SetPoint("TOPLEFT", MainPanel, "TOPLEFT", 215, -96)
ArmoryCanvas:SetPoint("BOTTOMRIGHT", MainPanel, "BOTTOMRIGHT", -16, 16)
ArmoryCanvas:Hide()

local ExitFullScreenStageMode -- forward declaration

function MainPanel:HideArmoryCanvas()
    if Armory.state.isFullScreenStage and MainPanel:GetActiveViewMode() ~= "ARMORY" and ExitFullScreenStageMode then
        ExitFullScreenStageMode()
    end
    if not Armory.state.isFullScreenStage then
        ArmoryCanvas:Hide()
        if HidePoseDropdownMenu then HidePoseDropdownMenu() end
    end
    if MainPanel:GetActiveViewMode() ~= "PHOTO_ALBUM" and ns.NetUI and ns.NetUI.AlbumCanvas then
        ns.NetUI.AlbumCanvas:Hide()
    end
end

local origHideListAndDB = MainPanel.HideListAndDBFrames
function MainPanel:HideListAndDBFrames()
    if origHideListAndDB then
        origHideListAndDB(self)
    end
    if MainPanel:GetActiveViewMode() ~= "PHOTO_ALBUM" and ns.NetUI and ns.NetUI.AlbumCanvas then
        ns.NetUI.AlbumCanvas:Hide()
    end
end

local PaperDollStage = CreateBackdrop("Frame", "AltVaultPaperDollStage", ArmoryCanvas)
if PaperDollStage.SetBackdrop then
    PaperDollStage:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
        tile = true, tileSize = 32, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    PaperDollStage:SetBackdropColor(0.03, 0.04, 0.06, 0.96)
    PaperDollStage:SetBackdropBorderColor(0.85, 0.70, 0.25, 0.95)
end

local StageHeaderText = PaperDollStage:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
StageHeaderText:SetPoint("TOP", PaperDollStage, "TOP", 0, -9)
StageHeaderText:SetFont(STANDARD_FONT, 20, "OUTLINE")

Armory.ArmoryCanvas = ArmoryCanvas
Armory.PaperDollStage = PaperDollStage
Armory.StageHeaderText = StageHeaderText

-- ============================================================================
-- BLOCK HEADING: TWO CANVASES LOCKED TO 1920x1009 ASPECT RATIO (1.903 : 1)
-- ============================================================================
local ModelViewport = CreateBackdrop("Frame", "AltVaultModelViewport", PaperDollStage)
ModelViewport:SetClipsChildren(true)
if ModelViewport.SetBackdrop then
    ModelViewport:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    ModelViewport:SetBackdropColor(0.01, 0.01, 0.02, 0.96)
    ModelViewport:SetBackdropBorderColor(0.35, 0.30, 0.20, 0.85)
end
Armory.ModelViewport = ModelViewport

local SyncedAspectFrame = CreateFrame("Frame", "AltVaultSyncedAspectFrame", ModelViewport)
SyncedAspectFrame:SetPoint("CENTER", ModelViewport, "CENTER", 0, 0)
SyncedAspectFrame:SetSize(480, 252)

local function EnforceMasterAspectOnTab1Viewport()
    local vw = (ModelViewport:GetWidth() or 480) - 6
    local vh = (ModelViewport:GetHeight() or 252) - 6
    if vw <= 20 or vh <= 20 then return end

    local targetW = vw
    local targetH = math.floor((targetW / MASTER_ASPECT_RATIO) + 0.5)
    if targetH > vh then
        targetH = vh
        targetW = math.floor((targetH * MASTER_ASPECT_RATIO) + 0.5)
    end
    SyncedAspectFrame:SetSize(math.max(64, targetW), math.max(36, targetH))
end

ModelViewport:SetScript("OnSizeChanged", function()
    EnforceMasterAspectOnTab1Viewport()
end)

local LiveStageCanvas = CreateFrame("Frame", "AltVaultLiveStageCanvas", SyncedAspectFrame)
LiveStageCanvas:SetAllPoints(SyncedAspectFrame)

local LiveBgTint = LiveStageCanvas:CreateTexture(nil, "BACKGROUND")
LiveBgTint:SetAllPoints(LiveStageCanvas)
SetSolid(LiveBgTint, 0.02, 0.03, 0.05, 0.96)

local okModel, CharModel = pcall(CreateFrame, "DressUpModel", "AltVaultPaperDollModel", LiveStageCanvas)
if not okModel or not CharModel then
    CharModel = CreateFrame("PlayerModel", "AltVaultPaperDollModel", LiveStageCanvas)
end
CharModel:SetAllPoints(LiveStageCanvas)
CharModel:EnableMouse(true)
CharModel:EnableMouseWheel(true)
Armory.CharModel = CharModel

local FlatPhotoCanvas = CreateFrame("Button", "AltVaultFlatPhotoCanvas", SyncedAspectFrame)
FlatPhotoCanvas:SetAllPoints(SyncedAspectFrame)
FlatPhotoCanvas:SetClipsChildren(true)
FlatPhotoCanvas:Hide()
Armory.FlatPhotoCanvas = FlatPhotoCanvas

local FlatPhotoBg = FlatPhotoCanvas:CreateTexture(nil, "BACKGROUND")
FlatPhotoBg:SetAllPoints(FlatPhotoCanvas)
SetSolid(FlatPhotoBg, 0.02, 0.03, 0.05, 0.98)

local FlatPhotoTex = FlatPhotoCanvas:CreateTexture(nil, "ARTWORK")
FlatPhotoTex:SetAllPoints(FlatPhotoCanvas)
EnsureTextureStack(FlatPhotoCanvas, FlatPhotoTex, 0)

local lastFlatFlipFrame = -1
FlatPhotoCanvas:SetScript("OnUpdate", function()
    local curName = Armory.state.activeDisplayedCharName
    local snap = curName and ResolveFeaturedSnapshotForCharacter(curName)
    if not snap or not snap.isFlipbook or snap.cleared then return end
    local fIdx = ResolveFlipbookGlobalFrameIndex(snap)
    if fIdx ~= lastFlatFlipFrame then
        lastFlatFlipFrame = fIdx
        Apply2DCropAndZoomToTexture(FlatPhotoTex, snap, fIdx)
    end
end)

FlatPhotoCanvas:SetScript("OnClick", function()
    if Armory.state.isFullScreenStage then
        return
    end
    MainPanel:SwitchToTab("PHOTO_ALBUM")
end)

local PhotoBannerOverlay = CreateFrame("Frame", nil, ModelViewport)
PhotoBannerOverlay:SetAllPoints(ModelViewport)
PhotoBannerOverlay:SetFrameLevel(ModelViewport:GetFrameLevel() + 15)

local PhotoBannerTopText = PhotoBannerOverlay:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
PhotoBannerTopText:SetPoint("TOP", PhotoBannerOverlay, "TOP", 0, -6)
PhotoBannerTopText:SetFont(STANDARD_FONT, 11, "OUTLINE")

local PhotoBannerBottomText = PhotoBannerOverlay:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
PhotoBannerBottomText:SetPoint("BOTTOM", PhotoBannerOverlay, "BOTTOM", 0, 6)
PhotoBannerBottomText:SetFont(STANDARD_FONT, 11, "OUTLINE")

-- ============================================================================
-- BLOCK HEADING: TRUE FULL-SCREEN 1920x1009 SCREENSHOT STAGE MODE
-- ============================================================================
local FullScreenToolbar = CreateBackdrop("Frame", "AltVaultFullScreenStageBar", ModelViewport)
FullScreenToolbar:SetSize(680, 44)
FullScreenToolbar:SetPoint("BOTTOM", ModelViewport, "BOTTOM", 0, 18)
FullScreenToolbar:SetFrameLevel(ModelViewport:GetFrameLevel() + 30)
if FullScreenToolbar.SetBackdrop then
    FullScreenToolbar:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
        tile = true, tileSize = 32, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    FullScreenToolbar:SetBackdropColor(0.03, 0.04, 0.08, 0.96)
end
FullScreenToolbar:Hide()

local FSPoseBtn = CreateFrame("Button", nil, FullScreenToolbar, "UIPanelButtonTemplate")
FSPoseBtn:SetSize(140, 30)
FSPoseBtn:SetPoint("LEFT", FullScreenToolbar, "LEFT", 12, 0)
FSPoseBtn:SetText("|cffffd100Pose / Dance ▼|r")
if FSPoseBtn:GetFontString() then FSPoseBtn:GetFontString():SetFont(STANDARD_FONT, 12, "OUTLINE") end
FSPoseBtn:SetScript("OnClick", function(self)
    TogglePoseDropdownMenu(self, Armory.state.currentPoseIndex or 1, function(selectedIdx, poseObj)
        Armory.state.currentPoseIndex = selectedIdx
        Armory.state.isModelDancing = (poseObj.anim == 69)
        if LiveStageCanvas:IsShown() then
            SetModelLoopingPose(CharModel, selectedIdx)
        end
    end)
end)

local FSSnapBtn = CreateFrame("Button", nil, FullScreenToolbar, "UIPanelButtonTemplate")
FSSnapBtn:SetSize(175, 30)
FSSnapBtn:SetPoint("LEFT", FSPoseBtn, "RIGHT", 8, 0)
FSSnapBtn:SetText("|cff00ff96📸 Snap 1920x1009 Pic|r")
if FSSnapBtn:GetFontString() then FSSnapBtn:GetFontString():SetFont(STANDARD_FONT, 12, "OUTLINE") end

local FSCleanTextBtn = CreateFrame("Button", nil, FullScreenToolbar, "UIPanelButtonTemplate")
FSCleanTextBtn:SetSize(170, 30)
FSCleanTextBtn:SetPoint("LEFT", FSSnapBtn, "RIGHT", 8, 0)
FSCleanTextBtn:SetText("|cff88ccffToggle Banner Text|r")
if FSCleanTextBtn:GetFontString() then FSCleanTextBtn:GetFontString():SetFont(STANDARD_FONT, 11, "OUTLINE") end
FSCleanTextBtn:SetScript("OnClick", function()
    if PhotoBannerOverlay:IsShown() then
        PhotoBannerOverlay:Hide()
    else
        PhotoBannerOverlay:Show()
    end
end)

local FSExitBtn = CreateFrame("Button", nil, FullScreenToolbar, "UIPanelButtonTemplate")
FSExitBtn:SetSize(150, 30)
FSExitBtn:SetPoint("RIGHT", FullScreenToolbar, "RIGHT", -12, 0)
FSExitBtn:SetText("|cffff5555Exit Full Screen|r")
if FSExitBtn:GetFontString() then FSExitBtn:GetFontString():SetFont(STANDARD_FONT, 12, "OUTLINE") end

local function EnterFullScreenStageMode()
    if Armory.state.isFullScreenStage then return end
    Armory.state.isFullScreenStage = true

    ModelViewport:SetParent(UIParent)
    ModelViewport:SetFrameStrata("FULLSCREEN_DIALOG")
    ModelViewport:SetFrameLevel(180)
    ModelViewport:ClearAllPoints()
    ModelViewport:SetAllPoints(UIParent)
    EnforceMasterAspectOnTab1Viewport()

    FullScreenToolbar:SetFrameLevel(ModelViewport:GetFrameLevel() + 25)
    FullScreenToolbar:Show()

    if MainPanel.FullScreenBtn then
        MainPanel.FullScreenBtn:SetText("|cff00ff00Exit Full Screen|r")
        MainPanel.FullScreenBtn:LockHighlight()
    end

    if Armory.ConfigureAndDress3DCharacterModel then
        Armory.ConfigureAndDress3DCharacterModel(Armory.state.activeDisplayedCharName, Armory.state.activeDisplayedCharData)
    end
end

ExitFullScreenStageMode = function()
    if not Armory.state.isFullScreenStage then return end
    Armory.state.isFullScreenStage = false

    FullScreenToolbar:Hide()
    PhotoBannerOverlay:Show()
    if HidePoseDropdownMenu then HidePoseDropdownMenu() end

    ModelViewport:SetParent(PaperDollStage)
    ModelViewport:SetFrameStrata(PaperDollStage:GetFrameStrata())
    ModelViewport:SetFrameLevel(PaperDollStage:GetFrameLevel() + 2)

    if MainPanel.FullScreenBtn then
        MainPanel.FullScreenBtn:SetText("|cffffd100Full Screen|r")
        MainPanel.FullScreenBtn:UnlockHighlight()
    end

    if MainPanel.UpdateLayoutSizes then
        MainPanel:UpdateLayoutSizes()
    end
    EnforceMasterAspectOnTab1Viewport()
    if Armory.ConfigureAndDress3DCharacterModel then
        Armory.ConfigureAndDress3DCharacterModel(Armory.state.activeDisplayedCharName, Armory.state.activeDisplayedCharData)
    end
end

Armory.EnterFullScreenStageMode = EnterFullScreenStageMode
Armory.ExitFullScreenStageMode = ExitFullScreenStageMode

FSExitBtn:SetScript("OnClick", function()
    ExitFullScreenStageMode()
end)

MainPanel:HookScript("OnHide", function()
    if Armory.state.isFullScreenStage then
        ExitFullScreenStageMode()
    end
end)

if MainPanel.TopHeaderBar and not MainPanel.FullScreenBtn then
    local fsBtn = CreateFrame("Button", "AltVaultFullScreenToggleBtn", MainPanel.TopHeaderBar, "UIPanelButtonTemplate")
    fsBtn:SetSize(96, 26)
    fsBtn:SetPoint("RIGHT", MainPanel.TopHeaderBar, "RIGHT", -12, 0)
    fsBtn:SetText("|cffffd100Full Screen|r")
    if fsBtn:GetFontString() then
        fsBtn:GetFontString():SetFont(STANDARD_FONT, 11, "OUTLINE")
    end

    fsBtn:SetScript("OnClick", function()
        if Armory.state.isFullScreenStage then
            ExitFullScreenStageMode()
        else
            if MainPanel:GetActiveViewMode() ~= "ARMORY" then
                MainPanel:SwitchToTab("ARMORY")
            end
            EnterFullScreenStageMode()
        end
    end)
    MainPanel.FullScreenBtn = fsBtn
end

-- ============================================================================
-- BLOCK HEADING: 3D MODEL DRAG ROTATE / PAN / WHEEL ZOOM & OFFLINE 3D DRESSER
-- ============================================================================
local isDraggingRotate = false
local isDraggingPan = false
local dragStartX, dragStartY = 0, 0

CharModel:SetScript("OnMouseDown", function(self, button)
    local x, y = GetCursorPosition()
    dragStartX, dragStartY = x, y
    if button == "LeftButton" then
        isDraggingRotate = true
    elseif button == "RightButton" then
        isDraggingPan = true
    end
end)

CharModel:SetScript("OnMouseUp", function()
    isDraggingRotate = false
    isDraggingPan = false
end)

CharModel:SetScript("OnUpdate", function(self, elapsed)
    TickModelLoopingPose(self, elapsed)

    if isDraggingRotate or isDraggingPan then
        local curX, curY = GetCursorPosition()
        local dx = curX - dragStartX
        local dy = curY - dragStartY
        dragStartX, dragStartY = curX, curY

        if isDraggingRotate then
            Armory.state.currentRotation = (Armory.state.currentRotation or 0) + (dx * 0.015)
        elseif isDraggingPan then
            Armory.state.currentPanX = math.max(-100, math.min(100, (Armory.state.currentPanX or 0) + (dx * 0.35)))
            Armory.state.currentPanY = math.max(-100, math.min(100, (Armory.state.currentPanY or 0) + (dy * 0.35)))
        end
        local curZoom = GetSavedModelZoom(Armory.state.activeDisplayedCharName)
        ApplyCameraTransformToModel(self, curZoom, Armory.state.currentRotation, Armory.state.currentPanX, Armory.state.currentPanY, nil)
    end
end)

CharModel:SetScript("OnMouseWheel", function(self, delta)
    local curName = Armory.state.activeDisplayedCharName
    local curZoom = GetSavedModelZoom(curName)
    local newZoom = math.max(50, math.min(180, curZoom + (delta * 8)))
    if AltVaultDB then
        AltVaultDB.ModelZoomPct = newZoom
        AltVaultDB.ModelZoomByChar = AltVaultDB.ModelZoomByChar or {}
        if curName then AltVaultDB.ModelZoomByChar[curName] = newZoom end
    end
    if Armory.ModelZoomSlider then
        Armory.state.isUpdatingZoomSlider = true
        Armory.ModelZoomSlider:SetValue(newZoom)
        if Armory.zoomTitle then Armory.zoomTitle:SetText("Zoom: " .. newZoom .. "%") end
        Armory.state.isUpdatingZoomSlider = false
    end
    ApplyCameraTransformToModel(self, newZoom, Armory.state.currentRotation, Armory.state.currentPanX, Armory.state.currentPanY, nil)
end)

local function ApplyCharacterModelZoom(pct)
    pct = math.max(50, math.min(180, tonumber(pct) or 95))
    if LiveStageCanvas:IsShown() then
        ApplyCameraTransformToModel(
            CharModel,
            pct,
            Armory.state.currentRotation or 0,
            Armory.state.currentPanX or 0,
            Armory.state.currentPanY or 0,
            nil
        )
    elseif FlatPhotoCanvas:IsShown() then
        local curName = Armory.state.activeDisplayedCharName
        local snap = ResolveFeaturedSnapshotForCharacter(curName)
        if snap then
            Apply2DCropAndZoomToTexture(FlatPhotoTex, snap)
        end
    end
end

local function TriggerModelDanceEmote(enableDance)
    Armory.state.isModelDancing = enableDance and true or false
    if enableDance then
        Armory.state.currentPoseIndex = 2
    end
    if LiveStageCanvas:IsShown() then
        SetModelLoopingPose(CharModel, Armory.state.currentPoseIndex or 1)
    end
end

-- Spawns a 3D Character Model for ANY offline alt or synced guildmate using their Race, Sex, and Gear IDs!
local function DressOfflineOrSyncedPeerIn3D(charName, charData)
    if not charData then return false end

    if CharModel.ClearModel then pcall(CharModel.ClearModel, CharModel) end

    local raceKey = charData.raceFile or charData.race or "Human"
    local raceID = RACE_TO_CUSTOM_MODEL_ID[raceKey] or 1
    -- WoW UnitSex: 2 = Male, 3 = Female -> 0 = Male, 1 = Female
    local sexNum = tonumber(charData.sex) or 2
    local isFemale = (sexNum == 3)
    local npcPair = RACE_MANNEQUIN_NPCS[raceID] or RACE_MANNEQUIN_NPCS[10] or RACE_MANNEQUIN_NPCS[1]
    local npcID = isFemale and npcPair.female or npcPair.male

    -- CRITICAL FOREVER 16001 FIX: Initialize with SetUnit("player") + SetCustomRace(raceID, gender) FIRST!
    -- Creature models have baked skins and ignore Undress()/TryOn(). Player models with SetCustomRace
    -- accept Undress() and all 19 equipment slots via TryOn("item:ID")!
    local setOk = pcall(CharModel.SetUnit, CharModel, "player")
    if setOk and CharModel.SetCustomRace then
        local customOk = pcall(CharModel.SetCustomRace, CharModel, raceID, isFemale and 1 or 0)
        if not customOk and (raceID == 95 or raceID == 96) then
            pcall(CharModel.SetCustomRace, CharModel, 10, isFemale and 1 or 0)
        end
    elseif not setOk and npcID and npcID > 0 and CharModel.SetCreature then
        pcall(CharModel.SetCreature, CharModel, npcID)
    end

    if CharModel.Undress then
        pcall(CharModel.Undress, CharModel)
    end

    -- Support custom FaceVault Runway Outfits overriding base gear when viewing a posted look!
    local gearTbl = (charData.runwayOutfit and next(charData.runwayOutfit) and charData.runwayOutfit)
        or charData.gear
        or {}
    local equippedCount = 0

    local function TryOnGearPieces()
        if not CharModel.TryOn then return end
        if CharModel.Undress then pcall(CharModel.Undress, CharModel) end
        for _, slotID in ipairs(VISIBLE_DRESS_SLOTS) do
            local rawItem = (Armory.state.triedOnSlots and Armory.state.triedOnSlots[slotID]) or gearTbl[slotID]
            if rawItem then
                local itemID = (type(rawItem) == "number" and rawItem)
                    or tonumber(string.match(tostring(rawItem), "item:(%d+)"))
                    or tonumber(rawItem)
                if itemID and itemID > 0 then
                    if C_Item and C_Item.RequestLoadItemDataByID then
                        pcall(C_Item.RequestLoadItemDataByID, itemID)
                    end
                    local tryArg = (type(rawItem) == "string" and string.find(rawItem, "item:")) and rawItem or ("item:" .. tostring(itemID))
                    pcall(CharModel.TryOn, CharModel, tryArg)
                    equippedCount = equippedCount + 1
                end
            end
        end
    end

    TryOnGearPieces()
    -- Second pass after 0.15s and 0.45s in case any uncached items just streamed in from the server
    for _, delaySec in ipairs({ 0.15, 0.45 }) do
        C_Timer.After(delaySec, function()
            if Armory.state.activeDisplayedCharName == charName and LiveStageCanvas:IsShown() then
                TryOnGearPieces()
                local zoomToUse = GetSavedModelZoom(charName)
                local poseToUse = charData.runwayPose or Armory.state.currentPoseIndex or 1
                ApplyCameraTransformToModel(
                    CharModel,
                    zoomToUse,
                    Armory.state.currentRotation or 0,
                    Armory.state.currentPanX or 0,
                    Armory.state.currentPanY or 0,
                    poseToUse
                )
            end
        end)
    end

    return true, equippedCount
end

local EQUIPLOC_TO_SLOT_ID = {
    INVTYPE_HEAD = 1, INVTYPE_SHOULDER = 3, INVTYPE_BODY = 4, INVTYPE_CHEST = 5,
    INVTYPE_ROBE = 5, INVTYPE_WAIST = 6, INVTYPE_LEGS = 7, INVTYPE_FEET = 8,
    INVTYPE_WRIST = 9, INVTYPE_HAND = 10, INVTYPE_CLOAK = 15, INVTYPE_WEAPON = 16,
    INVTYPE_2HWEAPON = 16, INVTYPE_WEAPONMAINHAND = 16, INVTYPE_WEAPONOFFHAND = 17,
    INVTYPE_SHIELD = 17, INVTYPE_HOLDABLE = 17, INVTYPE_RANGED = 16,
    INVTYPE_RANGEDRIGHT = 16, INVTYPE_TABARD = 19,
}

-- Allows Tab 6 (Item Database) or any item click to Try On any Item ID or Set on the active 3D Stage!
function Armory.TryOnItemOn3DStage(itemLinkOrID)
    if not itemLinkOrID then return end
    FlatPhotoCanvas:Hide()
    LiveStageCanvas:Show()
    local itemID = (type(itemLinkOrID) == "number" and itemLinkOrID)
        or tonumber(string.match(tostring(itemLinkOrID), "item:(%d+)"))
        or tonumber(itemLinkOrID)
    if itemID and itemID > 0 then
        Armory.state.triedOnSlots = Armory.state.triedOnSlots or {}
        local eqLoc = nil
        if ns.ForeverIndex and ns.ForeverIndex.Info then
            local info = ns.ForeverIndex:Info(itemID)
            eqLoc = info and info.equipLoc
        end
        if (not eqLoc or eqLoc == "") and ns.Scanner and ns.Scanner.FetchItemInfo then
            local _, _, _, _, _, _, _, _, loc = ns.Scanner.FetchItemInfo(itemID)
            eqLoc = loc
        end
        local slotID = eqLoc and EQUIPLOC_TO_SLOT_ID[eqLoc]
        if slotID then
            Armory.state.triedOnSlots[slotID] = itemID
        end
    end
    if CharModel and CharModel.TryOn then
        local tryArg = (type(itemLinkOrID) == "number") and ("item:" .. tostring(itemLinkOrID)) or tostring(itemLinkOrID)
        pcall(CharModel.TryOn, CharModel, tryArg)
    end
end

local function ConfigureAndDress3DCharacterModel(charName, charData)
    if Armory.state.activeDisplayedCharName ~= charName then
        Armory.state.triedOnSlots = {}
    end
    Armory.state.activeDisplayedCharName = charName
    Armory.state.activeDisplayedCharData = charData
    EnforceMasterAspectOnTab1Viewport()

    if Armory.UpdateNameplateGlowButtonVisual then
        Armory.UpdateNameplateGlowButtonVisual()
    end

    local liveToken = FindLiveUnitTokenForName(charName)
    local snap = ResolveFeaturedSnapshotForCharacter(charName)
    local hasValidSnap = (snap and not snap.cleared and snap.filePath)
    local hasValid2DReel = (hasValidSnap and snap.isFlipbook)
    local isOwnOfflineAlt = (not liveToken) and (AltVaultDB and AltVaultDB.Characters and AltVaultDB.Characters[charName] ~= nil)

    local show2DPhotoOrReel = false
    if liveToken then
        show2DPhotoOrReel = (Armory.state.prefer2DReelView == true) and hasValidSnap
    elseif isOwnOfflineAlt and hasValidSnap then
        -- For your own offline Alts, show their saved 2D Portrait / 20s Video Reel by default unless toggled to 3D!
        show2DPhotoOrReel = (Armory.state.prefer3DStageForOffline ~= true)
    else
        show2DPhotoOrReel = (Armory.state.prefer2DReelView == true) and hasValidSnap
    end

    if liveToken and not show2DPhotoOrReel then
        FlatPhotoCanvas:Hide()
        LiveStageCanvas:Show()

        SetSolid(LiveBgTint, 0.02, 0.03, 0.05, 0.96)
        if CharModel.ClearModel then pcall(CharModel.ClearModel, CharModel) end
        pcall(CharModel.SetUnit, CharModel, liveToken)
        if Armory.state.triedOnSlots and next(Armory.state.triedOnSlots) and CharModel.TryOn then
            for _, sID in ipairs(VISIBLE_DRESS_SLOTS) do
                local tID = Armory.state.triedOnSlots[sID]
                if tID then
                    pcall(CharModel.TryOn, CharModel, "item:" .. tostring(tID))
                end
            end
        end

        local zoomToUse = GetSavedModelZoom(charName)
        local poseToUse = Armory.state.currentPoseIndex or 1
        ApplyCameraTransformToModel(
            CharModel,
            zoomToUse,
            Armory.state.currentRotation or 0,
            Armory.state.currentPanX or 0,
            Armory.state.currentPanY or 0,
            poseToUse
        )

        PhotoBannerTopText:SetText("|cff00ff00[LIVE 3D STAGE — " .. string.upper(charName or "") .. "]|r  |cffcccccc(Drag to Rotate • Wheel to Zoom • [Pose ▼] • [📣 Post Look])|r")
        if hasValid2DReel then
            PhotoBannerBottomText:SetText("|cff00ff96HD Video Reel Available!|r |cffffd100Click [View: 3D/Reel] at top-right to toggle your 20s Video Reel.|r")
        else
            PhotoBannerBottomText:SetText("|cffffd100Try on gear in Tab 6, pick a [Pose ▼], then click [📣 Post Look] to broadcast on the FaceVault Runway!|r")
        end
    elseif not show2DPhotoOrReel and charData then
        -- OFFLINE ALT (IN 3D MODE) OR SYNCED GUILDMATE: Render them on the 3D Stage using their Race, Sex & Synced Gear!
        FlatPhotoCanvas:Hide()
        LiveStageCanvas:Show()
        SetSolid(LiveBgTint, 0.02, 0.03, 0.05, 0.96)

        DressOfflineOrSyncedPeerIn3D(charName, charData)

        local zoomToUse = GetSavedModelZoom(charName)
        local poseToUse = Armory.state.currentPoseIndex or 1
        ApplyCameraTransformToModel(
            CharModel,
            zoomToUse,
            Armory.state.currentRotation or 0,
            Armory.state.currentPanX or 0,
            Armory.state.currentPanY or 0,
            poseToUse
        )

        local raceLabel = charData.race or "Hero"
        local sexLabel = (tonumber(charData.sex) == 3) and "Female" or "Male"
        local classLabel = charData.class or ""
        PhotoBannerTopText:SetText(string.format("|cff00ccff[SYNCED 3D STAGE — %s (%s %s %s)]|r",
            string.upper(charName or "?"), sexLabel, raceLabel, classLabel))
        PhotoBannerBottomText:SetText("|cff88ccffDressed from Synced Gear IDs • Click [View: 3D/Reel] at top-right to toggle Saved Photo/Video Reel!|r")
    else
        LiveStageCanvas:Hide()
        FlatPhotoCanvas:Show()

        if snap and not snap.cleared and snap.filePath then
            PreloadTextureStackForSnap(FlatPhotoTex, snap)
            Apply2DCropAndZoomToTexture(FlatPhotoTex, snap)
            local vCount = (ns.GuildNet and ns.GuildNet.GetPhotoVoteCount and ns.GuildNet.GetPhotoVoteCount(snap.id)) or (snap.votes or 0)
            local nSheets = tonumber(snap.reelSheets) or 15
            local modeTag = snap.isFlipbook and string.format("🎬 %d-SHEET HD REEL (%d FPS)", nSheets, tonumber(snap.fps) or 24) or "PROFILE PHOTO"
            PhotoBannerTopText:SetText(string.format("|cff00ff96[%s — %s (%s)]|r  |cffffd100★ %d Votes|r",
                modeTag, string.upper(charName), snap.canvasFile or "Slot01", vCount))
            PhotoBannerBottomText:SetText(string.format("|cffffffff\"%s\"|r  |cff88ccff(Click [View: 3D/Reel] at top-right to switch to 3D Stage)|r",
                snap.caption or charName))
        else
            PreloadTextureStackForSnap(FlatPhotoTex, nil)
            PhotoBannerTopText:SetText(string.format("|cffffd100[EMPTY PROFILE SLOT — %s]|r", string.upper(charName or "?")))
            PhotoBannerBottomText:SetText("|cff88ccffClick [View: 3D/Reel] at top-right to view in 3D, or click here to open Tab 12 Album!|r")
        end
    end
end

Armory.ApplyCharacterModelZoom = ApplyCharacterModelZoom
Armory.TriggerModelDanceEmote = TriggerModelDanceEmote
Armory.ConfigureAndDress3DCharacterModel = ConfigureAndDress3DCharacterModel

-- ============================================================================
-- BLOCK HEADING: TOP OF STAGE — NAMEPLATE GLOW TOGGLE & [VIEW: 3D/REEL] BUTTONS
-- ============================================================================
local NameplateGlowBtn = CreateFrame("Button", "AltVaultNameplateGlowToggleBtn", PaperDollStage, "UIPanelButtonTemplate")
NameplateGlowBtn:SetSize(148, 22)
NameplateGlowBtn:SetPoint("TOPLEFT", PaperDollStage, "TOPLEFT", 12, -7)
if NameplateGlowBtn:GetFontString() then
    NameplateGlowBtn:GetFontString():SetFont(STANDARD_FONT, 10, "OUTLINE")
end

local function UpdateNameplateGlowButtonVisual()
    local isGlowOn = (not AltVaultDB) or (AltVaultDB.NameplateGlowEnabled ~= false)
    if isGlowOn then
        NameplateGlowBtn:SetText("|cff00ff00Nameplate Glow: ON|r")
        NameplateGlowBtn:LockHighlight()
    else
        NameplateGlowBtn:SetText("|cffaaaaaaNameplate Glow: OFF|r")
        NameplateGlowBtn:UnlockHighlight()
    end
end
Armory.UpdateNameplateGlowButtonVisual = UpdateNameplateGlowButtonVisual
UpdateNameplateGlowButtonVisual()

NameplateGlowBtn:SetScript("OnClick", function()
    if not AltVaultDB then return end
    if AltVaultDB.NameplateGlowEnabled == nil then
        AltVaultDB.NameplateGlowEnabled = true
    end
    AltVaultDB.NameplateGlowEnabled = not AltVaultDB.NameplateGlowEnabled
    UpdateNameplateGlowButtonVisual()
    if ns.GuildNet and ns.GuildNet.BroadcastNameplateBeaconState then
        ns.GuildNet.BroadcastNameplateBeaconState(AltVaultDB.NameplateGlowEnabled)
    end
    if AltVaultDB.NameplateGlowEnabled then
        print("|cff00ff00[AltVault]:|r |cffffd100Nameplate Glow is now ON!|r Nearby players with AltVault will see a Golden/Cyan glow on your nameplate in the open world.")
    else
        print("|cffffcc00[AltVault]:|r |cffaaaaaaNameplate Glow is now OFF.|r Your nameplate glow is hidden from other players in the open world.")
    end
end)

NameplateGlowBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:ClearLines()
    GameTooltip:AddLine("|cffffd100Open-World Nameplate Glow Beacon|r")
    GameTooltip:AddLine("When ON, other players nearby who have AltVault will see a Golden/Cyan glow on your nameplate so they know they can whisper-request to sync with you.", 1, 1, 1, true)
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("Turn this OFF anytime you do not want to advertise on your nameplate in the open world.", 0.75, 0.85, 1, true)
    GameTooltip:Show()
end)
NameplateGlowBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

-- ============================================================================
-- BLOCK HEADING: LEFT OF WEAPONS — ZOOM SLIDER, POSE DROPDOWN & [3D/REEL]
-- ============================================================================
local LeftControlsAnchor = CreateFrame("Frame", "AltVaultPaperDollLeftControls", PaperDollStage)
LeftControlsAnchor:SetSize(280, 38)

local ModelZoomSlider = CreateFrame("Slider", "AltVaultModelZoomSlider", LeftControlsAnchor, "OptionsSliderTemplate")
ModelZoomSlider:SetSize(78, 16)
ModelZoomSlider:SetPoint("LEFT", LeftControlsAnchor, "LEFT", 0, -4)
ModelZoomSlider:SetMinMaxValues(50, 180)
ModelZoomSlider:SetValueStep(1)
if ModelZoomSlider.SetObeyStepOnDrag then ModelZoomSlider.SetObeyStepOnDrag(ModelZoomSlider, true) end

local zoomLow = _G[ModelZoomSlider:GetName() .. "Low"]
local zoomHigh = _G[ModelZoomSlider:GetName() .. "High"]
local zoomTitle = _G[ModelZoomSlider:GetName() .. "Text"]
if zoomLow then zoomLow:SetFont(STANDARD_FONT, 8, "OUTLINE"); zoomLow:SetText("50%") end
if zoomHigh then zoomHigh:SetFont(STANDARD_FONT, 8, "OUTLINE"); zoomHigh:SetText("180%") end
if zoomTitle then zoomTitle:SetFont(STANDARD_FONT, 10, "OUTLINE"); zoomTitle:SetText("Zoom: 95%") end

ModelZoomSlider:SetScript("OnValueChanged", function(self, value)
    local pct = math.floor(value + 0.5)
    if zoomTitle then zoomTitle:SetText("Zoom: " .. pct .. "%") end
    if Armory.state.isUpdatingZoomSlider then return end
    if LiveStageCanvas:IsShown() then
        if AltVaultDB then
            AltVaultDB.ModelZoomPct = pct
            AltVaultDB.ModelZoomByChar = AltVaultDB.ModelZoomByChar or {}
            if Armory.state.activeDisplayedCharName then
                AltVaultDB.ModelZoomByChar[Armory.state.activeDisplayedCharName] = pct
            end
        end
        ApplyCharacterModelZoom(pct)
    end
end)

local DanceBtn = CreateFrame("Button", "AltVaultModelDanceBtn", LeftControlsAnchor, "UIPanelButtonTemplate")
DanceBtn:SetSize(62, 22)
DanceBtn:SetPoint("LEFT", ModelZoomSlider, "RIGHT", 5, 2)
DanceBtn:SetText("|cffffd100Pose ▼|r")
if DanceBtn:GetFontString() then
    DanceBtn:GetFontString():SetFont(STANDARD_FONT, 10, "OUTLINE")
end

DanceBtn:SetScript("OnClick", function(self)
    TogglePoseDropdownMenu(self, Armory.state.currentPoseIndex or 1, function(selectedIdx, poseObj)
        Armory.state.currentPoseIndex = selectedIdx
        Armory.state.isModelDancing = (poseObj.anim == 69)
        if LiveStageCanvas:IsShown() then
            SetModelLoopingPose(CharModel, selectedIdx)
        end
    end)
end)

local SnapPhotoBtn = CreateFrame("Button", "AltVaultArmorySnapPhotoBtn", LeftControlsAnchor, "UIPanelButtonTemplate")
SnapPhotoBtn:SetSize(62, 22)
SnapPhotoBtn:SetPoint("LEFT", DanceBtn, "RIGHT", 4, 0)
SnapPhotoBtn:SetText("|cff00ff96Snap Pic|r")
if SnapPhotoBtn:GetFontString() then
    SnapPhotoBtn:GetFontString():SetFont(STANDARD_FONT, 10, "OUTLINE")
end

local ToggleStageModeBtn = CreateFrame("Button", "AltVaultToggle3DReelBtn", PaperDollStage, "UIPanelButtonTemplate")
ToggleStageModeBtn:SetSize(104, 22)
ToggleStageModeBtn:SetPoint("TOPRIGHT", PaperDollStage, "TOPRIGHT", -12, -7)
ToggleStageModeBtn:SetText("|cff00ccffView: 3D / Reel|r")
if ToggleStageModeBtn:GetFontString() then
    ToggleStageModeBtn:GetFontString():SetFont(STANDARD_FONT, 10, "OUTLINE")
end
ToggleStageModeBtn:SetScript("OnClick", function()
    local curName = Armory.state.activeDisplayedCharName
    local liveToken = FindLiveUnitTokenForName(curName)
    if not liveToken and AltVaultDB and AltVaultDB.Characters and curName and AltVaultDB.Characters[curName] then
        Armory.state.prefer3DStageForOffline = not Armory.state.prefer3DStageForOffline
    else
        Armory.state.prefer2DReelView = not Armory.state.prefer2DReelView
    end
    ConfigureAndDress3DCharacterModel(Armory.state.activeDisplayedCharName, Armory.state.activeDisplayedCharData)
end)

local PostFaceVaultLookBtn = CreateFrame("Button", "AltVaultPostFaceVaultLookBtn", PaperDollStage, "UIPanelButtonTemplate")
PostFaceVaultLookBtn:SetSize(106, 22)
PostFaceVaultLookBtn:SetPoint("RIGHT", ToggleStageModeBtn, "LEFT", -6, 0)
PostFaceVaultLookBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
PostFaceVaultLookBtn:SetText("|cffff8000📣 Post Look|r")
if PostFaceVaultLookBtn:GetFontString() then
    PostFaceVaultLookBtn:GetFontString():SetFont(STANDARD_FONT, 10, "OUTLINE")
end
PostFaceVaultLookBtn:SetScript("OnClick", function(_, button)
    if ns.FaceVault and ns.FaceVault.PostCurrentLookToFaceVault then
        local chatChan = nil
        if button == "RightButton" then
            if IsInGuild and IsInGuild() then chatChan = "GUILD"
            elseif IsInGroup and IsInGroup() then chatChan = "PARTY" end
        end
        ns.FaceVault:PostCurrentLookToFaceVault(chatChan)
    end
end)
PostFaceVaultLookBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:ClearLines()
    GameTooltip:AddLine("|cffff8000📣 FaceVault 3D Runway Broadcast|r")
    GameTooltip:AddLine("Broadcasts your current 3D Stage Outfit (including tried-on Dress-Up items!) and Pose to the FaceVault Network so other players can view your character in 3D and vote on your look!", 1, 1, 1, true)
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("|cff00ff00Left-Click:|r Broadcast 3D Look to FaceVault & Print Clickable Link", 0.8, 0.9, 1)
    GameTooltip:AddLine("|cffffd100Right-Click:|r Broadcast + Announce in Guild/Party Chat", 0.8, 0.9, 1)
    GameTooltip:Show()
end)
PostFaceVaultLookBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

local function TriggerCleanStageScreenshot()
    PhotoBannerOverlay:Hide()
    local wasFSBarShown = FullScreenToolbar:IsShown()
    FullScreenToolbar:Hide()
    if HidePoseDropdownMenu then HidePoseDropdownMenu() end

    C_Timer.After(0.05, function()
        if Screenshot then
            pcall(Screenshot)
        end
        C_Timer.After(0.45, function()
            PhotoBannerOverlay:Show()
            if wasFSBarShown and Armory.state.isFullScreenStage then
                FullScreenToolbar:Show()
            end
        end)
    end)
end

SnapPhotoBtn:SetScript("OnClick", TriggerCleanStageScreenshot)
FSSnapBtn:SetScript("OnClick", TriggerCleanStageScreenshot)

Armory.LeftControlsAnchor = LeftControlsAnchor
Armory.ModelZoomSlider = ModelZoomSlider
Armory.zoomTitle = zoomTitle
Armory.DanceBtn = DanceBtn
Armory.SnapPhotoBtn = SnapPhotoBtn
Armory.ToggleStageModeBtn = ToggleStageModeBtn

-- ============================================================================
-- BLOCK HEADING: RIGHT OF WEAPONS — PERMANENT 1-VOTE THUMBS UP / DOWN & RANK
-- ============================================================================
local RightRatingCluster = CreateBackdrop("Frame", "AltVaultPaperDollRatingCluster", PaperDollStage)
RightRatingCluster:SetSize(166, 32)
if RightRatingCluster.SetBackdrop then
    RightRatingCluster:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    RightRatingCluster:SetBackdropColor(0.06, 0.08, 0.12, 0.94)
    RightRatingCluster:SetBackdropBorderColor(0.65, 0.55, 0.25, 0.90)
end
Armory.RightRatingCluster = RightRatingCluster

local ThumbsUpBtn = CreateFrame("Button", "AltVaultThumbsUpBtn", RightRatingCluster, "UIPanelButtonTemplate")
ThumbsUpBtn:SetSize(34, 24)
ThumbsUpBtn:SetPoint("LEFT", RightRatingCluster, "LEFT", 5, 0)
ThumbsUpBtn:SetText("|cff00ff00▲+|r")
if ThumbsUpBtn:GetFontString() then
    ThumbsUpBtn:GetFontString():SetFont(STANDARD_FONT, 12, "OUTLINE")
end

local ThumbsDownBtn = CreateFrame("Button", "AltVaultThumbsDownBtn", RightRatingCluster, "UIPanelButtonTemplate")
ThumbsDownBtn:SetSize(34, 24)
ThumbsDownBtn:SetPoint("LEFT", ThumbsUpBtn, "RIGHT", 4, 0)
ThumbsDownBtn:SetText("|cffff4444▼-|r")
if ThumbsDownBtn:GetFontString() then
    ThumbsDownBtn:GetFontString():SetFont(STANDARD_FONT, 12, "OUTLINE")
end

local RankingScoreText = RightRatingCluster:CreateFontString(nil, "OVERLAY", "GameFontNormal")
RankingScoreText:SetPoint("LEFT", ThumbsDownBtn, "RIGHT", 8, 0)
RankingScoreText:SetPoint("RIGHT", RightRatingCluster, "RIGHT", -6, 0)
RankingScoreText:SetJustifyH("CENTER")
RankingScoreText:SetFont(STANDARD_FONT, 13, "OUTLINE")

local function UpdateRatingDisplay()
    local curName = Armory.state.activeDisplayedCharName
    local totalScore, upCount, downCount, myVote = 0, 0, 0, nil
    if ns.GuildNet and ns.GuildNet.GetCharacterRatingSummary then
        totalScore, upCount, downCount, myVote = ns.GuildNet.GetCharacterRatingSummary(curName)
    end

    local colorHex = "ffd100"
    local signStr = ""
    if totalScore > 0 then
        colorHex = "00ff00"
        signStr = "+"
    elseif totalScore < 0 then
        colorHex = "ff4444"
    end
    RankingScoreText:SetText(string.format("|cffffd100Rank:|r |cff%s%s%d|r", colorHex, signStr, totalScore))

    local isOwnCharacter = (curName == UnitName("player"))
        or (AltVaultDB and AltVaultDB.Characters and curName and AltVaultDB.Characters[curName] ~= nil)

    if myVote == 1 then
        ThumbsUpBtn:LockHighlight()
        ThumbsDownBtn:UnlockHighlight()
        ThumbsUpBtn:SetAlpha(1.0)
        ThumbsDownBtn:SetAlpha(0.45)
    elseif myVote == -1 then
        ThumbsUpBtn:UnlockHighlight()
        ThumbsDownBtn:LockHighlight()
        ThumbsUpBtn:SetAlpha(0.45)
        ThumbsDownBtn:SetAlpha(1.0)
    elseif isOwnCharacter then
        ThumbsUpBtn:UnlockHighlight()
        ThumbsDownBtn:UnlockHighlight()
        ThumbsUpBtn:SetAlpha(0.50)
        ThumbsUpBtn:SetAlpha(0.50)
    else
        ThumbsUpBtn:UnlockHighlight()
        ThumbsDownBtn:UnlockHighlight()
        ThumbsUpBtn:SetAlpha(1.0)
        ThumbsUpBtn:SetAlpha(1.0)
    end
end

Armory.UpdateRatingDisplay = UpdateRatingDisplay

ThumbsUpBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
ThumbsUpBtn:SetScript("OnClick", function(_, button)
    local curName = Armory.state.activeDisplayedCharName
    if ns.GuildNet and ns.GuildNet.CastPermanentVote and curName then
        local voteWeight = 1
        if button == "RightButton" then
            voteWeight = 3 -- Crown (+3)
        elseif IsShiftKeyDown and IsShiftKeyDown() then
            voteWeight = 2 -- Fire (+2)
        end
        if ns.GuildNet.CastPermanentVote(curName, voteWeight) then
            if PlaySound then pcall(PlaySound, 856) end
        end
        UpdateRatingDisplay()
    end
end)
ThumbsUpBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:ClearLines()
    GameTooltip:AddLine("|cffffd100FaceVault Runway Reactions|r")
    GameTooltip:AddLine("|cff00ff96Left-Click:|r 👍 Like (+1 Rank)", 1, 1, 1)
    GameTooltip:AddLine("|cffff8000Shift-Click:|r 🔥 Fire Look (+2 Rank)", 1, 1, 1)
    GameTooltip:AddLine("|cffffd100Right-Click:|r 👑 Crown Royalty (+3 Rank)", 1, 1, 1)
    GameTooltip:Show()
end)
ThumbsUpBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

ThumbsDownBtn:SetScript("OnClick", function()
    local curName = Armory.state.activeDisplayedCharName
    if ns.GuildNet and ns.GuildNet.CastPermanentVote and curName then
        if ns.GuildNet.CastPermanentVote(curName, -1) then
            if PlaySound then pcall(PlaySound, 857) end
        end
        UpdateRatingDisplay()
    end
end)

-- ============================================================================
-- BLOCK HEADING: 19 PAPERDOLL EQUIPMENT SLOTS
-- ============================================================================
local LEFT_DOLL_SLOTS = {
    { id = 1,  inv = "HeadSlot",     label = "Head" },
    { id = 2,  inv = "NeckSlot",     label = "Neck" },
    { id = 3,  inv = "ShoulderSlot", label = "Shoulder" },
    { id = 15, inv = "BackSlot",     label = "Back" },
    { id = 5,  inv = "ChestSlot",    label = "Chest" },
    { id = 4,  inv = "ShirtSlot",    label = "Shirt" },
    { id = 19, inv = "TabardSlot",   label = "Tabard" },
    { id = 9,  inv = "WristSlot",    label = "Wrist" },
}

local RIGHT_DOLL_SLOTS = {
    { id = 10, inv = "HandsSlot",    label = "Hands" },
    { id = 6,  inv = "WaistSlot",    label = "Waist" },
    { id = 7,  inv = "LegsSlot",     label = "Legs" },
    { id = 8,  inv = "FeetSlot",     label = "Feet" },
    { id = 11, inv = "Finger0Slot",  label = "Ring 1" },
    { id = 12, inv = "Finger1Slot",  label = "Ring 2" },
    { id = 13, inv = "Trinket0Slot", label = "Trinket 1" },
    { id = 14, inv = "Trinket1Slot", label = "Trinket 2" },
}

local BOTTOM_DOLL_SLOTS = {
    { id = 16, inv = "MainHandSlot",       label = "Main Hand" },
    { id = 17, inv = "SecondaryHandSlot",  label = "Off Hand" },
    { id = 18, inv = "RangedSlot",         label = "Ranged / Relic" },
}

local paperDollSlotBtns = {}

local function GetEmptySlotTexture(invSlotName)
    if GetInventorySlotInfo then
        local ok, _, tex = pcall(GetInventorySlotInfo, invSlotName)
        if ok and tex then return tex end
    end
    return "Interface\\PaperDoll\\UI-Backpack-EmptySlot"
end

local function CreatePaperDollSlotButton(cfg)
    local btn = CreateBackdrop("Button", "AltVaultPaperDollSlot" .. cfg.id, PaperDollStage)
    btn:SetSize(36, 36)
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    if btn.SetBackdrop then
        btn:SetBackdrop({
            bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 10,
            insets = { left = 2, right = 2, top = 2, bottom = 2 }
        })
        btn:SetBackdropColor(0.06, 0.06, 0.08, 0.95)
        btn:SetBackdropBorderColor(0.45, 0.38, 0.22, 0.95)
    end

    btn.Icon = btn:CreateTexture(nil, "ARTWORK")
    btn.Icon:SetPoint("TOPLEFT", btn, "TOPLEFT", 3, -3)
    btn.Icon:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -3, 3)
    btn.Icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    btn.Highlight = btn:CreateTexture(nil, "HIGHLIGHT")
    btn.Highlight:SetAllPoints(btn.Icon)
    btn.Highlight:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
    btn.Highlight:SetBlendMode("ADD")

    btn.GSText = btn:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
    btn.GSText:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -2, 2)
    btn.GSText:SetFont(STANDARD_FONT, 10, "OUTLINE")

    btn.ILvlText = btn:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
    btn.ILvlText:SetPoint("TOPLEFT", btn, "TOPLEFT", 2, -2)
    btn.ILvlText:SetFont(STANDARD_FONT, 9, "OUTLINE")

    btn.slotID = cfg.id
    btn.slotLabel = cfg.label
    btn.emptyTex = GetEmptySlotTexture(cfg.inv)

    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if self.itemLink then
            GameTooltip:SetHyperlink(self.itemLink)
            if ns.Scanner and ns.Scanner.CleanTooltipRedLinesForAlt and self.ownerData then
                ns.Scanner.CleanTooltipRedLinesForAlt(GameTooltip, self.ownerData, true)
            end
            if self.itemGS and self.itemGS > 0 then
                GameTooltip:AddLine(" ")
                GameTooltip:AddDoubleLine("Slot: " .. self.slotLabel, "GearScore: " .. ns.Scanner.FormatGearScoreColor(self.itemGS), 1, 0.82, 0, 1, 1, 1)
            end
        else
            GameTooltip:ClearLines()
            GameTooltip:AddLine(self.slotLabel, 1, 0.82, 0)
            if self.itemGS and self.itemGS > 0 then
                GameTooltip:AddLine("Synced Slot GearScore: " .. ns.Scanner.FormatGearScoreColor(self.itemGS), 1, 1, 1)
            else
                GameTooltip:AddLine("Empty Equipment Slot", 0.6, 0.6, 0.6)
            end
        end
        GameTooltip:Show()
    end)

    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    btn:SetScript("OnClick", function(self)
        if self.itemLink then
            if IsModifiedClick() then
                HandleModifiedItemClick(self.itemLink)
            else
                Armory.TryOnItemOn3DStage(self.itemLink)
            end
        end
    end)

    paperDollSlotBtns[cfg.id] = btn
    return btn
end

for _, cfg in ipairs(LEFT_DOLL_SLOTS)   do CreatePaperDollSlotButton(cfg) end
for _, cfg in ipairs(RIGHT_DOLL_SLOTS)  do CreatePaperDollSlotButton(cfg) end
for _, cfg in ipairs(BOTTOM_DOLL_SLOTS) do CreatePaperDollSlotButton(cfg) end

Armory.LEFT_DOLL_SLOTS = LEFT_DOLL_SLOTS
Armory.RIGHT_DOLL_SLOTS = RIGHT_DOLL_SLOTS
Armory.BOTTOM_DOLL_SLOTS = BOTTOM_DOLL_SLOTS
Armory.paperDollSlotBtns = paperDollSlotBtns