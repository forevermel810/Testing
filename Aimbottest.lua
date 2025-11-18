--[[
getgenv().Aimbot = {
    Enabled = false,
    UseTeamCheck = false,
    UseVisibilityCheck = true,
    TargetPart = "Head",
    IgnoredTeams = {},
    MaxAngle = 120,
    SpeedAndSmoothness = 8,
    ESP = false
}
loadstring(game:HttpGet("https://raw.githubusercontent.com/forevermel810/Testing/main/Aimbottest.lua"))()
]]

-- SETTINGS TABLE REFERENCE
local Settings = getgenv().Aimbot

-- SERVICES
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UIS = game:GetService("UserInputService")

-- FIXED HELPER FUNCTIONS
local function enemy(player)
    if not Settings.UseTeamCheck then
        return true  -- If team check is off, everyone is enemy
    end
    
    if not player.Team then
        return true  -- If player has no team, they're enemy
    end
    
    -- Check if same team
    if player.Team == LocalPlayer.Team then
        return false
    end
    
    -- FIXED: Check team NAMES instead of team objects
    for _, ignoredTeamName in ipairs(Settings.IgnoredTeams) do
        if player.Team.Name == ignoredTeamName then
            return false
        end
    end
    
    return true
end

local function visible(part)
    if not (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head")) then return false end
    local origin = LocalPlayer.Character.Head.Position
    local dir = part.Position - origin
    local ray = Ray.new(origin, dir)
    local hit = Workspace:FindPartOnRayWithIgnoreList(ray, {LocalPlayer.Character})
    return hit and hit:IsDescendantOf(part.Parent)
end

local function getTarget()
    if not LocalPlayer.Character then return end
    local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local camLook = Camera.CFrame.LookVector
    local best, bestDot = nil, -1
    local maxDot = math.cos(math.rad(Settings.MaxAngle))

    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local hum = plr.Character:FindFirstChild("Humanoid")
            local part = plr.Character:FindFirstChild(Settings.TargetPart)

            if hum and hum.Health > 0 and part then
                if enemy(plr) and (not Settings.UseVisibilityCheck or visible(part)) then
                    local dir = (part.Position - hrp.Position).Unit
                    local dot = dir:Dot(camLook)
                    if dot > bestDot and dot >= maxDot then
                        bestDot = dot
                        best = part
                    end
                end
            end
        end
    end
    return best
end

-- CAMERA LOCK LOOP
if getgenv().AimbotConnection then getgenv().AimbotConnection:Disconnect() end
local smooth = Camera.CFrame

getgenv().AimbotConnection = RunService.RenderStepped:Connect(function(dt)
    local target = getTarget()
    local current = Camera.CFrame

    if Settings.Enabled and target then
        local goal = CFrame.new(current.Position, target.Position)
        smooth = current:Lerp(goal, math.clamp(Settings.SpeedAndSmoothness * dt, 0, 1))
    else
        smooth = current
    end

    Camera.CFrame = smooth
end)

-- GUI
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
if PlayerGui:FindFirstChild("AimbotUI") then PlayerGui.AimbotUI:Destroy() end

local gui = Instance.new("ScreenGui", PlayerGui)
gui.Name = "AimbotUI"
gui.ResetOnSpawn = false

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 200, 0, 180)
mainFrame.Position = UDim2.new(0, 10, 0, 10)
mainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = mainFrame

-- AIMBOT TOGGLE
local aimbotToggle = Instance.new("TextButton")
aimbotToggle.Size = UDim2.new(0.9, 0, 0, 30)
aimbotToggle.Position = UDim2.new(0.05, 0, 0.05, 0)
aimbotToggle.Text = "AIMBOT: OFF"
aimbotToggle.Font = Enum.Font.SourceSansBold
aimbotToggle.TextSize = 14
aimbotToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
aimbotToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
aimbotToggle.BorderSizePixel = 0
aimbotToggle.Parent = mainFrame

-- ESP TOGGLE
local espToggle = Instance.new("TextButton")
espToggle.Size = UDim2.new(0.9, 0, 0, 30)
espToggle.Position = UDim2.new(0.05, 0, 0.25, 0)
espToggle.Text = "ESP: OFF"
espToggle.Font = Enum.Font.SourceSansBold
espToggle.TextSize = 14
espToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
espToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
espToggle.BorderSizePixel = 0
espToggle.Parent = mainFrame

-- TEAM CHECK TOGGLE
local teamToggle = Instance.new("TextButton")
teamToggle.Size = UDim2.new(0.9, 0, 0, 30)
teamToggle.Position = UDim2.new(0.05, 0, 0.45, 0)
teamToggle.Text = "TEAM CHECK: OFF"
teamToggle.Font = Enum.Font.SourceSansBold
teamToggle.TextSize = 14
teamToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
teamToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
teamToggle.BorderSizePixel = 0
teamToggle.Parent = mainFrame

-- REFRESH ESP BUTTON
local refreshButton = Instance.new("TextButton")
refreshButton.Size = UDim2.new(0.9, 0, 0, 25)
refreshButton.Position = UDim2.new(0.05, 0, 0.7, 0)
refreshButton.Text = "REFRESH ESP"
refreshButton.Font = Enum.Font.SourceSansBold
refreshButton.TextSize = 12
refreshButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
refreshButton.TextColor3 = Color3.fromRGB(255, 255, 255)
refreshButton.BorderSizePixel = 0
refreshButton.Parent = mainFrame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 20)
title.Position = UDim2.new(0, 0, 0.9, 0)
title.Text = "Aimbot v3.0 - Fixed"
title.Font = Enum.Font.SourceSansBold
title.TextSize = 12
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(200, 200, 200)
title.Parent = mainFrame

-- Button functionality
aimbotToggle.MouseButton1Click:Connect(function()
    Settings.Enabled = not Settings.Enabled
    aimbotToggle.Text = "AIMBOT: " .. (Settings.Enabled and "ON" or "OFF")
end)

espToggle.MouseButton1Click:Connect(function()
    Settings.ESP = not Settings.ESP
    espToggle.Text = "ESP: " .. (Settings.ESP and "ON" or "OFF")
    refreshAllESP()
end)

teamToggle.MouseButton1Click:Connect(function()
    Settings.UseTeamCheck = not Settings.UseTeamCheck
    teamToggle.Text = "TEAM CHECK: " .. (Settings.UseTeamCheck and "ON" or "OFF")
    refreshAllESP()
end)

refreshButton.MouseButton1Click:Connect(function()
    refreshAllESP()
end)

-- Make GUI draggable
local dragging = false
local dragInput
local dragStart
local startPos

mainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

mainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

UIS.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- Hover effects
local function setupButtonHover(button)
    button.MouseEnter:Connect(function()
        button.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    end)
    
    button.MouseLeave:Connect(function()
        if button == refreshButton then
            button.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
        else
            button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        end
    end)
end

setupButtonHover(aimbotToggle)
setupButtonHover(espToggle)
setupButtonHover(teamToggle)
setupButtonHover(refreshButton)

-- COMPLETELY REWRITTEN ESP SYSTEM
local ESPHolders = {}

local function createESP(player)
    if player == LocalPlayer then return end
    
    -- Clean up existing ESP
    if ESPHolders[player] then
        if ESPHolders[player].highlight then
            ESPHolders[player].highlight:Destroy()
        end
        if ESPHolders[player].billboard then
            ESPHolders[player].billboard:Destroy()
        end
        if ESPHolders[player].connection then
            ESPHolders[player].connection:Disconnect()
        end
    end
    
    ESPHolders[player] = {}
    
    local function setupCharacter(character)
        if not character or not character.Parent then return end
        
        -- Wait for character to fully load
        local success, humanoid, head = pcall(function()
            return character:WaitForChild("Humanoid", 3), character:WaitForChild("Head", 3)
        end)
        
        if not success or not humanoid or not head then return end
        
        -- Clean up any existing ESP on this character
        if character:FindFirstChild("ESP_Highlight") then
            character.ESP_Highlight:Destroy()
        end
        if character:FindFirstChild("ESP_Billboard") then
            character.ESP_Billboard:Destroy()
        end
        
        -- Create Highlight
        local highlight = Instance.new("Highlight")
        highlight.Name = "ESP_Highlight"
        highlight.FillColor = player.Team and player.Team.TeamColor.Color or Color3.fromRGB(255, 0, 0)
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        highlight.FillTransparency = 0.5
        highlight.OutlineTransparency = 0
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Adornee = character
        highlight.Enabled = false -- Start disabled, update function will handle
        highlight.Parent = character
        
        -- Create Billboard
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "ESP_Billboard"
        billboard.Size = UDim2.new(0, 200, 0, 50)
        billboard.StudsOffset = Vector3.new(0, 3, 0)
        billboard.AlwaysOnTop = true
        billboard.Adornee = head
        billboard.Enabled = false -- Start disabled
        billboard.Parent = character
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.TextColor3 = highlight.FillColor
        label.TextStrokeColor3 = Color3.new(0, 0, 0)
        label.TextStrokeTransparency = 0
        label.Font = Enum.Font.SourceSansBold
        label.TextSize = 14
        label.Text = player.Name
        label.Parent = billboard
        
        -- Store ESP objects
        ESPHolders[player].highlight = highlight
        ESPHolders[player].billboard = billboard
        ESPHolders[player].label = label
        ESPHolders[player].humanoid = humanoid
        ESPHolders[player].character = character
        
        -- REAL-TIME UPDATE FUNCTION
        local function updateESP()
            if not character or not character.Parent or not humanoid or humanoid.Health <= 0 then
                highlight.Enabled = false
                billboard.Enabled = false
                return
            end
            
            local shouldShow = Settings.ESP and enemy(player)
            
            highlight.Enabled = shouldShow
            billboard.Enabled = shouldShow
            
            -- Update distance
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                local root = LocalPlayer.Character.HumanoidRootPart
                local targetRoot = character:FindFirstChild("HumanoidRootPart")
                
                if root and targetRoot then
                    local distance = (root.Position - targetRoot.Position).Magnitude
                    label.Text = player.Name .. "\n[" .. math.floor(distance) .. " studs]"
                end
            end
        end
        
        -- Update every frame
        local conn = RunService.Heartbeat:Connect(updateESP)
        ESPHolders[player].connection = conn
        
        -- Handle death
        humanoid.Died:Connect(function()
            highlight.Enabled = false
            billboard.Enabled = false
        end)
        
        -- Handle respawn
        humanoid:GetPropertyChangedSignal("Health"):Connect(function()
            if humanoid.Health > 0 then
                updateESP() -- Re-enable ESP when player respawns
            end
        end)
        
        -- Initial update
        updateESP()
    end
    
    -- Handle character changes
    local function onCharacterAdded(newCharacter)
        if ESPHolders[player] and ESPHolders[player].connection then
            ESPHolders[player].connection:Disconnect()
        end
        setupCharacter(newCharacter)
    end
    
    player.CharacterAdded:Connect(onCharacterAdded)
    
    -- Setup current character if exists
    if player.Character then
        setupCharacter(player.Character)
    end
end

-- FIXED REFRESH FUNCTION
local function refreshAllESP()
    for _, player in ipairs(Players:GetPlayers()) do
        createESP(player)
    end
end

-- Initialize ESP for all players
for _, player in ipairs(Players:GetPlayers()) do
    createESP(player)
end

Players.PlayerAdded:Connect(function(player)
    createESP(player)
end)

Players.PlayerRemoving:Connect(function(player)
    if ESPHolders[player] then
        if ESPHolders[player].highlight then
            ESPHolders[player].highlight:Destroy()
        end
        if ESPHolders[player].billboard then
            ESPHolders[player].billboard:Destroy()
        end
        if ESPHolders[player].connection then
            ESPHolders[player].connection:Disconnect()
        end
        ESPHolders[player] = nil
    end
end)

-- Make refresh function available
getgenv().refreshESP = refreshAllESP

-- Update GUI text based on current settings
espToggle.Text = "ESP: " .. (Settings.ESP and "ON" or "OFF")
teamToggle.Text = "TEAM CHECK: " .. (Settings.UseTeamCheck and "ON" or "OFF")

print("i think it works")