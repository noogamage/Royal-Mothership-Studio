-- ============================================================================
-- ROYAL COMPASS HUD & LIVE PRIORITY QUEST TRACKER DROPDOWN (RoyalCompassHUD.lua)
-- Features:
--   1. Top Draggable Compass HUD: Live Zone, (X, Y) Coords, Directional Arrow &
--      Yard Distance to Active Quest / Flight Master, XP/hr, TTL, Bags & Gold.
--   2. Right-Side Live Priority Quest Tracker Dropdown:
--      - Automatically reads all active quests in your Classic Quest Log
--      - Sorts them by Priority (Ready to Turn In -> Current Zone Nearest -> Level)
--      - Left-Click any quest: Locks Compass Arrow & plots Direct Route on Map ('M')!
--      - Click [Map] button (or Shift-Click): Opens 'M' World Map to that quest's route!
--      - Right-Click any quest: Opens Quest Log details for that quest!
-- ============================================================================
local ADDON_NAME = ...

local BUILTIN_FLIGHTS = {
    [1429] = { { name = "Stormwind Flight Master", x = 66.2, y = 62.4, fac = "Alliance" } },
    [1453] = { { name = "Stormwind Gryphon Master", x = 66.2, y = 62.4, fac = "Alliance" } },
    [1436] = { { name = "Sentinel Hill", x = 56.6, y = 52.6, fac = "Alliance" } },
    [1433] = { { name = "Lakeshire", x = 30.6, y = 59.4, fac = "Alliance" } },
    [1431] = { { name = "Darkshire", x = 77.5, y = 44.3, fac = "Alliance" } },
    [1426] = { { name = "Ironforge Airfield", x = 55.5, y = 47.8, fac = "Alliance" } },
    [1455] = { { name = "Ironforge Gryphon Master", x = 55.5, y = 47.8, fac = "Alliance" } },
    [1432] = { { name = "Thelsamar", x = 33.9, y = 50.9, fac = "Alliance" } },
    [1437] = { { name = "Menethil Harbor", x = 9.5, y = 59.7, fac = "Alliance" } },
    [1438] = { { name = "Rut'theran Village", x = 58.4, y = 94.0, fac = "Alliance" } },
    [1457] = { { name = "Darnassus Portal / Rut'theran", x = 36.6, y = 85.9, fac = "Alliance" } },
    [1439] = { { name = "Auberdine", x = 36.3, y = 45.6, fac = "Alliance" } },
    [1440] = { { name = "Astranaar", x = 34.4, y = 48.0, fac = "Alliance" }, { name = "Splintertree Post", x = 73.2, y = 61.6, fac = "Horde" } },
    [1411] = { { name = "Orgrimmar Wind Rider", x = 45.2, y = 63.8, fac = "Horde" } },
    [1454] = { { name = "Orgrimmar Wind Rider", x = 45.2, y = 63.8, fac = "Horde" } },
    [1412] = { { name = "Thunder Bluff Wind Rider", x = 46.8, y = 50.0, fac = "Horde" } },
    [1413] = { { name = "The Crossroads", x = 51.5, y = 30.3, fac = "Horde" }, { name = "Ratchet", x = 63.1, y = 37.2, fac = "Neutral" }, { name = "Camp Taurajo", x = 44.5, y = 59.1, fac = "Horde" } },
    [1420] = { { name = "Undercity Bat Handler", x = 63.3, y = 48.5, fac = "Horde" } },
    [1421] = { { name = "The Sepulcher", x = 45.6, y = 42.6, fac = "Horde" } },
    [1424] = { { name = "Southshore", x = 49.3, y = 52.3, fac = "Alliance" }, { name = "Tarren Mill", x = 60.1, y = 18.6, fac = "Horde" } },
    [1417] = { { name = "Refuge Pointe", x = 45.8, y = 46.1, fac = "Alliance" }, { name = "Hammerfall", x = 73.0, y = 32.7, fac = "Horde" } },
    [1434] = { { name = "Booty Bay", x = 27.5, y = 77.8, fac = "Neutral" }, { name = "Grom'gol Base Camp", x = 32.5, y = 29.4, fac = "Horde" } },
    [1446] = { { name = "Gadgetzan", x = 51.0, y = 29.3, fac = "Neutral" } },
}

local sessionStartTime = GetTime()
local sessionStartXP = nil
local sessionGainedXP = 0
local lastKnownXP = nil
local lastKnownMaxXP = nil
local customWaypoint = nil
local targetIndex = 1
local selectedQuestKey = nil

function _G.RoyalCompassHUD_SetQuestTarget(qTitle, qZone, qx, qy)
    if qTitle and qx and qy then
        customWaypoint = {
            name = qTitle,
            zone = qZone,
            x = tonumber(qx) or 50,
            y = tonumber(qy) or 50,
            isQuest = true,
        }
        selectedQuestKey = qTitle
    end
end

local function FormatGold(copper)
    copper = tonumber(copper) or 0
    local g = math.floor(copper / 10000)
    local s = math.floor((copper % 10000) / 100)
    local c = copper % 100
    if g > 0 then
        return string.format("|cffffd100%dg|r |cffc7c7cf%ds|r", g, s)
    else
        return string.format("|cffc7c7cf%ds|r |cffeda55f%dc|r", s, c)
    end
end

local function GetDirectionArrow(dx, dy)
    local angle = math.deg(math.atan2(-dy, dx))
    if angle < 0 then angle = angle + 360 end
    if angle >= 337.5 or angle < 22.5 then return "|cff00ffcc[E ->]|r"
    elseif angle < 67.5 then return "|cff00ffcc[NE ^>]|r"
    elseif angle < 112.5 then return "|cff00ffcc[N ^]|r"
    elseif angle < 157.5 then return "|cff00ffcc[NW <^]|r"
    elseif angle < 202.5 then return "|cff00ffcc[W <-]|r"
    elseif angle < 247.5 then return "|cff00ffcc[SW <v]|r"
    elseif angle < 292.5 then return "|cff00ffcc[S v]|r"
    else return "|cff00ffcc[SE v>]|r"
    end
end

local function GetZoneFlightTargets(mapID, zoneName)
    local results = {}
    local V = _G.TheKingdomForgeVault
    if V and V.LeatrixPOIs then
        local list = V.LeatrixPOIs[mapID] or V.LeatrixPOIs[zoneName] or {}
        for _, p in ipairs(list) do
            if p.kind and (p.kind:find("Flight") or p.kind == "Dungeon" or p.kind:find("Travel")) then
                table.insert(results, { name = p.title, x = p.x, y = p.y, kind = p.kind })
            end
        end
    end
    if #results == 0 and BUILTIN_FLIGHTS[mapID] then
        for _, f in ipairs(BUILTIN_FLIGHTS[mapID]) do
            table.insert(results, { name = f.name, x = f.x, y = f.y, kind = "Flight" })
        end
    end
    return results
end

local function ApplyBoxBackdrop(f, bgR, bgG, bgB, bgA, brR, brG, brB, brA)
    if not f.SetBackdrop then return end
    f:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 8, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    f:SetBackdropColor(bgR, bgG, bgB, bgA or 0.92)
    f:SetBackdropBorderColor(brR, brG, brB, brA or 1.0)
end

-- ============================================================================
-- 1. TOP ROYAL COMPASS HUD BAR
-- ============================================================================
local HUD = CreateFrame("Button", "RoyalCompassHUDFrame", UIParent, "BackdropTemplate")
HUD:SetSize(680, 28)
HUD:SetPoint("TOP", UIParent, "TOP", 0, -6)
HUD:SetFrameStrata("MEDIUM")
HUD:SetFrameLevel(20)
HUD:SetMovable(true)
HUD:EnableMouse(true)
HUD:RegisterForDrag("LeftButton")
HUD:RegisterForClicks("LeftButtonUp", "RightButtonUp")
ApplyBoxBackdrop(HUD, 0.05, 0.06, 0.10, 0.92, 0.95, 0.78, 0.22, 1.0)

local topGlow = HUD:CreateTexture(nil, "OVERLAY")
topGlow:SetTexture("Interface\\Buttons\\WHITE8X8")
topGlow:SetVertexColor(1.0, 0.84, 0.20, 0.55)
topGlow:SetPoint("TOPLEFT", 4, -2)
topGlow:SetPoint("TOPRIGHT", -4, -2)
topGlow:SetHeight(1)

local hudText = HUD:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
hudText:SetPoint("CENTER", 0, 0)
hudText:SetText("|cffffd100[Royal Compass HUD]|r Initializing...")

HUD:SetScript("OnDragStart", function(self) self:StartMoving() end)
HUD:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local pt, _, relPt, x, y = self:GetPoint()
    RoyalCompassHUDDB = RoyalCompassHUDDB or {}
    RoyalCompassHUDDB.point = { pt, relPt, x, y }
end)

HUD:SetScript("OnClick", function(_, button)
    if button == "RightButton" then
        if _G.TheKingdomForge and _G.TheKingdomForge.SelectTab then
            if _G.TheKingdomForgeMainFrame then _G.TheKingdomForgeMainFrame:Show() end
            _G.TheKingdomForge:SelectTab(3)
        elseif WorldMapFrame then
            ToggleWorldMap()
        end
    else
        customWaypoint = nil
        selectedQuestKey = nil
        targetIndex = targetIndex + 1
    end
end)

HUD:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
    GameTooltip:ClearLines()
    GameTooltip:AddLine("|TInterface\\Icons\\INV_Crown_01:14:14:0:0:64:64:4:60:4:60|t |cffffd100Royal Compass HUD|r", 1, 0.85, 0.15)
    GameTooltip:AddLine("|cff00ff96Left-Click:|r Cycle Flight Points / Clear Custom Quest Lock", 0.8, 0.95, 1)
    GameTooltip:AddLine("|cff00ff96Right-Click:|r Open Revealed Kingdom Atlas", 0.8, 0.95, 1)
    GameTooltip:AddLine("|cff00ff96Drag:|r Move HUD anywhere on screen", 0.8, 0.95, 1)
    GameTooltip:AddLine("|cffffd100Tip:|r Click any quest in the Right-Side Quest Tracker Dropdown to route to it!", 1, 0.9, 0.6)
    GameTooltip:Show()
end)
HUD:SetScript("OnLeave", function() GameTooltip:Hide() end)

-- ============================================================================
-- 2. RIGHT-SIDE LIVE PRIORITY QUEST TRACKER DROPDOWN (For Classic WoW)
-- ============================================================================
local Tracker = CreateFrame("Frame", "RoyalQuestTrackerFrame", UIParent, "BackdropTemplate")
Tracker:SetSize(288, 34)
Tracker:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -14, -195)
Tracker:SetFrameStrata("MEDIUM")
Tracker:SetFrameLevel(18)
Tracker:SetMovable(true)
Tracker:EnableMouse(true)

-- Dropdown Header Bar
local HeaderBar = CreateFrame("Button", "RoyalQuestTrackerHeader", Tracker, "BackdropTemplate")
HeaderBar:SetSize(288, 30)
HeaderBar:SetPoint("TOPLEFT", Tracker, "TOPLEFT", 0, 0)
HeaderBar:RegisterForDrag("LeftButton")
HeaderBar:RegisterForClicks("LeftButtonUp", "RightButtonUp")
ApplyBoxBackdrop(HeaderBar, 0.06, 0.07, 0.12, 0.95, 0.95, 0.78, 0.22, 1.0)

local headerAccent = HeaderBar:CreateTexture(nil, "OVERLAY")
headerAccent:SetTexture("Interface\\Buttons\\WHITE8X8")
headerAccent:SetVertexColor(1.0, 0.84, 0.20, 0.65)
headerAccent:SetPoint("TOPLEFT", 4, -2)
headerAccent:SetPoint("TOPRIGHT", -4, -2)
headerAccent:SetHeight(1)

local DropdownToggleBtn = CreateFrame("Button", nil, HeaderBar, "UIPanelButtonTemplate")
DropdownToggleBtn:SetSize(24, 20)
DropdownToggleBtn:SetPoint("LEFT", HeaderBar, "LEFT", 5, 0)
DropdownToggleBtn:SetText("v")

local HeaderTitle = HeaderBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
HeaderTitle:SetPoint("LEFT", DropdownToggleBtn, "RIGHT", 6, 0)
HeaderTitle:SetText("|cffffd100Active Quests (Priority)|r")

local MapAllBtn = CreateFrame("Button", nil, HeaderBar, "UIPanelButtonTemplate")
MapAllBtn:SetSize(58, 20)
MapAllBtn:SetPoint("RIGHT", HeaderBar, "RIGHT", -5, 0)
MapAllBtn:SetText("|cff00ffccMap All|r")

-- Dropdown Body Container (Collapsible)
local DropdownBody = CreateFrame("Frame", "RoyalQuestTrackerBody", Tracker, "BackdropTemplate")
DropdownBody:SetWidth(288)
DropdownBody:SetPoint("TOPLEFT", HeaderBar, "BOTTOMLEFT", 0, -2)
ApplyBoxBackdrop(DropdownBody, 0.04, 0.05, 0.09, 0.88, 0.30, 0.65, 0.90, 0.85)

local QuestRowPool = {}

local function GetQuestDifficultyHex(qLevel)
    local pLvl = UnitLevel("player") or 1
    qLevel = tonumber(qLevel) or pLvl
    local diff = qLevel - pLvl
    if diff >= 5 then return "ff2020"
    elseif diff >= 3 then return "ff8040"
    elseif diff >= -2 then return "ffd100"
    elseif diff >= -7 then return "40c040"
    else return "999999"
    end
end

local function AcquireQuestRow(idx)
    if QuestRowPool[idx] then return QuestRowPool[idx] end
    local r = CreateFrame("Button", nil, DropdownBody, "BackdropTemplate")
    r:SetWidth(278)
    r:SetHeight(48)
    r:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    ApplyBoxBackdrop(r, 0.08, 0.10, 0.15, 0.90, 0.25, 0.30, 0.42, 0.85)

    r.titleTxt = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    r.titleTxt:SetPoint("TOPLEFT", 7, -5)
    r.titleTxt:SetWidth(212)
    r.titleTxt:SetJustifyH("LEFT")

    r.zoneTxt = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    r.zoneTxt:SetPoint("TOPLEFT", 7, -18)
    r.zoneTxt:SetWidth(212)
    r.zoneTxt:SetJustifyH("LEFT")

    r.objTxt = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    r.objTxt:SetPoint("TOPLEFT", 10, -31)
    r.objTxt:SetWidth(260)
    r.objTxt:SetJustifyH("LEFT")
    r.objTxt:SetJustifyV("TOP")

    r.mapBtn = CreateFrame("Button", nil, r, "UIPanelButtonTemplate")
    r.mapBtn:SetSize(46, 18)
    r.mapBtn:SetPoint("TOPRIGHT", -5, -4)
    r.mapBtn:SetText("|cff00ffccRoute|r")

    r.mapBtn:SetScript("OnClick", function()
        if not r.qData then return end
        local q = r.qData
        selectedQuestKey = q.title
        _G.RoyalCompassHUD_SetQuestTarget(q.title, q.zone, q.x, q.y)
        if _G.TheKingdomForge and _G.TheKingdomForge.FocusQuestOnMaps then
            _G.TheKingdomForge:FocusQuestOnMaps(q, "WORLD_MAP")
        elseif WorldMapFrame then
            ToggleWorldMap()
        end
        if _G.RoyalQuestTracker_Refresh then _G.RoyalQuestTracker_Refresh() end
    end)

    r:SetScript("OnClick", function(self, button)
        if not self.qData then return end
        local q = self.qData
        if button == "RightButton" then
            -- Open native Blizzard Quest Log to this quest!
            if SelectQuestLogEntry and q.logIndex then
                SelectQuestLogEntry(q.logIndex)
                if QuestLog_SetSelection then pcall(QuestLog_SetSelection, q.logIndex) end
                if QuestLogFrame then
                    if not QuestLogFrame:IsShown() and ToggleQuestLog then
                        ToggleQuestLog()
                    elseif not QuestLogFrame:IsShown() then
                        ShowUIPanel(QuestLogFrame)
                    end
                    if QuestLog_Update then pcall(QuestLog_Update) end
                end
            end
        else
            -- Left-Click: Lock Compass + Plot Route on Map!
            selectedQuestKey = q.title
            _G.RoyalCompassHUD_SetQuestTarget(q.title, q.zone, q.x, q.y)
            local openMode = IsShiftKeyDown() and "WORLD_MAP" or nil
            if _G.TheKingdomForge and _G.TheKingdomForge.FocusQuestOnMaps then
                _G.TheKingdomForge:FocusQuestOnMaps(q, openMode)
            end
            print(string.format(
                "|cffffd100[Royal Quest Tracker]|r Routing to |cff00ffcc#%d %s|r in |cffffd100%s (%.1f, %.1f)|r! Press |cffffd100'M'|r to view the map route.",
                q.prioRank or 1, q.title, q.zone or "Zone", q.x or 50, q.y or 50
            ))
            if _G.RoyalQuestTracker_Refresh then _G.RoyalQuestTracker_Refresh() end
        end
    end)

    r:SetScript("OnEnter", function(self)
        if not self.qData then return end
        local q = self.qData
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:ClearLines()
        GameTooltip:AddLine(string.format("|cffffd100Priority #%d:|r %s (Lv %d)", q.prioRank or 1, q.title, q.level or 1), 1, 0.85, 0.15)
        GameTooltip:AddLine(string.format("|cff38bdf8Zone:|r %s  •  |cffffd100(%.1f, %.1f)|r", q.zone or "Unknown", q.x or 50, q.y or 50), 1, 1, 1)
        if q.npc and q.npc ~= "" then
            GameTooltip:AddLine("|cff00ffccQuest NPC:|r " .. q.npc, 0.8, 1, 0.9)
        end
        if q.objectives and #q.objectives > 0 then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("|cffffd100Objectives:|r")
            for _, ob in ipairs(q.objectives) do
                GameTooltip:AddLine(" • " .. ob.text, ob.done and 0.2 or 1.0, ob.done and 1.0 or 0.85, ob.done and 0.4 or 0.2)
            end
        end
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("|cff00ff96Left-Click:|r Lock Compass Arrow & Plot Route on Map ('M')", 0.2, 1, 0.6)
        GameTooltip:AddLine("|cff00ff96Click [Route] / Shift-Click:|r Open World Map ('M') to Quest Route", 0.2, 1, 0.6)
        GameTooltip:AddLine("|cff00ff96Right-Click:|r Open Full Quest Log Details", 0.7, 0.85, 1)
        GameTooltip:Show()
    end)
    r:SetScript("OnLeave", function() GameTooltip:Hide() end)

    QuestRowPool[idx] = r
    return r
end

local isCollapsed = false

local function ToggleDropdownCollapse()
    isCollapsed = not isCollapsed
    RoyalCompassHUDDB = RoyalCompassHUDDB or {}
    RoyalCompassHUDDB.trackerCollapsed = isCollapsed
    if _G.RoyalQuestTracker_Refresh then _G.RoyalQuestTracker_Refresh() end
end

DropdownToggleBtn:SetScript("OnClick", ToggleDropdownCollapse)
HeaderBar:SetScript("OnDragStart", function() Tracker:StartMoving() end)
HeaderBar:SetScript("OnDragStop", function()
    Tracker:StopMovingOrSizing()
    local pt, _, relPt, x, y = Tracker:GetPoint()
    RoyalCompassHUDDB = RoyalCompassHUDDB or {}
    RoyalCompassHUDDB.trackerPoint = { pt, relPt, x, y }
end)
HeaderBar:SetScript("OnClick", function(_, button)
    if button == "RightButton" then
        if ToggleQuestLog then ToggleQuestLog() end
    else
        ToggleDropdownCollapse()
    end
end)

MapAllBtn:SetScript("OnClick", function()
    local KF = _G.TheKingdomForge
    if KF then
        local db = KF:EnsureDB()
        db.focusedQuestRoute = nil
        local _, _, _, _, _, _, curZone = KF:GetPlayerContext()
        db.selectedZone = curZone
        if WorldMapFrame then
            if not WorldMapFrame:IsShown() and ToggleWorldMap then
                ToggleWorldMap()
            end
            local V = _G.TheKingdomForgeVault or {}
            local mid = V.ZoneToUIMapID and V.ZoneToUIMapID[curZone]
            if mid and WorldMapFrame.SetMapID then
                pcall(WorldMapFrame.SetMapID, WorldMapFrame, mid)
            end
        end
        if KF.RefreshNativeWorldMapOverlay then KF:RefreshNativeWorldMapOverlay(true) end
        if KF.RefreshPage3 and _G.TheKingdomForgeMainFrame and _G.TheKingdomForgeMainFrame:IsShown() then
            KF:RefreshPage3()
        end
    end
end)

function _G.RoyalQuestTracker_Refresh()
    -- Hide default Vanilla QuestWatchFrame if present so it doesn't overlap our live dropdown
    if QuestWatchFrame and QuestWatchFrame:IsShown() then
        QuestWatchFrame:Hide()
    end

    local KF = _G.TheKingdomForge
    local entries = (KF and KF.GetActiveQuestLogEntries and KF:GetActiveQuestLogEntries()) or {}

    HeaderTitle:SetText(string.format("|cffffd100Active Quests|r |cff00ffcc(%d in Log)|r", #entries))
    DropdownToggleBtn:SetText(isCollapsed and ">" or "v")

    if isCollapsed then
        DropdownBody:Hide()
        return
    end
    DropdownBody:Show()

    for _, r in ipairs(QuestRowPool) do r:Hide() end

    if #entries == 0 then
        local r = AcquireQuestRow(1)
        r.qData = nil
        r:SetPoint("TOPLEFT", DropdownBody, "TOPLEFT", 5, -6)
        r:SetHeight(36)
        r.titleTxt:SetText("|cff999999No active quests in your Quest Log.|r")
        r.zoneTxt:SetText("|cffccccccAccept a quest or open /kf Revealed Atlas!|r")
        r.objTxt:SetText("")
        r.mapBtn:Hide()
        r:Show()
        DropdownBody:SetHeight(48)
        return
    end

    -- Auto-lock onto Priority #1 quest if nothing is currently locked, or sync selected quest's live coordinates
    local foundSelected = false
    for _, q in ipairs(entries) do
        if selectedQuestKey and q.title == selectedQuestKey then
            foundSelected = true
            _G.RoyalCompassHUD_SetQuestTarget(q.title, q.zone, q.x, q.y)
            break
        end
    end
    if (not customWaypoint or not foundSelected) and entries[1] then
        local q1 = entries[1]
        selectedQuestKey = q1.title
        _G.RoyalCompassHUD_SetQuestTarget(q1.title, q1.zone, q1.x, q1.y)
        if KF and KF.EnsureDB then
            local db = KF:EnsureDB()
            if not db.focusedQuestRoute then
                db.focusedQuestRoute = {
                    id = q1.id, name = q1.title, lvl = q1.level, zone = q1.zone,
                    x = q1.x, y = q1.y, npc = q1.npc, isComplete = q1.isComplete, objSummary = q1.objSummary,
                }
            end
        end
    end

    local yOff = -6
    local maxShow = math.min(12, #entries)
    for idx = 1, maxShow do
        local q = entries[idx]
        local r = AcquireQuestRow(idx)
        r.qData = q
        r.mapBtn:Show()

        local hex = GetQuestDifficultyHex(q.level)
        local statusTag = ""
        if q.isComplete then
            statusTag = " |cff22c55e[? TURN IN]|r"
        elseif q.inCurrentZone and q.distYds < 9000 then
            statusTag = string.format(" |cff00ffcc(%dy)|r", q.distYds)
        end

        r.titleTxt:SetText(string.format(
            "|cffffd100#%d|r |cff%s[%d]|r |cffffffff%s|r%s",
            q.prioRank or idx, hex, q.level or 1, q.title:sub(1, 24), statusTag
        ))

        local zColor = q.inCurrentZone and "22c55e" or "38bdf8"
        r.zoneTxt:SetText(string.format(
            "|cff%s%s|r |cffffd100(%.1f, %.1f)|r%s",
            zColor, (q.zone or "Zone"):sub(1, 18), q.x or 50, q.y or 50,
            (q.npc and q.npc ~= "") and (" • |cffcccccc" .. q.npc:sub(1, 14) .. "|r") or ""
        ))

        -- Objectives text
        local objLines = {}
        if q.isComplete then
            table.insert(objLines, "|cff22c55e? Turn in at " .. (q.npc ~= "" and q.npc or "Quest Giver") .. "!|r")
        elseif q.objectives and #q.objectives > 0 then
            for j = 1, math.min(3, #q.objectives) do
                local ob = q.objectives[j]
                table.insert(objLines, (ob.done and "|cff22c55e✓ " or "|cffffd100• ") .. ob.text .. "|r")
            end
        else
            table.insert(objLines, "|cffcccccc• Target: " .. (q.npc ~= "" and q.npc or "See Map Route") .. "|r")
        end
        r.objTxt:SetText(table.concat(objLines, "\n"))

        local objH = math.max(12, r.objTxt:GetStringHeight() or 12)
        local rowH = 34 + objH
        r:SetHeight(rowH)

        if selectedQuestKey and selectedQuestKey == q.title then
            ApplyBoxBackdrop(r, 0.08, 0.16, 0.22, 0.96, 0.0, 1.0, 0.85, 1.0)
        elseif q.isComplete then
            ApplyBoxBackdrop(r, 0.06, 0.14, 0.09, 0.92, 0.20, 0.85, 0.40, 0.90)
        else
            ApplyBoxBackdrop(r, 0.07, 0.09, 0.14, 0.90, 0.28, 0.34, 0.48, 0.85)
        end

        r:ClearAllPoints()
        r:SetPoint("TOPLEFT", DropdownBody, "TOPLEFT", 5, yOff)
        r:Show()
        yOff = yOff - rowH - 4
    end

    DropdownBody:SetHeight(math.abs(yOff) + 4)
end

-- ============================================================================
-- 3. LIVE ONUPDATE TICKER (Compass + Quest Tracker Sync)
-- ============================================================================
local accum = 0
local trackerAccum = 0
HUD:SetScript("OnUpdate", function(_, elapsed)
    local dt = elapsed or 0.016
    accum = accum + dt
    trackerAccum = trackerAccum + dt

    if trackerAccum >= 1.5 then
        trackerAccum = 0
        if _G.RoyalQuestTracker_Refresh then
            _G.RoyalQuestTracker_Refresh()
        end
    end

    if accum < 0.25 then return end
    accum = 0

    local zone = (GetRealZoneText and GetRealZoneText()) or (GetZoneText and GetZoneText()) or "Azeroth"
    local mapID = (C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")) or 1429
    local px, py = 0, 0
    if mapID and C_Map and C_Map.GetPlayerMapPosition then
        local ok, pos = pcall(C_Map.GetPlayerMapPosition, mapID, "player")
        if ok and pos and pos.GetXY then
            local x, y = pos:GetXY()
            px, py = (x or 0) * 100, (y or 0) * 100
        end
    end

    local curXP = UnitXP("player") or 0
    local maxXP = math.max(1, UnitXPMax("player") or 1)
    if not sessionStartXP then
        sessionStartXP = curXP
        lastKnownXP = curXP
        lastKnownMaxXP = maxXP
    else
        if curXP >= lastKnownXP then
            sessionGainedXP = sessionGainedXP + (curXP - lastKnownXP)
        else
            sessionGainedXP = sessionGainedXP + ((lastKnownMaxXP - lastKnownXP) + curXP)
        end
        lastKnownXP = curXP
        lastKnownMaxXP = maxXP
    end

    local elapsedHrs = math.max(0.001, (GetTime() - sessionStartTime) / 3600)
    local xpPerHr = math.floor(sessionGainedXP / elapsedHrs)
    local xpPct = math.floor((curXP / maxXP) * 100)
    local ttlStr = ""
    if sessionGainedXP > 0 and xpPerHr > 0 then
        local minsLeft = math.ceil(((maxXP - curXP) / xpPerHr) * 60)
        ttlStr = string.format(" |cffaaaaaa(%dm TTL)|r", minsLeft)
    end

    local wpStr = "|cff999999No Waypoint|r"
    local target = customWaypoint
    if not target then
        local targets = GetZoneFlightTargets(mapID, zone)
        if #targets > 0 then
            if targetIndex > #targets then targetIndex = 1 end
            target = targets[targetIndex]
        end
    end

    if target and px > 0 and py > 0 then
        local dx = target.x - px
        local dy = target.y - py
        local dist = math.sqrt(dx * dx + dy * dy)
        local arrow = GetDirectionArrow(dx, dy)
        local prefix = target.isQuest and "|cff00ffccQ:|r " or ""
        wpStr = string.format("%s %s|cffffd100%s|r |cffcccccc(%.0f yds)|r", arrow, prefix, target.name:sub(1, 18), dist * 12)
    elseif target then
        wpStr = string.format("|cffffd100%s|r (%.1f, %.1f)", target.name:sub(1, 18), target.x, target.y)
    end

    local freeBags, totalBags = 0, 0
    for b = 0, 4 do
        local slots = (C_Container and C_Container.GetContainerNumSlots and C_Container.GetContainerNumSlots(b))
            or (GetContainerNumSlots and GetContainerNumSlots(b)) or 0
        local free = (C_Container and C_Container.GetContainerNumFreeSlots and C_Container.GetContainerNumFreeSlots(b))
            or (GetContainerNumFreeSlots and GetContainerNumFreeSlots(b)) or 0
        totalBags = totalBags + slots
        freeBags = freeBags + free
    end

    local goldStr = FormatGold(GetMoney and GetMoney() or 0)

    hudText:SetText(string.format(
        "|TInterface\\Icons\\INV_Crown_01:13:13:0:0:64:64:4:60:4:60|t |cffffd100%s|r |cff00ffcc(%.1f, %.1f)|r  |  %s  |  |cff22c55eXP: %d%%%s|r  |  |cff38bdf8Bags: %d/%d|r  |  %s",
        zone:sub(1, 16), px, py, wpStr, xpPct, ttlStr, freeBags, totalBags, goldStr
    ))
end)

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:RegisterEvent("QUEST_LOG_UPDATE")
ev:RegisterEvent("QUEST_WATCH_UPDATE")
ev:RegisterEvent("ZONE_CHANGED_NEW_AREA")
ev:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        if RoyalCompassHUDDB then
            if RoyalCompassHUDDB.point then
                local p = RoyalCompassHUDDB.point
                HUD:ClearAllPoints()
                HUD:SetPoint(p[1], UIParent, p[2], p[3], p[4])
            end
            if RoyalCompassHUDDB.trackerPoint then
                local tp = RoyalCompassHUDDB.trackerPoint
                Tracker:ClearAllPoints()
                Tracker:SetPoint(tp[1], UIParent, tp[2], tp[3], tp[4])
            end
            if RoyalCompassHUDDB.trackerCollapsed ~= nil then
                isCollapsed = RoyalCompassHUDDB.trackerCollapsed
            end
        end
    end
    if _G.RoyalQuestTracker_Refresh then
        _G.RoyalQuestTracker_Refresh()
    end
end)

SLASH_ROYALCOMPASSHUD1 = "/rc"
SLASH_ROYALCOMPASSHUD2 = "/compass"
SlashCmdList["ROYALCOMPASSHUD"] = function(msg)
    msg = (msg or ""):gsub("^%s+", ""):gsub("%s+$", "")
    local xStr, yStr = msg:match("([0-9.]+)%s+([0-9.]+)")
    if xStr and yStr then
        customWaypoint = { name = "Custom Pin", x = tonumber(xStr), y = tonumber(yStr) }
        print(string.format("|cffffd100[Royal Compass HUD]|r Locked onto custom coordinate waypoint (%.1f, %.1f)!", customWaypoint.x, customWaypoint.y))
    elseif msg == "clear" then
        customWaypoint = nil
        selectedQuestKey = nil
        print("|cffffd100[Royal Compass HUD]|r Cleared custom waypoint; tracking priority quest / Flight Points.")
    else
        if HUD:IsShown() then HUD:Hide(); Tracker:Hide() else HUD:Show(); Tracker:Show() end
    end
end
