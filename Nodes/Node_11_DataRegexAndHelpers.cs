// ============================================================================
// DECONSTRUCTION GOD STUDIO v14.3 - MODULAR NODE SYSTEM
// NODE INDEX  : [11] OF [35]
// FILE NAME   : Node_11_DataRegexAndHelpers.cs
// PARTIAL OF  : DataRipperEngine
// ============================================================================
using System;
using System.IO;
using System.Net;
using System.Text;
using System.Drawing;
using System.Windows.Forms;
using System.Text.RegularExpressions;
using System.Collections.Generic;

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