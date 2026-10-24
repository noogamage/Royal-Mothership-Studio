-- ============================================================================
-- THE KINGDOM FORGE — GRAPHICS-DRIVEN 4-PAGE UI & GLOWING SIGNALER ENGINE
-- Pages:
--   1. [TALENT & SYNERGY FORGE]   - Live Build Sync + High-Contrast Dimming + Next Obvious Choice + Phase 3 Comp
--   2. [THE ARMOR MANNEQUIN]      - Pure Suit-of-Armor Stand + 17 Glowing Slots + Upgrade Flyout
--   3. [REVEALED KINGDOM ATLAS]   - True Revealed Map + Flight Points + Quest Route + Gather Hotspots
--   4. [ROYAL LIAISON & EMPIRE]   - Animated Liaison + 3 Adventure Paths + Alt Analyzer + 70/30 AH Split
-- ============================================================================
local ADDON_NAME, KF = ...
local V = TheKingdomForgeVault or {}
local WHITE = "Interface\\Buttons\\WHITE8X8"

-- Helper for inline WoW icons (eliminates all [] missing Unicode emoji boxes in Classic fonts!)
local function IconTag(texPath, size)
    size = size or 13
    return string.format("|T%s:%d:%d:0:0:64:64:5:59:5:59|t", texPath, size, size)
end

local IC_CROWN  = IconTag("Interface\\Icons\\INV_Crown_01", 13)
local IC_SWORD  = IconTag("Interface\\Icons\\Ability_DualWield", 13)
local IC_SHIELD = IconTag("Interface\\Icons\\INV_Shield_06", 13)
local IC_STAR   = IconTag("Interface\\Icons\\Spell_Holy_MagicalSentry", 13)
local IC_BOLT   = IconTag("Interface\\Icons\\Spell_Nature_Lightning", 13)
local IC_COIN   = IconTag("Interface\\Icons\\INV_Misc_Coin_01", 13)
local IC_BAG    = IconTag("Interface\\Icons\\INV_Misc_Bag_10_Blue", 13)
local IC_DE     = IconTag("Interface\\Icons\\Trade_Engraving", 13)
local IC_MAP    = IconTag("Interface\\Icons\\INV_Misc_Map_01", 13)
local IC_HERB   = IconTag("Interface\\Icons\\Trade_Herbalism", 13)
local IC_CAMP   = IconTag("Interface\\Icons\\Spell_Fire_Fire", 13)

-- ============================================================================
-- 1. PRECISION 4-EDGE NEON PERIMETER GLOW ENGINE (Zero Stretched Oval Rings!)
-- ============================================================================
KF.GlowRegistry = {}
local pulseAccum = 0

local GlowDriver = CreateFrame("Frame")
GlowDriver:SetScript("OnUpdate", function(_, elapsed)
    pulseAccum = pulseAccum + (elapsed or 0.016) * 3.8
    local wave = (math.sin(pulseAccum) + 1) * 0.5 -- 0.0 to 1.0
    local alpha = 0.30 + wave * 0.65
    for glowGroup, cfg in pairs(KF.GlowRegistry) do
        if glowGroup and glowGroup.owner and glowGroup.owner:IsVisible() then
            local a = alpha * (cfg.scaleAlpha or 1.0)
            for _, tex in ipairs(glowGroup.edges) do
                tex:SetAlpha(a)
            end
            if glowGroup.fill then
                glowGroup.fill:SetAlpha(a * 0.14)
            end
        end
    end
end)

function KF:AttachGlowSignaler(frame, r, g, b, thickness, scaleAlpha)
    if not frame then return nil end
    r, g, b = r or 1.0, g or 0.82, b or 0.15
    thickness = math.max(2, math.min(4, tonumber(thickness) or 2))

    if not frame.kfGlowGroup then
        local grp = { owner = frame, edges = {} }
        -- 4 precision perimeter edge strips (Top, Bottom, Left, Right) + subtle inner glow tint
        local top = frame:CreateTexture(nil, "OVERLAY")
        local bot = frame:CreateTexture(nil, "OVERLAY")
        local lft = frame:CreateTexture(nil, "OVERLAY")
        local rgt = frame:CreateTexture(nil, "OVERLAY")
        for _, t in ipairs({ top, bot, lft, rgt }) do
            t:SetTexture(WHITE)
            t:SetBlendMode("ADD")
            table.insert(grp.edges, t)
        end
        local fill = frame:CreateTexture(nil, "BACKGROUND", nil, 7)
        fill:SetPoint("TOPLEFT", frame, "TOPLEFT", 2, -2)
        fill:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -2, 2)
        fill:SetTexture(WHITE)
        fill:SetBlendMode("ADD")
        grp.fill = fill
        frame.kfGlowGroup = grp
    end

    local grp = frame.kfGlowGroup
    local top, bot, lft, rgt = grp.edges[1], grp.edges[2], grp.edges[3], grp.edges[4]

    top:ClearAllPoints()
    top:SetPoint("TOPLEFT", frame, "TOPLEFT", -1, 1)
    top:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 1, 1)
    top:SetHeight(thickness)

    bot:ClearAllPoints()
    bot:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", -1, -1)
    bot:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 1, -1)
    bot:SetHeight(thickness)

    lft:ClearAllPoints()
    lft:SetPoint("TOPLEFT", frame, "TOPLEFT", -1, 1)
    lft:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", -1, -1)
    lft:SetWidth(thickness)

    rgt:ClearAllPoints()
    rgt:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 1, 1)
    rgt:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 1, -1)
    rgt:SetWidth(thickness)

    for _, t in ipairs(grp.edges) do
        t:SetVertexColor(r, g, b, 0.95)
        t:Show()
    end
    if grp.fill then
        grp.fill:SetVertexColor(r, g, b, 0.12)
        grp.fill:Show()
    end

    KF.GlowRegistry[grp] = { scaleAlpha = scaleAlpha or 1.0 }
    return grp
end

function KF:HideGlowSignaler(frame)
    if frame and frame.kfGlowGroup then
        local grp = frame.kfGlowGroup
        for _, t in ipairs(grp.edges) do t:Hide() end
        if grp.fill then grp.fill:Hide() end
        KF.GlowRegistry[grp] = nil
    end
end

local function SetStyledBackdrop(frame, bgR, bgG, bgB, bgA, brR, brG, brB, brA)
    if not frame or not frame.SetBackdrop then return end
    frame:SetBackdrop({
        bgFile = WHITE,
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 14,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    frame:SetBackdropColor(bgR or 0.05, bgG or 0.06, bgB or 0.09, bgA or 0.96)
    frame:SetBackdropBorderColor(brR or 0.85, brG or 0.68, brB or 0.22, brA or 1.0)
end

-- ============================================================================
-- 2. MAIN ROYAL WINDOW & 4 NAVIGATION TABS
-- ============================================================================
local MainFrame = CreateFrame("Frame", "TheKingdomForgeMainFrame", UIParent, "BackdropTemplate")
MainFrame:SetSize(1020, 680)
MainFrame:SetPoint("CENTER")
MainFrame:SetFrameStrata("HIGH")
MainFrame:SetMovable(true)
MainFrame:EnableMouse(true)
MainFrame:RegisterForDrag("LeftButton")
MainFrame:SetScript("OnDragStart", MainFrame.StartMoving)
MainFrame:SetScript("OnDragStop", MainFrame.StopMovingOrSizing)
MainFrame:Hide()
SetStyledBackdrop(MainFrame, 0.04, 0.05, 0.08, 0.97, 0.92, 0.74, 0.22, 1.0)
KF.MainFrame = MainFrame

tinsert(UISpecialFrames, "TheKingdomForgeMainFrame")

-- Top Royal Header Bar
local HeaderBar = CreateFrame("Frame", nil, MainFrame, "BackdropTemplate")
HeaderBar:SetPoint("TOPLEFT", 8, -8)
HeaderBar:SetPoint("TOPRIGHT", -8, -8)
HeaderBar:SetHeight(42)
SetStyledBackdrop(HeaderBar, 0.08, 0.09, 0.14, 0.95, 0.75, 0.58, 0.18, 1.0)

local CrestIcon = HeaderBar:CreateTexture(nil, "ARTWORK")
CrestIcon:SetSize(28, 28)
CrestIcon:SetPoint("LEFT", 10, 0)
CrestIcon:SetTexture("Interface\\Icons\\INV_Crown_01")
CrestIcon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

local TitleText = HeaderBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
TitleText:SetPoint("LEFT", CrestIcon, "RIGHT", 10, 1)
TitleText:SetText("|cffffd100THE KINGDOM FORGE|r  |cff00ffcc•  WoW Classic & Forever Royal Build, Mannequin, Atlas & Empire Suite|r")

local CloseBtn = CreateFrame("Button", nil, HeaderBar, "UIPanelCloseButton")
CloseBtn:SetPoint("RIGHT", -4, 0)

-- 4 Main Page Containers
local Pages = {}
local TabButtons = {}
local TAB_DEFS = {
    { id = 1, label = "1. Talent & Synergy Forge",   icon = "Interface\\Icons\\Ability_Marksmanship" },
    { id = 2, label = "2. The Armor Mannequin",      icon = "Interface\\Icons\\INV_Chest_Plate04" },
    { id = 3, label = "3. Revealed Kingdom Atlas",   icon = "Interface\\Icons\\INV_Misc_Map_01" },
    { id = 4, label = "4. Royal Liaison & Empire",   icon = "Interface\\Icons\\INV_Crown_01" },
}

for i, tdef in ipairs(TAB_DEFS) do
    local tb = CreateFrame("Button", "TheKingdomForgeTab" .. i, MainFrame, "BackdropTemplate")
    tb:SetSize(244, 32)
    tb:SetPoint("TOPLEFT", 12 + (i - 1) * 249, -54)
    SetStyledBackdrop(tb, 0.09, 0.11, 0.16, 0.95, 0.45, 0.38, 0.18, 1.0)

    tb.icon = tb:CreateTexture(nil, "ARTWORK")
    tb.icon:SetSize(20, 20)
    tb.icon:SetPoint("LEFT", 10, 0)
    tb.icon:SetTexture(tdef.icon)
    tb.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    tb.txt = tb:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    tb.txt:SetPoint("LEFT", tb.icon, "RIGHT", 8, 0)
    tb.txt:SetText(tdef.label)

    tb:SetScript("OnClick", function()
        KF:SelectTab(tdef.id)
    end)
    TabButtons[i] = tb

    local page = CreateFrame("Frame", "TheKingdomForgePage" .. i, MainFrame, "BackdropTemplate")
    page:SetPoint("TOPLEFT", 10, -90)
    page:SetPoint("BOTTOMRIGHT", -10, 10)
    SetStyledBackdrop(page, 0.05, 0.06, 0.09, 0.94, 0.32, 0.28, 0.16, 0.9)
    page:Hide()
    Pages[i] = page
end

-- ============================================================================
-- PAGE 1: SIMULATED TALENT & SYNERGY FORGE (Phases 1, 2 & 3)
-- High-Contrast Non-Build Dimming + Live Player Build Sync + Next Obvious Choice
-- ============================================================================
local P1 = Pages[1]

local P1_ClassBtns = {}
local CLASS_LIST = { "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID", "LEGACY" }

for idx, cTok in ipairs(CLASS_LIST) do
    local b = CreateFrame("Button", nil, P1, "UIPanelButtonTemplate")
    b:SetSize(66, 22)
    b:SetPoint("TOPLEFT", 10 + (idx - 1) * 68, -6)
    b:SetText(cTok:sub(1, 1) .. cTok:sub(2):lower())
    b:SetScript("OnClick", function()
        local db = KF:EnsureDB()
        local _, pCls, _, _, pLvl = KF:GetPlayerContext()
        db.selectedClass = cTok
        db.selectedSpecIdx = 1
        if cTok == pCls then
            db.useLiveTalents = true
            db.selectedLevel = pLvl
        else
            db.AutoLoadedSpec = nil
            KF:AutoPopulateSimTalentsFromSpec()
        end
        KF:RefreshPage1()
    end)
    P1_ClassBtns[cTok] = b
end

local P1_LvlSteps = {
    { lbl = "-5", d = -5, w = 32 },
    { lbl = "-1", d = -1, w = 32 },
    { lbl = "My Lvl", d = 0, w = 52 },
    { lbl = "+1", d = 1, w = 32 },
    { lbl = "+5", d = 5, w = 32 },
    { lbl = "Lv40", d = 400, w = 42 },
    { lbl = "Lv60", d = 600, w = 42 },
}
local lx = 700
for _, st in ipairs(P1_LvlSteps) do
    local b = CreateFrame("Button", nil, P1, "UIPanelButtonTemplate")
    b:SetSize(st.w, 22)
    b:SetPoint("TOPLEFT", lx, -6)
    b:SetText(st.lbl)
    b:SetScript("OnClick", function()
        local db = KF:EnsureDB()
        local _, pCls, _, _, pLvl = KF:GetPlayerContext()
        if st.d == 0 then
            db.selectedClass = pCls
            db.selectedLevel = pLvl
            db.useLiveTalents = true
        elseif st.d == 400 then
            db.selectedLevel = 40
            db.useLiveTalents = false
            KF:AutoPopulateSimTalentsFromSpec()
        elseif st.d == 600 then
            db.selectedLevel = 60
            db.useLiveTalents = false
            KF:AutoPopulateSimTalentsFromSpec()
        else
            db.selectedLevel = math.max(1, math.min(60, (db.selectedLevel or pLvl or 1) + st.d))
            db.useLiveTalents = false
            KF:AutoPopulateSimTalentsFromSpec()
        end
        KF:RefreshPage1()
    end)
    lx = lx + st.w + 3
end

-- 4 Role / Build Buttons + Live Sync Toggle + Load Optimal + Wipe Button
local P1_SpecBtns = {}
for i = 1, 4 do
    local sb = CreateFrame("Button", nil, P1, "UIPanelButtonTemplate")
    sb:SetSize(172, 22)
    sb:SetPoint("TOPLEFT", 10 + (i - 1) * 175, -31)
    sb:SetText("Role Spec " .. i)
    sb:SetScript("OnClick", function()
        local db = KF:EnsureDB()
        db.selectedSpecIdx = i
        if not db.useLiveTalents then
            KF:AutoPopulateSimTalentsFromSpec()
        end
        KF:RefreshPage1()
    end)
    P1_SpecBtns[i] = sb
end

local LiveSyncBtn = CreateFrame("Button", nil, P1, "UIPanelButtonTemplate")
LiveSyncBtn:SetSize(112, 22)
LiveSyncBtn:SetPoint("TOPLEFT", 712, -31)
LiveSyncBtn:SetText("My Live Build")
LiveSyncBtn:SetScript("OnClick", function()
    local db = KF:EnsureDB()
    local _, pCls, _, _, pLvl = KF:GetPlayerContext()
    db.selectedClass = pCls
    db.selectedLevel = pLvl
    db.useLiveTalents = not db.useLiveTalents
    if not db.useLiveTalents then
        KF:AutoPopulateSimTalentsFromSpec()
    end
    KF:RefreshPage1()
end)

local AutoFillBtn = CreateFrame("Button", nil, P1, "UIPanelButtonTemplate")
AutoFillBtn:SetSize(96, 22)
AutoFillBtn:SetPoint("TOPLEFT", 827, -31)
AutoFillBtn:SetText("Sim Path")
AutoFillBtn:SetScript("OnClick", function()
    local db = KF:EnsureDB()
    db.useLiveTalents = false
    KF:AutoPopulateSimTalentsFromSpec()
    KF:RefreshPage1()
end)

local ClearSimBtn = CreateFrame("Button", nil, P1, "UIPanelButtonTemplate")
ClearSimBtn:SetSize(64, 22)
ClearSimBtn:SetPoint("TOPLEFT", 926, -31)
ClearSimBtn:SetText("Wipe")
ClearSimBtn:SetScript("OnClick", function()
    local db = KF:EnsureDB()
    db.useLiveTalents = false
    local cls = db.selectedClass or "WARRIOR"
    db.simTalents[cls] = { [1] = {}, [2] = {}, [3] = {} }
    KF:RefreshPage1()
end)

-- Live Character Build & "Next Obvious Talent Choice" Banner above the 3 Trees
local LiveNextBanner = CreateFrame("Frame", nil, P1, "BackdropTemplate")
LiveNextBanner:SetSize(680, 26)
LiveNextBanner:SetPoint("TOPLEFT", 10, -56)
SetStyledBackdrop(LiveNextBanner, 0.05, 0.13, 0.10, 0.96, 0.15, 0.95, 0.55, 1.0)

local LiveNextText = LiveNextBanner:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
LiveNextText:SetPoint("LEFT", 10, 0)
LiveNextText:SetWidth(660)
LiveNextText:SetJustifyH("LEFT")
LiveNextText:SetText("")

-- 3 Visual Talent Tree Panels (Left 680px) + Right Synergy & Compensation Panel (295px)
local TreePanels = {}
local TreeNodeButtons = { [1] = {}, [2] = {}, [3] = {} }

for tIdx = 1, 3 do
    local tp = CreateFrame("Frame", nil, P1, "BackdropTemplate")
    tp:SetSize(224, 488)
    tp:SetPoint("TOPLEFT", 10 + (tIdx - 1) * 228, -85)
    SetStyledBackdrop(tp, 0.04, 0.05, 0.08, 0.98, 0.55, 0.44, 0.16, 1.0)

    tp.hdrIcon = tp:CreateTexture(nil, "ARTWORK")
    tp.hdrIcon:SetSize(20, 20)
    tp.hdrIcon:SetPoint("TOPLEFT", 8, -6)
    tp.hdrIcon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    tp.hdrTitle = tp:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    tp.hdrTitle:SetPoint("LEFT", tp.hdrIcon, "RIGHT", 6, 0)
    tp.hdrTitle:SetText("Tree " .. tIdx)

    tp.ptsTxt = tp:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    tp.ptsTxt:SetPoint("TOPRIGHT", -8, -9)
    tp.ptsTxt:SetText("0 pts")

    -- Create 7x4 Grid of Interactive Talent Node Buttons (28 slots per tree)
    for row = 1, 7 do
        TreeNodeButtons[tIdx][row] = {}
        for col = 1, 4 do
            local nb = CreateFrame("Button", nil, tp, "BackdropTemplate")
            nb:SetSize(38, 38)
            local nx = 15 + (col - 1) * 51
            local ny = -38 - (row - 1) * 63
            nb:SetPoint("TOPLEFT", nx, ny)
            nb:RegisterForClicks("LeftButtonUp", "RightButtonUp")
            SetStyledBackdrop(nb, 0.04, 0.04, 0.06, 0.95, 0.30, 0.30, 0.35, 0.8)

            nb.icon = nb:CreateTexture(nil, "ARTWORK")
            nb.icon:SetPoint("TOPLEFT", 3, -3)
            nb.icon:SetPoint("BOTTOMRIGHT", -3, 3)
            nb.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

            -- Dark veil overlay for non-build talents to guarantee extreme visual contrast!
            nb.dimVeil = nb:CreateTexture(nil, "OVERLAY", nil, 1)
            nb.dimVeil:SetPoint("TOPLEFT", 3, -3)
            nb.dimVeil:SetPoint("BOTTOMRIGHT", -3, 3)
            nb.dimVeil:SetColorTexture(0.0, 0.0, 0.02, 0.72)
            nb.dimVeil:Hide()

            nb.rankBadge = nb:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            nb.rankBadge:SetPoint("BOTTOMRIGHT", 2, -2)
            nb.rankBadge:SetText("0/5")

            nb.nextBadge = nb:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            nb.nextBadge:SetPoint("BOTTOM", nb, "TOP", 0, 2)
            nb.nextBadge:SetText("")

            nb:SetScript("OnEnter", function(self)
                if not self.nodeData then return end
                local nd = self.nodeData
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:ClearLines()
                GameTooltip:AddLine(string.format("|cffffd100%s|r  |cff00ffcc(Current: %d / %d)|r", nd.name, self.curRank or 0, nd.max), 1, 1, 1)
                if self.recRank and self.recRank > 0 then
                    GameTooltip:AddLine(string.format("|cff22c55eBuild Target Rank at This Level: %d / %d|r", self.recRank, nd.max), 0.2, 1, 0.4)
                else
                    GameTooltip:AddLine("|cff888888[Dimmed: Not used in this Role Build at this level]|r", 0.6, 0.6, 0.6)
                end
                if self.isNextObvious then
                    GameTooltip:AddLine("|cff00ff96>> BEST NEXT OBVIOUS TALENT POINT FOR YOUR PATH! <<|r", 0, 1, 0.6)
                end
                GameTooltip:AddLine(string.format("Tier Row %d, Column %d  •  Requires %d pts in %s", nd.row, nd.col, (nd.row - 1) * 5, self.treeName or "Tree"), 0.7, 0.85, 1.0)
                if nd.reqName and nd.reqName ~= "" then
                    GameTooltip:AddLine("|cffff8844Prerequisite Talent:|r " .. nd.reqName, 1, 1, 1)
                end
                if nd.r1 and nd.r1 ~= "" then
                    GameTooltip:AddLine(" ")
                    GameTooltip:AddLine("|cffffd100Rank 1:|r " .. nd.r1, 0.92, 0.92, 0.92, true)
                end
                if nd.max > 1 and nd.rMax and nd.rMax ~= "" and nd.rMax ~= nd.r1 then
                    GameTooltip:AddLine(string.format("|cff22c55eMax Rank (%d):|r %s", nd.max, nd.rMax), 0.85, 1.0, 0.85, true)
                end
                if nd.note and nd.note ~= "" then
                    GameTooltip:AddLine(" ")
                    GameTooltip:AddLine("|cffc084fcForever vs Classic:|r " .. nd.note, 0.85, 0.75, 1.0, true)
                end
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine("|cff38bdf8Left-Click:|r Simulate +1 Point   |   |cffff6666Right-Click:|r Refund -1 Point", 0.7, 0.7, 0.7)
                GameTooltip:Show()
            end)
            nb:SetScript("OnLeave", function() GameTooltip:Hide() end)

            nb:SetScript("OnClick", function(self, button)
                if not self.nodeData then return end
                local db = KF:EnsureDB()
                db.useLiveTalents = false
                local cls = db.selectedClass or "WARRIOR"
                db.simTalents[cls] = db.simTalents[cls] or { [1] = {}, [2] = {}, [3] = {} }
                local tTbl = db.simTalents[cls][tIdx] or {}
                db.simTalents[cls][tIdx] = tTbl
                local cur = tTbl[self.nodeData.id] or 0
                if button == "RightButton" then
                    if cur > 0 then tTbl[self.nodeData.id] = cur - 1 end
                else
                    if cur < (self.nodeData.max or 5) then
                        tTbl[self.nodeData.id] = cur + 1
                    end
                end
                KF:RefreshPage1()
            end)

            nb:Hide()
            TreeNodeButtons[tIdx][row][col] = nb
        end
    end

    TreePanels[tIdx] = tp
end

-- Right Synergy, Over-Stack & Compensation Panel on Page 1
local P1_RightPanel = CreateFrame("Frame", nil, P1, "BackdropTemplate")
P1_RightPanel:SetPoint("TOPLEFT", 698, -56)
P1_RightPanel:SetPoint("BOTTOMRIGHT", -8, 8)
SetStyledBackdrop(P1_RightPanel, 0.06, 0.08, 0.12, 0.96, 0.0, 0.82, 0.65, 1.0)

local P1_Scroll = CreateFrame("ScrollFrame", "TheKingdomForgeP1Scroll", P1_RightPanel, "UIPanelScrollFrameTemplate")
P1_Scroll:SetPoint("TOPLEFT", 8, -8)
P1_Scroll:SetPoint("BOTTOMRIGHT", -28, 8)
local P1_ScrollChild = CreateFrame("Frame", nil, P1_Scroll)
P1_ScrollChild:SetSize(258, 760)
P1_Scroll:SetScrollChild(P1_ScrollChild)

local P1_InfoText = P1_ScrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
P1_InfoText:SetPoint("TOPLEFT", 2, -2)
P1_InfoText:SetWidth(252)
P1_InfoText:SetJustifyH("LEFT")
P1_InfoText:SetJustifyV("TOP")
P1_InfoText:SetSpacing(3)

-- Helper: Parse recommended talents map { [tIdx][nodeId] = rank } and ordered list from spec at level
function KF:GetRecommendedMapForLevel(cls, sIdx, targetLvl)
    local recMap = { [1] = {}, [2] = {}, [3] = {} }
    local recOrdered = {}
    local specs = V.SpecBuilds and V.SpecBuilds[cls]
    local activeSpec = specs and specs[sIdx]
    local lookupLvl = math.max(10, math.min(60, tonumber(targetLvl) or 10))
    local lData = activeSpec and activeSpec.levels and activeSpec.levels[lookupLvl]
    local tStr = lData and lData.tStr or ""
    local trees = V.TalentTrees and V.TalentTrees[cls]
    if not trees or tStr == "" then return recMap, recOrdered, lData, activeSpec end

    for piece in tStr:gmatch("([^/]+)") do
        local tName, rStr = piece:match("^%s*(.-)%s*%((%d+)%)")
        local rank = tonumber(rStr)
        if tName and rank then
            local matched = false
            for tIdx = 1, 3 do
                local tInfo = trees[tIdx]
                for _, nd in ipairs((tInfo and tInfo.nodes) or {}) do
                    if nd.name:lower() == tName:lower() or nd.name:lower():find(tName:lower(), 1, true) then
                        local clamped = math.min(nd.max or 5, rank)
                        recMap[tIdx][nd.id] = clamped
                        table.insert(recOrdered, { tIdx = tIdx, treeName = tInfo.name, node = nd, recRank = clamped })
                        matched = true
                        break
                    end
                end
                if matched then break end
            end
        end
    end
    return recMap, recOrdered, lData, activeSpec
end

function KF:AutoPopulateSimTalentsFromSpec()
    local db = self:EnsureDB()
    local _, pCls, _, _, pLvl = self:GetPlayerContext()
    local cls = db.selectedClass or pCls or "WARRIOR"
    local lvl = db.selectedLevel or pLvl or 10
    local sIdx = db.selectedSpecIdx or 1

    local recMap = self:GetRecommendedMapForLevel(cls, sIdx, lvl)
    db.simTalents[cls] = recMap
end

function KF:RefreshPage1()
    local db = self:EnsureDB()
    local pName, pCls, _, _, pLvl = self:GetPlayerContext()

    -- Default to the logged-in character's class and level on first open!
    if not db.selectedClass then
        db.selectedClass = pCls
        db.selectedLevel = pLvl
        db.useLiveTalents = true
    end

    local cls = db.selectedClass or pCls or "WARRIOR"
    local lvl = tonumber(db.selectedLevel) or pLvl or 1
    if lvl < 1 then lvl = 1 elseif lvl > 60 then lvl = 60 end
    local sIdx = tonumber(db.selectedSpecIdx) or 1
    db.selectedClass = cls
    db.selectedLevel = lvl
    db.selectedSpecIdx = sIdx

    -- Highlight selected Class button
    for cTok, cb in pairs(P1_ClassBtns) do
        if cTok == cls then
            self:AttachGlowSignaler(cb, 1.0, 0.82, 0.15, 2, 0.85)
        else
            self:HideGlowSignaler(cb)
        end
    end

    -- Scan live player talents if viewing player's own class
    local _, _, liveByTab, liveByPos, liveTabSpent, totalLiveSpent, unspentLive = self:ScanLivePlayerTalents()
    local isViewingOwnClass = (cls == pCls)
    local usingLive = isViewingOwnClass and db.useLiveTalents

    if usingLive then
        LiveSyncBtn:SetText("|cff00ff96[Live Sync ON]|r")
        self:AttachGlowSignaler(LiveSyncBtn, 0.15, 1.0, 0.55, 2, 0.9)
    else
        LiveSyncBtn:SetText("My Live Build")
        self:HideGlowSignaler(LiveSyncBtn)
    end

    local specs = V.SpecBuilds and V.SpecBuilds[cls]
    for i = 1, 4 do
        local sb = P1_SpecBtns[i]
        local sp = specs and specs[i]
        if sb then
            if sp then
                sb:Show()
                local pre = (i == sIdx) and "|cff00ff96>> " or "|cffffd100"
                sb:SetText(pre .. sp.name:sub(1, 20) .. "|r")
                if i == sIdx then self:AttachGlowSignaler(sb, 0.15, 1.0, 0.55, 2, 0.85) else self:HideGlowSignaler(sb) end
            else
                sb:Hide()
                self:HideGlowSignaler(sb)
            end
        end
    end

    -- Get Recommended Build Map for current level AND next level (+1) to find the NEXT OBVIOUS CHOICE
    local evalLvl = usingLive and math.max(10, pLvl) or math.max(10, lvl)
    local recMap, recOrdered, lData, activeSpec = self:GetRecommendedMapForLevel(cls, sIdx, evalLvl)
    local nextRecMap, nextRecOrdered, nextLData = self:GetRecommendedMapForLevel(cls, sIdx, math.min(60, evalLvl + 1))

    if not db.simTalents[cls] then
        self:AutoPopulateSimTalentsFromSpec()
    end
    local simClass = db.simTalents[cls] or { [1] = {}, [2] = {}, [3] = {} }

    -- Build current rank map for all nodes (either Live In-Game Talents or Simulated Talents)
    local trees = V.TalentTrees and V.TalentTrees[cls]
    local curRanks = { [1] = {}, [2] = {}, [3] = {} }
    local treeTotals = { [1] = 0, [2] = 0, [3] = 0 }

    for tIdx = 1, 3 do
        local tInfo = trees and trees[tIdx]
        if tInfo then
            for _, nd in ipairs(tInfo.nodes or {}) do
                local r = 0
                if usingLive then
                    local byName = nd.name and liveByTab[tIdx][nd.name:lower()]
                    local byPos = liveByPos[tIdx][(nd.row or 1) .. ":" .. (nd.col or 1)]
                    r = byName or byPos or 0
                else
                    r = (simClass[tIdx] and simClass[tIdx][nd.id]) or 0
                end
                curRanks[tIdx][nd.id] = r
                treeTotals[tIdx] = treeTotals[tIdx] + r
            end
        end
    end

    -- Determine the SINGLE BEST NEXT OBVIOUS TALENT CHOICE given the character's current points & chosen path!
    local nextObvious = nil -- { tIdx, treeName, node, curRank, targetRank, why }
    -- Pass 1: Any talent in the current level's recommended path where curRank < recRank and row requirement is met
    for _, item in ipairs(recOrdered) do
        local cRank = curRanks[item.tIdx][item.node.id] or 0
        local reqPts = ((item.node.row or 1) - 1) * 5
        if cRank < item.recRank and treeTotals[item.tIdx] >= reqPts then
            nextObvious = {
                tIdx = item.tIdx,
                treeName = item.treeName,
                node = item.node,
                curRank = cRank,
                targetRank = item.recRank,
                why = string.format("Path priority for Level %d (%d -> %d)", evalLvl, cRank, cRank + 1)
            }
            break
        end
    end
    -- Pass 2: If current level build is already complete, check next level (evalLvl + 1) or lData.nextPt!
    if not nextObvious then
        for _, item in ipairs(nextRecOrdered) do
            local cRank = curRanks[item.tIdx][item.node.id] or 0
            local reqPts = ((item.node.row or 1) - 1) * 5
            if cRank < item.recRank and treeTotals[item.tIdx] >= reqPts then
                nextObvious = {
                    tIdx = item.tIdx,
                    treeName = item.treeName,
                    node = item.node,
                    curRank = cRank,
                    targetRank = item.recRank,
                    why = string.format("Next Level (%d) Path Unlock (%d -> %d)", math.min(60, evalLvl + 1), cRank, cRank + 1)
                }
                break
            end
        end
    end
    -- Pass 3: Fallback to lData.nextPt name match
    local nextPtName = (lData and lData.nextPt) or ""
    if not nextObvious and nextPtName ~= "" and trees then
        for tIdx = 1, 3 do
            local tInfo = trees[tIdx]
            for _, nd in ipairs((tInfo and tInfo.nodes) or {}) do
                if nd.name and nextPtName:lower():find(nd.name:lower(), 1, true) then
                    local cRank = curRanks[tIdx][nd.id] or 0
                    if cRank < (nd.max or 5) then
                        nextObvious = {
                            tIdx = tIdx,
                            treeName = tInfo.name,
                            node = nd,
                            curRank = cRank,
                            targetRank = math.min(nd.max or 5, cRank + 1),
                            why = "Recommended Next Point at Level " .. evalLvl
                        }
                        break
                    end
                end
            end
            if nextObvious then break end
        end
    end

    -- Update the Top Live Build & Next Obvious Choice Banner
    local modeLabel = usingLive
        and string.format("|cff00ff96[LIVE CHARACTER: %s (Lv %d %s) • Spent: %d pts • Unspent: %d pts]|r", pName, pLvl, pCls, totalLiveSpent, unspentLive)
        or string.format("|cffffd100[SIMULATOR MODE: %s (Target Lv %d)]|r", cls, lvl)

    if nextObvious and nextObvious.node then
        LiveNextText:SetText(string.format(
            "%s   |cffffd100>> NEXT OBVIOUS POINT:|r |cff00ff96[%s] %s (Rank %d -> %d)|r",
            modeLabel, nextObvious.treeName or "Tree", nextObvious.node.name, nextObvious.curRank, math.min(nextObvious.node.max or 5, nextObvious.curRank + 1)
        ))
    else
        LiveNextText:SetText(modeLabel .. "   |cff00ffcc>> All recommended talents for this level are complete!|r")
    end

    -- Render all 3 Trees with EXTREME CONTRAST (Dimmed Non-Build vs Vivid Active/Recommended vs Blazing Next Obvious)
    for tIdx = 1, 3 do
        local tp = TreePanels[tIdx]
        local tInfo = trees and trees[tIdx]
        for r = 1, 7 do
            for c = 1, 4 do
                local btn = TreeNodeButtons[tIdx][r][c]
                btn:Hide()
                self:HideGlowSignaler(btn)
            end
        end

        if tInfo then
            tp.hdrIcon:SetTexture(tInfo.icon or "Interface\\Icons\\INV_Misc_Book_11")
            tp.hdrTitle:SetText("|cffffd100" .. (tInfo.name or ("Tree " .. tIdx)) .. "|r")
            local treePts = treeTotals[tIdx] or 0

            for _, nd in ipairs(tInfo.nodes or {}) do
                local r = math.max(1, math.min(7, nd.row or 1))
                local c = math.max(1, math.min(4, nd.col or 1))
                local nb = TreeNodeButtons[tIdx][r][c]
                if nb then
                    local curRank = curRanks[tIdx][nd.id] or 0
                    local recRank = (recMap[tIdx] and recMap[tIdx][nd.id]) or (nextRecMap[tIdx] and nextRecMap[tIdx][nd.id]) or 0
                    local isNext = (nextObvious and nextObvious.node and nextObvious.node.id == nd.id) or false

                    nb.nodeData = nd
                    nb.curRank = curRank
                    nb.recRank = recRank
                    nb.isNextObvious = isNext
                    nb.treeName = tInfo.name
                    nb.icon:SetTexture(nd.icon or "Interface\\Icons\\INV_Misc_QuestionMark")

                    if isNext then
                        -- 1. BLAZING NEXT OBVIOUS TALENT CHOICE (Maximum Contrast + Cyan-Gold Neon Frame + >> NEXT << Tag!)
                        nb:SetAlpha(1.0)
                        nb.dimVeil:Hide()
                        nb.icon:SetDesaturated(false)
                        nb.icon:SetVertexColor(1.0, 1.0, 1.0)
                        SetStyledBackdrop(nb, 0.04, 0.22, 0.18, 1.0, 0.0, 1.0, 0.80, 1.0)
                        nb.rankBadge:SetText(string.format("|cff00ff96%d/%d|r", curRank, nd.max))
                        nb.nextBadge:SetText("|cff00ff96>>NEXT<<|r")
                        self:AttachGlowSignaler(nb, 0.0, 1.0, 0.80, 3, 1.0)
                    elseif curRank > 0 or recRank > 0 then
                        -- 2. ACTIVE IN CHARACTER BUILD OR RECOMMENDED PATH (Vivid Full Color + Crisp Border)
                        nb:SetAlpha(1.0)
                        nb.dimVeil:Hide()
                        nb.icon:SetDesaturated(false)
                        nb.icon:SetVertexColor(1.0, 1.0, 1.0)
                        nb.nextBadge:SetText("")

                        if curRank >= (nd.max or 1) then
                            -- Maxed talent: Royal Gold Border
                            SetStyledBackdrop(nb, 0.14, 0.11, 0.03, 1.0, 1.0, 0.82, 0.10, 1.0)
                            nb.rankBadge:SetText(string.format("|cffffd100%d/%d|r", curRank, nd.max))
                            self:AttachGlowSignaler(nb, 1.0, 0.82, 0.10, 2, 0.55)
                        elseif curRank > 0 then
                            -- Partially trained talent: Bright Emerald Border
                            SetStyledBackdrop(nb, 0.04, 0.15, 0.07, 1.0, 0.15, 1.0, 0.35, 1.0)
                            if recRank > curRank then
                                nb.rankBadge:SetText(string.format("|cff22c55e%d|r|cff38bdf8->%d|r", curRank, recRank))
                            else
                                nb.rankBadge:SetText(string.format("|cff22c55e%d/%d|r", curRank, nd.max))
                            end
                            self:AttachGlowSignaler(nb, 0.15, 1.0, 0.35, 2, 0.50)
                        else
                            -- Recommended in build at this level, but 0 points trained so far: Crisp Sky-Blue Target Border
                            SetStyledBackdrop(nb, 0.04, 0.10, 0.18, 0.96, 0.25, 0.78, 1.0, 0.95)
                            nb.rankBadge:SetText(string.format("|cff38bdf80->%d|r", recRank))
                        end
                    else
                        -- 3. NON-BUILD TALENT (DEEPLY DIMMED, DESATURATED & VEILED FOR SHARP VISUAL CONTRAST!)
                        nb:SetAlpha(0.32)
                        nb.dimVeil:Show()
                        nb.icon:SetDesaturated(true)
                        nb.icon:SetVertexColor(0.24, 0.24, 0.28)
                        SetStyledBackdrop(nb, 0.02, 0.02, 0.03, 0.70, 0.16, 0.16, 0.18, 0.35)
                        nb.rankBadge:SetText(string.format("|cff4444440/%d|r", nd.max))
                        nb.nextBadge:SetText("")
                    end

                    nb:Show()
                end
            end
            tp.ptsTxt:SetText(string.format("|cff00ffcc%d pts|r", treePts))
        else
            tp.hdrTitle:SetText("N/A")
            tp.ptsTxt:SetText("")
        end
    end

    -- Populate Right Synergy, Over-Stack & Phase 3 Compensation Panel
    local infoLines = {}
    table.insert(infoLines, string.format("|cffffd100[%s — LEVEL %d]|r", cls, evalLvl))
    if activeSpec and lData then
        table.insert(infoLines, string.format("|cff00ffccSpec:|r |cffffffff%s|r (|cffffff00%s|r)", activeSpec.name, activeSpec.role))
        table.insert(infoLines, string.format("|cff00ffccKill Efficiency:|r |cff22c55e%.2f|r", lData.score or 0))
        if nextObvious and nextObvious.node then
            table.insert(infoLines, string.format(
                "\n%s |cffffd100NEXT OBVIOUS TALENT CHOICE:|r\n|cff00ff96>> [%s] %s (Rank %d -> %d)|r\n|cffcccccc%s|r",
                IC_STAR, nextObvious.treeName or "Tree", nextObvious.node.name, nextObvious.curRank,
                math.min(nextObvious.node.max or 5, nextObvious.curRank + 1), nextObvious.why or ""
            ))
        elseif lData.nextPt and lData.nextPt ~= "" then
            table.insert(infoLines, string.format("\n%s |cffffd100NEXT POINT (Lv %d):|r\n|cff22c55e>> %s|r", IC_STAR, evalLvl, lData.nextPt))
        end
        if (lData.maxTier or 5) > 5 or (lData.overNote and lData.overNote ~= "") then
            table.insert(infoLines, string.format("\n%s |cffffaa00PHASE 2 TIER OVER-STACK (%d Pts in 1 Row!):|r\n|cffffffff%s|r", IC_BOLT, lData.maxTier or 6, lData.overNote or "Over-stacking >5 points in a single tier delivers higher immediate DPS/Sustain before later respec."))
        end
        if lData.respec == 1 or (lData.respecWhy and lData.respecWhy ~= "") then
            table.insert(infoLines, string.format("\n|cffff4444[LEVEL %d TRAINER RESPEC WINDOW]:|r\n|cffffffff%s|r", evalLvl, lData.respecWhy or "Wipe tree at Class Trainer (1g) to immediately lock in the 31-pt Capstone!"))
        end
        table.insert(infoLines, string.format("\n|cffffd100Dynamic Stat Priority:|r\n|cff66ff66%s|r", lData.stat or ""))
        table.insert(infoLines, string.format("\n|cffffd100Core Rotation Abilities:|r\n|cffffffff%s|r", lData.abil or ""))
        table.insert(infoLines, string.format("\n|cffffd100Optimal Weapon & Swing Rule:|r\n|cff38bdf8%s|r", lData.wep or ""))
        if lData.compTrig and lData.compTrig ~= "" then
            table.insert(infoLines, string.format("\n|cffffd100PHASE 3 COMPENSATION SHIFT:|r\n|cff00ffccTrigger:|r %s\n|cff22c55eTalent Swap:|r %s", lData.compTrig, lData.compSwap or ""))
        end
        if lData.acq and lData.acq ~= "" then
            table.insert(infoLines, string.format("\n%s |cffffd100PHASE 4 NEARBY ACQUISITION:|r\n|cffffffff%s|r", IC_MAP, lData.acq))
        end
        if lData.hlKit and lData.hlKit ~= "" then
            table.insert(infoLines, string.format("\n%s |cffffd100PHASE 4 & 5 HEIRLOOM / KIT:|r\n|cffcceeff%s|r", IC_SHIELD, lData.hlKit))
        end
    end

    local cRules = (V.CompensationRules and V.CompensationRules[cls]) or {}
    if #cRules > 0 then
        table.insert(infoLines, "\n|cffffd100— CLASS COMPENSATION MATRIX —|r")
        for _, cr in ipairs(cRules) do
            if evalLvl >= (cr.minL or 1) - 5 and evalLvl <= (cr.maxL or 60) + 5 then
                table.insert(infoLines, string.format("• |cff00ffcc[%s]|r %s -> |cff22c55e%s (+%s%%)|r", cr.cat or "RULE", cr.cond or "", cr.shift or "", tostring(cr.gain or "")))
            end
        end
    end

    P1_InfoText:SetText(table.concat(infoLines, "\n"))
    P1_ScrollChild:SetHeight(math.max(500, P1_InfoText:GetStringHeight() + 30))
end

-- ============================================================================
-- PAGE 2: THE ARMOR MANNEQUIN & SLOT UPGRADE DRAWER (Phases 3, 4 & 5)
-- ============================================================================
local P2 = Pages[2]

local MannequinCard = CreateFrame("Frame", nil, P2, "BackdropTemplate")
MannequinCard:SetSize(410, 562)
MannequinCard:SetPoint("TOPLEFT", 10, -10)
SetStyledBackdrop(MannequinCard, 0.06, 0.06, 0.09, 0.96, 0.78, 0.62, 0.20, 1.0)

local MTitle = MannequinCard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
MTitle:SetPoint("TOP", 0, -10)
MTitle:SetText("|cffffd100ROYAL SUIT OF ARMOR MANNEQUIN|r  |cff22c55e(Click Any Slot)|r")

local ArmorStand = CreateFrame("Frame", nil, MannequinCard, "BackdropTemplate")
ArmorStand:SetSize(218, 434)
ArmorStand:SetPoint("TOP", MannequinCard, "TOP", 0, -34)
SetStyledBackdrop(ArmorStand, 0.08, 0.07, 0.06, 0.98, 0.48, 0.38, 0.18, 1.0)

local StandHalo = ArmorStand:CreateTexture(nil, "BACKGROUND", nil, 1)
StandHalo:SetSize(210, 210)
StandHalo:SetPoint("CENTER", ArmorStand, "CENTER", 0, 25)
StandHalo:SetTexture("Interface\\Cooldown\\star4")
StandHalo:SetBlendMode("ADD")
StandHalo:SetVertexColor(1.0, 0.78, 0.22, 0.28)

local MANNEQUIN_ARMOR_PARTS = {
    { x = 0,   y = -24,  w = 52, h = 52, tex = "Interface\\Icons\\INV_Helmet_03",     label = "FORGED GREATHELM" },
    { x = -54, y = -68,  w = 46, h = 46, tex = "Interface\\Icons\\INV_Shoulder_23",   label = "LEFT PAULDRON" },
    { x = 54,  y = -68,  w = 46, h = 46, tex = "Interface\\Icons\\INV_Shoulder_23",   label = "RIGHT PAULDRON" },
    { x = 0,   y = -88,  w = 68, h = 68, tex = "Interface\\Icons\\INV_Chest_Plate04", label = "ROYAL CUIRASS" },
    { x = -60, y = -134, w = 40, h = 40, tex = "Interface\\Icons\\INV_Gauntlets_04",  label = "LEFT GAUNTLET" },
    { x = 60,  y = -134, w = 40, h = 40, tex = "Interface\\Icons\\INV_Gauntlets_04",  label = "RIGHT GAUNTLET" },
    { x = 0,   y = -162, w = 52, h = 32, tex = "Interface\\Icons\\INV_Belt_13",       label = "GIRDLE" },
    { x = 0,   y = -202, w = 60, h = 60, tex = "Interface\\Icons\\INV_Pants_04",      label = "LEGPLATES" },
    { x = -24, y = -270, w = 42, h = 42, tex = "Interface\\Icons\\INV_Boots_Plate_04",label = "LEFT SABATON" },
    { x = 24,  y = -270, w = 42, h = 42, tex = "Interface\\Icons\\INV_Boots_Plate_04",label = "RIGHT SABATON" },
}

ArmorStand.partTexs = {}
for idx, mp in ipairs(MANNEQUIN_ARMOR_PARTS) do
    local pf = CreateFrame("Frame", nil, ArmorStand, "BackdropTemplate")
    pf:SetSize(mp.w, mp.h)
    pf:SetPoint("TOP", ArmorStand, "TOP", mp.x, mp.y)
    SetStyledBackdrop(pf, 0.12, 0.11, 0.09, 0.92, 0.72, 0.56, 0.20, 0.9)
    local pt = pf:CreateTexture(nil, "ARTWORK")
    pt:SetPoint("TOPLEFT", 3, -3)
    pt:SetPoint("BOTTOMRIGHT", -3, 3)
    pt:SetTexture(mp.tex)
    pt:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    ArmorStand.partTexs[idx] = pt
end

local StandBanner = ArmorStand:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
StandBanner:SetPoint("BOTTOM", ArmorStand, "BOTTOM", 0, 42)
StandBanner:SetWidth(204)
StandBanner:SetJustifyH("CENTER")
StandBanner:SetText("|cffffd100[FORGED ARMOR STAND]|r\n|cff22c55eGreen Glow|r = Nearby Upgrade\n|cffffd100Gold Glow|r = Eternal White Heirloom")

local StandStatus = ArmorStand:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
StandStatus:SetPoint("BOTTOM", ArmorStand, "BOTTOM", 0, 10)
StandStatus:SetWidth(204)
StandStatus:SetJustifyH("CENTER")
StandStatus:SetText("")

local SlotButtons = {}

local function CreatePaperDollSlotBtn(slotID, x, y)
    local sInfo = KF.SLOT_INFO[slotID]
    local b = CreateFrame("Button", "TheKingdomForgeSlotBtn" .. slotID, MannequinCard, "BackdropTemplate")
    b:SetSize(52, 52)
    b:SetPoint("TOPLEFT", MannequinCard, "TOPLEFT", x, y)
    SetStyledBackdrop(b, 0.08, 0.08, 0.12, 0.95, 0.45, 0.42, 0.35, 1.0)

    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetPoint("TOPLEFT", 4, -4)
    b.icon:SetPoint("BOTTOMRIGHT", -4, 4)
    b.icon:SetTexture(sInfo.emptyTex)

    b.lbl = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    b.lbl:SetPoint("BOTTOM", b, "BOTTOM", 0, 2)
    b.lbl:SetText(sInfo.name:sub(1, 8))

    b.kitBadge = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    b.kitBadge:SetPoint("TOPRIGHT", -2, -2)
    b.kitBadge:SetText(sInfo.kitSlot and "|cff00ffcc[KIT]|r" or "")

    b:SetScript("OnEnter", function(self)
        local d = self.slotData
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:ClearLines()
        GameTooltip:AddLine(string.format("|cffffd100[%s Slot]|r", sInfo.name), 1, 1, 1)
        if d and d.link then
            GameTooltip:AddLine("Currently Wearing: " .. d.link, 1, 1, 1)
        else
            GameTooltip:AddLine("|cff999999Currently Empty Slot|r", 0.7, 0.7, 0.7)
        end
        if sInfo.kitSlot then
            GameTooltip:AddLine("|cff00ffcc* Phase 5 Armor Kit Slot:|r Accepts Forceful or Mystic Armor Kits!", 0.2, 1, 0.8)
        end
        if d and d.bestUpgrade then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(string.format("|cff22c55e>> Available Upgrade:|r %s (iLvl %d, Req Lv %d)", d.bestUpgrade.name, d.bestUpgrade.ilvl, d.bestUpgrade.req), 0.2, 1, 0.4)
            GameTooltip:AddLine(string.format("Source: %s in %s (%s)", d.bestUpgrade.src, d.bestUpgrade.zone, d.bestUpgrade.npc), 0.85, 0.95, 1)
        end
        if d and d.heirloom then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(string.format("|cffffd100* Eternal White Heirloom:|r %s (NEVER Binds!)", d.heirloom.name), 1, 0.85, 0.2)
        end
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("|cff38bdf8Click to open Slot Upgrade & Heirloom Flyout Window!|r", 0.6, 0.85, 1)
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)

    b:SetScript("OnClick", function()
        local db = KF:EnsureDB()
        db.selectedSlot = slotID
        KF:RefreshPage2()
    end)

    SlotButtons[slotID] = b
end

for idx, sid in ipairs(KF.LEFT_SLOTS) do
    CreatePaperDollSlotBtn(sid, 16, -34 - (idx - 1) * 62)
end
for idx, sid in ipairs(KF.RIGHT_SLOTS) do
    CreatePaperDollSlotBtn(sid, 342, -34 - (idx - 1) * 62)
end
for idx, sid in ipairs(KF.WEAPON_SLOTS) do
    CreatePaperDollSlotBtn(sid, 112 + (idx - 1) * 68, -482)
end

local SlotFlyout = CreateFrame("Frame", nil, P2, "BackdropTemplate")
SlotFlyout:SetPoint("TOPLEFT", 428, -10)
SlotFlyout:SetPoint("BOTTOMRIGHT", -10, 10)
SetStyledBackdrop(SlotFlyout, 0.06, 0.07, 0.11, 0.97, 0.22, 0.85, 0.55, 1.0)

local FlyoutTitle = SlotFlyout:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
FlyoutTitle:SetPoint("TOPLEFT", 14, -12)
FlyoutTitle:SetText("|cffffd100SLOT UPGRADE & ETERNAL HEIRLOOM DRAWER|r")

local FlyoutSub = SlotFlyout:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
FlyoutSub:SetPoint("TOPLEFT", 14, -34)
FlyoutSub:SetWidth(530)
FlyoutSub:SetJustifyH("LEFT")
FlyoutSub:SetText("")

local FlyoutScroll = CreateFrame("ScrollFrame", "TheKingdomForgeP2Scroll", SlotFlyout, "UIPanelScrollFrameTemplate")
FlyoutScroll:SetPoint("TOPLEFT", 12, -82)
FlyoutScroll:SetPoint("BOTTOMRIGHT", -30, 12)
local FlyoutChild = CreateFrame("Frame", nil, FlyoutScroll)
FlyoutChild:SetSize(515, 900)
FlyoutScroll:SetScrollChild(FlyoutChild)

local FlyoutRows = {}
for i = 1, 18 do
    local row = CreateFrame("Frame", nil, FlyoutChild, "BackdropTemplate")
    row:SetSize(510, 68)
    row:SetPoint("TOPLEFT", 2, -(i - 1) * 72)
    SetStyledBackdrop(row, 0.09, 0.11, 0.16, 0.94, 0.38, 0.35, 0.22, 1.0)

    row.title = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.title:SetPoint("TOPLEFT", 10, -8)
    row.title:SetWidth(380)
    row.title:SetJustifyH("LEFT")

    row.sub = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.sub:SetPoint("TOPLEFT", 10, -26)
    row.sub:SetWidth(380)
    row.sub:SetJustifyH("LEFT")

    row.ench = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.ench:SetPoint("TOPLEFT", 10, -44)
    row.ench:SetWidth(490)
    row.ench:SetJustifyH("LEFT")

    row.mapBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    row.mapBtn:SetSize(108, 24)
    row.mapBtn:SetPoint("TOPRIGHT", -8, -8)
    row.mapBtn:SetText("Show on Map")

    row:Hide()
    FlyoutRows[i] = row
end

function KF:RefreshPage2()
    local db = self:EnsureDB()
    local _, pCls, _, _, pLvl = self:GetPlayerContext()
    local cls = db.selectedClass or pCls or "WARRIOR"
    local lvl = tonumber(db.selectedLevel) or pLvl or 1
    local selSlot = tonumber(db.selectedSlot) or 16

    local eqMap, upgCount = self:ScanEquipmentAndUpgrades(cls, lvl)

    StandStatus:SetText(string.format(
        "|cff00ffccCharacter Level %d|r\n|cff22c55e%d / 17 Slots Have Nearby Upgrades!|r",
        lvl, upgCount
    ))

    for _, sid in ipairs(self.ALL_SLOTS) do
        local b = SlotButtons[sid]
        local d = eqMap[sid]
        if b and d then
            b.slotData = d
            b.icon:SetTexture(d.tex)
            if sid == selSlot then
                SetStyledBackdrop(b, 0.14, 0.18, 0.26, 1.0, 0.2, 1.0, 0.6, 1.0)
                self:AttachGlowSignaler(b, 0.2, 1.0, 0.6, 3, 1.0)
            elseif d.status == "UPGRADE" then
                SetStyledBackdrop(b, 0.08, 0.14, 0.10, 0.96, 0.2, 0.95, 0.35, 1.0)
                self:AttachGlowSignaler(b, 0.15, 1.0, 0.30, 2, 0.85)
            elseif d.status == "HEIRLOOM" then
                SetStyledBackdrop(b, 0.14, 0.12, 0.06, 0.96, 1.0, 0.82, 0.15, 1.0)
                self:AttachGlowSignaler(b, 1.0, 0.82, 0.15, 2, 0.75)
            else
                SetStyledBackdrop(b, 0.08, 0.08, 0.12, 0.95, 0.42, 0.40, 0.35, 1.0)
                self:HideGlowSignaler(b)
            end
        end
    end

    local selData = eqMap[selSlot]
    local sInfo = self.SLOT_INFO[selSlot] or { name = "Slot" }
    FlyoutTitle:SetText(string.format("|cffffd100[%s] — UPGRADE, VENDOR, QUEST & HEIRLOOM FINDER (Lv %d)|r", string.upper(sInfo.name), lvl))

    local kitMsg = sInfo.kitSlot
        and "|cff00ffcc* Phase 5 Armor Kit Slot:|r Apply |cffffd100Forceful Armor Kit|r (LW + Dust + Str Elixir) or |cff38bdf8Mystic Armor Kit|r (LW + Dust + Mana Pot)!"
        or "|cff00ffcc* Phase 4 Eternal Heirloom Rule:|r Enchanting a White (Quality 1) Vendor/Quest item NEVER binds it—pass it across all 10 alts!"
    local wornMsg = (selData and selData.link) and ("Wearing: " .. selData.link) or "|cff999999Currently Empty Slot|r"
    FlyoutSub:SetText(wornMsg .. "\n" .. kitMsg)

    for i = 1, 18 do FlyoutRows[i]:Hide() end

    local cands = (selData and selData.candidates) or {}
    if #cands == 0 and V.SlotUpgrades and V.SlotUpgrades[selSlot] then
        cands = V.SlotUpgrades[selSlot]
    end

    for idx = 1, math.min(18, #cands) do
        local it = cands[idx]
        local row = FlyoutRows[idx]
        local qHex = self.QUALITY_HEX[it.q or 1] or "ffffff"
        local badge = (it.hlTier == "TIER_1_ETERNAL_WHITE_HEIRLOOM")
            and ("  |cffffd100[" .. IC_CROWN .. " TIER 1 ETERNAL WHITE HEIRLOOM]|r")
            or string.format("  |cff22c55e[%s]|r", it.src or "Source")

        row.title:SetText(string.format("|cff%s%s|r  |cffcccccc(iLvl %d • Req Lv %d)|r%s", qHex, it.name, it.ilvl or 1, it.req or 1, badge))
        row.sub:SetText(string.format("|cffffd100Where to Get:|r |cffffffff%s|r  •  |cff00ffcc%s|r %s", it.zone or "Azeroth", it.npc or "", it.coords or ""))

        if it.lowEnch and it.lowEnch ~= "" then
            row.ench:SetText("|cffc084fcHeirloom Enchant:|r " .. it.lowEnch)
        else
            row.ench:SetText("|cffaaaaaa" .. (it.how or "Equip or mail to Banker Liaison.") .. "|r")
        end

        row.mapBtn:SetScript("OnClick", function()
            local db2 = KF:EnsureDB()
            if it.zone and it.zone ~= "" and it.zone ~= "Azeroth" and it.zone ~= "Crafted" then
                db2.selectedZone = it.zone
            end
            db2.pinnedRouteTarget = { title = it.name, zone = it.zone, npc = it.npc, coords = it.coords }
            KF:SelectTab(3)
        end)

        row:Show()
    end
    FlyoutChild:SetHeight(math.max(480, math.min(18, #cands) * 72 + 20))
end

-- ============================================================================
-- PAGE 3: REVEALED KINGDOM ATLAS, FLIGHT POINTS, QUEST ROUTES & GATHERING (Phases 4 & 7)
-- Covers ALL 46+ Zones, Cities & Continent Maps of Eastern Kingdoms & Kalimdor!
-- ============================================================================
local P3 = Pages[3]

local EK_ZONES = V.EasternKingdomsZones or {
    "Elwynn Forest", "Stormwind City", "Westfall", "Redridge Mountains", "Duskwood", "Deadwind Pass",
    "Dun Morogh", "Ironforge", "Loch Modan", "Wetlands", "Badlands", "Searing Gorge",
    "Burning Steppes", "Swamp of Sorrows", "Blasted Lands", "Stranglethorn Vale",
    "Tirisfal Glades", "Undercity", "Silverpine Forest", "Hillsbrad Foothills",
    "Alterac Mountains", "Arathi Highlands", "The Hinterlands", "Western Plaguelands", "Eastern Plaguelands"
}

local KAL_ZONES = V.KalimdorZones or {
    "Teldrassil", "Darnassus", "Darkshore", "Ashenvale", "Stonetalon Mountains", "Desolace",
    "Durotar", "Orgrimmar", "Mulgore", "Thunder Bluff", "The Barrens", "Thousand Needles",
    "Dustwallow Marsh", "Feralas", "Tanaris", "Un'Goro Crater", "Silithus",
    "Azshara", "Felwood", "Moonglade", "Winterspring"
}

local activeContinentTab = "EK" -- "EK" or "KAL"

local ContBtnEK = CreateFrame("Button", nil, P3, "UIPanelButtonTemplate")
ContBtnEK:SetSize(235, 20)
ContBtnEK:SetPoint("TOPLEFT", 10, -4)
ContBtnEK:SetText("|cffffd100Eastern Kingdoms (25 Zones)|r")
ContBtnEK:SetScript("OnClick", function()
    activeContinentTab = "EK"
    KF:RefreshPage3()
end)

local ContBtnKAL = CreateFrame("Button", nil, P3, "UIPanelButtonTemplate")
ContBtnKAL:SetSize(235, 20)
ContBtnKAL:SetPoint("TOPLEFT", 250, -4)
ContBtnKAL:SetText("|cff38bdf8Western Kingdoms / Kalimdor (21 Zones)|r")
ContBtnKAL:SetScript("OnClick", function()
    activeContinentTab = "KAL"
    KF:RefreshPage3()
end)

local ContMapEKBtn = CreateFrame("Button", nil, P3, "UIPanelButtonTemplate")
ContMapEKBtn:SetSize(185, 20)
ContMapEKBtn:SetPoint("TOPLEFT", 490, -4)
ContMapEKBtn:SetText("|cff22c55eFull Eastern Kingdoms Map|r")
ContMapEKBtn:SetScript("OnClick", function()
    activeContinentTab = "EK"
    local db = KF:EnsureDB()
    db.selectedZone = "Eastern Kingdoms"
    KF:RefreshPage3()
end)

local ContMapKALBtn = CreateFrame("Button", nil, P3, "UIPanelButtonTemplate")
ContMapKALBtn:SetSize(185, 20)
ContMapKALBtn:SetPoint("TOPLEFT", 680, -4)
ContMapKALBtn:SetText("|cff22c55eFull Kalimdor Map|r")
ContMapKALBtn:SetScript("OnClick", function()
    activeContinentTab = "KAL"
    local db = KF:EnsureDB()
    db.selectedZone = "Kalimdor"
    KF:RefreshPage3()
end)

local MyZoneTopBtn = CreateFrame("Button", nil, P3, "UIPanelButtonTemplate")
MyZoneTopBtn:SetSize(120, 20)
MyZoneTopBtn:SetPoint("TOPLEFT", 870, -4)
MyZoneTopBtn:SetText("|cffffd100My Current Zone|r")
MyZoneTopBtn:SetScript("OnClick", function()
    local db = KF:EnsureDB()
    local _, _, _, _, _, _, curZone = KF:GetPlayerContext()
    db.selectedZone = curZone
    for _, zn in ipairs(KAL_ZONES) do
        if zn == curZone then activeContinentTab = "KAL" end
    end
    KF:RefreshPage3()
end)

local ZoneBtnSlots = {}
for idx = 1, 27 do
    local zb = CreateFrame("Button", nil, P3, "UIPanelButtonTemplate")
    local col = (idx - 1) % 9
    local row = math.floor((idx - 1) / 9)
    zb:SetSize(107, 18)
    zb:SetPoint("TOPLEFT", 10 + col * 109, -26 - row * 19)
    zb:SetScript("OnClick", function(self)
        if not self.zoneName then return end
        local db = KF:EnsureDB()
        db.selectedZone = self.zoneName
        KF:RefreshPage3()
    end)
    ZoneBtnSlots[idx] = zb
end

local FILTER_DEFS = {
    { key = "mapFilterFlight",   lbl = "Flight/Dungeons" },
    { key = "mapFilterQuests",   lbl = "Quest Route" },
    { key = "mapFilterHerbs",    lbl = "Herbs" },
    { key = "mapFilterMining",   lbl = "Mining" },
    { key = "mapFilterSkinning", lbl = "Skinning" },
    { key = "mapFilterChests",   lbl = "Chests/Rares" },
    { key = "fogRevealEnabled",  lbl = "Full Map Reveal" },
}

for idx, fd in ipairs(FILTER_DEFS) do
    local fb = CreateFrame("Button", nil, P3, "UIPanelButtonTemplate")
    fb:SetSize(136, 20)
    fb:SetPoint("TOPLEFT", 10 + (idx - 1) * 140, -84)
    fb:SetScript("OnClick", function()
        local db = KF:EnsureDB()
        db[fd.key] = not db[fd.key]
        KF:ApplyWorldMapFogReveal()
        KF:RefreshPage3()
    end)
    fb.filterDef = fd
    P3["FilterBtn" .. idx] = fb
end

local AtlasCanvas = CreateFrame("Frame", "TheKingdomForgeAtlasCanvas", P3, "BackdropTemplate")
AtlasCanvas:SetSize(602, 456)
AtlasCanvas:SetPoint("TOPLEFT", 10, -108)
SetStyledBackdrop(AtlasCanvas, 0.04, 0.05, 0.08, 0.99, 0.85, 0.68, 0.20, 1.0)

local AtlasBanner = AtlasCanvas:CreateFontString(nil, "OVERLAY", "GameFontNormal")
AtlasBanner:SetPoint("TOPLEFT", 10, -8)
AtlasBanner:SetText("|cffffd100REVEALED ZONE ATLAS|r")

local MyZoneBtn = CreateFrame("Button", nil, AtlasCanvas, "UIPanelButtonTemplate")
MyZoneBtn:SetSize(124, 20)
MyZoneBtn:SetPoint("TOPRIGHT", -8, -5)
MyZoneBtn:SetText("Zoom Out Continent")
MyZoneBtn:SetScript("OnClick", function()
    local db = KF:EnsureDB()
    db.selectedZone = (activeContinentTab == "KAL") and "Kalimdor" or "Eastern Kingdoms"
    KF:RefreshPage3()
end)

-- True 3:2 Aspect Ratio WoW Zone Map Viewport (590 x 393 default, 636 x 424 when Bigger Map is toggled!)
local MAP_W, MAP_H = 590, 393
local MapViewport = CreateFrame("Button", "TheKingdomForgeMapViewport", AtlasCanvas)
MapViewport:SetSize(MAP_W, MAP_H)
MapViewport:SetPoint("TOPLEFT", AtlasCanvas, "TOPLEFT", 6, -30)
MapViewport:SetClipsChildren(true)
MapViewport:RegisterForClicks("RightButtonUp")
MapViewport:SetScript("OnClick", function(_, button)
    if button == "RightButton" then
        local db = KF:EnsureDB()
        db.selectedZone = (activeContinentTab == "KAL") and "Kalimdor" or "Eastern Kingdoms"
        KF:RefreshPage3()
    end
end)

local BiggerAtlasBtn = CreateFrame("Button", nil, AtlasCanvas, "UIPanelButtonTemplate")
BiggerAtlasBtn:SetSize(108, 20)
BiggerAtlasBtn:SetPoint("RIGHT", MyZoneBtn, "LEFT", -4, 0)
BiggerAtlasBtn:SetText("|cff22c55e[+ Bigger Map]|r")
BiggerAtlasBtn:SetScript("OnClick", function()
    local db = KF:EnsureDB()
    db.largeForgeMap = not db.largeForgeMap
    if db.largeForgeMap then
        MainFrame:SetScale(1.18)
    else
        MainFrame:SetScale(1.0)
    end
    KF:RefreshPage3()
end)

-- Bottom Legend & Live Mouse Coordinate Bar inside AtlasCanvas
local MapFooter = AtlasCanvas:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
MapFooter:SetPoint("BOTTOMLEFT", AtlasCanvas, "BOTTOMLEFT", 10, 8)
MapFooter:SetWidth(580)
MapFooter:SetJustifyH("LEFT")
MapFooter:SetText("|cffffd100Legend:|r |cff38bdf8[FP]|r Flight/Boat  |cffffd100#1..10|r Quest Chain  |cffc084fc[D]|r Dungeon/Rare  |cff22c55eGreen|r Herbs  |cffffaa00Orange|r Ore  |cff00ffccClick Zone Arrows to Travel!|r")

local CursorCoordTxt = AtlasCanvas:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
CursorCoordTxt:SetPoint("TOPRIGHT", MapViewport, "BOTTOMRIGHT", -4, -6)
CursorCoordTxt:SetText("")

MapViewport:SetScript("OnUpdate", function(self)
    if not self:IsVisible() then return end
    local mx, my = GetCursorPosition()
    local scale = self:GetEffectiveScale()
    mx, my = mx / scale, my / scale
    local l, b, w, h = self:GetRect()
    if l and w and w > 0 and h and h > 0 then
        local cx = ((mx - l) / w) * 100
        local cy = (((b + h) - my) / h) * 100
        if cx >= 0 and cx <= 100 and cy >= 0 and cy <= 100 then
            CursorCoordTxt:SetText(string.format("|cffffd100Cursor:|r |cff00ffcc(%.1f, %.1f)|r", cx, cy))
        else
            CursorCoordTxt:SetText("")
        end
    end
end)

-- Pool for the 12 Base Map Tiles (BACKGROUND layer) and Revealed Sub-Zone Overlay Tiles (BORDER/ARTWORK layer)
local BaseTilePool = {}
local RevealTilePool = {}

local function AcquireBaseTile(idx)
    if BaseTilePool[idx] then return BaseTilePool[idx] end
    local t = MapViewport:CreateTexture(nil, "BACKGROUND", nil, 1)
    BaseTilePool[idx] = t
    return t
end

local function AcquireRevealTile(idx)
    if RevealTilePool[idx] then return RevealTilePool[idx] end
    local t = MapViewport:CreateTexture(nil, "BORDER", nil, 2)
    RevealTilePool[idx] = t
    return t
end

local function RenderRevealedZoneArtwork(uiMapID, revealFog)
    for _, t in ipairs(BaseTilePool) do t:Hide() end
    for _, t in ipairs(RevealTilePool) do t:Hide() end

    if not uiMapID or not C_Map or not C_Map.GetMapArtLayerTextures then return end

    local layers = C_Map.GetMapArtLayers and C_Map.GetMapArtLayers(uiMapID)
    local layerInfo = (layers and layers[1]) or { layerWidth = 1002, layerHeight = 668, tileWidth = 256, tileHeight = 256 }
    local LW = layerInfo.layerWidth or 1002
    local LH = layerInfo.layerHeight or 668
    local TW = layerInfo.tileWidth or 256
    local TH = layerInfo.tileHeight or 256

    local scaleX = MAP_W / LW
    local scaleY = MAP_H / LH

    local numCols = math.ceil(LW / TW)
    local numRows = math.ceil(LH / TH)
    local baseTexIDs = C_Map.GetMapArtLayerTextures(uiMapID, 1)

    if baseTexIDs and #baseTexIDs > 0 then
        local tIdx = 0
        for r = 1, numRows do
            local pxH = (r < numRows) and TH or (LH - (r - 1) * TH)
            if pxH <= 0 then pxH = TH end
            for c = 1, numCols do
                tIdx = tIdx + 1
                local fdid = baseTexIDs[tIdx]
                if fdid then
                    local pxW = (c < numCols) and TW or (LW - (c - 1) * TW)
                    if pxW <= 0 then pxW = TW end
                    local tile = AcquireBaseTile(tIdx)
                    tile:ClearAllPoints()
                    tile:SetPoint("TOPLEFT", MapViewport, "TOPLEFT", (c - 1) * TW * scaleX, -((r - 1) * TH * scaleY))
                    tile:SetSize(pxW * scaleX + 0.5, pxH * scaleY + 0.5)
                    tile:SetTexCoord(0, pxW / TW, 0, pxH / TH)
                    tile:SetTexture(fdid)
                    tile:SetVertexColor(1, 1, 1, 1)
                    tile:Show()
                end
            end
        end
    end

    -- Now render Explored Sub-Zones + Unexplored FogClearData Sub-Zones!
    local revIdx = 0
    local exploredKeys = {}

    local function DrawOverlayRect(width, height, offsetX, offsetY, fileList, rCol, gCol, bCol)
        local numWide = math.ceil(width / TW)
        local numTall = math.ceil(height / TH)
        for j = 1, numTall do
            local pH = (j < numTall) and TH or math.fmod(height, TH)
            if pH == 0 then pH = TH end
            local fH = 16
            while fH < pH do fH = fH * 2 end
            for k = 1, numWide do
                local pW = (k < numWide) and TW or math.fmod(width, TW)
                if pW == 0 then pW = TW end
                local fW = 16
                while fW < pW do fW = fW * 2 end
                local fdid = tonumber(fileList[(j - 1) * numWide + k])
                if fdid then
                    revIdx = revIdx + 1
                    local rt = AcquireRevealTile(revIdx)
                    rt:ClearAllPoints()
                    local ox = (offsetX + TW * (k - 1)) * scaleX
                    local oy = -((offsetY + TH * (j - 1)) * scaleY)
                    rt:SetPoint("TOPLEFT", MapViewport, "TOPLEFT", ox, oy)
                    rt:SetSize(pW * scaleX + 0.5, pH * scaleY + 0.5)
                    rt:SetTexCoord(0, pW / fW, 0, pH / fH)
                    rt:SetTexture(fdid)
                    rt:SetVertexColor(rCol or 1, gCol or 1, bCol or 1, 1)
                    rt:Show()
                end
            end
        end
    end

    local explored = C_MapExplorationInfo and C_MapExplorationInfo.GetExploredMapTextures and C_MapExplorationInfo.GetExploredMapTextures(uiMapID)
    if explored then
        for _, info in ipairs(explored) do
            local kInt = info.textureWidth * 2^39 + info.textureHeight * 2^26 + info.offsetX * 2^13 + info.offsetY
            local kStr = string.format("%d:%d:%d:%d", info.textureWidth, info.textureHeight, info.offsetX, info.offsetY)
            exploredKeys[kInt] = true
            exploredKeys[kStr] = true
            DrawOverlayRect(info.textureWidth, info.textureHeight, info.offsetX, info.offsetY, info.fileDataIDs or {}, 1, 1, 1)
        end
    end

    if revealFog then
        local artID = C_Map.GetMapArtID and C_Map.GetMapArtID(uiMapID)
        local fogTable = artID and V.FogClearData and V.FogClearData[artID]
        if fogTable then
            for key, filesStr in pairs(fogTable) do
                if not exploredKeys[key] then
                    local width, height, offsetX, offsetY = KF:ParseFogRectKey(key)
                    if width > 0 and height > 0 then
                        local fileList = { strsplit(",", filesStr) }
                        DrawOverlayRect(width, height, offsetX, offsetY, fileList, 1.0, 0.98, 0.94)
                    end
                end
            end
        end
    end
end

local AtlasPinPool = {}
local AtlasRouteSegments = {}

local function AcquireAtlasPin(i)
    if AtlasPinPool[i] then return AtlasPinPool[i] end
    local p = CreateFrame("Button", nil, MapViewport)
    p:SetSize(20, 20)
    p:SetFrameLevel(MapViewport:GetFrameLevel() + 12)

    p.glow = p:CreateTexture(nil, "BACKGROUND")
    p.glow:SetSize(28, 28)
    p.glow:SetPoint("CENTER")
    p.glow:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    p.glow:SetBlendMode("ADD")

    p.icon = p:CreateTexture(nil, "ARTWORK")
    p.icon:SetSize(15, 15)
    p.icon:SetPoint("CENTER")

    p.lbl = p:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    p.lbl:SetPoint("BOTTOM", p, "TOP", 0, 1)

    p:SetScript("OnEnter", function(self)
        if not self.pinData then return end
        local d = self.pinData
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:ClearLines()
        GameTooltip:AddLine(d.title or "Kingdom Pin", 1, 0.85, 0.1)
        if d.sub then GameTooltip:AddLine(d.sub, 0.4, 0.9, 1.0) end
        GameTooltip:AddLine(string.format("|cffffd100Coordinates:|r (%.1f, %.1f)", d.x or 50, d.y or 50), 1, 1, 1)
        if d.note then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(d.note, 0.88, 0.95, 0.88, true)
        end
        if d.destZone then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("|cff00ff96Left-Click Pin:|r Open Revealed Map of |cffffd100" .. d.destZone .. "|r!", 0.2, 1, 0.6)
        end
        GameTooltip:Show()
    end)
    p:SetScript("OnLeave", function() GameTooltip:Hide() end)

    p:SetScript("OnClick", function(self)
        if self.pinData and self.pinData.destZone then
            local db = KF:EnsureDB()
            db.selectedZone = self.pinData.destZone
            KF:RefreshPage3()
        end
    end)

    AtlasPinPool[i] = p
    return p
end

local function AcquireRouteDot(i)
    if AtlasRouteSegments[i] then return AtlasRouteSegments[i] end
    local dot = MapViewport:CreateTexture(nil, "OVERLAY")
    dot:SetSize(4, 4)
    dot:SetTexture(WHITE)
    dot:SetVertexColor(1.0, 0.88, 0.10, 0.95)
    AtlasRouteSegments[i] = dot
    return dot
end

local P3_Right = CreateFrame("Frame", nil, P3, "BackdropTemplate")
P3_Right:SetPoint("TOPLEFT", 618, -108)
P3_Right:SetPoint("BOTTOMRIGHT", -10, 10)
SetStyledBackdrop(P3_Right, 0.06, 0.07, 0.11, 0.96, 0.25, 0.75, 0.95, 1.0)

local P3_Scroll = CreateFrame("ScrollFrame", "TheKingdomForgeP3Scroll", P3_Right, "UIPanelScrollFrameTemplate")
P3_Scroll:SetPoint("TOPLEFT", 8, -8)
P3_Scroll:SetPoint("BOTTOMRIGHT", -28, 8)
local P3_Child = CreateFrame("Frame", nil, P3_Scroll)
P3_Child:SetSize(336, 900)
P3_Scroll:SetScrollChild(P3_Child)

local P3_InfoTxt = P3_Child:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
P3_InfoTxt:SetPoint("TOPLEFT", 4, -4)
P3_InfoTxt:SetWidth(328)
P3_InfoTxt:SetJustifyH("LEFT")
P3_InfoTxt:SetJustifyV("TOP")
P3_InfoTxt:SetSpacing(3)

local function ApplyPinVisual(pin, pd, baseSize)
    local sz = baseSize or 20
    if pd.kind == "QUEST_TURNIN" or pd.isComplete then
        sz = baseSize + 6
    elseif pd.kind and pd.kind:find("Flight") or pd.kind == "FLIGHT" then
        sz = baseSize + 4
    elseif pd.kind == "Dungeon" or pd.kind == "Raid" or pd.kind == "Dunraid" then
        sz = baseSize + 6
    end
    pin:SetSize(sz, sz)
    pin.icon:SetSize(sz - 2, sz - 2)
    pin.glow:SetSize(sz + 10, sz + 10)

    pin.icon:SetRotation(0)
    pin.icon:SetTexCoord(0, 1, 0, 1)
    if pin.icon.SetDesaturated then
        pin.icon:SetDesaturated(pd.desaturate and true or false)
    end

    local usedAtlas = false
    if pd.atlas and pin.icon.SetAtlas then
        local ok = pcall(pin.icon.SetAtlas, pin.icon, pd.atlas)
        if ok then usedAtlas = true end
    end
    if not usedAtlas then
        pin.icon:SetTexture(pd.icon or "Interface\\TaxiFrame\\UI-Taxi-Icon-Yellow")
        if pd.texCoord then
            pin.icon:SetTexCoord(pd.texCoord[1], pd.texCoord[2], pd.texCoord[3], pd.texCoord[4])
        end
    end
    if pd.rot and pd.rot ~= 0 and pin.icon.SetRotation then
        pcall(pin.icon.SetRotation, pin.icon, pd.rot)
    end

    local c = pd.color or { 1, 0.82, 0 }
    pin.glow:SetVertexColor(c[1], c[2], c[3], 0.95)

    if pd.kind == "PLAYER" then
        pin.lbl:SetText("|cff00ff96[YOU]|r")
    elseif pd.kind == "QUEST_TURNIN" or pd.isComplete then
        -- Completed Quests always display a prominent Question Mark (?) on the map!
        if pd.step then
            pin.lbl:SetText("|cff22c55e[?|r |cffffd100#" .. pd.step .. "|cff22c55e]|r")
        else
            pin.lbl:SetText("|cff22c55e[?]|r")
        end
    elseif pd.kind == "QUEST_UNFINISHED_TURNIN" then
        pin.lbl:SetText("|cffaaaaaa[?]|r")
    elseif pd.kind == "QUEST_AVAILABLE" and pd.step then
        pin.lbl:SetText("|cffffd100[! #" .. pd.step .. "]|r")
    elseif pd.step then
        pin.lbl:SetText("|cff00ffcc#" .. pd.step .. "|r")
    elseif pd.kind == "FlightA" then
        pin.lbl:SetText("|cff38bdf8[A-FP]|r")
    elseif pd.kind == "FlightH" then
        pin.lbl:SetText("|cffff4444[H-FP]|r")
    elseif pd.kind == "FLIGHT" or (pd.kind and pd.kind:find("Flight")) then
        pin.lbl:SetText("|cffffd100[FP]|r")
    elseif pd.kind == "Dungeon" or pd.kind == "Raid" or pd.kind == "Dunraid" then
        pin.lbl:SetText("|cffc084fc[D]|r")
    else
        pin.lbl:SetText("")
    end
end

function KF:RefreshPage3()
    local db = self:EnsureDB()
    if db.largeForgeMap then
        MAP_W, MAP_H = 636, 424
        AtlasCanvas:SetSize(650, 456)
        MapViewport:SetSize(MAP_W, MAP_H)
        P3_Right:SetPoint("TOPLEFT", 666, -108)
        BiggerAtlasBtn:SetText("|cffffd100[- Normal Size]|r")
    else
        MAP_W, MAP_H = 590, 393
        AtlasCanvas:SetSize(602, 456)
        MapViewport:SetSize(MAP_W, MAP_H)
        P3_Right:SetPoint("TOPLEFT", 618, -108)
        BiggerAtlasBtn:SetText("|cff22c55e[+ Bigger Map]|r")
    end

    for idx = 1, #FILTER_DEFS do
        local fb = P3["FilterBtn" .. idx]
        if fb and fb.filterDef then
            local on = db[fb.filterDef.key]
            fb:SetText((on and "|cff22c55e[ON] " or "|cff777777[OFF] ") .. fb.filterDef.lbl .. "|r")
        end
    end

    local pins, route, activeZone, uiMapID = self:BuildZoneInteractiveAtlas(db.selectedZone)
    db.selectedZone = activeZone

    -- Auto-switch continent tab if activeZone belongs to Kalimdor or Eastern Kingdoms
    if activeZone == "Kalimdor" then
        activeContinentTab = "KAL"
    elseif activeZone == "Eastern Kingdoms" then
        activeContinentTab = "EK"
    else
        for _, zn in ipairs(KAL_ZONES) do
            if zn == activeZone then activeContinentTab = "KAL"; break end
        end
        for _, zn in ipairs(EK_ZONES) do
            if zn == activeZone then activeContinentTab = "EK"; break end
        end
    end

    if activeContinentTab == "EK" then
        self:AttachGlowSignaler(ContBtnEK, 1.0, 0.82, 0.15, 2, 0.85)
        self:HideGlowSignaler(ContBtnKAL)
    else
        self:AttachGlowSignaler(ContBtnKAL, 0.25, 0.80, 1.0, 2, 0.85)
        self:HideGlowSignaler(ContBtnEK)
    end

    local zList = (activeContinentTab == "KAL") and KAL_ZONES or EK_ZONES
    for idx = 1, 27 do
        local zb = ZoneBtnSlots[idx]
        local zName = zList[idx]
        if zName then
            zb.zoneName = zName
            zb:SetText(zName:sub(1, 15))
            zb:Show()
            if zName == activeZone then
                self:AttachGlowSignaler(zb, 1.0, 0.82, 0.15, 2, 0.90)
            else
                self:HideGlowSignaler(zb)
            end
        else
            zb.zoneName = nil
            zb:Hide()
            self:HideGlowSignaler(zb)
        end
    end

    -- Render the 12 Base Map Tiles + All 3,657 FogClear Revealed Sub-Zone Overlays!
    RenderRevealedZoneArtwork(uiMapID, db.fogRevealEnabled)

    AtlasBanner:SetText(string.format(
        "|cffffd100REVEALED KINGDOM ATLAS:|r |cff00ffcc%s|r |cffcccccc(MapID %d • %d Pins • %s)|r",
        activeZone, uiMapID or 0, #pins, db.fogRevealEnabled and "|cff22c55e100% Revealed|r" or "|cffffaa00Standard Fog|r"
    ))

    for _, p in ipairs(AtlasPinPool) do p:Hide() end
    for _, d in ipairs(AtlasRouteSegments) do d:Hide() end

    local dotIdx = 0
    for i = 1, (#route - 1) do
        local a, b = route[i], route[i + 1]
        local ax, ay = (a.x / 100.0) * MAP_W, -((a.y / 100.0) * MAP_H)
        local bx, by = (b.x / 100.0) * MAP_W, -((b.y / 100.0) * MAP_H)
        local steps = 14
        for s = 1, steps do
            dotIdx = dotIdx + 1
            local dot = AcquireRouteDot(dotIdx)
            local t = s / (steps + 1)
            dot:ClearAllPoints()
            dot:SetPoint("CENTER", MapViewport, "TOPLEFT", ax + (bx - ax) * t, ay + (by - ay) * t)
            dot:Show()
        end
    end

    for idx, pd in ipairs(pins) do
        local pin = AcquireAtlasPin(idx)
        pin.pinData = pd
        local px = (pd.x / 100.0) * MAP_W
        local py = -((pd.y / 100.0) * MAP_H)
        pin:ClearAllPoints()
        pin:SetPoint("CENTER", MapViewport, "TOPLEFT", px, py)
        ApplyPinVisual(pin, pd, 18)
        pin:Show()
    end

    local rLines = {}
    if db.pinnedRouteTarget then
        local pt = db.pinnedRouteTarget
        table.insert(rLines, string.format("%s |cffffd100PINNED UPGRADE TARGET:|r\n|cff22c55e%s|r\nZone: %s  •  %s %s\n", IC_MAP, pt.title or "", pt.zone or "", pt.npc or "", pt.coords or ""))
    end

    -- List Flight Points, Dungeons & Travel Connections in Zone
    local lPois = (V.LeatrixPOIs and V.LeatrixPOIs[activeZone]) or {}
    if #lPois > 0 then
        table.insert(rLines, string.format("%s |cffffd100FLIGHT POINTS, DUNGEONS & TRAVEL (%s):|r", IC_MAP, activeZone))
        for _, lp in ipairs(lPois) do
            if lp.kind ~= "Spirit" then
                local extra = (lp.minL and lp.minL > 0) and string.format(" (Lv %d-%d)", lp.minL, lp.maxL) or (lp.sub ~= "" and (" - " .. lp.sub) or "")
                table.insert(rLines, string.format("• |cff38bdf8[%s]|r |cffffffff%s%s|r at |cffffd100(%.1f, %.1f)|r", lp.kind, lp.title, extra, lp.x, lp.y))
            end
        end
        table.insert(rLines, "")
    end

    table.insert(rLines, string.format("%s |cffffd100ALONG-THE-WAY QUEST ROUTE (%s):|r", IC_BOLT, activeZone))
    if #route == 0 then
        table.insert(rLines, "|cff999999No filtered quests in this zone. Click another zone tab above!|r")
    else
        for _, q in ipairs(route) do
            table.insert(rLines, string.format("  |cffffd100Step #%d:|r |cffffffff%s|r (Lv %d)\n     └ NPC: |cff00ffcc%s|r at |cffffff00(%.1f, %.1f)|r", q.step, q.name, q.lvl or 1, q.npc ~= "" and q.npc or "Objective", q.x, q.y))
        end
    end

    table.insert(rLines, "\n" .. IC_HERB .. " |cffffd100ZONE GATHERING, SKINNING & LOOT HOTSPOTS:|r")
    local hCount = 0
    for _, h in ipairs(V.GatheringAndLootHotspots or {}) do
        if h.zone == activeZone and hCount < 16 then
            hCount = hCount + 1
            table.insert(rLines, string.format("• |cff22c55e[%s]|r |cffffffff%s|r (%d spawns, Req %d)\n   └ Best Cluster: |cffffd100(%.1f, %.1f)|r • %s", h.cat, h.name, h.count or 1, h.req or 1, h.x, h.y, h.alt or ""))
        end
    end

    P3_InfoTxt:SetText(table.concat(rLines, "\n"))
    P3_Child:SetHeight(math.max(480, P3_InfoTxt:GetStringHeight() + 30))
end

-- ============================================================================
-- PAGE 4: ANIMATED ROYAL LIAISON, ADVENTURE PATHS, ALT ANALYZER & 70/30 AH
-- Clean Rectangular Perimeter Glows (Zero Overlapping Circle Rings!)
-- ============================================================================
local P4 = Pages[4]

local LiaisonCard = CreateFrame("Frame", nil, P4, "BackdropTemplate")
LiaisonCard:SetSize(310, 215)
LiaisonCard:SetPoint("TOPLEFT", 10, -10)
SetStyledBackdrop(LiaisonCard, 0.07, 0.06, 0.12, 0.97, 0.95, 0.76, 0.22, 1.0)

-- Clean Rectangular Portrait Frame for Queen Ava (No ugly stretched circle ring!)
local LiaisonPortraitBox = CreateFrame("Frame", nil, LiaisonCard, "BackdropTemplate")
LiaisonPortraitBox:SetSize(112, 185)
LiaisonPortraitBox:SetPoint("TOPLEFT", LiaisonCard, "TOPLEFT", 12, -14)
SetStyledBackdrop(LiaisonPortraitBox, 0.04, 0.03, 0.07, 0.98, 0.92, 0.74, 0.20, 1.0)
KF:AttachGlowSignaler(LiaisonPortraitBox, 1.0, 0.82, 0.18, 2, 0.75)

local LiaisonHalo = LiaisonPortraitBox:CreateTexture(nil, "BACKGROUND")
LiaisonHalo:SetSize(104, 104)
LiaisonHalo:SetPoint("CENTER", LiaisonPortraitBox, "CENTER", 0, 10)
LiaisonHalo:SetTexture("Interface\\Cooldown\\star4")
LiaisonHalo:SetBlendMode("ADD")
LiaisonHalo:SetVertexColor(1.0, 0.80, 0.25, 0.28)

local LiaisonModelFrame = CreateFrame("PlayerModel", "TheKingdomForgeLiaisonModel", LiaisonPortraitBox)
LiaisonModelFrame:SetPoint("TOPLEFT", 4, -4)
LiaisonModelFrame:SetPoint("BOTTOMRIGHT", -4, 4)

local LiaisonTitle = LiaisonCard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
LiaisonTitle:SetPoint("TOPLEFT", 132, -14)
LiaisonTitle:SetText(IC_CROWN .. " |cffffd100QUEEN AVA|r\n|cff00ffccRoyal Kingdom Liaison|r")

local LiaisonSpeech = LiaisonCard:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
LiaisonSpeech:SetPoint("TOPLEFT", 132, -52)
LiaisonSpeech:SetWidth(166)
LiaisonSpeech:SetJustifyH("LEFT")
LiaisonSpeech:SetSpacing(2)
LiaisonSpeech:SetText("\"Welcome to The Kingdom Forge, My King! Choose your Adventure Path on the right and I will synchronize every talent, heirloom, profession, and 70/30 AH flip!\"")

-- Top-Right: 3 Glowing Adventure Path Selector Cards (Dynamic Non-Overlapping Text Anchors!)
local PATH_CARDS_DATA = {
    {
        id = "KINGDOM_EMPIRE",
        title = IC_CROWN .. " PATH I: THE KINGDOM FORGE",
        sub = "10-Alt Guild & 70/30 AH Gold Empire",
        desc = "Start with Hunter Skinner (Lv 1->7) to seed 15s & LW Greens -> Banker Mage (Lv 1->5) for DE & Alchemy -> Blacksmith Rods -> Tailor Reagent Bags -> Forceful/Mystic Kits!",
        color = { 1.0, 0.82, 0.15 }
    },
    {
        id = "SOLO_SOVEREIGN",
        title = IC_SWORD .. " PATH II: THE LONE SOVEREIGN",
        sub = "Single-Main 1-60 Hyper-Leveling",
        desc = "Focus 100% on 1 Main Character (+ optional Lv 5 Banker): uses Tier Over-Stacking (>5 pts/row), Phase 3 Compensation swaps, and nearby Quest/Vendor upgrades.",
        color = { 0.20, 0.95, 0.55 }
    },
    {
        id = "PVP_CRUCIBLE",
        title = IC_SHIELD .. " PATH III: WARLORD'S CRUCIBLE",
        sub = "PvP / Battleground & Twink Conquest",
        desc = "Builds god-tier Enchanted Tier 1 White Eternal Heirlooms (+100 HP Chest, Fiery Weapon, Minor Speed Boots, 4x Forceful/Mystic Armor Kits) to dominate every bracket!",
        color = { 0.95, 0.35, 0.35 }
    },
}

local PathCards = {}
for idx, pcd in ipairs(PATH_CARDS_DATA) do
    local card = CreateFrame("Button", nil, P4, "BackdropTemplate")
    card:SetSize(218, 215)
    card:SetPoint("TOPLEFT", 328 + (idx - 1) * 222, -10)
    SetStyledBackdrop(card, 0.08, 0.09, 0.14, 0.96, pcd.color[1], pcd.color[2], pcd.color[3], 1.0)

    card.title = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    card.title:SetPoint("TOPLEFT", 10, -10)
    card.title:SetWidth(198)
    card.title:SetJustifyH("LEFT")
    card.title:SetText("|cffffd100" .. pcd.title .. "|r")

    -- Anchor subtitle directly below title so multi-line titles NEVER overlap!
    card.sub = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    card.sub:SetPoint("TOPLEFT", card.title, "BOTTOMLEFT", 0, -4)
    card.sub:SetWidth(198)
    card.sub:SetJustifyH("LEFT")
    card.sub:SetText("|cff00ffcc" .. pcd.sub .. "|r")

    card.desc = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    card.desc:SetPoint("TOPLEFT", card.sub, "BOTTOMLEFT", 0, -6)
    card.desc:SetWidth(198)
    card.desc:SetJustifyH("LEFT")
    card.desc:SetSpacing(2)
    card.desc:SetText(pcd.desc)

    card.badge = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    card.badge:SetPoint("BOTTOM", 0, 10)
    card.badge:SetText("[CLICK TO ACTIVATE PATH]")

    card:SetScript("OnClick", function()
        local db = KF:EnsureDB()
        db.adventurePath = pcd.id
        KF:RefreshPage4()
    end)
    card.pathData = pcd
    PathCards[idx] = card
end

-- Middle Bar: Live "WHO TO LEVEL NEXT" Priority Banner + Pre-Register Alt Input Box
local AnalyzerBanner = CreateFrame("Frame", nil, P4, "BackdropTemplate")
AnalyzerBanner:SetSize(980, 68)
AnalyzerBanner:SetPoint("TOPLEFT", 10, -232)
SetStyledBackdrop(AnalyzerBanner, 0.06, 0.11, 0.09, 0.97, 0.22, 0.95, 0.55, 1.0)
KF:AttachGlowSignaler(AnalyzerBanner, 0.2, 1.0, 0.5, 2, 0.70)

local NextAltText = AnalyzerBanner:CreateFontString(nil, "OVERLAY", "GameFontNormal")
NextAltText:SetPoint("TOPLEFT", 12, -8)
NextAltText:SetWidth(670)
NextAltText:SetJustifyH("LEFT")
NextAltText:SetText("")

local AltInputLbl = AnalyzerBanner:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
AltInputLbl:SetPoint("TOPRIGHT", -165, -8)
AltInputLbl:SetText("|cffffd100Add Planned Alt Name:|r")

local AltNameBox = CreateFrame("EditBox", "TheKingdomForgeAltBox", AnalyzerBanner, "InputBoxTemplate")
AltNameBox:SetSize(130, 22)
AltNameBox:SetPoint("TOPRIGHT", -155, -24)
AltNameBox:SetAutoFocus(false)
AltNameBox:SetText("HunterPioneer")

local selectedPlanSlot = 3
local SlotCycleBtn = CreateFrame("Button", nil, AnalyzerBanner, "UIPanelButtonTemplate")
SlotCycleBtn:SetSize(68, 22)
SlotCycleBtn:SetPoint("LEFT", AltNameBox, "RIGHT", 6, 0)
SlotCycleBtn:SetText("Slot #3")
SlotCycleBtn:SetScript("OnClick", function(self)
    selectedPlanSlot = (selectedPlanSlot % 10) + 1
    self:SetText("Slot #" .. selectedPlanSlot)
end)

local AddAltBtn = CreateFrame("Button", nil, AnalyzerBanner, "UIPanelButtonTemplate")
AddAltBtn:SetSize(72, 22)
AddAltBtn:SetPoint("LEFT", SlotCycleBtn, "RIGHT", 4, 0)
AddAltBtn:SetText("Register")
AddAltBtn:SetScript("OnClick", function()
    local nm = AltNameBox:GetText()
    KF:RegisterPlannedAlt(nm, selectedPlanSlot)
    AltNameBox:ClearFocus()
    KF:RefreshPage4()
end)

local SeedAll10Btn = CreateFrame("Button", nil, AnalyzerBanner, "UIPanelButtonTemplate")
SeedAll10Btn:SetSize(145, 20)
SeedAll10Btn:SetPoint("BOTTOMRIGHT", -8, 4)
SeedAll10Btn:SetText("Load All 10 Guild Slots")
SeedAll10Btn:SetScript("OnClick", function()
    for s = 1, 10 do
        local rInfo = V.RoyalGuildRoster and V.RoyalGuildRoster[s]
        local defaultName = rInfo and ("Slot" .. s .. "_" .. rInfo.cls:match("^(%S+)")) or ("Alt" .. s)
        KF:RegisterPlannedAlt(defaultName, s)
    end
    KF:RefreshPage4()
end)

-- Bottom Split Area: Left (Auto-Detected Alt Roster & Ignition Order) + Right (70% Guild / 30% AH Cash Register & DE Matrix)
local P4_Left = CreateFrame("Frame", nil, P4, "BackdropTemplate")
P4_Left:SetSize(486, 260)
P4_Left:SetPoint("TOPLEFT", 10, -306)
SetStyledBackdrop(P4_Left, 0.06, 0.07, 0.11, 0.96, 0.55, 0.45, 0.20, 1.0)

local P4_LScroll = CreateFrame("ScrollFrame", "TheKingdomForgeP4LScroll", P4_Left, "UIPanelScrollFrameTemplate")
P4_LScroll:SetPoint("TOPLEFT", 8, -8)
P4_LScroll:SetPoint("BOTTOMRIGHT", -28, 8)
local P4_LChild = CreateFrame("Frame", nil, P4_LScroll)
P4_LChild:SetSize(446, 900)
P4_LScroll:SetScrollChild(P4_LChild)

local P4_LeftTxt = P4_LChild:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
P4_LeftTxt:SetPoint("TOPLEFT", 4, -4)
P4_LeftTxt:SetWidth(438)
P4_LeftTxt:SetJustifyH("LEFT")
P4_LeftTxt:SetJustifyV("TOP")
P4_LeftTxt:SetSpacing(3)

local P4_Right = CreateFrame("Frame", nil, P4, "BackdropTemplate")
P4_Right:SetSize(486, 260)
P4_Right:SetPoint("TOPRIGHT", -10, -306)
SetStyledBackdrop(P4_Right, 0.06, 0.07, 0.11, 0.96, 0.22, 0.85, 0.55, 1.0)

local P4_RScroll = CreateFrame("ScrollFrame", "TheKingdomForgeP4RScroll", P4_Right, "UIPanelScrollFrameTemplate")
P4_RScroll:SetPoint("TOPLEFT", 8, -8)
P4_RScroll:SetPoint("BOTTOMRIGHT", -28, 8)
local P4_RChild = CreateFrame("Frame", nil, P4_RScroll)
P4_RChild:SetSize(446, 900)
P4_RScroll:SetScrollChild(P4_RChild)

local P4_RightTxt = P4_RChild:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
P4_RightTxt:SetPoint("TOPLEFT", 4, -4)
P4_RightTxt:SetWidth(438)
P4_RightTxt:SetJustifyH("LEFT")
P4_RightTxt:SetJustifyV("TOP")
P4_RightTxt:SetSpacing(3)

function KF:RefreshPage4()
    local db = self:EnsureDB()
    pcall(function()
        LiaisonModelFrame:SetUnit("player")
        LiaisonModelFrame:SetFacing(0.35)
    end)

    for _, card in ipairs(PathCards) do
        local pcd = card.pathData
        if db.adventurePath == pcd.id then
            card.badge:SetText("|cff22c55e>> ACTIVE ROYAL PATH <<|r")
            SetStyledBackdrop(card, 0.11, 0.14, 0.20, 0.98, pcd.color[1], pcd.color[2], pcd.color[3], 1.0)
            self:AttachGlowSignaler(card, pcd.color[1], pcd.color[2], pcd.color[3], 3, 1.0)
        else
            card.badge:SetText("|cff888888[Click to Activate Path]|r")
            SetStyledBackdrop(card, 0.06, 0.07, 0.10, 0.92, pcd.color[1] * 0.45, pcd.color[2] * 0.45, pcd.color[3] * 0.45, 0.75)
            self:HideGlowSignaler(card)
        end
    end

    local bestEntry, scoredRoster, bankerAlert, avgLvl = self:EvaluateEmpireProgression()

    if db.adventurePath == "SOLO_SOVEREIGN" then
        local nm, _, clsL, _, lvl, _, zn = self:GetPlayerContext()
        LiaisonSpeech:SetText(string.format("\"Solo Sovereign Mode active, My King! Focus on %s (Lv %d in %s) and keep 1 Lv 5 Banker in the capital for Heirlooms & AH flips!\"", nm, lvl, zn))
        NextAltText:SetText(string.format(
            "%s |cffffd100SOLO SOVEREIGN FOCUS:|r |cff00ffcc%s (Level %d %s)|r  •  Next Milestone: Level %d\n|cff22c55eAction:|r Check Tab 1 for >5-Pt Tier Over-Stacking and Tab 2 for glowing nearby Quest/Vendor upgrades!",
            IC_CROWN, nm, lvl, clsL, math.min(60, lvl + 2)
        ))
    elseif db.adventurePath == "PVP_CRUCIBLE" then
        local nm, _, clsL, _, lvl = self:GetPlayerContext()
        LiaisonSpeech:SetText("\"Warlord's Crucible active! Let's forge your Tier 1 Eternal White Heirlooms + 4x Forceful/Mystic Armor Kits to crush the bracket!\"")
        NextAltText:SetText(string.format(
            "%s |cffff4444PVP CRUCIBLE TARGET:|r |cffffd100%s (Lv %d %s — Bracket %d9)|r\n|cff22c55eAction:|r Equip Enchanted White Heirlooms (+100 HP Chest, Minor Speed Boots) + 4/4 Forceful or Mystic Armor Kits!",
            IC_SWORD, nm, lvl, clsL, math.floor(lvl / 10)
        ))
    else
        LiaisonSpeech:SetText("\"The Kingdom Forge 10-Alt Empire is online! Follow our Ignition Order below: Hunter Skinner Lv 1->7 first, then Banker Lv 1->5!\"")
        if bestEntry and bestEntry.char then
            local bc = bestEntry.char
            NextAltText:SetText(string.format(
                "%s |cffffd100RECOMMENDED NEXT TOON TO LEVEL:|r |cff22c55e%s (%s)|r  •  |cffffff00Level %d -> Level %d (~%d mins)|r  [Priority Score: %.1f]\n%s\n|cff00ffccWhy:|r %s",
                IC_CROWN, bc.name, bc.class or "Alt", bestEntry.fromLvl, bestEntry.toLvl, bestEntry.estMins, bestEntry.score,
                bankerAlert, bestEntry.reason
            ))
        end
    end

    local lLines = {}
    table.insert(lLines, string.format("%s |cffffd100YOUR DETECTED & PLANNED ALT ROSTER (Avg Lv %.1f):|r", IC_CROWN, avgLvl or 1))
    for idx, entry in ipairs(scoredRoster) do
        local c = entry.char
        local statusTag = c.isPlanned and "|cff999999[PLANNED]|r" or string.format("|cff22c55e[SYNCED • %d%% Rested • %s]|r", c.restedPct or 0, self:FormatCoin(c.money or 0))
        local profStr = c.profsText or ""
        if c.profs and #c.profs > 0 then
            local pNames = {}
            for _, p in ipairs(c.profs) do table.insert(pNames, string.format("%s (%d/%d)", p.name, p.skill, p.max)) end
            profStr = table.concat(pNames, ", ")
        end
        table.insert(lLines, string.format(
            "%d. |cffffd100%s|r (Lv %d %s) %s\n   └ Profs: |cff00ffcc%s|r  •  Next Target: |cffffff00Lv %d|r (Score: %.1f)",
            idx, c.name, c.level or 1, c.class or "", statusTag, profStr ~= "" and profStr or "Train at Lv 2/5", entry.toLvl, entry.score
        ))
    end

    table.insert(lLines, "\n" .. IC_BOLT .. " |cffffd100DAY-1 BOOTSTRAP IGNITION SEQUENCE (WHO TO LEVEL FIRST):|r")
    for _, ig in ipairs(V.IgnitionSequence or {}) do
        local cleanUnlock = (ig.unlock or ""):gsub("[^\0-\127]+", "")
        table.insert(lLines, string.format(
            "• |cff22c55e%s|r (%s, ~%dm)\n  └ %s\n  └ |cffffd100Math:|r %s",
            ig.label, ig.profs, ig.mins or 30, cleanUnlock, ig.math
        ))
    end

    table.insert(lLines, "\n" .. IC_CAMP .. " |cffffd10011-PROFESSION PORTABLE CAMPING STATIONS (Forever 1.60.1):|r")
    for _, cm in ipairs(V.CampingMatrix or {}) do
        if cm.tier <= 2 then
            table.insert(lLines, string.format("• |cff00ffcc[%s Skill %d]|r |cffffffff%s|r: %s", cm.prof, cm.req, cm.name, cm.buff))
        end
    end

    P4_LeftTxt:SetText(table.concat(lLines, "\n"))
    P4_LChild:SetHeight(math.max(400, P4_LeftTxt:GetStringHeight() + 30))

    local rLines = {}
    table.insert(rLines, IC_COIN .. " |cffffd100LIVE BAG SCANNER: 70% GUILD / 30% AUCTION HOUSE SPLIT:|r")
    local bagSplits = self:ScanBagsFor7030Split()
    if #bagSplits == 0 then
        table.insert(rLines, "|cff999999No raw gathering commodities or BoE greens currently in bags. See Master 70/30 Ledger below!|r")
    else
        for _, sp in ipairs(bagSplits) do
            table.insert(rLines, string.format(
                "• |cffffffff%s (Total: %d)|r -> |cff22c55eKeep/Mail 70%% (%d)|r  |  |cffffd100Sell 30%% (%d)|r\n   ├ 70%% Guild: %s\n   └ 30%% AH: %s",
                sp.name, sp.total, sp.keep70, sp.sell30, sp.g70Text, sp.ah30Text
            ))
        end
    end

    table.insert(rLines, "\n" .. IC_BAG .. " |cffffd100MASTER 70% GUILD / 30% AH LIQUIDITY TABLE:|r")
    for _, ld in ipairs(V.AH7030Ledger or {}) do
        table.insert(rLines, string.format(
            "• |cff00ffcc[%s • %s]|r |cffffffff%s|r (+%d%% Margin)\n   ├ |cff22c55e70%% Guild:|r %s\n   └ |cffffd10030%% AH Flip:|r %s",
            ld.band, ld.prof, ld.item, ld.margin or 250, ld.g70, ld.ah30
        ))
    end

    table.insert(rLines, "\n" .. IC_DE .. " |cffffd100BANKER DISENCHANTING SKILL GATE MATRIX:|r")
    for _, de in ipairs(V.DisenchantMatrix or {}) do
        table.insert(rLines, string.format(
            "• |cffc084fcDE Skill %d (Banker Lv %d)|r -> %s (%s)\n   ├ Crafts: %s\n   └ Yields: |cff22c55e%s|r",
            de.reqSkill, de.reqLvl, de.eqLvl, de.ilvl, de.greens, de.armorYield
        ))
    end

    P4_RightTxt:SetText(table.concat(rLines, "\n"))
    P4_RChild:SetHeight(math.max(400, P4_RightTxt:GetStringHeight() + 30))
end

-- ============================================================================
-- TAB SWITCHER & MINIMAP CREST BUTTON
-- ============================================================================
function KF:SelectTab(tabID)
    local db = self:EnsureDB()
    tabID = tonumber(tabID) or 1
    db.activeTab = tabID
    for i = 1, 4 do
        local tb = TabButtons[i]
        local pg = Pages[i]
        if i == tabID then
            SetStyledBackdrop(tb, 0.16, 0.19, 0.28, 1.0, 1.0, 0.82, 0.18, 1.0)
            tb.txt:SetTextColor(1.0, 0.86, 0.22)
            self:AttachGlowSignaler(tb, 1.0, 0.82, 0.18, 2, 0.90)
            pg:Show()
        else
            SetStyledBackdrop(tb, 0.08, 0.09, 0.14, 0.92, 0.40, 0.35, 0.18, 1.0)
            tb.txt:SetTextColor(0.80, 0.82, 0.86)
            self:HideGlowSignaler(tb)
            pg:Hide()
        end
    end
    self:RefreshActivePage()
end

function KF:RefreshActivePage()
    if not MainFrame:IsShown() then return end
    local db = self:EnsureDB()
    local t = db.activeTab or 1
    if t == 1 then self:RefreshPage1()
    elseif t == 2 then self:RefreshPage2()
    elseif t == 3 then self:RefreshPage3()
    elseif t == 4 then self:RefreshPage4()
    end
end

-- Draggable Glowing Minimap Button
local MiniBtn = CreateFrame("Button", "TheKingdomForgeMiniBtn", Minimap)
MiniBtn:SetSize(34, 34)
MiniBtn:SetFrameStrata("MEDIUM")
MiniBtn:SetFrameLevel(9)
MiniBtn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

local miniIcon = MiniBtn:CreateTexture(nil, "BACKGROUND")
miniIcon:SetSize(20, 20)
miniIcon:SetPoint("CENTER", 0, 0)
miniIcon:SetTexture("Interface\\Icons\\INV_Crown_01")
miniIcon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

local miniBorder = MiniBtn:CreateTexture(nil, "OVERLAY")
miniBorder:SetSize(54, 54)
miniBorder:SetPoint("TOPLEFT", 0, 0)
miniBorder:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

local function UpdateMiniPos()
    local db = KF:EnsureDB()
    local rad = math.rad(db.minimapAngle or 225)
    MiniBtn:ClearAllPoints()
    MiniBtn:SetPoint("CENTER", Minimap, "CENTER", math.cos(rad) * 80, math.sin(rad) * 80)
end

MiniBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
MiniBtn:RegisterForDrag("LeftButton")
MiniBtn:SetScript("OnDragStart", function(self)
    self:SetScript("OnUpdate", function()
        local mx, my = Minimap:GetCenter()
        local cx, cy = GetCursorPosition()
        local scale = Minimap:GetEffectiveScale()
        cx, cy = cx / scale, cy / scale
        local db = KF:EnsureDB()
        db.minimapAngle = math.deg(math.atan2(cy - my, cx - mx))
        UpdateMiniPos()
    end)
end)
MiniBtn:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
MiniBtn:SetScript("OnClick", function(_, btn)
    if btn == "RightButton" then
        MainFrame:Show()
        KF:SelectTab(4)
    else
        if MainFrame:IsShown() then MainFrame:Hide() else MainFrame:Show(); KF:SelectTab(KF:EnsureDB().activeTab or 1) end
    end
end)
MiniBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:ClearLines()
    GameTooltip:AddLine("|cffffd100The Kingdom Forge|r |cff00ffcc(v1.60.1)|r", 1, 1, 1)
    GameTooltip:AddLine("|cff22c55eLeft-Click:|r Toggle Main Kingdom Window", 1, 1, 1)
    GameTooltip:AddLine("|cffffd100Right-Click:|r Open Queen Ava Liaison & Alt Analyzer", 1, 1, 1)
    GameTooltip:AddLine("|cffccccccDrag:|r Move around Minimap", 0.7, 0.7, 0.7)
    GameTooltip:Show()
end)
MiniBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

UpdateMiniPos()

SLASH_THEKINGDOMFORGE1 = "/kf"
SLASH_THEKINGDOMFORGE2 = "/kingdomforge"
SlashCmdList["THEKINGDOMFORGE"] = function(msg)
    msg = (msg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
    MainFrame:Show()
    if msg == "1" or msg == "talents" then KF:SelectTab(1)
    elseif msg == "2" or msg == "gear" or msg == "mannequin" then KF:SelectTab(2)
    elseif msg == "3" or msg == "map" or msg == "atlas" then KF:SelectTab(3)
    elseif msg == "4" or msg == "ava" or msg == "empire" then KF:SelectTab(4)
    else KF:SelectTab(KF:EnsureDB().activeTab or 1)
    end
end

-- ============================================================================
-- 6. NATIVE WOW UI WORLD MAP ('M' KEY — WorldMapFrame) FULL OVERLAY ENGINE
-- Mirrors all Revealed Fog Tiles, Flight Points, Dungeons, Quest Route Chains,
-- and Gathering/Rare/Chest Hotspots directly onto the native 'M' World Map!
-- ============================================================================
local WM_FogOverlay = nil
local WM_Overlay = nil
local WM_ControlBar = nil
local WM_FogTilePool = {}
local WM_PinPool = {}
local WM_RouteDotPool = {}
local lastWMMapID = nil
local lastWMW, lastWMH = 0, 0

local function GetNativeWorldMapCanvas()
    if not WorldMapFrame then return nil end
    if WorldMapFrame.GetCanvas then
        local ok, c = pcall(WorldMapFrame.GetCanvas, WorldMapFrame)
        if ok and c then return c end
    end
    if WorldMapFrame.ScrollContainer and WorldMapFrame.ScrollContainer.Child then
        return WorldMapFrame.ScrollContainer.Child
    end
    return WorldMapDetailFrame or WorldMapButton
end

local function AcquireWMFogTile(i)
    if WM_FogTilePool[i] then return WM_FogTilePool[i] end
    local t = WM_FogOverlay:CreateTexture(nil, "ARTWORK", nil, 1)
    WM_FogTilePool[i] = t
    return t
end

local function AcquireWMRouteDot(i)
    if WM_RouteDotPool[i] then return WM_RouteDotPool[i] end
    local d = WM_Overlay:CreateTexture(nil, "ARTWORK", nil, 4)
    d:SetSize(6, 6)
    d:SetTexture(WHITE)
    d:SetVertexColor(1.0, 0.88, 0.10, 0.95)
    WM_RouteDotPool[i] = d
    return d
end

local function AcquireWMPin(i)
    if WM_PinPool[i] then return WM_PinPool[i] end
    local p = CreateFrame("Button", nil, WM_Overlay)
    p:SetSize(24, 24)
    p:SetFrameStrata("HIGH")
    p:SetFrameLevel(110)

    p.glow = p:CreateTexture(nil, "BACKGROUND")
    p.glow:SetSize(34, 34)
    p.glow:SetPoint("CENTER")
    p.glow:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    p.glow:SetBlendMode("ADD")

    p.icon = p:CreateTexture(nil, "ARTWORK")
    p.icon:SetSize(20, 20)
    p.icon:SetPoint("CENTER")

    p.lbl = p:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    p.lbl:SetPoint("BOTTOM", p, "TOP", 0, 1)

    p:SetScript("OnEnter", function(self)
        if not self.pinData then return end
        local d = self.pinData
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:ClearLines()
        GameTooltip:AddLine("|cffffd100[Kingdom Forge]|r " .. (d.title or "Pin"), 1, 0.85, 0.1)
        if d.sub then GameTooltip:AddLine(d.sub, 0.4, 0.9, 1.0) end
        GameTooltip:AddLine(string.format("|cffffd100Coordinates:|r (%.1f, %.1f)", d.x or 50, d.y or 50), 1, 1, 1)
        if d.note then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(d.note, 0.88, 0.95, 0.88, true)
        end
        if d.destZone then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("|cff00ff96Left-Click Pin:|r Switch World Map to |cffffd100" .. d.destZone .. "|r!", 0.2, 1, 0.6)
        end
        GameTooltip:Show()
    end)
    p:SetScript("OnLeave", function() GameTooltip:Hide() end)

    p:SetScript("OnClick", function(self)
        if self.pinData and self.pinData.destZone then
            local destMapID = V.ZoneToUIMapID and V.ZoneToUIMapID[self.pinData.destZone]
            if destMapID and WorldMapFrame and WorldMapFrame.SetMapID then
                pcall(WorldMapFrame.SetMapID, WorldMapFrame, destMapID)
            end
        end
    end)

    WM_PinPool[i] = p
    return p
end

function KF:ApplyNativeWorldMapScale()
    if not WorldMapFrame then return end
    local db = self:EnsureDB()
    local sc = tonumber(db.worldMapScale) or 1.0
    if sc < 0.8 or sc > 1.6 then sc = 1.0 end
    pcall(function()
        WorldMapFrame:SetScale(sc)
    end)
    if WM_ControlBar and WM_ControlBar.sizeBtn then
        local pct = math.floor(sc * 100 + 0.5)
        if pct > 100 then
            WM_ControlBar.sizeBtn:SetText(string.format("|cff22c55e[Map Size: %d%%]|r", pct))
        else
            WM_ControlBar.sizeBtn:SetText("|cffffd100[+ Bigger Map]|r")
        end
    end
end

function KF:RefreshNativeWorldMapOverlay(force)
    if not WorldMapFrame or not WorldMapFrame:IsVisible() then return end
    local canvas = GetNativeWorldMapCanvas()
    if not canvas then return end

    local cw, ch = canvas:GetWidth() or 0, canvas:GetHeight() or 0
    if cw <= 10 or ch <= 10 then return end

    local db = self:EnsureDB()
    self:ApplyNativeWorldMapScale()

    local mapID = (WorldMapFrame.GetMapID and WorldMapFrame:GetMapID()) or WorldMapFrame.mapID or 0
    local needFogRedraw = force or (mapID ~= lastWMMapID) or (math.abs(cw - lastWMW) >= 1) or (math.abs(ch - lastWMH) >= 1)
    lastWMMapID = mapID
    lastWMW, lastWMH = cw, ch

    if not WM_FogOverlay then
        WM_FogOverlay = CreateFrame("Frame", "TheKingdomForgeWorldMapFogOverlay", canvas)
    end
    WM_FogOverlay:SetParent(canvas)
    WM_FogOverlay:ClearAllPoints()
    WM_FogOverlay:SetAllPoints(canvas)
    WM_FogOverlay:SetFrameStrata("MEDIUM")
    WM_FogOverlay:SetFrameLevel(15)
    WM_FogOverlay:Show()

    if not WM_Overlay then
        WM_Overlay = CreateFrame("Frame", "TheKingdomForgeWorldMapOverlay", canvas)
    end
    WM_Overlay:SetParent(canvas)
    WM_Overlay:ClearAllPoints()
    WM_Overlay:SetAllPoints(canvas)
    WM_Overlay:SetFrameStrata("HIGH")
    WM_Overlay:SetFrameLevel(100)
    WM_Overlay:Show()

    -- Docked Control Bar on WorldMapFrame (with Bigger Map Toggle!)
    if not WM_ControlBar then
        WM_ControlBar = CreateFrame("Frame", "TheKingdomForgeWorldMapBar", WorldMapFrame, "BackdropTemplate")
        WM_ControlBar:SetSize(860, 26)
        WM_ControlBar:SetPoint("BOTTOM", WorldMapFrame, "BOTTOM", 0, 6)
        WM_ControlBar:SetFrameStrata("FULLSCREEN_DIALOG")
        WM_ControlBar:SetFrameLevel(99)
        SetStyledBackdrop(WM_ControlBar, 0.05, 0.06, 0.10, 0.94, 0.92, 0.74, 0.20, 1.0)

        local lbl = WM_ControlBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lbl:SetPoint("LEFT", 8, 0)
        lbl:SetText(IC_CROWN .. " |cffffd100Kingdom Forge:|r")

        local WM_BTNS = {
            { key = "mapFilterFlight",   lbl = "FP/Dung",     w = 66 },
            { key = "mapFilterQuests",   lbl = "Quest Route", w = 80 },
            { key = "mapFilterHerbs",    lbl = "Herbs",       w = 52 },
            { key = "mapFilterMining",   lbl = "Mining",      w = 56 },
            { key = "mapFilterSkinning", lbl = "Skinning",    w = 64 },
            { key = "mapFilterChests",   lbl = "Chests/Rare", w = 78 },
            { key = "fogRevealEnabled",  lbl = "Reveal Fog",  w = 74 },
        }
        local bx = 110
        WM_ControlBar.filterBtns = {}
        for idx, bd in ipairs(WM_BTNS) do
            local b = CreateFrame("Button", nil, WM_ControlBar, "UIPanelButtonTemplate")
            b:SetSize(bd.w, 20)
            b:SetPoint("LEFT", bx, 0)
            b.bDef = bd
            b:SetScript("OnClick", function()
                local d2 = KF:EnsureDB()
                d2[bd.key] = not d2[bd.key]
                KF:ApplyWorldMapFogReveal()
                KF:RefreshNativeWorldMapOverlay(true)
                if MainFrame:IsShown() and d2.activeTab == 3 then
                    KF:RefreshPage3()
                end
            end)
            WM_ControlBar.filterBtns[idx] = b
            bx = bx + bd.w + 3
        end

        -- [+ Bigger Map] Toggle Button on the Native WoW 'M' World Map!
        local sizeBtn = CreateFrame("Button", nil, WM_ControlBar, "UIPanelButtonTemplate")
        sizeBtn:SetSize(112, 20)
        sizeBtn:SetPoint("LEFT", bx + 2, 0)
        sizeBtn:SetText("|cffffd100[+ Bigger Map]|r")
        sizeBtn:SetScript("OnClick", function()
            local d2 = KF:EnsureDB()
            local cur = tonumber(d2.worldMapScale) or 1.0
            if cur < 1.10 then
                d2.worldMapScale = 1.20
            elseif cur < 1.30 then
                d2.worldMapScale = 1.35
            else
                d2.worldMapScale = 1.0
            end
            KF:ApplyNativeWorldMapScale()
            KF:RefreshNativeWorldMapOverlay(true)
        end)
        WM_ControlBar.sizeBtn = sizeBtn

        local openForgeBtn = CreateFrame("Button", nil, WM_ControlBar, "UIPanelButtonTemplate")
        openForgeBtn:SetSize(96, 20)
        openForgeBtn:SetPoint("RIGHT", -6, 0)
        openForgeBtn:SetText("|cffffd100Open Forge|r")
        openForgeBtn:SetScript("OnClick", function()
            MainFrame:Show()
            KF:SelectTab(3)
        end)
    end

    for _, b in ipairs(WM_ControlBar.filterBtns or {}) do
        local on = db[b.bDef.key]
        b:SetText((on and "|cff22c55e" or "|cff777777") .. b.bDef.lbl .. "|r")
    end

    -- 1. Redraw FogClearData overlay tiles when mapID or fog toggle changes
    if needFogRedraw then
        for _, t in ipairs(WM_FogTilePool) do t:Hide() end
        self:ApplyWorldMapFogReveal()
        if db.fogRevealEnabled and mapID and mapID > 0 and C_Map and C_Map.GetMapArtID then
            local artID = C_Map.GetMapArtID(mapID)
            local fogTable = artID and V.FogClearData and V.FogClearData[artID]
            if fogTable then
                local layers = C_Map.GetMapArtLayers and C_Map.GetMapArtLayers(mapID)
                local layerInfo = (layers and layers[1]) or { layerWidth = 1002, layerHeight = 668, tileWidth = 256, tileHeight = 256 }
                local LW = layerInfo.layerWidth or 1002
                local LH = layerInfo.layerHeight or 668
                local TW = layerInfo.tileWidth or 256
                local TH = layerInfo.tileHeight or 256
                local scaleX = cw / LW
                local scaleY = ch / LH

                local exploredKeys = {}
                local explored = C_MapExplorationInfo and C_MapExplorationInfo.GetExploredMapTextures and C_MapExplorationInfo.GetExploredMapTextures(mapID)
                if explored then
                    for _, info in ipairs(explored) do
                        local kInt = info.textureWidth * 2^39 + info.textureHeight * 2^26 + info.offsetX * 2^13 + info.offsetY
                        local kStr = string.format("%d:%d:%d:%d", info.textureWidth, info.textureHeight, info.offsetX, info.offsetY)
                        exploredKeys[kInt] = true
                        exploredKeys[kStr] = true
                    end
                end

                local fIdx = 0
                for key, filesStr in pairs(fogTable) do
                    if not exploredKeys[key] then
                        local width, height, offsetX, offsetY = KF:ParseFogRectKey(key)
                        if width > 0 and height > 0 then
                            local fileList = { strsplit(",", filesStr) }
                            local numWide = math.ceil(width / TW)
                            local numTall = math.ceil(height / TH)
                            for j = 1, numTall do
                                local pH = (j < numTall) and TH or math.fmod(height, TH)
                                if pH == 0 then pH = TH end
                                local fH = 16
                                while fH < pH do fH = fH * 2 end
                                for k = 1, numWide do
                                    local pW = (k < numWide) and TW or math.fmod(width, TW)
                                    if pW == 0 then pW = TW end
                                    local fW = 16
                                    while fW < pW do fW = fW * 2 end
                                    local fdid = tonumber(fileList[(j - 1) * numWide + k])
                                    if fdid then
                                        fIdx = fIdx + 1
                                        local ft = AcquireWMFogTile(fIdx)
                                        ft:ClearAllPoints()
                                        ft:SetPoint("TOPLEFT", WM_FogOverlay, "TOPLEFT", (offsetX + TW * (k - 1)) * scaleX, -((offsetY + TH * (j - 1)) * scaleY))
                                        ft:SetSize(pW * scaleX + 0.5, pH * scaleY + 0.5)
                                        ft:SetTexCoord(0, pW / fW, 0, pH / fH)
                                        ft:SetTexture(fdid)
                                        ft:SetVertexColor(1, 1, 1, 1)
                                        ft:Show()
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    -- 2. Render all Kingdom Forge Pins & Dotted Quest Chain for this mapID's zone!
    for _, d in ipairs(WM_RouteDotPool) do d:Hide() end
    for _, p in ipairs(WM_PinPool) do p:Hide() end

    local zoneName = (V.UIMapIDToZone and V.UIMapIDToZone[mapID]) or nil
    if not zoneName and C_Map and C_Map.GetMapInfo and mapID > 0 then
        local mInfo = C_Map.GetMapInfo(mapID)
        if mInfo and mInfo.name then zoneName = mInfo.name end
    end
    if not zoneName then return end

    local pins, route = self:BuildZoneInteractiveAtlas(zoneName)

    local dotIdx = 0
    for i = 1, (#route - 1) do
        local a, b = route[i], route[i + 1]
        local ax, ay = (a.x / 100.0) * cw, -((a.y / 100.0) * ch)
        local bx, by = (b.x / 100.0) * cw, -((b.y / 100.0) * ch)
        local steps = 16
        for s = 1, steps do
            dotIdx = dotIdx + 1
            local dot = AcquireWMRouteDot(dotIdx)
            local t = s / (steps + 1)
            dot:ClearAllPoints()
            dot:SetPoint("CENTER", WM_Overlay, "TOPLEFT", ax + (bx - ax) * t, ay + (by - ay) * t)
            dot:Show()
        end
    end

    local cScale = (WorldMapFrame.GetCanvasScale and WorldMapFrame:GetCanvasScale()) or 1
    if cScale <= 0 then cScale = 1 end
    local basePinSz = math.max(18, math.min(30, math.floor(22 / cScale + 0.5)))

    for idx, pd in ipairs(pins) do
        if pd.kind ~= "PLAYER" then
            local pin = AcquireWMPin(idx)
            pin.pinData = pd
            -- Keep pin scale at 1.0 so SetPoint (px, py) is in the exact pixel space of WM_Overlay!
            pin:SetScale(1.0)
            local px = (pd.x / 100.0) * cw
            local py = -((pd.y / 100.0) * ch)
            pin:ClearAllPoints()
            pin:SetPoint("CENTER", WM_Overlay, "TOPLEFT", px, py)
            ApplyPinVisual(pin, pd, basePinSz)
            pin:Show()
        end
    end
end

-- Watcher Frame that updates the native 'M' WorldMapFrame whenever it is opened or changes zone!
local WMWatcher = CreateFrame("Frame")
local wmAccum = 0
WMWatcher:SetScript("OnUpdate", function(_, elapsed)
    wmAccum = wmAccum + (elapsed or 0.016)
    if wmAccum < 0.35 then return end
    wmAccum = 0
    if WorldMapFrame and WorldMapFrame:IsVisible() then
        KF:RefreshNativeWorldMapOverlay(false)
    else
        lastWMMapID = nil
    end
end)

