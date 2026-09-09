-- OrionLib 読み込み
local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/jadpy/suki/refs/heads/main/orion"))()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Debris = game:GetService("Debris")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer

-- ================= 変数 =================
local selectedPlayer = nil
local selectedActionTargetName = nil
local superSpeed = false
local infiniteJump = false
local noclip = false
local noclipConn = nil
local Multiplier = 0.15
local espEnabled = false
local espHighlights = {}
local levitateRunning = false

-- ================= =================
local strengthConnection = nil
local nageru = 400
local poisonGrabCoroutine = nil
local ufoGrabCoroutine = nil
local fireGrabCoroutine = nil
local poisonHurtParts = {}
local paintPlayerParts = {}

-- ================= 追加機能用変数 =================
local GrabModes = {
    NoclipGrab = false,
    KillGrab = false
}

-- ================= FTAP K HUB オーラ機能用変数 =================
local auraConnections = {}
local auraRadius = 20
local whitelistFriends = false
local isGrabAuraEnabled = false
local isDeleteAuraEnabled = false
local isFlingAuraEnabled = false

local function isFriend(player)
    return whitelistFriends and LocalPlayer:IsFriendsWith(player.UserId)
end

local function getLocalHumanoidRootPart()
    return LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
end

-- Grab Aura 機能
local function startGrabAura()
    if auraConnections.GrabAura then auraConnections.GrabAura:Disconnect() end
    auraConnections.GrabAura = RunService.Heartbeat:Connect(function()
        if not isGrabAuraEnabled then return end
        local myHRP = getLocalHumanoidRootPart()
        if not myHRP then return end
        
        local GE = ReplicatedStorage:FindFirstChild("GrabEvents")
        local SNO = GE and GE:FindFirstChild("SetNetworkOwner")
        
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and not isFriend(player) then
                local char = player.Character
                local targetHRP = char and char:FindFirstChild("HumanoidRootPart")
                if targetHRP and myHRP then
                    local distance = (myHRP.Position - targetHRP.Position).Magnitude
                    if distance <= auraRadius and SNO then
                        pcall(function()
                            SNO:FireServer(targetHRP, targetHRP.CFrame)
                        end)
                    end
                end
            end
        end
    end)
end

-- Delete Aura 機能（上空に吹き飛ばす）
local function startDeleteAura()
    if auraConnections.DeleteAura then auraConnections.DeleteAura:Disconnect() end
    auraConnections.DeleteAura = RunService.Heartbeat:Connect(function()
        if not isDeleteAuraEnabled then return end
        local myHRP = getLocalHumanoidRootPart()
        if not myHRP then return end
        
        local GE = ReplicatedStorage:FindFirstChild("GrabEvents")
        local SNO = GE and GE:FindFirstChild("SetNetworkOwner")
        
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and not isFriend(player) then
                local char = player.Character
                local targetHRP = char and char:FindFirstChild("HumanoidRootPart")
                local targetTorso = char and (char:FindFirstChild("Torso") or char:FindFirstChild("HumanoidRootPart"))
                if targetHRP and targetTorso and myHRP then
                    local distance = (myHRP.Position - targetHRP.Position).Magnitude
                    if distance <= auraRadius then
                        pcall(function()
                            if SNO then SNO:FireServer(targetTorso, targetHRP.CFrame) end
                            local velocity = targetTorso:FindFirstChild("AuraVelocity") or Instance.new("BodyVelocity")
                            velocity.Name = "AuraVelocity"
                            velocity.Parent = targetTorso
                            velocity.Velocity = Vector3.new(0, 9999999, 0)
                            velocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                            Debris:AddItem(velocity, 0.5)
                        end)
                    end
                end
            end
        end
    end)
end

-- Fling Aura 機能（ランダム方向に吹き飛ばす）
local function startFlingAura()
    if auraConnections.FlingAura then auraConnections.FlingAura:Disconnect() end
    auraConnections.FlingAura = RunService.Heartbeat:Connect(function()
        if not isFlingAuraEnabled then return end
        local myHRP = getLocalHumanoidRootPart()
        if not myHRP then return end
        
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and not isFriend(player) then
                local char = player.Character
                local targetHRP = char and char:FindFirstChild("HumanoidRootPart")
                if targetHRP and myHRP then
                    local distance = (myHRP.Position - targetHRP.Position).Magnitude
                    if distance <= auraRadius then
                        pcall(function()
                            local velocity = targetHRP:FindFirstChild("AuraFlingVelocity") or Instance.new("BodyVelocity")
                            velocity.Name = "AuraFlingVelocity"
                            velocity.Parent = targetHRP
                            velocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                            velocity.Velocity = Vector3.new(math.random(-2000, 2000), 2000, math.random(-2000, 2000))
                            Debris:AddItem(velocity, 0.3)
                        end)
                    end
                end
            end
        end
    end)
end

-- 全オーラ停止関数
local function stopAllAuras()
    if auraConnections.GrabAura then
        auraConnections.GrabAura:Disconnect()
        auraConnections.GrabAura = nil
    end
    if auraConnections.DeleteAura then
        auraConnections.DeleteAura:Disconnect()
        auraConnections.DeleteAura = nil
    end
    if auraConnections.FlingAura then
        auraConnections.FlingAura:Disconnect()
        auraConnections.FlingAura = nil
    end
end

-- ================= 元のコード（完全維持） =================
for _, descendant in ipairs(Workspace:GetDescendants()) do
    if descendant.Name == "PoisonHurtPart" then
        table.insert(poisonHurtParts, descendant)
    elseif descendant.Name == "PaintPlayerPart" then
        table.insert(paintPlayerParts, descendant)
    end
end

local function grabHandler(grabType)
    while true do
        pcall(function()
            local child = workspace:FindFirstChild("GrabParts")
            if child and child.Name == "GrabParts" then
                local grabPart = child:FindFirstChild("GrabPart")
                if grabPart and grabPart:FindFirstChild("WeldConstraint") then
                    local grabbedPart = grabPart.WeldConstraint.Part1
                    local head = grabbedPart and grabbedPart.Parent and grabbedPart.Parent:FindFirstChild("Head")
                    if head then
                        local partsTable = grabType == "poison" and poisonHurtParts or paintPlayerParts
                        for _, part in pairs(partsTable) do
                            part.Size = Vector3.new(2, 2, 2)
                            part.Transparency = 1
                            part.Position = head.Position
                        end
                        task.wait()
                        for _, part in pairs(partsTable) do
                            part.Position = Vector3.new(0, -200, 0)
                        end
                    end
                end
            end
        end)
        task.wait()
    end
end

local function fireGrab()
    while true do
        pcall(function()
            local child = workspace:FindFirstChild("GrabParts")
            if child and child.Name == "GrabParts" then
                local grabPart = child:FindFirstChild("GrabPart")
                if grabPart and grabPart:FindFirstChild("WeldConstraint") then
                    local grabbedPart = grabPart.WeldConstraint.Part1
                    local head = grabbedPart and grabbedPart.Parent and grabbedPart.Parent:FindFirstChild("Head")
                    if head then
                        local toysFolder = workspace:FindFirstChild(LocalPlayer.Name .. "SpawnedInToys")
                        if toysFolder and not toysFolder:FindFirstChild("Campfire") then
                            local spawnRemote = ReplicatedStorage:FindFirstChild("MenuToys") and ReplicatedStorage.MenuToys:FindFirstChild("SpawnToyRemoteFunction")
                            if spawnRemote then
                                pcall(function()
                                    spawnRemote:InvokeServer("Campfire", LocalPlayer.Character.Head.CFrame, Vector3.new(0, 90, 0))
                                end)
                            end
                        end
                        local campfire = toysFolder and toysFolder:FindFirstChild("Campfire")
                        if campfire then
                            local burnPart = campfire:FindFirstChild("FirePlayerPart")
                            if burnPart then
                                burnPart.Size = Vector3.new(7, 7, 7)
                                burnPart.Position = head.Position
                                task.wait(0.3)
                                burnPart.Position = Vector3.new(0, -50, 0)
                            end
                        end
                    end
                end
            end
        end)
        task.wait()
    end
end

-- GrabToggles（元のコード完全維持）
local GrabToggles = {
    KillGrab = false,
    SkyGrab = false,
    DownGrab = false,
    StableGrab = false
}
local GrabConnections = {}

local function handleGrabPart(model, mode)
    if model.Name == "GrabParts" then
        local part_to_impulse = model:FindFirstChild("GrabPart")
        if part_to_impulse and part_to_impulse:FindFirstChild("WeldConstraint") then
            local target = part_to_impulse.WeldConstraint.Part1
            if target then
                if mode == "Kill" then
                    local hum = target.Parent and target.Parent:FindFirstChildOfClass("Humanoid")
                    if hum then
                        hum.Health = 0
                    end
                elseif mode == "Sky" then
                    local bodyVelocity = Instance.new("BodyVelocity")
                    bodyVelocity.Parent = target
                    bodyVelocity.Velocity = Vector3.new(0, 50, 0)
                    bodyVelocity.MaxForce = Vector3.new(0, math.huge, 0)
                    Debris:AddItem(bodyVelocity, 1)
                elseif mode == "Down" then
                    local bodyVelocity = Instance.new("BodyVelocity")
                    bodyVelocity.Parent = target
                    bodyVelocity.Velocity = Vector3.new(0, -50, 0)
                    bodyVelocity.MaxForce = Vector3.new(0, math.huge, 0)
                    Debris:AddItem(bodyVelocity, 1)
                elseif mode == "Stable" then
                    local originalY = target.Position.Y
                    local bodyPosition = Instance.new("BodyPosition")
                    bodyPosition.Parent = target
                    bodyPosition.P = 5000
                    bodyPosition.D = 1000
                    bodyPosition.MaxForce = Vector3.new(0, math.huge, 0)
                    bodyPosition.Position = Vector3.new(target.Position.X, originalY, target.Position.Z)
                    
                    task.spawn(function()
                        while workspace:FindFirstChild("GrabParts") and target and target.Parent do
                            bodyPosition.Position = Vector3.new(target.Position.X, originalY, target.Position.Z)
                            task.wait(0.05)
                        end
                        bodyPosition:Destroy()
                    end)
                end
            end
        end
    end
end

local function toggleGrab(flag, mode)
    if GrabToggles[flag] then
        if GrabConnections[flag] then
            GrabConnections[flag]:Disconnect()
        end
        GrabConnections[flag] = Workspace.ChildAdded:Connect(function(model)
            handleGrabPart(model, mode)
        end)
    else
        if GrabConnections[flag] then
            GrabConnections[flag]:Disconnect()
            GrabConnections[flag] = nil
        end
    end
end

-- ========== 追加機能：Noclipグラブ＆キルグラブ処理 ==========
local function handleExtendedGrabModes(model)
    if model.Name == "GrabParts" then
        local part = model:FindFirstChild("GrabPart")
        if part and part:FindFirstChild("WeldConstraint") then
            local target = part.WeldConstraint.Part1
            if target then
                local targetChar = target.Parent
                
                if GrabModes.KillGrab and targetChar then
                    local hum = targetChar:FindFirstChildOfClass("Humanoid")
                    if hum then
                        hum.Health = 0
                    end
                end
                
                if GrabModes.NoclipGrab and targetChar then
                    for _, bodyPart in pairs(targetChar:GetDescendants()) do
                        if bodyPart:IsA("BasePart") then
                            bodyPart.CanCollide = false
                        end
                    end
                    model.AncestryChanged:Connect(function(_, parent)
                        if not parent and targetChar then
                            for _, bodyPart in pairs(targetChar:GetDescendants()) do
                                if bodyPart:IsA("BasePart") then
                                    bodyPart.CanCollide = true
                                end
                            end
                        end
                    end)
                end
            end
        end
    end
end

local extendedGrabConnection = Workspace.ChildAdded:Connect(function(model)
    handleExtendedGrabModes(model)
end)

-- ================= BlobmanKill用変数（元のコード完全維持） =================
local cachedCG, cachedCD, cachedCR = nil, nil, nil
local cachedR_Det, cachedR_Weld = nil, nil
local cachedL_Det, cachedL_Weld = nil, nil
local cachedBlobman = nil
local playerThreads = {}
local bmkAuraEnabled = false
local AURA_RADIUS = 35
local auraConn = nil
local auraInRange = {}

local function HRP()
    return LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
end

local function refreshBlobman()
    local found = nil
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v.Name == "CreatureBlobman" and v:FindFirstChild("VehicleSeat") then
            local seat = v.VehicleSeat
            local weld = seat and seat:FindFirstChild("SeatWeld")
            if weld and weld.Part1 and weld.Part1:IsDescendantOf(LocalPlayer.Character) then
                found = v; break
            end
        end
    end
    cachedBlobman = found
    if not found then
        cachedCG, cachedCD, cachedCR = nil, nil, nil
        cachedR_Det, cachedR_Weld, cachedL_Det, cachedL_Weld = nil, nil, nil, nil
        return
    end
    local s1 = found:FindFirstChild("BlobmanSeatAndOwnerScript")
    local s2 = found:FindFirstChild("BlobmanSeatAndOwnerScript[old]")
    cachedCG = (s1 and s1:FindFirstChild("CreatureGrab")) or (s2 and s2:FindFirstChild("CreatureGrab")) or found:FindFirstChild("CreatureGrab", true)
    cachedCD = (s1 and s1:FindFirstChild("CreatureDrop")) or (s2 and s2:FindFirstChild("CreatureDrop")) or found:FindFirstChild("CreatureDrop", true)
    cachedCR = (s1 and s1:FindFirstChild("CreatureRelease")) or (s2 and s2:FindFirstChild("CreatureRelease")) or found:FindFirstChild("CreatureRelease", true)
    cachedR_Det = found:FindFirstChild("RightDetector")
    cachedR_Weld = cachedR_Det and (cachedR_Det:FindFirstChild("RightWeld") or cachedR_Det:FindFirstChildWhichIsA("Weld"))
    cachedL_Det = found:FindFirstChild("LeftDetector")
    cachedL_Weld = cachedL_Det and (cachedL_Det:FindFirstChild("LeftWeld") or cachedL_Det:FindFirstChildWhichIsA("Weld"))
end

pcall(refreshBlobman)
Workspace.DescendantAdded:Connect(function(d)
    if d.Name == "CreatureBlobman" or d.Name == "SeatWeld" then task.defer(refreshBlobman) end
end)
Workspace.DescendantRemoving:Connect(function(d)
    if d == cachedBlobman or d.Name == "SeatWeld" then task.defer(refreshBlobman) end
end)

local function stopThreads(userId)
    local st = playerThreads[userId]
    if st then st.active = false; playerThreads[userId] = nil end
end

local function startThreads(player, userId)
    stopThreads(userId)
    local state = { active = true }
    playerThreads[userId] = state

    local grabConn = RunService.Heartbeat:Connect(function()
        if not state.active then grabConn:Disconnect() return end
        if not cachedCG then return end
        local char = player.Character
        if not char then return end
        local pHRP = char:FindFirstChild("HumanoidRootPart")
        if not pHRP then return end
        pcall(function()
            if cachedR_Det then
                cachedCG:FireServer(cachedR_Det, pHRP, cachedR_Weld)
                cachedR_Weld = cachedR_Det:FindFirstChild("RightWeld") or cachedR_Det:FindFirstChildWhichIsA("Weld")
                if cachedCR and cachedR_Weld then cachedCR:FireServer(cachedR_Weld) end
                if cachedCD and cachedR_Weld then cachedCD:FireServer(cachedR_Weld) end
            end
            if cachedL_Det then
                cachedCG:FireServer(cachedL_Det, pHRP, cachedL_Weld)
                cachedL_Weld = cachedL_Det:FindFirstChild("LeftWeld") or cachedL_Det:FindFirstChildWhichIsA("Weld")
                if cachedCR and cachedL_Weld then cachedCR:FireServer(cachedL_Weld) end
                if cachedCD and cachedL_Weld then cachedCD:FireServer(cachedL_Weld) end
            end
        end)
    end)

    local killConn = RunService.Heartbeat:Connect(function()
        if not state.active then killConn:Disconnect() return end
        local char = player.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        pcall(function()
            hum.Health = 0
            hum:ChangeState(Enum.HumanoidStateType.Dead)
        end)
    end)
end

local function autoSitOnBlobman()
    local blobman = nil
    local spawned = Workspace:FindFirstChild(LocalPlayer.Name .. "SpawnedInToys")
    if spawned then blobman = spawned:FindFirstChild("CreatureBlobman") end
    
    if not blobman then
        local mt = ReplicatedStorage:FindFirstChild("MenuToys")
        local st = mt and mt:FindFirstChild("SpawnToyRemoteFunction")
        if st then
            local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            local spawnCF = myRoot and (myRoot.CFrame + Vector3.new(0, 5, 0)) or CFrame.new(0, 50, 0)
            st:InvokeServer("CreatureBlobman", spawnCF, Vector3.zero)
            task.wait(0.5)
            spawned = Workspace:FindFirstChild(LocalPlayer.Name .. "SpawnedInToys")
            if spawned then blobman = spawned:FindFirstChild("CreatureBlobman") end
        end
    end
    
    if blobman then
        local seat = blobman:FindFirstChild("VehicleSeat")
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
        if seat and hum then
            if seat.Occupant ~= hum then
                local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.CFrame = seat.CFrame + Vector3.new(0, 2, 0)
                    task.wait(0.1)
                end
                seat:Sit(hum)
                task.wait(0.3)
                OrionLib:MakeNotification({Name="ブロブマン", Content="自動乗車しました", Time=2})
            end
        end
    end
end

local function stopAura()
    bmkAuraEnabled = false
    if auraConn then auraConn:Disconnect() auraConn = nil end
    for uid in pairs(auraInRange) do stopThreads(uid) end
    auraInRange = {}
end

local function startAura()
    if auraConn then auraConn:Disconnect() auraConn = nil end
    auraInRange = {}
    
    task.spawn(autoSitOnBlobman)

    auraConn = RunService.Heartbeat:Connect(function()
        if not bmkAuraEnabled then 
            stopAura() 
            return 
        end
        local myHRP = HRP()
        if not myHRP then return end
        local myPos = myHRP.Position
        local nowInRange = {}
        
        if LocalPlayer.Character then
            local hum = LocalPlayer.Character:FindFirstChild("Humanoid")
            if hum and not hum.Sit then
                task.spawn(autoSitOnBlobman)
            end
        end

        for _, p in ipairs(Players:GetPlayers()) do
            if p == LocalPlayer then continue end
            local char = p.Character
            local pHRP = char and char:FindFirstChild("HumanoidRootPart")

            if pHRP then
                if (myPos - pHRP.Position).Magnitude > AURA_RADIUS then
                    if auraInRange[p.UserId] then stopThreads(p.UserId) end
                    continue
                end
            elseif not auraInRange[p.UserId] then
                continue
            end

            nowInRange[p.UserId] = true

            if not auraInRange[p.UserId] then
                startThreads(p, p.UserId)
            end
        end

        for uid in pairs(auraInRange) do
            if not nowInRange[uid] then stopThreads(uid) end
        end
        auraInRange = nowInRange
    end)
end

-- ================= ブロブマンキルALL（自動乗車機能付き） =================
local blobmanKillAllRunning = false

local function autoSitOnBlobmanForKillAll()
    local blobman = nil
    local spawned = Workspace:FindFirstChild(LocalPlayer.Name .. "SpawnedInToys")
    if spawned then blobman = spawned:FindFirstChild("CreatureBlobman") end
    
    if not blobman then
        local mt = ReplicatedStorage:FindFirstChild("MenuToys")
        local st = mt and mt:FindFirstChild("SpawnToyRemoteFunction")
        if st then
            local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            local spawnCF = myRoot and (myRoot.CFrame + Vector3.new(0, 5, 0)) or CFrame.new(0, 50, 0)
            st:InvokeServer("CreatureBlobman", spawnCF, Vector3.zero)
            task.wait(0.5)
            spawned = Workspace:FindFirstChild(LocalPlayer.Name .. "SpawnedInToys")
            if spawned then blobman = spawned:FindFirstChild("CreatureBlobman") end
        end
    end
    
    if blobman then
        local seat = blobman:FindFirstChild("VehicleSeat")
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
        if seat and hum then
            if seat.Occupant ~= hum then
                local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.CFrame = seat.CFrame + Vector3.new(0, 2, 0)
                    task.wait(0.1)
                end
                seat:Sit(hum)
                task.wait(0.3)
                OrionLib:MakeNotification({Name="ブロブマンキルALL", Content="自動乗車しました", Time=2})
            end
            return true
        end
    end
    return false
end

local function blobmanKillAllLoop()
    local mounted = autoSitOnBlobmanForKillAll()
    if not mounted then
        OrionLib:MakeNotification({Name="ブロブマンキルALL", Content="Blobmanの生成/乗車に失敗しました", Time=3})
        blobmanKillAllRunning = false
        return
    end
    
    while blobmanKillAllRunning do
        pcall(function()
            local myHRP = HRP()
            if LocalPlayer.Character then
                local hum = LocalPlayer.Character:FindFirstChild("Humanoid")
                if hum and not hum.Sit then
                    autoSitOnBlobmanForKillAll()
                end
            end
            
            if myHRP and cachedBlobman then
                for _, p in ipairs(Players:GetPlayers()) do
                    if not blobmanKillAllRunning then break end
                    if p == LocalPlayer then continue end
                    local char = p.Character
                    local pHRP = char and char:FindFirstChild("HumanoidRootPart")
                    local hum = char and char:FindFirstChildOfClass("Humanoid")
                    if pHRP and hum and hum.Health > 0 then
                        myHRP.CFrame = pHRP.CFrame * CFrame.new(0, 2, -3)
                        startThreads(p, p.UserId)
                        task.wait(0.3)
                        stopThreads(p.UserId)
                    end
                end
            else
                if not cachedBlobman then
                    refreshBlobman()
                    if not cachedBlobman then
                        autoSitOnBlobmanForKillAll()
                    end
                end
            end
        end)
        task.wait(0.5)
    end
end

-- ================= LOOP機能（元のソース完全維持） =================

-- 1. ターゲット選択システム
local function getPlayerFromDisplayName(displayName)
    if not displayName or displayName == "" then return nil end
    for _, player in ipairs(Players:GetPlayers()) do
        if player.DisplayName == displayName then return player end
    end
    return nil
end

local function updateLoopPlayerList()
    local displayNames = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            table.insert(displayNames, player.DisplayName)
        end
    end
    return displayNames
end

-- 2. LOOP設定変数
local LoopConfig = {
    TargetPlayer = nil,
    LoopKill = false,
    LoopVoid = false,
    LoopPoison = false,
    LoopRagdoll = false,
    LoopDeath = false,
    LoopBring = false,
    LoopPull = false
}

local LoopTimer = 0

-- 3. LOOP関数（元のソース完全再現）
local function Snipefunc(root, func, ...)
    if not root or not root.Parent then return end
    local pos = HRP().CFrame
    local args = {...}
    task.spawn(function()
        local parts = {"Head", "Torso", "HumanoidRootPart"}
        for _, p in pairs(parts) do
            local part = LocalPlayer.Character:FindFirstChild(p)
            if part then part.CanCollide = false end
        end
        local targetPos = root.Position
        HRP().CFrame = CFrame.new(targetPos.X, targetPos.Y - 6, targetPos.Z)
        task.wait(0.1)
        Workspace.CurrentCamera.CFrame = CFrame.lookAt(Workspace.CurrentCamera.CFrame.Position, root.Position)
        for _ = 1, 4 do
            SetNetworkOwner(root, HRP().CFrame)
            task.wait(0.05)
        end
        local look = Workspace.CurrentCamera.CFrame
        task.wait(0.1)
        func(unpack(args))
        Workspace.CurrentCamera.CFrame = look
        task.wait(0.1)
        for _, p in pairs(parts) do
            local part = LocalPlayer.Character:FindFirstChild(p)
            if part then part.CanCollide = true end
        end
        HRP().CFrame = pos
        Velocity(HRP(), Vector3.zero)
    end)
end

local function SnipeKill(target)
    local character = target.Character
    if not character then return end
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    Snipefunc(root, function()
        MoveTo(root, CFrame.new(4096, -75, 4096))
        Velocity(root, Vector3.new(0, -1000, 0))
    end)
end

local function SnipeVoid(target)
    local character = target.Character
    if not character then return end
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    Snipefunc(root, function()
        Velocity(root, Vector3.new(0, 10000, 0))
    end)
end

local function SnipePoison(target)
    local character = target.Character
    if not character then return end
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    Snipefunc(root, function()
        MoveTo(root, CFrame.new(58, -70, 271))
    end)
end

local function SnipeRagdoll(target)
    local character = target.Character
    if not character then return end
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    Snipefunc(root, function()
        local rpos = root.CFrame
        Velocity(root, Vector3.new(0, -64, 0))
        task.wait(0.1)
        HRP().CFrame = rpos
        Velocity(root, Vector3.zero)
    end)
end

local function SnipeDeath(target)
    local character = target.Character
    if not character then return end
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    Snipefunc(root, function()
        local hum = character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Dead) end
        task.wait(0.5)
        ungrab(root)
    end)
end

local function SnipeBring(target)
    local character = target.Character
    if not character then return end
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local pos = HRP().CFrame
    Snipefunc(root, function()
        task.wait(0.01)
        root.CFrame = pos
        task.wait(0.5)
        ungrab(root)
    end)
end

local function SnipePull(target)
    local character = target.Character
    if not character then return end
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    Snipefunc(root, function()
        local bp = Instance.new("BodyPosition")
        bp.Name = "PullBodyPosition"
        bp.MaxForce = Vector3.new(1e8, 1e8, 1e8)
        bp.P, bp.D = 1e6, 1e5
        bp.Parent = root
        task.spawn(function()
            while bp and bp.Parent do
                if not root or not root.Parent then break end
                local currentMyPos = HRP().Position
                bp.Position = currentMyPos
                root.CFrame = CFrame.new(currentMyPos)
                SetNetworkOwner(root)
                task.wait(0.05)
            end
        end)
        task.wait(0.1)
    end)
    task.delay(2, function()
        if root and root.Parent then
            local bp = root:FindFirstChild("PullBodyPosition")
            if bp then bp:Destroy() end
            ungrab(root)
        end
    end)
end

-- ================= =================
local autoStruggleCoroutine = nil

-- アンチ掴むV2用（元のコード完全維持）
local autoGucciT = false
local sitJumpT = false
local ragdollLoopD = false
local blobmanInstanceS = nil
local currentHouseS = 0
local permRagdollT = false
local permRagdollRunningS = false

-- アンチキック解除用（元のコード完全維持）
local antikickRunning = false
local antikickKCoroutine = nil

-- アンチブロブマン用（元のコード完全維持）
local antiblob = false

-- アンチブリングtest用（元のコード完全維持）
local blobLoopT2 = false
local currentBlobS = nil
local connection = nil

-- アンチファイヤ用（元のコード完全維持）
local antiburn = false

-- アンチ爆発用（元のコード完全維持）
local antiExplosionConnection = nil
local characterAddedConn = nil

-- アンチファイヤall用（元のコード完全維持）
local FF5 = false
local FF2 = nil
local FF3 = "FireExtinguisher"
local FCoroutine = nil

-- アンチラグ用（元のコード完全維持）
local antiLagT = false

-- アンチキック用（元のコード完全維持）
local antikick = false

-- Bring軽減用（元のコード完全維持）
local toggleBringEnabled = false
local R_raaa = -30
local bringCoroutine = nil

-- アンチ雪玉V2用（元のコード完全維持）
local aaaa = 20
local BSATCoroutine = nil
local SSCoroutine = nil

-- ================= Reskill用変数（キル系タブ用・元のコード完全維持） =================
local reskillLooping = false
local reskillSelectedTargetName = ""
local killAllLoop = false
local processedAll = {}
local noclip_reskill = false
local lastFlungCharacter = nil

local function setupAntiExplosion(character)
    local partOwner = character:WaitForChild("Humanoid"):FindFirstChild("Ragdolled")
    if partOwner then
        local partOwnerChangedConn
        partOwnerChangedConn = partOwner:GetPropertyChangedSignal("Value"):Connect(function()
            if partOwner.Value then
                for _, part in pairs(character:GetChildren()) do
                    if part:IsA("BasePart") then
                        part.Anchored = true
                    end
                end
            else
                for _, part in pairs(character:GetChildren()) do
                    if part:IsA("BasePart") then
                        part.Anchored = false
                    end
                end
            end
        end)
        antiExplosionConnection = partOwnerChangedConn
    end
end

-- ================= Reskill用関数（キル系タブ用・元のコード完全維持） =================
local function safe_release(targetPart)
    if not targetPart then return end
    local GE = ReplicatedStorage:FindFirstChild("GrabEvents")
    for i = 1, 3 do
        if GE and GE:FindFirstChild("DestroyGrabLine") then
            GE.DestroyGrabLine:FireServer(targetPart)
        end
        task.wait(0.01)
    end
end

local function execute_sequence(target)
    pcall(function()
        if not target or not target.Character then return end
        local myChar = LocalPlayer.Character
        local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
        local targetChar = target.Character
        local targetPart = targetChar:FindFirstChild("Torso") or targetChar:FindFirstChild("HumanoidRootPart")
        local targetHum = targetChar:FindFirstChild("Humanoid")
        local targetHead = targetChar:FindFirstChild("Head")
        local GE = ReplicatedStorage:FindFirstChild("GrabEvents")

        if myHRP and targetPart and targetHum and targetHum.Health > 0 then
            local originalPos = myHRP.CFrame
            noclip_reskill = true
            myHRP.Velocity = Vector3.zero
            myHRP.CFrame = targetPart.CFrame * CFrame.new(0, 0.5, -2)
            task.wait(0.15)
            
            if GE and GE:FindFirstChild("SetNetworkOwner") and targetHead then
                GE.SetNetworkOwner:FireServer(targetHead, myHRP.CFrame)
            end
            
            local grabOffset = CFrame.new(0.648761749, 0.748010159, -0.5, -0.580110908, 0, 0.814537942, 9.71004894e-08, 1, 6.91546092e-08, -0.814537942, 5.96046448e-08, -0.580110908)
            if GE and GE:FindFirstChild("CreateGrabLine") then
                GE.CreateGrabLine:FireServer(targetPart, grabOffset)
            end
            if GE and GE:FindFirstChild("ExtendGrabLine") then
                GE.ExtendGrabLine:FireServer(3.955392599105835)
            end
            
            targetChar:BreakJoints()
            task.wait(0.3)
            safe_release(targetPart)
            task.wait(0.1)
            
            myHRP.CFrame = originalPos
            noclip_reskill = false
        end
    end)
end

local function setRagdollF(state)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if char and hrp then
        local ragdollRemote = ReplicatedStorage:FindFirstChild("CharacterEvents") and ReplicatedStorage.CharacterEvents:FindFirstChild("RagdollRemote")
        if ragdollRemote then
            ragdollRemote:FireServer(hrp, state and 1 or 0)
        end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.PlatformStand = state
        end
    end
end

local function permRagdollLoopF()
    if permRagdollRunningS then return end
    permRagdollRunningS = true
    while permRagdollT do
        setRagdollF(true)
        task.wait()
    end
    permRagdollRunningS = false
    setRagdollF(false)
end

local function updateCurrentHouseF()
    local char = LocalPlayer.Character
    if not char then return end
    if char.Parent == workspace then
        currentHouseS = 0
    elseif char.Parent.Name == "PlayersInPlots" then
        local plotItems = workspace:FindFirstChild("PlotItems")
        if plotItems then
            local playersInPlots = plotItems:FindFirstChild("PlayersInPlots")
            if playersInPlots then
                for _, plot in pairs(workspace:FindFirstChild("Plots"):GetChildren()) do
                    if string.match(plot.Name, "^Plot[1-5]$") then
                        local playerInPlot = playersInPlots:FindFirstChild(LocalPlayer.Name)
                        if playerInPlot then
                            if plot.Name == "Plot1" then currentHouseS = 1
                            elseif plot.Name == "Plot2" then currentHouseS = 2
                            elseif plot.Name == "Plot3" then currentHouseS = 3
                            elseif plot.Name == "Plot4" then currentHouseS = 4
                            elseif plot.Name == "Plot5" then currentHouseS = 5
                            end
                            break
                        end
                    end
                end
            end
        end
    end
end

local function getBlobmanF()
    updateCurrentHouseF()
    if currentHouseS == 0 then
        local inv = workspace:FindFirstChild(LocalPlayer.Name .. "SpawnedInToys")
        if inv then return inv:FindFirstChild("CreatureBlobman") end
        return nil
    else
        local plotItems = workspace:FindFirstChild("PlotItems")
        if plotItems then
            local plot = plotItems:FindFirstChild("Plot" .. currentHouseS)
            if plot then return plot:FindFirstChild("CreatureBlobman") end
        end
        return nil
    end
end

local function spawnBlobmanF()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local spawnRemote = ReplicatedStorage:FindFirstChild("MenuToys") and ReplicatedStorage.MenuToys:FindFirstChild("SpawnToyRemoteFunction")
    if spawnRemote then
        pcall(function()
            spawnRemote:InvokeServer("CreatureBlobman", hrp.CFrame * CFrame.new(0, 0, -5), Vector3.new(0, -15.716, 0))
        end)
        task.wait()
        blobmanInstanceS = getBlobmanF()
    end
end

local function destroyBlobmanF()
    if blobmanInstanceS then
        if currentHouseS == 0 then
            local destroyRemote = ReplicatedStorage:FindFirstChild("MenuToys") and ReplicatedStorage.MenuToys:FindFirstChild("DestroyToy")
            if destroyRemote then
                pcall(function()
                    destroyRemote:FireServer(blobmanInstanceS)
                end)
            end
            blobmanInstanceS = nil
        else
            if blobmanInstanceS and blobmanInstanceS:FindFirstChild("HumanoidRootPart") then
                local plots = workspace:FindFirstChild("Plots")
                if plots then
                    local plot = plots:FindFirstChild("Plot" .. currentHouseS)
                    if plot and plot:FindFirstChild("TeslaCoil") and plot.TeslaCoil:FindFirstChild("ZapPart") then
                        blobmanInstanceS.HumanoidRootPart.CFrame = plot.TeslaCoil.ZapPart.CFrame
                    end
                end
            end
            blobmanInstanceS = nil
        end
    end
end

local function ragdollLoopF()
    if ragdollLoopD then return end
    ragdollLoopD = true
    while sitJumpT do
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if char and hrp then
            local ragdollRemote = ReplicatedStorage:FindFirstChild("CharacterEvents") and ReplicatedStorage.CharacterEvents:FindFirstChild("RagdollRemote")
            if ragdollRemote then
                ragdollRemote:FireServer(hrp, 0)
            end
        end
        task.wait()
    end
    ragdollLoopD = false
end

local function sitJumpF()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not char or not hum then return end
    local startTime = tick()
    while autoGucciT and tick() - startTime < 0.9 do
        if blobmanInstanceS then
            local seat = blobmanInstanceS:FindFirstChildWhichIsA("VehicleSeat")
            if seat and seat.Occupant ~= hum then
                seat:Sit(hum)
            end
        end
        task.wait()
        if char and hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
        task.wait()
    end
    if blobmanInstanceS then
        destroyBlobmanF()
    end
    autoGucciT = false
    sitJumpT = false
end

local function antikickK()
    local localPlayerCharacter = LocalPlayer.Character
    local playerCharacter = localPlayerCharacter
    local function spawnItemCf(itemName, cframe)
        task.spawn(function()
            local rotation = Vector3.new(0, 0, 0)
            local spawnRemote = ReplicatedStorage:FindFirstChild("MenuToys") and ReplicatedStorage.MenuToys:FindFirstChild("SpawnToyRemoteFunction")
            if spawnRemote then
                pcall(function()
                    spawnRemote:InvokeServer(itemName, cframe, rotation)
                end)
            end
        end)
    end
    
    while antikickRunning do
        local success, err = pcall(function()
            local toysFolder = workspace:FindFirstChild(LocalPlayer.Name .. "SpawnedInToys")
            if toysFolder and toysFolder:FindFirstChild("SprayCanWD") then
                local destroyToy = ReplicatedStorage:FindFirstChild("MenuToys") and ReplicatedStorage.MenuToys:FindFirstChild("DestroyToy")
                if destroyToy then
                    destroyToy:FireServer(toysFolder:FindFirstChild("SprayCanWD"))
                end
                task.wait(0.5)
            end
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head") then
                spawnItemCf("SprayCanWD", LocalPlayer.Character.Head.CFrame)
                task.wait(0.001)
                local toysFolder2 = workspace:FindFirstChild(LocalPlayer.Name .. "SpawnedInToys")
                if toysFolder2 then
                    local campfire = toysFolder2:FindFirstChild("SprayCanWD")
                    if campfire then
                        local StickyRemoverPart = campfire:FindFirstChild("StickyRemoverPart")
                        if StickyRemoverPart then
                            StickyRemoverPart.Size = Vector3.new(10, 10, 10)
                            local setNetworkOwner = ReplicatedStorage:FindFirstChild("GrabEvents") and ReplicatedStorage.GrabEvents:FindFirstChild("SetNetworkOwner")
                            if setNetworkOwner then
                                setNetworkOwner:FireServer(StickyRemoverPart, StickyRemoverPart.CFrame)
                            end
                            task.wait(0.001)
                            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Torso") then
                                local originalPosition = LocalPlayer.Character.Torso.Position
                                if LocalPlayer.Character:FindFirstChild("Humanoid") then
                                    LocalPlayer.Character:MoveTo(originalPosition)
                                end
                                local bodyPosition = Instance.new("BodyPosition")
                                bodyPosition.P = 20000
                                bodyPosition.Position = Vector3.new(0, 600, 0)
                                bodyPosition.Parent = campfire.Main
                                while antikickRunning do
                                    for _, player in pairs(Players:GetPlayers()) do
                                        pcall(function()
                                            bodyPosition.Position = Vector3.new(300, 600, 0)
                                            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player ~= LocalPlayer then
                                                StickyRemoverPart.Position = player.Character.HumanoidRootPart.Position or (player.Character:FindFirstChild("Head") and player.Character.Head.Position)
                                                task.wait(0.001)
                                            end
                                        end)
                                    end
                                    task.wait(0.001)
                                end
                            end
                        end
                    end
                end
            end
        end)
        if not success then end
        task.wait(0.001)
    end
end

local function SetAntiBlobman(enabled)
    local function processPart(part)
        local invalid = part.Name == "LeftWeld" or part.Name == "RightWeld" or part.Name == "LeftAlignOrientation" or part.Name == "RightAlignOrientation"
        if invalid and part.Parent and part.Parent.Parent and part.Parent.Parent.Parent ~= Workspace:FindFirstChild(LocalPlayer.Name) then
            part.Enabled = not enabled
        end
    end
    for _, part in pairs(Workspace:GetDescendants()) do
        processPart(part)
    end
end

local BLOB_NAME = "CreatureBlobman"
local SEAT_NAME = "VehicleSeat"
local WELD_NAME = "SeatWeld"
local HRP_NAME = "HumanoidRootPart"
local DETECTOR_SUFFIXES = {"Left", "Right"}

local function updateCurrentBlobmanF()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild(HRP_NAME)
    if not hrp then return end
    local st = workspace:FindFirstChild("st")
    for _, player in pairs(Players:GetPlayers()) do
        if st then
            local toysFolderSt = st:FindFirstChild(player.Name .. "SpawnedInToys")
            if toysFolderSt then
                for _, blobs in ipairs(toysFolderSt:GetChildren()) do
                    if blobs.Name == BLOB_NAME and blobs:FindFirstChild(SEAT_NAME) and blobs[SEAT_NAME]:FindFirstChild(WELD_NAME) and blobs[SEAT_NAME][WELD_NAME].Part1 == hrp then
                        currentBlobS = blobs
                        return
                    end
                end
            end
        end
        local toysFolderWS = workspace:FindFirstChild(player.Name .. "SpawnedInToys")
        if toysFolderWS then
            for _, blobs in ipairs(toysFolderWS:GetChildren()) do
                if blobs.Name == BLOB_NAME and blobs:FindFirstChild(SEAT_NAME) and blobs[SEAT_NAME]:FindFirstChild(WELD_NAME) and blobs[SEAT_NAME][WELD_NAME].Part1 == hrp then
                    currentBlobS = blobs
                    return
                end
            end
        end
    end
end

local function blobDropF(blob, target)
    for _, side in ipairs(DETECTOR_SUFFIXES) do
        local weld = blob:FindFirstChild(side .. "Detector")
        weld = weld and weld:FindFirstChild(side .. "Weld")
        if weld and blob:FindFirstChild("BlobmanSeatAndOwnerScript") and blob.BlobmanSeatAndOwnerScript:FindFirstChild("CreatureDrop") then
            blob.BlobmanSeatAndOwnerScript.CreatureDrop:FireServer(weld, target)
        end
    end
end

local function loopdrop()
    connection = RunService.Heartbeat:Connect(function()
        updateCurrentBlobmanF()
        if currentBlobS then
            local blob = currentBlobS
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    local hrp = player.Character:FindFirstChild(HRP_NAME)
                    if hrp then
                        blobDropF(blob, hrp)
                    end
                end
            end
        end
    end)
end

local connections = {}
local protectionEnabled = false

local function clearConnections()
    for _, conn in ipairs(connections) do
        conn:Disconnect()
    end
    connections = {}
end

local function protectHumanoid(humanoid)
    humanoid.BreakJointsOnDeath = false
    humanoid.AutoRotate = true
    humanoid.PlatformStand = false
    table.insert(connections, humanoid.HealthChanged:Connect(function(health)
        if protectionEnabled and health <= 0 then
            humanoid.Health = 1
        end
    end))
    table.insert(connections, humanoid:GetPropertyChangedSignal("AutoRotate"):Connect(function()
        if protectionEnabled and humanoid.AutoRotate == false then
            humanoid.AutoRotate = true
        end
    end))
    table.insert(connections, humanoid:GetPropertyChangedSignal("PlatformStand"):Connect(function()
        if protectionEnabled and humanoid.PlatformStand == true then
            humanoid.PlatformStand = false
        end
    end))
    table.insert(connections, RunService.RenderStepped:Connect(function()
        if protectionEnabled then
            if humanoid.Sit and humanoid.SeatPart == nil then
                humanoid.Sit = false
            end
        end
    end))
end

local function onCharacter(char)
    local humanoid = char:WaitForChild("Humanoid", 5)
    if humanoid and protectionEnabled then
        protectHumanoid(humanoid)
    end
end

local function setProtection(state)
    protectionEnabled = state
    if protectionEnabled then
        local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
        if humanoid then
            protectHumanoid(humanoid)
        end
    else
        clearConnections()
    end
end

local function processPart(part)
    local character = LocalPlayer.Character
    if not toggleBringEnabled or not character or not character:FindFirstChild("Head") or not part:IsA("BasePart") then
        return
    end
    if part.Anchored or part:IsDescendantOf(character) then
        return
    end
    if part.Name == "Torso" or part.Name == "Head" or part.Name == "Right Arm" or part.Name == "Left Arm" or part.Name == "Right Leg" or part.Name == "Left Leg" or part.Name == "HumanoidRootPart" then
        return
    end
    if not part:FindFirstChildOfClass("BodyPosition") then
        local ForceInstance = Instance.new("BodyPosition")
        ForceInstance.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        ForceInstance.Position = Vector3.new(0, R_raaa, 0)
        ForceInstance.P = 6000000000000
        ForceInstance.D = 6000000
        ForceInstance.Parent = part
    end
end

local function processAllParts()
    for _, part in pairs(Workspace:GetDescendants()) do
        processPart(part)
    end
end

local function cleanupBringReduction()
    for _, part in pairs(Workspace:GetDescendants()) do
        local existingForce = part:FindFirstChildOfClass("BodyPosition")
        if existingForce then
            existingForce:Destroy()
        end
    end
end

local function bringLoop()
    while toggleBringEnabled do
        pcall(function()
            local character = LocalPlayer.Character
            if character and character:FindFirstChild("Head") then
                local head = character.Head
                for _, part in pairs(Workspace:GetDescendants()) do
                    if part:IsA("BasePart") and not part.Anchored and not part:IsDescendantOf(character) then
                        if part.Name ~= "Torso" and part.Name ~= "Head" and part.Name ~= "Right Arm" and part.Name ~= "Left Arm" and part.Name ~= "Right Leg" and part.Name ~= "Left Leg" and part.Name ~= "HumanoidRootPart" then
                            if not part:FindFirstChildOfClass("BodyPosition") then
                                local ForceInstance = Instance.new("BodyPosition")
                                ForceInstance.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                                ForceInstance.Position = Vector3.new(0, R_raaa, 0)
                                ForceInstance.P = 6000000000000
                                ForceInstance.D = 6000000
                                ForceInstance.Parent = part
                            end
                        end
                    end
                end
            end
        end)
        task.wait(0.5)
    end
end

-- ================= ウィンドウ =================
local Window = OrionLib:MakeWindow({
    Name = "ササミックスHUB FTAP🕊️ + オーラ統合版 + LOOP機能",
    HidePremium = true,
    SaveConfig = false,
    IntroEnabled = true,
    IntroText = "Sasamix Hub FTAP Loaded! + Aura System + LOOP",
    IntroIcon = "rbxassetid://4483345998"
})

-- プレイヤーリスト取得関数
local function getPlayers()
    local t = {}
    for _,p in pairs(Players:GetPlayers()) do if p ~= LocalPlayer then table.insert(t, p.DisplayName.." (@"..p.Name..")") end end
    return t
end

-- プレイヤードロップダウン常時更新用
local playerDropdown = nil
local lastPlayerList = {}

local function updatePlayerDropdown()
    local currentPlayers = getPlayers()
    local changed = false
    if #currentPlayers ~= #lastPlayerList then
        changed = true
    else
        for i, v in ipairs(currentPlayers) do
            if lastPlayerList[i] ~= v then
                changed = true
                break
            end
        end
    end
    if changed and playerDropdown then
        lastPlayerList = currentPlayers
        playerDropdown:Refresh(currentPlayers, true)
    end
end

-- ================= タブ0: 掴む =================
local GrabTab = Window:MakeTab({Name = "掴む", Icon = "rbxassetid://73570431850302"})

GrabTab:AddToggle({
    Name = "投げる",
    Default = false,
    Callback = function(enabled)
        if enabled then
            strengthConnection = Workspace.ChildAdded:Connect(function(model)
                if model.Name == "GrabParts" then
                    local partToImpulse = model:FindFirstChild("GrabPart")
                    if partToImpulse and partToImpulse:FindFirstChild("WeldConstraint") then
                        partToImpulse = partToImpulse.WeldConstraint.Part1
                        if partToImpulse then
                            local velocityObj = Instance.new("BodyVelocity", partToImpulse)
                            model:GetPropertyChangedSignal("Parent"):Connect(function()
                                if not model.Parent then
                                    local lastInput = UserInputService:GetLastInputType()
                                    if lastInput == Enum.UserInputType.MouseButton2 or lastInput == Enum.UserInputType.Touch then
                                        velocityObj.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                                        velocityObj.Velocity = Workspace.CurrentCamera.CFrame.LookVector * nageru
                                        Debris:AddItem(velocityObj, 1)
                                    else
                                        velocityObj:Destroy()
                                    end
                                end
                            end)
                        end
                    end
                end
            end)
        elseif strengthConnection then
            strengthConnection:Disconnect()
            strengthConnection = nil
        end
    end
})

GrabTab:AddSlider({
    Name = "投げる強さ",
    Min = 300,
    Max = 4000,
    Default = 400,
    Callback = function(value)
        nageru = value
    end
})

GrabTab:AddToggle({
    Name = "毒掴む",
    Default = false,
    Callback = function(enabled)
        if enabled then
            poisonGrabCoroutine = coroutine.create(function()
                grabHandler("poison")
            end)
            coroutine.resume(poisonGrabCoroutine)
        else
            if poisonGrabCoroutine then
                coroutine.close(poisonGrabCoroutine)
                poisonGrabCoroutine = nil
                for _, part in pairs(poisonHurtParts) do
                    part.Position = Vector3.new(0, -200, 0)
                end
            end
        end
    end
})

GrabTab:AddToggle({
    Name = "Radioactive掴む",
    Default = false,
    Callback = function(enabled)
        if enabled then
            ufoGrabCoroutine = coroutine.create(function()
                grabHandler("radioactive")
            end)
            coroutine.resume(ufoGrabCoroutine)
        else
            if ufoGrabCoroutine then
                coroutine.close(ufoGrabCoroutine)
                ufoGrabCoroutine = nil
                for _, part in pairs(paintPlayerParts) do
                    part.Position = Vector3.new(0, -200, 0)
                end
            end
        end
    end
})

GrabTab:AddToggle({
    Name = "燃やす掴む",
    Default = false,
    Callback = function(enabled)
        if enabled then
            fireGrabCoroutine = coroutine.create(fireGrab)
            coroutine.resume(fireGrabCoroutine)
        else
            if fireGrabCoroutine then
                coroutine.close(fireGrabCoroutine)
                fireGrabCoroutine = nil
            end
        end
    end
})

GrabTab:AddToggle({
    Name = "キルグラブ",
    Default = false,
    Callback = function(Value)
        GrabModes.KillGrab = Value
    end
})

GrabTab:AddToggle({
    Name = "Noclipグラブ",
    Default = false,
    Callback = function(Value)
        GrabModes.NoclipGrab = Value
    end
})

GrabTab:AddToggle({
    Name = "キル掴む",
    Default = false,
    Callback = function(Value)
        GrabToggles.KillGrab = Value
        toggleGrab("KillGrab", "Kill")
    end
})

GrabTab:AddToggle({
    Name = "上に上がる掴む",
    Default = false,
    Callback = function(Value)
        GrabToggles.SkyGrab = Value
        toggleGrab("SkyGrab", "Sky")
    end
})

GrabTab:AddToggle({
    Name = "下に下がる掴む",
    Default = false,
    Callback = function(Value)
        GrabToggles.DownGrab = Value
        toggleGrab("DownGrab", "Down")
    end
})

GrabTab:AddToggle({
    Name = "高さを保ちながら掴む",
    Default = false,
    Callback = function(Value)
        GrabToggles.StableGrab = Value
        toggleGrab("StableGrab", "Stable")
    end
})

-- ================= タブ1: バリア破壊 =================
local BarrierTab = Window:MakeTab({Name = "バリア破壊", Icon = "rbxassetid://4483362458"})
BarrierTab:AddSection({Name = "バリア破壊機能"})
BarrierTab:AddButton({Name = "バリア破壊実行", Callback = function()
    local player = LocalPlayer
    if not player then return end
    if not (player.Character and player.Character:FindFirstChild("HumanoidRootPart")) then  
        OrionLib:MakeNotification({Name="エラー", Content="Character not ready", Time=4})  
        return  
    end  
    local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")  
    local originalWalkSpeed,originalJumpPower  
    if humanoid then  
        originalWalkSpeed=humanoid.WalkSpeed  
        originalJumpPower=humanoid.JumpPower  
        pcall(function() humanoid.WalkSpeed=0 humanoid.JumpPower=0 end)  
    end  
    local success,err=pcall(function()  
        local MenuToys=ReplicatedStorage:WaitForChild("MenuToys")  
        local hrp=player.Character.HumanoidRootPart  
        local originalCFrame=hrp.CFrame  
        hrp.CFrame=CFrame.new(246.052,-7.35,431.821)  
        task.wait(0.05)  
        MenuToys.SpawnToyRemoteFunction:InvokeServer("InstrumentWoodwindOcarina",CFrame.new(184.148834,-5.54824972,498.136749,0.829037189,-0.214714944,0.516328275,0,0.923344612,0.383972496,-0.559193552,-0.318327487,0.765486956),Vector3.new(0,34,0))  
        task.wait(0.2)  
        local toyFolder=workspace:FindFirstChild(player.Name.."SpawnedInToys")  
        if not toyFolder then error("SpawnedInToys folder not found") end  
        local ocarina=toyFolder:FindFirstChild("InstrumentWoodwindOcarina")  
        if not ocarina then error("InstrumentWoodwindOcarina not found") end  
        if ocarina:FindFirstChild("HoldPart") and ocarina.HoldPart:FindFirstChild("HoldItemRemoteFunction") then  
            pcall(function() ocarina.HoldPart.HoldItemRemoteFunction:InvokeServer(ocarina,player.Character) end)  
            task.wait(0.2)  
        end  
        player.Character.HumanoidRootPart.CFrame=CFrame.new(304.06,25.77,488.54)  
        task.wait(0.05)  
        if MenuToys:FindFirstChild("DestroyToy") then MenuToys.DestroyToy:FireServer(ocarina) else error("DestroyToy event not found") end  
        task.wait(0.05)  
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then player.Character.HumanoidRootPart.CFrame=originalCFrame end  
        OrionLib:MakeNotification({Name="バリア破壊",Content="成功",Time=3})  
    end)  
    local function tryRestore()  
        if originalWalkSpeed==nil and originalJumpPower==nil then return end  
        local curHum=player.Character and player.Character:FindFirstChildOfClass("Humanoid")  
        if curHum then pcall(function() if originalWalkSpeed~=nil then curHum.WalkSpeed=originalWalkSpeed end if originalJumpPower~=nil then curHum.JumpPower=originalJumpPower end end) end  
    end  
    tryRestore()  
    if not success then OrionLib:MakeNotification({Name="エラー",Content=tostring(err),Time=6}) end
end})

-- ================= タブ2: キック =================
local KickTab = Window:MakeTab({Name = "キック", Icon = "rbxassetid://4483345998"})
local Label = KickTab:AddParagraph("選択中", "なし")

playerDropdown = KickTab:AddDropdown({
    Name = "プレイヤー選択", 
    Options = getPlayers(), 
    Callback = function(v)
        if v then
            local username = v:match("@(.+)%)")
            selectedPlayer = username
            selectedActionTargetName = username
            local p = Players:FindFirstChild(username)
            if p then 
                Label:Set("選択中", p.DisplayName.." @"..p.Name) 
            end
        end
    end
})

lastPlayerList = getPlayers()

task.spawn(function()
    while true do
        task.wait(1)
        updatePlayerDropdown()
    end
end)

KickTab:AddToggle({
    Name = "Blobman Kick",
    Default = false,
    Callback = function(v)
        levitateRunning = v
        if not v then return end

        local target = Players:FindFirstChild(selectedActionTargetName)
        
        if target and target ~= LocalPlayer and target.Character and target.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local blobman = nil
            local spawned = Workspace:FindFirstChild(LocalPlayer.Name .. "SpawnedInToys")
            if spawned then blobman = spawned:FindFirstChild("CreatureBlobman") end
            
            if not blobman then
                local mt = ReplicatedStorage:FindFirstChild("MenuToys")
                local st = mt and mt:FindFirstChild("SpawnToyRemoteFunction")
                if st then
                    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    local spawnCF = myRoot and (myRoot.CFrame + Vector3.new(0, 5, 0)) or CFrame.new(0, 50, 0)
                    st:InvokeServer("CreatureBlobman", spawnCF, Vector3.zero)
                    task.wait(0.5)
                    spawned = Workspace:FindFirstChild(LocalPlayer.Name .. "SpawnedInToys")
                    if spawned then blobman = spawned:FindFirstChild("CreatureBlobman") end
                end
            end

            if not blobman then
                for _, obj in ipairs(Workspace:GetChildren()) do
                    if obj.Name == "CreatureBlobman" and obj:FindFirstChild("VehicleSeat") then
                        blobman = obj
                        break
                    end
                end
            end
            
            if blobman then
                local scriptObj = blobman:FindFirstChild("BlobmanSeatAndOwnerScript")
                local grabRemote = scriptObj and scriptObj:FindFirstChild("CreatureGrab")
                local dropRemote = scriptObj and scriptObj:FindFirstChild("CreatureDrop")

                local lDet = blobman:FindFirstChild("LeftDetector")
                local rDet = blobman:FindFirstChild("RightDetector")
                local lWeld = lDet and (lDet:FindFirstChild("LeftWeld") or lDet:FindFirstChild("RigidConstraint"))
                local rWeld = rDet and (rDet:FindFirstChild("RightWeld") or rDet:FindFirstChild("RigidConstraint"))
                
                local seat = blobman:FindFirstChild("VehicleSeat")
                local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
                if seat and hum then
                    if seat.Occupant ~= hum then
                        LocalPlayer.Character.HumanoidRootPart.CFrame = seat.CFrame + Vector3.new(0, 2, 0)
                        seat:Sit(hum)
                        task.wait(0.3)
                    end
                end
                
                if grabRemote and dropRemote and ((lDet and lWeld) or (rDet and rWeld)) then
                    OrionLib:MakeNotification({ Name = "実行", Content = "Blobman Kick Loop", Time = 3 })

                    task.spawn(function()
                        local GE = ReplicatedStorage:WaitForChild("GrabEvents")
                        local blobRoot = blobman:FindFirstChild("HumanoidRootPart") or blobman.PrimaryPart
                        local SavedPos = blobRoot.CFrame
                        
                        local Det = rDet or lDet
                        local Weld = rWeld or lWeld
                        
                        local bringStart = tick()
                        while tick() - bringStart < 0.35 do
                            if not levitateRunning or not blobman or not blobman.Parent then break end
                            if target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                                local tRoot = target.Character.HumanoidRootPart
                                blobRoot.CFrame = tRoot.CFrame
                                blobRoot.AssemblyLinearVelocity = Vector3.zero
                                
                                pcall(function()
                                    if Det then grabRemote:FireServer(Det, tRoot, Weld) end
                                    GE.CreateGrabLine:FireServer(tRoot, Vector3.zero, tRoot.Position, false)
                                    GE.SetNetworkOwner:FireServer(tRoot, blobRoot.CFrame)
                                end)
                            end
                            RunService.Heartbeat:Wait()
                        end
                        
                        if blobRoot then
                            blobRoot.CFrame = SavedPos
                            blobRoot.AssemblyLinearVelocity = Vector3.zero
                            task.wait(0.05)
                        end
                        
                        while levitateRunning and blobman and blobman.Parent do
                            if not target or not target.Parent or not target.Character then break end
                            
                            local tChar = target.Character
                            local tRoot = tChar:FindFirstChild("HumanoidRootPart")
                            local tHum = tChar:FindFirstChild("Humanoid")
                            
                            if tRoot and tHum and tHum.Health > 0 and blobRoot then
                                blobRoot.CFrame = SavedPos
                                blobRoot.AssemblyLinearVelocity = Vector3.zero
                                
                                local lockPos = SavedPos * CFrame.new(0, 23, 0)
                                tRoot.CFrame = lockPos
                                tRoot.AssemblyLinearVelocity = Vector3.zero
                                tRoot.AssemblyAngularVelocity = Vector3.zero
                                
                                pcall(function()
                                    tHum.PlatformStand = true
                                    tHum.Sit = true
                                    GE.SetNetworkOwner:FireServer(tRoot, lockPos)
                                    
                                    local currentWeld = Det:FindFirstChild("RightWeld") or Det:FindFirstChild("LeftWeld") or Det:FindFirstChildWhichIsA("Weld") or Det:FindFirstChild("RigidConstraint")
                                    if currentWeld then
                                        dropRemote:FireServer(currentWeld)
                                    end
                                    
                                    GE.DestroyGrabLine:FireServer(tRoot)
                                    if Det then grabRemote:FireServer(Det, tRoot, Weld) end
                                    GE.CreateGrabLine:FireServer(tRoot, Vector3.zero, tRoot.Position, false)
                                end)
                            else
                                if blobRoot then
                                    blobRoot.CFrame = SavedPos
                                    blobRoot.AssemblyLinearVelocity = Vector3.zero
                                end
                            end
                            RunService.Heartbeat:Wait()
                        end
                        
                        if blobRoot then
                            blobRoot.CFrame = SavedPos
                            blobRoot.AssemblyLinearVelocity = Vector3.zero
                        end
                    end)
                else
                    local missing = {}
                    if not grabRemote then table.insert(missing, "CreatureGrab") end
                    if not dropRemote then table.insert(missing, "CreatureDrop") end
                    if not (lDet or rDet) then table.insert(missing, "Detector") end
                    if not (lWeld or rWeld) then table.insert(missing, "Weld/Constraint") end
                    OrionLib:MakeNotification({ Name = "エラー", Content = "不足: " .. table.concat(missing, ", "), Time = 5 })
                end
            else
                OrionLib:MakeNotification({ Name = "エラー", Content = "Blobmanが見つかりません (おもちゃを出してください)", Time = 3 })
            end
        end
    end
})

KickTab:AddButton({Name = "バグ修正", Callback = function()
    local spawned = Workspace:FindFirstChild(LocalPlayer.Name .. "SpawnedInToys")
    if spawned then
        local blobman = spawned:FindFirstChild("CreatureBlobman")
        if blobman then
            local dt = ReplicatedStorage:FindFirstChild("MenuToys") and ReplicatedStorage.MenuToys:FindFirstChild("DestroyToy")
            if dt then dt:FireServer(blobman) end
        end
    end
    task.wait(0.5)
    local mt = ReplicatedStorage:FindFirstChild("MenuToys")
    local st = mt and mt:FindFirstChild("SpawnToyRemoteFunction")
    if st then
        local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local spawnCF = myRoot and (myRoot.CFrame + Vector3.new(0, 5, 0)) or CFrame.new(0, 50, 0)
        st:InvokeServer("CreatureBlobman", spawnCF, Vector3.zero)
    end
    OrionLib:MakeNotification({ Name = "バグ修正", Content = "Blobmanを再生成しました", Time = 2 })
end})

KickTab:AddSection({ Name = "Kick All (ホワイトリスト対応)" })

local KickAllWhitelist = {}
local KickAllWhitelistLabel = nil
local KickAllWhitelistDropdown = nil
local lastWhitelistPlayerList = {}

local function IsKickAllWhitelisted(player)
    if not player then return false end
    return KickAllWhitelist[player.Name] == true
end

local function GetNonWhitelistedPlayersForKickAll()
    local list = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and not IsKickAllWhitelisted(player) then
            table.insert(list, player)
        end
    end
    return list
end

local function GetPlayerListForKickAllWhitelist()
    local list = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            table.insert(list, p.DisplayName .. " (@" .. p.Name .. ")")
        end
    end
    return list
end

local function UpdateKickAllWhitelistDropdownAuto()
    if not KickAllWhitelistDropdown then return end
    local currentPlayers = GetPlayerListForKickAllWhitelist()
    
    local changed = false
    if #currentPlayers ~= #lastWhitelistPlayerList then
        changed = true
    else
        for i, v in ipairs(currentPlayers) do
            if lastWhitelistPlayerList[i] ~= v then
                changed = true
                break
            end
        end
    end
    
    if changed then
        lastWhitelistPlayerList = currentPlayers
        KickAllWhitelistDropdown:Refresh(currentPlayers, true)
    end
end

local function UpdateKickAllWhitelistUI()
    local list = {}
    for name, _ in pairs(KickAllWhitelist) do
        table.insert(list, name)
    end
    if #list == 0 then
        if KickAllWhitelistLabel then
            KickAllWhitelistLabel:Set("保護リスト", "現在ホワイトリストは空です")
        end
    else
        if KickAllWhitelistLabel then
            KickAllWhitelistLabel:Set("保護リスト", "保護中: " .. table.concat(list, ", "))
        end
    end
end

local function GetMyRootForKickAll()
    return LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
end

local function GetMyBlobmanForKickAll()
    for _, v in pairs(Workspace:GetDescendants()) do
        if v.Name == "CreatureBlobman" then
            local seat = v:FindFirstChild("VehicleSeat")
            if seat and seat:FindFirstChild("SeatWeld") then
                local p1 = seat.SeatWeld.Part1
                if p1 and p1:IsDescendantOf(LocalPlayer.Character) then return v end
            end
        end
    end
    return nil
end

local function WaitForBlobmanAndRideForKickAll()
    for i = 1, 30 do
        task.wait(0.1)
        local folder = workspace:FindFirstChild(LocalPlayer.Name .. "SpawnedInToys")
        if folder then
            local blob = folder:FindFirstChild("CreatureBlobman")
            if blob then
                local seat = blob:FindFirstChild("VehicleSeat")
                if seat then
                    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                    if hum then
                        seat:Sit(hum)
                        task.wait(0.2)
                        if hum.SeatPart == seat then
                            return blob
                        end
                    end
                end
            end
        end
    end
    return nil
end

local function SpawnAndRideBlobmanForKickAll()
    local root = GetMyRootForKickAll()
    if not root then return nil end
    local spawnPos = root.CFrame * CFrame.new(0, 0, -8)
    local spawnRemote = ReplicatedStorage:FindFirstChild("MenuToys")
    if spawnRemote then
        pcall(function()
            spawnRemote.SpawnToyRemoteFunction:InvokeServer("CreatureBlobman", spawnPos, Vector3.new(0, 27.4, 0))
        end)
    end
    return WaitForBlobmanAndRideForKickAll()
end

local function TeleportToTargetForKickAll(targetRoot)
    local myRoot = GetMyRootForKickAll()
    if myRoot and targetRoot then
        myRoot.CFrame = targetRoot.CFrame
        task.wait(0.02)
    end
end

local function SetNetworkOwnerForKickAll(part)
    if not part then return end
    pcall(function()
        if ReplicatedStorage and ReplicatedStorage.GrabEvents then
            local root = GetMyRootForKickAll()
            if root then
                ReplicatedStorage.GrabEvents.SetNetworkOwner:FireServer(part, root.CFrame)
            end
        end
    end)
end

local function DoGrabForKickAll(targetPart)
    if not targetPart then return false end
    local grabEvents = ReplicatedStorage:FindFirstChild("GrabEvents")
    if not grabEvents then return false end
    pcall(function()
        if grabEvents:FindFirstChild("SetNetworkOwner") then
            grabEvents.SetNetworkOwner:FireServer(targetPart, CFrame.new(targetPart.Position))
        end
        if grabEvents:FindFirstChild("DestroyGrabLine") then
            grabEvents.DestroyGrabLine:FireServer(targetPart)
        end
    end)
    return true
end

local function AnchorBlobForKickAll(blob)
    if not blob then return end
    for _, part in ipairs(blob:GetDescendants()) do
        if part:IsA("BasePart") then
            pcall(function() part.Anchored = true end)
        end
    end
end

local function UnanchorBlobForKickAll(blob)
    if not blob then return end
    for _, part in ipairs(blob:GetDescendants()) do
        if part:IsA("BasePart") then
            pcall(function() part.Anchored = false end)
        end
    end
end

local function GrabReleaseForKickAll(blob, targetPlayer)
    if not blob or not targetPlayer or not targetPlayer.Character or IsKickAllWhitelisted(targetPlayer) then return end
    local targetRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not targetRoot then return end
    local script = blob:FindFirstChild("BlobmanSeatAndOwnerScript")
    if not script then return end
    pcall(function()
        if script:FindFirstChild("CreatureGrab") then
            script.CreatureGrab:FireServer(blob.LeftDetector, targetRoot, blob.LeftDetector.LeftWeld)
        end
        if script:FindFirstChild("CreatureRelease") then
            script.CreatureRelease:FireServer(blob.LeftDetector.LeftWeld)
        end
    end)
end

local function KickBothForKickAll(blob, targetPlayer)
    if not blob or not targetPlayer or not targetPlayer.Character or IsKickAllWhitelisted(targetPlayer) then return end
    local targetRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not targetRoot then return end
    local script = blob:FindFirstChild("BlobmanSeatAndOwnerScript")
    if not script or not script:FindFirstChild("CreatureGrab") then return end
    pcall(function()
        script.CreatureGrab:FireServer(blob.LeftDetector, targetRoot, blob.LeftDetector.LeftWeld)
        script.CreatureGrab:FireServer(blob.RightDetector, targetRoot, blob.RightDetector.RightWeld)
    end)
end

local kickAllPlacementMode = "circle"
local kickAllCircleRadius = 25
local kickAllInnerRadius = 15
local kickAllOuterRadius = 35
local kickAllSpiralStart = 10
local kickAllSpiralEnd = 40
local kickAllPlayerY = 100
local kickAllSelfY = 100

local function GetCirclePositionsForKickAll(center, radius, count)
    local positions = {}
    if count == 0 then return positions end
    local angleStep = (math.pi * 2) / count
    for i = 1, count do
        local angle = (i - 1) * angleStep
        local x = center.X + radius * math.cos(angle)
        local z = center.Z + radius * math.sin(angle)
        table.insert(positions, {x = x, z = z})
    end
    return positions
end

local function GetDoubleCirclePositionsForKickAll(center, innerR, outerR, count)
    local positions = {}
    if count == 0 then return positions end
    local halfCount = math.floor(count / 2)
    local innerCount = halfCount
    local outerCount = count - halfCount
    local innerAngleStep = (math.pi * 2) / math.max(innerCount, 1)
    for i = 1, innerCount do
        local angle = (i - 1) * innerAngleStep
        local x = center.X + innerR * math.cos(angle)
        local z = center.Z + innerR * math.sin(angle)
        table.insert(positions, {x = x, z = z})
    end
    local outerAngleStep = (math.pi * 2) / math.max(outerCount, 1)
    for i = 1, outerCount do
        local angle = (i - 1) * outerAngleStep + (math.pi / outerCount)
        local x = center.X + outerR * math.cos(angle)
        local z = center.Z + outerR * math.sin(angle)
        table.insert(positions, {x = x, z = z})
    end
    return positions
end

local function GetSpiralPositionsForKickAll(center, startR, endR, count)
    local positions = {}
    if count == 0 then return positions end
    for i = 1, count do
        local t = (i - 1) / (count - 1)
        local radius = startR + (endR - startR) * t
        local angle = (i - 1) * (math.pi * 2 / count) * 3
        local x = center.X + radius * math.cos(angle)
        local z = center.Z + radius * math.sin(angle)
        table.insert(positions, {x = x, z = z})
    end
    return positions
end

local function TeleportPlayersToPositionsForKickAll(players, centerX, centerZ, yOffset, getPositionsFunc, ...)
    local positions = getPositionsFunc({X = centerX, Z = centerZ}, ...)
    for i, target in ipairs(players) do
        if target.Character and positions[i] then
            local root = target.Character:FindFirstChild("HumanoidRootPart")
            if root then
                root.CFrame = CFrame.new(positions[i].x, kickAllPlayerY + yOffset, positions[i].z)
            end
        end
    end
end

KickTab:AddButton({
    Name = "【実行】Kick All (ホワイトリスト除外)", 
    Callback = function()
        local allPlayers = GetNonWhitelistedPlayersForKickAll()
        if #allPlayers == 0 then 
            OrionLib:MakeNotification({Name = "エラー", Content = "キック対象のプレイヤーがいません", Time = 2})
            return 
        end
        
        OrionLib:MakeNotification({Name = "実行", Content = "Kick All開始", Time = 2})
        
        local blob = SpawnAndRideBlobmanForKickAll()
        if not blob then 
            OrionLib:MakeNotification({Name = "エラー", Content = "Blobmanに乗れませんでした", Time = 3})
            return 
        end
        
        task.wait(0.3)
        local myRoot = GetMyRootForKickAll()
        if not myRoot then return end
        
        for _, target in ipairs(allPlayers) do
            local targetRoot = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
            if targetRoot then
                TeleportToTargetForKickAll(targetRoot)
                SetNetworkOwnerForKickAll(targetRoot)
                for j = 1, 3 do
                    GrabReleaseForKickAll(blob, target)
                    if j < 3 then task.wait(0.08) end
                end
            end
        end
        
        myRoot.CFrame = CFrame.new(0, kickAllSelfY, 0)
        task.wait(0.1)
        AnchorBlobForKickAll(blob)
        task.wait(0.1)
        
        local centerX, centerZ = 0, 0
        if kickAllPlacementMode == "circle" then
            TeleportPlayersToPositionsForKickAll(allPlayers, centerX, centerZ, 0, GetCirclePositionsForKickAll, kickAllCircleRadius, #allPlayers)
        elseif kickAllPlacementMode == "double" then
            TeleportPlayersToPositionsForKickAll(allPlayers, centerX, centerZ, 0, GetDoubleCirclePositionsForKickAll, kickAllInnerRadius, kickAllOuterRadius, #allPlayers)
        elseif kickAllPlacementMode == "spiral" then
            TeleportPlayersToPositionsForKickAll(allPlayers, centerX, centerZ, 0, GetSpiralPositionsForKickAll, kickAllSpiralStart, kickAllSpiralEnd, #allPlayers)
        end
        
        task.wait(0.1)
        for _, target in ipairs(allPlayers) do 
            local targetRoot = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
            if targetRoot then DoGrabForKickAll(targetRoot) end 
        end
        
        task.wait(0.1)
        for _, target in ipairs(allPlayers) do 
            local targetRoot = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
            if targetRoot then DoGrabForKickAll(targetRoot) end 
        end
        
        task.wait(0.3)
        for i = 1, 3 do 
            for _, target in ipairs(allPlayers) do 
                KickBothForKickAll(blob, target) 
            end 
            if i < 3 then task.wait(0.08) end 
        end
        
        task.wait(0.1)
        UnanchorBlobForKickAll(blob)
        
        OrionLib:MakeNotification({Name = "Kick All 完了", Content = #allPlayers .. "人をキック", Time = 4})
    end 
})

KickTab:AddSection({ Name = "Kick All 配置設定" })
KickTab:AddDropdown({ 
    Name = "プレイヤー配置形状", 
    Default = "円形 (シングル)", 
    Options = {"円形 (シングル)", "二重円", "渦巻き状"}, 
    Callback = function(Value)
        if Value == "円形 (シングル)" then kickAllPlacementMode = "circle"
        elseif Value == "二重円" then kickAllPlacementMode = "double"
        elseif Value == "渦巻き状" then kickAllPlacementMode = "spiral" end
    end 
})
KickTab:AddSlider({ Name = "円半径 (シングル用)", Min = 5, Max = 100, Default = 25, Callback = function(v) kickAllCircleRadius = v end })
KickTab:AddSlider({ Name = "内側半径 (二重円用)", Min = 5, Max = 50, Default = 15, Callback = function(v) kickAllInnerRadius = v end })
KickTab:AddSlider({ Name = "外側半径 (二重円用)", Min = 20, Max = 100, Default = 35, Callback = function(v) kickAllOuterRadius = v end })
KickTab:AddSlider({ Name = "渦巻き開始半径", Min = 5, Max = 30, Default = 10, Callback = function(v) kickAllSpiralStart = v end })
KickTab:AddSlider({ Name = "渦巻き終了半径", Min = 20, Max = 80, Default = 40, Callback = function(v) kickAllSpiralEnd = v end })
KickTab:AddSlider({ Name = "対象プレイヤーのY座標", Min = 0, Max = 500, Default = 100, Callback = function(v) kickAllPlayerY = v end })
KickTab:AddSlider({ Name = "自分のY座標", Min = 0, Max = 500, Default = 100, Callback = function(v) kickAllSelfY = v end })

KickTab:AddSection({ Name = "Kick All ホワイトリスト" })
KickAllWhitelistLabel = KickTab:AddParagraph("保護リスト", "現在ホワイトリストは空です")

KickAllWhitelistDropdown = KickTab:AddDropdown({ 
    Name = "追加/削除するプレイヤー", 
    Default = "", 
    Options = GetPlayerListForKickAllWhitelist(), 
    Callback = function(Value) 
        if Value and Value ~= "" then 
            local name = Value:match("%@(.*)%)")
            if name then
                if KickAllWhitelist[name] then
                    KickAllWhitelist[name] = nil
                    OrionLib:MakeNotification({Name = "Kick All Whitelist", Content = name .. " をホワイトリストから削除しました", Time = 2})
                else
                    KickAllWhitelist[name] = true
                    OrionLib:MakeNotification({Name = "Kick All Whitelist", Content = name .. " をホワイトリストに追加しました", Time = 2})
                end
                UpdateKickAllWhitelistUI()
            end
        end 
    end 
})

task.spawn(function()
    while true do
        task.wait(1)
        UpdateKickAllWhitelistDropdownAuto()
    end
end)

KickTab:AddButton({ Name = "Kick All ホワイトリスト全解除", Callback = function() 
    KickAllWhitelist = {} 
    UpdateKickAllWhitelistUI()
    lastWhitelistPlayerList = {}
    UpdateKickAllWhitelistDropdownAuto()
    OrionLib:MakeNotification({Name = "Kick All Whitelist", Content = "ホワイトリストをすべて解除しました", Time = 2})
end })

KickTab:AddSection({ Name = "ドリフトキック" })

local driftKickRunning = false
local driftCurrentLoopId = 0
local driftRadius = 19
local driftSpeed = 12
local driftHeightOffset = 0
local driftAngle = 0
local driftTargetName = ""
local driftPlayerMap = {}

local function DriftKick_GetPlayerList()
    local names = {}
    driftPlayerMap = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local displayStr = p.DisplayName .. " (@" .. p.Name .. ")"
            table.insert(names, displayStr)
            driftPlayerMap[displayStr] = p.Name
        end
    end
    if #names == 0 then table.insert(names, "(None)") end
    return names
end

local function DriftKick_GetMyBlobman()
    local spawned = Workspace:FindFirstChild(LocalPlayer.Name .. "SpawnedInToys")
    if spawned then
        local blob = spawned:FindFirstChild("CreatureBlobman")
        if blob then return blob end
    end
    return nil
end

local function DriftKick_SpawnAndRideBlobman()
    local myRoot = HRP()
    if not myRoot then return nil end
    
    local existing = DriftKick_GetMyBlobman()
    if existing then
        pcall(function()
            local dt = ReplicatedStorage:FindFirstChild("MenuToys") and ReplicatedStorage.MenuToys:FindFirstChild("DestroyToy")
            if dt then dt:FireServer(existing) end
        end)
        task.wait(0.3)
    end
    
    local spawnRemote = ReplicatedStorage:FindFirstChild("MenuToys") and ReplicatedStorage.MenuToys:FindFirstChild("SpawnToyRemoteFunction")
    if not spawnRemote then return nil end
    
    local spawnCF = myRoot.CFrame + Vector3.new(0, 5, 0)
    pcall(function()
        spawnRemote:InvokeServer("CreatureBlobman", spawnCF, Vector3.zero)
    end)
    
    for _ = 1, 30 do
        task.wait(0.1)
        local blob = DriftKick_GetMyBlobman()
        if blob then
            local seat = blob:FindFirstChild("VehicleSeat")
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if seat and hum then
                local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp then hrp.CFrame = seat.CFrame + Vector3.new(0, 2, 0) end
                task.wait(0.1)
                seat:Sit(hum)
                task.wait(0.3)
            end
            return blob
        end
    end
    return nil
end

local driftTargetDropdown = KickTab:AddDropdown({
    Name = "ドリフトキック ターゲット",
    Default = "",
    Options = DriftKick_GetPlayerList(),
    Callback = function(val)
        if val and val ~= "(None)" then
            driftTargetName = driftPlayerMap[val] or ""
        end
    end
})

task.spawn(function()
    while true do
        task.wait(1)
        if driftTargetDropdown then
            local currentPlayers = DriftKick_GetPlayerList()
            driftTargetDropdown:Refresh(currentPlayers, true)
        end
    end
end)

KickTab:AddSlider({
    Name = "ドリフト半径",
    Min = 5,
    Max = 50,
    Default = 19,
    Callback = function(v) driftRadius = v end
})

KickTab:AddSlider({
    Name = "ドリフト速度",
    Min = 1,
    Max = 30,
    Default = 12,
    Callback = function(v) driftSpeed = v end
})

KickTab:AddSlider({
    Name = "ドリフト高さオフセット",
    Min = -20,
    Max = 30,
    Default = 0,
    Callback = function(v) driftHeightOffset = v end
})

local function DriftKick_Start(targetPlayerName)
    local target = Players:FindFirstChild(targetPlayerName)
    if not target or target == LocalPlayer then
        OrionLib:MakeNotification({Name="ドリフトキック", Content="無効なターゲット", Time=2})
        return false
    end
    
    driftCurrentLoopId = driftCurrentLoopId + 1
    local myLoopId = driftCurrentLoopId
    
    local blobman = DriftKick_SpawnAndRideBlobman()
    if not blobman then
        OrionLib:MakeNotification({Name="ドリフトキック", Content="Blobmanの生成に失敗", Time=2})
        return false
    end
    
    local GE = ReplicatedStorage:FindFirstChild("GrabEvents")
    if not GE then
        OrionLib:MakeNotification({Name="ドリフトキック", Content="GrabEventsが見つからない", Time=2})
        return false
    end
    
    local scriptObj = blobman:FindFirstChild("BlobmanSeatAndOwnerScript") or blobman:FindFirstChild("BlobmanSeatAndOwnerScript[old]")
    local grabRemote = (scriptObj and scriptObj:FindFirstChild("CreatureGrab")) or blobman:FindFirstChild("CreatureGrab", true)
    local dropRemote = (scriptObj and scriptObj:FindFirstChild("CreatureDrop")) or blobman:FindFirstChild("CreatureDrop", true)
    local lDet = blobman:FindFirstChild("LeftDetector")
    local rDet = blobman:FindFirstChild("RightDetector")
    local lWeld = lDet and (lDet:FindFirstChild("LeftWeld") or lDet:FindFirstChildWhichIsA("Weld") or lDet:FindFirstChildWhichIsA("JointInstance"))
    local rWeld = rDet and (rDet:FindFirstChild("RightWeld") or rDet:FindFirstChildWhichIsA("Weld") or rDet:FindFirstChildWhichIsA("JointInstance"))
    local Det = rDet or lDet
    local Weld = rWeld or lWeld
    
    if not (grabRemote and dropRemote and Det and Weld) then
        OrionLib:MakeNotification({Name="ドリフトキック", Content="必要なRemote/Detectorが見つからない", Time=3})
        return false
    end
    
    OrionLib:MakeNotification({Name="ドリフトキック", Content="開始: " .. target.Name, Time=2})
    
    task.spawn(function()
        local lastTime = tick()
        while driftKickRunning and myLoopId == driftCurrentLoopId do
            if not target or not target.Parent then break end
            
            local tChar = target.Character
            local tHum = tChar and tChar:FindFirstChildOfClass("Humanoid")
            local tRoot = tChar and tChar:FindFirstChild("HumanoidRootPart")
            
            if not tChar or not tRoot or not tHum or tHum.Health <= 0 then
                local respawnWait = 0
                while driftKickRunning and myLoopId == driftCurrentLoopId and (not target.Character or not target.Character:FindFirstChild("HumanoidRootPart") or not target.Character:FindFirstChildOfClass("Humanoid")) do
                    task.wait(0.5)
                    respawnWait = respawnWait + 1
                    if respawnWait > 20 then break end
                end
                tChar = target.Character
                tRoot = tChar and tChar:FindFirstChild("HumanoidRootPart")
                tHum = tChar and tChar:FindFirstChildOfClass("Humanoid")
                if not tRoot or not tHum or tHum.Health <= 0 then break end
            end
            
            if tRoot and tHum and tHum.Health > 0 then
                local blobRoot = blobman:FindFirstChild("HumanoidRootPart") or blobman.PrimaryPart
                if not blobRoot then break end
                
                local bringStart = tick()
                while tick() - bringStart < 0.35 and driftKickRunning and myLoopId == driftCurrentLoopId do
                    if target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                        local currentTRoot = target.Character.HumanoidRootPart
                        blobRoot.CFrame = currentTRoot.CFrame
                        blobRoot.AssemblyLinearVelocity = Vector3.zero
                        pcall(function()
                            if Det then grabRemote:FireServer(Det, currentTRoot, Weld) end
                            if GE.CreateGrabLine then GE.CreateGrabLine:FireServer(currentTRoot, Vector3.zero, currentTRoot.Position, false) end
                            if GE.SetNetworkOwner then GE.SetNetworkOwner:FireServer(currentTRoot, blobRoot.CFrame) end
                        end)
                    end
                    RunService.Heartbeat:Wait()
                end
                
                if not driftKickRunning or myLoopId ~= driftCurrentLoopId then break end
                
                tChar = target.Character
                tRoot = tChar and tChar:FindFirstChild("HumanoidRootPart")
                tHum = tChar and tChar:FindFirstChildOfClass("Humanoid")
                if not tRoot or not tHum or tHum.Health <= 0 then break end
                
                local SavedPos = tRoot.CFrame
                local targetCenterCFrame = SavedPos + Vector3.new(0, 23 + driftHeightOffset, 0)
                
                while driftKickRunning and myLoopId == driftCurrentLoopId and blobman and blobman.Parent do
                    if not target or not target.Parent then break end
                    tChar = target.Character
                    tRoot = tChar and tChar:FindFirstChild("HumanoidRootPart")
                    tHum = tChar and tChar:FindFirstChildOfClass("Humanoid")
                    
                    if not tChar or not tRoot or not tHum or tHum.Health <= 0 then
                        break
                    end
                    
                    local currentTime = tick()
                    local dt = math.min(0.1, currentTime - lastTime)
                    lastTime = currentTime
                    
                    driftAngle = driftAngle + (driftSpeed * dt)
                    local offsetX = math.cos(driftAngle) * driftRadius
                    local offsetZ = math.sin(driftAngle) * driftRadius
                    
                    local blobPos = targetCenterCFrame.Position + Vector3.new(offsetX, driftHeightOffset, offsetZ)
                    blobRoot.CFrame = CFrame.new(blobPos, targetCenterCFrame.Position)
                    blobRoot.AssemblyLinearVelocity = Vector3.zero
                    blobRoot.AssemblyAngularVelocity = Vector3.zero
                    
                    tRoot.CFrame = targetCenterCFrame
                    tRoot.AssemblyLinearVelocity = Vector3.zero
                    tRoot.AssemblyAngularVelocity = Vector3.zero
                    
                    pcall(function()
                        tHum.PlatformStand = true
                        tHum.Sit = true
                        if GE.SetNetworkOwner then GE.SetNetworkOwner:FireServer(tRoot, targetCenterCFrame) end
                        
                        local currentWeld = Det:FindFirstChild("RightWeld") or Det:FindFirstChild("LeftWeld") or Det:FindFirstChildWhichIsA("Weld") or Det:FindFirstChildWhichIsA("JointInstance")
                        if currentWeld then dropRemote:FireServer(currentWeld) end
                        
                        if GE.DestroyGrabLine then GE.DestroyGrabLine:FireServer(tRoot) end
                        if Det then grabRemote:FireServer(Det, tRoot, Weld) end
                        if GE.CreateGrabLine then GE.CreateGrabLine:FireServer(tRoot, Vector3.zero, targetCenterCFrame.Position, false) end
                    end)
                    
                    RunService.Heartbeat:Wait()
                end
            end
            RunService.Heartbeat:Wait()
        end
    end)
end

KickTab:AddToggle({
    Name = "ドリフトキック",
    Default = false,
    Callback = function(state)
        driftKickRunning = state
        if state then
            if driftTargetName and driftTargetName ~= "" then
                DriftKick_Start(driftTargetName)
            else
                OrionLib:MakeNotification({Name="ドリフトキック", Content="先にターゲットを選択してください", Time=2})
                driftKickRunning = false
            end
        end
    end
})

-- ================= タブ3: キル系（LOOP機能完全統合） =================
local KillTab = Window:MakeTab({Name = "キル系", Icon = "rbxassetid://4483345998"})

local killLabel = KillTab:AddParagraph("選択中", "なし")

local killTargetDropdown = KillTab:AddDropdown({
    Name = "キルターゲット選択",
    Options = getPlayers(),
    Default = "",
    Callback = function(v)
        if v then
            local username = v:match("@(.+)%)")
            reskillSelectedTargetName = username
            local p = Players:FindFirstChild(username)
            if p then
                killLabel:Set("選択中", p.DisplayName.." @"..p.Name)
            end
        end
    end
})

-- キル系タブのドロップダウンを常時自動更新（1秒ごと）
task.spawn(function()
    while true do
        task.wait(1)
        if killTargetDropdown then
            local currentPlayers = getPlayers()
            killTargetDropdown:Refresh(currentPlayers, true)
        end
    end
end)

KillTab:AddToggle({
    Name = "Reskill (単体キル)",
    Default = false,
    Callback = function(state)
        reskillLooping = state
        if not state then lastFlungCharacter = nil end
        task.spawn(function()
            while reskillLooping do
                local selectedTarget = Players:FindFirstChild(reskillSelectedTargetName)
                if selectedTarget and selectedTarget.Character then
                    local currentCharacter = selectedTarget.Character
                    if currentCharacter ~= lastFlungCharacter then
                        local hum = currentCharacter:FindFirstChild("Humanoid")
                        if hum and hum.Health > 0 then
                            execute_sequence(selectedTarget)
                            lastFlungCharacter = currentCharacter
                        end
                    end
                end
                task.wait(0.5)
            end
        end)
    end
})

KillTab:AddToggle({
    Name = "Reskill All (全員キル)",
    Default = false,
    Callback = function(state)
        killAllLoop = state
        if state then
            task.spawn(function()
                while killAllLoop do
                    for _, p in ipairs(Players:GetPlayers()) do
                        if not killAllLoop then break end
                        if p ~= LocalPlayer and p.Character then
                            local char = p.Character
                            if processedAll[p] ~= char then
                                if char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
                                    execute_sequence(p)
                                    processedAll[p] = char
                                    task.wait(0.2)
                                end
                            end
                        end
                    end
                    task.wait(1)
                end
            end)
        else
            table.clear(processedAll)
        end
    end
})

KillTab:AddSection({Name = "ブロブマンキルALL"})
KillTab:AddToggle({
    Name = "🤖ブロブマンキルオーラ（半径35・自動乗車付き）",
    Default = false,
    Callback = function(v)
        bmkAuraEnabled = v
        if v then 
            startAura()
            OrionLib:MakeNotification({Name="ブロブマンキルオーラ", Content="ON（自動乗車付き）", Time=2})
        else
            stopAura()
            OrionLib:MakeNotification({Name="ブロブマンキルオーラ", Content="OFF", Time=2})
        end
    end
})

KillTab:AddToggle({
    Name = "ブロブマンキルALL（全員連続キル・自動乗車）",
    Default = false,
    Callback = function(v)
        blobmanKillAllRunning = v
        if v then
            task.spawn(blobmanKillAllLoop)
            OrionLib:MakeNotification({Name="ブロブマンキルALL", Content="ON（自動乗車付き）", Time=2})
        else
            OrionLib:MakeNotification({Name="ブロブマンキルALL", Content="OFF", Time=2})
        end
    end
})

-- ================= LOOP機能セクション（元のソース完全維持） =================
KillTab:AddSection({ Name = "━━━━━ LOOP攻撃 ━━━━━" })

-- LOOP用ターゲット選択
local loopTargetDropdown = KillTab:AddDropdown({
    Name = "🎯 LOOPターゲット選択",
    Options = updateLoopPlayerList(),
    Default = "",
    Callback = function(v)
        if v then
            LoopConfig.TargetPlayer = getPlayerFromDisplayName(v)
            local p = Players:FindFirstChild(LoopConfig.TargetPlayer and LoopConfig.TargetPlayer.Name)
            if p then
                OrionLib:MakeNotification({Name="LOOPターゲット", Content=p.DisplayName.." を選択", Time=2})
            end
        end
    end
})

KillTab:AddButton({
    Name = "🔄 LOOPプレイヤーリスト更新",
    Callback = function()
        loopTargetDropdown:Refresh(updateLoopPlayerList(), true)
    end
})

-- LOOP攻撃トグル（元のソース完全再現）
KillTab:AddToggle({
    Name = "🔪 ループキル",
    Default = false,
    Color = Color3.fromRGB(255, 255, 0),
    Callback = function(v) LoopConfig.LoopKill = v end
})

KillTab:AddToggle({
    Name = "🚀 ループボイド",
    Default = false,
    Color = Color3.fromRGB(255, 255, 0),
    Callback = function(v) LoopConfig.LoopVoid = v end
})

KillTab:AddToggle({
    Name = "☠️ ループ毒",
    Default = false,
    Color = Color3.fromRGB(255, 255, 0),
    Callback = function(v) LoopConfig.LoopPoison = v end
})

KillTab:AddToggle({
    Name = "🌀 ループラグドール",
    Default = false,
    Color = Color3.fromRGB(255, 255, 0),
    Callback = function(v) LoopConfig.LoopRagdoll = v end
})

KillTab:AddToggle({
    Name = "💀 ループデス",
    Default = false,
    Color = Color3.fromRGB(255, 255, 0),
    Callback = function(v) LoopConfig.LoopDeath = v end
})

KillTab:AddToggle({
    Name = "📦 ループブリング",
    Default = false,
    Color = Color3.fromRGB(255, 255, 0),
    Callback = function(v) LoopConfig.LoopBring = v end
})

KillTab:AddToggle({
    Name = "🎯 ループプル",
    Default = false,
    Color = Color3.fromRGB(255, 255, 0),
    Callback = function(v) LoopConfig.LoopPull = v end
})

KillTab:AddParagraph("⏱️ LOOP情報", "選択したターゲットに1.5秒ごとに攻撃")

-- ================= LOOP実行（Heartbeatで1.5秒ごと） =================
RunService.Heartbeat:Connect(function(dt)
    LoopTimer = LoopTimer + dt
    
    if LoopTimer >= 1.5 then
        if LoopConfig.TargetPlayer and LoopConfig.TargetPlayer.Character then
            if LoopConfig.LoopKill then task.spawn(SnipeKill, LoopConfig.TargetPlayer) end
            if LoopConfig.LoopVoid then task.spawn(SnipeVoid, LoopConfig.TargetPlayer) end
            if LoopConfig.LoopPoison then task.spawn(SnipePoison, LoopConfig.TargetPlayer) end
            if LoopConfig.LoopRagdoll then task.spawn(SnipeRagdoll, LoopConfig.TargetPlayer) end
            if LoopConfig.LoopDeath then task.spawn(SnipeDeath, LoopConfig.TargetPlayer) end
            if LoopConfig.LoopBring then task.spawn(SnipeBring, LoopConfig.TargetPlayer) end
            if LoopConfig.LoopPull then task.spawn(SnipePull, LoopConfig.TargetPlayer) end
        end
        LoopTimer = 0
    end
end)

-- LOOPプレイヤーリスト自動更新
Players.PlayerAdded:Connect(function()
    task.wait(0.5)
    if loopTargetDropdown then
        loopTargetDropdown:Refresh(updateLoopPlayerList(), true)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    if LoopConfig.TargetPlayer == player then
        LoopConfig.TargetPlayer = nil
        OrionLib:MakeNotification({
            Name = "LOOPターゲット退出",
            Content = "ターゲットがサーバーを離れました",
            Time = 3
        })
    end
    task.wait(0.5)
    if loopTargetDropdown then
        loopTargetDropdown:Refresh(updateLoopPlayerList(), true)
    end
end)

-- ================= タブ4: ESP =================
local ESP_Tab = Window:MakeTab({Name = "ESP", Icon = "rbxassetid://7733774602"})
ESP_Tab:AddSection({Name = "ESPハイライト"})

local function UpdateESP()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            if espEnabled and p.Character then
                if not espHighlights[p] then
                    local h = Instance.new("Highlight")
                    h.Adornee = p.Character
                    h.FillColor = Color3.fromRGB(255, 0, 0)
                    h.FillTransparency = 0.5
                    h.OutlineColor = Color3.fromRGB(255, 255, 255)
                    h.Parent = p.Character
                    espHighlights[p] = h
                end
            else
                if espHighlights[p] then espHighlights[p]:Destroy() espHighlights[p] = nil end
            end
        end
    end
end

ESP_Tab:AddToggle({Name = "ESP（ハイライト）", Default = false, Callback = function(val)
    espEnabled = val
    UpdateESP()
end})

-- ================= タブ5: プレイヤー =================
local PlayerTab = Window:MakeTab({Name = "プレイヤー", Icon = "rbxassetid://7743871002"})
PlayerTab:AddSection({Name = "移動速度"})
PlayerTab:AddToggle({Name = "移動速度", Default = false, Callback = function(v) superSpeed = v end})
PlayerTab:AddSlider({Name = "速度倍率", Min = 0.1, Max = 5, Default = 0.15, Increment = 0.01, Callback = function(v) Multiplier = v end})
PlayerTab:AddSection({Name = "無限ジャンプ"})
PlayerTab:AddToggle({Name = "無限ジャンプ", Default = false, Callback = function(v) infiniteJump = v end})
PlayerTab:AddSlider({Name = "ジャンプ力", Min = 24, Max = 1000, Default = 24, Increment = 10, Callback = function(v)
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.JumpPower = v end
end})
PlayerTab:AddSection({Name = "壁抜け"})
PlayerTab:AddToggle({Name = "壁抜け", Default = false, Callback = function(v)
    noclip = v
    if v then
        noclipConn = RunService.Stepped:Connect(function()
            if LocalPlayer.Character then
                for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
            end
        end)
    elseif noclipConn then noclipConn:Disconnect() noclipConn = nil end
end})

PlayerTab:AddSection({Name = "視点"})
local thirdPersonEnabled = false
PlayerTab:AddToggle({
    Name = "Third Person",
    Default = false,
    Callback = function(state)
        thirdPersonEnabled = state
        if state then
            LocalPlayer.CameraMode = Enum.CameraMode.Classic
            LocalPlayer.CameraMaxZoomDistance = 100
            LocalPlayer.CameraMinZoomDistance = 0.5
        else
            LocalPlayer.CameraMode = Enum.CameraMode.LockFirstPerson
            LocalPlayer.CameraMaxZoomDistance = 0.5
            LocalPlayer.CameraMinZoomDistance = 0.5
        end
    end
})

RunService.Heartbeat:Connect(function()
    if superSpeed and LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hum and root then root.CFrame = root.CFrame + hum.MoveDirection * Multiplier end
    end
end)

UserInputService.JumpRequest:Connect(function()
    if infiniteJump and LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState("Jumping") end
    end
end)

-- ================= タブ6: アンチ =================
local DefenseTab = Window:MakeTab({Name = "アンチ", Icon = "rbxassetid://129017321982695"})

DefenseTab:AddToggle({
    Name = "アンチ掴む",
    Default = false,
    Callback = function(enabled)
        if enabled then
            if autoStruggleCoroutine then autoStruggleCoroutine:Disconnect() end
            autoStruggleCoroutine = RunService.Heartbeat:Connect(function()
                local character = LocalPlayer.Character
                if character and character:FindFirstChild("Head") then
                    local head = character.Head
                    local partOwner = head:FindFirstChild("PartOwner")
                    if partOwner then
                        local struggle = ReplicatedStorage:FindFirstChild("CharacterEvents") and ReplicatedStorage.CharacterEvents:FindFirstChild("Struggle")
                        if struggle then struggle:FireServer() end
                        local stopAllVelocity = ReplicatedStorage:FindFirstChild("GameCorrectionEvents") and ReplicatedStorage.GameCorrectionEvents:FindFirstChild("StopAllVelocity")
                        if stopAllVelocity then stopAllVelocity:FireServer() end
                        for _, part in pairs(character:GetChildren()) do
                            if part:IsA("BasePart") then
                                part.Anchored = true
                            end
                        end
                        while LocalPlayer:FindFirstChild("IsHeld") and LocalPlayer.IsHeld.Value do
                            task.wait()
                        end
                        for _, part in pairs(character:GetChildren()) do
                            if part:IsA("BasePart") then
                                part.Anchored = false
                            end
                        end
                    end
                end
            end)
        else
            if autoStruggleCoroutine then
                autoStruggleCoroutine:Disconnect()
                autoStruggleCoroutine = nil
            end
        end
    end
})

DefenseTab:AddToggle({
    Name = "アンチ掴む V2",
    Default = false,
    Callback = function(Value)
        autoGucciT = Value
        if autoGucciT then
            spawnBlobmanF()
            task.wait()
            if not sitJumpT then
                task.spawn(sitJumpF)
                sitJumpT = true
            end
            task.spawn(ragdollLoopF)
        else
            sitJumpT = false
        end
    end
})

DefenseTab:AddToggle({
    Name = "アンチキック解除",
    Default = false,
    Callback = function(enabled)
        if enabled then
            if not antikickRunning then
                antikickRunning = true
                antikickKCoroutine = coroutine.create(antikickK)
                coroutine.resume(antikickKCoroutine)
            end
        else
            if antikickRunning then
                antikickRunning = false
            end
        end
    end
})

DefenseTab:AddToggle({
    Name = "アンチブロブマン",
    Default = false,
    Callback = function(Value)
        SetAntiBlobman(Value)
    end
})

local function bp()
    local pl = Workspace:FindFirstChild("PlotItems")
    if not pl then return end
    for i = 1, 5 do
        local pt = pl:FindFirstChild("Plot" .. i)
        if pt then
            local bc = pt:FindFirstChild("CreatureBlobman")
            if bc and bc:IsA("Folder") then
                for _, ude in ipairs(bc:GetChildren()) do
                    if ude.Name == "LeftDetector" or ude.Name == "RightDetector" then
                        ude:Destroy()
                    end
                end
            end
        end
    end
end

local function antib1()
    for _, allp in ipairs(Players:GetPlayers()) do
        if allp ~= LocalPlayer then
            local st1 = Workspace:FindFirstChild("st")
            local st2 = st1 and st1:FindFirstChild(allp.Name .. "SpawnedInToys")
            local wo = Workspace:FindFirstChild(allp.Name .. "SpawnedInToys")
            if wo and wo:IsA("Folder") then
                for _, antib1 in ipairs(wo:GetChildren()) do
                    if antib1.Name == "CreatureBlobman" then
                        for _, LD1 in ipairs(antib1:GetChildren()) do
                            if LD1.Name == "LeftDetector" then LD1:Destroy() end
                        end
                        for _, RD1 in ipairs(antib1:GetChildren()) do
                            if RD1.Name == "RightDetector" then RD1:Destroy() end
                        end
                    end
                end
            end
            if st2 and st2:IsA("Folder") then
                for _, antib2 in ipairs(st2:GetChildren()) do
                    if antib2.Name == "CreatureBlobman" then
                        for _, LD in ipairs(antib2:GetChildren()) do
                            if LD.Name == "LeftDetector" then LD:Destroy() end
                        end
                        for _, RD in ipairs(antib2:GetChildren()) do
                            if RD.Name == "RightDetector" then RD:Destroy() end
                        end
                    end
                end
            end
        end
    end
end

coroutine.wrap(function()
    while true do
        if antiblob then
            bp()
            antib1()
        end
        task.wait(0.5)
    end
end)()

DefenseTab:AddToggle({
    Name = "アンチブロブマンv2",
    Default = false,
    Callback = function(value)
        antiblob = value
    end
})

DefenseTab:AddToggle({
    Name = "アンチブリングtest",
    Default = false,
    Callback = function(value)
        blobLoopT2 = value
        if blobLoopT2 then
            loopdrop()
        else
            if connection then
                connection:Disconnect()
                connection = nil
            end
        end
    end
})

DefenseTab:AddToggle({
    Name = "ラグドール起こし",
    Default = false,
    Callback = function(Value)
        permRagdollT = Value
        if permRagdollT and not permRagdollRunningS then
            task.spawn(permRagdollLoopF)
        elseif not permRagdollT then
            permRagdollRunningS = false
        end
    end
})

DefenseTab:AddToggle({
    Name = "アンチラグドールテスト",
    Default = false,
    Callback = function(Value)
        setProtection(Value)
    end
})

DefenseTab:AddToggle({
    Name = "奈落",
    Default = false,
    Callback = function(Value)
        if Value then
            Workspace.FallenPartsDestroyHeight = 0/0
        else
            Workspace.FallenPartsDestroyHeight = -100
        end
    end
})

DefenseTab:AddToggle({
    Name = "アンチファイヤ",
    Default = false,
    Callback = function(Value)
        antiburn = Value
        while antiburn do
            if LocalPlayer.Character then
                local v1 = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                local v4 = LocalPlayer.Character:FindFirstChild("Humanoid")
                if v1 and v4 and v4.Health > 0 and v4:GetState() ~= Enum.HumanoidStateType.Dead then
                    local v2 = v1:FindFirstChild("FireLight")
                    if v2 then
                        local v3 = workspace:FindFirstChild(LocalPlayer.Name .. "SpawnedInToys") and workspace[LocalPlayer.Name .. "SpawnedInToys"]:FindFirstChild("FireExtinguisher")
                        if v3 then
                            local save = v3.ExtinguishPart.Position
                            while v1:FindFirstChild("FireLight") do
                                v3.ExtinguishPart.Position = LocalPlayer.Character.HumanoidRootPart.Position
                                task.wait()
                                v3.ExtinguishPart.Position = save
                            end
                            if v3 and v3.ExtinguishPart then
                                v3.ExtinguishPart.Position = save
                            end
                        elseif not (LocalPlayer:FindFirstChild("InPlot") and LocalPlayer.InPlot.Value) and (LocalPlayer:FindFirstChild("CanSpawnToy") and LocalPlayer.CanSpawnToy.Value) then
                            local spawnRemote = ReplicatedStorage:FindFirstChild("MenuToys") and ReplicatedStorage.MenuToys:FindFirstChild("SpawnToyRemoteFunction")
                            if spawnRemote then
                                local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                                if hrp then
                                    local cf = hrp.CFrame
                                    spawnRemote:InvokeServer("FireExtinguisher", cf - Vector3.new(cf.LookVector.X * 20, -15, cf.LookVector.Z * 20), Vector3.new(0,0,0))
                                end
                            end
                            while workspace:FindFirstChild(LocalPlayer.Name .. "SpawnedInToys") and not workspace[LocalPlayer.Name .. "SpawnedInToys"]:FindFirstChild("FireExtinguisher") do
                                task.wait()
                            end
                        end
                    end
                end
            end
            task.wait()
        end
    end
})

DefenseTab:AddToggle({
    Name = "アンチ爆発",
    Default = false,
    Callback = function(enabled)
        if enabled then
            if LocalPlayer.Character then
                setupAntiExplosion(LocalPlayer.Character)
            end
            characterAddedConn = LocalPlayer.CharacterAdded:Connect(function(character)
                if antiExplosionConnection then
                    antiExplosionConnection:Disconnect()
                end
                setupAntiExplosion(character)
            end)
        else
            if antiExplosionConnection then
                antiExplosionConnection:Disconnect()
                antiExplosionConnection = nil
            end
            if characterAddedConn then
                characterAddedConn:Disconnect()
                characterAddedConn = nil
            end
        end
    end
})

local function ch()
    if FF5 and LocalPlayer.Character and LocalPlayer.Character.Parent == workspace then
        if not FF2 then
            local spawnRemote = ReplicatedStorage:FindFirstChild("MenuToys") and ReplicatedStorage.MenuToys:FindFirstChild("SpawnToyRemoteFunction")
            if spawnRemote and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head") then
                spawnRemote:InvokeServer(FF3, LocalPlayer.Character.Head.CFrame, Vector3.new(0, 0, 0))
            end
            task.wait(0.001)
            local toysFolder = workspace:FindFirstChild(LocalPlayer.Name .. "SpawnedInToys")
            if toysFolder then
                FF2 = toysFolder:FindFirstChild(FF3)
            end
        end
        if FF2 then
            if FF2 and FF2:IsA("Model") then
                local ExtinguishPart = FF2:FindFirstChild("ExtinguishPart")
                if ExtinguishPart then
                    ExtinguishPart.Size = Vector3.new(1500, 1500, 1500)
                end
            end
        else
            local spawnRemote = ReplicatedStorage:FindFirstChild("MenuToys") and ReplicatedStorage.MenuToys:FindFirstChild("SpawnToyRemoteFunction")
            if spawnRemote and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head") then
                spawnRemote:InvokeServer(FF3, LocalPlayer.Character.Head.CFrame, Vector3.new(0, 0, 0))
            end
        end
    end
end

RunService.Heartbeat:Connect(ch)

DefenseTab:AddToggle({
    Name = "アンチファイヤall",
    Default = false,
    Callback = function(enabled)
        FF5 = enabled
        if not enabled then
            FF2 = nil
        end
        if enabled then
            if FCoroutine then coroutine.close(FCoroutine) end
            FCoroutine = coroutine.create(function()
                while true do
                    pcall(function()
                        local character = LocalPlayer.Character
                        if character and character:FindFirstChild("HumanoidRootPart") then
                            local root = character.HumanoidRootPart
                            for _, player in pairs(Players:GetPlayers()) do
                                local toysFolder = workspace:FindFirstChild(player.Name .. "SpawnedInToys")
                                if toysFolder then
                                    for _, obj in pairs(toysFolder:GetChildren()) do
                                        coroutine.wrap(function()
                                            if obj:IsA("Model") and obj.Name == "FireExtinguisher" then
                                                local soundPart = obj:FindFirstChild("SoundPart")
                                                if soundPart and soundPart:IsA("BasePart") then
                                                    local dist = (soundPart.Position - root.Position).Magnitude
                                                    if dist <= aaaa then
                                                        local setNetworkOwner = ReplicatedStorage:FindFirstChild("GrabEvents") and ReplicatedStorage.GrabEvents:FindFirstChild("SetNetworkOwner")
                                                        if setNetworkOwner then
                                                            setNetworkOwner:FireServer(soundPart, soundPart.CFrame)
                                                        end
                                                        task.wait()
                                                        local velocity = soundPart:FindFirstChild("l") or Instance.new("BodyVelocity", soundPart)
                                                        velocity.Name = "l"
                                                        velocity.Velocity = Vector3.new(0, 0, 0)
                                                        velocity.MaxForce = Vector3.new(0, math.huge, 0)
                                                        Debris:AddItem(velocity, 0)
                                                    end
                                                end
                                            end
                                        end)()
                                    end
                                end
                            end
                        end
                    end)
                    task.wait()
                end
            end)
            coroutine.resume(FCoroutine)
        else
            if FCoroutine then
                coroutine.close(FCoroutine)
                FCoroutine = nil
            end
        end
    end
})

local function antiLagF()
    if antiLagT then
        if LocalPlayer:FindFirstChild("PlayerScripts") and LocalPlayer.PlayerScripts:FindFirstChild("CharacterAndBeamMove") then
            LocalPlayer.PlayerScripts.CharacterAndBeamMove.Disabled = true
        end
    else
        if LocalPlayer:FindFirstChild("PlayerScripts") and LocalPlayer.PlayerScripts:FindFirstChild("CharacterAndBeamMove") then
            LocalPlayer.PlayerScripts.CharacterAndBeamMove.Enabled = true
        end
    end
end

DefenseTab:AddToggle({
    Name = "アンチラグ",
    Default = false,
    Callback = function(Value)
        antiLagT = Value
        antiLagF()
    end
})

DefenseTab:AddToggle({
    Name = "アンチキック",
    Default = false,
    Callback = function(Value)
        antikick = Value
        local lastt = false
        local function f()
            if Workspace:FindFirstChild(LocalPlayer.Name) then
                local character = LocalPlayer.Character
                if not character then return end
                local hrp = character:FindFirstChild("HumanoidRootPart")
                local hum = character:FindFirstChildOfClass("Humanoid")
                local leg = character:FindFirstChild("Right Leg")
                if hrp and hum and leg and hum.Health ~= 0 and hum:GetState() ~= Enum.HumanoidStateType.Dead and not (LocalPlayer:FindFirstChild("InPlot") and LocalPlayer.InPlot.Value) then
                    local backpack = workspace:FindFirstChild(LocalPlayer.Name .. "SpawnedInToys")
                    if backpack then
                        local v1 = backpack:FindFirstChild("NinjaKunai")
                        if v1 then
                            local v2 = v1:FindFirstChild("StickyPart")
                            if v2 then
                                local v3 = v2:FindFirstChild("StickyWeld")
                                if v3 then
                                    local v4 = v3.Part1
                                    if not v4 or v4 ~= leg then
                                        local destroyToy = ReplicatedStorage:FindFirstChild("MenuToys") and ReplicatedStorage.MenuToys:FindFirstChild("DestroyToy")
                                        if destroyToy then destroyToy:FireServer(v1) end
                                        task.wait()
                                        f()
                                    end
                                else
                                    local destroyToy = ReplicatedStorage:FindFirstChild("MenuToys") and ReplicatedStorage.MenuToys:FindFirstChild("DestroyToy")
                                    if destroyToy then destroyToy:FireServer(v1) end
                                    task.wait()
                                    f()
                                end
                            else
                                local destroyToy = ReplicatedStorage:FindFirstChild("MenuToys") and ReplicatedStorage.MenuToys:FindFirstChild("DestroyToy")
                                if destroyToy then destroyToy:FireServer(v1) end
                                task.wait()
                                f()
                            end
                        elseif not (LocalPlayer:FindFirstChild("InPlot") and LocalPlayer.InPlot.Value) and (LocalPlayer:FindFirstChild("CanSpawnToy") and LocalPlayer.CanSpawnToy.Value) then
                            if lastt then
                                lastt = false
                                task.wait(0.5)
                            end
                            local spawnRemote = ReplicatedStorage:FindFirstChild("MenuToys") and ReplicatedStorage.MenuToys:FindFirstChild("SpawnToyRemoteFunction")
                            if spawnRemote and hrp then
                                local cf = hrp.CFrame
                                spawnRemote:InvokeServer("NinjaKunai", cf - Vector3.new(cf.LookVector.X * 20, -15, cf.LookVector.Z * 20), Vector3.new(0,0,0))
                            end
                            while backpack and not backpack:FindFirstChild("NinjaKunai") do
                                task.wait()
                            end
                            local v8 = backpack and backpack:FindFirstChild("NinjaKunai") and backpack.NinjaKunai:FindFirstChild("StickyPart")
                            if v8 then
                                local v9 = v8:FindFirstChild("StickyWeld")
                                local stickyPartEvent = ReplicatedStorage:FindFirstChild("PlayerEvents") and ReplicatedStorage.PlayerEvents:FindFirstChild("StickyPartEvent")
                                while v9 and v9.Part1 == nil do
                                    if stickyPartEvent then
                                        stickyPartEvent:FireServer(v8, leg,
                                            CFrame.new(0.0490287527, 0.5, 0, 0, 0.00739139877, -0.999561906,
                                                -0.998452604, -0.0478846952, 0.0282763243,
                                                -0.0476547107, 0.99882561, 0) * CFrame.Angles(0, 0, 0))
                                    end
                                    task.wait()
                                end
                            end
                        elseif LocalPlayer:FindFirstChild("InPlot") and LocalPlayer.InPlot.Value then
                            lastt = true
                        end
                    end
                end
            end
        end
        while antikick do
            pcall(f)
            task.wait()
        end
    end
})

DefenseTab:AddButton({
    Name = "アンチリスキル",
    Callback = function()
        local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local HRP = Character:WaitForChild("HumanoidRootPart")
        local flingSpeed = 3000000
        pcall(function()
            for _, part in pairs(Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part:SetNetworkOwner(LocalPlayer)
                end
            end
        end)
        RunService.Stepped:Connect(function()
            if HRP then
                HRP.Velocity = Vector3.new(100, 20, 100)
                HRP.RotVelocity = Vector3.new(flingSpeed, flingSpeed, flingSpeed)
            end
        end)
    end
})

DefenseTab:AddButton({
    Name = "アンチ雪玉",
    Callback = function()
        local bombEvents = ReplicatedStorage:FindFirstChild("BombEvents")
        if bombEvents then
            bombEvents:Destroy()
        end
        local alreadyProcessed = {}
        local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local rangeRadius = 50
        local function isInRange(position)
            return character and character:FindFirstChild("HumanoidRootPart") and (position - character.HumanoidRootPart.Position).Magnitude <= rangeRadius
        end
        RunService.RenderStepped:Connect(function()
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer then
                    local toyFolder = Workspace:FindFirstChild(player.Name .. "SpawnedInToys")
                    if toyFolder and toyFolder:IsA("Folder") then
                        for _, toy in ipairs(toyFolder:GetChildren()) do
                            if toy.Name == "BallSnowball" then
                                for _, part in ipairs(toy:GetChildren()) do
                                    if (part.Name == "SnowRagdollPart" or part.Name == "SoundPart") and not alreadyProcessed[part] then
                                        if isInRange(part.Position) then
                                            part.CanCollide = false
                                            part.CanQuery = false
                                            part.CanTouch = false
                                            part.Size = Vector3.zero
                                            alreadyProcessed[part] = true
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end)
    end
})

local function BSAT()
    pcall(function()
        local myToysFolder = workspace:FindFirstChild(LocalPlayer.Name .. "SpawnedInToys")
        if myToysFolder then
            if myToysFolder:FindFirstChild("Campfire") then
                local destroyToy = ReplicatedStorage:FindFirstChild("MenuToys") and ReplicatedStorage.MenuToys:FindFirstChild("DestroyToy")
                if destroyToy then destroyToy:FireServer(myToysFolder:FindFirstChild("Campfire")) end
                task.wait()
            end
            local spawnRemote = ReplicatedStorage:FindFirstChild("MenuToys") and ReplicatedStorage.MenuToys:FindFirstChild("SpawnToyRemoteFunction")
            if spawnRemote and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head") then
                spawnRemote:InvokeServer("Campfire", LocalPlayer.Character.Head.CFrame, Vector3.new(0, 90, 0))
            end
            task.wait(0.001)
            local campfire = myToysFolder:WaitForChild("Campfire")
            campfire.PrimaryPart = campfire:FindFirstChild("Main")
            local firePlayerPart
            for _, part in pairs(campfire:GetChildren()) do
                if part.Name == "FirePlayerPart" then
                    part.Size = Vector3.new(0, 0, 0)
                    firePlayerPart = part
                    break
                end
            end
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Torso") then
                local originalPosition = LocalPlayer.Character.Torso.Position
                local setNetworkOwner = ReplicatedStorage:FindFirstChild("GrabEvents") and ReplicatedStorage.GrabEvents:FindFirstChild("SetNetworkOwner")
                if setNetworkOwner and firePlayerPart then
                    setNetworkOwner:FireServer(firePlayerPart, firePlayerPart.CFrame)
                end
                if LocalPlayer.Character:FindFirstChild("Humanoid") then
                    LocalPlayer.Character:MoveTo(firePlayerPart and firePlayerPart.Position or Vector3.zero)
                end
                task.wait()
                if LocalPlayer.Character:FindFirstChild("Humanoid") then
                    LocalPlayer.Character:MoveTo(originalPosition)
                end
                local bodyPosition = Instance.new("BodyPosition")
                bodyPosition.P = 200000
                bodyPosition.Position = LocalPlayer.Character.Head.Position + Vector3.new(0, 600, 0)
                bodyPosition.Parent = campfire.Main
                local bodyVelocity = Instance.new("BodyVelocity")
                bodyVelocity.MaxForce = Vector3.new(0, 0, 0)
                bodyVelocity.Velocity = Vector3.new(0, 0, 0)
                if firePlayerPart then
                    bodyVelocity.Parent = firePlayerPart
                end
                RunService.Heartbeat:Connect(function()
                    for _, player in ipairs(Players:GetPlayers()) do
                        if player ~= LocalPlayer then
                            local folder = Workspace:FindFirstChild("Folder")
                            local toysFolder = (folder and folder:FindFirstChild(player.Name .. "SpawnedInToys")) or Workspace:FindFirstChild(player.Name .. "SpawnedInToys")
                            if toysFolder then
                                for _, snowball in ipairs(toysFolder:GetChildren()) do
                                    pcall(function()
                                        if snowball:IsA("Model") and snowball.Name == "BallSnowball" then
                                            local targetPart = snowball.PrimaryPart or snowball:FindFirstChildWhichIsA("BasePart")
                                            if targetPart and campfire then
                                                campfire:SetPrimaryPartCFrame(CFrame.new(targetPart.Position))
                                                if bodyVelocity then
                                                    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
                                                end
                                                if bodyPosition then
                                                    bodyPosition.Position = Vector3.new(0, 600, 0)
                                                end
                                            end
                                        end
                                    end)
                                end
                            end
                        end
                    end
                end)
            end
        end
    end)
end

DefenseTab:AddToggle({
    Name = "アンチ雪玉V2",
    Default = false,
    Callback = function(enabled)
        if enabled then
            if BSATCoroutine then coroutine.close(BSATCoroutine) end
            BSATCoroutine = coroutine.create(BSAT)
            coroutine.resume(BSATCoroutine)
            if SSCoroutine then coroutine.close(SSCoroutine) end
            SSCoroutine = coroutine.create(function()
                while true do
                    pcall(function()
                        local character = LocalPlayer.Character
                        if character and character:FindFirstChild("HumanoidRootPart") then
                            local root = character.HumanoidRootPart
                            for _, player in pairs(Players:GetPlayers()) do
                                local toysFolder = workspace:FindFirstChild(player.Name .. "SpawnedInToys")
                                if toysFolder then
                                    for _, obj in pairs(toysFolder:GetChildren()) do
                                        coroutine.wrap(function()
                                            if obj:IsA("Model") and obj.Name == "Campfire" then
                                                local soundPart = obj:FindFirstChild("SoundPart")
                                                if soundPart and soundPart:IsA("BasePart") then
                                                    local dist = (soundPart.Position - root.Position).Magnitude
                                                    if dist <= aaaa then
                                                        local setNetworkOwner = ReplicatedStorage:FindFirstChild("GrabEvents") and ReplicatedStorage.GrabEvents:FindFirstChild("SetNetworkOwner")
                                                        if setNetworkOwner then
                                                            setNetworkOwner:FireServer(soundPart, soundPart.CFrame)
                                                        end
                                                        task.wait()
                                                        local velocity = soundPart:FindFirstChild("l") or Instance.new("BodyVelocity", soundPart)
                                                        velocity.Name = "l"
                                                        velocity.Velocity = Vector3.new(0, 0, 0)
                                                        velocity.MaxForce = Vector3.new(0, math.huge, 0)
                                                        Debris:AddItem(velocity, 0)
                                                    end
                                                end
                                                local FirePlayerPart = obj:FindFirstChild("FirePlayerPart")
                                                if FirePlayerPart and FirePlayerPart:IsA("BasePart") then
                                                    local dist = (FirePlayerPart.Position - root.Position).Magnitude
                                                    if dist <= aaaa then
                                                        local setNetworkOwner = ReplicatedStorage:FindFirstChild("GrabEvents") and ReplicatedStorage.GrabEvents:FindFirstChild("SetNetworkOwner")
                                                        if setNetworkOwner then
                                                            setNetworkOwner:FireServer(FirePlayerPart, FirePlayerPart.CFrame)
                                                        end
                                                        task.wait()
                                                        local velocity = FirePlayerPart:FindFirstChild("l") or Instance.new("BodyVelocity", FirePlayerPart)
                                                        velocity.Name = "l"
                                                        velocity.Velocity = Vector3.new(0, 0, 0)
                                                        velocity.MaxForce = Vector3.new(0, math.huge, 0)
                                                        Debris:AddItem(velocity, 0)
                                                    end
                                                end
                                            end
                                        end)()
                                    end
                                end
                            end
                        end
                    end)
                    task.wait()
                end
            end)
            coroutine.resume(SSCoroutine)
        else
            if BSATCoroutine then
                coroutine.close(BSATCoroutine)
                BSATCoroutine = nil
            end
            if SSCoroutine then
                coroutine.close(SSCoroutine)
                SSCoroutine = nil
            end
        end
    end
})

DefenseTab:AddButton({
    Name = "直接突破無効,雪玉",
    Callback = function()
        local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local head = character:WaitForChild("Head")
        local function createPart(size, color, transparency, anchored, collide)
            local part = Instance.new("Part")
            part.Size = size
            part.Anchored = anchored
            part.CanCollide = collide
            part.Transparency = transparency
            part.BrickColor = BrickColor.new(color)
            part.Parent = Workspace
            return part
        end
        local basketSize = 30
        local halfSize = basketSize / 2
        local transparency = 1
        local platform = createPart(Vector3.new(basketSize, 0.1, basketSize), "Bright blue", transparency, true, true)
        local posts = {}
        for i = 1, 4 do
            local post = createPart(Vector3.new(0.4, 4, 0.4), "Bright blue", transparency, true, true)
            table.insert(posts, post)
        end
        local walls = {}
        for i = 1, 4 do
            local wallSize = (i <= 2) and Vector3.new(basketSize, 4, 0.2) or Vector3.new(0.2, 4, basketSize)
            local wall = createPart(wallSize, "Bright blue", transparency, true, true)
            table.insert(walls, wall)
        end
        RunService.RenderStepped:Connect(function()
            if character and head then
                local basePos = head.Position + Vector3.new(0, 0.4, 0)
                platform.Position = basePos
                if posts[1] then posts[1].Position = basePos + Vector3.new(halfSize - 0.05, 2, halfSize - 0.05) end
                if posts[2] then posts[2].Position = basePos + Vector3.new(-halfSize + 0.05, 2, halfSize - 0.05) end
                if posts[3] then posts[3].Position = basePos + Vector3.new(halfSize - 0.05, 2, -halfSize + 0.05) end
                if posts[4] then posts[4].Position = basePos + Vector3.new(-halfSize + 0.05, 2, -halfSize + 0.05) end
                if walls[1] then walls[1].Position = basePos + Vector3.new(0, 2, halfSize) end
                if walls[2] then walls[2].Position = basePos + Vector3.new(0, 2, -halfSize) end
                if walls[3] then walls[3].Position = basePos + Vector3.new(halfSize, 2, 0) end
                if walls[4] then walls[4].Position = basePos + Vector3.new(-halfSize, 2, 0) end
            end
        end)
    end
})

DefenseTab:AddToggle({
    Name = "Bring軽減",
    Default = false,
    Callback = function(state)
        toggleBringEnabled = state
        if state then
            if bringCoroutine then coroutine.close(bringCoroutine) end
            bringCoroutine = coroutine.create(bringLoop)
            coroutine.resume(bringCoroutine)
        else
            if bringCoroutine then
                coroutine.close(bringCoroutine)
                bringCoroutine = nil
            end
            cleanupBringReduction()
        end
    end
})

DefenseTab:AddSlider({
    Name = "Bring軽減座標",
    Min = -34000000,
    Max = 34000000,
    Default = -30,
    Callback = function(value)
        R_raaa = value
    end
})

-- ================= タブ7: オーラ（FTAP K HUB統合版） =================
local AuraTab = Window:MakeTab({Name = "オーラ", Icon = "rbxassetid://117381520745599"})

AuraTab:AddSection({Name = "⚡ オーラ設定 ⚡"})

AuraTab:AddSlider({
    Name = "オーラ範囲",
    Min = 5,
    Max = 100,
    Default = 20,
    Increment = 1,
    Callback = function(value)
        auraRadius = value
    end
})

AuraTab:AddToggle({
    Name = "フレンドをホワイトリスト",
    Default = false,
    Callback = function(value)
        whitelistFriends = value
    end
})

AuraTab:AddSection({Name = "── オーラモード ──"})

AuraTab:AddToggle({
    Name = "🔘 グラブオーラ",
    Default = false,
    Callback = function(state)
        isGrabAuraEnabled = state
        if state then
            startGrabAura()
            OrionLib:MakeNotification({Name="グラブオーラ", Content="ON", Time=2})
        elseif auraConnections.GrabAura then
            auraConnections.GrabAura:Disconnect()
            auraConnections.GrabAura = nil
            OrionLib:MakeNotification({Name="グラブオーラ", Content="OFF", Time=2})
        end
    end
})

AuraTab:AddToggle({
    Name = "📤 デリートオーラ（上空へ）",
    Default = false,
    Callback = function(state)
        isDeleteAuraEnabled = state
        if state then
            startDeleteAura()
            OrionLib:MakeNotification({Name="デリートオーラ", Content="ON", Time=2})
        elseif auraConnections.DeleteAura then
            auraConnections.DeleteAura:Disconnect()
            auraConnections.DeleteAura = nil
            OrionLib:MakeNotification({Name="デリートオーラ", Content="OFF", Time=2})
        end
    end
})

AuraTab:AddToggle({
    Name = "💨 フリングオーラ（ランダム）",
    Default = false,
    Callback = function(state)
        isFlingAuraEnabled = state
        if state then
            startFlingAura()
            OrionLib:MakeNotification({Name="フリングオーラ", Content="ON", Time=2})
        elseif auraConnections.FlingAura then
            auraConnections.FlingAura:Disconnect()
            auraConnections.FlingAura = nil
            OrionLib:MakeNotification({Name="フリングオーラ", Content="OFF", Time=2})
        end
    end
})

AuraTab:AddParagraph("⚠️ 注意", "複数のオーラを同時にONにすると\nパフォーマンスに影響する可能性があります")

-- ================= タブ8: ブロブマンオーラ（元からあったもの）=================
local BlobmanAuraTab = Window:MakeTab({Name = "ブロブマンオーラ", Icon = "rbxassetid://4483345998"})
BlobmanAuraTab:AddToggle({
    Name = "🤖ブロブマンキルオーラ（半径35・自動乗車付き）",
    Default = false,
    Callback = function(v)
        bmkAuraEnabled = v
        if v then 
            startAura()
            OrionLib:MakeNotification({Name="ブロブマンキルオーラ", Content="ON（自動乗車付き）", Time=2})
        else
            stopAura()
            OrionLib:MakeNotification({Name="ブロブマンキルオーラ", Content="OFF", Time=2})
        end
    end
})

OrionLib:Init()
print("ササミックスHUB FTAP🕊️ 完全版 - オーラ統合 + キル系リスト自動更新 + LOOP機能統合 + 元のコード完全維持！")
