loadstring(game:HttpGet("https://raw.githubusercontent.com/sharkindigo12/ATTACK-OF-TITAN/refs/heads/main/obfuscated_script-1764221856270.lua.txt"))()

 

local Players = game:GetService("Players")

local RunService = game:GetService("RunService")

local UserInputService = game:GetService("UserInputService")

local ContextActionService = game:GetService("ContextActionService")

 

local player = Players.LocalPlayer

-- 距離を 50 から 40 に変更しました

local CONFIG = {TELEPORT_HEIGHT = 5, TELEPORT_DISTANCE = 40}

 

-- 状態管理変数

local selectedPlayer = nil

local currentTargetPlayer = nil

local teleportEnabled = false

local teleportConnection = nil

local uiOpen = false

 

-- スマホ用視点ロックの識別子

local ACTION_LOCK_NAME = "UI_Drag_Camera_Lock"

 

-- 視点移動をロック/解除する関数

local function setCameraLock(shouldLock)

    if shouldLock then

        ContextActionService:BindActionAtPriority(

            ACTION_LOCK_NAME,

            function() return Enum.ContextActionResult.Sink end,

            false,

            2000,

            Enum.UserInputType.Touch, Enum.UserInputType.MouseButton1

        )

    else

        ContextActionService:UnbindAction(ACTION_LOCK_NAME)

    end

end

 

-- スマホのタップとドラッグを両立させるドラッグ関数

local function makeDraggable(dragButton, targetFrame, isIcon)

    local dragging = false

    local dragInput

    local dragStart

    local startPos

    local hasMoved = false

 

    dragButton.InputBegan:Connect(function(input)

        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then

            dragging = true

            hasMoved = false

            dragStart = input.Position

            startPos = targetFrame.Position

            

            setCameraLock(true)

 

            local connection

            connection = input.Changed:Connect(function()

                if input.UserInputState == Enum.UserInputState.End then

                    dragging = false

                    setCameraLock(false)

                    connection:Disconnect()

                    

                    if isIcon and not hasMoved then

                        uiOpen = not uiOpen

                        local mainPanel = dragButton.Parent:FindFirstChild("MainPanel")

                        if mainPanel then

                            mainPanel.Visible = uiOpen

                            if uiOpen then

                                dragButton.BackgroundColor3 = Color3.fromRGB(235, 65, 65)

                                dragButton.Text = "✕"

                            else

                                dragButton.BackgroundColor3 = Color3.fromRGB(35, 115, 255)

                                dragButton.Text = "⚡"

                            end

                        end

                    end

                end

            end)

        end

    end)

 

    dragButton.InputChanged:Connect(function(input)

        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then

            dragInput = input

        end

    end)

 

    UserInputService.InputChanged:Connect(function(input)

        if input == dragInput and dragging then

            local delta = input.Position - dragStart

            

            if delta.Magnitude > 5 then

                hasMoved = true

            end

            

            targetFrame.Position = UDim2.new(

                startPos.X.Scale,

                startPos.X.Offset + delta.X,

                startPos.Y.Scale,

                startPos.Y.Offset + delta.Y

            )

        end

    end)

end

 

local function createUI()

    local playerGui = player:WaitForChild("PlayerGui")

    

    local oldGui = playerGui:FindFirstChild("AdvancedTeleportGui")

    if oldGui then oldGui:Destroy() end

 

    local screenGui = Instance.new("ScreenGui")

    screenGui.Name = "AdvancedTeleportGui"

    screenGui.ResetOnSpawn = false

    screenGui.Parent = playerGui

 

    -- メインアイコン

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

 

    local iconCorner = Instance.new("UICorner")

    iconCorner.CornerRadius = UDim.new(0, 12)

    iconCorner.Parent = iconButton

 

    local iconStroke = Instance.new("UIStroke")

    iconStroke.Color = Color3.fromRGB(100, 180, 255)

    iconStroke.Thickness = 1.5

    iconStroke.Parent = iconButton

 

    -- メインパネル

    local mainPanel = Instance.new("Frame")

    mainPanel.Name = "MainPanel"

    mainPanel.Size = UDim2.new(0, 300, 0, 385)

    mainPanel.AnchorPoint = Vector2.new(0.5, 0.5)

    mainPanel.Position = UDim2.new(0.5, 0, 0.5, 0)

    mainPanel.BackgroundColor3 = Color3.fromRGB(15, 16, 22)

    mainPanel.Visible = false

    mainPanel.Parent = screenGui

 

    local panelCorner = Instance.new("UICorner")

    panelCorner.CornerRadius = UDim.new(0, 10)

    panelCorner.Parent = mainPanel

 

    local panelStroke = Instance.new("UIStroke")

    panelStroke.Color = Color3.fromRGB(40, 45, 60)

    panelStroke.Thickness = 1

    panelStroke.Parent = mainPanel

 

    local gradient = Instance.new("UIGradient")

    gradient.Color = ColorSequence.new({

        ColorSequenceKeypoint.new(0, Color3.fromRGB(25, 27, 38)),

        ColorSequenceKeypoint.new(1, Color3.fromRGB(14, 15, 22))

    })

    gradient.Parent = mainPanel

 

    -- タイトルバー

    local titleBar = Instance.new("Frame")

    titleBar.Name = "TitleBar"

    titleBar.Size = UDim2.new(1, 0, 0, 40)

    titleBar.BackgroundTransparency = 1

    titleBar.Parent = mainPanel

 

    local title = Instance.new("TextLabel")

    title.Name = "Title"

    title.Size = UDim2.new(1, -40, 1, 0)

    title.Position = UDim2.new(0, 12, 0, 0)

    title.BackgroundTransparency = 1

    title.Text = "TELEPORT SYSTEM"

    title.TextColor3 = Color3.fromRGB(255, 198, 92)

    title.TextSize = 13

    title.Font = Enum.Font.GothamBold

    title.TextXAlignment = Enum.TextXAlignment.Left

    title.Parent = titleBar

 

    local closeButton = Instance.new("TextButton")

    closeButton.Name = "CloseButton"

    closeButton.Size = UDim2.new(0, 30, 0, 30)

    closeButton.Position = UDim2.new(1, -35, 0, 5)

    closeButton.BackgroundTransparency = 1

    closeButton.Text = "✕"

    closeButton.TextColor3 = Color3.fromRGB(180, 180, 190)

    closeButton.TextSize = 14

    closeButton.Font = Enum.Font.GothamBold

    closeButton.Parent = titleBar

 

    -- コンテンツフレーム

    local contentFrame = Instance.new("Frame")

    contentFrame.Name = "ContentFrame"

    contentFrame.Size = UDim2.new(1, -24, 1, -50)

    contentFrame.Position = UDim2.new(0, 12, 0, 42)

    contentFrame.BackgroundTransparency = 1

    contentFrame.Parent = mainPanel

 

    local contentLayout = Instance.new("UIListLayout")

    contentLayout.Padding = UDim.new(0, 8)

    contentLayout.SortOrder = Enum.SortOrder.LayoutOrder

    contentLayout.Parent = contentFrame

 

    -- ステータス表示

    local statusLabel = Instance.new("TextLabel")

    statusLabel.Name = "StatusLabel"

    statusLabel.Size = UDim2.new(1, 0, 0, 30)

    statusLabel.BackgroundColor3 = Color3.fromRGB(24, 25, 35)

    statusLabel.TextColor3 = Color3.fromRGB(255, 105, 105)

    statusLabel.Text = "STATUS: IDLE"

    statusLabel.TextSize = 11

    statusLabel.Font = Enum.Font.Code

    statusLabel.BorderSizePixel = 0

    statusLabel.LayoutOrder = 1

    statusLabel.Parent = contentFrame

 

    local statusCorner = Instance.new("UICorner")

    statusCorner.CornerRadius = UDim.new(0, 6)

    statusCorner.Parent = statusLabel

    

    local statusPadding = Instance.new("UIPadding")

    statusPadding.PaddingLeft = UDim.new(0, 10)

    statusPadding.Parent = statusLabel

 

    -- スクロールリスト

    local scrollingFrame = Instance.new("ScrollingFrame")

    scrollingFrame.Name = "ScrollingFrame"

    scrollingFrame.Size = UDim2.new(1, 0, 0, 180)

    scrollingFrame.BackgroundColor3 = Color3.fromRGB(18, 19, 27)

    scrollingFrame.BorderSizePixel = 0

    scrollingFrame.ScrollBarThickness = 4

    scrollingFrame.ScrollBarImageColor3 = Color3.fromRGB(60, 65, 85)

    scrollingFrame.LayoutOrder = 2

    scrollingFrame.Parent = contentFrame

 

    local scrollCorner = Instance.new("UICorner")

    scrollCorner.CornerRadius = UDim.new(0, 6)

    scrollCorner.Parent = scrollingFrame

 

    local listLayout = Instance.new("UIListLayout")

    listLayout.Padding = UDim.new(0, 4)

    listLayout.Parent = scrollingFrame

 

    -- 開始 / 停止 ボタン

    local toggleButton = Instance.new("TextButton")

    toggleButton.Name = "ToggleButton"

    toggleButton.Size = UDim2.new(1, 0, 0, 40)

    toggleButton.BackgroundColor3 = Color3.fromRGB(0, 185, 120)

    toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)

    toggleButton.Text = "START"

    toggleButton.TextSize = 13

    toggleButton.Font = Enum.Font.GothamBold

    toggleButton.BorderSizePixel = 0

    toggleButton.LayoutOrder = 3

    toggleButton.Parent = contentFrame

 

    local toggleCorner = Instance.new("UICorner")

    toggleCorner.CornerRadius = UDim.new(0, 6)

    toggleCorner.Parent = toggleButton

 

    -- 最寄りプレイヤー自動追尾ボタン

    local nearButton = Instance.new("TextButton")

    nearButton.Name = "NearestPlayerButton"

    nearButton.Size = UDim2.new(1, 0, 0, 40)

    nearButton.BackgroundColor3 = Color3.fromRGB(30, 45, 70)

    nearButton.TextColor3 = Color3.fromRGB(130, 215, 255)

    nearButton.Text = "🤖 最寄りのプレイヤーを自動追尾"

    nearButton.TextSize = 12

    nearButton.Font = Enum.Font.GothamBold

    nearButton.BorderSizePixel = 0

    nearButton.LayoutOrder = 4

    nearButton.Parent = contentFrame

 

    local nearCorner = Instance.new("UICorner")

    nearCorner.CornerRadius = UDim.new(0, 6)

    nearCorner.Parent = nearButton

 

    nearButton.MouseButton1Click:Connect(function()

        selectedPlayer = "nearest"

        currentTargetPlayer = nil

        teleportEnabled = false

        toggleButton.BackgroundColor3 = Color3.fromRGB(0, 185, 120)

        toggleButton.Text = "START"

        statusLabel.Text = "SELECTED: AUTOMATIC (NEAREST)"

        statusLabel.TextColor3 = Color3.fromRGB(100, 180, 255)

    end)

 

    makeDraggable(titleBar, mainPanel, false)

    makeDraggable(iconButton, iconButton, true)

 

    closeButton.MouseButton1Click:Connect(function()

        uiOpen = false

        mainPanel.Visible = false

        iconButton.BackgroundColor3 = Color3.fromRGB(35, 115, 255)

        iconButton.Text = "⚡"

    end)

 

    toggleButton.MouseButton1Click:Connect(function()

        if selectedPlayer then

            teleportEnabled = not teleportEnabled

            if teleportEnabled then

                toggleButton.BackgroundColor3 = Color3.fromRGB(235, 65, 65)

                toggleButton.Text = "STOP"

                statusLabel.TextColor3 = Color3.fromRGB(0, 255, 140)

                if selectedPlayer == "nearest" then

                    statusLabel.Text = "TARGET: AUTOMATIC (NEAREST)"

                else

                    statusLabel.Text = "TARGET: " .. selectedPlayer.Name:upper()

                end

            else

                toggleButton.BackgroundColor3 = Color3.fromRGB(0, 185, 120)

                toggleButton.Text = "START"

                statusLabel.TextColor3 = Color3.fromRGB(255, 180, 50)

                statusLabel.Text = "STATUS: PAUSED"

                currentTargetPlayer = nil

            end

        else

            statusLabel.Text = "ERROR: SELECT TARGET FIRST"

            statusLabel.TextColor3 = Color3.fromRGB(255, 65, 65)

        end

    end)

 

    local function updatePlayerList()

        for _, child in pairs(scrollingFrame:GetChildren()) do

            if child:IsA("TextButton") then child:Destroy() end

        end

 

        for _, plr in pairs(Players:GetPlayers()) do

            if plr ~= player then

                local playerButton = Instance.new("TextButton")

                playerButton.Name = plr.Name

                playerButton.Size = UDim2.new(1, -8, 0, 30)

                playerButton.BackgroundColor3 = Color3.fromRGB(24, 25, 35)

                playerButton.TextColor3 = Color3.fromRGB(190, 195, 210)

                playerButton.Text = "👤 " .. plr.Name

                playerButton.TextSize = 11

                playerButton.Font = Enum.Font.Gotham

                playerButton.BorderSizePixel = 0

                playerButton.Parent = scrollingFrame

 

                local btnCorner = Instance.new("UICorner")

                btnCorner.CornerRadius = UDim.new(0, 5)

                btnCorner.Parent = playerButton

 

                playerButton.MouseButton1Click:Connect(function()

                    selectedPlayer = plr

                    currentTargetPlayer = plr

                    teleportEnabled = false

                    toggleButton.BackgroundColor3 = Color3.fromRGB(0, 185, 120)

                    toggleButton.Text = "START"

                    statusLabel.Text = "SELECTED: " .. plr.Name:upper()

                    statusLabel.TextColor3 = Color3.fromRGB(100, 180, 255)

                end)

            end

        end

        scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)

    end

 

    updatePlayerList()

    Players.PlayerAdded:Connect(updatePlayerList)

    Players.PlayerRemoving:Connect(updatePlayerList)

 

    return statusLabel, toggleButton

end

 

local statusLabel, toggleButton = createUI()

 

if teleportConnection then

    teleportConnection:Disconnect()

end

 

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

 

teleportConnection = RunService.RenderStepped:Connect(function()

    if not teleportEnabled then return end

 

    if selectedPlayer == "nearest" then

        local targetValid = false

        if currentTargetPlayer and currentTargetPlayer.Parent and currentTargetPlayer.Character then

            local hum = currentTargetPlayer.Character:FindFirstChildOfClass("Humanoid")

            if hum and hum.Health > 0 then

                targetValid = true

            end

        end

 

        if not targetValid then

            local nextTarget = getNearestPlayer()

            if nextTarget then

                currentTargetPlayer = nextTarget

                statusLabel.Text = "TARGET: AUTO -> " .. nextTarget.Name:upper()

            else

                currentTargetPlayer = nil

                statusLabel.Text = "TARGET: SEARCHING NEAREST..."

            end

        end

    else

        currentTargetPlayer = selectedPlayer

    end

 

    if currentTargetPlayer and currentTargetPlayer.Parent and currentTargetPlayer.Character then

        local targetChar = currentTargetPlayer.Character

        local myChar = player.Character

        

        if targetChar and myChar then

            local targetHrp = targetChar:FindFirstChild("HumanoidRootPart")

            local myCurrentHrp = myChar:FindFirstChild("HumanoidRootPart")

            local targetHum = targetChar:FindFirstChildOfClass("Humanoid")

 

            if selectedPlayer ~= "nearest" and targetHum and targetHum.Health <= 0 then

                teleportEnabled = false

                toggleButton.BackgroundColor3 = Color3.fromRGB(0, 185, 120)

                toggleButton.Text = "START"

                statusLabel.TextColor3 = Color3.fromRGB(255, 65, 65)

                statusLabel.Text = "STATUS: TARGET DIED"

                currentTargetPlayer = nil

                return

            end

 

            if targetHrp and myCurrentHrp and targetHum and targetHum.Health > 0 then

                local lookDirection = targetHrp.CFrame.LookVector

                local backPosition = targetHrp.Position - (lookDirection * CONFIG.TELEPORT_DISTANCE) + Vector3.new(0, CONFIG.TELEPORT_HEIGHT, 0)

                myCurrentHrp.CFrame = CFrame.lookAt(backPosition, targetHrp.Position)

            end

        end

    end

end)

 

game:BindToClose(function()

    if teleportConnection then

        teleportConnection:Disconnect()

    end

end)