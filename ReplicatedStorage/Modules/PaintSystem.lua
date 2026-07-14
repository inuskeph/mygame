--[[
    PaintSystem.lua (ModuleScript)
    Shared paint logic for the Chameleon game.
    Handles color application, validation, and color pool management.
    Place in ReplicatedStorage/Modules.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameConfig"))

local PaintSystem = {}

----------------------------------------------------------------------
-- PAINTABLE BODY PARTS
----------------------------------------------------------------------

-- Parts of an R15/R6 character that can be painted
PaintSystem.PaintableParts = {
    "Head",
    "UpperTorso",
    "LowerTorso",
    "LeftUpperArm",
    "LeftLowerArm",
    "LeftHand",
    "RightUpperArm",
    "RightLowerArm",
    "RightHand",
    "LeftUpperLeg",
    "LeftLowerLeg",
    "LeftFoot",
    "RightUpperLeg",
    "RightLowerLeg",
    "RightFoot",
    -- R6 fallbacks
    "Torso",
    "Left Arm",
    "Right Arm",
    "Left Leg",
    "Right Leg",
}

----------------------------------------------------------------------
-- COLOR PALETTE (per-map)
----------------------------------------------------------------------

-- Default color palette - maps can override this
PaintSystem.DefaultPalette = {
    Color3.fromRGB(139, 90, 43),    -- Brown (wood)
    Color3.fromRGB(91, 154, 76),    -- Green (grass)
    Color3.fromRGB(163, 162, 165),  -- Gray (concrete)
    Color3.fromRGB(242, 243, 243),  -- White (walls)
    Color3.fromRGB(27, 42, 53),     -- Dark gray (metal)
    Color3.fromRGB(218, 134, 122),  -- Brick red
    Color3.fromRGB(255, 201, 67),   -- Yellow
    Color3.fromRGB(107, 164, 184),  -- Sky blue
    Color3.fromRGB(75, 151, 75),    -- Dark green
    Color3.fromRGB(196, 112, 58),   -- Tan/sand
    Color3.fromRGB(86, 66, 54),     -- Dark brown
    Color3.fromRGB(200, 200, 200),  -- Light gray
}

-- Map-specific palettes (key = map name)
PaintSystem.MapPalettes = {
    Playground = {
        Color3.fromRGB(91, 154, 76),    -- Green grass
        Color3.fromRGB(139, 90, 43),    -- Brown wood
        Color3.fromRGB(163, 162, 165),  -- Gray concrete
        Color3.fromRGB(242, 243, 243),  -- White walls
        Color3.fromRGB(218, 134, 122),  -- Brick
        Color3.fromRGB(255, 201, 67),   -- Yellow slide
        Color3.fromRGB(13, 105, 172),   -- Blue plastic
        Color3.fromRGB(255, 85, 0),     -- Orange
    },
    Kitchen = {
        Color3.fromRGB(242, 243, 243),  -- White appliances
        Color3.fromRGB(27, 42, 53),     -- Black countertop
        Color3.fromRGB(139, 90, 43),    -- Brown cabinets
        Color3.fromRGB(163, 162, 165),  -- Stainless steel
        Color3.fromRGB(194, 218, 184),  -- Light green tile
        Color3.fromRGB(255, 201, 67),   -- Yellow accents
    },
    Forest = {
        Color3.fromRGB(75, 151, 75),    -- Dark green foliage
        Color3.fromRGB(91, 154, 76),    -- Light green leaves
        Color3.fromRGB(86, 66, 54),     -- Dark brown bark
        Color3.fromRGB(139, 90, 43),    -- Medium brown
        Color3.fromRGB(196, 112, 58),   -- Tan earth
        Color3.fromRGB(163, 162, 165),  -- Gray rock
        Color3.fromRGB(37, 65, 23),     -- Very dark green
    },
}

----------------------------------------------------------------------
-- HELPER FUNCTIONS
----------------------------------------------------------------------

-- Get the palette for the current map
function PaintSystem.GetPalette(mapName)
    return PaintSystem.MapPalettes[mapName] or PaintSystem.DefaultPalette
end

-- Sample color from a part in the world (for color picker)
function PaintSystem.SampleColor(part)
    if part and part:IsA("BasePart") then
        return part.Color
    end
    return nil
end

-- Find the closest palette color to a given color
function PaintSystem.FindClosestPaletteColor(targetColor, palette)
    local closestColor = palette[1]
    local closestDist = math.huge

    for _, color in ipairs(palette) do
        local dist = (targetColor.R - color.R)^2 + (targetColor.G - color.G)^2 + (targetColor.B - color.B)^2
        if dist < closestDist then
            closestDist = dist
            closestColor = color
        end
    end

    return closestColor
end

-- Validate that a color is in the allowed palette
function PaintSystem.IsColorAllowed(color, mapName)
    local palette = PaintSystem.GetPalette(mapName)
    local tolerance = 0.01 -- Small tolerance for floating point

    for _, allowedColor in ipairs(palette) do
        local dist = (color.R - allowedColor.R)^2 + (color.G - allowedColor.G)^2 + (color.B - allowedColor.B)^2
        if dist < tolerance then
            return true
        end
    end
    return false
end

-- Apply paint to a specific body part
function PaintSystem.ApplyPaint(character, partName, color)
    if not character then return false end

    local part = character:FindFirstChild(partName)
    if part and part:IsA("BasePart") then
        part.Color = color
        return true
    end
    return false
end

-- Apply paint to all body parts (full body paint)
function PaintSystem.ApplyFullBodyPaint(character, color)
    if not character then return false end

    local painted = 0
    for _, partName in ipairs(PaintSystem.PaintableParts) do
        local part = character:FindFirstChild(partName)
        if part and part:IsA("BasePart") then
            part.Color = color
            painted += 1
        end
    end
    return painted > 0
end

-- Get the current colors of a character (for comparison)
function PaintSystem.GetCharacterColors(character)
    local colors = {}
    if not character then return colors end

    for _, partName in ipairs(PaintSystem.PaintableParts) do
        local part = character:FindFirstChild(partName)
        if part and part:IsA("BasePart") then
            colors[partName] = part.Color
        end
    end
    return colors
end

-- Calculate how well a character blends with surrounding parts
function PaintSystem.CalculateCamouflageScore(character, nearbyParts)
    if not character then return 0 end

    local charColors = PaintSystem.GetCharacterColors(character)
    if not next(charColors) then return 0 end

    -- Get average character color
    local totalR, totalG, totalB, count = 0, 0, 0, 0
    for _, color in pairs(charColors) do
        totalR += color.R
        totalG += color.G
        totalB += color.B
        count += 1
    end
    local avgCharColor = Color3.new(totalR / count, totalG / count, totalB / count)

    -- Compare to nearby environment colors
    local totalDifference = 0
    local envCount = 0
    for _, part in ipairs(nearbyParts) do
        if part:IsA("BasePart") and not part:IsDescendantOf(character) then
            local envColor = part.Color
            local diff = math.sqrt(
                (avgCharColor.R - envColor.R)^2 +
                (avgCharColor.G - envColor.G)^2 +
                (avgCharColor.B - envColor.B)^2
            )
            totalDifference += diff
            envCount += 1
        end
    end

    if envCount == 0 then return 0 end

    -- Return score from 0 (no blend) to 1 (perfect blend)
    local avgDiff = totalDifference / envCount
    local maxDiff = math.sqrt(3) -- Max possible color difference
    return 1 - math.clamp(avgDiff / maxDiff, 0, 1)
end

return PaintSystem
