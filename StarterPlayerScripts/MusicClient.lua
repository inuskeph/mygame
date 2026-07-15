--[[
    MusicClient.lua (LocalScript)
    Background music that changes per game phase.
    Smooth crossfade between tracks.
    Place in StarterPlayerScripts.
    
    HOW TO CHANGE MUSIC:
    Replace the "rbxassetid://NUMBER" with your own audio IDs.
    Go to Roblox Studio Toolbox > Audio > search for music > copy Asset ID.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Events = ReplicatedStorage:WaitForChild("Events")
local RoundStateChanged = Events:WaitForChild("RoundStateChanged")
local RoleAssigned = Events:WaitForChild("RoleAssigned")

local player = Players.LocalPlayer

----------------------------------------------------------------------
-- MUSIC CONFIGURATION
-- Replace these IDs with your own audio!
-- Find music: Toolbox > Audio > search keywords
----------------------------------------------------------------------

local MusicConfig = {
    Lobby = {
        id = "rbxassetid://1837849285",       -- Calm relaxing lobby
        volume = 0.3,
        pitch = 1,
    },
    PrepPhase = {
        id = "rbxassetid://1839888036",       -- Mysterious / getting ready
        volume = 0.35,
        pitch = 1,
    },
    HidePhase = {
        id = "rbxassetid://1839888036",       -- Tense (same as prep, faster)
        volume = 0.4,
        pitch = 1.15,
    },
    SeekPhase = {
        id = "rbxassetid://1836311602",       -- Intense chase / action
        volume = 0.45,
        pitch = 1,
    },
    Results = {
        id = "rbxassetid://1837849285",       -- Victory / celebration
        volume = 0.35,
        pitch = 1.1,
    },
}

local FADE_TIME = 1.2 -- Seconds for crossfade

----------------------------------------------------------------------
-- CREATE SOUND OBJECTS
----------------------------------------------------------------------

local sounds = {}
local currentSound = nil

for phaseName, config in pairs(MusicConfig) do
    local sound = Instance.new("Sound")
    sound.Name = "Music_" .. phaseName
    sound.SoundId = config.id
    sound.Volume = 0
    sound.PlaybackSpeed = config.pitch
    sound.Looped = true
    sound.Parent = SoundService
    sounds[phaseName] = {
        sound = sound,
        targetVolume = config.volume,
    }
end

----------------------------------------------------------------------
-- CROSSFADE LOGIC
----------------------------------------------------------------------

local function switchMusic(phaseName)
    local newData = sounds[phaseName]
    if not newData then return end
    if currentSound == newData.sound then return end

    -- Fade out current track
    if currentSound and currentSound.Playing then
        local oldSound = currentSound
        TweenService:Create(oldSound, TweenInfo.new(FADE_TIME), {
            Volume = 0
        }):Play()
        task.delay(FADE_TIME, function()
            oldSound:Stop()
        end)
    end

    -- Fade in new track
    local newSound = newData.sound
    newSound.Volume = 0
    newSound:Play()
    TweenService:Create(newSound, TweenInfo.new(FADE_TIME), {
        Volume = newData.targetVolume
    }):Play()

    currentSound = newSound
    print("[Music] Playing:", phaseName)
end

----------------------------------------------------------------------
-- LISTEN FOR GAME STATE CHANGES
----------------------------------------------------------------------

RoundStateChanged.OnClientEvent:Connect(function(state)
    if state == "Lobby" then
        switchMusic("Lobby")
    elseif state == "PrepPhase" then
        switchMusic("PrepPhase")
    elseif state == "HidePhase" then
        switchMusic("HidePhase")
    elseif state == "SeekPhase" then
        switchMusic("SeekPhase")
    elseif state == "Results" then
        switchMusic("Results")
    end
end)

----------------------------------------------------------------------
-- START WITH LOBBY MUSIC
----------------------------------------------------------------------

task.delay(1, function()
    switchMusic("Lobby")
end)

print("[MusicClient] Background music system loaded!")
print("[MusicClient] Replace audio IDs in this script to use your own music.")
