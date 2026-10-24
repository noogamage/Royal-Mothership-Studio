-- ============================================================================
-- FILE: UI_ArmoryBottomBoxes.lua (MODULE 2 OF 2 SPLIT FROM UI_ArmoryPaperDoll.lua)
-- BLOCK HEADING: 3 BOTTOM BOXES (BOX 1: BAGS, BOX 2: BANK, BOX 3: STATS/PROFS)
-- ============================================================================
local addonName, ns = ...
local MainPanel = _G.AltVaultMainPanel
local Armory = ns.Armory
if not MainPanel or not Armory then return end

local CreateBackdrop = Armory.CreateBackdrop
local SetSolid = Armory.SetSolid
local STANDARD_FONT = Armory.STANDARD_FONT
local BASE_PANEL_W = Armory.BASE_PANEL_W
local BASE_PANEL_H = Armory.BASE_PANEL_H
local CLASS_COLOR_RGB = Armory.CLASS_COLOR_RGB
local QUALITY_RGB = Armory.QUALITY_RGB
local GetItemIconTexture = Armory.GetItemIconTexture

local ArmoryCanvas = Armory.ArmoryCanvas
local PaperDollStage = Armory.PaperDollStage
local StageHeaderText = Armory.StageHeaderText
local ModelViewport = Armory.ModelViewport
local LeftControlsAnchor = Armory.LeftControlsAnchor
local ModelZoomSlider = Armory.ModelZoomSlider
local zoomTitle = Armory.zoomTitle
local DanceBtn = Armory.DanceBtn
local RightRatingCluster = Armory.RightRatingCluster

local GetSavedModelZoom = Armory.GetSavedModelZoom
local ApplyCharacterModelZoom = Armory.ApplyCharacterModelZoom
local TriggerModelDanceEmote = Armory.TriggerModelDanceEmote
local ConfigureAndDress3DCharacterModel = Armory.ConfigureAndDress3DCharacterModel
local UpdateRatingDisplay = Armory.UpdateRatingDisplay

local LEFT_DOLL_SLOTS = Armory.LEFT_DOLL_SLOTS
local RIGHT_DOLL_SLOTS = Armory.RIGHT_DOLL_SLOTS
local BOTTOM_DOLL_SLOTS = Armory.BOTTOM_DOLL_SLOTS
local paperDollSlotBtns = Armory.paperDollSlotBtns

local function CreateBottomBagBox(name, bagIconPath, titleText)
    local box = CreateBackdrop("Frame", name, ArmoryCanvas)
    if box.SetBackdrop then
        box:SetBackdrop({
            bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
            tile = true, tileSize = 32, edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        box:SetBackdropColor(0.04, 0.05, 0.08, 0.96)
        box:SetBackdropBorderColor(0.85, 0.68, 0.24, 0.95)
    end

    box.HeaderBar = CreateBackdrop("Frame", nil, box)
    box.HeaderBar:SetPoint("TOPLEFT", box, "TOPLEFT", 5, -5)
    box.HeaderBar:SetPoint("TOPRIGHT", box, "TOPRIGHT", -5, -5)
    box.HeaderBar:SetHeight(26)
    if box.HeaderBar.SetBackdrop then
        box.HeaderBar:SetBackdrop({
            bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 10,
            insets = { left = 2, right = 2, top = 2, bottom = 2 }
        })
        box.HeaderBar:SetBackdropColor(0.10, 0.08, 0.04, 0.95)
        box.HeaderBar:SetBackdropBorderColor(0.65, 0.52, 0.22, 0.90)
    end

    box.BagIcon = box.HeaderBar:CreateTexture(nil, "ARTWORK")
    box.BagIcon:SetSize(20, 20)
    box.BagIcon:SetPoint("LEFT", box.HeaderBar, "LEFT", 6, 0)
    box.BagIcon:SetTexture(bagIconPath)

    box.Title = box.HeaderBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    box.Title:SetPoint("LEFT", box.BagIcon, "RIGHT", 6, 0)
    box.Title:SetText("|cffffd100" .. titleText .. "|r")

    box.ToggleBtn = CreateFrame("Button", nil, box.HeaderBar, "UIPanelButtonTemplate")
    box.ToggleBtn:SetSize(56, 20)
    box.ToggleBtn:SetPoint("RIGHT", box.HeaderBar, "RIGHT", -4, 0)
    box.ToggleBtn:SetText("Usable")

    box.Scroll = CreateFrame("ScrollFrame", name .. "Scroll", box, "UIPanelScrollFrameTemplate")
    box.Scroll:SetPoint("TOPLEFT", box.HeaderBar, "BOTTOMLEFT", 2, -4)
    box.Scroll:SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT", -26, 6)

    box.Child = CreateFrame("Frame", nil, box.Scroll)
    box.Child:SetSize(180, 180)
    box.Scroll:SetScrollChild(box.Child)

    box.EmptyNote = box.Child:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    box.EmptyNote:SetPoint("TOPLEFT", box.Child, "TOPLEFT", 6, -8)
    box.EmptyNote:SetPoint("RIGHT", box.Child, "RIGHT", -6, 0)
    box.EmptyNote:SetJustifyH("CENTER")
    box.EmptyNote:SetWordWrap(true)

    box.itemButtons = {}
    return box
end

local BagContainerBox = CreateBottomBagBox(
    "AltVaultBottomBagBox",
    "Interface\\Icons\\INV_Misc_Bag_08",
    "Bag Items You Can Use"
)
BagContainerBox.ToggleBtn:SetScript("OnClick", function()
    Armory.state.showAllBagItemsInBox = not Armory.state.showAllBagItemsInBox
    MainPanel:RenderActivePane()
end)

local BankContainerBox = CreateBottomBagBox(
    "AltVaultBottomBankBox",
    "Interface\\Icons\\INV_Box_01",
    "Bank Items You Can Use"
)
BankContainerBox.ToggleBtn:SetScript("OnClick", function()
    Armory.state.showAllBankItemsInBox = not Armory.state.showAllBankItemsInBox
    MainPanel:RenderActivePane()
end)

local StatsContainerBox = CreateBottomBagBox(
    "AltVaultBottomStatsBox",
    "Interface\\Icons\\Trade_BlackSmithing",
    "Professions & Stats"
)
StatsContainerBox.ToggleBtn:Hide()
StatsContainerBox.statLines = {}
StatsContainerBox.profBars = {}

local function GetOrCreateMiniItemSlot(box, index)
    local btn = box.itemButtons[index]
    if not btn then
        btn = CreateBackdrop("Button", nil, box.Child)
        btn:SetSize(34, 34)
        btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        if btn.SetBackdrop then
            btn:SetBackdrop({
                bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                tile = true, tileSize = 16, edgeSize = 8,
                insets = { left = 2, right = 2, top = 2, bottom = 2 }
            })
            btn:SetBackdropColor(0.05, 0.05, 0.07, 0.95)
            btn:SetBackdropBorderColor(0.35, 0.35, 0.40, 0.90)
        end

        btn.Icon = btn:CreateTexture(nil, "ARTWORK")
        btn.Icon:SetPoint("TOPLEFT", btn, "TOPLEFT", 2, -2)
        btn.Icon:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -2, 2)
        btn.Icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

        btn.Highlight = btn:CreateTexture(nil, "HIGHLIGHT")
        btn.Highlight:SetAllPoints(btn.Icon)
        btn.Highlight:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
        btn.Highlight:SetBlendMode("ADD")

        btn.CountText = btn:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
        btn.CountText:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -2, 2)
        btn.CountText:SetFont(STANDARD_FONT, 10, "OUTLINE")

        btn.BadgeDot = btn:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
        btn.BadgeDot:SetPoint("TOPLEFT", btn, "TOPLEFT", 2, -1)
        btn.BadgeDot:SetFont(STANDARD_FONT, 10, "OUTLINE")

        btn:SetScript("OnEnter", function(self)
            if not self.itemLink then return end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink(self.itemLink)
            if self.recommendNote and self.recommendNote ~= "" then
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine(self.recommendNote, 0, 1, 0.5, true)
            end
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        btn:SetScript("OnClick", function(self, button)
            if button == "RightButton" and self.onRightClickAction then
                self.onRightClickAction()
                return
            end
            if self.itemLink and IsModifiedClick() then
                HandleModifiedItemClick(self.itemLink)
            elseif self.onClickAction then
                self.onClickAction()
            elseif self.itemLink then
                HandleModifiedItemClick(self.itemLink)
            end
        end)

        box.itemButtons[index] = btn
    end
    return btn
end

-- ============================================================================
-- BLOCK HEADING: POPULATE BOTTOM ITEM GRIDS & RIGHT STATS/PROFESSION BARS
-- ============================================================================
local function PopulateBottomItemGridBox(box, rawItems, faction, showAllFlag, emptyLabelText, isSyncedPeer)
    for _, btn in ipairs(box.itemButtons) do
        if ns.Scanner and ns.Scanner.ApplySlotBorderGlow then
            ns.Scanner.ApplySlotBorderGlow(btn, nil)
        end
        btn:Hide()
    end

    box.ToggleBtn:SetText(showAllFlag and "|cffffd100All|r" or "|cff00ff96Usable|r")

    local filtered = {}
    for _, entry in ipairs(rawItems or {}) do
        local ref = entry.link or entry.itemID
        if ref then
            local isLocked = (not isSyncedPeer) and (ns.DB and ns.DB.IsItemTradeLocked and ns.DB.IsItemTradeLocked(ref)) or false
            local upgList, profList = nil, nil
            if ns.Scanner and ns.Scanner.EvaluateItemForRoster then
                upgList, profList = ns.Scanner.EvaluateItemForRoster(ref, faction)
            end
            local craftUpgrades = ns.GuildNet and ns.GuildNet.GetMaterialCraftUpgradeNotes and ns.GuildNet.GetMaterialCraftUpgradeNotes(ref, faction)

            local isUsable = (upgList and #upgList > 0) or (profList and #profList > 0) or (craftUpgrades and #craftUpgrades > 0)
            if showAllFlag or isUsable or isLocked then
                local status = nil
                local badgeChar = ""
                local noteLines = {}

                if isLocked then
                    status = "LOCKED_RED"
                    badgeChar = "|cffff2020✖|r"
                    table.insert(noteLines, "|cffff2020[NOT FOR TRADE — Hidden from Synced Players & Trade Tabs]|r")
                else
                    if craftUpgrades and #craftUpgrades > 0 then
                        status = "PROF_SOON"
                        badgeChar = "|cff00ffff⚒|r"
                        table.insert(noteLines, string.format("|cffffd100⚒ Crafts %s for %s (+%d GS)|r",
                            craftUpgrades[1].itemName or "Upgrade", craftUpgrades[1].targetName, craftUpgrades[1].deltaGS or 0))
                    end
                    if upgList and #upgList > 0 then
                        local topU = upgList[1]
                        status = (topU.status == "UPGRADE_SOON") and "UPGRADE_SOON" or (status or "UPGRADE")
                        badgeChar = "|cff00ff00★|r"
                        for i = 1, math.min(#upgList, 4) do
                            local u = upgList[i]
                            table.insert(noteLines, string.format("|cff00ff00★ Upgrade for %s (Lvl %d): +%d GS|r", u.name, u.level, u.delta))
                        end
                    end
                    if profList and #profList > 0 then
                        local topP = profList[1]
                        if not status then
                            status = (topP.status == "PROF_SOON") and "PROF_SOON" or "PROF_MAT"
                        end
                        if badgeChar == "" then badgeChar = "|cff00ffff⚒|r" end
                        for i = 1, math.min(#profList, 5) do
                            local pm = profList[i]
                            table.insert(noteLines, string.format("|cff00ffff• %s (%s %d): %s|r", pm.name, pm.prof, pm.rank or 1, pm.note or "Crafting Mat"))
                        end
                    end
                end

                if not isSyncedPeer then
                    table.insert(noteLines, "|cffffcc00Right-Click: Toggle Not For Trade (Red = Hidden from Players)|r")
                end

                local _, fullLink, quality, _, _, _, _, _, _, icon = ns.Scanner.FetchItemInfo(ref)
                local rightClickFn = nil
                if not isSyncedPeer then
                    rightClickFn = function()
                        if ns.DB and ns.DB.ToggleItemTradeLock then
                            ns.DB.ToggleItemTradeLock(ref)
                            MainPanel:RenderActivePane()
                        end
                    end
                end

                table.insert(filtered, {
                    link = fullLink or (type(ref) == "string" and ref) or ("item:" .. tostring(ref)),
                    icon = entry.icon or icon or GetItemIconTexture(ref) or "Interface\\Icons\\INV_Misc_QuestionMark",
                    count = tonumber(entry.count) or 1,
                    quality = quality or 1,
                    status = status,
                    isLocked = isLocked,
                    badge = badgeChar,
                    note = table.concat(noteLines, "\n"),
                    onClickAction = entry.onClickAction,
                    onRightClickAction = rightClickFn
                })
            end
        end
    end

    local boxW = math.max(140, (box:GetWidth() or 220) - 34)
    box.Child:SetWidth(boxW)

    local winFactor = (MainPanel.GetWindowScaleFactor and MainPanel:GetWindowScaleFactor()) or 1.0
    if box.Title then
        box.Title:SetFont(STANDARD_FONT, math.max(11, math.floor(13 * winFactor + 0.5)), "OUTLINE")
    end
    if box.EmptyNote then
        box.EmptyNote:SetFont(STANDARD_FONT, math.max(10, math.floor(11.5 * winFactor + 0.5)), "")
    end

    if #filtered == 0 then
        box.EmptyNote:SetText(emptyLabelText)
        box.EmptyNote:Show()
        box.Child:SetHeight(80)
        return
    end
    box.EmptyNote:Hide()

    local slotSize = math.max(30, math.min(44, math.floor((boxW - 8) / 5) - 4))
    local cols = math.max(3, math.floor((boxW - 4) / (slotSize + 4)))

    for idx, it in ipairs(filtered) do
        local btn = GetOrCreateMiniItemSlot(box, idx)
        btn:SetSize(slotSize, slotSize)
        local rowIdx = math.floor((idx - 1) / cols)
        local colIdx = (idx - 1) % cols
        btn:ClearAllPoints()
        btn:SetPoint("TOPLEFT", box.Child, "TOPLEFT", 4 + colIdx * (slotSize + 4), -4 - rowIdx * (slotSize + 4))

        btn.Icon:SetTexture(it.icon)
        if it.isLocked then
            btn.Icon:SetVertexColor(1.0, 0.42, 0.42)
        else
            btn.Icon:SetVertexColor(1.0, 1.0, 1.0)
        end
        btn.itemLink = it.link
        btn.recommendNote = it.note
        btn.onClickAction = it.onClickAction
        btn.onRightClickAction = it.onRightClickAction
        btn.CountText:SetFont(STANDARD_FONT, math.max(9, math.floor(10.5 * winFactor + 0.5)), "OUTLINE")
        btn.BadgeDot:SetFont(STANDARD_FONT, math.max(9, math.floor(10.5 * winFactor + 0.5)), "OUTLINE")
        btn.CountText:SetText((it.count and it.count > 1) and tostring(it.count) or "")
        btn.BadgeDot:SetText(it.badge or "")

        local qRGB = QUALITY_RGB[it.quality or 1] or QUALITY_RGB[1]
        if btn.SetBackdropBorderColor then
            if it.isLocked then
                btn:SetBackdropBorderColor(1.0, 0.15, 0.15, 1.0)
            else
                btn:SetBackdropBorderColor(qRGB[1], qRGB[2], qRGB[3], 0.95)
            end
        end
        if ns.Scanner and ns.Scanner.ApplySlotBorderGlow then
            ns.Scanner.ApplySlotBorderGlow(btn, it.status)
        end
        btn:Show()
    end

    local totalRows = math.ceil(#filtered / cols)
    box.Child:SetHeight(math.max(80, totalRows * (slotSize + 4) + 10))
end

local function PopulateRightStatsAndProfsBox(charName, charData, totalGS, avgILvl, isSyncedPeer)
    local box = StatsContainerBox
    local boxW = math.max(150, (box:GetWidth() or 230) - 32)
    box.Child:SetWidth(boxW)
    box.EmptyNote:Hide()

    local winFactor = (MainPanel.GetWindowScaleFactor and MainPanel:GetWindowScaleFactor()) or 1.0
    if box.Title then
        box.Title:SetFont(STANDARD_FONT, math.max(11, math.floor(13 * winFactor + 0.5)), "OUTLINE")
    end

    for _, fs in ipairs(box.statLines) do fs:Hide() end
    for _, bar in ipairs(box.profBars) do bar:Hide() end

    local cInfo = CLASS_COLOR_RGB[charData.class or "WARRIOR"] or CLASS_COLOR_RGB.WARRIOR
    local maxCap = _G.MAX_PLAYER_LEVEL or 60
    local xpStr = (not isSyncedPeer and (charData.level or 1) < maxCap)
        and string.format(" (%d%% XP)", charData.xpPercent or 0)
        or ""

    local statStrings = {
        string.format("|cffffd100%s|r  |cffcccccc<%s>|r", charName, charData.guild or (isSyncedPeer and "Synced Member" or "No Guild")),
        string.format("|cffffd100Level:|r |cffffffff%d%s|r   |cffffd100Race:|r |cff00ff96%s|r", charData.level or 1, xpStr, charData.race or "Unknown"),
        string.format("|cffffd100Class:|r |cff%s%s|r", cInfo[4], charData.class or "WARRIOR"),
        string.format("|cffffd100Spec:|r |cffffffff%s|r |cff88ccff(%s)|r", charData.specName or "Hybrid", charData.talentBuild or "0/0/0"),
        string.format("|cffffd100GearScore:|r %s  |cffaaaaaa(Avg iLvl %d)|r", ns.Scanner.FormatGearScoreColor(totalGS), avgILvl or 0),
        "|cffffd100Professions & Skills:|r",
    }

    local titleStatFont = math.max(11, math.floor(13 * winFactor + 0.5))
    local bodyStatFont = math.max(10, math.floor(11.5 * winFactor + 0.5))
    local profFont = math.max(9, math.floor(10.5 * winFactor + 0.5))
    local profBarH = math.max(15, math.floor(18 * winFactor + 0.5))

    local y = -4
    for i, text in ipairs(statStrings) do
        local fs = box.statLines[i]
        if not fs then
            fs = box.Child:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            fs:SetJustifyH("LEFT")
            fs:SetWordWrap(true)
            box.statLines[i] = fs
        end
        fs:SetWidth(boxW - 8)
        fs:SetFont(STANDARD_FONT, (i == 1 or i == 6) and titleStatFont or bodyStatFont, "OUTLINE")
        fs:ClearAllPoints()
        fs:SetPoint("TOPLEFT", box.Child, "TOPLEFT", 6, y)
        fs:SetText(text)
        fs:Show()
        local h = (fs.GetStringHeight and fs:GetStringHeight()) or (bodyStatFont + 3)
        y = y - (math.ceil(h) + 4)
    end

    local profList = {}
    local seen = {}
    if isSyncedPeer then
        for pName, pRank in pairs(charData.profs or {}) do
            table.insert(profList, { name = pName, rank = pRank, maxRank = (pRank > 300 and 450 or 300) })
        end
        table.sort(profList, function(a, b) return a.name < b.name end)
    elseif charData.professions then
        local function AddP(p)
            if p and p.name and not seen[p.name] then
                seen[p.name] = true
                table.insert(profList, p)
            end
        end
        AddP(charData.professions.primary1)
        AddP(charData.professions.primary2)
        for _, p in ipairs(charData.professions.all or {}) do AddP(p) end
    end

    if #profList == 0 then
        local fs = box.statLines[7]
        if not fs then
            fs = box.Child:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
            box.statLines[7] = fs
        end
        fs:SetFont(STANDARD_FONT, bodyStatFont, "")
        fs:ClearAllPoints()
        fs:SetPoint("TOPLEFT", box.Child, "TOPLEFT", 8, y - 2)
        fs:SetText("|cff888888No professions learned yet.|r")
        fs:Show()
        y = y - (bodyStatFont + 10)
    else
        for idx, p in ipairs(profList) do
            local bar = box.profBars[idx]
            if not bar then
                bar = CreateBackdrop("StatusBar", nil, box.Child)
                bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
                bar.Bg = bar:CreateTexture(nil, "BACKGROUND")
                bar.Bg:SetAllPoints(bar)
                SetSolid(bar.Bg, 0.02, 0.03, 0.05, 0.88)
                bar.Label = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                bar.Label:SetPoint("LEFT", bar, "LEFT", 6, 0)
                bar.RankText = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                bar.RankText:SetPoint("RIGHT", bar, "RIGHT", -6, 0)
                box.profBars[idx] = bar
            end
            local maxR = math.max(p.rank or 1, p.maxRank or 300)
            bar:SetSize(boxW - 12, profBarH)
            bar:ClearAllPoints()
            bar:SetPoint("TOPLEFT", box.Child, "TOPLEFT", 6, y - 1)
            bar:SetMinMaxValues(0, maxR)
            bar:SetValue(p.rank or 1)
            bar:SetStatusBarColor(0.0, 0.65, 0.45, 0.90)
            bar.Label:SetFont(STANDARD_FONT, profFont, "OUTLINE")
            bar.RankText:SetFont(STANDARD_FONT, profFont, "OUTLINE")
            bar.Label:SetText("|cff00ff96" .. (p.name or "Skill") .. "|r")
            bar.RankText:SetText(string.format("|cffffffff%d / %d|r", p.rank or 1, maxR))
            bar:Show()
            y = y - (profBarH + 3)
        end
    end

    box.Child:SetHeight(math.max(90, math.abs(y) + 10))
end

-- ============================================================================
-- BLOCK HEADING: MASTER VISUAL CHARACTER DASHBOARD RENDERER
-- ============================================================================
function MainPanel:RenderVisualCharacterDashboard(charName, charData, isSyncedPeer)
    if self.HideListAndDBFrames then
        self:HideListAndDBFrames()
    end

    Armory.state.activeDisplayedCharName = charName

    local leftX = self:GetLeftColumnOffset()
    local baseTopY = self:GetBaseContentTopY()
    if isSyncedPeer and self.GetActiveViewMode and self:GetActiveViewMode() == "SYNCED_ROSTER" then
        local bScale = self:GetButtonScale()
        baseTopY = baseTopY - math.max(68, math.floor(82 * math.min(1.22, bScale) + 0.5)) - 6
    end

    ArmoryCanvas:ClearAllPoints()
    ArmoryCanvas:SetPoint("TOPLEFT", MainPanel, "TOPLEFT", leftX, baseTopY)
    ArmoryCanvas:SetPoint("BOTTOMRIGHT", MainPanel, "BOTTOMRIGHT", -14, 14)
    ArmoryCanvas:Show()

    local canvasW = math.max(420, (MainPanel:GetWidth() or BASE_PANEL_W) - leftX - 18)
    local canvasH = math.max(360, (MainPanel:GetHeight() or BASE_PANEL_H) - math.abs(baseTopY) - 18)

    local topStageH = math.max(220, math.floor(canvasH * 0.58))
    local bottomBoxH = math.max(130, canvasH - topStageH - 8)

    PaperDollStage:ClearAllPoints()
    PaperDollStage:SetPoint("TOPLEFT", ArmoryCanvas, "TOPLEFT", 0, 0)
    PaperDollStage:SetPoint("TOPRIGHT", ArmoryCanvas, "TOPRIGHT", 0, 0)
    PaperDollStage:SetHeight(topStageH)

    local slotSize = math.max(24, math.min(40, math.floor((topStageH - 44) / 8) - 3))
    local slotStep = slotSize + 3
    local topSlotStartY = -36

    for idx, cfg in ipairs(LEFT_DOLL_SLOTS) do
        local btn = paperDollSlotBtns[cfg.id]
        btn:SetSize(slotSize, slotSize)
        btn:ClearAllPoints()
        btn:SetPoint("TOPLEFT", PaperDollStage, "TOPLEFT", 12, topSlotStartY - ((idx - 1) * slotStep))
    end

    for idx, cfg in ipairs(RIGHT_DOLL_SLOTS) do
        local btn = paperDollSlotBtns[cfg.id]
        btn:SetSize(slotSize, slotSize)
        btn:ClearAllPoints()
        btn:SetPoint("TOPRIGHT", PaperDollStage, "TOPRIGHT", -12, topSlotStartY - ((idx - 1) * slotStep))
    end

    for idx, cfg in ipairs(BOTTOM_DOLL_SLOTS) do
        local btn = paperDollSlotBtns[cfg.id]
        btn:SetSize(slotSize, slotSize)
        btn:ClearAllPoints()
        local xOff = (idx - 2) * (slotSize + 8)
        btn:SetPoint("BOTTOM", PaperDollStage, "BOTTOM", xOff, 8)
    end

    ModelViewport:ClearAllPoints()
    ModelViewport:SetPoint("TOPLEFT", PaperDollStage, "TOPLEFT", slotSize + 24, -36)
    ModelViewport:SetPoint("BOTTOMRIGHT", PaperDollStage, "BOTTOMRIGHT", -(slotSize + 24), slotSize + 14)

    local halfStageW = canvasW * 0.5
    local weaponClusterHalfW = (slotSize * 1.5) + 12
    local leftFreeStart = slotSize + 20
    local leftFreeEnd = halfStageW - weaponClusterHalfW - 8
    local leftCenterOffset = -halfStageW + ((leftFreeStart + leftFreeEnd) * 0.5)
    local leftAvailW = math.max(130, leftFreeEnd - leftFreeStart)

    local sliderW = math.max(70, math.min(125, leftAvailW - 78))
    local danceW = math.max(54, math.min(72, leftAvailW - sliderW - 6))
    ModelZoomSlider:SetWidth(sliderW)
    DanceBtn:SetSize(danceW, math.max(22, slotSize - 8))
    LeftControlsAnchor:SetSize(sliderW + danceW + 8, slotSize)
    LeftControlsAnchor:ClearAllPoints()
    LeftControlsAnchor:SetPoint("BOTTOM", PaperDollStage, "BOTTOM", leftCenterOffset, 6)

    local rightFreeStart = halfStageW + weaponClusterHalfW + 8
    local rightFreeEnd = canvasW - (slotSize + 20)
    local rightCenterOffset = ((rightFreeStart + rightFreeEnd) * 0.5) - halfStageW
    local rightAvailW = math.max(135, math.min(182, rightFreeEnd - rightFreeStart))

    RightRatingCluster:SetSize(rightAvailW, math.max(26, slotSize - 4))
    RightRatingCluster:ClearAllPoints()
    RightRatingCluster:SetPoint("BOTTOM", PaperDollStage, "BOTTOM", rightCenterOffset, 8)

    local cInfo = CLASS_COLOR_RGB[charData.class or "WARRIOR"] or CLASS_COLOR_RGB.WARRIOR
    local totalGS, avgILvl = 0, 0
    if not isSyncedPeer then
        totalGS, avgILvl = ns.Scanner.CalculateCharacterGearScore(charData.gear)
        if totalGS and totalGS > 0 then charData.gearScore = totalGS else totalGS = charData.gearScore or 0 end
    else
        totalGS = charData.gearScore or 0
    end

    local winFactor = self:GetWindowScaleFactor()
    local headerFontSz = math.max(15, math.floor(20 * winFactor + 0.5))
    StageHeaderText:SetFont(STANDARD_FONT, headerFontSz, "OUTLINE")
    StageHeaderText:SetText(string.format("|cffffd100%s|r  —  Level %d |cff%s%s %s|r  —  GS: %s",
        charName, charData.level or 1, cInfo[4], charData.race or "", charData.class or "WARRIOR",
        ns.Scanner.FormatGearScoreColor(totalGS)))

    for slotID, btn in pairs(paperDollSlotBtns) do
        local rawItem = charData.gear and charData.gear[slotID]
        local slotGS = (isSyncedPeer and charData.slotGS and charData.slotGS[slotID]) or 0
        btn.ownerData = charData

        if rawItem and rawItem ~= 0 then
            local _, itemLink, itemQual, baseILvl, _, _, _, _, _, itemTex = ns.Scanner.FetchItemInfo(rawItem)
            local calcGS, detILvl = ns.Scanner.CalculateItemGearScore(itemLink or rawItem, slotID)
            local finalGS = (calcGS and calcGS > 0) and calcGS or slotGS
            local finalILvl = detILvl or baseILvl or 0

            btn.itemLink = itemLink or (type(rawItem) == "string" and rawItem) or ("item:" .. tostring(rawItem))
            btn.itemGS = finalGS
            btn.Icon:SetTexture(itemTex or GetItemIconTexture(rawItem) or btn.emptyTex)
            btn.Icon:SetDesaturated(false)
            btn.Icon:SetVertexColor(1, 1, 1)
            btn.GSText:SetText(finalGS > 0 and tostring(finalGS) or "")
            btn.ILvlText:SetText(finalILvl > 0 and ("|cffcccccc" .. finalILvl .. "|r") or "")

            local qRGB = QUALITY_RGB[itemQual or 2] or QUALITY_RGB[2]
            if btn.SetBackdropBorderColor then
                btn:SetBackdropBorderColor(qRGB[1], qRGB[2], qRGB[3], 1.0)
            end
        else
            btn.itemLink = nil
            btn.itemGS = slotGS
            btn.Icon:SetTexture(btn.emptyTex)
            btn.Icon:SetDesaturated(true)
            btn.Icon:SetVertexColor(0.45, 0.45, 0.45)
            btn.GSText:SetText(slotGS > 0 and tostring(slotGS) or "")
            btn.ILvlText:SetText("")
            if btn.SetBackdropBorderColor then
                btn:SetBackdropBorderColor(0.28, 0.25, 0.20, 0.85)
            end
        end
    end

    ConfigureAndDress3DCharacterModel(charName, charData)

    local savedZoom = GetSavedModelZoom(charName)
    Armory.state.isUpdatingZoomSlider = true
    ModelZoomSlider:SetValue(savedZoom)
    if zoomTitle then zoomTitle:SetText("Size: " .. savedZoom .. "%") end
    Armory.state.isUpdatingZoomSlider = false
    ApplyCharacterModelZoom(savedZoom)

    if Armory.state.isModelDancing then
        TriggerModelDanceEmote(true)
        DanceBtn:SetText("|cff00ff00Dancing!|r")
        DanceBtn:LockHighlight()
    else
        DanceBtn:SetText("|cffffd100Dance!|r")
        DanceBtn:UnlockHighlight()
    end

    UpdateRatingDisplay()

    local gap = 8
    local boxW = math.floor((canvasW - (gap * 2)) / 3)

    BagContainerBox:ClearAllPoints()
    BagContainerBox:SetPoint("BOTTOMLEFT", ArmoryCanvas, "BOTTOMLEFT", 0, 0)
    BagContainerBox:SetSize(boxW, bottomBoxH)

    BankContainerBox:ClearAllPoints()
    BankContainerBox:SetPoint("BOTTOMLEFT", BagContainerBox, "BOTTOMRIGHT", gap, 0)
    BankContainerBox:SetSize(boxW, bottomBoxH)

    StatsContainerBox:ClearAllPoints()
    StatsContainerBox:SetPoint("BOTTOMLEFT", BankContainerBox, "BOTTOMRIGHT", gap, 0)
    StatsContainerBox:SetPoint("BOTTOMRIGHT", ArmoryCanvas, "BOTTOMRIGHT", 0, 0)
    StatsContainerBox:SetHeight(bottomBoxH)

    local showAllBags = Armory.state.showAllBagItemsInBox
    local showAllBank = Armory.state.showAllBankItemsInBox

    if not isSyncedPeer then
        BagContainerBox.Title:SetText(showAllBags and "|cffffd100All Bag Items|r" or "|cffffd100Usable in Bags|r")
        BankContainerBox.Title:SetText(showAllBank and "|cffffd100All Bank Items|r" or "|cffffd100Usable in Bank|r")
        BagContainerBox.ToggleBtn:SetSize(58, 20)
        BagContainerBox.ToggleBtn:SetScript("OnClick", function()
            Armory.state.showAllBagItemsInBox = not Armory.state.showAllBagItemsInBox
            MainPanel:RenderActivePane()
        end)
        BankContainerBox.ToggleBtn:SetSize(58, 20)
        BankContainerBox.ToggleBtn:SetScript("OnClick", function()
            Armory.state.showAllBankItemsInBox = not Armory.state.showAllBankItemsInBox
            MainPanel:RenderActivePane()
        end)
        StatsContainerBox.ToggleBtn:Hide()

        PopulateBottomItemGridBox(
            BagContainerBox,
            charData.bags or {},
            charData.faction,
            showAllBags,
            "No roster upgrades or needed crafting mats in " .. charName .. "'s Bags.\n\n(Click [Usable] in the top-right of this box to toggle All Bag Items!)",
            false
        )
        PopulateBottomItemGridBox(
            BankContainerBox,
            charData.bank or {},
            charData.faction,
            showAllBank,
            "No roster upgrades or needed crafting mats in " .. charName .. "'s Bank.\n\n(Visit a Banker in-game to scan Bank, or click [Usable] to toggle All!)",
            false
        )
    else
        -- Synced Peer: Bags & Bank remain CLOSED until explicitly requested and approved!
        StatsContainerBox.ToggleBtn:SetSize(84, 20)
        StatsContainerBox.ToggleBtn:Show()
        StatsContainerBox.ToggleBtn:SetText(charData.recipesSynced and "|cff00ff00Recipes OK|r" or "|cffffd100Req Recipes|r")
        StatsContainerBox.ToggleBtn:SetScript("OnClick", function()
            if ns.GuildNet and ns.GuildNet.RequestPeerCategory then
                ns.GuildNet.RequestPeerCategory(charName, "RECIPES")
            end
        end)

        if not charData.bagsSynced then
            BagContainerBox.Title:SetText("|cffffaa00Bags (Closed)|r")
            PopulateBottomItemGridBox(
                BagContainerBox,
                {},
                charData.faction,
                true,
                "|cffffcc00[BAGS CLOSED]|r\n\n" .. charName .. "'s Bag Inventory is closed.\nClick |cff00ff00[Req Bags]|r above to request a Bag sync (goes into their Sync Queue).",
                true
            )
            BagContainerBox.ToggleBtn:SetSize(74, 20)
            BagContainerBox.ToggleBtn:SetText("|cff00ff00Req Bags|r")
            BagContainerBox.ToggleBtn:SetScript("OnClick", function()
                if ns.GuildNet and ns.GuildNet.RequestPeerCategory then
                    ns.GuildNet.RequestPeerCategory(charName, "BAGS")
                end
            end)
        else
            BagContainerBox.Title:SetText("|cff00ff00Synced Bags|r")
            local peerBagList = charData.bags or {}
            if #peerBagList == 0 then
                for id, cnt in pairs(charData.mats or {}) do
                    if cnt and cnt > 0 then table.insert(peerBagList, { itemID = id, count = cnt }) end
                end
            end
            PopulateBottomItemGridBox(
                BagContainerBox,
                peerBagList,
                charData.faction,
                true,
                "No tradeable items found in " .. charName .. "'s synced bags.",
                true
            )
            BagContainerBox.ToggleBtn:SetSize(74, 20)
            BagContainerBox.ToggleBtn:SetText("|cff00ff96Re-Sync|r")
            BagContainerBox.ToggleBtn:SetScript("OnClick", function()
                if ns.GuildNet and ns.GuildNet.RequestPeerCategory then
                    ns.GuildNet.RequestPeerCategory(charName, "BAGS")
                end
            end)
        end

        if not charData.bankSynced then
            BankContainerBox.Title:SetText("|cffffaa00Bank (Closed)|r")
            PopulateBottomItemGridBox(
                BankContainerBox,
                {},
                charData.faction,
                true,
                "|cffffcc00[PERSONAL BANK CLOSED]|r\n\n" .. charName .. "'s Personal Bank is closed.\nClick |cff00ff00[Req Bank]|r above to request a Bank sync (goes into their Sync Queue).",
                true
            )
            BankContainerBox.ToggleBtn:SetSize(74, 20)
            BankContainerBox.ToggleBtn:SetText("|cff00ff00Req Bank|r")
            BankContainerBox.ToggleBtn:SetScript("OnClick", function()
                if ns.GuildNet and ns.GuildNet.RequestPeerCategory then
                    ns.GuildNet.RequestPeerCategory(charName, "BANK")
                end
            end)
        else
            BankContainerBox.Title:SetText("|cff00ff00Synced Bank|r")
            local peerBankList = charData.bank or {}
            if #peerBankList == 0 then
                for id, cnt in pairs(charData.cons or {}) do
                    if cnt and cnt > 0 then table.insert(peerBankList, { itemID = id, count = cnt }) end
                end
            end
            PopulateBottomItemGridBox(
                BankContainerBox,
                peerBankList,
                charData.faction,
                true,
                "No tradeable items found in " .. charName .. "'s synced bank.",
                true
            )
            BankContainerBox.ToggleBtn:SetSize(74, 20)
            BankContainerBox.ToggleBtn:SetText("|cff00ff96Re-Sync|r")
            BankContainerBox.ToggleBtn:SetScript("OnClick", function()
                if ns.GuildNet and ns.GuildNet.RequestPeerCategory then
                    ns.GuildNet.RequestPeerCategory(charName, "BANK")
                end
            end)
        end
    end

    PopulateRightStatsAndProfsBox(charName, charData, totalGS, avgILvl, isSyncedPeer)
end