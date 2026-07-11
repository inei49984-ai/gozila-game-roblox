local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer

local isTeleportOn = false
local isAttackOn = false
local isLightAttackOn = false
local isBehindOn = false
local isFrontOn = false    
local isRotateOn = false   
local isRandomSafeOn = true 
local currentDistance = 30 
local targetPlayerName = "最寄り自動追尾"
local isSpeedOn = false
local walkSpeedValue = 16 

local teleportConnection = nil
local rotateAngle = 0 
local lastMoveTime = 0
local lastStrikeTime = 0
local lastBurstAttackTime = 0
local lastLightAttackTime = 0
local currentRandomOffset = Vector3.new(0, 5, 0)
local isStrikeMoment = false

local Window = Fluent:CreateWindow({
    Title = "ADMIN CONTROL PANEL",
    SubTitle = "by Assistant",
    TabWidth = 140,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = false,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})
Window:Minimize()

local function createToggleIcon()
    local playerGui = player:WaitForChild("PlayerGui")
    local oldIcon = playerGui:FindFirstChild("FluentToggleIconGui")
    if oldIcon then oldIcon:Destroy() end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "FluentToggleIconGui"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui

    local iconButton = Instance.new("TextButton")
    iconButton.Name = "IconButton"
    iconButton.Size = UDim2.new(0, 50, 0, 50)
    iconButton.Position = UDim2.new(1, -70, 0, 20)
    iconButton.BackgroundColor3 = Color3.fromRGB(35, 115, 255)
    iconButton.Text = "⚡"
    iconButton.TextSize = 24
    iconButton.Font = Enum.Font.GothamBold
    iconButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    iconButton.Parent = screenGui
    
    Instance.new("UICorner", iconButton).CornerRadius = UDim.new(0, 12)
    local iconStroke = Instance.new("UIStroke", iconButton)
    iconStroke.Color = Color3.fromRGB(100, 180, 255)
    iconStroke.Thickness = 1.5

    iconButton.MouseButton1Click:Connect(function() Window:Minimize() end)
end
createToggleIcon()

local function getNearestPlayer()
    local myChar = player.Character
    if not myChar then return nil end
    local myHrp = myChar:FindFirstChild("HumanoidRootPart")
    if not myHrp then return nil end

    local nearestPlr = nil
    local shortestDistance = math.huge

    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character then
            local tHrp = plr.Character:FindFirstChild("HumanoidRootPart")
            local tHum = plr.Character:FindFirstChildOfClass("Humanoid")
            if tHrp and tHum and tHum.Health > 0 then
                local dist = (myHrp.Position - tHrp.Position).Magnitude
                if dist < shortestDistance then
                    shortestDistance = dist
                    nearestPlr = plr
                end
            end
        end
    end
    return nearestPlr
end

local MainTab = Window:AddTab({ Title = "メイン機能", Icon = "zap" })

local TeleportToggle = MainTab:AddToggle("TeleportToggle", { Title = "🚀 テレポート開始 (START TELEPORT)", Default = false })
TeleportToggle:OnChanged(function(Value) isTeleportOn = Value end)

MainTab:AddButton({
    Title = "🤖 最寄りのプレイヤーを自動追尾",
    Description = "近くにいる生存者を自動でターゲットにします",
    Callback = function() targetPlayerName = "最寄り自動追尾" end
})

local AttackToggle = MainTab:AddToggle("AttackToggle", { Title = "🔥 5連撃バースト攻撃 (0.016秒毎5発)", Default = false })
AttackToggle:OnChanged(function(Value) 
    isAttackOn = Value 
    if Value then 
        isLightAttackOn = false 
        local ToggleWidget = Fluent:GetWidget("LightAttackToggle")
        if ToggleWidget then ToggleWidget:SetValue(false) end
    end
end)

local LightAttackToggle = MainTab:AddToggle("LightAttackToggle", { Title = "🍃 攻撃軽量化モード (0.1秒毎3発/低負荷)", Default = false })
LightAttackToggle:OnChanged(function(Value) 
    isLightAttackOn = Value 
    if Value then 
        isAttackOn = false 
        local ToggleWidget = Fluent:GetWidget("AttackToggle")
        if ToggleWidget then ToggleWidget:SetValue(false) end
    end
end)

local RandomSafeToggle = MainTab:AddToggle("RandomSafeToggle", { Title = "🛡️ 安全ランダム乱舞モード (0.1秒乱舞/0.5秒強襲)", Default = true })
RandomSafeToggle:OnChanged(function(Value) 
    isRandomSafeOn = Value 
    if Value then isRotateOn = false isFrontOn = false isBehindOn = false end
end)

local RotateToggle = MainTab:AddToggle("RotateToggle", { Title = "🌀 超高速回転モード（ターゲットの周りを回る）", Default = false })
RotateToggle:OnChanged(function(Value) 
    isRotateOn = Value 
    if Value then isRandomSafeOn = false isFrontOn = false isBehindOn = false end
end)

local FrontToggle = MainTab:AddToggle("FrontToggle", { Title = "🎯 敵の正面に回り込む", Default = false })
FrontToggle:OnChanged(function(Value) 
    isFrontOn = Value 
    if Value then isRandomSafeOn = false isRotateOn = false isBehindOn = false end
end)

local BehindToggle = MainTab:AddToggle("BehindToggle", { Title = "🔙 敵の背後に回り込む", Default = false })
BehindToggle:OnChanged(function(Value) 
    isBehindOn = Value 
    if Value then isRandomSafeOn = false isRotateOn = false isFrontOn = false end
end)

local TweenToggle = MainTab:AddToggle("TweenToggle", { Title = "✈️ Tween（滑らか移動）モード", Default = false })
TweenToggle:OnChanged(function(Value) isTweenOn = Value end)

local SpeedToggle = MainTab:AddToggle("SpeedToggle", { Title = "⚡ 移動速度調節を有効化", Default = false })
SpeedToggle:OnChanged(function(Value) isSpeedOn = Value end)

local SpeedSlider = MainTab:AddSlider("SpeedSlider", { Title = "🏃‍♂️ キャラクターの走る速度 (SPEED)", Min = 16, Max = 200, Default = 16, Rounding = 0 })
SpeedSlider:OnChanged(function(Value) walkSpeedValue = Value end)

local DistanceSlider = MainTab:AddSlider("DistanceSlider", { Title = "🎯 ターゲットとの設定距離 (DISTANCE)", Min = 0, Max = 100, Default = 30, Rounding = 0 })
DistanceSlider:OnChanged(function(Value) currentDistance = Value end)

MainTab:AddButton({
    Title = "🔮 プリセット: ファイナルウォーズ (30)",
    Callback = function() DistanceSlider:SetValue(30) currentDistance = 30 end
})

local function getPlayerList()
    local names = {"最寄り自動追尾"}
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= player then table.insert(names, plr.Name) end
    end
    return names
end

local PlayerDropdown = MainTab:AddDropdown("PlayerDropdown", { Title = "👤 個別でターゲットを選ぶ", Values = getPlayerList(), CurrentOption = "最寄り自動追尾" })
PlayerDropdown:OnChanged(function(Value) if Value then targetPlayerName = Value end end)

Players.PlayerAdded:Connect(function() PlayerDropdown:SetValues(getPlayerList()) end)
Players.PlayerRemoving:Connect(function() PlayerDropdown:SetValues(getPlayerList()) end)

if teleportConnection then teleportConnection:Disconnect() end

teleportConnection = RunService.RenderStepped:Connect(function()
    local myChar = player.Character
    if not myChar then return end
    local myHrp = myChar:FindFirstChild("HumanoidRootPart")
    local myHum = myChar:FindFirstChildOfClass("Humanoid")
    if not myHrp or not myHum then return end

    local currentTime = tick()

    if (isAttackOn or isLightAttackOn) and (not isRandomSafeOn or isStrikeMoment) then
        local tool = myChar:FindFirstChildOfClass("Tool")
        if tool then tool:Activate() end
        
        if isAttackOn and (currentTime - lastBurstAttackTime >= 0.016) then
            lastBurstAttackTime = currentTime
            pcall(function()
                local remoteEvent = myChar:FindFirstChild("RemoteEvent") or myChar:FindFirstChildOfClass("RemoteEvent")
                if remoteEvent then
                    for i = 1, 5 do 
                        remoteEvent:FireServer("Lc1Hitbox", 0.32500016689301) 
                    end
                end
            end)
        elseif isLightAttackOn and (currentTime - lastLightAttackTime >= 0.1) then
            lastLightAttackTime = currentTime
            pcall(function()
                local remoteEvent = myChar:FindFirstChild("RemoteEvent") or myChar:FindFirstChildOfClass("RemoteEvent")
                if remoteEvent then
                    for i = 1, 3 do
                        remoteEvent:FireServer("Lc1Hitbox", 0.32500016689301)
                    end
                end
            end)
        end
    end

    if isSpeedOn then myHum.WalkSpeed = walkSpeedValue end

    if isTeleportOn then
        local targetPlr = nil
        if targetPlayerName == "最寄り自動追尾" then
            targetPlr = getNearestPlayer()
        else
            targetPlr = Players:FindFirstChild(targetPlayerName)
        end

        if targetPlr and targetPlr.Character then
            local tChar = targetPlr.Character
            local tHrp = tChar:FindFirstChild("HumanoidRootPart")
            local tHum = tChar:FindFirstChildOfClass("Humanoid")

            if tHrp and tHum and tHum.Health > 0 then
                local computedPosition
                local lookDirection = tHrp.CFrame.LookVector

                if isRandomSafeOn then
                    if currentTime - lastStrikeTime >= 0.5 then
                        lastStrikeTime = currentTime
                        isStrikeMoment = true
                    elseif currentTime - lastStrikeTime > 0.08 then
                        isStrikeMoment = false
                    end

                    if isStrikeMoment then
                        local strikeDirection = currentRandomOffset.Unit
                        if strikeDirection.Magnitude == 0 then strikeDirection = Vector3.new(0,0,1) end
                        computedPosition = tHrp.Position + (strikeDirection * currentDistance)
                    else
                        if currentTime - lastMoveTime >= 0.1 then
                            lastMoveTime = currentTime
                            local randomDirection = Vector3.new(math.random(-100, 100), math.random(-10, 50), math.random(-100, 100)).Unit
                            currentRandomOffset = randomDirection * (currentDistance + 40)
                        end
                        computedPosition = tHrp.Position + currentRandomOffset
                    end
                elseif isRotateOn then
                    rotateAngle = rotateAngle + 0.15
                    local offsetX = math.cos(rotateAngle) * currentDistance
                    local offsetZ = math.sin(rotateAngle) * currentDistance
                    computedPosition = tHrp.Position + Vector3.new(offsetX, 5, offsetZ)
                elseif isFrontOn then
                    computedPosition = tHrp.Position + (lookDirection * currentDistance) + Vector3.new(0, 5, 0)
                elseif isBehindOn then
                    computedPosition = tHrp.Position - (lookDirection * currentDistance) + Vector3.new(0, 5, 0)
                else
                    computedPosition = tHrp.Position + Vector3.new(0, 5, currentDistance)
                end
                
                if isTweenOn then
                    local tweenInfo = TweenInfo.new(0.05, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
                    local tween = TweenService:Create(myHrp, tweenInfo, {CFrame = CFrame.lookAt(computedPosition, tHrp.Position)})
                    tween:Play()
                else
                    myHrp.CFrame = CFrame.lookAt(computedPosition, tHrp.Position)
                end
            end
        end
    end
end)

game:BindToClose(function() if teleportConnection then teleportConnection:Disconnect() end end)
Window:SelectTab(1)
