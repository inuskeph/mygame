--[[
    TauntClient.lua (LocalScript)
    Client-side taunt controls and visual/audio effects.
    Hiders press G to taunt for bonus points (risky!).
    Place in StarterPlayerScripts.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local GameConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameConfig"))

local Events = ReplicatedStorage:WaitForChild("Events")
local TauntPerformed = Events:WaitForChild("TauntPerformed")
local RoundStateChanged = Events:WaitForChild("RoundStateChanged")
local RoleAssigned = Events:WaitForChild("RoleAssigned")


----------------------------------------------------------------------
-- STATE
----------------------------------------------------------------------

local player = Players.LocalPlayer
local myRole = nil
local canTaunt = false
local isTaunting = false
local selectedTauntIndex = 1
local cooldownRemaining = 0

-- Available taunts (synced with server definitions)
local availableTaunts = {
    { id = "Wave", name = "Wave", key = "1" },
    { id = "Dance", name = "Dance", key = "2" },
    { id = "Laugh", name = "Laugh", key = "3" },
    { id = "Spin", name = "Spin", key = "4" },
    { id = "Flex", name = "Flex", key = "5" },
}

----------------------------------------------------------------------
-- VISUAL EFFECTS
----------------------------------------------------------------------

-- Show a "!" indicator above player during taunt (visible to everyone)
local function createTauntIndicator(character, duration)
    if not character then return end
    local head = character:FindFirstChild("Head")
    if not head then return end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "TauntIndicator"
    billboard.Size = UDim2.new(0, 60, 0, 60)
    billboard.StudsOffset = Vector3.new(0, 3.5, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = head

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 255, 0)
    label.Text = "!"
    label.TextSize = 40
    label.Font = Enum.Font.GothamBlack
    label.TextStrokeColor3 = Color3.fromRGB(200, 100, 0)
    label.TextStrokeTransparency = 0
    label.Parent = billboard

    -- Bounce animation
    task.spawn(function()
        local elapsed = 0
        while elapsed < duration and billboard.Parent do
            local bounce = math.sin(elapsed * 8) * 0.3
            billboard.StudsOffset = Vector3.new(0, 3.5 + bounce, 0)
            elapsed += task.wait()
        end
        if billboard.Parent then
            billboard:Destroy()
        end
    end)

    -- Auto-remove
    task.delay(duration, function()
        if billboard and billboard.Parent then
            billboard:Destroy()
        end
    end)
end

-- Screen flash for the taunting player
local function showTauntFlash()
    local gui = player:FindFirstChild("PlayerGui")
    if not gui then return end

    local flash = Instance.new("ScreenGui")
    flash.Name = "TauntFlash"
    flash.IgnoreGuiInset = true
    flash.Parent = gui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
    frame.BackgroundTransparency = 0.7
    frame.BorderSizePixel = 0
    frame.Parent = flash

    -- Quick fade out
    local tween = TweenService:Create(frame, TweenInfo.new(0.5, Enum.EasingStyle.Linear), {
        BackgroundTransparency = 1,
    })
    tween:Play()
    tween.Completed:Connect(function()
        flash:Destroy()
    end)
end

-- Show "+25 pts" floating text
local function showPointsPopup(points)
    local gui = player:FindFirstChild("PlayerGui")
    if not gui then return end

    local popup = Instance.new("ScreenGui")
    popup.Name = "TauntPoints"
    popup.IgnoreGuiInset = true
    popup.Parent = gui

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 200, 0, 40)
    label.Position = UDim2.new(0.5, -100, 0.4, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 220, 50)
    label.Text = "+" .. points .. " pts (Taunt!)"
    label.TextSize = 22
    label.Font = Enum.Font.GothamBlack
    label.TextStrokeTransparency = 0.3
    label.Parent = popup

    -- Float up and fade
    local tween = TweenService:Create(label, TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, -100, 0.3, 0),
        TextTransparency = 1,
        TextStrokeTransparency = 1,
    })
    tween:Play()
    tween.Completed:Connect(function()
        popup:Destroy()
    end)
end


----------------------------------------------------------------------
-- TAUNT INPUT
----------------------------------------------------------------------

local function performTaunt()
    if not canTaunt then return end
    if isTaunting then return end
    if myRole ~= "Hider" then return end

    local taunt = availableTaunts[selectedTauntIndex]
    if not taunt then return end

    isTaunting = true
    showTauntFlash()

    -- Send to server
    TauntPerformed:FireServer({
        tauntId = taunt.id,
    })
end

local function cycleTaunt(direction)
    selectedTauntIndex += direction
    if selectedTauntIndex > #availableTaunts then
        selectedTauntIndex = 1
    elseif selectedTauntIndex < 1 then
        selectedTauntIndex = #availableTaunts
    end
    local taunt = availableTaunts[selectedTauntIndex]
    print("[TauntClient] Selected taunt:", taunt.name)
end

----------------------------------------------------------------------
-- INPUT HANDLING
----------------------------------------------------------------------

local function onInputBegan(input, gameProcessed)
    if gameProcessed then return end
    if myRole ~= "Hider" then return end
    if not canTaunt then return end

    if input.UserInputType == Enum.UserInputType.Keyboard then
        -- G key to perform taunt
        if input.KeyCode == Enum.KeyCode.G then
            performTaunt()
        end

        -- Tab to cycle taunts (hold shift for reverse)
        if input.KeyCode == Enum.KeyCode.Tab then
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                cycleTaunt(-1)
            else
                cycleTaunt(1)
            end
        end
    end
end

----------------------------------------------------------------------
-- SERVER RESPONSES
----------------------------------------------------------------------

TauntPerformed.OnClientEvent:Connect(function(data)
    if not data then return end

    -- Response to our own taunt request
    if data.status == "DENIED" then
        isTaunting = false
        print("[TauntClient] Taunt denied:", data.reason)
        return
    end

    if data.status == "COMPLETE" then
        isTaunting = false
        showPointsPopup(data.pointsEarned or 25)
        print("[TauntClient] Taunt complete! +" .. (data.pointsEarned or 25) .. " points!")
        return
    end

    -- Broadcast: another player is taunting (show indicator)
    if data.playerName then
        local targetPlayer = Players:FindFirstChild(data.playerName)
        if targetPlayer and targetPlayer.Character then
            createTauntIndicator(targetPlayer.Character, data.duration or 2)
        end
    end
end)

----------------------------------------------------------------------
-- ROUND STATE
----------------------------------------------------------------------

RoleAssigned.OnClientEvent:Connect(function(role)
    myRole = role
    canTaunt = false
    isTaunting = false
end)

RoundStateChanged.OnClientEvent:Connect(function(state, data)
    if state == "SeekPhase" and myRole == "Hider" then
        canTaunt = true
        print("[TauntClient] Taunts enabled! Press G to taunt (risky for bonus points). Tab to switch taunt.")
    else
        canTaunt = false
        isTaunting = false
    end
end)

----------------------------------------------------------------------
-- CONNECT
----------------------------------------------------------------------

UserInputService.InputBegan:Connect(onInputBegan)

print("[TauntClient] Taunt system loaded. G=Taunt, Tab=Cycle taunts")
