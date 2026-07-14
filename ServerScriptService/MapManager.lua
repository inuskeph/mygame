--[[
    MapManager.lua (ServerScript)
    Manages map loading, rotation, lobby area, spawn points, color pools,
    and teleportation between lobby and game maps.
    Place in ServerScriptService.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

local GameConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameConfig"))
local PaintSystem = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PaintSystem"))

local Events = ReplicatedStorage:WaitForChild("Events")
local TeleportPlayer = Events:WaitForChild("TeleportPlayer")


----------------------------------------------------------------------
-- MAP DEFINITIONS
----------------------------------------------------------------------

local MapManager = {}

-- Map registry: defines all available maps and their properties
MapManager.Maps = {
    Playground = {
        name = "Playground",
        description = "A colorful playground with slides, swings, and climbing frames",
        palette = PaintSystem.MapPalettes.Playground,
        lighting = {
            Ambient = Color3.fromRGB(150, 180, 200),
            Brightness = 2,
            ClockTime = 14,
            FogEnd = 1000,
        },
        -- Spawn positions (defined as offsets from map origin)
        hiderSpawns = {
            Vector3.new(0, 5, 0),
            Vector3.new(10, 5, 10),
            Vector3.new(-10, 5, 10),
            Vector3.new(10, 5, -10),
            Vector3.new(-10, 5, -10),
            Vector3.new(20, 5, 0),
            Vector3.new(-20, 5, 0),
            Vector3.new(0, 5, 20),
        },
        seekerSpawns = {
            Vector3.new(0, 5, -50),
            Vector3.new(5, 5, -50),
            Vector3.new(-5, 5, -50),
        },
        -- Color pool positions
        colorPools = {
            { position = Vector3.new(15, 1, 15), color = Color3.fromRGB(91, 154, 76) },
            { position = Vector3.new(-15, 1, 15), color = Color3.fromRGB(139, 90, 43) },
            { position = Vector3.new(15, 1, -15), color = Color3.fromRGB(163, 162, 165) },
            { position = Vector3.new(-15, 1, -15), color = Color3.fromRGB(242, 243, 243) },
            { position = Vector3.new(0, 1, 25), color = Color3.fromRGB(255, 201, 67) },
            { position = Vector3.new(0, 1, -25), color = Color3.fromRGB(13, 105, 172) },
        },
    },
    Kitchen = {
        name = "Kitchen",
        description = "A giant kitchen - you're the size of a mouse!",
        palette = PaintSystem.MapPalettes.Kitchen,
        lighting = {
            Ambient = Color3.fromRGB(200, 190, 170),
            Brightness = 1.5,
            ClockTime = 10,
            FogEnd = 800,
        },
        hiderSpawns = {
            Vector3.new(0, 5, 0),
            Vector3.new(12, 5, 8),
            Vector3.new(-12, 5, 8),
            Vector3.new(12, 5, -8),
            Vector3.new(-12, 5, -8),
            Vector3.new(20, 5, 0),
        },
        seekerSpawns = {
            Vector3.new(0, 5, -40),
            Vector3.new(5, 5, -40),
            Vector3.new(-5, 5, -40),
        },
        colorPools = {
            { position = Vector3.new(10, 1, 10), color = Color3.fromRGB(242, 243, 243) },
            { position = Vector3.new(-10, 1, 10), color = Color3.fromRGB(27, 42, 53) },
            { position = Vector3.new(10, 1, -10), color = Color3.fromRGB(139, 90, 43) },
            { position = Vector3.new(-10, 1, -10), color = Color3.fromRGB(163, 162, 165) },
            { position = Vector3.new(0, 1, 20), color = Color3.fromRGB(194, 218, 184) },
        },
    },
    Forest = {
        name = "Forest",
        description = "A dense forest with hiding spots among trees and rocks",
        palette = PaintSystem.MapPalettes.Forest,
        lighting = {
            Ambient = Color3.fromRGB(80, 120, 60),
            Brightness = 1,
            ClockTime = 16,
            FogEnd = 500,
        },
        hiderSpawns = {
            Vector3.new(0, 5, 0),
            Vector3.new(15, 5, 15),
            Vector3.new(-15, 5, 15),
            Vector3.new(15, 5, -15),
            Vector3.new(-15, 5, -15),
            Vector3.new(25, 5, 0),
            Vector3.new(-25, 5, 0),
            Vector3.new(0, 5, 25),
            Vector3.new(0, 5, -25),
        },
        seekerSpawns = {
            Vector3.new(0, 5, -60),
            Vector3.new(8, 5, -60),
            Vector3.new(-8, 5, -60),
        },
        colorPools = {
            { position = Vector3.new(20, 1, 0), color = Color3.fromRGB(75, 151, 75) },
            { position = Vector3.new(-20, 1, 0), color = Color3.fromRGB(86, 66, 54) },
            { position = Vector3.new(0, 1, 20), color = Color3.fromRGB(91, 154, 76) },
            { position = Vector3.new(0, 1, -20), color = Color3.fromRGB(163, 162, 165) },
            { position = Vector3.new(15, 1, 15), color = Color3.fromRGB(196, 112, 58) },
            { position = Vector3.new(-15, 1, -15), color = Color3.fromRGB(37, 65, 23) },
        },
    },
}


----------------------------------------------------------------------
-- STATE
----------------------------------------------------------------------

MapManager.CurrentMap = nil          -- Current active map name
MapManager.MapRotationIndex = 0      -- Index for rotation
MapManager.ActiveColorPools = {}     -- Spawned color pool parts
MapManager.MapFolder = nil           -- Current map folder in Workspace

-- Lobby spawn position
MapManager.LobbySpawn = Vector3.new(-221, 12.375, 488.175)

-- Map rotation order
MapManager.RotationOrder = { "Playground", "Kitchen", "Forest" }

----------------------------------------------------------------------
-- LOBBY CREATION
----------------------------------------------------------------------

function MapManager.CreateLobby()
    -- Check if lobby already exists
    if Workspace:FindFirstChild("Lobby") then return end

    local lobby = Instance.new("Folder")
    lobby.Name = "Lobby"
    lobby.Parent = Workspace

    -- Floor
    local floor = Instance.new("Part")
    floor.Name = "LobbyFloor"
    floor.Size = Vector3.new(80, 2, 80)
    floor.Position = Vector3.new(0, 0, 0)
    floor.Anchored = true
    floor.Material = Enum.Material.SmoothPlastic
    floor.Color = Color3.fromRGB(100, 150, 200)
    floor.Parent = lobby

    -- Walls (invisible barriers)
    local wallPositions = {
        { pos = Vector3.new(40, 15, 0), size = Vector3.new(2, 30, 80) },
        { pos = Vector3.new(-40, 15, 0), size = Vector3.new(2, 30, 80) },
        { pos = Vector3.new(0, 15, 40), size = Vector3.new(80, 30, 2) },
        { pos = Vector3.new(0, 15, -40), size = Vector3.new(80, 30, 2) },
    }

    for i, wallData in ipairs(wallPositions) do
        local wall = Instance.new("Part")
        wall.Name = "Wall_" .. i
        wall.Size = wallData.size
        wall.Position = wallData.pos
        wall.Anchored = true
        wall.Transparency = 0.8
        wall.Material = Enum.Material.ForceField
        wall.Color = Color3.fromRGB(150, 200, 255)
        wall.CanCollide = true
        wall.Parent = lobby
    end

    -- Spawn point
    local spawnPart = Instance.new("SpawnLocation")
    spawnPart.Name = "LobbySpawn"
    spawnPart.Size = Vector3.new(8, 1, 8)
    spawnPart.Position = Vector3.new(0, 1.5, 0)
    spawnPart.Anchored = true
    spawnPart.Material = Enum.Material.Neon
    spawnPart.Color = Color3.fromRGB(80, 200, 80)
    spawnPart.Neutral = true
    spawnPart.Parent = lobby

    -- Info sign
    local sign = Instance.new("Part")
    sign.Name = "InfoSign"
    sign.Size = Vector3.new(12, 6, 1)
    sign.Position = Vector3.new(0, 6, -35)
    sign.Anchored = true
    sign.Material = Enum.Material.SmoothPlastic
    sign.Color = Color3.fromRGB(40, 40, 60)
    sign.Parent = lobby

    local surfaceGui = Instance.new("SurfaceGui")
    surfaceGui.Face = Enum.NormalId.Front
    surfaceGui.Parent = sign

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    textLabel.Text = "🦎 CHAMELEON 🦎\n\nPaint yourself, hide in plain sight!\nSurvive the Seekers to win!"
    textLabel.TextSize = 60
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextWrapped = true
    textLabel.Parent = surfaceGui

    print("[MapManager] Lobby created")
end


----------------------------------------------------------------------
-- COLOR POOL CREATION
----------------------------------------------------------------------

function MapManager.CreateColorPools(mapName)
    MapManager.ClearColorPools()

    local mapData = MapManager.Maps[mapName]
    if not mapData or not mapData.colorPools then return end

    local mapOrigin = Vector3.new(0, 0, 200) -- Maps offset from lobby

    for i, poolData in ipairs(mapData.colorPools) do
        local pool = Instance.new("Part")
        pool.Name = "ColorPool_" .. i
        pool.Shape = Enum.PartType.Cylinder
        pool.Size = Vector3.new(1, 5, 5) -- Cylinder rotated
        pool.CFrame = CFrame.new(mapOrigin + poolData.position) * CFrame.Angles(0, 0, math.rad(90))
        pool.Anchored = true
        pool.Material = Enum.Material.Neon
        pool.Color = poolData.color
        pool.CanCollide = true
        pool.Transparency = 0.3
        pool.Parent = Workspace:FindFirstChild("Maps") or Workspace

        -- Set attributes for detection
        pool:SetAttribute("IsColorPool", true)
        pool:SetAttribute("PaintColor", poolData.color)

        -- Visual: particles rising from pool
        local attachment = Instance.new("Attachment")
        attachment.Parent = pool

        local particles = Instance.new("ParticleEmitter")
        particles.Color = ColorSequence.new(poolData.color)
        particles.Size = NumberSequence.new(0.3, 0)
        particles.Transparency = NumberSequence.new(0.3, 1)
        particles.Lifetime = NumberRange.new(1, 2)
        particles.Rate = 5
        particles.Speed = NumberRange.new(1, 2)
        particles.SpreadAngle = Vector2.new(20, 20)
        particles.Parent = attachment

        -- Label above pool
        local billboard = Instance.new("BillboardGui")
        billboard.Size = UDim2.new(0, 60, 0, 25)
        billboard.StudsOffset = Vector3.new(0, 3, 0)
        billboard.AlwaysOnTop = false
        billboard.Parent = pool

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundColor3 = poolData.color
        label.BackgroundTransparency = 0.3
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.Text = "Paint"
        label.TextSize = 14
        label.Font = Enum.Font.GothamBold
        label.Parent = billboard

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = label

        table.insert(MapManager.ActiveColorPools, pool)
    end

    print("[MapManager] Created", #mapData.colorPools, "color pools for", mapName)
end

function MapManager.ClearColorPools()
    for _, pool in ipairs(MapManager.ActiveColorPools) do
        if pool and pool.Parent then
            pool:Destroy()
        end
    end
    MapManager.ActiveColorPools = {}
end


----------------------------------------------------------------------
-- MAP LOADING
----------------------------------------------------------------------

function MapManager.LoadMap(mapName)
    local mapData = MapManager.Maps[mapName]
    if not mapData then
        warn("[MapManager] Map not found:", mapName)
        return false
    end

    -- Set current map
    MapManager.CurrentMap = mapName

    -- Apply lighting
    if mapData.lighting then
        Lighting.Ambient = mapData.lighting.Ambient
        Lighting.Brightness = mapData.lighting.Brightness
        Lighting.ClockTime = mapData.lighting.ClockTime
        Lighting.FogEnd = mapData.lighting.FogEnd
    end

    -- Create color pools
    MapManager.CreateColorPools(mapName)

    -- Look for pre-built map in Workspace/Maps folder
    local mapsFolder = Workspace:FindFirstChild("Maps")
    if mapsFolder then
        local mapModel = mapsFolder:FindFirstChild(mapName)
        if mapModel then
            -- Map already exists in workspace, just make sure it's visible
            for _, part in ipairs(mapModel:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.Transparency = part:GetAttribute("OriginalTransparency") or part.Transparency
                end
            end
            MapManager.MapFolder = mapModel
            print("[MapManager] Loaded existing map:", mapName)
            return true
        end
    end

    -- If no pre-built map, create a basic placeholder
    MapManager.CreatePlaceholderMap(mapName, mapData)

    print("[MapManager] Loaded map:", mapName)
    return true
end

function MapManager.UnloadMap()
    if MapManager.MapFolder and MapManager.MapFolder:FindFirstChild("_Placeholder") then
        MapManager.MapFolder:Destroy()
    end
    MapManager.ClearColorPools()
    MapManager.CurrentMap = nil

    -- Reset lighting
    Lighting.Ambient = Color3.fromRGB(150, 150, 150)
    Lighting.Brightness = 2
    Lighting.ClockTime = 14
    Lighting.FogEnd = 1000
end

----------------------------------------------------------------------
-- PLACEHOLDER MAP (basic geometry for testing)
----------------------------------------------------------------------

function MapManager.CreatePlaceholderMap(mapName, mapData)
    local mapOrigin = Vector3.new(0, 0, 200)

    local folder = Instance.new("Folder")
    folder.Name = mapName
    folder.Parent = Workspace:FindFirstChild("Maps") or Workspace

    -- Mark as placeholder
    local marker = Instance.new("BoolValue")
    marker.Name = "_Placeholder"
    marker.Parent = folder

    -- Ground
    local ground = Instance.new("Part")
    ground.Name = "Ground"
    ground.Size = Vector3.new(120, 2, 120)
    ground.Position = mapOrigin + Vector3.new(0, -1, 0)
    ground.Anchored = true
    ground.Material = Enum.Material.Grass
    ground.Color = mapData.palette and mapData.palette[1] or Color3.fromRGB(91, 154, 76)
    ground.Parent = folder

    -- Scatter props for hiding
    local propColors = mapData.palette or PaintSystem.DefaultPalette
    local propCount = 30

    for i = 1, propCount do
        local prop = Instance.new("Part")
        prop.Name = "Prop_" .. i
        local sizeX = math.random(3, 8)
        local sizeY = math.random(3, 12)
        local sizeZ = math.random(3, 8)
        prop.Size = Vector3.new(sizeX, sizeY, sizeZ)
        prop.Position = mapOrigin + Vector3.new(
            math.random(-50, 50),
            sizeY / 2,
            math.random(-50, 50)
        )
        prop.Anchored = true
        prop.Material = Enum.Material.SmoothPlastic
        prop.Color = propColors[math.random(1, #propColors)]
        prop.Parent = folder
    end

    -- Walls
    local walls = {
        { pos = Vector3.new(60, 10, 0), size = Vector3.new(2, 20, 120) },
        { pos = Vector3.new(-60, 10, 0), size = Vector3.new(2, 20, 120) },
        { pos = Vector3.new(0, 10, 60), size = Vector3.new(120, 20, 2) },
        { pos = Vector3.new(0, 10, -60), size = Vector3.new(120, 20, 2) },
    }

    for j, wallData in ipairs(walls) do
        local wall = Instance.new("Part")
        wall.Name = "MapWall_" .. j
        wall.Size = wallData.size
        wall.Position = mapOrigin + wallData.pos
        wall.Anchored = true
        wall.Material = Enum.Material.Concrete
        wall.Color = propColors[math.random(1, #propColors)]
        wall.Parent = folder
    end

    -- Seeker waiting area (separate boxed area)
    local seekerRoom = Instance.new("Part")
    seekerRoom.Name = "SeekerWaitFloor"
    seekerRoom.Size = Vector3.new(20, 2, 20)
    seekerRoom.Position = mapOrigin + Vector3.new(0, -1, -80)
    seekerRoom.Anchored = true
    seekerRoom.Material = Enum.Material.SmoothPlastic
    seekerRoom.Color = Color3.fromRGB(80, 40, 40)
    seekerRoom.Parent = folder

    MapManager.MapFolder = folder
end


----------------------------------------------------------------------
-- TELEPORTATION
----------------------------------------------------------------------

function MapManager.TeleportToLobby(playerObj)
    if not playerObj or not playerObj.Character then return end
    local rootPart = playerObj.Character:FindFirstChild("HumanoidRootPart")
    if rootPart then
        rootPart.CFrame = CFrame.new(MapManager.LobbySpawn + Vector3.new(
            math.random(-5, 5), 0, math.random(-5, 5)
        ))
    end
end

function MapManager.TeleportAllToLobby()
    for _, p in ipairs(Players:GetPlayers()) do
        MapManager.TeleportToLobby(p)
    end
    TeleportPlayer:FireAllClients("Lobby")
end

function MapManager.TeleportHidersToMap(hiders)
    local mapData = MapManager.Maps[MapManager.CurrentMap]
    if not mapData then return end

    local mapOrigin = Vector3.new(0, 0, 200)
    local spawns = mapData.hiderSpawns

    for i, hider in ipairs(hiders) do
        if hider and hider.Character then
            local rootPart = hider.Character:FindFirstChild("HumanoidRootPart")
            if rootPart then
                local spawnIdx = ((i - 1) % #spawns) + 1
                rootPart.CFrame = CFrame.new(mapOrigin + spawns[spawnIdx])
            end
        end
    end
end

function MapManager.TeleportSeekersToMap(seekers)
    local mapData = MapManager.Maps[MapManager.CurrentMap]
    if not mapData then return end

    local mapOrigin = Vector3.new(0, 0, 200)
    local spawns = mapData.seekerSpawns

    for i, seeker in ipairs(seekers) do
        if seeker and seeker.Character then
            local rootPart = seeker.Character:FindFirstChild("HumanoidRootPart")
            if rootPart then
                local spawnIdx = ((i - 1) % #spawns) + 1
                rootPart.CFrame = CFrame.new(mapOrigin + spawns[spawnIdx])
            end
        end
    end
end

----------------------------------------------------------------------
-- MAP ROTATION
----------------------------------------------------------------------

function MapManager.GetNextMap()
    if not GameConfig.MapRotation then
        return GameConfig.DefaultMap
    end

    MapManager.MapRotationIndex += 1
    if MapManager.MapRotationIndex > #MapManager.RotationOrder then
        MapManager.MapRotationIndex = 1
    end

    return MapManager.RotationOrder[MapManager.MapRotationIndex]
end

function MapManager.GetCurrentMapName()
    return MapManager.CurrentMap or GameConfig.DefaultMap
end

function MapManager.GetMapPalette(mapName)
    local name = mapName or MapManager.CurrentMap
    local mapData = MapManager.Maps[name]
    if mapData then
        return mapData.palette or PaintSystem.DefaultPalette
    end
    return PaintSystem.DefaultPalette
end

----------------------------------------------------------------------
-- INITIALIZATION
----------------------------------------------------------------------

-- Create the Maps folder in Workspace
if not Workspace:FindFirstChild("Maps") then
    local mapsFolder = Instance.new("Folder")
    mapsFolder.Name = "Maps"
    mapsFolder.Parent = Workspace
end

-- Create lobby on startup (DISABLED - using custom lobby)
-- MapManager.CreateLobby()
print("[MapManager] Map system initialized (custom lobby mode)")

return MapManager
