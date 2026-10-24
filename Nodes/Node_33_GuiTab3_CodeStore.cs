// ============================================================================
// DECONSTRUCTION GOD STUDIO v14.3 - MODULAR NODE SYSTEM
// NODE INDEX  : [33] OF [35]
// FILE NAME   : Node_33_GuiTab3_CodeStore.cs
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
}
