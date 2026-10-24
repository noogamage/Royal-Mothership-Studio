// ============================================================================
// DECONSTRUCTION GOD STUDIO v14.3 - MODULAR NODE SYSTEM
// NODE INDEX  : [31] OF [35]
// FILE NAME   : Node_31_GuiTab1_Scoreboard.cs
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
}
