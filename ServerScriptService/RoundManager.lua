--[[
    RoundManager.lua (ServerScript)
    The core game loop: Lobby -> PrepPhase -> HidePhase -> SeekPhase -> Results
    Handles role assignment, timers, transitions, and win conditions.
    Place in ServerScriptService.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

-- Modules
local GameConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameConfig"))

-- Wait for events to be initialized
local Events = ReplicatedStorage:WaitForChild("Events")
local RoundStateChanged = Events:WaitForChild("RoundStateChanged")
local RoleAssigned = Events:WaitForChild("RoleAssigned")
local TimerSync = Events:WaitForChild("TimerSync")
local PlayerEliminated = Events:WaitForChild("PlayerEliminated")
local GameOver = Events:WaitForChild("GameOver")
local ScoreUpdate = Events:WaitForChild("ScoreUpdate")
local SeekerTag = Events:WaitForChild("SeekerTag")

----------------------------------------------------------------------
-- STATE
----------------------------------------------------------------------

local RoundManager = {}

-- Game states
RoundManager.States = {
    LOBBY = "Lobby",
    PREP = "PrepPhase",
    HIDE = "HidePhase",
    SEEK = "SeekPhase",
    RESULTS = "Results",
}

RoundManager.CurrentState = RoundManager.States.LOBBY
RoundManager.CurrentRound = 0
RoundManager.RoundActive = false

-- Player role tracking
RoundManager.Seekers = {}       -- {Player} list
RoundManager.Hiders = {}        -- {Player} list
RoundManager.Eliminated = {}    -- {Player} list (hiders that got tagged)
RoundManager.PlayerScores = {}  -- {[Player] = {points, coins}}

----------------------------------------------------------------------
-- UTILITY FUNCTIONS
----------------------------------------------------------------------

local function getActivePlayers()
    local players = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character and player.Character:FindFirstChild("Humanoid") then
            table.insert(players, player)
        end
    end
    return players
end

local function countAlivePlayers(list)
    local count = 0
    for _, player in ipairs(list) do
        if player and player.Parent and not table.find(RoundManager.Eliminated, player) then
            count += 1
        end
    end
    return count
end

local function broadcastState(state, data)
    RoundManager.CurrentState = state
    RoundStateChanged:FireAllClients(state, data or {})
    print("[RoundManager] State:", state)
end

local function countdownTimer(duration, label)
    for i = duration, 0, -1 do
        TimerSync:FireAllClients(i, label or RoundManager.CurrentState)
        task.wait(1)

        -- Check early termination during seek phase
        if RoundManager.CurrentState == RoundManager.States.SEEK then
            if countAlivePlayers(RoundManager.Hiders) <= 0 then
                return true -- All hiders found
            end
        end
    end
    return false
end

----------------------------------------------------------------------
-- ROLE ASSIGNMENT
----------------------------------------------------------------------

function RoundManager.AssignRoles(players)
    RoundManager.Seekers = {}
    RoundManager.Hiders = {}
    RoundManager.Eliminated = {}

    -- Determine number of seekers
    local numSeekers = math.max(1, math.ceil(#players * GameConfig.SeekerRatio))

    -- Shuffle players for random assignment
    local shuffled = {}
    for _, p in ipairs(players) do
        table.insert(shuffled, p)
    end
    for i = #shuffled, 2, -1 do
        local j = math.random(1, i)
        shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
    end

    -- Assign roles
    for i, player in ipairs(shuffled) do
        if i <= numSeekers then
            table.insert(RoundManager.Seekers, player)
            RoleAssigned:FireClient(player, "Seeker")
        else
            table.insert(RoundManager.Hiders, player)
            RoleAssigned:FireClient(player, "Hider")
        end
    end

    print("[RoundManager] Assigned", #RoundManager.Seekers, "Seekers and", #RoundManager.Hiders, "Hiders")
end

----------------------------------------------------------------------
-- SCORING
----------------------------------------------------------------------

function RoundManager.InitScores(players)
    for _, player in ipairs(players) do
        if not RoundManager.PlayerScores[player] then
            RoundManager.PlayerScores[player] = { points = 0, coins = 0 }
        end
    end
end

function RoundManager.AwardPoints(player, amount, reason)
    if not RoundManager.PlayerScores[player] then
        RoundManager.PlayerScores[player] = { points = 0, coins = 0 }
    end
    RoundManager.PlayerScores[player].points += amount
    RoundManager.PlayerScores[player].coins += math.floor(amount * GameConfig.CoinsPerPoint)

    ScoreUpdate:FireClient(player, RoundManager.PlayerScores[player], reason or "")
end

function RoundManager.GetLeaderboard()
    local leaderboard = {}
    for player, data in pairs(RoundManager.PlayerScores) do
        if player and player.Parent then
            table.insert(leaderboard, {
                name = player.Name,
                points = data.points,
                coins = data.coins,
            })
        end
    end
    table.sort(leaderboard, function(a, b) return a.points > b.points end)
    return leaderboard
end

----------------------------------------------------------------------
-- ELIMINATION (Seeker Tags Hider)
----------------------------------------------------------------------

function RoundManager.EliminateHider(seeker, hider)
    if not table.find(RoundManager.Hiders, hider) then return end
    if table.find(RoundManager.Eliminated, hider) then return end

    table.insert(RoundManager.Eliminated, hider)

    -- Award seeker
    RoundManager.AwardPoints(seeker, GameConfig.PointsPerTag, "Tagged " .. hider.Name)

    -- Notify all clients
    PlayerEliminated:FireAllClients(hider.Name, seeker.Name)

    -- Make the hider's character transparent or teleport to spectator
    if hider.Character then
        local humanoid = hider.Character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.Health = 0 -- Respawn as spectator
        end
    end

    print("[RoundManager]", seeker.Name, "tagged", hider.Name)
end

----------------------------------------------------------------------
-- ROUND PHASES
----------------------------------------------------------------------

function RoundManager.LobbyPhase()
    broadcastState(RoundManager.States.LOBBY)

    -- Wait for minimum players
    while #Players:GetPlayers() < GameConfig.MinPlayers do
        TimerSync:FireAllClients(-1, "Waiting for " .. GameConfig.MinPlayers .. " players...")
        task.wait(2)
    end

    -- Countdown in lobby
    countdownTimer(GameConfig.LobbyWaitTime, "Round starting in...")
end

function RoundManager.PrepPhase(players)
    broadcastState(RoundManager.States.PREP, {
        seekers = RoundManager.Seekers,
        hiders = RoundManager.Hiders,
    })

    -- During prep phase:
    -- Hiders can paint themselves
    -- Seekers are blinded / held in a separate area
    for _, seeker in ipairs(RoundManager.Seekers) do
        if seeker.Character then
            -- Blind seekers (handled client-side via RoundStateChanged)
            -- Optionally teleport to seeker waiting area
        end
    end

    countdownTimer(GameConfig.PrepPhaseTime, "Paint yourself!")
end

function RoundManager.HidePhase()
    broadcastState(RoundManager.States.HIDE)

    -- Hiders have extra time to find their hiding spot
    -- Paint is disabled, only movement and freezing allowed
    countdownTimer(GameConfig.HidePhaseTime, "Find your spot!")
end

function RoundManager.SeekPhase()
    broadcastState(RoundManager.States.SEEK)

    -- Release seekers - they can now see and move
    -- Start awarding survival points to hiders
    local survivalTask = task.spawn(function()
        while RoundManager.CurrentState == RoundManager.States.SEEK do
            task.wait(1)
            for _, hider in ipairs(RoundManager.Hiders) do
                if not table.find(RoundManager.Eliminated, hider) then
                    RoundManager.AwardPoints(hider, GameConfig.PointsPerSecondAlive, "")
                end
            end
        end
    end)

    -- Countdown - returns true if all hiders found early
    local allFound = countdownTimer(GameConfig.SeekPhaseTime, "Find the Chameleons!")

    -- Award survival bonus to remaining hiders
    for _, hider in ipairs(RoundManager.Hiders) do
        if not table.find(RoundManager.Eliminated, hider) then
            RoundManager.AwardPoints(hider, GameConfig.PointsPerSurvive, "Survived the round!")
        end
    end
end

function RoundManager.ResultsPhase()
    local allFound = countAlivePlayers(RoundManager.Hiders) <= 0
    local results = {
        seekersWin = allFound,
        hidersWin = not allFound,
        leaderboard = RoundManager.GetLeaderboard(),
        seekers = RoundManager.Seekers,
        hiders = RoundManager.Hiders,
        eliminated = RoundManager.Eliminated,
    }

    broadcastState(RoundManager.States.RESULTS, results)
    GameOver:FireAllClients(results)

    countdownTimer(GameConfig.ResultsTime, "Next round starting...")
end

----------------------------------------------------------------------
-- MAIN GAME LOOP
----------------------------------------------------------------------

function RoundManager.StartGameLoop()
    print("[RoundManager] Game loop started!")

    while true do
        -- LOBBY PHASE
        RoundManager.LobbyPhase()

        -- Get active players and assign roles
        local players = getActivePlayers()
        if #players >= GameConfig.MinPlayers then
            RoundManager.CurrentRound += 1
            RoundManager.RoundActive = true
            RoundManager.InitScores(players)
            RoundManager.AssignRoles(players)

            -- PREP PHASE - Hiders paint themselves
            RoundManager.PrepPhase(players)

            -- HIDE PHASE - Hiders find a spot, seekers still blinded
            RoundManager.HidePhase()

            -- SEEK PHASE - Seekers released, hunt for hiders
            RoundManager.SeekPhase()

            -- RESULTS PHASE - Show scores and winners
            RoundManager.ResultsPhase()

            RoundManager.RoundActive = false
        else
            task.wait(3) -- Not enough players, wait and retry
        end
    end
end

----------------------------------------------------------------------
-- EVENT CONNECTIONS
----------------------------------------------------------------------

-- Seeker tagging a hider
SeekerTag.OnServerEvent:Connect(function(seeker, targetPlayer)
    if RoundManager.CurrentState ~= RoundManager.States.SEEK then return end
    if not table.find(RoundManager.Seekers, seeker) then return end

    -- Validate distance
    if seeker.Character and targetPlayer and targetPlayer.Character then
        local seekerPos = seeker.Character:FindFirstChild("HumanoidRootPart")
        local targetPos = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
        if seekerPos and targetPos then
            local distance = (seekerPos.Position - targetPos.Position).Magnitude
            if distance <= GameConfig.TagDistance then
                RoundManager.EliminateHider(seeker, targetPlayer)
            end
        end
    end
end)

-- Clean up when player leaves
Players.PlayerRemoving:Connect(function(player)
    -- Remove from active lists
    local seekerIdx = table.find(RoundManager.Seekers, player)
    if seekerIdx then table.remove(RoundManager.Seekers, seekerIdx) end

    local hiderIdx = table.find(RoundManager.Hiders, player)
    if hiderIdx then table.remove(RoundManager.Hiders, hiderIdx) end

    -- Clean up scores (keep for session or remove)
    -- RoundManager.PlayerScores[player] = nil
end)

----------------------------------------------------------------------
-- START
----------------------------------------------------------------------

-- Initialize remote events first
require(ReplicatedStorage:WaitForChild("Events"):WaitForChild("RemoteEvents"))

-- Start the game loop
task.spawn(RoundManager.StartGameLoop)

return RoundManager
