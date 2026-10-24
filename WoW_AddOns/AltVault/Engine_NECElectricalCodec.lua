-- ============================================================================
-- FILE: Engine_NECElectricalCodec.lua
-- PURPOSE: Dual-Purpose WoW Gameplay + Master Electrician NEC Formula & Ladder-Logic
--          Engine inside AltVault! Translates live WoW character stats, combat telemetry,
--          bag slots, and range distances into real NEC Master Exam formulas:
--            1. Ohm's Law & Power Wheel (P = E × I, I = P / E, R = E / I)
--            2. NEC 210.20(A) & 215.3 Continuous Load 125% OCPD Breaker Sizing
--               & NEC 240.6(A) Standard Ampere Rating Selection
--            3. NEC Table 310.16 (TN 310.15(B)(16)) 75°C Copper Conductor Sizing
--            4. Ugly's / NEC Voltage Drop Formula: VD = (2 × K × I × L) / CM
--            5. NEC 314.16(B) Box Fill Volume Calculator (TN 2017 vs GA 2023 EGC Rule!)
--            6. In-Game Ladder-Logic Section Finder HUD & /nec Slash Command!
-- ============================================================================
local addonName, ns = ...

local NECCodec = {}
ns.NECCodec = NECCodec

-- ============================================================================
-- 1. NEC TABLE 240.6(A) STANDARD OVERCURRENT DEVICE RATINGS (AMPS)
-- ============================================================================
local NEC_240_6A_BREAKERS = {
    15, 20, 25, 30, 35, 40, 45, 50, 60, 70, 80, 90, 100,
    110, 125, 150, 175, 200, 225, 250, 300, 350, 400, 450, 500, 600
}

-- ============================================================================
-- 2. NEC TABLE 310.16 (TN 2017: TABLE 310.15(B)(16)) 75°C COPPER AMPACITY
--    & CHAPTER 9 TABLE 8 CIRCULAR MILS (CM)
-- ============================================================================
local NEC_310_16_COPPER_75C = {
    { awg = "#14 AWG", amps75 = 15,  cm = 4110,   note = "240.4(D) Small Conductor Cap = 15A" },
    { awg = "#12 AWG", amps75 = 20,  cm = 6530,   note = "240.4(D) Small Conductor Cap = 20A" },
    { awg = "#10 AWG", amps75 = 30,  cm = 10380,  note = "240.4(D) Small Conductor Cap = 30A" },
    { awg = "#8 AWG",  amps75 = 50,  cm = 16510,  note = "75°C Terminal Column (110.14(C))" },
    { awg = "#6 AWG",  amps75 = 65,  cm = 26240,  note = "75°C Terminal Column (110.14(C))" },
    { awg = "#4 AWG",  amps75 = 85,  cm = 41740,  note = "75°C Terminal Column (110.14(C))" },
    { awg = "#3 AWG",  amps75 = 100, cm = 52620,  note = "75°C Terminal Column (110.14(C))" },
    { awg = "#2 AWG",  amps75 = 115, cm = 66360,  note = "75°C Terminal Column (110.14(C))" },
    { awg = "#1 AWG",  amps75 = 130, cm = 83690,  note = "75°C Terminal Column (110.14(C))" },
    { awg = "1/0 AWG", amps75 = 150, cm = 105600, note = "75°C Terminal Column (110.14(C))" },
    { awg = "2/0 AWG", amps75 = 175, cm = 133100, note = "75°C Terminal Column (110.14(C))" },
    { awg = "3/0 AWG", amps75 = 200, cm = 167800, note = "75°C Terminal Column (110.14(C))" },
    { awg = "4/0 AWG", amps75 = 230, cm = 211600, note = "75°C Terminal Column (110.14(C))" },
    { awg = "250 kcmil", amps75 = 255, cm = 250000, note = "75°C Large Conductor" },
    { awg = "350 kcmil", amps75 = 310, cm = 350000, note = "75°C Large Conductor" },
    { awg = "500 kcmil", amps75 = 380, cm = 500000, note = "75°C Large Conductor" },
}

-- ============================================================================
-- 3. CURATED HIGH-YIELD LADDER-LOGIC KEYWORD DRILLS FOR IN-GAME HUD
-- ============================================================================
local WOW_LADDER_DRILLS = {
    { kw = "Purpose, Practical Safeguarding, Not a Design Manual", sec = "NEC 90.1", chap = "Ch. 1 General", tab = "Tab 1 (Art. 90)" },
    { kw = "Mandatory Rules ('Shall') vs Permissive ('Shall Be Permitted')", sec = "NEC 90.5", chap = "Ch. 1 General", tab = "Tab 1 (Art. 90)" },
    { kw = "Readily Accessible (No Ladders, No Tools, No Obstacles)", sec = "NEC Art. 100", chap = "Ch. 1 General", tab = "Tab 2 (Art. 100)" },
    { kw = "Continuous Load (Maximum Current for 3 Hours or More)", sec = "NEC Art. 100", chap = "Ch. 1 General", tab = "Tab 2 (Art. 100)" },
    { kw = "Terminal Temperature Limits: <=100A (60°C) vs >100A (75°C)", sec = "NEC 110.14(C)", chap = "Ch. 1 General", tab = "Tab 3 (Art. 110)" },
    { kw = "Working Space Clearances: 30 in. Wide, 3/3.5/4 ft Deep, 6.5 ft High", sec = "NEC 110.26(A)", chap = "Ch. 1 General", tab = "Tab 3 (Art. 110)" },
    { kw = "GFCI Protection for Personnel in Dwelling Units & Bathrooms", sec = "NEC 210.8(A)", chap = "Ch. 2 Wiring", tab = "Tab 5 (Art. 210)" },
    { kw = "AFCI Arc-Fault Protection in Dwelling Unit Bedrooms & Rooms", sec = "NEC 210.12", chap = "Ch. 2 Wiring", tab = "Tab 5 (Art. 210)" },
    { kw = "Branch-Circuit Continuous Load OCPD = 125% Continuous + 100% Non-Cont", sec = "NEC 210.20(A)", chap = "Ch. 2 Wiring", tab = "Tab 5 (Art. 210)" },
    { kw = "Dwelling Wall Countertop & 6-Foot / 12-Foot Receptacle Spacing", sec = "NEC 210.52(A)&(C)", chap = "Ch. 2 Wiring", tab = "Tab 5 (Art. 210)" },
    { kw = "Dwelling General Lighting Load = 3 VA per Square Foot", sec = "NEC 220.12 / 220.14(J)", chap = "Ch. 2 Wiring", tab = "Tab 7 (Art. 220)" },
    { kw = "Household Electric Ranges Demand Factor (12 kW Base = 8 kW)", sec = "NEC Table 220.55", chap = "Ch. 2 Wiring", tab = "Tab 7 (Art. 220)" },
    { kw = "Service Drop Overhead Vertical Clearance Over Roofs & Driveways", sec = "NEC 230.24", chap = "Ch. 2 Wiring", tab = "Tab 9 (Art. 230)" },
    { kw = "Maximum Number of Service Disconnects (Six-Disconnect Rule)", sec = "NEC 230.71", chap = "Ch. 2 Wiring", tab = "Tab 9 (Art. 230)" },
    { kw = "Next Higher Standard Overcurrent Device Rating (<= 800 Amps)", sec = "NEC 240.4(B)", chap = "Ch. 2 Wiring", tab = "Tab 10 (Art. 240)" },
    { kw = "Small Conductor Overcurrent Caps (#14=15A, #12=20A, #10=30A)", sec = "NEC 240.4(D)", chap = "Ch. 2 Wiring", tab = "Tab 10 (Art. 240)" },
    { kw = "Standard Ampere Ratings for Fuses and Inverse-Time Breakers", sec = "NEC 240.6(A)", chap = "Ch. 2 Wiring", tab = "Tab 10 (Art. 240)" },
    { kw = "Feeder Tap Rules (10-Foot Tap Rule & 25-Foot Tap Rule)", sec = "NEC 240.21(B)", chap = "Ch. 2 Wiring", tab = "Tab 10 (Art. 240)" },
    { kw = "Grounding Electrode Conductor (GEC) Sizing by Service Wire Size", sec = "NEC Table 250.66", chap = "Ch. 2 Wiring", tab = "Tab 11 (Art. 250)" },
    { kw = "Equipment Grounding Conductor (EGC) Sizing by Breaker Rating", sec = "NEC Table 250.122", chap = "Ch. 2 Wiring", tab = "Tab 11 (Art. 250)" },
    { kw = "Minimum Cover Requirements / Underground Trench Burial Depth", sec = "NEC Table 300.5", chap = "Ch. 3 Methods", tab = "Tab 12 (Art. 300)" },
    { kw = "Allowable Ampacities of Insulated Conductors (60°C / 75°C / 90°C)", sec = "NEC Table 310.16 (TN: 310.15(B)(16))", chap = "Ch. 3 Methods", tab = "Tab 13 (Art. 310)" },
    { kw = "More Than 3 Current-Carrying Conductors in a Raceway Derating", sec = "NEC Table 310.15(C)(1) (TN: 310.15(B)(3)(a))", chap = "Ch. 3 Methods", tab = "Tab 13 (Art. 310)" },
    { kw = "Outlet Box Fill Volume Allowances (#14=2.0, #12=2.25, #10=2.5 cu.in.)", sec = "NEC Table 314.16(B)", chap = "Ch. 3 Methods", tab = "Tab 15 (Art. 314)" },
    { kw = "Pull and Junction Boxes (#4 AWG & Larger: 8x Straight, 6x Angle)", sec = "NEC 314.28(A)", chap = "Ch. 3 Methods", tab = "Tab 15 (Art. 314)" },
    { kw = "Romex (NM Cable) Securing Within 12 Inches & Every 4.5 Feet", sec = "NEC 334.30", chap = "Ch. 3 Methods", tab = "Tab 16 (Art. 334)" },
    { kw = "EMT Conduit Securing Within 3 Feet of Box & Every 10 Feet", sec = "NEC 358.30(A)", chap = "Ch. 3 Methods", tab = "Tab 17 (Art. 358)" },
    { kw = "Motor Full-Load Current (Use FLC Tables 430.248/250, NOT Nameplate!)", sec = "NEC 430.6(A)(1)", chap = "Ch. 4 Equipment", tab = "Tab 23 (Art. 430)" },
    { kw = "Single Motor Branch-Circuit Conductor Sizing = 125% of FLC", sec = "NEC 430.22", chap = "Ch. 4 Equipment", tab = "Tab 23 (Art. 430)" },
    { kw = "Motor Short-Circuit & Ground-Fault Breaker/Fuse Percentages", sec = "NEC Table 430.52", chap = "Ch. 4 Equipment", tab = "Tab 23 (Art. 430)" },
    { kw = "Transformer Primary & Secondary Overcurrent Protection (125% / 250%)", sec = "NEC Table 450.3(B)", chap = "Ch. 4 Equipment", tab = "Tab 25 (Art. 450)" },
    { kw = "Swimming Pool Equipotential Bonding Grid (#8 AWG Solid Copper)", sec = "NEC 680.26", chap = "Ch. 6 Special Equip", tab = "Tab 31 (Art. 680)" },
    { kw = "NFPA 70E Live-Dead-Live Voltmeter Absence-of-Voltage Verification", sec = "NFPA 70E Art. 120.5", chap = "Book #2: NFPA 70E", tab = "Art. 120 LOTO" },
    { kw = "OSHA Construction Temporary GFCI vs Assured Grounding (AEGCP)", sec = "29 CFR 1926.404(b)(1)", chap = "Book #3: OSHA 1926", tab = "Subpart K Electrical" },
    { kw = "NASCLA Bid Price Formula = Direct Costs ÷ (1.00 - (OH% + Profit%))", sec = "NASCLA Ch. 7 Estimating", chap = "Book #4: NASCLA", tab = "Estimating Tab" },
}

-- ============================================================================
-- 4. PURE ELECTRICAL FORMULA FUNCTIONS USED TO SCORE & ANALYZE WOW GAMEPLAY!
-- ============================================================================

-- Formula 1: Select standard NEC 240.6(A) breaker for a continuous load (125% rule)
function NECCodec.CalcContinuousOCPD(loadAmps)
    local requiredAmps = loadAmps * 1.25 -- NEC 210.20(A) / 215.3 Continuous Load Rule
    for _, rating in ipairs(NEC_240_6A_BREAKERS) do
        if rating >= requiredAmps then
            return rating, requiredAmps
        end
    end
    return 600, requiredAmps
end

-- Formula 2: Select minimum 75°C Copper Conductor from NEC Table 310.16
function NECCodec.SelectCopperConductor75C(requiredAmps)
    for _, row in ipairs(NEC_310_16_COPPER_75C) do
        if row.amps75 >= requiredAmps then
            return row
        end
    end
    return NEC_310_16_COPPER_75C[#NEC_310_16_COPPER_75C]
end

-- Formula 3: Ugly's / NEC Single-Phase Copper Voltage Drop: VD = (2 * K * I * L) / CM
function NECCodec.CalcVoltageDrop(volts, amps, distanceFeet, circularMils)
    local K = 12.9 -- Copper K-factor (ohms per circular mil-foot at 75°C)
    local cm = (circularMils and circularMils > 0) and circularMils or 16510
    local vd = (2 * K * amps * distanceFeet) / cm
    local pct = (volts > 0) and ((vd / volts) * 100) or 0
    return vd, pct
end

-- Formula 4: NEC 314.16(B) Box Fill Calculator (Maps Equipped Gear + Bags to Cubic Inches!)
function NECCodec.CalcLiveBoxFillFromInventory()
    -- Count equipped items as Current-Carrying Conductors (#12 AWG = 2.25 cu.in.)
    local equippedCount = 0
    for slot = 1, 18 do
        if GetInventoryItemLink("player", slot) then
            equippedCount = equippedCount + 1
        end
    end
    -- Count weapon/trinket slots as Strap/Yoke Devices (2 allowances each per 314.16(B)(4))
    local devices = 2 -- 2 strap devices = 4 allowances
    local clamps = 1  -- All internal cable clamps = 1 allowance total (314.16(B)(2))
    local egcs = 6    -- Simulate 6 Equipment Grounding Conductors to show TN vs GA delta!

    local egcAllowTN = 1.0 -- TN (2017 NEC): All EGCs count as 1 volume allowance total!
    local egcAllowGA = 1.0 + (egcs - 4) * 0.25 -- GA (2023 NEC): >4 EGCs add 0.25 each = 1.50!

    local totalAllowTN = equippedCount + clamps + (devices * 2) + egcAllowTN
    local totalAllowGA = equippedCount + clamps + (devices * 2) + egcAllowGA
    local volPerWire = 2.25 -- #12 AWG Table 314.16(B)

    return {
        wires = equippedCount,
        devices = devices,
        egcs = egcs,
        cuInTN = totalAllowTN * volPerWire,
        cuInGA = totalAllowGA * volPerWire,
    }
end

-- ============================================================================
-- 5. IN-GAME FLOATING "NEC POWER WHEEL & LADDER-LOGIC HUD" FRAME
-- ============================================================================
local DrillIdx = 1
local DrillFlipped = false

local HUD = CreateFrame("Frame", "AltVaultNECCodeCoachHUD", UIParent, "BackdropTemplate")
HUD:SetSize(430, 265)
HUD:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -24, -140)
HUD:SetMovable(true)
HUD:EnableMouse(true)
HUD:RegisterForDrag("LeftButton")
HUD:SetScript("OnDragStart", HUD.StartMoving)
HUD:SetScript("OnDragStop", HUD.StopMovingOrSizing)
if HUD.SetBackdrop then
    HUD:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 14,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    HUD:SetBackdropColor(0.06, 0.09, 0.16, 0.92)
    HUD:SetBackdropBorderColor(0.98, 0.75, 0.14, 1)
end

local TitleTxt = HUD:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
TitleTxt:SetPoint("TOPLEFT", HUD, "TOPLEFT", 12, -10)
TitleTxt:SetText("|cffffd100⚡ AltVault NEC Master Formula & Ladder HUD|r")

local CloseBtn = CreateFrame("Button", nil, HUD, "UIPanelCloseButton")
CloseBtn:SetPoint("TOPRIGHT", HUD, "TOPRIGHT", -2, -2)

local TelemetryTxt = HUD:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
TelemetryTxt:SetPoint("TOPLEFT", HUD, "TOPLEFT", 12, -34)
TelemetryTxt:SetWidth(406)
TelemetryTxt:SetJustifyH("LEFT")

local DrillBox = CreateFrame("Button", nil, HUD, "BackdropTemplate")
DrillBox:SetSize(406, 94)
DrillBox:SetPoint("BOTTOMLEFT", HUD, "BOTTOMLEFT", 12, 38)
if DrillBox.SetBackdrop then
    DrillBox:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    DrillBox:SetBackdropColor(0.12, 0.18, 0.28, 0.95)
    DrillBox:SetBackdropBorderColor(0.22, 0.74, 0.97, 1)
end

local DrillTxt = DrillBox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
DrillTxt:SetPoint("TOPLEFT", DrillBox, "TOPLEFT", 10, -8)
DrillTxt:SetWidth(386)
DrillTxt:SetJustifyH("LEFT")

local function RenderHUDDrill()
    local d = WOW_LADDER_DRILLS[DrillIdx]
    if not DrillFlipped then
        DrillTxt:SetText(string.format(
            "|cff38bdf8🪜 LADDER DRILL #%d/%d (Click Box to Flip):|r\n|cffffd100Key Words:|r %s\n|cffcbd5e1👉 Which NEC Chapter, Tab & Section do you turn to?|r",
            DrillIdx, #WOW_LADDER_DRILLS, d.kw
        ))
    else
        DrillTxt:SetText(string.format(
            "|cff22c55e✅ EXACT CODE LOCATION:|r |cffffd100%s|r\n|cff38bdf8Rung 1:|r %s   |   |cff38bdf8Rung 2:|r %s\n|cffcbd5e1(Click 'Next Drill' below or type /nec in chat!)|r",
            d.sec, d.chap, d.tab
        ))
    end
end

DrillBox:SetScript("OnClick", function()
    DrillFlipped = not DrillFlipped
    RenderHUDDrill()
end)

local NextBtn = CreateFrame("Button", nil, HUD, "UIPanelButtonTemplate")
NextBtn:SetSize(130, 24)
NextBtn:SetPoint("BOTTOMLEFT", HUD, "BOTTOMLEFT", 12, 10)
NextBtn:SetText("Next Drill ▶")
NextBtn:SetScript("OnClick", function()
    DrillIdx = (DrillIdx % #WOW_LADDER_DRILLS) + 1
    DrillFlipped = false
    RenderHUDDrill()
end)

local RandBtn = CreateFrame("Button", nil, HUD, "UIPanelButtonTemplate")
RandBtn:SetSize(130, 24)
RandBtn:SetPoint("BOTTOM", HUD, "BOTTOM", 0, 10)
RandBtn:SetText("🎲 Random Drill")
RandBtn:SetScript("OnClick", function()
    DrillIdx = math.random(1, #WOW_LADDER_DRILLS)
    DrillFlipped = false
    RenderHUDDrill()
end)

local FlipBtn = CreateFrame("Button", nil, HUD, "UIPanelButtonTemplate")
FlipBtn:SetSize(130, 24)
FlipBtn:SetPoint("BOTTOMRIGHT", HUD, "BOTTOMRIGHT", -12, 10)
FlipBtn:SetText("🔄 Flip Answer")
FlipBtn:SetScript("OnClick", function()
    DrillFlipped = not DrillFlipped
    RenderHUDDrill()
end)

-- Update live WoW-to-NEC Electrical Formulas every 1.0 second
local accum = 0
HUD:SetScript("OnUpdate", function(self, elapsed)
    accum = accum + (elapsed or 0)
    if accum < 1.0 then return end
    accum = 0

    local lvl = UnitLevel("player") or 60
    local talentPts = math.max(0, math.min(51, lvl - 9)) -- WoW Forever Level 10..60 = 1..51 Talent Points!
    local E = (lvl >= 40) and 240 or 120 -- System Voltage (120V or 240V Single-Phase)
    local hpMax = UnitHealthMax("player") or 2400
    -- Scale Character Power/Health into realistic Continuous Load Amps (12A to 180A)
    local I_cont = math.max(12, math.min(180, math.floor((hpMax / 120) + 0.5)))
    local P_va = E * I_cont -- Ohm's Law Power Wheel: P = E x I

    local breaker, req125 = NECCodec.CalcContinuousOCPD(I_cont)
    local wire = NECCodec.SelectCopperConductor75C(req125)
    local vd, vdPct = NECCodec.CalcVoltageDrop(E, I_cont, 100, wire.cm) -- 100 ft run
    local bf = NECCodec.CalcLiveBoxFillFromInventory()

    local vdColor = (vdPct <= 3.0) and "|cff22c55e" or "|cfff87171"

    TelemetryTxt:SetText(string.format(
        "|cff38bdf8• Ohm's Power Wheel (P = E × I):|r %dV × %dA = |cffffd100%d VA|r\n" ..
        "|cff38bdf8• Continuous Load (210.20(A) 125%%):|r %dA × 1.25 = %.1fA ➔ |cff22c55e%dA Breaker (240.6(A))|r\n" ..
        "|cff38bdf8• Table 310.16 (75°C Cu Wire):|r |cffffd100%s|r (%dA rated, %d CM)\n" ..
        "|cff38bdf8• 100ft Voltage Drop (2×K×I×L/CM):|r %s%.2fV (%.1f%%)|r [NEC Max 3%%]\n" ..
        "|cff38bdf8• Gear Box Fill (314.16 #12 AWG):|r TN 2017 = |cffffd100%.2f in³|r | GA 2023 = |cffffd100%.2f in³|r",
        E, I_cont, P_va,
        I_cont, req125, breaker,
        wire.awg, wire.amps75, wire.cm,
        vdColor, vd, vdPct,
        bf.cuInTN, bf.cuInGA
    ))
end)

RenderHUDDrill()

-- Slash Command: /nec to toggle HUD or spawn a random drill in chat
SLASH_ALTVAULTNEC1 = "/nec"
SlashCmdList["ALTVAULTNEC"] = function(msg)
    if msg == "drill" then
        DrillIdx = math.random(1, #WOW_LADDER_DRILLS)
        DrillFlipped = false
        HUD:Show()
        RenderHUDDrill()
    else
        if HUD:IsShown() then
            HUD:Hide()
        else
            HUD:Show()
            RenderHUDDrill()
        end
    end
end

-- ============================================================================
-- 6. ELEMENTAL SHAMAN ".edu NEC ACADEMY" TAB INSIDE ALTVAULT MAIN PANEL!
--    Maps Elemental Shaman Spells & Leveling Milestones (Levels 1 to 80)
--    directly to Master Electrician NEC Formulas, Code Sections & CEU Credits!
-- ============================================================================
local SHAMAN_SPELL_NEC_MATRIX = {
    {
        spell = "⚡ Lightning Bolt (Single-Conductor Branch Circuit)",
        formula = "Ohm's Law & Power Wheel: E = I × R   |   P = E × I   |   I = P ÷ E",
        nec = "NEC Article 210 & Chapter 9 Table 8 (DC Conductor Resistance)",
        lesson = "Every Lightning Bolt is a direct path from source to load! Higher wire resistance (R) drops your voltage (VD = 2×K×I×L/CM). Thicker copper (more Circular Mils) delivers maximum voltage to the target!"
    },
    {
        spell = "⛓️ Chain Lightning (3-Phase Wye/Delta & Multiwire Branch Circuits)",
        formula = "3-Phase Power: P = E × I × 1.732 (√3)   |   Balanced Neutral Current = 0 Amps!",
        nec = "NEC 210.4 (Multiwire Branch Circuits — Simultaneous Disconnect of Ungrounded Conductors)",
        lesson = "Chain Lightning jumps across 3 targets just like a 3-Phase 120/208V or 277/480V Wye circuit! Remember NEC 210.4(B): Every Multiwire Branch Circuit (sharing a neutral) MUST have a handle tie or 2-pole/3-pole breaker for simultaneous disconnect!"
    },
    {
        spell = "🛡️ Lightning Shield & Grounding Totem (Equipment Grounding & Fault Path)",
        formula = "Effective Ground-Fault Current Path (Low Impedance = Instant Breaker Trip!)",
        nec = "NEC 250.4(A)(5) & Table 250.122 (Equipment Grounding Conductor Sizing) + Table 250.66 (GEC)",
        lesson = "Your Grounding Totem is your Grounding Electrode System (NEC 250.50 — Rod, Pipe, Plate, Concrete-Encased Ufer)! Remember: The Earth is NEVER permitted as the sole equipment ground path (250.4(A)(5))—you must run a copper EGC sized by the breaker in Table 250.122!"
    },
    {
        spell = "🔥 Flame Shock & Lava Burst (I²R Thermal Heating, Ampacity & Arc Flash)",
        formula = "Joule Heating: Watts Lost = I² × R   |   Arc Flash Boundary = 1.2 cal/cm²",
        nec = "NEC 110.14(C) (60°C vs 75°C Terminals), Table 310.16 Ampacity & NFPA 70E Art. 130",
        lesson = "Current squared times Resistance (I²R) creates heat! That is why NEC 110.14(C) caps <=100A terminals at the 60°C column and >100A terminals at the 75°C column, and why NFPA 70E requires Arc-Rated PPE (Cat 1=4, Cat 2=8, Cat 3=25, Cat 4=40 cal/cm²)!"
    },
    {
        spell = "💥 Elemental Overload & Thunderstorm (Overcurrent Protection & Tap Rules)",
        formula = "Continuous Load OCPD = 125% × Continuous Load (NEC 210.20(A) / 215.3)",
        nec = "NEC Article 240: 240.4(B) Next Size Up (<=800A), 240.4(D) Small Conductors, 240.6(A) Ratings",
        lesson = "When current surges into Overload or Short-Circuit, Article 240 protects the wire! Memorize the Small Conductor caps (240.4(D)): #14 AWG = 15A max, #12 AWG = 20A max, #10 AWG = 30A max (unless it's a Motor under Art. 430 or A/C under Art. 440)!"
    },
    {
        spell = "🌀 Totemic Recall & Astral Recall (Lockout/Tagout & Disconnecting Means)",
        formula = "NFPA 70E Art. 120: Live-Dead-Live Voltmeter Verification (>= 50 Volts)",
        nec = "NEC 110.26 (Working Space: 30\" Wide, 3/3.5/4 ft Deep, 6.5 ft High) & 430.102 In-Sight Disconnect",
        lesson = "In the NEC, 'In Sight From' (Article 100) means visible AND not more than 50 FEET distant! Before working on any equipment >=50V, open the disconnect, apply Lockout/Tagout, and test Live-Dead-Live!"
    }
}

-- ============================================================================
-- 7. WOW FOREVER (LEVEL 60 CAP / 51 TALENT POINTS) ELEMENTAL TALENT TREE MATH!
--    Evaluates each Talent Tier starting at Level 10 (Tiers 1 to 7) and maps
--    the exact talent rank percentage math to NEC Master Exam Calculations!
-- ============================================================================
local SHAMAN_TALENT_TIER_MATH = {
    {
        tier = 1, reqLvl = "Levels 10–14 (Pts 1–5)",
        talents = "Convection (5/5 = -10% Mana Cost) & Concussion (5/5 = +5% Shock/Bolt Damage)",
        talentMath = "Efficiency Factor η = P_out ÷ P_in = 1.05 ÷ 0.90 = 116.7% Net Circuit Efficiency!",
        necFormula = "NEC Table 310.15(C)(1) [TN 2017: 310.15(B)(3)(a)] Conduit Fill Derating (80%, 70%, 50%)",
        explanation = "Just like 5/5 Convection reduces mana loss by 2% per rank (2% × 5 = 10%) and 5/5 Concussion boosts output by 1% per rank (1% × 5 = 5%), NEC conduit bundling multiplies wire ampacity by 80% (4–6 wires), 70% (7–9 wires), or 50% (10–20 wires)!"
    },
    {
        tier = 2, reqLvl = "Levels 15–19 (Pts 6–10)",
        talents = "Call of Flame (3/3 = +15% Fire Totem) & Elemental Warding (3/3 = -10% Nature/Fire/Frost Damage Taken)",
        talentMath = "Damage Reduction Multiplier = 1.00 - 0.10 = 0.90 (90% Thermal Load Factor)",
        necFormula = "NEC Table 310.15(B)(1) Ambient Temperature Correction Factors (> 86°F / 30°C)",
        explanation = "Elemental Warding protects you from heat/fire just like Ambient Temperature Derating protects THHN insulation in hot attics and rooftops! Start in the 90°C column of Table 310.16, multiply by the temperature correction factor, and cap at the 75°C terminal rating (110.14(C))!"
    },
    {
        tier = 3, reqLvl = "Levels 20–24 (Pts 11–15)",
        talents = "Elemental Focus (Clearcasting = 10% Proc for 100% Free Cast) & Reverberation (5/5 = -1.0s Shock CD)",
        talentMath = "Cycle Duty Time Reduction: T_new = 6.0s - (5 × 0.2s) = 5.0s (20% Higher Duty Frequency!)",
        necFormula = "NEC Article 100 Duty Definitions (Continuous >= 3 Hrs vs Intermittent/Short-Time/Varying Duty)",
        explanation = "Reverberation shortens your Shock cycle time by 0.2s per talent point (5 × 0.2s = 1.0s), increasing your Duty Cycle! In NEC Table 430.22(E), Intermittent/Short-Time Duty motors use different percentage multipliers than Continuous Duty (125%) motors!"
    },
    {
        tier = 4, reqLvl = "Levels 25–29 (Pts 16–20)",
        talents = "Improved Fire Totems (2/2) & Eye of the Storm (3/3 = 100% Pushback Immunity on Crit)",
        talentMath = "Fault Ride-Through Stability = 100% Continuity Under Short-Circuit Stress",
        necFormula = "NEC 110.9 Interrupting Rating (AIC) & 110.10 Short-Circuit Current Rating (SCCR)",
        explanation = "Eye of the Storm prevents spell interruption when you take a critical hit—exact same principle as NEC 110.9 (Interrupting Rating) and 110.10 (Equipment SCCR), which ensure breakers and panels don't explode under high Available Fault Current!"
    },
    {
        tier = 5, reqLvl = "Levels 30–34 (Pts 21–25)",
        talents = "Elemental Fury (1/1 = Increases Critical Strike Damage Bonus from +50% to +100% -> 2.0× Peak!)",
        talentMath = "Peak Fault/Surge Multiplier: P_crit = P_base × (1.00 + (2 × 0.50)) = 2.00 × P_base (200% Peak!)",
        necFormula = "NEC Table 430.52 Motor Inrush & Inverse-Time Breaker Sizing = 250% of Table FLC (Dual-Element Fuse = 175%)",
        explanation = "Elemental Fury doubles your critical strike surge to 200% (2.0×) of base damage! That mirrors Motor Inrush Current in NEC Table 430.52, where an Inverse-Time Circuit Breaker is sized up to 250% (2.5×) of Full-Load Current so the startup surge doesn't trip the breaker!"
    },
    {
        tier = 6, reqLvl = "Levels 35–39 (Pts 26–30)",
        talents = "Lightning Mastery (5/5 = -0.2s Cast Time per Rank ➔ -1.0s Total on Lightning Bolt & Chain Lightning!)",
        talentMath = "Throughput Surge: 3.0s Cast ➔ 2.0s Cast = (3.0 ÷ 2.0) = 1.50× (150% Watts/Second Throughput!)",
        necFormula = "NEC 210.20(A) & 215.3 Continuous Load 125% Rule + NEC Table 220.55 Demand Factor Math",
        explanation = "Each point in Lightning Mastery shaves 0.2s off your cast (5 × 0.2s = 1.0s faster), boosting your electrical throughput by 150%! Whenever a circuit runs continuously for 3+ hours, NEC 210.20(A) & 215.3 require sizing the breaker and wire at 125% (1.25×) of the continuous load!"
    },
    {
        tier = 7, reqLvl = "Level 40–60 Capstone (Pts 31–51)",
        talents = "Elemental Mastery (31st Point Capstone = Instant Cast + 100% Guaranteed Crit & 0 Mana Cost!)",
        talentMath = "Unity Power Factor (PF = 1.00): Apparent Power (kVA) = True Power (kW) with Zero Reactive Loss!",
        necFormula = "3-Phase True Power: P_Watts = E × I × 1.732 × Power Factor (PF) + Transformer Table 450.3(B) (125% Primary / 250% Secondary)",
        explanation = "At Level 40 (your 31st Talent Point in WoW Forever!), Elemental Mastery gives you 100% Power Factor (PF = 1.0) with zero wasted mana! From Levels 40 to 60, your remaining 20 talent points (Pts 32–51) hybridize into Restoration/Enhancement—just like combining NEC, NFPA 70E, OSHA 1926 & NASCLA for your Master Exam!"
    }
}

local SHAMAN_LEVEL_MILESTONES = {
    { minLvl = 1,  maxLvl = 9,  pts = "0 Talent Pts (Pre-Tree)", course = "ELTR-1010", ceu = "0.6 CEU (6 Hrs)", title = "Levels 1–9 Totem Initiate: NEC Structure, Definitions & 110.26 Clearances", sec = "Articles 90, 100 & 110 (110.14(C) & 110.26)" },
    { minLvl = 10, maxLvl = 19, pts = "Talent Pts 1–10 (Tiers 1–2)", course = "ELTR-1020", ceu = "1.2 CEU (12 Hrs)", title = "Levels 10–19 Shock Caller: Branch Circuits, GFCI/AFCI & Dwelling Loads", sec = "Articles 200, 210 (210.8, 210.12, 210.52) & 220 + Talent Tier 1–2 Derating Math" },
    { minLvl = 20, maxLvl = 29, pts = "Talent Pts 11–20 (Tiers 3–4)", course = "ELTR-1030", ceu = "1.6 CEU (16 Hrs)", title = "Levels 20–29 Grounding Totem Master: Services, OCPD & Grounding/Bonding", sec = "Articles 230, 240 (240.4, 240.6) & 250 (Tables 250.66 & 250.122) + Tier 3–4 Duty/AIC Math" },
    { minLvl = 30, maxLvl = 39, pts = "Talent Pts 21–30 (Tiers 5–6)", course = "ELTR-2010", ceu = "1.4 CEU (14 Hrs)", title = "Levels 30–39 Chain Lightning Weaver: Ampacity Table 310.16 & Box Fill 314.16", sec = "Articles 300, 310, 314 (314.16 & 314.28), Ch. 9 + Elemental Fury 200% & Lightning Mastery Math" },
    { minLvl = 40, maxLvl = 49, pts = "Talent Pts 31–40 (Tier 7 Capstone!)", course = "ELTR-2020", ceu = "1.4 CEU (14 Hrs)", title = "Levels 40–49 Elemental Mastery Lord: Motors (430), A/C (440) & Transformers (450)", sec = "Articles 430 (430.22, 430.52, 430.250), 440, 450 & 500–517 + Power Factor (PF) Math" },
    { minLvl = 50, maxLvl = 55, pts = "Talent Pts 41–46 (Hybrid Mastery)", course = "SAFE-3010", ceu = "1.2 CEU (12 Hrs)", title = "Levels 50–55 Arc-Flash Shield Warden: NFPA 70E LOTO & OSHA 29 CFR 1926 Subpart K", sec = "NFPA 70E Arts. 120–130 & OSHA 1926.404 / 1926.501 / 1926.652" },
    { minLvl = 56, maxLvl = 59, pts = "Talent Pts 47–50 (Pre-BiS Prep)", course = "BUSI-4010", ceu = "1.0 CEU (10 Hrs)", title = "Levels 56–59 Master Contractor Guildmaster: NASCLA Estimating, Margin Math & Taxes", sec = "NASCLA Contractors Guide (Bid ÷ (1 - OH+P%)) & IRS Circular E" },
    { minLvl = 60, maxLvl = 60, pts = "Level 60 Cap! (All 51 Talent Pts!)", course = "EDUC-5010", ceu = "3.0 CEU (30 Hrs)", title = "Level 60 WoW Forever Grandmaster Inspector & Accredited .edu Code Professor", sec = "1,000 Ladder-Logic Section Drills + Full TN (2017) & GA (2023) Mastery" },
}

local function RenderShamanEduAcademyTab(panel)
    if ns.NetUI and ns.NetUI.HistoryFrame then ns.NetUI.HistoryFrame:Hide() end
    if ns.NetUI and ns.NetUI.TopBar then ns.NetUI.TopBar:Hide() end
    panel._state.customScrollTopOffset = nil

    local rows = {}
    local playerName = UnitName("player") or "Shaman"
    local playerLvl = math.min(60, UnitLevel("player") or 1)
    local talentPts = math.max(0, math.min(51, playerLvl - 9))
    local _, playerClass = UnitClass("player")

    local E = (playerLvl >= 40) and 240 or 120
    local hpMax = UnitHealthMax("player") or 2400
    local I_cont = math.max(12, math.min(180, math.floor((hpMax / 120) + 0.5)))
    local breaker, req125 = NECCodec.CalcContinuousOCPD(I_cont)
    local wire = NECCodec.SelectCopperConductor75C(req125)
    local vd, vdPct = NECCodec.CalcVoltageDrop(E, I_cont, 100, wire.cm)
    local bf = NECCodec.CalcLiveBoxFillFromInventory()

    table.insert(rows, {
        tint = "SPEC_HEADER",
        text = string.format("|cffffd100🎓 .EDU ELEMENTAL SHAMAN NEC ACADEMY (WoW Forever Cap 60) — %s (Lvl %d • %d/51 Talent Pts)|r",
            playerName, playerLvl, talentPts)
    })
    table.insert(rows, {
        tint = "PROF",
        text = string.format(
            "  |cff38bdf8Live Elemental Circuit Telemetry:|r  |cffffd100%dV × %dA = %d VA|r   •   |cff22c55e125%% OCPD = %dA Breaker (NEC 240.6(A))|r   •   |cffffd100Wire = %s (%dA)|r   •   |cff38bdf8100ft VD = %.2fV (%.1f%%)|r   •   |cffffd100Box Fill: TN=%.2f in³ / GA=%.2f in³|r",
            E, I_cont, E * I_cont, breaker, wire.awg, wire.amps75, vd, vdPct, bf.cuInTN, bf.cuInGA
        ),
        onClickAction = function()
            if HUD:IsShown() then HUD:Hide() else HUD:Show() end
        end
    })

    local d = WOW_LADDER_DRILLS[DrillIdx]
    table.insert(rows, {
        tint = "UPGRADE_SOON",
        text = string.format(
            "  |cff00ff00[🃏 CLICK HERE TO FLIP / NEXT IN-GAME LADDER-LOGIC DRILL #%d/%d]|r\n  |cffffd100Trigger Key Words:|r %s\n  %s",
            DrillIdx, #WOW_LADDER_DRILLS, d.kw,
            DrillFlipped
                and string.format("|cff22c55e✅ ANSWER: Turn to %s|r  |cff38bdf8(%s • %s)|r", d.sec, d.chap, d.tab)
                or "|cffcccccc👉 Click this row once to reveal the exact NEC Section, and click again for the next drill!|r"
        ),
        onClickAction = function()
            if not DrillFlipped then
                DrillFlipped = true
            else
                DrillIdx = (DrillIdx % #WOW_LADDER_DRILLS) + 1
                DrillFlipped = false
            end
            RenderHUDDrill()
            RenderShamanEduAcademyTab(panel)
        end
    })

    table.insert(rows, { text = "|cff555555----------------------------------------------------------------------|r" })
    table.insert(rows, {
        tint = "SPEC_HEADER",
        text = "|cffffd100⚡ PART 1: ELEMENTAL SHAMAN SPELLBOOK ➔ NEC MASTER FORMULA CODEX|r"
    })

    for _, sp in ipairs(SHAMAN_SPELL_NEC_MATRIX) do
        table.insert(rows, {
            tint = "PROF",
            text = string.format(
                "|cffffd100%s|r\n  |cff38bdf8• Formula:|r |cff22c55e%s|r\n  |cff38bdf8• Code Book Location:|r |cffffd100%s|r\n  |cffcccccc• Field & Exam Rule:|r %s",
                sp.spell, sp.formula, sp.nec, sp.lesson
            )
        })
    end

    table.insert(rows, { text = "|cff555555----------------------------------------------------------------------|r" })
    table.insert(rows, {
        tint = "SPEC_HEADER",
        text = "|cffffd100🌳 PART 2: LEVEL 10–60 TALENT TREE MATH (51 POINTS) ➔ NEC DERATING, DUTY CYCLE & INRUSH FORMULAS|r"
    })

    for _, tm in ipairs(SHAMAN_TALENT_TIER_MATH) do
        local reqMinLvl = 10 + ((tm.tier - 1) * 5)
        local tierUnlocked = (playerLvl >= reqMinLvl)
        table.insert(rows, {
            tint = tierUnlocked and "UPGRADE" or "LOCKED_RED",
            text = string.format(
                "|cffffd100Tier %d (%s) — %s|r  %s\n  |cff22c55e• Talent Percentage Math:|r %s\n  |cff38bdf8• Matching NEC Formula:|r |cffffd100%s|r\n  |cffcccccc• How the Math Connects:|r %s",
                tm.tier, tm.reqLvl, tm.talents,
                tierUnlocked and "|cff22c55e[✅ TALENT TIER UNLOCKED]|r" or ("|cffff5555[🔒 UNLOCKS AT LEVEL " .. reqMinLvl .. "]|r"),
                tm.talentMath, tm.necFormula, tm.explanation
            )
        })
    end

    table.insert(rows, { text = "|cff555555----------------------------------------------------------------------|r" })
    table.insert(rows, {
        tint = "SPEC_HEADER",
        text = "|cffffd100🏆 PART 3: WOW FOREVER LEVEL 1–60 MILESTONES (51 TALENT PTS) ➔ ACCREDITED .EDU COURSE & CEU TRACKER|r"
    })

    for _, ms in ipairs(SHAMAN_LEVEL_MILESTONES) do
        local unlocked = (playerLvl >= ms.minLvl)
        local isCurrent = (playerLvl >= ms.minLvl and playerLvl <= ms.maxLvl)
        local badge = isCurrent and "|cff00ff00[★ ACTIVE LEVEL BRACKET — EARNING CREDITS NOW!]|r"
            or (unlocked and "|cff22c55e[✅ UNLOCKED & CREDITED]|r" or "|cffff5555[🔒 REACH LEVEL " .. ms.minLvl .. " TO UNLOCK]|r")
        table.insert(rows, {
            tint = isCurrent and "UPGRADE_SOON" or (unlocked and "UPGRADE" or "LOCKED_RED"),
            text = string.format(
                "|cffffd100Levels %d–%d (%s) • %s (%s):|r %s  %s\n  |cff38bdf8• Required NEC & 4-Book Competency:|r %s",
                ms.minLvl, ms.maxLvl, ms.pts, ms.course, ms.ceu, ms.title, badge, ms.sec
            )
        })
    end

    panel:RenderRowList(rows)
end

local MainPanel = _G.AltVaultMainPanel
if MainPanel and MainPanel.RegisterExternalTab then
    MainPanel:RegisterExternalTab(
        "EDU_SHAMAN_NEC",
        "⚡ .edu Shaman NEC",
        "Elemental Shaman .edu Electrical Engineering & NEC Master Licensing Academy — Learn Ohm's Law, Table 310.16, 3-Phase Chain Lightning & Ladder-Logic Drills as you level!",
        RenderShamanEduAcademyTab
    )
    if MainPanel.ApplyGlobalButtonScaling then
        MainPanel:ApplyGlobalButtonScaling(false)
    end
end

