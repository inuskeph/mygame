--[[
    DummyCharacter.lua (Script)
    Transforms hiders into blank white dummy characters.
    Removes all accessories, clothing, face, and body colors.
    Makes them a plain white mannequin that can be painted.
    Place in ServerScriptService.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Events = ReplicatedStorage:WaitForChild("Events")
local RoleAssigned = Events:WaitForChild("RoleAssigned")
local RoundStateChanged = Events:WaitForChild("RoundStateChanged")

local DummyCharacter = {}

-- Store original character appearance to restore later
DummyCharacter.OriginalAppearances = {} -- {[Player] = {descriptions}}

----------------------------------------------------------------------
-- MAKE DUMMY (strip character to blank white mannequin)
----------------------------------------------------------------------

function DummyCharacter.MakeDummy(player)
    local character = player.Character
    if not character then return end

    -- Store what we remove so we can restore later
    DummyCharacter.OriginalAppearances[player] = {}

    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return end

    -- Remove all accessories (hats, hair, etc.)
    for _, accessory in ipairs(character:GetChildren()) do
        if accessory:IsA("Accessory") then
            accessory.Parent = nil -- Move out temporarily
            table.insert(DummyCharacter.OriginalAppearances[player], {
                type = "Accessory",
                instance = accessory,
            })
        end
    end

    -- Remove shirts and pants
    for _, clothing in ipairs(character:GetChildren()) do
        if clothing:IsA("Shirt") or clothing:IsA("Pants") or clothing:IsA("ShirtGraphic") then
            clothing.Parent = nil
            table.insert(DummyCharacter.OriginalAppearances[player], {
                type = "Clothing",
                instance = clothing,
            })
        end
    end

    -- Remove face
    local head = character:FindFirstChild("Head")
    if head then
        for _, decal in ipairs(head:GetChildren()) do
            if decal:IsA("Decal") and decal.Name == "face" then
                decal.Parent = nil
                table.insert(DummyCharacter.OriginalAppearances[player], {
                    type = "Face",
                    instance = decal,
                    parent = head,
                })
            end
        end
    end

    -- Remove body colors (BodyColors instance)
    local bodyColors = character:FindFirstChildOfClass("BodyColors")
    if bodyColors then
        bodyColors.Parent = nil
        table.insert(DummyCharacter.OriginalAppearances[player], {
            type = "BodyColors",
            instance = bodyColors,
        })
    end

    -- Set all body parts to plain white
    local white = Color3.fromRGB(255, 255, 255)
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            part.Color = white
            part.Material = Enum.Material.SmoothPlastic
        end
    end

    -- Remove MeshParts texture (if using R15 with textures)
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("MeshPart") then
            part.TextureID = ""
        end
    end

    -- Hide nametag during game
    if humanoid then
        humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    end

    print("[DummyCharacter] Made", player.Name, "into a dummy")
end

----------------------------------------------------------------------
-- RESTORE ORIGINAL APPEARANCE
----------------------------------------------------------------------

function DummyCharacter.RestoreAppearance(player)
    local character = player.Character
    if not character then return end

    local saved = DummyCharacter.OriginalAppearances[player]
    if not saved then return end

    -- Restore all saved items
    for _, item in ipairs(saved) do
        if item.instance then
            if item.type == "Face" and item.parent then
                item.instance.Parent = item.parent
            else
                item.instance.Parent = character
            end
        end
    end

    -- Restore nametag
    local humanoid = character:FindFirstChild("Humanoid")
    if humanoid then
        humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
    end

    -- Clear saved data
    DummyCharacter.OriginalAppearances[player] = nil

    print("[DummyCharacter] Restored", player.Name, "appearance")
end

----------------------------------------------------------------------
-- MAKE ALL HIDERS INTO DUMMIES
----------------------------------------------------------------------

function DummyCharacter.TransformHiders(hiders)
    for _, player in ipairs(hiders) do
        DummyCharacter.MakeDummy(player)
    end
end

function DummyCharacter.RestoreAll()
    for player, _ in pairs(DummyCharacter.OriginalAppearances) do
        if player and player.Parent then
            DummyCharacter.RestoreAppearance(player)
        end
    end
    DummyCharacter.OriginalAppearances = {}
end

----------------------------------------------------------------------
-- CLEANUP
----------------------------------------------------------------------

Players.PlayerRemoving:Connect(function(player)
    DummyCharacter.OriginalAppearances[player] = nil
end)

return DummyCharacter
