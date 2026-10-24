// ============================================================================
// DECONSTRUCTION GOD STUDIO v14.3 - MODULAR NODE SYSTEM
// NODE INDEX  : [25] OF [35]
// FILE NAME   : Node_25_OllamaMicroLLM.cs
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
    // v14.1 NATIVE OLLAMA CLIENT WITH WARM-UP PING (NO MORE COLD-START TIMEOUT)
    // ========================================================================
    public static List<string> DiscoverLocalOllamaModels(string baseUrl) {
        List<string> models = new List<string>();
        try {
            string url = baseUrl.TrimEnd('/') + "/api/tags";
            HttpWebRequest req = (HttpWebRequest)WebRequest.Create(url);
            req.Method = "GET";
            req.Timeout = 2500;
            using (HttpWebResponse resp = (HttpWebResponse)req.GetResponse())
            using (StreamReader sr = new StreamReader(resp.GetResponseStream(), Encoding.UTF8)) {
                string json = sr.ReadToEnd();
                MatchCollection mc = rxOllamaModelTag.Matches(json);
                foreach (Match m in mc) {
                    string name = m.Groups[1].Value;
                    if (!models.Contains(name)) models.Add(name);
                }
            }
        } catch {}

        if (models.Count == 0) {
            models.Add("codegemma:7b");
            models.Add("cas/phi-3-mini-4k-instruct-llamafied-4q:latest");
            models.Add("taozhiyuai/llama-3-8b-ultra-instruct:q4_k_m");
        }
        return models;
    }

    private static string EscapeJsonString(string s) {
        if (string.IsNullOrEmpty(s)) return "";
        return s.Replace("\\", "\\\\").Replace("\"", "\\\"").Replace("\r", "\\r").Replace("\n", "\\n").Replace("\t", "\\t");
    }

    private static string UnescapeJsonString(string s) {
        if (string.IsNullOrEmpty(s)) return "";
        return s.Replace("\\n", "\r\n").Replace("\\r", "").Replace("\\t", "\t").Replace("\\\"", "\"").Replace("\\\\", "\\");
    }

    public static void WarmUpOllamaModelInRam(string baseUrl, string modelName, Action<string> progressCallback) {
        try {
            if (progressCallback != null) progressCallback("Warming up [" + modelName + "] in 64GB RAM (prevents cold-start timeout)...");
            string url = baseUrl.TrimEnd('/') + "/api/generate";
            HttpWebRequest req = (HttpWebRequest)WebRequest.Create(url);
            req.Method = "POST";
            req.ContentType = "application/json";
            req.Timeout = 180000;
            string payload = string.Format(
                "{{\"model\":\"{0}\",\"prompt\":\"hi\",\"stream\":false,\"keep_alive\":\"30m\",\"options\":{{\"num_ctx\":512,\"num_predict\":1}}}}",
                EscapeJsonString(modelName)
            );
            byte[] bytes = Encoding.UTF8.GetBytes(payload);
            req.ContentLength = bytes.Length;
            using (Stream reqStream = req.GetRequestStream()) {
                reqStream.Write(bytes, 0, bytes.Length);
            }
            using (HttpWebResponse resp = (HttpWebResponse)req.GetResponse()) {}
        } catch {}
    }

    public static string ExecuteStatelessMicroLlmPrompt(string baseUrl, string modelName, string microPrompt, int maxPredictTokens) {
        try {
            string url = baseUrl.TrimEnd('/') + "/api/generate";
            HttpWebRequest req = (HttpWebRequest)WebRequest.Create(url);
            req.Method = "POST";
            req.ContentType = "application/json";
            req.Timeout = 180000;

            string payload = string.Format(
                "{{\"model\":\"{0}\",\"prompt\":\"{1}\",\"stream\":false,\"keep_alive\":\"30m\",\"options\":{{\"num_ctx\":2048,\"num_predict\":{2},\"temperature\":0.3}}}}",
                EscapeJsonString(modelName),
                EscapeJsonString(microPrompt),
                maxPredictTokens
            );

            byte[] bytes = Encoding.UTF8.GetBytes(payload);
            req.ContentLength = bytes.Length;
            using (Stream reqStream = req.GetRequestStream()) {
                reqStream.Write(bytes, 0, bytes.Length);
            }

            using (HttpWebResponse resp = (HttpWebResponse)req.GetResponse())
            using (StreamReader sr = new StreamReader(resp.GetResponseStream(), Encoding.UTF8)) {
                string json = sr.ReadToEnd();
                Match m = rxOllamaResponse.Match(json);
                if (m.Success) {
                    return UnescapeJsonString(m.Groups[1].Value).Trim();
                }
            }
        } catch (Exception ex) {
            return "-- [Local LLM Micro-Task Notice: " + ex.Message + "]";
        }
        return "-- [Local LLM returned empty response]";
    }

    // ========================================================================
    // v14.1 STATELESS MICRO-LLM: INVENTS THE ADDON NAME, PITCH & GLUE CODE
    // Cleanly replaces LlmMicroSynthesisNotes (never stacks duplicate blocks!)
    // ========================================================================
    public static string RunChainedMicroWindowLlmSynthesis(string baseUrl, string modelName, AddonForgeBlueprint bp, Action<string> progressCallback) {
        if (bp == null) return "-- Select a Discovered Cluster in the left table first!";

        WarmUpOllamaModelInRam(baseUrl, modelName, progressCallback);

        string trigPreview = GetSnippetPreviewLinesOnDemand(bp.TriggerBlock.FullFilePath, bp.TriggerBlock.StartLine, bp.TriggerBlock.EndLine, 12);
        string prodPreview = GetSnippetPreviewLinesOnDemand(bp.ProducerBlock.FullFilePath, bp.ProducerBlock.StartLine, bp.ProducerBlock.EndLine, 12);
        string poolPreview = GetSnippetPreviewLinesOnDemand(bp.EnginePoolBlock.FullFilePath, bp.EnginePoolBlock.StartLine, bp.EnginePoolBlock.EndLine, 12);
        string uiPreview   = GetSnippetPreviewLinesOnDemand(bp.UiRenderBlock.FullFilePath, bp.UiRenderBlock.StartLine, bp.UiRenderBlock.EndLine, 12);

        // MICRO-TASK 1 (Fresh 2K Window): Invent Addon Concept Title & Pitch from the 4 real functions!
        if (progressCallback != null) progressCallback("LLM Micro-Task [1/3] (Fresh 2K Window): Inventing Addon Concept & Pitch from the 4 organs...");
        string promptConcept =
            "You are a World of Warcraft Addon Architect. Look at these 4 functions harvested from different addons sharing API family [" + bp.SharedApiFamily + "]:\n" +
            "1. Trigger (" + bp.TriggerBlock.AddonName + "): " + bp.TriggerBlock.Signature + "\n" +
            "2. Producer (" + bp.ProducerBlock.AddonName + "): " + bp.ProducerBlock.Signature + "\n" +
            "3. Engine/Pool (" + bp.EnginePoolBlock.AddonName + "): " + bp.EnginePoolBlock.Signature + "\n" +
            "4. UI/Tooltip (" + bp.UiRenderBlock.AddonName + "): " + bp.UiRenderBlock.Signature + "\n" +
            "Invent a creative, specific new WoW Addon concept that fuses these 4 functions. Reply in exactly 3 lines:\n" +
            "ADDON_NAME: < catchy 3-4 word addon name >\n" +
            "PITCH: < 1 sentence explaining what this new addon does >\n" +
            "SYNERGY_HOW: < 1 sentence explaining how the data flows from 1 to 4 >";
        string conceptOut = ExecuteStatelessMicroLlmPrompt(baseUrl, modelName, promptConcept, 160);

        // Parse LLM's invented ADDON_NAME so the left table updates with the LLM's own invention!
        string[] cLines = conceptOut.Split(new char[] { '\r', '\n' }, StringSplitOptions.RemoveEmptyEntries);
        for (int i = 0; i < cLines.Length; i++) {
            string cl = cLines[i].Trim();
            if (cl.StartsWith("ADDON_NAME:", StringComparison.OrdinalIgnoreCase)) {
                string newName = cl.Substring(11).Trim().Trim('*', '"', '\'');
                if (newName.Length > 3) bp.AddonTitle = "[LLM] " + newName;
            } else if (cl.StartsWith("PITCH:", StringComparison.OrdinalIgnoreCase)) {
                bp.ExecutivePitch = cl.Substring(6).Trim();
            }
        }

        // MICRO-TASK 2 (Window Wiped & Refreshed!): Wire Organ 1 (Trigger) -> Organ 2 (Producer)
        if (progressCallback != null) progressCallback("LLM Micro-Task [2/3] (Window Refreshed): Writing Lua Bridge for Organ 1 -> Organ 2...");
        string prompt1 =
            "Write ONLY a 10-line World of Warcraft Lua function `Forge_Step1_CollectData(event, ...)` that calls Organ 1 and passes data into Organ 2.\n" +
            "Organ 1 (" + bp.TriggerBlock.AddonName + "): " + bp.TriggerBlock.Signature + "\n" + trigPreview + "\n" +
            "Organ 2 (" + bp.ProducerBlock.AddonName + "): " + bp.ProducerBlock.Signature + "\n" + prodPreview + "\n" +
            "Output ONLY valid WoW Lua code.";
        string step1Out = ExecuteStatelessMicroLlmPrompt(baseUrl, modelName, prompt1, 220);

        // MICRO-TASK 3 (Window Wiped & Refreshed!): Wire Organ 3 (Pool/Throttle) -> Organ 4 (UI/Tooltip)
        if (progressCallback != null) progressCallback("LLM Micro-Task [3/3] (Window Refreshed): Writing Lua Bridge for Organ 3 -> Organ 4...");
        string prompt2 =
            "Write ONLY a 12-line World of Warcraft Lua function `Forge_Step2_RenderUI(dataset)` that uses Organ 3 and renders via Organ 4.\n" +
            "Organ 3 (" + bp.EnginePoolBlock.AddonName + "): " + bp.EnginePoolBlock.Signature + "\n" + poolPreview + "\n" +
            "Organ 4 (" + bp.UiRenderBlock.AddonName + "): " + bp.UiRenderBlock.Signature + "\n" + uiPreview + "\n" +
            "Output ONLY valid WoW Lua code.";
        string step2Out = ExecuteStatelessMicroLlmPrompt(baseUrl, modelName, prompt2, 240);

        StringBuilder sbLlm = new StringBuilder();
        sbLlm.AppendLine("================================================================================");
        sbLlm.AppendLine("[LOCAL LLM AUTONOMOUS INVENTION & STATELESS MICRO-WINDOW SYNTHESIS]");
        sbLlm.AppendLine("Model: " + modelName + "  |  Context Strategy: 3 Fresh 2,048-Token Windows");
        sbLlm.AppendLine("================================================================================");
        sbLlm.AppendLine(conceptOut);
        sbLlm.AppendLine("--------------------------------------------------------------------------------");
        sbLlm.AppendLine("-- [MICRO-TASK 2: TRIGGER -> DATA PRODUCER LUA BRIDGE]");
        sbLlm.AppendLine(step1Out);
        sbLlm.AppendLine("");
        sbLlm.AppendLine("-- [MICRO-TASK 3: ASYNC POOL -> UI RENDERER LUA BRIDGE]");
        sbLlm.AppendLine(step2Out);
        sbLlm.AppendLine("================================================================================");
        sbLlm.AppendLine("");

        // Clean overwrite of LlmMicroSynthesisNotes + BaseBlueprintReport (never stacks duplicates!)
        bp.LlmMicroSynthesisNotes = sbLlm.ToString();
        bp.FullBlueprintReport = bp.LlmMicroSynthesisNotes + bp.BaseBlueprintReport;
        return bp.FullBlueprintReport;
    }

    // ========================================================================

    public static string RunSelfReflectionAndEnvironmentAudit(string studioDir, string altVaultDir, string ollamaUrl, string ollamaModel, bool useLlm) {
        StringBuilder sb = new StringBuilder();
        sb.AppendLine("================================================================================");
        sb.AppendLine("DECONSTRUCTION GOD STUDIO v14.1 - SELF-REFLECTION & ENVIRONMENT UPGRADE AUDIT");
        sb.AppendLine("Generated UTC: " + DateTime.UtcNow.ToString("yyyy-MM-dd HH:mm:ss"));
        sb.AppendLine("================================================================================");
        sb.AppendLine("");

        sb.AppendLine("### PART 1: SELF-REFLECTION ON DECONSTRUCTION GOD STUDIO ENGINE FILES");
        sb.AppendLine("--------------------------------------------------------------------------------");
        string[] studioFiles = Directory.GetFiles(studioDir, "*.*", SearchOption.TopDirectoryOnly);
        int studioLines = 0;
        int studioMethods = 0;
        for (int i = 0; i < studioFiles.Length; i++) {
            string ext = Path.GetExtension(studioFiles[i]).ToLowerInvariant();
            if (ext == ".cs" || ext == ".ps1") {
                string[] lns = File.ReadAllLines(studioFiles[i]);
                studioLines += lns.Length;
                for (int l = 0; l < lns.Length; l++) {
                    if (lns[l].Contains("public static ") || lns[l].Contains("private static ") || lns[l].Contains("private void ")) studioMethods++;
                }
                sb.AppendLine("  * Audited Self File: " + Path.GetFileName(studioFiles[i]) + " (" + lns.Length + " lines)");
            }
        }
        sb.AppendLine("  * Total Self Engine Footprint: " + studioLines + " lines across " + studioMethods + " C#/WinForms methods.");

        string bpPath = Path.Combine(DataRipperEngine.ResolveTroughDir(studioDir), "Trough_Blueprints.tsv");
        Dictionary<string, int> apiFreq = new Dictionary<string, int>();
        if (File.Exists(bpPath)) {
            using (StreamReader sr = new StreamReader(bpPath, Encoding.UTF8)) {
                string ln;
                while ((ln = sr.ReadLine()) != null) {
                    string[] c = ln.Split('\t');
                    if (c.Length >= 5 && c[0] == "Modern_API") {
                        string ns = c[4].Split('.')[0];
                        if (!apiFreq.ContainsKey(ns)) apiFreq[ns] = 0;
                        apiFreq[ns]++;
                    }
                }
            }
        }
        List<KeyValuePair<string, int>> topApis = new List<KeyValuePair<string, int>>(apiFreq);
        topApis.Sort((a, b) => b.Value.CompareTo(a.Value));
        sb.AppendLine("  * Top WoW API Namespaces Discovered Across Your 648 Addons:");
        for (int i = 0; i < Math.Min(10, topApis.Count); i++) {
            sb.AppendLine(string.Format("      [{0}] {1,-28} : {2,6} call sites harvested", (i + 1), topApis[i].Key, topApis[i].Value));
        }
        sb.AppendLine("");

        sb.AppendLine("### PART 2: ALTVAULT CODEBASE DISSECTION & 648-ADDON UPGRADE MATCHES");
        sb.AppendLine("--------------------------------------------------------------------------------");
        if (!string.IsNullOrEmpty(altVaultDir) && Directory.Exists(altVaultDir)) {
            string[] altLuaFiles = Directory.GetFiles(altVaultDir, "*.lua", SearchOption.AllDirectories);
            sb.AppendLine("  * Target AltVault Directory: " + altVaultDir + " (" + altLuaFiles.Length + " Lua files)");

            for (int f = 0; f < altLuaFiles.Length; f++) {
                string fName = Path.GetFileName(altLuaFiles[f]);
                if (fName.StartsWith("DB_MasterHoldingTank", StringComparison.OrdinalIgnoreCase)) continue;
                string[] lines = File.ReadAllLines(altLuaFiles[f]);
                int fnCount = 0;
                bool hasCoroutine = false;
                bool hasFramePool = false;
                bool hasPolyfill  = false;
                for (int l = 0; l < lines.Length; l++) {
                    if (lines[l].Contains("function")) fnCount++;
                    if (lines[l].Contains("coroutine.")) hasCoroutine = true;
                    if (lines[l].Contains("CreateFramePool")) hasFramePool = true;
                    if (lines[l].Contains("C_Container") && lines[l].Contains("GetContainerItemInfo")) hasPolyfill = true;
                }
                sb.AppendLine(string.Format(
                    "  * File: {0,-32} | Lines: {1,5} | Functions: {2,3} | FramePool:{3} | Coroutine:{4} | Polyfill:{5}",
                    fName, lines.Length, fnCount, (hasFramePool ? "YES" : "NO "), (hasCoroutine ? "YES" : "NO "), (hasPolyfill ? "YES" : "NO ")
                ));
            }

            sb.AppendLine("");
            sb.AppendLine("### PART 3: RECOMMENDED HIGH-SYNERGY BRICKS TO INJECT INTO ALTVAULT & STUDIO");
            sb.AppendLine("--------------------------------------------------------------------------------");
            if (DistilledConcepts.Count == 0) {
                RunThreePassDeepCrossReferenceScan(studioDir, null);
            }
            int shown = 0;
            for (int i = 0; i < DistilledConcepts.Count && shown < 5; i++) {
                AtomicConceptEntry ace = DistilledConcepts[i];
                if (ace.CreativeLegoTag == "Lego_Frame_And_Object_Pool" || ace.CreativeLegoTag == "Lego_Async_Throttle_Engine" || ace.CreativeLegoTag == "Lego_Polyfill_And_Compat_Shim" || ace.CreativeLegoTag == "Lego_UI_Grid_Matrix") {
                    shown++;
                    sb.AppendLine(string.Format(
                        "  [{0}] UPGRADE BRICK: {1} -> {2} ({3} | Versatility: {4}/100)",
                        shown, ace.AddonName, ace.Signature, ace.CreativeLegoTag, ace.VersatilityScore
                    ));
                    sb.AppendLine("      File: " + ace.RelativePath + ":" + ace.StartLine + "-" + ace.EndLine + " | Returns: " + ace.ReturnVars);
                    sb.AppendLine(GetSnippetPreviewLinesOnDemand(ace.FullFilePath, ace.StartLine, ace.EndLine, 10));
                    sb.AppendLine("  ------------------------------------------------------------------------------");
                }
            }
        } else {
            sb.AppendLine("  * AltVault folder not found at: " + altVaultDir);
        }

        if (useLlm && !string.IsNullOrEmpty(ollamaModel)) {
            WarmUpOllamaModelInRam(ollamaUrl, ollamaModel, null);
            sb.AppendLine("");
            sb.AppendLine("### PART 4: LOCAL LLM SELF-REFLECTION VERDICT (" + ollamaModel + ")");
            sb.AppendLine("--------------------------------------------------------------------------------");
            string prompt =
                "You are auditing our C# DeconstructionGod_Studio (" + studioLines + " lines) and WoW Lua addon AltVault. " +
                "We have 648 addons harvested with 85,171 Creative Bricks. Give 3 specific, high-impact code improvements we should make next to AltVault and Studio to maximize speed and cross-expansion compatibility.";
            string llmVerdict = ExecuteStatelessMicroLlmPrompt(ollamaUrl, ollamaModel, prompt, 250);
            sb.AppendLine(llmVerdict);
        }

        return sb.ToString();
    }
}
