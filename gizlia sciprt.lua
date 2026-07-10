-- ==========================================
-- 1. Fluent UI ライブラリの読み込み
-- ==========================================
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

-- ==========================================
-- 2. 基本設定と状態管理変数
-- ==========================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService") -- Tween用のサービス
local player = Players.LocalPlayer

-- 全てローカル変数で状態を管理
local isTeleportOn = false
local isAttackOn = false
local isBehindOn = false
local isFrontOn = true    -- デフォルトON
local isTweenOn = false   -- 【追加】Tweenモード（デフォルトOFF）
local currentDistance = 50
local targetPlayerName = "最寄り自動追尾"

local teleportConnection = nil

-- ==========================================
-- 3. メインウィンドウの作成
-- ==========================================
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

-- ==========================================
-- 4. 青く光る枠線の「⚡」アイコン作成
-- ==========================================
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

    iconButton.MouseButton1Click:Connect(function()
        Window:Minimize()
    end)
end
createToggleIcon()

-- ==========================================
-- 5. タブの作成
-- ==========================================
local MainTab = Window:AddTab({ Title = "メイン機能", Icon = "zap" })

-- ==========================================
-- 6. 最寄りプレイヤー取得ロジック
-- ==========================================
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

-- ==========================================
-- 7. 【メイン機能】UIパーツ配置
-- ==========================================

-- [1] テレポート開始スイッチ
local TeleportToggle = MainTab:AddToggle("TeleportToggle", {
    Title = "🚀 テレポート開始 (START TELEPORT)",
    Default = false
})
TeleportToggle:OnChanged(function(Value)
    isTeleportOn = Value
end)

-- [2] 最寄り自動追尾ボタン
MainTab:AddButton({
    Title = "🤖 最寄りのプレイヤーを自動追尾",
    Description = "近くにいる生存者を自動でターゲットにします",
    Callback = function()
        targetPlayerName = "最寄り自動追尾"
        Fluent:Notify({
            Title = "ターゲット設定",
            Content = "最寄りのプレイヤー自動追尾に設定しました",
            Duration = 3
        })
    end
})

-- [3] 5連撃バーストスイッチ
local AttackToggle = MainTab:AddToggle("AttackToggle", {
    Title = "🔥 5連撃バースト攻撃 (MAX SPEED)",
    Default = false
})
AttackToggle:OnChanged(function(Value)
    isAttackOn = Value
end)

-- [4] 背後回り込みスイッチ
local BehindToggle = MainTab:AddToggle("BehindToggle", {
    Title = "🔙 敵の背後に回り込む",
    Default = false
})
BehindToggle:OnChanged(function(Value)
    isBehindOn = Value
end)

-- [5] 正面回り込みスイッチ
local FrontToggle = MainTab:AddToggle("FrontToggle", {
    Title = "🎯 敵の正面に回り込む",
    Default = true
})
FrontToggle:OnChanged(function(Value)
    isFrontOn = Value
end)

-- [6] 【新機能】Tweenモードスイッチ（説明付き・デフォルトOFF）
local TweenToggle = MainTab:AddToggle("TweenToggle", {
    Title = "✈️ Tween（滑らか移動）モード",
    Description = "一瞬で消えるワープではなく、ビューン!と超高速で走って近づく安全なモードです",
    Default = false
})
TweenToggle:OnChanged(function(Value)
    isTweenOn = Value
end)

-- [7] 距離スライダー
local DistanceSlider = MainTab:AddSlider("DistanceSlider", {
    Title = "🎯 ターゲットとの設定距離 (DISTANCE)",
    Min = 0,
    Max = 100,
    Default = 50,
    Rounding = 0
})
DistanceSlider:OnChanged(function(Value)
    currentDistance = Value
end)

-- [8] プリセット30ボタン
MainTab:AddButton({
    Title = "🔮 プリセット: ファイナルウォーズ (30)",
    Callback = function()
        DistanceSlider:SetValue(30)
        currentDistance = 30
        Fluent:Notify({
            Title = "プリセット適用",
            Content = "距離を 30 に変更しました",
            Duration = 2
        })
    end
})

-- [9] プレイヤー個別選択ドロップダウン
local function getPlayerList()
    local names = {"最寄り自動追尾"}
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= player then table.insert(names, plr.Name) end
    end
    return names
end

local PlayerDropdown = MainTab:AddDropdown("PlayerDropdown", {
    Title = "👤 個別でターゲットを選ぶ",
    Values = getPlayerList(),
    CurrentOption = "最寄り自動追尾"
})
PlayerDropdown:OnChanged(function(Value)
    if not Value then return end
    targetPlayerName = Value
    Fluent:Notify({
        Title = "ターゲット決定",
        Content = Value .. " をターゲットに指定しました",
        Duration = 3
    })
end)

Players.PlayerAdded:Connect(function() PlayerDropdown:SetValues(getPlayerList()) end)
Players.PlayerRemoving:Connect(function() PlayerDropdown:SetValues(getPlayerList()) end)


-- ==========================================
-- 8. メインループ
-- ==========================================
if teleportConnection then teleportConnection:Disconnect() end

teleportConnection = RunService.RenderStepped:Connect(function()
    local myChar = player.Character
    if not myChar then return end
    local myHrp = myChar:FindFirstChild("HumanoidRootPart")
    if not myHrp then return end

    -- 1. 5連撃バースト攻撃
    if isAttackOn then
        local tool = myChar:FindFirstChildOfClass("Tool")
        if tool then tool:Activate() end
        
        pcall(function()
            local remoteEvent = myChar:FindFirstChild("RemoteEvent") or myChar:FindFirstChildOfClass("RemoteEvent")
            if remoteEvent then
                for i = 1, 5 do 
                    remoteEvent:FireServer("Lc1Hitbox", 0.32500016689301)
                end
            end
        end)
    end

    -- 2. テレポート・移動処理
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

                -- 位置計算の分岐（正面 ＞ 背後 ＞ 通常）
                if isFrontOn then
                    computedPosition = tHrp.Position + (lookDirection * currentDistance) + Vector3.new(0, 5, 0)
                elseif isBehindOn then
                    computedPosition = tHrp.Position - (lookDirection * currentDistance) + Vector3.new(0, 5, 0)
                else
                    computedPosition = tHrp.Position + Vector3.new(0, 5, currentDistance)
                end
                
                -- 移動方式の分岐（Tweenモード ＆ 通常ワープ）
                if isTweenOn then
                    -- 【Tweenモード】0.1秒でターゲット位置へ滑らかに走る
                    local tweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
                    local tween = TweenService:Create(myHrp, tweenInfo, {CFrame = CFrame.lookAt(computedPosition, tHrp.Position)})
                    tween:Play()
                else
                    -- 【通常ワープ】一瞬でパッと移動
                    myHrp.CFrame = CFrame.lookAt(computedPosition, tHrp.Position)
                end
            end
        end
    end
end)

game:BindToClose(function()
    if teleportConnection then teleportConnection:Disconnect() end
end)

Window:SelectTab(1)
