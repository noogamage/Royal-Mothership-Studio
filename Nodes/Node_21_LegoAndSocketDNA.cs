// ============================================================================
// DECONSTRUCTION GOD STUDIO v14.3 - MODULAR NODE SYSTEM
// NODE INDEX  : [21] OF [35]
// FILE NAME   : Node_21_LegoAndSocketDNA.cs
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
    // SECTION 5.0: PRECISION SOCKET/PLUG DNA, SYNERGY SCORE & 18 LEGO CLASSIFIERS
    // ========================================================================
    private static string ClassifyFeatureIntent(string funcName, string body, string addonName, string lang) {
        if (lang == "C++" || lang == "C" || lang == "C/C++ Header" || lang == "C++ Header" || lang == "C#" || lang == "Python" || lang == "SQL") {
            string sysCheck = (funcName + " " + body).ToUpperInvariant();
            if (sysCheck.Contains("BAG") || sysCheck.Contains("INVENTORY") || sysCheck.Contains("SORT")) return "Bag_And_Inventory_Sorting";
            return "External_CPlusPlus_Python_SQL";
        }

        string uAddon = addonName.ToUpperInvariant();
        string text   = (addonName + " " + funcName + " " + body).ToUpperInvariant();

        if (uAddon.Contains("BAGNON") || uAddon.Contains("BAGANATOR") || uAddon.Contains("BAGBROTHER") || uAddon.Contains("BETTERBAGS") || text.Contains("SORTBAGS") || text.Contains("CONTAINERFRAME") || text.Contains("C_CONTAINER") || text.Contains("BAGSLOT") || text.Contains("ITEMBUTTON") || text.Contains("GUILDBANK")) {
            return "Bag_And_Inventory_Sorting";
        }
        if (uAddon.Contains("ATLASLOOT") || uAddon.Contains("DUNGEONJOURNAL") || uAddon.Contains("ALLTHETHINGS")) {
            if (text.Contains("BUTTON") || text.Contains("DROPDOWN") || text.Contains("FRAME") || text.Contains("SCROLL") || text.Contains("MODEL") || text.Contains("ITEM")) {
                return "Loot_Browser_And_Dropdown_UI";
            }
        }
        if (text.Contains("HOOKSECUREFUNC") || text.Contains("ONUPDATE") || text.Contains("AUTOSELL") || text.Contains("AUTOREPAIR") || text.Contains("GARGUL") || text.Contains("LOOTROLL")) {
            return "Automation_And_Hooks";
        }
        if (text.Contains("GAMETOOLTIP") || text.Contains("TOOLTIPDATAPROCESSOR") || text.Contains("SETITEMBYID") || text.Contains("SETHYPERLINK") || uAddon.Contains("BISTOOLTIP")) {
            return "Tooltips_And_BiS";
        }
        if (text.Contains("SECUREUNITBUTTON") || text.Contains("HEALBOT") || text.Contains("INCOMINGHEAL") || text.Contains("UNITHEALTH") || text.Contains("CLEANSE") || text.Contains("RAIDFRAME")) {
            return "UnitFrames_And_Heal";
        }
        if (uAddon.Contains("DBM") || uAddon.Contains("BIGWIGS") || text.Contains("COMBAT_LOG_EVENT") || text.Contains("ENCOUNTER_START") || text.Contains("SPELL_CAST_START")) {
            return "Boss_Timers_And_Alerts";
        }
        if (text.Contains("C_NAMEPLATE") || text.Contains("NAME_PLATE_UNIT") || text.Contains("THREAT") || text.Contains("CASTBAR")) {
            return "Nameplates_And_HUD";
        }
        if (text.Contains("C_MAP") || text.Contains("QUESTIE") || text.Contains("HEREBEDRAGONS") || text.Contains("WORLDMAP") || text.Contains("MINIMAP")) {
            return "Map_Quests_And_Coords";
        }
        if (text.Contains("AUCTION") || text.Contains("GETAUCTION") || text.Contains("C_AUCTIONHOUSE") || text.Contains("VENDORPRICE")) {
            return "Auction_And_Economy";
        }
        if (text.Contains("SENDADDONMESSAGE") || text.Contains("CHAT_MSG_ADDON") || text.Contains("LIBDEFLATE") || text.Contains("ACESERIALIZER") || uAddon.Contains("DATASTORE") || uAddon.Contains("ALTOHOLIC")) {
            return "DataStore_Network_And_Sync";
        }
        if (text.Contains("C_TRAITS") || text.Contains("C_CLASSTALENTS") || text.Contains("C_SPELL") || text.Contains("BACKDROPTEMPLATE")) {
            return "Forever_16001_ModernAPI";
        }
        if (text.Contains("TRADESKILL") || text.Contains("C_TRADESKILLUI") || text.Contains("CRAFT") || text.Contains("REAGENT")) {
            return "Professions_And_Crafting";
        }
        if (text.Contains("CREATEFRAME") || text.Contains("SETPOINT") || text.Contains("SCROLLFRAME") || text.Contains("SLIDER") || text.Contains("EDITBOX")) {
            return "Frames_And_UI_Layout";
        }

        return "General_Logic_And_Utils";
    }

    private static void ClassifyCreativeLegoBrick(string funcName, string body, string addonName, string lang, int lineSpan, out string legoTag, out string frankensteinIdea) {
        string u = (funcName + " " + body).ToUpperInvariant();

        if (lineSpan < 5 && !u.Contains("SETMETATABLE") && !u.Contains("HOOKSECUREFUNC") && !u.Contains("CREATEFRAMEPOOL")) {
            legoTag = "Lego_Utility_And_Math";
            frankensteinIdea = "Compact helper/getter from " + addonName + ".";
            return;
        }

        if (u.Contains("WOW_PROJECT_ID") || u.Contains("GETBUILDINFO") || (u.Contains("C_CONTAINER") && u.Contains("GETCONTAINERITEMINFO")) || (u.Contains("C_ITEM") && u.Contains("GETITEMINFO")) || (u.Contains("TOOLTIPDATAPROCESSOR") && u.Contains("ONTOOLTIPSETITEM"))) {
            legoTag = "Lego_Polyfill_And_Compat_Shim";
            frankensteinIdea = "Universal cross-expansion polyfill wrapper -> Makes addon code run seamlessly across 3.3.5a, Classic, Wrath, and Retail.";
            return;
        }

        if (u.Contains("CREATEFRAMEPOOL") || u.Contains("CREATEOBJECTPOOL") || u.Contains("ACQUIRE(") || u.Contains("RELEASEALL(") || (u.Contains("POOL") && u.Contains("TREMOVE"))) {
            legoTag = "Lego_Frame_And_Object_Pool";
            frankensteinIdea = "Zero-lag UI frame/widget recycling pool -> Pair with any Grid Matrix or Nameplate HUD to eliminate garbage collection stutter.";
            return;
        }

        if (u.Contains("COMBATLOGGETCURRENTEVENTINFO") || u.Contains("SPELL_DAMAGE") || u.Contains("SPELL_AURA_APPLIED") || u.Contains("UNIT_DIED") || u.Contains("SWING_DAMAGE")) {
            legoTag = "Lego_CombatLog_SubEvent_Parser";
            frankensteinIdea = "Real-time CombatLog subevent parser -> Feed output into TactiVision threat bars, custom DPS meters, or boss alert triggers.";
            return;
        }

        if (u.Contains("SETATTRIBUTE") || u.Contains("SECUREACTIONBUTTON") || u.Contains("REGISTERSTATEDRIVER") || u.Contains("INCOMBATLOCKDOWN")) {
            legoTag = "Lego_Secure_Action_Macro";
            frankensteinIdea = "Combat-safe SecureActionButton / StateDriver logic -> Pair with UnitFrames or custom action buttons for 1-click spell/item use.";
            return;
        }

        if (u.Contains("ATAN2") || u.Contains("SETROTATION") || u.Contains("GETPLAYERMAPPOSITION") || u.Contains("HEREBEDRAGONS") || u.Contains("WORLDMAPFRAME") || (u.Contains("DIST") && u.Contains("SQRT"))) {
            legoTag = "Lego_Spatial_And_Pin_Math";
            frankensteinIdea = "2D coordinate distance, waypoint arrow rotation, or map pin projection -> Pair with QuestieDB/GatherMate2 node tables.";
            return;
        }

        if (u.Contains("CHATFRAME_ADDMESSAGEEVENTFILTER") || u.Contains("|HITEM:") || u.Contains("|H") || u.Contains("SETITEMREF") || u.Contains("CHAT_MSG_LOOT")) {
            legoTag = "Lego_Hyperlink_And_Chat_Filter";
            frankensteinIdea = "Chat stream interceptor or custom clickable |H hyperlink builder -> Use for clickable loot alerts or chat command links.";
            return;
        }

        if (rxTrueModuloMath.IsMatch(body) || ((u.Contains("ROWHEIGHT") || u.Contains("COLWIDTH") || u.Contains("NUMCOLS") || u.Contains("MAXDISPLAYEDROWS")) && u.Contains("SETPOINT")) || (u.Contains("SETPOINT") && (u.Contains("IPAIRS") || u.Contains("FOR ")) && (u.Contains("BUTTON") || u.Contains("SLOT") || u.Contains("ICON")))) {
            legoTag = "Lego_UI_Grid_Matrix";
            frankensteinIdea = "Dynamic icon/slot grid or virtualized scroll row layout -> Feed an Item/Spell table array into this to render a live matrix.";
            return;
        }

        if (u.Contains("STRFIND") || u.Contains("STRING.FIND") || u.Contains("STRING.MATCH") || u.Contains("STRMATCH") || u.Contains("STRING.LOWER") || u.Contains("TABLE.SORT") || (u.Contains("FILTER") && u.Contains("SEARCH"))) {
            legoTag = "Lego_Search_And_Filter";
            frankensteinIdea = "Real-time text search, fuzzy matcher, or comparator sort -> Place between a raw DB table and a UI Grid Matrix.";
            return;
        }

        if (u.Contains("ONUPDATE") || u.Contains("C_TIMER.AFTER") || u.Contains("C_TIMER.NEWTICKER") || u.Contains("COROUTINE") || u.Contains("C_CREATE") || u.Contains("YIELD")) {
            legoTag = "Lego_Async_Throttle_Engine";
            frankensteinIdea = "Non-blocking coroutine or frame-budget throttle -> Wrap around heavy AH scans or 200,000-row DB queries for zero FPS drop.";
            return;
        }

        if (u.Contains("GAMETOOLTIP") || u.Contains("ADDLINE") || u.Contains("ADDDOUBLELINE") || u.Contains("TOOLTIPDATAPROCESSOR") || u.Contains("ONTOOLTIPSETITEM")) {
            legoTag = "Lego_Tooltip_Data_Injector";
            frankensteinIdea = "Tooltip hook & line injector -> Connect an ItemID/SpellID data lookup plug straight into this tooltip renderer.";
            return;
        }

        if (u.Contains("SETBACKDROP") || u.Contains("CREATEANIMATIONGROUP") || u.Contains("CREATETEXTURE") || u.Contains("SETGRADIENT") || u.Contains("SETVERTEXCOLOR") || u.Contains("UIDROPDOWNMENU") || u.Contains("SCROLLFRAME")) {
            legoTag = "Lego_Custom_Widget_Skin";
            frankensteinIdea = "Custom dark UI skinning, dropdown, scrollframe, or animation -> Graft onto any UI Frame for pro visual polish.";
            return;
        }

        if (u.Contains("HOOKSECUREFUNC") || u.Contains("SETSCRIPT") || u.Contains("HOOKSCRIPT")) {
            legoTag = "Lego_Hook_And_Automation";
            frankensteinIdea = "Secure hook or interactive script trigger -> Intercept default Blizzard frames or automate clicks/actions.";
            return;
        }

        if (u.Contains("SENDADDONMESSAGE") || u.Contains("SERIALIZE") || u.Contains("COMPRESS") || u.Contains("LIBDEFLATE") || u.Contains("DECOMPRESS") || u.Contains("BIT.BAND") || u.Contains("BIT.LSHIFT") || u.Contains("STRSPLIT")) {
            legoTag = "Lego_Data_Compression_Sync";
            frankensteinIdea = "Data packing, bitmasking, or addon channel sync -> Use for compact SavedVariables or cross-player guild data sync.";
            return;
        }

        if (u.Contains("SETMETATABLE") || u.Contains("__INDEX") || u.Contains("__NEWINDEX") || u.Contains("__CALL")) {
            legoTag = "Lego_Metatable_OOP_Engine";
            frankensteinIdea = "Metatable class inheritance or lazy-loading table router -> Use for zero-memory on-demand database lookups.";
            return;
        }

        if (u.Contains("REGISTEREVENT") || u.Contains("UNIT_AURA") || u.Contains("BAG_UPDATE") || u.Contains("PLAYER_ENTERING_WORLD")) {
            legoTag = "Lego_State_Event_Router";
            frankensteinIdea = "Event-driven state dispatcher -> Use as the trigger plug to fire Data Producers and UI Renderers.";
            return;
        }

        if (lang != "Lua" && lang != "XML") {
            legoTag = "Lego_CrossLang_Algorithm";
            frankensteinIdea = lang + " algorithm/schema from " + addonName + " -> Port logic or SQL structure into your Lua/Python tools.";
            return;
        }

        legoTag = "Lego_Utility_And_Math";
        frankensteinIdea = "Reusable helper logic from " + addonName + " -> Combine with UI or database modules.";
    }

    private static void AnalyzeCodeCompatibilityAndSynergy(
        string addonName,
        string funcName,
        string sig,
        string body,
        string cat,
        string legoTag,
        int lineSpan,
        int apiCount,
        int eventCount,
        out int synergyScore,
        out string inputSockets,
        out string outputPlugs
    ) {
        string uSig  = sig.ToUpperInvariant();
        string uBody = body.ToUpperInvariant();

        List<string> ins  = new List<string>(4);
        List<string> outs = new List<string>(4);

        if (uSig.Contains("ITEM") || uSig.Contains("LINK") || uSig.Contains("BAG") || uSig.Contains("SLOT") || uBody.Contains("GETITEMINFO") || uBody.Contains("C_CONTAINER") || uBody.Contains("C_ITEM")) {
            ins.Add("Socket_Item");
        }
        if (uSig.Contains("AUCTION") || uSig.Contains("PRICE") || uSig.Contains("COPPER") || uSig.Contains("BID") || uSig.Contains("BUYOUT") || uBody.Contains("C_AUCTIONHOUSE")) {
            ins.Add("Socket_Auction_Gold");
        }
        if (uSig.Contains("SPELL") || uSig.Contains("AURA") || uSig.Contains("BUFF") || uSig.Contains("COOLDOWN") || uBody.Contains("GETSPELLINFO") || uBody.Contains("C_SPELL") || uBody.Contains("UNIT_AURA")) {
            ins.Add("Socket_Spell_Aura");
        }
        if (uSig.Contains("UNIT") || uSig.Contains("GUID") || uSig.Contains("TARGET") || uSig.Contains("PLATE") || uBody.Contains("UNITEXISTS") || uBody.Contains("UNITHEALTH") || uBody.Contains("C_NAMEPLATE")) {
            ins.Add("Socket_Unit_GUID");
        }
        if (uSig.Contains("MAP") || uSig.Contains("ZONE") || uSig.Contains("COORD") || uSig.Contains("QUEST") || uBody.Contains("C_MAP") || uBody.Contains("HEREBEDRAGONS")) {
            ins.Add("Socket_Map_Coord");
        }
        if (uSig.Contains("PREFIX") || uSig.Contains("SENDER") || uSig.Contains("CHANNEL") || uBody.Contains("SENDADDONMESSAGE") || uBody.Contains("DECOMPRESS")) {
            ins.Add("Socket_Chat_Comm");
        }

        if (uSig.Contains("LIST") || uSig.Contains("TABLE") || uSig.Contains("ARRAY") || uSig.Contains("RESULTS") || uSig.Contains("GROUP") || uBody.Contains("IPAIRS(") || uBody.Contains("TABLE.SORT")) {
            ins.Add("Socket_Table_Array");
        }
        if (uSig.Contains("FRAME") || uSig.Contains("BUTTON") || uSig.Contains("TOOLTIP") || uSig.Contains("ROW") || uSig.Contains("SCROLL") || uBody.Contains(":SETPOINT") || uBody.Contains("GAMETOOLTIP") || uBody.Contains("CREATEFRAME")) {
            ins.Add("Socket_UI_Frame");
        }
        if (ins.Count == 0) ins.Add("Socket_Generic");

        if (uBody.Contains("RETURN ") && (uBody.Contains("TABLE.INSERT") || uBody.Contains("TINSERT") || uBody.Contains("= {}") || uSig.Contains("BUILD") || uSig.Contains("FILTER") || uSig.Contains("GET"))) {
            outs.Add("Plug_Table_Dataset");
        }
        if (uBody.Contains(":ADDLINE") || uBody.Contains(":ADDDOUBLELINE") || uBody.Contains("GAMETOOLTIP:SHOW") || legoTag == "Lego_Tooltip_Data_Injector") {
            outs.Add("Plug_Tooltip_Lines");
        }
        if (uBody.Contains("CREATEFRAME") || uBody.Contains(":SETPOINT") || uBody.Contains(":SETTEXTURE") || uBody.Contains(":SETTEXT") || legoTag == "Lego_UI_Grid_Matrix" || legoTag == "Lego_Custom_Widget_Skin") {
            outs.Add("Plug_UI_Visual_Render");
        }
        if (uBody.Contains("SENDADDONMESSAGE") || uBody.Contains("SERIALIZE") || uBody.Contains("COMPRESS") || legoTag == "Lego_Data_Compression_Sync") {
            outs.Add("Plug_Network_Packet");
        }
        if (uBody.Contains("C_TIMER") || uBody.Contains("COROUTINE") || uBody.Contains("ONUPDATE") || legoTag == "Lego_Async_Throttle_Engine" || legoTag == "Lego_Frame_And_Object_Pool") {
            outs.Add("Plug_Async_Scheduler");
        }
        if (uBody.Contains("RETURN ")) {
            if (ins.Contains("Socket_Item")) outs.Add("Plug_Item_Data");
            else if (ins.Contains("Socket_Spell_Aura")) outs.Add("Plug_Spell_Data");
            else if (ins.Contains("Socket_Unit_GUID")) outs.Add("Plug_Unit_State");
            else if (ins.Contains("Socket_Map_Coord")) outs.Add("Plug_Map_Waypoint");
            else outs.Add("Plug_Computed_Value");
        }
        if (outs.Count == 0) outs.Add("Plug_State_Mutation");

        inputSockets = string.Join(",", ins);
        outputPlugs  = string.Join(",", outs);

        int score = 30;
        if (legoTag != "Lego_Utility_And_Math") score += 28;
        if (lineSpan >= 10 && lineSpan <= 120) score += 22;
        else if (lineSpan > 120 && lineSpan <= 350) score += 16;
        else if (lineSpan > 350 && lineSpan <= 1000) score += 10;
        else if (lineSpan >= 5 && lineSpan < 10) score += 4;
        else if (lineSpan < 5) score -= 22;

        if (apiCount > 0) score += Math.Min(apiCount * 5, 15);
        if (eventCount > 0) score += 8;
        if (uBody.Contains("RETURN ")) score += 6;
        if (uBody.Contains("IPAIRS") || uBody.Contains("PAIRS(") || uBody.Contains("MATH.")) score += 5;

        // v14.3 Algorithmic & Architectural Genius Boosters (O(1) fast substring checks)
        if (uBody.Contains("BIT.BAND") || uBody.Contains("BIT.LSHIFT") || uBody.Contains("BIT.BXOR") || uBody.Contains("LIBDEFLATE") || uBody.Contains("COMPRESS") || uBody.Contains("SERIALIZE")) {
            score += 8;
        }
        if (uBody.Contains("DRESSUPMODEL") || uBody.Contains("MODELSCENE") || uBody.Contains("SETCUSTOMRACE") || uBody.Contains(":TRYON(") || uBody.Contains(":SETCREATURE(") || uBody.Contains(":SETLIGHT(")) {
            score += 8;
        }
        if (uBody.Contains("COROUTINE.") || uBody.Contains("C_TIMER.NEWTICKER") || uBody.Contains("CONTINUEONITEMLOAD")) {
            score += 7;
        }
        if (uBody.Contains("CREATEFRAMEPOOL") || uBody.Contains("CREATEOBJECTPOOL") || uBody.Contains(":ACQUIRE(") || uBody.Contains(":RELEASEALL(") || uBody.Contains("HYBRIDSCROLLFRAME") || uBody.Contains("FAUXSCROLLFRAME")) {
            score += 7;
        }
        if (uBody.Contains("TABLE.SORT") || uBody.Contains("MATH.ATAN2") || uBody.Contains("MATH.SQRT")) {
            score += 5;
        }

        // Trivial Getter Penalty: keep < 5 line simple getters from crowding top synergy ranks
        if (lineSpan < 5 && apiCount == 0 && eventCount == 0 && legoTag == "Lego_Utility_And_Math") {
            if (score > 35) score = 35;
        }

        if (score < 5) score = 5;
        if (score > 100) score = 100;
        synergyScore = score;
    }
}
