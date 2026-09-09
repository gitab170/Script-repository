--初心者ハブ 完全日本語版（全ロジック保持）

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local camera = workspace.CurrentCamera
local UserInputService = game:GetService("UserInputService")

-- Orion Library ロード
local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/jadpy/suki/refs/heads/main/orion"))()

-- ウィンドウ作成
local Window = OrionLib:MakeWindow({
	Name = "初心者ハブ",
	HidePremium = false,
	SaveConfig = true,
	ConfigFolder = "OrionTest"
})

-- ===== 羽用変数 =====
local mode = "None"
local presentEnabled = false
local presentSpeed = 25
local monoAllEnabled = false
local monoAllSpeed = 10
local hoveringObjects = {}
local objectData = {}
local tpCoordinates = "0, 50, 0"
local selectedTargetName = LP.Name
local selectedGiftTarget = LP.Name
local geroAllEnabled = false
local geroSettings = { wait = 0.1, dist = 3 }
local settings = {
    speed = 0.03, width = 18, height = 5,
    speedEnabled = false, jumpEnabled = false, customSpeed = 100, customJump = 150,
    flyEnabled = false, flySpeed = 50, infJump = false, fov = 70,
    espNames = false, espBoxes = false, espTracers = false
}

-- Fly用物理オブジェクト
local flyBV = Instance.new("BodyVelocity")
flyBV.MaxForce = Vector3.new(1,1,1) * math.huge
local flyBG = Instance.new("BodyGyro")
flyBG.MaxTorque = Vector3.new(1,1,1) * math.huge

-- エフェクト用Highlight
local viewHighlight = Instance.new("Highlight")
viewHighlight.Name = "Hane_ViewHighlight"
viewHighlight.FillTransparency = 0.5
viewHighlight.Parent = nil

-- ===== バイパス処理 =====
local mt = getrawmetatable(game)
local old_index = mt.__index
setreadonly(mt, false)
mt.__index = newcclosure(function(t, k)
    if not checkcaller() and t:IsA("Humanoid") then
        if k == "WalkSpeed" then return 16 end
        if k == "JumpPower" then return 50 end
    end
    return old_index(t, k)
end)
setreadonly(mt, true)

-- ===== 便利関数 =====
local function getPlayerList()
    local list = {LP.Name}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then table.insert(list, p.Name) end
    end
    return list
end

-- ===== ESPロジック =====
local function createESP(p)
    local box = Drawing.new("Square")
    box.Visible = false; box.Color = Color3.new(1, 1, 1); box.Thickness = 1
    local name = Drawing.new("Text")
    name.Visible = false; name.Color = Color3.new(1, 1, 1); name.Size = 16; name.Center = true; name.Outline = true
    local tracer = Drawing.new("Line")
    tracer.Visible = false; tracer.Color = Color3.new(1, 1, 1); tracer.Thickness = 1

    local connection
    connection = RunService.RenderStepped:Connect(function()
        if p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChildOfClass("Humanoid") then
            local hrp = p.Character.HumanoidRootPart
            local pos, onScreen = camera:WorldToViewportPoint(hrp.Position)
            if onScreen then
                if settings.espBoxes then
                    local scale = (1 / (camera.CFrame.Position - hrp.Position).Magnitude) * 1000
                    box.Size = Vector2.new(scale * 1.5, scale * 2)
                    box.Position = Vector2.new(pos.X - box.Size.X / 2, pos.Y - box.Size.Y / 2); box.Visible = true
                else box.Visible = false end
                if settings.espNames then
                    name.Text = p.Name; name.Position = Vector2.new(pos.X, pos.Y - 40); name.Visible = true
                else name.Visible = false end
                if settings.espTracers then
                    tracer.From = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
                    tracer.To = Vector2.new(pos.X, pos.Y); tracer.Visible = true
                else tracer.Visible = false end
            else box.Visible = false; name.Visible = false; tracer.Visible = false end
        else
            box.Visible = false; name.Visible = false; tracer.Visible = false
            if not p.Parent then box:Remove(); name:Remove(); tracer:Remove(); connection:Disconnect() end
        end
    end)
end
for _, v in ipairs(Players:GetPlayers()) do if v ~= LP then createESP(v) end end
Players.PlayerAdded:Connect(function(v) if v ~= LP then createESP(v) end end)

-- ===== 物理能力管理 =====
local function clearObjects()
    for o in pairs(hoveringObjects) do
        pcall(function()
            if o and o.Parent then
                o.CanCollide = true
                if o:FindFirstChild("SyncForce") then o.SyncForce:Destroy() end
                if o:FindFirstChild("SyncGyro") then o.SyncGyro:Destroy() end
            end
        end)
    end
    hoveringObjects = {}; objectData = {}
end

local function registerPart(part)
    if not part:IsA("BasePart") or part.Anchored then return end
    if LP.Character and part:IsDescendantOf(LP.Character) then return end
    if hoveringObjects[part] then return end 
    hoveringObjects[part] = true
    objectData[part] = { seed = math.random() * 100, phase = math.random() * math.pi * 2 }
    local bv = Instance.new("BodyVelocity")
    bv.Name = "SyncForce"; bv.MaxForce = Vector3.new(1,1,1)*1e6; bv.Velocity = Vector3.zero; bv.Parent = part
    local bg = Instance.new("BodyGyro")
    bg.Name = "SyncGyro"; bg.MaxTorque = Vector3.new(1,1,1)*1e6; bg.P = 3000; bg.D = 500; bg.Parent = part
    part.CanCollide = false
    pcall(function() part:SetNetworkOwner(LP) end)
end

-- ===== テレポートタブ =====
local TPTab = Window:MakeTab({
	Name = "テレポート",
	Icon = "rbxassetid://4483345998",
	PremiumOnly = false
})

local function Teleport(coords)
	local player = game.Players.LocalPlayer
	if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		player.Character.HumanoidRootPart.CFrame = CFrame.new(coords)
	end
end

TPTab:AddSection({Name = "各地点への移動"})
TPTab:AddButton({ Name = "ピンクの家へテレポート", Callback = function() Teleport(Vector3.new(-481.23, -7.35, -149.67)) end })
TPTab:AddButton({ Name = "緑の家へテレポート", Callback = function() Teleport(Vector3.new(-546.02, -7.35, 78.07)) end })
TPTab:AddButton({ Name = "赤い家へテレポート", Callback = function() Teleport(Vector3.new(542.11, 123.34, -91.78)) end })
TPTab:AddButton({ Name = "水色の家へテレポート", Callback = function() Teleport(Vector3.new(496.99, 83.34, -350.96)) end })

-- ===== WINGSタブ =====
local WingTab = Window:MakeTab({
	Name = "あんまわからん",
	Icon = "rbxassetid://6031075927",
	PremiumOnly = false
})

local TargetSet = "Stick"
local Enabled = false
local function rescan() end

WingTab:AddDropdown({
	Name = "ターゲット選択",
	Default = TargetSet,
	Options = {"Stick", "Sparkler","Toilet", "Piano", "GlassBox", "Pallet"},
	Callback = function(v) TargetSet = v; if Enabled then rescan() end end
})

-- ===== サイレントエイム =====
local SilentEnabled = false
local SilentMaxStuds = 40

local SATab = Window:MakeTab({Name = "サイレントエイム", Icon = "rbxassetid://4483345998"})
SATab:AddToggle({ Name = "Silent aim", Default = false, Callback = function(v) SilentEnabled = v end })
SATab:AddSlider({ Name = "最大補正距離", Min = 0, Max = 50, Default = 40, Increment = 1, Callback = function(v) SilentMaxStuds = v end })

local function GetClosestPlayer()
	local Closest, Distance = nil, 10000
	for _, Player in next, Players:GetPlayers() do
		if Player ~= LP and Player.Character and Player.Character:FindFirstChild("Head") then
			local Head = Player.Character.Head
			local ScreenPos, IsVisible = workspace.CurrentCamera:WorldToScreenPoint(Head.Position)
			if IsVisible then
				local _Distance = (Vector2.new(LP:GetMouse().X, LP:GetMouse().Y) - Vector2.new(ScreenPos.X, ScreenPos.Y)).Magnitude
				if _Distance <= Distance and (workspace.CurrentCamera.CFrame.Position - Head.Position).Magnitude <= SilentMaxStuds then
					Closest = Head; Distance = _Distance
				end
			end
		end
	end
	return Closest
end

local oldNamecall; oldNamecall = hookmetamethod(game, "__namecall", function(...)
	local Method = getnamecallmethod(); local Args = {...}
	if SilentEnabled and Method == "Raycast" and Args[1] == workspace then
		local Hit = GetClosestPlayer()
		if Hit then Args[3] = (Hit.Position - Args[2]).Unit * SilentMaxStuds; return oldNamecall(unpack(Args)) end
	end
	return oldNamecall(...)
end)

-- ===== ブロブマン =====
local BlobmanTab = Window:MakeTab({ Name = "ブロブマン", Icon = "rbxassetid://10427807755", PremiumOnly = false })

local blobalter = 1
local ForceGrabCoroutine = nil

local function findActiveBlobman()
	for _, v in ipairs(Workspace:GetDescendants()) do
		if v.Name == "CreatureBlobman" and v:FindFirstChild("VehicleSeat") and v.VehicleSeat:FindFirstChild("SeatWeld") then
			if LP.Character and v.VehicleSeat.SeatWeld.Part1 and v.VehicleSeat.SeatWeld.Part1:IsDescendantOf(LP.Character) then return v end
		end
	end
	return nil
end

BlobmanTab:AddToggle({
	Name = "全員掴む",
	Default = false,
	Callback = function(v)
		if v then
			ForceGrabCoroutine = task.spawn(function()
				while true do
					local blobman = findActiveBlobman()
					if blobman then
						for _, plr in ipairs(Players:GetPlayers()) do
							if plr ~= LP and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
								local grabPart = (blobalter == 1) and blobman:FindFirstChild("LeftDetector") or blobman:FindFirstChild("RightDetector")
								local weldPart = grabPart and grabPart:FindFirstChild(blobalter == 1 and "LeftWeld" or "RightWeld")
								blobalter = (blobalter == 1) and 2 or 1
								local grabEvent = blobman:FindFirstChild("BlobmanSeatAndOwnerScript") and blobman.BlobmanSeatAndOwnerScript:FindFirstChild("CreatureGrab")
								if grabEvent then pcall(function() grabEvent:FireServer(grabPart, plr.Character.HumanoidRootPart, weldPart) end) end
							end
						end
						if ReplicatedStorage:FindFirstChild("CreatureEvents") and ReplicatedStorage.CreatureEvents:FindFirstChild("CreatureToss") then pcall(function() ReplicatedStorage.CreatureEvents.CreatureToss:FireServer() end) end
					end
					task.wait(0.5)
				end
			end)
		else 
			if ForceGrabCoroutine then task.cancel(ForceGrabCoroutine) end 
		end
	end
})

-- ===== ★★★ 羽タブ ★★★ =====
local HaneTab = Window:MakeTab({
    Name = "羽",
    Icon = "rbxassetid://4483345998"
})

-- 1. メイン能力
local targetDropdown = HaneTab:AddDropdown({
    Name = "能力の対象",
    Default = LP.Name,
    Options = getPlayerList(),
    Callback = function(V) selectedTargetName = V end
})
HaneTab:AddButton({ Name = "リスト更新", Callback = function() targetDropdown:Refresh(getPlayerList(), true) end })
HaneTab:AddDropdown({
    Name = "モード選択",
    Default = "None",
    Options = {"None", "回転", "魔法陣", "幽霊", "神聖", "卍", "幾何学の輪"},
    Callback = function(Value)
        local map = {["None"]="None", ["回転"]="Orbit", ["魔法陣"]="MagicCircle", ["幽霊"]="Ghost", ["神聖"]="Divine", ["卍"]="Manji", ["幾何学の輪"]="Geometry"}
        mode = map[Value] or "None"
        if mode == "None" then clearObjects() end
    end
})
HaneTab:AddButton({ Name = "全パーツ解除", Callback = function() clearObjects() end })

-- 2. 調整
local AdjustTab = Window:MakeTab({ Name = "調整", Icon = "rbxassetid://4483345998" })
AdjustTab:AddSlider({ Name = "回転速度", Min = 0.01, Max = 0.15, Default = 0.03, Increment = 0.01, Callback = function(V) settings.speed = V end })
AdjustTab:AddSlider({ Name = "広がり", Min = 5, Max = 100, Default = 18, Increment = 1, Callback = function(V) settings.width = V end })
AdjustTab:AddSlider({ Name = "高さ", Min = -20, Max = 30, Default = 5, Increment = 1, Callback = function(V) settings.height = V end })

-- 3. 身体・設定
local MiscTab = Window:MakeTab({ Name = "身体・設定", Icon = "rbxassetid://4483345998" })
MiscTab:AddToggle({ Name = "Fly (飛行)", Default = false, Callback = function(V) settings.flyEnabled = V end })
MiscTab:AddSlider({ Name = "Fly速度", Min = 10, Max = 300, Default = 50, Increment = 1, Callback = function(V) settings.flySpeed = V end })
MiscTab:AddToggle({ Name = "高速移動有効", Default = false, Callback = function(V) settings.speedEnabled = V end })
MiscTab:AddSlider({ Name = "速度設定", Min = 16, Max = 500, Default = 100, Increment = 1, Callback = function(V) settings.customSpeed = V end })
MiscTab:AddToggle({ Name = "ジャンプ有効", Default = false, Callback = function(V) settings.jumpEnabled = V end })
MiscTab:AddSlider({ Name = "ジャンプ設定", Min = 50, Max = 500, Default = 150, Increment = 1, Callback = function(V) settings.customJump = V end })
MiscTab:AddToggle({ Name = "無限ジャンプ", Default = false, Callback = function(V) settings.infJump = V end })
MiscTab:AddSlider({ Name = "視野角 (FOV)", Min = 30, Max = 120, Default = 70, Increment = 1, Callback = function(V) settings.fov = V end })

-- 4. プレゼント
local PresentTab = Window:MakeTab({ Name = "プレゼント", Icon = "rbxassetid://4483345998" })
local giftDropdown = PresentTab:AddDropdown({
    Name = "贈る相手を選択",
    Default = LP.Name,
    Options = getPlayerList(),
    Callback = function(V) selectedGiftTarget = V end
})
PresentTab:AddButton({ Name = "リスト更新", Callback = function() giftDropdown:Refresh(getPlayerList(), true) end })
PresentTab:AddSlider({ 
    Name = "荒ぶる速度", 
    Min = 5, 
    Max = 100, 
    Default = 25, 
    Increment = 1, 
    Callback = function(V) presentSpeed = V end 
})
PresentTab:AddToggle({
    Name = "プレゼント開始",
    Default = false,
    Callback = function(V) 
        presentEnabled = V 
        if V then mode = "None"; monoAllEnabled = false end 
    end
})

-- 5. 荒らし
local TrollTab = Window:MakeTab({ Name = "荒らし", Icon = "rbxassetid://4483345998" })
TrollTab:AddToggle({
    Name = "ものおーる (自分以外全員)",
    Default = false,
    Callback = function(V)
        monoAllEnabled = V
        if V then mode = "None"; presentEnabled = false end
    end
})
TrollTab:AddSlider({ Name = "ものおーる速度", Min = 1, Max = 30, Default = 10, Increment = 1, Callback = function(V) monoAllSpeed = V end })

TrollTab:AddToggle({
    Name = "げろおーる (実行)",
    Default = false,
    Callback = function(V)
        geroAllEnabled = V
        if V then
            task.spawn(function()
                while geroAllEnabled do
                    for _, p in ipairs(Players:GetPlayers()) do
                        if not geroAllEnabled then break end
                        if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                            if LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
                                LP.Character.HumanoidRootPart.CFrame = p.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, geroSettings.dist)
                            end
                        end
                        task.wait(geroSettings.wait)
                    end
                    task.wait()
                end
            end)
        end
    end
})
TrollTab:AddSlider({ Name = "げろおーる速度", Min = 0.01, Max = 1, Default = 0.1, Increment = 0.01, Callback = function(V) geroSettings.wait = V end })
TrollTab:AddSlider({ Name = "げろおーる距離", Min = -20, Max = 20, Default = 3, Increment = 1, Callback = function(V) geroSettings.dist = V end })
TrollTab:AddToggle({
    Name = "高速チャット送信",
    Default = false,
    Callback = function(V)
        _G.Spam = V
        task.spawn(function()
            while _G.Spam do
                local chatRemote = game:GetService("ReplicatedStorage"):FindFirstChild("DefaultChatSystemChatEvents") 
                if chatRemote then chatRemote.SayMessageRequest:FireServer("羽 ON TOP", "All") end
                task.wait(1)
            end
        end)
    end
})

-- 6. TP (羽用)
local HaneTPTab = Window:MakeTab({ Name = "TP (羽)", Icon = "rbxassetid://4483345998" })
HaneTPTab:AddTextbox({ Name = "座標入力", Default = "0, 50, 0", TextDisappear = false, Callback = function(V) tpCoordinates = V end })
HaneTPTab:AddButton({ Name = "座標へ移動実行", Callback = function()
    local coords = string.split(tpCoordinates, ",")
    if #coords == 3 then
        local x,y,z = tonumber(coords[1]), tonumber(coords[2]), tonumber(coords[3])
        if x and y and z and LP.Character then LP.Character.HumanoidRootPart.CFrame = CFrame.new(x,y,z) end
    end
end})
local playerDropdownTP = HaneTPTab:AddDropdown({ Name = "プレイヤーを選択", Options = getPlayerList(), Callback = function(V) selectedTargetName = V end })
HaneTPTab:AddButton({ Name = "リスト更新", Callback = function() playerDropdownTP:Refresh(getPlayerList(), true) end })
HaneTPTab:AddButton({ Name = "選択プレイヤーへ移動", Callback = function()
    local target = Players:FindFirstChild(selectedTargetName)
    if target and target.Character then LP.Character.HumanoidRootPart.CFrame = target.Character.HumanoidRootPart.CFrame * CFrame.new(0,0,3) end
end})

-- 7. ESP
local ESPTab = Window:MakeTab({ Name = "ESP", Icon = "rbxassetid://4483345998" })
ESPTab:AddToggle({ Name = "名前を表示", Default = false, Callback = function(V) settings.espNames = V end })
ESPTab:AddToggle({ Name = "ボックスを表示", Default = false, Callback = function(V) settings.espBoxes = V end })
ESPTab:AddToggle({ Name = "トレーサーを表示", Default = false, Callback = function(V) settings.espTracers = V end })

-- 8. 視点変更
local ViewTab = Window:MakeTab({ Name = "視点変更", Icon = "rbxassetid://4483345998" })
local playerDropdownView = ViewTab:AddDropdown({ Name = "プレイヤーを選択", Options = getPlayerList(), Callback = function(V) selectedTargetName = V end })
ViewTab:AddButton({ Name = "リスト更新", Callback = function() playerDropdownView:Refresh(getPlayerList(), true) end })
ViewTab:AddToggle({ Name = "観戦モード", Default = false, Callback = function(V)
    if V then
        local t = Players:FindFirstChild(selectedTargetName)
        if t and t.Character then camera.CameraSubject = t.Character:FindFirstChildOfClass("Humanoid") end
    else
        if LP.Character then camera.CameraSubject = LP.Character:FindFirstChildOfClass("Humanoid") end
    end
end})
ViewTab:AddToggle({ Name = "ターゲットハイライト", Default = false, Callback = function(V)
    if V then
        local t = Players:FindFirstChild(selectedTargetName)
        if t and t.Character then viewHighlight.Parent = t.Character end
    else viewHighlight.Parent = nil end
end})

-- ===== 羽メインループ =====
RunService.Stepped:Connect(function()
    if LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = LP.Character.HumanoidRootPart
        local hum = LP.Character:FindFirstChildOfClass("Humanoid")

        -- Fly
        if settings.flyEnabled then
            flyBV.Parent = hrp; flyBG.Parent = hrp; flyBG.CFrame = camera.CFrame
            flyBV.Velocity = hum.MoveDirection.Magnitude > 0 and camera.CFrame.LookVector * settings.flySpeed or Vector3.new(0, 0.1, 0)
            hum.PlatformStand = true
        else
            flyBV.Parent = nil; flyBG.Parent = nil
            if hum then
                hum.PlatformStand = false
                hum.WalkSpeed = settings.speedEnabled and settings.customSpeed or 16
                hum.JumpPower = settings.jumpEnabled and settings.customJump or 50
            end
        end
    end
    camera.FieldOfView = settings.fov
end)

UserInputService.JumpRequest:Connect(function()
    if settings.infJump and LP.Character then
        local hum = LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- 物理エフェクト計算
local timeCounter = 0
RunService.Heartbeat:Connect(function()
    timeCounter = timeCounter + settings.speed
    local currentParts = {}
    for o in pairs(objectData) do table.insert(currentParts, o) end
    local totalParts = #currentParts
    if totalParts == 0 then return end

    if monoAllEnabled then
        local others = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                table.insert(others, p.Character.HumanoidRootPart)
            end
        end
        if #others > 0 then
            for i, o in ipairs(currentParts) do
                if o and o.Parent and o:FindFirstChild("SyncForce") then
                    local targetHRP = others[(i % #others) + 1]
                    local pAngle = (timeCounter * monoAllSpeed) + (i * 0.5)
                    local targetPos = targetHRP.Position + Vector3.new(math.cos(pAngle) * 5, math.sin(timeCounter * 3 + i) * 2, math.sin(pAngle) * 5)
                    o.SyncForce.Velocity = (targetPos - o.Position) * 35
                    o.SyncGyro.CFrame = CFrame.new(o.Position, targetHRP.Position)
                end
            end
            return
        end
    end

    local target
    if presentEnabled then target = Players:FindFirstChild(selectedGiftTarget)
    else
        if mode == "None" then return end
        target = Players:FindFirstChild(selectedTargetName)
    end
    local hrp = target and target.Character and target.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    for i, o in ipairs(currentParts) do
        if o and o.Parent and o:FindFirstChild("SyncForce") then
            local data = objectData[o]
            local angle = (timeCounter) + (i / totalParts * math.pi * 2)
            local targetPos
            if presentEnabled then
                local pAngle = (timeCounter * (presentSpeed/10)) + (i / totalParts * math.pi * 2)
                targetPos = hrp.Position + Vector3.new(math.cos(pAngle) * 4, math.sin(timeCounter * 2 + i) * 2, math.sin(pAngle) * 4)
                o.SyncForce.Velocity = (targetPos - o.Position) * presentSpeed
            elseif mode == "Orbit" then 
                targetPos = hrp.Position + Vector3.new(math.cos(angle) * settings.width, settings.height, math.sin(angle) * settings.width)
                o.SyncForce.Velocity = (targetPos - o.Position) * 25
            elseif mode == "MagicCircle" then
                local res = 0.15
                local x = math.sign(math.cos(angle)) * math.pow(math.abs(math.cos(angle)), res) * (settings.width/2)
                local z = math.sign(math.sin(angle)) * math.pow(math.abs(math.sin(angle)), res) * (settings.width/2)
                targetPos = hrp.Position + Vector3.new(x, settings.height, z)
                o.SyncForce.Velocity = (targetPos - o.Position) * 25
            elseif mode == "Ghost" then
                local t = timeCounter + data.seed
                targetPos = hrp.Position + Vector3.new(math.sin(t * 0.7) * settings.width, math.cos(t * 0.5) * (settings.width * 0.5) + settings.height, math.sin(t * 0.3) * settings.width)
                o.SyncForce.Velocity = (targetPos - o.Position) * 25
            elseif mode == "Manji" then
                local b = (i - 1) % 4
                local a = (b * math.pi / 2) + (timeCounter * 1.5)
                local sIdx = math.floor((i - 1) / 4)
                local r = math.min(1, sIdx / (math.max(1, totalParts/4) * 0.6 + 0.1))
                targetPos = hrp.Position + Vector3.new(math.cos(a) * (r * settings.width), settings.height, math.sin(a) * (r * settings.width))
                o.SyncForce.Velocity = (targetPos - o.Position) * 25
            elseif mode == "Divine" then
                local a = (i / totalParts) * math.pi * 2 + (timeCounter * 0.5)
                targetPos = hrp.Position + Vector3.new(math.cos(a) * settings.width, settings.height + math.sin(timeCounter + i), math.sin(a) * settings.width)
                o.SyncForce.Velocity = (targetPos - o.Position) * 25
            elseif mode == "Geometry" then
                local n = 12 
                local sA = timeCounter * 1.5 + data.phase
                local lA = ((i - 1) % n / n) * math.pi * 2 + (timeCounter * 0.2)
                targetPos = hrp.Position + Vector3.new(math.cos(lA) * settings.width + math.cos(sA) * 5, settings.height, math.sin(lA) * settings.width + math.sin(sA) * 5)
                o.SyncForce.Velocity = (targetPos - o.Position) * 25
            end

            if targetPos then
                o.SyncGyro.CFrame = CFrame.new(o.Position, hrp.Position)
                if math.random() > 0.98 then pcall(function() o:SetNetworkOwner(LP) end) end
            end
        end
    end
end)

local function setupCharacter(char)
    char:WaitForChild("HumanoidRootPart")
    for _, v in ipairs(char:GetChildren()) do
        if v:IsA("BasePart") then
            v.Touched:Connect(function(hit) 
                if mode ~= "None" or presentEnabled or monoAllEnabled then registerPart(hit) end 
            end)
        end
    end
end
for _, p in ipairs(Players:GetPlayers()) do if p.Character then setupCharacter(p.Character) end p.CharacterAdded:Connect(setupCharacter) end

-- ===== ★★★ ノーブロブキックオール（追加） ★★★ =====
local KingTab = Window:MakeTab({
	Name = "ノーブロブキックオール",
	Icon = "rbxassetid://4483345998",
	PremiumOnly = false
})

KingTab:AddSection({Name = "ノーブロブキックオール"})

local selectedHeight = "Spawn"

-- 関数定義
local function getAllPlayers()
	local players = {}
	for _, plr in pairs(Players:GetPlayers()) do
		if plr ~= LP then table.insert(players, plr) end
	end
	return players
end

local GrabEvents = ReplicatedStorage:FindFirstChild("GrabEvents")

local function spamOwnership(hrp)
	if not GrabEvents then return end
	local setOwner = GrabEvents:FindFirstChild("SetNetworkOwner")
	if setOwner and hrp then pcall(function() setOwner:FireServer(hrp, hrp.CFrame) end) end
end

local function teleportToPlayer(myHrp, targetHrp)
	if not myHrp or not targetHrp then return end
	pcall(function()
		myHrp.CFrame = targetHrp.CFrame * CFrame.new(0, 5, 5)
		myHrp.AssemblyLinearVelocity = Vector3.zero
	end)
end

local function destroyLineOnPlayer(hrp)
	if not GrabEvents then return end
	local createLine = GrabEvents:FindFirstChild("CreateGrabLine")
	local destroyLine = GrabEvents:FindFirstChild("DestroyGrabLine")
	if not createLine or not destroyLine then return end
	pcall(function()
		createLine:FireServer(hrp, CFrame.new(0, 1e9, 0))
		task.wait()
		destroyLine:FireServer(hrp)
	end)
end

-- ラインラグ制御
local lineLagThread = nil
local lineLagEnabled = false

local function startLineLag()
	if lineLagEnabled then return end
	lineLagEnabled = true
	lineLagThread = coroutine.create(function()
		if not GrabEvents then return end
		local createLine = GrabEvents:FindFirstChild("CreateGrabLine")
		if not createLine then return end
		while lineLagEnabled do
			local spawnLocation = Workspace:FindFirstChild("SpawnLocation") or Workspace:FindFirstChild("Spawn") or (LP.Character and LP.Character:FindFirstChild("HumanoidRootPart"))
			if spawnLocation then
				local randomX = math.random(-1e9, 1e9)
				local randomZ = math.random(-1e9, 1e9)
				local directions = {CFrame.new(randomX, 0, randomZ), CFrame.new(-randomX, 0, -randomZ), CFrame.new(randomX, 0, -randomZ), CFrame.new(-randomX, 0, randomZ)}
				for _, pos in pairs(directions) do createLine:FireServer(spawnLocation, pos) end
			end
			task.wait()
		end
	end)
	coroutine.resume(lineLagThread)
end

local function stopLineLag()
	lineLagEnabled = false
	if lineLagThread then coroutine.close(lineLagThread); lineLagThread = nil end
end

-- UI部品（OrionLib）
KingTab:AddDropdown({
	Name = "破壊の高さモード",
	Default = "Spawn (地上)",
	Options = {"Spawn (地上)", "Heaven (天国)"},
	Callback = function(Value)
		selectedHeight = (Value == "Heaven (天国)") and "Heaven" or "Spawn"
	end
})

KingTab:AddButton({
	Name = "🚀 キックオール実行",
	Callback = function()
		task.spawn(function()
			local height = (selectedHeight == "Heaven") and 1e9 or 35
			startLineLag()
			task.wait(1)

			local players = getAllPlayers()
			if #players == 0 then
				stopLineLag()
				OrionLib:MakeNotification({Name = "ノーブロブキックオール", Content = "対象プレイヤーがいません", Image = "rbxassetid://4483345998", Time = 3})
				return
			end

			local myChar = LP.Character
			local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
			if not myHrp then stopLineLag(); return end

			local playerData = {}
			for _, plr in ipairs(players) do
				local char = plr.Character
				local hrp = char and char:FindFirstChild("HumanoidRootPart")
				if hrp then table.insert(playerData, {player = plr, hrp = hrp}) end
			end

			for _, data in ipairs(playerData) do
				teleportToPlayer(myHrp, data.hrp)
				task.wait(0.2)
				spamOwnership(data.hrp)
				task.wait()
			end

			local radius = 40
			local angleStep = (math.pi * 2) / #playerData
			for idx, data in ipairs(playerData) do
				local angle = (idx - 1) * angleStep
				local x = math.cos(angle) * radius
				local z = math.sin(angle) * radius

				pcall(function()
					data.hrp.CFrame = CFrame.new(x, height, z)
					data.hrp.AssemblyLinearVelocity = Vector3.zero
				end)

				local bp = Instance.new("BodyPosition")
				bp.MaxForce = Vector3.new(1e9, 1e9, 1e9)
				bp.P = 40000000
				bp.Position = Vector3.new(x, height, z)
				bp.Parent = data.hrp
				task.delay(2, function() pcall(function() bp:Destroy() end) end)
				task.wait()
			end

			for i = 1, 8 do
				for _, data in ipairs(playerData) do destroyLineOnPlayer(data.hrp) end
				task.wait(0.3)
			end
			
			OrionLib:MakeNotification({Name = "ノーブロブキックオール", Content = "キックオール完了！ラグは継続中です。", Image = "rbxassetid://4483345998", Time = 2})
		end)
	end
})

KingTab:AddButton({
	Name = "⏹ ラグ停止",
	Callback = function()
		stopLineLag()
		OrionLib:MakeNotification({Name = "ノーブロブキックオール", Content = "ラグ処理を停止しました", Image = "rbxassetid://4483345998", Time = 2})
	end
})

-- ===== ★★★ ドリフトキック（追加） ★★★ =====
local OrbitTab = Window:MakeTab({
    Name = "ドリフトキック",
    Icon = "rbxassetid://4483345998"
})

-- 変数宣言
local orbitRunning = false
local selectedActionTargetName = ""
local orbitRadius = 19
local orbitSpeed = 8.5
local orbitHeightOffset = 0
local orbitAngle = 0
local orbitCurrentLoopId = 0
local orbitPlayerMap = {}

-- プレイヤー名取得関数
local function getOrbitPlayerNames()
    local names = {}
    orbitPlayerMap = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LP then
            local displayStr = player.DisplayName .. " (@" .. player.Name .. ")"
            table.insert(names, displayStr)
            orbitPlayerMap[displayStr] = player.Name
        end
    end
    return names
end

-- ドロップダウンメニュー
local OrbitTargetDropdown = OrbitTab:AddDropdown({
    Name = "ターゲットを選択",
    Default = "",
    Options = getOrbitPlayerNames(),
    Callback = function(Value)
        selectedActionTargetName = orbitPlayerMap[Value] or ""
    end
})

-- プレイヤーリスト更新ボタン
OrbitTab:AddButton({
    Name = "プレイヤーリストを更新",
    Callback = function()
        OrbitTargetDropdown:Refresh(getOrbitPlayerNames(), true)
    end
})

-- Orbit半径設定スライダー
OrbitTab:AddSlider({
    Name = "Orbit半径",
    Min = 5,
    Max = 50,
    Default = 19,
    Increment = 1,
    Callback = function(Value)
        orbitRadius = Value
    end
})

-- Orbit速度設定スライダー
OrbitTab:AddSlider({
    Name = "Orbit速度",
    Min = 1,
    Max = 20,
    Default = 8.5,
    Increment = 0.5,
    Callback = function(Value)
        orbitSpeed = Value
    end
})

-- 高度オフセット設定スライダー
OrbitTab:AddSlider({
    Name = "高度オフセット",
    Min = -10,
    Max = 10,
    Default = 0,
    Increment = 1,
    Callback = function(Value)
        orbitHeightOffset = Value
    end
})

-- メイントグル
OrbitTab:AddToggle({
    Name = "ドリフトキック",
    Default = false,
    Callback = function(v)
        orbitRunning = v
        orbitCurrentLoopId = orbitCurrentLoopId + 1
        local myLoopId = orbitCurrentLoopId

        if not v then return end

        local target = Players:FindFirstChild(selectedActionTargetName)
        
        if target and target ~= LP and target.Character and target.Character:FindFirstChild("HumanoidRootPart") and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
            local blobman = nil
            local spawned = Workspace:FindFirstChild(LP.Name .. "SpawnedInToys")
            if spawned then blobman = spawned:FindFirstChild("CreatureBlobman") end
            
            if not blobman then
                local mt = ReplicatedStorage:FindFirstChild("MenuToys")
                local st = mt and mt:FindFirstChild("SpawnToyRemoteFunction")
                if st then
                    local myRoot = LP.Character.HumanoidRootPart
                    local spawnCF = myRoot and (myRoot.CFrame + Vector3.new(0, 5, 0)) or CFrame.new(0, 50, 0)
                    st:InvokeServer("CreatureBlobman", spawnCF, Vector3.zero)
                    task.wait(0.8)
                    spawned = Workspace:FindFirstChild(LP.Name .. "SpawnedInToys")
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
                local hum = LP.Character:FindFirstChild("Humanoid")
                
                if seat and hum then
                    if seat.Occupant ~= hum then
                        LP.Character.HumanoidRootPart.CFrame = seat.CFrame + Vector3.new(0, 2, 0)
                        task.wait(0.2)
                        seat:Sit(hum)
                        task.wait(0.5)
                    end
                end
                
                local GE = ReplicatedStorage:FindFirstChild("GrabEvents")
                
                if GE and grabRemote and dropRemote and ((lDet and lWeld) or (rDet and rWeld)) then
                    OrionLib:MakeNotification({
                        Name = "実行",
                        Content = "ドリフトキックを開始します",
                        Time = 3
                    })

                    task.spawn(function()
                        local blobRoot = blobman:FindFirstChild("HumanoidRootPart") or blobman.PrimaryPart
                        local Det = rDet or lDet
                        local Weld = rWeld or lWeld
                        
                        local bringStart = tick()
                        while tick() - bringStart < 0.35 do
                            if myLoopId ~= orbitCurrentLoopId or not orbitRunning or not blobman or not blobman.Parent then return end
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
                        
                        if not target.Character or not target.Character:FindFirstChild("HumanoidRootPart") then return end
                        
                        local SavedPos = target.Character.HumanoidRootPart.CFrame
                        local targetCenterCFrame = SavedPos + Vector3.new(0, 30, 0)
                        
                        local lastTime = tick()
                        local lastDropTime = tick()
                        local dropCount = 0
                        
                        while orbitRunning and blobman and blobman.Parent do
                            if myLoopId ~= orbitCurrentLoopId then break end
                            if not target or not target.Parent or not target.Character then break end
                            
                            local tChar = target.Character
                            local tRoot = tChar:FindFirstChild("HumanoidRootPart")
                            local tHum = tChar:FindFirstChild("Humanoid")
                            
                            if dropCount < 2 and (tick() - lastDropTime) > 0.8 then
                                dropCount = dropCount + 1
                                
                                pcall(function()
                                    local currentWeld = Det:FindFirstChild("RightWeld") or Det:FindFirstChild("LeftWeld") or Det:FindFirstChildWhichIsA("Weld") or Det:FindFirstChild("RigidConstraint")
                                    if currentWeld then
                                        dropRemote:FireServer(currentWeld)
                                    end
                                    GE.DestroyGrabLine:FireServer(tRoot)
                                end)
                                
                                blobRoot.CFrame = SavedPos
                                blobRoot.AssemblyLinearVelocity = Vector3.zero
                                
                                task.wait(0.1)
                                
                                local reCaptureStart = tick()
                                while tick() - reCaptureStart < 0.35 do
                                    if myLoopId ~= orbitCurrentLoopId or not orbitRunning or not blobman or not blobman.Parent then break end
                                    if target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                                        local currentTRoot = target.Character.HumanoidRootPart
                                        blobRoot.CFrame = currentTRoot.CFrame
                                        blobRoot.AssemblyLinearVelocity = Vector3.zero
                                        
                                        pcall(function()
                                            if Det then grabRemote:FireServer(Det, currentTRoot, Weld) end
                                            GE.CreateGrabLine:FireServer(currentTRoot, Vector3.zero, currentTRoot.Position, false)
                                            GE.SetNetworkOwner:FireServer(currentTRoot, blobRoot.CFrame)
                                        end)
                                    end
                                    RunService.Heartbeat:Wait()
                                end
                                
                                lastTime = tick()
                                lastDropTime = tick()
                            end

                            if tRoot and tHum and tHum.Health > 0 and blobRoot then
                                local currentTime = tick()
                                local dt = currentTime - lastTime
                                lastTime = currentTime

                                orbitAngle = orbitAngle + (orbitSpeed * dt)
                                local offsetX = math.cos(orbitAngle) * orbitRadius
                                local offsetZ = math.sin(orbitAngle) * orbitRadius
                                
                                local blobPos = targetCenterCFrame.Position + Vector3.new(offsetX, orbitHeightOffset, offsetZ)
                                blobRoot.CFrame = CFrame.new(blobPos, targetCenterCFrame.Position)
                                blobRoot.AssemblyLinearVelocity = Vector3.zero
                                blobRoot.AssemblyAngularVelocity = Vector3.zero
                                
                                tRoot.CFrame = targetCenterCFrame
                                tRoot.AssemblyLinearVelocity = Vector3.zero
                                tRoot.AssemblyAngularVelocity = Vector3.zero

                                pcall(function()
                                    tHum.PlatformStand = true
                                    tHum.Sit = true
                                    GE.SetNetworkOwner:FireServer(tRoot, targetCenterCFrame)
                                    
                                    local currentWeld = Det:FindFirstChild("RightWeld") or Det:FindFirstChild("LeftWeld") or Det:FindFirstChildWhichIsA("Weld") or Det:FindFirstChild("RigidConstraint")
                                    if currentWeld then
                                        dropRemote:FireServer(currentWeld)
                                    end
                                    
                                    GE.DestroyGrabLine:FireServer(tRoot)
                                    if Det then grabRemote:FireServer(Det, tRoot, Weld) end
                                    GE.CreateGrabLine:FireServer(tRoot, Vector3.zero, targetCenterCFrame.Position, false)
                                end)
                            else
                                break
                            end
                            RunService.Heartbeat:Wait()
                        end
                        
                        if blobRoot and SavedPos then
                            pcall(function()
                                local currentWeld = Det:FindFirstChild("RightWeld") or Det:FindFirstChild("LeftWeld") or Det:FindFirstChildWhichIsA("Weld") or Det:FindFirstChild("RigidConstraint")
                                if currentWeld then dropRemote:FireServer(currentWeld) end
                                if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                                    GE.DestroyGrabLine:FireServer(target.Character.HumanoidRootPart)
                                end
                            end)
                            blobRoot.CFrame = SavedPos
                            blobRoot.AssemblyLinearVelocity = Vector3.zero
                        end
                    end)
                else
                    OrionLib:MakeNotification({
                        Name = "エラー",
                        Content = "必要なRemoteEventやDetectorが見つかりません",
                        Time = 5
                    })
                    orbitRunning = false
                end
            else
                OrionLib:MakeNotification({
                    Name = "エラー",
                    Content = "Blobmanの取得・生成に失敗しました",
                    Time = 3
                })
                orbitRunning = false
            end
        else
            OrionLib:MakeNotification({
                Name = "エラー",
                Content = "ターゲットが無効です",
                Time = 3
            })
            orbitRunning = false
        end
    end
})
