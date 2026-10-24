// ============================================================================
// DECONSTRUCTION GOD STUDIO v14.3 - MODULAR NODE SYSTEM
// NODE INDEX  : [13] OF [35]
// FILE NAME   : Node_13_AltVaultBridge.cs
// PARTIAL OF  : DataRipperEngine (AltVault Bridge)
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
