-- ============================================================================
-- BLOCK HEADING: GLOBAL COMPONENT REGISTRATION (GUILD BANK GLOW OVERLAY)
-- ============================================================================
local addonName, ns = ...
local GuildOverlay = CreateFrame("Frame")
GuildOverlay:RegisterEvent("GUILDBANKFRAME_OPENED")
GuildOverlay:RegisterEvent("GUILDBANKBAGSLOTS_CHANGED")

-- ============================================================================
-- BLOCK HEADING: GUILD VAULT SLOT RESOLVER & BORDER GLOW DISPATCHER
-- ============================================================================
local function GetGuildSlotButton(slotIndex)
    if _G["GuildBankGridFrameButton" .. slotIndex] then
        return _G["GuildBankGridFrameButton" .. slotIndex]
    end
    local col = math.ceil(slotIndex / 14)
    local btn = ((slotIndex - 1) % 14) + 1
    if _G["GuildBankColumn" .. col .. "Button" .. btn] then
        return _G["GuildBankColumn" .. col .. "Button" .. btn]
    end
    if GuildBankFrame and GuildBankFrame.Columns and GuildBankFrame.Columns[col] and GuildBankFrame.Columns[col].Buttons then
        return GuildBankFrame.Columns[col].Buttons[btn]
    end
    return nil
end

local function ScanActiveGuildVaultTab()
    if not GuildBankFrame or not GuildBankFrame:IsShown() or not ns.Scanner or not ns.Scanner.ApplySlotBorderGlow then return end
    local currentTab = GetCurrentGuildBankTab()
    local activeFaction = UnitFactionGroup("player") or "Alliance"

    for slotIndex = 1, 98 do
        local slotFrame = GetGuildSlotButton(slotIndex)
        if slotFrame then
            local itemLink = GetGuildBankItemLink(currentTab, slotIndex)
            if itemLink then
                if ns.DB and ns.DB.IsItemTradeLocked and ns.DB.IsItemTradeLocked(itemLink) then
                    ns.Scanner.ApplySlotBorderGlow(slotFrame, "LOCKED_RED")
                else
                    local upgList, profList = ns.Scanner.EvaluateItemForRoster(itemLink, activeFaction)
                    if upgList and #upgList > 0 then
                        ns.Scanner.ApplySlotBorderGlow(slotFrame, upgList[1].status)
                    elseif profList and #profList > 0 then
                        ns.Scanner.ApplySlotBorderGlow(slotFrame, profList[1].status)
                    else
                        ns.Scanner.ApplySlotBorderGlow(slotFrame, "CLEAR")
                    end
                end
            else
                ns.Scanner.ApplySlotBorderGlow(slotFrame, "CLEAR")
            end
        end
    end
end

GuildOverlay:SetScript("OnEvent", function(self, event)
    if event == "GUILDBANKFRAME_OPENED" or event == "GUILDBANKBAGSLOTS_CHANGED" then
        C_Timer.After(0.1, function()
            ScanActiveGuildVaultTab()
        end)
    end
end)
ns.RefreshLiveGuildBankGlows = ScanActiveGuildVaultTab
