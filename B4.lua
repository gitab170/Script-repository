local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
    LocalPlayer = Players.LocalPlayer
end

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui", 10)
local Camera = workspace.CurrentCamera

-- 古いGUIの完全削除
if PlayerGui:FindFirstChild("KanapHubGui") then 
    PlayerGui.KanapHubGui:Destroy() 
end

-- メインGUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "KanapHubGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true 
ScreenGui.Parent = PlayerGui

---------------------------------------------------------
-- メインメニュー
---------------------------------------------------------
local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 420, 0, 340)
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0) 
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Visible = true 
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

-- ドラッグ用のタイトルバー
local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "かなっぷはぶv3！"
Title.TextColor3 = Color3.fromRGB(180, 130, 255)
Title.Font = Enum.Font.Code
Title.TextSize = 14
Title.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
Instance.new("UICorner", Title).CornerRadius = UDim.new(0, 8)

local TabBar = Instance.new("Frame", MainFrame)
TabBar.Size = UDim2.new(0, 90, 1, -40)
TabBar.Position = UDim2.new(0, 5, 0, 35)
TabBar.BackgroundTransparency = 1

local Content = Instance.new("Frame", MainFrame)
Content.Size = UDim2.new(1, -110, 1, -45) 
Content.Position = UDim2.new(0, 100, 0, 35)
Content.BackgroundColor3 = Color3.fromRGB(32, 32, 32)
Content.BorderSizePixel = 0
Instance.new("UICorner", Content).CornerRadius = UDim.new(0, 6)

---------------------------------------------------------
-- ページ作成
---------------------------------------------------------
local function createScrollPage(canvasHeight)
    local sFrame = Instance.new("ScrollingFrame", Content)
    sFrame.Size = UDim2.new(1, 0, 1, 0)
    sFrame.BackgroundTransparency = 1
    sFrame.BorderSizePixel = 0
    sFrame.ScrollBarThickness = 4 
    sFrame.ScrollBarImageColor3 = Color3.fromRGB(180, 130, 255) 
    sFrame.CanvasSize = UDim2.new(0, 0, 0, canvasHeight or 320)
    return sFrame
end

local PageMain = createScrollPage(320)
local PageCombat = createScrollPage(500)
PageCombat.Visible = false

-- タブボタン
local TabMainBtn = Instance.new("TextButton", TabBar)
TabMainBtn.Size = UDim2.new(1, 0, 0, 30)
TabMainBtn.Text = "身体能力強化"
TabMainBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
TabMainBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
TabMainBtn.Font = Enum.Font.SourceSansBold
TabMainBtn.TextSize = 13
Instance.new("UICorner", TabMainBtn).CornerRadius = UDim.new(0, 4)

local TabCombatBtn = Instance.new("TextButton", TabBar)
TabCombatBtn.Size = UDim2.new(1, 0, 0, 30)
TabCombatBtn.Position = UDim2.new(0, 0, 0, 35)
TabCombatBtn.Text = "強い＆クロスヘア"
TabCombatBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
TabCombatBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
TabCombatBtn.Font = Enum.Font.SourceSansBold
TabCombatBtn.TextSize = 11 
Instance.new("UICorner", TabCombatBtn).CornerRadius = UDim.new(0, 4)

TabMainBtn.MouseButton1Click:Connect(function()
    PageMain.Visible = true; PageCombat.Visible = false
    TabMainBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40); TabMainBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    TabCombatBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30); TabCombatBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
end)

TabCombatBtn.MouseButton1Click:Connect(function()
    PageMain.Visible = false; PageCombat.Visible = true
    TabMainBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30); TabMainBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
    TabCombatBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40); TabCombatBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
end)

---------------------------------------------------------
-- パーツ配置
---------------------------------------------------------
local maxSpeedVal = 300 
local speedVal = 50 

local SpeedLabel = Instance.new("TextLabel", PageMain)
SpeedLabel.Size = UDim2.new(0.9, 0, 0, 20)
SpeedLabel.Position = UDim2.new(0.05, 0, 0, 5)
SpeedLabel.BackgroundTransparency = 1
SpeedLabel.Text = "速度調整: " .. tostring(speedVal)
SpeedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
SpeedLabel.Font = Enum.Font.Code
SpeedLabel.TextSize = 12
SpeedLabel.TextXAlignment = Enum.TextXAlignment.Left

local SliderBar = Instance.new("Frame", PageMain)
SliderBar.Size = UDim2.new(0.9, 0, 0, 8)
SliderBar.Position = UDim2.new(0.05, 0, 0, 28)
SliderBar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
SliderBar.BorderSizePixel = 0
Instance.new("UICorner", SliderBar).CornerRadius = UDim.new(0, 4)

local SliderButton = Instance.new("TextButton", SliderBar)
local startPercent = (speedVal - 1) / (maxSpeedVal - 1)
SliderButton.Size = UDim2.new(0, 16, 0, 16)
SliderButton.Position = UDim2.new(startPercent, -8, -0.5, 0)
SliderButton.BackgroundColor3 = Color3.fromRGB(180, 130, 255)
SliderButton.Text = ""
SliderButton.BorderSizePixel = 0
Instance.new("UICorner", SliderButton).CornerRadius = UDim.new(1, 0)

local function createToggle(name, yPos, parentPage)
    local btn = Instance.new("TextButton", parentPage)
    btn.Size = UDim2.new(0.9, 0, 0, 25)
    btn.Position = UDim2.new(0.05, 0, 0, yPos)
    btn.Text = "[ ] " .. name
    btn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    btn.TextColor3 = Color3.fromRGB(200, 100, 255)
    btn.Font = Enum.Font.Code
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.BorderSizePixel = 0
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    return btn
end

local SpeedBtn = createToggle("スピードアップ", 50, PageMain)
local ESPBtn = createToggle("Esp(虹色)", 85, PageMain)
local GhostBtn = createToggle("ノークリップ (壁抜け)", 120, PageMain)
local JumpBtn = createToggle("無限ジャンプ", 155, PageMain)

local AimBtn = createToggle("オートエイム", 10, PageCombat)
local LoopTpBtn = createToggle("背後ワープ！", 45, PageCombat)
LoopTpBtn.TextColor3 = Color3.fromRGB(255, 215, 0)

local RandomWarpBtn = createToggle("相手の周りにランダムワープ", 80, PageCombat)
RandomWarpBtn.TextColor3 = Color3.fromRGB(0, 255, 255)

local AdvancedESPBtn = createToggle("相手のHPを表示", 115, PageCombat)
AdvancedESPBtn.TextColor3 = Color3.fromRGB(0, 255, 150)

local CrosshairBtn = createToggle("かっこいいクロスヘア", 150, PageCombat)
CrosshairBtn.TextColor3 = Color3.fromRGB(255, 0, 128) 

-- 数字の意味がわかるように左側に説明ラベルを置く関数
local function createInputWithLabel(yPos, labelText, defaultText)
    local label = Instance.new("TextLabel", PageCombat)
    label.Size = UDim2.new(0.55, 0, 0, 25)
    label.Position = UDim2.new(0.05, 0, 0, yPos)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = Color3.fromRGB(220, 220, 220)
    label.Font = Enum.Font.Code
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left

    local box = Instance.new("TextBox", PageCombat)
    box.Size = UDim2.new(0.32, 0, 0, 25)
    box.Position = UDim2.new(0.63, 0, 0, yPos) 
    box.Text = defaultText
    box.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    box.TextColor3 = Color3.fromRGB(255, 255, 255)
    box.Font = Enum.Font.Code
    box.TextSize = 12
    box.BorderSizePixel = 0
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 4)
    return box
end

local BackWaitBox = createInputWithLabel(185, "背後間隔(秒)", "0.1")
local DistanceInput = createInputWithLabel(220, "背後ワープ距離", "3")
local HeightInput = createInputWithLabel(255, "上にワープ (高さ)", "0")
local RandWaitBox = createInputWithLabel(290, "乱数ワープ間隔(秒)", "2")
local MinRangeBox = createInputWithLabel(325, "最低乱数スタッド", "20")
local RangeBox = createInputWithLabel(360, "最大乱数スタッド", "60")
local MaxTargetDistBox = createInputWithLabel(395, "最大ターゲット距離", "1000")

---------------------------------------------------------
-- 猫アイコン
---------------------------------------------------------
local CatBtn = Instance.new("ImageButton", ScreenGui)
CatBtn.Size = UDim2.new(0, 55, 0, 55)
CatBtn.AnchorPoint = Vector2.new(0.5, 0)
CatBtn.Position = UDim2.new(0.5, 0, 0, 45) 
CatBtn.Image = "rbxassetid://10425026214"
CatBtn.BackgroundTransparency = 0 
CatBtn.BorderSizePixel = 0
CatBtn.Active = true
Instance.new("UICorner", CatBtn).CornerRadius = UDim.new(1, 0)

CatBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

---------------------------------------------------------
-- スライダーロジック
---------------------------------------------------------
local holdingSlider = false

local function moveSlider(input)
    local relativeX = input.Position.X - SliderBar.AbsolutePosition.X
    local percentage = math.clamp(relativeX / SliderBar.AbsoluteSize.X, 0, 1)
    SliderButton.Position = UDim2.new(percentage, -8, -0.5, 0)
    
    speedVal = math.floor(1 + (percentage * (maxSpeedVal - 1)))
    SpeedLabel.Text = "速度調整: " .. tostring(speedVal)
end

SliderButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        holdingSlider = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        holdingSlider = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if holdingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        moveSlider(input)
    end
end)

---------------------------------------------------------
-- ドラッグ移動ロジック
---------------------------------------------------------
local function makeDraggable(guiObject, dragHandle)
    local dragging, dragInput, dragStart, startPos
    
    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = guiObject.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    dragHandle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            guiObject.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

makeDraggable(MainFrame, Title)
makeDraggable(CatBtn, CatBtn)

---------------------------------------------------------
-- クロスヘア構築
---------------------------------------------------------
local CrosshairContainer = Instance.new("Frame", ScreenGui)
CrosshairContainer.AnchorPoint = Vector2.new(0.5, 0.5)
CrosshairContainer.Size = UDim2.new(0, 150, 0, 150) 
CrosshairContainer.Position = UDim2.new(0.5, 0, 0.5, 0) 
CrosshairContainer.BackgroundTransparency = 1
CrosshairContainer.Visible = false

local CenterDot = Instance.new("Frame", CrosshairContainer)
CenterDot.AnchorPoint = Vector2.new(0.5, 0.5)
CenterDot.Size = UDim2.new(0, 6, 0, 6)
CenterDot.Position = UDim2.new(0.5, 0, 0.5, 0) 
CenterDot.BorderSizePixel = 0
Instance.new("UICorner", CenterDot).CornerRadius = UDim.new(1, 0)

local InnerRotator = Instance.new("Frame", CrosshairContainer)
InnerRotator.Size = UDim2.new(1, 0, 1, 0)
InnerRotator.BackgroundTransparency = 1

local innerLines = {}
local innerPositions = {
    {Size = UDim2.new(0, 2, 0, 14), Pos = UDim2.new(0.5, -1, 0.5, -22)}, 
    {Size = UDim2.new(0, 2, 0, 14), Pos = UDim2.new(0.5, -1, 0.5, 8)},   
    {Size = UDim2.new(0, 14, 0, 2), Pos = UDim2.new(0.5, -22, 0.5, -1)}, 
    {Size = UDim2.new(0, 14, 0, 2), Pos = UDim2.new(0.5, 8, 0.5, -1)}    
}
for _, config in ipairs(innerPositions) do
    local l = Instance.new("Frame", InnerRotator)
    l.Size = config.Size
    l.Position = config.Pos
    l.BorderSizePixel = 0
    Instance.new("UICorner", l).CornerRadius = UDim.new(0, 1) 
    table.insert(innerLines, l)
end

local MiddleRotator = Instance.new("Frame", CrosshairContainer)
MiddleRotator.Size = UDim2.new(1, 0, 1, 0)
MiddleRotator.BackgroundTransparency = 1

local middleParts = {}
local middlePositions = {
    {Size = UDim2.new(0, 10, 0, 2), Pos = UDim2.new(0.5, -35, 0.5, -35)}, {Size = UDim2.new(0, 2, 0, 10), Pos = UDim2.new(0.5, -35, 0.5, -35)},
    {Size = UDim2.new(0, 10, 0, 2), Pos = UDim2.new(0.5, 25, 0.5, -35)},  {Size = UDim2.new(0, 2, 0, 10), Pos = UDim2.new(0.5, 33, 0.5, -35)},
    {Size = UDim2.new(0, 10, 0, 2), Pos = UDim2.new(0.5, -35, 0.5, 33)},  {Size = UDim2.new(0, 2, 0, 10), Pos = UDim2.new(0.5, -35, 0.5, 25)},
    {Size = UDim2.new(0, 10, 0, 2), Pos = UDim2.new(0.5, 25, 0.5, 33)},  {Size = UDim2.new(0, 2, 0, 10), Pos = UDim2.new(0.5, 33, 0.5, 25)}
}
for _, config in ipairs(middlePositions) do
    local p = Instance.new("Frame", MiddleRotator)
    p.Size = config.Size
    p.Position = config.Pos
    p.BorderSizePixel = 0
    Instance.new("UICorner", p).CornerRadius = UDim.new(0, 1)
    table.insert(middleParts, p)
end

local OuterRotator = Instance.new("Frame", CrosshairContainer)
OuterRotator.Size = UDim2.new(1, 0, 1, 0)
OuterRotator.BackgroundTransparency = 1

local outerParts = {}
local outerPositions = {
    {Size = UDim2.new(0, 28, 0, 3), Pos = UDim2.new(0.5, -14, 0.5, -55)}, 
    {Size = UDim2.new(0, 28, 0, 3), Pos = UDim2.new(0.5, -14, 0.5, 52)},  
    {Size = UDim2.new(0, 3, 0, 28), Pos = UDim2.new(0.5, -55, 0.5, -14)}, 
    {Size = UDim2.new(0, 3, 0, 28), Pos = UDim2.new(0.5, 52, 0.5, -14)}   
}
for _, config in ipairs(outerPositions) do
    local p = Instance.new("Frame", OuterRotator)
    p.Size = config.Size
    p.Position = config.Pos
    p.BorderSizePixel = 0
    Instance.new("UICorner", p).CornerRadius = UDim.new(0, 1.5)
    table.insert(outerParts, p)
end

---------------------------------------------------------
-- ロジック用変数と関数
---------------------------------------------------------
local enabled = {esp = false, advEsp = false, ghost = false, jump = false, speed = false, aim = false, loopTp = false, randomWarp = false, crosshair = false}
local tickCount = 0
local lastBackWarp, lastRandomWarp = 0, 0

local function isVisible(targetPart, myCharacter)
    local castParams = RaycastParams.new()
    castParams.FilterType = Enum.RaycastFilterType.Exclude
    castParams.FilterDescendantsInstances = {myCharacter, targetPart.Parent}
    castParams.IgnoreWater = true
    
    local rayOrigin = Camera.CFrame.Position
    local rayDirection = targetPart.Position - rayOrigin
    local raycastResult = workspace:Raycast(rayOrigin, rayDirection, castParams)
    
    return raycastResult == nil
end

local function getClosestEnemy()
    local closest, minDist = nil, math.huge
    local myCharacter = LocalPlayer.Character
    if not myCharacter or not myCharacter:FindFirstChild("HumanoidRootPart") then return nil end
    local myPos = myCharacter.HumanoidRootPart.Position
    local maxTargetDist = tonumber(MaxTargetDistBox.Text) or 1000

    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") and p.Character:FindFirstChild("Humanoid") then
            local isEnemy = (not LocalPlayer.Team or not p.Team or LocalPlayer.Team ~= p.Team)
            if isEnemy and p.Character.Humanoid.Health > 0 then
                local d = (p.Character.Head.Position - myPos).Magnitude
                if d < maxTargetDist and d < minDist then
                    if isVisible(p.Character.Head, myCharacter) then
                        minDist = d
                        closest = p.Character
                    end
                end
            end
        end
    end
    
    if not closest then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") and p.Character:FindFirstChild("Humanoid") then
                local isEnemy = (not LocalPlayer.Team or not p.Team or LocalPlayer.Team ~= p.Team)
                if isEnemy and p.Character.Humanoid.Health > 0 then
                    local d = (p.Character.Head.Position - myPos).Magnitude
                    if d < maxTargetDist and d < minDist then
                        minDist = d
                        closest = p.Character
                    end
                end
            end
        end
    end
    return closest
end

local function updateHpTracker(player, character, myPos, currentRainbowColor)
    local head = character:FindFirstChild("Head")
    local humanoid = character:FindFirstChild("Humanoid")
    if not head or not humanoid then return end
    
    local bgui = head:FindFirstChild("KanapHpTracker")
    local isEnemy = (not LocalPlayer.Team or not player.Team or LocalPlayer.Team ~= player.Team)
    local distance = (head.Position - myPos).Magnitude
    local maxTargetDist = tonumber(MaxTargetDistBox.Text) or 1000
    local shouldShow = enabled.advEsp and isEnemy and humanoid.Health > 0 and distance < maxTargetDist

    if shouldShow then
        if not bgui then
            bgui = Instance.new("BillboardGui")
            bgui.Name = "KanapHpTracker"
            bgui.Size = UDim2.new(0, 100, 0, 30)
            bgui.AlwaysOnTop = true
            bgui.ExtentsOffset = Vector3.new(0, 2.5, 0)
            bgui.Parent = head
            
            local textLabel = Instance.new("TextLabel", bgui)
            textLabel.Name = "HPText"
            textLabel.Size = UDim2.new(1, 0, 1, 0)
            textLabel.BackgroundTransparency = 1
            textLabel.TextStrokeTransparency = 0
            textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
            textLabel.Font = Enum.Font.SourceSansBold
            textLabel.TextSize = 16
        end
        bgui.HPText.Text = string.format("HP: %d", math.floor(humanoid.Health))
        bgui.HPText.TextColor3 = currentRainbowColor
    else
        if bgui then bgui:Destroy() end
    end
end

---------------------------------------------------------
-- メインループ
---------------------------------------------------------
RunService.RenderStepped:Connect(function()
    local targetChar = getClosestEnemy()
    local myCharacter = LocalPlayer.Character
    local myRoot = (myCharacter and myCharacter:FindFirstChild("HumanoidRootPart")) and myCharacter.HumanoidRootPart or nil
    local myPos = myRoot and myRoot.Position or Vector3.new(0,0,0)
    
    tickCount = tickCount + 1
    local textHue = (tickCount % 120) / 120
    local sharedRainbowColor = Color3.fromHSV(textHue, 1, 1)

    CatBtn.BackgroundColor3 = sharedRainbowColor

    -- 背後ワープ処理
    if enabled.loopTp and targetChar and targetChar:FindFirstChild("HumanoidRootPart") and myRoot then
        if tick() - lastBackWarp > (tonumber(BackWaitBox.Text) or 0.1) then
            lastBackWarp = tick()
            local enemyRoot = targetChar.HumanoidRootPart
            local currentDist = tonumber(DistanceInput.Text) or 3
            local currentHeight = tonumber(HeightInput.Text) or 0
            myRoot.CFrame = enemyRoot.CFrame * CFrame.new(0, currentHeight, currentDist)
        end
    end

    -- ランダムワープ処理
    if enabled.randomWarp and targetChar and targetChar:FindFirstChild("HumanoidRootPart") and myRoot then
        if tick() - lastRandomWarp > (tonumber(RandWaitBox.Text) or 2) then
            lastRandomWarp = tick()
            local minR = tonumber(MinRangeBox.Text) or 20
            local maxR = tonumber(RangeBox.Text) or 60
            if minR > maxR then minR, maxR = maxR, minR end

            local angle = math.random() * math.pi * 2
            local distance = math.random(minR, maxR)
            local offsetX = math.cos(angle) * distance
            local offsetZ = math.sin(angle) * distance
            local offsetY = math.random(0, math.floor(maxR / 2))

            local randomOffset = Vector3.new(offsetX, offsetY, offsetZ)
            myRoot.CFrame = targetChar.HumanoidRootPart.CFrame + randomOffset
        end
    end

    -- スマートオートエイム
    if enabled.aim and targetChar and targetChar:FindFirstChild("Head") then
        Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, targetChar.Head.Position)
    end
    
    -- ESP & HPトラッカー
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local isEnemy = (not LocalPlayer.Team or not p.Team or LocalPlayer.Team ~= p.Team)
            
            if p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 and enabled.esp and isEnemy then
                local h = p.Character:FindFirstChild("ESPHighlight")
                if not h then 
                    h = Instance.new("Highlight", p.Character)
                    h.Name = "ESPHighlight"
                    h.FillTransparency = 0.5 
                    h.OutlineTransparency = 0
                end
                h.FillColor = sharedRainbowColor
                h.OutlineColor = sharedRainbowColor
            else
                local h = p.Character:FindFirstChild("ESPHighlight")
                if h then h:Destroy() end
            end
            updateHpTracker(p, p.Character, myPos, sharedRainbowColor)
        end
    end
    
    -- ノークリップ（壁抜け）
    if enabled.ghost and myCharacter then
        for _, v in pairs(myCharacter:GetDescendants()) do 
            if v:IsA("BasePart") and v.CanCollide then 
                v.CanCollide = false 
            end 
        end
    end

    -- クロスヘア制御（いつでも常時表示）
    if enabled.crosshair then
        CrosshairContainer.Visible = true
        local isLocking = targetChar and (enabled.loopTp or enabled.randomWarp or enabled.aim)
        local colorCore, colorLayer2, colorLayer3, colorLayer4
        
        if isLocking then
            local alertPulse = math.abs(math.sin(tickCount * 0.3))
            colorCore   = Color3.fromRGB(255, 0, 0)
            colorLayer2 = Color3.fromRGB(255, 50, 50)
            colorLayer3 = Color3.fromRGB(255, 200, 0)
            colorLayer4 = Color3.fromHSV(0, 1, 0.4 + (alertPulse * 0.6))
        else
            local hue1 = (tickCount % 180) / 180
            local hue2 = ((tickCount + 45) % 180) / 180
            local hue3 = ((tickCount + 90) % 180) / 180
            colorCore   = Color3.fromHSV(hue1, 0.5, 1)
            colorLayer2 = sharedRainbowColor
            colorLayer3 = Color3.fromHSV(hue2, 0.8, 1)
            colorLayer4 = Color3.fromHSV(hue3, 1, 1)
        end

        CenterDot.BackgroundColor3 = colorCore
        for _, line in ipairs(innerLines) do line.BackgroundColor3 = colorLayer2 end
        for _, part in ipairs(middleParts) do part.BackgroundColor3 = colorLayer3 end
        for _, part in ipairs(outerParts) do part.BackgroundColor3 = colorLayer4 end

        local baseSpeed = isLocking and 12 or 2.5
        InnerRotator.Rotation  = (InnerRotator.Rotation + baseSpeed) % 360
        MiddleRotator.Rotation = (MiddleRotator.Rotation - (baseSpeed * 0.4)) % 360
        OuterRotator.Rotation  = (OuterRotator.Rotation + (baseSpeed * 0.2)) % 360

        local pulseRange = isLocking and 12 or 6
        local pulseSpeed = isLocking and 0.3 or 0.12
        local pulse = math.sin(tickCount * pulseSpeed) * pulseRange
        
        if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
            CrosshairContainer.Size = UDim2.new(0, 90 + pulse, 0, 90 + pulse)
            InnerRotator.Rotation = (InnerRotator.Rotation + 4) % 360
        else
            CrosshairContainer.Size = UDim2.new(0, 140 + pulse, 0, 140 + pulse)
        end
    else
        CrosshairContainer.Visible = false
    end
end)

RunService.Heartbeat:Connect(function(dt)
    if enabled.speed and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.HumanoidRootPart.CFrame += LocalPlayer.Character.Humanoid.MoveDirection * (speedVal * dt)
    end
end)

UserInputService.JumpRequest:Connect(function() 
    if enabled.jump and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then 
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping") 
    end 
end)

---------------------------------------------------------
-- イベント紐付け
---------------------------------------------------------
SpeedBtn.MouseButton1Click:Connect(function() enabled.speed = not enabled.speed; SpeedBtn.Text = enabled.speed and "[X] スピードアップ" or "[ ] スピードアップ" end)
ESPBtn.MouseButton1Click:Connect(function() enabled.esp = not enabled.esp; ESPBtn.Text = enabled.esp and "[X] Esp(虹色)" or "[ ] Esp(虹色)" end)
GhostBtn.MouseButton1Click:Connect(function() enabled.ghost = not enabled.ghost; GhostBtn.Text = enabled.ghost and "[X] ノークリップ (壁抜け)" or "[ ] ノークリップ (壁抜け)" end)
JumpBtn.MouseButton1Click:Connect(function() enabled.jump = not enabled.jump; JumpBtn.Text = enabled.jump and "[X] 無限ジャンプ" or "[ ] 無限ジャンプ" end)
AimBtn.MouseButton1Click:Connect(function() enabled.aim = not enabled.aim; AimBtn.Text = enabled.aim and "[X] オートエイム" or "[ ] オートエイム" end)

AdvancedESPBtn.MouseButton1Click:Connect(function() enabled.advEsp = not enabled.advEsp; AdvancedESPBtn.Text = enabled.advEsp and "[X] 相手のHPを表示" or "[ ] 相手のHPを表示" end)
CrosshairBtn.MouseButton1Click:Connect(function() enabled.crosshair = not enabled.crosshair; CrosshairBtn.Text = enabled.crosshair and "[X] かっこいいクロスヘア" or "[ ] かっこいいクロスヘア" end)

LoopTpBtn.MouseButton1Click:Connect(function()
    enabled.loopTp = not enabled.loopTp
    LoopTpBtn.Text = enabled.loopTp and "[X] 背後ワープ！" or "[ ] 背後ワープ！"
    if enabled.loopTp then
        enabled.ghost = true
        GhostBtn.Text = "[X] ノークリップ (壁抜け)"
    end
end)

RandomWarpBtn.MouseButton1Click:Connect(function()
    enabled.randomWarp = not enabled.randomWarp
    RandomWarpBtn.Text = enabled.randomWarp and "[X] 相手の周りにランダムワープ" or "[ ] 相手の周りにランダムワープ"
    if enabled.randomWarp then
        enabled.ghost = true
        GhostBtn.Text = "[X] ノークリップ (壁抜け)"
    end
end)
