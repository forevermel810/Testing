--[[ 
getgenv().Aimbot = {
    Enabled = false,
    UseTeamCheck = false,
    TargetPart = "Head",
    IgnoredTeams = {},
    MaxAngle = 120,
    SpeedAndSmoothness = 8,
    ESP = false,
    ToggleKey = Enum.KeyCode.F
}
loadstring(game:HttpGet("https://raw.githubusercontent.com/forevermel810/Testing/main/oldone.lua"))()
]]

local Settings = getgenv().Aimbot

-- SERVICES
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UIS = game:GetService("UserInputService")

-- KEYBIND TOGGLE
UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Settings.ToggleKey then
        Settings.Enabled = not Settings.Enabled
        if toggle then
            toggle.Text = "AIMBOT: "..(Settings.Enabled and "ON" or "OFF")
        end
    end
end)

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

-- TARGET SELECTION
local function getTarget()
    if not LocalPlayer.Character then return end
    local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local camLook = Camera.CFrame.LookVector
    local best
    local bestDot = -1
    local maxDot = math.cos(math.rad(Settings.MaxAngle))

    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local hum = plr.Character:FindFirstChild("Humanoid")
            local part = plr.Character:FindFirstChild(Settings.TargetPart)
            if hum and hum.Health > 0 and part and enemy(plr) and visible(part) then
                local dir = (part.Position - hrp.Position).Unit
                local dot = dir:Dot(camLook)
                if dot > bestDot and dot >= maxDot then
                    bestDot = dot
                    best = part
                end
            end
        end
    end
    return best
end

-- CAMERA LOCK
if getgenv().AimbotConnection then
    getgenv().AimbotConnection:Disconnect()
end

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

-- GUI TOGGLE
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
if PlayerGui:FindFirstChild("AimbotUI") then
    PlayerGui.AimbotUI:Destroy()
end

local gui = Instance.new("ScreenGui", PlayerGui)
gui.Name = "AimbotUI"
gui.ResetOnSpawn = false

toggle = Instance.new("TextButton", gui)
toggle.Size = UDim2.new(0,180,0,60)
toggle.Position = UDim2.new(1,-200,0,100)
toggle.Text = "AIMBOT: OFF"
toggle.Font = Enum.Font.SourceSansLight
toggle.TextSize = 22
toggle.BackgroundColor3 = Color3.fromRGB(35,35,35)
toggle.TextColor3 = Color3.fromRGB(200,200,200)

local corner = Instance.new("UICorner", toggle)
corner.CornerRadius = UDim.new(0,24)

toggle.MouseButton1Click:Connect(function()
    Settings.Enabled = not Settings.Enabled
    toggle.Text = "AIMBOT: "..(Settings.Enabled and "ON" or "OFF")
end)