-- ============================================================================
-- ALTVAULT MASTER HOLDING TANK QUERY & SEARCH ENGINE (Core_MasterLootIndex.lua)
-- Connects AltVault to DB_MasterHoldingTank.lua (Static Records + Auto-Indexer)
-- ============================================================================
local addonName, ns = ...
ns = ns or {}
ns.MasterDB = ns.MasterDB or _G.AltVaultMasterDB or {}
_G.AltVaultMasterDB = ns.MasterDB

local MasterDB = ns.MasterDB
MasterDB.HoldingTank      = MasterDB.HoldingTank or {}
MasterDB.ByItemID         = MasterDB.ByItemID or {}
MasterDB.BySpellID        = MasterDB.BySpellID or {}
MasterDB.BySetID          = MasterDB.BySetID or {}
MasterDB.UniqueItemIDList = MasterDB.UniqueItemIDList or {}
MasterDB.Stats            = MasterDB.Stats or {
    TotalRecords = 0,
    UniqueItems = 0,
    UniqueSpells = 0,
    UniqueSets = 0,
    UniqueQuestsAndNPCs = 0,
}

local SEP = string.char(124) -- ASCII 124 ('|')
local COLOR_START = SEP .. "cff"
local COLOR_END   = SEP .. "r"

local function Colorize(hex6, text)
    return COLOR_START .. hex6 .. tostring(text or "") .. COLOR_END
end

local ERA_COLORS = {
    ["Classic"]     = "ffcc66",
    ["SoD_Forever"] = "00ffcc",
    ["TBC"]         = "66ff66",
    ["Wrath"]       = "66ccff",
}

local ERA_LABELS = {
    ["Classic"]     = "Classic",
    ["SoD_Forever"] = "Forever/SoD",
    ["TBC"]         = "TBC",
    ["Wrath"]       = "Wrath",
}

local unpackedCache = {}
local unpackedCount = 0
local indexesBuilt  = false

local function SplitPackedRecord(rawStr)
    local fields = {}
    local startPos = 1
    local sepLen = 1
    while true do
        local pos = string.find(rawStr, SEP, startPos, true)
        if not pos then
            fields[#fields + 1] = string.sub(rawStr, startPos)
            break
        end
        fields[#fields + 1] = string.sub(rawStr, startPos, pos - 1)
        startPos = pos + sepLen
    end
    return fields
end

-- Automatically builds ByItemID, BySpellID, BySetID, and UniqueItemIDList from HoldingTank
function MasterDB:EnsureIndexesBuilt()
    if indexesBuilt then return end
    local tank = self.HoldingTank
    if not tank then
        tank = {}
        self.HoldingTank = tank
    end
    if #tank == 0 and self.RawBlobs and #self.RawBlobs > 0 then
        for b = 1, #self.RawBlobs do
            local blob = self.RawBlobs[b]
            if type(blob) == "string" then
                for line in string.gmatch(blob, "[^\r\n]+") do
                    if line ~= "" then
                        tank[#tank + 1] = line
                    end
                end
            end
            self.RawBlobs[b] = nil
        end
        self.RawBlobs = {}
    end
    if #tank == 0 then return end

    indexesBuilt = true
    self.ByItemID = {}
    self.BySpellID = {}
    self.BySetID = {}
    self.UniqueItemIDList = {}

    local uItems, uSpells, uSets, uOther = 0, 0, 0, 0

    for idx = 1, #tank do
        local raw = tank[idx]
        if raw then
            local p1 = string.find(raw, SEP, 1, true)
            if p1 then
                local idType = string.sub(raw, 1, p1 - 1)
                local p2 = string.find(raw, SEP, p1 + 1, true)
                if p2 then
                    local numID = tonumber(string.sub(raw, p1 + 1, p2 - 1))
                    if numID and numID > 0 then
                        if idType == "Item" or idType == "DB_Entry" then
                            local list = self.ByItemID[numID]
                            if not list then
                                list = {}
                                self.ByItemID[numID] = list
                                uItems = uItems + 1
                                self.UniqueItemIDList[#self.UniqueItemIDList + 1] = numID
                            end
                            list[#list + 1] = idx
                        elseif idType == "Spell" then
                            local list = self.BySpellID[numID]
                            if not list then
                                list = {}
                                self.BySpellID[numID] = list
                                uSpells = uSpells + 1
                            end
                            list[#list + 1] = idx
                        elseif idType == "Set" then
                            local list = self.BySetID[numID]
                            if not list then
                                list = {}
                                self.BySetID[numID] = list
                                uSets = uSets + 1
                            end
                            list[#list + 1] = idx
                        else
                            uOther = uOther + 1
                        end
                    end
                end
            end
        end
    end

    table.sort(self.UniqueItemIDList)
    self.Stats = {
        TotalRecords = #tank,
        UniqueItems = uItems,
        UniqueSpells = uSpells,
        UniqueSets = uSets,
        UniqueQuestsAndNPCs = uOther,
    }
end

function MasterDB:UpsertLiveRecord(idType, numID, name, contentType, category, subSection, bossOrHeader, faction, priceOrCost, phase, sourceFile)
    if not numID or type(numID) ~= "number" or numID <= 0 then return end
    if not indexesBuilt then
        self:EnsureIndexesBuilt()
    end
    idType = idType or "Item"
    name = tostring(name or "")
    contentType = tostring(contentType or "Forever_Server")
    category = tostring(category or "WoW Forever Server")
    subSection = tostring(subSection or "")
    bossOrHeader = tostring(bossOrHeader or "")
    faction = tostring(faction or "Both")
    priceOrCost = tostring(priceOrCost or "")
    phase = tostring(phase or "")
    sourceFile = tostring(sourceFile or "LiveServerSync")

    local existingIndices = (idType == "Item") and self.ByItemID[numID]
        or (idType == "Spell" and self.BySpellID[numID])
        or (idType == "Set" and self.BySetID[numID])
    local wasBrandNewItem = (not existingIndices or #existingIndices == 0)

    if existingIndices and #existingIndices > 0 then
        -- Check if an identical source line already exists, and backfill missing names on existing records
        for _, rIdx in ipairs(existingIndices) do
            local rec = self:GetRecordByIndex(rIdx)
            if rec then
                if (rec.Name == "" or not rec.Name) and name ~= "" then
                    rec.Name = name
                end
                if rec.Category == category and rec.SubSection == subSection and rec.BossOrHeader == bossOrHeader then
                    return rec, false, false
                end
            end
        end
        -- If this is just a generic server scan ping and we already have a rich dungeon/raid/craft record, just enrich the name
        if contentType == "Forever_Server" then
            return self:GetRecordByIndex(existingIndices[1]), false, false
        end
    end

    local rawPacked = table.concat({
        idType,
        tostring(numID),
        name,
        "SoD_Forever",
        contentType,
        category,
        category,
        subSection,
        bossOrHeader,
        "Normal",
        faction,
        priceOrCost,
        phase,
        sourceFile
    }, SEP)

    local newIdx = #self.HoldingTank + 1
    self.HoldingTank[newIdx] = rawPacked
    self.Stats.TotalRecords = newIdx

    -- Persist live discoveries (Vendors, Trainers, Quests, Boss Drops, Recipes) in SavedVariables in the exact 14-field Master Holding Tank format
    if AltVaultDB and contentType ~= "Forever_Server" then
        AltVaultDB.HoldingTankLiveRecords = AltVaultDB.HoldingTankLiveRecords or {}
        AltVaultDB.HoldingTankLiveRecords[rawPacked] = true
    end

    if idType == "Item" then
        if not self.ByItemID[numID] then
            self.ByItemID[numID] = {}
            self.UniqueItemIDList[#self.UniqueItemIDList + 1] = numID
            self.Stats.UniqueItems = (self.Stats.UniqueItems or 0) + 1
        end
        table.insert(self.ByItemID[numID], newIdx)
    elseif idType == "Spell" then
        if not self.BySpellID[numID] then
            self.BySpellID[numID] = {}
            self.Stats.UniqueSpells = (self.Stats.UniqueSpells or 0) + 1
        end
        table.insert(self.BySpellID[numID], newIdx)
    end

    return self:GetRecordByIndex(newIdx), true, wasBrandNewItem
end

function MasterDB:SyncSingleItemToHoldingTank(itemID, info)
    if not itemID or type(itemID) ~= "table" and type(info) ~= "table" then return end
    if ns.Scanner and ns.Scanner.IsValidWowForeverItem then
        if not ns.Scanner.IsValidWowForeverItem(itemID, info.n, info.q, info.l, info.r, info.t, info.st, info.eq, info.c, nil) then
            return
        end
    end

    local fac = "Both"
    if info.ra and info.ra ~= "" then
        local rLow = string.lower(info.ra)
        local hasAlly = string.find(rLow, "human") or string.find(rLow, "dwarf") or string.find(rLow, "night elf") or string.find(rLow, "gnome") or string.find(rLow, "draenei") or string.find(rLow, "worgen")
        local hasHorde = string.find(rLow, "orc") or string.find(rLow, "undead") or string.find(rLow, "tauren") or string.find(rLow, "troll") or string.find(rLow, "blood elf") or string.find(rLow, "goblin")
        if hasAlly and not hasHorde then fac = "Alliance"
        elseif hasHorde and not hasAlly then fac = "Horde" end
    end

    local cat = (info.t and info.t ~= "" and info.t) or "Item"
    local sub = (info.st and info.st ~= "" and info.st) or (info.eq and info.eq ~= "" and info.eq) or "General"
    local metaTags = {}
    if info.r and info.r > 1 then table.insert(metaTags, "Req Lvl " .. tostring(info.r)) end
    if info.l and info.l > 1 then table.insert(metaTags, "iLvl " .. tostring(info.l)) end
    if info.cl and info.cl ~= "" and info.cl ~= "All Classes" then table.insert(metaTags, info.cl) end
    if info.ra and info.ra ~= "" then table.insert(metaTags, info.ra) end
    if info.ro and info.ro ~= "" and info.ro ~= "ANY" then table.insert(metaTags, info.ro) end
    local bossHeader = (#metaTags > 0) and table.concat(metaTags, " • ") or "Verified Server Item"

    -- Sync base item metadata into Holding Tank
    self:UpsertLiveRecord("Item", itemID, info.n, "Forever_Server", cat, sub, bossHeader, fac, "", "", "LiveServerCache")

    -- If PatternDB has profession pattern info for this item, sync it
    local pat = AltVaultDB and AltVaultDB.PatternDB and AltVaultDB.PatternDB[itemID]
    if pat and pat.p then
        self:UpsertLiveRecord("Item", itemID, info.n, "Professions", pat.p, "Recipe Pattern (Skill " .. tostring(pat.s or 1) .. ")", pat.cn or "", fac, "", "", "PatternScanner")
    end

    -- If RecipeDB has crafted output schematic for this item, sync it
    local rec = AltVaultDB and AltVaultDB.RecipeDB and AltVaultDB.RecipeDB[itemID]
    if rec and rec.prof then
        self:UpsertLiveRecord("Item", itemID, info.n or rec.name, "Professions", rec.prof, "Crafted (" .. tostring(rec.rank or 1) .. " Skill)", "Profession Recipe", fac, "", "", "TradeSkillScanner")
    end

    -- If SourceDB has live trainer, vendor, craft, or boss drop info for this item, sync it
    local src = AltVaultDB and AltVaultDB.SourceDB and AltVaultDB.SourceDB[itemID]
    if src then
        if src.both then
            self:UpsertLiveRecord("Item", itemID, info.n, "Live_Discovery", "Live World Source", src.both, "", "Both", "", "", "LiveEventScanner")
        end
        if src.alliance then
            self:UpsertLiveRecord("Item", itemID, info.n, "Live_Discovery", "Alliance Source", src.alliance, "", "Alliance", "", "", "LiveEventScanner")
        end
        if src.horde then
            self:UpsertLiveRecord("Item", itemID, info.n, "Live_Discovery", "Horde Source", src.horde, "", "Horde", "", "", "LiveEventScanner")
        end
    end
end

function MasterDB:SyncAllLiveCachesToHoldingTank()
    if not AltVaultDB then return end
    if type(AltVaultDB.HoldingTankLiveRecords) == "table" then
        for rawPacked in pairs(AltVaultDB.HoldingTankLiveRecords) do
            if type(rawPacked) == "string" then
                local f = SplitPackedRecord(rawPacked)
                local numID = tonumber(f[2])
                if numID and numID > 0 then
                    self:UpsertLiveRecord(f[1], numID, f[3], f[5], f[7], f[8], f[9], f[11], f[12], f[13], f[14])
                end
            end
        end
    end
    if not AltVaultDB.ItemCache then return end
    for itemID, info in pairs(AltVaultDB.ItemCache) do
        if type(itemID) == "number" and type(info) == "table" and info.n then
            self:SyncSingleItemToHoldingTank(itemID, info)
        end
    end
end

function MasterDB:GetRecordByIndex(recordIdx)
    if not recordIdx then return nil end
    if unpackedCache[recordIdx] then
        return unpackedCache[recordIdx]
    end

    local raw = self.HoldingTank and self.HoldingTank[recordIdx]
    if not raw then return nil end

    local f = SplitPackedRecord(raw)
    local rec = {
        RecordIndex  = recordIdx,
        IDType       = f[1] or "Item",
        ID           = tonumber(f[2]) or 0,
        Name         = f[3] or "",
        Era          = f[4] or "Classic",
        ContentType  = f[5] or "General",
        ModuleKey    = f[6] or "",
        Category     = f[7] or "",
        SubSection   = f[8] or "",
        BossOrHeader = f[9] or "",
        Difficulty   = f[10] or "Normal",
        Faction      = f[11] or "Both",
        PriceOrCost  = f[12] or "",
        Phase        = f[13] or "",
        SourceFile   = f[14] or "",
    }

    if unpackedCount > 4000 then
        unpackedCache = {}
        unpackedCount = 0
    end
    unpackedCache[recordIdx] = rec
    unpackedCount = unpackedCount + 1
    return rec
end

local function NormalizeNumericID(itemOrID)
    if not itemOrID then return nil end
    if type(itemOrID) == "number" then return itemOrID end
    if type(itemOrID) == "string" then
        local direct = tonumber(itemOrID)
        if direct then return direct end
        local fromLink = string.match(itemOrID, "item:(%d+)") or string.match(itemOrID, "spell:(%d+)") or string.match(itemOrID, "(%d+)")
        if fromLink then return tonumber(fromLink) end
    end
    return nil
end

function MasterDB:GetItemSources(itemOrID)
    self:EnsureIndexesBuilt()
    local itemID = NormalizeNumericID(itemOrID)
    if not itemID then return {} end

    local idxList = self.ByItemID and self.ByItemID[itemID]
    if not idxList then return {} end
    if type(idxList) == "number" then idxList = { idxList } end

    local results = {}
    for i = 1, #idxList do
        local rec = self:GetRecordByIndex(idxList[i])
        if rec then
            results[#results + 1] = rec
        end
    end
    return results
end

function MasterDB:GetSpellSources(spellOrID)
    self:EnsureIndexesBuilt()
    local spellID = NormalizeNumericID(spellOrID)
    if not spellID then return {} end

    local idxList = self.BySpellID and self.BySpellID[spellID]
    if not idxList then return {} end

    local results = {}
    for i = 1, #idxList do
        local rec = self:GetRecordByIndex(idxList[i])
        if rec then
            results[#results + 1] = rec
        end
    end
    return results
end

function MasterDB:GetSetSources(setID)
    self:EnsureIndexesBuilt()
    local numID = NormalizeNumericID(setID)
    if not numID then return {} end

    local idxList = self.BySetID and self.BySetID[numID]
    if not idxList then return {} end

    local results = {}
    for i = 1, #idxList do
        local rec = self:GetRecordByIndex(idxList[i])
        if rec then
            results[#results + 1] = rec
        end
    end
    return results
end

function MasterDB:FormatPriceString(rawPrice)
    if not rawPrice or rawPrice == "" then return "" end
    local token, amt = string.match(rawPrice, "^([^:]+):(%d+)$")
    if token and amt then
        if token == "TUF" then
            return amt .. "x Tarnished Undermine Real"
        elseif token == "wildoffering" then
            return amt .. "x Wild Offering"
        elseif token == "firelandsember" then
            return amt .. "x Firelands Ember"
        elseif string.sub(token, 1, 5) == "Item_" then
            local costItemID = tonumber(string.sub(token, 6))
            if costItemID == 19182 then
                return amt .. "x Darkmoon Faire Ticket"
            end
            local itemName = C_Item and C_Item.GetItemNameByID and C_Item.GetItemNameByID(costItemID) or ("Item #" .. tostring(costItemID))
            return amt .. "x " .. tostring(itemName)
        end
        return amt .. "x " .. token
    end
    return rawPrice
end

function MasterDB:FormatRecordSummaryLine(rec)
    if not rec then return "" end
    local eraHex   = ERA_COLORS[rec.Era] or "cccccc"
    local eraLabel = ERA_LABELS[rec.Era] or rec.Era
    local line     = "[" .. Colorize(eraHex, eraLabel) .. "] "

    local primaryLoc = rec.Category
    if primaryLoc == "" then primaryLoc = rec.ModuleKey end
    line = line .. Colorize("ffd100", primaryLoc)

    if rec.SubSection ~= "" and rec.SubSection ~= primaryLoc then
        line = line .. " > " .. Colorize("ffffff", rec.SubSection)
    end
    if rec.BossOrHeader ~= "" and rec.BossOrHeader ~= rec.SubSection then
        line = line .. " (" .. Colorize("ff9966", rec.BossOrHeader) .. ")"
    end

    local tags = {}
    if rec.Difficulty ~= "" and rec.Difficulty ~= "Normal" then
        tags[#tags + 1] = rec.Difficulty
    end
    if rec.Faction ~= "" and rec.Faction ~= "Both" then
        tags[#tags + 1] = rec.Faction
    end
    if rec.Phase ~= "" then
        tags[#tags + 1] = rec.Phase
    end
    if #tags > 0 then
        line = line .. " " .. Colorize("aaddff", "[" .. table.concat(tags, "/") .. "]")
    end

    if rec.PriceOrCost ~= "" then
        line = line .. " - Cost: " .. Colorize("66ff99", self:FormatPriceString(rec.PriceOrCost))
    end

    return line
end

function MasterDB:GetFormattedSourceLines(itemOrID, maxLines)
    maxLines = maxLines or 5
    local records = self:GetItemSources(itemOrID)
    if #records == 0 then return {} end

    local lines = {}
    local seenLines = {}
    for i = 1, #records do
        local formatted = self:FormatRecordSummaryLine(records[i])
        if formatted ~= "" and not seenLines[formatted] then
            seenLines[formatted] = true
            lines[#lines + 1] = formatted
            if #lines >= maxLines then break end
        end
    end
    return lines
end

function MasterDB:SearchRecords(queryText, eraFilter, contentFilter, maxResults)
    self:EnsureIndexesBuilt()
    maxResults = maxResults or 100
    local q = string.lower(strtrim and strtrim(queryText or "") or (queryText or ""))
    local results = {}
    local tank = self.HoldingTank
    if not tank then return results end

    local numericQuery = tonumber(q)
    if numericQuery then
        local byItem = self:GetItemSources(numericQuery)
        for i = 1, #byItem do results[#results + 1] = byItem[i] end
        local bySpell = self:GetSpellSources(numericQuery)
        for i = 1, #bySpell do results[#results + 1] = bySpell[i] end
        if #results > 0 then return results end
    end

    local total = #tank
    for idx = 1, total do
        local raw = tank[idx]
        if raw then
            local match = true
            if eraFilter and eraFilter ~= "" and eraFilter ~= "ALL" then
                if not string.find(raw, SEP .. eraFilter .. SEP, 1, true) then
                    match = false
                end
            end
            if match and contentFilter and contentFilter ~= "" and contentFilter ~= "ALL" then
                if not string.find(raw, SEP .. contentFilter .. SEP, 1, true) then
                    match = false
                end
            end
            if match and q ~= "" then
                if not string.find(string.lower(raw), q, 1, true) then
                    match = false
                end
            end

            if match then
                local rec = self:GetRecordByIndex(idx)
                if rec then
                    results[#results + 1] = rec
                    if #results >= maxResults then
                        break
                    end
                end
            end
        end
    end

    return results
end

function MasterDB:GetHoldingTankStats()
    self:EnsureIndexesBuilt()
    local st = self.Stats or {}
    local total = st.TotalRecords or (self.HoldingTank and #self.HoldingTank or 0)
    return {
        TotalRecords        = total,
        UniqueItems         = st.UniqueItems or 0,
        UniqueSpells        = st.UniqueSpells or 0,
        UniqueSets          = st.UniqueSets or 0,
        UniqueQuestsAndNPCs = st.UniqueQuestsAndNPCs or 0,
    }
end

SLASH_ALTVAULTMASTERDB1 = "/avdb"
SlashCmdList["ALTVAULTMASTERDB"] = function(msg)
    local input = strtrim and strtrim(msg or "") or (msg or "")
    local st = MasterDB:GetHoldingTankStats()

    if input == "" or string.lower(input) == "stats" then
        print(Colorize("00ffcc", "[AltVault Master Holding Tank]") .. " Loaded Static Records: " .. Colorize("ffd100", st.TotalRecords))
        print("  * Unique Items: " .. Colorize("ffffff", st.UniqueItems) ..
              " | Recipe Spells: " .. Colorize("ffffff", st.UniqueSpells) ..
              " | Armor Sets: " .. Colorize("ffffff", st.UniqueSets) ..
              " | Quests/NPCs: " .. Colorize("ffffff", st.UniqueQuestsAndNPCs))
        print("  * Usage: " .. Colorize("66ccff", "/avdb <ItemID, Item Name, Boss, or Dungeon>"))
        return
    end

    local matches = MasterDB:SearchRecords(input, nil, nil, 15)
    print(Colorize("00ffcc", "[AltVault MasterDB]") .. " Search for '" .. Colorize("ffd100", input) .. "' returned " .. #matches .. " result(s):")
    for i = 1, #matches do
        local r = matches[i]
        local nameLabel = (r.Name ~= "" and r.Name) or (r.IDType .. " #" .. tostring(r.ID))
        print(string.format("  %d) [%s #%d] %s -> %s",
            i,
            r.IDType,
            r.ID,
            Colorize("66ff99", nameLabel),
            MasterDB:FormatRecordSummaryLine(r)
        ))
    end
end