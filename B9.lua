-- [[ Orion Lib ]]
local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/jadpy/suki/refs/heads/main/orion"))()

local Window = OrionLib:MakeWindow({
    Name = "kick all",
    HidePremium = false,
    SaveConfig = false,
    ConfigFolder = "KickAllConfig"
})

local Tab = Window:MakeTab({
    Name = "Kick All",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local currentBlob = nil
local isActive = false
local playerStatus = {}

local function GetAllPlayers()
    local players = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            table.insert(players, player)
        end
    end
    return players
end

local function GetMyRoot()
    return LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
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
        ReplicatedStorage.MenuToys.SpawnToyRemoteFunction:InvokeServer("CreatureBlobman", spawnPos, Vector3.new(0, 127, 0))
    end
    task.wait(0.5)
    
    local toyFolder = workspace:FindFirstChild(LocalPlayer.Name .. "SpawnedInToys")
    currentBlob = toyFolder and toyFolder:FindFirstChild("CreatureBlobman")
    if not currentBlob then 
        ResetTargets()
        isActive = false
        return 
    end
    
    local vehicleSeat = currentBlob:FindFirstChild("VehicleSeat")
    if vehicleSeat and LocalPlayer.Character then
        local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
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
    
    myRoot.CFrame = CFrame.new(0, 100, 0)
    myRoot.AssemblyLinearVelocity = Vector3.zero
    task.wait(0.1)
    
    for _, part in ipairs(currentBlob:GetDescendants()) do
        if part:IsA("BasePart") then pcall(function() part.Anchored = true end) end
    end
    task.wait(0.1)
    
    local radius = 15
    for i, targetPlayer in ipairs(allPlayers) do
        local targetRoot = targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart")
        if targetRoot then
            local angle = math.rad((i - 1) * (360 / #allPlayers))
            local x = radius * math.cos(angle)
            local z = radius * math.sin(angle)
            targetRoot.CFrame = CFrame.new(x, 110, z)
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
        task.wait(0.1)
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

Tab:AddButton({
    Name = "Kick All",
    Callback = KickAll
})

OrionLib:Init()
