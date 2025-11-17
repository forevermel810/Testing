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

-- SERVICES
local Players, RunService, UIS = game:GetService("Players"), game:GetService("RunService"), game:GetService("UserInputService")
local LocalPlayer, Camera, Workspace = Players.LocalPlayer, workspace.CurrentCamera, game:GetService("Workspace")

-- SETTINGS
local Settings = getgenv().Aimbot

-- CORE FUNCTIONS
local function enemy(player)
    return not (player.Team == LocalPlayer.Team or table.find(Settings.IgnoredTeams, player.Team))
end

local function visible(part)
    if not (LocalPlayer.Character and LocalPlayer.Character.Head) then return false end
    local origin = LocalPlayer.Character.Head.Position
    local ray = Ray.new(origin, part.Position - origin)
    local hit = Workspace:FindPartOnRayWithIgnoreList(ray, {LocalPlayer.Character})
    return hit and hit:IsDescendantOf(part.Parent)
end

local function getTarget()
    local hrp = LocalPlayer.Character and LocalPlayer.Character.HumanoidRootPart
    if not hrp then return end

    local camLook, best, bestDot = Camera.CFrame.LookVector, nil, -1
    local maxDot = math.cos(math.rad(Settings.MaxAngle))

    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local hum, part = plr.Character.Humanoid, plr.Character:FindFirstChild(Settings.TargetPart)
            if hum and hum.Health > 0 and part and (not Settings.UseTeamCheck or enemy(plr)) and visible(part) then
                local dir = (part.Position - hrp.Position).Unit
                local dot = dir:Dot(camLook)
                if dot > bestDot and dot >= maxDot then
                    bestDot, best = dot, part
                end
            end
        end
    end
    return best
end

-- ESP SYSTEM
local function createESP(player)
    if player == LocalPlayer then return end

    local function setupCharacter(character)
        if not character then return end
        
        -- Clean up and team check
        local highlight, billboard = character:FindFirstChild("ESP_Highlight"), character:FindFirstChild("ESP_Billboard")
        if highlight then highlight:Destroy() end
        if billboard then billboard:Destroy() end
        
        if Settings.UseTeamCheck and not enemy(player) then return end
        
        local humanoid, head = character.Humanoid, character.Head
        if not humanoid or not head then return end

        -- Create ESP elements
        local teamColor = player.Team and player.Team.TeamColor.Color or Color3.fromRGB(255,0,0)
        
        local highlight = Instance.new("Highlight")
        highlight.Name, highlight.FillColor, highlight.OutlineColor = "ESP_Highlight", teamColor, Color3.fromRGB(255,255,255)
        highlight.FillTransparency, highlight.DepthMode, highlight.Adornee = 0.5, Enum.HighlightDepthMode.AlwaysOnTop, character
        highlight.Enabled, highlight.Parent = Settings.ESP, character

        local billboard = Instance.new("BillboardGui")
        billboard.Name, billboard.Size, billboard.StudsOffset = "ESP_Billboard", UDim2.new(0,200,0,50), Vector3.new(0,3,0)
        billboard.AlwaysOnTop, billboard.Adornee, billboard.Enabled, billboard.Parent = true, head, Settings.ESP, character

        local label = Instance.new("TextLabel")
        label.Size, label.BackgroundTransparency, label.TextColor3 = UDim2.new(1,0,1,0), 1, teamColor
        label.TextStrokeTransparency, label.Font, label.TextSize, label.Parent = 0.5, Enum.Font.SourceSansLight, 14, billboard

        -- Distance tracking
        RunService.RenderStepped:Connect(function()
            if not Settings.ESP or not LocalPlayer.Character then return end
            local shouldShow = not (Settings.UseTeamCheck and not enemy(player))
            highlight.Enabled, billboard.Enabled = shouldShow and Settings.ESP, shouldShow and Settings.ESP
            
            local root, targetRoot = LocalPlayer.Character.HumanoidRootPart, character.HumanoidRootPart
            if root and targetRoot then
                label.Text = player.Name .. "\n[" .. math.floor((root.Position - targetRoot.Position).Magnitude) .. " studs]"
            end
        end)
    end

    player.CharacterAdded:Connect(setupCharacter)
    if player.Character then setupCharacter(player.Character) end
end

-- Initialize ESP
for _, player in ipairs(Players:GetPlayers()) do createESP(player) end
Players.PlayerAdded:Connect(createESP)
getgenv().refreshESP = function() for _, p in ipairs(Players:GetPlayers()) do if p.Character then createESP(p) end end end

-- AIMBOT LOOP
if getgenv().AimbotConnection then getgenv().AimbotConnection:Disconnect() end
local smooth = Camera.CFrame

getgenv().AimbotConnection = RunService.RenderStepped:Connect(function(dt)
    local target, current = getTarget(), Camera.CFrame
    if Settings.Enabled and target then
        smooth = current:Lerp(CFrame.new(current.Position, target.Position), math.clamp(Settings.SpeedAndSmoothness * dt, 0, 1))
    else
        smooth = current
    end
    Camera.CFrame = smooth
end)

-- SIMPLE GUI
local gui = Instance.new("ScreenGui", LocalPlayer.PlayerGui)
gui.Name, gui.ResetOnSpawn = "AimbotUI", false

local toggle = Instance.new("TextButton", gui)
toggle.Size, toggle.Position, toggle.Text = UDim2.new(0,180,0,60), UDim2.new(1,-200,0,100), "AIMBOT: OFF"
toggle.Font, toggle.TextSize, toggle.BackgroundColor3, toggle.TextColor3 = Enum.Font.SourceSansLight, 22, Color3.fromRGB(35,35,35), Color3.fromRGB(200,200,200)

Instance.new("UICorner", toggle).CornerRadius = UDim.new(0,24)

toggle.MouseEnter:Connect(function() toggle.BackgroundColor3 = Color3.fromRGB(55,55,55) end)
toggle.MouseLeave:Connect(function() toggle.BackgroundColor3 = Color3.fromRGB(35,35,35) end)

toggle.MouseButton1Click:Connect(function()
    Settings.Enabled = not Settings.Enabled
    toggle.Text = "AIMBOT: " .. (Settings.Enabled and "ON" or "OFF")
end)

-- Dragging
local dragging, offset = false, Vector2.new()
local drag = Instance.new("Frame", toggle)
drag.Size, drag.BackgroundTransparency = UDim2.new(1,0,0,30), 1

drag.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging, offset = true, UIS:GetMouseLocation() - toggle.AbsolutePosition end end)
drag.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
UIS.InputChanged:Connect(function(i) if dragging then toggle.Position = UDim2.new(0, (UIS:GetMouseLocation() - offset).X, 0, (UIS:GetMouseLocation() - offset).Y) end end)