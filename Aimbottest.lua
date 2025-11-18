-- AIMBOT SETTINGS
getgenv().Aimbot = {
    Enabled = false,
    UseTeamCheck = false,
    UseVisibilityCheck = true,
    TargetPart = "Head",
    IgnoredTeams = {},
    MaxAngle = 120,
    SpeedAndSmoothness = 8
}

getgenv().ESP = {
    Enabled = false
}

loadstring(game:HttpGet("https://raw.githubusercontent.com/forevermel810/Testing/main/Aimbottest.lua"))()

local Settings = getgenv().Aimbot
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UIS = game:GetService("UserInputService")

-- Aimbot functions
local function enemy(player)
    if not Settings.UseTeamCheck then return true end
    if not player.Team then return true end
    if player.Team == LocalPlayer.Team then return false end
    for _, name in ipairs(Settings.IgnoredTeams) do
        if player.Team.Name == name then return false end
    end
    return true
end

local function visible(part)
    local c = LocalPlayer.Character
    if not c or not c:FindFirstChild("Head") then return false end
    local origin = c.Head.Position
    local dir = part.Position - origin
    local ray = Ray.new(origin, dir)
    local hit = Workspace:FindPartOnRayWithIgnoreList(ray, {c})
    return hit and hit:IsDescendantOf(part.Parent)
end

local function getTarget()
    local c = LocalPlayer.Character
    if not c then return end
    local hrp = c:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local camLook = Camera.CFrame.LookVector
    local best
    local bestDot = -1
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

-- Aimbot camera
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

-- Aimbot GUI toggle
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
if PlayerGui:FindFirstChild("AimbotUI") then PlayerGui.AimbotUI:Destroy() end

local gui = Instance.new("ScreenGui", PlayerGui)
gui.Name = "AimbotUI"
gui.ResetOnSpawn = false

local toggle = Instance.new("TextButton", gui)
toggle.Size = UDim2.new(0,180,0,60)
toggle.Position = UDim2.new(0,20,0,20)
toggle.Text = "AIMBOT: OFF"
toggle.Font = Enum.Font.SourceSansLight
toggle.TextSize = 22
toggle.BackgroundColor3 = Color3.fromRGB(35,35,35)
toggle.TextColor3 = Color3.fromRGB(200,200,200)

local corner = Instance.new("UICorner", toggle)
corner.CornerRadius = UDim.new(0,24)

toggle.MouseEnter:Connect(function()
    toggle.BackgroundColor3 = Color3.fromRGB(55,55,55)
end)

toggle.MouseLeave:Connect(function()
    toggle.BackgroundColor3 = Color3.fromRGB(35,35,35)
end)

toggle.MouseButton1Click:Connect(function()
    Settings.Enabled = not Settings.Enabled
    toggle.Text = "AIMBOT: " .. (Settings.Enabled and "ON" or "OFF")
end)

-- Drag GUI
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

print("aimbot loaded")

-- =================
-- ESP MODULE BELOW
-- =================

local espBoxes = {}

local function clearBox(plr)
    if espBoxes[plr] then
        espBoxes[plr]:Remove()
        espBoxes[plr] = nil
    end
end

local function makeBox(plr)
    clearBox(plr)
    local box = Drawing.new("Square")
    box.Thickness = 1
    box.Color = Color3.fromRGB(0,255,0)
    box.Filled = false
    box.Visible = true
    espBoxes[plr] = box
end

local function track(plr)
    plr.CharacterAdded:Connect(function(char)
        task.wait(0.2)
        if getgenv().ESP.Enabled then
            makeBox(plr)
        end
        char:WaitForChild("Humanoid").Died:Connect(function()
            clearBox(plr)
        end)
    end)
    plr.CharacterRemoving:Connect(function()
        clearBox(plr)
    end)
end

for _,p in pairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then
        track(p)
    end
end

Players.PlayerAdded:Connect(function(p)
    if p ~= LocalPlayer then
        track(p)
    end
end)

RunService.RenderStepped:Connect(function()
    if not getgenv().ESP.Enabled then
        for plr,_ in pairs(espBoxes) do clearBox(plr) end
        return
    end
    for plr,box in pairs(espBoxes) do
        local char = plr.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local hrp = char.HumanoidRootPart
            local pos,vis = Camera:WorldToViewportPoint(hrp.Position)
            if vis then
                local scale = 3
                box.Size = Vector2.new(40 * scale, 60 * scale)
                box.Position = Vector2.new(pos.X - box.Size.X / 2, pos.Y - box.Size.Y / 2)
                box.Visible = true
            else
                box.Visible = false
            end
        else
            box.Visible = false
        end
    end
end)

print("it works i think")