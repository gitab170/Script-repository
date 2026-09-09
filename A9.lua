-- =====================================================
-- やきたまごハブ (フル統合版)
-- =====================================================

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local Window = Rayfield:CreateWindow({
    Name = "やきたまごハブ",
    LoadingTitle = "やきたまごハブ",
    LoadingSubtitle = "Full Integrated Version",
    KeySystem = false
})

-- タブ
local KillTab = Window:CreateTab("Kill System", nil)
local DestroyTab = Window:CreateTab("Destroy Server", nil)

-- =====================================================
-- 共通ロジック
-- =====================================================
local BlobmanKill = {isRunning = false, isKillAura = false, isSelectedKill = false, selectedPlayer = nil, currentBlobman = nil}
local GrabEvents = ReplicatedStorage:FindFirstChild("GrabEvents")
local globalFriendWhitelist = false

local function GetSeatedBlobman()
    local char = LocalPlayer.Character
    if not char then return nil end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid or not humanoid.SeatPart then return nil end
    local obj = humanoid.SeatPart
    while obj and obj ~= Workspace do
        if obj:IsA("Model") and obj.Name == "CreatureBlobman" then return obj end
        obj = obj.Parent
    end
    return nil
end

function BlobmanKill.SpawnBlobman()
    local seated = GetSeatedBlobman()
    if seated then return seated end
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return nil end
    local spawnPos = char.HumanoidRootPart.CFrame * CFrame.new(0, 0, -5)
    pcall(function() ReplicatedStorage.MenuToys.SpawnToyRemoteFunction:InvokeServer("CreatureBlobman", spawnPos, Vector3.new(0, 127, 0)) end)
    task.wait(0.8)
    return GetSeatedBlobman()
end

function BlobmanKill.GrabRelease(blobman, targetRoot)
    if not blobman or not targetRoot then return end
    pcall(function()
        local script = blobman:FindFirstChild("BlobmanSeatAndOwnerScript")
        if script then
            script.CreatureGrab:FireServer(blobman.LeftDetector, targetRoot, blobman.LeftDetector.LeftWeld)
            script.CreatureRelease:FireServer(blobman.LeftDetector.LeftWeld)
        end
    end)
end

-- =====================================================
-- Kill System UI
-- =====================================================
KillTab:CreateToggle({
    Name = "Kill Aura (範囲内全員)",
    CurrentValue = false,
    Callback = function(Value)
        BlobmanKill.isKillAura = Value
        task.spawn(function()
            while BlobmanKill.isKillAura do
                local blob = GetSeatedBlobman() or BlobmanKill.SpawnBlobman()
                for _, p in pairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                        if (LocalPlayer.Character.HumanoidRootPart.Position - p.Character.HumanoidRootPart.Position).Magnitude < 40 then
                            if not (globalFriendWhitelist and LocalPlayer:IsFriendsWith(p.UserId)) then
                                pcall(function() p.Character.Humanoid.Health = 0 end)
                                if blob then BlobmanKill.GrabRelease(blob, p.Character.HumanoidRootPart) end
                            end
                        end
                    end
                end
                task.wait(0.1)
            end
        end)
    end
})

KillTab:CreateToggle({
    Name = "Whitelist Friends",
    CurrentValue = false,
    Callback = function(Value) globalFriendWhitelist = Value end
})

-- =====================================================
-- Destroy Server UI
-- =====================================================
local lineLagEnabled = false
local function startLineLag()
    lineLagEnabled = true
    task.spawn(function()
        while lineLagEnabled and GrabEvents do
            local createLine = GrabEvents:FindFirstChild("CreateGrabLine")
            local spawn = Workspace:FindFirstChild("SpawnLocation") or Workspace:FindFirstChild("Spawn") or LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if createLine and spawn then
                local pos = CFrame.new(math.random(-1e9, 1e9), 0, math.random(-1e9, 1e9))
                createLine:FireServer(spawn, pos)
            end
            task.wait()
        end
    end)
end

DestroyTab:CreateButton({
    Name = "Destroy Server (ラグ+強制飛ばし)",
    Callback = function()
        startLineLag()
        local players = Players:GetPlayers()
        for _, p in pairs(players) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local hrp = p.Character.HumanoidRootPart
                
                -- Ownership強制
                local setOwner = GrabEvents and GrabEvents:FindFirstChild("SetNetworkOwner")
                if setOwner then setOwner:FireServer(hrp, hrp.CFrame) end
                
                -- 高高度へ飛ばす
                local bp = Instance.new("BodyPosition", hrp)
                bp.MaxForce = Vector3.new(1/0, 1/0, 1/0)
                bp.P = 40000000
                bp.Position = Vector3.new(0, 1e9, 0)
                task.delay(2, function() bp:Destroy() end)
            end
        end
        Rayfield:Notify({Title = "Destroy", Content = "サーバー破壊コマンドを実行しました", Duration = 3})
    end
})

DestroyTab:CreateButton({
    Name = "Stop All Lag/System",
    Callback = function()
        lineLagEnabled = false
        BlobmanKill.isKillAura = false
        Rayfield:Notify({Title = "System", Content = "全てのラグ・キル処理を停止しました", Duration = 2})
    end
})

Rayfield:Notify({Title = "やきたまごハブ", Content = "完全統合版が準備完了しました", Duration = 5})
