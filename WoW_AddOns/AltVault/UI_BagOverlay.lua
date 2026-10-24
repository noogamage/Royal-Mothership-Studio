-- ============================================================================
-- BLOCK HEADING: LIVE BAGS, PERSONAL BANK, BANK BAGS & TOOLTIP FLYOUT ENGINE
-- ============================================================================
local addonName, ns = ...
local BagOverlay = CreateFrame("Frame")

local function SafeRegisterEvent(frame, eventName)
    pcall(frame.RegisterEvent, frame, eventName)
end

SafeRegisterEvent(BagOverlay, "BAG_UPDATE_DELAYED")
SafeRegisterEvent(BagOverlay, "BAG_OPEN")
SafeRegisterEvent(BagOverlay, "BANKFRAME_OPENED")
SafeRegisterEvent(BagOverlay, "PLAYERBANKSLOTS_CHANGED")
SafeRegisterEvent(BagOverlay, "BANK_TAB_SETTINGS_UPDATED")
SafeRegisterEvent(BagOverlay, "BANK_TABS_CHANGED")

-- ============================================================================
-- BLOCK HEADING: SLOT EVALUATION & BORDER GLOW INJECTOR (NO MAILBOX ICON)
-- ============================================================================
local function ApplyLocalOrScannerGlow(itemButton, triggerStatus)
    if type(itemButton) ~= "table" then return end
    if ns.Scanner and ns.Scanner.ApplySlotBorderGlow then
        ns.Scanner.ApplySlotBorderGlow(itemButton, triggerStatus)
        return
    end

    if not itemButton.CreateTexture then return end
    if not itemButton.avGlowFrame then
        local glow = CreateFrame("Frame", nil, itemButton, "BackdropTemplate")
        glow:SetPoint("TOPLEFT", itemButton, "TOPLEFT", -1, 1)
        glow:SetPoint("BOTTOMRIGHT", itemButton, "BOTTOMRIGHT", 1, -1)
        glow:SetFrameLevel((itemButton:GetFrameLevel() or 1) + 8)
        glow:SetBackdrop({
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 2,
        })
        glow.InnerTint = glow:CreateTexture(nil, "BACKGROUND")
        glow.InnerTint:SetAllPoints(itemButton)
        itemButton.avGlowFrame = glow
    end

    local glow = itemButton.avGlowFrame
    if triggerStatus == "LOCKED_RED" then
        glow:SetBackdropBorderColor(1.0, 0.12, 0.12, 1.0)
        glow.InnerTint:SetColorTexture(0.90, 0.05, 0.05, 0.40)
        glow:Show()
        if ns.Scanner and ns.Scanner.ApplyPulseAnimation then ns.Scanner.ApplyPulseAnimation(glow, false) end
    elseif triggerStatus == "UPGRADE_SOON" then
        glow:SetBackdropBorderColor(0.1, 1.0, 0.2, 1.0)
        glow.InnerTint:SetColorTexture(0.1, 1.0, 0.2, 0.16)
        glow:Show()
        if ns.Scanner and ns.Scanner.ApplyPulseAnimation then ns.Scanner.ApplyPulseAnimation(glow, true) end
    elseif triggerStatus == "PROF_SOON" then
        glow:SetBackdropBorderColor(0.0, 0.9, 1.0, 1.0)
        glow.InnerTint:SetColorTexture(0.0, 0.9, 1.0, 0.16)
        glow:Show()
        if ns.Scanner and ns.Scanner.ApplyPulseAnimation then ns.Scanner.ApplyPulseAnimation(glow, true) end
    elseif triggerStatus == "UPGRADE" then
        glow:SetBackdropBorderColor(0.0, 0.85, 0.1, 1.0)
        glow.InnerTint:SetColorTexture(0.0, 0.85, 0.1, 0.12)
        glow:Show()
        if ns.Scanner and ns.Scanner.ApplyPulseAnimation then ns.Scanner.ApplyPulseAnimation(glow, false) end
    elseif triggerStatus == "PROF_MAT" then
        glow:SetBackdropBorderColor(0.0, 0.65, 1.0, 1.0)
        glow.InnerTint:SetColorTexture(0.0, 0.65, 1.0, 0.12)
        glow:Show()
        if ns.Scanner and ns.Scanner.ApplyPulseAnimation then ns.Scanner.ApplyPulseAnimation(glow, false) end
    else
        if ns.Scanner and ns.Scanner.ApplyPulseAnimation then ns.Scanner.ApplyPulseAnimation(glow, false) end
        glow:Hide()
    end
end

local function SetSlotButtonIconRedTint(itemButton, isRedLocked)
    if type(itemButton) ~= "table" then return end
    local iconTex = itemButton.icon or itemButton.Icon or (itemButton.GetName and itemButton:GetName() and _G[itemButton:GetName() .. "IconTexture"])
    if iconTex and iconTex.SetVertexColor then
        if isRedLocked then
            iconTex:SetVertexColor(1.0, 0.38, 0.38)
            itemButton.avWasRedTinted = true
        elseif itemButton.avWasRedTinted then
            iconTex:SetVertexColor(1.0, 1.0, 1.0)
            itemButton.avWasRedTinted = false
        end
    end
end

local function EvaluateAndGlowSlotButton(itemButton, itemLinkOrID, currentFaction)
    if type(itemButton) ~= "table" or not ns.Scanner then return end

    if itemButton.avIndicator then
        itemButton.avIndicator:Hide()
    end

    if not itemLinkOrID then
        SetSlotButtonIconRedTint(itemButton, false)
        ApplyLocalOrScannerGlow(itemButton, "CLEAR")
        return
    end

    if ns.DB and ns.DB.IsItemTradeLocked and ns.DB.IsItemTradeLocked(itemLinkOrID) then
        SetSlotButtonIconRedTint(itemButton, true)
        ApplyLocalOrScannerGlow(itemButton, "LOCKED_RED")
        return
    end

    SetSlotButtonIconRedTint(itemButton, false)

    local upgList, profList = ns.Scanner.EvaluateItemForRoster(itemLinkOrID, currentFaction)
    if upgList and #upgList > 0 then
        ApplyLocalOrScannerGlow(itemButton, upgList[1].status)
    elseif profList and #profList > 0 then
        ApplyLocalOrScannerGlow(itemButton, profList[1].status)
    else
        ApplyLocalOrScannerGlow(itemButton, "CLEAR")
    end
end

local function GetSlotItemRef(bagID, slotID)
    if bagID == nil or slotID == nil then return nil end
    if C_Container and C_Container.GetContainerItemInfo then
        local info = C_Container.GetContainerItemInfo(bagID, slotID)
        if info and (info.hyperlink or info.itemID) then
            return info.hyperlink or info.itemID
        end
    end
    if bagID == -1 and BankButtonIDToInvSlotID then
        local invSlot = BankButtonIDToInvSlotID(slotID)
        if invSlot then
            return GetInventoryItemLink("player", invSlot)
        end
    end
    return nil
end

local function ExtractItemFromButton(itemButton, fallbackBagID)
    if type(itemButton) ~= "table" then return nil end

    local bagID = (itemButton.GetBankTabID and itemButton:GetBankTabID())
        or itemButton.bankTabID
        or (itemButton.GetBagID and itemButton:GetBagID())
        or itemButton.bagID

    if bagID == nil and itemButton.GetParent then
        local parent = itemButton:GetParent()
        if type(parent) == "table" and parent ~= UIParent and parent ~= _G.ContainerFrameCombinedBags and parent ~= _G.BankPanel and parent.GetID then
            bagID = parent:GetID()
        end
    end
    if bagID == nil then
        bagID = fallbackBagID
    end

    local slotID = (itemButton.GetContainerSlotID and itemButton:GetContainerSlotID())
        or itemButton.containerSlotID
        or (itemButton.GetSlotIndex and itemButton:GetSlotIndex())
        or itemButton.slotIndex
        or (itemButton.GetID and itemButton:GetID())

    local itemRef = GetSlotItemRef(bagID, slotID)
    if itemRef then return itemRef end

    if type(itemButton.itemLocation) == "table" and C_Item then
        local ok, isValid = pcall(function()
            return itemButton.itemLocation.IsValid and itemButton.itemLocation:IsValid()
        end)
        if ok and isValid then
            local link = C_Item.GetItemLink and C_Item.GetItemLink(itemButton.itemLocation)
            if link then return link end
            local id = C_Item.GetItemID and C_Item.GetItemID(itemButton.itemLocation)
            if id then return id end
        end
    end

    return nil
end

local function ScanSingleContainerFrame(frame, currentFaction)
    if type(frame) ~= "table" or not frame.IsShown or not frame:IsShown() then return end

    local fallbackBagID = frame.GetID and frame:GetID()

    if frame.EnumerateValidItems then
        for k, v in frame:EnumerateValidItems() do
            local itemButton = (type(v) == "table" and v) or (type(k) == "table" and k)
            if itemButton then
                local itemRef = ExtractItemFromButton(itemButton, fallbackBagID)
                EvaluateAndGlowSlotButton(itemButton, itemRef, currentFaction)
            end
        end
        return
    elseif frame.Items and type(frame.Items) == "table" then
        for _, itemButton in ipairs(frame.Items) do
            if type(itemButton) == "table" and itemButton.IsShown and itemButton:IsShown() then
                local itemRef = ExtractItemFromButton(itemButton, fallbackBagID)
                EvaluateAndGlowSlotButton(itemButton, itemRef, currentFaction)
            end
        end
        return
    end

    local frameName = frame.GetName and frame:GetName()
    if frameName and fallbackBagID then
        local maxButtons = frame.size or (C_Container and C_Container.GetContainerNumSlots(fallbackBagID)) or 36
        for btnIndex = 1, maxButtons do
            local itemButton = _G[frameName .. "Item" .. btnIndex]
            if type(itemButton) == "table" and itemButton.IsShown and itemButton:IsShown() then
                local itemRef = ExtractItemFromButton(itemButton, fallbackBagID)
                EvaluateAndGlowSlotButton(itemButton, itemRef, currentFaction)
            end
        end
    end
end

local function ScanPersonalBankSlots(currentFaction)
    if BankFrame and BankFrame.IsShown and BankFrame:IsShown() then
        for slotID = 1, 28 do
            local itemButton = _G["BankFrameItem" .. slotID] or (BankSlotsFrame and BankSlotsFrame["Item" .. slotID])
            if type(itemButton) == "table" and itemButton.IsShown and itemButton:IsShown() then
                local itemRef = GetSlotItemRef(-1, slotID)
                EvaluateAndGlowSlotButton(itemButton, itemRef, currentFaction)
            end
        end
    end

    if BankPanel and BankPanel.IsShown and BankPanel:IsShown() and BankPanel.EnumerateValidItems then
        for k, v in BankPanel:EnumerateValidItems() do
            local itemButton = (type(v) == "table" and v) or (type(k) == "table" and k)
            if itemButton then
                local itemRef = ExtractItemFromButton(itemButton, -1)
                EvaluateAndGlowSlotButton(itemButton, itemRef, currentFaction)
            end
        end
    end
end

local function ScanAllLiveContainers()
    if not AltVaultDB or not AltVaultDB.Characters or not ns.Scanner then return end
    local currentFaction = UnitFactionGroup("player") or "Alliance"

    if _G.ContainerFrameCombinedBags then
        ScanSingleContainerFrame(_G.ContainerFrameCombinedBags, currentFaction)
    end

    local maxContainerFrames = _G.NUM_CONTAINER_FRAMES or 13
    for i = 1, maxContainerFrames do
        local frame = _G["ContainerFrame" .. i]
        if frame then
            ScanSingleContainerFrame(frame, currentFaction)
        end
    end

    if _G.ContainerFrameContainer and type(_G.ContainerFrameContainer.ContainerFrames) == "table" then
        for _, frame in ipairs(_G.ContainerFrameContainer.ContainerFrames) do
            ScanSingleContainerFrame(frame, currentFaction)
        end
    end

    ScanPersonalBankSlots(currentFaction)
end

ns.RefreshLiveContainerGlows = ScanAllLiveContainers

-- ============================================================================
-- BLOCK HEADING: HOOK BAG & BANK OPENING SO GLOWS APPEAR IMMEDIATELY
-- ============================================================================
local containerScanPending = false
local function ScheduleQuickContainerScan()
    if containerScanPending then return end
    containerScanPending = true
    C_Timer.After(0.15, function()
        containerScanPending = false
        ScanAllLiveContainers()
    end)
end

if _G.ToggleBag then hooksecurefunc("ToggleBag", ScheduleQuickContainerScan) end
if _G.OpenBag then hooksecurefunc("OpenBag", ScheduleQuickContainerScan) end
if _G.OpenAllBags then hooksecurefunc("OpenAllBags", ScheduleQuickContainerScan) end
if _G.ToggleAllBags then hooksecurefunc("ToggleAllBags", ScheduleQuickContainerScan) end
if _G.UpdateContainerFrameAnchors then hooksecurefunc("UpdateContainerFrameAnchors", ScheduleQuickContainerScan) end
if _G.ContainerFrame_GenerateFrame then hooksecurefunc("ContainerFrame_GenerateFrame", ScheduleQuickContainerScan) end
if _G.BankFrame_UpdateItems then hooksecurefunc("BankFrame_UpdateItems", ScheduleQuickContainerScan) end

C_Timer.After(0.5, function()
    if _G.ContainerFrameCombinedBags then
        pcall(_G.ContainerFrameCombinedBags.HookScript, _G.ContainerFrameCombinedBags, "OnShow", ScheduleQuickContainerScan)
        if _G.ContainerFrameCombinedBags.UpdateItems then
            hooksecurefunc(_G.ContainerFrameCombinedBags, "UpdateItems", ScanAllLiveContainers)
        end
    end
    for i = 1, (_G.NUM_CONTAINER_FRAMES or 13) do
        local cf = _G["ContainerFrame" .. i]
        if cf then
            pcall(cf.HookScript, cf, "OnShow", ScheduleQuickContainerScan)
            if cf.UpdateItems then
                hooksecurefunc(cf, "UpdateItems", ScanAllLiveContainers)
            end
        end
    end
    if _G.BankFrame then
        pcall(_G.BankFrame.HookScript, _G.BankFrame, "OnShow", ScheduleQuickContainerScan)
    end
    if _G.BankPanel then
        pcall(_G.BankPanel.HookScript, _G.BankPanel, "OnShow", ScheduleQuickContainerScan)
        if _G.BankPanel.SelectTab then
            hooksecurefunc(_G.BankPanel, "SelectTab", ScheduleQuickContainerScan)
        end
        if _G.BankPanel.RefreshBankPanel then
            hooksecurefunc(_G.BankPanel, "RefreshBankPanel", ScheduleQuickContainerScan)
        end
        if _G.BankPanel.GenerateItemSlotsForSelectedTab then
            hooksecurefunc(_G.BankPanel, "GenerateItemSlotsForSelectedTab", ScheduleQuickContainerScan)
        end
    end
end)

-- ============================================================================
-- BLOCK HEADING: LIVE GAMETOOLTIP HOVER FLYOUT (MULTI-PROFESSION AWARE)
-- ============================================================================
local function AppendAltVaultFlyoutToTooltip(tooltip, itemLink)
    if not tooltip or not itemLink or not AltVaultDB or not AltVaultDB.Characters or not ns.Scanner then return end

    local owner = tooltip:GetOwner()
    while owner do
        if owner == AltVaultMainPanel then
            return
        end
        owner = owner.GetParent and owner:GetParent() or nil
    end

    if tooltip.avLastAppendedLink == itemLink then return end
    tooltip.avLastAppendedLink = itemLink

    local currentFaction = UnitFactionGroup("player") or "Alliance"
    local itemGS, iLvl = ns.Scanner.CalculateItemGearScore(itemLink)
    local upgList, profList = ns.Scanner.EvaluateItemForRoster(itemLink, currentFaction)
    local allMatProfs = ns.Scanner.GetMaterialProfessionsList and ns.Scanner.GetMaterialProfessionsList(itemLink) or nil

    local isLockedRed = (ns.DB and ns.DB.IsItemTradeLocked and ns.DB.IsItemTradeLocked(itemLink)) or false
    local hasUpgrades = upgList and #upgList > 0
    local hasProfNeeds = profList and #profList > 0
    local hasMatProfs = allMatProfs and #allMatProfs > 0

    if not isLockedRed and not hasUpgrades and not hasProfNeeds and not hasMatProfs and (not itemGS or itemGS <= 0) then
        return
    end

    tooltip:AddLine(" ")
    if isLockedRed then
        tooltip:AddLine("|cffff2020[AltVault: NOT FOR TRADE — Important / Hidden from Players]|r", 1, 0.15, 0.15)
    end
    if itemGS and itemGS > 0 then
        tooltip:AddDoubleLine(
            "|cffffd100[AltVault] GearScore:|r",
            ns.Scanner.FormatGearScoreColor(itemGS) .. (iLvl and iLvl > 0 and (" |cffaaaaaa(iLvl " .. iLvl .. ")|r") or ""),
            1, 0.82, 0, 1, 1, 1
        )
    elseif hasMatProfs then
        tooltip:AddDoubleLine(
            "|cffffd100[AltVault] Used By Trades:|r",
            "|cff00ff96" .. table.concat(allMatProfs, ", ") .. "|r",
            1, 0.82, 0, 0, 1, 0.6
        )
    else
        tooltip:AddLine("|cffffd100[AltVault Roster Recommendations]|r")
    end

    if hasUpgrades then
        local maxShow = math.min(#upgList, 5)
        for i = 1, maxShow do
            local u = upgList[i]
            if u.status == "UPGRADE_SOON" then
                tooltip:AddDoubleLine(
                    string.format("|cff00ff00⚡ Next-Lvl Upgrade: %s|r |cffcccccc(Lvl %d %s)|r", u.name, u.level, u.spec or u.class or ""),
                    string.format("|cff00ff00+%d GS (Req Lvl %d)|r", u.delta, u.reqLvl or u.level),
                    0.1, 1.0, 0.2, 0.1, 1.0, 0.2
                )
            else
                tooltip:AddDoubleLine(
                    string.format("|cff00ff00★ Gear Upgrade: %s|r |cffcccccc(Lvl %d %s)|r", u.name, u.level, u.spec or u.class or ""),
                    string.format("|cff00ff00+%d GS (Equip Now)|r", u.delta),
                    0.0, 0.9, 0.2, 0.0, 0.9, 0.2
                )
            end
        end
    end

    if hasProfNeeds then
        local maxShow = math.min(#profList, 8)
        for i = 1, maxShow do
            local p = profList[i]
            if p.status == "PROF_SOON" then
                tooltip:AddDoubleLine(
                    string.format("|cff00ffff⚡ Skill-Up Mat: %s|r |cffcccccc(%s %d/300)|r", p.name, p.prof, p.rank or 1),
                    string.format("|cff00ffff%s|r", p.note or "Next Tier"),
                    0.0, 0.9, 1.0, 0.0, 0.9, 1.0
                )
            else
                tooltip:AddDoubleLine(
                    string.format("|cff00ccff⚒ Crafting Mat: %s|r |cffcccccc(%s %d/300)|r", p.name, p.prof, p.rank or 1),
                    string.format("|cff00ccff%s|r", p.note or "Usable Mat"),
                    0.0, 0.75, 1.0, 0.0, 0.75, 1.0
                )
            end
        end
    end

    tooltip:Show()
end

pcall(GameTooltip.HookScript, GameTooltip, "OnTooltipCleared", function(self)
    self.avLastAppendedLink = nil
end)
pcall(GameTooltip.HookScript, GameTooltip, "OnHide", function(self)
    self.avLastAppendedLink = nil
end)

if _G.TooltipDataProcessor and _G.TooltipDataProcessor.AddTooltipPostCall and _G.Enum and _G.Enum.TooltipDataType then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip, data)
        if tooltip ~= GameTooltip then return end
        local _, itemLink = TooltipUtil and TooltipUtil.GetDisplayedItem and TooltipUtil.GetDisplayedItem(tooltip)
        if not itemLink and tooltip.GetItem then
            _, itemLink = tooltip:GetItem()
        end
        if not itemLink and type(data) == "table" then
            itemLink = data.hyperlink or data.id
        end
        if not itemLink then
            local owner = tooltip:GetOwner()
            if type(owner) == "table" then
                itemLink = ExtractItemFromButton(owner, nil)
            end
        end
        if itemLink then
            AppendAltVaultFlyoutToTooltip(tooltip, itemLink)
        end
    end)
end

pcall(GameTooltip.HookScript, GameTooltip, "OnTooltipSetItem", function(self)
    local itemLink = nil
    if self.GetItem then
        _, itemLink = self:GetItem()
    end
    if not itemLink then
        local owner = self:GetOwner()
        if type(owner) == "table" then
            itemLink = ExtractItemFromButton(owner, nil)
        end
    end
    if itemLink then
        AppendAltVaultFlyoutToTooltip(self, itemLink)
    end
end)

if GameTooltip.SetBagItem then
    hooksecurefunc(GameTooltip, "SetBagItem", function(self, bagID, slotID)
        local itemRef = GetSlotItemRef(bagID, slotID)
        if itemRef then
            AppendAltVaultFlyoutToTooltip(self, itemRef)
        end
    end)
end

if GameTooltip.SetInventoryItem then
    hooksecurefunc(GameTooltip, "SetInventoryItem", function(self, unit, invSlot)
        if unit == "player" and invSlot then
            local link = GetInventoryItemLink("player", invSlot)
            if link then
                AppendAltVaultFlyoutToTooltip(self, link)
            end
        end
    end)
end

if GameTooltip.SetGuildBankItem then
    hooksecurefunc(GameTooltip, "SetGuildBankItem", function(self, tab, slot)
        local link = GetGuildBankItemLink and GetGuildBankItemLink(tab, slot)
        if link then
            AppendAltVaultFlyoutToTooltip(self, link)
        end
    end)
end

-- ============================================================================
-- BLOCK HEADING: CONTAINER REFRESH HANDLING EVENT
-- ============================================================================
BagOverlay:SetScript("OnEvent", function(self, event)
    ScheduleQuickContainerScan()
end)