// ============================================================================
// DECONSTRUCTION GOD STUDIO v14.3 - MODULAR NODE SYSTEM
// NODE INDEX  : [22] OF [35]
// FILE NAME   : Node_22_LayerQueueScanner.cs
// PARTIAL OF  : CodeHarvesterEngine
// ============================================================================
using System;
using System.IO;
using System.Net;
using System.Text;
using System.Drawing;
using System.Windows.Forms;
using System.Text.RegularExpressions;
using System.Collections.Generic;

public static partial class CodeHarvesterEngine {
    // ========================================================================
    // SECTION 6.0: BREADTH-FIRST LAYER-BY-LAYER QUEUE & 1-FILE-AT-A-TIME STREAMER
    // ========================================================================
    public static List<Tuple<string, string, bool>> DiscoverTargetsFromDrop(string[] inputPaths) {
        List<Tuple<string, string, bool>> targets = new List<Tuple<string, string, bool>>();
        HashSet<string> seenPaths = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

        for (int i = 0; i < inputPaths.Length; i++) {
            string p = inputPaths[i];
            if (string.IsNullOrWhiteSpace(p)) continue;

            if (File.Exists(p)) {
                FileInfo fi = new FileInfo(p);
                string parentName = fi.Directory != null ? fi.Directory.Name : "DroppedFiles";
                if (seenPaths.Add(p)) {
                    targets.Add(Tuple.Create(parentName, p, true));
                }
                continue;
            }

            if (!Directory.Exists(p)) continue;
            string dirName = new DirectoryInfo(p).Name;
            if (string.Equals(dirName, "AltVault", StringComparison.OrdinalIgnoreCase)) continue;
            if (string.Equals(dirName, "Backup", StringComparison.OrdinalIgnoreCase)) continue;
            if (string.Equals(dirName, "Nodes", StringComparison.OrdinalIgnoreCase)) continue;
            if (string.Equals(dirName, "Forged_Addon_Prototypes", StringComparison.OrdinalIgnoreCase)) continue;
            if (string.Equals(dirName, "DeconstructionGod_Studio", StringComparison.OrdinalIgnoreCase)) continue;
            if (string.Equals(dirName, "Portable_SQL_Trough", StringComparison.OrdinalIgnoreCase)) continue;

            string[] rootTocs = new string[0];
            try { rootTocs = Directory.GetFiles(p, "*.toc", SearchOption.TopDirectoryOnly); } catch {}
            bool hasDirectCode = (rootTocs.Length > 0);
            if (!hasDirectCode) {
                try {
                    string[] rootCode = Directory.GetFiles(p, "*.*", SearchOption.TopDirectoryOnly);
                    for (int r = 0; r < rootCode.Length; r++) {
                        string ext = Path.GetExtension(rootCode[r]).ToLowerInvariant();
                        if (DataRipperEngine.IsSupportedExtension(ext)) {
                            hasDirectCode = true;
                            break;
                        }
                    }
                } catch {}
            }

            if (hasDirectCode) {
                if (seenPaths.Add(p)) {
                    targets.Add(Tuple.Create(dirName, p, false));
                }
            } else {
                string[] subDirs = new string[0];
                try { subDirs = Directory.GetDirectories(p, "*", SearchOption.TopDirectoryOnly); } catch {}
                for (int s = 0; s < subDirs.Length; s++) {
                    string sd = subDirs[s];
                    string sdName = new DirectoryInfo(sd).Name;
                    if (string.Equals(sdName, "AltVault", StringComparison.OrdinalIgnoreCase)) continue;
                    if (string.Equals(sdName, "Backup", StringComparison.OrdinalIgnoreCase)) continue;
                    if (string.Equals(sdName, "Nodes", StringComparison.OrdinalIgnoreCase)) continue;
                    if (string.Equals(sdName, "Forged_Addon_Prototypes", StringComparison.OrdinalIgnoreCase)) continue;
                    if (string.Equals(sdName, "DeconstructionGod_Studio", StringComparison.OrdinalIgnoreCase)) continue;
                    if (string.Equals(sdName, "Portable_SQL_Trough", StringComparison.OrdinalIgnoreCase)) continue;
                    if (seenPaths.Add(sd)) {
                        targets.Add(Tuple.Create(sdName, sd, false));
                    }
                }
            }
        }
        return targets;
    }

    private static List<string> ReadFileLinesSafe(string filePath, int maxLines, out string sampleHeader) {
        List<string> lines = new List<string>(256);
        StringBuilder sbSample = new StringBuilder(512);
        using (StreamReader sr = new StreamReader(filePath, Encoding.UTF8)) {
            string ln;
            int cnt = 0;
            while ((ln = sr.ReadLine()) != null) {
                lines.Add(ln);
                if (cnt < 30) sbSample.AppendLine(ln);
                cnt++;
                if (cnt >= maxLines) break;
            }
        }
        sampleHeader = sbSample.ToString();
        return lines;
    }

    public static void ExecuteOmniDeconstruction(
        string[] droppedPaths,
        string altVaultOutputDir,
        string studioDir,
        bool ripGenericData,
        bool harvestCodeSnippets,
        bool forceReScan,
        Action<string> logCallback
    ) {
        CancelRequested = false;
        DataRipperEngine.ActiveStudioDirForMidFlush = studioDir;
        List<Tuple<string, string, bool>> parentQueue = DiscoverTargetsFromDrop(droppedPaths);
        int totalParents = parentQueue.Count;
        LiveParentTotal = totalParents;

        if (forceReScan) {
            HashSet<string> parentsToPurge = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            for (int i = 0; i < parentQueue.Count; i++) {
                parentsToPurge.Add(parentQueue[i].Item1);
            }
            logCallback("Purging old disk records for " + parentsToPurge.Count + " selected parent group(s) before Re-Chew...");
            DataRipperEngine.PurgeParentFromDiskDataTrough(studioDir, parentsToPurge);
            PurgeParentFromDiskCodeTrough(studioDir, parentsToPurge);
        }

        int skippedParents = 0;
        int chewedParents  = 0;

        for (int pIdx = 0; pIdx < totalParents; pIdx++) {
            if (CancelRequested) {
                logCallback("STOPPED BY USER at Parent [" + (pIdx + 1) + "/" + totalParents + "]. All previous parents and files are safely committed to disk.");
                break;
            }

            string addonName  = parentQueue[pIdx].Item1;
            string targetPath = parentQueue[pIdx].Item2;
            bool isSingleFile = parentQueue[pIdx].Item3;

            LiveParentIndex = pIdx + 1;
            LiveParentName  = addonName;

            AddonTelemetry existingStat;
            if (!forceReScan && DataRipperEngine.AddonStatsMap.TryGetValue(addonName, out existingStat)) {
                if (existingStat.TotalFiles > 0 && existingStat.StatusBadge.Contains("COMPLETED")) {
                    existingStat.StatusBadge = "COMPLETED (SKIPPED)";
                    skippedParents++;
                    continue;
                }
            }

            DataRipperEngine.ClearCurrentAddonDedupMemory();
            ClearCurrentAddonCodeMemory();

            AddonTelemetry stat = DataRipperEngine.GetOrCreateAddonTelemetry(addonName, targetPath);
            stat.FolderPath          = targetPath;
            stat.LastWriteSignature  = "SIG_" + DateTime.UtcNow.Ticks;
            stat.StatusBadge         = "CHEWING LAYERS...";
            stat.TotalFolders        = 0;
            stat.TotalFiles          = 0;
            stat.LuaFiles            = 0;
            stat.XmlFiles            = 0;
            stat.TocFiles            = 0;
            stat.CodeOtherFiles      = 0;
            stat.DataRecordsCount    = 0;
            stat.ItemIDsCount        = 0;
            stat.SpellIDsCount       = 0;
            stat.QuestOrNpcIDsCount  = 0;
            stat.FunctionsCount      = 0;
            stat.CreativeBricksCount = 0;
            stat.BlueprintsCount     = 0;

            if (isSingleFile) {
                stat.TotalFolders = 1;
                LiveLayerDepth = 0;
                LiveSubFolder  = "(Single File)";
                ProcessSingleFileAndFlushImmediately(stat, targetPath, targetPath, studioDir, ripGenericData, harvestCodeSnippets);
            } else {
                Queue<Tuple<string, int>> folderLayerQueue = new Queue<Tuple<string, int>>();
                folderLayerQueue.Enqueue(Tuple.Create(targetPath, 0));

                while (folderLayerQueue.Count > 0 && !CancelRequested) {
                    Tuple<string, int> currentDirNode = folderLayerQueue.Dequeue();
                    string currentDirPath = currentDirNode.Item1;
                    int currentLayerDepth = currentDirNode.Item2;

                    stat.TotalFolders++;
                    LiveLayerDepth = currentLayerDepth;
                    string relFolder = (currentDirPath.Length > targetPath.Length)
                        ? currentDirPath.Substring(targetPath.Length).TrimStart('\\', '/')
                        : "(Root Layer 0)";
                    LiveSubFolder = relFolder;

                    string[] childDirs = new string[0];
                    try {
                        childDirs = Directory.GetDirectories(currentDirPath, "*", SearchOption.TopDirectoryOnly);
                    } catch {}

                    for (int c = 0; c < childDirs.Length; c++) {
                        string cName = new DirectoryInfo(childDirs[c]).Name;
                        if (cName.StartsWith(".")) continue;
                        if (string.Equals(cName, "Portable_SQL_Trough", StringComparison.OrdinalIgnoreCase)) continue;
                        folderLayerQueue.Enqueue(Tuple.Create(childDirs[c], currentLayerDepth + 1));
                    }

                    string[] dirFiles = new string[0];
                    try {
                        dirFiles = Directory.GetFiles(currentDirPath, "*.*", SearchOption.TopDirectoryOnly);
                    } catch {}

                    LiveFolderFilesTotal = dirFiles.Length;
                    for (int f = 0; f < dirFiles.Length; f++) {
                        if (CancelRequested) break;
                        LiveFolderFilesIndex = f + 1;
                        ProcessSingleFileAndFlushImmediately(stat, dirFiles[f], targetPath, studioDir, ripGenericData, harvestCodeSnippets);
                    }
                }
            }

            DataRipperEngine.FlushSingleFileDataToDisk(studioDir);
            FlushSingleFileCodeToDisk(studioDir);
            stat.StatusBadge = CancelRequested ? "PAUSED (PARTIAL)" : "COMPLETED (SAVED)";
            if ((pIdx & 31) == 0 || pIdx == totalParents - 1 || CancelRequested) {
                DataRipperEngine.SaveAddonInventoryTableToDisk(studioDir);
            }
            DataRipperEngine.ClearCurrentAddonDedupMemory();
            ClearCurrentAddonCodeMemory();
            if ((pIdx & 63) == 0) GC.Collect();

            if (!CancelRequested) {
                chewedParents++;
                logCallback(string.Format(
                    "Finished Parent [{0}/{1}] {2} (Folders:{3} Files:{4}) -> Data IDs:{5} | Code Blocks:{6} | Creative Bricks:{7}",
                    (pIdx + 1), totalParents, addonName, stat.TotalFolders, stat.TotalFiles, stat.DataRecordsCount, stat.FunctionsCount, stat.CreativeBricksCount
                ));
            }
        }

        if (skippedParents > 0) {
            logCallback("Smart-Skip bypassed " + skippedParents + " already-completed parent folder(s).");
        }

        int uItems, uSpells, uSets, uQuests;
        DataRipperEngine.StreamLuaFeederFromDiskTrough(studioDir, altVaultOutputDir, logCallback, out uItems, out uSpells, out uSets, out uQuests);
        WriteStudioReadmeAndAiManual(studioDir, uItems, uSpells, uSets, uQuests, logCallback);
    }

    private static void ProcessSingleFileAndFlushImmediately(
        AddonTelemetry stat,
        string filePath,
        string parentRootPath,
        string studioDir,
        bool ripGenericData,
        bool harvestCodeSnippets
    ) {
        DataRipperEngine.ActiveStudioDirForMidFlush = studioDir;
        string fName = Path.GetFileName(filePath);
        if (fName.StartsWith("DB_MasterHoldingTank", StringComparison.OrdinalIgnoreCase)) return;
        if (fName.StartsWith("Core_MasterLootIndex", StringComparison.OrdinalIgnoreCase)) return;
        if (fName.StartsWith("AI_MASTER_LIBRARY_HANDOFF", StringComparison.OrdinalIgnoreCase)) return;
        if (fName.StartsWith("STUDIO_README", StringComparison.OrdinalIgnoreCase)) return;
        if (fName.StartsWith("Trough_", StringComparison.OrdinalIgnoreCase)) return;

        string ext = Path.GetExtension(filePath).ToLowerInvariant();
        if (!DataRipperEngine.IsSupportedExtension(ext)) return;

        FileInfo fi = new FileInfo(filePath);
        if (!fi.Exists || fi.Length > 30 * 1024 * 1024) return;

        LiveFileName = fName;
        CountFileExtension(stat, ext);

        string relPath = (filePath.Length > parentRootPath.Length && Directory.Exists(parentRootPath))
            ? filePath.Substring(parentRootPath.Length).TrimStart('\\', '/')
            : fName;

        string sampleHeader = "";
        List<string> lines;
        try {
            lines = ReadFileLinesSafe(filePath, 250000, out sampleHeader);
        } catch {
            return;
        }

        if (ext == ".toc") {
            ParseTocFile(stat, fName, relPath, filePath, lines);
        } else if (ext == ".xml") {
            ParseXmlFile(stat, fName, relPath, filePath, lines);
        } else {
            string fileEra = DataRipperEngine.DetectFileEra(filePath, sampleHeader);
            if (ext == ".lua") {
                DataRipperEngine.ParseLuaFileForData(stat, filePath, relPath, lines, fileEra, ripGenericData);
                bool isGeneratedBlob = fName.StartsWith("DB_TankNode_", StringComparison.OrdinalIgnoreCase) || fName.StartsWith("DB_MasterHoldingTank", StringComparison.OrdinalIgnoreCase);
                bool parseCodeInLua = harvestCodeSnippets && !isGeneratedBlob && (lines.Count <= 60000);
                ParseLuaFileForCodeAndBlueprints(stat, fName, relPath, filePath, lines, parseCodeInLua);
            } else if (ext == ".sql" || ext == ".json" || ext == ".csv") {
                DataRipperEngine.ParseStructuredDataFile(stat, filePath, relPath, lines, fileEra);
                if (ext == ".sql" && harvestCodeSnippets) {
                    ParseSqlFileForCode(stat, fName, relPath, filePath, lines);
                }
            } else if (ext == ".py" && harvestCodeSnippets && lines.Count <= 4500) {
                ParsePythonFileForCode(stat, fName, relPath, filePath, lines);
            } else if (harvestCodeSnippets && lines.Count <= 4500) {
                ParseBraceLanguageFileForCode(stat, fName, relPath, filePath, ext, lines);
            }
        }

        lines.Clear();

        if (CurrentFileSnippets.Count >= 1500 || CurrentFileBlueprints.Count >= 1500) {
            FlushSingleFileCodeToDisk(studioDir);
        }
    }
}
