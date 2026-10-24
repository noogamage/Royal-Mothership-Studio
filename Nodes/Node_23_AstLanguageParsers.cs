// ============================================================================
// DECONSTRUCTION GOD STUDIO v14.3 - MODULAR NODE SYSTEM
// NODE INDEX  : [23] OF [35]
// FILE NAME   : Node_23_AstLanguageParsers.cs
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
    // SECTION 7.0: MULTI-LANGUAGE AST & MEDIA/ASSET PARSERS
    // ========================================================================
    private static void CountFileExtension(AddonTelemetry stat, string ext) {
        stat.TotalFiles++;
        if (ext == ".lua") stat.LuaFiles++;
        else if (ext == ".xml") stat.XmlFiles++;
        else if (ext == ".toc") stat.TocFiles++;
        else stat.CodeOtherFiles++;
    }

    private static void ParseTocFile(AddonTelemetry addonStat, string fileName, string relPath, string fullPath, List<string> lines) {
        string addonName = addonStat.AddonName;
        for (int i = 0; i < lines.Count; i++) {
            string t = lines[i].Trim();
            if (t.StartsWith("## Interface:") || t.StartsWith("## Title:") || t.StartsWith("## Notes:") || t.StartsWith("## SavedVariables:") || t.StartsWith("## SavedVariablesPerCharacter:") || t.StartsWith("## Dependencies:") || t.StartsWith("## OptionalDeps:")) {
                string[] kv = t.Substring(2).Split(new char[] { ':' }, 2);
                if (kv.Length == 2) {
                    AddBlueprint(addonStat, "TOC_Metadata", addonName, fileName, relPath, fullPath, i + 1, kv[0].Trim(), kv[1].Trim());
                }
            }
        }
    }

    private static void ParseXmlFile(AddonTelemetry addonStat, string fileName, string relPath, string fullPath, List<string> lines) {
        string addonName = addonStat.AddonName;
        bool inXmlScript = false;
        string curXmlTag = "";
        int scriptStart = 0;
        StringBuilder sbScript = new StringBuilder();
        HashSet<string> emptySet = new HashSet<string>();

        for (int i = 0; i < lines.Count; i++) {
            string line = lines[i];
            if (line.Length > 2000) continue;
            Match mVirt = rxXmlTemplate.Match(line);
            if (mVirt.Success) {
                string widgetType = mVirt.Groups[1].Value;
                string tmplName   = mVirt.Groups[2].Value;
                string inh        = mVirt.Groups[3].Success ? mVirt.Groups[3].Value : "none";
                AddBlueprint(addonStat, "XML_VirtualTemplate", addonName, fileName, relPath, fullPath, i + 1, tmplName, widgetType + " (inherits: " + inh + ")");
            } else {
                Match mInh = rxXmlInherits.Match(line);
                if (mInh.Success) {
                    AddBlueprint(addonStat, "XML_FrameInherits", addonName, fileName, relPath, fullPath, i + 1, mInh.Groups[2].Value, mInh.Groups[1].Value + " inherits " + mInh.Groups[3].Value);
                }
            }

            if (!inXmlScript) {
                if (line.Contains("<OnLoad>") || line.Contains("<OnClick>") || line.Contains("<OnEvent>") || line.Contains("<OnShow>")) {
                    inXmlScript = true;
                    scriptStart = i + 1;
                    curXmlTag = line.Trim().Split('>')[0].TrimStart('<');
                    sbScript.Clear();
                    sbScript.AppendLine(line);
                    if (line.Contains("</On")) {
                        FinalizeSnippet(addonStat, addonName, "XML", fileName, relPath, fullPath, "XML_" + curXmlTag, "<" + curXmlTag + ">", scriptStart, i + 1, sbScript.ToString(), emptySet, emptySet);
                        inXmlScript = false;
                    }
                }
            } else {
                sbScript.AppendLine(line);
                if (line.Contains("</On") || (i + 1 - scriptStart) > 80) {
                    FinalizeSnippet(addonStat, addonName, "XML", fileName, relPath, fullPath, "XML_" + curXmlTag, "<" + curXmlTag + ">", scriptStart, i + 1, sbScript.ToString(), emptySet, emptySet);
                    inXmlScript = false;
                }
            }
        }
    }

    private static bool IsLuaIdentChar(char c) {
        return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') || c == '_';
    }

    private static void TryTrackFileLocalDeclaration(string trimmed, int lineNum, Dictionary<string, int> fileLocals) {
        if (fileLocals.Count >= 64) return;
        if (!trimmed.StartsWith("local ", StringComparison.Ordinal)) return;
        string rest = trimmed.Substring(6).TrimStart();
        if (rest.StartsWith("function ", StringComparison.Ordinal)) {
            rest = rest.Substring(9).TrimStart();
        }
        int len = 0;
        while (len < rest.Length && IsLuaIdentChar(rest[len])) len++;
        if (len >= 3 && len <= 36) {
            string ident = rest.Substring(0, len);
            if (ident != "function" && ident != "nil" && ident != "true" && ident != "false" && ident != "addonName") {
                fileLocals[ident] = lineNum;
            }
        }
    }

    private static string ResolveUpvalueDepsFast(string body, string fnName, Dictionary<string, int> fileLocals) {
        if (fileLocals == null || fileLocals.Count == 0 || string.IsNullOrEmpty(body)) return "";
        List<string> found = new List<string>(6);
        foreach (KeyValuePair<string, int> kvp in fileLocals) {
            string id = kvp.Key;
            if (string.Equals(id, fnName, StringComparison.Ordinal) || fnName.EndsWith("." + id, StringComparison.Ordinal) || fnName.EndsWith(":" + id, StringComparison.Ordinal)) continue;
            int idx = body.IndexOf(id, StringComparison.Ordinal);
            while (idx >= 0) {
                bool leftOk = (idx == 0) || !IsLuaIdentChar(body[idx - 1]);
                int endIdx = idx + id.Length;
                bool rightOk = (endIdx >= body.Length) || !IsLuaIdentChar(body[endIdx]);
                if (leftOk && rightOk) {
                    found.Add(id + "@L" + kvp.Value);
                    break;
                }
                idx = body.IndexOf(id, idx + id.Length, StringComparison.Ordinal);
            }
            if (found.Count >= 6) break;
        }
        return found.Count > 0 ? string.Join(", ", found.ToArray()) : "";
    }

    private static void ParseLuaFileForCodeAndBlueprints(AddonTelemetry addonStat, string fileName, string relPath, string fullPath, List<string> lines, bool harvestSnippets) {
        string addonName = addonStat.AddonName;
        bool inFunc = false;
        string curFuncName = "";
        string curFuncSig  = "";
        int curFuncStart   = 0;
        int blockDepth     = 0;
        StringBuilder sbFuncBody = new StringBuilder();
        HashSet<string> curFuncApis   = new HashSet<string>();
        HashSet<string> curFuncEvents = new HashSet<string>();
        Dictionary<string, int> fileLocals = new Dictionary<string, int>(StringComparer.Ordinal);

        int scanLimit = Math.Min(lines.Count, 60000);

        for (int i = 0; i < scanLimit; i++) {
            string line = lines[i];
            if (line.Length > 2000) continue;
            string trimmed = line.Trim();
            if (trimmed.Length == 0) continue;

            char c0 = trimmed[0];
            if (!inFunc) {
                if (c0 == '-' && trimmed.StartsWith("--", StringComparison.Ordinal)) continue;
                // Fast O(1) skip for pure data-table rows so 50,000-line hybrid files scan in < 3ms!
                if (c0 == '[' || c0 == '{' || c0 == '}' || c0 == '"' || c0 == '\'' || (c0 >= '0' && c0 <= '9')) continue;
                if (c0 == 'l') {
                    TryTrackFileLocalDeclaration(trimmed, i + 1, fileLocals);
                }
            }

            if (!(c0 == '-' && trimmed.StartsWith("--", StringComparison.Ordinal))) {
                if (line.Contains("Event")) {
                    Match mEv = rxRegEvent.Match(line);
                    if (mEv.Success) {
                        string evName = mEv.Groups[1].Value;
                        AddBlueprint(addonStat, "WoW_Event", addonName, fileName, relPath, fullPath, i + 1, evName, "Registered in " + addonName + "\\" + relPath);
                        if (inFunc) curFuncEvents.Add(evName);
                    }
                }

                if (line.Contains("Frame")) {
                    Match mCf = rxCreateFrame.Match(line);
                    if (mCf.Success) {
                        string fType = mCf.Groups[1].Value;
                        string fName = mCf.Groups[2].Success ? mCf.Groups[2].Value : "(anonymous)";
                        string fTmpl = mCf.Groups[3].Success ? mCf.Groups[3].Value : "none";
                        if (fTmpl != "none") {
                            AddBlueprint(addonStat, "Lua_FrameTemplate", addonName, fileName, relPath, fullPath, i + 1, fTmpl, fType + " '" + fName + "'");
                        }
                    }
                }

                if (line.Contains("C_")) {
                    MatchCollection mcApi = rxModernApi.Matches(line);
                    foreach (Match ma in mcApi) {
                        string apiCall = ma.Groups[1].Value.Trim();
                        AddBlueprint(addonStat, "Modern_API", addonName, fileName, relPath, fullPath, i + 1, apiCall, "Called in " + addonName + "\\" + relPath);
                        if (inFunc) curFuncApis.Add(apiCall);
                    }
                }

                if (line.Contains("TooltipDataProcessor")) {
                    Match mTp = rxTooltipProc.Match(line);
                    if (mTp.Success) {
                        string tpCall = mTp.Groups[1].Value.Trim();
                        AddBlueprint(addonStat, "Modern_API", addonName, fileName, relPath, fullPath, i + 1, tpCall, "Called in " + addonName + "\\" + relPath);
                        if (inFunc) curFuncApis.Add(tpCall);
                    }
                }

                if (line.Contains("hooksecurefunc")) {
                    Match mHs = rxHookSec.Match(line);
                    if (mHs.Success) {
                        string hookedTarget = mHs.Groups[2].Success ? mHs.Groups[2].Value : "hooksecurefunc";
                        AddBlueprint(addonStat, "Secure_Hook", addonName, fileName, relPath, fullPath, i + 1, "hooksecurefunc -> " + hookedTarget, "Hooked in " + addonName + "\\" + relPath);
                        if (inFunc) curFuncApis.Add("hooksecurefunc:" + hookedTarget);
                    }
                }

                if (line.Contains("SLASH_")) {
                    Match mSlash = rxSlashCmd.Match(line);
                    if (mSlash.Success) {
                        AddBlueprint(addonStat, "Slash_Command", addonName, fileName, relPath, fullPath, i + 1, mSlash.Groups[2].Value, "SLASH_" + mSlash.Groups[1].Value);
                    }
                }

                if (line.Contains("Interface\\")) {
                    Match mAsset = rxMediaAsset.Match(line);
                    if (mAsset.Success) {
                        AddBlueprint(addonStat, "Asset_Texture_Sound", addonName, fileName, relPath, fullPath, i + 1, mAsset.Groups[1].Value, "Media asset in " + addonName + "\\" + relPath);
                    }
                }

                if (line.Contains(" or {")) {
                    Match mSv = rxSavedVarTbl.Match(line);
                    if (mSv.Success) {
                        AddBlueprint(addonStat, "SavedVars_Schema", addonName, fileName, relPath, fullPath, i + 1, mSv.Groups[1].Value, "Persistent DB Table in " + addonName + "\\" + relPath);
                    }
                }
            }

            if (harvestSnippets) {
                if (!inFunc && line.IndexOf("function", StringComparison.Ordinal) < 0 && line.IndexOf("setmetatable", StringComparison.Ordinal) < 0) continue;

                int cmtPos = line.IndexOf("--", StringComparison.Ordinal);
                string codeNoComment = (cmtPos >= 0) ? line.Substring(0, cmtPos) : line;
                string codeNoStrings = (codeNoComment.IndexOf('"') >= 0) ? rxStripDqStrings.Replace(codeNoComment, "") : codeNoComment;

                if (!inFunc) {
                    Match mFn = rxLuaFuncNamed.Match(codeNoComment);
                    Match mFa = (!mFn.Success) ? rxLuaFuncAssign.Match(codeNoComment) : null;
                    Match mSc = (!mFn.Success && (mFa == null || !mFa.Success)) ? rxLuaSetScript.Match(codeNoComment) : null;
                    Match mMt = (!mFn.Success && (mFa == null || !mFa.Success) && (mSc == null || !mSc.Success)) ? rxLuaMetatable.Match(codeNoComment) : null;

                    if (mFn.Success || (mFa != null && mFa.Success) || (mSc != null && mSc.Success)) {
                        inFunc = true;
                        if (mFn.Success) {
                            curFuncName = mFn.Groups[1].Value;
                            curFuncSig  = curFuncName + "(" + mFn.Groups[2].Value.Trim() + ")";
                        } else if (mFa != null && mFa.Success) {
                            curFuncName = mFa.Groups[1].Value;
                            curFuncSig  = curFuncName + "(" + mFa.Groups[2].Value.Trim() + ")";
                        } else {
                            curFuncName = mSc.Groups[1].Value + ":" + mSc.Groups[2].Value;
                            curFuncSig  = curFuncName + "(" + mSc.Groups[3].Value.Trim() + ")";
                        }
                        curFuncStart = i + 1;
                        sbFuncBody.Clear();
                        curFuncApis.Clear();
                        curFuncEvents.Clear();
                        sbFuncBody.AppendLine(line);

                        int opens = rxLuaKwOpen.Matches(codeNoStrings).Count;
                        if (rxLuaLoopDo.IsMatch(codeNoStrings)) opens--;
                        int closes = rxLuaKwClose.Matches(codeNoStrings).Count;
                        blockDepth = opens - closes;
                        if (blockDepth <= 0) {
                            FinalizeSnippet(addonStat, addonName, "Lua", fileName, relPath, fullPath, curFuncName, curFuncSig, curFuncStart, i + 1, sbFuncBody.ToString(), curFuncApis, curFuncEvents, fileLocals);
                            inFunc = false;
                        }
                    } else if (mMt != null && mMt.Success) {
                        int mtEnd = Math.Min(i + 25, scanLimit - 1);
                        StringBuilder sbMt = new StringBuilder();
                        for (int mLine = i; mLine <= mtEnd; mLine++) sbMt.AppendLine(lines[mLine]);
                        FinalizeSnippet(addonStat, addonName, "Lua", fileName, relPath, fullPath, "Metatable_" + mMt.Groups[1].Value, "setmetatable(" + mMt.Groups[1].Value + ")", i + 1, mtEnd + 1, sbMt.ToString(), curFuncApis, curFuncEvents, fileLocals);
                    }
                } else {
                    sbFuncBody.AppendLine(line);
                    int opens = rxLuaKwOpen.Matches(codeNoStrings).Count;
                    if (rxLuaLoopDo.IsMatch(codeNoStrings)) opens--;
                    int closes = rxLuaKwClose.Matches(codeNoStrings).Count;
                    blockDepth += (opens - closes);

                    if (blockDepth <= 0 || (i + 1 - curFuncStart) > 1000) {
                        FinalizeSnippet(addonStat, addonName, "Lua", fileName, relPath, fullPath, curFuncName, curFuncSig, curFuncStart, i + 1, sbFuncBody.ToString(), curFuncApis, curFuncEvents, fileLocals);
                        inFunc = false;
                    }
                }
            }
        }
    }

    private static void ParseBraceLanguageFileForCode(AddonTelemetry addonStat, string fileName, string relPath, string fullPath, string ext, List<string> lines) {
        string addonName = addonStat.AddonName;
        string lang = MapExtensionToLanguage(ext);
        bool inBlock = false;
        string curName = "";
        string curSig  = "";
        int curStart   = 0;
        int braceDepth = 0;
        StringBuilder sbBody = new StringBuilder();
        HashSet<string> emptySet = new HashSet<string>();

        for (int i = 0; i < lines.Count; i++) {
            string line = lines[i];
            if (line.Length > 2000) continue;
            string trimmed = line.Trim();
            if (trimmed.StartsWith("//")) continue;

            if (!inBlock) {
                Match mCls = rxCStyleClass.Match(line);
                if (mCls.Success) {
                    string kind = mCls.Groups[1].Value;
                    string cname = mCls.Groups[2].Value;
                    AddBlueprint(addonStat, lang + "_Type", addonName, fileName, relPath, fullPath, i + 1, cname, kind + " in " + addonName + "\\" + relPath);
                }

                if (line.Contains("(")) {
                    Match mMeth = rxCStyleMethod.Match(line);
                    if (mMeth.Success) {
                        string mName = mMeth.Groups[1].Value;
                        if (mName != "if" && mName != "for" && mName != "while" && mName != "switch" && mName != "catch") {
                            inBlock = true;
                            curName = mName;
                            curSig  = mName + "(" + mMeth.Groups[2].Value.Trim() + ")";
                            curStart = i + 1;
                            sbBody.Clear();
                            sbBody.AppendLine(line);
                            braceDepth = CountChar(line, '{') - CountChar(line, '}');
                            if (braceDepth <= 0 && line.Contains("{")) {
                                FinalizeSnippet(addonStat, addonName, lang, fileName, relPath, fullPath, curName, curSig, curStart, i + 1, sbBody.ToString(), emptySet, emptySet);
                                inBlock = false;
                            }
                        }
                    }
                }
            } else {
                sbBody.AppendLine(line);
                braceDepth += (CountChar(line, '{') - CountChar(line, '}'));
                if (braceDepth <= 0 || (i + 1 - curStart) > 220) {
                    FinalizeSnippet(addonStat, addonName, lang, fileName, relPath, fullPath, curName, curSig, curStart, i + 1, sbBody.ToString(), emptySet, emptySet);
                    inBlock = false;
                }
            }
        }
    }

    private static void ParsePythonFileForCode(AddonTelemetry addonStat, string fileName, string relPath, string fullPath, List<string> lines) {
        string addonName = addonStat.AddonName;
        bool inPy = false;
        int baseIndent = 0;
        string curName = "";
        string curSig  = "";
        int curStart   = 0;
        StringBuilder sbBody = new StringBuilder();
        HashSet<string> emptySet = new HashSet<string>();

        for (int i = 0; i < lines.Count; i++) {
            string line = lines[i];
            if (line.Length > 2000) continue;
            string trimmed = line.Trim();
            if (trimmed.StartsWith("#")) continue;

            Match mPy = rxPyDefOrClass.Match(line);
            if (mPy.Success) {
                if (inPy) {
                    FinalizeSnippet(addonStat, addonName, "Python", fileName, relPath, fullPath, curName, curSig, curStart, i, sbBody.ToString(), emptySet, emptySet);
                }
                inPy = true;
                baseIndent = mPy.Groups[1].Value.Length;
                string kw = mPy.Groups[2].Value;
                curName = mPy.Groups[3].Value;
                string args = mPy.Groups[4].Success ? mPy.Groups[4].Value : "()";
                curSig = kw + " " + curName + args;
                curStart = i + 1;
                sbBody.Clear();
                sbBody.AppendLine(line);
                if (kw == "class") {
                    AddBlueprint(addonStat, "Python_Class", addonName, fileName, relPath, fullPath, i + 1, curName, "Class in " + addonName + "\\" + relPath);
                }
                continue;
            }

            if (inPy) {
                if (!string.IsNullOrEmpty(trimmed)) {
                    int curIndent = line.Length - line.TrimStart().Length;
                    if (curIndent <= baseIndent && (i + 1 - curStart) > 1) {
                        FinalizeSnippet(addonStat, addonName, "Python", fileName, relPath, fullPath, curName, curSig, curStart, i, sbBody.ToString(), emptySet, emptySet);
                        inPy = false;
                        continue;
                    }
                }
                sbBody.AppendLine(line);
                if ((i + 1 - curStart) > 200) {
                    FinalizeSnippet(addonStat, addonName, "Python", fileName, relPath, fullPath, curName, curSig, curStart, i + 1, sbBody.ToString(), emptySet, emptySet);
                    inPy = false;
                }
            }
        }
        if (inPy) {
            FinalizeSnippet(addonStat, addonName, "Python", fileName, relPath, fullPath, curName, curSig, curStart, lines.Count, sbBody.ToString(), emptySet, emptySet);
        }
    }

    private static void ParseSqlFileForCode(AddonTelemetry addonStat, string fileName, string relPath, string fullPath, List<string> lines) {
        string addonName = addonStat.AddonName;
        for (int i = 0; i < lines.Count; i++) {
            Match mSql = rxSqlCreate.Match(lines[i]);
            if (mSql.Success) {
                string objType = mSql.Groups[1].Value.ToUpperInvariant();
                string objName = mSql.Groups[2].Value;
                AddBlueprint(addonStat, "SQL_" + objType, addonName, fileName, relPath, fullPath, i + 1, objName, "SQL Schema in " + addonName + "\\" + relPath);
            }
        }
    }

    private static int CountChar(string s, char c) {
        int cnt = 0;
        for (int i = 0; i < s.Length; i++) {
            if (s[i] == c) cnt++;
        }
        return cnt;
    }

    private static void FinalizeSnippet(AddonTelemetry addonStat, string addon, string lang, string file, string relPath, string fullPath, string fnName, string sig, int startLn, int endLn, string body, HashSet<string> apis, HashSet<string> evts) {
        FinalizeSnippet(addonStat, addon, lang, file, relPath, fullPath, fnName, sig, startLn, endLn, body, apis, evts, null);
    }

    private static void FinalizeSnippet(AddonTelemetry addonStat, string addon, string lang, string file, string relPath, string fullPath, string fnName, string sig, int startLn, int endLn, string body, HashSet<string> apis, HashSet<string> evts, Dictionary<string, int> fileLocals) {
        int lineSpan = endLn - startLn + 1;
        if (lineSpan < 3) return;

        string cat = ClassifyFeatureIntent(fnName, body, addon, lang);
        string legoTag;
        string idea;
        ClassifyCreativeLegoBrick(fnName, body, addon, lang, lineSpan, out legoTag, out idea);

        string upDeps = (lang == "Lua" && fileLocals != null) ? ResolveUpvalueDepsFast(body, fnName, fileLocals) : "";
        if (!string.IsNullOrEmpty(upDeps)) {
            idea = idea + " [Upvalues: " + upDeps + "]";
        }

        int synScore;
        string inSocks;
        string outPlugs;
        AnalyzeCodeCompatibilityAndSynergy(addon, fnName, sig, body, cat, legoTag, lineSpan, apis.Count, evts.Count, out synScore, out inSocks, out outPlugs);

        TotalSavedSnippetsOnDisk++;
        CodeSnippet cs = new CodeSnippet();
        cs.SnippetID        = TotalSavedSnippetsOnDisk;
        cs.AddonName        = addon;
        cs.Language         = lang;
        cs.FileName         = file;
        cs.RelativePath     = string.IsNullOrEmpty(relPath) ? (addon + "\\" + file) : (addon + "\\" + relPath);
        cs.FullFilePath     = fullPath;
        cs.FuncName         = fnName;
        cs.Signature        = sig;
        cs.StartLine        = startLn;
        cs.EndLine          = endLn;
        cs.Category         = cat;
        cs.CreativeLegoTag  = legoTag;
        cs.FrankensteinIdea = idea;
        cs.ApisUsed         = string.Join(", ", apis);
        cs.EventsUsed       = string.Join(", ", evts);
        cs.SynergyScore     = synScore;
        cs.InputSockets     = inSocks;
        cs.OutputPlugs      = outPlugs;
        cs.UpvalueDeps      = upDeps;
        cs.CodeBody         = "";

        CurrentFileSnippets.Add(cs);

        if (addonStat != null) {
            addonStat.FunctionsCount++;
            if (legoTag != "Lego_Utility_And_Math") {
                addonStat.CreativeBricksCount++;
                TotalSavedCreativeBricksOnDisk++;
            }
        }
    }

    private static void AddBlueprint(AddonTelemetry addonStat, string bType, string addon, string file, string relPath, string fullPath, int ln, string key, string details) {
        string parentRel = string.IsNullOrEmpty(relPath) ? (addon + "\\" + file) : (addon + "\\" + relPath);
        string k = bType + SEP + addon + SEP + key + SEP + parentRel;
        if (!CurrentAddonSeenBlueprints.Add(k)) return;

        BlueprintEntry b = new BlueprintEntry();
        b.EntryType          = bType;
        b.AddonName          = addon;
        b.FileName           = file;
        b.ParentRelativePath = DataRipperEngine.SanitizeField(parentRel);
        b.ParentFullDiskPath = DataRipperEngine.SanitizeField(fullPath);
        b.LineNumber         = ln;
        b.KeyName            = DataRipperEngine.SanitizeField(key);
        b.Details            = DataRipperEngine.SanitizeField(details);

        CurrentFileBlueprints.Add(b);
        TotalSavedBlueprintsOnDisk++;
        if (addonStat != null) {
            addonStat.BlueprintsCount++;
        }
    }
}
