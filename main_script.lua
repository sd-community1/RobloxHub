local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera

local player = Players.LocalPlayer
local guiName = "VNDXS_HUB_SHOOTER"

-- تنظيف النسخ القديمة
if player.PlayerGui:FindFirstChild(guiName) then
	player.PlayerGui[guiName]:Destroy()
end

-- ============================================================================
-- 1. الإعدادات (CONFIG)
-- ============================================================================

local CONFIG = {
	OpenSize = UDim2.new(0.65, 0, 0.65, 0), -- الحجم الطبيعي
	ClosedSize = UDim2.new(0.65, 0, 0, 55), -- حجم التصغير الطبيعي
	
	-- الألوان
	ThemeColor = Color3.fromRGB(10, 10, 10), 
	SidebarColor = Color3.fromRGB(18, 18, 18), 
	AccentColor = Color3.fromRGB(255, 255, 255),
	TextColor = Color3.fromRGB(255, 255, 255),
	
	-- إعدادات الهاك
	AimbotRange = 100,
	OverrideRange = 50,
	HighlightColor = Color3.fromRGB(255, 255, 255),
	HitboxSize = 50
}

local screenGui = Instance.new("ScreenGui")
screenGui.Name = guiName
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = player:WaitForChild("PlayerGui")

local function addCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
end

-- ============================================================================
-- 2. منطق الهاك (LOGIC FUNCTIONS)
-- ============================================================================

local ESP_Enabled = false
local Aimbot_Enabled = false
local Hitbox_Enabled = false
local CurrentTarget = nil
local Connections = {}

-- :: 1. وظيفة ESP ::
local function ApplyHighlight(char)
	if not char then return end
	task.spawn(function()
		char:WaitForChild("HumanoidRootPart", 10)
		if ESP_Enabled then
			if char:FindFirstChild("ESPHighlight") then char.ESPHighlight:Destroy() end
			local hl = Instance.new("Highlight")
			hl.Name = "ESPHighlight"
			hl.FillColor = CONFIG.HighlightColor
			hl.OutlineColor = Color3.fromRGB(0, 0, 0)
			hl.FillTransparency = 0.5
			hl.OutlineTransparency = 0
			hl.Adornee = char
			hl.Parent = char
		end
	end)
end

local function RemoveHighlight(char)
	if char and char:FindFirstChild("ESPHighlight") then
		char.ESPHighlight:Destroy()
	end
end

-- :: 2. وظيفة Hitbox ::
local function ApplyHitbox(char)
	if not char then return end
	task.spawn(function()
		local head = char:WaitForChild("Head", 10)
		if head and Hitbox_Enabled then
			head.Size = Vector3.new(CONFIG.HitboxSize, CONFIG.HitboxSize, CONFIG.HitboxSize)
			head.Transparency = 0.6
			head.CanCollide = false
		elseif head and not Hitbox_Enabled then
			head.Size = Vector3.new(2, 1, 1)
			head.Transparency = 0
		end
	end)
end

-- :: إدارة اللاعبين ::
local function SetupPlayerConnection(plr)
	if plr == player then return end
	
	local function CharacterHandler(char)
		if ESP_Enabled then ApplyHighlight(char) end
		if Hitbox_Enabled then ApplyHitbox(char) end
	end

	if plr.Character then CharacterHandler(plr.Character) end
	local conn = plr.CharacterAdded:Connect(CharacterHandler)
	table.insert(Connections, conn)
end

for _, v in pairs(Players:GetPlayers()) do SetupPlayerConnection(v) end
table.insert(Connections, Players.PlayerAdded:Connect(SetupPlayerConnection))

-- :: Toggles ::
local function ToggleESP(state)
	ESP_Enabled = state
	for _, v in pairs(Players:GetPlayers()) do
		if v ~= player and v.Character then
			if state then ApplyHighlight(v.Character) else RemoveHighlight(v.Character) end
		end
	end
end

local function ToggleHitbox(state)
	Hitbox_Enabled = state
	for _, v in pairs(Players:GetPlayers()) do
		if v ~= player and v.Character then
			if state then ApplyHitbox(v.Character) else
				local head = v.Character:FindFirstChild("Head")
				if head then head.Size = Vector3.new(1.2, 1, 1) head.Transparency = 0 end
			end
		end
	end
end

-- :: Aimbot Logic ::
local function IsValidTarget(targetPlr)
	if not targetPlr or not targetPlr.Character then return false end
	local hum = targetPlr.Character:FindFirstChild("Humanoid")
	local head = targetPlr.Character:FindFirstChild("Head")
	if not hum or not head or hum.Health <= 0 then return false end
	return true
end

RunService.RenderStepped:Connect(function()
	if not Aimbot_Enabled then 
		CurrentTarget = nil
		return 
	end

	local MyChar = player.Character
	if not MyChar or not MyChar:FindFirstChild("Head") then return end
	local MyPos = MyChar.Head.Position

	local ClosestPriorityEnemy = nil
	local ShortestDist = CONFIG.OverrideRange

	for _, v in pairs(Players:GetPlayers()) do
		if v ~= player and IsValidTarget(v) then
			local EnemyPos = v.Character.Head.Position
			local Dist = (EnemyPos - MyPos).Magnitude
			if Dist < ShortestDist then
				ShortestDist = Dist
				ClosestPriorityEnemy = v
			end
		end
	end

	if ClosestPriorityEnemy then
		CurrentTarget = ClosestPriorityEnemy
	else
		if CurrentTarget then
			local EnemyHead = CurrentTarget.Character and CurrentTarget.Character:FindFirstChild("Head")
			if EnemyHead then
				local Dist = (EnemyHead.Position - MyPos).Magnitude
				if not IsValidTarget(CurrentTarget) or Dist > CONFIG.AimbotRange then
					CurrentTarget = nil
				end
			else
				CurrentTarget = nil
			end
		end

		if not CurrentTarget then
			local BestTarget = nil
			local BestDist = CONFIG.AimbotRange
			for _, v in pairs(Players:GetPlayers()) do
				if v ~= player and IsValidTarget(v) then
					local d = (v.Character.Head.Position - MyPos).Magnitude
					if d < BestDist then
						BestDist = d
						BestTarget = v
					end
				end
			end
			CurrentTarget = BestTarget
		end
	end

	if CurrentTarget and CurrentTarget.Character and CurrentTarget.Character:FindFirstChild("Head") then
		local TargetHead = CurrentTarget.Character.Head
		Camera.CFrame = CFrame.new(Camera.CFrame.Position, TargetHead.Position)
	end
end)

-- ============================================================================
-- 3. واجهة المستخدم (UI STRUCTURE)
-- ============================================================================

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 0, 0, 0)
mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.BackgroundColor3 = CONFIG.ThemeColor
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.Parent = screenGui
addCorner(mainFrame, 12)

local stroke = Instance.new("UIStroke")
stroke.Color = CONFIG.AccentColor
stroke.Thickness = 1
stroke.Transparency = 0.5
stroke.Parent = mainFrame

-- H E A D E R
local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 50)
header.BackgroundTransparency = 1
header.ZIndex = 10
header.Parent = mainFrame

local titleText = Instance.new("TextLabel")
-- !! تم تغيير العنوان هنا !!
titleText.Text = "VNDXS HUB SHOOTER"
titleText.Font = Enum.Font.GothamBlack
titleText.TextColor3 = CONFIG.AccentColor
titleText.TextSize = 20
titleText.Size = UDim2.new(0, 250, 1, 0)
titleText.Position = UDim2.new(0, 20, 0, 0)
titleText.BackgroundTransparency = 1
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Parent = header

-- LINE
local line = Instance.new("Frame")
line.Size = UDim2.new(1, 0, 0, 1)
line.Position = UDim2.new(0, 0, 1, -1)
line.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
line.BorderSizePixel = 0
line.Parent = header

-- ============================================================================
-- 4. القائمة الجانبية ومحتوى التبويبات
-- ============================================================================

local container = Instance.new("Frame")
container.Name = "Container"
container.Size = UDim2.new(1, 0, 1, -50)
container.Position = UDim2.new(0, 0, 0, 50)
container.BackgroundTransparency = 1
container.Parent = mainFrame

-- 1. Sidebar (Left)
local sidebar = Instance.new("Frame")
sidebar.Name = "Sidebar"
sidebar.Size = UDim2.new(0.25, 0, 1, 0)
sidebar.BackgroundColor3 = CONFIG.SidebarColor
sidebar.BorderSizePixel = 0
sidebar.Parent = container

local sidebarLayout = Instance.new("UIListLayout")
sidebarLayout.Padding = UDim.new(0, 5)
sidebarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
sidebarLayout.Parent = sidebar

local sidebarPad = Instance.new("UIPadding")
sidebarPad.PaddingTop = UDim.new(0, 10)
sidebarPad.Parent = sidebar

-- 2. Pages Area (Right)
local pagesArea = Instance.new("Frame")
pagesArea.Name = "PagesArea"
pagesArea.Size = UDim2.new(0.75, 0, 1, 0)
pagesArea.Position = UDim2.new(0.25, 0, 0, 0)
pagesArea.BackgroundTransparency = 1
pagesArea.Parent = container

local Pages = {}
local Buttons = {}

local function createPage(name)
	local page = Instance.new("ScrollingFrame")
	page.Name = name
	page.Size = UDim2.new(1, 0, 1, 0)
	page.BackgroundTransparency = 1
	page.Visible = false
	page.ScrollBarThickness = 2
	page.ScrollBarImageColor3 = CONFIG.AccentColor
	page.Parent = pagesArea
	
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 10)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Parent = page
	
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 20)
	pad.PaddingBottom = UDim.new(0, 20)
	pad.Parent = page
	
	Pages[name] = page
	return page
end

local function createSidebarBtn(text, targetPageName)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0.9, 0, 0, 40)
	btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	btn.Text = text
	btn.Font = Enum.Font.GothamBold
	btn.TextColor3 = Color3.fromRGB(150, 150, 150)
	btn.TextSize = 14
	btn.AutoButtonColor = false
	btn.Parent = sidebar
	addCorner(btn, 6)
	
	btn.MouseButton1Click:Connect(function()
		for _, p in pairs(Pages) do p.Visible = false end
		Pages[targetPageName].Visible = true
		
		for _, b in pairs(Buttons) do
			b.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
			b.TextColor3 = Color3.fromRGB(150, 150, 150)
		end
		btn.BackgroundColor3 = CONFIG.AccentColor
		btn.TextColor3 = CONFIG.ThemeColor
	end)
	
	Buttons[targetPageName] = btn
	return btn
end

local function createToggle(parent, text, defaultState, callback)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0.9, 0, 0, 40)
	frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	frame.BorderSizePixel = 0
	frame.Parent = parent
	addCorner(frame, 6)
	
	local label = Instance.new("TextLabel")
	label.Text = text
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = CONFIG.TextColor
	label.TextSize = 14
	label.Size = UDim2.new(0.7, 0, 1, 0)
	label.Position = UDim2.new(0, 10, 0, 0)
	label.BackgroundTransparency = 1
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = frame
	
	local toggleBtn = Instance.new("TextButton")
	toggleBtn.Size = UDim2.new(0, 20, 0, 20)
	toggleBtn.Position = UDim2.new(1, -30, 0.5, -10)
	toggleBtn.BackgroundColor3 = defaultState and CONFIG.AccentColor or Color3.fromRGB(50, 50, 50)
	toggleBtn.Text = ""
	toggleBtn.AutoButtonColor = false
	toggleBtn.Parent = frame
	addCorner(toggleBtn, 10)
	
	local state = defaultState
	
	toggleBtn.MouseButton1Click:Connect(function()
		state = not state
		toggleBtn.BackgroundColor3 = state and CONFIG.AccentColor or Color3.fromRGB(50, 50, 50)
		callback(state)
	end)
	
	return frame
end

-- ============================================================================
-- 5. بناء التبويبات (BUILDING TABS)
-- ============================================================================

-- 1. Tab: Combat
local combatPage = createPage("Combat")
createSidebarBtn("Combat", "Combat")
createToggle(combatPage, "Aimbot", Aimbot_Enabled, function(state)
	Aimbot_Enabled = state
end)
createToggle(combatPage, "Hitbox", Hitbox_Enabled, ToggleHitbox)

-- 2. Tab: Visuals
local visualsPage = createPage("Visuals")
createSidebarBtn("Visuals", "Visuals")
createToggle(visualsPage, "ESP", ESP_Enabled, ToggleESP)

-- 3. Tab: Settings
local settingsPage = createPage("Settings")
createSidebarBtn("Settings", "Settings")

-- ============================================================================
-- 6. منطق الواجهة (UI LOGIC)
-- ============================================================================

-- A. Toggle UI with 'Insert' key
local isUIOpen = false
local function toggleUI(input, gameProcessed)
	if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.Insert and not gameProcessed then
		isUIOpen = not isUIOpen
		local targetSize = isUIOpen and CONFIG.OpenSize or CONFIG.ClosedSize
		local targetPos = isUIOpen and UDim2.new(0.5, 0, 0.5, 0) or UDim2.new(0.5, 0, 1, -25)
		
		TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = targetSize,
			Position = targetPos
		}):Play()
	end
end

UserInputService.InputBegan:Connect(toggleUI)

-- B. Dragging
local dragging
local dragStart
local startPos

local function drag(input)
	if dragging then
		local delta = input.Position - dragStart
		local newPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		mainFrame.Position = newPos
	end
end

local function dragEnd()
	dragging = false
end

header.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = mainFrame.Position
		
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragEnd()
			end
		end)
	end
end)

UserInputService.InputChanged:Connect(drag)
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragEnd()
	end
end)

-- C. Initial State
task.wait(0.1)
-- Simulate 'Insert' key press to open the UI initially
toggleUI({UserInputType = Enum.UserInputType.Keyboard, KeyCode = Enum.KeyCode.Insert}, false)

-- D. Select first tab
Buttons["Combat"].MouseButton1Click:Fire()

-- E. Cleanup on script stop
screenGui.Parent = nil
for _, conn in pairs(Connections) do
	conn:Disconnect()
end
