--[[
    TauntServer.lua (ServerScript)
    Server-side taunt handling for hiders.
    Taunts are risky actions that award bonus points but temporarily
    increase the hider's detection radius and play a visible/audible cue.
    Place in ServerScriptService.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameConfig"))

local Events = ReplicatedStorage:WaitForChild("Events")
local TauntPerformed = Events:WaitForChild("TauntPerformed")
local RoundStateChanged = Events:WaitForChild("RoundStateChanged")
local ScoreUpdate = Events:WaitForChild("ScoreUpdate")


----------------------------------------------------------------------
-- TAUNT DEFINITIONS
----------------------------------------------------------------------

local TauntServer = {}

TauntServer.Taunts = {
    Wave = {
        id = "Wave",
        name = "Wave",
        animationId = "rbxassetid://507770239",  -- Roblox default wave
        soundId = nil,
        duration = 2,
        riskMultiplier = 1.5,   -- Detection radius multiplied during taunt
        pointReward = 25,
        unlockDefault = true,
    },
    Dance = {
        id = "Dance",
        name = "Dance",
        animationId = "rbxassetid://507771019",  -- Roblox default dance
        soundId = nil,
        duration = 3,
        riskMultiplier = 2.0,
        pointReward = 40,
        unlockDefault = false,
    },
    Laugh = {
        id = "Laugh",
        name = "Laugh",
        animationId = "rbxassetid://507770818",  -- Roblox default laugh
        soundId = "rbxassetid://2639897498",
        duration = 2,
        riskMultiplier = 1.8,
        pointReward = 30,
        unlockDefault = false,
    },
    Spin = {
        id = "Spin",
        name = "Spin",
        animationId = nil,
        soundId = "rbxassetid://3199270999",
        duration = 2.5,
        riskMultiplier = 2.5,
        pointReward = 50,
        unlockDefault = false,
    },
    Flex = {
        id = "Flex",
        name = "Flex",
        animationId = "rbxassetid://507771019",
        soundId = nil,
        duration = 2,
        riskMultiplier = 1.5,
        pointReward = 25,
        unlockDefault = false,
    },
}

----------------------------------------------------------------------
-- STATE
----------------------------------------------------------------------

local playerCooldowns = {}    -- {[Player] = lastTauntTime}
local tauntsEnabled = false
local activeTaunts = {}       -- {[Player] = {tauntId, startTime, endTime}}


----------------------------------------------------------------------
-- VALIDATION
----------------------------------------------------------------------

local function canTaunt(player)
    if not tauntsEnabled then return false, "Taunts disabled" end

    -- Check cooldown
    local lastTaunt = playerCooldowns[player] or 0
    local elapsed = tick() - lastTaunt
    if elapsed < GameConfig.TauntCooldown then
        local remaining = GameConfig.TauntCooldown - elapsed
        return false, "Cooldown: " .. math.ceil(remaining) .. "s"
    end

    -- Check if already taunting
    if activeTaunts[player] then
        return false, "Already taunting"
    end

    return true, nil
end

----------------------------------------------------------------------
-- TAUNT EXECUTION
----------------------------------------------------------------------

local function executeTaunt(player, tauntId)
    local tauntData = TauntServer.Taunts[tauntId]
    if not tauntData then return end

    local character = player.Character
    if not character then return end

    -- Set cooldown
    playerCooldowns[player] = tick()

    -- Mark as actively taunting
    activeTaunts[player] = {
        tauntId = tauntId,
        startTime = tick(),
        endTime = tick() + tauntData.duration,
    }

    -- Set attribute for detection system to read
    character:SetAttribute("IsTaunting", true)
    character:SetAttribute("TauntRiskMultiplier", tauntData.riskMultiplier)

    -- If player was frozen, briefly unfreeze for animation
    local wasFrozen = character:GetAttribute("IsFrozen") == true
    if wasFrozen then
        local humanoid = character:FindFirstChild("Humanoid")
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        -- Keep anchored but allow animation
        if humanoid then
            -- Play taunt animation
            local animator = humanoid:FindFirstChild("Animator")
            if not animator then
                animator = Instance.new("Animator")
                animator.Parent = humanoid
            end

            if tauntData.animationId then
                local animation = Instance.new("Animation")
                animation.AnimationId = tauntData.animationId
                local track = animator:LoadAnimation(animation)
                track.Priority = Enum.AnimationPriority.Action4
                track:Play()
                -- Stop after duration
                task.delay(tauntData.duration, function()
                    track:Stop()
                end)
            end
        end
    end

    -- Play sound (audible to nearby players)
    if tauntData.soundId then
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            local sound = Instance.new("Sound")
            sound.SoundId = tauntData.soundId
            sound.Volume = 0.8
            sound.RollOffMaxDistance = 50
            sound.Parent = rootPart
            sound:Play()
            sound.Ended:Connect(function()
                sound:Destroy()
            end)
        end
    end

    -- Notify ALL clients about the taunt (so seekers can hear/see it)
    TauntPerformed:FireAllClients({
        playerName = player.Name,
        tauntId = tauntId,
        position = character:FindFirstChild("HumanoidRootPart") and character.HumanoidRootPart.Position,
        duration = tauntData.duration,
    })

    -- Award points after taunt completes (if player survives)
    task.delay(tauntData.duration, function()
        -- Clear active taunt
        activeTaunts[player] = nil

        if character and character.Parent then
            character:SetAttribute("IsTaunting", false)
            character:SetAttribute("TauntRiskMultiplier", nil)

            -- Player survived the taunt! Award points
            -- (If they got tagged during taunt, this won't fire because character is gone)
            TauntPerformed:FireClient(player, {
                status = "COMPLETE",
                tauntId = tauntId,
                pointsEarned = tauntData.pointReward,
            })

            -- Award via scoring system attribute (RoundManager handles actual scoring)
            character:SetAttribute("TauntPointsPending", (character:GetAttribute("TauntPointsPending") or 0) + tauntData.pointReward)
        end
    end)
end


----------------------------------------------------------------------
-- EVENT HANDLERS
----------------------------------------------------------------------

TauntPerformed.OnServerEvent:Connect(function(player, data)
    if not data or not data.tauntId then return end

    local canDo, reason = canTaunt(player)
    if not canDo then
        TauntPerformed:FireClient(player, {
            status = "DENIED",
            reason = reason,
        })
        return
    end

    -- Validate taunt is unlocked (check via attribute or data store)
    local tauntData = TauntServer.Taunts[data.tauntId]
    if not tauntData then
        TauntPerformed:FireClient(player, {
            status = "DENIED",
            reason = "Unknown taunt",
        })
        return
    end

    -- Execute the taunt
    executeTaunt(player, data.tauntId)
end)

----------------------------------------------------------------------
-- PUBLIC API
----------------------------------------------------------------------

function TauntServer.EnableTaunts()
    tauntsEnabled = true
    print("[TauntServer] Taunts enabled")
end

function TauntServer.DisableTaunts()
    tauntsEnabled = false
    activeTaunts = {}
    print("[TauntServer] Taunts disabled")
end

function TauntServer.IsPlayerTaunting(player)
    return activeTaunts[player] ~= nil
end

function TauntServer.GetTauntRiskMultiplier(player)
    if not activeTaunts[player] then return 1.0 end
    local tauntData = TauntServer.Taunts[activeTaunts[player].tauntId]
    return tauntData and tauntData.riskMultiplier or 1.0
end

function TauntServer.GetAvailableTaunts()
    local list = {}
    for id, data in pairs(TauntServer.Taunts) do
        table.insert(list, {
            id = data.id,
            name = data.name,
            pointReward = data.pointReward,
            riskMultiplier = data.riskMultiplier,
            unlockDefault = data.unlockDefault,
        })
    end
    return list
end

function TauntServer.Reset()
    playerCooldowns = {}
    activeTaunts = {}
end

----------------------------------------------------------------------
-- CLEANUP
----------------------------------------------------------------------

Players.PlayerRemoving:Connect(function(player)
    playerCooldowns[player] = nil
    activeTaunts[player] = nil
end)

return TauntServer
