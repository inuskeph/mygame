--[[
    PaintClient.lua (LocalScript)
    Full color picker paint system for hiders.
    Features: Color wheel, eyedropper sampler, brush painting, paint all.
    Place in StarterPlayerScripts.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
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

----------------------------------------------------------------------
-- STATE
----------------------------------------------------------------------

local myRole = nil
local paintMode = false
local selectedColor = Color3.fromRGB(255, 255, 255)
local recentColors = {}
local eyedropperMode = false
local MAX_RECENT = 8
local hue, sat, val = 0, 1, 1 -- HSV values

----------------------------------------------------------------------
-- UI CREATION
----------------------------------------------------------------------

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PaintToolGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = false
screenGui.Enabled = false
screenGui.DisplayOrder = 70
screenGui.Parent = playerGui

-- Main paint panel (left side)
local paintPanel = Instance.new("Frame")
paintPanel.Name = "PaintPanel"
paintPanel.Size = UDim2.new(0, 280, 0, 420)
paintPanel.Position = UDim2.new(0, 15, 0.5, -210)
paintPanel.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
paintPanel.BackgroundTransparency = 0.05
paintPanel.Parent = screenGui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 14)
panelCorner.Parent = paintPanel

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = Color3.fromRGB(80, 150, 255)
panelStroke.Thickness = 2
panelStroke.Parent = paintPanel

-- Title
local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 35)
titleLabel.Position = UDim2.new(0, 0, 0, 5)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "PAINT TOOL"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 16
titleLabel.Font = Enum.Font.GothamBlack
titleLabel.Parent = paintPanel


----------------------------------------------------------------------
-- COLOR WHEEL (HSV circle)
----------------------------------------------------------------------

local wheelFrame = Instance.new("Frame")
wheelFrame.Name = "WheelFrame"
wheelFrame.Size = UDim2.new(0, 200, 0, 200)
wheelFrame.Position = UDim2.new(0.5, -100, 0, 40)
wheelFrame.BackgroundTransparency = 1
wheelFrame.Parent = paintPanel

-- Color wheel image (we'll create it with gradients)
local wheelImage = Instance.new("ImageLabel")
wheelImage.Name = "WheelImage"
wheelImage.Size = UDim2.new(1, 0, 1, 0)
wheelImage.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
wheelImage.Image = "rbxassetid://6020106367" -- Standard color wheel image
wheelImage.Parent = wheelFrame

local wheelCorner = Instance.new("UICorner")
wheelCorner.CornerRadius = UDim.new(0.5, 0)
wheelCorner.Parent = wheelImage

-- Selector dot on wheel
local wheelSelector = Instance.new("Frame")
wheelSelector.Name = "Selector"
wheelSelector.Size = UDim2.new(0, 14, 0, 14)
wheelSelector.Position = UDim2.new(0.5, -7, 0.5, -7)
wheelSelector.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
wheelSelector.Parent = wheelFrame

local selectorCorner = Instance.new("UICorner")
selectorCorner.CornerRadius = UDim.new(0.5, 0)
selectorCorner.Parent = wheelSelector

local selectorStroke = Instance.new("UIStroke")
selectorStroke.Color = Color3.fromRGB(0, 0, 0)
selectorStroke.Thickness = 2
selectorStroke.Parent = wheelSelector

----------------------------------------------------------------------
-- BRIGHTNESS SLIDER
----------------------------------------------------------------------

local brightnessFrame = Instance.new("Frame")
brightnessFrame.Name = "BrightnessFrame"
brightnessFrame.Size = UDim2.new(0, 240, 0, 25)
brightnessFrame.Position = UDim2.new(0.5, -120, 0, 248)
brightnessFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
brightnessFrame.Parent = paintPanel

local brightCorner = Instance.new("UICorner")
brightCorner.CornerRadius = UDim.new(0, 6)
brightCorner.Parent = brightnessFrame

-- Gradient for brightness
local brightGradient = Instance.new("UIGradient")
brightGradient.Color = ColorSequence.new(Color3.fromRGB(0, 0, 0), Color3.fromRGB(255, 255, 255))
brightGradient.Parent = brightnessFrame

-- Brightness slider handle
local brightSlider = Instance.new("Frame")
brightSlider.Name = "BrightSlider"
brightSlider.Size = UDim2.new(0, 8, 1, 4)
brightSlider.Position = UDim2.new(1, -8, 0, -2)
brightSlider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
brightSlider.Parent = brightnessFrame

local brightSliderCorner = Instance.new("UICorner")
brightSliderCorner.CornerRadius = UDim.new(0, 3)
brightSliderCorner.Parent = brightSlider

local brightSliderStroke = Instance.new("UIStroke")
brightSliderStroke.Color = Color3.fromRGB(0, 0, 0)
brightSliderStroke.Thickness = 2
brightSliderStroke.Parent = brightSlider

local brightnessLabel = Instance.new("TextLabel")
brightnessLabel.Size = UDim2.new(0, 240, 0, 18)
brightnessLabel.Position = UDim2.new(0.5, -120, 0, 275)
brightnessLabel.BackgroundTransparency = 1
brightnessLabel.Text = "Brightness"
brightnessLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
brightnessLabel.TextSize = 11
brightnessLabel.Font = Enum.Font.Gotham
brightnessLabel.Parent = paintPanel


----------------------------------------------------------------------
-- SELECTED COLOR PREVIEW + BUTTONS
----------------------------------------------------------------------

local previewFrame = Instance.new("Frame")
previewFrame.Name = "PreviewFrame"
previewFrame.Size = UDim2.new(0, 50, 0, 50)
previewFrame.Position = UDim2.new(0, 15, 0, 300)
previewFrame.BackgroundColor3 = selectedColor
previewFrame.Parent = paintPanel

local previewCorner = Instance.new("UICorner")
previewCorner.CornerRadius = UDim.new(0, 8)
previewCorner.Parent = previewFrame

local previewStroke = Instance.new("UIStroke")
previewStroke.Color = Color3.fromRGB(255, 255, 255)
previewStroke.Thickness = 2
previewStroke.Parent = previewFrame

-- Paint All button
local paintAllBtn = Instance.new("TextButton")
paintAllBtn.Name = "PaintAllBtn"
paintAllBtn.Size = UDim2.new(0, 90, 0, 35)
paintAllBtn.Position = UDim2.new(0, 75, 0, 300)
paintAllBtn.BackgroundColor3 = Color3.fromRGB(50, 120, 50)
paintAllBtn.Text = "PAINT ALL"
paintAllBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
paintAllBtn.TextSize = 12
paintAllBtn.Font = Enum.Font.GothamBold
paintAllBtn.Parent = paintPanel

local paintAllCorner = Instance.new("UICorner")
paintAllCorner.CornerRadius = UDim.new(0, 8)
paintAllCorner.Parent = paintAllBtn

-- Eyedropper button
local eyedropperBtn = Instance.new("TextButton")
eyedropperBtn.Name = "EyedropperBtn"
eyedropperBtn.Size = UDim2.new(0, 90, 0, 35)
eyedropperBtn.Position = UDim2.new(0, 175, 0, 300)
eyedropperBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 130)
eyedropperBtn.Text = "SAMPLE"
eyedropperBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
eyedropperBtn.TextSize = 12
eyedropperBtn.Font = Enum.Font.GothamBold
eyedropperBtn.Parent = paintPanel

local eyedropCorner = Instance.new("UICorner")
eyedropCorner.CornerRadius = UDim.new(0, 8)
eyedropCorner.Parent = eyedropperBtn

----------------------------------------------------------------------
-- RECENT COLORS
----------------------------------------------------------------------

local recentLabel = Instance.new("TextLabel")
recentLabel.Size = UDim2.new(0, 240, 0, 18)
recentLabel.Position = UDim2.new(0, 15, 0, 350)
recentLabel.BackgroundTransparency = 1
recentLabel.Text = "Recent Colors:"
recentLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
recentLabel.TextSize = 11
recentLabel.Font = Enum.Font.Gotham
recentLabel.TextXAlignment = Enum.TextXAlignment.Left
recentLabel.Parent = paintPanel

local recentFrame = Instance.new("Frame")
recentFrame.Name = "RecentFrame"
recentFrame.Size = UDim2.new(0, 250, 0, 30)
recentFrame.Position = UDim2.new(0, 15, 0, 370)
recentFrame.BackgroundTransparency = 1
recentFrame.Parent = paintPanel

local recentLayout = Instance.new("UIListLayout")
recentLayout.FillDirection = Enum.FillDirection.Horizontal
recentLayout.Padding = UDim.new(0, 5)
recentLayout.Parent = recentFrame

----------------------------------------------------------------------
-- INSTRUCTIONS (bottom)
----------------------------------------------------------------------

local instructLabel = Instance.new("TextLabel")
instructLabel.Size = UDim2.new(1, -10, 0, 20)
instructLabel.Position = UDim2.new(0, 5, 1, -25)
instructLabel.BackgroundTransparency = 1
instructLabel.Text = "Click body parts to paint | RMB = Sample color"
instructLabel.TextColor3 = Color3.fromRGB(140, 140, 160)
instructLabel.TextSize = 10
instructLabel.Font = Enum.Font.Gotham
instructLabel.TextWrapped = true
instructLabel.Parent = paintPanel


----------------------------------------------------------------------
-- COLOR LOGIC
----------------------------------------------------------------------

local function hsvToRgb(h, s, v)
    local r, g, b
    local i = math.floor(h * 6)
    local f = h * 6 - i
    local p = v * (1 - s)
    local q = v * (1 - f * s)
    local t = v * (1 - (1 - f) * s)
    i = i % 6
    if i == 0 then r, g, b = v, t, p
    elseif i == 1 then r, g, b = q, v, p
    elseif i == 2 then r, g, b = p, v, t
    elseif i == 3 then r, g, b = p, q, v
    elseif i == 4 then r, g, b = t, p, v
    elseif i == 5 then r, g, b = v, p, q
    end
    return Color3.new(r, g, b)
end

local function updateSelectedColor()
    selectedColor = hsvToRgb(hue, sat, val)
    previewFrame.BackgroundColor3 = selectedColor

    -- Update brightness gradient to show current hue
    local pureColor = hsvToRgb(hue, sat, 1)
    brightGradient.Color = ColorSequence.new(Color3.fromRGB(0, 0, 0), pureColor)
end

local function addRecentColor(color)
    -- Don't add duplicates
    for _, c in ipairs(recentColors) do
        if c.R == color.R and c.G == color.G and c.B == color.B then return end
    end

    table.insert(recentColors, 1, color)
    if #recentColors > MAX_RECENT then
        table.remove(recentColors, MAX_RECENT + 1)
    end

    -- Rebuild recent colors UI
    for _, child in ipairs(recentFrame:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end

    for i, c in ipairs(recentColors) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 28, 0, 28)
        btn.BackgroundColor3 = c
        btn.Text = ""
        btn.Parent = recentFrame

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = btn

        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(200, 200, 200)
        stroke.Thickness = 1
        stroke.Parent = btn

        btn.MouseButton1Click:Connect(function()
            selectedColor = c
            previewFrame.BackgroundColor3 = c
            -- Reverse HSV from color
            local r, g, b = c.R, c.G, c.B
            local maxC = math.max(r, g, b)
            local minC = math.min(r, g, b)
            val = maxC
            if maxC == 0 then sat = 0 else sat = (maxC - minC) / maxC end
            if maxC == minC then
                hue = 0
            elseif maxC == r then
                hue = ((g - b) / (maxC - minC)) / 6
                if hue < 0 then hue += 1 end
            elseif maxC == g then
                hue = ((b - r) / (maxC - minC) + 2) / 6
            else
                hue = ((r - g) / (maxC - minC) + 4) / 6
            end
        end)
    end
end


----------------------------------------------------------------------
-- COLOR WHEEL INTERACTION
----------------------------------------------------------------------

local draggingWheel = false
local draggingBrightness = false

local function onWheelInput(input)
    local wheelCenter = wheelImage.AbsolutePosition + wheelImage.AbsoluteSize / 2
    local radius = wheelImage.AbsoluteSize.X / 2

    local dx = input.Position.X - wheelCenter.X
    local dy = input.Position.Y - wheelCenter.Y
    local dist = math.sqrt(dx * dx + dy * dy)

    if dist <= radius then
        -- Calculate hue from angle
        local angle = math.atan2(dy, dx)
        hue = (angle / (2 * math.pi) + 0.5) % 1

        -- Calculate saturation from distance to center
        sat = math.clamp(dist / radius, 0, 1)

        -- Move selector
        local selectorX = 0.5 + (dx / (radius * 2))
        local selectorY = 0.5 + (dy / (radius * 2))
        wheelSelector.Position = UDim2.new(selectorX, -7, selectorY, -7)

        updateSelectedColor()
    end
end

wheelImage.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingWheel = true
        onWheelInput(input)
    end
end)

wheelImage.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingWheel = false
    end
end)

-- Brightness slider interaction
brightnessFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingBrightness = true
        local relX = math.clamp((input.Position.X - brightnessFrame.AbsolutePosition.X) / brightnessFrame.AbsoluteSize.X, 0, 1)
        val = relX
        brightSlider.Position = UDim2.new(relX, -4, 0, -2)
        updateSelectedColor()
    end
end)

brightnessFrame.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingBrightness = false
    end
end)

-- Handle dragging
UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        if draggingWheel then
            onWheelInput(input)
        end
        if draggingBrightness then
            local relX = math.clamp((input.Position.X - brightnessFrame.AbsolutePosition.X) / brightnessFrame.AbsoluteSize.X, 0, 1)
            val = relX
            brightSlider.Position = UDim2.new(relX, -4, 0, -2)
            updateSelectedColor()
        end
    end
end)


----------------------------------------------------------------------
-- PAINTING LOGIC
----------------------------------------------------------------------

local function paintBodyPart(partName)
    if not selectedColor then return end
    PaintCharacter:FireServer(partName, selectedColor)
    addRecentColor(selectedColor)
end

local function paintFullBody()
    if not selectedColor then return end
    if not player.Character then return end

    local paintableParts = {
        "Head","UpperTorso","LowerTorso","LeftUpperArm","LeftLowerArm","LeftHand",
        "RightUpperArm","RightLowerArm","RightHand","LeftUpperLeg","LeftLowerLeg",
        "LeftFoot","RightUpperLeg","RightLowerLeg","RightFoot",
        "Torso","Left Arm","Right Arm","Left Leg","Right Leg",
    }

    for _, partName in ipairs(paintableParts) do
        if player.Character:FindFirstChild(partName) then
            PaintCharacter:FireServer(partName, selectedColor)
            task.wait(0.02)
        end
    end
    addRecentColor(selectedColor)
end

local function sampleColorFromWorld()
    local mousePos = UserInputService:GetMouseLocation()
    local ray = camera:ViewportPointToRay(mousePos.X, mousePos.Y)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = {player.Character}

    local result = Workspace:Raycast(ray.Origin, ray.Direction * 500, raycastParams)
    if result and result.Instance and result.Instance:IsA("BasePart") then
        local color = result.Instance.Color
        selectedColor = color
        previewFrame.BackgroundColor3 = color
        addRecentColor(color)

        -- Update HSV from sampled color
        local r, g, b = color.R, color.G, color.B
        local maxC = math.max(r, g, b)
        local minC = math.min(r, g, b)
        val = maxC
        if maxC == 0 then sat = 0 else sat = (maxC - minC) / maxC end
        if maxC == minC then
            hue = 0
        elseif maxC == r then
            hue = ((g - b) / (maxC - minC)) / 6
            if hue < 0 then hue += 1 end
        elseif maxC == g then
            hue = ((b - r) / (maxC - minC) + 2) / 6
        else
            hue = ((r - g) / (maxC - minC) + 4) / 6
        end

        print("[Paint] Sampled color:", math.floor(r*255), math.floor(g*255), math.floor(b*255))
        eyedropperMode = false
        eyedropperBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 130)
        return true
    end
    return false
end

----------------------------------------------------------------------
-- BUTTON HANDLERS
----------------------------------------------------------------------

paintAllBtn.MouseButton1Click:Connect(function()
    if not paintMode then return end
    paintFullBody()

    -- Flash button
    paintAllBtn.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
    task.delay(0.3, function()
        paintAllBtn.BackgroundColor3 = Color3.fromRGB(50, 120, 50)
    end)
end)

eyedropperBtn.MouseButton1Click:Connect(function()
    if not paintMode then return end
    eyedropperMode = not eyedropperMode
    if eyedropperMode then
        eyedropperBtn.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
        eyedropperBtn.Text = "SAMPLING..."
    else
        eyedropperBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 130)
        eyedropperBtn.Text = "SAMPLE"
    end
end)


----------------------------------------------------------------------
-- INPUT HANDLING
----------------------------------------------------------------------

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if not paintMode then return end

    -- Left click: paint body part OR sample color (if eyedropper active)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if eyedropperMode then
            sampleColorFromWorld()
        else
            -- Check if clicking on own character
            local target = mouse.Target
            if target and player.Character and target:IsDescendantOf(player.Character) then
                paintBodyPart(target.Name)
            end
        end
    end

    -- Right click: always sample color from world
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        sampleColorFromWorld()
    end

    -- Keyboard shortcuts
    if input.UserInputType == Enum.UserInputType.Keyboard then
        -- F = Paint full body
        if input.KeyCode == Enum.KeyCode.F then
            paintFullBody()
        end

        -- E = Toggle eyedropper
        if input.KeyCode == Enum.KeyCode.E then
            eyedropperMode = not eyedropperMode
            if eyedropperMode then
                eyedropperBtn.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
                eyedropperBtn.Text = "SAMPLING..."
            else
                eyedropperBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 130)
                eyedropperBtn.Text = "SAMPLE"
            end
        end
    end
end)

----------------------------------------------------------------------
-- SERVER RESPONSES
----------------------------------------------------------------------

PaintCharacter.OnClientEvent:Connect(function(status, charges)
    if status == "SUCCESS" then
        -- Brief green flash on preview
        local original = previewFrame.BackgroundColor3
        previewStroke.Color = Color3.fromRGB(0, 255, 0)
        task.delay(0.2, function()
            previewStroke.Color = Color3.fromRGB(255, 255, 255)
        end)
    elseif status == "NO_CHARGES" then
        warn("[Paint] Out of paint charges!")
    elseif status == "FAILED" then
        -- Red flash
        previewStroke.Color = Color3.fromRGB(255, 0, 0)
        task.delay(0.3, function()
            previewStroke.Color = Color3.fromRGB(255, 255, 255)
        end)
    end
end)

----------------------------------------------------------------------
-- ROUND STATE HANDLING
----------------------------------------------------------------------

RoleAssigned.OnClientEvent:Connect(function(role)
    myRole = role
end)

RoundStateChanged.OnClientEvent:Connect(function(state, data)
    if state == "PrepPhase" and myRole == "Hider" then
        paintMode = true
        screenGui.Enabled = true
        -- Animate panel in
        paintPanel.Position = UDim2.new(-1, 0, 0.5, -210)
        TweenService:Create(paintPanel, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Position = UDim2.new(0, 15, 0.5, -210)
        }):Play()
        print("[Paint] Paint tool opened! Click body parts to paint. RMB or E to sample colors.")

    elseif state == "HidePhase" or state == "SeekPhase" or state == "Lobby" or state == "Results" then
        paintMode = false
        eyedropperMode = false
        if screenGui.Enabled then
            TweenService:Create(paintPanel, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
                Position = UDim2.new(-1, 0, 0.5, -210)
            }):Play()
            task.delay(0.4, function()
                screenGui.Enabled = false
            end)
        end
        if state == "Lobby" or state == "Results" then
            myRole = nil
        end
    end
end)

print("[PaintClient] Color wheel paint system loaded!")
