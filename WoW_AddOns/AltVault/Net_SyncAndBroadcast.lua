-- ============================================================================
-- FILE: Net_SyncAndBroadcast.lua (MODULE 2 OF 3 SPLIT FROM Engine_GuildNetwork.lua)
-- BLOCK HEADING: RECIPE SCHEMATICS, STOCKPILE BUILDER & MESH BROADCASTER
-- ============================================================================
local addonName, ns = ...
local GuildNet = ns.GuildNet or {}
ns.GuildNet = GuildNet

local PREFIX = GuildNet.PREFIX or "AV_Net"
local PROF_SHORT = GuildNet.PROF_SHORT
local SHORT_TO_PROF = GuildNet.SHORT_TO_PROF
local EQUIP_SLOTS = GuildNet.EQUIP_SLOTS
local EnsureGuildNetTables = GuildNet.EnsureGuildNetTables
local StripRealm = GuildNet.StripRealm
local ExtractID = GuildNet.ExtractID
local EnqueuePacket = GuildNet.EnqueuePacket
local RecordIncomingVote = GuildNet.RecordIncomingVote
local AppendChatHistory = GuildNet.AppendChatHistory
local seenChatMsgIDs = GuildNet.seenChatMsgIDs

local NetFrame = CreateFrame("Frame")
local SafeRegisterEvent = (ns.Compat and ns.Compat.SafeRegisterEvent) or function(frame, eventName)
    pcall(frame.RegisterEvent, frame, eventName)
end

SafeRegisterEvent(NetFrame, "PLAYER_LOGIN")
SafeRegisterEvent(NetFrame, "CHAT_MSG_ADDON")
SafeRegisterEvent(NetFrame, "TRADE_SKILL_SHOW")
SafeRegisterEvent(NetFrame, "CRAFT_SHOW")
SafeRegisterEvent(NetFrame, "NAME_PLATE_UNIT_ADDED")
SafeRegisterEvent(NetFrame, "NAME_PLATE_UNIT_REMOVED")

local lastBroadcastTime = 0
local lastPingTime = 0
local lastBeaconBroadcastTime = 0
GuildNet.BeaconActivePeers = GuildNet.BeaconActivePeers or {}

-- ============================================================================
-- BLOCK HEADING: FULL RECIPE SCHEMATIC SCANNER (OUTPUT ITEM + REAGENT COUNTS)
-- ============================================================================
local function SaveRecipeSchematic(craftedID, recipeName, profName, reqRank, reagentsList, crafterName)
    if not EnsureGuildNetTables() or not craftedID or not profName then return end
    if ns.Scanner and ns.Scanner.CacheItemData then
        ns.Scanner.CacheItemData(craftedID, false)
    end

    local entry = AltVaultDB.RecipeDB[craftedID] or {
        id = craftedID,
        name = recipeName,
        prof = profName,
        rank = tonumber(reqRank) or 1,
        reagents = {},
        crafters = {}
    }

    entry.name = entry.name or recipeName
    entry.prof = profName
    if reqRank and tonumber(reqRank) and tonumber(reqRank) > 0 then
        entry.rank = tonumber(reqRank)
    end
    if reagentsList and #reagentsList > 0 then
        entry.reagents = reagentsList
    end
    if crafterName and crafterName ~= "" then
        entry.crafters = entry.crafters or {}
        entry.crafters[crafterName] = true
    end

    AltVaultDB.RecipeDB[craftedID] = entry
    if ns.MasterDB and ns.MasterDB.SyncSingleItemToHoldingTank and AltVaultDB.ItemCache and AltVaultDB.ItemCache[craftedID] then
        ns.MasterDB:SyncSingleItemToHoldingTank(craftedID, AltVaultDB.ItemCache[craftedID])
    end
end

function GuildNet.ScanOpenProfessionRecipes()
    if not EnsureGuildNetTables() then return end
    local playerName = UnitName("player")
    if not playerName then return end

    if GetNumTradeSkills and GetTradeSkillInfo then
        local profName, curRank = nil, 1
        if GetTradeSkillLine then
            local lineName, rank = GetTradeSkillLine()
            if lineName and lineName ~= "" and lineName ~= "UNKNOWN" then
                profName = lineName
                curRank = rank or 1
            end
        end

        if profName then
            local numSkills = GetNumTradeSkills() or 0
            for i = 1, numSkills do
                local skillName, skillType = GetTradeSkillInfo(i)
                if skillName and skillType and skillType ~= "header" and skillType ~= "subheader" then
                    local outLink = GetTradeSkillItemLink and GetTradeSkillItemLink(i)
                    local craftedID = ExtractID(outLink)
                    if craftedID then
                        local reagents = {}
                        local numReags = GetTradeSkillNumReagents and GetTradeSkillNumReagents(i) or 0
                        for r = 1, numReags do
                            local rName, _, rCount = GetTradeSkillReagentInfo(i, r)
                            local rLink = GetTradeSkillReagentItemLink and GetTradeSkillReagentItemLink(i, r)
                            local rID = ExtractID(rLink)
                            if rID then
                                if ns.Scanner and ns.Scanner.CacheItemData then
                                    ns.Scanner.CacheItemData(rLink or rID, false)
                                end
                                table.insert(reagents, { id = rID, name = rName, count = tonumber(rCount) or 1 })
                            end
                        end
                        local learnedReq = AltVaultDB.LearnedProgression
                            and AltVaultDB.LearnedProgression[profName]
                            and AltVaultDB.LearnedProgression[profName][skillName]
                        SaveRecipeSchematic(craftedID, skillName, profName, learnedReq or curRank, reagents, playerName)
                    end
                end
            end
        end
    end

    if C_TradeSkillUI and C_TradeSkillUI.GetAllRecipeIDs and C_TradeSkillUI.GetRecipeSchematic then
        local profInfo = C_TradeSkillUI.GetBaseProfessionInfo and C_TradeSkillUI.GetBaseProfessionInfo()
        local profName = profInfo and profInfo.professionName
        local curRank = (profInfo and profInfo.skillLevel) or 1
        if profName and profName ~= "" then
            local recipeIDs = C_TradeSkillUI.GetAllRecipeIDs() or {}
            for _, recipeID in ipairs(recipeIDs) do
                local rInfo = C_TradeSkillUI.GetRecipeInfo and C_TradeSkillUI.GetRecipeInfo(recipeID)
                local schematic = C_TradeSkillUI.GetRecipeSchematic(recipeID, false)
                local craftedID = schematic and schematic.outputItemID
                if craftedID and rInfo and rInfo.learned then
                    local reagents = {}
                    for _, slot in ipairs(schematic.reagentSlotSchematics or {}) do
                        local firstReag = slot.reagents and slot.reagents[1]
                        if firstReag and firstReag.itemID then
                            if ns.Scanner and ns.Scanner.CacheItemData then
                                ns.Scanner.CacheItemData(firstReag.itemID, false)
                            end
                            table.insert(reagents, {
                                id = firstReag.itemID,
                                count = tonumber(slot.quantityRequired) or 1
                            })
                        end
                    end
                    SaveRecipeSchematic(craftedID, rInfo.name or schematic.name, profName, curRank, reagents, playerName)
                end
            end
        end
    end
end

-- ============================================================================
-- BLOCK HEADING: ACCOUNT STOCKPILE AGGREGATOR (MATS & CONSUMABLES)
-- ============================================================================
local function GetConsumableCategory(itemID, itemName, itemSubType, equipLoc)
    local nameLower = itemName and string.lower(itemName) or ""
    if string.find(nameLower, "bandage", 1, true) then
        return "Bandage"
    elseif string.find(nameLower, "scroll of", 1, true) then
        return "Scroll"
    elseif string.find(nameLower, "elixir", 1, true) or string.find(nameLower, "flask", 1, true) then
        return "Elixir / Flask"
    elseif string.find(nameLower, "potion", 1, true) then
        return "Potion"
    elseif itemSubType == "Food & Drink" or string.find(nameLower, "cooked") or string.find(nameLower, "roasted")
        or string.find(nameLower, "steak") or string.find(nameLower, "stew") or string.find(nameLower, "soup")
        or string.find(nameLower, "bread") or string.find(nameLower, "cheese") or string.find(nameLower, "water")
        or string.find(nameLower, "milk") or string.find(nameLower, "juice") or string.find(nameLower, "nectar") then
        return "Food & Drink"
    end
    return "Consumable / Utility"
end

GuildNet.GetConsumableCategory = GetConsumableCategory

local function BuildAccountStockpiles(faction)
    local matTotals = {}
    local consTotals = {}
    if not AltVaultDB or not AltVaultDB.Characters then return matTotals, consTotals end

    for _, charData in pairs(AltVaultDB.Characters) do
        if not faction or charData.faction == faction then
            local function ScanList(list)
                for _, item in ipairs(list or {}) do
                    local ref = item.link or item.itemID
                    local id = ExtractID(ref)
                    local isLocked = id and (ns.DB and ns.DB.IsItemTradeLocked and ns.DB.IsItemTradeLocked(id))
                    if id and not isLocked then
                        local name, _, _, _, _, itemType, itemSubType, _, equipLoc, _, _, classID, _, bindType, _, _, isReagent =
                            ns.Scanner.FetchItemInfo(ref)
                        if name and (not bindType or bindType == 0 or bindType == 2 or bindType == 3) then
                            local count = tonumber(item.count) or 1
                            local isMat = (classID == 7) or (itemType == "Trade Goods") or (itemType == "Tradeskill") or (isReagent == true)
                            local isCons = (classID == 0) or (itemType == "Consumable")
                            if isMat then
                                matTotals[id] = (matTotals[id] or 0) + count
                            elseif isCons and (not equipLoc or equipLoc == "" or equipLoc == "INVTYPE_NON_EQUIP_IGNORE") then
                                consTotals[id] = (consTotals[id] or 0) + count
                            end
                        end
                    end
                end
            end
            ScanList(charData.bags)
            ScanList(charData.bank)
        end
    end

    return matTotals, consTotals
end

-- ============================================================================
-- BLOCK HEADING: CONSENT-BASED WHISPER SYNC & WAITLIST QUEUE ENGINE
-- ============================================================================
local function DispatchMeshPacket(msg, explicitDist, whisperTarget, playerFaction)
    if explicitDist == "WHISPER" and whisperTarget then
        EnqueuePacket(msg, "WHISPER", whisperTarget)
    end
end

GuildNet.DispatchMeshPacket = DispatchMeshPacket

local function BuildBasicProfilePacketsForChar(charName, charData, isReplyFlag)
    if not charData then return {} end
    local packets = {}
    local profParts = {}
    if charData.professions and type(charData.professions.all) == "table" then
        for _, p in ipairs(charData.professions.all) do
            local code = p.name and PROF_SHORT[p.name]
            if code then
                table.insert(profParts, code .. ":" .. tostring(p.rank or 1))
            end
        end
    end
    local profStr = (#profParts > 0) and table.concat(profParts, ",") or "-"

    local slotParts = {}
    local gearIDParts = {}
    for _, sID in ipairs(EQUIP_SLOTS) do
        local link = charData.gear and charData.gear[sID]
        local gs = (sID ~= 4 and sID ~= 19 and link) and ns.Scanner.CalculateItemGearScore(link, sID) or 0
        local itemID = ExtractID(link) or 0
        if sID ~= 4 and sID ~= 19 then
            table.insert(slotParts, sID .. ":" .. gs)
        end
        if itemID > 0 then
            table.insert(gearIDParts, sID .. ":" .. itemID)
        end
    end
    local slotStr = table.concat(slotParts, ",")
    local gearIDStr = (#gearIDParts > 0) and table.concat(gearIDParts, ",") or "-"

    local cleanRace = string.gsub(charData.race or "Unknown", "|", "")
    local cleanSpec = string.gsub(charData.specName or "Spec", "|", "")
    local cleanBuild = string.gsub(charData.talentBuild or "0/0/0", "|", "")
    local cleanGuild = string.gsub(charData.guild or "No Guild", "|", "")
    local charSex = (charData.sex == 3) and 3 or 2
    local fofFlag = (AltVaultDB and AltVaultDB.BlockFriendsOfFriends) and 1 or 0

    local cmdPrefix = isReplyFlag and "REP_HB" or "REQ_HB"
    table.insert(packets, string.format("%s|%s|%d|%s|%d|%s|%s|%s|%s|%s|%s|%d|%d",
        cmdPrefix,
        charData.class or "WARRIOR",
        charData.level or 1,
        charData.specRole or "MELEE_STR",
        charData.gearScore or 0,
        profStr,
        slotStr,
        cleanRace,
        cleanSpec,
        cleanBuild,
        cleanGuild,
        charSex,
        fofFlag
    ))
    table.insert(packets, (isReplyFlag and "REP_GEAR|" or "REQ_GEAR|") .. gearIDStr)

    -- Include only the names/classes/levels of alts on the same faction (inventories remain closed until requested 1-by-1)
    local fac = charData.faction or UnitFactionGroup("player") or "Alliance"
    local altTokens = {}
    for aName, aData in pairs((AltVaultDB and AltVaultDB.Characters) or {}) do
        if aName ~= charName and aData.faction == fac then
            local cleanA = string.gsub(aName, "[:|,]", "")
            table.insert(altTokens, string.format("%s:%s:%d", cleanA, aData.class or "WARRIOR", aData.level or 1))
            if #altTokens >= 10 then break end
        end
    end
    if #altTokens > 0 then
        table.insert(packets, (isReplyFlag and "REP_ALTS|" or "REQ_ALTS|") .. table.concat(altTokens, ","))
    end
    return packets
end

-- No automatic broadcasts! Only targeted whisper sync when explicitly approved or requested.
function GuildNet.BroadcastPlayerState(forceAll, explicitDist, whisperTarget)
    if explicitDist == "WHISPER" and whisperTarget then
        local playerName = UnitName("player")
        local charData = playerName and AltVaultDB and AltVaultDB.Characters and AltVaultDB.Characters[playerName]
        if not charData then return end
        local pkts = BuildBasicProfilePacketsForChar(playerName, charData, true)
        for _, p in ipairs(pkts) do
            EnqueuePacket(p, "WHISPER", whisperTarget)
        end
    end
end

function GuildNet.RequestGuildSync()
    print("|cffffd100[AltVault Sync]:|r Automatic mass broadcasting is disabled to prevent lag. Type a player's name (or target them) and click |cff00ff00[Request Sync]|r!")
end

-- 1) Send a Sync Request (Basic Profile Preview + Polite Whisper -> Receiver's Sync Queue)
function GuildNet.RequestDirectWhisperSync(targetPlayerName)
    if not EnsureGuildNetTables() then return end
    if not targetPlayerName or targetPlayerName == "" then return end
    local cleanTarget = StripRealm(string.gsub(targetPlayerName, "^%s*(.-)%s*$", "%1"))
    local playerName = UnitName("player")
    if not cleanTarget or cleanTarget == "" or cleanTarget == playerName then
        print("|cffffcc00[AltVault]:|r Please enter another player's character name to request a sync.")
        return
    end

    if ns.DB and ns.DB.SyncCurrentCharacterData then
        ns.DB.SyncCurrentCharacterData()
    end

    local charData = playerName and AltVaultDB.Characters and AltVaultDB.Characters[playerName]
    if not charData then return end

    -- Send polite visible whisper so the player knows you are requesting to sync
    if SendChatMessage then
        pcall(SendChatMessage, string.format("[AltVault]: %s is requesting to sync with you! (Check your AltVault 'Sync Queue & Hub' tab to preview and Accept or Deny.)", playerName), "WHISPER", nil, cleanTarget)
    end

    local pkts = BuildBasicProfilePacketsForChar(playerName, charData, false)
    for _, p in ipairs(pkts) do
        EnqueuePacket(p, "WHISPER", cleanTarget)
    end

    print(string.format("|cff00ff00[AltVault Sync]:|r Sent whisper Sync Request to |cffffff00%s|r! Once they accept in their Sync Queue, their profile will unlock.", cleanTarget))
end

-- 2) Request a Specific Closed Category from a Synced Peer (Goes into their Sync Queue!)
local CATEGORY_LABELS = {
    PROFILE = "Basic Profile & Equipped Gear",
    BAGS    = "Bag Inventory (Tradeable Items)",
    BANK    = "Personal Bank (Tradeable Items)",
    RECIPES = "Profession Levels & Known Recipes",
    TALENTS = "Talent Tree & Specialization",
    VGUILD  = "Virtual Guild Synced Peers List",
    ALT     = "Alt Character Profile",
}
GuildNet.CATEGORY_LABELS = CATEGORY_LABELS

function GuildNet.RequestPeerCategory(peerName, reqType, altName)
    if not EnsureGuildNetTables() or not peerName or not reqType then return end
    local cleanTarget = StripRealm(peerName)
    local playerName = UnitName("player")
    if not cleanTarget or cleanTarget == "" or cleanTarget == playerName then return end

    local catLabel = (reqType == "ALT" and altName) and ("Alt Character [" .. altName .. "]") or (CATEGORY_LABELS[reqType] or reqType)
    if SendChatMessage then
        pcall(SendChatMessage, string.format("[AltVault]: %s is requesting to sync your %s (Check your AltVault Sync Queue to Approve or Deny).", playerName, catLabel), "WHISPER", nil, cleanTarget)
    end

    EnqueuePacket(string.format("REQ_CAT|%s|%s", reqType, tostring(altName or "")), "WHISPER", cleanTarget)
    print(string.format("|cff00ccff[AltVault Sync]:|r Requested |cffffff00%s|r from |cff00ff96%s|r (placed in their Sync Queue for approval).", catLabel, cleanTarget))
end

-- Helper to send only the approved category back to the requester
local function SendApprovedCategoryData(targetPeer, reqType, altName)
    local playerName = UnitName("player")
    local charData = playerName and AltVaultDB.Characters and AltVaultDB.Characters[playerName]
    if not charData then return end

    if reqType == "PROFILE" then
        local pkts = BuildBasicProfilePacketsForChar(playerName, charData, true)
        for _, p in ipairs(pkts) do
            EnqueuePacket(p, "WHISPER", targetPeer)
        end
        return
    end

    if reqType == "BAGS" or reqType == "BANK" then
        local srcList = (reqType == "BAGS") and (charData.bags or {}) or (charData.bank or {})
        local cmdTag = (reqType == "BAGS") and "DATA_BAGS" or "DATA_BANK"
        local totals = {}
        for _, item in ipairs(srcList) do
            local ref = item.link or item.itemID
            local id = ExtractID(ref)
            local isLocked = id and (ns.DB and ns.DB.IsItemTradeLocked and ns.DB.IsItemTradeLocked(id))
            if id and not isLocked then
                local _, _, _, _, _, _, _, _, _, _, _, _, _, bindType = ns.Scanner.FetchItemInfo(ref)
                if not bindType or bindType == 0 or bindType == 2 or bindType == 3 then
                    totals[id] = (totals[id] or 0) + (tonumber(item.count) or 1)
                end
            end
        end
        EnqueuePacket(cmdTag .. "_START|" .. playerName, "WHISPER", targetPeer)
        local chunk = cmdTag .. "|"
        for id, cnt in pairs(totals) do
            local tok = tostring(id) .. ":" .. tostring(cnt)
            if (#chunk + #tok + 1) > 230 then
                EnqueuePacket(chunk, "WHISPER", targetPeer)
                chunk = cmdTag .. "|" .. tok
            else
                chunk = (chunk == (cmdTag .. "|")) and (chunk .. tok) or (chunk .. "," .. tok)
            end
        end
        if chunk ~= (cmdTag .. "|") then
            EnqueuePacket(chunk, "WHISPER", targetPeer)
        end
        return
    end

    if reqType == "RECIPES" then
        EnqueuePacket("DATA_REC_START|" .. playerName, "WHISPER", targetPeer)
        local recChunk = "REC|"
        for craftedID, rData in pairs(AltVaultDB.RecipeDB or {}) do
            if rData.crafters and rData.crafters[playerName] and rData.reagents and #rData.reagents > 0 then
                local pCode = PROF_SHORT[rData.prof or ""] or "CR"
                local rTokens = {}
                for _, rg in ipairs(rData.reagents) do
                    table.insert(rTokens, tostring(rg.id) .. "x" .. tostring(rg.count or 1))
                end
                local entry = string.format("%d:%s:%d:%s", craftedID, pCode, rData.rank or 1, table.concat(rTokens, "+"))
                if (#recChunk + #entry + 1) > 230 then
                    EnqueuePacket(recChunk, "WHISPER", targetPeer)
                    recChunk = "REC|" .. entry
                else
                    recChunk = (recChunk == "REC|") and (recChunk .. entry) or (recChunk .. ";" .. entry)
                end
            end
        end
        if recChunk ~= "REC|" then
            EnqueuePacket(recChunk, "WHISPER", targetPeer)
        end
        return
    end

    if reqType == "TALENTS" then
        EnqueuePacket("DATA_TAL_START|" .. (charData.specName or "Spec") .. "|" .. (charData.talentBuild or "0/0/0"), "WHISPER", targetPeer)
        for tIdx, tree in ipairs(charData.talentTrees or {}) do
            local cleanTreeName = string.gsub(tree.name or ("Tree " .. tIdx), "[|:,;]", "")
            local tChunk = string.format("DATA_TAL|%d|%s|%d|", tIdx, cleanTreeName, tree.pointsSpent or 0)
            local prefixLen = #tChunk
            for _, tal in ipairs(tree.talents or {}) do
                if (tal.rank or 0) > 0 then
                    local cleanTName = string.gsub(tal.name or "Talent", "[|:,;]", "")
                    local tok = string.format("%d:%s:%d:%d", tal.tier or 1, cleanTName, tal.rank or 1, tal.maxRank or 5)
                    if (#tChunk + #tok + 1) > 230 then
                        EnqueuePacket(tChunk, "WHISPER", targetPeer)
                        tChunk = string.format("DATA_TAL|%d|%s|%d|", tIdx, cleanTreeName, tree.pointsSpent or 0) .. tok
                    else
                        tChunk = (#tChunk == prefixLen) and (tChunk .. tok) or (tChunk .. ";" .. tok)
                    end
                end
            end
            if #tChunk > prefixLen then
                EnqueuePacket(tChunk, "WHISPER", targetPeer)
            end
        end
        return
    end

    if reqType == "VGUILD" then
        local fac = charData.faction or UnitFactionGroup("player") or "Alliance"
        local allowedPeers = {}
        for pName, pData in pairs(AltVaultDB.GuildNetwork or {}) do
            if pName ~= playerName and pName ~= targetPeer and pData.isSynced ~= false then
                if (not pData.faction or pData.faction == fac) and not pData.blockFoF then
                    table.insert(allowedPeers, string.format("%s:%s:%d", pName, pData.class or "WARRIOR", pData.level or 1))
                    if #allowedPeers >= 14 then break end
                end
            end
        end
        EnqueuePacket("DATA_VGUILD|" .. (#allowedPeers > 0 and table.concat(allowedPeers, ",") or "-"), "WHISPER", targetPeer)
        return
    end

    if reqType == "ALT" and altName and AltVaultDB.Characters and AltVaultDB.Characters[altName] then
        local aData = AltVaultDB.Characters[altName]
        local profParts = {}
        if aData.professions and type(aData.professions.all) == "table" then
            for _, p in ipairs(aData.professions.all) do
                local code = p.name and PROF_SHORT[p.name]
                if code then table.insert(profParts, code .. ":" .. tostring(p.rank or 1)) end
            end
        end
        local profStr = (#profParts > 0) and table.concat(profParts, ",") or "-"
        local gearIDParts = {}
        for _, sID in ipairs(EQUIP_SLOTS) do
            local itemID = ExtractID(aData.gear and aData.gear[sID]) or 0
            if itemID > 0 then table.insert(gearIDParts, sID .. ":" .. itemID) end
        end
        local gearIDStr = (#gearIDParts > 0) and table.concat(gearIDParts, ",") or "-"
        local cleanRace = string.gsub(aData.race or "Unknown", "|", "")
        local cleanSpec = string.gsub(aData.specName or "Spec", "|", "")
        local cleanBuild = string.gsub(aData.talentBuild or "0/0/0", "|", "")
        EnqueuePacket(string.format("DATA_ALT|%s|%s|%d|%s|%d|%s|%s|%s|%s|%d",
            altName, aData.class or "WARRIOR", aData.level or 1, cleanRace,
            aData.gearScore or 0, profStr, cleanSpec, cleanBuild, gearIDStr, (aData.sex == 3) and 3 or 2),
            "WHISPER", targetPeer)
        return
    end
end

-- 3) Approve or Deny a Sync Queue Item
function GuildNet.ApproveQueueItem(queueIdx)
    if not EnsureGuildNetTables() then return end
    local qItem = AltVaultDB.SyncQueue and AltVaultDB.SyncQueue[queueIdx]
    if not qItem then return end

    local sender = qItem.sender
    local reqType = qItem.reqType or "PROFILE"
    local altName = qItem.altName

    -- If this is an initial profile sync or we have previewData for them, promote their Basic Profile into GuildNetwork!
    if qItem.previewData then
        local fac = UnitFactionGroup("player") or "Alliance"
        AltVaultDB.GuildNetwork[sender] = AltVaultDB.GuildNetwork[sender] or {
            faction = fac, profs = {}, slotGS = {}, gear = {}, mats = {}, cons = {},
        }
        local peer = AltVaultDB.GuildNetwork[sender]
        local pv = qItem.previewData
        peer.isSynced = true
        peer.explicitlyApprovedSync = true
        peer.isOnline = true
        peer.lastSeen = date("%Y-%m-%d %H:%M")
        peer.lastSeenTimestamp = time()
        peer.class = pv.class or peer.class or "WARRIOR"
        peer.level = pv.level or peer.level or 1
        peer.specRole = pv.specRole or peer.specRole or "MELEE_STR"
        peer.gearScore = pv.gearScore or peer.gearScore or 0
        peer.race = pv.race or peer.race or "Unknown"
        peer.specName = pv.specName or peer.specName or "Spec"
        peer.talentBuild = pv.talentBuild or peer.talentBuild or "0/0/0"
        peer.guild = pv.guild or peer.guild or "Virtual Guild"
        peer.sex = pv.sex or peer.sex or 2
        peer.blockFoF = pv.blockFoF and true or false
        if pv.profs then peer.profs = pv.profs end
        if pv.slotGS then peer.slotGS = pv.slotGS end
        if pv.gear and next(pv.gear) then peer.gear = pv.gear end
        if pv.altList then peer.altList = pv.altList end
    end

    table.remove(AltVaultDB.SyncQueue, queueIdx)
    SendApprovedCategoryData(sender, reqType, altName)

    local catLabel = (reqType == "ALT" and altName) and ("Alt [" .. altName .. "]") or (CATEGORY_LABELS[reqType] or reqType)
    print(string.format("|cff00ff00[AltVault Sync Queue]:|r Approved |cffffff00%s|r's request for |cff00ff96%s|r and sent whisper sync reply!", sender, catLabel))

    if AltVaultMainPanel and AltVaultMainPanel:IsShown() then
        AltVaultMainPanel:RefreshView()
    end
end

function GuildNet.DenyQueueItem(queueIdx, addToIgnoreList)
    if not EnsureGuildNetTables() then return end
    local qItem = AltVaultDB.SyncQueue and AltVaultDB.SyncQueue[queueIdx]
    if not qItem then return end

    local sender = qItem.sender
    table.remove(AltVaultDB.SyncQueue, queueIdx)

    if addToIgnoreList and sender then
        AltVaultDB.IgnoredSyncPlayers[sender] = true
        print(string.format("|cffff4444[AltVault Sync]:|r Denied and added |cffffff00%s|r to your Ignored Sync list.", sender))
    else
        print(string.format("|cffffcc00[AltVault Sync]:|r Declined sync request from |cffffff00%s|r.", sender or "Player"))
    end

    if sender then
        EnqueuePacket("SYNC_DENY|DECLINED", "WHISPER", sender)
    end

    if AltVaultMainPanel and AltVaultMainPanel:IsShown() then
        AltVaultMainPanel:RenderActivePane()
    end
end

local function FindOrCreateQueueEntry(sender, reqType, altName)
    AltVaultDB.SyncQueue = AltVaultDB.SyncQueue or {}
    for _, q in ipairs(AltVaultDB.SyncQueue) do
        if q.sender == sender and q.reqType == reqType and (q.altName or "") == (altName or "") then
            q.timestamp = time()
            q.timeStr = date("%H:%M")
            return q, false
        end
    end
    local newEntry = {
        sender = sender,
        reqType = reqType,
        altName = altName,
        timestamp = time(),
        timeStr = date("%H:%M"),
        previewData = { profs = {}, slotGS = {}, gear = {}, altList = {} }
    }
    table.insert(AltVaultDB.SyncQueue, 1, newEntry)
    return newEntry, true
end

local function ParseHBIntoTable(targetTbl, payload)
    local parts = {}
    for token in string.gmatch((payload or "") .. "|", "([^|]*)|") do
        table.insert(parts, token)
    end
    local class, lvl, role, gs, profStr, slotStr, race, specName, talentBuild, guildName, sexStr, fofStr =
        parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8], parts[9], parts[10], parts[11], parts[12]

    if class and class ~= "" then
        targetTbl.class = class
        targetTbl.level = tonumber(lvl) or 1
        targetTbl.specRole = role or "MELEE_STR"
        targetTbl.gearScore = tonumber(gs) or 0
        if race and race ~= "" then targetTbl.race = race end
        if specName and specName ~= "" then targetTbl.specName = specName end
        if talentBuild and talentBuild ~= "" then targetTbl.talentBuild = talentBuild end
        if guildName and guildName ~= "" then targetTbl.guild = guildName end
        targetTbl.sex = (tonumber(sexStr) == 3) and 3 or 2
        targetTbl.blockFoF = (tonumber(fofStr) == 1)

        targetTbl.profs = {}
        if profStr and profStr ~= "-" then
            for token in string.gmatch(profStr, "([^,]+)") do
                local code, rStr = string.match(token, "^(%a%a):(%d+)$")
                if code and SHORT_TO_PROF[code] then
                    targetTbl.profs[SHORT_TO_PROF[code]] = tonumber(rStr) or 1
                end
            end
        end
        targetTbl.slotGS = {}
        if slotStr then
            for token in string.gmatch(slotStr, "([^,]+)") do
                local sID, sGS = string.match(token, "^(%d+):(%d+)$")
                if sID and sGS then
                    targetTbl.slotGS[tonumber(sID)] = tonumber(sGS) or 0
                end
            end
        end
    end
end

local function ParseGearIntoTable(targetTbl, payload)
    targetTbl.gear = {}
    if payload and payload ~= "-" then
        for token in string.gmatch(payload, "([^,]+)") do
            local sIDStr, itemIDStr = string.match(token, "^(%d+):(%d+)$")
            local sID, itemID = tonumber(sIDStr), tonumber(itemIDStr)
            if sID and itemID and itemID > 0 then
                targetTbl.gear[sID] = itemID
                if C_Item and C_Item.RequestLoadItemDataByID then
                    pcall(C_Item.RequestLoadItemDataByID, itemID)
                end
            end
        end
    end
end

local function ParseAltListIntoTable(targetTbl, payload)
    targetTbl.altList = {}
    if payload and payload ~= "-" then
        for token in string.gmatch(payload, "([^,]+)") do
            local aName, aClass, aLvl = string.match(token, "^([^:]+):([^:]+):(%d+)$")
            if aName and aClass then
                table.insert(targetTbl.altList, { name = aName, class = aClass, level = tonumber(aLvl) or 1 })
            end
        end
    end
end

-- ============================================================================
-- BLOCK HEADING: INCOMING ADDON PACKET ROUTER & EVENT DISPATCHER
-- ============================================================================
local uiRefreshPending = false
local function ScheduleDebouncedNetUIRefresh()
    if uiRefreshPending then return end
    uiRefreshPending = true
    C_Timer.After(0.20, function()
        uiRefreshPending = false
        if AltVaultMainPanel and AltVaultMainPanel:IsShown() then
            if AltVaultMainPanel.RefreshPeerSidebarList then
                AltVaultMainPanel:RefreshPeerSidebarList()
            end
            local mode = AltVaultMainPanel.GetActiveViewMode and AltVaultMainPanel:GetActiveViewMode()
            if mode == "ARMORY" or mode == "TALENTS" or mode == "GUILD" or mode == "GUILD_GEAR" or mode == "GUILD_MATS" or mode == "GUILD_CONS" or mode == "SYNCED_ROSTER" or mode == "VIRTUAL_CHAT" then
                AltVaultMainPanel:RenderActivePane()
            end
        end
    end)
end

local function OnAddonMessageReceived(prefix, message, channel, sender)
    if prefix ~= PREFIX or not message or not sender then return end
    if not EnsureGuildNetTables() then return end

    local cleanSender = StripRealm(sender)
    if not cleanSender or cleanSender == "" or cleanSender == UnitName("player") then return end

    -- 1. Check Ignored Sync Players list
    if AltVaultDB.IgnoredSyncPlayers and AltVaultDB.IgnoredSyncPlayers[cleanSender] then
        return
    end

    local cmd, payload = string.match(message, "^([^|]+)|(.*)$")
    if not cmd then return end

    -- 1B. Open-World Nameplate Glow Beacon Packets (Lightweight 10-byte presence flag)
    if cmd == "BEACON" or cmd == "BEACON_PING" then
        local isSenderGlowOn = (payload == "1")
        GuildNet.BeaconActivePeers[cleanSender] = isSenderGlowOn or nil
        if AltVaultDB and AltVaultDB.GuildNetwork and AltVaultDB.GuildNetwork[cleanSender] then
            AltVaultDB.GuildNetwork[cleanSender].beaconOn = isSenderGlowOn
        end
        if GuildNet.RefreshAllVisibleNameplates then
            GuildNet.RefreshAllVisibleNameplates()
        end
        if cmd == "BEACON_PING" then
            local myGlowOn = (not AltVaultDB or AltVaultDB.NameplateGlowEnabled ~= false) and not (AltVaultDB and AltVaultDB.SyncDND)
            if myGlowOn then
                EnqueuePacket("BEACON|1", "WHISPER", cleanSender)
                if ns.FaceVault and ns.FaceVault.EncodeCurrentRunwayLook then
                    local encLook = ns.FaceVault:EncodeCurrentRunwayLook()
                    if encLook then
                        EnqueuePacket("FV_LOOK|" .. encLook, "WHISPER", cleanSender)
                    end
                end
            end
        end
        return
    end

    -- 1C. Public FaceVault 3D Runway Look Broadcast & Public Reactions (No SyncQueue Barrier!)
    local myFac = UnitFactionGroup("player") or "Alliance"
    if cmd == "FV_LOOK" and ns.FaceVault and ns.FaceVault.DecodeRunwayLook then
        local decoded = ns.FaceVault:DecodeRunwayLook(payload)
        if decoded and AltVaultDB.GuildNetwork[cleanSender] and AltVaultDB.GuildNetwork[cleanSender].explicitlyApprovedSync == true then
            local peer = AltVaultDB.GuildNetwork[cleanSender]
            peer.faction = myFac
            peer.isOnline = true
            peer.lastSeen = date("%Y-%m-%d %H:%M")
            peer.lastSeenTimestamp = time()
            peer.class = decoded.class or peer.class or "WARRIOR"
            peer.race = decoded.race or peer.race or "Human"
            peer.sex = decoded.sex or peer.sex or 2
            peer.runwayOutfit = decoded.runwayOutfit
            peer.runwayPose = decoded.pose
            if not next(peer.gear or {}) then
                peer.gear = decoded.runwayOutfit
            end
            GuildNet.BeaconActivePeers[cleanSender] = true
            if GuildNet.RefreshAllVisibleNameplates then
                GuildNet.RefreshAllVisibleNameplates()
            end
            ScheduleDebouncedNetUIRefresh()
        end
        return
    elseif cmd == "VOTE" then
        local tName, vName, valStr = string.match(payload or "", "^([^|]+)|([^|]+)|([%-]?%d+)$")
        local numVal = tonumber(valStr)
        if tName and vName and numVal then
            if RecordIncomingVote(StripRealm(tName), StripRealm(vName), numVal) then
                if GuildNet.RefreshAllVisibleNameplates then
                    GuildNet.RefreshAllVisibleNameplates()
                end
                ScheduleDebouncedNetUIRefresh()
            end
        end
        return
    end

    -- 2. Handle DND / Decline notifications
    if cmd == "SYNC_DENY" then
        if payload == "DND" then
            print(string.format("|cffffcc00[AltVault Sync]:|r |cffffff00%s|r currently has Sync DND (Do Not Disturb) turned on.", cleanSender))
        else
            print(string.format("|cffffcc00[AltVault Sync]:|r |cffffff00%s|r declined the sync request.", cleanSender))
        end
        return
    end

    -- 3. If DND is turned ON locally, automatically block incoming sync requests without bothering the player
    if AltVaultDB.SyncDND and (cmd == "REQ_HB" or cmd == "REQ_GEAR" or cmd == "REQ_ALTS" or cmd == "REQ_CAT" or cmd == "PING") then
        if cmd == "REQ_HB" or cmd == "REQ_CAT" or cmd == "PING" then
            EnqueuePacket("SYNC_DENY|DND", "WHISPER", cleanSender)
        end
        return
    end

    -- 4. Incoming Initial Sync Request -> Places in SyncQueue ONLY (does NOT add to GuildNetwork until approved!)
    if cmd == "REQ_HB" or cmd == "HB" then
        local qEntry, isNew = FindOrCreateQueueEntry(cleanSender, "PROFILE", nil)
        ParseHBIntoTable(qEntry.previewData, payload)
        if AltVaultDB.GuildNetwork[cleanSender] and AltVaultDB.GuildNetwork[cleanSender].explicitlyApprovedSync == true then
            local pubPeer = AltVaultDB.GuildNetwork[cleanSender]
            pubPeer.isOnline = true
            pubPeer.lastSeen = date("%Y-%m-%d %H:%M")
            pubPeer.lastSeenTimestamp = time()
            ParseHBIntoTable(pubPeer, payload)
        elseif isNew then
            print(string.format("|cff00ff00[AltVault Sync Queue]:|r |cffffff00%s|r requested to sync with you! Open |cff00ccffSync Queue & Hub|r to Preview, Accept, or Deny.", cleanSender))
        end
        ScheduleDebouncedNetUIRefresh()
        return
    elseif cmd == "REQ_GEAR" then
        local qEntry = FindOrCreateQueueEntry(cleanSender, "PROFILE", nil)
        ParseGearIntoTable(qEntry.previewData, payload)
        if AltVaultDB.GuildNetwork[cleanSender] and AltVaultDB.GuildNetwork[cleanSender].explicitlyApprovedSync == true then
            ParseGearIntoTable(AltVaultDB.GuildNetwork[cleanSender], payload)
        end
        ScheduleDebouncedNetUIRefresh()
        return
    elseif cmd == "REQ_ALTS" then
        local qEntry = FindOrCreateQueueEntry(cleanSender, "PROFILE", nil)
        ParseAltListIntoTable(qEntry.previewData, payload)
        if AltVaultDB.GuildNetwork[cleanSender] and AltVaultDB.GuildNetwork[cleanSender].explicitlyApprovedSync == true then
            ParseAltListIntoTable(AltVaultDB.GuildNetwork[cleanSender], payload)
        end
        ScheduleDebouncedNetUIRefresh()
        return
    elseif cmd == "REQ_CAT" then
        local reqType, altName = string.match(payload or "", "^([^|]+)|(.*)$")
        reqType = reqType or "BAGS"
        if altName == "" then altName = nil end
        local qEntry, isNew = FindOrCreateQueueEntry(cleanSender, reqType, altName)
        -- Copy known basic profile if they are already synced
        if AltVaultDB.GuildNetwork[cleanSender] then
            qEntry.previewData = AltVaultDB.GuildNetwork[cleanSender]
        end
        if isNew then
            local catLabel = (reqType == "ALT" and altName) and ("Alt [" .. altName .. "]") or (CATEGORY_LABELS[reqType] or reqType)
            print(string.format("|cff00ccff[AltVault Sync Queue]:|r |cffffff00%s|r requested to sync your |cff00ff96%s|r! Check your |cff00ccffSync Queue & Hub|r tab to Approve or Deny.", cleanSender, catLabel))
        end
        ScheduleDebouncedNetUIRefresh()
        return
    end

    -- 5. Incoming Approved Reply for Basic Profile (REP_HB / REP_GEAR / REP_ALTS) -> Unlocks Synced Peer!
    local faction = UnitFactionGroup("player") or "Alliance"
    if cmd == "REP_HB" or cmd == "REP_GEAR" or cmd == "REP_ALTS" then
        AltVaultDB.GuildNetwork[cleanSender] = AltVaultDB.GuildNetwork[cleanSender] or {
            faction = faction, profs = {}, slotGS = {}, gear = {}, mats = {}, cons = {},
        }
        local peer = AltVaultDB.GuildNetwork[cleanSender]
        peer.faction = faction
        peer.isSynced = true
        peer.explicitlyApprovedSync = true
        peer.isOnline = true
        peer.lastSeen = date("%Y-%m-%d %H:%M")
        peer.lastSeenTimestamp = time()
        peer.lastChannel = "WHISPER"
        GuildNet.BeaconActivePeers[cleanSender] = true
        if GuildNet.RefreshAllVisibleNameplates then
            GuildNet.RefreshAllVisibleNameplates()
        end
        if cmd == "REP_HB" then
            ParseHBIntoTable(peer, payload)
            print(string.format("|cff00ff00[AltVault Sync]:|r |cffffff00%s|r accepted your sync request! Their Basic Profile is now unlocked.", cleanSender))
        elseif cmd == "REP_GEAR" then
            ParseGearIntoTable(peer, payload)
        elseif cmd == "REP_ALTS" then
            ParseAltListIntoTable(peer, payload)
        end
        ScheduleDebouncedNetUIRefresh()
        return
    end

    -- 6. All other packets require the sender to be an accepted Synced Peer in GuildNetwork!
    local peer = AltVaultDB.GuildNetwork[cleanSender]
    if not peer or peer.isSynced == false then
        return
    end

    peer.lastSeen = date("%Y-%m-%d %H:%M")
    peer.lastSeenTimestamp = time()
    peer.isOnline = true

    if cmd == "VCHAT" then
        local msgID, sClass, chatText = string.match(payload, "^([^|]+)|([^|]+)|(.*)$")
        if msgID and chatText and not seenChatMsgIDs[msgID] then
            seenChatMsgIDs[msgID] = true
            AppendChatHistory(cleanSender, sClass ~= "" and sClass or (peer.class or "WARRIOR"), chatText)
        end
        return
    elseif cmd == "VOTE" then
        local tName, vName, valStr = string.match(payload or "", "^([^|]+)|([^|]+)|([%-]?%d+)$")
        local numVal = tonumber(valStr)
        if tName and vName and numVal then
            if RecordIncomingVote(StripRealm(tName), StripRealm(vName), numVal) then
                ScheduleDebouncedNetUIRefresh()
            end
        end
        return
    elseif cmd == "DATA_BAGS_START" then
        peer.bags = {}
        peer.bagItems = {}
        peer.mats = peer.mats or {}
        peer.cons = peer.cons or {}
        peer.bagsSynced = true
        peer.bagsUnlocked = true
        print(string.format("|cff00ff00[AltVault Sync]:|r |cffffff00%s|r shared their |cff00ff96Bag Inventory|r with you!", cleanSender))
    elseif cmd == "DATA_BAGS" or cmd == "MATS" then
        peer.bags = peer.bags or {}
        peer.bagItems = peer.bagItems or {}
        peer.mats = peer.mats or {}
        peer.cons = peer.cons or {}
        peer.bagsSynced = true
        peer.bagsUnlocked = true
        for token in string.gmatch(payload or "", "([^,]+)") do
            local idStr, cntStr = string.match(token, "^(%d+):(%d+)$")
            local id, cnt = tonumber(idStr), tonumber(cntStr)
            if id and cnt then
                table.insert(peer.bags, { itemID = id, count = cnt })
                peer.bagItems[id] = (peer.bagItems[id] or 0) + cnt
                local _, _, _, _, _, itemType, _, _, _, _, _, classID, _, _, _, _, isReagent = ns.Scanner.FetchItemInfo(id)
                local isMat = (classID == 7) or (itemType == "Trade Goods") or (itemType == "Tradeskill") or (isReagent == true)
                local isCons = (classID == 0) or (itemType == "Consumable")
                if isMat then peer.mats[id] = cnt elseif isCons then peer.cons[id] = cnt end
            end
        end
    elseif cmd == "DATA_BANK_START" then
        peer.bank = {}
        peer.bankItems = {}
        peer.mats = peer.mats or {}
        peer.cons = peer.cons or {}
        peer.bankSynced = true
        peer.bankUnlocked = true
        print(string.format("|cff00ff00[AltVault Sync]:|r |cffffff00%s|r shared their |cff00ff96Personal Bank|r with you!", cleanSender))
    elseif cmd == "DATA_BANK" or cmd == "CONS" then
        peer.bank = peer.bank or {}
        peer.bankItems = peer.bankItems or {}
        peer.mats = peer.mats or {}
        peer.cons = peer.cons or {}
        peer.bankSynced = true
        peer.bankUnlocked = true
        for token in string.gmatch(payload or "", "([^,]+)") do
            local idStr, cntStr = string.match(token, "^(%d+):(%d+)$")
            local id, cnt = tonumber(idStr), tonumber(cntStr)
            if id and cnt then
                table.insert(peer.bank, { itemID = id, count = cnt })
                peer.bankItems[id] = (peer.bankItems[id] or 0) + cnt
                local _, _, _, _, _, itemType, _, _, _, _, _, classID, _, _, _, _, isReagent = ns.Scanner.FetchItemInfo(id)
                local isMat = (classID == 7) or (itemType == "Trade Goods") or (itemType == "Tradeskill") or (isReagent == true)
                local isCons = (classID == 0) or (itemType == "Consumable")
                if isMat then peer.mats[id] = (peer.mats[id] or 0) + cnt elseif isCons then peer.cons[id] = (peer.cons[id] or 0) + cnt end
            end
        end
    elseif cmd == "DATA_REC_START" then
        peer.recipesSynced = true
        peer.recipesUnlocked = true
        peer.recipes = peer.recipes or {}
        print(string.format("|cff00ff00[AltVault Sync]:|r |cffffff00%s|r shared their |cff00ff96Known Profession Recipes|r with you!", cleanSender))
    elseif cmd == "REC" then
        peer.recipesSynced = true
        peer.recipesUnlocked = true
        peer.recipes = peer.recipes or {}
        for entry in string.gmatch(payload or "", "([^;]+)") do
            local cIDStr, pCode, rRankStr, reagBlob = string.match(entry, "^(%d+):(%a%a):(%d+):(.*)$")
            local craftedID = tonumber(cIDStr)
            local profName = pCode and SHORT_TO_PROF[pCode]
            if craftedID and profName and reagBlob then
                peer.recipes[craftedID] = profName
                local reagents = {}
                for rPair in string.gmatch(reagBlob, "([^%+]+)") do
                    local rID, rCnt = string.match(rPair, "^(%d+)x(%d+)$")
                    if rID and rCnt then
                        table.insert(reagents, { id = tonumber(rID), count = tonumber(rCnt) or 1 })
                    end
                end
                local itemName = ns.Scanner and ns.Scanner.FetchItemInfo and ns.Scanner.FetchItemInfo(craftedID)
                SaveRecipeSchematic(craftedID, itemName, profName, tonumber(rRankStr) or 1, reagents, cleanSender)
            end
        end
    elseif cmd == "DATA_TAL_START" then
        local sName, tBuild = string.match(payload or "", "^([^|]*)|(.*)$")
        peer.specName = (sName and sName ~= "") and sName or peer.specName
        peer.talentBuild = (tBuild and tBuild ~= "") and tBuild or peer.talentBuild
        peer.talentTrees = {}
        peer.talentsSynced = true
        peer.talentsUnlocked = true
        print(string.format("|cff00ff00[AltVault Sync]:|r |cffffff00%s|r shared their |cff00ff96Talent Tree (%s)|r with you!", cleanSender, peer.talentBuild or "0/0/0"))
    elseif cmd == "DATA_TAL" then
        peer.talentTrees = peer.talentTrees or {}
        peer.talentsSynced = true
        peer.talentsUnlocked = true
        local tIdxStr, tName, ptsStr, talBlob = string.match(payload or "", "^(%d+)|([^|]+)|(%d+)|(.*)$")
        local tIdx = tonumber(tIdxStr)
        if tIdx and tName then
            peer.talentTrees[tIdx] = peer.talentTrees[tIdx] or {
                name = tName,
                points = tonumber(ptsStr) or 0,
                pointsSpent = tonumber(ptsStr) or 0,
                talents = {}
            }
            local treeObj = peer.talentTrees[tIdx]
            for tok in string.gmatch(talBlob or "", "([^;]+)") do
                local tierStr, talName, rStr, maxStr = string.match(tok, "^(%d+):([^:]+):(%d+):(%d+)$")
                if tierStr and talName then
                    table.insert(treeObj.talents, {
                        tier = tonumber(tierStr) or 1,
                        name = talName,
                        rank = tonumber(rStr) or 1,
                        maxRank = tonumber(maxStr) or 5
                    })
                end
            end
        end
    elseif cmd == "DATA_VGUILD" then
        peer.vguildSynced = true
        peer.vguildUnlocked = true
        peer.sharedPeers = {}
        if payload and payload ~= "-" then
            for tok in string.gmatch(payload, "([^,]+)") do
                local pName, pClass, pLvl = string.match(tok, "^([^:]+):([^:]+):(%d+)$")
                if pName and pClass then
                    table.insert(peer.sharedPeers, { name = pName, class = pClass, level = tonumber(pLvl) or 1 })
                end
            end
        end
        print(string.format("|cff00ff00[AltVault Sync]:|r |cffffff00%s|r shared their |cff00ff96Virtual Guild Roster (%d visible members)|r with you!", cleanSender, #peer.sharedPeers))
    elseif cmd == "DATA_ALT" then
        local aName, aClass, aLvl, aRace, aGS, profStr, aSpec, aBuild, gearStr, aSex =
            string.match(payload or "", "^([^|]+)|([^|]+)|(%d+)|([^|]+)|(%d+)|([^|]+)|([^|]+)|([^|]+)|([^|]+)|(%d+)$")
        if aName and aClass then
            peer.syncedAlts = peer.syncedAlts or {}
            local altObj = {
                name = aName,
                class = aClass,
                level = tonumber(aLvl) or 1,
                race = aRace,
                gearScore = tonumber(aGS) or 0,
                specName = aSpec,
                talentBuild = aBuild,
                sex = tonumber(aSex) or 2,
                profs = {},
                gear = {},
            }
            if profStr and profStr ~= "-" then
                for tok in string.gmatch(profStr, "([^,]+)") do
                    local code, rStr = string.match(tok, "^(%a%a):(%d+)$")
                    if code and SHORT_TO_PROF[code] then
                        altObj.profs[SHORT_TO_PROF[code]] = tonumber(rStr) or 1
                    end
                end
            end
            ParseGearIntoTable(altObj, gearStr)
            peer.syncedAlts[aName] = altObj
            print(string.format("|cff00ff00[AltVault Sync]:|r |cffffff00%s|r shared their Alt |cff00ff96%s (Lvl %d %s)|r with you!", cleanSender, aName, altObj.level, altObj.class))
        end
    end

    ScheduleDebouncedNetUIRefresh()
end

-- ============================================================================
-- BLOCK HEADING: OPEN-WORLD NAMEPLATE GLOW BEACON FOR ALTVAULT USERS
-- ============================================================================
local function ApplyAltVaultGlowToNameplate(unitToken, showGlow, peerName)
    if not C_NamePlate or not C_NamePlate.GetNamePlateForUnit or not unitToken then return end
    local ok, plate = pcall(C_NamePlate.GetNamePlateForUnit, unitToken)
    if not ok or not plate then return end

    if not showGlow then
        if plate.AltVaultBeaconFrame then
            plate.AltVaultBeaconFrame:Hide()
        end
        return
    end

    local beacon = plate.AltVaultBeaconFrame
    if not beacon then
        local createFn = (ns.Compat and ns.Compat.CreateBackdropFrame) or CreateFrame
        beacon = createFn("Button", nil, plate)
        beacon:SetPoint("TOPLEFT", plate, "TOPLEFT", -4, 4)
        beacon:SetPoint("BOTTOMRIGHT", plate, "BOTTOMRIGHT", 4, -4)
        beacon:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        if beacon.SetBackdrop then
            beacon:SetBackdrop({
                edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
                edgeSize = 12,
                insets = { left = 2, right = 2, top = 2, bottom = 2 }
            })
            beacon:SetBackdropBorderColor(0.0, 0.95, 1.0, 0.98)
        end

        beacon.GlowTex = beacon:CreateTexture(nil, "OVERLAY")
        beacon.GlowTex:SetPoint("TOPLEFT", beacon, "TOPLEFT", -2, 2)
        beacon.GlowTex:SetPoint("BOTTOMRIGHT", beacon, "BOTTOMRIGHT", 2, -2)
        beacon.GlowTex:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
        beacon.GlowTex:SetBlendMode("ADD")
        beacon.GlowTex:SetVertexColor(0.1, 0.95, 1.0, 0.55)

        beacon.Badge = beacon:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        beacon.Badge:SetPoint("BOTTOM", beacon, "TOP", 0, 2)
        beacon.Badge:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")

        beacon:SetScript("OnClick", function(self, button)
            if button == "RightButton" and self.peerName and GuildNet.RequestDirectWhisperSync then
                GuildNet.RequestDirectWhisperSync(self.peerName)
            elseif button == "LeftButton" and self.peerName and _G.AltVaultMainPanel then
                _G.AltVaultMainPanel:Show()
                if _G.AltVaultMainPanel.SelectSidebarCharacter then
                    _G.AltVaultMainPanel:SelectSidebarCharacter(self.peerName, true)
                end
            end
        end)

        plate.AltVaultBeaconFrame = beacon
    end

    beacon.peerName = peerName
    local rankScore = (peerName and GuildNet.GetCharacterRatingSummary and GuildNet.GetCharacterRatingSummary(peerName)) or 0
    local rankSuffix = (rankScore > 0 and string.format(" |cffffd100(+%d)|r", rankScore))
        or (rankScore < 0 and string.format(" |cffff4444(%d)|r", rankScore))
        or ""
    local isAlreadySynced = (AltVaultDB and AltVaultDB.GuildNetwork and peerName and AltVaultDB.GuildNetwork[peerName] and AltVaultDB.GuildNetwork[peerName].isSynced ~= false)
    if isAlreadySynced then
        beacon.Badge:SetText("|cff00ff00★ [FaceVault" .. rankSuffix .. "|cff00ff00]|r")
        if beacon.SetBackdropBorderColor then beacon:SetBackdropBorderColor(0.15, 1.0, 0.35, 0.98) end
        beacon.GlowTex:SetVertexColor(0.15, 1.0, 0.35, 0.50)
    else
        beacon.Badge:SetText("|cff00ffff★ [FaceVault" .. rankSuffix .. "|cff00ffff]|r")
        if beacon.SetBackdropBorderColor then beacon:SetBackdropBorderColor(0.0, 0.92, 1.0, 0.98) end
        beacon.GlowTex:SetVertexColor(0.0, 0.92, 1.0, 0.55)
    end
    beacon:Show()
end

function GuildNet.RefreshAllVisibleNameplates()
    if not C_NamePlate or not C_NamePlate.GetNamePlates then return end
    local ok, plates = pcall(C_NamePlate.GetNamePlates)
    if not ok or type(plates) ~= "table" then return end

    for _, plate in ipairs(plates) do
        local uToken = plate.namePlateUnitToken or (plate.UnitFrame and plate.UnitFrame.unit)
        if uToken and UnitExists(uToken) and UnitIsPlayer and UnitIsPlayer(uToken) then
            local pName = StripRealm(UnitName(uToken))
            local hasGlow = pName and (
                GuildNet.BeaconActivePeers[pName] == true
                or (AltVaultDB and AltVaultDB.GuildNetwork and AltVaultDB.GuildNetwork[pName] and AltVaultDB.GuildNetwork[pName].beaconOn ~= false)
            )
            ApplyAltVaultGlowToNameplate(uToken, hasGlow, pName)
        elseif plate.AltVaultBeaconFrame then
            plate.AltVaultBeaconFrame:Hide()
        end
    end
end

function GuildNet.BroadcastNameplateBeaconState(isEnabled, isPing)
    local isOn = (isEnabled ~= false) and not (AltVaultDB and AltVaultDB.SyncDND)
    local pkt = (isPing and "BEACON_PING|" or "BEACON|") .. (isOn and "1" or "0")
    EnqueuePacket(pkt, "YELL")
    if IsInGuild and IsInGuild() then
        EnqueuePacket(pkt, "GUILD")
    end
    if IsInRaid and IsInRaid() then
        EnqueuePacket(pkt, "RAID")
    elseif IsInGroup and IsInGroup() then
        EnqueuePacket(pkt, "PARTY")
    end
end

NetFrame:SetScript("OnEvent", function(self, event, arg1, arg2, arg3, arg4)
    if event == "PLAYER_LOGIN" then
        EnsureGuildNetTables()
        if AltVaultDB and AltVaultDB.NameplateGlowEnabled == nil then
            AltVaultDB.NameplateGlowEnabled = true
        end
        if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
            pcall(C_ChatInfo.RegisterAddonMessagePrefix, PREFIX)
        elseif RegisterAddonMessagePrefix then
            pcall(RegisterAddonMessagePrefix, PREFIX)
        end
    elseif event == "CHAT_MSG_ADDON" then
        OnAddonMessageReceived(arg1, arg2, arg3, arg4)
    elseif event == "NAME_PLATE_UNIT_ADDED" then
        local unitToken = arg1
        if unitToken and UnitIsPlayer and UnitIsPlayer(unitToken) then
            local pName = StripRealm(UnitName(unitToken))
            if pName and pName ~= UnitName("player") then
                local hasGlow = (GuildNet.BeaconActivePeers[pName] == true)
                    or (AltVaultDB and AltVaultDB.GuildNetwork and AltVaultDB.GuildNetwork[pName] and AltVaultDB.GuildNetwork[pName].beaconOn ~= false)
                ApplyAltVaultGlowToNameplate(unitToken, hasGlow, pName)

                local now = GetTime and GetTime() or 0
                if (now - lastBeaconBroadcastTime) >= 12 then
                    lastBeaconBroadcastTime = now
                    local myGlowOn = (not AltVaultDB or AltVaultDB.NameplateGlowEnabled ~= false) and not (AltVaultDB and AltVaultDB.SyncDND)
                    if myGlowOn then
                        GuildNet.BroadcastNameplateBeaconState(true, true)
                    end
                end
            end
        elseif unitToken then
            ApplyAltVaultGlowToNameplate(unitToken, false, nil)
        end
    elseif event == "NAME_PLATE_UNIT_REMOVED" then
        local unitToken = arg1
        if unitToken then
            ApplyAltVaultGlowToNameplate(unitToken, false, nil)
        end
    elseif event == "TRADE_SKILL_SHOW" or event == "CRAFT_SHOW" then
        C_Timer.After(0.25, function()
            GuildNet.ScanOpenProfessionRecipes()
        end)
    end
end)