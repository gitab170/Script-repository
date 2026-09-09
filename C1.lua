--// ===== サービス =====
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

--// ===== UI (Orion) =====
local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/jadpy/suki/refs/heads/main/orion"))()

--// ===== 設定 =====
local Config = {
    Enabled = false,
    Distance = 8,
    Radius = 2,
    Speed = 25,
    ShootSpeed = 250,
    Count = 10
}

local Toys = {}
local Loop
local Time = 0
local State = 0
local ChargeTime = 0

--// ===== 【ドラッグ移動機能】 =====
local function makeDraggable(gui)
    local dragging, dragInput, dragStart, startPos

    gui.InputBegan:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            dragging = true
            dragStart = input.Position
            startPos = gui.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    gui.InputChanged:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            dragInput = input
        end
    end)

    UIS.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            gui.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

--// ===== ユーティリティ =====
local function getPrimaryPart(model) return model:FindFirstChildWhichIsA("BasePart") end
local function attach(part)
    local bp = Instance.new("BodyPosition")
    bp.Name = "MurasakiBP"; bp.MaxForce = Vector3.new(1,1,1)*1e9; bp.P = 30000; bp.D = 200; bp.Parent = part
    local bg = Instance.new("BodyGyro")
    bg.Name = "MurasakiBG"; bg.MaxTorque = Vector3.new(1,1,1)*1e9; bg.P = 30000; bg.D = 200; bg.Parent = part
    return bp, bg
end

local function clear()
    if Loop then Loop:Disconnect() end
    for _, toy in ipairs(Toys) do
        local part = getPrimaryPart(toy)
        if part then
            if part:FindFirstChild("MurasakiBP") then part.MurasakiBP:Destroy() end
            if part:FindFirstChild("MurasakiBG") then part.MurasakiBG:Destroy() end
        end
    end
    Toys = {}
end

local function getDice()
    local found = {}
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("Model") and v.Name == "DiceBig" then table.insert(found, v) end
    end
    if #found == 0 then return {} end
    while #found < Config.Count do
        local clone = found[1]:Clone(); clone.Parent = workspace; table.insert(found, clone)
    end
    while #found > Config.Count do table.remove(found) end
    return found
end

--// ===== モバイル用ドラッグボタン生成 =====
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MurasakiMobileDraggable"
ScreenGui.Parent = game:GetService("CoreGui")
ScreenGui.Enabled = false

local function createButton(name, pos, color, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 80, 0, 80)
    btn.Position = pos
    btn.BackgroundColor3 = color
    btn.Text = name
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 18
    btn.Active = true
    btn.Parent = ScreenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 15)
    corner.Parent = btn

    makeDraggable(btn)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- 初期位置
createButton("紫 (F)", UDim2.new(0.8, 0, 0.4, 0), Color3.fromRGB(130, 0, 255), function()
    if State == 0 then State = 1 elseif State == 1 then State = 2 ChargeTime = 0 end
end)

createButton("回収 (Q)", UDim2.new(0.8, 0, 0.55, 0), Color3.fromRGB(50, 50, 50), function()
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if root then
        for _, t in ipairs(Toys) do
            local p = getPrimaryPart(t)
            if p then p.CFrame = root.CFrame + Vector3.new(0,5,0) end
        end
        State = 0
    end
end)

--// ===== メインループ =====
local function start()
    clear(); Toys = getDice(); Time = 0
    Loop = RunService.Heartbeat:Connect(function(dt)
        if not Config.Enabled then return end
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        Time += dt
        local right, look, up = root.CFrame.RightVector, root.CFrame.LookVector, root.CFrame.UpVector
        local center = root.Position + up * 3
        if State == 2 then ChargeTime += dt if ChargeTime >= 0.5 then State = 3 end end
        local leftCount = math.floor(Config.Count / 2)
        local rightCount = Config.Count - leftCount
        for i, toy in ipairs(Toys) do
            local part = getPrimaryPart(toy)
            if part then
                local bp = part:FindFirstChild("MurasakiBP") or attach(part)
                local bg = part:FindFirstChild("MurasakiBG")
                for _, v in ipairs(toy:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = false end end
                local isLeft = i <= leftCount
                local angleBase = ((isLeft and (i-1) or (i-leftCount-1)) / (isLeft and leftCount or rightCount)) * math.pi * 2
                if State == 0 then
                    local sideOffset = right * (isLeft and -Config.Distance or Config.Distance)
                    local angle = angleBase + Time * Config.Speed
                    local pos = (center + sideOffset) + (up * math.cos(angle) * Config.Radius + look * math.sin(angle) * Config.Radius)
                    bp.Position = pos; bg.CFrame = CFrame.lookAt(pos, pos + look)
                elseif State == 1 or State == 2 then
                    local s = State == 2 and 2 or 1
                    local front = root.Position + look * 5 + up * 2
                    local angle = angleBase + Time * (Config.Speed * s)
                    local pos = front + (right * math.cos(angle) * Config.Radius + up * math.sin(angle) * Config.Radius)
                    bp.Position = pos; bg.CFrame = CFrame.lookAt(pos, pos + look)
                elseif State == 3 then
                    local move = look * Config.ShootSpeed * dt
                    local pos = part.Position + move
                    bp.Position = pos; bg.CFrame = CFrame.lookAt(pos, pos + look)
                end
            end
        end
    end)
end

--// ===== Orion UI（設定） =====
local Window = OrionLib:MakeWindow({Name = "Murasaki Draggable", HidePremium = true, IntroEnabled = false})
local Tab = Window:MakeTab({Name = "メイン設定", Icon = "rbxassetid://4483345998"})

Tab:AddToggle({Name = "スクリプト有効化", Default = false, Callback = function(v)
    Config.Enabled = v; ScreenGui.Enabled = v; if v then start() else clear() end
end})

Tab:AddSlider({Name = "ダイス数", Min = 1, Max = 30, Default = 10, Callback = function(v) Config.Count = v; if Config.Enabled then Toys = getDice() end end})
Tab:AddSlider({Name = "回転速度", Min = 1, Max = 50, Default = 25, Callback = function(v) Config.Speed = v end})
Tab:AddSlider({Name = "発射スピード", Min = 50, Max = 500, Default = 250, Callback = function(v) Config.ShootSpeed = v end})
Tab:AddSlider({Name = "距離", Min = 3, Max = 15, Default = 8, Callback = function(v) Config.Distance = v end})
Tab:AddSlider({Name = "円の大きさ", Min = 1, Max = 8, Default = 2, Callback = function(v) Config.Radius = v end})

OrionLib:Init()
