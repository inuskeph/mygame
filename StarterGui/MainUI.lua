--[[
    MainUI.lua (LocalScript)
    Master UI controller for the Chameleon game.
    Creates and manages all UI elements: HUD, timer, scoreboard, paint picker,
    role display, round results, and controls help.
    Place in StarterGui.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local GameConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameConfig"))
local PaintSystem = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PaintSystem"))

local Events = ReplicatedStorage:WaitForChild("Events")
local RoundStateChanged = Events:WaitForChild("RoundStateChanged")
local RoleAssigned = Events:WaitForChild("RoleAssigned")
local TimerSync = Events:WaitForChild("TimerSync")
local ScoreUpdate = Events:WaitForChild("ScoreUpdate")
local PlayerEliminated = Events:WaitForChild("PlayerEliminated")
local GameOver = Events:WaitForChild("GameOver")
local PaintCharacter = Events:WaitForChild("PaintCharacter")


----------------------------------------------------------------------
-- REFERENCES
----------------------------------------------------------------------

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local myRole = nil
local currentState = "Lobby"

----------------------------------------------------------------------
-- UI CREATION HELPERS
----------------------------------------------------------------------

local function createCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 8)
    corner.Parent = parent
    return corner
end

local function createStroke(parent, color, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Color3.fromRGB(255, 255, 255)
    stroke.Thickness = thickness or 1
    stroke.Parent = parent
    return stroke
end

local function createPadding(parent, padding)
    local p = Instance.new("UIPadding")
    p.PaddingTop = UDim.new(0, padding)
    p.PaddingBottom = UDim.new(0, padding)
    p.PaddingLeft = UDim.new(0, padding)
    p.PaddingRight = UDim.new(0, padding)
    p.Parent = parent
    return p
end


----------------------------------------------------------------------
-- MAIN SCREEN GUI
----------------------------------------------------------------------

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ChameleonHUD"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

----------------------------------------------------------------------
-- TIMER DISPLAY (top center)
----------------------------------------------------------------------

local timerFrame = Instance.new("Frame")
timerFrame.Name = "TimerFrame"
timerFrame.Size = UDim2.new(0, 280, 0, 60)
timerFrame.Position = UDim2.new(0.5, -140, 0, 10)
timerFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
timerFrame.BackgroundTransparency = 0.2
timerFrame.Parent = screenGui
createCorner(timerFrame, 12)
createStroke(timerFrame, Color3.fromRGB(80, 150, 255), 2)

local timerLabel = Instance.new("TextLabel")
timerLabel.Name = "TimerLabel"
timerLabel.Size = UDim2.new(1, 0, 0.4, 0)
timerLabel.Position = UDim2.new(0, 0, 0, 4)
timerLabel.BackgroundTransparency = 1
timerLabel.TextColor3 = Color3.fromRGB(180, 200, 255)
timerLabel.Text = "LOBBY"
timerLabel.TextSize = 14
timerLabel.Font = Enum.Font.GothamBold
timerLabel.Parent = timerFrame

local timerValue = Instance.new("TextLabel")
timerValue.Name = "TimerValue"
timerValue.Size = UDim2.new(1, 0, 0.6, 0)
timerValue.Position = UDim2.new(0, 0, 0.35, 0)
timerValue.BackgroundTransparency = 1
timerValue.TextColor3 = Color3.fromRGB(255, 255, 255)
timerValue.Text = "--:--"
timerValue.TextSize = 28
timerValue.Font = Enum.Font.GothamBlack
timerValue.Parent = timerFrame


----------------------------------------------------------------------
-- ROLE DISPLAY (below timer)
----------------------------------------------------------------------

local roleFrame = Instance.new("Frame")
roleFrame.Name = "RoleFrame"
roleFrame.Size = UDim2.new(0, 200, 0, 40)
roleFrame.Position = UDim2.new(0.5, -100, 0, 78)
roleFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
roleFrame.BackgroundTransparency = 0.3
roleFrame.Visible = false
roleFrame.Parent = screenGui
createCorner(roleFrame, 10)

local roleLabel = Instance.new("TextLabel")
roleLabel.Name = "RoleLabel"
roleLabel.Size = UDim2.new(1, 0, 1, 0)
roleLabel.BackgroundTransparency = 1
roleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
roleLabel.Text = ""
roleLabel.TextSize = 20
roleLabel.Font = Enum.Font.GothamBold
roleLabel.Parent = roleFrame

----------------------------------------------------------------------
-- SCORE DISPLAY (top right)
----------------------------------------------------------------------

local scoreFrame = Instance.new("Frame")
scoreFrame.Name = "ScoreFrame"
scoreFrame.Size = UDim2.new(0, 180, 0, 70)
scoreFrame.Position = UDim2.new(1, -190, 0, 10)
scoreFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
scoreFrame.BackgroundTransparency = 0.3
scoreFrame.Parent = screenGui
createCorner(scoreFrame, 10)
createStroke(scoreFrame, Color3.fromRGB(255, 200, 50), 1)

local pointsLabel = Instance.new("TextLabel")
pointsLabel.Name = "PointsLabel"
pointsLabel.Size = UDim2.new(1, -10, 0.5, 0)
pointsLabel.Position = UDim2.new(0, 10, 0, 2)
pointsLabel.BackgroundTransparency = 1
pointsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
pointsLabel.Text = "Points: 0"
pointsLabel.TextSize = 16
pointsLabel.Font = Enum.Font.GothamBold
pointsLabel.TextXAlignment = Enum.TextXAlignment.Left
pointsLabel.Parent = scoreFrame

local coinsLabel = Instance.new("TextLabel")
coinsLabel.Name = "CoinsLabel"
coinsLabel.Size = UDim2.new(1, -10, 0.5, 0)
coinsLabel.Position = UDim2.new(0, 10, 0.5, 0)
coinsLabel.BackgroundTransparency = 1
coinsLabel.TextColor3 = Color3.fromRGB(255, 210, 50)
coinsLabel.Text = "Coins: 0"
coinsLabel.TextSize = 16
coinsLabel.Font = Enum.Font.GothamBold
coinsLabel.TextXAlignment = Enum.TextXAlignment.Left
coinsLabel.Parent = scoreFrame


----------------------------------------------------------------------
-- PAINT CHARGES DISPLAY (bottom left, visible during prep)
----------------------------------------------------------------------

local paintFrame = Instance.new("Frame")
paintFrame.Name = "PaintFrame"
paintFrame.Size = UDim2.new(0, 200, 0, 50)
paintFrame.Position = UDim2.new(0, 10, 1, -60)
paintFrame.BackgroundColor3 = Color3.fromRGB(20, 40, 20)
paintFrame.BackgroundTransparency = 0.3
paintFrame.Visible = false
paintFrame.Parent = screenGui
createCorner(paintFrame, 8)

local paintIcon = Instance.new("TextLabel")
paintIcon.Size = UDim2.new(0, 30, 1, 0)
paintIcon.Position = UDim2.new(0, 5, 0, 0)
paintIcon.BackgroundTransparency = 1
paintIcon.Text = "🎨"
paintIcon.TextSize = 20
paintIcon.Parent = paintFrame

local paintChargesLabel = Instance.new("TextLabel")
paintChargesLabel.Name = "PaintCharges"
paintChargesLabel.Size = UDim2.new(1, -40, 1, 0)
paintChargesLabel.Position = UDim2.new(0, 38, 0, 0)
paintChargesLabel.BackgroundTransparency = 1
paintChargesLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
paintChargesLabel.Text = "Paint: 10/10"
paintChargesLabel.TextSize = 16
paintChargesLabel.Font = Enum.Font.GothamBold
paintChargesLabel.TextXAlignment = Enum.TextXAlignment.Left
paintChargesLabel.Parent = paintFrame

----------------------------------------------------------------------
-- COLOR PALETTE UI (bottom center, visible during prep)
----------------------------------------------------------------------

local paletteFrame = Instance.new("Frame")
paletteFrame.Name = "PaletteFrame"
paletteFrame.Size = UDim2.new(0, 400, 0, 60)
paletteFrame.Position = UDim2.new(0.5, -200, 1, -70)
paletteFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
paletteFrame.BackgroundTransparency = 0.2
paletteFrame.Visible = false
paletteFrame.Parent = screenGui
createCorner(paletteFrame, 10)
createStroke(paletteFrame, Color3.fromRGB(100, 200, 100), 1)

local paletteLayout = Instance.new("UIListLayout")
paletteLayout.FillDirection = Enum.FillDirection.Horizontal
paletteLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
paletteLayout.VerticalAlignment = Enum.VerticalAlignment.Center
paletteLayout.Padding = UDim.new(0, 6)
paletteLayout.Parent = paletteFrame
createPadding(paletteFrame, 8)


----------------------------------------------------------------------
-- SEEKER ABILITY COOLDOWN (bottom right, visible during seek)
----------------------------------------------------------------------

local abilityFrame = Instance.new("Frame")
abilityFrame.Name = "AbilityFrame"
abilityFrame.Size = UDim2.new(0, 180, 0, 50)
abilityFrame.Position = UDim2.new(1, -190, 1, -60)
abilityFrame.BackgroundColor3 = Color3.fromRGB(40, 20, 20)
abilityFrame.BackgroundTransparency = 0.3
abilityFrame.Visible = false
abilityFrame.Parent = screenGui
createCorner(abilityFrame, 8)

local abilityLabel = Instance.new("TextLabel")
abilityLabel.Name = "AbilityLabel"
abilityLabel.Size = UDim2.new(1, -10, 1, 0)
abilityLabel.Position = UDim2.new(0, 10, 0, 0)
abilityLabel.BackgroundTransparency = 1
abilityLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
abilityLabel.Text = "[X] Pulse: READY"
abilityLabel.TextSize = 14
abilityLabel.Font = Enum.Font.GothamBold
abilityLabel.TextXAlignment = Enum.TextXAlignment.Left
abilityLabel.Parent = abilityFrame

----------------------------------------------------------------------
-- CONTROLS HELP (bottom center, contextual)
----------------------------------------------------------------------

local controlsFrame = Instance.new("Frame")
controlsFrame.Name = "ControlsFrame"
controlsFrame.Size = UDim2.new(0, 500, 0, 35)
controlsFrame.Position = UDim2.new(0.5, -250, 1, -105)
controlsFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
controlsFrame.BackgroundTransparency = 0.5
controlsFrame.Visible = false
controlsFrame.Parent = screenGui
createCorner(controlsFrame, 6)

local controlsLabel = Instance.new("TextLabel")
controlsLabel.Name = "ControlsLabel"
controlsLabel.Size = UDim2.new(1, 0, 1, 0)
controlsLabel.BackgroundTransparency = 1
controlsLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
controlsLabel.Text = ""
controlsLabel.TextSize = 12
controlsLabel.Font = Enum.Font.Gotham
controlsLabel.Parent = controlsFrame


----------------------------------------------------------------------
-- ELIMINATION FEED (top left, shows tags)
----------------------------------------------------------------------

local feedFrame = Instance.new("Frame")
feedFrame.Name = "FeedFrame"
feedFrame.Size = UDim2.new(0, 280, 0, 200)
feedFrame.Position = UDim2.new(0, 10, 0, 10)
feedFrame.BackgroundTransparency = 1
feedFrame.Parent = screenGui

local feedLayout = Instance.new("UIListLayout")
feedLayout.FillDirection = Enum.FillDirection.Vertical
feedLayout.VerticalAlignment = Enum.VerticalAlignment.Top
feedLayout.Padding = UDim.new(0, 4)
feedLayout.SortOrder = Enum.SortOrder.LayoutOrder
feedLayout.Parent = feedFrame

----------------------------------------------------------------------
-- RESULTS SCREEN (shown at end of round)
----------------------------------------------------------------------

local resultsGui = Instance.new("ScreenGui")
resultsGui.Name = "ResultsScreen"
resultsGui.ResetOnSpawn = false
resultsGui.IgnoreGuiInset = true
resultsGui.Enabled = false
resultsGui.DisplayOrder = 50
resultsGui.Parent = playerGui

local resultsBg = Instance.new("Frame")
resultsBg.Size = UDim2.new(1, 0, 1, 0)
resultsBg.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
resultsBg.BackgroundTransparency = 0.3
resultsBg.Parent = resultsGui

local resultsFrame = Instance.new("Frame")
resultsFrame.Name = "ResultsPanel"
resultsFrame.Size = UDim2.new(0, 450, 0, 400)
resultsFrame.Position = UDim2.new(0.5, -225, 0.5, -200)
resultsFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
resultsFrame.BackgroundTransparency = 0.1
resultsFrame.Parent = resultsGui
createCorner(resultsFrame, 16)
createStroke(resultsFrame, Color3.fromRGB(255, 200, 50), 2)

local resultsTitle = Instance.new("TextLabel")
resultsTitle.Name = "Title"
resultsTitle.Size = UDim2.new(1, 0, 0, 50)
resultsTitle.BackgroundTransparency = 1
resultsTitle.TextColor3 = Color3.fromRGB(255, 220, 50)
resultsTitle.Text = "ROUND RESULTS"
resultsTitle.TextSize = 28
resultsTitle.Font = Enum.Font.GothamBlack
resultsTitle.Parent = resultsFrame

local resultsContent = Instance.new("ScrollingFrame")
resultsContent.Name = "Content"
resultsContent.Size = UDim2.new(1, -20, 1, -60)
resultsContent.Position = UDim2.new(0, 10, 0, 55)
resultsContent.BackgroundTransparency = 1
resultsContent.ScrollBarThickness = 4
resultsContent.Parent = resultsFrame

local resultsLayout = Instance.new("UIListLayout")
resultsLayout.Padding = UDim.new(0, 6)
resultsLayout.Parent = resultsContent


----------------------------------------------------------------------
-- UI UPDATE FUNCTIONS
----------------------------------------------------------------------

-- Update the color palette display
local function buildPalette(colors)
    -- Clear existing buttons
    for _, child in ipairs(paletteFrame:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end

    -- Create color buttons
    for i, color in ipairs(colors) do
        local btn = Instance.new("TextButton")
        btn.Name = "Color_" .. i
        btn.Size = UDim2.new(0, 38, 0, 38)
        btn.BackgroundColor3 = color
        btn.Text = tostring(i)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.TextSize = 11
        btn.Font = Enum.Font.GothamBold
        btn.TextStrokeTransparency = 0.5
        btn.Parent = paletteFrame
        createCorner(btn, 6)
        createStroke(btn, Color3.fromRGB(255, 255, 255), 1)

        btn.MouseButton1Click:Connect(function()
            -- Handled by PaintClient via number keys,
            -- but also fire a BindableEvent or just select visually
            -- Highlight selected
            for _, other in ipairs(paletteFrame:GetChildren()) do
                if other:IsA("TextButton") then
                    local stroke = other:FindFirstChildOfClass("UIStroke")
                    if stroke then
                        stroke.Color = Color3.fromRGB(255, 255, 255)
                        stroke.Thickness = 1
                    end
                end
            end
            local myStroke = btn:FindFirstChildOfClass("UIStroke")
            if myStroke then
                myStroke.Color = Color3.fromRGB(0, 255, 0)
                myStroke.Thickness = 3
            end
        end)
    end
end

-- Add a kill feed entry
local function addFeedEntry(text, color)
    local entry = Instance.new("TextLabel")
    entry.Size = UDim2.new(1, 0, 0, 22)
    entry.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    entry.BackgroundTransparency = 0.5
    entry.TextColor3 = color or Color3.fromRGB(255, 100, 100)
    entry.Text = text
    entry.TextSize = 13
    entry.Font = Enum.Font.GothamBold
    entry.TextXAlignment = Enum.TextXAlignment.Left
    entry.Parent = feedFrame
    createCorner(entry, 4)
    createPadding(entry, 4)

    -- Auto-remove after 8 seconds
    task.delay(8, function()
        if entry and entry.Parent then
            local fade = TweenService:Create(entry, TweenInfo.new(0.5), {
                TextTransparency = 1,
                BackgroundTransparency = 1,
            })
            fade:Play()
            fade.Completed:Connect(function()
                entry:Destroy()
            end)
        end
    end)

    -- Limit feed entries
    local children = feedFrame:GetChildren()
    local labels = {}
    for _, c in ipairs(children) do
        if c:IsA("TextLabel") then table.insert(labels, c) end
    end
    if #labels > 8 then
        labels[1]:Destroy()
    end
end


-- Show results screen
local function showResults(data)
    -- Clear old entries
    for _, child in ipairs(resultsContent:GetChildren()) do
        if child:IsA("Frame") or child:IsA("TextLabel") then
            child:Destroy()
        end
    end

    -- Winner announcement
    local winnerText = data.seekersWin and "SEEKERS WIN!" or "CHAMELEONS SURVIVE!"
    local winnerColor = data.seekersWin and Color3.fromRGB(255, 80, 80) or Color3.fromRGB(80, 255, 80)
    resultsTitle.Text = winnerText
    resultsTitle.TextColor3 = winnerColor

    -- Leaderboard entries
    local leaderboard = data.leaderboard or {}
    for i, entry in ipairs(leaderboard) do
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 30)
        row.BackgroundColor3 = i % 2 == 0 and Color3.fromRGB(35, 35, 50) or Color3.fromRGB(45, 45, 60)
        row.BackgroundTransparency = 0.3
        row.Parent = resultsContent
        createCorner(row, 4)

        local rank = Instance.new("TextLabel")
        rank.Size = UDim2.new(0, 30, 1, 0)
        rank.BackgroundTransparency = 1
        rank.Text = "#" .. i
        rank.TextColor3 = i <= 3 and Color3.fromRGB(255, 220, 50) or Color3.fromRGB(200, 200, 200)
        rank.TextSize = 14
        rank.Font = Enum.Font.GothamBold
        rank.Parent = row

        local name = Instance.new("TextLabel")
        name.Size = UDim2.new(0.5, -30, 1, 0)
        name.Position = UDim2.new(0, 35, 0, 0)
        name.BackgroundTransparency = 1
        name.Text = entry.name or "Player"
        name.TextColor3 = Color3.fromRGB(255, 255, 255)
        name.TextSize = 14
        name.Font = Enum.Font.Gotham
        name.TextXAlignment = Enum.TextXAlignment.Left
        name.Parent = row

        local score = Instance.new("TextLabel")
        score.Size = UDim2.new(0.3, 0, 1, 0)
        score.Position = UDim2.new(0.7, 0, 0, 0)
        score.BackgroundTransparency = 1
        score.Text = tostring(entry.points or 0) .. " pts"
        score.TextColor3 = Color3.fromRGB(255, 200, 50)
        score.TextSize = 14
        score.Font = Enum.Font.GothamBold
        score.Parent = row
    end

    resultsGui.Enabled = true
end

local function hideResults()
    resultsGui.Enabled = false
end


-- Update controls text based on state and role
local function updateControls(state, role)
    controlsFrame.Visible = true

    if state == "PrepPhase" and role == "Hider" then
        controlsLabel.Text = "B=Brush  |  F=Full Body  |  1-9=Select Color  |  RMB=Sample Color  |  Walk to Color Pools"
    elseif state == "HidePhase" and role == "Hider" then
        controlsLabel.Text = "Q=Freeze  |  E/R=Change Pose  |  Find your hiding spot!"
    elseif state == "SeekPhase" and role == "Hider" then
        controlsLabel.Text = "Q=Freeze/Unfreeze  |  G=Taunt (risky!)  |  Stay hidden!"
    elseif state == "SeekPhase" and role == "Seeker" then
        controlsLabel.Text = "LMB=Tag (aim)  |  T=Tag (proximity)  |  X=Detection Pulse"
    else
        controlsFrame.Visible = false
    end
end

----------------------------------------------------------------------
-- EVENT HANDLERS
----------------------------------------------------------------------

-- Timer sync
TimerSync.OnClientEvent:Connect(function(seconds, label)
    if seconds < 0 then
        timerValue.Text = "--:--"
        timerLabel.Text = label or "WAITING"
    else
        local minutes = math.floor(seconds / 60)
        local secs = seconds % 60
        timerValue.Text = string.format("%d:%02d", minutes, secs)
        timerLabel.Text = string.upper(label or currentState)

        -- Flash red when time is low
        if seconds <= 10 and seconds > 0 then
            timerValue.TextColor3 = Color3.fromRGB(255, 80, 80)
        else
            timerValue.TextColor3 = Color3.fromRGB(255, 255, 255)
        end
    end
end)

-- Role assigned
RoleAssigned.OnClientEvent:Connect(function(role)
    myRole = role
    roleFrame.Visible = true

    if role == "Hider" then
        roleLabel.Text = "🦎 CHAMELEON (Hider)"
        roleLabel.TextColor3 = Color3.fromRGB(80, 255, 80)
        roleFrame.BackgroundColor3 = Color3.fromRGB(20, 50, 20)
    else
        roleLabel.Text = "👁 SEEKER"
        roleLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
        roleFrame.BackgroundColor3 = Color3.fromRGB(50, 20, 20)
    end

    -- Animate in
    roleFrame.Position = UDim2.new(0.5, -100, 0, -50)
    local tween = TweenService:Create(roleFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back), {
        Position = UDim2.new(0.5, -100, 0, 78),
    })
    tween:Play()
end)


-- Round state changed
RoundStateChanged.OnClientEvent:Connect(function(state, data)
    currentState = state
    hideResults()

    if state == "Lobby" then
        roleFrame.Visible = false
        paintFrame.Visible = false
        paletteFrame.Visible = false
        abilityFrame.Visible = false
        controlsFrame.Visible = false
        timerLabel.Text = "LOBBY"
        myRole = nil

    elseif state == "PrepPhase" then
        if myRole == "Hider" then
            paintFrame.Visible = true
            paletteFrame.Visible = true
            -- Build palette from available colors
            local palette = PaintSystem.GetPalette(GameConfig.DefaultMap)
            buildPalette(palette)
        end
        abilityFrame.Visible = false
        updateControls(state, myRole)

    elseif state == "HidePhase" then
        paintFrame.Visible = false
        paletteFrame.Visible = false
        updateControls(state, myRole)

    elseif state == "SeekPhase" then
        paintFrame.Visible = false
        paletteFrame.Visible = false
        if myRole == "Seeker" then
            abilityFrame.Visible = true
        end
        updateControls(state, myRole)

    elseif state == "Results" then
        abilityFrame.Visible = false
        controlsFrame.Visible = false
        if data then
            showResults(data)
        end
    end
end)

-- Score update
ScoreUpdate.OnClientEvent:Connect(function(data)
    if data then
        pointsLabel.Text = "Points: " .. (data.sessionPoints or 0)
        coinsLabel.Text = "Coins: " .. (data.totalCoins or 0)

        -- Flash score on update
        if data.pointsAwarded and data.pointsAwarded > 0 then
            local flash = TweenService:Create(pointsLabel, TweenInfo.new(0.2), {
                TextColor3 = Color3.fromRGB(100, 255, 100),
            })
            flash:Play()
            flash.Completed:Connect(function()
                TweenService:Create(pointsLabel, TweenInfo.new(0.5), {
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                }):Play()
            end)
        end
    end
end)

-- Player eliminated
PlayerEliminated.OnClientEvent:Connect(function(hiderName, seekerName)
    addFeedEntry(seekerName .. " found " .. hiderName .. "!", Color3.fromRGB(255, 100, 100))
end)

-- Paint charges update (from PaintClient bridge)
PaintCharacter.OnClientEvent:Connect(function(status, charges)
    if charges then
        paintChargesLabel.Text = "Paint: " .. charges .. "/" .. GameConfig.MaxPaintCharges
        if charges <= 2 then
            paintChargesLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        else
            paintChargesLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
        end
    end
end)

-- Game over
GameOver.OnClientEvent:Connect(function(data)
    if data then
        showResults(data)
    end
end)

print("[MainUI] HUD loaded successfully.")
