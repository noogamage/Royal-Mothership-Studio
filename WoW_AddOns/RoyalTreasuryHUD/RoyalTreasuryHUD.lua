-- ============================================================================
-- ROYAL TREASURY HUD (Bag Appraisal, Auto-Vendor Greys, Mount Goal & Loot Ledger)
-- Crafted by Queen Ava for King Stephen
-- ============================================================================

local ADDON_NAME = ...
RoyalTreasuryHUDDB = RoyalTreasuryHUDDB or {}

local RT = CreateFrame("Frame", "RoyalTreasuryHUDFrame", UIParent, "BackdropTemplate")
RT:SetSize(330, 82)
RT:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 18, -100)
RT:SetFrameStrata("MEDIUM")
RT:SetClampedToScreen(true)
RT:SetMovable(true)
RT:EnableMouse(true)
RT:RegisterForDrag("LeftButton")

RT:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 8, edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 }
})
RT:SetBackdropColor(0.06, 0.03, 0.10, 0.90)
RT:SetBackdropBorderColor(0.85, 0.68, 0.15, 0.95)

-- Top Accent Line
local topBar = RT:CreateTexture(nil, "ARTWORK")
topBar:SetHeight(2)
topBar:SetPoint("TOPLEFT", RT, "TOPLEFT", 4, -4)
topBar:SetPoint("TOPRIGHT", RT, "TOPRIGHT", -4, -4)
topBar:SetColorTexture(1.0, 0.82, 0.0, 0.7)

-- Container API wrappers (supports both Classic C_Container and legacy globals)
local function GetNumSlots(bag)
    if C_Container and C_Container.GetContainerNumSlots then
        return C_Container.GetContainerNumSlots(bag) or 0
    elseif GetContainerNumSlots then
        return GetContainerNumSlots(bag) or 0
    end
    return 0
end

local function GetSlotInfo(bag, slot)
    if C_Container and C_Container.GetContainerItemInfo then
        local info = C_Container.GetContainerItemInfo(bag, slot)
        if info then
            return info.hyperlink, info.stackCount or 1, info.quality, info.isLocked, info.iconFileID
        end
        return nil
    elseif GetContainerItemInfo then
        local icon, count, locked, quality, _, _, link = GetContainerItemInfo(bag, slot)
        if link then
            return link, count or 1, quality, locked, icon
        end
    end
    return nil
end

local function UseBagSlot(bag, slot)
    if C_Container and C_Container.UseContainerItem then
        C_Container.UseContainerItem(bag, slot)
    elseif UseContainerItem then
        UseContainerItem(bag, slot)
    end
end

local function FormatCoins(copper, showZeroCopper)
    if not copper or copper < 0 then copper = 0 end
    local g = math.floor(copper / 10000)
    local s = math.floor((copper % 10000) / 100)
    local c = math.floor(copper % 100)
    if g > 0 then
        return string.format("|cffffd100%dg|r |cffc7c7cf%ds|r |cffeda55f%dc|r", g, s, c)
    elseif s > 0 then
        return string.format("|cffc7c7cf%ds|r |cffeda55f%dc|r", s, c)
    else
        return string.format("|cffeda55f%dc|r", c)
    end
end

-- Header Title
local titleTxt = RT:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
titleTxt:SetPoint("TOPLEFT", RT, "TOPLEFT", 10, -8)
titleTxt:SetText("|cffffd100Royal Treasury|r |cffff77aa& Loot Ledger|r")

-- Line 1: Gold + Session Net + Gold/hr
local goldTxt = RT:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
goldTxt:SetPoint("TOPLEFT", RT, "TOPLEFT", 10, -24)
goldTxt:SetJustifyH("LEFT")

-- Line 2: Bag Value + Grey Trash Value + Cheapest Stack
local bagValueTxt = RT:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
bagValueTxt:SetPoint("TOPLEFT", RT, "TOPLEFT", 10, -40)
bagValueTxt:SetJustifyH("LEFT")

-- Mount / Gold Goal Progress Bar
local goalBg = CreateFrame("Frame", nil, RT, "BackdropTemplate")
goalBg:SetSize(222, 16)
goalBg:SetPoint("BOTTOMLEFT", RT, "BOTTOMLEFT", 10, 8)
goalBg:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
})
goalBg:SetBackdropColor(0.03, 0.02, 0.05, 0.95)
goalBg:SetBackdropBorderColor(0.45, 0.35, 0.12, 0.85)

local goalFill = goalBg:CreateTexture(nil, "ARTWORK")
goalFill:SetPoint("TOPLEFT", goalBg, "TOPLEFT", 1, -1)
goalFill:SetPoint("BOTTOMLEFT", goalBg, "BOTTOMLEFT", 1, 1)
goalFill:SetWidth(1)
goalFill:SetColorTexture(0.15, 0.72, 0.38, 0.85)

local goalTxt = goalBg:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
goalTxt:SetPoint("CENTER", goalBg, "CENTER", 0, 0)

-- Button: [Drop Hint] (Finds cheapest item stack in bags to make room)
local dropBtn = CreateFrame("Button", nil, RT, "BackdropTemplate")
dropBtn:SetSize(82, 18)
dropBtn:SetPoint("BOTTOMRIGHT", RT, "BOTTOMRIGHT", -8, 7)
dropBtn:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
})
dropBtn:SetBackdropColor(0.32, 0.10, 0.22, 0.95)
dropBtn:SetBackdropBorderColor(0.95, 0.65, 0.15, 0.9)
local dropBtnLbl = dropBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
dropBtnLbl:SetPoint("CENTER")
dropBtnLbl:SetText("|cffffd100Cheapest Slot|r")

-- Button: [Ledger] (Toggles recent loot & vendor settings drawer)
local ledgerBtn = CreateFrame("Button", nil, RT, "BackdropTemplate")
ledgerBtn:SetSize(64, 16)
ledgerBtn:SetPoint("TOPRIGHT", RT, "TOPRIGHT", -8, -6)
ledgerBtn:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
})
ledgerBtn:SetBackdropColor(0.14, 0.24, 0.42, 0.95)
ledgerBtn:SetBackdropBorderColor(0.4, 0.8, 1.0, 0.9)
local ledgerBtnLbl = ledgerBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
ledgerBtnLbl:SetPoint("CENTER")
ledgerBtnLbl:SetText("|cff00ffcc[Ledger v]|r")

-- ============================================================================
-- COLLAPSIBLE TREASURY LEDGER DRAWER (Recent Notable Drops + Auto-Vendor Toggle)
-- ============================================================================
local drawer = CreateFrame("Frame", "RoyalTreasuryDrawer", RT, "BackdropTemplate")
drawer:SetPoint("TOPLEFT", RT, "BOTTOMLEFT", 0, -2)
drawer:SetPoint("TOPRIGHT", RT, "BOTTOMRIGHT", 0, -2)
drawer:SetHeight(168)
drawer:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 8, edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 }
})
drawer:SetBackdropColor(0.05, 0.03, 0.08, 0.94)
drawer:SetBackdropBorderColor(0.75, 0.58, 0.15, 0.90)
drawer:Hide()

-- Auto-Sell Greys Toggle Button
local autoSellBtn = CreateFrame("Button", nil, drawer, "BackdropTemplate")
autoSellBtn:SetSize(150, 18)
autoSellBtn:SetPoint("TOPLEFT", drawer, "TOPLEFT", 8, -8)
autoSellBtn:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
})
local autoSellLbl = autoSellBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
autoSellLbl:SetPoint("CENTER")

-- Auto-Repair Toggle Button
local autoRepairBtn = CreateFrame("Button", nil, drawer, "BackdropTemplate")
autoRepairBtn:SetSize(150, 18)
autoRepairBtn:SetPoint("TOPRIGHT", drawer, "TOPRIGHT", -8, -8)
autoRepairBtn:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
})
local autoRepairLbl = autoRepairBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
autoRepairLbl:SetPoint("CENTER")

local drawerHeader = drawer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
drawerHeader:SetPoint("TOPLEFT", drawer, "TOPLEFT", 10, -30)
drawerHeader:SetText("|cffffd100Recent Notable Loot & Bag Appraisal:|r")

local lootRows = {}
for i = 1, 6 do
    local row = CreateFrame("Button", nil, drawer)
    row:SetSize(310, 19)
    row:SetPoint("TOPLEFT", drawer, "TOPLEFT", 10, -46 - ((i - 1) * 19))

    local hl = row:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetColorTexture(1, 0.82, 0, 0.14)

    row.txt = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.txt:SetPoint("LEFT", row, "LEFT", 2, 0)
    row.txt:SetPoint("RIGHT", row, "RIGHT", -65, 0)
    row.txt:SetJustifyH("LEFT")
    row.txt:SetWordWrap(false)

    row.valTxt = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.valTxt:SetPoint("RIGHT", row, "RIGHT", -2, 0)
    row.valTxt:SetJustifyH("RIGHT")

    row:SetScript("OnEnter", function(self)
        if self.itemLink then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink(self.itemLink)
            GameTooltip:Show()
        end
    end)
    row:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    row:SetScript("OnClick", function(self)
        if self.itemLink then
            if IsModifiedClick("CHATLINK") and ChatEdit_GetActiveWindow() then
                ChatEdit_InsertLink(self.itemLink)
            elseif IsControlKeyDown() and DressUpItemLink then
                DressUpItemLink(self.itemLink)
            else
                DEFAULT_CHAT_FRAME:AddMessage(string.format("|cffffd100[Royal Treasury]|r %s (Stack Vendor Value: %s)", self.itemLink, FormatCoins(self.stackValue or 0)))
            end
        end
    end)

    lootRows[i] = row
end

-- ============================================================================
-- STATE & BAG APPRAISAL ENGINE
-- ============================================================================
local sessionStartGold = nil
local sessionStartTime = GetTime()
local lastScan = {
    totalVendorCopper = 0,
    greyVendorCopper = 0,
    greyCount = 0,
    freeSlots = 0,
    totalSlots = 0,
    cheapestItem = nil,
    topItems = {},
}

local function UpdateToggleVisuals()
    if RoyalTreasuryHUDDB.autoSellGreys ~= false then
        autoSellBtn:SetBackdropColor(0.10, 0.35, 0.18, 0.95)
        autoSellBtn:SetBackdropBorderColor(0.25, 0.85, 0.40, 0.9)
        autoSellLbl:SetText("|cff00ff96Auto-Sell Greys: ON|r")
    else
        autoSellBtn:SetBackdropColor(0.28, 0.12, 0.12, 0.95)
        autoSellBtn:SetBackdropBorderColor(0.65, 0.25, 0.25, 0.9)
        autoSellLbl:SetText("|cffff6666Auto-Sell Greys: OFF|r")
    end

    if RoyalTreasuryHUDDB.autoRepair ~= false then
        autoRepairBtn:SetBackdropColor(0.10, 0.35, 0.18, 0.95)
        autoRepairBtn:SetBackdropBorderColor(0.25, 0.85, 0.40, 0.9)
        autoRepairLbl:SetText("|cff00ff96Auto-Repair: ON|r")
    else
        autoRepairBtn:SetBackdropColor(0.28, 0.12, 0.12, 0.95)
        autoRepairBtn:SetBackdropBorderColor(0.65, 0.25, 0.25, 0.9)
        autoRepairLbl:SetText("|cffff6666Auto-Repair: OFF|r")
    end
end

autoSellBtn:SetScript("OnClick", function()
    RoyalTreasuryHUDDB.autoSellGreys = not (RoyalTreasuryHUDDB.autoSellGreys ~= false)
    UpdateToggleVisuals()
end)

autoRepairBtn:SetScript("OnClick", function()
    RoyalTreasuryHUDDB.autoRepair = not (RoyalTreasuryHUDDB.autoRepair ~= false)
    UpdateToggleVisuals()
end)

local function ScanBagsAppraisal()
    local totalVendor = 0
    local greyVendor = 0
    local greyStacks = 0
    local freeSlots = 0
    local totalSlots = 0
    local cheapest = nil
    local allPricedItems = {}

    for bag = 0, 4 do
        local numSlots = GetNumSlots(bag)
        if numSlots and numSlots > 0 then
            totalSlots = totalSlots + numSlots
            for slot = 1, numSlots do
                local link, count, quality = GetSlotInfo(bag, slot)
                if not link then
                    freeSlots = freeSlots + 1
                else
                    local itemName, _, itemRarity, _, _, _, _, _, _, _, sellPrice = GetItemInfo(link)
                    local q = quality or itemRarity or 1
                    local unitPrice = sellPrice or 0
                    local stackVal = unitPrice * (count or 1)

                    if stackVal > 0 then
                        totalVendor = totalVendor + stackVal
                        if q == 0 then
                            greyVendor = greyVendor + stackVal
                            greyStacks = greyStacks + 1
                        end
                        -- Track cheapest grey or common non-quest item to drop when bags fill up
                        if q <= 1 then
                            if not cheapest or stackVal < cheapest.stackVal then
                                cheapest = {
                                    bag = bag,
                                    slot = slot,
                                    link = link,
                                    name = itemName or "Unknown",
                                    count = count or 1,
                                    stackVal = stackVal,
                                    quality = q,
                                }
                            end
                        end
                        table.insert(allPricedItems, {
                            bag = bag,
                            slot = slot,
                            link = link,
                            count = count or 1,
                            stackVal = stackVal,
                            quality = q,
                        })
                    end
                end
            end
        end
    end

    table.sort(allPricedItems, function(a, b)
        return (a.stackVal or 0) > (b.stackVal or 0)
    end)

    lastScan.totalVendorCopper = totalVendor
    lastScan.greyVendorCopper = greyVendor
    lastScan.greyCount = greyStacks
    lastScan.freeSlots = freeSlots
    lastScan.totalSlots = totalSlots
    lastScan.cheapestItem = cheapest
    lastScan.topItems = allPricedItems
end

local function RefreshHUD()
    local curMoney = GetMoney() or 0
    if not sessionStartGold then
        sessionStartGold = curMoney
    end

    ScanBagsAppraisal()

    local netDiff = curMoney - sessionStartGold
    local netStr = ""
    if netDiff > 0 then
        netStr = " |cff00ff96(+" .. FormatCoins(netDiff) .. ")|r"
    elseif netDiff < 0 then
        netStr = " |cffff5555(-" .. FormatCoins(math.abs(netDiff)) .. ")|r"
    end

    goldTxt:SetText(string.format("Purse: %s%s", FormatCoins(curMoney), netStr))
    bagValueTxt:SetText(string.format(
        "Bag Loot: %s  |cffaaaaaa(Greys: %s)|r",
        FormatCoins(lastScan.totalVendorCopper),
        FormatCoins(lastScan.greyVendorCopper)
    ))

    -- Determine Mount / Savings Goal based on player level
    local pLvl = UnitLevel("player") or 1
    local targetCopper = 100 * 10000 -- 100g Level 40 Mount
    local goalLabel = "Lv40 Mount (100g)"
    if pLvl >= 40 and curMoney >= 100 * 10000 then
        targetCopper = 1000 * 10000 -- 1000g Epic Mount
        goalLabel = "Epic Mount (1000g)"
    elseif pLvl < 20 and curMoney < 10 * 10000 then
        targetCopper = 10 * 10000 -- First 10g milestone
        goalLabel = "Royal Milestone (10g)"
    end

    local liquidTotal = curMoney + lastScan.greyVendorCopper
    local pct = math.min(1.0, math.max(0.0, liquidTotal / targetCopper))
    goalFill:SetWidth(math.max(1, math.floor(220 * pct)))
    goalTxt:SetText(string.format("%s: %.1f%%", goalLabel, pct * 100))

    -- Refresh Drawer Rows (Top Priced Stacks in Bags)
    if drawer:IsShown() then
        for i = 1, 6 do
            local row = lootRows[i]
            local item = lastScan.topItems[i]
            if item then
                row.itemLink = item.link
                row.stackValue = item.stackVal
                row.txt:SetText(string.format("%d. %s |cffaaaaaa(x%d)|r", i, item.link, item.count))
                row.valTxt:SetText(FormatCoins(item.stackVal))
                row:Show()
            else
                row.itemLink = nil
                row.txt:SetText("|cff666666Empty slot|r")
                row.valTxt:SetText("")
                row:Show()
            end
        end
    end
end

-- ============================================================================
-- INTERACTIVE BUTTONS & DRAGGING
-- ============================================================================
dropBtn:SetScript("OnClick", function()
    ScanBagsAppraisal()
    local c = lastScan.cheapestItem
    if c then
        DEFAULT_CHAT_FRAME:AddMessage(string.format(
            "|cffffd100[Royal Treasury]|r Cheapest vendored stack in bags: %s x%d (Bag %d, Slot %d) — Worth only %s!",
            c.link, c.count, c.bag, c.slot, FormatCoins(c.stackVal)
        ))
        if OpenAllBags then OpenAllBags() end
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[Royal Treasury]|r No grey or common vendor items found in your bags!")
    end
end)

dropBtn:SetScript("OnEnter", function(self)
    ScanBagsAppraisal()
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
    GameTooltip:AddLine("👑 Cheapest Bag Slot Finder", 1, 0.82, 0)
    if lastScan.cheapestItem then
        local c = lastScan.cheapestItem
        GameTooltip:AddLine(string.format("Lowest value stack: %s (x%d)", c.link, c.count), 1, 1, 1)
        GameTooltip:AddLine(string.format("Location: Bag %d, Slot %d", c.bag, c.slot), 0.7, 0.9, 1.0)
        GameTooltip:AddLine("Vendor Value: " .. FormatCoins(c.stackVal), 0, 1, 0.6)
        GameTooltip:AddLine("Click to announce & open bags so you know what to drop!", 0.8, 0.8, 0.8)
    else
        GameTooltip:AddLine("No grey/white vendor items in bags.", 0.7, 0.7, 0.7)
    end
    GameTooltip:Show()
end)
dropBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

ledgerBtn:SetScript("OnClick", function()
    if drawer:IsShown() then
        drawer:Hide()
        ledgerBtnLbl:SetText("|cff00ffcc[Ledger v]|r")
    else
        drawer:Show()
        ledgerBtnLbl:SetText("|cffffd100[Ledger ^]|r")
        UpdateToggleVisuals()
        RefreshHUD()
    end
end)

RT:SetScript("OnDragStart", function(self)
    self:StartMoving()
end)
RT:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, relPoint, x, y = self:GetPoint()
    RoyalTreasuryHUDDB.point = point
    RoyalTreasuryHUDDB.relPoint = relPoint
    RoyalTreasuryHUDDB.x = x
    RoyalTreasuryHUDDB.y = y
end)

RT:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
    GameTooltip:AddLine("👑 Royal Treasury & Loot Ledger", 1, 0.82, 0)
    GameTooltip:AddDoubleLine("Purse + Greys Liquid Total:", FormatCoins((GetMoney() or 0) + lastScan.greyVendorCopper), 0.9, 0.9, 0.9, 1, 1, 1)
    GameTooltip:AddDoubleLine("Total Bag Vendor Value:", FormatCoins(lastScan.totalVendorCopper), 0.9, 0.9, 0.9, 1, 1, 1)
    GameTooltip:AddDoubleLine("Free Bag Slots:", string.format("%d / %d", lastScan.freeSlots, lastScan.totalSlots), 0.9, 0.9, 0.9, 0, 1, 0.6)
    if lastScan.cheapestItem then
        GameTooltip:AddDoubleLine("Cheapest Drop Candidate:", string.format("%s (%s)", lastScan.cheapestItem.link, FormatCoins(lastScan.cheapestItem.stackVal)), 1, 0.6, 0.6, 1, 1, 1)
    end
    GameTooltip:AddLine("Drag to move | Click [Ledger] to view top items & auto-vendor toggles", 0.65, 0.85, 1.0)
    GameTooltip:Show()
end)
RT:SetScript("OnLeave", function() GameTooltip:Hide() end)

-- ============================================================================
-- AUTO-SELL GREYS & AUTO-REPAIR AT MERCHANTS
-- ============================================================================
local function HandleMerchantVisit()
    if RoyalTreasuryHUDDB.autoSellGreys ~= false then
        local soldCount = 0
        local soldCopper = 0
        for bag = 0, 4 do
            local numSlots = GetNumSlots(bag)
            for slot = 1, numSlots do
                local link, count, quality, locked = GetSlotInfo(bag, slot)
                if link and not locked then
                    local _, _, itemRarity, _, _, _, _, _, _, _, sellPrice = GetItemInfo(link)
                    local q = quality or itemRarity
                    if q == 0 and sellPrice and sellPrice > 0 then
                        soldCount = soldCount + 1
                        soldCopper = soldCopper + (sellPrice * (count or 1))
                        UseBagSlot(bag, slot)
                    end
                end
            end
        end
        if soldCount > 0 then
            DEFAULT_CHAT_FRAME:AddMessage(string.format(
                "|cffffd100👑 [Royal Treasury]|r Auto-sold %d grey trash stack(s) for %s!",
                soldCount, FormatCoins(soldCopper)
            ))
        end
    end

    if RoyalTreasuryHUDDB.autoRepair ~= false and CanMerchantRepair and CanMerchantRepair() then
        local repairCost, canRepair = GetRepairAllCost()
        if canRepair and repairCost and repairCost > 0 and (GetMoney() or 0) >= repairCost then
            RepairAllItems()
            DEFAULT_CHAT_FRAME:AddMessage(string.format(
                "|cffffd100👑 [Royal Treasury]|r Royal armorers repaired all gear for %s.",
                FormatCoins(repairCost)
            ))
        end
    end
end

-- ============================================================================
-- EVENTS & SLASH COMMANDS
-- ============================================================================
RT:RegisterEvent("PLAYER_LOGIN")
RT:RegisterEvent("BAG_UPDATE")
RT:RegisterEvent("PLAYER_MONEY")
RT:RegisterEvent("MERCHANT_SHOW")
RT:RegisterEvent("GET_ITEM_INFO_RECEIVED")

RT:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        if RoyalTreasuryHUDDB.autoSellGreys == nil then
            RoyalTreasuryHUDDB.autoSellGreys = true
        end
        if RoyalTreasuryHUDDB.autoRepair == nil then
            RoyalTreasuryHUDDB.autoRepair = true
        end
        if RoyalTreasuryHUDDB.point then
            self:ClearAllPoints()
            self:SetPoint(
                RoyalTreasuryHUDDB.point,
                UIParent,
                RoyalTreasuryHUDDB.relPoint or "TOPLEFT",
                RoyalTreasuryHUDDB.x or 18,
                RoyalTreasuryHUDDB.y or -100
            )
        end
        sessionStartGold = GetMoney() or 0
        UpdateToggleVisuals()
        RefreshHUD()
    elseif event == "MERCHANT_SHOW" then
        HandleMerchantVisit()
        RefreshHUD()
    else
        RefreshHUD()
    end
end)

SLASH_ROYALTREASURY1 = "/treasury"
SLASH_ROYALTREASURY2 = "/rt"
SlashCmdList["ROYALTREASURY"] = function(msg)
    msg = (msg or ""):lower():match("^%s*(.-)%s*$")
    if msg == "reset" then
        RT:ClearAllPoints()
        RT:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 18, -100)
        RoyalTreasuryHUDDB.point = nil
        DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[Royal Treasury]|r HUD position reset.")
    else
        if RT:IsShown() then
            RT:Hide()
        else
            RT:Show()
            RefreshHUD()
        end
    end
end
