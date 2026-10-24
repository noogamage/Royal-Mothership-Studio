-- ============================================================================
-- FILE: Engine_ForeverVaultIntelligence.lua
-- BLOCK HEADING: FOREVER 16001 INTELLIGENCE ENGINE, GOD TOOLTIP, GPS WAYPOINT
--                HUD, GOLD/AH FLIP ADVISOR & "FACEVAULT" LIVE 3D RUNWAY NETWORK
-- ============================================================================
local addonName, ns = ...

local FVD = ns.ForeverVaultData or {}
ns.ForeverVaultData = FVD

local ForeverIndex = ns.ForeverIndex or {}
ns.ForeverIndex = ForeverIndex

local FaceVault = ns.FaceVault or {}
ns.FaceVault = FaceVault

local find, sub, lower, byte, format = string.find, string.sub, string.lower, string.byte, string.format
local tonumber, floor, max, min = tonumber, math.floor, math.max, math.min

-- ============================================================================
-- BLOCK HEADING: 1. ZERO-RAM LAZY BINARY-SEARCH ITEM INDEX (15,534 ITEMS)
-- ============================================================================
local loaded = false
local LOWER
local starts = {}
local ids = {}
local fieldAt = {}
local byID = {}
local byName = nil
local bySpell = nil
local count = 0

local WORD_BREAK = { [32] = true, [45] = true, [40] = true, [91] = true, [58] = true, [47] = true, [34] = true }

local INVTYPE_TO_EQUIPLOC = {
    [1]  = "INVTYPE_HEAD",
    [2]  = "INVTYPE_NECK",
    [3]  = "INVTYPE_SHOULDER",
    [4]  = "INVTYPE_BODY",
    [5]  = "INVTYPE_CHEST",
    [6]  = "INVTYPE_WAIST",
    [7]  = "INVTYPE_LEGS",
    [8]  = "INVTYPE_FEET",
    [9]  = "INVTYPE_WRIST",
    [10] = "INVTYPE_HAND",
    [11] = "INVTYPE_FINGER",
    [12] = "INVTYPE_TRINKET",
    [13] = "INVTYPE_WEAPON",
    [14] = "INVTYPE_SHIELD",
    [15] = "INVTYPE_RANGED",
    [16] = "INVTYPE_CLOAK",
    [17] = "INVTYPE_2HWEAPON",
    [18] = "INVTYPE_BAG",
    [19] = "INVTYPE_TABARD",
    [20] = "INVTYPE_ROBE",
    [21] = "INVTYPE_WEAPONMAINHAND",
    [22] = "INVTYPE_WEAPONOFFHAND",
    [23] = "INVTYPE_HOLDABLE",
    [24] = "INVTYPE_AMMO",
    [25] = "INVTYPE_THROWN",
    [26] = "INVTYPE_RANGEDRIGHT",
    [28] = "INVTYPE_RELIC",
}

local CLASS_SUBCLASS_LABELS = {
    [0]  = { name = "Consumable", subs = { [0] = "Consumable", [1] = "Potion", [2] = "Elixir", [3] = "Flask", [4] = "Scroll", [5] = "Food & Drink", [6] = "Item Enhancement", [7] = "Bandage" } },
    [1]  = { name = "Container",  subs = { [0] = "Bag", [1] = "Soul Bag", [2] = "Herb Bag", [3] = "Enchanting Bag", [4] = "Engineering Bag" } },
    [2]  = { name = "Weapon",     subs = {
        [0] = "One-Handed Axes", [1] = "Two-Handed Axes", [2] = "Bows", [3] = "Guns",
        [4] = "One-Handed Maces", [5] = "Two-Handed Maces", [6] = "Polearms",
        [7] = "One-Handed Swords", [8] = "Two-Handed Swords", [10] = "Staves",
        [13] = "Fist Weapons", [14] = "Miscellaneous", [15] = "Daggers",
        [16] = "Thrown", [17] = "Spears", [18] = "Crossbows", [19] = "Wands", [20] = "Fishing Poles"
    } },
    [4]  = { name = "Armor",      subs = {
        [0] = "Miscellaneous", [1] = "Cloth", [2] = "Leather", [3] = "Mail",
        [4] = "Plate", [6] = "Shields", [7] = "Librams", [8] = "Idols", [9] = "Totems"
    } },
    [5]  = { name = "Reagent",    subs = { [0] = "Reagent" } },
    [6]  = { name = "Projectile", subs = { [2] = "Arrow", [3] = "Bullet" } },
    [7]  = { name = "Trade Goods", subs = { [0] = "Trade Goods", [1] = "Parts", [2] = "Explosives", [3] = "Devices", [5] = "Cloth", [6] = "Leather", [7] = "Metal & Stone", [8] = "Meat", [9] = "Herb", [10] = "Elemental", [11] = "Other", [12] = "Enchanting" } },
    [9]  = { name = "Recipe",     subs = { [0] = "Book", [1] = "Leatherworking", [2] = "Tailoring", [3] = "Engineering", [4] = "Blacksmithing", [5] = "Cooking", [6] = "Alchemy", [7] = "First Aid", [8] = "Enchanting", [9] = "Fishing" } },
    [11] = { name = "Quiver",     subs = { [2] = "Quiver", [3] = "Ammo Pouch" } },
    [12] = { name = "Quest",      subs = { [0] = "Quest" } },
    [13] = { name = "Key",        subs = { [0] = "Key", [1] = "Lockpick" } },
    [15] = { name = "Miscellaneous", subs = { [0] = "Junk", [1] = "Reagent", [2] = "Pet", [3] = "Holiday", [4] = "Other", [5] = "Mount" } },
}

local SKILL_ID_TO_PROF = {
    [129] = "First Aid",
    [164] = "Blacksmithing",
    [165] = "Leatherworking",
    [171] = "Alchemy",
    [182] = "Herbalism",
    [185] = "Cooking",
    [186] = "Mining",
    [197] = "Tailoring",
    [202] = "Engineering",
    [333] = "Enchanting",
    [356] = "Fishing",
    [393] = "Skinning",
    [633] = "Lockpicking",
}

local function ensureIndexLoaded()
    if loaded then return end
    loaded = true
    local NAMES, FIELDS = FVD.NAMES, FVD.FIELDS
    if not (NAMES and FIELDS) then return end

    local n = 0
    for s in NAMES:gmatch("\n()[^\n]") do
        n = n + 1
        starts[n] = s
    end
    local k = 0
    for at, id in FIELDS:gmatch("()(%d+)[^\n]*\n") do
        k = k + 1
        id = tonumber(id)
        ids[k] = id
        fieldAt[k] = at
        if not byID[id] then byID[id] = k end
    end
    count = (n < k) and n or k
    starts[count + 1] = #NAMES + 1
    LOWER = lower(NAMES)
end

local function nameOf(i)
    return sub(FVD.NAMES, starts[i], starts[i + 1] - 2)
end

local function fieldsOf(i)
    local line = FVD.FIELDS:match("^([^\n]*)", fieldAt[i])
    local out, n = {}, 0
    for v in (line .. ","):gmatch("([^,]*),") do
        n = n + 1
        out[n] = tonumber(v) or 0
    end
    return out
end

local function qualityOf(i)
    local q = FVD.FIELDS:match("^%d+,(%d*)", fieldAt[i])
    return tonumber(q) or 0
end

local function indexAt(pos)
    local lo, hi = 1, count
    while lo < hi do
        local mid = floor((lo + hi + 1) / 2)
        if starts[mid] <= pos then lo = mid else hi = mid - 1 end
    end
    return lo
end

function ForeverIndex:Count()
    ensureIndexLoaded()
    return count
end

function ForeverIndex:GetAllIDs()
    ensureIndexLoaded()
    return ids
end

function ForeverIndex:Has(id)
    ensureIndexLoaded()
    return byID[tonumber(id) or 0] ~= nil
end

function ForeverIndex:Name(id)
    ensureIndexLoaded()
    local i = byID[tonumber(id) or 0]
    return i and nameOf(i) or nil
end

function ForeverIndex:Quality(id)
    ensureIndexLoaded()
    local i = byID[tonumber(id) or 0]
    return i and qualityOf(i) or nil
end

function ForeverIndex:Info(id)
    id = tonumber(id)
    if not id then return nil end
    ensureIndexLoaded()
    local i = byID[id]
    if not i then return nil end
    local f = fieldsOf(i)
    local classID = f[5] or 0
    local subclassID = f[6] or 0
    local invType = f[7] or 0
    local cInfo = CLASS_SUBCLASS_LABELS[classID]
    local itemType = (cInfo and cInfo.name) or "Miscellaneous"
    local itemSubType = (cInfo and cInfo.subs and cInfo.subs[subclassID]) or itemType
    local equipLoc = INVTYPE_TO_EQUIPLOC[invType] or ""
    local mask = f[9] or 0
    local skillID = (f[10] or 0) ~= 0 and f[10] or nil
    return {
        id = id,
        name = nameOf(i),
        quality = f[2] or 1,
        reqLevel = f[3] or 0,
        itemLevel = f[4] or 0,
        classID = classID,
        subclassID = subclassID,
        invType = invType,
        equipLoc = equipLoc,
        itemType = itemType,
        itemSubType = itemSubType,
        bonding = f[8] or 0,
        classMask = (mask ~= 0) and mask or nil,
        skill = skillID,
        skillName = skillID and SKILL_ID_TO_PROF[skillID] or nil,
        skillRank = skillID and (f[11] or 0) or nil,
        stack = (f[12] or 0) > 0 and f[12] or 1,
        lockSkill = (f[13] or 0) > 0 and f[13] or nil,
        teaches = (f[14] or 0) > 0 and f[14] or nil,
    }
end

function ForeverIndex:Search(text, maxResults)
    maxResults = maxResults or 25
    local out = {}
    if type(text) ~= "string" or maxResults < 1 then return out end
    ensureIndexLoaded()
    local seen = {}
    local numID = tonumber(text:match("|Hitem:(%d+)") or text:match("^%s*item:(%d+)") or text:match("^%s*#?(%d+)%s*$"))
    if numID and byID[numID] then
        local idx = byID[numID]
        out[1] = { id = ids[idx], name = nameOf(idx), quality = qualityOf(idx) }
        seen[idx] = true
    end
    local q = lower(text):gsub("^%s*%[", ""):gsub("%]%s*$", ""):gsub("%s+", " "):gsub("^ ", ""):gsub(" $", "")
    if q == "" or not LOWER then return out end
    local qlen = #q
    local tier1, tier2, tier3 = {}, {}, {}
    local best = {}
    local pos = 1
    while true do
        local p = find(LOWER, q, pos, true)
        if not p then break end
        local i = indexAt(p)
        local e = starts[i + 1] - 2
        if p + qlen - 1 > e then
            pos = starts[i + 1]
        else
            local prev = byte(LOWER, p - 1)
            local tier = (p == starts[i]) and 1 or (WORD_BREAK[prev] and 2 or 3)
            local had = best[i]
            if not had or tier < had then
                best[i] = tier
                if tier == 1 then
                    tier1[#tier1 + 1] = i
                    if #tier1 >= maxResults then break end
                end
            end
            if tier <= 2 then pos = starts[i + 1] else pos = p + 1 end
        end
    end
    for i, t in pairs(best) do
        if t == 2 then tier2[#tier2 + 1] = i elseif t == 3 then tier3[#tier3 + 1] = i end
    end
    table.sort(tier2)
    table.sort(tier3)
    for _, list in ipairs({ tier1, tier2, tier3 }) do
        for _, i in ipairs(list) do
            if #out >= maxResults then return out end
            if not seen[i] then
                seen[i] = true
                out[#out + 1] = { id = ids[i], name = nameOf(i), quality = qualityOf(i) }
            end
        end
    end
    return out
end

-- ============================================================================
-- BLOCK HEADING: 2. UNIFIED SOURCE, VENDOR & GPS COORDINATE RESOLVER
-- ============================================================================
function ForeverIndex:GetItemSourceAndCoords(itemID, preferFaction)
    itemID = tonumber(itemID)
    if not itemID then return nil end

    local fac = preferFaction or (UnitFactionGroup and UnitFactionGroup("player")) or "Alliance"
    local result = {
        itemID = itemID,
        sourceType = nil,
        typeLabel = nil,
        zone = nil,
        npc = nil,
        mapId = nil,
        x = nil,
        y = nil,
        faction = nil,
        note = nil,
        vendors = nil,
    }

    -- 1. Check ETB 7,132 Forever Item Sources
    local etb = FVD.ETBSources and FVD.ETBSources[itemID]
    if etb then
        result.sourceType = etb[1]
        result.typeLabel = (FVD.SourceTypeLabels and FVD.SourceTypeLabels[etb[1]]) or etb[1]
        if etb[2] and etb[2] ~= "" then result.zone = etb[2] end
        if etb[3] and etb[3] ~= "" then result.npc = etb[3] end
    end

    -- 2. Check NaowhForever BiS Curated Sources (707 endgame & custom items)
    local bisSrc = FVD.BiSData and FVD.BiSData.sources and FVD.BiSData.sources[itemID]
    if bisSrc then
        result.typeLabel = result.typeLabel or bisSrc.t or "Drop"
        if bisSrc.z and bisSrc.z ~= "" then result.zone = result.zone or bisSrc.z end
        if bisSrc.n and bisSrc.n ~= "" then result.npc = result.npc or bisSrc.n end
    end

    -- 3. Check GearQuest 7,329 Exact Map Coordinates
    local coordRaw = FVD.Coordinates and FVD.Coordinates[itemID]
    if coordRaw then
        local spotsPart, notePart = string.match(coordRaw, "^(.-)##(.*)$")
        spotsPart = spotsPart or coordRaw
        if notePart and notePart ~= "" then
            result.note = notePart
        end
        local chosenSpot = nil
        local firstSpot = nil
        for spotStr in string.gmatch(spotsPart .. ";;", "(.-);;") do
            if spotStr ~= "" then
                local mapName, mapIdStr, xStr, yStr, npcName, spotFac =
                    string.match(spotStr, "^([^|]*)|([^|]*)|([^|]*)|([^|]*)|([^|]*)|([^|]*)$")
                if mapName then
                    local parsed = {
                        zone = (mapName ~= "" and mapName) or nil,
                        mapId = tonumber(mapIdStr),
                        x = tonumber(xStr),
                        y = tonumber(yStr),
                        npc = (npcName ~= "" and npcName) or nil,
                        faction = (spotFac ~= "" and spotFac) or nil,
                    }
                    if not firstSpot then firstSpot = parsed end
                    if not parsed.faction or parsed.faction == fac then
                        chosenSpot = parsed
                        break
                    end
                end
            end
        end
        chosenSpot = chosenSpot or firstSpot
        if chosenSpot then
            result.zone = chosenSpot.zone or result.zone
            result.mapId = chosenSpot.mapId
            result.x = chosenSpot.x
            result.y = chosenSpot.y
            result.npc = chosenSpot.npc or result.npc
            result.faction = chosenSpot.faction
        end
    end

    -- 4. Check Unlimited Profession Reagent Vendor Sellers
    local vList = FVD.VendorSellers and FVD.VendorSellers[itemID]
    if vList and FVD.VendorSellerNames then
        local names = {}
        for i = 1, min(#vList, 3) do
            local vName = FVD.VendorSellerNames[vList[i]]
            if vName then table.insert(names, vName) end
        end
        if #names > 0 then
            result.vendors = table.concat(names, ", ")
            result.typeLabel = result.typeLabel or "Unlimited Vendor"
            result.npc = result.npc or names[1]
        end
    end

    if not result.typeLabel and not result.zone and not result.npc and not result.x then
        return nil
    end
    return result
end

-- ============================================================================
-- BLOCK HEADING: 3. FLOATING 3D WAYPOINT HUD & ONE-CLICK MAP PIN ENGINE
-- ============================================================================
local WaypointHUD = nil
local activeWaypoint = nil

local function EnsureWaypointHUD()
    if WaypointHUD then return WaypointHUD end
    local createFn = (ns.Compat and ns.Compat.CreateBackdropFrame) or CreateFrame
    WaypointHUD = createFn("Button", "AltVaultWaypointHUD", UIParent)
    WaypointHUD:SetSize(310, 54)
    WaypointHUD:SetPoint("TOP", UIParent, "TOP", 0, -18)
    WaypointHUD:SetFrameStrata("HIGH")
    WaypointHUD:SetMovable(true)
    WaypointHUD:EnableMouse(true)
    WaypointHUD:RegisterForDrag("LeftButton")
    WaypointHUD:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    WaypointHUD:SetScript("OnDragStart", WaypointHUD.StartMoving)
    WaypointHUD:SetScript("OnDragStop", WaypointHUD.StopMovingOrSizing)

    if WaypointHUD.SetBackdrop then
        WaypointHUD:SetBackdrop({
            bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
            tile = true, tileSize = 16, edgeSize = 14,
            insets = { left = 3, right = 3, top = 3, bottom = 3 }
        })
        WaypointHUD:SetBackdropColor(0.03, 0.05, 0.09, 0.94)
        WaypointHUD:SetBackdropBorderColor(1.0, 0.82, 0.20, 0.98)
    end

    WaypointHUD.ArrowTex = WaypointHUD:CreateTexture(nil, "ARTWORK")
    WaypointHUD.ArrowTex:SetSize(32, 32)
    WaypointHUD.ArrowTex:SetPoint("LEFT", WaypointHUD, "LEFT", 10, 0)
    WaypointHUD.ArrowTex:SetTexture("Interface\\Minimap\\MinimapArrow")

    WaypointHUD.Title = WaypointHUD:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    WaypointHUD.Title:SetPoint("TOPLEFT", WaypointHUD.ArrowTex, "TOPRIGHT", 8, -2)
    WaypointHUD.Title:SetPoint("RIGHT", WaypointHUD, "RIGHT", -10, 0)
    WaypointHUD.Title:SetJustifyH("LEFT")
    WaypointHUD.Title:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")

    WaypointHUD.SubText = WaypointHUD:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    WaypointHUD.SubText:SetPoint("BOTTOMLEFT", WaypointHUD.ArrowTex, "BOTTOMRIGHT", 8, 2)
    WaypointHUD.SubText:SetPoint("RIGHT", WaypointHUD, "RIGHT", -10, 0)
    WaypointHUD.SubText:SetJustifyH("LEFT")
    WaypointHUD.SubText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")

    WaypointHUD:SetScript("OnClick", function(self, btn)
        if btn == "RightButton" then
            activeWaypoint = nil
            self:Hide()
            if C_Map and C_Map.ClearUserWaypoint then pcall(C_Map.ClearUserWaypoint) end
            print("|cffffcc00[AltVault GPS]:|r Waypoint cleared.")
        elseif activeWaypoint and ToggleWorldMap then
            pcall(ToggleWorldMap)
        end
    end)

    local accum = 0
    WaypointHUD:SetScript("OnUpdate", function(self, elapsed)
        accum = accum + (elapsed or 0.05)
        if accum < 0.08 then return end
        accum = 0
        if not activeWaypoint then self:Hide() return end

        local distInfo = ""
        if C_Map and C_Map.GetBestMapForUnit and C_Map.GetPlayerMapPosition then
            local okM, curMap = pcall(C_Map.GetBestMapForUnit, "player")
            if okM and curMap and (not activeWaypoint.mapId or activeWaypoint.mapId == 0 or activeWaypoint.mapId == curMap) then
                local okP, pos = pcall(C_Map.GetPlayerMapPosition, curMap, "player")
                if okP and pos and pos.x and pos.y and activeWaypoint.x and activeWaypoint.y then
                    local px, py = pos.x * 100, pos.y * 100
                    local dx = activeWaypoint.x - px
                    local dy = activeWaypoint.y - py
                    local dist = math.sqrt(dx * dx + dy * dy)
                    distInfo = format("  |cff00ff00(%.1f yds/units)|r", dist)
                    if GetPlayerFacing then
                        local facing = GetPlayerFacing() or 0
                        local angle = math.atan2(-dx, -dy) - facing
                        if self.ArrowTex.SetRotation then
                            pcall(self.ArrowTex.SetRotation, self.ArrowTex, angle)
                        end
                    end
                    if dist < 1.2 then
                        distInfo = "  |cff00ff00[ARRIVED!]|r"
                    end
                end
            end
        end
        self.SubText:SetText(format("|cff00ccff%s|r |cffffd100(%.1f, %.1f)|r%s  |cff888888[R-Click: Clear]|r",
            activeWaypoint.zone or "World Map", activeWaypoint.x or 0, activeWaypoint.y or 0, distInfo))
    end)

    WaypointHUD:Hide()
    return WaypointHUD
end

function ForeverIndex:GuideToItem(itemID)
    itemID = tonumber(itemID) or (type(itemID) == "string" and tonumber(string.match(itemID, "item:(%d+)")))
    if not itemID then return false end

    local src = self:GetItemSourceAndCoords(itemID)
    local info = self:Info(itemID)
    local itemName = (info and info.name) or (ns.Scanner and ns.Scanner.FetchItemInfo and ns.Scanner.FetchItemInfo(itemID)) or ("Item #" .. itemID)

    if not src or (not src.x and not src.zone and not src.npc) then
        print(format("|cffffcc00[AltVault GPS]:|r No fixed map coordinates on record for |cffffff00%s|r (World Drop / RNG).", itemName))
        return false
    end

    local hud = EnsureWaypointHUD()
    activeWaypoint = {
        itemID = itemID,
        name = itemName,
        zone = src.zone or "Azeroth",
        npc = src.npc or src.typeLabel or "Target",
        mapId = src.mapId,
        x = src.x or 50.0,
        y = src.y or 50.0,
    }

    hud.Title:SetText(format("|cffffd100📍 %s|r  |cffffffff— %s|r", itemName, activeWaypoint.npc))
    hud.SubText:SetText(format("|cff00ccff%s|r |cffffd100(%.1f, %.1f)|r  |cff888888[R-Click: Clear]|r",
        activeWaypoint.zone, activeWaypoint.x, activeWaypoint.y))
    hud:Show()

    -- Set Native WoW Map Pin if mapId is available
    if src.mapId and src.mapId > 0 and src.x and src.y and C_Map and C_Map.SetUserWaypoint and UiMapPoint and UiMapPoint.CreateFromCoordinates then
        pcall(function()
            local pt = UiMapPoint.CreateFromCoordinates(src.mapId, src.x / 100, src.y / 100)
            C_Map.SetUserWaypoint(pt)
            if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then
                C_SuperTrack.SetSuperTrackedUserWaypoint(true)
            end
        end)
    end

    -- Also feed TomTom if the player runs TomTom
    if _G.TomTom and _G.TomTom.AddWaypoint and src.mapId and src.mapId > 0 and src.x and src.y then
        pcall(_G.TomTom.AddWaypoint, _G.TomTom, src.mapId, src.x / 100, src.y / 100, {
            title = itemName .. " (" .. (src.npc or "") .. ")"
        })
    end

    if PlaySound then pcall(PlaySound, 856) end
    print(format("|cff00ff00[AltVault GPS]:|r Locked waypoint for |cffffff00[%s]|r -> |cff00ccff%s|r %s |cffffd100(%.1f, %.1f)|r!",
        itemName, activeWaypoint.npc, activeWaypoint.zone, activeWaypoint.x, activeWaypoint.y))
    return true
end

-- ============================================================================
-- BLOCK HEADING: 4. OFFICIAL FOREVER BIS RANKINGS & SPEC STAT WEIGHT SCORER
-- ============================================================================
local bisLookupByItem = nil

local function EnsureBiSLookup()
    if bisLookupByItem then return bisLookupByItem end
    bisLookupByItem = {}
    local specs = FVD.BiSData and FVD.BiSData.specs
    if type(specs) ~= "table" then return bisLookupByItem end

    for _, specObj in ipairs(specs) do
        local cToken = specObj.class
        local sName = specObj.name
        for slotID, itemList in pairs(specObj.slots or {}) do
            for rankIdx, id in ipairs(itemList) do
                if id and rankIdx <= 5 then
                    bisLookupByItem[id] = bisLookupByItem[id] or {}
                    table.insert(bisLookupByItem[id], {
                        class = cToken,
                        specName = sName,
                        slotID = slotID,
                        rank = rankIdx,
                    })
                end
            end
        end
    end
    return bisLookupByItem
end

function ForeverIndex:GetBiSRankingsForItem(itemID, filterClass)
    itemID = tonumber(itemID)
    if not itemID then return nil end
    local map = EnsureBiSLookup()
    local list = map[itemID]
    if not list then return nil end
    if not filterClass then return list end
    local filtered = {}
    for _, entry in ipairs(list) do
        if entry.class == filterClass then
            table.insert(filtered, entry)
        end
    end
    return (#filtered > 0) and filtered or list
end

function ForeverIndex:IsOfficialForeverBiS(itemID, filterClass)
    local list = self:GetBiSRankingsForItem(itemID, filterClass)
    return (list and #list > 0) and true or false, list
end

-- ============================================================================
-- BLOCK HEADING: 5. EARLY-LEVEL GOLD, TWINK ENCHANT BASE & AH FLIP ADVISOR
-- ============================================================================
local CURATED_GOLD_TARGETS = {
    -- Tier A: No-Level White Items that NEVER bind when enchanted (Reusable Twink Heirlooms!)
    [7005]  = { cat = "TWINK_BASE", title = "Unbound Twink Weapon Base", tip = "Enchant with Fiery Weapon / +30 Spell Power / Crusader — NEVER binds on equip or trade!" },
    [2901]  = { cat = "TWINK_BASE", title = "Unbound 2H Twink Base", tip = "Mining Pick (No Req Level) — Enchant with +9 Str / +22 Int / Crusader for Lvl 1 alts!" },
    [5956]  = { cat = "TWINK_BASE", title = "Unbound 1H Twink Hammer", tip = "Blacksmith Hammer (No Req Level) — Never binds when enchanted!" },
    [6256]  = { cat = "TWINK_BASE", title = "Unbound Fishing Pole", tip = "Can be equipped at Level 1 by any class." },
    [14092] = { cat = "TWINK_BASE", title = "No-Level White Boots Base", tip = "Enchant with Minor Speed (+8% Run Speed) or +7 Agility — resellable on AH after use!" },
    [6238]  = { cat = "TWINK_BASE", title = "No-Level White Robe Base", tip = "Enchant with +100 Health or +100 Mana (+4 Stats) — Ultimate Level 1 Twink Chest!" },
    [6241]  = { cat = "TWINK_BASE", title = "No-Level White Linen Robe", tip = "Enchant with +100 Health or +3 All Stats — Never binds when equipped!" },
    [2570]  = { cat = "TWINK_BASE", title = "No-Level White Cloak Base", tip = "Enchant with +70 Armor or +5 All Resistance or Lesser Agility!" },
    [3428]  = { cat = "TWINK_BASE", title = "Cosmetic Shirt Flip", tip = "High-demand RP / FaceVault Runway shirt base." },
    -- Tier B: High-Velocity Early Bottlenecks & Quest Turn-Ins
    [2589]  = { cat = "AH_BOTTLENECK", title = "Early Tailoring / First Aid Bottleneck", tip = "High volume starter flip — convert to Bolts or Enchanted White Robes." },
    [2592]  = { cat = "AH_BOTTLENECK", title = "Prime Level 15-25 Cloth Bottleneck", tip = "Always in massive demand for Wool Bandages & Bags." },
    [4306]  = { cat = "AH_BOTTLENECK", title = "Silk Cloth Stockpile", tip = "Convert to Small Silk Packs (10-slot bags) or Heavy Silk Bandages." },
    [4338]  = { cat = "AH_BOTTLENECK", title = "Mageweave Quest & Bag Bottleneck", tip = "Used for Runecloth/Mageweave Bags & City Reputation turn-ins." },
    [2770]  = { cat = "AH_BOTTLENECK", title = "Copper Ore / Bar Starter Flip", tip = "Smelt Copper Bars on Mining alt for 2x-3x raw ore value on AH." },
    [2771]  = { cat = "AH_BOTTLENECK", title = "Tin Ore / Bronze Bar Bottleneck", tip = "Combine with Copper to smelt Bronze Bars for Engineering/BS." },
    [2772]  = { cat = "AH_BOTTLENECK", title = "Iron Ore / Heavy Stone Bottleneck", tip = "Huge Engineering & Blacksmithing bottleneck at skill 125-175." },
    [3829]  = { cat = "QUEST_FLIP",    title = "Badlands Quest Turn-In (Frost Oil)", tip = "Required for Badlands quests — sells for 3x-5x crafting cost on AH!" },
    [4389]  = { cat = "QUEST_FLIP",    title = "Badlands Quest Turn-In (Gyrochronatom)", tip = "Required for Badlands quests — huge profit margin for Engineers!" },
    [3864]  = { cat = "QUEST_FLIP",    title = "Gem Bottleneck (Citrine)", tip = "Required for Blacksmithing, Engineering & Badlands quests." },
    [10940] = { cat = "ENCHANT_FLIP",  title = "Strange Dust (Starter Twink Enchant Mat)", tip = "Core reagent for +50 HP Chest & Minor Speed/Stats enchants!" },
    [10938] = { cat = "ENCHANT_FLIP",  title = "Lesser Magic Essence", tip = "Used for early weapon & bracer enchants; high early-server velocity." },
    [10939] = { cat = "ENCHANT_FLIP",  title = "Greater Magic Essence", tip = "Used for +15/+20 Bracer/Chest enchants." },
}

function ForeverIndex:GetGoldFlipAdvisory(itemID)
    itemID = tonumber(itemID)
    if not itemID then return nil end

    if CURATED_GOLD_TARGETS[itemID] then
        return CURATED_GOLD_TARGETS[itemID]
    end

    local info = self:Info(itemID)
    if info then
        -- Any Unbound (bonding == 0) White/Common Weapon or Armor with reqLevel <= 2 is a No-Level Twink Enchant Base!
        if info.bonding == 0 and info.quality == 1 and (info.classID == 2 or info.classID == 4) and (info.reqLevel or 0) <= 2 then
            if info.invType == 1 or info.invType == 3 or info.invType == 5 or info.invType == 7 or info.invType == 8
                or info.invType == 9 or info.invType == 10 or info.invType == 13 or info.invType == 14
                or info.invType == 16 or info.invType == 17 or info.invType == 20 or info.invType == 21 then
                return {
                    cat = "TWINK_BASE",
                    title = "Unbound No-Level Enchant Base",
                    tip = "White quality & Unbound (ReqLvl <= 2): Can be enchanted for Level 1 alts and NEVER binds!"
                }
            end
        end
        -- Recipes sold by vendors (bonding == 0, classID == 9) are classic Limited Vendor Recipe Flips!
        if info.classID == 9 and info.bonding == 0 then
            local src = self:GetItemSourceAndCoords(itemID)
            if src and (src.sourceType == "vendor" or src.typeLabel == "Vendor") then
                return {
                    cat = "VENDOR_FLIP",
                    title = "Tradeable Vendor Recipe Flip",
                    tip = format("Sold by %s (%s) — Buy from vendor & flip on Auction House!", src.npc or "Vendor", src.zone or "Azeroth")
                }
            end
        end
    end

    if FVD.VendorSellers and FVD.VendorSellers[itemID] then
        local src = self:GetItemSourceAndCoords(itemID)
        return {
            cat = "UNLIMITED_VENDOR",
            title = "Unlimited Vendor Reagent (Do Not Overpay on AH!)",
            tip = format("Sold in unlimited stock by %s.", (src and src.vendors) or "Trade Vendors")
        }
    end

    return nil
end

-- ============================================================================
-- BLOCK HEADING: 6. DISENCHANT EV, ALT-ACTION ROUTING & SKILL-UP THRESHOLDS
-- ============================================================================
local DE_UNCOMMON_BANDS = {
    { 5,  15, 1,   "80% Strange Dust (1-2), 20% Lesser Magic Essence (1-2)" },
    { 16, 20, 25,  "75% Strange Dust (2-3), 20% Greater Magic Essence, 5% Small Glimmering Shard" },
    { 21, 25, 25,  "75% Strange Dust (4-6), 15% Lesser Astral Essence, 10% Small Glimmering Shard" },
    { 26, 30, 50,  "75% Soul Dust (1-2), 20% Greater Astral Essence, 5% Large Glimmering Shard" },
    { 31, 35, 75,  "75% Soul Dust (2-5), 20% Lesser Mystic Essence, 5% Small Glowing Shard" },
    { 36, 40, 100, "75% Vision Dust (1-2), 20% Greater Mystic Essence, 5% Large Glowing Shard" },
    { 41, 45, 125, "75% Vision Dust (2-5), 20% Lesser Nether Essence, 5% Small Radiant Shard" },
    { 46, 50, 150, "75% Dream Dust (1-2), 20% Greater Nether Essence, 5% Large Radiant Shard" },
    { 51, 55, 175, "75% Dream Dust (2-5), 20% Lesser Eternal Essence, 5% Small Brilliant Shard" },
    { 56, 65, 200, "75% Illusion Dust (1-5), 20% Greater Eternal Essence, 5% Large Brilliant Shard" },
}

local DE_RARE_BANDS = {
    { 1,  25, 25,  "100% Small Glimmering Shard" },
    { 26, 30, 50,  "100% Large Glimmering Shard" },
    { 31, 35, 75,  "100% Small Glowing Shard" },
    { 36, 40, 100, "100% Large Glowing Shard" },
    { 41, 45, 125, "100% Small Radiant Shard" },
    { 46, 50, 150, "100% Large Radiant Shard" },
    { 51, 55, 175, "100% Small Brilliant Shard" },
    { 56, 80, 200, "99.5% Large Brilliant Shard, 0.5% Nexus Crystal" },
}

function ForeverIndex:GetDisenchantInfo(itemID)
    itemID = tonumber(itemID)
    if not itemID then return nil end
    local info = self:Info(itemID)
    local quality, iLvl, classID, invType
    if info then
        quality, iLvl, classID, invType = info.quality, info.itemLevel, info.classID, info.invType
    elseif ns.Scanner and ns.Scanner.FetchItemInfo then
        local _, _, q, il, _, _, _, _, eqLoc, _, _, cID = ns.Scanner.FetchItemInfo(itemID)
        quality, iLvl, classID = q, il, cID
        if eqLoc == "INVTYPE_BODY" or eqLoc == "INVTYPE_TABARD" or eqLoc == "INVTYPE_BAG" then return nil end
    end
    if not quality or quality < 2 or quality > 4 then return nil end
    if classID ~= 2 and classID ~= 4 then return nil end
    if invType == 4 or invType == 18 or invType == 19 or invType == 24 then return nil end

    iLvl = (iLvl and iLvl > 0) and iLvl or 20
    local reqSkill = 1
    local summary = "Enchanting Shards / Dust"

    if quality == 2 then
        for _, b in ipairs(DE_UNCOMMON_BANDS) do
            if iLvl >= b[1] and iLvl <= b[2] then
                reqSkill = b[3]
                summary = b[4]
                break
            end
        end
    elseif quality == 3 then
        for _, b in ipairs(DE_RARE_BANDS) do
            if iLvl >= b[1] and iLvl <= b[2] then
                reqSkill = b[3]
                summary = b[4]
                break
            end
        end
    elseif quality == 4 then
        reqSkill = (iLvl >= 56) and 225 or 175
        summary = (iLvl >= 56) and "100% Nexus Crystal (1-2)" or "100% Radiant / Brilliant Shards (2-4)"
    end

    -- Check if any Alt on the account has Enchanting >= reqSkill
    local bestEnchanter = nil
    if AltVaultDB and AltVaultDB.Characters then
        for cName, cData in pairs(AltVaultDB.Characters) do
            if cData.professions and type(cData.professions.all) == "table" then
                for _, p in ipairs(cData.professions.all) do
                    if p.name == "Enchanting" and (p.rank or 0) >= reqSkill then
                        bestEnchanter = format("%s (%d)", cName, p.rank or 1)
                        break
                    end
                end
            end
        end
    end

    return {
        reqSkill = reqSkill,
        summary = summary,
        enchanterAlt = bestEnchanter,
    }
end

function ForeverIndex:GetRecipeThresholds(itemID, itemName)
    itemID = tonumber(itemID)
    local info = itemID and self:Info(itemID)
    if info and info.teaches and FVD.ThresholdsBySpell and FVD.ThresholdsBySpell[info.teaches] then
        return FVD.ThresholdsBySpell[info.teaches]
    end
    local checkName = itemName or (info and info.name)
    if checkName and FVD.ThresholdsByName then
        local clean = lower(checkName):gsub("^recipe:%s*", ""):gsub("^plans:%s*", ""):gsub("^pattern:%s*", "")
            :gsub("^schematic:%s*", ""):gsub("^formula:%s*", ""):gsub("^manual:%s*", "")
        if FVD.ThresholdsByName[clean] then
            return FVD.ThresholdsByName[clean]
        end
    end
    return nil
end

-- ============================================================================
-- BLOCK HEADING: 7. 12-DIMENSION "GOD TOOLTIP" INJECTOR
-- ============================================================================
local function AppendForeverIntelligenceToTooltip(tooltip, itemLinkOrID)
    if not tooltip or not itemLinkOrID then return end
    local itemID = (type(itemLinkOrID) == "number" and itemLinkOrID)
        or tonumber(string.match(tostring(itemLinkOrID), "item:(%d+)"))
    if not itemID or itemID <= 0 then return end

    -- Avoid duplicate injection on the same tooltip pass
    if tooltip._avLastIntelItemID == itemID and (GetTime() - (tooltip._avLastIntelTime or 0)) < 0.05 then
        return
    end
    tooltip._avLastIntelItemID = itemID
    tooltip._avLastIntelTime = GetTime()

    local info = ForeverIndex:Info(itemID)
    local src = ForeverIndex:GetItemSourceAndCoords(itemID)
    local _, playerClass = UnitClass("player")
    local bisList = ForeverIndex:GetBiSRankingsForItem(itemID, playerClass)
    local goldAdv = ForeverIndex:GetGoldFlipAdvisory(itemID)
    local deInfo = ForeverIndex:GetDisenchantInfo(itemID)
    local thresholds = ForeverIndex:GetRecipeThresholds(itemID, info and info.name)

    local sellPrice = nil
    local getInfoFn = (C_Item and C_Item.GetItemInfo) or GetItemInfo
    if getInfoFn then
        local ok, _, _, _, _, _, _, _, _, _, _, sp = pcall(getInfoFn, itemLinkOrID or itemID)
        if ok and type(sp) == "number" then
            sellPrice = sp
        end
    end

    if not src and not bisList and not goldAdv and not deInfo and not thresholds and not (info and info.lockSkill) and sellPrice == nil then
        return
    end

    tooltip:AddLine(" ")
    tooltip:AddLine("|cffffd100[AltVault Forever Intelligence]|r")

    -- 0. Vendor Sell Price (Always visible on Auction House, Chat & Vendor tooltips!)
    if sellPrice ~= nil then
        if sellPrice > 0 then
            local coinText = (GetCoinTextureString and GetCoinTextureString(sellPrice))
                or format("%dg %ds %dc", math.floor(sellPrice / 10000), math.floor((sellPrice % 10000) / 100), sellPrice % 100)
            tooltip:AddDoubleLine("|cffffd100🪙 Vendor Sell Price:|r", "|cffffffff" .. coinText .. "|r", 1, 0.82, 0, 1, 1, 1)
        else
            tooltip:AddDoubleLine("|cffffd100🪙 Vendor Sell Price:|r", "|cff888888No Vendor Value (0c)|r", 1, 0.82, 0, 0.53, 0.53, 0.53)
        end
    end

    -- 1. Official BiS Badges
    if bisList and #bisList > 0 then
        local parts = {}
        for i = 1, min(#bisList, 3) do
            local b = bisList[i]
            table.insert(parts, format("#%d %s", b.rank, b.specName))
        end
        tooltip:AddDoubleLine("|cffff8000🏆 Forever BiS:|r", "|c00ff96" .. table.concat(parts, " • ") .. "|r", 1, 0.82, 0, 0, 1, 0.6)
    end

    -- 2. Source + NPC + Exact Map Coordinates
    if src then
        local rightStr = ""
        if src.npc and src.npc ~= "" then
            rightStr = "|cffffffff" .. src.npc .. "|r"
        end
        if src.zone and src.zone ~= "" then
            rightStr = (rightStr ~= "") and (rightStr .. " — |cff00ccff" .. src.zone .. "|r") or ("|cff00ccff" .. src.zone .. "|r")
        end
        if src.x and src.y and src.x > 0 then
            rightStr = rightStr .. format(" |cffffd100(%.1f, %.1f)|r", src.x, src.y)
        end
        if rightStr ~= "" then
            tooltip:AddDoubleLine("|cff00ccff📍 " .. (src.typeLabel or "Source") .. ":|r", rightStr, 0, 0.8, 1, 1, 1, 1)
        end
    end

    -- 3. Recipe Skill-Up Bands [Orange / Yellow / Green / Grey]
    if thresholds then
        tooltip:AddDoubleLine(
            "|cffffaa00📈 Skill-Up Bands:|r",
            format("|cffff8000%d|r / |cffffff00%d|r / |cff40ff40%d|r / |cffaaaaaa%d|r",
                thresholds[1] or 1, thresholds[2] or 1, thresholds[3] or 1, thresholds[4] or 1)
        )
    end

    -- 4. Disenchant EV & Enchanter Alt Routing
    if deInfo then
        local deLabel = format("Skill %d", deInfo.reqSkill)
        if deInfo.enchanterAlt then
            deLabel = deLabel .. " |cff00ff96(" .. deInfo.enchanterAlt .. ")|r"
        end
        tooltip:AddDoubleLine("|cffcc66ff✨ Disenchant (" .. deLabel .. "):|r", "|cffdddddd" .. deInfo.summary .. "|r")
    end

    -- 5. Lockbox Lockpicking Requirement
    if info and info.lockSkill then
        tooltip:AddDoubleLine("|cffffcc00🔐 Lockbox:|r", format("|cffffffffRequires Lockpicking %d|r", info.lockSkill))
    end

    -- 6. Early Gold / AH Flip / Twink Enchant Base Advisory
    if goldAdv then
        tooltip:AddDoubleLine("|cff00ff00💰 " .. goldAdv.title .. ":|r", "|cfffff569" .. goldAdv.tip .. "|r")
    end

    if src and (src.x or src.zone) then
        tooltip:AddLine("|cff88ccffAlt+RightClick item to lock 3D GPS Waypoint Arrow!|r")
    end

    tooltip:Show()
end

-- Hook Tooltips (Compatible with 16001 TooltipDataProcessor AND Classic OnTooltipSetItem)
local function HookTooltipsForForeverIntelligence()
    if _G.TooltipDataProcessor and _G.TooltipDataProcessor.AddTooltipPostCall and _G.Enum and _G.Enum.TooltipDataType then
        pcall(_G.TooltipDataProcessor.AddTooltipPostCall, _G.Enum.TooltipDataType.Item, function(tooltip, data)
            if tooltip and data and data.id then
                AppendForeverIntelligenceToTooltip(tooltip, data.id)
            end
        end)
    end

    for _, ttName in ipairs({ "GameTooltip", "ItemRefTooltip" }) do
        local tt = _G[ttName]
        if tt and tt.HookScript then
            pcall(tt.HookScript, tt, "OnTooltipSetItem", function(self)
                if self.GetItem then
                    local _, link = self:GetItem()
                    if link then
                        AppendForeverIntelligenceToTooltip(self, link)
                    end
                end
            end)
        end
    end

    -- Alt+RightClick or Alt+Click on any modified item link triggers GPS Waypoint!
    if hooksecurefunc and _G.HandleModifiedItemClick then
        hooksecurefunc("HandleModifiedItemClick", function(link)
            if link and IsAltKeyDown and IsAltKeyDown() then
                ForeverIndex:GuideToItem(link)
            end
        end)
    end
end

-- ============================================================================
-- BLOCK HEADING: 8. "FACEVAULT" LIVE 3D RUNWAY CODEC, REACTION VOTES & TOAST
-- ============================================================================
FaceVault.REACTION_TYPES = {
    LIKE  = { code = 1, icon = "👍", label = "Like (+1)",  color = "00ff96" },
    FIRE  = { code = 2, icon = "🔥", label = "Fire (+2)",  color = "ff8000" },
    CROWN = { code = 3, icon = "👑", label = "Crown (+3)", color = "ffd100" },
}

-- Celebratory Fanfare Toast when a player reacts to your FaceVault Look or Profile!
local VoteToastFrame = nil
function FaceVault:TriggerVoteFanfareToast(voterName, reactionType, targetLookTitle)
    if not VoteToastFrame then
        local createFn = (ns.Compat and ns.Compat.CreateBackdropFrame) or CreateFrame
        VoteToastFrame = createFn("Frame", "AltVaultFaceVaultToast", UIParent)
        VoteToastFrame:SetSize(360, 58)
        VoteToastFrame:SetPoint("TOP", UIParent, "TOP", 0, -82)
        VoteToastFrame:SetFrameStrata("DIALOG")
        if VoteToastFrame.SetBackdrop then
            VoteToastFrame:SetBackdrop({
                bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
                edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
                tile = true, tileSize = 16, edgeSize = 16,
                insets = { left = 4, right = 4, top = 4, bottom = 4 }
            })
            VoteToastFrame:SetBackdropColor(0.05, 0.03, 0.10, 0.96)
            VoteToastFrame:SetBackdropBorderColor(1.0, 0.84, 0.15, 1.0)
        end
        VoteToastFrame.Header = VoteToastFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        VoteToastFrame.Header:SetPoint("TOP", VoteToastFrame, "TOP", 0, -8)
        VoteToastFrame.Header:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE")

        VoteToastFrame.Body = VoteToastFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        VoteToastFrame.Body:SetPoint("BOTTOM", VoteToastFrame, "BOTTOM", 0, 9)
        VoteToastFrame.Body:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    end

    local rInfo = FaceVault.REACTION_TYPES[reactionType or "LIKE"] or FaceVault.REACTION_TYPES.LIKE
    VoteToastFrame.Header:SetText("|cffffd100★ FACEVAULT RUNWAY APPLAUSE! ★|r")
    VoteToastFrame.Body:SetText(format("|cffffff00%s|r reacted with |cff%s%s %s|r to your |cff00ccff%s|r!",
        voterName or "A Player", rInfo.color, rInfo.icon, rInfo.label, targetLookTitle or "3D Runway Look"))
    VoteToastFrame:SetAlpha(1.0)
    VoteToastFrame:Show()

    if PlaySound then pcall(PlaySound, 888) end
    C_Timer.After(4.5, function()
        if VoteToastFrame then VoteToastFrame:Hide() end
    end)
end

-- Encodes the active 3D Stage (including tried-on Dress-Up items!) into a compact FaceVault Runway Packet
function FaceVault:EncodeCurrentRunwayLook(customTitle)
    local Armory = ns.Armory
    local curName = (Armory and Armory.state and Armory.state.activeDisplayedCharName) or UnitName("player") or "Hero"
    local charData = (Armory and Armory.state and Armory.state.activeDisplayedCharData)
        or (AltVaultDB and AltVaultDB.Characters and AltVaultDB.Characters[curName])
        or {}

    local race = string.gsub(charData.race or "Human", "[:|,;]", "")
    local sex = tonumber(charData.sex) or 2
    local class = charData.class or "WARRIOR"
    local pose = (Armory and Armory.state and Armory.state.currentPoseIndex) or 1
    local title = string.gsub(customTitle or (curName .. "'s Look"), "[|;]", "")

    -- Merge equipped gear + any custom Dress-Up items currently tried on the 3D Stage!
    local mergedSlots = {}
    if charData.gear then
        for sID, linkOrID in pairs(charData.gear) do
            local id = (type(linkOrID) == "number" and linkOrID) or tonumber(string.match(tostring(linkOrID), "item:(%d+)"))
            if id and id > 0 then mergedSlots[sID] = id end
        end
    end
    if charData.runwayOutfit then
        for sID, id in pairs(charData.runwayOutfit) do
            if tonumber(id) and tonumber(id) > 0 then mergedSlots[sID] = tonumber(id) end
        end
    end
    if Armory and Armory.state and Armory.state.triedOnSlots then
        for sID, id in pairs(Armory.state.triedOnSlots) do
            if tonumber(id) and tonumber(id) > 0 then mergedSlots[sID] = tonumber(id) end
        end
    end

    local slotPairs = {}
    for _, sID in ipairs({ 1, 3, 4, 5, 6, 7, 8, 9, 10, 15, 16, 17, 19 }) do
        if mergedSlots[sID] then
            table.insert(slotPairs, sID .. ":" .. mergedSlots[sID])
        end
    end
    local gearStr = (#slotPairs > 0) and table.concat(slotPairs, ",") or "-"

    return format("FV1;%s;%s;%d;%s;%d;%s;%s", curName, class, sex, race, pose, gearStr, title), mergedSlots
end

function FaceVault:DecodeRunwayLook(encodedStr)
    if type(encodedStr) ~= "string" then return nil end
    local ver, charName, class, sexStr, race, poseStr, gearStr, title =
        string.match(encodedStr, "^(FV1);([^;]+);([^;]+);(%d+);([^;]+);(%d+);([^;]+);(.*)$")
    if ver ~= "FV1" or not charName then return nil end

    local outfit = {}
    if gearStr and gearStr ~= "-" then
        for tok in string.gmatch(gearStr, "([^,]+)") do
            local sID, iID = string.match(tok, "^(%d+):(%d+)$")
            if sID and iID then
                outfit[tonumber(sID)] = tonumber(iID)
                if C_Item and C_Item.RequestLoadItemDataByID then
                    pcall(C_Item.RequestLoadItemDataByID, tonumber(iID))
                end
            end
        end
    end

    return {
        name = charName,
        class = class,
        sex = tonumber(sexStr) or 2,
        race = race,
        pose = tonumber(poseStr) or 1,
        runwayOutfit = outfit,
        gear = outfit,
        title = (title and title ~= "") and title or (charName .. "'s Look"),
    }
end

-- Broadcasts your current 3D Dress-Up Look to the FaceVault Wall AND posts a clickable link in Chat!
function FaceVault:PostCurrentLookToFaceVault(shareToChatChannel)
    local encoded, mergedSlots = self:EncodeCurrentRunwayLook()
    if not encoded then return end

    local playerName = UnitName("player")
    if playerName and AltVaultDB and AltVaultDB.Characters and AltVaultDB.Characters[playerName] then
        AltVaultDB.Characters[playerName].runwayOutfit = mergedSlots
        AltVaultDB.Characters[playerName].runwayPose = (ns.Armory and ns.Armory.state and ns.Armory.state.currentPoseIndex) or 1
    end

    -- 1. Broadcast over AltVault Mesh (`FV_LOOK|<encoded>`) only to active guild/group channels and explicitly consented peers
    if ns.GuildNet and ns.GuildNet.EnqueuePacket then
        ns.GuildNet.EnqueuePacket("FV_LOOK|" .. encoded)
        local fac = UnitFactionGroup("player") or "Alliance"
        for peerName, peerData in pairs((AltVaultDB and AltVaultDB.GuildNetwork) or {}) do
            if peerName ~= playerName and peerData.isSynced == true and not peerData.isPublicFaceVault and peerData.isOnline ~= false and (not peerData.faction or peerData.faction == fac) then
                ns.GuildNet.EnqueuePacket("FV_LOOK|" .. encoded, "WHISPER", peerName)
            end
        end
    end

    -- 2. Echo clickable hyperlink into local chat so the player can also Shift-Click or see it immediately
    local clickableLink = format("|cff00ff96|Hgarrmission:altvault:fv:%s|h[FaceVault Runway: %s's 3D Look ★ (Click to Dress & Vote)]|h|r",
        encoded, playerName or "Hero")
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[FaceVault Runway]:|r Broadcasted your live 3D Dress-Up Look! " .. clickableLink)
    end

    if shareToChatChannel and SendChatMessage then
        pcall(SendChatMessage, format("[FaceVault Runway] Check out my 3D Look in AltVault (/av)!"), shareToChatChannel)
    end
    if PlaySound then pcall(PlaySound, 856) end
end

-- Intercept clicks on `[FaceVault Runway: ...]` and `[AltVault GPS: ...]` hyperlinks in chat!
local function HookFaceVaultChatLinks()
    if not hooksecurefunc or not _G.SetItemRef then return end
    hooksecurefunc("SetItemRef", function(link)
        if type(link) ~= "string" then return end
        local gpsItemID = string.match(link, "^garrmission:altvault:gps:(%d+)$")
        if gpsItemID then
            if HideUIPanel and _G.ItemRefTooltip then pcall(HideUIPanel, _G.ItemRefTooltip) end
            ForeverIndex:GuideToItem(tonumber(gpsItemID))
            return
        end
        local vigMap, vigX, vigY, vigName = string.match(link, "^garrmission:altvault:vig:(%d+):([%d%.]+):([%d%.]+):(.+)$")
        if vigMap and vigX and vigY then
            if HideUIPanel and _G.ItemRefTooltip then pcall(HideUIPanel, _G.ItemRefTooltip) end
            local hud = EnsureWaypointHUD()
            activeWaypoint = {
                itemID = 0,
                name = vigName or "Rare Vignette",
                zone = (GetRealZoneText and GetRealZoneText()) or "Azeroth",
                npc = "Live Vignette Radar",
                mapId = tonumber(vigMap),
                x = tonumber(vigX) or 50.0,
                y = tonumber(vigY) or 50.0,
            }
            hud.Title:SetText(format("|cffff8000⚡ %s|r  |cffffffff— Rare Radar|r", activeWaypoint.name))
            hud.SubText:SetText(format("|cff00ccff%s|r |cffffd100(%.1f, %.1f)|r  |cff888888[R-Click: Clear]|r",
                activeWaypoint.zone, activeWaypoint.x, activeWaypoint.y))
            hud:Show()
            if C_Map and C_Map.SetUserWaypoint and UiMapPoint and UiMapPoint.CreateFromCoordinates and activeWaypoint.mapId and activeWaypoint.mapId > 0 then
                pcall(function()
                    local pt = UiMapPoint.CreateFromCoordinates(activeWaypoint.mapId, activeWaypoint.x / 100, activeWaypoint.y / 100)
                    C_Map.SetUserWaypoint(pt)
                    if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then
                        C_SuperTrack.SetSuperTrackedUserWaypoint(true)
                    end
                end)
            end
            return
        end
        local encoded = string.match(link, "^garrmission:altvault:fv:(.+)$")
        if encoded then
            if HideUIPanel and _G.ItemRefTooltip then pcall(HideUIPanel, _G.ItemRefTooltip) end
            local decoded = FaceVault:DecodeRunwayLook(encoded)
            if decoded and _G.AltVaultMainPanel then
                AltVaultDB.GuildNetwork = AltVaultDB.GuildNetwork or {}
                local peer = AltVaultDB.GuildNetwork[decoded.name] or {
                    faction = UnitFactionGroup("player") or "Alliance",
                    profs = {}, slotGS = {}, gear = {}, mats = {}, cons = {},
                }
                peer.class = decoded.class or peer.class or "WARRIOR"
                peer.race = decoded.race or peer.race or "Human"
                peer.sex = decoded.sex or peer.sex or 2
                peer.runwayOutfit = decoded.runwayOutfit
                peer.runwayPose = decoded.pose
                peer.isPublicFaceVault = true
                if not next(peer.gear or {}) then peer.gear = decoded.runwayOutfit end
                AltVaultDB.GuildNetwork[decoded.name] = peer

                _G.AltVaultMainPanel:Show()
                if ns.Armory and ns.Armory.state then
                    ns.Armory.state.currentPoseIndex = decoded.pose or 1
                    ns.Armory.state.prefer2DReelView = false
                    ns.Armory.state.prefer3DStageForOffline = true
                end
                if _G.AltVaultMainPanel.SelectSidebarCharacter then
                    _G.AltVaultMainPanel:SelectSidebarCharacter(decoded.name, true)
                end
                print(format("|cff00ff96[FaceVault Runway]:|r Loaded |cffffff00%s|r's 3D Runway Look onto the Armory Stage!", decoded.name))
            end
        end
    end)
end

-- ============================================================================
-- BLOCK HEADING: 9. PASSIVE ENCOUNTER TRACKER & GROUP-LOOT BIS ADVISOR
-- ============================================================================
local function RecordPlayerEncounter(unitToken)
    if not unitToken or not UnitExists(unitToken) or not UnitIsPlayer(unitToken) then return end
    if UnitIsUnit(unitToken, "player") then return end

    local rawName = UnitName(unitToken)
    local cleanName = (ns.GuildNet and ns.GuildNet.StripRealm and ns.GuildNet.StripRealm(rawName)) or rawName
    if not cleanName or cleanName == "" or cleanName == "Unknown" then return end

    local myFac = UnitFactionGroup("player") or "Alliance"
    local unitFac = UnitFactionGroup(unitToken)
    if unitFac and unitFac ~= myFac then return end

    if not AltVaultDB then return end
    AltVaultDB.EncounterHistory = AltVaultDB.EncounterHistory or {}
    local enc = AltVaultDB.EncounterHistory[cleanName] or { count = 0, firstSeen = date("%Y-%m-%d") }
    local now = time()
    if (now - (enc.lastTimestamp or 0)) > 120 then
        enc.count = (enc.count or 0) + 1
        enc.lastTimestamp = now
        enc.lastZone = (GetRealZoneText and GetRealZoneText()) or "Azeroth"
        AltVaultDB.EncounterHistory[cleanName] = enc
    end

    -- Only update live status if this player is ALREADY an explicitly synced peer (never add random mouseover players!)
    if AltVaultDB.GuildNetwork and AltVaultDB.GuildNetwork[cleanName] and AltVaultDB.GuildNetwork[cleanName].isSynced == true then
        local peer = AltVaultDB.GuildNetwork[cleanName]
        local lvl = UnitLevel(unitToken)
        if lvl and lvl > 0 then peer.level = lvl end
        peer.lastSeen = date("%Y-%m-%d %H:%M")
        peer.lastSeenTimestamp = now
        peer.isOnline = true
    end
end

-- ============================================================================
-- BLOCK HEADING: 10. STEALTH ZERO-ALLOCATION INDEX READY & FOREVER ADVANTAGES
-- ============================================================================
function ForeverIndex:HydrateIntoMasterDB()
    -- Zero-RAM Stealth Architecture: FVD binary-search strings & ETBSources are queried
    -- directly in <0.005ms without allocating 15,534 tables or bloating SavedVariables!
    ensureIndexLoaded()
end

-- MODULE A: Live Rare & Vignette Radar (1.60.1 C_VignetteInfo Event Listener)
local seenVignetteGUIDs = {}
local function ScanActiveVignettes()
    if not C_VignetteInfo or not C_VignetteInfo.GetVignettes or not C_VignetteInfo.GetVignetteInfo then return end
    local ok, guids = pcall(C_VignetteInfo.GetVignettes)
    if not ok or type(guids) ~= "table" then return end

    local curMap = (C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")) or 0
    for i = 1, #guids do
        local guid = guids[i]
        if guid and not seenVignetteGUIDs[guid] then
            seenVignetteGUIDs[guid] = GetTime()
            local okI, vInfo = pcall(C_VignetteInfo.GetVignetteInfo, guid)
            if okI and vInfo and vInfo.name and vInfo.name ~= "" then
                local vx, vy = 50.0, 50.0
                if curMap > 0 and C_VignetteInfo.GetVignettePosition then
                    local okP, pos = pcall(C_VignetteInfo.GetVignettePosition, guid, curMap)
                    if okP and pos and pos.x and pos.y then
                        vx = pos.x * 100
                        vy = pos.y * 100
                    end
                end
                local safeTitle = string.gsub(vInfo.name, "[:|]", "")
                local pinLink = format("|cff00ff96|Hgarrmission:altvault:vig:%d:%.1f:%.1f:%s|h[📍 Lock 3D GPS Pin (%.1f, %.1f)]|h|r",
                    curMap, vx, vy, safeTitle, vx, vy)
                print(format("|cffff8000[AltVault Rare Radar]:|r Detected |cffffff00%s|r nearby! %s", vInfo.name, pinLink))
                if PlaySound then pcall(PlaySound, 8959) end
            end
        end
    end
end

-- MODULE B: Quest Turn-In Max-Gold & BiS Evaluator (QUEST_COMPLETE)
local function EvaluateQuestCompleteRewards()
    if not GetNumQuestChoices then return end
    local numChoices = GetNumQuestChoices() or 0
    if numChoices <= 1 then return end

    local bestVendorIdx, bestVendorVal, bestVendorLink = nil, 0, nil
    local bisChoices = {}
    local _, myClass = UnitClass("player")

    for i = 1, numChoices do
        local link = GetQuestItemLink and GetQuestItemLink("choice", i)
        local _, _, qty = GetQuestItemInfo and GetQuestItemInfo("choice", i)
        qty = tonumber(qty) or 1
        local itemID = link and tonumber(string.match(link, "item:(%d+)"))
        if itemID then
            local sellPrice = 0
            if GetItemInfo then
                local _, _, _, _, _, _, _, _, _, _, sp = GetItemInfo(link or itemID)
                sellPrice = (tonumber(sp) or 0) * qty
            end
            if sellPrice > bestVendorVal then
                bestVendorVal = sellPrice
                bestVendorIdx = i
                bestVendorLink = link
            end
            local isBiS, bisList = ForeverIndex:IsOfficialForeverBiS(itemID, myClass)
            if isBiS and bisList and bisList[1] then
                table.insert(bisChoices, format("%s (#%d %s BiS!)", link, bisList[1].rank, bisList[1].specName))
            end
        end
    end

    if #bisChoices > 0 then
        print("|cffff8000[AltVault Quest Advisor]:|r 🏆 Official Forever BiS Reward: " .. table.concat(bisChoices, " | "))
    end
    if bestVendorIdx and bestVendorVal > 0 then
        local g = floor(bestVendorVal / 10000)
        local s = floor((bestVendorVal % 10000) / 100)
        local c = bestVendorVal % 100
        local coinStr = (g > 0 and format("%dg %ds %dc", g, s, c)) or (s > 0 and format("%ds %dc", s, c)) or format("%dc", c)
        print(format("|cff00ff00[AltVault Quest Gold Advisor]:|r Highest vendor payout is Choice #%d: %s (|cffffd100%s|r)",
            bestVendorIdx, bestVendorLink or "Item", coinStr))
    end
end

-- MODULE C & D: Hyper-Leveling Upgrade Finder, Gold Arbitrage & Alt Synergy Command Suite (/avintel)
local CLASS_WEARABLE_SUBCLASSES = {
    WARRIOR     = { [4] = { [1]=true, [2]=true, [3]=true, [4]=true, [6]=true }, [2] = true },
    PALADIN     = { [4] = { [1]=true, [2]=true, [3]=true, [4]=true, [6]=true, [7]=true }, [2] = true },
    HUNTER      = { [4] = { [1]=true, [2]=true, [3]=true }, [2] = true },
    SHAMAN      = { [4] = { [1]=true, [2]=true, [3]=true, [6]=true, [9]=true }, [2] = true },
    ROGUE       = { [4] = { [1]=true, [2]=true }, [2] = true },
    DRUID       = { [4] = { [1]=true, [2]=true, [8]=true }, [2] = true },
    PRIEST      = { [4] = { [1]=true }, [2] = true },
    MAGE        = { [4] = { [1]=true }, [2] = true },
    WARLOCK     = { [4] = { [1]=true }, [2] = true },
}

function ForeverIndex:PrintImmediateUpgradesForPlayer()
    ensureIndexLoaded()
    local pLvl = UnitLevel("player") or 1
    local _, pClass = UnitClass("player")
    pClass = pClass or "WARRIOR"
    local minReq = max(1, pLvl - 5)
    local maxReq = min(60, pLvl + 3)
    local wearable = CLASS_WEARABLE_SUBCLASSES[pClass] or CLASS_WEARABLE_SUBCLASSES.WARRIOR

    local candidates = {}
    for i = 1, count do
        local id = ids[i]
        local info = self:Info(id)
        if info and (info.classID == 2 or info.classID == 4) and info.quality >= 2 then
            local rLvl = info.reqLevel or 0
            if rLvl >= minReq and rLvl <= maxReq then
                local canWear = (info.classID == 2)
                    or (info.invType == 2 or info.invType == 11 or info.invType == 12 or info.invType == 16)
                    or (wearable[4] and wearable[4][info.subclassID])
                if canWear then
                    local src = self:GetItemSourceAndCoords(id)
                    if src and (src.x or src.zone or src.npc) then
                        local isBiS = self:IsOfficialForeverBiS(id, pClass)
                        local score = (info.itemLevel or rLvl) + (info.quality * 6) + (isBiS and 25 or 0) + (src.x and 8 or 0)
                        candidates[#candidates + 1] = {
                            id = id,
                            info = info,
                            src = src,
                            isBiS = isBiS,
                            score = score,
                        }
                    end
                end
            end
        end
    end

    table.sort(candidates, function(a, b) return a.score > b.score end)
    print(format("|cff00ffcc[AltVault Hyper-Leveling Upgrades]|r Top farmable upgrades for |cffffff00Level %d %s|r (Click [📍 GPS] to lock 3D Arrow):", pLvl, pClass))
    local shown = min(#candidates, 10)
    for i = 1, shown do
        local c = candidates[i]
        local qHex = (c.info.quality == 4 and "a335ee") or (c.info.quality == 3 and "0070dd") or "1eff00"
        local bisBadge = c.isBiS and " |cffff8000[🏆 BiS]|r" or ""
        local gpsLink = format("|cff00ff96|Hgarrmission:altvault:gps:%d|h[📍 GPS: %s (%s)]|h|r",
            c.id, c.src.zone or "Map", c.src.npc or c.src.typeLabel or "Target")
        print(format("  %d) |cff%s[%s]|r (Req %d, iLvl %d)%s -> %s",
            i, qHex, c.info.name, c.info.reqLevel or 1, c.info.itemLevel or 1, bisBadge, gpsLink))
    end
end

SLASH_ALTVAULTINTEL1 = "/avintel"
SlashCmdList["ALTVAULTINTEL"] = function(msg)
    local cmd = lower((strtrim and strtrim(msg or "")) or (msg or ""))
    if cmd == "upgrades" or cmd == "up" or cmd == "level" then
        ForeverIndex:PrintImmediateUpgradesForPlayer()
        return
    elseif cmd == "gold" or cmd == "flip" then
        print("|cff00ff00[AltVault Gold & Arbitrage Targets]|r Top Forever Twink Bases & AH Bottlenecks (Click [📍 GPS] to route):")
        local order = { 7005, 2901, 14092, 6238, 3829, 4389, 3864, 10940, 4306, 4338 }
        for idx, id in ipairs(order) do
            local adv = CURATED_GOLD_TARGETS[id]
            local name = ForeverIndex:Name(id) or ("Item #" .. id)
            local gpsLink = format("|cff00ff96|Hgarrmission:altvault:gps:%d|h[📍 GPS Route]|h|r", id)
            if adv then
                print(format("  %d) |cffffd100[%s]|r (#%d) — |cff00ff96%s|r: %s %s", idx, name, id, adv.title, adv.tip, gpsLink))
            end
        end
        return
    elseif cmd == "alt" or cmd == "synergy" then
        print("|cff00ffcc[AltVault Forever Alt Race/Class/Profession Synergy Matrix]|r")
        print("  |cffffd1001. Speed-Leveler & Gold Harvester:|r |cffabd473Night Elf / Troll Hunter|r + |cff00ff96Skinning & Herbalism/Mining|r (+30% Aspect speed, zero downtime, feeds Leather/Ore/Herbs).")
        print("  |cffffd1002. AoE Gold & Cloth Engine:|r |cff40c7ebGnome / Troll Mage|r + |cff00ff96Tailoring & Enchanting|r (Free water/portals, AoE farms Cloth -> Bags + Disenchants BoEs into Strange/Soul/Dream Dust).")
        print("  |cffffd1003. Instant-Queue Dungeon Tank / Cleave:|r |cfff58cbaHuman Warrior / Paladin|r or |cff0070deOrc Warrior / Shaman|r + |cff00ff96Engineering & Mining|r (Weapon Skill racials + Force Reactive Disk / Grenades).")
        print("  |cffffd1004. Level 5 Bank & Disenchant Mule:|r Any Class parked at City AH/Mailbox with |cff00ff96Enchanting (Lvl 5 can DE up to iLvl 20!)|r + |cff00ff96Alchemy|r cooldowns.")
        return
    end

    if UpdateAddOnMemoryUsage then pcall(UpdateAddOnMemoryUsage) end
    local memKB = (GetAddOnMemoryUsage and GetAddOnMemoryUsage(addonName)) or 0
    local pausedStr = (ns.DB and ns.DB.IsScannerPaused and ns.DB.IsScannerPaused()) and "|cff00ff00STEALTH PAUSED (0 Server Queries)|r" or "|cffffaa00ACTIVE (Verified-IDs Only)|r"
    print(format("|cff00ffcc[AltVault Forever Intelligence & Stealth Status]|r Memory: |cffffd100%.1f MB|r | Scanner: %s | Indexed Forever Items: |cff00ff96%d|r",
        memKB / 1024, pausedStr, ForeverIndex:Count()))
    print("  • |cffffff00/avintel upgrades|r — Top farmable gear upgrades for your exact Level & Class with 1-click 3D GPS links")
    print("  • |cffffff00/avintel gold|r     — Top Unbound Twink Enchant Bases, Badlands Quest Flips & AH Bottlenecks")
    print("  • |cffffff00/avintel alt|r      — Best Forever Race/Class/Profession Alt Synergy combinations")
    print("  • |cffffff00Alt+RightClick|r any item link or icon to lock the 3D GPS Waypoint Arrow!")
end

-- ============================================================================
-- BLOCK HEADING: EVENT BOOTSTRAP
-- ============================================================================
local IntelEventFrame = CreateFrame("Frame")
local SafeReg = (ns.Compat and ns.Compat.SafeRegisterEvent) or function(f, e) pcall(f.RegisterEvent, f, e) end
SafeReg(IntelEventFrame, "PLAYER_LOGIN")
SafeReg(IntelEventFrame, "UPDATE_MOUSEOVER_UNIT")
SafeReg(IntelEventFrame, "PLAYER_TARGET_CHANGED")
SafeReg(IntelEventFrame, "START_LOOT_ROLL")
SafeReg(IntelEventFrame, "VIGNETTE_MINIMAP_UPDATED")
SafeReg(IntelEventFrame, "VIGNETTES_UPDATED")
SafeReg(IntelEventFrame, "QUEST_COMPLETE")

IntelEventFrame:SetScript("OnEvent", function(_, event, arg1)
    if event == "PLAYER_LOGIN" then
        HookTooltipsForForeverIntelligence()
        HookFaceVaultChatLinks()
        ensureIndexLoaded()
    elseif event == "UPDATE_MOUSEOVER_UNIT" then
        RecordPlayerEncounter("mouseover")
    elseif event == "PLAYER_TARGET_CHANGED" then
        RecordPlayerEncounter("target")
    elseif event == "VIGNETTE_MINIMAP_UPDATED" or event == "VIGNETTES_UPDATED" then
        ScanActiveVignettes()
    elseif event == "QUEST_COMPLETE" then
        EvaluateQuestCompleteRewards()
    elseif event == "START_LOOT_ROLL" then
        local rollID = arg1
        if rollID and GetLootRollItemLink then
            local link = GetLootRollItemLink(rollID)
            local itemID = link and tonumber(string.match(link, "item:(%d+)"))
            if itemID then
                local _, myClass = UnitClass("player")
                local isBiS, bisList = ForeverIndex:IsOfficialForeverBiS(itemID, myClass)
                if isBiS and bisList and bisList[1] then
                    print(format("|cffff8000[AltVault Loot Advisor]:|r %s is |cff00ff00#%d Official Forever BiS|r for |cffffff00%s|r!",
                        link, bisList[1].rank, bisList[1].specName))
                end
            end
        end
    end
end)
