-- ============================================================================
-- FILE: UI_NetTab_VirtualChat.lua (MODULE 1 OF 2 SPLIT FROM UI_GuildNetworkTabs.lua)
-- BLOCK HEADING: NETWORK TOP CONTROL BAR, 4-LINE CHAT BOX & SHIFT-CLICK LINKER
-- ============================================================================
local addonName, ns = ...
local MainPanel = _G.AltVaultMainPanel
if not MainPanel or not MainPanel.RegisterExternalTab then return end

local NetUI = ns.NetUI or {}
ns.NetUI = NetUI

local CreateBackdrop = (ns.Compat and ns.Compat.CreateBackdropFrame) or function(fType, fName, parent, extraTpl)
    if _G.BackdropTemplateMixin then
        local tpl = extraTpl and (extraTpl .. ", BackdropTemplate") or "BackdropTemplate"
        local ok, f = pcall(CreateFrame, fType, fName, parent, tpl)
        if ok and f then return f end
    end
    return CreateFrame(fType or "Frame", fName, parent, extraTpl)
end

local STANDARD_FONT = "Fonts\\FRIZQT__.TTF"

NetUI.state = {
    selectedRecipeForMats = nil,
    matSearchFilterText = "",
    activeConsCategory = "ALL", -- "ALL", "Potion", "Elixir / Flask", "Scroll", "Food & Drink", "Bandage"
    inspectedPeerName = nil,
}

-- Smart Contact Helper:
-- 1) If the Mailbox is open, automatically switches to Send Mail and fills in "To:" & "Subject:"!
-- 2) Otherwise, opens a pre-filled whisper in the chat box.
local function ContactOrMailSyncedPlayer(targetName, itemLinkOrName, isSendingGift)
    if not targetName or targetName == "" or targetName == UnitName("player") then return end

    if MailFrame and MailFrame:IsShown() and SendMailNameEditBox then
        if MailFrameTab_OnClick then
            pcall(MailFrameTab_OnClick, nil, 2)
        elseif MailFrameTab2 and MailFrameTab2:GetScript("OnClick") then
            pcall(MailFrameTab2:GetScript("OnClick"), MailFrameTab2)
        end
        SendMailNameEditBox:SetText(targetName)
        if SendMailSubjectEditBox and itemLinkOrName then
            local cleanItem = string.gsub(itemLinkOrName, "|c%x%x%x%x%x%x%x%x", "")
            cleanItem = string.gsub(cleanItem, "|H.-|h", "")
            cleanItem = string.gsub(cleanItem, "|h|r", "")
            SendMailSubjectEditBox:SetText("AltVault: " .. cleanItem)
        end
        print(string.format("|cff00ff00[AltVault Mail Helper]:|r Pre-filled Send Mail recipient to |cffffff00%s|r!", targetName))
        return
    end

    local msg
    if isSendingGift then
        msg = string.format("/w %s Hey %s! AltVault shows you could use %s — I can craft/mail it to you!",
            targetName, targetName, itemLinkOrName or "an upgrade")
    else
        msg = string.format("/w %s Hey %s! AltVault shows you have %s — could I grab some when you have a moment?",
            targetName, targetName, itemLinkOrName or "those mats")
    end

    if ChatFrame_OpenChat then
        ChatFrame_OpenChat(msg)
    elseif DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.editBox then
        DEFAULT_CHAT_FRAME.editBox:Show()
        DEFAULT_CHAT_FRAME.editBox:SetFocus()
        DEFAULT_CHAT_FRAME.editBox:SetText(msg)
    end
end

-- Opens Blizzard's standard clickable Item Popup Window (ItemRefTooltip) when clicking an item link in Tab 11!
local function OpenItemLinkPopupWindow(fullItemLink)
    if not fullItemLink then return end
    if IsModifiedClick() and HandleModifiedItemClick then
        HandleModifiedItemClick(fullItemLink)
        return
    end
    local linkPayload = string.match(fullItemLink, "|H(item:[^|]+)|h")
        or string.match(fullItemLink, "(item:[%d:%-]+)")
    if linkPayload and SetItemRef then
        pcall(SetItemRef, linkPayload, fullItemLink, "LeftButton")
    elseif ItemRefTooltip then
        ShowUIPanel(ItemRefTooltip)
        if not ItemRefTooltip:IsShown() then
            ItemRefTooltip:SetOwner(UIParent, "ANCHOR_PRESERVE")
        end
        pcall(ItemRefTooltip.SetHyperlink, ItemRefTooltip, linkPayload or fullItemLink)
    end
end

NetUI.ContactOrMailSyncedPlayer = ContactOrMailSyncedPlayer
NetUI.OpenItemLinkPopupWindow = OpenItemLinkPopupWindow

MainPanel.OnSelectSyncedPeerFromSidebar = function(peerName)
    NetUI.state.inspectedPeerName = peerName
    if MainPanel.SetSelectedSyncedPeer then
        MainPanel:SetSelectedSyncedPeer(peerName)
    end
    MainPanel:SwitchToTab("SYNCED_ROSTER")
end

-- ============================================================================
-- BLOCK HEADING: TALL TOP CONTROL BAR FOR TABS 7, 8, 9, 10 & 11 (AUTO-FITTING)
-- ============================================================================
local NetHeader = CreateBackdrop("Frame", nil, MainPanel)
NetHeader:SetPoint("TOPLEFT", MainPanel, "TOPLEFT", 215, -96)
NetHeader:SetPoint("TOPRIGHT", MainPanel, "TOPRIGHT", -28, -96)
NetHeader:SetHeight(56)
if NetHeader.SetBackdrop then
    NetHeader:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    NetHeader:SetBackdropColor(0.05, 0.08, 0.12, 0.94)
    NetHeader:SetBackdropBorderColor(0.4, 0.6, 0.9, 0.85)
end
NetHeader:Hide()

local NetRow1 = CreateFrame("Frame", nil, NetHeader)
NetRow1:SetPoint("TOPLEFT", NetHeader, "TOPLEFT", 6, -6)
NetRow1:SetPoint("TOPRIGHT", NetHeader, "TOPRIGHT", -6, -6)
NetRow1:SetHeight(28)

local NetRow2 = CreateFrame("Frame", nil, NetHeader)
NetRow2:SetPoint("TOPLEFT", NetRow1, "BOTTOMLEFT", 0, -5)
NetRow2:SetPoint("TOPRIGHT", NetRow1, "BOTTOMRIGHT", 0, -5)
NetRow2:SetHeight(28)
NetRow2:Hide()

local SyncBtn = CreateFrame("Button", nil, NetRow1, "UIPanelButtonTemplate")
SyncBtn:SetSize(130, 26)
SyncBtn:SetPoint("LEFT", NetRow1, "LEFT", 4, 0)
SyncBtn:SetText("|cff00ccffSync Queue Hub|r")
SyncBtn:SetScript("OnClick", function()
    NetUI.state.inspectedPeerName = nil
    MainPanel._state.previewQueueEntry = nil
    if MainPanel.SetSelectedSyncedPeer then
        MainPanel:SetSelectedSyncedPeer(nil)
    end
    MainPanel:SwitchToTab("SYNCED_ROSTER")
end)

-- Direct Player Whisper Sync Controls (For Tab 7 & Tab 10)
local WhisperTargetBox = CreateFrame("EditBox", "AltVaultWhisperSyncBox", NetRow1, "InputBoxTemplate")
WhisperTargetBox:SetSize(150, 26)
WhisperTargetBox:SetPoint("LEFT", SyncBtn, "RIGHT", 8, 0)
WhisperTargetBox:SetAutoFocus(false)
WhisperTargetBox:SetText("")
WhisperTargetBox:Hide()

local WhisperPlaceholder = WhisperTargetBox:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
WhisperPlaceholder:SetPoint("LEFT", WhisperTargetBox, "LEFT", 6, 0)
WhisperPlaceholder:SetPoint("RIGHT", WhisperTargetBox, "RIGHT", -6, 0)
WhisperPlaceholder:SetJustifyH("LEFT")
WhisperPlaceholder:SetWordWrap(false)
WhisperPlaceholder:SetText("Player Name...")

WhisperTargetBox:SetScript("OnEditFocusGained", function() WhisperPlaceholder:Hide() end)
WhisperTargetBox:SetScript("OnEditFocusLost", function(self)
    if self:GetText() == "" then WhisperPlaceholder:Show() end
end)

local function ExecuteWhisperSync()
    local target = WhisperTargetBox:GetText() or ""
    target = string.gsub(target, "^%s*(.-)%s*$", "%1")
    if target == "" then
        print("|cffffcc00[AltVault]:|r Type a player's name in the box first (or click [Request Target] while targeting a player).")
        return
    end
    if ns.GuildNet and ns.GuildNet.RequestDirectWhisperSync then
        ns.GuildNet.RequestDirectWhisperSync(target)
    end
end

WhisperTargetBox:SetScript("OnEnterPressed", function(self)
    self:ClearFocus()
    ExecuteWhisperSync()
end)

local WhisperSyncBtn = CreateFrame("Button", nil, NetRow1, "UIPanelButtonTemplate")
WhisperSyncBtn:SetSize(124, 26)
WhisperSyncBtn:SetPoint("LEFT", WhisperTargetBox, "RIGHT", 6, 0)
WhisperSyncBtn:SetText("|cff00ff00Request Sync|r")
WhisperSyncBtn:Hide()
WhisperSyncBtn:SetScript("OnClick", function()
    WhisperTargetBox:ClearFocus()
    ExecuteWhisperSync()
end)

local SyncTargetBtn = CreateFrame("Button", nil, NetRow1, "UIPanelButtonTemplate")
SyncTargetBtn:SetSize(128, 26)
SyncTargetBtn:SetPoint("LEFT", WhisperSyncBtn, "RIGHT", 6, 0)
SyncTargetBtn:SetText("Request Target")
SyncTargetBtn:Hide()
SyncTargetBtn:SetScript("OnClick", function()
    if UnitExists("target") and UnitIsPlayer("target") then
        local tName = UnitName("target")
        if tName and ns.GuildNet and ns.GuildNet.RequestDirectWhisperSync then
            WhisperTargetBox:SetText(tName)
            WhisperPlaceholder:Hide()
            ns.GuildNet.RequestDirectWhisperSync(tName)
        end
    else
        print("|cffffcc00[AltVault]:|r Target a friendly player in-game first, or type their name into the box!")
    end
end)

-- Row 2 Privacy & DND Toggles (For Sync Queue & Hub)
local DndToggleBtn = CreateFrame("Button", nil, NetRow2, "UIPanelButtonTemplate")
DndToggleBtn:SetSize(195, 26)
DndToggleBtn:SetPoint("LEFT", NetRow2, "LEFT", 4, 0)
DndToggleBtn:SetScript("OnClick", function()
    if not AltVaultDB then return end
    AltVaultDB.SyncDND = not AltVaultDB.SyncDND
    if AltVaultDB.SyncDND then
        print("|cffff4444[AltVault Sync DND]:|r Ignore Syncs is now |cffff4444ON|r — incoming sync requests are automatically blocked while you are busy.")
    else
        print("|cff00ff00[AltVault Sync DND]:|r Ignore Syncs is now |cff00ff00OFF|r — incoming sync requests will enter your Sync Queue.")
    end
    MainPanel:RenderActivePane()
end)

local FoFToggleBtn = CreateFrame("Button", nil, NetRow2, "UIPanelButtonTemplate")
FoFToggleBtn:SetSize(225, 26)
FoFToggleBtn:SetPoint("LEFT", DndToggleBtn, "RIGHT", 6, 0)
FoFToggleBtn:SetScript("OnClick", function()
    if not AltVaultDB then return end
    AltVaultDB.BlockFriendsOfFriends = not AltVaultDB.BlockFriendsOfFriends
    if AltVaultDB.BlockFriendsOfFriends then
        print("|cffffaa00[AltVault Privacy]:|r Block Friends-of-Friends is |cffffaa00ON|r — your name will be hidden when others share their Virtual Guild list.")
    else
        print("|cff00ff00[AltVault Privacy]:|r Block Friends-of-Friends is |cff00ff00OFF|r — synced friends may include you in Virtual Guild list syncs.")
    end
    MainPanel:RenderActivePane()
end)

local ClearQueueBtn = CreateFrame("Button", nil, NetRow2, "UIPanelButtonTemplate")
ClearQueueBtn:SetSize(126, 26)
ClearQueueBtn:SetPoint("LEFT", FoFToggleBtn, "RIGHT", 6, 0)
ClearQueueBtn:SetText("Clear Waitlist")
ClearQueueBtn:SetScript("OnClick", function()
    if AltVaultDB then
        AltVaultDB.SyncQueue = {}
        AltVaultDB.IgnoredSyncPlayers = {}
    end
    MainPanel._state.previewQueueEntry = nil
    print("|cffffcc00[AltVault Sync Queue]:|r Cleared all pending Sync Queue waitlist items and reset ignored sync list.")
    MainPanel:RenderActivePane()
end)

-- Mat Search Controls (For Tab 8)
local ClearRecipeFilterBtn = CreateFrame("Button", nil, NetRow1, "UIPanelButtonTemplate")
ClearRecipeFilterBtn:SetSize(128, 26)
ClearRecipeFilterBtn:SetPoint("LEFT", SyncBtn, "RIGHT", 6, 0)
ClearRecipeFilterBtn:SetText("Show All Mats")
ClearRecipeFilterBtn:Hide()
ClearRecipeFilterBtn:SetScript("OnClick", function()
    NetUI.state.selectedRecipeForMats = nil
    MainPanel:RenderActivePane()
end)

local MatSearchBox = CreateFrame("EditBox", "AltVaultGuildMatSearchBox", NetRow1, "InputBoxTemplate")
MatSearchBox:SetSize(170, 26)
MatSearchBox:SetPoint("LEFT", ClearRecipeFilterBtn, "RIGHT", 8, 0)
MatSearchBox:SetAutoFocus(false)
MatSearchBox:SetText("")
MatSearchBox:Hide()

local MatPlaceholder = MatSearchBox:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
MatPlaceholder:SetPoint("LEFT", MatSearchBox, "LEFT", 6, 0)
MatPlaceholder:SetPoint("RIGHT", MatSearchBox, "RIGHT", -6, 0)
MatPlaceholder:SetJustifyH("LEFT")
MatPlaceholder:SetWordWrap(false)
MatPlaceholder:SetText("Filter Mat Name...")

MatSearchBox:SetScript("OnEditFocusGained", function() MatPlaceholder:Hide() end)
MatSearchBox:SetScript("OnEditFocusLost", function(self)
    if self:GetText() == "" then MatPlaceholder:Show() end
end)
MatSearchBox:SetScript("OnEnterPressed", function(self)
    self:ClearFocus()
    NetUI.state.matSearchFilterText = string.gsub(self:GetText() or "", "^%s*(.-)%s*$", "%1")
    NetUI.state.selectedRecipeForMats = nil
    MainPanel:RenderActivePane()
end)

local MatFilterBtn = CreateFrame("Button", nil, NetRow1, "UIPanelButtonTemplate")
MatFilterBtn:SetSize(80, 26)
MatFilterBtn:SetPoint("LEFT", MatSearchBox, "RIGHT", 6, 0)
MatFilterBtn:SetText("Filter")
MatFilterBtn:Hide()
MatFilterBtn:SetScript("OnClick", function()
    MatSearchBox:ClearFocus()
    NetUI.state.matSearchFilterText = string.gsub(MatSearchBox:GetText() or "", "^%s*(.-)%s*$", "%1")
    NetUI.state.selectedRecipeForMats = nil
    MainPanel:RenderActivePane()
end)

-- Consumable Category Filter Buttons (For Tab 9)
local CONS_FILTERS = {
    { id = "ALL",            label = "All",        baseW = 58 },
    { id = "Potion",         label = "Potions",    baseW = 76 },
    { id = "Elixir / Flask", label = "Elixirs",    baseW = 74 },
    { id = "Scroll",         label = "Scrolls",    baseW = 74 },
    { id = "Food & Drink",   label = "Food/Drink", baseW = 92 },
    { id = "Bandage",        label = "Bandages",   baseW = 82 },
}
local consFilterBtns = {}
for i, cfg in ipairs(CONS_FILTERS) do
    local b = CreateFrame("Button", nil, NetRow1, "UIPanelButtonTemplate")
    b:SetSize(cfg.baseW, 26)
    b.baseW = cfg.baseW
    if i == 1 then
        b:SetPoint("LEFT", SyncBtn, "RIGHT", 6, 0)
    else
        b:SetPoint("LEFT", consFilterBtns[i - 1], "RIGHT", 4, 0)
    end
    b:SetText(cfg.label)
    b.catID = cfg.id
    b:SetScript("OnClick", function(self)
        NetUI.state.activeConsCategory = self.catID
        MainPanel:RenderActivePane()
    end)
    b:Hide()
    table.insert(consFilterBtns, b)
end

-- ============================================================================
-- BLOCK HEADING: 4-LINE MULTI-LINE CHAT PROMPT BOX WITH SCROLLBAR (TAB 11)
-- ============================================================================
local ChatInputContainer = CreateBackdrop("Frame", "AltVaultVirtualChatBoxContainer", NetRow1)
ChatInputContainer:SetSize(275, 72)
ChatInputContainer:SetPoint("LEFT", SyncBtn, "RIGHT", 8, 0)
if ChatInputContainer.SetBackdrop then
    ChatInputContainer:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    ChatInputContainer:SetBackdropColor(0.02, 0.03, 0.05, 0.95)
    ChatInputContainer:SetBackdropBorderColor(0.55, 0.65, 0.80, 0.90)
end
ChatInputContainer:EnableMouse(true)
ChatInputContainer:Hide()

local ChatInputScroll = CreateFrame("ScrollFrame", "AltVaultVirtualChatInputScroll", ChatInputContainer, "UIPanelScrollFrameTemplate")
ChatInputScroll:SetPoint("TOPLEFT", ChatInputContainer, "TOPLEFT", 6, -6)
ChatInputScroll:SetPoint("BOTTOMRIGHT", ChatInputContainer, "BOTTOMRIGHT", -26, 6)

local ChatInputBox = CreateFrame("EditBox", "AltVaultVirtualChatEditBox", ChatInputScroll)
ChatInputBox:SetMultiLine(true)
ChatInputBox:SetAutoFocus(false)
ChatInputBox:SetMaxLetters(200)
ChatInputBox:SetWidth(240)
ChatInputBox:SetFont(STANDARD_FONT, 14, "")
ChatInputBox:SetTextColor(1, 0.96, 0.41, 1)
ChatInputBox:SetTextInsets(2, 2, 2, 2)
ChatInputBox:SetText("")
ChatInputScroll:SetScrollChild(ChatInputBox)

ChatInputContainer:SetScript("OnMouseDown", function()
    ChatInputBox:SetFocus()
end)
ChatInputScroll:SetScript("OnMouseDown", function()
    ChatInputBox:SetFocus()
end)

local ChatPlaceholder = ChatInputContainer:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
ChatPlaceholder:SetPoint("TOPLEFT", ChatInputContainer, "TOPLEFT", 8, -8)
ChatPlaceholder:SetPoint("BOTTOMRIGHT", ChatInputContainer, "BOTTOMRIGHT", -28, 8)
ChatPlaceholder:SetJustifyH("LEFT")
ChatPlaceholder:SetJustifyV("TOP")
ChatPlaceholder:SetWordWrap(true)
ChatPlaceholder:SetText("Type a message to your Virtual Guild (Press Enter or click Send • Shift-Click items to link)...")

ChatInputBox:SetScript("OnEditFocusGained", function(self)
    ChatPlaceholder:Hide()
end)

ChatInputBox:SetScript("OnEditFocusLost", function(self)
    if (self:GetText() or "") == "" then
        ChatPlaceholder:Show()
    end
end)

ChatInputBox:SetScript("OnEscapePressed", function(self)
    self:ClearFocus()
    if (self:GetText() or "") == "" then
        ChatPlaceholder:Show()
    end
end)

ChatInputBox:SetScript("OnTextChanged", function(self, userInput)
    if (self:GetText() or "") ~= "" then
        ChatPlaceholder:Hide()
    elseif not self:HasFocus() then
        ChatPlaceholder:Show()
    end
    if ScrollingEdit_OnTextChanged then
        pcall(ScrollingEdit_OnTextChanged, self, ChatInputScroll)
    else
        ChatInputScroll:UpdateScrollChildRect()
        local sb = ChatInputScroll.ScrollBar or _G["AltVaultVirtualChatInputScrollScrollBar"]
        if sb and sb.GetMinMaxValues then
            local _, maxVal = sb:GetMinMaxValues()
            if maxVal and maxVal > 0 and userInput then
                ChatInputScroll:SetVerticalScroll(maxVal)
            end
        end
    end
end)

ChatInputBox:SetScript("OnCursorChanged", function(self, x, y, w, h)
    if ScrollingEdit_OnCursorChanged then
        pcall(ScrollingEdit_OnCursorChanged, self, x, y, w, h)
    end
end)

ChatInputBox:SetScript("OnUpdate", function(self, elapsed)
    if ScrollingEdit_OnUpdate then
        pcall(ScrollingEdit_OnUpdate, self, elapsed, ChatInputScroll)
    end
end)

local function SendCurrentVirtualChat()
    local text = ChatInputBox:GetText() or ""
    text = string.gsub(text, "[\r\n]+", " ")
    text = string.gsub(text, "^%s*(.-)%s*$", "%1")
    if text == "" then return end

    if AltVaultDB and not AltVaultDB.EchoUserConfigured then
        AltVaultDB.EchoVirtualChat = false
    end

    ChatInputBox:SetText("")
    ChatInputScroll:SetVerticalScroll(0)
    if not ChatInputBox:HasFocus() then ChatPlaceholder:Show() end
    if ns.GuildNet and ns.GuildNet.SendVirtualChatMessage then
        ns.GuildNet.SendVirtualChatMessage(text)
    end
end

ChatInputBox:SetScript("OnEnterPressed", function(self)
    SendCurrentVirtualChat()
    self:ClearFocus()
    ChatPlaceholder:Show()
end)

-- ============================================================================
-- BLOCK HEADING: SINGLE-INSERT SHIFT-CLICK ITEM LINK INTERCEPTOR
-- ============================================================================
local lastInsertedLink = nil
local lastInsertedTime = 0

local function InsertSingleLinkIntoVirtualChat(link)
    if not link or not ChatInputContainer:IsShown() then return false end
    local isChatTabActive = (MainPanel:IsShown() and MainPanel.GetActiveViewMode and MainPanel:GetActiveViewMode() == "VIRTUAL_CHAT")
    if not ChatInputBox:HasFocus() and not isChatTabActive then return false end

    local now = GetTime()
    if link == lastInsertedLink and (now - lastInsertedTime) < 0.40 then
        return true
    end
    lastInsertedLink = link
    lastInsertedTime = now

    ChatPlaceholder:Hide()
    ChatInputBox:SetFocus()
    ChatInputBox:Insert(link)

    if _G.StackSplitFrame and _G.StackSplitFrame:IsShown() then
        _G.StackSplitFrame:Hide()
    end
    if _G.StackSplitCancelButton_OnClick then
        pcall(_G.StackSplitCancelButton_OnClick)
    end
    return true
end

local function ExtractLinkFromBagButton(btn)
    if type(btn) ~= "table" then return nil end
    local bagID = (btn.GetBankTabID and btn:GetBankTabID())
        or btn.bankTabID
        or (btn.GetBagID and btn:GetBagID())
        or btn.bagID
        or (btn:GetParent() and btn:GetParent().GetID and btn:GetParent():GetID())
    local slotID = (btn.GetContainerSlotID and btn:GetContainerSlotID())
        or btn.containerSlotID
        or (btn.GetSlotIndex and btn:GetSlotIndex())
        or btn.slotIndex
        or (btn.GetID and btn:GetID())

    if bagID ~= nil and slotID ~= nil then
        if C_Container and C_Container.GetContainerItemInfo then
            local info = C_Container.GetContainerItemInfo(bagID, slotID)
            if info and info.hyperlink then return info.hyperlink end
        end
        if GetContainerItemLink then
            local link = GetContainerItemLink(bagID, slotID)
            if link then return link end
        end
    end
    if type(btn.itemLocation) == "table" and C_Item and C_Item.GetItemLink then
        local ok, link = pcall(C_Item.GetItemLink, btn.itemLocation)
        if ok and link then return link end
    end
    return nil
end

if _G.ChatEdit_InsertLink then
    hooksecurefunc("ChatEdit_InsertLink", function(link)
        if link and ChatInputContainer:IsShown() then
            InsertSingleLinkIntoVirtualChat(link)
        end
    end)
end

if _G.HandleModifiedItemClick then
    hooksecurefunc("HandleModifiedItemClick", function(link)
        if link and IsShiftKeyDown() and ChatInputContainer:IsShown() then
            InsertSingleLinkIntoVirtualChat(link)
        end
    end)
end

if _G.StackSplitFrame and _G.StackSplitFrame.HookScript then
    pcall(_G.StackSplitFrame.HookScript, _G.StackSplitFrame, "OnShow", function(splitFrame)
        local isChatTabActive = (MainPanel:IsShown() and MainPanel.GetActiveViewMode and MainPanel:GetActiveViewMode() == "VIRTUAL_CHAT")
        if ChatInputContainer:IsShown() and (ChatInputBox:HasFocus() or isChatTabActive) then
            local owner = splitFrame.owner
            local link = owner and ExtractLinkFromBagButton(owner)
            if not link and GameTooltip and GameTooltip.GetItem then
                _, link = GameTooltip:GetItem()
            end
            if link then
                InsertSingleLinkIntoVirtualChat(link)
                splitFrame:Hide()
            end
        end
    end)
end

local ChatSendBtn = CreateFrame("Button", nil, NetRow1, "UIPanelButtonTemplate")
ChatSendBtn:SetSize(64, 28)
ChatSendBtn:SetPoint("LEFT", ChatInputContainer, "RIGHT", 6, 0)
ChatSendBtn:SetText("Send")
ChatSendBtn:Hide()
ChatSendBtn:SetScript("OnClick", function()
    SendCurrentVirtualChat()
    ChatInputBox:ClearFocus()
    ChatPlaceholder:Show()
end)

local ChatEchoBtn = CreateFrame("Button", nil, NetRow1, "UIPanelButtonTemplate")
ChatEchoBtn:SetSize(92, 28)
ChatEchoBtn:SetPoint("LEFT", ChatSendBtn, "RIGHT", 5, 0)
ChatEchoBtn:SetText("|cff888888Echo: OFF|r")
ChatEchoBtn:Hide()
ChatEchoBtn:SetScript("OnClick", function(self)
    if not AltVaultDB then return end
    AltVaultDB.EchoUserConfigured = true
    AltVaultDB.EchoVirtualChat = not AltVaultDB.EchoVirtualChat
    self:SetText(AltVaultDB.EchoVirtualChat and "|cff00ff00Echo: ON|r" or "|cff888888Echo: OFF|r")
end)

local ChatClearBtn = CreateFrame("Button", nil, NetRow1, "UIPanelButtonTemplate")
ChatClearBtn:SetSize(62, 28)
ChatClearBtn:SetPoint("LEFT", ChatEchoBtn, "RIGHT", 5, 0)
ChatClearBtn:SetText("Clear")
ChatClearBtn:Hide()
ChatClearBtn:SetScript("OnClick", function()
    if AltVaultDB then AltVaultDB.VirtualChatHistory = {} end
    MainPanel:RenderActivePane()
end)

-- ============================================================================
-- BLOCK HEADING: HEADER SCALING & TAB 11 VIRTUAL GUILD CHAT RENDERER
-- ============================================================================
local function GetNetHeaderHeightForMode(mode, bScale)
    local effScale = math.min(1.30, math.max(0.85, bScale or 1.12))
    if mode == "VIRTUAL_CHAT" then
        return math.max(72, math.floor(94 * effScale + 0.5))
    elseif mode == "SYNCED_ROSTER" then
        return math.max(74, math.floor(84 * effScale + 0.5))
    end
    return math.max(46, math.floor(54 * effScale + 0.5))
end

MainPanel.OnApplyExternalScaling = function(panel, bScale, leftX, baseTopY)
    local activeMode = (panel.GetActiveViewMode and panel:GetActiveViewMode()) or "ARMORY"
    local netHeaderH = GetNetHeaderHeightForMode(activeMode, bScale)

    NetHeader:ClearAllPoints()
    NetHeader:SetPoint("TOPLEFT", panel, "TOPLEFT", leftX, baseTopY)
    NetHeader:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -28, baseTopY)
    NetHeader:SetHeight(netHeaderH)

    local rowH = math.max(26, math.floor(30 * math.min(1.22, bScale) + 0.5))
    NetRow1:ClearAllPoints()
    NetRow1:SetPoint("TOPLEFT", NetHeader, "TOPLEFT", 6, -6)
    NetRow1:SetPoint("TOPRIGHT", NetHeader, "TOPRIGHT", -6, -6)
    NetRow1:SetHeight(rowH)

    NetRow2:ClearAllPoints()
    NetRow2:SetPoint("TOPLEFT", NetRow1, "BOTTOMLEFT", 0, -5)
    NetRow2:SetPoint("TOPRIGHT", NetRow1, "BOTTOMRIGHT", 0, -5)
    NetRow2:SetHeight(rowH)

    if not panel.FitControlsRowInsideBar then return end

    if activeMode == "GUILD_MATS" then
        panel:FitControlsRowInsideBar(NetRow1, 4, 4, 6, {
            { frame = SyncBtn,              baseW = 140, baseH = 29, font = 12.5 },
            { frame = ClearRecipeFilterBtn, baseW = 138, baseH = 29, font = 12.5 },
            { frame = MatSearchBox,         isEditBox = true, placeholder = MatPlaceholder, baseW = 192, baseH = 29, font = 12.5 },
            { frame = MatFilterBtn,         baseW = 86,  baseH = 29, font = 12.5 },
        })
    elseif activeMode == "GUILD_CONS" then
        local consSpecs = {
            { frame = SyncBtn, baseW = 136, baseH = 29, font = 12.5 }
        }
        for _, b in ipairs(consFilterBtns) do
            table.insert(consSpecs, { frame = b, baseW = math.floor((b.baseW or 72) * 1.10), baseH = 29, font = 12.5 })
        end
        panel:FitControlsRowInsideBar(NetRow1, 4, 4, 5, consSpecs)
    elseif activeMode == "VIRTUAL_CHAT" then
        local chatBoxH = math.max(54, netHeaderH - 14)
        NetRow1:SetHeight(chatBoxH)
        local rowScale = panel:FitControlsRowInsideBar(NetRow1, 4, 4, 6, {
            { frame = SyncBtn,            baseW = 134, baseH = 30, font = 12.5 },
            { frame = ChatInputContainer, isCustomContainer = true, baseW = 300, baseH = chatBoxH },
            { frame = ChatSendBtn,        baseW = 75,  baseH = 30, font = 12.5 },
            { frame = ChatEchoBtn,        baseW = 105, baseH = 30, font = 12.5 },
            { frame = ChatClearBtn,       baseW = 75,  baseH = 30, font = 12.5 },
        })
        ChatInputContainer:SetHeight(chatBoxH)
        local actualBoxW = ChatInputContainer:GetWidth() or 240
        local chatFont = math.max(10, math.floor(12.5 * math.min(1.22, rowScale or bScale) + 0.5))
        ChatInputBox:SetWidth(math.max(110, actualBoxW - 34))
        ChatInputBox:SetFont(STANDARD_FONT, chatFont, "")
        ChatPlaceholder:SetFont(STANDARD_FONT, math.max(9, chatFont - 1), "")
    elseif activeMode == "SYNCED_ROSTER" then
        panel:FitControlsRowInsideBar(NetRow1, 4, 4, 6, {
            { frame = SyncBtn,          baseW = 148, baseH = 29, font = 12.5 },
            { frame = WhisperTargetBox, isEditBox = true, placeholder = WhisperPlaceholder, baseW = 180, baseH = 29, font = 12.5 },
            { frame = WhisperSyncBtn,   baseW = 145, baseH = 29, font = 12.5 },
            { frame = SyncTargetBtn,    baseW = 150, baseH = 29, font = 12.5 },
        })
        panel:FitControlsRowInsideBar(NetRow2, 4, 4, 6, {
            { frame = DndToggleBtn,   baseW = 225, baseH = 29, font = 12.5 },
            { frame = FoFToggleBtn,   baseW = 264, baseH = 29, font = 12.5 },
            { frame = ClearQueueBtn,  baseW = 140, baseH = 29, font = 12.5 },
        })
    else
        panel:FitControlsRowInsideBar(NetRow1, 4, 4, 6, {
            { frame = SyncBtn,          baseW = 148, baseH = 29, font = 12.5 },
            { frame = WhisperTargetBox, isEditBox = true, placeholder = WhisperPlaceholder, baseW = 180, baseH = 29, font = 12.5 },
            { frame = WhisperSyncBtn,   baseW = 145, baseH = 29, font = 12.5 },
            { frame = SyncTargetBtn,    baseW = 150, baseH = 29, font = 12.5 },
        })
    end
end

local function HideAllHeaderSubControls()
    WhisperTargetBox:Hide()
    WhisperSyncBtn:Hide()
    SyncTargetBtn:Hide()
    ClearRecipeFilterBtn:Hide()
    MatSearchBox:Hide()
    MatFilterBtn:Hide()
    ChatInputContainer:Hide()
    ChatSendBtn:Hide()
    ChatEchoBtn:Hide()
    ChatClearBtn:Hide()
    NetRow2:Hide()
    for _, b in ipairs(consFilterBtns) do b:Hide() end
end

local function ConfigureHeaderForMode(mode)
    if mode ~= "GUILD_GEAR" and mode ~= "GUILD_MATS" and mode ~= "GUILD_CONS" and mode ~= "SYNCED_ROSTER" and mode ~= "VIRTUAL_CHAT" then
        NetHeader:Hide()
        return
    end

    if AltVaultDB and not AltVaultDB.EchoUserConfigured then
        AltVaultDB.EchoVirtualChat = false
    end

    local qCount = (AltVaultDB and AltVaultDB.SyncQueue and #AltVaultDB.SyncQueue) or 0
    if qCount > 0 then
        SyncBtn:SetText(string.format("|cff00ff00Sync Queue (%d)|r", qCount))
    else
        SyncBtn:SetText("|cff00ccffSync Queue Hub|r")
    end

    local bScale = (MainPanel.GetButtonScale and MainPanel:GetButtonScale()) or 1.15
    local leftX = (MainPanel.GetLeftColumnOffset and MainPanel:GetLeftColumnOffset()) or 215
    local baseTopY = (MainPanel.GetBaseContentTopY and MainPanel:GetBaseContentTopY()) or -96
    local netHeaderH = GetNetHeaderHeightForMode(mode, bScale)

    NetHeader:SetHeight(netHeaderH)
    NetHeader:Show()
    MainPanel:SetScrollTopOffset(baseTopY - netHeaderH - 6)
    HideAllHeaderSubControls()

    if mode == "GUILD_MATS" then
        ClearRecipeFilterBtn:Show()
        MatSearchBox:Show()
        MatFilterBtn:Show()
    elseif mode == "GUILD_CONS" then
        for _, b in ipairs(consFilterBtns) do
            b:Show()
            if b.catID == NetUI.state.activeConsCategory then b:LockHighlight() else b:UnlockHighlight() end
        end
    elseif mode == "VIRTUAL_CHAT" then
        ChatInputContainer:Show()
        ChatSendBtn:Show()
        ChatEchoBtn:Show()
        ChatEchoBtn:SetText((AltVaultDB and AltVaultDB.EchoVirtualChat == true) and "|cff00ff00Echo: ON|r" or "|cff888888Echo: OFF|r")
        ChatClearBtn:Show()
    elseif mode == "SYNCED_ROSTER" then
        WhisperTargetBox:Show()
        WhisperSyncBtn:Show()
        SyncTargetBtn:Show()
        NetRow2:Show()
        local isDND = (AltVaultDB and AltVaultDB.SyncDND) == true
        local isFoF = (AltVaultDB and AltVaultDB.BlockFriendsOfFriends) == true
        DndToggleBtn:SetText(isDND and "|cffff4444DND (Ignore Syncs): ON|r" or "|cff00ff00DND (Ignore Syncs): OFF|r")
        FoFToggleBtn:SetText(isFoF and "|cffffaa00Block Friends-of-Friends: ON|r" or "|cff00ff96Block Friends-of-Friends: OFF|r")
    else
        WhisperTargetBox:Show()
        WhisperSyncBtn:Show()
        SyncTargetBtn:Show()
    end

    if MainPanel.OnApplyExternalScaling then
        MainPanel.OnApplyExternalScaling(MainPanel, bScale, leftX, baseTopY)
    end
end

NetUI.ConfigureHeaderForMode = ConfigureHeaderForMode

MainPanel.OnBeforeRenderActivePane = function(self, mode)
    ConfigureHeaderForMode(mode)
    if mode ~= "PHOTO_ALBUM" then
        if NetUI.HidePhotoAlbumFrames then NetUI.HidePhotoAlbumFrames() end
        if NetUI.PhotoEditFlyout then NetUI.PhotoEditFlyout:Hide() end
    end
end

local function RenderVirtualGuildChatTab(panel)
    ConfigureHeaderForMode("VIRTUAL_CHAT")
    local faction = panel:GetSelectedFaction()
    local rows = {}

    local onlineNames = {}
    local totalPeers = 0
    for peerName, pData in pairs((AltVaultDB and AltVaultDB.GuildNetwork) or {}) do
        if type(pData) == "table" and pData.explicitlyApprovedSync == true and not (AltVaultDB.Characters and AltVaultDB.Characters[peerName]) then
            if not pData.faction or pData.faction == faction then
                totalPeers = totalPeers + 1
                if ns.GuildNet and ns.GuildNet.IsPeerOnline and ns.GuildNet.IsPeerOnline(peerName) then
                    table.insert(onlineNames, "|cff00ff00" .. peerName .. "|r")
                end
            end
        end
    end
    table.sort(onlineNames)
    local onlineSummary = (#onlineNames > 0) and table.concat(onlineNames, ", ") or "|cff888888None Currently Active (Click 'Sync All Net' to ping)|r"

    table.insert(rows, {
        tint = "SPEC_HEADER",
        text = string.format("|cffffd100Virtual Guild Chatroom (%s) — %d Online / %d Locked-In Peers|r",
            faction, #onlineNames, totalPeers)
    })
    table.insert(rows, {
        text = "  |cffccccccOnline Now:|r " .. onlineSummary
    })
    table.insert(rows, {
        text = "  |cff888888Tip: Shift-Click any item in bags to link it! Click any linked message row below to pop open the Item Window.|r"
    })
    table.insert(rows, { text = "|cff555555----------------------------------------------------------------------|r" })

    local history = (AltVaultDB and AltVaultDB.VirtualChatHistory) or {}
    if #history == 0 then
        table.insert(rows, { text = " " })
        table.insert(rows, { text = "  |cff888888No messages in Virtual Guild Chat yet. Say hello in the box above!|r" })
    else
        local startIdx = math.max(1, #history - 79)
        for i = startIdx, #history do
            local m = history[i]
            local embeddedLink = m.text and string.match(m.text, "(|c%x+|Hitem:[^|]+|h%[[^%]]+%]|h|r)")
                or (m.text and string.match(m.text, "(|Hitem:[^|]+|h%[[^%]]+%]|h)"))
            local senderName = m.sender or "Peer"
            local hex = m.hex or "00ff96"

            local clickHint = embeddedLink
                and "|cff00ff00Left-Click:|r Open Linked Item Description Window"
                or ("|cffffd100Left-Click:|r Whisper / Mail " .. senderName)

            table.insert(rows, {
                link = embeddedLink,
                recommendNote = string.format("Message from %s at %s\n\n%s\n\n%s",
                    senderName, m.time or "", m.text or "", clickHint),
                text = string.format("|cff888888[%s]|r |cff%s[%s]|r: |cfffff569%s|r",
                    m.time or "--:--", hex, senderName, m.text or ""),
                onClickAction = function()
                    if embeddedLink then
                        OpenItemLinkPopupWindow(embeddedLink)
                        return
                    end
                    if senderName ~= UnitName("player") then
                        ContactOrMailSyncedPlayer(senderName, "your message", false)
                    end
                end
            })
        end
    end

    panel:RenderRowList(rows)
end

NetUI.RenderVirtualGuildChatTab = RenderVirtualGuildChatTab