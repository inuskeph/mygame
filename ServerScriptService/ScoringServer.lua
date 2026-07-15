--[[
    ScoringServer.lua (ServerScript)
    Manages player scores, coins, persistent data saving, and leaderboard.
    Uses DataStoreService for persistence across sessions.
    Place in ServerScriptService.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

local GameConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameConfig"))

local Events = ReplicatedStorage:WaitForChild("Events")
local ScoreUpdate = Events:WaitForChild("ScoreUpdate")
local GetPlayerScore = Events:WaitForChild("GetPlayerScore")

----------------------------------------------------------------------
-- DATA STORE
----------------------------------------------------------------------

local playerDataStore = DataStoreService:GetDataStore("ChameleonPlayerData_v1")

----------------------------------------------------------------------
-- STATE
----------------------------------------------------------------------

local ScoringServer = {}

-- Session scores (reset each round)
ScoringServer.SessionScores = {} -- {[Player] = {points = 0, coins = 0}}

-- Persistent data (saved across sessions)
ScoringServer.PlayerData = {} -- {[Player] = {totalCoins, totalWins, gamesPlayed, ...}}

-- Default player data template
local DEFAULT_DATA = {
    totalCoins = 0,
    totalPoints = 0,
    totalWins = 0,
    totalTags = 0,
    totalSurvivals = 0,
    totalTaunts = 0,
    gamesPlayed = 0,
    highestRoundScore = 0,
    -- Unlockables
    unlockedPoses = { "Standing", "Crouching" },
    unlockedTaunts = { "Wave" },
    equippedTitle = "",
}

----------------------------------------------------------------------
-- DATA PERSISTENCE
----------------------------------------------------------------------

function ScoringServer.LoadPlayerData(player)
    local success, data = pcall(function()
        return playerDataStore:GetAsync("Player_" .. player.UserId)
    end)

    if success and data then
        ScoringServer.PlayerData[player] = data
        print("[Scoring] Loaded data for", player.Name)
    else
        -- New player or load failed, use defaults
        ScoringServer.PlayerData[player] = table.clone(DEFAULT_DATA)
        print("[Scoring] Created new data for", player.Name)
    end

    -- Initialize session scores
    ScoringServer.SessionScores[player] = { points = 0, coins = 0 }

    -- Set up leaderstats
    ScoringServer.CreateLeaderstats(player)
end

function ScoringServer.SavePlayerData(player)
    local data = ScoringServer.PlayerData[player]
    if not data then return end

    local success, err = pcall(function()
        playerDataStore:SetAsync("Player_" .. player.UserId, data)
    end)

    if success then
        print("[Scoring] Saved data for", player.Name)
    else
        warn("[Scoring] Failed to save data for", player.Name, ":", err)
    end
end

----------------------------------------------------------------------
-- LEADERSTATS (visible in Roblox player list)
----------------------------------------------------------------------

function ScoringServer.CreateLeaderstats(player)
    local leaderstats = Instance.new("Folder")
    leaderstats.Name = "leaderstats"
    leaderstats.Parent = player

    local coins = Instance.new("IntValue")
    coins.Name = "Coins"
    coins.Value = ScoringServer.PlayerData[player] and ScoringServer.PlayerData[player].totalCoins or 0
    coins.Parent = leaderstats

    local wins = Instance.new("IntValue")
    wins.Name = "Wins"
    wins.Value = ScoringServer.PlayerData[player] and ScoringServer.PlayerData[player].totalWins or 0
    wins.Parent = leaderstats
end

function ScoringServer.UpdateLeaderstats(player)
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then return end

    local data = ScoringServer.PlayerData[player]
    if not data then return end

    local coins = leaderstats:FindFirstChild("Coins")
    if coins then coins.Value = data.totalCoins end

    local wins = leaderstats:FindFirstChild("Wins")
    if wins then wins.Value = data.totalWins end
end

----------------------------------------------------------------------
-- SCORING API
----------------------------------------------------------------------

-- Award points during a round (session-based)
function ScoringServer.AwardPoints(player, amount, reason)
    if not player or not player.Parent then return end
    if amount <= 0 then return end

    -- Update session score
    if not ScoringServer.SessionScores[player] then
        ScoringServer.SessionScores[player] = { points = 0, coins = 0 }
    end
    ScoringServer.SessionScores[player].points += amount

    -- Calculate coins earned
    local coinsEarned = math.floor(amount * GameConfig.CoinsPerPoint)
    ScoringServer.SessionScores[player].coins += coinsEarned

    -- Update persistent data
    if ScoringServer.PlayerData[player] then
        ScoringServer.PlayerData[player].totalPoints += amount
        ScoringServer.PlayerData[player].totalCoins += coinsEarned
    end

    -- Update leaderstats
    ScoringServer.UpdateLeaderstats(player)

    -- Notify client
    ScoreUpdate:FireClient(player, {
        sessionPoints = ScoringServer.SessionScores[player].points,
        sessionCoins = ScoringServer.SessionScores[player].coins,
        totalCoins = ScoringServer.PlayerData[player] and ScoringServer.PlayerData[player].totalCoins or 0,
        reason = reason or "",
        pointsAwarded = amount,
        coinsAwarded = coinsEarned,
    })
end

-- Award coins directly (for purchases, bonuses, etc.)
function ScoringServer.AwardCoins(player, amount, reason)
    if not player or not player.Parent then return end
    if amount <= 0 then return end

    if ScoringServer.PlayerData[player] then
        ScoringServer.PlayerData[player].totalCoins += amount
    end

    ScoringServer.UpdateLeaderstats(player)

    ScoreUpdate:FireClient(player, {
        sessionPoints = ScoringServer.SessionScores[player] and ScoringServer.SessionScores[player].points or 0,
        sessionCoins = (ScoringServer.SessionScores[player] and ScoringServer.SessionScores[player].coins or 0) + amount,
        totalCoins = ScoringServer.PlayerData[player] and ScoringServer.PlayerData[player].totalCoins or 0,
        reason = reason or "Bonus",
        pointsAwarded = 0,
        coinsAwarded = amount,
    })
end

-- Spend coins (returns true if successful, false if not enough)
function ScoringServer.SpendCoins(player, amount)
    if not player then return false end
    local data = ScoringServer.PlayerData[player]
    if not data then return false end
    if data.totalCoins < amount then return false end

    data.totalCoins -= amount
    ScoringServer.UpdateLeaderstats(player)
    return true
end

-- Record a win
function ScoringServer.RecordWin(player)
    if not player then return end
    local data = ScoringServer.PlayerData[player]
    if not data then return end

    data.totalWins += 1
    ScoringServer.UpdateLeaderstats(player)
end

-- Record a tag (for seekers)
function ScoringServer.RecordTag(player)
    if not player then return end
    local data = ScoringServer.PlayerData[player]
    if not data then return end
    data.totalTags += 1
end

-- Record a survival (for hiders)
function ScoringServer.RecordSurvival(player)
    if not player then return end
    local data = ScoringServer.PlayerData[player]
    if not data then return end
    data.totalSurvivals += 1
end

-- Record a successful taunt
function ScoringServer.RecordTaunt(player)
    if not player then return end
    local data = ScoringServer.PlayerData[player]
    if not data then return end
    data.totalTaunts += 1
end

-- Record game played
function ScoringServer.RecordGamePlayed(player)
    if not player then return end
    local data = ScoringServer.PlayerData[player]
    if not data then return end
    data.gamesPlayed += 1
end

----------------------------------------------------------------------
-- ROUND MANAGEMENT
----------------------------------------------------------------------

-- Reset session scores for a new round
function ScoringServer.ResetRoundScores()
    for player, _ in pairs(ScoringServer.SessionScores) do
        ScoringServer.SessionScores[player] = { points = 0, coins = 0 }
    end
end

-- End-of-round processing
function ScoringServer.ProcessRoundEnd(seekersWin, seekers, hiders, eliminated)
    -- Record games played
    for _, player in ipairs(seekers) do
        ScoringServer.RecordGamePlayed(player)
    end
    for _, player in ipairs(hiders) do
        ScoringServer.RecordGamePlayed(player)
    end

    -- Award win bonuses
    if seekersWin then
        for _, seeker in ipairs(seekers) do
            ScoringServer.RecordWin(seeker)
            ScoringServer.AwardPoints(seeker, 50, "Seekers Win Bonus!")
        end
    else
        -- Hiders who survived win
        for _, hider in ipairs(hiders) do
            if not table.find(eliminated, hider) then
                ScoringServer.RecordWin(hider)
                ScoringServer.RecordSurvival(hider)
            end
        end
    end

    -- Update highest round scores
    for player, scores in pairs(ScoringServer.SessionScores) do
        local data = ScoringServer.PlayerData[player]
        if data and scores.points > data.highestRoundScore then
            data.highestRoundScore = scores.points
        end
    end

    -- Save all player data
    for _, player in ipairs(Players:GetPlayers()) do
        ScoringServer.SavePlayerData(player)
    end
end

-- Get session leaderboard
function ScoringServer.GetLeaderboard()
    local leaderboard = {}
    for player, scores in pairs(ScoringServer.SessionScores) do
        if player and player.Parent then
            table.insert(leaderboard, {
                name = player.Name,
                displayName = player.DisplayName,
                points = scores.points,
                coins = scores.coins,
            })
        end
    end
    table.sort(leaderboard, function(a, b) return a.points > b.points end)
    return leaderboard
end

----------------------------------------------------------------------
-- UNLOCKABLES SHOP
----------------------------------------------------------------------

ScoringServer.Shop = {
    poses = {
        { id = "TShaped", name = "T-Pose", cost = 100 },
        { id = "Sitting", name = "Sitting", cost = 150 },
        { id = "Lying", name = "Lying Down", cost = 200 },
        { id = "WallLean", name = "Wall Lean", cost = 250 },
        { id = "Statue", name = "Statue", cost = 500 },
        { id = "Dabbing", name = "Dab", cost = 300 },
    },
    taunts = {
        { id = "Dance", name = "Dance", cost = 200 },
        { id = "Laugh", name = "Laugh", cost = 150 },
        { id = "Spin", name = "Spin", cost = 300 },
        { id = "Flex", name = "Flex", cost = 250 },
    },
}

function ScoringServer.PurchaseItem(player, category, itemId)
    local data = ScoringServer.PlayerData[player]
    if not data then return false, "No player data" end

    -- Find item in shop
    local shopCategory = ScoringServer.Shop[category]
    if not shopCategory then return false, "Invalid category" end

    local item = nil
    for _, shopItem in ipairs(shopCategory) do
        if shopItem.id == itemId then
            item = shopItem
            break
        end
    end

    if not item then return false, "Item not found" end

    -- Check if already owned
    local ownedList = category == "poses" and data.unlockedPoses or data.unlockedTaunts
    if table.find(ownedList, itemId) then
        return false, "Already owned"
    end

    -- Check and spend coins
    if not ScoringServer.SpendCoins(player, item.cost) then
        return false, "Not enough coins"
    end

    -- Add to unlocked items
    table.insert(ownedList, itemId)
    ScoringServer.SavePlayerData(player)

    return true, "Purchased!"
end

----------------------------------------------------------------------
-- REMOTE FUNCTION
----------------------------------------------------------------------

GetPlayerScore.OnServerInvoke = function(player)
    return {
        session = ScoringServer.SessionScores[player] or { points = 0, coins = 0 },
        persistent = ScoringServer.PlayerData[player] or DEFAULT_DATA,
        leaderboard = ScoringServer.GetLeaderboard(),
    }
end

----------------------------------------------------------------------
-- PLAYER CONNECTIONS (called automatically when module loads)
----------------------------------------------------------------------

Players.PlayerAdded:Connect(function(player)
    ScoringServer.LoadPlayerData(player)
end)

Players.PlayerRemoving:Connect(function(player)
    ScoringServer.SavePlayerData(player)
    ScoringServer.SessionScores[player] = nil
    ScoringServer.PlayerData[player] = nil
end)

-- Load data for players already in game (in case module loads late)
for _, player in ipairs(Players:GetPlayers()) do
    if not ScoringServer.PlayerData[player] then
        task.spawn(function()
            ScoringServer.LoadPlayerData(player)
        end)
    end
end

-- Auto-save every 5 minutes
task.spawn(function()
    while true do
        task.wait(300)
        for _, player in ipairs(Players:GetPlayers()) do
            ScoringServer.SavePlayerData(player)
        end
        print("[Scoring] Auto-saved all player data")
    end
end)

-- Save all on game close
game:BindToClose(function()
    for _, player in ipairs(Players:GetPlayers()) do
        ScoringServer.SavePlayerData(player)
    end
end)

print("[ScoringServer] Scoring system loaded - DataStore saving enabled")

return ScoringServer
