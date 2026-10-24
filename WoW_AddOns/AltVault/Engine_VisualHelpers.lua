-- ============================================================================
-- FILE: Engine_VisualHelpers.lua (MODULE 3 OF 3 SPLIT FROM Engine_Scanner.lua)
-- BLOCK HEADING: VENDOR SELL VALUE & FULL ITEM DOSSIER BUILDER (FOR TAB 6)
-- ============================================================================
local addonName, ns = ...
local Scanner = ns.Scanner or {}
ns.Scanner = Scanner

local ItemScanTip = Scanner.ItemScanTip
local ExtractItemID = Scanner.ExtractItemID
local FetchDetailedILvl = Scanner.FetchDetailedILvl
local DetectGearStatRole = Scanner.DetectGearStatRole
local NON_CONSUMING_GATHER_PROFS = Scanner.NON_CONSUMING_GATHER_PROFS
local EQUIP_LOC_LABELS = Scanner.EQUIP_LOC_LABELS
local QUALITY_NAMES = Scanner.QUALITY_NAMES
local QUALITY_HEX = Scanner.QUALITY_HEX
local BIND_TYPE_LABELS = Scanner.BIND_TYPE_LABELS

function Scanner.FormatMoneyString(copper)
    copper = tonumber(copper) or 0
    if copper <= 0 then
        return "|cff888888No Vendor Value (Cannot Sell)|r"
    end
    local gold = math.floor(copper / 10000)
    local silver = math.floor((copper % 10000) / 100)
    local cop = copper % 100
    local parts = {}
    if gold > 0 then table.insert(parts, string.format("|cffffd700%dg|r", gold)) end
    if silver > 0 or gold > 0 then table.insert(parts, string.format("|cffc7c7cf%ds|r", silver)) end
    table.insert(parts, string.format("|cffeda55f%dc|r", cop))
    return table.concat(parts, " ")
end

local function ExtractTooltipStatLines(itemID, itemLink)
    local lines = {}
    ItemScanTip:ClearLines()
    ItemScanTip:SetOwner(WorldFrame, "ANCHOR_NONE")
    local query = (itemLink and string.find(itemLink, "item:")) and itemLink or ("item:" .. tostring(itemID))
    pcall(ItemScanTip.SetHyperlink, ItemScanTip, query)

    local numLines = ItemScanTip:NumLines() or 0
    for i = 2, numLines do
        local leftFont = _G["AltVaultItemPatternScanTooltipTextLeft" .. i]
        local rightFont = _G["AltVaultItemPatternScanTooltipTextRight" .. i]
        local lText = leftFont and leftFont:GetText()
        local rText = rightFont and rightFont:IsShown() and rightFont:GetText()

        if lText and lText ~= "" and not string.find(lText, "^Sell Price") then
            if rText and rText ~= "" then
                table.insert(lines, lText .. "   |cffcccccc(" .. rText .. ")|r")
            else
                table.insert(lines, lText)
            end
        end
    end
    return lines
end

local function DetermineFactionSources(itemID, cached, patRecord, reagRecord, multiProfs)
    local allianceSrc = nil
    local hordeSrc = nil

    if ns.AcquisitionDB and ns.AcquisitionDB.GetItemDualFactionSummary then
        local aLine, hLine = ns.AcquisitionDB:GetItemDualFactionSummary(itemID, cached and cached.n)
        if aLine and aLine ~= "" then allianceSrc = "Alliance: " .. aLine end
        if hLine and hLine ~= "" then hordeSrc = "Horde: " .. hLine end
    end

    if AltVaultDB and AltVaultDB.SourceDB and AltVaultDB.SourceDB[itemID] then
        local src = AltVaultDB.SourceDB[itemID]
        if src.alliance then allianceSrc = src.alliance end
        if src.horde then hordeSrc = src.horde end
        if src.both then
            allianceSrc = allianceSrc or src.both
            hordeSrc = hordeSrc or src.both
        end
    end

    if patRecord then
        local patText = string.format("%s Recipe (Requires %d %s) - Sold by %s Trainers / Vendors or World Drop",
            patRecord.p or "Profession", patRecord.s or 1, patRecord.p or "Skill", patRecord.p or "Profession")
        allianceSrc = allianceSrc or ("Alliance: " .. patText)
        hordeSrc    = hordeSrc or ("Horde: " .. patText)
    end

    if multiProfs and #multiProfs > 0 then
        local rText = "Crafting Material used by: " .. table.concat(multiProfs, ", ")
        allianceSrc = allianceSrc or ("Alliance: " .. rText)
        hordeSrc    = hordeSrc or ("Horde: " .. rText)
    elseif reagRecord and type(reagRecord.profs) == "table" then
        local pNames = {}
        for pName, info in pairs(reagRecord.profs) do
            if not NON_CONSUMING_GATHER_PROFS[pName] then
                table.insert(pNames, string.format("%s (%d-%d)", pName, info.min or 1, info.max or 300))
            end
        end
        if #pNames > 0 then
            local rText = "Used in " .. table.concat(pNames, ", ")
            allianceSrc = allianceSrc or ("Alliance: " .. rText)
            hordeSrc    = hordeSrc or ("Horde: " .. rText)
        end
    end

    if not allianceSrc or not hordeSrc then
        local q = cached.q or 1
        local b = cached.b or 0
        local c = cached.c
        local st = cached.st or ""
        local reqLvl = cached.r or 1
        local iLvl = cached.l or 1
        local zoneTier = (reqLvl >= 55 or iLvl >= 60) and "Lvl 55+ Endgame Dungeons / Raids / High-Level Zones"
            or (reqLvl >= 40 or iLvl >= 42) and "Lvl 40-54 Mid-High Dungeons & Contested Zones"
            or (reqLvl >= 20 or iLvl >= 22) and "Lvl 20-39 Dungeons & Leveling Zones"
            or "Lvl 1-19 Starter & Early Zones"

        if c == 7 or cached.cr then
            local gatherNote = "Trade Goods / Crafting Material (" .. (st ~= "" and st or "Reagent") .. ") - Gathered, Skinned, Mined, or Auction House"
            allianceSrc = allianceSrc or ("Alliance: " .. gatherNote .. " (" .. zoneTier .. ")")
            hordeSrc    = hordeSrc or ("Horde: " .. gatherNote .. " (" .. zoneTier .. ")")
        elseif b == 4 then
            allianceSrc = allianceSrc or ("Alliance: Quest Item / Objective Reward (" .. zoneTier .. ")")
            hordeSrc    = hordeSrc or ("Horde: Quest Item / Objective Reward (" .. zoneTier .. ")")
        elseif b == 1 and q >= 3 then
            allianceSrc = allianceSrc or ("Alliance: Dungeon / Raid Boss Drop or Faction Quartermaster [BoP] (" .. zoneTier .. ")")
            hordeSrc    = hordeSrc or ("Horde: Dungeon / Raid Boss Drop or Faction Quartermaster [BoP] (" .. zoneTier .. ")")
        elseif b == 1 and q == 2 then
            allianceSrc = allianceSrc or ("Alliance: Quest Reward or Dungeon Drop [BoP] (" .. zoneTier .. ")")
            hordeSrc    = hordeSrc or ("Horde: Quest Reward or Dungeon Drop [BoP] (" .. zoneTier .. ")")
        elseif b == 2 then
            allianceSrc = allianceSrc or ("Alliance: World Drop, Crafted Gear, or Auction House [BoE] (" .. zoneTier .. ")")
            hordeSrc    = hordeSrc or ("Horde: World Drop, Crafted Gear, or Auction House [BoE] (" .. zoneTier .. ")")
        else
            allianceSrc = allianceSrc or ("Alliance: Vendor, General Drop, or Tradeable Item (" .. zoneTier .. ")")
            hordeSrc    = hordeSrc or ("Horde: Vendor, General Drop, or Tradeable Item (" .. zoneTier .. ")")
        end
    end

    return allianceSrc, hordeSrc
end

function Scanner.GetItemFullDossier(itemLinkOrID)
    local itemID = ExtractItemID(itemLinkOrID)
    if not itemID then return nil end

    if C_Item and C_Item.RequestLoadItemDataByID then
        pcall(C_Item.RequestLoadItemDataByID, itemID)
    end

    local itemName, itemLink, itemQuality, baseILvl, itemMinLevel, itemType, itemSubType,
          itemStackCount, itemEquipLoc, itemTexture, sellPrice, classID, subClassID,
          bindType, _, _, isCraftingReagent = Scanner.CacheItemData(itemLinkOrID, false)

    local cached = (AltVaultDB and AltVaultDB.ItemCache and AltVaultDB.ItemCache[itemID]) or {}
    itemName = itemName or cached.n
    if not itemName then
        return {
            itemID = itemID,
            loaded = false,
            name = "Querying Server for Item #" .. tostring(itemID) .. "..."
        }
    end

    itemQuality       = itemQuality or cached.q or 1
    baseILvl          = FetchDetailedILvl(itemLink or itemID) or baseILvl or cached.l or 1
    itemMinLevel      = itemMinLevel or cached.r or 1
    itemType          = itemType or cached.t or "Item"
    itemSubType       = itemSubType or cached.st or ""
    itemStackCount    = itemStackCount or cached.s or 1
    itemEquipLoc      = itemEquipLoc or cached.eq or ""
    itemTexture       = itemTexture or cached.ic or "Interface\\Icons\\INV_Misc_QuestionMark"
    sellPrice         = sellPrice or cached.v or 0
    classID           = classID or cached.c
    subClassID        = subClassID or cached.sc
    bindType          = bindType or cached.b or 0
    isCraftingReagent = isCraftingReagent or cached.cr or false

    if not itemLink or not string.find(itemLink, "|Hitem:") then
        itemLink = string.format("|cff%s|Hitem:%d:0:0:0:0:0:0:0:60|h[%s]|h|r",
            QUALITY_HEX[itemQuality] or "ffffff", itemID, itemName)
    end

    local gs = Scanner.CalculateItemGearScore(itemLink)
    local patRecord = AltVaultDB and AltVaultDB.PatternDB and AltVaultDB.PatternDB[itemID]
    local reagRecord = AltVaultDB and AltVaultDB.ReagentDB and (AltVaultDB.ReagentDB[itemID] or AltVaultDB.ReagentDB[itemName])
    local multiProfs = Scanner.GetMaterialProfessionsList(itemLink)
    local allianceSource, hordeSource = DetermineFactionSources(itemID, cached, patRecord, reagRecord, multiProfs)
    local statLines = ExtractTooltipStatLines(itemID, itemLink)

    return {
        loaded            = true,
        itemID            = itemID,
        name              = itemName,
        link              = itemLink,
        icon              = itemTexture,
        quality           = itemQuality,
        qualityText       = QUALITY_NAMES[itemQuality] or tostring(itemQuality),
        iLvl              = baseILvl,
        reqLvl            = itemMinLevel,
        gearScore         = gs or 0,
        itemType          = itemType,
        itemSubType       = itemSubType,
        classID           = classID,
        subClassID        = subClassID,
        equipLoc          = itemEquipLoc,
        equipSlotLabel    = EQUIP_LOC_LABELS[itemEquipLoc] or "Non-Equippable",
        stackSize         = itemStackCount,
        vendorCopper      = sellPrice,
        vendorUnitString  = Scanner.FormatMoneyString(sellPrice),
        vendorStackString = (itemStackCount > 1 and sellPrice > 0) and Scanner.FormatMoneyString(sellPrice * itemStackCount) or nil,
        bindType          = bindType,
        bindText          = BIND_TYPE_LABELS[bindType] or "Not Bound",
        isReagent         = isCraftingReagent or (classID == 7) or false,
        usedByProfs       = multiProfs,
        roleTag           = cached.ro or DetectGearStatRole(itemLink),
        patternInfo       = patRecord,
        allianceSource    = allianceSource,
        hordeSource       = hordeSource,
        tooltipLines      = statLines,
    }
end

-- ============================================================================
-- BLOCK HEADING: SHARED UI PULSE ANIMATION & SLOT BORDER GLOW ENGINE
-- ============================================================================
function Scanner.ApplyPulseAnimation(frame, enablePulse)
    if not frame or not frame.CreateAnimationGroup then return end
    if not frame.avPulseGroup then
        local ag = frame:CreateAnimationGroup()
        ag:SetLooping("BOUNCE")
        local alpha = ag:CreateAnimation("Alpha")
        if alpha.SetFromAlpha and alpha.SetToAlpha then
            alpha:SetFromAlpha(0.25)
            alpha:SetToAlpha(1.0)
        elseif alpha.SetChange then
            alpha:SetChange(-0.75)
        end
        alpha:SetDuration(0.65)
        if alpha.SetSmoothing then
            alpha:SetSmoothing("IN_OUT")
        end
        frame.avPulseGroup = ag
    end
    if enablePulse then
        if not frame.avPulseGroup:IsPlaying() then
            frame.avPulseGroup:Play()
        end
    else
        if frame.avPulseGroup:IsPlaying() then
            frame.avPulseGroup:Stop()
        end
        frame:SetAlpha(1.0)
    end
end

function Scanner.ApplySlotBorderGlow(buttonFrame, triggerStatus)
    if type(buttonFrame) ~= "table" or not buttonFrame.CreateTexture then return end

    if not buttonFrame.avGlowFrame then
        local glow
        if ns.Compat and ns.Compat.CreateBackdropFrame then
            glow = ns.Compat.CreateBackdropFrame("Frame", nil, buttonFrame)
        else
            glow = CreateFrame("Frame", nil, buttonFrame, _G.BackdropTemplateMixin and "BackdropTemplate" or nil)
        end
        glow:SetPoint("TOPLEFT", buttonFrame, "TOPLEFT", -1, 1)
        glow:SetPoint("BOTTOMRIGHT", buttonFrame, "BOTTOMRIGHT", 1, -1)
        glow:SetFrameLevel((buttonFrame:GetFrameLevel() or 1) + 8)
        if glow.SetBackdrop then
            glow:SetBackdrop({
                edgeFile = "Interface\\Buttons\\WHITE8X8",
                edgeSize = 2,
            })
        end
        glow.InnerTint = glow:CreateTexture(nil, "BACKGROUND")
        glow.InnerTint:SetAllPoints(buttonFrame)
        buttonFrame.avGlowFrame = glow
    end

    local glow = buttonFrame.avGlowFrame
    local SetSolid = (ns.Compat and ns.Compat.SetSolidColor) or function(t, r, g, b, a)
        if t.SetColorTexture then t:SetColorTexture(r, g, b, a) elseif t.SetTexture then t:SetTexture(r, g, b, a) end
    end

    if triggerStatus == "LOCKED_RED" then
        if glow.SetBackdropBorderColor then glow:SetBackdropBorderColor(1.0, 0.12, 0.12, 1.0) end
        SetSolid(glow.InnerTint, 0.90, 0.05, 0.05, 0.40)
        glow:Show()
        Scanner.ApplyPulseAnimation(glow, false)
    elseif triggerStatus == "UPGRADE_SOON" then
        if glow.SetBackdropBorderColor then glow:SetBackdropBorderColor(0.1, 1.0, 0.2, 1.0) end
        SetSolid(glow.InnerTint, 0.1, 1.0, 0.2, 0.16)
        glow:Show()
        Scanner.ApplyPulseAnimation(glow, true)
    elseif triggerStatus == "PROF_SOON" then
        if glow.SetBackdropBorderColor then glow:SetBackdropBorderColor(0.0, 0.9, 1.0, 1.0) end
        SetSolid(glow.InnerTint, 0.0, 0.9, 1.0, 0.16)
        glow:Show()
        Scanner.ApplyPulseAnimation(glow, true)
    elseif triggerStatus == "UPGRADE" then
        if glow.SetBackdropBorderColor then glow:SetBackdropBorderColor(0.0, 0.85, 0.1, 1.0) end
        SetSolid(glow.InnerTint, 0.0, 0.85, 0.1, 0.12)
        glow:Show()
        Scanner.ApplyPulseAnimation(glow, false)
    elseif triggerStatus == "PROF_MAT" then
        if glow.SetBackdropBorderColor then glow:SetBackdropBorderColor(0.0, 0.65, 1.0, 1.0) end
        SetSolid(glow.InnerTint, 0.0, 0.65, 1.0, 0.12)
        glow:Show()
        Scanner.ApplyPulseAnimation(glow, false)
    else
        Scanner.ApplyPulseAnimation(glow, false)
        glow:Hide()
    end
end

-- ============================================================================
-- BLOCK HEADING: TOOLTIP LEVEL-RED OVERRIDE FIXER
-- ============================================================================
function Scanner.CleanTooltipRedLinesForAlt(tooltip, altData, isEquippedItem)
    if not tooltip or not altData then return end
    local altLevel = altData.level or 60
    local numLines = tooltip:NumLines()

    for i = 2, numLines do
        local leftFont = _G[tooltip:GetName() .. "TextLeft" .. i]
        local rightFont = _G[tooltip:GetName() .. "TextRight" .. i]

        if leftFont then
            local text = leftFont:GetText() or ""
            local r, g, b = leftFont:GetTextColor()
            local isRed = (r and r > 0.85 and g < 0.25 and b < 0.25)

            if isRed then
                local reqLvl = tonumber(string.match(text, "(%d+)"))
                if isEquippedItem then
                    leftFont:SetTextColor(1, 1, 1)
                elseif reqLvl and altLevel >= reqLvl then
                    leftFont:SetTextColor(1, 1, 1)
                end
            end
        end

        if rightFont and isEquippedItem then
            local r, g, b = rightFont:GetTextColor()
            if r and r > 0.85 and g < 0.25 and b < 0.25 then
                rightFont:SetTextColor(1, 1, 1)
            end
        end
    end
end