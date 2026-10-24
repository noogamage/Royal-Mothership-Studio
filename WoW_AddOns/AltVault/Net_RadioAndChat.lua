-- ============================================================================
-- FILE: Net_RadioAndChat.lua (MODULE 1 OF 3 SPLIT FROM Engine_GuildNetwork.lua)
-- BLOCK HEADING: VIRTUAL GUILD RADIO QUEUE, VOTING LEDGER & CHATROOM ENGINE
-- ============================================================================
local addonName, ns = ...
local GuildNet = ns.GuildNet or {}
ns.GuildNet = GuildNet

local PREFIX = "AV_Net"
GuildNet.PREFIX = PREFIX

local sendQueue = {}
local recentWhisperTargets = {}
local seenChatMsgIDs = {}
local chatMsgCounter = 0

GuildNet.seenChatMsgIDs = seenChatMsgIDs

local CLASS_HEX = {
    WARRIOR = "c79c6e", PALADIN = "f58cba", HUNTER = "abd473",
    ROGUE = "fff569", PRIEST = "ffffff", DEATHKNIGHT = "c41f3b",
    SHAMAN = "0070de", MAGE = "40c7eb", WARLOCK = "8787ed", DRUID = "ff7d0a",
    MONK = "00ff98"
}

local PROF_SHORT = {
    ["Alchemy"] = "AL", ["Blacksmithing"] = "BS", ["Enchanting"] = "EN",
    ["Engineering"] = "EG", ["Herbalism"] = "HE", ["Inscription"] = "IN",
    ["Jewelcrafting"] = "JC", ["Leatherworking"] = "LW", ["Mining"] = "MI",
    ["Skinning"] = "SK", ["Tailoring"] = "TA", ["Camping"] = "CA",
    ["First Aid"] = "FA", ["Cooking"] = "CK", ["Fishing"] = "FI"
}
local SHORT_TO_PROF = {}
for k, v in pairs(PROF_SHORT) do SHORT_TO_PROF[v] = k end

local EQUIP_SLOTS = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19}

GuildNet.CLASS_HEX = CLASS_HEX
GuildNet.PROF_SHORT = PROF_SHORT
GuildNet.SHORT_TO_PROF = SHORT_TO_PROF
GuildNet.EQUIP_SLOTS = EQUIP_SLOTS

local function EnsureGuildNetTables()
    if not AltVaultDB then return false end
    AltVaultDB.RecipeDB = AltVaultDB.RecipeDB or {}
    AltVaultDB.GuildNetwork = AltVaultDB.GuildNetwork or {}
    AltVaultDB.VirtualChatHistory = AltVaultDB.VirtualChatHistory or {}
    AltVaultDB.CharacterVotes = AltVaultDB.CharacterVotes or {}
    AltVaultDB.SyncQueue = AltVaultDB.SyncQueue or {}
    AltVaultDB.IgnoredSyncPlayers = AltVaultDB.IgnoredSyncPlayers or {}
    if AltVaultDB.SyncDND == nil then AltVaultDB.SyncDND = false end
    if AltVaultDB.BlockFriendsOfFriends == nil then AltVaultDB.BlockFriendsOfFriends = false end
    if AltVaultDB.EchoVirtualChat == nil then
        AltVaultDB.EchoVirtualChat = true
    end
    return true
end

local function StripRealm(name)
    if not name then return nil end
    return string.match(name, "^([^%-]+)") or name
end

local function ExtractID(linkOrID)
    if not linkOrID then return nil end
    if type(linkOrID) == "number" then return linkOrID end
    return tonumber(string.match(tostring(linkOrID), "item:(%d+)")) or tonumber(linkOrID)
end

GuildNet.EnsureGuildNetTables = EnsureGuildNetTables
GuildNet.StripRealm = StripRealm
GuildNet.ExtractID = ExtractID

-- ============================================================================
-- BLOCK HEADING: SILENT OFFLINE-WHISPER SYSTEM MESSAGE FILTER
-- ============================================================================
if ChatFrame_AddMessageEventFilter then
    ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", function(_, _, msg)
        if not msg then return false end
        local offlineName = string.match(msg, "No player named '([^']+)' is currently playing")
        if offlineName then
            local clean = StripRealm(offlineName)
            local sentTime = clean and recentWhisperTargets[string.lower(clean)]
            if sentTime and (GetTime() - sentTime) < 6.0 then
                if AltVaultDB and AltVaultDB.GuildNetwork and AltVaultDB.GuildNetwork[clean] then
                    AltVaultDB.GuildNetwork[clean].isOnline = false
                end
                return true
            end
        end
        return false
    end)
end

function GuildNet.IsPeerOnline(peerName)
    if not peerName or not AltVaultDB or not AltVaultDB.GuildNetwork then return false end
    local p = AltVaultDB.GuildNetwork[peerName]
    if not p then return false end
    if p.isOnline == false then return false end
    local lastTS = p.lastSeenTimestamp or 0
    return (time() - lastTS) < 600
end

-- ============================================================================
-- BLOCK HEADING: MULTI-CHANNEL & WHISPER MESH RADIO QUEUE (16001 & 3.3.5a)
-- ============================================================================
local function GetActiveBroadcastChannels()
    local channels = {}
    if IsInGuild and IsInGuild() then
        table.insert(channels, { dist = "GUILD" })
    end

    if IsInGroup and _G.LE_PARTY_CATEGORY_INSTANCE and IsInGroup(_G.LE_PARTY_CATEGORY_INSTANCE) then
        table.insert(channels, { dist = "INSTANCE_CHAT" })
    elseif (IsInRaid and IsInRaid()) or (GetNumRaidMembers and GetNumRaidMembers() > 0) then
        table.insert(channels, { dist = "RAID" })
    elseif (IsInGroup and IsInGroup()) or (GetNumPartyMembers and GetNumPartyMembers() > 0) then
        table.insert(channels, { dist = "PARTY" })
    end
    return channels
end

local activeRadioTicker = nil

local function EnsureRadioDrainRunning()
    if activeRadioTicker then return end
    activeRadioTicker = C_Timer.NewTicker(0.45, function()
        if #sendQueue == 0 then
            if activeRadioTicker and activeRadioTicker.Cancel then
                activeRadioTicker:Cancel()
            end
            activeRadioTicker = nil
            return
        end
        if InCombatLockdown() then return end
        local item = table.remove(sendQueue, 1)
        if not item or not item.msg then return end

        if item.dist == "WHISPER" and item.target then
            recentWhisperTargets[string.lower(item.target)] = GetTime()
        end

        if C_ChatInfo and C_ChatInfo.SendAddonMessage then
            pcall(C_ChatInfo.SendAddonMessage, PREFIX, item.msg, item.dist, item.target)
        elseif SendAddonMessage then
            pcall(SendAddonMessage, PREFIX, item.msg, item.dist, item.target)
        end
    end)
end

local function EnqueuePacket(msg, explicitDist, whisperTarget)
    if not msg or #msg > 250 then return end
    -- Stealth Hygiene: Never broadcast addon data over YELL/SAY
    if explicitDist == "YELL" or explicitDist == "SAY" then return end

    if explicitDist == "WHISPER" then
        if not whisperTarget or whisperTarget == "" or whisperTarget == UnitName("player") then return end
        for _, q in ipairs(sendQueue) do
            if q.msg == msg and q.dist == "WHISPER" and q.target == whisperTarget then return end
        end
        table.insert(sendQueue, { msg = msg, dist = "WHISPER", target = whisperTarget })
        EnsureRadioDrainRunning()
        return
    end

    local targets = explicitDist and { { dist = explicitDist } } or GetActiveBroadcastChannels()
    for _, ch in ipairs(targets) do
        local duplicate = false
        for _, q in ipairs(sendQueue) do
            if q.msg == msg and q.dist == ch.dist then
                duplicate = true
                break
            end
        end
        if not duplicate then
            table.insert(sendQueue, { msg = msg, dist = ch.dist })
        end
    end
    if #sendQueue > 0 then
        EnsureRadioDrainRunning()
    end
end

GuildNet.EnqueuePacket = EnqueuePacket

-- ============================================================================
-- BLOCK HEADING: PERMANENT 1-VOTE-PER-PLAYER RANKING LEDGER (NO RESET ALLOWED)
-- ============================================================================
function GuildNet.GetCharacterRatingSummary(targetName)
    if not EnsureGuildNetTables() or not targetName then
        return 0, 0, 0, nil
    end
    local voterMap = AltVaultDB.CharacterVotes[targetName]
    if not voterMap then
        return 0, 0, 0, nil
    end

    local totalScore, upCount, downCount = 0, 0, 0
    local myVote = nil
    local myChars = AltVaultDB.Characters or {}
    local currentPlayer = UnitName("player")

    for voterName, val in pairs(voterMap) do
        local nVal = tonumber(val) or 0
        if nVal >= 1 then
            totalScore = totalScore + nVal
            upCount = upCount + 1
        elseif nVal == -1 then
            totalScore = totalScore - 1
            downCount = downCount + 1
        end
        if voterName == currentPlayer or myChars[voterName] then
            myVote = (nVal >= 1 and 1) or (nVal <= -1 and -1) or nil
        end
    end

    return totalScore, upCount, downCount, myVote
end

function GuildNet.CanLocalPlayerVoteFor(targetName)
    if not EnsureGuildNetTables() or not targetName then
        return false, "Invalid character."
    end
    local currentPlayer = UnitName("player")
    if targetName == currentPlayer or (AltVaultDB.Characters and AltVaultDB.Characters[targetName]) then
        return false, "You cannot vote on your own characters."
    end

    local _, _, _, existingVote = GuildNet.GetCharacterRatingSummary(targetName)
    if existingVote ~= nil then
        return false, "Your permanent vote for " .. targetName .. " is already locked in!"
    end

    return true, nil
end

function GuildNet.CastPermanentVote(targetName, voteVal)
    if not EnsureGuildNetTables() or not targetName then return false end
    local rawNum = tonumber(voteVal) or 1
    if rawNum >= 3 then voteVal = 3
    elseif rawNum == 2 then voteVal = 2
    elseif rawNum >= 1 then voteVal = 1
    else voteVal = -1 end

    local canVote, reason = GuildNet.CanLocalPlayerVoteFor(targetName)
    if not canVote then
        if reason then
            print("|cffffcc00[FaceVault Ranking]:|r " .. reason)
        end
        return false
    end

    local voterName = UnitName("player")
    if not voterName or voterName == "Unknown" then return false end

    AltVaultDB.CharacterVotes[targetName] = AltVaultDB.CharacterVotes[targetName] or {}
    if AltVaultDB.CharacterVotes[targetName][voterName] ~= nil then
        return false
    end
    AltVaultDB.CharacterVotes[targetName][voterName] = voteVal

    local packet = string.format("VOTE|%s|%s|%d", targetName, voterName, voteVal)
    EnqueuePacket(packet)
    EnqueuePacket(packet, "WHISPER", targetName)

    local faction = UnitFactionGroup("player") or "Alliance"
    for peerName, peerData in pairs(AltVaultDB.GuildNetwork or {}) do
        if peerName ~= voterName and peerName ~= targetName and not (AltVaultDB.Characters and AltVaultDB.Characters[peerName]) then
            if peerData.isSynced == true and not peerData.isPublicFaceVault and (not peerData.faction or peerData.faction == faction) then
                if peerData.isOnline ~= false then
                    EnqueuePacket(packet, "WHISPER", peerName)
                end
            end
        end
    end

    local label = (voteVal == 3 and "|cffffd100👑 Crown (+3)|r")
        or (voteVal == 2 and "|cffff8000🔥 Fire (+2)|r")
        or (voteVal == 1 and "|cff00ff00👍 Like (+1)|r")
        or "|cffff4444Thumbs Down (-1)|r"
    print(string.format("|cff00ff00[FaceVault Runway]:|r Sent %s reaction to |cffffff00%s|r!", label, targetName))
    return true
end

local function RecordIncomingVote(targetName, voterName, voteVal)
    if not targetName or not voterName or targetName == "" or voterName == "" then return false end
    if targetName == voterName then return false end
    voteVal = tonumber(voteVal)
    if not voteVal or (voteVal ~= -1 and voteVal ~= 1 and voteVal ~= 2 and voteVal ~= 3) then return false end

    AltVaultDB.CharacterVotes = AltVaultDB.CharacterVotes or {}
    AltVaultDB.CharacterVotes[targetName] = AltVaultDB.CharacterVotes[targetName] or {}
    if AltVaultDB.CharacterVotes[targetName][voterName] == nil then
        AltVaultDB.CharacterVotes[targetName][voterName] = voteVal
        local myName = UnitName("player")
        if voteVal >= 1 and (targetName == myName or (AltVaultDB.Characters and AltVaultDB.Characters[targetName])) then
            if ns.FaceVault and ns.FaceVault.TriggerVoteFanfareToast then
                local rKey = (voteVal == 3 and "CROWN") or (voteVal == 2 and "FIRE") or "LIKE"
                ns.FaceVault:TriggerVoteFanfareToast(voterName, rKey, targetName .. "'s 3D Look")
            end
        end
        return true
    end
    return false
end

GuildNet.RecordIncomingVote = RecordIncomingVote

-- ============================================================================
-- BLOCK HEADING: VIRTUAL GUILD CHATROOM ENGINE (MULTI-PEER WHISPER + CHANNELS)
-- ============================================================================
local function AppendChatHistory(senderName, senderClass, text)
    if not EnsureGuildNetTables() then return end
    local timeStr = date("%H:%M")
    local hex = CLASS_HEX[senderClass or ""] or "00ff96"

    table.insert(AltVaultDB.VirtualChatHistory, {
        time = timeStr,
        sender = senderName,
        class = senderClass,
        hex = hex,
        text = text
    })

    while #AltVaultDB.VirtualChatHistory > 150 do
        table.remove(AltVaultDB.VirtualChatHistory, 1)
    end

    if AltVaultDB.EchoVirtualChat and DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage(string.format(
            "|cff00ccff[Virtual Guild]|r |cff888888[%s]|r |cff%s[%s]|r: |cfffff569%s|r",
            timeStr, hex, senderName, text
        ))
    end

    if AltVaultMainPanel and AltVaultMainPanel:IsShown() then
        local mode = AltVaultMainPanel.GetActiveViewMode and AltVaultMainPanel:GetActiveViewMode()
        if mode == "VIRTUAL_CHAT" then
            AltVaultMainPanel:RenderActivePane()
        end
    end
end

GuildNet.AppendChatHistory = AppendChatHistory

function GuildNet.SendVirtualChatMessage(rawText)
    if not EnsureGuildNetTables() or not rawText then return end
    local cleanText = string.gsub(rawText, "^%s*(.-)%s*$", "%1")
    cleanText = string.gsub(cleanText, "|", "||")
    if cleanText == "" then return end

    local playerName = UnitName("player") or "Player"
    local _, playerClass = UnitClass("player")
    playerClass = playerClass or "WARRIOR"

    chatMsgCounter = chatMsgCounter + 1
    local msgID = string.format("%s-%d-%d", playerName, time() % 100000, chatMsgCounter)
    seenChatMsgIDs[msgID] = true

    local displayText = string.gsub(cleanText, "||", "|")
    AppendChatHistory(playerName, playerClass, displayText)

    local packet = string.format("VCHAT|%s|%s|%s", msgID, playerClass, displayText)
    if #packet > 248 then
        packet = string.sub(packet, 1, 248)
    end

    local faction = UnitFactionGroup("player") or "Alliance"
    for peerName, peerData in pairs(AltVaultDB.GuildNetwork or {}) do
        if peerName ~= playerName and not (AltVaultDB.Characters and AltVaultDB.Characters[peerName]) then
            if peerData.isSynced == true and not peerData.isPublicFaceVault and (not peerData.faction or peerData.faction == faction) then
                if peerData.isOnline ~= false then
                    EnqueuePacket(packet, "WHISPER", peerName)
                end
            end
        end
    end
end