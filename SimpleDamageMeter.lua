-- SimpleDamageMeter.lua

local frame = CreateFrame("Frame", "SimpleDamageMeterFrame", UIParent, "BackdropTemplate")
frame:SetSize(250, 200)
frame:SetPoint("CENTER")
frame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
frame:SetBackdropColor(0, 0, 0, 1)

-- Dragging Logic
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

-- Damage Storage
local damageData = {}

-- Function to Format Numbers
local function FormatNumber(num)
    if num >= 1e6 then
        return string.format("%.1fM", num / 1e6)
    elseif num >= 1e3 then
        return string.format("%.1fK", num / 1e3)
    else
        return tostring(num)
    end
end

-- UI Update Function
local function UpdateDamageUI()
    for _, text in ipairs(frame.texts or {}) do
        text:Hide()
    end
    frame.texts = {}

    local yOffset = -10
    for player, damage in pairs(damageData) do
        local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("TOPLEFT", 10, yOffset)
        text:SetText(player .. ": " .. FormatNumber(damage))
        table.insert(frame.texts, text)
        yOffset = yOffset - 20
    end
end

-- Check if player is in the group
local function IsPlayerInGroup(playerName)
    local isInGroup = false
    if IsInGroup() then
        -- Check party members
        for i = 1, GetNumGroupMembers() do
            local name = GetUnitName("party" .. i, true)
            if name == playerName then
                isInGroup = true
                break
            end
        end
    end
    if IsInRaid() then
        -- Check raid members
        for i = 1, GetNumGroupMembers() do
            local name = GetUnitName("raid" .. i, true)
            if name == playerName then
                isInGroup = true
                break
            end
        end
    end
    return isInGroup
end

-- Event Handling
frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
frame:RegisterEvent("PLAYER_REGEN_DISABLED")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")

frame:SetScript("OnEvent", function(self, event)
    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local _, subEvent, _, sourceGUID, sourceName, _, _, _, _, _, _, _, _, _, amount = CombatLogGetCurrentEventInfo()
        if (subEvent == "SPELL_DAMAGE" or subEvent == "RANGE_DAMAGE" or subEvent == "SWING_DAMAGE") then
            if sourceName and (sourceName == UnitName("player") or IsPlayerInGroup(sourceName)) then
                damageData[sourceName] = (damageData[sourceName] or 0) + (amount or 0)
                UpdateDamageUI()
            end
        end
    elseif event == "PLAYER_REGEN_DISABLED" then
        damageData = {}  -- Reset on fight start
        UpdateDamageUI()
    elseif event == "PLAYER_REGEN_ENABLED" then
        print("Fight Over! Damage Done:")
        for player, damage in pairs(damageData) do
            print(player .. ": " .. FormatNumber(damage))
        end
    end
end)

-- Toggle Button
local toggleButton = CreateFrame("Button", "SimpleDamageMeterToggleButton", UIParent, "UIPanelButtonTemplate")
toggleButton:SetPoint("BOTTOMRIGHT", -20, 100)
toggleButton:SetSize(150, 30)
toggleButton:SetText("Toggle Damage Meter")
toggleButton:SetScript("OnClick", function()
    if frame:IsShown() then
        frame:Hide()
    else
        frame:Show()
    end
end)
toggleButton:Show()

SLASH_SIMPLEDMG1 = "/damage"
SlashCmdList["SIMPLEDMG"] = function(msg)
    if msg == "reset" then
        damageData = {}
        UpdateDamageUI()
        print("Damage reset!")
    else
        print("Current Damage Done:")
        for player, damage in pairs(damageData) do
            print(player .. ": " .. FormatNumber(damage))
        end
    end
end
