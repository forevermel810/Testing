--[[
getgenv().Aimbot = {
    Enabled = false,
    UseTeamCheck = false,
    ESP = false,
    ESPTeamCheck = false,
    TargetPart = "Head",
    IgnoredTeams = {},
    MaxAngle = 120,
    LerpSpeed = 8
}

loadstring(game:HttpGet("https://raw.githubusercontent.com/forevermel810/Testing/main/Aimbottest.lua"))()
]]

------------------------------------------------------------
-- SERVICES
------------------------------------------------------------
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera

------------------------------------------------------------
-- SETTINGS TABLE REFERENCE
------------------------------------------------------------
local Settings = getgenv().Aimbot

------------------------------------------------------------
-- VISIBILITY CHECK ALWAYS ON
------------------------------------------------------------
local function visible(part)
    local head = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head")
    if not head then return false end

    local origin = head.Position
    local dir = part.Position - origin
    local ray = Ray.new(origin, dir)
    local hit = workspace:FindPartOnRayWithIgnoreList(ray, {LocalPlayer.Character})

    return hit and hit:IsDescendantOf(part.Parent)
end

------------------------------------------------------------
-- TEAM CHECK
------------------------------------------------------------
local function sameTeam(plr)
    if not plr.Team or not LocalPlayer.Team then return false end
    return plr.Team == LocalPlayer.Team
end

------------------------------------------------------------
-- GET TARGET
------------------------------------------------------------
local function getTarget()
    local best = nil
    local bestAngle = Settings.MaxAngle

    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            if Settings.UseTeamCheck and sameTeam(p) then
                -- skip
            else
                local char = p.Character
                local part = char and char:FindFirstChild(Settings.TargetPart)
                if part and visible(part) then
                    local pos, onScreen = Camera:WorldToScreenPoint(part.Position)
                    if onScreen then
                        local mousePos = UIS:GetMouseLocation()
                        local dx = pos.X - mousePos.X
                        local dy = pos.Y - mousePos.Y
                        local dist = math.sqrt(dx*dx + dy*dy)

                        if dist < bestAngle then
                            bestAngle = dist
                            best = part
                        end
                    end
                end
            end
        end
    end

    return best
end

------------------------------------------------------------
-- AIM LOOP
------------------------------------------------------------
RunService.RenderStepped:Connect(function()
    if not Settings.Enabled then return end

    local target = getTarget()
    if target then
        local goal = CFrame.new(Camera.CFrame.Position, target.Position)
        Camera.CFrame = Camera.CFrame:Lerp(goal, Settings.LerpSpeed * 0.01)
    end
end)

------------------------------------------------------------
-- GUI
------------------------------------------------------------
local ScreenGui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0,180,0,160)
Frame.Position = UDim2.new(0.05,0,0.2,0)
Frame.BackgroundColor3 = Color3.fromRGB(30,30,30)

local function makeToggle(name, y, callback)
    local btn = Instance.new("TextButton", Frame)
    btn.Size = UDim2.new(1,-20,0,25)
    btn.Position = UDim2.new(0,10,0,y*25)
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(220,220,220)
    btn.Font = Enum.Font.SourceSansLight
    btn.BackgroundColor3 = Color3.fromRGB(50,50,50)

    btn.MouseButton1Click:Connect(callback)
end

makeToggle("Aimbot",0,function() Settings.Enabled = not Settings.Enabled end)
makeToggle("Team Check",1,function() Settings.UseTeamCheck = not Settings.UseTeamCheck end)
makeToggle("ESP",2,function() Settings.ESP = not Settings.ESP end)
makeToggle("ESP Team Check",3,function() Settings.ESPTeamCheck = not Settings.ESPTeamCheck end)

------------------------------------------------------------
-- ESP
------------------------------------------------------------
local function createBox(char)
    local h = Instance.new("Highlight")
    h.Parent = char
    h.FillTransparency = 1
    h.OutlineTransparency = 0
    h.OutlineColor = Color3.fromRGB(255,255,255)
    return h
end

local ESPStorage = {}

local function updateESP()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local char = p.Character
            if char then
                local teamBlock = Settings.ESPTeamCheck and p.Team and LocalPlayer.Team and p.Team == LocalPlayer.Team
                if Settings.ESP and not teamBlock then
                    if not ESPStorage[p] then
                        ESPStorage[p] = createBox(char)
                    end
                    if p.Team then
                        ESPStorage[p].OutlineColor = p.Team.TeamColor.Color
                    end
                else
                    if ESPStorage[p] then
                        ESPStorage[p]:Destroy()
                        ESPStorage[p] = nil
                    end
                end
            end
        end
    end
end

RunService.RenderStepped:Connect(updateESP)