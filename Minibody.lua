-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

-- Animation IDs
local IDLE_ID = "rbxassetid://83918901718686"
local PANIC_ID = "rbxassetid://131462725467743"
local RUN_ID = "rbxassetid://85887415033585"
local SIT_ID = "rbxassetid://114302219876492"

-- Variables
local character, humanoid, animator
local idleTrack, panicTrack, runTrack, sitTrack

local isStarted = false
local isDragEnabled = false
local isPanicking = false
local isSitting = false

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MiniBodyGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

---------------------------------------------------------
-- 1. START FRAME (Cầu vồng giữa màn hình)
---------------------------------------------------------
local startFrame = Instance.new("Frame")
startFrame.Name = "StartFrame"
startFrame.Size = UDim2.new(0, 300, 0, 150)
startFrame.Position = UDim2.new(0.5, -150, 0.5, -75)
startFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
startFrame.BorderSizePixel = 0
startFrame.Parent = screenGui

local startCorner = Instance.new("UICorner")
startCorner.CornerRadius = UDim.new(0, 12)
startCorner.Parent = startFrame

-- Title Rainbow
local titleText = Instance.new("TextLabel")
titleText.Name = "Title"
titleText.Size = UDim2.new(1, 0, 0, 50)
titleText.Position = UDim2.new(0, 0, 0, 10)
titleText.BackgroundTransparency = 1
titleText.Text = "Mini Body by KageFloppey"
titleText.Font = Enum.Font.GothamBold
titleText.TextSize = 18
titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
titleText.Parent = startFrame

-- Rainbow Effect cho Title
task.spawn(function()
	local hue = 0
	while task.wait(0.03) do
		hue = (hue + 0.01) % 1
		titleText.TextColor3 = Color3.fromHSV(hue, 0.8, 1)
	end
end)

-- Start Button
local startBtn = Instance.new("TextButton")
startBtn.Name = "StartBtn"
startBtn.Size = UDim2.new(0, 160, 0, 45)
startBtn.Position = UDim2.new(0.5, -80, 1, -55)
startBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
startBtn.Text = "START"
startBtn.Font = Enum.Font.GothamBold
startBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
startBtn.TextSize = 16
startBtn.Parent = startFrame

local startBtnCorner = Instance.new("UICorner")
startBtnCorner.CornerRadius = UDim.new(0, 8)
startBtnCorner.Parent = startBtn

---------------------------------------------------------
-- 2. MAIN CONTROL BUTTONS (Đã thu nhỏ & độc lập)
---------------------------------------------------------
-- Hàm tạo Button thu nhỏ
local function createButton(name, text, defaultPos)
	local btn = Instance.new("TextButton")
	btn.Name = name
	btn.Size = UDim2.new(0, 135, 0, 36) -- Đã thu nhỏ kích thước (135x36)
	btn.Position = defaultPos
	btn.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
	btn.Text = text
	btn.Font = Enum.Font.GothamBold
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.TextSize = 16 -- Cỡ chữ vừa vặn hơn
	btn.Active = true
	btn.Visible = false
	btn.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = btn

	return btn
end

-- Khởi tạo 3 nút ở vị trí giữa màn hình lúc đầu
local dragBtn = createButton("DragBtn", "drag: off", UDim2.new(0.5, -67, 0.5, -45))
local panicBtn = createButton("PanicBtn", "panic", UDim2.new(0.5, -67, 0.5, -3))
local sitBtn = createButton("SitBtn", "sit", UDim2.new(0.5, -67, 0.5, 39))

---------------------------------------------------------
-- 3. ANIMATION & CHARACTER SYSTEM
---------------------------------------------------------
local function loadAnimations()
	character = player.Character or player.CharacterAdded:Wait()
	humanoid = character:WaitForChild("Humanoid")
	animator = humanoid:WaitForChild("Animator")

	local idleAnim = Instance.new("Animation")
	idleAnim.AnimationId = IDLE_ID
	idleTrack = animator:LoadAnimation(idleAnim)
	idleTrack.Priority = Enum.AnimationPriority.Movement

	local panicAnim = Instance.new("Animation")
	panicAnim.AnimationId = PANIC_ID
	panicTrack = animator:LoadAnimation(panicAnim)
	panicTrack.Priority = Enum.AnimationPriority.Action

	local runAnim = Instance.new("Animation")
	runAnim.AnimationId = RUN_ID
	runTrack = animator:LoadAnimation(runAnim)
	runTrack.Priority = Enum.AnimationPriority.Movement

	local sitAnim = Instance.new("Animation")
	sitAnim.AnimationId = SIT_ID
	sitTrack = animator:LoadAnimation(sitAnim)
	sitTrack.Priority = Enum.AnimationPriority.Action
end

-- Tự động dừng Sit khi nhân vật di chuyển
local function setupMovementCheck()
	humanoid:GetPropertyChangedSignal("MoveDirection"):Connect(function()
		if not isStarted then return end
		
		local isMoving = humanoid.MoveDirection.Magnitude > 0
		
		-- Tự động dừng Sit nếu di chuyển
		if isMoving and isSitting then
			isSitting = false
			if sitTrack then sitTrack:Stop() end
		end

		-- Xử lý chuyển đổi Idle / Run khi không bật Panic hoặc Sit
		if not isPanicking and not isSitting then
			if isMoving then
				if idleTrack and idleTrack.IsPlaying then idleTrack:Stop() end
				if runTrack and not runTrack.IsPlaying then runTrack:Play() end
			else
				if runTrack and runTrack.IsPlaying then runTrack:Stop() end
				if idleTrack and not idleTrack.IsPlaying then idleTrack:Play() end
			end
		end
	end)
end

player.CharacterAdded:Connect(function()
	task.wait(0.5)
	loadAnimations()
	setupMovementCheck()
	if isStarted then
		idleTrack:Play()
	end
end)

---------------------------------------------------------
-- 4. BUTTON EVENTS & INDIVIDUAL DRAG SYSTEM
---------------------------------------------------------
-- START Button Click
startBtn.MouseButton1Click:Connect(function()
	isStarted = true
	startFrame.Visible = false
	
	dragBtn.Visible = true
	panicBtn.Visible = true
	sitBtn.Visible = true
	
	loadAnimations()
	setupMovementCheck()
	if idleTrack then idleTrack:Play() end
end)

-- Panic Button
panicBtn.MouseButton1Click:Connect(function()
	if not isStarted or isDragEnabled then return end
	isPanicking = not isPanicking
	
	if isPanicking then
		if isSitting then
			isSitting = false
			if sitTrack then sitTrack:Stop() end
		end
		if idleTrack then idleTrack:Stop() end
		if runTrack then runTrack:Stop() end
		if panicTrack then panicTrack:Play() end
	else
		if panicTrack then panicTrack:Stop() end
		if humanoid.MoveDirection.Magnitude > 0 then
			if runTrack then runTrack:Play() end
		else
			if idleTrack then idleTrack:Play() end
		end
	end
end)

-- Sit Button
sitBtn.MouseButton1Click:Connect(function()
	if not isStarted or isDragEnabled then return end
	isSitting = not isSitting

	if isSitting then
		if isPanicking then
			isPanicking = false
			if panicTrack then panicTrack:Stop() end
		end
		if idleTrack then idleTrack:Stop() end
		if runTrack then runTrack:Stop() end
		if sitTrack then sitTrack:Play() end
	else
		if sitTrack then sitTrack:Stop() end
		if humanoid.MoveDirection.Magnitude > 0 then
			if runTrack then runTrack:Play() end
		else
			if idleTrack then idleTrack:Play() end
		end
	end
end)

-- Toggle Drag Mode
dragBtn.MouseButton1Click:Connect(function()
	isDragEnabled = not isDragEnabled
	dragBtn.Text = isDragEnabled and "drag: on" or "drag: off"
end)

-- Hàm xử lý kéo thả riêng biệt cho từng nút
local function makeDraggable(btn)
	local dragging = false
	local dragStart = Vector3.new()
	local startPos = UDim2.new()

	btn.InputBegan:Connect(function(input)
		if not isDragEnabled then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = btn.Position

			local conn
			conn = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
					if conn then conn:Disconnect() end
				end
			end)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and isDragEnabled and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			btn.Position = UDim2.new(
				startPos.X.Scale, 
				startPos.X.Offset + delta.X, 
				startPos.Y.Scale, 
				startPos.Y.Offset + delta.Y
			)
		end
	end)
end

-- Áp dụng kéo thả độc lập cho từng nút
makeDraggable(dragBtn)
makeDraggable(panicBtn)
makeDraggable(sitBtn)
