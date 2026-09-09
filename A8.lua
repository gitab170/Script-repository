-- =============================================
-- tanpopo Hub - GrabKick Enhanced
-- ターゲット最大10人、ラグ威力50まで対応
-- =============================================

local aa = loadstring(game:HttpGet("https://raw.githubusercontent.com/jadpy/suki/refs/heads/main/orion"))()
local aa1 = game:GetService("Players")
local aa2 = game:GetService("ReplicatedStorage")
local aa3 = game:GetService("RunService")
local aa82 = game:GetService("Workspace")

local aa4 = aa1.LocalPlayer
local aa5 = aa2:WaitForChild("GrabEvents")

local aa6 = false
-- ターゲットを最大10人まで保持するテーブル
local aa7 = {}
local aa8 = 15
local aa9 = 25

local aa10 = aa2:WaitForChild("MenuToys"):WaitForChild("SpawnToyRemoteFunction")
local aa11 = aa5:WaitForChild("SetNetworkOwner")

local aa12 = {
    aa13 = false
}
local aa14 = {
    aa15 = {},
}
local aa16 = {}
local aa17 = false

-- ===== ラグ方式（威力調整付き 最大50） =====
local running = false
local lagMultiplier = 2  -- デフォルト2倍
-- ============================================

-- 各ターゲット用のパレット管理
local aa72List = {}

local function aa18()
    local aa19 = {}
    for _, aa20 in ipairs(aa1:GetPlayers()) do
        if aa20 ~= aa4 then
            table.insert(aa19, aa20.DisplayName .. " (@" .. aa20.Name .. ")")
        end
    end
    return aa19
end

local function aa21(aa22)
    for _, aa23 in ipairs(aa1:GetPlayers()) do
        local aa24 = aa23.DisplayName .. " (@" .. aa23.Name .. ")"
        if aa24 == aa22 then return aa23 end
    end
    return nil
end

local function aa25(aa26, aa27)
    if not aa26.Character then return end
    local aa28 = aa26.Character:FindFirstChild("HumanoidRootPart")
    if not aa28 or not aa27 then return end

    local aa29 = aa27.CFrame
    aa27.CFrame = aa28.CFrame * CFrame.new(0, 0, 2)

    for aa30 = 1, 15 do
        aa11:FireServer(aa28, aa28.CFrame)
        task.wait()
    end

    aa27.CFrame = aa29
end

local function aa31(aa32, aa33, aa34)
    return aa32:FindFirstChild(aa33) or aa32:WaitForChild(aa33, aa34 or 5)
end

local function aa35(aa36)
    if aa36 and aa36:IsA("BasePart") then
        aa11:FireServer(aa36, aa36.CFrame)
        task.wait()
    end
end

local function aa37(aa38, aa39)
    return aa38:FindFirstChild(aa39) ~= nil
end

local function aa40(aa41, offsetIndex)
    local aa42 = aa4.Character or aa4.CharacterAdded:Wait()
    local aa43 = aa42:WaitForChild("HumanoidRootPart")

    local waitCount = 0
    while (aa4.InPlot.Value and not aa4.InOwnedPlot.Value) and waitCount < 50 do
        task.wait(0.1)
        waitCount = waitCount + 1
    end
    waitCount = 0
    while not aa4.CanSpawnToy.Value and waitCount < 50 do
        task.wait(0.1)
        waitCount = waitCount + 1
    end

    local offset = Vector3.new((offsetIndex or 0) * 5, 0, 0)
    local aa44 = aa43.CFrame * CFrame.new(0, 14, 20) + offset

    local aa45 = workspace:FindFirstChild(aa4.Name.."SpawnedInToys")
    if not aa45 then
        aa45 = workspace:FindFirstChild("PlotItems")
        if aa45 then
            aa45 = aa45:FindFirstChild("Plot1")
        end
    end
    if not aa45 then
        aa45 = workspace
    end

    local aa46 = nil
    local aa47 = aa45.ChildAdded:Connect(function(aa48)
        if aa48.Name == aa41 then
            aa46 = aa48
        end
    end)

    task.spawn(function()
        pcall(function()
            aa10:InvokeServer(aa41, aa44, Vector3.zero)
        end)
    end)

    local aa49 = tick()
    repeat task.wait(0.05) until aa46 or (tick() - aa49) > 5
    aa47:Disconnect()
    return aa46
end

local function aa50(offsetIndex)
    if aa17 then return nil end
    aa17 = true

    local aa51 = aa40("PalletLightBrown", offsetIndex)
    if not aa51 then
        aa17 = false
        return nil
    end

    local aa52 = aa31(aa51, "SoundPart", 3)
    if not aa52 then
        aa51:Destroy()
        aa17 = false
        return nil
    end

    local retryCount = 0
    while retryCount < 10 do
        if not aa12.aa13 then
            aa51:Destroy()
            aa17 = false
            return nil
        end
        aa35(aa52)
        task.wait()
        if aa37(aa52, "PartOwner") then
            break
        end
        retryCount = retryCount + 1
    end

    if not aa37(aa52, "PartOwner") then
        aa51:Destroy()
        aa17 = false
        return nil
    end

    for _, aa54 in pairs(aa51:GetDescendants()) do
        if aa54:IsA("BasePart") then
            aa54.CanCollide = false
            aa54.Transparency = 0.8
        end
    end
    aa51.Name = "RagdollPalete"

    local aa55 = Instance.new("BodyVelocity")
    aa55.MaxForce = Vector3.new(0, math.huge, 0)
    aa55.Velocity = Vector3.new(0, 900, 0)
    aa55.Parent = aa52

    aa17 = false
    return aa51
end

-- ===== ラグスパム（威力調整付き 最大50） =====
local function startLagSpam()
    if running then return end
    local createLineRemote = aa5:FindFirstChild("CreateGrabLine")
    if not createLineRemote then return end
    running = true

    task.spawn(function()
        while running do
            local spawnLocation = aa82:FindFirstChild("SpawnLocation")
                or aa82:FindFirstChild("Spawn")
                or (aa4.Character and aa4.Character:FindFirstChild("HumanoidRootPart"))

            if spawnLocation then
                for _ = 1, lagMultiplier do
                    createLineRemote:FireServer(spawnLocation, CFrame.new(math.random(-2010000000, 2000000001), 0, math.random(-2008100000, 2000200000)))
                end
            end
            task.wait()
        end
    end)
end

local function stopLagSpam()
    if not running then return end
    running = false
end
-- =============================================

-- ===== UI作成 =====
local aa56 = aa:MakeWindow({Name = "tanpopo Hub", HidePremium = true, SaveConfig = false})

-- タブ: Kick
local aa57 = aa56:MakeTab({Name = "Kick", Icon = "rbxassetid://4483345998"})

-- 10個のドロップダウンを生成
local dropdowns = {}
for i = 1, 10 do
    local dropdown = aa57:AddDropdown({
        Name = "Target " .. i,
        Default = "",
        Options = aa18(),
        Callback = function(aa59)
            aa7[i] = aa59
            local aa60 = aa21(aa59)
            if aa60 then
                aa14.aa15[i] = aa60.Name
            else
                aa14.aa15[i] = nil
            end
        end
    })
    dropdowns[i] = dropdown
end

-- ★ ラグ威力スライダー（最大50） ★
aa57:AddSlider({
    Name = "Lag Power (1-50)",
    Min = 1,
    Max = 50,
    Default = 2,
    Callback = function(value)
        lagMultiplier = value
        if running then
            stopLagSpam()
            task.wait(0.1)
            startLagSpam()
        end
    end
})

aa57:AddToggle({
    Name = "Grab Kick (BETA)",
    Default = false,
    Callback = function(aa61)
        aa6 = aa61
        aa12.aa13 = aa61

        if aa61 then
            startLagSpam()
        else
            stopLagSpam()
        end

        if aa6 then
            task.spawn(function()
                while aa6 do
                    for idx = 1, 10 do
                        local targetDisplay = aa7[idx]
                        if targetDisplay and targetDisplay ~= "" then
                            local aa62 = aa21(targetDisplay)
                            local aa63 = aa4.Character
                            local aa64 = aa63 and aa63:FindFirstChild("HumanoidRootPart")

                            if aa62 and aa64 then
                                local aa65 = aa62.Character
                                local aa66 = aa65 and aa65:FindFirstChild("HumanoidRootPart")

                                if aa66 then
                                    local aa67 = (aa64.Position - aa66.Position).Magnitude
                                    if aa67 > aa9 then
                                        aa25(aa62, aa64)
                                    end

                                    aa11:FireServer(aa66, aa66.CFrame)
                                    if aa5:FindFirstChild("DestroyGrabLine") then
                                        aa5.DestroyGrabLine:FireServer(aa66)
                                    end

                                    aa66.AssemblyLinearVelocity = Vector3.zero
                                    aa66.AssemblyAngularVelocity = Vector3.zero

                                    local aa68 = aa66:FindFirstChild("ControlBP")
                                    if not aa68 then
                                        aa68 = Instance.new("BodyPosition")
                                        aa68.Name = "ControlBP"
                                        aa68.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                                        aa68.P = 800000
                                        aa68.Parent = aa66
                                    end
                                    -- 円形配置（10人用に調整）
                                    local angle = (idx - 1) * 2 * math.pi / 10
                                    local radius = 12
                                    local height = 5
                                    local offset = Vector3.new(
                                        radius * math.cos(angle),
                                        height,
                                        radius * math.sin(angle)
                                    )
                                    aa68.Position = aa64.Position + offset
                                end
                            end
                        end
                    end
                    task.wait()
                end

                -- 終了時に全ControlBPを削除
                for idx = 1, 10 do
                    local targetDisplay = aa7[idx]
                    if targetDisplay and targetDisplay ~= "" then
                        local aa69 = aa21(targetDisplay)
                        if aa69 and aa69.Character then
                            local aa70 = aa69.Character:FindFirstChild("HumanoidRootPart")
                            if aa70 and aa70:FindFirstChild("ControlBP") then
                                aa70.ControlBP:Destroy()
                            end
                        end
                    end
                end
            end)
        end

        if aa61 then
            local aa71 = workspace:FindFirstChild(aa4.Name.."SpawnedInToys")
            aa16["aa73"] = aa3.RenderStepped:Connect(function()
                if not aa12.aa13 then return end

                for idx = 1, 10 do
                    local targetName = aa14.aa15[idx]
                    if not targetName then
                        if aa72List[idx] and aa72List[idx]:IsDescendantOf(workspace) then
                            aa72List[idx]:Destroy()
                            aa72List[idx] = nil
                        end
                        continue
                    end

                    local aa74 = aa1:FindFirstChild(targetName)
                    if not aa74 or not aa74.Character then
                        if aa72List[idx] and aa72List[idx]:IsDescendantOf(workspace) then
                            aa72List[idx]:Destroy()
                            aa72List[idx] = nil
                        end
                        continue
                    end

                    local aa75 = aa74.Character:FindFirstChild("HumanoidRootPart")
                    local aa76 = aa74.Character:FindFirstChild("Humanoid")
                    if not aa75 or not aa76 then continue end

                    local pallet = aa72List[idx]
                    if pallet and pallet:IsDescendantOf(workspace) then
                        local soundPart = pallet:FindFirstChild("SoundPart")
                        if soundPart then
                            if not aa37(soundPart, "PartOwner") then
                                pallet:Destroy()
                                aa72List[idx] = nil
                            end
                        else
                            pallet:Destroy()
                            aa72List[idx] = nil
                        end
                    end

                    if not aa17 and (not aa72List[idx] or not aa72List[idx]:IsDescendantOf(workspace)) then
                        aa72List[idx] = aa50(idx)
                    end

                    if aa72List[idx] and aa72List[idx]:IsDescendantOf(workspace) then
                        local soundPart = aa72List[idx]:FindFirstChild("SoundPart")
                        if soundPart then
                            local ragdolled = aa76:FindFirstChild("Ragdolled")
                            if ragdolled and not ragdolled.Value then
                                soundPart.Position = aa75.Position
                            end
                        end
                    end
                end
            end)
        else
            if aa16["aa73"] then
                aa16["aa73"]:Disconnect()
                aa16["aa73"] = nil
            end
            for idx = 1, 10 do
                if aa72List[idx] and aa72List[idx]:IsDescendantOf(workspace) then
                    aa72List[idx]:Destroy()
                    aa72List[idx] = nil
                end
            end
        end
    end
})

-- プレイヤー追加/削除時に全ドロップダウンを更新
local function aa79(aa80)
    if aa80 then
        for i = 1, 10 do
            if aa14.aa15[i] == aa80.Name then
                aa14.aa15[i] = nil
                aa7[i] = nil
            end
        end
    end
    for i = 1, 10 do
        dropdowns[i]:Refresh(aa18(), true)
    end
end

aa1.PlayerAdded:Connect(function()
    task.wait(0.5)
    aa79()
end)
aa1.PlayerRemoving:Connect(aa79)

aa:Init()
