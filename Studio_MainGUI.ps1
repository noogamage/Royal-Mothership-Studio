# ==============================================================================
# DECONSTRUCTION GOD STUDIO v14.1 - FILE 3 OF 3: Studio_MainGUI.ps1
# ==============================================================================
# SECTION 1.0: POWERSHELL BOOTSTRAP & ENGINE FILE VERIFICATION
# SECTION 2.0: CUSTOM NEON HUD PROGRESS BAR CONTROL (C#)
# SECTION 3.0: STUDIO MAIN WINDOW CLASS, UI STATE & 10-FPS TELEMETRY TIMER
# SECTION 4.0: TOP MENU BAR WITH 6-TAB NAVIGATION & WORKSPACE LAYOUT
# SECTION 5.0: VIEW [1] MULTI-SELECT PARENT SCOREBOARD & LIVE LAYER TRACKER
# SECTION 6.0: VIEW [2] ON-DEMAND SQL TROUGH DATABASE EXPLORER
# SECTION 7.0: VIEW [3] CREATIVE CODE STORE (SORTED BY SYNERGY 100 -> 5)
# SECTION 8.0: VIEW [4] ON-DEMAND HOOKS, MEDIA ASSETS & AI RAG BRAIN BASKET
# SECTION 9.0: VIEW [5] SEARCHABLE INTERACTIVE README & AI HANDOFF MANUAL
# SECTION 10.0: VIEW [6] EMERGENT ADDON FORGE, MICRO-LLM INVENTOR & SELF-AUDITOR
# SECTION 11.0: CORE WORKFLOWS (EMERGENT CLUSTERS, LLM INVENTOR, CLEAR/RESET)
# ==============================================================================

# ==============================================================================
# SECTION 1.0: POWERSHELL BOOTSTRAP & ENGINE FILE VERIFICATION
# ==============================================================================
try {
    Write-Host "[1/3] Loading .NET Windows Forms Assemblies..." -ForegroundColor Cyan;
    Add-Type -AssemblyName System.Windows.Forms;
    Add-Type -AssemblyName System.Drawing;

    $studioDir = ($PSScriptRoot);
    if (-not ($studioDir)) { $studioDir = ((Get-Location).Path); }

    $csFile1 = (Join-Path ($studioDir) "Engine_DataRipper.cs");
    $csFile2 = (Join-Path ($studioDir) "Engine_CodeHarvester.cs");

    if ((-not (Test-Path ($csFile1))) -or (-not (Test-Path ($csFile2)))) {
        Write-Host "ERROR: Missing Engine_DataRipper.cs or Engine_CodeHarvester.cs in $studioDir" -ForegroundColor Red;
        Read-Host "Press Enter to exit";
        exit 1;
    }

    Write-Host "[2/3] Compiling C# Engines and Studio v14.1 Emergent Discovery & Micro-LLM UI..." -ForegroundColor Cyan;

    $uiCSharpSource = @'
// ============================================================================
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
public class StudioMainForm : Form {
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

    // ========================================================================
    // SECTION 5.0: VIEW [1] MULTI-SELECT PARENT SCOREBOARD & LIVE LAYER TRACKER
    // ========================================================================
    private void BuildView1Scoreboard() {
        view1Scoreboard = new Panel();
        view1Scoreboard.Dock = DockStyle.Fill;

        SplitContainer split = new SplitContainer();
        split.Dock = DockStyle.Fill;
        split.Orientation = Orientation.Vertical;
        split.SplitterDistance = 880;
        split.SplitterWidth = 6;
        split.BackColor = Color.FromArgb(55, 65, 81);

        TableLayoutPanel leftLayout = new TableLayoutPanel();
        leftLayout.Dock = DockStyle.Fill;
        leftLayout.BackColor = bgPanel;
        leftLayout.ColumnCount = 1;
        leftLayout.RowCount = 3;
        leftLayout.RowStyles.Add(new RowStyle(SizeType.Absolute, 36F));
        leftLayout.RowStyles.Add(new RowStyle(SizeType.Percent, 100F));
        leftLayout.RowStyles.Add(new RowStyle(SizeType.Absolute, 42F));

        FlowLayoutPanel leftTop = new FlowLayoutPanel();
        leftTop.Dock = DockStyle.Fill;
        leftTop.BackColor = bgHeader;
        leftTop.Padding = new Padding(6, 4, 6, 0);
        Label lblP = new Label();
        lblP.Text = "PARENT FOLDERS IN SQL TROUGH (Ctrl/Shift-Click to Multi-Select Parents):  Filter:";
        lblP.AutoSize = true;
        lblP.Font = fontBold;
        lblP.ForeColor = fgCyan;
        lblP.Padding = new Padding(0, 4, 6, 0);
        txtFilterProjects = new TextBox();
        txtFilterProjects.Width = 150;
        txtFilterProjects.BackColor = bgDark;
        txtFilterProjects.ForeColor = fgGold;
        txtFilterProjects.TextChanged += (s, e) => { if (!isUpdatingGrids) PopulateProjectsGrid(); };
        leftTop.Controls.AddRange(new Control[] { lblP, txtFilterProjects });

        gridProjects = new DataGridView();
        gridProjects.Dock = DockStyle.Fill;
        StyleGrid(gridProjects, true);
        gridProjects.Columns.Add("AddonName", "Parent Folder Name");
        gridProjects.Columns[0].Width = 190;
        gridProjects.Columns.Add("Status", "Parent Status");
        gridProjects.Columns[1].Width = 145;
        gridProjects.Columns.Add("Folders", "Folders");
        gridProjects.Columns[2].Width = 60;
        gridProjects.Columns.Add("Files", "Files");
        gridProjects.Columns[3].Width = 55;
        gridProjects.Columns.Add("Lua", "Lua");
        gridProjects.Columns[4].Width = 50;
        gridProjects.Columns.Add("XmlToc", "XML/TOC");
        gridProjects.Columns[5].Width = 65;
        gridProjects.Columns.Add("DataIDs", "Data IDs");
        gridProjects.Columns[6].Width = 75;
        gridProjects.Columns.Add("Items", "Items");
        gridProjects.Columns[7].Width = 65;
        gridProjects.Columns.Add("Spells", "Spells");
        gridProjects.Columns[8].Width = 65;
        gridProjects.Columns.Add("Funcs", "Code Blocks");
        gridProjects.Columns[9].Width = 85;
        gridProjects.Columns.Add("Lego", "Creative Bricks");
        gridProjects.Columns[10].Width = 105;
        gridProjects.Columns.Add("FolderPath", "Full Parent Disk Path");
        gridProjects.Columns[11].Width = 320;
        gridProjects.CellDoubleClick += (s, e) => JumpFromScoreboardToCode();

        FlowLayoutPanel leftBot = new FlowLayoutPanel();
        leftBot.Dock = DockStyle.Fill;
        leftBot.BackColor = bgPanel;

        Button bReChew = MakeBtn("Re-Chew Selected Parent Group(s)", bgAccentGold, 240, 32);
        bReChew.Click += (s, e) => ReChewSelectedParentGroups();

        Button bSelAll = MakeBtn("Select All Parents", bgHeader, 135, 32);
        bSelAll.Click += (s, e) => gridProjects.SelectAll();

        Button bClrSel = MakeBtn("Clear Selection", bgHeader, 120, 32);
        bClrSel.Click += (s, e) => gridProjects.ClearSelection();

        Button bJumpDb = MakeBtn("Inspect Data ->", bgAccentBlue, 130, 32);
        bJumpDb.Click += (s, e) => JumpFromScoreboardToData();

        Button bJumpCd = MakeBtn("Inspect Code ->", bgAccentGrn, 130, 32);
        bJumpCd.Click += (s, e) => JumpFromScoreboardToCode();

        Button bScout = MakeBtn("Scout CurseForge/GitHub ->", bgAccentPurp, 195, 32);
        bScout.Click += (s, e) => { SwitchView(6); RunDonorAddonScoutNow(); };

        leftBot.Controls.AddRange(new Control[] { bReChew, bSelAll, bClrSel, bJumpDb, bJumpCd, bScout });

        leftLayout.Controls.Add(leftTop, 0, 0);
        leftLayout.Controls.Add(gridProjects, 0, 1);
        leftLayout.Controls.Add(leftBot, 0, 2);
        split.Panel1.Controls.Add(leftLayout);

        TableLayoutPanel rightLayout = new TableLayoutPanel();
        rightLayout.Dock = DockStyle.Fill;
        rightLayout.BackColor = bgPanel;
        rightLayout.ColumnCount = 1;
        rightLayout.RowCount = 3;
        rightLayout.RowStyles.Add(new RowStyle(SizeType.Absolute, 36F));
        rightLayout.RowStyles.Add(new RowStyle(SizeType.Absolute, 68F));
        rightLayout.RowStyles.Add(new RowStyle(SizeType.Percent, 100F));

        Label lblRightHdr = new Label();
        lblRightHdr.Dock = DockStyle.Fill;
        lblRightHdr.BackColor = bgHeader;
        lblRightHdr.ForeColor = fgCyan;
        lblRightHdr.Font = fontBold;
        lblRightHdr.TextAlign = ContentAlignment.MiddleLeft;
        lblRightHdr.Padding = new Padding(8, 0, 0, 0);
        lblRightHdr.Text = "WORKSPACE PATHS & COMPLETED PARENT LOG";

        TableLayoutPanel pathGrid = new TableLayoutPanel();
        pathGrid.Dock = DockStyle.Fill;
        pathGrid.ColumnCount = 3;
        pathGrid.RowCount = 2;
        pathGrid.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute, 110F));
        pathGrid.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100F));
        pathGrid.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute, 80F));

        Label lM = new Label() { Text = "Master AddOns:", Dock = DockStyle.Fill, TextAlign = ContentAlignment.MiddleLeft };
        txtMasterDir = new TextBox() { Dock = DockStyle.Fill, BackColor = bgDark, ForeColor = fgGreen, Font = fontMono };
        Button bM = MakeBtn("...", bgHeader, 68, 24);
        bM.Click += (s, e) => PickMasterDir();

        Label lO = new Label() { Text = "AltVault Out:", Dock = DockStyle.Fill, TextAlign = ContentAlignment.MiddleLeft };
        txtAltVaultDir = new TextBox() { Dock = DockStyle.Fill, BackColor = bgDark, ForeColor = fgGreen, Font = fontMono };
        Button bO = MakeBtn("...", bgHeader, 68, 24);
        bO.Click += (s, e) => PickAltVaultDir();

        pathGrid.Controls.Add(lM, 0, 0);
        pathGrid.Controls.Add(txtMasterDir, 1, 0);
        pathGrid.Controls.Add(bM, 2, 0);
        pathGrid.Controls.Add(lO, 0, 1);
        pathGrid.Controls.Add(txtAltVaultDir, 1, 1);
        pathGrid.Controls.Add(bO, 2, 1);

        txtLog = new TextBox();
        txtLog.Dock = DockStyle.Fill;
        txtLog.Multiline = true;
        txtLog.ReadOnly = true;
        txtLog.ScrollBars = ScrollBars.Both;
        txtLog.WordWrap = false;
        txtLog.BackColor = Color.FromArgb(9, 12, 16);
        txtLog.ForeColor = fgGreen;
        txtLog.Font = fontMono;

        rightLayout.Controls.Add(lblRightHdr, 0, 0);
        rightLayout.Controls.Add(pathGrid, 0, 1);
        rightLayout.Controls.Add(txtLog, 0, 2);
        split.Panel2.Controls.Add(rightLayout);

        view1Scoreboard.Controls.Add(split);
    }

    // ========================================================================
    // SECTION 6.0: VIEW [2] ON-DEMAND SQL TROUGH DATABASE EXPLORER
    // ========================================================================
    private void BuildView2DbExplorer() {
        view2DbExplorer = new Panel();
        view2DbExplorer.Dock = DockStyle.Fill;
        view2DbExplorer.Visible = false;

        TableLayoutPanel layout = new TableLayoutPanel();
        layout.Dock = DockStyle.Fill;
        layout.ColumnCount = 1;
        layout.RowCount = 2;
        layout.RowStyles.Add(new RowStyle(SizeType.Absolute, 42F));
        layout.RowStyles.Add(new RowStyle(SizeType.Percent, 100F));

        FlowLayoutPanel filterBar = new FlowLayoutPanel();
        filterBar.Dock = DockStyle.Fill;
        filterBar.BackColor = bgPanel;
        filterBar.WrapContents = false;
        filterBar.Padding = new Padding(6, 6, 6, 0);

        cmbDbAddon = new ComboBox() { Width = 190, DropDownStyle = ComboBoxStyle.DropDownList };
        cmbDbAddon.Items.Add("ALL PARENT ADDONS");
        cmbDbAddon.SelectedIndex = 0;
        cmbDbAddon.SelectedIndexChanged += (s, e) => { if (!isUpdatingGrids) RefreshDbGridOnDemand(); };

        cmbDbType = new ComboBox() { Width = 120, DropDownStyle = ComboBoxStyle.DropDownList };
        cmbDbType.Items.AddRange(new object[] { "ALL TYPES", "Item", "Spell", "Set", "Quest", "NPC", "DB_Entry", "SQL_Record", "JSON_Record" });
        cmbDbType.SelectedIndex = 0;
        cmbDbType.SelectedIndexChanged += (s, e) => { if (!isUpdatingGrids) RefreshDbGridOnDemand(); };

        cmbDbEra = new ComboBox() { Width = 120, DropDownStyle = ComboBoxStyle.DropDownList };
        cmbDbEra.Items.AddRange(new object[] { "ALL ERAS", "Classic", "SoD_Forever", "TBC", "Wrath" });
        cmbDbEra.SelectedIndex = 0;
        cmbDbEra.SelectedIndexChanged += (s, e) => { if (!isUpdatingGrids) RefreshDbGridOnDemand(); };

        txtDbSearch = new TextBox() { Width = 240, BackColor = bgDark, ForeColor = fgGold, Font = fontMono };
        Button btnQ = MakeBtn("Query Disk Trough", bgAccentBlue, 150, 28);
        btnQ.Click += (s, e) => RefreshDbGridOnDemand();
        Button btnF = MakeBtn("Float Window", bgHeader, 125, 28);
        btnF.Click += (s, e) => SpawnFloatingWindow("Floating SQL Record Inspector", txtDbInspector.Text);

        filterBar.Controls.AddRange(new Control[] { cmbDbAddon, cmbDbType, cmbDbEra, txtDbSearch, btnQ, btnF });
        layout.Controls.Add(filterBar, 0, 0);

        SplitContainer split = new SplitContainer();
        split.Dock = DockStyle.Fill;
        split.Orientation = Orientation.Horizontal;
        split.SplitterDistance = 380;
        split.SplitterWidth = 6;
        split.BackColor = Color.FromArgb(55, 65, 81);

        gridDbRecords = new DataGridView();
        gridDbRecords.Dock = DockStyle.Fill;
        StyleGrid(gridDbRecords, false);
        gridDbRecords.Columns.Add("RowNum", "#"); gridDbRecords.Columns[0].Width = 55;
        gridDbRecords.Columns.Add("IDType", "Type"); gridDbRecords.Columns[1].Width = 80;
        gridDbRecords.Columns.Add("ID", "ID"); gridDbRecords.Columns[2].Width = 80;
        gridDbRecords.Columns.Add("Name", "Name / Label"); gridDbRecords.Columns[3].Width = 210;
        gridDbRecords.Columns.Add("Era", "Era"); gridDbRecords.Columns[4].Width = 95;
        gridDbRecords.Columns.Add("Content", "Content"); gridDbRecords.Columns[5].Width = 120;
        gridDbRecords.Columns.Add("Category", "Category / Zone"); gridDbRecords.Columns[6].Width = 175;
        gridDbRecords.Columns.Add("Boss", "Boss / Header"); gridDbRecords.Columns[7].Width = 160;
        gridDbRecords.Columns.Add("ParentAddon", "Parent Addon"); gridDbRecords.Columns[8].Width = 150;
        gridDbRecords.Columns.Add("ParentRel", "Parent Relative File Path"); gridDbRecords.Columns[9].Width = 310;
        gridDbRecords.SelectionChanged += (s, e) => { if (!isUpdatingGrids) InspectSelectedDbRecord(); };
        split.Panel1.Controls.Add(gridDbRecords);

        TableLayoutPanel botLayout = new TableLayoutPanel();
        botLayout.Dock = DockStyle.Fill;
        botLayout.RowCount = 2;
        botLayout.RowStyles.Add(new RowStyle(SizeType.Absolute, 36F));
        botLayout.RowStyles.Add(new RowStyle(SizeType.Percent, 100F));

        FlowLayoutPanel botBar = new FlowLayoutPanel() { Dock = DockStyle.Fill, BackColor = bgHeader };
        lblDbCount = new Label() { Text = "SQL Record Inspector (Streamed On-Demand From Disk)", AutoSize = true, ForeColor = fgCyan, Font = fontBold, Padding = new Padding(6, 8, 20, 0) };
        Button bPin = MakeBtn("+ Pin Record to AI Brain", bgAccentPurp, 195, 28);
        bPin.Click += (s, e) => AppendRagChunk("SQL Trough Record", txtDbInspector.Text);
        Button bCpy = MakeBtn("Copy Record", bgAccentGrn, 130, 28);
        bCpy.Click += (s, e) => { if (txtDbInspector.Text.Length > 0) Clipboard.SetText(txtDbInspector.Text); };
        botBar.Controls.AddRange(new Control[] { lblDbCount, bPin, bCpy });

        txtDbInspector = new TextBox() { Dock = DockStyle.Fill, Multiline = true, ReadOnly = true, ScrollBars = ScrollBars.Both, WordWrap = false, BackColor = bgDark, ForeColor = fgGreen, Font = fontMono };
        botLayout.Controls.Add(botBar, 0, 0);
        botLayout.Controls.Add(txtDbInspector, 0, 1);
        split.Panel2.Controls.Add(botLayout);

        layout.Controls.Add(split, 0, 1);
        view2DbExplorer.Controls.Add(layout);
    }

    // ========================================================================
    // SECTION 7.0: VIEW [3] CREATIVE CODE STORE (SORTED BY SYNERGY 100 -> 5)
    // ========================================================================
    private void BuildView3CodeVault() {
        view3CodeVault = new Panel();
        view3CodeVault.Dock = DockStyle.Fill;
        view3CodeVault.Visible = false;

        TableLayoutPanel layout = new TableLayoutPanel();
        layout.Dock = DockStyle.Fill;
        layout.ColumnCount = 1;
        layout.RowCount = 2;
        layout.RowStyles.Add(new RowStyle(SizeType.Absolute, 42F));
        layout.RowStyles.Add(new RowStyle(SizeType.Percent, 100F));

        FlowLayoutPanel filterBar = new FlowLayoutPanel() { Dock = DockStyle.Fill, BackColor = bgPanel, WrapContents = false, Padding = new Padding(6, 6, 6, 0) };

        cmbCodeAddon = new ComboBox() { Width = 150, DropDownStyle = ComboBoxStyle.DropDownList };
        cmbCodeAddon.Items.Add("ALL PARENT ADDONS");
        cmbCodeAddon.SelectedIndex = 0;
        cmbCodeAddon.SelectedIndexChanged += (s, e) => { if (!isUpdatingGrids) RefreshCodeGridOnDemand(); };

        cmbCodeLang = new ComboBox() { Width = 95, DropDownStyle = ComboBoxStyle.DropDownList };
        cmbCodeLang.Items.AddRange(new object[] { "ALL LANGS", "Lua", "XML", "C++", "C", "C/C++ Header", "C#", "Python", "SQL", "JavaScript", "TypeScript", "PowerShell" });
        cmbCodeLang.SelectedIndex = 0;
        cmbCodeLang.SelectedIndexChanged += (s, e) => { if (!isUpdatingGrids) RefreshCodeGridOnDemand(); };

        cmbCodeCat = new ComboBox() { Width = 185, DropDownStyle = ComboBoxStyle.DropDownList };
        cmbCodeCat.Items.AddRange(new object[] {
            "ALL INTENDED FEATURES", "Bag_And_Inventory_Sorting", "Loot_Browser_And_Dropdown_UI",
            "Automation_And_Hooks", "Tooltips_And_BiS", "Forever_16001_ModernAPI",
            "UnitFrames_And_Heal", "Boss_Timers_And_Alerts", "Nameplates_And_HUD",
            "Map_Quests_And_Coords", "Auction_And_Economy", "DataStore_Network_And_Sync",
            "Professions_And_Crafting", "Frames_And_UI_Layout", "External_CPlusPlus_Python_SQL", "General_Logic_And_Utils"
        });
        cmbCodeCat.SelectedIndex = 0;
        cmbCodeCat.SelectedIndexChanged += (s, e) => { if (!isUpdatingGrids) RefreshCodeGridOnDemand(); };

        cmbCodeLego = new ComboBox() { Width = 225, DropDownStyle = ComboBoxStyle.DropDownList };
        cmbCodeLego.Items.AddRange(new object[] {
            "ALL CREATIVE LEGO BRICKS",
            "Lego_Polyfill_And_Compat_Shim",
            "Lego_Frame_And_Object_Pool",
            "Lego_UI_Grid_Matrix",
            "Lego_Search_And_Filter",
            "Lego_Async_Throttle_Engine",
            "Lego_Tooltip_Data_Injector",
            "Lego_Custom_Widget_Skin",
            "Lego_Hook_And_Automation",
            "Lego_CombatLog_SubEvent_Parser",
            "Lego_Spatial_And_Pin_Math",
            "Lego_Hyperlink_And_Chat_Filter",
            "Lego_Secure_Action_Macro",
            "Lego_Data_Compression_Sync",
            "Lego_Metatable_OOP_Engine",
            "Lego_State_Event_Router",
            "Lego_CrossLang_Algorithm",
            "Lego_Utility_And_Math"
        });
        cmbCodeLego.SelectedIndex = 0;
        cmbCodeLego.SelectedIndexChanged += (s, e) => { if (!isUpdatingGrids) RefreshCodeGridOnDemand(); };

        txtCodeSearch = new TextBox() { Width = 175, BackColor = bgDark, ForeColor = fgGold, Font = fontMono };
        Button btnS = MakeBtn("Query Store", bgAccentBlue, 110, 28);
        btnS.Click += (s, e) => RefreshCodeGridOnDemand();
        Button btnFl = MakeBtn("Float Window", bgHeader, 120, 28);
        btnFl.Click += (s, e) => SpawnFloatingWindow("Floating Creative Code & Synergy Inspector", txtCodePreview.Text);

        filterBar.Controls.AddRange(new Control[] { cmbCodeAddon, cmbCodeLang, cmbCodeCat, cmbCodeLego, txtCodeSearch, btnS, btnFl });
        layout.Controls.Add(filterBar, 0, 0);

        SplitContainer split = new SplitContainer();
        split.Dock = DockStyle.Fill;
        split.Orientation = Orientation.Vertical;
        split.SplitterDistance = 710;
        split.SplitterWidth = 6;
        split.BackColor = Color.FromArgb(55, 65, 81);

        TableLayoutPanel leftPane = new TableLayoutPanel() { Dock = DockStyle.Fill, RowCount = 2 };
        leftPane.RowStyles.Add(new RowStyle(SizeType.Percent, 100F));
        leftPane.RowStyles.Add(new RowStyle(SizeType.Absolute, 28F));

        gridSnippets = new DataGridView() { Dock = DockStyle.Fill };
        StyleGrid(gridSnippets, false);
        gridSnippets.Columns.Add("Synergy", "Syn"); gridSnippets.Columns[0].Width = 45;
        gridSnippets.Columns.Add("Addon", "Parent Addon"); gridSnippets.Columns[1].Width = 135;
        gridSnippets.Columns.Add("Func", "Function / Script Block"); gridSnippets.Columns[2].Width = 175;
        gridSnippets.Columns.Add("Lego", "Creative Lego Brick"); gridSnippets.Columns[3].Width = 185;
        gridSnippets.Columns.Add("Sockets", "Precision Sockets -> Plugs"); gridSnippets.Columns[4].Width = 210;
        gridSnippets.Columns.Add("ParentRel", "Parent Relative File : Line"); gridSnippets.Columns[5].Width = 220;
        gridSnippets.SelectionChanged += (s, e) => { if (!isUpdatingGrids) InspectSelectedSnippet(); };

        lblCodeCount = new Label() { Dock = DockStyle.Fill, BackColor = bgHeader, ForeColor = fgCyan, Font = fontBold, TextAlign = ContentAlignment.MiddleLeft, Padding = new Padding(6, 0, 0, 0), Text = "Matching Creative Code Blocks (Sorted High -> Low Synergy across all 648 Addons): 0" };
        leftPane.Controls.Add(gridSnippets, 0, 0);
        leftPane.Controls.Add(lblCodeCount, 0, 1);
        split.Panel1.Controls.Add(leftPane);

        TableLayoutPanel rightPane = new TableLayoutPanel() { Dock = DockStyle.Fill, RowCount = 2 };
        rightPane.RowStyles.Add(new RowStyle(SizeType.Absolute, 38F));
        rightPane.RowStyles.Add(new RowStyle(SizeType.Percent, 100F));

        FlowLayoutPanel codeTop = new FlowLayoutPanel() { Dock = DockStyle.Fill, BackColor = bgHeader, WrapContents = false };
        Button bSyn = MakeBtn("Forge New Addon Idea from Brick", bgAccentGold, 240, 28);
        bSyn.Click += (s, e) => SynthesizeCompatiblePartnersForSelected();

        Button bPinC = MakeBtn("+ Add to AI Brain", bgAccentPurp, 140, 28);
        bPinC.Click += (s, e) => { if (txtCodePreview.Text.Length > 0) AppendRagChunk("Frankenstein Creative Brick / Synthesis", txtCodePreview.Text); };

        Button bCpyC = MakeBtn("Copy for AI Chat", bgAccentGrn, 140, 28);
        bCpyC.Click += (s, e) => { if (txtCodePreview.Text.Length > 0) Clipboard.SetText(txtCodePreview.Text); };
        codeTop.Controls.AddRange(new Control[] { bSyn, bPinC, bCpyC });

        txtCodePreview = new TextBox() { Dock = DockStyle.Fill, Multiline = true, ReadOnly = true, ScrollBars = ScrollBars.Both, WordWrap = false, BackColor = Color.FromArgb(9, 12, 16), ForeColor = fgGreen, Font = fontMono };
        rightPane.Controls.Add(codeTop, 0, 0);
        rightPane.Controls.Add(txtCodePreview, 0, 1);
        split.Panel2.Controls.Add(rightPane);

        layout.Controls.Add(split, 0, 1);
        view3CodeVault.Controls.Add(layout);
    }

    // ========================================================================
    // SECTION 8.0: VIEW [4] ON-DEMAND HOOKS, MEDIA ASSETS & AI RAG BRAIN BASKET
    // ========================================================================
    private void BuildView4RagBrain() {
        view4RagBrain = new Panel();
        view4RagBrain.Dock = DockStyle.Fill;
        view4RagBrain.Visible = false;

        TableLayoutPanel layout = new TableLayoutPanel() { Dock = DockStyle.Fill, RowCount = 2 };
        layout.RowStyles.Add(new RowStyle(SizeType.Absolute, 42F));
        layout.RowStyles.Add(new RowStyle(SizeType.Percent, 100F));

        FlowLayoutPanel bar = new FlowLayoutPanel() { Dock = DockStyle.Fill, BackColor = bgPanel, WrapContents = false, Padding = new Padding(6, 6, 6, 0) };
        cmbBpType = new ComboBox() { Width = 210, DropDownStyle = ComboBoxStyle.DropDownList };
        cmbBpType.Items.AddRange(new object[] {
            "ALL BLUEPRINTS", "Asset_Texture_Sound", "SavedVars_Schema",
            "Secure_Hook", "WoW_Event", "Modern_API",
            "XML_VirtualTemplate", "XML_FrameInherits", "Lua_FrameTemplate",
            "Slash_Command", "TOC_Metadata", "C++_Type", "C#_Type", "Python_Class", "SQL_TABLE"
        });
        cmbBpType.SelectedIndex = 0;
        cmbBpType.SelectedIndexChanged += (s, e) => { if (!isUpdatingGrids) RefreshBlueprintsOnDemand(); };

        txtBpSearch = new TextBox() { Width = 240, BackColor = bgDark, ForeColor = fgGold, Font = fontMono };
        Button bFilt = MakeBtn("Query Hooks / Assets", bgAccentBlue, 155, 28);
        bFilt.Click += (s, e) => RefreshBlueprintsOnDemand();
        Button bAuto = MakeBtn("Auto-Build Frankenstein Prompt for Topic", bgAccentPurp, 280, 28);
        bAuto.Click += (s, e) => AutoPackTopicToRag();

        bar.Controls.AddRange(new Control[] { cmbBpType, txtBpSearch, bFilt, bAuto });
        layout.Controls.Add(bar, 0, 0);

        SplitContainer split = new SplitContainer() { Dock = DockStyle.Fill, Orientation = Orientation.Vertical, SplitterDistance = 640, SplitterWidth = 6, BackColor = Color.FromArgb(55, 65, 81) };

        TableLayoutPanel leftP = new TableLayoutPanel() { Dock = DockStyle.Fill, RowCount = 2 };
        leftP.RowStyles.Add(new RowStyle(SizeType.Absolute, 36F));
        leftP.RowStyles.Add(new RowStyle(SizeType.Percent, 100F));
        FlowLayoutPanel lTop = new FlowLayoutPanel() { Dock = DockStyle.Fill, BackColor = bgHeader };
        Button bPinBp = MakeBtn("+ Pin Filtered Hooks/Assets to RAG Basket", bgAccentPurp, 275, 28);
        bPinBp.Click += (s, e) => AppendRagChunk("Filtered Hooks & Media Assets", txtBlueprintsView.Text);
        lTop.Controls.Add(bPinBp);
        txtBlueprintsView = new TextBox() { Dock = DockStyle.Fill, Multiline = true, ReadOnly = true, ScrollBars = ScrollBars.Both, WordWrap = false, BackColor = bgDark, ForeColor = fgCyan, Font = fontMono };
        leftP.Controls.Add(lTop, 0, 0);
        leftP.Controls.Add(txtBlueprintsView, 0, 1);
        split.Panel1.Controls.Add(leftP);

        TableLayoutPanel rightP = new TableLayoutPanel() { Dock = DockStyle.Fill, RowCount = 2 };
        rightP.RowStyles.Add(new RowStyle(SizeType.Absolute, 36F));
        rightP.RowStyles.Add(new RowStyle(SizeType.Percent, 100F));
        FlowLayoutPanel rTop = new FlowLayoutPanel() { Dock = DockStyle.Fill, BackColor = bgHeader };
        lblRagTitle = new Label() { Text = "FRANKENSTEIN & AI RAG BRAIN BASKET (0 Bricks)", AutoSize = true, ForeColor = fgGold, Font = fontBold, Padding = new Padding(6, 8, 12, 0) };
        Button bCpyRag = MakeBtn("Copy Entire AI Brain Prompt", bgAccentGrn, 215, 28);
        bCpyRag.Click += (s, e) => { if (txtRagBasket.Text.Length > 0) Clipboard.SetText(txtRagBasket.Text); };
        Button bClrRag = MakeBtn("Clear", Color.FromArgb(153, 27, 27), 75, 28);
        bClrRag.Click += (s, e) => ClearRagBasket();
        rTop.Controls.AddRange(new Control[] { lblRagTitle, bCpyRag, bClrRag });

        txtRagBasket = new TextBox() { Dock = DockStyle.Fill, Multiline = true, ScrollBars = ScrollBars.Both, WordWrap = false, BackColor = Color.FromArgb(9, 12, 16), ForeColor = fgGold, Font = fontMono };
        rightP.Controls.Add(rTop, 0, 0);
        rightP.Controls.Add(txtRagBasket, 0, 1);
        split.Panel2.Controls.Add(rightP);

        layout.Controls.Add(split, 0, 1);
        view4RagBrain.Controls.Add(layout);
    }

    // ========================================================================
    // SECTION 9.0: VIEW [5] SEARCHABLE INTERACTIVE README & AI HANDOFF MANUAL
    // ========================================================================
    private void BuildView5SearchableManual() {
        view5Manual = new Panel();
        view5Manual.Dock = DockStyle.Fill;
        view5Manual.Visible = false;

        TableLayoutPanel layout = new TableLayoutPanel() { Dock = DockStyle.Fill, RowCount = 2 };
        layout.RowStyles.Add(new RowStyle(SizeType.Absolute, 44F));
        layout.RowStyles.Add(new RowStyle(SizeType.Percent, 100F));

        FlowLayoutPanel topBar = new FlowLayoutPanel() { Dock = DockStyle.Fill, BackColor = bgPanel, WrapContents = false, Padding = new Padding(8, 6, 8, 0) };
        Label lblSearch = new Label() { Text = "SEARCH MANUAL & UI FUNCTIONS:", AutoSize = true, Font = fontBold, ForeColor = fgCyan, Padding = new Padding(0, 6, 8, 0) };
        txtManualSearch = new TextBox() { Width = 250, BackColor = bgDark, ForeColor = fgGold, Font = fontMono };
        txtManualSearch.TextChanged += (s, e) => RefreshManualTopicsList();

        Button btnCopyAiMaster = MakeBtn("Copy Complete AI Handoff & High-Synergy Audit", bgAccentGrn, 340, 30);
        btnCopyAiMaster.Click += (s, e) => CopyHandoffToClipboard();

        Button btnOpenMd = MakeBtn("Save & Open STUDIO_README_AND_AI_ARCHITECTURE.md", bgAccentBlue, 350, 30);
        btnOpenMd.Click += (s, e) => GenerateAndOpenReadmeManual();

        topBar.Controls.AddRange(new Control[] { lblSearch, txtManualSearch, btnCopyAiMaster, btnOpenMd });
        layout.Controls.Add(topBar, 0, 0);

        SplitContainer split = new SplitContainer() { Dock = DockStyle.Fill, Orientation = Orientation.Vertical, SplitterDistance = 420, SplitterWidth = 6, BackColor = Color.FromArgb(55, 65, 81) };

        lstManualTopics = new ListBox() { Dock = DockStyle.Fill, BackColor = bgPanel, ForeColor = fgLight, Font = fontBold, BorderStyle = BorderStyle.None };
        lstManualTopics.SelectedIndexChanged += (s, e) => DisplaySelectedManualTopic();
        split.Panel1.Controls.Add(lstManualTopics);

        txtManualBody = new TextBox() { Dock = DockStyle.Fill, Multiline = true, ReadOnly = true, ScrollBars = ScrollBars.Both, WordWrap = true, BackColor = bgDark, ForeColor = fgGreen, Font = new Font("Consolas", 11F, FontStyle.Regular) };
        split.Panel2.Controls.Add(txtManualBody);

        layout.Controls.Add(split, 0, 1);
        view5Manual.Controls.Add(layout);
    }

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

        Button btnExportProto = MakeBtn("Export .toc", bgHeader, 95, 30);
        btnExportProto.Click += (s, e) => ExportSelectedForgeAddon();

        topBar.Controls.AddRange(new Control[] { lblUrl, txtOllamaUrl, cmbOllamaModel, btnRun3Pass, btnRunLlm, btnSelfAudit, btnScoutDonors, btnCopyForge, btnClearView, btnResetSeeds, btnExportProto });
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
'@

    $raw1 = [System.IO.File]::ReadAllText($csFile1);
    $raw2 = [System.IO.File]::ReadAllText($csFile2);

    $clean1 = [System.Text.RegularExpressions.Regex]::Replace($raw1, "(?m)^\s*using\s+[A-Za-z0-9_\.]+\s*;\s*$", "");
    $clean2 = [System.Text.RegularExpressions.Regex]::Replace($raw2, "(?m)^\s*using\s+[A-Za-z0-9_\.]+\s*;\s*$", "");

    $masterUsings = @"
using System;
using System.IO;
using System.Net;
using System.Text;
using System.Drawing;
using System.Windows.Forms;
using System.Text.RegularExpressions;
using System.Collections.Generic;
"@

    $fullCSharpUnit = ($masterUsings + "`r`n" + $clean1 + "`r`n" + $clean2 + "`r`n" + $uiCSharpSource);

    Add-Type -TypeDefinition ($fullCSharpUnit) -ReferencedAssemblies @(
        "System.dll",
        "System.Core.dll",
        "System.Drawing.dll",
        "System.Windows.Forms.dll"
    );

    Write-Host "[3/3] Launching Deconstruction God Studio v14.1..." -ForegroundColor Green;
    [System.Windows.Forms.Application]::EnableVisualStyles();
    $mainForm = New-Object StudioMainForm($studioDir);
    [void][System.Windows.Forms.Application]::Run($mainForm);

} catch {
    Write-Host "================================================================================" -ForegroundColor Red;
    Write-Host "FATAL ERROR IN STUDIO_MAINGUI.PS1:" -ForegroundColor Red;
    Write-Host ($_.Exception.ToString()) -ForegroundColor Yellow;
    Write-Host "================================================================================" -ForegroundColor Red;
    Read-Host "Press Enter to close this window";
}