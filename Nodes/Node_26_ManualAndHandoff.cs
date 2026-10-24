// ============================================================================
// DECONSTRUCTION GOD STUDIO v14.3 - MODULAR NODE SYSTEM
// NODE INDEX  : [26] OF [35]
// FILE NAME   : Node_26_ManualAndHandoff.cs
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
    // SECTION 9.0: SEARCHABLE UI MANUAL & HIGH-SYNERGY MULTI-ADDON AUDITOR
    // ========================================================================
    public static void InitializeSearchableManualTopics() {
        StudioManualTopics.Clear();

        StudioManualTopics.Add(new ManualTopic() {
            SectionNum = "TOPIC 1.0",
            Title = "Zero-Hardcode Emergent Discovery & Seed Rotation (v14.1)",
            Category = "Autonomous Addon Forge",
            Keywords = "discover emergent seed rotation zero hardcode cluster",
            GuideBody = "WHAT IT DOES:\r\n" +
                        "There are ZERO hardcoded addon titles or pitches. Every click of '1. Discover New Autonomous Ideas' picks 8 unvisited high-versatility seed bricks from Trough_AtomicConcepts.tsv, pairs them with 3 compatible organs from other addons that share the exact same WoW API family, and presents a brand-new generation of circuits!"
        });

        StudioManualTopics.Add(new ManualTopic() {
            SectionNum = "TOPIC 2.0",
            Title = "Stateless Micro-Window Local LLM Concept Inventor",
            Category = "Stateless Local LLM Brain",
            Keywords = "ollama llm codegemma phi-3 llama-3 invent title bridge",
            GuideBody = "WHAT IT DOES:\r\n" +
                        "When you click '2. Micro-LLM Synthesize', your Local LLM warms up in RAM, inspects the 4 discovered functions, invents a custom Addon Name & Pitch (updating the table row with '[LLM] <Invented Name>'), and writes the Lua adapter bridges in 3 fresh 2,048-token steps!"
        });
    }

    public static void WriteStudioReadmeAndAiManual(string studioDir, int uItems, int uSpells, int uSets, int uQuests, Action<string> logCallback) {
        if (!Directory.Exists(studioDir)) Directory.CreateDirectory(studioDir);
        InitializeSearchableManualTopics();
        UTF8Encoding utf8NoBom = new UTF8Encoding(false);

        DataRipperEngine.SaveAddonInventoryTableToDisk(studioDir);

        string readmePath  = Path.Combine(studioDir, "STUDIO_README_AND_AI_ARCHITECTURE.md");
        string handoffPath = Path.Combine(studioDir, "AI_MASTER_LIBRARY_HANDOFF.txt");
        string snipPath    = Path.Combine(DataRipperEngine.ResolveTroughDir(studioDir), "Trough_CodeVault.tsv");

        using (StreamWriter sw = new StreamWriter(readmePath, false, utf8NoBom)) {
            sw.WriteLine("# DECONSTRUCTION GOD STUDIO v14.1 - USER MANUAL & AI ARCHITECTURE");
            for (int i = 0; i < StudioManualTopics.Count; i++) {
                ManualTopic t = StudioManualTopics[i];
                sw.WriteLine("## " + t.SectionNum + ": " + t.Title);
                sw.WriteLine(t.GuideBody);
                sw.WriteLine("");
            }
        }

        Dictionary<string, int> legoCounts = new Dictionary<string, int>();
        Dictionary<string, string> legoIdeas = new Dictionary<string, string>();
        Dictionary<string, List<CodeSnippet>> legoBestSamples = new Dictionary<string, List<CodeSnippet>>();

        if (File.Exists(snipPath)) {
            using (StreamReader sr = new StreamReader(snipPath, Encoding.UTF8)) {
                string ln;
                while ((ln = sr.ReadLine()) != null) {
                    if (string.IsNullOrWhiteSpace(ln)) continue;
                    string[] c = ln.Split('\t');
                    if (c.Length < 15) continue;

                    string lTag = c[9];
                    if (!legoCounts.ContainsKey(lTag)) {
                        legoCounts[lTag] = 0;
                        legoIdeas[lTag]  = c[10];
                        legoBestSamples[lTag] = new List<CodeSnippet>();
                    }
                    legoCounts[lTag]++;

                    if (lTag == "Lego_Utility_And_Math") continue;

                    int stLn = 0; int endLn = 0;
                    int.TryParse(c[11], out stLn);
                    int.TryParse(c[12], out endLn);
                    int span = endLn - stLn + 1;
                    if (span < 12 || span > 80) continue;

                    CodeSnippet cs = ParseSnippetRowFromTsv(c);
                    if (cs.SynergyScore >= 80) {
                        List<CodeSnippet> sampleList = legoBestSamples[lTag];
                        bool sameAddonExists = false;
                        for (int k = 0; k < sampleList.Count; k++) {
                            if (sampleList[k].AddonName == cs.AddonName) {
                                sameAddonExists = true;
                                if (cs.SynergyScore > sampleList[k].SynergyScore) sampleList[k] = cs;
                                break;
                            }
                        }
                        if (!sameAddonExists && sampleList.Count < 5) {
                            sampleList.Add(cs);
                        }
                    }
                }
            }
        }

        using (StreamWriter sw = new StreamWriter(handoffPath, false, utf8NoBom)) {
            sw.WriteLine("================================================================================");
            sw.WriteLine("DECONSTRUCTION GOD STUDIO v14.1 - MASTER AI HANDOFF & 648-ADDON FORGE AUDIT");
            sw.WriteLine("Generated UTC: " + DateTime.UtcNow.ToString("yyyy-MM-dd HH:mm:ss"));
            sw.WriteLine("Parents: " + DataRipperEngine.AddonStatsList.Count + " | Data IDs: " + DataRipperEngine.TotalSavedDataRecordsOnDisk + " | Code Blocks: " + TotalSavedSnippetsOnDisk + " | Creative Bricks: " + TotalSavedCreativeBricksOnDisk);
            sw.WriteLine("================================================================================");
            sw.WriteLine("SECTION 1.0: PARENT ADDON SCOREBOARD (" + DataRipperEngine.AddonStatsList.Count + " Parents)");
            sw.WriteLine("--------------------------------------------------------------------------------");
            for (int i = 0; i < DataRipperEngine.AddonStatsList.Count; i++) {
                AddonTelemetry st = DataRipperEngine.AddonStatsList[i];
                sw.WriteLine(string.Format(
                    "  * Parent: {0,-30} :: Status:{1,-20} :: Folders:{2,3} :: Files:{3,4} :: Data IDs:{4,6} :: Code Blocks:{5,5} :: Creative Bricks:{6,4}",
                    st.AddonName, st.StatusBadge, st.TotalFolders, st.TotalFiles, st.DataRecordsCount, st.FunctionsCount, st.CreativeBricksCount
                ));
            }
            sw.WriteLine("");
            sw.WriteLine("================================================================================");
            sw.WriteLine("SECTION 2.0: TOP HIGH-SYNERGY CREATIVE BRICKS (WITH PRECISION SOCKET DNA)");
            sw.WriteLine("================================================================================");
            foreach (var kvp in legoCounts) {
                string tag = kvp.Key;
                int count  = kvp.Value;
                string idea = legoIdeas.ContainsKey(tag) ? legoIdeas[tag] : "";
                sw.WriteLine("### CREATIVE LEGO CATEGORY: " + tag + " (Total Harvested Blocks: " + count + ")");
                sw.WriteLine("    Frankenstein Repurpose Idea: " + idea);
                if (legoBestSamples.ContainsKey(tag)) {
                    List<CodeSnippet> samps = legoBestSamples[tag];
                    for (int sIdx = 0; sIdx < samps.Count; sIdx++) {
                        CodeSnippet cs = samps[sIdx];
                        sw.WriteLine(string.Format(
                            "    [{0}] Synergy:{1}/100 | Parent:{2} | Sig:{3} | Sockets:{4} -> {5} | File:{6}:{7}-{8} | APIs:{9}",
                            (sIdx + 1), cs.SynergyScore, cs.AddonName, cs.Signature, cs.InputSockets, cs.OutputPlugs, cs.RelativePath, cs.StartLine, cs.EndLine, cs.ApisUsed
                        ));
                        string preview = GetSnippetPreviewLinesOnDemand(cs.FullFilePath, cs.StartLine, cs.EndLine, 12);
                        sw.WriteLine(preview);
                        sw.WriteLine("    ----------------------------------------------------------------------------");
                    }
                }
                sw.WriteLine("");
            }
        }
        logCallback("Updated STUDIO_README_AND_AI_ARCHITECTURE.md and AI_MASTER_LIBRARY_HANDOFF.txt (v14.3 Speed, Upvalue Graph & Donor Scout Ready!)");
    }

    // ========================================================================
    // v14.3 CURSEFORGE / WAGO / GITHUB PRIME DONOR ADDON SCOUT & GAP ANALYZER
    // Cross-checks elite donor addons & live GitHub WoW repositories against
    // the 648-Addon Vault to rank the highest-yield targets for deconstruction!
    // ========================================================================
    private static bool IsDonorAddonInVault(string candidateKey, out string matchedVaultFolder, out int vaultFuncs, out int vaultBricks, out int vaultDataIds) {
        matchedVaultFolder = "";
        vaultFuncs = 0;
        vaultBricks = 0;
        vaultDataIds = 0;
        string[] aliases = candidateKey.Split('/');
        for (int a = 0; a < aliases.Length; a++) {
            string tok = aliases[a].Trim();
            if (tok.Length == 0) continue;
            AddonTelemetry exact;
            if (DataRipperEngine.AddonStatsMap.TryGetValue(tok, out exact)) {
                matchedVaultFolder = exact.AddonName;
                vaultFuncs = exact.FunctionsCount;
                vaultBricks = exact.CreativeBricksCount;
                vaultDataIds = exact.DataRecordsCount;
                return true;
            }
            for (int i = 0; i < DataRipperEngine.AddonStatsList.Count; i++) {
                AddonTelemetry st = DataRipperEngine.AddonStatsList[i];
                if (st.AddonName.IndexOf(tok, StringComparison.OrdinalIgnoreCase) >= 0) {
                    matchedVaultFolder = st.AddonName;
                    vaultFuncs += st.FunctionsCount;
                    vaultBricks += st.CreativeBricksCount;
                    vaultDataIds += st.DataRecordsCount;
                }
            }
            if (!string.IsNullOrEmpty(matchedVaultFolder)) return true;
        }
        return false;
    }

    public static string ScoutPrimeDonorAddonsReport(string studioDir, string searchQuery) {
        if (DataRipperEngine.AddonStatsList.Count == 0) {
            string invPath = Path.Combine(DataRipperEngine.ResolveTroughDir(studioDir), "Trough_AddonsInventory.tsv");
            if (File.Exists(invPath)) {
                try {
                    using (StreamReader sr = new StreamReader(invPath, Encoding.UTF8)) {
                        string ln;
                        while ((ln = sr.ReadLine()) != null) {
                            if (string.IsNullOrWhiteSpace(ln)) continue;
                            string[] c = ln.Split('\t');
                            if (c.Length >= 15) {
                                AddonTelemetry st = DataRipperEngine.GetOrCreateAddonTelemetry(c[0], c[1]);
                                int.TryParse(c[9], out st.DataRecordsCount);
                                int.TryParse(c[13], out st.FunctionsCount);
                                if (c.Length >= 16) int.TryParse(c[15], out st.CreativeBricksCount);
                            }
                        }
                    }
                } catch {}
            }
        }

        string[][] matrix = new string[][] {
            // { AliasKey, DisplayName, Category, YieldScore, CurseForgeSlug, TargetOrgansToRip, WhyPrimeForDeconstruction }
            new string[] { "Narcissus", "Narcissus (3D Photo Studio & Turntable)", "3D_ModelScene_And_DressUp", "99", "curseforge.com/wow/addons/narcissus", "ModelSceneActor lighting, custom race/gender mannequin camera interpolation, equipment flyout shaders, skeletal animation sequencers", "Gold-standard 3D character showcase, custom lighting rigs, and multi-actor posing math." },
            new string[] { "BetterWardrobe/BetterWardrobe_SourceData", "BetterWardrobe and Transmog", "3D_ModelScene_And_DressUp", "98", "curseforge.com/wow/addons/better-wardrobe-and-transmog", "3D preview grid matrix, extra armor set aggregation, dressing room slot masking, illusion preview hooks", "Solves multi-slot try-on sets, hidden slot toggling, and high-density 3D model grids." },
            new string[] { "MogIt", "MogIt (Classic & Retail 3D Wishlist Grid)", "3D_ModelScene_And_DressUp", "97", "curseforge.com/wow/addons/mogit", "Multi-race/gender DressUpModel recycling pool, camera zoom/pan per armor slot, wishlist string serializer", "Specifically engineered for Classic/TBC/Wrath DressUpModel race/sex switching and slot-specific camera framing." },
            new string[] { "EnhancedTransmogBrowser", "EnhancedTransmogBrowser", "3D_ModelScene_And_DressUp", "96", "curseforge.com/wow/addons/enhanced-transmog-browser", "Cross-era item displayID tables, model preview cell recycler, instant search index", "Massive displayID-to-item mapping tables + fast 3D model grid pagination." },
            new string[] { "ChonkyCharacterSheet", "ChonkyCharacterSheet", "3D_ModelScene_And_DressUp", "93", "curseforge.com/wow/addons/chonky-character-sheet", "Expanded paperdoll stat breakdown, socket/enchant inspection overlays, modern character frame skinning", "High-polish paperdoll slot overlays and stat parser math." },

            new string[] { "TradeSkillMaster/TSM_Core", "TradeSkillMaster (TSM Core Quant Engine)", "Auction_And_Economy_Quants", "99", "curseforge.com/wow/addons/tradeskill-master", "Custom virtualized UI table engine, compressed price database strings, crafting profit graph solver, sniper state machine", "Contains the most advanced Lua virtualized scroll tables, expression evaluators, and crafting profit math in WoW." },
            new string[] { "Auctionator", "Auctionator", "Auction_And_Economy_Quants", "96", "curseforge.com/wow/addons/auctionator", "Incremental scan coroutines, historical price day-bucketing, shopping list filter parser, 1-click undercut calculator", "Cleanest modular coroutine scanner and lightweight historical price compression for Classic & Retail." },
            new string[] { "Aux-Addon/aux", "Aux (Classic Auction House Quant Terminal)", "Auction_And_Economy_Quants", "95", "github.com/shirsig/aux-addon", "Multi-threaded Lua query coroutine pipeline, vendor flip margin scorer, historical median price estimator", "Pure Classic/Vanilla auction house quant engine with ultra-fast page scanning and flip scoring." },
            new string[] { "Journalator", "Journalator (Gold Ledger & Flip Accounting)", "Auction_And_Economy_Quants", "91", "curseforge.com/wow/addons/journalator", "Invoice/mail/trade gold flow tracker, time-series profit/loss aggregator", "Ideal donor for tracking arbitrage ROI, vendor flips, and crafting margins across alts." },

            new string[] { "Baganator", "Baganator", "Virtualized_Bags_And_GuildBank", "97", "curseforge.com/wow/addons/baganator", "Zero-lag item button pool, instant cross-character Syndicate cache, category rule compiler, guild bank tab snapshots", "Ultra-fast modern item button pooling and multi-character offline bag/bank search." },
            new string[] { "Syndicator", "Syndicator (Cross-Alt Item & Currency Indexer)", "Virtualized_Bags_And_GuildBank", "96", "curseforge.com/wow/addons/syndicator", "Event-driven bag/bank/mail/VoidStorage delta indexer, instant item-count tooltip aggregator", "Decoupled data layer that indexes every item across all alts, banks, auctions, and mails." },
            new string[] { "BetterBags", "BetterBags", "Virtualized_Bags_And_GuildBank", "94", "curseforge.com/wow/addons/betterbags", "2D section grid layout engine, smooth slot animations, custom item category filter predicates", "Cleanest OOP frame pooling and dynamic multi-section grid math." },
            new string[] { "AdiBags", "AdiBags", "Virtualized_Bags_And_GuildBank", "91", "curseforge.com/wow/addons/adibags", "Rule-based virtual stacker, new-item glow pulse engine, modular filter plugins", "Great filter plugin architecture for auto-grouping BoEs, recipes, and consumables." },

            new string[] { "Masque", "Masque (Universal Button Skinning Engine)", "Procedural_UI_And_Animations", "96", "curseforge.com/wow/addons/masque", "Normal/Pushed/Highlight/Cooldown/Border texture layer compositor, custom mask regions", "Lets you skin any item/spell button in AltVault with metallic, dark-glass, or neon borders." },
            new string[] { "WeakAuras/WeakAuras2", "WeakAuras", "Procedural_UI_And_Animations", "99", "curseforge.com/wow/addons/weakauras-2", "Custom animation curve interpolators, texture atlas rotator, dynamic group grid arranger, state machine triggers", "The ultimate library of procedural Lua animations, glow shaders, progress textures, and event triggers." },
            new string[] { "LibCustomGlow", "LibCustomGlow-1.0", "Procedural_UI_And_Animations", "94", "curseforge.com/wow/addons/libcustomglow", "PixelGlow, AutoCastGlow, and ButtonGlow particle/line animators using pure texture pools", "Zero-dependency procedural glowing borders for BiS items, Sync Beacons, and rare alerts." },
            new string[] { "ElvUI", "ElvUI (Core Skinning & Layout Engine)", "Procedural_UI_And_Animations", "97", "tukui.org/elvui", "Pixel-perfect UI scale math, flat dark-theme frame skinners, custom scrollbars, mover snap grid", "Complete library of functions to strip ugly default Blizzard textures and apply modern flat borders." },
            new string[] { "DialogueUI/Plumber", "DialogueUI & Plumber", "Procedural_UI_And_Animations", "95", "curseforge.com/wow/addons/dialogueui", "Smooth spring-physics frame transitions, parchment/dark-mode quest cards, custom keybind pills", "Next-gen UI micro-interactions, smooth alpha/position easing curves, and typography." },

            new string[] { "Questie", "Questie", "Quest_Recipe_And_Loot_Databases", "98", "curseforge.com/wow/addons/questie", "Binary-packed Quest/NPC/Object/Item relational DB, spatial quadtree map pins, prerequisite chain solver", "Complete relational graph of every Classic/TBC/Wrath quest, NPC drop, vendor, and coordinate." },
            new string[] { "AllTheThings", "AllTheThings (ATT)", "Quest_Recipe_And_Loot_Databases", "99", "curseforge.com/wow/addons/all-the-things", "Hierarchical sourcelist graph (Zone -> NPC -> Quest -> Item -> Recipe), completion bitmask tracker", "Deepest cross-referenced item/recipe acquisition tree in existence." },
            new string[] { "AtlasLootClassic/AtlasLootContinued", "AtlasLoot (Classic & Continued)", "Quest_Recipe_And_Loot_Databases", "97", "curseforge.com/wow/addons/atlaslootclassic", "Dungeon/Raid boss loot tables, faction rep rewards, PvP sets, crafting recipe reagent trees", "Core boss drop and tier set tables across difficulties and phases." },
            new string[] { "MissingTradeSkillsList/MTSL", "MissingTradeSkillsList (MTSL)", "Quest_Recipe_And_Loot_Databases", "96", "curseforge.com/wow/addons/missing-tradeskills-list", "Every Profession Recipe -> Trainer/Vendor/Quest/WorldDrop source with min skill, faction, and coordinates", "The #1 donor specifically for 'Quest for Recipe' trainer/vendor/quest acquisition coordinates!" },
            new string[] { " LoonBestInSlot/Bistooltip", "LoonBestInSlot (LBIS)", "Quest_Recipe_And_Loot_Databases", "93", "curseforge.com/wow/addons/loon-best-in-slot", "Phase-by-phase BiS rankings per Class/Spec/Slot with exact acquisition source tags", "Ideal for automatic BiS badge scoring and spec gear recommendations." },

            new string[] { "Details", "Details! Damage Meter", "Combat_And_Timeline_Telemetry", "97", "curseforge.com/wow/addons/details", "High-frequency CLEU ring buffer, custom line/bar chart renderer, boss encounter segmenter", "Blazing fast combat log parser and custom canvas graph/sparkline drawing engine." },
            new string[] { "Plater", "Plater Nameplates", "Combat_And_Timeline_Telemetry", "96", "curseforge.com/wow/addons/plater-nameplates", "Nameplate unit lifecycle pool, 3D/2D nameplate badge attachments, castbar interrupt flashers", "Direct donor for upgrading open-world Nameplate Beacons and guildmate HUD badges." },

            new string[] { "TotalRP3/totalRP3", "Total RP 3 (TRP3)", "Network_Sync_And_Social_Profiles", "98", "curseforge.com/wow/addons/total-rp-3", "Chunked whisper/channel profile sync protocol, character biography/directory UI, map scan broadcast", "The closest architectural cousin to FaceVault's social profile directory and chunked peer syncing!" },
            new string[] { "LibDeflate", "LibDeflate + LibSerialize", "Network_Sync_And_Social_Profiles", "96", "curseforge.com/wow/addons/libdeflate", "Pure-Lua DEFLATE LZ77/Huffman compression & 6-bit addon channel/whisper byte encoder", "Compresses sync payloads by 70-85% so 5x more profile/inventory data fits in a single whisper." },
            new string[] { "Altoholic/DataStore", "Altoholic + DataStore Suite", "Network_Sync_And_Social_Profiles", "95", "curseforge.com/wow/addons/altoholic", "Bit-packed alt inventory/talent/recipe/cooldown schemas, cross-account guild bank sync", "Proven multi-alt data schemas and profession cooldown trackers." }
        };

        string q = (searchQuery ?? "").Trim().ToLowerInvariant();
        List<string> missingLines = new List<string>();
        List<string> presentLines = new List<string>();
        int missingCount = 0;
        int presentCount = 0;

        for (int i = 0; i < matrix.Length; i++) {
            string[] row = matrix[i];
            if (q.Length > 0) {
                string hay = (row[0] + " " + row[1] + " " + row[2] + " " + row[5] + " " + row[6]).ToLowerInvariant();
                if (!hay.Contains(q)) continue;
            }

            string matchedFolder;
            int vFuncs, vBricks, vData;
            bool inVault = IsDonorAddonInVault(row[0], out matchedFolder, out vFuncs, out vBricks, out vData);

            if (!inVault) {
                missingCount++;
                StringBuilder sbItem = new StringBuilder();
                sbItem.AppendLine(string.Format("  [*] [MISSING PRIME TARGET #{0}] {1}  |  Deconstruction Yield: {2}/100  |  Domain: [{3}]", missingCount, row[1], row[3], row[2]));
                sbItem.AppendLine("      Source URL      : https://" + row[4]);
                sbItem.AppendLine("      Organs to Rip   : " + row[5]);
                sbItem.AppendLine("      Why We Want It  : " + row[6]);
                sbItem.AppendLine("  ------------------------------------------------------------------------------");
                missingLines.Add(sbItem.ToString());
            } else {
                presentCount++;
                StringBuilder sbItem = new StringBuilder();
                sbItem.AppendLine(string.Format("  [OK] [ALREADY IN VAULT #{0}] {1}  (Matched Folder: '{2}' | Yield: {3}/100)", presentCount, row[1], matchedFolder, row[3]));
                sbItem.AppendLine(string.Format("      Harvested Stats : {0:N0} Code Blocks | {1:N0} Creative Bricks | {2:N0} Data IDs", vFuncs, vBricks, vData));
                sbItem.AppendLine("      Available Organs: " + row[5]);
                sbItem.AppendLine("  ------------------------------------------------------------------------------");
                presentLines.Add(sbItem.ToString());
            }
        }

        // Live GitHub Public WoW Lua Addon Repository Discovery (fast 3.5s timeout, TLS 1.2)
        List<string> liveWebHits = new List<string>();
        try {
            ServicePointManager.SecurityProtocol = (SecurityProtocolType)3072;
            string ghQuery = "wow+addon+lua" + (q.Length > 0 ? ("+" + Uri.EscapeDataString(q)) : "");
            string ghUrl = "https://api.github.com/search/repositories?q=" + ghQuery + "&sort=stars&order=desc&per_page=10";
            HttpWebRequest req = (HttpWebRequest)WebRequest.Create(ghUrl);
            req.Method = "GET";
            req.UserAgent = "DeconstructionGodStudio/14.3";
            req.Accept = "application/vnd.github.v3+json";
            req.Timeout = 3500;
            using (HttpWebResponse resp = (HttpWebResponse)req.GetResponse())
            using (StreamReader sr = new StreamReader(resp.GetResponseStream(), Encoding.UTF8)) {
                string json = sr.ReadToEnd();
                Regex rxRepo = new Regex(@"""full_name""\s*:\s*""([^""]+)""[\s\S]{1,600}?""html_url""\s*:\s*""([^""]+)""[\s\S]{1,600}?""description""\s*:\s*(?:""((?:[^""\\]|\\.)*)""|null)[\s\S]{1,1200}?""stargazers_count""\s*:\s*(\d+)");
                MatchCollection mc = rxRepo.Matches(json);
                for (int m = 0; m < mc.Count && liveWebHits.Count < 8; m++) {
                    string fullName = mc[m].Groups[1].Value;
                    string htmlUrl  = mc[m].Groups[2].Value;
                    string desc     = UnescapeJsonString(mc[m].Groups[3].Value);
                    string stars    = mc[m].Groups[4].Value;
                    string repoShort = fullName.Contains("/") ? fullName.Split('/')[1] : fullName;

                    string mf; int vf, vb, vd;
                    bool hasIt = IsDonorAddonInVault(repoShort, out mf, out vf, out vb, out vd);
                    string badge = hasIt ? ("[IN VAULT as '" + mf + "']") : "[NEW WEB CANDIDATE [*]]";
                    liveWebHits.Add(string.Format("  * {0,-28} | [*] {1,5} stars | {2}\r\n      URL : {3}\r\n      Desc: {4}", repoShort, stars, badge, htmlUrl, desc));
                }
            }
        } catch {}

        StringBuilder sb = new StringBuilder();
        sb.AppendLine("================================================================================");
        sb.AppendLine("DECONSTRUCTION GOD STUDIO v14.3 - CURSEFORGE / WAGO / GITHUB DONOR ADDON SCOUT");
        sb.AppendLine("Vault Cross-Check: " + DataRipperEngine.AddonStatsList.Count + " Parent Addons Indexed | Filter: '" + (q.Length > 0 ? q : "ALL DOMAINS") + "'");
        sb.AppendLine("================================================================================");
        sb.AppendLine("");
        sb.AppendLine("### SECTION 1: PRIME MISSING DONOR TARGETS TO FEED THE COOKIE MONSTER (" + missingCount + " Missing)");
        sb.AppendLine("(Download any of these from CurseForge/GitHub and drag-and-drop into Studio to rip their organs!)");
        sb.AppendLine("================================================================================");
        if (missingLines.Count == 0) {
            sb.AppendLine("  All curated donor targets for this filter are already in your Vault!");
        } else {
            for (int i = 0; i < missingLines.Count; i++) sb.Append(missingLines[i]);
        }
        sb.AppendLine("");
        sb.AppendLine("### SECTION 2: LIVE GITHUB WOW ADDON REPOSITORY SCOUT (" + liveWebHits.Count + " Live Web Hits)");
        sb.AppendLine("================================================================================");
        if (liveWebHits.Count == 0) {
            sb.AppendLine("  (Live GitHub API query skipped or rate-limited; use Omni-Search box to filter specific keywords)");
        } else {
            for (int i = 0; i < liveWebHits.Count; i++) sb.AppendLine(liveWebHits[i]);
        }
        sb.AppendLine("");
        sb.AppendLine("### SECTION 3: ELITE DONORS ALREADY HARVESTED IN YOUR 648-ADDON VAULT (" + presentCount + " Ready)");
        sb.AppendLine("(You already have these! Jump to Tab [3] Code Store to search their harvested Creative Bricks!)");
        sb.AppendLine("================================================================================");
        for (int i = 0; i < presentLines.Count; i++) sb.Append(presentLines[i]);

        return sb.ToString();
    }
}
