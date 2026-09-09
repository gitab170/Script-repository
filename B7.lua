-- ==========================================
-- Sushi Hub - 完全統合版
-- ==========================================

-- ==========================================
-- 1. 設定・初期値
-- ==========================================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Debris = game:GetService("Debris")
local VirtualUser = game:GetService("VirtualUser")

local GroupId = 51439630      -- 指定のコミュニティID
local StaticKey = "sushi67"   -- 未参加者に要求するパスワード
local KeyExpiryTime = 86400   -- キーの有効期限（24時間）
local ConfigFileName = "SushiHub_StaticKeyData.json"

-- OrionLib の読み込み
local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/jadpy/suki/refs/heads/main/orion"))()

-- ==========================================
-- 2. セーブデータ（期限切れ）チェック
-- ==========================================
local function CheckSavedKey()
    if isfile and isfile(ConfigFileName) then
        local success, data = pcall(function()
            return game:GetService("HttpService"):JSONDecode(readfile(ConfigFileName))
        end)
        if success and data and data.Key == StaticKey then
            if os.time() - data.Time < KeyExpiryTime then
                return true
            end
        end
    end
    return false
end

local function SaveKeyData()
    if writefile then
        local data = {
            Key = StaticKey,
            Time = os.time()
        }
        writefile(ConfigFileName, game:GetService("HttpService"):JSONEncode(data))
    end
end

-- ==========================================
-- 3. 変数定義（全機能用）
-- ==========================================
-- ブレインロット用
_G.SaisenSpam = false

-- 掴む機能用
local selectedPlayer = nil
local selectedActionTargetName = nil
local strengthConnection = nil
local nageru = 400
local poisonGrabCoroutine = nil
local ufoGrabCoroutine = nil
local fireGrabCoroutine = nil
local poisonHurtParts = {}
local paintPlayerParts = {}

-- プレイヤー機能用
local superSpeed = false
local infiniteJump = false
local noclip = false
local noclipConn = nil
local Multiplier = 0.15

-- ESP用
local espEnabled = false
local espHighlights = {}

-- 掴むトグル
local GrabToggles = { KillGrab = false, SkyGrab = false, DownGrab = false, StableGrab = false }
local GrabConnections = {}

-- ブロブマンキルオーラ用
local bmkAuraEnabled = false
local AURA_RADIUS = 35
local auraConn = nil
local auraInRange = {}
local cachedCG, cachedCD, cachedCR = nil, nil, nil
local cachedR_Det, cachedR_Weld = nil, nil
local cachedL_Det, cachedL_Weld = nil, nil
local cachedBlobman = nil
local playerThreads = {}

-- アンチ機能用
local autoStruggleCoroutine = nil
local autoGucciT = false
local sitJumpT = false
local ragdollLoopD = false
local blobmanInstanceS = nil
local currentHouseS = 0
local permRagdollT = false
local permRagdollRunningS = false
local antikickRunning = false
local antikickKCoroutine = nil
local antiblob = false
local blobLoopT2 = false
local currentBlobS = nil
local connection = nil
local antiburn = false
local antiExplosionConnection = nil
local characterAddedConn = nil
local FF5 = false
local FF2 = nil
local FF3 = "FireExtinguisher"
local FCoroutine = nil
local antiLagT = false
local antikick = false
local toggleBringEnabled = false
local R_raaa = -30
local bringCoroutine = nil
local aaaa = 20
local BSATCoroutine = nil
local SSCoroutine = nil
local protectionEnabled = false
local connections = {}

-- ==========================================
-- 4. 毒/ペイントパーツ収集
-- ==========================================
for _, descendant in ipairs(Workspace:GetDescendants()) do
    if descendant.Name == "PoisonHurtPart" then
        table.insert(poisonHurtParts, descendant)
    elseif descendant.Name == "PaintPlayerPart" then
        table.insert(paintPlayerParts, descendant)
    end
end

-- ==========================================
-- 5. 掴む機能
-- ==========================================
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

local function handleGrabPart(model, mode)
    if model.Name == "GrabParts" then
        local part_to_impulse = model:FindFirstChild("GrabPart")
        if part_to_impulse and part_to_impulse:FindFirstChild("WeldConstraint") then
            local target = part_to_impulse.WeldConstraint.Part1
            if target then
                if mode == "Kill" then
                    local hum = target.Parent and target.Parent:FindFirstChildOfClass("Humanoid")
                    if hum then hum.Health = 0 end
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
        if GrabConnections[flag] then GrabConnections[flag]:Disconnect() end
        GrabConnections[flag] = Workspace.ChildAdded:Connect(function(model) handleGrabPart(model, mode) end)
    elseif GrabConnections[flag] then
        GrabConnections[flag]:Disconnect()
        GrabConnections[flag] = nil
    end
end

-- ==========================================
-- 6. ブロブマンキルオーラ機能
-- ==========================================
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

-- ==========================================
-- 7. アンチ機能
-- ==========================================
-- アンチ掴むV2用
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

-- アンチキック解除
local function antikickK()
    local function spawnItemCf(itemName, cframe)
        task.spawn(function()
            local spawnRemote = ReplicatedStorage:FindFirstChild("MenuToys") and ReplicatedStorage.MenuToys:FindFirstChild("SpawnToyRemoteFunction")
            if spawnRemote then
                pcall(function()
                    spawnRemote:InvokeServer(itemName, cframe, Vector3.new(0, 0, 0))
                end)
            end
        end)
    end
    
    while antikickRunning do
        pcall(function()
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
                        end
                    end
                end
            end
        end)
        task.wait(0.001)
    end
end

-- アンチブロブマン
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

-- アンチブリングtest
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

-- アンチラグドール
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

-- アンチ爆発
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

-- アンチファイヤall
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

-- アンチラグ
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

-- Bring軽減
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

-- アンチブロブマンv2用
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

-- アンチ雪玉V2用
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
                            local folder = workspace:FindFirstChild("Folder")
                            local toysFolder = (folder and folder:FindFirstChild(player.Name .. "SpawnedInToys")) or workspace:FindFirstChild(player.Name .. "SpawnedInToys")
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

-- ==========================================
-- 8. プレイヤーリスト取得
-- ==========================================
local function getPlayers()
    local t = {}
    for _, p in pairs(Players:GetPlayers()) do if p ~= LocalPlayer then table.insert(t, p.DisplayName .. " (@" .. p.Name .. ")") end end
    return t
end

-- ==========================================
-- 9. メインGUI
-- ==========================================
local function LoadMainGUI()
    local MainWindow = OrionLib:MakeWindow({
        Name = "Sushi Hub - 完全統合版", 
        HidePremium = true, 
        SaveConfig = false
    })
    
    -- ==========================================
    -- タブ0: ブレインロット
    -- ==========================================
    local BrainRotTab = MainWindow:MakeTab({
        Name = "ブレインロット",
        Icon = "rbxassetid://4483345998"
    })
    
    BrainRotTab:AddParagraph("それってあなたの感想ですよね？", "在庫無視からラック偽装まで、なぁぜなぁぜ？")
    
    -- ラック999倍
    BrainRotTab:AddButton({
        Name = "🍀 ラック999倍（クライアント偽装）",
        Callback = function()
            if firesignal then
                local args = { [1] = { FuseCharacterCount = 0, GenerationBonusActive = false, IsActive = true, LuckValue = 999 } }
                local remoteEvent = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("Fuse_lul") and ReplicatedStorage.Remotes.Fuse_lul:FindFirstChild("LuckStatusUpdate")
                if remoteEvent then
                    firesignal(remoteEvent.OnClientEvent, table.unpack(args))
                    OrionLib:MakeNotification({ Name = "Sushi Hub", Content = "ラックを999倍に偽装しました！", Time = 3 })
                else
                    OrionLib:MakeNotification({ Name = "エラー", Content = "LuckStatusUpdate イベントが見つかりません。", Time = 3 })
                end
            else
                OrionLib:MakeNotification({ Name = "エラー", Content = "お使いのエグゼキューターは firesignal に対応していません。", Time = 4 })
            end
        end
    })
    
    -- 賽銭強制購入
    BrainRotTab:AddButton({
        Name = "💸 賽銭強制購入 (在庫無視アタック)",
        Callback = function()
            local remote = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("SaisenLuckyBlockSpawn")
            if remote then
                pcall(function() remote:FireServer(1) end)
                pcall(function() remote:FireServer(true) end)
                pcall(function() remote:FireServer("Saisen", 1) end)
                pcall(function() remote:FireServer({}) end)
                OrionLib:MakeNotification({ Name = "Sushi Hub", Content = "在庫抜けの強制パケットを送信しました！", Time = 2 })
            end
        end
    })
    
    -- 自動賽銭スパム
    BrainRotTab:AddToggle({
        Name = "自動賽銭スパム (在庫無視連打)",
        Default = false,
        Callback = function(Value)
            _G.SaisenSpam = Value
            while _G.SaisenSpam do
                local remote = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("SaisenLuckyBlockSpawn")
                if remote then
                    pcall(function() remote:FireServer(1) end)
                    pcall(function() remote:FireServer(true) end)
                end
                task.wait(0.1)
            end
        end
    })
    
    -- ==========================================
    -- タブ1: 掴む
    -- ==========================================
    local GrabTab = MainWindow:MakeTab({ Name = "掴む", Icon = "rbxassetid://73570431850302" })
    
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
    
    GrabTab:AddSlider({ Name = "投げる強さ", Min = 300, Max = 4000, Default = 400, Callback = function(v) nageru = v end })
    
    GrabTab:AddToggle({
        Name = "毒掴む",
        Default = false,
        Callback = function(enabled)
            if enabled then
                poisonGrabCoroutine = coroutine.create(function() grabHandler("poison") end)
                coroutine.resume(poisonGrabCoroutine)
            elseif poisonGrabCoroutine then
                coroutine.close(poisonGrabCoroutine)
                poisonGrabCoroutine = nil
                for _, part in pairs(poisonHurtParts) do part.Position = Vector3.new(0, -200, 0) end
            end
        end
    })
    
    GrabTab:AddToggle({
        Name = "Radioactive掴む",
        Default = false,
        Callback = function(enabled)
            if enabled then
                ufoGrabCoroutine = coroutine.create(function() grabHandler("radioactive") end)
                coroutine.resume(ufoGrabCoroutine)
            elseif ufoGrabCoroutine then
                coroutine.close(ufoGrabCoroutine)
                ufoGrabCoroutine = nil
                for _, part in pairs(paintPlayerParts) do part.Position = Vector3.new(0, -200, 0) end
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
            elseif fireGrabCoroutine then
                coroutine.close(fireGrabCoroutine)
                fireGrabCoroutine = nil
            end
        end
    })
    
    GrabTab:AddToggle({ Name = "キル掴む", Default = false, Callback = function(v) GrabToggles.KillGrab = v; toggleGrab("KillGrab", "Kill") end })
    GrabTab:AddToggle({ Name = "上に上がる掴む", Default = false, Callback = function(v) GrabToggles.SkyGrab = v; toggleGrab("SkyGrab", "Sky") end })
    GrabTab:AddToggle({ Name = "下に下がる掴む", Default = false, Callback = function(v) GrabToggles.DownGrab = v; toggleGrab("DownGrab", "Down") end })
    GrabTab:AddToggle({ Name = "高さを保ちながら掴む", Default = false, Callback = function(v) GrabToggles.StableGrab = v; toggleGrab("StableGrab", "Stable") end })
    
    -- ==========================================
    -- タブ2: プレイヤー
    -- ==========================================
    local PlayerTab = MainWindow:MakeTab({ Name = "プレイヤー", Icon = "rbxassetid://7743871002" })
    PlayerTab:AddSection({ Name = "移動速度" })
    PlayerTab:AddToggle({ Name = "移動速度", Default = false, Callback = function(v) superSpeed = v end })
    PlayerTab:AddSlider({ Name = "速度倍率", Min = 0.1, Max = 5, Default = 0.15, Increment = 0.01, Callback = function(v) Multiplier = v end })
    PlayerTab:AddSection({ Name = "無限ジャンプ" })
    PlayerTab:AddToggle({ Name = "無限ジャンプ", Default = false, Callback = function(v) infiniteJump = v end })
    PlayerTab:AddSlider({ Name = "ジャンプ力", Min = 24, Max = 1000, Default = 24, Increment = 10, Callback = function(v)
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.JumpPower = v end
    end })
    PlayerTab:AddSection({ Name = "壁抜け" })
    PlayerTab:AddToggle({
        Name = "壁抜け",
        Default = false,
        Callback = function(v)
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
        end
    })
    
    -- ==========================================
    -- タブ3: ESP
    -- ==========================================
    local ESP_Tab = MainWindow:MakeTab({ Name = "ESP", Icon = "rbxassetid://7733774602" })
    ESP_Tab:AddSection({ Name = "ESPハイライト" })
    ESP_Tab:AddToggle({
        Name = "ESP（ハイライト）",
        Default = false,
        Callback = function(val)
            espEnabled = val
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
                    elseif espHighlights[p] then
                        espHighlights[p]:Destroy()
                        espHighlights[p] = nil
                    end
                end
            end
        end
    })
    
    -- ==========================================
    -- タブ4: キルオーラ
    -- ==========================================
    local AuraTab = MainWindow:MakeTab({ Name = "キルオーラ", Icon = "rbxassetid://117381520745599" })
    AuraTab:AddToggle({ Name = "🤖ブロブマンキルオーラ（半径35・自動乗車付き）", Default = false, Callback = function(v)
        bmkAuraEnabled = v
        if v then 
            startAura()
            OrionLib:MakeNotification({ Name = "Sushi Hub", Content = "ブロブマンキルオーラ ON", Time = 2 })
        else
            stopAura()
            OrionLib:MakeNotification({ Name = "Sushi Hub", Content = "ブロブマンキルオーラ OFF", Time = 2 })
        end
    end })
    
    -- ==========================================
    -- タブ5: アンチ
    -- ==========================================
    local DefenseTab = MainWindow:MakeTab({ Name = "アンチ", Icon = "rbxassetid://129017321982695" })
    
    -- アンチ掴む
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
    
    -- アンチ掴むV2
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
    
    -- アンチキック解除
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
    
    -- アンチブロブマン
    DefenseTab:AddToggle({
        Name = "アンチブロブマン",
        Default = false,
        Callback = function(Value)
            SetAntiBlobman(Value)
        end
    })
    
    -- アンチブロブマンv2
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
    
    -- アンチブリングtest
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
    
    -- ラグドール起こし
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
    
    -- アンチラグドールテスト
    DefenseTab:AddToggle({
        Name = "アンチラグドールテスト",
        Default = false,
        Callback = function(Value)
            setProtection(Value)
        end
    })
    
    -- 奈落
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
    
    -- アンチファイヤ
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
    
    -- アンチ爆発
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
    
    -- アンチファイヤall
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
    
    -- アンチラグ
    DefenseTab:AddToggle({
        Name = "アンチラグ",
        Default = false,
        Callback = function(Value)
            antiLagT = Value
            antiLagF()
        end
    })
    
    -- アンチキック
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
    
    -- アンチリスキル
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
    
    -- アンチ雪玉
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
    
    -- アンチ雪玉V2
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
    
    -- 直接突破無効,雪玉
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
    
    -- Bring軽減
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
    
    -- ==========================================
    -- タブ6: その他
    -- ==========================================
    local OtherTab = MainWindow:MakeTab({ Name = "その他", Icon = "rbxassetid://4483345998" })
    OtherTab:AddParagraph("ステータス", "Sushi Hub 完全統合版 正常稼働中")
    
    OrionLib:Init()
end

-- 移動速度/無限ジャンプのループ
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

-- ==========================================
-- 10. キーシステム画面
-- ==========================================
local function ShowKeySystemMenu()
    local KeyWindow = OrionLib:MakeWindow({
        Name = "Sushi Hub - キーシステム", 
        HidePremium = true, 
        SaveConfig = false,
        KeySystem = true,
        Title = "認証が必要です",
        Subtitle = "コミュニティ参加者はこの画面をスキップできます",
        FileName = "SushiHubKey",
        SaveKey = StaticKey,
        KeySettings = {
            Title = "コミュニティに参加してスキップ",
            Description = "グループ(ID: 51439630)に参加すると、次回から自動スキップされます。",
            Link = "https://www.roblox.com/groups/" .. tostring(GroupId)
        }
    })

    local AuthTab = KeyWindow:MakeTab({
        Name = "完了手続き",
        Icon = "rbxassetid://4483345998"
    })
    
    AuthTab:AddButton({
        Name = "ログインを確定して24時間保存する",
        Callback = function()
            SaveKeyData()
            OrionLib:Destroy()
            task.wait(0.5)
            LoadMainGUI()
        end
    })

    OrionLib:Init()
end

-- ==========================================
-- 11. メイン実行ロジック
-- ==========================================
if LocalPlayer:IsInGroup(GroupId) then
    LoadMainGUI()
else
    if CheckSavedKey() then
        LoadMainGUI()
    else
        ShowKeySystemMenu()
    end
end
