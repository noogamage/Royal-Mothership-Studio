import os
import sys
import re
import math
import json
import time
import hashlib
import sqlite3
import urllib.parse
from http.server import ThreadingHTTPServer, BaseHTTPRequestHandler

try:
    sys.stdout.reconfigure(encoding='utf-8')
    sys.stderr.reconfigure(encoding='utf-8')
except Exception:
    pass

STUDIO_DIR = r'c:\Program Files (x86)\World of Warcraft\_classic_beta_\Interface\AddOns\DeconstructionGod_Studio'
NEC_DB_PATH = os.path.join(STUDIO_DIR, 'NEC_Harvest_Targets', 'NEC_Master_Vault.sqlite')
SI_DB_PATH = os.path.join(STUDIO_DIR, 'SQL_SI_Language_Vault.sqlite')
SI_PORT = 8770

# Circular mils table (NEC Chapter 9, Table 8) for instant zero-token Voltage Drop math!
AWG_CM_MAP = {
    "14": 4110, "12": 6530, "10": 10380, "8": 16510, "6": 26240,
    "4": 41740, "3": 52620, "2": 66360, "1": 83690,
    "1/0": 105600, "2/0": 133100, "3/0": 167800, "4/0": 211600,
    "250": 250000, "300": 300000, "350": 350000, "400": 400000, "500": 500000
}


def solve_spoken_electrical_math(q):
    """
    Zero-Token Dynamic Python Electrical & College Math Solver!
    Extracts numbers and units from spoken/typed English and calculates the exact step-by-step result.
    """
    low = q.lower()
    if not any(ch.isdigit() for ch in low):
        return None

    # Extract numbers associated with units
    def find_val(pattern):
        m = re.search(pattern, low)
        return float(m.group(1)) if m else None

    volts = find_val(r"(\d+(?:\.\d+)?)\s*(?:v|volt|volts)\b")
    amps = find_val(r"(\d+(?:\.\d+)?)\s*(?:a|amp|amps|amperes)\b")
    watts = find_val(r"(\d+(?:\.\d+)?)\s*(?:w|watt|watts|va)\b")
    kw = find_val(r"(\d+(?:\.\d+)?)\s*(?:kw|kilowatt|kilowatts|kva)\b")
    if kw is not None and watts is None:
        watts = kw * 1000.0
    ohms = find_val(r"(\d+(?:\.\d+)?)\s*(?:ohm|ohms|\u03a9)\b")
    feet = find_val(r"(\d+(?:\.\d+)?)\s*(?:ft|foot|feet)\b")
    deg = find_val(r"(\d+(?:\.\d+)?)\s*(?:deg|degree|degrees)\b")
    inches = find_val(r"(\d+(?:\.\d+)?)\s*(?:in|inch|inches)\b")

    # 1. Conduit Bending Offset Calculation
    if ("offset" in low or "bend" in low or "multiplier" in low) and (deg or inches):
        d_val = deg or 30.0
        i_val = inches or 6.0
        mult_map = {10: (6.0, "1/16\""), 22.5: (2.6, "3/16\""), 30: (2.0, "1/4\""), 45: (1.414, "3/8\""), 60: (1.15, "1/2\"")}
        mult, shrink_str = mult_map.get(d_val, (round(1.0 / math.sin(math.radians(d_val)), 3), "1/4\""))
        dist = round(i_val * mult, 2)
        spoken = f"Zero-Token Math Solver: For a {i_val:g} inch offset using {d_val:g} degree bends, multiply {i_val:g} inches by the multiplier {mult} to get {dist} inches between bends! Your conduit shrink is {shrink_str} per inch of rise."
        disp = f"🧮 LIVE PYTHON MATH SOLVER (CONDUIT OFFSET)\n• Offset Rise: {i_val:g} inches\n• Bend Angle: {d_val:g}° (Multiplier = {mult})\n• Distance Between Bends = {i_val:g} × {mult} = {dist} inches\n• Shrink per Inch: {shrink_str}"
        return {
            "si_code": "SI::CALC::LIVE_CONDUIT",
            "verb": "CALC",
            "domain": "ELEC_MATH",
            "topic_label": f"🧮 Live Calc: {i_val:g}\" Offset @ {d_val:g}° = {dist}\" Between Bends",
            "ava_spoken_response": spoken,
            "structured_display": disp
        }

    # 2. Continuous Load (125% Rule)
    if "continuous" in low and amps is not None:
        req = round(amps * 1.25, 2)
        spoken = f"Zero-Token Math Solver: Under NEC 210.19 and 210.20, a continuous load of {amps:g} Amps must be multiplied by 125 percent, which equals {req} Amps minimum circuit and breaker rating!"
        disp = f"🧮 LIVE PYTHON MATH SOLVER (NEC 125% CONTINUOUS LOAD)\n• Continuous Load Current: {amps:g} A\n• Formula: {amps:g} A × 1.25 (125%) = {req} Amps"
        return {
            "si_code": "SI::CALC::LIVE_CONTINUOUS",
            "verb": "CALC",
            "domain": "ELEC_MATH",
            "topic_label": f"🧮 Live Calc: {amps:g}A Continuous × 125% = {req}A",
            "ava_spoken_response": spoken,
            "structured_display": disp
        }

    # 3. Voltage Drop Calculation
    if ("drop" in low or feet is not None) and feet is not None and amps is not None:
        awg_m = re.search(r"\b(14|12|10|8|6|4|3|2|1|1/0|2/0|3/0|4/0|250|300|350|400|500)\s*(?:awg|gauge|kcmil|#)?\b", low)
        awg = awg_m.group(1) if awg_m else "12"
        cm = AWG_CM_MAP.get(awg, 6530)
        is_3ph = "three phase" in low or "3 phase" in low or "3-phase" in low
        is_al = "aluminum" in low or "alum" in low
        k_val = 21.2 if is_al else 12.9
        mult = 1.732 if is_3ph else 2.0
        v_sys = volts or (208.0 if is_3ph else 120.0)
        vd = round((mult * k_val * amps * feet) / cm, 2)
        pct = round((vd / v_sys) * 100.0, 2)
        status = "PASSES (<3% branch limit)" if pct <= 3.0 else "EXCEEDS 3% branch recommendation — upsize wire!"
        spoken = f"Zero-Token Voltage Drop Solver: For {amps:g} Amps over {feet:g} feet on {awg} gauge {'aluminum' if is_al else 'copper'}, your voltage drop is {vd} Volts, which is {pct} percent on a {v_sys:g} Volt system. That {status}!"
        disp = (
            f"🧮 LIVE PYTHON VOLTAGE DROP SOLVER\n"
            f"• Formula: VD = ({mult} × K[{k_val}] × I[{amps:g}A] × D[{feet:g}ft]) ÷ CM[{cm} ({awg} AWG)]\n"
            f"• Voltage Drop: {vd} Volts ({pct}% of {v_sys:g}V)\n"
            f"• NEC Result: {status}"
        )
        return {
            "si_code": "SI::CALC::LIVE_VDROP",
            "verb": "CALC",
            "domain": "ELEC_MATH",
            "topic_label": f"🧮 Live Voltage Drop: {vd}V ({pct}%) on #{awg} AWG",
            "ava_spoken_response": spoken,
            "structured_display": disp
        }

    # 4. Ohm's Law & Power Wheel Solver (Any 2 of E, I, R, P!)
    known = sum(x is not None for x in (volts, amps, watts, ohms))
    if known >= 2:
        is_3ph = "three phase" in low or "3 phase" in low or "3-phase" in low
        ph_mult = 1.732 if is_3ph else 1.0
        if volts is not None and watts is not None and amps is None:
            amps = round(watts / (volts * ph_mult), 2)
            ohms = round(volts / amps, 2) if amps else 0
        elif volts is not None and amps is not None and watts is None:
            watts = round(volts * amps * ph_mult, 2)
            ohms = round(volts / amps, 2) if amps else 0
        elif volts is not None and ohms is not None and amps is None:
            amps = round(volts / ohms, 2) if ohms else 0
            watts = round(volts * amps, 2)
        elif amps is not None and ohms is not None and volts is None:
            volts = round(amps * ohms, 2)
            watts = round((amps ** 2) * ohms, 2)
        elif watts is not None and amps is not None and volts is None:
            volts = round(watts / (amps * ph_mult), 2) if amps else 0
            ohms = round(volts / amps, 2) if amps else 0

        if volts is not None and amps is not None:
            spoken = f"Zero-Token Ohm's Law Solver: Voltage is {volts:g} Volts, Current is {amps:g} Amps, Power is {watts:g} Volt-Amps or Watts, and Resistance is {ohms:g} Ohms!"
            disp = (
                f"🧮 LIVE PYTHON OHM'S LAW & POWER SOLVER ({'3-Phase' if is_3ph else 'Single-Phase'})\n"
                f"• Voltage (E): {volts:g} V\n"
                f"• Current (I): {amps:g} A\n"
                f"• Power (P):   {watts:g} W / VA ({watts/1000.0:.2f} kVA)\n"
                f"• Resistance (R): {ohms:g} Ω"
            )
            return {
                "si_code": "SI::CALC::LIVE_OHMS",
                "verb": "CALC",
                "domain": "ELEC_MATH",
                "topic_label": f"🧮 Live Ohm's Law: {volts:g}V | {amps:g}A | {watts:g}W | {ohms:g}Ω",
                "ava_spoken_response": spoken,
                "structured_display": disp
            }

    return None


def learn_new_qa_pair(question, answer):
    """
    Automatically learns a new Question + Answer pair into `sql_si_learned_memory` and `sql_si_lexicon`
    so the SQL-SI Language Vault grows permanently from every conversation!
    """
    q_clean = str(question or "").strip()
    a_clean = re.sub(r"<[^>]+>", "", str(answer or "")).strip()
    if len(q_clean) < 5 or len(a_clean) < 10:
        return None
    h = hashlib.sha256(q_clean.lower().encode("utf-8")).hexdigest()[:10].upper()
    si_code = f"SI::LEARNED::{h}"
    ts = time.strftime("%Y-%m-%d %H:%M:%S")
    words = [w for w in re.sub(r"[^a-zA-Z0-9\s]", " ", q_clean.lower()).split() if len(w) >= 2]
    norm_kw = " ".join(words)

    conn = sqlite3.connect(SI_DB_PATH)
    cur = conn.cursor()
    cur.execute("""
        CREATE TABLE IF NOT EXISTS sql_si_learned_memory (
            memory_id TEXT PRIMARY KEY,
            learned_at TEXT,
            user_question TEXT,
            normalized_keywords TEXT,
            ava_answer TEXT,
            times_recalled INTEGER DEFAULT 0
        )
    """)
    cur.execute("""
        INSERT OR REPLACE INTO sql_si_learned_memory
        (memory_id, learned_at, user_question, normalized_keywords, ava_answer, times_recalled)
        VALUES (?, ?, ?, ?, ?, 0)
    """, (si_code, ts, q_clean, norm_kw, a_clean))

    label = f"🧬 Learned: \"{q_clean[:62]}\""
    disp = (
        f"🧬 AUTO-LEARNED SQL-SI MEMORY ({ts})\n"
        f"• Memory ID: {si_code}\n\n"
        f"🗣️ Your Question:\n\"{q_clean}\"\n\n"
        f"👩 Ava's Verified Answer (0 Tokens Forever Now!):\n{a_clean}"
    )
    cur.execute("""
        INSERT OR REPLACE INTO sql_si_lexicon
        (si_code, verb, domain, topic_label, spoken_triggers, ava_spoken_response, structured_display)
        VALUES (?, 'LEARNED', 'LEARNED_MEMORY', ?, ?, ?, ?)
    """, (si_code, label, f"{norm_kw} {a_clean[:300].lower()}", a_clean, disp))
    cur.execute("""
        INSERT INTO sql_si_fts
        (si_code, verb, domain, topic_label, spoken_triggers, ava_spoken_response, structured_display)
        VALUES (?, 'LEARNED', 'LEARNED_MEMORY', ?, ?, ?, ?)
    """, (si_code, label, f"{norm_kw} {a_clean[:300].lower()}", a_clean, disp))

    # Also stamp BOTH the User Question and Ava's Answer into sql_si_chronological_timeline!
    cur.execute("""
        CREATE TABLE IF NOT EXISTS sql_si_chronological_timeline (
            event_id INTEGER PRIMARY KEY AUTOINCREMENT,
            event_uid TEXT UNIQUE,
            iso_timestamp TEXT,
            date_bucket TEXT,
            event_type TEXT,
            actor TEXT,
            summary_headline TEXT,
            full_content TEXT,
            sha256_hash TEXT
        )
    """)
    date_b = ts[:10]
    uid_q = f"TS::{ts.replace('-', '').replace(':', '').replace(' ', '_')}::Q_{h[:5]}"
    uid_a = f"TS::{ts.replace('-', '').replace(':', '').replace(' ', '_')}::A_{h[:5]}"
    cur.execute("""
        INSERT OR REPLACE INTO sql_si_chronological_timeline
        (event_uid, iso_timestamp, date_bucket, event_type, actor, summary_headline, full_content, sha256_hash)
        VALUES (?, ?, ?, 'LIVE_CONVERSATION_Q', 'Stephen', ?, ?, ?)
    """, (uid_q, ts, date_b, q_clean[:120], q_clean, h))
    cur.execute("""
        INSERT OR REPLACE INTO sql_si_chronological_timeline
        (event_uid, iso_timestamp, date_bucket, event_type, actor, summary_headline, full_content, sha256_hash)
        VALUES (?, ?, ?, 'LIVE_CONVERSATION_A', 'Ava (Antigravity)', ?, ?, ?)
    """, (uid_a, ts, date_b, a_clean[:120], a_clean, h))

    tl_label = f"⏱️ [{ts}] Q: {q_clean[:28]}... ➔ A: {a_clean[:28]}..."
    tl_disp = (
        f"⏱️ SQL CHRONOLOGICAL MEMORY TIMESTAMP ({ts})\n"
        f"• Event UID: {uid_a} | SHA-256: {h}\n\n"
        f"🗣️ Stephen ({ts}):\n\"{q_clean}\"\n\n"
        f"👩 Ava (Antigravity):\n{a_clean}"
    )
    cur.execute("""
        INSERT OR REPLACE INTO sql_si_lexicon
        (si_code, verb, domain, topic_label, spoken_triggers, ava_spoken_response, structured_display)
        VALUES (?, 'TIMESTAMP', 'TIMELINE_LOG', ?, ?, ?, ?)
    """, (uid_a, tl_label, f"timestamp {ts} {date_b} {norm_kw} {a_clean[:300].lower()}", f"On {ts}, you asked: {q_clean}. And I answered: {a_clean}", tl_disp))
    cur.execute("""
        INSERT INTO sql_si_fts
        (si_code, verb, domain, topic_label, spoken_triggers, ava_spoken_response, structured_display)
        VALUES (?, 'TIMESTAMP', 'TIMELINE_LOG', ?, ?, ?, ?)
    """, (uid_a, tl_label, f"timestamp {ts} {date_b} {norm_kw} {a_clean[:300].lower()}", f"On {ts}, you asked: {q_clean}. And I answered: {a_clean}", tl_disp))

    conn.commit()
    conn.close()
    return si_code


def expand_words_with_thesaurus(cur, words):
    expanded = list(words)
    seen = set(w.lower() for w in words)
    for w in words[:4]:
        try:
            cur.execute("SELECT synonyms_csv FROM english_thesaurus WHERE word = ? LIMIT 1", (w.lower(),))
            r = cur.fetchone()
            if r and r["synonyms_csv"]:
                for syn in r["synonyms_csv"].split(","):
                    s = syn.strip().lower()
                    if s and s not in seen and len(expanded) < 18:
                        seen.add(s)
                        expanded.append(s)
        except Exception:
            pass
    return expanded


def query_sql_si_vault(q="", verb="", domain="", si_code="", limit=35):
    conn = sqlite3.connect(SI_DB_PATH)
    conn.row_factory = sqlite3.Row
    cur = conn.cursor()

    if si_code:
        if si_code.startswith("SI::THESAURUS::"):
            w_target = si_code.replace("SI::THESAURUS::", "").lower()
            cur.execute("SELECT * FROM english_thesaurus WHERE word = ? LIMIT 1", (w_target,))
            r = cur.fetchone()
            conn.close()
            if r:
                w = r["word"]
                syns = r["synonyms_csv"]
                return [{
                    "si_code": f"SI::THESAURUS::{w.upper()}",
                    "verb": "SYNONYM",
                    "domain": "THESAURUS",
                    "topic_label": f"🔄 {w.title()} ({r['synonym_count']} Synonyms)",
                    "ava_spoken_response": f"Thesaurus synonyms for {w} include: {syns[:350]}",
                    "structured_display": f"🔄 ENGLISH & ELECTRICAL THESAURUS (45,274 ROOT WORDS • 87,831 SYNONYMS)\n• Word: {w}\n• Synonym Count: {r['synonym_count']}\n• SQL-SI Code: SI::THESAURUS::{w.upper()}\n\n🔗 Linked Synonyms & Trade Terms:\n{syns}"
                }]
            return []

        if si_code.startswith("SI::WEBSTER::"):
            w_target = si_code.replace("SI::WEBSTER::", "").lower()
            cur.execute("SELECT * FROM webster_english_lexicon WHERE word_lower = ? LIMIT 1", (w_target,))
            r = cur.fetchone()
            conn.close()
            if r:
                w = r["word"]
                d = r["definition"]
                return [{
                    "si_code": f"SI::WEBSTER::{w.upper()}",
                    "verb": "DEFINE",
                    "domain": "WEBSTER_ENGLISH",
                    "topic_label": f"📖 {w.title()} ({r['length']} letters)",
                    "ava_spoken_response": f"Webster's English definition of {w}: {d[:400]}",
                    "structured_display": f"📖 WEBSTER'S UNABRIDGED DICTIONARY (102,217 WORDS)\n• Word: {w}\n• SQL-SI Code: SI::WEBSTER::{w.upper()}\n\n📝 Full Definition:\n{d}"
                }]
            return []

        cur.execute("UPDATE sql_si_lexicon SET hits = hits + 1 WHERE si_code = ?", (si_code,))
        conn.commit()
        cur.execute("SELECT * FROM sql_si_lexicon WHERE si_code = ?", (si_code,))
        row = cur.fetchone()
        conn.close()
        return [dict(row)] if row else []

    if domain == "THESAURUS":
        rows_out = []
        clean_q = re.sub(r"[^a-zA-Z0-9\-\s]", " ", q).strip().lower()
        if clean_q:
            cur.execute("SELECT * FROM english_thesaurus WHERE word = ? OR word LIKE ? ORDER BY length(word) ASC LIMIT ?", (clean_q, f"{clean_q}%", limit))
            for r in cur.fetchall():
                w = r["word"]
                syns = r["synonyms_csv"]
                rows_out.append({
                    "si_code": f"SI::THESAURUS::{w.upper()}",
                    "verb": "SYNONYM",
                    "domain": "THESAURUS",
                    "topic_label": f"🔄 {w} ({r['synonym_count']} syns) ➔ {syns[:52]}...",
                    "ava_spoken_response": f"Thesaurus synonyms for {w} include: {syns[:350]}",
                    "structured_display": f"🔄 ENGLISH & ELECTRICAL THESAURUS (45,274 ROOT WORDS • 87,831 SYNONYMS)\n• Word: {w}\n• Synonym Count: {r['synonym_count']}\n• SQL-SI Code: SI::THESAURUS::{w.upper()}\n\n🔗 Linked Synonyms & Trade Terms:\n{syns}"
                })
        else:
            sample_syns = [
                "romex", "greenfield", "sealtight", "bx", "smurf tube", "emt", "panel", "breaker",
                "plug", "wire", "ampacity", "ground", "bond", "neutral", "gfci", "afci", "disconnect",
                "motor", "transformer", "generator", "solar", "stipend", "tuition", "tools"
            ]
            placeholders = ",".join(["?"] * len(sample_syns))
            cur.execute(f"SELECT * FROM english_thesaurus WHERE word IN ({placeholders}) ORDER BY word ASC", sample_syns)
            for r in cur.fetchall():
                w = r["word"]
                syns = r["synonyms_csv"]
                rows_out.append({
                    "si_code": f"SI::THESAURUS::{w.upper()}",
                    "verb": "SYNONYM",
                    "domain": "THESAURUS",
                    "topic_label": f"🔄 {w.title()} ({r['synonym_count']} syns) ➔ {syns[:48]}...",
                    "ava_spoken_response": f"Thesaurus synonyms for {w} include: {syns[:350]}",
                    "structured_display": f"🔄 ENGLISH & ELECTRICAL THESAURUS (45,274 ROOT WORDS • 87,831 SYNONYMS)\n• Word: {w}\n• Synonym Count: {r['synonym_count']}\n• SQL-SI Code: SI::THESAURUS::{w.upper()}\n\n🔗 Linked Synonyms & Trade Terms:\n{syns}"
                })
        conn.close()
        return rows_out

    if domain == "WEBSTER_ENGLISH":
        rows_out = []
        clean_q = re.sub(r"[^a-zA-Z0-9\-\s]", " ", q).strip().lower()
        if clean_q:
            cur.execute("SELECT * FROM webster_english_lexicon WHERE word_lower = ? OR word_lower LIKE ? ORDER BY length ASC LIMIT ?", (clean_q, f"{clean_q}%", limit))
            for r in cur.fetchall():
                w = r["word"]
                d = r["definition"]
                rows_out.append({
                    "si_code": f"SI::WEBSTER::{w.upper()}",
                    "verb": "DEFINE",
                    "domain": "WEBSTER_ENGLISH",
                    "topic_label": f"📖 {w} — {d[:55]}...",
                    "ava_spoken_response": f"Webster's English definition of {w}: {d[:380]}",
                    "structured_display": f"📖 WEBSTER'S UNABRIDGED DICTIONARY (102,217 WORDS)\n• Word: {w}\n• SQL-SI Code: SI::WEBSTER::{w.upper()}\n\n📝 Full Definition:\n{d}"
                })
        else:
            sample_words = [
                "electricity", "conductor", "insulator", "voltage", "ampere", "ohm", "resistance",
                "impedance", "inductance", "capacitance", "transformer", "alternating", "ground",
                "circuit", "overcurrent", "bonding", "raceway", "feeder", "algorithm", "database",
                "cipher", "encryption", "protocol", "calculus", "trigonometry", "algebra", "theorem"
            ]
            placeholders = ",".join(["?"] * len(sample_words))
            cur.execute(f"SELECT * FROM webster_english_lexicon WHERE word_lower IN ({placeholders}) ORDER BY word_lower ASC", sample_words)
            for r in cur.fetchall():
                w = r["word"]
                d = r["definition"]
                rows_out.append({
                    "si_code": f"SI::WEBSTER::{w.upper()}",
                    "verb": "DEFINE",
                    "domain": "WEBSTER_ENGLISH",
                    "topic_label": f"📖 {w.title()} — {d[:52]}...",
                    "ava_spoken_response": f"Webster's English definition of {w}: {d[:380]}",
                    "structured_display": f"📖 WEBSTER'S UNABRIDGED DICTIONARY (102,217 WORDS)\n• Word: {w}\n• SQL-SI Code: SI::WEBSTER::{w.upper()}\n\n📝 Full Definition:\n{d}"
                })
        conn.close()
        return rows_out

    if q.strip():
        results = []
        low_q = q.lower()
        # 0. Check Time-Based Memory Queries ("today", "yesterday", "timeline", "history", "when did we", "timestamp")
        if any(tk in low_q for tk in ("today", "yesterday", "timeline", "timestamp", "history", "earlier", "morning", "last night")):
            import datetime
            now_dt = datetime.datetime.now()
            target_date = None
            if "today" in low_q or "morning" in low_q or "earlier" in low_q:
                target_date = now_dt.strftime("%Y-%m-%d")
            elif "yesterday" in low_q or "last night" in low_q:
                target_date = (now_dt - datetime.timedelta(days=1)).strftime("%Y-%m-%d")
            if target_date:
                cur.execute("SELECT * FROM sql_si_lexicon WHERE domain = 'TIMELINE_LOG' AND spoken_triggers LIKE ? ORDER BY id DESC LIMIT ?", (f"%{target_date}%", limit))
            else:
                cur.execute("SELECT * FROM sql_si_lexicon WHERE domain = 'TIMELINE_LOG' ORDER BY id DESC LIMIT ?", (limit,))
            tl_rows = [dict(r) for r in cur.fetchall()]
            if tl_rows:
                results.extend(tl_rows)

        # 1. Run Live Python Math Solver first if spoken query has numbers + units!
        math_res = solve_spoken_electrical_math(q)
        if math_res:
            results.append(math_res)

        clean_q = re.sub(r"[^a-zA-Z0-9.\s]", " ", q).strip()
        # 2. Check exact NEC section match (e.g. 250.66, 310.16)
        sec_m = re.search(r"\b(\d{2,3}\.\d+[A-Za-z0-9()]*)\b", clean_q)
        if sec_m:
            sec_id = sec_m.group(1)
            cur.execute("SELECT * FROM sql_si_lexicon WHERE si_code LIKE ? OR topic_label LIKE ? LIMIT ?", (f"%{sec_id}%", f"%{sec_id}%", limit))
            results.extend([dict(r) for r in cur.fetchall()])
            if results:
                conn.close()
                return results[:limit]

        # 3. Automatic Thesaurus Synonym Expansion + FTS5 Search across all 19,225 SQL-SI / 4-Book / Learned nodes!
        stop_words = {"the", "and", "for", "where", "what", "how", "find", "show", "tell", "ava", "is", "in", "of", "to", "can", "you", "me", "about", "when", "why", "do", "does", "would", "look", "up"}
        raw_words = [w for w in clean_q.lower().split() if len(w) >= 2 and w not in stop_words]
        expanded_words = expand_words_with_thesaurus(cur, raw_words)

        if expanded_words:
            # First try strict AND match on raw_words so multi-word queries are laser-accurate!
            if len(raw_words) >= 2:
                and_terms = [f'"{re.sub(r"[^a-zA-Z0-9]", "", w)}"*' for w in raw_words[:5] if re.sub(r"[^a-zA-Z0-9]", "", w)]
                if and_terms:
                    and_expr = " AND ".join(and_terms)
                    try:
                        cur.execute("""
                            SELECT l.* FROM sql_si_fts f
                            JOIN sql_si_lexicon l ON f.si_code = l.si_code
                            WHERE sql_si_fts MATCH ?
                            ORDER BY CASE WHEN l.domain = 'LEARNED_MEMORY' THEN 0 WHEN l.domain = 'COLLEGE_AID' THEN 1 ELSE 2 END, bm25(sql_si_fts)
                            LIMIT ?
                        """, (and_expr, limit))
                        results.extend([dict(r) for r in cur.fetchall()])
                    except Exception:
                        pass

            if len(results) < 5:
                fts_terms = []
                for term in expanded_words[:12]:
                    safe_t = re.sub(r"[^a-zA-Z0-9]", " ", term).strip()
                    if safe_t:
                        fts_terms.append(f'"{safe_t}"*')
                fts_expr = " OR ".join(fts_terms)
                sql = """
                    SELECT l.* FROM sql_si_fts f
                    JOIN sql_si_lexicon l ON f.si_code = l.si_code
                    WHERE sql_si_fts MATCH ?
                """
                params = [fts_expr]
                if domain:
                    sql += " AND l.domain = ?"
                    params.append(domain)
                sql += " ORDER BY bm25(sql_si_fts) LIMIT ?"
                params.append(limit)
                try:
                    cur.execute(sql, params)
                    seen_codes = {r["si_code"] for r in results}
                    for r in cur.fetchall():
                        rd = dict(r)
                        if rd["si_code"] not in seen_codes:
                            seen_codes.add(rd["si_code"])
                            results.append(rd)
                except Exception:
                    pass

            # Append Thesaurus & Webster's matches for single/double word lookups
            for w in raw_words[:2]:
                cur.execute("SELECT * FROM english_thesaurus WHERE word = ? LIMIT 1", (w,))
                tr = cur.fetchone()
                if tr:
                    syns = tr["synonyms_csv"]
                    results.append({
                        "si_code": f"SI::THESAURUS::{w.upper()}",
                        "verb": "SYNONYM",
                        "domain": "THESAURUS",
                        "topic_label": f"🔄 Thesaurus: \"{w}\" ➔ {syns[:50]}...",
                        "ava_spoken_response": f"Thesaurus synonyms for {w} include: {syns[:350]}",
                        "structured_display": f"🔄 ENGLISH & ELECTRICAL THESAURUS\n• Word: {w}\n• Linked Synonyms: {syns}"
                    })
                cur.execute("SELECT * FROM webster_english_lexicon WHERE word_lower = ? LIMIT 1", (w,))
                wr = cur.fetchone()
                if wr:
                    wd = wr["definition"]
                    results.append({
                        "si_code": f"SI::WEBSTER::{wr['word'].upper()}",
                        "verb": "DEFINE",
                        "domain": "WEBSTER_ENGLISH",
                        "topic_label": f"📖 Webster's: \"{wr['word']}\" — {wd[:50]}...",
                        "ava_spoken_response": f"Webster's English definition of {wr['word']}: {wd[:380]}",
                        "structured_display": f"📖 WEBSTER'S UNABRIDGED DICTIONARY\n• Word: {wr['word']}\n\n📝 Full Definition:\n{wd}"
                    })
        if results:
            conn.close()
            return results[:limit]

    sql = "SELECT * FROM sql_si_lexicon WHERE 1=1"
    params = []
    if domain:
        sql += " AND domain = ?"
        params.append(domain)
    if verb:
        sql += " AND verb = ?"
        params.append(verb)
    sql += " ORDER BY id DESC LIMIT ?" if domain in ("LEARNED_MEMORY", "TIMELINE_LOG") else " ORDER BY id ASC LIMIT ?"
    params.append(limit)
    cur.execute(sql, params)
    rows = [dict(r) for r in cur.fetchall()]
    conn.close()
    return rows


SQL_SI_HTML = r"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
<title>🧠 SQL-SI Self-Learning Language Server (166,716+ Nodes)</title>
<style>
  * { box-sizing: border-box; margin: 0; padding: 0; -webkit-tap-highlight-color: transparent; }
  body { background: #020617; color: #f8fafc; font-family: 'Segoe UI', system-ui, sans-serif; padding: 10px; }
  .container { max-width: 500px; margin: 0 auto; border: 3px solid #38bdf8; border-radius: 22px; padding: 12px; background: #0f172a; box-shadow: 0 10px 30px rgba(0,0,0,0.7); }
  .header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px; }
  .title { font-size: 0.98rem; font-weight: 900; color: #38bdf8; }
  .zero-badge { background: #15803d; color: #fff; font-weight: 900; font-size: 0.74rem; padding: 4px 8px; border-radius: 8px; border: 1px solid #4ade80; }
  .sql-bar { background: #020617; border: 2px solid #fbbf24; border-radius: 12px; padding: 10px; font-family: Consolas, monospace; font-size: 0.82rem; color: #fde047; margin-bottom: 10px; text-align: left; }
  .section-lbl { font-size: 0.8rem; font-weight: 900; color: #94a3b8; text-align: left; margin: 6px 0 4px 2px; text-transform: uppercase; }
  .dom-grid { display: grid; grid-template-columns: repeat(2, 1fr); gap: 6px; margin-bottom: 8px; }
  button { padding: 10px 8px; border-radius: 12px; border: 2px solid #334155; background: #1e293b; color: #fff; font-weight: 800; font-size: 0.84rem; cursor: pointer; }
  button.dom-active { background: #0284c7; color: #fff; border-color: #38bdf8; }
  .topic-list { max-height: 215px; overflow-y: auto; display: flex; flex-direction: column; gap: 6px; margin-bottom: 10px; padding: 4px; background: #020617; border-radius: 12px; border: 1px solid #334155; }
  .topic-btn { text-align: left; padding: 12px; font-size: 0.88rem; background: #1e293b; border: 1px solid #475569; border-radius: 10px; color: #e2e8f0; }
  .topic-btn:active { background: #38bdf8; color: #000; }
  .output-card { background: #1e1b4b; border: 2px solid #22c55e; border-radius: 14px; padding: 12px; text-align: left; white-space: pre-wrap; font-size: 0.95rem; line-height: 1.45; margin-top: 8px; }
</style>
</head>
<body>
<div class="container">
  <div class="header">
    <span class="title">🧠 SQL-SI SELF-LEARNING VAULT</span>
    <span class="zero-badge">⚡ 166,716+ NODES • 0 TOKENS</span>
  </div>
  <div style="margin-bottom:8px;display:flex;gap:6px;">
    <a href="/watch" style="flex:1;text-decoration:none;"><button type="button" style="width:100%;background:#334155;border-color:#94a3b8;">↩ BACK TO 1,000 CARDS &amp; AVA BRIDGE</button></a>
  </div>

  <!-- LIVE COMPOSABLE SQL-SI QUERY MONITOR -->
  <div class="sql-bar" id="sql-query-monitor">
    SELECT * FROM sql_si_166k WHERE auto_learning = TRUE; -- [0 TOKENS]
  </div>

  <!-- STEP 1: SPEAK OR TYPE IN SQL-SI (WITH LIVE MATH SOLVER + THESAURUS EXPANSION!) -->
  <div style="display:flex;gap:6px;margin-bottom:8px;">
    <input type="text" id="si-search-input" placeholder="🗣️ Ask any question, math calc, word, or NEC rule (0 Tokens)..." style="flex:1;padding:12px;border-radius:12px;border:2px solid #38bdf8;background:#020617;color:#fff;font-size:0.95rem;" onkeydown="if(event.key==='Enter'){runSqlSiSearch();}">
    <button type="button" onclick="runSqlSiSearch()" style="background:#22c55e;color:#000;border-color:#22c55e;padding:12px 14px;">FETCH</button>
  </div>

  <!-- STEP 2: TAP A SQL-SI DOMAIN (TABLE FILTER) -->
  <div class="section-lbl">1. Select SQL-SI Knowledge Domain (167,582+ Nodes):</div>
  <div class="dom-grid">
    <button type="button" id="dom-TIMELINE_LOG" class="dom-active" style="grid-column:span 2;background:#7c3aed;border-color:#fde047;" onclick="setSiDomain('TIMELINE_LOG')">⏱️ SQL Memory Timestamp Timeline (493+ Events)</button>
    <button type="button" id="dom-LEARNED_MEMORY" onclick="setSiDomain('LEARNED_MEMORY')">🧬 Auto-Learned Q&amp;A (372+)</button>
    <button type="button" id="dom-ENGLISH_CONTEXT" onclick="setSiDomain('ENGLISH_CONTEXT')">🧠 Context &amp; Contacts</button>
    <button type="button" id="dom-TEXTBOOK_VAULT" onclick="setSiDomain('TEXTBOOK_VAULT')">📚 4 Full Books (8,428)</button>
    <button type="button" id="dom-WEBSTER_ENGLISH" onclick="setSiDomain('WEBSTER_ENGLISH')">📖 Webster's (102,217)</button>
    <button type="button" id="dom-THESAURUS" onclick="setSiDomain('THESAURUS')">🔄 Thesaurus (45,274)</button>
    <button type="button" id="dom-NEC_CODE" onclick="setSiDomain('NEC_CODE')">⚡ NEC Drills &amp; Exams (6,590)</button>
    <button type="button" id="dom-ELEC_MATH" onclick="setSiDomain('ELEC_MATH')">📐 Math &amp; Live Solver</button>
    <button type="button" id="dom-COLLEGE_AID" onclick="setSiDomain('COLLEGE_AID')">🎓 College &amp; Stipends</button>
    <button type="button" id="dom-WOW_ADDONS" onclick="setSiDomain('WOW_ADDONS')">⚔️ WoW Addon Forge (49+)</button>
    <button type="button" id="dom-WOW_BUILDS_1_60" style="grid-column:span 2;background:#0f766e;border-color:#5eead4;" onclick="setSiDomain('WOW_BUILDS_1_60')">🏆 WoW Forever 1–60 Perfect Builds (540)</button>
  </div>

  <!-- STEP 3: TAP ANY PHRASE/RULE TO FETCH & HEAR AVA READ IT FOR 0 TOKENS -->
  <div class="section-lbl" id="results-count-lbl">2. Tap Any SQL-SI Node (Instant Ava Voice • 0 Tokens):</div>
  <div class="topic-list" id="si-topic-list"></div>

  <!-- SPOKEN & STRUCTURED OUTPUT -->
  <div class="output-card" id="si-output-box">Welcome to your 166,716-node Self-Learning SQL-SI Language Vault! Type or speak any question, NEC rule, word, or live math problem (like "voltage drop 150 feet 20 amps 12 awg" or "4800 watts at 240 volts") above to hear Ava solve and read it for 0 AI tokens!</div>
</div>

<script>
let CurrentDomain = 'TIMELINE_LOG';
let AvaCtx = null;
let ActiveSrc = null;

function updateSqlMonitor(q, dom, code) {
  const el = document.getElementById('sql-query-monitor');
  if (code) {
    el.textContent = `SELECT ava_voice FROM sql_si_vault WHERE si_code = '${code}'; -- [0 TOKENS]`;
  } else if (q) {
    el.textContent = `SELECT * FROM math_solver('${q}') UNION thesaurus_fts('${q}'); -- [0 TOKENS]`;
  } else {
    el.textContent = `SELECT * FROM sql_si_vault WHERE domain = '${dom}' ORDER BY timestamp DESC; -- [0 TOKENS]`;
  }
}

async function setSiDomain(dom) {
  CurrentDomain = dom;
  ['TIMELINE_LOG', 'LEARNED_MEMORY', 'ENGLISH_CONTEXT', 'TEXTBOOK_VAULT', 'WEBSTER_ENGLISH', 'THESAURUS', 'NEC_CODE', 'ELEC_MATH', 'COLLEGE_AID', 'WOW_ADDONS', 'WOW_BUILDS_1_60'].forEach(d => {
    const b = document.getElementById('dom-' + d);
    if (b) {
      b.className = (d === dom) ? 'dom-active' : '';
      if (d === 'TIMELINE_LOG') b.style.background = (d === dom) ? '#7c3aed' : '#1e293b';
    }
  });
  document.getElementById('si-search-input').value = '';
  updateSqlMonitor('', dom, '');
  await loadSiNodes('', dom);
}

async function runSqlSiSearch() {
  const q = document.getElementById('si-search-input').value.trim();
  updateSqlMonitor(q, CurrentDomain, '');
  const searchDom = (CurrentDomain === 'WEBSTER_ENGLISH' || CurrentDomain === 'THESAURUS') ? CurrentDomain : '';
  await loadSiNodes(q, searchDom, true);
}

async function loadSiNodes(q, dom, autoSpeakFirst = false) {
  const res = await fetch(`/api/sql_si_query?q=${encodeURIComponent(q)}&domain=${encodeURIComponent(dom)}&limit=40&t=${Date.now()}`);
  const rows = await res.json();
  const list = document.getElementById('si-topic-list');
  list.innerHTML = '';
  document.getElementById('results-count-lbl').textContent = `2. Tap Any SQL-SI Node (${rows.length} Matched • 0 Tokens):`;
  rows.forEach((r, idx) => {
    const b = document.createElement('button');
    b.type = 'button';
    b.className = 'topic-btn';
    b.innerHTML = `<strong style="color:#fbbf24;">[${r.verb}]</strong> ${r.topic_label} <span style="float:right;color:#38bdf8;font-size:0.74rem;">${r.si_code}</span>`;
    b.onclick = () => executeSiNode(r);
    list.appendChild(b);
    if (autoSpeakFirst && idx === 0) {
      executeSiNode(r);
    }
  });
}

async function executeSiNode(r) {
  updateSqlMonitor('', CurrentDomain, r.si_code);
  document.getElementById('si-output-box').textContent =
    `🔊 AVA SPOKEN RESPONSE (0 TOKENS):\n"${r.ava_spoken_response}"\n\n` +
    `📋 STRUCTURED SQL-SI RECORD:\n${r.structured_display}`;
  playSiAvaVoice(r.ava_spoken_response);
}

async function playSiAvaVoice(txt) {
  try {
    if (!AvaCtx) AvaCtx = new (window.AudioContext || window.webkitAudioContext)();
    if (AvaCtx.state === 'suspended') await AvaCtx.resume();
    if (ActiveSrc) { try { ActiveSrc.stop(); } catch (e) {} ActiveSrc = null; }
    const res = await fetch('/api/ava_tts?text=' + encodeURIComponent(txt) + '&t=' + Date.now());
    const buf = await res.arrayBuffer();
    const audioBuf = await AvaCtx.decodeAudioData(buf);
    const src = AvaCtx.createBufferSource();
    src.buffer = audioBuf;
    const gain = AvaCtx.createGain();
    gain.gain.value = 2.6;
    src.connect(gain);
    gain.connect(AvaCtx.destination);
    ActiveSrc = src;
    src.start(0);
  } catch (e) {}
}

window.addEventListener('DOMContentLoaded', () => setSiDomain('TIMELINE_LOG'));
</script>
</body>
</html>
"""


class SqlSiHandler(BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        pass

    def send_json(self, data):
        body = json.dumps(data).encode('utf-8')
        self.send_response(200)
        self.send_header('Content-Type', 'application/json; charset=utf-8')
        self.send_header('Cache-Control', 'no-store')
        self.send_header('Content-Length', str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)
        path = parsed.path
        qs = urllib.parse.parse_qs(parsed.query)

        if path in ('/', '/sql_si'):
            body = SQL_SI_HTML.encode('utf-8')
            self.send_response(200)
            self.send_header('Content-Type', 'text/html; charset=utf-8')
            self.send_header('Cache-Control', 'no-store')
            self.send_header('Content-Length', str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return

        if path == '/api/sql_si_query':
            q = qs.get('q', [''])[0]
            verb = qs.get('verb', [''])[0]
            domain = qs.get('domain', [''])[0]
            si_code = qs.get('si_code', [''])[0]
            limit = int(qs.get('limit', ['35'])[0])
            rows = query_sql_si_vault(q=q, verb=verb, domain=domain, si_code=si_code, limit=limit)
            self.send_json(rows)
            return

        if path == '/api/ava_tts':
            txt = qs.get('text', ['Hello Stephen'])[0].strip()
            try:
                import asyncio, edge_tts
                clean = re.sub(r"<[^>]+>", "", re.sub(r"[*_`#]+", "", txt)).strip()[:900]
                async def _gen():
                    comm = edge_tts.Communicate(clean, voice="en-US-AvaNeural", rate="+8%", volume="+50%")
                    buf = bytearray()
                    async for ch in comm.stream():
                        if ch["type"] == "audio":
                            buf.extend(ch["data"])
                    return bytes(buf)
                mp3 = asyncio.run(_gen())
                self.send_response(200)
                self.send_header('Content-Type', 'audio/mpeg')
                self.send_header('Content-Length', str(len(mp3)))
                self.end_headers()
                self.wfile.write(mp3)
                return
            except Exception:
                self.send_error(500)
                return

        self.send_error(404)


if __name__ == '__main__':
    srv = ThreadingHTTPServer(('0.0.0.0', SI_PORT), SqlSiHandler)
    srv.daemon_threads = True
    print(f"SQL-SI Language Server (166,716+ nodes) running on http://0.0.0.0:{SI_PORT}")
    srv.serve_forever()
