--[[
    SeekerClient.lua (LocalScript)
    Seeker controls: Paint gun to shoot hiders from distance.
    Handles blind screen, detection pulse, and paint gun visuals.
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

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local mouse = player:GetMouse()

----------------------------------------------------------------------
-- STATE
----------------------------------------------------------------------

local myRole = nil
local seekMode = false
local pulseCooldown = 0
local activeHighlights = {}
local canShoot = true
local GUN_RANGE = 200 -- Paint gun range in studs
local SHOOT_COOLDOWN = 0.8 -- Seconds between shots

----------------------------------------------------------------------
-- CROSSHAIR UI
----------------------------------------------------------------------

local crosshairGui = Instance.new("ScreenGui")
crosshairGui.Name = "CrosshairGui"
crosshairGui.ResetOnSpawn = false
crosshairGui.IgnoreGuiInset = true
crosshairGui.Enabled = false
crosshairGui.Parent = player:WaitForChild("PlayerGui")

local crosshair = Instance.new("Frame")
crosshair.Size = UDim2.new(0, 30, 0, 30)
crosshair.Position = UDim2.new(0.5, -15, 0.5, -15)
crosshair.BackgroundTransparency = 1
crosshair.Parent = crosshairGui

-- Crosshair lines
local function makeLine(size, pos)
    local line = Instance.new("Frame")
    line.Size = size
    line.Position = pos
    line.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    line.BorderSizePixel = 0
    line.Parent = crosshair
    return line
end

makeLine(UDim2.new(0, 2, 0, 12), UDim2.new(0.5, -1, 0, 0))   -- Top
makeLine(UDim2.new(0, 2, 0, 12), UDim2.new(0.5, -1, 1, -12))  -- Bottom
makeLine(UDim2.new(0, 12, 0, 2), UDim2.new(0, 0, 0.5, -1))    -- Left
makeLine(UDim2.new(0, 12, 0, 2), UDim2.new(1, -12, 0.5, -1))  -- Right

-- Center dot
local centerDot = Instance.new("Frame")
centerDot.Size = UDim2.new(0, 4, 0, 4)
centerDot.Position = UDim2.new(0.5, -2, 0.5, -2)
centerDot.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
centerDot.Parent = crosshair
local dotCorner = Instance.new("UICorner")
dotCorner.CornerRadius = UDim.new(0.5, 0)
dotCorner.Parent = centerDot

-- Hit marker (shows briefly on hit)
local hitMarker = Instance.new("TextLabel")
hitMarker.Size = UDim2.new(0, 40, 0, 40)
hitMarker.Position = UDim2.new(0.5, -20, 0.5, -20)
hitMarker.BackgroundTransparency = 1
hitMarker.Text = "X"
hitMarker.TextColor3 = Color3.fromRGB(255, 50, 50)
hitMarker.TextSize = 30
hitMarker.Font = Enum.Font.GothamBlack
hitMarker.TextTransparency = 1
hitMarker.Parent = crosshairGui


----------------------------------------------------------------------
-- PAINT GUN - SHOOT TO TAG
----------------------------------------------------------------------

local function createBulletTrail(startPos, endPos, hit)
    -- Create a PAINT BALL projectile that flies to target
    local distance = (endPos - startPos).Magnitude
    local direction = (endPos - startPos).Unit

    -- Paint ball (visible sphere that travels)
    local paintBall = Instance.new("Part")
    paintBall.Name = "PaintBall"
    paintBall.Shape = Enum.PartType.Ball
    paintBall.Size = Vector3.new(1.5, 1.5, 1.5)
    paintBall.Position = startPos
    paintBall.Anchored = true
    paintBall.CanCollide = false
    paintBall.Material = Enum.Material.Neon
    paintBall.Color = hit and Color3.fromRGB(255, 0, 50) or Color3.fromRGB(255, 150, 0)
    paintBall.Transparency = 0
    paintBall.Parent = Workspace

    -- Trail behind the ball
    local attachment0 = Instance.new("Attachment", paintBall)
    local attachment1 = Instance.new("Attachment", paintBall)
    attachment1.Position = Vector3.new(0, 0, 0.5)

    local trail = Instance.new("Trail")
    trail.Attachment0 = attachment0
    trail.Attachment1 = attachment1
    trail.Color = ColorSequence.new(hit and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(255, 200, 0))
    trail.Transparency = NumberSequence.new(0, 1)
    trail.Lifetime = 0.3
    trail.WidthScale = NumberSequence.new(1, 0)
    trail.Parent = paintBall

    -- Animate the ball flying to target
    local flyTime = math.clamp(distance / 300, 0.05, 0.4) -- Faster for closer targets
    TweenService:Create(paintBall, TweenInfo.new(flyTime, Enum.EasingStyle.Linear), {
        Position = endPos
    }):Play()

    -- On arrival: SPLASH!
    task.delay(flyTime, function()
        paintBall.Transparency = 1
        trail.Enabled = false

        -- Create splash effect at impact point
        local splash = Instance.new("Part")
        splash.Name = "PaintSplash"
        splash.Shape = Enum.PartType.Ball
        splash.Size = Vector3.new(0.5, 0.5, 0.5)
        splash.Position = endPos
        splash.Anchored = true
        splash.CanCollide = false
        splash.Material = Enum.Material.Neon
        splash.Color = hit and Color3.fromRGB(255, 0, 50) or Color3.fromRGB(255, 150, 0)
        splash.Transparency = 0.3
        splash.Parent = Workspace

        -- Expand splash
        TweenService:Create(splash, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = Vector3.new(hit and 5 or 3, hit and 5 or 3, hit and 5 or 3),
            Transparency = 1,
        }):Play()

        -- Splat particles
        local splatAttach = Instance.new("Attachment", splash)
        local particles = Instance.new("ParticleEmitter")
        particles.Color = ColorSequence.new(hit and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(255, 180, 0))
        particles.Size = NumberSequence.new(0.4, 0)
        particles.Transparency = NumberSequence.new(0, 1)
        particles.Lifetime = NumberRange.new(0.3, 0.6)
        particles.Speed = NumberRange.new(8, 15)
        particles.SpreadAngle = Vector2.new(360, 360)
        particles.Rate = 0
        particles.Parent = splatAttach
        particles:Emit(20)

        -- Paint decal on surface (flat circle)
        local decalPart = Instance.new("Part")
        decalPart.Name = "PaintDecal"
        decalPart.Size = Vector3.new(3, 0.1, 3)
        decalPart.Position = endPos
        decalPart.Anchored = true
        decalPart.CanCollide = false
        decalPart.Material = Enum.Material.SmoothPlastic
        decalPart.Color = hit and Color3.fromRGB(255, 0, 50) or Color3.fromRGB(255, 180, 0)
        decalPart.Transparency = 0.3
        decalPart.Parent = Workspace
        Instance.new("UICorner") -- won't work on Part but that's fine

        -- Fade out decal after a few seconds
        task.delay(3, function()
            TweenService:Create(decalPart, TweenInfo.new(1), {
                Transparency = 1
            }):Play()
            task.delay(1.2, function()
                decalPart:Destroy()
            end)
        end)

        -- Cleanup
        task.delay(1, function()
            paintBall:Destroy()
            splash:Destroy()
        end)
    end)
end

local function createSplashEffect(position, color)
    -- This is now handled inside createBulletTrail on impact
    -- Keeping for compatibility but it's a no-op
end

local function shootPaintGun()
    if not seekMode then return end
    if not canShoot then return end
    if not player.Character then return end

    local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    canShoot = false

    -- Raycast from camera center (where crosshair is)
    local mousePos = UserInputService:GetMouseLocation()
    local ray = camera:ViewportPointToRay(mousePos.X, mousePos.Y)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = { player.Character }

    local result = Workspace:Raycast(ray.Origin, ray.Direction * GUN_RANGE, raycastParams)

    local startPos = rootPart.Position + Vector3.new(0, 1, 0)
    local endPos = result and result.Position or (ray.Origin + ray.Direction * GUN_RANGE)
    local hitPlayer = false

    if result and result.Instance then
        -- Check if we hit a player
        local hitCharacter = result.Instance:FindFirstAncestorOfClass("Model")
        if hitCharacter then
            local targetPlayer = Players:GetPlayerFromCharacter(hitCharacter)
            if targetPlayer and targetPlayer ~= player then
                -- HIT! Send tag to server
                SeekerTag:FireServer(targetPlayer)
                hitPlayer = true

                -- Show hit marker
                hitMarker.TextTransparency = 0
                TweenService:Create(hitMarker, TweenInfo.new(0.4), {
                    TextTransparency = 1,
                }):Play()

                -- Splash on target
                createSplashEffect(result.Position, Color3.fromRGB(255, 50, 50))
            end
        end

        -- Splash on wall/floor if missed
        if not hitPlayer then
            createSplashEffect(result.Position, Color3.fromRGB(255, 150, 0))
        end
    end

    -- Bullet trail visual
    createBulletTrail(startPos, endPos, hitPlayer)

    -- Crosshair kick animation
    TweenService:Create(crosshair, TweenInfo.new(0.05), {
        Position = UDim2.new(0.5, -15, 0.5, -20)
    }):Play()
    task.delay(0.05, function()
        TweenService:Create(crosshair, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {
            Position = UDim2.new(0.5, -15, 0.5, -15)
        }):Play()
    end)

    -- Cooldown
    task.delay(SHOOT_COOLDOWN, function()
        canShoot = true
    end)
end


----------------------------------------------------------------------
-- DETECTION PULSE VISUAL
----------------------------------------------------------------------

local function createPulseVisual()
    local character = player.Character
    if not character then return end
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

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

    local targetSize = GameConfig.DetectionPulseRadius * 2
    local tween = TweenService:Create(sphere, TweenInfo.new(1.0, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = Vector3.new(targetSize, targetSize, targetSize),
        Transparency = 1,
    })
    tween:Play()
    tween.Completed:Connect(function()
        sphere:Destroy()
    end)
end

----------------------------------------------------------------------
-- HIGHLIGHT SYSTEM
----------------------------------------------------------------------

local function highlightPlayer(data)
    local targetName = data.playerName
    local duration = data.duration or GameConfig.HighlightDuration

    local targetPlayer = Players:FindFirstChild(targetName)
    if not targetPlayer or not targetPlayer.Character then return end

    local character = targetPlayer.Character

    local highlight = Instance.new("Highlight")
    highlight.Name = "SeekerDetection"
    highlight.FillColor = Color3.fromRGB(255, 50, 50)
    highlight.FillTransparency = 0.5
    highlight.OutlineColor = Color3.fromRGB(255, 100, 0)
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = character

    table.insert(activeHighlights, { highlight = highlight, character = character })

    task.delay(duration, function()
        if highlight and highlight.Parent then
            highlight:Destroy()
        end
    end)
end

----------------------------------------------------------------------
-- SEEKER BLIND SCREEN
----------------------------------------------------------------------

local blindGui = nil

local function showSeekerBlind(show)
    local gui = player:FindFirstChild("PlayerGui")
    if not gui then return end

    if show then
        if not blindGui then
            blindGui = Instance.new("ScreenGui")
            blindGui.Name = "SeekerBlind"
            blindGui.IgnoreGuiInset = true
            blindGui.DisplayOrder = 100
            blindGui.Parent = gui

            local frame = Instance.new("Frame")
            frame.Name = "BlindFrame"
            frame.Size = UDim2.new(1, 0, 1, 0)
            frame.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
            frame.BackgroundTransparency = 0
            frame.BorderSizePixel = 0
            frame.Parent = blindGui

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(0.6, 0, 0, 60)
            label.Position = UDim2.new(0.2, 0, 0.45, 0)
            label.BackgroundTransparency = 1
            label.TextColor3 = Color3.fromRGB(200, 200, 200)
            label.Text = "The Chameleons are hiding...\nGet ready to seek!"
            label.TextSize = 24
            label.Font = Enum.Font.GothamBold
            label.Parent = blindGui

            local eye = Instance.new("TextLabel")
            eye.Name = "Eye"
            eye.Size = UDim2.new(0, 80, 0, 80)
            eye.Position = UDim2.new(0.5, -40, 0.3, 0)
            eye.BackgroundTransparency = 1
            eye.TextColor3 = Color3.fromRGB(255, 100, 100)
            eye.Text = "👁"
            eye.TextSize = 50
            eye.Parent = blindGui
        end
    else
        -- REMOVE the blind screen
        if blindGui then
            local frame = blindGui:FindFirstChild("BlindFrame")
            if frame then
                TweenService:Create(frame, TweenInfo.new(0.5), {
                    BackgroundTransparency = 1,
                }):Play()
            end
            task.delay(0.6, function()
                if blindGui then
                    blindGui:Destroy()
                    blindGui = nil
                end
            end)
        end
    end
end


----------------------------------------------------------------------
-- INPUT HANDLING
----------------------------------------------------------------------

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if not seekMode then return end

    -- Left click = SHOOT paint gun
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        shootPaintGun()
    end

    if input.UserInputType == Enum.UserInputType.Keyboard then
        -- X key for detection pulse
        if input.KeyCode == Enum.KeyCode.X then
            if pulseCooldown <= 0 then
                SeekerAbility:FireServer("PULSE")
                createPulseVisual()
                pulseCooldown = GameConfig.DetectionPulseCooldown
            end
        end
    end
end)

----------------------------------------------------------------------
-- COOLDOWN TIMER
----------------------------------------------------------------------

RunService.Heartbeat:Connect(function(dt)
    if pulseCooldown > 0 then
        pulseCooldown -= dt
        if pulseCooldown < 0 then pulseCooldown = 0 end
    end
end)

----------------------------------------------------------------------
-- SERVER RESPONSES
----------------------------------------------------------------------

SeekerAbility.OnClientEvent:Connect(function(status, data)
    if status == "PULSE_RESULT" then
        local detected = data.detected or 0
        if detected > 0 then
            print("[Seeker] Pulse detected", detected, "hider(s)!")
        end
    elseif status == "TAG_SUCCESS" then
        print("[Seeker] HIT!", data.targetName, "eliminated!")
    end
end)

HighlightHider.OnClientEvent:Connect(function(data)
    highlightPlayer(data)
end)

----------------------------------------------------------------------
-- ROUND STATE HANDLING
----------------------------------------------------------------------

RoleAssigned.OnClientEvent:Connect(function(role)
    myRole = role
    seekMode = false
    crosshairGui.Enabled = false
end)

RoundStateChanged.OnClientEvent:Connect(function(state, data)
    if state == "SeekPhase" and myRole == "Seeker" then
        -- RELEASE THE SEEKER!
        seekMode = true
        pulseCooldown = 0
        showSeekerBlind(false) -- REMOVE black screen!
        crosshairGui.Enabled = true -- Show crosshair
        print("[Seeker] GO! Left-click to shoot paint gun! X = Detection Pulse")

    elseif state == "PrepPhase" and myRole == "Seeker" then
        seekMode = false
        showSeekerBlind(true) -- Show black screen during prep

    elseif state == "HidePhase" and myRole == "Seeker" then
        seekMode = false
        -- Keep blind screen during hide phase (already showing)

    elseif state == "Lobby" or state == "Results" then
        seekMode = false
        myRole = nil
        showSeekerBlind(false)
        crosshairGui.Enabled = false
        -- Clear highlights
        for _, d in ipairs(activeHighlights) do
            if d.highlight and d.highlight.Parent then
                d.highlight:Destroy()
            end
        end
        activeHighlights = {}
    end
end)

print("[SeekerClient] Paint gun seeker loaded! LMB=Shoot, X=Pulse")
