--[[
    VoteClient.lua (LocalScript)
    Client-side map voting UI.
    Shows 3 map options during lobby, players click to vote.
    Place in StarterPlayerScripts.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Events = ReplicatedStorage:WaitForChild("Events")
local VoteStart = Events:WaitForChild("VoteStart")
local VoteUpdate = Events:WaitForChild("VoteUpdate")
local VoteEnd = Events:WaitForChild("VoteEnd")
local CastVote = Events:WaitForChild("CastVote")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

----------------------------------------------------------------------
-- UI CREATION
----------------------------------------------------------------------

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "VoteGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Enabled = false
screenGui.DisplayOrder = 60
screenGui.Parent = playerGui

-- Main container
local mainFrame = Instance.new("Frame")
mainFrame.Name = "VoteFrame"
mainFrame.Size = UDim2.new(0, 700, 0, 350)
mainFrame.Position = UDim2.new(0.5, -350, 0.5, -175)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
mainFrame.BackgroundTransparency = 0.1
mainFrame.Parent = screenGui


local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 16)
corner.Parent = mainFrame

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(100, 150, 255)
stroke.Thickness = 2
stroke.Parent = mainFrame

-- Title
local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, 0, 0, 50)
title.Position = UDim2.new(0, 0, 0, 5)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Text = "VOTE FOR THE NEXT MAP"
title.TextSize = 24
title.Font = Enum.Font.GothamBlack
title.Parent = mainFrame

-- Subtitle (timer)
local subtitle = Instance.new("TextLabel")
subtitle.Name = "Subtitle"
subtitle.Size = UDim2.new(1, 0, 0, 25)
subtitle.Position = UDim2.new(0, 0, 0, 45)
subtitle.BackgroundTransparency = 1
subtitle.TextColor3 = Color3.fromRGB(180, 180, 200)
subtitle.Text = "Click a map to vote!"
subtitle.TextSize = 14
subtitle.Font = Enum.Font.Gotham
subtitle.Parent = mainFrame

-- Cards container
local cardsFrame = Instance.new("Frame")
cardsFrame.Name = "Cards"
cardsFrame.Size = UDim2.new(1, -30, 1, -90)
cardsFrame.Position = UDim2.new(0, 15, 0, 80)
cardsFrame.BackgroundTransparency = 1
cardsFrame.Parent = mainFrame

local cardsLayout = Instance.new("UIListLayout")
cardsLayout.FillDirection = Enum.FillDirection.Horizontal
cardsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
cardsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
cardsLayout.Padding = UDim.new(0, 15)
cardsLayout.Parent = cardsFrame


----------------------------------------------------------------------
-- CARD CREATION
----------------------------------------------------------------------

local cardButtons = {} -- Store references to card buttons
local myVoteIndex = nil

local function createMapCard(index, mapData)
    local card = Instance.new("TextButton")
    card.Name = "Card_" .. index
    card.Size = UDim2.new(0, 200, 0, 240)
    card.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
    card.Text = ""
    card.AutoButtonColor = false
    card.Parent = cardsFrame

    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 12)
    cardCorner.Parent = card

    local cardStroke = Instance.new("UIStroke")
    cardStroke.Name = "CardStroke"
    cardStroke.Color = Color3.fromRGB(80, 80, 120)
    cardStroke.Thickness = 2
    cardStroke.Parent = card

    -- Icon
    local icon = Instance.new("TextLabel")
    icon.Name = "Icon"
    icon.Size = UDim2.new(1, 0, 0, 60)
    icon.Position = UDim2.new(0, 0, 0, 15)
    icon.BackgroundTransparency = 1
    icon.Text = mapData.icon or "🗺️"
    icon.TextSize = 40
    icon.Parent = card

    -- Map name
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "MapName"
    nameLabel.Size = UDim2.new(1, -10, 0, 30)
    nameLabel.Position = UDim2.new(0, 5, 0, 80)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.Text = mapData.displayName or mapData.name
    nameLabel.TextSize = 16
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextWrapped = true
    nameLabel.Parent = card

    -- Description
    local desc = Instance.new("TextLabel")
    desc.Name = "Description"
    desc.Size = UDim2.new(1, -10, 0, 40)
    desc.Position = UDim2.new(0, 5, 0, 110)
    desc.BackgroundTransparency = 1
    desc.TextColor3 = Color3.fromRGB(160, 160, 180)
    desc.Text = mapData.description or ""
    desc.TextSize = 12
    desc.Font = Enum.Font.Gotham
    desc.TextWrapped = true
    desc.Parent = card


    -- Vote count display
    local voteCount = Instance.new("TextLabel")
    voteCount.Name = "VoteCount"
    voteCount.Size = UDim2.new(1, 0, 0, 35)
    voteCount.Position = UDim2.new(0, 0, 0, 160)
    voteCount.BackgroundTransparency = 1
    voteCount.TextColor3 = Color3.fromRGB(255, 200, 50)
    voteCount.Text = "0 votes"
    voteCount.TextSize = 18
    voteCount.Font = Enum.Font.GothamBold
    voteCount.Parent = card

    -- "YOUR VOTE" indicator (hidden by default)
    local yourVote = Instance.new("TextLabel")
    yourVote.Name = "YourVote"
    yourVote.Size = UDim2.new(1, 0, 0, 25)
    yourVote.Position = UDim2.new(0, 0, 0, 200)
    yourVote.BackgroundTransparency = 1
    yourVote.TextColor3 = Color3.fromRGB(100, 255, 100)
    yourVote.Text = "YOUR VOTE"
    yourVote.TextSize = 12
    yourVote.Font = Enum.Font.GothamBlack
    yourVote.Visible = false
    yourVote.Parent = card

    -- Click handler
    card.MouseButton1Click:Connect(function()
        myVoteIndex = index
        CastVote:FireServer(index)

        -- Visual feedback: highlight selected card
        for idx, btn in ipairs(cardButtons) do
            local s = btn:FindFirstChild("CardStroke")
            local yv = btn:FindFirstChild("YourVote")
            if idx == index then
                if s then s.Color = Color3.fromRGB(100, 255, 100); s.Thickness = 3 end
                if yv then yv.Visible = true end
                btn.BackgroundColor3 = Color3.fromRGB(30, 50, 30)
            else
                if s then s.Color = Color3.fromRGB(80, 80, 120); s.Thickness = 2 end
                if yv then yv.Visible = false end
                btn.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
            end
        end
    end)

    -- Hover effects
    card.MouseEnter:Connect(function()
        if myVoteIndex ~= index then
            TweenService:Create(card, TweenInfo.new(0.2), {
                BackgroundColor3 = Color3.fromRGB(40, 40, 70)
            }):Play()
        end
    end)

    card.MouseLeave:Connect(function()
        if myVoteIndex ~= index then
            TweenService:Create(card, TweenInfo.new(0.2), {
                BackgroundColor3 = Color3.fromRGB(30, 30, 50)
            }):Play()
        end
    end)

    table.insert(cardButtons, card)
    return card
end


----------------------------------------------------------------------
-- EVENT HANDLERS
----------------------------------------------------------------------

-- Vote started: show UI with 3 map options
VoteStart.OnClientEvent:Connect(function(voteData)
    -- Clear old cards
    for _, btn in ipairs(cardButtons) do
        btn:Destroy()
    end
    cardButtons = {}
    myVoteIndex = nil

    -- Create new cards
    for i, mapData in ipairs(voteData) do
        createMapCard(i, mapData)
    end

    -- Show the UI with animation
    screenGui.Enabled = true
    mainFrame.Position = UDim2.new(0.5, -350, 0, -400)
    TweenService:Create(mainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, -350, 0.5, -175)
    }):Play()

    subtitle.Text = "Click a map to vote!"
end)

-- Vote counts updated
VoteUpdate.OnClientEvent:Connect(function(voteCounts)
    for i, btn in ipairs(cardButtons) do
        local countLabel = btn:FindFirstChild("VoteCount")
        if countLabel and voteCounts[i] then
            local count = voteCounts[i]
            countLabel.Text = count .. (count == 1 and " vote" or " votes")

            -- Pulse animation on update
            TweenService:Create(countLabel, TweenInfo.new(0.1), {
                TextSize = 22
            }):Play()
            task.delay(0.1, function()
                TweenService:Create(countLabel, TweenInfo.new(0.2), {
                    TextSize = 18
                }):Play()
            end)
        end
    end
end)

-- Vote ended: show winner then hide
VoteEnd.OnClientEvent:Connect(function(resultData)
    -- Highlight winner card
    for i, btn in ipairs(cardButtons) do
        local s = btn:FindFirstChild("CardStroke")
        if i == resultData.winnerIndex then
            if s then s.Color = Color3.fromRGB(255, 220, 50); s.Thickness = 4 end
            btn.BackgroundColor3 = Color3.fromRGB(50, 45, 20)

            -- Winner animation
            TweenService:Create(btn, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
                Size = UDim2.new(0, 220, 0, 255)
            }):Play()
        else
            if s then s.Color = Color3.fromRGB(50, 50, 60); s.Thickness = 1 end
            btn.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
            -- Fade losers
            TweenService:Create(btn, TweenInfo.new(0.3), {
                BackgroundTransparency = 0.5
            }):Play()
        end
    end

    -- Update title
    title.Text = resultData.winnerIcon .. " " .. resultData.winnerName .. " WINS!"
    title.TextColor3 = Color3.fromRGB(255, 220, 50)
    subtitle.Text = "Loading map..."

    -- Hide after 3 seconds
    task.delay(3, function()
        TweenService:Create(mainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Position = UDim2.new(0.5, -350, 1, 100)
        }):Play()

        task.delay(0.5, function()
            screenGui.Enabled = false
            -- Reset for next vote
            title.Text = "VOTE FOR THE NEXT MAP"
            title.TextColor3 = Color3.fromRGB(255, 255, 255)
        end)
    end)
end)

print("[VoteClient] Vote UI loaded. Waiting for vote to start...")
