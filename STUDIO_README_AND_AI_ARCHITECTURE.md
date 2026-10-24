================================================================================
MASTER AI HANDOFF & ARCHITECTURAL CONTINUITY BRIEFING (UPDATED 2026-10-20)
ECOSYSTEM VERSION: DeconstructionGod_Studio v14.3 + AltVault v3.1 (Stealth Mode)
================================================================================

0. CRITICAL CONSTRAINTS & STANDING ORDERS FOR ANY FUTURE AI:
--------------------------------------------------------------------------------
1) NEVER TOUCH BACKUP:
   Never modify, move, or delete c:\Program Files (x86)\World of Warcraft\_classic_beta_\Interface\AddOns\Backup.
2) THREE ACTIVE PROJECT DIRECTORIES:
   * Folder 1 (In-Game Addon): c:\Program Files (x86)\World of Warcraft\_classic_beta_\Interface\AddOns\AltVault
   * Folder 2 (Desktop Harvester & AI Forge): c:\Program Files (x86)\World of Warcraft\_classic_beta_\Interface\AddOns\DeconstructionGod_Studio
   * Folder 3 (Consolidated 1,083-Addon Vault & SQL Trough): C:\Users\seanw\OneDrive\Desktop\wow forever addons (and Portable_SQL_Trough\)
3) SPEED & STEALTH ARE PARAMOUNT:
   * DeconstructionGod_Studio must maintain its Zero-RAM streaming speed.
   * AltVault must remain in strict **Stealth / Clean-Citizen Mode** (5.22 MB total Lua/DB footprint, 0 idle timers, 0 unsolicited server item queries, 0 YELL addon broadcasts, 0 passive-mouseover whispers, 0 UI taint).

--------------------------------------------------------------------------------
1. CONSOLIDATED DATA TROUGH STATUS (Portable_SQL_Trough\)
--------------------------------------------------------------------------------
* Consolidated Third-Party Addon Folders : 1,083 folders in C:\Users\seanw\OneDrive\Desktop\wow forever addons
  (All third-party addons across _anniversary_, _classic_, _classic_beta_, _classic_era_, and _retail_ were devoured and consolidated here so _classic_beta_\Interface\AddOns stays clean with only AltVault, DeconstructionGod_Studio, and Backup.)
* Trough_AddonsInventory.tsv           : 965 unique parent sources (addons, SavedVariables, client binaries/logs)
* Trough_CodeVault.tsv                 : 528,199 unique code blocks (119,734 Creative Lego Bricks, 269,149+ [Upvalues: ...] chains)
* Trough_Blueprints.tsv                : 120,899 blueprints, hooks & native engine APIs
* Trough_EngineAPIs_1_60_1.tsv         : 8,811 native C++ symbols ripped from WowB.exe (1.60.1.70450)
  - 294 C_* namespaces, 2,072 native events, 6,415 global APIs/methods, 28 C++ widget classes
* Trough_DatasetSchemas.tsv            : 5,209 structured dataset schemas
* Trough_GameDataRecords.tsv           : 1,186,335+ game data records, including:
  - 88,924 Forever relational IDs ripped via upgraded Node_11_DataRegexAndHelpers.cs & Node_12_DataParsers.cs
  - 33,701 live server DB2 hotfix records (Item, ItemSparse, ItemSearchName, SpellActionBarPref, QuestV2, Spell, CooldownSetSpell, TradeSkillItem) ripped from _classic_beta_\Logs\Hotfix.log (Region 70, cfgContentSetID: 137)
* Trough_PointsOfInterest.tsv          : 150 High-Priority Forever 1.60.1 Points of Interest across 6 Pillars:
  - Pillar_0_Client_Binary_Engine (Hotfix.log live stream, General.log LimitedLuaResources 500-Timer quota bypass, Cache\ADB\enUS\DBCache.bin & *Sparse.tmp, Cache\WDB\enUS\*.wdb, FrameXML.log diagnostics)
  - Pillar_1_HyperLeveling (XP curves, C_GossipInfo/C_QuestLog automation, 7,329 GPS coordinates)
  - Pillar_2_GoldDominance (No-level white Twink Enchant Bases #7005, #2901, #14092, #6238; Badlands quest bottlenecks #3829, #4389, #3864; Disenchant EV matrices; unlimited vendor arbitrage)
  - Pillar_3_AltSynergy (Race/Class/Profession synergy matrix, 28-spec BiS, 31-spec Pawn stat weights, 4,330 recipe [Orange/Yellow/Green/Grey] skill-up brackets)
  - Pillar_4_WorldRadar (C_VignetteInfo 100+ yd pre-nameplate rare/chest detection, UNIT_TARGET raid scanner, COMBAT_LOG_EVENT_UNFILTERED enemy CD tracker)
  - Pillar_5_Engine_Bypass (1-Timer Coroutine Ring-Buffer Scheduler, Frame/FontString Object Pool, Binary-Search String Packing)

--------------------------------------------------------------------------------
2. DECONSTRUCTION GOD STUDIO v14.3 UPGRADES (DeconstructionGod_Studio\)
--------------------------------------------------------------------------------
* Modular C# Architecture (Studio_Manifest.toc + Nodes\Node_10..Node_35.cs, synced to Engine_DataRipper.cs & Engine_CodeHarvester.cs):
  - Node_11_DataRegexAndHelpers.cs & Node_12_DataParsers.cs: Added 4 new Forever table parsers (xBareNumKeyStringVal, xBareNumKeyNumTuple, xCsvFirstNumLine, xQuotedNameThresholdTuple).
  - Node_13_AltVaultBridge.cs: Upgraded Lua raw blob output from [[ ... ]] to [===[ ... ]===] and sanitized inner brackets so Lua 5.1 never triggers 
esting of [[...]] is deprecated.
  - Node_32_GuiTab2_SqlTrough.cs: Added Classic_Forever_16001 Era filter and Hotfix_* Type filters to Tab [2] (SQL Trough).
  - Node_35_GuiTab6_AddonForge.cs: Added the Matrix POIs (150) button to Tab [6] (Addon Forge) so all 150 Points of Interest from Trough_PointsOfInterest.tsv can be browsed, searched, inspected, and wired into the Micro-LLM Inventor.

--------------------------------------------------------------------------------
3. ALTVAULT v3.1 STEALTH, LIGHTWEIGHT & INTELLIGENCE OVERHAUL (AltVault\)
--------------------------------------------------------------------------------
* 96.8% Memory & Disk Reduction (164.2 MB -> 5.22 MB total across all 26 Lua files):
  - Replaced the 19 multi-expansion DB_TankNode_01..19.lua files (161.3 MB) with a single 2.4 MB Forever-16001-Curated DB_Tank\DB_TankNode_01.lua (18,000 authentic Classic/Forever records) and updated AltVault.toc and Core_MasterLootIndex.lua to unpack MasterDB.RawBlobs lazily on demand and immediately free the raw strings.
* Fixed All 3 Client Log Lua Errors (FrameXML.log & General.log):
  1) DB_TankNode [[...]] delimiter nesting -> Fixed via [===[ ... ]===] delimiters.
  2) DB_ForeverVaultData.lua:44440 nil global GQ -> Fixed GQ.ScoringWeightLabels to FVD.ScoringWeightLabels, unlocking all 7,329 GPS item coordinates in FVD.Coordinates.
  3) Engine_ForeverVaultIntelligence.lua HydrateIntoMasterDB table collision -> Replaced 31,000-table login hydration loop with zero-allocation ForeverIndex:GetAllIDs(), eliminating both the MasterDB.ByItemID type collision and 15,534 static entries in AltVaultDB.SourceDB SavedVariables.
* Stealth & Zero-Footprint Guards:
  - 0 Idle Timers: Net_RadioAndChat.lua uses an on-demand timer (EnsureRadioDrainRunning) that runs only while sendQueue is non-empty and cancels itself when #sendQueue == 0.
  - 0 Unsolicited Server Queries: Core_TalentsAndCrawler.lua defaults AltVaultDB.ScannerPaused = true and, when manually resumed, steps ONLY through verified ForeverIndex:GetAllIDs() item IDs (never blind-querying invalid IDs).
  - Silent Comms: Removed "YELL" / "SAY" addon broadcasts and set peer.isSynced = false (isPublicFaceVault = true) on passive mouseover players in RecordPlayerEncounter so passive encounters are never whispered.
* 4 Event-Driven In-Game Forever Advantage Modules (Engine_ForeverVaultIntelligence.lua):
  1) Live Rare & Vignette Radar (VIGNETTE_MINIMAP_UPDATED + clickable [📍 Lock 3D GPS Pin] chat link)
  2) Quest Turn-In Max-Gold & BiS Evaluator (QUEST_COMPLETE highest vendor payout + Official Forever BiS alert)
  3) Hyper-Leveling Next-Upgrades Solver (/avintel upgrades with clickable 1-click 3D GPS links)
  4) Gold Arbitrage, Alt Synergy & Stealth Telemetry Suite (/avintel, /avintel gold, /avintel alt)

================================================================================
# DECONSTRUCTION GOD STUDIO v14.1 - USER MANUAL & AI ARCHITECTURE
## TOPIC 1.0: Zero-Hardcode Emergent Discovery & Seed Rotation (v14.1)
WHAT IT DOES:
There are ZERO hardcoded addon titles or pitches. Every click of '1. Discover New Autonomous Ideas' picks 8 unvisited high-versatility seed bricks from Trough_AtomicConcepts.tsv, pairs them with 3 compatible organs from other addons that share the exact same WoW API family, and presents a brand-new generation of circuits!

## TOPIC 2.0: Stateless Micro-Window Local LLM Concept Inventor
WHAT IT DOES:
When you click '2. Micro-LLM Synthesize', your Local LLM warms up in RAM, inspects the 4 discovered functions, invents a custom Addon Name & Pitch (updating the table row with '[LLM] <Invented Name>'), and writes the Lua adapter bridges in 3 fresh 2,048-token steps!

