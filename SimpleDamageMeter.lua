local addonName = "SimpleDamageMeter"
local addonVersion = "2.1"

-- Configuration settings
local settings = {
    lockPosition = false,
    showRankNumbers = true,
    fontSize = 12,
    lineHeight = 20,
    width = 250,
    showTooltips = true,
    showDPS = true,
    autoHide = false,
    autoHideDelay = 10
}

-- Class color definitions
local CLASS_COLORS = {}
for classTag, color in pairs(RAID_CLASS_COLORS) do
    CLASS_COLORS[classTag] = {r = color.r, g = color.g, b = color.b}
end

-- Create main frame with guaranteed dragging
local frame = CreateFrame("Frame", "SimpleDamageMeterFrame", UIParent)
frame:SetSize(settings.width, 100)
frame:SetPoint("CENTER")

-- Create a nearly invisible drag handle that covers the whole frame
local dragFrame = CreateFrame("Frame", nil, frame)
dragFrame:SetAllPoints()
dragFrame:EnableMouse(true)
dragFrame:RegisterForDrag("LeftButton")
dragFrame:SetScript("OnDragStart", function(self)
    if not settings.lockPosition then
        frame:StartMoving()
    end
end)
dragFrame:SetScript("OnDragStop", function(self)
    frame:StopMovingOrSizing()
end)

-- Make the frame itself movable (double protection)
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", function(self)
    if not settings.lockPosition then
        self:StartMoving()
    end
end)
frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
end)

-- Data storage
local damageData = {}
local playerFrames = {}
local inCombat = false
local combatStartTime = 0
local playerClasses = {}
local petToOwner = {}

-- Format numbers
local function FormatNumber(num)
    num = num or 0
    if num >= 1e6 then return string.format("%.1fM", num/1e6) end
    if num >= 1e3 then return string.format("%.1fK", num/1e3) end
    return math.floor(num)
end

-- Reset all damage data
local function ResetDamageData()
    wipe(damageData)
    wipe(petToOwner)
    for _, f in pairs(playerFrames) do
        f:Hide()
    end
    combatStartTime = GetTime()
end

-- Check if unit is player or group member
local function IsPlayerOrGroupMember(sourceName)
    if UnitName("player") == sourceName then
        return true, nil
    end
    
    if IsInGroup() then
        for i = 1, GetNumGroupMembers() do
            local unit = IsInRaid() and "raid"..i or "party"..i
            if UnitName(unit) == sourceName then
                return true, nil
            end
            
            local petUnit = unit.."pet"
            if UnitExists(petUnit) and UnitName(petUnit) == sourceName then
                return false, UnitName(unit)
            end
        end
    end
    
    return false, nil
end

-- Get player class
local function GetPlayerClass(playerName)
    if UnitName("player") == playerName then
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
    return "WARRIOR"
end

-- Get player class icon
local function GetPlayerClassIcon(playerName)
    local class = GetPlayerClass(playerName)
    return "Interface\\ICONS\\CLASSICON_"..strupper(class)
end

-- Update UI
local function UpdateDamageUI()
    -- Sort players by damage
    local sortedPlayers = {}
    for player, damage in pairs(damageData) do
        table.insert(sortedPlayers, { name = player, damage = damage })
    end
    table.sort(sortedPlayers, function(a, b) return a.damage > b.damage end)

    -- Calculate needed height
    local numPlayers = math.max(1, #sortedPlayers)
    local padding = 5
    local headerHeight = 5
    local totalHeight = headerHeight + (numPlayers * settings.lineHeight) + padding * 2

    -- Resize frame
    frame:SetHeight(totalHeight)

    -- Create/update player lines
    for i, playerData in ipairs(sortedPlayers) do
        local playerName = playerData.name
        local damage = playerData.damage
        
        -- Get player class
        if not playerClasses[playerName] then
            playerClasses[playerName] = GetPlayerClass(playerName)
        end
        
        local playerFrame = playerFrames[playerName] or CreateFrame("Frame", nil, frame)
        playerFrame:SetSize(settings.width - 10, settings.lineHeight)
        playerFrame:SetPoint("TOPLEFT", 5, -headerHeight - (i-1)*settings.lineHeight - padding)
        
        -- Class-colored rectangle background
        if not playerFrame.background then
            playerFrame.background = playerFrame:CreateTexture(nil, "BACKGROUND")
            playerFrame.background:SetAllPoints()
        end
        
        local color = CLASS_COLORS[playerClasses[playerName]] or CLASS_COLORS.WARRIOR
        playerFrame.background:SetColorTexture(color.r, color.g, color.b, 0.5)
        
        -- Class icon
        if not playerFrame.classIcon then
            playerFrame.classIcon = playerFrame:CreateTexture(nil, "OVERLAY")
            playerFrame.classIcon:SetSize(settings.lineHeight - 4, settings.lineHeight - 4)
            playerFrame.classIcon:SetPoint("LEFT", 5, 0)
        end
        playerFrame.classIcon:SetTexture(GetPlayerClassIcon(playerName))
        playerFrame.classIcon:Show()
        
        -- Player name
        if not playerFrame.nameText then
            playerFrame.nameText = playerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            playerFrame.nameText:SetPoint("LEFT", playerFrame.classIcon, "RIGHT", 5, 0)
            playerFrame.nameText:SetTextColor(1, 1, 1, 1)
        end
        playerFrame.nameText:SetText(playerName)
        
        -- Damage value
        if not playerFrame.damageText then
            playerFrame.damageText = playerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            playerFrame.damageText:SetPoint("RIGHT", -5, 0)
            playerFrame.damageText:SetTextColor(1, 1, 1, 1)
        end
        
        local displayText = FormatNumber(damage)
        if settings.showDPS and inCombat then
            local dps = damage / (GetTime() - combatStartTime)
            displayText = displayText.." ("..FormatNumber(dps)..")"
        end
        playerFrame.damageText:SetText(displayText)
        
        playerFrame:Show()
        playerFrames[playerName] = playerFrame
    end
end

-- Combat events
frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
frame:RegisterEvent("PLAYER_REGEN_DISABLED")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:SetScript("OnEvent", function(_, event, ...)
    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local _, subEvent, _, sourceGUID, sourceName = CombatLogGetCurrentEventInfo()
        local amount = select(15, CombatLogGetCurrentEventInfo()) or 0
        
        if (subEvent == "SPELL_DAMAGE" or subEvent == "SWING_DAMAGE" or 
            subEvent == "RANGE_DAMAGE" or subEvent == "SPELL_PERIODIC_DAMAGE") then
            
            local isPlayer, ownerName = IsPlayerOrGroupMember(sourceName)
            
            if isPlayer then
                if not inCombat then
                    ResetDamageData()
                    inCombat = true
                end
                damageData[sourceName] = (damageData[sourceName] or 0) + amount
                UpdateDamageUI()
            elseif ownerName then
                if not inCombat then
                    ResetDamageData()
                    inCombat = true
                end
                petToOwner[sourceName] = ownerName
                damageData[ownerName] = (damageData[ownerName] or 0) + amount
                UpdateDamageUI()
            end
        end
    elseif event == "PLAYER_REGEN_DISABLED" then
        if not inCombat then
            ResetDamageData()
            inCombat = true
        end
    elseif event == "PLAYER_REGEN_ENABLED" then
        inCombat = false
        if settings.autoHide then
            C_Timer.After(settings.autoHideDelay, function()
                if not inCombat then
                    frame:Hide()
                end
            end)
        end
    end
end)

-- Toggle button
local toggleBtn = CreateFrame("Button", nil, UIParent)
toggleBtn:SetSize(24, 24)
toggleBtn:SetPoint("TOPRIGHT", Minimap, "TOPRIGHT", -5, -5)
toggleBtn:SetNormalTexture("Interface\\Icons\\Ability_Warrior_Charge")
toggleBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
toggleBtn:SetScript("OnClick", function() 
    frame:SetShown(not frame:IsShown())
end)

-- Slash commands
SLASH_SIMPLEDMG1 = "/dm"
SlashCmdList["SIMPLEDMG"] = function(msg)
    msg = msg and msg:lower() or ""
    if msg == "reset" then
        ResetDamageData()
    elseif msg == "lock" then
        settings.lockPosition = true
        print(addonName..": Window position locked")
    elseif msg == "unlock" then
        settings.lockPosition = false
        print(addonName..": Window position unlocked")
    else
        frame:SetShown(not frame:IsShown())
    end
end

-- Initial setup
ResetDamageData()
frame:Show()