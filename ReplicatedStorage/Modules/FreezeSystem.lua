--[[
    FreezeSystem.lua (ModuleScript)
    Shared freeze logic for the Chameleon game.
    Handles freezing/unfreezing characters, hiding nametags, and pose management.
    Place in ReplicatedStorage/Modules.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameConfig"))

local FreezeSystem = {}

----------------------------------------------------------------------
-- POSE PRESETS
----------------------------------------------------------------------

-- Predefined poses (CFrame offsets for limbs relative to HumanoidRootPart)
-- These are simplified - in practice you'd use Motor6D manipulation or AnimationTracks
FreezeSystem.Poses = {
    Standing = {
        name = "Standing",
        description = "Default standing pose",
    },
    TShaped = {
        name = "T-Pose",
        description = "Arms stretched out like a T",
    },
    Crouching = {
        name = "Crouching",
        description = "Low crouch to blend with short objects",
    },
    Sitting = {
        name = "Sitting",
        description = "Sitting pose for benches/chairs",
    },
    Lying = {
        name = "Lying Down",
        description = "Flat on the ground",
    },
    WallLean = {
        name = "Wall Lean",
        description = "Leaning against a wall",
    },
    Statue = {
        name = "Statue",
        description = "Arms raised like a statue",
    },
    Dabbing = {
        name = "Dab",
        description = "The classic dab pose",
    },
}

-- Animation IDs for poses (these would be actual Roblox animation asset IDs)
-- Replace with your own uploaded animations
FreezeSystem.PoseAnimations = {
    Standing = nil, -- Uses default idle
    TShaped = "rbxassetid://0", -- Replace with actual ID
    Crouching = "rbxassetid://0",
    Sitting = "rbxassetid://0",
    Lying = "rbxassetid://0",
    WallLean = "rbxassetid://0",
    Statue = "rbxassetid://0",
    Dabbing = "rbxassetid://0",
}

----------------------------------------------------------------------
-- FREEZE STATE TRACKING
----------------------------------------------------------------------

-- Tracks frozen players on the server (replicated via attributes)
FreezeSystem.FrozenPlayers = {} -- {[Player] = {frozen = bool, pose = string, position = Vector3}}

----------------------------------------------------------------------
-- CORE FUNCTIONS
----------------------------------------------------------------------

-- Freeze a character in place
function FreezeSystem.Freeze(character)
    if not character then return false end

    local humanoid = character:FindFirstChild("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not rootPart then return false end

    -- Disable movement
    humanoid.WalkSpeed = 0
    humanoid.JumpPower = 0
    humanoid.JumpHeight = 0

    -- Anchor the root part to prevent any physics movement
    rootPart.Anchored = true

    -- Set attribute for other scripts to check
    character:SetAttribute("IsFrozen", true)
    character:SetAttribute("FreezeTime", tick())

    -- Hide nametag if configured
    if GameConfig.NametagHideOnFreeze then
        FreezeSystem.HideNametag(character)
    end

    return true
end

-- Unfreeze a character
function FreezeSystem.Unfreeze(character)
    if not character then return false end

    local humanoid = character:FindFirstChild("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not rootPart then return false end

    -- Re-enable movement
    humanoid.WalkSpeed = 16 -- Default Roblox walk speed
    humanoid.JumpPower = 50
    humanoid.JumpHeight = 7.2

    -- Unanchor
    rootPart.Anchored = false

    -- Clear attribute
    character:SetAttribute("IsFrozen", false)
    character:SetAttribute("FreezeTime", nil)

    -- Show nametag again
    FreezeSystem.ShowNametag(character)

    return true
end

-- Check if a character is frozen
function FreezeSystem.IsFrozen(character)
    if not character then return false end
    return character:GetAttribute("IsFrozen") == true
end

----------------------------------------------------------------------
-- NAMETAG MANAGEMENT
----------------------------------------------------------------------

function FreezeSystem.HideNametag(character)
    if not character then return end

    local humanoid = character:FindFirstChild("Humanoid")
    if humanoid then
        humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    end

    -- Also hide any custom BillboardGui nametags
    local head = character:FindFirstChild("Head")
    if head then
        for _, child in ipairs(head:GetChildren()) do
            if child:IsA("BillboardGui") then
                child.Enabled = false
            end
        end
    end
end

function FreezeSystem.ShowNametag(character)
    if not character then return end

    local humanoid = character:FindFirstChild("Humanoid")
    if humanoid then
        humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
    end

    -- Show custom BillboardGui nametags
    local head = character:FindFirstChild("Head")
    if head then
        for _, child in ipairs(head:GetChildren()) do
            if child:IsA("BillboardGui") then
                child.Enabled = true
            end
        end
    end
end

----------------------------------------------------------------------
-- POSE SYSTEM
----------------------------------------------------------------------

-- Apply a pose to a character (plays animation and freezes)
function FreezeSystem.ApplyPose(character, poseName)
    if not character then return false end
    if not FreezeSystem.Poses[poseName] then return false end

    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return false end

    -- Store current pose
    character:SetAttribute("CurrentPose", poseName)

    -- Get animation ID
    local animId = FreezeSystem.PoseAnimations[poseName]
    if animId and animId ~= "rbxassetid://0" then
        -- Load and play the pose animation
        local animator = humanoid:FindFirstChild("Animator")
        if not animator then
            animator = Instance.new("Animator")
            animator.Parent = humanoid
        end

        local animation = Instance.new("Animation")
        animation.AnimationId = animId

        local track = animator:LoadAnimation(animation)
        track.Priority = Enum.AnimationPriority.Action4
        track.Looped = false
        track:Play()

        -- Stop at last frame to hold the pose
        track:AdjustSpeed(0)
        track.TimePosition = track.Length

        -- Store reference for cleanup
        character:SetAttribute("PoseTrackId", tostring(track))
    end

    return true
end

-- Get the current pose of a character
function FreezeSystem.GetCurrentPose(character)
    if not character then return "Standing" end
    return character:GetAttribute("CurrentPose") or "Standing"
end

-- Get list of available pose names
function FreezeSystem.GetPoseList()
    local poses = {}
    for name, data in pairs(FreezeSystem.Poses) do
        table.insert(poses, {
            name = name,
            displayName = data.name,
            description = data.description,
        })
    end
    return poses
end

----------------------------------------------------------------------
-- UTILITY
----------------------------------------------------------------------

-- Reset character to normal state (used between rounds)
function FreezeSystem.ResetCharacter(character)
    if not character then return end

    FreezeSystem.Unfreeze(character)
    character:SetAttribute("CurrentPose", nil)
    character:SetAttribute("FreezeTime", nil)

    -- Stop any pose animations
    local humanoid = character:FindFirstChild("Humanoid")
    if humanoid then
        local animator = humanoid:FindFirstChild("Animator")
        if animator then
            for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                track:Stop()
            end
        end
    end
end

return FreezeSystem
