--[[
    SeekerAbilitiesServer.lua (ServerScript)
    Server-side handling of seeker abilities: detection pulse, tag, and highlight.
    Validates requests, checks cooldowns, and broadcasts results.
    Place in ServerScriptService.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameConfig"))
local FreezeSystem = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("FreezeSystem"))

local Events = ReplicatedStorage:WaitForChild("Events")
local SeekerAbility = Events:WaitForChild("SeekerAbility")
local SeekerTag = Events:WaitForChild("SeekerTag")
local HighlightHider = Events:WaitForChild("HighlightHider")
local PlayerEliminated = Events:WaitForChild("PlayerEliminated")

----------------------------------------------------------------------
-- STATE
----------------------------------------------------------------------

local seekerCooldowns = {}   -- {[Player] = {pulse = tick(), ...}}
local seekersActive = {}     -- {[Player] = true} -- who is currently a seeker
local hidersActive = {}      -- {[Player] = true} -- who is currently a hider
local eliminatedPlayers = {} -- {[Player] = true}

----------------------------------------------------------------------
-- UTILITY
----------------------------------------------------------------------

local function isSeeker(player)
    return seekersActive[player] == true
end

local function isHider(player)
    return hidersActive[player] == true
end

local function isEliminated(player)
    return eliminatedPlayers[player] == true
end

local function getCooldown(player, ability)
    if not seekerCooldowns[player] then return 0 end
    local lastUsed = seekerCooldowns[player][ability] or 0
    local elapsed = tick() - lastUsed
    local cooldownTime = 0

    if ability == "pulse" then
        cooldownTime = GameConfig.DetectionPulseCooldown
    end

    return math.max(0, cooldownTime - elapsed)
end

local function setCooldown(player, ability)
    if not seekerCooldowns[player] then
        seekerCooldowns[player] = {}
    end
    seekerCooldowns[player][ability] = tick()
end

----------------------------------------------------------------------
-- DETECTION PULSE
----------------------------------------------------------------------

local function performDetectionPulse(seeker)
    if not seeker.Character then return end
    local seekerRoot = seeker.Character:FindFirstChild("HumanoidRootPart")
    if not seekerRoot then return end

    local seekerPos = seekerRoot.Position
    local detectedHiders = {}

    -- Find hiders within pulse radius
    for player, _ in pairs(hidersActive) do
        if player and player.Character and not isEliminated(player) then
            local hiderRoot = player.Character:FindFirstChild("HumanoidRootPart")
            if hiderRoot then
                local distance = (seekerPos - hiderRoot.Position).Magnitude
                if distance <= GameConfig.DetectionPulseRadius then
                    -- Check if hider is frozen (frozen hiders are harder to detect)
                    local isFrozen = FreezeSystem.IsFrozen(player.Character)
                    local detectionChance = 1.0

                    if isFrozen then
                        -- Frozen hiders have reduced detection (based on camouflage)
                        detectionChance = 0.6 -- 60% chance to detect frozen hiders
                    end

                    if math.random() <= detectionChance then
                        table.insert(detectedHiders, {
                            player = player,
                            distance = distance,
                            position = hiderRoot.Position,
                        })
                    end
                end
            end
        end
    end

    -- Send highlight data to seeker
    for _, hiderData in ipairs(detectedHiders) do
        HighlightHider:FireClient(seeker, {
            playerName = hiderData.player.Name,
            position = hiderData.position,
            distance = hiderData.distance,
            duration = GameConfig.HighlightDuration,
        })
    end

    -- Return count for feedback
    return #detectedHiders
end

----------------------------------------------------------------------
-- TAG SYSTEM
----------------------------------------------------------------------

local function performTag(seeker, targetPlayer)
    -- Validate both players
    if not seeker or not targetPlayer then return false end
    if not isSeeker(seeker) then return false end
    if not isHider(targetPlayer) then return false end
    if isEliminated(targetPlayer) then return false end

    -- Validate distance
    if not seeker.Character or not targetPlayer.Character then return false end
    local seekerRoot = seeker.Character:FindFirstChild("HumanoidRootPart")
    local targetRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not seekerRoot or not targetRoot then return false end

    local distance = (seekerRoot.Position - targetRoot.Position).Magnitude
    if distance > GameConfig.TagDistance then return false end

    -- Tag successful!
    eliminatedPlayers[targetPlayer] = true

    -- Unfreeze the hider if frozen
    if FreezeSystem.IsFrozen(targetPlayer.Character) then
        FreezeSystem.Unfreeze(targetPlayer.Character)
    end

    -- Notify all clients
    PlayerEliminated:FireAllClients(targetPlayer.Name, seeker.Name)

    -- Send specific feedback to seeker
    SeekerAbility:FireClient(seeker, "TAG_SUCCESS", {
        targetName = targetPlayer.Name,
    })

    print("[SeekerAbilities]", seeker.Name, "tagged", targetPlayer.Name)
    return true
end

----------------------------------------------------------------------
-- EVENT HANDLERS
----------------------------------------------------------------------

-- Handle ability requests from seekers
SeekerAbility.OnServerEvent:Connect(function(player, abilityName, data)
    if not isSeeker(player) then return end

    if abilityName == "PULSE" then
        -- Check cooldown
        local remaining = getCooldown(player, "pulse")
        if remaining > 0 then
            SeekerAbility:FireClient(player, "COOLDOWN", {
                ability = "pulse",
                remaining = remaining,
            })
            return
        end

        -- Perform detection pulse
        setCooldown(player, "pulse")
        local detected = performDetectionPulse(player)

        -- Feedback to seeker
        SeekerAbility:FireClient(player, "PULSE_RESULT", {
            detected = detected,
        })

    elseif abilityName == "TAG" then
        -- Find target player from data
        local targetName = data and data.targetName
        if not targetName then return end

        local targetPlayer = Players:FindFirstChild(targetName)
        if targetPlayer then
            performTag(player, targetPlayer)
        end
    end
end)

-- Also handle the dedicated SeekerTag event (from RoundManager compatibility)
SeekerTag.OnServerEvent:Connect(function(seeker, targetPlayer)
    if not isSeeker(seeker) then return end
    if targetPlayer and typeof(targetPlayer) == "Instance" and targetPlayer:IsA("Player") then
        performTag(seeker, targetPlayer)
    end
end)

----------------------------------------------------------------------
-- PUBLIC API (called by RoundManager)
----------------------------------------------------------------------

local SeekerAbilitiesServer = {}

function SeekerAbilitiesServer.SetSeekers(seekerList)
    seekersActive = {}
    seekerCooldowns = {}
    for _, seeker in ipairs(seekerList) do
        seekersActive[seeker] = true
        seekerCooldowns[seeker] = {}
    end
    print("[SeekerAbilities] Registered", #seekerList, "seekers")
end

function SeekerAbilitiesServer.SetHiders(hiderList)
    hidersActive = {}
    eliminatedPlayers = {}
    for _, hider in ipairs(hiderList) do
        hidersActive[hider] = true
    end
    print("[SeekerAbilities] Registered", #hiderList, "hiders")
end

function SeekerAbilitiesServer.Reset()
    seekersActive = {}
    hidersActive = {}
    eliminatedPlayers = {}
    seekerCooldowns = {}
end

function SeekerAbilitiesServer.GetAliveHiderCount()
    local count = 0
    for player, _ in pairs(hidersActive) do
        if not isEliminated(player) and player.Parent then
            count += 1
        end
    end
    return count
end

function SeekerAbilitiesServer.IsEliminated(player)
    return isEliminated(player)
end

----------------------------------------------------------------------
-- CLEANUP
----------------------------------------------------------------------

Players.PlayerRemoving:Connect(function(player)
    seekersActive[player] = nil
    hidersActive[player] = nil
    eliminatedPlayers[player] = nil
    seekerCooldowns[player] = nil
end)

return SeekerAbilitiesServer
