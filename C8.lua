local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
Library.ForceCheckbox = false

local Window = Library:CreateWindow({
    Title = "Dragonic",
    Footer = "Made by Siroo",
    NotifySide = "Right",
    ShowCustomCursor = true,
})

local Tabs = {
    Ragdoll = Window:AddTab("Ragdoll", "hammer"),
}

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
ThemeManager:SetFolder("Dragonic")
SaveManager:SetFolder("Dragonic/Configs")
SaveManager:SetSubFolder("config")

do
    local RagdollGroup = Tabs.Ragdoll:AddLeftGroupbox("Ragdoll Kill")
    
    local selectedPlayer = nil
    local isLooping = false
    local loopConnection = nil
    local monitorConnection = nil
    local currentBanana = nil
    local playerDropdown = nil
    local isTargetDead = false
    local toggleRef = nil
    
    -- Ragdoll Kill用
    local isRagdollActive = false
    local ragdollMonitorTask = nil
    
    local function getLocalChar()
        return LocalPlayer.Character
    end
    
    local function getHumanoidRootPart()
        local char = getLocalChar()
        if char then
            return char:FindFirstChild("HumanoidRootPart")
        end
        return nil
    end
    
    local function getSpawnedToysFolder()
        return Workspace:FindFirstChild(LocalPlayer.Name .. "SpawnedInToys")
    end
    
    -- ============================================================
    -- Ragdoll Kill 関数
    -- ============================================================
    local function destroyAllPencils()
        local folder = getSpawnedToysFolder()
        if not folder then return end
        local destroyToy = ReplicatedStorage:FindFirstChild("MenuToys") and ReplicatedStorage.MenuToys:FindFirstChild("DestroyToy")
        if not destroyToy then return end
        for _, child in pairs(folder:GetChildren()) do
            if child.Name == "ToolPencil" then
                pcall(function()
                    destroyToy:FireServer(child)
                end)
            end
        end
    end
    
    local function countPencils()
        local folder = getSpawnedToysFolder()
        if not folder then return 0 end
        local count = 0
        for _, child in pairs(folder:GetChildren()) do
            if child.Name == "ToolPencil" then
                count = count + 1
            end
        end
        return count
    end
    
    local function isPencilWeldedToTarget()
        local folder = getSpawnedToysFolder()
        if not folder then return false end
        
        local target = Players:FindFirstChild(selectedPlayer)
        if not target or not target.Character then return false end
        local targetHead = target.Character:FindFirstChild("Head")
        if not targetHead then return false end
        
        for _, child in pairs(folder:GetChildren()) do
            if child.Name == "ToolPencil" then
                local stickyPart = child:FindFirstChild("StickyPart")
                if stickyPart then
                    local weld = stickyPart:FindFirstChild("StickyWeld")
                    if weld and weld.Part1 == targetHead then
                        return true
                    end
                end
            end
        end
        return false
    end
    
    local function spawnToolPencil()
        local hrp = getHumanoidRootPart()
        if not hrp then return nil end
        
        local spawnPos = hrp.CFrame * CFrame.new(0, 14, 20)
        local menuToys = ReplicatedStorage:FindFirstChild("MenuToys")
        if not menuToys then return nil end
        
        local spawnRemote = menuToys:FindFirstChild("SpawnToyRemoteFunction")
        if not spawnRemote then return nil end
        
        local spawned = nil
        local folder = getSpawnedToysFolder()
        if not folder then return nil end
        
        local conn
        conn = folder.ChildAdded:Connect(function(child)
            if child.Name == "ToolPencil" then
                spawned = child
                conn:Disconnect()
            end
        end)
        
        task.spawn(function()
            pcall(function()
                spawnRemote:InvokeServer("ToolPencil", spawnPos, Vector3.zero)
            end)
        end)
        
        local start = tick()
        repeat
            task.wait(0.05)
        until spawned or (tick() - start) > 3
        
        if conn then
            pcall(function() conn:Disconnect() end)
        end
        
        return spawned
    end
    
    local function setNetworkOwnerPencil(part)
        if not part then return end
        local grabEvents = ReplicatedStorage:FindFirstChild("GrabEvents")
        if not grabEvents then return end
        local setNet = grabEvents:FindFirstChild("SetNetworkOwner")
        if not setNet then return end
        
        pcall(function()
            setNet:FireServer(part, part.CFrame)
            setNet:FireServer(part, part.CFrame)
            setNet:FireServer(part, part.CFrame)
            setNet:FireServer(part, part.CFrame)
            setNet:FireServer(part, part.CFrame)
        end)
    end
    
    local function doSticky()
        if not selectedPlayer or selectedPlayer == "" then return false end
        
        local target = Players:FindFirstChild(selectedPlayer)
        if not target or not target.Character then return false end
        
        local targetHead = target.Character:FindFirstChild("Head")
        if not targetHead then return false end
        
        destroyAllPencils()
        task.wait(0.05)
        
        local pencil = spawnToolPencil()
        if not pencil then return false end
        
        local soundPart = pencil:FindFirstChild("SoundPart")
        local stickyPart = pencil:FindFirstChild("StickyPart")
        
        if soundPart then
            setNetworkOwnerPencil(soundPart)
        end
        
        task.wait(0.05)
        
        if stickyPart then
            local stickyEvent = ReplicatedStorage:FindFirstChild("PlayerEvents") and ReplicatedStorage.PlayerEvents:FindFirstChild("StickyPartEvent")
            if stickyEvent then
                pcall(function()
                    stickyEvent:FireServer(stickyPart, targetHead, CFrame.new(0, 0/0, 0))
                    stickyEvent:FireServer(stickyPart, targetHead, CFrame.new(0, 0/0, 0))
                end)
                
                task.wait(0.5)
                
                if not isPencilWeldedToTarget() then
                    destroyAllPencils()
                    task.wait(0.05)
                    doSticky()
                end
                
                return true
            end
        end
        return false
    end
    
    local function RagdollRespawnMonitor()
        local target = Players:FindFirstChild(selectedPlayer)
        if not target then return end
        
        target.CharacterAdded:Connect(function()
            if isRagdollActive then
                doSticky()
            end
        end)
    end
    
    local function PencilMonitor()
        while isRagdollActive do
            local count = countPencils()
            
            if count == 0 then
                doSticky()
            elseif count >= 2 then
                destroyAllPencils()
                task.wait(0.05)
                doSticky()
            elseif count == 1 then
                if not isPencilWeldedToTarget() then
                    destroyAllPencils()
                    task.wait(0.05)
                    doSticky()
                end
            end
            
            task.wait(0.1)
        end
    end
    
    -- ============================================================
    -- Loop Banana Ragdoll
    -- ============================================================
    local function setNetworkOwner(part)
        if not part then return end
        local grabEvents = ReplicatedStorage:FindFirstChild("GrabEvents")
        if not grabEvents then return end
        local setNet = grabEvents:FindFirstChild("SetNetworkOwner")
        if not setNet then return end
        
        pcall(function()
            setNet:FireServer(part, part.CFrame)
        end)
    end
    
    local function destroyGrabLine(part)
        if not part then return end
        local grabEvents = ReplicatedStorage:FindFirstChild("GrabEvents")
        if not grabEvents then return end
        local destroyLine = grabEvents:FindFirstChild("DestroyGrabLine")
        if not destroyLine then return end
        
        pcall(function()
            destroyLine:FireServer(part)
        end)
    end
    
    local function destroyBanana(banana)
        if not banana then return end
        local menuToys = ReplicatedStorage:FindFirstChild("MenuToys")
        if not menuToys then return end
        local destroyToy = menuToys:FindFirstChild("DestroyToy")
        if not destroyToy then return end
        
        pcall(function()
            destroyToy:FireServer(banana)
        end)
    end
    
    local function spawnBanana()
        local hrp = getHumanoidRootPart()
        if not hrp then return nil end
        
        local spawnPos = hrp.CFrame * CFrame.new(0, 14, 20)
        local menuToys = ReplicatedStorage:FindFirstChild("MenuToys")
        if not menuToys then return nil end
        
        local spawnRemote = menuToys:FindFirstChild("SpawnToyRemoteFunction")
        if not spawnRemote then return nil end
        
        local spawned = nil
        local folder = getSpawnedToysFolder()
        if not folder then return nil end
        
        local conn
        conn = folder.ChildAdded:Connect(function(child)
            if child.Name == "FoodBanana" then
                spawned = child
                conn:Disconnect()
            end
        end)
        
        task.spawn(function()
            pcall(function()
                spawnRemote:InvokeServer("FoodBanana", spawnPos, Vector3.zero)
            end)
        end)
        
        local start = tick()
        repeat
            task.wait(0.05)
        until spawned or (tick() - start) > 3
        
        if conn then
            pcall(function() conn:Disconnect() end)
        end
        
        return spawned
    end
    
    local function holdBanana(banana)
        if not banana then return end
        local holdPart = banana:FindFirstChild("HoldPart")
        if not holdPart then return end
        
        local holdRemote = holdPart:FindFirstChild("HoldItemRemoteFunction")
        if not holdRemote then return end
        
        local char = getLocalChar()
        if not char then return end
        
        local success = false
        for i = 1, 5 do
            if not banana or not banana.Parent then break end
            local result = pcall(function()
                return holdRemote:InvokeServer(banana, char)
            end)
            if result then
                success = true
                break
            end
            task.wait(0.05)
        end
        return success
    end
    
    local function useBanana(banana)
        if not banana then return end
        local useEvent = ReplicatedStorage:FindFirstChild("HoldEvents") and ReplicatedStorage.HoldEvents:FindFirstChild("Use")
        if not useEvent then return end
        
        pcall(function()
            useEvent:FireServer(banana)
        end)
    end
    
    local function dropBanana(banana)
        if not banana then return end
        local holdPart = banana:FindFirstChild("HoldPart")
        if not holdPart then return end
        local dropRemote = holdPart:FindFirstChild("DropItemRemoteFunction")
        if not dropRemote then return end
        local hrp = getHumanoidRootPart()
        if not hrp then return end
        
        local dropPos = hrp.CFrame * CFrame.new(0, 15, 0)
        pcall(function()
            dropRemote:InvokeServer(banana, dropPos, dropPos)
        end)
    end
    
    local function getTargetLeg()
        if not selectedPlayer then return nil end
        local target = Players:FindFirstChild(selectedPlayer)
        if not target or not target.Character then return nil end
        return target.Character:FindFirstChild("Left Leg")
    end
    
    local function getTargetHealth()
        if not selectedPlayer then return 0 end
        local target = Players:FindFirstChild(selectedPlayer)
        if not target or not target.Character then return 0 end
        local hum = target.Character:FindFirstChildOfClass("Humanoid")
        if not hum then return 0 end
        return hum.Health
    end
    
    local function fullBananaCycle()
        if not selectedPlayer or selectedPlayer == "" then return false end
        
        local banana = spawnBanana()
        if not banana then return false end
        
        holdBanana(banana)
        task.wait(0.05)
        holdBanana(banana)
        task.wait(0.05)
        
        task.wait(0.5)
        
        useBanana(banana)
        
        task.wait(2.3)
        
        dropBanana(banana)
        task.wait(0.05)
        dropBanana(banana)
        
        task.wait(0.3)
        
        return banana
    end
    
    -- ループ再開用の関数
    local function restartLoop(banana)
        if loopConnection then
            loopConnection:Disconnect()
            loopConnection = nil
        end
        
        currentBanana = banana
        
        local hitboxPart = banana:FindFirstChild("HitboxPart")
        if not hitboxPart then return end
        
        loopConnection = RunService.Heartbeat:Connect(function()
            if not isLooping then
                stopLoop()
                return end
            
            if not currentBanana or not currentBanana.Parent then
                return end
            
            local folder = getSpawnedToysFolder()
            local bananaExists = false
            if folder then
                for _, child in pairs(folder:GetChildren()) do
                    if child.Name == "FoodBanana" then
                        bananaExists = true
                        currentBanana = child
                        hitboxPart = child:FindFirstChild("HitboxPart")
                        break
                    end
                end
            end
            
            if not bananaExists or not hitboxPart then
                loopConnection:Disconnect()
                loopConnection = nil
                currentBanana = nil
                if isLooping then
                    task.wait(0.05)
                    -- 監視ループが再スポーンしてくれる
                end
                return
            end
            
            local hrp = getHumanoidRootPart()
            if not hrp then return end
            
            local targetPos
            local targetCFrame
            
            local health = getTargetHealth()
            if health <= 0 then
                isTargetDead = true
                targetPos = hrp.CFrame * CFrame.new(0, 7, 0)
                targetCFrame = CFrame.new(targetPos.Position)
            else
                isTargetDead = false
                local leg = getTargetLeg()
                if leg then
                    targetPos = leg.CFrame * CFrame.new(0, 0.5, 0)
                    targetCFrame = leg.CFrame
                else
                    targetPos = hrp.CFrame * CFrame.new(0, 7, 0)
                    targetCFrame = CFrame.new(targetPos.Position)
                end
            end
            
            setNetworkOwner(hitboxPart)
            destroyGrabLine(hitboxPart)
            
            local bp = hitboxPart:FindFirstChild("BodyPosition")
            if bp then
                bp.Position = targetPos.Position
            else
                bp = Instance.new("BodyPosition")
                bp.P = 10000
                bp.D = 100
                bp.MaxForce = Vector3.new(1e9, 1e9, 1e9)
                bp.Position = targetPos.Position
                bp.Parent = hitboxPart
            end
            
            local bg = hitboxPart:FindFirstChild("BodyGyro")
            if bg then
                bg.CFrame = targetCFrame
            else
                bg = Instance.new("BodyGyro")
                bg.P = 10000
                bg.D = 100
                bg.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
                bg.CFrame = targetCFrame
                bg.Parent = hitboxPart
            end
        end)
    end
    
    local function startLoop()
        if isLooping then return end
        if not selectedPlayer or selectedPlayer == "" then return end
        
        isLooping = true
        isTargetDead = false
        
        local banana = fullBananaCycle()
        if banana then
            restartLoop(banana)
        end
        
        -- バナナ監視用ループ
        monitorConnection = RunService.Heartbeat:Connect(function()
            if not isLooping then return end
            
            local folder = getSpawnedToysFolder()
            local bananaExists = false
            if folder then
                for _, child in pairs(folder:GetChildren()) do
                    if child.Name == "FoodBanana" then
                        bananaExists = true
                        break
                    end
                end
            end
            
            if not bananaExists then
                -- ループ停止
                if loopConnection then
                    loopConnection:Disconnect()
                    loopConnection = nil
                end
                
                task.wait(0.05)
                
                -- 新しいバナナをスポーン
                local newBanana = fullBananaCycle()
                if newBanana then
                    -- ループ再開
                    restartLoop(newBanana)
                end
            end
        end)
    end
    
    local function stopLoop()
        isLooping = false
        if loopConnection then
            loopConnection:Disconnect()
            loopConnection = nil
        end
        if monitorConnection then
            monitorConnection:Disconnect()
            monitorConnection = nil
        end
        
        if currentBanana then
            destroyBanana(currentBanana)
            local hitboxPart = currentBanana:FindFirstChild("HitboxPart")
            if hitboxPart then
                local bp = hitboxPart:FindFirstChild("BodyPosition")
                if bp then bp:Destroy() end
                local bg = hitboxPart:FindFirstChild("BodyGyro")
                if bg then bg:Destroy() end
            end
            currentBanana = nil
        end
        
        local folder = getSpawnedToysFolder()
        if folder then
            for _, child in pairs(folder:GetChildren()) do
                if child.Name == "FoodBanana" then
                    destroyBanana(child)
                end
            end
        end
    end
    
    -- ============================================================
    -- UI
    -- ============================================================
    local function GetPlayerList()
        local list = {}
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                table.insert(list, player.DisplayName .. " (" .. player.Name .. ")")
            end
        end
        return list
    end
    
    local function GetPlayerNameFromDisplay(display)
        if not display or display == "" then return nil end
        local startPos, endPos = string.find(display, "%(")
        if startPos then
            return string.sub(display, startPos + 1, -2)
        end
        return nil
    end
    
    playerDropdown = RagdollGroup:AddDropdown("TargetSelect", {
        Text = "Select Player",
        Default = "",
        Values = GetPlayerList(),
        Callback = function(v)
            local name = GetPlayerNameFromDisplay(v)
            if name then
                selectedPlayer = name
            else
                selectedPlayer = nil
            end
        end
    })
    
    local function UpdatePlayerList()
        if playerDropdown then
            playerDropdown:SetValues(GetPlayerList())
        end
    end
    
    Players.PlayerAdded:Connect(function()
        task.wait(0.5)
        UpdatePlayerList()
    end)
    
    Players.PlayerRemoving:Connect(function()
        task.wait(0.2)
        UpdatePlayerList()
    end)
    
    task.spawn(function()
        task.wait(1)
        UpdatePlayerList()
    end)
    
    -- Ragdoll Kill Toggle
    RagdollGroup:AddToggle("RagdollKill", {
        Text = "Ragdoll Kill",
        Default = false,
        Callback = function(v)
            if v then
                if not selectedPlayer or selectedPlayer == "" then
                    return
                end
                isRagdollActive = true
                doSticky()
                RagdollRespawnMonitor()
                ragdollMonitorTask = task.spawn(PencilMonitor)
            else
                isRagdollActive = false
                if ragdollMonitorTask then
                    task.cancel(ragdollMonitorTask)
                    ragdollMonitorTask = nil
                end
                destroyAllPencils()
            end
        end
    })
    
    -- Loop Banana Ragdoll Toggle
    toggleRef = RagdollGroup:AddToggle("LoopBananaRagdoll", {
        Text = "Loop Banana Ragdoll",
        Default = false,
        Callback = function(v)
            if v then
                if not selectedPlayer or selectedPlayer == "" then
                    toggleRef:Set(false)
                    return
                end
                stopLoop()
                startLoop()
            else
                stopLoop()
            end
        end
    })
end
