 -- こっちみんな
 -- その心笑ってるね？今笑ってたでしょ、あついでにスキッドしたらお前の住所特定してピザハーフ2個頼んでやる、ちょっと新しくなったよ！
 -- コードか仕組み盗んだら翌日着払いで照り焼きチキンと二倍チーズが家に届く呪いをかける
 -- 君はスキッドしてないよね？えー…聞かないというならもう一枚ピザ送る、ピザ食べたい
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/katnaa-debug/SolarisUI/refs/heads/main/Library1.lua"))()
local P = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local WS = game:GetService("Workspace")
local LP = P.LocalPlayer

local lagActive = false
local lagThread = nil
local lagStrength = 5
local lagSpeed = 3
local lagRange = 500000000
local lagHeight = 0
local targetLagActive = false
local targetLagThread = nil
local selectedTarget = nil
local targetRange = 100
local targetHeightMin = 50
local targetHeightMax = 200

local function HRP()
    return LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
end

local function notify(title, content)
    Library:Notify({Title = title, Content = content, Duration = 2})
end

local function getPlayerList()
    local list = {}
    for _, p in pairs(P:GetPlayers()) do if p ~= LP then table.insert(list, p.DisplayName .. " (@" .. p.Name .. ")") end end
    if #list == 0 then table.insert(list, "(なし)") end
    return list
end

local function startLag()
    if lagActive then notify("全体ラグ", "すでに発動中") return end
    lagActive = true
    local GE = RS:FindFirstChild("GrabEvents")
    if not GE then notify("エラー", "GrabEventsなし"); lagActive = false; return end
    local cl = GE:FindFirstChild("CreateGrabLine")
    if not cl then notify("エラー", "CreateGrabLineなし"); lagActive = false; return end
    lagThread = task.spawn(function()
        while lagActive do
            local sp = WS:FindFirstChild("SpawnLocation") or HRP()
            if sp then
                for _ = 1, lagStrength do
                    pcall(function() cl:FireServer(sp, CFrame.new(math.random(-lagRange, lagRange), lagHeight, math.random(-lagRange, lagRange))) end)
                end
            end
            task.wait(0.01 * (11 - lagSpeed))
        end
    end)
    notify("全体ラグ", "発動")
end

local function stopLag()
    if not lagActive then return end
    lagActive = false
    if lagThread then task.cancel(lagThread); lagThread = nil end
    notify("全体ラグ", "停止")
end

local function startTargetLag()
    if targetLagActive then notify("ターゲットラグ", "すでに発動中") return end
    if not selectedTarget then notify("エラー", "ターゲット未選択") return end
    local target = P:FindFirstChild(selectedTarget)
    if not target then notify("エラー", "ターゲット不在"); return end
    if not target.Character then notify("エラー", "キャラなし"); return end

    targetLagActive = true
    local GE = RS:FindFirstChild("GrabEvents")
    if not GE then targetLagActive = false; return end
    local cl = GE:FindFirstChild("CreateGrabLine")
    local so = GE:FindFirstChild("SetNetworkOwner")
    if not cl then targetLagActive = false; return end

    targetLagThread = task.spawn(function()
        while targetLagActive do
            local t = P:FindFirstChild(selectedTarget)
            if not t or not t.Character then targetLagActive = false; break end
            local hrp = t.Character:FindFirstChild("HumanoidRootPart")
            local hum = t.Character:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 then
                if so then pcall(function() so:FireServer(hrp, hrp.CFrame) end) end
                for _ = 1, lagStrength do
                    pcall(function() cl:FireServer(hrp, CFrame.new(math.random(-targetRange, targetRange), math.random(targetHeightMin, targetHeightMax), math.random(-targetRange, targetRange))) end)
                end
            end
            task.wait(0.01 * (11 - lagSpeed))
        end
        stopTargetLag()
        notify("ターゲットラグ", "対象が退出したため停止")
    end)
    notify("ターゲットラグ", selectedTarget .. " を集中攻撃")
end

local function stopTargetLag()
    if not targetLagActive then return end
    targetLagActive = false
    if targetLagThread then task.cancel(targetLagThread); targetLagThread = nil end
    notify("ターゲットラグ", "停止")
end

local function stopAll()
    stopLag(); stopTargetLag()
    notify("全停止", "すべて解除")
end

P.PlayerRemoving:Connect(function(p)
    if selectedTarget == p.Name then stopTargetLag(); notify("退出", p.Name .. " が退出したため停止") end
end)

local Window = Library:CreateWindow({
    Title = "なべHub FTAPラインラグシステム v1.2", ToggleKey = Enum.KeyCode.RightShift, Transparency = 0.15,
    ShowWatermark = {Enabled = true, Title = true, FPS = true, Ping = true},
    AutoSave = true, ConfigFolder = "NabeHub_LineLag",
    Theme = {Main = Color3.fromRGB(25, 25, 30), Second = Color3.fromRGB(35, 35, 40), Accent = Color3.fromRGB(255, 100, 80), ElementAccent = Color3.fromRGB(255, 130, 100), Text = Color3.fromRGB(240, 240, 240), TextDark = Color3.fromRGB(160, 160, 160), Error = Color3.fromRGB(255, 80, 80), GradientStart = Color3.fromRGB(255, 100, 80), GradientEnd = Color3.fromRGB(200, 50, 30), Transparency = 0.15, Font = "Gotham", UiScale = 1.0}
})

local Tab = Window:CreateTab("メイン", true)

local AllBlock = Tab:CreateBlock({Name = "全体ラグ", Side = "Left"})
AllBlock:CreateButton({Name = "発動", Callback = startLag})
AllBlock:CreateButton({Name = "停止", Callback = stopLag})

local TargetBlock = Tab:CreateBlock({Name = "ターゲットラグ", Side = "Right"})
local targetDropdown = TargetBlock:CreateDropdown({Name = "選択", Flag = "TGT", Items = getPlayerList(), Default = 1, Callback = function(v)
    if v and v ~= "(なし)" then selectedTarget = v:match("%(@(.*)%)") end
end})
TargetBlock:CreateButton({Name = "発動", Callback = startTargetLag})
TargetBlock:CreateButton({Name = "停止", Callback = stopTargetLag})
TargetBlock:CreateButton({Name = "リスト更新", Callback = function() targetDropdown:Refresh(getPlayerList(), true) end})

local SettingsBlock = Tab:CreateBlock({Name = "全体設定", Side = "Left"})
SettingsBlock:CreateSlider({Name = "強さ", Flag = "STR", Min = 1, Max = 30, Default = 5, Callback = function(v) lagStrength = v end})
SettingsBlock:CreateSlider({Name = "速度", Flag = "SPD", Min = 1, Max = 10, Default = 3, Callback = function(v) lagSpeed = v end})
SettingsBlock:CreateSlider({Name = "範囲", Flag = "ARange", Min = 1000, Max = 1000000000, Default = 500000000, Callback = function(v) lagRange = v end})
SettingsBlock:CreateSlider({Name = "高さ", Flag = "AHeight", Min = -500, Max = 1000, Default = 0, Callback = function(v) lagHeight = v end})

local TargetSettingsBlock = Tab:CreateBlock({Name = "ターゲット設定", Side = "Right"})
TargetSettingsBlock:CreateSlider({Name = "範囲", Flag = "TRange", Min = 10, Max = 500, Default = 100, Callback = function(v) targetRange = v end})
TargetSettingsBlock:CreateSlider({Name = "最低高さ", Flag = "THMin", Min = 0, Max = 300, Default = 50, Callback = function(v) targetHeightMin = v end})
TargetSettingsBlock:CreateSlider({Name = "最高高さ", Flag = "THMax", Min = 10, Max = 500, Default = 200, Callback = function(v) targetHeightMax = v end})

local MiscBlock = Tab:CreateBlock({Name = "制御", Side = "Left"})
MiscBlock:CreateButton({Name = "全停止", Callback = stopAll})
MiscBlock:CreateToggle({Name = "強制三人称視点", Flag = "TPV", Default = false, Callback = function(v)
    if v then LP.CameraMode = Enum.CameraMode.Classic; LP.CameraMaxZoomDistance = 10000; LP.CameraMinZoomDistance = 0
    else LP.CameraMode = Enum.CameraMode.LockFirstPerson end
end})

Library:Notify({Title = "なべHub FTAPラインラグシステム v1.2", Content = "ロード完了", Duration = 3})
