-- SimpleDamageMeter.lua

-- Create the frame for the damage meter
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
frame:EnableMouse(true)  -- Make frame clickable to drag

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

-- Function to Get Class Icon
local function GetClassIcon(playerName)
    local _, class = UnitClass(playerName)
    if class then
        local texture = "Interface\\Icons\\ClassIcon_" .. class
        return texture
    end
    return nil
end

-- UI Update Function
local function UpdateDamageUI()
    -- Clear existing texts before updating
    if frame.texts then
        for _, text in ipairs(frame.texts) do
            text:Hide()
        end
    end
    frame.texts = {}

    local yOffset = -10
    for player, damage in pairs(damageData) do
        -- Create a new container frame for each player
        local playerFrame = CreateFrame("Frame", nil, frame)
        playerFrame:SetSize(230, 20)  -- Adjust width to fit the icon and name within the frame
        playerFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, yOffset)  -- Position it within the main frame

        -- Create the class icon inside the playerFrame
        local icon = GetClassIcon(player)
        if icon then
            local classIcon = playerFrame:CreateTexture(nil, "ARTWORK")
            classIcon:SetTexture(icon)
            classIcon:SetSize(16, 16)  -- Set the size of the icon
            classIcon:SetPoint("LEFT", playerFrame, "LEFT", 0, 0)  -- Position it to the left of the name
        end

        -- Create the player's name and damage text
        local text = playerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("LEFT", playerFrame, "LEFT", 20, 0)  -- Position the text to the right of the icon
        text:SetText(FormatNumber(damage) .. " " .. player)

        table.insert(frame.texts, text)
        yOffset = yOffset - 20
    end
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
        -- No chat print now, just update UI
        UpdateDamageUI()
    end
end)

-- Create the round button attached to the mini-map (Toggle Button)
local toggleButton = CreateFrame("Button", "SimpleDamageMeterToggleButton", UIParent, "BackdropTemplate")
toggleButton:SetSize(30, 30)  -- Set the size of the button
toggleButton:SetNormalTexture("Interface\\Icons\\INV_Misc_QuestionMark")  -- Set the icon

-- Add a golden border to the button (mimicking mini-map style)
toggleButton:SetBackdrop({
    bgFile = "Interface\\Buttons\\White8x8", 
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", 
    edgeSize = 12,
    insets = { left = 2, right = 2, top = 2, bottom = 2 }
})
toggleButton:SetBackdropColor(0, 0, 0, 0.8)
toggleButton:SetBackdropBorderColor(1, 0.84, 0, 1)  -- Golden color for the border

-- Function to position the icon on the edge of the mini-map
local function PositionButton()
    local minimapRadius = Minimap:GetWidth() / 2
    local angle = math.random() * 2 * math.pi  -- Random angle to start with
    local xOffset = minimapRadius * math.cos(angle)
    local yOffset = minimapRadius * math.sin(angle)

    toggleButton:SetPoint("CENTER", Minimap, "CENTER", xOffset, yOffset)
end

PositionButton()

-- Make the button **non-movable** and **clickable** (to toggle the frame visibility)
toggleButton:SetMovable(false)
toggleButton:EnableMouse(true)
toggleButton:SetScript("OnClick", function()
    if frame:IsShown() then
        frame:Hide()
    else
        frame:Show()
    end
end)

toggleButton:Show()

-- Allow dragging the frame (damage meter)
frame:SetMovable(true)
frame:EnableMouse(true)
frame:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" then
        self:StartMoving()
    end
end)

frame:SetScript("OnMouseUp", function(self)
    self:StopMovingOrSizing()
end)

SLASH_SIMPLEDMG1 = "/damage"
SlashCmdList["SIMPLEDMG"] = function(msg)
    if msg == "reset" then
        damageData = {}
        UpdateDamageUI()
        print("Damage reset!")
    else
        UpdateDamageUI()
    end
end
