-- ============================================================================
-- FILE: UI_LeftSidebar.lua (MODULE 2 OF 3 SPLIT FROM UI_MainPanel.lua)
-- BLOCK HEADING: FULL-HEIGHT ALT ROSTER SIDEBAR & GLOBAL WINDOW SCALING
-- ============================================================================
local addonName, ns = ...
local MainPanel = _G.AltVaultMainPanel
if not MainPanel then return end

local CreateBackdrop = MainPanel.CreateBackdrop
local SetSolid = MainPanel.SetSolid
local STANDARD_FONT = MainPanel.STANDARD_FONT
local BASE_PANEL_W = MainPanel.BASE_PANEL_W
local BASE_PANEL_H = MainPanel.BASE_PANEL_H

local TopHeaderBar = MainPanel.TopHeaderBar
local AllianceBtn = MainPanel.AllianceBtn
local HordeBtn = MainPanel.HordeBtn
local HeaderStatusBanner = MainPanel.HeaderStatusBanner

local charButtons = MainPanel.charButtons
local peerButtons = MainPanel.peerButtons
local exteriorTabs = MainPanel.exteriorTabs

local AltRosterBanner = CreateBackdrop("Frame", "AltVaultAltRosterBanner", MainPanel)
AltRosterBanner:SetHeight(28)
if AltRosterBanner.SetBackdrop then
    AltRosterBanner:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    AltRosterBanner:SetBackdropColor(0.08, 0.12, 0.18, 0.96)
    AltRosterBanner:SetBackdropBorderColor(0.85, 0.68, 0.20, 0.95)
end

local AltRosterTitle = AltRosterBanner:CreateFontString(nil, "OVERLAY", "GameFontNormal")
AltRosterTitle:SetPoint("CENTER", AltRosterBanner, "CENTER", 0, 0)
AltRosterTitle:SetText("|cffffd100MY CHARACTERS|r")

local AltRosterScroll = CreateFrame("ScrollFrame", "AltVaultAltRosterScroll", MainPanel, "UIPanelScrollFrameTemplate")
local AltRosterChild = CreateFrame("Frame", nil, AltRosterScroll)
AltRosterChild:SetSize(160, 200)
AltRosterScroll:SetScrollChild(AltRosterChild)

local function IsShowingSyncedPeersOnLeft(panel)
    local mode = (panel.GetActiveViewMode and panel:GetActiveViewMode()) or panel._state.activeViewMode
    if mode == "VIRTUAL_CHAT" then
        return true
    end
    if panel._state.selectedSyncedPeer ~= nil then
        return true
    end
    return false
end

function MainPanel:UpdateLeftSidebarHighlights()
    local selChar = self._state.selectedCharacter
    local selPeer = self._state.selectedSyncedPeer
    for _, btn in ipairs(charButtons) do
        if not selPeer and selChar == btn.charName then
            btn:LockHighlight()
        else
            btn:UnlockHighlight()
        end
    end
    for _, btn in ipairs(peerButtons) do
        if btn.peerName and selPeer == btn.peerName then
            btn:LockHighlight()
        else
            btn:UnlockHighlight()
        end
    end
end

-- ============================================================================
-- BLOCK HEADING: GLOBAL RESPONSIVE SCALING & SLASH COMMANDS
-- ============================================================================
function MainPanel:ApplyGlobalButtonScaling()
    local bScale = self:GetButtonScale()
    local winFactor = self:GetWindowScaleFactor()
    local topHeaderH = self:GetTopHeaderHeight()
    local leftX = self:GetLeftColumnOffset()
    local baseTopY = self:GetBaseContentTopY()
    local btnW = math.max(95, leftX - 42)
    local btnH = math.max(22, math.floor(28 * bScale + 0.5))
    local btnStep = btnH + 4

    TopHeaderBar:SetHeight(topHeaderH)

    local facW = math.max(82, math.floor(108 * bScale + 0.5))
    local facH = math.max(24, math.floor(29 * bScale + 0.5))
    local facFont = math.max(10, math.min(18, math.floor(13 * bScale + 0.5)))

    AllianceBtn:SetSize(facW, facH)
    HordeBtn:SetSize(facW, facH)
    if AllianceBtn:GetFontString() then AllianceBtn:GetFontString():SetFont(STANDARD_FONT, facFont, "OUTLINE") end
    if HordeBtn:GetFontString() then HordeBtn:GetFontString():SetFont(STANDARD_FONT, facFont, "OUTLINE") end
    AllianceBtn:ClearAllPoints()
    AllianceBtn:SetPoint("LEFT", TopHeaderBar, "LEFT", 12, 0)
    HordeBtn:ClearAllPoints()
    HordeBtn:SetPoint("LEFT", AllianceBtn, "RIGHT", 8, 0)

    if HeaderStatusBanner then
        local statusFont = math.max(10, math.min(18, math.floor(12.5 * winFactor + 0.5)))
        HeaderStatusBanner:SetFont(STANDARD_FONT, statusFont, "OUTLINE")
        HeaderStatusBanner:ClearAllPoints()
        HeaderStatusBanner:SetPoint("LEFT", HordeBtn, "RIGHT", 16, 0)
        HeaderStatusBanner:SetPoint("RIGHT", TopHeaderBar, "RIGHT", -12, 0)

        local activePeer = self:GetSelectedSyncedPeer()
        local activeChar = activePeer or self:GetSelectedCharacter() or UnitName("player") or "Character"
        local activeLvl = self:GetActiveCharacterLevel()
        local facLabel = (self:GetSelectedFaction() == "Horde") and "|cffff4444Horde|r" or "|cff3399ffAlliance|r"
        local modeTag = activePeer and "|cff00ccff[Synced Player]|r " or ""
        HeaderStatusBanner:SetText(string.format("%s|cffffd100%s|r |cffcccccc(Lvl %d • %s)|r   •   |cff88ccffDrag bottom-right corner to scale all tabs & text|r",
            modeTag, activeChar, activeLvl, facLabel))
    end

    local panelH = self:GetHeight() or BASE_PANEL_H
    local numTabs = math.max(1, #exteriorTabs)
    local availTabH = math.max(280, panelH - 36)
    local maxTabStep = math.floor(availTabH / numTabs)
    local desiredTabH = math.floor(31 * bScale + 0.5)
    local tabH = math.min(math.max(20, maxTabStep - 2), desiredTabH)
    local tabStep = math.min(tabH + 2, maxTabStep)
    local tabW = math.max(154, math.floor(176 * bScale + 0.5))
    local tabFont = math.max(10, math.min(16, math.floor(tabH * 0.48), math.floor(12.2 * bScale + 0.5)))

    for idx, tab in ipairs(exteriorTabs) do
        tab:SetSize(tabW, tabH)
        local fs = tab:GetFontString()
        if fs then
            fs:SetFont(STANDARD_FONT, tabFont, "OUTLINE")
            if fs.SetWordWrap then fs:SetWordWrap(false) end
            if fs.SetWidth then fs:SetWidth(tabW - 14) end
        end
        tab:ClearAllPoints()
        tab:SetPoint("TOPLEFT", MainPanel, "TOPRIGHT", -2, -32 - ((idx - 1) * tabStep))
    end

    local bannerH = math.max(24, math.floor(27 * bScale + 0.5))
    local bannerFont = math.max(10, math.min(16, math.floor(12 * bScale + 0.5)))
    AltRosterBanner:ClearAllPoints()
    AltRosterBanner:SetPoint("TOPLEFT", MainPanel, "TOPLEFT", 8, baseTopY)
    AltRosterBanner:SetSize(btnW + 26, bannerH)
    AltRosterTitle:SetFont(STANDARD_FONT, bannerFont, "OUTLINE")

    local showPeers = IsShowingSyncedPeersOnLeft(self)
    if showPeers then
        AltRosterTitle:SetText("|cff00ccffSYNCED PLAYERS|r")
        if AltRosterBanner.SetBackdropBorderColor then
            AltRosterBanner:SetBackdropBorderColor(0.20, 0.75, 0.95, 0.95)
        end
    else
        AltRosterTitle:SetText("|cffffd100MY CHARACTERS|r")
        if AltRosterBanner.SetBackdropBorderColor then
            AltRosterBanner:SetBackdropBorderColor(0.85, 0.68, 0.20, 0.95)
        end
    end

    local rosterTopY = baseTopY - bannerH - 6
    local availLeftH = math.max(180, panelH - math.abs(rosterTopY) - 18)

    AltRosterScroll:ClearAllPoints()
    AltRosterScroll:SetPoint("TOPLEFT", MainPanel, "TOPLEFT", 10, rosterTopY)
    AltRosterScroll:SetPoint("BOTTOMLEFT", MainPanel, "BOTTOMLEFT", 10, 14)
    AltRosterScroll:SetWidth(btnW + 4)
    AltRosterChild:SetWidth(btnW)

    local shownCount = 0
    if showPeers then
        for _, btn in ipairs(charButtons) do btn:Hide() end
        for idx, btn in ipairs(peerButtons) do
            self:StyleControlButton(btn, 150, 28, 12.5)
            btn:SetSize(btnW - 2, btnH)
            btn:ClearAllPoints()
            btn:SetPoint("TOPLEFT", AltRosterChild, "TOPLEFT", 2, -((idx - 1) * btnStep))
            if btn:IsShown() then shownCount = idx end
        end
    else
        for _, btn in ipairs(peerButtons) do btn:Hide() end
        for idx, btn in ipairs(charButtons) do
            self:StyleControlButton(btn, 150, 28, 13)
            btn:SetSize(btnW - 2, btnH)
            btn:ClearAllPoints()
            btn:SetPoint("TOPLEFT", AltRosterChild, "TOPLEFT", 2, -((idx - 1) * btnStep))
            if btn:IsShown() then shownCount = idx end
        end
    end
    AltRosterChild:SetHeight(math.max(availLeftH, shownCount * btnStep + 8))

    if self.ScaleDBHeaderControls then
        self:ScaleDBHeaderControls(bScale, leftX, baseTopY)
    end

    if self.OnApplyExternalScaling then
        self:OnApplyExternalScaling(bScale, leftX, baseTopY)
    end
end

function MainPanel:UpdateLayoutSizes()
    self:ApplyGlobalButtonScaling()
    if MainPanel:IsShown() then self:RenderActivePane() end
end

MainPanel:SetScript("OnSizeChanged", function(self) self:UpdateLayoutSizes() end)

SLASH_ALTVAULT1 = "/altvault"
SLASH_ALTVAULT2 = "/av"
SlashCmdList["ALTVAULT"] = function()
    if MainPanel:IsShown() then
        MainPanel:Hide()
    else
        -- Default to the currently logged-in character whenever opening the window!
        local curPlayer = UnitName("player")
        local curFaction = UnitFactionGroup and UnitFactionGroup("player")
        if curFaction == "Alliance" or curFaction == "Horde" then
            MainPanel._state.selectedFaction = curFaction
        end
        if curPlayer and curPlayer ~= "Unknown" then
            MainPanel._state.selectedCharacter = curPlayer
            MainPanel._state.selectedSyncedPeer = nil
        end

        MainPanel:Show()
        MainPanel:SetFrameStrata("DIALOG")
        MainPanel:Raise()
        MainPanel:ApplyGlobalButtonScaling()
        MainPanel:RefreshView()
    end
end

-- ============================================================================
-- BLOCK HEADING: SYNCED PLAYERS LEFT PANEL BUILDER (FOR VIRTUAL GUILD CHAT)
-- ============================================================================
function MainPanel:RefreshPeerSidebarList()
    for _, btn in ipairs(peerButtons) do
        btn:Hide()
    end
    if not AltVaultDB then return end

    local showPeers = IsShowingSyncedPeersOnLeft(self)
    if not showPeers then
        for _, btn in ipairs(charButtons) do
            if btn.charName then btn:Show() end
        end
        return
    end

    -- Hide Alt buttons while Synced Players mode is active in the left panel
    for _, btn in ipairs(charButtons) do
        btn:Hide()
    end

    local faction = self:GetSelectedFaction()
    local bScale = self:GetButtonScale()
    local leftX = self:GetLeftColumnOffset()
    local btnW = math.max(95, leftX - 42)
    local btnH = math.max(22, math.floor(28 * bScale + 0.5))
    local btnStep = btnH + 4

    local sortedPeers = {}
    for peerName, pData in pairs(AltVaultDB.GuildNetwork or {}) do
        if type(pData) == "table" and pData.explicitlyApprovedSync == true and not (AltVaultDB.Characters and AltVaultDB.Characters[peerName]) then
            if not pData.faction or pData.faction == faction then
                local isOnline = (ns.GuildNet and ns.GuildNet.IsPeerOnline and ns.GuildNet.IsPeerOnline(peerName)) or false
                table.insert(sortedPeers, {
                    name = peerName,
                    data = pData,
                    isOnline = isOnline,
                })
            end
        end
    end

    table.sort(sortedPeers, function(a, b)
        if a.isOnline ~= b.isOnline then return a.isOnline end
        return a.name < b.name
    end)

    local btnIdx = 0
    local function AcquirePeerBtn()
        btnIdx = btnIdx + 1
        local b = peerButtons[btnIdx]
        if not b then
            b = CreateFrame("Button", "AltVaultPeerSidebarBtn" .. btnIdx, AltRosterChild, "UIPanelButtonTemplate")
            b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
            peerButtons[btnIdx] = b
        end
        self:StyleControlButton(b, 150, 28, 12.5)
        b:SetSize(btnW - 2, btnH)
        b:ClearAllPoints()
        b:SetPoint("TOPLEFT", AltRosterChild, "TOPLEFT", 2, -((btnIdx - 1) * btnStep))
        return b
    end

    -- Top button: Return to My Characters & Alts
    local backBtn = AcquirePeerBtn()
    backBtn.peerName = nil
    backBtn:SetText("|cff00ff96← My Characters|r")
    backBtn:UnlockHighlight()
    backBtn:SetScript("OnClick", function()
        MainPanel:Raise()
        MainPanel._state.previewQueueEntry = nil
        MainPanel._state.selectedSyncedPeer = nil
        if ns.NetUI and ns.NetUI.state then
            ns.NetUI.state.inspectedPeerName = nil
        end
        if MainPanel._state.activeViewMode == "VIRTUAL_CHAT" then
            MainPanel._state.activeViewMode = "ARMORY"
            MainPanel:UpdateExteriorTabVisuals()
        end
        MainPanel:RefreshView()
    end)
    backBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:ClearLines()
        GameTooltip:AddLine("Return to My Characters", 0, 1, 0.6)
        GameTooltip:AddLine("Switch the left sidebar back to your own Alts.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    backBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    backBtn:Show()

    if #sortedPeers == 0 then
        local emptyBtn = AcquirePeerBtn()
        emptyBtn.peerName = nil
        emptyBtn:SetText("|cff88ccff+ Sync Players...|r")
        emptyBtn:UnlockHighlight()
        emptyBtn:SetScript("OnClick", function()
            MainPanel:SwitchToTab("SYNCED_ROSTER")
        end)
        emptyBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:ClearLines()
            GameTooltip:AddLine("No Synced Players Yet", 1, 0.82, 0)
            GameTooltip:AddLine("Click to open the Sync Queue & Hub to request a sync with a friendly player!", 1, 1, 1, true)
            GameTooltip:Show()
        end)
        emptyBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        emptyBtn:Show()
    else
        for _, entry in ipairs(sortedPeers) do
            local btn = AcquirePeerBtn()
            local statusDot = entry.isOnline and "|cff00ff00•|r " or "|cff888888•|r "
            btn:SetText(statusDot .. "|cff88ccff" .. entry.name .. "|r")
            btn.peerName = entry.name
            btn.peerData = entry.data
            btn.isOnline = entry.isOnline

            if self._state.selectedSyncedPeer == entry.name then
                btn:LockHighlight()
            else
                btn:UnlockHighlight()
            end

            btn:SetScript("OnClick", function(self, mouseBtn)
                MainPanel:Raise()
                if mouseBtn == "RightButton" and IsShiftKeyDown() then
                    if AltVaultDB and AltVaultDB.GuildNetwork then
                        AltVaultDB.GuildNetwork[self.peerName] = nil
                    end
                    if MainPanel._state.selectedSyncedPeer == self.peerName then
                        MainPanel._state.selectedSyncedPeer = nil
                    end
                    print("|cffffcc00[AltVault]:|r Removed |cffffff00" .. self.peerName .. "|r from Synced Players.")
                    MainPanel:RefreshView()
                    return
                end

                local wasAlreadySelected = (MainPanel._state.selectedSyncedPeer == self.peerName)
                MainPanel._state.previewQueueEntry = nil
                MainPanel._state.selectedSyncedPeer = self.peerName
                if ns.NetUI and ns.NetUI.state then
                    ns.NetUI.state.inspectedPeerName = self.peerName
                end
                MainPanel:UpdateLeftSidebarHighlights()

                if mouseBtn == "RightButton" or (wasAlreadySelected and MainPanel._state.activeViewMode == "VIRTUAL_CHAT") then
                    -- Right-Click (or second Left-Click): Inspect their agreed-upon shared Profile (Armory + Synced Bags/Bank + Professions)
                    MainPanel._state.activeViewMode = "ARMORY"
                    MainPanel:UpdateExteriorTabVisuals()
                    MainPanel:RenderActivePane()
                    return
                end

                -- First Left-Click in Virtual Guild Chat: Select player & ready @Name in chat box!
                if MainPanel._state.activeViewMode == "VIRTUAL_CHAT" then
                    local chatBox = _G.AltVaultVirtualChatEditBox
                    if chatBox and chatBox:IsShown() then
                        local curTxt = chatBox:GetText() or ""
                        local prefix = "@" .. self.peerName .. " "
                        if not string.find(curTxt, prefix, 1, true) then
                            chatBox:SetText(prefix .. curTxt)
                        end
                        chatBox:SetFocus()
                    end
                    MainPanel:ApplyGlobalButtonScaling()
                else
                    MainPanel:RenderActivePane()
                end
            end)

            btn:SetScript("OnEnter", function(self)
                local d = self.peerData or {}
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:ClearLines()
                GameTooltip:AddDoubleLine(
                    "|cff00ccff" .. self.peerName .. "|r",
                    self.isOnline and "|cff00ff00[ONLINE]|r" or "|cffaaaaaa[OFFLINE]|r",
                    1, 0.82, 0, 1, 1, 1
                )
                GameTooltip:AddLine(string.format("Level %d %s %s  •  GS: %d",
                    d.level or 1, d.race or "", d.class or "?", d.gearScore or 0), 1, 1, 1)

                local pList = {}
                for pName, pRank in pairs(d.profs or {}) do
                    table.insert(pList, string.format("%s (%d)", pName, pRank))
                end
                table.sort(pList)
                if #pList > 0 then
                    GameTooltip:AddLine("Professions: |cff00ff96" .. table.concat(pList, ", ") .. "|r", 0.85, 0.85, 0.85)
                end
                GameTooltip:AddLine("Shared Areas: " ..
                    ((d.bagsSynced and "|cff00ff00Bags OK|r" or "|cffffaa00Bags Closed|r") .. " • " ..
                     (d.bankSynced and "|cff00ff00Bank OK|r" or "|cffffaa00Bank Closed|r")), 0.85, 0.85, 0.85)
                GameTooltip:AddLine("Last Synced: |cffffd100" .. (d.lastSeen or "Recently") .. "|r", 0.75, 0.75, 0.75)
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine("|cff00ff00Left-Click:|r Select Player & Message in Virtual Guild Chat", 1, 0.82, 0)
                GameTooltip:AddLine("|cff00ccffRight-Click:|r View Agreed-Upon Profile, Gear, Bags & Bank", 1, 0.82, 0)
                GameTooltip:AddLine("|cffff5555Shift + Right-Click:|r Remove Synced Player", 0.75, 0.75, 0.75)
                GameTooltip:Show()
            end)

            btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
            btn:Show()
        end
    end
end

-- ============================================================================
-- BLOCK HEADING: CHARACTER LIST & FACTION FILTER ENGINE
-- ============================================================================
local hasInitializedLoggedInDefault = false

function MainPanel:RefreshView()
    if ns.DB and ns.DB.SyncCurrentCharacterData then ns.DB.SyncCurrentCharacterData() end
    if not AltVaultDB or not AltVaultDB.Characters then return end

    local loggedInPlayer = UnitName("player")
    local loggedInFaction = UnitFactionGroup and UnitFactionGroup("player")

    if not hasInitializedLoggedInDefault and loggedInPlayer and loggedInPlayer ~= "Unknown" then
        hasInitializedLoggedInDefault = true
        if loggedInFaction == "Alliance" or loggedInFaction == "Horde" then
            self._state.selectedFaction = loggedInFaction
        end
        self._state.selectedCharacter = loggedInPlayer
        self._state.selectedSyncedPeer = nil
    end

    local selectedFaction = self:GetSelectedFaction()

    self:UpdateExteriorTabVisuals()
    for _, btn in ipairs(charButtons) do btn:Hide() end

    local bScale = self:GetButtonScale()
    local leftX = self:GetLeftColumnOffset()
    local btnW = math.max(95, leftX - 42)
    local charH = math.max(18, math.floor(26 * bScale + 0.5))
    local charStep = charH + 4

    -- Sort characters deterministically with the currently logged-in character at #1!
    local factionChars = {}
    for name, data in pairs(AltVaultDB.Characters) do
        local charFaction = data.faction or "Alliance"
        if charFaction == selectedFaction then
            table.insert(factionChars, { name = name, data = data })
        end
    end
    table.sort(factionChars, function(a, b)
        if a.name == loggedInPlayer and b.name ~= loggedInPlayer then return true end
        if b.name == loggedInPlayer and a.name ~= loggedInPlayer then return false end
        return a.name < b.name
    end)

    local index = 1
    local firstChar = nil

    for _, entry in ipairs(factionChars) do
        local name = entry.name
        local data = entry.data
        local charFaction = data.faction or "Alliance"

        local btn = charButtons[index]
        if not btn then
            btn = CreateFrame("Button", "AltVaultCharBtn" .. index, AltRosterChild, "UIPanelButtonTemplate")
            btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
            charButtons[index] = btn
        end
        self:StyleControlButton(btn, 150, 26, 13)
        btn:SetSize(btnW - 2, charH)
        btn:ClearAllPoints()
        btn:SetPoint("TOPLEFT", AltRosterChild, "TOPLEFT", 2, -((index - 1) * charStep))

        local factionPrefix = (charFaction == "Horde") and "|cffff3333[H]|r " or "|cff3399ff[A]|r "
        btn:SetText(factionPrefix .. name)
        btn.charName = name

        btn:SetScript("OnClick", function(self, mouseBtn)
            MainPanel:Raise()
            if mouseBtn == "RightButton" and IsShiftKeyDown() then
                if self.charName ~= UnitName("player") then
                    AltVaultDB.Characters[self.charName] = nil
                    if ns.DB and ns.DB.SaveToBetaMacro then ns.DB.SaveToBetaMacro() end
                    if MainPanel._state.selectedCharacter == self.charName then
                        MainPanel._state.selectedCharacter = nil
                    end
                    MainPanel:RefreshView()
                else
                    print("|cffffcc00[AltVault]:|r Cannot delete the currently logged-in character.")
                end
                return
            end
            MainPanel._state.previewQueueEntry = nil
            MainPanel._state.selectedSyncedPeer = nil
            if ns.NetUI and ns.NetUI.state then
                ns.NetUI.state.inspectedPeerName = nil
            end
            MainPanel._state.selectedCharacter = self.charName
            if MainPanel._state.activeViewMode == "SYNCED_ROSTER" then
                MainPanel._state.activeViewMode = "ARMORY"
                MainPanel:UpdateExteriorTabVisuals()
            end
            MainPanel:RefreshView()
        end)
        btn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine(self.charName, 1, 0.82, 0)
            GameTooltip:AddLine("|cff00ff00Left-Click:|r Open Visual PaperDoll Armory & Bag Boxes", 1, 1, 1)
            if self.charName ~= UnitName("player") then
                GameTooltip:AddLine("|cffff5555Shift + Right-Click:|r Remove Alt from Database", 0.85, 0.85, 0.85)
            end
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

        btn:Show()
        if not firstChar then firstChar = name end
        index = index + 1
    end

    local selChar = self._state.selectedCharacter
    if not selChar or not AltVaultDB.Characters[selChar] or AltVaultDB.Characters[selChar].faction ~= selectedFaction then
        if loggedInPlayer and AltVaultDB.Characters[loggedInPlayer] and AltVaultDB.Characters[loggedInPlayer].faction == selectedFaction then
            self._state.selectedCharacter = loggedInPlayer
        else
            self._state.selectedCharacter = firstChar
        end
    end

    self:RefreshPeerSidebarList()
    self:UpdateLeftSidebarHighlights()
    self:ApplyGlobalButtonScaling(false)
    self:RenderActivePane()
end