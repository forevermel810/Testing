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

-- YOUR ORIGINAL GUI
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

-- FIXED ESP SYSTEM (KEEPS YOUR ORIGINAL STRUCTURE BUT FIXES THE ISSUES)
local ESPHolders = {}

local function createESP(player)
    if player == LocalPlayer then return end
    
    local function setupCharacter(character)
        if not character then return end
        
        -- Wait for character to load
        local humanoid = character:WaitForChild("Humanoid", 2)
        local head = character:WaitForChild("Head", 2)
        if not humanoid or not head then return end
        
        -- Remove old ESP
        if character:FindFirstChild("ESP_Highlight") then 
            character.ESP_Highlight:Destroy() 
        end
        if character:FindFirstChild("ESP_Billboard") then 
            character.ESP_Billboard:Destroy() 
        end

        -- Create Highlight
        local highlight = Instance.new("Highlight")
        highlight.Name = "ESP_Highlight"
        highlight.FillColor = player.Team and player.Team.TeamColor.Color or Color3.fromRGB(255,0,0)
        highlight.OutlineColor = Color3.fromRGB(255,255,255)
        highlight.FillTransparency = 0.5
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Adornee = character
        highlight.Parent = character

        -- Billboard with name and distance
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "ESP_Billboard"
        billboard.Size = UDim2.new(0,200,0,50)
        billboard.StudsOffset = Vector3.new(0,3,0)
        billboard.AlwaysOnTop = true
        billboard.Adornee = head
        billboard.Parent = character

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1,0,1,0)
        label.BackgroundTransparency = 1
        label.TextColor3 = highlight.FillColor
        label.TextStrokeTransparency = 0.5
        label.Font = Enum.Font.SourceSansLight
        label.TextSize = 14
        label.Parent = billboard

        -- FIXED: Real-time update function that handles death/respawn
        local function updateDistance()
            if not character or not character.Parent then return end
            
            local shouldShow = Settings.ESP and enemy(player) and humanoid.Health > 0
            
            highlight.Enabled = shouldShow
            billboard.Enabled = shouldShow
            
            if LocalPlayer.Character then
                local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                local targetRoot = character:FindFirstChild("HumanoidRootPart")

                if root and targetRoot and humanoid.Health > 0 then
                    local distance = (root.Position - targetRoot.Position).Magnitude
                    label.Text = player.Name .. "\n[" .. math.floor(distance) .. " studs]"
                else
                    label.Text = player.Name .. "\n[DEAD]"
                end
            end
        end

        -- FIXED: Use Heartbeat instead of RenderStepped for better performance
        local connection = RunService.Heartbeat:Connect(updateDistance)
        
        -- FIXED: Handle death properly
        humanoid.Died:Connect(function()
            highlight.Enabled = false
            billboard.Enabled = false
        end)
        
        -- FIXED: Handle respawn
        humanoid:GetPropertyChangedSignal("Health"):Connect(function()
            if humanoid.Health > 0 then
                updateDistance() -- Re-enable ESP when player respawns
            end
        end)
        
        -- Store for cleanup
        ESPHolders[player] = {
            highlight = highlight,
            billboard = billboard,
            connection = connection,
            humanoid = humanoid
        }
        
        -- Initial update
        updateDistance()
    end

    player.CharacterAdded:Connect(setupCharacter)
    if player.Character then 
        setupCharacter(player.Character) 
    end
end

-- FIXED REFRESH FUNCTION
local function refreshAllESP()
    -- Clean up all existing ESP
    for player, espData in pairs(ESPHolders) do
        if espData.connection then
            espData.connection:Disconnect()
        end
        if espData.highlight then
            espData.highlight:Destroy()
        end
        if espData.billboard then
            espData.billboard:Destroy()
        end
    end
    
    ESPHolders = {}
    
    -- Recreate ESP for all players
    for _, player in ipairs(Players:GetPlayers()) do
        createESP(player)
    end
end

-- Initialize ESP for existing and new players
for _, player in ipairs(Players:GetPlayers()) do
    createESP(player)
end

Players.PlayerAdded:Connect(createESP)

Players.PlayerRemoving:Connect(function(player)
    if ESPHolders[player] then
        if ESPHolders[player].connection then
            ESPHolders[player].connection:Disconnect()
        end
        if ESPHolders[player].highlight then
            ESPHolders[player].highlight:Destroy()
        end
        if ESPHolders[player].billboard then
            ESPHolders[player].billboard:Destroy()
        end
        ESPHolders[player] = nil
    end
end)

-- Make refresh function available to call when team check changes
getgenv().refreshESP = refreshAllESP

print("i think it works")