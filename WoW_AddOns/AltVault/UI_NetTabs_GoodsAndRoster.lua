-- ============================================================================
-- FILE: UI_NetTabs_GoodsAndRoster.lua (MODULE 2 OF 2 SPLIT FROM UI_GuildNetworkTabs.lua)
-- BLOCK HEADING: TABS 7, 8, 9 & 10 RENDERERS, TAB REGISTRATION & TOOLTIP HOOK
-- ============================================================================
local addonName, ns = ...
local MainPanel = _G.AltVaultMainPanel
local NetUI = ns.NetUI
if not MainPanel or not MainPanel.RegisterExternalTab or not NetUI then return end

local ConfigureHeaderForMode = NetUI.ConfigureHeaderForMode
local ContactOrMailSyncedPlayer = NetUI.ContactOrMailSyncedPlayer
local RenderVirtualGuildChatTab = NetUI.RenderVirtualGuildChatTab

local SLOT_LABELS = {
    [1]="Head", [2]="Neck", [3]="Shoulder", [5]="Chest", [6]="Waist",
    [7]="Legs", [8]="Feet", [9]="Wrist", [10]="Hands", [11]="Ring 1",
    [12]="Ring 2", [13]="Trinket 1", [14]="Trinket 2", [15]="Back",
    [16]="Main Hand", [17]="Off Hand", [18]="Ranged"
}
local DISPLAY_SLOTS = {1, 2, 3, 15, 5, 9, 10, 6, 7, 8, 11, 12, 13, 14, 16, 17, 18}

-- ============================================================================
-- BLOCK HEADING: TAB 7 RENDERER (GUILD GEAR NEEDS & CRAFTABLE UPGRADES)
-- ============================================================================
local function RenderGuildGearNeedsTab(panel)
    ConfigureHeaderForMode("GUILD_GEAR")
    local faction = panel:GetSelectedFaction()
    local rows = {}

    local peerCount, recipeCount = 0, 0
    if AltVaultDB then
        for _, p in pairs(AltVaultDB.GuildNetwork or {}) do
            if not p.faction or p.faction == faction then peerCount = peerCount + 1 end
        end
        for _ in pairs(AltVaultDB.RecipeDB or {}) do recipeCount = recipeCount + 1 end
    end

    table.insert(rows, {
        tint = "SPEC_HEADER",
        text = string.format("|cffffd100Virtual Guild Gear Upgrade Network (%s) — %d Locked-In Peers • %d Schematics|r",
            faction, peerCount, recipeCount)
    })
    table.insert(rows, {
        text = "  |cffccccccClick any upgrade row to locate its mats in Tab 8! Synced players stay saved offline so you can craft & mail upgrades anytime.|r"
    })
    table.insert(rows, { text = "|cff555555----------------------------------------------------------------------|r" })

    local upgrades = (ns.GuildNet and ns.GuildNet.GetCraftableGearUpgrades and ns.GuildNet.GetCraftableGearUpgrades(faction)) or {}

    if #upgrades == 0 then
        table.insert(rows, { text = " " })
        table.insert(rows, { text = "  |cff888888No craftable gear upgrades detected yet for your Alts or Synced Players.|r" })
        table.insert(rows, { text = "  • Open your Crafting Professions (Blacksmithing, Tailoring, Leatherworking, Engineering) so AltVault learns your recipes." })
        table.insert(rows, { text = "  • Use |cff00ff00[Sync All Net]|r or type a friend's name & click |cff00ff00[Whisper Sync]|r above!" })
    else
        for _, u in ipairs(upgrades) do
            local targetBadge = u.isGuildmate
                and string.format("|cff00ccff[Synced: %s - Lvl %d %s]|r", u.targetName, u.targetLevel, u.targetClass)
                or string.format("|cff00ff96[Alt: %s - Lvl %d %s]|r", u.targetName, u.targetLevel, u.targetClass)

            local readyBadge = u.allMatsReady
                and "|cff00ff00[ALL MATS READY!]|r"
                or "|cffffaa00[Mats Needed]|r"

            local tooltipText = string.format(
                "|cffffd100Craftable Upgrade for %s|r\n• Gain: |cff00ff00+%d GearScore|r (Req Lvl %d)\n• Profession: |cff00ffff%s (%d)|r\n• Known By: |cffffffff%s|r\n• Last Seen: |cffcccccc%s|r\n• Network Materials: %s\n\n|cffffd100Left-Click:|r Jump to Tab 8 (Mat Search) for this recipe!",
                u.targetName, u.deltaGS, u.reqLvl, u.prof or "Craft", u.reqSkill or 1, u.crafters, u.targetSeen or "Recently", u.matSummary
            )

            table.insert(rows, {
                icon = u.icon,
                link = u.itemLink,
                tint = u.allMatsReady and "UPGRADE_SOON" or "UPGRADE",
                recommendNote = tooltipText,
                text = string.format("%s  %s  |cff00ff00(+%d GS)|r  •  %s  •  Crafter: |cffffffff%s|r",
                    targetBadge, u.itemLink, u.deltaGS, readyBadge, u.crafters),
                onClickAction = function()
                    NetUI.state.selectedRecipeForMats = u
                    panel:SwitchToTab("GUILD_MATS")
                end
            })
            table.insert(rows, {
                text = string.format("      |cffaaaaaaMats:|r %s   |cffffd100[Click here to Mail / Whisper %s]|r", u.matSummary, u.targetName),
                onClickAction = function()
                    ContactOrMailSyncedPlayer(u.targetName, u.itemLink, true)
                end
            })
        end
    end

    panel:RenderRowList(rows)
end

-- ============================================================================
-- BLOCK HEADING: TAB 8 RENDERER (GUILD MAT SEARCH — ALTS + VAULT + SYNCED PEERS)
-- ============================================================================
local function RenderGuildMatSearchTab(panel)
    ConfigureHeaderForMode("GUILD_MATS")
    local faction = panel:GetSelectedFaction()
    local rows = {}
    local selectedRecipeForMats = NetUI.state.selectedRecipeForMats

    if selectedRecipeForMats and ns.GuildNet then
        local r = selectedRecipeForMats
        table.insert(rows, {
            tint = "SPEC_HEADER",
            icon = r.icon,
            link = r.itemLink,
            text = string.format("|cffffd100Material Scavenger Hunt for:|r %s  |cff00ff00(For %s, +%d GS)|r  —  |cffffd100[Click 'Show All Mats' above to clear]|r",
                r.itemLink, r.targetName or "Target", r.deltaGS or 0)
        })
        table.insert(rows, {
            text = string.format("  |cffccccccProfession: %s (%d)  •  Known Crafters: %s  •  Target Last Seen: %s|r",
                r.prof or "Craft", r.reqSkill or 1, r.crafters or "You", r.targetSeen or "Active")
        })
        table.insert(rows, { text = "|cff555555----------------------------------------------------------------------|r" })

        for _, rg in ipairs(r.reagents or {}) do
            local loc = ns.GuildNet.LocateMaterialAcrossNetwork(rg.id, faction)
            local rName, rLink, _, _, _, _, _, _, _, rIcon = ns.Scanner.FetchItemInfo(rg.id)
            rName = rName or rg.name or ("Item #" .. rg.id)
            rLink = rLink or ("item:" .. rg.id)
            local have = loc.totalAvailable or 0
            local need = rg.count or 1
            local statusColor = (have >= need) and "|cff00ff00" or "|cffff5555"

            table.insert(rows, {
                icon = rIcon or "Interface\\Icons\\INV_Misc_QuestionMark",
                link = rLink,
                tint = (have >= need) and "UPGRADE" or "PROF",
                text = string.format("%s   —   %sAvailable on Network: %d / %d Needed|r", rLink, statusColor, have, need)
            })

            if #loc.sources == 0 then
                table.insert(rows, {
                    text = "      |cffff5555• None found in Alts' Bags/Banks, Guild Vault, or Synced Players.|r"
                })
            else
                for _, src in ipairs(loc.sources) do
                    if src.isGuildmate then
                        table.insert(rows, {
                            tint = "PROF_SOON",
                            recommendNote = "Left-Click to Whisper " .. src.owner .. " (or auto-fill Mailbox 'To:' if at a Mailbox)!",
                            text = string.format("      |cff00ffff• %dx held by %s|r   |cffffd100[Click to Whisper / Mail %s]|r",
                                src.count, src.location, src.owner),
                            onClickAction = function()
                                ContactOrMailSyncedPlayer(src.owner, rLink, false)
                            end
                        })
                    elseif src.isGuildVault then
                        table.insert(rows, {
                            text = string.format("      |cffffd100• %dx in %s|r", src.count, src.location)
                        })
                    else
                        table.insert(rows, {
                            text = string.format("      |cff00ff96• %dx in %s|r", src.count, src.location)
                        })
                    end
                end
            end
            table.insert(rows, { text = " " })
        end

        panel:RenderRowList(rows)
        return
    end

    table.insert(rows, {
        tint = "SPEC_HEADER",
        text = string.format("|cffffd100Virtual Guild Material Locator (%s) — Alts, Guild Vault & Synced Players|r", faction)
    })
    table.insert(rows, {
        text = "  |cffccccccClick any material row held by a Synced Player to Whisper them (or auto-fill Mailbox 'To:')!|r"
    })
    table.insert(rows, { text = "|cff555555----------------------------------------------------------------------|r" })

    local seenMatIDs = {}
    local function CollectLocalID(id)
        if id and type(id) == "number" then
            if not (ns.DB and ns.DB.IsItemTradeLocked and ns.DB.IsItemTradeLocked(id)) then
                seenMatIDs[id] = true
            end
        end
    end
    local function CollectPeerID(id)
        if id and type(id) == "number" then seenMatIDs[id] = true end
    end

    if AltVaultDB then
        for _, cData in pairs(AltVaultDB.Characters or {}) do
            if not faction or cData.faction == faction then
                for _, it in ipairs(cData.bags or {}) do CollectLocalID(ns.Scanner.ExtractItemID(it.link or it.itemID)) end
                for _, it in ipairs(cData.bank or {}) do CollectLocalID(ns.Scanner.ExtractItemID(it.link or it.itemID)) end
            end
        end
        for _, vData in pairs(AltVaultDB.GuildVaults or {}) do
            if not faction or vData.faction == faction then
                for tIdx = 1, 8 do
                    local tab = vData.tabs and vData.tabs[tIdx]
                    if tab then
                        for _, it in ipairs(tab.items or {}) do CollectLocalID(ns.Scanner.ExtractItemID(it.link)) end
                    end
                end
            end
        end
        for _, pData in pairs(AltVaultDB.GuildNetwork or {}) do
            if not faction or pData.faction == faction then
                for id in pairs(pData.mats or {}) do CollectPeerID(id) end
                if type(pData.guildVault) == "table" then
                    for _, tabItems in pairs(pData.guildVault) do
                        for id in pairs(tabItems or {}) do CollectPeerID(id) end
                    end
                end
            end
        end
    end

    local filterLower = string.lower(NetUI.state.matSearchFilterText or "")
    local matRowsData = {}

    for id in pairs(seenMatIDs) do
        local name, link, _, _, _, itemType, _, _, _, icon, _, classID, _, _, _, _, isReagent = ns.Scanner.FetchItemInfo(id)
        local isMat = (classID == 7) or (itemType == "Trade Goods") or (itemType == "Tradeskill") or (isReagent == true)
        if name and isMat then
            local trades = ns.Scanner.GetMaterialProfessionsList and ns.Scanner.GetMaterialProfessionsList(link or id)
            local tradesStr = (trades and #trades > 0) and table.concat(trades, ", ") or "Crafting"
            if filterLower == ""
                or string.find(string.lower(name), filterLower, 1, true)
                or string.find(string.lower(tradesStr), filterLower, 1, true) then
                local loc = ns.GuildNet.LocateMaterialAcrossNetwork(id, faction)
                if loc.totalAvailable > 0 then
                    table.insert(matRowsData, {
                        id = id,
                        name = name,
                        link = link or ("item:" .. id),
                        icon = icon or "Interface\\Icons\\INV_Misc_QuestionMark",
                        tradesStr = tradesStr,
                        loc = loc
                    })
                end
            end
        end
    end

    table.sort(matRowsData, function(a, b)
        if a.loc.totalAvailable ~= b.loc.totalAvailable then
            return a.loc.totalAvailable > b.loc.totalAvailable
        end
        return a.name < b.name
    end)

    for _, m in ipairs(matRowsData) do
        local locParts = {}
        for _, s in ipairs(m.loc.sources) do
            if s.isGuildmate then
                table.insert(locParts, string.format("|cff00ffff%s (%dx)|r", s.owner, s.count))
            elseif s.isGuildVault then
                table.insert(locParts, string.format("|cffffd100%s (%dx)|r", s.location, s.count))
            else
                table.insert(locParts, string.format("|cff00ff96%s (%dx)|r", s.location, s.count))
            end
        end

        local firstPeer = m.loc.holdersToWhisper and m.loc.holdersToWhisper[1]
        local whisperBadge = firstPeer and ("   |cffffd100[Click to Contact " .. firstPeer .. "]|r") or ""

        table.insert(rows, {
            icon = m.icon,
            link = m.link,
            tint = firstPeer and "PROF_SOON" or "PROF",
            recommendNote = "Used By: " .. m.tradesStr .. "\nHolders: " .. table.concat(locParts, ", "),
            text = string.format("%s |cffffff00x%d|r  |cff88ccff[%s]|r  —  %s%s",
                m.link, m.loc.totalAvailable, m.tradesStr, table.concat(locParts, " / "), whisperBadge),
            onClickAction = firstPeer and function()
                ContactOrMailSyncedPlayer(firstPeer, m.link, false)
            end or nil
        })
    end

    if #matRowsData == 0 then
        table.insert(rows, { text = "  |cff888888No matching crafting materials found across your Alts, Guild Vault, or Synced Players.|r" })
    end

    panel:RenderRowList(rows)
end

-- ============================================================================
-- BLOCK HEADING: TAB 9 RENDERER (GUILD CONSUMABLES NETWORK)
-- ============================================================================
local function RenderGuildConsumablesTab(panel)
    ConfigureHeaderForMode("GUILD_CONS")
    local faction = panel:GetSelectedFaction()
    local activeConsCategory = NetUI.state.activeConsCategory or "ALL"
    local rows = {}

    table.insert(rows, {
        tint = "SPEC_HEADER",
        text = string.format("|cffffd100Virtual Guild Consumables Network (%s) — Filter: [%s]|r", faction, activeConsCategory)
    })
    table.insert(rows, {
        text = "  |cffccccccPotions, Elixirs, Scrolls, Food, Drink & Bandages across Alts, Guild Vault & Synced Players. Click any row to Whisper/Mail!|r"
    })
    table.insert(rows, { text = "|cff555555----------------------------------------------------------------------|r" })

    local consList = (ns.GuildNet and ns.GuildNet.GetGuildConsumablesList and ns.GuildNet.GetGuildConsumablesList(faction, activeConsCategory)) or {}

    if #consList == 0 then
        table.insert(rows, { text = " " })
        table.insert(rows, { text = "  |cff888888No consumables found for this category yet.|r" })
    else
        for _, c in ipairs(consList) do
            local whisperTarget = c.firstWhisperTarget
            local whisperTag = whisperTarget and ("   |cffffd100[Click to Contact " .. whisperTarget .. "]|r") or ""
            local craftTag = c.crafterNote and ("   |cff00ff96(" .. c.crafterNote .. ")|r") or ""
            local holdersStr = table.concat(c.holders, " / ")

            table.insert(rows, {
                icon = c.icon,
                link = c.link,
                tint = whisperTarget and "UPGRADE_SOON" or "UPGRADE",
                recommendNote = string.format("%s (Req Lvl %d)\nHolders: %s%s",
                    c.category, c.reqLvl or 1, holdersStr, c.crafterNote and ("\n" .. c.crafterNote) or ""),
                text = string.format("|cff88ccff[%s]|r %s |cffffff00x%d|r |cffcccccc(Req %d)|r  —  %s%s%s",
                    c.category, c.link, c.totalCount, c.reqLvl or 1, holdersStr, craftTag, whisperTag),
                onClickAction = whisperTarget and function()
                    ContactOrMailSyncedPlayer(whisperTarget, c.link, false)
                end or nil
            })
        end
    end

    panel:RenderRowList(rows)
end

-- ============================================================================
-- BLOCK HEADING: TAB 10 RENDERER (SYNC QUEUE WAITLIST & INTERACTIVE SYNC HUB)
-- ============================================================================
local REQ_CATEGORY_DESC = {
    PROFILE = "Initial Basic Profile Sync (3D Armory, Gear & Profession Levels)",
    BAGS    = "Bag Inventory Sync (See Possible Trades & Bag Items)",
    BANK    = "Personal Bank Sync (See Bank Vault Stockpile)",
    RECIPES = "Profession Levels & Known Craftable Recipes",
    TALENTS = "Talent Tree & Specialization Build",
    VGUILD  = "Virtual Guild Network List (Friends-of-Friends Sync)",
    ALT     = "Single Alt Character Sync"
}

local function RenderSyncedRosterTab(panel)
    ConfigureHeaderForMode("SYNCED_ROSTER")
    local rows = {}

    -- ========================================================================
    -- INCOMING SYNC QUEUE (WAITLIST) — ONLY PLAYERS WAITING IN QUEUE
    -- ========================================================================
    local queue = (AltVaultDB and AltVaultDB.SyncQueue) or {}
    local dndState = (AltVaultDB and AltVaultDB.SyncDND) and "|cffff5555ON (Auto-Ignoring Requests)|r" or "|cff00ff00OFF (Accepting Requests into Waitlist)|r"
    local fofState = (AltVaultDB and AltVaultDB.BlockFriendsOfFriends) and "|cffff8800ON (Hidden from Friends-of-Friends)|r" or "|cff00ff00OFF (Shareable in Virtual Guild Lists)|r"

    table.insert(rows, {
        tint = "SPEC_HEADER",
        text = string.format("|cffffd100SYNC QUEUE (WAITLIST): %d Pending|r   •   |cffccccccDND:|r %s   •   |cffccccccBlock FoF:|r %s",
            #queue, dndState, fofState)
    })

    if #queue > 0 then
        for qIdx, qItem in ipairs(queue) do
            local reqDesc = REQ_CATEGORY_DESC[qItem.reqType or "PROFILE"] or (qItem.reqType or "Sync")
            if qItem.reqType == "ALT" and qItem.altName and qItem.altName ~= "" then
                reqDesc = "Alt Character Sync: |cff00ffff[" .. qItem.altName .. "]|r"
            end

            local pList = {}
            for pName, pRank in pairs(qItem.profs or {}) do
                table.insert(pList, string.format("%s (%d)", pName, pRank))
            end
            table.sort(pList)
            local profSummary = (#pList > 0) and table.concat(pList, ", ") or "None Listed"

            table.insert(rows, {
                tint = "UPGRADE_SOON",
                text = string.format("|cffffd100#%d [%s]|r |cff00ffff%s|r (Lvl %d %s %s • GS: %s • Profs: %s)  ->  Requesting: |cffffff00%s|r",
                    qIdx, qItem.timestamp or "Now", qItem.sender or "?",
                    qItem.level or 1, qItem.race or "", qItem.class or "?",
                    ns.Scanner.FormatGearScoreColor(qItem.gearScore or 0), profSummary, reqDesc)
            })

            -- Action Row A: One-Way Caller ID Preview (Does NOT share your data)
            table.insert(rows, {
                tint = "PROF",
                text = string.format("      |cff00ffff[1. PREVIEW %s'S BASIC PROFILE IN 3D ARMORY]|r  |cffaaaaaa(One-Way Caller ID Preview — Does NOT Share Your Info)|r",
                    string.upper(qItem.sender or "PLAYER")),
                onClickAction = function()
                    if panel._state then
                        panel._state.previewQueueEntry = qItem
                    end
                    panel:SelectCategoryTab("ARMORY")
                end
            })

            -- Action Row B: Accept & Whisper Sync Reply
            local capturedIdx = qIdx
            table.insert(rows, {
                tint = "UPGRADE",
                text = string.format("      |cff00ff00[2. ACCEPT & WHISPER SYNC REPLY TO %s]|r  |cffcccccc(Approves & Shares Requested %s)|r",
                    string.upper(qItem.sender or "PLAYER"), qItem.reqType or "PROFILE"),
                onClickAction = function()
                    if ns.GuildNet and ns.GuildNet.ApproveQueueItem then
                        ns.GuildNet.ApproveQueueItem(capturedIdx)
                    end
                end
            })

            -- Action Row C: Deny or Ignore Player
            table.insert(rows, {
                text = string.format("      |cffff5555[3. DENY REQUEST]|r  |cffaaaaaa(Left-Click: Deny Request   •   Right-Click or Shift-Click: Block & Ignore %s)|r",
                    qItem.sender or "Player"),
                onClickAction = function(_, mouseButton)
                    local doIgnore = IsShiftKeyDown() or (mouseButton == "RightButton")
                    if ns.GuildNet and ns.GuildNet.DenyQueueItem then
                        ns.GuildNet.DenyQueueItem(capturedIdx, doIgnore)
                    end
                end
            })
            table.insert(rows, { text = "|cff444444----------------------------------------------------------------------|r" })
        end
    end

    panel:RenderRowList(rows)
end

-- ============================================================================
-- BLOCK HEADING: REGISTER TABS 7, 8, 9, 10 & 11 ON ALTVAULT MAIN PANEL
-- ============================================================================
MainPanel:RegisterExternalTab(
    "GUILD_GEAR",
    "Guild Gear Needs",
    "See which Alts & Synced Players need craftable gear upgrades, who can craft them, and click any upgrade to locate its mats!",
    RenderGuildGearNeedsTab
)

MainPanel:RegisterExternalTab(
    "GUILD_MATS",
    "Guild Mat Search",
    "Locate crafting materials across Your Alts, Outside Guild Vaults, and Synced Players' Bags/Banks (Click to Whisper or Mail!).",
    RenderGuildMatSearchTab
)

MainPanel:RegisterExternalTab(
    "GUILD_CONS",
    "Consumables Net",
    "Track Potions, Elixirs, Scrolls, Food, Drink & Bandages across your Alts, Outside Guild Vaults & Synced Players.",
    RenderGuildConsumablesTab
)

MainPanel:RegisterExternalTab(
    "SYNCED_ROSTER",
    "Sync Queue & Hub",
    "Manage your Incoming Sync Queue (Waitlist), preview callers one-way, toggle DND / Block Friends-of-Friends, and request Bags, Bank, Recipes, Talents & Alts from Synced Peers!",
    RenderSyncedRosterTab
)

MainPanel:RegisterExternalTab(
    "VIRTUAL_CHAT",
    "Virtual Guild Chat",
    "Live Virtual Guild Chatroom powered by the addon whisper mesh—chat and link items with all online synced peers across any guild!",
    RenderVirtualGuildChatTab
)

if MainPanel.ApplyGlobalButtonScaling then
    MainPanel:ApplyGlobalButtonScaling(false)
end

-- ============================================================================
-- BLOCK HEADING: LIVE TOOLTIP HOOK FOR GUILD CRAFTING UPGRADE MATERIALS
-- ============================================================================
local function AppendGuildCraftNotesToTooltip(tooltip)
    if tooltip ~= GameTooltip or not ns.GuildNet or not ns.GuildNet.GetMaterialCraftUpgradeNotes then return end
    local _, itemLink
    if TooltipUtil and TooltipUtil.GetDisplayedItem then
        _, itemLink = TooltipUtil.GetDisplayedItem(tooltip)
    end
    if not itemLink and tooltip.GetItem then
        _, itemLink = tooltip:GetItem()
    end
    if not itemLink or tooltip.avGuildMatAppended == itemLink then return end
    tooltip.avGuildMatAppended = itemLink

    local faction = UnitFactionGroup("player") or "Alliance"
    local craftUpgrades = ns.GuildNet.GetMaterialCraftUpgradeNotes(itemLink, faction)
    if craftUpgrades and #craftUpgrades > 0 then
        for i = 1, math.min(#craftUpgrades, 3) do
            local u = craftUpgrades[i]
            local whoType = u.isGuildmate and "Synced" or "Alt"
            tooltip:AddDoubleLine(
                string.format("|cffffd100⚒ Crafts Upgrade for %s %s:|r", whoType, u.targetName),
                string.format("%s |cff00ff00(+%d GS)|r", u.itemLink or u.itemName, u.deltaGS),
                1, 0.82, 0, 0, 1, 0.3
            )
        end
        tooltip:Show()
    end
end

if _G.TooltipDataProcessor and _G.TooltipDataProcessor.AddTooltipPostCall and _G.Enum and _G.Enum.TooltipDataType then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, AppendGuildCraftNotesToTooltip)
end

pcall(GameTooltip.HookScript, GameTooltip, "OnTooltipSetItem", AppendGuildCraftNotesToTooltip)
pcall(GameTooltip.HookScript, GameTooltip, "OnTooltipCleared", function(self)
    self.avGuildMatAppended = nil
end)
pcall(GameTooltip.HookScript, GameTooltip, "OnHide", function(self)
    self.avGuildMatAppended = nil
end)