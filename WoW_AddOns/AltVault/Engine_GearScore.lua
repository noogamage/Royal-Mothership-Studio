-- ============================================================================
-- FILE: Engine_GearScore.lua (MODULE 1 OF 3 SPLIT FROM Engine_Scanner.lua)
-- BLOCK HEADING: MODULE CONFIGURATION, CONSTANTS & ITEM CACHING ENGINE
-- ============================================================================
local addonName, ns = ...
local Scanner = ns.Scanner or {}
ns.Scanner = Scanner

local ItemScanTip = CreateFrame("GameTooltip", "AltVaultItemPatternScanTooltip", nil, "GameTooltipTemplate")
ItemScanTip:SetOwner(WorldFrame, "ANCHOR_NONE")
Scanner.ItemScanTip = ItemScanTip

local EQUIP_LOC_TO_SLOTS = {
    INVTYPE_HEAD = {1}, INVTYPE_NECK = {2}, INVTYPE_SHOULDER = {3},
    INVTYPE_BODY = {4}, INVTYPE_CHEST = {5}, INVTYPE_ROBE = {5},
    INVTYPE_WAIST = {6}, INVTYPE_LEGS = {7}, INVTYPE_FEET = {8},
    INVTYPE_WRIST = {9}, INVTYPE_HAND = {10}, INVTYPE_FINGER = {11, 12},
    INVTYPE_TRINKET = {13, 14}, INVTYPE_CLOAK = {15}, INVTYPE_WEAPON = {16, 17},
    INVTYPE_SHIELD = {17}, INVTYPE_2HWEAPON = {16}, INVTYPE_WEAPONMAINHAND = {16},
    INVTYPE_WEAPONOFFHAND = {17}, INVTYPE_HOLDABLE = {17}, INVTYPE_RANGED = {18},
    INVTYPE_THROWN = {18}, INVTYPE_RANGEDRIGHT = {18}, INVTYPE_RELIC = {18},
}

local EQUIP_LOC_LABELS = {
    INVTYPE_HEAD = "Head", INVTYPE_NECK = "Neck", INVTYPE_SHOULDER = "Shoulder",
    INVTYPE_BODY = "Shirt", INVTYPE_CHEST = "Chest", INVTYPE_ROBE = "Chest (Robe)",
    INVTYPE_WAIST = "Waist", INVTYPE_LEGS = "Legs", INVTYPE_FEET = "Feet",
    INVTYPE_WRIST = "Wrist", INVTYPE_HAND = "Hands", INVTYPE_FINGER = "Finger",
    INVTYPE_TRINKET = "Trinket", INVTYPE_CLOAK = "Back", INVTYPE_WEAPON = "One-Hand Weapon",
    INVTYPE_SHIELD = "Off Hand (Shield)", INVTYPE_2HWEAPON = "Two-Hand Weapon",
    INVTYPE_WEAPONMAINHAND = "Main Hand Weapon", INVTYPE_WEAPONOFFHAND = "Off Hand Weapon",
    INVTYPE_HOLDABLE = "Held In Off-Hand", INVTYPE_RANGED = "Ranged",
    INVTYPE_THROWN = "Thrown", INVTYPE_RANGEDRIGHT = "Ranged / Wand",
    INVTYPE_RELIC = "Relic", INVTYPE_BAG = "Container / Bag",
}

local SLOT_WEIGHTS = {
    INVTYPE_2HWEAPON = 2.0,
    INVTYPE_HEAD = 1.0, INVTYPE_CHEST = 1.0, INVTYPE_ROBE = 1.0, INVTYPE_LEGS = 1.0,
    INVTYPE_SHOULDER = 0.75, INVTYPE_HAND = 0.75, INVTYPE_WAIST = 0.75, INVTYPE_FEET = 0.75,
    INVTYPE_NECK = 0.5625, INVTYPE_WRIST = 0.5625, INVTYPE_FINGER = 0.5625,
    INVTYPE_TRINKET = 0.5625, INVTYPE_CLOAK = 0.5625,
    INVTYPE_WEAPON = 1.0, INVTYPE_WEAPONMAINHAND = 1.0, INVTYPE_WEAPONOFFHAND = 1.0,
    INVTYPE_SHIELD = 1.0, INVTYPE_HOLDABLE = 1.0,
    INVTYPE_RANGED = 0.3164, INVTYPE_THROWN = 0.3164, INVTYPE_RANGEDRIGHT = 0.3164, INVTYPE_RELIC = 0.3164,
}

local QUALITY_MULTIPLIERS = {
    [0] = 0.5, [1] = 0.75, [2] = 1.0, [3] = 1.25, [4] = 1.6, [5] = 2.0,
}

local QUALITY_NAMES = {
    [0] = "|cff9d9d9dPoor (Grey)|r",
    [1] = "|cffffffffCommon (White)|r",
    [2] = "|cff1eff00Uncommon (Green)|r",
    [3] = "|cff0070ddRare (Blue)|r",
    [4] = "|cffa335eeEpic (Purple)|r",
    [5] = "|cffff8000Legendary (Orange)|r",
}

local QUALITY_HEX = {
    [0] = "9d9d9d", [1] = "ffffff", [2] = "1eff00",
    [3] = "0070dd", [4] = "a335ee", [5] = "ff8000",
}

local BIND_TYPE_LABELS = {
    [0] = "Not Bound (Tradeable)",
    [1] = "Binds when picked up (BoP)",
    [2] = "Binds when equipped (BoE)",
    [3] = "Binds when used (BoU)",
    [4] = "Quest Item",
}

local LEGACY_ITEMTYPE_TO_CLASSID = {
    ["Consumable"]    = 0,
    ["Container"]     = 1,
    ["Weapon"]        = 2,
    ["Gem"]           = 3,
    ["Armor"]         = 4,
    ["Reagent"]       = 5,
    ["Projectile"]    = 6,
    ["Trade Goods"]   = 7,
    ["Tradeskill"]    = 7,
    ["Recipe"]        = 9,
    ["Quiver"]        = 11,
    ["Quest"]         = 12,
    ["Key"]           = 13,
    ["Miscellaneous"] = 15,
    ["Glyph"]         = 16,
}

local CLASS_IDEAL_ARMOR = {
    WARRIOR     = { low = "Mail",    high = "Plate",   canShield = true },
    PALADIN     = { low = "Mail",    high = "Plate",   canShield = true },
    DEATHKNIGHT = { low = "Plate",   high = "Plate",   canShield = false },
    HUNTER      = { low = "Leather", high = "Mail",    canShield = false },
    SHAMAN      = { low = "Leather", high = "Mail",    canShield = true },
    ROGUE       = { low = "Leather", high = "Leather", canShield = false },
    DRUID       = { low = "Leather", high = "Leather", canShield = false },
    MONK        = { low = "Leather", high = "Leather", canShield = false },
    PRIEST      = { low = "Cloth",   high = "Cloth",   canShield = false },
    MAGE        = { low = "Cloth",   high = "Cloth",   canShield = false },
    WARLOCK     = { low = "Cloth",   high = "Cloth",   canShield = false },
}

local ARMOR_SUBTYPE_TO_CLASSES = {
    ["Plate"]   = "Warrior, Paladin, Death Knight",
    ["Mail"]    = "Hunter, Shaman, Warrior, Paladin",
    ["Leather"] = "Rogue, Druid, Monk, Hunter, Shaman",
    ["Cloth"]   = "Priest, Mage, Warlock",
    ["Shields"] = "Warrior, Paladin, Shaman",
}

local CLASS_WEAPONS = {
    WARRIOR     = { ["One-Handed Axes"]=true, ["Two-Handed Axes"]=true, ["One-Handed Swords"]=true, ["Two-Handed Swords"]=true, ["One-Handed Maces"]=true, ["Two-Handed Maces"]=true, ["Polearms"]=true, ["Staves"]=true, ["Daggers"]=true, ["Fist Weapons"]=true, ["Bows"]=true, ["Crossbows"]=true, ["Guns"]=true, ["Thrown"]=true },
    PALADIN     = { ["One-Handed Axes"]=true, ["Two-Handed Axes"]=true, ["One-Handed Swords"]=true, ["Two-Handed Swords"]=true, ["One-Handed Maces"]=true, ["Two-Handed Maces"]=true, ["Polearms"]=true },
    DEATHKNIGHT = { ["One-Handed Axes"]=true, ["Two-Handed Axes"]=true, ["One-Handed Swords"]=true, ["Two-Handed Swords"]=true, ["One-Handed Maces"]=true, ["Two-Handed Maces"]=true, ["Polearms"]=true },
    HUNTER      = { ["One-Handed Axes"]=true, ["Two-Handed Axes"]=true, ["One-Handed Swords"]=true, ["Two-Handed Swords"]=true, ["Polearms"]=true, ["Staves"]=true, ["Daggers"]=true, ["Fist Weapons"]=true, ["Bows"]=true, ["Crossbows"]=true, ["Guns"]=true },
    SHAMAN      = { ["One-Handed Axes"]=true, ["Two-Handed Axes"]=true, ["One-Handed Maces"]=true, ["Two-Handed Maces"]=true, ["Staves"]=true, ["Daggers"]=true, ["Fist Weapons"]=true },
    ROGUE       = { ["One-Handed Axes"]=true, ["One-Handed Swords"]=true, ["One-Handed Maces"]=true, ["Daggers"]=true, ["Fist Weapons"]=true, ["Bows"]=true, ["Crossbows"]=true, ["Guns"]=true, ["Thrown"]=true },
    DRUID       = { ["One-Handed Maces"]=true, ["Two-Handed Maces"]=true, ["Polearms"]=true, ["Staves"]=true, ["Daggers"]=true, ["Fist Weapons"]=true },
    MONK        = { ["One-Handed Axes"]=true, ["One-Handed Swords"]=true, ["One-Handed Maces"]=true, ["Polearms"]=true, ["Staves"]=true, ["Fist Weapons"]=true },
    PRIEST      = { ["One-Handed Maces"]=true, ["Staves"]=true, ["Daggers"]=true, ["Wands"]=true },
    MAGE        = { ["One-Handed Swords"]=true, ["Staves"]=true, ["Daggers"]=true, ["Wands"]=true },
    WARLOCK     = { ["One-Handed Swords"]=true, ["Staves"]=true, ["Daggers"]=true, ["Wands"]=true },
}

Scanner.EQUIP_LOC_TO_SLOTS = EQUIP_LOC_TO_SLOTS
Scanner.EQUIP_LOC_LABELS = EQUIP_LOC_LABELS
Scanner.QUALITY_NAMES = QUALITY_NAMES
Scanner.QUALITY_HEX = QUALITY_HEX
Scanner.BIND_TYPE_LABELS = BIND_TYPE_LABELS
Scanner.CLASS_IDEAL_ARMOR = CLASS_IDEAL_ARMOR
Scanner.CLASS_WEAPONS = CLASS_WEAPONS

-- ============================================================================
-- BLOCK HEADING: PERSISTENT GEAR, CLASS, RACE & PATTERN CACHES
-- ============================================================================
local function ExtractItemID(item)
    if not item then return nil end
    if type(item) == "number" then return item end
    return tonumber(string.match(tostring(item), "item:(%d+)")) or tonumber(item)
end

Scanner.ExtractItemID = ExtractItemID

local function FetchItemStatsTable(itemLinkOrID)
    if not itemLinkOrID or type(itemLinkOrID) ~= "string" then return nil end
    if C_Item and C_Item.GetItemStats then
        return C_Item.GetItemStats(itemLinkOrID)
    elseif GetItemStats then
        return GetItemStats(itemLinkOrID)
    end
    return nil
end

local function DetectGearStatRole(itemLinkOrID)
    local stats = FetchItemStatsTable(itemLinkOrID)
    if not stats then return nil end

    local hasDef   = (stats["ITEM_MOD_DEFENSE_SKILL_RATING_SHORT"] or stats["ITEM_MOD_BLOCK_RATING_SHORT"] or stats["ITEM_MOD_PARRY_RATING_SHORT"] or stats["ITEM_MOD_DODGE_RATING_SHORT"] or 0) > 0
    local hasHeal  = (stats["ITEM_MOD_SPELL_HEALING_DONE_SHORT"] or stats["ITEM_MOD_SPIRIT_SHORT"] or 0) > 0
    local hasSpell = (stats["ITEM_MOD_SPELL_POWER_SHORT"] or stats["ITEM_MOD_SPELL_DAMAGE_DONE_SHORT"] or 0) > 0
    local hasInt   = (stats["ITEM_MOD_INTELLECT_SHORT"] or 0) > 0
    local hasStr   = (stats["ITEM_MOD_STRENGTH_SHORT"] or 0) > 0
    local hasAgi   = (stats["ITEM_MOD_AGILITY_SHORT"] or 0) > 0
    local hasAP    = (stats["ITEM_MOD_ATTACK_POWER_SHORT"] or stats["ITEM_MOD_RANGED_ATTACK_POWER_SHORT"] or 0) > 0

    if hasDef then return "TANK" end
    if hasHeal and not hasSpell and not hasAgi and not hasStr then return "HEALER" end
    if hasSpell or (hasInt and not hasStr and not hasAgi) then return "CASTER_DPS" end
    if hasStr and not hasInt then return "MELEE_STR" end
    if hasAgi and not hasStr and not hasInt then return "MELEE_AGI" end
    if hasAP then return "MELEE_AGI" end
    return "ANY"
end

-- Scans tooltip for explicit "Classes: ..." and "Races: ..." restrictions
local function ExtractItemClassAndRaceRestrictions(itemID, itemLinkOrID, itemType, itemSubType, itemEquipLoc)
    local allowedClasses = nil
    local allowedRaces = nil

    ItemScanTip:ClearLines()
    ItemScanTip:SetOwner(WorldFrame, "ANCHOR_NONE")
    local linkStr = (type(itemLinkOrID) == "string" and string.find(itemLinkOrID, "item:")) and itemLinkOrID or ("item:" .. tostring(itemID))
    pcall(ItemScanTip.SetHyperlink, ItemScanTip, linkStr)

    local numLines = ItemScanTip:NumLines() or 0
    for i = 2, numLines do
        local leftFont = _G["AltVaultItemPatternScanTooltipTextLeft" .. i]
        local text = leftFont and leftFont:GetText()
        if text and text ~= "" then
            local clsMatch = string.match(text, "^Classes:%s*(.+)$")
            if clsMatch then
                allowedClasses = clsMatch
            end
            local raceMatch = string.match(text, "^Races:%s*(.+)$")
            if raceMatch then
                allowedRaces = raceMatch
            end
        end
    end

    if not allowedClasses and itemType == "Armor" and itemSubType then
        if itemEquipLoc == "INVTYPE_CLOAK" or itemEquipLoc == "INVTYPE_NECK" or itemEquipLoc == "INVTYPE_FINGER" or itemEquipLoc == "INVTYPE_TRINKET" then
            allowedClasses = "All Classes"
        else
            allowedClasses = ARMOR_SUBTYPE_TO_CLASSES[itemSubType] or "All Classes"
        end
    elseif not allowedClasses and itemType == "Weapon" and itemSubType then
        local cList = {}
        for clsToken, wMap in pairs(CLASS_WEAPONS) do
            if wMap[itemSubType] then
                table.insert(cList, clsToken)
            end
        end
        table.sort(cList)
        if #cList > 0 then
            allowedClasses = table.concat(cList, ", ")
        end
    end

    return allowedClasses, allowedRaces
end

local function ExtractCraftedNameFromPattern(patternName)
    if not patternName then return nil end
    local stripped = string.match(patternName, "^[^:]+:%s*(.+)$")
    return stripped or patternName
end

local function ScanAndCachePatternDetails(itemID, itemLinkOrID, patternName, fallbackProf, itemMinLevel)
    if not itemID then return nil end
    if AltVaultDB and AltVaultDB.PatternDB and AltVaultDB.PatternDB[itemID] then
        return AltVaultDB.PatternDB[itemID]
    end

    local detectedProf = fallbackProf
    local detectedSkill = nil

    ItemScanTip:ClearLines()
    ItemScanTip:SetOwner(WorldFrame, "ANCHOR_NONE")
    local linkStr = (type(itemLinkOrID) == "string" and string.find(itemLinkOrID, "item:")) and itemLinkOrID or ("item:" .. tostring(itemID))
    pcall(ItemScanTip.SetHyperlink, ItemScanTip, linkStr)

    local numLines = ItemScanTip:NumLines() or 0
    for i = 2, numLines do
        local leftFont = _G["AltVaultItemPatternScanTooltipTextLeft" .. i]
        local text = leftFont and leftFont:GetText()
        if text and text ~= "" then
            local profMatch, rankMatch = string.match(text, "Requires%s+([%a%s]+)%s*%((%d+)%)")
            if profMatch and rankMatch then
                profMatch = string.gsub(profMatch, "^%s*(.-)%s*$", "%1")
                detectedProf = profMatch
                detectedSkill = tonumber(rankMatch)
                break
            end
        end
    end

    if detectedProf and detectedProf ~= "" then
        local patRecord = {
            n  = patternName or ("Pattern #" .. itemID),
            p  = detectedProf,
            s  = detectedSkill or ((itemMinLevel and itemMinLevel > 1) and (itemMinLevel * 5)) or 150,
            cn = ExtractCraftedNameFromPattern(patternName)
        }
        if AltVaultDB then
            AltVaultDB.PatternDB = AltVaultDB.PatternDB or {}
            AltVaultDB.PatternDB[itemID] = patRecord
        end
        return patRecord
    end
    return nil
end

Scanner.FetchItemStatsTable = FetchItemStatsTable
Scanner.DetectGearStatRole = DetectGearStatRole
Scanner.ExtractCraftedNameFromPattern = ExtractCraftedNameFromPattern
Scanner.ScanAndCachePatternDetails = ScanAndCachePatternDetails
Scanner.ExtractItemClassAndRaceRestrictions = ExtractItemClassAndRaceRestrictions

local FOREVER_BLOCKED_ITEM_IDS = {
    [17] = true, [192] = true, [2189] = true, [3687] = true, [3895] = true, [5828] = true,
    [6698] = true, [6707] = true, [6708] = true, [6711] = true, [6724] = true, [6728] = true,
    [12947] = true, [17122] = true, [17802] = true, [18565] = true, [18582] = true, [18583] = true,
    [18584] = true, [18589] = true, [18881] = true, [19158] = true, [122270] = true, [122284] = true,
    [232454] = true, [232455] = true, [232456] = true, [232457] = true,
}

function Scanner.IsValidWowForeverItem(itemID, itemName, itemQuality, baseILvl, itemMinLevel, itemType, itemSubType, itemEquipLoc, classID, expacID)
    local id = tonumber(itemID)
    if not id or id <= 0 then return false end
    if FOREVER_BLOCKED_ITEM_IDS[id] then return false end

    local isSeenInWorld = (AltVaultDB and AltVaultDB.SourceDB and AltVaultDB.SourceDB[id] ~= nil)
        or (ns.MasterDB and ns.MasterDB.ByItemID and ns.MasterDB.ByItemID[id] ~= nil)

    -- 1. Enforce WoW Forever ID Ranges: Classic (1..24500), Custom Forever (180000..500000), or any item physically seen in the live Forever world
    if id > 24500 and id < 180000 and not isSeenInWorld then
        return false
    end
    if id > 500000 and not isSeenInWorld then
        return false
    end

    -- 2. Enforce Character Required Level <= 60 (No artificial iLvl <= 92 cap so custom high-iLvl Level 60 raid/legendary items are never blocked)
    local reqLvl = tonumber(itemMinLevel) or 0
    if reqLvl > 60 then
        return false
    end

    -- 3. Reject Artifact/Heirloom/Token Qualities (>= 6), Glyphs (16), and WoW Tokens (18)
    local qual = tonumber(itemQuality) or 1
    if qual >= 6 then
        return false
    end
    if classID == 16 or classID == 18 then
        return false
    end
    if expacID and tonumber(expacID) and tonumber(expacID) > 0 and id <= 24500 and not isSeenInWorld then
        return false
    end

    -- 4. Reject Obsolete / Token / Glyph Item Types & SubTypes
    local tUpper = string.upper(tostring(itemType or ""))
    local stUpper = string.upper(tostring(itemSubType or ""))
    if string.find(tUpper, "OBSOLETE", 1, true) or string.find(stUpper, "OBSOLETE", 1, true)
        or string.find(tUpper, "WOW TOKEN", 1, true) or string.find(stUpper, "WOW TOKEN", 1, true)
        or string.find(tUpper, "GLYPH", 1, true) or string.find(stUpper, "GLYPH", 1, true) then
        return false
    end

    -- 5. Reject Developer, GM, Test, Deprecated, and Placeholder Items by Name
    if itemName and itemName ~= "" then
        local nUpper = string.upper(tostring(itemName))
        if string.find(nUpper, "DEPRECATED", 1, true)
            or string.find(nUpper, "OBSOLETE", 1, true)
            or string.find(nUpper, "(TEST)", 1, true)
            or string.find(nUpper, "TEST ", 1, true)
            or string.find(nUpper, " TEST", 1, true)
            or string.find(nUpper, "[PH]", 1, true)
            or string.find(nUpper, "(PH)", 1, true)
            or string.find(nUpper, "UNUSED", 1, true)
            or string.find(nUpper, "MONSTER -", 1, true)
            or string.find(nUpper, "TIGOLE", 1, true)
            or string.find(nUpper, "ALEX'S RING", 1, true)
            or string.find(nUpper, "WARGLAIVE OF AZZINOTH", 1, true)
            or string.find(nUpper, "TWIN BLADES OF AZZINOTH", 1, true)
            or string.find(nUpper, "UBER RESISTS", 1, true)
            or string.find(nUpper, "MARTIN FURY", 1, true)
            or string.find(nUpper, "MARTIN THUNDER", 1, true)
            or string.find(nUpper, "STONE OF BROWNELL", 1, true)
            or string.find(nUpper, "STONE OF BACKUS", 1, true)
            or string.find(nUpper, "STONE OF KURTZ", 1, true)
            or string.find(nUpper, "STONE OF GOODMAN", 1, true)
            or string.find(nUpper, "STONE OF LAPIDIS", 1, true)
            or string.find(nUpper, "STONE OF PIERCE", 1, true) then
            return false
        end
    end

    return true
end

function Scanner.PurgeInvalidForeverItems()
    if not AltVaultDB or not AltVaultDB.ItemCache then return 0 end
    local removed = 0
    for id, info in pairs(AltVaultDB.ItemCache) do
        if type(id) ~= "number" or type(info) ~= "table"
            or not Scanner.IsValidWowForeverItem(id, info.n, info.q, info.l, info.r, info.t, info.st, info.eq, info.c, nil) then
            AltVaultDB.ItemCache[id] = nil
            removed = removed + 1
        end
    end
    return removed
end

function Scanner.CacheItemData(item, strictFilter)
    if not item then return nil end
    local itemID = ExtractItemID(item)

    -- Fast path: if strictFilter background scan hits an already-cached item, skip all tooltip & HoldingTank work
    local existingCache = itemID and AltVaultDB and AltVaultDB.ItemCache and AltVaultDB.ItemCache[itemID]
    if strictFilter and existingCache and existingCache.n then
        return existingCache.n
    end

    local itemName, itemLink, itemQuality, baseILvl, itemMinLevel, itemType, itemSubType,
          itemStackCount, itemEquipLoc, itemTexture, sellPrice, classID, subClassID,
          bindType, expacID, setID, isCraftingReagent

    if C_Item and C_Item.GetItemInfo then
        itemName, itemLink, itemQuality, baseILvl, itemMinLevel, itemType, itemSubType,
        itemStackCount, itemEquipLoc, itemTexture, sellPrice, classID, subClassID,
        bindType, expacID, setID, isCraftingReagent = C_Item.GetItemInfo(item)
    elseif GetItemInfo then
        itemName, itemLink, itemQuality, baseILvl, itemMinLevel, itemType, itemSubType,
        itemStackCount, itemEquipLoc, itemTexture, sellPrice, classID, subClassID,
        bindType, expacID, setID, isCraftingReagent = GetItemInfo(item)
    end

    if itemName and classID == nil and itemType then
        classID = LEGACY_ITEMTYPE_TO_CLASSID[itemType]
    end

    -- Fast return if we already have this item cached in ItemCache (avoids redundant tooltip scans & table churn)
    if itemName and existingCache and existingCache.n then
        return itemName, itemLink, itemQuality, baseILvl, itemMinLevel, itemType, itemSubType,
               itemStackCount, itemEquipLoc, itemTexture, sellPrice, classID, subClassID,
               bindType, expacID, setID, isCraftingReagent
    end

    if itemName and itemID then
        if not Scanner.IsValidWowForeverItem(itemID, itemName, itemQuality, baseILvl, itemMinLevel, itemType, itemSubType, itemEquipLoc, classID, expacID) then
            if AltVaultDB and AltVaultDB.ItemCache then
                AltVaultDB.ItemCache[itemID] = nil
            end
            return nil
        end
    end

    if itemName and itemID and AltVaultDB then
        local isPattern = (classID == 9) or (itemType == "Recipe")
        local isReagent = (classID == 7) or (itemType == "Trade Goods") or (itemType == "Tradeskill") or (isCraftingReagent == true)
        local isEquippableGear = (itemEquipLoc ~= nil and EQUIP_LOC_TO_SLOTS[itemEquipLoc] ~= nil)

        if isPattern and not (AltVaultDB.PatternDB and AltVaultDB.PatternDB[itemID]) then
            ScanAndCachePatternDetails(itemID, itemLink or item, itemName, itemSubType, itemMinLevel)
        end

        -- Save all valid WoW Forever items without quality or category restrictions
        local shouldSaveToItemCache = true

        if shouldSaveToItemCache then
            AltVaultDB.ItemCache = AltVaultDB.ItemCache or {}
            local existing = AltVaultDB.ItemCache[itemID]
            local roleTag = existing and existing.ro
            local allowedClasses = existing and existing.cl
            local allowedRaces = existing and existing.ra
            if isEquippableGear then
                roleTag = roleTag or DetectGearStatRole(itemLink or ("item:" .. tostring(itemID)))
                if not allowedClasses or not allowedRaces then
                    local extCl, extRa = ExtractItemClassAndRaceRestrictions(itemID, itemLink or item, itemType, itemSubType, itemEquipLoc)
                    allowedClasses = allowedClasses or extCl
                    allowedRaces = allowedRaces or extRa
                end
            end

            local record = {
                n  = itemName,
                q  = itemQuality or 1,
                l  = baseILvl or 1,
                r  = itemMinLevel or 1,
                t  = itemType or "Item",
                st = itemSubType or "",
                eq = itemEquipLoc or "",
                ic = itemTexture,
                s  = itemStackCount or 1,
                v  = sellPrice or 0,
                b  = bindType or 0,
                c  = classID,
                sc = subClassID,
                cr = (isCraftingReagent or isReagent) and true or nil,
                ro = roleTag,
                cl = allowedClasses,
                ra = allowedRaces,
                fromMasterTank = nil
            }
            AltVaultDB.ItemCache[itemID] = record
            if ns.MasterDB and ns.MasterDB.SyncSingleItemToHoldingTank then
                ns.MasterDB:SyncSingleItemToHoldingTank(itemID, record)
            end
        end
    end

    if itemName then
        return itemName, itemLink, itemQuality, baseILvl, itemMinLevel, itemType, itemSubType,
               itemStackCount, itemEquipLoc, itemTexture, sellPrice, classID, subClassID,
               bindType, expacID, setID, isCraftingReagent
    end

    local cached = itemID and AltVaultDB and AltVaultDB.ItemCache and AltVaultDB.ItemCache[itemID]
    if cached then
        if not Scanner.IsValidWowForeverItem(itemID, cached.n, cached.q, cached.l, cached.r, cached.t, cached.st, cached.eq, cached.c, nil) then
            AltVaultDB.ItemCache[itemID] = nil
            return nil
        end
        local fallbackLink = (type(item) == "string" and string.find(item, "|Hitem:")) and item
            or string.format("|cff%s|Hitem:%d:0:0:0:0:0:0:0:60|h[%s]|h|r", QUALITY_HEX[cached.q or 1] or "ffffff", itemID, cached.n or ("Item #" .. itemID))
        return cached.n, fallbackLink, cached.q, cached.l, cached.r, cached.t, cached.st,
               cached.s or 1, cached.eq, cached.ic, cached.v or 0, cached.c, cached.sc, cached.b or 0, nil, nil, cached.cr
    end

    -- Fallback to the pre-compiled 15,534-item ForeverIndex so even uncached custom Forever items (180k-287k) resolve instantly!
    local fInfo = itemID and ns.ForeverIndex and ns.ForeverIndex.Info and ns.ForeverIndex:Info(itemID)
    if fInfo and fInfo.name then
        local fallbackLink = (type(item) == "string" and string.find(item, "|Hitem:")) and item
            or string.format("|cff%s|Hitem:%d:0:0:0:0:0:0:0:60|h[%s]|h|r", QUALITY_HEX[fInfo.quality or 1] or "ffffff", itemID, fInfo.name)
        local iconTex = (C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(itemID)) or "Interface\\Icons\\INV_Misc_QuestionMark"
        return fInfo.name, fallbackLink, fInfo.quality or 1, (fInfo.itemLevel and fInfo.itemLevel > 0) and fInfo.itemLevel or math.max(1, fInfo.reqLevel or 1),
               fInfo.reqLevel or 0, fInfo.itemType or "Item", fInfo.itemSubType or "",
               fInfo.stack or 1, fInfo.equipLoc or "", iconTex, 0, fInfo.classID, fInfo.subclassID, fInfo.bonding or 0, nil, nil, (fInfo.classID == 7)
    end

    return nil
end

-- Async Server Item Response Receiver (Only active while the database scanner is explicitly running)
local AsyncItemReceiver = CreateFrame("Frame")
if ns.Compat and ns.Compat.SafeRegisterEvent then
    ns.Compat.SafeRegisterEvent(AsyncItemReceiver, "GET_ITEM_INFO_RECEIVED")
    ns.Compat.SafeRegisterEvent(AsyncItemReceiver, "ITEM_DATA_LOAD_RESULT")
else
    pcall(AsyncItemReceiver.RegisterEvent, AsyncItemReceiver, "GET_ITEM_INFO_RECEIVED")
    pcall(AsyncItemReceiver.RegisterEvent, AsyncItemReceiver, "ITEM_DATA_LOAD_RESULT")
end

AsyncItemReceiver:SetScript("OnEvent", function(_, event, arg1, arg2)
    if not AltVaultDB then return end
    local itemID = tonumber(arg1)
    if itemID and itemID > 0 and (arg2 == nil or arg2 == true) then
        local isSeenInWorld = (AltVaultDB.SourceDB and AltVaultDB.SourceDB[itemID] ~= nil)
            or (ns.MasterDB and ns.MasterDB.ByItemID and ns.MasterDB.ByItemID[itemID] ~= nil)
        if (itemID <= 24500) or (itemID >= 180000 and itemID <= 500000) or isSeenInWorld then
            Scanner.CacheItemData(itemID, true)
        end
    end
end)

local function FetchItemInfo(item)
    return Scanner.CacheItemData(item, false)
end

local function FetchDetailedILvl(item)
    if not item then return nil end
    if C_Item and C_Item.GetDetailedItemLevelInfo then
        local ilvl = C_Item.GetDetailedItemLevelInfo(item)
        if ilvl and ilvl > 0 then return ilvl end
    elseif GetDetailedItemLevelInfo then
        local ilvl = GetDetailedItemLevelInfo(item)
        if ilvl and ilvl > 0 then return ilvl end
    end
    local _, _, _, iLvl = FetchItemInfo(item)
    return iLvl
end

Scanner.FetchItemInfo = FetchItemInfo
Scanner.FetchDetailedILvl = FetchDetailedILvl

-- ============================================================================
-- BLOCK HEADING: GEARSCORE CALCULATION ENGINE
-- ============================================================================
function Scanner.CalculateItemGearScore(itemLinkOrID, fallbackSlotID)
    if not itemLinkOrID then return 0, 0 end

    if C_Item and C_Item.RequestLoadItemDataByID then
        local id = ExtractItemID(itemLinkOrID)
        if id then pcall(C_Item.RequestLoadItemDataByID, id) end
    end

    local _, _, itemQuality, baseILvl, _, _, _, _, itemEquipLoc = FetchItemInfo(itemLinkOrID)

    if (not itemEquipLoc or not EQUIP_LOC_TO_SLOTS[itemEquipLoc]) and not fallbackSlotID then
        return 0, 0
    end

    local iLvl = FetchDetailedILvl(itemLinkOrID) or baseILvl

    if not iLvl or iLvl == 0 then
        local linkStr = tostring(itemLinkOrID)
        if linkStr:find("ff8000") then itemQuality = 5; iLvl = 80
        elseif linkStr:find("a335ee") then itemQuality = 4; iLvl = 66
        elseif linkStr:find("0070dd") then itemQuality = 3; iLvl = 55
        elseif linkStr:find("1eff00") then itemQuality = 2; iLvl = 40
        else itemQuality = 1; iLvl = 20 end
    end

    local slotWeight = (itemEquipLoc and SLOT_WEIGHTS[itemEquipLoc]) or 0.75
    if fallbackSlotID == 16 and (not itemEquipLoc or not EQUIP_LOC_TO_SLOTS[itemEquipLoc]) then
        slotWeight = 1.25
    end
    local qualMult = QUALITY_MULTIPLIERS[itemQuality or 2] or 1.0

    local gs = math.floor((iLvl * 1.85) * slotWeight * qualMult + 0.5)
    return gs, iLvl
end

function Scanner.CalculateCharacterGearScore(gearTable)
    if not gearTable then return 0, 0 end
    local totalGS = 0
    local equippedCount = 0
    local totalILvl = 0

    for slotID = 1, 18 do
        if slotID ~= 4 then
            local link = gearTable[slotID]
            if link then
                local gs, iLvl = Scanner.CalculateItemGearScore(link, slotID)
                totalGS = totalGS + (gs or 0)
                if iLvl and iLvl > 0 then
                    totalILvl = totalILvl + iLvl
                    equippedCount = equippedCount + 1
                end
            end
        end
    end

    local avgILvl = (equippedCount > 0) and math.floor((totalILvl / equippedCount) + 0.5) or 0
    return totalGS, avgILvl
end

function Scanner.FormatGearScoreColor(gs)
    if not gs or gs <= 0 then return "|cff8888880|r" end
    if gs >= 1500 then return "|cffff8000" .. gs .. "|r"
    elseif gs >= 1000 then return "|cffa335ee" .. gs .. "|r"
    elseif gs >= 600 then return "|cff0070dd" .. gs .. "|r"
    elseif gs >= 300 then return "|cff1eff00" .. gs .. "|r"
    else return "|cffffffff" .. gs .. "|r" end
end

-- ============================================================================
-- BLOCK HEADING: CLASS, TALENT SPEC & ARMOR/WEAPON SUITABILITY CHECKER
-- ============================================================================
local function CheckTalentRoleStatMatch(altData, itemLinkOrID)
    local role = altData.specRole or "MELEE_STR"

    local itemID = ExtractItemID(itemLinkOrID)
    local cachedEntry = itemID and AltVaultDB and AltVaultDB.ItemCache and AltVaultDB.ItemCache[itemID]
    local cachedRole = cachedEntry and cachedEntry.ro
    if cachedRole and cachedRole ~= "ANY" then
        if role == "MELEE_STR" and (cachedRole == "CASTER_DPS" or cachedRole == "HEALER") then return false end
        if role == "MELEE_AGI" and (cachedRole == "CASTER_DPS" or cachedRole == "HEALER" or cachedRole == "TANK") then return false end
        if (role == "CASTER_DPS" or role == "HEALER") and (cachedRole == "MELEE_STR" or cachedRole == "MELEE_AGI" or cachedRole == "TANK") then return false end
        if role == "TANK" and (cachedRole == "CASTER_DPS" or cachedRole == "HEALER") then return false end
    end

    local stats = FetchItemStatsTable(itemLinkOrID)
    if stats then
        local hasSpell = (stats["ITEM_MOD_SPELL_POWER_SHORT"] or stats["ITEM_MOD_SPELL_DAMAGE_DONE_SHORT"] or stats["ITEM_MOD_SPELL_HEALING_DONE_SHORT"] or 0) > 0
        local hasInt   = (stats["ITEM_MOD_INTELLECT_SHORT"] or 0) > 0
        local hasStr   = (stats["ITEM_MOD_STRENGTH_SHORT"] or 0) > 0
        local hasAgi   = (stats["ITEM_MOD_AGILITY_SHORT"] or 0) > 0
        local hasAP    = (stats["ITEM_MOD_ATTACK_POWER_SHORT"] or stats["ITEM_MOD_RANGED_ATTACK_POWER_SHORT"] or 0) > 0
        local hasDef   = (stats["ITEM_MOD_DEFENSE_SKILL_RATING_SHORT"] or stats["ITEM_MOD_BLOCK_RATING_SHORT"] or stats["ITEM_MOD_PARRY_RATING_SHORT"] or 0) > 0

        if role == "MELEE_STR" then
            if hasSpell or (hasInt and not hasStr and not hasAP) then return false end
        elseif role == "MELEE_AGI" then
            if hasSpell or hasDef or (hasInt and not hasAgi and not hasAP) then return false end
        elseif role == "CASTER_DPS" or role == "HEALER" then
            if hasStr or hasAP or hasDef or (hasAgi and not hasInt and not hasSpell) then return false end
        elseif role == "TANK" then
            if hasSpell and not hasStr and not hasAgi and not hasDef then return false end
        end
    end

    return true
end

function Scanner.CanAltUseAndWantItem(altData, itemLinkOrID)
    if not altData then return false end
    local _, _, _, _, itemMinLevel, itemType, itemSubType, _, itemEquipLoc = FetchItemInfo(itemLinkOrID)

    if not itemEquipLoc or not EQUIP_LOC_TO_SLOTS[itemEquipLoc] then return false end

    local targetSlots = EQUIP_LOC_TO_SLOTS[itemEquipLoc]
    if not targetSlots then return false end

    local classInfo = CLASS_IDEAL_ARMOR[altData.class or "WARRIOR"]
    if not classInfo then return false end

    if not CheckTalentRoleStatMatch(altData, itemLinkOrID) then
        return false
    end

    if itemType == "Armor" then
        if itemEquipLoc == "INVTYPE_CLOAK" or itemEquipLoc == "INVTYPE_NECK" or itemEquipLoc == "INVTYPE_FINGER" or itemEquipLoc == "INVTYPE_TRINKET" or itemEquipLoc == "INVTYPE_HOLDABLE" then
            if itemEquipLoc == "INVTYPE_HOLDABLE" and (altData.class == "WARRIOR" or altData.class == "ROGUE" or altData.class == "HUNTER" or altData.class == "DEATHKNIGHT") then
                return false
            end
        elseif itemEquipLoc == "INVTYPE_SHIELD" or itemSubType == "Shields" then
            if not classInfo.canShield then return false end
        elseif itemSubType and (itemSubType == "Cloth" or itemSubType == "Leather" or itemSubType == "Mail" or itemSubType == "Plate") then
            local effectiveCheckLvl = math.max(altData.level or 60, itemMinLevel or 1)
            local expectedArmor = (effectiveCheckLvl >= 40) and classInfo.high or classInfo.low
            if itemSubType ~= expectedArmor then
                return false
            end
        end
    elseif itemType == "Weapon" then
        local allowedWeps = CLASS_WEAPONS[altData.class or "WARRIOR"]
        if allowedWeps and itemSubType and not allowedWeps[itemSubType] then
            return false
        end
    end

    return true, targetSlots, (itemMinLevel or 1), itemEquipLoc
end

function Scanner.CheckItemUpgradeForAlt(altName, itemLinkOrID)
    local charTable = AltVaultDB and AltVaultDB.Characters
    if not charTable or not charTable[altName] or not itemLinkOrID then return false end

    local altData = charTable[altName]
    local isSuited, targetSlots, reqLvl, incomingEquipLoc = Scanner.CanAltUseAndWantItem(altData, itemLinkOrID)
    if not isSuited or not targetSlots then return false end

    local altLvl = altData.level or 60
    local maxCap = _G.MAX_PLAYER_LEVEL or 60
    local lvlDiff = reqLvl - altLvl

    if lvlDiff > 4 then return false end

    local incomingGS = Scanner.CalculateItemGearScore(itemLinkOrID)
    if not incomingGS or incomingGS <= 0 then return false end

    local mainLink = altData.gear and altData.gear[16]
    local _, _, _, _, _, _, _, _, mainEquipLoc = FetchItemInfo(mainLink)
    local has2HEquipped = (mainEquipLoc == "INVTYPE_2HWEAPON")

    local bestDelta = 0

    if incomingEquipLoc == "INVTYPE_2HWEAPON" then
        local mainGS = mainLink and Scanner.CalculateItemGearScore(mainLink, 16) or 0
        local offLink = altData.gear and altData.gear[17]
        local offGS = offLink and Scanner.CalculateItemGearScore(offLink, 17) or 0
        local combinedEquippedGS = mainGS + offGS
        if incomingGS > combinedEquippedGS then
            bestDelta = incomingGS - combinedEquippedGS
        end
    else
        for _, slotID in ipairs(targetSlots) do
            if (slotID == 16 or slotID == 17) and has2HEquipped then
                local main2HGS = Scanner.CalculateItemGearScore(mainLink, 16) or 0
                local singleHandBaseline = math.floor((main2HGS * 0.5) + 0.5)
                if incomingGS > singleHandBaseline then
                    bestDelta = math.max(bestDelta, incomingGS - singleHandBaseline)
                end
            else
                local currentEquippedLink = altData.gear and altData.gear[slotID]
                if not currentEquippedLink then
                    bestDelta = math.max(bestDelta, incomingGS)
                else
                    local currentGS = Scanner.CalculateItemGearScore(currentEquippedLink, slotID)
                    if currentGS and incomingGS > currentGS then
                        bestDelta = math.max(bestDelta, incomingGS - currentGS)
                    end
                end
            end
        end
    end

    if bestDelta > 0 then
        local isNextLevelPulse = (lvlDiff >= 1 and lvlDiff <= 4) or ((altData.xpPercent or 0) >= 70 and altLvl < maxCap)
        local statusType = isNextLevelPulse and "UPGRADE_SOON" or "UPGRADE"
        return true, bestDelta, statusType, reqLvl
    end
    return false
end