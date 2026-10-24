// ============================================================================
// DECONSTRUCTION GOD STUDIO v14.3 - MODULAR NODE SYSTEM
// NODE INDEX  : [30] OF [35]
// FILE NAME   : Node_30_GuiCoreAndHud.cs
// PARTIAL OF  : CustomHudProgressBar, StudioMainForm
// ============================================================================
using System;
using System.IO;
using System.Net;
using System.Text;
using System.Drawing;
using System.Windows.Forms;
using System.Text.RegularExpressions;
using System.Collections.Generic;

// SECTION 2.0: CUSTOM NEON HUD PROGRESS BAR CONTROL (C#)
// ============================================================================
public class CustomHudProgressBar : Control {
    private int val = 0;
    private int max = 100;
    private string overlayText = "PAUSED / IDLE -- CLICK TAB [6] FOR EMERGENT DISCOVERY, MICRO-LLM & SELF-AUDIT";
    private bool isRunning = false;

    public int Value {
        get { return val; }
        set { val = value < 0 ? 0 : (value > max ? max : value); this.Invalidate(); }
    }
    public int Maximum {
        get { return max; }
        set { max = value < 1 ? 1 : value; this.Invalidate(); }
    }
    public string OverlayText {
        get { return overlayText; }
        set { overlayText = value ?? ""; this.Invalidate(); }
    }
    public bool IsRunning {
        get { return isRunning; }
        set { isRunning = value; this.Invalidate(); }
    }

    public CustomHudProgressBar() {
        this.DoubleBuffered = true;
        this.SetStyle(ControlStyles.UserPaint | ControlStyles.AllPaintingInWmPaint | ControlStyles.OptimizedDoubleBuffer, true);
        this.Height = 38;
    }

    protected override void OnPaint(PaintEventArgs e) {
        Graphics g = e.Graphics;
        g.SmoothingMode = System.Drawing.Drawing2D.SmoothingMode.AntiAlias;
        Rectangle rect = this.ClientRectangle;

        using (SolidBrush bgBrush = new SolidBrush(Color.FromArgb(10, 14, 20))) {
            g.FillRectangle(bgBrush, rect);
        }

        if (val > 0 && max > 0) {
            int fillW = (int)((long)rect.Width * val / max);
            if (fillW > 0) {
                Rectangle fillRect = new Rectangle(0, 0, fillW, rect.Height);
                Color c1 = isRunning ? Color.FromArgb(16, 185, 129) : Color.FromArgb(37, 99, 235);
                Color c2 = isRunning ? Color.FromArgb(6, 182, 212) : Color.FromArgb(59, 130, 246);
                using (System.Drawing.Drawing2D.LinearGradientBrush grad = new System.Drawing.Drawing2D.LinearGradientBrush(fillRect, c1, c2, 0f)) {
                    g.FillRectangle(grad, fillRect);
                }
            }
        }

        using (Pen borderPen = new Pen(isRunning ? Color.FromArgb(245, 158, 11) : Color.FromArgb(55, 65, 81), 2)) {
            g.DrawRectangle(borderPen, 1, 1, rect.Width - 2, rect.Height - 2);
        }

        using (Font f = new Font("Consolas", 10.5F, FontStyle.Bold)) {
            TextRenderer.DrawText(
                g,
                overlayText,
                f,
                rect,
                Color.White,
                TextFormatFlags.HorizontalCenter | TextFormatFlags.VerticalCenter | TextFormatFlags.EndEllipsis
            );
        }
    }
}

// ============================================================================
// SECTION 3.0: STUDIO MAIN WINDOW CLASS, UI STATE & 10-FPS TELEMETRY TIMER
// ============================================================================
public partial class StudioMainForm : Form {
    private string studioDir;
    private string configPath;
    private int ragChunkCount = 0;

    private volatile bool isScanning = false;
    private volatile bool cancelRequested = false;
    private bool isUpdatingGrids = false;
    private System.Threading.Thread workerThread = null;
    private System.Diagnostics.Stopwatch scanTimer = new System.Diagnostics.Stopwatch();
    private System.Windows.Forms.Timer uiTelemetryTimer = null;
    private int timerTickCounter = 0;
    private Queue<string> pendingLogMessages = new Queue<string>();

    private Panel pnlDropBanner;
    private Label lblDropTitle;
    private CheckBox chkForceRescan;
    private Button btnStopResumeToggle;
    private Button btnWipeDbTop;
    private CustomHudProgressBar hudBar;
    private Label lblLiveLayerTracker;

    private TextBox txtMasterDir;
    private TextBox txtAltVaultDir;
    private TextBox txtGlobalSearch;
    private Label lblStatsBanner;

    private Panel view1Scoreboard;
    private Panel view2DbExplorer;
    private Panel view3CodeVault;
    private Panel view4RagBrain;
    private Panel view5Manual;
    private Panel view6AddonForge;
    private Button btnNav1;
    private Button btnNav2;
    private Button btnNav3;
    private Button btnNav4;
    private Button btnNav5;
    private Button btnNav6;

    private DataGridView gridProjects;
    private TextBox txtFilterProjects;
    private TextBox txtLog;

    private ComboBox cmbDbAddon;
    private ComboBox cmbDbType;
    private ComboBox cmbDbEra;
    private TextBox txtDbSearch;
    private DataGridView gridDbRecords;
    private TextBox txtDbInspector;
    private Label lblDbCount;
    private List<LootRecord> currentDbList = new List<LootRecord>();

    private ComboBox cmbCodeAddon;
    private ComboBox cmbCodeLang;
    private ComboBox cmbCodeCat;
    private ComboBox cmbCodeLego;
    private TextBox txtCodeSearch;
    private DataGridView gridSnippets;
    private TextBox txtCodePreview;
    private Label lblCodeCount;
    private List<CodeSnippet> currentSnippetList = new List<CodeSnippet>();

    private ComboBox cmbBpType;
    private TextBox txtBpSearch;
    private TextBox txtBlueprintsView;
    private TextBox txtRagBasket;
    private Label lblRagTitle;

    private TextBox txtManualSearch;
    private ListBox lstManualTopics;
    private TextBox txtManualBody;
    private List<ManualTopic> filteredManualTopics = new List<ManualTopic>();

    private TextBox txtOllamaUrl;
    private ComboBox cmbOllamaModel;
    private DataGridView gridForgeCatalog;
    private TextBox txtForgeBlueprintView;
    private Label lblForgeCount;

    private Color bgDark       = Color.FromArgb(13, 17, 23);
    private Color bgPanel      = Color.FromArgb(22, 27, 34);
    private Color bgHeader     = Color.FromArgb(31, 41, 55);
    private Color bgAccentBlue = Color.FromArgb(37, 99, 235);
    private Color bgAccentGold = Color.FromArgb(217, 119, 6);
    private Color bgAccentGrn  = Color.FromArgb(5, 150, 105);
    private Color bgAccentPurp = Color.FromArgb(109, 40, 217);
    private Color bgAccentRed  = Color.FromArgb(185, 28, 28);
    private Color fgLight      = Color.FromArgb(230, 237, 243);
    private Color fgCyan       = Color.FromArgb(56, 189, 248);
    private Color fgGreen      = Color.FromArgb(110, 231, 183);
    private Color fgGold       = Color.FromArgb(251, 191, 36);

    private Font fontHeader = new Font("Segoe UI", 10.5F, FontStyle.Bold);
    private Font fontBold   = new Font("Segoe UI", 9.0F, FontStyle.Bold);
    private Font fontReg    = new Font("Segoe UI", 9F, FontStyle.Regular);
    private Font fontMono   = new Font("Consolas", 10F, FontStyle.Regular);

    public StudioMainForm(string baseStudioDir) {
        this.studioDir = baseStudioDir;
        this.configPath = Path.Combine(baseStudioDir, "Studio_Config.txt");

        this.Text = "Deconstruction God Studio v14.1 - Zero-Hardcode Emergent Discovery, Stateless Micro-LLM & Self-Auditor";
        this.Size = new Size(1460, 900);
        this.MinimumSize = new Size(1060, 680);
        this.StartPosition = FormStartPosition.CenterScreen;
        this.BackColor = bgDark;
        this.ForeColor = fgLight;
        this.Font = fontReg;
        this.AllowDrop = true;
        this.WindowState = FormWindowState.Maximized;

        CodeHarvesterEngine.InitializeSearchableManualTopics();
        BuildCompleteStudioLayout();
        WireDragAndDrop(this);
        WireDragAndDrop(pnlDropBanner);
        WireDragAndDrop(lblDropTitle);

        LoadStudioConfig();
        RefreshManualTopicsList();

        uiTelemetryTimer = new System.Windows.Forms.Timer();
        uiTelemetryTimer.Interval = 100;
        uiTelemetryTimer.Tick += (s, e) => OnTelemetryTimerTick();
        uiTelemetryTimer.Start();

        this.Shown += (s, e) => {
            LoadLightweightParentInventoryOnly();
            RefreshOllamaModelsDropdown();
            EnqueueLog("Studio v14.1 Ready! Zero-Hardcode Emergent Discovery, Micro-LLM Concept Inventor & Clear/Reset controls active.");
        };
    }

    private void EnqueueLog(string msg) {
        string stamp = DateTime.Now.ToString("HH:mm:ss");
        lock (pendingLogMessages) {
            pendingLogMessages.Enqueue("[" + stamp + "] " + msg);
        }
    }

    private void OnTelemetryTimerTick() {
        if (pendingLogMessages.Count > 0) {
            StringBuilder sbLog = new StringBuilder();
            lock (pendingLogMessages) {
                while (pendingLogMessages.Count > 0) {
                    sbLog.AppendLine(pendingLogMessages.Dequeue());
                }
            }
            txtLog.AppendText(sbLog.ToString());
        }

        if (!isScanning) return;

        timerTickCounter++;
        int pIdx = CodeHarvesterEngine.LiveParentIndex;
        int pTot = CodeHarvesterEngine.LiveParentTotal;
        int pct  = (pTot > 0) ? (int)((pIdx * 100L) / pTot) : 1;
        if (pct < 1) pct = 1;
        if (pct > 100) pct = 100;

        string elapsed = scanTimer.Elapsed.ToString(@"mm\:ss");
        long ramMb = GC.GetTotalMemory(false) / (1024 * 1024);

        hudBar.Value = pct;
        hudBar.OverlayText = string.Format(
            "PARENT [{0}/{1}] ({2}%): {3}  |  LAYER {4}: {5}  |  FILE [{6}/{7}]: {8}  |  RAM: {9}MB  Time: {10}",
            pIdx, pTot, pct,
            CodeHarvesterEngine.LiveParentName,
            CodeHarvesterEngine.LiveLayerDepth,
            CodeHarvesterEngine.LiveSubFolder,
            CodeHarvesterEngine.LiveFolderFilesIndex,
            CodeHarvesterEngine.LiveFolderFilesTotal,
            CodeHarvesterEngine.LiveFileName,
            ramMb,
            elapsed
        );

        lblLiveLayerTracker.Text = string.Format(
            "ACTIVE PARENT: {0} [{1}/{2}]   >>>   LAYER DEPTH: {3} ({4})   >>>   EXTRACTING FILE [{5}/{6}]: {7}",
            CodeHarvesterEngine.LiveParentName, pIdx, pTot,
            CodeHarvesterEngine.LiveLayerDepth, CodeHarvesterEngine.LiveSubFolder,
            CodeHarvesterEngine.LiveFolderFilesIndex, CodeHarvesterEngine.LiveFolderFilesTotal,
            CodeHarvesterEngine.LiveFileName
        );

        lblStatsBanner.Text = string.Format(
            "Parents: {0} | Data IDs: {1} | Code Blocks: {2} | Creative Bricks: {3} | RAM: {4} MB",
            DataRipperEngine.AddonStatsList.Count,
            DataRipperEngine.TotalSavedDataRecordsOnDisk,
            CodeHarvesterEngine.TotalSavedSnippetsOnDisk,
            CodeHarvesterEngine.TotalSavedCreativeBricksOnDisk,
            ramMb
        );

        if (timerTickCounter % 10 == 0) {
            PopulateProjectsGrid();
        }
    }

    private void StyleGrid(DataGridView dg, bool allowMultiSelect) {
        dg.BackgroundColor = bgDark;
        dg.BorderStyle = BorderStyle.None;
        dg.GridColor = Color.FromArgb(40, 48, 60);
        dg.EnableHeadersVisualStyles = false;
        dg.ColumnHeadersBorderStyle = DataGridViewHeaderBorderStyle.Single;
        dg.ColumnHeadersDefaultCellStyle.BackColor = bgHeader;
        dg.ColumnHeadersDefaultCellStyle.ForeColor = fgCyan;
        dg.ColumnHeadersDefaultCellStyle.Font = fontBold;
        dg.ColumnHeadersDefaultCellStyle.WrapMode = DataGridViewTriState.False;
        dg.ColumnHeadersHeight = 32;

        dg.DefaultCellStyle.BackColor = bgDark;
        dg.DefaultCellStyle.ForeColor = fgLight;
        dg.DefaultCellStyle.SelectionBackColor = bgAccentBlue;
        dg.DefaultCellStyle.SelectionForeColor = Color.White;
        dg.DefaultCellStyle.Font = fontMono;
        dg.AlternatingRowsDefaultCellStyle.BackColor = bgPanel;

        dg.RowHeadersVisible = false;
        dg.AllowUserToAddRows = false;
        dg.AllowUserToDeleteRows = false;
        dg.AllowUserToResizeRows = false;
        dg.ReadOnly = true;
        dg.SelectionMode = DataGridViewSelectionMode.FullRowSelect;
        dg.MultiSelect = allowMultiSelect;
        dg.ScrollBars = ScrollBars.Both;
        dg.AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.None;
    }

    private Button MakeBtn(string text, Color bg, int width, int height) {
        Button b = new Button();
        b.Text = text;
        b.BackColor = bg;
        b.ForeColor = Color.White;
        b.FlatStyle = FlatStyle.Flat;
        b.FlatAppearance.BorderColor = Color.FromArgb(75, 85, 99);
        b.Font = fontBold;
        b.Size = new Size(width, height);
        b.Margin = new Padding(3, 3, 3, 3);
        b.Cursor = Cursors.Hand;
        return b;
    }

    // ========================================================================
    // SECTION 4.0: TOP MENU BAR WITH 6-TAB NAVIGATION & WORKSPACE LAYOUT
    // ========================================================================
    private void BuildCompleteStudioLayout() {
        MenuStrip menu = new MenuStrip();
        menu.BackColor = bgPanel;
        menu.ForeColor = fgLight;
        menu.Font = fontBold;

        ToolStripMenuItem mFile = new ToolStripMenuItem("  [1] File & Database  ");
        mFile.ForeColor = fgLight;
        mFile.DropDownItems.Add("Set Master AddOns Directory...", null, (s, e) => PickMasterDir());
        mFile.DropDownItems.Add("Set AltVault Feeder Output Folder...", null, (s, e) => PickAltVaultDir());
        mFile.DropDownItems.Add("Open Portable_SQL_Trough Folder in Explorer", null, (s, e) => OpenTroughInExplorer());
        mFile.DropDownItems.Add("Refresh Parent Inventory from Disk", null, (s, e) => LoadLightweightParentInventoryOnly());
        mFile.DropDownItems.Add("WIPE DATABASE (Double-Confirmation Safety Protocol)...", null, (s, e) => PromptDoubleConfirmWipeDatabase());
        mFile.DropDownItems.Add("Exit Studio", null, (s, e) => this.Close());

        ToolStripMenuItem mIngest = new ToolStripMenuItem("  [2] Cookie Monster Ingester  ");
        mIngest.ForeColor = fgLight;
        mIngest.DropDownItems.Add("Resume / Start Layer-by-Layer Scan (Skips Completed Parents)", null, (s, e) => ChewMasterDir(false));
        mIngest.DropDownItems.Add("Stop / Pause Active Scan Immediately", null, (s, e) => StopActiveScanNow());
        mIngest.DropDownItems.Add("Re-Chew Selected Parent Group(s) in Scoreboard", null, (s, e) => ReChewSelectedParentGroups());
        mIngest.DropDownItems.Add("Force Full Re-Chew of ALL Addons in Master Dir", null, (s, e) => ChewMasterDir(true));
        mIngest.DropDownItems.Add("Feed Specific Project / Parent Folder...", null, (s, e) => FeedFolderDialog());
        mIngest.DropDownItems.Add("Feed Individual Code / Data Files (.lua, .cpp, .py, .sql)...", null, (s, e) => FeedFilesDialog());

        ToolStripMenuItem mForge = new ToolStripMenuItem("  [3] Emergent Forge & Local LLM  ");
        mForge.ForeColor = fgGold;
        mForge.DropDownItems.Add("Discover Next 8 Emergent Multi-Addon Clusters (Zero Hardcode)", null, (s, e) => { SwitchView(6); RunDeepSynergyAgentNow(); });
        mForge.DropDownItems.Add("Run Stateless Micro-Window Local LLM on Selected Cluster", null, (s, e) => RunStatelessLlmOnSelectedBlueprint());
        mForge.DropDownItems.Add("Run Self-Reflection Audit on DeconstructionGod_Studio & AltVault", null, (s, e) => { SwitchView(6); RunSelfReflectionAuditNow(); });
        mForge.DropDownItems.Add("Scout Prime Donor Addons (CurseForge / GitHub + 648-Addon Vault Gap Analysis)", null, (s, e) => { SwitchView(6); RunDonorAddonScoutNow(); });
        mForge.DropDownItems.Add("Clear Forge Viewer Window", null, (s, e) => txtForgeBlueprintView.Clear());
        mForge.DropDownItems.Add("Reset All Visited Forge Seeds (Start Fresh Generation #1)", null, (s, e) => ResetAllForgeSeeds());

        ToolStripMenuItem mRag = new ToolStripMenuItem("  [4] AI RAG Brain & Handoff  ");
        mRag.ForeColor = fgLight;
        mRag.DropDownItems.Add("Copy Complete AI Handoff & High-Synergy Audit (AI_MASTER_LIBRARY_HANDOFF.txt)", null, (s, e) => CopyHandoffToClipboard());
        mRag.DropDownItems.Add("Stream In-Game Lua Feeder (AltVault/DB_MasterHoldingTank.lua)", null, (s, e) => ExportLuaFeederNow());
        mRag.DropDownItems.Add("Compile SQLite3 Database (Run Build_SQLite_DB.py)", null, (s, e) => RunPythonSqliteBuilder());
        mRag.DropDownItems.Add("Clear Pinned AI Context Basket", null, (s, e) => ClearRagBasket());

        ToolStripMenuItem mFloat = new ToolStripMenuItem("  [5] Floating Windows  ");
        mFloat.ForeColor = fgLight;
        mFloat.DropDownItems.Add("Pop Out Floating Addon Forge Blueprint Window", null, (s, e) => SpawnFloatingWindow("Floating New Addon Forge Blueprint", txtForgeBlueprintView.Text));
        mFloat.DropDownItems.Add("Pop Out Floating Code & Frankenstein Inspector", null, (s, e) => SpawnFloatingWindow("Floating Code & Frankenstein Inspector", txtCodePreview.Text));
        mFloat.DropDownItems.Add("Pop Out Floating SQL Record Inspector", null, (s, e) => SpawnFloatingWindow("Floating SQL Record Inspector", txtDbInspector.Text));

        ToolStripMenuItem mHelp = new ToolStripMenuItem("  [6] Interactive Manual & Help  ");
        mHelp.ForeColor = fgCyan;
        mHelp.DropDownItems.Add("Open Searchable Interactive Manual & AI Handoff Tab [5]", null, (s, e) => SwitchView(5));
        for (int i = 0; i < CodeHarvesterEngine.StudioManualTopics.Count; i++) {
            int topicIdx = i;
            ManualTopic t = CodeHarvesterEngine.StudioManualTopics[i];
            mHelp.DropDownItems.Add(t.SectionNum + ": " + t.Title, null, (s, e) => JumpToManualTopic(topicIdx));
        }

        menu.Items.AddRange(new ToolStripItem[] { mFile, mIngest, mForge, mRag, mFloat, mHelp });
        this.MainMenuStrip = menu;

        TableLayoutPanel rootGrid = new TableLayoutPanel();
        rootGrid.Dock = DockStyle.Fill;
        rootGrid.ColumnCount = 1;
        rootGrid.RowCount = 5;
        rootGrid.RowStyles.Add(new RowStyle(SizeType.Absolute, 72F));
        rootGrid.RowStyles.Add(new RowStyle(SizeType.Absolute, 44F));
        rootGrid.RowStyles.Add(new RowStyle(SizeType.Absolute, 28F));
        rootGrid.RowStyles.Add(new RowStyle(SizeType.Absolute, 42F));
        rootGrid.RowStyles.Add(new RowStyle(SizeType.Percent, 100F));

        // ROW 0: FLUID COOKIE MONSTER DROP BANNER + STOP/RESUME TOGGLE + WIPE DATABASE
        pnlDropBanner = new Panel();
        pnlDropBanner.Dock = DockStyle.Fill;
        pnlDropBanner.Margin = new Padding(8, 4, 8, 2);
        pnlDropBanner.BackColor = Color.FromArgb(17, 24, 39);
        pnlDropBanner.BorderStyle = BorderStyle.FixedSingle;

        TableLayoutPanel dropGrid = new TableLayoutPanel();
        dropGrid.Dock = DockStyle.Fill;
        dropGrid.ColumnCount = 2;
        dropGrid.RowCount = 1;
        dropGrid.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100F));
        dropGrid.ColumnStyles.Add(new ColumnStyle(SizeType.AutoSize));

        lblDropTitle = new Label();
        lblDropTitle.Dock = DockStyle.Fill;
        lblDropTitle.TextAlign = ContentAlignment.MiddleLeft;
        lblDropTitle.Padding = new Padding(12, 0, 0, 0);
        lblDropTitle.Font = fontHeader;
        lblDropTitle.ForeColor = fgCyan;
        lblDropTitle.Text = "COOKIE MONSTER v14.1: ZERO-HARDCODE EMERGENT GRAPH, STATELESS MICRO-LLM & SELF-AUDITOR\r\n(Pass 1: Trough_AtomicConcepts -> Pass 2: Real API Overlap Clusters -> Pass 3: Local LLM Concept Inventor)";

        FlowLayoutPanel dropButtons = new FlowLayoutPanel();
        dropButtons.Dock = DockStyle.Fill;
        dropButtons.AutoSize = true;
        dropButtons.WrapContents = false;
        dropButtons.Padding = new Padding(4, 10, 8, 4);

        chkForceRescan = new CheckBox();
        chkForceRescan.Text = "Force Re-Chew";
        chkForceRescan.ForeColor = fgGold;
        chkForceRescan.Font = fontBold;
        chkForceRescan.AutoSize = true;
        chkForceRescan.Margin = new Padding(4, 10, 8, 0);

        btnStopResumeToggle = MakeBtn("RESUME / START SCAN", bgAccentGrn, 195, 36);
        btnStopResumeToggle.Click += (s, e) => ToggleStopOrResumeScan();

        Button btnFeedDir = MakeBtn("+ Feed Folder...", bgAccentBlue, 145, 36);
        btnFeedDir.Click += (s, e) => FeedFolderDialog();

        btnWipeDbTop = MakeBtn("WIPE DATABASE", bgAccentRed, 145, 36);
        btnWipeDbTop.Click += (s, e) => PromptDoubleConfirmWipeDatabase();

        dropButtons.Controls.AddRange(new Control[] { chkForceRescan, btnStopResumeToggle, btnFeedDir, btnWipeDbTop });
        dropGrid.Controls.Add(lblDropTitle, 0, 0);
        dropGrid.Controls.Add(dropButtons, 1, 0);
        pnlDropBanner.Controls.Add(dropGrid);
        rootGrid.Controls.Add(pnlDropBanner, 0, 0);

        // ROW 1: GIANT CUSTOM NEON HUD PROGRESS METER BAR
        Panel hudWrap = new Panel();
        hudWrap.Dock = DockStyle.Fill;
        hudWrap.Margin = new Padding(8, 2, 8, 2);
        hudBar = new CustomHudProgressBar();
        hudBar.Dock = DockStyle.Fill;
        hudWrap.Controls.Add(hudBar);
        rootGrid.Controls.Add(hudWrap, 0, 1);

        // ROW 2: LIVE LAYER / SUBFOLDER / FILE TRACKER TICKER
        lblLiveLayerTracker = new Label();
        lblLiveLayerTracker.Dock = DockStyle.Fill;
        lblLiveLayerTracker.Margin = new Padding(8, 0, 8, 2);
        lblLiveLayerTracker.BackColor = Color.FromArgb(15, 23, 42);
        lblLiveLayerTracker.ForeColor = fgGold;
        lblLiveLayerTracker.Font = fontMono;
        lblLiveLayerTracker.TextAlign = ContentAlignment.MiddleLeft;
        lblLiveLayerTracker.Padding = new Padding(10, 0, 0, 0);
        lblLiveLayerTracker.Text = "LIVE TRACKER: [IDLE] -- Click Tab [6] 'NEW ADDON FORGE' -> '1. Discover Next 8 Clusters' to generate fresh combinations!";
        rootGrid.Controls.Add(lblLiveLayerTracker, 0, 2);

        // ROW 3: 6-TAB NAVIGATION BAR + STATS + OMNI-SEARCH
        TableLayoutPanel navBar = new TableLayoutPanel();
        navBar.Dock = DockStyle.Fill;
        navBar.Margin = new Padding(8, 0, 8, 4);
        navBar.BackColor = bgPanel;
        navBar.ColumnCount = 3;
        navBar.RowCount = 1;
        navBar.ColumnStyles.Add(new ColumnStyle(SizeType.AutoSize));
        navBar.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100F));
        navBar.ColumnStyles.Add(new ColumnStyle(SizeType.AutoSize));

        FlowLayoutPanel navBtns = new FlowLayoutPanel();
        navBtns.AutoSize = true;
        navBtns.WrapContents = false;
        navBtns.Padding = new Padding(4, 2, 0, 0);

        btnNav1 = MakeBtn("[1] Scoreboard", bgAccentBlue, 118, 32);
        btnNav2 = MakeBtn("[2] SQL Trough", bgHeader, 118, 32);
        btnNav3 = MakeBtn("[3] Code Store", bgHeader, 122, 32);
        btnNav4 = MakeBtn("[4] Hooks/Assets", bgHeader, 132, 32);
        btnNav5 = MakeBtn("[5] Manual/Audit", bgAccentPurp, 138, 32);
        btnNav6 = MakeBtn("[6] NEW ADDON FORGE", bgAccentGold, 168, 32);

        btnNav1.Click += (s, e) => SwitchView(1);
        btnNav2.Click += (s, e) => SwitchView(2);
        btnNav3.Click += (s, e) => SwitchView(3);
        btnNav4.Click += (s, e) => SwitchView(4);
        btnNav5.Click += (s, e) => SwitchView(5);
        btnNav6.Click += (s, e) => SwitchView(6);
        navBtns.Controls.AddRange(new Control[] { btnNav1, btnNav2, btnNav3, btnNav4, btnNav5, btnNav6 });

        lblStatsBanner = new Label();
        lblStatsBanner.Dock = DockStyle.Fill;
        lblStatsBanner.TextAlign = ContentAlignment.MiddleCenter;
        lblStatsBanner.Font = fontBold;
        lblStatsBanner.ForeColor = fgGreen;
        lblStatsBanner.Text = "Parents: 0 | Data IDs: 0 | Code Blocks: 0 | Creative Bricks: 0 | RAM: 0 MB";

        FlowLayoutPanel searchBox = new FlowLayoutPanel();
        searchBox.AutoSize = true;
        searchBox.WrapContents = false;
        searchBox.Padding = new Padding(0, 5, 6, 0);

        txtGlobalSearch = new TextBox();
        txtGlobalSearch.Width = 130;
        txtGlobalSearch.BackColor = bgDark;
        txtGlobalSearch.ForeColor = fgGold;
        txtGlobalSearch.Font = fontMono;

        Button btnOmni = MakeBtn("Omni-Search", bgAccentBlue, 96, 28);
        btnOmni.Click += (s, e) => RunOmniSearch();
        searchBox.Controls.AddRange(new Control[] { txtGlobalSearch, btnOmni });

        navBar.Controls.Add(navBtns, 0, 0);
        navBar.Controls.Add(lblStatsBanner, 1, 0);
        navBar.Controls.Add(searchBox, 2, 0);
        rootGrid.Controls.Add(navBar, 0, 3);

        // ROW 4: WORKSPACE DECK (6 FULL-SIZE VIEWS)
        Panel deck = new Panel();
        deck.Dock = DockStyle.Fill;
        deck.Margin = new Padding(8, 0, 8, 8);

        BuildView1Scoreboard();
        BuildView2DbExplorer();
        BuildView3CodeVault();
        BuildView4RagBrain();
        BuildView5SearchableManual();
        BuildView6AddonForge();

        deck.Controls.Add(view1Scoreboard);
        deck.Controls.Add(view2DbExplorer);
        deck.Controls.Add(view3CodeVault);
        deck.Controls.Add(view4RagBrain);
        deck.Controls.Add(view5Manual);
        deck.Controls.Add(view6AddonForge);
        rootGrid.Controls.Add(deck, 0, 4);

        this.Controls.Add(rootGrid);
        this.Controls.Add(menu);
    }
}
