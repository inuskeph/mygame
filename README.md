# 🦎 Chameleon - Paint to Hide (Roblox Game)

A multiplayer hide-and-seek game where **Hiders** paint themselves to blend into the environment while **Seekers** hunt them down. Inspired by Meccha Chameleon.

---

## 📋 Game Overview

| Phase | Duration | Description |
|-------|----------|-------------|
| **Lobby** | 30s | Wait for players (min 4) |
| **Prep** | 20s | Hiders paint themselves using color pools |
| **Hide** | 10s | Hiders find a spot and freeze in a pose |
| **Seek** | 90s | Seekers are released to find hidden players |
| **Results** | 10s | Scores displayed, then next round |

---

## 🎮 Controls

### Hiders (Chameleons)
| Key | Action |
|-----|--------|
| `B` | Toggle brush tool |
| `F` | Paint full body (uses multiple charges) |
| `1-9` | Quick-select palette color |
| `RMB` | Sample color from environment |
| `Q` | Freeze / Unfreeze |
| `E` | Next pose |
| `R` | Previous pose |
| `G` | Perform taunt (risky, bonus points!) |
| `Tab` | Cycle taunt selection |

### Seekers
| Key | Action |
|-----|--------|
| `LMB` | Tag hider (aim at them) |
| `T` | Tag nearest hider (proximity) |
| `X` | Detection pulse (cooldown: 15s) |

---

## 🗂️ Project Structure

```
ChameleonGame/
├── ServerScriptService/         -- Server-side scripts
│   ├── RoundManager.lua         -- Core game loop & state machine
│   ├── PaintServer.lua          -- Paint validation & charge management
│   ├── FreezeServer.lua         -- Freeze state management
│   ├── SeekerAbilitiesServer.lua-- Detection pulse & tag validation
│   ├── ScoringServer.lua        -- Points, coins, DataStore persistence
│   ├── TauntServer.lua          -- Taunt execution & risk management
│   └── MapManager.lua           -- Map loading, rotation, teleportation
│
├── ReplicatedStorage/
│   ├── Modules/
│   │   ├── GameConfig.lua       -- All tunable game settings
│   │   ├── PaintSystem.lua      -- Shared paint logic & palettes
│   │   └── FreezeSystem.lua     -- Shared freeze logic & poses
│   └── Events/
│       └── RemoteEvents.lua     -- Creates all RemoteEvents/Functions
│
├── StarterGui/
│   └── MainUI.lua               -- Full HUD (timer, scores, palette, results)
│
├── StarterPlayerScripts/        -- Client-side scripts
│   ├── PaintClient.lua          -- Paint input & color sampling
│   ├── FreezeClient.lua         -- Freeze toggle & pose cycling
│   ├── SeekerClient.lua         -- Seeker abilities & highlight visuals
│   └── TauntClient.lua          -- Taunt input & visual effects
│
├── StarterPlayer/
│   └── StarterCharacterScripts/ -- (for future per-character scripts)
│
└── Workspace/
    └── Maps/                    -- Map models go here
```

---

## 🚀 Setup Instructions for Roblox Studio

### Step 1: Create a New Place
1. Open **Roblox Studio**
2. Create a new **Baseplate** or **Empty** place
3. Delete the default baseplate (the game creates its own)

### Step 2: Import Scripts

For each file, create the corresponding script type in the correct location:

| File | Script Type | Location in Studio |
|------|-------------|-------------------|
| `ServerScriptService/*.lua` | **Script** (Server) | ServerScriptService |
| `ReplicatedStorage/Modules/*.lua` | **ModuleScript** | ReplicatedStorage > Modules (folder) |
| `ReplicatedStorage/Events/RemoteEvents.lua` | **ModuleScript** | ReplicatedStorage > Events (folder) |
| `StarterGui/MainUI.lua` | **LocalScript** | StarterGui |
| `StarterPlayerScripts/*.lua` | **LocalScript** | StarterPlayer > StarterPlayerScripts |

### Step 3: Create Folder Structure
In Roblox Studio Explorer, create these folders:
1. **ReplicatedStorage** > New Folder: `Modules`
2. **ReplicatedStorage** > New Folder: `Events`
3. **Workspace** > New Folder: `Maps`

### Step 4: Paste Scripts
1. For each `.lua` file, create the appropriate script type
2. Copy-paste the contents into the script
3. Rename scripts to match (remove `.lua` extension)

### Step 5: Enable DataStore (for saving)
1. Go to **Game Settings** > **Security**
2. Enable **"Enable Studio Access to API Services"**

### Step 6: Test
1. Click **Play** (F5) to test in single-player
2. Use **Test** > **Start Server** (2+ players) for multiplayer testing
3. The game auto-creates a lobby and placeholder maps

---

## ⚙️ Configuration

All game settings are in `ReplicatedStorage/Modules/GameConfig.lua`:

```lua
-- Key settings to tweak:
GameConfig.MinPlayers = 4          -- Min players to start
GameConfig.PrepPhaseTime = 20      -- Painting time
GameConfig.SeekPhaseTime = 90      -- Seeking duration
GameConfig.MaxPaintCharges = 10    -- Paint uses per round
GameConfig.DetectionPulseRadius = 30  -- Pulse range (studs)
GameConfig.TagDistance = 6         -- Tag reach (studs)
```

---

## 🗺️ Adding Custom Maps

1. Build your map as a **Model** in Workspace > Maps
2. Name it to match a key in `MapManager.Maps` (or add a new entry)
3. Use colors from the map's palette for props/walls
4. The game auto-generates placeholder maps for testing

### Map Requirements:
- Maps should use **distinct, paintable colors** from their palette
- Include varied geometry for hiding spots (boxes, walls, cylinders)
- Color pools are auto-spawned by the system
- Keep map size within ~120x120 studs

---

## 💰 Scoring System

| Action | Points |
|--------|--------|
| Survive full round (Hider) | 100 |
| Per second alive (Hider) | 1 |
| Tag a hider (Seeker) | 50 |
| Successful taunt (Hider) | 25-50 |
| Seekers win bonus | 50 |

**Coins** = Points × 0.1 (saved permanently via DataStore)

---

## 🛒 Shop / Unlockables

Players can spend coins on:
- **Poses**: T-Pose (100), Sitting (150), Lying (200), Wall Lean (250), Dab (300), Statue (500)
- **Taunts**: Dance (200), Laugh (150), Spin (300), Flex (250)

---

## 🔧 Technical Notes

- **Networking**: All game logic is server-authoritative. Clients send requests, server validates.
- **Anti-cheat**: Paint colors validated against palette, tag distance checked server-side, freeze state managed on server.
- **Performance**: Highlights and particles auto-cleanup, kill feed limited to 8 entries, auto-save every 5 minutes.
- **Data**: Uses DataStoreService with auto-save on leave, periodic saves, and `BindToClose` for shutdown safety.

---

## 📝 Future Enhancements

- [ ] More maps (Library, Toybox, Beach, Space Station)
- [ ] Spectator camera system for eliminated players
- [ ] Daily challenges for bonus coins
- [ ] Custom character skins/trails
- [ ] Matchmaking by skill level
- [ ] Mobile touch controls optimization
- [ ] VIP/Gamepass perks (extra paint charges, exclusive poses)
- [ ] Seasonal events with limited-time maps

---

## 📄 License

This game code is provided as a starter template. Customize and expand it for your own Roblox experience!
