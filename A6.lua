local aa = loadstring(game:HttpGet("https://raw.githubusercontent.com/jadpy/suki/refs/heads/main/orion"))()
local aa1 = game:GetService("Players")
local aa2 = game:GetService("ReplicatedStorage")
local aa3 = game:GetService("RunService")
local aa82 = game:GetService("Workspace")

local aa4 = aa1.LocalPlayer
local aa5 = aa2:WaitForChild("GrabEvents")

local aa6 = false
local aa7 = ""
local aa8 = 15
local aa9 = 25

local aa10 = aa2:WaitForChild("MenuToys"):WaitForChild("SpawnToyRemoteFunction")
local aa11 = aa5:WaitForChild("SetNetworkOwner")

local aa12 = {
    aa13 = false
}
local aa14 = {
    aa15 = nil,
}
local aa16 = {}
local aa17 = false

-- ===== ラグ方式（秒間100回 / 0.01秒で1回） =====
local running = false
local ragServer = false
local targetLag = false
local selectedPlayerName = nil

local createLineRemote = aa5:FindFirstChild("CreateGrabLine")
-- ================================================

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

local function aa40(aa41)
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

    local aa44 = aa43.CFrame * CFrame.new(0, 14, 20)
    
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

local function aa50()
    if aa17 then return nil end
    aa17 = true

    local aa51 = aa40("PalletLightBrown")
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

-- ===== ラグ方式（即連打 / 0秒待機） =====
local function startLagSpam()
    if running then return end
    if not createLineRemote then return end
    running = true

    task.spawn(function()
        while running do
            local spawnLocation = aa82:FindFirstChild("SpawnLocation")
                or aa82:FindFirstChild("Spawn")
                or (aa4.Character and aa4.Character:FindFirstChild("HumanoidRootPart"))

            if spawnLocation then
                createLineRemote:FireServer(spawnLocation, CFrame.new(math.random(-2010000000, 2000000001), 0, math.random(-2008100000, 2000200000)))
            end
            task.wait()  -- 待機時間0秒（最速）
        end
    end)
end

local function stopLagSpam()
    if not running then return end
    running = false
end
-- ================================================

local aa56 = aa:MakeWindow({Name = "Grabkick", HidePremium = true, SaveConfig = false})

-- タブ1
local aa57 = aa56:MakeTab({Name = "1", Icon = "rbxassetid://4483345998"})

local aa58 = aa57:AddDropdown({
    Name = "Target Player",
    Default = "",
    Options = aa18(),
    Callback = function(aa59)
        aa7 = aa59
        local aa60 = aa21(aa59)
        if aa60 then
            aa14.aa15 = aa60.Name
        else
            aa14.aa15 = nil
        end
    end
})

aa57:AddToggle({
    Name = "Grab kick (BETA)",
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
                    local aa62 = aa21(aa7)
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
                            aa68.Position = aa64.Position + Vector3.new(5, 10, 5)
                        end
                    end
                    task.wait()  -- 待機時間0秒（最速）
                end

                local aa69 = aa21(aa7)
                if aa69 and aa69.Character then
                    local aa70 = aa69.Character:FindFirstChild("HumanoidRootPart")
                    if aa70 and aa70:FindFirstChild("ControlBP") then
                        aa70.ControlBP:Destroy()
                    end
                end
            end)
        end

        if aa61 then
            local aa71 = workspace:FindFirstChild(aa4.Name.."SpawnedInToys")
            local aa72 = nil

            aa16["aa73"] = aa3.RenderStepped:Connect(function()
                if not aa12.aa13 then return end
                if not aa14.aa15 then return end

                local aa74 = aa1:FindFirstChild(aa14.aa15)
                if not aa74 or not aa74.Character then return end

                local aa75 = aa74.Character:FindFirstChild("HumanoidRootPart")
                local aa76 = aa74.Character:FindFirstChild("Humanoid")
                if not aa75 or not aa76 then return end

                if aa72 and aa72:IsDescendantOf(workspace) then
                    local aa77 = aa72:FindFirstChild("SoundPart")
                    if aa77 then
                        if not aa37(aa77, "PartOwner") then
                            aa72:Destroy()
                            aa72 = nil
                        end
                    else
                        aa72:Destroy()
                        aa72 = nil
                    end
                end

                if not aa17 and (not aa72 or not aa72:IsDescendantOf(workspace)) then
                    aa72 = aa71 and aa71:FindFirstChild("RagdollPalete") or aa50()
                end

                if aa72 and aa72:FindFirstChild("SoundPart") then
                    local aa78 = aa76:FindFirstChild("Ragdolled")
                    if aa78 and not aa78.Value then
                        aa72.SoundPart.Position = aa75.Position
                    end
                end
            end)
        else
            if aa16["aa73"] then
                aa16["aa73"]:Disconnect()
                aa16["aa73"] = nil
            end
        end
    end
})

local function aa79(aa80)
    if aa80 and aa14.aa15 == aa80.Name then
        aa14.aa15 = nil
    end
    aa58:Refresh(aa18(), true)
end

aa1.PlayerAdded:Connect(function()
    task.wait(0.5)
    aa79()
end)
aa1.PlayerRemoving:Connect(aa79)

aa:Init()
