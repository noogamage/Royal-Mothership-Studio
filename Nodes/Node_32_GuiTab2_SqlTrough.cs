// ============================================================================
// DECONSTRUCTION GOD STUDIO v14.3 - MODULAR NODE SYSTEM
// NODE INDEX  : [32] OF [35]
// FILE NAME   : Node_32_GuiTab2_SqlTrough.cs
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
        cmbDbType.Items.AddRange(new object[] { "ALL TYPES", "Item", "Spell", "Set", "Quest", "NPC", "Hotfix_BroadcastText", "Hotfix_ItemSparse", "DB_Entry", "SQL_Record", "JSON_Record" });
        cmbDbType.SelectedIndex = 0;
        cmbDbType.SelectedIndexChanged += (s, e) => { if (!isUpdatingGrids) RefreshDbGridOnDemand(); };

        cmbDbEra = new ComboBox() { Width = 120, DropDownStyle = ComboBoxStyle.DropDownList };
        cmbDbEra.Items.AddRange(new object[] { "ALL ERAS", "Classic_Forever_16001", "SoD_Forever", "Classic", "TBC", "Wrath" });
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
}
