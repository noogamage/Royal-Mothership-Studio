// ============================================================================
// DECONSTRUCTION GOD STUDIO v14.3 - MODULAR NODE SYSTEM
// NODE INDEX  : [20] OF [35]
// FILE NAME   : Node_20_HarvesterModels.cs
// PARTIAL OF  : CodeSnippet, AtomicConceptEntry, CodeHarvesterEngine
// ============================================================================
using System;
using System.IO;
using System.Net;
using System.Text;
using System.Drawing;
using System.Windows.Forms;
using System.Text.RegularExpressions;
using System.Collections.Generic;

// SECTION 2.0: CODE, ATOMIC CONCEPT, SYNERGY MATRIX & FORGE MODELS
// ============================================================================
public class CodeSnippet {
    public int SnippetID = 0;
    public string AddonName = "";
    public string Language = "Lua";
    public string FileName = "";
    public string RelativePath = "";
    public string FullFilePath = "";
    public string FuncName = "";
    public string Signature = "";
    public string Category = "General_Logic_And_Utils";
    public string CreativeLegoTag = "Lego_Utility_And_Math";
    public string FrankensteinIdea = "";
    public int StartLine = 0;
    public int EndLine = 0;
    public string ApisUsed = "";
    public string EventsUsed = "";
    public int SynergyScore = 50;
    public string InputSockets = "Socket_Generic";
    public string OutputPlugs = "Plug_State_Mutation";
    public string RoleTag = "Processor";
    public string UpvalueDeps = "";
    public string CodeBody = "";
}

public class AtomicConceptEntry {
    public int ConceptID = 0;
    public int SourceSnippetID = 0;
    public string AddonName = "";
    public string FuncName = "";
    public string Signature = "";
    public string RelativePath = "";
    public string FullFilePath = "";
    public int StartLine = 0;
    public int EndLine = 0;
    public string Category = "";
    public string CreativeLegoTag = "";
    public string OrganRole = "PROCESSOR";
    public string PrimarySocket = "Socket_Generic";
    public string OutputPlugs = "Plug_State_Mutation";
    public string ParamNames = "";
    public string ReturnVars = "";
    public string CoreApiTokens = "";
    public int PortabilityScore = 80;
    public int VersatilityScore = 85;
    public string ApisUsed = "";
}

public class BlueprintEntry {
    public string EntryType = "";
    public string AddonName = "";
    public string FileName = "";
    public string ParentRelativePath = "";
    public string ParentFullDiskPath = "";
    public int LineNumber = 0;
    public string KeyName = "";
    public string Details = "";
}

public class AddonForgeBlueprint {
    public int ForgeID = 0;
    public string AddonTitle = "";
    public string SafeFolderName = "";
    public string DomainSocket = "";
    public string TargetCategory = "";
    public int TotalSynergyScore = 90;
    public string ParentLineageMix = "";
    public string SharedApiFamily = "";
    public string ExecutivePitch = "";
    public string ArchitectureFlow = "";
    public CodeSnippet TriggerBlock = null;
    public CodeSnippet ProducerBlock = null;
    public CodeSnippet EnginePoolBlock = null;
    public CodeSnippet UiRenderBlock = null;
    public string AgentGlueLuaCode = "";
    public string BaseBlueprintReport = "";
    public string LlmMicroSynthesisNotes = "";
    public string FullBlueprintReport = "";
}

public class ManualTopic {
    public string SectionNum = "";
    public string Title = "";
    public string Category = "";
    public string Keywords = "";
    public string GuideBody = "";
}

// ============================================================================
// SECTION 3.0: STATIC ENGINE STATE, LIVE TELEMETRY & COMPILED REGEXES
// ============================================================================
public static partial class CodeHarvesterEngine {
    public static List<CodeSnippet> HarvestedSnippets = new List<CodeSnippet>();
    public static List<BlueprintEntry> HarvestedBlueprints = new List<BlueprintEntry>();
    public static List<AddonForgeBlueprint> ForgedAddonIdeas = new List<AddonForgeBlueprint>();
    public static List<AtomicConceptEntry> DistilledConcepts = new List<AtomicConceptEntry>();
    public static HashSet<int> UsedSeedSnippetIDs = new HashSet<int>();

    public static List<CodeSnippet> CurrentFileSnippets = new List<CodeSnippet>(64);
    public static List<BlueprintEntry> CurrentFileBlueprints = new List<BlueprintEntry>(64);

    public static List<ManualTopic> StudioManualTopics = new List<ManualTopic>();
    public static volatile bool CancelRequested = false;

    public static int TotalSavedSnippetsOnDisk = 0;
    public static int TotalSavedCreativeBricksOnDisk = 0;
    public static int TotalSavedBlueprintsOnDisk = 0;
    public static int TotalAtomicConceptsOnDisk = 0;
    public static int TotalSynergyMatrixPairsOnDisk = 0;
    public static int DiscoveryGenerationCounter = 0;

    public static volatile string LiveParentName = "IDLE";
    public static volatile int LiveParentIndex = 0;
    public static volatile int LiveParentTotal = 0;
    public static volatile int LiveLayerDepth = 0;
    public static volatile string LiveSubFolder = "";
    public static volatile string LiveFileName = "";
    public static volatile int LiveFolderFilesIndex = 0;
    public static volatile int LiveFolderFilesTotal = 0;

    private static HashSet<string> CurrentAddonSeenBlueprints = new HashSet<string>();
    private static string SEP = ((char)124).ToString();
    private static string TAB = "\t";

    private static Regex rxLuaFuncNamed  = new Regex(@"^\s*(?:local\s+)?function\s+([A-Za-z0-9_:\.]+)\s*\(([^)]*)\)", RegexOptions.Compiled);
    private static Regex rxLuaFuncAssign = new Regex(@"^\s*([A-Za-z0-9_:\.\[\]""']+)\s*=\s*function\s*\(([^)]*)\)", RegexOptions.Compiled);
    private static Regex rxLuaSetScript  = new Regex(@"([A-Za-z0-9_:\.]+)\s*:\s*(?:Set|Hook)Script\s*\(\s*""(On[A-Za-z]+)""\s*,\s*function\s*\(([^)]*)\)", RegexOptions.Compiled);
    private static Regex rxLuaMetatable  = new Regex(@"setmetatable\s*\(\s*([A-Za-z0-9_\.\{\}]+)\s*,\s*\{", RegexOptions.Compiled);
    private static Regex rxLuaKwOpen     = new Regex(@"\b(function|if|for|while|repeat|do)\b", RegexOptions.Compiled);
    private static Regex rxLuaKwClose    = new Regex(@"\b(end|until)\b", RegexOptions.Compiled);
    private static Regex rxLuaLoopDo     = new Regex(@"\b(while|for)\b.*\bdo\b", RegexOptions.Compiled);
    private static Regex rxStripDqStrings = new Regex(@"""[^""]*""", RegexOptions.Compiled);

    private static Regex rxCStyleClass   = new Regex(@"^\s*(?:public\s+|private\s+|protected\s+|internal\s+|static\s+|abstract\s+|sealed\s+)*(class|struct|interface|enum)\s+([A-Za-z0-9_:<>\.]+)", RegexOptions.Compiled);
    private static Regex rxCStyleMethod  = new Regex(@"^\s*(?:[A-Za-z0-9_<>\[\]\*&\s:]+\s+)([A-Za-z0-9_:~]+)\s*\(([^;]*)\)\s*(?:const)?\s*\{?", RegexOptions.Compiled);
    private static Regex rxPyDefOrClass  = new Regex(@"^(\s*)(def|class)\s+([A-Za-z0-9_]+)\s*(\([^)]*\))?\s*:", RegexOptions.Compiled);
    private static Regex rxSqlCreate     = new Regex(@"^\s*CREATE\s+(?:TEMPORARY\s+)?(TABLE|VIEW|PROCEDURE|FUNCTION|TRIGGER)\s+(?:IF\s+NOT\s+EXISTS\s+)?([A-Za-z0-9_`\.]+)", RegexOptions.Compiled | RegexOptions.IgnoreCase);

    private static Regex rxRegEvent    = new Regex(@"\b(?:Safe)?RegisterEvent\s*\(\s*(?:[A-Za-z0-9_]+\s*,\s*)?""([A-Z0-9_]+)""", RegexOptions.Compiled);
    private static Regex rxCreateFrame = new Regex(@"\bCreate(?:Backdrop)?Frame\s*\(\s*""([^""]+)""(?:\s*,\s*""([^""]*)"")?(?:\s*,\s*[^,]+)?(?:\s*,\s*""([^""]+)"")?", RegexOptions.Compiled);
    private static Regex rxModernApi   = new Regex(@"\b(C_[A-Za-z0-9_]+\.[A-Za-z0-9_]+)\b", RegexOptions.Compiled);
    private static Regex rxTooltipProc = new Regex(@"\b(TooltipDataProcessor\.[A-Za-z0-9_]+)\b", RegexOptions.Compiled);
    private static Regex rxHookSec     = new Regex(@"\b(hooksecurefunc)\s*\(\s*(?:[A-Za-z0-9_]+\s*,\s*)?""?([A-Za-z0-9_]+)""?", RegexOptions.Compiled);
    private static Regex rxSlashCmd    = new Regex(@"SLASH_([A-Za-z0-9_]+)\d*\s*=\s*""(/[^""]+)""", RegexOptions.Compiled);
    private static Regex rxMediaAsset  = new Regex(@"""(Interface\\\\[^""]+\.(?:blp|tga|ogg|mp3|ttf)|Interface\\[^""]+\.(?:blp|tga|ogg|mp3|ttf))""", RegexOptions.Compiled | RegexOptions.IgnoreCase);
    private static Regex rxSavedVarTbl = new Regex(@"^\s*([A-Za-z0-9_]+(?:DB|Saved|Config|Options|Storage))\s*=\s*([A-Za-z0-9_]+(?:DB|Saved|Config|Options|Storage))\s+or\s+\{", RegexOptions.Compiled);
    private static Regex rxXmlTemplate = new Regex(@"<([A-Za-z0-9_]+)\s+[^>]*name=""([^""]+)""[^>]*virtual=""true""[^>]*(?:inherits=""([^""]+)"")?", RegexOptions.Compiled | RegexOptions.IgnoreCase);
    private static Regex rxXmlInherits = new Regex(@"<([A-Za-z0-9_]+)\s+[^>]*name=""([^""]+)""[^>]*inherits=""([^""]+)""", RegexOptions.Compiled | RegexOptions.IgnoreCase);

    private static Regex rxTrueModuloMath = new Regex(@"(?:\bmath\.(?:floor|ceil|fmod)\s*\(|\b(?:col|row|idx|index|i|slot)\s*%\s*[A-Za-z0-9_]+)", RegexOptions.Compiled | RegexOptions.IgnoreCase);
    // Fixed v14.3: Horizontal single-line whitespace [ \t]+ only so bare "return" never jumps across newlines!
    private static Regex rxRealReturnStmt = new Regex(@"\breturn[ \t]+(?!end\b|elseif\b|else\b|until\b)([A-Za-z0-9_,\.\(\)\[\]\{\}""' \t]+)", RegexOptions.Compiled);
    private static Regex rxOllamaModelTag = new Regex(@"""name""\s*:\s*""([^""]+)""", RegexOptions.Compiled);
    private static Regex rxOllamaResponse = new Regex(@"""response""\s*:\s*""((?:[^""\\]|\\.)*)""", RegexOptions.Compiled);

    // ========================================================================
    // SECTION 4.0: ZERO-RAM MEMORY MANAGEMENT & ON-DEMAND DISK CODE READER
    // ========================================================================
    public static void ResetAllCodeMemory() {
        HarvestedSnippets.Clear();
        CurrentFileSnippets.Clear();
        HarvestedBlueprints.Clear();
        CurrentFileBlueprints.Clear();
        ForgedAddonIdeas.Clear();
        DistilledConcepts.Clear();
        UsedSeedSnippetIDs.Clear();
        CurrentAddonSeenBlueprints.Clear();
        TotalSavedSnippetsOnDisk = 0;
        TotalSavedCreativeBricksOnDisk = 0;
        TotalSavedBlueprintsOnDisk = 0;
    }

    public static void ClearForgeMemoryOnly() {
        ForgedAddonIdeas.Clear();
        UsedSeedSnippetIDs.Clear();
        DiscoveryGenerationCounter = 0;
    }

    public static void ClearCurrentAddonCodeMemory() {
        CurrentFileSnippets.Clear();
        CurrentFileBlueprints.Clear();
        CurrentAddonSeenBlueprints.Clear();
    }

    public static string GetSnippetBodyOnDemand(CodeSnippet s) {
        if (s == null) return "";
        if (!string.IsNullOrEmpty(s.CodeBody)) return s.CodeBody;
        if (!string.IsNullOrEmpty(s.FullFilePath) && File.Exists(s.FullFilePath)) {
            try {
                StringBuilder sb = new StringBuilder();
                using (StreamReader sr = new StreamReader(s.FullFilePath, Encoding.UTF8)) {
                    string ln;
                    int curLine = 0;
                    while ((ln = sr.ReadLine()) != null) {
                        curLine++;
                        if (curLine >= s.StartLine && curLine <= s.EndLine) {
                            sb.AppendLine(ln);
                        }
                        if (curLine > s.EndLine) break;
                    }
                }
                string loaded = sb.ToString().TrimEnd();
                if (!string.IsNullOrEmpty(loaded)) return loaded;
            } catch {}
        }
        return "-- [Parent Source File Not Found at: " + s.FullFilePath + "]";
    }

    public static string GetSnippetPreviewLinesOnDemand(string fullFilePath, int startLine, int endLine, int maxPreviewLines) {
        if (string.IsNullOrEmpty(fullFilePath) || !File.Exists(fullFilePath)) return "    -- [Source file unavailable]";
        try {
            StringBuilder sb = new StringBuilder();
            int targetEnd = Math.Min(endLine, startLine + maxPreviewLines - 1);
            using (StreamReader sr = new StreamReader(fullFilePath, Encoding.UTF8)) {
                string ln;
                int curLine = 0;
                while ((ln = sr.ReadLine()) != null) {
                    curLine++;
                    if (curLine >= startLine && curLine <= targetEnd) {
                        sb.AppendLine("      " + ln);
                    }
                    if (curLine > targetEnd) break;
                }
            }
            if (endLine > targetEnd) {
                sb.AppendLine("      -- ... [" + (endLine - targetEnd) + " more lines in block]");
            }
            return sb.ToString().TrimEnd();
        } catch {
            return "    -- [Error reading preview]";
        }
    }

    public static string MapExtensionToLanguage(string ext) {
        if (ext == ".lua") return "Lua";
        if (ext == ".xml") return "XML";
        if (ext == ".toc") return "TOC";
        if (ext == ".cpp") return "C++";
        if (ext == ".c") return "C";
        if (ext == ".h") return "C/C++ Header";
        if (ext == ".hpp") return "C++ Header";
        if (ext == ".cs") return "C#";
        if (ext == ".py") return "Python";
        if (ext == ".sql") return "SQL";
        if (ext == ".json") return "JSON";
        if (ext == ".csv") return "CSV";
        if (ext == ".js") return "JavaScript";
        if (ext == ".ts") return "TypeScript";
        if (ext == ".ps1") return "PowerShell";
        if (ext == ".sh") return "Shell";
        if (ext == ".bat") return "Batch";
        return "Text";
    }
}
