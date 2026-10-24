-- ============================================================================
-- FILE: Core_MacroCache.lua (MODULE 2 OF 4 SPLIT FROM Core_Database.lua)
-- BLOCK HEADING: TRUNCATION-SAFE MULTI-MACRO BETA CACHE (CHARS + PEERS + TGA SLOTS)
-- ============================================================================
local addonName, ns = ...
ns.DB = ns.DB or {}

local PROF_TO_CODE = ns.DB.PROF_TO_CODE
local CODE_TO_PROF = ns.DB.CODE_TO_PROF
local NON_CONSUMING_GATHER_PROFS = ns.DB.NON_CONSUMING_GATHER_PROFS
local RACE_TO_FACTION = ns.DB.RACE_TO_FACTION
local DEFAULT_CLASS_ROLE = ns.DB.DEFAULT_CLASS_ROLE

local MACRO_NAMES = { "AV_DataCache", "AV_DataCache2", "AV_DataCache3" }
local PEER_MACRO_NAMES = { "AV_PeerCache", "AV_PeerCache2" }
local VOTE_MACRO_NAME = "AV_VoteCache"
local PHOTO_MACRO_NAME = "AV_PhotoCache"
local SNAPSHOT_FOLDER = "Interface\\AddOns\\" .. tostring(addonName or "AltVault") .. "\\Snapshots\\"

local function SanitizeCharTag(charName)
    local raw = tostring(charName or "Player")
    raw = string.gsub(raw, "%s+", "")
    raw = string.gsub(raw, "[^%w_%-]", "")
    if raw == "" then raw = "Player" end
    return raw
end

local function EncodeAllProfsForMacro(profTable)
    if not profTable then return "-" end
    local list = {}
    local seen = {}

    local function AddProf(p)
        if p and p.name and PROF_TO_CODE[p.name] and not seen[p.name] then
            seen[p.name] = true
            table.insert(list, PROF_TO_CODE[p.name] .. tostring(p.rank or 1))
        end
    end

    AddProf(profTable.primary1)
    AddProf(profTable.primary2)
    if type(profTable.all) == "table" then
        for _, p in ipairs(profTable.all) do
            AddProf(p)
        end
    end

    if #list == 0 then return "-" end
    return table.concat(list, ",")
end

local function DecodeAllProfsFromMacro(profBlob, c)
    if not profBlob or profBlob == "-" or profBlob == "" then return end
    c.professions = c.professions or {}
    c.professions.all = c.professions.all or {}

    local existingByName = {}
    for _, p in ipairs(c.professions.all) do
        if p and p.name then existingByName[p.name] = p end
    end

    for token in string.gmatch(profBlob, "([^,]+)") do
        local code, rankStr = string.match(token, "^(%a%a)(%d+)$")
        if code and CODE_TO_PROF[code] then
            local pName = CODE_TO_PROF[code]
            local pRank = tonumber(rankStr) or 1
            local profObj = { name = pName, rank = pRank, maxRank = 300 }
            if not existingByName[pName] then
                table.insert(c.professions.all, profObj)
                existingByName[pName] = profObj
            end
            if not c.professions.primary1 then
                c.professions.primary1 = profObj
            elseif not c.professions.primary2 and c.professions.primary1.name ~= pName then
                c.professions.primary2 = profObj
            end
        end
    end
end

-- ============================================================================
-- BLOCK HEADING: SYNCED PEER & PERMANENT VOTE LEDGER MACRO BACKUP
-- ============================================================================
local function EncodePeerProfsForMacro(peerProfsMap)
    if type(peerProfsMap) ~= "table" then return "-" end
    local list = {}
    for pName, rank in pairs(peerProfsMap) do
        local code = PROF_TO_CODE[pName]
        if code then
            table.insert(list, code .. tostring(tonumber(rank) or 1))
        end
    end
    table.sort(list)
    if #list == 0 then return "-" end
    return table.concat(list, ",")
end

local function DecodePeerProfsFromMacro(profBlob, peerTbl)
    if not profBlob or profBlob == "-" or profBlob == "" then return end
    peerTbl.profs = peerTbl.profs or {}
    for token in string.gmatch(profBlob, "([^,]+)") do
        local code, rankStr = string.match(token, "^(%a%a)(%d+)$")
        if code and CODE_TO_PROF[code] then
            peerTbl.profs[CODE_TO_PROF[code]] = tonumber(rankStr) or 1
        end
    end
end

local function SavePeersAndVotesToBetaMacro()
    if InCombatLockdown() or not AltVaultDB then return end
    if not GetMacroIndexByName or not EditMacro or not CreateMacro then return end

    -- 1. Save ONLY Explicitly Approved Synced Peers into AV_PeerCache & AV_PeerCache2
    local peerBuckets = { "", "" }
    local curPeerBucket = 1

    for peerName, p in pairs(AltVaultDB.GuildNetwork or {}) do
        if type(p) == "table" and p.explicitlyApprovedSync == true and not (AltVaultDB.Characters and AltVaultDB.Characters[peerName]) then
            local facCode = (p.faction == "Horde") and "H" or "A"
            local sexNum = tonumber(p.sex) or 2
            local sexSuffix = (sexNum == 3 and "~F") or "~M"
            local raceClean = (p.race and p.race ~= "Unknown") and (p.race .. sexSuffix) or "?"
            local gs = tonumber(p.gearScore) or 0
            local profBlob = EncodePeerProfsForMacro(p.profs)

            local entry = string.format("%s:%s:%d:%s:%s:%d:%s",
                peerName, p.class or "WARRIOR", tonumber(p.level) or 1, facCode, raceClean, gs, profBlob)

            local candidate = (peerBuckets[curPeerBucket] == "") and entry or (peerBuckets[curPeerBucket] .. ";" .. entry)
            if #candidate > 250 then
                curPeerBucket = curPeerBucket + 1
                if curPeerBucket <= #PEER_MACRO_NAMES then
                    peerBuckets[curPeerBucket] = entry
                end
            else
                peerBuckets[curPeerBucket] = candidate
            end
            if curPeerBucket > #PEER_MACRO_NAMES then break end
        end
    end

    for i, macroName in ipairs(PEER_MACRO_NAMES) do
        local body = peerBuckets[i] or ""
        local okIdx, idx = pcall(GetMacroIndexByName, macroName)
        if not okIdx then idx = 0 end
        if body ~= "" then
            if idx and idx > 0 then
                pcall(EditMacro, idx, macroName, "INV_Misc_GroupLooking", body)
            else
                local numGlobal = GetNumMacros and GetNumMacros() or 0
                if numGlobal < 36 then
                    pcall(CreateMacro, macroName, "INV_Misc_GroupLooking", body, nil)
                end
            end
        elseif idx and idx > 0 then
            pcall(EditMacro, idx, macroName, "INV_Misc_GroupLooking", " ")
        end
    end

    -- 2. Save Permanent CharacterVotes into AV_VoteCache
    local voteTokens = {}
    for targetChar, voterTbl in pairs(AltVaultDB.CharacterVotes or {}) do
        if type(voterTbl) == "table" then
            for vName, vVal in pairs(voterTbl) do
                if vVal == 1 or vVal == -1 then
                    local tok = string.format("%s:%s:%d", targetChar, vName, vVal)
                    local candidate = (#voteTokens == 0) and tok or (table.concat(voteTokens, ",") .. "," .. tok)
                    if #candidate <= 250 then
                        table.insert(voteTokens, tok)
                    end
                end
            end
        end
    end

    local voteBody = (#voteTokens > 0) and table.concat(voteTokens, ",") or ""
    local lockTokens = {}
    for lockID, isLocked in pairs(AltVaultDB.LockedTradeItems or {}) do
        if isLocked and tonumber(lockID) then
            local lTok = tostring(lockID)
            local candidate = (#lockTokens == 0) and lTok or (table.concat(lockTokens, ",") .. "," .. lTok)
            if (#voteBody + #candidate + 4) <= 250 then
                table.insert(lockTokens, lTok)
            end
        end
    end
    if #lockTokens > 0 then
        voteBody = voteBody .. "#L:" .. table.concat(lockTokens, ",")
    end
    local okV, vIdx = pcall(GetMacroIndexByName, VOTE_MACRO_NAME)
    if not okV then vIdx = 0 end
    if voteBody ~= "" then
        if vIdx and vIdx > 0 then
            pcall(EditMacro, vIdx, VOTE_MACRO_NAME, "Achievement_BG_winWSG", voteBody)
        else
            local numGlobal = GetNumMacros and GetNumMacros() or 0
            if numGlobal < 36 then
                pcall(CreateMacro, VOTE_MACRO_NAME, "Achievement_BG_winWSG", voteBody, nil)
            end
        end
    end
end

local function RestorePeersAndVotesFromBetaMacro()
    if not GetMacroIndexByName or not GetMacroInfo or not AltVaultDB then return end
    AltVaultDB.GuildNetwork = AltVaultDB.GuildNetwork or {}
    AltVaultDB.CharacterVotes = AltVaultDB.CharacterVotes or {}

    -- Clear any legacy AV_PeerCache / AV_PeerCache2 macros that previously stored passive mouseover players
    if not InCombatLockdown() and EditMacro then
        for _, macroName in ipairs(PEER_MACRO_NAMES) do
            local okIdx, idx = pcall(GetMacroIndexByName, macroName)
            if okIdx and idx and idx > 0 then
                pcall(EditMacro, idx, macroName, "INV_Misc_GroupLooking", " ")
            end
        end
    end

    AltVaultDB.LockedTradeItems = AltVaultDB.LockedTradeItems or {}
    local okV, vIdx = pcall(GetMacroIndexByName, VOTE_MACRO_NAME)
    if okV and vIdx and vIdx > 0 then
        local okInfo, _, _, vBody = pcall(GetMacroInfo, vIdx)
        if okInfo and vBody and vBody ~= "" and vBody ~= " " then
            local votePart, lockPart = string.match(vBody, "^(.-)#L:(.*)$")
            if not votePart then votePart = vBody end
            for token in string.gmatch(votePart, "([^,]+)") do
                local tName, vName, valStr = string.match(token, "^([^:]+):([^:]+):([%-]?%d+)$")
                local numVal = tonumber(valStr)
                if tName and vName and (numVal == 1 or numVal == -1) then
                    AltVaultDB.CharacterVotes[tName] = AltVaultDB.CharacterVotes[tName] or {}
                    if AltVaultDB.CharacterVotes[tName][vName] == nil then
                        AltVaultDB.CharacterVotes[tName][vName] = numVal
                    end
                end
            end
            if lockPart and lockPart ~= "" then
                for idStr in string.gmatch(lockPart, "([^,]+)") do
                    local numID = tonumber(idStr)
                    if numID and numID > 0 then
                        AltVaultDB.LockedTradeItems[numID] = true
                    end
                end
            end
        end
    end
end

-- ============================================================================
-- BLOCK HEADING: FEATURED 2D PHOTO / 16-SHEET TGA VIDEO SLOT MACRO CACHE
-- Format per character: Name:SlotIdx:FileSlot:Zoom:PanX:PanY:StretchX:FlipFlag:GearBlob
-- ============================================================================
local VISIBLE_MACRO_SLOTS = { 1, 3, 5, 6, 7, 8, 9, 10, 15, 16, 17, 19 }

local function SavePhotosToBetaMacro()
    if InCombatLockdown() or not AltVaultDB then return end
    if not GetMacroIndexByName or not EditMacro or not CreateMacro then return end

    local album = AltVaultDB.PhotoAlbum or {}
    local avatars = AltVaultDB.CharacterAvatars or {}
    local entries = {}

    for charName, cData in pairs(AltVaultDB.Characters or {}) do
        local snapID = avatars[charName] or (charName .. "_Slot1")
        local snap = (snapID and album[snapID]) or cData.profileSnapshot
        local sIdx = (snap and tonumber(snap.slotIndex)) or 1
        local fSlot = (snap and tonumber(snap.fileSlot)) or sIdx
        local zm = (snap and tonumber(snap.zoom)) or 100
        local px = (snap and tonumber(snap.panX)) or 0
        local py = (snap and tonumber(snap.panY)) or 0
        local sx = (snap and tonumber(snap.stretchX)) or 100
        local flipFlag = (snap and snap.isFlipbook) and math.max(1, math.min(16, tonumber(snap.reelSheets) or 15)) or 0

        local gList = {}
        local gTable = cData.gear or (snap and snap.gear) or {}
        for _, sID in ipairs(VISIBLE_MACRO_SLOTS) do
            local raw = gTable[sID]
            local itemID = raw and (type(raw) == "number" and raw or tonumber(string.match(tostring(raw), "item:(%d+)")))
            if itemID and itemID > 0 then
                table.insert(gList, sID .. "=" .. itemID)
            end
        end
        local gBlob = (#gList > 0) and table.concat(gList, ",") or "-"
        local token = string.format("%s:%d:%d:%d:%d:%d:%d:%d:%s",
            charName, sIdx, fSlot, zm, px, py, sx, flipFlag, gBlob
        )
        local candidate = (#entries == 0) and token or (table.concat(entries, ";") .. ";" .. token)
        if #candidate <= 250 then
            table.insert(entries, token)
        end
    end

    local body = (#entries > 0) and table.concat(entries, ";") or ""
    local okIdx, idx = pcall(GetMacroIndexByName, PHOTO_MACRO_NAME)
    if not okIdx then idx = 0 end
    if body ~= "" then
        if idx and idx > 0 then
            pcall(EditMacro, idx, PHOTO_MACRO_NAME, "INV_Misc_Camera", body)
        else
            local numGlobal = GetNumMacros and GetNumMacros() or 0
            if numGlobal < 36 then
                pcall(CreateMacro, PHOTO_MACRO_NAME, "INV_Misc_Camera", body, nil)
            end
        end
    end
end

local function RestorePhotosFromBetaMacro()
    if not GetMacroIndexByName or not GetMacroInfo or not AltVaultDB then return end
    AltVaultDB.PhotoAlbum = AltVaultDB.PhotoAlbum or {}
    AltVaultDB.CharacterAvatars = AltVaultDB.CharacterAvatars or {}

    local okIdx, idx = pcall(GetMacroIndexByName, PHOTO_MACRO_NAME)
    if not okIdx or not idx or idx <= 0 then return end
    local okInfo, _, _, body = pcall(GetMacroInfo, idx)
    if not okInfo or not body or body == "" or body == " " then return end

    for chunk in string.gmatch(body, "([^;]+)") do
        local name, sIdxStr, fSlotStr, zmStr, pxStr, pyStr, sxStr, flipStr, gBlob =
            string.match(chunk, "^([^:]+):(%d+):(%d+):([%-]?%d+):([%-]?%d+):([%-]?%d+):(%d+):(%d+):([^:]*)$")
        if not name then
            name, sIdxStr, fSlotStr, zmStr, pxStr, pyStr, sxStr, gBlob =
                string.match(chunk, "^([^:]+):(%d+):(%d+):([%-]?%d+):([%-]?%d+):([%-]?%d+):(%d+):([^:]*)$")
            flipStr = nil
        end

        if name and name ~= "" then
            local cData = AltVaultDB.Characters and AltVaultDB.Characters[name]
            local restoredGear = {}
            if gBlob and gBlob ~= "-" then
                for pair in string.gmatch(gBlob, "([^,]+)") do
                    local sID, itemID = string.match(pair, "^(%d+)=(%d+)$")
                    if sID and itemID then
                        restoredGear[tonumber(sID)] = tonumber(itemID)
                    end
                end
            end
            if cData and cData.gear and next(restoredGear) then
                for k, v in pairs(restoredGear) do
                    cData.gear[k] = cData.gear[k] or v
                end
            end

            local sIdx = math.max(1, math.min(12, tonumber(sIdxStr) or 1))
            local fSlot = math.max(1, math.min(12, tonumber(fSlotStr) or sIdx))
            local zm = tonumber(zmStr) or 100
            if zm < 100 then zm = 100 end
            local tag = SanitizeCharTag(name)
            local stdID = string.format("%s_Slot%d", name, sIdx)

            local snap = AltVaultDB.PhotoAlbum[stdID] or {}
            snap.id = stdID
            snap.author = name
            snap.slotIndex = sIdx
            snap.fileSlot = fSlot
            snap.canvasFile = string.format("%s_Slot%02d.tga", tag, fSlot)
            snap.filePath = SNAPSHOT_FOLDER .. string.format("%s_Slot%02d", tag, fSlot)
            snap.zoom = zm
            snap.panX = tonumber(pxStr) or 0
            snap.panY = tonumber(pyStr) or 0
            snap.stretchX = tonumber(sxStr) or 100
            if flipStr ~= nil then
                local flipVal = tonumber(flipStr) or 0
                snap.isFlipbook = (flipVal >= 1)
                if flipVal >= 1 then
                    snap.reelSheets = math.max(1, math.min(16, (flipVal > 1) and flipVal or (tonumber(snap.reelSheets) or 15)))
                end
            else
                snap.isFlipbook = snap.isFlipbook or false
            end
            snap.reelSheets = math.max(1, math.min(16, tonumber(snap.reelSheets) or 15))
            snap.fps = math.max(8, math.min(60, tonumber(snap.fps) or 24))
            snap.locked = true
            snap.votes = snap.votes or 0
            snap.voters = snap.voters or {}
            snap.caption = snap.caption or string.format("%s Photo #%d", name, sIdx)

            AltVaultDB.PhotoAlbum[stdID] = snap
            AltVaultDB.CharacterAvatars[name] = stdID
            if cData then
                cData.profileSnapshot = snap
            end
        end
    end
end

local function SaveToBetaMacro()
    if InCombatLockdown() or not AltVaultDB or not AltVaultDB.Characters then return end
    if not GetMacroIndexByName or not EditMacro or not CreateMacro then return end

    local playerName = UnitName("player")
    if playerName and AltVaultDB.Characters[playerName] then
        local liveData = AltVaultDB.Characters[playerName]
        if UnitSex then
            liveData.sex = UnitSex("player")
        end
        local rName, rFile = UnitRace("player")
        if rName and rName ~= "" then
            liveData.race = rName
        end
        if rFile and rFile ~= "" then
            liveData.raceFile = rFile
        end
    end

    local buckets = { "", "", "" }
    local currentBucket = 1

    for name, d in pairs(AltVaultDB.Characters) do
        local facCode = (d.faction == "Horde") and "H" or "A"
        local sexNum = tonumber(d.sex) or 2
        local sexSuffix = (sexNum == 3 and "~F") or (sexNum == 2 and "~M") or "~M"
        local raceClean = (d.race and d.race ~= "Unknown") and (d.race .. sexSuffix) or "?"
        local gs = d.gearScore or 0
        local profBlob = EncodeAllProfsForMacro(d.professions)

        local entry = string.format("%s:%s:%d:%s:%s:%d:%s",
            name, d.class or "WARRIOR", d.level or 1, facCode, raceClean, gs, profBlob)

        local candidate = (buckets[currentBucket] == "") and entry or (buckets[currentBucket] .. ";" .. entry)
        if #candidate > 250 then
            currentBucket = currentBucket + 1
            if currentBucket > #MACRO_NAMES then break end
            buckets[currentBucket] = entry
        else
            buckets[currentBucket] = candidate
        end
    end

    for i, macroName in ipairs(MACRO_NAMES) do
        local body = buckets[i] or ""
        local okIdx, idx = pcall(GetMacroIndexByName, macroName)
        if not okIdx then idx = 0 end
        if body ~= "" then
            if idx and idx > 0 then
                pcall(EditMacro, idx, macroName, "INV_Misc_Bag_10_Black", body)
            else
                local numGlobal = GetNumMacros and GetNumMacros() or 0
                if numGlobal < 36 then
                    pcall(CreateMacro, macroName, "INV_Misc_Bag_10_Black", body, nil)
                end
            end
        elseif idx and idx > 0 then
            pcall(EditMacro, idx, macroName, "INV_Misc_Bag_10_Black", " ")
        end
    end

    pcall(SavePhotosToBetaMacro)
    pcall(SavePeersAndVotesToBetaMacro)
end

local function RestoreFromBetaMacro()
    if not GetMacroIndexByName or not GetMacroInfo then return end
    for _, macroName in ipairs(MACRO_NAMES) do
        local okIdx, idx = pcall(GetMacroIndexByName, macroName)
        if okIdx and idx and idx > 0 then
            local okInfo, _, _, body = pcall(GetMacroInfo, idx)
            if okInfo and body and body ~= "" and body ~= " " then
                for chunk in string.gmatch(body, "([^;]+)") do
                    local name, class, lvl, facCode, raceRaw, gs, pBlob1, pBlob2 =
                        string.match(chunk, "([^:]+):([^:]+):(%d+):([^:]+):([^:]+):?(%d*):?([^:]*):?([^:]*)")
                    if name and name ~= "" then
                        AltVaultDB.Characters[name] = AltVaultDB.Characters[name] or {
                            professions = {}, gear = {}, bags = {}, bank = {}, talentTrees = {}, neededReagents = {}, knownRecipes = {}
                        }
                        local c = AltVaultDB.Characters[name]
                        c.class = c.class or class
                        c.level = c.level or tonumber(lvl) or 1
                        if facCode == "H" then c.faction = "Horde" elseif facCode == "A" then c.faction = "Alliance" end
                        if raceRaw and raceRaw ~= "?" and raceRaw ~= "Unknown" then
                            local parsedRace, parsedSex = string.match(raceRaw, "^([^~]+)~([MF])$")
                            local cleanRace = parsedRace or raceRaw
                            c.race = cleanRace
                            if parsedSex == "F" then
                                c.sex = 3
                            elseif parsedSex == "M" then
                                c.sex = 2
                            end
                        end
                        if gs and tonumber(gs) and (not c.gearScore or c.gearScore == 0) then
                            c.gearScore = tonumber(gs)
                        end
                        if pBlob1 and pBlob1 ~= "" then
                            DecodeAllProfsFromMacro(pBlob1, c)
                        end
                        if pBlob2 and pBlob2 ~= "" then
                            DecodeAllProfsFromMacro(pBlob2, c)
                        end
                    end
                end
            end
        end
    end

    pcall(RestorePhotosFromBetaMacro)
    pcall(RestorePeersAndVotesFromBetaMacro)
end

-- ============================================================================
-- BLOCK HEADING: SAVEDVARIABLES INITIALIZER & SANITIZER
-- ============================================================================
local dbInitializedOnce = false

local function InitializeDatabase()
    AltVaultDB = AltVaultDB or {}
    AltVaultDB.Characters = AltVaultDB.Characters or {}
    AltVaultDB.GuildVaults = AltVaultDB.GuildVaults or {}
    AltVaultDB.LearnedProgression = AltVaultDB.LearnedProgression or {}
    AltVaultDB.ItemCache = AltVaultDB.ItemCache or {}
    AltVaultDB.PatternDB = AltVaultDB.PatternDB or {}
    AltVaultDB.ReagentDB = AltVaultDB.ReagentDB or {}
    AltVaultDB.SourceDB = AltVaultDB.SourceDB or {}
    AltVaultDB.CharacterVotes = AltVaultDB.CharacterVotes or {}
    AltVaultDB.LockedTradeItems = AltVaultDB.LockedTradeItems or {}
    AltVaultDB.PhotoAlbum = AltVaultDB.PhotoAlbum or {}
    AltVaultDB.CharacterAvatars = AltVaultDB.CharacterAvatars or {}
    AltVaultDB.PhotoVotes = AltVaultDB.PhotoVotes or {}
    AltVaultDB.SyncQueue = AltVaultDB.SyncQueue or {}
    AltVaultDB.IgnoredSyncPlayers = AltVaultDB.IgnoredSyncPlayers or {}
    if AltVaultDB.SyncDND == nil then AltVaultDB.SyncDND = false end
    if AltVaultDB.BlockFriendsOfFriends == nil then AltVaultDB.BlockFriendsOfFriends = false end
    if AltVaultDB.NameplateGlowEnabled == nil then AltVaultDB.NameplateGlowEnabled = true end
    AltVaultDB.CrawlCursorID = AltVaultDB.CrawlCursorID or 150
    AltVaultDB.MinimapAngle = AltVaultDB.MinimapAngle or 45
    AltVaultDB.PerPageCount = AltVaultDB.PerPageCount or 20
    AltVaultDB.Favorites = AltVaultDB.Favorites or { items = {}, recipes = {} }

    if dbInitializedOnce then return end
    dbInitializedOnce = true

    -- Keep background database scanner paused by default so it never causes lag during gameplay
    AltVaultDB.ScannerPaused = true

    -- Purge any non-approved or legacy mouseover entries from GuildNetwork so ONLY explicitly approved syncs remain
    for peerName, pData in pairs(AltVaultDB.GuildNetwork or {}) do
        if type(pData) ~= "table" or pData.explicitlyApprovedSync ~= true then
            AltVaultDB.GuildNetwork[peerName] = nil
        end
    end

    for _, entry in pairs(AltVaultDB.ReagentDB) do
        if type(entry) == "table" and type(entry.profs) == "table" then
            for pName in pairs(NON_CONSUMING_GATHER_PROFS) do
                entry.profs[pName] = nil
            end
        end
    end

    for _, data in pairs(AltVaultDB.Characters) do
        data.gear = data.gear or {}
        data.bags = data.bags or {}
        data.bank = data.bank or {}
        data.professions = data.professions or {}
        data.professions.all = data.professions.all or {}
        data.talentTrees = data.talentTrees or {}
        data.neededReagents = data.neededReagents or {}
        data.knownRecipes = data.knownRecipes or {}
        if data.race and RACE_TO_FACTION[data.race] then
            data.faction = RACE_TO_FACTION[data.race]
        end
        if not data.specRole then
            data.specRole = DEFAULT_CLASS_ROLE[data.class or "WARRIOR"] or "MELEE_STR"
        end
    end
end

ns.DB.EncodeAllProfsForMacro = EncodeAllProfsForMacro
ns.DB.DecodeAllProfsFromMacro = DecodeAllProfsFromMacro
ns.DB.SaveToBetaMacro = SaveToBetaMacro
ns.DB.SavePhotosToBetaMacro = SavePhotosToBetaMacro
ns.DB.SavePeersAndVotesToBetaMacro = SavePeersAndVotesToBetaMacro
local function ExtractLockItemID(itemLinkOrID)
    if not itemLinkOrID then return nil end
    if type(itemLinkOrID) == "number" then return itemLinkOrID end
    return tonumber(string.match(tostring(itemLinkOrID), "item:(%d+)")) or tonumber(itemLinkOrID)
end

function ns.DB.IsItemTradeLocked(itemLinkOrID)
    if not AltVaultDB or not AltVaultDB.LockedTradeItems then return false end
    local id = ExtractLockItemID(itemLinkOrID)
    if not id then return false end
    return AltVaultDB.LockedTradeItems[id] == true
end

function ns.DB.ToggleItemTradeLock(itemLinkOrID)
    if not AltVaultDB then return false end
    AltVaultDB.LockedTradeItems = AltVaultDB.LockedTradeItems or {}
    local id = ExtractLockItemID(itemLinkOrID)
    if not id then return false end

    local newState = not AltVaultDB.LockedTradeItems[id]
    if newState then
        AltVaultDB.LockedTradeItems[id] = true
    else
        AltVaultDB.LockedTradeItems[id] = nil
    end

    pcall(SavePeersAndVotesToBetaMacro)

    local displayLink = (ns.Scanner and ns.Scanner.FetchItemInfo and select(2, ns.Scanner.FetchItemInfo(itemLinkOrID)))
        or (type(itemLinkOrID) == "string" and itemLinkOrID)
        or ("Item #" .. tostring(id))

    if newState then
        print(string.format("|cffff2020[AltVault Trade Lock]:|r %s marked |cffff2020[NOT FOR TRADE (RED)]|r — hidden from other players & trade tabs!", displayLink))
    else
        print(string.format("|cff00ff00[AltVault Trade Lock]:|r %s unlocked — now visible for trade & network tabs!", displayLink))
    end

    if ns.RefreshLiveContainerGlows then
        pcall(ns.RefreshLiveContainerGlows)
    end
    if ns.RefreshLiveGuildBankGlows then
        pcall(ns.RefreshLiveGuildBankGlows)
    end
    return newState
end

ns.DB.RestoreFromBetaMacro = RestoreFromBetaMacro
ns.DB.InitializeDatabase = InitializeDatabase