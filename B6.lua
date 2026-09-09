-- // カメラ微調整パッド v1.3 - 左右完全修正 + 感度0.025
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui", 10)
local Camera = workspace.CurrentCamera

if PlayerGui:FindFirstChild("CamPadGUI") then PlayerGui.CamPadGUI:Destroy() end

local sensitivity = 0.3
local moveDirection = Vector2.zero
local minimized = false

-- GUI
local ScreenGui = Instance.new("ScreenGui", PlayerGui)
ScreenGui.Name = "CamPadGUI"
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 220, 0, 290)
MainFrame.Position = UDim2.new(0, 20, 0.5, -145)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

local TitleBar = Instance.new("TextLabel", MainFrame)
TitleBar.Size = UDim2.new(1, -35, 0, 28)
TitleBar.Text = "カメラ微調整 v1.3"
TitleBar.TextColor3 = Color3.fromRGB(255, 200, 100)
TitleBar.Font = Enum.Font.Code
TitleBar.TextSize = 12
TitleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 8)

local MinimizeBtn = Instance.new("TextButton", MainFrame)
MinimizeBtn.Size = UDim2.new(0, 30, 0, 28)
MinimizeBtn.Position = UDim2.new(1, -32, 0, 0)
MinimizeBtn.Text = "_"
MinimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
MinimizeBtn.Font = Enum.Font.SourceSansBold
MinimizeBtn.TextSize = 16
MinimizeBtn.BorderSizePixel = 0
MinimizeBtn.ZIndex = 2
Instance.new("UICorner", MinimizeBtn).CornerRadius = UDim.new(0, 8)

local contentElements = {}

-- 十字キー
local function createArrow(text, x, y, w, h, dirX, dirY)
    local btn = Instance.new("TextButton", MainFrame)
    btn.Size = UDim2.new(0, w, 0, h)
    btn.Position = UDim2.new(0, x, 0, y)
    btn.Text = text
    btn.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 20
    btn.BorderSizePixel = 0
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    table.insert(contentElements, btn)

    btn.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
            moveDirection = Vector2.new(dirX, dirY)
        end
    end)
    btn.InputEnded:Connect(function(i)
        moveDirection = Vector2.zero
    end)
end

createArrow("▲", 80, 50, 60, 50, 0, 1)    -- 上
createArrow("▼", 80, 150, 60, 50, 0, -1)   -- 下
createArrow("◀", 15, 100, 60, 50, 1, 0)    -- 左ボタン → 右に回転
createArrow("▶", 145, 100, 60, 50, -1, 0)   -- 右ボタン → 左に回転

-- 感度スライダー
local SliderLabel = Instance.new("TextLabel", MainFrame)
SliderLabel.Size = UDim2.new(0.9, 0, 0, 14)
SliderLabel.Position = UDim2.new(0.05, 0, 0, 215)
SliderLabel.BackgroundTransparency = 1
SliderLabel.Text = "感度: 0.30"
SliderLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
SliderLabel.Font = Enum.Font.Code
SliderLabel.TextSize = 10
SliderLabel.TextXAlignment = Enum.TextXAlignment.Left
table.insert(contentElements, SliderLabel)

local SliderBar = Instance.new("Frame", MainFrame)
SliderBar.Size = UDim2.new(0.9, 0, 0, 5)
SliderBar.Position = UDim2.new(0.05, 0, 0, 232)
SliderBar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
SliderBar.BorderSizePixel = 0
Instance.new("UICorner", SliderBar).CornerRadius = UDim.new(0, 3)
table.insert(contentElements, SliderBar)

local SliderFill = Instance.new("Frame", SliderBar)
SliderFill.Size = UDim2.new(0.282, 0, 1, 0)
SliderFill.BackgroundColor3 = Color3.fromRGB(255, 200, 100)
SliderFill.BorderSizePixel = 0
Instance.new("UICorner", SliderFill).CornerRadius = UDim.new(0, 3)

local SliderBtn = Instance.new("TextButton", SliderBar)
SliderBtn.Size = UDim2.new(0, 14, 0, 14)
SliderBtn.Position = UDim2.new(0.282, -7, -0.5, -4)
SliderBtn.BackgroundColor3 = Color3.fromRGB(255, 200, 100)
SliderBtn.Text = ""
SliderBtn.BorderSizePixel = 0
Instance.new("UICorner", SliderBtn).CornerRadius = UDim.new(1, 0)

local holding = false
SliderBtn.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then holding = true end
end)
UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then holding = false end
end)
UserInputService.InputChanged:Connect(function(i)
    if holding and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
        local p = math.clamp((i.Position.X - SliderBar.AbsolutePosition.X) / SliderBar.AbsoluteSize.X, 0, 1)
        SliderBtn.Position = UDim2.new(p, -7, -0.5, -4)
        SliderFill.Size = UDim2.new(p, 0, 1, 0)
        sensitivity = 0.025 + p * 0.975
        SliderLabel.Text = "感度: " .. string.format("%.3f", sensitivity)
    end
end)

-- リセットボタン
local ResetBtn = Instance.new("TextButton", MainFrame)
ResetBtn.Size = UDim2.new(0.9, 0, 0, 24)
ResetBtn.Position = UDim2.new(0.05, 0, 0, 252)
ResetBtn.Text = "リセット"
ResetBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
ResetBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
ResetBtn.Font = Enum.Font.Code
ResetBtn.TextSize = 11
ResetBtn.BorderSizePixel = 0
Instance.new("UICorner", ResetBtn).CornerRadius = UDim.new(0, 4)
table.insert(contentElements, ResetBtn)
ResetBtn.MouseButton1Click:Connect(function()
    Camera.CFrame = CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + Camera.CFrame.LookVector)
end)

-- 最小化
MinimizeBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        MainFrame.Size = UDim2.new(0, 220, 0, 28)
        MinimizeBtn.Text = "+"
        for _, el in pairs(contentElements) do el.Visible = false end
    else
        MainFrame.Size = UDim2.new(0, 220, 0, 290)
        MinimizeBtn.Text = "_"
        for _, el in pairs(contentElements) do el.Visible = true end
    end
end)

-- ドラッグ
local function makeDraggable(gui, handle)
    local dragging, ds, sp
    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true; ds = i.Position; sp = gui.Position
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - ds
            gui.Position = UDim2.new(0, math.clamp(sp.X.Offset + d.X, 0, Camera.ViewportSize.X - gui.AbsoluteSize.X), 0, math.clamp(sp.Y.Offset + d.Y, 0, Camera.ViewportSize.Y - gui.AbsoluteSize.Y))
        end
    end)
end
makeDraggable(MainFrame, TitleBar)

-- カメラ移動処理
RunService.RenderStepped:Connect(function(dt)
    if moveDirection.Magnitude > 0 then
        local speed = sensitivity * 2 * dt
        local cf = Camera.CFrame
        cf = cf * CFrame.Angles(0, moveDirection.X * speed * 0.5, 0)
        cf = cf * CFrame.Angles(moveDirection.Y * speed * 0.3, 0, 0)
        Camera.CFrame = cf
    end
end)

print("カメラ微調整パッド v1.3 ロード完了")
