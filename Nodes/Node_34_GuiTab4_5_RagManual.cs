// ============================================================================
// DECONSTRUCTION GOD STUDIO v14.3 - MODULAR NODE SYSTEM
// NODE INDEX  : [34] OF [35]
// FILE NAME   : Node_34_GuiTab4_5_RagManual.cs
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
}
