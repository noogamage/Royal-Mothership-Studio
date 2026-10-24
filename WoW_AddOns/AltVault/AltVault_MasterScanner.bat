@echo off
title AltVault Addon Deconstruction God and Master Holding Tank Studio
set "SELF=%~f0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$lines = [System.IO.File]::ReadAllLines($env:SELF); $script = ($lines[7..($lines.Length - 1)]) -join \"`r`n\"; Invoke-Expression $script"
if errorlevel 1 pause
exit /b
# --- POWERSHELL & INLINE C# START ON LINE 8 ---

Add-Type -AssemblyName System.Windows.Forms;
Add-Type -AssemblyName System.Drawing;

$csharpSource = @'
using System;
using System.IO;
using System.Text;
using System.Text.RegularExpressions;
using System.Collections.Generic;

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
}

public class CodeSnippet {
    public int SnippetID = 0;
    public string AddonName = "";
    public string FileName = "";
    public string RelativePath = "";
    public string FuncName = "";
    public string Signature = "";
    public string Category = "General_Logic";
    public int StartLine = 0;
    public int EndLine = 0;
    public string ApisUsed = "";
    public string EventsUsed = "";
    public string CodeBody = "";
}

public class BlueprintEntry {
    public string EntryType = "";
    public string AddonName = "";
    public string FileName = "";
    public int LineNumber = 0;
    public string KeyName = "";
    public string Details = "";
}

public static class DeconstructionGodEngine {
    public static List<LootRecord> LastLootRecords = new List<LootRecord>();
    public static List<CodeSnippet> LastSnippets = new List<CodeSnippet>();
    public static List<BlueprintEntry> LastBlueprints = new List<BlueprintEntry>();

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

    public static string EscapeLua(string s) {
        if (string.IsNullOrEmpty(s)) return "";
        return s.Replace("\\", "\\\\").Replace("\"", "\\\"").Replace("\r", "").Replace("\n", " ").Replace("|", "/").Trim();
    }

    private static string CleanLuaExpr(string raw) {
        if (string.IsNullOrEmpty(raw)) return "";
        string s = raw.Trim();
        s = Regex.Replace(s, @"C_Map_GetAreaInfo\s*\(\s*(\d+)\s*\)", m => {
            int id = int.Parse(m.Groups[1].Value);
            return MapNames.ContainsKey(id) ? MapNames[id] : "Zone_" + id;
        });
        s = Regex.Replace(s, @"GetFactionInfoByID\s*\(\s*(\d+)\s*\)", m => {
            int id = int.Parse(m.Groups[1].Value);
            return FactionNames.ContainsKey(id) ? FactionNames[id] : "Faction_" + id;
        });
        s = Regex.Replace(s, @"format\s*\(\s*AL\[""([^""]+)""\]\s*,\s*""([^""]+)""\s*\)", m => {
            return m.Groups[1].Value.Replace("%s", m.Groups[2].Value);
        });
        s = Regex.Replace(s, @"format\s*\(\s*AL\[""([^""]+)""\]\s*,\s*AL\[""([^""]+)""\]\s*\)", m => {
            return m.Groups[1].Value.Replace("%s", m.Groups[2].Value);
        });
        s = Regex.Replace(s, @"format\s*\(\s*GEM_FORMAT1\s*,\s*ALIL\[""([^""]+)""\]\s*\)", m => {
            return "Gems - " + m.Groups[1].Value;
        });
        s = Regex.Replace(s, @"ALIL?\[""([^""]+)""\]", "$1");
        s = s.Replace("..", " ").Replace("\"", "").Replace("'", "");
        s = Regex.Replace(s, @"\s+", " ").Trim();
        if (s.EndsWith(",")) s = s.Substring(0, s.Length - 1).Trim();
        return s;
    }

    private static string DetectFileEra(string filePath, string content) {
        string lowerName = Path.GetFileName(filePath).ToLowerInvariant();
        string lowerPath = filePath.ToLowerInvariant();
        if (lowerName.Contains("sod") || content.Contains("GetActiveSeason() == 2")) return "SoD_Forever";
        if (lowerName.Contains("wrath") || lowerName.Contains("wotlk") || lowerPath.Contains("wrath") || lowerPath.Contains("wotlk") || content.Contains("WRATH_VERSION_NUM")) return "Wrath";
        if (lowerName.Contains("tbc") || lowerName.Contains("bc") || lowerPath.Contains("burningcrusade") || lowerPath.Contains("_bc") || content.Contains("BC_VERSION_NUM")) return "TBC";
        return "Classic";
    }

    private static string ResolveAddonName(string filePath, string rootFolder) {
        try {
            string rel = filePath.Substring(rootFolder.Length).TrimStart('\\', '/');
            string[] parts = rel.Split(new char[] { '\\', '/' }, StringSplitOptions.RemoveEmptyEntries);
            if (parts.Length > 1) return parts[0];
            return new DirectoryInfo(rootFolder).Name;
        } catch {
            return "UnknownAddon";
        }
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
        if (u.Contains("PROF")) return "Professions";
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

    private static string ClassifyFunctionCategory(string funcName, string body, string addonName) {
        string text = (funcName + " " + body).ToUpperInvariant();
        if (text.Contains("SECUREUNITBUTTON") || text.Contains("HEALBOT") || text.Contains("INCOMINGHEAL") || text.Contains("UNITHEALTH") || text.Contains("CLEANSE") || text.Contains("DISPEL") || text.Contains("RAIDFRAME"))
            return "UnitFrames_And_Heal";
        if (text.Contains("C_NAMEPLATE") || text.Contains("NAME_PLATE_UNIT") || text.Contains("THREAT") || text.Contains("CASTBAR"))
            return "Nameplates_And_HUD";
        if (text.Contains("C_MAP") || text.Contains("QUESTIE") || text.Contains("HEREBEDRAGONS") || text.Contains("WORLDMAP") || text.Contains("MINIMAP") || text.Contains("QUESTLOG"))
            return "Map_Quests_And_Coords";
        if (text.Contains("AUCTION") || text.Contains("GETAUCTION") || text.Contains("C_AUCTIONHOUSE") || text.Contains("VENDORPRICE") || text.Contains("BUYMERCHANT"))
            return "Auction_And_Economy";
        if (text.Contains("COMBAT_LOG_EVENT") || text.Contains("UNITCAST") || text.Contains("COOLDOWN") || text.Contains("SPELL_DAMAGE"))
            return "CombatLog_And_Timers";
        if (text.Contains("GAMETOOLTIP") || text.Contains("TOOLTIPDATAPROCESSOR") || text.Contains("SETITEMBYID") || text.Contains("SETHYPERLINK") || text.Contains("ITEMREFTOOLTIP"))
            return "Tooltips_And_Links";
        if (text.Contains("SENDADDONMESSAGE") || text.Contains("CHAT_MSG_ADDON") || text.Contains("REGISTERADDONMESSAGEPREFIX") || text.Contains("LIBDEFLATE") || text.Contains("ACESERIALIZER"))
            return "Network_And_Sync";
        if (text.Contains("C_TRAITS") || text.Contains("C_CLASSTALENTS") || text.Contains("C_CONTAINER") || text.Contains("C_SPELL") || text.Contains("BACKDROPTEMPLATE"))
            return "Forever_16001_ModernAPI";
        if (text.Contains("TRADESKILL") || text.Contains("C_TRADESKILLUI") || text.Contains("CRAFT") || text.Contains("REAGENT") || text.Contains("PROFESSION"))
            return "Professions_And_Crafting";
        if (text.Contains("DRESSUPMODEL") || text.Contains("PLAYERMODEL") || text.Contains("SETTEXTURE") || text.Contains("SETTEXCOORD") || text.Contains("CREATEANIMATION"))
            return "Models_Textures_And_Video";
        if (text.Contains("CREATEFRAME") || text.Contains("SETPOINT") || text.Contains("SCROLLFRAME") || text.Contains("SLIDER") || text.Contains("EDITBOX"))
            return "Frames_And_UI_Layout";
        return "General_Logic_And_Utils";
    }

    public static void ExecuteOmniDeconstruction(
        string[] folders,
        string outputDir,
        bool ripGenericData,
        bool harvestCodeSnippets,
        Action<int, int, string, int, int, int> progressCallback,
        Action<string> logCallback
    ) {
        LastLootRecords.Clear();
        LastSnippets.Clear();
        LastBlueprints.Clear();

        HashSet<string> dedupLoot = new HashSet<string>();
        HashSet<string> seenBlueprints = new HashSet<string>();

        List<Tuple<string, string>> allTargetFiles = new List<Tuple<string, string>>();
        foreach (string root in folders) {
            if (string.IsNullOrWhiteSpace(root) || !Directory.Exists(root)) continue;
            string[] files = Directory.GetFiles(root, "*.*", SearchOption.AllDirectories);
            foreach (string f in files) {
                string ext = Path.GetExtension(f).ToLowerInvariant();
                string fName = Path.GetFileName(f);
                if (fName.StartsWith("DB_MasterHoldingTank", StringComparison.OrdinalIgnoreCase) ||
                    fName.StartsWith("Core_MasterLootIndex", StringComparison.OrdinalIgnoreCase) ||
                    fName.StartsWith("AI_MASTER_LIBRARY_HANDOFF", StringComparison.OrdinalIgnoreCase)) {
                    continue;
                }
                if (ext == ".lua" || ext == ".xml" || ext == ".toc") {
                    allTargetFiles.Add(Tuple.Create(root, f));
                }
            }
        }

        int totalFiles = allTargetFiles.Count;
        logCallback("Discovered " + totalFiles + " total (.lua, .xml, .toc) files across all subfolder layers.");

        Regex rxDataBlock = new Regex(@"^\s*data\s*\[\s*""([^""]+)""\s*\]\s*=\s*\{", RegexOptions.Compiled);
        Regex rxTableType = new Regex(@"TableType\s*=\s*([A-Za-z0-9_]+)", RegexOptions.Compiled);
        Regex rxContentType = new Regex(@"ContentType\s*=\s*([A-Za-z0-9_]+)", RegexOptions.Compiled);
        Regex rxPhase = new Regex(@"ContentPhase(?:BC|Wrath)?\s*=\s*([0-9\.]+)", RegexOptions.Compiled);
        Regex rxMapID = new Regex(@"^\s*MapID\s*=\s*(\d+)", RegexOptions.Compiled);
        Regex rxFactionID = new Regex(@"^\s*FactionID\s*=\s*(\d+)", RegexOptions.Compiled);
        Regex rxNameLine = new Regex(@"^\s*name\s*=\s*(.+?)\s*,?\s*$", RegexOptions.Compiled);
        Regex rxDiffHeader = new Regex(@"^\s*\[\s*([A-Za-z0-9_]+_DIFF|[A-Za-z0-9_]+_ITTYPE)\s*\]\s*=\s*\{", RegexOptions.Compiled);
        Regex rxBoxDivider = new Regex(@"^\s*\{\s*\d+\s*,\s*""INV_[^""]*""\s*,\s*nil\s*,\s*(.+?)\s*\}", RegexOptions.Compiled);
        Regex rxDualFaction = new Regex(@"^\s*\{\s*\d+\s*,\s*\[ATLASLOOT_IT_ALLIANCE\]\s*=\s*\{\s*(\d+)\s*\}\s*,\s*\[ATLASLOOT_IT_HORDE\]\s*=\s*\{\s*(\d+)\s*\}\s*\}\s*,?\s*(?:--\s*(.*))?$", RegexOptions.Compiled);
        Regex rxGetVersion = new Regex(@"^\s*\{\s*\d+\s*,\s*GetForVersion\s*\(\s*(\d+)\s*,\s*(\d+)\s*\)\s*\}\s*,?\s*(?:--\s*(.*))?$", RegexOptions.Compiled);
        Regex rxGameVerGE = new Regex(@"AtlasLoot:GameVersion_GE\s*\(\s*([A-Za-z0-9_\.]+)\s*,\s*\{\s*\d+\s*,\s*(\d+)\s*\}\s*\)\s*,?\s*(?:--\s*(.*))?$", RegexOptions.Compiled);
        Regex rxPrefixedItem = new Regex(@"^\s*\{\s*\d+\s*,\s*""i(\d+)""\s*\}\s*,?\s*(?:--\s*(.*))?$", RegexOptions.Compiled);
        Regex rxStandardEntry = new Regex(@"^\s*\{\s*(\d+)\s*,\s*(\d+)(.*?)\}\s*,?\s*(?:--\s*(.*))?$", RegexOptions.Compiled);

        Regex rxGenericItem = new Regex(@"(?:itemID|itemId|ItemID|\[""item""\]|item\s*=)\s*[:=]\s*(\d{3,7})", RegexOptions.Compiled);
        Regex rxQuestieOrDBKey = new Regex(@"^\s*\[(\d{2,7})\]\s*=\s*\{\s*""([^""]{2,60})""", RegexOptions.Compiled);

        Regex rxFuncStart = new Regex(@"^\s*(?:local\s+)?function\s+([A-Za-z0-9_:\.]+)\s*\(([^)]*)\)|^\s*([A-Za-z0-9_:\.\[\]""']+)\s*=\s*function\s*\(([^)]*)\)", RegexOptions.Compiled);
        Regex rxBlockOpen = new Regex(@"\b(?:function|if|for|while|repeat)\b|\bdo\b", RegexOptions.Compiled);
        Regex rxBlockClose = new Regex(@"\b(?:end|until)\b", RegexOptions.Compiled);

        Regex rxRegEvent = new Regex(@"(?:RegisterEvent|SafeRegisterEvent)\s*\(\s*(?:[A-Za-z0-9_]+\s*,\s*)?""([A-Z0-9_]+)""", RegexOptions.Compiled);
        Regex rxCreateFrame = new Regex(@"(?:CreateFrame|CreateBackdropFrame)\s*\(\s*""([^""]+)""(?:\s*,\s*""([^""]*)"")?(?:\s*,\s*[^,]+)?(?:\s*,\s*""([^""]+)"")?", RegexOptions.Compiled);
        Regex rxModernApi = new Regex(@"\b(C_[A-Za-z0-9_]+\.[A-Za-z0-9_]+|TooltipDataProcessor\.[A-Za-z0-9_]+|hooksecurefunc)\b", RegexOptions.Compiled);
        Regex rxSlashCmd = new Regex(@"SLASH_([A-Za-z0-9_]+)\d*\s*=\s*""(/[^""]+)""", RegexOptions.Compiled);

        Regex rxXmlTemplate = new Regex(@"<([A-Za-z0-9_]+)\s+[^>]*name=""([^""]+)""[^>]*virtual=""true""[^>]*(?:inherits=""([^""]+)"")?", RegexOptions.Compiled | RegexOptions.IgnoreCase);
        Regex rxXmlInherits = new Regex(@"<([A-Za-z0-9_]+)\s+[^>]*name=""([^""]+)""[^>]*inherits=""([^""]+)""", RegexOptions.Compiled | RegexOptions.IgnoreCase);

        for (int fIdx = 0; fIdx < totalFiles; fIdx++) {
            string rootFolder = allTargetFiles[fIdx].Item1;
            string filePath = allTargetFiles[fIdx].Item2;
            string fileName = Path.GetFileName(filePath);
            string ext = Path.GetExtension(filePath).ToLowerInvariant();
            string addonName = ResolveAddonName(filePath, rootFolder);
            string relPath = filePath.Length > rootFolder.Length ? filePath.Substring(rootFolder.Length).TrimStart('\\', '/') : fileName;

            if (fIdx % 3 == 0 || fIdx == totalFiles - 1) {
                progressCallback(fIdx + 1, totalFiles, addonName + "\\" + fileName, LastLootRecords.Count, LastSnippets.Count, LastBlueprints.Count);
            }

            string fullText = "";
            try {
                fullText = File.ReadAllText(filePath, Encoding.UTF8);
            } catch {
                continue;
            }

            string[] lines = fullText.Split(new string[] { "\r\n", "\n" }, StringSplitOptions.None);

            if (ext == ".toc") {
                for (int i = 0; i < lines.Length; i++) {
                    string t = lines[i].Trim();
                    if (t.StartsWith("## Interface:") || t.StartsWith("## SavedVariables:") || t.StartsWith("## SavedVariablesPerCharacter:") || t.StartsWith("## Dependencies:") || t.StartsWith("## OptionalDeps:")) {
                        string[] kv = t.Substring(2).Split(new char[] { ':' }, 2);
                        if (kv.Length == 2) {
                            AddBlueprint(seenBlueprints, "TOC_Metadata", addonName, fileName, i + 1, kv[0].Trim(), kv[1].Trim());
                        }
                    }
                }
                continue;
            }

            if (ext == ".xml") {
                for (int i = 0; i < lines.Length; i++) {
                    string line = lines[i];
                    Match mVirt = rxXmlTemplate.Match(line);
                    if (mVirt.Success) {
                        string widgetType = mVirt.Groups[1].Value;
                        string tmplName = mVirt.Groups[2].Value;
                        string inh = mVirt.Groups[3].Success ? mVirt.Groups[3].Value : "none";
                        AddBlueprint(seenBlueprints, "XML_VirtualTemplate", addonName, fileName, i + 1, tmplName, widgetType + " (inherits: " + inh + ")");
                        continue;
                    }
                    Match mInh = rxXmlInherits.Match(line);
                    if (mInh.Success) {
                        AddBlueprint(seenBlueprints, "XML_FrameInherits", addonName, fileName, i + 1, mInh.Groups[2].Value, mInh.Groups[1].Value + " inherits " + mInh.Groups[3].Value);
                    }
                }
                continue;
            }

            string fileEra = DetectFileEra(filePath, fullText);
            string currentModuleKey = "";
            string currentCategoryName = "";
            string currentContentType = "General";
            string currentTableType = "Item";
            string currentSubSection = "";
            string currentBossHeader = "";
            string currentDifficulty = "Normal";
            string currentFaction = "Both";
            string currentPhase = "";
            bool inItemsArray = false;
            string activeSubTableType = "";

            bool inFunc = false;
            string curFuncName = "";
            string curFuncSig = "";
            int curFuncStart = 0;
            int blockDepth = 0;
            StringBuilder sbFuncBody = new StringBuilder();
            HashSet<string> curFuncApis = new HashSet<string>();
            HashSet<string> curFuncEvents = new HashSet<string>();

            for (int i = 0; i < lines.Length; i++) {
                string line = lines[i];
                string trimmed = line.Trim();

                if (!trimmed.StartsWith("--")) {
                    Match mEv = rxRegEvent.Match(line);
                    if (mEv.Success) {
                        string evName = mEv.Groups[1].Value;
                        AddBlueprint(seenBlueprints, "WoW_Event", addonName, fileName, i + 1, evName, "Registered in " + relPath);
                        if (inFunc) curFuncEvents.Add(evName);
                    }

                    Match mCf = rxCreateFrame.Match(line);
                    if (mCf.Success) {
                        string fType = mCf.Groups[1].Value;
                        string fName = mCf.Groups[2].Success ? mCf.Groups[2].Value : "(anonymous)";
                        string fTmpl = mCf.Groups[3].Success ? mCf.Groups[3].Value : "none";
                        if (fTmpl != "none") {
                            AddBlueprint(seenBlueprints, "Lua_FrameTemplate", addonName, fileName, i + 1, fTmpl, fType + " '" + fName + "'");
                        }
                    }

                    MatchCollection mcApi = rxModernApi.Matches(line);
                    foreach (Match ma in mcApi) {
                        string apiCall = ma.Groups[1].Value.Trim();
                        AddBlueprint(seenBlueprints, "Modern_API", addonName, fileName, i + 1, apiCall, "Called in " + fileName);
                        if (inFunc) curFuncApis.Add(apiCall);
                    }

                    Match mSlash = rxSlashCmd.Match(line);
                    if (mSlash.Success) {
                        AddBlueprint(seenBlueprints, "Slash_Command", addonName, fileName, i + 1, mSlash.Groups[2].Value, "SLASH_" + mSlash.Groups[1].Value);
                    }
                }

                if (harvestCodeSnippets && lines.Length < 25000) {
                    string codeNoComment = Regex.Replace(line, @"--.*$", "");
                    string codeNoStrings = Regex.Replace(codeNoComment, @"""[^""]*""|'[^']*'", "");

                    if (!inFunc) {
                        Match mFs = rxFuncStart.Match(codeNoComment);
                        if (mFs.Success) {
                            inFunc = true;
                            curFuncName = !string.IsNullOrEmpty(mFs.Groups[1].Value) ? mFs.Groups[1].Value : mFs.Groups[3].Value;
                            string args = !string.IsNullOrEmpty(mFs.Groups[1].Value) ? mFs.Groups[2].Value : mFs.Groups[4].Value;
                            curFuncSig = curFuncName + "(" + args.Trim() + ")";
                            curFuncStart = i + 1;
                            sbFuncBody.Clear();
                            curFuncApis.Clear();
                            curFuncEvents.Clear();
                            sbFuncBody.AppendLine(line);

                            int opens = rxBlockOpen.Matches(codeNoStrings).Count;
                            if (Regex.IsMatch(codeNoStrings, @"\b(?:while|for)\b.*\bdo\b")) opens--;
                            int closes = rxBlockClose.Matches(codeNoStrings).Count;
                            blockDepth = opens - closes;
                            if (blockDepth <= 0) {
                                FinalizeSnippet(addonName, fileName, relPath, curFuncName, curFuncSig, curFuncStart, i + 1, sbFuncBody.ToString(), curFuncApis, curFuncEvents);
                                inFunc = false;
                            }
                        }
                    } else {
                        sbFuncBody.AppendLine(line);
                        int opens = rxBlockOpen.Matches(codeNoStrings).Count;
                        if (Regex.IsMatch(codeNoStrings, @"\b(?:while|for)\b.*\bdo\b")) opens--;
                        int closes = rxBlockClose.Matches(codeNoStrings).Count;
                        blockDepth += (opens - closes);

                        if (blockDepth <= 0 || (i + 1 - curFuncStart) > 260) {
                            FinalizeSnippet(addonName, fileName, relPath, curFuncName, curFuncSig, curFuncStart, i + 1, sbFuncBody.ToString(), curFuncApis, curFuncEvents);
                            inFunc = false;
                        }
                    }
                }

                if (string.IsNullOrEmpty(trimmed) || trimmed.StartsWith("--")) continue;

                Match mData = rxDataBlock.Match(line);
                if (mData.Success) {
                    currentModuleKey = mData.Groups[1].Value;
                    currentCategoryName = currentModuleKey;
                    currentContentType = MapContentType("", currentModuleKey);
                    currentTableType = "Item";
                    currentSubSection = "";
                    currentBossHeader = "";
                    currentDifficulty = "Normal";
                    currentFaction = "Both";
                    currentPhase = "";
                    inItemsArray = false;
                    activeSubTableType = "";
                    continue;
                }

                if (string.IsNullOrEmpty(currentModuleKey)) {
                    if (ripGenericData) {
                        Match mQ = rxQuestieOrDBKey.Match(line);
                        if (mQ.Success) {
                            int qId = int.Parse(mQ.Groups[1].Value);
                            string qName = mQ.Groups[2].Value;
                            string recType = fileName.ToLowerInvariant().Contains("npc") ? "NPC" : (fileName.ToLowerInvariant().Contains("quest") ? "Quest" : "DB_Entry");
                            AddLootEntry(dedupLoot, recType, qId, 0, qName, fileEra, "External_Addon_DB", addonName, Path.GetFileNameWithoutExtension(fileName), "", "", "Normal", "Both", "", "", addonName, fileName);
                            continue;
                        }
                        Match mGen = rxGenericItem.Match(line);
                        if (mGen.Success) {
                            int genID = int.Parse(mGen.Groups[1].Value);
                            AddLootEntry(dedupLoot, "Item", genID, 0, "", fileEra, "Generic_Addon_Rip", addonName, Path.GetFileNameWithoutExtension(fileName), "", "", "Normal", "Both", "", "", addonName, fileName);
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
                    string mName = MapNames.ContainsKey(mapId) ? MapNames[mapId] : ("Map_" + mapId);
                    if (!inItemsArray) currentCategoryName = mName;
                    else { currentSubSection = mName; currentBossHeader = ""; }
                    continue;
                }

                Match mFac = rxFactionID.Match(line);
                if (mFac.Success) {
                    int facId = int.Parse(mFac.Groups[1].Value);
                    string fName = FactionNames.ContainsKey(facId) ? FactionNames[facId] : ("Faction_" + facId);
                    if (!inItemsArray) currentCategoryName = fName;
                    else currentSubSection = fName;
                    continue;
                }

                Match mName = rxNameLine.Match(line);
                if (mName.Success) {
                    string cleaned = CleanLuaExpr(mName.Groups[1].Value);
                    if (!inItemsArray) currentCategoryName = cleaned;
                    else { currentSubSection = cleaned; currentBossHeader = ""; activeSubTableType = ""; }
                    continue;
                }

                Match mDiff = rxDiffHeader.Match(line);
                if (mDiff.Success) {
                    string dTok = mDiff.Groups[1].Value;
                    currentDifficulty = MapDiffLabel(dTok);
                    if (dTok.Contains("ALLIANCE")) currentFaction = "Alliance";
                    else if (dTok.Contains("HORDE")) currentFaction = "Horde";
                    else currentFaction = "Both";
                    currentBossHeader = "";
                    continue;
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
                    AddLootEntry(dedupLoot, effectiveType, allyID, hordeID, comment, fileEra, currentContentType, currentModuleKey, currentCategoryName, currentSubSection, currentBossHeader, currentDifficulty, "Alliance", "", currentPhase, addonName, fileName);
                    AddLootEntry(dedupLoot, effectiveType, hordeID, allyID, comment, fileEra, currentContentType, currentModuleKey, currentCategoryName, currentSubSection, currentBossHeader, currentDifficulty, "Horde", "", currentPhase, addonName, fileName);
                    continue;
                }

                Match mVer = rxGetVersion.Match(line);
                if (mVer.Success) {
                    int idClassic = int.Parse(mVer.Groups[1].Value);
                    int idTBC = int.Parse(mVer.Groups[2].Value);
                    string comment = mVer.Groups[3].Success ? mVer.Groups[3].Value.Trim() : "";
                    AddLootEntry(dedupLoot, effectiveType, idClassic, idTBC, comment, "Classic", currentContentType, currentModuleKey, currentCategoryName, currentSubSection, currentBossHeader, currentDifficulty, currentFaction, "", currentPhase, addonName, fileName);
                    AddLootEntry(dedupLoot, effectiveType, idTBC, idClassic, comment, "TBC", currentContentType, currentModuleKey, currentCategoryName, currentSubSection, currentBossHeader, currentDifficulty, currentFaction, "", currentPhase, addonName, fileName);
                    continue;
                }

                Match mGE = rxGameVerGE.Match(line);
                if (mGE.Success) {
                    string verTok = mGE.Groups[1].Value;
                    int idVal = int.Parse(mGE.Groups[2].Value);
                    string comment = mGE.Groups[3].Success ? mGE.Groups[3].Value.Trim() : "";
                    string geEra = verTok.Contains("WRATH") ? "Wrath" : (verTok.Contains("BC") ? "TBC" : fileEra);
                    AddLootEntry(dedupLoot, effectiveType, idVal, 0, comment, geEra, currentContentType, currentModuleKey, currentCategoryName, currentSubSection, currentBossHeader, currentDifficulty, currentFaction, "", currentPhase, addonName, fileName);
                    continue;
                }

                Match mPref = rxPrefixedItem.Match(line);
                if (mPref.Success) {
                    int itemVal = int.Parse(mPref.Groups[1].Value);
                    string comment = mPref.Groups[2].Success ? mPref.Groups[2].Value.Trim() : "";
                    AddLootEntry(dedupLoot, "Item", itemVal, 0, comment, fileEra, currentContentType, currentModuleKey, currentCategoryName, currentSubSection, currentBossHeader, currentDifficulty, currentFaction, "", currentPhase, addonName, fileName);
                    continue;
                }

                Match mStd = rxStandardEntry.Match(line);
                if (mStd.Success) {
                    int mainID = int.Parse(mStd.Groups[2].Value);
                    string midTail = mStd.Groups[3].Value;
                    string comment = mStd.Groups[4].Success ? mStd.Groups[4].Value.Trim() : "";
                    string priceInfo = "";
                    int secID = 0;

                    Match mPriceStr = Regex.Match(midTail, @"\[PRICE_EXTRA_ITTYPE\]\s*=\s*""([^""]+)""");
                    if (mPriceStr.Success) {
                        priceInfo = mPriceStr.Groups[1].Value;
                    } else {
                        Match mTicket = Regex.Match(midTail, @",\s*(\d+)\s*,\s*\[ATLASLOOT_IT_AMOUNT2\]\s*=\s*(\d+)");
                        if (mTicket.Success) {
                            secID = int.Parse(mTicket.Groups[1].Value);
                            priceInfo = "Item_" + mTicket.Groups[1].Value + ":" + mTicket.Groups[2].Value;
                        }
                    }

                    AddLootEntry(dedupLoot, effectiveType, mainID, secID, comment, fileEra, currentContentType, currentModuleKey, currentCategoryName, currentSubSection, currentBossHeader, currentDifficulty, currentFaction, priceInfo, currentPhase, addonName, fileName);
                }
            }
        }

        WriteAllOutputFiles(outputDir, logCallback);
    }

    private static void FinalizeSnippet(string addon, string file, string relPath, string fnName, string sig, int startLn, int endLn, string body, HashSet<string> apis, HashSet<string> evts) {
        if ((endLn - startLn) < 2) return;
        CodeSnippet cs = new CodeSnippet();
        cs.SnippetID = LastSnippets.Count + 1;
        cs.AddonName = addon;
        cs.FileName = file;
        cs.RelativePath = relPath;
        cs.FuncName = fnName;
        cs.Signature = sig;
        cs.StartLine = startLn;
        cs.EndLine = endLn;
        cs.Category = ClassifyFunctionCategory(fnName, body, addon);
        cs.ApisUsed = string.Join(", ", apis);
        cs.EventsUsed = string.Join(", ", evts);
        cs.CodeBody = body.TrimEnd();
        LastSnippets.Add(cs);
    }

    private static void AddBlueprint(HashSet<string> dedup, string bType, string addon, string file, int ln, string key, string details) {
        string k = bType + "|" + addon + "|" + key + "|" + file;
        if (dedup.Contains(k)) return;
        dedup.Add(k);
        BlueprintEntry b = new BlueprintEntry();
        b.EntryType = bType;
        b.AddonName = addon;
        b.FileName = file;
        b.LineNumber = ln;
        b.KeyName = key;
        b.Details = details;
        LastBlueprints.Add(b);
    }

    private static void AddLootEntry(HashSet<string> dedup, string idType, int id, int secId, string name, string era, string content, string modKey, string catName, string subSec, string bossHdr, string diff, string fac, string price, string phase, string srcAddon, string srcFile) {
        if (id <= 0) return;
        string key = idType + "|" + id + "|" + era + "|" + modKey + "|" + subSec + "|" + bossHdr + "|" + diff + "|" + fac;
        if (dedup.Contains(key)) return;
        dedup.Add(key);

        LootRecord r = new LootRecord();
        r.IDType = idType;
        r.ID = id;
        r.SecondaryID = secId;
        r.Name = name;
        r.Era = era;
        r.ContentType = content;
        r.ModuleKey = modKey;
        r.CategoryName = string.IsNullOrEmpty(catName) ? modKey : catName;
        r.SubSectionName = subSec;
        r.BossOrHeader = bossHdr;
        r.Difficulty = diff;
        r.Faction = fac;
        r.PriceOrCost = price;
        r.Phase = phase;
        r.SourceAddon = srcAddon;
        r.SourceFile = srcFile;
        LastLootRecords.Add(r);
    }

    private static void WriteAllOutputFiles(string outputDir, Action<string> logCallback) {
        if (!Directory.Exists(outputDir)) Directory.CreateDirectory(outputDir);
        UTF8Encoding utf8NoBom = new UTF8Encoding(false);

        string luaPath = Path.Combine(outputDir, "DB_MasterHoldingTank.lua");
        string csvPath = Path.Combine(outputDir, "MasterHoldingTank_Export.csv");
        string handoffPath = Path.Combine(outputDir, "AI_MASTER_LIBRARY_HANDOFF.txt");

        Dictionary<int, List<int>> byItem = new Dictionary<int, List<int>>();
        Dictionary<int, List<int>> bySpell = new Dictionary<int, List<int>>();
        Dictionary<int, List<int>> bySet = new Dictionary<int, List<int>>();
        Dictionary<int, List<int>> byQuest = new Dictionary<int, List<int>>();

        StringBuilder sbLua = new StringBuilder(LastLootRecords.Count * 120 + 4096);
        sbLua.AppendLine("-- ============================================================================");
        sbLua.AppendLine("-- ALTVAULT MASTER HOLDING TANK DATABASE (AUTO-GENERATED BY DECONSTRUCTION GOD)");
        sbLua.AppendLine("-- STATIC READ-ONLY LUA MODULE: 100% IMMUNE TO WOW SAVEDVARIABLES RESETS");
        sbLua.AppendLine("-- Total Extracted Records: " + LastLootRecords.Count);
        sbLua.AppendLine("-- Generated UTC: " + DateTime.UtcNow.ToString("yyyy-MM-dd HH:mm:ss"));
        sbLua.AppendLine("-- Format: \"IDType|ID|Name|Era|ContentType|ModuleKey|Category|SubSection|BossOrHeader|Difficulty|Faction|PriceOrCost|Phase|SourceAddon:SourceFile\"");
        sbLua.AppendLine("-- ============================================================================");
        sbLua.AppendLine("local addonName, ns = ...");
        sbLua.AppendLine("ns = ns or {}");
        sbLua.AppendLine("ns.MasterDB = ns.MasterDB or {}");
        sbLua.AppendLine("local MasterDB = ns.MasterDB");
        sbLua.AppendLine("");
        sbLua.AppendLine("MasterDB.HoldingTank = {");

        for (int i = 0; i < LastLootRecords.Count; i++) {
            int luaIdx = i + 1;
            LootRecord r = LastLootRecords[i];

            string packed = string.Format("{0}|{1}|{2}|{3}|{4}|{5}|{6}|{7}|{8}|{9}|{10}|{11}|{12}|{13}:{14}",
                EscapeLua(r.IDType), r.ID, EscapeLua(r.Name), EscapeLua(r.Era),
                EscapeLua(r.ContentType), EscapeLua(r.ModuleKey), EscapeLua(r.CategoryName),
                EscapeLua(r.SubSectionName), EscapeLua(r.BossOrHeader), EscapeLua(r.Difficulty),
                EscapeLua(r.Faction), EscapeLua(r.PriceOrCost), EscapeLua(r.Phase),
                EscapeLua(r.SourceAddon), EscapeLua(r.SourceFile)
            );

            sbLua.Append("    [").Append(luaIdx).Append("] = \"").Append(packed).AppendLine("\",");

            if (r.IDType == "Item") {
                if (!byItem.ContainsKey(r.ID)) byItem[r.ID] = new List<int>();
                byItem[r.ID].Add(luaIdx);
            } else if (r.IDType == "Spell") {
                if (!bySpell.ContainsKey(r.ID)) bySpell[r.ID] = new List<int>();
                bySpell[r.ID].Add(luaIdx);
            } else if (r.IDType == "Set") {
                if (!bySet.ContainsKey(r.ID)) bySet[r.ID] = new List<int>();
                bySet[r.ID].Add(luaIdx);
            } else if (r.IDType == "Quest") {
                if (!byQuest.ContainsKey(r.ID)) byQuest[r.ID] = new List<int>();
                byQuest[r.ID].Add(luaIdx);
            }
        }
        sbLua.AppendLine("}");
        sbLua.AppendLine("");

        sbLua.AppendLine("MasterDB.ByItemID = {");
        foreach (var kvp in byItem) {
            sbLua.Append("    [").Append(kvp.Key).Append("] = { ").Append(string.Join(",", kvp.Value)).AppendLine(" },");
        }
        sbLua.AppendLine("}");
        sbLua.AppendLine("");

        sbLua.AppendLine("MasterDB.BySpellID = {");
        foreach (var kvp in bySpell) {
            sbLua.Append("    [").Append(kvp.Key).Append("] = { ").Append(string.Join(",", kvp.Value)).AppendLine(" },");
        }
        sbLua.AppendLine("}");
        sbLua.AppendLine("");

        sbLua.AppendLine("MasterDB.BySetID = {");
        foreach (var kvp in bySet) {
            sbLua.Append("    [").Append(kvp.Key).Append("] = { ").Append(string.Join(",", kvp.Value)).AppendLine(" },");
        }
        sbLua.AppendLine("}");
        sbLua.AppendLine("");

        sbLua.AppendLine("MasterDB.Stats = {");
        sbLua.AppendLine("    TotalRecords = " + LastLootRecords.Count + ",");
        sbLua.AppendLine("    UniqueItems = " + byItem.Count + ",");
        sbLua.AppendLine("    UniqueSpells = " + bySpell.Count + ",");
        sbLua.AppendLine("    UniqueSets = " + bySet.Count + ",");
        sbLua.AppendLine("    UniqueQuests = " + byQuest.Count + ",");
        sbLua.AppendLine("}");
        sbLua.AppendLine("_G.AltVaultMasterDB = MasterDB");

        File.WriteAllText(luaPath, sbLua.ToString(), utf8NoBom);
        logCallback("Saved Holding Tank: " + luaPath + " (" + Math.Round(new FileInfo(luaPath).Length / 1024.0, 1) + " KB)");

        StringBuilder sbCsv = new StringBuilder(LastLootRecords.Count * 100 + 512);
        sbCsv.AppendLine("RecordIndex,IDType,ID,SecondaryID,Name,Era,ContentType,ModuleKey,CategoryName,SubSectionName,BossOrHeader,Difficulty,Faction,PriceOrCost,Phase,SourceAddon,SourceFile");
        for (int i = 0; i < LastLootRecords.Count; i++) {
            LootRecord r = LastLootRecords[i];
            sbCsv.AppendFormat("{0},\"{1}\",{2},{3},\"{4}\",\"{5}\",\"{6}\",\"{7}\",\"{8}\",\"{9}\",\"{10}\",\"{11}\",\"{12}\",\"{13}\",\"{14}\",\"{15}\",\"{16}\"\r\n",
                (i + 1), r.IDType, r.ID, r.SecondaryID, r.Name.Replace("\"", "'"),
                r.Era, r.ContentType, r.ModuleKey, r.CategoryName.Replace("\"", "'"),
                r.SubSectionName.Replace("\"", "'"), r.BossOrHeader.Replace("\"", "'"),
                r.Difficulty, r.Faction, r.PriceOrCost.Replace("\"", "'"),
                r.Phase, r.SourceAddon, r.SourceFile);
        }
        File.WriteAllText(csvPath, sbCsv.ToString(), utf8NoBom);
        logCallback("Saved Master CSV: " + csvPath);

        StringBuilder sbHandoff = new StringBuilder(65536);
        sbHandoff.AppendLine("================================================================================");
        sbHandoff.AppendLine("AI MASTER LIBRARY & ADDON DECONSTRUCTION HANDOFF INDEX");
        sbHandoff.AppendLine("Generated UTC: " + DateTime.UtcNow.ToString("yyyy-MM-dd HH:mm:ss"));
        sbHandoff.AppendLine("================================================================================");
        sbHandoff.AppendLine("INSTRUCTIONS FOR THE AI:");
        sbHandoff.AppendLine("1. This document indexes the user's local Master Holding Tank (DB_MasterHoldingTank.lua)");
        sbHandoff.AppendLine("   and the deconstructed Code Snippet Vault across all installed reference addons.");
        sbHandoff.AppendLine("2. NEVER ask the user to upload DB_MasterHoldingTank.lua (it is a massive static tank).");
        sbHandoff.AppendLine("   Instead, query it in Lua via ns.MasterDB (Core_MasterLootIndex.lua).");
        sbHandoff.AppendLine("3. When you need to see how a reference addon (HealBot, Questie, AtlasLoot, etc.)");
        sbHandoff.AppendLine("   implements a specific function or template listed below, ask the user to copy");
        sbHandoff.AppendLine("   that exact Function Name from Tab 2 of AltVault_MasterScanner.bat!");
        sbHandoff.AppendLine("");
        sbHandoff.AppendLine("--------------------------------------------------------------------------------");
        sbHandoff.AppendLine("1. MASTER HOLDING TANK SUMMARY (DB_MasterHoldingTank.lua)");
        sbHandoff.AppendLine("--------------------------------------------------------------------------------");
        sbHandoff.AppendLine("* Total Indexed Records : " + LastLootRecords.Count);
        sbHandoff.AppendLine("* Unique Item IDs       : " + byItem.Count);
        sbHandoff.AppendLine("* Unique Recipe Spells  : " + bySpell.Count);
        sbHandoff.AppendLine("* Unique Armor Set IDs  : " + bySet.Count);
        sbHandoff.AppendLine("* Unique Quest/DB IDs   : " + byQuest.Count);
        sbHandoff.AppendLine("* Packed Record Schema  : \"IDType|ID|Name|Era|ContentType|ModuleKey|Category|SubSection|BossOrHeader|Difficulty|Faction|PriceOrCost|Phase|SourceAddon:SourceFile\"");
        sbHandoff.AppendLine("");

        sbHandoff.AppendLine("--------------------------------------------------------------------------------");
        sbHandoff.AppendLine("2. DECONSTRUCTED ADDON & TOC MANIFEST BLUEPRINTS");
        sbHandoff.AppendLine("--------------------------------------------------------------------------------");
        foreach (BlueprintEntry bp in LastBlueprints) {
            if (bp.EntryType == "TOC_Metadata" || bp.EntryType == "XML_VirtualTemplate" || bp.EntryType == "Slash_Command") {
                sbHandoff.AppendFormat("[{0}] {1} ({2}:{3}) -> {4} : {5}\r\n", bp.EntryType, bp.AddonName, bp.FileName, bp.LineNumber, bp.KeyName, bp.Details);
            }
        }
        sbHandoff.AppendLine("");

        sbHandoff.AppendLine("--------------------------------------------------------------------------------");
        sbHandoff.AppendLine("3. CATALOGED WOW EVENTS & MODERN 16001 API CALLS ACROSS ALL ADDONS");
        sbHandoff.AppendLine("--------------------------------------------------------------------------------");
        int apiPrintCount = 0;
        foreach (BlueprintEntry bp in LastBlueprints) {
            if (bp.EntryType == "WoW_Event" || bp.EntryType == "Modern_API" || bp.EntryType == "Lua_FrameTemplate") {
                if (apiPrintCount < 450) {
                    sbHandoff.AppendFormat("[{0}] {1} -> {2} ({3}:{4})\r\n", bp.EntryType, bp.AddonName, bp.KeyName, bp.FileName, bp.LineNumber);
                }
                apiPrintCount++;
            }
        }
        if (apiPrintCount > 450) sbHandoff.AppendLine("... plus " + (apiPrintCount - 450) + " additional API/Event bindings searchable in Tab 3.");
        sbHandoff.AppendLine("");

        sbHandoff.AppendLine("--------------------------------------------------------------------------------");
        sbHandoff.AppendLine("4. HARVESTED LUA FUNCTION DIRECTORY BY SUBSYSTEM (Total: " + LastSnippets.Count + " Functions)");
        sbHandoff.AppendLine("--------------------------------------------------------------------------------");
        Dictionary<string, List<CodeSnippet>> byCat = new Dictionary<string, List<CodeSnippet>>();
        foreach (CodeSnippet s in LastSnippets) {
            if (!byCat.ContainsKey(s.Category)) byCat[s.Category] = new List<CodeSnippet>();
            byCat[s.Category].Add(s);
        }
        foreach (var kvp in byCat) {
            sbHandoff.AppendLine("=== CATEGORY: " + kvp.Key + " (" + kvp.Value.Count + " functions) ===");
            int limit = Math.Min(kvp.Value.Count, 120);
            for (int i = 0; i < limit; i++) {
                CodeSnippet cs = kvp.Value[i];
                string extra = !string.IsNullOrEmpty(cs.EventsUsed) ? (" [Events: " + cs.EventsUsed + "]") : "";
                if (!string.IsNullOrEmpty(cs.ApisUsed)) extra += " [APIs: " + cs.ApisUsed + "]";
                sbHandoff.AppendFormat("  * [{0}] {1} ({2}:{3}-{4}){5}\r\n", cs.AddonName, cs.Signature, cs.RelativePath, cs.StartLine, cs.EndLine, extra);
            }
            if (kvp.Value.Count > limit) {
                sbHandoff.AppendLine("  ... (" + (kvp.Value.Count - limit) + " more functions in this category available in Tab 2 Snippet Search)");
            }
            sbHandoff.AppendLine("");
        }

        File.WriteAllText(handoffPath, sbHandoff.ToString(), utf8NoBom);
        logCallback("Saved AI Master Handoff Index: " + handoffPath);
    }
}
'@;

Add-Type -TypeDefinition $csharpSource -Language CSharp;

$form = New-Object System.Windows.Forms.Form;
$form.Text = "AltVault Deconstruction God and Master Holding Tank Studio (v3.2)";
$form.Size = New-Object System.Drawing.Size(1020, 740);
$form.StartPosition = "CenterScreen";
$form.BackColor = [System.Drawing.Color]::FromArgb(20, 22, 28);
$form.ForeColor = [System.Drawing.Color]::White;
$form.FormBorderStyle = "FixedDialog";
$form.MaximizeBox = $false;

$fontTitle = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold);
$fontBold  = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold);
$fontReg   = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Regular);
$fontMono  = New-Object System.Drawing.Font("Consolas", 9.5, [System.Drawing.FontStyle]::Regular);

$tabs = New-Object System.Windows.Forms.TabControl;
$tabs.Location = New-Object System.Drawing.Point(10, 10);
$tabs.Size = New-Object System.Drawing.Size(985, 680);
$tabs.Font = $fontBold;
$form.Controls.Add($tabs);

$tabScan = New-Object System.Windows.Forms.TabPage;
$tabScan.Text = " [1] SCANNER AND LIVE PROGRESS MONITOR ";
$tabScan.BackColor = [System.Drawing.Color]::FromArgb(24, 26, 32);
$tabScan.ForeColor = [System.Drawing.Color]::White;
$tabs.Controls.Add($tabScan);

$tabVault = New-Object System.Windows.Forms.TabPage;
$tabVault.Text = " [2] CODE VAULT AND SNIPPET SEARCH (FOR AI) ";
$tabVault.BackColor = [System.Drawing.Color]::FromArgb(24, 26, 32);
$tabVault.ForeColor = [System.Drawing.Color]::White;
$tabs.Controls.Add($tabVault);

$tabBlueprints = New-Object System.Windows.Forms.TabPage;
$tabBlueprints.Text = " [3] EVENTS, APIS, XML AND TOC BLUEPRINTS ";
$tabBlueprints.BackColor = [System.Drawing.Color]::FromArgb(24, 26, 32);
$tabBlueprints.ForeColor = [System.Drawing.Color]::White;
$tabs.Controls.Add($tabBlueprints);

# ==============================================================================
# TAB 1: SCANNER & LIVE MONITOR
# ==============================================================================
$lblFolders = New-Object System.Windows.Forms.Label;
$lblFolders.Text = "1. SOURCE ADDON FOLDERS TO DECONSTRUCT (AtlasLoot, HealBot, Questie, GatherMate, Details, or entire AddOns dir):";
$lblFolders.Location = New-Object System.Drawing.Point(14, 12);
$lblFolders.Size = New-Object System.Drawing.Size(940, 20);
$lblFolders.Font = $fontBold;
$lblFolders.ForeColor = [System.Drawing.Color]::FromArgb(90, 200, 250);
$tabScan.Controls.Add($lblFolders);

$lstFolders = New-Object System.Windows.Forms.ListBox;
$lstFolders.Location = New-Object System.Drawing.Point(14, 36);
$lstFolders.Size = New-Object System.Drawing.Size(760, 125);
$lstFolders.Font = $fontMono;
$lstFolders.BackColor = [System.Drawing.Color]::FromArgb(14, 16, 20);
$lstFolders.ForeColor = [System.Drawing.Color]::FromArgb(220, 235, 245);
$tabScan.Controls.Add($lstFolders);

$scriptDir = Split-Path -Parent $env:SELF;
if (-not $scriptDir) { $scriptDir = (Get-Location).Path; }
$parentAddonsDir = Split-Path $scriptDir -Parent;
if ($parentAddonsDir -and (Test-Path $parentAddonsDir)) {
    Get-ChildItem -Path $parentAddonsDir -Directory | Where-Object {
        $_.Name -match "AtlasLoot|HealBot|Questie|GatherMate|RareScanner|Details|Auctionator|Plater|WeakAuras|Bagnon"
    } | ForEach-Object {
        [void]$lstFolders.Items.Add($_.FullName);
    };
}

$btnAddFolder = New-Object System.Windows.Forms.Button;
$btnAddFolder.Text = "+ Add Folder...";
$btnAddFolder.Location = New-Object System.Drawing.Point(790, 36);
$btnAddFolder.Size = New-Object System.Drawing.Size(170, 34);
$btnAddFolder.BackColor = [System.Drawing.Color]::FromArgb(40, 115, 65);
$btnAddFolder.ForeColor = [System.Drawing.Color]::White;
$btnAddFolder.FlatStyle = "Flat";
$tabScan.Controls.Add($btnAddFolder);

$btnAddAllAddons = New-Object System.Windows.Forms.Button;
$btnAddAllAddons.Text = "+ Add Parent AddOns";
$btnAddAllAddons.Location = New-Object System.Drawing.Point(790, 74);
$btnAddAllAddons.Size = New-Object System.Drawing.Size(170, 30);
$btnAddAllAddons.Font = $fontReg;
$btnAddAllAddons.BackColor = [System.Drawing.Color]::FromArgb(45, 85, 130);
$btnAddAllAddons.ForeColor = [System.Drawing.Color]::White;
$btnAddAllAddons.FlatStyle = "Flat";
$tabScan.Controls.Add($btnAddAllAddons);

$btnRemoveFolder = New-Object System.Windows.Forms.Button;
$btnRemoveFolder.Text = "- Remove Selected";
$btnRemoveFolder.Location = New-Object System.Drawing.Point(790, 108);
$btnRemoveFolder.Size = New-Object System.Drawing.Size(82, 26);
$btnRemoveFolder.Font = $fontReg;
$btnRemoveFolder.BackColor = [System.Drawing.Color]::FromArgb(120, 45, 45);
$btnRemoveFolder.ForeColor = [System.Drawing.Color]::White;
$btnRemoveFolder.FlatStyle = "Flat";
$tabScan.Controls.Add($btnRemoveFolder);

$btnClearFolders = New-Object System.Windows.Forms.Button;
$btnClearFolders.Text = "Clear";
$btnClearFolders.Location = New-Object System.Drawing.Point(878, 108);
$btnClearFolders.Size = New-Object System.Drawing.Size(82, 26);
$btnClearFolders.Font = $fontReg;
$btnClearFolders.BackColor = [System.Drawing.Color]::FromArgb(65, 70, 80);
$btnClearFolders.ForeColor = [System.Drawing.Color]::White;
$btnClearFolders.FlatStyle = "Flat";
$tabScan.Controls.Add($btnClearFolders);

$lblOut = New-Object System.Windows.Forms.Label;
$lblOut.Text = "2. OUTPUT DESTINATION FOLDER (Where DB_MasterHoldingTank.lua and AI_MASTER_LIBRARY_HANDOFF.txt are saved):";
$lblOut.Location = New-Object System.Drawing.Point(14, 170);
$lblOut.Size = New-Object System.Drawing.Size(940, 20);
$lblOut.Font = $fontBold;
$lblOut.ForeColor = [System.Drawing.Color]::FromArgb(90, 200, 250);
$tabScan.Controls.Add($lblOut);

$txtOutput = New-Object System.Windows.Forms.TextBox;
$txtOutput.Location = New-Object System.Drawing.Point(14, 194);
$txtOutput.Size = New-Object System.Drawing.Size(760, 26);
$txtOutput.Font = $fontMono;
$txtOutput.BackColor = [System.Drawing.Color]::FromArgb(14, 16, 20);
$txtOutput.ForeColor = [System.Drawing.Color]::FromArgb(120, 255, 160);
$txtOutput.Text = $scriptDir;
$tabScan.Controls.Add($txtOutput);

$btnBrowseOut = New-Object System.Windows.Forms.Button;
$btnBrowseOut.Text = "Browse Output...";
$btnBrowseOut.Location = New-Object System.Drawing.Point(790, 192);
$btnBrowseOut.Size = New-Object System.Drawing.Size(170, 28);
$btnBrowseOut.Font = $fontReg;
$btnBrowseOut.BackColor = [System.Drawing.Color]::FromArgb(55, 85, 130);
$btnBrowseOut.ForeColor = [System.Drawing.Color]::White;
$btnBrowseOut.FlatStyle = "Flat";
$tabScan.Controls.Add($btnBrowseOut);

$chkGeneric = New-Object System.Windows.Forms.CheckBox;
$chkGeneric.Text = "Enable Universal Questie / GatherMate / Addon DB Table Ripper";
$chkGeneric.Location = New-Object System.Drawing.Point(14, 226);
$chkGeneric.Size = New-Object System.Drawing.Size(450, 24);
$chkGeneric.Font = $fontReg;
$chkGeneric.Checked = $true;
$tabScan.Controls.Add($chkGeneric);

$chkSnippets = New-Object System.Windows.Forms.CheckBox;
$chkSnippets.Text = "Enable Full AST Lua Function, Event, API and XML Blueprint Harvester";
$chkSnippets.Location = New-Object System.Drawing.Point(480, 226);
$chkSnippets.Size = New-Object System.Drawing.Size(480, 24);
$chkSnippets.Font = $fontReg;
$chkSnippets.Checked = $true;
$tabScan.Controls.Add($chkSnippets);

$btnBuild = New-Object System.Windows.Forms.Button;
$btnBuild.Text = "UNLEASH DECONSTRUCTION GOD (SCAN ALL FOLDERS AND BUILD MASTER LIBRARY)";
$btnBuild.Location = New-Object System.Drawing.Point(14, 256);
$btnBuild.Size = New-Object System.Drawing.Size(946, 44);
$btnBuild.Font = $fontTitle;
$btnBuild.BackColor = [System.Drawing.Color]::FromArgb(225, 150, 20);
$btnBuild.ForeColor = [System.Drawing.Color]::Black;
$btnBuild.FlatStyle = "Flat";
$tabScan.Controls.Add($btnBuild);

$lblProgStatus = New-Object System.Windows.Forms.Label;
$lblProgStatus.Text = "Status: Idle - Ready to scan.";
$lblProgStatus.Location = New-Object System.Drawing.Point(14, 308);
$lblProgStatus.Size = New-Object System.Drawing.Size(946, 20);
$lblProgStatus.Font = $fontMono;
$lblProgStatus.ForeColor = [System.Drawing.Color]::FromArgb(255, 220, 110);
$tabScan.Controls.Add($lblProgStatus);

$progBar = New-Object System.Windows.Forms.ProgressBar;
$progBar.Location = New-Object System.Drawing.Point(14, 330);
$progBar.Size = New-Object System.Drawing.Size(946, 22);
$progBar.Style = "Continuous";
$tabScan.Controls.Add($progBar);

$lblStatsBanner = New-Object System.Windows.Forms.Label;
$lblStatsBanner.Text = "Files: 0 / 0   |   Loot/DB Records: 0   |   Lua Functions Harvested: 0   |   Events/APIs/Templates: 0";
$lblStatsBanner.Location = New-Object System.Drawing.Point(14, 356);
$lblStatsBanner.Size = New-Object System.Drawing.Size(946, 22);
$lblStatsBanner.Font = $fontBold;
$lblStatsBanner.ForeColor = [System.Drawing.Color]::FromArgb(110, 255, 160);
$tabScan.Controls.Add($lblStatsBanner);

$txtLog = New-Object System.Windows.Forms.TextBox;
$txtLog.Location = New-Object System.Drawing.Point(14, 382);
$txtLog.Size = New-Object System.Drawing.Size(946, 255);
$txtLog.Multiline = $true;
$txtLog.ScrollBars = "Vertical";
$txtLog.ReadOnly = $true;
$txtLog.Font = $fontMono;
$txtLog.BackColor = [System.Drawing.Color]::FromArgb(10, 12, 16);
$txtLog.ForeColor = [System.Drawing.Color]::FromArgb(200, 245, 200);
$tabScan.Controls.Add($txtLog);

# ==============================================================================
# TAB 2: CODE VAULT & SNIPPET SEARCH
# ==============================================================================
$lblFilterAddon = New-Object System.Windows.Forms.Label;
$lblFilterAddon.Text = "Addon Filter:";
$lblFilterAddon.Location = New-Object System.Drawing.Point(14, 16);$lblFilterAddon.Size = New-Object System.Drawing.Size(90, 20);
$tabVault.Controls.Add($lblFilterAddon);

$cmbAddonFilter = New-Object System.Windows.Forms.ComboBox;
$cmbAddonFilter.Location = New-Object System.Drawing.Point(105, 13);
$cmbAddonFilter.Size = New-Object System.Drawing.Size(170, 26);$cmbAddonFilter.DropDownStyle = "DropDownList";
$cmbAddonFilter.BackColor = [System.Drawing.Color]::FromArgb(14, 16, 20);$cmbAddonFilter.ForeColor = [System.Drawing.Color]::White;
[void]$cmbAddonFilter.Items.Add("ALL ADDONS");
$cmbAddonFilter.SelectedIndex = 0;
$tabVault.Controls.Add($cmbAddonFilter);

$lblFilterCat = New-Object System.Windows.Forms.Label;
$lblFilterCat.Text = "Category:";
$lblFilterCat.Location = New-Object System.Drawing.Point(285, 16);$lblFilterCat.Size = New-Object System.Drawing.Size(70, 20);
$tabVault.Controls.Add($lblFilterCat);

$cmbCatFilter = New-Object System.Windows.Forms.ComboBox;
$cmbCatFilter.Location = New-Object System.Drawing.Point(358, 13);
$cmbCatFilter.Size = New-Object System.Drawing.Size(210, 26);$cmbCatFilter.DropDownStyle = "DropDownList";
$cmbCatFilter.BackColor = [System.Drawing.Color]::FromArgb(14, 16, 20);$cmbCatFilter.ForeColor = [System.Drawing.Color]::White;
@(
    "ALL CATEGORIES",
    "Forever_16001_ModernAPI",
    "UnitFrames_And_Heal",
    "Nameplates_And_HUD",
    "Map_Quests_And_Coords",
    "Auction_And_Economy",
    "CombatLog_And_Timers",
    "Tooltips_And_Links",
    "Network_And_Sync",
    "Professions_And_Crafting",
    "Models_Textures_And_Video",
    "Frames_And_UI_Layout",
    "General_Logic_And_Utils"
) | ForEach-Object { [void]$cmbCatFilter.Items.Add($_); };$cmbCatFilter.SelectedIndex = 0;
$tabVault.Controls.Add($cmbCatFilter);

$lblSearchKw = New-Object System.Windows.Forms.Label;
$lblSearchKw.Text = "Keyword / API:";
$lblSearchKw.Location = New-Object System.Drawing.Point(578, 16);$lblSearchKw.Size = New-Object System.Drawing.Size(100, 20);
$tabVault.Controls.Add($lblSearchKw);

$txtSnippetSearch = New-Object System.Windows.Forms.TextBox;
$txtSnippetSearch.Location = New-Object System.Drawing.Point(680, 13);$txtSnippetSearch.Size = New-Object System.Drawing.Size(185, 26);
$txtSnippetSearch.Font =$fontMono;
$txtSnippetSearch.BackColor = [System.Drawing.Color]::FromArgb(14, 16, 20);$txtSnippetSearch.ForeColor = [System.Drawing.Color]::FromArgb(255, 235, 130);
$tabVault.Controls.Add($txtSnippetSearch);

$btnSearchVault = New-Object System.Windows.Forms.Button;
$btnSearchVault.Text = "Filter";
$btnSearchVault.Location = New-Object System.Drawing.Point(872, 12);$btnSearchVault.Size = New-Object System.Drawing.Size(88, 27);
$btnSearchVault.BackColor = [System.Drawing.Color]::FromArgb(50, 120, 190);$btnSearchVault.ForeColor = [System.Drawing.Color]::White;
$btnSearchVault.FlatStyle = "Flat";
$tabVault.Controls.Add($btnSearchVault);

$lstSnippets = New-Object System.Windows.Forms.ListBox;
$lstSnippets.Location = New-Object System.Drawing.Point(14, 48);$lstSnippets.Size = New-Object System.Drawing.Size(420, 545);
$lstSnippets.Font =$fontMono;
$lstSnippets.BackColor = [System.Drawing.Color]::FromArgb(12, 14, 18);$lstSnippets.ForeColor = [System.Drawing.Color]::FromArgb(210, 230, 255);
$lstSnippets.HorizontalScrollbar =$true;
$tabVault.Controls.Add($lstSnippets);

$txtCodePreview = New-Object System.Windows.Forms.TextBox;
$txtCodePreview.Location = New-Object System.Drawing.Point(444, 48);$txtCodePreview.Size = New-Object System.Drawing.Size(516, 545);
$txtCodePreview.Multiline =$true;
$txtCodePreview.ScrollBars = "Both";
$txtCodePreview.WordWrap =$false;
$txtCodePreview.ReadOnly =$true;
$txtCodePreview.Font =$fontMono;
$txtCodePreview.BackColor = [System.Drawing.Color]::FromArgb(10, 12, 16);$txtCodePreview.ForeColor = [System.Drawing.Color]::FromArgb(160, 250, 180);
$tabVault.Controls.Add($txtCodePreview);

$lblVaultCount = New-Object System.Windows.Forms.Label;
$lblVaultCount.Text = "Matching Functions: 0";
$lblVaultCount.Location = New-Object System.Drawing.Point(14, 604);
$lblVaultCount.Size = New-Object System.Drawing.Size(420, 24);$lblVaultCount.ForeColor = [System.Drawing.Color]::FromArgb(120, 210, 250);
$tabVault.Controls.Add($lblVaultCount);

$btnCopyForAI = New-Object System.Windows.Forms.Button;
$btnCopyForAI.Text = "COPY SELECTED SNIPPET FOR AI CHAT (WITH CITATION HEADER)";
$btnCopyForAI.Location = New-Object System.Drawing.Point(444, 598);$btnCopyForAI.Size = New-Object System.Drawing.Size(516, 36);
$btnCopyForAI.BackColor = [System.Drawing.Color]::FromArgb(40, 140, 75);$btnCopyForAI.ForeColor = [System.Drawing.Color]::White;
$btnCopyForAI.FlatStyle = "Flat";
$tabVault.Controls.Add($btnCopyForAI);

# ==============================================================================
# TAB 3: EVENTS, APIS, XML & TOC BLUEPRINTS
# ==============================================================================
$lblBpType = New-Object System.Windows.Forms.Label;
$lblBpType.Text = "Blueprint Type:";
$lblBpType.Location = New-Object System.Drawing.Point(14, 16);$lblBpType.Size = New-Object System.Drawing.Size(105, 20);
$tabBlueprints.Controls.Add($lblBpType);

$cmbBpType = New-Object System.Windows.Forms.ComboBox;
$cmbBpType.Location = New-Object System.Drawing.Point(122, 13);
$cmbBpType.Size = New-Object System.Drawing.Size(220, 26);$cmbBpType.DropDownStyle = "DropDownList";
$cmbBpType.BackColor = [System.Drawing.Color]::FromArgb(14, 16, 20);$cmbBpType.ForeColor = [System.Drawing.Color]::White;
@(
    "ALL BLUEPRINTS",
    "WoW_Event",
    "Modern_API",
    "XML_VirtualTemplate",
    "XML_FrameInherits",
    "Lua_FrameTemplate",
    "Slash_Command",
    "TOC_Metadata"
) | ForEach-Object { [void]$cmbBpType.Items.Add($_); };$cmbBpType.SelectedIndex = 0;
$tabBlueprints.Controls.Add($cmbBpType);

$txtBpSearch = New-Object System.Windows.Forms.TextBox;
$txtBpSearch.Location = New-Object System.Drawing.Point(356, 13);$txtBpSearch.Size = New-Object System.Drawing.Size(480, 26);
$txtBpSearch.Font =$fontMono;
$txtBpSearch.BackColor = [System.Drawing.Color]::FromArgb(14, 16, 20);$txtBpSearch.ForeColor = [System.Drawing.Color]::FromArgb(255, 235, 130);
$tabBlueprints.Controls.Add($txtBpSearch);

$btnBpFilter = New-Object System.Windows.Forms.Button;
$btnBpFilter.Text = "Filter List";
$btnBpFilter.Location = New-Object System.Drawing.Point(848, 12);$btnBpFilter.Size = New-Object System.Drawing.Size(112, 27);
$btnBpFilter.BackColor = [System.Drawing.Color]::FromArgb(50, 120, 190);$btnBpFilter.ForeColor = [System.Drawing.Color]::White;
$btnBpFilter.FlatStyle = "Flat";
$tabBlueprints.Controls.Add($btnBpFilter);

$txtBlueprintsView = New-Object System.Windows.Forms.TextBox;
$txtBlueprintsView.Location = New-Object System.Drawing.Point(14, 48);$txtBlueprintsView.Size = New-Object System.Drawing.Size(946, 585);
$txtBlueprintsView.Multiline =$true;
$txtBlueprintsView.ScrollBars = "Both";
$txtBlueprintsView.WordWrap =$false;
$txtBlueprintsView.ReadOnly =$true;
$txtBlueprintsView.Font =$fontMono;
$txtBlueprintsView.BackColor = [System.Drawing.Color]::FromArgb(10, 12, 16);$txtBlueprintsView.ForeColor = [System.Drawing.Color]::FromArgb(220, 240, 255);
$tabBlueprints.Controls.Add($txtBlueprintsView);

# ==============================================================================
# UI LOGIC & EVENT HANDLERS
# ==============================================================================
$script:filteredSnippets = New-Object System.Collections.ArrayList;

$WriteLog = {
    param([string]$msg);$stamp = (Get-Date).ToString("HH:mm:ss");
    $txtLog.AppendText("[$stamp]$msg`r`n");
    $txtLog.SelectionStart =$txtLog.Text.Length;
    $txtLog.ScrollToCaret();
    [System.Windows.Forms.Application]::DoEvents();
};

$RefreshVaultList = {$lstSnippets.BeginUpdate();
    $lstSnippets.Items.Clear();$script:filteredSnippets.Clear();

    $selAddon = [string]$cmbAddonFilter.SelectedItem;
    $selCat   = [string]$cmbCatFilter.SelectedItem;
    $kw       =$txtSnippetSearch.Text.Trim().ToLowerInvariant();

    $allSnips = [DeconstructionGodEngine]::LastSnippets;
    $matchCount = 0;

    for ($i = 0; $i -lt$allSnips.Count; $i++) {$s = $allSnips[$i];
        if ($selAddon -ne "ALL ADDONS" -and $s.AddonName -ne$selAddon) { continue; }
        if ($selCat -ne "ALL CATEGORIES" -and $s.Category -ne$selCat) { continue; }
        if ($kw.Length -gt 0) {
            $hay = ($s.FuncName + " " + $s.FileName + " " + $s.ApisUsed + " " + $s.EventsUsed + " " + $s.CodeBody).ToLowerInvariant();
            if (-not $hay.Contains($kw)) { continue; }
        }

        [void]$script:filteredSnippets.Add($s);
        [void]$lstSnippets.Items.Add(("[" + $s.AddonName + "] " + $s.FuncName + " (" + $s.FileName + ":" + $s.StartLine + ")"));
        $matchCount++;
        if ($matchCount -ge 1500) { break; }
    }
    $lstSnippets.EndUpdate();$lblVaultCount.Text = ("Matching Functions Shown: " + $matchCount + " (of " + $allSnips.Count + " total harvested)");
};

$RefreshBlueprintsView = {
    $selType = [string]$cmbBpType.SelectedItem;
    $kw      = $txtBpSearch.Text.Trim().ToLowerInvariant();$allBps  = [DeconstructionGodEngine]::LastBlueprints;

    $sb = New-Object System.Text.StringBuilder;
    $count = 0;
    for ($i = 0; $i -lt$allBps.Count; $i++) {$b = $allBps[$i];
        if ($selType -ne "ALL BLUEPRINTS" -and $b.EntryType -ne$selType) { continue; }
        if ($kw.Length -gt 0) {$hay = ($b.AddonName + " " + $b.KeyName + " " + $b.Details + " " + $b.FileName).ToLowerInvariant();
            if (-not $hay.Contains($kw)) { continue; }
        }
        [void]$sb.AppendFormat("[{0}] {1} | {2} ({3}:{4}) -> {5}`r`n", $b.EntryType, $b.AddonName, $b.KeyName, $b.FileName, $b.LineNumber, $b.Details);$count++;
        if ($count -ge 2000) { [void]$sb.AppendLine("... (Display capped at 2,000 rows - use the search box above to narrow results)");
            break;
        }
    }
    $txtBlueprintsView.Text =$sb.ToString();
};

$btnAddFolder.Add_Click({$dlg = New-Object System.Windows.Forms.FolderBrowserDialog;
    $dlg.Description = "Select an Addon folder (AtlasLoot, HealBot, Questie, etc.) to scan";
    $dlg.SelectedPath =$scriptDir;
    if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $sel =$dlg.SelectedPath;
        if (-not $lstFolders.Items.Contains($sel)) {
            [void]$lstFolders.Items.Add($sel);
            &$WriteLog ("Added folder: " + $sel);
        }
    }
});

$btnAddAllAddons.Add_Click({
    if ($parentAddonsDir -and (Test-Path$parentAddonsDir)) {
        Get-ChildItem -Path $parentAddonsDir -Directory \vert{} Where-Object {$_.Name -ne "AltVault" } | ForEach-Object {
            if (-not $lstFolders.Items.Contains($_.FullName)) {
                [void]$lstFolders.Items.Add($_.FullName);
            }
        };
        &$WriteLog ("Added all sibling addon folders from: " + $parentAddonsDir);
    }
});

$btnRemoveFolder.Add_Click({
    if ($lstFolders.SelectedIndex -ge 0) {
        $rem =$lstFolders.SelectedItem;
        $lstFolders.Items.RemoveAt($lstFolders.SelectedIndex);
        &$WriteLog ("Removed folder: " + $rem);
    }
});

$btnClearFolders.Add_Click({$lstFolders.Items.Clear();
    &$WriteLog "Cleared source folder list.";
});

$btnBrowseOut.Add_Click({$dlg = New-Object System.Windows.Forms.FolderBrowserDialog;
    $dlg.Description = "Select output folder for DB_MasterHoldingTank.lua and AI_MASTER_LIBRARY_HANDOFF.txt";
    $dlg.SelectedPath =$txtOutput.Text;
    if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $txtOutput.Text =$dlg.SelectedPath;
        &$WriteLog ("Output folder set to: " + $txtOutput.Text);
    }
});

$btnSearchVault.Add_Click({ &$RefreshVaultList; });
$cmbAddonFilter.Add_SelectedIndexChanged({ &$RefreshVaultList; });
$cmbCatFilter.Add_SelectedIndexChanged({ &$RefreshVaultList; });

$lstSnippets.Add_SelectedIndexChanged({
    $idx =$lstSnippets.SelectedIndex;
    if ($idx -ge 0 -and $idx -lt$script:filteredSnippets.Count) {
        $s =$script:filteredSnippets[$idx];$hdr = "-- ============================================================================`r`n";
        $hdr += ("-- ADDON      : " + $s.AddonName + "`r`n");
        $hdr += ("-- FILE       : " + $s.RelativePath + " (Lines " + $s.StartLine + " - " + $s.EndLine + ")`r`n");
        $hdr += ("-- SIGNATURE  : " + $s.Signature + "`r`n");
        $hdr += ("-- CATEGORY   : " + $s.Category + "`r`n");
        if ($s.ApisUsed)   {$hdr += ("-- APIS USED  : " + $s.ApisUsed + "`r`n"); }
        if ($s.EventsUsed) { $hdr += ("-- EVENTS     : " + $s.EventsUsed + "`r`n"); }
        $hdr += "-- ============================================================================`r`n";
        $txtCodePreview.Text = ($hdr +$s.CodeBody);
    }
});

$btnCopyForAI.Add_Click({
    if ($txtCodePreview.Text.Length -gt 0) { [System.Windows.Forms.Clipboard]::SetText($txtCodePreview.Text);
        [System.Windows.Forms.MessageBox]::Show("Snippet copied to Clipboard with full Addon/File/Line headers! Ready to paste into AI chat.", "Copied for AI", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information);
    }
});

$btnBpFilter.Add_Click({ &$RefreshBlueprintsView; });
$cmbBpType.Add_SelectedIndexChanged({ &$RefreshBlueprintsView; });

$btnBuild.Add_Click({
    if ($lstFolders.Items.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("Please add at least one Addon folder to scan!", "No Folders", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning);
        return;
    }
    $outDir =$txtOutput.Text.Trim();
    if (-not $outDir) { return; }

    $btnBuild.Enabled =$false;
    $progBar.Value = 0; &$WriteLog "================================================================================";
    &$WriteLog "LAUNCHING 5-ENGINE OMNI-DECONSTRUCTION...";

    $folderArray = New-Object string[]$lstFolders.Items.Count;
    for ($i = 0; $i -lt $lstFolders.Items.Count; $i++) {
        $folderArray[$i] = [string]$lstFolders.Items[$i];
    }

    $progAction = [Action[int, int, string, int, int, int]] {
        param($curFile, $totFiles,$curName, $lootCnt,$snipCnt, $bpCnt);$pct = 0;
        if ($totFiles -gt 0) {$pct = [int][Math]::Floor(($curFile * 100.0) /$totFiles); }
        if ($pct -gt 100) {$pct = 100; }
        $progBar.Value =$pct;
        $lblProgStatus.Text = ("Scanning [" + $curFile + " / " + $totFiles + " (" + $pct + "%)] -> " + $curName);$lblStatsBanner.Text = ("Files: " + $curFile + " / " + $totFiles + "   |   Loot/DB Records: " + $lootCnt + "   |   Lua Functions Harvested: " + $snipCnt + "   \vert{}   Events/APIs/Templates: " + $bpCnt);
        [System.Windows.Forms.Application]::DoEvents();
    };

    $logAction = [Action[string]] { param($s); &$WriteLog$s; };

    $sw = [System.Diagnostics.Stopwatch]::StartNew();
    try {
        [DeconstructionGodEngine]::ExecuteOmniDeconstruction($folderArray, $outDir,$chkGeneric.Checked, $chkSnippets.Checked, $progAction, $logAction);$sw.Stop();

        $progBar.Value = 100;
        $lblProgStatus.Text = ("COMPLETE in " + $sw.ElapsedMilliseconds + " ms! Check Tab [2] and Tab [3] to browse harvested code and blueprints.");

        $cmbAddonFilter.Items.Clear();
        [void]$cmbAddonFilter.Items.Add("ALL ADDONS");
        $uniqueAddons = New-Object System.Collections.Generic.HashSet[string];
        foreach ($s in [DeconstructionGodEngine]::LastSnippets) {
            if ($uniqueAddons.Add($s.AddonName)) {
                [void]$cmbAddonFilter.Items.Add($s.AddonName);
            }
        }
        $cmbAddonFilter.SelectedIndex = 0;

        &$RefreshVaultList;
        &$RefreshBlueprintsView;

        $recs = [DeconstructionGodEngine]::LastLootRecords;
        $cClassic = ($recs \vert{} Where-Object {$_.Era -eq "Classic" }).Count;
        $cSod     = ($recs \vert{} Where-Object {$_.Era -eq "SoD_Forever" }).Count;
        $cTbc     = ($recs \vert{} Where-Object {$_.Era -eq "TBC" }).Count;
        $cWrath   = ($recs \vert{} Where-Object {$_.Era -eq "Wrath" }).Count;

        &$WriteLog "--------------------------------------------------------------------------------";
        &$WriteLog ("DECONSTRUCTION COMPLETE IN " + $sw.ElapsedMilliseconds + " MS!");
        &$WriteLog ("  * Total Holding Tank Records : " + $recs.Count + " (Classic: " + $cClassic + " \vert{} SoD/Forever: " + $cSod + " | TBC: " + $cTbc + " \vert{} Wrath: " + $cWrath + ")");
        &$WriteLog ("  * Total Lua Functions Indexed: " + [DeconstructionGodEngine]::LastSnippets.Count);
        &$WriteLog ("  * Total Events/APIs/XMLs     : " + [DeconstructionGodEngine]::LastBlueprints.Count);
        &$WriteLog "--------------------------------------------------------------------------------";
        &$WriteLog "Generated Files in Output Folder:";
        &$WriteLog "  1) DB_MasterHoldingTank.lua";
        &$WriteLog "  2) MasterHoldingTank_Export.csv";
        &$WriteLog "  3) AI_MASTER_LIBRARY_HANDOFF.txt";
    } catch {
        &$WriteLog ("ERROR: " + $_.Exception.Message);
    }
    $btnBuild.Enabled =$true;
});

&$WriteLog "Deconstruction God v3.2 Ready.";
&$WriteLog "Add your AtlasLoot, HealBot, Questie, or entire AddOns folders above, then click UNLEASH DECONSTRUCTION GOD!";

[void]$form.ShowDialog();