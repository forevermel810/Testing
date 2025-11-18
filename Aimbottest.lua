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

local Settings = getgenv().Aimbot

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UIS = game:GetService("UserInputService")

local function enemy(player)
    if not Settings.UseTeamCheck then return true end
    if not player.Team then return true end
    if player.Team == LocalPlayer.Team then return false end
    for _, t in ipairs(Settings.IgnoredTeams) do
        if player.Team.Name == t then return false end
    end
    return true
end

local function visible(part)
    local c = LocalPlayer.Character
    if not c then return false end
    local h = c:FindFirstChild("Head")
    if not h then return false end
    local origin = h.Position
    local dir = part.Position - origin
    local r = Ray.new(origin, dir)
    local hit = Workspace:FindPartOnRayWithIgnoreList(r, {c})
    return hit and hit:IsDescendantOf(part.Parent)
end

local function getTarget()
    local c = LocalPlayer.Character
    if not c then return end
    local root = c:FindFirstChild("HumanoidRootPart")
    if not root then return end

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
                    local dir = (part.Position - root.Position).Unit
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

if getgenv().AimbotConnection then getgenv().AimbotConnection:Disconnect() end
local smooth = Camera.CFrame

getgenv().AimbotConnection = RunService.RenderStepped:Connect(function(dt)
    local t = getTarget()
    local current = Camera.CFrame
    if Settings.Enabled and t then
        local goal = CFrame.new(current.Position, t.Position)
        smooth = current:Lerp(goal, math.clamp(Settings.SpeedAndSmoothness * dt, 0, 1))
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
toggle.Position = UDim2.new(1,-220,0,20)
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

local dragging = false
local offset = Vector2.new()
local drag = Instance.new("Frame", toggle)
drag.Size = UDim2.new(1,0,0,30)
drag.BackgroundTransparency = 1

drag.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        offset = UIS:GetMouseLocation() - toggle.AbsolutePosition
    end
end)

drag.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

UIS.InputChanged:Connect(function(i)
    if dragging then
        local pos = UIS:GetMouseLocation() - offset
        toggle.Position = UDim2.new(0,pos.X,0,pos.Y)
    end
end)

local ESPHolders = {}

local function setupCharacter(player, character)
    if ESPHolders[player] then
        local old = ESPHolders[player]
        if old.connection then old.connection:Disconnect() end
        if old.highlight then old.highlight:Destroy() end
        if old.billboard then old.billboard:Destroy() end
    end

    local hum = character:FindFirstChildOfClass("Humanoid")
    local head = character:FindFirstChild("Head")
    if not hum or not head then return end

    local h = Instance.new("Highlight")
    h.Name = "ESP_Highlight"
    h.FillColor = player.Team and player.Team.TeamColor.Color or Color3.fromRGB(255,0,0)
    h.OutlineColor = Color3.fromRGB(255,255,255)
    h.FillTransparency = 0.5
    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    h.Adornee = character
    h.Parent = character

    local b = Instance.new("BillboardGui")
    b.Name = "ESP_Billboard"
    b.Size = UDim2.new(0,200,0,50)
    b.StudsOffset = Vector3.new(0,3,0)
    b.AlwaysOnTop = true
    b.Adornee = head
    b.Parent = character

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1,0,1,0)
    label.BackgroundTransparency = 1
    label.TextColor3 = h.FillColor
    label.TextStrokeTransparency = 0.5
    label.Font = Enum.Font.SourceSansLight
    label.TextSize = 14
    label.Parent = b

    local function update()
        local lc = LocalPlayer.Character
        local hrp = lc and lc:FindFirstChild("HumanoidRootPart")
        local tr = character:FindFirstChild("HumanoidRootPart")
        local alive = hum.Health > 0
        local show = Settings.ESP and enemy(player) and alive

        h.Enabled = show
        b.Enabled = show

        if hrp and tr and alive then
            local d = (hrp.Position - tr.Position).Magnitude
            label.Text = player.Name .. "\n[" .. math.floor(d) .. " studs]"
        else
            label.Text = player.Name .. "\n[DEAD]"
        end
    end

    local connection = RunService.Heartbeat:Connect(update)

    ESPHolders[player] = {
        connection = connection,
        highlight = h,
        billboard = b
    }

    update()
end

local function createESP(player)
    if player == LocalPlayer then return end
    player.CharacterAdded:Connect(function(c)
        setupCharacter(player, c)
    end)
    if player.Character then
        setupCharacter(player, player.Character)
    end
end

for _, plr in pairs(Players:GetPlayers()) do
    createESP(plr)
end

Players.PlayerAdded:Connect(createESP)

Players.PlayerRemoving:Connect(function(player)
    local old = ESPHolders[player]
    if old then
        if old.connection then old.connection:Disconnect() end
        if old.highlight then old.highlight:Destroy() end
        if old.billboard then old.billboard:Destroy() end
        ESPHolders[player] = nil
    end
end)

print("i think it works")