--[[
getgenv().Aimbot = {
    Enabled = false,
    UseTeamCheck = false,
    UseVisibilityCheck = true,
    TargetPart = "Head",
    IgnoredTeams = {},
    MaxAngle = 120,
    LerpSpeed = 8,
    ESP = false
}
loadstring(game:HttpGet("https://raw.githubusercontent.com/forevermel810/Testing/main/Aimbottest.lua"))()
]]

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Settings
local Settings = getgenv().Aimbot

-- Core Functions
local function enemy(player)
    return not (player.Team == LocalPlayer.Team or table.find(Settings.IgnoredTeams, player.Team))
end

local function visible(part)
    if not Settings.UseVisibilityCheck then return true end
    local origin = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head")
    if not origin then return false end
    
    local ray = Ray.new(origin.Position, (part.Position - origin.Position))
    local hit = workspace:FindPartOnRayWithIgnoreList(ray, {LocalPlayer.Character})
    return hit and hit:IsDescendantOf(part.Parent)
end

local function getTarget()
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local camLook, best, bestDot = Camera.CFrame.LookVector, nil, -1
    local maxDot = math.cos(math.rad(Settings.MaxAngle))

    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local hum = plr.Character:FindFirstChild("Humanoid")
            local part = plr.Character:FindFirstChild(Settings.TargetPart)

            if hum and hum.Health > 0 and part then
                if (not Settings.UseTeamCheck or enemy(plr)) and visible(part) then
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

-- ESP with Distance
local function createESP(player)
    if player == LocalPlayer then return end

    local function setupCharacter(character)
        if not character then return end
        
        -- Clean up old ESP
        if character:FindFirstChild("ESP_Highlight") then character.ESP_Highlight:Destroy() end
        if character:FindFirstChild("ESP_Billboard") then character.ESP_Billboard:Destroy() end

        local humanoid, head = character:FindFirstChild("Humanoid"), character:FindFirstChild("Head")
        if not humanoid or not head then return end

        -- Create highlight
        local highlight = Instance.new("Highlight")
        highlight.Name = "ESP_Highlight"
        highlight.FillColor = player.Team and player.Team.TeamColor.Color or Color3.fromRGB(255,0,0)
        highlight.OutlineColor = Color3.fromRGB(255,255,255)
        highlight.FillTransparency = 0.5
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Adornee = character
        highlight.Enabled = Settings.ESP
        highlight.Parent = character

        -- Create billboard with distance
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
            if not Settings.ESP or not LocalPlayer.Character then return end
            local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            local targetRoot = character:FindFirstChild("HumanoidRootPart")
            
            if root and targetRoot then
                local distance = (root.Position - targetRoot.Position).Magnitude
                label.Text = player.Name .. "\n[" .. math.floor(distance) .. " studs]"
            end
        end

        RunService.RenderStepped:Connect(updateDistance)
        updateDistance()
    end

    player.CharacterAdded:Connect(setupCharacter)
    if player.Character then setupCharacter(player.Character) end
end

-- Initialize ESP
for _, player in ipairs(Players:GetPlayers()) do
    createESP(player)
end
Players.PlayerAdded:Connect(createESP)

-- Aimbot loop
local smooth = Camera.CFrame
RunService.RenderStepped:Connect(function(dt)
    local target = getTarget()
    local current = Camera.CFrame

    if Settings.Enabled and target then
        local goal = CFrame.new(current.Position, target.Position)
        smooth = current:Lerp(goal, math.clamp(Settings.LerpSpeed * dt, 0, 1))
    else
        smooth = current
    end

    Camera.CFrame = smooth
end)

-- GUI (kept your original GUI code)
-- ... your existing GUI code here ...