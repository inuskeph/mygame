--[[
    EventsInitializer.lua (Script)
    THIS MUST RUN FIRST - creates all RemoteEvents before other scripts need them.
    Place in ServerScriptService.
    
    IMPORTANT: In Roblox Studio, right-click this script > Properties > 
    Set RunContext to "Server" and make sure it has Priority loading.
    OR simply name it "!EventsInitializer" (the ! makes it load first alphabetically).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Create Events folder
local eventsFolder = Instance.new("Folder")
eventsFolder.Name = "Events"
eventsFolder.Parent = ReplicatedStorage

-- List of RemoteEvents
local remoteEvents = {
    "RoundStateChanged",
    "RoleAssigned",
    "PaintCharacter",
    "FreezeCharacter",
    "SeekerTag",
    "SeekerAbility",
    "HighlightHider",
    "TauntPerformed",
    "ScoreUpdate",
    "TimerSync",
    "PlayerEliminated",
    "GameOver",
    "TeleportPlayer",
}

-- List of RemoteFunctions
local remoteFunctions = {
    "GetColorPalette",
    "GetPlayerScore",
}

-- Create RemoteEvents
for _, eventName in ipairs(remoteEvents) do
    local event = Instance.new("RemoteEvent")
    event.Name = eventName
    event.Parent = eventsFolder
end

-- Create RemoteFunctions
for _, funcName in ipairs(remoteFunctions) do
    local func = Instance.new("RemoteFunction")
    func.Name = funcName
    func.Parent = eventsFolder
end

print("[Chameleon] All remote events created successfully!")
