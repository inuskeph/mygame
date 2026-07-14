--[[
    SeekerClient.lua (LocalScript)
    Client-side seeker controls and abilities.
    Handles detection pulse, tagging, and highlight visuals.
    Place in StarterPlayerScripts.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local GameConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameConfig"))

local Events = ReplicatedStorage:WaitForChild("Events")
local SeekerAbility = Events:WaitForChild("SeekerAbility")
local SeekerTag = Events:WaitForChild("SeekerTag")
local HighlightHider = Events:WaitForChild("HighlightHider")
local RoundStateChanged = Events:WaitForChild("RoundStateChanged")
local RoleAssigned = Events:WaitForChild("RoleAssigned")

----------------------------------------------------------------------
-- STATE
----------------------------------------------------------------------

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local mouse = player:GetMouse()

local myRole = nil
local seekMode = false        -- Are we in seek phase as seeker?
local pulseCooldown = 0       -- Remaining cooldown for pulse
local activeHighlights = {}   -- Currently active highlight effects
local canTag = true           -- Debounce for tagging

----------------------------------------------------------------------
-- DETECTION PULSE VISUAL
----------------------------------------------------------------------

-- Creates an expanding sphere visual for the detection pulse
local function createPulseVisual()
    local character = player.Character
    if not character then return end
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    -- Create expanding sphere
    local sphere = Instance.new("Part")
    sphere.Name = "DetectionPulse"
    sphere.Shape = Enum.PartType.Ball
    sphere.Size = Vector3.new(1, 1, 1)
    sphere.Position = rootPart.Position
    sphere.Anchored = true
    sphere.CanCollide = false
    sphere.Material = Enum.Material.ForceField
    sphere.Color = Color3.fromRGB(0, 150, 255)
    sphere.Transparency = 0.7
    sphere.Parent = Workspace

    -- Expand animation
    local targetSize = GameConfig.DetectionPulseRadius * 2
    local tweenInfo = TweenInfo.new(1.0, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tween = TweenService:Create(sphere, tweenInfo, {
        Size = Vector3.new(targetSize, targetSize, targetSize),
        Transparency = 1,
    })
    tween:Play()

    -- Cleanup after animation
    tween.Completed:Connect(function()
        sphere:Destroy()
    end)
end

----------------------------------------------------------------------
-- HIGHLIGHT SYSTEM
----------------------------------------------------------------------

-- Highlight a detected hider temporarily
local function highlightPlayer(data)
    local targetName = data.playerName
    local duration = data.duration or GameConfig.HighlightDuration

    -- Find the target player's character
    local targetPlayer = Players:FindFirstChild(targetName)
    if not targetPlayer or not targetPlayer.Character then return end

    local character = targetPlayer.Character

    -- Create highlight effect
    local highlight = Instance.new("Highlight")
    highlight.Name = "SeekerDetection"
    highlight.FillColor = Color3.fromRGB(255, 50, 50)
    highlight.FillTransparency = 0.5
    highlight.OutlineColor = Color3.fromRGB(255, 100, 0)
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = character

    -- Add distance indicator (BillboardGui)
    local head = character:FindFirstChild("Head")
    if head then
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "DetectionIndicator"
        billboard.Size = UDim2.new(0, 100, 0, 30)
        billboard.StudsOffset = Vector3.new(0, 3, 0)
        billboard.AlwaysOnTop = true
        billboard.Parent = head

        local distLabel = Instance.new("TextLabel")
        distLabel.Size = UDim2.new(1, 0, 1, 0)
        distLabel.BackgroundTransparency = 0.3
        distLabel.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        distLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        distLabel.Text = string.format("%.0fm", data.distance or 0)
        distLabel.TextSize = 16
        distLabel.Font = Enum.Font.GothamBold
        distLabel.Parent = billboard

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = distLabel
    end

    -- Store for cleanup
    table.insert(activeHighlights, { highlight = highlight, character = character })

    -- Remove after duration
    task.delay(duration, function()
        if highlight and highlight.Parent then
            -- Fade out
            local fadeInfo = TweenInfo.new(0.5, Enum.EasingStyle.Linear)
            local fadeTween = TweenService:Create(highlight, fadeInfo, {
                FillTransparency = 1,
                OutlineTransparency = 1,
            })
            fadeTween:Play()
            fadeTween.Completed:Connect(function()
                highlight:Destroy()
            end)
        end

        -- Remove billboard
        if head then
            local billboard = head:FindFirstChild("DetectionIndicator")
            if billboard then billboard:Destroy() end
        end
    end)
end

----------------------------------------------------------------------
-- TAGGING
----------------------------------------------------------------------

local function attemptTag()
    if not seekMode then return end
    if not canTag then return end

    -- Raycast from camera to find a hider
    local mousePos = UserInputService:GetMouseLocation()
    local ray = camera:ViewportPointToRay(mousePos.X, mousePos.Y)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = { player.Character }

    local result = Workspace:Raycast(ray.Origin, ray.Direction * GameConfig.TagDistance, raycastParams)

    if result and result.Instance then
        -- Check if hit part belongs to a player character
        local hitCharacter = result.Instance:FindFirstAncestorOfClass("Model")
        if hitCharacter then
            local targetPlayer = Players:GetPlayerFromCharacter(hitCharacter)
            if targetPlayer and targetPlayer ~= player then
                -- Send tag request
                canTag = false
                SeekerTag:FireServer(targetPlayer)

                -- Brief cooldown to prevent spam
                task.delay(0.5, function()
                    canTag = true
                end)
            end
        end
    end
end

-- Alternative: proximity-based tag (click on nearby player)
local function attemptProximityTag()
    if not seekMode then return end
    if not canTag then return end
    if not player.Character then return end

    local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    -- Find closest hider within tag distance
    local closestPlayer = nil
    local closestDist = GameConfig.TagDistance

    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= player and otherPlayer.Character then
            local otherRoot = otherPlayer.Character:FindFirstChild("HumanoidRootPart")
            if otherRoot then
                local dist = (rootPart.Position - otherRoot.Position).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    closestPlayer = otherPlayer
                end
            end
        end
    end

    if closestPlayer then
        canTag = false
        SeekerTag:FireServer(closestPlayer)
        task.delay(0.5, function()
            canTag = true
        end)
    end
end

----------------------------------------------------------------------
-- INPUT HANDLING
----------------------------------------------------------------------

local function onInputBegan(input, gameProcessed)
    if gameProcessed then return end
    if not seekMode then return end

    if input.UserInputType == Enum.UserInputType.Keyboard then
        -- X key for detection pulse
        if input.KeyCode == Enum.KeyCode.X then
            if pulseCooldown <= 0 then
                SeekerAbility:FireServer("PULSE")
                createPulseVisual()
                pulseCooldown = GameConfig.DetectionPulseCooldown
            else
                print("[SeekerClient] Pulse on cooldown:", math.ceil(pulseCooldown), "seconds remaining")
            end
        end

        -- T key for proximity tag
        if input.KeyCode == Enum.KeyCode.T then
            attemptProximityTag()
        end
    end

    -- Left click for raycast tag
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        attemptTag()
    end
end

----------------------------------------------------------------------
-- COOLDOWN TIMER
----------------------------------------------------------------------

RunService.Heartbeat:Connect(function(dt)
    if pulseCooldown > 0 then
        pulseCooldown -= dt
        if pulseCooldown < 0 then
            pulseCooldown = 0
        end
    end
end)

----------------------------------------------------------------------
-- SERVER RESPONSE HANDLING
----------------------------------------------------------------------

SeekerAbility.OnClientEvent:Connect(function(status, data)
    if status == "PULSE_RESULT" then
        local detected = data.detected or 0
        if detected > 0 then
            print("[SeekerClient] Pulse detected", detected, "hider(s) nearby!")
        else
            print("[SeekerClient] Pulse found nothing nearby.")
        end

    elseif status == "TAG_SUCCESS" then
        print("[SeekerClient] Successfully tagged", data.targetName, "!")
        -- Play success sound/effect here

    elseif status == "COOLDOWN" then
        pulseCooldown = data.remaining or 0
        print("[SeekerClient] Ability on cooldown:", math.ceil(pulseCooldown), "s")
    end
end)

-- Highlight hider when server sends detection data
HighlightHider.OnClientEvent:Connect(function(data)
    highlightPlayer(data)
end)

----------------------------------------------------------------------
-- ROUND STATE HANDLING
----------------------------------------------------------------------

RoleAssigned.OnClientEvent:Connect(function(role)
    myRole = role
    seekMode = false

    if role == "Seeker" then
        print("[SeekerClient] You are a SEEKER! Wait for the seek phase...")
    end
end)

RoundStateChanged.OnClientEvent:Connect(function(state, data)
    if state == "SeekPhase" and myRole == "Seeker" then
        seekMode = true
        pulseCooldown = 0
        print("[SeekerClient] SEEK PHASE! Controls: LMB=Tag(aim), T=Tag(proximity), X=Detection Pulse")

    elseif state == "PrepPhase" and myRole == "Seeker" then
        -- Seeker is blinded during prep
        seekMode = false
        showSeekerBlind(true)

    elseif state == "HidePhase" and myRole == "Seeker" then
        -- Still blinded during hide phase
        seekMode = false

    elseif state == "Lobby" or state == "Results" then
        seekMode = false
        myRole = nil
        showSeekerBlind(false)
        -- Clear any active highlights
        for _, data in ipairs(activeHighlights) do
            if data.highlight and data.highlight.Parent then
                data.highlight:Destroy()
            end
        end
        activeHighlights = {}
    end
end)

----------------------------------------------------------------------
-- SEEKER BLIND (during prep/hide phases)
----------------------------------------------------------------------

function showSeekerBlind(show)
    local gui = player:FindFirstChild("PlayerGui")
    if not gui then return end

    local blind = gui:FindFirstChild("SeekerBlind")

    if show then
        if not blind then
            blind = Instance.new("ScreenGui")
            blind.Name = "SeekerBlind"
            blind.IgnoreGuiInset = true
            blind.DisplayOrder = 100
            blind.Parent = gui

            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, 0, 1, 0)
            frame.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
            frame.BackgroundTransparency = 0
            frame.BorderSizePixel = 0
            frame.Parent = blind

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(0.6, 0, 0, 60)
            label.Position = UDim2.new(0.2, 0, 0.45, 0)
            label.BackgroundTransparency = 1
            label.TextColor3 = Color3.fromRGB(200, 200, 200)
            label.Text = "The Chameleons are hiding...\nGet ready to seek!"
            label.TextSize = 24
            label.Font = Enum.Font.GothamBold
            label.Parent = blind

            -- Pulsing eye icon
            local eye = Instance.new("TextLabel")
            eye.Size = UDim2.new(0, 80, 0, 80)
            eye.Position = UDim2.new(0.5, -40, 0.3, 0)
            eye.BackgroundTransparency = 1
            eye.TextColor3 = Color3.fromRGB(255, 100, 100)
            eye.Text = "👁"
            eye.TextSize = 50
            eye.Parent = blind

            -- Pulse animation
            task.spawn(function()
                while blind and blind.Parent do
                    local tweenIn = TweenService:Create(eye, TweenInfo.new(0.8, Enum.EasingStyle.Sine), {
                        TextTransparency = 0.5,
                    })
                    tweenIn:Play()
                    tweenIn.Completed:Wait()

                    local tweenOut = TweenService:Create(eye, TweenInfo.new(0.8, Enum.EasingStyle.Sine), {
                        TextTransparency = 0,
                    })
                    tweenOut:Play()
                    tweenOut.Completed:Wait()
                end
            end)
        end
    else
        if blind then
            -- Fade out
            local frame = blind:FindFirstChildOfClass("Frame")
            if frame then
                local fadeInfo = TweenInfo.new(0.5, Enum.EasingStyle.Linear)
                local fadeTween = TweenService:Create(frame, fadeInfo, {
                    BackgroundTransparency = 1,
                })
                fadeTween:Play()
                fadeTween.Completed:Connect(function()
                    blind:Destroy()
                end)
            else
                blind:Destroy()
            end
        end
    end
end

----------------------------------------------------------------------
-- CONNECT INPUT
----------------------------------------------------------------------

UserInputService.InputBegan:Connect(onInputBegan)

print("[SeekerClient] Seeker system loaded. Controls: LMB=Tag(aim), T=Tag(proximity), X=Pulse")
