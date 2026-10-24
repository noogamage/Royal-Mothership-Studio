using System;
using System.IO;
using System.Net;
using System.Text;
using System.Drawing;
using System.Windows.Forms;
using System.Text.RegularExpressions;
using System.Collections.Generic;
// ============================================================================
// DECONSTRUCTION GOD STUDIO v14.3 - MODULAR NODE SYSTEM
// NODE INDEX  : [10] OF [35]
// FILE NAME   : Node_10_DataModels.cs
// PARTIAL OF  : LootRecord, DatasetSchemaRecord, AddonTelemetry, DataRipperEngine
// ============================================================================








// SECTION 2.0: DATA MODELS WITH FULL PARENT & LAYER LINEAGE
// ============================================================================
public class LootRecord {
    public string IDType = "Item";
    public int ID = 0;
    public int SecondaryID = 0;
    public string Name = "";
    public string Era = "Classic";
    public string ContentType = "General";
    public string ModuleKey = "";
    public string CategoryName = "";
    public string SubSectionName = "";
    public string BossOrHeader = "";
    public string Difficulty = "Normal";
    public string Faction = "Both";
    public string PriceOrCost = "";
    public string Phase = "";
    public string SourceAddon = "";
    public string SourceFile = "";
    public string ParentRelativePath = "";
    public string ParentFullDiskPath = "";
}

public class DatasetSchemaRecord {
    public string AddonName = "";
    public string RelativePath = "";
    public string TableName = "";
    public string KeyType = "NumericID";
    public int RowCount = 0;
    public string SampleKeys = "";
    public string SampleRowPreview = "";
    public string Era = "Classic";
}

public class AddonTelemetry {
    public string AddonName = "";
    public string FolderPath = "";
    public string LastWriteSignature = "";
    public string StatusBadge = "NEW";
    public int TotalFolders = 0;
    public int TotalFiles = 0;
    public int LuaFiles = 0;
    public int XmlFiles = 0;
    public int TocFiles = 0;
    public int CodeOtherFiles = 0;
    public int DataRecordsCount = 0;
    public int ItemIDsCount = 0;
    public int SpellIDsCount = 0;
    public int QuestOrNpcIDsCount = 0;
    public int FunctionsCount = 0;
    public int CreativeBricksCount = 0;
    public int BlueprintsCount = 0;
}

// ============================================================================
// SECTION 3.0: STATIC ENGINE STATE & WOW ZONE/FACTION DICTIONARIES
// ============================================================================
public static partial class DataRipperEngine {
    public static List<LootRecord> ExtractedRecords = new List<LootRecord>();
    public static List<LootRecord> CurrentFileRecords = new List<LootRecord>(512);
    public static List<DatasetSchemaRecord> CurrentFileSchemas = new List<DatasetSchemaRecord>(32);
    public static List<DatasetSchemaRecord> ExtractedSchemas = new List<DatasetSchemaRecord>();

    public static Dictionary<string, AddonTelemetry> AddonStatsMap = new Dictionary<string, AddonTelemetry>(StringComparer.OrdinalIgnoreCase);
    public static List<AddonTelemetry> AddonStatsList = new Dictionary<string, AddonTelemetry>().Values != null ? new List<AddonTelemetry>() : new List<AddonTelemetry>();

    public static int TotalSavedDataRecordsOnDisk = 0;
    public static int TotalSavedDatasetSchemasOnDisk = 0;
    public static string ActiveStudioDirForMidFlush = "";

    private static string CachedResolvedTroughDir = "";
    private static string CachedResolvedStudioKey = "";

    private static HashSet<string> CurrentAddonDedupKeys = new HashSet<string>();
    private static string SEP = ((char)124).ToString();
    private static string TAB = "\t";

    private static Dictionary<int, string> MapNames = new Dictionary<int, string>() {
        {209, "Shadowfang Keep"}, {717, "The Stockade"}, {718, "Wailing Caverns"},
        {719, "Blackfathom Deeps"}, {721, "Gnomeregan"}, {722, "Razorfen Downs"},
        {796, "Scarlet Monastery"}, {1176, "Zul'Farrak"}, {1337, "Uldaman"},
        {1477, "Sunken Temple"}, {1581, "The Deadmines"}, {1583, "Blackrock Spire"},
        {1584, "Blackrock Depths"}, {1977, "Zul'Gurub"}, {2017, "Stratholme"},
        {2057, "Scholomance"}, {2100, "Maraudon"}, {2437, "Ragefire Chasm"},
        {2557, "Dire Maul"}, {2677, "Blackwing Lair"}, {2717, "Molten Core"},
        {3428, "Ahn'Qiraj (AQ40)"}, {3429, "Ruins of Ahn'Qiraj (AQ20)"}, {3456, "Naxxramas"},
        {3457, "Karazhan"}, {3562, "Hellfire Ramparts"}, {3606, "Hyjal Summit"},
        {3607, "Serpentshrine Cavern"}, {3713, "The Blood Furnace"}, {3714, "The Shattered Halls"},
        {3715, "The Steamvault"}, {3716, "The Underbog"}, {3717, "The Slave Pens"},
        {3789, "Shadow Labyrinth"}, {3790, "Auchenai Crypts"}, {3791, "Sethekk Halls"},
        {3792, "Mana-Tombs"}, {3805, "Zul'Aman"}, {3836, "Magtheridon's Lair"},
        {3845, "Tempest Keep"}, {3847, "The Botanica"}, {3848, "The Arcatraz"},
        {3849, "The Mechanar"}, {3923, "Gruul's Lair"}, {3959, "Black Temple"},
        {4075, "Sunwell Plateau"}, {4100, "The Culling of Stratholme"}, {4196, "Drak'Tharon Keep"},
        {4228, "The Oculus"}, {4264, "Halls of Stone"}, {4265, "The Nexus"},
        {4272, "Halls of Lightning"}, {4273, "Ulduar"}, {4277, "Azjol-Nerub"},
        {4415, "The Violet Hold"}, {4416, "Gundrak"}, {4493, "The Obsidian Sanctum"},
        {4494, "Ahn'kahet: The Old Kingdom"}, {4500, "The Eye of Eternity"},
        {4722, "Trial of the Crusader"}, {4723, "Trial of the Champion"},
        {4809, "The Forge of Souls"}, {4812, "Icecrown Citadel"}, {4813, "Pit of Saron"},
        {4820, "Halls of Reflection"}, {4987, "The Ruby Sanctum"}
    };

    private static Dictionary<int, string> FactionNames = new Dictionary<int, string>() {
        {59, "Thorium Brotherhood"}, {270, "Zandalar Tribe"}, {509, "The League of Arathor"},
        {510, "The Defilers"}, {529, "Argent Dawn"}, {576, "Timbermaw Hold"},
        {609, "Cenarion Circle"}, {729, "Frostwolf Clan"}, {730, "Stormpike Guard"},
        {749, "Hydraxian Waterlords"}, {889, "Warsong Outriders"}, {890, "Silverwing Sentinels"},
        {909, "Darkmoon Faire"}, {910, "Brood of Nozdormu"}, {932, "The Aldor"},
        {933, "The Consortium"}, {934, "The Scryers"}, {935, "The Sha'tar"},
        {942, "Cenarion Expedition"}, {946, "Honor Hold"}, {947, "Thrallmar"},
        {970, "Sporeggar"}, {978, "Kurenai"}, {989, "Keepers of Time"},
        {990, "The Scale of the Sands"}, {1011, "Lower City"}, {1012, "Ashtongue Deathsworn"},
        {1015, "Netherwing"}, {1031, "Sha'tari Skyguard"}, {1038, "Ogri'la"},
        {1077, "Shattered Sun Offensive"}, {1090, "Kirin Tor"}, {1091, "The Wyrmrest Accord"},
        {1098, "Knights of the Ebon Blade"}, {1106, "Argent Crusade"}, {1119, "The Sons of Hodir"},
        {1156, "The Ashen Verdict"}
    };
}

// ============================================================================
// DECONSTRUCTION GOD STUDIO v14.3 - MODULAR NODE SYSTEM
// NODE INDEX  : [11] OF [35]
// FILE NAME   : Node_11_DataRegexAndHelpers.cs
// PARTIAL OF  : DataRipperEngine
// ============================================================================








public static partial class DataRipperEngine {
    // ========================================================================
    // SECTION 4.0: COMPILED REGEX PATTERNS (INCLUDING MINIFIED & NUMERIC TABLES)
    // ========================================================================
    private static Regex rxDataBlock      = new Regex(@"^\s*data\s*\[\s*""([^""]+)""\s*\]\s*=\s*\{", RegexOptions.Compiled);
    private static Regex rxNamedLuaTable  = new Regex(@"^\s*(?:local\s+)?([A-Za-z_][A-Za-z0-9_\.]*(?:\[\s*""[^""]+""\s*\])?)\s*=\s*\{\s*$", RegexOptions.Compiled);
    private static Regex rxSubKeyName     = new Regex(@"\b([A-Za-z_][A-Za-z0-9_]{1,24})\s*=", RegexOptions.Compiled);
    private static Regex rxTableType      = new Regex(@"TableType\s*=\s*([A-Za-z0-9_]+)", RegexOptions.Compiled);
    private static Regex rxContentType    = new Regex(@"ContentType\s*=\s*([A-Za-z0-9_]+)", RegexOptions.Compiled);
    private static Regex rxPhase          = new Regex(@"ContentPhase[A-Za-z]*\s*=\s*([0-9\.]+)", RegexOptions.Compiled);
    private static Regex rxMapID          = new Regex(@"^\s*MapID\s*=\s*(\d+)", RegexOptions.Compiled);
    private static Regex rxFactionID      = new Regex(@"^\s*FactionID\s*=\s*(\d+)", RegexOptions.Compiled);
    private static Regex rxNameLine       = new Regex(@"^\s*name\s*=\s*(.+?)\s*,?\s*$", RegexOptions.Compiled);
    private static Regex rxDiffHeader     = new Regex(@"^\s*\[\s*([A-Za-z0-9_]+)\s*\]\s*=\s*\{", RegexOptions.Compiled);
    private static Regex rxBoxDivider     = new Regex(@"^\s*\{\s*\d+\s*,\s*""INV_[^""]*""\s*,\s*nil\s*,\s*(.+?)\s*\}", RegexOptions.Compiled);
    private static Regex rxDualFaction    = new Regex(@"^\s*\{\s*\d+\s*,\s*\[ATLASLOOT_IT_ALLIANCE\]\s*=\s*\{\s*(\d+)\s*\}\s*,\s*\[ATLASLOOT_IT_HORDE\]\s*=\s*\{\s*(\d+)\s*\}\s*\}\s*,?\s*(?:--\s*(.*))?$", RegexOptions.Compiled);
    private static Regex rxGetVersion     = new Regex(@"^\s*\{\s*\d+\s*,\s*GetForVersion\s*\(\s*(\d+)\s*,\s*(\d+)\s*\)\s*\}\s*,?\s*(?:--\s*(.*))?$", RegexOptions.Compiled);
    private static Regex rxGameVerGE      = new Regex(@"AtlasLoot:GameVersion_GE\s*\(\s*([A-Za-z0-9_\.]+)\s*,\s*\{\s*\d+\s*,\s*(\d+)\s*\}\s*\)\s*,?\s*(?:--\s*(.*))?$", RegexOptions.Compiled);
    private static Regex rxPrefixedItem   = new Regex(@"^\s*\{\s*\d+\s*,\s*""i(\d+)""\s*\}\s*,?\s*(?:--\s*(.*))?$", RegexOptions.Compiled);
    private static Regex rxStandardEntry  = new Regex(@"^\s*\{\s*(\d+)\s*,\s*(\d+)(.*?)\}\s*,?\s*(?:--\s*(.*))?$", RegexOptions.Compiled);

    private static Regex rxAttMacro       = new Regex(@"\b([iqns])\s*\(\s*(\d{2,7})\b", RegexOptions.Compiled);
    private static Regex rxKeyedString    = new Regex(@"^\s*\[(\d{2,7})\]\s*=\s*\{?\s*""([^""]{2,70})""", RegexOptions.Compiled);

    private static Regex rxKeyedTableAny  = new Regex(@"^\s*\[(\d{2,7})\]\s*=\s*\{(.*)$", RegexOptions.Compiled);
    private static Regex rxFirstQuoted    = new Regex(@"""([^""]{2,70})""", RegexOptions.Compiled);
    private static Regex rxKeyedScalar    = new Regex(@"^\s*\[(\d{3,7})\]\s*=\s*(\d{2,7})\s*,?\s*(?:--\s*(.*))?$", RegexOptions.Compiled);
    private static Regex rxMinifiedPairs  = new Regex(@"\[(\d{3,7})\]\s*=\s*(?:\{\s*(?:""([^""]{1,60})""|(\d+))|""([^""]{1,60})"")", RegexOptions.Compiled);

    private static Regex rxExplicitItem   = new Regex(@"\b[iI]tem[I]?[dD]?\s*[:=]\s*(\d{3,7})", RegexOptions.Compiled);
    private static Regex rxExplicitSpell  = new Regex(@"\b[sS]pell[I]?[dD]?\s*[:=]\s*(\d{2,7})", RegexOptions.Compiled);
    private static Regex rxExplicitNpc    = new Regex(@"\b[nN]pc[I]?[dD]?\s*[:=]\s*(\d{2,7})", RegexOptions.Compiled);
    private static Regex rxExplicitBoss   = new Regex(@"\b[cC]reature[I]?[dD]?\s*[:=]\s*(\d{2,7})", RegexOptions.Compiled);
    private static Regex rxItemLinkId     = new Regex(@"item:(\d{3,7})", RegexOptions.Compiled);
    private static Regex rxSqlInsertId    = new Regex(@"VALUES\s*\(\s*(\d{2,7})\s*,\s*'([^']{2,60})'", RegexOptions.Compiled | RegexOptions.IgnoreCase);
    private static Regex rxJsonIdName     = new Regex(@"""id""\s*:\s*(\d{2,7})\s*,\s*""name""\s*:\s*""([^""]{2,60})""", RegexOptions.Compiled | RegexOptions.IgnoreCase);
    private static Regex rxCsvLeadingId   = new Regex(@"^\s*(\d{2,7})\s*,\s*""?([^"",]{2,60})""?", RegexOptions.Compiled);

    // ========================================================================
    // SECTION 5.0: ZERO-RAM MEMORY MANAGEMENT & SANITIZATION HELPERS
    // ========================================================================
    public static string ResolveTroughDir(string studioDir) {
        if (!string.IsNullOrEmpty(CachedResolvedTroughDir) && string.Equals(CachedResolvedStudioKey, studioDir, StringComparison.OrdinalIgnoreCase)) {
            return CachedResolvedTroughDir;
        }
        CachedResolvedStudioKey = studioDir ?? "";
        string localTrough = Path.Combine(studioDir ?? "", "Portable_SQL_Trough");
        if (Directory.Exists(localTrough) && File.Exists(Path.Combine(localTrough, "Trough_AddonsInventory.tsv"))) {
            CachedResolvedTroughDir = localTrough;
            return localTrough;
        }
        string desktopTrough = @"C:\Users\seanw\OneDrive\Desktop\wow forever addons\Portable_SQL_Trough";
        if (Directory.Exists(desktopTrough) && File.Exists(Path.Combine(desktopTrough, "Trough_AddonsInventory.tsv"))) {
            CachedResolvedTroughDir = desktopTrough;
            return desktopTrough;
        }
        CachedResolvedTroughDir = localTrough;
        return localTrough;
    }

    public static void ResetAllMemory() {
        ExtractedRecords.Clear();
        CurrentFileRecords.Clear();
        CurrentFileSchemas.Clear();
        ExtractedSchemas.Clear();
        CurrentAddonDedupKeys.Clear();
        AddonStatsMap.Clear();
        AddonStatsList.Clear();
        TotalSavedDataRecordsOnDisk = 0;
        TotalSavedDatasetSchemasOnDisk = 0;
        CachedResolvedTroughDir = "";
        CachedResolvedStudioKey = "";
    }

    public static void ClearCurrentAddonDedupMemory() {
        CurrentFileRecords.Clear();
        CurrentFileSchemas.Clear();
        CurrentAddonDedupKeys.Clear();
    }

    public static string SanitizeField(string s) {
        if (string.IsNullOrEmpty(s)) return "";
        return s.Replace("\t", " ").Replace("\r", "").Replace("\n", " ").Replace(SEP, "/").Trim();
    }

    public static string EscapeLua(string s) {
        if (string.IsNullOrEmpty(s)) return "";
        return s.Replace("\\", "\\\\").Replace("\"", "\\\"").Replace("\r", "").Replace("\n", " ").Replace(SEP, "/").Trim();
    }

    public static string EscapeSql(string s) {
        if (string.IsNullOrEmpty(s)) return "";
        return s.Replace("'", "''").Replace("\r", "").Replace("\n", " ").Trim();
    }

    public static bool IsSupportedExtension(string ext) {
        if (ext == ".lua") return true;
        if (ext == ".xml") return true;
        if (ext == ".toc") return true;
        if (ext == ".cpp") return true;
        if (ext == ".c") return true;
        if (ext == ".h") return true;
        if (ext == ".hpp") return true;
        if (ext == ".cs") return true;
        if (ext == ".py") return true;
        if (ext == ".sql") return true;
        if (ext == ".json") return true;
        if (ext == ".csv") return true;
        if (ext == ".js") return true;
        if (ext == ".ts") return true;
        if (ext == ".ps1") return true;
        if (ext == ".sh") return true;
        if (ext == ".bat") return true;
        return false;
    }

    public static AddonTelemetry GetOrCreateAddonTelemetry(string addonName, string folderPath) {
        AddonTelemetry t;
        if (!AddonStatsMap.TryGetValue(addonName, out t)) {
            t = new AddonTelemetry();
            t.AddonName = addonName;
            t.FolderPath = folderPath;
            AddonStatsMap[addonName] = t;
            AddonStatsList.Add(t);
        }
        return t;
    }

    public static int FastCountDirectoriesSafe(string folderPath) {
        if (string.IsNullOrEmpty(folderPath) || !Directory.Exists(folderPath)) return 1;
        int count = 1;
        Queue<string> q = new Queue<string>();
        q.Enqueue(folderPath);
        while (q.Count > 0) {
            string cur = q.Dequeue();
            try {
                string[] subs = Directory.GetDirectories(cur, "*", SearchOption.TopDirectoryOnly);
                for (int i = 0; i < subs.Length; i++) {
                    string dn = new DirectoryInfo(subs[i]).Name;
                    if (dn.StartsWith(".")) continue;
                    count++;
                    q.Enqueue(subs[i]);
                }
            } catch {}
        }
        return count;
    }

    public static string DetectFileEra(string filePath, string contentSample) {
        string lowerName = Path.GetFileName(filePath).ToLowerInvariant();
        string lowerPath = filePath.ToLowerInvariant();
        if (lowerName.Contains("sod") || lowerPath.Contains("forever") || contentSample.Contains("GetActiveSeason() == 2")) return "SoD_Forever";
        if (lowerName.Contains("wrath") || lowerName.Contains("wotlk") || lowerPath.Contains("wrath") || lowerPath.Contains("wotlk") || contentSample.Contains("WRATH_VERSION_NUM")) return "Wrath";
        if (lowerName.Contains("tbc") || lowerName.Contains("bc") || lowerPath.Contains("burningcrusade") || lowerPath.Contains("-bc") || lowerPath.Contains("_bc") || contentSample.Contains("BC_VERSION_NUM")) return "TBC";
        return "Classic";
    }

    private static string InferRecordTypeFromPath(string addonName, string fileName) {
        string lowerFn = (addonName + " " + fileName).ToLowerInvariant();
        if (lowerFn.Contains("npc") || lowerFn.Contains("mob") || lowerFn.Contains("spawn") || lowerFn.Contains("rare")) return "NPC";
        if (lowerFn.Contains("quest")) return "Quest";
        if (lowerFn.Contains("spell") || lowerFn.Contains("craft") || lowerFn.Contains("enchant") || lowerFn.Contains("talent")) return "Spell";
        if (lowerFn.Contains("item") || lowerFn.Contains("loot") || lowerFn.Contains("bis") || lowerFn.Contains("vendor") || lowerFn.Contains("gargul")) return "Item";
        if (lowerFn.Contains("gather") || lowerFn.Contains("node") || lowerFn.Contains("herb") || lowerFn.Contains("mine") || lowerFn.Contains("fish") || lowerFn.Contains("treasure") || lowerFn.Contains("object")) return "DB_Entry";
        return "DB_Entry";
    }

    private static string CleanLuaExpr(string raw) {
        if (string.IsNullOrEmpty(raw)) return "";
        string s = raw.Trim();
        if (s.IndexOf("C_Map_GetAreaInfo", StringComparison.Ordinal) >= 0) {
            s = Regex.Replace(s, @"C_Map_GetAreaInfo\s*\(\s*(\d+)\s*\)", m => {
                int id = int.Parse(m.Groups[1].Value);
                return MapNames.ContainsKey(id) ? MapNames[id] : "Zone_" + id;
            });
        }
        if (s.IndexOf("GetFactionInfoByID", StringComparison.Ordinal) >= 0) {
            s = Regex.Replace(s, @"GetFactionInfoByID\s*\(\s*(\d+)\s*\)", m => {
                int id = int.Parse(m.Groups[1].Value);
                return FactionNames.ContainsKey(id) ? FactionNames[id] : "Faction_" + id;
            });
        }
        if (s.IndexOf("format", StringComparison.Ordinal) >= 0) {
            s = Regex.Replace(s, @"format\s*\(\s*AL\[""([^""]+)""\]\s*,\s*""([^""]+)""\s*\)", m => {
                return m.Groups[1].Value.Replace("%s", m.Groups[2].Value);
            });
            s = Regex.Replace(s, @"format\s*\(\s*AL\[""([^""]+)""\]\s*,\s*AL\[""([^""]+)""\]\s*\)", m => {
                return m.Groups[1].Value.Replace("%s", m.Groups[2].Value);
            });
            s = Regex.Replace(s, @"format\s*\(\s*GEM_FORMAT1\s*,\s*ALIL\[""([^""]+)""\]\s*\)", m => {
                return "Gems - " + m.Groups[1].Value;
            });
        }
        if (s.IndexOf("AL", StringComparison.Ordinal) >= 0) {
            s = Regex.Replace(s, @"ALIL?\[""([^""]+)""\]", "$1");
        }
        s = s.Replace("..", " ").Replace("\"", "").Replace("'", "");
        if (s.EndsWith(",")) s = s.Substring(0, s.Length - 1).Trim();
        return s;
    }

    private static string MapDiffLabel(string diffToken) {
        if (string.IsNullOrEmpty(diffToken)) return "Normal";
        string u = diffToken.ToUpperInvariant();
        if (u.Contains("HEROIC") || u == "H") return "Heroic";
        if (u.Contains("25RAIDH")) return "25-Man Heroic";
        if (u.Contains("25RAID")) return "25-Man";
        if (u.Contains("10RAIDH")) return "10-Man Heroic";
        if (u.Contains("10RAID")) return "10-Man";
        if (u.Contains("ALLIANCE")) return "Alliance";
        if (u.Contains("HORDE")) return "Horde";
        if (u.Contains("LEATHER")) return "Leather";
        if (u.Contains("MAIL")) return "Mail";
        if (u.Contains("PLATE")) return "Plate";
        if (u.Contains("CLOTH")) return "Cloth";
        if (u.Contains("MAJOR_GLYPH")) return "Major Glyphs";
        if (u.Contains("MINOR_GLYPH")) return "Minor Glyphs";
        if (u.Contains("VENDOR")) return "Vendor";
        return "Normal";
    }

    private static string MapContentType(string rawToken, string moduleKey) {
        string u = (rawToken + " " + moduleKey).ToUpperInvariant();
        if (u.Contains("BIS")) return "Best_In_Slot";
        if (u.Contains("PROF") || u.Contains("CRAFT")) return "Professions";
        if (u.Contains("GATHER") || u.Contains("HERB") || u.Contains("MINE") || u.Contains("NODE")) return "Gathering_Nodes";
        if (u.Contains("QUEST")) return "Quests_And_Objectives";
        if (u.Contains("SET")) return "Sets";
        if (u.Contains("VENDOR") || u.Contains("BADGE") || u.Contains("SUNMOTE")) return "Vendors";
        if (u.Contains("WORLD_EVENT") || u.Contains("FESTIVAL") || u.Contains("INVASION") || u.Contains("HALLOWEEN") || u.Contains("WINTERVEIL") || u.Contains("BREWFEST") || u.Contains("DARKMOON")) return "World_Events";
        if (u.Contains("COLLECTION") || u.Contains("MOUNT") || u.Contains("COMPANION") || u.Contains("TABARD") || u.Contains("TOY") || u.Contains("LEGENDARY") || u.Contains("WORLDEPIC")) return "Collections";
        if (u.Contains("RAID")) return "Raids";
        if (u.Contains("DUNGEON")) return "Dungeons";
        if (u.Contains("PVP") || u.Contains("ARENA")) return "PvP";
        if (u.Contains("FACTION") || u.Contains("REPUTATION")) return "Factions";
        return "Dungeons_And_Loot";
    }

}
// ============================================================================
// DECONSTRUCTION GOD STUDIO v14.3 - MODULAR NODE SYSTEM
// NODE INDEX  : [12] OF [35]
// FILE NAME   : Node_12_DataParsers.cs
// PARTIAL OF  : DataRipperEngine
// ============================================================================








public static partial class DataRipperEngine {
    // ========================================================================
    // SECTION 6.0: UNIVERSAL LUA, MINIFIED STREAM, SQL, CSV & JSON DATA PARSERS
    // ========================================================================
    public static void ParseStructuredDataFile(AddonTelemetry addonStat, string filePath, string relPath, List<string> lines, string fileEra) {
        string addonName = addonStat.AddonName;
        string fileName = Path.GetFileName(filePath);
        string baseFileNoExt = Path.GetFileNameWithoutExtension(fileName);
        string ext = Path.GetExtension(filePath).ToLowerInvariant();

        for (int i = 0; i < lines.Count; i++) {
            string line = lines[i].Trim();
            if (string.IsNullOrEmpty(line)) continue;

            if (ext == ".sql") {
                Match mSql = rxSqlInsertId.Match(line);
                if (mSql.Success) {
                    int idVal = int.Parse(mSql.Groups[1].Value);
                    string nameVal = mSql.Groups[2].Value;
                    AddLootEntry(addonStat, "SQL_Record", idVal, 0, nameVal, fileEra, "SQL_Database", addonName, baseFileNoExt, "", "", "Normal", "Both", "", "", addonName, fileName, relPath, filePath);
                }
            } else if (ext == ".json") {
                Match mJs = rxJsonIdName.Match(line);
                if (mJs.Success) {
                    int idVal = int.Parse(mJs.Groups[1].Value);
                    string nameVal = mJs.Groups[2].Value;
                    AddLootEntry(addonStat, "JSON_Record", idVal, 0, nameVal, fileEra, "JSON_Data", addonName, baseFileNoExt, "", "", "Normal", "Both", "", "", addonName, fileName, relPath, filePath);
                }
            } else if (ext == ".csv") {
                Match mCsv = rxCsvLeadingId.Match(line);
                if (mCsv.Success) {
                    int idVal = 0;
                    if (int.TryParse(mCsv.Groups[1].Value, out idVal)) {
                        AddLootEntry(addonStat, "DB_Entry", idVal, 0, mCsv.Groups[2].Value, fileEra, "CSV_Data", addonName, baseFileNoExt, "", "", "Normal", "Both", "", "", addonName, fileName, relPath, filePath);
                    }
                }
            }
        }
    }

    private static void RecordDatasetSchemaIfEligible(string addonName, string relPath, string tableName, string keyType, int rowCount, string sampleKeys, string sampleRow, string fileEra) {
        if (rowCount < 15 || string.IsNullOrEmpty(tableName)) return;
        DatasetSchemaRecord dsr = new DatasetSchemaRecord();
        dsr.AddonName = SanitizeField(addonName);
        dsr.RelativePath = SanitizeField(string.IsNullOrEmpty(relPath) ? addonName : (addonName + "\\" + relPath));
        dsr.TableName = SanitizeField(tableName);
        dsr.KeyType = SanitizeField(keyType);
        dsr.RowCount = rowCount;
        dsr.SampleKeys = SanitizeField(sampleKeys);
        dsr.SampleRowPreview = SanitizeField(sampleRow.Length > 140 ? sampleRow.Substring(0, 140) : sampleRow);
        dsr.Era = SanitizeField(fileEra);
        CurrentFileSchemas.Add(dsr);
        TotalSavedDatasetSchemasOnDisk++;
    }

    public static void ParseLuaFileForData(AddonTelemetry addonStat, string filePath, string relPath, List<string> lines, string fileEra, bool ripGenericData) {
        string addonName = addonStat.AddonName;
        string fileName = Path.GetFileName(filePath);
        string baseFileNoExt = Path.GetFileNameWithoutExtension(fileName);
        string currentModuleKey = "";
        string currentCategoryName = "";
        string currentContentType = MapContentType("", addonName + " " + baseFileNoExt);
        string currentTableType = "Item";
        string currentSubSection = "";
        string currentBossHeader = "";
        string currentDifficulty = "Normal";
        string currentFaction = "Both";
        string currentPhase = "";
        bool inItemsArray = false;
        string activeSubTableType = "";
        string inferredType = InferRecordTypeFromPath(addonName, fileName);

        // Zero-overhead streaming table schema tracker
        string schemaTableName = baseFileNoExt;
        string schemaKeyType = inferredType;
        int schemaRowCount = 0;
        string schemaSampleKeys = "";
        string schemaSampleRow = "";

        for (int i = 0; i < lines.Count; i++) {
            string line = lines[i];

            if (line.Length > 2000) {
                if (ripGenericData && line.Contains("[")) {
                    MatchCollection mcMin = rxMinifiedPairs.Matches(line);
                    int minCap = Math.Min(mcMin.Count, 15000);
                    for (int mIdx = 0; mIdx < minCap; mIdx++) {
                        Match mm = mcMin[mIdx];
                        int mId = 0;
                        if (int.TryParse(mm.Groups[1].Value, out mId) && mId > 0) {
                            string mLabel = "";
                            int secVal = 0;
                            if (mm.Groups[2].Success) mLabel = mm.Groups[2].Value;
                            else if (mm.Groups[4].Success) mLabel = mm.Groups[4].Value;
                            else if (mm.Groups[3].Success) int.TryParse(mm.Groups[3].Value, out secVal);
                            AddLootEntry(addonStat, inferredType, mId, secVal, mLabel, fileEra, currentContentType, addonName, baseFileNoExt, "Minified_Table", "", "Normal", "Both", "", "", addonName, fileName, relPath, filePath);
                            schemaRowCount++;
                        }
                    }
                }
                continue;
            }

            string trimmed = line.Trim();
            if (string.IsNullOrEmpty(trimmed)) continue;
            char c0 = trimmed[0];
            if (c0 == '-' && trimmed.StartsWith("--")) continue;

            // Detect top-level named table header in O(1) pre-check before regex
            if (c0 != '[' && c0 != '{' && c0 != '}' && trimmed[trimmed.Length - 1] == '{' && trimmed.IndexOf('=') > 0) {
                Match mNamed = rxNamedLuaTable.Match(line);
                if (mNamed.Success) {
                    RecordDatasetSchemaIfEligible(addonName, relPath, schemaTableName, schemaKeyType, schemaRowCount, schemaSampleKeys, schemaSampleRow, fileEra);
                    schemaTableName = mNamed.Groups[1].Value;
                    schemaKeyType = inferredType;
                    schemaRowCount = 0;
                    schemaSampleKeys = "";
                    schemaSampleRow = "";
                }
            }

            Match mData = rxDataBlock.Match(line);
            if (mData.Success) {
                RecordDatasetSchemaIfEligible(addonName, relPath, schemaTableName, schemaKeyType, schemaRowCount, schemaSampleKeys, schemaSampleRow, fileEra);
                currentModuleKey = mData.Groups[1].Value;
                currentCategoryName = currentModuleKey;
                currentContentType = MapContentType("", addonName + " " + currentModuleKey);
                currentTableType = "Item";
                currentSubSection = "";
                currentBossHeader = "";
                currentDifficulty = "Normal";
                currentFaction = "Both";
                currentPhase = "";
                inItemsArray = false;
                activeSubTableType = "";
                schemaTableName = "data[\"" + currentModuleKey + "\"]";
                schemaKeyType = "AtlasLoot_Module";
                schemaRowCount = 0;
                schemaSampleKeys = "MapID,FactionID,items,Difficulty";
                schemaSampleRow = "";
                continue;
            }

            if (string.IsNullOrEmpty(currentModuleKey)) {
                if (ripGenericData) {
                    string inlineComment = "";
                    int commentIdx = line.IndexOf("--");
                    if (commentIdx >= 0) {
                        inlineComment = line.Substring(commentIdx + 2).Trim();
                    }

                    if (line.IndexOf('(') >= 0) {
                        MatchCollection mcAtt = rxAttMacro.Matches(line);
                        if (mcAtt.Count > 0) {
                            foreach (Match ma in mcAtt) {
                                string macroChar = ma.Groups[1].Value;
                                int mId = int.Parse(ma.Groups[2].Value);
                                string mType = "Item";
                                if (macroChar == "q") mType = "Quest";
                                else if (macroChar == "n") mType = "NPC";
                                else if (macroChar == "s") mType = "Spell";
                                AddLootEntry(addonStat, mType, mId, 0, inlineComment, fileEra, currentContentType, addonName, baseFileNoExt, "", "", "Normal", "Both", "", "", addonName, fileName, relPath, filePath);
                                schemaRowCount++;
                                if (schemaRowCount == 1) {
                                    schemaKeyType = "ATT_Macro_" + mType;
                                    schemaSampleRow = trimmed;
                                }
                            }
                            continue;
                        }
                    }

                    if (c0 == '[') {
                        Match mKeyed = rxKeyedString.Match(line);
                        if (mKeyed.Success) {
                            int kId = int.Parse(mKeyed.Groups[1].Value);
                            string kName = mKeyed.Groups[2].Value;
                            AddLootEntry(addonStat, inferredType, kId, 0, kName, fileEra, currentContentType, addonName, baseFileNoExt, "", "", "Normal", "Both", "", "", addonName, fileName, relPath, filePath);
                            schemaRowCount++;
                            if (schemaRowCount == 1) {
                                schemaKeyType = inferredType + "[id]=String";
                                schemaSampleKeys = "id,name";
                                schemaSampleRow = trimmed;
                            }
                            continue;
                        }

                        Match mTblAny = rxKeyedTableAny.Match(line);
                        if (mTblAny.Success) {
                            int kId = int.Parse(mTblAny.Groups[1].Value);
                            string restOfRow = mTblAny.Groups[2].Value;
                            string extractedLabel = inlineComment;
                            if (string.IsNullOrEmpty(extractedLabel) && restOfRow.IndexOf('"') >= 0) {
                                Match mFq = rxFirstQuoted.Match(restOfRow);
                                if (mFq.Success) extractedLabel = mFq.Groups[1].Value;
                            }
                            if (string.IsNullOrEmpty(extractedLabel)) {
                                extractedLabel = baseFileNoExt + "_" + kId;
                            }
                            AddLootEntry(addonStat, inferredType, kId, 0, extractedLabel, fileEra, currentContentType, addonName, baseFileNoExt, "", "", "Normal", "Both", "", "", addonName, fileName, relPath, filePath);
                            schemaRowCount++;
                            if (schemaRowCount == 1) {
                                schemaKeyType = inferredType + "[id]=Table";
                                schemaSampleRow = trimmed;
                                if (restOfRow.IndexOf('=') > 0) {
                                    MatchCollection mcKeys = rxSubKeyName.Matches(restOfRow);
                                    if (mcKeys.Count > 0) {
                                        List<string> kNames = new List<string>();
                                        for (int ki = 0; ki < mcKeys.Count && ki < 8; ki++) {
                                            kNames.Add(mcKeys[ki].Groups[1].Value);
                                        }
                                        schemaSampleKeys = string.Join(",", kNames.ToArray());
                                    } else {
                                        schemaSampleKeys = "array_tuple";
                                    }
                                } else {
                                    schemaSampleKeys = "array_tuple";
                                }
                            }
                            continue;
                        }

                        Match mScalar = rxKeyedScalar.Match(line);
                        if (mScalar.Success) {
                            int kId = int.Parse(mScalar.Groups[1].Value);
                            int vId = int.Parse(mScalar.Groups[2].Value);
                            string lbl = mScalar.Groups[3].Success ? mScalar.Groups[3].Value.Trim() : ("Node_" + vId);
                            AddLootEntry(addonStat, inferredType, kId, vId, lbl, fileEra, currentContentType, addonName, baseFileNoExt, "", "", "Normal", "Both", "", "", addonName, fileName, relPath, filePath);
                            schemaRowCount++;
                            if (schemaRowCount == 1) {
                                schemaKeyType = inferredType + "[id]=ScalarID";
                                schemaSampleKeys = "key_id,val_id";
                                schemaSampleRow = trimmed;
                            }
                            continue;
                        }
                    }

                    if (line.IndexOf("tem", StringComparison.Ordinal) >= 0) {
                        Match mItm = rxExplicitItem.Match(line);
                        if (mItm.Success) {
                            int idVal = int.Parse(mItm.Groups[1].Value);
                            AddLootEntry(addonStat, "Item", idVal, 0, inlineComment, fileEra, currentContentType, addonName, baseFileNoExt, "", "", "Normal", "Both", "", "", addonName, fileName, relPath, filePath);
                            continue;
                        }
                        Match mLnk = rxItemLinkId.Match(line);
                        if (mLnk.Success) {
                            int idVal = int.Parse(mLnk.Groups[1].Value);
                            AddLootEntry(addonStat, "Item", idVal, 0, inlineComment, fileEra, currentContentType, addonName, baseFileNoExt, "", "", "Normal", "Both", "", "", addonName, fileName, relPath, filePath);
                            continue;
                        }
                    }

                    if (line.IndexOf("pell", StringComparison.Ordinal) >= 0) {
                        Match mSpl = rxExplicitSpell.Match(line);
                        if (mSpl.Success) {
                            int idVal = int.Parse(mSpl.Groups[1].Value);
                            AddLootEntry(addonStat, "Spell", idVal, 0, inlineComment, fileEra, currentContentType, addonName, baseFileNoExt, "", "", "Normal", "Both", "", "", addonName, fileName, relPath, filePath);
                            continue;
                        }
                    }

                    if (line.IndexOf("pc", StringComparison.Ordinal) >= 0 || line.IndexOf("reature", StringComparison.Ordinal) >= 0) {
                        Match mNpc = rxExplicitNpc.Match(line);
                        if (mNpc.Success) {
                            int idVal = int.Parse(mNpc.Groups[1].Value);
                            AddLootEntry(addonStat, "NPC", idVal, 0, inlineComment, fileEra, currentContentType, addonName, baseFileNoExt, "", "", "Normal", "Both", "", "", addonName, fileName, relPath, filePath);
                            continue;
                        }
                        Match mBoss = rxExplicitBoss.Match(line);
                        if (mBoss.Success) {
                            int idVal = int.Parse(mBoss.Groups[1].Value);
                            AddLootEntry(addonStat, "NPC", idVal, 0, inlineComment, fileEra, currentContentType, addonName, baseFileNoExt, "", "", "Normal", "Both", "", "", addonName, fileName, relPath, filePath);
                            continue;
                        }
                    }
                }
                continue;
            }

            Match mTT = rxTableType.Match(line);
            if (mTT.Success) {
                string ttRaw = mTT.Groups[1].Value;
                string mapped = "Item";
                if (ttRaw.Contains("PROF")) mapped = "Spell";
                else if (ttRaw.Contains("SET")) mapped = "Set";
                if (!inItemsArray) currentTableType = mapped;
                else activeSubTableType = mapped;
            }

            Match mCT = rxContentType.Match(line);
            if (mCT.Success) currentContentType = MapContentType(mCT.Groups[1].Value, currentModuleKey);

            Match mPh = rxPhase.Match(line);
            if (mPh.Success) currentPhase = "P" + mPh.Groups[1].Value;

            if (trimmed.StartsWith("items = {")) {
                inItemsArray = true;
                continue;
            }

            Match mMap = rxMapID.Match(line);
            if (mMap.Success) {
                int mapId = int.Parse(mMap.Groups[1].Value);
                string resolvedMap = MapNames.ContainsKey(mapId) ? MapNames[mapId] : ("Map_" + mapId);
                if (!inItemsArray) currentCategoryName = resolvedMap;
                else { currentSubSection = resolvedMap; currentBossHeader = ""; }
                continue;
            }

            Match mFac = rxFactionID.Match(line);
            if (mFac.Success) {
                int facId = int.Parse(mFac.Groups[1].Value);
                string resolvedFac = FactionNames.ContainsKey(facId) ? FactionNames[facId] : ("Faction_" + facId);
                if (!inItemsArray) currentCategoryName = resolvedFac;
                else currentSubSection = resolvedFac;
                continue;
            }

            Match mNameLine = rxNameLine.Match(line);
            if (mNameLine.Success) {
                string cleaned = CleanLuaExpr(mNameLine.Groups[1].Value);
                if (!inItemsArray) currentCategoryName = cleaned;
                else { currentSubSection = cleaned; currentBossHeader = ""; activeSubTableType = ""; }
                continue;
            }

            Match mDiff = rxDiffHeader.Match(line);
            if (mDiff.Success) {
                string dTok = mDiff.Groups[1].Value;
                if (dTok.EndsWith("_DIFF")) {
                    currentDifficulty = MapDiffLabel(dTok);
                    if (dTok.Contains("ALLIANCE")) currentFaction = "Alliance";
                    else if (dTok.Contains("HORDE")) currentFaction = "Horde";
                    else currentFaction = "Both";
                    currentBossHeader = "";
                    continue;
                }
                if (dTok.EndsWith("_ITTYPE")) {
                    currentDifficulty = "Normal";
                    currentFaction = "Both";
                    currentBossHeader = "";
                    continue;
                }
            }

            Match mBox = rxBoxDivider.Match(line);
            if (mBox.Success) {
                currentBossHeader = CleanLuaExpr(mBox.Groups[1].Value);
                continue;
            }

            string effectiveType = !string.IsNullOrEmpty(activeSubTableType) ? activeSubTableType : currentTableType;

            Match mDual = rxDualFaction.Match(line);
            if (mDual.Success) {
                int allyID = int.Parse(mDual.Groups[1].Value);
                int hordeID = int.Parse(mDual.Groups[2].Value);
                string comment = mDual.Groups[3].Success ? mDual.Groups[3].Value.Trim() : "";
                AddLootEntry(addonStat, effectiveType, allyID, hordeID, comment, fileEra, currentContentType, currentModuleKey, currentCategoryName, currentSubSection, currentBossHeader, currentDifficulty, "Alliance", "", currentPhase, addonName, fileName, relPath, filePath);
                AddLootEntry(addonStat, effectiveType, hordeID, allyID, comment, fileEra, currentContentType, currentModuleKey, currentCategoryName, currentSubSection, currentBossHeader, currentDifficulty, "Horde", "", currentPhase, addonName, fileName, relPath, filePath);
                schemaRowCount += 2;
                continue;
            }

            Match mVer = rxGetVersion.Match(line);
            if (mVer.Success) {
                int idClassic = int.Parse(mVer.Groups[1].Value);
                int idTBC = int.Parse(mVer.Groups[2].Value);
                string comment = mVer.Groups[3].Success ? mVer.Groups[3].Value.Trim() : "";
                AddLootEntry(addonStat, effectiveType, idClassic, idTBC, comment, "Classic", currentContentType, currentModuleKey, currentCategoryName, currentSubSection, currentBossHeader, currentDifficulty, currentFaction, "", currentPhase, addonName, fileName, relPath, filePath);
                AddLootEntry(addonStat, effectiveType, idTBC, idClassic, comment, "TBC", currentContentType, currentModuleKey, currentCategoryName, currentSubSection, currentBossHeader, currentDifficulty, currentFaction, "", currentPhase, addonName, fileName, relPath, filePath);
                schemaRowCount += 2;
                continue;
            }

            Match mGE = rxGameVerGE.Match(line);
            if (mGE.Success) {
                string verTok = mGE.Groups[1].Value;
                int idVal = int.Parse(mGE.Groups[2].Value);
                string comment = mGE.Groups[3].Success ? mGE.Groups[3].Value.Trim() : "";
                string geEra = verTok.Contains("WRATH") ? "Wrath" : (verTok.Contains("BC") ? "TBC" : fileEra);
                AddLootEntry(addonStat, effectiveType, idVal, 0, comment, geEra, currentContentType, currentModuleKey, currentCategoryName, currentSubSection, currentBossHeader, currentDifficulty, currentFaction, "", currentPhase, addonName, fileName, relPath, filePath);
                schemaRowCount++;
                continue;
            }

            Match mPref = rxPrefixedItem.Match(line);
            if (mPref.Success) {
                int itemVal = int.Parse(mPref.Groups[1].Value);
                string comment = mPref.Groups[2].Success ? mPref.Groups[2].Value.Trim() : "";
                AddLootEntry(addonStat, "Item", itemVal, 0, comment, fileEra, currentContentType, currentModuleKey, currentCategoryName, currentSubSection, currentBossHeader, currentDifficulty, currentFaction, "", currentPhase, addonName, fileName, relPath, filePath);
                schemaRowCount++;
                continue;
            }

            Match mStd = rxStandardEntry.Match(line);
            if (mStd.Success) {
                int mainID = int.Parse(mStd.Groups[2].Value);
                string midTail = mStd.Groups[3].Value;
                string comment = mStd.Groups[4].Success ? mStd.Groups[4].Value.Trim() : "";
                string priceInfo = "";
                int secID = 0;

                if (!string.IsNullOrEmpty(midTail) && midTail.IndexOf('[') >= 0) {
                    if (midTail.IndexOf("PRICE_EXTRA_ITTYPE", StringComparison.Ordinal) >= 0) {
                        Match mPriceStr = Regex.Match(midTail, @"\[PRICE_EXTRA_ITTYPE\]\s*=\s*""([^""]+)""");
                        if (mPriceStr.Success) priceInfo = mPriceStr.Groups[1].Value;
                    } else if (midTail.IndexOf("ATLASLOOT_IT_AMOUNT2", StringComparison.Ordinal) >= 0) {
                        Match mTicket = Regex.Match(midTail, @",\s*(\d+)\s*,\s*\[ATLASLOOT_IT_AMOUNT2\]\s*=\s*(\d+)");
                        if (mTicket.Success) {
                            secID = int.Parse(mTicket.Groups[1].Value);
                            priceInfo = "Item_" + mTicket.Groups[1].Value + ":" + mTicket.Groups[2].Value;
                        }
                    }
                }

                AddLootEntry(addonStat, effectiveType, mainID, secID, comment, fileEra, currentContentType, currentModuleKey, currentCategoryName, currentSubSection, currentBossHeader, currentDifficulty, currentFaction, priceInfo, currentPhase, addonName, fileName, relPath, filePath);
                schemaRowCount++;
                if (string.IsNullOrEmpty(schemaSampleRow)) schemaSampleRow = trimmed;
            }
        }

        RecordDatasetSchemaIfEligible(addonName, relPath, schemaTableName, schemaKeyType, schemaRowCount, schemaSampleKeys, schemaSampleRow, fileEra);
    }

    public static void AddLootEntry(AddonTelemetry addonStat, string idType, int id, int secId, string name, string era, string content, string modKey, string catName, string subSec, string bossHdr, string diff, string fac, string price, string phase, string srcAddon, string srcFile, string relPath, string fullPath) {
        if (id <= 0) return;
        string key = idType + SEP + id + SEP + era + SEP + modKey + SEP + subSec + SEP + bossHdr + SEP + diff + SEP + fac;
        if (!CurrentAddonDedupKeys.Add(key)) return;

        LootRecord r = new LootRecord();
        r.IDType = idType;
        r.ID = id;
        r.SecondaryID = secId;
        r.Name = SanitizeField(name);
        r.Era = SanitizeField(era);
        r.ContentType = SanitizeField(content);
        r.ModuleKey = SanitizeField(modKey);
        r.CategoryName = string.IsNullOrEmpty(catName) ? SanitizeField(modKey) : SanitizeField(catName);
        r.SubSectionName = SanitizeField(subSec);
        r.BossOrHeader = SanitizeField(bossHdr);
        r.Difficulty = SanitizeField(diff);
        r.Faction = SanitizeField(fac);
        r.PriceOrCost = SanitizeField(price);
        r.Phase = SanitizeField(phase);
        r.SourceAddon = SanitizeField(srcAddon);
        r.SourceFile = SanitizeField(srcFile);
        r.ParentRelativePath = SanitizeField(string.IsNullOrEmpty(relPath) ? (srcAddon + "\\" + srcFile) : (srcAddon + "\\" + relPath));
        r.ParentFullDiskPath = SanitizeField(fullPath);

        CurrentFileRecords.Add(r);
        TotalSavedDataRecordsOnDisk++;

        if (addonStat != null) {
            addonStat.DataRecordsCount++;
            if (idType == "Item") addonStat.ItemIDsCount++;
            else if (idType == "Spell") addonStat.SpellIDsCount++;
            else addonStat.QuestOrNpcIDsCount++;
        }

        if (CurrentFileRecords.Count >= 2500 && !string.IsNullOrEmpty(ActiveStudioDirForMidFlush)) {
            FlushSingleFileDataToDisk(ActiveStudioDirForMidFlush);
        }
    }

}
// ============================================================================
// DECONSTRUCTION GOD STUDIO v14.3 - MODULAR NODE SYSTEM
// NODE INDEX  : [13] OF [35]
// FILE NAME   : Node_13_AltVaultBridge.cs
// PARTIAL OF  : DataRipperEngine (AltVault Bridge)
// ============================================================================








public static partial class DataRipperEngine {
    // ========================================================================
    // SECTION 7.0: PER-FILE / MID-FILE DIRECT DISK FLUSHING & ON-DEMAND LOADER
    // ========================================================================
    public static void FlushSingleFileDataToDisk(string studioDir) {
        if (CurrentFileRecords.Count == 0 && CurrentFileSchemas.Count == 0) return;
        string troughDir = ResolveTroughDir(studioDir);
        if (!Directory.Exists(troughDir)) Directory.CreateDirectory(troughDir);
        UTF8Encoding utf8NoBom = new UTF8Encoding(false);

        if (CurrentFileRecords.Count > 0) {
            string dataPath = Path.Combine(troughDir, "Trough_GameDataRecords.tsv");
            using (StreamWriter swData = new StreamWriter(dataPath, true, utf8NoBom, 65536)) {
                for (int i = 0; i < CurrentFileRecords.Count; i++) {
                    LootRecord r = CurrentFileRecords[i];
                    string[] cols = new string[] {
                        r.IDType, r.ID.ToString(), r.SecondaryID.ToString(), r.Name, r.Era,
                        r.ContentType, r.ModuleKey, r.CategoryName, r.SubSectionName,
                        r.BossOrHeader, r.Difficulty, r.Faction, r.PriceOrCost, r.Phase,
                        r.SourceAddon, r.SourceFile, r.ParentRelativePath, r.ParentFullDiskPath
                    };
                    swData.WriteLine(string.Join(TAB, cols));
                }
            }
            CurrentFileRecords.Clear();
        }

        if (CurrentFileSchemas.Count > 0) {
            string schemaPath = Path.Combine(troughDir, "Trough_DatasetSchemas.tsv");
            using (StreamWriter swSchema = new StreamWriter(schemaPath, true, utf8NoBom)) {
                for (int i = 0; i < CurrentFileSchemas.Count; i++) {
                    DatasetSchemaRecord ds = CurrentFileSchemas[i];
                    string[] cols = new string[] {
                        ds.AddonName, ds.RelativePath, ds.TableName, ds.KeyType,
                        ds.RowCount.ToString(), ds.SampleKeys, ds.SampleRowPreview, ds.Era
                    };
                    swSchema.WriteLine(string.Join(TAB, cols));
                }
            }
            CurrentFileSchemas.Clear();
        }
    }

    public static void SaveAddonInventoryTableToDisk(string studioDir) {
        string troughDir = ResolveTroughDir(studioDir);
        if (!Directory.Exists(troughDir)) Directory.CreateDirectory(troughDir);
        UTF8Encoding utf8NoBom = new UTF8Encoding(false);
        string invPath = Path.Combine(troughDir, "Trough_AddonsInventory.tsv");

        using (StreamWriter swInv = new StreamWriter(invPath, false, utf8NoBom)) {
            for (int i = 0; i < AddonStatsList.Count; i++) {
                AddonTelemetry st = AddonStatsList[i];
                if (st.TotalFolders <= 0 && !string.IsNullOrEmpty(st.FolderPath)) {
                    st.TotalFolders = FastCountDirectoriesSafe(st.FolderPath);
                }
                string[] cols = new string[] {
                    SanitizeField(st.AddonName),
                    SanitizeField(st.FolderPath),
                    SanitizeField(st.LastWriteSignature),
                    SanitizeField(st.StatusBadge),
                    st.TotalFiles.ToString(),
                    st.LuaFiles.ToString(),
                    st.XmlFiles.ToString(),
                    st.TocFiles.ToString(),
                    st.CodeOtherFiles.ToString(),
                    st.DataRecordsCount.ToString(),
                    st.ItemIDsCount.ToString(),
                    st.SpellIDsCount.ToString(),
                    st.QuestOrNpcIDsCount.ToString(),
                    st.FunctionsCount.ToString(),
                    st.BlueprintsCount.ToString(),
                    st.CreativeBricksCount.ToString(),
                    st.TotalFolders.ToString()
                };
                swInv.WriteLine(string.Join(TAB, cols));
            }
        }
    }

    public static void PurgeParentFromDiskDataTrough(string studioDir, HashSet<string> parentsToPurge) {
        string troughDir = ResolveTroughDir(studioDir);
        string dataPath   = Path.Combine(troughDir, "Trough_GameDataRecords.tsv");
        string schemaPath = Path.Combine(troughDir, "Trough_DatasetSchemas.tsv");
        UTF8Encoding utf8NoBom = new UTF8Encoding(false);

        if (parentsToPurge.Count >= 500) {
            if (File.Exists(dataPath)) File.WriteAllText(dataPath, "", utf8NoBom);
            if (File.Exists(schemaPath)) File.WriteAllText(schemaPath, "", utf8NoBom);
            TotalSavedDataRecordsOnDisk = 0;
            TotalSavedDatasetSchemasOnDisk = 0;
            return;
        }
        if (!File.Exists(dataPath)) return;

        string tempPath = dataPath + ".tmp";
        int kept = 0;

        using (StreamReader sr = new StreamReader(dataPath, Encoding.UTF8))
        using (StreamWriter sw = new StreamWriter(tempPath, false, utf8NoBom)) {
            string ln;
            while ((ln = sr.ReadLine()) != null) {
                if (string.IsNullOrWhiteSpace(ln)) continue;
                string[] c = ln.Split('\t');
                if (c.Length >= 15 && parentsToPurge.Contains(c[14])) {
                    continue;
                }
                sw.WriteLine(ln);
                kept++;
            }
        }
        File.Delete(dataPath);
        File.Move(tempPath, dataPath);
        TotalSavedDataRecordsOnDisk = kept;
    }

    private static string SafeRawBlobLine(string s) {
        if (string.IsNullOrEmpty(s)) return "";
        return s.Replace("[[", "(").Replace("]]", ")").Replace("[===[", "(").Replace("]===]", ")").Replace("\r", "").Replace("\n", " ").Trim();
    }

    public static void StreamLuaFeederFromDiskTrough(string studioDir, string altVaultOutputDir, Action<string> logCallback, out int uniqueItems, out int uniqueSpells, out int uniqueSets, out int uniqueQuests) {
        uniqueItems = 0; uniqueSpells = 0; uniqueSets = 0; uniqueQuests = 0;
        string troughDir = ResolveTroughDir(studioDir);
        if (!Directory.Exists(troughDir)) Directory.CreateDirectory(troughDir);

        UTF8Encoding utf8NoBom = new UTF8Encoding(false);
        string pyPath = Path.Combine(troughDir, "Build_SQLite_DB.py");
        using (StreamWriter swPy = new StreamWriter(pyPath, false, utf8NoBom)) {
            swPy.WriteLine("#!/usr/bin/env python3");
            swPy.WriteLine("import os, sqlite3");
            swPy.WriteLine("base_dir = os.path.dirname(os.path.abspath(__file__))");
            swPy.WriteLine("db_path = os.path.join(base_dir, 'DeconstructionTrough.sqlite3')");
            swPy.WriteLine("conn = sqlite3.connect(db_path)");
            swPy.WriteLine("for fname in ['Trough_MasterSchema.sql', 'Trough_CodeVaultSchema.sql']:");
            swPy.WriteLine("    fpath = os.path.join(base_dir, fname)");
            swPy.WriteLine("    if os.path.exists(fpath):");
            swPy.WriteLine("        with open(fpath, 'r', encoding='utf-8') as f: conn.executescript(f.read())");
            swPy.WriteLine("conn.commit()");
            swPy.WriteLine("conn.close()");
            swPy.WriteLine("print('Built Portable SQLite3 Trough:', db_path)");
        }

        string dataPath = Path.Combine(troughDir, "Trough_GameDataRecords.tsv");
        if (!File.Exists(dataPath) || new FileInfo(dataPath).Length < 64) {
            string altDataPath = Path.Combine(troughDir, "Trough_DataRecords.tsv");
            if (File.Exists(altDataPath) && new FileInfo(altDataPath).Length > 0) dataPath = altDataPath;
        }

        if (string.IsNullOrEmpty(altVaultOutputDir) || string.Equals(altVaultOutputDir.TrimEnd('\\', '/'), studioDir.TrimEnd('\\', '/'), StringComparison.OrdinalIgnoreCase)) {
            DirectoryInfo parentDir = Directory.GetParent(studioDir);
            if (parentDir != null) {
                string siblingAltVault = Path.Combine(parentDir.FullName, "AltVault");
                if (Directory.Exists(siblingAltVault)) {
                    altVaultOutputDir = siblingAltVault;
                }
            }
        }

        if (!File.Exists(dataPath) || string.IsNullOrEmpty(altVaultOutputDir)) return;
        if (!Directory.Exists(altVaultOutputDir)) Directory.CreateDirectory(altVaultOutputDir);

        string dbTankSubDir = Path.Combine(altVaultOutputDir, "DB_Tank");
        if (Directory.Exists(dbTankSubDir)) {
            try { Directory.Delete(dbTankSubDir, true); } catch {}
        }
        Directory.CreateDirectory(dbTankSubDir);

        HashSet<int> uItm = new HashSet<int>();
        HashSet<int> uSpl = new HashSet<int>();
        HashSet<int> uSet = new HashSet<int>();
        HashSet<int> uQst = new HashSet<int>();

        List<string> generatedNodeRelPaths = new List<string>();
        int recordsPerNodeFile = 60000;
        int recordsPerRawBlob  = 500;

        int totalIdx = 0;
        int currentNodeNum = 0;
        int recordsInCurrentNode = 0;
        int recordsInCurrentBlob = 0;
        StreamWriter swNode = null;

        using (StreamReader sr = new StreamReader(dataPath, Encoding.UTF8)) {
            string ln;
            while ((ln = sr.ReadLine()) != null) {
                if (string.IsNullOrWhiteSpace(ln)) continue;
                string[] c = ln.Split('\t');
                if (c.Length < 15) continue;

                int idVal = 0;
                int.TryParse(c[1], out idVal);
                if (idVal <= 0) continue;

                totalIdx++;
                string idType = c[0];
                if (idType == "Item" || idType == "DB_Entry") uItm.Add(idVal);
                else if (idType == "Spell") uSpl.Add(idVal);
                else if (idType == "Set") uSet.Add(idVal);
                else uQst.Add(idVal);

                if (swNode == null || recordsInCurrentNode >= recordsPerNodeFile) {
                    if (swNode != null) {
                        if (recordsInCurrentBlob > 0) {
                            swNode.WriteLine("]===]");
                            recordsInCurrentBlob = 0;
                        }
                        swNode.Close();
                        swNode.Dispose();
                    }
                    currentNodeNum++;
                    recordsInCurrentNode = 0;
                    string nodeFileName = string.Format("DB_TankNode_{0:D2}.lua", currentNodeNum);
                    string nodeFullPath = Path.Combine(dbTankSubDir, nodeFileName);
                    generatedNodeRelPaths.Add("DB_Tank\\" + nodeFileName);

                    swNode = new StreamWriter(nodeFullPath, false, utf8NoBom);
                    swNode.WriteLine("-- ============================================================================");
                    swNode.WriteLine("-- ALTVAULT HOLDING TANK DATA NODE [" + currentNodeNum + "] (500-ROW RAW BLOB PACKETS)");
                    swNode.WriteLine("-- ============================================================================");
                    swNode.WriteLine("local MasterDB = _G.AltVaultMasterDB");
                    swNode.WriteLine("if not MasterDB or not MasterDB.RawBlobs then return end");
                    swNode.WriteLine("local blobs = MasterDB.RawBlobs");
                }

                if (recordsInCurrentBlob == 0) {
                    swNode.WriteLine("blobs[#blobs + 1] = [===[");
                }

                string parentRel = (c.Length >= 17) ? c[16] : (c[14] + "\\" + c[15]);
                string packedLine = string.Join(SEP, new string[] {
                    SafeRawBlobLine(idType), c[1], SafeRawBlobLine(c[3]), SafeRawBlobLine(c[4]),
                    SafeRawBlobLine(c[5]), SafeRawBlobLine(c[6]), SafeRawBlobLine(c[7]),
                    SafeRawBlobLine(c[8]), SafeRawBlobLine(c[9]), SafeRawBlobLine(c[10]),
                    SafeRawBlobLine(c[11]), SafeRawBlobLine(c[12]), SafeRawBlobLine(c[13]),
                    SafeRawBlobLine(parentRel)
                });
                swNode.WriteLine(packedLine);

                recordsInCurrentNode++;
                recordsInCurrentBlob++;

                if (recordsInCurrentBlob >= recordsPerRawBlob) {
                    swNode.WriteLine("]===]");
                    recordsInCurrentBlob = 0;
                }
            }
        }

        if (swNode != null) {
            if (recordsInCurrentBlob > 0) {
                swNode.WriteLine("]===]");
            }
            swNode.Close();
            swNode.Dispose();
        }

        string luaPath = Path.Combine(altVaultOutputDir, "DB_MasterHoldingTank.lua");
        using (StreamWriter swLua = new StreamWriter(luaPath, false, utf8NoBom)) {
            swLua.WriteLine("-- ============================================================================");
            swLua.WriteLine("-- ALTVAULT MASTER HOLDING TANK CONTROLLER (MULTI-NODE RAW BLOB ARCHITECTURE)");
            swLua.WriteLine("-- Total Records Across " + generatedNodeRelPaths.Count + " Data Nodes: " + totalIdx);
            swLua.WriteLine("-- ============================================================================");
            swLua.WriteLine("local addonName, ns = ...");
            swLua.WriteLine("ns = ns or {}");
            swLua.WriteLine("ns.MasterDB = ns.MasterDB or {}");
            swLua.WriteLine("local MasterDB = ns.MasterDB");
            swLua.WriteLine("_G.AltVaultMasterDB = MasterDB");
            swLua.WriteLine("");
            swLua.WriteLine("MasterDB.RawBlobs = MasterDB.RawBlobs or {}");
            swLua.WriteLine("MasterDB.HoldingTank = MasterDB.HoldingTank or {}");
            swLua.WriteLine("");
            swLua.WriteLine("MasterDB.RacesAndSex = {");
            swLua.WriteLine("    [1]  = { raceID = 1,  name = \"Human\",     raceFile = \"Human\",    faction = \"Alliance\", maleSexID = 2, femaleSexID = 3, maleCustomGender = 0, femaleCustomGender = 1 },");
            swLua.WriteLine("    [2]  = { raceID = 2,  name = \"Orc\",       raceFile = \"Orc\",      faction = \"Horde\",    maleSexID = 2, femaleSexID = 3, maleCustomGender = 0, femaleCustomGender = 1 },");
            swLua.WriteLine("    [3]  = { raceID = 3,  name = \"Dwarf\",     raceFile = \"Dwarf\",    faction = \"Alliance\", maleSexID = 2, femaleSexID = 3, maleCustomGender = 0, femaleCustomGender = 1 },");
            swLua.WriteLine("    [4]  = { raceID = 4,  name = \"Night Elf\", raceFile = \"NightElf\", faction = \"Alliance\", maleSexID = 2, femaleSexID = 3, maleCustomGender = 0, femaleCustomGender = 1 },");
            swLua.WriteLine("    [5]  = { raceID = 5,  name = \"Undead\",    raceFile = \"Scourge\",  faction = \"Horde\",    maleSexID = 2, femaleSexID = 3, maleCustomGender = 0, femaleCustomGender = 1 },");
            swLua.WriteLine("    [6]  = { raceID = 6,  name = \"Tauren\",    raceFile = \"Tauren\",   faction = \"Horde\",    maleSexID = 2, femaleSexID = 3, maleCustomGender = 0, femaleCustomGender = 1 },");
            swLua.WriteLine("    [7]  = { raceID = 7,  name = \"Gnome\",     raceFile = \"Gnome\",    faction = \"Alliance\", maleSexID = 2, femaleSexID = 3, maleCustomGender = 0, femaleCustomGender = 1 },");
            swLua.WriteLine("    [8]  = { raceID = 8,  name = \"Troll\",     raceFile = \"Troll\",    faction = \"Horde\",    maleSexID = 2, femaleSexID = 3, maleCustomGender = 0, femaleCustomGender = 1 },");
            swLua.WriteLine("    [9]  = { raceID = 9,  name = \"Goblin\",    raceFile = \"Goblin\",   faction = \"Horde\",    maleSexID = 2, femaleSexID = 3, maleCustomGender = 0, femaleCustomGender = 1 },");
            swLua.WriteLine("    [10] = { raceID = 10, name = \"Blood Elf\", raceFile = \"BloodElf\", faction = \"Horde\",    maleSexID = 2, femaleSexID = 3, maleCustomGender = 0, femaleCustomGender = 1 },");
            swLua.WriteLine("    [11] = { raceID = 11, name = \"Draenei\",   raceFile = \"Draenei\",  faction = \"Alliance\", maleSexID = 2, femaleSexID = 3, maleCustomGender = 0, femaleCustomGender = 1 },");
            swLua.WriteLine("    [22] = { raceID = 22, name = \"Worgen\",    raceFile = \"Worgen\",   faction = \"Alliance\", maleSexID = 2, femaleSexID = 3, maleCustomGender = 0, femaleCustomGender = 1 },");
            swLua.WriteLine("    [24] = { raceID = 24, name = \"Pandaren\",  raceFile = \"Pandaren\", faction = \"Both\",     maleSexID = 2, femaleSexID = 3, maleCustomGender = 0, femaleCustomGender = 1 },");
            swLua.WriteLine("}");
            swLua.WriteLine("");
            swLua.WriteLine("MasterDB.Classes = {");
            swLua.WriteLine("    [1]  = { classID = 1,  token = \"WARRIOR\",     name = \"Warrior\",      hex = \"c79c6e\", lowArmor = \"Mail\",    highArmor = \"Plate\",   canShield = true  },");
            swLua.WriteLine("    [2]  = { classID = 2,  token = \"PALADIN\",     name = \"Paladin\",      hex = \"f58cba\", lowArmor = \"Mail\",    highArmor = \"Plate\",   canShield = true  },");
            swLua.WriteLine("    [3]  = { classID = 3,  token = \"HUNTER\",      name = \"Hunter\",       hex = \"abd473\", lowArmor = \"Leather\", highArmor = \"Mail\",    canShield = false },");
            swLua.WriteLine("    [4]  = { classID = 4,  token = \"ROGUE\",       name = \"Rogue\",        hex = \"fff569\", lowArmor = \"Leather\", highArmor = \"Leather\", canShield = false },");
            swLua.WriteLine("    [5]  = { classID = 5,  token = \"PRIEST\",      name = \"Priest\",       hex = \"ffffff\", lowArmor = \"Cloth\",   highArmor = \"Cloth\",   canShield = false },");
            swLua.WriteLine("    [6]  = { classID = 6,  token = \"DEATHKNIGHT\", name = \"Death Knight\", hex = \"c41f3b\", lowArmor = \"Plate\",   highArmor = \"Plate\",   canShield = false },");
            swLua.WriteLine("    [7]  = { classID = 7,  token = \"SHAMAN\",      name = \"Shaman\",       hex = \"0070de\", lowArmor = \"Leather\", highArmor = \"Mail\",    canShield = true  },");
            swLua.WriteLine("    [8]  = { classID = 8,  token = \"MAGE\",        name = \"Mage\",         hex = \"40c7eb\", lowArmor = \"Cloth\",   highArmor = \"Cloth\",   canShield = false },");
            swLua.WriteLine("    [9]  = { classID = 9,  token = \"WARLOCK\",     name = \"Warlock\",      hex = \"8787ed\", lowArmor = \"Cloth\",   highArmor = \"Cloth\",   canShield = false },");
            swLua.WriteLine("    [10] = { classID = 10, token = \"MONK\",        name = \"Monk\",         hex = \"00ff96\", lowArmor = \"Leather\", highArmor = \"Leather\", canShield = false },");
            swLua.WriteLine("    [11] = { classID = 11, token = \"DRUID\",       name = \"Druid\",        hex = \"ff7d0a\", lowArmor = \"Leather\", highArmor = \"Leather\", canShield = false },");
            swLua.WriteLine("}");
            swLua.WriteLine("");
            swLua.WriteLine("MasterDB.Stats = {");
            swLua.WriteLine("    TotalRecords = " + totalIdx + ",");
            swLua.WriteLine("    UniqueItems = " + uItm.Count + ",");
            swLua.WriteLine("    UniqueSpells = " + uSpl.Count + ",");
            swLua.WriteLine("    UniqueSets = " + uSet.Count + ",");
            swLua.WriteLine("    UniqueQuestsAndNPCs = " + uQst.Count + ",");
            swLua.WriteLine("}");
        }

        string tocPath = Path.Combine(altVaultOutputDir, "AltVault.toc");
        if (File.Exists(tocPath)) {
            string[] oldTocLines = File.ReadAllLines(tocPath, Encoding.UTF8);
            List<string> newTocLines = new List<string>();
            bool insertedTankNodes = false;

            for (int i = 0; i < oldTocLines.Length; i++) {
                string t = oldTocLines[i].Trim();
                if (t.StartsWith("DB_Tank\\DB_TankNode_", StringComparison.OrdinalIgnoreCase)) continue;
                if (string.Equals(t, "DB_MasterHoldingTank.lua", StringComparison.OrdinalIgnoreCase)) {
                    if (!insertedTankNodes) {
                        newTocLines.Add("DB_MasterHoldingTank.lua");
                        for (int n = 0; n < generatedNodeRelPaths.Count; n++) {
                            newTocLines.Add(generatedNodeRelPaths[n]);
                        }
                        insertedTankNodes = true;
                    }
                    continue;
                }
                newTocLines.Add(oldTocLines[i]);
            }
            File.WriteAllLines(tocPath, newTocLines.ToArray(), utf8NoBom);
        }

        TotalSavedDataRecordsOnDisk = totalIdx;
        uniqueItems  = uItm.Count;
        uniqueSpells = uSpl.Count;
        uniqueSets   = uSet.Count;
        uniqueQuests = uQst.Count;
        if (logCallback != null) {
            logCallback("Streamed ALL " + totalIdx + " records across " + generatedNodeRelPaths.Count + " Data Nodes into: " + dbTankSubDir + " and updated AltVault.toc!");
        }
    }

    public static void QueryDataTroughOnDemand(string studioDir, string filterAddon, string filterType, string filterEra, string keyword, int maxResults) {
        ExtractedRecords.Clear();
        string troughDir = ResolveTroughDir(studioDir);
        string dataPath  = Path.Combine(troughDir, "Trough_GameDataRecords.tsv");
        if (!File.Exists(dataPath) || new FileInfo(dataPath).Length < 64) {
            string altDataPath = Path.Combine(troughDir, "Trough_DataRecords.tsv");
            if (File.Exists(altDataPath) && new FileInfo(altDataPath).Length > 0) dataPath = altDataPath;
        }
        if (!File.Exists(dataPath)) return;

        string kw = (keyword ?? "").Trim().ToLowerInvariant();
        using (StreamReader sr = new StreamReader(dataPath, Encoding.UTF8)) {
            string ln;
            while ((ln = sr.ReadLine()) != null) {
                if (string.IsNullOrWhiteSpace(ln)) continue;
                string[] c = ln.Split('\t');
                if (c.Length < 16) continue;

                if (filterAddon != "ALL PARENT ADDONS" && !string.Equals(c[14], filterAddon, StringComparison.OrdinalIgnoreCase)) continue;
                if (filterType != "ALL TYPES" && !string.Equals(c[0], filterType, StringComparison.OrdinalIgnoreCase)) continue;
                if (filterEra != "ALL ERAS" && !string.Equals(c[4], filterEra, StringComparison.OrdinalIgnoreCase)) continue;

                if (kw.Length > 0) {
                    if (ln.ToLowerInvariant().IndexOf(kw) < 0) continue;
                }

                LootRecord r = new LootRecord();
                r.IDType = c[0];
                int.TryParse(c[1], out r.ID);
                int.TryParse(c[2], out r.SecondaryID);
                r.Name = c[3];
                r.Era = c[4];
                r.ContentType = c[5];
                r.ModuleKey = c[6];
                r.CategoryName = c[7];
                r.SubSectionName = c[8];
                r.BossOrHeader = c[9];
                r.Difficulty = c[10];
                r.Faction = c[11];
                r.PriceOrCost = c[12];
                r.Phase = c[13];
                r.SourceAddon = c[14];
                r.SourceFile = c[15];
                r.ParentRelativePath = (c.Length >= 17) ? c[16] : (c[14] + "\\" + c[15]);
                r.ParentFullDiskPath = (c.Length >= 18) ? c[17] : "";
                ExtractedRecords.Add(r);

                if (ExtractedRecords.Count >= maxResults) break;
            }
        }
    }

    public static void QueryDatasetSchemasOnDemand(string studioDir, string filterAddon, string keyword, int maxResults) {
        ExtractedSchemas.Clear();
        string troughDir = ResolveTroughDir(studioDir);
        string schemaPath = Path.Combine(troughDir, "Trough_DatasetSchemas.tsv");
        if (!File.Exists(schemaPath)) return;

        string kw = (keyword ?? "").Trim().ToLowerInvariant();
        using (StreamReader sr = new StreamReader(schemaPath, Encoding.UTF8)) {
            string ln;
            while ((ln = sr.ReadLine()) != null) {
                if (string.IsNullOrWhiteSpace(ln)) continue;
                string[] c = ln.Split('\t');
                if (c.Length < 8) continue;

                if (filterAddon != "ALL PARENT ADDONS" && !string.Equals(c[0], filterAddon, StringComparison.OrdinalIgnoreCase)) continue;
                if (kw.Length > 0 && ln.ToLowerInvariant().IndexOf(kw) < 0) continue;

                DatasetSchemaRecord ds = new DatasetSchemaRecord();
                ds.AddonName = c[0];
                ds.RelativePath = c[1];
                ds.TableName = c[2];
                ds.KeyType = c[3];
                int.TryParse(c[4], out ds.RowCount);
                ds.SampleKeys = c[5];
                ds.SampleRowPreview = c[6];
                ds.Era = c[7];
                ExtractedSchemas.Add(ds);
                if (ExtractedSchemas.Count >= maxResults) break;
            }
        }
    }
}

