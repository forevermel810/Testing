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
                -- FIXED: Simple enemy check without complex logic
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

-- FIXED ESP SYSTEM
local ESPHolders = {}

local function createESP(player)
    if player == LocalPlayer then return end
    
    -- Remove existing ESP if any
    if ESPHolders[player] then
        for _, object in pairs(ESPHolders[player]) do
            if object then
                object:Destroy()
            end
        end
    end
    
    ESPHolders[player] = {}
    
    local function setupCharacter(character)
        if not character then return end
        
        -- Wait for character to load
        local humanoid = character:WaitForChild("Humanoid", 2)
        local head = character:WaitForChild("Head", 2)
        if not humanoid or not head then return end
        
        -- Remove old ESP
        if ESPHolders[player] then
            for _, object in pairs(ESPHolders[player]) do
                if object then
                    object:Destroy()
                end
            end
        end
        
        ESPHolders[player] = {}
        
        -- Create Highlight (ALWAYS create, control visibility with Enabled)
        local highlight = Instance.new("Highlight")
        highlight.Name = "ESP_Highlight"
        highlight.FillColor = player.Team and player.Team.TeamColor.Color or Color3.fromRGB(255, 0, 0)
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        highlight.FillTransparency = 0.5
        highlight.OutlineTransparency = 0
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Adornee = character
        highlight.Enabled = Settings.ESP and enemy(player)
        highlight.Parent = character
        
        -- Create Billboard
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "ESP_Billboard"
        billboard.Size = UDim2.new(0, 200, 0, 50)
        billboard.StudsOffset = Vector3.new(0, 3, 0)
        billboard.AlwaysOnTop = true
        billboard.Adornee = head
        billboard.Enabled = Settings.ESP and enemy(player)
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
        
        -- REAL-TIME UPDATE FUNCTION
        local function updateESP()
            if not character or not character.Parent then
                return
            end
            
            local shouldShow = Settings.ESP and enemy(player) and humanoid.Health > 0
            
            if highlight then
                highlight.Enabled = shouldShow
            end
            if billboard then
                billboard.Enabled = shouldShow
            end
            
            -- Update distance text
            if label and LocalPlayer.Character then
                local localRoot = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                local targetRoot = character:FindFirstChild("HumanoidRootPart")
                
                if localRoot and targetRoot and humanoid.Health > 0 then
                    local distance = (localRoot.Position - targetRoot.Position).Magnitude
                    label.Text = player.Name .. "\n[" .. math.floor(distance) .. " studs]"
                else
                    label.Text = player.Name .. "\n[DEAD]"
                end
            end
        end
        
        -- Connect events
        humanoid.Died:Connect(function()
            if highlight then highlight.Enabled = false end
            if billboard then billboard.Enabled = false end
        end)
        
        -- Update every frame
        local conn
        conn = RunService.Heartbeat:Connect(function()
            if not character or not character.Parent then
                conn:Disconnect()
                return
            end
            updateESP()
        end)
        
        ESPHolders[player].connection = conn
    end
    
    -- Handle character added
    player.CharacterAdded:Connect(setupCharacter)
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

Players.PlayerAdded:Connect(createESP)
Players.PlayerRemoving:Connect(function(player)
    if ESPHolders[player] then
        for _, object in pairs(ESPHolders[player]) do
            if object and typeof(object) ~= "RBXScriptConnection" then
                object:Destroy()
            end
        end
        ESPHolders[player] = nil
    end
end)

-- Make refresh function available
getgenv().refreshESP = refreshAllESP

print("it should work now")
