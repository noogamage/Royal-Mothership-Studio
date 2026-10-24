-- ============================================================================
-- FILE: UI_RosterAndScannerTabs.lua (MODULE 3 OF 3 SPLIT FROM UI_MainPanel.lua)
-- BLOCK HEADING: TAB 6 COMPACT GRID, FILTER DROPDOWNS, HOVER FLYOUT & UNDOCKED 3D CLOSET
-- ============================================================================
local addonName, ns = ...
local MainPanel = _G.AltVaultMainPanel
if not MainPanel then return end

local CreateBackdrop = MainPanel.CreateBackdrop
local SetSolid = MainPanel.SetSolid
local STANDARD_FONT = MainPanel.STANDARD_FONT
local QUALITY_HEX = MainPanel.QUALITY_HEX
local GetItemIconTexture = MainPanel.GetItemIconTexture
local ScrollFrame = MainPanel.ScrollFrame
local ScrollChild = MainPanel.ScrollChild
local externalTabRenderers = MainPanel.externalTabRenderers

local MAX_SCAN_ID = 500000
local localTurboTicker = nil
local isTurboActive = false
local turboPending = {}

-- ============================================================================
-- BLOCK HEADING: RACE, SEX, CLASS, ARMOR & POSE MASTER TABLES
-- ============================================================================

local DRESS_RACES = {
    { name = "My Character", id = 0,  maleNpc = 0,     femaleNpc = 0     },
    { name = "Target Unit",  id = -1, maleNpc = -1,    femaleNpc = -1    },
    { name = "Human",        id = 1,  maleNpc = 1976,  femaleNpc = 1423  },
    { name = "Orc",          id = 2,  maleNpc = 3296,  femaleNpc = 14304 },
    { name = "Dwarf",        id = 3,  maleNpc = 5595,  femaleNpc = 13076 },
    { name = "Night Elf",    id = 4,  maleNpc = 4262,  femaleNpc = 4261  },
    { name = "Undead",       id = 5,  maleNpc = 5624,  femaleNpc = 14910 },
    { name = "Tauren",       id = 6,  maleNpc = 3084,  femaleNpc = 14720 },
    { name = "Gnome",        id = 7,  maleNpc = 7937,  femaleNpc = 7954  },
    { name = "Troll",        id = 8,  maleNpc = 5973,  femaleNpc = 14567 },
    { name = "Goblin",       id = 9,  maleNpc = 34668, femaleNpc = 34673 },
    { name = "Blood Elf",    id = 10, maleNpc = 16222, femaleNpc = 15298 },
    { name = "Draenei",      id = 11, maleNpc = 16733, femaleNpc = 16734 },
    { name = "High Order Skyborne", id = 95, maleNpc = 16222, femaleNpc = 15298 },
    { name = "Windshaper Skyborne", id = 96, maleNpc = 16222, femaleNpc = 15298 },
    { name = "Worgen",       id = 22, maleNpc = 34913, femaleNpc = 35378 },
    { name = "Pandaren",     id = 24, maleNpc = 53566, femaleNpc = 53565 },
}

local DRESS_POSES = {
    { name = "Standing",       anim = 0   },
    { name = "Dance Loop",     anim = 69  },
    { name = "Combat 1H",      anim = 26  },
    { name = "Combat 2H",      anim = 27  },
    { name = "Bow / Gun Aim",  anim = 29  },
    { name = "Spell Channel",  anim = 51  },
    { name = "Spell Omni",     anim = 53  },
    { name = "Flex Muscles",   anim = 82  },
    { name = "Victory Cheer",  anim = 68  },
    { name = "Battle Roar",    anim = 74  },
    { name = "Kneel Pose",     anim = 119 },
    { name = "Whirlwind Spin", anim = 126 },
}

local FILTER_CLASSES = {
    { label = "All Classes",  token = "ALL",         armor = nil },
    { label = "Warrior",      token = "WARRIOR",     armor = { ["Plate"]=true, ["Mail"]=true, ["Shields"]=true } },
    { label = "Paladin",      token = "PALADIN",     armor = { ["Plate"]=true, ["Mail"]=true, ["Shields"]=true } },
    { label = "Death Knight", token = "DEATHKNIGHT", armor = { ["Plate"]=true } },
    { label = "Hunter",       token = "HUNTER",      armor = { ["Mail"]=true, ["Leather"]=true } },
    { label = "Shaman",       token = "SHAMAN",      armor = { ["Mail"]=true, ["Leather"]=true, ["Shields"]=true } },
    { label = "Rogue",        token = "ROGUE",       armor = { ["Leather"]=true } },
    { label = "Druid",        token = "DRUID",       armor = { ["Leather"]=true } },
    { label = "Monk",         token = "MONK",        armor = { ["Leather"]=true } },
    { label = "Priest",       token = "PRIEST",      armor = { ["Cloth"]=true } },
    { label = "Mage",         token = "MAGE",        armor = { ["Cloth"]=true } },
    { label = "Warlock",      token = "WARLOCK",     armor = { ["Cloth"]=true } },
}

local FILTER_ARMOR_TYPES = {
    { label = "All Gear & Items",              token = "ALL"              },
    { label = "🏆 Official Forever BiS",       token = "FOREVER_BIS"      },
    { label = "💰 Early Gold & AH Flips",      token = "GOLD_FLIPS"       },
    { label = "Custom Forever (ID 180k+)",     token = "CUSTOM_FOREVER"   },
    { label = "All DB Items (Gear + Non-Gear)",token = "ALL_DB_ITEMS"     },
    { label = "Plate Armor",                   token = "Plate"            },
    { label = "Mail Armor",                    token = "Mail"             },
    { label = "Leather Armor",                 token = "Leather"          },
    { label = "Cloth Armor",                   token = "Cloth"            },
    { label = "Shields",                       token = "Shields"          },
    { label = "Cloaks / Back",                 token = "INVTYPE_CLOAK"    },
    { label = "Weapons (All)",                 token = "Weapon"           },
    { label = "Jewelry & Trinkets",            token = "JEWELRY"          },
    { label = "Recipes & Patterns",            token = "RECIPES"          },
    { label = "Bags & Containers",             token = "CONTAINERS"       },
}

local FILTER_RACES = {
    { label = "All Races",        token = "ALL",      faction = nil },
    { label = "Alliance Races",   token = "Alliance", faction = "Alliance" },
    { label = "Horde Races",      token = "Horde",    faction = "Horde" },
    { label = "Human",            token = "Human",    faction = "Alliance" },
    { label = "Dwarf",            token = "Dwarf",    faction = "Alliance" },
    { label = "Night Elf",        token = "Night Elf",faction = "Alliance" },
    { label = "Gnome",            token = "Gnome",    faction = "Alliance" },
    { label = "Draenei",          token = "Draenei",  faction = "Alliance" },
    { label = "Orc",              token = "Orc",      faction = "Horde" },
    { label = "Undead",           token = "Undead",   faction = "Horde" },
    { label = "Tauren",           token = "Tauren",   faction = "Horde" },
    { label = "Troll",            token = "Troll",    faction = "Horde" },
    { label = "Blood Elf",        token = "Blood Elf",faction = "Horde" },
}

local dbFilterState = {
    classIdx = 1,
    armorIdx = 1,
    raceIdx  = 1,
    minLvl   = nil,
    maxLvl   = nil,
    useGridView = true,
    showFavoritesOnly = false,
    autoLevelDefault = false,
    lastSeededCharKey = nil,
    currentPage = 1,
    totalPages = 1,
    qualities = {
        [0] = true,
        [1] = true,
        [2] = true,
        [3] = true,
        [4] = true,
        [5] = true,
    },
}

local dressState = {
    isPlayerUnit = true,
    raceIndex = 1,
    genderID = 0, -- 0 = Male, 1 = Female
    poseIndex = 1,
    poseTimer = 0,
    rotation = 0,
    zoom = 0.85,
    panX = 0,
    panY = 0,
    triedOnItems = {},
}

-- ============================================================================
-- BLOCK HEADING: REUSABLE FLYOUT DROPDOWN MENU ENGINE
-- ============================================================================
local ActiveFlyoutMenu = CreateBackdrop("Frame", "AltVaultTab6FlyoutMenu", UIParent)
ActiveFlyoutMenu:SetFrameStrata("TOOLTIP")
ActiveFlyoutMenu:SetFrameLevel(350)
ActiveFlyoutMenu:EnableMouse(true)
if ActiveFlyoutMenu.SetBackdrop then
    ActiveFlyoutMenu:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
        tile = true, tileSize = 16, edgeSize = 14,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    ActiveFlyoutMenu:SetBackdropColor(0.04, 0.06, 0.10, 0.98)
    ActiveFlyoutMenu:SetBackdropBorderColor(0.85, 0.70, 0.25, 0.98)
end
ActiveFlyoutMenu:Hide()
ActiveFlyoutMenu.buttons = {}

local function ShowFlyoutDropdown(anchorBtn, optionsList, currentIndex, onSelectCallback)
    if ActiveFlyoutMenu:IsShown() and ActiveFlyoutMenu.anchorBtn == anchorBtn then
        ActiveFlyoutMenu:Hide()
        return
    end
    ActiveFlyoutMenu.anchorBtn = anchorBtn

    for _, b in ipairs(ActiveFlyoutMenu.buttons) do b:Hide() end

    local dScale = math.max(0.80, math.min(2.20, (anchorBtn and anchorBtn.GetHeight and (anchorBtn:GetHeight() / 24)) or 1.0))
    local maxW = math.floor(155 * dScale + 0.5)
    local rowH = math.max(18, math.floor(22 * dScale + 0.5))
    local fontSz = math.max(9, math.min(18, math.floor(11 * dScale + 0.5)))
    for i, opt in ipairs(optionsList) do
        local btn = ActiveFlyoutMenu.buttons[i]
        if not btn then
            btn = CreateFrame("Button", nil, ActiveFlyoutMenu)
            btn.Highlight = btn:CreateTexture(nil, "HIGHLIGHT")
            btn.Highlight:SetAllPoints(btn)
            SetSolid(btn.Highlight, 1, 0.82, 0, 0.22)
            btn.Text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            btn.Text:SetPoint("LEFT", btn, "LEFT", 8, 0)
            btn.Text:SetJustifyH("LEFT")
            ActiveFlyoutMenu.buttons[i] = btn
        end
        btn:SetHeight(rowH)
        local textLabel = opt.label or opt.name or tostring(opt)
        local prefix = (i == currentIndex) and "|cff00ff00▶ |r" or "   "
        btn.Text:SetFont(STANDARD_FONT, fontSz, "OUTLINE")
        btn.Text:SetText(prefix .. textLabel)
        local tw = (btn.Text.GetStringWidth and btn.Text:GetStringWidth() or math.floor(110 * dScale)) + math.floor(26 * dScale)
        if tw > maxW then maxW = tw end

        btn:ClearAllPoints()
        btn:SetPoint("TOPLEFT", ActiveFlyoutMenu, "TOPLEFT", 6, -6 - ((i - 1) * rowH))
        btn:SetScript("OnClick", function()
            ActiveFlyoutMenu:Hide()
            onSelectCallback(i, opt)
        end)
        btn:Show()
    end

    for i = 1, #optionsList do
        ActiveFlyoutMenu.buttons[i]:SetWidth(maxW - 12)
    end

    ActiveFlyoutMenu:SetSize(maxW, (#optionsList * rowH) + 12)
    ActiveFlyoutMenu:ClearAllPoints()
    ActiveFlyoutMenu:SetPoint("TOPLEFT", anchorBtn, "BOTTOMLEFT", 0, -2)
    ActiveFlyoutMenu:Show()
end

-- ============================================================================
-- BLOCK HEADING: HOVER FLYOUT STUBS (SIDE PREVIEW WINDOW REMOVED PER USER)
-- ============================================================================
local function ShowItemHoverFlyout() end
local function HideItemHoverFlyout() end

MainPanel.ShowItemHoverFlyout = ShowItemHoverFlyout
MainPanel.HideItemHoverFlyout = HideItemHoverFlyout

-- ============================================================================
-- BLOCK HEADING: UNDOCKED, DRAGGABLE & RESIZABLE 3D DRESSING ROOM WINDOW
-- ============================================================================
local DBDressUpDrawer = CreateBackdrop("Frame", "AltVaultTab6FloatingDressUp", UIParent)
DBDressUpDrawer:SetSize(330, 490)
DBDressUpDrawer:SetPoint("TOPLEFT", MainPanel, "TOPRIGHT", 6, 0)
DBDressUpDrawer:SetFrameStrata("FULLSCREEN_DIALOG")
DBDressUpDrawer:SetFrameLevel(200)
DBDressUpDrawer:SetToplevel(true)
DBDressUpDrawer:SetMovable(true)
DBDressUpDrawer:SetClampedToScreen(true)
DBDressUpDrawer:EnableMouse(true)
if DBDressUpDrawer.SetResizable then DBDressUpDrawer:SetResizable(true) end
if DBDressUpDrawer.SetResizeBounds then
    DBDressUpDrawer:SetResizeBounds(260, 360, 760, 960)
elseif DBDressUpDrawer.SetMinResize then
    DBDressUpDrawer:SetMinResize(260, 360)
    DBDressUpDrawer:SetMaxResize(760, 960)
end

if DBDressUpDrawer.SetBackdrop then
    DBDressUpDrawer:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
        tile = true, tileSize = 32, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    DBDressUpDrawer:SetBackdropColor(0.03, 0.04, 0.07, 0.97)
    DBDressUpDrawer:SetBackdropBorderColor(0.85, 0.70, 0.25, 0.98)
end
DBDressUpDrawer:Hide()
MainPanel.DBDressUpDrawer = DBDressUpDrawer

DBDressUpDrawer:RegisterForDrag("LeftButton")
DBDressUpDrawer:SetScript("OnDragStart", function(self)
    self:Raise()
    self:StartMoving()
end)
DBDressUpDrawer:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
end)

local DressCloseBtn = CreateFrame("Button", nil, DBDressUpDrawer, "UIPanelCloseButton")
DressCloseBtn:SetPoint("TOPRIGHT", DBDressUpDrawer, "TOPRIGHT", -2, -2)

local ReDockBtn = CreateFrame("Button", nil, DBDressUpDrawer, "UIPanelButtonTemplate")
ReDockBtn:SetSize(58, 20)
ReDockBtn:SetPoint("TOPLEFT", DBDressUpDrawer, "TOPLEFT", 8, -8)
ReDockBtn:SetText("Dock")
if ReDockBtn:GetFontString() then ReDockBtn:GetFontString():SetFont(STANDARD_FONT, 10, "OUTLINE") end
ReDockBtn:SetScript("OnClick", function()
    DBDressUpDrawer:ClearAllPoints()
    DBDressUpDrawer:SetPoint("TOPLEFT", MainPanel, "TOPRIGHT", 6, 0)
    DBDressUpDrawer:SetSize(330, 490)
end)

local DressTitle = DBDressUpDrawer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
DressTitle:SetPoint("TOP", DBDressUpDrawer, "TOP", 0, -10)
DressTitle:SetFont(STANDARD_FONT, 13, "OUTLINE")
DressTitle:SetText("|cffffd1003D DRESSING ROOM|r")

local DressSubTitle = DBDressUpDrawer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
DressSubTitle:SetPoint("TOP", DressTitle, "BOTTOM", 0, -2)
DressSubTitle:SetFont(STANDARD_FONT, 10, "OUTLINE")
DressSubTitle:SetText("|cff88ccffDrag Window to Move • Drag Corner to Resize|r")

-- Bottom-Right Corner Resize Tab for the Floating Dressing Room!
local DressResizeGrip = CreateFrame("Button", nil, DBDressUpDrawer)
DressResizeGrip:SetSize(22, 22)
DressResizeGrip:SetPoint("BOTTOMRIGHT", DBDressUpDrawer, "BOTTOMRIGHT", -4, 4)
DressResizeGrip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
DressResizeGrip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
DressResizeGrip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
DressResizeGrip:SetFrameLevel(DBDressUpDrawer:GetFrameLevel() + 20)
DressResizeGrip:SetScript("OnMouseDown", function(_, button)
    if button == "LeftButton" and DBDressUpDrawer.StartSizing then
        DBDressUpDrawer:Raise()
        pcall(DBDressUpDrawer.StartSizing, DBDressUpDrawer, "BOTTOMRIGHT")
    end
end)
DressResizeGrip:SetScript("OnMouseUp", function()
    DBDressUpDrawer:StopMovingOrSizing()
end)

local okDressModel, DBTryOnModel = pcall(CreateFrame, "DressUpModel", "AltVaultTab6TryOnModel", DBDressUpDrawer)
if not okDressModel or not DBTryOnModel then
    DBTryOnModel = CreateFrame("PlayerModel", "AltVaultTab6TryOnModel", DBDressUpDrawer)
end
DBTryOnModel:SetPoint("TOPLEFT", DBDressUpDrawer, "TOPLEFT", 10, -44)
DBTryOnModel:SetPoint("BOTTOMRIGHT", DBDressUpDrawer, "BOTTOMRIGHT", -10, 68)
DBTryOnModel:EnableMouse(true)
DBTryOnModel:EnableMouseWheel(true)

local ModelBgTex = DBTryOnModel:CreateTexture(nil, "BACKGROUND")
ModelBgTex:SetAllPoints(DBTryOnModel)
SetSolid(ModelBgTex, 0.015, 0.02, 0.035, 0.95)

local LastTriedText = DBDressUpDrawer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
LastTriedText:SetPoint("BOTTOMLEFT", DBTryOnModel, "BOTTOMLEFT", 4, 4)
LastTriedText:SetPoint("BOTTOMRIGHT", DBTryOnModel, "BOTTOMRIGHT", -4, 4)
LastTriedText:SetFont(STANDARD_FONT, 10, "OUTLINE")
LastTriedText:SetText("|cffaaaaaaLeft-Drag: Rotate • Right-Drag: Pan • Wheel: Zoom|r")

local RaceCycleBtn = CreateFrame("Button", nil, DBDressUpDrawer, "UIPanelButtonTemplate")
local GenderToggleBtn = CreateFrame("Button", nil, DBDressUpDrawer, "UIPanelButtonTemplate")
local PoseCycleBtn = CreateFrame("Button", nil, DBDressUpDrawer, "UIPanelButtonTemplate")

local function ApplyTab6ModelTransform()
    if DBTryOnModel.SetFacing then
        pcall(DBTryOnModel.SetFacing, DBTryOnModel, dressState.rotation or 0)
    end
    if DBTryOnModel.SetPortraitZoom then
        pcall(DBTryOnModel.SetPortraitZoom, DBTryOnModel, 0)
    end
    if DBTryOnModel.SetCamDistanceScale then
        pcall(DBTryOnModel.SetCamDistanceScale, DBTryOnModel, dressState.zoom or 0.85)
    end
    if DBTryOnModel.SetPosition then
        pcall(DBTryOnModel.SetPosition, DBTryOnModel, 0, dressState.panX or 0, dressState.panY or 0)
    end
    local pose = DRESS_POSES[dressState.poseIndex or 1]
    if pose and DBTryOnModel.SetAnimation then
        pcall(DBTryOnModel.SetAnimation, DBTryOnModel, pose.anim)
    end
end

local function ReapplyTriedOnItems()
    if not DBTryOnModel.TryOn then return end
    for _, itemArg in ipairs(dressState.triedOnItems) do
        pcall(DBTryOnModel.TryOn, DBTryOnModel, itemArg)
    end
end

-- Syncs the Race & Sex button labels to the player's actual character
local function SyncDressButtonsToPlayer()
    local raceName, raceFile = UnitRace("player")
    local sex = UnitSex and UnitSex("player") or 2 -- 2 = Male, 3 = Female
    dressState.genderID = (sex == 3) and 1 or 0
    for i, r in ipairs(DRESS_RACES) do
        if r.name == raceName or string.gsub(r.name, "%s+", "") == tostring(raceFile or "") then
            dressState.raceIndex = i
            break
        end
    end
    local curRace = DRESS_RACES[dressState.raceIndex] or DRESS_RACES[1]
    RaceCycleBtn:SetText("Race: " .. curRace.name .. " ▼")
    GenderToggleBtn:SetText(dressState.genderID == 1 and "Sex: Female" or "Sex: Male")
end

local function ResetTab6ModelToPlayer(keepTriedItems)
    dressState.isPlayerUnit = true
    if DBTryOnModel.ClearModel then pcall(DBTryOnModel.ClearModel, DBTryOnModel) end
    pcall(DBTryOnModel.SetUnit, DBTryOnModel, "player")
    SyncDressButtonsToPlayer()

    if not keepTriedItems then
        dressState.triedOnItems = {}
        if DBTryOnModel.Dress then pcall(DBTryOnModel.Dress, DBTryOnModel) end
        LastTriedText:SetText("|cff00ff96Showing Your Active Character|r")
    else
        ReapplyTriedOnItems()
    end
    ApplyTab6ModelTransform()
end

-- Applies a custom Race & Sex (Male=0, Female=1) cleanly without white-blob DisplayIDs!
-- Switches the 3D Dressing Room between Player, Target, or Pre-Baked Male/Female Racial Mannequins
local function ApplySelectedRaceAndGenderToTab6Model()
    local raceObj = DRESS_RACES[dressState.raceIndex or 1] or DRESS_RACES[1]
    local gID = dressState.genderID or 0 -- 0 = Male, 1 = Female

    -- Snapshot player's equipped gear if triedOnItems is empty so mannequin has gear to wear
    if #dressState.triedOnItems == 0 then
        local slots = { 1, 3, 4, 5, 6, 7, 8, 9, 10, 15, 16, 17, 19 }
        for _, sID in ipairs(slots) do
            local link = GetInventoryItemLink("player", sID)
            if link then
                table.insert(dressState.triedOnItems, link)
            end
        end
    end

    if DBTryOnModel.ClearModel then pcall(DBTryOnModel.ClearModel, DBTryOnModel) end

    if raceObj.id == 0 then
        -- Option 1: Your Active Player Character
        dressState.isPlayerUnit = true
        pcall(DBTryOnModel.SetUnit, DBTryOnModel, "player")
        LastTriedText:SetText("|cff00ff96Model: Your Active Character|r")
    elseif raceObj.id == -1 then
        -- Option 2: Clone Current Target (Any Player or NPC in Range!)
        dressState.isPlayerUnit = false
        if UnitExists("target") then
            pcall(DBTryOnModel.SetUnit, DBTryOnModel, "target")
            local tName = UnitName("target") or "Target"
            LastTriedText:SetText("|cff00ff00Cloned Target:|r " .. tName)
        else
            pcall(DBTryOnModel.SetUnit, DBTryOnModel, "player")
            LastTriedText:SetText("|cffffcc00Target a player/NPC first to clone their body!|r")
        end
    else
        -- Option 3: Custom Race & Gender Mannequin via SetUnit("player") + SetCustomRace so TryOn() works on all 19 slots!
        dressState.isPlayerUnit = false
        local npcID = (gID == 1) and raceObj.femaleNpc or raceObj.maleNpc
        local okSet = pcall(DBTryOnModel.SetUnit, DBTryOnModel, "player")
        if okSet and DBTryOnModel.SetCustomRace then
            local customOk = pcall(DBTryOnModel.SetCustomRace, DBTryOnModel, raceObj.id, gID)
            if not customOk and (raceObj.id == 95 or raceObj.id == 96) then
                pcall(DBTryOnModel.SetCustomRace, DBTryOnModel, 10, gID)
            end
        elseif not okSet and npcID and npcID > 0 and DBTryOnModel.SetCreature then
            pcall(DBTryOnModel.SetCreature, DBTryOnModel, npcID)
        end
        if DBTryOnModel.Undress then
            pcall(DBTryOnModel.Undress, DBTryOnModel)
        end
        LastTriedText:SetText(string.format("|cff00ccffMannequin: %s %s (3D Dress-Up Ready)|r",
            gID == 1 and "Female" or "Male", raceObj.name))
    end

    C_Timer.After(0.08, function()
        if not DBTryOnModel:IsShown() then return end
        ReapplyTriedOnItems()
        ApplyTab6ModelTransform()
    end)

    RaceCycleBtn:SetText("Race: " .. raceObj.name .. " ▼")
    GenderToggleBtn:SetText(gID == 1 and "Sex: Female" or "Sex: Male")
end

function MainPanel:TryOnItemInTab6(itemLinkOrID, itemNameLabel)
    if not itemLinkOrID then return end

    local numID = (type(itemLinkOrID) == "number" and itemLinkOrID)
        or tonumber(string.match(tostring(itemLinkOrID), "item:(%d+)"))
        or tonumber(itemLinkOrID)

    if numID and C_Item and C_Item.RequestLoadItemDataByID then
        pcall(C_Item.RequestLoadItemDataByID, numID)
    end

    local tryArg = (type(itemLinkOrID) == "string" and string.find(itemLinkOrID, "item:"))
        and itemLinkOrID
        or ("item:" .. tostring(numID or itemLinkOrID))

    table.insert(dressState.triedOnItems, tryArg)
    if ns.Armory and ns.Armory.TryOnItemOn3DStage then
        pcall(ns.Armory.TryOnItemOn3DStage, tryArg)
    end
    if DBDressUpDrawer:IsShown() and DBTryOnModel.TryOn then
        pcall(DBTryOnModel.TryOn, DBTryOnModel, tryArg)
        C_Timer.After(0.15, function()
            if DBTryOnModel:IsShown() and DBTryOnModel.TryOn then
                pcall(DBTryOnModel.TryOn, DBTryOnModel, tryArg)
                ApplyTab6ModelTransform()
            end
        end)
    end

    local label = itemNameLabel or (numID and ("Item #" .. tostring(numID))) or tostring(itemLinkOrID)
    LastTriedText:SetText("|cff00ff00Tried On:|r " .. tostring(label) .. " |cffff8000(Ready for [📣 Post Look])|r")
end

-- Continuous Animation Loop & Mouse Drag Rotate / Pan / Wheel Zoom
local isDraggingRot6, isDraggingPan6 = false, false
local dragX6, dragY6 = 0, 0

DBTryOnModel:SetScript("OnMouseDown", function(_, btn)
    dragX6, dragY6 = GetCursorPosition()
    if btn == "LeftButton" then isDraggingRot6 = true
    elseif btn == "RightButton" then isDraggingPan6 = true end
end)

DBTryOnModel:SetScript("OnMouseUp", function()
    isDraggingRot6 = false
    isDraggingPan6 = false
end)

DBTryOnModel:SetScript("OnUpdate", function(_, elapsed)
    -- Keep chosen Pose/Dance looping continuously!
    if (dressState.poseIndex or 1) > 1 then
        dressState.poseTimer = (dressState.poseTimer or 0) + elapsed
        if dressState.poseTimer >= 0.85 then
            dressState.poseTimer = 0
            local pose = DRESS_POSES[dressState.poseIndex]
            if pose and DBTryOnModel.SetAnimation then
                pcall(DBTryOnModel.SetAnimation, DBTryOnModel, pose.anim)
            end
        end
    end

    if not isDraggingRot6 and not isDraggingPan6 then return end
    local cx, cy = GetCursorPosition()
    local dx, dy = cx - dragX6, cy - dragY6
    dragX6, dragY6 = cx, cy
    if isDraggingRot6 then
        dressState.rotation = (dressState.rotation or 0) + (dx * 0.018)
    elseif isDraggingPan6 then
        dressState.panX = math.max(-1.5, math.min(1.5, (dressState.panX or 0) + (dx * 0.004)))
        dressState.panY = math.max(-1.5, math.min(1.5, (dressState.panY or 0) + (dy * 0.004)))
    end
    ApplyTab6ModelTransform()
end)

DBTryOnModel:SetScript("OnMouseWheel", function(_, delta)
    dressState.zoom = math.max(0.35, math.min(2.2, (dressState.zoom or 0.85) - (delta * 0.08)))
    ApplyTab6ModelTransform()
end)

-- Row 1 of Dressing Room Buttons: [Race ▼] [Sex: Male/Female] [Pose ▼]
RaceCycleBtn:SetSize(102, 24)
RaceCycleBtn:SetPoint("BOTTOMLEFT", DBDressUpDrawer, "BOTTOMLEFT", 10, 36)
RaceCycleBtn:SetText("Race ▼")
if RaceCycleBtn:GetFontString() then RaceCycleBtn:GetFontString():SetFont(STANDARD_FONT, 10, "OUTLINE") end
RaceCycleBtn:SetScript("OnClick", function(self)
    ShowFlyoutDropdown(self, DRESS_RACES, dressState.raceIndex, function(idx)
        dressState.raceIndex = idx
        ApplySelectedRaceAndGenderToTab6Model()
    end)
end)

GenderToggleBtn:SetSize(84, 24)
GenderToggleBtn:SetPoint("LEFT", RaceCycleBtn, "RIGHT", 5, 0)
GenderToggleBtn:SetText("Sex: Male")
if GenderToggleBtn:GetFontString() then GenderToggleBtn:GetFontString():SetFont(STANDARD_FONT, 10, "OUTLINE") end
GenderToggleBtn:SetScript("OnClick", function()
    dressState.genderID = (dressState.genderID == 0) and 1 or 0
    ApplySelectedRaceAndGenderToTab6Model()
end)

PoseCycleBtn:SetSize(102, 24)
PoseCycleBtn:SetPoint("LEFT", GenderToggleBtn, "RIGHT", 5, 0)
PoseCycleBtn:SetText("Pose: Stand ▼")
if PoseCycleBtn:GetFontString() then PoseCycleBtn:GetFontString():SetFont(STANDARD_FONT, 10, "OUTLINE") end
PoseCycleBtn:SetScript("OnClick", function(self)
    ShowFlyoutDropdown(self, DRESS_POSES, dressState.poseIndex, function(idx, poseObj)
        dressState.poseIndex = idx
        dressState.poseTimer = 0
        self:SetText("Pose: " .. poseObj.name .. " ▼")
        ApplyTab6ModelTransform()
    end)
end)

-- Row 2 of Dressing Room Buttons: [My Char] [Undress] [📸 Snap Pic]
local ResetCharBtn = CreateFrame("Button", nil, DBDressUpDrawer, "UIPanelButtonTemplate")
ResetCharBtn:SetSize(92, 24)
ResetCharBtn:SetPoint("BOTTOMLEFT", DBDressUpDrawer, "BOTTOMLEFT", 10, 8)
ResetCharBtn:SetText("|cff00ff96My Char|r")
if ResetCharBtn:GetFontString() then ResetCharBtn:GetFontString():SetFont(STANDARD_FONT, 10, "OUTLINE") end
ResetCharBtn:SetScript("OnClick", function()
    ResetTab6ModelToPlayer(false)
end)

local UndressBtn = CreateFrame("Button", nil, DBDressUpDrawer, "UIPanelButtonTemplate")
UndressBtn:SetSize(92, 24)
UndressBtn:SetPoint("LEFT", ResetCharBtn, "RIGHT", 6, 0)
UndressBtn:SetText("|cffffcc00Undress|r")
if UndressBtn:GetFontString() then UndressBtn:GetFontString():SetFont(STANDARD_FONT, 10, "OUTLINE") end
UndressBtn:SetScript("OnClick", function()
    dressState.triedOnItems = {}
    if DBTryOnModel.Undress then pcall(DBTryOnModel.Undress, DBTryOnModel) end
    LastTriedText:SetText("|cffffcc00Undressed — Click any item to Try On!|r")
end)

local SnapDressBtn = CreateFrame("Button", nil, DBDressUpDrawer, "UIPanelButtonTemplate")
SnapDressBtn:SetSize(102, 24)
SnapDressBtn:SetPoint("LEFT", UndressBtn, "RIGHT", 6, 0)
SnapDressBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
SnapDressBtn:SetText("|cffff8000📣 Post / Snap|r")
if SnapDressBtn:GetFontString() then SnapDressBtn:GetFontString():SetFont(STANDARD_FONT, 10, "OUTLINE") end
SnapDressBtn:SetScript("OnClick", function(_, button)
    if button == "RightButton" and ns.FaceVault and ns.FaceVault.PostCurrentLookToFaceVault then
        ns.FaceVault:PostCurrentLookToFaceVault()
        LastTriedText:SetText("|cff00ff00Broadcasted 3D Look to FaceVault Runway!|r")
        return
    end
    LastTriedText:SetText("")
    C_Timer.After(0.05, function()
        if Screenshot then pcall(Screenshot) end
        C_Timer.After(0.35, function()
            LastTriedText:SetText("|cff00ff00Screenshot Saved! (Right-Click to Post Look to FaceVault)|r")
        end)
    end)
end)

local function UpdateDressUpDrawerLayoutAndScale()
    local w = DBDressUpDrawer:GetWidth() or 330
    local h = DBDressUpDrawer:GetHeight() or 490
    local s = math.max(0.78, math.min(2.25, math.min(w / 330, h / 490)))

    local padX = math.max(8, math.floor(10 * s + 0.5))
    local gap = math.max(4, math.floor(5 * s + 0.5))
    local btnH = math.max(20, math.floor(24 * s + 0.5))
    local btnFont = math.max(9, math.min(18, math.floor(10 * s + 0.5)))
    local titleFont = math.max(11, math.min(22, math.floor(13 * s + 0.5)))
    local subFont = math.max(8, math.min(16, math.floor(10 * s + 0.5)))

    DressTitle:SetFont(STANDARD_FONT, titleFont, "OUTLINE")
    DressSubTitle:SetFont(STANDARD_FONT, subFont, "OUTLINE")
    LastTriedText:SetFont(STANDARD_FONT, subFont, "OUTLINE")

    ReDockBtn:SetSize(math.floor(58 * s + 0.5), math.floor(20 * s + 0.5))
    if ReDockBtn:GetFontString() then
        ReDockBtn:GetFontString():SetFont(STANDARD_FONT, btnFont, "OUTLINE")
    end

    local gripSize = math.max(18, math.floor(22 * s + 0.5))
    DressResizeGrip:SetSize(gripSize, gripSize)

    local rowW = math.max(200, w - (padX * 2) - math.floor(gripSize * 0.65))
    local usableW = rowW - (gap * 2)

    local r1W1 = math.floor(usableW * 0.36)
    local r1W2 = math.floor(usableW * 0.28)
    local r1W3 = usableW - r1W1 - r1W2

    local r2W1 = math.floor(usableW * 0.32)
    local r2W2 = math.floor(usableW * 0.32)
    local r2W3 = usableW - r2W1 - r2W2

    local row2BottomY = math.max(6, math.floor(8 * s + 0.5))
    local row1BottomY = row2BottomY + btnH + gap

    RaceCycleBtn:ClearAllPoints()
    RaceCycleBtn:SetPoint("BOTTOMLEFT", DBDressUpDrawer, "BOTTOMLEFT", padX, row1BottomY)
    RaceCycleBtn:SetSize(r1W1, btnH)
    if RaceCycleBtn:GetFontString() then RaceCycleBtn:GetFontString():SetFont(STANDARD_FONT, btnFont, "OUTLINE") end

    GenderToggleBtn:ClearAllPoints()
    GenderToggleBtn:SetPoint("LEFT", RaceCycleBtn, "RIGHT", gap, 0)
    GenderToggleBtn:SetSize(r1W2, btnH)
    if GenderToggleBtn:GetFontString() then GenderToggleBtn:GetFontString():SetFont(STANDARD_FONT, btnFont, "OUTLINE") end

    PoseCycleBtn:ClearAllPoints()
    PoseCycleBtn:SetPoint("LEFT", GenderToggleBtn, "RIGHT", gap, 0)
    PoseCycleBtn:SetSize(r1W3, btnH)
    if PoseCycleBtn:GetFontString() then PoseCycleBtn:GetFontString():SetFont(STANDARD_FONT, btnFont, "OUTLINE") end

    ResetCharBtn:ClearAllPoints()
    ResetCharBtn:SetPoint("BOTTOMLEFT", DBDressUpDrawer, "BOTTOMLEFT", padX, row2BottomY)
    ResetCharBtn:SetSize(r2W1, btnH)
    if ResetCharBtn:GetFontString() then ResetCharBtn:GetFontString():SetFont(STANDARD_FONT, btnFont, "OUTLINE") end

    UndressBtn:ClearAllPoints()
    UndressBtn:SetPoint("LEFT", ResetCharBtn, "RIGHT", gap, 0)
    UndressBtn:SetSize(r2W2, btnH)
    if UndressBtn:GetFontString() then UndressBtn:GetFontString():SetFont(STANDARD_FONT, btnFont, "OUTLINE") end

    SnapDressBtn:ClearAllPoints()
    SnapDressBtn:SetPoint("LEFT", UndressBtn, "RIGHT", gap, 0)
    SnapDressBtn:SetSize(r2W3, btnH)
    if SnapDressBtn:GetFontString() then SnapDressBtn:GetFontString():SetFont(STANDARD_FONT, btnFont, "OUTLINE") end

    local topInset = math.max(38, math.floor(44 * s + 0.5))
    local bottomInset = row1BottomY + btnH + math.max(6, math.floor(8 * s + 0.5))
    DBTryOnModel:ClearAllPoints()
    DBTryOnModel:SetPoint("TOPLEFT", DBDressUpDrawer, "TOPLEFT", padX, -topInset)
    DBTryOnModel:SetPoint("BOTTOMRIGHT", DBDressUpDrawer, "BOTTOMRIGHT", -padX, bottomInset)
end

DBDressUpDrawer:SetScript("OnSizeChanged", function()
    UpdateDressUpDrawerLayoutAndScale()
end)

DBDressUpDrawer:SetScript("OnShow", function()
    UpdateDressUpDrawerLayoutAndScale()
    if dressState.isPlayerUnit then
        ResetTab6ModelToPlayer(#dressState.triedOnItems > 0)
    else
        ApplySelectedRaceAndGenderToTab6Model()
    end
end)

MainPanel:HookScript("OnHide", function()
    DBDressUpDrawer:Hide()
    ActiveFlyoutMenu:Hide()
    HideItemHoverFlyout()
end)

-- ============================================================================
-- BLOCK HEADING: 3-ROW TAB 6 HEADER BAR (SCANNER + SEARCH + FILTERS + QUALITY & PAGES)
-- ============================================================================
local DBHeaderFrame = CreateBackdrop("Frame", nil, MainPanel)
DBHeaderFrame:SetPoint("TOPLEFT", MainPanel, "TOPLEFT", 215, -96)
DBHeaderFrame:SetPoint("TOPRIGHT", MainPanel, "TOPRIGHT", -28, -96)
DBHeaderFrame:SetHeight(148)
if DBHeaderFrame.SetBackdrop then
    DBHeaderFrame:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    DBHeaderFrame:SetBackdropColor(0.05, 0.08, 0.12, 0.94)
    DBHeaderFrame:SetBackdropBorderColor(0.4, 0.6, 0.9, 0.85)
end
DBHeaderFrame:Hide()
MainPanel.DBHeaderFrame = DBHeaderFrame

local ScannerBar = CreateBackdrop("StatusBar", nil, DBHeaderFrame)
ScannerBar:SetPoint("TOPLEFT", DBHeaderFrame, "TOPLEFT", 10, -7)
ScannerBar:SetPoint("TOPRIGHT", DBHeaderFrame, "TOPRIGHT", -10, -7)
ScannerBar:SetHeight(22)
ScannerBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
ScannerBar:SetStatusBarColor(0.0, 0.75, 0.95, 0.9)
ScannerBar:SetMinMaxValues(1, MAX_SCAN_ID)
ScannerBar:SetValue(1)

ScannerBar.Bg = ScannerBar:CreateTexture(nil, "BACKGROUND")
ScannerBar.Bg:SetAllPoints(ScannerBar)
SetSolid(ScannerBar.Bg, 0.02, 0.02, 0.05, 0.85)

ScannerBar.Text = ScannerBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
ScannerBar.Text:SetPoint("CENTER", ScannerBar, "CENTER", 0, 0)
ScannerBar.Text:SetText("Master Holding Tank Scanner Ready...")

-- Row 1: Search, Favorites, View Mode, 3D Closet & Scanner Controls
local DBButtonRow = CreateFrame("Frame", nil, DBHeaderFrame)
DBButtonRow:SetPoint("TOPLEFT", ScannerBar, "BOTTOMLEFT", 0, -4)
DBButtonRow:SetPoint("TOPRIGHT", ScannerBar, "BOTTOMRIGHT", 0, -4)
DBButtonRow:SetHeight(32)

-- Row 2: Class, Armor/Weapon, Race Dropdowns + Level Range + Per-Page & +/- Pagination
local DBFilterRow = CreateFrame("Frame", nil, DBHeaderFrame)
DBFilterRow:SetPoint("TOPLEFT", DBButtonRow, "BOTTOMLEFT", 0, -4)
DBFilterRow:SetPoint("TOPRIGHT", DBButtonRow, "BOTTOMRIGHT", 0, -4)
DBFilterRow:SetHeight(32)

-- Row 3: Quality Toggle Bar (All Qualities, Grey, Common, Uncommon, Rare, Epic, Legend+)
local DBQualityRow = CreateFrame("Frame", nil, DBHeaderFrame)
DBQualityRow:SetPoint("TOPLEFT", DBFilterRow, "BOTTOMLEFT", 0, -4)
DBQualityRow:SetPoint("TOPRIGHT", DBFilterRow, "BOTTOMRIGHT", 0, -4)
DBQualityRow:SetHeight(30)

local SearchBox = CreateFrame("EditBox", "AltVaultDBSearchBox", DBButtonRow, "InputBoxTemplate")
SearchBox:SetSize(160, 26)
SearchBox:SetPoint("LEFT", DBButtonRow, "LEFT", 6, 0)
SearchBox:SetAutoFocus(false)
SearchBox:SetText("")

local SearchPlaceholder = SearchBox:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
SearchPlaceholder:SetPoint("LEFT", SearchBox, "LEFT", 6, 0)
SearchPlaceholder:SetPoint("RIGHT", SearchBox, "RIGHT", -6, 0)
SearchPlaceholder:SetJustifyH("LEFT")
SearchPlaceholder:SetWordWrap(false)
SearchPlaceholder:SetText("ID, Name, Boss, Zone...")

SearchBox:SetScript("OnEditFocusGained", function() SearchPlaceholder:Hide() end)
SearchBox:SetScript("OnEditFocusLost", function(self)
    if self:GetText() == "" then SearchPlaceholder:Show() end
end)

local function GetMasterItemIDList()
    if ns.MasterDB and ns.MasterDB.EnsureIndexesBuilt then
        ns.MasterDB:EnsureIndexesBuilt()
    end
    return (ns.MasterDB and ns.MasterDB.UniqueItemIDList) or nil
end

local function ExecuteDatabaseSearch()
    local raw = SearchBox:GetText() or ""
    raw = string.gsub(raw, "^%s*(.-)%s*$", "%1")
    MainPanel._state.dbSearchQuery = raw
    dbFilterState.currentPage = 1
    if raw == "" then
        SearchPlaceholder:Show()
        MainPanel._state.inspectedItemID = nil
        MainPanel:RenderActivePane()
        return
    end
    SearchPlaceholder:Hide()

    local exactID = tonumber(raw)
    if exactID and exactID >= 1 and exactID <= 500000 then
        local targetID = math.floor(exactID)
        MainPanel._state.inspectedItemID = targetID
        if C_Item and C_Item.RequestLoadItemDataByID then
            pcall(C_Item.RequestLoadItemDataByID, targetID)
        end
        if ns.Scanner and ns.Scanner.CacheItemData then
            ns.Scanner.CacheItemData(targetID, false)
        end
        MainPanel:TryOnItemInTab6(targetID)
        MainPanel:RenderActivePane()
        C_Timer.After(0.25, function()
            if MainPanel:IsShown() and MainPanel._state.activeViewMode == "DATABASE" then
                if ns.Scanner and ns.Scanner.CacheItemData then
                    ns.Scanner.CacheItemData(targetID, false)
                end
                MainPanel:RenderActivePane()
            end
        end)
    else
        MainPanel._state.inspectedItemID = nil
        MainPanel:RenderActivePane()
    end
end

SearchBox:SetScript("OnEnterPressed", function(self)
    self:ClearFocus()
    ExecuteDatabaseSearch()
end)

local SearchBtn = CreateFrame("Button", nil, DBButtonRow, "UIPanelButtonTemplate")
SearchBtn:SetText("Search")
SearchBtn:SetScript("OnClick", function()
    SearchBox:ClearFocus()
    ExecuteDatabaseSearch()
end)

local JumpIDBtn = CreateFrame("Button", nil, DBButtonRow, "UIPanelButtonTemplate")
JumpIDBtn:SetText("Scan From #")
JumpIDBtn:SetScript("OnClick", function()
    local targetID = tonumber(SearchBox:GetText() or "") or 1
    targetID = math.max(1, math.floor(targetID))
    if ns.DB and ns.DB.SetCrawlCursor then
        ns.DB.SetCrawlCursor(targetID)
    elseif AltVaultDB then
        AltVaultDB.CrawlCursorID = targetID
    end
    if ns.DB and ns.DB.SetScannerPaused then
        ns.DB.SetScannerPaused(false)
    elseif AltVaultDB then
        AltVaultDB.ScannerPaused = false
    end
    MainPanel:UpdateScannerMeter()
end)

local TurboBtn = CreateFrame("Button", nil, DBButtonRow, "UIPanelButtonTemplate")
TurboBtn:SetText("Turbo: OFF")

local PauseScanBtn = CreateFrame("Button", nil, DBButtonRow, "UIPanelButtonTemplate")
PauseScanBtn:SetText("|cffff5555Stop Scan|r")

local ToggleClosetBtn = CreateFrame("Button", nil, DBButtonRow, "UIPanelButtonTemplate")
ToggleClosetBtn:SetText("|cffffd100👗 3D Closet|r")
ToggleClosetBtn:SetScript("OnClick", function()
    if DBDressUpDrawer:IsShown() then
        DBDressUpDrawer:Hide()
    else
        DBDressUpDrawer:Show()
        DBDressUpDrawer:Raise()
    end
end)

-- Row 2 Filter Dropdown Buttons & Pagination Controls
local ClassFilterBtn = CreateFrame("Button", nil, DBFilterRow, "UIPanelButtonTemplate")
ClassFilterBtn:SetText("Class: All ▼")
ClassFilterBtn:SetScript("OnClick", function(self)
    ShowFlyoutDropdown(self, FILTER_CLASSES, dbFilterState.classIdx, function(idx, opt)
        dbFilterState.classIdx = idx
        dbFilterState.currentPage = 1
        self:SetText("Class: " .. opt.label .. " ▼")
        MainPanel._state.inspectedItemID = nil
        MainPanel:RenderActivePane()
    end)
end)

local ArmorFilterBtn = CreateFrame("Button", nil, DBFilterRow, "UIPanelButtonTemplate")
ArmorFilterBtn:SetText("Gear: All ▼")
ArmorFilterBtn:SetScript("OnClick", function(self)
    ShowFlyoutDropdown(self, FILTER_ARMOR_TYPES, dbFilterState.armorIdx, function(idx, opt)
        dbFilterState.armorIdx = idx
        dbFilterState.currentPage = 1
        self:SetText("Gear: " .. opt.label .. " ▼")
        MainPanel._state.inspectedItemID = nil
        MainPanel:RenderActivePane()
    end)
end)

local RaceFilterBtn = CreateFrame("Button", nil, DBFilterRow, "UIPanelButtonTemplate")
RaceFilterBtn:SetText("Race: All ▼")
RaceFilterBtn:SetScript("OnClick", function(self)
    ShowFlyoutDropdown(self, FILTER_RACES, dbFilterState.raceIdx, function(idx, opt)
        dbFilterState.raceIdx = idx
        dbFilterState.currentPage = 1
        self:SetText("Race: " .. opt.label .. " ▼")
        MainPanel._state.inspectedItemID = nil
        MainPanel:RenderActivePane()
    end)
end)

local DBMinLvlBox = CreateFrame("EditBox", "AltVaultDBMinLvlBox", DBFilterRow, "InputBoxTemplate")
DBMinLvlBox:SetSize(56, 24)
DBMinLvlBox:SetAutoFocus(false)
DBMinLvlBox:SetNumeric(true)
DBMinLvlBox:SetMaxLetters(3)
DBMinLvlBox:SetText("")

local DBMinLvlPlaceholder = DBMinLvlBox:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
DBMinLvlPlaceholder:SetPoint("LEFT", DBMinLvlBox, "LEFT", 5, 0)
DBMinLvlPlaceholder:SetPoint("RIGHT", DBMinLvlBox, "RIGHT", -4, 0)
DBMinLvlPlaceholder:SetJustifyH("LEFT")
DBMinLvlPlaceholder:SetWordWrap(false)
DBMinLvlPlaceholder:SetText("Min Lvl")

local DBMaxLvlBox = CreateFrame("EditBox", "AltVaultDBMaxLvlBox", DBFilterRow, "InputBoxTemplate")
DBMaxLvlBox:SetSize(56, 24)
DBMaxLvlBox:SetAutoFocus(false)
DBMaxLvlBox:SetNumeric(true)
DBMaxLvlBox:SetMaxLetters(3)
DBMaxLvlBox:SetText("")

local DBMaxLvlPlaceholder = DBMaxLvlBox:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
DBMaxLvlPlaceholder:SetPoint("LEFT", DBMaxLvlBox, "LEFT", 5, 0)
DBMaxLvlPlaceholder:SetPoint("RIGHT", DBMaxLvlBox, "RIGHT", -4, 0)
DBMaxLvlPlaceholder:SetJustifyH("LEFT")
DBMaxLvlPlaceholder:SetWordWrap(false)
DBMaxLvlPlaceholder:SetText("Max Lvl")

local MyLvlBtn = CreateFrame("Button", nil, DBFilterRow, "UIPanelButtonTemplate")
local function UpdateDBMyLvlBtnText()
    if dbFilterState.autoLevelDefault then
        MyLvlBtn:SetText("|cff00ff96My Lvl: ON|r")
        MyLvlBtn:LockHighlight()
    else
        MyLvlBtn:SetText("Lvl 1-60")
        MyLvlBtn:UnlockHighlight()
    end
end
UpdateDBMyLvlBtnText()

local function ApplyDBLevelFilters()
    local minVal = tonumber(DBMinLvlBox:GetText() or "")
    local maxVal = tonumber(DBMaxLvlBox:GetText() or "")
    if minVal and minVal <= 0 then minVal = nil end
    if maxVal and maxVal <= 0 then maxVal = nil end
    dbFilterState.autoLevelDefault = false
    dbFilterState.minLvl = minVal
    dbFilterState.maxLvl = maxVal
    dbFilterState.currentPage = 1
    UpdateDBMyLvlBtnText()
    MainPanel._state.inspectedItemID = nil
    if MainPanel.ScrollFrame then MainPanel.ScrollFrame:SetVerticalScroll(0) end
    MainPanel:RenderActivePane()
end

local function SyncDBAutoLevelDefault()
    if not dbFilterState.autoLevelDefault then
        UpdateDBMyLvlBtnText()
        return
    end
    local charKey = (MainPanel:GetSelectedSyncedPeer() or MainPanel:GetSelectedCharacter() or UnitName("player") or "Player")
        .. ":" .. tostring(MainPanel:GetActiveCharacterLevel())
    if dbFilterState.lastSeededCharKey ~= charKey or (not dbFilterState.minLvl and not dbFilterState.maxLvl) then
        dbFilterState.lastSeededCharKey = charKey
        local minL, maxL = MainPanel:GetDefaultLevelBand(false)
        dbFilterState.minLvl = minL
        dbFilterState.maxLvl = maxL
        if DBMinLvlBox and not DBMinLvlBox:HasFocus() then
            DBMinLvlBox:SetText(tostring(minL))
            DBMinLvlPlaceholder:Hide()
        end
        if DBMaxLvlBox and not DBMaxLvlBox:HasFocus() then
            DBMaxLvlBox:SetText(tostring(maxL))
            DBMaxLvlPlaceholder:Hide()
        end
    end
    UpdateDBMyLvlBtnText()
end

MyLvlBtn:SetScript("OnClick", function()
    dbFilterState.autoLevelDefault = not dbFilterState.autoLevelDefault
    dbFilterState.lastSeededCharKey = nil
    dbFilterState.currentPage = 1
    if not dbFilterState.autoLevelDefault then
        dbFilterState.minLvl = nil
        dbFilterState.maxLvl = nil
        DBMinLvlBox:SetText("")
        DBMinLvlPlaceholder:Show()
        DBMaxLvlBox:SetText("")
        DBMaxLvlPlaceholder:Show()
    else
        SyncDBAutoLevelDefault()
    end
    UpdateDBMyLvlBtnText()
    if MainPanel.ScrollFrame then MainPanel.ScrollFrame:SetVerticalScroll(0) end
    MainPanel:RenderActivePane()
end)

local function SetupDBLevelBoxScripts(box, placeholder)
    box:SetScript("OnEditFocusGained", function() placeholder:Hide() end)
    box:SetScript("OnEditFocusLost", function(self)
        if (self:GetText() or "") == "" then placeholder:Show() end
    end)
    box:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
        if (self:GetText() or "") == "" then placeholder:Show() end
    end)
    box:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
        ApplyDBLevelFilters()
    end)
    box:SetScript("OnTextChanged", function(self, userInput)
        local txt = self:GetText() or ""
        if txt ~= "" then placeholder:Hide() elseif not self:HasFocus() then placeholder:Show() end
        if userInput then
            ApplyDBLevelFilters()
        end
    end)
end

SetupDBLevelBoxScripts(DBMinLvlBox, DBMinLvlPlaceholder)
SetupDBLevelBoxScripts(DBMaxLvlBox, DBMaxLvlPlaceholder)

-- Per-Page Dropdown & [ - ] Page X/Y [ + ] Pagination Controls
local PerPageBtn = CreateFrame("Button", nil, DBFilterRow, "UIPanelButtonTemplate")
local PrevPageBtn = CreateFrame("Button", nil, DBFilterRow, "UIPanelButtonTemplate")
local PageInfoBtn = CreateFrame("Button", nil, DBFilterRow, "UIPanelButtonTemplate")
local NextPageBtn = CreateFrame("Button", nil, DBFilterRow, "UIPanelButtonTemplate")

local function UpdateDBPaginationControls(totalMatches)
    local perPage = MainPanel:GetPerPageSize()
    local perLabel = (perPage >= 9999) and "All" or tostring(perPage)
    PerPageBtn:SetText("|cff00ff96Per Pg: " .. perLabel .. " ▼|r")

    local totalPages = math.max(1, math.ceil(math.max(0, totalMatches or 0) / math.max(1, perPage)))
    dbFilterState.totalPages = totalPages
    if dbFilterState.currentPage > totalPages then dbFilterState.currentPage = totalPages end
    if dbFilterState.currentPage < 1 then dbFilterState.currentPage = 1 end

    PrevPageBtn:SetText(dbFilterState.currentPage > 1 and "|cffffd100[ - ]|r" or "|cff666666[ - ]|r")
    PageInfoBtn:SetText(string.format("|cffffffffPg %d/%d|r", dbFilterState.currentPage, totalPages))
    NextPageBtn:SetText(dbFilterState.currentPage < totalPages and "|cffffd100[ + ]|r" or "|cff666666[ + ]|r")
end

PerPageBtn:SetScript("OnClick", function(self)
    local curSize = MainPanel:GetPerPageSize()
    local curIdx = 2
    for i, opt in ipairs(MainPanel.PAGE_SIZE_OPTIONS or {}) do
        if opt.count == curSize then curIdx = i; break end
    end
    ShowFlyoutDropdown(self, MainPanel.PAGE_SIZE_OPTIONS or {}, curIdx, function(_, opt)
        MainPanel:SetPerPageSize(opt.count)
        dbFilterState.currentPage = 1
        if MainPanel.ScrollFrame then MainPanel.ScrollFrame:SetVerticalScroll(0) end
        MainPanel:RenderActivePane()
    end)
end)

PrevPageBtn:SetScript("OnClick", function()
    if dbFilterState.currentPage > 1 then
        dbFilterState.currentPage = dbFilterState.currentPage - 1
    else
        dbFilterState.currentPage = dbFilterState.totalPages or 1
    end
    if MainPanel.ScrollFrame then MainPanel.ScrollFrame:SetVerticalScroll(0) end
    MainPanel:RenderActivePane()
end)

PageInfoBtn:SetScript("OnClick", function()
    dbFilterState.currentPage = 1
    if MainPanel.ScrollFrame then MainPanel.ScrollFrame:SetVerticalScroll(0) end
    MainPanel:RenderActivePane()
end)

NextPageBtn:SetScript("OnClick", function()
    if dbFilterState.currentPage < (dbFilterState.totalPages or 1) then
        dbFilterState.currentPage = dbFilterState.currentPage + 1
    else
        dbFilterState.currentPage = 1
    end
    if MainPanel.ScrollFrame then MainPanel.ScrollFrame:SetVerticalScroll(0) end
    MainPanel:RenderActivePane()
end)

-- Row 3: Quality Filter Buttons (All Qualities, Grey, Common, Uncommon, Rare, Epic, Legend+)
local AllQualityBtn = CreateFrame("Button", nil, DBQualityRow, "UIPanelButtonTemplate")
local dbQualityBtns = {}

local function UpdateDBQualityButtonLabels()
    local allOn = true
    for _, qDef in ipairs(MainPanel.QUALITY_FILTER_DEFS or {}) do
        local isOn = dbFilterState.qualities[qDef.key] ~= false
        if not isOn then allOn = false end
        local btn = dbQualityBtns[qDef.key]
        if btn then
            if isOn then
                btn:SetText(string.format("|cff00ff00✓|r |cff%s%s|r", qDef.hex, qDef.label))
                btn:LockHighlight()
            else
                btn:SetText(string.format("|cff555555✗ %s|r", qDef.label))
                btn:UnlockHighlight()
            end
        end
    end
    if allOn then
        AllQualityBtn:SetText("|cffffd100All Qualities: ON|r")
        AllQualityBtn:LockHighlight()
    else
        AllQualityBtn:SetText("All Qualities")
        AllQualityBtn:UnlockHighlight()
    end
end

AllQualityBtn:SetScript("OnClick", function()
    local allOn = true
    for _, qDef in ipairs(MainPanel.QUALITY_FILTER_DEFS or {}) do
        if dbFilterState.qualities[qDef.key] == false then allOn = false; break end
    end
    for _, qDef in ipairs(MainPanel.QUALITY_FILTER_DEFS or {}) do
        dbFilterState.qualities[qDef.key] = true
    end
    if allOn then
        -- Quick cycle: if all were on and clicked, keep all on and reset to Page 1
    end
    dbFilterState.currentPage = 1
    UpdateDBQualityButtonLabels()
    if MainPanel.ScrollFrame then MainPanel.ScrollFrame:SetVerticalScroll(0) end
    MainPanel:RenderActivePane()
end)

for _, qDef in ipairs(MainPanel.QUALITY_FILTER_DEFS or {}) do
    local qBtn = CreateFrame("Button", nil, DBQualityRow, "UIPanelButtonTemplate")
    qBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    local qKey = qDef.key
    qBtn:SetScript("OnClick", function(_, button)
        if button == "RightButton" then
            -- Right-click solos this quality!
            for _, d in ipairs(MainPanel.QUALITY_FILTER_DEFS or {}) do
                dbFilterState.qualities[d.key] = (d.key == qKey)
            end
        else
            dbFilterState.qualities[qKey] = not (dbFilterState.qualities[qKey] ~= false)
            local anyEnabled = false
            for _, d in ipairs(MainPanel.QUALITY_FILTER_DEFS or {}) do
                if dbFilterState.qualities[d.key] ~= false then anyEnabled = true; break end
            end
            if not anyEnabled then
                for _, d in ipairs(MainPanel.QUALITY_FILTER_DEFS or {}) do
                    dbFilterState.qualities[d.key] = true
                end
            end
        end
        dbFilterState.currentPage = 1
        UpdateDBQualityButtonLabels()
        if MainPanel.ScrollFrame then MainPanel.ScrollFrame:SetVerticalScroll(0) end
        MainPanel:RenderActivePane()
    end)
    dbQualityBtns[qKey] = qBtn
end
UpdateDBQualityButtonLabels()

local FavToggleBtn = CreateFrame("Button", nil, DBButtonRow, "UIPanelButtonTemplate")
local function UpdateDBFavToggleText()
    local iCount = (MainPanel.GetFavoriteCounts and MainPanel:GetFavoriteCounts()) or 0
    if dbFilterState.showFavoritesOnly then
        FavToggleBtn:SetText(string.format("|cffffd100★ Favs: ON (%d)|r", iCount))
        FavToggleBtn:LockHighlight()
    else
        FavToggleBtn:SetText(string.format("|cffffd100★ Favs (%d)|r", iCount))
        FavToggleBtn:UnlockHighlight()
    end
end
UpdateDBFavToggleText()
FavToggleBtn:SetScript("OnClick", function()
    dbFilterState.showFavoritesOnly = not dbFilterState.showFavoritesOnly
    dbFilterState.currentPage = 1
    MainPanel._state.inspectedItemID = nil
    UpdateDBFavToggleText()
    if MainPanel.ScrollFrame then MainPanel.ScrollFrame:SetVerticalScroll(0) end
    MainPanel:RenderActivePane()
end)

local ViewModeToggleBtn = CreateFrame("Button", nil, DBButtonRow, "UIPanelButtonTemplate")
ViewModeToggleBtn:SetText("|cff00ff96View: 3-Col Grid|r")
ViewModeToggleBtn:SetScript("OnClick", function(self)
    dbFilterState.useGridView = not dbFilterState.useGridView
    self:SetText(dbFilterState.useGridView and "|cff00ff96View: 3-Col Grid|r" or "|cff88ccffView: Full List|r")
    MainPanel:RenderActivePane()
end)

local ClearFiltersBtn = CreateFrame("Button", nil, DBButtonRow, "UIPanelButtonTemplate")
ClearFiltersBtn:SetText("Reset")
ClearFiltersBtn:SetScript("OnClick", function()
    dbFilterState.classIdx = 1
    dbFilterState.armorIdx = 1
    dbFilterState.raceIdx  = 1
    dbFilterState.minLvl   = nil
    dbFilterState.maxLvl   = nil
    dbFilterState.autoLevelDefault = false
    dbFilterState.showFavoritesOnly = false
    dbFilterState.currentPage = 1
    for _, qDef in ipairs(MainPanel.QUALITY_FILTER_DEFS or {}) do
        dbFilterState.qualities[qDef.key] = true
    end
    UpdateDBQualityButtonLabels()
    UpdateDBMyLvlBtnText()
    UpdateDBFavToggleText()
    SearchBox:SetText("")
    SearchPlaceholder:Show()
    DBMinLvlBox:SetText("")
    DBMinLvlBox:ClearFocus()
    DBMinLvlPlaceholder:Show()
    DBMaxLvlBox:SetText("")
    DBMaxLvlBox:ClearFocus()
    DBMaxLvlPlaceholder:Show()
    MainPanel._state.dbSearchQuery = ""
    MainPanel._state.inspectedItemID = nil
    ClassFilterBtn:SetText("Class: All ▼")
    ArmorFilterBtn:SetText("Gear: All ▼")
    RaceFilterBtn:SetText("Race: All ▼")
    if MainPanel.ScrollFrame then MainPanel.ScrollFrame:SetVerticalScroll(0) end
    MainPanel:RenderActivePane()
end)

local function StopLocalTurboTicker()
    isTurboActive = false
    if localTurboTicker then
        localTurboTicker:Cancel()
        localTurboTicker = nil
    end
end

local function EnsureCursorReadyForRestart()
    if not AltVaultDB then return end
    local maxID = (ns.DB and ns.DB.MAX_CRAWL_ID) or MAX_SCAN_ID
    if (AltVaultDB.CrawlCursorID or 1) >= maxID then
        if ns.DB and ns.DB.SetCrawlCursor then
            ns.DB.SetCrawlCursor(1)
        else
            AltVaultDB.CrawlCursorID = 1
        end
    end
    if ns.DB and ns.DB.StartSilentBackgroundScanner then
        ns.DB.StartSilentBackgroundScanner()
    end
end

local function ToggleTurboScanner()
    isTurboActive = not isTurboActive
    if isTurboActive then
        EnsureCursorReadyForRestart()
        if ns.DB and ns.DB.SetScannerPaused then
            ns.DB.SetScannerPaused(false)
        elseif AltVaultDB then
            AltVaultDB.ScannerPaused = false
        end
        if ns.DB and ns.DB.SetTurboMode then
            ns.DB.SetTurboMode(true)
        end
        if not localTurboTicker then
            localTurboTicker = C_Timer.NewTicker(0.12, function()
                local paused = (ns.DB and ns.DB.IsScannerPaused and ns.DB.IsScannerPaused()) or (AltVaultDB and AltVaultDB.ScannerPaused)
                if not isTurboActive or paused or InCombatLockdown() or not AltVaultDB or not ns.Scanner then
                    return
                end
                for i = 1, #turboPending do
                    ns.Scanner.CacheItemData(turboPending[i], false)
                end
                turboPending = {}

                local maxID = (ns.DB and ns.DB.MAX_CRAWL_ID) or MAX_SCAN_ID

                for _ = 1, 12 do
                    local cur = (AltVaultDB.CrawlCursorID or 1)
                    if cur >= maxID then
                        AltVaultDB.CrawlCursorID = maxID
                        if ns.DB and ns.DB.SetScannerPaused then
                            ns.DB.SetScannerPaused(true)
                        else
                            AltVaultDB.ScannerPaused = true
                        end
                        StopLocalTurboTicker()
                        break
                    end
                    cur = cur + 1
                    -- Smart-jump over non-Forever expansion ID gap (24501..179999)
                    if cur > 24500 and cur < 180000 then
                        cur = 180000
                    end
                    AltVaultDB.CrawlCursorID = cur

                    if not (AltVaultDB.ItemCache and AltVaultDB.ItemCache[cur]) then
                        if C_Item and C_Item.RequestLoadItemDataByID then
                            pcall(C_Item.RequestLoadItemDataByID, cur)
                        end
                        ns.Scanner.CacheItemData(cur, true)
                        table.insert(turboPending, cur)
                        local retryID = cur
                        if C_Timer and C_Timer.After then
                            C_Timer.After(0.45, function()
                                if AltVaultDB and not (AltVaultDB.ItemCache and AltVaultDB.ItemCache[retryID]) and ns.Scanner and ns.Scanner.CacheItemData then
                                    ns.Scanner.CacheItemData(retryID, false)
                                end
                            end)
                            C_Timer.After(1.25, function()
                                if AltVaultDB and not (AltVaultDB.ItemCache and AltVaultDB.ItemCache[retryID]) and ns.Scanner and ns.Scanner.CacheItemData then
                                    ns.Scanner.CacheItemData(retryID, false)
                                end
                            end)
                        end
                    end
                end
            end)
        end
    else
        if ns.DB and ns.DB.SetTurboMode then
            ns.DB.SetTurboMode(false)
        end
        StopLocalTurboTicker()
    end
    MainPanel:UpdateScannerMeter()
end

TurboBtn:SetScript("OnClick", ToggleTurboScanner)

PauseScanBtn:SetScript("OnClick", function()
    local currentlyPaused = (ns.DB and ns.DB.IsScannerPaused and ns.DB.IsScannerPaused())
        or (AltVaultDB and AltVaultDB.ScannerPaused == true)
    local newPaused = not currentlyPaused
    if not newPaused then EnsureCursorReadyForRestart() end
    if ns.DB and ns.DB.SetScannerPaused then
        ns.DB.SetScannerPaused(newPaused)
    elseif AltVaultDB then
        AltVaultDB.ScannerPaused = newPaused
    end
    if newPaused then StopLocalTurboTicker() end
    MainPanel:UpdateScannerMeter()
end)

function MainPanel:ScaleDBHeaderControls(bScale, leftX, baseTopY)
    local dbHeaderH = math.max(126, math.floor(144 * bScale + 0.5))
    DBHeaderFrame:ClearAllPoints()
    DBHeaderFrame:SetPoint("TOPLEFT", MainPanel, "TOPLEFT", leftX, baseTopY)
    DBHeaderFrame:SetPoint("TOPRIGHT", MainPanel, "TOPRIGHT", -28, baseTopY)
    DBHeaderFrame:SetHeight(dbHeaderH)

    local barH = math.max(18, math.floor(21 * bScale + 0.5))
    ScannerBar:SetHeight(barH)
    if ScannerBar.Text then
        ScannerBar.Text:SetFont(STANDARD_FONT, math.max(9, math.floor(11 * bScale + 0.5)), "OUTLINE")
    end

    local rowH = math.max(25, math.floor(30 * bScale + 0.5))
    DBButtonRow:SetHeight(rowH)
    DBFilterRow:SetHeight(rowH)
    DBQualityRow:SetHeight(rowH)

    self:FitControlsRowInsideBar(DBButtonRow, 6, 6, 4, {
        { frame = SearchBox,         isEditBox = true, placeholder = SearchPlaceholder, baseW = 128, baseH = 26, font = 12 },
        { frame = SearchBtn,         baseW = 56,  baseH = 26, font = 12 },
        { frame = FavToggleBtn,      baseW = 92,  baseH = 26, font = 12 },
        { frame = ViewModeToggleBtn, baseW = 98,  baseH = 26, font = 11 },
        { frame = ToggleClosetBtn,   baseW = 90,  baseH = 26, font = 11 },
        { frame = JumpIDBtn,         baseW = 78,  baseH = 26, font = 11 },
        { frame = TurboBtn,          baseW = 74,  baseH = 26, font = 11 },
        { frame = PauseScanBtn,      baseW = 78,  baseH = 26, font = 11 },
        { frame = ClearFiltersBtn,   baseW = 54,  baseH = 26, font = 11 },
    })

    self:FitControlsRowInsideBar(DBFilterRow, 6, 6, 4, {
        { frame = ClassFilterBtn,    baseW = 98,  baseH = 26, font = 11 },
        { frame = ArmorFilterBtn,    baseW = 104, baseH = 26, font = 11 },
        { frame = RaceFilterBtn,     baseW = 90,  baseH = 26, font = 11 },
        { frame = DBMinLvlBox,       isEditBox = true, placeholder = DBMinLvlPlaceholder, baseW = 50, baseH = 24, font = 11 },
        { frame = DBMaxLvlBox,       isEditBox = true, placeholder = DBMaxLvlPlaceholder, baseW = 50, baseH = 24, font = 11 },
        { frame = MyLvlBtn,          baseW = 72,  baseH = 26, font = 11 },
        { frame = PerPageBtn,        baseW = 86,  baseH = 26, font = 11 },
        { frame = PrevPageBtn,       baseW = 42,  baseH = 26, font = 12 },
        { frame = PageInfoBtn,       baseW = 68,  baseH = 26, font = 11 },
        { frame = NextPageBtn,       baseW = 42,  baseH = 26, font = 12 },
    })

    local qSpecs = {
        { frame = AllQualityBtn, baseW = 112, baseH = 25, font = 11 },
    }
    for _, qDef in ipairs(MainPanel.QUALITY_FILTER_DEFS or {}) do
        local qBtn = dbQualityBtns[qDef.key]
        if qBtn then
            table.insert(qSpecs, { frame = qBtn, baseW = 88, baseH = 25, font = 11 })
        end
    end
    self:FitControlsRowInsideBar(DBQualityRow, 6, 6, 4, qSpecs)
end

function MainPanel:UpdateScannerMeter()
    if not AltVaultDB then return end
    local maxID = (ns.DB and ns.DB.MAX_CRAWL_ID) or MAX_SCAN_ID
    local cursor = math.min(maxID, math.max(1, AltVaultDB.CrawlCursorID or 1))

    local numItems = 0
    if ns.DB and ns.DB.GetDatabaseStats then
        numItems = ns.DB.GetDatabaseStats()
    else
        for _ in pairs(AltVaultDB.ItemCache or {}) do numItems = numItems + 1 end
    end

    local masterStats = (ns.MasterDB and ns.MasterDB.GetHoldingTankStats and ns.MasterDB:GetHoldingTankStats()) or {}
    local totalStatic = masterStats.TotalRecords or 0

    local isPaused = (ns.DB and ns.DB.IsScannerPaused and ns.DB.IsScannerPaused())
        or (AltVaultDB.ScannerPaused == true)
    local turboOn = (not isPaused) and (isTurboActive or (ns.DB and ns.DB.IsTurboMode and ns.DB.IsTurboMode()))

    local statusTag
    if isPaused then
        statusTag = "|cffff5555[PAUSED]|r"
        PauseScanBtn:SetText("|cff00ff00Resume Scan|r")
        TurboBtn:SetText("Turbo: OFF")
        ScannerBar:SetStatusBarColor(0.55, 0.25, 0.15, 0.90)
    elseif turboOn then
        statusTag = "|cff00ff00[TURBO]|r"
        PauseScanBtn:SetText("|cffff5555Stop Scan|r")
        TurboBtn:SetText("|cff00ff00Turbo: ON|r")
        ScannerBar:SetStatusBarColor(0.1, 1.0, 0.3, 0.95)
    else
        statusTag = "|cff00ffff[SCANNING]|r"
        PauseScanBtn:SetText("|cffff5555Stop Scan|r")
        TurboBtn:SetText("Turbo: OFF")
        ScannerBar:SetStatusBarColor(0.0, 0.75, 0.95, 0.90)
    end

    local pct = (cursor / math.max(1, maxID)) * 100
    ScannerBar:SetMinMaxValues(1, math.max(1, maxID))
    ScannerBar:SetValue(cursor)
    local uForeverItems = masterStats.UniqueItems or 0
    ScannerBar.Text:SetText(string.format(
        "%s Server ID: %d / %d (%.1f%%)  |  Forever Tank: %d Sources (%d IDs)  |  Verified Forever Items: %d",
        statusTag, cursor, maxID, pct, totalStatic, uForeverItems, numItems
    ))
end

C_Timer.NewTicker(0.25, function()
    if MainPanel:IsShown() and MainPanel._state.activeViewMode == "DATABASE" then
        MainPanel:UpdateScannerMeter()
    end
end)

-- ============================================================================
-- BLOCK HEADING: 3-COLUMN COMPACT GRID CELL POOL FOR TAB 6
-- ============================================================================
MainPanel.dbGridCells = MainPanel.dbGridCells or {}

local function HideAllDBGridCells()
    for _, cell in pairs(MainPanel.dbGridCells) do
        cell:Hide()
    end
end

local function GetOrCreateDBGridCell(index)
    local cell = MainPanel.dbGridCells[index]
    if not cell then
        cell = CreateBackdrop("Button", nil, ScrollChild)
        cell:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        if cell.SetBackdrop then
            cell:SetBackdrop({
                bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                tile = true, tileSize = 16, edgeSize = 10,
                insets = { left = 2, right = 2, top = 2, bottom = 2 }
            })
            cell:SetBackdropColor(0.06, 0.08, 0.12, 0.94)
            cell:SetBackdropBorderColor(0.32, 0.36, 0.46, 0.90)
        end

        cell.Highlight = cell:CreateTexture(nil, "HIGHLIGHT")
        cell.Highlight:SetPoint("TOPLEFT", cell, "TOPLEFT", 2, -2)
        cell.Highlight:SetPoint("BOTTOMRIGHT", cell, "BOTTOMRIGHT", -2, 2)
        SetSolid(cell.Highlight, 1, 0.82, 0, 0.18)

        cell.Icon = cell:CreateTexture(nil, "ARTWORK")
        cell.Icon:SetSize(30, 30)
        cell.Icon:SetPoint("LEFT", cell, "LEFT", 5, 0)
        cell.Icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

        cell.Title = cell:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        cell.Title:SetPoint("TOPLEFT", cell.Icon, "TOPRIGHT", 6, -1)
        cell.Title:SetPoint("RIGHT", cell, "RIGHT", -22, 0)
        cell.Title:SetJustifyH("LEFT")
        cell.Title:SetWordWrap(false)

        cell.Meta = cell:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        cell.Meta:SetPoint("TOPLEFT", cell.Title, "BOTTOMLEFT", 0, -2)
        cell.Meta:SetPoint("RIGHT", cell, "RIGHT", -4, 0)
        cell.Meta:SetJustifyH("LEFT")
        cell.Meta:SetWordWrap(false)

        cell.FavBtn = CreateFrame("Button", nil, cell)
        cell.FavBtn:SetSize(20, 20)
        cell.FavBtn:SetPoint("TOPRIGHT", cell, "TOPRIGHT", -2, -2)
        cell.FavBtn:SetFrameLevel(cell:GetFrameLevel() + 5)
        cell.FavBtn.Text = cell.FavBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        cell.FavBtn.Text:SetPoint("CENTER", cell.FavBtn, "CENTER", 0, 0)
        cell.FavBtn.Text:SetFont(STANDARD_FONT, 13, "OUTLINE")
        cell.FavBtn.Text:SetText("|cff888888☆|r")
        cell.FavBtn:SetScript("OnEnter", function(btn)
            GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
            local isFav = cell.itemID and MainPanel:IsItemFavorite(cell.itemID)
            GameTooltip:AddLine(isFav and "|cffffd100★ Remove from Favorites|r" or "|cff00ff96☆ Add to Favorites List|r", 1, 1, 1)
            GameTooltip:Show()
        end)
        cell.FavBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        cell.FavBtn:SetScript("OnClick", function()
            if cell.itemID then
                MainPanel:ToggleItemFavorite(cell.itemID, cell.entryMeta)
                UpdateDBFavToggleText()
                MainPanel:RenderActivePane()
            end
        end)

        cell:SetScript("OnEnter", function(self)
            if self.itemLink then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetHyperlink(self.itemLink)
                if self.sourceLine and self.sourceLine ~= "" then
                    GameTooltip:AddLine(" ")
                    GameTooltip:AddLine(self.sourceLine, 1, 0.82, 0, true)
                end
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine("|cff00ff00Left-Click:|r Try On in 3D Closet   |   |cffffd100Right-Click:|r Open Full Dossier", 1, 1, 1)
                GameTooltip:AddLine("|cffffd100Alt-Click or [★]:|r Toggle Favorite", 0.85, 0.92, 1)
                GameTooltip:Show()
            end
        end)

        cell:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        cell:SetScript("OnClick", function(self, button)
            if IsAltKeyDown() and self.itemID then
                MainPanel:ToggleItemFavorite(self.itemID, self.entryMeta)
                UpdateDBFavToggleText()
                MainPanel:RenderActivePane()
                return
            end
            if self.itemLink and IsModifiedClick() then
                HandleModifiedItemClick(self.itemLink)
                return
            end
            if button == "RightButton" and self.itemID then
                MainPanel._state.inspectedItemID = self.itemID
                MainPanel:RenderActivePane()
                return
            end
            if self.itemLink or self.itemID then
                MainPanel:TryOnItemInTab6(self.itemLink or self.itemID, self.rawName)
            end
        end)

        MainPanel.dbGridCells[index] = cell
    end
    return cell
end

local function RenderDBMatchesAsCompactGrid(headerText, matches)
    if MainPanel.HideArmoryCanvas then MainPanel:HideArmoryCanvas() end
    if MainPanel.ClearAllScrollContent then
        MainPanel:ClearAllScrollContent()
    else
        for _, row in pairs(MainPanel.contentRows or {}) do
            row:Hide()
        end
        HideAllDBGridCells()
    end
    ScrollChild:Show()
    ScrollFrame:Show()

    local wScale = (MainPanel.GetWindowScaleFactor and MainPanel:GetWindowScaleFactor()) or 1.0
    local leftX = MainPanel:GetLeftColumnOffset()
    local contentWidth = math.max(320, (MainPanel:GetWidth() or 960) - leftX - 38)
    local numCols = (contentWidth >= 660) and 3 or 2
    local gap = math.max(5, math.floor(6 * wScale + 0.5))
    local cellW = math.floor((contentWidth - ((numCols - 1) * gap) - 8) / numCols)
    local cellH = math.max(38, math.floor(42 * wScale + 0.5))
    local iconSz = math.max(26, math.floor(32 * wScale + 0.5))
    local titleFontSz = math.max(10, math.min(18, math.floor(11 * wScale + 0.5)))
    local metaFontSz = math.max(8, math.min(15, math.floor(9.5 * wScale + 0.5)))

    local yOffset = -6
    for i, m in ipairs(matches) do
        local cell = GetOrCreateDBGridCell(i)
        local colIdx = (i - 1) % numCols
        local rowIdx = math.floor((i - 1) / numCols)
        local xPos = 4 + (colIdx * (cellW + gap))
        local yPos = yOffset - (rowIdx * (cellH + 4))

        cell:SetSize(cellW, cellH)
        cell:ClearAllPoints()
        cell:SetPoint("TOPLEFT", ScrollChild, "TOPLEFT", xPos, yPos)
        cell.Icon:SetSize(iconSz, iconSz)

        local hex = QUALITY_HEX[m.quality or 3] or "0070dd"
        local link = string.format("|cff%s|Hitem:%d:0:0:0:0:0:0:0:60|h[%s]|h|r", hex, m.id, m.name)
        local isFav = MainPanel:IsItemFavorite(m.id)

        cell.itemID = m.id
        cell.itemLink = link
        cell.rawName = m.name
        cell.iconTex = m.icon
        cell.sourceLine = m.sourceLine
        cell.entryMeta = m

        cell.Icon:SetTexture(m.icon)
        cell.Title:SetFont(STANDARD_FONT, titleFontSz, "OUTLINE")
        cell.Title:SetText(string.format("%s|cff%s%s|r", isFav and "|cffffd100★ |r" or "", hex, m.name))

        cell.Meta:SetFont(STANDARD_FONT, metaFontSz, "")
        cell.Meta:SetText(string.format("|cff00ff96Lvl %d|r • |cffcccccc%s (iLvl %d • #%d)|r", m.reqLvl or 1, m.subType or "Gear", m.iLvl or 1, m.id))
        if cell.FavBtn and cell.FavBtn.Text then
            cell.FavBtn.Text:SetFont(STANDARD_FONT, math.max(11, math.floor(13 * wScale + 0.5)), "OUTLINE")
            cell.FavBtn.Text:SetText(isFav and "|cffffd100★|r" or "|cff777777☆|r")
        end

        cell:Show()
    end

    local totalRows = math.ceil(#matches / numCols)
    ScrollChild:SetSize(contentWidth, math.max(200, (totalRows * (cellH + 4)) + 30))
    if ScrollFrame.UpdateScrollChildRect then
        pcall(ScrollFrame.UpdateScrollChildRect, ScrollFrame)
    end
end

-- ============================================================================
-- BLOCK HEADING: ITEM FILTER MATCHER (CLASS + ARMOR/WEAPON + RACE + LEVEL + QUALITY)
-- ============================================================================
local function ResolveEffectiveCharLevel(itemReqLvl, itemILvl)
    local req = tonumber(itemReqLvl)
    local ilv = tonumber(itemILvl)
    if req and req > 1 then
        return req
    elseif ilv and ilv >= 58 then
        return 60
    elseif ilv and ilv >= 10 then
        return ilv - 5
    elseif ilv and ilv >= 1 then
        return ilv
    elseif req and req >= 1 then
        return req
    end
    return 1
end

local function DoesItemPassTab6Filters(itemID, itemType, itemSubType, itemEquipLoc, allowedClassesStr, allowedRacesStr, factionStr, itemName, itemQuality, itemILvl, itemReqLvl, classID)
    if ns.Scanner and ns.Scanner.IsValidWowForeverItem then
        if not ns.Scanner.IsValidWowForeverItem(itemID, itemName, itemQuality, itemILvl, itemReqLvl, itemType, itemSubType, itemEquipLoc, classID, nil) then
            return false
        end
    end

    -- 0a. Quality Filter (Grey, Common, Uncommon, Rare, Epic, Legend+)
    if MainPanel.DoesQualityPassMask and not MainPanel:DoesQualityPassMask(itemQuality, dbFilterState.qualities) then
        return false
    end

    -- 0b. Min / Max Level Filter
    local minLvl = dbFilterState.minLvl
    local maxLvl = dbFilterState.maxLvl
    if minLvl or maxLvl then
        local effLvl = ResolveEffectiveCharLevel(itemReqLvl, itemILvl) or 1
        if minLvl and effLvl < minLvl then return false end
        if maxLvl and effLvl > maxLvl then return false end
    end

    local clsOpt = FILTER_CLASSES[dbFilterState.classIdx or 1]
    local armOpt = FILTER_ARMOR_TYPES[dbFilterState.armorIdx or 1]
    local racOpt = FILTER_RACES[dbFilterState.raceIdx or 1]

    -- In Dressing Room default view (no search text and no non-gear filter active), only show wearable/try-on-able equipment & weapons
    local hasSearchText = (MainPanel._state.dbSearchQuery and MainPanel._state.dbSearchQuery ~= "")
    local allowNonGearFilter = armOpt and (
        armOpt.token == "CUSTOM_FOREVER"
        or armOpt.token == "ALL_DB_ITEMS"
        or armOpt.token == "RECIPES"
        or armOpt.token == "CONTAINERS"
        or armOpt.token == "GOLD_FLIPS"
    )
    if not hasSearchText and not allowNonGearFilter then
        if not itemEquipLoc or itemEquipLoc == "" or itemEquipLoc == "INVTYPE_NON_EQUIP_IGNORE" or itemEquipLoc == "INVTYPE_BAG" or itemEquipLoc == "INVTYPE_AMMO" then
            return false
        end
    end

    -- 1. Armor / Weapon / Category Filter
    if armOpt and armOpt.token ~= "ALL" and armOpt.token ~= "ALL_DB_ITEMS" then
        if armOpt.token == "FOREVER_BIS" then
            local filterCls = (clsOpt and clsOpt.token ~= "ALL") and clsOpt.token or nil
            if not (ns.ForeverIndex and ns.ForeverIndex.IsOfficialForeverBiS and ns.ForeverIndex:IsOfficialForeverBiS(itemID, filterCls)) then
                return false
            end
        elseif armOpt.token == "GOLD_FLIPS" then
            if not (ns.ForeverIndex and ns.ForeverIndex.GetGoldFlipAdvisory and ns.ForeverIndex:GetGoldFlipAdvisory(itemID)) then
                return false
            end
        elseif armOpt.token == "CUSTOM_FOREVER" then
            if not itemID or tonumber(itemID) < 180000 then return false end
        elseif armOpt.token == "RECIPES" then
            if classID ~= 9 and itemType ~= "Recipe" then return false end
        elseif armOpt.token == "CONTAINERS" then
            if classID ~= 1 and itemType ~= "Container" and itemEquipLoc ~= "INVTYPE_BAG" then return false end
        elseif armOpt.token == "Weapon" then
            if itemType ~= "Weapon" then return false end
        elseif armOpt.token == "INVTYPE_CLOAK" then
            if itemEquipLoc ~= "INVTYPE_CLOAK" then return false end
        elseif armOpt.token == "JEWELRY" then
            if itemEquipLoc ~= "INVTYPE_NECK" and itemEquipLoc ~= "INVTYPE_FINGER" and itemEquipLoc ~= "INVTYPE_TRINKET" then
                return false
            end
        else
            if itemSubType ~= armOpt.token then return false end
        end
    end

    -- 2. Class Filter
    if clsOpt and clsOpt.token ~= "ALL" then
        if allowedClassesStr and allowedClassesStr ~= "" and allowedClassesStr ~= "All Classes" then
            if not string.find(string.upper(allowedClassesStr), clsOpt.token, 1, true) then
                return false
            end
        elseif itemType == "Armor" and itemSubType and (itemSubType == "Cloth" or itemSubType == "Leather" or itemSubType == "Mail" or itemSubType == "Plate" or itemSubType == "Shields") then
            if itemEquipLoc ~= "INVTYPE_CLOAK" and clsOpt.armor and not clsOpt.armor[itemSubType] then
                return false
            end
        elseif itemType == "Weapon" and itemSubType and ns.Scanner and ns.Scanner.CLASS_WEAPONS then
            local wepMap = ns.Scanner.CLASS_WEAPONS[clsOpt.token]
            if wepMap and not wepMap[itemSubType] then
                return false
            end
        end
    end

    -- 3. Race / Faction Filter
    if racOpt and racOpt.token ~= "ALL" then
        if racOpt.token == "Alliance" or racOpt.token == "Horde" then
            if factionStr and factionStr ~= "" and factionStr ~= "Both" and factionStr ~= racOpt.token then
                return false
            end
        elseif allowedRacesStr and allowedRacesStr ~= "" then
            if not string.find(string.lower(allowedRacesStr), string.lower(racOpt.token), 1, true) then
                return false
            end
        end
    end

    return true
end

-- ============================================================================
-- BLOCK HEADING: RECOMMENDATION BADGES & TAB RENDERERS (TABS 2-6)
-- ============================================================================
local function FormatRecommendationTags(itemLinkOrID, faction)
    if not ns.Scanner or not ns.Scanner.EvaluateItemForRoster then return "", nil, nil end
    local upgList, profList = ns.Scanner.EvaluateItemForRoster(itemLinkOrID, faction)
    local allMatProfs = ns.Scanner.GetMaterialProfessionsList and ns.Scanner.GetMaterialProfessionsList(itemLinkOrID) or nil

    local badges = {}
    local tooltipLines = {}
    local tint = nil

    if allMatProfs and #allMatProfs > 0 then
        local tradesStr = table.concat(allMatProfs, ", ")
        table.insert(tooltipLines, "|cffffd100Used By Trades:|r |cff00ff96" .. tradesStr .. "|r")
    end

    if upgList and #upgList > 0 then
        local top = upgList[1]
        if top.status == "UPGRADE_SOON" then
            tint = "UPGRADE_SOON"
            table.insert(badges, string.format("|cff00ff00⚡ NEXT-LVL GEAR (PULSE): %s (Lvl %d -> Req %d, +%d GS)|r", top.name, top.level, top.reqLvl, top.delta))
        else
            tint = "UPGRADE"
            table.insert(badges, string.format("|cff00ff00★ Best For: %s (+%d GS)|r", top.name, top.delta))
        end
        for i = 1, math.min(#upgList, 5) do
            local u = upgList[i]
            table.insert(tooltipLines, string.format("|cff00ff00• %s (Lvl %d %s): +%d GS (Req Lvl %d)|r", u.name, u.level, u.spec or u.class or "", u.delta, u.reqLvl or u.level))
        end
    end

    if profList and #profList > 0 then
        local pFirst = profList[1]
        if pFirst.status == "PROF_SOON" then tint = tint or "PROF_SOON" else tint = tint or "PROF" end

        local rowProfBadges = {}
        for i = 1, math.min(#profList, 8) do
            local pm = profList[i]
            if pm.status == "PROF_SOON" then
                table.insert(rowProfBadges, string.format("|cff00ffff⚡ %s (%s %d)|r", pm.name, pm.prof, pm.rank or 1))
            else
                table.insert(rowProfBadges, string.format("|cff00ccff⚒ %s (%s %d)|r", pm.name, pm.prof, pm.rank or 1))
            end
        end
        table.insert(badges, table.concat(rowProfBadges, " |cff666666/|r "))
    elseif allMatProfs and #allMatProfs > 0 then
        table.insert(badges, "|cff88ccff[Trades: " .. table.concat(allMatProfs, ", ") .. "]|r")
    end

    local joined = (#badges > 0) and ("   " .. table.concat(badges, "  ")) or ""
    local fullNote = (#tooltipLines > 0) and table.concat(tooltipLines, "\n") or joined
    return joined, tint, fullNote
end

local hasPurgedInvalidOnce = false

function MainPanel:RenderDatabaseExplorerPane()
    if not hasPurgedInvalidOnce and ns.Scanner and ns.Scanner.PurgeInvalidForeverItems then
        hasPurgedInvalidOnce = true
        ns.Scanner.PurgeInvalidForeverItems()
    end
    SyncDBAutoLevelDefault()
    UpdateDBFavToggleText()
    UpdateDBQualityButtonLabels()
    self:UpdateScannerMeter()
    HideAllDBGridCells()
    local rows = {}
    local inspectedItemID = self._state.inspectedItemID
    local dbSearchQuery = self._state.dbSearchQuery

    if ns.MasterDB and ns.MasterDB.EnsureIndexesBuilt then
        ns.MasterDB:EnsureIndexesBuilt()
    end

    if inspectedItemID and ns.Scanner and ns.Scanner.GetItemFullDossier then
        if ns.Scanner.IsValidWowForeverItem and not ns.Scanner.IsValidWowForeverItem(inspectedItemID) then
            table.insert(rows, {
                tint = "SPEC_HEADER",
                text = "|cffffd100[<- Click Here to Return to Dressing Room Grid]|r",
                onClickAction = function()
                    MainPanel._state.inspectedItemID = nil
                    MainPanel:RenderActivePane()
                end
            })
            table.insert(rows, {
                tint = "LOCKED_RED",
                text = "|cffff2020Item #" .. tostring(inspectedItemID) .. " is not a valid Level-60 WoW Forever item and is blocked on this server.|r"
            })
            self:RenderRowList(rows)
            return
        end
        local d = ns.Scanner.GetItemFullDossier(inspectedItemID)
        if d and d.loaded and ns.Scanner.IsValidWowForeverItem and not ns.Scanner.IsValidWowForeverItem(d.itemID, d.name, d.quality, d.iLvl, d.reqLvl, d.itemType, d.itemSubType, d.equipLoc, d.classID, nil) then
            table.insert(rows, {
                tint = "SPEC_HEADER",
                text = "|cffffd100[<- Click Here to Return to Dressing Room Grid]|r",
                onClickAction = function()
                    MainPanel._state.inspectedItemID = nil
                    MainPanel:RenderActivePane()
                end
            })
            table.insert(rows, {
                tint = "LOCKED_RED",
                text = "|cffff2020Item #" .. tostring(inspectedItemID) .. " (" .. tostring(d.name or "Unknown") .. ") exceeds WoW Forever Level-60 rules and is blocked.|r"
            })
            self:RenderRowList(rows)
            return
        end

        table.insert(rows, {
            tint = "SPEC_HEADER",
            text = "|cffffd100[<- Click Here to Return to Item Grid / Search List]|r",
            onClickAction = function()
                MainPanel._state.inspectedItemID = nil
                MainPanel:RenderActivePane()
            end
        })

        local isFav = self:IsItemFavorite(inspectedItemID)
        table.insert(rows, {
            tint = isFav and "SPEC_HEADER" or "PROF",
            text = isFav
                and "|cffffd100[★ FAVORITED — Click Here to Remove Item #" .. tostring(inspectedItemID) .. " from Your Favorites List]|r"
                or "|cff00ff96[☆ Click Here to Add Item #" .. tostring(inspectedItemID) .. " to Your Favorites List]|r",
            onClickAction = function()
                MainPanel:ToggleItemFavorite(inspectedItemID, {
                    id = inspectedItemID,
                    name = d and d.name,
                    quality = d and d.quality,
                    iLvl = d and d.iLvl,
                    reqLvl = d and d.reqLvl,
                    subType = d and d.itemSubType,
                    icon = d and d.icon,
                })
                UpdateDBFavToggleText()
                MainPanel:RenderActivePane()
            end
        })

        table.insert(rows, {
            tint = "UPGRADE",
            text = "|cff00ff00[👗 Click Here to Try On Item #" .. tostring(inspectedItemID) .. " in the Floating 3D Closet]|r",
            onClickAction = function()
                MainPanel:TryOnItemInTab6((d and d.link) or inspectedItemID, d and d.name)
            end
        })

        if ns.AcquisitionDB and ns.AcquisitionDB.OpenItemQuestlineDossier then
            table.insert(rows, {
                tint = "PROF",
                text = "|cff00ccff[📜 Click Here to Find Questline, Vendors & Boss Drops in 'Quest for Item']|r",
                onClickAction = function()
                    ns.AcquisitionDB:OpenItemQuestlineDossier(inspectedItemID, d and d.name)
                end
            })
        end

        if ns.ForeverIndex and ns.ForeverIndex.GetItemSourceAndCoords then
            local src = ns.ForeverIndex:GetItemSourceAndCoords(inspectedItemID)
            if src and (src.x or src.zone or src.npc) then
                local coordLabel = (src.x and src.y and src.x > 0) and string.format(" (%.1f, %.1f)", src.x, src.y) or ""
                table.insert(rows, {
                    tint = "PROF_SOON",
                    text = string.format("|cff00ffff[📍 Click Here to Lock 3D GPS Waypoint Arrow -> %s (%s%s)]|r",
                        src.npc or src.typeLabel or "Source", src.zone or "Azeroth", coordLabel),
                    onClickAction = function()
                        ns.ForeverIndex:GuideToItem(inspectedItemID)
                    end
                })
            end
        end

        if ns.MasterDB and ns.MasterDB.GetFormattedSourceLines then
            local srcLines = ns.MasterDB:GetFormattedSourceLines(inspectedItemID, 8)
            if srcLines and #srcLines > 0 then
                table.insert(rows, { tint = "SPEC_HEADER", text = "|cffffd100MASTER HOLDING TANK DROP & VENDOR SOURCES:|r" })
                for _, sLine in ipairs(srcLines) do
                    table.insert(rows, { text = "  • " .. sLine })
                end
            end
        end

        if not d or not d.loaded then
            table.insert(rows, { text = "|cff00ffffRequesting 3D Model & Tooltip Stats from Server for Item ID #" .. tostring(inspectedItemID) .. "...|r" })
            self:RenderRowList(rows)
            return
        end

        table.insert(rows, {
            icon = d.icon,
            link = d.link,
            gs = d.gearScore,
            tint = "UPGRADE",
            onClickAction = function()
                MainPanel:TryOnItemInTab6(d.link or d.itemID, d.name)
            end,
            text = string.format("%s   |cffffd100[Item ID: #%d]|r   |cff00ff96(Click to Try On 3D Stage!)|r", d.link, d.itemID)
        })
        table.insert(rows, { text = string.format("|cffffd100Quality:|r %s   |   |cffffd100Category:|r |cffffffff%s - %s|r",
            d.qualityText, d.itemType, d.itemSubType ~= "" and d.itemSubType or "General") })
        table.insert(rows, { text = string.format("|cffffd100Item Level (iLvl):|r |cffffffff%d|r   |   |cffffd100Required Level:|r |cff00ff96%d|r   |   |cffffd100AltVault GearScore:|r %s",
            d.iLvl or 1, d.reqLvl or 1, ns.Scanner.FormatGearScoreColor(d.gearScore)) })
        table.insert(rows, { text = string.format("|cffffd100Equip Slot:|r |cffffffff%s|r   |   |cffffd100Binding:|r |cff88ccff%s|r",
            d.equipSlotLabel, d.bindText) })

        if d.tooltipLines and #d.tooltipLines > 0 then
            table.insert(rows, { tint = "SPEC_HEADER", text = "|cffffd100SERVER ITEM ATTRIBUTES & TOOLTIP STATS:|r" })
            for _, line in ipairs(d.tooltipLines) do
                table.insert(rows, { text = "  |cffffffff" .. line .. "|r" })
            end
        end

        self:RenderRowList(rows)
        return
    end

    -- Favorites Mode: Clear regular items and render itemized Favorites list with full action rows!
    if dbFilterState.showFavoritesOnly then
        local favDB = self:EnsureFavoritesDB()
        local favItems = {}
        for idKey, meta in pairs(favDB.items) do
            local numID = tonumber(idKey) or (type(meta) == "table" and tonumber(meta.id))
            if numID and meta then
                local fInfo = ns.ForeverIndex and ns.ForeverIndex.Info and ns.ForeverIndex:Info(numID)
                local cached = AltVaultDB and AltVaultDB.ItemCache and AltVaultDB.ItemCache[numID]
                local name = (type(meta) == "table" and meta.name) or (cached and cached.n) or (fInfo and fInfo.name) or ("Item #" .. numID)
                local quality = (type(meta) == "table" and meta.quality) or (cached and cached.q) or (fInfo and fInfo.quality) or 3
                local iLvl = (type(meta) == "table" and meta.iLvl) or (cached and cached.l) or (fInfo and fInfo.itemLevel) or 1
                local reqLvl = (type(meta) == "table" and meta.reqLvl) or (cached and cached.r) or (fInfo and fInfo.reqLevel) or 1
                local subType = (type(meta) == "table" and meta.subType) or (cached and cached.st) or (fInfo and fInfo.itemSubType) or "Gear"
                local icon = (type(meta) == "table" and meta.icon) or (cached and (cached.i or cached.ic)) or GetItemIconTexture(numID) or "Interface\\Icons\\INV_Misc_QuestionMark"
                local srcLine = (type(meta) == "table" and meta.sourceLine) or nil
                if not srcLine and ns.ForeverIndex and ns.ForeverIndex.GetItemSourceAndCoords then
                    local src = ns.ForeverIndex:GetItemSourceAndCoords(numID)
                    if src then
                        local coordStr = (src.x and src.y and src.x > 0) and string.format(" (%.1f, %.1f)", src.x, src.y) or ""
                        srcLine = string.format("|cff00ccff📍 %s:|r %s — %s%s", src.typeLabel or "Source", src.npc or "Drop", src.zone or "Azeroth", coordStr)
                    end
                end
                if MainPanel:DoesQualityPassMask(quality, dbFilterState.qualities) then
                    table.insert(favItems, {
                        id = numID,
                        name = name,
                        quality = quality,
                        iLvl = iLvl,
                        reqLvl = reqLvl,
                        subType = subType,
                        icon = icon,
                        sourceLine = srcLine,
                    })
                end
            end
        end
        table.sort(favItems, function(a, b)
            local rA, rB = (a.reqLvl or 1), (b.reqLvl or 1)
            if rA ~= rB then return rA < rB end
            local lA, lB = (a.iLvl or 1), (b.iLvl or 1)
            if lA ~= lB then return lA < lB end
            if (a.quality or 1) ~= (b.quality or 1) then return (a.quality or 1) > (b.quality or 1) end
            return (a.name or "") < (b.name or "")
        end)

        UpdateDBPaginationControls(#favItems)
        local perPage = self:GetPerPageSize()
        local page = dbFilterState.currentPage or 1
        local startIdx = ((page - 1) * perPage) + 1
        local endIdx = math.min(#favItems, page * perPage)

        table.insert(rows, {
            tint = "SPEC_HEADER",
            onClickAction = function()
                dbFilterState.showFavoritesOnly = false
                dbFilterState.currentPage = 1
                UpdateDBFavToggleText()
                MainPanel:RenderActivePane()
            end,
            text = string.format("|cffffd100★ FAVORITE ITEMS LIST (%d Saved • Page %d/%d) — Click [★ Favs: ON] or this banner to return to normal catalog|r",
                #favItems, page, dbFilterState.totalPages or 1)
        })

        if #favItems == 0 then
            table.insert(rows, {
                text = "  |cff888888Your Item Favorites list is empty (or filtered out by Quality). Click the [☆] star on any item card (or Alt+Click any item) to save it here!|r"
            })
            self:RenderRowList(rows)
            return
        end

        for i = startIdx, endIdx do
            local m = favItems[i]
            local hex = QUALITY_HEX[m.quality or 3] or "0070dd"
            local link = string.format("|cff%s|Hitem:%d:0:0:0:0:0:0:0:60|h[%s]|h|r", hex, m.id, m.name)
            local srcTag = m.sourceLine and ("\n     " .. m.sourceLine) or ""

            -- Primary Itemized Row (Left-Click: Try On • Right-Click: Open Full Dossier • Alt+Click: Unfavorite)
            table.insert(rows, {
                icon = m.icon,
                link = link,
                inspectID = m.id,
                recommendNote = m.sourceLine,
                onClickAction = function()
                    MainPanel:TryOnItemInTab6(link, m.name)
                end,
                onRightClickAction = function()
                    MainPanel._state.inspectedItemID = m.id
                    MainPanel:RenderActivePane()
                end,
                onAltClickAction = function()
                    MainPanel:ToggleItemFavorite(m.id, m)
                    UpdateDBFavToggleText()
                    MainPanel:RenderActivePane()
                end,
                text = string.format("|cffffd100★|r |cff00ff96[Lvl %d]|r |cff88ccff[#%d]|r %s  |cffcccccc(%s, iLvl %d)|r  |cff00ff96[Left-Click: Try On • Right-Click: Dossier]|r%s",
                    m.reqLvl or 1, m.id, link, m.subType or "Gear", m.iLvl or 1, srcTag)
            })

            -- Action Toolbar Sub-Row: Track GPS, Find Questline, Unfavorite
            table.insert(rows, {
                tint = "RECOMMEND",
                onClickAction = function()
                    if ns.AcquisitionDB and ns.AcquisitionDB.OpenItemQuestlineDossier then
                        ns.AcquisitionDB:OpenItemQuestlineDossier(m.id, m.name)
                    end
                end,
                onRightClickAction = function()
                    if ns.ForeverIndex and ns.ForeverIndex.GuideToItem then
                        ns.ForeverIndex:GuideToItem(m.id)
                    end
                end,
                onAltClickAction = function()
                    MainPanel:ToggleItemFavorite(m.id, m)
                    UpdateDBFavToggleText()
                    MainPanel:RenderActivePane()
                end,
                text = "     |cffffd100↳ Actions:|r |cff00ff96[Left-Click: Find Questline / Drop Dossier]|r   •   |cff00ccff[Right-Click: Track 3D GPS Waypoint]|r   •   |cffff8888[Alt+Click: Remove ★]|r"
            })
        end

        self:RenderRowList(rows)
        return
    end

    local queryLower = string.lower(dbSearchQuery or "")
    local matches = {}
    local seenIDs = {}
    local maxCollect = 1800

    local function CollectDatabaseMatches()
        -- 1. First query our local Master Holding Tank (DB_MasterHoldingTank.lua), matched against WoW Forever's server cache!
        if ns.MasterDB and ns.MasterDB.SearchRecords then
            local masterHits = ns.MasterDB:SearchRecords(dbSearchQuery, nil, nil, 600)
            for i = 1, #masterHits do
                local r = masterHits[i]
                if r and r.ID and r.ID > 0 and (r.IDType == "Item" or r.IDType == "DB_Entry") and not seenIDs[r.ID] then
                    local cached = AltVaultDB and AltVaultDB.ItemCache and AltVaultDB.ItemCache[r.ID]
                    if not cached and ns.Scanner and ns.Scanner.CacheItemData then
                        if C_Item and C_Item.RequestLoadItemDataByID then
                            pcall(C_Item.RequestLoadItemDataByID, r.ID)
                        end
                        ns.Scanner.CacheItemData(r.ID, true)
                        cached = AltVaultDB and AltVaultDB.ItemCache and AltVaultDB.ItemCache[r.ID]
                    end

                    -- Only display Holding Tank items that are verified by the WoW Forever server & pass Level <= 60 rules!
                    if cached and cached.n then
                        local iType = cached.t or "Armor"
                        local iSub  = (cached.st ~= "" and cached.st) or r.Category or r.ContentType or "Gear"
                        local eqLoc = cached.eq or ""
                        local clStr = cached.cl
                        local raStr = cached.ra

                        if DoesItemPassTab6Filters(r.ID, iType, iSub, eqLoc, clStr, raStr, r.Faction, cached.n, cached.q, cached.l, cached.r, cached.c) then
                            seenIDs[r.ID] = true
                            local srcSummary = ns.MasterDB:FormatRecordSummaryLine(r)
                            table.insert(matches, {
                                id = r.ID,
                                name = cached.n,
                                quality = cached.q or 3,
                                iLvl = cached.l or 1,
                                reqLvl = ResolveEffectiveCharLevel(cached.r, cached.l) or 1,
                                subType = iSub,
                                icon = cached.i or cached.ic or GetItemIconTexture(r.ID) or "Interface\\Icons\\INV_Misc_QuestionMark",
                                sourceLine = srcSummary,
                            })
                            if #matches >= maxCollect then break end
                        end
                    end
                end
            end
        end

        -- 2. Supplement with items in AltVaultDB.ItemCache
        if AltVaultDB and AltVaultDB.ItemCache and #matches < maxCollect then
            for id, info in pairs(AltVaultDB.ItemCache) do
                if type(id) == "number" and not seenIDs[id] and type(info) == "table" and info.n then
                    if queryLower == ""
                        or tostring(id) == queryLower
                        or string.find(string.lower(info.n), queryLower, 1, true)
                        or (info.st and string.find(string.lower(info.st), queryLower, 1, true))
                        or (info.t and string.find(string.lower(info.t), queryLower, 1, true)) then

                        if DoesItemPassTab6Filters(id, info.t, info.st, info.eq, info.cl, info.ra, nil, info.n, info.q, info.l, info.r, info.c) then
                            seenIDs[id] = true
                            local srcLines = (ns.MasterDB and ns.MasterDB.GetFormattedSourceLines and ns.MasterDB:GetFormattedSourceLines(id, 1)) or nil
                            table.insert(matches, {
                                id = id,
                                name = info.n,
                                quality = info.q or 1,
                                iLvl = info.l or 1,
                                reqLvl = ResolveEffectiveCharLevel(info.r, info.l) or 1,
                                subType = (info.st ~= "" and info.st) or info.t or "Item",
                                icon = info.i or info.ic or GetItemIconTexture(id) or "Interface\\Icons\\INV_Misc_QuestionMark",
                                sourceLine = srcLines and srcLines[1] or nil,
                            })
                            if #matches >= maxCollect then break end
                        end
                    end
                end
            end
        end

        -- 3. Supplement directly from the 15,534-item ForeverIndex (Instant binary search + BiS + Gold Flip + Coordinates!)
        if ns.ForeverIndex and #matches < maxCollect then
            local candidateIDs = {}
            if queryLower ~= "" and ns.ForeverIndex.Search then
                local hits = ns.ForeverIndex:Search(queryLower, 500)
                for _, h in ipairs(hits) do
                    table.insert(candidateIDs, h.id)
                end
            elseif ns.ForeverIndex.GetAllIDs then
                local allIDs = ns.ForeverIndex:GetAllIDs()
                for i = 1, #allIDs do
                    local fid = allIDs[i]
                    if fid and not seenIDs[fid] then
                        table.insert(candidateIDs, fid)
                    end
                end
            elseif ns.MasterDB and ns.MasterDB.AllRecords then
                for _, rec in ipairs(ns.MasterDB.AllRecords) do
                    if rec.itemID and not seenIDs[rec.itemID] then
                        table.insert(candidateIDs, rec.itemID)
                        if #candidateIDs >= 6000 then break end
                    end
                end
            end

            local isForeverClient = (select(4, GetBuildInfo()) == 16001)
            for _, id in ipairs(candidateIDs) do
                if not seenIDs[id] then
                    local instID, instType, instSub, instEquip, instIcon = nil, nil, nil, nil, nil
                    if GetItemInfoInstant then
                        instID, instType, instSub, instEquip, instIcon = GetItemInfoInstant(id)
                    end
                    -- If running on Classic Era / non-Forever client, skip custom 200k+ Forever-only IDs that don't exist on this server!
                    if isForeverClient or instID ~= nil then
                        local fInfo = ns.ForeverIndex:Info(id)
                        if fInfo and fInfo.name then
                            local effType = (fInfo.itemType and fInfo.itemType ~= "" and fInfo.itemType) or instType or "Armor"
                            local effSub  = (fInfo.itemSubType and fInfo.itemSubType ~= "" and fInfo.itemSubType) or instSub or effType
                            local effEq   = (fInfo.equipLoc and fInfo.equipLoc ~= "" and fInfo.equipLoc) or instEquip or ""
                            if DoesItemPassTab6Filters(id, effType, effSub, effEq, nil, nil, nil, fInfo.name, fInfo.quality, fInfo.itemLevel, fInfo.reqLevel, fInfo.classID) then
                                seenIDs[id] = true
                                local src = ns.ForeverIndex:GetItemSourceAndCoords(id)
                                local srcLine = nil
                                if src then
                                    local coordStr = (src.x and src.y and src.x > 0) and string.format(" (%.1f, %.1f)", src.x, src.y) or ""
                                    srcLine = string.format("|cff00ccff📍 %s:|r %s — %s%s",
                                        src.typeLabel or "Source", src.npc or "Drop", src.zone or "Azeroth", coordStr)
                                end
                                table.insert(matches, {
                                    id = id,
                                    name = fInfo.name,
                                    quality = fInfo.quality or 1,
                                    iLvl = (fInfo.itemLevel and fInfo.itemLevel > 0) and fInfo.itemLevel or math.max(1, fInfo.reqLevel or 1),
                                    reqLvl = ResolveEffectiveCharLevel(fInfo.reqLevel, fInfo.itemLevel) or 1,
                                    subType = effSub,
                                    icon = instIcon or GetItemIconTexture(id) or "Interface\\Icons\\INV_Misc_QuestionMark",
                                    sourceLine = srcLine,
                                })
                                if #matches >= maxCollect then break end
                            end
                        end
                    end
                end
            end
        end
    end

    CollectDatabaseMatches()

    -- If My Lvl mode is active and found too few items (< 4), widen slightly around player level so a handful always loads
    if #matches < 4 and dbFilterState.autoLevelDefault and queryLower == "" then
        local savedMin, savedMax = dbFilterState.minLvl, dbFilterState.maxLvl
        dbFilterState.minLvl = 1
        dbFilterState.maxLvl = math.min(60, math.max(20, (savedMax or 10) + 12))
        CollectDatabaseMatches()
        dbFilterState.minLvl, dbFilterState.maxLvl = savedMin, savedMax
    end

    -- Sort items starting at Level 1 ascending up to Level 60!
    table.sort(matches, function(a, b)
        local rA = a.reqLvl or 1
        local rB = b.reqLvl or 1
        if rA ~= rB then return rA < rB end
        local lA = a.iLvl or 1
        local lB = b.iLvl or 1
        if lA ~= lB then return lA < lB end
        if (a.quality or 1) ~= (b.quality or 1) then return (a.quality or 1) > (b.quality or 1) end
        return (a.id or 0) < (b.id or 0)
    end)

    UpdateDBPaginationControls(#matches)
    local perPage = self:GetPerPageSize()
    local page = dbFilterState.currentPage or 1
    local startIdx = ((page - 1) * perPage) + 1
    local endIdx = math.min(#matches, page * perPage)

    local pagedMatches = {}
    for i = startIdx, endIdx do
        table.insert(pagedMatches, matches[i])
    end

    -- Render in 3-Column Compact Grid Mode (Default) or Full List Mode
    if dbFilterState.useGridView and #pagedMatches > 0 then
        RenderDBMatchesAsCompactGrid("Compact Grid", pagedMatches)
        return
    end

    local headerNote = string.format("|cffffd100Showing %d–%d of %d Matching Items (Page %d/%d • Level 1→60 Order) — Left-Click: Try On • Right-Click: Dossier • Alt+Click: ★ Fav:|r",
        (#pagedMatches > 0 and startIdx or 0), endIdx, #matches, page, dbFilterState.totalPages or 1)
    table.insert(rows, { tint = "SPEC_HEADER", text = headerNote })

    for i = 1, #pagedMatches do
        local m = pagedMatches[i]
        local hex = QUALITY_HEX[m.quality or 3] or "0070dd"
        local link = string.format("|cff%s|Hitem:%d:0:0:0:0:0:0:0:60|h[%s]|h|r", hex, m.id, m.name)
        local srcTag = m.sourceLine and ("\n     " .. m.sourceLine) or ""
        local favStar = self:IsItemFavorite(m.id) and "|cffffd100★|r " or "|cff666666☆|r "

        table.insert(rows, {
            icon = m.icon,
            link = link,
            inspectID = m.id,
            recommendNote = m.sourceLine,
            onClickAction = function()
                MainPanel:TryOnItemInTab6(link, m.name)
            end,
            onAltClickAction = function()
                local nowFav = MainPanel:ToggleItemFavorite(m.id, m)
                UpdateDBFavToggleText()
                print(string.format("|cff00ccff[AltVault]|r %s %s Favorites.", m.name or ("Item #" .. m.id), nowFav and "|cff00ff00added to|r" or "|cffff6666removed from|r"))
                MainPanel:RenderActivePane()
            end,
            text = string.format("%s|cff00ff96[Lvl %d]|r |cff88ccff[#%d]|r %s  |cffcccccc(%s, iLvl %d)|r  |cff00ff96[👗 Try On]|r%s",
                favStar, m.reqLvl or 1, m.id, link, m.subType, m.iLvl or 1, srcTag)
        })
    end

    if #matches == 0 then
        table.insert(rows, { text = "  |cff888888No items matched your current Class / Armor / Level / Quality filters. Click [Reset] or [All Qualities] to expand!|r" })
    end

    self:RenderRowList(rows)
end

function MainPanel:AppendTalentTreeRows(rows, data)
    table.insert(rows, { tint = "SPEC_HEADER", text = "|cffffd100Selected Talents by Specialization & Tier (Hover any talent card for description):|r" })

    local trees = data.talentTrees or {}
    local anyPointsSpent = false

    for _, tree in ipairs(trees) do
        local numTalents = tree.talents and #tree.talents or 0
        if (tree.points and tree.points > 0) or numTalents > 0 then
            anyPointsSpent = true
            table.insert(rows, {
                icon = tree.icon,
                tint = "SPEC_HEADER",
                text = string.format("|cffffd100[%s Specialization]|r  —  |cff00ff00%d Points Spent|r", tree.name or "Spec", tree.points or numTalents)
            })

            for _, tal in ipairs(tree.talents or {}) do
                local minLvl = tal.minLevel or (10 + (((tal.tier or 1) - 1) * 5))
                local rankColor = (tal.rank == tal.maxRank) and "|cffffd100" or "|cff00ff00"
                table.insert(rows, {
                    icon = tal.icon or "Interface\\Icons\\INV_Misc_QuestionMark",
                    talentData = {
                        name = tal.name,
                        specName = tree.name,
                        tier = tal.tier or 1,
                        minLevel = minLvl,
                        rank = tal.rank or 1,
                        maxRank = tal.maxRank or 5,
                        desc = tal.desc
                    },
                    text = string.format("|cff88ccff[Tier %d - Lvl %d]|r  |cffffffff%s|r   %s(%d/%d)|r", tal.tier or 1, minLvl, tal.name or "Talent", rankColor, tal.rank or 1, tal.maxRank or 5)
                })
            end
        end
    end

    if not anyPointsSpent then
        table.insert(rows, { text = "  |cff888888No spent talent points recorded for this character yet.|r" })
        table.insert(rows, { text = "  • Log onto this character (or open your Talent Window |cffffff00[N]|r) to snapshot their talent trees." })
    end
end

function MainPanel:RenderActivePane()
    self:RefreshPeerSidebarList()
    self:UpdateLeftSidebarHighlights()
    self:ApplyGlobalButtonScaling(true)
    ActiveFlyoutMenu:Hide()
    HideItemHoverFlyout()
    if self.ClearAllScrollContent then
        self:ClearAllScrollContent()
    else
        HideAllDBGridCells()
    end

    local leftX = self:GetLeftColumnOffset()
    local baseTopY = self:GetBaseContentTopY()
    local bScale = self:GetButtonScale()
    local activeViewMode = self._state.activeViewMode
    local selectedCharacter = self._state.selectedCharacter
    local selectedSyncedPeer = self._state.selectedSyncedPeer
    local selectedFaction = self:GetSelectedFaction()

    self._state.customScrollTopOffset = nil
    if self.OnBeforeRenderActivePane then
        self:OnBeforeRenderActivePane(activeViewMode)
    end

    -- TAB 1 (ARMORY): Delegates to UI_ArmoryPaperDoll modules (100% Untouched!)
    if activeViewMode == "ARMORY" and self.RenderVisualCharacterDashboard then
        DBHeaderFrame:Hide()
        DBDressUpDrawer:Hide()
        if self._state.previewQueueEntry and self._state.previewQueueEntry.previewData then
            self:RenderVisualCharacterDashboard(self._state.previewQueueEntry.sender or "Preview", self._state.previewQueueEntry.previewData, true)
            return
        elseif selectedSyncedPeer and AltVaultDB and AltVaultDB.GuildNetwork and AltVaultDB.GuildNetwork[selectedSyncedPeer] then
            self:RenderVisualCharacterDashboard(selectedSyncedPeer, AltVaultDB.GuildNetwork[selectedSyncedPeer], true)
            return
        elseif selectedCharacter and AltVaultDB and AltVaultDB.Characters and AltVaultDB.Characters[selectedCharacter] then
            self:RenderVisualCharacterDashboard(selectedCharacter, AltVaultDB.Characters[selectedCharacter], false)
            return
        end
    end

    if self.HideArmoryCanvas then self:HideArmoryCanvas() end

    if activeViewMode == "DATABASE" then
        DBHeaderFrame:Show()
        local dbHeaderH = math.max(126, math.floor(144 * bScale + 0.5))
        local contentTopY = baseTopY - dbHeaderH - 6

        -- Full-width ScrollFrame inside Tab 6 because DBDressUpDrawer is now an undocked floating window!
        ScrollFrame:ClearAllPoints()
        ScrollFrame:SetPoint("TOPLEFT", MainPanel, "TOPLEFT", leftX, contentTopY)
        ScrollFrame:SetPoint("BOTTOMRIGHT", MainPanel, "BOTTOMRIGHT", -32, 24)

        self:RenderDatabaseExplorerPane()
        return
    else
        DBHeaderFrame:Hide()
        if activeViewMode ~= "QUEST_FOR_ITEM" and activeViewMode ~= "QUEST_FOR_RECIPE" then
            DBDressUpDrawer:Hide()
        end
        local effectiveTopY = self._state.customScrollTopOffset or baseTopY
        ScrollFrame:ClearAllPoints()
        ScrollFrame:SetPoint("TOPLEFT", MainPanel, "TOPLEFT", leftX, effectiveTopY)
        ScrollFrame:SetPoint("BOTTOMRIGHT", MainPanel, "BOTTOMRIGHT", -32, 24)
    end

    if externalTabRenderers[activeViewMode] then
        externalTabRenderers[activeViewMode](self)
        return
    end

    if activeViewMode == "GUILD" then
        self:RenderGuildVaultPane()
        return
    end

    -- If a Synced Peer is selected in the sidebar, only show what they have explicitly synced with you!
    if selectedSyncedPeer and AltVaultDB and AltVaultDB.GuildNetwork and AltVaultDB.GuildNetwork[selectedSyncedPeer] then
        local peerData = AltVaultDB.GuildNetwork[selectedSyncedPeer]
        local peerRows = {
            {
                tint = "SPEC_HEADER",
                text = string.format("|cff00ccff[Synced Player: %s]|r (Lvl %d %s %s)   •   GearScore: %s   —   |cffffd100[Click to Return to Sync Queue & Hub]|r",
                    selectedSyncedPeer, peerData.level or 1, peerData.race or "", peerData.class or "?",
                    ns.Scanner.FormatGearScoreColor(peerData.gearScore or 0)),
                onClickAction = function()
                    MainPanel:SwitchToTab("SYNCED_ROSTER")
                end
            }
        }
        if activeViewMode == "TALENTS" then
            if not peerData.talentsSynced then
                table.insert(peerRows, {
                    tint = "UPGRADE_SOON",
                    text = string.format("  |cffffcc00[TALENT TREE CLOSED]|r  %s's Talent Tree has not been synced yet.  |cff00ff00[Click Here to Request Talent Tree Sync]|r", selectedSyncedPeer),
                    onClickAction = function()
                        if ns.GuildNet and ns.GuildNet.RequestPeerCategory then
                            ns.GuildNet.RequestPeerCategory(selectedSyncedPeer, "TALENTS")
                        end
                    end
                })
            else
                self:AppendTalentTreeRows(peerRows, peerData)
            end
        elseif activeViewMode == "BAGS" or activeViewMode == "BANK" then
            local isBags = (activeViewMode == "BAGS")
            local isUnlocked = isBags and peerData.bagsSynced or peerData.bankSynced
            local catTitle = isBags and "Bag Inventory" or "Personal Bank"
            if not isUnlocked then
                table.insert(peerRows, {
                    tint = "UPGRADE_SOON",
                    text = string.format("  |cffffcc00[%s CLOSED]|r  %s's %s is closed.  |cff00ff00[Click Here to Request %s Sync]|r",
                        string.upper(catTitle), selectedSyncedPeer, catTitle, catTitle),
                    onClickAction = function()
                        if ns.GuildNet and ns.GuildNet.RequestPeerCategory then
                            ns.GuildNet.RequestPeerCategory(selectedSyncedPeer, isBags and "BAGS" or "BANK")
                        end
                    end
                })
            else
                local list = isBags and (peerData.bags or {}) or (peerData.bank or {})
                table.insert(peerRows, {
                    tint = "SPEC_HEADER",
                    text = string.format("|cff00ff00%s's Synced %s (%d tradeable stacks):|r", selectedSyncedPeer, catTitle, #list)
                })
                for _, entry in ipairs(list) do
                    local ref = entry.link or entry.itemID
                    local _, link, _, _, _, _, _, _, _, icon = ns.Scanner.FetchItemInfo(ref)
                    local countStr = (entry.count and entry.count > 1) and (" |cffffff00x" .. entry.count .. "|r") or ""
                    table.insert(peerRows, {
                        icon = icon or GetItemIconTexture(ref) or "Interface\\Icons\\INV_Misc_Bag_08",
                        link = link or ("item:" .. tostring(ref)),
                        text = tostring(link or ("Item #" .. tostring(ref))) .. countStr .. "   |cffffd100[Click to Whisper / Mail " .. selectedSyncedPeer .. "]|r",
                        onClickAction = function()
                            if ns.NetUI and ns.NetUI.ContactOrMailSyncedPlayer then
                                ns.NetUI.ContactOrMailSyncedPlayer(selectedSyncedPeer, link or ("Item #" .. tostring(ref)), false)
                            end
                        end
                    })
                end
            end
        end
        self:RenderRowList(peerRows)
        return
    end

    if not selectedCharacter or not AltVaultDB.Characters[selectedCharacter] then
        self:RenderRowList({
            { tint = "SPEC_HEADER", text = "|cffffd100No Characters Recorded Yet for Faction: " .. tostring(selectedFaction) .. "|r" },
            { text = "• Log onto a character on this faction to automatically record their Armory, Talents, Bags & Bank." },
        })
        return
    end

    local data = AltVaultDB.Characters[selectedCharacter]
    local totalGS, avgILvl = ns.Scanner.CalculateCharacterGearScore(data.gear)
    if totalGS and totalGS > 0 then data.gearScore = totalGS else totalGS = data.gearScore or 0 end

    local rows = {
        {
            tint = "SPEC_HEADER",
            text = string.format("|cffffff00%s|r (Lvl %d %s %s)   •   Total GearScore: %s (Avg iLvl %d)",
                selectedCharacter, data.level or 1, data.race or "", data.class or "?",
                ns.Scanner.FormatGearScoreColor(totalGS), avgILvl or 0)
        }
    }

    if activeViewMode == "BAGS" or activeViewMode == "BANK" then
        local items = (activeViewMode == "BAGS") and (data.bags or {}) or (data.bank or {})
        local title = (activeViewMode == "BAGS") and "Bag Inventory" or "Personal Bank"
        table.insert(rows, {
            tint = "SPEC_HEADER",
            text = string.format("|cffffd100%s (%d stacks) — Right-Click any item to turn RED (Hide from Trade & Other Players):|r", title, #items)
        })

        for _, entry in ipairs(items) do
            local ref = entry.link or entry.itemID
            local isLocked = ns.DB and ns.DB.IsItemTradeLocked and ns.DB.IsItemTradeLocked(ref)
            local countStr = (entry.count and entry.count > 1) and (" |cffffff00x" .. entry.count .. "|r") or ""
            local itemGS, iLvl = ns.Scanner.CalculateItemGearScore(ref)
            local recText, tint, note = FormatRecommendationTags(ref, data.faction)
            if isLocked then
                tint = "LOCKED_RED"
                recText = "   |cffff2020[✖ NOT FOR TRADE — HIDDEN FROM PLAYERS]|r"
                note = "|cffff2020[NOT FOR TRADE — Hidden from Synced Players & Trade Tabs]|r\n|cffffcc00Right-Click: Unlock & allow trading|r"
            else
                note = (note and note ~= "" and (note .. "\n") or "") .. "|cffffcc00Right-Click: Mark Not For Trade (Turns RED & Hides from Players)|r"
            end
            local icon = entry.icon or GetItemIconTexture(ref) or "Interface\\Icons\\INV_Misc_Bag_08"
            table.insert(rows, {
                icon = icon,
                link = entry.link or (ref and ("item:" .. tostring(ref))),
                gs = itemGS,
                iLvl = iLvl,
                tint = tint,
                recommendNote = note,
                onRightClickAction = function()
                    if ns.DB and ns.DB.ToggleItemTradeLock then
                        ns.DB.ToggleItemTradeLock(ref)
                        MainPanel:RenderActivePane()
                    end
                end,
                text = tostring(entry.link or ("Item #" .. tostring(entry.itemID))) .. countStr .. recText
            })
        end

    elseif activeViewMode == "TALENTS" then
        self:AppendTalentTreeRows(rows, data)
    end

    self:RenderRowList(rows)
end

function MainPanel:RenderGuildVaultPane()
    local selectedFaction = self:GetSelectedFaction()
    local rows = {
        { tint = "SPEC_HEADER", text = "|cffffd100Outside Guild Vault — Items Posted from Your Guild & Synced Outside Guilds|r" },
        { text = "  |cffccccccRight-Click any item in your Guild Vault to turn it |cffff2020RED|cffcccccc (hides it from outside guilds while keeping it visible to your own guildmates).|r" },
    }
    local vaults = AltVaultDB and AltVaultDB.GuildVaults or {}
    local foundAny = false
    local localGuildsSeen = {}

    for guildName, vaultData in pairs(vaults) do
        if not selectedFaction or vaultData.faction == selectedFaction then
            foundAny = true
            localGuildsSeen[guildName] = true
            table.insert(rows, {
                tint = "SPEC_HEADER",
                text = string.format("|cff00ff00<%s> (Your Scanned Guild Vault)|r  |cffaaaaaa(Last Scanned: %s)|r", guildName, vaultData.lastUpdated or "Unknown")
            })
            if vaultData.tabs then
                for tabIndex = 1, 8 do
                    local tabInfo = vaultData.tabs[tabIndex]
                    if tabInfo then
                        table.insert(rows, {
                            tint = "UPGRADE",
                            text = string.format("|cffffff00[%s]|r", tabInfo.name or ("Tab " .. tabIndex))
                        })
                        for _, item in ipairs(tabInfo.items or {}) do
                            local itemRef = item.link
                            local isLocked = ns.DB and ns.DB.IsItemTradeLocked and ns.DB.IsItemTradeLocked(itemRef)
                            local countStr = (item.count and item.count > 1) and (" |cffffff00x" .. item.count .. "|r") or ""
                            local recText, tint, note = FormatRecommendationTags(itemRef, vaultData.faction)
                            if isLocked then
                                tint = "LOCKED_RED"
                                recText = "   |cffff2020[✖ HIDDEN FROM OUTSIDE GUILDS (Visible Only to <" .. guildName .. ">)]|r"
                                note = "|cffff2020[HIDDEN FROM OUTSIDE GUILDS]|r\nOnly members of <" .. guildName .. "> can see this item.\n|cffffcc00Right-Click: Unlock to share with Outside Guilds|r"
                            else
                                note = (note and note ~= "" and (note .. "\n") or "") .. "|cffffcc00Right-Click: Turn RED (Hide from Outside Guilds)|r"
                            end
                            local icon = item.icon or GetItemIconTexture(itemRef) or "Interface\\Icons\\INV_Misc_Coin_02"
                            table.insert(rows, {
                                icon = icon,
                                link = itemRef,
                                tint = tint,
                                recommendNote = note,
                                onRightClickAction = function()
                                    if ns.DB and ns.DB.ToggleItemTradeLock then
                                        ns.DB.ToggleItemTradeLock(itemRef)
                                        MainPanel:RenderActivePane()
                                    end
                                end,
                                text = tostring(itemRef) .. countStr .. recText
                            })
                        end
                    end
                end
            end
        end
    end

    -- Also render Outside Guild Vault items posted by Synced Players in the Virtual Guild Network!
    if AltVaultDB and AltVaultDB.GuildNetwork then
        for peerName, peerData in pairs(AltVaultDB.GuildNetwork) do
            if not (AltVaultDB.Characters and AltVaultDB.Characters[peerName]) then
                if (not selectedFaction or peerData.faction == selectedFaction) and type(peerData.guildVault) == "table" and next(peerData.guildVault) then
                    local peerGuild = peerData.guild or (peerName .. "'s Guild")
                    foundAny = true
                    table.insert(rows, {
                        tint = "SPEC_HEADER",
                        text = string.format("|cff00ccff<%s> — Posted by Synced Member %s|r  |cffaaaaaa(Last Synced: %s)|r",
                            peerGuild, peerName, peerData.lastSeen or "Recently")
                    })
                    for tabName, tabItems in pairs(peerData.guildVault) do
                        if type(tabItems) == "table" and next(tabItems) then
                            table.insert(rows, {
                                tint = "UPGRADE",
                                text = string.format("|cffffff00[%s]|r  |cff88ccff(Click any item to Whisper / Mail %s)|r", tabName, peerName)
                            })
                            for itemID, count in pairs(tabItems) do
                                local name, link, _, _, _, _, _, _, _, icon = ns.Scanner.FetchItemInfo(itemID)
                                local dispLink = link or ("item:" .. tostring(itemID))
                                local countStr = (count and count > 1) and (" |cffffff00x" .. count .. "|r") or ""
                                local recText, tint, note = FormatRecommendationTags(dispLink, selectedFaction)
                                table.insert(rows, {
                                    icon = icon or GetItemIconTexture(itemID) or "Interface\\Icons\\INV_Misc_Coin_02",
                                    link = dispLink,
                                    tint = tint,
                                    recommendNote = (note and note ~= "" and (note .. "\n") or "") .. "|cffffd100Left-Click: Whisper / Mail " .. peerName .. " about this Outside Guild Vault item!|r",
                                    onClickAction = function()
                                        if ns.NetUI and ns.NetUI.ContactOrMailSyncedPlayer then
                                            ns.NetUI.ContactOrMailSyncedPlayer(peerName, link or name or ("Item #" .. tostring(itemID)), false)
                                        end
                                    end,
                                    text = tostring(link or name or ("Item #" .. tostring(itemID))) .. countStr .. recText .. "   |cff00ccff[Posted by " .. peerName .. "]|r"
                                })
                            end
                        end
                    end
                end
            end
        end
    end

    if not foundAny then
        table.insert(rows, { text = "No Outside Guild Vault items recorded yet for this faction. Open your Guild Bank in-game or sync with players to populate this tab!" })
    end
    self:RenderRowList(rows)
end