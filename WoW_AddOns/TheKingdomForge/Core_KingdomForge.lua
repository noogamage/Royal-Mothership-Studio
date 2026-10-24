-- ============================================================================
-- THE KINGDOM FORGE — CORE ENGINE (PHASES 1–7 + PARENT ADDON MECHANICS)
-- Connects:
--   • Phase 1 & 2: 30 Talent/Legacy Trees, 493 Nodes, >5 Pts/Row Over-Stack & Lv 40 Respec
--   • Phase 3: 72 Cross-Vector Dynamic Compensation Rules & Role Stat Weights
--   • Phase 4: 8,354-Item Upgrade Radar, 3,101 Quests & 423 Tier 1 White Eternal Heirlooms
--   • Phase 5: 587 Profession Enhancements (15 Forceful/Mystic Kits, 30 Reagent/Std Bags, 36 Camping Stations)
--   • Phase 6: Auto-Alt Scanner, NextAltPriorityScore Formula, DE Skill Matrix & 70/30 AH Cash Register
--   • Phase 7: True Revealed World Map, 71 Flight/Transport Nodes & 880 Gathering/Rare/Chest Hotspots
-- ============================================================================
local ADDON_NAME, KF = ...
_G.TheKingdomForge = KF

KF.Version = "1.60.1-RoyalForge"
KF.MediaPath = "Interface\\AddOns\\TheKingdomForge\\Media\\"

-- PaperDoll 17 Equipment Slots (Matching ForeverLevelingGuide wowF_VistaEquipo & GearQuestForever)
KF.LEFT_SLOTS   = { 1, 2, 3, 15, 5, 9, 10 }
KF.RIGHT_SLOTS  = { 6, 7, 8, 11, 12, 13, 14 }
KF.WEAPON_SLOTS = { 16, 17, 18 }
KF.ALL_SLOTS    = { 1, 2, 3, 15, 5, 9, 10, 6, 7, 8, 11, 12, 13, 14, 16, 17, 18 }

KF.SLOT_INFO = {
    [1]  = { name = "Head",       inv = "HeadSlot",          emptyTex = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Head",       kitSlot = false },
    [2]  = { name = "Neck",       inv = "NeckSlot",          emptyTex = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Neck",       kitSlot = false },
    [3]  = { name = "Shoulder",   inv = "ShoulderSlot",      emptyTex = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Shoulder",   kitSlot = false },
    [15] = { name = "Back",       inv = "BackSlot",          emptyTex = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Chest",      kitSlot = false },
    [5]  = { name = "Chest",      inv = "ChestSlot",         emptyTex = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Chest",      kitSlot = true  },
    [9]  = { name = "Wrist",      inv = "WristSlot",         emptyTex = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Wrists",     kitSlot = false },
    [10] = { name = "Hands",      inv = "HandsSlot",         emptyTex = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Hands",      kitSlot = true  },
    [6]  = { name = "Waist",      inv = "WaistSlot",         emptyTex = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Waist",      kitSlot = false },
    [7]  = { name = "Legs",       inv = "LegsSlot",          emptyTex = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Legs",       kitSlot = true  },
    [8]  = { name = "Feet",       inv = "FeetSlot",          emptyTex = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Feet",       kitSlot = true  },
    [11] = { name = "Finger 1",   inv = "Finger0Slot",       emptyTex = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Finger",     kitSlot = false },
    [12] = { name = "Finger 2",   inv = "Finger1Slot",       emptyTex = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Finger",     kitSlot = false },
    [13] = { name = "Trinket 1",  inv = "Trinket0Slot",      emptyTex = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Trinket",    kitSlot = false },
    [14] = { name = "Trinket 2",  inv = "Trinket1Slot",      emptyTex = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Trinket",    kitSlot = false },
    [16] = { name = "Main Hand",  inv = "MainHandSlot",      emptyTex = "Interface\\PaperDoll\\UI-PaperDoll-Slot-MainHand",   kitSlot = false },
    [17] = { name = "Off Hand",   inv = "SecondaryHandSlot", emptyTex = "Interface\\PaperDoll\\UI-PaperDoll-Slot-SecondaryHand", kitSlot = false },
    [18] = { name = "Ranged/Relic", inv = "RangedSlot",      emptyTex = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Ranged",     kitSlot = false },
}

KF.CLASS_HEX = {
    WARRIOR = "c79c6e", PALADIN = "f58cba", HUNTER  = "abd473",
    ROGUE   = "fff569", PRIEST  = "ffffff", SHAMAN  = "0070de",
    MAGE    = "40c7eb", WARLOCK = "8787ed", DRUID   = "ff7d0a",
}

KF.QUALITY_HEX = {
    [0] = "9d9d9d", [1] = "ffffff", [2] = "1eff00",
    [3] = "0070dd", [4] = "a335ee", [5] = "ff8000",
}

local DEFAULT_DB = {
    minimapAngle = 225,
    activeTab = 1,
    adventurePath = "KINGDOM_EMPIRE", -- "KINGDOM_EMPIRE" | "SOLO_SOVEREIGN" | "PVP_CRUCIBLE"
    selectedClass = nil,
    selectedLevel = nil,
    selectedSpecIdx = 1,
    selectedSlot = 16,
    selectedZone = nil,
    fogRevealEnabled = true,
    mapFilterFlight = true,
    mapFilterQuests = true,
    mapFilterHerbs = true,
    mapFilterMining = true,
    mapFilterSkinning = true,
    mapFilterChests = true,
    simTalents = {},     -- [class][treeIdx][nodeId] = rank
    useLiveTalents = true, -- Sync player's actual trained talents when viewing own class
    characters = {},     -- Auto-detected logged characters via SavedVariables
    plannedRoster = {},  -- Pre-registered or custom named guild alts
    pinnedRouteTarget = nil,
}

function KF:EnsureDB()
    if type(TheKingdomForgeDB) ~= "table" then
        TheKingdomForgeDB = {}
    end
    for k, v in pairs(DEFAULT_DB) do
        if TheKingdomForgeDB[k] == nil then
            if type(v) == "table" then
                TheKingdomForgeDB[k] = {}
            else
                TheKingdomForgeDB[k] = v
            end
        end
    end
    return TheKingdomForgeDB
end

-- ============================================================================
-- 1. SAFE PLAYER, ZONE & COORDINATE HELPERS
-- ============================================================================
function KF:GetPlayerContext()
    local name = UnitName("player") or "Sovereign"
    local raceName = UnitRace("player") or "Human"
    local className, classToken = UnitClass("player")
    classToken = classToken or "WARRIOR"
    local level = UnitLevel("player") or 1
    local faction = UnitFactionGroup and UnitFactionGroup("player") or "Alliance"
    local zone = (GetRealZoneText and GetRealZoneText()) or (GetZoneText and GetZoneText()) or "Elwynn Forest"
    local mapID = 1429
    local px, py = 50.0, 50.0
    if C_Map and C_Map.GetBestMapForUnit then
        mapID = C_Map.GetBestMapForUnit("player") or 1429
        if mapID and C_Map.GetPlayerMapPosition then
            local ok, pos = pcall(C_Map.GetPlayerMapPosition, mapID, "player")
            if ok and pos and pos.GetXY then
                local rx, ry = pos:GetXY()
                if rx and ry and rx > 0 and ry > 0 then
                    px, py = math.floor(rx * 1000 + 0.5) / 10, math.floor(ry * 1000 + 0.5) / 10
                end
            end
        end
    end
    return name, classToken, className or classToken, raceName, level, faction, zone, mapID, px, py
end

function KF:FormatCoin(copper)
    copper = tonumber(copper) or 0
    local g = math.floor(copper / 10000)
    local s = math.floor((copper % 10000) / 100)
    local c = copper % 100
    if g > 0 then
        return string.format("|cffffd100%dg|r |cffc7c7cf%ds|r |cffeda55f%dc|r", g, s, c)
    elseif s > 0 then
        return string.format("|cffc7c7cf%ds|r |cffeda55f%dc|r", s, c)
    else
        return string.format("|cffeda55f%dc|r", c)
    end
end

-- ============================================================================
-- 2. ACCOUNT-WIDE AUTO-ALT SCANNER (Phase 6 SavedVariables Engine)
-- ============================================================================
function KF:ScanCurrentCharacter()
    local db = self:EnsureDB()
    local name, cls, clsLocal, race, level, faction, zone, mapID, px, py = self:GetPlayerContext()
    local xp = UnitXP and UnitXP("player") or 0
    local maxXP = UnitXPMax and UnitXPMax("player") or 1000
    local rested = GetXPExhaustion and GetXPExhaustion() or 0
    local restedPct = (maxXP > 0) and math.min(150, math.floor((rested / maxXP) * 100 + 0.5)) or 0
    local money = GetMoney and GetMoney() or 0

    -- Scan learned professions (Classic GetNumSkillLines / GetSkillLineInfo)
    local profs = {}
    if GetNumSkillLines and GetSkillLineInfo then
        local numSkills = GetNumSkillLines() or 0
        for i = 1, numSkills do
            local sName, isHeader, _, sRank, _, _, sMax = GetSkillLineInfo(i)
            if sName and not isHeader and sMax and sMax >= 75 and sMax <= 350 then
                if sName == "Alchemy" or sName == "Enchanting" or sName == "Tailoring"
                   or sName == "Leatherworking" or sName == "Blacksmithing" or sName == "Engineering"
                   or sName == "Herbalism" or sName == "Mining" or sName == "Skinning"
                   or sName == "Cooking" or sName == "First Aid" or sName == "Fishing" then
                    table.insert(profs, { name = sName, skill = sRank or 1, max = sMax or 75 })
                end
            end
        end
    end

    -- Scan bag free slots &total slots
    local freeSlots, totalSlots = 0, 0
    local CC = rawget(_G, "C_Container")
    for bag = 0, 4 do
        local numF = (CC and CC.GetContainerNumSlots) or GetContainerNumSlots
        local freeF = (CC and CC.GetContainerNumFreeSlots) or GetContainerNumFreeSlots
        if numF then
            local okN, n = pcall(numF, bag)
            if okN and tonumber(n) then totalSlots = totalSlots + tonumber(n) end
        end
        if freeF then
            local okF, f = pcall(freeF, bag)
            if okF and tonumber(f) then freeSlots = freeSlots + tonumber(f) end
        end
    end

    local isBanker = false
    for _, p in ipairs(profs) do
        if p.name == "Enchanting" or p.name == "Alchemy" then
            if level <= 35 then isBanker = true end
        end
    end

    db.characters[name] = {
        name = name,
        class = cls,
        classLocal = clsLocal,
        race = race,
        level = level,
        faction = faction,
        zone = zone,
        mapID = mapID,
        x = px,
        y = py,
        xp = xp,
        maxXP = maxXP,
        restedPct = restedPct,
        money = money,
        profs = profs,
        freeSlots = freeSlots,
        totalSlots = totalSlots,
        isBanker = isBanker,
        lastSeen = time and time() or 0,
    }
    return db.characters[name]
end

-- Register a Planned Alt by name & Royal Slot (1..10) so unlogged alts also appear!
function KF:RegisterPlannedAlt(customName, rosterSlot)
    local db = self:EnsureDB()
    local V = TheKingdomForgeVault
    local slotInfo = V and V.RoyalGuildRoster and V.RoyalGuildRoster[rosterSlot or 1]
    if not customName or customName == "" then
        customName = slotInfo and ("RoyalSlot" .. tostring(rosterSlot)) or "NewAlt"
    end
    db.plannedRoster[customName] = {
        name = customName,
        rosterSlot = rosterSlot or 1,
        roleCode = slotInfo and slotInfo.code or "ROYAL ALT",
        class = slotInfo and slotInfo.cls:match("^(%S+)"):upper() or "HUNTER",
        level = 1,
        restedPct = 0,
        profsText = slotInfo and (slotInfo.p1 .. " + " .. slotInfo.p2) or "Skinning + LW",
        isPlanned = true,
    }
end

-- ============================================================================
-- 3. PHASE 6 MATHEMATICAL FORMULA: NextAltPriorityScore(c) & Banker Gate Alert
-- ============================================================================
function KF:EvaluateEmpireProgression()
    local db = self:EnsureDB()
    self:ScanCurrentCharacter()
    local V = TheKingdomForgeVault or {}

    local allChars = {}
    local totalLvl, countChars = 0, 0
    local bankerChar = nil
    local maxRosterLvl = 1

    for _, c in pairs(db.characters) do
        table.insert(allChars, c)
        totalLvl = totalLvl + (c.level or 1)
        countChars = countChars + 1
        if (c.level or 1) > maxRosterLvl then maxRosterLvl = c.level end
        if c.isBanker or (c.name and c.name:lower():find("bank")) then
            bankerChar = c
        end
    end
    for k, pc in pairs(db.plannedRoster) do
        if not db.characters[k] then
            table.insert(allChars, pc)
            totalLvl = totalLvl + (pc.level or 1)
            countChars = countChars + 1
        end
    end

    local avgLvl = countChars > 0 and (totalLvl / countChars) or 1.0

    -- Determine Banker Cap Urgency
    local bankerAlert = "|cff22c55e[BANKER STATUS: SYNCHRONIZED]|r Ready to Disenchant & Brew for current bracket."
    local reqBankerLvl = 5
    local reqDESkill = 1
    if maxRosterLvl >= 32 then reqBankerLvl = 35; reqDESkill = 175
    elseif maxRosterLvl >= 18 then reqBankerLvl = 20; reqDESkill = 125
    elseif maxRosterLvl >= 8 then reqBankerLvl = 10; reqDESkill = 50
    end

    local bankerUrgency = 0
    if not bankerChar then
        bankerUrgency = (maxRosterLvl >= 6) and 1.0 or 0.4
        bankerAlert = "|cffffaa00[BANKER ALERT]|r Once your Skinner Pioneer hits Lv 6-7 with ~15s & LW Greens, log into your Banker Mage and level 1 -> 5!"
    elseif (bankerChar.level or 1) < reqBankerLvl then
        bankerUrgency = 1.0
        bankerAlert = string.format(
            "|cffff4444[BANKER CAP GATE URGENT!]|r Roster is Lv %d — push Banker [%s] from Lv %d -> Lv %d to unlock %d Profession Cap & DE Skill %d!",
            maxRosterLvl, bankerChar.name, bankerChar.level or 1, reqBankerLvl,
            (reqBankerLvl == 35 and 300 or (reqBankerLvl == 20 and 225 or 150)), reqDESkill
        )
    end

    -- Score every character using the Phase 6 Formula:
    -- Score(c) = 100*BootstrapGate + 80*BankerCapUrgency + 35*(Rested/150) + 8*max(0, AvgLvl - Lvl) + 25*SupplyWeight
    local bestChar = nil
    local bestScore = -999
    local scoredList = {}

    for _, c in ipairs(allChars) do
        local lvl = c.level or 1
        local rested = c.restedPct or 0
        local bootWeight = 0
        local targetLvl = math.min(60, lvl + 3)
        local reason = "Standard Lockstep Band Progression"

        local cls = (c.class or "HUNTER"):upper()
        if maxRosterLvl < 6 and (cls == "HUNTER" or cls == "DRUID") and lvl < 7 then
            bootWeight = 1.0
            targetLvl = 7
            reason = "IGNITION STEP 1: Level Pioneer Skinner 1 -> 7 first to seed 15s coin + Light Leather + LW Greens!"
        elseif maxRosterLvl >= 6 and (c.isBanker or cls == "MAGE") and lvl < reqBankerLvl then
            bootWeight = 0.95
            targetLvl = reqBankerLvl
            reason = string.format("IGNITION STEP 2: Level Banker Liaison to Lv %d to unlock Enchanting DE & Alchemy!", reqBankerLvl)
        elseif lvl < 6 then
            bootWeight = 0.75
            targetLvl = 6
            reason = "IGNITION STEP 3-6: Bring alt to Lv 6 & park at Capital City Inn to unlockLv 5 Professions & 150% Rested XP!"
        elseif rested >= 100 then
            targetLvl = math.min(60, lvl + 2)
            reason = string.format("HIGH RESTED XP (%d%%): Burn double-XP rested pool in current zone!", rested)
        end

        local bUrg = (c == bankerChar and bankerUrgency > 0) and bankerUrgency or 0
        local restedTerm = (rested / 150.0) * 35.0
        local lagTerm = math.max(0, avgLvl - lvl) * 8.0
        local supplyTerm = (cls == "HUNTER" or cls == "DRUID" or cls == "PALADIN") and 15.0 or 8.0

        local totalScore = math.floor((100.0 * bootWeight + 80.0 * bUrg + restedTerm + lagTerm + supplyTerm) * 10) / 10
        local entry = {
            char = c,
            score = totalScore,
            fromLvl = lvl,
            toLvl = targetLvl,
            estMins = math.max(15, (targetLvl - lvl) * 12),
            reason = reason,
        }
        table.insert(scoredList, entry)
        if totalScore > bestScore then
            bestScore = totalScore
            bestChar = entry
        end
    end

    table.sort(scoredList, function(a, b) return a.score > b.score end)
    return bestChar, scoredList, bankerAlert, avgLvl
end

-- ============================================================================
-- 4. PHASE 3 & 4 LIVE EQUIPPED GEAR & SLOT UPGRADE EVALUATOR
-- ============================================================================
function KF:ScanEquipmentAndUpgrades(targetClass, targetLevel)
    local _, pClass, _, _, pLvl = self:GetPlayerContext()
    local cls = targetClass or pClass or "WARRIOR"
    local lvl = tonumber(targetLevel) or pLvl or 1
    local V = TheKingdomForgeVault or {}
    local slotUpgrades = V.SlotUpgrades or {}

    local results = {}
    local upgradeCount = 0

    for _, slotID in ipairs(self.ALL_SLOTS) do
        local sInfo = self.SLOT_INFO[slotID]
        local link = GetInventoryItemLink and GetInventoryItemLink("player", slotID) or nil
        local tex = GetInventoryItemTexture and GetInventoryItemTexture("player", slotID) or nil
        local eqName, eqIlvl, eqQuality = "Empty Slot", 0, 0
        if link then
            eqName = link:match("%[(.-)%]") or "Equipped Item"
            local getInfo = (C_Item and C_Item.GetItemInfo) or GetItemInfo
            if getInfo then
                local _, _, q, ilvl = getInfo(link)
                eqQuality = q or 1
                eqIlvl = ilvl or math.max(1, lvl * 2)
            else
                eqQuality = 2
                eqIlvl = math.max(1, lvl * 2)
            end
        end

        -- Find available upgrades in V.SlotUpgrades[slotID] within [1 .. lvl + 4]
        local candidates = {}
        local bestUpgrade = nil
        local hasHeirloom = nil

        for _, cand in ipairs(slotUpgrades[slotID] or {}) do
            if cand.req <= (lvl + 4) and cand.req >= math.max(1, lvl - 12) then
                table.insert(candidates, cand)
                if cand.hlTier == "TIER_1_ETERNAL_WHITE_HEIRLOOM" and not hasHeirloom then
                    hasHeirloom = cand
                end
                if not bestUpgrade or (cand.ilvl > bestUpgrade.ilvl and cand.req <= lvl + 2) then
                    bestUpgrade = cand
                end
            end
        end

        local status = "OK" -- "UPGRADE" (Green Glow), "HEIRLOOM" (Gold Glow), "OK"
        if not link or (bestUpgrade and bestUpgrade.ilvl > eqIlvl + 2) then
            status = "UPGRADE"
            upgradeCount = upgradeCount + 1
        elseif hasHeirloom then
            status = "HEIRLOOM"
        end

        results[slotID] = {
            slotID = slotID,
            slotName = sInfo.name,
            kitAllowed = sInfo.kitSlot,
            link = link,
            tex = tex or sInfo.emptyTex,
            isEmpty = (link == nil),
            eqName = eqName,
            eqIlvl = eqIlvl,
            eqQuality = eqQuality,
            status = status,
            bestUpgrade = bestUpgrade,
            heirloom = hasHeirloom,
            candidates = candidates,
        }
    end

    return results, upgradeCount
end

-- ============================================================================
-- 5. PHASE 5 & 6 LIVE BAG 70% GUILD / 30% AH LIQUIDITY SCANNER
-- ============================================================================
local COMMODITY_RULES = {
    ["Leather"] = { g70 = "Mail 70% to Slot 3 Hunter (Leatherworking) for Forceful/Mystic Armor Kits", ah30 = "Convert 30% into Forceful/Mystic Armor Kits or Light Leather Reagent Bags for AH (+380% margin)!" },
    ["Hide"]    = { g70 = "Mail 70% to Slot 3 Hunter (Cured Hides for Quickdraw Quivers & Reagent Bags)", ah30 = "Sell 30% as Cured Hides or Quickdraw Quivers on AH!" },
    ["Cloth"]   = { g70 = "Mail 70% to Slot 2 Mage (Tailoring) for Standard Bags & Custom Reagent Bags", ah30 = "Sew 30% into WoW Forever Custom Reagent Bags (Linen/Wool/Silk/Mageweave) & post as singles!" },
    ["Ore"]     = { g70 = "Mail 70% to Slot 5 Paladin (BS) & Slot 6 Rogue (Eng) for Rods, Stones & Bots", ah30 = "Forge 30% into Inert Enchanting Rods (Copper/Silver/Golden/Truesilver) for 420% AH markup!" },
    ["Bar"]     = { g70 = "Mail 70% to Blacksmith/Engineer for Rods, Buckles, Scopes & Repair Bots", ah30 = "Convert 30% into Inert Enchanting Rods & Bronze Tubes on AH!" },
    ["Stone"]   = { g70 = "Mail 70% to Blacksmith for Sharpening/Weightstones & Grinding Stones", ah30 = "Sell 30% as Sharpening Stones or Solid/Dense Stone stacks!" },
    ["Dust"]    = { g70 = "Keep 70% on Banker Enchanter + mail pairs of 2x to Hunter LW for Forceful/Mystic Kits!", ah30 = "Sell 30% in stacks of 2x or 5x on AH (or craft Lesser/Greater Magic Wands)!" },
    ["Essence"] = { g70 = "Keep 70% on Banker Enchanter for Wands & Heirloom Enchants", ah30 = "Craft Wands or sell Greater Essences on AH!" },
    ["Peacebloom"] = { g70 = "Mail 70% to Slot 1 Banker Alchemist (Minor Healing Potions & Incense Candles)", ah30 = "Sell 30% as Minor Healing Potions on AH!" },
    ["Silverleaf"] = { g70 = "Mail 70% to Slot 1 Banker Alchemist (Elixir of Minor Strength for Forceful Kits!)", ah30 = "Brew 30% into pairs of 2x Elixir of Minor Strength for LW buyers on AH!" },
    ["Mageroyal"]  = { g70 = "Mail 70% to Slot 1 Banker Alchemist (Minor Mana Potions for Mystic Kits!)", ah30 = "Brew 30% into pairs of 2x Minor Mana Potion for LW buyers on AH!" },
    ["Briarthorn"] = { g70 = "Mail 70% to Banker Alchemist (Elixir of Wisdom & Swiftness Potions)", ah30 = "Sell 30% as Swiftness Potions on AH!" },
    ["Bruiseweed"] = { g70 = "Mail 70% to Banker Alchemist", ah30 = "Sell 30% as Healing Potions!" },
    ["Kingsblood"] = { g70 = "Mail 70% to Banker Alchemist", ah30 = "Sell 30% on AH!" },
}

function KF:ScanBagsFor7030Split()
    local itemsFound = {}
    local CC = rawget(_G, "C_Container")
    local getInfo = (C_Item and C_Item.GetItemInfo) or GetItemInfo

    for bag = 0, 4 do
        local numF = (CC and CC.GetContainerNumSlots) or GetContainerNumSlots
        local okN, numSlots = pcall(numF or function() return 0 end, bag)
        numSlots = (okN and tonumber(numSlots)) or 0
        for slot = 1, numSlots do
            local itemID, count, link = nil, 1, nil
            if CC and CC.GetContainerItemInfo then
                local okI, info = pcall(CC.GetContainerItemInfo, bag, slot)
                if okI and type(info) == "table" then
                    itemID = info.itemID
                    count = info.stackCount or 1
                    link = info.hyperlink
                end
            elseif GetContainerItemInfo then
                local _, c, _, _, _, _, l = GetContainerItemInfo(bag, slot)
                count = c or 1
                link = l
                itemID = GetContainerItemID and GetContainerItemID(bag, slot)
            end
            if link or itemID then
                local name = link and link:match("%[(.-)%]")
                local quality = 1
                if getInfo then
                    local n, _, q = getInfo(link or itemID)
                    name = name or n
                    quality = q or 1
                end
                if name then
                    itemsFound[name] = itemsFound[name] or { name = name, count = 0, quality = quality, link = link }
                    itemsFound[name].count = itemsFound[name].count + count
                end
            end
        end
    end

    local splitRows = {}
    for name, data in pairs(itemsFound) do
        local matchedRule = nil
        for kw, rule in pairs(COMMODITY_RULES) do
            if name:find(kw) then
                matchedRule = rule
                break
            end
        end
        if not matchedRule and data.quality == 2 then
            matchedRule = {
                g70 = "Mail BoE Green to Slot 1 Banker Enchanter to Disenchant into Dust/Essence!",
                ah30 = "If top-rolled 'of the Monkey/Tiger/Bear/Eagle', list on AH for 3x DE value!"
            }
        end
        if matchedRule then
            local keep70 = math.max(1, math.floor(data.count * 0.70 + 0.5))
            local sell30 = math.max(0, data.count - keep70)
            table.insert(splitRows, {
                name = name,
                total = data.count,
                keep70 = keep70,
                sell30 = sell30,
                g70Text = matchedRule.g70,
                ah30Text = matchedRule.ah30,
            })
        end
    end

    table.sort(splitRows, function(a, b) return a.total > b.total end)
    return splitRows
end

-- ============================================================================
-- 6. PHASE 4 & 7 WORLD MAP FOG-OF-WAR REVEALER & ALONG-THE-WAY QUEST ROUTER
-- Harvested from Mapster (FogClear.lua + FogClearData) & Leatrix_Maps
-- ============================================================================
local worldMapHooked = false
local battlefieldMapHooked = false

function KF:ParseFogRectKey(key)
    if type(key) == "string" then
        local w, h, ox, oy = strsplit(":", key)
        return tonumber(w) or 0, tonumber(h) or 0, tonumber(ox) or 0, tonumber(oy) or 0
    elseif type(key) == "number" then
        local w = math.fmod(math.floor(key / 2^39), 2^13)
        local h = math.fmod(math.floor(key / 2^26), 2^13)
        local ox = math.fmod(math.floor(key / 2^13), 2^13)
        local oy = math.fmod(key, 2^13)
        return w, h, ox, oy
    end
    return 0, 0, 0, 0
end

local function RevealPinOverlays(pin, fullUpdate)
    local db = KF:EnsureDB()
    if not db.fogRevealEnabled then return end
    local V = TheKingdomForgeVault or {}
    local FogData = V.FogClearData or {}

    if pin.overlayTexturePool then
        for overlay in pin.overlayTexturePool:EnumerateActive() do
            overlay:SetVertexColor(1, 1, 1)
            overlay:SetAlpha(1)
        end
    end

    local mapCanvas = pin.GetMap and pin:GetMap()
    local mapID = (mapCanvas and mapCanvas.GetMapID and mapCanvas:GetMapID())
        or (WorldMapFrame and WorldMapFrame.mapID)
        or (WorldMapFrame and WorldMapFrame.GetMapID and WorldMapFrame:GetMapID())
    if not mapID or not C_Map or not C_Map.GetMapArtID then return end
    local artID = C_Map.GetMapArtID(mapID)
    if not artID or not FogData[artID] then return end
    local data = FogData[artID]

    local exploredTilesKeyed = {}
    local exploredMapTextures = C_MapExplorationInfo and C_MapExplorationInfo.GetExploredMapTextures and C_MapExplorationInfo.GetExploredMapTextures(mapID)
    if exploredMapTextures then
        for _, info in ipairs(exploredMapTextures) do
            local kInt = info.textureWidth * 2^39 + info.textureHeight * 2^26 + info.offsetX * 2^13 + info.offsetY
            local kStr = string.format("%d:%d:%d:%d", info.textureWidth, info.textureHeight, info.offsetX, info.offsetY)
            exploredTilesKeyed[kInt] = true
            exploredTilesKeyed[kStr] = true
        end
    end

    local layerIdx = (mapCanvas and mapCanvas.GetCanvasContainer and mapCanvas:GetCanvasContainer():GetCurrentLayerIndex()) or 1
    local layers = C_Map.GetMapArtLayers and C_Map.GetMapArtLayers(mapID)
    local layerInfo = (layers and layers[layerIdx]) or (layers and layers[1]) or { tileWidth = 256, tileHeight = 256 }
    local TILE_W = layerInfo.tileWidth or 256
    local TILE_H = layerInfo.tileHeight or 256

    local drawLayer, subLevel = "ARTWORK", 0
    if pin.dataProvider and pin.dataProvider.GetDrawLayer then
        drawLayer, subLevel = pin.dataProvider:GetDrawLayer()
    end

    for key, files in pairs(data) do
        if not exploredTilesKeyed[key] then
            local width, height, offsetX, offsetY = KF:ParseFogRectKey(key)
            if width > 0 and height > 0 then
                local fileDataIDs = { strsplit(",", files) }
                local numWide = math.ceil(width / TILE_W)
                local numTall = math.ceil(height / TILE_H)
                for j = 1, numTall do
                    local pH = (j < numTall) and TILE_H or math.fmod(height, TILE_H)
                    if pH == 0 then pH = TILE_H end
                    local fH = 16
                    while fH < pH do fH = fH * 2 end
                    for k = 1, numWide do
                        local pW = (k < numWide) and TILE_W or math.fmod(width, TILE_W)
                        if pW == 0 then pW = TILE_W end
                        local fW = 16
                        while fW < pW do fW = fW * 2 end
                        local fdid = tonumber(fileDataIDs[(j - 1) * numWide + k])
                        if fdid and pin.overlayTexturePool then
                            local tex = pin.overlayTexturePool:Acquire()
                            if mapCanvas and mapCanvas.AddMaskableTexture then mapCanvas:AddMaskableTexture(tex) end
                            tex:SetWidth(pW)
                            tex:SetHeight(pH)
                            tex:SetTexCoord(0, pW / fW, 0, pH / fH)
                            tex:SetPoint("TOPLEFT", offsetX + (TILE_W * (k - 1)), -(offsetY + (TILE_H * (j - 1))))
                            tex:SetTexture(fdid, nil, nil, "TRILINEAR")
                            tex:SetVertexColor(1, 1, 1)
                            tex:SetAlpha(1)
                            tex:SetDrawLayer(drawLayer, (subLevel or 0) - 1)
                            tex:Show()
                            if fullUpdate and pin.textureLoadGroup and pin.textureLoadGroup.AddTexture then
                                pin.textureLoadGroup:AddTexture(tex)
                            end
                        end
                    end
                end
            end
        end
    end
end

function KF:ApplyWorldMapFogReveal()
    local db = self:EnsureDB()
    if WorldMapFrame and WorldMapFrame.EnumeratePinsByTemplate then
        if not worldMapHooked then
            worldMapHooked = true
            for pin in WorldMapFrame:EnumeratePinsByTemplate("MapExplorationPinTemplate") do
                if hooksecurefunc then
                    hooksecurefunc(pin, "RefreshOverlays", RevealPinOverlays)
                end
            end
        end
        for pin in WorldMapFrame:EnumeratePinsByTemplate("MapExplorationPinTemplate") do
            if pin.RefreshOverlays then
                pcall(pin.RefreshOverlays, pin, true)
            end
        end
    end

    if BattlefieldMapFrame and BattlefieldMapFrame.EnumeratePinsByTemplate then
        if not battlefieldMapHooked then
            battlefieldMapHooked = true
            for pin in BattlefieldMapFrame:EnumeratePinsByTemplate("MapExplorationPinTemplate") do
                if hooksecurefunc then
                    hooksecurefunc(pin, "RefreshOverlays", RevealPinOverlays)
                end
            end
        end
        for pin in BattlefieldMapFrame:EnumeratePinsByTemplate("MapExplorationPinTemplate") do
            if pin.RefreshOverlays then
                pcall(pin.RefreshOverlays, pin, true)
            end
        end
    end
end

-- Nearest-Neighbor Travelling Salesman Route across Zone Quests + Flight Point + Gathering Hotspots + Leatrix POIs
function KF:BuildZoneInteractiveAtlas(zoneName)
    local pName, _, _, _, pLvl, pFac, curZone, pMapID, px, py = self:GetPlayerContext()
    local z = zoneName or curZone or "Elwynn Forest"
    local V = TheKingdomForgeVault or {}
    local db = self:EnsureDB()
    local uiMapID = (V.ZoneToUIMapID and V.ZoneToUIMapID[z]) or (z == curZone and pMapID) or 1429

    local pins = {}

    -- 0. Player Live Position Pin if currently inside this zone!
    if z == curZone and px and py and px > 0 and py > 0 then
        table.insert(pins, {
            kind = "PLAYER",
            title = "YOU: " .. (pName or "King"),
            sub = string.format("Current Position in %s (%.1f, %.1f)", z, px, py),
            x = px,
            y = py,
            note = "Your live character position on the Revealed Kingdom Atlas!",
            color = { 0.0, 1.0, 0.85 },
            icon = "Interface\\Icons\\INV_Crown_01",
        })
    end

    -- 1. Flight Masters, Dungeons, Raids, Boats/Zeppelins, Spirit Healers & Zone Crossings (from ShortestPath + Leatrix_Maps + TaxiNodes)
    if db.mapFilterFlight then
        local seenCoords = {}
        for _, fn in ipairs(V.FlightAndTransportNodes or {}) do
            if fn.zone == z then
                local ck = string.format("%d:%d", math.floor(fn.x / 3), math.floor(fn.y / 3))
                seenCoords[ck] = true
                local fAtlas = (fn.faction == "Alliance") and "TaxiNode_Alliance" or ((fn.faction == "Horde") and "TaxiNode_Horde" or "TaxiNode_Neutral")
                table.insert(pins, {
                    kind = "FLIGHT",
                    title = fn.name,
                    sub = fn.kind .. " (" .. fn.faction .. ")",
                    x = fn.x,
                    y = fn.y,
                    note = fn.note,
                    atlas = fAtlas,
                    color = (fn.faction == "Alliance") and {0.25, 0.70, 1.0} or ((fn.faction == "Horde") and {1.0, 0.30, 0.25} or {1.0, 0.85, 0.15}),
                    icon = "Interface\\TaxiFrame\\UI-Taxi-Icon-Yellow",
                })
            end
        end

        -- Add Leatrix_Maps & TaxiNodes POIs (Flight Points, Dungeons, Raids, Boats/Zeppelins, Portals, Spirit Healers, Zone Crossings)
        local lPois = (V.LeatrixPOIs and (V.LeatrixPOIs[z] or V.LeatrixPOIs[uiMapID])) or {}
        for _, lp in ipairs(lPois) do
            local ck = string.format("%d:%d", math.floor(lp.x / 3), math.floor(lp.y / 3))
            if not (lp.kind:find("Flight") and seenCoords[ck]) then
                if lp.kind:find("Flight") then seenCoords[ck] = true end
                local ic = "Interface\\TaxiFrame\\UI-Taxi-Icon-Yellow"
                local atlasName = nil
                local texCoord = nil
                local col = { 1.0, 0.85, 0.15 }
                local subTxt = (lp.sub and lp.sub ~= "") and lp.sub or lp.kind
                local noteTxt = "Revealed Kingdom Atlas Landmark"
                local destZone = (lp.destMap and lp.destMap > 0 and V.UIMapIDToZone and V.UIMapIDToZone[lp.destMap]) or nil

                if lp.kind == "FlightA" then
                    atlasName = "TaxiNode_Alliance"
                    col = { 0.25, 0.70, 1.0 }
                    subTxt = (lp.sub and lp.sub ~= "") and ("Alliance Flight Master — " .. lp.sub) or "Alliance Flight Master"
                    noteTxt = "Alliance Flight Point! Click on Continent Maps to zoom into this zone."
                elseif lp.kind == "FlightH" then
                    atlasName = "TaxiNode_Horde"
                    col = { 1.0, 0.30, 0.25 }
                    subTxt = (lp.sub and lp.sub ~= "") and ("Horde Flight Master — " .. lp.sub) or "Horde Flight Master"
                    noteTxt = "Horde Flight Point! Click on Continent Maps to zoom into this zone."
                elseif lp.kind == "FlightN" or lp.kind == "FLIGHT" then
                    atlasName = "TaxiNode_Neutral"
                    col = { 1.0, 0.85, 0.15 }
                    subTxt = (lp.sub and lp.sub ~= "") and ("Neutral Flight Master — " .. lp.sub) or "Neutral Flight Master"
                    noteTxt = "Neutral Flight Point! Click on Continent Maps to zoom into this zone."
                elseif lp.kind == "Dungeon" then
                    atlasName = "Dungeon"
                    ic = "Interface\\Icons\\INV_Misc_Head_Dragon_01"
                    col = { 0.35, 0.75, 1.0 }
                    subTxt = string.format("Dungeon Entrance (Levels %d - %d)", lp.minL or 15, lp.maxL or 60)
                    noteTxt = "Dungeon Entrance revealed on the Kingdom Atlas!"
                elseif lp.kind == "Raid" or lp.kind == "Dunraid" then
                    atlasName = "Raid"
                    ic = "Interface\\Icons\\INV_Misc_Head_Dragon_01"
                    col = { 0.85, 0.35, 1.0 }
                    subTxt = string.format("Raid Entrance (Levels %d - %d)", lp.minL or 60, lp.maxL or 60)
                    noteTxt = "Raid Entrance revealed on the Kingdom Atlas!"
                elseif lp.kind:find("Travel") then
                    ic = "Interface\\AddOns\\TheKingdomForge\\Media\\Leatrix_Maps.blp"
                    if lp.kind == "TravelA" then
                        texCoord = { 0, 0.25, 0.75, 1.0 }
                        col = { 0.25, 0.85, 1.0 }
                    elseif lp.kind == "TravelH" then
                        texCoord = { 0.25, 0.50, 0.75, 1.0 }
                        col = { 1.0, 0.35, 0.30 }
                    else
                        texCoord = { 0.50, 0.75, 0.75, 1.0 }
                        col = { 1.0, 0.85, 0.20 }
                    end
                    if destZone then noteTxt = "Ship / Zeppelin / Tram Route -> Click to open " .. destZone .. " Map!" end
                elseif lp.kind:find("Portal") then
                    atlasName = (lp.kind == "PortalH") and "MagePortalHorde" or "MagePortalAlliance"
                    ic = "Interface\\Icons\\Spell_Arcane_TeleportStormwind"
                    col = { 0.25, 0.90, 1.0 }
                    if destZone then noteTxt = "Portal -> Click to open " .. destZone .. " Map!" end
                elseif lp.kind == "Arrow" then
                    atlasName = "Garr_LevelUpgradeArrow"
                    ic = "Interface\\Icons\\Ability_Spy"
                    col = { 0.70, 0.95, 0.55 }
                    subTxt = "Zone Crossing Trail" .. (lp.sub ~= "" and (" (" .. lp.sub .. ")") or "")
                    if destZone then noteTxt = "Zone Crossing Trail -> Click to open " .. destZone .. " Map!" end
                elseif lp.kind == "Spirit" then
                    atlasName = "Vehicle-TempleofKotmogu-GreenBall"
                    ic = "Interface\\Icons\\Spell_Holy_GuardianSpirit"
                    col = { 0.65, 0.95, 1.0 }
                    subTxt = "Spirit Healer (Graveyard)"
                end

                table.insert(pins, {
                    kind = lp.kind,
                    title = lp.title,
                    sub = subTxt,
                    x = lp.x,
                    y = lp.y,
                    note = noteTxt,
                    destZone = destZone,
                    color = col,
                    icon = ic,
                    atlas = atlasName,
                    texCoord = texCoord,
                    rot = lp.rot or 0,
                })
            end
        end
    end

    -- 2. Quests in Zone: Prioritize Focused Quest -> Completed (?) Turn-Ins -> Active Log Objectives -> Available (!) Quest Givers!
    local activeLogQuests = self:GetActiveQuestLogEntries()
    local activeByID = {}
    for _, lq in ipairs(activeLogQuests) do
        if lq.id and lq.id > 0 then activeByID[lq.id] = lq end
        if lq.title then activeByID[lq.title:lower()] = lq end
    end

    local focusedQ = db.focusedQuestRoute
    -- Keep focused quest synchronized with live completion state if it is in the Quest Log
    if focusedQ then
        local liveMatch = (focusedQ.id and activeByID[focusedQ.id]) or (focusedQ.name and activeByID[focusedQ.name:lower()])
        if liveMatch then
            focusedQ.zone = liveMatch.zone
            focusedQ.x = liveMatch.x
            focusedQ.y = liveMatch.y
            focusedQ.npc = liveMatch.npc
            focusedQ.isComplete = liveMatch.isComplete
            focusedQ.objSummary = liveMatch.objSummary
            focusedQ.endZone = liveMatch.endZone
            focusedQ.endX = liveMatch.endX
            focusedQ.endY = liveMatch.endY
            focusedQ.endNpc = liveMatch.endNpc
        end
    end

    local rawQuests = (V.ZoneQuestRoutes and V.ZoneQuestRoutes[z]) or {}
    local questCandidates = {}
    local seenQuestIDs = {}
    local secondaryTurnInPins = {}

    -- A) First insert any Focused Quest (clicked in the Right-Side Quest Tracker Dropdown) if in this zone!
    if focusedQ and focusedQ.zone == z and focusedQ.x and focusedQ.y then
        local fKey = focusedQ.id or focusedQ.name
        seenQuestIDs[fKey] = true
        if focusedQ.name then seenQuestIDs[focusedQ.name:lower()] = true end
        table.insert(questCandidates, {
            id = focusedQ.id or 0,
            name = focusedQ.name or "Tracked Quest",
            lvl = focusedQ.lvl or pLvl,
            npc = focusedQ.npc or "Tracked Target",
            x = focusedQ.x,
            y = focusedQ.y,
            endZone = focusedQ.endZone,
            endX = focusedQ.endX,
            endY = focusedQ.endY,
            endNpc = focusedQ.endNpc,
            isFocused = true,
            isActiveLog = true,
            isComplete = focusedQ.isComplete,
            objSummary = focusedQ.objSummary,
        })
    end

    -- B) Next insert all other Active Quests from the player's Live Quest Log in this zone!
    for _, lq in ipairs(activeLogQuests) do
        local key = lq.id or lq.title
        local titleKey = lq.title and lq.title:lower() or ""
        if lq.zone == z and not seenQuestIDs[key] and not seenQuestIDs[titleKey] and lq.x and lq.y then
            seenQuestIDs[key] = true
            if titleKey ~= "" then seenQuestIDs[titleKey] = true end
            table.insert(questCandidates, {
                id = lq.id or 0,
                name = lq.title,
                lvl = lq.level or pLvl,
                npc = lq.npc or "Quest Objective",
                x = lq.x,
                y = lq.y,
                endZone = lq.endZone,
                endX = lq.endX,
                endY = lq.endY,
                endNpc = lq.endNpc,
                isActiveLog = true,
                isComplete = lq.isComplete,
                objSummary = lq.objSummary,
            })
        elseif not lq.isComplete and lq.endZone == z and lq.endX and lq.endY then
            table.insert(secondaryTurnInPins, lq)
        end
    end

    -- C) Fill remaining slots with Available Quest Giver Hubs (!) in this zone (filtered by Prerequisites, Completion & Faction)
    if db.mapFilterQuests then
        local giverHubs = {}
        local giverHubList = {}
        for _, q in ipairs(rawQuests) do
            local qTitleKey = q.name and q.name:lower() or ""
            if q and not seenQuestIDs[q.id] and not seenQuestIDs[qTitleKey] then
                if self:IsQuestAvailableToPlayer(q, pLvl, pFac, activeByID) then
                    seenQuestIDs[q.id] = true
                    if qTitleKey ~= "" then seenQuestIDs[qTitleKey] = true end
                    -- Merge quests offered by the exact same Quest Giver coordinates into one clean Hub stop
                    local hubKey = string.format("%d:%d", math.floor((q.x or 50) * 2 + 0.5), math.floor((q.y or 50) * 2 + 0.5))
                    local hub = giverHubs[hubKey]
                    if not hub then
                        hub = {
                            id = q.id,
                            name = q.name,
                            lvl = q.lvl or 1,
                            minL = q.minL or 1,
                            npc = q.npc or "Quest Giver",
                            x = q.x,
                            y = q.y,
                            isAvailableGiver = true,
                            hubQuests = { string.format("[%d] %s", q.lvl or 1, q.name) },
                        }
                        giverHubs[hubKey] = hub
                        table.insert(giverHubList, hub)
                    else
                        table.insert(hub.hubQuests, string.format("[%d] %s", q.lvl or 1, q.name))
                    end
                end
            end
        end
        for _, hub in ipairs(giverHubList) do
            if #hub.hubQuests > 1 then
                hub.objSummary = string.format("Quest Giver: %s (%d Available Quests)", hub.npc, #hub.hubQuests)
                hub.hubListText = "Available Quests from " .. hub.npc .. ":\n• " .. table.concat(hub.hubQuests, "\n• ")
            else
                hub.objSummary = "Quest Giver: " .. hub.npc
                hub.hubListText = string.format("Available Quest from %s:\n• [%d] %s", hub.npc, hub.lvl or 1, hub.name)
            end
            table.insert(questCandidates, hub)
        end
    end

    -- Nearest-Neighbor sort from (px, py) to build the accurate Quest Route!
    -- Priority order: 1. Focused Quest -> 2. Completed (?) Turn-Ins -> 3. Active Log Objectives -> 4. Available (!) Quest Givers
    local orderedRoute = {}
    local curX, curY = px or 50.0, py or 50.0
    if z == curZone and px and py and px > 0 and py > 0 then
        table.insert(orderedRoute, {
            step = 0,
            id = 0,
            name = "YOUR POSITION",
            lvl = pLvl,
            npc = pName or "You",
            x = px,
            y = py,
        })
    end

    local used = {}
    for step = 1, math.min(12, #questCandidates) do
        local bestIdx, bestDist = nil, 99999999
        for idx, q in ipairs(questCandidates) do
            if not used[idx] then
                if q.isFocused then
                    bestIdx = idx
                    bestDist = -1
                    break
                end
                local dx, dy = (q.x - curX), (q.y - curY)
                local d2 = dx * dx + dy * dy
                if q.isActiveLog and q.isComplete then
                    -- Completed quests ready for '?' Turn-In get top route priority
                    d2 = d2 * 0.05
                elseif q.isActiveLog then
                    -- Active Quest Log objectives get second priority
                    d2 = d2 * 0.20
                else
                    -- Unaccepted Available (!) Quest Givers penalize quests above player level
                    local lvlDiff = math.max(0, (q.lvl or pLvl) - pLvl)
                    d2 = d2 + (lvlDiff * 25)
                end
                if d2 < bestDist then
                    bestDist = d2
                    bestIdx = idx
                end
            end
        end
        if bestIdx then
            used[bestIdx] = true
            local q = questCandidates[bestIdx]
            curX, curY = q.x, q.y
            table.insert(orderedRoute, {
                step = step,
                id = q.id,
                name = q.name,
                lvl = q.lvl,
                npc = q.npc,
                x = q.x,
                y = q.y,
                isFocused = q.isFocused,
                isActiveLog = q.isActiveLog,
                isComplete = q.isComplete,
            })

            local pinKind = "QUEST_AVAILABLE"
            local pinColor = { 1.0, 0.85, 0.15 }
            local pinIcon = "Interface\\GossipFrame\\AvailableQuestIcon"
            local pinAtlas = "QuestNormal"
            local tagPrefix = "! #" .. step
            local subLine = q.objSummary or ("Quest Giver: " .. (q.npc ~= "" and q.npc or "Quest NPC"))
            local noteLine = q.hubListText or string.format("Route Stop #%d • Quest Giver: %s at (%.1f, %.1f)", step, q.npc or "NPC", q.x, q.y)

            if q.isComplete then
                -- Completed Quest: Show Gold Question Mark (?) on the Turn-In NPC!
                pinKind = "QUEST_TURNIN"
                pinColor = q.isFocused and { 0.0, 1.0, 0.90 } or { 0.20, 1.0, 0.40 }
                pinIcon = "Interface\\GossipFrame\\ActiveQuestIcon"
                pinAtlas = "QuestTurnin"
                tagPrefix = "? TURN IN #" .. step
                subLine = "|cff22c55eReady to Turn In!|r  •  Speak with |cffffd100" .. (q.npc ~= "" and q.npc or "Turn-In NPC") .. "|r"
                noteLine = string.format("Completed Quest (?) — Hand in to %s at (%.1f, %.1f)!", q.npc or "Quest Turn-In", q.x, q.y)
            elseif q.isActiveLog then
                -- Incomplete Active Log Quest: Route directly to Objective spawn!
                pinKind = q.isFocused and "FOCUSED_QUEST" or "QUEST_OBJECTIVE"
                pinColor = q.isFocused and { 0.0, 1.0, 0.90 } or { 0.25, 0.90, 1.0 }
                pinIcon = "Interface\\GossipFrame\\AvailableQuestIcon"
                pinAtlas = nil
                tagPrefix = (q.isFocused and "TRACKED #" or "OBJECTIVE #") .. step
                subLine = "Target: |cff00ffcc" .. (q.npc ~= "" and q.npc or "Objective") .. "|r" .. ((q.objSummary and q.objSummary ~= "") and ("\n" .. q.objSummary) or "")
                noteLine = string.format("Active Quest Objective #%d at (%.1f, %.1f)\nTurn-In NPC when finished: %s (%.1f, %.1f)", step, q.x, q.y, q.endNpc or q.npc or "NPC", q.endX or q.x, q.endY or q.y)

                -- Also add a silver/grey '?' pin at the Turn-In NPC if it is at a different spot in this zone
                if q.endZone == z and q.endX and q.endY and (math.abs(q.endX - q.x) > 1.2 or math.abs(q.endY - q.y) > 1.2) then
                    table.insert(secondaryTurnInPins, {
                        title = q.name,
                        level = q.lvl,
                        endNpc = q.endNpc,
                        endX = q.endX,
                        endY = q.endY,
                    })
                end
            end

            table.insert(pins, {
                kind = pinKind,
                step = step,
                isFocused = q.isFocused,
                isActiveLog = q.isActiveLog,
                isComplete = q.isComplete,
                title = string.format("%s: %s (Lv %d)", tagPrefix, q.name, q.lvl or 1),
                sub = subLine,
                x = q.x,
                y = q.y,
                note = noteLine,
                color = pinColor,
                icon = pinIcon,
                atlas = pinAtlas,
            })
        end
    end

    -- Add silver/grey '?' Turn-In reference pins for in-progress quests whose finisher is in this zone
    for _, sq in ipairs(secondaryTurnInPins) do
        local ex, ey = sq.endX, sq.endY
        if ex and ey then
            local overlap = false
            for _, ep in ipairs(pins) do
                if math.abs((ep.x or 0) - ex) < 1.0 and math.abs((ep.y or 0) - ey) < 1.0 then
                    overlap = true
                    break
                end
            end
            if not overlap then
                table.insert(pins, {
                    kind = "QUEST_UNFINISHED_TURNIN",
                    isComplete = false,
                    title = string.format("? Turn-In (In Progress): %s (Lv %d)", sq.title or "Quest", sq.level or 1),
                    sub = "Hand-In NPC: |cffcccccc" .. (sq.endNpc or "Quest Finisher") .. "|r (Complete objectives first)",
                    x = ex,
                    y = ey,
                    note = string.format("Return to %s at (%.1f, %.1f) once objectives are complete.", sq.endNpc or "NPC", ex, ey),
                    color = { 0.65, 0.70, 0.78 },
                    icon = "Interface\\GossipFrame\\IncompleteQuestIcon",
                    atlas = "QuestTurnin",
                    desaturate = true,
                })
            end
        end
    end

    -- 3. Gathering Profession, Rare Elite & Treasure Chest Hotspots
    for _, h in ipairs(V.GatheringAndLootHotspots or {}) do
        if h.zone == z then
            local show = false
            local col = { 0.2, 1.0, 0.4 }
            local ic = "Interface\\Icons\\INV_Misc_Herb_07"
            if h.cat == "HERBALISM" and db.mapFilterHerbs then
                show = true; col = { 0.20, 0.95, 0.35 }; ic = "Interface\\Icons\\Trade_Herbalism"
            elseif h.cat == "MINING" and db.mapFilterMining then
                show = true; col = { 0.95, 0.65, 0.20 }; ic = "Interface\\Icons\\Trade_Mining"
            elseif h.cat == "SKINNING_HUB" and db.mapFilterSkinning then
                show = true; col = { 0.90, 0.45, 0.25 }; ic = "Interface\\Icons\\INV_Misc_Pelt_Wolf_01"
            elseif (h.cat == "TREASURE_CHEST" or h.cat == "RARE_ELITE_LOOT" or h.cat == "FISHING") and db.mapFilterChests then
                show = true
                col = (h.cat == "RARE_ELITE_LOOT") and { 0.85, 0.35, 1.0 } or { 0.35, 0.85, 1.0 }
                ic = (h.cat == "RARE_ELITE_LOOT") and "Interface\\Icons\\Ability_Hunter_SniperShot" or "Interface\\Icons\\INV_Box_01"
            end
            if show then
                table.insert(pins, {
                    kind = h.cat,
                    title = string.format("%s (%d spawns)", h.name, h.count or 1),
                    sub = string.format("Skill/Lv Req: %d  •  %s", h.req or 1, h.alt or "Guild Gatherer"),
                    x = h.x,
                    y = h.y,
                    note = h.tip .. "\nClusters: " .. (h.clusters or ""),
                    color = col,
                    icon = ic,
                })
            end
        end
    end

    return pins, orderedRoute, z, uiMapID
end

-- ============================================================================
-- 6B. LIVE CLASSIC QUEST LOG SCANNER & PRIORITY ROUTER (For Right-Side Dropdown)
-- ============================================================================
local completedQuestCache = {}

function KF:IsForeverClient()
    if GetBuildInfo then
        local ver, _, _, toc = GetBuildInfo()
        if tonumber(toc) == 16001 or (type(ver) == "string" and ver:find("^1%.60")) then
            return true
        end
    end
    return false
end

function KF:IsQuestCompleted(questID)
    questID = tonumber(questID)
    if not questID or questID <= 0 then return false end
    if completedQuestCache[questID] then return true end
    local fn = (C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted) or IsQuestFlaggedCompleted
    if fn then
        local ok, res = pcall(fn, questID)
        if ok and res == true then
            completedQuestCache[questID] = true
            return true
        end
    end
    return false
end

function KF:IsQuestAvailableToPlayer(q, pLvl, pFac, activeByID)
    if not q or not q.id then return false end
    -- Filter out Forever-only custom quests (id >= 70000) when running on standard Classic Era / Anniversary
    if q.isForever == 1 and not self:IsForeverClient() then
        return false
    end
    if q.fac and q.fac ~= "Both" and q.fac ~= pFac then
        return false
    end
    if activeByID and (activeByID[q.id] or (q.name and activeByID[q.name:lower()])) then
        return false
    end
    if self:IsQuestCompleted(q.id) then
        return false
    end
    local reqL = tonumber(q.minL) or 1
    local qL = tonumber(q.lvl) or 1
    pLvl = tonumber(pLvl) or 1
    if reqL > (pLvl + 2) or qL > (pLvl + 5) then
        return false
    end
    -- Hide grey trivial quests more than 9 levels below player unless in a starting zone at low level
    if pLvl >= 12 and (qL + 9) < pLvl then
        return false
    end
    -- Check Prerequisite Quests (preAll: all required; preAny: at least one required)
    if q.preAll and q.preAll ~= "" then
        for preId in tostring(q.preAll):gmatch("%d+") do
            if not self:IsQuestCompleted(tonumber(preId)) then
                return false
            end
        end
    end
    if q.preAny and q.preAny ~= "" then
        local anyDone = false
        for preId in tostring(q.preAny):gmatch("%d+") do
            if self:IsQuestCompleted(tonumber(preId)) then
                anyDone = true
                break
            end
        end
        if not anyDone then
            return false
        end
    end
    return true
end

function KF:GetActiveQuestLogEntries()
    local results = {}
    if not GetNumQuestLogEntries or not GetQuestLogTitle then return results end

    local _, _, _, _, pLvl, _, curZone, _, px, py = self:GetPlayerContext()
    local V = TheKingdomForgeVault or {}
    local byID = V.AllQuestsByID or {}
    local byTitle = V.AllQuestsByTitle or {}
    local zoneToMap = V.ZoneToUIMapID or {}

    local numEntries = GetNumQuestLogEntries() or 0
    local currentHeaderZone = curZone or "Elwynn Forest"

    for i = 1, numEntries do
        local title, level, suggestedGroup, isHeader, isCollapsed, isComplete, frequency, questID = GetQuestLogTitle(i)
        if title then
            if isHeader then
                currentHeaderZone = title
            else
                local cleanTitle = title:gsub("^%[.-%]%s*", ""):gsub("^%s+", ""):gsub("%s+$", "")
                local qID = tonumber(questID) or byTitle[cleanTitle:lower()] or 0
                local dbEntry = (qID > 0 and byID[qID]) or nil
                if not dbEntry then
                    local tid = byTitle[cleanTitle:lower()]
                    if tid then
                        qID = tid
                        dbEntry = byID[tid]
                    end
                end

                -- Collect live objective progress lines first so we know if the quest is Completed (?) or Incomplete!
                local objectives = {}
                local numObj = (GetNumQuestLeaderBoards and GetNumQuestLeaderBoards(i)) or 0
                local allObjDone = (numObj > 0)
                for j = 1, numObj do
                    local objText, objType, finished = GetQuestLogLeaderBoard(j, i)
                    if objText and objText ~= "" then
                        table.insert(objectives, { text = objText, done = finished and true or false })
                        if not finished then allObjDone = false end
                    end
                end

                local apiComplete = (isComplete == 1 or isComplete == true)
                if not apiComplete and qID > 0 and C_QuestLog and C_QuestLog.IsComplete then
                    local okC, cVal = pcall(C_QuestLog.IsComplete, qID)
                    if okC and cVal == true then apiComplete = true end
                end
                -- 0-objective talk/delivery quests (e.g. 'A Threat Within', 'Report to Goldshire') are immediately ready to Turn In (?)
                local completeFlag = apiComplete or allObjDone or (numObj == 0 and isComplete ~= -1)

                local defaultZone = (dbEntry and dbEntry.zone) or (zoneToMap[currentHeaderZone] and currentHeaderZone) or curZone or "Elwynn Forest"
                local startZone = (dbEntry and dbEntry.zone) or defaultZone
                local startX = (dbEntry and dbEntry.x) or 50.0
                local startY = (dbEntry and dbEntry.y) or 50.0
                local startNpc = (dbEntry and dbEntry.npc) or "Quest Giver"

                local endZone = (dbEntry and dbEntry.endZone) or startZone
                local endX = (dbEntry and dbEntry.endX) or startX
                local endY = (dbEntry and dbEntry.endY) or startY
                local endNpc = (dbEntry and dbEntry.endNpc) or startNpc

                local objZone = (dbEntry and dbEntry.objZone) or startZone
                local objX = (dbEntry and dbEntry.objX) or endX
                local objY = (dbEntry and dbEntry.objY) or endY
                local objTarget = (dbEntry and dbEntry.objTarget) or endNpc

                -- Route to Turn-In NPC (?) when Complete, or to Objective Spawn when Incomplete!
                local qZone, qx, qy, qNpc
                if completeFlag then
                    qZone = endZone
                    qx = endX
                    qy = endY
                    qNpc = endNpc
                else
                    qZone = objZone
                    qx = objX
                    qy = objY
                    qNpc = objTarget
                end

                -- Calculate distance from player if in current zone
                local distYds = 9999
                if qZone == curZone and px and py and px > 0 and py > 0 then
                    local dx = qx - px
                    local dy = qy - py
                    distYds = math.floor(math.sqrt(dx * dx + dy * dy) * 12)
                end

                -- Priority Score (lower score = higher priority at top of dropdown!)
                -- 1. Ready to Turn In (?) in Current Zone -> 2. Active Objectives in Current Zone (by distance)
                -- 3. Ready to Turn In (?) in Other Zone  -> 4. Active Objectives in Other Zone (by level)
                local prioScore = 5000
                if qZone == curZone then
                    if completeFlag then
                        prioScore = 100 + math.min(90, distYds / 10)
                    else
                        prioScore = 1000 + math.min(800, distYds)
                    end
                else
                    if completeFlag then
                        prioScore = 2000 + math.abs((tonumber(level) or pLvl) - pLvl) * 10
                    else
                        prioScore = 3000 + math.abs((tonumber(level) or pLvl) - pLvl) * 20
                    end
                end

                local objSummary = ""
                if completeFlag then
                    objSummary = "|cff22c55e? Ready to Turn In to " .. (endNpc ~= "" and endNpc or "Quest Giver") .. "!|r"
                elseif #objectives > 0 then
                    local parts = {}
                    for _, ob in ipairs(objectives) do
                        table.insert(parts, (ob.done and "|cff22c55e" or "|cffffd100") .. ob.text .. "|r")
                    end
                    objSummary = table.concat(parts, "  •  ")
                else
                    objSummary = "Target: " .. (qNpc ~= "" and qNpc or "Quest Objective")
                end

                table.insert(results, {
                    logIndex = i,
                    id = qID,
                    title = cleanTitle,
                    level = tonumber(level) or pLvl,
                    group = suggestedGroup,
                    header = currentHeaderZone,
                    zone = qZone,
                    x = qx,
                    y = qy,
                    npc = qNpc,
                    endZone = endZone,
                    endX = endX,
                    endY = endY,
                    endNpc = endNpc,
                    isComplete = completeFlag,
                    objectives = objectives,
                    objSummary = objSummary,
                    distYds = distYds,
                    inCurrentZone = (qZone == curZone),
                    prioScore = prioScore,
                })
            end
        end
    end

    table.sort(results, function(a, b)
        if a.prioScore ~= b.prioScore then
            return a.prioScore < b.prioScore
        end
        return (a.title or "") < (b.title or "")
    end)

    for rank, entry in ipairs(results) do
        entry.prioRank = rank
    end

    return results
end

function KF:FocusQuestOnMaps(qEntry, openMode)
    if not qEntry then return end
    local db = self:EnsureDB()
    db.focusedQuestRoute = {
        id = qEntry.id,
        name = qEntry.title,
        lvl = qEntry.level,
        zone = qEntry.zone,
        x = qEntry.x,
        y = qEntry.y,
        npc = qEntry.npc,
        endZone = qEntry.endZone,
        endX = qEntry.endX,
        endY = qEntry.endY,
        endNpc = qEntry.endNpc,
        isComplete = qEntry.isComplete,
        objSummary = qEntry.objSummary,
    }
    if qEntry.zone and qEntry.zone ~= "" then
        db.selectedZone = qEntry.zone
    end

    -- Also lock RoyalCompassHUD arrow directly onto this quest!
    if _G.RoyalCompassHUD_SetQuestTarget then
        _G.RoyalCompassHUD_SetQuestTarget(qEntry.title, qEntry.zone, qEntry.x, qEntry.y)
    end

    local V = TheKingdomForgeVault or {}
    local targetMapID = (V.ZoneToUIMapID and V.ZoneToUIMapID[qEntry.zone]) or nil

    if openMode == "WORLD_MAP" then
        if WorldMapFrame then
            if not WorldMapFrame:IsShown() and ToggleWorldMap then
                ToggleWorldMap()
            elseif not WorldMapFrame:IsShown() then
                ShowUIPanel(WorldMapFrame)
            end
            if targetMapID and WorldMapFrame.SetMapID then
                pcall(WorldMapFrame.SetMapID, WorldMapFrame, targetMapID)
            end
        end
    elseif openMode == "FORGE_MAP" then
        if _G.TheKingdomForgeMainFrame then
            _G.TheKingdomForgeMainFrame:Show()
            if self.SelectTab then self:SelectTab(3) end
        end
    else
        -- If WorldMapFrame is already open, jump it to the quest's zone and refresh!
        if WorldMapFrame and WorldMapFrame:IsShown() and targetMapID and WorldMapFrame.SetMapID then
            pcall(WorldMapFrame.SetMapID, WorldMapFrame, targetMapID)
        end
    end

    if self.RefreshNativeWorldMapOverlay then
        self:RefreshNativeWorldMapOverlay(true)
    end
    if self.RefreshPage3 and _G.TheKingdomForgeMainFrame and _G.TheKingdomForgeMainFrame:IsShown() then
        self:RefreshPage3()
    end
end

-- ============================================================================
-- 1B. LIVE PLAYER IN-GAME TALENT SCANNER (Syncs Actual Trained Points)
-- ============================================================================
function KF:ScanLivePlayerTalents()
    local _, pCls, _, _, pLvl = self:GetPlayerContext()
    local liveByTab = { [1] = {}, [2] = {}, [3] = {} }
    local liveByPos = { [1] = {}, [2] = {}, [3] = {} }
    local totalSpent = 0
    local tabSpent = { [1] = 0, [2] = 0, [3] = 0 }

    if GetNumTalentTabs and GetNumTalents and GetTalentInfo then
        local numTabs = GetNumTalentTabs() or 0
        for tab = 1, math.min(3, numTabs) do
            local numTalents = GetNumTalents(tab) or 0
            for idx = 1, numTalents do
                local ok, name, iconTex, tier, column, rank, maxRank = pcall(GetTalentInfo, tab, idx)
                if ok and name then
                    rank = tonumber(rank) or 0
                    tier = tonumber(tier) or 1
                    column = tonumber(column) or 1
                    liveByTab[tab][name:lower()] = rank
                    liveByPos[tab][tier .. ":" .. column] = rank
                    tabSpent[tab] = tabSpent[tab] + rank
                    totalSpent = totalSpent + rank
                end
            end
        end
    end

    local expectedPts = math.max(0, (tonumber(pLvl) or 1) - 9)
    local unspent = math.max(0, expectedPts - totalSpent)
    if UnitCharacterPoints then
        local okU, uPts = pcall(UnitCharacterPoints, "player")
        if okU and tonumber(uPts) then
            unspent = tonumber(uPts)
        end
    end

    return pCls, pLvl, liveByTab, liveByPos, tabSpent, totalSpent, unspent
end

-- Hook WorldMapFrame Show to auto-reveal Fog of War
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_LEVEL_UP")
eventFrame:RegisterEvent("PLAYER_XP_UPDATE")
eventFrame:RegisterEvent("CHARACTER_POINTS_CHANGED")
eventFrame:RegisterEvent("BAG_UPDATE_DELAYED")
eventFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
eventFrame:SetScript("OnEvent", function(_, event)
    local db = KF:EnsureDB()
    if not db._v2RevealMigrated then
        db._v2RevealMigrated = true
        db.fogRevealEnabled = true
        db.mapFilterFlight = true
        db.mapFilterQuests = true
        db.mapFilterHerbs = true
        db.mapFilterMining = true
        db.mapFilterSkinning = true
        db.mapFilterChests = true
    end
    KF:ScanCurrentCharacter()
    if event == "PLAYER_LOGIN" then
        KF:ApplyWorldMapFogReveal()
        if WorldMapFrame and WorldMapFrame.HookScript then
            WorldMapFrame:HookScript("OnShow", function()
                KF:ApplyWorldMapFogReveal()
            end)
        end
        if WorldMapFrame and hooksecurefunc then
            pcall(hooksecurefunc, WorldMapFrame, "OnMapChanged", function()
                KF:ApplyWorldMapFogReveal()
            end)
        end
        print("|cffffd100[The Kingdom Forge]|r |cff00ffccv1.60.1 Royal Suite Loaded!|r Click the golden Minimap Crest or type |cffffd100/kf|r to open.")
    end
    if KF.RefreshActivePage then
        KF:RefreshActivePage()
    end
end)
