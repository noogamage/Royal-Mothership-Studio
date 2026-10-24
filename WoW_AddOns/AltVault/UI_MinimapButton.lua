-- ============================================================================
-- BLOCK HEADING: MINIMAP BUTTON FRAME CREATION (WOW: FOREVER 16001)
-- ============================================================================
local addonName, ns = ...
local MiniButton = CreateFrame("Button", "AltVaultCleanButton", Minimap)

MiniButton:SetSize(31, 31)
MiniButton:SetFrameStrata("MEDIUM")
MiniButton:SetFrameLevel(10)
MiniButton:SetToplevel(true)
MiniButton:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
MiniButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
MiniButton:RegisterForDrag("LeftButton")

MiniButton.Icon = MiniButton:CreateTexture(nil, "BACKGROUND")
MiniButton.Icon:SetTexture("Interface\\Icons\\INV_Misc_Bag_10_Black")
MiniButton.Icon:SetSize(20, 20)
MiniButton.Icon:SetPoint("TOPLEFT", MiniButton, "TOPLEFT", 7, -6)

MiniButton.Border = MiniButton:CreateTexture(nil, "OVERLAY")
MiniButton.Border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
MiniButton.Border:SetSize(53, 53)
MiniButton.Border:SetPoint("TOPLEFT", MiniButton, "TOPLEFT", 0, 0)

-- ============================================================================
-- BLOCK HEADING: POSITION CALCULATOR & BOUNDS CONSTRAINT ENGINE
-- ============================================================================
local function UpdateButtonPosition()
    local angle = (AltVaultDB and AltVaultDB.MinimapAngle) or 45
    local rads = math.rad(angle)
    local radius = (Minimap:GetWidth() / 2) + 5
    local x = radius * math.cos(rads)
    local y = radius * math.sin(rads)

    MiniButton:ClearAllPoints()
    MiniButton:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

ns.UpdateMinimapPosition = UpdateButtonPosition

-- ============================================================================
-- BLOCK HEADING: MOUSE DRAG POSITION CALCULATION
-- ============================================================================
local atan2 = math.atan2 or math.atan

MiniButton:SetScript("OnDragStart", function(self)
    self:LockHighlight()
    self:SetScript("OnUpdate", function()
        local mx, my = GetCursorPosition()
        local scale = Minimap:GetEffectiveScale()
        local x, y = mx / scale, my / scale
        local cx, cy = Minimap:GetCenter()

        local angle = math.deg(atan2(y - cy, x - cx))
        if angle < 0 then angle = angle + 360 end

        if AltVaultDB then
            AltVaultDB.MinimapAngle = angle
        end
        UpdateButtonPosition()
    end)
end)

MiniButton:SetScript("OnDragStop", function(self)
    self:UnlockHighlight()
    self:SetScript("OnUpdate", nil)
end)

-- ============================================================================
-- BLOCK HEADING: INTERACTIVE CLICK & LIVE DATABASE TOOLTIP HANDLING
-- ============================================================================
local function RenderMinimapTooltip(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:ClearLines()
    GameTooltip:AddLine("AltVault Armory (Forever)", 1, 0.82, 0)
    GameTooltip:AddLine("|cff00ff00Left-Click:|r Toggle Armory & Database Window", 1, 1, 1)
    GameTooltip:AddLine("|cff00ff00Left-Drag:|r Move Minimap Button", 1, 1, 1)

    if AltVaultDB then
        local numItems, numPatterns = 0, 0
        for _ in pairs(AltVaultDB.ItemCache or {}) do numItems = numItems + 1 end
        for _ in pairs(AltVaultDB.PatternDB or {}) do numPatterns = numPatterns + 1 end
        local cursor = AltVaultDB.CrawlCursorID or 150
        local maxID = (ns.DB and ns.DB.MAX_CRAWL_ID) or 500000
        local pct = math.min(100, (cursor / maxID) * 100)

        GameTooltip:AddLine(" ")
        GameTooltip:AddDoubleLine("|cffffd100Indexed Gear & Mats:|r", "|cffffffff" .. numItems .. "|r", 1, 0.82, 0, 1, 1, 1)
        GameTooltip:AddDoubleLine("|cffffd100Indexed Patterns:|r", "|cff00ffff" .. numPatterns .. "|r", 1, 0.82, 0, 0, 1, 1)
        GameTooltip:AddDoubleLine("|cffaaaaaaServer Scan Sweep:|r", string.format("|cff00ff00%.1f%% (ID %d / %d)|r", pct, cursor, maxID), 0.7, 0.7, 0.7, 0, 1, 0.5)
    end

    GameTooltip:Show()
end

local tooltipTicker = nil

MiniButton:SetScript("OnClick", function(self, button)
    if AltVaultMainPanel then
        if AltVaultMainPanel:IsShown() then
            AltVaultMainPanel:Hide()
        else
            AltVaultMainPanel:Show()
            AltVaultMainPanel:RefreshView()
        end
    end
end)

MiniButton:SetScript("OnEnter", function(self)
    RenderMinimapTooltip(self)
    if tooltipTicker then tooltipTicker:Cancel() end
    tooltipTicker = C_Timer.NewTicker(0.5, function()
        if MiniButton:IsMouseOver() then
            RenderMinimapTooltip(MiniButton)
        end
    end)
end)

MiniButton:SetScript("OnLeave", function()
    if tooltipTicker then
        tooltipTicker:Cancel()
        tooltipTicker = nil
    end
    GameTooltip:Hide()
end)

UpdateButtonPosition()