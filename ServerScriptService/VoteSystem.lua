--[[
    VoteSystem.lua (Script)
    Server-side map voting system.
    During lobby, presents 3 random maps for players to vote on.
    The map with the most votes wins.
    Place in ServerScriptService.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Events = ReplicatedStorage:WaitForChild("Events")

local VoteSystem = {}

----------------------------------------------------------------------
-- STATE
----------------------------------------------------------------------

VoteSystem.IsVoting = false
VoteSystem.VoteOptions = {}     -- {mapName, mapName, mapName}
VoteSystem.PlayerVotes = {}     -- {[Player] = mapIndex (1,2,3)}
VoteSystem.VoteCounts = {}      -- {[1] = count, [2] = count, [3] = count}
VoteSystem.WinningMap = nil

-- All available maps for voting
VoteSystem.AllMaps = {
    {
        name = "School",
        displayName = "School Classroom",
        icon = "📚",
        description = "Desks, bookshelves, and a chalkboard",
    },
    {
        name = "Supermarket",
        displayName = "Supermarket",
        icon = "🛒",
        description = "Aisles of colorful products",
    },
    {
        name = "Bedroom",
        displayName = "Giant Bedroom",
        icon = "🛏️",
        description = "You're tiny! Hide under the bed",
    },
    {
        name = "Construction",
        displayName = "Construction Site",
        icon = "🏗️",
        description = "Scaffolding, pipes, and dirt piles",
    },

    {
        name = "Aquarium",
        displayName = "Aquarium",
        icon = "🐠",
        description = "Glass tanks, coral, and dark walkways",
    },
    {
        name = "HauntedHouse",
        displayName = "Haunted House",
        icon = "👻",
        description = "Dark rooms, cobwebs, and a coffin",
    },
}

----------------------------------------------------------------------
-- VOTING LOGIC
----------------------------------------------------------------------

-- Pick 3 random maps from the pool
function VoteSystem.PickRandomMaps()
    local available = {}
    for i, map in ipairs(VoteSystem.AllMaps) do
        table.insert(available, i)
    end

    -- Shuffle and pick 3
    local picked = {}
    for i = 1, math.min(3, #available) do
        local idx = math.random(1, #available)
        table.insert(picked, VoteSystem.AllMaps[available[idx]])
        table.remove(available, idx)
    end

    return picked
end

-- Start a new vote
function VoteSystem.StartVote()
    VoteSystem.IsVoting = true
    VoteSystem.PlayerVotes = {}
    VoteSystem.VoteCounts = {0, 0, 0}
    VoteSystem.WinningMap = nil

    -- Pick 3 random maps
    local options = VoteSystem.PickRandomMaps()
    VoteSystem.VoteOptions = options

    -- Send vote options to all clients
    local voteData = {}
    for i, option in ipairs(options) do
        voteData[i] = {
            name = option.name,
            displayName = option.displayName,
            icon = option.icon,
            description = option.description,
            votes = 0,
        }
    end

    Events.VoteStart:FireAllClients(voteData)
    print("[VoteSystem] Vote started with options:", options[1].name, options[2].name, options[3].name)
end


-- Handle a player's vote
function VoteSystem.CastVote(player, mapIndex)
    if not VoteSystem.IsVoting then return end
    if mapIndex < 1 or mapIndex > #VoteSystem.VoteOptions then return end

    -- Remove previous vote if they already voted
    local previousVote = VoteSystem.PlayerVotes[player]
    if previousVote then
        VoteSystem.VoteCounts[previousVote] = math.max(0, VoteSystem.VoteCounts[previousVote] - 1)
    end

    -- Cast new vote
    VoteSystem.PlayerVotes[player] = mapIndex
    VoteSystem.VoteCounts[mapIndex] = (VoteSystem.VoteCounts[mapIndex] or 0) + 1

    -- Broadcast updated vote counts to all clients
    Events.VoteUpdate:FireAllClients(VoteSystem.VoteCounts)

    print("[VoteSystem]", player.Name, "voted for", VoteSystem.VoteOptions[mapIndex].name)
end

-- End the vote and determine winner
function VoteSystem.EndVote()
    VoteSystem.IsVoting = false

    -- Find the map with most votes
    local maxVotes = 0
    local winnerIndex = 1

    for i, count in ipairs(VoteSystem.VoteCounts) do
        if count > maxVotes then
            maxVotes = count
            winnerIndex = i
        end
    end

    -- If tie or no votes, pick randomly from tied options
    local tiedOptions = {}
    for i, count in ipairs(VoteSystem.VoteCounts) do
        if count == maxVotes then
            table.insert(tiedOptions, i)
        end
    end
    winnerIndex = tiedOptions[math.random(1, #tiedOptions)]

    VoteSystem.WinningMap = VoteSystem.VoteOptions[winnerIndex].name

    -- Notify all clients of the winner
    Events.VoteEnd:FireAllClients({
        winnerIndex = winnerIndex,
        winnerName = VoteSystem.VoteOptions[winnerIndex].displayName,
        winnerIcon = VoteSystem.VoteOptions[winnerIndex].icon,
        mapName = VoteSystem.WinningMap,
    })

    print("[VoteSystem] Vote ended! Winner:", VoteSystem.WinningMap, "with", maxVotes, "votes")
    return VoteSystem.WinningMap
end

-- Get the winning map name (called by RoundManager)
function VoteSystem.GetWinningMap()
    return VoteSystem.WinningMap or VoteSystem.AllMaps[math.random(1, #VoteSystem.AllMaps)].name
end

-- Reset for next round
function VoteSystem.Reset()
    VoteSystem.IsVoting = false
    VoteSystem.VoteOptions = {}
    VoteSystem.PlayerVotes = {}
    VoteSystem.VoteCounts = {0, 0, 0}
    VoteSystem.WinningMap = nil
end


----------------------------------------------------------------------
-- EVENT CONNECTIONS
----------------------------------------------------------------------

-- Listen for player votes
Events.CastVote.OnServerEvent:Connect(function(player, mapIndex)
    VoteSystem.CastVote(player, mapIndex)
end)

-- Clean up when player leaves during vote
Players.PlayerRemoving:Connect(function(player)
    if VoteSystem.IsVoting and VoteSystem.PlayerVotes[player] then
        local idx = VoteSystem.PlayerVotes[player]
        VoteSystem.VoteCounts[idx] = math.max(0, VoteSystem.VoteCounts[idx] - 1)
        VoteSystem.PlayerVotes[player] = nil
        -- Update everyone
        Events.VoteUpdate:FireAllClients(VoteSystem.VoteCounts)
    end
end)

print("[VoteSystem] Vote system initialized")

return VoteSystem
