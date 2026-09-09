-- =====================================================
-- Obsidian UI (LinoriaLibベース) への変換
-- 元のスクリプト: かつらハブ (OrionLib)
-- 変換日: 2026-09-05
-- バージョン: v0.2
-- =====================================================

local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

Library.ForceCheckbox = false
Library.ShowToggleFrameInKeybinds = true

-- =====================================================
-- ウィンドウ作成
-- =====================================================
local Window = Library:CreateWindow({
    Title = "かつらハブ v0.2",
    Footer = "Katsura Hub v0.2",
    Icon = 4483345998,
    NotifySide = "Right",
    ShowCustomCursor = true,
})

-- =====================================================
-- タブ定義
-- =====================================================
local Tabs = {
    Main = Window:AddTab("メイン", "sword"),
    Kick = Window:AddTab("キック", "crosshair"),
    Lag = Window:AddTab("ラグ", "zap"),
    Aura = Window:AddTab("オーラ", "users"),
    ["UI Settings"] = Window:AddTab("UI設定", "settings"),
}

-- =====================================================
-- グローバル変数
-- =====================================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer

-- =====================================================
-- メインタブ - グループボックス
-- =====================================================
local MainGroup = Tabs.Main:AddLeftGroupbox("キックコントロール", "user")
local TargetGroup = Tabs.Main:AddRightGroupbox("ターゲット選択", "crosshair")

-- =====================================================
-- 共通プレイヤーリスト
-- =====================================================
local selectedKickPlayer = nil
local playerListCache = {}

local function getPlayerList()
    local list = {}
    playerListCache = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= Player then
            local display = plr.DisplayName .. " (" .. plr.Name .. ")"
            table.insert(list, display)
            playerListCache[display] = plr
        end
    end
    return list
end

local function getPlayerFromSelection(selection)
    if not selection then return nil end
    return playerListCache[selection]
end

-- ターゲット選択ドロップダウン
TargetGroup:AddDropdown("TargetSelector", {
    Values = getPlayerList(),
    Default = "",
    Text = "ターゲット選択",
    Tooltip = "キックするプレイヤーを選択します",
    Callback = function(Value)
        selectedKickPlayer = getPlayerFromSelection(Value)
        if selectedKickPlayer then
            Library:Notify({
                Title = "ターゲット選択",
                Description = "選択: " .. selectedKickPlayer.DisplayName,
                Time = 2,
            })
        end
    end,
})

TargetGroup:AddButton({
    Text = "🔄 リスト更新",
    Func = function()
        local newList = getPlayerList()
        Options.TargetSelector:SetValues(newList)
        Library:Notify({
            Title = "更新完了",
            Description = "プレイヤーリストを更新しました",
            Time = 2,
        })
    end,
    Tooltip = "プレイヤーリストを最新の状態に更新します",
})

-- =====================================================
-- 共通変数（ブロブマン管理）
-- =====================================================
local currentBlobman = nil
local blobmanEnabled = false
local blobmanSpawnConnection = nil
local isProcessing = false

-- プレイヤー死亡監視
local playerDiedConnection = nil
local isKickActive = false

-- =====================================================
-- ブロブマン自動リスポーン機能
-- =====================================================
local function GetSeatedBlobman()
    local char = Player.Character
    if not char then return nil end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return nil end
    local seat = humanoid.SeatPart
    if not seat or not seat:IsA("VehicleSeat") then return nil end
    local obj = seat
    while obj do
        if obj:IsA("Model") and obj.Name == "CreatureBlobman" then
            return obj
        end
        obj = obj.Parent
    end
    return nil
end

local function SpawnBlobman()
    local char = Player.Character
    if not char then return nil end
    local rootPart = char:FindFirstChild("HumanoidRootPart")
    if not rootPart then return nil end

    local existing = GetSeatedBlobman()
    if existing then 
        currentBlobman = existing
        return existing 
    end

    local spawnPos = rootPart.CFrame * CFrame.new(0, 0, -5)
    local success, result = pcall(function()
        return ReplicatedStorage.MenuToys.SpawnToyRemoteFunction:InvokeServer("CreatureBlobman", spawnPos, Vector3.new(0, 127, 0))
    end)
    
    if not success then return nil end

    local toyFolderName = Player.Name .. "SpawnedInToys"
    local blobman = nil
    local startTime = tick()
    repeat
        local toyFolder = Workspace:FindFirstChild(toyFolderName)
        if toyFolder then blobman = toyFolder:FindFirstChild("CreatureBlobman") end
        if blobman then break end
        task.wait(0.1)
    until tick() - startTime > 3
    
    if not blobman then return nil end

    local seat = blobman:FindFirstChild("VehicleSeat")
    if seat then
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if humanoid then 
            seat:Sit(humanoid)
            task.wait(0.1)
        end
    end
    currentBlobman = blobman
    return blobman
end

local function ForceSpawnBlobman()
    if not blobmanEnabled then return end
    local existing = GetSeatedBlobman()
    if existing then 
        currentBlobman = existing
        return 
    end
    local blobman = SpawnBlobman()
    if blobman then
        currentBlobman = blobman
    end
end

local function StartBlobmanMonitor()
    if blobmanSpawnConnection then return end
    blobmanSpawnConnection = RunService.Heartbeat:Connect(function()
        if not blobmanEnabled then return end
        if not Player.Character then return end
        local blobman = GetSeatedBlobman()
        if not blobman then
            ForceSpawnBlobman()
        else
            currentBlobman = blobman
        end
    end)
end

local function StopBlobmanMonitor()
    if blobmanSpawnConnection then
        blobmanSpawnConnection:Disconnect()
        blobmanSpawnConnection = nil
    end
    currentBlobman = nil
end

local function sitOnBlobman()
    if not currentBlobman or not currentBlobman.Parent then return false end
    
    local seat = currentBlobman:FindFirstChild("VehicleSeat")
    if not seat then
        for _, child in ipairs(currentBlobman:GetChildren()) do
            if child:IsA("VehicleSeat") or child.Name:find("Seat") then
                seat = child
                break
            end
        end
    end
    
    if not seat then return false end
    
    local char = Player.Character
    if not char then return false end
    
    local hum = char:FindFirstChild("Humanoid")
    if not hum then return false end
    
    pcall(function()
        hum.Sit = true
        hum.SeatPart = seat
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.CFrame = seat.CFrame * CFrame.new(0, 0, 0)
        end
    end)
    
    task.wait(0.5)
    return hum.SeatPart == seat
end

-- =====================================================
-- キック停止処理
-- =====================================================
local function stopAllKicks()
    isKickActive = false
    
    -- 全トグルをOFFに
    if Toggles.DriftKick then Toggles.DriftKick:SetValue(false) end
    if Toggles.KickV1 then Toggles.KickV1:SetValue(false) end
    if Toggles.KickV2 then Toggles.KickV2:SetValue(false) end
    if Toggles.KickV3 then Toggles.KickV3:SetValue(false) end
    if Toggles.KickV4 then Toggles.KickV4:SetValue(false) end
    if Toggles.KickV5 then Toggles.KickV5:SetValue(false) end
    if Toggles.KickV6 then Toggles.KickV6:SetValue(false) end
    
    blobmanEnabled = false
    StopBlobmanMonitor()
    
    if playerDiedConnection then
        playerDiedConnection:Disconnect()
        playerDiedConnection = nil
    end
end

-- =====================================================
-- ドリフトキック（ぐるぐるバージョン 高さ6固定）
-- =====================================================
local kickLoopEnabled = false
local orbitAngle = 0
local orbitRadius = 20
local orbitSpeed = 23
local floatHeight = 6
local driftKickThread = nil

MainGroup:AddToggle("DriftKick", {
    Text = "🔄 ドリフトキック",
    Tooltip = "ターゲットを高さ6でぐるぐる回します",
    Default = false,
    Callback = function(on)
        if not on then
            kickLoopEnabled = false
            orbitAngle = 0
            if driftKickThread then
                task.cancel(driftKickThread)
                driftKickThread = nil
            end
            blobmanEnabled = false
            StopBlobmanMonitor()
            return
        end

        if not selectedKickPlayer then
            Library:Notify({
                Title = "エラー",
                Description = "先にターゲットを選択してください",
                Time = 3,
            })
            Toggles.DriftKick:SetValue(false)
            return
        end
        
        if not blobmanEnabled then
            blobmanEnabled = true
            isProcessing = true
            task.spawn(function()
                local success = false
                for i = 1, 3 do
                    local blobman = SpawnBlobman()
                    if blobman then
                        success = true
                        break
                    end
                    task.wait(0.5)
                end
                
                if success then
                    StartBlobmanMonitor()
                else
                    blobmanEnabled = false
                    Library:Notify({
                        Title = "エラー",
                        Description = "ブロブマンのスポーンに失敗しました",
                        Time = 3,
                    })
                    Toggles.DriftKick:SetValue(false)
                    return
                end
                isProcessing = false
            end)
            
            local waitCount = 0
            while (not currentBlobman or not currentBlobman.Parent) and waitCount < 30 do
                task.wait(0.1)
                waitCount = waitCount + 1
            end
            if not currentBlobman or not currentBlobman.Parent then
                Library:Notify({
                    Title = "エラー",
                    Description = "ブロブマンが準備できていません",
                    Time = 3,
                })
                Toggles.DriftKick:SetValue(false)
                return
            end
        else
            if not currentBlobman or not currentBlobman.Parent then
                local waitCount = 0
                while (not currentBlobman or not currentBlobman.Parent) and waitCount < 30 do
                    task.wait(0.1)
                    waitCount = waitCount + 1
                end
                if not currentBlobman or not currentBlobman.Parent then
                    Library:Notify({
                        Title = "エラー",
                        Description = "ブロブマンが準備できていません",
                        Time = 3,
                    })
                    Toggles.DriftKick:SetValue(false)
                    return
                end
            end
        end
        
        local sat = sitOnBlobman()
        if not sat then
            Library:Notify({
                Title = "情報",
                Description = "ブロブマンに座れませんでした（手動で座ってください）",
                Time = 3,
            })
        end
        
        kickLoopEnabled = true
        orbitAngle = 0
        isKickActive = true
        
        local target = selectedKickPlayer
        
        -- プレイヤー死亡監視
        if playerDiedConnection then
            playerDiedConnection:Disconnect()
            playerDiedConnection = nil
        end
        playerDiedConnection = Player.CharacterAdded:Connect(function()
            if kickLoopEnabled then
                Library:Notify({
                    Title = "情報",
                    Description = "プレイヤーが死亡したため停止しました",
                    Time = 3,
                })
                stopAllKicks()
            end
        end)
        
        Library:Notify({
            Title = "Info",
            Description = "ドリフトキックを開始しました",
            Time = 2,
        })
        
        driftKickThread = task.spawn(function()
            local GE = ReplicatedStorage:WaitForChild("GrabEvents")
            local blob = currentBlobman
            local blobRoot = blob:FindFirstChild("HumanoidRootPart") or blob.PrimaryPart
            local scriptObj = blob:FindFirstChild("BlobmanSeatAndOwnerScript")
            local CG = scriptObj and scriptObj:FindFirstChild("CreatureGrab")
            local CD = scriptObj and scriptObj:FindFirstChild("CreatureDrop")
            local R_Det = blob:FindFirstChild("RightDetector")
            local R_Weld = R_Det and (R_Det:FindFirstChild("RightWeld") or R_Det:FindFirstChildWhichIsA("Weld"))
            local SavedPos = blobRoot.CFrame
            
            local tChar = target.Character
            local tRoot = tChar and tChar:FindFirstChild("HumanoidRootPart")
            
            if tRoot and blobRoot then
                local bringStart = tick()
                while tick() - bringStart < 0.35 do
                    if not kickLoopEnabled then break end
                    blobRoot.CFrame = tRoot.CFrame
                    blobRoot.Velocity = Vector3.zero
                    pcall(function()
                        if CG and R_Det then
                            CG:FireServer(R_Det, tRoot, R_Weld)
                        end
                        GE.CreateGrabLine:FireServer(tRoot, Vector3.zero, tRoot.Position, false)
                        GE.SetNetworkOwner:FireServer(tRoot, blobRoot.CFrame)
                    end)
                    RunService.Heartbeat:Wait()
                end
                blobRoot.CFrame = SavedPos
                blobRoot.Velocity = Vector3.zero
                task.wait(0.05)
            end
            
            local packetTimer = 0
            
            while kickLoopEnabled do
                if not Player.Character or not Player.Character:FindFirstChild("Humanoid") or Player.Character.Humanoid.Health <= 0 then
                    Library:Notify({
                        Title = "情報",
                        Description = "プレイヤーが死亡したため停止しました",
                        Time = 3,
                    })
                    stopAllKicks()
                    break
                end
                
                if not target or not target.Parent or not target.Character then
                    break
                end
                if not blobRoot or not blobRoot.Parent then
                    break
                end
                
                tChar = target.Character
                tRoot = tChar and tChar:FindFirstChild("HumanoidRootPart")
                local tHum = tChar and tChar:FindFirstChild("Humanoid")
                
                if tRoot and tHum and tHum.Health > 0 then
                    local lockPos = SavedPos * CFrame.new(0, 23, 0)
                    tRoot.CFrame = lockPos
                    tRoot.Velocity = Vector3.zero
                    tRoot.RotVelocity = Vector3.zero
                    
                    orbitAngle = orbitAngle + (RunService.Heartbeat:Wait() * orbitSpeed)
                    local orbitX = math.cos(orbitAngle) * orbitRadius
                    local orbitZ = math.sin(orbitAngle) * orbitRadius
                    
                    local orbitPos = Vector3.new(lockPos.Position.X + orbitX, lockPos.Position.Y + floatHeight, lockPos.Position.Z + orbitZ)
                    local lookAtCFrame = CFrame.lookAt(orbitPos, lockPos.Position)
                    blobRoot.CFrame = lookAtCFrame
                    blobRoot.Velocity = Vector3.zero
                    
                    if tick() - packetTimer > 0.05 then
                        packetTimer = tick()
                        pcall(function()
                            tHum.PlatformStand = true
                            tHum.Sit = true
                            GE.SetNetworkOwner:FireServer(tRoot, lockPos)
                            if R_Det then
                                local weld = R_Det:FindFirstChild("RightWeld") or R_Det:FindFirstChildWhichIsA("Weld")
                                if weld then
                                    CD:FireServer(weld)
                                end
                            end
                            GE.DestroyGrabLine:FireServer(tRoot)
                            if CG and R_Det then
                                CG:FireServer(R_Det, tRoot, R_Weld)
                            end
                            GE.CreateGrabLine:FireServer(tRoot, Vector3.zero, tRoot.Position, false)
                        end)
                    end
                else
                    if blobRoot and blobRoot.Parent then
                        blobRoot.CFrame = SavedPos
                        blobRoot.Velocity = Vector3.zero
                    end
                end
                
                RunService.Heartbeat:Wait()
            end
            
            kickLoopEnabled = false
            if blobRoot and blobRoot.Parent then
                blobRoot.CFrame = SavedPos
                blobRoot.Velocity = Vector3.zero
            end
        end)
    end
})

-- =====================================================
-- ブロブキックv1（トグル）
-- =====================================================
local blobKickEnabled = false
local blobKickThread = nil

MainGroup:AddToggle("KickV1", {
    Text = "👊 キックv1",
    Tooltip = "ターゲットを掴んで保持します",
    Default = false,
    Callback = function(on)
        if not on then
            blobKickEnabled = false
            if blobKickThread then
                task.cancel(blobKickThread)
                blobKickThread = nil
            end
            return
        end

        if not selectedKickPlayer then
            Library:Notify({
                Title = "エラー",
                Description = "先にターゲットを選択してください",
                Time = 3,
            })
            Toggles.KickV1:SetValue(false)
            return
        end

        local char = Player.Character
        if not char then
            Library:Notify({
                Title = "エラー",
                Description = "キャラクターが見つかりません",
                Time = 3,
            })
            Toggles.KickV1:SetValue(false)
            return
        end

        local hum = char:FindFirstChild("Humanoid")
        if not hum then
            Library:Notify({
                Title = "エラー",
                Description = "Humanoidが見つかりません",
                Time = 3,
            })
            Toggles.KickV1:SetValue(false)
            return
        end

        local seat = hum.SeatPart
        if not seat or not seat.Parent or seat.Parent.Name ~= "CreatureBlobman" then
            Library:Notify({
                Title = "エラー",
                Description = "ブロブマンに座っている必要があります",
                Time = 3,
            })
            Toggles.KickV1:SetValue(false)
            return
        end

        blobKickEnabled = true
        isKickActive = true
        local target = selectedKickPlayer

        blobKickThread = task.spawn(function()
            local GE = ReplicatedStorage:FindFirstChild("GrabEvents")
            if not GE then
                Library:Notify({
                    Title = "エラー",
                    Description = "GrabEventsが見つかりません",
                    Time = 3,
                })
                blobKickEnabled = false
                Toggles.KickV1:SetValue(false)
                return
            end

            local blob = seat.Parent
            local blobRoot = blob:FindFirstChild("HumanoidRootPart") or blob.PrimaryPart
            if not blobRoot then
                Library:Notify({
                    Title = "エラー",
                    Description = "ブロブマンのルートパーツが見つかりません",
                    Time = 3,
                })
                blobKickEnabled = false
                Toggles.KickV1:SetValue(false)
                return
            end

            local SavedPos = blobRoot.CFrame
            
            local R_Det = blob:FindFirstChild("RightDetector")
            if not R_Det then
                for _, child in ipairs(blob:GetChildren()) do
                    if child.Name:lower():find("detector") then
                        R_Det = child
                        break
                    end
                end
            end
            
            local R_Weld = nil
            if R_Det then
                R_Weld = R_Det:FindFirstChild("RightWeld") or R_Det:FindFirstChildWhichIsA("Weld")
            end

            local scriptObj = blob:FindFirstChild("BlobmanSeatAndOwnerScript")
            local CG = scriptObj and scriptObj:FindFirstChild("CreatureGrab")
            local CD = scriptObj and scriptObj:FindFirstChild("CreatureDrop")
            
            if not CG or not CD then
                for _, child in ipairs(blob:GetDescendants()) do
                    if child:IsA("Script") or child:IsA("LocalScript") or child:IsA("ModuleScript") then
                        if not CG then CG = child:FindFirstChild("CreatureGrab") end
                        if not CD then CD = child:FindFirstChild("CreatureDrop") end
                    end
                end
            end

            local CreateGrabLine = GE:FindFirstChild("CreateGrabLine")
            local DestroyGrabLine = GE:FindFirstChild("DestroyGrabLine")
            local SetNetworkOwner = GE:FindFirstChild("SetNetworkOwner")

            local packetTimer = 0

            while blobKickEnabled do
                if not target or not target.Parent then
                    break
                end

                local tChar = target.Character
                if not tChar then
                    RunService.Heartbeat:Wait()
                    continue
                end

                local tRoot = tChar:FindFirstChild("HumanoidRootPart")
                local tHum = tChar:FindFirstChild("Humanoid")
                if not tRoot or not tHum or tHum.Health <= 0 then
                    RunService.Heartbeat:Wait()
                    continue
                end

                if not blobRoot or not blobRoot.Parent then
                    break
                end

                local dist = (blobRoot.Position - tRoot.Position).Magnitude
                if dist > 30 then
                    blobRoot.CFrame = tRoot.CFrame * CFrame.new(0, 0, 5)
                else
                    blobRoot.CFrame = SavedPos
                end
                blobRoot.Velocity = Vector3.zero

                if tick() - packetTimer > 0.05 then
                    packetTimer = tick()
                    
                    pcall(function()
                        if CG and R_Det and tRoot then
                            CG:FireServer(R_Det, tRoot, R_Weld)
                        end

                        if CreateGrabLine and tRoot then
                            CreateGrabLine:FireServer(tRoot, Vector3.zero, tRoot.Position, false)
                        end

                        if SetNetworkOwner and tRoot then
                            SetNetworkOwner:FireServer(tRoot, tRoot.CFrame)
                        end

                        if R_Det then
                            local weld = R_Det:FindFirstChild("RightWeld") or R_Det:FindFirstChildWhichIsA("Weld")
                            if weld and CD then
                                CD:FireServer(weld)
                            end
                        end

                        if DestroyGrabLine and tRoot then
                            DestroyGrabLine:FireServer(tRoot)
                        end

                        if CG and R_Det and tRoot then
                            CG:FireServer(R_Det, tRoot, R_Weld)
                        end

                        if CreateGrabLine and tRoot then
                            CreateGrabLine:FireServer(tRoot, Vector3.zero, tRoot.Position, false)
                        end
                    end)
                end

                RunService.Heartbeat:Wait()
            end

            blobKickEnabled = false
            blobKickThread = nil
        end)
    end
})

-- =====================================================
-- スピンキックv2（トグル）
-- =====================================================
local spinKickEnabled = false
local spinAngle2 = 0
local spinSpeed2 = 15
local spinKickThread = nil

MainGroup:AddToggle("KickV2", {
    Text = "🌀 キックv2",
    Tooltip = "ターゲットを周回させます",
    Default = false,
    Callback = function(on)
        if not on then
            spinKickEnabled = false
            spinAngle2 = 0
            if spinKickThread then
                task.cancel(spinKickThread)
                spinKickThread = nil
            end
            return
        end

        if not selectedKickPlayer then
            Library:Notify({
                Title = "エラー",
                Description = "先にターゲットを選択してください",
                Time = 3,
            })
            Toggles.KickV2:SetValue(false)
            return
        end

        local char = Player.Character
        if not char then
            Library:Notify({
                Title = "エラー",
                Description = "キャラクターが見つかりません",
                Time = 3,
            })
            Toggles.KickV2:SetValue(false)
            return
        end

        local hum = char:FindFirstChild("Humanoid")
        if not hum then
            Library:Notify({
                Title = "エラー",
                Description = "Humanoidが見つかりません",
                Time = 3,
            })
            Toggles.KickV2:SetValue(false)
            return
        end

        local seat = hum.SeatPart
        if not seat or not seat.Parent or seat.Parent.Name ~= "CreatureBlobman" then
            Library:Notify({
                Title = "エラー",
                Description = "ブロブマンに座っている必要があります",
                Time = 3,
            })
            Toggles.KickV2:SetValue(false)
            return
        end

        spinKickEnabled = true
        spinAngle2 = 0
        isKickActive = true
        local target = selectedKickPlayer

        spinKickThread = task.spawn(function()
            local GE = ReplicatedStorage:WaitForChild("GrabEvents")
            local blob = seat.Parent
            local blobRoot = blob:FindFirstChild("HumanoidRootPart") or blob.PrimaryPart
            local scriptObj = blob:FindFirstChild("BlobmanSeatAndOwnerScript")
            local CG = scriptObj and scriptObj:FindFirstChild("CreatureGrab")
            local CD = scriptObj and scriptObj:FindFirstChild("CreatureDrop")
            local R_Det = blob:FindFirstChild("RightDetector")
            local R_Weld = R_Det and (R_Det:FindFirstChild("RightWeld") or R_Det:FindFirstChildWhichIsA("Weld"))
            local SavedPos = blobRoot.CFrame

            local tChar = target.Character
            local tRoot = tChar and tChar:FindFirstChild("HumanoidRootPart")

            if tRoot and blobRoot then
                local bringStart = tick()
                while tick() - bringStart < 0.35 do
                    if not spinKickEnabled then break end
                    blobRoot.CFrame = tRoot.CFrame
                    blobRoot.Velocity = Vector3.zero
                    pcall(function()
                        if CG and R_Det then
                            CG:FireServer(R_Det, tRoot, R_Weld)
                        end
                        GE.CreateGrabLine:FireServer(tRoot, Vector3.zero, tRoot.Position, false)
                        GE.SetNetworkOwner:FireServer(tRoot, blobRoot.CFrame)
                    end)
                    RunService.Heartbeat:Wait()
                end
                blobRoot.CFrame = SavedPos
                blobRoot.Velocity = Vector3.zero
                task.wait(0.05)
            end

            local packetTimer = 0
            while spinKickEnabled do
                if not target or not target.Parent or not target.Character then
                    break
                end
                if not blobRoot or not blobRoot.Parent then
                    break
                end

                tChar = target.Character
                tRoot = tChar and tChar:FindFirstChild("HumanoidRootPart")
                local tHum = tChar and tChar:FindFirstChild("Humanoid")

                if tRoot and tHum and tHum.Health > 0 then
                    spinAngle2 = spinAngle2 + (math.rad(spinSpeed2) * 2)
                    if spinAngle2 > math.pi * 2 then
                        spinAngle2 = spinAngle2 - math.pi * 2
                    end

                    blobRoot.CFrame = CFrame.new(SavedPos.Position) * CFrame.Angles(0, spinAngle2, 0)
                    blobRoot.Velocity = Vector3.zero

                    local distance = 8
                    local targetPos = SavedPos.Position + Vector3.new(
                        math.sin(spinAngle2) * distance,
                        0,
                        math.cos(spinAngle2) * distance
                    )
                    tRoot.CFrame = CFrame.new(targetPos)
                    tRoot.Velocity = Vector3.zero
                    tRoot.RotVelocity = Vector3.zero

                    if tick() - packetTimer > 0.05 then
                        packetTimer = tick()
                        pcall(function()
                            tHum.PlatformStand = true
                            tHum.Sit = true
                            GE.SetNetworkOwner:FireServer(tRoot, tRoot.CFrame)
                            if R_Det then
                                local weld = R_Det:FindFirstChild("RightWeld") or R_Det:FindFirstChildWhichIsA("Weld")
                                if weld then
                                    CD:FireServer(weld)
                                end
                            end
                            GE.DestroyGrabLine:FireServer(tRoot)
                            if CG and R_Det then
                                CG:FireServer(R_Det, tRoot, R_Weld)
                            end
                            GE.CreateGrabLine:FireServer(tRoot, Vector3.zero, tRoot.Position, false)
                        end)
                    end
                else
                    if blobRoot and blobRoot.Parent then
                        blobRoot.CFrame = SavedPos
                        blobRoot.Velocity = Vector3.zero
                    end
                end

                RunService.Heartbeat:Wait()
            end

            spinKickEnabled = false
            spinAngle2 = 0
            if blobRoot and blobRoot.Parent then
                blobRoot.CFrame = SavedPos
                blobRoot.Velocity = Vector3.zero
            end
        end)
    end
})

-- =====================================================
-- 上下キック（キックv3）
-- =====================================================
local updownEnabled = false
local updownThread = nil

MainGroup:AddToggle("KickV3", {
    Text = "⬆⬇ キックv3",
    Tooltip = "ターゲットを上下に振ります",
    Default = false,
    Callback = function(on)
        updownEnabled = on

        if not on then
            if updownThread then
                task.cancel(updownThread)
                updownThread = nil
            end
            return
        end

        if not selectedKickPlayer then
            Library:Notify({
                Title = "エラー",
                Description = "先にターゲットを選択してください",
                Time = 3,
            })
            Toggles.KickV3:SetValue(false)
            return
        end

        local char = Player.Character
        local hum = char and char:FindFirstChild("Humanoid")
        local seat = hum and hum.SeatPart

        if not seat or seat.Parent.Name ~= "CreatureBlobman" then
            Library:Notify({
                Title = "エラー",
                Description = "ブロブマンに乗っている必要があります",
                Time = 3,
            })
            Toggles.KickV3:SetValue(false)
            return
        end

        isKickActive = true
        local target = selectedKickPlayer

        updownThread = task.spawn(function()
            local GE = ReplicatedStorage:WaitForChild("GrabEvents")
            local blob = seat.Parent
            local blobRoot = blob:FindFirstChild("HumanoidRootPart") or blob.PrimaryPart
            local scriptObj = blob:FindFirstChild("BlobmanSeatAndOwnerScript")
            local CG = scriptObj and scriptObj:FindFirstChild("CreatureGrab")
            local CD = scriptObj and scriptObj:FindFirstChild("CreatureDrop")
            local R_Det = blob:FindFirstChild("RightDetector")
            local R_Weld = R_Det and (R_Det:FindFirstChild("RightWeld") or R_Det:FindFirstChildWhichIsA("Weld"))
            local SavedPos = blobRoot.CFrame

            local tChar = target.Character
            local tRoot = tChar and tChar:FindFirstChild("HumanoidRootPart")

            if tRoot and blobRoot then
                local bringStart = tick()
                while tick() - bringStart < 0.15 do
                    if not updownEnabled then break end
                    blobRoot.CFrame = tRoot.CFrame
                    blobRoot.Velocity = Vector3.zero
                    pcall(function()
                        if CG and R_Det then
                            CG:FireServer(R_Det, tRoot, R_Weld)
                        end
                        GE.CreateGrabLine:FireServer(tRoot, Vector3.zero, tRoot.Position, false)
                        GE.SetNetworkOwner:FireServer(tRoot, blobRoot.CFrame)
                    end)
                    RunService.Heartbeat:Wait()
                end
                blobRoot.CFrame = SavedPos
                blobRoot.Velocity = Vector3.zero
                task.wait(0.05)
            end

            local packetTimer = 0
            local cycleTime = 0.05
            while updownEnabled do
                if not target or not target.Parent or not target.Character then
                    break
                end
                if not blobRoot or not blobRoot.Parent then
                    break
                end

                tChar = target.Character
                tRoot = tChar and tChar:FindFirstChild("HumanoidRootPart")
                local tHum = tChar and tChar:FindFirstChild("Humanoid")

                if tRoot and tHum and tHum.Health > 0 then
                    blobRoot.CFrame = SavedPos
                    blobRoot.Velocity = Vector3.zero

                    local phase = math.floor(tick() / cycleTime) % 2
                    local offsetY = (phase == 0) and 12 or -5
                    local lockPos = SavedPos * CFrame.new(0, offsetY, -5)

                    tRoot.CFrame = lockPos
                    tRoot.Velocity = Vector3.zero
                    tRoot.RotVelocity = Vector3.zero

                    if tick() - packetTimer > 0.05 then
                        packetTimer = tick()
                        pcall(function()
                            tHum.PlatformStand = true
                            tHum.Sit = true
                            GE.SetNetworkOwner:FireServer(tRoot, lockPos)
                            if R_Det then
                                local weld = R_Det:FindFirstChild("RightWeld") or R_Det:FindFirstChildWhichIsA("Weld")
                                if weld then
                                    CD:FireServer(weld)
                                end
                            end
                            GE.DestroyGrabLine:FireServer(tRoot)
                            if CG and R_Det then
                                CG:FireServer(R_Det, tRoot, R_Weld)
                            end
                            GE.CreateGrabLine:FireServer(tRoot, Vector3.zero, tRoot.Position, false)
                        end)
                    end
                else
                    if blobRoot and blobRoot.Parent then
                        blobRoot.CFrame = SavedPos
                        blobRoot.Velocity = Vector3.zero
                    end
                end

                RunService.Heartbeat:Wait()
            end

            updownEnabled = false
            if blobRoot and blobRoot.Parent then
                blobRoot.CFrame = SavedPos
                blobRoot.Velocity = Vector3.zero
            end
        end)
    end
})

-- =====================================================
-- ランダムキック（キックv4）
-- =====================================================
local randomKickEnabled = false
local randomKickThread = nil

MainGroup:AddToggle("KickV4", {
    Text = "🎲 キックv4",
    Tooltip = "ランダムな方向にキックします",
    Default = false,
    Callback = function(on)
        if not on then
            randomKickEnabled = false
            if randomKickThread then
                task.cancel(randomKickThread)
                randomKickThread = nil
            end
            return
        end

        if not selectedKickPlayer then
            Library:Notify({
                Title = "エラー",
                Description = "先にターゲットを選択してください",
                Time = 3,
            })
            Toggles.KickV4:SetValue(false)
            return
        end

        local char = Player.Character
        if not char then
            Library:Notify({
                Title = "エラー",
                Description = "キャラクターが見つかりません",
                Time = 3,
            })
            Toggles.KickV4:SetValue(false)
            return
        end

        local hum = char:FindFirstChild("Humanoid")
        if not hum then
            Library:Notify({
                Title = "エラー",
                Description = "Humanoidが見つかりません",
                Time = 3,
            })
            Toggles.KickV4:SetValue(false)
            return
        end

        local seat = hum.SeatPart
        if not seat or not seat.Parent or seat.Parent.Name ~= "CreatureBlobman" then
            Library:Notify({
                Title = "エラー",
                Description = "ブロブマンに座っている必要があります",
                Time = 3,
            })
            Toggles.KickV4:SetValue(false)
            return
        end

        randomKickEnabled = true
        isKickActive = true
        local target = selectedKickPlayer

        randomKickThread = task.spawn(function()
            local GE = ReplicatedStorage:WaitForChild("GrabEvents")
            local blob = seat.Parent
            local blobRoot = blob:FindFirstChild("HumanoidRootPart") or blob.PrimaryPart
            local scriptObj = blob:FindFirstChild("BlobmanSeatAndOwnerScript")
            local CG = scriptObj and scriptObj:FindFirstChild("CreatureGrab")
            local CD = scriptObj and scriptObj:FindFirstChild("CreatureDrop")
            local R_Det = blob:FindFirstChild("RightDetector")
            local R_Weld = R_Det and (R_Det:FindFirstChild("RightWeld") or R_Det:FindFirstChildWhichIsA("Weld"))
            local SavedPos = blobRoot.CFrame

            local kickDirections = {
                CFrame.new(0, 0, -15),
                CFrame.new(0, 0, 15),
                CFrame.new(-15, 0, 0),
                CFrame.new(15, 0, 0),
                CFrame.new(0, 20, 0),
                CFrame.new(0, -10, 0),
                CFrame.new(10, 10, 10),
                CFrame.new(-10, 10, -10),
                CFrame.new(10, -5, -10),
                CFrame.new(-10, -5, 10),
            }

            local tChar = target.Character
            local tRoot = tChar and tChar:FindFirstChild("HumanoidRootPart")

            if tRoot and blobRoot then
                local bringStart = tick()
                while tick() - bringStart < 0.35 do
                    if not randomKickEnabled then break end
                    blobRoot.CFrame = tRoot.CFrame
                    blobRoot.Velocity = Vector3.zero
                    pcall(function()
                        if CG and R_Det then
                            CG:FireServer(R_Det, tRoot, R_Weld)
                        end
                        GE.CreateGrabLine:FireServer(tRoot, Vector3.zero, tRoot.Position, false)
                        GE.SetNetworkOwner:FireServer(tRoot, blobRoot.CFrame)
                    end)
                    RunService.Heartbeat:Wait()
                end
                blobRoot.CFrame = SavedPos
                blobRoot.Velocity = Vector3.zero
                task.wait(0.05)
            end

            local packetTimer = 0
            local kickCount = 0
            while randomKickEnabled do
                if not target or not target.Parent or not target.Character then
                    break
                end
                if not blobRoot or not blobRoot.Parent then
                    break
                end

                tChar = target.Character
                tRoot = tChar and tChar:FindFirstChild("HumanoidRootPart")
                local tHum = tChar and tChar:FindFirstChild("Humanoid")

                if tRoot and tHum and tHum.Health > 0 then
                    blobRoot.CFrame = SavedPos
                    blobRoot.Velocity = Vector3.zero

                    local randomDir = kickDirections[math.random(1, #kickDirections)]
                    local targetPos = SavedPos * randomDir
                    
                    if randomDir.Y < 5 and randomDir.Y > -5 then
                        targetPos = CFrame.new(targetPos.X, SavedPos.Y + 1, targetPos.Z)
                    end

                    tRoot.CFrame = targetPos
                    tRoot.Velocity = Vector3.zero
                    tRoot.RotVelocity = Vector3.zero

                    if tick() - packetTimer > 0.03 then
                        packetTimer = tick()
                        pcall(function()
                            tHum.PlatformStand = true
                            tHum.Sit = true
                            GE.SetNetworkOwner:FireServer(tRoot, targetPos)
                            if R_Det then
                                local weld = R_Det:FindFirstChild("RightWeld") or R_Det:FindFirstChildWhichIsA("Weld")
                                if weld then
                                    CD:FireServer(weld)
                                end
                            end
                            GE.DestroyGrabLine:FireServer(tRoot)
                            if CG and R_Det then
                                CG:FireServer(R_Det, tRoot, R_Weld)
                            end
                            GE.CreateGrabLine:FireServer(tRoot, Vector3.zero, tRoot.Position, false)
                        end)
                    end

                    kickCount = kickCount + 1
                    if kickCount % 5 == 0 then
                        blobRoot.CFrame = SavedPos * CFrame.new(0, 3, 0)
                        task.wait(0.01)
                        blobRoot.CFrame = SavedPos
                    end

                else
                    if blobRoot and blobRoot.Parent then
                        blobRoot.CFrame = SavedPos
                        blobRoot.Velocity = Vector3.zero
                    end
                end

                RunService.Heartbeat:Wait()
            end

            randomKickEnabled = false
            if blobRoot and blobRoot.Parent then
                blobRoot.CFrame = SavedPos
                blobRoot.Velocity = Vector3.zero
            end
        end)
    end
})

-- =====================================================
-- テストキックv5（新規追加）
-- 同じプレイヤーリストを使用
-- =====================================================
local testKickEnabled = false
local testKickThread = nil

local KickTab = Tabs.Kick
local KickGroup = KickTab:AddLeftGroupbox("キックv5", "crosshair")

-- ターゲット選択（共通のものを使うため、説明のみ表示）
KickGroup:AddLabel("使用するターゲットはメインタブで選択してください")

KickGroup:AddToggle("KickV5", {
    Text = "🧪 キックv5（テスト）",
    Tooltip = "ターゲットを空中に固定します（テスト機能）",
    Default = false,
    Callback = function(on)
        if not on then
            testKickEnabled = false
            if testKickThread then
                task.cancel(testKickThread)
                testKickThread = nil
            end
            return
        end

        -- エラーチェック: ターゲット未選択
        if not selectedKickPlayer then
            Library:Notify({
                Title = "エラー",
                Description = "先にメインタブでターゲットを選択してください",
                Time = 3,
            })
            Toggles.KickV5:SetValue(false)
            return
        end

        -- エラーチェック: Blobmanに乗っていない
        local char = Player.Character
        local hum = char and char:FindFirstChild("Humanoid")
        local seat = hum and hum.SeatPart

        if not seat or not seat.Parent or seat.Parent.Name ~= "CreatureBlobman" then
            Library:Notify({
                Title = "エラー",
                Description = "ブロブマンに座っている必要があります",
                Time = 3,
            })
            Toggles.KickV5:SetValue(false)
            return
        end

        testKickEnabled = true
        isKickActive = true
        local target = selectedKickPlayer

        testKickThread = task.spawn(function()
            local GE = ReplicatedStorage:WaitForChild("GrabEvents")
            local blob = seat.Parent
            local blobRoot = blob:FindFirstChild("HumanoidRootPart") or blob.PrimaryPart
            local scriptObj = blob:FindFirstChild("BlobmanSeatAndOwnerScript")
            local CG = scriptObj and scriptObj:FindFirstChild("CreatureGrab")
            local CD = scriptObj and scriptObj:FindFirstChild("CreatureDrop")
            local R_Det = blob:FindFirstChild("RightDetector")
            local R_Weld = R_Det and (R_Det:FindFirstChild("RightWeld") or R_Det:FindFirstChildWhichIsA("Weld"))
            local SavedPos = blobRoot.CFrame

            -- 最初にターゲットを掴む
            local tChar = target.Character
            local tRoot = tChar and tChar:FindFirstChild("HumanoidRootPart")

            if tRoot and blobRoot then
                -- ターゲットに近づいて掴む
                local bringStart = tick()
                while tick() - bringStart < 0.35 do
                    if not testKickEnabled then break end
                    blobRoot.CFrame = tRoot.CFrame
                    blobRoot.Velocity = Vector3.zero
                    pcall(function()
                        if CG and R_Det then
                            CG:FireServer(R_Det, tRoot, R_Weld)
                        end
                        GE.CreateGrabLine:FireServer(tRoot, Vector3.zero, tRoot.Position, false)
                        GE.SetNetworkOwner:FireServer(tRoot, blobRoot.CFrame)
                    end)
                    RunService.Heartbeat:Wait()
                end
                blobRoot.CFrame = SavedPos
                blobRoot.Velocity = Vector3.zero
                task.wait(0.05)
            end

            -- 掴んだ状態で空中に固定し続ける
            local packetTimer = 0
            while testKickEnabled do
                -- ターゲット有効チェック
                if not target or not target.Parent or not target.Character then
                    break
                end

                tChar = target.Character
                tRoot = tChar and tChar:FindFirstChild("HumanoidRootPart")
                local tHum = tChar and tChar:FindFirstChild("Humanoid")

                if tRoot and tHum and tHum.Health > 0 then
                    -- ターゲットを空中に固定（浮いている状態）
                    local floatPos = SavedPos * CFrame.new(0, 23, 0)
                    tRoot.CFrame = floatPos
                    tRoot.Velocity = Vector3.zero
                    tRoot.RotVelocity = Vector3.zero

                    -- 掴み状態を維持
                    if tick() - packetTimer > 0.05 then
                        packetTimer = tick()
                        pcall(function()
                            tHum.PlatformStand = true
                            tHum.Sit = true
                            GE.SetNetworkOwner:FireServer(tRoot, floatPos)
                            if R_Det then
                                local weld = R_Det:FindFirstChild("RightWeld") or R_Det:FindFirstChildWhichIsA("Weld")
                                if weld then
                                    CD:FireServer(weld)
                                end
                            end
                            GE.DestroyGrabLine:FireServer(tRoot)
                            if CG and R_Det then
                                CG:FireServer(R_Det, tRoot, R_Weld)
                            end
                            GE.CreateGrabLine:FireServer(tRoot, Vector3.zero, tRoot.Position, false)
                        end)
                    end
                end

                RunService.Heartbeat:Wait()
            end

            -- 終了処理
            testKickEnabled = false
            if blobRoot and blobRoot.Parent then
                blobRoot.CFrame = SavedPos
                blobRoot.Velocity = Vector3.zero
            end
        end)
    end
})

KickGroup:AddDivider()
KickGroup:AddButton({
    Text = "🛑 このタブのキック停止",
    Func = function()
        testKickEnabled = false
        if testKickThread then
            task.cancel(testKickThread)
            testKickThread = nil
        end
        if Toggles.KickV5 then Toggles.KickV5:SetValue(false) end
        Library:Notify({
            Title = "停止",
            Description = "キックv5を停止しました",
            Time = 2,
        })
    end,
    Risky = true,
})

-- =====================================================
-- キックv6 最強（Kick Only Edition 移植）
-- 同じプレイヤーリストを使用
-- =====================================================
local KickGroupV6 = KickTab:AddRightGroupbox("キックv6 最強", "sword")

-- ステータス表示
local StatusLabelV6 = KickGroupV6:AddLabel("ステータス: ⏳ 待機中", true)

KickGroupV6:AddLabel("📌 使い方:", true)
KickGroupV6:AddLabel("1. ブロブマンに座る", true)
KickGroupV6:AddLabel("2. メインタブでターゲットを選択", true)
KickGroupV6:AddLabel("3. 下のボタンを押す", true)

KickGroupV6:AddDivider()

-- キック実行（ボタン方式）
KickGroupV6:AddButton({
    Text = "💥 キックv6 最強 (掴んで固定)",
    Func = function()
        if not selectedKickPlayer then
            Library:Notify({
                Title = "エラー",
                Description = "先にメインタブでターゲットを選択してください",
                Time = 3,
            })
            return
        end

        local char = Player.Character
        local hum = char and char:FindFirstChild("Humanoid")
        local seat = hum and hum.SeatPart

        if not seat or seat.Parent.Name ~= "CreatureBlobman" then
            Library:Notify({
                Title = "エラー",
                Description = "ブロブマンに座っている必要があります",
                Time = 3,
            })
            return
        end

        local target = selectedKickPlayer

        if not target or not target.Parent then
            Library:Notify({
                Title = "エラー",
                Description = "無効なターゲットです",
                Time = 3,
            })
            return
        end

        local GE = ReplicatedStorage:WaitForChild("GrabEvents")
        local blob = seat.Parent
        local blobRoot = blob:FindFirstChild("HumanoidRootPart") or blob.PrimaryPart
        
        if not blobRoot then
            Library:Notify({
                Title = "エラー",
                Description = "ブロブマンのルートパーツが見つかりません",
                Time = 3,
            })
            return
        end

        local scriptObj = blob:FindFirstChild("BlobmanSeatAndOwnerScript")
        local CG = scriptObj and scriptObj:FindFirstChild("CreatureGrab")
        local CD = scriptObj and scriptObj:FindFirstChild("CreatureDrop")
        local R_Det = blob:FindFirstChild("RightDetector")
        local R_Weld = R_Det and (R_Det:FindFirstChild("RightWeld") or R_Det:FindFirstChildWhichIsA("Weld"))
        local SavedPos = blobRoot.CFrame

        local tChar = target.Character
        local tRoot = tChar and tChar:FindFirstChild("HumanoidRootPart")
        local tHum = tChar and tChar:FindFirstChild("Humanoid")

        if not tRoot or not tHum or tHum.Health <= 0 then
            Library:Notify({
                Title = "エラー",
                Description = "無効なターゲットです",
                Time = 3,
            })
            return
        end

        StatusLabelV6:SetText("ステータス: 🔄 掴み中 " .. target.DisplayName .. "...")
        Library:Notify({
            Title = "実行中",
            Description = target.DisplayName .. " を掴んでいます...",
            Time = 2,
        })

        task.spawn(function()
            -- 掴むフェーズ
            local bringStart = tick()
            while tick() - bringStart < 0.35 do
                if not blobRoot or not blobRoot.Parent then break end
                if not tRoot or not tRoot.Parent then break end
                
                blobRoot.CFrame = tRoot.CFrame
                blobRoot.Velocity = Vector3.zero
                
                pcall(function()
                    if CG and R_Det then
                        CG:FireServer(R_Det, tRoot, R_Weld)
                    end
                    GE.CreateGrabLine:FireServer(tRoot, Vector3.zero, tRoot.Position, false)
                    GE.SetNetworkOwner:FireServer(tRoot, blobRoot.CFrame)
                end)
                RunService.Heartbeat:Wait()
            end

            if blobRoot and blobRoot.Parent then
                blobRoot.CFrame = SavedPos
                blobRoot.Velocity = Vector3.zero
            end
            task.wait(0.05)

            -- 固定フェーズ
            if tRoot and tRoot.Parent and tHum and tHum.Health > 0 then
                if blobRoot and blobRoot.Parent then
                    blobRoot.CFrame = SavedPos
                    blobRoot.Velocity = Vector3.zero
                end

                local lockPos = SavedPos * CFrame.new(0, 23, 0)
                tRoot.CFrame = lockPos
                tRoot.Velocity = Vector3.zero
                tRoot.RotVelocity = Vector3.zero

                pcall(function()
                    tHum.PlatformStand = true
                    tHum.Sit = true
                    GE.SetNetworkOwner:FireServer(tRoot, lockPos)
                    
                    if R_Det then
                        local weld = R_Det:FindFirstChild("RightWeld") or R_Det:FindFirstChildWhichIsA("Weld")
                        if weld then
                            CD:FireServer(weld)
                        end
                    end
                    GE.DestroyGrabLine:FireServer(tRoot)
                    if CG and R_Det then
                        CG:FireServer(R_Det, tRoot, R_Weld)
                    end
                    GE.CreateGrabLine:FireServer(tRoot, Vector3.zero, tRoot.Position, false)
                end)

                StatusLabelV6:SetText("ステータス: ✅ " .. target.DisplayName .. " を空中に固定！")
                Library:Notify({
                    Title = "成功",
                    Description = target.DisplayName .. " を空中に固定しました！",
                    Time = 3,
                })
            else
                StatusLabelV6:SetText("ステータス: ❌ ターゲットが無効になりました")
                Library:Notify({
                    Title = "エラー",
                    Description = "ターゲットが無効になりました",
                    Time = 3,
                })
            end
        end)
    end,
})

KickGroupV6:AddDivider()
KickGroupV6:AddButton({
    Text = "🛑 状態リセット",
    Func = function()
        StatusLabelV6:SetText("ステータス: ⏳ 待機中")
        Library:Notify({
            Title = "リセット",
            Description = "ステータスをリセットしました",
            Time = 2,
        })
    end,
})

-- =====================================================
-- 全停止ボタン
-- =====================================================
MainGroup:AddDivider()
MainGroup:AddButton({
    Text = "🛑 全キック停止",
    Func = function()
        stopAllKicks()
        -- v6の状態もリセット
        if StatusLabelV6 then
            StatusLabelV6:SetText("ステータス: ⏳ 待機中")
        end
        Library:Notify({
            Title = "停止",
            Description = "全てのキック機能を停止しました",
            Time = 2,
        })
    end,
    Risky = true,
    Tooltip = "全てのキック機能を強制停止します",
})

-- =====================================================
-- ラグタブ
-- =====================================================
local LagGroup = Tabs.Lag:AddLeftGroupbox("ラグ機能", "zap")

local lineLagThread = nil
local lineLagEnabled = false
local GrabEvents = ReplicatedStorage:FindFirstChild("GrabEvents")

local function startLineLag()
    if lineLagEnabled then return end
    lineLagEnabled = true
    lineLagThread = task.spawn(function()
        if not GrabEvents then return end
        local createLine = GrabEvents:FindFirstChild("CreateGrabLine")
        if not createLine then return end

        while lineLagEnabled do
            local target = Workspace:FindFirstChild("SpawnLocation") or Workspace:FindFirstChild("Spawn") or (Player.Character and Player.Character:FindFirstChild("HumanoidRootPart"))
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
    if lineLagThread then 
        task.cancel(lineLagThread)
        lineLagThread = nil
    end
end

LagGroup:AddToggle("LineLag", {
    Text = "📡 ラインラグ",
    Tooltip = "サーバーに大量のラインリクエストを送信します",
    Default = false,
    Callback = function(Value)
        if Value then
            startLineLag()
            Library:Notify({
                Title = "Info",
                Description = "ラインラグを開始しました",
                Time = 2,
            })
        else
            stopLineLag()
            Library:Notify({
                Title = "Info",
                Description = "ラインラグを停止しました",
                Time = 2,
            })
        end
    end
})

-- =====================================================
-- オーラタブ
-- =====================================================
local AuraGroup = Tabs.Aura:AddLeftGroupbox("オーラコントロール", "users")
local StatusGroup = Tabs.Aura:AddRightGroupbox("ステータス", "info")

local grabbedPlayers = {}
local MAX_GRAB = 5
local auraRadius = 8
local isAuraActive = false
local auraLoop = nil
local searchRadius = 15

local function getNearbyPlayers()
    local char = Player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return {} end
    
    local nearby = {}
    local grabbedNames = {}
    for _, info in pairs(grabbedPlayers) do
        if info.player then
            grabbedNames[info.player.Name] = true
        end
    end
    
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= Player and not grabbedNames[plr.Name] then
            local plrChar = plr.Character
            local plrRoot = plrChar and plrChar:FindFirstChild("HumanoidRootPart")
            if plrRoot then
                local dist = (hrp.Position - plrRoot.Position).Magnitude
                if dist < searchRadius then
                    table.insert(nearby, plr)
                end
            end
        end
    end
    
    return nearby
end

local function getAuraPosition(index, total, hrpPos)
    if total == 0 then return hrpPos + Vector3.new(0, 5, 0) end
    if total == 1 then
        return hrpPos + Vector3.new(0, 5, 0)
    end
    
    local angle = (index / total) * 2 * math.pi
    local x = math.cos(angle) * auraRadius
    local z = math.sin(angle) * auraRadius
    local y = 5 + math.sin(angle * 2) * 0.5
    
    return hrpPos + Vector3.new(x, y, z)
end

local function updateAuraPositions()
    local char = Player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local count = #grabbedPlayers
    for i, info in ipairs(grabbedPlayers) do
        if info.active then
            local pos = getAuraPosition(i - 1, MAX_GRAB, hrp.Position)
            info.grabPos = CFrame.new(pos)
        end
    end
end

local function releaseAll()
    for _, info in pairs(grabbedPlayers) do
        info.active = false
        if info.root and info.root.Parent then
            pcall(function()
                if info.humanoid then
                    info.humanoid.PlatformStand = false
                    info.humanoid.Sit = false
                end
                info.root.Velocity = Vector3.zero
            end)
        end
    end
    grabbedPlayers = {}
end

local function grabAura()
    if #grabbedPlayers >= MAX_GRAB then return end
    
    local char = Player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local nearby = getNearbyPlayers()
    if #nearby == 0 then return end
    
    local grabCount = 0
    for _, target in ipairs(nearby) do
        if #grabbedPlayers >= MAX_GRAB then break end
        
        local targetChar = target.Character
        local targetRoot = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
        local targetHumanoid = targetChar and targetChar:FindFirstChild("Humanoid")
        
        if targetRoot and targetHumanoid and targetHumanoid.Health > 0 then
            local total = #grabbedPlayers + 1
            local pos = getAuraPosition(total - 1, MAX_GRAB, hrp.Position)
            
            local grabInfo = {
                player = target,
                char = targetChar,
                root = targetRoot,
                humanoid = targetHumanoid,
                grabPos = CFrame.new(pos),
                active = true
            }
            table.insert(grabbedPlayers, grabInfo)
            grabCount = grabCount + 1
        end
    end
    
    updateAuraPositions()
end

local function startAuraLoop()
    if auraLoop then return end
    
    auraLoop = task.spawn(function()
        while isAuraActive do
            if #grabbedPlayers < MAX_GRAB then
                grabAura()
            end
            
            local char = Player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local GE = ReplicatedStorage:WaitForChild("GrabEvents")
            
            if hrp and #grabbedPlayers > 0 then
                updateAuraPositions()
            end
            
            for _, info in pairs(grabbedPlayers) do
                if info.active and info.root and info.root.Parent then
                    if info.humanoid and info.humanoid.Health > 0 then
                        info.root.CFrame = info.grabPos
                        info.root.Velocity = Vector3.zero
                        info.root.RotVelocity = Vector3.zero
                        
                        if hrp then
                            local lookAt = CFrame.lookAt(info.root.Position, hrp.Position)
                            info.root.CFrame = lookAt
                        end
                        
                        pcall(function()
                            info.humanoid.PlatformStand = true
                            info.humanoid.Sit = true
                            GE.SetNetworkOwner:FireServer(info.root, info.grabPos)
                        end)
                    else
                        info.active = false
                    end
                end
            end
            
            local newList = {}
            for _, info in pairs(grabbedPlayers) do
                if info.active and info.root and info.root.Parent then
                    table.insert(newList, info)
                end
            end
            grabbedPlayers = newList
            
            RunService.Heartbeat:Wait()
        end
        
        releaseAll()
        auraLoop = nil
    end)
end

AuraGroup:AddToggle("AuraToggle", {
    Text = "🫳 オーラで掴む（最大5人）",
    Tooltip = "半径 " .. searchRadius .. " ブロック以内のプレイヤーをオーラで掴みます",
    Default = false,
    Callback = function(Value)
        isAuraActive = Value
        if Value then
            startAuraLoop()
            Library:Notify({
                Title = "オーラON",
                Description = "半径 " .. searchRadius .. " ブロック以内のプレイヤーを掴みます",
                Time = 2,
            })
        else
            if auraLoop then
                task.cancel(auraLoop)
                auraLoop = nil
            end
            releaseAll()
            Library:Notify({
                Title = "オーラOFF",
                Description = "全員解放しました",
                Time = 2,
            })
        end
    end
})

-- レンジ調整スライダー
AuraGroup:AddSlider("AuraRange", {
    Text = "オーラレンジ",
    Default = 15,
    Min = 5,
    Max = 50,
    Rounding = 1,
    Suffix = "ブロック",
    Tooltip = "オーラで掴む範囲を調整します",
    Callback = function(Value)
        searchRadius = Value
        StatusGroup:AddLabel("AuraStatusLabel", {
            Text = "掴んでいる人: 0/" .. MAX_GRAB .. " | 範囲: " .. searchRadius .. "ブロック",
            DoesWrap = true,
        })
    end
})

-- ステータス表示（最初はラベルを追加）
local function updateStatusLabel()
    if #grabbedPlayers > 0 then
        local names = {}
        for _, info in pairs(grabbedPlayers) do
            table.insert(names, info.player.DisplayName)
        end
        return "掴んでいる人: " .. #grabbedPlayers .. "/" .. MAX_GRAB .. " 🔵 " .. table.concat(names, ", ")
    else
        return "掴んでいる人: 0/" .. MAX_GRAB .. " | 範囲: " .. searchRadius .. "ブロック"
    end
end

StatusGroup:AddLabel("AuraStatusLabel", {
    Text = updateStatusLabel(),
    DoesWrap = true,
})

-- ステータス更新ループ
task.spawn(function()
    while true do
        local label = Options.AuraStatusLabel
        if label then
            label:SetText(updateStatusLabel())
        end
        task.wait(1)
    end
end)

-- =====================================================
-- UI設定
-- =====================================================
local MenuGroup = Tabs["UI Settings"]:AddLeftGroupbox("メニュー設定", "wrench")

MenuGroup:AddToggle("ShowCustomCursor", {
    Text = "カスタムカーソル",
    Default = true,
    Callback = function(Value)
        Library.ShowCustomCursor = Value
    end,
})

MenuGroup:AddDropdown("NotificationSide", {
    Values = { "Left", "Right" },
    Default = "Right",
    Text = "通知表示位置",
    Callback = function(Value)
        Library:SetNotifySide(Value)
    end,
})

MenuGroup:AddSlider("DPIScale", {
    Text = "DPIスケール",
    Default = 100,
    Min = 50,
    Max = 200,
    Rounding = 0,
    Suffix = "%",
    Callback = function(Value)
        Library:SetDPIScale(Value)
    end,
})

MenuGroup:AddDivider()
MenuGroup:AddLabel("メニューキーバインド")
    :AddKeyPicker("MenuKeybind", { 
        Default = "RightShift", 
        NoUI = true, 
        Text = "メニューキーバインド" 
    })

MenuGroup:AddButton({
    Text = "アンロード",
    Func = function()
        Library:Unload()
    end,
    Risky = true,
})

Library.ToggleKeybind = Options.MenuKeybind

-- =====================================================
-- 終了時処理
-- =====================================================
Library:OnUnload(function()
    stopAllKicks()
    stopLineLag()
    
    isAuraActive = false
    if auraLoop then
        task.cancel(auraLoop)
        auraLoop = nil
    end
    releaseAll()
    
    blobmanEnabled = false
    StopBlobmanMonitor()
    
    print("Katsura Hub v0.2 unloaded!")
end)

-- =====================================================
-- セーブマネージャー＆テーママネージャー
-- =====================================================
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })

ThemeManager:SetFolder("KatsuraHub")
SaveManager:SetFolder("KatsuraHub/settings")

SaveManager:BuildConfigSection(Tabs["UI Settings"])
ThemeManager:ApplyToTab(Tabs["UI Settings"])

SaveManager:LoadAutoloadConfig()
