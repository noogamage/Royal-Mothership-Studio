-- ============================================================================
-- ALTVAULT MASTER HOLDING TANK CONTROLLER (MULTI-NODE RAW BLOB ARCHITECTURE)
-- Total Records Across 19 Data Nodes: 1095043
-- ============================================================================
local addonName, ns = ...
ns = ns or {}
ns.MasterDB = ns.MasterDB or {}
local MasterDB = ns.MasterDB
_G.AltVaultMasterDB = MasterDB

MasterDB.RawBlobs = MasterDB.RawBlobs or {}
MasterDB.HoldingTank = MasterDB.HoldingTank or {}

MasterDB.RacesAndSex = {
    [1]  = { raceID = 1,  name = "Human",     raceFile = "Human",    faction = "Alliance", maleSexID = 2, femaleSexID = 3, maleCustomGender = 0, femaleCustomGender = 1 },
    [2]  = { raceID = 2,  name = "Orc",       raceFile = "Orc",      faction = "Horde",    maleSexID = 2, femaleSexID = 3, maleCustomGender = 0, femaleCustomGender = 1 },
    [3]  = { raceID = 3,  name = "Dwarf",     raceFile = "Dwarf",    faction = "Alliance", maleSexID = 2, femaleSexID = 3, maleCustomGender = 0, femaleCustomGender = 1 },
    [4]  = { raceID = 4,  name = "Night Elf", raceFile = "NightElf", faction = "Alliance", maleSexID = 2, femaleSexID = 3, maleCustomGender = 0, femaleCustomGender = 1 },
    [5]  = { raceID = 5,  name = "Undead",    raceFile = "Scourge",  faction = "Horde",    maleSexID = 2, femaleSexID = 3, maleCustomGender = 0, femaleCustomGender = 1 },
    [6]  = { raceID = 6,  name = "Tauren",    raceFile = "Tauren",   faction = "Horde",    maleSexID = 2, femaleSexID = 3, maleCustomGender = 0, femaleCustomGender = 1 },
    [7]  = { raceID = 7,  name = "Gnome",     raceFile = "Gnome",    faction = "Alliance", maleSexID = 2, femaleSexID = 3, maleCustomGender = 0, femaleCustomGender = 1 },
    [8]  = { raceID = 8,  name = "Troll",     raceFile = "Troll",    faction = "Horde",    maleSexID = 2, femaleSexID = 3, maleCustomGender = 0, femaleCustomGender = 1 },
    [9]  = { raceID = 9,  name = "Goblin",    raceFile = "Goblin",   faction = "Horde",    maleSexID = 2, femaleSexID = 3, maleCustomGender = 0, femaleCustomGender = 1 },
    [10] = { raceID = 10, name = "Blood Elf", raceFile = "BloodElf", faction = "Horde",    maleSexID = 2, femaleSexID = 3, maleCustomGender = 0, femaleCustomGender = 1 },
    [11] = { raceID = 11, name = "Draenei",   raceFile = "Draenei",  faction = "Alliance", maleSexID = 2, femaleSexID = 3, maleCustomGender = 0, femaleCustomGender = 1 },
    [22] = { raceID = 22, name = "Worgen",    raceFile = "Worgen",   faction = "Alliance", maleSexID = 2, femaleSexID = 3, maleCustomGender = 0, femaleCustomGender = 1 },
    [24] = { raceID = 24, name = "Pandaren",  raceFile = "Pandaren", faction = "Both",     maleSexID = 2, femaleSexID = 3, maleCustomGender = 0, femaleCustomGender = 1 },
}

MasterDB.Classes = {
    [1]  = { classID = 1,  token = "WARRIOR",     name = "Warrior",      hex = "c79c6e", lowArmor = "Mail",    highArmor = "Plate",   canShield = true  },
    [2]  = { classID = 2,  token = "PALADIN",     name = "Paladin",      hex = "f58cba", lowArmor = "Mail",    highArmor = "Plate",   canShield = true  },
    [3]  = { classID = 3,  token = "HUNTER",      name = "Hunter",       hex = "abd473", lowArmor = "Leather", highArmor = "Mail",    canShield = false },
    [4]  = { classID = 4,  token = "ROGUE",       name = "Rogue",        hex = "fff569", lowArmor = "Leather", highArmor = "Leather", canShield = false },
    [5]  = { classID = 5,  token = "PRIEST",      name = "Priest",       hex = "ffffff", lowArmor = "Cloth",   highArmor = "Cloth",   canShield = false },
    [6]  = { classID = 6,  token = "DEATHKNIGHT", name = "Death Knight", hex = "c41f3b", lowArmor = "Plate",   highArmor = "Plate",   canShield = false },
    [7]  = { classID = 7,  token = "SHAMAN",      name = "Shaman",       hex = "0070de", lowArmor = "Leather", highArmor = "Mail",    canShield = true  },
    [8]  = { classID = 8,  token = "MAGE",        name = "Mage",         hex = "40c7eb", lowArmor = "Cloth",   highArmor = "Cloth",   canShield = false },
    [9]  = { classID = 9,  token = "WARLOCK",     name = "Warlock",      hex = "8787ed", lowArmor = "Cloth",   highArmor = "Cloth",   canShield = false },
    [10] = { classID = 10, token = "MONK",        name = "Monk",         hex = "00ff96", lowArmor = "Leather", highArmor = "Leather", canShield = false },
    [11] = { classID = 11, token = "DRUID",       name = "Druid",        hex = "ff7d0a", lowArmor = "Leather", highArmor = "Leather", canShield = false },
}

MasterDB.Stats = {
    TotalRecords = 18000,
    UniqueItems = 15534,
    UniqueSpells = 1779,
    UniqueSets = 111,
    UniqueQuestsAndNPCs = 3,
}
