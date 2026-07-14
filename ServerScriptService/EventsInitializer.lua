--[[
    EventsInitializer.lua (Script)
    THIS MUST RUN FIRST - creates all RemoteEvents before other scripts need them.
    Place in ServerScriptService.
    
    IMPORTANT IN ROBLOX STUDIO:
    1. Right-click this script in Explorer
    2. Go to Properties panel
    3. Find "RunContext" and set it to "Server"
    4. Find "Priority" or ensure this is the ONLY script that doesn't WaitForChild events
    
    ALTERNATIVE (RECOMMENDED): Instead of using this script, manually create the
    Events folder and all RemoteEvents in Roblox Studio Explorer:
    - Right-click ReplicatedStorage > Insert Object > Folder (name it "Events")
    - Inside Events folder, insert 13 RemoteEvents and 2 RemoteFunctions
    See the list below for names.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Create or find Events folder
local eventsFolder = ReplicatedStorage:FindFirstChild("Events")
if not eventsFolder then
    eventsFolder = Instance.new("Folder")
    eventsFolder.Name = "Events"
    eventsFolder.Parent = ReplicatedStorage
end

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
    -- Voting system events
    "VoteStart",
    "VoteUpdate",
    "VoteEnd",
    "CastVote",
}

-- List of RemoteFunctions
local remoteFunctions = {
    "GetColorPalette",
    "GetPlayerScore",
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

-- Signal that events are ready (other scripts can check this attribute)
eventsFolder:SetAttribute("Ready", true)

print("[Chameleon] All remote events created successfully!")
