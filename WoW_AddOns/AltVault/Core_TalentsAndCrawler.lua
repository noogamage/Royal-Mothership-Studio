-- ============================================================================
-- FILE: Core_TalentsAndCrawler.lua (MODULE 3 OF 4 SPLIT FROM Core_Database.lua)
-- BLOCK HEADING: CONTROLLABLE BACKGROUND SERVER SCANNER (WITH AUTO-RESTART FIX)
-- ============================================================================
local addonName, ns = ...
ns.DB = ns.DB or {}

local ScanTip = ns.DB.ScanTip
local CLASS_TALENT_SPECS = ns.DB.CLASS_TALENT_SPECS
local DEFAULT_CLASS_ROLE = ns.DB.DEFAULT_CLASS_ROLE

local bgScannerStarted = false
local isTurboScan = false
local stealthTicker = nil

function ns.DB.GetDatabaseStats()
    local items, patterns, reagents = 0, 0, 0
    if AltVaultDB then
        for _ in pairs(AltVaultDB.ItemCache or {}) do items = items + 1 end
        for _ in pairs(AltVaultDB.PatternDB or {}) do patterns = patterns + 1 end
        for _ in pairs(AltVaultDB.ReagentDB or {}) do reagents = reagents + 1 end
    end
    if ns.ForeverIndex and ns.ForeverIndex.Count then
        items = math.max(items, ns.ForeverIndex:Count() or 0)
    end
    return items, patterns, reagents
end

function ns.DB.IsScannerPaused()
    if not AltVaultDB then return true end
    -- STEALTH MODE DEFAULT: Paused by default so zero unsolicited server item queries are sent!
    if AltVaultDB.ScannerPaused == nil then
        AltVaultDB.ScannerPaused = true
    end
    return AltVaultDB.ScannerPaused == true
end

function ns.DB.SetScannerPaused(paused)
    if not AltVaultDB then return end
    AltVaultDB.ScannerPaused = paused and true or false
    if AltVaultDB.ScannerPaused then
        isTurboScan = false
        if stealthTicker and stealthTicker.Cancel then
            stealthTicker:Cancel()
            stealthTicker = nil
        end
        bgScannerStarted = false
    else
        if (AltVaultDB.CrawlCursorID or 1) >= (ns.DB.MAX_CRAWL_ID or 250000) then
            AltVaultDB.CrawlCursorID = 1
        end
        if ns.DB.StartSilentBackgroundScanner then
            ns.DB.StartSilentBackgroundScanner()
        end
    end
end

function ns.DB.SetTurboMode(enabled)
    isTurboScan = enabled and true or false
    if isTurboScan and AltVaultDB then
        AltVaultDB.ScannerPaused = false
        if ns.DB.StartSilentBackgroundScanner then
            ns.DB.StartSilentBackgroundScanner()
        end
    end
end

function ns.DB.IsTurboMode()
    return isTurboScan
end

function ns.DB.SetCrawlCursor(newID)
    if AltVaultDB and type(newID) == "number" then
        AltVaultDB.CrawlCursorID = math.max(1, math.min(ns.DB.MAX_CRAWL_ID or 250000, math.floor(newID)))
    end
end

local function StartSilentBackgroundScanner()
    if bgScannerStarted then return end
    if ns.DB.IsScannerPaused() then return end
    bgScannerStarted = true

    -- STEALTH ON-DEMAND CRAWLER: Only queries verified ForeverIndex item IDs (never blind-queries invalid IDs!)
    stealthTicker = C_Timer.NewTicker(0.65, function()
        if not AltVaultDB or ns.DB.IsScannerPaused() or InCombatLockdown() then
            if AltVaultDB and AltVaultDB.ScannerPaused and stealthTicker and stealthTicker.Cancel then
                stealthTicker:Cancel()
                stealthTicker = nil
                bgScannerStarted = false
            end
            return
        end
        if not ns.Scanner or not ns.Scanner.CacheItemData then return end

        local validIDs = (ns.ForeverIndex and ns.ForeverIndex.GetAllIDs and ns.ForeverIndex:GetAllIDs()) or nil
        if not validIDs or #validIDs == 0 then return end

        AltVaultDB.ForeverScanIdx = AltVaultDB.ForeverScanIdx or 0
        local batchSize = isTurboScan and 6 or 2
        local checked = 0

        while checked < batchSize and AltVaultDB.ForeverScanIdx < #validIDs do
            AltVaultDB.ForeverScanIdx = AltVaultDB.ForeverScanIdx + 1
            local itemID = validIDs[AltVaultDB.ForeverScanIdx]
            AltVaultDB.CrawlCursorID = itemID or AltVaultDB.ForeverScanIdx
            if itemID and not (AltVaultDB.ItemCache and AltVaultDB.ItemCache[itemID]) then
                ns.Scanner.CacheItemData(itemID, true)
                checked = checked + 1
            end
        end

        if AltVaultDB.ForeverScanIdx >= #validIDs then
            AltVaultDB.ForeverScanIdx = 0
            AltVaultDB.ScannerPaused = true
            isTurboScan = false
            if stealthTicker and stealthTicker.Cancel then
                stealthTicker:Cancel()
                stealthTicker = nil
            end
            bgScannerStarted = false
        end
    end)
end

ns.DB.StartSilentBackgroundScanner = StartSilentBackgroundScanner

SLASH_ALTVAULTSTOP1 = "/avstop"
SlashCmdList["ALTVAULTSTOP"] = function()
    if not AltVaultDB then return end
    local newPaused = not AltVaultDB.ScannerPaused
    ns.DB.SetScannerPaused(newPaused)
    if newPaused then
        print("|cffffcc00[AltVault]:|r Background server scanner |cffff4444STOPPED|r. (Type |cffffff00/avstop|r or click |cff00ff00[Resume Scan]|r in Tab 6 to resume.)")
    else
        print("|cff00ff00[AltVault]:|r Background server scanner |cff00ff00RESUMED|r (Cursor at ID #" .. tostring(AltVaultDB.CrawlCursorID or 150) .. ").")
    end
    if AltVaultMainPanel and AltVaultMainPanel.UpdateScannerMeter then
        AltVaultMainPanel:UpdateScannerMeter()
    end
end

-- ============================================================================
-- BLOCK HEADING: 3-ENGINE TALENT SCANNER (16001 C_TRAITS, MOP 6-TIER, 3.3.5a)
-- ============================================================================
local function ExtractTalentDescription(tabIndex, talentIndex, spellID)
    if spellID and spellID > 0 then
        if C_Spell and C_Spell.GetSpellDescription then
            local ok, desc = pcall(C_Spell.GetSpellDescription, spellID)
            if ok and desc and desc ~= "" then return desc end
        end
        if GetSpellDescription then
            local ok, desc = pcall(GetSpellDescription, spellID)
            if ok and desc and desc ~= "" then return desc end
        end
    end

    ScanTip:ClearLines()
    ScanTip:SetOwner(WorldFrame, "ANCHOR_NONE")

    local loaded = false
    if spellID and spellID > 0 and ScanTip.SetSpellByID then
        loaded = pcall(ScanTip.SetSpellByID, ScanTip, spellID)
    end
    if (not loaded or (ScanTip:NumLines() or 0) <= 1) and ScanTip.SetTalent and talentIndex then
        pcall(ScanTip.SetTalent, ScanTip, tabIndex, talentIndex)
    end

    local numLines = ScanTip:NumLines() or 0
    local descLines = {}
    for i = 2, numLines do
        local leftText = _G["AltVaultTalentScanTooltipTextLeft" .. i]
        local text = leftText and leftText:GetText()
        if text and text ~= ""
            and not string.find(text, "^Rank %d")
            and not string.find(text, "^Next rank")
            and not string.find(text, "^Requires ")
            and not string.find(text, "Click to learn")
            and not string.find(text, "Instant$") then
            table.insert(descLines, text)
        end
    end

    if #descLines > 0 then
        return table.concat(descLines, "\n")
    end
    return "Talent ability active in this specialization tree."
end

-- ENGINE A: WoW: Forever 16001 3-Column C_Traits Canvas Scanner
local function ScanForeverTraitCanvas(classSpecs)
    if not C_Traits or not C_ClassTalents or not C_ClassTalents.GetActiveConfigID then
        return nil
    end

    local okCfg, configID = pcall(C_ClassTalents.GetActiveConfigID)
    if not okCfg or not configID then return nil end

    local okInfo, configInfo = pcall(C_Traits.GetConfigInfo, configID)
    local treeIDs = okInfo and configInfo and configInfo.treeIDs
    if not treeIDs or #treeIDs == 0 then return nil end

    local specBuckets = {}
    for s = 1, 3 do
        local specMeta = (classSpecs and classSpecs[s]) or { name = "Spec " .. s, icon = "Interface\\Icons\\Spell_Nature_StarFall" }
        specBuckets[s] = {
            name = specMeta.name,
            icon = specMeta.icon,
            role = specMeta.role,
            points = 0,
            talents = {}
        }
    end

    local allNodes = {}
    local minX, maxX = 999999, -999999
    local distinctY = {}

    for tIdx, treeID in ipairs(treeIDs) do
        local okNodes, nodeIDs = pcall(C_Traits.GetTreeNodes, treeID)
        nodeIDs = (okNodes and nodeIDs) or {}
        for _, nodeID in ipairs(nodeIDs) do
            local okN, nodeInfo = pcall(C_Traits.GetNodeInfo, configID, nodeID)
            if okN and nodeInfo and nodeInfo.posX and nodeInfo.posY and (nodeInfo.maxRanks or 0) > 0 then
                local px, py = nodeInfo.posX, nodeInfo.posY
                if px < minX then minX = px end
                if px > maxX then maxX = px end

                local matchedRowY = nil
                for _, existingY in ipairs(distinctY) do
                    if math.abs(py - existingY) < 150 then
                        matchedRowY = existingY
                        break
                    end
                end
                if not matchedRowY then
                    table.insert(distinctY, py)
                end

                table.insert(allNodes, {
                    nodeID = nodeID,
                    info = nodeInfo,
                    treeIndex = (#treeIDs >= 3) and tIdx or nil
                })
            end
        end
    end

    if #allNodes == 0 then return nil end

    table.sort(distinctY, function(a, b) return a < b end)

    local function GetExactTierForY(py)
        local bestTier = 1
        local bestDist = 999999
        for tierIdx, rowY in ipairs(distinctY) do
            local dist = math.abs(py - rowY)
            if dist < bestDist then
                bestDist = dist
                bestTier = tierIdx
            end
        end
        return bestTier
    end

    local xSpan = math.max(1, maxX - minX)
    local leftBoundary  = minX + (xSpan * 0.333)
    local rightBoundary = minX + (xSpan * 0.666)

    local function GetSpecIndexForNode(nodeWrapper)
        if nodeWrapper.treeIndex and nodeWrapper.treeIndex >= 1 and nodeWrapper.treeIndex <= 3 then
            return nodeWrapper.treeIndex
        end
        local px = nodeWrapper.info.posX or minX
        if px <= leftBoundary then
            return 1
        elseif px <= rightBoundary then
            return 2
        else
            return 3
        end
    end

    for _, nodeWrapper in ipairs(allNodes) do
        local nodeInfo = nodeWrapper.info
        local rank = nodeInfo.activeRank or nodeInfo.currentRank or 0
        if rank > 0 then
            local entryID = (nodeInfo.activeEntry and nodeInfo.activeEntry.entryID) or (nodeInfo.entryIDs and nodeInfo.entryIDs[1])
            local okE, entryInfo = pcall(C_Traits.GetEntryInfo, configID, entryID)
            local okD, defInfo = false, nil
            if okE and entryInfo and entryInfo.definitionID then
                okD, defInfo = pcall(C_Traits.GetDefinitionInfo, entryInfo.definitionID)
            end
            local spellID = okD and defInfo and defInfo.spellID

            local sName, sIcon
            if spellID then
                sName = (C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(spellID)) or (GetSpellInfo and GetSpellInfo(spellID))
                sIcon = (C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(spellID)) or (GetSpellTexture and GetSpellTexture(spellID))
            end
            if (not sName or sName == "") and defInfo then
                sName = defInfo.overrideName
                sIcon = defInfo.overrideIcon
            end

            if sName and sName ~= "" then
                local specIdx = GetSpecIndexForNode(nodeWrapper)
                local exactTier = GetExactTierForY(nodeInfo.posY)
                local desc = ExtractTalentDescription(specIdx, nil, spellID)

                local bucket = specBuckets[specIdx]
                bucket.points = bucket.points + rank
                table.insert(bucket.talents, {
                    name = sName,
                    icon = sIcon or "Interface\\Icons\\INV_Misc_QuestionMark",
                    tier = exactTier,
                    col = nodeInfo.posX or 1,
                    rank = rank,
                    maxRank = nodeInfo.maxRanks or 5,
                    minLevel = 10 + ((exactTier - 1) * 5),
                    desc = desc
                })
            end
        end
    end

    for s = 1, 3 do
        table.sort(specBuckets[s].talents, function(a, b)
            if a.tier ~= b.tier then return a.tier < b.tier end
            return (a.col or 1) < (b.col or 1)
        end)
    end

    return specBuckets
end

-- ENGINE B: Mists of Pandaria Classic 6-Tier Talent Grid & Specialization Scanner
local function ScanMoPTalentGrid(classSpecs)
    if C_Traits and C_ClassTalents and C_ClassTalents.GetActiveConfigID then
        local okCfg, cfgID = pcall(C_ClassTalents.GetActiveConfigID)
        if okCfg and cfgID then return nil end
    end

    local getSpecFn = (C_SpecializationInfo and C_SpecializationInfo.GetSpecialization) or _G.GetSpecialization
    local getSpecInfoFn = (C_SpecializationInfo and C_SpecializationInfo.GetSpecializationInfo) or _G.GetSpecializationInfo
    if not getSpecFn then return nil end

    local okSpec, activeSpecIdx = pcall(getSpecFn)
    if not okSpec then return nil end
    if type(activeSpecIdx) ~= "number" or activeSpecIdx < 1 or activeSpecIdx > 4 then
        activeSpecIdx = 1
    end

    local specName, specIcon = nil, nil
    if getSpecInfoFn then
        local okInfo, r1, r2, r3, r4 = pcall(getSpecInfoFn, activeSpecIdx)
        if okInfo then
            if type(r2) == "string" and r2 ~= "" then
                specName = r2
                specIcon = r4
            elseif type(r1) == "string" and r1 ~= "" then
                specName = r1
                specIcon = r3
            end
        end
    end

    local maxSpecCount = (classSpecs and #classSpecs) or 3
    local specBuckets = {}
    for s = 1, maxSpecCount do
        local specMeta = (classSpecs and classSpecs[s]) or { name = "Spec " .. s, icon = "Interface\\Icons\\Spell_Nature_StarFall" }
        specBuckets[s] = {
            name = (s == activeSpecIdx and specName and specName ~= "") and specName or specMeta.name,
            icon = (s == activeSpecIdx and specIcon) or specMeta.icon,
            role = specMeta.role,
            points = 0,
            talents = {}
        }
    end

    local activeBucket = specBuckets[activeSpecIdx] or specBuckets[1]
    if not activeBucket then return nil end

    local activeTalentGroup = 1
    if C_SpecializationInfo and C_SpecializationInfo.GetActiveSpecGroup then
        local okG, g = pcall(C_SpecializationInfo.GetActiveSpecGroup)
        if okG and type(g) == "number" then activeTalentGroup = g end
    elseif _G.GetActiveSpecGroup then
        local okG, g = pcall(_G.GetActiveSpecGroup)
        if okG and type(g) == "number" then activeTalentGroup = g end
    end

    for tier = 1, 7 do
        for col = 1, 3 do
            local tName, tIcon, tSelected, tSpellID
            if C_SpecializationInfo and C_SpecializationInfo.GetTalentInfo then
                local ok, info = pcall(C_SpecializationInfo.GetTalentInfo, {
                    tier = tier,
                    column = col,
                    groupIndex = activeTalentGroup,
                    isInspect = false
                })
                if ok and type(info) == "table" and info.name then
                    tName = info.name
                    tIcon = info.icon or info.texture
                    tSelected = (info.selected == true) or (info.known == true)
                    tSpellID = info.spellID
                end
            end
            if not tName and _G.GetTalentInfo then
                local ok, a1, a2, a3, a4, a5, a6 = pcall(_G.GetTalentInfo, tier, col, activeTalentGroup)
                if ok then
                    if type(a1) == "number" and type(a2) == "string" then
                        tName = a2
                        tIcon = a3
                        tSelected = (a4 == true)
                        tSpellID = a6
                    elseif type(a1) == "string" and type(a4) == "boolean" then
                        tName = a1
                        tIcon = a2
                        tSelected = (a4 == true)
                    end
                end
            end

            if tName and tSelected then
                activeBucket.points = activeBucket.points + 1
                table.insert(activeBucket.talents, {
                    name = tName,
                    icon = tIcon or "Interface\\Icons\\INV_Misc_QuestionMark",
                    tier = tier,
                    col = col,
                    rank = 1,
                    maxRank = 1,
                    minLevel = tier * 15,
                    desc = ExtractTalentDescription(tier, col, tSpellID)
                })
            end
        end
    end

    if (C_SpecializationInfo and C_SpecializationInfo.GetSpecialization) or _G.GetSpecialization then
        return specBuckets
    end
    return nil
end

-- ENGINE C: Classic / TBC / WotLK 3.3.5a Multi-Rank 3-Tab Talent Scanner
local function ScanClassicFallbackTalents(classSpecs)
    local specBuckets = {}
    for s = 1, 3 do
        local specMeta = (classSpecs and classSpecs[s]) or { name = "Spec " .. s, icon = "Interface\\Icons\\Spell_Nature_StarFall" }
        specBuckets[s] = {
            name = specMeta.name,
            icon = specMeta.icon,
            role = specMeta.role,
            points = 0,
            talents = {}
        }

        if _G.GetTalentInfo and _G.GetNumTalents then
            local okNum, maxT = pcall(_G.GetNumTalents, s)
            maxT = (okNum and type(maxT) == "number" and maxT) or 0
            for tIdx = 1, maxT do
                local ok, a1, a2, a3, a4, a5, a6, _, _, _, _, _, a12 = pcall(_G.GetTalentInfo, s, tIdx)
                if ok and type(a1) == "string" and type(a5) == "number" and a5 > 0 then
                    local tier = tonumber(a3) or 1
                    specBuckets[s].points = specBuckets[s].points + a5
                    table.insert(specBuckets[s].talents, {
                        name = a1,
                        icon = a2 or "Interface\\Icons\\INV_Misc_QuestionMark",
                        tier = tier,
                        col = tonumber(a4) or 1,
                        rank = a5,
                        maxRank = tonumber(a6) or 5,
                        minLevel = 10 + ((tier - 1) * 5),
                        desc = ExtractTalentDescription(s, tIdx, a12)
                    })
                end
            end
            table.sort(specBuckets[s].talents, function(a, b)
                if a.tier ~= b.tier then return a.tier < b.tier end
                return (a.col or 1) < (b.col or 1)
            end)
        end
    end
    return specBuckets
end

local function ScanTalentsAndXP(charData)
    local curXP = UnitXP("player") or 0
    local maxXP = UnitXPMax("player") or 1
    charData.xpPercent = (maxXP > 0) and math.floor((curXP / maxXP) * 100 + 0.5) or 0

    local classSpecs = CLASS_TALENT_SPECS[charData.class or "WARRIOR"]
    local scannedTrees = ScanForeverTraitCanvas(classSpecs)
        or ScanMoPTalentGrid(classSpecs)
        or ScanClassicFallbackTalents(classSpecs)

    local pointsSummary = {}
    local bestTab, maxPoints = 0, 0
    local totalPointsFound = 0

    for s = 1, #scannedTrees do
        local tree = scannedTrees[s]
        if classSpecs and classSpecs[s] then
            tree.name = tree.name or classSpecs[s].name
            tree.icon = tree.icon or classSpecs[s].icon
        end

        local pts = tree.points or 0
        totalPointsFound = totalPointsFound + pts
        table.insert(pointsSummary, tostring(pts))

        if pts > maxPoints then
            maxPoints = pts
            bestTab = s
        end
    end

    if totalPointsFound > 0 or not charData.talentTrees or #charData.talentTrees == 0 then
        charData.talentTrees = scannedTrees
        charData.talentBuild = table.concat(pointsSummary, "/")
    end

    if bestTab > 0 and classSpecs and classSpecs[bestTab] then
        charData.specName = classSpecs[bestTab].name
        charData.specRole = classSpecs[bestTab].role
    else
        charData.specName = charData.specName or "Hybrid / Leveling"
        charData.specRole = charData.specRole or DEFAULT_CLASS_ROLE[charData.class or "WARRIOR"] or "MELEE_STR"
    end
end

ns.DB.ScanTalentsAndXP = ScanTalentsAndXP