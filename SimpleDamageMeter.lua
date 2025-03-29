local addonName = "SimpleDamageMeter"
local frame = CreateFrame("Frame", "SimpleDamageMeterFrame", UIParent)
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

-- Class color definitions (using Blizzard's exact colors)
local CLASS_COLORS = {}
for i = 1, GetNumClasses() do
    local className, classTag = GetClassInfo(i)
    local color = RAID_CLASS_COLORS[classTag]
    if color then
        CLASS_COLORS[classTag] = {r = color.r, g = color.g, b = color.b}
    end
end

-- Data storage
local damageData = {}
local playerFrames = {}
local playerClasses = {} -- Store class for each player
local playerSpecIcons = {} -- Store spec icons for each player
local pendingInspect = {} -- Tracks pending inspect requests

-- Format numbers
local function FormatNumber(num)
    num = num or 0
    if num >= 1e6 then return string.format("%.1fM", num/1e6) end
    if num >= 1e3 then return string.format("%.1fK", num/1e3) end
    return math.floor(num)
end

-- Check if player is in our group
local function IsInOurGroup(unitName)
    if UnitIsUnit("player", unitName) then return true end
    if not IsInGroup() then return false end
    
    for i = 1, GetNumGroupMembers() do
        local unit = IsInRaid() and "raid"..i or "party"..i
        if UnitName(unit) == unitName then
            return true
        end
    end
    return false
end

-- Get player class and spec
local function UpdatePlayerInfo(playerName)
    if UnitIsUnit("player", playerName) then
        -- Player
        local _, class = UnitClass("player")
        local specID = GetSpecialization()
        if specID then
            local _, _, _, icon = GetSpecializationInfo(specID)
            playerClasses[playerName] = class
            playerSpecIcons[playerName] = icon or "Interface\\Icons\\INV_Misc_QuestionMark"
        end
    else
        -- Group members
        for i = 1, GetNumGroupMembers() do
            local unit = IsInRaid() and "raid"..i or "party"..i
            if UnitName(unit) == playerName then
                local _, class = UnitClass(unit)
                playerClasses[playerName] = class
                
                -- Default to question mark until we inspect
                playerSpecIcons[playerName] = "Interface\\Icons\\INV_Misc_QuestionMark"
                
                -- Request inspection
                if CanInspect(unit) then
                    NotifyInspect(unit)
                    pendingInspect[UnitGUID(unit)] = playerName
                end
                break
            end
        end
    end
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
    local lineHeight = 24
    local padding = 5
    local totalHeight = numPlayers * lineHeight + padding * 2

    -- Resize frame
    frame:SetSize(250, totalHeight)

    -- Create/update player lines
    for i, playerData in ipairs(sortedPlayers) do
        local playerName = playerData.name
        local damage = playerData.damage
        
        -- Update player info if we don't have it yet
        if not playerClasses[playerName] then
            UpdatePlayerInfo(playerName)
        end
        
        local playerFrame = playerFrames[playerName] or CreateFrame("Frame", nil, frame)
        playerFrame:SetSize(240, lineHeight)
        playerFrame:SetPoint("TOPLEFT", 5, -padding - (i-1)*lineHeight)
        
        -- Class-colored line
        if not playerFrame.line then
            playerFrame.line = playerFrame:CreateTexture(nil, "BACKGROUND")
            playerFrame.line:SetAllPoints()
        end
        
        local class = playerClasses[playerName] or "WARRIOR"
        local color = CLASS_COLORS[class] or CLASS_COLORS.WARRIOR
        playerFrame.line:SetColorTexture(color.r, color.g, color.b, 0.7)
        
        -- Spec icon
        if not playerFrame.icon then
            playerFrame.icon = playerFrame:CreateTexture(nil, "ARTWORK")
            playerFrame.icon:SetSize(20, 20)
            playerFrame.icon:SetPoint("LEFT", 5, 0)
            playerFrame.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        end
        playerFrame.icon:SetTexture(playerSpecIcons[playerName])
        
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
frame:RegisterEvent("INSPECT_READY")
frame:SetScript("OnEvent", function(_, event, ...)
    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local _, subEvent, _, sourceGUID, sourceName = CombatLogGetCurrentEventInfo()
        local amount = select(15, CombatLogGetCurrentEventInfo()) or 0
        
        if (subEvent == "SPELL_DAMAGE" or subEvent == "SWING_DAMAGE" or 
            subEvent == "RANGE_DAMAGE" or subEvent == "SPELL_PERIODIC_DAMAGE") then
            
            -- Only track if source is in our group
            if sourceName and IsInOurGroup(sourceName) then
                damageData[sourceName] = (damageData[sourceName] or 0) + amount
                UpdateDamageUI()
            end
        end
        
    elseif event == "PLAYER_REGEN_DISABLED" then
        wipe(damageData)
        UpdateDamageUI()
        
    elseif event == "GROUP_ROSTER_UPDATE" then
        -- Update all player info when group changes
        wipe(pendingInspect)
        for playerName in pairs(damageData) do
            UpdatePlayerInfo(playerName)
        end
        UpdateDamageUI()
        
    elseif event == "INSPECT_READY" then
        local guid = ...
        local playerName = pendingInspect[guid]
        if playerName then
            for i = 1, GetNumGroupMembers() do
                local unit = IsInRaid() and "raid"..i or "party"..i
                if UnitName(unit) == playerName then
                    local specID = GetInspectSpecialization(unit)
                    if specID and specID > 0 then
                        local _, _, _, icon = GetSpecializationInfoByID(specID)
                        playerSpecIcons[playerName] = icon
                        UpdateDamageUI()
                    end
                    pendingInspect[guid] = nil
                    break
                end
            end
        end
    end
end)

-- Toggle button
local toggleBtn = CreateFrame("Button", nil, UIParent, "UIPanelButtonTemplate")
toggleBtn:SetSize(36, 36)
toggleBtn:SetPoint("TOPRIGHT", Minimap, "TOPRIGHT", -5, -5)
toggleBtn:SetNormalTexture("Interface\\Icons\\Ability_Warrior_Charge")
toggleBtn:SetPushedTexture("Interface\\Icons\\Ability_Warrior_Charge")
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

-- Periodically request spec info
local specUpdateTimer = 0
frame:SetScript("OnUpdate", function(self, elapsed)
    specUpdateTimer = specUpdateTimer + elapsed
    if specUpdateTimer > 5 then -- Update every 5 seconds
        if IsInGroup() then
            for i = 1, GetNumGroupMembers() do
                local unit = IsInRaid() and "raid"..i or "party"..i
                if not UnitIsUnit(unit, "player") and CanInspect(unit) then
                    NotifyInspect(unit)
                end
            end
        end
        specUpdateTimer = 0
    end
end)