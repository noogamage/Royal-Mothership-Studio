// ============================================================================
// DECONSTRUCTION GOD STUDIO v14.3 - MODULAR NODE SYSTEM
// NODE INDEX  : [12] OF [35]
// FILE NAME   : Node_12_DataParsers.cs
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