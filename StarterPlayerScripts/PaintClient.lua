--[[
    PaintClient.lua (LocalScript)
    Meccha Chameleon style paint system:
    - Walk into color pools on the ground to pick up color
    - Body part selection buttons (Head, Torso, Arms, Legs)
    - Paint All / Freeze / Pose buttons at bottom
    - Current color indicator
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
local FreezeCharacter = Events:WaitForChild("FreezeCharacter")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local mouse = player:GetMouse()

-- State
local myRole = nil
local paintMode = false
local selectedColor = Color3.fromRGB(255, 255, 255)
local isFrozen = false

----------------------------------------------------------------------
-- UI CREATION
----------------------------------------------------------------------

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PaintUI"
screenGui.ResetOnSpawn = false
screenGui.Enabled = false
screenGui.DisplayOrder = 70
screenGui.Parent = playerGui

----------------------------------------------------------------------
-- CURRENT COLOR INDICATOR (top-left during paint)
----------------------------------------------------------------------

local colorIndicator = Instance.new("Frame")
colorIndicator.Name = "ColorIndicator"
colorIndicator.Size = UDim2.new(0, 70, 0, 70)
colorIndicator.Position = UDim2.new(0, 20, 0, 80)
colorIndicator.BackgroundColor3 = selectedColor
colorIndicator.Parent = screenGui
Instance.new("UICorner", colorIndicator).CornerRadius = UDim.new(0.5, 0)
local ciStroke = Instance.new("UIStroke", colorIndicator)
ciStroke.Color = Color3.fromRGB(255, 255, 255)
ciStroke.Thickness = 3

local colorLabel = Instance.new("TextLabel")
colorLabel.Size = UDim2.new(0, 70, 0, 20)
colorLabel.Position = UDim2.new(0, 20, 0, 155)
colorLabel.BackgroundTransparency = 1
colorLabel.Text = "MY COLOR"
colorLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
colorLabel.TextSize = 10
colorLabel.Font = Enum.Font.GothamBold
colorLabel.Parent = screenGui

----------------------------------------------------------------------
-- BODY PART SELECTION (right side panel)
----------------------------------------------------------------------

local bodyPanel = Instance.new("Frame")
bodyPanel.Name = "BodyPanel"
bodyPanel.Size = UDim2.new(0, 160, 0, 320)
bodyPanel.Position = UDim2.new(1, -175, 0.5, -160)
bodyPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
bodyPanel.BackgroundTransparency = 0.1
bodyPanel.Parent = screenGui
Instance.new("UICorner", bodyPanel).CornerRadius = UDim.new(0, 12)
local bpStroke = Instance.new("UIStroke", bodyPanel)
bpStroke.Color = Color3.fromRGB(60, 120, 200)
bpStroke.Thickness = 2

local bodyTitle = Instance.new("TextLabel")
bodyTitle.Size = UDim2.new(1, 0, 0, 25)
bodyTitle.Position = UDim2.new(0, 0, 0, 5)
bodyTitle.BackgroundTransparency = 1
bodyTitle.Text = "PAINT BODY"
bodyTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
bodyTitle.TextSize = 12
bodyTitle.Font = Enum.Font.GothamBlack
bodyTitle.Parent = bodyPanel

-- Body part buttons
local bodyParts = {
    {name = "Head", parts = {"Head"}, y = 35},
    {name = "Torso", parts = {"UpperTorso", "LowerTorso", "Torso"}, y = 75},
    {name = "Left Arm", parts = {"LeftUpperArm", "LeftLowerArm", "LeftHand", "Left Arm"}, y = 115},
    {name = "Right Arm", parts = {"RightUpperArm", "RightLowerArm", "RightHand", "Right Arm"}, y = 155},
    {name = "Left Leg", parts = {"LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "Left Leg"}, y = 195},
    {name = "Right Leg", parts = {"RightUpperLeg", "RightLowerLeg", "RightFoot", "Right Leg"}, y = 235},
    {name = "ALL", parts = {"Head","UpperTorso","LowerTorso","LeftUpperArm","LeftLowerArm","LeftHand","RightUpperArm","RightLowerArm","RightHand","LeftUpperLeg","LeftLowerLeg","LeftFoot","RightUpperLeg","RightLowerLeg","RightFoot","Torso","Left Arm","Right Arm","Left Leg","Right Leg"}, y = 278},
}

for _, bp in ipairs(bodyParts) do
    local btn = Instance.new("TextButton")
    btn.Name = "Btn_" .. bp.name
    btn.Size = UDim2.new(0, 135, 0, 32)
    btn.Position = UDim2.new(0.5, -67, 0, bp.y)
    btn.BackgroundColor3 = bp.name == "ALL" and Color3.fromRGB(50, 130, 50) or Color3.fromRGB(40, 40, 60)
    btn.Text = bp.name
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 12
    btn.Font = Enum.Font.GothamBold
    btn.Parent = bodyPanel
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

    btn.MouseButton1Click:Connect(function()
        if not paintMode then return end
        if not player.Character then return end
        for _, partName in ipairs(bp.parts) do
            if player.Character:FindFirstChild(partName) then
                PaintCharacter:FireServer(partName, selectedColor)
                task.wait(0.02)
            end
        end
        -- Flash button green
        btn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
        task.delay(0.2, function()
            btn.BackgroundColor3 = bp.name == "ALL" and Color3.fromRGB(50, 130, 50) or Color3.fromRGB(40, 40, 60)
        end)
    end)

    -- Hover
    btn.MouseEnter:Connect(function()
        if bp.name ~= "ALL" then
            btn.BackgroundColor3 = Color3.fromRGB(60, 60, 90)
        end
    end)
    btn.MouseLeave:Connect(function()
        btn.BackgroundColor3 = bp.name == "ALL" and Color3.fromRGB(50, 130, 50) or Color3.fromRGB(40, 40, 60)
    end)
end


----------------------------------------------------------------------
-- BOTTOM ACTION BUTTONS (Freeze, Pose, Sample)
----------------------------------------------------------------------

local bottomBar = Instance.new("Frame")
bottomBar.Name = "BottomBar"
bottomBar.Size = UDim2.new(0, 400, 0, 55)
bottomBar.Position = UDim2.new(0.5, -200, 1, -70)
bottomBar.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
bottomBar.BackgroundTransparency = 0.15
bottomBar.Parent = screenGui
Instance.new("UICorner", bottomBar).CornerRadius = UDim.new(0, 12)

local bottomLayout = Instance.new("UIListLayout", bottomBar)
bottomLayout.FillDirection = Enum.FillDirection.Horizontal
bottomLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
bottomLayout.VerticalAlignment = Enum.VerticalAlignment.Center
bottomLayout.Padding = UDim.new(0, 10)

local function makeBottomBtn(text, color, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 110, 0, 40)
    btn.BackgroundColor3 = color
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 13
    btn.Font = Enum.Font.GothamBold
    btn.Parent = bottomBar
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- Freeze button
local freezeBtn = makeBottomBtn("FREEZE [Q]", Color3.fromRGB(50, 100, 180), function()
    if isFrozen then
        FreezeCharacter:FireServer("UNFREEZE")
        isFrozen = false
        freezeBtn.Text = "FREEZE [Q]"
        freezeBtn.BackgroundColor3 = Color3.fromRGB(50, 100, 180)
    else
        FreezeCharacter:FireServer("FREEZE", "Standing")
        isFrozen = true
        freezeBtn.Text = "UNFREEZE [Q]"
        freezeBtn.BackgroundColor3 = Color3.fromRGB(180, 80, 50)
    end
end)

-- Sample color button
local sampleBtn = makeBottomBtn("SAMPLE [E]", Color3.fromRGB(80, 80, 130), function()
    -- Next click will sample
    eyedropActive = true
    sampleBtn.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
    sampleBtn.Text = "CLICK MAP..."
end)

-- Pose button
local poseBtn = makeBottomBtn("POSE [R]", Color3.fromRGB(100, 60, 130), function()
    FreezeCharacter:FireServer("POSE", "TShaped")
end)

local eyedropActive = false

----------------------------------------------------------------------
-- COLOR POOL DETECTION (walk into pools on ground)
----------------------------------------------------------------------

local function onColorPoolTouched(part)
    if not paintMode then return end
    local poolColor = part:GetAttribute("PaintColor")
    if poolColor then
        selectedColor = poolColor
        colorIndicator.BackgroundColor3 = selectedColor
        -- Visual feedback
        ciStroke.Color = Color3.fromRGB(0, 255, 0)
        task.delay(0.3, function()
            ciStroke.Color = Color3.fromRGB(255, 255, 255)
        end)
    end
end

local function setupTouchDetection()
    local character = player.Character or player.CharacterAdded:Wait()
    local rootPart = character:WaitForChild("HumanoidRootPart")
    rootPart.Touched:Connect(function(otherPart)
        if otherPart:GetAttribute("IsColorPool") then
            onColorPoolTouched(otherPart)
        end
    end)
end

player.CharacterAdded:Connect(setupTouchDetection)
if player.Character then setupTouchDetection() end

----------------------------------------------------------------------
-- SAMPLE FROM WORLD (eyedropper)
----------------------------------------------------------------------

local function sampleColor()
    local pos = UserInputService:GetMouseLocation()
    local ray = Workspace.CurrentCamera:ViewportPointToRay(pos.X, pos.Y)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {player.Character}
    local result = Workspace:Raycast(ray.Origin, ray.Direction * 500, params)
    if result and result.Instance and result.Instance:IsA("BasePart") then
        selectedColor = result.Instance.Color
        colorIndicator.BackgroundColor3 = selectedColor
        eyedropActive = false
        sampleBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 130)
        sampleBtn.Text = "SAMPLE [E]"
    end
end


----------------------------------------------------------------------
-- INPUT
----------------------------------------------------------------------

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if not paintMode then return end

    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if eyedropActive then
            sampleColor()
        else
            -- Click on own body part to paint it
            local target = mouse.Target
            if target and player.Character and target:IsDescendantOf(player.Character) then
                PaintCharacter:FireServer(target.Name, selectedColor)
            end
        end
    end

    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        sampleColor()
    end

    if input.UserInputType == Enum.UserInputType.Keyboard then
        if input.KeyCode == Enum.KeyCode.F then
            -- Paint all
            if player.Character then
                local allParts = {"Head","UpperTorso","LowerTorso","LeftUpperArm","LeftLowerArm","LeftHand","RightUpperArm","RightLowerArm","RightHand","LeftUpperLeg","LeftLowerLeg","LeftFoot","RightUpperLeg","RightLowerLeg","RightFoot","Torso","Left Arm","Right Arm","Left Leg","Right Leg"}
                for _, p in ipairs(allParts) do
                    if player.Character:FindFirstChild(p) then
                        PaintCharacter:FireServer(p, selectedColor)
                        task.wait(0.02)
                    end
                end
            end
        end
        if input.KeyCode == Enum.KeyCode.E then
            eyedropActive = true
            sampleBtn.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
            sampleBtn.Text = "CLICK MAP..."
        end
        if input.KeyCode == Enum.KeyCode.Q then
            freezeBtn.MouseButton1Click:Fire()
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
        isFrozen = false
        screenGui.Enabled = true
        -- Slide in body panel
        bodyPanel.Position = UDim2.new(1, 50, 0.5, -160)
        TweenService:Create(bodyPanel, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Position = UDim2.new(1, -175, 0.5, -160)
        }):Play()
        bottomBar.Position = UDim2.new(0.5, -200, 1, 60)
        TweenService:Create(bottomBar, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Position = UDim2.new(0.5, -200, 1, -70)
        }):Play()

    elseif state == "HidePhase" and myRole == "Hider" then
        -- Keep freeze/pose buttons but hide paint stuff
        paintMode = false
        bodyPanel.Visible = false

    elseif state == "SeekPhase" or state == "Lobby" or state == "Results" then
        paintMode = false
        eyedropActive = false
        isFrozen = false
        if screenGui.Enabled then
            screenGui.Enabled = false
        end
        bodyPanel.Visible = true
        if state == "Lobby" or state == "Results" then myRole = nil end
    end
end)

-- Server paint response
PaintCharacter.OnClientEvent:Connect(function(status)
    if status == "SUCCESS" then
        ciStroke.Color = Color3.fromRGB(0, 255, 0)
        task.delay(0.15, function() ciStroke.Color = Color3.fromRGB(255, 255, 255) end)
    end
end)

-- Freeze response
FreezeCharacter.OnClientEvent:Connect(function(status)
    if status == "FROZEN" then
        isFrozen = true
        freezeBtn.Text = "UNFREEZE [Q]"
        freezeBtn.BackgroundColor3 = Color3.fromRGB(180, 80, 50)
    elseif status == "UNFROZEN" then
        isFrozen = false
        freezeBtn.Text = "FREEZE [Q]"
        freezeBtn.BackgroundColor3 = Color3.fromRGB(50, 100, 180)
    end
end)

print("[PaintClient] Meccha Chameleon style paint UI loaded!")
