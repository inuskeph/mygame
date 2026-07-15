--[[
    PaintClient.lua (LocalScript)
    Color wheel paint system for hiders.
    Place in StarterPlayerScripts.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local GameConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameConfig"))
local Events = ReplicatedStorage:WaitForChild("Events")
local PaintCharacter = Events:WaitForChild("PaintCharacter")
local RoundStateChanged = Events:WaitForChild("RoundStateChanged")
local RoleAssigned = Events:WaitForChild("RoleAssigned")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local mouse = player:GetMouse()
local camera = Workspace.CurrentCamera

-- State
local myRole = nil
local paintMode = false
local selectedColor = Color3.fromRGB(255, 255, 255)
local recentColors = {}
local eyedropperMode = false
local MAX_RECENT = 8
local hue, sat, val = 0, 0, 1
local draggingWheel = false
local draggingBrightness = false

-- HSV to RGB
local function hsvToRgb(h, s, v)
    local r, g, b
    local i = math.floor(h * 6)
    local f = h * 6 - i
    local p = v * (1 - s)
    local q = v * (1 - f * s)
    local t = v * (1 - (1 - f) * s)
    i = i % 6
    if i == 0 then r,g,b = v,t,p
    elseif i == 1 then r,g,b = q,v,p
    elseif i == 2 then r,g,b = p,v,t
    elseif i == 3 then r,g,b = p,q,v
    elseif i == 4 then r,g,b = t,p,v
    elseif i == 5 then r,g,b = v,p,q end
    return Color3.new(r, g, b)
end


-- UI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PaintToolGui"
screenGui.ResetOnSpawn = false
screenGui.Enabled = false
screenGui.DisplayOrder = 70
screenGui.Parent = playerGui

local paintPanel = Instance.new("Frame")
paintPanel.Size = UDim2.new(0, 260, 0, 380)
paintPanel.Position = UDim2.new(0, 15, 0.5, -190)
paintPanel.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
paintPanel.BackgroundTransparency = 0.05
paintPanel.Parent = screenGui
Instance.new("UICorner", paintPanel).CornerRadius = UDim.new(0, 14)
local ps = Instance.new("UIStroke", paintPanel)
ps.Color = Color3.fromRGB(80, 150, 255)
ps.Thickness = 2

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 28)
title.BackgroundTransparency = 1
title.Text = "PAINT TOOL"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 14
title.Font = Enum.Font.GothamBlack
title.Parent = paintPanel

-- Color wheel
local wheelFrame = Instance.new("Frame")
wheelFrame.Size = UDim2.new(0, 170, 0, 170)
wheelFrame.Position = UDim2.new(0.5, -85, 0, 32)
wheelFrame.BackgroundTransparency = 1
wheelFrame.Parent = paintPanel

local wheelImage = Instance.new("ImageLabel")
wheelImage.Size = UDim2.new(1, 0, 1, 0)
wheelImage.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
wheelImage.Image = "rbxassetid://6020106367"
wheelImage.Parent = wheelFrame
Instance.new("UICorner", wheelImage).CornerRadius = UDim.new(0.5, 0)

local wheelSelector = Instance.new("Frame")
wheelSelector.Size = UDim2.new(0, 12, 0, 12)
wheelSelector.Position = UDim2.new(0.5, -6, 0.5, -6)
wheelSelector.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
wheelSelector.Parent = wheelFrame
Instance.new("UICorner", wheelSelector).CornerRadius = UDim.new(0.5, 0)
local ss = Instance.new("UIStroke", wheelSelector)
ss.Color = Color3.fromRGB(0, 0, 0)
ss.Thickness = 2


-- Brightness slider
local brightFrame = Instance.new("Frame")
brightFrame.Size = UDim2.new(0, 220, 0, 18)
brightFrame.Position = UDim2.new(0.5, -110, 0, 210)
brightFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
brightFrame.Parent = paintPanel
Instance.new("UICorner", brightFrame).CornerRadius = UDim.new(0, 6)
local brightGradient = Instance.new("UIGradient", brightFrame)
brightGradient.Color = ColorSequence.new(Color3.new(0,0,0), Color3.new(1,1,1))

local brightSlider = Instance.new("Frame")
brightSlider.Size = UDim2.new(0, 6, 1, 4)
brightSlider.Position = UDim2.new(1, -6, 0, -2)
brightSlider.BackgroundColor3 = Color3.new(1, 1, 1)
brightSlider.Parent = brightFrame
Instance.new("UICorner", brightSlider).CornerRadius = UDim.new(0, 3)

-- Preview + Buttons
local previewFrame = Instance.new("Frame")
previewFrame.Size = UDim2.new(0, 40, 0, 40)
previewFrame.Position = UDim2.new(0, 15, 0, 240)
previewFrame.BackgroundColor3 = selectedColor
previewFrame.Parent = paintPanel
Instance.new("UICorner", previewFrame).CornerRadius = UDim.new(0, 8)
local pvStroke = Instance.new("UIStroke", previewFrame)
pvStroke.Color = Color3.new(1, 1, 1)
pvStroke.Thickness = 2

local paintAllBtn = Instance.new("TextButton")
paintAllBtn.Size = UDim2.new(0, 75, 0, 30)
paintAllBtn.Position = UDim2.new(0, 65, 0, 245)
paintAllBtn.BackgroundColor3 = Color3.fromRGB(50, 130, 50)
paintAllBtn.Text = "PAINT ALL"
paintAllBtn.TextColor3 = Color3.new(1, 1, 1)
paintAllBtn.TextSize = 11
paintAllBtn.Font = Enum.Font.GothamBold
paintAllBtn.Parent = paintPanel
Instance.new("UICorner", paintAllBtn).CornerRadius = UDim.new(0, 6)

local eyedropBtn = Instance.new("TextButton")
eyedropBtn.Size = UDim2.new(0, 75, 0, 30)
eyedropBtn.Position = UDim2.new(0, 150, 0, 245)
eyedropBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 130)
eyedropBtn.Text = "SAMPLE"
eyedropBtn.TextColor3 = Color3.new(1, 1, 1)
eyedropBtn.TextSize = 11
eyedropBtn.Font = Enum.Font.GothamBold
eyedropBtn.Parent = paintPanel
Instance.new("UICorner", eyedropBtn).CornerRadius = UDim.new(0, 6)

-- Recent colors
local recentFrame = Instance.new("Frame")
recentFrame.Size = UDim2.new(0, 230, 0, 28)
recentFrame.Position = UDim2.new(0, 15, 0, 290)
recentFrame.BackgroundTransparency = 1
recentFrame.Parent = paintPanel
local rl = Instance.new("UIListLayout", recentFrame)
rl.FillDirection = Enum.FillDirection.Horizontal
rl.Padding = UDim.new(0, 4)

local instrLabel = Instance.new("TextLabel")
instrLabel.Size = UDim2.new(1, -10, 0, 25)
instrLabel.Position = UDim2.new(0, 5, 1, -30)
instrLabel.BackgroundTransparency = 1
instrLabel.Text = "LMB=Paint part | RMB/E=Sample | F=All"
instrLabel.TextColor3 = Color3.fromRGB(120, 120, 140)
instrLabel.TextSize = 9
instrLabel.Font = Enum.Font.Gotham
instrLabel.Parent = paintPanel


----------------------------------------------------------------------
-- FUNCTIONS
----------------------------------------------------------------------

local function updateSelectedColor()
    selectedColor = hsvToRgb(hue, sat, val)
    previewFrame.BackgroundColor3 = selectedColor
    brightGradient.Color = ColorSequence.new(Color3.new(0,0,0), hsvToRgb(hue, sat, 1))
end

local function addRecentColor(color)
    for _, c in ipairs(recentColors) do
        if math.abs(c.R-color.R)<0.02 and math.abs(c.G-color.G)<0.02 and math.abs(c.B-color.B)<0.02 then return end
    end
    table.insert(recentColors, 1, color)
    if #recentColors > MAX_RECENT then table.remove(recentColors) end
    for _, ch in ipairs(recentFrame:GetChildren()) do if ch:IsA("TextButton") then ch:Destroy() end end
    for _, c in ipairs(recentColors) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 24, 0, 24); btn.BackgroundColor3 = c; btn.Text = ""
        btn.Parent = recentFrame
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)
        btn.MouseButton1Click:Connect(function()
            selectedColor = c; previewFrame.BackgroundColor3 = c
        end)
    end
end

local function paintBodyPart(partName)
    PaintCharacter:FireServer(partName, selectedColor)
    addRecentColor(selectedColor)
end

local function paintFullBody()
    if not player.Character then return end
    local parts = {"Head","UpperTorso","LowerTorso","LeftUpperArm","LeftLowerArm","LeftHand","RightUpperArm","RightLowerArm","RightHand","LeftUpperLeg","LeftLowerLeg","LeftFoot","RightUpperLeg","RightLowerLeg","RightFoot","Torso","Left Arm","Right Arm","Left Leg","Right Leg"}
    for _, p in ipairs(parts) do
        if player.Character:FindFirstChild(p) then
            PaintCharacter:FireServer(p, selectedColor)
            task.wait(0.02)
        end
    end
    addRecentColor(selectedColor)
end

local function sampleColorFromWorld()
    local pos = UserInputService:GetMouseLocation()
    local ray = camera:ViewportPointToRay(pos.X, pos.Y)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {player.Character}
    local result = Workspace:Raycast(ray.Origin, ray.Direction * 500, params)
    if result and result.Instance and result.Instance:IsA("BasePart") then
        selectedColor = result.Instance.Color
        previewFrame.BackgroundColor3 = selectedColor
        addRecentColor(selectedColor)
        eyedropperMode = false
        eyedropBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 130)
        eyedropBtn.Text = "SAMPLE"
    end
end


----------------------------------------------------------------------
-- WHEEL + SLIDER INTERACTION
----------------------------------------------------------------------

wheelImage.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then draggingWheel = true end
end)
wheelImage.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then draggingWheel = false end
end)
brightFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then draggingBrightness = true end
end)
brightFrame.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then draggingBrightness = false end
end)

UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
    if draggingWheel then
        local center = wheelImage.AbsolutePosition + wheelImage.AbsoluteSize / 2
        local radius = wheelImage.AbsoluteSize.X / 2
        local dx = input.Position.X - center.X
        local dy = input.Position.Y - center.Y
        local dist = math.sqrt(dx*dx + dy*dy)
        if dist <= radius then
            hue = (math.atan2(dy, dx) / (2 * math.pi) + 0.5) % 1
            sat = math.clamp(dist / radius, 0, 1)
            wheelSelector.Position = UDim2.new(0.5 + dx/(radius*2), -6, 0.5 + dy/(radius*2), -6)
            updateSelectedColor()
        end
    end
    if draggingBrightness then
        local relX = math.clamp((input.Position.X - brightFrame.AbsolutePosition.X) / brightFrame.AbsoluteSize.X, 0, 1)
        val = relX
        brightSlider.Position = UDim2.new(relX, -3, 0, -2)
        updateSelectedColor()
    end
end)

-- Also handle single click on wheel
wheelImage.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        local center = wheelImage.AbsolutePosition + wheelImage.AbsoluteSize / 2
        local radius = wheelImage.AbsoluteSize.X / 2
        local dx = input.Position.X - center.X
        local dy = input.Position.Y - center.Y
        local dist = math.sqrt(dx*dx + dy*dy)
        if dist <= radius then
            hue = (math.atan2(dy, dx) / (2 * math.pi) + 0.5) % 1
            sat = math.clamp(dist / radius, 0, 1)
            wheelSelector.Position = UDim2.new(0.5 + dx/(radius*2), -6, 0.5 + dy/(radius*2), -6)
            updateSelectedColor()
        end
    end
end)
brightFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        local relX = math.clamp((input.Position.X - brightFrame.AbsolutePosition.X) / brightFrame.AbsoluteSize.X, 0, 1)
        val = relX
        brightSlider.Position = UDim2.new(relX, -3, 0, -2)
        updateSelectedColor()
    end
end)

----------------------------------------------------------------------
-- BUTTON CLICKS
----------------------------------------------------------------------

paintAllBtn.MouseButton1Click:Connect(paintFullBody)
eyedropBtn.MouseButton1Click:Connect(function()
    eyedropperMode = not eyedropperMode
    eyedropBtn.BackgroundColor3 = eyedropperMode and Color3.fromRGB(100,255,100) or Color3.fromRGB(80,80,130)
    eyedropBtn.Text = eyedropperMode and "PICKING..." or "SAMPLE"
end)


----------------------------------------------------------------------
-- MAIN INPUT
----------------------------------------------------------------------

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if not paintMode then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if eyedropperMode then sampleColorFromWorld()
        else
            local target = mouse.Target
            if target and player.Character and target:IsDescendantOf(player.Character) then
                paintBodyPart(target.Name)
            end
        end
    elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
        sampleColorFromWorld()
    elseif input.UserInputType == Enum.UserInputType.Keyboard then
        if input.KeyCode == Enum.KeyCode.F then paintFullBody() end
        if input.KeyCode == Enum.KeyCode.E then
            eyedropperMode = not eyedropperMode
            eyedropBtn.BackgroundColor3 = eyedropperMode and Color3.fromRGB(100,255,100) or Color3.fromRGB(80,80,130)
            eyedropBtn.Text = eyedropperMode and "PICKING..." or "SAMPLE"
        end
    end
end)

----------------------------------------------------------------------
-- ROUND STATE
----------------------------------------------------------------------

RoleAssigned.OnClientEvent:Connect(function(role) myRole = role end)

RoundStateChanged.OnClientEvent:Connect(function(state)
    if state == "PrepPhase" and myRole == "Hider" then
        paintMode = true
        screenGui.Enabled = true
        paintPanel.Position = UDim2.new(-1, 0, 0.5, -190)
        TweenService:Create(paintPanel, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Position = UDim2.new(0, 15, 0.5, -190)
        }):Play()
    else
        paintMode = false
        eyedropperMode = false
        if screenGui.Enabled then
            TweenService:Create(paintPanel, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
                Position = UDim2.new(-1, 0, 0.5, -190)
            }):Play()
            task.delay(0.4, function() screenGui.Enabled = false end)
        end
        if state == "Lobby" or state == "Results" then myRole = nil end
    end
end)

PaintCharacter.OnClientEvent:Connect(function(status)
    if status == "SUCCESS" then
        pvStroke.Color = Color3.fromRGB(0, 255, 0)
        task.delay(0.2, function() pvStroke.Color = Color3.new(1,1,1) end)
    end
end)

print("[PaintClient] Color wheel paint system loaded!")
