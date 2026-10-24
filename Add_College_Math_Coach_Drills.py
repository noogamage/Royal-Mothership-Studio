import sqlite3
import json
import hashlib
import time

DB_PATH = r"c:\Program Files (x86)\World of Warcraft\_classic_beta_\Interface\AddOns\DeconstructionGod_Studio\NEC_Harvest_Targets\NEC_Master_Vault.sqlite"

MATH_CARDS = [
    {
        "sec": "MATH 1012 • #1",
        "title": "Percentages to Decimals: The 125% Continuous Load & 80% Breaker Rule",
        "kw": "MATH 1012 • percentage to decimal • 125% • 1.25 • 80% • 0.80 • NEC 210.20(A)",
        "front": "📐 STEP-BY-STEP COLLEGE & NEC MATH (#1 — GNTC MATH 1012):\nHow do you turn ANY percentage into a decimal multiplier on your calculator?\n• Rule: Move the decimal point 2 places to the LEFT (divide by 100)!\n  - 125% ➔ 1.25  |  80% ➔ 0.80  |  35% ➔ 0.35\n\n🧮 PRACTICE PROBLEM:\nA store has 32 Amps of LED lighting that stays on all day (Continuous Load >= 3 hours). Under NEC 210.20(A), multiply by 125%. What is the minimum amp rating?",
        "back": "✅ STEP-BY-STEP SOLUTION:\n1) Convert 125% to a decimal: 125 ÷ 100 = 1.25\n2) Multiply: 32 Amps × 1.25 = 40 Amps!\n💡 SHORTCUT TRICK: Multiplying by 1.25 is the exact same thing as adding One-Quarter (1/4) of the number to itself! One-quarter of 32 is 8, and 32 + 8 = 40 Amps!",
        "q": "In GNTC MATH 1012 and NEC 210.20(A), how do you calculate 125% of a 32-Amp continuous load?",
        "a": "32 × 1.25 = 40 Amps (or add 1/4 of 32, which is 8, to get 40 Amps)",
        "d1": "32 ÷ 1.25 = 25.6 Amps",
        "d2": "32 + 1.25 = 33.25 Amps",
        "d3": "32 × 0.80 = 25.6 Amps",
        "chap": 2
    },
    {
        "sec": "MATH 1012 • #2",
        "title": "Dividing by a Complement: The NASCLA Contractor Bid Margin Formula",
        "kw": "MATH 1012 • NASCLA • overhead • profit margin • bid price • division",
        "front": "📐 STEP-BY-STEP COLLEGE & NEC MATH (#2 — GNTC MATH 1012 & NASCLA):\nWhy do 80% of people miss the Contractor Bid question on the state exam?\n• TRAP: If Direct Costs = $60,000, Overhead = 15%, and Profit = 10% (25% total), you CANNOT just multiply $60,000 × 1.25!\n• FORMULA: Bid Price = Direct Costs ÷ (1.00 − Total %)\n\n🧮 Solve for $60,000 Direct Costs with 25% total Overhead & Profit:",
        "back": "✅ STEP-BY-STEP SOLUTION:\n1) Add Overhead + Profit: 15% + 10% = 25% = 0.25\n2) Subtract from 1.00: 1.00 − 0.25 = 0.75 (This means your $60,000 direct cost is 75% of the final bid!)\n3) Divide on your calculator: $60,000 ÷ 0.75 = $80,000 Final Bid Price!",
        "q": "Using the NASCLA & MATH 1012 margin formula, if a job has $60,000 in direct costs, 15% overhead, and 10% profit (25% total), what is the correct Bid Price?",
        "a": "$80,000 ($60,000 ÷ (1.00 − 0.25) = $60,000 ÷ 0.75)",
        "d1": "$75,000 ($60,000 × 1.25)",
        "d2": "$60,025 ($60,000 + 25)",
        "d3": "$45,000 ($60,000 × 0.75)",
        "chap": 1
    },
    {
        "sec": "MATH 1012 • #3",
        "title": "Basic Algebra Rearranging: The Ohm's Law & Watt's Law Thumb-Cover Trick",
        "kw": "MATH 1012 • algebra • Ohm's Law • Watt's Law • E=IR • P=EI • solve for X",
        "front": "📐 STEP-BY-STEP COLLEGE & NEC MATH (#3 — Basic Algebra Without Pain):\nIn College Algebra, when `Top = Bottom1 × Bottom2`, you never have to guess whether to multiply or divide! Just picture a triangle:\n• In `E = I × R` (Volts = Amps × Ohms), `E` sits on TOP!\n• In `P = E × I` (Watts = Volts × Amps), `P` sits on TOP!\n\n🧮 Cover the letter you want with your thumb:\nIf a 240V water heater is rated at 4,500 Watts (P), how many Amps (I) does it draw?",
        "back": "✅ STEP-BY-STEP SOLUTION:\n1) In `P = E × I`, Watts (`P`) is on TOP, and Volts (`E`) & Amps (`I`) are on the BOTTOM.\n2) Cover `I` (Amps) with your thumb ➔ You see `P` over `E` (`P ÷ E`)!\n3) Divide: 4,500 Watts ÷ 240 Volts = 18.75 Amps!",
        "q": "Using the Watt's Law algebra triangle (P = E × I), how many Amps (I) does a 4,500-Watt, 240-Volt water heater draw?",
        "a": "18.75 Amps (I = P ÷ E = 4,500 ÷ 240)",
        "d1": "1,080,000 Amps (4,500 × 240)",
        "d2": "0.053 Amps (240 ÷ 4,500)",
        "d3": "37.50 Amps (4,500 ÷ 120)",
        "chap": 4
    },
    {
        "sec": "MATH 1012 • #4",
        "title": "Exponents & Square Roots: Heating Power (P = I²R) & Solving for Current",
        "kw": "MATH 1012 • exponents • squared • square root • P = I^2 * R • Ugly's",
        "front": "📐 STEP-BY-STEP COLLEGE & NEC MATH (#4 — Exponents & Square Roots):\n1) What does the little `²` (squared) mean in `P = I² × R`?\n   • It NEVER means `I × 2`! It means multiply `I` by ITSELF (`I × I`)!\n2) How do you UNDO a square (`²`) in algebra? Press the Square Root (`√`) key!\n\n🧮 PRACTICE: A 10-Ohm baseboard heater carries 12 Amps (`I`). What is the power in Watts (`P = I² × R`)?",
        "back": "✅ STEP-BY-STEP SOLUTION:\n1) Square the current first (Order of Operations — PEMDAS): 12² = 12 × 12 = 144\n2) Multiply by Resistance (`R = 10 Ohms`): 144 × 10 = 1,440 Watts!\n💡 Reverse Check: If given 1,440W and 10 Ohms, `I = √(P ÷ R) = √(1440 ÷ 10) = √144 = 12 Amps`!",
        "q": "In the power formula P = I² × R, if Current (I) = 12 Amps and Resistance (R) = 10 Ohms, how many Watts of heat are produced?",
        "a": "1,440 Watts (12 × 12 = 144, then 144 × 10 = 1,440 W)",
        "d1": "240 Watts (12 × 2 × 10)",
        "d2": "120 Watts (12 × 10)",
        "d3": "14,400 Watts ((12 × 10)²)",
        "chap": 4
    },
    {
        "sec": "MATH 1012 • #5",
        "title": "Ratios & Proportions: Transformer Turns Ratio (Cross-Multiplication)",
        "kw": "MATH 1012 • ratio • proportion • cross multiply • transformer turns • Article 450",
        "front": "📐 STEP-BY-STEP COLLEGE & NEC MATH (#5 — Ratios & Cross-Multiplication):\nA 480V-to-120V step-down control transformer has a 4-to-1 ratio (`480 ÷ 120 = 4`).\n• Proportion Rule: `Primary Volts ÷ Secondary Volts = Primary Turns ÷ Secondary Turns`\n\n🧮 If the Primary coil has 800 turns of wire (`Np = 800`), how many turns are on the 120V Secondary coil (`Ns`)?",
        "back": "✅ STEP-BY-STEP SOLUTION:\n1) Set up the fraction proportion: `480 / 120 = 800 / Ns`\n2) Cross-Multiply & Divide (or divide by the 4:1 ratio):\n   `Ns = (120 × 800) ÷ 480 = 96,000 ÷ 480 = 200 turns`!\n💡 Bonus Rule: Voltage steps DOWN 4-to-1 (480V ➔ 120V), while available Current (Amps) steps UP 4-to-1!",
        "q": "A 480V primary to 120V secondary step-down transformer (4:1 ratio) has 800 primary turns. How many turns are on the secondary winding?",
        "a": "200 turns (800 ÷ 4 = 200)",
        "d1": "3,200 turns (800 × 4)",
        "d2": "400 turns (800 ÷ 2)",
        "d3": "600 turns (800 − 200)",
        "chap": 4
    },
    {
        "sec": "MATH 1012 • #6",
        "title": "Circle Geometry & NEC Chapter 9 Conduit Fill (40% Rule & Area = πr²)",
        "kw": "MATH 1012 • geometry • circle area • pi r squared • Chapter 9 Table 4 • 40% conduit fill",
        "front": "📐 STEP-BY-STEP COLLEGE & NEC MATH (#6 — Geometry & Conduit Fill):\n1) In geometry, the Cross-Sectional Area of a round wire or pipe is:\n   `Area = π × r²` (where `π ≈ 3.1416` and radius `r = Diameter ÷ 2`).\n2) Under NEC Chapter 9 Table 1, when pulling 3 or more wires in a conduit, the wires can fill at most **40%** (`0.40`) of the pipe's total internal area!\n\n🧮 If eight #12 THHN wires each have an area of `0.0133 sq.in.` (Table 5), what is their total wire area?",
        "back": "✅ STEP-BY-STEP SOLUTION:\n1) Multiply number of wires × area of 1 wire:\n   `8 × 0.0133 sq.in. = 0.1064 sq.in.` total wire area.\n2) Look in NEC Chapter 9 Table 4 under the **Over 2 Wires (40%)** column and pick the conduit whose 40% area is `>= 0.1064 sq.in.` (1/2-inch EMT is `0.122 sq.in.`, so 8 #12 THHN wires fit in 1/2\" EMT!).",
        "q": "Under NEC Chapter 9 Table 1 & Table 5, if one #12 THHN wire has an area of 0.0133 sq.in., what is the total area of 8 wires, and which Table 4 column do you check?",
        "a": "0.1064 sq.in. (8 × 0.0133); check the 'Over 2 Wires (40%)' column in Table 4",
        "d1": "0.8000 sq.in.; check the '1 Wire (53%)' column",
        "d2": "0.0133 sq.in.; check the '2 Wires (31%)' column",
        "d3": "1.064 sq.in.; check the '100% Total Area' column",
        "chap": 9
    },
    {
        "sec": "MATH 1012 • #7",
        "title": "Piecewise Percentages: NEC Table 220.42 House Lighting Demand Math",
        "kw": "MATH 1012 • piecewise function • Table 220.42 • 3 VA per sq ft • 35% demand factor",
        "front": "📐 STEP-BY-STEP COLLEGE & NEC MATH (#7 — Multi-Step House Load Math):\nLet's do a full NEC Article 220 Dwelling General Lighting + Small Appliance + Laundry calculation in 4 easy steps for a **2,000 sq.ft. house**:\n1) Lighting: `2,000 sq.ft. × 3 VA = 6,000 VA`\n2) Add 2 Kitchen Small-Appliance circuits (`3,000 VA`) + 1 Laundry circuit (`1,500 VA`) = `10,500 VA Total`.\n\n🧮 Now apply Table 220.42 (First 3,000 VA at 100%, Remainder at 35%):",
        "back": "✅ STEP-BY-STEP SOLUTION:\n1) Subtract the first 3,000 VA from 10,500 VA:\n   `10,500 − 3,000 = 7,500 VA Remainder`\n2) Multiply the 7,500 VA Remainder by 35% (`0.35`):\n   `7,500 × 0.35 = 2,625 VA`\n3) Add the first 3,000 VA back in:\n   `3,000 + 2,625 = 5,625 VA Net Demand Load`!",
        "q": "A 2,000 sq.ft. house has 6,000 VA lighting + 3,000 VA small appliance + 1,500 VA laundry = 10,500 VA total. Applying Table 220.42 (first 3,000 VA @ 100%, remainder @ 35%), what is the net demand load?",
        "a": "5,625 VA (3,000 + ((10,500 − 3,000) × 0.35) = 3,000 + 2,625)",
        "d1": "10,500 VA (100% of everything)",
        "d2": "3,675 VA (10,500 × 0.35)",
        "d3": "7,500 VA (10,500 − 3,000)",
        "chap": 2
    },
    {
        "sec": "MATH 1111 • #8",
        "title": "College Algebra Equations: Single-Phase Voltage Drop (VD = 2·K·I·D / CM)",
        "kw": "MATH 1111 • algebra • voltage drop • 2 K I D / CM • Copper K=12.9 • circular mils",
        "front": "📐 STEP-BY-STEP COLLEGE & NEC MATH (#8 — GNTC MATH 1111 Multi-Variable Formula):\nThe Single-Phase Voltage Drop formula is:\n`VD = (2 × K × I × D) ÷ CM`\n• `2` = 2-way round trip (out on hot, back on neutral)\n• `K` = `12.9` for Copper (or `21.2` for Aluminum)\n• `I` = Amps | `D` = One-way distance in feet | `CM` = Wire Circular Mils (Chapter 9 Table 8: `#10 AWG = 10,380 CM`).\n\n🧮 Find the Voltage Drop for `20 Amps` at `100 Feet` on `#10 Copper (10,380 CM)`:",
        "back": "✅ STEP-BY-STEP SOLUTION:\n1) Multiply the TOP numbers together (`2 × K × I × D`):\n   `2 × 12.9 × 20 × 100 = 51,600`\n2) Divide by the BOTTOM number (`CM = 10,380`):\n   `51,600 ÷ 10,380 = 4.97 Volts dropped`!\n💡 Algebra Swap: If you know the max allowed Voltage Drop (`VD`) and need to solve for Wire Size (`CM`), just swap `VD` and `CM`: `CM = (2 × K × I × D) ÷ VD`!",
        "q": "Using VD = (2 × K × I × D) ÷ CM with Copper (K = 12.9), Current I = 20 A, Distance D = 100 ft, and #10 AWG (CM = 10,380), what is the single-phase voltage drop?",
        "a": "4.97 Volts (51,600 ÷ 10,380 = 4.97 V)",
        "d1": "2.48 Volts (forgot the × 2 round-trip factor)",
        "d2": "10.38 Volts",
        "d3": "51.60 Volts",
        "chap": 9
    },
    {
        "sec": "MATH 1111 • #9",
        "title": "The Magic 3-Phase Number: √3 = 1.732 & 3-Phase Voltage Drop",
        "kw": "MATH 1111 • square root of 3 • 1.732 • three phase • voltage drop • 208V • 480V",
        "front": "📐 STEP-BY-STEP COLLEGE & NEC MATH (#9 — Why 3-Phase Always Uses 1.732):\nWhy do electricians see `1.732` everywhere in 3-phase power?\n• Because the 3 phases are 120° apart on a circle, trig proves the phase-to-phase vector is `√3` (`Square Root of 3 ≈ 1.732`)!\n  - Notice: `120V × 1.732 = 208V`! And `277V × 1.732 = 480V`!\n• In 3-Phase Voltage Drop, simply replace the `2` with `1.732`:\n  `VD_3Φ = (1.732 × K × I × D) ÷ CM`",
        "back": "✅ STEP-BY-STEP SOLUTION:\n1) Why does `120V` line-to-neutral become `208V` line-to-line (and NOT 240V) on a 3-phase Wye panel?\n   Because `120 × √3 = 120 × 1.732 = 207.84V ≈ 208V`!\n2) Why does `277V` line-to-neutral become `480V` line-to-line?\n   Because `277 × 1.732 = 479.76V ≈ 480V`!\n3) Memorize `1.732`—it is your best friend on every 3-phase college & licensing exam!",
        "q": "Where does the number 1.732 come from in 3-phase electrical formulas, and what is 120 Volts multiplied by 1.732?",
        "a": "It is the Square Root of 3 (√3 ≈ 1.732); 120V × 1.732 = 208 Volts (3-Phase Wye line-to-line voltage)",
        "d1": "It is Pi divided by 2; 120V × 1.732 = 240 Volts",
        "d2": "It is the resistance of copper; 120V × 1.732 = 480 Volts",
        "d3": "It is 3 divided by 2; 120V × 1.732 = 180 Volts",
        "chap": 9
    },
    {
        "sec": "MATH 1111 • #10",
        "title": "3-Phase Transformer & Feeder Amps: I = (kVA × 1,000) ÷ (V × 1.732)",
        "kw": "MATH 1111 • 3-phase kVA • transformer full load amps • 1.732 • Article 450",
        "front": "📐 STEP-BY-STEP COLLEGE & NEC MATH (#10 — 3-Phase Transformer Amps):\nThis question is guaranteed to appear on your GNTC AC Circuits test AND your Georgia/Tennessee Master Electrician exam!\n• Formula: `Amps (I) = (kVA × 1,000) ÷ (Volts × 1.732)`\n  *(Tip: Always put parentheses around `Volts × 1.732` on your calculator first: `208 × 1.732 = 360`, or `480 × 1.732 = 831`!)*\n\n🧮 How many Full-Load Amps is a `75 kVA`, `208V 3-Phase` transformer?",
        "back": "✅ STEP-BY-STEP SOLUTION:\n1) Convert `75 kVA` to Volt-Amps (`× 1,000`): `75 × 1,000 = 75,000 VA`\n2) Multiply the bottom (`208V × 1.732`): `208 × 1.732 = 360.25`\n3) Divide Top by Bottom: `75,000 ÷ 360.25 = 208.19 Amps`!\n💡 COOL TRICK FOR 208V 3-PHASE: Since `208 × 1.732 = 360`, a `36 kVA` transformer is `100 Amps`, and a `75 kVA` transformer is right at `208 Amps`!",
        "q": "Using I = (kVA × 1,000) ÷ (Volts × 1.732), what is the secondary full-load current of a 75 kVA, 208V 3-phase transformer?",
        "a": "208.2 Amps (75,000 ÷ (208 × 1.732) = 75,000 ÷ 360.25 = 208.2 A)",
        "d1": "360.6 Amps (75,000 ÷ 208, forgetting 1.732)",
        "d2": "90.2 Amps (used 480V instead of 208V)",
        "d3": "125.0 Amps",
        "chap": 4
    },
    {
        "sec": "AC TRIG • #11",
        "title": "Right-Triangle Trigonometry: AC Impedance (Z = √(R² + XL²))",
        "kw": "ELTR 1090 • trigonometry • Pythagorean theorem • impedance Z • resistance R • inductive reactance XL • 3-4-5 triangle",
        "front": "📐 STEP-BY-STEP COLLEGE & NEC MATH (#11 — AC Circuit Right-Triangle Math):\nIn GNTC `ELTR 1090 (Alternating Current)`, why can't you just add Resistance (`R`) + Coil Reactance (`XL`) normally?\n• Because a coil's magnetic field shifts the wave by **90 degrees** (forming a Right Triangle)!\n• Use the **Pythagorean Theorem**: `Z = √(R² + XL²)`\n\n🧮 Classic '3-4-5' Exam Problem: A motor coil has `R = 3 Ohms` of resistance and `XL = 4 Ohms` of inductive reactance. What is the Total Impedance (`Z`)?",
        "back": "✅ STEP-BY-STEP SOLUTION:\n1) Square `R`: `3² = 3 × 3 = 9`\n2) Square `XL`: `4² = 4 × 4 = 16`\n3) Add them together: `9 + 16 = 25`\n4) Take the Square Root (`√25`): `Z = 5 Ohms`!\n💡 Memorize the **3 - 4 - 5** and **6 - 8 - 10** Right Triangles—college professors love using `(3, 4 ➔ 5)` and `(6, 8 ➔ 10)` on AC Impedance tests!",
        "q": "In an AC series circuit with Resistance R = 3 Ohms and Inductive Reactance XL = 4 Ohms, what is the Total Impedance (Z = √(R² + XL²))?",
        "a": "5 Ohms (√(3² + 4²) = √(9 + 16) = √25 = 5 Ohms)",
        "d1": "7 Ohms (3 + 4)",
        "d2": "25 Ohms (forgot to take the square root)",
        "d3": "12 Ohms (3 × 4)",
        "chap": 4
    },
    {
        "sec": "AC TRIG • #12",
        "title": "Power Factor & Cosine: True Power (kW) vs. Apparent Power (kVA)",
        "kw": "ELTR 1090 • power factor • cosine • True Power kW • Apparent Power kVA • efficiency",
        "front": "📐 STEP-BY-STEP COLLEGE & NEC MATH (#12 — Power Factor & Trig Cosine):\nIn AC circuits, **Power Factor (`PF`)** is simply the **Cosine (`cos θ`)** of the phase angle, or:\n• `Power Factor (PF) = True Power (kW) ÷ Apparent Power (kVA)`\n• Rearranged: `True Power (Watts) = Volts × Amps × PF`\n\n🧮 An industrial AC load draws `20 kVA` of Apparent Power from the transformer, and a wattmeter reads `16 kW` of True Power. What is the Power Factor (`PF`)?",
        "back": "✅ STEP-BY-STEP SOLUTION:\n1) Divide True Power (`kW`) by Apparent Power (`kVA`):\n   `PF = 16 kW ÷ 20 kVA = 0.80` (or **80% Power Factor**!)\n2) Why does an electrician care? Because if a load has an `80%` (`0.80`) Power Factor, it draws `25% MORE Amps` (`1 ÷ 0.80 = 1.25`) through your wires than a 100% resistive heater of the same kW!",
        "q": "If a 3-phase industrial machine uses 16 kW of True Power while drawing 20 kVA of Apparent Power, what is its Power Factor (PF = kW ÷ kVA)?",
        "a": "0.80 or 80% (16 kW ÷ 20 kVA = 0.80)",
        "d1": "1.25 or 125% (20 ÷ 16)",
        "d2": "4.0 or 40% (20 − 16)",
        "d3": "1.00 or 100%",
        "chap": 4
    },
    {
        "sec": "MATH 1012 • #13",
        "title": "Linear Equations in NEC 314.28: Large Pull Box Sizing (8× vs 6×)",
        "kw": "MATH 1012 • linear equation • pull box • NEC 314.28 • 8x straight pull • 6x angle pull",
        "front": "📐 STEP-BY-STEP COLLEGE & NEC MATH (#13 — Pull Box Linear Equations):\nFor conduits containing `#4 AWG` or larger wires (NEC 314.28):\n• **Straight Pull**: `Length = 8 × Largest Conduit`\n• **Angle or U-Pull**: `Distance = (6 × Largest Conduit) + Sum of ALL OTHER conduits in the same row`!\n\n🧮 An Angle Pull box has one `3-inch` conduit and two `2-inch` conduits entering the same wall. What is the minimum distance to the opposite wall?",
        "back": "✅ STEP-BY-STEP SOLUTION:\n1) Identify the LARGEST conduit in the row: `3 inches`.\n2) Multiply Largest × 6: `6 × 3\" = 18 inches`.\n3) Add the other two `2-inch` conduits in the same row: `18\" + 2\" + 2\" = 22 inches` minimum box dimension!",
        "q": "Under NEC 314.28(A)(2), a junction box for an Angle Pull has one 3-inch conduit and two 2-inch conduits in the same row. What is the minimum distance to the opposite wall?",
        "a": "22 inches ((6 × 3\") + 2\" + 2\" = 18 + 4 = 22 inches)",
        "d1": "24 inches (8 × 3\")",
        "d2": "18 inches (6 × 3\" only, forgetting to add the other conduits)",
        "d3": "42 inches (6 × (3 + 2 + 2))",
        "chap": 3
    },
    {
        "sec": "CS MATH • #14",
        "title": "Bilateral Computer Science Math: Base-2 Binary & Base-16 Hexadecimal",
        "kw": "Discrete Math • CIST • Binary • Base-2 • Hexadecimal • Base-16 • PLC register • IPv4 subnet",
        "front": "💻📐 BILATERAL CS & PLC MATH (#14 — Binary & Hexadecimal Made Simple):\nBoth Industrial PLCs (Modbus/Allen-Bradley) and Cybersecurity networks count in **Base-2 Binary**! Each bit doubles from right to left:\n`[ 128 | 64 | 32 | 16 | 8 | 4 | 2 | 1 ]`\n• Put a `1` under the numbers you want to turn ON (close the switch) and add them up!\n\n🧮 What decimal number is the 4-bit binary nibble `1010`, and what is `11111111` (all 8 bits ON)?",
        "back": "✅ STEP-BY-STEP SOLUTION:\n1) For `1010` using columns `[ 8 | 4 | 2 | 1 ]`:\n   `8 is ON (1) + 4 is OFF (0) + 2 is ON (1) + 1 is OFF (0)` ➔ `8 + 2 = 10` (which is written as `0xA` in Hexadecimal)!\n2) When all 8 bits are ON (`11111111` = `0xFF` in Hex):\n   `128 + 64 + 32 + 16 + 8 + 4 + 2 + 1 = 255`! (That's why IPv4 subnet masks look like `255.255.255.0`!)",
        "q": "In Base-2 Binary (used in PLC registers and IPv4 networking), what decimal value is the 4-bit binary number `1010`, and what is `11111111` (all 8 bits ON)?",
        "a": "`1010` = 10 (8 + 2); `11111111` = 255 (which is why subnet masks use 255.255.255.0)",
        "d1": "`1010` = 2; `11111111` = 8",
        "d2": "`1010` = 100; `11111111` = 1,000",
        "d3": "`1010` = 15; `11111111` = 512",
        "chap": 7
    },
    {
        "sec": "CS MATH • #15",
        "title": "Boolean Algebra = Electrical Ladder Logic! (AND, OR, NOT Gates)",
        "kw": "Discrete Math • Boolean Algebra • AND gate • OR gate • NOT gate • PLC Ladder Logic • series • parallel",
        "front": "💻📐 BILATERAL CS & PLC MATH (#15 — Boolean Algebra Is Just Electrical Switches!):\nIn your Bachelor's & Master's Computer Science math, **Boolean Algebra** was literally invented to describe electrical relay circuits!\n• **Boolean `AND` (`A · B`)** = Two switches wired in **SERIES** (BOTH Switch A AND Switch B must close for the light to turn on!).\n• **Boolean `OR` (`A + B`)** = Two switches wired in **PARALLEL** (EITHER Switch A OR Switch B closing turns the light on!).\n• **Boolean `NOT` (`!A`)** = A **Normally Closed (NC)** stop button!",
        "back": "✅ WHY ELECTRICIANS ACE BOOLEAN MATH:\n1) On an OSHA 2-hand safety punch press, Left Button (`A`) AND Right Button (`B`) are wired in **SERIES** (`Output = A AND B`).\n2) On a 3-location warehouse fire alarm pull station, Pull 1 (`A`) OR Pull 2 (`B`) are wired in **PARALLEL** (`Output = A OR B`).\n3) In Python & Lua: `if switch_a and switch_b:` is a Series circuit; `if switch_a or switch_b:` is a Parallel circuit!",
        "q": "In Boolean Algebra and PLC Ladder Logic, how do Boolean `AND` and Boolean `OR` correspond to physical electrical switch wiring?",
        "a": "`AND` = Switches wired in SERIES (all must close); `OR` = Switches wired in PARALLEL (any one closing completes the circuit)",
        "d1": "`AND` = Parallel wiring; `OR` = Series wiring",
        "d2": "`AND` = Ground fault; `OR` = Short circuit",
        "d3": "`AND` = AC voltage; `OR` = DC voltage",
        "chap": 7
    },
    {
        "sec": "SHAMAN MATH • #16",
        "title": "WoW Level 60 Elemental Shaman Talent Math: Cast-Time Throughput & Crit Multipliers",
        "kw": "WoW Forever • Level 60 • Elemental Shaman • Lightning Mastery • Elemental Fury • throughput math",
        "front": "⚡📐 WOW .EDU ELEMENTAL SHAMAN MATH (#16 — Rate & Throughput Algebra):\nAt Level 40 in WoW: Forever, 5/5 *Lightning Mastery* reduces your *Lightning Bolt* cast time from `2.5 seconds` down to `2.0 seconds` (`-0.5s`).\n• Common Math Trap: Reducing cast time by `0.5s / 2.5s = 20%` does NOT increase your spells-per-minute by 20%—it increases throughput by **25%**!\n\n🧮 Why does going from `2.5s` per cast to `2.0s` per cast give you **+25% more casts** in a 60-second boss fight?",
        "back": "✅ STEP-BY-STEP RATE ALGEBRA (`Rate = Time ÷ Cast_Duration`):\n1) At `2.5s` cast time: `60 seconds ÷ 2.5s = 24 Lightning Bolts` per minute.\n2) At `2.0s` cast time: `60 seconds ÷ 2.0s = 30 Lightning Bolts` per minute.\n3) Percentage Increase (`(New − Old) ÷ Old`): `(30 − 24) ÷ 24 = 6 ÷ 24 = 0.25 = +25% More Bolts`!\n💡 Electrical Equivalent: Reducing circuit impedance (`Z`) to `80%` (`0.80`) increases current flow (`I = E ÷ Z`) by `1 ÷ 0.80 = 1.25` (**+25%** — NEC 210.20(A) reciprocal!).",
        "q": "Why does reducing Lightning Bolt's cast time by 20% (from 2.5s to 2.0s) — or reducing circuit impedance to 80% — increase total output by +25%?",
        "a": "Because dividing by 0.80 is the reciprocal of 4/5, which equals 5/4 = 1.25 (+25% more casts per minute: 30 vs 24)",
        "d1": "It only increases output by 5%",
        "d2": "It reduces output by 20%",
        "d3": "Because 2.5 + 2.0 = 4.5",
        "chap": 2
    }
]

def main():
    conn = sqlite3.connect(DB_PATH)
    cur = conn.cursor()

    cur.execute("DELETE FROM flashcard_drills WHERE article = 'MATH'")
    cur.execute("DELETE FROM ladder_section_drills WHERE article = 'MATH'")

    for i, c in enumerate(MATH_CARDS, start=1):
        card_id = f"MATH_COACH_{i:03d}"
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
            "COLLEGE_MATH_COACH",
            "College & Master Electrician Math Coach",
            "MATH",
            c["sec"],
            "College & Master Electrician Step-by-Step Math Coach",
            f"Math Ladder ➔ {c['sec']} ({c['title']})",
            c["title"],
            c["front"],
            f"✅ {c['sec']} — {c['title']}",
            c["back"],
            json.dumps({"keywords": c["kw"]}),
            json.dumps(quiz_obj),
            c["chap"],
            960,
            i
        ))

        drill_num = 1014 + i
        drill_id = f"LADDER_{drill_num:04d}"
        r1 = f"Rung 1 (Formula Selection — {c['sec']})"
        r2 = f"Rung 2 (Plug In Numbers & Order of Operations)"
        r3 = f"Rung 3 (Step-by-Step Solution): {c['title']}"
        watch_q = f"College and Electrical Math Drill {drill_num}. {c['q']}"
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
            "College & Master Electrician Math Coach",
            "MATH",
            960,
            "MATH 1012 / 1111 / AC Trig / Binary Math",
            "Math Coach (MATH 1012 & 1111)",
            c["sec"],
            i,
            c["title"],
            25,
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
    cur.execute("DELETE FROM academic_clock_hours_log WHERE course_code = 'MATH-1012 / MATH-1111'")
    hm = hashlib.sha256(f"{ts}|MATH-1012|MathCoach".encode()).hexdigest()[:12].upper()
    cur.execute("""
        INSERT INTO academic_clock_hours_log (timestamp, course_code, activity_summary, minutes_credited, verification_hash)
        VALUES (?, ?, ?, ?, ?)
    """, (
        ts,
        "MATH-1012 / MATH-1111",
        "Applied Technical Mathematics & College Algebra Track: Percentages, Ohm/Watt Algebra, 3-Phase √3 Trig, Voltage Drop & Binary/Boolean CS Math",
        900.0,
        f"SHA256-{hm}"
    ))

    conn.commit()
    cur.execute("SELECT COUNT(*) FROM flashcard_drills WHERE article = 'MATH'")
    fc_cnt = cur.fetchone()[0]
    cur.execute("SELECT COUNT(*) FROM ladder_section_drills")
    ld_cnt = cur.fetchone()[0]
    conn.close()
    print(f"SUCCESS: Added {fc_cnt} College & Master Electrician Math Coach drills! Total Ladder Drills = {ld_cnt}")

if __name__ == "__main__":
    main()
