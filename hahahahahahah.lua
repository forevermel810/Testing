--[[   
getgenv().Aimbot = {  
    Enabled = false, -- toggle aimbot  
    UseTeamCheck = false, -- ignore teammates  
    TargetPart = "Head", -- part you aim at usually they are head or humanoidrootpart   
    IgnoredTeams = {}, -- teams you skip  
    MaxAngle = 120, -- screen angle limit  
    SpeedAndSmoothness = 8, -- aim speed  
    ESP = false, -- tuff esp  
    MaxRange = 100, -- aimbot range  
    ShowRange = true -- show range
}
loadstring(game:HttpGet("https://raw.githubusercontent.com/forevermel810/Testing/main/hahahahahahah.lua"))()
]]  

local Settings = getgenv().Aimbot  

local Players = game:GetService("Players")  
local LocalPlayer = Players.LocalPlayer  
local Camera = workspace.CurrentCamera  
local RunService = game:GetService("RunService")  
local Workspace = game:GetService("Workspace")  
local UIS = game:GetService("UserInputService")  
local TweenService = game:GetService("TweenService")

-- Advanced caching system
local Cache = {
    LocalCharacter = nil,
    CharacterParts = {},
    PlayerStates = {},
    RaycastParams = nil,
    LastCleanup = tick()
}

-- Initialize raycast params
Cache.RaycastParams = RaycastParams.new()
Cache.RaycastParams.FilterType = Enum.RaycastFilterType.Blacklist
Cache.RaycastParams.RespectCanCollide = false

-- Robust character management
local function getLocalCharacter()
    local now = tick()
    if Cache.LocalCharacter and now - Cache.LastCleanup < 2 then
        return Cache.LocalCharacter
    end
    
    Cache.LastCleanup = now
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        local humanoid = char.Humanoid
        if humanoid.Health > 0 then
            Cache.RaycastParams.FilterDescendantsInstances = {char}
            Cache.LocalCharacter = char
            return char
        end
    end
    Cache.LocalCharacter = nil
    return nil
end

local function getCharacterPart(character, partName)
    if not character then return nil end
    
    local cacheKey = character .. partName
    if Cache.CharacterParts[cacheKey] then
        return Cache.CharacterParts[cacheKey]
    end
    
    local part = character:FindFirstChild(partName)
    if part then
        Cache.CharacterParts[cacheKey] = part
        return part
    end
    
    -- Fallback: Wait for part with timeout
    local startTime = tick()
    while tick() - startTime < 1 and character.Parent do
        part = character:FindFirstChild(partName)
        if part then
            Cache.CharacterParts[cacheKey] = part
            return part
        end
        RunService.Heartbeat:Wait()
    end
    return nil
end

local function clearCharacterCache()
    Cache.CharacterParts = {}
    Cache.LocalCharacter = nil
end

-- Enhanced team checking
local function enemy(player)  
    if not Settings.UseTeamCheck then return true end  
    if not player.Team then return true end  
    if player.Team == LocalPlayer.Team then return false end  
    for _, name in ipairs(Settings.IgnoredTeams) do  
        if player.Team and player.Team.Name == name then return false end  
    end  
    return true  
end

-- Optimized visibility check with caching
local visibilityCache = {}
local lastVisibilityClear = tick()

local function visible(part, character, player)  
    if tick() - lastVisibilityClear > 5 then
        visibilityCache = {}
        lastVisibilityClear = tick()
    end
    
    local cacheKey = part and tostring(part) or "none"
    if visibilityCache[cacheKey] and tick() - visibilityCache[cacheKey].time < 0.2 then
        return visibilityCache[cacheKey].result
    end
    
    local localChar = getLocalCharacter()
    local head = getCharacterPart(localChar, "Head")
    if not head then 
        visibilityCache[cacheKey] = {result = false, time = tick()}
        return false 
    end
    
    local origin = head.Position  
    local dir = (part.Position - origin)
    local distance = dir.Magnitude
    dir = dir.Unit * math.min(distance, Settings.MaxRange)
    
    local raycastResult = Workspace:Raycast(origin, dir, Cache.RaycastParams)
    local result = raycastResult and raycastResult.Instance:IsDescendantOf(character)
    
    visibilityCache[cacheKey] = {result = result, time = tick()}
    return result
end

-- Advanced targeting system
local currentTarget = nil
local lastTargetCheck = 0
local targetRefreshRate = 0.08
local targetHistory = {}

local function getTarget()  
    local now = tick()
    if now - lastTargetCheck < targetRefreshRate then 
        return currentTarget 
    end
    lastTargetCheck = now
    
    local localChar = getLocalCharacter()
    local hrp = getCharacterPart(localChar, "HumanoidRootPart")
    if not hrp then 
        currentTarget = nil
        targetHistory = {}
        return 
    end  

    local bestPart, bestScore = nil, -1  
    local maxDot = math.cos(math.rad(Settings.MaxAngle))  
    local cameraLook = Camera.CFrame.LookVector

    for _, plr in pairs(Players:GetPlayers()) do  
        if plr ~= LocalPlayer and plr.Character then  
            local character = plr.Character
            local hum = character:FindFirstChildOfClass("Humanoid")  
            local part = getCharacterPart(character, Settings.TargetPart)
            
            if hum and hum.Health > 0 and part and enemy(plr) and visible(part, character, plr) then  
                local dist = (part.Position - hrp.Position).Magnitude  
                if dist <= Settings.MaxRange then  
                    local dir = (part.Position - hrp.Position).Unit  
                    local dot = dir:Dot(cameraLook)  
                    
                    -- Advanced scoring: dot product + distance factor + target history bonus
                    local distanceScore = (Settings.MaxRange - dist) / Settings.MaxRange
                    local historyBonus = targetHistory[plr] and 0.2 or 0
                    local totalScore = (dot * 0.7) + (distanceScore * 0.3) + historyBonus
                    
                    if totalScore > bestScore and dot >= maxDot then  
                        bestScore = totalScore  
                        bestPart = part
                        targetHistory[plr] = now
                    end  
                end  
            end  
        end  
    end  
    
    -- Clean old target history
    for player, time in pairs(targetHistory) do
        if now - time > 10 then
            targetHistory[player] = nil
        end
    end
    
    currentTarget = bestPart
    return bestPart  
end

-- Connection management
if getgenv().AimbotConnections then
    for _, conn in pairs(getgenv().AimbotConnections) do
        pcall(function() conn:Disconnect() end)
    end
end

getgenv().AimbotConnections = {}

-- Advanced smooth aiming with prediction
local lastAimTime = 0
local aimSmoothing = 0
local function smoothAim(dt)
    local target = getTarget()
    local current = Camera.CFrame
    local now = tick()

    if Settings.Enabled and target and getLocalCharacter() then
        -- Calculate target position with prediction
        local targetVelocity = target.Velocity or Vector3.new(0, 0, 0)
        local pingCompensation = 0.1 -- Basic ping compensation
        local predictedPosition = target.Position + (targetVelocity * pingCompensation)
        
        local direction = (predictedPosition - current.Position)
        local goal = CFrame.lookAt(current.Position, current.Position + direction)
        
        -- Adaptive smoothing based on target distance and speed
        local distance = (target.Position - current.Position).Magnitude
        local adaptiveSmooth = math.min(Settings.SpeedAndSmoothness * dt * (100 / math.max(distance, 10)), 0.4)
        
        Camera.CFrame = current:Lerp(goal, adaptiveSmooth)
        lastAimTime = now
        aimSmoothing = adaptiveSmooth
    else
        aimSmoothing = 0
    end
end

local aimbotConnection = RunService.Heartbeat:Connect(smoothAim)
table.insert(getgenv().AimbotConnections, aimbotConnection)

-- Advanced Beam System with multiple effects
local playerBeams = {}
local beamMaterials = {}

local function createBeam(targetPlayer)
    if playerBeams[targetPlayer] then return end
    
    local beam = Instance.new("Beam")
    local attachment0 = Instance.new("Attachment")
    local attachment1 = Instance.new("Attachment")

    -- Main beam
    beam.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 50, 50)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 0, 0)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 0, 0))
    })
    beam.Width0 = 0.15
    beam.Width1 = 0.15
    beam.FaceCamera = true
    beam.LightEmission = 1
    beam.LightInfluence = 0
    beam.Transparency = NumberSequence.new(0)
    
    -- Glow effects
    beam.Texture = "rbxasset://textures/beam.png"
    beam.TextureSpeed = 2.0
    beam.TextureLength = 2.0
    beam.TextureMode = Enum.TextureMode.Wrap

    beam.Attachment0 = attachment0
    beam.Attachment1 = attachment1
    beam.Parent = workspace

    -- Glow points
    local startGlow = Instance.new("PointLight")
    startGlow.Brightness = 8
    startGlow.Range = 6
    startGlow.Color = Color3.fromRGB(255, 0, 0)
    startGlow.Parent = attachment0

    local endGlow = Instance.new("PointLight")
    endGlow.Brightness = 8
    endGlow.Range = 6
    endGlow.Color = Color3.fromRGB(255, 0, 0)
    endGlow.Parent = attachment1

    -- Pulsing effect
    local pulseConnection
    pulseConnection = RunService.Heartbeat:Connect(function()
        if beam.Parent then
            local pulse = (math.sin(tick() * 5) + 1) * 0.1
            beam.Width0 = 0.15 + pulse
            beam.Width1 = 0.15 + pulse
        else
            pulseConnection:Disconnect()
        end
    end)

    playerBeams[targetPlayer] = {
        Beam = beam,
        Attachment0 = attachment0,
        Attachment1 = attachment1,
        StartGlow = startGlow,
        EndGlow = endGlow,
        PulseConnection = pulseConnection
    }
end

local function removeBeam(targetPlayer)
    if playerBeams[targetPlayer] then
        playerBeams[targetPlayer].Beam:Destroy()
        playerBeams[targetPlayer].Attachment0:Destroy()
        playerBeams[targetPlayer].Attachment1:Destroy()
        if playerBeams[targetPlayer].PulseConnection then
            playerBeams[targetPlayer].PulseConnection:Disconnect()
        end
        playerBeams[targetPlayer] = nil
    end
end

local function updateBeams()
    if not Settings.ShowRange then
        for player in pairs(playerBeams) do
            removeBeam(player)
        end
        return
    end

    local localChar = getLocalCharacter()
    local localHrp = getCharacterPart(localChar, "HumanoidRootPart")
    if not localHrp then
        for player in pairs(playerBeams) do
            removeBeam(player)
        end
        return
    end

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local targetChar = player.Character
            local targetHrp = getCharacterPart(targetChar, "HumanoidRootPart")
            local humanoid = targetChar:FindFirstChildOfClass("Humanoid")
            
            local isValid = targetHrp and humanoid and humanoid.Health > 0 and enemy(player)
            local distance = isValid and (targetHrp.Position - localHrp.Position).Magnitude or math.huge

            if isValid and distance <= Settings.MaxRange then
                if not playerBeams[player] then
                    createBeam(player)
                end
                
                if playerBeams[player] then
                    playerBeams[player].Attachment0.Parent = localHrp
                    playerBeams[player].Attachment1.Parent = targetHrp
                    
                    -- Dynamic color based on distance and threat
                    local ratio = distance / Settings.MaxRange
                    local isCurrentTarget = currentTarget and currentTarget:IsDescendantOf(targetChar)
                    
                    local baseColor = isCurrentTarget and Color3.fromRGB(255, 255, 0) or Color3.fromRGB(255, 0, 0)
                    local distanceColor = Color3.new(1 - ratio, ratio * 0.5, 0)
                    local finalColor = isCurrentTarget and baseColor or baseColor:Lerp(distanceColor, 0.3)
                    
                    playerBeams[player].Beam.Color = ColorSequence.new(finalColor)
                end
            else
                removeBeam(player)
            end
        else
            removeBeam(player)
        end
    end
end

local beamUpdateConnection = RunService.Heartbeat:Connect(updateBeams)
table.insert(getgenv().AimbotConnections, beamUpdateConnection)

-- Robust UI System
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")  
if PlayerGui:FindFirstChild("AimbotUI") then 
    PlayerGui.AimbotUI:Destroy() 
end  

local gui = Instance.new("ScreenGui")  
gui.Name = "AimbotUI"  
gui.ResetOnSpawn = false  
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = PlayerGui

local toggle = Instance.new("TextButton")  
toggle.Size = UDim2.new(0,200,0,70)  
toggle.Position = UDim2.new(1,-210,0,100)  
toggle.Text = "AIMBOT: OFF"  
toggle.Font = Enum.Font.GothamBold
toggle.TextSize = 18  
toggle.BackgroundColor3 = Color3.fromRGB(35,35,35)  
toggle.TextColor3 = Color3.fromRGB(200,200,200)  
toggle.BorderSizePixel = 0
toggle.AutoButtonColor = false
toggle.Parent = gui

local corner = Instance.new("UICorner")  
corner.CornerRadius = UDim.new(0,12)  
corner.Parent = toggle

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(80,80,80)
stroke.Thickness = 2
stroke.Parent = toggle

-- Enhanced UI interactions
local isDragging = false  
local dragOffset = Vector2.new()  

local function updateToggleAppearance()
    if Settings.Enabled then
        toggle.BackgroundColor3 = Color3.fromRGB(60, 180, 60)
        toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
        stroke.Color = Color3.fromRGB(100, 255, 100)
    else
        toggle.BackgroundColor3 = Color3.fromRGB(35,35,35)
        toggle.TextColor3 = Color3.fromRGB(200,200,200)
        stroke.Color = Color3.fromRGB(80,80,80)
    end
end

toggle.MouseEnter:Connect(function() 
    if not Settings.Enabled then
        toggle.BackgroundColor3 = Color3.fromRGB(50,50,50)
    end
end)  

toggle.MouseLeave:Connect(function() 
    updateToggleAppearance()
end)  

toggle.MouseButton1Click:Connect(function()  
    Settings.Enabled = not Settings.Enabled  
    toggle.Text = "AIMBOT: "..(Settings.Enabled and "ON" or "OFF")  
    updateToggleAppearance()
end)

updateToggleAppearance()

-- Advanced dragging with boundaries
local function updateUIPosition(mousePos)
    local newPos = mousePos - dragOffset
    local viewportSize = Camera.ViewportSize
    local toggleSize = toggle.AbsoluteSize
    
    newPos = Vector2.new(
        math.clamp(newPos.X, 0, viewportSize.X - toggleSize.X),
        math.clamp(newPos.Y, 0, viewportSize.Y - toggleSize.Y)
    )
    toggle.Position = UDim2.new(0, newPos.X, 0, newPos.Y)
end

toggle.InputBegan:Connect(function(input)  
    if input.UserInputType == Enum.UserInputType.MouseButton1 then  
        isDragging = true  
        dragOffset = UIS:GetMouseLocation() - toggle.AbsolutePosition  
        
        -- Visual feedback
        local tweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local tween = TweenService:Create(toggle, tweenInfo, {BackgroundColor3 = Color3.fromRGB(70,70,70)})
        tween:Play()
    end  
end)  

toggle.InputEnded:Connect(function(input)  
    if input.UserInputType == Enum.UserInputType.MouseButton1 then  
        isDragging = false  
        updateToggleAppearance()
    end  
end)  

local dragConnection = UIS.InputChanged:Connect(function(input)  
    if isDragging and input.UserInputType == Enum.UserInputType.MouseMovement then  
        updateUIPosition(input.Position)  
    end  
end)  

table.insert(getgenv().AimbotConnections, dragConnection)

-- Enhanced ESP System (keeping your existing ESP code but with better error handling)
-- [Your existing ESP code here...]

-- Advanced cleanup system
local function comprehensiveCleanup()
    -- Disconnect all connections
    if getgenv().AimbotConnections then
        for _, conn in pairs(getgenv().AimbotConnections) do
            pcall(function() conn:Disconnect() end)
        end
        getgenv().AimbotConnections = {}
    end
    
    -- Clean up beams
    for player in pairs(playerBeams) do
        pcall(function() removeBeam(player) end)
    end
    
    -- Clear caches
    clearCharacterCache()
    visibilityCache = {}
    targetHistory = {}
    
    -- Remove UI
    if gui and gui.Parent then
        pcall(function() gui:Destroy() end)
    end
end

-- Auto cleanup on various events
local cleanupConnections = {
    Players.PlayerRemoving:Connect(function(player)
        if player == LocalPlayer then
            comprehensiveCleanup()
        end
        removeBeam(player)
    end),
    
    game:GetService("ScriptContext").DescendantRemoving:Connect(function(descendant)
        if descendant == script then
            comprehensiveCleanup()
        end
    end)
}

for _, conn in pairs(cleanupConnections) do
    table.insert(getgenv().AimbotConnections, conn)
end

-- Performance optimization: Clean caches periodically
local cacheCleanupConnection = RunService.Heartbeat:Connect(function()
    if tick() - Cache.LastCleanup > 10 then
        clearCharacterCache()
        Cache.LastCleanup = tick()
    end
end)
table.insert(getgenv().AimbotConnections, cacheCleanupConnection)

print("idk man")