--[[
    PaintServer.lua (ServerScript)
    Handles server-side validation and application of paint requests.
    Manages paint charges per player per round.
    Place in ServerScriptService.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameConfig"))
local PaintSystem = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PaintSystem"))

local Events = ReplicatedStorage:WaitForChild("Events")
local PaintCharacter = Events:WaitForChild("PaintCharacter")
local GetColorPalette = Events:WaitForChild("GetColorPalette")

----------------------------------------------------------------------
-- STATE
----------------------------------------------------------------------

local playerPaintCharges = {} -- {[Player] = remaining charges}
local currentMapName = GameConfig.DefaultMap
local paintingEnabled = false

----------------------------------------------------------------------
-- PAINT CHARGE MANAGEMENT
----------------------------------------------------------------------

local function resetCharges(player)
    playerPaintCharges[player] = GameConfig.MaxPaintCharges
end

local function useCharge(player)
    if not playerPaintCharges[player] then return false end
    if playerPaintCharges[player] <= 0 then return false end
    playerPaintCharges[player] -= 1
    return true
end

local function getCharges(player)
    return playerPaintCharges[player] or 0
end

----------------------------------------------------------------------
-- EVENT HANDLERS
----------------------------------------------------------------------

-- Handle paint request from client
PaintCharacter.OnServerEvent:Connect(function(player, partName, color)
    -- Validate game state
    if not paintingEnabled then return end

    -- Validate player has a character
    if not player.Character then return end

    -- Validate the part name is allowed
    local validPart = false
    for _, allowedPart in ipairs(PaintSystem.PaintableParts) do
        if allowedPart == partName then
            validPart = true
            break
        end
    end
    if not validPart then return end

    -- Validate color is a valid Color3 (any color allowed now - free painting!)
    if typeof(color) ~= "Color3" then return end

    -- Apply the paint (no charge limit for free painting)
    local success = PaintSystem.ApplyPaint(player.Character, partName, color)

    if success then
        PaintCharacter:FireClient(player, "SUCCESS", 99)
    else
        PaintCharacter:FireClient(player, "FAILED", 99)
    end
end)

-- GetColorPalette RemoteFunction
GetColorPalette.OnServerInvoke = function(player)
    return PaintSystem.GetPalette(currentMapName)
end

----------------------------------------------------------------------
-- PUBLIC API (called by RoundManager)
----------------------------------------------------------------------

local PaintServer = {}

function PaintServer.EnablePainting(mapName)
    currentMapName = mapName or GameConfig.DefaultMap
    paintingEnabled = true

    -- Reset all player charges
    for _, player in ipairs(Players:GetPlayers()) do
        resetCharges(player)
    end

    print("[PaintServer] Painting enabled for map:", currentMapName)
end

function PaintServer.DisablePainting()
    paintingEnabled = false
    print("[PaintServer] Painting disabled")
end

function PaintServer.SetMap(mapName)
    currentMapName = mapName
end

function PaintServer.GetPlayerCharges(player)
    return getCharges(player)
end

function PaintServer.RefillCharge(player)
    if not playerPaintCharges[player] then
        playerPaintCharges[player] = 0
    end
    playerPaintCharges[player] = math.min(
        playerPaintCharges[player] + 1,
        GameConfig.MaxPaintCharges
    )
    PaintCharacter:FireClient(player, "REFILL", getCharges(player))
end

----------------------------------------------------------------------
-- CLEANUP
----------------------------------------------------------------------

Players.PlayerRemoving:Connect(function(player)
    playerPaintCharges[player] = nil
end)

return PaintServer
