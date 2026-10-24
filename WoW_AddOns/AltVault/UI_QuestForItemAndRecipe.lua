-- ============================================================================
-- FILE: UI_QuestForItemAndRecipe.lua
-- BLOCK HEADING: "QUEST FOR ITEM" & "QUEST FOR RECIPE" DUAL-FACTION ACQUISITION TABS
-- Associates Alliance & Horde Quests, Vendors, Quartermasters, Trainers & Bosses
-- with every Item and Profession Recipe in AltVault (Classic + WoW Forever).
-- ============================================================================
local addonName, ns = ...
local MainPanel = _G.AltVaultMainPanel
if not MainPanel or not MainPanel.RegisterExternalTab then return end

local CreateBackdrop = MainPanel.CreateBackdrop
local SetSolid = MainPanel.SetSolid
local STANDARD_FONT = MainPanel.STANDARD_FONT or "Fonts\\FRIZQT__.TTF"
local QUALITY_HEX = MainPanel.QUALITY_HEX or {
    [0] = "9d9d9d", [1] = "ffffff", [2] = "1eff00", [3] = "0070dd",
    [4] = "a335ee", [5] = "ff8000", [6] = "e6cc80", [7] = "00ccff",
}
local GetItemIconTexture = MainPanel.GetItemIconTexture or function(id)
    if GetItemIcon then return GetItemIcon(id) end
    return "Interface\\Icons\\INV_Misc_QuestionMark"
end

ns.AcquisitionDB = ns.AcquisitionDB or {}
local AcquisitionDB = ns.AcquisitionDB

-- ============================================================================
-- BLOCK HEADING: FACTION STANDING TRANSLATOR & QUARTERMASTER / VENDOR ATLAS
-- ============================================================================
local STANDING_LABELS = {
    ["_G[FACTION_STANDING_LABEL4]"] = "Neutral",
    ["_G[FACTION_STANDING_LABEL5]"] = "Friendly",
    ["_G[FACTION_STANDING_LABEL6]"] = "Honored",
    ["_G[FACTION_STANDING_LABEL7]"] = "Revered",
    ["_G[FACTION_STANDING_LABEL8]"] = "Exalted",
}

local function CleanStandingTag(raw)
    if not raw or raw == "" then return "" end
    local s = tostring(raw)
    for k, v in pairs(STANDING_LABELS) do
        s = string.gsub(s, k, v)
    end
    s = string.gsub(s, "_G%[FACTION_STANDING_LABEL(%d+)%]", function(d)
        local n = tonumber(d)
        if n == 5 then return "Friendly"
        elseif n == 6 then return "Honored"
        elseif n == 7 then return "Revered"
        elseif n == 8 then return "Exalted"
        end
        return "Reputation"
    end)
    s = string.gsub(s, ",%s*nil", "")
    return s
end

-- Maps MasterDB Categories / SubSections to Dual-Faction Vendors, Quartermasters & Quest Givers
local CATEGORY_FACTION_ATLAS = {
    ["AlteracValley"] = {
        method = "VENDOR",
        alliance = "Vendor: Gaelden Hammersmith / Thanthaldis Snowgleam <Stormpike Supply Officer> (Dunbaldar, Alterac Valley / Alterac Mtns)",
        horde    = "Vendor: Grunnda Wolfheart / Jekyll Flandring <Frostwolf Supply Officer> (Frostwolf Keep, Alterac Valley / Alterac Mtns)",
    },
    ["WarsongGulch"] = {
        method = "VENDOR",
        alliance = "Vendor: Illiyana Moonblaze <Silverwing Supply Officer> (Silverwing Grove, Ashenvale)",
        horde    = "Vendor: Kelm Hargunth <Warsong Supply Officer> (Mor'shan Base Camp, Northern Barrens)",
    },
    ["ArathiBasin"] = {
        method = "VENDOR",
        alliance = "Vendor: Samuel Hawke <League of Arathor Supply Officer> (Refuge Pointe, Arathi Highlands)",
        horde    = "Vendor: Rutherford Twing <Defilers Supply Officer> (Hammerfall, Arathi Highlands)",
    },
    ["PvPMounts"] = {
        method = "VENDOR",
        alliance = "Vendor: Lieutenant Karter <Mount Vendor> (Champions' Hall, Stormwind - Rank 11 PvP)",
        horde    = "Vendor: Raider Bork <Mount Vendor> (Hall of Legends, Orgrimmar - Rank 11 PvP)",
    },
    ["Insignia"] = {
        method = "VENDOR",
        alliance = "Vendor: Officer Areyn / Sergeant Major Clate (Champions' Hall, Stormwind)",
        horde    = "Vendor: First Sergeant Hola'mahi / Brave Stonehide (Hall of Legends, Orgrimmar)",
    },
    ["Weapons"] = {
        method = "VENDOR",
        alliance = "Vendor: Lieutenant Jackspring <Weapons Quartermaster> (Champions' Hall, Stormwind - Rank 14)",
        horde    = "Vendor: Lady Palanseer <Weapons Quartermaster> (Hall of Legends, Orgrimmar - Rank 14)",
    },
    ["Tarnished Undermine Real"] = {
        method = "VENDOR",
        alliance = "Vendor: Pix Xizzix <Undermine Real Quartermaster> (Booty Bay, Stranglethorn Vale - Costs Tarnished Undermine Reals from Lvl 55+ Dungeon Bosses)",
        horde    = "Vendor: Pix Xizzix <Undermine Real Quartermaster> (Booty Bay, Stranglethorn Vale - Costs Tarnished Undermine Reals from Lvl 55+ Dungeon Bosses)",
    },
    ["Firelands Ember"] = {
        method = "VENDOR",
        alliance = "Vendor / Quest: Lokhtos Darkbargainer (Blackrock Depths - Grim Guzzler, Requires Firelands Embers)",
        horde    = "Vendor / Quest: Lokhtos Darkbargainer (Blackrock Depths - Grim Guzzler, Requires Firelands Embers)",
    },
    ["WaylaidSupplies"] = {
        method = "QUEST",
        alliance = "Quest Turn-In: Elaine Compton (Stormwind) / Tamelyn Aldridge (Ironforge) / Marcy Baker (Darnassus) <Azeroth Commerce Authority>",
        horde    = "Quest Turn-In: Jornah (Orgrimmar) / Gishah (Thunder Bluff) / Gordon Wendham (Undercity) <Durotar Supply and Logistics>",
    },
    ["Waylaid Supplies"] = {
        method = "QUEST",
        alliance = "Quest Turn-In: Elaine Compton (Stormwind) / Tamelyn Aldridge (Ironforge) / Marcy Baker (Darnassus) <Azeroth Commerce Authority>",
        horde    = "Quest Turn-In: Jornah (Orgrimmar) / Gishah (Thunder Bluff) / Gordon Wendham (Undercity) <Durotar Supply and Logistics>",
    },
    ["Darkmoon Faire"] = {
        method = "QUEST",
        alliance = "Quest / Vendor: Gelvas Grimegate & Professor Thaddeus Paleo (Darkmoon Faire - Goldshire, Elwynn Forest)",
        horde    = "Quest / Vendor: Gelvas Grimegate & Professor Thaddeus Paleo (Darkmoon Faire - Mulgore, southwest of Thunder Bluff)",
    },
    ["DarkmoonForever"] = {
        method = "QUEST",
        alliance = "Quest / Vendor: Gelvas Grimegate & Professor Thaddeus Paleo (Darkmoon Faire - Goldshire, Elwynn Forest)",
        horde    = "Quest / Vendor: Gelvas Grimegate & Professor Thaddeus Paleo (Darkmoon Faire - Mulgore, southwest of Thunder Bluff)",
    },
    ["Scourge Invasion"] = {
        method = "QUEST",
        alliance = "Quest / Vendor: Argent Quartermaster (Light's Hope Chapel, EPL / Stormwind / Ironforge - Necrotic Runes)",
        horde    = "Quest / Vendor: Argent Quartermaster (Light's Hope Chapel, EPL / Orgrimmar / Undercity - Necrotic Runes)",
    },
    ["AQ opening"] = {
        method = "QUEST",
        alliance = "Quest Chain: The Scepter of the Shifting Sands — Anachronos & Baristolth of the Shifting Sands (Cenarion Hold, Silithus)",
        horde    = "Quest Chain: The Scepter of the Shifting Sands — Anachronos & Baristolth of the Shifting Sands (Cenarion Hold, Silithus)",
    },
    ["Lunar Festival"] = {
        method = "QUEST",
        alliance = "Quest / Vendor: Valadar Starsong & Fariel Starsong (Nighthaven, Moonglade - Coin of Ancestry)",
        horde    = "Quest / Vendor: Valadar Starsong & Fariel Starsong (Nighthaven, Moonglade - Coin of Ancestry)",
    },
}

-- ============================================================================
-- BLOCK HEADING: CURATED DUAL-FACTION QUEST & VENDOR ITEM ENCYCLOPEDIA
-- Covers iconic Classic + WoW Forever Quest Rewards, Class Quests & Vendors
-- ============================================================================
local CURATED_QUEST_ITEMS = {
    -- Iconic Endgame Quest Trinkets, Rings, Weapons & Armor
    { id = 13965, name = "Blackhand's Breadth", slot = "Trinket", reqLvl = 55, q = 3, method = "QUEST",
      alliance = "Quest: General Drakkisath's Demise — Marshal Maxwell (Burning Steppes, Morgan's Vigil - UBRS)",
      horde    = "Quest: For The Horde! — Thrall / Overlord Runthak (Orgrimmar, Valley of Wisdom - UBRS)" },
    { id = 13966, name = "Mark of Tyranny", slot = "Trinket", reqLvl = 55, q = 3, method = "QUEST",
      alliance = "Quest: General Drakkisath's Demise — Marshal Maxwell (Burning Steppes, Morgan's Vigil - UBRS)",
      horde    = "Quest: For The Horde! — Thrall / Overlord Runthak (Orgrimmar, Valley of Wisdom - UBRS)" },
    { id = 13968, name = "Eye of the Beast", slot = "Trinket", reqLvl = 55, q = 3, method = "QUEST",
      alliance = "Quest: General Drakkisath's Demise — Marshal Maxwell (Burning Steppes, Morgan's Vigil - UBRS)",
      horde    = "Quest: For The Horde! — Thrall / Overlord Runthak (Orgrimmar, Valley of Wisdom - UBRS)" },
    { id = 15411, name = "Mark of Fordring", slot = "Neck", reqLvl = 56, q = 3, method = "QUEST",
      alliance = "Quest Chain: In Dreams — Tirion Fordring & Highlord Taelan Fordring (Western/Eastern Plaguelands)",
      horde    = "Quest Chain: In Dreams — Tirion Fordring & Highlord Taelan Fordring (Western/Eastern Plaguelands)" },
    { id = 16058, name = "Fordring's Seal", slot = "Finger", reqLvl = 56, q = 3, method = "QUEST",
      alliance = "Quest Chain: In Dreams — Tirion Fordring & Highlord Taelan Fordring (Western/Eastern Plaguelands)",
      horde    = "Quest Chain: In Dreams — Tirion Fordring & Highlord Taelan Fordring (Western/Eastern Plaguelands)" },
    { id = 15806, name = "Mirah's Song", slot = "One-Hand Sword", reqLvl = 57, q = 3, method = "QUEST",
      alliance = "Quest: Kirtonos the Herald — Eva Sarkhoff (Outside Scholomance, Western Plaguelands)",
      horde    = "Quest: Kirtonos the Herald — Eva Sarkhoff (Outside Scholomance, Western Plaguelands)" },
    { id = 17705, name = "Thrash Blade", slot = "One-Hand Sword", reqLvl = 45, q = 3, method = "QUEST",
      alliance = "Quest: Corruption of Earth and Seed — Selendra (Nijel's Point, Desolace -> Maraudon Princess Theradras)",
      horde    = "Quest: Corruption of Earth and Seed — Selendra (Shadowprey Path, Desolace -> Maraudon Princess Theradras)" },
    { id = 19120, name = "Rune of the Guard Captain", slot = "Trinket", reqLvl = 46, q = 2, method = "QUEST",
      alliance = "Horde Exclusive Quest Reward (Alliance Equivalent: Blackhand's Breadth / Royal Seal of Eldre'Thalas)",
      horde    = "Quest: Job Opening: Guard Captain of Revantusk Village — Primal Torntusk (Revantusk Village, The Hinterlands)" },
    { id = 18406, name = "Onyxia Blood Talisman", slot = "Trinket", reqLvl = 60, q = 4, method = "QUEST",
      alliance = "Quest: Celebrating Good Times — Highlord Bolvar Fordragon (Stormwind Keep - Head of Onyxia)",
      horde    = "Quest: For All To See — Overlord Runthak (Orgrimmar - Head of Onyxia)" },
    { id = 18404, name = "Onyxia Tooth Pendant", slot = "Neck", reqLvl = 60, q = 4, method = "QUEST",
      alliance = "Quest: Celebrating Good Times — Highlord Bolvar Fordragon (Stormwind Keep - Head of Onyxia)",
      horde    = "Quest: For All To See — Overlord Runthak (Orgrimmar - Head of Onyxia)" },
    { id = 18403, name = "Dragonslayer's Signet", slot = "Finger", reqLvl = 60, q = 4, method = "QUEST",
      alliance = "Quest: Celebrating Good Times — Highlord Bolvar Fordragon (Stormwind Keep - Head of Onyxia)",
      horde    = "Quest: For All To See — Overlord Runthak (Orgrimmar - Head of Onyxia)" },
    { id = 19383, name = "Master Dragonslayer's Medallion", slot = "Neck", reqLvl = 60, q = 4, method = "QUEST",
      alliance = "Quest: The Lord of Blackrock — Highlord Bolvar Fordragon (Stormwind Keep - Head of Nefarian)",
      horde    = "Quest: The Lord of Blackrock — High Overlord Saurfang (Orgrimmar - Head of Nefarian)" },
    { id = 19384, name = "Master Dragonslayer's Ring", slot = "Finger", reqLvl = 60, q = 4, method = "QUEST",
      alliance = "Quest: The Lord of Blackrock — Highlord Bolvar Fordragon (Stormwind Keep - Head of Nefarian)",
      horde    = "Quest: The Lord of Blackrock — High Overlord Saurfang (Orgrimmar - Head of Nefarian)" },
    { id = 19366, name = "Master Dragonslayer's Orb", slot = "Off-Hand", reqLvl = 60, q = 4, method = "QUEST",
      alliance = "Quest: The Lord of Blackrock — Highlord Bolvar Fordragon (Stormwind Keep - Head of Nefarian)",
      horde    = "Quest: The Lord of Blackrock — High Overlord Saurfang (Orgrimmar - Head of Nefarian)" },
    { id = 19950, name = "Zandalarian Hero Charm", slot = "Trinket", reqLvl = 58, q = 4, method = "QUEST",
      alliance = "Quest: The Heart of Hakkar — Molthor (Yojamba Isle, Stranglethorn Vale - Zul'Gurub)",
      horde    = "Quest: The Heart of Hakkar — Molthor (Yojamba Isle, Stranglethorn Vale - Zul'Gurub)" },
    { id = 19949, name = "Zandalarian Hero Medallion", slot = "Trinket", reqLvl = 58, q = 4, method = "QUEST",
      alliance = "Quest: The Heart of Hakkar — Molthor (Yojamba Isle, Stranglethorn Vale - Zul'Gurub)",
      horde    = "Quest: The Heart of Hakkar — Molthor (Yojamba Isle, Stranglethorn Vale - Zul'Gurub)" },
    { id = 19948, name = "Zandalarian Hero Badge", slot = "Trinket", reqLvl = 58, q = 4, method = "QUEST",
      alliance = "Quest: The Heart of Hakkar — Molthor (Yojamba Isle, Stranglethorn Vale - Zul'Gurub)",
      horde    = "Quest: The Heart of Hakkar — Molthor (Yojamba Isle, Stranglethorn Vale - Zul'Gurub)" },
    { id = 19822, name = "Zandalar Vindicator's Breastplate", slot = "Chest", reqLvl = 60, q = 4, method = "QUEST",
      alliance = "Quest: Paragons of Power — Al'tabim the All-Seeing (Yojamba Isle, STV - Zandalar Tribe Rep)",
      horde    = "Quest: Paragons of Power — Al'tabim the All-Seeing (Yojamba Isle, STV - Zandalar Tribe Rep)" },
    -- Blackrock Depths Dual-Faction Princess Quest Rings
    { id = 12548, name = "Magni's Will", slot = "Finger", reqLvl = 50, q = 3, method = "QUEST",
      alliance = "Quest: The Fate of the Kingdom — King Magni Bronzebeard (Ironforge Throne Room -> BRD Emperor Thaurissan)",
      horde    = "Alliance Exclusive Ring — Horde Equivalent: Thrall's Resolve [#12544] (Quest: The Royal Rescue in Orgrimmar)" },
    { id = 12543, name = "Songstone of Ironforge", slot = "Finger", reqLvl = 50, q = 3, method = "QUEST",
      alliance = "Quest: The Fate of the Kingdom — King Magni Bronzebeard (Ironforge Throne Room -> BRD Emperor Thaurissan)",
      horde    = "Alliance Exclusive Ring — Horde Equivalent: Eye of Orgrimmar [#12545] (Quest: The Royal Rescue in Orgrimmar)" },
    { id = 12544, name = "Thrall's Resolve", slot = "Finger", reqLvl = 50, q = 3, method = "QUEST",
      alliance = "Horde Exclusive Ring — Alliance Equivalent: Magni's Will [#12548] (Quest: The Fate of the Kingdom in Ironforge)",
      horde    = "Quest: The Royal Rescue — Thrall & Princess Moira Bronzebeard (Orgrimmar -> BRD Emperor Thaurissan)" },
    { id = 12545, name = "Eye of Orgrimmar", slot = "Finger", reqLvl = 50, q = 3, method = "QUEST",
      alliance = "Horde Exclusive Ring — Alliance Equivalent: Songstone of Ironforge [#12543] (Quest: The Fate of the Kingdom in Ironforge)",
      horde    = "Quest: The Royal Rescue — Thrall & Princess Moira Bronzebeard (Orgrimmar -> BRD Emperor Thaurissan)" },
    -- Scarlet Monastery Dual-Faction Weapon Quests
    { id = 6802, name = "Sword of Serenity", slot = "One-Hand Sword", reqLvl = 34, q = 3, method = "QUEST",
      alliance = "Quest: In the Name of the Light — Raleigh the Devout (Southshore, Hillsbrad -> Scarlet Monastery)",
      horde    = "Alliance Exclusive Quest — Horde Equivalent: Sword of Omen [#6802/10758] (Quest: Into The Scarlet Monastery in Undercity)" },
    { id = 6830, name = "Bonebiter", slot = "Two-Hand Axe", reqLvl = 34, q = 3, method = "QUEST",
      alliance = "Quest: In the Name of the Light — Raleigh the Devout (Southshore, Hillsbrad -> Scarlet Monastery)",
      horde    = "Alliance Exclusive Quest — Horde Equivalent: Whirlwind Axe [#6975] / Prophetic Cane (Undercity SM Quest)" },
    { id = 6803, name = "Sword of Omen", slot = "One-Hand Sword", reqLvl = 33, q = 3, method = "QUEST",
      alliance = "Horde Exclusive Quest — Alliance Equivalent: Sword of Serenity [#6802] (Quest: In the Name of the Light in Southshore)",
      horde    = "Quest: Into The Scarlet Monastery — Varimathras (Royal Quarter, Undercity -> Scarlet Monastery)" },
    -- Razorfen Downs Dual-Faction Sword
    { id = 10823, name = "Vanquisher's Sword", slot = "One-Hand Sword", reqLvl = 37, q = 3, method = "QUEST",
      alliance = "Quest: Bring the Light — Archbishop Benedictus (Cathedral of Light, Stormwind -> RFD Amnennar the Coldbringer)",
      horde    = "Quest: Bring the End — Andrew Brownell (The Apothecarium, Undercity -> RFD Amnennar the Coldbringer)" },
    -- Deadmines / Wailing Caverns / Shadowfang Keep Quests
    { id = 2042, name = "Staff of Westfall", slot = "Two-Hand Staff", reqLvl = 14, q = 3, method = "QUEST",
      alliance = "Quest: The Defias Brotherhood — Gryan Stoutmantle (Sentinel Hill, Westfall -> Deadmines Edwin VanCleef)",
      horde    = "Alliance Exclusive Quest — Horde Equivalent: Crescent Staff [#6505] (Quest: Leaders of the Fang in Wailing Caverns)" },
    { id = 2041, name = "Tunic of Westfall", slot = "Leather Chest", reqLvl = 14, q = 3, method = "QUEST",
      alliance = "Quest: The Defias Brotherhood — Gryan Stoutmantle (Sentinel Hill, Westfall -> Deadmines Edwin VanCleef)",
      horde    = "Alliance Exclusive Quest — Horde Equivalent: Wingblade / Crescent Staff (Wailing Caverns Quest)" },
    { id = 2043, name = "Chausses of Westfall", slot = "Mail Legs", reqLvl = 14, q = 3, method = "QUEST",
      alliance = "Quest: The Defias Brotherhood — Gryan Stoutmantle (Sentinel Hill, Westfall -> Deadmines Edwin VanCleef)",
      horde    = "Alliance Exclusive Quest — Horde Equivalent: Firebelcher / Crescent Staff (Wailing Caverns Quest)" },
    { id = 2933, name = "Seal of Wrynn", slot = "Finger", reqLvl = 16, q = 3, method = "QUEST",
      alliance = "Quest Chain: An Unsent Letter -> Bazil Thredd — Baros Alexston (Cathedral Square, Stormwind)",
      horde    = "Alliance Exclusive Ring — Horde Equivalent: Seal of Sylvanas [#6414] (Quest: Arugal Must Die in Sepulcher, Silverpine)" },
    { id = 6414, name = "Seal of Sylvanas", slot = "Finger", reqLvl = 18, q = 3, method = "QUEST",
      alliance = "Horde Exclusive Ring — Alliance Equivalent: Seal of Wrynn [#2933] (Stormwind VanCleef Letter Chain)",
      horde    = "Quest: Arugal Must Die — High Executor Hadrec (The Sepulcher, Silverpine Forest -> Shadowfang Keep)" },
    { id = 6505, name = "Crescent Staff", slot = "Two-Hand Staff", reqLvl = 15, q = 3, method = "QUEST",
      alliance = "Horde Exclusive Quest — Alliance Equivalent: Staff of Westfall [#2042] (Sentinel Hill, Westfall)",
      horde    = "Quest: Leaders of the Fang — Nara Wildmane (Elder Rise, Thunder Bluff -> Wailing Caverns)" },
    { id = 6504, name = "Wingblade", slot = "One-Hand Sword", reqLvl = 15, q = 3, method = "QUEST",
      alliance = "Horde Exclusive Quest — Alliance Equivalent: Tunic of Westfall [#2041] (Sentinel Hill, Westfall)",
      horde    = "Quest: Leaders of the Fang — Nara Wildmane (Elder Rise, Thunder Bluff -> Wailing Caverns)" },
    -- Gnomeregan Dual-Faction Quest Pants
    { id = 9624, name = "Triprunner Dungarees", slot = "Leather Legs", reqLvl = 25, q = 3, method = "QUEST",
      alliance = "Quest: The Grand Betrayal — High Tinker Mekkatorque (Tinkertown, Ironforge -> Gnomeregan Thermaplugg)",
      horde    = "Quest: Rig Wars — Nogg (Valley of Honor, Orgrimmar -> Gnomeregan Thermaplugg)" },
    { id = 9623, name = "Civinad Robes", slot = "Cloth Chest", reqLvl = 25, q = 3, method = "QUEST",
      alliance = "Quest: The Grand Betrayal — High Tinker Mekkatorque (Tinkertown, Ironforge -> Gnomeregan Thermaplugg)",
      horde    = "Quest: Rig Wars — Nogg (Valley of Honor, Orgrimmar -> Gnomeregan Thermaplugg)" },
    { id = 9625, name = "Dual Reinforced Leggings", slot = "Mail Legs", reqLvl = 25, q = 3, method = "QUEST",
      alliance = "Quest: The Grand Betrayal — High Tinker Mekkatorque (Tinkertown, Ironforge -> Gnomeregan Thermaplugg)",
      horde    = "Quest: Rig Wars — Nogg (Valley of Honor, Orgrimmar -> Gnomeregan Thermaplugg)" },
    -- Class Weapon Quests
    { id = 6975, name = "Whirlwind Axe", slot = "Two-Hand Axe", reqLvl = 30, q = 3, method = "QUEST",
      alliance = "Warrior Class Quest: The Summoning (Cyclonian) — Bath'rah the Windwatcher (Alterac Mountains)",
      horde    = "Warrior Class Quest: The Summoning (Cyclonian) — Bath'rah the Windwatcher (Alterac Mountains)" },
    { id = 6976, name = "Whirlwind Warhammer", slot = "Two-Hand Mace", reqLvl = 30, q = 3, method = "QUEST",
      alliance = "Warrior Class Quest: The Summoning (Cyclonian) — Bath'rah the Windwatcher (Alterac Mountains)",
      horde    = "Warrior Class Quest: The Summoning (Cyclonian) — Bath'rah the Windwatcher (Alterac Mountains)" },
    { id = 6977, name = "Whirlwind Sword", slot = "Two-Hand Sword", reqLvl = 30, q = 3, method = "QUEST",
      alliance = "Warrior Class Quest: The Summoning (Cyclonian) — Bath'rah the Windwatcher (Alterac Mountains)",
      horde    = "Warrior Class Quest: The Summoning (Cyclonian) — Bath'rah the Windwatcher (Alterac Mountains)" },
    { id = 20130, name = "Diamond Flask", slot = "Trinket", reqLvl = 50, q = 3, method = "QUEST",
      alliance = "Warrior Class Quest: Voodoo Feathers — Fallen Hero of the Horde (Swamp of Sorrows -> Sunken Temple)",
      horde    = "Warrior Class Quest: Voodoo Feathers — Fallen Hero of the Horde (Swamp of Sorrows -> Sunken Temple)" },
    { id = 6953, name = "Verigan's Fist", slot = "Two-Hand Mace", reqLvl = 20, q = 3, method = "QUEST",
      alliance = "Paladin Class Quest: The Test of Righteousness — Jordan Stilwell (Outside Ironforge -> Deadmines/SFK/BFD)",
      horde    = "Alliance Paladin Exclusive Class Quest (Horde Shaman Quest: Call of Fire / Call of Water Totems)" },
    { id = 18608, name = "Benediction", slot = "Two-Hand Staff", reqLvl = 60, q = 4, method = "QUEST",
      alliance = "Priest Class Quest: The Balance of Light and Shadow — Eris Havenfire (Eastern Plaguelands - Eye of Divinity + Eye of Shadow)",
      horde    = "Priest Class Quest: The Balance of Light and Shadow — Eris Havenfire (Eastern Plaguelands - Eye of Divinity + Eye of Shadow)" },
    { id = 18609, name = "Anathema", slot = "Two-Hand Staff", reqLvl = 60, q = 4, method = "QUEST",
      alliance = "Priest Class Quest: The Balance of Light and Shadow — Eris Havenfire (Eastern Plaguelands - Transform Benediction)",
      horde    = "Priest Class Quest: The Balance of Light and Shadow — Eris Havenfire (Eastern Plaguelands - Transform Benediction)" },
    { id = 18713, name = "Rhok'delar, Longbow of the Ancient Keepers", slot = "Bow", reqLvl = 60, q = 4, method = "QUEST",
      alliance = "Hunter Class Quest: Stave of the Ancients — Vartrus the Ancient (Felwood - Ancient Petrified Leaf from Majordomo)",
      horde    = "Hunter Class Quest: Stave of the Ancients — Vartrus the Ancient (Felwood - Ancient Petrified Leaf from Majordomo)" },
    { id = 18715, name = "Lok'delar, Stave of the Ancient Keepers", slot = "Two-Hand Staff", reqLvl = 60, q = 4, method = "QUEST",
      alliance = "Hunter Class Quest: Stave of the Ancients — Vartrus the Ancient (Felwood - Ancient Petrified Leaf from Majordomo)",
      horde    = "Hunter Class Quest: Stave of the Ancients — Vartrus the Ancient (Felwood - Ancient Petrified Leaf from Majordomo)" },
    { id = 18348, name = "Quel'Serrar", slot = "One-Hand Sword", reqLvl = 60, q = 4, method = "QUEST",
      alliance = "Warrior/Paladin Quest: The Forging of Quel'Serrar — Lorekeeper Lydros (Dire Maul Library + Onyxia's Breath)",
      horde    = "Warrior Quest: The Forging of Quel'Serrar — Lorekeeper Lydros (Dire Maul Library + Onyxia's Breath)" },
    -- Dire Maul Class Book Trinkets
    { id = 18473, name = "Royal Seal of Eldre'Thalas", slot = "Trinket", reqLvl = 57, q = 3, method = "QUEST",
      alliance = "Class Book Quest: Lorekeeper Lydros / Scholar Runethorn (Dire Maul Library - Athenaeum)",
      horde    = "Class Book Quest: Lorekeeper Lydros / Scholar Runethorn (Dire Maul Library - Athenaeum)" },
    -- Un'Goro Linken Chain & Carrot on a Stick
    { id = 11902, name = "Linken's Sword of Mastery", slot = "One-Hand Sword", reqLvl = 47, q = 3, method = "QUEST",
      alliance = "Quest Chain: It's a Secret to Everybody -> Alone in the Woods — Linken (Marshal's Refuge, Un'Goro Crater)",
      horde    = "Quest Chain: It's a Secret to Everybody -> Alone in the Woods — Linken (Marshal's Refuge, Un'Goro Crater)" },
    { id = 11905, name = "Linken's Boomerang", slot = "Trinket", reqLvl = 47, q = 2, method = "QUEST",
      alliance = "Quest Chain: It's a Secret to Everybody -> Alone in the Woods — Linken (Marshal's Refuge, Un'Goro Crater)",
      horde    = "Quest Chain: It's a Secret to Everybody -> Alone in the Woods — Linken (Marshal's Refuge, Un'Goro Crater)" },
    { id = 11122, name = "Carrot on a Stick", slot = "Trinket", reqLvl = 40, q = 2, method = "QUEST",
      alliance = "Quest: Gahz'rilla — Wizzle Brassbolts (Mirage Raceway, Thousand Needles -> Zul'Farrak)",
      horde    = "Quest: Gahz'rilla — Wizzle Brassbolts (Mirage Raceway, Thousand Needles -> Zul'Farrak)" },
    -- Argent Dawn & EPL Quests
    { id = 13938, name = "Bonecreeper Stylus", slot = "Wand", reqLvl = 57, q = 3, method = "BOSS",
      alliance = "Boss Drop: Darkmaster Gandling (Scholomance, Western Plaguelands)",
      horde    = "Boss Drop: Darkmaster Gandling (Scholomance, Western Plaguelands)" },
    { id = 22383, name = "Sageblade", slot = "One-Hand Sword", reqLvl = 60, q = 4, method = "CRAFT",
      alliance = "Crafted by Master Swordsmith (300 Blacksmithing - Plans sold by Shen'dralar Provisioner in Dire Maul)",
      horde    = "Crafted by Master Swordsmith (300 Blacksmithing - Plans sold by Shen'dralar Provisioner in Dire Maul)" },
    { id = 12640, name = "Lionheart Helm", slot = "Plate Head", reqLvl = 56, q = 4, method = "CRAFT",
      alliance = "Crafted by Armorsmith (300 Blacksmithing - Plans #12696 World/Raid Drop)",
      horde    = "Crafted by Armorsmith (300 Blacksmithing - Plans #12696 World/Raid Drop)" },
    { id = 19169, name = "Nightfall", slot = "Two-Hand Axe", reqLvl = 60, q = 4, method = "CRAFT",
      alliance = "Crafted by Master Axesmith (300 Blacksmithing - Plans sold by Lokhtos Darkbargainer, BRD Grim Guzzler - Thorium Brotherhood Exalted)",
      horde    = "Crafted by Master Axesmith (300 Blacksmithing - Plans sold by Lokhtos Darkbargainer, BRD Grim Guzzler - Thorium Brotherhood Exalted)" },
    { id = 14152, name = "Robe of the Archmage", slot = "Cloth Chest", reqLvl = 57, q = 4, method = "CRAFT",
      alliance = "Crafted by 300 Tailoring (Pattern #14495 Drops from Pyromancer Loregrain in Blackrock Depths)",
      horde    = "Crafted by 300 Tailoring (Pattern #14495 Drops from Pyromancer Loregrain in Blackrock Depths)" },
    { id = 14153, name = "Robe of the Void", slot = "Cloth Chest", reqLvl = 57, q = 4, method = "CRAFT",
      alliance = "Crafted by 300 Tailoring (Pattern #14481 Drops from Darkmaster Gandling in Scholomance)",
      horde    = "Crafted by 300 Tailoring (Pattern #14481 Drops from Darkmaster Gandling in Scholomance)" },
    { id = 14154, name = "Truefaith Vestments", slot = "Cloth Chest", reqLvl = 57, q = 4, method = "CRAFT",
      alliance = "Crafted by 300 Tailoring (Pattern #14492 Drops from Balnazzar in Stratholme Live)",
      horde    = "Crafted by 300 Tailoring (Pattern #14492 Drops from Balnazzar in Stratholme Live)" },
    { id = 18510, name = "Hide of the Wild", slot = "Back", reqLvl = 57, q = 4, method = "CRAFT",
      alliance = "Crafted by 300 Tribal Leatherworking (Pattern #18518 from Knot Thimblejack's Cache, Dire Maul North)",
      horde    = "Crafted by 300 Tribal Leatherworking (Pattern #18518 from Knot Thimblejack's Cache, Dire Maul North)" },
    { id = 15062, name = "Devilsaur Leggings", slot = "Leather Legs", reqLvl = 55, q = 3, method = "CRAFT",
      alliance = "Crafted by 300 Tribal Leatherworking (Pattern #15772 Drops from Oozes/Mobs in Un'Goro Crater)",
      horde    = "Crafted by 300 Tribal Leatherworking (Pattern #15772 Drops from Oozes/Mobs in Un'Goro Crater)" },
    { id = 15063, name = "Devilsaur Gauntlets", slot = "Leather Hands", reqLvl = 53, q = 3, method = "CRAFT",
      alliance = "Crafted by 290 Tribal Leatherworking (Pattern #15758 Sold by Nergal in Marshal's Refuge, Un'Goro Crater)",
      horde    = "Crafted by 290 Tribal Leatherworking (Pattern #15758 Sold by Nergal in Marshal's Refuge, Un'Goro Crater)" },
}

local CURATED_ITEMS_BY_ID = {}
for _, entry in ipairs(CURATED_QUEST_ITEMS) do
    CURATED_ITEMS_BY_ID[entry.id] = entry
end

-- ============================================================================
-- BLOCK HEADING: PROFESSION TRAINER ATLAS (APPRENTICE -> ARTISAN / MASTER)
-- Maps every Profession + Skill Rank to Alliance & Horde Trainers & Cities!
-- ============================================================================
local PROF_TRAINER_ATLAS = {
    ["Alchemy"] = {
        apprentice = {
            alliance = "Trainer (1-150): Lilyssia Nightbreeze (Stormwind), Tally Berryfizz (Ironforge), Ainethil (Darnassus)",
            horde    = "Trainer (1-150): Yelmak (Orgrimmar), Doctor Marsh (Undercity), Bena Winterhoof (Thunder Bluff)",
        },
        expert = {
            alliance = "Expert Trainer (150-225): Ainethil (Craftsmen's Terrace, Darnassus) or Kylanna (Ashenvale)",
            horde    = "Expert Trainer (150-225): Doctor Herbert Halsey (The Apothecarium, Undercity) or Miao'zan (Sen'jin)",
        },
        artisan = {
            alliance = "Artisan Trainer (225-300+): Kylanna Windwhisper (Feathermoon Stronghold, Feralas)",
            horde    = "Artisan Trainer (225-300+): Rogvar (Stonard, Swamp of Sorrows)",
        },
    },
    ["Blacksmithing"] = {
        apprentice = {
            alliance = "Trainer (1-150): Therum Deepforge (Stormwind), Groum Stonebeard (Ironforge), Delfrum Flintbeard (Loch Modan)",
            horde    = "Trainer (1-150): Saru Steelfury (Orgrimmar), James Van Brunt (Undercity), Karn Stonehoof (Thunder Bluff)",
        },
        expert = {
            alliance = "Expert Trainer (150-225): Bengus Deepforge (The Great Forge, Ironforge)",
            horde    = "Expert Trainer (150-225): Saru Steelfury (Valley of Honor, Orgrimmar)",
        },
        artisan = {
            alliance = "Artisan Trainer (225-300+): Brikk Keencraft (Booty Bay, Stranglethorn Vale) or Bengus Deepforge (Ironforge)",
            horde    = "Artisan Trainer (225-300+): Brikk Keencraft (Booty Bay, Stranglethorn Vale) or Borgosh Corebender (Orgrimmar)",
        },
    },
    ["Enchanting"] = {
        apprentice = {
            alliance = "Trainer (1-150): Lucan Cordell (Stormwind), Gimble Thistlefuzz (Ironforge), Taladan (Darnassus)",
            horde    = "Trainer (1-150): Godan (Orgrimmar), Malcomb Wynn (Undercity), Teg Dawnstrider (Thunder Bluff)",
        },
        expert = {
            alliance = "Expert Trainer (150-225): Kitta Firewind (Tower of Azora, Elwynn Forest)",
            horde    = "Expert Trainer (150-225): Hgarth (Sun Rock Retreat, Stonetalon Mountains)",
        },
        artisan = {
            alliance = "Artisan Trainer (225-300+): Annora <Master Enchanter> (Inside Uldaman Dungeon, Badlands)",
            horde    = "Artisan Trainer (225-300+): Annora <Master Enchanter> (Inside Uldaman Dungeon, Badlands)",
        },
    },
    ["Engineering"] = {
        apprentice = {
            alliance = "Trainer (1-150): Lilliam Sparkspindle (Stormwind), Jemma Quikswitch (Ironforge), Finbus Geargrind (Duskwood)",
            horde    = "Trainer (1-150): Roxxik (Orgrimmar), Franklin Lloyd (Undercity), Twizwick Sprocket (The Barrens)",
        },
        expert = {
            alliance = "Expert Trainer (150-225): Springspindle Fizzlegear (Tinker Town, Ironforge)",
            horde    = "Expert Trainer (150-225): Roxxik (Valley of Honor, Orgrimmar)",
        },
        artisan = {
            alliance = "Artisan Trainer (225-300+): Buzzek Bracketswing (Gadgetzan, Tanaris) or Springspindle Fizzlegear (Ironforge)",
            horde    = "Artisan Trainer (225-300+): Buzzek Bracketswing (Gadgetzan, Tanaris) or Roxxik (Orgrimmar)",
        },
    },
    ["Leatherworking"] = {
        apprentice = {
            alliance = "Trainer (1-150): Simon Tanner (Stormwind), Fimble Finespindle (Ironforge), Telonis (Darnassus)",
            horde    = "Trainer (1-150): Karolek (Orgrimmar), Arthur Moore (Undercity), Una (Thunder Bluff)",
        },
        expert = {
            alliance = "Expert Trainer (150-225): Telonis (Craftsmen's Terrace, Darnassus)",
            horde    = "Expert Trainer (150-225): Una (Thunder Bluff)",
        },
        artisan = {
            alliance = "Artisan Trainer (225-300+): Drakk Stonehand (Aerie Peak, The Hinterlands)",
            horde    = "Artisan Trainer (225-300+): Hahrana Ironhide (Camp Mojache, Feralas)",
        },
    },
    ["Tailoring"] = {
        apprentice = {
            alliance = "Trainer (1-150): Sellandus (Stormwind), Jormund Stonebrow (Ironforge), Me'lynn (Darnassus)",
            horde    = "Trainer (1-150): Magar (Orgrimmar), Rhiannon Davis (Undercity), Tepa (Thunder Bluff)",
        },
        expert = {
            alliance = "Expert Trainer (150-225): Georgio Bolero (Mage Quarter, Stormwind)",
            horde    = "Expert Trainer (150-225): Josef Gregorian (Magic Quarter, Undercity)",
        },
        artisan = {
            alliance = "Artisan Trainer (225-300+): Timothy Worthington (Theramore Isle, Dustwallow Marsh)",
            horde    = "Artisan Trainer (225-300+): Daryl Stack (Tarren Mill, Hillsbrad Foothills)",
        },
    },
    ["Cooking"] = {
        apprentice = {
            alliance = "Trainer (1-125): Stephen Ryback (Stormwind), Daryl Riknussun (Ironforge), Alegorn (Darnassus)",
            horde    = "Trainer (1-125): Zamja (Orgrimmar), Eunice Burch (Undercity), Aska Mistrunner (Thunder Bluff)",
        },
        expert = {
            alliance = "Vendor Book (125-225): 'Expert Cookbook' sold by Shandrina (Mystral Lake, Ashenvale)",
            horde    = "Vendor Book (125-225): 'Expert Cookbook' sold by Wulan (Shadowprey Village, Desolace)",
        },
        artisan = {
            alliance = "Quest (225-300+): 'Clamlette Surprise' from Dirge Quikcleave (Gadgetzan, Tanaris)",
            horde    = "Quest (225-300+): 'Clamlette Surprise' from Dirge Quikcleave (Gadgetzan, Tanaris)",
        },
    },
    ["First Aid"] = {
        apprentice = {
            alliance = "Trainer (1-125): Shaina Fuller (Stormwind), Nissa Firestone (Ironforge), Dannelor (Darnassus)",
            horde    = "Trainer (1-125): Arnok (Orgrimmar), Mary Edras (Undercity), Pand Stonebinder (Thunder Bluff)",
        },
        expert = {
            alliance = "Vendor Book (125-225): 'Expert First Aid - Under Wraps' sold by Deneb Walker (Stromgarde Keep, Arathi Highlands)",
            horde    = "Vendor Book (125-225): 'Expert First Aid - Under Wraps' sold by Balai Lok'Wein (Brackenwall Village, Dustwallow Marsh)",
        },
        artisan = {
            alliance = "Quest (225-300+): 'Triage' from Doctor Gustaf VanHowzen (Theramore Isle, Dustwallow Marsh)",
            horde    = "Quest (225-300+): 'Triage' from Doctor Gregory Victor (Hammerfall, Arathi Highlands)",
        },
    },
    ["Mining"] = {
        apprentice = {
            alliance = "Trainer (1-300): Gelman Stonehand (Stormwind), Geofram Bouldertoe (Ironforge), Kurdram Stonehammer (Darkshore)",
            horde    = "Trainer (1-300): Makaru (Orgrimmar), Brom Killian (Undercity), Brek Stonehoof (Thunder Bluff)",
        },
        expert = {
            alliance = "Trainer (150-300): Geofram Bouldertoe (The Great Forge, Ironforge) / Pikkle (Gadgetzan)",
            horde    = "Trainer (150-300): Makaru (Valley of Honor, Orgrimmar) / Pikkle (Gadgetzan)",
        },
        artisan = {
            alliance = "Quest / Trainer (230-300): Smelt Dark Iron — Gloom'rel (Summoner's Tomb, Blackrock Depths - 20 Gold Bar, 2 Star Ruby, 10 Truesilver)",
            horde    = "Quest / Trainer (230-300): Smelt Dark Iron — Gloom'rel (Summoner's Tomb, Blackrock Depths - 20 Gold Bar, 2 Star Ruby, 10 Truesilver)",
        },
    },
    ["Rogue Poisons"] = {
        apprentice = {
            alliance = "Rogue Trainer & Poison Supplies: Sloan McCoy (SI:7, Stormwind) / Hulfdan Blackbeard (Ironforge)",
            horde    = "Rogue Trainer & Poison Supplies:Rekkul (Cleft of Shadow, Orgrimmar) / Ezekiel Graves (Undercity)",
        },
        expert = {
            alliance = "Rogue Trainer & Quest: Mathias Shaw (SI:7, Stormwind - Quest: Klaven's Tower)",
            horde    = "Rogue Trainer & Quest: Shenthul (Cleft of Shadow, Orgrimmar - Quest: Mission: Possible But Not Probable)",
        },
        artisan = {
            alliance = "Rogue Trainer (225-300): Jorach Ravenholdt / Fahrad (Ravenholdt Manor, Hillsbrad Foothills)",
            horde    = "Rogue Trainer (225-300): Jorach Ravenholdt / Fahrad (Ravenholdt Manor, Hillsbrad Foothills)",
        },
    },
}

-- ============================================================================
-- BLOCK HEADING: CURATED DUAL-FACTION RECIPE VENDOR, QUEST, REP & DROP ATLAS
-- Matches Recipe/Spell Names & Pattern Item IDs to exact Alliance & Horde NPCs!
-- ============================================================================
local CURATED_RECIPE_SOURCES = {
    -- ALCHEMY RECIPES (VENDORS, QUESTS, REPS & DROPS)
    { match = "free action potion", prof = "Alchemy", rank = 150, method = "VENDOR",
      alliance = "Vendor: Soolie Berryfizz (Tinker Town, Ironforge) or Ulthir (Craftsmen's Terrace, Darnassus)",
      horde    = "Vendor: Kor'geld (Drag, Orgrimmar) or Hagrus (Orgrimmar)" },
    { match = "rage potion", prof = "Alchemy", rank = 60, method = "VENDOR",
      alliance = "Vendor: Maria Lumere (Canals, Stormwind) or Harklan Moongrove (Ashenvale)",
      horde    = "Vendor: Hagrus (Drag, Orgrimmar) or Worb Strongstitch (Feralas)" },
    { match = "great rage potion", prof = "Alchemy", rank = 175, method = "VENDOR",
      alliance = "Vendor: Ulthir (Craftsmen's Terrace, Darnassus)",
      horde    = "Vendor: Hagrus (The Drag, Orgrimmar)" },
    { match = "holy protection potion", prof = "Alchemy", rank = 100, method = "VENDOR",
      alliance = "Vendor: Harklan Moongrove (Astranaar, Ashenvale) or Kzixx (Duskwood)",
      horde    = "Vendor: Hula'mahi (The Crossroads, The Barrens) or Christoph Jeffcoat (Tarren Mill)" },
    { match = "shadow protection potion", prof = "Alchemy", rank = 135, method = "VENDOR",
      alliance = "Vendor: Harklan Moongrove (Astranaar, Ashenvale)",
      horde    = "Vendor: Christoph Jeffcoat (Tarren Mill, Hillsbrad Foothills)" },
    { match = "frost protection potion", prof = "Alchemy", rank = 190, method = "VENDOR",
      alliance = "Vendor: Drovnar Strongbrew (Refuge Pointe, Arathi Highlands)",
      horde    = "Vendor: Glyx Brewright (Booty Bay, Stranglethorn Vale)" },
    { match = "fire protection potion", prof = "Alchemy", rank = 165, method = "VENDOR",
      alliance = "Vendor: Nandar Branson (Southshore, Hillsbrad Foothills)",
      horde    = "Vendor: Jeeda (Sun Rock Retreat, Stonetalon Mountains)" },
    { match = "nature protection potion", prof = "Alchemy", rank = 190, method = "VENDOR",
      alliance = "Vendor: Alchemist Pestlezugg (Gadgetzan, Tanaris) or Glyx Brewright (Booty Bay)",
      horde    = "Vendor: Alchemist Pestlezugg (Gadgetzan, Tanaris) or Bronk (Camp Mojache, Feralas)" },
    { match = "superior mana potion", prof = "Alchemy", rank = 260, method = "VENDOR",
      alliance = "Vendor: Ulthir (Craftsmen's Terrace, Darnassus)",
      horde    = "Vendor: Algernon (The Apothecarium, Undercity)" },
    { match = "major healing potion", prof = "Alchemy", rank = 275, method = "VENDOR",
      alliance = "Vendor: Evie Whirlbrew (Everlook, Winterspring)",
      horde    = "Vendor: Evie Whirlbrew (Everlook, Winterspring)" },
    { match = "major mana potion", prof = "Alchemy", rank = 295, method = "VENDOR",
      alliance = "Vendor / Drop: Magnus Frostwake (Outside Scholomance, WPL - Requires Essence of Undeath quest) or Darkmaster Gandling Drop",
      horde    = "Vendor / Drop: Magnus Frostwake (Outside Scholomance, WPL - Requires Essence of Undeath quest) or Darkmaster Gandling Drop" },
    { match = "transmute: arcanite", prof = "Alchemy", rank = 275, method = "VENDOR",
      alliance = "Vendor: Alchemist Pestlezugg (Gadgetzan, Tanaris)",
      horde    = "Vendor: Alchemist Pestlezugg (Gadgetzan, Tanaris)" },
    { match = "philosophers' stone", prof = "Alchemy", rank = 225, method = "VENDOR",
      alliance = "Vendor: Alchemist Pestlezugg (Gadgetzan, Tanaris)",
      horde    = "Vendor: Alchemist Pestlezugg (Gadgetzan, Tanaris)" },
    { match = "transmute: iron to gold", prof = "Alchemy", rank = 225, method = "VENDOR",
      alliance = "Vendor: Alchemist Pestlezugg (Gadgetzan, Tanaris)",
      horde    = "Vendor: Alchemist Pestlezugg (Gadgetzan, Tanaris)" },
    { match = "transmute: mithril to truesilver", prof = "Alchemy", rank = 225, method = "VENDOR",
      alliance = "Vendor: Alchemist Pestlezugg (Gadgetzan, Tanaris)",
      horde    = "Vendor: Alchemist Pestlezugg (Gadgetzan, Tanaris)" },
    { match = "transmute: undeath to water", prof = "Alchemy", rank = 275, method = "DROP",
      alliance = "World Drop (Lvl 50-60 Mobs in Plaguelands, Winterspring, Silithus)",
      horde    = "World Drop (Lvl 50-60 Mobs in Plaguelands, Winterspring, Silithus)" },
    { match = "transmute: water to air", prof = "Alchemy", rank = 275, method = "QUEST",
      alliance = "Quest / Vendor: Magnus Frostwake (Caer Darrow, Western Plaguelands - Requires 'The Lich, Ras Frostwhisper')",
      horde    = "Quest / Vendor: Magnus Frostwake (Caer Darrow, Western Plaguelands - Requires 'The Lich, Ras Frostwhisper')" },
    { match = "transmute: air to fire", prof = "Alchemy", rank = 275, method = "REP",
      alliance = "Reputation Vendor: Quartermaster Miranda Breechlock (Light's Hope Chapel, EPL - Argent Dawn Honored)",
      horde    = "Reputation Vendor: Quartermaster Miranda Breechlock (Light's Hope Chapel, EPL - Argent Dawn Honored)" },
    { match = "transmute: fire to earth", prof = "Alchemy", rank = 275, method = "VENDOR",
      alliance = "Vendor: Plugger Spazzring (Grim Guzzler Bar, Blackrock Depths)",
      horde    = "Vendor: Plugger Spazzring (Grim Guzzler Bar, Blackrock Depths)" },
    { match = "transmute: elemental fire", prof = "Alchemy", rank = 300, method = "REP",
      alliance = "Reputation Vendor: Lokhtos Darkbargainer (Grim Guzzler, Blackrock Depths - Thorium Brotherhood Friendly)",
      horde    = "Reputation Vendor: Lokhtos Darkbargainer (Grim Guzzler, Blackrock Depths - Thorium Brotherhood Friendly)" },
    { match = "elixir of shadow power", prof = "Alchemy", rank = 250, method = "VENDOR",
      alliance = "Vendor: Maria Lumere (The Canals, Stormwind)",
      horde    = "Vendor: Algernon (The Apothecarium, Undercity)" },
    { match = "elixir of demonslaying", prof = "Alchemy", rank = 250, method = "VENDOR",
      alliance = "Vendor: Nina Lightbrew (Nethergarde Keep, Blasted Lands)",
      horde    = "Vendor: Rartar (Stonard, Swamp of Sorrows)" },
    { match = "elixir of the mongoose", prof = "Alchemy", rank = 280, method = "DROP",
      alliance = "Drop: Jadefire Rogues (Felwood) & Legashi Rogues (Azshara)",
      horde    = "Drop: Jadefire Rogues (Felwood) & Legashi Rogues (Azshara)" },
    { match = "flask of the titans", prof = "Alchemy", rank = 300, method = "DROP",
      alliance = "Boss Drop: General Drakkisath (Upper Blackrock Spire) — Crafted at Alchemy Lab in Scholomance/BWL",
      horde    = "Boss Drop: General Drakkisath (Upper Blackrock Spire) — Crafted at Alchemy Lab in Scholomance/BWL" },
    { match = "flask of supreme power", prof = "Alchemy", rank = 300, method = "DROP",
      alliance = "Boss Drop: Ras Frostwhisper (Scholomance) — Crafted at Alchemy Lab in Scholomance/BWL",
      horde    = "Boss Drop: Ras Frostwhisper (Scholomance) — Crafted at Alchemy Lab in Scholomance/BWL" },
    { match = "flask of distilled wisdom", prof = "Alchemy", rank = 300, method = "DROP",
      alliance = "Boss Drop: Balnazzar (Stratholme Live) — Crafted at Alchemy Lab in Scholomance/BWL",
      horde    = "Boss Drop: Balnazzar (Stratholme Live) — Crafted at Alchemy Lab in Scholomance/BWL" },
    { match = "flask of chromatic resistance", prof = "Alchemy", rank = 300, method = "DROP",
      alliance = "Boss Drop: Gyth (Upper Blackrock Spire) — Crafted at Alchemy Lab in Scholomance/BWL",
      horde    = "Boss Drop: Gyth (Upper Blackrock Spire) — Crafted at Alchemy Lab in Scholomance/BWL" },
    { match = "restorative potion", prof = "Alchemy", rank = 210, method = "QUEST",
      alliance = "Quest: Badlands Reagent Run — Ghak Healtouch (Thelsamar, Loch Modan)",
      horde    = "Quest: Badlands Reagent Run — Jarkal Mossmeld (Kargath, Badlands)" },

    -- TAILORING PATTERNS (VENDORS, QUESTS, REPS & DROPS)
    { match = "runecloth bag", prof = "Tailoring", rank = 260, method = "VENDOR",
      alliance = "Vendor: Qia (Everlook, Winterspring)",
      horde    = "Vendor: Qia (Everlook, Winterspring)" },
    { match = "runecloth robe", prof = "Tailoring", rank = 255, method = "VENDOR",
      alliance = "Vendor: Qia (Everlook, Winterspring)",
      horde    = "Vendor: Qia (Everlook, Winterspring)" },
    { match = "runecloth cloak", prof = "Tailoring", rank = 265, method = "VENDOR",
      alliance = "Vendor: Qia (Everlook, Winterspring)",
      horde    = "Vendor: Qia (Everlook, Winterspring)" },
    { match = "runecloth boots", prof = "Tailoring", rank = 280, method = "VENDOR",
      alliance = "Vendor: Qia (Everlook, Winterspring - Limited Supply)",
      horde    = "Vendor: Qia (Everlook, Winterspring - Limited Supply)" },
    { match = "mooncloth", prof = "Tailoring", rank = 250, method = "VENDOR",
      alliance = "Vendor: Qia (Everlook, Winterspring)",
      horde    = "Vendor: Qia (Everlook, Winterspring)" },
    { match = "felcloth pants", prof = "Tailoring", rank = 275, method = "VENDOR",
      alliance = "Vendor: Lorelae Wintersong (Nighthaven, Moonglade)",
      horde    = "Vendor: Lorelae Wintersong (Nighthaven, Moonglade)" },
    { match = "brightcloth cloak", prof = "Tailoring", rank = 275, method = "VENDOR",
      alliance = "Vendor: Lorelae Wintersong (Nighthaven, Moonglade)",
      horde    = "Vendor: Lorelae Wintersong (Nighthaven, Moonglade)" },
    { match = "cindercloth vest", prof = "Tailoring", rank = 260, method = "DROP",
      alliance = "Drop: Thaurissan Firewalkers (Burning Steppes)",
      horde    = "Drop: Thaurissan Firewalkers (Burning Steppes)" },
    { match = "shadoweave", prof = "Tailoring", rank = 215, method = "VENDOR",
      alliance = "Vendor: Zarena Cromwind (Booty Bay, Stranglethorn Vale) or Master Shadoweave Tailor in Undercity",
      horde    = "Trainer: Jalane Ayrole <Master Shadoweave Tailor> (The Apothecarium, Undercity)" },
    { match = "bloodvine", prof = "Tailoring", rank = 300, method = "REP",
      alliance = "Reputation Vendor: Rin'wosho the Trader (Yojamba Isle, Stranglethorn Vale - Zandalar Tribe Friendly/Honored/Revered)",
      horde    = "Reputation Vendor: Rin'wosho the Trader (Yojamba Isle, Stranglethorn Vale - Zandalar Tribe Friendly/Honored/Revered)" },
    { match = "flarecore", prof = "Tailoring", rank = 300, method = "REP",
      alliance = "Reputation Vendor: Lokhtos Darkbargainer (Grim Guzzler, Blackrock Depths - Thorium Brotherhood Friendly/Honored/Revered)",
      horde    = "Reputation Vendor: Lokhtos Darkbargainer (Grim Guzzler, Blackrock Depths - Thorium Brotherhood Friendly/Honored/Revered)" },
    { match = "wisdom of the timbermaw", prof = "Tailoring", rank = 290, method = "REP",
      alliance = "Reputation Vendor: Meilosh (Timbermaw Hold, Felwood - Timbermaw Hold Friendly)",
      horde    = "Reputation Vendor: Meilosh (Timbermaw Hold, Felwood - Timbermaw Hold Friendly)" },
    { match = "mantle of the timbermaw", prof = "Tailoring", rank = 300, method = "REP",
      alliance = "Reputation Vendor: Meilosh (Timbermaw Hold, Felwood - Timbermaw Hold Revered)",
      horde    = "Reputation Vendor: Meilosh (Timbermaw Hold, Felwood - Timbermaw Hold Revered)" },
    { match = "argent boots", prof = "Tailoring", rank = 290, method = "REP",
      alliance = "Reputation Vendor: Quartermaster Miranda Breechlock (Light's Hope Chapel, EPL - Argent Dawn Honored)",
      horde    = "Reputation Vendor: Quartermaster Miranda Breechlock (Light's Hope Chapel, EPL - Argent Dawn Honored)" },
    { match = "argent shoulders", prof = "Tailoring", rank = 300, method = "REP",
      alliance = "Reputation Vendor: Quartermaster Miranda Breechlock (Light's Hope Chapel, EPL - Argent Dawn Revered)",
      horde    = "Reputation Vendor: Quartermaster Miranda Breechlock (Light's Hope Chapel, EPL - Argent Dawn Revered)" },
    { match = "robe of the archmage", prof = "Tailoring", rank = 300, method = "DROP",
      alliance = "Boss Drop: Pyromancer Loregrain (Blackrock Depths)",
      horde    = "Boss Drop: Pyromancer Loregrain (Blackrock Depths)" },
    { match = "truefaith vestments", prof = "Tailoring", rank = 300, method = "DROP",
      alliance = "Boss Drop: Balnazzar (Stratholme Live - Scarlet Bastion)",
      horde    = "Boss Drop: Balnazzar (Stratholme Live - Scarlet Bastion)" },
    { match = "robe of the void", prof = "Tailoring", rank = 300, method = "DROP",
      alliance = "Boss Drop: Darkmaster Gandling (Scholomance)",
      horde    = "Boss Drop: Darkmaster Gandling (Scholomance)" },

    -- ENCHANTING FORMULAS (VENDORS, REPS & DROPS)
    { match = "enchant weapon - crusader", prof = "Enchanting", rank = 300, method = "DROP",
      alliance = "Drop: Scarlet Spellbinders (Tyr's Hand, Eastern Plaguelands) & Scarlet Archmages (Western Plaguelands)",
      horde    = "Drop: Scarlet Spellbinders (Tyr's Hand, Eastern Plaguelands) & Scarlet Archmages (Western Plaguelands)" },
    { match = "enchant weapon - fiery weapon", prof = "Enchanting", rank = 265, method = "DROP",
      alliance = "Boss Drop: Pyromancer Loregrain (Blackrock Depths)",
      horde    = "Boss Drop: Pyromancer Loregrain (Blackrock Depths)" },
    { match = "enchant weapon - icy chill", prof = "Enchanting", rank = 285, method = "DROP",
      alliance = "Drop: Anguished Highborne (Lake Kel'Theril, Winterspring)",
      horde    = "Drop: Anguished Highborne (Lake Kel'Theril, Winterspring)" },
    { match = "enchant weapon - lifestealing", prof = "Enchanting", rank = 300, method = "DROP",
      alliance = "Drop: Spectral Researchers (Scholomance)",
      horde    = "Drop: Spectral Researchers (Scholomance)" },
    { match = "enchant weapon - spell power", prof = "Enchanting", rank = 300, method = "DROP",
      alliance = "Raid Boss Drop: Molten Core Bosses (Lucifron, Gehennas, Shazzrah, Baron Geddon)",
      horde    = "Raid Boss Drop: Molten Core Bosses (Lucifron, Gehennas, Shazzrah, Baron Geddon)" },
    { match = "enchant weapon - healing power", prof = "Enchanting", rank = 300, method = "DROP",
      alliance = "Raid Boss Drop: Molten Core Bosses (Lucifron, Gehennas, Shazzrah, Sulfuron)",
      horde    = "Raid Boss Drop: Molten Core Bosses (Lucifron, Gehennas, Shazzrah, Sulfuron)" },
    { match = "enchant weapon - agility", prof = "Enchanting", rank = 290, method = "REP",
      alliance = "Reputation Vendor: Meilosh (Timbermaw Hold, Felwood - Timbermaw Hold Honored)",
      horde    = "Reputation Vendor: Meilosh (Timbermaw Hold, Felwood - Timbermaw Hold Honored)" },
    { match = "enchant 2h weapon - agility", prof = "Enchanting", rank = 290, method = "REP",
      alliance = "Reputation Vendor: Meilosh (Timbermaw Hold, Felwood - Timbermaw Hold Friendly)",
      horde    = "Reputation Vendor: Meilosh (Timbermaw Hold, Felwood - Timbermaw Hold Friendly)" },
    { match = "enchant weapon - strength", prof = "Enchanting", rank = 290, method = "REP",
      alliance = "Reputation Vendor: Lokhtos Darkbargainer (Grim Guzzler, Blackrock Depths - Thorium Brotherhood Friendly)",
      horde    = "Reputation Vendor: Lokhtos Darkbargainer (Grim Guzzler, Blackrock Depths - Thorium Brotherhood Friendly)" },
    { match = "enchant weapon - mighty intellect", prof = "Enchanting", rank = 300, method = "REP",
      alliance = "Reputation Vendor: Lokhtos Darkbargainer (Grim Guzzler, Blackrock Depths - Thorium Brotherhood Revered)",
      horde    = "Reputation Vendor: Lokhtos Darkbargainer (Grim Guzzler, Blackrock Depths - Thorium Brotherhood Revered)" },
    { match = "enchant weapon - mighty spirit", prof = "Enchanting", rank = 300, method = "REP",
      alliance = "Reputation Vendor: Lokhtos Darkbargainer (Grim Guzzler, Blackrock Depths - Thorium Brotherhood Honored)",
      horde    = "Reputation Vendor: Lokhtos Darkbargainer (Grim Guzzler, Blackrock Depths - Thorium Brotherhood Honored)" },
    { match = "enchant chest - greater stats", prof = "Enchanting", rank = 300, method = "DROP",
      alliance = "World / Raid Drop (Lvl 57-63 Elite Mobs & Raid Bosses)",
      horde    = "World / Raid Drop (Lvl 57-63 Elite Mobs & Raid Bosses)" },
    { match = "enchant chest - major mana", prof = "Enchanting", rank = 290, method = "DROP",
      alliance = "Drop: Crimson Conjurers (Stratholme Live - Scarlet Bastion)",
      horde    = "Drop: Crimson Conjurers (Stratholme Live - Scarlet Bastion)" },
    { match = "enchant chest - major health", prof = "Enchanting", rank = 275, method = "VENDOR",
      alliance = "Vendor: Qia (Everlook, Winterspring)",
      horde    = "Vendor: Qia (Everlook, Winterspring)" },
    { match = "enchant bracer - superior stamina", prof = "Enchanting", rank = 300, method = "DROP",
      alliance = "World Drop (Lvl 50-60 Mobs across Azeroth)",
      horde    = "World Drop (Lvl 50-60 Mobs across Azeroth)" },
    { match = "enchant bracer - healing power", prof = "Enchanting", rank = 300, method = "REP",
      alliance = "Reputation Vendor: Quartermaster Miranda Breechlock (Light's Hope Chapel, EPL - Argent Dawn Revered)",
      horde    = "Reputation Vendor: Quartermaster Miranda Breechlock (Light's Hope Chapel, EPL - Argent Dawn Revered)" },
    { match = "enchant bracer - mana regeneration", prof = "Enchanting", rank = 290, method = "REP",
      alliance = "Reputation Vendor: Quartermaster Miranda Breechlock (Light's Hope Chapel, EPL - Argent Dawn Honored)",
      horde    = "Reputation Vendor: Quartermaster Miranda Breechlock (Light's Hope Chapel, EPL - Argent Dawn Honored)" },
    { match = "runed arcanite rod", prof = "Enchanting", rank = 290, method = "VENDOR",
      alliance = "Vendor: Lorelae Wintersong (Nighthaven, Moonglade)",
      horde    = "Vendor: Lorelae Wintersong (Nighthaven, Moonglade)" },
    { match = "brilliant wizard oil", prof = "Enchanting", rank = 300, method = "REP",
      alliance = "Reputation Vendor: Rin'wosho the Trader (Yojamba Isle, STV - Zandalar Tribe Honored)",
      horde    = "Reputation Vendor: Rin'wosho the Trader (Yojamba Isle, STV - Zandalar Tribe Honored)" },
    { match = "brilliant mana oil", prof = "Enchanting", rank = 300, method = "REP",
      alliance = "Reputation Vendor: Rin'wosho the Trader (Yojamba Isle, STV - Zandalar Tribe Friendly)",
      horde    = "Reputation Vendor: Rin'wosho the Trader (Yojamba Isle, STV - Zandalar Tribe Friendly)" },

    -- BLACKSMITHING PLANS (QUESTS, VENDORS, REPS & DROPS)
    { match = "imperial plate", prof = "Blacksmithing", rank = 265, method = "QUEST",
      alliance = "Quest: Derotain Mudsipper (Gadgetzan, Tanaris - Bring Thorium Bars to learn each Imperial Plate piece)",
      horde    = "Quest: Derotain Mudsipper (Gadgetzan, Tanaris - Bring Thorium Bars to learn each Imperial Plate piece)" },
    { match = "ornate mithril", prof = "Blacksmithing", rank = 220, method = "QUEST",
      alliance = "Quest Chain: The Mithril Order — McGavan (Booty Bay) -> Galvan the Ancient (STV) -> Trenton Lighthammer (Gadgetzan)",
      horde    = "Quest Chain: The Mithril Order — McGavan (Booty Bay) -> Galvan the Ancient (STV) -> Trenton Lighthammer (Gadgetzan)" },
    { match = "dark iron", prof = "Blacksmithing", rank = 275, method = "REP",
      alliance = "Vendor / Rep: Lokhtos Darkbargainer or Plugger Spazzring / Ribbly Screwspigot (Grim Guzzler, Blackrock Depths - Thorium Brotherhood)",
      horde    = "Vendor / Rep: Lokhtos Darkbargainer or Plugger Spazzring / Ribbly Screwspigot (Grim Guzzler, Blackrock Depths - Thorium Brotherhood)" },
    { match = "fiery chain", prof = "Blacksmithing", rank = 295, method = "REP",
      alliance = "Reputation Vendor: Lokhtos Darkbargainer (Grim Guzzler, Blackrock Depths - Thorium Brotherhood Honored/Revered)",
      horde    = "Reputation Vendor: Lokhtos Darkbargainer (Grim Guzzler, Blackrock Depths - Thorium Brotherhood Honored/Revered)" },
    { match = "sulfuron hammer", prof = "Blacksmithing", rank = 300, method = "QUEST",
      alliance = "Quest: A Binding Contract — Lokhtos Darkbargainer (Grim Guzzler, Blackrock Depths - Turn in 1x Sulfuron Ingot)",
      horde    = "Quest: A Binding Contract — Lokhtos Darkbargainer (Grim Guzzler, Blackrock Depths - Turn in 1x Sulfuron Ingot)" },
    { match = "lionheart helm", prof = "Blacksmithing", rank = 300, method = "DROP",
      alliance = "World / Raid Drop (Lvl 58-63 Elite Mobs & Raid Bosses)",
      horde    = "World / Raid Drop (Lvl 58-63 Elite Mobs & Raid Bosses)" },
    { match = "stronghold gauntlets", prof = "Blacksmithing", rank = 300, method = "DROP",
      alliance = "World / Raid Drop (Lvl 57-63 Elite Mobs & Raid Bosses)",
      horde    = "World / Raid Drop (Lvl 57-63 Elite Mobs & Raid Bosses)" },
    { match = "titanic leggings", prof = "Blacksmithing", rank = 300, method = "DROP",
      alliance = "World / Raid Drop (Lvl 58-63 Elite Mobs & Raid Bosses)",
      horde    = "World / Raid Drop (Lvl 58-63 Elite Mobs & Raid Bosses)" },
    { match = "elemental sharpening stone", prof = "Blacksmithing", rank = 300, method = "DROP",
      alliance = "Raid Boss Drop: Molten Core Bosses",
      horde    = "Raid Boss Drop: Molten Core Bosses" },
    { match = "arcanite reaper", prof = "Blacksmithing", rank = 300, method = "DROP",
      alliance = "Boss Drop: Bannok Grimaxe (Lower Blackrock Spire)",
      horde    = "Boss Drop: Bannok Grimaxe (Lower Blackrock Spire)" },
    { match = "heartseeker", prof = "Blacksmithing", rank = 300, method = "DROP",
      alliance = "Boss Drop: Cannon Master Willey (Stratholme Live)",
      horde    = "Boss Drop: Cannon Master Willey (Stratholme Live)" },
    { match = "annihilator", prof = "Blacksmithing", rank = 300, method = "DROP",
      alliance = "Boss Drop: Quartermaster Zigris (Lower Blackrock Spire)",
      horde    = "Boss Drop: Quartermaster Zigris (Lower Blackrock Spire)" },

    -- LEATHERWORKING PATTERNS (QUESTS, VENDORS, REPS & DROPS)
    { match = "wild leather", prof = "Leatherworking", rank = 225, method = "QUEST",
      alliance = "Quest Chain: Wild Leather Armor — Pratt McGrubben (Feathermoon Stronghold, Feralas)",
      horde    = "Quest Chain: Wild Leather Armor — Jangdor Swiftstrider (Camp Mojache, Feralas)" },
    { match = "devilsaur gauntlets", prof = "Leatherworking", rank = 290, method = "VENDOR",
      alliance = "Vendor: Nergal (Marshal's Refuge, Un'Goro Crater)",
      horde    = "Vendor: Nergal (Marshal's Refuge, Un'Goro Crater)" },
    { match = "devilsaur leggings", prof = "Leatherworking", rank = 300, method = "DROP",
      alliance = "Drop: Cloning / Muculent / Primal / Glutinous Oozes (Un'Goro Crater)",
      horde    = "Drop: Cloning / Muculent / Primal / Glutinous Oozes (Un'Goro Crater)" },
    { match = "black dragonscale", prof = "Leatherworking", rank = 290, method = "VENDOR",
      alliance = "Vendor / Drop: Plugger Spazzring (Grim Guzzler, Blackrock Depths) & Anvilrage Captains/Marshals in BRD",
      horde    = "Vendor / Drop: Plugger Spazzring (Grim Guzzler, Blackrock Depths) & Anvilrage Captains/Marshals in BRD" },
    { match = "corehound", prof = "Leatherworking", rank = 295, method = "REP",
      alliance = "Reputation Vendor: Lokhtos Darkbargainer (Grim Guzzler, Blackrock Depths - Thorium Brotherhood Friendly/Revered)",
      horde    = "Reputation Vendor: Lokhtos Darkbargainer (Grim Guzzler, Blackrock Depths - Thorium Brotherhood Friendly/Revered)" },
    { match = "chromatic gauntlets", prof = "Leatherworking", rank = 300, method = "REP",
      alliance = "Reputation Vendor: Lokhtos Darkbargainer (Grim Guzzler, Blackrock Depths - Thorium Brotherhood Exalted)",
      horde    = "Reputation Vendor: Lokhtos Darkbargainer (Grim Guzzler, Blackrock Depths - Thorium Brotherhood Exalted)" },
    { match = "hide of the wild", prof = "Leatherworking", rank = 300, method = "DROP",
      alliance = "Drop: Knot Thimblejack's Cache (Dire Maul North Tribute Run)",
      horde    = "Drop: Knot Thimblejack's Cache (Dire Maul North Tribute Run)" },
    { match = "shifting cloak", prof = "Leatherworking", rank = 300, method = "DROP",
      alliance = "Drop: Knot Thimblejack's Cache (Dire Maul North Tribute Run)",
      horde    = "Drop: Knot Thimblejack's Cache (Dire Maul North Tribute Run)" },
    { match = "warbear", prof = "Leatherworking", rank = 275, method = "REP",
      alliance = "Reputation Vendor: Meilosh (Timbermaw Hold, Felwood - Timbermaw Hold Friendly)",
      horde    = "Reputation Vendor: Meilosh (Timbermaw Hold, Felwood - Timbermaw Hold Friendly)" },
    { match = "might of the timbermaw", prof = "Leatherworking", rank = 290, method = "REP",
      alliance = "Reputation Vendor: Meilosh (Timbermaw Hold, Felwood - Timbermaw Hold Honored)",
      horde    = "Reputation Vendor: Meilosh (Timbermaw Hold, Felwood - Timbermaw Hold Honored)" },
    { match = "timbermaw brawlers", prof = "Leatherworking", rank = 300, method = "REP",
      alliance = "Reputation Vendor: Meilosh (Timbermaw Hold, Felwood - Timbermaw Hold Revered)",
      horde    = "Reputation Vendor: Meilosh (Timbermaw Hold, Felwood - Timbermaw Hold Revered)" },
    { match = "primal batskin", prof = "Leatherworking", rank = 300, method = "REP",
      alliance = "Reputation Vendor: Rin'wosho the Trader (Yojamba Isle, STV - Zandalar Tribe Friendly/Honored/Revered)",
      horde    = "Reputation Vendor: Rin'wosho the Trader (Yojamba Isle, STV - Zandalar Tribe Friendly/Honored/Revered)" },
    { match = "blood tiger", prof = "Leatherworking", rank = 300, method = "REP",
      alliance = "Reputation Vendor: Rin'wosho the Trader (Yojamba Isle, STV - Zandalar Tribe Revered/Exalted)",
      horde    = "Reputation Vendor: Rin'wosho the Trader (Yojamba Isle, STV - Zandalar Tribe Revered/Exalted)" },

    -- ENGINEERING SCHEMATICS (VENDORS, QUESTS & DROPS)
    { match = "goblin jumper cables xl", prof = "Engineering", rank = 265, method = "VENDOR",
      alliance = "Boss Drop / Vendor: Plugger Spazzring (Grim Guzzler Bar, Blackrock Depths)",
      horde    = "Boss Drop / Vendor: Plugger Spazzring (Grim Guzzler Bar, Blackrock Depths)" },
    { match = "goblin jumper cables", prof = "Engineering", rank = 165, method = "VENDOR",
      alliance = "Vendor: Gearcutter Cogspinner (Tinker Town, Ironforge) or Xizzer Fizzbolt (Everlook)",
      horde    = "Vendor: Sovik (The Drag, Orgrimmar) or Gagsprocket (Ratchet)" },
    { match = "delicate arcanite converter", prof = "Engineering", rank = 285, method = "VENDOR",
      alliance = "Vendor: Xizzer Fizzbolt (Everlook, Winterspring)",
      horde    = "Vendor: Xizzer Fizzbolt (Everlook, Winterspring)" },
    { match = "gyrofreeze ice reflector", prof = "Engineering", rank = 260, method = "VENDOR",
      alliance = "Vendor: Xizzer Fizzbolt (Everlook, Winterspring)",
      horde    = "Vendor: Xizzer Fizzbolt (Everlook, Winterspring)" },
    { match = "hyper-radiant flame reflector", prof = "Engineering", rank = 290, method = "DROP",
      alliance = "Boss Drop: Solakar Flamewreath (Upper Blackrock Spire)",
      horde    = "Boss Drop: Solakar Flamewreath (Upper Blackrock Spire)" },
    { match = "ultra-flash shadow reflector", prof = "Engineering", rank = 300, method = "DROP",
      alliance = "Drop: Crimson Inquisitors (Stratholme Live - Scarlet Bastion)",
      horde    = "Drop: Crimson Inquisitors (Stratholme Live - Scarlet Bastion)" },
    { match = "field repair bot 74a", prof = "Engineering", rank = 300, method = "QUEST",
      alliance = "World Blueprint Object: Schematic on the floor next to Golem Lord Argelmach (Blackrock Depths)",
      horde    = "World Blueprint Object: Schematic on the floor next to Golem Lord Argelmach (Blackrock Depths)" },
    { match = "force reactive disk", prof = "Engineering", rank = 300, method = "DROP",
      alliance = "Raid Boss Drop: Molten Core Bosses",
      horde    = "Raid Boss Drop: Molten Core Bosses" },
    { match = "biznicks 247x128 accurascope", prof = "Engineering", rank = 300, method = "DROP",
      alliance = "Raid Boss Drop: Molten Core Bosses",
      horde    = "Raid Boss Drop: Molten Core Bosses" },
    { match = "core marksman rifle", prof = "Engineering", rank = 300, method = "DROP",
      alliance = "Raid Boss Drop: Molten Core Bosses",
      horde    = "Raid Boss Drop: Molten Core Bosses" },

    -- COOKING RECIPES (QUESTS & VENDORS)
    { match = "savory deviate delight", prof = "Cooking", rank = 85, method = "DROP",
      alliance = "Drop: Barrens Mobs (Razormane, Kolkar, Venture Co., Southsea Pirates in Northern Barrens)",
      horde    = "Drop: Barrens Mobs (Razormane, Kolkar, Venture Co., Southsea Pirates in Northern Barrens)" },
    { match = "thistle tea", prof = "Cooking", rank = 60, method = "QUEST",
      alliance = "Rogue Quest: Klaven's Tower — Mathias Shaw (SI:7, Stormwind) or Sold by Smudge Thunderwood (Ravenholdt)",
      horde    = "Rogue Quest: Mission: Possible But Not Probable — Shenthul (Cleft of Shadow, Orgrimmar) or Smudge Thunderwood" },
    { match = "nightfin soup", prof = "Cooking", rank = 250, method = "VENDOR",
      alliance = "Vendor: Himmik (Everlook Inn, Winterspring)",
      horde    = "Vendor: Himmik (Everlook Inn, Winterspring)" },
    { match = "grilled squid", prof = "Cooking", rank = 240, method = "VENDOR",
      alliance = "Vendor: Himmik (Everlook Inn, Winterspring)",
      horde    = "Vendor: Himmik (Everlook Inn, Winterspring)" },
    { match = "smoked desert dumplings", prof = "Cooking", rank = 285, method = "QUEST",
      alliance = "Quest Chain: Desert Recipe -> Sharing the Knowledge -> Kitchen Assistance — Calandrath (Cenarion Hold, Silithus)",
      horde    = "Quest Chain: Desert Recipe -> Sharing the Knowledge -> Kitchen Assistance — Calandrath (Cenarion Hold, Silithus)" },
    { match = "dirge's kickin' chimaerok chops", prof = "Cooking", rank = 300, method = "QUEST",
      alliance = "AQ Opening Quest: Dirge's Kickin' Chimaerok Chops — Dirge Quikcleave (Gadgetzan, Tanaris)",
      horde    = "AQ Opening Quest: Dirge's Kickin' Chimaerok Chops — Dirge Quikcleave (Gadgetzan, Tanaris)" },
    { match = "runn tum tuber surprise", prof = "Cooking", rank = 275, method = "DROP",
      alliance = "Boss Drop: Pusillin (Dire Maul East)",
      horde    = "Boss Drop: Pusillin (Dire Maul East)" },
    { match = "monster omelet", prof = "Cooking", rank = 225, method = "VENDOR",
      alliance = "Vendor: Himmik (Everlook, Winterspring) or Malygen (Talonbranch Glade, Felwood)",
      horde    = "Vendor: Himmik (Everlook, Winterspring) or Bale (Bloodvenom Post, Felwood)" },
    { match = "tender wolf steak", prof = "Cooking", rank = 225, method = "VENDOR",
      alliance = "Vendor: Dirge Quikcleave (Gadgetzan, Tanaris)",
      horde    = "Vendor: Dirge Quikcleave (Gadgetzan, Tanaris)" },
    { match = "westfall stew", prof = "Cooking", rank = 75, method = "QUEST",
      alliance = "Quest: Westfall Stew — Salma Saldean (Saldean's Farm, Westfall)",
      horde    = "Vendor: Sold on Neutral Auction House (Quest from Salma Saldean in Westfall)" },
    { match = "dig rat stew", prof = "Cooking", rank = 90, method = "QUEST",
      alliance = "Horde Quest: Dig Rat Stew — Grub (Southern Barrens)",
      horde    = "Quest: Dig Rat Stew — Grub (Bael Modan Digsite, Southern Barrens)" },
}

-- ============================================================================
-- BLOCK HEADING: LIVE IN-GAME QUEST REWARD & VENDOR AUTO-RECORDER
-- ============================================================================
local QuestRecorderFrame = CreateFrame("Frame")
QuestRecorderFrame:RegisterEvent("QUEST_DETAIL")
QuestRecorderFrame:RegisterEvent("QUEST_COMPLETE")
QuestRecorderFrame:SetScript("OnEvent", function(_, event)
    if not AltVaultDB then return end
    AltVaultDB.SourceDB = AltVaultDB.SourceDB or {}

    local questTitle = (GetTitleText and GetTitleText()) or "Quest"
    local npcName = UnitName("npc") or UnitName("target") or "Quest Giver"
    local zoneName = (GetRealZoneText and GetRealZoneText()) or (GetZoneText and GetZoneText()) or "Azeroth"
    local fac = UnitFactionGroup("player") or "Alliance"
    local facKey = (fac == "Horde") and "horde" or "alliance"

    local function RecordQuestItemLink(link)
        if not link or not ns.Scanner then return end
        local itemID = ns.Scanner.ExtractItemID and ns.Scanner.ExtractItemID(link)
        if not itemID then return end
        ns.Scanner.CacheItemData(link, false)

        local detail = string.format("Quest: %s — %s (%s)", questTitle, npcName, zoneName)
        AltVaultDB.SourceDB[itemID] = AltVaultDB.SourceDB[itemID] or {}
        AltVaultDB.SourceDB[itemID][facKey] = string.format("%s: %s", fac, detail)

        if ns.MasterDB and ns.MasterDB.UpsertLiveRecord then
            local name = C_Item and C_Item.GetItemNameByID and C_Item.GetItemNameByID(itemID) or ""
            ns.MasterDB:UpsertLiveRecord("Item", itemID, name, "Quests", zoneName, "Quest: " .. questTitle, npcName, fac, "", "", "LiveQuestScan")
        end
    end

    local numChoices = (GetNumQuestChoices and GetNumQuestChoices()) or 0
    for i = 1, numChoices do
        local link = GetQuestItemLink and GetQuestItemLink("choice", i)
        if link then RecordQuestItemLink(link) end
    end

    local numRewards = (GetNumQuestRewards and GetNumQuestRewards()) or 0
    for i = 1, numRewards do
        local link = GetQuestItemLink and GetQuestItemLink("reward", i)
        if link then RecordQuestItemLink(link) end
    end
end)

-- ============================================================================
-- BLOCK HEADING: DUAL-FACTION ACQUISITION RESOLVERS (ITEMS & RECIPES)
-- ============================================================================
function AcquisitionDB:ResolveTrainerByProfAndRank(profName, reqRank)
    local pAtlas = PROF_TRAINER_ATLAS[profName or ""]
    local rank = tonumber(reqRank) or 1
    if not pAtlas then
        local tier = (rank >= 225 and "Artisan Trainer") or (rank >= 150 and "Expert Trainer") or "Profession Trainer"
        return string.format("Trainer (%s %d): %s in Stormwind / Ironforge / Darnassus", profName or "Profession", rank, tier),
               string.format("Trainer (%s %d): %s in Orgrimmar / Undercity / Thunder Bluff", profName or "Profession", rank, tier)
    end
    local bracket = (rank >= 225 and pAtlas.artisan) or (rank >= 150 and pAtlas.expert) or pAtlas.apprentice
    return bracket.alliance, bracket.horde
end

function AcquisitionDB:ResolveRecipeDualFaction(recipeName, profName, reqRank, patternItemID, masterRecords)
    local nameLow = string.lower(tostring(recipeName or ""))
    -- Strip "/ 225" suffix if present in MasterDB Spell names
    local cleanLow = string.gsub(nameLow, "%s*/%s*%d+.*$", "")
    cleanLow = string.gsub(cleanLow, "^recipe:%s*", "")
    cleanLow = string.gsub(cleanLow, "^pattern:%s*", "")
    cleanLow = string.gsub(cleanLow, "^plans:%s*", "")
    cleanLow = string.gsub(cleanLow, "^schematic:%s*", "")
    cleanLow = string.gsub(cleanLow, "^formula:%s*", "")

    -- 1. Check Curated Dual-Faction Recipe Vendor/Quest/Rep/Drop Atlas
    for _, entry in ipairs(CURATED_RECIPE_SOURCES) do
        if string.find(cleanLow, entry.match, 1, true) then
            return entry.method, entry.alliance, entry.horde, entry.rank or reqRank, entry.prof or profName
        end
    end

    -- 2. Check Live SourceDB if patternItemID was scanned at a Vendor, Trainer, or Quest
    if patternItemID and AltVaultDB and AltVaultDB.SourceDB and AltVaultDB.SourceDB[patternItemID] then
        local s = AltVaultDB.SourceDB[patternItemID]
        local ally = s.alliance or s.both
        local horde = s.horde or s.both
        if ally or horde then
            local m = "VENDOR"
            local checkStr = string.lower((ally or "") .. " " .. (horde or ""))
            if string.find(checkStr, "quest") then m = "QUEST"
            elseif string.find(checkStr, "taught") or string.find(checkStr, "trainer") then m = "TRAINER"
            elseif string.find(checkStr, "drop") then m = "DROP"
            end
            local defA, defH = self:ResolveTrainerByProfAndRank(profName, reqRank)
            return m, ally or defA, horde or defH, reqRank, profName
        end
    end

    -- 3. Check MasterDB Records if patternItemID or spell has Dungeon/Boss/Vendor records
    if masterRecords and #masterRecords > 0 then
        for _, r in ipairs(masterRecords) do
            if r.ContentType == "Dungeons" or r.ContentType == "Raids" then
                local loc = string.format("Dungeon/Raid Drop: %s — %s",
                    r.Category ~= "" and r.Category or r.ModuleKey,
                    r.BossOrHeader ~= "" and r.BossOrHeader or r.SubSection)
                return "DROP", loc, loc, reqRank, profName
            elseif r.ContentType == "World_Events" then
                local atlas = CATEGORY_FACTION_ATLAS[r.Category] or CATEGORY_FACTION_ATLAS[r.ModuleKey]
                if atlas then
                    local cost = (r.PriceOrCost ~= "" and ns.MasterDB) and (" [Cost: " .. ns.MasterDB:FormatPriceString(r.PriceOrCost) .. "]") or ""
                    return atlas.method, atlas.alliance .. cost, atlas.horde .. cost, reqRank, profName
                end
            end
        end
    end

    -- 4. Default to Dual-Faction Trainer / Vendor Resolution by Profession & Skill Rank
    local allyTrainer, hordeTrainer = self:ResolveTrainerByProfAndRank(profName, reqRank)
    local method = "TRAINER"
    if (profName == "Cooking" or profName == "First Aid") and (tonumber(reqRank) or 1) >= 225 then
        method = "QUEST"
    elseif (profName == "Cooking" or profName == "First Aid") and (tonumber(reqRank) or 1) >= 125 then
        method = "VENDOR"
    end
    return method, allyTrainer, hordeTrainer, reqRank, profName
end

function AcquisitionDB:GetItemDualFactionSummary(itemID, itemName)
    if not itemID then return nil, nil, "ALL" end

    -- 1. Check Curated Quest & Iconic Item Encyclopedia
    local curated = CURATED_ITEMS_BY_ID[itemID]
    if curated then
        return curated.alliance, curated.horde, curated.method or "QUEST"
    end

    local allianceLines = {}
    local hordeLines = {}
    local primaryMethod = nil

    -- 2. Check Live SourceDB (recorded from Quests, Vendors, Trainers, or Boss Loot)
    if AltVaultDB and AltVaultDB.SourceDB and AltVaultDB.SourceDB[itemID] then
        local src = AltVaultDB.SourceDB[itemID]
        if src.alliance then table.insert(allianceLines, src.alliance) end
        if src.horde then table.insert(hordeLines, src.horde) end
        if src.both then
            if #allianceLines == 0 then table.insert(allianceLines, src.both) end
            if #hordeLines == 0 then table.insert(hordeLines, src.both) end
        end
        local combined = string.lower((src.alliance or "") .. " " .. (src.horde or "") .. " " .. (src.both or ""))
        if string.find(combined, "quest") then primaryMethod = "QUEST"
        elseif string.find(combined, "sold by") or string.find(combined, "vendor") then primaryMethod = "VENDOR"
        elseif string.find(combined, "drop") then primaryMethod = "BOSS"
        elseif string.find(combined, "craft") then primaryMethod = "CRAFT"
        end
    end

    -- 3. Check MasterDB Holding Tank Records
    local records = (ns.MasterDB and ns.MasterDB.GetItemSources and ns.MasterDB:GetItemSources(itemID)) or {}
    for _, r in ipairs(records) do
        local cat = (r.Category ~= "" and r.Category) or r.ModuleKey or "Source"
        local sub = CleanStandingTag(r.SubSection or "")
        local boss = CleanStandingTag(r.BossOrHeader or "")
        local cost = (r.PriceOrCost ~= "" and ns.MasterDB and ns.MasterDB.FormatPriceString)
            and (" [Cost: " .. ns.MasterDB:FormatPriceString(r.PriceOrCost) .. "]")
            or ""

        local atlas = CATEGORY_FACTION_ATLAS[cat] or CATEGORY_FACTION_ATLAS[r.ModuleKey] or CATEGORY_FACTION_ATLAS[sub]
        if atlas then
            primaryMethod = primaryMethod or atlas.method
            local extra = (boss ~= "" and boss ~= sub and (" • " .. boss) or "") .. cost
            if r.Faction == "Alliance" then
                table.insert(allianceLines, atlas.alliance .. extra)
            elseif r.Faction == "Horde" then
                table.insert(hordeLines, atlas.horde .. extra)
            else
                table.insert(allianceLines, atlas.alliance .. extra)
                table.insert(hordeLines, atlas.horde .. extra)
            end
        elseif r.ContentType == "Quests" or string.find(string.lower(sub .. " " .. boss), "quest") then
            primaryMethod = primaryMethod or "QUEST"
            local qLine = string.format("Quest (%s): %s%s%s", cat, sub ~= "" and sub or "Quest Reward", boss ~= "" and (" — " .. boss) or "", cost)
            if r.Faction == "Alliance" then
                table.insert(allianceLines, qLine)
            elseif r.Faction == "Horde" then
                table.insert(hordeLines, qLine)
            else
                table.insert(allianceLines, qLine)
                table.insert(hordeLines, qLine)
            end
        elseif r.ContentType == "PvP" or r.ContentType == "Factions" then
            primaryMethod = primaryMethod or "REP"
            local repLine = string.format("Faction / PvP Quartermaster (%s): %s%s%s", cat, sub, boss ~= "" and (" • " .. boss) or "", cost)
            if r.Faction == "Alliance" then
                table.insert(allianceLines, repLine)
            elseif r.Faction == "Horde" then
                table.insert(hordeLines, repLine)
            else
                table.insert(allianceLines, repLine)
                table.insert(hordeLines, repLine)
            end
        elseif r.ContentType == "Dungeons" or r.ContentType == "Raids" then
            if string.find(string.lower(sub .. " " .. boss), "tier 0.5") or string.find(string.lower(sub .. " " .. boss), "heirloom") then
                primaryMethod = primaryMethod or "QUEST"
                local t05Ally = string.format("Dungeon Set 2 (Tier 0.5) Quest Chain: %s (%s) — Deliana in Ironforge", cat, boss ~= "" and boss or sub)
                local t05Horde = string.format("Dungeon Set 2 (Tier 0.5) Quest Chain: %s (%s) — Mokvar in Orgrimmar", cat, boss ~= "" and boss or sub)
                table.insert(allianceLines, t05Ally)
                table.insert(hordeLines, t05Horde)
            else
                primaryMethod = primaryMethod or "BOSS"
                local dLine = string.format("%s: %s%s", cat, sub ~= "" and sub or "Boss Drop", (boss ~= "" and boss ~= sub) and (" (" .. boss .. ")") or "")
                table.insert(allianceLines, dLine)
                table.insert(hordeLines, dLine)
            end
        elseif r.ContentType == "Collections" or r.ContentType == "World_Events" then
            if sub == "Quest" or sub == "Quest Item" then
                primaryMethod = primaryMethod or "QUEST"
            elseif sub == "Vendor" or cost ~= "" then
                primaryMethod = primaryMethod or "VENDOR"
            elseif sub == "Crafting" then
                primaryMethod = primaryMethod or "CRAFT"
            else
                primaryMethod = primaryMethod or "BOSS"
            end
            local cLine = string.format("%s (%s)%s", cat, sub ~= "" and sub or "Reward", cost)
            if r.Faction == "Alliance" then
                table.insert(allianceLines, cLine)
            elseif r.Faction == "Horde" then
                table.insert(hordeLines, cLine)
            else
                table.insert(allianceLines, cLine)
                table.insert(hordeLines, cLine)
            end
        elseif r.ContentType == "Professions" then
            primaryMethod = primaryMethod or "CRAFT"
            local pLine = string.format("Profession (%s): %s%s", cat, sub, boss ~= "" and (" • " .. boss) or "")
            table.insert(allianceLines, pLine)
            table.insert(hordeLines, pLine)
        end
    end

    -- 4. Check PatternDB / RecipeDB if item is a Recipe Pattern or Crafted Item
    local pat = AltVaultDB and AltVaultDB.PatternDB and AltVaultDB.PatternDB[itemID]
    if pat and pat.p then
        local m, aLine, hLine = self:ResolveRecipeDualFaction(itemName or pat.cn or "", pat.p, pat.s or 1, itemID, records)
        primaryMethod = primaryMethod or m
        if #allianceLines == 0 then table.insert(allianceLines, aLine) end
        if #hordeLines == 0 then table.insert(hordeLines, hLine) end
    end

    local rec = AltVaultDB and AltVaultDB.RecipeDB and AltVaultDB.RecipeDB[itemID]
    if rec and rec.prof then
        primaryMethod = primaryMethod or "CRAFT"
        local cLine = string.format("Crafted by %s (%d Skill)", rec.prof, rec.rank or 1)
        if #allianceLines == 0 then table.insert(allianceLines, cLine .. " — Alliance Trainers / Crafters") end
        if #hordeLines == 0 then table.insert(hordeLines, cLine .. " — Horde Trainers / Crafters") end
    end

    -- 5. Fallback heuristic from ItemCache metadata if no explicit record yet
    local cached = AltVaultDB and AltVaultDB.ItemCache and AltVaultDB.ItemCache[itemID]
    if (#allianceLines == 0 or #hordeLines == 0) and cached then
        local b = cached.b or 0
        local q = cached.q or 1
        local reqLvl = cached.r or 1
        local iLvl = cached.l or 1
        local bracket = (reqLvl >= 55 or iLvl >= 60) and "Lvl 55-60 Endgame Zones & Dungeons"
            or (reqLvl >= 40 or iLvl >= 42) and "Lvl 40-54 Mid-High Zones (Tanaris, Feralas, Hinterlands, Ungoro)"
            or (reqLvl >= 20 or iLvl >= 22) and "Lvl 20-39 Contested Zones (Duskwood, Ashenvale, Hillsbrad, STV)"
            or "Lvl 1-19 Starter Zones (Elwynn/Dun Morogh/Teldrassil • Durotar/Mulgore/Tirisfal)"

        if b == 4 or cached.c == 12 then
            primaryMethod = primaryMethod or "QUEST"
            if #allianceLines == 0 then table.insert(allianceLines, "Quest Objective / Reward (" .. bracket .. ")") end
            if #hordeLines == 0 then table.insert(hordeLines, "Quest Objective / Reward (" .. bracket .. ")") end
        elseif b == 1 and q == 2 then
            primaryMethod = primaryMethod or "QUEST"
            if #allianceLines == 0 then table.insert(allianceLines, "Alliance Quest Reward or Dungeon Drop [BoP] (" .. bracket .. ")") end
            if #hordeLines == 0 then table.insert(hordeLines, "Horde Quest Reward or Dungeon Drop [BoP] (" .. bracket .. ")") end
        elseif b == 1 and q >= 3 then
            primaryMethod = primaryMethod or "BOSS"
            if #allianceLines == 0 then table.insert(allianceLines, "Dungeon / Raid Boss Drop or Faction Quest Reward [BoP] (" .. bracket .. ")") end
            if #hordeLines == 0 then table.insert(hordeLines, "Dungeon / Raid Boss Drop or Faction Quest Reward [BoP] (" .. bracket .. ")") end
        else
            primaryMethod = primaryMethod or "CRAFT"
            if #allianceLines == 0 then table.insert(allianceLines, "Vendor, Crafted, or World Drop [BoE] (" .. bracket .. ")") end
            if #hordeLines == 0 then table.insert(hordeLines, "Vendor, Crafted, or World Drop [BoE] (" .. bracket .. ")") end
        end
    end

    if #allianceLines == 0 and #hordeLines > 0 then
        table.insert(allianceLines, "Horde-Only Acquisition (Not directly available to Alliance)")
    elseif #hordeLines == 0 and #allianceLines > 0 then
        table.insert(hordeLines, "Alliance-Only Acquisition (Not directly available to Horde)")
    end

    return allianceLines[1] or "Available in Classic / WoW Forever",
           hordeLines[1] or "Available in Classic / WoW Forever",
           primaryMethod or "ALL",
           allianceLines,
           hordeLines
end

-- ============================================================================
-- BLOCK HEADING: FILTER DEFINITIONS & UI STATE FOR BOTH NEW TABS
-- ============================================================================
local ITEM_SOURCE_FILTERS = {
    { label = "Source: All Sources",        token = "ALL"    },
    { label = "Source: Quest Rewards",      token = "QUEST"  },
    { label = "Source: Vendors & Reals",    token = "VENDOR" },
    { label = "Source: Factions & PvP",     token = "REP"    },
    { label = "Source: Dungeons & Raids",   token = "BOSS"   },
    { label = "Source: Crafted & World",    token = "CRAFT"  },
}

local ITEM_CATEGORY_FILTERS = {
    { label = "Type: All Gear & Items",     token = "ALL"      },
    { label = "Type: Weapons & Shields",    token = "WEAPON"   },
    { label = "Type: Plate Armor",          token = "Plate"    },
    { label = "Type: Mail Armor",           token = "Mail"     },
    { label = "Type: Leather Armor",        token = "Leather"  },
    { label = "Type: Cloth & Cloaks",       token = "Cloth"    },
    { label = "Type: Rings, Necks & Trinkets", token = "JEWELRY" },
    { label = "Type: Mounts, Pets & Tabards",  token = "COLLECT" },
    { label = "Type: Quest & Legendaries",  token = "QUEST_LEG" },
}

local RECIPE_METHOD_FILTERS = {
    { label = "Method: All Sources",        token = "ALL"     },
    { label = "Method: Vendor Recipes",     token = "VENDOR"  },
    { label = "Method: Quest Recipes",      token = "QUEST"   },
    { label = "Method: Trainer Recipes",    token = "TRAINER" },
    { label = "Method: Reputation Recipes", token = "REP"     },
    { label = "Method: Boss & World Drops", token = "DROP"    },
}

local RECIPE_PROF_FILTERS = {
    { label = "Prof: All Professions",      token = "ALL"            },
    { label = "Prof: Alchemy",              token = "Alchemy"        },
    { label = "Prof: Blacksmithing",        token = "Blacksmithing"  },
    { label = "Prof: Cooking",              token = "Cooking"        },
    { label = "Prof: Enchanting",           token = "Enchanting"     },
    { label = "Prof: Engineering",          token = "Engineering"    },
    { label = "Prof: First Aid",            token = "First Aid"      },
    { label = "Prof: Leatherworking",       token = "Leatherworking" },
    { label = "Prof: Mining & Smelting",    token = "Mining"         },
    { label = "Prof: Tailoring",            token = "Tailoring"      },
    { label = "Prof: Rogue Poisons",        token = "Rogue Poisons"  },
}

local FACTION_FILTERS = {
    { label = "Faction: Both (A + H)",      token = "BOTH"          },
    { label = "Faction: Alliance Paths",    token = "ALLIANCE"      },
    { label = "Faction: Horde Paths",       token = "HORDE"         },
    { label = "Faction: Alliance Only",     token = "ALLIANCE_ONLY" },
    { label = "Faction: Horde Only",        token = "HORDE_ONLY"    },
}

local acqState = {
    useGridView             = true,

    itemSearchText          = "",
    itemMinLvl              = nil,
    itemMaxLvl              = nil,
    itemAutoLevelDefault    = false,
    lastSeededItemCharKey   = nil,
    showItemFavoritesOnly   = false,
    itemSourceIdx           = 1,
    itemCatIdx              = 1,
    itemFactionIdx          = 1,
    itemPage                = 1,
    itemTotalPages          = 1,
    inspectedItemEntry      = nil,

    recipeSearchText        = "",
    recipeMinLvl            = nil,
    recipeMaxLvl            = nil,
    recipeAutoLevelDefault  = false,
    lastSeededRecipeCharKey = nil,
    showRecipeFavoritesOnly = false,
    recipeMethodIdx         = 1,
    recipeProfIdx           = 1,
    recipeFactionIdx        = 1,
    recipePage              = 1,
    recipeTotalPages        = 1,
    inspectedRecipeEntry    = nil,

    qualities = {
        [0] = true,
        [1] = true,
        [2] = true,
        [3] = true,
        [4] = true,
        [5] = true,
    },
}

local function SyncAcqAutoLevelDefault(mode)
    local curChar = (MainPanel.GetSelectedCharacter and MainPanel:GetSelectedCharacter()) or UnitName("player") or "Player"
    if mode == "QUEST_FOR_RECIPE" then
        if acqState.recipeAutoLevelDefault and acqState.lastSeededRecipeCharKey ~= curChar then
            acqState.lastSeededRecipeCharKey = curChar
            local minSkill, maxSkill = MainPanel:GetDefaultLevelBand(true)
            acqState.recipeMinLvl = minSkill
            acqState.recipeMaxLvl = maxSkill
        end
    else
        if acqState.itemAutoLevelDefault and acqState.lastSeededItemCharKey ~= curChar then
            acqState.lastSeededItemCharKey = curChar
            local minLv, maxLv = MainPanel:GetDefaultLevelBand(false)
            acqState.itemMinLvl = minLv
            acqState.itemMaxLvl = maxLv
        end
    end
end

-- ============================================================================
-- BLOCK HEADING: DEDICATED FLYOUT DROPDOWN MENU FOR QUEST TABS
-- ============================================================================
local AcqDropdownMenu = CreateBackdrop("Frame", "AltVaultQuestAcqDropdownMenu", UIParent)
AcqDropdownMenu:SetFrameStrata("TOOLTIP")
AcqDropdownMenu:SetFrameLevel(360)
AcqDropdownMenu:EnableMouse(true)
if AcqDropdownMenu.SetBackdrop then
    AcqDropdownMenu:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
        tile = true, tileSize = 16, edgeSize = 14,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    AcqDropdownMenu:SetBackdropColor(0.04, 0.06, 0.10, 0.98)
    AcqDropdownMenu:SetBackdropBorderColor(0.85, 0.70, 0.25, 0.98)
end
AcqDropdownMenu:Hide()
AcqDropdownMenu.buttons = {}

local function ToggleAcqDropdown(anchorBtn, optionsList, currentIdx, onSelect)
    if AcqDropdownMenu:IsShown() and AcqDropdownMenu.anchorBtn == anchorBtn then
        AcqDropdownMenu:Hide()
        return
    end
    AcqDropdownMenu.anchorBtn = anchorBtn
    for _, b in ipairs(AcqDropdownMenu.buttons) do b:Hide() end

    local dScale = math.max(0.85, math.min(2.0, (anchorBtn and anchorBtn.GetHeight and (anchorBtn:GetHeight() / 24)) or 1.0))
    local maxW = math.floor(175 * dScale + 0.5)
    local rowH = math.max(18, math.floor(22 * dScale + 0.5))
    local fontSz = math.max(9, math.min(17, math.floor(11 * dScale + 0.5)))

    for i, opt in ipairs(optionsList) do
        local btn = AcqDropdownMenu.buttons[i]
        if not btn then
            btn = CreateFrame("Button", nil, AcqDropdownMenu)
            btn.Highlight = btn:CreateTexture(nil, "HIGHLIGHT")
            btn.Highlight:SetAllPoints(btn)
            SetSolid(btn.Highlight, 1, 0.82, 0, 0.22)
            btn.Text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            btn.Text:SetPoint("LEFT", btn, "LEFT", 8, 0)
            btn.Text:SetJustifyH("LEFT")
            AcqDropdownMenu.buttons[i] = btn
        end
        btn:SetHeight(rowH)
        local prefix = (i == currentIdx) and "|cff00ff00> |r" or "   "
        btn.Text:SetFont(STANDARD_FONT, fontSz, "OUTLINE")
        btn.Text:SetText(prefix .. (opt.label or ""))
        local tw = (btn.Text.GetStringWidth and btn.Text:GetStringWidth() or math.floor(130 * dScale)) + math.floor(26 * dScale)
        if tw > maxW then maxW = tw end

        btn:ClearAllPoints()
        btn:SetPoint("TOPLEFT", AcqDropdownMenu, "TOPLEFT", 6, -6 - ((i - 1) * rowH))
        btn:SetScript("OnClick", function()
            AcqDropdownMenu:Hide()
            onSelect(i, opt)
        end)
        btn:Show()
    end

    for i = 1, #optionsList do
        AcqDropdownMenu.buttons[i]:SetWidth(maxW - 12)
    end
    AcqDropdownMenu:SetSize(maxW, (#optionsList * rowH) + 12)
    AcqDropdownMenu:ClearAllPoints()
    AcqDropdownMenu:SetPoint("TOPLEFT", anchorBtn, "BOTTOMLEFT", 0, -2)
    AcqDropdownMenu:Show()
end

-- ============================================================================
-- BLOCK HEADING: 3-ROW TOP FILTER, QUALITY & PAGINATION HEADER BAR FOR QUEST TABS
-- ============================================================================
local QuestAcqHeader = CreateBackdrop("Frame", "AltVaultQuestAcqHeaderBar", MainPanel)
QuestAcqHeader:SetPoint("TOPLEFT", MainPanel, "TOPLEFT", 215, -96)
QuestAcqHeader:SetPoint("TOPRIGHT", MainPanel, "TOPRIGHT", -28, -96)
QuestAcqHeader:SetHeight(112)
QuestAcqHeader:SetFrameLevel((MainPanel:GetFrameLevel() or 10) + 8)
QuestAcqHeader:EnableMouse(true)

QuestAcqHeader.SolidBG = QuestAcqHeader:CreateTexture(nil, "BACKGROUND")
QuestAcqHeader.SolidBG:SetPoint("TOPLEFT", QuestAcqHeader, "TOPLEFT", 2, -2)
QuestAcqHeader.SolidBG:SetPoint("BOTTOMRIGHT", QuestAcqHeader, "BOTTOMRIGHT", -2, 2)
SetSolid(QuestAcqHeader.SolidBG, 0.05, 0.07, 0.11, 0.98)

QuestAcqHeader.BottomBorder = QuestAcqHeader:CreateTexture(nil, "BORDER")
QuestAcqHeader.BottomBorder:SetPoint("BOTTOMLEFT", QuestAcqHeader, "BOTTOMLEFT", 2, 0)
QuestAcqHeader.BottomBorder:SetPoint("BOTTOMRIGHT", QuestAcqHeader, "BOTTOMRIGHT", -2, 0)
QuestAcqHeader.BottomBorder:SetHeight(2)
SetSolid(QuestAcqHeader.BottomBorder, 0.80, 0.65, 0.22, 0.95)

if QuestAcqHeader.SetBackdrop then
    QuestAcqHeader:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    QuestAcqHeader:SetBackdropColor(0.05, 0.07, 0.11, 0.98)
    QuestAcqHeader:SetBackdropBorderColor(0.75, 0.60, 0.22, 0.95)
end
QuestAcqHeader:Hide()

local AcqRow1 = CreateFrame("Frame", nil, QuestAcqHeader)
local AcqRow2 = CreateFrame("Frame", nil, QuestAcqHeader)
local AcqRow3 = CreateFrame("Frame", nil, QuestAcqHeader)

local AcqSearchBox = CreateFrame("EditBox", "AltVaultQuestAcqSearchBox", AcqRow1, "InputBoxTemplate")
AcqSearchBox:SetSize(165, 26)
AcqSearchBox:SetAutoFocus(false)
AcqSearchBox:SetText("")

local AcqSearchPlaceholder = AcqSearchBox:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
AcqSearchPlaceholder:SetPoint("LEFT", AcqSearchBox, "LEFT", 6, 0)
AcqSearchPlaceholder:SetPoint("RIGHT", AcqSearchBox, "RIGHT", -6, 0)
AcqSearchPlaceholder:SetJustifyH("LEFT")
AcqSearchPlaceholder:SetWordWrap(false)
AcqSearchPlaceholder:SetText("Search Item, Quest, Vendor, Zone...")

local AcqMinLvlBox = CreateFrame("EditBox", "AltVaultQuestAcqMinLvlBox", AcqRow2, "InputBoxTemplate")
AcqMinLvlBox:SetSize(56, 24)
AcqMinLvlBox:SetAutoFocus(false)
AcqMinLvlBox:SetNumeric(true)
AcqMinLvlBox:SetMaxLetters(3)
AcqMinLvlBox:SetText("")

local AcqMinPlaceholder = AcqMinLvlBox:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
AcqMinPlaceholder:SetPoint("LEFT", AcqMinLvlBox, "LEFT", 5, 0)
AcqMinPlaceholder:SetPoint("RIGHT", AcqMinLvlBox, "RIGHT", -4, 0)
AcqMinPlaceholder:SetJustifyH("LEFT")
AcqMinPlaceholder:SetWordWrap(false)
AcqMinPlaceholder:SetText("Min Lvl")

local AcqMaxLvlBox = CreateFrame("EditBox", "AltVaultQuestAcqMaxLvlBox", AcqRow2, "InputBoxTemplate")
AcqMaxLvlBox:SetSize(56, 24)
AcqMaxLvlBox:SetAutoFocus(false)
AcqMaxLvlBox:SetNumeric(true)
AcqMaxLvlBox:SetMaxLetters(3)
AcqMaxLvlBox:SetText("")

local AcqMaxPlaceholder = AcqMaxLvlBox:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
AcqMaxPlaceholder:SetPoint("LEFT", AcqMaxLvlBox, "LEFT", 5, 0)
AcqMaxPlaceholder:SetPoint("RIGHT", AcqMaxLvlBox, "RIGHT", -4, 0)
AcqMaxPlaceholder:SetJustifyH("LEFT")
AcqMaxPlaceholder:SetWordWrap(false)
AcqMaxPlaceholder:SetText("Max Lvl")

local function ApplySearchTextFromBox(isUserLevelEdit)
    local raw = string.gsub(AcqSearchBox:GetText() or "", "^%s*(.-)%s*$", "%1")
    local minVal = tonumber(AcqMinLvlBox:GetText() or "")
    local maxVal = tonumber(AcqMaxLvlBox:GetText() or "")
    if minVal and minVal <= 0 then minVal = nil end
    if maxVal and maxVal <= 0 then maxVal = nil end

    local mode = MainPanel:GetActiveViewMode()
    if mode == "QUEST_FOR_RECIPE" then
        if isUserLevelEdit then acqState.recipeAutoLevelDefault = false end
        acqState.recipeSearchText = raw
        acqState.recipeMinLvl = minVal
        acqState.recipeMaxLvl = maxVal
        acqState.recipePage = 1
        acqState.inspectedRecipeEntry = nil
    else
        if isUserLevelEdit then acqState.itemAutoLevelDefault = false end
        acqState.itemSearchText = raw
        acqState.itemMinLvl = minVal
        acqState.itemMaxLvl = maxVal
        acqState.itemPage = 1
        acqState.inspectedItemEntry = nil
    end
    if MainPanel.ScrollFrame then MainPanel.ScrollFrame:SetVerticalScroll(0) end
    MainPanel:RenderActivePane()
end

AcqSearchBox:SetScript("OnEditFocusGained", function() AcqSearchPlaceholder:Hide() end)
AcqSearchBox:SetScript("OnEditFocusLost", function(self)
    if (self:GetText() or "") == "" then AcqSearchPlaceholder:Show() end
end)
AcqSearchBox:SetScript("OnEscapePressed", function(self)
    self:ClearFocus()
    if (self:GetText() or "") == "" then AcqSearchPlaceholder:Show() end
end)
AcqSearchBox:SetScript("OnEnterPressed", function(self)
    self:ClearFocus()
    ApplySearchTextFromBox(false)
end)

local function SetupLevelBoxScripts(box, placeholder)
    box:SetScript("OnEditFocusGained", function() placeholder:Hide() end)
    box:SetScript("OnEditFocusLost", function(self)
        if (self:GetText() or "") == "" then placeholder:Show() end
    end)
    box:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
        if (self:GetText() or "") == "" then placeholder:Show() end
    end)
    box:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
        ApplySearchTextFromBox(true)
    end)
    box:SetScript("OnTextChanged", function(self, userInput)
        local txt = self:GetText() or ""
        if txt ~= "" then placeholder:Hide() elseif not self:HasFocus() then placeholder:Show() end
        if userInput then
            ApplySearchTextFromBox(true)
        end
    end)
end

SetupLevelBoxScripts(AcqMinLvlBox, AcqMinPlaceholder)
SetupLevelBoxScripts(AcqMaxLvlBox, AcqMaxPlaceholder)

local AcqSearchBtn = CreateFrame("Button", nil, AcqRow1, "UIPanelButtonTemplate")
AcqSearchBtn:SetSize(64, 26)
AcqSearchBtn:SetText("Search")
AcqSearchBtn:SetScript("OnClick", function()
    AcqSearchBox:ClearFocus()
    ApplySearchTextFromBox(false)
end)

local AcqSourceDropBtn = CreateFrame("Button", nil, AcqRow1, "UIPanelButtonTemplate")
AcqSourceDropBtn:SetSize(145, 26)
AcqSourceDropBtn:SetScript("OnClick", function(self)
    local mode = MainPanel:GetActiveViewMode()
    if mode == "QUEST_FOR_RECIPE" then
        ToggleAcqDropdown(self, RECIPE_METHOD_FILTERS, acqState.recipeMethodIdx, function(idx)
            acqState.recipeMethodIdx = idx
            acqState.recipePage = 1
            acqState.inspectedRecipeEntry = nil
            if MainPanel.ScrollFrame then MainPanel.ScrollFrame:SetVerticalScroll(0) end
            MainPanel:RenderActivePane()
        end)
    else
        ToggleAcqDropdown(self, ITEM_SOURCE_FILTERS, acqState.itemSourceIdx, function(idx)
            acqState.itemSourceIdx = idx
            acqState.itemPage = 1
            acqState.inspectedItemEntry = nil
            if MainPanel.ScrollFrame then MainPanel.ScrollFrame:SetVerticalScroll(0) end
            MainPanel:RenderActivePane()
        end)
    end
end)

local AcqCatDropBtn = CreateFrame("Button", nil, AcqRow1, "UIPanelButtonTemplate")
AcqCatDropBtn:SetSize(145, 26)
AcqCatDropBtn:SetScript("OnClick", function(self)
    local mode = MainPanel:GetActiveViewMode()
    if mode == "QUEST_FOR_RECIPE" then
        ToggleAcqDropdown(self, RECIPE_PROF_FILTERS, acqState.recipeProfIdx, function(idx)
            acqState.recipeProfIdx = idx
            acqState.recipePage = 1
            acqState.inspectedRecipeEntry = nil
            if MainPanel.ScrollFrame then MainPanel.ScrollFrame:SetVerticalScroll(0) end
            MainPanel:RenderActivePane()
        end)
    else
        ToggleAcqDropdown(self, ITEM_CATEGORY_FILTERS, acqState.itemCatIdx, function(idx)
            acqState.itemCatIdx = idx
            acqState.itemPage = 1
            acqState.inspectedItemEntry = nil
            if MainPanel.ScrollFrame then MainPanel.ScrollFrame:SetVerticalScroll(0) end
            MainPanel:RenderActivePane()
        end)
    end
end)

local AcqFactionDropBtn = CreateFrame("Button", nil, AcqRow1, "UIPanelButtonTemplate")
AcqFactionDropBtn:SetSize(135, 26)
AcqFactionDropBtn:SetScript("OnClick", function(self)
    local mode = MainPanel:GetActiveViewMode()
    local curIdx = (mode == "QUEST_FOR_RECIPE") and acqState.recipeFactionIdx or acqState.itemFactionIdx
    ToggleAcqDropdown(self, FACTION_FILTERS, curIdx, function(idx)
        if mode == "QUEST_FOR_RECIPE" then
            acqState.recipeFactionIdx = idx
            acqState.recipePage = 1
            acqState.inspectedRecipeEntry = nil
        else
            acqState.itemFactionIdx = idx
            acqState.itemPage = 1
            acqState.inspectedItemEntry = nil
        end
        if MainPanel.ScrollFrame then MainPanel.ScrollFrame:SetVerticalScroll(0) end
        MainPanel:RenderActivePane()
    end)
end)

-- Row 1 & Row 2 Action Buttons + Pagination + Quality Filter Row 3
local QuickAllBtn = CreateFrame("Button", nil, AcqRow2, "UIPanelButtonTemplate")
local QuickQuestBtn = CreateFrame("Button", nil, AcqRow2, "UIPanelButtonTemplate")
local QuickVendorBtn = CreateFrame("Button", nil, AcqRow2, "UIPanelButtonTemplate")
local QuickThirdBtn = CreateFrame("Button", nil, AcqRow2, "UIPanelButtonTemplate")
local QuickDropBtn = CreateFrame("Button", nil, AcqRow2, "UIPanelButtonTemplate")
local AcqMyLvlBtn = CreateFrame("Button", nil, AcqRow2, "UIPanelButtonTemplate")
local AcqViewToggleBtn = CreateFrame("Button", nil, AcqRow2, "UIPanelButtonTemplate")
local AcqPerPageBtn = CreateFrame("Button", nil, AcqRow2, "UIPanelButtonTemplate")
local AcqPrevPageBtn = CreateFrame("Button", nil, AcqRow2, "UIPanelButtonTemplate")
local AcqPageInfoBtn = CreateFrame("Button", nil, AcqRow2, "UIPanelButtonTemplate")
local AcqNextPageBtn = CreateFrame("Button", nil, AcqRow2, "UIPanelButtonTemplate")
local AcqFavToggleBtn = CreateFrame("Button", nil, AcqRow1, "UIPanelButtonTemplate")
local ToggleClosetBtn = CreateFrame("Button", nil, AcqRow1, "UIPanelButtonTemplate")
local AcqResetBtn = CreateFrame("Button", nil, AcqRow1, "UIPanelButtonTemplate")

local AcqAllQualityBtn = CreateFrame("Button", nil, AcqRow3, "UIPanelButtonTemplate")
local acqQualityBtns = {}

local function UpdateAcqQualityButtonLabels()
    local allOn = true
    for _, qDef in ipairs(MainPanel.QUALITY_FILTER_DEFS or {}) do
        local isOn = acqState.qualities[qDef.key] ~= false
        if not isOn then allOn = false end
        local btn = acqQualityBtns[qDef.key]
        if btn then
            if isOn then
                btn:SetText(string.format("|cff00ff00✓|r |cff%s%s|r", qDef.hex, qDef.label))
                btn:LockHighlight()
            else
                btn:SetText(string.format("|cff555555✗ %s|r", qDef.label))
                btn:UnlockHighlight()
            end
        end
    end
    if allOn then
        AcqAllQualityBtn:SetText("|cffffd100All Qualities: ON|r")
        AcqAllQualityBtn:LockHighlight()
    else
        AcqAllQualityBtn:SetText("All Qualities")
        AcqAllQualityBtn:UnlockHighlight()
    end
end

AcqAllQualityBtn:SetScript("OnClick", function()
    for _, qDef in ipairs(MainPanel.QUALITY_FILTER_DEFS or {}) do
        acqState.qualities[qDef.key] = true
    end
    acqState.itemPage = 1
    acqState.recipePage = 1
    UpdateAcqQualityButtonLabels()
    if MainPanel.ScrollFrame then MainPanel.ScrollFrame:SetVerticalScroll(0) end
    MainPanel:RenderActivePane()
end)

for _, qDef in ipairs(MainPanel.QUALITY_FILTER_DEFS or {}) do
    local qBtn = CreateFrame("Button", nil, AcqRow3, "UIPanelButtonTemplate")
    qBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    local qKey = qDef.key
    qBtn:SetScript("OnClick", function(_, button)
        if button == "RightButton" then
            for _, d in ipairs(MainPanel.QUALITY_FILTER_DEFS or {}) do
                acqState.qualities[d.key] = (d.key == qKey)
            end
        else
            acqState.qualities[qKey] = not (acqState.qualities[qKey] ~= false)
            local anyEnabled = false
            for _, d in ipairs(MainPanel.QUALITY_FILTER_DEFS or {}) do
                if acqState.qualities[d.key] ~= false then anyEnabled = true; break end
            end
            if not anyEnabled then
                for _, d in ipairs(MainPanel.QUALITY_FILTER_DEFS or {}) do
                    acqState.qualities[d.key] = true
                end
            end
        end
        acqState.itemPage = 1
        acqState.recipePage = 1
        UpdateAcqQualityButtonLabels()
        if MainPanel.ScrollFrame then MainPanel.ScrollFrame:SetVerticalScroll(0) end
        MainPanel:RenderActivePane()
    end)
    acqQualityBtns[qKey] = qBtn
end
UpdateAcqQualityButtonLabels()

local function UpdateAcqPaginationControls(mode, totalMatches)
    local perPage = MainPanel:GetPerPageSize()
    local perLabel = (perPage >= 9999) and "All" or tostring(perPage)
    AcqPerPageBtn:SetText("|cff00ff96Per Pg: " .. perLabel .. " ▼|r")

    local totalPages = math.max(1, math.ceil(math.max(0, totalMatches or 0) / math.max(1, perPage)))
    local curPage
    if mode == "QUEST_FOR_RECIPE" then
        acqState.recipeTotalPages = totalPages
        if acqState.recipePage > totalPages then acqState.recipePage = totalPages end
        if acqState.recipePage < 1 then acqState.recipePage = 1 end
        curPage = acqState.recipePage
    else
        acqState.itemTotalPages = totalPages
        if acqState.itemPage > totalPages then acqState.itemPage = totalPages end
        if acqState.itemPage < 1 then acqState.itemPage = 1 end
        curPage = acqState.itemPage
    end

    AcqPrevPageBtn:SetText(curPage > 1 and "|cffffd100[ - ]|r" or "|cff666666[ - ]|r")
    AcqPageInfoBtn:SetText(string.format("|cffffffffPg %d/%d|r", curPage, totalPages))
    AcqNextPageBtn:SetText(curPage < totalPages and "|cffffd100[ + ]|r" or "|cff666666[ + ]|r")
end

AcqPerPageBtn:SetScript("OnClick", function(self)
    local curSize = MainPanel:GetPerPageSize()
    local curIdx = 2
    for i, opt in ipairs(MainPanel.PAGE_SIZE_OPTIONS or {}) do
        if opt.count == curSize then curIdx = i; break end
    end
    ToggleAcqDropdown(self, MainPanel.PAGE_SIZE_OPTIONS or {}, curIdx, function(_, opt)
        MainPanel:SetPerPageSize(opt.count)
        acqState.itemPage = 1
        acqState.recipePage = 1
        if MainPanel.ScrollFrame then MainPanel.ScrollFrame:SetVerticalScroll(0) end
        MainPanel:RenderActivePane()
    end)
end)

AcqPrevPageBtn:SetScript("OnClick", function()
    local mode = MainPanel:GetActiveViewMode()
    if mode == "QUEST_FOR_RECIPE" then
        acqState.recipePage = (acqState.recipePage > 1) and (acqState.recipePage - 1) or (acqState.recipeTotalPages or 1)
    else
        acqState.itemPage = (acqState.itemPage > 1) and (acqState.itemPage - 1) or (acqState.itemTotalPages or 1)
    end
    if MainPanel.ScrollFrame then MainPanel.ScrollFrame:SetVerticalScroll(0) end
    MainPanel:RenderActivePane()
end)

AcqPageInfoBtn:SetScript("OnClick", function()
    local mode = MainPanel:GetActiveViewMode()
    if mode == "QUEST_FOR_RECIPE" then acqState.recipePage = 1 else acqState.itemPage = 1 end
    if MainPanel.ScrollFrame then MainPanel.ScrollFrame:SetVerticalScroll(0) end
    MainPanel:RenderActivePane()
end)

AcqNextPageBtn:SetScript("OnClick", function()
    local mode = MainPanel:GetActiveViewMode()
    if mode == "QUEST_FOR_RECIPE" then
        acqState.recipePage = (acqState.recipePage < (acqState.recipeTotalPages or 1)) and (acqState.recipePage + 1) or 1
    else
        acqState.itemPage = (acqState.itemPage < (acqState.itemTotalPages or 1)) and (acqState.itemPage + 1) or 1
    end
    if MainPanel.ScrollFrame then MainPanel.ScrollFrame:SetVerticalScroll(0) end
    MainPanel:RenderActivePane()
end)

AcqMyLvlBtn:SetScript("OnClick", function()
    local mode = MainPanel:GetActiveViewMode()
    if mode == "QUEST_FOR_RECIPE" then
        acqState.recipeAutoLevelDefault = not acqState.recipeAutoLevelDefault
        acqState.lastSeededRecipeCharKey = nil
        acqState.recipePage = 1
        if not acqState.recipeAutoLevelDefault then
            acqState.recipeMinLvl = nil
            acqState.recipeMaxLvl = nil
            AcqMinLvlBox:SetText("")
            AcqMinPlaceholder:Show()
            AcqMaxLvlBox:SetText("")
            AcqMaxPlaceholder:Show()
        else
            SyncAcqAutoLevelDefault("QUEST_FOR_RECIPE")
        end
    else
        acqState.itemAutoLevelDefault = not acqState.itemAutoLevelDefault
        acqState.lastSeededItemCharKey = nil
        acqState.itemPage = 1
        if not acqState.itemAutoLevelDefault then
            acqState.itemMinLvl = nil
            acqState.itemMaxLvl = nil
            AcqMinLvlBox:SetText("")
            AcqMinPlaceholder:Show()
            AcqMaxLvlBox:SetText("")
            AcqMaxPlaceholder:Show()
        else
            SyncAcqAutoLevelDefault("QUEST_FOR_ITEM")
        end
    end
    if MainPanel.ScrollFrame then MainPanel.ScrollFrame:SetVerticalScroll(0) end
    MainPanel:RenderActivePane()
end)

AcqResetBtn:SetSize(56, 26)
AcqResetBtn:SetText("Reset")
AcqResetBtn:SetScript("OnClick", function()
    AcqDropdownMenu:Hide()
    AcqSearchBox:SetText("")
    AcqSearchBox:ClearFocus()
    AcqSearchPlaceholder:Show()
    AcqMinLvlBox:SetText("")
    AcqMinLvlBox:ClearFocus()
    AcqMinPlaceholder:Show()
    AcqMaxLvlBox:SetText("")
    AcqMaxLvlBox:ClearFocus()
    AcqMaxPlaceholder:Show()
    for _, qDef in ipairs(MainPanel.QUALITY_FILTER_DEFS or {}) do
        acqState.qualities[qDef.key] = true
    end
    UpdateAcqQualityButtonLabels()
    local mode = MainPanel:GetActiveViewMode()
    if mode == "QUEST_FOR_RECIPE" then
        acqState.recipeSearchText = ""
        acqState.recipeAutoLevelDefault = false
        acqState.showRecipeFavoritesOnly = false
        acqState.recipeMinLvl = nil
        acqState.recipeMaxLvl = nil
        acqState.recipeMethodIdx = 1
        acqState.recipeProfIdx = 1
        acqState.recipeFactionIdx = 1
        acqState.recipePage = 1
        acqState.inspectedRecipeEntry = nil
    else
        acqState.itemSearchText = ""
        acqState.itemAutoLevelDefault = false
        acqState.showItemFavoritesOnly = false
        acqState.itemMinLvl = nil
        acqState.itemMaxLvl = nil
        acqState.itemSourceIdx = 1
        acqState.itemCatIdx = 1
        acqState.itemFactionIdx = 1
        acqState.itemPage = 1
        acqState.inspectedItemEntry = nil
    end
    if MainPanel.ScrollFrame then MainPanel.ScrollFrame:SetVerticalScroll(0) end
    MainPanel:RenderActivePane()
end)

local function SetQuickMethodIdx(targetIdx)
    local mode = MainPanel:GetActiveViewMode()
    if mode == "QUEST_FOR_RECIPE" then
        acqState.recipeMethodIdx = targetIdx
        acqState.showRecipeFavoritesOnly = false
        acqState.recipePage = 1
        acqState.inspectedRecipeEntry = nil
    else
        acqState.itemSourceIdx = targetIdx
        acqState.showItemFavoritesOnly = false
        acqState.itemPage = 1
        acqState.inspectedItemEntry = nil
    end
    if MainPanel.ScrollFrame then MainPanel.ScrollFrame:SetVerticalScroll(0) end
    MainPanel:RenderActivePane()
end

QuickAllBtn:SetScript("OnClick", function() SetQuickMethodIdx(1) end)
QuickQuestBtn:SetScript("OnClick", function()
    local mode = MainPanel:GetActiveViewMode()
    SetQuickMethodIdx(mode == "QUEST_FOR_RECIPE" and 3 or 2)
end)
QuickVendorBtn:SetScript("OnClick", function()
    local mode = MainPanel:GetActiveViewMode()
    SetQuickMethodIdx(mode == "QUEST_FOR_RECIPE" and 2 or 3)
end)
QuickThirdBtn:SetScript("OnClick", function()
    SetQuickMethodIdx(4)
end)
QuickDropBtn:SetScript("OnClick", function()
    local mode = MainPanel:GetActiveViewMode()
    SetQuickMethodIdx(mode == "QUEST_FOR_RECIPE" and 6 or 5)
end)

AcqFavToggleBtn:SetText("|cffffd100★ Favs (0)|r")
AcqFavToggleBtn:SetScript("OnClick", function()
    local mode = MainPanel:GetActiveViewMode()
    if mode == "QUEST_FOR_RECIPE" then
        acqState.showRecipeFavoritesOnly = not acqState.showRecipeFavoritesOnly
        acqState.recipePage = 1
        acqState.inspectedRecipeEntry = nil
    else
        acqState.showItemFavoritesOnly = not acqState.showItemFavoritesOnly
        acqState.itemPage = 1
        acqState.inspectedItemEntry = nil
    end
    if MainPanel.ScrollFrame then MainPanel.ScrollFrame:SetVerticalScroll(0) end
    MainPanel:RenderActivePane()
end)

AcqViewToggleBtn:SetText("|cff00ff96View: 3-Col Grid|r")
AcqViewToggleBtn:SetScript("OnClick", function(self)
    acqState.useGridView = not acqState.useGridView
    self:SetText(acqState.useGridView and "|cff00ff96View: 3-Col Grid|r" or "|cff88ccffView: Full List|r")
    if MainPanel.ScrollFrame then MainPanel.ScrollFrame:SetVerticalScroll(0) end
    MainPanel:RenderActivePane()
end)

ToggleClosetBtn:SetText("|cffffd100👗 3D Closet|r")
ToggleClosetBtn:SetScript("OnClick", function()
    local drawer = MainPanel.DBDressUpDrawer or _G.AltVaultTab6FloatingDressUp or _G.AltVaultDBDressUpDrawer
    if drawer then
        if drawer:IsShown() then drawer:Hide() else drawer:Show(); drawer:Raise() end
    end
end)

local function SyncQuestAcqHeaderControls(mode)
    SyncAcqAutoLevelDefault(mode)
    UpdateAcqQualityButtonLabels()
    AcqViewToggleBtn:SetText(acqState.useGridView and "|cff00ff96View: 3-Col Grid|r" or "|cff88ccffView: Full List|r")
    local itemFavCount, recipeFavCount = 0, 0
    if MainPanel.GetFavoriteCounts then
        itemFavCount, recipeFavCount = MainPanel:GetFavoriteCounts()
    end

    local isRecipe = (mode == "QUEST_FOR_RECIPE")
    if isRecipe then
        if acqState.recipeAutoLevelDefault then
            AcqMyLvlBtn:SetText("|cff00ff96My Skill: ON|r")
            AcqMyLvlBtn:LockHighlight()
        else
            AcqMyLvlBtn:SetText("Skill 1-300")
            AcqMyLvlBtn:UnlockHighlight()
        end
        if acqState.showRecipeFavoritesOnly then
            AcqFavToggleBtn:SetText(string.format("|cffffd100★ Favs: ON (%d)|r", recipeFavCount))
            AcqFavToggleBtn:LockHighlight()
        else
            AcqFavToggleBtn:SetText(string.format("|cffffd100★ Favs (%d)|r", recipeFavCount))
            AcqFavToggleBtn:UnlockHighlight()
        end
        AcqSearchPlaceholder:SetText("Search Recipe, Profession, Vendor, Quest, Zone...")
        local curTxt = acqState.recipeSearchText or ""
        if AcqSearchBox:GetText() ~= curTxt then AcqSearchBox:SetText(curTxt) end
        if curTxt ~= "" then AcqSearchPlaceholder:Hide() elseif not AcqSearchBox:HasFocus() then AcqSearchPlaceholder:Show() end

        AcqMinPlaceholder:SetText("Min 1-300")
        local minTxt = acqState.recipeMinLvl and tostring(acqState.recipeMinLvl) or ""
        if AcqMinLvlBox:GetText() ~= minTxt then AcqMinLvlBox:SetText(minTxt) end
        if minTxt ~= "" then AcqMinPlaceholder:Hide() elseif not AcqMinLvlBox:HasFocus() then AcqMinPlaceholder:Show() end

        AcqMaxPlaceholder:SetText("Max 1-300")
        local maxTxt = acqState.recipeMaxLvl and tostring(acqState.recipeMaxLvl) or ""
        if AcqMaxLvlBox:GetText() ~= maxTxt then AcqMaxLvlBox:SetText(maxTxt) end
        if maxTxt ~= "" then AcqMaxPlaceholder:Hide() elseif not AcqMaxLvlBox:HasFocus() then AcqMaxPlaceholder:Show() end

        local mOpt = RECIPE_METHOD_FILTERS[acqState.recipeMethodIdx] or RECIPE_METHOD_FILTERS[1]
        local pOpt = RECIPE_PROF_FILTERS[acqState.recipeProfIdx] or RECIPE_PROF_FILTERS[1]
        local fOpt = FACTION_FILTERS[acqState.recipeFactionIdx] or FACTION_FILTERS[1]
        AcqSourceDropBtn:SetText(mOpt.label .. " ▼")
        AcqCatDropBtn:SetText(pOpt.label .. " ▼")
        AcqFactionDropBtn:SetText(fOpt.label .. " ▼")

        QuickAllBtn:SetText("All")
        QuickQuestBtn:SetText("Quests")
        QuickVendorBtn:SetText("Vendors")
        QuickThirdBtn:SetText("Trainers")
        QuickDropBtn:SetText("Drops")

        local mIdx = acqState.recipeMethodIdx
        if mIdx == 1 then QuickAllBtn:LockHighlight() else QuickAllBtn:UnlockHighlight() end
        if mIdx == 3 then QuickQuestBtn:LockHighlight() else QuickQuestBtn:UnlockHighlight() end
        if mIdx == 2 then QuickVendorBtn:LockHighlight() else QuickVendorBtn:UnlockHighlight() end
        if mIdx == 4 then QuickThirdBtn:LockHighlight() else QuickThirdBtn:UnlockHighlight() end
        if mIdx == 6 then QuickDropBtn:LockHighlight() else QuickDropBtn:UnlockHighlight() end
    else
        if acqState.itemAutoLevelDefault then
            AcqMyLvlBtn:SetText("|cff00ff96My Lvl: ON|r")
            AcqMyLvlBtn:LockHighlight()
        else
            AcqMyLvlBtn:SetText("Lvl 1-60")
            AcqMyLvlBtn:UnlockHighlight()
        end
        if acqState.showItemFavoritesOnly then
            AcqFavToggleBtn:SetText(string.format("|cffffd100★ Favs: ON (%d)|r", itemFavCount))
            AcqFavToggleBtn:LockHighlight()
        else
            AcqFavToggleBtn:SetText(string.format("|cffffd100★ Favs (%d)|r", itemFavCount))
            AcqFavToggleBtn:UnlockHighlight()
        end
        AcqSearchPlaceholder:SetText("Search Item, Quest, Vendor, Zone, Boss...")
        local curTxt = acqState.itemSearchText or ""
        if AcqSearchBox:GetText() ~= curTxt then AcqSearchBox:SetText(curTxt) end
        if curTxt ~= "" then AcqSearchPlaceholder:Hide() elseif not AcqSearchBox:HasFocus() then AcqSearchPlaceholder:Show() end

        AcqMinPlaceholder:SetText("Min Lvl")
        local minTxt = acqState.itemMinLvl and tostring(acqState.itemMinLvl) or ""
        if AcqMinLvlBox:GetText() ~= minTxt then AcqMinLvlBox:SetText(minTxt) end
        if minTxt ~= "" then AcqMinPlaceholder:Hide() elseif not AcqMinLvlBox:HasFocus() then AcqMinPlaceholder:Show() end

        AcqMaxPlaceholder:SetText("Max Lvl")
        local maxTxt = acqState.itemMaxLvl and tostring(acqState.itemMaxLvl) or ""
        if AcqMaxLvlBox:GetText() ~= maxTxt then AcqMaxLvlBox:SetText(maxTxt) end
        if maxTxt ~= "" then AcqMaxPlaceholder:Hide() elseif not AcqMaxLvlBox:HasFocus() then AcqMaxPlaceholder:Show() end

        local sOpt = ITEM_SOURCE_FILTERS[acqState.itemSourceIdx] or ITEM_SOURCE_FILTERS[1]
        local cOpt = ITEM_CATEGORY_FILTERS[acqState.itemCatIdx] or ITEM_CATEGORY_FILTERS[1]
        local fOpt = FACTION_FILTERS[acqState.itemFactionIdx] or FACTION_FILTERS[1]
        AcqSourceDropBtn:SetText(sOpt.label .. " ▼")
        AcqCatDropBtn:SetText(cOpt.label .. " ▼")
        AcqFactionDropBtn:SetText(fOpt.label .. " ▼")

        QuickAllBtn:SetText("All")
        QuickQuestBtn:SetText("Quests")
        QuickVendorBtn:SetText("Vendors")
        QuickThirdBtn:SetText("Factions")
        QuickDropBtn:SetText("Bosses")

        local sIdx = acqState.itemSourceIdx
        if sIdx == 1 then QuickAllBtn:LockHighlight() else QuickAllBtn:UnlockHighlight() end
        if sIdx == 2 then QuickQuestBtn:LockHighlight() else QuickQuestBtn:UnlockHighlight() end
        if sIdx == 3 then QuickVendorBtn:LockHighlight() else QuickVendorBtn:UnlockHighlight() end
        if sIdx == 4 then QuickThirdBtn:LockHighlight() else QuickThirdBtn:UnlockHighlight() end
        if sIdx == 5 then QuickDropBtn:LockHighlight() else QuickDropBtn:UnlockHighlight() end
    end
end

local function ScaleQuestAcqHeader(panel, bScale, leftX, baseTopY)
    local mode = panel:GetActiveViewMode()
    if mode ~= "QUEST_FOR_ITEM" and mode ~= "QUEST_FOR_RECIPE" then
        QuestAcqHeader:Hide()
        return
    end
    bScale = bScale or (panel.GetButtonScale and panel:GetButtonScale()) or 1.0
    leftX = leftX or (panel.GetLeftColumnOffset and panel:GetLeftColumnOffset()) or 220
    baseTopY = baseTopY or (panel.GetBaseContentTopY and panel:GetBaseContentTopY()) or -84

    local headerH = math.max(98, math.floor(112 * bScale + 0.5))
    QuestAcqHeader:SetFrameLevel((panel:GetFrameLevel() or 10) + 10)
    QuestAcqHeader:ClearAllPoints()
    QuestAcqHeader:SetPoint("TOPLEFT", panel, "TOPLEFT", leftX, baseTopY)
    QuestAcqHeader:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -28, baseTopY)
    QuestAcqHeader:SetHeight(headerH)
    QuestAcqHeader:Show()

    local scrollTopY = baseTopY - headerH - 8
    panel:SetScrollTopOffset(scrollTopY)
    if panel.ScrollFrame then
        panel.ScrollFrame:ClearAllPoints()
        panel.ScrollFrame:SetPoint("TOPLEFT", panel, "TOPLEFT", leftX, scrollTopY)
        panel.ScrollFrame:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -32, 24)
    end

    local rowH = math.max(25, math.floor(30 * bScale + 0.5))
    AcqRow1:ClearAllPoints()
    AcqRow1:SetPoint("TOPLEFT", QuestAcqHeader, "TOPLEFT", 6, -6)
    AcqRow1:SetPoint("TOPRIGHT", QuestAcqHeader, "TOPRIGHT", -6, -6)
    AcqRow1:SetHeight(rowH)

    AcqRow2:ClearAllPoints()
    AcqRow2:SetPoint("TOPLEFT", AcqRow1, "BOTTOMLEFT", 0, -4)
    AcqRow2:SetPoint("TOPRIGHT", AcqRow1, "BOTTOMRIGHT", 0, -4)
    AcqRow2:SetHeight(rowH)

    AcqRow3:ClearAllPoints()
    AcqRow3:SetPoint("TOPLEFT", AcqRow2, "BOTTOMLEFT", 0, -4)
    AcqRow3:SetPoint("TOPRIGHT", AcqRow2, "BOTTOMRIGHT", 0, -4)
    AcqRow3:SetHeight(rowH)

    if panel.FitControlsRowInsideBar then
        panel:FitControlsRowInsideBar(AcqRow1, 2, 2, 4, {
            { frame = AcqSearchBox,       isEditBox = true, placeholder = AcqSearchPlaceholder, baseW = 140, baseH = 26, font = 12 },
            { frame = AcqSearchBtn,       baseW = 54,  baseH = 26, font = 12 },
            { frame = AcqSourceDropBtn,   baseW = 132, baseH = 26, font = 11 },
            { frame = AcqCatDropBtn,      baseW = 132, baseH = 26, font = 11 },
            { frame = AcqFactionDropBtn,  baseW = 118, baseH = 26, font = 11 },
            { frame = AcqFavToggleBtn,    baseW = 88,  baseH = 26, font = 11 },
            { frame = ToggleClosetBtn,    baseW = 84,  baseH = 26, font = 11 },
            { frame = AcqResetBtn,        baseW = 50,  baseH = 26, font = 11 },
        })
        panel:FitControlsRowInsideBar(AcqRow2, 2, 2, 3, {
            { frame = QuickAllBtn,        baseW = 46,  baseH = 25, font = 11 },
            { frame = QuickQuestBtn,      baseW = 54,  baseH = 25, font = 11 },
            { frame = QuickVendorBtn,     baseW = 60,  baseH = 25, font = 11 },
            { frame = QuickThirdBtn,      baseW = 62,  baseH = 25, font = 11 },
            { frame = QuickDropBtn,       baseW = 58,  baseH = 25, font = 11 },
            { frame = AcqMinLvlBox,       isEditBox = true, placeholder = AcqMinPlaceholder, baseW = 48, baseH = 24, font = 11 },
            { frame = AcqMaxLvlBox,       isEditBox = true, placeholder = AcqMaxPlaceholder, baseW = 48, baseH = 24, font = 11 },
            { frame = AcqMyLvlBtn,        baseW = 68,  baseH = 25, font = 11 },
            { frame = AcqViewToggleBtn,   baseW = 88,  baseH = 25, font = 11 },
            { frame = AcqPerPageBtn,      baseW = 82,  baseH = 25, font = 11 },
            { frame = AcqPrevPageBtn,     baseW = 38,  baseH = 25, font = 12 },
            { frame = AcqPageInfoBtn,     baseW = 64,  baseH = 25, font = 11 },
            { frame = AcqNextPageBtn,     baseW = 38,  baseH = 25, font = 12 },
        })
        local qSpecs = {
            { frame = AcqAllQualityBtn, baseW = 112, baseH = 25, font = 11 },
        }
        for _, qDef in ipairs(MainPanel.QUALITY_FILTER_DEFS or {}) do
            local qBtn = acqQualityBtns[qDef.key]
            if qBtn then
                table.insert(qSpecs, { frame = qBtn, baseW = 88, baseH = 25, font = 11 })
            end
        end
        panel:FitControlsRowInsideBar(AcqRow3, 2, 2, 4, qSpecs)
    end
end

-- ============================================================================
-- BLOCK HEADING: 3-COLUMN COMPACT GRID CELL POOL FOR QUEST TABS (DRESSING ROOM STYLE)
-- ============================================================================
MainPanel.acqGridCells = MainPanel.acqGridCells or {}

local function HideAllAcqGridCells()
    for _, cell in pairs(MainPanel.acqGridCells) do
        cell:Hide()
    end
end

local SHORT_METHOD_TAGS = {
    ["QUEST"]   = "|cffffd100[Quest]|r",
    ["VENDOR"]  = "|cff00ff96[Vendor]|r",
    ["REP"]     = "|cffff8000[Faction]|r",
    ["TRAINER"] = "|cff00ccff[Trainer]|r",
    ["BOSS"]    = "|cffff5555[Boss]|r",
    ["DROP"]    = "|cffff5555[Drop]|r",
    ["CRAFT"]   = "|cff66ccff[Craft]|r",
}

local function GetOrCreateAcqGridCell(index)
    local cell = MainPanel.acqGridCells[index]
    if not cell then
        cell = CreateBackdrop("Button", nil, MainPanel.ScrollChild)
        cell:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        if cell.SetBackdrop then
            cell:SetBackdrop({
                bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                tile = true, tileSize = 16, edgeSize = 10,
                insets = { left = 2, right = 2, top = 2, bottom = 2 }
            })
            cell:SetBackdropColor(0.06, 0.08, 0.12, 0.94)
            cell:SetBackdropBorderColor(0.32, 0.36, 0.46, 0.90)
        end

        cell.Highlight = cell:CreateTexture(nil, "HIGHLIGHT")
        cell.Highlight:SetPoint("TOPLEFT", cell, "TOPLEFT", 2, -2)
        cell.Highlight:SetPoint("BOTTOMRIGHT", cell, "BOTTOMRIGHT", -2, 2)
        SetSolid(cell.Highlight, 1, 0.82, 0, 0.18)

        cell.Icon = cell:CreateTexture(nil, "ARTWORK")
        cell.Icon:SetSize(32, 32)
        cell.Icon:SetPoint("LEFT", cell, "LEFT", 5, 0)
        cell.Icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

        cell.Title = cell:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        cell.Title:SetPoint("TOPLEFT", cell.Icon, "TOPRIGHT", 6, 2)
        cell.Title:SetPoint("RIGHT", cell, "RIGHT", -22, 0)
        cell.Title:SetJustifyH("LEFT")
        cell.Title:SetWordWrap(false)

        cell.FavBtn = CreateFrame("Button", nil, cell)
        cell.FavBtn:SetSize(18, 18)
        cell.FavBtn:SetPoint("TOPRIGHT", cell, "TOPRIGHT", -3, -3)
        cell.FavBtn.Text = cell.FavBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        cell.FavBtn.Text:SetPoint("CENTER", 0, 0)
        cell.FavBtn.Text:SetFont(STANDARD_FONT, 12, "OUTLINE")
        cell.FavBtn:SetScript("OnClick", function(btn)
            local parentCell = btn:GetParent()
            if not parentCell or not parentCell.entryData then return end
            local e = parentCell.entryData
            if parentCell.isRecipe then
                local rKey = MainPanel:MakeRecipeFavoriteKey(e.prof, e.name, e.id)
                local nowFav = MainPanel:ToggleRecipeFavorite(rKey, e)
                btn.Text:SetText(nowFav and "|cffffd100★|r" or "|cff777777☆|r")
                SyncQuestAcqHeaderControls("QUEST_FOR_RECIPE")
            else
                local nowFav = MainPanel:ToggleItemFavorite(e.id, e)
                btn.Text:SetText(nowFav and "|cffffd100★|r" or "|cff777777☆|r")
                SyncQuestAcqHeaderControls("QUEST_FOR_ITEM")
            end
        end)

        cell.Meta = cell:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        cell.Meta:SetPoint("TOPLEFT", cell.Title, "BOTTOMLEFT", 0, -1)
        cell.Meta:SetPoint("RIGHT", cell, "RIGHT", -4, 0)
        cell.Meta:SetJustifyH("LEFT")
        cell.Meta:SetWordWrap(false)

        cell.SourceSub = cell:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        cell.SourceSub:SetPoint("TOPLEFT", cell.Meta, "BOTTOMLEFT", 0, -1)
        cell.SourceSub:SetPoint("RIGHT", cell, "RIGHT", -4, 0)
        cell.SourceSub:SetJustifyH("LEFT")
        cell.SourceSub:SetWordWrap(false)

        cell:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            if self.itemLink and string.find(self.itemLink, "|Hitem:") then
                GameTooltip:SetHyperlink(self.itemLink)
            else
                GameTooltip:ClearLines()
                GameTooltip:AddLine(self.rawName or "Recipe", 1, 0.82, 0)
            end
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("|cffffd100Dual-Faction Acquisition Guide:|r", 1, 0.82, 0)
            if self.allianceLine and self.allianceLine ~= "" then
                GameTooltip:AddLine("|cff3399ff• Alliance:|r " .. self.allianceLine, 0.85, 0.92, 1, true)
            end
            if self.hordeLine and self.hordeLine ~= "" then
                GameTooltip:AddLine("|cffff3333• Horde:|r " .. self.hordeLine, 1, 0.82, 0.82, true)
            end
            if self.knownByText and self.knownByText ~= "" then
                GameTooltip:AddLine("|cff00ff00• Known By:|r " .. self.knownByText, 0.2, 1, 0.2, true)
            end
            GameTooltip:AddLine(" ")
            if self.isRecipe then
                GameTooltip:AddLine("|cff00ff00Left-Click:|r Open Full Acquisition Dossier   |   |cffffd100Right-Click:|r Try On / Dossier", 1, 1, 1)
                GameTooltip:AddLine("|cffffd100Alt+Click or [★]:|r Toggle Recipe Favorite", 1, 0.85, 0.2)
            else
                GameTooltip:AddLine("|cff00ff00Left-Click:|r Try On in 3D Closet   |   |cffffd100Right-Click:|r Open Full Acquisition Dossier", 1, 1, 1)
                GameTooltip:AddLine("|cffffd100Alt+Click or [★]:|r Toggle Item Favorite", 1, 0.85, 0.2)
            end
            GameTooltip:Show()
        end)

        cell:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        cell:SetScript("OnClick", function(self, button)
            if IsAltKeyDown() and self.entryData then
                local e = self.entryData
                if self.isRecipe then
                    local rKey = MainPanel:MakeRecipeFavoriteKey(e.prof, e.name, e.id)
                    local nowFav = MainPanel:ToggleRecipeFavorite(rKey, e)
                    if self.FavBtn and self.FavBtn.Text then
                        self.FavBtn.Text:SetText(nowFav and "|cffffd100★|r" or "|cff777777☆|r")
                    end
                    SyncQuestAcqHeaderControls("QUEST_FOR_RECIPE")
                else
                    local nowFav = MainPanel:ToggleItemFavorite(e.id, e)
                    if self.FavBtn and self.FavBtn.Text then
                        self.FavBtn.Text:SetText(nowFav and "|cffffd100★|r" or "|cff777777☆|r")
                    end
                    SyncQuestAcqHeaderControls("QUEST_FOR_ITEM")
                end
                return
            end
            if self.itemLink and IsModifiedClick() then
                HandleModifiedItemClick(self.itemLink)
                return
            end
            if self.isRecipe then
                if button == "RightButton" and self.itemLink and MainPanel.TryOnItemInTab6 then
                    MainPanel:TryOnItemInTab6(self.itemLink, self.rawName)
                    return
                end
                acqState.inspectedRecipeEntry = self.entryData
                MainPanel:RenderActivePane()
            else
                if button == "RightButton" then
                    acqState.inspectedItemEntry = self.entryData
                    MainPanel:RenderActivePane()
                    return
                end
                if (self.itemLink or self.itemID) and MainPanel.TryOnItemInTab6 then
                    MainPanel:TryOnItemInTab6(self.itemLink or self.itemID, self.rawName)
                else
                    acqState.inspectedItemEntry = self.entryData
                    MainPanel:RenderActivePane()
                end
            end
        end)

        MainPanel.acqGridCells[index] = cell
    end
    return cell
end

local function RenderAcqMatchesAsCompactGrid(panel, entries, isRecipeMode)
    if panel.HideArmoryCanvas then panel:HideArmoryCanvas() end
    if panel.ClearAllScrollContent then
        panel:ClearAllScrollContent()
    else
        if panel.contentRows then
            for _, row in pairs(panel.contentRows) do
                row:Hide()
            end
        end
        HideAllAcqGridCells()
    end
    if panel.ScrollChild then panel.ScrollChild:Show() end
    if panel.ScrollFrame then panel.ScrollFrame:Show() end

    local wScale = (panel.GetWindowScaleFactor and panel:GetWindowScaleFactor()) or 1.0
    local leftX = panel:GetLeftColumnOffset()
    local contentWidth = math.max(320, (panel:GetWidth() or 960) - leftX - 38)
    local numCols = (contentWidth >= 660) and 3 or 2
    local gap = math.max(5, math.floor(6 * wScale + 0.5))
    local cellW = math.floor((contentWidth - ((numCols - 1) * gap) - 8) / numCols)
    local cellH = math.max(44, math.floor(48 * wScale + 0.5))
    local iconSz = math.max(28, math.floor(34 * wScale + 0.5))
    local titleFontSz = math.max(10, math.min(18, math.floor(11 * wScale + 0.5)))
    local metaFontSz = math.max(8, math.min(15, math.floor(9.5 * wScale + 0.5)))

    local maxCells = #entries
    local yOffset = -6
    for i = 1, maxCells do
        local e = entries[i]
        local cell = GetOrCreateAcqGridCell(i)
        local colIdx = (i - 1) % numCols
        local rowIdx = math.floor((i - 1) / numCols)
        local xPos = 4 + (colIdx * (cellW + gap))
        local yPos = yOffset - (rowIdx * (cellH + 4))

        cell:SetSize(cellW, cellH)
        cell:ClearAllPoints()
        cell:SetPoint("TOPLEFT", panel.ScrollChild, "TOPLEFT", xPos, yPos)
        cell.Icon:SetSize(iconSz, iconSz)

        cell.isRecipe = isRecipeMode
        cell.entryData = e
        cell.itemID = e.id
        cell.itemLink = e.link
        cell.rawName = e.name
        cell.iconTex = e.icon
        cell.allianceLine = e.alliance
        cell.hordeLine = e.horde
        cell.knownByText = e.knownByText

        cell.Icon:SetTexture(e.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
        cell.Title:SetFont(STANDARD_FONT, titleFontSz, "OUTLINE")
        cell.Meta:SetFont(STANDARD_FONT, metaFontSz, "")
        cell.SourceSub:SetFont(STANDARD_FONT, metaFontSz, "")

        local shortBadge = SHORT_METHOD_TAGS[e.method or "QUEST"] or ""
        if isRecipeMode then
            local rKey = panel:MakeRecipeFavoriteKey(e.prof, e.name, e.id)
            local isFav = panel:IsRecipeFavorite(rKey)
            if cell.FavBtn and cell.FavBtn.Text then
                cell.FavBtn.Text:SetFont(STANDARD_FONT, math.max(11, math.floor(13 * wScale + 0.5)), "OUTLINE")
                cell.FavBtn.Text:SetText(isFav and "|cffffd100★|r" or "|cff777777☆|r")
            end
            local knownStar = (e.knownByText and e.knownByText ~= "") and "|cff00ff00✓ |r" or ""
            cell.Title:SetText(string.format("%s|cffffd100%s|r", knownStar, e.name))
            cell.Meta:SetText(string.format("|cff00ff96Skill %d|r • |cff00ffff%s|r • %s", e.reqRank or 1, e.prof or "Recipe", shortBadge))
        else
            local isFav = panel:IsItemFavorite(e.id)
            if cell.FavBtn and cell.FavBtn.Text then
                cell.FavBtn.Text:SetFont(STANDARD_FONT, math.max(11, math.floor(13 * wScale + 0.5)), "OUTLINE")
                cell.FavBtn.Text:SetText(isFav and "|cffffd100★|r" or "|cff777777☆|r")
            end
            local hex = QUALITY_HEX[e.quality or 3] or "0070dd"
            cell.Title:SetText(string.format("|cff%s%s|r", hex, e.name))
            cell.Meta:SetText(string.format("|cff00ff96Lvl %d|r • |cffcccccc%s (#%d)|r • %s",
                e.reqLvl or 1, e.subType or "Gear", e.id or 0, shortBadge))
        end

        cell.SourceSub:SetText(string.format("|cff3399ffA:|r |cffffffff%s|r  |cffff3333H:|r |cffffffff%s|r",
            tostring(e.alliance or "—"), tostring(e.horde or "—")))

        cell:Show()
    end

    local totalRows = math.ceil(maxCells / numCols)
    panel.ScrollChild:SetSize(contentWidth, math.max(200, (totalRows * (cellH + 4)) + 30))
    if panel.ScrollFrame and panel.ScrollFrame.UpdateScrollChildRect then
        pcall(panel.ScrollFrame.UpdateScrollChildRect, panel.ScrollFrame)
    end
end

-- Chain into MainPanel's lifecycle callbacks without overwriting NetHeader!
local prevBeforeRender = MainPanel.OnBeforeRenderActivePane
MainPanel.OnBeforeRenderActivePane = function(self, mode)
    AcqDropdownMenu:Hide()
    HideAllAcqGridCells()
    if prevBeforeRender then prevBeforeRender(self, mode) end
    if mode == "QUEST_FOR_ITEM" or mode == "QUEST_FOR_RECIPE" then
        SyncQuestAcqHeaderControls(mode)
        local bScale = self:GetButtonScale()
        local leftX = self:GetLeftColumnOffset()
        local baseTopY = self:GetBaseContentTopY()
        ScaleQuestAcqHeader(self, bScale, leftX, baseTopY)
    else
        QuestAcqHeader:Hide()
    end
end

local prevApplyScaling = MainPanel.OnApplyExternalScaling
MainPanel.OnApplyExternalScaling = function(panel, bScale, leftX, baseTopY)
    if prevApplyScaling then prevApplyScaling(panel, bScale, leftX, baseTopY) end
    local mode = panel:GetActiveViewMode()
    if mode == "QUEST_FOR_ITEM" or mode == "QUEST_FOR_RECIPE" then
        ScaleQuestAcqHeader(panel, bScale, leftX, baseTopY)
    end
end

-- ============================================================================
-- BLOCK HEADING: METHOD BADGE & FACTION FILTER HELPERS
-- ============================================================================
local METHOD_BADGES = {
    ["QUEST"]   = "|TInterface\\GossipFrame\\AvailableQuestIcon:13:13|t |cffffd100[QUEST REWARD]|r",
    ["VENDOR"]  = "|TInterface\\GossipFrame\\VendorGossipIcon:13:13|t |cff00ff96[VENDOR / REAL]|r",
    ["REP"]     = "|TInterface\\GossipFrame\\BattleMasterGossipIcon:13:13|t |cffff8000[FACTION / PVP]|r",
    ["TRAINER"] = "|TInterface\\GossipFrame\\TrainerGossipIcon:13:13|t |cff00ccff[TRAINER]|r",
    ["BOSS"]    = "|cffff5555[BOSS / DUNGEON]|r",
    ["DROP"]    = "|cffff5555[BOSS / DROP]|r",
    ["CRAFT"]   = "|cff66ccff[CRAFTED / BOE]|r",
}

local function PassesFactionFilter(allianceText, hordeText, facToken)
    if not facToken or facToken == "BOTH" then return true end
    local aLow = string.lower(allianceText or "")
    local hLow = string.lower(hordeText or "")
    local isHordeOnly = (string.find(aLow, "horde exclusive") ~= nil) or (string.find(aLow, "horde-only") ~= nil)
    local isAllyOnly  = (string.find(hLow, "alliance exclusive") ~= nil) or (string.find(hLow, "alliance-only") ~= nil)

    if facToken == "ALLIANCE" then
        return not isHordeOnly
    elseif facToken == "HORDE" then
        return not isAllyOnly
    elseif facToken == "ALLIANCE_ONLY" then
        return isAllyOnly
    elseif facToken == "HORDE_ONLY" then
        return isHordeOnly
    end
    return true
end

local function PassesItemCategoryFilter(catToken, subType, equipLoc, method, q, itemName)
    if not catToken or catToken == "ALL" then return true end
    local st = tostring(subType or "")
    local eq = tostring(equipLoc or "")
    local nLow = string.lower(tostring(itemName or ""))

    if catToken == "WEAPON" then
        return eq == "INVTYPE_WEAPON" or eq == "INVTYPE_2HWEAPON" or eq == "INVTYPE_WEAPONMAINHAND"
            or eq == "INVTYPE_WEAPONOFFHAND" or eq == "INVTYPE_HOLDABLE" or eq == "INVTYPE_SHIELD"
            or eq == "INVTYPE_RANGED" or eq == "INVTYPE_RANGEDRIGHT" or string.find(st, "Sword")
            or string.find(st, "Axe") or string.find(st, "Mace") or string.find(st, "Staff")
            or string.find(st, "Dagger") or string.find(st, "Bow") or string.find(st, "Gun") or string.find(st, "Wand")
            or string.find(st, "Shield")
    elseif catToken == "Plate" or catToken == "Mail" or catToken == "Leather" then
        return string.find(st, catToken, 1, true) ~= nil
    elseif catToken == "Cloth" then
        return string.find(st, "Cloth", 1, true) ~= nil or eq == "INVTYPE_CLOAK" or string.find(st, "Cloak", 1, true) ~= nil
    elseif catToken == "JEWELRY" then
        return eq == "INVTYPE_NECK" or eq == "INVTYPE_FINGER" or eq == "INVTYPE_TRINKET"
            or string.find(st, "Neck") or string.find(st, "Finger") or string.find(st, "Trinket") or string.find(st, "Ring")
    elseif catToken == "COLLECT" then
        return string.find(st, "Mount") or string.find(st, "Companion") or string.find(st, "Tabard")
            or eq == "INVTYPE_TABARD" or string.find(nLow, "tabard") or string.find(nLow, "reins") or string.find(nLow, "bridle")
    elseif catToken == "QUEST_LEG" then
        return method == "QUEST" or (q and q >= 5) or string.find(st, "Quest")
    end
    return true
end

-- ============================================================================
-- BLOCK HEADING: FULL IN-PANE ACQUISITION DOSSIER VIEW (FOR ITEMS & RECIPES)
-- ============================================================================
local function RenderItemAcquisitionDossier(panel, entry)
    local rows = {}
    table.insert(rows, {
        tint = "SPEC_HEADER",
        text = "|cffffd100[<< Click Here to Return to 'Quest for Item' Search Results]|r",
        onClickAction = function()
            acqState.inspectedItemEntry = nil
            panel:RenderActivePane()
        end
    })

    local hex = QUALITY_HEX[entry.quality or 3] or "0070dd"
    local link = entry.link or string.format("|cff%s|Hitem:%d:0:0:0:0:0:0:0:60|h[%s]|h|r", hex, entry.id, entry.name)
    local badge = METHOD_BADGES[entry.method or "QUEST"] or ""

    table.insert(rows, {
        icon = entry.icon,
        link = link,
        tint = "UPGRADE_SOON",
        text = string.format("%s  |cff88ccff[Item #%d]|r  %s  —  |cff00ff96[Click Row to Try On in 3D Closet!]|r", link, entry.id, badge),
        onClickAction = function()
            if panel.TryOnItemInTab6 then panel:TryOnItemInTab6(link, entry.name) end
        end
    })

    -- Favorite Toggle + 3D GPS Waypoint Tracking Row
    local isFavNow = panel:IsItemFavorite(entry.id)
    table.insert(rows, {
        tint = isFavNow and "UPGRADE" or "RECOMMEND",
        onClickAction = function()
            local nowFav = panel:ToggleItemFavorite(entry.id, entry)
            SyncQuestAcqHeaderControls("QUEST_FOR_ITEM")
            print(string.format("|cff00ccff[AltVault]|r %s %s Favorites.", entry.name or ("Item #" .. entry.id), nowFav and "|cff00ff00added to|r" or "|cffff6666removed from|r"))
            panel:RenderActivePane()
        end,
        onRightClickAction = function()
            if ns.ForeverIndex and ns.ForeverIndex.GuideToItem then
                ns.ForeverIndex:GuideToItem(entry.id)
            end
        end,
        text = isFavNow
            and "  |cffffd100★ IN YOUR FAVORITES LIST|r — |cffff8888[Left-Click: Remove from Favorites]|r   •   |cff00ccff[Right-Click: Track 3D GPS Waypoint]|r"
            or  "  |cffaaaaaa☆ Not Favorited|r — |cffffd100[Left-Click: ★ Add to Favorites List]|r   •   |cff00ccff[Right-Click: Track 3D GPS Waypoint]|r"
    })

    if ns.ForeverIndex and ns.ForeverIndex.GetItemSourceAndCoords then
        local src = ns.ForeverIndex:GetItemSourceAndCoords(entry.id)
        if src then
            local coordStr = (src.x and src.y and src.x > 0) and string.format(" (%.1f, %.1f)", src.x, src.y) or ""
            table.insert(rows, {
                tint = "RECOMMEND",
                onClickAction = function()
                    ns.ForeverIndex:GuideToItem(entry.id)
                end,
                text = string.format("  |cff00ccff📍 Forever GPS Source:|r |cffffffff%s — %s%s|r  |cff00ff96[Click to Launch 3D Waypoint Guide]|r",
                    src.npc or "Source", src.zone or "Azeroth", coordStr)
            })
        end
    end

    table.insert(rows, {
        text = string.format("  |cffccccccSlot / Type:|r |cffffffff%s|r   •   |cffccccccRequired Level:|r |cffffffff%d|r   •   |cffccccccItem Level:|r |cffffffff%d|r",
            entry.subType or "Item", entry.reqLvl or 1, entry.iLvl or 1)
    })
    table.insert(rows, { text = " " })

    -- ALLIANCE ACQUISITION SECTION
    table.insert(rows, {
        tint = "SPEC_HEADER",
        text = "|cff3399ff[ALLIANCE ACQUISITION — QUESTS, VENDORS & LOCATIONS]:|r"
    })
    local allyList = entry.allAllianceLines or { entry.alliance }
    for _, line in ipairs(allyList) do
        table.insert(rows, {
            tint = "PROF",
            text = "  |cff3399ff• [Alliance]:|r |cffffffff" .. tostring(line) .. "|r"
        })
    end

    table.insert(rows, { text = " " })

    -- HORDE ACQUISITION SECTION
    table.insert(rows, {
        tint = "SPEC_HEADER",
        text = "|cffff3333[HORDE ACQUISITION — QUESTS, VENDORS & LOCATIONS]:|r"
    })
    local hordeList = entry.allHordeLines or { entry.horde }
    for _, line in ipairs(hordeList) do
        table.insert(rows, {
            tint = "UPGRADE",
            text = "  |cffff3333• [Horde]:|r |cffffffff" .. tostring(line) .. "|r"
        })
    end

    -- Check full dossier stats if available
    if ns.Scanner and ns.Scanner.GetItemFullDossier then
        local d = ns.Scanner.GetItemFullDossier(entry.id)
        if d and d.loaded and d.statLines and #d.statLines > 0 then
            table.insert(rows, { text = " " })
            table.insert(rows, {
                tint = "SPEC_HEADER",
                text = "|cffffd100[ITEM ATTRIBUTES & TOOLTIP STATS]:|r"
            })
            for _, sLine in ipairs(d.statLines) do
                table.insert(rows, { text = "  • " .. sLine })
            end
        end
    end

    panel:RenderRowList(rows)
end

local function RenderRecipeAcquisitionDossier(panel, entry)
    local rows = {}
    table.insert(rows, {
        tint = "SPEC_HEADER",
        text = "|cffffd100[<< Click Here to Return to 'Quest for Recipe' Search Results]|r",
        onClickAction = function()
            acqState.inspectedRecipeEntry = nil
            panel:RenderActivePane()
        end
    })

    local badge = METHOD_BADGES[entry.method or "TRAINER"] or ""
    table.insert(rows, {
        icon = entry.icon,
        link = entry.link,
        tint = "UPGRADE_SOON",
        text = string.format("|cffffd100%s|r  |cff88ccff[%s #%d]|r  %s  —  |cff00ff96[Click to Preview / Try On]|r", entry.name, entry.idType or "Recipe", entry.id or 0, badge),
        onClickAction = function()
            if entry.link and panel.TryOnItemInTab6 then
                panel:TryOnItemInTab6(entry.link, entry.name)
            end
        end
    })

    local rKey = panel:MakeRecipeFavoriteKey(entry.prof, entry.name, entry.id)
    local isFavNow = panel:IsRecipeFavorite(rKey)
    table.insert(rows, {
        tint = isFavNow and "UPGRADE" or "RECOMMEND",
        onClickAction = function()
            local nowFav = panel:ToggleRecipeFavorite(rKey, entry)
            SyncQuestAcqHeaderControls("QUEST_FOR_RECIPE")
            print(string.format("|cff00ccff[AltVault]|r %s %s Recipe Favorites.", entry.name or "Recipe", nowFav and "|cff00ff00added to|r" or "|cffff6666removed from|r"))
            panel:RenderActivePane()
        end,
        onRightClickAction = function()
            if entry.id and entry.id > 0 and ns.ForeverIndex and ns.ForeverIndex.GuideToItem then
                ns.ForeverIndex:GuideToItem(entry.id)
            end
        end,
        text = isFavNow
            and "  |cffffd100★ IN YOUR RECIPE FAVORITES LIST|r — |cffff8888[Left-Click: Remove from Favorites]|r   •   |cff00ccff[Right-Click: Track 3D GPS Waypoint]|r"
            or  "  |cffaaaaaa☆ Not Favorited|r — |cffffd100[Left-Click: ★ Add Recipe to Favorites List]|r   •   |cff00ccff[Right-Click: Track 3D GPS Waypoint]|r"
    })

    table.insert(rows, {
        text = string.format("  |cffccccccProfession:|r |cff00ffff%s|r   •   |cffccccccRequired Skill:|r |cffffff00%d|r   •   |cffccccccCategory:|r |cffffffff%s|r",
            entry.prof or "Profession", entry.reqRank or 1, entry.subCategory or "Recipe")
    })

    if entry.knownByText and entry.knownByText ~= "" then
        table.insert(rows, {
            tint = "UPGRADE",
            text = "  |cff00ff00* Known By Your Alts / Network:|r " .. entry.knownByText
        })
    end

    table.insert(rows, { text = " " })
    table.insert(rows, {
        tint = "SPEC_HEADER",
        text = "|cff3399ff[ALLIANCE RECIPE ACQUISITION — VENDOR, QUEST OR TRAINER]:|r"
    })
    table.insert(rows, {
        tint = "PROF",
        text = "  |cff3399ff• [Alliance]:|r |cffffffff" .. tostring(entry.alliance) .. "|r"
    })

    table.insert(rows, { text = " " })
    table.insert(rows, {
        tint = "SPEC_HEADER",
        text = "|cffff3333[HORDE RECIPE ACQUISITION — VENDOR, QUEST OR TRAINER]:|r"
    })
    table.insert(rows, {
        tint = "UPGRADE",
        text = "  |cffff3333• [Horde]:|r |cffffffff" .. tostring(entry.horde) .. "|r"
    })

    if entry.reagentSummary and entry.reagentSummary ~= "" then
        table.insert(rows, { text = " " })
        table.insert(rows, {
            tint = "SPEC_HEADER",
            text = "|cffffd100[REQUIRED CRAFTING REAGENTS]:|r"
        })
        table.insert(rows, {
            text = "  • " .. entry.reagentSummary
        })
    end

    panel:RenderRowList(rows)
end

-- ============================================================================
-- BLOCK HEADING: TAB RENDERER 1 — "QUEST FOR ITEM"
-- ============================================================================
local function GetFastItemIcon(itemID, cached, fallbackName)
    if cached and (cached.ic or cached.i) then
        return cached.ic or cached.i
    end
    if itemID then
        if GetItemInfoInstant then
            local _, _, _, _, instantIcon = GetItemInfoInstant(itemID)
            if instantIcon then return instantIcon end
        end
        if C_Item and C_Item.GetItemIconByID then
            local ic = C_Item.GetItemIconByID(itemID)
            if ic then return ic end
        elseif GetItemIcon then
            local ic = GetItemIcon(itemID)
            if ic then return ic end
        end
    end
    if type(fallbackName) == "string" and string.find(fallbackName, "^Interface\\") then
        return string.gsub(fallbackName, "\\\\", "\\")
    end
    return "Interface\\Icons\\INV_Misc_QuestionMark"
end

-- Cross-Tab Bridge: Jump directly to an Item's Questline / Acquisition Dossier from Dressing Room or Favorites!
function AcquisitionDB:OpenItemQuestlineDossier(itemID, defaultName)
    if not itemID then return end
    local cached = AltVaultDB and AltVaultDB.ItemCache and AltVaultDB.ItemCache[itemID]
    local fInfo = ns.ForeverIndex and ns.ForeverIndex.Info and ns.ForeverIndex:Info(itemID)
    local name = (cached and cached.n) or (fInfo and fInfo.name) or defaultName or ("Item #" .. tostring(itemID))
    local quality = (cached and cached.q) or (fInfo and fInfo.quality) or 3
    local subType = (cached and cached.st and cached.st ~= "" and cached.st) or (fInfo and fInfo.itemSubType) or "Equipment"
    local reqLvl = (cached and cached.r and cached.r > 0 and cached.r) or (fInfo and fInfo.reqLevel) or 1
    local iLvl = (cached and cached.l and cached.l > 0 and cached.l) or (fInfo and fInfo.itemLevel) or reqLvl
    local icon = GetFastItemIcon(itemID, cached)
    local hex = QUALITY_HEX[quality] or "0070dd"
    local link = string.format("|cff%s|Hitem:%d:0:0:0:0:0:0:0:60|h[%s]|h|r", hex, itemID, name)
    local allyLine, hordeLine, method, allAlly, allHorde = self:GetItemDualFactionSummary(itemID, name)

    acqState.showItemFavoritesOnly = false
    acqState.inspectedItemEntry = {
        id = itemID,
        name = name,
        link = link,
        icon = icon,
        quality = quality,
        subType = subType,
        reqLvl = reqLvl,
        iLvl = iLvl,
        method = method,
        alliance = allyLine,
        horde = hordeLine,
        allAllianceLines = allAlly,
        allHordeLines = allHorde,
    }
    if MainPanel.SwitchToTab then
        MainPanel:SwitchToTab("QUEST_FOR_ITEM")
    else
        MainPanel:RenderActivePane()
    end
end

local function RenderQuestForItemTab(panel)
    HideAllAcqGridCells()
    SyncQuestAcqHeaderControls("QUEST_FOR_ITEM")
    ScaleQuestAcqHeader(panel, panel:GetButtonScale(), panel:GetLeftColumnOffset(), panel:GetBaseContentTopY())
    if acqState.inspectedItemEntry then
        RenderItemAcquisitionDossier(panel, acqState.inspectedItemEntry)
        return
    end

    if ns.MasterDB and ns.MasterDB.EnsureIndexesBuilt then
        ns.MasterDB:EnsureIndexesBuilt()
    end

    -- Favorites Mode: Clear regular items and display itemized Favorites list with full actions!
    if acqState.showItemFavoritesOnly then
        local rows = {}
        local favDB = panel:EnsureFavoritesDB()
        local favList = {}
        for idKey, meta in pairs(favDB.items) do
            local numID = tonumber(idKey) or (type(meta) == "table" and tonumber(meta.id))
            if numID and meta then
                local cached = AltVaultDB and AltVaultDB.ItemCache and AltVaultDB.ItemCache[numID]
                local fInfo = ns.ForeverIndex and ns.ForeverIndex.Info and ns.ForeverIndex:Info(numID)
                local name = (type(meta) == "table" and meta.name) or (cached and cached.n) or (fInfo and fInfo.name) or ("Item #" .. numID)
                local quality = (type(meta) == "table" and meta.quality) or (cached and cached.q) or (fInfo and fInfo.quality) or 3
                local subType = (type(meta) == "table" and meta.subType) or (cached and cached.st) or (fInfo and fInfo.itemSubType) or "Equipment"
                local reqLvl = (type(meta) == "table" and meta.reqLvl) or (cached and cached.r) or (fInfo and fInfo.reqLevel) or 1
                local iLvl = (type(meta) == "table" and meta.iLvl) or (cached and cached.l) or (fInfo and fInfo.itemLevel) or reqLvl
                local icon = (type(meta) == "table" and meta.icon) or GetFastItemIcon(numID, cached)
                local hex = QUALITY_HEX[quality] or "0070dd"
                local link = string.format("|cff%s|Hitem:%d:0:0:0:0:0:0:0:60|h[%s]|h|r", hex, numID, name)
                local allyLine, hordeLine, method, allAlly, allHorde = AcquisitionDB:GetItemDualFactionSummary(numID, name)
                if not panel.DoesQualityPassMask or panel:DoesQualityPassMask(quality, acqState.qualities) then
                    table.insert(favList, {
                        id = numID,
                        name = name,
                        link = link,
                        icon = icon,
                        quality = quality,
                        subType = subType,
                        reqLvl = reqLvl,
                        iLvl = iLvl,
                        method = method,
                        alliance = allyLine,
                        horde = hordeLine,
                        allAllianceLines = allAlly,
                        allHordeLines = allHorde,
                    })
                end
            end
        end
        table.sort(favList, function(a, b)
            local rA, rB = (a.reqLvl or 1), (b.reqLvl or 1)
            if rA ~= rB then return rA < rB end
            local lA, lB = (a.iLvl or 1), (b.iLvl or 1)
            if lA ~= lB then return lA < lB end
            if (a.quality or 1) ~= (b.quality or 1) then return (a.quality or 1) > (b.quality or 1) end
            return (a.name or "") < (b.name or "")
        end)

        UpdateAcqPaginationControls("QUEST_FOR_ITEM", #favList)
        local perPage = panel:GetPerPageSize()
        local page = acqState.itemPage or 1
        local startIdx = ((page - 1) * perPage) + 1
        local endIdx = math.min(#favList, page * perPage)

        table.insert(rows, {
            tint = "SPEC_HEADER",
            onClickAction = function()
                acqState.showItemFavoritesOnly = false
                acqState.itemPage = 1
                SyncQuestAcqHeaderControls("QUEST_FOR_ITEM")
                panel:RenderActivePane()
            end,
            text = string.format("|cffffd100★ FAVORITE ITEMS LIST (%d Saved • Page %d/%d) — Click [★ Favs: ON] or this banner to return to 'Quest for Item'|r",
                #favList, page, acqState.itemTotalPages or 1)
        })

        if #favList == 0 then
            table.insert(rows, {
                text = "  |cff888888Your Item Favorites list is empty (or filtered out by Quality). Click the [☆] star on any item card (or Alt+Click any item) to save it here!|r"
            })
            panel:RenderRowList(rows)
            return
        end

        for i = startIdx, endIdx do
            local c = favList[i]
            local badge = METHOD_BADGES[c.method] or ""
            local rowText = string.format(
                "|cffffd100★|r |cff00ff96[Lvl %d]|r %s  |cff88ccff[#%d]|r  |cffcccccc(%s)|r  %s\n     |cff3399ff[Alliance]:|r |cffffffff%s|r\n     |cffff3333[Horde]:|r    |cffffffff%s|r",
                c.reqLvl or 1, c.link, c.id, c.subType, badge, c.alliance, c.horde
            )
            table.insert(rows, {
                icon = c.icon,
                link = c.link,
                onClickAction = function()
                    acqState.inspectedItemEntry = c
                    panel:RenderActivePane()
                end,
                onRightClickAction = function()
                    if panel.TryOnItemInTab6 then
                        panel:TryOnItemInTab6(c.link, c.name)
                    end
                end,
                onAltClickAction = function()
                    panel:ToggleItemFavorite(c.id, c)
                    SyncQuestAcqHeaderControls("QUEST_FOR_ITEM")
                    panel:RenderActivePane()
                end,
                text = rowText,
            })

            -- Action Toolbar Sub-Row: Open Questline Dossier, Try On, Track GPS, Unfavorite
            table.insert(rows, {
                tint = "RECOMMEND",
                onClickAction = function()
                    acqState.inspectedItemEntry = c
                    panel:RenderActivePane()
                end,
                onRightClickAction = function()
                    if ns.ForeverIndex and ns.ForeverIndex.GuideToItem then
                        ns.ForeverIndex:GuideToItem(c.id)
                    end
                end,
                onAltClickAction = function()
                    panel:ToggleItemFavorite(c.id, c)
                    SyncQuestAcqHeaderControls("QUEST_FOR_ITEM")
                    panel:RenderActivePane()
                end,
                text = "     |cffffd100↳ Actions:|r |cff00ff96[Left-Click: Open Questline Dossier (Right-Click Item Row: Try On)]|r   •   |cff00ccff[Right-Click: Track 3D GPS Waypoint]|r   •   |cffff8888[Alt+Click: Remove ★]|r"
            })
        end

        panel:RenderRowList(rows)
        return
    end

    local qLow = string.lower(acqState.itemSearchText or "")
    local numericQuery = tonumber(qLow)
    local minLvl = acqState.itemMinLvl
    local maxLvl = acqState.itemMaxLvl
    local srcToken = (ITEM_SOURCE_FILTERS[acqState.itemSourceIdx] or ITEM_SOURCE_FILTERS[1]).token
    local catToken = (ITEM_CATEGORY_FILTERS[acqState.itemCatIdx] or ITEM_CATEGORY_FILTERS[1]).token
    local facToken = (FACTION_FILTERS[acqState.itemFactionIdx] or FACTION_FILTERS[1]).token

    local seenIDs = {}
    local candidates = {}
    local maxCandidateCap = 1600

    local function EvaluateCandidateItem(itemID, defaultName, defaultSlot, defaultReqLvl, defaultQ)
        if not itemID or seenIDs[itemID] then return end
        if #candidates >= maxCandidateCap then return end
        -- Skip recipe patterns in Quest for Item (they belong in Quest for Recipe!)
        if AltVaultDB and AltVaultDB.PatternDB and AltVaultDB.PatternDB[itemID] then return end

        local cached = AltVaultDB and AltVaultDB.ItemCache and AltVaultDB.ItemCache[itemID]
        if cached and cached.c == 9 then return end

        local fInfo = ns.ForeverIndex and ns.ForeverIndex.Info and ns.ForeverIndex:Info(itemID)
        local name = (cached and cached.n) or (fInfo and fInfo.name) or defaultName
        if not name or name == "" then
            if C_Item and C_Item.GetItemNameByID then
                name = C_Item.GetItemNameByID(itemID)
            end
        end
        if not name or name == "" then return end

        local nLow = string.lower(name)
        -- Skip non-item texture paths / faction icon rows / internal test items / recipe patterns
        if string.find(nLow, "^interface\\") or defaultSlot == "Faction_type" or defaultSlot == "Argent Crusade" then
            return
        end
        if string.find(nLow, "deprecated") or string.find(nLow, "gamemaster") or string.find(nLow, "monster -") or string.find(nLow, "^test ") then
            return
        end
        if string.find(nLow, "^recipe:") or string.find(nLow, "^pattern:") or string.find(nLow, "^plans:")
            or string.find(nLow, "^schematic:") or string.find(nLow, "^formula:") then
            return
        end

        -- Ensure item has a valid local client icon (via GetItemInfoInstant / ItemCache / ForeverIndex)
        local instItemID, instType, instSubType, instEquipLoc, instIcon, instClassID, instSubClassID
        if GetItemInfoInstant then
            instItemID, instType, instSubType, instEquipLoc, instIcon, instClassID, instSubClassID = GetItemInfoInstant(itemID)
        end
        local isForeverClient = (select(4, GetBuildInfo()) == 16001)
        if not instItemID and not cached and (not isForeverClient or itemID < 200000) then
            -- Item ID does not exist in this client's local DBC (e.g. Forever 270k+ item when logged into Classic Era)
            return
        end

        local equipLocCheck = (cached and cached.eq) or (fInfo and fInfo.equipLoc) or instEquipLoc or ""
        -- Unless user explicitly chose "Type: Quest & Legendaries" (QUEST_LEG), hide non-equippable quest objective drops (severed heads/paws/pages) and junk
        if catToken ~= "QUEST_LEG" and equipLocCheck == "" then
            if instClassID == 12 or instType == "Quest" or defaultSlot == "Quest" or defaultSlot == "Junk" then
                return
            end
            if instClassID == 15 and instSubClassID == 0 then
                return
            end
        end

        local quality = (cached and cached.q) or (fInfo and fInfo.quality) or defaultQ or 3
        if panel.DoesQualityPassMask and not panel:DoesQualityPassMask(quality, acqState.qualities) then
            return
        end

        local rawReq = (cached and cached.r and cached.r > 0 and cached.r)
            or (fInfo and fInfo.reqLevel and fInfo.reqLevel > 0 and fInfo.reqLevel)
            or (defaultReqLvl and defaultReqLvl > 0 and defaultReqLvl)
        local rawILvl = (cached and cached.l and cached.l > 0 and cached.l)
            or (fInfo and fInfo.itemLevel and fInfo.itemLevel > 0 and fInfo.itemLevel)
            or rawReq

        local effectiveLvl = 1
        if rawReq and rawReq > 1 then
            effectiveLvl = rawReq
        elseif rawILvl and rawILvl >= 58 then
            effectiveLvl = 60
        elseif rawILvl and rawILvl >= 10 then
            effectiveLvl = rawILvl - 5
        elseif rawILvl and rawILvl >= 1 then
            effectiveLvl = rawILvl
        elseif rawReq and rawReq == 1 then
            effectiveLvl = 1
        end

        -- Strict, unified Min/Max level check
        if minLvl or maxLvl then
            if minLvl and effectiveLvl < minLvl then return end
            if maxLvl and effectiveLvl > maxLvl then return end
        end

        if qLow ~= "" and numericQuery then
            if itemID ~= numericQuery and not string.find(tostring(itemID), qLow, 1, true) then return end
        end

        local subType = (cached and cached.st and cached.st ~= "" and cached.st)
            or (fInfo and fInfo.itemSubType and fInfo.itemSubType ~= "" and fInfo.itemSubType)
            or (instSubType and instSubType ~= "" and instSubType)
            or defaultSlot
            or (cached and cached.t)
            or (fInfo and fInfo.itemType)
            or (instType and instType ~= "" and instType)
            or "Equipment"
        local equipLoc = (cached and cached.eq) or (fInfo and fInfo.equipLoc) or instEquipLoc or ""
        local reqLvl = effectiveLvl or 1
        local iLvl = rawILvl or reqLvl

        local allyLine, hordeLine, method, allAlly, allHorde = AcquisitionDB:GetItemDualFactionSummary(itemID, name)
        if srcToken ~= "ALL" and method ~= srcToken then return end
        if not PassesFactionFilter(allyLine, hordeLine, facToken) then return end
        if not PassesItemCategoryFilter(catToken, subType, equipLoc, method, quality, name) then return end

        if qLow ~= "" and not numericQuery then
            local hay = string.lower(name .. " " .. subType .. " " .. (allyLine or "") .. " " .. (hordeLine or ""))
            if not string.find(hay, qLow, 1, true) then return end
        end

        seenIDs[itemID] = true

        local icon = instIcon or GetFastItemIcon(itemID, cached, name)
        local hex = QUALITY_HEX[quality] or "0070dd"
        local link = string.format("|cff%s|Hitem:%d:0:0:0:0:0:0:0:60|h[%s]|h|r", hex, itemID, name)

        local priority = (CURATED_ITEMS_BY_ID[itemID] and 100)
            or (method == "QUEST" and 80)
            or (method == "VENDOR" and 75)
            or (method == "REP" and 70)
            or (method == "BOSS" and 60)
            or 40

        table.insert(candidates, {
            id = itemID,
            name = name,
            link = link,
            icon = icon,
            quality = quality,
            subType = subType,
            reqLvl = reqLvl,
            iLvl = iLvl,
            method = method,
            alliance = allyLine,
            horde = hordeLine,
            allAllianceLines = allAlly,
            allHordeLines = allHorde,
            priority = priority,
        })
    end

    local function GatherItemCandidates()
        -- 1. Evaluate Curated Quest & Vendor Encyclopedia first
        for _, cur in ipairs(CURATED_QUEST_ITEMS) do
            EvaluateCandidateItem(cur.id, cur.name, cur.slot, cur.reqLvl, cur.q)
        end

        -- 2. Evaluate Live SourceDB items (Quests/Vendors discovered in-game)
        if AltVaultDB and AltVaultDB.SourceDB then
            for itemID in pairs(AltVaultDB.SourceDB) do
                if #candidates >= maxCandidateCap then break end
                if type(itemID) == "number" then
                    EvaluateCandidateItem(itemID, nil, nil, nil, 3)
                end
            end
        end

        -- 3. Evaluate MasterDB Holding Tank Unique Items
        if ns.MasterDB and ns.MasterDB.UniqueItemIDList then
            local cacheTbl = AltVaultDB and AltVaultDB.ItemCache
            for _, itemID in ipairs(ns.MasterDB.UniqueItemIDList) do
                if #candidates >= maxCandidateCap then break end
                local cInfo = cacheTbl and cacheTbl[itemID]
                if cInfo and cInfo.n then
                    EvaluateCandidateItem(itemID, cInfo.n, cInfo.st, cInfo.r, cInfo.q)
                else
                    local recs = ns.MasterDB:GetItemSources(itemID)
                    local firstRec = recs and recs[1]
                    if firstRec and firstRec.Name and firstRec.Name ~= "" then
                        local defSlot = (firstRec.SubSection ~= "" and firstRec.SubSection) or firstRec.Category
                        EvaluateCandidateItem(itemID, firstRec.Name, defSlot, nil, 3)
                    end
                end
            end
        end

        -- 4. Evaluate Scanned ItemCache
        if AltVaultDB and AltVaultDB.ItemCache and #candidates < maxCandidateCap then
            for itemID, info in pairs(AltVaultDB.ItemCache) do
                if #candidates >= maxCandidateCap then break end
                if type(itemID) == "number" and type(info) == "table" and info.n then
                    EvaluateCandidateItem(itemID, info.n, info.st, info.r, info.q)
                end
            end
        end

        -- 5. Supplement from ForeverIndex so Level 1 through Level 60 items are richly represented
        if ns.ForeverIndex and ns.ForeverIndex.GetAllIDs and #candidates < maxCandidateCap then
            local allIDs = ns.ForeverIndex:GetAllIDs()
            for i = 1, #allIDs do
                if #candidates >= maxCandidateCap then break end
                local fid = allIDs[i]
                if fid and not seenIDs[fid] then
                    local fInfo = ns.ForeverIndex:Info(fid)
                    if fInfo and fInfo.name and fInfo.equipLoc and fInfo.equipLoc ~= "" then
                        EvaluateCandidateItem(fid, fInfo.name, fInfo.itemSubType, fInfo.reqLevel, fInfo.quality)
                    end
                end
            end
        end
    end

    GatherItemCandidates()

    -- If My Lvl mode is active and found too few items (< 4), widen slightly so a handful of items always load
    if #candidates < 4 and acqState.itemAutoLevelDefault and qLow == "" then
        local savedMin, savedMax = minLvl, maxLvl
        minLvl = 1
        maxLvl = math.min(60, math.max(25, (savedMax or 10) + 18))
        GatherItemCandidates()
        minLvl, maxLvl = savedMin, savedMax
    end

    -- Sort items starting at Level 1 ascending up to Level 60!
    table.sort(candidates, function(a, b)
        local rA = a.reqLvl or 1
        local rB = b.reqLvl or 1
        if rA ~= rB then return rA < rB end
        local lA = a.iLvl or 1
        local lB = b.iLvl or 1
        if lA ~= lB then return lA < lB end
        if (a.priority or 0) ~= (b.priority or 0) then return (a.priority or 0) > (b.priority or 0) end
        if (a.quality or 1) ~= (b.quality or 1) then return (a.quality or 1) > (b.quality or 1) end
        return (a.name or "") < (b.name or "")
    end)

    UpdateAcqPaginationControls("QUEST_FOR_ITEM", #candidates)
    local perPage = panel:GetPerPageSize()
    local page = acqState.itemPage or 1
    local startIdx = ((page - 1) * perPage) + 1
    local endIdx = math.min(#candidates, page * perPage)

    local pagedCandidates = {}
    for i = startIdx, endIdx do
        table.insert(pagedCandidates, candidates[i])
    end

    if acqState.useGridView and #pagedCandidates > 0 then
        RenderAcqMatchesAsCompactGrid(panel, pagedCandidates, false)
        return
    end

    local rows = {}
    local lvlNote = ""
    if minLvl or maxLvl then
        lvlNote = string.format(" • Lvl %d-%d", minLvl or 1, maxLvl or 60)
    else
        lvlNote = " • Level 1→60 Order"
    end
    table.insert(rows, {
        tint = "SPEC_HEADER",
        text = string.format("|cffffd100Quest for Item — Dual-Faction Acquisition Guide (Showing %d–%d of %d%s • Page %d/%d) — Left-Click: Dossier • Right-Click: Try On • Alt+Click: ★ Fav|r",
            (#pagedCandidates > 0 and startIdx or 0), endIdx, #candidates, lvlNote, page, acqState.itemTotalPages or 1)
    })

    if #candidates == 0 then
        table.insert(rows, { text = "  |cff888888No items matched your search, level, or quality filters. Click [Reset] or [All Qualities] above!|r" })
        panel:RenderRowList(rows)
        return
    end

    for i = 1, #pagedCandidates do
        local c = pagedCandidates[i]
        local badge = METHOD_BADGES[c.method] or ""
        local favStar = panel:IsItemFavorite(c.id) and "|cffffd100★|r " or "|cff666666☆|r "
        local rowText = string.format(
            "%s|cff00ff96[Lvl %d]|r %s  |cff88ccff[#%d]|r  |cffcccccc(%s)|r  %s\n     |cff3399ff[Alliance]:|r |cffffffff%s|r\n     |cffff3333[Horde]:|r    |cffffffff%s|r",
            favStar, c.reqLvl or 1, c.link, c.id, c.subType, badge, c.alliance, c.horde
        )
        local tooltipNote = string.format(
            "|cffffd100Dual-Faction Acquisition Guide:|r\n|cff3399ff• Alliance:|r %s\n|cffff3333• Horde:|r %s\n\n|cff00ff00Left-Click:|r Open Full Dual-Faction Acquisition Dossier\n|cff00ff96Right-Click:|r Try On in 3D Closet\n|cffffd100Alt+Click:|r Toggle ★ Favorite",
            c.alliance, c.horde
        )

        table.insert(rows, {
            icon = c.icon,
            link = c.link,
            recommendNote = tooltipNote,
            onClickAction = function()
                acqState.inspectedItemEntry = c
                panel:RenderActivePane()
            end,
            onRightClickAction = function()
                if panel.TryOnItemInTab6 then
                    panel:TryOnItemInTab6(c.link, c.name)
                end
            end,
            onAltClickAction = function()
                local nowFav = panel:ToggleItemFavorite(c.id, c)
                SyncQuestAcqHeaderControls("QUEST_FOR_ITEM")
                print(string.format("|cff00ccff[AltVault]|r %s %s Favorites.", c.name or ("Item #" .. c.id), nowFav and "|cff00ff00added to|r" or "|cffff6666removed from|r"))
                panel:RenderActivePane()
            end,
            text = rowText,
        })
    end

    panel:RenderRowList(rows)
end

-- ============================================================================
-- BLOCK HEADING: TAB RENDERER 2 — "QUEST FOR RECIPE"
-- ============================================================================
local PROF_ICONS = {
    ["Alchemy"]        = "Interface\\Icons\\Trade_Alchemy",
    ["Blacksmithing"]  = "Interface\\Icons\\Trade_BlackSmithing",
    ["Cooking"]        = "Interface\\Icons\\INV_Misc_Food_15",
    ["Enchanting"]     = "Interface\\Icons\\Trade_Engraving",
    ["Engineering"]    = "Interface\\Icons\\Trade_Engineering",
    ["First Aid"]      = "Interface\\Icons\\Spell_Holy_SealOfSacrifice",
    ["Leatherworking"] = "Interface\\Icons\\Trade_LeatherWorking",
    ["Mining"]         = "Interface\\Icons\\Trade_Mining",
    ["Tailoring"]      = "Interface\\Icons\\Trade_Tailoring",
    ["Rogue Poisons"]  = "Interface\\Icons\\Ability_Poisons",
}

local function FindKnownCraftersForRecipe(cleanRecipeName, craftedItemID)
    local crafters = {}
    local seen = {}
    if craftedItemID and AltVaultDB and AltVaultDB.RecipeDB and AltVaultDB.RecipeDB[craftedItemID] then
        local r = AltVaultDB.RecipeDB[craftedItemID]
        for cName in pairs(r.crafters or {}) do
            if not seen[cName] then seen[cName] = true; table.insert(crafters, cName) end
        end
    end
    if cleanRecipeName and AltVaultDB and AltVaultDB.Characters then
        for charName, charData in pairs(AltVaultDB.Characters) do
            if charData.knownRecipes and charData.knownRecipes[cleanRecipeName] and not seen[charName] then
                seen[charName] = true
                table.insert(crafters, charName)
            end
        end
    end
    table.sort(crafters)
    return table.concat(crafters, ", ")
end

local function RenderQuestForRecipeTab(panel)
    HideAllAcqGridCells()
    SyncQuestAcqHeaderControls("QUEST_FOR_RECIPE")
    ScaleQuestAcqHeader(panel, panel:GetButtonScale(), panel:GetLeftColumnOffset(), panel:GetBaseContentTopY())
    if acqState.inspectedRecipeEntry then
        RenderRecipeAcquisitionDossier(panel, acqState.inspectedRecipeEntry)
        return
    end

    if ns.MasterDB and ns.MasterDB.EnsureIndexesBuilt then
        ns.MasterDB:EnsureIndexesBuilt()
    end

    -- Favorites Mode: Clear regular recipes and render itemized Recipe Favorites list with full actions!
    if acqState.showRecipeFavoritesOnly then
        local rows = {}
        local favDB = panel:EnsureFavoritesDB()
        local favRecipes = {}
        for rKey, meta in pairs(favDB.recipes) do
            if type(meta) == "table" then
                table.insert(favRecipes, {
                    favKey = rKey,
                    idType = meta.idType or "Recipe",
                    id = meta.id or 0,
                    name = meta.name or rKey,
                    link = meta.link,
                    icon = meta.icon or PROF_ICONS[meta.prof or ""] or "Interface\\Icons\\INV_Scroll_03",
                    prof = meta.prof or "Profession",
                    reqRank = meta.reqRank or 1,
                    subCategory = meta.subCategory or meta.prof or "Recipe",
                    method = meta.method or "VENDOR",
                    alliance = meta.alliance or "—",
                    horde = meta.horde or "—",
                    knownByText = FindKnownCraftersForRecipe(meta.name, (meta.idType == "Item") and meta.id or nil),
                })
            end
        end
        table.sort(favRecipes, function(a, b)
            local rA, rB = (a.reqRank or 1), (b.reqRank or 1)
            if rA ~= rB then return rA < rB end
            if (a.prof or "") ~= (b.prof or "") then return (a.prof or "") < (b.prof or "") end
            return (a.name or "") < (b.name or "")
        end)

        UpdateAcqPaginationControls("QUEST_FOR_RECIPE", #favRecipes)
        local perPage = panel:GetPerPageSize()
        local page = acqState.recipePage or 1
        local startIdx = ((page - 1) * perPage) + 1
        local endIdx = math.min(#favRecipes, page * perPage)

        table.insert(rows, {
            tint = "SPEC_HEADER",
            onClickAction = function()
                acqState.showRecipeFavoritesOnly = false
                acqState.recipePage = 1
                SyncQuestAcqHeaderControls("QUEST_FOR_RECIPE")
                panel:RenderActivePane()
            end,
            text = string.format("|cffffd100★ FAVORITE RECIPES LIST (%d Saved • Page %d/%d) — Click [★ Favs: ON] or this banner to return to 'Quest for Recipe'|r",
                #favRecipes, page, acqState.recipeTotalPages or 1)
        })

        if #favRecipes == 0 then
            table.insert(rows, {
                text = "  |cff888888Your Recipe Favorites list is empty. Click the [☆] star on any recipe card (or Alt+Click any recipe) to save it here!|r"
            })
            panel:RenderRowList(rows)
            return
        end

        for i = startIdx, endIdx do
            local r = favRecipes[i]
            local badge = METHOD_BADGES[r.method] or ""
            local titleStr = r.link or ("|cffffd100[" .. r.name .. "]|r")
            local knownBadge = (r.knownByText and r.knownByText ~= "")
                and ("  |cff00ff00[* Known: " .. r.knownByText .. "]|r")
                or ""
            local rowText = string.format(
                "|cffffd100★|r |cff00ff96[Skill %d]|r %s  |cff00ffff(%s)|r  %s%s\n     |cff3399ff[Alliance]:|r |cffffffff%s|r\n     |cffff3333[Horde]:|r    |cffffffff%s|r",
                r.reqRank or 1, titleStr, r.prof, badge, knownBadge, r.alliance, r.horde
            )
            table.insert(rows, {
                icon = r.icon,
                link = r.link,
                onClickAction = function()
                    acqState.inspectedRecipeEntry = r
                    panel:RenderActivePane()
                end,
                onRightClickAction = function()
                    if r.link and panel.TryOnItemInTab6 then
                        panel:TryOnItemInTab6(r.link, r.name)
                    end
                end,
                onAltClickAction = function()
                    panel:ToggleRecipeFavorite(r.favKey, r)
                    SyncQuestAcqHeaderControls("QUEST_FOR_RECIPE")
                    panel:RenderActivePane()
                end,
                text = rowText,
            })

            table.insert(rows, {
                tint = "RECOMMEND",
                onClickAction = function()
                    acqState.inspectedRecipeEntry = r
                    panel:RenderActivePane()
                end,
                onRightClickAction = function()
                    if r.id and r.id > 0 and ns.ForeverIndex and ns.ForeverIndex.GuideToItem then
                        ns.ForeverIndex:GuideToItem(r.id)
                    end
                end,
                onAltClickAction = function()
                    panel:ToggleRecipeFavorite(r.favKey, r)
                    SyncQuestAcqHeaderControls("QUEST_FOR_RECIPE")
                    panel:RenderActivePane()
                end,
                text = "     |cffffd100↳ Actions:|r |cff00ff96[Left-Click: Open Full Recipe Dossier (Right-Click Row: Try On)]|r   •   |cff00ccff[Right-Click: Track 3D GPS]|r   •   |cffff8888[Alt+Click: Remove ★]|r"
            })
        end

        panel:RenderRowList(rows)
        return
    end

    local qLow = string.lower(acqState.recipeSearchText or "")
    local numericQuery = tonumber(qLow)
    local minLvl = acqState.recipeMinLvl
    local maxLvl = acqState.recipeMaxLvl
    local methodToken = (RECIPE_METHOD_FILTERS[acqState.recipeMethodIdx] or RECIPE_METHOD_FILTERS[1]).token
    local profToken   = (RECIPE_PROF_FILTERS[acqState.recipeProfIdx] or RECIPE_PROF_FILTERS[1]).token
    local facToken    = (FACTION_FILTERS[acqState.recipeFactionIdx] or FACTION_FILTERS[1]).token

    local seenKeys = {}
    local recipes = {}

    local function AddCandidateRecipe(idType, numID, rawName, profName, reqRank, subCat, patternItemID, masterRecords, reagentSummary)
        if not rawName or rawName == "" then return end
        -- Extract embedded "/ 225" skill rank if present in MasterDB Spell names
        local parsedName, parsedRank = string.match(rawName, "^(.-)%s*/%s*(%d+)$")
        local cleanName = parsedName or rawName
        local skillRank = tonumber(reqRank) or tonumber(parsedRank) or 1
        profName = profName or "Profession"

        -- Normalize profession name
        if string.find(profName, "Poisons") then profName = "Rogue Poisons" end

        local dedupeKey = string.lower(profName .. ":" .. cleanName)
        if seenKeys[dedupeKey] then return end

        local method, allyLine, hordeLine, resolvedRank, resolvedProf =
            AcquisitionDB:ResolveRecipeDualFaction(cleanName, profName, skillRank, patternItemID, masterRecords)

        profName = resolvedProf or profName
        skillRank = tonumber(resolvedRank) or skillRank
        local estCharLvl = math.max(1, math.min(60, math.ceil(skillRank / 5)))

        if minLvl then
            -- Support both Skill Rank (1-300) and Character Level (1-60) filtering seamlessly
            if skillRank < minLvl and estCharLvl < minLvl then return end
        end
        if maxLvl then
            if maxLvl <= 60 then
                -- If user typed <= 60 (e.g. Max Lvl 35), match either skillRank <= 35 OR estCharLvl <= 35
                if skillRank > maxLvl and estCharLvl > maxLvl then return end
            else
                if skillRank > maxLvl then return end
            end
        end

        if profToken ~= "ALL" and profName ~= profToken then return end
        if methodToken ~= "ALL" and method ~= methodToken then return end
        if not PassesFactionFilter(allyLine, hordeLine, facToken) then return end

        local patCached = patternItemID and AltVaultDB and AltVaultDB.ItemCache and AltVaultDB.ItemCache[patternItemID]
        local itemCached = (idType == "Item" and numID) and AltVaultDB and AltVaultDB.ItemCache and AltVaultDB.ItemCache[numID]
        local rQuality = (patCached and patCached.q)
            or (itemCached and itemCached.q)
            or (method == "TRAINER" and 1)
            or (method == "REP" and 3)
            or (method == "DROP" and 3)
            or 2
        if panel.DoesQualityPassMask and not panel:DoesQualityPassMask(rQuality, acqState.qualities) then
            return
        end

        if qLow ~= "" then
            if numericQuery then
                if numID ~= numericQuery and patternItemID ~= numericQuery and not string.find(tostring(numID or ""), qLow, 1, true) then
                    return
                end
            else
                local hay = string.lower(cleanName .. " " .. profName .. " " .. (subCat or "") .. " " .. (allyLine or "") .. " " .. (hordeLine or ""))
                if not string.find(hay, qLow, 1, true) then return end
            end
        end

        seenKeys[dedupeKey] = true

        local icon = (patternItemID and (patCached and (patCached.ic or patCached.i) or (C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(patternItemID))))
            or (idType == "Item" and numID and (itemCached and (itemCached.ic or itemCached.i) or (C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(numID))))
            or PROF_ICONS[profName]
            or "Interface\\Icons\\INV_Scroll_03"

        local link = nil
        if patternItemID then
            local hex = QUALITY_HEX[(patCached and patCached.q) or rQuality] or "1eff00"
            link = string.format("|cff%s|Hitem:%d:0:0:0:0:0:0:0:60|h[%s]|h|r", hex, patternItemID, cleanName)
        elseif idType == "Item" and numID then
            local hex = QUALITY_HEX[(itemCached and itemCached.q) or rQuality] or "1eff00"
            link = string.format("|cff%s|Hitem:%d:0:0:0:0:0:0:0:60|h[%s]|h|r", hex, numID, cleanName)
        end

        local knownBy = FindKnownCraftersForRecipe(cleanName, (idType == "Item") and numID or nil)
        local priority = (method == "QUEST" and 95)
            or (method == "VENDOR" and 90)
            or (method == "REP" and 85)
            or (method == "DROP" and 80)
            or 50

        table.insert(recipes, {
            idType = idType or "Recipe",
            id = numID or 0,
            name = cleanName,
            link = link,
            icon = icon,
            quality = rQuality,
            prof = profName,
            reqRank = skillRank,
            subCategory = subCat or profName,
            method = method,
            alliance = allyLine,
            horde = hordeLine,
            knownByText = knownBy,
            reagentSummary = reagentSummary,
            priority = priority,
        })
    end

    local function GatherRecipeCandidates()
        -- 1. Load PatternDB items (actual Recipe/Plans/Pattern/Schematic/Formula items)
        if AltVaultDB and AltVaultDB.PatternDB then
            for patID, pat in pairs(AltVaultDB.PatternDB) do
                local cached = AltVaultDB.ItemCache and AltVaultDB.ItemCache[patID]
                local patName = (cached and cached.n) or pat.cn
                local recs = ns.MasterDB and ns.MasterDB.GetItemSources and ns.MasterDB:GetItemSources(patID)
                if patName then
                    AddCandidateRecipe("Pattern", patID, patName, pat.p, pat.s, "Recipe Item", patID, recs, nil)
                end
            end
        end

        -- 2. Load RecipeDB entries (learned crafting schematics with reagent lists)
        if AltVaultDB and AltVaultDB.RecipeDB then
            for craftedID, rec in pairs(AltVaultDB.RecipeDB) do
                local reagParts = {}
                for _, rg in ipairs(rec.reagents or {}) do
                    table.insert(reagParts, string.format("%dx %s", rg.count or 1, rg.name or ("Item #" .. tostring(rg.id))))
                end
                local reagStr = (#reagParts > 0) and table.concat(reagParts, ", ") or nil
                AddCandidateRecipe("Item", craftedID, rec.name, rec.prof, rec.rank, "Crafted Schematic", nil, nil, reagStr)
            end
        end

        -- 3. Load MasterDB Holding Tank Profession Spells & Recipe Items (4,200+ Profession Records)
        if ns.MasterDB and ns.MasterDB.HoldingTank then
            local tank = ns.MasterDB.HoldingTank
            for idx = 1, #tank do
                local r = ns.MasterDB:GetRecordByIndex(idx)
                if r then
                    if r.IDType == "Spell" and r.ContentType == "Professions" then
                        AddCandidateRecipe("Spell", r.ID, r.Name, r.Category, nil, r.SubSection, nil, { r }, nil)
                    elseif r.IDType == "Item" then
                        local nLow = string.lower(r.Name or "")
                        if string.find(nLow, "^recipe:") or string.find(nLow, "^pattern:") or string.find(nLow, "^plans:")
                            or string.find(nLow, "^schematic:") or string.find(nLow, "^formula:") then
                            local pGuess = (string.find(nLow, "^recipe:") and (string.find(nLow, "potion") or string.find(nLow, "elixir") or string.find(nLow, "transmute") or string.find(nLow, "flask")) and "Alchemy")
                                or (string.find(nLow, "^recipe:") and "Cooking")
                                or (string.find(nLow, "^plans:") and "Blacksmithing")
                                or (string.find(nLow, "^schematic:") and "Engineering")
                                or (string.find(nLow, "^formula:") and "Enchanting")
                                or "Tailoring"
                            local allRecs = ns.MasterDB:GetItemSources(r.ID)
                            AddCandidateRecipe("Pattern", r.ID, r.Name, pGuess, 250, r.Category, r.ID, allRecs, nil)
                        end
                    end
                end
            end
        end

        -- 4. Load LearnedProgression (Trainer-scanned recipes)
        if AltVaultDB and AltVaultDB.LearnedProgression then
            for profName, skillTable in pairs(AltVaultDB.LearnedProgression) do
                if type(skillTable) == "table" then
                    for serviceName, reqRank in pairs(skillTable) do
                        AddCandidateRecipe("Trainer", 0, serviceName, profName, reqRank, "Trainer Progression", nil, nil, nil)
                    end
                end
            end
        end
    end

    GatherRecipeCandidates()

    if #recipes < 4 and acqState.recipeAutoLevelDefault and qLow == "" then
        local savedMin, savedMax = minLvl, maxLvl
        minLvl = 1
        maxLvl = math.min(300, math.max(125, (savedMax or 75) + 75))
        GatherRecipeCandidates()
        minLvl, maxLvl = savedMin, savedMax
    end

    -- Sort recipes starting at Skill 1 ascending up to Skill 300!
    table.sort(recipes, function(a, b)
        local rA = a.reqRank or 1
        local rB = b.reqRank or 1
        if rA ~= rB then return rA < rB end
        if (a.priority or 0) ~= (b.priority or 0) then return (a.priority or 0) > (b.priority or 0) end
        return (a.name or "") < (b.name or "")
    end)

    UpdateAcqPaginationControls("QUEST_FOR_RECIPE", #recipes)
    local perPage = panel:GetPerPageSize()
    local page = acqState.recipePage or 1
    local startIdx = ((page - 1) * perPage) + 1
    local endIdx = math.min(#recipes, page * perPage)

    local pagedRecipes = {}
    for i = startIdx, endIdx do
        table.insert(pagedRecipes, recipes[i])
    end

    if acqState.useGridView and #pagedRecipes > 0 then
        RenderAcqMatchesAsCompactGrid(panel, pagedRecipes, true)
        return
    end

    local rows = {}
    local lvlNote = ""
    if minLvl or maxLvl then
        lvlNote = string.format(" • Skill %d-%d", minLvl or 1, maxLvl or 300)
    else
        lvlNote = " • Skill 1→300 Order"
    end
    table.insert(rows, {
        tint = "SPEC_HEADER",
        text = string.format("|cffffd100Quest for Recipe — Dual-Faction Vendor, Quest & Trainer Guide (Showing %d–%d of %d%s • Page %d/%d) — Left-Click: Dossier • Alt+Click: ★ Fav|r",
            (#pagedRecipes > 0 and startIdx or 0), endIdx, #recipes, lvlNote, page, acqState.recipeTotalPages or 1)
    })

    if #recipes == 0 then
        table.insert(rows, { text = "  |cff888888No recipes matched your current Profession / Method / Faction / Level / Quality filters. Click [Reset] above!|r" })
        panel:RenderRowList(rows)
        return
    end

    for i = 1, #pagedRecipes do
        local r = pagedRecipes[i]
        local badge = METHOD_BADGES[r.method] or ""
        local titleStr = r.link or ("|cffffd100[" .. r.name .. "]|r")
        local knownBadge = (r.knownByText and r.knownByText ~= "")
            and ("  |cff00ff00[* Known: " .. r.knownByText .. "]|r")
            or ""
        local rKey = panel:MakeRecipeFavoriteKey(r.prof, r.name, r.id)
        local favStar = panel:IsRecipeFavorite(rKey) and "|cffffd100★|r " or "|cff666666☆|r "

        local rowText = string.format(
            "%s|cff00ff96[Skill %d]|r %s  |cff00ffff(%s)|r  %s%s\n     |cff3399ff[Alliance]:|r |cffffffff%s|r\n     |cffff3333[Horde]:|r    |cffffffff%s|r",
            favStar, r.reqRank or 1, titleStr, r.prof, badge, knownBadge, r.alliance, r.horde
        )
        local tooltipNote = string.format(
            "|cffffd100%s (%s %d)|r\n|cff3399ff• Alliance:|r %s\n|cffff3333• Horde:|r %s%s\n\n|cff00ff00Left-Click:|r Open Full Dual-Faction Recipe Dossier\n|cffffd100Alt+Click:|r Toggle ★ Recipe Favorite",
            r.name, r.prof, r.reqRank or 1, r.alliance, r.horde,
            (r.knownByText and r.knownByText ~= "" and ("\n|cff00ff00• Known By:|r " .. r.knownByText) or "")
        )

        table.insert(rows, {
            icon = r.icon,
            link = r.link,
            recommendNote = tooltipNote,
            onClickAction = function()
                acqState.inspectedRecipeEntry = r
                panel:RenderActivePane()
            end,
            onAltClickAction = function()
                local nowFav = panel:ToggleRecipeFavorite(rKey, r)
                SyncQuestAcqHeaderControls("QUEST_FOR_RECIPE")
                print(string.format("|cff00ccff[AltVault]|r %s %s Recipe Favorites.", r.name or "Recipe", nowFav and "|cff00ff00added to|r" or "|cffff6666removed from|r"))
                panel:RenderActivePane()
            end,
            text = rowText,
        })
    end

    panel:RenderRowList(rows)
end

-- ============================================================================
-- BLOCK HEADING: REGISTER "QUEST FOR ITEM" & "QUEST FOR RECIPE" ON MAIN PANEL
-- ============================================================================
MainPanel:RegisterExternalTab(
    "QUEST_FOR_ITEM",
    "Quest for Item",
    "Search any Gear or Item and see which Quest, Vendor, Quartermaster, or Dungeon Boss on BOTH Factions (Alliance & Horde) awards or sells it!",
    RenderQuestForItemTab
)

MainPanel:RegisterExternalTab(
    "QUEST_FOR_RECIPE",
    "Quest for Recipe",
    "Search any Profession Recipe, Pattern, Plans, Schematic, or Formula and see which Vendor, Quest, Trainer, or Drop on BOTH Factions (Alliance & Horde) teaches it!",
    RenderQuestForRecipeTab
)

if MainPanel.ApplyGlobalButtonScaling then
    MainPanel:ApplyGlobalButtonScaling(false)
end
