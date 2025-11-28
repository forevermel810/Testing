--[[
getgenv().Aimbot = {
    Enabled = false,
    UseTeamCheck = false,
    TargetPart = "Head",
    IgnoredTeams = {"Criminals"},
    MaxAngle = 120,
    SpeedAndSmoothness = 8,
    ESP = true,
    MaxRange = 1000
}
loadstring(game:HttpGet("https://raw.githubusercontent.com/forevermel810/Testing/main/universalaimbot.lua"))()
]]--

local Settings = getgenv().Aimbot
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UIS = game:GetService("UserInputService")

local function isEnemy(plr)
    if not Settings.UseTeamCheck then return true end
    if not plr.Team then return true end
    if plr.Team == LocalPlayer.Team then return false end
    for _, t in ipairs(Settings.IgnoredTeams) do
        if plr.Team.Name == t then return false end
    end
    return true
end

local function getRoot(c)
    return c and c:FindFirstChild("HumanoidRootPart")
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
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local camLook = Camera.CFrame.LookVector
    local best = nil
    local bestDot = -1
    local maxDot = math.cos(math.rad(Settings.MaxAngle))
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and isEnemy(plr) then
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

if getgenv().TracerConnection then
    getgenv().TracerConnection:Disconnect()
end
if getgenv().Tracers then
    for _, v in pairs(getgenv().Tracers) do
        if v.Line and v.Line.Remove then v.Line:Remove() end
        if v.Box and v.Box.Remove then v.Box:Remove() end
        if v.NameTag and v.NameTag.Remove then v.NameTag:Remove() end
        if v.Distance and v.Distance.Remove then v.Distance:Remove() end
    end
end
getgenv().Tracers = {}
local tracers = getgenv().Tracers
local function createESP()
    local line = Drawing.new("Line")
    line.Thickness = 1
    line.Transparency = 1
    line.Visible = false
    local box = Drawing.new("Square")
    box.Thickness = 1
    box.Transparency = 1
    box.Visible = false
    local nameTag = Drawing.new("Text")
    nameTag.Size = 16
    nameTag.Center = true
    nameTag.Outline = true
    nameTag.Visible = false
    local distanceTag = Drawing.new("Text")
    distanceTag.Size = 16
    distanceTag.Center = true
    distanceTag.Outline = true
    distanceTag.Visible = false
    return {Line=line, Box=box, NameTag=nameTag, Distance=distanceTag}
end
local function trackCharacter(p)
    local function setup()
        local c = p.Character
        if not c then return end
        if not tracers[p] then
            tracers[p] = createESP()
        end
    end
    p.CharacterAdded:Connect(setup)
    setup()
end
Players.PlayerAdded:Connect(trackCharacter)
for _, p in pairs(Players:GetPlayers()) do
    trackCharacter(p)
end

getgenv().TracerConnection = RunService.Heartbeat:Connect(function()
    local localRoot = getRoot(LocalPlayer.Character)
    if not localRoot then return end
    local viewport = Camera.ViewportSize
    local screenCenter = Vector2.new(viewport.X*0.5, viewport.Y*0.5)
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local root = getRoot(p.Character)
            local tracer = tracers[p]
            if not tracer then
                tracer = createESP()
                tracers[p] = tracer
            end
            if not Settings.ESP then
                for _, v in pairs(tracer) do v.Visible = false end
                continue
            end
            
            -- Team check logic for ESP
            local shouldShowESP = true
            local color = Color3.fromRGB(255, 0, 0) -- Default enemy color

            if Settings.UseTeamCheck then
                local isSameTeam = p.Team and LocalPlayer.Team and p.Team == LocalPlayer.Team
                local isIgnoredTeam = false
                for _, t in ipairs(Settings.IgnoredTeams) do
                    if p.Team and p.Team.Name == t then
                        isIgnoredTeam = true
                        break
                    end
                end
                
                -- Hide ESP for teammates when team check is enabled
                if isSameTeam or isIgnoredTeam then
                    shouldShowESP = false
                end
            else
                -- When team check is disabled, show ESP for everyone but color them differently
                local isSameTeam = p.Team and LocalPlayer.Team and p.Team == LocalPlayer.Team
                local isIgnoredTeam = false
                for _, t in ipairs(Settings.IgnoredTeams) do
                    if p.Team and p.Team.Name == t then
                        isIgnoredTeam = true
                        break
                    end
                end
                
                if isSameTeam then
                    color = Color3.fromRGB(0, 140, 255) -- Blue for teammates
                elseif isIgnoredTeam then
                    color = Color3.fromRGB(255, 255, 255) -- White for ignored teams
                else
                    color = Color3.fromRGB(255, 0, 0) -- Red for enemies
                end
            end
            
            if not root or (root.Position - localRoot.Position).Magnitude > Settings.MaxRange or not shouldShowESP then
                for _, v in pairs(tracer) do v.Visible = false end
                continue
            end
            local pos, onScreen = Camera:WorldToViewportPoint(root.Position)
            if not onScreen then
                for _, v in pairs(tracer) do v.Visible = false end
            else
                local dist = math.floor((root.Position - localRoot.Position).Magnitude)
                tracer.Line.Color = color
                tracer.Box.Color = color
                tracer.NameTag.Color = color
                tracer.Distance.Color = color
                tracer.Line.From = screenCenter
                tracer.Line.To = Vector2.new(pos.X, pos.Y)
                tracer.Line.Visible = true
                local size = 30
                tracer.Box.Position = Vector2.new(pos.X - size * 0.5, pos.Y - size * 0.5)
                tracer.Box.Size = Vector2.new(size, size)
                tracer.Box.Visible = true
                tracer.NameTag.Text = p.Name
                tracer.NameTag.Position = Vector2.new(pos.X, pos.Y - 25)
                tracer.NameTag.Visible = true
                tracer.Distance.Text = dist.."m"
                tracer.Distance.Position = Vector2.new(pos.X, pos.Y + 25)
                tracer.Distance.Visible = true
            end
        end
    end
end)

print("okidk")