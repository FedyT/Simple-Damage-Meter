local addonName = "SimpleDamageMeter"
local frame = CreateFrame("Frame", "SimpleDamageMeterFrame", UIParent, "BackdropTemplate")
frame:SetBackdrop(nil) -- No background frame
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

-- Class color definitions (RGB 0-1 format)
local CLASS_COLORS = {
    WARRIOR = { r = 0.78, g = 0.61, b = 0.43 },
    MAGE = { r = 0.41, g = 0.80, b = 0.94 },
    ROGUE = { r = 1.00, g = 0.96, b = 0.41 },
    HUNTER = { r = 0.67, g = 0.83, b = 0.45 },
    PRIEST = { r = 1.00, g = 1.00, b = 1.00 },
    PALADIN = { r = 0.96, g = 0.55, b = 0.73 },
    SHAMAN = { r = 0.00, g = 0.44, b = 0.87 },
    WARLOCK = { r = 0.53, g = 0.53, b = 0.93 },
    DRUID = { r = 1.00, g = 0.49, b = 0.04 },
    DEATHKNIGHT = { r = 0.77, g = 0.12, b = 0.23 },
    MONK = { r = 0.00, g = 1.00, b = 0.59 },
    DEMONHUNTER = { r = 0.64, g = 0.19, b = 0.79 },
    EVOKER = { r = 0.20, g = 0.58, b = 0.50 },
}

-- Data storage
local damageData = {}
local playerFrames = {}

-- Format numbers
local function FormatNumber(num)
    num = num or 0
    if num >= 1e6 then return string.format("%.1fM", num/1e6) end
    if num >= 1e3 then return string.format("%.1fK", num/1e3) end
    return math.floor(num)
end

-- Get player class
local function GetPlayerClass(playerName)
    if UnitIsUnit("player", playerName) then
        local _, class = UnitClass("player")
        return class
    end
    
    for i = 1, GetNumGroupMembers() do
        local unit = IsInRaid() and "raid"..i or "party"..i
        if UnitName(unit) == playerName then
            local _, class = UnitClass(unit)
            return class
        end
    end
    return "WARRIOR" -- Default
end

-- Get spec icon
local function GetSpecIcon(playerName)
    for i = 1, GetNumGroupMembers() do
        local unit = IsInRaid() and "raid"..i or "party"..i
        if UnitName(unit) == playerName then
            local specID = GetSpecializationInfo(GetSpecialization(nil, nil, unit))
            return specID and select(4, GetSpecializationInfoByID(specID)) or "Interface\\Icons\\INV_Misc_QuestionMark"
        end
    end
    if UnitIsUnit("player", playerName) then
        local specID = GetSpecializationInfo(GetSpecialization())
        return specID and select(4, GetSpecializationInfoByID(specID)) or "Interface\\Icons\\INV_Misc_QuestionMark"
    end
    return "Interface\\Icons\\INV_Misc_QuestionMark"
end

-- Update UI with dynamic sizing
local function UpdateDamageUI()
    -- Sort players by damage
    local sortedPlayers = {}
    for player, damage in pairs(damageData) do
        table.insert(sortedPlayers, { name = player, damage = damage })
    end
    table.sort(sortedPlayers, function(a, b) return a.damage > b.damage end)

    -- Calculate needed height
    local numPlayers = math.max(1, #sortedPlayers) -- At least 1 line
    local lineHeight = 24
    local padding = 5
    local totalHeight = numPlayers * lineHeight + padding * 2

    -- Resize frame
    frame:SetSize(250, totalHeight)

    -- Create/update player lines
    for i, playerData in ipairs(sortedPlayers) do
        local playerName = playerData.name
        local damage = playerData.damage
        
        local playerFrame = playerFrames[playerName] or CreateFrame("Frame", nil, frame, "BackdropTemplate")
        playerFrame:SetSize(240, lineHeight)
        playerFrame:SetPoint("TOPLEFT", 5, -padding - (i-1)*lineHeight)
        
        -- Class-colored line
        if not playerFrame.line then
            playerFrame.line = playerFrame:CreateTexture(nil, "BACKGROUND")
            playerFrame.line:SetAllPoints()
        end
        
        local class = GetPlayerClass(playerName)
        local color = CLASS_COLORS[class] or CLASS_COLORS.WARRIOR
        playerFrame.line:SetColorTexture(color.r, color.g, color.b, 0.7)
        
        -- Spec icon
        if not playerFrame.icon then
            playerFrame.icon = playerFrame:CreateTexture(nil, "ARTWORK")
            playerFrame.icon:SetSize(20, 20)
            playerFrame.icon:SetPoint("LEFT", 5, 0)
            playerFrame.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        end
        playerFrame.icon:SetTexture(GetSpecIcon(playerName))
        
        -- Player name
        if not playerFrame.nameText then
            playerFrame.nameText = playerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            playerFrame.nameText:SetPoint("LEFT", 30, 0)
            playerFrame.nameText:SetTextColor(1, 1, 1, 1)
            playerFrame.nameText:SetShadowOffset(1, -1)
        end
        playerFrame.nameText:SetText(playerName)
        
        -- Damage value
        if not playerFrame.damageText then
            playerFrame.damageText = playerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            playerFrame.damageText:SetPoint("RIGHT", -5, 0)
            playerFrame.damageText:SetTextColor(1, 1, 1, 1)
            playerFrame.damageText:SetShadowOffset(1, -1)
        end
        playerFrame.damageText:SetText(FormatNumber(damage))
        
        playerFrame:Show()
        playerFrames[playerName] = playerFrame
    end
end

-- Combat events
frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
frame:RegisterEvent("PLAYER_REGEN_DISABLED")
frame:RegisterEvent("GROUP_ROSTER_UPDATE")
frame:SetScript("OnEvent", function(_, event, ...)
    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local _, subEvent, _, _, sourceName = CombatLogGetCurrentEventInfo()
        if (subEvent == "SPELL_DAMAGE" or subEvent == "SWING_DAMAGE" or 
            subEvent == "RANGE_DAMAGE" or subEvent == "SPELL_PERIODIC_DAMAGE") then
            if sourceName and (UnitIsUnit("player", sourceName) or IsInGroup()) then
                local amount = select(15, CombatLogGetCurrentEventInfo()) or 0
                damageData[sourceName] = (damageData[sourceName] or 0) + amount
                UpdateDamageUI()
            end
        end
    elseif event == "PLAYER_REGEN_DISABLED" then
        wipe(damageData)
        UpdateDamageUI()
    elseif event == "GROUP_ROSTER_UPDATE" then
        UpdateDamageUI()
    end
end)

-- Toggle button with icon instead of text
local toggleBtn = CreateFrame("Button", nil, UIParent, "UIPanelButtonTemplate")
toggleBtn:SetSize(36, 36)  -- Set button size (adjust as needed)
toggleBtn:SetPoint("TOPRIGHT", Minimap, "TOPRIGHT", -5, -5)  -- Position around the minimap

-- Set an icon for the button (use a valid path for the icon)
toggleBtn:SetNormalTexture("Interface\\Icons\\Ability_Warrior_Charge")  -- Replace with a valid icon path
toggleBtn:SetPushedTexture("Interface\\Icons\\Ability_Warrior_Charge")  -- Optional, set for the pressed state

toggleBtn:SetScript("OnClick", function() 
    frame:SetShown(not frame:IsShown())
end)

-- Slash command
SLASH_SIMPLEDMG1 = "/dm"
SlashCmdList["SIMPLEDMG"] = function(msg)
    if msg == "reset" then
        wipe(damageData)
        UpdateDamageUI()
    else
        frame:SetShown(not frame:IsShown())
    end
end

-- Initial setup
frame:SetPoint("CENTER")
UpdateDamageUI()
