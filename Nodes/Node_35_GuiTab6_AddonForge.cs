// ============================================================================
// DECONSTRUCTION GOD STUDIO v14.3 - MODULAR NODE SYSTEM
// NODE INDEX  : [35] OF [35]
// FILE NAME   : Node_35_GuiTab6_AddonForge.cs
// PARTIAL OF  : StudioMainForm
// ============================================================================
using System;
using System.IO;
using System.Net;
using System.Text;
using System.Drawing;
using System.Windows.Forms;
using System.Text.RegularExpressions;
using System.Collections.Generic;

public partial class StudioMainForm : Form {
    // ========================================================================
    // SECTION 10.0: VIEW [6] EMERGENT ADDON FORGE, MICRO-LLM & SELF-AUDITOR
    // ========================================================================
    private void BuildView6AddonForge() {
        view6AddonForge = new Panel();
        view6AddonForge.Dock = DockStyle.Fill;
        view6AddonForge.Visible = false;

        TableLayoutPanel layout = new TableLayoutPanel() { Dock = DockStyle.Fill, RowCount = 2 };
        layout.RowStyles.Add(new RowStyle(SizeType.Absolute, 46F));
        layout.RowStyles.Add(new RowStyle(SizeType.Percent, 100F));

        FlowLayoutPanel topBar = new FlowLayoutPanel() { Dock = DockStyle.Fill, BackColor = bgPanel, WrapContents = false, Padding = new Padding(6, 5, 6, 0) };

        Label lblUrl = new Label() { Text = "Ollama:", AutoSize = true, Font = fontBold, ForeColor = fgCyan, Padding = new Padding(0, 6, 2, 0) };
        txtOllamaUrl = new TextBox() { Width = 135, Text = "http://localhost:11434", BackColor = bgDark, ForeColor = fgGreen, Font = fontMono };

        cmbOllamaModel = new ComboBox() { Width = 195, DropDownStyle = ComboBoxStyle.DropDownList };
        cmbOllamaModel.Items.Add("codegemma:7b");
        cmbOllamaModel.Items.Add("cas/phi-3-mini-4k-instruct-llamafied-4q:latest");
        cmbOllamaModel.Items.Add("taozhiyuai/llama-3-8b-ultra-instruct:q4_k_m");
        cmbOllamaModel.SelectedIndex = 0;

        Button btnRun3Pass = MakeBtn("1. Discover Next 8 Clusters", bgAccentGold, 195, 30);
        btnRun3Pass.Click += (s, e) => RunDeepSynergyAgentNow();

        Button btnRunLlm = MakeBtn("2. Micro-LLM Invent & Wire", bgAccentPurp, 195, 30);
        btnRunLlm.Click += (s, e) => RunStatelessLlmOnSelectedBlueprint();

        Button btnSelfAudit = MakeBtn("3. Self-Audit Studio & AltVault", bgAccentBlue, 205, 30);
        btnSelfAudit.Click += (s, e) => RunSelfReflectionAuditNow();

        Button btnCopyForge = MakeBtn("4. Copy Output", bgAccentGrn, 130, 30);
        btnCopyForge.Click += (s, e) => {
            if (txtForgeBlueprintView.Text.Length > 0) {
                Clipboard.SetText(txtForgeBlueprintView.Text);
                hudBar.OverlayText = "COPIED FORGE OUTPUT TO CLIPBOARD -- DROP IT INTO CHAT!";
                MessageBox.Show("Copied complete output from the Forge Viewer to Clipboard!", "Copied to Clipboard", MessageBoxButtons.OK, MessageBoxIcon.Information);
            }
        };

        Button btnClearView = MakeBtn("Clear View", bgHeader, 95, 30);
        btnClearView.Click += (s, e) => {
            txtForgeBlueprintView.Clear();
            hudBar.OverlayText = "CLEARED FORGE VIEWER WINDOW.";
        };

        Button btnResetSeeds = MakeBtn("Reset Seeds", bgAccentRed, 100, 30);
        btnResetSeeds.Click += (s, e) => ResetAllForgeSeeds();

        Button btnScoutDonors = MakeBtn("Scout Donors", bgAccentGold, 110, 30);
        btnScoutDonors.Click += (s, e) => RunDonorAddonScoutNow();

        Button btnMatrixPois = MakeBtn("Matrix POIs (150)", Color.FromArgb(180, 45, 90), 140, 30);
        btnMatrixPois.Click += (s, e) => LoadForeverMatrixPoisNow();

        Button btnExportProto = MakeBtn("Export .toc", bgHeader, 95, 30);
        btnExportProto.Click += (s, e) => ExportSelectedForgeAddon();

        topBar.Controls.AddRange(new Control[] { lblUrl, txtOllamaUrl, cmbOllamaModel, btnRun3Pass, btnRunLlm, btnSelfAudit, btnScoutDonors, btnMatrixPois, btnCopyForge, btnClearView, btnResetSeeds, btnExportProto });
        layout.Controls.Add(topBar, 0, 0);

        SplitContainer split = new SplitContainer() { Dock = DockStyle.Fill, Orientation = Orientation.Vertical, SplitterDistance = 620, SplitterWidth = 6, BackColor = Color.FromArgb(55, 65, 81) };

        TableLayoutPanel leftPane = new TableLayoutPanel() { Dock = DockStyle.Fill, RowCount = 2 };
        leftPane.RowStyles.Add(new RowStyle(SizeType.Percent, 100F));
        leftPane.RowStyles.Add(new RowStyle(SizeType.Absolute, 28F));

        gridForgeCatalog = new DataGridView() { Dock = DockStyle.Fill };
        StyleGrid(gridForgeCatalog, false);
        gridForgeCatalog.Columns.Add("ForgeID", "#"); gridForgeCatalog.Columns[0].Width = 38;
        gridForgeCatalog.Columns.Add("Synergy", "Syn%"); gridForgeCatalog.Columns[1].Width = 52;
        gridForgeCatalog.Columns.Add("Title", "Emergent Cluster / LLM-Invented Name"); gridForgeCatalog.Columns[2].Width = 245;
        gridForgeCatalog.Columns.Add("ApiFam", "Shared API Family"); gridForgeCatalog.Columns[3].Width = 145;
        gridForgeCatalog.Columns.Add("Parents", "Multi-Addon Parent Lineage Mix"); gridForgeCatalog.Columns[4].Width = 240;
        gridForgeCatalog.SelectionChanged += (s, e) => { if (!isUpdatingGrids) InspectSelectedForgeBlueprint(); };

        lblForgeCount = new Label() { Dock = DockStyle.Fill, BackColor = bgHeader, ForeColor = fgGold, Font = fontBold, TextAlign = ContentAlignment.MiddleLeft, Padding = new Padding(6, 0, 0, 0), Text = "Emergent Clusters: 0 -- Click '1. Discover Next 8 Clusters' to generate fresh combinations!" };
        leftPane.Controls.Add(gridForgeCatalog, 0, 0);
        leftPane.Controls.Add(lblForgeCount, 0, 1);
        split.Panel1.Controls.Add(leftPane);

        txtForgeBlueprintView = new TextBox() { Dock = DockStyle.Fill, Multiline = true, ReadOnly = true, ScrollBars = ScrollBars.Both, WordWrap = false, BackColor = Color.FromArgb(9, 12, 16), ForeColor = fgGreen, Font = fontMono };
        split.Panel2.Controls.Add(txtForgeBlueprintView);

        layout.Controls.Add(split, 0, 1);
        view6AddonForge.Controls.Add(layout);
    }

    private void RefreshOllamaModelsDropdown() {
        try {
            List<string> mods = CodeHarvesterEngine.DiscoverLocalOllamaModels(txtOllamaUrl.Text.Trim());
            if (mods.Count > 0) {
                cmbOllamaModel.Items.Clear();
                int prefIdx = 0;
                for (int i = 0; i < mods.Count; i++) {
                    cmbOllamaModel.Items.Add(mods[i]);
                    if (mods[i].ToLowerInvariant().Contains("codegemma")) prefIdx = i;
                }
                cmbOllamaModel.SelectedIndex = prefIdx;
            }
        } catch {}
    }

    private void ResetAllForgeSeeds() {
        CodeHarvesterEngine.ClearForgeMemoryOnly();
        gridForgeCatalog.Rows.Clear();
        txtForgeBlueprintView.Clear();
        lblForgeCount.Text = "Reset Complete! Click '1. Discover Next 8 Clusters' to start Generation #1.";
        hudBar.OverlayText = "RESET ALL VISITED FORGE SEEDS & CLEARED VIEWER.";
    }

    private void RunDeepSynergyAgentNow() {
        txtForgeBlueprintView.Clear();
        hudBar.IsRunning = true;
        hudBar.Value = 35;
        hudBar.OverlayText = "DISCOVERING NEXT 8 EMERGENT MULTI-ADDON CLUSTERS BY REAL API OVERLAP...";
        Application.DoEvents();

        CodeHarvesterEngine.RunThreePassDeepCrossReferenceScan(studioDir, (statusMsg) => {
            hudBar.OverlayText = statusMsg;
            EnqueueLog(statusMsg);
            Application.DoEvents();
        });

        hudBar.IsRunning = false;
        hudBar.Value = 100;
        PopulateForgeCatalogGrid(0);
    }

    private void RunStatelessLlmOnSelectedBlueprint() {
        if (gridForgeCatalog.SelectedRows.Count == 0) {
            MessageBox.Show("Click '1. Discover Next 8 Clusters' and select a row in the left table first!", "No Cluster Selected", MessageBoxButtons.OK, MessageBoxIcon.Information);
            return;
        }
        int idx = gridForgeCatalog.SelectedRows[0].Index;
        if (idx < 0 || idx >= CodeHarvesterEngine.ForgedAddonIdeas.Count) return;

        AddonForgeBlueprint bp = CodeHarvesterEngine.ForgedAddonIdeas[idx];
        string url = txtOllamaUrl.Text.Trim();
        string model = cmbOllamaModel.SelectedItem != null ? cmbOllamaModel.SelectedItem.ToString() : "codegemma:7b";

        txtForgeBlueprintView.Text = "-- Warming up [" + model + "] in 64GB RAM and running 3 Stateless 2K-Token Micro-Tasks...\r\n-- Please wait ~10-25 seconds...";
        hudBar.IsRunning = true;
        hudBar.Value = 50;
        hudBar.OverlayText = "WARMING UP [" + model + "] & RUNNING 3 STATELESS 2K-TOKEN MICRO-TASKS...";
        Application.DoEvents();

        string updatedReport = CodeHarvesterEngine.RunChainedMicroWindowLlmSynthesis(url, model, bp, (stepMsg) => {
            hudBar.OverlayText = stepMsg;
            EnqueueLog(stepMsg);
            Application.DoEvents();
        });

        hudBar.IsRunning = false;
        hudBar.Value = 100;
        hudBar.OverlayText = "LLM INVENTED '" + bp.AddonTitle + "' & WROTE LUA ADAPTER BRIDGES!";
        PopulateForgeCatalogGrid(idx);
        txtForgeBlueprintView.Text = updatedReport;
    }

    private void RunSelfReflectionAuditNow() {
        string url = txtOllamaUrl.Text.Trim();
        string model = cmbOllamaModel.SelectedItem != null ? cmbOllamaModel.SelectedItem.ToString() : "codegemma:7b";

        txtForgeBlueprintView.Text = "-- Running Self-Reflection Audit on DeconstructionGod_Studio (.cs/.ps1) & AltVault (.lua)...\r\n-- Please wait...";
        hudBar.IsRunning = true;
        hudBar.Value = 60;
        hudBar.OverlayText = "AUDITING STUDIO C#/PS1 & ALTVAULT LUA AGAINST 648-ADDON KNOWLEDGE GRAPH...";
        Application.DoEvents();

        string auditReport = CodeHarvesterEngine.RunSelfReflectionAndEnvironmentAudit(
            studioDir,
            txtAltVaultDir.Text.Trim(),
            url,
            model,
            true
        );

        hudBar.IsRunning = false;
        hudBar.Value = 100;
        hudBar.OverlayText = "SELF-REFLECTION & ALTVAULT UPGRADE AUDIT COMPLETE -- CLICK '4. Copy Output'!";
        txtForgeBlueprintView.Text = auditReport;
        EnqueueLog("Completed Self-Reflection & Environment Upgrade Audit on Studio and AltVault.");
    }


    private void LoadForeverMatrixPoisNow() {
        string filterKw = (txtGlobalSearch != null) ? txtGlobalSearch.Text.Trim().ToLowerInvariant() : "";
        string troughDir = DataRipperEngine.ResolveTroughDir(studioDir);
        string poiPath = Path.Combine(troughDir, "Trough_PointsOfInterest.tsv");
        if (!File.Exists(poiPath)) {
            MessageBox.Show("Trough_PointsOfInterest.tsv not found at: " + poiPath, "Missing POI Table", MessageBoxButtons.OK, MessageBoxIcon.Warning);
            return;
        }

        CodeHarvesterEngine.ForgedAddonIdeas.Clear();
        string[] lines = File.ReadAllLines(poiPath, Encoding.UTF8);
        int loadedCount = 0;
        for (int i = 1; i < lines.Length; i++) {
            string ln = lines[i];
            if (string.IsNullOrWhiteSpace(ln)) continue;
            string[] cols = ln.Split('\t');
            if (cols.Length < 8) continue;

            if (filterKw.Length > 0 && !ln.ToLowerInvariant().Contains(filterKw)) continue;

            string poiId = cols[0];
            string pillar = cols[1];
            string priority = cols[2];
            string title = cols[3];
            string sourceTarget = cols[4];
            string scale = cols[5];
            string mechanism = cols[6];
            string strategy = cols[7];

            AddonForgeBlueprint bp = new AddonForgeBlueprint();
            bp.ForgeID = loadedCount + 1;
            bp.TotalSynergyScore = priority.Contains("CRITICAL") ? 100 : (priority.Contains("EXTREME") ? 98 : 95);
            bp.AddonTitle = "[" + poiId + "] " + title;
            bp.SharedApiFamily = pillar;
            bp.ParentLineageMix = sourceTarget + " (" + scale + ")";

            StringBuilder sb = new StringBuilder();
            sb.AppendLine("================================================================================");
            sb.AppendLine("FOREVER 1.60.1 MATRIX POINT OF INTEREST: " + poiId + " (" + priority + ")");
            sb.AppendLine("================================================================================");
            sb.AppendLine("TITLE         : " + title);
            sb.AppendLine("PILLAR        : " + pillar);
            sb.AppendLine("SOURCE TARGET : " + sourceTarget);
            sb.AppendLine("DATA SCALE    : " + scale);
            sb.AppendLine("--------------------------------------------------------------------------------");
            sb.AppendLine("[1] ENGINE MECHANISM & DATA ADVANTAGE:");
            sb.AppendLine("    " + mechanism);
            sb.AppendLine("");
            sb.AppendLine("[2] ADDON IMPLEMENTATION STRATEGY:");
            sb.AppendLine("    " + strategy);
            sb.AppendLine("================================================================================");
            sb.AppendLine("-- Tip: Select this row and click '2. Micro-LLM Invent & Wire' to synthesize");
            sb.AppendLine("--      a custom Lua module around this exact Point of Interest!");
            bp.FullBlueprintReport = sb.ToString();

            CodeHarvesterEngine.ForgedAddonIdeas.Add(bp);
            loadedCount++;
        }

        PopulateForgeCatalogGrid(0);
        lblForgeCount.Text = string.Format("Loaded {0} Forever 1.60.1 Matrix Points of Interest from Trough_PointsOfInterest.tsv!", loadedCount);
        hudBar.OverlayText = string.Format("LOADED {0} FOREVER 1.60.1 POINTS OF INTEREST INTO ADDON FORGE!", loadedCount);
    }
    private void RunDonorAddonScoutNow() {
        string filterKw = txtGlobalSearch != null ? txtGlobalSearch.Text.Trim() : "";
        txtForgeBlueprintView.Text = "-- Scouting Prime Donor Addons (CurseForge / Wago / GitHub + 648-Addon Vault Gap Analysis)...\r\n-- Please wait...";
        hudBar.IsRunning = true;
        hudBar.Value = 65;
        hudBar.OverlayText = "SCOUTING CURSEFORGE & LIVE GITHUB ADDONS AGAINST YOUR 648-ADDON VAULT...";
        Application.DoEvents();

        string scoutReport = CodeHarvesterEngine.ScoutPrimeDonorAddonsReport(studioDir, filterKw);

        hudBar.IsRunning = false;
        hudBar.Value = 100;
        hudBar.OverlayText = "DONOR ADDON SCOUT COMPLETE -- MISSING TARGETS & HARVESTED ORGANS RANKED!";
        txtForgeBlueprintView.Text = scoutReport;
        EnqueueLog("Completed CurseForge/GitHub Prime Donor Addon Scout against 648-Addon Vault.");
    }

    private void PopulateForgeCatalogGrid(int selectRowIndex) {
        bool prevLock = isUpdatingGrids;
        isUpdatingGrids = true;
        try {
            gridForgeCatalog.Rows.Clear();
            for (int i = 0; i < CodeHarvesterEngine.ForgedAddonIdeas.Count; i++) {
                AddonForgeBlueprint bp = CodeHarvesterEngine.ForgedAddonIdeas[i];
                gridForgeCatalog.Rows.Add(
                    bp.ForgeID,
                    bp.TotalSynergyScore + "%",
                    bp.AddonTitle,
                    bp.SharedApiFamily,
                    bp.ParentLineageMix
                );
            }
            int remaining = Math.Max(0, CodeHarvesterEngine.DistilledConcepts.Count - CodeHarvesterEngine.UsedSeedSnippetIDs.Count);
            lblForgeCount.Text = string.Format(
                "Generation #{0} | Unvisited Seeds Left: {1}/{2} (Click '1. Discover Next 8 Clusters' for 8 brand-new ideas!)",
                CodeHarvesterEngine.DiscoveryGenerationCounter,
                remaining,
                CodeHarvesterEngine.DistilledConcepts.Count
            );
        } finally {
            isUpdatingGrids = prevLock;
        }

        if (gridForgeCatalog.Rows.Count > 0) {
            int targetIdx = (selectRowIndex >= 0 && selectRowIndex < gridForgeCatalog.Rows.Count) ? selectRowIndex : 0;
            gridForgeCatalog.Rows[targetIdx].Selected = true;
            InspectSelectedForgeBlueprint();
        }
    }

    private void InspectSelectedForgeBlueprint() {
        if (gridForgeCatalog.SelectedRows.Count == 0) return;
        int idx = gridForgeCatalog.SelectedRows[0].Index;
        if (idx < 0 || idx >= CodeHarvesterEngine.ForgedAddonIdeas.Count) return;
        AddonForgeBlueprint bp = CodeHarvesterEngine.ForgedAddonIdeas[idx];
        txtForgeBlueprintView.Text = bp.FullBlueprintReport;
    }

    private void ExportSelectedForgeAddon() {
        if (gridForgeCatalog.SelectedRows.Count == 0) {
            MessageBox.Show("Select a Forged Addon Cluster in Tab [6] first!", "No Cluster Selected", MessageBoxButtons.OK, MessageBoxIcon.Information);
            return;
        }
        int idx = gridForgeCatalog.SelectedRows[0].Index;
        if (idx < 0 || idx >= CodeHarvesterEngine.ForgedAddonIdeas.Count) return;
        AddonForgeBlueprint bp = CodeHarvesterEngine.ForgedAddonIdeas[idx];

        string exportedDir = CodeHarvesterEngine.ExportPlayableForgePrototype(studioDir, bp);
        if (!string.IsNullOrEmpty(exportedDir) && Directory.Exists(exportedDir)) {
            hudBar.OverlayText = "EXPORTED PLAYABLE ADDON PROTOTYPE TO: " + exportedDir;
            System.Diagnostics.Process.Start("explorer.exe", exportedDir);
        }
    }

    private void RefreshManualTopicsList() {
        lstManualTopics.Items.Clear();
        filteredManualTopics.Clear();
        string q = (txtManualSearch != null) ? txtManualSearch.Text.Trim().ToLowerInvariant() : "";

        for (int i = 0; i < CodeHarvesterEngine.StudioManualTopics.Count; i++) {
            ManualTopic t = CodeHarvesterEngine.StudioManualTopics[i];
            if (q.Length > 0) {
                string hay = (t.SectionNum + " " + t.Title + " " + t.Category + " " + t.Keywords + " " + t.GuideBody).ToLowerInvariant();
                if (!hay.Contains(q)) continue;
            }
            filteredManualTopics.Add(t);
            lstManualTopics.Items.Add(t.SectionNum + " -- " + t.Title);
        }
        if (lstManualTopics.Items.Count > 0) {
            lstManualTopics.SelectedIndex = 0;
        } else {
            txtManualBody.Text = "No manual topics matched your search query.";
        }
    }

    private void DisplaySelectedManualTopic() {
        int idx = lstManualTopics.SelectedIndex;
        if (idx < 0 || idx >= filteredManualTopics.Count) return;
        ManualTopic t = filteredManualTopics[idx];
        StringBuilder sb = new StringBuilder();
        sb.AppendLine("================================================================================");
        sb.AppendLine(t.SectionNum + ": " + t.Title.ToUpperInvariant());
        sb.AppendLine("CATEGORY: " + t.Category);
        sb.AppendLine("================================================================================");
        sb.AppendLine("");
        sb.AppendLine(t.GuideBody);
        txtManualBody.Text = sb.ToString();
    }

    private void JumpToManualTopic(int idx) {
        SwitchView(5);
        txtManualSearch.Text = "";
        RefreshManualTopicsList();
        if (idx >= 0 && idx < lstManualTopics.Items.Count) {
            lstManualTopics.SelectedIndex = idx;
        }
    }

    // ========================================================================
    // SECTION 11.0: CORE WORKFLOWS (EMERGENT CLUSTERS, LLM INVENTOR, CLEAR)
    // ========================================================================
    private void SwitchView(int idx) {
        view1Scoreboard.Visible = (idx == 1);
        view2DbExplorer.Visible = (idx == 2);
        view3CodeVault.Visible  = (idx == 3);
        view4RagBrain.Visible   = (idx == 4);
        view5Manual.Visible     = (idx == 5);
        view6AddonForge.Visible = (idx == 6);

        btnNav1.BackColor = (idx == 1) ? bgAccentBlue : bgHeader;
        btnNav2.BackColor = (idx == 2) ? bgAccentBlue : bgHeader;
        btnNav3.BackColor = (idx == 3) ? bgAccentBlue : bgHeader;
        btnNav4.BackColor = (idx == 4) ? bgAccentBlue : bgHeader;
        btnNav5.BackColor = (idx == 5) ? bgAccentBlue : bgAccentPurp;
        btnNav6.BackColor = (idx == 6) ? bgAccentBlue : bgAccentGold;

        if (idx == 2 && gridDbRecords.Rows.Count == 0) RefreshDbGridOnDemand();
        if (idx == 3 && gridSnippets.Rows.Count == 0) RefreshCodeGridOnDemand();
        if (idx == 4 && txtBlueprintsView.Text.Length == 0) RefreshBlueprintsOnDemand();
    }

    private void SynthesizeCompatiblePartnersForSelected() {
        if (gridSnippets.SelectedRows.Count == 0) {
            MessageBox.Show("Select a function in the Tab [3] Creative Code Store table first!", "No Function Selected", MessageBoxButtons.OK, MessageBoxIcon.Information);
            return;
        }
        int idx = gridSnippets.SelectedRows[0].Index;
        if (idx < 0 || idx >= currentSnippetList.Count) return;

        CodeSnippet anchor = currentSnippetList[idx];
        hudBar.OverlayText = "FORGING COMPLETE 4-ORGAN ADDON CLUSTER & LUA GLUE CODE FOR [" + anchor.FuncName + "]...";
        Application.DoEvents();

        string report = CodeHarvesterEngine.BuildCompatiblePartnerSynthesisReport(studioDir, anchor);
        txtCodePreview.Text = report;
        PopulateForgeCatalogGrid(0);
        SwitchView(6);
        hudBar.OverlayText = "ADDED CUSTOM CLUSTER '" + anchor.AddonName + "." + anchor.FuncName + "' TO TAB [6] NEW ADDON FORGE!";
    }

    private void ToggleStopOrResumeScan() {
        if (isScanning) {
            StopActiveScanNow();
        } else {
            ChewMasterDir(chkForceRescan.Checked);
        }
    }

    private void StopActiveScanNow() {
        cancelRequested = true;
        CodeHarvesterEngine.CancelRequested = true;
        isScanning = false;
        hudBar.IsRunning = false;
        btnStopResumeToggle.Text = "RESUME / START SCAN";
        btnStopResumeToggle.BackColor = bgAccentGrn;
        hudBar.OverlayText = "SCAN PAUSED BY USER -- CLICK 'RESUME / START SCAN' TO CONTINUE OR 'WIPE DATABASE'";
        EnqueueLog("Scan paused/stopped by user.");
    }

    private void PromptDoubleConfirmWipeDatabase() {
        DialogResult step1 = MessageBox.Show(
            "Are you sure you want to wipe the database?",
            "Wipe Database Confirmation (Step 1 of 2)",
            MessageBoxButtons.YesNo,
            MessageBoxIcon.Warning,
            MessageBoxDefaultButton.Button2
        );
        if (step1 != DialogResult.Yes) return;

        DialogResult step2 = MessageBox.Show(
            "Are you absolutely positive you want to wipe the database?",
            "FINAL WARNING: Wipe Database (Step 2 of 2)",
            MessageBoxButtons.YesNo,
            MessageBoxIcon.Stop,
            MessageBoxDefaultButton.Button2
        );
        if (step2 != DialogResult.Yes) return;

        if (isScanning || (workerThread != null && workerThread.IsAlive)) {
            cancelRequested = true;
            CodeHarvesterEngine.CancelRequested = true;
            try { workerThread.Abort(); } catch {}
            System.Threading.Thread.Sleep(150);
        }

        isScanning = false;
        btnStopResumeToggle.Text = "RESUME / START SCAN";
        btnStopResumeToggle.BackColor = bgAccentGrn;

        string tDir = DataRipperEngine.ResolveTroughDir(studioDir);
        if (Directory.Exists(tDir)) {
            try { Directory.Delete(tDir, true); } catch {}
        }
        DataRipperEngine.ResetAllMemory();
        CodeHarvesterEngine.ResetAllCodeMemory();
        GC.Collect();

        gridProjects.Rows.Clear();
        gridDbRecords.Rows.Clear();
        gridSnippets.Rows.Clear();
        gridForgeCatalog.Rows.Clear();
        txtBlueprintsView.Clear();
        txtForgeBlueprintView.Clear();
        hudBar.IsRunning = false;
        hudBar.Value = 0;
        hudBar.OverlayText = "DATABASE WIPED CLEAN -- CLICK 'RESUME / START SCAN' TO BEGIN FRESH CHEW!";
        lblLiveLayerTracker.Text = "LIVE LAYER TRACKER: [DATABASE WIPED CLEAN]";
        EnqueueLog("DATABASE WIPED CLEAN after double confirmation.");
        MessageBox.Show("The Portable SQL Trough database has been wiped completely clean.", "Database Wiped", MessageBoxButtons.OK, MessageBoxIcon.Information);
    }

    private void ReChewSelectedParentGroups() {
        if (gridProjects.SelectedRows.Count == 0) {
            MessageBox.Show("Select 1 or more Parent Folders in the table first (use Ctrl+Click or Shift+Click for multiple parents)!", "No Parent Selected", MessageBoxButtons.OK, MessageBoxIcon.Information);
            return;
        }

        List<string> selectedPaths = new List<string>();
        List<string> selectedNames = new List<string>();
        for (int i = 0; i < gridProjects.SelectedRows.Count; i++) {
            string pName = gridProjects.SelectedRows[i].Cells[0].Value.ToString();
            AddonTelemetry st;
            if (DataRipperEngine.AddonStatsMap.TryGetValue(pName, out st)) {
                if (!string.IsNullOrEmpty(st.FolderPath) && (Directory.Exists(st.FolderPath) || File.Exists(st.FolderPath))) {
                    selectedPaths.Add(st.FolderPath);
                    selectedNames.Add(pName);
                }
            }
        }

        if (selectedPaths.Count == 0) {
            MessageBox.Show("Could not locate disk paths for the selected parent folder(s).", "Path Not Found", MessageBoxButtons.OK, MessageBoxIcon.Warning);
            return;
        }

        EnqueueLog("Starting Layer-by-Layer Force Re-Chew on " + selectedPaths.Count + " selected parent(s): " + string.Join(", ", selectedNames));
        StartBackgroundIngestion(selectedPaths.ToArray(), true);
    }

    private void WireDragAndDrop(Control c) {
        c.AllowDrop = true;
        c.DragEnter += (s, e) => {
            if (e.Data.GetDataPresent(DataFormats.FileDrop)) {
                e.Effect = DragDropEffects.Copy;
                pnlDropBanner.BackColor = Color.FromArgb(6, 78, 59);
            } else {
                e.Effect = DragDropEffects.None;
            }
        };
        c.DragLeave += (s, e) => {
            pnlDropBanner.BackColor = Color.FromArgb(17, 24, 39);
        };
        c.DragDrop += (s, e) => {
            pnlDropBanner.BackColor = Color.FromArgb(17, 24, 39);
            if (e.Data.GetDataPresent(DataFormats.FileDrop)) {
                string[] paths = (string[])e.Data.GetData(DataFormats.FileDrop);
                if (paths != null && paths.Length > 0) {
                    SwitchView(1);
                    StartBackgroundIngestion(paths, chkForceRescan.Checked);
                }
            }
        };
    }

    private void SaveStudioConfig() {
        try {
            StringBuilder sb = new StringBuilder();
            sb.AppendLine("OUT=" + txtAltVaultDir.Text.Trim());
            sb.AppendLine("MASTER=" + txtMasterDir.Text.Trim());
            File.WriteAllText(configPath, sb.ToString());
        } catch {}
    }

    private void LoadStudioConfig() {
        DirectoryInfo parent = Directory.GetParent(studioDir);
        string parentPath = (parent != null) ? parent.FullName : studioDir;
        string desktopAddons = @"C:\Users\seanw\OneDrive\Desktop\wow forever addons";
        txtMasterDir.Text = Directory.Exists(desktopAddons) ? desktopAddons : parentPath;
        string defaultAlt = Path.Combine(parentPath, "AltVault");
        txtAltVaultDir.Text = Directory.Exists(defaultAlt) ? defaultAlt : studioDir;

        if (File.Exists(configPath)) {
            string[] lines = File.ReadAllLines(configPath);
            for (int i = 0; i < lines.Length; i++) {
                if (lines[i].StartsWith("OUT=")) {
                    string v = lines[i].Substring(4).Trim();
                    if (v.Length > 0) txtAltVaultDir.Text = v;
                } else if (lines[i].StartsWith("MASTER=")) {
                    string m = lines[i].Substring(7).Trim();
                    if (m.Length > 0) txtMasterDir.Text = m;
                }
            }
        }
    }

    private void LoadLightweightParentInventoryOnly() {
        DataRipperEngine.ResetAllMemory();
        CodeHarvesterEngine.ResetAllCodeMemory();

        string invPath = Path.Combine(DataRipperEngine.ResolveTroughDir(studioDir), "Trough_AddonsInventory.tsv");
        int totalDataCount     = 0;
        int totalFuncCount     = 0;
        int totalCreativeCount = 0;
        int totalBpCount       = 0;
        bool neededFolderBackfill = false;

        if (File.Exists(invPath)) {
            try {
                using (StreamReader sr = new StreamReader(invPath, Encoding.UTF8)) {
                    string ln;
                    while ((ln = sr.ReadLine()) != null) {
                        if (string.IsNullOrWhiteSpace(ln)) continue;
                        string[] c = ln.Split('\t');
                        if (c.Length >= 15) {
                            AddonTelemetry st = DataRipperEngine.GetOrCreateAddonTelemetry(c[0], c[1]);
                            st.LastWriteSignature = c[2];
                            st.StatusBadge        = c[3];
                            int.TryParse(c[4], out st.TotalFiles);
                            int.TryParse(c[5], out st.LuaFiles);
                            int.TryParse(c[6], out st.XmlFiles);
                            int.TryParse(c[7], out st.TocFiles);
                            int.TryParse(c[8], out st.CodeOtherFiles);
                            int.TryParse(c[9], out st.DataRecordsCount);
                            int.TryParse(c[10], out st.ItemIDsCount);
                            int.TryParse(c[11], out st.SpellIDsCount);
                            int.TryParse(c[12], out st.QuestOrNpcIDsCount);
                            int.TryParse(c[13], out st.FunctionsCount);
                            int.TryParse(c[14], out st.BlueprintsCount);
                            if (c.Length >= 16) int.TryParse(c[15], out st.CreativeBricksCount);
                            if (c.Length >= 17) int.TryParse(c[16], out st.TotalFolders);

                            if (st.TotalFolders <= 0 && !string.IsNullOrEmpty(st.FolderPath)) {
                                st.TotalFolders = DataRipperEngine.FastCountDirectoriesSafe(st.FolderPath);
                                neededFolderBackfill = true;
                            }

                            totalDataCount     += st.DataRecordsCount;
                            totalFuncCount     += st.FunctionsCount;
                            totalCreativeCount += st.CreativeBricksCount;
                            totalBpCount       += st.BlueprintsCount;
                        }
                    }
                }
                if (neededFolderBackfill) {
                    DataRipperEngine.SaveAddonInventoryTableToDisk(studioDir);
                }
            } catch {}
        }

        DataRipperEngine.TotalSavedDataRecordsOnDisk       = totalDataCount;
        CodeHarvesterEngine.TotalSavedSnippetsOnDisk       = totalFuncCount;
        CodeHarvesterEngine.TotalSavedCreativeBricksOnDisk = totalCreativeCount;
        CodeHarvesterEngine.TotalSavedBlueprintsOnDisk     = totalBpCount;

        RefreshAddonDropdowns();
        PopulateProjectsGrid();

        long ramMb = GC.GetTotalMemory(false) / (1024 * 1024);
        lblStatsBanner.Text = string.Format(
            "Parents: {0} | Data IDs: {1} | Code Blocks: {2} | Creative Bricks: {3} | RAM: {4} MB",
            DataRipperEngine.AddonStatsList.Count, totalDataCount, totalFuncCount, totalCreativeCount, ramMb
        );
        hudBar.Value = 0;
        hudBar.OverlayText = string.Format(
            "READY ({0} Parents | {1} Data IDs | {2} Code Blocks | {3} Creative Bricks) -- OPEN TAB [6]!",
            DataRipperEngine.AddonStatsList.Count, totalDataCount, totalFuncCount, totalCreativeCount
        );
    }

    private void RefreshAddonDropdowns() {
        isUpdatingGrids = true;
        try {
            cmbDbAddon.Items.Clear();
            cmbDbAddon.Items.Add("ALL PARENT ADDONS");
            cmbCodeAddon.Items.Clear();
            cmbCodeAddon.Items.Add("ALL PARENT ADDONS");

            for (int i = 0; i < DataRipperEngine.AddonStatsList.Count; i++) {
                string name = DataRipperEngine.AddonStatsList[i].AddonName;
                cmbDbAddon.Items.Add(name);
                cmbCodeAddon.Items.Add(name);
            }
            cmbDbAddon.SelectedIndex = 0;
            cmbCodeAddon.SelectedIndex = 0;
        } finally {
            isUpdatingGrids = false;
        }
    }

    private void PopulateProjectsGrid() {
        bool prevLock = isUpdatingGrids;
        isUpdatingGrids = true;
        try {
            gridProjects.Rows.Clear();
            string q = txtFilterProjects.Text.Trim().ToLowerInvariant();
            for (int i = 0; i < DataRipperEngine.AddonStatsList.Count; i++) {
                AddonTelemetry st = DataRipperEngine.AddonStatsList[i];
                if (q.Length > 0 && !st.AddonName.ToLowerInvariant().Contains(q)) continue;
                gridProjects.Rows.Add(
                    st.AddonName, st.StatusBadge, st.TotalFolders, st.TotalFiles, st.LuaFiles,
                    (st.XmlFiles + st.TocFiles),
                    st.DataRecordsCount, st.ItemIDsCount, st.SpellIDsCount,
                    st.FunctionsCount, st.CreativeBricksCount, st.FolderPath
                );
            }
        } finally {
            isUpdatingGrids = prevLock;
        }
    }

    private void RefreshDbGridOnDemand() {
        bool prevLock = isUpdatingGrids;
        isUpdatingGrids = true;
        try {
            string selAddon = cmbDbAddon.SelectedItem != null ? cmbDbAddon.SelectedItem.ToString() : "ALL PARENT ADDONS";
            string selType  = cmbDbType.SelectedItem != null ? cmbDbType.SelectedItem.ToString() : "ALL TYPES";
            string selEra   = cmbDbEra.SelectedItem != null ? cmbDbEra.SelectedItem.ToString() : "ALL ERAS";
            string kw       = txtDbSearch.Text.Trim();

            DataRipperEngine.QueryDataTroughOnDemand(studioDir, selAddon, selType, selEra, kw, 500);

            gridDbRecords.Rows.Clear();
            currentDbList.Clear();
            for (int i = 0; i < DataRipperEngine.ExtractedRecords.Count; i++) {
                LootRecord r = DataRipperEngine.ExtractedRecords[i];
                currentDbList.Add(r);
                gridDbRecords.Rows.Add(
                    (i + 1), r.IDType, r.ID, r.Name, r.Era, r.ContentType,
                    r.CategoryName, r.BossOrHeader, r.SourceAddon, r.ParentRelativePath
                );
            }
            lblDbCount.Text = "Showing " + currentDbList.Count + " matching records streamed on-demand from disk";
        } finally {
            isUpdatingGrids = prevLock;
        }
    }

    private void InspectSelectedDbRecord() {
        if (gridDbRecords.SelectedRows.Count == 0) return;
        int idx = gridDbRecords.SelectedRows[0].Index;
        if (idx < 0 || idx >= currentDbList.Count) return;
        LootRecord r = currentDbList[idx];
        StringBuilder sb = new StringBuilder();
        sb.AppendLine("-- ============================================================================");
        sb.AppendLine("-- PORTABLE SQL TROUGH RECORD INSPECTOR (FULL PARENT FILE LINEAGE)");
        sb.AppendLine("-- ============================================================================");
        sb.AppendLine("PARENT ADDON FOLDER  : " + r.SourceAddon);
        sb.AppendLine("PARENT RELATIVE FILE : " + r.ParentRelativePath);
        sb.AppendLine("PARENT FULL DISK PATH: " + r.ParentFullDiskPath);
        sb.AppendLine("-------------------------------------------------------------------------------");
        sb.AppendLine("ID_TYPE              : " + r.IDType + "  |  MAIN_ID: " + r.ID);
        sb.AppendLine("NAME / LABEL         : " + r.Name);
        sb.AppendLine("ERA & CONTENT TYPE   : " + r.Era + "  |  " + r.ContentType);
        sb.AppendLine("CATEGORY & SUBSECTION: " + r.CategoryName + "  |  " + r.SubSectionName);
        sb.AppendLine("BOSS / HEADER        : " + r.BossOrHeader + " (" + r.Difficulty + ")");
        sb.AppendLine("");
        sb.AppendLine("local sources = _G.AltVaultMasterDB:GetItemSources(" + r.ID + ")");
        txtDbInspector.Text = sb.ToString();
    }

    private void RefreshCodeGridOnDemand() {
        bool prevLock = isUpdatingGrids;
        isUpdatingGrids = true;
        try {
            string selAddon = cmbCodeAddon.SelectedItem != null ? cmbCodeAddon.SelectedItem.ToString() : "ALL PARENT ADDONS";
            string selLang  = cmbCodeLang.SelectedItem != null ? cmbCodeLang.SelectedItem.ToString() : "ALL LANGS";
            string selCat   = cmbCodeCat.SelectedItem != null ? cmbCodeCat.SelectedItem.ToString() : "ALL INTENDED FEATURES";
            string selLego  = cmbCodeLego.SelectedItem != null ? cmbCodeLego.SelectedItem.ToString() : "ALL CREATIVE LEGO BRICKS";
            string kw       = txtCodeSearch.Text.Trim();

            CodeHarvesterEngine.QueryCodeTroughOnDemand(studioDir, selAddon, selLang, selCat, selLego, kw, 500);

            gridSnippets.Rows.Clear();
            currentSnippetList.Clear();
            for (int i = 0; i < CodeHarvesterEngine.HarvestedSnippets.Count; i++) {
                CodeSnippet s = CodeHarvesterEngine.HarvestedSnippets[i];
                currentSnippetList.Add(s);
                gridSnippets.Rows.Add(
                    s.SynergyScore,
                    s.AddonName,
                    s.FuncName,
                    s.CreativeLegoTag,
                    s.InputSockets + " -> " + s.OutputPlugs,
                    s.RelativePath + ":" + s.StartLine
                );
            }
            lblCodeCount.Text = "Showing " + currentSnippetList.Count + " blocks sorted High -> Low Synergy across all 648 Addons";
        } finally {
            isUpdatingGrids = prevLock;
        }
    }

    private void InspectSelectedSnippet() {
        if (gridSnippets.SelectedRows.Count == 0) return;
        int idx = gridSnippets.SelectedRows[0].Index;
        if (idx < 0 || idx >= currentSnippetList.Count) return;
        CodeSnippet s = currentSnippetList[idx];
        string bodyOnDemand = CodeHarvesterEngine.GetSnippetBodyOnDemand(s);

        StringBuilder sb = new StringBuilder();
        sb.AppendLine("-- ============================================================================");
        sb.AppendLine("-- PARENT ADDON FOLDER : " + s.AddonName + " [" + s.Language + "]  |  SYNERGY SCORE: " + s.SynergyScore + "/100");
        sb.AppendLine("-- PARENT RELATIVE FILE: " + s.RelativePath + " (Lines " + s.StartLine + " - " + s.EndLine + ")");
        sb.AppendLine("-- PARENT DISK PATH    : " + s.FullFilePath);
        sb.AppendLine("-- SIGNATURE           : " + s.Signature);
        sb.AppendLine("-- SOCKET / PLUG DNA   : IN [" + s.InputSockets + "]  --->  OUT [" + s.OutputPlugs + "]");
        sb.AppendLine("-- INTENDED FEATURE    : " + s.Category);
        sb.AppendLine("-- CREATIVE LEGO BRICK : " + s.CreativeLegoTag);
        sb.AppendLine("-- FRANKENSTEIN IDEA   : " + s.FrankensteinIdea);
        if (!string.IsNullOrEmpty(s.ApisUsed)) sb.AppendLine("-- APIS / HOOKS        : " + s.ApisUsed);
        if (!string.IsNullOrEmpty(s.EventsUsed)) sb.AppendLine("-- WOW EVENTS          : " + s.EventsUsed);
        sb.AppendLine("-- ============================================================================");
        sb.AppendLine(bodyOnDemand);
        txtCodePreview.Text = sb.ToString();
    }

    private void RefreshBlueprintsOnDemand() {
        string selType = cmbBpType.SelectedItem != null ? cmbBpType.SelectedItem.ToString() : "ALL BLUEPRINTS";
        string kw      = txtBpSearch.Text.Trim();
        CodeHarvesterEngine.QueryBlueprintsTroughOnDemand(studioDir, selType, kw, 800);

        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < CodeHarvesterEngine.HarvestedBlueprints.Count; i++) {
            BlueprintEntry b = CodeHarvesterEngine.HarvestedBlueprints[i];
            sb.AppendFormat("[{0}] Parent: {1} :: {2} (File: {3}:{4}) -> {5}\r\n", b.EntryType, b.AddonName, b.KeyName, b.ParentRelativePath, b.LineNumber, b.Details);
        }
        txtBlueprintsView.Text = sb.ToString();
    }

    private void StartBackgroundIngestion(string[] paths, bool forceFlag) {
        if (isScanning) {
            StopActiveScanNow();
            return;
        }

        SaveStudioConfig();
        string outDirCopy = txtAltVaultDir.Text.Trim();

        isScanning = true;
        cancelRequested = false;
        CodeHarvesterEngine.CancelRequested = false;
        btnStopResumeToggle.Text = "STOP / PAUSE SCAN";
        btnStopResumeToggle.BackColor = bgAccentGold;
        hudBar.IsRunning = true;
        hudBar.Maximum = 100;
        hudBar.Value = 1;
        hudBar.OverlayText = "STARTING LAYER-BY-LAYER ZERO-RAM STREAMING QUEUE...";

        scanTimer.Restart();

        workerThread = new System.Threading.Thread(() => {
            try {
                CodeHarvesterEngine.ExecuteOmniDeconstruction(
                    paths,
                    outDirCopy,
                    studioDir,
                    true,
                    true,
                    forceFlag,
                    EnqueueLog
                );

                scanTimer.Stop();
                if (!this.IsDisposed && this.IsHandleCreated) {
                    this.BeginInvoke((Action)(() => {
                        isScanning = false;
                        btnStopResumeToggle.Text = "RESUME / START SCAN";
                        btnStopResumeToggle.BackColor = bgAccentGrn;
                        hudBar.IsRunning = false;
                        hudBar.Value = 100;
                        RefreshAddonDropdowns();
                        PopulateProjectsGrid();
                        hudBar.OverlayText = cancelRequested
                            ? "SCAN PAUSED BY USER -- CLICK 'RESUME / START SCAN' TO CONTINUE"
                            : string.Format(
                                "COMPLETE IN {0:0.0} SEC! Parents:{1} | Data IDs:{2} | Code Blocks:{3} | Creative Bricks:{4}",
                                scanTimer.Elapsed.TotalSeconds,
                                DataRipperEngine.AddonStatsList.Count,
                                DataRipperEngine.TotalSavedDataRecordsOnDisk,
                                CodeHarvesterEngine.TotalSavedSnippetsOnDisk,
                                CodeHarvesterEngine.TotalSavedCreativeBricksOnDisk
                            );
                    }));
                }
            } catch (Exception ex) {
                EnqueueLog("Scan interrupted: " + ex.Message);
                if (!this.IsDisposed && this.IsHandleCreated) {
                    this.BeginInvoke((Action)(() => {
                        isScanning = false;
                        btnStopResumeToggle.Text = "RESUME / START SCAN";
                        btnStopResumeToggle.BackColor = bgAccentGrn;
                        hudBar.IsRunning = false;
                    }));
                }
            }
        });

        workerThread.IsBackground = true;
        workerThread.Start();
    }

    private void ChewMasterDir(bool forceFlag) {
        string m = txtMasterDir.Text.Trim();
        if (string.IsNullOrEmpty(m) || !Directory.Exists(m)) {
            MessageBox.Show("Please select a valid Master AddOns directory first!");
            return;
        }
        SwitchView(1);
        StartBackgroundIngestion(new string[] { m }, forceFlag);
    }

    private void FeedFolderDialog() {
        FolderBrowserDialog dlg = new FolderBrowserDialog();
        dlg.SelectedPath = txtMasterDir.Text;
        if (dlg.ShowDialog() == DialogResult.OK) {
            SwitchView(1);
            StartBackgroundIngestion(new string[] { dlg.SelectedPath }, chkForceRescan.Checked);
        }
    }

    private void FeedFilesDialog() {
        OpenFileDialog ofd = new OpenFileDialog();
        ofd.Multiselect = true;
        if (ofd.ShowDialog() == DialogResult.OK) {
            SwitchView(1);
            StartBackgroundIngestion(ofd.FileNames, chkForceRescan.Checked);
        }
    }

    private void PickMasterDir() {
        FolderBrowserDialog dlg = new FolderBrowserDialog();
        dlg.SelectedPath = txtMasterDir.Text;
        if (dlg.ShowDialog() == DialogResult.OK) {
            txtMasterDir.Text = dlg.SelectedPath;
            SaveStudioConfig();
        }
    }

    private void PickAltVaultDir() {
        FolderBrowserDialog dlg = new FolderBrowserDialog();
        dlg.SelectedPath = txtAltVaultDir.Text;
        if (dlg.ShowDialog() == DialogResult.OK) {
            txtAltVaultDir.Text = dlg.SelectedPath;
            SaveStudioConfig();
        }
    }

    private void JumpFromScoreboardToCode() {
        if (gridProjects.SelectedRows.Count == 0) return;
        string name = gridProjects.SelectedRows[0].Cells[0].Value.ToString();
        SwitchView(3);
        if (cmbCodeAddon.Items.Contains(name)) {
            cmbCodeAddon.SelectedItem = name;
            RefreshCodeGridOnDemand();
        }
    }

    private void JumpFromScoreboardToData() {
        if (gridProjects.SelectedRows.Count == 0) return;
        string name = gridProjects.SelectedRows[0].Cells[0].Value.ToString();
        SwitchView(2);
        if (cmbDbAddon.Items.Contains(name)) {
            cmbDbAddon.SelectedItem = name;
            RefreshDbGridOnDemand();
        }
    }

    private void RunOmniSearch() {
        string q = txtGlobalSearch.Text.Trim();
        txtDbSearch.Text = q;
        txtCodeSearch.Text = q;
        txtBpSearch.Text = q;
        RefreshCodeGridOnDemand();
        SwitchView(3);
    }

    private void AppendRagChunk(string title, string content) {
        if (string.IsNullOrEmpty(content)) return;
        ragChunkCount++;
        if (txtRagBasket.Text.Length == 0) {
            txtRagBasket.Text = "================================================================================\r\nFRANKENSTEIN CREATIVE CODE & AI RAG BRAIN PACKET (WITH SOCKET DNA & LINEAGE)\r\n================================================================================\r\n\r\n";
        }
        txtRagBasket.AppendText("### [FRANKENSTEIN BRICK #" + ragChunkCount + "] " + title + "\r\n" + content + "\r\n\r\n");
        lblRagTitle.Text = "FRANKENSTEIN & AI RAG BRAIN BASKET (" + ragChunkCount + " Bricks)";
        hudBar.OverlayText = "ADDED '" + title + "' TO FRANKENSTEIN AI BRAIN BASKET!";
    }

    private void ClearRagBasket() {
        ragChunkCount = 0;
        txtRagBasket.Clear();
        lblRagTitle.Text = "FRANKENSTEIN & AI RAG BRAIN BASKET (0 Bricks)";
    }

    private void AutoPackTopicToRag() {
        string topic = txtBpSearch.Text.Trim();
        if (topic.Length == 0) topic = "Lego_UI_Grid_Matrix";
        CodeHarvesterEngine.QueryCodeTroughOnDemand(studioDir, "ALL PARENT ADDONS", "ALL LANGS", "ALL INTENDED FEATURES", "ALL CREATIVE LEGO BRICKS", topic, 10);

        StringBuilder sb = new StringBuilder();
        int count = 0;
        for (int i = 0; i < CodeHarvesterEngine.HarvestedSnippets.Count; i++) {
            CodeSnippet s = CodeHarvesterEngine.HarvestedSnippets[i];
            string bodyOnDemand = CodeHarvesterEngine.GetSnippetBodyOnDemand(s);
            sb.AppendLine("-- [Parent: " + s.AddonName + " | Synergy: " + s.SynergyScore + "/100 | " + s.CreativeLegoTag + "] " + s.Signature + " (File: " + s.RelativePath + ":" + s.StartLine + ")");
            sb.AppendLine("-- Sockets: " + s.InputSockets + " -> " + s.OutputPlugs);
            sb.AppendLine("-- Repurpose Idea: " + s.FrankensteinIdea);
            sb.AppendLine(bodyOnDemand);
            sb.AppendLine("");
            count++;
        }
        AppendRagChunk("Auto-Packed Frankenstein Topic: " + topic + " (" + count + " bricks)", sb.ToString());
    }

    private void ExportLuaFeederNow() {
        int u1, u2, u3, u4;
        DataRipperEngine.StreamLuaFeederFromDiskTrough(studioDir, txtAltVaultDir.Text.Trim(), EnqueueLog, out u1, out u2, out u3, out u4);
        MessageBox.Show("Streamed DB_MasterHoldingTank.lua feeder directly from disk to AltVault!");
    }

    private void GenerateAndOpenReadmeManual() {
        CodeHarvesterEngine.WriteStudioReadmeAndAiManual(studioDir, 0, 0, 0, 0, EnqueueLog);
        string mdPath = Path.Combine(studioDir, "STUDIO_README_AND_AI_ARCHITECTURE.md");
        if (File.Exists(mdPath)) {
            System.Diagnostics.Process.Start("notepad.exe", mdPath);
        }
    }

    private void OpenTroughInExplorer() {
        string tDir = DataRipperEngine.ResolveTroughDir(studioDir);
        if (!Directory.Exists(tDir)) Directory.CreateDirectory(tDir);
        System.Diagnostics.Process.Start("explorer.exe", tDir);
    }

    private void RunPythonSqliteBuilder() {
        string py = Path.Combine(DataRipperEngine.ResolveTroughDir(studioDir), "Build_SQLite_DB.py");
        if (File.Exists(py)) System.Diagnostics.Process.Start("python", "\"" + py + "\"");
    }

    private void CopyHandoffToClipboard() {
        hudBar.OverlayText = "BUILDING v14.1 648-ADDON HIGH-SYNERGY AUDIT & SOCKET DNA REPORT FROM DISK...";
        Application.DoEvents();
        CodeHarvesterEngine.WriteStudioReadmeAndAiManual(studioDir, 0, 0, 0, 0, EnqueueLog);
        string hp = Path.Combine(studioDir, "AI_MASTER_LIBRARY_HANDOFF.txt");
        if (File.Exists(hp)) {
            Clipboard.SetText(File.ReadAllText(hp));
            hudBar.OverlayText = "COPIED v14.1 MASTER AI HANDOFF & SYNERGY AUDIT TO CLIPBOARD!";
            MessageBox.Show("Copied complete v14.1 AI_MASTER_LIBRARY_HANDOFF.txt to Clipboard!", "v14.1 Synergy Audit Copied", MessageBoxButtons.OK, MessageBoxIcon.Information);
        }
    }

    private void SpawnFloatingWindow(string title, string content) {
        Form f = new Form();
        f.Text = title;
        f.Size = new Size(980, 720);
        f.StartPosition = FormStartPosition.CenterScreen;
        f.BackColor = bgDark;
        TextBox tb = new TextBox() { Dock = DockStyle.Fill, Multiline = true, ScrollBars = ScrollBars.Both, WordWrap = false, BackColor = bgDark, ForeColor = fgGreen, Font = fontMono, Text = content };
        f.Controls.Add(tb);
        f.Show();
    }
}
