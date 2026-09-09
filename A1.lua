--[[
	GrabMoveController.lua (LocalScript, サーバー不使用, 物理演算対応版)
	配置場所: StarterPlayer > StarterPlayerScripts

	・起動時に画面中央へメッセージを2秒間表示
	・「操作」ボタンは常に独立して画面右上に表示される
	・操作をONにすると、隣に「スピード入力」と「飛行」ボタンが横並びで出現する
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera

----------------------------------------------------------------
-- 0. 起動時メッセージの表示 (2秒間)
----------------------------------------------------------------

local startupGui = Instance.new("ScreenGui")
startupGui.Name = "StartupMessageGui"
startupGui.ResetOnSpawn = false
startupGui.Parent = playerGui

local messageLabel = Instance.new("TextLabel")
messageLabel.Size = UDim2.new(0, 450, 0, 70)
messageLabel.AnchorPoint = Vector2.new(0.5, 0.5)
messageLabel.Position = UDim2.new(0.5, 0, 0.4, 0)
messageLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
messageLabel.BackgroundTransparency = 0.2
messageLabel.Text = "このスクリプトは解読化を実施しません！"
messageLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
messageLabel.Font = Enum.Font.GothamBold
messageLabel.TextSize = 18

local msgCorner = Instance.new("UICorner")
msgCorner.CornerRadius = UDim.new(0, 10)
msgCorner.Parent = messageLabel
messageLabel.Parent = startupGui

task.delay(2, function()
	if startupGui then
		startupGui:Destroy()
	end
end)

----------------------------------------------------------------
-- 1. 状態管理
----------------------------------------------------------------

local controlling = false
local flying = false
local currentRoot = nil
local mover = nil

local RAY_DISTANCE = 60

-- 統合されたスピード設定の変数
local CURRENT_SPEED = 20

-- 三人称カメラのパラメータ
local CAMERA_DISTANCE = 20
local cameraYaw = 0          -- 目標ヨー角
local cameraPitch = -20      -- 目標ピッチ角
local currentYaw = 0         -- 現在のヨー角
local currentPitch = -20     -- 現在のピッチ角
local CAMERA_SMOOTHNESS = 30 -- キビキビ追従

local CAMERA_SENSITIVITY = 1.0 -- 感度1.00固定

-- プレイヤーを固定する指定座標 ＆ 元の位置を記憶する変数
local PLAYER_FIXED_POSITION = Vector3.new(460.4, 131.4, 202.7)
local savedPlayerCFrame = nil

----------------------------------------------------------------
-- 2. 画面中央のパーツを探す(レイキャスト)
----------------------------------------------------------------

local function findCenterTarget()
	local cam = workspace.CurrentCamera
	if not cam then return nil end

	local origin = cam.CFrame.Position
	local direction = cam.CFrame.LookVector * RAY_DISTANCE

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { player.Character }
	params.IgnoreWater = true

	local result = workspace:Raycast(origin, direction, params)
	if not result then return nil end

	local part = result.Instance
	if not part or not part:IsA("BasePart") then return nil end
	if part.Anchored then return nil end

	return part
end

----------------------------------------------------------------
-- 3. 三人称カメラの更新
----------------------------------------------------------------

local function updateThirdPersonCamera(dt)
	if not currentRoot then return end

	currentYaw = currentYaw + (cameraYaw - currentYaw) * math.clamp(dt * CAMERA_SMOOTHNESS, 0, 1)
	currentPitch = currentPitch + (cameraPitch - currentPitch) * math.clamp(dt * CAMERA_SMOOTHNESS, 0, 1)

	local yawRad = math.rad(currentYaw)
	local pitchRad = math.rad(currentPitch)

	local offset = Vector3.new(
		math.cos(pitchRad) * math.sin(yawRad),
		math.sin(pitchRad),
		math.cos(pitchRad) * math.cos(yawRad)
	) * CAMERA_DISTANCE

	local targetPos = currentRoot.Position
	camera.CFrame = CFrame.lookAt(targetPos + offset, targetPos)
end

----------------------------------------------------------------
-- 4. 操作の開始・終了(BodyVelocity + カメラ切り替え)
----------------------------------------------------------------

local MAX_FORCE = 100000

local function destroyMover()
	if mover then
		mover:Destroy()
		mover = nil
	end
end

-- 標準ジャンプボタンの表示/非表示を切り替える関数
local function setRobloxJumpButtonVisible(visible)
	pcall(function()
		local touchGui = playerGui:FindFirstChild("TouchGui")
		if touchGui then
			local touchControlFrame = touchGui:FindFirstChild("TouchControlFrame")
			if touchControlFrame then
				local jumpButton = touchControlFrame:FindFirstChild("JumpButton")
				if jumpButton then
					jumpButton.Visible = visible
				end
			end
		end
	end)
end

local function startControl()
	local target = findCenterTarget()
	if not target then return false end

	currentRoot = target.AssemblyRootPart or target

	local char = player.Character
	if char then
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if hrp then
			savedPlayerCFrame = hrp.CFrame
			hrp.CFrame = CFrame.new(PLAYER_FIXED_POSITION)
			hrp.AssemblyLinearVelocity = Vector3.zero
			hrp.AssemblyAngularVelocity = Vector3.zero
		end
	end

	destroyMover()
	mover = Instance.new("BodyVelocity")
	mover.Name = "GrabMoveVelocity"
	mover.MaxForce = Vector3.new(MAX_FORCE, MAX_FORCE, MAX_FORCE)
	mover.P = 12500
	mover.Velocity = Vector3.zero
	mover.Parent = currentRoot

	cameraYaw = 0
	cameraPitch = -20
	currentYaw = 0
	currentPitch = -20

	camera.CameraType = Enum.CameraType.Scriptable
	updateThirdPersonCamera(0)

	controlling = true
	setRobloxJumpButtonVisible(false)
	return true
end

local function stopControl()
	destroyMover()
	
	if savedPlayerCFrame then
		local char = player.Character
		if char then
			local hrp = char:FindFirstChild("HumanoidRootPart")
			if hrp then
				hrp.CFrame = savedPlayerCFrame
				hrp.AssemblyLinearVelocity = Vector3.zero
				hrp.AssemblyAngularVelocity = Vector3.zero
			end
		end
		savedPlayerCFrame = nil
	end

	controlling = false
	flying = false
	currentRoot = nil

	camera.CameraType = Enum.CameraType.Custom
	setRobloxJumpButtonVisible(true)
end

----------------------------------------------------------------
-- 5. GUI構築 (独立した操作ボタン ＋ 横並びコンテナ)
----------------------------------------------------------------

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GrabMoveGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local crosshair = Instance.new("Frame")
crosshair.Size = UDim2.new(0, 8, 0, 8)
crosshair.AnchorPoint = Vector2.new(0.5, 0.5)
crosshair.Position = UDim2.new(0.5, 0, 0.5, 0)
crosshair.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
crosshair.BackgroundTransparency = 0.3
local crosshairCorner = Instance.new("UICorner")
crosshairCorner.CornerRadius = UDim.new(1, 0)
crosshairCorner.Parent = crosshair
crosshair.Parent = screenGui

-- 1. 操作トグルボタン (常に画面右上に単体で表示)
local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0, 110, 0, 40)
toggleButton.Position = UDim2.new(1, -130, 0, 20)
toggleButton.Text = "操作: OFF"
toggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.Font = Enum.Font.GothamBold
toggleButton.TextSize = 15
local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 8)
btnCorner.Parent = toggleButton
toggleButton.Parent = screenGui

-- 操作ONのときだけ出現する、スピードと飛行ボタンの横並びコンテナ（操作ボタンの左側に配置）
local subButtonContainer = Instance.new("Frame")
subButtonContainer.Size = UDim2.new(0, 200, 0, 40)
subButtonContainer.Position = UDim2.new(1, -345, 0, 20)
subButtonContainer.BackgroundTransparency = 1
subButtonContainer.Visible = false
subButtonContainer.Parent = screenGui

local listLayout = Instance.new("UIListLayout")
listLayout.FillDirection = Enum.FillDirection.Horizontal
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
listLayout.VerticalAlignment = Enum.VerticalAlignment.Center
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 10)
listLayout.Parent = subButtonContainer

-- 2. 統合スピード入力ボックス
local speedBox = Instance.new("TextBox")
speedBox.Size = UDim2.new(0, 80, 0, 40)
speedBox.Text = tostring(CURRENT_SPEED)
speedBox.PlaceholderText = "速度"
speedBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
speedBox.TextColor3 = Color3.fromRGB(255, 255, 255)
speedBox.Font = Enum.Font.GothamBold
speedBox.TextSize = 14
speedBox.ClearTextOnFocus = false
speedBox.LayoutOrder = 1
local sBoxCorner = Instance.new("UICorner")
sBoxCorner.CornerRadius = UDim.new(0, 8)
sBoxCorner.Parent = speedBox
speedBox.Parent = subButtonContainer

-- スピード入力の反映処理
speedBox.FocusLost:Connect(function()
	local val = tonumber(speedBox.Text)
	if val then
		CURRENT_SPEED = math.clamp(val, 1, 300)
		speedBox.Text = tostring(CURRENT_SPEED)
	else
		speedBox.Text = tostring(CURRENT_SPEED)
	end
end)

-- 3. 飛行ボタン
local flyButton = Instance.new("TextButton")
flyButton.Size = UDim2.new(0, 100, 0, 40)
flyButton.Text = "飛行: OFF"
flyButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
flyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
flyButton.Font = Enum.Font.GothamBold
flyButton.TextSize = 15
flyButton.LayoutOrder = 2
local flyCorner = Instance.new("UICorner")
flyCorner.CornerRadius = UDim.new(0, 8)
flyCorner.Parent = flyButton
flyButton.Parent = subButtonContainer

-- 移動スティック（サイズ90x90）
local stickBase = Instance.new("Frame")
stickBase.Size = UDim2.new(0, 90, 0, 90)
stickBase.Position = UDim2.new(0, 40, 1, -150)
stickBase.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
stickBase.BackgroundTransparency = 0.4
stickBase.Visible = false
local baseCorner = Instance.new("UICorner")
baseCorner.CornerRadius = UDim.new(1, 0)
baseCorner.Parent = stickBase
stickBase.Parent = screenGui

local stickKnob = Instance.new("Frame")
stickKnob.Size = UDim2.new(0, 40, 0, 40)
stickKnob.Position = UDim2.new(0.5, -20, 0.5, -20)
stickKnob.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
local knobCorner = Instance.new("UICorner")
knobCorner.CornerRadius = UDim.new(1, 0)
knobCorner.Parent = stickKnob
stickKnob.Parent = stickBase

-- 操作用ジャンプボタン（画面右下に配置）
local jumpButton = Instance.new("TextButton")
jumpButton.Size = UDim2.new(0, 100, 0, 100)
jumpButton.Position = UDim2.new(1, -120, 1, -140)
jumpButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
jumpButton.BackgroundTransparency = 0.4
jumpButton.Text = "JUMP"
jumpButton.TextColor3 = Color3.fromRGB(255, 255, 255)
jumpButton.Font = Enum.Font.GothamBold
jumpButton.TextSize = 20
jumpButton.Visible = false
local jumpCorner = Instance.new("UICorner")
jumpCorner.CornerRadius = UDim.new(1, 0)
jumpCorner.Parent = jumpButton
jumpButton.Parent = screenGui

local stickRadius = 45
local stickCenter = Vector2.new(45, 45)
local stickInput = Vector2.new(0, 0)
local activeStickTouch = nil

local function updateKnob(delta)
	local clamped = delta
	if clamped.Magnitude > stickRadius then
		clamped = clamped.Unit * stickRadius
	end
	stickKnob.Position = UDim2.new(0.5, clamped.X - 20, 0.5, clamped.Y - 20)
	stickInput = Vector2.new(clamped.X / stickRadius, clamped.Y / stickRadius)
end

local function resetKnob()
	stickKnob.Position = UDim2.new(0.5, -20, 0.5, -20)
	stickInput = Vector2.new(0, 0)
end

stickBase.InputBegan:Connect(function(input)
	if not controlling then return end
	if input.UserInputType == Enum.UserInputType.Touch
		or input.UserInputType == Enum.UserInputType.MouseButton1 then
		activeStickTouch = input
		local pos = input.Position
		local basePos = stickBase.AbsolutePosition
		updateKnob(Vector2.new(pos.X, pos.Y) - basePos - stickCenter)
	end
end)

----------------------------------------------------------------
-- 6. 画面右半分のドラッグでカメラを回転
----------------------------------------------------------------

local activeCameraTouch = nil
local lastCameraTouchPos = nil

local MIN_PITCH = -80
local MAX_PITCH = 80

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if not controlling then return end
	if gameProcessed then return end
	if input.UserInputType ~= Enum.UserInputType.Touch
		and input.UserInputType ~= Enum.UserInputType.MouseButton1 then
		return
	end

	local screenWidth = camera.ViewportSize.X
	if input.Position.X < screenWidth * 0.5 then
		return
	end

	activeCameraTouch = input
	lastCameraTouchPos = Vector2.new(input.Position.X, input.Position.Y)
end)

UserInputService.InputChanged:Connect(function(input)
	if not controlling then return end

	if activeStickTouch == input
		and (input.UserInputType == Enum.UserInputType.Touch
			or input.UserInputType == Enum.UserInputType.MouseMovement) then
		local pos = input.Position
		local basePos = stickBase.AbsolutePosition
		updateKnob(Vector2.new(pos.X, pos.Y) - basePos - stickCenter)
	end

	if activeCameraTouch == input
		and (input.UserInputType == Enum.UserInputType.Touch
			or input.UserInputType == Enum.UserInputType.MouseMovement) then
		local pos = Vector2.new(input.Position.X, input.Position.Y)
		local delta = pos - lastCameraTouchPos
		lastCameraTouchPos = pos

		cameraYaw = cameraYaw - delta.X * CAMERA_SENSITIVITY
		cameraPitch = math.clamp(cameraPitch + delta.Y * CAMERA_SENSITIVITY, MIN_PITCH, MAX_PITCH)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if activeStickTouch == input then
		activeStickTouch = nil
		resetKnob()
	end
	if activeCameraTouch == input then
		activeCameraTouch = nil
		lastCameraTouchPos = nil
	end
end)

----------------------------------------------------------------
-- 7. ジャンプの検知 (Spaceキー または 専用ジャンプボタン)
----------------------------------------------------------------

local isJumpRequested = false

ContextActionService:BindAction("GrabMoveJumpKey", function(actionName, inputState, inputObject)
	if not controlling then return Enum.ContextActionResult.Pass end
	
	if inputState == Enum.UserInputState.Begin then
		isJumpRequested = true
	elseif inputState == Enum.UserInputState.End then
		isJumpRequested = false
	end
	return Enum.ContextActionResult.Sink
end, false, Enum.KeyCode.Space)

jumpButton.InputBegan:Connect(function(input)
	if not controlling then return end
	if input.UserInputType == Enum.UserInputType.Touch
		or input.UserInputType == Enum.UserInputType.MouseButton1 then
		isJumpRequested = true
		jumpButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
	end
end)

jumpButton.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch
		or input.UserInputType == Enum.UserInputType.MouseButton1 then
		isJumpRequested = false
		jumpButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	end
end)

local function getPlayerJumpPower()
	local char = player.Character
	if not char then return 50 end
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if humanoid then
		return humanoid.JumpPower
	end
	return 50
end

local function isGrounded(part)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { player.Character, part }
	
	local result = workspace:Raycast(part.Position, Vector3.new(0, -(part.Size.Y * 0.5 + 0.6), 0), params)
	return result ~= nil
end

----------------------------------------------------------------
-- 8. トグルボタン & 飛行ボタン
----------------------------------------------------------------

toggleButton.MouseButton1Click:Connect(function()
	if not controlling then
		local ok = startControl()
		if ok then
			toggleButton.Text = "操作: ON"
			subButtonContainer.Visible = true
			stickBase.Visible = true
			jumpButton.Visible = true
		else
			toggleButton.Text = "対象なし"
			task.wait(1)
			toggleButton.Text = "操作: OFF"
		end
	else
		stopControl()
		toggleButton.Text = "操作: OFF"
		flyButton.Text = "飛行: OFF"
		subButtonContainer.Visible = false
		stickBase.Visible = false
		jumpButton.Visible = false
		resetKnob()
	end
end)

flyButton.MouseButton1Click:Connect(function()
	if not controlling then return end
	flying = not flying
	if flying then
		flyButton.Text = "飛行: ON"
		flyButton.BackgroundColor3 = Color3.fromRGB(40, 120, 40)
	else
		flyButton.Text = "飛行: OFF"
		flyButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	end
end)

----------------------------------------------------------------
-- 9. 毎フレーム更新(移動 + 飛行 + ジャンプ + カメラ追従)
----------------------------------------------------------------

RunService.Heartbeat:Connect(function(dt)
	if not controlling or not mover or not currentRoot or not currentRoot.Parent then
		if controlling then
			stopControl()
			toggleButton.Text = "操作: OFF"
			flyButton.Text = "飛行: OFF"
			subButtonContainer.Visible = false
			stickBase.Visible = false
			jumpButton.Visible = false
			resetKnob()
		end
		return
	end

	updateThirdPersonCamera(dt)

	local camCF = camera.CFrame
	local forward = Vector3.new(camCF.LookVector.X, 0, camCF.LookVector.Z)
	if forward.Magnitude > 0 then forward = forward.Unit end
	local right = Vector3.new(camCF.RightVector.X, 0, camCF.RightVector.Z)
	if right.Magnitude > 0 then right = right.Unit end

	local moveDir = (right * stickInput.X) + (forward * -stickInput.Y)
	if moveDir.Magnitude > 1 then
		moveDir = moveDir.Unit
	end

	if flying then
		local lookVec = camCF.LookVector
		local flyDir = (lookVec * -stickInput.Y) + (camCF.RightVector * stickInput.X)
		if flyDir.Magnitude > 1 then
			flyDir = flyDir.Unit
		end
		local targetVel = flyDir * CURRENT_SPEED
		mover.MaxForce = Vector3.new(MAX_FORCE, MAX_FORCE, MAX_FORCE)
		mover.Velocity = targetVel
	else
		local targetVel = moveDir * CURRENT_SPEED
		mover.MaxForce = Vector3.new(MAX_FORCE, 0, MAX_FORCE)
		mover.Velocity = Vector3.new(targetVel.X, 0, targetVel.Z)

		if isJumpRequested and isGrounded(currentRoot) then
			local jumpPower = getPlayerJumpPower()
			local jumpVelocity = math.sqrt(jumpPower * 2) * 2.6
			currentRoot:ApplyImpulse(Vector3.new(0, currentRoot.AssemblyMass * jumpVelocity, 0))
			isJumpRequested = false
		end
	end
end)
