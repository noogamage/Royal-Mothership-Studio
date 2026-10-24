// ============================================================================
// DECONSTRUCTION GOD STUDIO v14.3 - MODULAR NODE SYSTEM
// NODE INDEX  : [10] OF [35]
// FILE NAME   : Node_10_DataModels.cs
// PARTIAL OF  : LootRecord, DatasetSchemaRecord, AddonTelemetry, DataRipperEngine
// ============================================================================
using System;
using System.IO;
using System.Net;
using System.Text;
using System.Drawing;
using System.Windows.Forms;
using System.Text.RegularExpressions;
using System.Collections.Generic;

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
