--[[
    FreezeClient.lua (LocalScript)
    Client-side freeze controls for hiders.
    Handles freeze toggle, pose selection, and visual feedback.
    Place in StarterPlayerScripts.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local GameConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameConfig"))
local FreezeSystem = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("FreezeSystem"))

local Events = ReplicatedStorage:WaitForChild("Events")
local FreezeCharacter = Events:WaitForChild("FreezeCharacter")
local RoundStateChanged = Events:WaitForChild("RoundStateChanged")
local RoleAssigned = Events:WaitForChild("RoleAssigned")

----------------------------------------------------------------------
-- STATE
----------------------------------------------------------------------

local player = Players.LocalPlayer
local myRole = nil
local isFrozen = false
local canFreeze = false
local currentPoseIndex = 1
local poseList = FreezeSystem.GetPoseList()

----------------------------------------------------------------------
-- VISUAL EFFECTS
----------------------------------------------------------------------

-- Visual feedback when freezing (subtle transparency pulse)
local function playFreezeEffect(character)
    if not character then return end

    -- Brief white flash on character
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if rootPart then
        -- Create a subtle particle effect
        local attachment = Instance.new("Attachment")
        attachment.Parent = rootPart

        local particles = Instance.new("ParticleEmitter")
        particles.Texture = "rbxassetid://6026568198" -- Sparkle texture
        particles.Color = ColorSequence.new(Color3.fromRGB(200, 220, 255))
        particles.Size = NumberSequence.new(0.3, 0)
        particles.Transparency = NumberSequence.new(0, 1)
        particles.Lifetime = NumberRange.new(0.3, 0.5)
        particles.Rate = 20
        particles.Speed = NumberRange.new(2, 4)
        particles.SpreadAngle = Vector2.new(360, 360)
        particles.Parent = attachment

        -- Brief burst then remove
        task.delay(0.5, function()
            particles.Enabled = false
            task.delay(1, function()
                attachment:Destroy()
            end)
        end)
    end
end

-- Visual feedback when unfreezing
local function playUnfreezeEffect(character)
    if not character then return end

    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if rootPart then
        local attachment = Instance.new("Attachment")
        attachment.Parent = rootPart

        local particles = Instance.new("ParticleEmitter")
        particles.Texture = "rbxassetid://6026568198"
        particles.Color = ColorSequence.new(Color3.fromRGB(255, 200, 100))
        particles.Size = NumberSequence.new(0.2, 0)
        particles.Transparency = NumberSequence.new(0, 1)
        particles.Lifetime = NumberRange.new(0.2, 0.4)
        particles.Rate = 30
        particles.Speed = NumberRange.new(3, 5)
        particles.SpreadAngle = Vector2.new(360, 360)
        particles.Parent = attachment

        task.delay(0.3, function()
            particles.Enabled = false
            task.delay(1, function()
                attachment:Destroy()
            end)
        end)
    end
end

-- Show freeze indicator on screen (ice overlay)
local function showFreezeOverlay(show)
    local gui = player:FindFirstChild("PlayerGui")
    if not gui then return end

    local overlay = gui:FindFirstChild("FreezeOverlay")

    if show then
        if not overlay then
            overlay = Instance.new("ScreenGui")
            overlay.Name = "FreezeOverlay"
            overlay.IgnoreGuiInset = true
            overlay.Parent = gui

            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, 0, 1, 0)
            frame.BackgroundColor3 = Color3.fromRGB(180, 220, 255)
            frame.BackgroundTransparency = 0.92
            frame.BorderSizePixel = 0
            frame.Parent = overlay

            -- Border glow effect
            local border = Instance.new("UIStroke")
            border.Color = Color3.fromRGB(100, 180, 255)
            border.Thickness = 4
            border.Transparency = 0.5
            border.Parent = frame

            -- "FROZEN" text indicator
            local label = Instance.new("TextLabel")
            label.Name = "FreezeLabel"
            label.Size = UDim2.new(0, 200, 0, 40)
            label.Position = UDim2.new(0.5, -100, 0, 60)
            label.BackgroundColor3 = Color3.fromRGB(50, 100, 150)
            label.BackgroundTransparency = 0.3
            label.TextColor3 = Color3.fromRGB(200, 230, 255)
            label.Text = "FROZEN - Press Q to unfreeze"
            label.TextSize = 14
            label.Font = Enum.Font.GothamBold
            label.Parent = overlay

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 8)
            corner.Parent = label
        end
    else
        if overlay then
            overlay:Destroy()
        end
    end
end

----------------------------------------------------------------------
-- FREEZE/UNFREEZE LOGIC
----------------------------------------------------------------------

local function toggleFreeze()
    if not canFreeze then return end
    if myRole ~= "Hider" then return end

    if isFrozen then
        -- Request unfreeze
        FreezeCharacter:FireServer("UNFREEZE")
    else
        -- Get current pose name
        local currentPose = poseList[currentPoseIndex]
        local poseName = currentPose and currentPose.name or "Standing"
        -- Request freeze with pose
        FreezeCharacter:FireServer("FREEZE", poseName)
    end
end

local function cyclePose(direction)
    if not canFreeze then return end
    if myRole ~= "Hider" then return end

    -- Cycle through poses
    currentPoseIndex += direction
    if currentPoseIndex > #poseList then
        currentPoseIndex = 1
    elseif currentPoseIndex < 1 then
        currentPoseIndex = #poseList
    end

    local pose = poseList[currentPoseIndex]
    print("[FreezeClient] Pose selected:", pose.displayName, "-", pose.description)

    -- If already frozen, change pose in-place
    if isFrozen then
        FreezeCharacter:FireServer("POSE", pose.name)
    end
end

----------------------------------------------------------------------
-- INPUT HANDLING
----------------------------------------------------------------------

local function onInputBegan(input, gameProcessed)
    if gameProcessed then return end
    if myRole ~= "Hider" then return end

    if input.UserInputType == Enum.UserInputType.Keyboard then
        -- Q key to toggle freeze
        if input.KeyCode == Enum.KeyCode.Q then
            toggleFreeze()
        end

        -- E key to cycle pose forward
        if input.KeyCode == Enum.KeyCode.E and canFreeze then
            cyclePose(1)
        end

        -- R key to cycle pose backward
        if input.KeyCode == Enum.KeyCode.R and canFreeze then
            cyclePose(-1)
        end
    end
end

----------------------------------------------------------------------
-- SERVER RESPONSE HANDLING
----------------------------------------------------------------------

FreezeCharacter.OnClientEvent:Connect(function(status, data)
    if status == "FROZEN" then
        isFrozen = true
        showFreezeOverlay(true)
        playFreezeEffect(player.Character)
        print("[FreezeClient] You are now FROZEN. Press Q to unfreeze (risky!).")

    elseif status == "UNFROZEN" then
        isFrozen = false
        showFreezeOverlay(false)
        playUnfreezeEffect(player.Character)
        print("[FreezeClient] You are now UNFROZEN. Move carefully!")

    elseif status == "POSE_CHANGED" then
        print("[FreezeClient] Pose changed to:", data)
    end
end)

----------------------------------------------------------------------
-- ROUND STATE HANDLING
----------------------------------------------------------------------

RoleAssigned.OnClientEvent:Connect(function(role)
    myRole = role
    if role == "Hider" then
        canFreeze = false -- Will be enabled in HidePhase
    else
        canFreeze = false
        isFrozen = false
        showFreezeOverlay(false)
    end
end)

RoundStateChanged.OnClientEvent:Connect(function(state, data)
    if state == "HidePhase" and myRole == "Hider" then
        -- Enable freezing during hide and seek phases
        canFreeze = true
        print("[FreezeClient] Freeze enabled! Press Q to freeze, E/R to cycle poses.")

    elseif state == "SeekPhase" and myRole == "Hider" then
        -- Keep freeze enabled during seeking
        canFreeze = true

    elseif state == "Lobby" or state == "Results" or state == "PrepPhase" then
        -- Disable freezing
        canFreeze = false
        isFrozen = false
        showFreezeOverlay(false)
        myRole = nil
    end
end)

----------------------------------------------------------------------
-- CONNECT INPUT
----------------------------------------------------------------------

UserInputService.InputBegan:Connect(onInputBegan)

print("[FreezeClient] Freeze system loaded. Controls: Q=Freeze/Unfreeze, E=Next Pose, R=Prev Pose")
