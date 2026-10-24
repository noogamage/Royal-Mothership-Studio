-- ============================================================================
-- FILE: Engine_AIBeacon.lua
-- PURPOSE: Ultra-lightweight 16-Cell RGB Pixel Telemetry Strip (32x2 px at TOPLEFT)
--          Streams live Zone, SubZone, Coordinates, HP%, Mana%, Target Name/HP%,
--          and Boss/Combat state to the external AltVault AI Companion Overlay.
-- ============================================================================
local addonName, ns = ...

local AIBeacon = {}
ns.AIBeacon = AIBeacon

local NUM_CELLS = 16
local CELL_SIZE = 2 -- 2x2 pixels per cell = 32x2 strip at (0,0) top-left of screen

local CLASS_TO_ID = {
    WARRIOR = 1, PALADIN = 2, HUNTER = 3, ROGUE = 4, PRIEST = 5,
    DEATHKNIGHT = 6, SHAMAN = 7, MAGE = 8, WARLOCK = 9, MONK = 10,
    DRUID = 11, DEMONHUNTER = 12,
}

local StripFrame = CreateFrame("Frame", "AltVaultAITelemetryStrip", UIParent)
StripFrame:SetSize(NUM_CELLS * CELL_SIZE, CELL_SIZE)
StripFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0)
StripFrame:SetFrameStrata("TOOLTIP")
StripFrame:SetFrameLevel(9999)
StripFrame:EnableMouse(false)

local cells = {}
for i = 0, NUM_CELLS - 1 do
    local tex = StripFrame:CreateTexture(nil, "OVERLAY")
    tex:SetSize(CELL_SIZE, CELL_SIZE)
    tex:SetPoint("TOPLEFT", StripFrame, "TOPLEFT", i * CELL_SIZE, 0)
    if tex.SetColorTexture then
        tex:SetColorTexture(0, 0, 0, 1)
    else
        tex:SetTexture("Interface\\Buttons\\WHITE8X8")
        tex:SetVertexColor(0, 0, 0, 1)
    end
    cells[i] = tex
end

local function SetCellRGB(idx, rByte, gByte, bByte)
    local tex = cells[idx]
    if not tex then return end
    local r = math.max(0, math.min(255, math.floor(rByte or 0))) / 255
    local g = math.max(0, math.min(255, math.floor(gByte or 0))) / 255
    local b = math.max(0, math.min(255, math.floor(bByte or 0))) / 255
    if tex.SetColorTexture then
        tex:SetColorTexture(r, g, b, 1)
    else
        tex:SetVertexColor(r, g, b, 1)
    end
end

local issecret = _G.issecretvalue or function() return false end

local function SafeNumber(val, defaultVal)
    if val == nil or issecret(val) then return defaultVal end
    local ok, n = pcall(tonumber, val)
    if ok and type(n) == "number" and not issecret(n) then
        return n
    end
    return defaultVal
end

local function SafePercent(cur, maxVal, defaultPct)
    if cur == nil or maxVal == nil or issecret(cur) or issecret(maxVal) then
        return defaultPct
    end
    local ok, pct = pcall(function()
        if maxVal <= 0 then return defaultPct end
        return math.floor((cur / maxVal) * 100 + 0.5)
    end)
    if ok and type(pct) == "number" and not issecret(pct) then
        return math.max(0, math.min(100, pct))
    end
    return defaultPct
end

local function SanitizeASCII30(str)
    if not str or issecret(str) then return string.rep(" ", 30) end
    local ok, clean = pcall(function()
        if str == "" then return string.rep(" ", 30) end
        local s = string.gsub(tostring(str), "[^\32-\126]", "")
        if #s < 30 then
            s = s .. string.rep(" ", 30 - #s)
        elseif #s > 30 then
            s = string.sub(s, 1, 30)
        end
        return s
    end)
    if ok and type(clean) == "string" and not issecret(clean) then
        return clean
    end
    return string.rep(" ", 30)
end

local function GetFreeBagSlotsCount()
    local free = 0
    for bag = 0, 4 do
        if C_Container and C_Container.GetContainerNumFreeSlots then
            local ok, n = pcall(C_Container.GetContainerNumFreeSlots, bag)
            if ok and tonumber(n) then free = free + tonumber(n) end
        elseif GetContainerNumFreeSlots then
            local ok, n = pcall(GetContainerNumFreeSlots, bag)
            if ok and tonumber(n) then free = free + tonumber(n) end
        end
    end
    return math.min(255, math.max(0, free))
end

local function GetPlayerMapAndCoords()
    local mapID = 0
    local cx, cy = 0, 0
    if C_Map and C_Map.GetBestMapForUnit then
        local okM, m = pcall(C_Map.GetBestMapForUnit, "player")
        if okM and tonumber(m) then
            mapID = tonumber(m)
            if C_Map.GetPlayerMapPosition then
                local okP, pos = pcall(C_Map.GetPlayerMapPosition, mapID, "player")
                if okP and pos and pos.GetXY then
                    local x, y = pos:GetXY()
                    if x and y then
                        cx = math.floor(x * 1000 + 0.5)
                        cy = math.floor(y * 1000 + 0.5)
                    end
                end
            end
        end
    elseif GetPlayerMapPosition then
        local okP, x, y = pcall(GetPlayerMapPosition, "player")
        if okP and x and y then
            cx = math.floor(x * 1000 + 0.5)
            cy = math.floor(y * 1000 + 0.5)
        end
    end
    return math.max(0, math.min(65535, mapID)), math.max(0, math.min(1000, cx)), math.max(0, math.min(1000, cy))
end

local heartbeatSeq = 0
local textPage = 0 -- 0 = Zone/SubZone (30 chars), 1 = TargetName (30 chars)

function AIBeacon:UpdateTelemetryStrip()
    if not StripFrame:IsShown() then return end

    heartbeatSeq = (heartbeatSeq + 1) % 256
    textPage = 1 - textPage

    -- Cell 0: Sync Magic Header (170, 85, 240)
    SetCellRGB(0, 170, 85, 240)

    local inCombat = (InCombatLockdown and InCombatLockdown()) or (UnitAffectingCombat and UnitAffectingCombat("player")) or false
    local hasTarget = UnitExists and UnitExists("target") or false
    local classification = hasTarget and UnitClassification and UnitClassification("target") or "normal"
    local isBossOrElite = (classification == "worldboss" or classification == "elite" or classification == "rareelite")
    local isBossFight = (IsEncounterInProgress and IsEncounterInProgress()) or (inCombat and isBossOrElite) or false
    local isHostile = hasTarget and UnitCanAttack and UnitCanAttack("player", "target") or false
    local isDead = UnitIsDeadOrGhost and UnitIsDeadOrGhost("player") or false
    local panelOpen = (_G.AltVaultMainPanel and _G.AltVaultMainPanel:IsShown()) or false

    local flags = 0
    if inCombat      then flags = flags + 1  end
    if hasTarget     then flags = flags + 2  end
    if isBossOrElite then flags = flags + 4  end
    if isHostile     then flags = flags + 8  end
    if isDead        then flags = flags + 16 end
    if panelOpen     then flags = flags + 32 end
    if isBossFight   then flags = flags + 64 end
    if textPage == 1 then flags = flags + 128 end

    local pLevel = math.min(255, math.max(1, SafeNumber(UnitLevel and UnitLevel("player"), 1)))
    local _, classToken = UnitClass("player")
    if issecret(classToken) then classToken = "WARRIOR" end
    local classID = CLASS_TO_ID[classToken or "WARRIOR"] or 1

    -- Cell 1: Flags, Player Level, Class ID
    SetCellRGB(1, flags, pLevel, classID)

    -- Cell 2: Player HP%, Player Power%, Target HP% (100% Secret-Value Safe for 12.0 Forever Engine!)
    local hpPct = SafePercent(UnitHealth and UnitHealth("player"), UnitHealthMax and UnitHealthMax("player"), 100)
    local pwPct = SafePercent(UnitPower and UnitPower("player"), UnitPowerMax and UnitPowerMax("player"), 100)

    local tHpPct = 255
    local tLevel = 0
    if hasTarget then
        tHpPct = SafePercent(UnitHealth and UnitHealth("target"), UnitHealthMax and UnitHealthMax("target"), 100)
        local rawTLvl = SafeNumber(UnitLevel and UnitLevel("target"), 0)
        tLevel = (rawTLvl < 0) and 255 or math.min(254, math.max(0, rawTLvl))
    end
    SetCellRGB(2, hpPct, pwPct, tHpPct)

    -- Cell 3, 4, 5: MapID, Coordinates (0..1000), Target Level, Free Bag Slots, Heartbeat
    local mapID, cx, cy = GetPlayerMapAndCoords()
    SetCellRGB(3, math.floor(mapID / 256), mapID % 256, tLevel)
    SetCellRGB(4, math.floor(cx / 256), cx % 256, math.floor(cy / 256))
    SetCellRGB(5, cy % 256, GetFreeBagSlotsCount(), heartbeatSeq)

    -- Cells 6..15: 30 ASCII characters (Page 0 = Zone:SubZone, Page 1 = TargetName)
    local payloadStr = ""
    if textPage == 0 then
        local z = (GetRealZoneText and GetRealZoneText()) or (GetZoneText and GetZoneText()) or "Azeroth"
        local sz = (GetSubZoneText and GetSubZoneText()) or ""
        if issecret(z) then z = "Azeroth" end
        if issecret(sz) then sz = "" end
        if sz ~= "" and sz ~= z then
            payloadStr = z .. " - " .. sz
        else
            payloadStr = z
        end
    else
        local tName = hasTarget and UnitName("target") or ""
        if issecret(tName) then tName = "Target" end
        payloadStr = tName
    end

    local ascii30 = SanitizeASCII30(payloadStr)
    for cellIdx = 6, 15 do
        local charBase = (cellIdx - 6) * 3 + 1
        local b1 = string.byte(ascii30, charBase) or 32
        local b2 = string.byte(ascii30, charBase + 1) or 32
        local b3 = string.byte(ascii30, charBase + 2) or 32
        SetCellRGB(cellIdx, b1, b2, b3)
    end
end

if C_Timer and C_Timer.NewTicker then
    C_Timer.NewTicker(1.0, function()
        pcall(AIBeacon.UpdateTelemetryStrip, AIBeacon)
    end)
end

local BeaconEvents = CreateFrame("Frame")
BeaconEvents:RegisterEvent("PLAYER_ENTERING_WORLD")
BeaconEvents:RegisterEvent("ZONE_CHANGED_NEW_AREA")
BeaconEvents:RegisterEvent("ZONE_CHANGED")
BeaconEvents:RegisterEvent("PLAYER_TARGET_CHANGED")
BeaconEvents:RegisterEvent("PLAYER_REGEN_DISABLED")
BeaconEvents:RegisterEvent("PLAYER_REGEN_ENABLED")
BeaconEvents:SetScript("OnEvent", function()
    pcall(AIBeacon.UpdateTelemetryStrip, AIBeacon)
end)

SLASH_ALTVAULTAI1 = "/avai"
SlashCmdList["ALTVAULTAI"] = function()
    if StripFrame:IsShown() then
        StripFrame:Hide()
        print("|cffffcc00[AltVault AI Beacon]:|r Pixel telemetry strip hidden.")
    else
        StripFrame:Show()
        AIBeacon:UpdateTelemetryStrip()
        print("|cff00ff00[AltVault AI Beacon]:|r Pixel telemetry strip active at (0,0).")
    end
end
