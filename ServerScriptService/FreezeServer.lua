--[[
    FreezeServer.lua (ServerScript)
    Server-side freeze handling - validates and applies freeze requests.
    Place in ServerScriptService.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameConfig"))
local FreezeSystem = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("FreezeSystem"))

local Events = ReplicatedStorage:WaitForChild("Events")
local FreezeCharacter = Events:WaitForChild("FreezeCharacter")
local RoundStateChanged = Events:WaitForChild("RoundStateChanged")

----------------------------------------------------------------------
-- STATE
----------------------------------------------------------------------

local freezeEnabled = false   -- Can players freeze?
local frozenPlayers = {}      -- {[Player] = true}

----------------------------------------------------------------------
-- EVENT HANDLERS
----------------------------------------------------------------------

-- Handle freeze/unfreeze requests from client
FreezeCharacter.OnServerEvent:Connect(function(player, action, poseName)
    if not player.Character then return end

    if action == "FREEZE" then
        -- Validate: only during HidePhase and SeekPhase
        if not freezeEnabled then return end

        -- Apply pose first (if specified)
        if poseName and FreezeSystem.Poses[poseName] then
            FreezeSystem.ApplyPose(player.Character, poseName)
        end

        -- Freeze after a small delay (transition)
        task.delay(GameConfig.FreezeDelay, function()
            if player.Character then
                local success = FreezeSystem.Freeze(player.Character)
                if success then
                    frozenPlayers[player] = true
                    -- Confirm to client
                    FreezeCharacter:FireClient(player, "FROZEN", poseName)
                end
            end
        end)

    elseif action == "UNFREEZE" then
        -- Players can unfreeze anytime (but it risks detection!)
        if player.Character and FreezeSystem.IsFrozen(player.Character) then
            FreezeSystem.Unfreeze(player.Character)
            frozenPlayers[player] = nil
            FreezeCharacter:FireClient(player, "UNFROZEN")
        end

    elseif action == "POSE" then
        -- Change pose while frozen
        if player.Character and FreezeSystem.IsFrozen(player.Character) then
            -- Briefly unfreeze to change pose
            FreezeSystem.Unfreeze(player.Character)
            if poseName and FreezeSystem.Poses[poseName] then
                FreezeSystem.ApplyPose(player.Character, poseName)
            end
            -- Re-freeze
            task.delay(0.1, function()
                if player.Character then
                    FreezeSystem.Freeze(player.Character)
                    FreezeCharacter:FireClient(player, "POSE_CHANGED", poseName)
                end
            end)
        end
    end
end)

----------------------------------------------------------------------
-- PUBLIC API (called by RoundManager)
----------------------------------------------------------------------

local FreezeServer = {}

function FreezeServer.EnableFreezing()
    freezeEnabled = true
    print("[FreezeServer] Freezing enabled")
end

function FreezeServer.DisableFreezing()
    freezeEnabled = false
    -- Unfreeze all players
    for player, _ in pairs(frozenPlayers) do
        if player and player.Character then
            FreezeSystem.Unfreeze(player.Character)
        end
    end
    frozenPlayers = {}
    print("[FreezeServer] Freezing disabled, all players unfrozen")
end

function FreezeServer.IsPlayerFrozen(player)
    return frozenPlayers[player] == true
end

function FreezeServer.ResetAllPlayers()
    for player, _ in pairs(frozenPlayers) do
        if player and player.Character then
            FreezeSystem.ResetCharacter(player.Character)
        end
    end
    frozenPlayers = {}
end

----------------------------------------------------------------------
-- CLEANUP
----------------------------------------------------------------------

Players.PlayerRemoving:Connect(function(player)
    frozenPlayers[player] = nil
end)

-- Reset on round end
RoundStateChanged.Event = nil -- Tracked by RoundManager

return FreezeServer
