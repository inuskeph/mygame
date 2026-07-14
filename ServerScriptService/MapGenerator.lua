--[[
    MapGenerator.lua (ModuleScript used by MapManager)
    Generates 6 detailed maps with furniture, props, and hiding spots.
    Each map has a unique theme, palette, and layout.
    Place in ServerScriptService.
]]

local MapGenerator = {}

-- Helper to create a part
local function makePart(parent, name, size, position, color, material, transparency)
    local part = Instance.new("Part")
    part.Name = name or "Part"
    part.Size = size or Vector3.new(4, 4, 4)
    part.Position = position or Vector3.new(0, 0, 0)
    part.Color = color or Color3.fromRGB(163, 162, 165)
    part.Material = material or Enum.Material.SmoothPlastic
    part.Transparency = transparency or 0
    part.Anchored = true
    part.Parent = parent
    return part
end

-- Helper to create a wedge
local function makeWedge(parent, name, size, cframe, color, material)
    local wedge = Instance.new("WedgePart")
    wedge.Name = name or "Wedge"
    wedge.Size = size or Vector3.new(4, 4, 4)
    wedge.CFrame = cframe or CFrame.new(0, 0, 0)
    wedge.Color = color or Color3.fromRGB(163, 162, 165)
    wedge.Material = material or Enum.Material.SmoothPlastic
    wedge.Anchored = true
    wedge.Parent = parent
    return wedge
end


----------------------------------------------------------------------
-- MAP 1: SCHOOL CLASSROOM
----------------------------------------------------------------------

function MapGenerator.CreateSchool(origin)
    local folder = Instance.new("Folder")
    folder.Name = "School"

    local o = origin or Vector3.new(0, 0, 200)
    local wood = Color3.fromRGB(139, 90, 43)
    local cream = Color3.fromRGB(242, 235, 215)
    local green = Color3.fromRGB(80, 120, 80)
    local gray = Color3.fromRGB(163, 162, 165)
    local darkGray = Color3.fromRGB(90, 90, 90)
    local chalkGreen = Color3.fromRGB(53, 94, 59)
    local tileWhite = Color3.fromRGB(230, 230, 230)

    -- Floor
    makePart(folder, "Floor", Vector3.new(100, 2, 80), o + Vector3.new(0, -1, 0), tileWhite, Enum.Material.Marble)

    -- Ceiling
    makePart(folder, "Ceiling", Vector3.new(100, 1, 80), o + Vector3.new(0, 20, 0), cream, Enum.Material.SmoothPlastic)

    -- Walls
    makePart(folder, "WallBack", Vector3.new(100, 20, 2), o + Vector3.new(0, 10, -40), cream, Enum.Material.Concrete)
    makePart(folder, "WallFront", Vector3.new(100, 20, 2), o + Vector3.new(0, 10, 40), cream, Enum.Material.Concrete)
    makePart(folder, "WallLeft", Vector3.new(2, 20, 80), o + Vector3.new(-50, 10, 0), cream, Enum.Material.Concrete)
    makePart(folder, "WallRight", Vector3.new(2, 20, 80), o + Vector3.new(50, 10, 0), cream, Enum.Material.Concrete)

    -- Chalkboard
    makePart(folder, "Chalkboard", Vector3.new(30, 10, 1), o + Vector3.new(0, 8, -38), chalkGreen, Enum.Material.SmoothPlastic)
    makePart(folder, "ChalkTray", Vector3.new(32, 0.5, 2), o + Vector3.new(0, 3, -38), wood, Enum.Material.Wood)

    -- Teacher desk
    makePart(folder, "TeacherDesk", Vector3.new(12, 4, 6), o + Vector3.new(0, 2, -30), wood, Enum.Material.Wood)
    makePart(folder, "TeacherChair", Vector3.new(3, 5, 3), o + Vector3.new(0, 2.5, -25), darkGray, Enum.Material.SmoothPlastic)


    -- Student desks (4 rows x 5 columns)
    for row = 1, 4 do
        for col = 1, 5 do
            local x = -30 + (col * 12)
            local z = -15 + (row * 12)
            makePart(folder, "Desk_"..row.."_"..col, Vector3.new(8, 3.5, 5), o + Vector3.new(x, 1.75, z), wood, Enum.Material.Wood)
            makePart(folder, "Chair_"..row.."_"..col, Vector3.new(3, 4, 3), o + Vector3.new(x, 2, z + 4), darkGray, Enum.Material.SmoothPlastic)
        end
    end

    -- Bookshelf (left wall)
    makePart(folder, "Bookshelf1", Vector3.new(2, 12, 20), o + Vector3.new(-48, 6, -20), wood, Enum.Material.Wood)
    makePart(folder, "Books1", Vector3.new(1.5, 2, 18), o + Vector3.new(-48, 3, -20), Color3.fromRGB(180, 50, 50), Enum.Material.SmoothPlastic)
    makePart(folder, "Books2", Vector3.new(1.5, 2, 18), o + Vector3.new(-48, 6, -20), Color3.fromRGB(50, 50, 180), Enum.Material.SmoothPlastic)
    makePart(folder, "Books3", Vector3.new(1.5, 2, 18), o + Vector3.new(-48, 9, -20), Color3.fromRGB(50, 150, 50), Enum.Material.SmoothPlastic)

    -- Bookshelf (right wall)
    makePart(folder, "Bookshelf2", Vector3.new(2, 12, 20), o + Vector3.new(48, 6, 10), wood, Enum.Material.Wood)

    -- Filing cabinet
    makePart(folder, "FilingCabinet", Vector3.new(4, 8, 3), o + Vector3.new(-45, 4, 30), gray, Enum.Material.Metal)

    -- Globe on stand
    makePart(folder, "GlobeStand", Vector3.new(2, 5, 2), o + Vector3.new(40, 2.5, -35), wood, Enum.Material.Wood)

    -- Trash can
    makePart(folder, "TrashCan", Vector3.new(3, 4, 3), o + Vector3.new(45, 2, 35), darkGray, Enum.Material.Metal)

    -- Door frame
    makePart(folder, "DoorFrame", Vector3.new(8, 14, 2), o + Vector3.new(40, 7, 40), wood, Enum.Material.Wood)

    return folder
end


----------------------------------------------------------------------
-- MAP 2: SUPERMARKET
----------------------------------------------------------------------

function MapGenerator.CreateSupermarket(origin)
    local folder = Instance.new("Folder")
    folder.Name = "Supermarket"

    local o = origin or Vector3.new(0, 0, 200)
    local white = Color3.fromRGB(240, 240, 240)
    local shelfMetal = Color3.fromRGB(180, 180, 185)
    local floor = Color3.fromRGB(220, 215, 200)
    local red = Color3.fromRGB(200, 50, 50)
    local blue = Color3.fromRGB(40, 80, 160)
    local green = Color3.fromRGB(60, 160, 60)
    local yellow = Color3.fromRGB(255, 210, 50)
    local orange = Color3.fromRGB(240, 130, 40)
    local brown = Color3.fromRGB(139, 90, 43)

    -- Floor
    makePart(folder, "Floor", Vector3.new(120, 2, 100), o + Vector3.new(0, -1, 0), floor, Enum.Material.Marble)

    -- Ceiling
    makePart(folder, "Ceiling", Vector3.new(120, 1, 100), o + Vector3.new(0, 18, 0), white, Enum.Material.SmoothPlastic)

    -- Walls
    makePart(folder, "WallBack", Vector3.new(120, 18, 2), o + Vector3.new(0, 9, -50), white, Enum.Material.Concrete)
    makePart(folder, "WallFront", Vector3.new(120, 18, 2), o + Vector3.new(0, 9, 50), white, Enum.Material.Concrete)
    makePart(folder, "WallLeft", Vector3.new(2, 18, 100), o + Vector3.new(-60, 9, 0), white, Enum.Material.Concrete)
    makePart(folder, "WallRight", Vector3.new(2, 18, 100), o + Vector3.new(60, 9, 0), white, Enum.Material.Concrete)

    -- Aisle shelves (6 long aisles)
    for aisle = 1, 6 do
        local x = -45 + (aisle * 14)
        -- Left shelf
        makePart(folder, "Shelf_L_"..aisle, Vector3.new(3, 10, 60), o + Vector3.new(x - 2, 5, 0), shelfMetal, Enum.Material.Metal)
        -- Right shelf
        makePart(folder, "Shelf_R_"..aisle, Vector3.new(3, 10, 60), o + Vector3.new(x + 2, 5, 0), shelfMetal, Enum.Material.Metal)
        -- Products on shelves (colorful boxes)
        for shelf_z = -25, 25, 10 do
            local productColor = ({red, blue, green, yellow, orange, brown})[math.random(1, 6)]
            makePart(folder, "Product_"..aisle.."_"..shelf_z, Vector3.new(2.5, 2, 3), o + Vector3.new(x - 2, 2, shelf_z), productColor, Enum.Material.SmoothPlastic)
            makePart(folder, "Product2_"..aisle.."_"..shelf_z, Vector3.new(2.5, 2, 3), o + Vector3.new(x + 2, 2, shelf_z), productColor, Enum.Material.SmoothPlastic)
            makePart(folder, "Product3_"..aisle.."_"..shelf_z, Vector3.new(2.5, 2, 3), o + Vector3.new(x - 2, 5, shelf_z), ({red, blue, green, yellow, orange})[math.random(1, 5)], Enum.Material.SmoothPlastic)
            makePart(folder, "Product4_"..aisle.."_"..shelf_z, Vector3.new(2.5, 2, 3), o + Vector3.new(x + 2, 5, shelf_z), ({red, blue, green, yellow, orange})[math.random(1, 5)], Enum.Material.SmoothPlastic)
        end
    end


    -- Checkout counters (front)
    for i = 1, 4 do
        local x = -30 + (i * 15)
        makePart(folder, "Counter_"..i, Vector3.new(6, 4, 10), o + Vector3.new(x, 2, 40), brown, Enum.Material.Wood)
        makePart(folder, "Register_"..i, Vector3.new(2, 2, 2), o + Vector3.new(x, 5, 40), Color3.fromRGB(40, 40, 40), Enum.Material.SmoothPlastic)
    end

    -- Freezer section (back wall)
    makePart(folder, "Freezer1", Vector3.new(25, 12, 4), o + Vector3.new(-35, 6, -47), Color3.fromRGB(200, 220, 240), Enum.Material.Glass, 0.3)
    makePart(folder, "Freezer2", Vector3.new(25, 12, 4), o + Vector3.new(0, 6, -47), Color3.fromRGB(200, 220, 240), Enum.Material.Glass, 0.3)
    makePart(folder, "Freezer3", Vector3.new(25, 12, 4), o + Vector3.new(35, 6, -47), Color3.fromRGB(200, 220, 240), Enum.Material.Glass, 0.3)

    -- Fruit stand (corner)
    makePart(folder, "FruitTable", Vector3.new(12, 3, 8), o + Vector3.new(-50, 1.5, 40), brown, Enum.Material.Wood)
    makePart(folder, "Apples", Vector3.new(4, 2, 4), o + Vector3.new(-52, 3.5, 40), red, Enum.Material.SmoothPlastic)
    makePart(folder, "Bananas", Vector3.new(4, 2, 4), o + Vector3.new(-48, 3.5, 40), yellow, Enum.Material.SmoothPlastic)

    -- Shopping carts (scattered)
    for i = 1, 5 do
        makePart(folder, "Cart_"..i, Vector3.new(3, 4, 5), o + Vector3.new(math.random(-50, 50), 2, math.random(-30, 30)), shelfMetal, Enum.Material.Metal)
    end

    return folder
end


----------------------------------------------------------------------
-- MAP 3: GIANT BEDROOM (you're tiny!)
----------------------------------------------------------------------

function MapGenerator.CreateBedroom(origin)
    local folder = Instance.new("Folder")
    folder.Name = "Bedroom"

    local o = origin or Vector3.new(0, 0, 200)
    local wallColor = Color3.fromRGB(180, 200, 220)
    local woodFloor = Color3.fromRGB(160, 110, 60)
    local bedRed = Color3.fromRGB(180, 50, 60)
    local white = Color3.fromRGB(245, 245, 245)
    local darkWood = Color3.fromRGB(100, 60, 30)
    local carpet = Color3.fromRGB(80, 60, 120)
    local toyYellow = Color3.fromRGB(255, 220, 50)
    local toyBlue = Color3.fromRGB(50, 100, 200)
    local toyRed = Color3.fromRGB(220, 50, 50)

    -- Floor (wood)
    makePart(folder, "Floor", Vector3.new(120, 2, 100), o + Vector3.new(0, -1, 0), woodFloor, Enum.Material.Wood)

    -- Carpet (center)
    makePart(folder, "Carpet", Vector3.new(50, 0.5, 40), o + Vector3.new(0, 0.3, 0), carpet, Enum.Material.Fabric)

    -- Walls
    makePart(folder, "WallBack", Vector3.new(120, 40, 2), o + Vector3.new(0, 20, -50), wallColor, Enum.Material.SmoothPlastic)
    makePart(folder, "WallFront", Vector3.new(120, 40, 2), o + Vector3.new(0, 20, 50), wallColor, Enum.Material.SmoothPlastic)
    makePart(folder, "WallLeft", Vector3.new(2, 40, 100), o + Vector3.new(-60, 20, 0), wallColor, Enum.Material.SmoothPlastic)
    makePart(folder, "WallRight", Vector3.new(2, 40, 100), o + Vector3.new(60, 20, 0), wallColor, Enum.Material.SmoothPlastic)

    -- Giant Bed (main hiding spot!)
    makePart(folder, "BedFrame", Vector3.new(40, 3, 50), o + Vector3.new(-25, 1.5, -20), darkWood, Enum.Material.Wood)
    makePart(folder, "Mattress", Vector3.new(38, 6, 48), o + Vector3.new(-25, 6, -20), white, Enum.Material.Fabric)
    makePart(folder, "Blanket", Vector3.new(38, 2, 35), o + Vector3.new(-25, 10, -15), bedRed, Enum.Material.Fabric)
    makePart(folder, "Pillow1", Vector3.new(12, 4, 8), o + Vector3.new(-30, 10, -40), white, Enum.Material.Fabric)
    makePart(folder, "Pillow2", Vector3.new(12, 4, 8), o + Vector3.new(-20, 10, -40), white, Enum.Material.Fabric)
    -- Under the bed space (great hiding spot)
    makePart(folder, "BedLeg1", Vector3.new(3, 3, 3), o + Vector3.new(-43, 1.5, -43), darkWood, Enum.Material.Wood)
    makePart(folder, "BedLeg2", Vector3.new(3, 3, 3), o + Vector3.new(-7, 1.5, -43), darkWood, Enum.Material.Wood)
    makePart(folder, "BedLeg3", Vector3.new(3, 3, 3), o + Vector3.new(-43, 1.5, 3), darkWood, Enum.Material.Wood)
    makePart(folder, "BedLeg4", Vector3.new(3, 3, 3), o + Vector3.new(-7, 1.5, 3), darkWood, Enum.Material.Wood)


    -- Wardrobe (right side)
    makePart(folder, "Wardrobe", Vector3.new(20, 30, 10), o + Vector3.new(45, 15, -40), darkWood, Enum.Material.Wood)
    makePart(folder, "WardrobeDoor1", Vector3.new(9, 28, 1), o + Vector3.new(40, 15, -34), darkWood, Enum.Material.Wood)
    makePart(folder, "WardrobeDoor2", Vector3.new(9, 28, 1), o + Vector3.new(50, 15, -34), darkWood, Enum.Material.Wood)

    -- Desk with lamp
    makePart(folder, "Desk", Vector3.new(20, 12, 10), o + Vector3.new(40, 6, 20), darkWood, Enum.Material.Wood)
    makePart(folder, "DeskLamp", Vector3.new(3, 6, 3), o + Vector3.new(45, 15, 20), toyYellow, Enum.Material.SmoothPlastic)
    makePart(folder, "DeskChair", Vector3.new(8, 14, 8), o + Vector3.new(40, 7, 30), Color3.fromRGB(60, 60, 60), Enum.Material.SmoothPlastic)

    -- Toy box
    makePart(folder, "ToyBox", Vector3.new(15, 10, 10), o + Vector3.new(20, 5, 40), toyBlue, Enum.Material.SmoothPlastic)

    -- Scattered toys
    makePart(folder, "ToyBlock1", Vector3.new(4, 4, 4), o + Vector3.new(10, 2, 30), toyRed, Enum.Material.SmoothPlastic)
    makePart(folder, "ToyBlock2", Vector3.new(4, 4, 4), o + Vector3.new(15, 2, 35), toyYellow, Enum.Material.SmoothPlastic)
    makePart(folder, "ToyBlock3", Vector3.new(4, 4, 4), o + Vector3.new(5, 2, 25), toyBlue, Enum.Material.SmoothPlastic)
    makePart(folder, "ToyBlock4", Vector3.new(3, 6, 3), o + Vector3.new(12, 3, 20), Color3.fromRGB(50, 200, 50), Enum.Material.SmoothPlastic)

    -- Teddy bear (large)
    makePart(folder, "TeddyBody", Vector3.new(6, 8, 5), o + Vector3.new(-50, 4, 35), Color3.fromRGB(180, 140, 80), Enum.Material.Fabric)
    makePart(folder, "TeddyHead", Vector3.new(5, 5, 4), o + Vector3.new(-50, 9, 35), Color3.fromRGB(180, 140, 80), Enum.Material.Fabric)

    -- Nightstand
    makePart(folder, "Nightstand", Vector3.new(8, 8, 8), o + Vector3.new(-50, 4, -20), darkWood, Enum.Material.Wood)

    -- Rug detail
    makePart(folder, "RugBorder", Vector3.new(54, 0.3, 44), o + Vector3.new(0, 0.2, 0), Color3.fromRGB(60, 40, 100), Enum.Material.Fabric)

    return folder
end


----------------------------------------------------------------------
-- MAP 4: CONSTRUCTION SITE
----------------------------------------------------------------------

function MapGenerator.CreateConstruction(origin)
    local folder = Instance.new("Folder")
    folder.Name = "Construction"

    local o = origin or Vector3.new(0, 0, 200)
    local dirt = Color3.fromRGB(140, 100, 50)
    local concrete = Color3.fromRGB(163, 162, 165)
    local orange = Color3.fromRGB(255, 130, 0)
    local yellow = Color3.fromRGB(255, 200, 0)
    local metal = Color3.fromRGB(120, 120, 130)
    local wood = Color3.fromRGB(160, 110, 60)
    local darkMetal = Color3.fromRGB(60, 60, 65)

    -- Ground (dirt)
    makePart(folder, "Ground", Vector3.new(130, 2, 110), o + Vector3.new(0, -1, 0), dirt, Enum.Material.Ground)

    -- Concrete foundation patches
    makePart(folder, "Foundation1", Vector3.new(40, 1, 40), o + Vector3.new(-30, 0.5, -20), concrete, Enum.Material.Concrete)
    makePart(folder, "Foundation2", Vector3.new(30, 1, 30), o + Vector3.new(30, 0.5, 20), concrete, Enum.Material.Concrete)

    -- Scaffolding (multi-level)
    for level = 0, 2 do
        local y = level * 10
        -- Horizontal bars
        makePart(folder, "Scaffold_H1_"..level, Vector3.new(30, 1, 1), o + Vector3.new(-30, y + 5, -20), metal, Enum.Material.Metal)
        makePart(folder, "Scaffold_H2_"..level, Vector3.new(30, 1, 1), o + Vector3.new(-30, y + 5, -10), metal, Enum.Material.Metal)
        -- Platform
        makePart(folder, "Scaffold_P_"..level, Vector3.new(30, 0.5, 12), o + Vector3.new(-30, y + 5.5, -15), wood, Enum.Material.Wood)
        -- Vertical poles
        makePart(folder, "Scaffold_V1_"..level, Vector3.new(1, 10, 1), o + Vector3.new(-44, y + 5, -20), metal, Enum.Material.Metal)
        makePart(folder, "Scaffold_V2_"..level, Vector3.new(1, 10, 1), o + Vector3.new(-16, y + 5, -20), metal, Enum.Material.Metal)
        makePart(folder, "Scaffold_V3_"..level, Vector3.new(1, 10, 1), o + Vector3.new(-44, y + 5, -10), metal, Enum.Material.Metal)
        makePart(folder, "Scaffold_V4_"..level, Vector3.new(1, 10, 1), o + Vector3.new(-16, y + 5, -10), metal, Enum.Material.Metal)
    end

    -- Concrete barriers (orange/white stripes simulated with orange)
    for i = 1, 8 do
        local x = -50 + (i * 12)
        makePart(folder, "Barrier_"..i, Vector3.new(8, 4, 2), o + Vector3.new(x, 2, 45), orange, Enum.Material.SmoothPlastic)
    end

    -- Dirt piles
    makePart(folder, "DirtPile1", Vector3.new(12, 6, 10), o + Vector3.new(30, 3, -30), dirt, Enum.Material.Ground)
    makePart(folder, "DirtPile2", Vector3.new(8, 4, 8), o + Vector3.new(40, 2, -35), dirt, Enum.Material.Ground)
    makePart(folder, "DirtPile3", Vector3.new(15, 8, 12), o + Vector3.new(-10, 4, 30), dirt, Enum.Material.Ground)


    -- Concrete pipes (cylinders to hide in)
    local pipe1 = Instance.new("Part")
    pipe1.Name = "Pipe1"; pipe1.Shape = Enum.PartType.Cylinder
    pipe1.Size = Vector3.new(20, 8, 8)
    pipe1.CFrame = CFrame.new(o + Vector3.new(20, 4, 0)) * CFrame.Angles(0, 0, math.rad(90))
    pipe1.Color = concrete; pipe1.Material = Enum.Material.Concrete; pipe1.Anchored = true
    pipe1.Parent = folder

    local pipe2 = Instance.new("Part")
    pipe2.Name = "Pipe2"; pipe2.Shape = Enum.PartType.Cylinder
    pipe2.Size = Vector3.new(15, 8, 8)
    pipe2.CFrame = CFrame.new(o + Vector3.new(25, 4, 8)) * CFrame.Angles(0, 0, math.rad(90))
    pipe2.Color = concrete; pipe2.Material = Enum.Material.Concrete; pipe2.Anchored = true
    pipe2.Parent = folder

    -- Crane base
    makePart(folder, "CraneBase", Vector3.new(8, 2, 8), o + Vector3.new(45, 1, -40), yellow, Enum.Material.Metal)
    makePart(folder, "CranePole", Vector3.new(3, 40, 3), o + Vector3.new(45, 21, -40), yellow, Enum.Material.Metal)
    makePart(folder, "CraneArm", Vector3.new(40, 2, 3), o + Vector3.new(45, 41, -40), yellow, Enum.Material.Metal)

    -- Wooden pallets
    for i = 1, 4 do
        makePart(folder, "Pallet_"..i, Vector3.new(6, 1, 6), o + Vector3.new(math.random(-40, 40), 0.5, math.random(-30, 30)), wood, Enum.Material.Wood)
    end

    -- Porta potty
    makePart(folder, "Portapotty", Vector3.new(5, 10, 5), o + Vector3.new(-55, 5, 40), Color3.fromRGB(50, 100, 180), Enum.Material.SmoothPlastic)

    -- Toolbox
    makePart(folder, "Toolbox", Vector3.new(4, 3, 3), o + Vector3.new(50, 1.5, 30), darkMetal, Enum.Material.Metal)

    -- Caution signs
    makePart(folder, "CautionSign1", Vector3.new(0.5, 6, 4), o + Vector3.new(-20, 3, 45), yellow, Enum.Material.SmoothPlastic)
    makePart(folder, "CautionSign2", Vector3.new(0.5, 6, 4), o + Vector3.new(10, 3, 45), yellow, Enum.Material.SmoothPlastic)

    return folder
end


----------------------------------------------------------------------
-- MAP 5: AQUARIUM
----------------------------------------------------------------------

function MapGenerator.CreateAquarium(origin)
    local folder = Instance.new("Folder")
    folder.Name = "Aquarium"

    local o = origin or Vector3.new(0, 0, 200)
    local deepBlue = Color3.fromRGB(20, 50, 100)
    local lightBlue = Color3.fromRGB(100, 180, 220)
    local glass = Color3.fromRGB(180, 220, 240)
    local sand = Color3.fromRGB(220, 200, 150)
    local coral1 = Color3.fromRGB(255, 100, 120)
    local coral2 = Color3.fromRGB(255, 150, 50)
    local coral3 = Color3.fromRGB(150, 50, 200)
    local seaGreen = Color3.fromRGB(50, 180, 130)
    local rock = Color3.fromRGB(100, 100, 110)
    local darkFloor = Color3.fromRGB(30, 40, 60)

    -- Floor (dark tile - aquarium walkway)
    makePart(folder, "Floor", Vector3.new(110, 2, 90), o + Vector3.new(0, -1, 0), darkFloor, Enum.Material.Slate)

    -- Ceiling (dark)
    makePart(folder, "Ceiling", Vector3.new(110, 1, 90), o + Vector3.new(0, 20, 0), Color3.fromRGB(20, 20, 30), Enum.Material.SmoothPlastic)

    -- Glass tank walls (transparent blue)
    makePart(folder, "TankLeft", Vector3.new(2, 16, 70), o + Vector3.new(-40, 8, 0), glass, Enum.Material.Glass, 0.4)
    makePart(folder, "TankRight", Vector3.new(2, 16, 70), o + Vector3.new(40, 8, 0), glass, Enum.Material.Glass, 0.4)
    makePart(folder, "TankBack", Vector3.new(80, 16, 2), o + Vector3.new(0, 8, -35), glass, Enum.Material.Glass, 0.4)

    -- Outer walls (dark)
    makePart(folder, "WallLeft", Vector3.new(2, 20, 90), o + Vector3.new(-55, 10, 0), deepBlue, Enum.Material.SmoothPlastic)
    makePart(folder, "WallRight", Vector3.new(2, 20, 90), o + Vector3.new(55, 10, 0), deepBlue, Enum.Material.SmoothPlastic)
    makePart(folder, "WallBack", Vector3.new(110, 20, 2), o + Vector3.new(0, 10, -45), deepBlue, Enum.Material.SmoothPlastic)
    makePart(folder, "WallFront", Vector3.new(110, 20, 2), o + Vector3.new(0, 10, 45), deepBlue, Enum.Material.SmoothPlastic)

    -- Sand floor inside tanks
    makePart(folder, "Sand1", Vector3.new(30, 1, 30), o + Vector3.new(-20, 0.5, -15), sand, Enum.Material.Sand)
    makePart(folder, "Sand2", Vector3.new(30, 1, 30), o + Vector3.new(20, 0.5, -15), sand, Enum.Material.Sand)

    -- Coral formations
    makePart(folder, "Coral1", Vector3.new(4, 8, 4), o + Vector3.new(-25, 4, -20), coral1, Enum.Material.SmoothPlastic)
    makePart(folder, "Coral2", Vector3.new(3, 12, 3), o + Vector3.new(-20, 6, -25), coral2, Enum.Material.SmoothPlastic)
    makePart(folder, "Coral3", Vector3.new(5, 6, 5), o + Vector3.new(-15, 3, -15), coral3, Enum.Material.SmoothPlastic)
    makePart(folder, "Coral4", Vector3.new(3, 10, 3), o + Vector3.new(15, 5, -20), coral1, Enum.Material.SmoothPlastic)
    makePart(folder, "Coral5", Vector3.new(4, 7, 4), o + Vector3.new(25, 3.5, -25), seaGreen, Enum.Material.SmoothPlastic)
    makePart(folder, "Coral6", Vector3.new(6, 5, 6), o + Vector3.new(30, 2.5, -10), coral2, Enum.Material.SmoothPlastic)


    -- Rocks
    makePart(folder, "Rock1", Vector3.new(8, 5, 6), o + Vector3.new(-30, 2.5, -5), rock, Enum.Material.Slate)
    makePart(folder, "Rock2", Vector3.new(6, 4, 8), o + Vector3.new(20, 2, 5), rock, Enum.Material.Slate)
    makePart(folder, "Rock3", Vector3.new(10, 6, 8), o + Vector3.new(0, 3, -30), rock, Enum.Material.Slate)
    makePart(folder, "Rock4", Vector3.new(5, 3, 5), o + Vector3.new(-10, 1.5, 10), rock, Enum.Material.Slate)

    -- Seaweed (tall green pillars)
    for i = 1, 8 do
        makePart(folder, "Seaweed_"..i, Vector3.new(1.5, math.random(8, 14), 1.5),
            o + Vector3.new(math.random(-35, 35), math.random(4, 7), math.random(-30, 0)),
            seaGreen, Enum.Material.SmoothPlastic)
    end

    -- Viewing benches (walkway area)
    makePart(folder, "Bench1", Vector3.new(12, 3, 4), o + Vector3.new(-20, 1.5, 30), Color3.fromRGB(60, 60, 70), Enum.Material.SmoothPlastic)
    makePart(folder, "Bench2", Vector3.new(12, 3, 4), o + Vector3.new(20, 1.5, 30), Color3.fromRGB(60, 60, 70), Enum.Material.SmoothPlastic)

    -- Info stands
    makePart(folder, "InfoStand1", Vector3.new(3, 5, 3), o + Vector3.new(-35, 2.5, 25), Color3.fromRGB(40, 40, 50), Enum.Material.SmoothPlastic)
    makePart(folder, "InfoStand2", Vector3.new(3, 5, 3), o + Vector3.new(35, 2.5, 25), Color3.fromRGB(40, 40, 50), Enum.Material.SmoothPlastic)

    -- Tunnel arch (walkthrough)
    makePart(folder, "TunnelFloor", Vector3.new(15, 1, 30), o + Vector3.new(0, 0.5, 15), darkFloor, Enum.Material.Slate)
    makePart(folder, "TunnelWallL", Vector3.new(1, 12, 30), o + Vector3.new(-7, 6, 15), glass, Enum.Material.Glass, 0.5)
    makePart(folder, "TunnelWallR", Vector3.new(1, 12, 30), o + Vector3.new(7, 6, 15), glass, Enum.Material.Glass, 0.5)
    makePart(folder, "TunnelTop", Vector3.new(15, 1, 30), o + Vector3.new(0, 12, 15), glass, Enum.Material.Glass, 0.5)

    return folder
end


----------------------------------------------------------------------
-- MAP 6: HAUNTED HOUSE
----------------------------------------------------------------------

function MapGenerator.CreateHauntedHouse(origin)
    local folder = Instance.new("Folder")
    folder.Name = "HauntedHouse"

    local o = origin or Vector3.new(0, 0, 200)
    local darkPurple = Color3.fromRGB(40, 20, 50)
    local dustyWood = Color3.fromRGB(80, 55, 35)
    local cobweb = Color3.fromRGB(200, 200, 200)
    local darkRed = Color3.fromRGB(100, 20, 20)
    local ghostWhite = Color3.fromRGB(220, 220, 230)
    local candleYellow = Color3.fromRGB(255, 200, 50)
    local black = Color3.fromRGB(20, 20, 25)
    local gray = Color3.fromRGB(80, 80, 85)
    local green = Color3.fromRGB(40, 80, 40)

    -- Floor (creaky wood)
    makePart(folder, "Floor", Vector3.new(110, 2, 90), o + Vector3.new(0, -1, 0), dustyWood, Enum.Material.Wood)

    -- Ceiling
    makePart(folder, "Ceiling", Vector3.new(110, 1, 90), o + Vector3.new(0, 22, 0), black, Enum.Material.SmoothPlastic)

    -- Walls (dark purple wallpaper)
    makePart(folder, "WallBack", Vector3.new(110, 22, 2), o + Vector3.new(0, 11, -45), darkPurple, Enum.Material.Fabric)
    makePart(folder, "WallFront", Vector3.new(110, 22, 2), o + Vector3.new(0, 11, 45), darkPurple, Enum.Material.Fabric)
    makePart(folder, "WallLeft", Vector3.new(2, 22, 90), o + Vector3.new(-55, 11, 0), darkPurple, Enum.Material.Fabric)
    makePart(folder, "WallRight", Vector3.new(2, 22, 90), o + Vector3.new(55, 11, 0), darkPurple, Enum.Material.Fabric)

    -- Interior dividing walls (creates rooms)
    makePart(folder, "DivWall1", Vector3.new(2, 22, 40), o + Vector3.new(-20, 11, -25), darkPurple, Enum.Material.Fabric)
    makePart(folder, "DivWall2", Vector3.new(2, 22, 40), o + Vector3.new(20, 11, 15), darkPurple, Enum.Material.Fabric)
    makePart(folder, "DivWall3", Vector3.new(40, 22, 2), o + Vector3.new(0, 11, 0), darkPurple, Enum.Material.Fabric)

    -- Doorways (gaps in walls) - represented by empty space

    -- Grand staircase
    for step = 0, 8 do
        makePart(folder, "Stair_"..step, Vector3.new(15, 1.5, 4),
            o + Vector3.new(-40, step * 1.5 + 0.75, -30 + step * 3), dustyWood, Enum.Material.Wood)
    end
    -- Stair railing
    makePart(folder, "Railing", Vector3.new(1, 15, 30), o + Vector3.new(-47, 8, -15), dustyWood, Enum.Material.Wood)

    -- Grandfather clock
    makePart(folder, "Clock", Vector3.new(5, 16, 4), o + Vector3.new(50, 8, -40), dustyWood, Enum.Material.Wood)
    makePart(folder, "ClockFace", Vector3.new(4, 4, 0.5), o + Vector3.new(50, 14, -37.5), ghostWhite, Enum.Material.SmoothPlastic)


    -- Cobwebs (thin white parts in corners)
    makePart(folder, "Cobweb1", Vector3.new(8, 0.2, 8), o + Vector3.new(-52, 20, -42), cobweb, Enum.Material.SmoothPlastic, 0.5)
    makePart(folder, "Cobweb2", Vector3.new(8, 0.2, 8), o + Vector3.new(52, 20, -42), cobweb, Enum.Material.SmoothPlastic, 0.5)
    makePart(folder, "Cobweb3", Vector3.new(8, 0.2, 8), o + Vector3.new(-52, 20, 42), cobweb, Enum.Material.SmoothPlastic, 0.5)
    makePart(folder, "Cobweb4", Vector3.new(8, 0.2, 8), o + Vector3.new(52, 20, 42), cobweb, Enum.Material.SmoothPlastic, 0.5)

    -- Dining table with candles
    makePart(folder, "DiningTable", Vector3.new(20, 4, 10), o + Vector3.new(35, 2, 30), dustyWood, Enum.Material.Wood)
    makePart(folder, "Candle1", Vector3.new(1, 3, 1), o + Vector3.new(30, 5.5, 30), candleYellow, Enum.Material.Neon)
    makePart(folder, "Candle2", Vector3.new(1, 3, 1), o + Vector3.new(35, 5.5, 30), candleYellow, Enum.Material.Neon)
    makePart(folder, "Candle3", Vector3.new(1, 3, 1), o + Vector3.new(40, 5.5, 30), candleYellow, Enum.Material.Neon)

    -- Chairs around table
    for i = 1, 6 do
        local cx = 28 + (i * 3)
        makePart(folder, "Chair_"..i, Vector3.new(3, 6, 3), o + Vector3.new(cx, 3, 37), dustyWood, Enum.Material.Wood)
    end

    -- Creepy paintings on walls
    makePart(folder, "Painting1", Vector3.new(8, 6, 0.5), o + Vector3.new(-40, 12, -43), darkRed, Enum.Material.SmoothPlastic)
    makePart(folder, "PaintFrame1", Vector3.new(9, 7, 0.3), o + Vector3.new(-40, 12, -43.5), Color3.fromRGB(120, 80, 30), Enum.Material.Wood)
    makePart(folder, "Painting2", Vector3.new(6, 8, 0.5), o + Vector3.new(0, 12, -43), green, Enum.Material.SmoothPlastic)
    makePart(folder, "PaintFrame2", Vector3.new(7, 9, 0.3), o + Vector3.new(0, 12, -43.5), Color3.fromRGB(120, 80, 30), Enum.Material.Wood)

    -- Coffin
    makePart(folder, "Coffin", Vector3.new(4, 3, 10), o + Vector3.new(-35, 1.5, 30), black, Enum.Material.SmoothPlastic)
    makePart(folder, "CoffinLid", Vector3.new(4, 0.5, 10), o + Vector3.new(-35, 3.2, 30), dustyWood, Enum.Material.Wood)

    -- Bookshelf with dusty books
    makePart(folder, "Bookshelf", Vector3.new(3, 16, 20), o + Vector3.new(53, 8, 0), dustyWood, Enum.Material.Wood)
    makePart(folder, "DustyBooks", Vector3.new(2, 3, 18), o + Vector3.new(53, 4, 0), darkRed, Enum.Material.SmoothPlastic)
    makePart(folder, "DustyBooks2", Vector3.new(2, 3, 18), o + Vector3.new(53, 8, 0), green, Enum.Material.SmoothPlastic)

    -- Armor stand
    makePart(folder, "ArmorBody", Vector3.new(3, 8, 3), o + Vector3.new(10, 4, -40), gray, Enum.Material.Metal)
    makePart(folder, "ArmorHead", Vector3.new(3, 3, 3), o + Vector3.new(10, 9, -40), gray, Enum.Material.Metal)

    -- Broken chandelier on floor
    makePart(folder, "Chandelier", Vector3.new(8, 2, 8), o + Vector3.new(0, 1, 20), Color3.fromRGB(150, 130, 50), Enum.Material.Metal)

    return folder
end


----------------------------------------------------------------------
-- MASTER GENERATE FUNCTION
----------------------------------------------------------------------

function MapGenerator.GenerateMap(mapName, origin)
    local generators = {
        School = MapGenerator.CreateSchool,
        Supermarket = MapGenerator.CreateSupermarket,
        Bedroom = MapGenerator.CreateBedroom,
        Construction = MapGenerator.CreateConstruction,
        Aquarium = MapGenerator.CreateAquarium,
        HauntedHouse = MapGenerator.CreateHauntedHouse,
    }

    local generator = generators[mapName]
    if generator then
        return generator(origin)
    end
    return nil
end

-- Get list of all available generated maps
function MapGenerator.GetMapList()
    return { "School", "Supermarket", "Bedroom", "Construction", "Aquarium", "HauntedHouse" }
end

return MapGenerator
