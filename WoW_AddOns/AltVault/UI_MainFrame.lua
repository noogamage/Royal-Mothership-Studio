-- ============================================================================
-- FILE: UI_MainFrame.lua (MODULE 1 OF 3 SPLIT FROM UI_MainPanel.lua)
-- BLOCK HEADING: GLOBAL INITIALIZATION & DRAGGABLE/RESIZABLE FRAME SETUP
-- ============================================================================
local addonName, ns = ...

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

local okBtnTpl, MainPanel = pcall(CreateFrame, "Frame", "AltVaultMainPanel", UIParent, "ButtonFrameTemplate")
local isLegacyFrame = false
if not okBtnTpl or not MainPanel then
    isLegacyFrame = true
    MainPanel = CreateBackdrop("Frame", "AltVaultMainPanel", UIParent)
    if MainPanel.SetBackdrop then
        MainPanel:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 24,
            insets = { left = 6, right = 6, top = 6, bottom = 6 }
        })
        MainPanel:SetBackdropColor(0.04, 0.05, 0.08, 0.97)
    end
    MainPanel.CloseBtn = CreateFrame("Button", nil, MainPanel, "UIPanelCloseButton")
    MainPanel.CloseBtn:SetPoint("TOPRIGHT", MainPanel, "TOPRIGHT", -2, -2)
    MainPanel.TitleText = MainPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    MainPanel.TitleText:SetPoint("TOP", MainPanel, "TOP", 0, -9)
end

local BASE_PANEL_W = 960
local BASE_PANEL_H = 700
local STANDARD_FONT = "Fonts\\FRIZQT__.TTF"

MainPanel.BASE_PANEL_W = BASE_PANEL_W
MainPanel.BASE_PANEL_H = BASE_PANEL_H
MainPanel.STANDARD_FONT = STANDARD_FONT
MainPanel.CreateBackdrop = CreateBackdrop
MainPanel.SetSolid = SetSolid

MainPanel._state = {
    selectedFaction = nil,
    selectedCharacter = nil,
    selectedSyncedPeer = nil,
    peerSearchQuery = "",
    activeViewMode = "ARMORY",
    dbSearchQuery = "",
    inspectedItemID = nil,
    customScrollTopOffset = nil,
}

MainPanel.charButtons = {}
MainPanel.peerButtons = {}
MainPanel.contentRows = {}
MainPanel.exteriorTabs = {}
MainPanel.externalTabRenderers = {}

MainPanel.QUALITY_HEX = {
    [0] = "9d9d9d", [1] = "ffffff", [2] = "1eff00",
    [3] = "0070dd", [4] = "a335ee", [5] = "ff8000",
    [6] = "e6cc80", [7] = "00ccff",
}

MainPanel.QUALITY_FILTER_DEFS = {
    { key = 0, q = 0, label = "Grey",     hex = "9d9d9d", full = "Poor (Grey)"              },
    { key = 1, q = 1, label = "Common",   hex = "ffffff", full = "Common (White)"           },
    { key = 2, q = 2, label = "Uncommon", hex = "1eff00", full = "Uncommon (Green)"         },
    { key = 3, q = 3, label = "Rare",     hex = "0070dd", full = "Rare (Blue)"              },
    { key = 4, q = 4, label = "Epic",     hex = "a335ee", full = "Epic (Purple)"            },
    { key = 5, q = 5, label = "Legend+",  hex = "ff8000", full = "Legendary / Heirloom (5+)" },
}

MainPanel.PAGE_SIZE_OPTIONS = {
    { count = 12,   label = "Per Page: 12"  },
    { count = 20,   label = "Per Page: 20"  },
    { count = 30,   label = "Per Page: 30"  },
    { count = 45,   label = "Per Page: 45"  },
    { count = 60,   label = "Per Page: 60"  },
    { count = 90,   label = "Per Page: 90"  },
    { count = 9999, label = "Per Page: All" },
}

function MainPanel:GetPerPageSize()
    local saved = AltVaultDB and tonumber(AltVaultDB.PerPageCount)
    if saved and saved >= 6 then return saved end
    return 20
end

function MainPanel:SetPerPageSize(count)
    local c = tonumber(count) or 20
    if AltVaultDB then
        AltVaultDB.PerPageCount = c
    end
end

function MainPanel:DoesQualityPassMask(itemQuality, qualityMask)
    if not qualityMask then return true end
    local q = tonumber(itemQuality)
    if q == nil then q = 1 end
    if q < 0 then q = 0 end
    if q >= 5 then
        return qualityMask[5] == true
    end
    return qualityMask[q] == true
end

function MainPanel.GetItemIconTexture(linkOrID)
    if not linkOrID then return nil end
    if C_Item and C_Item.GetItemIconByID then return C_Item.GetItemIconByID(linkOrID)
    elseif GetItemIcon then return GetItemIcon(linkOrID) end
    local _, _, _, _, _, _, _, _, _, icon = ns.Scanner.FetchItemInfo(linkOrID)
    return icon
end

MainPanel:SetSize(BASE_PANEL_W, BASE_PANEL_H)
MainPanel:SetPoint("CENTER", UIParent, "CENTER", -80, 0)

MainPanel:SetFrameStrata("DIALOG")
MainPanel:SetFrameLevel(120)
MainPanel:SetToplevel(true)

MainPanel:SetMovable(true)
MainPanel:EnableMouse(true)
MainPanel:SetClampedToScreen(true)
MainPanel:RegisterForDrag("LeftButton")
MainPanel:SetScript("OnDragStart", function(self)
    self:Raise()
    self:StartMoving()
end)
MainPanel:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
MainPanel:SetScript("OnMouseDown", function(self) self:Raise() end)
MainPanel:SetScript("OnShow", function(self)
    self:SetFrameStrata("DIALOG")
    self:Raise()
    if ns.DB and ns.DB.SyncOnceOnAppOpen then
        ns.DB.SyncOnceOnAppOpen()
    end
    if self.RefreshView then
        self:RefreshView()
    end
end)

if MainPanel.SetResizable then MainPanel:SetResizable(true) end
if MainPanel.SetResizeBounds then
    MainPanel:SetResizeBounds(680, 500, 1550, 1080)
else
    if MainPanel.SetMinResize then MainPanel:SetMinResize(680, 500) end
    if MainPanel.SetMaxResize then MainPanel:SetMaxResize(1550, 1080) end
end

MainPanel:Hide()

if not isLegacyFrame and ButtonFrameTemplate_HidePortrait then
    pcall(ButtonFrameTemplate_HidePortrait, MainPanel)
end
if MainPanel.SetTitle then
    MainPanel:SetTitle("AltVault Armory, Talents & Guild Crafter Network")
elseif MainPanel.TitleText then
    MainPanel.TitleText:SetText("AltVault Armory, Talents & Guild Crafter Network")
end

tinsert(UISpecialFrames, "AltVaultMainPanel")

local ResizeGrip = CreateFrame("Button", nil, MainPanel)
ResizeGrip:SetSize(22, 22)
ResizeGrip:SetPoint("BOTTOMRIGHT", MainPanel, "BOTTOMRIGHT", -4, 4)
ResizeGrip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
ResizeGrip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
ResizeGrip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
ResizeGrip:SetFrameStrata("DIALOG")
ResizeGrip:SetFrameLevel(MainPanel:GetFrameLevel() + 25)
ResizeGrip:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" then
        MainPanel:Raise()
        if MainPanel.StartSizing then
            pcall(MainPanel.StartSizing, MainPanel, "BOTTOMRIGHT")
        end
    end
end)
ResizeGrip:SetScript("OnMouseUp", function(self, button)
    MainPanel:StopMovingOrSizing()
    MainPanel:UpdateLayoutSizes()
end)

-- ============================================================================
-- BLOCK HEADING: TALL TOP HEADER DECK, FACTION BUTTONS & AUTO-WINDOW SCALING
-- ============================================================================
local TopHeaderBar = CreateBackdrop("Frame", "AltVaultTopHeaderBar", MainPanel)
TopHeaderBar:SetPoint("TOPLEFT", MainPanel, "TOPLEFT", 6, -23)
TopHeaderBar:SetPoint("TOPRIGHT", MainPanel, "TOPRIGHT", -6, -23)
TopHeaderBar:SetHeight(56)
TopHeaderBar:SetFrameLevel(MainPanel:GetFrameLevel() + 4)
if TopHeaderBar.SetBackdrop then
    TopHeaderBar:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 14,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    TopHeaderBar:SetBackdropColor(0.07, 0.08, 0.11, 0.96)
    TopHeaderBar:SetBackdropBorderColor(0.55, 0.48, 0.30, 0.95)
end
MainPanel.TopHeaderBar = TopHeaderBar

function MainPanel:GetWindowScaleFactor()
    local curW = self:GetWidth() or BASE_PANEL_W
    local curH = self:GetHeight() or BASE_PANEL_H
    local wRatio = curW / 920
    local hRatio = curH / 660
    return math.max(0.76, math.min(1.65, math.min(wRatio, hRatio)))
end

function MainPanel:GetButtonScale()
    local winFactor = self:GetWindowScaleFactor()
    -- +10% larger base button & header scale that scales dynamically with the window!
    return math.max(0.84, math.min(1.80, winFactor * 1.12))
end

function MainPanel:GetTopHeaderHeight()
    local bScale = self:GetButtonScale()
    return math.max(46, math.floor(48 * bScale + 0.5))
end

function MainPanel:GetLeftColumnOffset()
    local bScale = self:GetButtonScale()
    local maxLeft = math.floor((self:GetWidth() or BASE_PANEL_W) * 0.29)
    return math.min(maxLeft, math.floor(152 * bScale) + 38)
end

function MainPanel:GetBaseContentTopY()
    return -(23 + self:GetTopHeaderHeight() + 6)
end

local function StripVisibleText(raw)
    if not raw then return "" end
    local s = tostring(raw)
    s = string.gsub(s, "|c%x%x%x%x%x%x%x%x", "")
    s = string.gsub(s, "|r", "")
    s = string.gsub(s, "|T[^|]+|t", " ")
    return s
end

function MainPanel:StyleControlButton(btn, baseWidth, baseHeight, baseFontSize, overrideScale)
    if not btn then return end
    local bScale = overrideScale or self:GetButtonScale()
    local w = btn:GetWidth() or 80
    local h = btn:GetHeight() or 26
    if baseWidth and baseHeight then
        w = math.max(46, math.floor(baseWidth * bScale + 0.5))
        h = math.max(22, math.floor(baseHeight * bScale + 0.5))
        btn:SetSize(w, h)
    end
    local cleanLen = math.max(3, #StripVisibleText(btn.GetText and btn:GetText() or "Btn"))
    local maxFitFont = math.max(10, math.min(17, math.floor((w - 10) / (cleanLen * 0.52))))
    local desiredFont = math.max(10, math.min(17, math.floor((baseFontSize or 12.5) * bScale + 0.5)))
    local fontSize = math.min(desiredFont, maxFitFont)
    local fs = btn.GetFontString and btn:GetFontString()
    if fs then
        if fs.SetFont then
            fs:SetFont(STANDARD_FONT, fontSize, "OUTLINE")
        end
        if fs.SetWordWrap then fs:SetWordWrap(false) end
        if fs.SetWidth then fs:SetWidth(math.max(24, w - 8)) end
    end
end

function MainPanel:StyleControlEditBox(box, placeholderFS, baseWidth, baseHeight, baseFontSize, overrideScale)
    if not box then return end
    local bScale = overrideScale or self:GetButtonScale()
    if baseWidth and baseHeight then
        box:SetSize(math.max(54, math.floor(baseWidth * bScale + 0.5)), math.max(22, math.floor(baseHeight * bScale + 0.5)))
    end
    local fontSize = math.max(10, math.min(16, math.floor((baseFontSize or 12.5) * bScale + 0.5)))
    if box.SetFont then
        box:SetFont(STANDARD_FONT, fontSize, "")
    end
    if placeholderFS and placeholderFS.SetFont then
        placeholderFS:SetFont(STANDARD_FONT, math.max(9, fontSize - 1), "")
    end
end

function MainPanel:FitControlsRowInsideBar(barFrame, leftPad, rightPad, gap, itemSpecs)
    if not barFrame or not itemSpecs or #itemSpecs == 0 then return end
    local bScale = self:GetButtonScale()
    local barW = barFrame:GetWidth()
    if not barW or barW <= 50 then
        barW = (self:GetWidth() or BASE_PANEL_W) - self:GetLeftColumnOffset() - 28
    end

    local availW = math.max(180, barW - (leftPad or 8) - (rightPad or 8) - ((#itemSpecs - 1) * (gap or 5)))
    local desiredTotalW = 0
    for _, spec in ipairs(itemSpecs) do
        desiredTotalW = desiredTotalW + (spec.baseW * bScale)
    end

    local widthScale = (desiredTotalW > availW) and (bScale * (availW / desiredTotalW)) or bScale
    local uniformRowFont = math.max(10, math.min(16, math.floor(12.2 * widthScale + 0.5)))
    local prevFrame = nil

    for idx, spec in ipairs(itemSpecs) do
        local f = spec.frame
        if f then
            local w = math.max(32, math.floor(spec.baseW * widthScale + 0.5))
            local h = math.max(22, math.floor(((spec.baseH or 26) * 1.08) * bScale + 0.5))
            if spec.isEditBox then
                self:StyleControlEditBox(f, spec.placeholder, spec.baseW, spec.baseH or 26, uniformRowFont, bScale)
                f:SetSize(w, h)
            elseif spec.isCustomContainer then
                f:SetSize(w, h)
            else
                f:SetSize(w, h)
                local fs = f.GetFontString and f:GetFontString()
                if fs then
                    local cleanLen = math.max(2, #StripVisibleText(f:GetText() or "Btn"))
                    local fitFont = math.max(9, math.min(uniformRowFont, math.floor((w - 8) / (cleanLen * 0.51))))
                    fs:SetFont(STANDARD_FONT, fitFont, "OUTLINE")
                    if fs.SetWordWrap then fs:SetWordWrap(false) end
                    if fs.SetWidth then fs:SetWidth(math.max(18, w - 6)) end
                end
            end
            f:ClearAllPoints()
            if idx == 1 then
                f:SetPoint("LEFT", barFrame, "LEFT", leftPad or 8, 0)
            else
                f:SetPoint("LEFT", prevFrame, "RIGHT", gap or 5, 0)
            end
            prevFrame = f
        end
    end
    return bScale
end

local AllianceBtn = CreateFrame("Button", nil, TopHeaderBar, "UIPanelButtonTemplate")
AllianceBtn:SetSize(112, 30)
AllianceBtn:SetPoint("LEFT", TopHeaderBar, "LEFT", 12, 0)
AllianceBtn:SetText("|cff0070ddAlliance|r")
AllianceBtn:SetScript("OnClick", function()
    MainPanel._state.selectedFaction = "Alliance"
    MainPanel._state.selectedCharacter = nil
    MainPanel._state.selectedSyncedPeer = nil
    MainPanel:RefreshView()
end)

local HordeBtn = CreateFrame("Button", nil, TopHeaderBar, "UIPanelButtonTemplate")
HordeBtn:SetSize(112, 30)
HordeBtn:SetPoint("LEFT", AllianceBtn, "RIGHT", 8, 0)
HordeBtn:SetText("|cffff2020Horde|r")
HordeBtn:SetScript("OnClick", function()
    MainPanel._state.selectedFaction = "Horde"
    MainPanel._state.selectedCharacter = nil
    MainPanel._state.selectedSyncedPeer = nil
    MainPanel:RefreshView()
end)

local HeaderStatusBanner = TopHeaderBar:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
HeaderStatusBanner:SetPoint("LEFT", HordeBtn, "RIGHT", 18, 0)
HeaderStatusBanner:SetPoint("RIGHT", TopHeaderBar, "RIGHT", -14, 0)
HeaderStatusBanner:SetJustifyH("LEFT")
HeaderStatusBanner:SetWordWrap(false)
HeaderStatusBanner:SetFont(STANDARD_FONT, 13, "OUTLINE")
HeaderStatusBanner:SetText("|cffffd100AltVault Forever|r  •  |cff88ccffDrag bottom-right corner to scale all tabs, buttons & text automatically|r")

MainPanel.AllianceBtn = AllianceBtn
MainPanel.HordeBtn = HordeBtn
MainPanel.HeaderStatusBanner = HeaderStatusBanner

-- ============================================================================
-- BLOCK HEADING: EXTERIOR SIDE TABS & MODULAR EXTENSION API
-- ============================================================================
local SIDE_TAB_CONFIG = {
    { id = "ARMORY",        label = "Profile",            tooltip = "Visual PaperDoll Armory + Usable Bag Box + Usable Bank Box + Professions & Stats! (Right-click items to mark Not For Trade)" },
    { id = "DATABASE",      label = "Dressing Room",      tooltip = "3D Dressing Room, Live Graphic Scanner Meter, Search by Item ID or Name, Class/Gear/Race Filters & Full Item Dossier!" },
    { id = "TALENTS",       label = "Talents & Specs",    tooltip = "View selected Talents organized by Spec Tree & Tier" },
    { id = "PHOTO_ALBUM",   label = "Photo Album",        tooltip = "1920x1009 Synchronized 12-Slot Photo Album, 20-Second Preloaded HD Videos, Pic Vault & Competition!" },
    { id = "BANK",          label = "Personal Bank",      tooltip = "View full Personal Bank cards (Right-Click any item to turn RED & hide from trade)" },
    { id = "VIRTUAL_CHAT",  label = "Virtual Guild Chat", tooltip = "Live Virtual Guild Chatroom powered by the addon whisper mesh—chat and link items with all online synced peers across any guild!" },
    { id = "BAGS",          label = "Bag Inventory",      tooltip = "View full Bag Inventory cards (Right-Click any item to turn RED & hide from trade)" },
    { id = "GUILD_GEAR",    label = "Guild Gear Needs",   tooltip = "See which Alts & Synced Players need craftable gear upgrades, who can craft them, and click any upgrade to locate its mats!" },
    { id = "GUILD_MATS",    label = "Guild Mat Search",   tooltip = "Locate crafting materials across Your Alts, Outside Guild Vaults, and Synced Players' Bags/Banks (Click to Whisper or Mail!)." },
    { id = "GUILD",         label = "Guild Vault",        tooltip = "View items posted from your Guild Vault and Synced Players' Outside Guild Vaults (Right-Click your items to turn RED & hide from outside guilds)" },
    { id = "SYNCED_ROSTER", label = "Sync Queue & Hub",   tooltip = "Consent-based Whisper Sync Queue (Waitlist), Preview Incoming Requests, Manage Synced Players, DND & Privacy Settings!" },
    { id = "GUILD_CONS",    label = "Consumables Net",    tooltip = "Track Potions, Elixirs, Scrolls, Food, Drink & Bandages across your Alts, Outside Guild Vaults & Synced Players." },
    { id = "QUEST_FOR_ITEM",   label = "Quest for Item",   tooltip = "Search any Gear or Item and see which Quest, Vendor, Quartermaster, or Dungeon Boss on BOTH Factions (Alliance & Horde) awards or sells it!" },
    { id = "QUEST_FOR_RECIPE", label = "Quest for Recipe", tooltip = "Search any Profession Recipe, Pattern, Plans, Schematic, or Formula and see which Vendor, Quest, Trainer, or Drop on BOTH Factions (Alliance & Horde) teaches it!" },
}

function MainPanel:UpdateExteriorTabVisuals()
    local activeMode = self._state.activeViewMode
    for _, tab in ipairs(self.exteriorTabs) do
        if tab.modeID == activeMode then tab:LockHighlight() else tab:UnlockHighlight() end
    end
    if self._state.selectedFaction == "Alliance" then
        AllianceBtn:LockHighlight()
        HordeBtn:UnlockHighlight()
    else
        HordeBtn:LockHighlight()
        AllianceBtn:UnlockHighlight()
    end
end

local function CreateSideTabButton(index, cfg)
    local sideTab = CreateFrame("Button", "AltVaultExtTab" .. index, MainPanel, "UIPanelButtonTemplate")
    sideTab.tabIndex = index
    sideTab:SetFrameStrata("DIALOG")
    sideTab:SetFrameLevel(MainPanel:GetFrameLevel() + 5)
    sideTab:SetSize(165, 32)
    sideTab:SetPoint("TOPLEFT", MainPanel, "TOPRIGHT", -2, -56 - ((index - 1) * 36))
    sideTab:SetText(cfg.label)
    sideTab.modeID = cfg.id
    sideTab:SetScript("OnClick", function(self)
        MainPanel:Raise()
        if MainPanel._state.activeViewMode ~= self.modeID and MainPanel.ScrollFrame then
            MainPanel.ScrollFrame:SetVerticalScroll(0)
        end
        MainPanel._state.activeViewMode = self.modeID
        MainPanel:UpdateExteriorTabVisuals()
        MainPanel:RenderActivePane()
    end)
    sideTab:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(cfg.label, 1, 0.82, 0)
        GameTooltip:AddLine(cfg.tooltip, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    sideTab:SetScript("OnLeave", function() GameTooltip:Hide() end)
    table.insert(MainPanel.exteriorTabs, sideTab)
    MainPanel:StyleControlButton(sideTab, 160, 30, 13)
    return sideTab
end

for i, cfg in ipairs(SIDE_TAB_CONFIG) do
    CreateSideTabButton(i, cfg)
end

function MainPanel:RegisterExternalTab(tabID, label, tooltip, renderCallback)
    self.externalTabRenderers[tabID] = renderCallback
    for _, existingBtn in ipairs(self.exteriorTabs) do
        if existingBtn.modeID == tabID then
            if self.ApplyGlobalButtonScaling then
                self:ApplyGlobalButtonScaling()
            end
            return existingBtn
        end
    end
    local nextIdx = #self.exteriorTabs + 1
    local btn = CreateSideTabButton(nextIdx, { id = tabID, label = label, tooltip = tooltip })
    if self.ApplyGlobalButtonScaling then
        self:ApplyGlobalButtonScaling()
    end
    return btn
end

function MainPanel:SwitchToTab(tabID)
    if self._state.activeViewMode ~= tabID and self.ScrollFrame then
        self.ScrollFrame:SetVerticalScroll(0)
    end
    self._state.activeViewMode = tabID
    self:UpdateExteriorTabVisuals()
    self:RenderActivePane()
end
MainPanel.SelectCategoryTab = MainPanel.SwitchToTab

function MainPanel:GetActiveViewMode()
    return self._state.activeViewMode
end

function MainPanel:GetSelectedFaction()
    local fac = self._state.selectedFaction
    if not fac or (fac ~= "Alliance" and fac ~= "Horde") then
        fac = UnitFactionGroup("player") or "Alliance"
        self._state.selectedFaction = fac
    end
    return fac
end

function MainPanel:GetSelectedCharacter()
    return self._state.selectedCharacter
end

function MainPanel:GetSelectedSyncedPeer()
    return self._state.selectedSyncedPeer
end

function MainPanel:SetSelectedSyncedPeer(peerName)
    self._state.selectedSyncedPeer = peerName
    if self.UpdateLeftSidebarHighlights then
        self:UpdateLeftSidebarHighlights()
    end
end

-- ============================================================================
-- BLOCK HEADING: LEVEL-SMART STARTUP BAND & PERSISTENT FAVORITES ENGINE
-- ============================================================================
function MainPanel:GetActiveCharacterLevel()
    local selPeer = self._state.selectedSyncedPeer
    if selPeer and AltVaultDB and AltVaultDB.GuildNetwork and AltVaultDB.GuildNetwork[selPeer] then
        local pl = tonumber(AltVaultDB.GuildNetwork[selPeer].level)
        if pl and pl >= 1 then return math.min(60, pl) end
    end
    local selChar = self._state.selectedCharacter
    if selChar and AltVaultDB and AltVaultDB.Characters and AltVaultDB.Characters[selChar] then
        local cl = tonumber(AltVaultDB.Characters[selChar].level)
        if cl and cl >= 1 then return math.min(60, cl) end
    end
    local liveLvl = UnitLevel and UnitLevel("player")
    if liveLvl and liveLvl >= 1 then return math.min(60, liveLvl) end
    return 1
end

function MainPanel:GetDefaultLevelBand(isRecipeMode)
    local charLvl = self:GetActiveCharacterLevel()
    if isRecipeMode then
        local targetSkill = math.min(300, math.max(1, charLvl * 5))
        local minSkill = math.max(1, targetSkill - 55)
        local maxSkill = math.min(300, math.max(75, targetSkill + 25))
        return minSkill, maxSkill, charLvl
    else
        local minLvl = math.max(1, charLvl - 5)
        local maxLvl = math.min(60, math.max(8, charLvl + 3))
        return minLvl, maxLvl, charLvl
    end
end

function MainPanel:EnsureFavoritesDB()
    if not AltVaultDB then return nil end
    AltVaultDB.Favorites = AltVaultDB.Favorites or {}
    AltVaultDB.Favorites.items = AltVaultDB.Favorites.items or {}
    AltVaultDB.Favorites.recipes = AltVaultDB.Favorites.recipes or {}
    return AltVaultDB.Favorites
end

function MainPanel:IsItemFavorite(itemID)
    local numID = tonumber(itemID)
    if not numID then return false end
    local favs = self:EnsureFavoritesDB()
    return (favs and favs.items[numID] ~= nil) or false
end

function MainPanel:ToggleItemFavorite(itemID, entryMeta)
    local numID = tonumber(itemID)
    if not numID then return false end
    local favs = self:EnsureFavoritesDB()
    if not favs then return false end

    if favs.items[numID] then
        local oldName = (type(favs.items[numID]) == "table" and favs.items[numID].name) or ("Item #" .. numID)
        favs.items[numID] = nil
        print(string.format("|cffffcc00[AltVault Favorites]:|r ☆ Removed |cffffffff%s|r (#%d) from your Favorites List.", oldName, numID))
        return false
    else
        local meta = type(entryMeta) == "table" and entryMeta or { id = numID }
        meta.id = numID
        meta.savedAt = time()
        favs.items[numID] = meta
        print(string.format("|cff00ff00[AltVault Favorites]:|r |cffffd100★ Added %s|r (#%d) to your Favorites List!", meta.name or ("Item #" .. numID), numID))
        return true
    end
end

function MainPanel:MakeRecipeFavoriteKey(profName, cleanName, idNum)
    local p = string.lower(tostring(profName or "Recipe"))
    local n = string.lower(tostring(cleanName or idNum or "Unknown"))
    return p .. ":" .. n
end

function MainPanel:IsRecipeFavorite(recipeKey)
    if not recipeKey or recipeKey == "" then return false end
    local favs = self:EnsureFavoritesDB()
    return (favs and favs.recipes[recipeKey] ~= nil) or false
end

function MainPanel:ToggleRecipeFavorite(recipeKey, recipeMeta)
    if not recipeKey or recipeKey == "" then return false end
    local favs = self:EnsureFavoritesDB()
    if not favs then return false end

    if favs.recipes[recipeKey] then
        local oldName = (type(favs.recipes[recipeKey]) == "table" and favs.recipes[recipeKey].name) or recipeKey
        favs.recipes[recipeKey] = nil
        print(string.format("|cffffcc00[AltVault Favorites]:|r ☆ Removed Recipe |cffffffff%s|r from your Favorites List.", oldName))
        return false
    else
        local meta = type(recipeMeta) == "table" and recipeMeta or { key = recipeKey, name = recipeKey }
        meta.key = recipeKey
        meta.savedAt = time()
        favs.recipes[recipeKey] = meta
        print(string.format("|cff00ff00[AltVault Favorites]:|r |cffffd100★ Added Recipe %s|r to your Favorites List!", meta.name or recipeKey))
        return true
    end
end

function MainPanel:GetFavoriteCounts()
    local favs = self:EnsureFavoritesDB()
    if not favs then return 0, 0 end
    local iCount, rCount = 0, 0
    for _ in pairs(favs.items) do iCount = iCount + 1 end
    for _ in pairs(favs.recipes) do rCount = rCount + 1 end
    return iCount, rCount
end

-- ============================================================================
-- BLOCK HEADING: FRAMED CARD ROW LIST (FOR TABS 2 through 11)
-- ============================================================================
local ScrollFrame = CreateFrame("ScrollFrame", "AltVaultContentScrollFrame", MainPanel, "UIPanelScrollFrameTemplate")
ScrollFrame:SetPoint("TOPLEFT", MainPanel, "TOPLEFT", 215, -96)
ScrollFrame:SetPoint("BOTTOMRIGHT", MainPanel, "BOTTOMRIGHT", -32, 24)

local ScrollChild = CreateFrame("Frame", nil, ScrollFrame)
ScrollChild:SetSize(520, 800)
ScrollFrame:SetScrollChild(ScrollChild)

MainPanel.ScrollFrame = ScrollFrame
MainPanel.ScrollChild = ScrollChild

function MainPanel:ClearAllScrollContent()
    for _, row in pairs(self.contentRows or {}) do
        if type(row) == "table" then
            if ns.Scanner and ns.Scanner.ApplyPulseAnimation and row.BgTint then
                ns.Scanner.ApplyPulseAnimation(row.BgTint, false)
            end
            if row.Text then row.Text:SetText("") end
            if row.IconBorder then row.IconBorder:Hide() end
            if row.BgTint then row.BgTint:Hide() end
            if row.Highlight then row.Highlight:Hide() end
            row:Hide()
        end
    end
    for _, cell in pairs(self.dbGridCells or {}) do
        if type(cell) == "table" then
            if cell.Title then cell.Title:SetText("") end
            if cell.Meta then cell.Meta:SetText("") end
            cell:Hide()
        end
    end
    for _, cell in pairs(self.acqGridCells or {}) do
        if type(cell) == "table" then
            if cell.Title then cell.Title:SetText("") end
            if cell.Meta then cell.Meta:SetText("") end
            if cell.SourceSub then cell.SourceSub:SetText("") end
            cell:Hide()
        end
    end
    if ScrollChild and ScrollChild.GetChildren then
        local kids = { ScrollChild:GetChildren() }
        for idx = 1, #kids do
            local child = kids[idx]
            if child and child.Hide then
                child:Hide()
            end
        end
    end
end

function MainPanel:HideListAndDBFrames()
    self:ClearAllScrollContent()
    ScrollChild:Hide()
    ScrollFrame:Hide()
    if self.DBHeaderFrame then
        self.DBHeaderFrame:Hide()
    end
end

function MainPanel:SetScrollTopOffset(topY)
    self._state.customScrollTopOffset = topY
    local leftX = self:GetLeftColumnOffset()
    ScrollFrame:ClearAllPoints()
    ScrollFrame:SetPoint("TOPLEFT", MainPanel, "TOPLEFT", leftX, topY or self:GetBaseContentTopY())
    ScrollFrame:SetPoint("BOTTOMRIGHT", MainPanel, "BOTTOMRIGHT", -32, 24)
end

local function GetOrCreateRow(index)
    local contentRows = MainPanel.contentRows
    local row = contentRows[index]
    if not row then
        row = CreateBackdrop("Button", nil, ScrollChild)
        row:SetHeight(28)
        row:EnableMouse(true)
        row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        if row.SetBackdrop then
            row:SetBackdrop({
                bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                tile = true, tileSize = 16, edgeSize = 10,
                insets = { left = 2, right = 2, top = 2, bottom = 2 }
            })
            row:SetBackdropColor(0.06, 0.07, 0.10, 0.92)
            row:SetBackdropBorderColor(0.28, 0.30, 0.38, 0.85)
        end

        row.BgTint = row:CreateTexture(nil, "BACKGROUND")
        row.BgTint:SetPoint("TOPLEFT", row, "TOPLEFT", 2, -2)
        row.BgTint:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -2, 2)
        row.BgTint:Hide()

        row.Highlight = row:CreateTexture(nil, "BORDER")
        row.Highlight:SetPoint("TOPLEFT", row, "TOPLEFT", 2, -2)
        row.Highlight:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -2, 2)
        SetSolid(row.Highlight, 1, 0.82, 0, 0.16)
        row.Highlight:Hide()

        row.IconBorder = CreateBackdrop("Frame", nil, row)
        row.IconBorder:SetSize(24, 24)
        row.IconBorder:SetPoint("TOPLEFT", row, "TOPLEFT", 5, -3)
        if row.IconBorder.SetBackdrop then
            row.IconBorder:SetBackdrop({
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                edgeSize = 8,
            })
            row.IconBorder:SetBackdropBorderColor(0.65, 0.55, 0.25, 0.95)
        end

        row.Icon = row.IconBorder:CreateTexture(nil, "ARTWORK")
        row.Icon:SetPoint("TOPLEFT", row.IconBorder, "TOPLEFT", 2, -2)
        row.Icon:SetPoint("BOTTOMRIGHT", row.IconBorder, "BOTTOMRIGHT", -2, 2)
        row.Icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

        row.Text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        row.Text:SetPoint("TOPLEFT", row.IconBorder, "TOPRIGHT", 8, -2)
        row.Text:SetJustifyH("LEFT")
        row.Text:SetJustifyV("TOP")
        row.Text:SetWordWrap(true)
        if row.Text.SetNonSpaceWrap then row.Text:SetNonSpaceWrap(true) end

        row:SetScript("OnEnter", function(self)
            self.Highlight:Show()
            if self.talentData then
                local t = self.talentData
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:ClearLines()
                GameTooltip:AddLine(t.name, 1, 1, 1)
                GameTooltip:AddDoubleLine(
                    string.format("Spec: %s", t.specName or "Specialization"),
                    string.format("Rank %d/%d", t.rank or 1, t.maxRank or 5),
                    1, 0.82, 0, 0, 1, 0.5
                )
                GameTooltip:AddLine(string.format("Tier %d Talent (Unlocks at Level %d)", t.tier or 1, t.minLevel or 10), 0.7, 0.85, 1)
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine(t.desc or "Talent ability.", 1, 0.82, 0, true)
                GameTooltip:Show()
                return
            end

            if self.itemLink then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetHyperlink(self.itemLink)
                local selChar = MainPanel._state.selectedCharacter
                local viewedChar = selChar and AltVaultDB and AltVaultDB.Characters[selChar]
                if ns.Scanner and ns.Scanner.CleanTooltipRedLinesForAlt and viewedChar then
                    ns.Scanner.CleanTooltipRedLinesForAlt(GameTooltip, viewedChar, self.isEquipped)
                end
                if self.gearScore and self.gearScore > 0 then
                    GameTooltip:AddLine(" ")
                    GameTooltip:AddDoubleLine("AltVault GearScore:", ns.Scanner.FormatGearScoreColor(self.gearScore), 1, 0.82, 0, 1, 1, 1)
                end
                if self.recommendNote and self.recommendNote ~= "" then
                    GameTooltip:AddLine(" ")
                    GameTooltip:AddLine(self.recommendNote, 0, 1, 0.5, true)
                end
                if MainPanel._state.activeViewMode == "DATABASE" and not MainPanel._state.inspectedItemID then
                    GameTooltip:AddLine(" ")
                    GameTooltip:AddLine("|cffffd100Left-Click:|r Open Full Item Attribute Dossier", 1, 0.82, 0)
                end
                GameTooltip:Show()
            elseif self.recommendNote and self.recommendNote ~= "" then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:ClearLines()
                GameTooltip:AddLine(self.recommendNote, 1, 1, 1, true)
                GameTooltip:Show()
            end
        end)

        row:SetScript("OnLeave", function(self)
            self.Highlight:Hide()
            GameTooltip:Hide()
        end)

        row:SetScript("OnClick", function(self, button)
            MainPanel:Raise()
            if IsAltKeyDown() and self.onAltClickAction then
                self.onAltClickAction(self, button)
                return
            end
            if button == "RightButton" and self.onRightClickAction then
                self.onRightClickAction()
                return
            end
            if self.itemLink and IsModifiedClick() then
                HandleModifiedItemClick(self.itemLink)
                return
            end
            if self.onClickAction then
                self.onClickAction(self, button)
                return
            end
            if self.inspectID then
                MainPanel._state.inspectedItemID = self.inspectID
                MainPanel:RenderActivePane()
                return
            end
            if self.itemLink then
                HandleModifiedItemClick(self.itemLink)
            end
        end)

        contentRows[index] = row
    end
    return row
end

function MainPanel:RenderRowList(rowEntries)
    if self.HideArmoryCanvas then self:HideArmoryCanvas() end
    self:ClearAllScrollContent()
    ScrollChild:Show()
    ScrollFrame:Show()

    local winFactor = self:GetWindowScaleFactor()
    local fontSize = math.max(11, math.min(20, math.floor(14.5 * winFactor + 0.5)))
    local minRowHeight = fontSize + 15
    local leftX = self:GetLeftColumnOffset()
    local contentWidth = math.max(260, MainPanel:GetWidth() - leftX - 38)

    local yOffset = -4
    local visibleRowIdx = 0
    for i, entry in ipairs(rowEntries) do
        local isSpacer = (not entry.icon and (not entry.text or entry.text == " " or string.find(entry.text, "^|cff555555%-%-%-")))
        if isSpacer then
            yOffset = yOffset - math.max(5, math.floor(7 * winFactor + 0.5))
        else
            visibleRowIdx = visibleRowIdx + 1
            local row = GetOrCreateRow(visibleRowIdx)
            row:SetWidth(contentWidth)
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", ScrollChild, "TOPLEFT", 4, yOffset)

            row.Text:SetFont(STANDARD_FONT, fontSize, "OUTLINE")
            row.Text:SetWordWrap(true)

            local iconSize = fontSize + 11
            local textWidth
            if entry.icon then
                row.Icon:SetTexture(entry.icon)
                row.IconBorder:SetSize(iconSize, iconSize)
                row.IconBorder:ClearAllPoints()
                row.IconBorder:SetPoint("TOPLEFT", row, "TOPLEFT", 6, -4)
                row.IconBorder:Show()

                textWidth = math.max(120, contentWidth - (iconSize + 22))
                row.Text:ClearAllPoints()
                row.Text:SetPoint("TOPLEFT", row.IconBorder, "TOPRIGHT", 8, -2)
                row.Text:SetWidth(textWidth)
            else
                row.IconBorder:Hide()
                textWidth = math.max(120, contentWidth - 18)
                row.Text:ClearAllPoints()
                row.Text:SetPoint("TOPLEFT", row, "TOPLEFT", 10, -5)
                row.Text:SetWidth(textWidth)
            end

            row.Text:SetText(entry.text or "")

            local measuredTextH = (row.Text.GetStringHeight and row.Text:GetStringHeight()) or fontSize
            local actualRowHeight = math.max(minRowHeight, math.ceil(measuredTextH) + 11)
            row:SetHeight(actualRowHeight)

            row.itemLink = entry.link
            row.talentData = entry.talentData
            row.gearScore = entry.gs
            row.itemILvl = entry.iLvl
            row.isEquipped = entry.isEquipped
            row.recommendNote = entry.recommendNote
            row.inspectID = entry.inspectID
            row.onClickAction = entry.onClickAction
            row.onRightClickAction = entry.onRightClickAction
            row.onAltClickAction = entry.onAltClickAction

            if row.SetBackdropColor then
                local evenBg = (visibleRowIdx % 2 == 0) and 0.08 or 0.05
                row:SetBackdropColor(evenBg, evenBg + 0.01, evenBg + 0.03, 0.94)
                row:SetBackdropBorderColor(0.28, 0.30, 0.38, 0.85)
            end

            if entry.tint == "LOCKED_RED" then
                SetSolid(row.BgTint, 0.85, 0.08, 0.08, 0.36)
                if row.SetBackdropBorderColor then row:SetBackdropBorderColor(1.0, 0.18, 0.18, 0.98) end
                row.BgTint:Show()
                ns.Scanner.ApplyPulseAnimation(row.BgTint, false)
            elseif entry.tint == "UPGRADE_SOON" then
                SetSolid(row.BgTint, 0.08, 0.85, 0.20, 0.26)
                if row.SetBackdropBorderColor then row:SetBackdropBorderColor(0.15, 1.0, 0.30, 0.95) end
                row.BgTint:Show()
                ns.Scanner.ApplyPulseAnimation(row.BgTint, true)
            elseif entry.tint == "PROF_SOON" then
                SetSolid(row.BgTint, 0.0, 0.80, 1.0, 0.26)
                if row.SetBackdropBorderColor then row:SetBackdropBorderColor(0.0, 0.90, 1.0, 0.95) end
                row.BgTint:Show()
                ns.Scanner.ApplyPulseAnimation(row.BgTint, true)
            elseif entry.tint == "UPGRADE" then
                SetSolid(row.BgTint, 0, 0.55, 0.15, 0.16)
                if row.SetBackdropBorderColor then row:SetBackdropBorderColor(0.1, 0.75, 0.25, 0.90) end
                row.BgTint:Show()
                ns.Scanner.ApplyPulseAnimation(row.BgTint, false)
            elseif entry.tint == "PROF" then
                SetSolid(row.BgTint, 0, 0.45, 0.80, 0.16)
                if row.SetBackdropBorderColor then row:SetBackdropBorderColor(0.1, 0.60, 0.90, 0.90) end
                row.BgTint:Show()
                ns.Scanner.ApplyPulseAnimation(row.BgTint, false)
            elseif entry.tint == "SPEC_HEADER" then
                SetSolid(row.BgTint, 0.65, 0.45, 0.05, 0.28)
                if row.SetBackdropBorderColor then row:SetBackdropBorderColor(0.85, 0.68, 0.20, 0.95) end
                row.BgTint:Show()
                ns.Scanner.ApplyPulseAnimation(row.BgTint, false)
            else
                row.BgTint:Hide()
                ns.Scanner.ApplyPulseAnimation(row.BgTint, false)
            end

            row:Show()
            yOffset = yOffset - (actualRowHeight + 3)
        end
    end

    ScrollChild:SetSize(contentWidth, math.abs(yOffset) + 24)
    if ScrollFrame.UpdateScrollChildRect then
        pcall(ScrollFrame.UpdateScrollChildRect, ScrollFrame)
    end
end