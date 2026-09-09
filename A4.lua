local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local LP = Players.LocalPlayer

-- Rayfieldライブラリの安全な読み込み
local success, Rayfield = pcall(function()
    return loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
end)

if not success or not Rayfield then
    warn("Rayfieldの読み込みに失敗しました")
    return
end

local Window = Rayfield:CreateWindow({
    Name = "⚡ tanpopo rag kick Premium 💀",
    LoadingTitle = "tanpopo hub",
    LoadingSubtitle = "by tanpopo",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "RagHUB",
        FileName = "RagHubConfig"
    },
    KeySystem = true,
    KeySettings = {
        Title = "🔑 tanpopo hub",
        Subtitle = "キーを入力してください",
        FileName = "tanpopo_key",
        SaveKey = true,
        GrabKeyFromSite = false,
        Key = {"tanpopo"}
    }
})

-- ラグ機能用変数
local lineLagThread = nil
local lineLagEnabled = false
local GrabEvents = ReplicatedStorage:FindFirstChild("GrabEvents")

-- ラグ生成関数 (軽量安定版)
local function startLineLag()
    if lineLagEnabled then return end
    lineLagEnabled = true
    lineLagThread = task.spawn(function()
        if not GrabEvents then return end
        local createLine = GrabEvents:FindFirstChild("CreateGrabLine")
        if not createLine then return end

        while lineLagEnabled do
            local target = Workspace:FindFirstChild("SpawnLocation") or Workspace:FindFirstChild("Spawn") or (LP.Character and LP.Character:FindFirstChild("HumanoidRootPart"))
            if target then
                for i = 1, 10 do 
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
    if lineLagThread then task.cancel(lineLagThread) end
end

-- Kick All 機能用変数と関数
local currentBlob = nil
local isActive = false
local playerStatus = {}

local function GetAllPlayers()
    local players = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LP then
            table.insert(players, player)
        end
    end
    return players
end

local function GetMyRoot()
    return LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
end

local function ResetTargets()
    for id, status in pairs(playerStatus) do
        if status == "Targeting" then playerStatus[id] = nil end
    end
end

local function KickAll()
    if isActive then return end
    isActive = true

    local allPlayers = GetAllPlayers()
    if #allPlayers == 0 then 
        isActive = false
        return 
    end

    for _, targetPlayer in ipairs(allPlayers) do
        playerStatus[targetPlayer.UserId] = "Targeting"
    end

    local rootPart = GetMyRoot()
    if rootPart then
        local spawnPos = rootPart.CFrame * CFrame.new(0, 0, -5)
        pcall(function()
            ReplicatedStorage.MenuToys.SpawnToyRemoteFunction:InvokeServer("CreatureBlobman", spawnPos, Vector3.new(0, 127, 0))
        end)
    end
    task.wait(0.5)

    local toyFolder = workspace:FindFirstChild(LP.Name .. "SpawnedInToys")
    currentBlob = toyFolder and toyFolder:FindFirstChild("CreatureBlobman")
    if not currentBlob then 
        ResetTargets()
        isActive = false
        return 
    end

    local vehicleSeat = currentBlob:FindFirstChild("VehicleSeat")
    if vehicleSeat and LP.Character then
        local humanoid = LP.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            vehicleSeat:Sit(humanoid)
        end
    end
    task.wait(0.3)

    local myRoot = GetMyRoot()
    if not myRoot then 
        ResetTargets()
        isActive = false
        return 
    end

    local tpWait = 0.025

    for _, targetPlayer in ipairs(allPlayers) do
        local targetRoot = targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart")
        if targetRoot then
            myRoot.CFrame = targetRoot.CFrame
            myRoot.AssemblyAngularVelocity = Vector3.zero
            task.wait(tpWait)

            local distance = (myRoot.Position - targetRoot.Position).Magnitude
            if distance <= 35 then
                for i = 1, 8 do
                    if not targetRoot.Parent or not currentBlob.Parent then break end
                    pcall(function()
                        currentBlob.BlobmanSeatAndOwnerScript.CreatureGrab:FireServer(
                            currentBlob.LeftDetector, targetRoot, currentBlob.LeftDetector.LeftWeld
                        )
                        currentBlob.BlobmanSeatAndOwnerScript.CreatureRelease:FireServer(currentBlob.LeftDetector.LeftWeld)
                    end)
                    task.wait()
                end
            end
        end
    end

    myRoot.CFrame = CFrame.new(0, 0, 0)
    myRoot.AssemblyLinearVelocity = Vector3.zero
    task.wait(0.1)

    for _, part in ipairs(currentBlob:GetDescendants()) do
        if part:IsA("BasePart") then pcall(function() part.Anchored = true end) end
    end
    task.wait(0.1)

    -- 円形配置 ＆ 落下防止（BodyPositionで空中に固定）
    local radius = 13
    local centerX, centerY, centerZ = 0, 10, 0

    for i, targetPlayer in ipairs(allPlayers) do
        local targetRoot = targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart")
        if targetRoot then
            local angle = math.rad((i - 1) * (360 / #allPlayers))
            local x = centerX + radius * math.cos(angle)
            local z = centerZ + radius * math.sin(angle)

            pcall(function()
                targetRoot.CFrame = CFrame.new(x, centerY, z)
                targetRoot.AssemblyLinearVelocity = Vector3.zero
                targetRoot.AssemblyAngularVelocity = Vector3.zero
            end)

            local bp = Instance.new("BodyPosition")
            bp.MaxForce = Vector3.new(1e9, 1e9, 1e9)
            bp.P = 4000
            bp.Position = Vector3.new(x, centerY, z)
            bp.Parent = targetRoot
            task.delay(2, function() pcall(function() bp:Destroy() end) end)
        end
    end
    task.wait(0.1)

    for _ = 1, 2 do
        for _, targetPlayer in ipairs(allPlayers) do
            local targetRoot = targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart")
            if targetRoot then
                task.spawn(function()
                    pcall(function()
                        ReplicatedStorage.GrabEvents.SetNetworkOwner:FireServer(targetRoot, CFrame.new(targetRoot.Position))
                        ReplicatedStorage.GrabEvents.DestroyGrabLine:FireServer(targetRoot)
                    end)
                end)
            end
        end
        task.wait(00000.1)
    end

    task.wait(0.3)

    for _, targetPlayer in ipairs(allPlayers) do
        local targetRoot = targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart")
        if targetRoot then
            task.spawn(function()
                pcall(function()
                    currentBlob.BlobmanSeatAndOwnerScript.CreatureGrab:FireServer(
                        currentBlob.LeftDetector, targetRoot, currentBlob.LeftDetector.LeftWeld
                    )
                    currentBlob.BlobmanSeatAndOwnerScript.CreatureGrab:FireServer(
                        currentBlob.RightDetector, targetRoot, currentBlob.RightDetector.RightWeld
                    )
                end)
            end)
        end
    end

    task.wait(0.1)

    for _, targetPlayer in ipairs(allPlayers) do
        if targetPlayer and targetPlayer.Parent == Players then
            playerStatus[targetPlayer.UserId] = "Kicked"
        end
    end

    for _, part in ipairs(currentBlob:GetDescendants()) do
        if part:IsA("BasePart") then pcall(function() part.Anchored = false end) end
    end

    task.wait(1)
    isActive = false
end

-- ===== UI設定 (Rayfield UI) =====
local MainTab = Window:CreateTab("⚡ メイン")

-- ボタンをスタイリッシュに (画像風に)
MainTab:CreateButton({
    Name = "🔥 ラグ＆Kick All 開始 (20秒)",
    Callback = function()
        if lineLagEnabled then
            Rayfield:Notify({
                Title = "⚠️ tanpopo HUB",
                Content = "すでにラグ処理が実行中です",
                Duration = 2,
            })
            return
        end

        startLineLag()

        task.spawn(function()
            pcall(function()
                KickAll()
            end)
        end)

        Rayfield:Notify({
            Title = "🚀 tanpopo hub",
            Content = "20秒間のラグとKick Allを開始しました",
            Duration = 2,
        })

        task.delay(20, function()
            if lineLagEnabled then
                stopLineLag()
                Rayfield:Notify({
                    Title = "⏹️ Rag HUB",
                    Content = "20秒経過したためラグ処理を停止しました",
                    Duration = 2,
                })
            end
        end)
    end,
})

-- 追加で情報表示用セクション
local InfoTab = Window:CreateTab("📋 情報")
InfoTab:CreateParagraph({
    Title = "📌 使い方",
    Content = "「ラグ＆Kick All 開始」ボタンを押すと\n全員に対してラグ攻撃 + 強制キックを実行します。\n処理は約20秒間続きます。"
})

InfoTab:CreateParagraph({
    Title = "👑 クレジット",
    Content = "tanpopo hub Premium\nby tanpopo"
})
