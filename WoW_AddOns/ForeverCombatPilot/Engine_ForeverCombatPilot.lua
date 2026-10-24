-- ============================================================================
-- Engine_ForeverCombatPilot.lua
-- DECONSTRUCTION GOD STUDIO v14.3 x ALTVAULT v3.1 — FOREVER COMBAT PILOT
-- Synthesized from Portable_SQL_Trough:
--   1) !Blizzard_WowB_Engine_1_60_1 (C_AssistedCombat.GetNextCastSpell / GetActionSpell)
--   2) RotationPilot (ActionBars/Scanner, Engines/Interrupt, Data/Presets)
--   3) FojjiCore_SpellRanks (Multi-Rank SpellBook Indexer & Down-Rank Advisor)
--   4) Engine_NECElectricalCodec (NEC 210.20(A) 80% Continuous Mana Load Derating)
--
-- STEALTH COMPLIANCE:
--   * 0 Idle Timers: Combat ticker runs ONLY during active combat or hostile target
--     selection, and cancels itself immediately when idle.
--   * 0 Unsolicited Network Calls, 0 UI Taint.
--   * Slash Commands: /pilot, /fcp, /pilot toggle, /pilot aoe, /pilot button, /pilot macro
-- ============================================================================

local addonName, AltVault = ...
AltVault = AltVault or _G.AltVault or {}
_G.AltVault = AltVault

local FCP = {}
AltVault.ForeverCombatPilot = FCP
_G.ForeverCombatPilot = FCP

-- ----------------------------------------------------------------------------
-- 1. STATE & CONFIGURATION
-- ----------------------------------------------------------------------------
FCP.Enabled = true
FCP.AoEMode = false
FCP.ShowAlways = true
FCP.ActionGlowEnabled = true
FCP.ActiveTicker = nil
FCP.LastCastTime = {}
FCP.TargetCastMemory = {}
FCP.KnownSpellsByName = {}   -- [lowerName] = { name, maxID, minID, midID, maxRank, minRank, icon, ranks = { [r]=id } }
FCP.KnownSpellsByID = {}     -- [spellID] = { name, rank, icon }
FCP.KeybindBySpellID = {}    -- [spellID] = { slot, key, label, button }
FCP.KeybindBySpellName = {}  -- [lowerName] = { slot, key, label, button }
FCP.ScannerDirty = true
FCP.SpellbookDirty = true

-- 1.60.1 Secret-Value Guard (from RotationPilot SecretSafe)
local issecretvalue = _G.issecretvalue
local function IsSecret(v)
    return issecretvalue ~= nil and issecretvalue(v)
end
local function SafeVal(v, fallback)
    if IsSecret(v) or v == nil then return fallback end
    return v
end

-- ----------------------------------------------------------------------------
-- 2. FOREVER 1.60.1 CLASS PRIORITY & INTERRUPT PRESETS
--    (Ripped & Enhanced from RotationPilot\Data\Presets.lua)
-- ----------------------------------------------------------------------------
FCP.ClassPresets = {
    SHAMAN = {
        trees = { "Elemental", "Enhancement", "Restoration" },
        interrupts = { "Earth Shock" },
        stuns = { "War Stomp" },
        buffs = {
            shield = { "Lightning Shield", "Water Shield", "Earth Shield" },
            weapon = { "Flametongue Weapon", "Rockbiter Weapon", "Windfury Weapon", "Frostbrand Weapon" },
        },
        burst = { "Rage of the Farseer", "Rage of the Far Seer", "Elemental Mastery", "Nature's Swiftness", "Mana Tide Totem" },
        priority = {
            { names = { "Stormstrike" }, notSpec = 1 },
            { names = { "Flame Shock" }, debuff = "Flame Shock", every = 11 },
            { names = { "Lava Burst" }, notSpec = 2 },
            { names = { "Searing Totem" }, totemSlot = 1, every = 28 },
            { names = { "Fire Nova" }, aoe = true },
            { names = { "Chain Lightning" }, aoe = true },
            { names = { "Chain Lightning" }, spec = 1 },
            { names = { "Earth Shock" }, notSpec = 1 },
            { names = { "Lightning Bolt" } },
        },
    },
    WARRIOR = {
        trees = { "Arms", "Fury", "Protection" },
        interrupts = { "Pummel", "Shield Bash" },
        stuns = { "Concussion Blow", "Intimidating Shout" },
        buffs = {
            shield = { "Battle Shout" },
        },
        burst = { "Death Wish", "Recklessness", "Bloodrage", "Shield Wall" },
        priority = {
            { names = { "Execute" } },
            { names = { "Victory Rush" } },
            { names = { "Overpower" } },
            { names = { "Sweeping Strikes" }, aoe = true },
            { names = { "Thunder Clap" }, aoe = true },
            { names = { "Whirlwind" }, aoe = true },
            { names = { "Rend" }, debuff = "Rend", every = 18 },
            { names = { "Mortal Strike", "Bloodthirst", "Shield Slam" } },
            { names = { "Revenge" } },
            { names = { "Spearing Strike" } },
            { names = { "Whirlwind" } },
            { names = { "Sunder Armor" }, spec = 3 },
            { names = { "Heroic Strike" } },
        },
    },
    PALADIN = {
        trees = { "Holy", "Protection", "Retribution" },
        interrupts = {},
        stuns = { "Hammer of Justice", "Repentance" },
        buffs = {
            shield = { "Blessing of Might", "Blessing of Wisdom", "Blessing of Kings", "Blessing of Sanctuary" },
        },
        burst = { "Divine Favor", "Voice of Truth", "Avenging Wrath", "Divine Shield" },
        priority = {
            { names = { "Hammer of Wrath" } },
            { names = { "Holy Shield" }, spec = 2 },
            { names = { "Seal of Command", "Seal of Fury", "Seal of Righteousness" }, selfBuff = { "Seal of Command", "Seal of Fury", "Seal of Righteousness" }, every = 27 },
            { names = { "Consecration" }, aoe = true },
            { names = { "Hammer of the Righteous" }, aoe = true },
            { names = { "Holy Strike" } },
            { names = { "Judgement", "Judgment" } },
            { names = { "Swift Judgement" } },
            { names = { "Exorcism" } },
            { names = { "Holy Shock" } },
        },
    },
    HUNTER = {
        trees = { "Beast Mastery", "Marksmanship", "Survival" },
        interrupts = {},
        stuns = { "Scatter Shot", "Intimidation" },
        buffs = {
            shield = { "Aspect of the Hawk", "Aspect of the Monkey", "Aspect of the Viper", "Trueshot Aura" },
        },
        burst = { "Rapid Fire", "Bestial Wrath" },
        priority = {
            { names = { "Hunter's Mark" }, debuff = "Hunter's Mark", every = 90 },
            { names = { "Mongoose Bite" }, spec = 3 },
            { names = { "Counterattack" }, spec = 3 },
            { names = { "Strider Kick" }, spec = 3 },
            { names = { "Raptor Strike" }, spec = 3 },
            { names = { "Lacerate" }, debuff = "Lacerate", every = 18, spec = 3 },
            { names = { "Multi-Shot" }, aoe = true },
            { names = { "Volley" }, aoe = true },
            { names = { "Serpent Sting" }, debuff = "Serpent Sting", every = 13 },
            { names = { "Summon Hawk" }, every = 8 },
            { names = { "Sniper Shot", "Aimed Shot" } },
            { names = { "Arcane Shot" } },
        },
    },
    ROGUE = {
        trees = { "Assassination", "Combat", "Subtlety" },
        interrupts = { "Kick" },
        stuns = { "Gouge", "Kidney Shot", "Cheap Shot", "Blind" },
        buffs = {},
        burst = { "Adrenaline Rush", "Blade Flurry", "Cold Blood", "Sprint" },
        priority = {
            { names = { "Riposte" } },
            { names = { "Blade Flurry" }, aoe = true },
            { names = { "Slice and Dice" }, combo = 2, selfBuff = { "Slice and Dice" }, every = 14 },
            { names = { "Venom" }, combo = 3, every = 14 },
            { names = { "Eviscerate" }, combo = 4 },
            { names = { "Ghostly Strike" } },
            { names = { "Mutilate", "Hemorrhage", "Sinister Strike" } },
        },
    },
    MAGE = {
        trees = { "Arcane", "Fire", "Frost" },
        interrupts = { "Counterspell" },
        stuns = { "Frost Nova", "Polymorph" },
        buffs = {
            shield = { "Ice Armor", "Frost Armor", "Mage Armor", "Molten Armor", "Arcane Intellect" },
        },
        burst = { "Arcane Power", "Combustion", "Presence of Mind", "Icy Veins", "Evocation" },
        priority = {
            { names = { "Flamestrike", "Cone of Cold", "Blast Wave", "Arcane Explosion" }, aoe = true },
            { names = { "Fire Blast" } },
            { names = { "Ice Lance" }, spec = 3 },
            { names = { "Pyroblast" }, spec = 2 },
            { names = { "Arcane Blast", "Fireball", "Frostbolt" } },
        },
    },
    WARLOCK = {
        trees = { "Affliction", "Demonology", "Destruction" },
        interrupts = { "Spell Lock" },
        stuns = { "Death Coil", "Fear" },
        buffs = {
            shield = { "Demon Armor", "Demon Skin", "Fel Armor" },
        },
        burst = { "Amplify Curse", "Fel Domination", "Shadowburn" },
        priority = {
            { names = { "Rain of Fire", "Hellfire" }, aoe = true },
            { names = { "Shadowburn" } },
            { names = { "Immolate" }, debuff = "Immolate", every = 13 },
            { names = { "Conflagrate" } },
            { names = { "Bane of Agony", "Curse of Agony" }, debuff = "Agony", every = 22 },
            { names = { "Corruption" }, debuff = "Corruption", every = 16 },
            { names = { "Siphon Life" }, debuff = "Siphon Life", every = 28 },
            { names = { "Wrack", "Incinerate", "Shadow Bolt" } },
        },
    },
    PRIEST = {
        trees = { "Discipline", "Holy", "Shadow" },
        interrupts = { "Silence" },
        stuns = { "Psychic Scream", "Chastise" },
        buffs = {
            shield = { "Inner Fire", "Power Word: Fortitude", "Shadowform" },
        },
        burst = { "Power Infusion", "Inner Focus", "Shadowfiend" },
        priority = {
            { names = { "Holy Nova" }, aoe = true },
            { names = { "Shadow Word: Pain" }, debuff = "Shadow Word: Pain", every = 16 },
            { names = { "Mind Blast" } },
            { names = { "Penance", "Holy Fire" }, notSpec = 3 },
            { names = { "Devouring Plague" }, every = 22 },
            { names = { "Mind Flay", "Smite" } },
        },
    },
    DRUID = {
        trees = { "Balance", "Feral Combat", "Restoration" },
        interrupts = { "Feral Charge" },
        stuns = { "Bash", "Pounce" },
        buffs = {
            shield = { "Mark of the Wild", "Thorns", "Omen of Clarity" },
        },
        burst = { "Berserk", "Tiger's Fury", "Nature's Swiftness", "Innervate" },
        priority = {
            { names = { "Ferocious Bite", "Rip" }, combo = 5 },
            { names = { "Swipe", "Hurricane" }, aoe = true },
            { names = { "Faerie Fire (Feral)", "Faerie Fire" }, debuff = "Faerie Fire", every = 35 },
            { names = { "Rake" }, debuff = "Rake", every = 8 },
            { names = { "Primal Bite", "Mangle", "Claw", "Maul" } },
            { names = { "Moonfire" }, debuff = "Moonfire", every = 11 },
            { names = { "Insect Swarm" }, debuff = "Insect Swarm", every = 11 },
            { names = { "Starfire", "Wrath" } },
        },
    },
}

-- ----------------------------------------------------------------------------
-- 3. SPELLBOOK MULTI-RANK INDEXER (FojjiCore_SpellRanks Architecture)
-- ----------------------------------------------------------------------------
local function ParseRankNum(subName)
    if type(subName) ~= "string" then return nil end
    return tonumber(subName:match("(%d+)"))
end

function FCP:ScanSpellbook()
    wipe(self.KnownSpellsByName)
    wipe(self.KnownSpellsByID)

    local function RecordSpell(name, subName, iconID, spellID)
        if not name or name == "" then return end
        local lower = name:lower()
        local rank = ParseRankNum(subName) or 1
        if not iconID and spellID then
            if C_Spell and C_Spell.GetSpellTexture then
                iconID = C_Spell.GetSpellTexture(spellID)
            elseif GetSpellTexture then
                iconID = GetSpellTexture(spellID)
            end
        end
        iconID = iconID or 136243

        local entry = self.KnownSpellsByName[lower]
        if not entry then
            entry = {
                name = name,
                maxID = spellID,
                minID = spellID,
                midID = spellID,
                maxRank = rank,
                minRank = rank,
                icon = iconID,
                ranks = {},
            }
            self.KnownSpellsByName[lower] = entry
        end
        if spellID then
            entry.ranks[rank] = spellID
            self.KnownSpellsByID[spellID] = { name = name, rank = rank, icon = iconID }
        end
        if rank >= entry.maxRank then
            entry.maxRank = rank
            entry.maxID = spellID or entry.maxID
            entry.icon = iconID or entry.icon
        end
        if rank <= entry.minRank then
            entry.minRank = rank
            entry.minID = spellID or entry.minID
        end
        -- Compute economical mid-rank (~60% of max rank) for NEC Continuous Load down-ranking
        local midRank = math.max(1, math.floor(entry.maxRank * 0.6))
        entry.midID = entry.ranks[midRank] or entry.minID or entry.maxID
        entry.midRank = midRank
    end

    if C_SpellBook and C_SpellBook.GetNumSpellBookSkillLines and C_SpellBook.GetSpellBookItemInfo then
        local bank = (Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player) or 0
        local numLines = C_SpellBook.GetNumSpellBookSkillLines() or 0
        for t = 1, numLines do
            local line = C_SpellBook.GetSpellBookSkillLineInfo(t)
            if line and not line.offSpecID and not line.shouldHide then
                local first = (line.itemIndexOffset or 0) + 1
                local last = first + (line.numSpellBookItems or 0) - 1
                for i = first, last do
                    local item = C_SpellBook.GetSpellBookItemInfo(i, bank)
                    if item and item.name and not item.isPassive and not item.isOffSpec then
                        RecordSpell(item.name, item.subName, item.iconID, item.spellID or item.actionID)
                    end
                end
            end
        end
    elseif GetNumSpellTabs and GetSpellTabInfo and GetSpellBookItemName then
        local book = BOOKTYPE_SPELL or "spell"
        for t = 1, GetNumSpellTabs() do
            local _, _, offset, count = GetSpellTabInfo(t)
            for i = (offset or 0) + 1, (offset or 0) + (count or 0) do
                local name, sub = GetSpellBookItemName(i, book)
                local passive = IsPassiveSpell and IsPassiveSpell(i, book)
                if name and not passive then
                    local tex = GetSpellBookItemTexture and GetSpellBookItemTexture(i, book)
                    local _, id = GetSpellBookItemInfo(i, book)
                    RecordSpell(name, sub, tex, id)
                end
            end
        end
    end

    self.SpellbookDirty = false
end

-- ----------------------------------------------------------------------------
-- 4. ACTION BAR KEYBIND & BUTTON SCANNER (RotationPilot\ActionBars\Scanner)
-- ----------------------------------------------------------------------------
local MODIFIERS = { ALT = "a", CTRL = "c", SHIFT = "s", META = "m" }
local SHORT_KEYS = {
    MOUSEWHEELUP = "WU", MOUSEWHEELDOWN = "WD",
    SPACE = "Spc", ESCAPE = "Esc", BACKSPACE = "Bks", DELETE = "Del",
    TAB = "Tab", CAPSLOCK = "Cap", ENTER = "Ent",
    NUMPADPLUS = "N+", NUMPADMINUS = "N-", NUMPADMULTIPLY = "N*",
    NUMPADDIVIDE = "N/", NUMPADDECIMAL = "N.",
}

function FCP.FormatKeyLabel(key)
    if type(key) ~= "string" or key == "" then return nil end
    local prefix, base = "", key
    while true do
        local mod, rest = base:match("^(%u+)%-(.+)$")
        if mod and MODIFIERS[mod] then
            prefix = prefix .. MODIFIERS[mod]
            base = rest
        else
            break
        end
    end
    local short = SHORT_KEYS[base] or base:gsub("^NUMPAD", "N"):gsub("^BUTTON", "M")
    return prefix .. short
end

local BLIZZ_BAR_MAP = {
    { prefix = "ActionButton",           cmd = "ACTIONBUTTON",          startSlot = 1 },
    { prefix = "MultiBarBottomLeftButton", cmd = "MULTIACTIONBAR1BUTTON", startSlot = 61 },
    { prefix = "MultiBarBottomRightButton", cmd = "MULTIACTIONBAR2BUTTON", startSlot = 49 },
    { prefix = "MultiBarRightButton",    cmd = "MULTIACTIONBAR3BUTTON", startSlot = 25 },
    { prefix = "MultiBarLeftButton",     cmd = "MULTIACTIONBAR4BUTTON", startSlot = 37 },
}

function FCP:ScanActionBars()
    wipe(self.KeybindBySpellID)
    wipe(self.KeybindBySpellName)

    for _, bar in ipairs(BLIZZ_BAR_MAP) do
        for i = 1, 12 do
            local btn = _G[bar.prefix .. i]
            local slot = (btn and btn.action) or (btn and btn.GetAttribute and btn:GetAttribute("action")) or (bar.startSlot + i - 1)
            local cmd = bar.cmd .. i
            local rawKey = GetBindingKey and SafeVal(GetBindingKey(cmd), nil)
            local label = self.FormatKeyLabel(rawKey) or (bar.startSlot == 1 and tostring(i == 10 and 0 or (i == 11 and "-" or (i == 12 and "=" or i)))) or nil

            if slot and GetActionInfo then
                local aType, id, subType = GetActionInfo(slot)
                if not IsSecret(aType) and not IsSecret(id) and id then
                    if aType == "spell" or (aType == "macro" and subType == "spell") then
                        local info = { slot = slot, key = rawKey, label = label, button = btn }
                        if not self.KeybindBySpellID[id] or (label and not self.KeybindBySpellID[id].label) then
                            self.KeybindBySpellID[id] = info
                        end
                        local spName = (C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(id))
                            or (GetSpellInfo and GetSpellInfo(id))
                        if spName and not IsSecret(spName) then
                            local low = spName:lower()
                            if not self.KeybindBySpellName[low] or (label and not self.KeybindBySpellName[low].label) then
                                self.KeybindBySpellName[low] = info
                            end
                        end
                    end
                end
            end
        end
    end
    self.ScannerDirty = false
end

function FCP:GetBindingForSpell(spellID, spellName)
    if self.ScannerDirty then self:ScanActionBars() end
    if spellID and self.KeybindBySpellID[spellID] then
        return self.KeybindBySpellID[spellID]
    end
    if spellName and self.KeybindBySpellName[spellName:lower()] then
        return self.KeybindBySpellName[spellName:lower()]
    end
    -- Fallback to C_ActionBar.FindSpellActionButtons if available in 1.60.1
    if spellID and C_ActionBar and C_ActionBar.FindSpellActionButtons then
        local ok, slots = pcall(C_ActionBar.FindSpellActionButtons, spellID)
        if ok and type(slots) == "table" and not IsSecret(slots) and slots[1] then
            local slot = slots[1]
            if slot >= 1 and slot <= 12 then
                local k = GetBindingKey and SafeVal(GetBindingKey("ACTIONBUTTON" .. slot), nil)
                return { slot = slot, key = k, label = self.FormatKeyLabel(k) or tostring(slot), button = _G["ActionButton" .. slot] }
            end
        end
    end
    return nil
end

-- ----------------------------------------------------------------------------
-- 5. SPELL USABILITY, COOLDOWN & AURA HELPERS (1.60.1 + 3.3.5a Compatible)
-- ----------------------------------------------------------------------------
function FCP:IsSpellReady(spellID, spellName)
    local target = spellID or spellName
    if not target then return false end

    -- Cooldown check
    local start, duration = 0, 0
    if C_Spell and C_Spell.GetSpellCooldown then
        local cd = C_Spell.GetSpellCooldown(target)
        if cd and not IsSecret(cd) then
            start = SafeVal(cd.startTime, 0)
            duration = SafeVal(cd.duration, 0)
        end
    elseif GetSpellCooldown then
        local s, d = GetSpellCooldown(target)
        start = SafeVal(s, 0)
        duration = SafeVal(d, 0)
    end
    -- Ignore Global Cooldown (<= 1.5s) so next cast stays steady during GCD
    if duration and duration > 1.55 and (start + duration - GetTime()) > 0.15 then
        return false
    end

    -- Usable check (Mana / Rage / Energy / Reactive Proc)
    if C_Spell and C_Spell.IsSpellUsable then
        local usable, noMana = C_Spell.IsSpellUsable(target)
        if not IsSecret(usable) and usable == false and not SafeVal(noMana, false) then
            return false
        end
    elseif IsUsableSpell then
        local usable, noMana = IsUsableSpell(target)
        if not IsSecret(usable) and usable == false and not SafeVal(noMana, false) then
            return false
        end
    end
    return true
end

function FCP:HasUnitAura(unit, auraNames, filter)
    if not UnitExists(unit) then return false end
    local namesList = type(auraNames) == "table" and auraNames or { auraNames }
    for i = 1, 40 do
        local name
        if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
            local data = C_UnitAuras.GetAuraDataByIndex(unit, i, filter)
            if not data then break end
            name = SafeVal(data.name, nil)
        elseif UnitAura then
            name = SafeVal(UnitAura(unit, i, filter), nil)
            if not name then break end
        end
        if name then
            local low = name:lower()
            for _, targetName in ipairs(namesList) do
                if low == targetName:lower() or low:find(targetName:lower(), 1, true) then
                    return true, name
                end
            end
        end
    end
    return false
end

function FCP:GetActiveSpecIndex()
    if GetPrimaryTalentTree then
        local tree = GetPrimaryTalentTree()
        if tree and tree >= 1 and tree <= 3 then return tree end
    end
    if GetNumTalentTabs and GetTalentTabInfo then
        local bestTab, bestPts = 1, -1
        for i = 1, GetNumTalentTabs() do
            local _, _, pts = GetTalentTabInfo(i)
            pts = tonumber(pts) or 0
            if pts > bestPts then
                bestPts = pts
                bestTab = i
            end
        end
        return bestTab
    end
    return 1
end

-- ----------------------------------------------------------------------------
-- 6. CORE DECISION ENGINE:
--    Layer A: Rank-1 Interrupt Reflex (UnitCastingInfo / UnitChannelInfo)
--    Layer B: Native C++ C_AssistedCombat.GetNextCastSpell()
--    Layer C: Forever 1.60.1 Class Priority Engine + NEC Down-Rank Advisor
-- ----------------------------------------------------------------------------
function FCP:CheckTargetInterrupt()
    if not UnitExists("target") or UnitIsDeadOrGhost("target") or not UnitCanAttack("player", "target") then
        return nil
    end

    local isCasting, castName = false, nil
    if UnitCastingInfo then
        local name, _, _, _, _, isTradeskill, _, notInterruptible = UnitCastingInfo("target")
        if IsSecret(isTradeskill) or isTradeskill ~= nil or (name and not IsSecret(name)) then
            if not SafeVal(notInterruptible, false) then
                isCasting = true
                castName = SafeVal(name, "Enemy Cast")
            end
        end
    end
    if not isCasting and UnitChannelInfo then
        local name, _, _, _, _, isTradeskill, notInterruptible = UnitChannelInfo("target")
        if IsSecret(isTradeskill) or isTradeskill ~= nil or (name and not IsSecret(name)) then
            if not SafeVal(notInterruptible, false) then
                isCasting = true
                castName = SafeVal(name, "Enemy Channel")
            end
        end
    end

    if not isCasting then return nil end

    local _, class = UnitClass("player")
    local preset = self.ClassPresets[class or "SHAMAN"]
    if not preset then return nil end

    -- Try true interrupts first (prefer Rank 1 for Earth Shock to save mana!)
    for _, spName in ipairs(preset.interrupts or {}) do
        local entry = self.KnownSpellsByName[spName:lower()]
        if entry and self:IsSpellReady(entry.minID or entry.maxID, entry.name) then
            local useRank1 = (spName == "Earth Shock")
            local id = useRank1 and (entry.minID or entry.maxID) or entry.maxID
            local rankTag = useRank1 and "Rank 1 (Kick)" or ("Rank " .. (entry.maxRank or 1))
            return {
                spellID = id,
                name = entry.name,
                rankTag = rankTag,
                icon = entry.icon,
                reason = "INTERRUPT: " .. tostring(castName),
                isInterrupt = true,
            }
        end
    end

    -- Fallback to stuns
    for _, spName in ipairs(preset.stuns or {}) do
        local entry = self.KnownSpellsByName[spName:lower()]
        if entry and self:IsSpellReady(entry.maxID, entry.name) then
            return {
                spellID = entry.maxID,
                name = entry.name,
                rankTag = "STUN CAST",
                icon = entry.icon,
                reason = "STOP CAST: " .. tostring(castName),
                isInterrupt = true,
            }
        end
    end

    return nil
end

function FCP:GetManaAndTargetMetrics()
    local manaPct = 100
    local pType = UnitPowerType and SafeVal(UnitPowerType("player"), 0) or 0
    if pType == 0 then
        local cur = SafeVal(UnitPower("player", 0), 0)
        local max = SafeVal(UnitPowerMax("player", 0), 1)
        if max > 0 then manaPct = math.floor((cur / max) * 100) end
    end

    local targetHpPct = 100
    if UnitExists("target") and not UnitIsDeadOrGhost("target") then
        local thp = SafeVal(UnitHealth("target"), 0)
        local tmax = SafeVal(UnitHealthMax("target"), 1)
        if tmax > 0 then targetHpPct = math.floor((thp / tmax) * 100) end
    end

    return manaPct, targetHpPct
end

function FCP:EvaluateRecommendation()
    if self.SpellbookDirty then self:ScanSpellbook() end
    if self.ScannerDirty then self:ScanActionBars() end

    local manaPct, targetHpPct = self:GetManaAndTargetMetrics()

    -- 1. Urgent Interrupt Check
    local interruptRec = self:CheckTargetInterrupt()

    -- 2. Native C++ C_AssistedCombat Check (1.60.1.70450 Engine)
    local cppSpellID = nil
    if C_AssistedCombat and C_AssistedCombat.GetNextCastSpell then
        local ok, sid = pcall(C_AssistedCombat.GetNextCastSpell, false)
        if ok and type(sid) == "number" and not IsSecret(sid) and sid > 0 then
            cppSpellID = sid
        end
    end

    if cppSpellID then
        local spName = (C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(cppSpellID))
            or (GetSpellInfo and GetSpellInfo(cppSpellID))
        local spIcon = (C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(cppSpellID))
            or (GetSpellTexture and GetSpellTexture(cppSpellID)) or 136243
        local entry = spName and self.KnownSpellsByName[spName:lower()]
        local chosenID = cppSpellID
        local rankLabel = entry and ("Rank " .. tostring(entry.maxRank or 1)) or "C++ Engine"
        local reason = "C_AssistedCombat Native C++"

        -- Apply NEC 210.20(A) Down-Rank intelligence when Mana < 25% or Target HP < 18%
        if entry and entry.maxRank > 1 then
            if targetHpPct <= 18 and UnitExists("target") then
                chosenID = entry.minID or chosenID
                rankLabel = "Rank " .. tostring(entry.minRank or 1) .. " (Finisher)"
                reason = "Overkill Prevention (<18% HP)"
            elseif manaPct <= 25 then
                chosenID = entry.midID or chosenID
                rankLabel = "Rank " .. tostring(entry.midRank or 1) .. " (80% NEC Load)"
                reason = "NEC 210.20(A) Mana Derating (<25%)"
            end
        end

        return {
            spellID = chosenID,
            name = spName or ("Spell #" .. cppSpellID),
            rankTag = rankLabel,
            icon = spIcon,
            reason = reason,
            cppActive = true,
            interrupt = interruptRec,
            manaPct = manaPct,
            targetHpPct = targetHpPct,
        }
    end

    -- 3. Forever 1.60.1 Class Priority Engine
    local _, class = UnitClass("player")
    local preset = self.ClassPresets[class or "SHAMAN"] or self.ClassPresets.SHAMAN
    local spec = self:GetActiveSpecIndex()
    local now = GetTime()
    local combo = (GetComboPoints and SafeVal(GetComboPoints("player", "target"), 0)) or 0

    for _, rule in ipairs(preset.priority or {}) do
        local pass = true
        if rule.aoe and not self.AoEMode then pass = false end
        if rule.spec and rule.spec ~= spec then pass = false end
        if rule.notSpec and rule.notSpec == spec then pass = false end
        if rule.combo and combo < rule.combo then pass = false end

        if pass and rule.totemSlot and GetTotemInfo then
            local haveTotem, totemName, startTime, duration = GetTotemInfo(rule.totemSlot)
            if SafeVal(haveTotem, false) and (SafeVal(startTime, 0) + SafeVal(duration, 0) - now) > 2 then
                pass = false
            end
        end

        if pass and rule.debuff and UnitExists("target") then
            if self:HasUnitAura("target", rule.debuff, "HARMFUL|PLAYER") then
                pass = false
            end
        end

        if pass and rule.selfBuff then
            if self:HasUnitAura("player", rule.selfBuff, "HELPFUL") then
                pass = false
            end
        end

        if pass then
            for _, candName in ipairs(rule.names or {}) do
                local entry = self.KnownSpellsByName[candName:lower()]
                if entry then
                    local lastCast = self.LastCastTime[entry.name:lower()] or 0
                    if not rule.every or (now - lastCast) >= rule.every then
                        if self:IsSpellReady(entry.maxID, entry.name) then
                            local chosenID = entry.maxID
                            local rankLabel = "Rank " .. tostring(entry.maxRank or 1)
                            local reason = (preset.trees and preset.trees[spec] or class) .. " Priority"

                            if entry.maxRank > 1 then
                                if targetHpPct <= 18 and UnitExists("target") and not UnitIsDeadOrGhost("target") then
                                    chosenID = entry.minID or chosenID
                                    rankLabel = "Rank " .. tostring(entry.minRank or 1) .. " (Finisher)"
                                    reason = "Overkill Prevention (<18% HP)"
                                elseif manaPct <= 25 then
                                    chosenID = entry.midID or chosenID
                                    rankLabel = "Rank " .. tostring(entry.midRank or 1) .. " (80% NEC Load)"
                                    reason = "NEC 210.20(A) Mana Derating"
                                end
                            end

                            return {
                                spellID = chosenID,
                                name = entry.name,
                                rankTag = rankLabel,
                                icon = entry.icon,
                                reason = reason,
                                cppActive = false,
                                interrupt = interruptRec,
                                manaPct = manaPct,
                                targetHpPct = targetHpPct,
                            }
                        end
                    end
                end
            end
        end
    end

    return {
        spellID = nil,
        name = "Ready",
        rankTag = "Standby",
        icon = 136048, -- Lightning Bolt icon
        reason = "Awaiting Combat Target",
        cppActive = (C_AssistedCombat ~= nil),
        interrupt = interruptRec,
        manaPct = manaPct,
        targetHpPct = targetHpPct,
    }
end

-- ----------------------------------------------------------------------------
-- 7. MISSING BUFF, WEAPON IMBUE & TOTEM WATCHER
-- ----------------------------------------------------------------------------
function FCP:GetWatchBadges()
    local badges = {}
    local _, class = UnitClass("player")
    local preset = self.ClassPresets[class or "SHAMAN"] or self.ClassPresets.SHAMAN

    -- Badge 1: Self Shield / Armor Buff
    if preset.buffs and preset.buffs.shield then
        local hasBuff, activeName = self:HasUnitAura("player", preset.buffs.shield, "HELPFUL")
        local suggestEntry = nil
        for _, bName in ipairs(preset.buffs.shield) do
            if self.KnownSpellsByName[bName:lower()] then
                suggestEntry = self.KnownSpellsByName[bName:lower()]
                break
            end
        end
        if suggestEntry then
            local kb = self:GetBindingForSpell(suggestEntry.maxID, suggestEntry.name)
            badges[#badges + 1] = {
                label = hasBuff and "SHIELD OK" or "MISSING!",
                name = activeName or suggestEntry.name,
                icon = suggestEntry.icon,
                key = kb and kb.label or "",
                ok = hasBuff,
            }
        end
    end

    -- Badge 2: Weapon Imbue (Shaman) or Burst Cooldown
    if preset.buffs and preset.buffs.weapon and GetWeaponEnchantInfo then
        local hasMainHandEnchant = SafeVal(GetWeaponEnchantInfo(), false)
        local imbueEntry = nil
        for _, wName in ipairs(preset.buffs.weapon) do
            if self.KnownSpellsByName[wName:lower()] then
                imbueEntry = self.KnownSpellsByName[wName:lower()]
                break
            end
        end
        if imbueEntry then
            local kb = self:GetBindingForSpell(imbueEntry.maxID, imbueEntry.name)
            badges[#badges + 1] = {
                label = hasMainHandEnchant and "IMBUE OK" or "IMBUE!",
                name = imbueEntry.name,
                icon = imbueEntry.icon,
                key = kb and kb.label or "",
                ok = hasMainHandEnchant and true or false,
            }
        end
    end

    -- Badge 3: Fire Totem (Shaman) or Class Burst CD
    if class == "SHAMAN" and GetTotemInfo then
        local haveFire, totemName, startTime, duration = GetTotemInfo(1)
        local rem = (SafeVal(haveFire, false) and duration and duration > 0) and math.max(0, math.floor(startTime + duration - GetTime())) or 0
        local searEntry = self.KnownSpellsByName["searing totem"]
        badges[#badges + 1] = {
            label = rem > 0 and ("TOTEM " .. rem .. "s") or "NO TOTEM",
            name = (rem > 0 and SafeVal(totemName, "Fire Totem")) or (searEntry and searEntry.name or "Fire Totem"),
            icon = (searEntry and searEntry.icon) or 135825,
            key = (searEntry and self:GetBindingForSpell(searEntry.maxID, searEntry.name) and self:GetBindingForSpell(searEntry.maxID, searEntry.name).label) or "",
            ok = rem > 0,
        }
    else
        for _, cdName in ipairs(preset.burst or {}) do
            local entry = self.KnownSpellsByName[cdName:lower()]
            if entry then
                local ready = self:IsSpellReady(entry.maxID, entry.name)
                local kb = self:GetBindingForSpell(entry.maxID, entry.name)
                badges[#badges + 1] = {
                    label = ready and "BURST RDY" or "ON CD",
                    name = entry.name,
                    icon = entry.icon,
                    key = kb and kb.label or "",
                    ok = ready,
                }
                break
            end
        end
    end

    return badges
end

-- ----------------------------------------------------------------------------
-- 8. ONE-CLICK NATIVE C++ SINGLE-BUTTON ASSISTANT & MACRO BUILDER
-- ----------------------------------------------------------------------------
function FCP:PickupNativeSingleButtonAssistant()
    if C_AssistedCombat and C_AssistedCombat.GetActionSpell then
        local ok, actionSpellID = pcall(C_AssistedCombat.GetActionSpell)
        if ok and type(actionSpellID) == "number" and actionSpellID > 0 then
            if C_Spell and C_Spell.PickupSpell then
                C_Spell.PickupSpell(actionSpellID)
                print("|cff00ffcc[ForeverCombatPilot]|r Picked up Native C++ Single-Button Assistant (SpellID |cffffd100" .. actionSpellID .. "|r)! Drop it onto any Action Bar slot!")
                return true
            elseif PickupSpell then
                PickupSpell(actionSpellID)
                print("|cff00ffcc[ForeverCombatPilot]|r Picked up Native C++ Single-Button Assistant (SpellID |cffffd100" .. actionSpellID .. "|r)! Drop it onto any Action Bar slot!")
                return true
            end
        end
    end
    -- Fallback: create/pickup the dynamic ForeverPilot macro!
    return self:UpdateAndPickupPilotMacro(true)
end

function FCP:UpdateAndPickupPilotMacro(pickupToCursor)
    if InCombatLockdown() then
        print("|cffff6600[ForeverCombatPilot]|r Cannot modify macro during combat lockdown. Try right after combat!")
        return false
    end
    local rec = self:EvaluateRecommendation()
    local spellName = (rec and rec.spellID and rec.name) or "Lightning Bolt"
    local body = "#showtooltip\n/startattack\n/cast " .. spellName

    if GetMacroIndexByName and CreateMacro and EditMacro then
        local idx = GetMacroIndexByName("ForeverPilot")
        if idx and idx > 0 then
            EditMacro(idx, "ForeverPilot", "INV_Misc_QuestionMark", body)
        else
            local numGlobal = GetNumMacros()
            if (numGlobal or 0) < 120 then
                idx = CreateMacro("ForeverPilot", "INV_Misc_QuestionMark", body, nil)
            end
        end
        if pickupToCursor and idx and idx > 0 and PickupMacro then
            PickupMacro(idx)
            print("|cff00ffcc[ForeverCombatPilot]|r Picked up |cffffd100ForeverPilot|r 1-Button Macro (" .. spellName .. ") to cursor! Drop it onto your Action Bar!")
        end
        return true
    end
    return false
end

-- ----------------------------------------------------------------------------
-- 9. HUD FRAME & ACTION-BAR BUTTON GLOW OVERLAY
-- ----------------------------------------------------------------------------
function FCP:SetActionBarGlow(targetButton)
    if not self.GlowFrame then
        local gf = CreateFrame("Frame", "ForeverCombatPilotActionGlow", UIParent, "BackdropTemplate")
        gf:SetFrameStrata("HIGH")
        gf:SetBackdrop({
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 14,
        })
        gf:SetBackdropBorderColor(0.0, 1.0, 0.85, 1.0)

        local tex = gf:CreateTexture(nil, "OVERLAY")
        tex:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
        tex:SetBlendMode("ADD")
        tex:SetAllPoints(gf)
        tex:SetVertexColor(0.0, 1.0, 0.8, 0.75)
        gf.tex = tex

        local kbBadge = gf:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        kbBadge:SetPoint("TOP", gf, "TOP", 0, 12)
        kbBadge:SetTextColor(1.0, 0.9, 0.1, 1.0)
        gf.kbBadge = kbBadge

        self.GlowFrame = gf
    end

    if not self.ActionGlowEnabled or not targetButton or not targetButton:IsVisible() then
        self.GlowFrame:Hide()
        return
    end

    self.GlowFrame:ClearAllPoints()
    self.GlowFrame:SetPoint("TOPLEFT", targetButton, "TOPLEFT", -4, 4)
    self.GlowFrame:SetPoint("BOTTOMRIGHT", targetButton, "BOTTOMRIGHT", 4, -4)
    self.GlowFrame:Show()
end

function FCP:CreateHUD()
    if self.HUD then return self.HUD end

    local f = CreateFrame("Frame", "ForeverCombatPilotHUD", UIParent, "BackdropTemplate")
    f:SetSize(250, 138)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, -165)
    f:SetFrameStrata("MEDIUM")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 14,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    f:SetBackdropColor(0.04, 0.07, 0.12, 0.92)
    f:SetBackdropBorderColor(0.0, 0.82, 1.0, 0.90)

    -- Header Bar
    local hdr = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hdr:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -7)
    hdr:SetText("|cff00e5ff⚡ FOREVER COMBAT PILOT|r |cff88aaccv1.60.1|r")
    f.hdr = hdr

    -- Close Button
    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetSize(20, 20)
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -2, -2)
    closeBtn:SetScript("OnClick", function()
        FCP.Enabled = false
        f:Hide()
        FCP:SetActionBarGlow(nil)
        print("|cff00ffcc[ForeverCombatPilot]|r HUD hidden. Type |cffffd100/pilot|r to re-open.")
    end)

    -- Interrupt Flash Banner (Top Emergency Strip)
    local intBanner = CreateFrame("Frame", nil, f, "BackdropTemplate")
    intBanner:SetSize(234, 24)
    intBanner:SetPoint("BOTTOM", f, "TOP", 0, 2)
    intBanner:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    intBanner:SetBackdropColor(0.75, 0.08, 0.08, 0.95)
    intBanner:SetBackdropBorderColor(1.0, 0.85, 0.0, 1.0)
    intBanner.txt = intBanner:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    intBanner.txt:SetPoint("CENTER", intBanner, "CENTER", 0, 0)
    intBanner.txt:SetText("|cffffcc00⚡ INTERRUPT NOW: [1] Earth Shock (R1)|r")
    intBanner:Hide()
    f.intBanner = intBanner

    -- Main Next-Cast Spell Icon
    local iconFrame = CreateFrame("Frame", nil, f, "BackdropTemplate")
    iconFrame:SetSize(54, 54)
    iconFrame:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -24)
    iconFrame:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12,
    })
    iconFrame:SetBackdropBorderColor(1.0, 0.82, 0.0, 1.0)

    local iconTex = iconFrame:CreateTexture(nil, "ARTWORK")
    iconTex:SetPoint("TOPLEFT", iconFrame, "TOPLEFT", 3, -3)
    iconTex:SetPoint("BOTTOMRIGHT", iconFrame, "BOTTOMRIGHT", -3, 3)
    iconTex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    iconTex:SetTexture(136048)
    f.iconTex = iconTex

    -- Giant Keybind Overlay on Main Icon
    local keyText = iconFrame:CreateFontString(nil, "OVERLAY", "NumberFontNormalLarge")
    keyText:SetPoint("TOPRIGHT", iconFrame, "TOPRIGHT", -3, -3)
    keyText:SetTextColor(1.0, 0.95, 0.1, 1.0)
    keyText:SetText("1")
    f.keyText = keyText

    -- Spell Name, Rank & NEC Load Telemetry
    local spellTitle = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    spellTitle:SetPoint("TOPLEFT", iconFrame, "TOPRIGHT", 10, -2)
    spellTitle:SetWidth(164)
    spellTitle:SetJustifyH("LEFT")
    spellTitle:SetText("|cffffffffLightning Bolt|r")
    f.spellTitle = spellTitle

    local rankText = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    rankText:SetPoint("TOPLEFT", spellTitle, "BOTTOMLEFT", 0, -3)
    rankText:SetWidth(164)
    rankText:SetJustifyH("LEFT")
    rankText:SetText("|cff00ffccRank 1 | C++ Engine|r")
    f.rankText = rankText

    local reasonText = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    reasonText:SetPoint("TOPLEFT", rankText, "BOTTOMLEFT", 0, -3)
    reasonText:SetWidth(164)
    reasonText:SetJustifyH("LEFT")
    reasonText:SetText("|cffaaaaaaNEC 210.20(A) Load: OK|r")
    f.reasonText = reasonText

    -- 3 Watch Badges (Shield, Weapon Imbue, Totem/Burst)
    f.badges = {}
    for i = 1, 3 do
        local b = CreateFrame("Frame", nil, f, "BackdropTemplate")
        b:SetSize(74, 26)
        b:SetPoint("TOPLEFT", f, "TOPLEFT", 10 + (i - 1) * 78, -82)
        b:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 8,
            insets = { left = 1, right = 1, top = 1, bottom = 1 },
        })
        b:SetBackdropColor(0.08, 0.14, 0.20, 0.9)
        b:SetBackdropBorderColor(0.2, 0.6, 0.8, 0.8)

        b.ico = b:CreateTexture(nil, "ARTWORK")
        b.ico:SetSize(18, 18)
        b.ico:SetPoint("LEFT", b, "LEFT", 4, 0)
        b.ico:SetTexCoord(0.08, 0.92, 0.08, 0.92)

        b.txt = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        b.txt:SetPoint("LEFT", b.ico, "RIGHT", 4, 0)
        b.txt:SetWidth(46)
        b.txt:SetJustifyH("LEFT")
        f.badges[i] = b
    end

    -- Bottom Control Buttons: [AoE Mode] and [🎯 Grab 1-Btn C++ Assist]
    local aoeBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    aoeBtn:SetSize(92, 20)
    aoeBtn:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 10, 6)
    aoeBtn:SetText("AoE: OFF")
    aoeBtn:SetScript("OnClick", function()
        FCP.AoEMode = not FCP.AoEMode
        aoeBtn:SetText(FCP.AoEMode and "|cffff8800AoE: ON|r" or "AoE: OFF")
        FCP:RefreshHUD()
    end)
    f.aoeBtn = aoeBtn

    local grabBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    grabBtn:SetSize(134, 20)
    grabBtn:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -10, 6)
    grabBtn:SetText("Grab 1-Btn Assistant")
    grabBtn:SetScript("OnClick", function()
        FCP:PickupNativeSingleButtonAssistant()
    end)
    f.grabBtn = grabBtn

    self.HUD = f
    return f
end

-- ----------------------------------------------------------------------------
-- 10. REAL-TIME REFRESH & STEALTH 1-TIMER SCHEDULER
-- ----------------------------------------------------------------------------
function FCP:RefreshHUD()
    if not self.Enabled then
        if self.HUD then self.HUD:Hide() end
        self:SetActionBarGlow(nil)
        return
    end

    local f = self:CreateHUD()
    f:Show()

    local rec = self:EvaluateRecommendation()
    local kb = self:GetBindingForSpell(rec.spellID, rec.name)
    local keyLabel = (kb and kb.label) or ""

    f.iconTex:SetTexture(rec.icon or 136048)
    f.keyText:SetText(keyLabel ~= "" and ("[" .. keyLabel .. "]") or "")
    f.spellTitle:SetText("|cffffffff" .. tostring(rec.name or "Ready") .. "|r")
    f.rankText:SetText("|cff00ffcc" .. tostring(rec.rankTag or "") .. "|r" .. (keyLabel ~= "" and ("  |cffffd100Key: " .. keyLabel .. "|r") or ""))

    local loadStatus = rec.manaPct <= 25 and ("|cffff5555Mana " .. rec.manaPct .. "% (Derate!)|r")
        or ("|cff88ff88Mana " .. rec.manaPct .. "%|r | " .. tostring(rec.reason or ""))
    f.reasonText:SetText(loadStatus)

    -- Interrupt Alert Banner
    if rec.interrupt then
        local ikb = self:GetBindingForSpell(rec.interrupt.spellID, rec.interrupt.name)
        local ikey = (ikb and ikb.label and ("[" .. ikb.label .. "] ")) or ""
        f.intBanner.txt:SetText("|cffffe000⚡ KICK: " .. ikey .. rec.interrupt.name .. " (" .. rec.interrupt.rankTag .. ")|r")
        f.intBanner:Show()
        if ikb and ikb.button then
            self:SetActionBarGlow(ikb.button)
        end
    else
        f.intBanner:Hide()
        if kb and kb.button and (InCombatLockdown() or (UnitExists("target") and UnitCanAttack("player", "target"))) then
            self:SetActionBarGlow(kb.button)
        else
            self:SetActionBarGlow(nil)
        end
    end

    -- Update Watch Badges
    local badges = self:GetWatchBadges()
    for i = 1, 3 do
        local b = f.badges[i]
        local data = badges[i]
        if data then
            b:Show()
            b.ico:SetTexture(data.icon or 136243)
            local kTag = (data.key and data.key ~= "") and ("[" .. data.key .. "] ") or ""
            b.txt:SetText((data.ok and "|cff55ff55" or "|cffff5555") .. kTag .. data.label .. "|r")
            if data.ok then
                b:SetBackdropBorderColor(0.15, 0.75, 0.35, 0.85)
            else
                b:SetBackdropBorderColor(1.0, 0.25, 0.25, 0.95)
            end
        else
            b:Hide()
        end
    end

    -- Out of combat: keep ForeverPilot macro synced to current recommendation
    if not InCombatLockdown() and rec.spellID and self.LastSyncedMacroSpell ~= rec.name then
        self.LastSyncedMacroSpell = rec.name
        if GetMacroIndexByName and GetMacroIndexByName("ForeverPilot") > 0 then
            self:UpdateAndPickupPilotMacro(false)
        end
    end
end

function FCP:EnsureCombatTickerState()
    local shouldTick = self.Enabled and (
        InCombatLockdown() or
        (UnitExists("target") and not UnitIsDeadOrGhost("target") and UnitCanAttack("player", "target"))
    )

    if shouldTick and not self.ActiveTicker then
        if C_Timer and C_Timer.NewTicker then
            self.ActiveTicker = C_Timer.NewTicker(0.15, function()
                if not FCP.Enabled or (not InCombatLockdown() and not (UnitExists("target") and UnitCanAttack("player", "target"))) then
                    if FCP.ActiveTicker then
                        FCP.ActiveTicker:Cancel()
                        FCP.ActiveTicker = nil
                    end
                    FCP:RefreshHUD()
                    return
                end
                FCP:RefreshHUD()
            end)
        end
    elseif not shouldTick and self.ActiveTicker then
        self.ActiveTicker:Cancel()
        self.ActiveTicker = nil
    end
end

-- ----------------------------------------------------------------------------
-- 11. MINIMAP BUTTON (ForeverCombatPilotMiniButton)
-- ----------------------------------------------------------------------------
function FCP:CreateMinimapButton()
    if self.MinimapButton or not Minimap then return self.MinimapButton end

    ForeverCombatPilotDB = ForeverCombatPilotDB or {}
    local mb = CreateFrame("Button", "ForeverCombatPilotMiniButton", Minimap)
    mb:SetSize(31, 31)
    mb:SetFrameStrata("MEDIUM")
    mb:SetFrameLevel(10)
    mb:SetToplevel(true)
    mb:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    mb:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    mb:RegisterForDrag("LeftButton")

    mb.Icon = mb:CreateTexture(nil, "BACKGROUND")
    mb.Icon:SetTexture("Interface\\Icons\\Spell_Nature_Lightning")
    mb.Icon:SetSize(20, 20)
    mb.Icon:SetPoint("TOPLEFT", mb, "TOPLEFT", 7, -6)

    mb.Border = mb:CreateTexture(nil, "OVERLAY")
    mb.Border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    mb.Border:SetSize(53, 53)
    mb.Border:SetPoint("TOPLEFT", mb, "TOPLEFT", 0, 0)

    local function UpdateMinimapPos()
        local angle = (ForeverCombatPilotDB and ForeverCombatPilotDB.MinimapAngle) or 205
        local rads = math.rad(angle)
        local radius = ((Minimap:GetWidth() or 140) / 2) + 5
        local x = radius * math.cos(rads)
        local y = radius * math.sin(rads)
        mb:ClearAllPoints()
        mb:SetPoint("CENTER", Minimap, "CENTER", x, y)
    end

    local atan2 = math.atan2 or function(y, x)
        if x > 0 then return math.atan(y / x)
        elseif x < 0 and y >= 0 then return math.atan(y / x) + math.pi
        elseif x < 0 and y < 0 then return math.atan(y / x) - math.pi
        elseif x == 0 and y > 0 then return math.pi / 2
        elseif x == 0 and y < 0 then return -math.pi / 2
        else return 0 end
    end

    mb:SetScript("OnDragStart", function(self)
        self:LockHighlight()
        self:SetScript("OnUpdate", function()
            local mx, my = GetCursorPosition()
            local scale = Minimap:GetEffectiveScale()
            local x, y = mx / scale, my / scale
            local cx, cy = Minimap:GetCenter()
            local angle = math.deg(atan2(y - cy, x - cx))
            if angle < 0 then angle = angle + 360 end
            ForeverCombatPilotDB = ForeverCombatPilotDB or {}
            ForeverCombatPilotDB.MinimapAngle = angle
            UpdateMinimapPos()
        end)
    end)

    mb:SetScript("OnDragStop", function(self)
        self:UnlockHighlight()
        self:SetScript("OnUpdate", nil)
    end)

    mb:SetScript("OnClick", function(_, button)
        if button == "RightButton" then
            FCP:PickupNativeSingleButtonAssistant()
        elseif IsShiftKeyDown() then
            FCP.AoEMode = not FCP.AoEMode
            if FCP.HUD and FCP.HUD.aoeBtn then
                FCP.HUD.aoeBtn:SetText(FCP.AoEMode and "|cffff8800AoE: ON|r" or "AoE: OFF")
            end
            FCP:RefreshHUD()
            print("|cff00ffcc[ForeverCombatPilot]|r AoE Mode: " .. (FCP.AoEMode and "|cff00ff00ON|r" or "|cffff5555OFF|r"))
        else
            FCP.Enabled = not FCP.Enabled
            FCP:EnsureCombatTickerState()
            FCP:RefreshHUD()
            print("|cff00ffcc[ForeverCombatPilot]|r HUD: " .. (FCP.Enabled and "|cff00ff00SHOWN|r" or "|cffff5555HIDDEN|r"))
        end
    end)

    mb:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:ClearLines()
        GameTooltip:AddLine("⚡ Forever Combat Pilot (1.60.1)", 0, 0.9, 1)
        GameTooltip:AddLine("|cff00ff00Left-Click:|r Toggle Combat Pilot HUD (" .. (FCP.Enabled and "|cff55ff55ON|r" or "|cffff5555OFF|r") .. ")", 1, 1, 1)
        GameTooltip:AddLine("|cff00ff00Right-Click:|r Grab 1-Button C++ Assistant / Macro", 1, 1, 1)
        GameTooltip:AddLine("|cff00ff00Shift-Click:|r Toggle AoE Mode (" .. (FCP.AoEMode and "|cffff8800ON|r" or "|cffaaaaaaOFF|r") .. ")", 1, 1, 1)
        GameTooltip:AddLine("|cff00ff00Left-Drag:|r Orbit Minimap Button", 1, 1, 1)
        GameTooltip:Show()
    end)

    mb:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    UpdateMinimapPos()
    self.MinimapButton = mb
    return mb
end

-- ----------------------------------------------------------------------------
-- 12. EVENT FRAME & SLASH COMMANDS (/pilot, /fcp)
-- ----------------------------------------------------------------------------
local evFrame = CreateFrame("Frame")
evFrame:RegisterEvent("PLAYER_LOGIN")
evFrame:RegisterEvent("SPELLS_CHANGED")
evFrame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
evFrame:RegisterEvent("UPDATE_BINDINGS")
evFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
evFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
evFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
evFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
evFrame:RegisterEvent("UNIT_SPELLCAST_START")
evFrame:RegisterEvent("UNIT_SPELLCAST_STOP")
evFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
evFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
evFrame:RegisterEvent("UNIT_AURA")
evFrame:RegisterEvent("PLAYER_TOTEM_UPDATE")

evFrame:SetScript("OnEvent", function(_, event, unit, _, spellID)
    if event == "PLAYER_LOGIN" then
        FCP.SpellbookDirty = true
        FCP.ScannerDirty = true
        FCP:CreateMinimapButton()
        FCP:RefreshHUD()
        print("|cff00e5ff[ForeverCombatPilot v1.60.1]|r Loaded! Click the |cffffd100⚡ Lightning Minimap Button|r (or type |cffffd100/pilot|r) to toggle HUD, or Right-Click it to grab the 1-Button Assistant!")
    elseif event == "SPELLS_CHANGED" then
        FCP.SpellbookDirty = true
        FCP.ScannerDirty = true
        FCP:RefreshHUD()
    elseif event == "ACTIONBAR_SLOT_CHANGED" or event == "UPDATE_BINDINGS" then
        FCP.ScannerDirty = true
        FCP:RefreshHUD()
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" and unit == "player" then
        local spName = spellID and ((C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(spellID)) or (GetSpellInfo and GetSpellInfo(spellID)))
        if spName and not IsSecret(spName) then
            FCP.LastCastTime[spName:lower()] = GetTime()
        end
        FCP:RefreshHUD()
    elseif event == "PLAYER_TARGET_CHANGED" or event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_REGEN_ENABLED" then
        FCP:EnsureCombatTickerState()
        FCP:RefreshHUD()
    elseif (event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_CHANNEL_START" or event == "UNIT_SPELLCAST_CHANNEL_STOP") and unit == "target" then
        FCP:RefreshHUD()
    elseif (event == "UNIT_AURA" and (unit == "player" or unit == "target")) or event == "PLAYER_TOTEM_UPDATE" then
        FCP:RefreshHUD()
    end
end)

SLASH_FOREVERCOMBATPILOT1 = "/pilot"
SLASH_FOREVERCOMBATPILOT2 = "/fcp"
SlashCmdList["FOREVERCOMBATPILOT"] = function(msg)
    local cmd = (msg or ""):lower():match("^%s*(.-)%s*$")
    if cmd == "aoe" then
        FCP.AoEMode = not FCP.AoEMode
        if FCP.HUD and FCP.HUD.aoeBtn then
            FCP.HUD.aoeBtn:SetText(FCP.AoEMode and "|cffff8800AoE: ON|r" or "AoE: OFF")
        end
        FCP:RefreshHUD()
        print("|cff00ffcc[ForeverCombatPilot]|r AoE Mode: " .. (FCP.AoEMode and "|cff00ff00ON|r" or "|cffff5555OFF|r"))
    elseif cmd == "button" or cmd == "assist" then
        FCP:PickupNativeSingleButtonAssistant()
    elseif cmd == "macro" then
        FCP:UpdateAndPickupPilotMacro(true)
    elseif cmd == "glow" then
        FCP.ActionGlowEnabled = not FCP.ActionGlowEnabled
        FCP:RefreshHUD()
        print("|cff00ffcc[ForeverCombatPilot]|r Action Bar Glow: " .. (FCP.ActionGlowEnabled and "|cff00ff00ON|r" or "|cffff5555OFF|r"))
    else
        FCP.Enabled = not FCP.Enabled
        FCP:EnsureCombatTickerState()
        FCP:RefreshHUD()
        print("|cff00ffcc[ForeverCombatPilot]|r HUD: " .. (FCP.Enabled and "|cff00ff00SHOWN|r" or "|cffff5555HIDDEN|r"))
    end
end
