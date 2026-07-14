--[[
    GameConfig.lua
    Central configuration for the Chameleon game.
    Tweak these values to balance gameplay.
]]

local GameConfig = {}

-- Player counts
GameConfig.MinPlayers = 4          -- Minimum players to start a round
GameConfig.MaxPlayers = 12         -- Maximum players per server
GameConfig.SeekerRatio = 0.25      -- Fraction of players that become seekers (rounded up)

-- Round Timers (seconds)
GameConfig.LobbyWaitTime = 30      -- Time waiting in lobby for players
GameConfig.PrepPhaseTime = 20      -- Time for hiders to paint themselves
GameConfig.HidePhaseTime = 10      -- Extra time for hiders to find a spot (seekers blinded)
GameConfig.SeekPhaseTime = 90      -- Time seekers have to find hiders
GameConfig.ResultsTime = 10        -- Time to show results before next round

-- Paint System
GameConfig.MaxPaintCharges = 10    -- Number of paint strokes per hider
GameConfig.PaintRefillTime = 3     -- Seconds to refill one paint charge at a color pool
GameConfig.BrushSize = 1           -- Default brush size (1 = single part, 2 = adjacent parts)

-- Seeker Abilities
GameConfig.DetectionPulseCooldown = 15   -- Seconds between detection pulses
GameConfig.DetectionPulseRadius = 30     -- Studs radius for detection pulse
GameConfig.HighlightDuration = 2         -- Seconds a detected hider is highlighted
GameConfig.TagDistance = 6               -- Studs distance to tag a hider

-- Scoring
GameConfig.PointsPerSurvive = 100        -- Points for surviving the full round (hider)
GameConfig.PointsPerSecondAlive = 1      -- Points per second alive (hider)
GameConfig.PointsPerTag = 50             -- Points for tagging a hider (seeker)
GameConfig.PointsPerTaunt = 25           -- Bonus points for successfully taunting (hider)
GameConfig.CoinsPerPoint = 0.1           -- Coins earned = points * this multiplier

-- Freeze System
GameConfig.FreezeDelay = 0.5             -- Seconds to fully freeze (transition)
GameConfig.NametagHideOnFreeze = true    -- Hide nametag when frozen

-- Taunt System
GameConfig.TauntCooldown = 10            -- Seconds between taunts
GameConfig.TauntDuration = 2             -- How long taunt animation/sound plays
GameConfig.TauntDetectionBonus = 1.5     -- Multiplier to detection radius during taunt

-- Map Configuration
GameConfig.DefaultMap = "Playground"      -- Default map name
GameConfig.MapRotation = true            -- Rotate maps between rounds

return GameConfig
