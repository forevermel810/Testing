--[[ 
getgenv().Aimbot = {
    Enabled = false, -- do not true this
    UseTeamCheck = false,-- team check
    TargetPart = "Head", -- target body parts usually its head or humanoidrootpart
    IgnoredTeams = {}, -- ignored teams
    MaxAngle = 120, -- how big is the range in your screen
    SpeedAndSmoothness = 8,-- the travel speed to the target distance
    ESP = false, -- esp i think
    MaxRange = 100, 
    ShowRangeCircle = true
}
loadstring(game:HttpGet("https://raw.githubusercontent.com/forevermel810/Testing/main/rica.lua"))()
]]

local Settings = getgenv().Aimbot

-- SERVICES
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UIS = game:GetService("UserInputService")

-- CHECK ENEMY / TEAM
local function enemy(player)
    if not Settings.UseTeamCheck then return true end
    if not player.Team then return true end
    if player.Team == LocalPlayer.Team then return false end
    for _, name in ipairs(Settings.IgnoredTeams) do
        if player.Team.Name == name then return false end
    end
    return true
end

-- VISIBILITY CHECK
local function visible(part)
    if not (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head")) then return false end
    local origin = LocalPlayer.Character.Head.Position
    local dir = part.Position - origin
    local ray = Ray.new(origin, dir)
    local hit = Workspace:FindPartOnRayWithIgnoreList(ray, {LocalPlayer.Character})
    return hit and hit:IsDescendantOf(part.Parent)
end

-- TARGET SELECTION WITH RANGE
local function getTarget()
    if not LocalPlayer.Character then return end
    local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local best, bestDot = nil, -1
    local maxDot = math.cos(math.rad(Settings.MaxAngle))

    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local hum = plr.Character:FindFirstChild("Humanoid")
            local part = plr.Character:FindFirstChild(Settings.TargetPart)
            if hum and hum.Health > 0 and part and enemy(plr) and visible(part) then
                local dist = (part.Position - hrp.Position).Magnitude
                if dist <= Settings.MaxRange then
                    local dir = (part.Position - hrp.Position).Unit
                    local dot = dir:Dot(Camera.CFrame.LookVector)
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

-- CAMERA LOCK
if getgenv().AimbotConnection then getgenv().AimbotConnection:Disconnect() end
local smooth = Camera.CFrame
getgenv().AimbotConnection = RunService.RenderStepped:Connect(function(dt)
    local target = getTarget()
    local current = Camera.CFrame
    if Settings.Enabled and target then
        local goal = CFrame.new(current.Position, target.Position)
        smooth = current:Lerp(goal, math.clamp(Settings.SpeedAndSmoothness*dt,0,1))
    else
        smooth = current
    end
    Camera.CFrame = smooth
end)

-- GUI TOGGLE
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
    toggle.Text = "AIMBOT: "..(Settings.Enabled and "ON" or "OFF")
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

-- ESP FUNCTION
local function addESP(character, player)
    if character:FindFirstChild("ESP_Highlight") then character.ESP_Highlight:Destroy() end
    if character:FindFirstChild("ESP_Billboard") then character.ESP_Billboard:Destroy() end

    local head = character:FindFirstChild("Head")
    local humanoid = character:FindFirstChild("Humanoid")
    if not head or not humanoid then return end

    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP_Highlight"
    highlight.FillColor = player.Team and player.Team.TeamColor.Color or Color3.fromRGB(255,0,0)
    highlight.OutlineColor = Color3.fromRGB(255,255,255)
    highlight.FillTransparency = 0.5
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Adornee = character
    highlight.Enabled = Settings.ESP
    highlight.Parent = character

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESP_Billboard"
    billboard.Size = UDim2.new(0,200,0,50)
    billboard.StudsOffset = Vector3.new(0,3,0)
    billboard.AlwaysOnTop = true
    billboard.Adornee = head
    billboard.Enabled = Settings.ESP
    billboard.Parent = character

    -- NAME LABEL
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1,0,0.5,0)
    nameLabel.Position = UDim2.new(0,0,0,0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = highlight.FillColor
    nameLabel.TextStrokeTransparency = 0.5
    nameLabel.Font = Enum.Font.SourceSansLight
    nameLabel.TextSize = 14
    nameLabel.Text = player.Name
    nameLabel.Parent = billboard

    -- DISTANCE LABEL
    local distLabel = Instance.new("TextLabel")
    distLabel.Size = UDim2.new(1,0,0.5,0)
    distLabel.Position = UDim2.new(0,0,0.5,0)
    distLabel.BackgroundTransparency = 1
    distLabel.TextColor3 = highlight.FillColor
    distLabel.TextStrokeTransparency = 0.3
    distLabel.Font = Enum.Font.GothamBold
    distLabel.TextSize = 16
    distLabel.Text = ""
    distLabel.Parent = billboard

    -- UPDATE LOOP
    RunService.RenderStepped:Connect(function()
        if not Settings.ESP or not enemy(player) then
            highlight.Enabled = false
            billboard.Enabled = false
            return
        end

        highlight.FillColor = player.Team and player.Team.TeamColor.Color or Color3.fromRGB(255,0,0)
        nameLabel.TextColor3 = highlight.FillColor
        distLabel.TextColor3 = highlight.FillColor

        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and character:FindFirstChild("HumanoidRootPart") then
            local root = LocalPlayer.Character.HumanoidRootPart
            local targetRoot = character.HumanoidRootPart
            local dist = (root.Position - targetRoot.Position).Magnitude
            distLabel.Text = "["..math.floor(dist).." studs]"
        end

        highlight.Enabled = Settings.ESP
        billboard.Enabled = Settings.ESP
    end)
end

local function setupESP(player)
    if player == LocalPlayer then return end
    player.CharacterAdded:Connect(function(char) wait(0.1) addESP(char, player) end)
    if player.Character then addESP(player.Character, player) end
end

for _, plr in ipairs(Players:GetPlayers()) do setupESP(plr) end
Players.PlayerAdded:Connect(setupESP)

-- RANGE CIRCLE
local circle
local function createRangeCircle()
    if circle then circle:Destroy() end
    if not Settings.ShowRangeCircle then return end

    circle = Instance.new("Part")
    circle.Name = "AimbotRangeCircle"
    circle.Anchored = true
    circle.CanCollide = false
    circle.Size = Vector3.new(Settings.MaxRange*2, 0.1, Settings.MaxRange*2)
    circle.Transparency = 0.5
    circle.Color = Color3.fromRGB(255,0,0)
    circle.Material = Enum.Material.Neon
    circle.Parent = workspace

    RunService.RenderStepped:Connect(function()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            circle.Position = LocalPlayer.Character.HumanoidRootPart.Position + Vector3.new(0,0.1,0)
        end
        circle.Visible = Settings.ShowRangeCircle
    end)
end

createRangeCircle()

print("i think it works")