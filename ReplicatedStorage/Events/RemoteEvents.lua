--[[
    RemoteEvents.lua
    Place this in ReplicatedStorage/Events
    Creates all RemoteEvents and RemoteFunctions used by the game.
    Run once on the server to initialize.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local eventsFolder = ReplicatedStorage:FindFirstChild("Events") or Instance.new("Folder")
eventsFolder.Name = "Events"
eventsFolder.Parent = ReplicatedStorage

-- List of RemoteEvents
local remoteEvents = {
    "RoundStateChanged",      -- Server -> Client: notify round state changes
    "RoleAssigned",           -- Server -> Client: tell player their role
    "PaintCharacter",         -- Client -> Server: request to paint a body part
    "FreezeCharacter",        -- Client -> Server: request to freeze/unfreeze
    "SeekerTag",              -- Client -> Server: seeker tags a hider
    "SeekerAbility",          -- Client -> Server: seeker uses detection ability
    "HighlightHider",         -- Server -> Client: briefly highlight a hider for seeker
    "TauntPerformed",         -- Client -> Server: hider performs a taunt
    "ScoreUpdate",            -- Server -> Client: update player scores
    "TimerSync",              -- Server -> Client: sync round timer
    "PlayerEliminated",       -- Server -> Client: notify a hider was found
    "GameOver",               -- Server -> Client: round results
    "TeleportPlayer",         -- Server -> Client: teleport to map/lobby
}

-- List of RemoteFunctions
local remoteFunctions = {
    "GetColorPalette",        -- Client -> Server: get available colors for current map
    "GetPlayerScore",         -- Client -> Server: get current score data
}

-- Create RemoteEvents
for _, eventName in ipairs(remoteEvents) do
    if not eventsFolder:FindFirstChild(eventName) then
        local event = Instance.new("RemoteEvent")
        event.Name = eventName
        event.Parent = eventsFolder
    end
end

-- Create RemoteFunctions
for _, funcName in ipairs(remoteFunctions) do
    if not eventsFolder:FindFirstChild(funcName) then
        local func = Instance.new("RemoteFunction")
        func.Name = funcName
        func.Parent = eventsFolder
    end
end

print("[Chameleon] Remote events initialized.")
return eventsFolder
