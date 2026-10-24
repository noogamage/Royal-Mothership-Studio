-- ============================================================================
-- FILE: Engine_Professions.lua (MODULE 2 OF 3 SPLIT FROM Engine_Scanner.lua)
-- BLOCK HEADING: MULTI-PROFESSION REAGENT & SUPPLY TABLES (SKILL 1-600)
-- ============================================================================
local addonName, ns = ...
local Scanner = ns.Scanner or {}
ns.Scanner = Scanner

local EQUIP_LOC_TO_SLOTS = Scanner.EQUIP_LOC_TO_SLOTS
local ExtractItemID = Scanner.ExtractItemID
local FetchItemInfo = Scanner.FetchItemInfo
local ScanAndCachePatternDetails = Scanner.ScanAndCachePatternDetails
local ExtractCraftedNameFromPattern = Scanner.ExtractCraftedNameFromPattern

local MATERIAL_TO_PROFESSIONS = {
    ["Herb"]            = { "Alchemy", "Inscription" },
    ["Metal & Stone"]   = { "Blacksmithing", "Engineering", "Jewelcrafting" },
    ["Leather"]         = { "Leatherworking", "Blacksmithing", "Engineering", "Tailoring", "Camping" },
    ["Cloth"]           = { "Tailoring", "First Aid", "Camping" },
    ["Enchanting"]      = { "Enchanting" },
    ["Jewelcrafting"]   = { "Jewelcrafting", "Blacksmithing", "Engineering", "Tailoring", "Leatherworking" },
    ["Parts"]           = { "Engineering" },
    ["Devices"]         = { "Engineering" },
    ["Explosives"]      = { "Engineering" },
    ["Elemental"]       = { "Alchemy", "Blacksmithing", "Enchanting", "Engineering", "Jewelcrafting", "Leatherworking", "Tailoring" },
    ["Cooking"]         = { "Cooking", "Camping" },
    ["Meat"]            = { "Cooking", "Camping" },
    ["Inscription"]     = { "Inscription" },
}

local TRADE_GOODS_SUBCLASS_MAP = {
    [1]  = { "Engineering" },
    [2]  = { "Engineering" },
    [3]  = { "Engineering" },
    [4]  = { "Jewelcrafting", "Blacksmithing", "Engineering", "Tailoring", "Leatherworking" },
    [5]  = { "Tailoring", "First Aid", "Camping" },
    [6]  = { "Leatherworking", "Blacksmithing", "Engineering", "Tailoring", "Camping" },
    [7]  = { "Blacksmithing", "Engineering", "Jewelcrafting" },
    [8]  = { "Cooking", "Camping" },
    [9]  = { "Alchemy", "Inscription" },
    [10] = { "Alchemy", "Blacksmithing", "Enchanting", "Engineering", "Jewelcrafting", "Leatherworking", "Tailoring" },
    [12] = { "Enchanting" },
    [16] = { "Inscription" },
}

local NON_CONSUMING_GATHER_PROFS = {
    ["Fishing"]     = true,
    ["Herbalism"]   = true,
    ["Skinning"]    = true,
    ["Archaeology"] = true,
}

local PROF_SORT_PRIORITY = {
    ["Tailoring"]      = 10,
    ["Leatherworking"] = 10,
    ["Blacksmithing"]  = 10,
    ["Alchemy"]        = 10,
    ["Engineering"]    = 10,
    ["Enchanting"]     = 10,
    ["Jewelcrafting"]  = 10,
    ["Inscription"]    = 10,
    ["Cooking"]        = 9,
    ["Camping"]        = 8,
    ["First Aid"]      = 8,
    ["Mining"]         = 7,
}

Scanner.NON_CONSUMING_GATHER_PROFS = NON_CONSUMING_GATHER_PROFS

local RAW_CLOTHS = {
    ["linen cloth"]       = { min = 1,   max = 85,  profs = { "Tailoring", "First Aid", "Camping", "Engineering" } },
    ["wool cloth"]        = { min = 50,  max = 150, profs = { "Tailoring", "First Aid", "Camping", "Engineering", "Leatherworking" } },
    ["silk cloth"]        = { min = 125, max = 215, profs = { "Tailoring", "First Aid", "Camping", "Engineering", "Leatherworking" } },
    ["mageweave cloth"]   = { min = 175, max = 260, profs = { "Tailoring", "First Aid", "Camping", "Engineering", "Leatherworking" } },
    ["runecloth"]         = { min = 225, max = 300, profs = { "Tailoring", "First Aid", "Camping", "Engineering", "Leatherworking" } },
    ["netherweave cloth"] = { min = 275, max = 360, profs = { "Tailoring", "First Aid", "Engineering", "Leatherworking" } },
    ["frostweave cloth"]  = { min = 350, max = 450, profs = { "Tailoring", "First Aid", "Engineering", "Leatherworking" } },
    ["embersilk cloth"]   = { min = 425, max = 525, profs = { "Tailoring", "First Aid", "Engineering", "Leatherworking" } },
    ["windwool cloth"]    = { min = 500, max = 600, profs = { "Tailoring", "First Aid", "Engineering", "Leatherworking" } },
}

local THREAD_SKILL_BRACKETS = {
    ["coarse thread"]       = { min = 1,   max = 110 },
    ["fine thread"]         = { min = 75,  max = 185 },
    ["silken thread"]       = { min = 145, max = 240 },
    ["heavy silken thread"] = { min = 215, max = 285 },
    ["rune thread"]         = { min = 250, max = 375 },
    ["eternium thread"]     = { min = 350, max = 600 },
}

local DYE_SKILL_BRACKETS = {
    ["red dye"]    = { min = 25,  max = 150, profs = { "Tailoring", "Leatherworking" } },
    ["blue dye"]   = { min = 25,  max = 150, profs = { "Tailoring", "Leatherworking" } },
    ["green dye"]  = { min = 50,  max = 175, profs = { "Tailoring", "Leatherworking" } },
    ["gray dye"]   = { min = 75,  max = 200, profs = { "Tailoring", "Leatherworking" } },
    ["yellow dye"] = { min = 75,  max = 200, profs = { "Tailoring", "Leatherworking" } },
    ["purple dye"] = { min = 120, max = 240, profs = { "Tailoring", "Leatherworking" } },
    ["orange dye"] = { min = 120, max = 240, profs = { "Tailoring", "Leatherworking" } },
    ["pink dye"]   = { min = 140, max = 250, profs = { "Tailoring", "Leatherworking" } },
    ["black dye"]  = { min = 150, max = 275, profs = { "Tailoring", "Leatherworking" } },
    ["ghost dye"]  = { min = 225, max = 300, profs = { "Tailoring", "Leatherworking" } },
    ["bleach"]     = { min = 25,  max = 150, profs = { "Tailoring" } },
}

local COOKING_SUPPLY_BRACKETS = {
    ["mild spices"]     = { min = 1,   max = 125 },
    ["hot spices"]      = { min = 100, max = 225 },
    ["soothing spices"] = { min = 175, max = 300 },
    ["holiday spices"]  = { min = 1,   max = 300 },
    ["simple flour"]    = { min = 1,   max = 100 },
    ["northern spices"] = { min = 350, max = 450 },
}

-- ============================================================================
-- BLOCK HEADING: MULTI-PROFESSION SERVER REAGENT & SUPPLY CLASSIFIER
-- ============================================================================
local function ResolveCandidateProfessionsForMaterial(itemID, itemName, classID, subClassID, itemSubType)
    local nameLower = itemName and string.lower(itemName) or ""
    if nameLower == "" then return nil end

    if string.find(nameLower, "bandage", 1, true) then
        return nil
    end

    local baseList = nil
    local customMin, customMax = nil, nil
    local isStrictFamily = false

    if COOKING_SUPPLY_BRACKETS[nameLower] then
        local b = COOKING_SUPPLY_BRACKETS[nameLower]
        baseList = { "Cooking", "Camping" }
        customMin, customMax = b.min, b.max
        isStrictFamily = true
    elseif string.find(nameLower, " spices$") then
        baseList = { "Cooking", "Camping" }
        isStrictFamily = true

    elseif DYE_SKILL_BRACKETS[nameLower] then
        local d = DYE_SKILL_BRACKETS[nameLower]
        baseList = d.profs
        customMin, customMax = d.min, d.max
        isStrictFamily = true
    elseif string.find(nameLower, " dye$") then
        baseList = { "Tailoring", "Leatherworking" }
        isStrictFamily = true

    elseif string.find(nameLower, "^bolt of ") then
        baseList = { "Tailoring", "Leatherworking", "Engineering", "Camping" }
        isStrictFamily = true

    elseif string.find(nameLower, "spider's silk", 1, true)
        or string.find(nameLower, "spider silk", 1, true)
        or nameLower == "shadow silk"
        or nameLower == "felcloth"
        or nameLower == "mooncloth"
        or nameLower == "imperial silk" then
        baseList = { "Tailoring", "Leatherworking", "Engineering" }
        isStrictFamily = true

    elseif THREAD_SKILL_BRACKETS[nameLower] or string.find(nameLower, " thread$") then
        local b = THREAD_SKILL_BRACKETS[nameLower]
        baseList = { "Tailoring", "Leatherworking" }
        if b then customMin, customMax = b.min, b.max end
        isStrictFamily = true

    elseif RAW_CLOTHS[nameLower] then
        local c = RAW_CLOTHS[nameLower]
        baseList = c.profs
        customMin, customMax = c.min, c.max
        isStrictFamily = true

    elseif string.find(nameLower, "oily blackmouth", 1, true)
        or string.find(nameLower, "firefin snapper", 1, true)
        or string.find(nameLower, "stonescale eel", 1, true)
        or string.find(nameLower, "stranglekelp", 1, true)
        or nameLower == "empty vial"
        or nameLower == "leaded vial"
        or nameLower == "crystal vial"
        or nameLower == "imbued vial"
        or nameLower == "enchanted vial"
        or string.find(nameLower, " lotus$") then
        baseList = { "Alchemy" }
        isStrictFamily = true

    elseif string.find(nameLower, "venom sac", 1, true) then
        baseList = { "First Aid", "Alchemy" }
        isStrictFamily = true

    elseif subClassID == 8 or itemSubType == "Cooking" or itemSubType == "Meat"
        or string.find(nameLower, " meat")
        or string.find(nameLower, "^raw ")
        or string.find(nameLower, " rib")
        or string.find(nameLower, " flanks")
        or string.find(nameLower, " tenderloin")
        or string.find(nameLower, " drumstick")
        or string.find(nameLower, "crawler claw")
        or string.find(nameLower, "crawler flesh")
        or string.find(nameLower, "clam meat")
        or string.find(nameLower, " small egg")
        or string.find(nameLower, "giant egg")
        or string.find(nameLower, "murloc eye")
        or string.find(nameLower, "murloc fin")
        or string.find(nameLower, "goretusk")
        or string.find(nameLower, "buzzard wing")
        or string.find(nameLower, "strider meat")
        or string.find(nameLower, "coyote meat")
        or string.find(nameLower, "bear meat")
        or string.find(nameLower, "lion meat")
        or string.find(nameLower, "raptorflesh")
        or string.find(nameLower, "raptor flesh")
        or string.find(nameLower, "mystery meat")
        or string.find(nameLower, "tiger meat")
        or string.find(nameLower, "stag meat")
        or string.find(nameLower, "turtle meat")
        or string.find(nameLower, "crocolisk meat")
        or string.find(nameLower, "kodo meat")
        or string.find(nameLower, "scorpid stinger")
        or string.find(nameLower, "steak$")
        or string.find(nameLower, "breast$") then
        baseList = { "Cooking", "Camping" }
        isStrictFamily = true

    elseif string.find(nameLower, " leather$")
        or string.find(nameLower, " hide$")
        or string.find(nameLower, " scale$")
        or string.find(nameLower, " scales$") then
        baseList = { "Leatherworking", "Blacksmithing", "Engineering", "Tailoring", "Camping" }

    elseif nameLower == "salt"
        or nameLower == "refined deeprock salt"
        or nameLower == "deeprock salt" then
        baseList = { "Leatherworking" }
        isStrictFamily = true

    elseif string.find(nameLower, " ore$") or nameLower == "kyparite" then
        baseList = { "Mining", "Blacksmithing", "Engineering", "Jewelcrafting" }

    elseif string.find(nameLower, " stone$") and not string.find(nameLower, "sharpening") and not string.find(nameLower, "weightstone") then
        baseList = { "Engineering", "Blacksmithing", "Jewelcrafting", "Mining" }

    elseif string.find(nameLower, " bar$")
        or string.find(nameLower, "grinding stone") then
        baseList = { "Blacksmithing", "Engineering", "Jewelcrafting" }

    elseif string.find(nameLower, " flux$") or nameLower == "coal" then
        baseList = { "Blacksmithing", "Engineering" }

    elseif string.find(nameLower, "blasting powder")
        or string.find(nameLower, "handful of ")
        or string.find(nameLower, " tube$")
        or string.find(nameLower, " modulator")
        or string.find(nameLower, " widget")
        or string.find(nameLower, " casing")
        or string.find(nameLower, " framework") then
        baseList = { "Engineering" }

    elseif subClassID == 12 or itemSubType == "Enchanting"
        or string.find(nameLower, " dust$")
        or string.find(nameLower, " essence$")
        or string.find(nameLower, " shard$")
        or string.find(nameLower, " crystal$") then
        baseList = { "Enchanting" }

    elseif string.find(nameLower, " pigment$") or string.find(nameLower, " ink$") or string.find(nameLower, "parchment") then
        baseList = { "Inscription" }

    elseif subClassID == 9 or itemSubType == "Herb" then
        baseList = { "Alchemy", "Inscription" }

    elseif string.find(nameLower, " pearl$")
        or nameLower == "malachite"
        or nameLower == "tigerseye"
        or nameLower == "shadowgem"
        or nameLower == "moss agate"
        or nameLower == "lesser moonstone"
        or nameLower == "jade"
        or nameLower == "citrine"
        or nameLower == "aquamarine"
        or nameLower == "star ruby"
        or nameLower == "blue sapphire"
        or nameLower == "large opal"
        or nameLower == "huge emerald"
        or nameLower == "azerothian diamond" then
        baseList = { "Blacksmithing", "Engineering", "Jewelcrafting", "Tailoring", "Leatherworking" }

    elseif classID == 7 and subClassID and subClassID > 0 and TRADE_GOODS_SUBCLASS_MAP[subClassID] then
        baseList = TRADE_GOODS_SUBCLASS_MAP[subClassID]
    elseif itemSubType and MATERIAL_TO_PROFESSIONS[itemSubType] then
        baseList = MATERIAL_TO_PROFESSIONS[itemSubType]
    end

    local combined = {}
    local seen = {}

    if baseList then
        for _, p in ipairs(baseList) do
            if not NON_CONSUMING_GATHER_PROFS[p] and not seen[p] then
                seen[p] = true
                table.insert(combined, p)
            end
        end
    end

    if not isStrictFamily and AltVaultDB and AltVaultDB.ReagentDB then
        local dbEntry = (itemID and AltVaultDB.ReagentDB[itemID]) or (itemName and AltVaultDB.ReagentDB[itemName])
        if dbEntry and type(dbEntry.profs) == "table" then
            for pName in pairs(dbEntry.profs) do
                if not NON_CONSUMING_GATHER_PROFS[pName] and not seen[pName] then
                    seen[pName] = true
                    table.insert(combined, pName)
                end
            end
        end
    end

    if #combined == 0 then return nil end
    return combined, customMin, customMax, isStrictFamily
end

function Scanner.GetMaterialProfessionsList(itemLinkOrID)
    if not itemLinkOrID then return nil end
    local itemName, _, _, _, itemMinLevel, itemType, itemSubType, _, itemEquipLoc, _, _, classID, subClassID, _, _, _, isCraftingReagent = FetchItemInfo(itemLinkOrID)
    if not itemName then return nil end
    if itemEquipLoc and (EQUIP_LOC_TO_SLOTS[itemEquipLoc] ~= nil or itemEquipLoc == "INVTYPE_BAG") then
        return nil
    end

    local id = ExtractItemID(itemLinkOrID)
    if classID == 9 or itemType == "Recipe" then
        local patData = ScanAndCachePatternDetails(id, itemLinkOrID, itemName, itemSubType, itemMinLevel)
        local targetProf = (patData and patData.p) or itemSubType
        if targetProf and targetProf ~= "" then
            return { targetProf }
        end
        return nil
    end

    if classID == 0 or itemType == "Consumable" or itemType == "Container" then
        return nil
    end

    local isServerVerifiedReagent = (classID == 7)
        or (itemType == "Trade Goods")
        or (itemType == "Tradeskill")
        or (isCraftingReagent == true)
    if not isServerVerifiedReagent then
        return nil
    end

    local resolvedProfs = ResolveCandidateProfessionsForMaterial(id, itemName, classID, subClassID, itemSubType)
    return resolvedProfs
end

-- ============================================================================
-- BLOCK HEADING: MULTI-PROFESSION PATTERN & REAGENT ENGINE (ALL 16 PROFS)
-- ============================================================================
local function GetCharacterProfessionList(altData)
    local list = {}
    local seen = {}
    if not altData or not altData.professions then return list end

    local function AddProf(p)
        if p and p.name and not seen[p.name] then
            seen[p.name] = true
            table.insert(list, p)
        end
    end

    AddProf(altData.professions.primary1)
    AddProf(altData.professions.primary2)
    if type(altData.professions.all) == "table" then
        for _, p in ipairs(altData.professions.all) do
            AddProf(p)
        end
    end
    return list
end

local function EvaluateBracketForProf(profObj, minSkill, maxSkill, customLabel)
    local rank = profObj.rank or 1
    if rank >= (minSkill - 35) and rank < minSkill then
        local ptsNeeded = minSkill - rank
        return "PROF_SOON", string.format("Next Tier at %d (%d pts away!)", minSkill, ptsNeeded), rank
    elseif rank >= minSkill and rank < maxSkill then
        return "PROF_SOON", customLabel or string.format("Active Skill-Up Bracket (%d-%d)", minSkill, maxSkill), rank
    elseif rank < (minSkill - 35) then
        return "PROF_MAT", string.format("Future Tier (Unlocks at %d Skill)", minSkill), rank
    else
        return "PROF_MAT", (minSkill >= 245) and "Endgame Crafting Mat" or "Crafting Material", rank
    end
end

function Scanner.IsMaterialNeededForAlt(altName, itemLinkOrID)
    local charTable = AltVaultDB and AltVaultDB.Characters
    if not charTable or not charTable[altName] or not itemLinkOrID then return false end

    local altData = charTable[altName]
    local profList = GetCharacterProfessionList(altData)
    if #profList == 0 then return false end

    local itemName, _, _, baseILvl, itemMinLevel, itemType, itemSubType, _, itemEquipLoc, _, _, classID, subClassID, _, _, _, isCraftingReagent = FetchItemInfo(itemLinkOrID)

    if itemEquipLoc and (EQUIP_LOC_TO_SLOTS[itemEquipLoc] ~= nil or itemEquipLoc == "INVTYPE_BAG") then
        return false
    end

    local id = ExtractItemID(itemLinkOrID)

    local charProfByName = {}
    for _, profObj in ipairs(profList) do
        if profObj and profObj.name and not NON_CONSUMING_GATHER_PROFS[profObj.name] then
            charProfByName[profObj.name] = profObj
        end
    end

    -- 1. Check Profession Patterns, Plans, Schematics, Formulas & Recipes
    if classID == 9 or itemType == "Recipe" then
        local patData = ScanAndCachePatternDetails(id, itemLinkOrID, itemName, itemSubType, itemMinLevel)
        local targetProf = (patData and patData.p) or itemSubType
        local craftedName = (patData and patData.cn) or ExtractCraftedNameFromPattern(itemName)

        if targetProf and charProfByName[targetProf] then
            local profObj = charProfByName[targetProf]
            if craftedName and altData.knownRecipes and altData.knownRecipes[craftedName] then
                return false
            end

            local rank = profObj.rank or 1
            local learnedReq = AltVaultDB and AltVaultDB.LearnedProgression
                and AltVaultDB.LearnedProgression[profObj.name]
                and craftedName and AltVaultDB.LearnedProgression[profObj.name][craftedName]
            local reqSkill = (patData and patData.s) or learnedReq or ((itemMinLevel and itemMinLevel > 1) and (itemMinLevel * 5) or 150)

            local status, note
            if rank >= reqSkill then
                status = "PROF_SOON"
                note = string.format("Unlearned Pattern - Can Learn Now! (Req %d)", reqSkill)
            elseif rank >= (reqSkill - 40) then
                status = "PROF_SOON"
                note = string.format("Next-Tier Pattern (Req %d, %d pts away)", reqSkill, reqSkill - rank)
            else
                status = "PROF_MAT"
                note = string.format("Future Pattern (Req %d Skill)", reqSkill)
            end
            local singleMatch = { { prof = profObj.name, status = status, note = note, rank = rank } }
            return true, profObj.name, status, note, rank, singleMatch
        end
        return false
    end

    -- 2. STRICT SERVER GATEKEEPER AT THE TOP:
    if classID == 0 or itemType == "Consumable" or itemType == "Container" then
        if AltVaultDB and AltVaultDB.ReagentDB then
            if id then AltVaultDB.ReagentDB[id] = nil end
            if itemName then AltVaultDB.ReagentDB[itemName] = nil end
        end
        if altData.neededReagents then
            if id then altData.neededReagents[id] = nil end
            if itemName then altData.neededReagents[itemName] = nil end
        end
        return false
    end

    local isServerVerifiedReagent = (classID == 7)
        or (itemType == "Trade Goods")
        or (itemType == "Tradeskill")
        or (isCraftingReagent == true)

    if not isServerVerifiedReagent then
        return false
    end

    -- 3. Resolve ALL candidate professions for this material
    local resolvedProfs, customMinSkill, customMaxSkill = ResolveCandidateProfessionsForMaterial(id, itemName, classID, subClassID, itemSubType)
    if not resolvedProfs or #resolvedProfs == 0 then
        return false
    end

    local effectiveILvl = (baseILvl and baseILvl > 0) and baseILvl or ((itemMinLevel and itemMinLevel > 0) and itemMinLevel or 10)
    local defaultMinSkill = customMinSkill or ((effectiveILvl <= 12) and 1 or math.max(1, math.min(525, (effectiveILvl - 5) * 5)))
    local defaultMaxSkill = customMaxSkill or math.min(600, defaultMinSkill + 75)

    local dbEntry = AltVaultDB and AltVaultDB.ReagentDB and ((id and AltVaultDB.ReagentDB[id]) or (itemName and AltVaultDB.ReagentDB[itemName]))
    local activeNeed = altData.neededReagents and ((id and altData.neededReagents[id]) or (itemName and altData.neededReagents[itemName]))

    local allCharMatches = {}

    for _, profName in ipairs(resolvedProfs) do
        local profObj = charProfByName[profName]
        if profObj then
            local status, note, rank

            if type(activeNeed) == "table" and activeNeed.prof == profName then
                status = "PROF_SOON"
                note = "Active Skill-Up Recipe: " .. (activeNeed.recipe or "Craft")
                rank = profObj.rank or 1
            elseif dbEntry and type(dbEntry.profs) == "table" and dbEntry.profs[profName] then
                local lb = dbEntry.profs[profName]
                status, note, rank = EvaluateBracketForProf(
                    profObj,
                    lb.min or defaultMinSkill,
                    lb.max or defaultMaxSkill,
                    lb.sampleRecipe and ("Recipe Mat: " .. lb.sampleRecipe) or nil
                )
            else
                status, note, rank = EvaluateBracketForProf(profObj, defaultMinSkill, defaultMaxSkill, nil)
            end

            table.insert(allCharMatches, {
                prof   = profName,
                status = status,
                note   = note,
                rank   = rank or (profObj.rank or 1),
                prio   = PROF_SORT_PRIORITY[profName] or 1
            })
        end
    end

    if #allCharMatches == 0 then
        return false
    end

    table.sort(allCharMatches, function(a, b)
        if (a.status == "PROF_SOON") ~= (b.status == "PROF_SOON") then
            return a.status == "PROF_SOON"
        end
        if (a.prio or 1) ~= (b.prio or 1) then
            return (a.prio or 1) > (b.prio or 1)
        end
        return (a.rank or 0) > (b.rank or 0)
    end)

    local top = allCharMatches[1]
    return true, top.prof, top.status, top.note, top.rank, allCharMatches
end

-- ============================================================================
-- BLOCK HEADING: ROSTER-WIDE PROGRESSION EVALUATOR (MULTI-PROFESSION AWARE)
-- ============================================================================
function Scanner.EvaluateItemForRoster(itemLinkOrID, factionFilter)
    local charTable = AltVaultDB and AltVaultDB.Characters
    if not charTable or not itemLinkOrID then return nil, nil, false end

    local activePlayer = UnitName("player")
    local upgradeMatches = {}
    local profMatches = {}
    local shouldPulse = false

    for altName, altData in pairs(charTable) do
        if not factionFilter or altData.faction == factionFilter then
            local isUpg, deltaGS, upgStatus, reqLvl = Scanner.CheckItemUpgradeForAlt(altName, itemLinkOrID)
            if isUpg then
                if upgStatus == "UPGRADE_SOON" then shouldPulse = true end
                table.insert(upgradeMatches, {
                    name = altName,
                    isOtherAlt = (altName ~= activePlayer),
                    class = altData.class,
                    spec = altData.specName or altData.class,
                    level = altData.level or 60,
                    xpPct = altData.xpPercent or 0,
                    delta = deltaGS,
                    status = upgStatus,
                    reqLvl = reqLvl
                })
            end

            local isMat, _, _, _, _, allCharMatches = Scanner.IsMaterialNeededForAlt(altName, itemLinkOrID)
            if isMat and type(allCharMatches) == "table" then
                for _, m in ipairs(allCharMatches) do
                    if m.status == "PROF_SOON" then shouldPulse = true end
                    table.insert(profMatches, {
                        name = altName,
                        isOtherAlt = (altName ~= activePlayer),
                        prof = m.prof,
                        prio = m.prio or PROF_SORT_PRIORITY[m.prof] or 1,
                        rank = m.rank or 1,
                        status = m.status,
                        note = m.note
                    })
                end
            end
        end
    end

    table.sort(upgradeMatches, function(a, b)
        if (a.status == "UPGRADE_SOON") ~= (b.status == "UPGRADE_SOON") then
            return a.status == "UPGRADE_SOON"
        end
        if a.isOtherAlt ~= b.isOtherAlt then return a.isOtherAlt end
        return a.delta > b.delta
    end)

    table.sort(profMatches, function(a, b)
        if (a.status == "PROF_SOON") ~= (b.status == "PROF_SOON") then
            return a.status == "PROF_SOON"
        end
        if (a.prio or 1) ~= (b.prio or 1) then
            return (a.prio or 1) > (b.prio or 1)
        end
        if a.isOtherAlt ~= b.isOtherAlt then return a.isOtherAlt end
        return (a.rank or 0) > (b.rank or 0)
    end)

    return upgradeMatches, profMatches, shouldPulse
end