-- LagKick UI - 既存機能維持 + ラインラグ変更 (Obsidian Library)
local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

Library.ForceCheckbox = false

local Window = Library:CreateWindow({
    Title = "LagKick",
    Footer = "Destroy Server Tool",
    NotifySide = "Right",
    ShowCustomCursor = true,
})

local Tabs = {
    Main = Window:AddTab("LagKick", "clock"),
    ["UI Settings"] = Window:AddTab("UI Settings", "settings"),
}

-- =====================================================
-- LagKick コア機能 (エフェクトなし)
-- =====================================================
local LagKick = {
    Enabled = false,
    SelectedHeight = "Spawn",
    Running = false,
    LineLagEnabled = false,
    LineLagThread = nil,
}

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local GrabEvents = ReplicatedStorage:FindFirstChild("GrabEvents")

local function getAllPlayers()
    local players = {}
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            table.insert(players, plr)
        end
    end
    return players
end

local function spamOwnership(hrp)
    if not GrabEvents then return end
    local setOwner = GrabEvents:FindFirstChild("SetNetworkOwner")
    if setOwner and hrp then
        pcall(function() setOwner:FireServer(hrp, hrp.CFrame) end)
    end
end

local function teleportToPlayer(myHrp, targetHrp)
    if not myHrp or not targetHrp then return end
    pcall(function()
        myHrp.CFrame = targetHrp.CFrame * CFrame.new(0, 5, 5)
        myHrp.AssemblyLinearVelocity = Vector3.zero
    end)
end

local function destroyLineOnPlayer(hrp)
    if not GrabEvents then return end
    local createLine = GrabEvents:FindFirstChild("CreateGrabLine")
    local destroyLine = GrabEvents:FindFirstChild("DestroyGrabLine")
    if not createLine or not destroyLine then return end
    pcall(function()
        createLine:FireServer(hrp, CFrame.new(0, 1e9, 0))
        task.wait()
        destroyLine:FireServer(hrp)
    end)
end

-- =====================================================
-- ★ ラインラグ機能 (軽量安定版に変更) ★
-- =====================================================
local lineLagThread = nil
local lineLagEnabled = false

-- ラグ生成関数 (軽量安定版)
local function startLineLag()
    if lineLagEnabled then return end
    lineLagEnabled = true
    lineLagThread = task.spawn(function()
        if not GrabEvents then return end
        local createLine = GrabEvents:FindFirstChild("CreateGrabLine")
        if not createLine then
            Library:Notify({ Title = "Error", Description = "CreateGrabLine not found", Time = 3 })
            return
        end

        local packetCount = _G.LineLagPacketCount or 10

        while lineLagEnabled do
            local target = Workspace:FindFirstChild("SpawnLocation") 
                or Workspace:FindFirstChild("Spawn") 
                or (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart"))
            if target then
                for i = 1, packetCount do 
                    local randomX = math.random(-1e9, 1e9)
                    local randomZ = math.random(-1e9, 1e9)
                    pcall(function() 
                        createLine:FireServer(target, CFrame.new(randomX, 0, randomZ)) 
                    end)
                end
            end
            task.wait(0.05) 
        end
    end)
end

local function stopLineLag()
    lineLagEnabled = false
    if lineLagThread then 
        task.cancel(lineLagThread) 
        lineLagThread = nil
    end
end

-- デフォルト値を設定
_G.LineLagPacketCount = 10

-- =====================================================
-- UI 構築
-- =====================================================
local LagKickGroup = Tabs.Main:AddLeftGroupbox("LagKick Control", "clock")

-- 高さ設定ドロップダウン
LagKickGroup:AddDropdown("HeightMode", {
    Values = { "Spawn (Ground)", "Heaven" },
    Default = 1,
    Text = "Height Mode",
    Callback = function(Value)
        LagKick.SelectedHeight = (Value == "Heaven") and "Heaven" or "Spawn"
    end,
})

-- Destroy Server ボタン (エフェクトなし)
LagKickGroup:AddButton({
    Text = "Destroy Server",
    Tooltip = "全てのプレイヤーを円形に配置し、サーバーにラグを発生させます",
    DoubleClick = false,
    Risky = true,
    Func = function()
        if LagKick.Running then
            Library:Notify({ Title = "Already Running", Description = "Destroy Server is already in progress", Time = 3 })
            return
        end

        LagKick.Running = true
        Library:Notify({ Title = "", Description = "Destroy Server Started!", Time = 2 })

        task.spawn(function()
            local height = (LagKick.SelectedHeight == "Heaven") and 1e9 or 35

            -- ★ ラインラグ開始 (軽量安定版) ★
            startLineLag()
            task.wait(1)

            -- 全プレイヤー取得
            local players = getAllPlayers()
            if #players == 0 then
                stopLineLag()
                LagKick.Running = false
                Library:Notify({ Title = "Error", Description = "No players found", Time = 3 })
                return
            end

            Library:Notify({ Title = "Target", Description = #players .. " players found", Time = 2 })

            local myChar = LocalPlayer.Character
            local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
            if not myHrp then
                stopLineLag()
                LagKick.Running = false
                return
            end

            -- 有効なプレイヤーを収集
            local playerData = {}
            for _, plr in ipairs(players) do
                local char = plr.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    table.insert(playerData, { player = plr, hrp = hrp })
                end
            end

            -- 各プレイヤーにテレポートしてNetworkOwnerを主張
            for _, data in ipairs(playerData) do
                teleportToPlayer(myHrp, data.hrp)
                task.wait(0.2)
                spamOwnership(data.hrp)
                task.wait()
            end

            -- プレイヤーを円形に配置
            local radius = 40
            local angleStep = (math.pi * 2) / #playerData
            for idx, data in ipairs(playerData) do
                local angle = (idx - 1) * angleStep
                local x = math.cos(angle) * radius
                local z = math.sin(angle) * radius

                pcall(function()
                    data.hrp.CFrame = CFrame.new(x, height, z)
                    data.hrp.AssemblyLinearVelocity = Vector3.zero
                end)

                local bp = Instance.new("BodyPosition")
                bp.MaxForce = Vector3.new(1e9, 1e9, 1e9)
                bp.P = 40000000
                bp.Position = Vector3.new(x, height, z)
                bp.Parent = data.hrp
                task.delay(2, function() pcall(function() bp:Destroy() end) end)
                task.wait()
            end

            -- ラインスパム
            for i = 1, 8 do
                for _, data in ipairs(playerData) do
                    destroyLineOnPlayer(data.hrp)
                end
                task.wait(0.3)
            end

            LagKick.Running = false
            Library:Notify({ Title = "✔ Complete", Description = "Destruction complete!", Time = 3 })
        end)
    end,
})

-- Stop Lag ボタン
LagKickGroup:AddButton({
    Text = "Stop Lag",
    Tooltip = "ラインラグを停止します",
    Func = function()
        stopLineLag()
        LagKick.Running = false
        Library:Notify({ Title = "Stopped", Description = "Lag stopped", Time = 2 })
    end,
})

-- ステータス表示
LagKickGroup:AddDivider()
LagKickGroup:AddLabel("Status: Idle")

-- =====================================================
-- オプション設定 (パケット数調整)
-- =====================================================
local OptionGroup = Tabs.Main:AddRightGroupbox("オプション", "settings")

OptionGroup:AddSlider("PacketCount", {
    Text = "1回あたりのパケット数",
    Default = 10,
    Min = 1,
    Max = 50,
    Rounding = 0,
    Suffix = "件",
    Tooltip = "1ループで送信するライン作成リクエストの数",
    Callback = function(Value)
        _G.LineLagPacketCount = Value
    end,
})

-- =====================================================
-- UI Settings
-- =====================================================
local MenuGroup = Tabs["UI Settings"]:AddLeftGroupbox("Menu", "wrench")

MenuGroup:AddToggle("ShowCustomCursor", {
    Text = "Custom Cursor",
    Default = true,
    Callback = function(Value)
        Library.ShowCustomCursor = Value
    end,
})

MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", {
    Default = "RightShift",
    NoUI = true,
    Text = "Menu keybind"
})

MenuGroup:AddButton("Unload", function()
    stopLineLag()
    Library:Unload()
end)

Library.ToggleKeybind = Options.MenuKeybind

-- ThemeManager & SaveManager
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })

ThemeManager:SetFolder("LemonLagKick")
SaveManager:SetFolder("LemonLagKick/Configs")

SaveManager:BuildConfigSection(Tabs["UI Settings"])
ThemeManager:ApplyToTab(Tabs["UI Settings"])

SaveManager:LoadAutoloadConfig()

print("LagKick UI Loaded! (Line Lag Mode)")
