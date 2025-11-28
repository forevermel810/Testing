--[[
getgenv().Aimbot = {
    Enabled = false,
    UseTeamCheck = false,
    TargetPart = "Head",
    IgnoredTeams = {},
    MaxAngle = 120,
    SpeedAndSmoothness = 8,
    ESP = false,
    MaxRange = 100
}
loadstring(game:HttpGet("https://raw.githubusercontent.com/forevermel810/Testing/main/universalaimbot.lua"))()
]]
local Settings = getgenv().Aimbot
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UIS = game:GetService("UserInputService")

---------------------------------------------------
-- TEAM CHECK
---------------------------------------------------
local function enemy(plr)
    if not Settings.UseTeamCheck then return true end
    if not plr.Team then return true end
    if plr.Team == LocalPlayer.Team then return false end
    for _, t in ipairs(Settings.IgnoredTeams) do
        if plr.Team.Name == t then return false end
    end
    return true
end

---------------------------------------------------
-- VISIBILITY CHECK
---------------------------------------------------
local function visible(part)
    if not (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head")) then return false end
    local origin = LocalPlayer.Character.Head.Position
    local dir = part.Position - origin
    local ray = Ray.new(origin, dir)
    local hit = Workspace:FindPartOnRayWithIgnoreList(ray, {LocalPlayer.Character})
    return hit and hit:IsDescendantOf(part.Parent)
end

---------------------------------------------------
-- GET TARGET
---------------------------------------------------
local function getTarget()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local camLook = Camera.CFrame.LookVector
    local best = nil
    local bestDot = -1
    local maxDot = math.cos(math.rad(Settings.MaxAngle))

    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and enemy(plr) then
            local hum = plr.Character:FindFirstChild("Humanoid")
            local part = plr.Character:FindFirstChild(Settings.TargetPart)
            if hum and hum.Health > 0 and part and visible(part) then
                local dist = (part.Position - hrp.Position).Magnitude
                if dist <= Settings.MaxRange then
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

---------------------------------------------------
-- AIMBOT LOOP
---------------------------------------------------
if getgenv().AimbotConnection then
    getgenv().AimbotConnection:Disconnect()
end

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

---------------------------------------------------
-- GUI BUTTON
---------------------------------------------------
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
if PlayerGui:FindFirstChild("AimbotUI") then PlayerGui.AimbotUI:Destroy() end

local gui = Instance.new("ScreenGui", PlayerGui)
gui.Name = "AimbotUI"
gui.ResetOnSpawn = false

local toggle = Instance.new("TextButton", gui)
toggle.Size = UDim2.new(0,180,0,60)
toggle.Position = UDim2.new(1,-200,0,100)
toggle.Text = "AIMBOT OFF"
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
    toggle.Text = Settings.Enabled and "AIMBOT ON" or "AIMBOT OFF"
end)

---------------------------------------------------
-- DRAGGING
---------------------------------------------------
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

---------------------------------------------------
-- TRACER SYSTEM
---------------------------------------------------

if getgenv().TracerConnection then
    getgenv().TracerConnection:Disconnect()
end

local tracers = {}

local function createTracer()
    local line = Drawing.new("Line")
    line.Thickness = 1
    line.Transparency = 1
    line.Color = Color3.fromRGB(0,255,0)
    line.Visible = false
    return line
end

local function getRoot(c)
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function enemyTracer(plr)
    if not Settings.UseTeamCheck then return true end
    if not plr.Team then return true end
    if plr.Team == LocalPlayer.Team then return false end
    for _, t in ipairs(Settings.IgnoredTeams) do
        if plr.Team.Name == t then return false end
    end
    return true
end

Players.PlayerRemoving:Connect(function(p)
    if tracers[p] then
        tracers[p]:Remove()
        tracers[p] = nil
    end
end)

local function trackCharacter(p)
    local c = p.Character
    if not c then return end
    local h = c:FindFirstChildOfClass("Humanoid")
    if h then
        h.Died:Connect(function()
            if tracers[p] then
                tracers[p]:Remove()
                tracers[p] = nil
            end
        end)
    end
    c.AncestryChanged:Connect(function(_, parent)
        if not parent and tracers[p] then
            tracers[p]:Remove()
            tracers[p] = nil
        end
    end)
end

Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function()
        trackCharacter(p)
    end)
end)

for _, p in pairs(Players:GetPlayers()) do
    if p.Character then
        trackCharacter(p)
    end
end

getgenv().TracerConnection = RunService.RenderStepped:Connect(function()
    local localRoot = getRoot(LocalPlayer.Character)
    if not localRoot then return end

    local viewport = Camera.ViewportSize
    local screenCenter = Vector2.new(viewport.X * 0.5, viewport.Y * 0.5)

    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and enemyTracer(p) then
            local c = p.Character
            local root = getRoot(c)

            if root then
                local dist = (root.Position - localRoot.Position).Magnitude

                if dist > Settings.MaxRange then
                    if tracers[p] then tracers[p].Visible = false end
                    continue
                end

                if not tracers[p] then
                    tracers[p] = createTracer()
                end

                local tracer = tracers[p]
                local pos, onScreen = Camera:WorldToViewportPoint(root.Position)

                local camDir = Camera.CFrame.LookVector
                local toTarget = (root.Position - Camera.CFrame.Position).Unit
                local dot = toTarget:Dot(camDir)

                if dot > 0.95 then
                    tracer.Visible = false
                else
                    if onScreen then
                        tracer.Visible = true
                        tracer.From = screenCenter
                        tracer.To = Vector2.new(pos.X, pos.Y)

                        local r = math.clamp(255 - dist, 0, 255)
                        local g = math.clamp(dist, 0, 255)
                        tracer.Color = Color3.fromRGB(r, g, 0)
                    else
                        tracer.Visible = false
                    end
                end
            else
                if tracers[p] then tracers[p].Visible = false end
            end
        else
            if tracers[p] then tracers[p].Visible = false end
        end
    end
end)

print("idk")