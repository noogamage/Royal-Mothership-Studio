-- ============================================================================
-- FILE: Core_Database.lua (MODULE 4 OF 4 SPLIT FROM Core_Database.lua)
-- BLOCK HEADING: EVENT REGISTRATION & SHARED NAMESPACE REFERENCES
-- ============================================================================
local addonName, ns = ...
ns.Compat = ns.Compat or {}
ns.DB = ns.DB or {}

local SafeRegisterEvent = ns.Compat.SafeRegisterEvent
local ScanTip = ns.DB.ScanTip
local PRIMARY_PROFESSIONS = ns.DB.PRIMARY_PROFESSIONS
local TRACKED_PROFESSIONS = ns.DB.TRACKED_PROFESSIONS
local NON_CONSUMING_GATHER_PROFS = ns.DB.NON_CONSUMING_GATHER_PROFS
local RACE_TO_FACTION = ns.DB.RACE_TO_FACTION
local RACE_FILE_DISPLAY = ns.DB.RACE_FILE_DISPLAY

local InitializeDatabase = ns.DB.InitializeDatabase
local RestoreFromBetaMacro = ns.DB.RestoreFromBetaMacro
local SaveToBetaMacro = ns.DB.SaveToBetaMacro
local ScanTalentsAndXP = ns.DB.ScanTalentsAndXP
local StartSilentBackgroundScanner = ns.DB.StartSilentBackgroundScanner

local EventFrame = CreateFrame("Frame")

SafeRegisterEvent(EventFrame, "ADDON_LOADED")
SafeRegisterEvent(EventFrame, "PLAYER_LOGIN")
SafeRegisterEvent(EventFrame, "TRADE_SKILL_SHOW")
SafeRegisterEvent(EventFrame, "CRAFT_SHOW")
SafeRegisterEvent(EventFrame, "BANKFRAME_OPENED")
SafeRegisterEvent(EventFrame, "GUILDBANKFRAME_OPENED")
SafeRegisterEvent(EventFrame, "MERCHANT_SHOW")
SafeRegisterEvent(EventFrame, "TRAINER_SHOW")
SafeRegisterEvent(EventFrame, "TRAINER_UPDATE")
SafeRegisterEvent(EventFrame, "LOOT_OPENED")
SafeRegisterEvent(EventFrame, "QUEST_DETAIL")
SafeRegisterEvent(EventFrame, "QUEST_COMPLETE")
SafeRegisterEvent(EventFrame, "QUEST_ITEM_UPDATE")
SafeRegisterEvent(EventFrame, "AUCTION_ITEM_LIST_UPDATE")
SafeRegisterEvent(EventFrame, "AUCTION_HOUSE_BROWSE_RESULTS_UPDATED")
SafeRegisterEvent(EventFrame, "AUCTION_HOUSE_BROWSE_RESULTS_ADDED")

-- ============================================================================
-- BLOCK HEADING: ROBUST RACE & FACTION DETECTOR (PANDAREN AWARE)
-- ============================================================================
local function DetectPlayerRaceAndFaction()
    local raceName, raceFile = UnitRace("player")
    if (not raceName or raceName == "") and raceFile then
        raceName = RACE_FILE_DISPLAY[raceFile] or raceFile
    end
    if raceFile and RACE_FILE_DISPLAY[raceFile] then
        raceName = RACE_FILE_DISPLAY[raceFile]
    end
    local factionGroup = UnitFactionGroup("player")
    if (not factionGroup or factionGroup == "" or factionGroup == "Neutral") and raceName then
        factionGroup = RACE_TO_FACTION[raceName] or RACE_TO_FACTION[raceFile or ""]
    end
    return raceName, factionGroup, raceFile
end

-- ============================================================================
-- BLOCK HEADING: SELF-LEARNING GEAR, PATTERN, REAGENT & SOURCE DATABASE ENGINE
-- ============================================================================
local function RecordItemSource(itemLinkOrID, sourceCategory, detailText)
    if not AltVaultDB or not itemLinkOrID then return end
    local itemID = tonumber(string.match(tostring(itemLinkOrID), "item:(%d+)")) or tonumber(itemLinkOrID)
    if not itemID then return end

    AltVaultDB.SourceDB = AltVaultDB.SourceDB or {}
    AltVaultDB.SourceDB[itemID] = AltVaultDB.SourceDB[itemID] or {}
    local fac = UnitFactionGroup("player") or "Alliance"
    local entry = AltVaultDB.SourceDB[itemID]

    if sourceCategory == "CRAFT" then
        entry.both = detailText
    elseif fac == "Horde" then
        entry.horde = "Horde " .. detailText
    else
        entry.alliance = "Alliance " .. detailText
    end

    if ns.MasterDB and ns.MasterDB.SyncSingleItemToHoldingTank and AltVaultDB.ItemCache and AltVaultDB.ItemCache[itemID] then
        ns.MasterDB:SyncSingleItemToHoldingTank(itemID, AltVaultDB.ItemCache[itemID])
    end
end

local function RecordReagentInGlobalDB(reagentLinkOrID, reagentName, profName, skillRank, skillType, recipeName, charData)
    if not AltVaultDB then return end
    if not profName or profName == "" or profName == "UNKNOWN" or NON_CONSUMING_GATHER_PROFS[profName] then
        return
    end

    AltVaultDB.ReagentDB = AltVaultDB.ReagentDB or {}

    local itemID = tonumber(string.match(tostring(reagentLinkOrID or ""), "item:(%d+)")) or tonumber(reagentLinkOrID)
    if ns.Scanner and ns.Scanner.CacheItemData and reagentLinkOrID then
        ns.Scanner.CacheItemData(reagentLinkOrID)
    end

    if (not reagentName or reagentName == "") and itemID and AltVaultDB.ItemCache and AltVaultDB.ItemCache[itemID] then
        reagentName = AltVaultDB.ItemCache[itemID].n
    end

    local key = itemID or reagentName
    if not key then return end

    local rankNum = tonumber(skillRank) or 1
    local learnedReq = AltVaultDB.LearnedProgression
        and AltVaultDB.LearnedProgression[profName]
        and recipeName
        and AltVaultDB.LearnedProgression[profName][recipeName]

    local estMin = learnedReq or math.max(1, rankNum - 25)
    local estMax = math.min(600, estMin + 75)

    local function SaveKeyRecord(k)
        if not k then return end
        AltVaultDB.ReagentDB[k] = AltVaultDB.ReagentDB[k] or {
            name = reagentName,
            profs = {}
        }
        local entry = AltVaultDB.ReagentDB[k]
        entry.name = entry.name or reagentName

        local profRecord = entry.profs[profName]
        if not profRecord then
            entry.profs[profName] = {
                min = estMin,
                max = estMax,
                sampleRecipe = recipeName
            }
        else
            if estMin < profRecord.min then profRecord.min = estMin end
            if estMax > profRecord.max then profRecord.max = estMax end
            profRecord.sampleRecipe = profRecord.sampleRecipe or recipeName
        end
    end

    SaveKeyRecord(itemID)
    if reagentName and reagentName ~= "" then
        SaveKeyRecord(reagentName)
    end

    if charData and (skillType == "optimal" or skillType == "medium") then
        charData.neededReagents = charData.neededReagents or {}
        local needInfo = { prof = profName, recipe = recipeName or "Skill-Up Recipe" }
        if itemID then
            charData.neededReagents[itemID] = needInfo
        end
        if reagentName and reagentName ~= "" then
            charData.neededReagents[reagentName] = needInfo
        end
    end
end

ns.DB.RecordReagentInGlobalDB = RecordReagentInGlobalDB

local function ScanOpenTradeSkillReagents()
    local playerName = UnitName("player")
    if not playerName or not AltVaultDB or not AltVaultDB.Characters[playerName] then return end
    local charData = AltVaultDB.Characters[playerName]
    charData.neededReagents = charData.neededReagents or {}
    charData.knownRecipes = charData.knownRecipes or {}

    if GetNumTradeSkills and GetTradeSkillInfo then
        local profName, curRank = nil, 1
        if GetTradeSkillLine then
            local okLine, lineName, rank = pcall(GetTradeSkillLine)
            if okLine and lineName and lineName ~= "" and lineName ~= "UNKNOWN" then
                profName = lineName
                curRank = rank or 1
            end
        end

        if profName and TRACKED_PROFESSIONS[profName] then
            local numSkills = GetNumTradeSkills() or 0
            for i = 1, numSkills do
                local skillName, skillType = GetTradeSkillInfo(i)
                if skillName and skillType and skillType ~= "header" and skillType ~= "subheader" then
                    charData.knownRecipes[skillName] = true

                    local itemLink = GetTradeSkillItemLink and GetTradeSkillItemLink(i)
                    if itemLink and ns.Scanner and ns.Scanner.CacheItemData then
                        ns.Scanner.CacheItemData(itemLink)
                        RecordItemSource(itemLink, "CRAFT", string.format("Crafted via %s (%s)", profName, skillName))
                    end

                    local numReagents = GetTradeSkillNumReagents and GetTradeSkillNumReagents(i) or 0
                    for r = 1, numReagents do
                        local reagentName = GetTradeSkillReagentInfo(i, r)
                        local reagentLink = GetTradeSkillReagentItemLink(i, r)
                        RecordReagentInGlobalDB(reagentLink, reagentName, profName, curRank, skillType, skillName, charData)
                    end
                end
            end
        end
    end

    if C_TradeSkillUI and C_TradeSkillUI.GetAllRecipeIDs and C_TradeSkillUI.GetRecipeSchematic then
        local profInfo = C_TradeSkillUI.GetBaseProfessionInfo and C_TradeSkillUI.GetBaseProfessionInfo()
        local profName = profInfo and profInfo.professionName
        local curRank = (profInfo and profInfo.skillLevel) or 1
        if profName and TRACKED_PROFESSIONS[profName] and not NON_CONSUMING_GATHER_PROFS[profName] then
            local recipeIDs = C_TradeSkillUI.GetAllRecipeIDs() or {}
            for _, recipeID in ipairs(recipeIDs) do
                local rInfo = C_TradeSkillUI.GetRecipeInfo and C_TradeSkillUI.GetRecipeInfo(recipeID)
                local schematic = C_TradeSkillUI.GetRecipeSchematic(recipeID, false)
                local rName = (rInfo and rInfo.name) or (schematic and schematic.name)
                if rInfo and rInfo.learned and rName then
                    charData.knownRecipes[rName] = true
                end
                if schematic and type(schematic.reagentSlotSchematics) == "table" then
                    local diffType = (rInfo and rInfo.relativeDifficulty == 1 and "optimal")
                        or (rInfo and rInfo.relativeDifficulty == 2 and "medium")
                        or "trivial"
                    for _, slot in ipairs(schematic.reagentSlotSchematics) do
                        if type(slot.reagents) == "table" then
                            for _, reag in ipairs(slot.reagents) do
                                if reag.itemID then
                                    RecordReagentInGlobalDB(reag.itemID, nil, profName, curRank, (rInfo and rInfo.learned) and diffType or nil, rName, charData)
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    if GetNumCrafts and GetCraftInfo then
        local craftProf = (GetCraftDisplaySkillLine and GetCraftDisplaySkillLine()) or "Enchanting"
        local numCrafts = GetNumCrafts() or 0
        for i = 1, numCrafts do
            local craftName, _, craftType = GetCraftInfo(i)
            if craftName and craftType and craftType ~= "header" then
                charData.knownRecipes[craftName] = true
                local numReagents = GetCraftNumReagents and GetCraftNumReagents(i) or 0
                for r = 1, numReagents do
                    local reagentName = GetCraftReagentInfo(i, r)
                    local reagentLink = GetCraftReagentItemLink and GetCraftReagentItemLink(i, r)
                    RecordReagentInGlobalDB(reagentLink, reagentName, craftProf, 150, craftType, craftName, charData)
                end
            end
        end
    end
end

local lastScanNoticeText = ""
local lastScanNoticeTime = 0

local function PrintLiveScanReceipt(label, totalScanned, newItems, newSources)
    if (newItems or 0) <= 0 and (newSources or 0) <= 0 then
        return
    end
    local now = (GetTime and GetTime()) or 0
    local key = tostring(label) .. ":" .. tostring(totalScanned) .. ":" .. tostring(newItems) .. ":" .. tostring(newSources)
    if key == lastScanNoticeText and (now - lastScanNoticeTime) < 3.0 then
        return
    end
    lastScanNoticeText = key
    lastScanNoticeTime = now

    local alreadyKnown = math.max(0, (totalScanned or 0) - math.max(newItems or 0, newSources or 0))
    local st = (ns.MasterDB and ns.MasterDB.GetHoldingTankStats and ns.MasterDB:GetHoldingTankStats()) or {}
    local totalSources = st.TotalRecords or 0
    local uniqueIDs = st.UniqueItems or 0

    print(string.format("|cff00ffcc[AltVault Scanner]:|r %s — |cff00ff00+%d New Items|r, |cffffd100+%d New Locations|r, |cffaaaaaa%d already in DB|r |cff88ccff(DB: %d Sources / %d Item IDs)|r",
        label, newItems or 0, newSources or 0, alreadyKnown, totalSources, uniqueIDs))
end

local function ScanOpenTrainerProgression()
    if not GetNumTrainerServices or not GetTrainerServiceInfo then return end
    AltVaultDB.LearnedProgression = AltVaultDB.LearnedProgression or {}
    local playerName = UnitName("player")
    local charData = playerName and AltVaultDB.Characters and AltVaultDB.Characters[playerName]
    local trainerNPC = UnitName("npc") or UnitName("target") or "Trainer"
    local zoneName = (GetRealZoneText and GetRealZoneText()) or (GetZoneText and GetZoneText()) or "Azeroth"
    local fac = UnitFactionGroup("player") or "Both"
    local numServices = GetNumTrainerServices() or 0
    local scannedCount, newItems, newSources = 0, 0, 0

    for i = 1, numServices do
        local serviceName, _, serviceType = GetTrainerServiceInfo(i)
        if serviceName then
            if serviceType == "used" and charData then
                charData.knownRecipes = charData.knownRecipes or {}
                charData.knownRecipes[serviceName] = true
            end
            if serviceType == "available" or serviceType == "unavailable" or serviceType == "used" then
                scannedCount = scannedCount + 1
                local skillName, reqRank = nil, nil
                if GetTrainerServiceSkillReq then
                    skillName, reqRank = GetTrainerServiceSkillReq(i)
                end
                if skillName and reqRank and reqRank > 0 then
                    AltVaultDB.LearnedProgression[skillName] = AltVaultDB.LearnedProgression[skillName] or {}
                    AltVaultDB.LearnedProgression[skillName][serviceName] = reqRank
                end

                local itemLink = GetTrainerServiceItemLink and GetTrainerServiceItemLink(i)
                if itemLink and ns.Scanner and ns.Scanner.CacheItemData then
                    local taughtID = ns.Scanner.ExtractItemID and ns.Scanner.ExtractItemID(itemLink)
                    local wasCached = taughtID and AltVaultDB and AltVaultDB.ItemCache and AltVaultDB.ItemCache[taughtID] ~= nil
                    ns.Scanner.CacheItemData(itemLink, false)
                    local trainerDetail = string.format("Taught by %s (%s%s) in %s",
                        trainerNPC,
                        skillName or "Trainer",
                        (reqRank and reqRank > 0) and (" " .. reqRank) or "",
                        zoneName
                    )
                    RecordItemSource(itemLink, "TRAINER", trainerDetail)
                    if taughtID and ns.MasterDB and ns.MasterDB.UpsertLiveRecord then
                        local _, isNewSrc, isNewItm = ns.MasterDB:UpsertLiveRecord(
                            "Item",
                            taughtID,
                            serviceName,
                            "Professions",
                            skillName or "Trainer",
                            "Trainer Recipe" .. ((reqRank and reqRank > 0) and (" (Req " .. reqRank .. ")") or ""),
                            trainerNPC .. " - " .. zoneName,
                            fac,
                            "",
                            "",
                            "LiveTrainerScan"
                        )
                        if isNewItm or not wasCached then newItems = newItems + 1 end
                        if isNewSrc then newSources = newSources + 1 end
                    end
                end
            end
        end
    end
    if scannedCount > 0 then
        PrintLiveScanReceipt(string.format("Trainer |cffffd100%s|r (%s)", trainerNPC, zoneName), scannedCount, newItems, newSources)
    end
end

local VENDOR_TITLE_TO_PROF = {
    { pattern = "cooking",        prof = "Cooking" },
    { pattern = "chef",           prof = "Cooking" },
    { pattern = "butcher",        prof = "Cooking" },
    { pattern = "baker",          prof = "Cooking" },
    { pattern = "tailor",         prof = "Tailoring" },
    { pattern = "clothier",       prof = "Tailoring" },
    { pattern = "leatherwork",    prof = "Leatherworking" },
    { pattern = "tanner",         prof = "Leatherworking" },
    { pattern = "alchem",         prof = "Alchemy" },
    { pattern = "blacksmith",     prof = "Blacksmithing" },
    { pattern = "weaponsmith",    prof = "Blacksmithing" },
    { pattern = "armorsmith",     prof = "Blacksmithing" },
    { pattern = "engineer",       prof = "Engineering" },
    { pattern = "enchant",        prof = "Enchanting" },
    { pattern = "jewelcraft",     prof = "Jewelcrafting" },
    { pattern = "inscript",       prof = "Inscription" },
    { pattern = "mining",         prof = "Mining" },
    { pattern = "camping",        prof = "Camping" },
}

local function DetectMerchantProfession(npcName)
    local combinedText = string.lower(npcName or "")
    ScanTip:ClearLines()
    ScanTip:SetOwner(WorldFrame, "ANCHOR_NONE")
    if UnitExists("npc") then
        pcall(ScanTip.SetUnit, ScanTip, "npc")
    elseif UnitExists("target") then
        pcall(ScanTip.SetUnit, ScanTip, "target")
    end
    for i = 1, (ScanTip:NumLines() or 0) do
        local leftFont = _G["AltVaultTalentScanTooltipTextLeft" .. i]
        local lineText = leftFont and leftFont:GetText()
        if lineText and lineText ~= "" then
            combinedText = combinedText .. " " .. string.lower(lineText)
        end
    end

    if string.find(combinedText, "trade supplies", 1, true)
        or string.find(combinedText, "trade goods", 1, true)
        or string.find(combinedText, "general goods", 1, true)
        or string.find(combinedText, "general supplies", 1, true) then
        return nil
    end

    for _, entry in ipairs(VENDOR_TITLE_TO_PROF) do
        if string.find(combinedText, entry.pattern, 1, true) then
            return entry.prof
        end
    end
    return nil
end

local function ScanMerchantInventory()
    if not GetMerchantNumItems or not GetMerchantItemLink or not ns.Scanner then return end
    local npcName = UnitName("npc") or UnitName("target") or "Vendor"
    local zoneName = (GetRealZoneText and GetRealZoneText()) or (GetZoneText and GetZoneText()) or "Azeroth"
    local fac = UnitFactionGroup("player") or "Both"
    local vendorProf = DetectMerchantProfession(npcName)
    local count = GetMerchantNumItems() or 0
    local scannedItems, newItems, newSources = 0, 0, 0

    for i = 1, count do
        local link = GetMerchantItemLink(i)
        if link then
            scannedItems = scannedItems + 1
            local itemID = tonumber(string.match(tostring(link), "item:(%d+)"))
            local wasCached = itemID and AltVaultDB and AltVaultDB.ItemCache and AltVaultDB.ItemCache[itemID] ~= nil
            local itemName, _, _, baseILvl, itemMinLevel, itemType, _, _, itemEquipLoc, _, _, classID, _, _, _, _, isCraftingReagent =
                ns.Scanner.CacheItemData(link, false)

            -- Format vendor price / alternate currency cost if present
            local costStr = ""
            if GetMerchantItemInfo then
                local _, _, price, _, _, _, extendedCost = GetMerchantItemInfo(i)
                if extendedCost and GetMerchantItemCostInfo and GetMerchantItemCostItem then
                    local numCurrencies = GetMerchantItemCostInfo(i) or 0
                    local parts = {}
                    for c = 1, numCurrencies do
                        local _, itemValue, itemCostLink, currencyName = GetMerchantItemCostItem(i, c)
                        local costItemID = itemCostLink and tonumber(string.match(tostring(itemCostLink), "item:(%d+)"))
                        if costItemID and itemValue and itemValue > 0 then
                            table.insert(parts, "Item_" .. tostring(costItemID) .. ":" .. tostring(itemValue))
                        elseif currencyName and itemValue and itemValue > 0 then
                            table.insert(parts, tostring(currencyName) .. ":" .. tostring(itemValue))
                        end
                    end
                    if #parts > 0 then costStr = table.concat(parts, ", ") end
                elseif price and price > 0 then
                    local g = math.floor(price / 10000)
                    local s = math.floor((price % 10000) / 100)
                    if g > 0 then costStr = g .. "g" .. (s > 0 and (" " .. s .. "s") or "")
                    elseif s > 0 then costStr = s .. "s" end
                end
            end

            local vendorNote = vendorProf
                and string.format("Sold by %s <%s Supplies> in %s", npcName, vendorProf, zoneName)
                or string.format("Sold by %s in %s", npcName, zoneName)
            RecordItemSource(link, "VENDOR", vendorNote)

            if itemID and ns.MasterDB and ns.MasterDB.UpsertLiveRecord then
                local _, isNewSrc, isNewItm = ns.MasterDB:UpsertLiveRecord(
                    "Item",
                    itemID,
                    itemName or "",
                    vendorProf and "Professions" or "Vendor",
                    vendorProf or zoneName,
                    "Vendor: " .. npcName,
                    zoneName,
                    fac,
                    costStr,
                    "",
                    "LiveVendorScan"
                )
                if isNewItm or not wasCached then newItems = newItems + 1 end
                if isNewSrc then newSources = newSources + 1 end
            end

            local isEquippable = (itemEquipLoc and itemEquipLoc ~= "" and itemEquipLoc ~= "INVTYPE_NON_EQUIP_IGNORE" and itemEquipLoc ~= "INVTYPE_BAG")
            local isReagentOrSupply = (classID == 7) or (itemType == "Trade Goods") or (itemType == "Tradeskill") or (isCraftingReagent == true)
            if vendorProf and not isEquippable and isReagentOrSupply then
                local estRank = (baseILvl and baseILvl > 12) and math.max(1, math.min(250, (baseILvl - 5) * 5))
                    or ((itemMinLevel and itemMinLevel > 1) and (itemMinLevel * 5) or 1)
                RecordReagentInGlobalDB(link, itemName, vendorProf, estRank, nil, vendorProf .. " Supply (" .. npcName .. ")", nil)
            end
        end
    end

    if scannedItems > 0 then
        PrintLiveScanReceipt(string.format("Vendor |cffffd100%s|r (%s)", npcName, zoneName), scannedItems, newItems, newSources)
    end
    if ns.RefreshLiveContainerGlows then ns.RefreshLiveContainerGlows() end
end

local function ScanLootWindow()
    if not GetNumLootItems or not GetLootSlotLink or not ns.Scanner then return end
    local sourceName = UnitName("target") or "Loot Drop"
    local zoneName = (GetRealZoneText and GetRealZoneText()) or (GetZoneText and GetZoneText()) or "Azeroth"
    local count = GetNumLootItems() or 0
    local lootedItems, newItems, newSources = 0, 0, 0
    for i = 1, count do
        local link = GetLootSlotLink(i)
        if link then
            lootedItems = lootedItems + 1
            local itemID = tonumber(string.match(tostring(link), "item:(%d+)"))
            local wasCached = itemID and AltVaultDB and AltVaultDB.ItemCache and AltVaultDB.ItemCache[itemID] ~= nil
            local itemName = ns.Scanner.CacheItemData(link, false)
            RecordItemSource(link, "LOOT", string.format("Dropped by %s in %s", sourceName, zoneName))
            if itemID and ns.MasterDB and ns.MasterDB.UpsertLiveRecord then
                local _, isNewSrc, isNewItm = ns.MasterDB:UpsertLiveRecord(
                    "Item",
                    itemID,
                    itemName or "",
                    "Dungeons_Raids",
                    zoneName,
                    "Dropped by " .. sourceName,
                    sourceName,
                    "Both",
                    "",
                    "",
                    "LiveLootScan"
                )
                if isNewItm or not wasCached then newItems = newItems + 1 end
                if isNewSrc then newSources = newSources + 1 end
            end
        end
    end
    if lootedItems > 0 then
        PrintLiveScanReceipt(string.format("Loot from |cffffd100%s|r (%s)", sourceName, zoneName), lootedItems, newItems, newSources)
    end
end

local function RecordQuestRewardItem(link, questTitle, npcName, zoneName, fac)
    if not link or not ns.Scanner then return false, false end
    local itemID = tonumber(string.match(tostring(link), "item:(%d+)"))
    if not itemID then return false, false end
    local wasCached = AltVaultDB and AltVaultDB.ItemCache and AltVaultDB.ItemCache[itemID] ~= nil
    local itemName = ns.Scanner.CacheItemData(link, false)

    local questDetail = (npcName and npcName ~= "")
        and string.format("Quest: %s — %s (%s)", questTitle, npcName, zoneName)
        or string.format("Quest: %s (%s)", questTitle, zoneName)

    RecordItemSource(link, "QUEST", questDetail)

    local isNewSrc, isNewItm = false, false
    if ns.MasterDB and ns.MasterDB.UpsertLiveRecord then
        _, isNewSrc, isNewItm = ns.MasterDB:UpsertLiveRecord(
            "Item",
            itemID,
            itemName or "",
            "Quests",
            zoneName,
            "Quest: " .. questTitle,
            npcName or zoneName,
            fac or "Both",
            "",
            "",
            "LiveQuestScan"
        )
    end
    return (isNewItm or not wasCached), isNewSrc
end

local function ScanQuestGiverWindow()
    if not GetTitleText or not GetQuestItemLink then return end
    local questTitle = GetTitleText()
    if not questTitle or questTitle == "" then return end
    local npcName = UnitName("npc") or UnitName("target") or "Quest Giver"
    local zoneName = (GetRealZoneText and GetRealZoneText()) or (GetZoneText and GetZoneText()) or "Azeroth"
    local fac = UnitFactionGroup("player") or "Both"
    local rewardCount, newItems, newSources = 0, 0, 0

    local numChoices = (GetNumQuestChoices and GetNumQuestChoices()) or 0
    for i = 1, numChoices do
        local link = GetQuestItemLink("choice", i)
        if link then
            rewardCount = rewardCount + 1
            local ni, nsFlag = RecordQuestRewardItem(link, questTitle, npcName, zoneName, fac)
            if ni then newItems = newItems + 1 end
            if nsFlag then newSources = newSources + 1 end
        end
    end

    local numRewards = (GetNumQuestRewards and GetNumQuestRewards()) or 0
    for i = 1, numRewards do
        local link = GetQuestItemLink("reward", i)
        if link then
            rewardCount = rewardCount + 1
            local ni, nsFlag = RecordQuestRewardItem(link, questTitle, npcName, zoneName, fac)
            if ni then newItems = newItems + 1 end
            if nsFlag then newSources = newSources + 1 end
        end
    end

    if rewardCount > 0 then
        PrintLiveScanReceipt(string.format("Quest |cffffd100%s|r (%s)", questTitle, npcName), rewardCount, newItems, newSources)
    end
end

local function ScanActiveQuestLogRewards()
    if not GetNumQuestLogEntries or not GetQuestLogTitle or not SelectQuestLogEntry then return end
    local prevSelection = GetQuestLogSelection and GetQuestLogSelection() or nil
    local numEntries = GetNumQuestLogEntries() or 0
    local fac = UnitFactionGroup("player") or "Both"
    local currentHeaderZone = (GetRealZoneText and GetRealZoneText()) or "Azeroth"

    for i = 1, numEntries do
        local title, _, _, isHeader = GetQuestLogTitle(i)
        if isHeader and title and title ~= "" then
            currentHeaderZone = title
        elseif not isHeader and title and title ~= "" then
            pcall(SelectQuestLogEntry, i)
            local numChoices = (GetNumQuestLogChoices and GetNumQuestLogChoices()) or 0
            for c = 1, numChoices do
                local link = GetQuestLogItemLink and GetQuestLogItemLink("choice", c)
                if link then
                    RecordQuestRewardItem(link, title, nil, currentHeaderZone, fac)
                end
            end
            local numRewards = (GetNumQuestLogRewards and GetNumQuestLogRewards()) or 0
            for r = 1, numRewards do
                local link = GetQuestLogItemLink and GetQuestLogItemLink("reward", r)
                if link then
                    RecordQuestRewardItem(link, title, nil, currentHeaderZone, fac)
                end
            end
        end
    end

    if prevSelection and prevSelection > 0 then
        pcall(SelectQuestLogEntry, prevSelection)
    end
end

local function ScanAuctionHouseList()
    if not ns.Scanner or not ns.Scanner.CacheItemData then return end
    local scannedAHCount, newItems, newSources = 0, 0, 0
    local seenPageIDs = {}

    -- 1. Classic Auction House Page List ("list" / "owner" / "bidder")
    if GetNumAuctionItems and GetAuctionItemLink then
        for _, listType in ipairs({ "list", "owner", "bidder" }) do
            local batchCount = GetNumAuctionItems(listType) or 0
            for i = 1, batchCount do
                local link = GetAuctionItemLink(listType, i)
                if link then
                    local itemID = tonumber(string.match(tostring(link), "item:(%d+)"))
                    if itemID and not seenPageIDs[itemID] then
                        seenPageIDs[itemID] = true
                        scannedAHCount = scannedAHCount + 1
                        local wasCached = AltVaultDB and AltVaultDB.ItemCache and AltVaultDB.ItemCache[itemID] ~= nil
                        ns.Scanner.CacheItemData(link, false)
                        local isNowCached = AltVaultDB and AltVaultDB.ItemCache and AltVaultDB.ItemCache[itemID] ~= nil
                        if not wasCached and isNowCached then
                            newItems = newItems + 1
                        end
                        if isNowCached and ns.MasterDB and ns.MasterDB.SyncSingleItemToHoldingTank then
                            ns.MasterDB:SyncSingleItemToHoldingTank(itemID, AltVaultDB.ItemCache[itemID])
                        end
                    end
                end
            end
        end
    end

    -- 2. C_AuctionHouse Browse Results (if modern AH UI is active on 16001)
    if C_AuctionHouse and C_AuctionHouse.GetBrowseResults then
        local okB, results = pcall(C_AuctionHouse.GetBrowseResults)
        if okB and type(results) == "table" then
            for i = 1, #results do
                local r = results[i]
                local itemID = r and r.itemKey and r.itemKey.itemID
                if itemID and itemID > 0 and not seenPageIDs[itemID] then
                    seenPageIDs[itemID] = true
                    scannedAHCount = scannedAHCount + 1
                    local wasCached = AltVaultDB and AltVaultDB.ItemCache and AltVaultDB.ItemCache[itemID] ~= nil
                    if C_Item and C_Item.RequestLoadItemDataByID then
                        pcall(C_Item.RequestLoadItemDataByID, itemID)
                    end
                    ns.Scanner.CacheItemData(itemID, false)
                    local isNowCached = AltVaultDB and AltVaultDB.ItemCache and AltVaultDB.ItemCache[itemID] ~= nil
                    if not wasCached and isNowCached then
                        newItems = newItems + 1
                    end
                    if isNowCached and ns.MasterDB and ns.MasterDB.SyncSingleItemToHoldingTank then
                        ns.MasterDB:SyncSingleItemToHoldingTank(itemID, AltVaultDB.ItemCache[itemID])
                    end
                end
            end
        end
    end

    if scannedAHCount > 0 then
        PrintLiveScanReceipt("Auction House Page", scannedAHCount, newItems, newSources)
    end
end

-- ============================================================================
-- BLOCK HEADING: PROFESSIONS, GEAR, BAGS, BANK & GUILD VAULT SCANNERS
-- ============================================================================
local function ScanCharacterProfessions(charData)
    charData.professions = charData.professions or {}
    local allFound = {}
    local seen = {}
    local primaryList = {}
    local secondaryList = {}

    local function RecordSkill(skillName, skillRank, skillMaxRank)
        if not skillName or not TRACKED_PROFESSIONS[skillName] or seen[skillName] then return end
        seen[skillName] = true
        local entry = {
            name = skillName,
            rank = tonumber(skillRank) or 1,
            maxRank = tonumber(skillMaxRank) or 300
        }
        table.insert(allFound, entry)
        if PRIMARY_PROFESSIONS[skillName] then
            table.insert(primaryList, entry)
        else
            table.insert(secondaryList, entry)
        end
    end

    if GetProfessions and GetProfessionInfo then
        local okP, p1, p2, arch, fish, cook, firstAid = pcall(GetProfessions)
        if okP then
            local profIndices = { p1, p2, arch, fish, cook, firstAid }
            for idx = 1, 6 do
                local profIndex = profIndices[idx]
                if profIndex then
                    local okInfo, name, _, rank, maxRank = pcall(GetProfessionInfo, profIndex)
                    if okInfo and name then
                        RecordSkill(name, rank, maxRank)
                    end
                end
            end
        end
    end

    if GetNumSkillLines and GetSkillLineInfo then
        local okLines, numLines = pcall(GetNumSkillLines)
        if okLines and type(numLines) == "number" then
            for i = 1, numLines do
                local okL, skillName, isHeader, _, skillRank, _, _, skillMaxRank = pcall(GetSkillLineInfo, i)
                if okL and not isHeader and skillName then
                    RecordSkill(skillName, skillRank, skillMaxRank)
                end
            end
        end
    end

    if #allFound > 0 then
        charData.professions.all = allFound
        charData.professions.primary1 = primaryList[1] or secondaryList[1]
        charData.professions.primary2 = primaryList[2] or (primaryList[1] and secondaryList[1]) or secondaryList[2]
    end
end

local function ScanCharacterGear(charData)
    charData.gear = charData.gear or {}
    for slotID = 1, 19 do
        local link = GetInventoryItemLink("player", slotID)
        charData.gear[slotID] = link
        if link and ns.Scanner and ns.Scanner.CacheItemData then
            ns.Scanner.CacheItemData(link)
        end
    end
    if ns.Scanner and ns.Scanner.CalculateCharacterGearScore then
        charData.gearScore = ns.Scanner.CalculateCharacterGearScore(charData.gear)
    end
end

local function ScanCharacterBags()
    local playerName = UnitName("player")
    if not playerName or not AltVaultDB or not AltVaultDB.Characters[playerName] then return end
    local charData = AltVaultDB.Characters[playerName]
    charData.bags = {}

    for bagID = 0, 4 do
        local okS, numSlots = pcall(function()
            return (C_Container and C_Container.GetContainerNumSlots and C_Container.GetContainerNumSlots(bagID)) or 0
        end)
        numSlots = (okS and numSlots) or 0
        for slotID = 1, numSlots do
            local okI, info = pcall(function()
                return C_Container and C_Container.GetContainerItemInfo and C_Container.GetContainerItemInfo(bagID, slotID)
            end)
            if okI and info and (info.hyperlink or info.itemID) then
                local ref = info.hyperlink or info.itemID
                if ns.Scanner and ns.Scanner.CacheItemData then
                    ns.Scanner.CacheItemData(ref, true)
                end
                table.insert(charData.bags, {
                    bag = bagID,
                    slot = slotID,
                    link = info.hyperlink,
                    itemID = info.itemID,
                    count = info.stackCount or 1,
                    icon = info.iconFileID
                })
            end
        end
    end
end

local function ScanCharacterBank()
    local playerName = UnitName("player")
    if not playerName or not AltVaultDB or not AltVaultDB.Characters[playerName] then return end
    local charData = AltVaultDB.Characters[playerName]
    charData.bank = {}
    charData.bankLastUpdated = date("%Y-%m-%d %H:%M")

    local bankBags = { -1, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17 }
    for _, bagID in ipairs(bankBags) do
        local okSlots, numSlots = pcall(function()
            return C_Container and C_Container.GetContainerNumSlots and C_Container.GetContainerNumSlots(bagID)
        end)
        if okSlots and numSlots and numSlots > 0 then
            for slotID = 1, numSlots do
                local okI, info = pcall(function()
                    return C_Container and C_Container.GetContainerItemInfo and C_Container.GetContainerItemInfo(bagID, slotID)
                end)
                if okI and info and (info.hyperlink or info.itemID) then
                    local ref = info.hyperlink or info.itemID
                    if ns.Scanner and ns.Scanner.CacheItemData then
                        ns.Scanner.CacheItemData(ref, true)
                    end
                    table.insert(charData.bank, {
                        bag = bagID,
                        slot = slotID,
                        link = info.hyperlink,
                        itemID = info.itemID,
                        count = info.stackCount or 1,
                        icon = info.iconFileID
                    })
                end
            end
        end
    end
end

local function ScanGuildVault()
    if not GuildBankFrame or not GuildBankFrame:IsShown() then return end
    local guildName = GetGuildInfo("player")
    if not guildName or guildName == "" then return end

    local playerName = UnitName("player")
    if playerName and AltVaultDB.Characters[playerName] then
        AltVaultDB.Characters[playerName].guild = guildName
    end

    AltVaultDB.GuildVaults[guildName] = AltVaultDB.GuildVaults[guildName] or {
        faction = UnitFactionGroup("player") or "Alliance",
        tabs = {}
    }

    local vault = AltVaultDB.GuildVaults[guildName]
    vault.lastUpdated = date("%Y-%m-%d %H:%M")
    local currentTab = GetCurrentGuildBankTab()
    local tabName = GetGuildBankTabInfo(currentTab) or ("Tab " .. currentTab)

    vault.tabs[currentTab] = {
        name = tabName,
        items = {}
    }

    for slotIndex = 1, 98 do
        local link = GetGuildBankItemLink(currentTab, slotIndex)
        if link then
            if ns.Scanner and ns.Scanner.CacheItemData then
                ns.Scanner.CacheItemData(link, true)
            end
            local icon, count = GetGuildBankItemInfo(currentTab, slotIndex)
            table.insert(vault.tabs[currentTab].items, {
                slot = slotIndex,
                link = link,
                count = count or 1,
                icon = icon
            })
        end
    end
end

local function SyncCurrentCharacterData()
    InitializeDatabase()
    pcall(RestoreFromBetaMacro)

    local playerName = UnitName("player")
    if not playerName or playerName == "Unknown" then return end

    local _, playerClass = UnitClass("player")
    local playerLevel = UnitLevel("player")
    local detectedRace, detectedFaction, raceFile = DetectPlayerRaceAndFaction()
    local playerSex = UnitSex and UnitSex("player") or 2
    local guildName = GetGuildInfo("player")

    AltVaultDB.Characters[playerName] = AltVaultDB.Characters[playerName] or {
        professions = {}, gear = {}, bags = {}, bank = {}, talentTrees = {}, neededReagents = {}, knownRecipes = {}
    }

    local charData = AltVaultDB.Characters[playerName]
    charData.class = playerClass or charData.class or "WARRIOR"
    charData.level = (playerLevel and playerLevel > 0) and playerLevel or charData.level or 1
    charData.sex = (playerSex == 3) and 3 or 2

    if detectedRace and detectedRace ~= "" then
        charData.race = detectedRace
    end
    if raceFile and raceFile ~= "" then
        charData.raceFile = raceFile
    end
    if detectedFaction and detectedFaction ~= "" and detectedFaction ~= "Neutral" then
        charData.faction = detectedFaction
    elseif charData.race and RACE_TO_FACTION[charData.race] then
        charData.faction = RACE_TO_FACTION[charData.race]
    else
        charData.faction = charData.faction or "Alliance"
    end

    charData.guild = guildName or charData.guild
    charData.lastSeen = date("%Y-%m-%d %H:%M")

    pcall(ScanCharacterGear, charData)
    pcall(ScanCharacterProfessions, charData)
    pcall(ScanCharacterBags)
    pcall(ScanTalentsAndXP, charData)
    pcall(ScanActiveQuestLogRewards)
    if ns.MasterDB and ns.MasterDB.SyncAllLiveCachesToHoldingTank then
        pcall(ns.MasterDB.SyncAllLiveCachesToHoldingTank, ns.MasterDB)
    end
    pcall(SaveToBetaMacro)
end

local function SyncOnceOnAppOpen()
    SyncCurrentCharacterData()
    return true
end

ns.DB.SyncCurrentCharacterData = SyncCurrentCharacterData
ns.DB.SyncOnceOnAppOpen = SyncOnceOnAppOpen
ns.DB.ScanCharacterBags = ScanCharacterBags
ns.DB.ScanCharacterBank = ScanCharacterBank
ns.DB.ScanGuildVault = ScanGuildVault
ns.DB.ScanMerchantInventory = ScanMerchantInventory
ns.DB.ScanOpenTrainerProgression = ScanOpenTrainerProgression
ns.DB.ScanQuestGiverWindow = ScanQuestGiverWindow
ns.DB.ScanActiveQuestLogRewards = ScanActiveQuestLogRewards
ns.DB.ScanLootWindow = ScanLootWindow
ns.DB.ScanAuctionHouseList = ScanAuctionHouseList

-- ============================================================================
-- BLOCK HEADING: MASTER EVENT DISPATCHER (ONE-TIME ON APP OPEN + PASSIVE WINDOWS)
-- ============================================================================
EventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        InitializeDatabase()
        if ns.UpdateMinimapPosition then ns.UpdateMinimapPosition() end
    elseif event == "PLAYER_LOGIN" then
        InitializeDatabase()
        pcall(RestoreFromBetaMacro)
        if ns.MasterDB and ns.MasterDB.SyncAllLiveCachesToHoldingTank then
            pcall(ns.MasterDB.SyncAllLiveCachesToHoldingTank, ns.MasterDB)
        end
        if ns.UpdateMinimapPosition then ns.UpdateMinimapPosition() end
        print("|cff00ff00[AltVault]:|r Ready! Character data updates once when you open |cffffff00/av|r (zero background lag).")
    elseif event == "TRADE_SKILL_SHOW" or event == "CRAFT_SHOW" then
        C_Timer.After(0.2, function()
            pcall(ScanOpenTradeSkillReagents)
        end)
    elseif event == "BANKFRAME_OPENED" then
        C_Timer.After(0.2, function()
            pcall(ScanCharacterBank)
            if ns.RefreshLiveContainerGlows then ns.RefreshLiveContainerGlows() end
        end)
    elseif event == "GUILDBANKFRAME_OPENED" then
        C_Timer.After(0.2, function()
            pcall(ScanGuildVault)
        end)
    elseif event == "MERCHANT_SHOW" then
        C_Timer.After(0.15, function()
            pcall(ScanMerchantInventory)
        end)
    elseif event == "TRAINER_SHOW" or event == "TRAINER_UPDATE" then
        C_Timer.After(0.15, function()
            pcall(ScanOpenTrainerProgression)
        end)
    elseif event == "LOOT_OPENED" then
        C_Timer.After(0.05, function()
            pcall(ScanLootWindow)
        end)
    elseif event == "QUEST_DETAIL" or event == "QUEST_COMPLETE" or event == "QUEST_ITEM_UPDATE" then
        C_Timer.After(0.15, function()
            pcall(ScanQuestGiverWindow)
        end)
    elseif event == "AUCTION_ITEM_LIST_UPDATE" or event == "AUCTION_HOUSE_BROWSE_RESULTS_UPDATED" or event == "AUCTION_HOUSE_BROWSE_RESULTS_ADDED" then
        C_Timer.After(0.10, function()
            pcall(ScanAuctionHouseList)
        end)
    end
end)