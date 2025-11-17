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
    -- If team check is disabled, everyone is an enemy
    if not Settings.UseTeamCheck then
        return true
    end
    
    -- Check if same team
    if player.Team == LocalPlayer.Team then
        return false
    end
    
    -- Check ignored teams by comparing Team objects, not TeamColor
    for _, ignoredTeam in ipairs(Settings.IgnoredTeams) do
        if player.Team == ignoredTeam then
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

            -- CRITICAL: Check if humanoid exists AND health > 0
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

local toggle = Instance.new("TextButton", gui)
toggle.Size = UDim2.new(0,180,0,60)
toggle.Position = UDim2.new(1,-200,0,100)
toggle.Text = "AIMBOT: OFF"
toggle.Font = Enum.Font.SourceSansLight
toggle.TextSize = 22
toggle.BackgroundColor3 = Color3.fromRGB(35,35,35)
toggle.TextColor3 = Color3.fromRGB(200,200,200)

local corner = Instance.new("UICorner", toggle)
corner.CornerRadius = UDim.new(0,24)

toggle.MouseEnter:Connect(function() toggle.BackgroundColor3 = Color3.fromRGB(55,55,55) end)
toggle.MouseLeave:Connect(function() toggle.BackgroundColor3 = Color3.fromRGB(35,35,35) end)

toggle.MouseButton1Click:Connect(function()
    Settings.Enabled = not Settings.Enabled
    toggle.Text = "AIMBOT: " .. (Settings.Enabled and "ON" or "OFF")
end)

-- DRAGGING
local dragging = false
local offset = Vector2.new()
local drag = Instance.new("Frame", toggle)
drag.Size = UDim2.new(1,0,0,30)
drag.BackgroundTransparency = 1

drag.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        offset = UIS:GetMouseLocation() - toggle.AbsolutePosition
    end
end)

drag.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

UIS.InputChanged:Connect(function(input)
    if dragging then
        local pos = UIS:GetMouseLocation() - offset
        toggle.Position = UDim2.new(0,pos.X,0,pos.Y)
    end
end)

-- FIXED ESP FUNCTIONALITY WITH PROPER TEAM HANDLING
local function createESP(player)
    if player == LocalPlayer then return end

    local function setupCharacter(character)
        if not character then return end
        
        -- Wait for character to fully load
        local humanoid = character:WaitForChild("Humanoid", 5)
        local head = character:WaitForChild("Head", 5)
        if not humanoid or not head then return end

        -- Remove old ESP if it exists
        if character:FindFirstChild("ESP_Highlight") then 
            character.ESP_Highlight:Destroy() 
        end
        if character:FindFirstChild("ESP_Billboard") then 
            character.ESP_Billboard:Destroy() 
        end

        -- Only create ESP if player meets conditions
        if not enemy(player) then
            return -- Don't create ESP for teammates or ignored teams
        end

        -- Highlight whole body
        local highlight = Instance.new("Highlight")
        highlight.Name = "ESP_Highlight"
        highlight.FillColor = player.Team and player.Team.TeamColor.Color or Color3.fromRGB(255,0,0)
        highlight.OutlineColor = Color3.fromRGB(255,255,255)
        highlight.FillTransparency = 0.5
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Adornee = character
        highlight.Enabled = Settings.ESP
        highlight.Parent = character

        -- Billboard with name and distance
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "ESP_Billboard"
        billboard.Size = UDim2.new(0,200,0,50)
        billboard.StudsOffset = Vector3.new(0,3,0)
        billboard.AlwaysOnTop = true
        billboard.Adornee = head
        billboard.Enabled = Settings.ESP
        billboard.Parent = character

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1,0,1,0)
        label.BackgroundTransparency = 1
        label.TextColor3 = highlight.FillColor
        label.TextStrokeTransparency = 0.5
        label.Font = Enum.Font.SourceSansLight
        label.TextSize = 14
        label.Parent = billboard

        -- Distance update function
        local function updateDistance()
            if not Settings.ESP or not LocalPlayer.Character or not character.Parent then
                highlight.Enabled = false
                billboard.Enabled = false
                return
            end

            -- Re-check team conditions every frame
            if not enemy(player) then
                highlight.Enabled = false
                billboard.Enabled = false
                return
            else
                highlight.Enabled = Settings.ESP
                billboard.Enabled = Settings.ESP
            end

            local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            local targetRoot = character:FindFirstChild("HumanoidRootPart")

            if root and targetRoot and humanoid.Health > 0 then
                local distance = (root.Position - targetRoot.Position).Magnitude
                label.Text = player.Name .. "\n[" .. math.floor(distance) .. " studs]"
                highlight.Enabled = Settings.ESP
                billboard.Enabled = Settings.ESP
            else
                -- Hide ESP if player is dead
                highlight.Enabled = false
                billboard.Enabled = false
            end
        end

        -- Connect to humanoid to detect death
        humanoid.Died:Connect(function()
            highlight.Enabled = false
            billboard.Enabled = false
        end)

        -- Update distance every frame
        local distanceConnection
        distanceConnection = RunService.RenderStepped:Connect(updateDistance)
        
        -- Clean up when character is removed
        character.AncestryChanged:Connect(function(_, parent)
            if not parent then
                distanceConnection:Disconnect()
            end
        end)
    end

    -- Handle character respawns
    player.CharacterAdded:Connect(setupCharacter)
    
    -- Handle initial character
    if player.Character then
        setupCharacter(player.Character)
    end
end

-- Function to refresh all ESP when team check changes
local function refreshAllESP()
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character then
            createESP(player)
        end
    end
end

-- Initialize ESP for existing and new players
for _, player in ipairs(Players:GetPlayers()) do
    createESP(player)
end
Players.PlayerAdded:Connect(createESP)

-- Make refresh function available to call when team check changes
getgenv().refreshESP = refreshAllESP

-- ESP TOGGLE FUNCTIONALITY
local function updateAllESP()
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character then
            local highlight = player.Character:FindFirstChild("ESP_Highlight")
            local billboard = player.Character:FindFirstChild("ESP_Billboard")
            
            if highlight then
                highlight.Enabled = Settings.ESP and enemy(player)
            end
            if billboard then
                billboard.Enabled = Settings.ESP and enemy(player)
            end
        end
    end
end

-- Connect ESP toggle to settings changes
getgenv().AimbotSettings = Settings

-- Helper function to properly set IgnoredTeams
local function updateIgnoredTeams()
    refreshAllESP()
end

-- Example of how to use IgnoredTeams properly:
--[[
getgenv().Aimbot.IgnoredTeams = {game:GetService("Teams")["TeamName"]}
-- OR for multiple teams:
getgenv().Aimbot.IgnoredTeams = {
    game:GetService("Teams")["Team1"],
    game:GetService("Teams")["Team2"]
}
]]

print("Aimbot loaded! Use: getgenv().Aimbot.IgnoredTeams = {game:GetService('Teams')['TeamName']} to ignore teams")