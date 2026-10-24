import sqlite3
import json
import hashlib
import time

DB_PATH = r"c:\Program Files (x86)\World of Warcraft\_classic_beta_\Interface\AddOns\DeconstructionGod_Studio\NEC_Harvest_Targets\NEC_Master_Vault.sqlite"

BILATERAL_CARDS = [
    {
        "sec": "110.3(A)(8) + PYTHON",
        "title": "NEC Equipment Cybersecurity Evaluation & Python SHA-256 Hash Check",
        "kw": "cybersecurity • smart breaker • firmware • SHA-256 hash • Python hashlib",
        "front": "💻⚡ BILATERAL CODE & NEC DRILL:\n1) Where in the 2023 NEC does it require electrical equipment connected to a network to be evaluated for CYBERSECURITY?\n2) What does this 1-line Python snippet do?\n`hashlib.sha256(firmware_bytes).hexdigest()`",
        "back": "✅ 1) NEC Section 110.3(A)(8) (Examination, Identification, Installation, and Use of Equipment — Cybersecurity) requires networked electrical gear (smart panels, relays, EV chargers) to be evaluated for resilience against cyberattacks!\n✅ 2) PYTHON SNIPPET: Computes a tamper-proof 64-character SHA-256 digital fingerprint of the equipment firmware or your study transcript so nobody can alter a single byte undetected!",
        "q": "In the 2023 NEC, which section requires networked electrical equipment to be evaluated for cybersecurity, and which Python module verifies file integrity with SHA-256?",
        "a": "NEC 110.3(A)(8) & Python `hashlib.sha256()`",
        "d1": "NEC 250.4(A)(1) & Python `math.sqrt()`",
        "d2": "NEC 310.16 & Python `random.choice()`",
        "d3": "NEC 430.52 & Python `time.sleep()`",
        "chap": 1,
        "art": "CYBER"
    },
    {
        "sec": "240.6(D) + PYTHON",
        "title": "Remotely Accessible Adjustable-Trip Breakers & Python Password Auth",
        "kw": "remotely accessible • adjustable trip • breaker cybersecurity • 240.6(D) • Python hmac",
        "front": "💻⚡ BILATERAL CODE & NEC DRILL:\n1) What does NEC 240.6(D) require when a circuit breaker's trip setting can be adjusted REMOTELY over a network?\n2) Why should Python use `hmac.compare_digest(user_pw, stored_pw)` instead of `==`?",
        "back": "✅ 1) NEC 240.6(D) forbids remote network modification of a breaker's trip settings unless access is restricted by an approved cybersecurity method (or physical local switch) so a hacker cannot raise a 100A breaker to 800A and burn down the building!\n✅ 2) CYBER CODING: `hmac.compare_digest()` takes the exact same microsecond whether the first letter is wrong or the last letter is wrong, preventing 'Timing Side-Channel Attacks'!",
        "q": "What does NEC 240.6(D) protect on smart circuit breakers, and how does `hmac.compare_digest()` protect password checks in Python?",
        "a": "Protects remote adjustable-trip settings from unauthorized network changes; prevents timing side-channel attacks",
        "d1": "Sizes ground rods; speeds up Wi-Fi",
        "d2": "Calculates conduit fill; compresses images",
        "d3": "Measures voltage drop; sorts arrays",
        "chap": 2,
        "art": "CYBER"
    },
    {
        "sec": "708.7 + CYBER",
        "title": "Critical Operations Power Systems (COPS) Cybersecurity & Air-Gapped Networks",
        "kw": "Critical Operations Power Systems • COPS • 708.7 • air gap • firewall • SCADA",
        "front": "💻⚡ BILATERAL CODE & NEC DRILL:\n1) Which NEC Article governs Critical Operations Power Systems (911 centers, hospitals, defense grids) and requires a documented Cybersecurity Risk Assessment?\n2) In Python, how do you bind a server ONLY to your local PC (`127.0.0.1`) vs. the whole Wi-Fi LAN (`0.0.0.0`)?",
        "back": "✅ 1) NEC Article 708 (specifically 708.7 Cybersecurity) governs Critical Operations Power Systems (COPS)!\n✅ 2) PYTHON NETWORKING:\n• `HTTPServer(('127.0.0.1', 8765), Handler)` = Loopback only (Air-gapped to your own PC).\n• `HTTPServer(('0.0.0.0', 8765), Handler)` = Listens on all network interfaces so your Galaxy Watch (`192.168.1.x`) can talk to your Mothership PC!",
        "q": "Which NEC Article covers Critical Operations Power Systems (COPS), and which IP address binds a Python server strictly to the local machine (loopback)?",
        "a": "NEC Article 708 & IP `127.0.0.1`",
        "d1": "NEC Article 210 & IP `255.255.255.0`",
        "d2": "NEC Article 314 & IP `8.8.8.8`",
        "d3": "NEC Article 430 & IP `192.168.0.254`",
        "chap": 7,
        "art": "CYBER"
    },
    {
        "sec": "725.121 + PYTHON",
        "title": "NEC Class 2 PLC/SCADA Control Circuits & Python Ohm's Law Function",
        "kw": "Class 2 circuit • PLC • SCADA • 24V DC • Article 725 • Python def function",
        "front": "💻⚡ BILATERAL CODE & NEC DRILL:\n1) Which NEC Article governs Class 1, Class 2, and Class 3 remote-control, signaling, and 24V PLC/SCADA circuits?\n2) Read this Python function—what does `calc_amps(2400, 240)` return?\n`def calc_amps(watts, volts): return watts / volts`",
        "back": "✅ 1) NEC Article 725 (Class 1, Class 2, and Class 3 Remote-Control, Signaling, and Power-Limited Circuits — Physical Tab: 'Class 1, 2, 3 Circuits' in Chapter 7)!\n✅ 2) PYTHON SNIPPET: `def` defines a reusable function. Passing `2400` watts and `240` volts returns `2400 / 240 = 10.0` Amps!",
        "q": "Which NEC Article governs Class 2 PLC control circuits, and what does the Python function `def calc_amps(w, v): return w / v` return for `(4800, 240)`?",
        "a": "NEC Article 725 & `20.0` Amps",
        "d1": "NEC Article 250 & `4800` Amps",
        "d2": "NEC Article 300 & `0.05` Amps",
        "d3": "NEC Article 400 & `240` Amps",
        "chap": 7,
        "art": "CYBER"
    },
    {
        "sec": "210.20(A) + LUA",
        "title": "125% Continuous Load Breaker Rule in NEC & WoW Lua AddOn Code",
        "kw": "continuous load • 125% • 3 hours • 210.20(A) • Lua function • math.ceil",
        "front": "💻⚡ BILATERAL CODE & NEC DRILL:\n1) Under NEC 210.20(A), how do you size a breaker for a continuous load (3+ hours)?\n2) What does this WoW Lua snippet in `Engine_NECElectricalCodec.lua` calculate?\n`local minBreaker = math.ceil(loadAmps * 1.25)`",
        "back": "✅ 1) NEC 210.20(A) requires the breaker to be rated at 100% of the noncontinuous load PLUS 125% (`1.25x`) of the continuous load!\n✅ 2) LUA SNIPPET: `local` creates a fast local variable in Lua, multiplies `loadAmps * 1.25`, and `math.ceil()` rounds UP to the next whole integer amp before selecting the next standard breaker size in NEC 240.6(A)!",
        "q": "In WoW Lua (`Engine_NECElectricalCodec.lua`), what does `local minBreaker = math.ceil(loadAmps * 1.25)` implement from the NEC?",
        "a": "NEC 210.20(A) 125% Continuous Load Overcurrent Sizing",
        "d1": "NEC 250.66 Grounding Electrode Sizing",
        "d2": "NEC 314.16 Box Fill Volume",
        "d3": "NEC 430.250 3-Phase Motor FLA",
        "chap": 2,
        "art": "CYBER"
    },
    {
        "sec": "240.6(A) + PYTHON",
        "title": "Standard Ampere Ratings (NEC 240.6(A)) & Python List Comprehension",
        "kw": "standard ampere ratings • 240.6(A) • next size up • Python list • for loop",
        "front": "💻⚡ BILATERAL CODE & NEC DRILL:\n1) Where in the NEC are the Standard Ampere Ratings for fuses and inverse-time breakers listed (15, 20, 25, 30, 35, 40, 45, 50, 60...)?\n2) How does this 1-line Python snippet pick the next standard breaker for `34 Amps`?\n`std = [15, 20, 25, 30, 35, 40, 50, 60]; breaker = next(b for b in std if b >= 34)`",
        "back": "✅ 1) NEC Section 240.6(A) (and Table 240.6(A)) lists all standard overcurrent device ratings!\n✅ 2) PYTHON SNIPPET: `std` is a Python List (`[...]`). `next(b for b in std if b >= 34)` scans the list left-to-right and stops at the first standard breaker `>= 34`, returning `35` (a 35A breaker)!",
        "q": "What value does `next(b for b in [15,20,25,30,35,40,50] if b >= 27)` return when sizing a standard breaker under NEC 240.6(A)?",
        "a": "`30` (30-Amp Standard Breaker)",
        "d1": "`25` (25-Amp Standard Breaker)",
        "d2": "`27` (27-Amp Custom Breaker)",
        "d3": "`50` (50-Amp Standard Breaker)",
        "chap": 2,
        "art": "CYBER"
    },
    {
        "sec": "770.24 + CYBER",
        "title": "Optical Fiber Cables (NEC Art. 770) & Cyber Tap / EMI Immunity",
        "kw": "optical fiber • Article 770 • conductive • nonconductive • EMI • cyber wiretap",
        "front": "💻⚡ BILATERAL CODE & NEC DRILL:\n1) Which NEC Article covers Optical Fiber Cables (OFNP / OFNR / OFCP), and can nonconductive fiber be run in the same raceway as power conductors?\n2) Why do high-security cybersecurity data centers use Optical Fiber instead of copper Cat6 for classified links?",
        "back": "✅ 1) NEC Article 770 (Optical Fiber Cables and Raceways — Chapter 7)! Under 770.133, nonconductive optical fiber cables are permitted with power conductors where functionally associated.\n✅ 2) CYBERSECURITY: Glass fiber transmits light pulses (`photons`) instead of electrical current (`electrons`)—so it emits ZERO electromagnetic radiation (impossible to eavesdrop with an inductive clamp probe) and is 100% immune to high-voltage EMI and ground-loop surges!",
        "q": "Which NEC Article covers Optical Fiber Cables, and why is nonconductive fiber preferred in high-security cybersecurity zones?",
        "a": "NEC Article 770; fiber carries light instead of electricity, eliminating electromagnetic eavesdropping & EMI",
        "d1": "NEC Article 800; fiber carries 480V 3-phase power",
        "d2": "NEC Article 310; fiber requires #6 AWG copper bonding",
        "d3": "NEC Article 500; fiber amplifies Wi-Fi signals",
        "chap": 7,
        "art": "CYBER"
    },
    {
        "sec": "800.100 + SQL",
        "title": "Communications Grounding (NEC Art. 800) & SQL Injection Prevention",
        "kw": "communications • Article 800 • primary protector • bonding • SQL injection • parameterized query",
        "front": "💻⚡ BILATERAL CODE & NEC DRILL:\n1) Under NEC 800.100(B), where must the telecommunications Primary Protector grounding conductor be bonded?\n2) In SQLite (`NEC_Master_Vault.sqlite`), why must you write:\n`cur.execute('SELECT * FROM cards WHERE id = ?', (user_id,))`\ninstead of string-concatenating `user_id`?",
        "back": "✅ 1) NEC 800.100(B) requires bonding to the building's Intersystem Bonding Termination (IBT — NEC 250.94) or grounding electrode system using at least a #14 AWG (or #6 AWG bonding jumper) so lightning surges don't fry the server rack!\n✅ 2) CYBER SQL SECURITY: Using `?` placeholders (Parameterized Queries) prevents **SQL Injection (`SQLi`)**—the #1 web hacking attack where an attacker types `' OR 1=1 --` to dump an entire database!",
        "q": "In NEC 800.100, what protects communications lines from lightning surges, and in Python SQLite, what protects databases from SQL Injection (`SQLi`)?",
        "a": "Bonding the Primary Protector to the Intersystem Bonding Termination (250.94); using `?` parameterized queries",
        "d1": "Using PVC conduit; using `eval()` in Python",
        "d2": "Floating the ground wire; disabling passwords",
        "d3": "Oversizing the main breaker; storing plain text",
        "chap": 8,
        "art": "CYBER"
    },
    {
        "sec": "310.16 + PYTHON_DICT",
        "title": "NEC Table 310.16 Ampacity Lookup Using a Python Dictionary (`dict`)",
        "kw": "Table 310.16 • 75C copper • ampacity • Python dictionary • key-value lookup",
        "front": "💻⚡ BILATERAL CODE & NEC DRILL:\n1) In NEC Table 310.16 (75°C Copper column), what are the ampacities of `#12`, `#10`, `#8`, and `#6` AWG?\n2) How does a Python Dictionary (`dict`) look up `#8` AWG in O(1) instant time?\n`amp_75c = {'#14': 20, '#12': 25, '#10': 35, '#8': 50, '#6': 65}; print(amp_75c['#8'])`",
        "back": "✅ 1) NEC Table 310.16 (75°C Copper): `#12 = 25A` (capped at 20A breaker by 240.4(D)), `#10 = 35A` (capped at 30A breaker by 240.4(D)), `#8 = 50A`, `#6 = 65A`!\n✅ 2) PYTHON SNIPPET: `{key: value}` is a Python Dictionary (hash map). `amp_75c['#8']` jumps straight to the key `'#8'` and returns `50`!",
        "q": "Given the Python dictionary `amp_75c = {'#12': 25, '#10': 35, '#8': 50, '#6': 65}`, what does `amp_75c['#6']` return, matching NEC Table 310.16 (75°C Cu)?",
        "a": "`65` (65 Amps for #6 AWG Copper at 75°C)",
        "d1": "`50` (50 Amps)",
        "d2": "`55` (60°C Column)",
        "d3": "`75` (90°C Column)",
        "chap": 3,
        "art": "CYBER"
    },
    {
        "sec": "CH9_T8 + JS_VD",
        "title": "Voltage Drop Formula (NEC Ch. 9 Table 8) in JavaScript (Galaxy Watch App)",
        "kw": "voltage drop • 2KIL/CM • 12.9 copper • Chapter 9 Table 8 • JavaScript const",
        "front": "💻⚡ BILATERAL CODE & NEC DRILL:\n1) What is the Single-Phase Voltage Drop formula and the DC resistance constant `K` for Copper?\n2) Read this JavaScript snippet from your Galaxy Watch app—what does it compute?\n`const K = 12.9; const vd = (2 * K * amps * feet) / circularMils;`",
        "back": "✅ 1) Formula: `VD = (2 × K × I × L) ÷ CM`, where `K = 12.9` ohms per circular-mil-foot for Copper (`21.2` for Aluminum), and NEC 210.19(A) Info Note #4 recommends `<= 3%` on a branch circuit (`<= 5%` total)!\n✅ 2) JAVASCRIPT SNIPPET: `const` declares a constant variable in JavaScript, computes the exact voltage drop in volts (`vd`), and converts it to a percentage (`pct`) of system voltage!",
        "q": "In the JavaScript snippet `const vd = (2 * 12.9 * amps * feet) / circularMils;`, what does `12.9` represent in NEC Chapter 9?",
        "a": "The `K` resistance constant (ohms per circular-mil-foot) for Uncoated Copper conductors",
        "d1": "The `K` constant for Aluminum conductors (`21.2`)",
        "d2": "The continuous load multiplier (`1.25`)",
        "d3": "The 3-phase square root of 3 multiplier (`1.732`)",
        "chap": 9,
        "art": "CYBER"
    },
    {
        "sec": "645.10 + CYBER_EPO",
        "title": "Information Technology Equipment Rooms (NEC Art. 645) & Emergency Power Off (EPO)",
        "kw": "Article 645 • IT equipment room • server room • disconnecting means • 645.10 • EPO",
        "front": "💻⚡ BILATERAL CODE & NEC DRILL:\n1) Under NEC 645.10, where must the Emergency Disconnecting Means (EPO button) for an Information Technology Equipment (Server) Room be located, and what two systems must it shut down?\n2) In Cybersecurity Incident Response, why do you isolate a compromised server's network port (`ipconfig /release` or unplugging Cat6) BEFORE pulling the power plug?",
        "back": "✅ 1) NEC 645.10 requires the disconnecting means at the principal exit doors, and it must disconnect power to ALL electronic equipment in the room AND all dedicated HVAC/air-conditioning serving the room (and close fire/smoke dampers)!\n✅ 2) CYBER FORENSICS: Pulling the power plug wipes volatile RAM (where encryption keys and active hacker network sockets live). Isolating the network cable first traps the evidence in RAM while stopping data exfiltration!",
        "q": "Under NEC 645.10, what two systems must the server room Emergency Power Off (EPO) disconnect at the principal exit door?",
        "a": "All electronic IT equipment AND the dedicated HVAC/air-conditioning system serving the room",
        "d1": "Only the emergency exit lighting and fire alarms",
        "d2": "Only the main utility transformer outside",
        "d3": "Only the bathroom GFCI receptacles",
        "chap": 6,
        "art": "CYBER"
    },
    {
        "sec": "70E_120 + CYBER_MFA",
        "title": "NFPA 70E Lockout/Tagout (LOTO) vs. Cybersecurity Multi-Factor Authentication (MFA)",
        "kw": "NFPA 70E • Article 120 • Lockout Tagout • Electrically Safe Work Condition • MFA • Zero Trust",
        "front": "💻⚡ BILATERAL CODE & NEC DRILL:\n1) What are the 6 steps to establish an Electrically Safe Work Condition (Lockout/Tagout) in NFPA 70E Article 120.5?\n2) How does Physical LOTO (`1 Lock, 1 Key, 1 Person + Live-Dead-Live Test`) mirror Cybersecurity 'Zero Trust & Multi-Factor Authentication (MFA)'?",
        "back": "✅ 1) NFPA 70E 120.5 Steps: (1) Identify all power sources, (2) Interrupt load & open disconnect, (3) Visually verify blades open, (4) Apply personal Lock & Tag, (5) Release stored energy/capacitors, (6) Verify absence of voltage with a Live-Dead-Live meter test!\n✅ 2) BILATERAL PRINCIPLE: In both Electrical Safety and Cybersecurity ('Zero Trust'), you NEVER trust a label or a single switch—you verify identity with a personal cryptographic key (MFA) and actively test the state before touching the system!",
        "q": "In NFPA 70E Article 120.5, what is the mandatory final verification step after applying your Lockout/Tagout device?",
        "a": "Test every phase conductor phase-to-phase and phase-to-ground using the 'Live-Dead-Live' voltage meter method",
        "d1": "Check if the room lights turned off",
        "d2": "Ask the apprentice if the breaker is off",
        "d3": "Read the panel directory schedule only",
        "chap": 1,
        "art": "CYBER"
    },
    {
        "sec": "ACL_v21 + NEC_250",
        "title": "Your Aetheros Command Language (ACL v21.0) Pipe Syntax (`>`) & NEC 250 Grounding",
        "kw": "ACL v21.0 • ^, marker • >> depth modifier • <~wc> 30% rule • > pipe chain • NEC 250.66",
        "front": "💻⚡ YOUR OWN ACL v21.0 LANGUAGE + NEC DRILL:\n1) In your Aetheros Command Language (`ACL v21.0`), what does this query do?\n`^,[>>AnTb(NEC Table 250.66 Grounding Electrode Conductor)]<~1000> > [CdDc(Python GEC Sizer)]<500>`\n2) Under NEC Table 250.66, what is the largest Grounding Electrode Conductor required for a sole connection to a ground rod (`250.66(A)`)?",
        "back": "✅ 1) YOUR ACL v21.0 COMPILER SYNTAX:\n• `^,` = ACL Command Marker.\n• `>>AnTb` = Deep Analyze + Table format; triggers `<~1000>` Flexible Depth Word Count (requires >= 30% more = 1,300+ words!).\n• `>` = Pipes the NEC 250.66 analysis directly into `[CdDc(...)]<500>` (Generate Code + Document Code in 500 words)!\n✅ 2) NEC 250.66(A): A grounding electrode conductor to a driven ground rod NEVER needs to be larger than `#6 AWG Copper` (or `#4 AWG Aluminum`)!",
        "q": "In your Aetheros Command Language (ACL v21.0), what does the `>>` depth modifier trigger on `<~1000>`, and what is the max GEC size to a ground rod under NEC 250.66(A)?",
        "a": "Requires at least 30% more words (1,300+ words minimum); `#6 AWG Copper` max to a ground rod",
        "d1": "Cuts word count by 50%; `#2/0 AWG Copper`",
        "d2": "Deletes the subject; `#14 AWG Copper`",
        "d3": "Closes the app; `500 kcmil Copper`",
        "chap": 2,
        "art": "CYBER"
    },
    {
        "sec": "ACL_TS + NEC_310",
        "title": "Your TypeScript ACL Compiler (`aclQueryBuilder.ts`) & NEC 310.15 Derating",
        "kw": "TypeScript • aclQueryBuilder.ts • .some() • .map() • NEC 310.15(C)(1) • conduit fill derating",
        "front": "💻⚡ YOUR OWN TYPESCRIPT CODE (`aclQueryBuilder.ts`) + NEC DRILL:\n1) Look at line 21 of YOUR OWN `aclQueryBuilder.ts`:\n`const commandStr = subject.commands.map(c => c.isDeep ? '>>' + c.cmd : c.cmd).join('');`\nWhat does `.map()` do here?\n2) Under NEC Table 310.15(C)(1), what derating multiplier applies when 4 to 6 current-carrying conductors are in one conduit?",
        "back": "✅ 1) YOUR TYPESCRIPT CODE (`aclQueryBuilder.ts`):\n`.map()` transforms every command object in your array—if `c.isDeep` is true, it prepends `'>>'` to the opcode (like `>>Re` or `>>Uv`), and `.join('')` concatenates them into a single ACL command string!\n✅ 2) NEC Table 310.15(C)(1): 4 to 6 current-carrying conductors in a raceway must be derated to `80%` (`× 0.80`) of their 90°C THHN ampacity!",
        "q": "In your `aclQueryBuilder.ts` TypeScript code, what does `.join(' > ')` vs `.join(' + ')` do, and what is the NEC 310.15(C)(1) derating factor for 4–6 wires?",
        "a": "`>` chains sequential piped blocks while `+` separates parallel tasks; `80%` derating for 4–6 wires",
        "d1": "Multiplies numbers; `50%` derating",
        "d2": "Encrypts files; `125%` multiplier",
        "d3": "Draws a circle; `100%` rating",
        "chap": 3,
        "art": "CYBER"
    }
]

def main():
    conn = sqlite3.connect(DB_PATH)
    cur = conn.cursor()

    cur.execute("DELETE FROM flashcard_drills WHERE article = 'CYBER'")
    cur.execute("DELETE FROM ladder_section_drills WHERE drill_num > 1000")

    for i, c in enumerate(BILATERAL_CARDS, start=1):
        card_id = f"CYBER_{i:04d}"
        quiz_obj = {
            "question": c["q"],
            "choices": [c["a"], c["d1"], c["d2"], c["d3"]],
            "options": [c["a"], c["d1"], c["d2"], c["d3"]],
            "correctIndex": 0,
            "answer_index": 0,
            "explanation": c["back"]
        }
        cur.execute("""
            INSERT INTO flashcard_drills (
                card_id, source_bank, room_or_category, article, citation,
                tab_name, code_location_path, front_title, front_subtitle,
                back_title, back_body, givens_json, choice_quiz_json,
                chapter_num, article_sort, section_sort
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (
            card_id,
            "BILATERAL_CYBER_NEC",
            "NEC + Cybersecurity & Coding",
            "CYBER",
            c["sec"],
            "Bilateral NEC + Cybersecurity & Coding Snippets",
            f"Chapter {c['chap']} ➔ {c['sec']} ({c['title']})",
            c["title"],
            c["front"],
            f"✅ {c['sec']} — {c['title']}",
            c["back"],
            json.dumps({"keywords": c["kw"]}),
            json.dumps(quiz_obj),
            c["chap"],
            950,
            i
        ))

        drill_num = 1000 + i
        drill_id = f"LADDER_{drill_num:04d}"
        r1 = f"Rung 1 (Chapter {c['chap']} + Bilateral Cyber/Code Track)"
        r2 = f"Rung 2 (Tab: {c['sec']} — NEC + Programming Snippet)"
        r3 = f"Rung 3 (Exact Rule & Code): {c['title']}"
        watch_q = f"Bilateral Electrical and Coding Drill {drill_num}. Key words: {c['kw']}. {c['q']}"
        watch_a = f"Answer: {c['a']}. {c['back'][:220]}"

        cur.execute("""
            INSERT INTO ladder_section_drills (
                drill_id, drill_num, chapter_num, chapter_title,
                article, article_sort, article_title, tab_name,
                section_num, section_sort, section_title, page_num,
                trigger_keywords, watch_voice_prompt, watch_voice_answer,
                rule_preview, ladder_rung_1_chapter, ladder_rung_2_tab_article,
                ladder_rung_3_section, choice_quiz_json
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (
            drill_id,
            drill_num,
            c["chap"],
            "Bilateral NEC + Cybersecurity & Coding",
            c["art"],
            950,
            "NEC + Cyber/Programming Snippets",
            "NEC + Cyber/Programming",
            c["sec"],
            i,
            c["title"],
            24,
            c["kw"],
            watch_q,
            watch_a,
            c["front"],
            r1,
            r2,
            r3,
            json.dumps(quiz_obj)
        ))

    ts = time.strftime("%Y-%m-%d %H:%M:%S")
    h1 = hashlib.sha256(f"{ts}|CIST-1601|Bilateral".encode()).hexdigest()[:12].upper()
    cur.execute("""
        INSERT INTO academic_clock_hours_log (timestamp, course_code, activity_summary, minutes_credited, verification_hash)
        VALUES (?, ?, ?, ?, ?)
    """, (
        ts,
        "ELTR+CIST-1601",
        "Bilateral Dual-Track Credit: Primary Electrical (80%) + Secondary Cybersecurity & Python/Lua/SQL Programming (20%)",
        30.0,
        f"SHA256-{h1}"
    ))

    # Also ensure the user's verified local portfolio artifacts (ACL v21.0, TypeScript IDE v3.6.4, Scrivener Books, Mothership Hardware, Photoshop) are permanently logged!
    portfolio_entries = [
        ("AI-2010 / CIST-1305", "Verified AI Systems Architecture & Prompt Engineering Portfolio (3,465+ Logged Antigravity Steps + Gemini History)", 1800.0),
        ("DSL-3010 / CIST-2351", "Original Author & Architect of Aetheros Command Language (ACL v21.0 — 62 Opcodes) & React/TypeScript Compiler IDE v3.6.4 (aclQueryBuilder.ts)", 2700.0),
        ("ENGL-1101 / LIT-2010", "Authored Scrivener Manuscripts & Technical Treatises: 'Earth Tribe (.scriv)', 'Aetheros: The Philosophy of the Cosmic Weave', and 'Anatomy & Properties of Bamboo'", 2700.0),
        ("CIST-1122 / A+ HW", "Custom PC & Workstation Hardware Engineering (40+ Yrs: 1983 Apple IIe Architecture through Scratch-Built Custom Mothership Workstation & Local llama.cpp)", 900.0),
        ("DMPT-1000 / CIST-1530", "Digital Media Production & Full Adobe Photoshop Suite Visual Design Portfolio (Prior Learning Competency)", 600.0),
    ]
    for code, desc, mins in portfolio_entries:
        cur.execute("DELETE FROM academic_clock_hours_log WHERE course_code = ?", (code,))
        hp = hashlib.sha256(f"{ts}|{code}|{desc}".encode()).hexdigest()[:12].upper()
        cur.execute("""
            INSERT INTO academic_clock_hours_log (timestamp, course_code, activity_summary, minutes_credited, verification_hash)
            VALUES (?, ?, ?, ?, ?)
        """, (ts, code, desc, mins, f"SHA256-{hp}"))

    conn.commit()
    cur.execute("SELECT COUNT(*) FROM flashcard_drills WHERE article = 'CYBER'")
    fc_cnt = cur.fetchone()[0]
    cur.execute("SELECT COUNT(*) FROM ladder_section_drills")
    ld_cnt = cur.fetchone()[0]
    conn.close()
    print(f"SUCCESS: Added {fc_cnt} Bilateral Cyber/Coding flashcards and updated Ladder Deck to {ld_cnt} total drills!")

if __name__ == "__main__":
    main()
