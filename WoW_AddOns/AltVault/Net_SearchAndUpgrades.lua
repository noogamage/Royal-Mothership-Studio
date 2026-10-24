-- ============================================================================
-- FILE: Net_SearchAndUpgrades.lua (MODULE 3 OF 3 SPLIT FROM Engine_GuildNetwork.lua)
-- BLOCK HEADING: CROSS-REFERENCE MATERIAL LOCATOR (ALTS + VAULT + SYNCED PEERS)
-- ============================================================================
local addonName, ns = ...
local GuildNet = ns.GuildNet or {}
ns.GuildNet = GuildNet

local EnsureGuildNetTables = GuildNet.EnsureGuildNetTables
local ExtractID = GuildNet.ExtractID
local GetConsumableCategory = GuildNet.GetConsumableCategory

function GuildNet.LocateMaterialAcrossNetwork(itemID, faction)
    local report = {
        itemID = itemID,
        totalAvailable = 0,
        sources = {},
        holdersToWhisper = {}
    }
    if not itemID or not AltVaultDB then return report end

    local playerName = UnitName("player")
    local isLockedLocally = (ns.DB and ns.DB.IsItemTradeLocked and ns.DB.IsItemTradeLocked(itemID)) or false

    if not isLockedLocally then
        for charName, cData in pairs(AltVaultDB.Characters or {}) do
            if not faction or cData.faction == faction then
                local bagCnt, bankCnt = 0, 0
                for _, bItem in ipairs(cData.bags or {}) do
                    local id = ExtractID(bItem.link or bItem.itemID)
                    if id == itemID then bagCnt = bagCnt + (tonumber(bItem.count) or 1) end
                end
                for _, kItem in ipairs(cData.bank or {}) do
                    local id = ExtractID(kItem.link or kItem.itemID)
                    if id == itemID then bankCnt = bankCnt + (tonumber(kItem.count) or 1) end
                end
                if bagCnt > 0 then
                    report.totalAvailable = report.totalAvailable + bagCnt
                    table.insert(report.sources, {
                        owner = charName,
                        isSelfAccount = true,
                        location = (charName == playerName) and "Your Bags" or (charName .. "'s Bags (Alt)"),
                        count = bagCnt
                    })
                end
                if bankCnt > 0 then
                    report.totalAvailable = report.totalAvailable + bankCnt
                    table.insert(report.sources, {
                        owner = charName,
                        isSelfAccount = true,
                        location = (charName == playerName) and "Your Personal Bank" or (charName .. "'s Bank (Alt)"),
                        count = bankCnt
                    })
                end
            end
        end

        for gName, vData in pairs(AltVaultDB.GuildVaults or {}) do
            if not faction or vData.faction == faction then
                for tIdx = 1, 8 do
                    local tab = vData.tabs and vData.tabs[tIdx]
                    if tab then
                        local tabCnt = 0
                        for _, gItem in ipairs(tab.items or {}) do
                            if ExtractID(gItem.link) == itemID then
                                tabCnt = tabCnt + (tonumber(gItem.count) or 1)
                            end
                        end
                        if tabCnt > 0 then
                            report.totalAvailable = report.totalAvailable + tabCnt
                            table.insert(report.sources, {
                                owner = "<" .. gName .. ">",
                                isGuildVault = true,
                                location = string.format("Outside Guild Vault [%s]", tab.name or ("Tab " .. tIdx)),
                                count = tabCnt
                            })
                        end
                    end
                end
            end
        end
    end

    for peerName, peerData in pairs(AltVaultDB.GuildNetwork or {}) do
        if not (AltVaultDB.Characters and AltVaultDB.Characters[peerName]) then
            if not faction or peerData.faction == faction then
                local peerCnt = peerData.mats and peerData.mats[itemID] or 0
                if peerCnt > 0 then
                    report.totalAvailable = report.totalAvailable + peerCnt
                    local onlineBadge = GuildNet.IsPeerOnline(peerName) and "Online" or ("Last Seen " .. (peerData.lastSeen or "Offline"))
                    table.insert(report.sources, {
                        owner = peerName,
                        isGuildmate = true,
                        lastSeen = peerData.lastSeen or "Synced",
                        location = string.format("%s (%s)", peerName, onlineBadge),
                        count = peerCnt
                    })
                    table.insert(report.holdersToWhisper, peerName)
                end
                if type(peerData.guildVault) == "table" then
                    for tabName, tabItems in pairs(peerData.guildVault) do
                        local gvCnt = tabItems and tabItems[itemID] or 0
                        if gvCnt > 0 then
                            report.totalAvailable = report.totalAvailable + gvCnt
                            table.insert(report.sources, {
                                owner = peerName,
                                isGuildmate = true,
                                isGuildVault = true,
                                location = string.format("<%s> Vault [%s] via %s", peerData.guild or "Outside Guild", tabName, peerName),
                                count = gvCnt
                            })
                            table.insert(report.holdersToWhisper, peerName)
                        end
                    end
                end
            end
        end
    end

    return report
end

-- ============================================================================
-- BLOCK HEADING: CRAFTABLE GEAR UPGRADE MATCHER (ALTS + LOCKED-IN SYNCED PEERS)
-- ============================================================================
local function GetUnifiedRosterTargets(faction)
    local targets = {}
    if not AltVaultDB then return targets end

    for charName, cData in pairs(AltVaultDB.Characters or {}) do
        if not faction or cData.faction == faction then
            table.insert(targets, {
                name = charName,
                isAccountAlt = true,
                class = cData.class or "WARRIOR",
                level = cData.level or 1,
                specRole = cData.specRole or "MELEE_STR",
                gear = cData.gear,
                slotGS = nil,
                lastSeen = cData.lastSeen or "Account Alt"
            })
        end
    end

    for peerName, pData in pairs(AltVaultDB.GuildNetwork or {}) do
        if not (AltVaultDB.Characters and AltVaultDB.Characters[peerName]) then
            if not faction or pData.faction == faction then
                table.insert(targets, {
                    name = peerName,
                    isGuildmate = true,
                    class = pData.class or "WARRIOR",
                    level = pData.level or 1,
                    specRole = pData.specRole or "MELEE_STR",
                    gear = pData.gear,
                    slotGS = pData.slotGS or {},
                    lastSeen = pData.lastSeen or "Synced"
                })
            end
        end
    end

    return targets
end

local function CheckCraftedItemUpgradesTarget(target, craftedID)
    if not ns.Scanner then return false end
    local link = "item:" .. tostring(craftedID)
    local isSuited, targetSlots, reqLvl, equipLoc = ns.Scanner.CanAltUseAndWantItem(target, link)
    if not isSuited or not targetSlots then return false end

    local lvlDiff = (reqLvl or 1) - (target.level or 60)
    if lvlDiff > 4 or (target.level - (reqLvl or 1)) > 18 then
        return false
    end

    local craftedGS = ns.Scanner.CalculateItemGearScore(link)
    if not craftedGS or craftedGS <= 0 then return false end

    if target.isAccountAlt then
        local isUpg, delta, status = ns.Scanner.CheckItemUpgradeForAlt(target.name, link)
        if isUpg and delta and delta > 0 then
            return true, delta, status, reqLvl
        end
        return false
    end

    local bestDelta = 0
    if equipLoc == "INVTYPE_2HWEAPON" then
        local curMain = (target.slotGS and target.slotGS[16]) or 0
        local curOff  = (target.slotGS and target.slotGS[17]) or 0
        if craftedGS > (curMain + curOff) then
            bestDelta = craftedGS - (curMain + curOff)
        end
    else
        for _, sID in ipairs(targetSlots) do
            local curGS = (target.slotGS and target.slotGS[sID]) or 0
            if craftedGS > curGS then
                bestDelta = math.max(bestDelta, craftedGS - curGS)
            end
        end
    end

    if bestDelta > 0 then
        local status = (lvlDiff >= 1 and lvlDiff <= 4) and "UPGRADE_SOON" or "UPGRADE"
        return true, bestDelta, status, reqLvl
    end
    return false
end

function GuildNet.GetCraftableGearUpgrades(faction)
    local results = {}
    if not EnsureGuildNetTables() or not ns.Scanner then return results end

    local targets = GetUnifiedRosterTargets(faction)

    for craftedID, rData in pairs(AltVaultDB.RecipeDB) do
        local itemName, itemLink, _, _, _, _, _, _, equipLoc, icon = ns.Scanner.FetchItemInfo(craftedID)
        if itemName and equipLoc and equipLoc ~= "" and equipLoc ~= "INVTYPE_NON_EQUIP_IGNORE" and equipLoc ~= "INVTYPE_BAG" then
            local allMatsReady = true
            local matSummaryParts = {}
            for _, rg in ipairs(rData.reagents or {}) do
                local locReport = GuildNet.LocateMaterialAcrossNetwork(rg.id, faction)
                local have = locReport.totalAvailable or 0
                local need = rg.count or 1
                if have < need then
                    allMatsReady = false
                end
                local rName = (ns.Scanner.FetchItemInfo(rg.id)) or rg.name or ("Mat #" .. rg.id)
                local color = (have >= need) and "|cff00ff00" or "|cffff5555"
                table.insert(matSummaryParts, string.format("%s%d/%d %s|r", color, have, need, rName))
            end

            local crafterNames = {}
            for cName in pairs(rData.crafters or {}) do
                table.insert(crafterNames, cName)
            end
            table.sort(crafterNames)
            local crafterStr = (#crafterNames > 0) and table.concat(crafterNames, ", ") or (rData.prof or "Crafter")

            for _, target in ipairs(targets) do
                local isUpg, delta, status, reqLvl = CheckCraftedItemUpgradesTarget(target, craftedID)
                if isUpg then
                    table.insert(results, {
                        craftedID     = craftedID,
                        itemLink      = itemLink or ("item:" .. craftedID),
                        itemName      = itemName,
                        icon          = icon or "Interface\\Icons\\INV_Misc_QuestionMark",
                        prof          = rData.prof,
                        reqSkill      = rData.rank or 1,
                        crafters      = crafterStr,
                        targetName    = target.name,
                        targetClass   = target.class,
                        targetLevel   = target.level,
                        targetSeen    = target.lastSeen,
                        isGuildmate   = target.isGuildmate,
                        deltaGS       = delta,
                        status        = status,
                        reqLvl        = reqLvl or 1,
                        allMatsReady  = allMatsReady,
                        matSummary    = (#matSummaryParts > 0) and table.concat(matSummaryParts, ", ") or "Reagents Ready",
                        reagents      = rData.reagents or {}
                    })
                end
            end
        end
    end

    table.sort(results, function(a, b)
        if a.allMatsReady ~= b.allMatsReady then return a.allMatsReady end
        if a.deltaGS ~= b.deltaGS then return a.deltaGS > b.deltaGS end
        return a.targetName < b.targetName
    end)

    return results
end

function GuildNet.GetMaterialCraftUpgradeNotes(itemLinkOrID, faction)
    local matID = ExtractID(itemLinkOrID)
    if not matID or not EnsureGuildNetTables() then return nil end

    local upgrades = GuildNet.GetCraftableGearUpgrades(faction)
    local matches = {}
    for _, u in ipairs(upgrades) do
        for _, rg in ipairs(u.reagents or {}) do
            if rg.id == matID then
                table.insert(matches, u)
                break
            end
        end
    end
    return (#matches > 0) and matches or nil
end

-- ============================================================================
-- BLOCK HEADING: GUILD CONSUMABLES AGGREGATOR (POTIONS, SCROLLS, FOOD, BANDAGES)
-- ============================================================================
function GuildNet.GetGuildConsumablesList(faction, categoryFilter)
    local byItemID = {}
    if not EnsureGuildNetTables() or not ns.Scanner then return {} end

    local function AddConsEntry(id, count, holderText, whisperName)
        if not id or not count or count <= 0 then return end
        local name, link, quality, iLvl, reqLvl, itemType, itemSubType, _, equipLoc, icon, _, classID =
            ns.Scanner.FetchItemInfo(id)
        if not name then return end
        if classID ~= 0 and itemType ~= "Consumable" then return end
        if equipLoc and equipLoc ~= "" and equipLoc ~= "INVTYPE_NON_EQUIP_IGNORE" then return end

        local cat = GetConsumableCategory(id, name, itemSubType, equipLoc)
        if categoryFilter and categoryFilter ~= "ALL" and cat ~= categoryFilter then
            return
        end

        byItemID[id] = byItemID[id] or {
            itemID = id,
            name = name,
            link = link or ("item:" .. id),
            icon = icon or "Interface\\Icons\\INV_Potion_51",
            quality = quality or 1,
            iLvl = iLvl or 1,
            reqLvl = reqLvl or 1,
            category = cat,
            totalCount = 0,
            holders = {},
            firstWhisperTarget = nil
        }
        local rec = byItemID[id]
        rec.totalCount = rec.totalCount + count
        table.insert(rec.holders, string.format("%s (%dx)", holderText, count))
        if whisperName and not rec.firstWhisperTarget then
            rec.firstWhisperTarget = whisperName
        end
    end

    for charName, cData in pairs(AltVaultDB.Characters or {}) do
        if not faction or cData.faction == faction then
            local perCharCounts = {}
            for _, item in ipairs(cData.bags or {}) do
                local id = ExtractID(item.link or item.itemID)
                if id and not (ns.DB and ns.DB.IsItemTradeLocked and ns.DB.IsItemTradeLocked(id)) then
                    perCharCounts[id] = (perCharCounts[id] or 0) + (tonumber(item.count) or 1)
                end
            end
            for _, item in ipairs(cData.bank or {}) do
                local id = ExtractID(item.link or item.itemID)
                if id and not (ns.DB and ns.DB.IsItemTradeLocked and ns.DB.IsItemTradeLocked(id)) then
                    perCharCounts[id] = (perCharCounts[id] or 0) + (tonumber(item.count) or 1)
                end
            end
            for id, cnt in pairs(perCharCounts) do
                AddConsEntry(id, cnt, "|cff00ff96" .. charName .. " (Alt)|r", nil)
            end
        end
    end

    for _, vData in pairs(AltVaultDB.GuildVaults or {}) do
        if not faction or vData.faction == faction then
            for tIdx = 1, 8 do
                local tab = vData.tabs and vData.tabs[tIdx]
                if tab then
                    local perTabCounts = {}
                    for _, item in ipairs(tab.items or {}) do
                        local id = ExtractID(item.link)
                        if id and not (ns.DB and ns.DB.IsItemTradeLocked and ns.DB.IsItemTradeLocked(id)) then
                            perTabCounts[id] = (perTabCounts[id] or 0) + (tonumber(item.count) or 1)
                        end
                    end
                    for id, cnt in pairs(perTabCounts) do
                        AddConsEntry(id, cnt, "|cffffd100Vault [" .. (tab.name or ("Tab " .. tIdx)) .. "]|r", nil)
                    end
                end
            end
        end
    end

    for peerName, peerData in pairs(AltVaultDB.GuildNetwork or {}) do
        if not (AltVaultDB.Characters and AltVaultDB.Characters[peerName]) then
            if not faction or peerData.faction == faction then
                for id, cnt in pairs(peerData.cons or {}) do
                    AddConsEntry(id, cnt, "|cff00ccff" .. peerName .. " (Synced)|r", peerName)
                end
                if type(peerData.guildVault) == "table" then
                    for tabName, tabItems in pairs(peerData.guildVault) do
                        for id, cnt in pairs(tabItems or {}) do
                            AddConsEntry(id, cnt, "|cffffd100<" .. (peerData.guild or "Outside Guild") .. "> [" .. tabName .. "]|r", peerName)
                        end
                    end
                end
            end
        end
    end

    local list = {}
    for _, rec in pairs(byItemID) do
        local rEntry = AltVaultDB.RecipeDB[rec.itemID]
        if rEntry and rEntry.crafters then
            local cList = {}
            for cName in pairs(rEntry.crafters) do table.insert(cList, cName) end
            if #cList > 0 then
                rec.crafterNote = "Craftable by: " .. table.concat(cList, ", ")
            end
        end
        table.insert(list, rec)
    end

    table.sort(list, function(a, b)
        if a.category ~= b.category then return a.category < b.category end
        if a.reqLvl ~= b.reqLvl then return a.reqLvl > b.reqLvl end
        return a.totalCount > b.totalCount
    end)

    return list
end