-- 盗んだら許しませんよ
-- 製作者・なべうどん なべHub
-- TikTokもやってます
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/katnaa-debug/SolarisUI/refs/heads/main/Library1.lua"))()

local function sendStartMessage()
    local message = "なべHub 溶岩タワースクリプト起動"
    pcall(function()
        local chatEvents = game:GetService("ReplicatedStorage"):FindFirstChild("DefaultChatSystemChatEvents")
        if chatEvents then
            local say = chatEvents:FindFirstChild("SayMessageRequest")
            if say and typeof(say.FireServer) == "function" then
                say:FireServer(message, "All")
                print("チャット送信: " .. message)
                return
            end
        end
    end)
    pcall(function()
        local starterGui = game:GetService("StarterGui")
        starterGui:SetCore("ChatMakeSystemMessage", {
            Name = message,
            Color = Color3.fromRGB(200, 200, 200),
            Font = Enum.Font.SourceSansBold,
            FontSize = Enum.FontSize.Size18,
        })
        print("システムメッセージ: " .. message)
    end)
end

local CustomTheme = {
    Main = Color3.fromRGB(30, 30, 35),
    Second = Color3.fromRGB(45, 45, 50),
    Accent = Color3.fromRGB(200, 200, 200),
    ElementAccent = Color3.fromRGB(220, 220, 220),
    Text = Color3.fromRGB(240, 240, 240),
    TextDark = Color3.fromRGB(170, 170, 170),
    Error = Color3.fromRGB(255, 80, 80),
    GradientStart = Color3.fromRGB(200, 200, 200),
    GradientEnd = Color3.fromRGB(150, 150, 150),
    Transparency = 0.15,
    HudTransparency = 0.3,
    ImageTransparency = 0.2,
    Font = "Gotham",
    Background = "",
    UiScale = 1.0
}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Lighting = game:GetService("Lighting")

local CONFIG = {
    AuraRadius = 8,
    AuraInterval = 0.5,
    AttackSpeed = 10,
    AttackDuration = 3,
    TeleportInterval = 0.15,
    TeleportMaxDistance = 150,
    TeleportHeight = 3,
    MassTeleportInterval = 0.3,
    MassTeleportRadius = 30,
    MassTeleportHeight = 10,
    MoveThreshold = 50,
    MaxLogs = 50,
    WalkSpeed = 16,
    JumpPower = 50,
    Brightness = 2,
    LavaTransparency = 100,
    FOV = 70,
    ExcludedPlayer = "",
    Whitelist = {},
    ExcludeFriends = true,
    InfiniteJump = false,
    AutoHeal = false,
    Noclip = false,
    SelfSlashProtection = false,
    MoveDetection = false,
    KillBlockDetection = false,
    MassTeleportEnabled = false,
}

local SlashRemote = ReplicatedStorage:FindFirstChild("lol")

local auraActive = false
local selectedTarget = nil
local autoTPActive = false
local autoTPStartPos = nil
local targetLoopActive = false
local targetLoopStartPos = nil
local pullActive = false
local infiniteJumpActive = false
local currentLavaTransparency = 100
local savedPositions = {}
local savedPositionNames = {}
local espHighlights = {}
local espEnabled = false
local spinActive = false
local spinSpeed = 5
local detectionLogs = {}
local speedActive = false
local killAuraActive = false
local magmaOff = false
local noclipActive = false
local massTeleportActive = false
local massTeleportConnection = nil
local cachedTargets = {}
local cachedLavaParts = {}
local lastCacheUpdate = 0
local mainLoopConnection = nil
local lavaMonitorConnection = nil

local function isWhitelisted(player)
    if not player then return false end
    if player.Name == CONFIG.ExcludedPlayer then return true end
    if CONFIG.ExcludeFriends and LocalPlayer:IsFriendsWith(player.UserId) then return true end
    for _, name in ipairs(CONFIG.Whitelist) do
        if player.Name == name or player.DisplayName == name then
            return true
        end
    end
    return false
end

local function updateCaches()
    local targets = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and not isWhitelisted(p) then
            local char = p.Character
            if char and char:FindFirstChild("Head") and char:FindFirstChild("HumanoidRootPart") then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    table.insert(targets, {
                        player = p,
                        character = char,
                        head = char.Head,
                        root = char.HumanoidRootPart,
                        hum = hum,
                    })
                end
            end
        end
    end
    cachedTargets = targets
    local lavas = {}
    for _, part in pairs(Workspace:GetDescendants()) do
        if part:IsA("BasePart") and part.Name == "Lava" then
            table.insert(lavas, part)
        end
    end
    cachedLavaParts = lavas
end

updateCaches()
Players.PlayerAdded:Connect(function() task.wait(0.3) updateCaches() end)
Players.PlayerRemoving:Connect(function() task.wait(0.3) updateCaches() end)
LocalPlayer.CharacterAdded:Connect(function() task.wait(0.5) updateCaches() end)

local function slashAll()
    if not SlashRemote then return end
    for _, t in ipairs(cachedTargets) do
        if t.head then
            pcall(function()
                SlashRemote:FireServer("slash", t.character, t.head.Position)
            end)
        end
    end
end

local function startMassTeleport()
    if massTeleportConnection then return end
    massTeleportConnection = RunService.Heartbeat:Connect(function()
        if not massTeleportActive then return end
        local myChar = LocalPlayer.Character
        if not myChar then return end
        local myRoot = myChar:FindFirstChild("HumanoidRootPart")
        if not myRoot then return end
        local myPos = myRoot.Position
        for _, t in ipairs(cachedTargets) do
            if not t.root then continue end
            local offset = Vector3.new(
                math.random(-CONFIG.MassTeleportRadius, CONFIG.MassTeleportRadius),
                CONFIG.MassTeleportHeight,
                math.random(-CONFIG.MassTeleportRadius, CONFIG.MassTeleportRadius)
            )
            t.root.CFrame = CFrame.new(myPos + offset)
            t.root.AssemblyLinearVelocity = Vector3.zero
            t.root.AssemblyAngularVelocity = Vector3.zero
            task.wait(CONFIG.MassTeleportInterval)
        end
    end)
end

local function stopMassTeleport()
    if massTeleportConnection then
        massTeleportConnection:Disconnect()
        massTeleportConnection = nil
    end
end

local function startMainLoop()
    if mainLoopConnection then return end
    local timers = {
        aura = 0,
        heal = 0,
        move = 0,
        killblock = 0,
        targetloop = 0,
        autotp = 0,
        pull = 0,
        spin = 0,
        noclip = 0,
        speed = 0,
        cache = 0,
    }
    mainLoopConnection = RunService.Heartbeat:Connect(function()
        local now = tick()
        if now - timers.cache >= 0.5 then
            updateCaches()
            timers.cache = now
        end
        if auraActive and SlashRemote and now - timers.aura >= CONFIG.AuraInterval then
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                local myPos = char.HumanoidRootPart.Position
                for _, t in ipairs(cachedTargets) do
                    if (t.head.Position - myPos).Magnitude <= CONFIG.AuraRadius then
                        pcall(function()
                            SlashRemote:FireServer("slash", t.character, t.head.Position)
                        end)
                    end
                end
            end
            timers.aura = now
        end
        if killAuraActive and now - timers.aura >= 0.3 then
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                local myPos = char.HumanoidRootPart.Position
                for _, t in ipairs(cachedTargets) do
                    if (t.root.Position - myPos).Magnitude <= CONFIG.AuraRadius then
                        pcall(function()
                            t.hum.Health = 0
                        end)
                    end
                end
            end
            timers.aura = now
        end
        if targetLoopActive and SlashRemote and now - timers.targetloop >= CONFIG.TeleportInterval then
            if selectedTarget and selectedTarget.Character then
                local myChar = LocalPlayer.Character
                if myChar and myChar:FindFirstChild("HumanoidRootPart") then
                    local myRoot = myChar.HumanoidRootPart
                    local tChar = selectedTarget.Character
                    local tRoot = tChar:FindFirstChild("HumanoidRootPart")
                    if tRoot then
                        if (myRoot.Position - tRoot.Position).Magnitude <= CONFIG.TeleportMaxDistance * 1.2 then
                            myRoot.CFrame = tRoot.CFrame
                            myRoot.AssemblyLinearVelocity = Vector3.zero
                            for i = 1, 3 do
                                pcall(function()
                                    SlashRemote:FireServer("slash", tChar, tRoot.Position)
                                end)
                                task.wait(0.02)
                            end
                            if targetLoopStartPos then
                                myRoot.CFrame = targetLoopStartPos
                                myRoot.AssemblyLinearVelocity = Vector3.zero
                            end
                        end
                    end
                end
            end
            timers.targetloop = now
        end
        if autoTPActive and SlashRemote and now - timers.autotp >= CONFIG.TeleportInterval then
            local myChar = LocalPlayer.Character
            if myChar and myChar:FindFirstChild("HumanoidRootPart") then
                local myRoot = myChar.HumanoidRootPart
                for _, t in ipairs(cachedTargets) do
                    if not autoTPActive then break end
                    if (myRoot.Position - t.root.Position).Magnitude <= CONFIG.TeleportMaxDistance then
                        myRoot.CFrame = t.root.CFrame + Vector3.new(0, CONFIG.TeleportHeight, 0)
                        myRoot.AssemblyLinearVelocity = Vector3.zero
                        task.wait(0.03)
                        for i = 1, 2 do
                            pcall(function()
                                SlashRemote:FireServer("slash", t.character, t.root.Position)
                            end)
                            task.wait(0.03)
                        end
                        if autoTPStartPos then
                            myRoot.CFrame = autoTPStartPos
                            myRoot.AssemblyLinearVelocity = Vector3.zero
                        end
                        break
                    end
                end
            end
            timers.autotp = now
        end
        if pullActive and now - timers.pull >= 0.15 then
            local currentPos = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character.HumanoidRootPart.Position
            if currentPos then
                for _, t in ipairs(cachedTargets) do
                    local offset = Vector3.new(math.random(-3, 3), 3, math.random(-3, 3))
                    t.root.CFrame = CFrame.new(currentPos + offset)
                    t.root.AssemblyLinearVelocity = Vector3.zero
                end
            end
            timers.pull = now
        end
        if spinActive and now - timers.spin >= 0.05 then
            local char = LocalPlayer.Character
            if char then
                local root = char:FindFirstChild("HumanoidRootPart")
                if root then
                    root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(spinSpeed), 0)
                end
            end
            timers.spin = now
        end
        if noclipActive and now - timers.noclip >= 0.1 then
            local char = LocalPlayer.Character
            if char then
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
            timers.noclip = now
        end
        if speedActive and now - timers.speed >= 0.1 then
            local char = LocalPlayer.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then
                    hum.WalkSpeed = CONFIG.WalkSpeed
                end
            end
            timers.speed = now
        end
        if now - timers.heal >= 0.3 then
            if CONFIG.AutoHeal or CONFIG.SelfSlashProtection then
                local char = LocalPlayer.Character
                if char then
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health < hum.MaxHealth then
                        hum.Health = hum.MaxHealth
                    end
                end
            end
            timers.heal = now
        end
        if CONFIG.MoveDetection and now - timers.move >= 0.3 then
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                local root = char.HumanoidRootPart
                if root then
                    if root:GetAttribute("LastPos") then
                        local lastPos = root:GetAttribute("LastPos")
                        if (root.Position - lastPos).Magnitude > CONFIG.MoveThreshold then
                            pcall(function()
                                root.CFrame = CFrame.new(lastPos)
                                root.AssemblyLinearVelocity = Vector3.zero
                            end)
                            AddLog("強制移動検知", {})
                        end
                    end
                    root:SetAttribute("LastPos", root.Position)
                end
            end
            timers.move = now
        end
        if CONFIG.KillBlockDetection and now - timers.killblock >= 0.5 then
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                local myPos = char.HumanoidRootPart.Position
                for _, part in pairs(cachedLavaParts) do
                    if part and part.Parent and (myPos - part.Position).Magnitude < 3 then
                        AddLog("危険ブロック", {blockName = part.Name})
                        Library:Notify({
                            Title = "危険ブロック検知",
                            Content = string.format("%s に接近", part.Name),
                            Duration = 2
                        })
                        break
                    end
                end
            end
            timers.killblock = now
        end
    end)
end

local function setupLavaMonitor()
    if lavaMonitorConnection then
        lavaMonitorConnection:Disconnect()
        lavaMonitorConnection = nil
    end
    lavaMonitorConnection = Workspace.DescendantAdded:Connect(function(descendant)
        if descendant:IsA("BasePart") and descendant.Name == "Lava" then
            task.wait(0.05)
            local transparency = currentLavaTransparency / 100
            pcall(function()
                descendant.Transparency = transparency
            end)
            if magmaOff then
                local ti = descendant:FindFirstChild("TouchInterest")
                if ti then ti:Destroy() end
            end
            table.insert(cachedLavaParts, descendant)
        end
    end)
end

local function setLavaTransparency(value)
    CONFIG.LavaTransparency = value
    currentLavaTransparency = value
    local transparency = value / 100
    for _, part in ipairs(cachedLavaParts) do
        if part and part.Parent then
            pcall(function()
                part.Transparency = transparency
            end)
        end
    end
end

local function toggleMagma(on)
    magmaOff = on
    if on then
        for _, part in ipairs(cachedLavaParts) do
            if part and part.Parent then
                local ti = part:FindFirstChild("TouchInterest")
                if ti then ti:Destroy() end
            end
        end
        setLavaTransparency(100)
        Library:Notify({ Title = "溶岩無効化", Content = "ON", Duration = 2 })
    else
        setLavaTransparency(0)
        Library:Notify({ Title = "溶岩無効化", Content = "OFF", Duration = 2 })
    end
end

local function toggleInfiniteJump(on)
    CONFIG.InfiniteJump = on
    infiniteJumpActive = on
    Library:Notify({ Title = "無限ジャンプ", Content = on and "ON" or "OFF", Duration = 2 })
end

UserInputService.JumpRequest:Connect(function()
    if infiniteJumpActive then
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end
end)

local function startAura()
    if auraActive then return end
    auraActive = true
    Library:Notify({ Title = "オーラ", Content = "ON", Duration = 2 })
end

local function stopAura()
    auraActive = false
    Library:Notify({ Title = "オーラ", Content = "OFF", Duration = 2 })
end

local function startKillAura()
    if killAuraActive then return end
    killAuraActive = true
    Library:Notify({ Title = "キルオーラ", Content = "ON", Duration = 2 })
end

local function stopKillAura()
    killAuraActive = false
    Library:Notify({ Title = "キルオーラ", Content = "OFF", Duration = 2 })
end

local function toggleTargetLoop(on)
    targetLoopActive = on
    if on then
        if not selectedTarget then
            Library:Notify({ Title = "ターゲットLOOP", Content = "先にターゲットを選択", Duration = 2 })
            targetLoopActive = false
            return
        end
        if selectedTarget == LocalPlayer then
            Library:Notify({ Title = "ターゲットLOOP", Content = "自分は選択できません", Duration = 2 })
            targetLoopActive = false
            return
        end
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            targetLoopStartPos = char.HumanoidRootPart.CFrame
        end
        Library:Notify({ Title = "ターゲットLOOP", Content = selectedTarget.Name .. " を攻撃", Duration = 2 })
    else
        Library:Notify({ Title = "ターゲットLOOP", Content = "停止", Duration = 2 })
    end
end

local function toggleAutoTP(on)
    autoTPActive = on
    if on then
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            autoTPStartPos = char.HumanoidRootPart.CFrame
        end
        Library:Notify({ Title = "AutoTP", Content = "ON", Duration = 2 })
    else
        Library:Notify({ Title = "AutoTP", Content = "OFF", Duration = 2 })
    end
end

local function togglePull(on)
    pullActive = on
    Library:Notify({ Title = "引き寄せ", Content = on and "ON" or "OFF", Duration = 2 })
end

local function toggleSpeed(on)
    speedActive = on
    Library:Notify({ Title = "移動速度", Content = on and "ON" or "OFF", Duration = 2 })
end

local function toggleNoclip(on)
    noclipActive = on
    Library:Notify({ Title = "壁抜け", Content = on and "ON" or "OFF", Duration = 2 })
end

local function toggleSpin(on)
    spinActive = on
    Library:Notify({ Title = "スピン", Content = on and "ON" or "OFF", Duration = 2 })
end

local function toggleMassTeleport(on)
    massTeleportActive = on
    if on then
        startMassTeleport()
        Library:Notify({ Title = "全員テレポート", Content = "ON", Duration = 2 })
    else
        stopMassTeleport()
        Library:Notify({ Title = "全員テレポート", Content = "OFF", Duration = 2 })
    end
end

local function killRandom()
    if #cachedTargets == 0 then
        Library:Notify({ Title = "ランダムキル", Content = "対象がいません", Duration = 2 })
        return
    end
    local t = cachedTargets[math.random(1, #cachedTargets)]
    if t and t.hum then
        t.hum.Health = 0
        Library:Notify({ Title = "ランダムキル", Content = t.player.Name .. " をキル", Duration = 2 })
    end
end

local function attackAll()
    local dur = CONFIG.AttackDuration
    local interval = 1 / CONFIG.AttackSpeed
    local t = tick()
    while tick() - t < dur do
        slashAll()
        task.wait(interval)
    end
    Library:Notify({ Title = "全体攻撃", Content = "完了", Duration = 2 })
end

local function setFOV(value)
    CONFIG.FOV = value
    Camera.FieldOfView = value
end

local function setBrightness(value)
    CONFIG.Brightness = value
    Lighting.Brightness = value
end

setBrightness(CONFIG.Brightness)

local function TeleportToPlayer(player)
    if not player then return end
    local tChar = player.Character
    if not tChar then return end
    local tRoot = tChar:FindFirstChild("HumanoidRootPart")
    if not tRoot then return end
    local myChar = LocalPlayer.Character
    if not myChar then return end
    local myRoot = myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    myRoot.CFrame = tRoot.CFrame + Vector3.new(0, CONFIG.TeleportHeight, 0)
    Library:Notify({ Title = "テレポート", Content = player.DisplayName .. " の位置へ", Duration = 2 })
end

local function TeleportToCoordinates(x, y, z)
    local myChar = LocalPlayer.Character
    if not myChar then return end
    local myRoot = myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    myRoot.CFrame = CFrame.new(x, y, z)
    Library:Notify({ Title = "テレポート", Content = string.format("(%.1f, %.1f, %.1f)", x, y, z), Duration = 2 })
end

local function SaveCurrentPosition(name)
    if not name or name == "" then
        Library:Notify({ Title = "保存", Content = "名前を入力", Duration = 2 })
        return
    end
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    savedPositions[name] = root.Position
    table.insert(savedPositionNames, name)
    Library:Notify({ Title = "保存", Content = "'" .. name .. "' を保存", Duration = 2 })
end

local function TeleportToSaved(name)
    local pos = savedPositions[name]
    if not pos then
        Library:Notify({ Title = "テレポート", Content = "'" .. name .. "' は見つかりません", Duration = 2 })
        return
    end
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    root.CFrame = CFrame.new(pos)
    Library:Notify({ Title = "テレポート", Content = "'" .. name .. "' に移動", Duration = 2 })
end

local function DeleteSavedPosition(name)
    savedPositions[name] = nil
    for i, n in ipairs(savedPositionNames) do
        if n == name then
            table.remove(savedPositionNames, i)
            break
        end
    end
    Library:Notify({ Title = "削除", Content = "'" .. name .. "' を削除", Duration = 2 })
end

local function AddLog(logType, data)
    table.insert(detectionLogs, 1, {
        type = logType,
        time = os.date("%H:%M:%S"),
        data = data,
    })
    while #detectionLogs > CONFIG.MaxLogs do
        table.remove(detectionLogs)
    end
end

local function showDetectionLogs()
    if #detectionLogs == 0 then
        Library:Notify({ Title = "検知ログ", Content = "ログがありません", Duration = 2 })
        return
    end
    local logText = ""
    for i = 1, math.min(10, #detectionLogs) do
        local log = detectionLogs[i]
        logText = logText .. string.format("[%s] %s\n", log.time, log.type)
        if log.data then
            for k, v in pairs(log.data) do
                logText = logText .. string.format("  %s: %s\n", k, tostring(v))
            end
        end
        logText = logText .. "\n"
    end
    Library:Notify({ Title = "検知ログ", Content = logText, Duration = 6 })
end

local function updateESP()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            if espEnabled and p.Character then
                if not espHighlights[p] then
                    local h = Instance.new("Highlight")
                    h.Adornee = p.Character
                    h.FillColor = Color3.fromRGB(200, 200, 200)
                    h.FillTransparency = 0.4
                    h.OutlineColor = Color3.fromRGB(240, 240, 240)
                    h.Parent = p.Character
                    espHighlights[p] = h
                end
            else
                if espHighlights[p] then
                    espHighlights[p]:Destroy()
                    espHighlights[p] = nil
                end
            end
        end
    end
end

local function toggleESP(on)
    espEnabled = on
    if not on then
        for _, h in pairs(espHighlights) do
            if h then h:Destroy() end
        end
        espHighlights = {}
    else
        updateESP()
    end
    Library:Notify({ Title = "ESP", Content = on and "ON" or "OFF", Duration = 2 })
end

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    if espEnabled then updateESP() end
end)

Players.PlayerAdded:Connect(function()
    task.wait(0.5)
    if espEnabled then updateESP() end
end)

local function getPlayerList()
    local list = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local whitelisted = false
            for _, name in ipairs(CONFIG.Whitelist) do
                if p.Name == name then whitelisted = true break end
            end
            if not whitelisted then
                table.insert(list, p.DisplayName .. " (@ " .. p.Name .. ")")
            end
        end
    end
    if #list == 0 then table.insert(list, "(なし)") end
    return list
end

local function getWhitelistForDropdown()
    local list = {}
    for _, name in ipairs(CONFIG.Whitelist) do
        table.insert(list, name)
    end
    if #list == 0 then table.insert(list, "(なし)") end
    return list
end

local function getTargetList()
    local list = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and not isWhitelisted(p) then
            table.insert(list, p.DisplayName .. " (@ " .. p.Name .. ")")
        end
    end
    if #list == 0 then table.insert(list, "(なし)") end
    return list
end

local function getSavedPositionNames()
    local list = {}
    for _, name in ipairs(savedPositionNames) do
        local pos = savedPositions[name]
        if pos then
            table.insert(list, string.format("%s (%.1f, %.1f, %.1f)", name, pos.X, pos.Y, pos.Z))
        else
            table.insert(list, name)
        end
    end
    if #list == 0 then table.insert(list, "(なし)") end
    return list
end

local function updateAllLists(td, tp, wd, rd, sd, dd)
    if td then td:Refresh(getTargetList(), true) end
    if tp then tp:Refresh(getTargetList(), true) end
    if wd then wd:Refresh(getPlayerList(), true) end
    if rd then rd:Refresh(getWhitelistForDropdown(), true) end
    if sd then sd:Refresh(getSavedPositionNames(), true) end
    if dd then dd:Refresh(getSavedPositionNames(), true) end
end

local function PatchCloseButton()
    task.wait(0.8)
    local screenGui = game:GetService("CoreGui"):FindFirstChild("MainUI")
    if not screenGui then return end
    local windowContainer = screenGui:FindFirstChild("WindowContainer")
    if not windowContainer then return end
    local main = windowContainer:FindFirstChild("Main")
    if not main then return end
    local topBar = main:FindFirstChild("TopBar")
    if not topBar then return end
    local closeBtn = nil
    for _, child in pairs(topBar:GetChildren()) do
        if child:IsA("TextButton") then
            closeBtn = child
            break
        end
    end
    if closeBtn then
        for _, conn in pairs(getconnections(closeBtn.MouseButton1Click)) do
            conn:Disconnect()
        end
        closeBtn.MouseButton1Click:Connect(function()
            windowContainer.Visible = false
            for _, child in pairs(windowContainer:GetChildren()) do
                if child:IsA("ImageLabel") and child.Name:find("Shadow") then
                    child.Visible = false
                end
            end
        end)
    end
end

local Window = Library:CreateWindow({
    Title = "なべHub 溶岩タワー v1.4",
    Theme = CustomTheme,
    ToggleKey = Enum.KeyCode.RightShift,
    Transparency = 0.15,
    ShowWatermark = {
        Enabled = true,
        Title = true,
        User = true,
        FPS = true,
        Duration = false,
        Ping = true
    },
    AutoSave = true,
    ConfigFolder = "NabeHub_LavaTower_Config"
})

task.spawn(PatchCloseButton)
startMainLoop()
setupLavaMonitor()

task.spawn(function()
    task.wait(0.5)
    sendStartMessage()
end)

local CombatTab = Window:CreateTab("戦闘", true, "rbxassetid://107058246184363")
local CombatGroup = CombatTab:CreateBlock({ Name = "攻撃", Side = "Left" })
local TargetGroup = CombatTab:CreateBlock({ Name = "ターゲット", Side = "Right" })

CombatGroup:CreateToggle({
    Name = "オーラモード",
    Flag = "AuraMode",
    Default = false,
    Callback = function(on)
        if on then startAura() else stopAura() end
    end
})

CombatGroup:CreateToggle({
    Name = "キルオーラ（即死）",
    Flag = "KillAura",
    Default = false,
    Callback = function(on)
        if on then startKillAura() else stopKillAura() end
    end
})

CombatGroup:CreateButton({
    Name = "ランダムキル",
    Callback = killRandom
})

CombatGroup:CreateButton({
    Name = "全体攻撃",
    Callback = attackAll
})

CombatGroup:CreateSlider({
    Name = "オーラ半径",
    Flag = "AuraRadius",
    Min = 3,
    Max = 20,
    Default = 8,
    Callback = function(v) CONFIG.AuraRadius = v end
})

CombatGroup:CreateSlider({
    Name = "オーラ間隔(秒)",
    Flag = "AuraInterval",
    Min = 0.1,
    Max = 2,
    Default = 0.5,
    Callback = function(v) CONFIG.AuraInterval = v end
})

CombatGroup:CreateSlider({
    Name = "全体攻撃速度",
    Flag = "AttackSpeed",
    Min = 1,
    Max = 50,
    Default = 10,
    Callback = function(v) CONFIG.AttackSpeed = v end
})

CombatGroup:CreateSlider({
    Name = "全体攻撃時間(秒)",
    Flag = "AttackDuration",
    Min = 1,
    Max = 10,
    Default = 3,
    Callback = function(v) CONFIG.AttackDuration = v end
})

local targetDropdown = TargetGroup:CreateDropdown({
    Name = "ターゲット選択",
    Flag = "TargetSelect",
    Items = getTargetList(),
    Default = 1,
    Callback = function(v)
        if v and v ~= "(なし)" then
            local name = v:match("%@%s*(.-)%)")
            if name then selectedTarget = Players:FindFirstChild(name) end
        end
    end
})

TargetGroup:CreateToggle({
    Name = "ターゲットLOOP攻撃",
    Flag = "TargetLoop",
    Default = false,
    Callback = toggleTargetLoop
})

TargetGroup:CreateToggle({
    Name = "AutoTP攻撃",
    Flag = "AutoTP",
    Default = false,
    Callback = toggleAutoTP
})

TargetGroup:CreateToggle({
    Name = "引き寄せ",
    Flag = "Pull",
    Default = false,
    Callback = togglePull
})

TargetGroup:CreateSlider({
    Name = "テレポート間隔(秒)",
    Flag = "TeleportInterval",
    Min = 0.02,
    Max = 0.5,
    Default = 0.15,
    Callback = function(v) CONFIG.TeleportInterval = v end
})

TargetGroup:CreateSlider({
    Name = "TP最大距離",
    Flag = "TPMaxDist",
    Min = 50,
    Max = 300,
    Default = 150,
    Callback = function(v) CONFIG.TeleportMaxDistance = v end
})

TargetGroup:CreateSlider({
    Name = "テレポート高さ",
    Flag = "TeleportHeight",
    Min = 0,
    Max = 20,
    Default = 3,
    Callback = function(v) CONFIG.TeleportHeight = v end
})

TargetGroup:CreateButton({
    Name = "リスト更新",
    Callback = function()
        updateAllLists(targetDropdown, nil, nil, nil, nil, nil)
    end
})

local DefenseTab = Window:CreateTab("防御", true, "rbxassetid://7461510456")
local DefenseGroup = DefenseTab:CreateBlock({ Name = "防御機能", Side = "Left" })
local LavaGroup = DefenseTab:CreateBlock({ Name = "溶岩設定", Side = "Right" })

DefenseGroup:CreateToggle({
    Name = "自分スラップ無効化",
    Flag = "SelfProtection",
    Default = false,
    Callback = function(on) CONFIG.SelfSlashProtection = on end
})

DefenseGroup:CreateToggle({
    Name = "強制移動検知",
    Flag = "MoveDetection",
    Default = false,
    Callback = function(on) CONFIG.MoveDetection = on end
})

DefenseGroup:CreateToggle({
    Name = "Killブロック検知",
    Flag = "KillBlockDetection",
    Default = false,
    Callback = function(on) CONFIG.KillBlockDetection = on end
})

DefenseGroup:CreateToggle({
    Name = "Health自動回復",
    Flag = "AutoHeal",
    Default = false,
    Callback = function(on) CONFIG.AutoHeal = on end
})

DefenseGroup:CreateButton({
    Name = "検知ログ表示",
    Callback = showDetectionLogs
})

DefenseGroup:CreateSlider({
    Name = "移動検知閾値(m)",
    Flag = "MoveThreshold",
    Min = 10,
    Max = 200,
    Default = 50,
    Callback = function(v) CONFIG.MoveThreshold = v end
})

DefenseGroup:CreateSlider({
    Name = "ログ保存数",
    Flag = "MaxLogs",
    Min = 10,
    Max = 100,
    Default = 50,
    Callback = function(v) CONFIG.MaxLogs = v end
})

LavaGroup:CreateSlider({
    Name = "溶岩透明度",
    Flag = "LavaTransparency",
    Min = 0,
    Max = 100,
    Default = 100,
    Callback = function(v) setLavaTransparency(v) end
})

LavaGroup:CreateToggle({
    Name = "溶岩ダメージ無効化",
    Flag = "MagmaOff",
    Default = false,
    Callback = toggleMagma
})

LavaGroup:CreateButton({
    Name = "デフォルトに戻す",
    Callback = function() setLavaTransparency(0) end
})

local PlayerTab = Window:CreateTab("プレイヤー", true, "rbxassetid://124871982298256")
local PlayerGroup = PlayerTab:CreateBlock({ Name = "プレイヤー設定", Side = "Left" })
local TeleportGroup = PlayerTab:CreateBlock({ Name = "テレポート", Side = "Right" })
local ExtraGroup = PlayerTab:CreateBlock({ Name = "その他", Side = "Right" })

PlayerGroup:CreateToggle({
    Name = "無限ジャンプ",
    Flag = "InfiniteJump",
    Default = false,
    Callback = toggleInfiniteJump
})

PlayerGroup:CreateSlider({
    Name = "ジャンプ力",
    Flag = "JumpPower",
    Min = 24,
    Max = 1000,
    Default = 50,
    Callback = function(v) CONFIG.JumpPower = v end
})

PlayerGroup:CreateToggle({
    Name = "移動速度",
    Flag = "SpeedToggle",
    Default = false,
    Callback = toggleSpeed
})

PlayerGroup:CreateSlider({
    Name = "速度(数値)",
    Flag = "WalkSpeed",
    Min = 16,
    Max = 500,
    Default = 16,
    Callback = function(v) CONFIG.WalkSpeed = v end
})

PlayerGroup:CreateToggle({
    Name = "壁抜け",
    Flag = "Noclip",
    Default = false,
    Callback = toggleNoclip
})

PlayerGroup:CreateToggle({
    Name = "全員テレポート",
    Flag = "MassTeleport",
    Default = false,
    Callback = toggleMassTeleport
})

PlayerGroup:CreateSlider({
    Name = "全員テレポート間隔(秒)",
    Flag = "MassTeleportInterval",
    Min = 0.05,
    Max = 1,
    Default = 0.3,
    Callback = function(v) CONFIG.MassTeleportInterval = v end
})

PlayerGroup:CreateSlider({
    Name = "全員テレポート範囲",
    Flag = "MassTeleportRadius",
    Min = 5,
    Max = 100,
    Default = 30,
    Callback = function(v) CONFIG.MassTeleportRadius = v end
})

PlayerGroup:CreateSlider({
    Name = "全員テレポート高さ",
    Flag = "MassTeleportHeight",
    Min = 0,
    Max = 50,
    Default = 10,
    Callback = function(v) CONFIG.MassTeleportHeight = v end
})

local teleportDropdown = TeleportGroup:CreateDropdown({
    Name = "テレポート先",
    Flag = "TeleportTarget",
    Items = getTargetList(),
    Default = 1,
    Callback = function(v)
        if v and v ~= "(なし)" then
            local name = v:match("%@%s*(.-)%)")
            if name then selectedTarget = Players:FindFirstChild(name) end
        end
    end
})

TeleportGroup:CreateButton({
    Name = "テレポート実行",
    Callback = function()
        if selectedTarget then TeleportToPlayer(selectedTarget) end
    end
})

TeleportGroup:CreateInput({
    Name = "X",
    Flag = "TeleportX",
    Default = "0",
    Placeholder = "X"
})

TeleportGroup:CreateInput({
    Name = "Y",
    Flag = "TeleportY",
    Default = "10",
    Placeholder = "Y"
})

TeleportGroup:CreateInput({
    Name = "Z",
    Flag = "TeleportZ",
    Default = "0",
    Placeholder = "Z"
})

TeleportGroup:CreateButton({
    Name = "座標にテレポート",
    Callback = function()
        local x = tonumber(Library.Flags["TeleportX"] or 0) or 0
        local y = tonumber(Library.Flags["TeleportY"] or 10) or 10
        local z = tonumber(Library.Flags["TeleportZ"] or 0) or 0
        TeleportToCoordinates(x, y, z)
    end
})

TeleportGroup:CreateButton({
    Name = "現在地を取得",
    Callback = function()
        local char = LocalPlayer.Character
        if char then
            local root = char:FindFirstChild("HumanoidRootPart")
            if root then
                local pos = root.Position
                Library:Notify({ Title = "現在地", Content = string.format("(%.1f, %.1f, %.1f)", pos.X, pos.Y, pos.Z), Duration = 2 })
            end
        end
    end
})

TeleportGroup:CreateInput({
    Name = "保存名",
    Flag = "SaveName",
    Default = "",
    Placeholder = "名前"
})

TeleportGroup:CreateButton({
    Name = "現在地を保存",
    Callback = function()
        local name = Library.Flags["SaveName"] or ""
        if name ~= "" then
            SaveCurrentPosition(name)
            savedDropdown:Refresh(getSavedPositionNames(), true)
            deleteDropdown:Refresh(getSavedPositionNames(), true)
        end
    end
})

local savedDropdown = TeleportGroup:CreateDropdown({
    Name = "保存済み座標",
    Flag = "SavedPositions",
    Items = getSavedPositionNames(),
    Default = 1,
    Callback = function(v)
        if v and v ~= "(なし)" then
            local name = v:match("^(.-)%s*%(")
            if name then TeleportToSaved(name) end
        end
    end
})

local deleteDropdown = TeleportGroup:CreateDropdown({
    Name = "削除する座標",
    Flag = "DeleteSaved",
    Items = getSavedPositionNames(),
    Default = 1,
    Callback = function(v)
        if v and v ~= "(なし)" then
            local name = v:match("^(.-)%s*%(")
            if name then
                DeleteSavedPosition(name)
                savedDropdown:Refresh(getSavedPositionNames(), true)
                deleteDropdown:Refresh(getSavedPositionNames(), true)
            end
        end
    end
})

TeleportGroup:CreateButton({
    Name = "保存リスト更新",
    Callback = function()
        savedDropdown:Refresh(getSavedPositionNames(), true)
        deleteDropdown:Refresh(getSavedPositionNames(), true)
    end
})

ExtraGroup:CreateToggle({
    Name = "スピン",
    Flag = "Spin",
    Default = false,
    Callback = toggleSpin
})

ExtraGroup:CreateSlider({
    Name = "スピン速度",
    Flag = "SpinSpeed",
    Min = 1,
    Max = 50,
    Default = 5,
    Callback = function(v) spinSpeed = v end
})

ExtraGroup:CreateSlider({
    Name = "FOV",
    Flag = "FOV",
    Min = 40,
    Max = 120,
    Default = 70,
    Callback = setFOV
})

ExtraGroup:CreateToggle({
    Name = "ESP",
    Flag = "ESP",
    Default = false,
    Callback = toggleESP
})

ExtraGroup:CreateSlider({
    Name = "明るさ",
    Flag = "Brightness",
    Min = 0,
    Max = 10,
    Default = 2,
    Callback = function(v)
        setBrightness(v)
        Library:Notify({
            Title = "明るさ",
            Content = string.format("明るさ: %.1f", v),
            Duration = 1
        })
    end
})

local SettingsTab = Window:CreateTab("設定", true, "rbxassetid://7059346373")
local WhitelistGroup = SettingsTab:CreateBlock({ Name = "ホワイトリスト", Side = "Left" })
local WhitelistManage = SettingsTab:CreateBlock({ Name = "ホワイトリスト管理", Side = "Right" })

WhitelistGroup:CreateToggle({
    Name = "フレンドを除外",
    Flag = "ExcludeFriends",
    Default = true,
    Callback = function(on)
        CONFIG.ExcludeFriends = on
        updateAllLists(targetDropdown, teleportDropdown, whitelistDropdown, removeDropdown, nil, nil)
    end
})

WhitelistGroup:CreateInput({
    Name = "除外プレイヤー名",
    Flag = "ExcludedPlayer",
    Default = "",
    Placeholder = "プレイヤー名",
    Callback = function(v)
        CONFIG.ExcludedPlayer = v
        updateAllLists(targetDropdown, teleportDropdown, whitelistDropdown, removeDropdown, nil, nil)
    end
})

local whitelistDropdown = WhitelistManage:CreateDropdown({
    Name = "追加",
    Flag = "WhitelistAdd",
    Items = getPlayerList(),
    Default = 1,
    Callback = function(v)
        if v and v ~= "(なし)" then
            local name = v:match("%@%s*(.-)%)")
            if name then
                table.insert(CONFIG.Whitelist, name)
                whitelistDropdown:Refresh(getPlayerList(), true)
                removeDropdown:Refresh(getWhitelistForDropdown(), true)
                updateAllLists(targetDropdown, teleportDropdown, whitelistDropdown, removeDropdown, nil, nil)
            end
        end
    end
})

local removeDropdown = WhitelistManage:CreateDropdown({
    Name = "削除",
    Flag = "WhitelistRemove",
    Items = getWhitelistForDropdown(),
    Default = 1,
    Callback = function(v)
        if v and v ~= "(なし)" then
            for i, name in ipairs(CONFIG.Whitelist) do
                if name == v then
                    table.remove(CONFIG.Whitelist, i)
                    removeDropdown:Refresh(getWhitelistForDropdown(), true)
                    whitelistDropdown:Refresh(getPlayerList(), true)
                    updateAllLists(targetDropdown, teleportDropdown, whitelistDropdown, removeDropdown, nil, nil)
                    break
                end
            end
        end
    end
})

WhitelistManage:CreateButton({
    Name = "全解除",
    Callback = function()
        CONFIG.Whitelist = {}
        whitelistDropdown:Refresh(getPlayerList(), true)
        removeDropdown:Refresh(getWhitelistForDropdown(), true)
        updateAllLists(targetDropdown, teleportDropdown, whitelistDropdown, removeDropdown, nil, nil)
    end
})

WhitelistManage:CreateButton({
    Name = "全リスト更新",
    Callback = function()
        updateAllLists(targetDropdown, teleportDropdown, whitelistDropdown, removeDropdown, savedDropdown, deleteDropdown)
    end
})

local ScriptTab = Window:CreateTab("スクリプト", true, "rbxassetid://4814130203")
local ScriptGroup = ScriptTab:CreateBlock({ Name = "スクリプト実行", Side = "Left" })

ScriptGroup:CreateButton({
    Name = "vFly起動",
    Callback = function()
        Library:Notify({ Title = "vFly", Content = "読み込み中...", Duration = 2 })
        pcall(function()
            loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-VFly-gui-and-noclip-78112"))()
            Library:Notify({ Title = "vFly", Content = "起動しました！", Duration = 2 })
        end)
    end
})

ScriptGroup:CreateButton({
    Name = "Infinite Yield起動",
    Callback = function()
        Library:Notify({ Title = "Infinite Yield", Content = "読み込み中...", Duration = 2 })
        pcall(function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
            Library:Notify({ Title = "Infinite Yield", Content = "起動しました！", Duration = 2 })
        end)
    end
})

ScriptGroup:CreateInput({
    Name = "スクリプトURL",
    Flag = "ScriptURL",
    Default = "",
    Placeholder = "https://..."
})

ScriptGroup:CreateButton({
    Name = "カスタムスクリプト実行",
    Callback = function()
        local url = Library.Flags["ScriptURL"] or ""
        if url == "" then
            Library:Notify({ Title = "エラー", Content = "URLを入力してください", Duration = 2 })
            return
        end
        Library:Notify({ Title = "スクリプト", Content = "読み込み中...", Duration = 2 })
        pcall(function()
            loadstring(game:HttpGet(url))()
            Library:Notify({ Title = "スクリプト", Content = "実行しました！", Duration = 2 })
        end)
    end
})

task.spawn(function()
    while true do
        task.wait(5)
        pcall(function()
            if whitelistDropdown then whitelistDropdown:Refresh(getPlayerList(), true) end
            if removeDropdown then removeDropdown:Refresh(getWhitelistForDropdown(), true) end
            if targetDropdown then targetDropdown:Refresh(getTargetList(), true) end
            if teleportDropdown then teleportDropdown:Refresh(getTargetList(), true) end
            if savedDropdown then savedDropdown:Refresh(getSavedPositionNames(), true) end
            if deleteDropdown then deleteDropdown:Refresh(getSavedPositionNames(), true) end
        end)
    end
end)

Library:Notify({
    Title = "なべHub 溶岩タワー v1.4",
    Content = "明るさ調整追加版 ロード完了！",
    Duration = 3
})

print("なべHub 溶岩タワー v1.4 - 明るさ調整追加版 ロード完了")
