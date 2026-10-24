-- ============================================================================
-- FILE: Core_Compat.lua (MODULE 1 OF 4 SPLIT FROM Core_Database.lua)
-- BLOCK HEADING: UNIVERSAL 3.3.5a, MOP CLASSIC & FOREVER 16001 SHIMS & CONSTANTS
-- ============================================================================
local addonName, ns = ...
ns.Compat = ns.Compat or {}
ns.DB = ns.DB or {}
ns.DB.MAX_CRAWL_ID = 500000

-- 1. Safe Event Registration Helper (Prevents unknown legacy events from throwing errors)
function ns.Compat.SafeRegisterEvent(frame, eventName)
    if not frame or not eventName then return end
    pcall(frame.RegisterEvent, frame, eventName)
end

-- 2. Safe Backdrop Frame Creator (Works on 3.3.5a, MoP Classic, and 16001 BackdropTemplate)
function ns.Compat.CreateBackdropFrame(frameType, frameName, parentFrame, extraTemplate)
    frameType = frameType or "Frame"
    if _G.BackdropTemplateMixin then
        local tpl = extraTemplate and (extraTemplate .. ", BackdropTemplate") or "BackdropTemplate"
        local ok, f = pcall(CreateFrame, frameType, frameName, parentFrame, tpl)
        if ok and f then return f end
    end
    if extraTemplate then
        local ok, f = pcall(CreateFrame, frameType, frameName, parentFrame, extraTemplate)
        if ok and f then return f end
    end
    return CreateFrame(frameType, frameName, parentFrame)
end

-- 3. Safe Solid Color Texture Setter (SetColorTexture in modern vs SetTexture in 3.3.5a)
function ns.Compat.SetSolidColor(tex, r, g, b, a)
    if not tex then return end
    if tex.SetColorTexture then
        tex:SetColorTexture(r, g, b, a or 1.0)
    elseif tex.SetTexture then
        tex:SetTexture(r, g, b, a or 1.0)
    end
end

-- 4. Global C_Timer Polyfill for WotLK 3.3.5a / Legacy 5.4.8 (Idle when C_Timer exists)
if not _G.C_Timer then
    _G.C_Timer = {}
    local timerQueue = {}
    local timerFrame = CreateFrame("Frame", "AltVaultCompatTimerFrame")
    timerFrame:SetScript("OnUpdate", function(_, elapsed)
        if #timerQueue == 0 then return end
        local i = 1
        while i <= #timerQueue do
            local t = timerQueue[i]
            if t.cancelled then
                table.remove(timerQueue, i)
            else
                t.remaining = t.remaining - elapsed
                if t.remaining <= 0 then
                    if t.isTicker then
                        if t.iterations then
                            t.iterations = t.iterations - 1
                            if t.iterations <= 0 then
                                t.cancelled = true
                            end
                        end
                        t.remaining = t.interval
                        pcall(t.callback)
                        if t.cancelled then
                            table.remove(timerQueue, i)
                        else
                            i = i + 1
                        end
                    else
                        table.remove(timerQueue, i)
                        pcall(t.callback)
                    end
                else
                    i = i + 1
                end
            end
        end
    end)

    function _G.C_Timer.After(duration, callback)
        if type(callback) ~= "function" then return end
        table.insert(timerQueue, {
            remaining = math.max(0.01, tonumber(duration) or 0.01),
            callback = callback,
            isTicker = false,
            cancelled = false
        })
    end

    function _G.C_Timer.NewTicker(interval, callback, iterations)
        local tickerObj = {
            interval = math.max(0.01, tonumber(interval) or 0.1),
            remaining = math.max(0.01, tonumber(interval) or 0.1),
            callback = callback,
            iterations = iterations,
            isTicker = true,
            cancelled = false
        }
        function tickerObj:Cancel()
            self.cancelled = true
        end
        function tickerObj:IsCancelled()
            return self.cancelled
        end
        if type(callback) == "function" then
            table.insert(timerQueue, tickerObj)
        end
        return tickerObj
    end
end

-- 5. Global C_Container Polyfill for WotLK 3.3.5a / Legacy 5.4.8 (Idle when C_Container exists)
if not _G.C_Container then
    _G.C_Container = {}
end
if not _G.C_Container.GetContainerNumSlots and _G.GetContainerNumSlots then
    function _G.C_Container.GetContainerNumSlots(bagID)
        return _G.GetContainerNumSlots(bagID)
    end
end
if not _G.C_Container.GetContainerItemInfo and _G.GetContainerItemInfo then
    function _G.C_Container.GetContainerItemInfo(bagID, slotID)
        local icon, count, locked, quality, readable, lootable, link = _G.GetContainerItemInfo(bagID, slotID)
        if not link and _G.GetContainerItemLink then
            link = _G.GetContainerItemLink(bagID, slotID)
        end
        if not icon and not link then return nil end
        local itemID = link and tonumber(string.match(link, "item:(%d+)")) or nil
        return {
            iconFileID = icon,
            stackCount = count or 1,
            isLocked = locked,
            quality = quality,
            isReadable = readable,
            hasLoot = lootable,
            hyperlink = link,
            itemID = itemID
        }
    end
end

-- ============================================================================
-- BLOCK HEADING: SHARED HIDDEN SCAN TOOLTIP & CORE LOOKUP TABLES
-- ============================================================================
local ScanTip = CreateFrame("GameTooltip", "AltVaultTalentScanTooltip", nil, "GameTooltipTemplate")
ScanTip:SetOwner(WorldFrame, "ANCHOR_NONE")
ns.DB.ScanTip = ScanTip

ns.DB.PRIMARY_PROFESSIONS = {
    ["Alchemy"] = true, ["Blacksmithing"] = true, ["Enchanting"] = true,
    ["Engineering"] = true, ["Herbalism"] = true, ["Inscription"] = true,
    ["Jewelcrafting"] = true, ["Leatherworking"] = true, ["Mining"] = true,
    ["Skinning"] = true, ["Tailoring"] = true, ["Camping"] = true
}

ns.DB.TRACKED_PROFESSIONS = {
    ["Alchemy"] = true, ["Blacksmithing"] = true, ["Enchanting"] = true,
    ["Engineering"] = true, ["Herbalism"] = true, ["Inscription"] = true,
    ["Jewelcrafting"] = true, ["Leatherworking"] = true, ["Mining"] = true,
    ["Skinning"] = true, ["Tailoring"] = true, ["Camping"] = true,
    ["First Aid"] = true, ["Cooking"] = true, ["Fishing"] = true,
    ["Archaeology"] = true
}

ns.DB.NON_CONSUMING_GATHER_PROFS = {
    ["Fishing"]     = true,
    ["Herbalism"]   = true,
    ["Skinning"]    = true,
    ["Archaeology"] = true,
}

ns.DB.PROF_TO_CODE = {
    ["Alchemy"] = "AL", ["Blacksmithing"] = "BS", ["Enchanting"] = "EN",
    ["Engineering"] = "EG", ["Herbalism"] = "HE", ["Inscription"] = "IN",
    ["Jewelcrafting"] = "JC", ["Leatherworking"] = "LW", ["Mining"] = "MI",
    ["Skinning"] = "SK", ["Tailoring"] = "TA", ["Camping"] = "CA",
    ["First Aid"] = "FA", ["Cooking"] = "CK", ["Fishing"] = "FI",
    ["Archaeology"] = "AR"
}

ns.DB.CODE_TO_PROF = {}
for profName, code in pairs(ns.DB.PROF_TO_CODE) do
    ns.DB.CODE_TO_PROF[code] = profName
end

ns.DB.RACE_TO_FACTION = {
    ["Human"] = "Alliance", ["Dwarf"] = "Alliance", ["Night Elf"] = "Alliance",
    ["NightElf"] = "Alliance", ["Gnome"] = "Alliance", ["Draenei"] = "Alliance",
    ["Worgen"] = "Alliance", ["High Elf"] = "Alliance", ["Void Elf"] = "Alliance",
    ["High Order Skyborne"] = "Alliance", ["Lightforged Draenei"] = "Alliance",
    ["Dark Iron Dwarf"] = "Alliance", ["Kul Tiran"] = "Alliance", ["Mechagnome"] = "Alliance",
    ["Orc"] = "Horde", ["Undead"] = "Horde", ["Scourge"] = "Horde",
    ["Tauren"] = "Horde", ["Troll"] = "Horde", ["Blood Elf"] = "Horde",
    ["BloodElf"] = "Horde", ["Goblin"] = "Horde", ["Nightborne"] = "Horde",
    ["Windshaper Skyborne"] = "Horde", ["Highmountain Tauren"] = "Horde",
    ["Zandalari Troll"] = "Horde", ["Vulpera"] = "Horde", ["Mag'har Orc"] = "Horde"
}

ns.DB.RACE_FILE_DISPLAY = {
    ["NightElf"] = "Night Elf",
    ["BloodElf"] = "Blood Elf",
    ["Scourge"]  = "Undead",
    ["HighElf"]  = "High Elf",
    ["Pandaren"] = "Pandaren",
}

ns.DB.CLASS_TALENT_SPECS = {
    WARRIOR     = {
        [1] = { name = "Arms",             role = "MELEE_STR",  icon = "Interface\\Icons\\Ability_Warrior_SavageBlow" },
        [2] = { name = "Fury",             role = "MELEE_STR",  icon = "Interface\\Icons\\Ability_Warrior_InnerRage" },
        [3] = { name = "Protection",       role = "TANK",       icon = "Interface\\Icons\\Ability_Warrior_DefensiveStance" }
    },
    PALADIN     = {
        [1] = { name = "Holy",             role = "HEALER",     icon = "Interface\\Icons\\Spell_Holy_HolyBolt" },
        [2] = { name = "Protection",       role = "TANK",       icon = "Interface\\Icons\\Spell_Holy_DevotionAura" },
        [3] = { name = "Retribution",      role = "MELEE_STR",  icon = "Interface\\Icons\\Spell_Holy_AuraOfLight" }
    },
    DEATHKNIGHT = {
        [1] = { name = "Blood",            role = "TANK",       icon = "Interface\\Icons\\Spell_Deathknight_BloodPresence" },
        [2] = { name = "Frost",            role = "MELEE_STR",  icon = "Interface\\Icons\\Spell_Deathknight_FrostPresence" },
        [3] = { name = "Unholy",           role = "MELEE_STR",  icon = "Interface\\Icons\\Spell_Deathknight_UnholyPresence" }
    },
    HUNTER      = {
        [1] = { name = "Beast Mastery",    role = "MELEE_AGI",  icon = "Interface\\Icons\\Ability_Hunter_BeastTaming" },
        [2] = { name = "Marksmanship",     role = "MELEE_AGI",  icon = "Interface\\Icons\\Ability_Marksmanship" },
        [3] = { name = "Survival",         role = "MELEE_AGI",  icon = "Interface\\Icons\\Ability_Hunter_SwiftStrike" }
    },
    SHAMAN      = {
        [1] = { name = "Elemental Combat", role = "CASTER_DPS", icon = "Interface\\Icons\\Spell_Nature_Lightning" },
        [2] = { name = "Enhancement",      role = "MELEE_AGI",  icon = "Interface\\Icons\\Spell_Nature_LightningShield" },
        [3] = { name = "Restoration",      role = "HEALER",     icon = "Interface\\Icons\\Spell_Nature_MagicImmunity" }
    },
    ROGUE       = {
        [1] = { name = "Assassination",    role = "MELEE_AGI",  icon = "Interface\\Icons\\Ability_Rogue_Eviscerate" },
        [2] = { name = "Combat",           role = "MELEE_AGI",  icon = "Interface\\Icons\\Ability_BackStab" },
        [3] = { name = "Subtlety",         role = "MELEE_AGI",  icon = "Interface\\Icons\\Ability_Stealth" }
    },
    DRUID       = {
        [1] = { name = "Balance",          role = "CASTER_DPS", icon = "Interface\\Icons\\Spell_Nature_StarFall" },
        [2] = { name = "Feral Combat",     role = "MELEE_AGI",  icon = "Interface\\Icons\\Ability_Racial_BearForm" },
        [3] = { name = "Restoration",      role = "HEALER",     icon = "Interface\\Icons\\Spell_Nature_HealingTouch" },
        [4] = { name = "Guardian",         role = "TANK",       icon = "Interface\\Icons\\Ability_Racial_BearForm" }
    },
    PRIEST      = {
        [1] = { name = "Discipline",       role = "HEALER",     icon = "Interface\\Icons\\Spell_Holy_WordFortitude" },
        [2] = { name = "Holy",             role = "HEALER",     icon = "Interface\\Icons\\Spell_Holy_GuardianSpirit" },
        [3] = { name = "Shadow",           role = "CASTER_DPS", icon = "Interface\\Icons\\Spell_Shadow_ShadowWordPain" }
    },
    MAGE        = {
        [1] = { name = "Arcane",           role = "CASTER_DPS", icon = "Interface\\Icons\\Spell_Holy_MagicalSentry" },
        [2] = { name = "Fire",             role = "CASTER_DPS", icon = "Interface\\Icons\\Spell_Fire_FireBolt02" },
        [3] = { name = "Frost",            role = "CASTER_DPS", icon = "Interface\\Icons\\Spell_Frost_FrostBolt02" }
    },
    WARLOCK     = {
        [1] = { name = "Affliction",       role = "CASTER_DPS", icon = "Interface\\Icons\\Spell_Shadow_DeathCoil" },
        [2] = { name = "Demonology",       role = "CASTER_DPS", icon = "Interface\\Icons\\Spell_Shadow_Metamorphosis" },
        [3] = { name = "Destruction",      role = "CASTER_DPS", icon = "Interface\\Icons\\Spell_Shadow_RainOfFire" }
    },
    MONK        = {
        [1] = { name = "Brewmaster",       role = "TANK",       icon = "Interface\\Icons\\Spell_Monk_Brewmaster_Spec" },
        [2] = { name = "Mistweaver",       role = "HEALER",     icon = "Interface\\Icons\\Spell_Monk_Mistweaver_Spec" },
        [3] = { name = "Windwalker",       role = "MELEE_AGI",  icon = "Interface\\Icons\\Spell_Monk_Windwalker_Spec" }
    },
}

ns.DB.DEFAULT_CLASS_ROLE = {
    WARRIOR = "MELEE_STR", PALADIN = "MELEE_STR", DEATHKNIGHT = "MELEE_STR",
    HUNTER = "MELEE_AGI", SHAMAN = "MELEE_AGI", ROGUE = "MELEE_AGI", DRUID = "MELEE_AGI",
    MONK = "MELEE_AGI", PRIEST = "HEALER", MAGE = "CASTER_DPS", WARLOCK = "CASTER_DPS"
}