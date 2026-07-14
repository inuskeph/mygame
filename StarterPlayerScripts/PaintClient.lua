--[[
    PaintClient.lua (LocalScript)
    Client-side paint controls for hiders.
    Handles color picking, brush tool, and painting body parts.
    Place in StarterPlayerScripts.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local GameConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameConfig"))
local PaintSystem = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PaintSystem"))

local Events = ReplicatedStorage:WaitForChild("Events")
local PaintCharacter = Events:WaitForChild("PaintCharacter")
local RoundStateChanged = Events:WaitForChild("RoundStateChanged")
local RoleAssigned = Events:WaitForChild("RoleAssigned")
local GetColorPalette = Events:WaitForChild("GetColorPalette")

----------------------------------------------------------------------
-- STATE
----------------------------------------------------------------------

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local camera = Workspace.CurrentCamera

local myRole = nil           -- "Hider" or "Seeker"
local paintMode = false      -- Is painting active
local selectedColor = nil    -- Currently selected Color3
local remainingCharges = 0   -- Paint charges left
local brushActive = false    -- Is brush tool equipped
local colorPalette = {}      -- Available colors for current map
local currentState = "Lobby"

----------------------------------------------------------------------
-- UI REFERENCES (will be created by UI system, this connects to them)
----------------------------------------------------------------------

local function getGui()
    local gui = player:WaitForChild("PlayerGui"):FindFirstChild("PaintGui")
    return gui
end

----------------------------------------------------------------------
-- COLOR SAMPLING (click on world to pick color)
----------------------------------------------------------------------

local function sampleColorFromWorld()
    local mousePos = UserInputService:GetMouseLocation()
    local ray = camera:ViewportPointToRay(mousePos.X, mousePos.Y)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = {player.Character}

    local result = Workspace:Raycast(ray.Origin, ray.Direction * 100, raycastParams)
    if result and result.Instance then
        local sampledColor = PaintSystem.SampleColor(result.Instance)
        if sampledColor then
            -- Snap to closest palette color
            local closestColor = PaintSystem.FindClosestPaletteColor(sampledColor, colorPalette)
            return closestColor
        end
    end
    return nil
end

----------------------------------------------------------------------
-- PAINTING
----------------------------------------------------------------------

local function paintBodyPart(partName)
    if not selectedColor then
        warn("[PaintClient] No color selected!")
        return
    end

    if remainingCharges <= 0 then
        warn("[PaintClient] No paint charges remaining!")
        return
    end

    -- Send paint request to server
    PaintCharacter:FireServer(partName, selectedColor)
end

-- Paint all visible parts at once (uses multiple charges)
local function paintFullBody()
    if not selectedColor then return end
    if not player.Character then return end

    for _, partName in ipairs(PaintSystem.PaintableParts) do
        if player.Character:FindFirstChild(partName) then
            if remainingCharges <= 0 then break end
            PaintCharacter:FireServer(partName, selectedColor)
            task.wait(0.05) -- Small delay to avoid flooding
        end
    end
end

-- Paint a specific clicked body part
local function onBodyPartClicked()
    if not paintMode or not brushActive then return end
    if not selectedColor then return end

    local target = mouse.Target
    if target and target:IsDescendantOf(player.Character) then
        paintBodyPart(target.Name)
    end
end

----------------------------------------------------------------------
-- COLOR POOL INTERACTION
----------------------------------------------------------------------

local function onColorPoolTouched(colorPool)
    if not paintMode then return end

    -- Color pools are Parts with a "PaintColor" Color3Value attribute
    local poolColor = colorPool:GetAttribute("PaintColor")
    if poolColor then
        selectedColor = poolColor
        print("[PaintClient] Selected color from pool:", tostring(poolColor))
    end
end

----------------------------------------------------------------------
-- INPUT HANDLING
----------------------------------------------------------------------

local function onInputBegan(input, gameProcessed)
    if gameProcessed then return end
    if not paintMode then return end

    -- Left click to paint body part (when brush is active)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        onBodyPartClicked()
    end

    -- Right click to sample color from world
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        local sampled = sampleColorFromWorld()
        if sampled then
            selectedColor = sampled
            print("[PaintClient] Sampled color:", tostring(sampled))
        end
    end

    -- Key bindings
    if input.UserInputType == Enum.UserInputType.Keyboard then
        -- B key to toggle brush
        if input.KeyCode == Enum.KeyCode.B then
            brushActive = not brushActive
            print("[PaintClient] Brush:", brushActive and "ON" or "OFF")
        end

        -- F key to paint full body
        if input.KeyCode == Enum.KeyCode.F then
            paintFullBody()
        end

        -- Number keys 1-9 to quick-select palette colors
        local numKeys = {
            Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three,
            Enum.KeyCode.Four, Enum.KeyCode.Five, Enum.KeyCode.Six,
            Enum.KeyCode.Seven, Enum.KeyCode.Eight, Enum.KeyCode.Nine,
        }
        for i, keyCode in ipairs(numKeys) do
            if input.KeyCode == keyCode and colorPalette[i] then
                selectedColor = colorPalette[i]
                print("[PaintClient] Selected palette color #" .. i)
            end
        end
    end
end

----------------------------------------------------------------------
-- SERVER RESPONSE HANDLING
----------------------------------------------------------------------

PaintCharacter.OnClientEvent:Connect(function(status, charges)
    remainingCharges = charges or remainingCharges

    if status == "SUCCESS" then
        -- Paint applied successfully
    elseif status == "NO_CHARGES" then
        warn("[PaintClient] Out of paint! Find a color pool to refill.")
    elseif status == "FAILED" then
        warn("[PaintClient] Paint failed!")
    elseif status == "REFILL" then
        print("[PaintClient] Paint refilled! Charges:", charges)
    end
end)

----------------------------------------------------------------------
-- ROUND STATE HANDLING
----------------------------------------------------------------------

RoleAssigned.OnClientEvent:Connect(function(role)
    myRole = role
    print("[PaintClient] Assigned role:", role)

    if role == "Hider" then
        -- Prepare for painting
        brushActive = true
    else
        -- Seekers don't paint
        brushActive = false
        paintMode = false
    end
end)

RoundStateChanged.OnClientEvent:Connect(function(state, data)
    currentState = state

    if state == "PrepPhase" and myRole == "Hider" then
        -- Enable painting mode
        paintMode = true
        brushActive = true

        -- Fetch color palette from server
        local success, palette = pcall(function()
            return GetColorPalette:InvokeServer()
        end)
        if success and palette then
            colorPalette = palette
            -- Default to first color
            if #colorPalette > 0 then
                selectedColor = colorPalette[1]
            end
        end

        print("[PaintClient] Painting enabled! Use B for brush, F for full body, 1-9 for colors, RMB to sample.")

    elseif state == "HidePhase" then
        -- Disable painting in hide phase (only positioning)
        paintMode = false
        brushActive = false

    elseif state == "SeekPhase" or state == "Lobby" or state == "Results" then
        paintMode = false
        brushActive = false
        selectedColor = nil
        myRole = nil
    end
end)

----------------------------------------------------------------------
-- CONNECT INPUT
----------------------------------------------------------------------

UserInputService.InputBegan:Connect(onInputBegan)

-- Detect color pool touches
local function setupCharacterTouchDetection()
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

    humanoidRootPart.Touched:Connect(function(otherPart)
        if otherPart:GetAttribute("IsColorPool") then
            onColorPoolTouched(otherPart)
        end
    end)
end

player.CharacterAdded:Connect(setupCharacterTouchDetection)
if player.Character then
    setupCharacterTouchDetection()
end

print("[PaintClient] Paint system loaded. Controls: B=Brush, F=FullBody, 1-9=Colors, RMB=Sample")
