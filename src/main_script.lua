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
		if Pages[targetPageName] then Pages[targetPageName].Visible = true end
		
		for _, b in pairs(Buttons) do
			TweenService:Create(b, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(30,30,30), TextColor3 = Color3.fromRGB(150,150,150)}):Play()
		end
		TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = CONFIG.AccentColor, TextColor3 = Color3.fromRGB(0,0,0)}):Play()
	end)
	
	table.insert(Buttons, btn)
	return btn
end

local profilePage = createPage("Profile")
local scriptPage = createPage("Script")
local smPage = createPage("SM")

local btn1 = createSidebarBtn("Profile", "Profile")
local btn2 = createSidebarBtn("Script", "Script")
local btn3 = createSidebarBtn("SM", "SM")

btn1.BackgroundColor3 = CONFIG.AccentColor
btn1.TextColor3 = Color3.new(0,0,0)
profilePage.Visible = true

-- >>>>> 1. PROFILE Content <<<<<
local function setupProfile()
	local imgContainer = Instance.new("Frame")
	imgContainer.Size = UDim2.new(0, 100, 0, 100)
	imgContainer.BackgroundTransparency = 1
	imgContainer.Parent = profilePage
	
	local img = Instance.new("ImageLabel")
	img.Size = UDim2.new(1, 0, 1, 0)
	img.Image = Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
	img.BackgroundColor3 = Color3.fromRGB(30,30,30)
	img.Parent = imgContainer
	addCorner(img, 100)
	
	local stroke = Instance.new("UIStroke")
	stroke.Color = CONFIG.AccentColor
	stroke.Thickness = 2
	stroke.Parent = img
	
	local function addInfo(title, val)
		local f = Instance.new("Frame")
		f.Size = UDim2.new(0.9, 0, 0, 40)
		f.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
		f.Parent = profilePage
		addCorner(f, 6)
		
		local t = Instance.new("TextLabel")
		t.Text = title .. ": "
		t.Size = UDim2.new(0.4, 0, 1, 0)
		t.Position = UDim2.new(0.05, 0, 0, 0)
		t.Font = Enum.Font.GothamMedium
		t.TextColor3 = Color3.fromRGB(150, 150, 150)
		t.TextXAlignment = Enum.TextXAlignment.Left
		t.BackgroundTransparency = 1
		t.Parent = f
		
		local v = Instance.new("TextLabel")
		v.Text = val
		v.Size = UDim2.new(0.5, 0, 1, 0)
		v.Position = UDim2.new(0.45, 0, 0, 0)
		v.Font = Enum.Font.GothamBold
		v.TextColor3 = CONFIG.AccentColor
		v.TextXAlignment = Enum.TextXAlignment.Right
		v.BackgroundTransparency = 1
		v.Parent = f
	end
	
	local days = player.AccountAge
	local years = days / 365.25
	local createdYear = math.floor(os.date("%Y") - years)
	
	addInfo("Username", player.Name)
	addInfo("Alias", player.DisplayName)
	addInfo("Created", tostring(createdYear))
end
setupProfile()

-- >>>>> 2. SCRIPT Content <<<<<
local function createHackBtn(text, callback)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0.9, 0, 0, 45)
	btn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	btn.Text = text
	btn.Font = Enum.Font.GothamBold
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.TextSize = 14
	btn.AutoButtonColor = false
	btn.Parent = scriptPage
	addCorner(btn, 8)
	
	local isActive = false
	btn.MouseButton1Click:Connect(function()
		isActive = not isActive
		if callback then callback(isActive) end
		
		if isActive then
			TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = CONFIG.AccentColor, TextColor3 = Color3.new(0,0,0)}):Play()
			btn.Text = text .. " [ON]"
		else
			TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(35, 35, 35), TextColor3 = Color3.new(1,1,1)}):Play()
			btn.Text = text
		end
	end)
end

createHackBtn("PLAYER ESP (TRACKING)", function(s) ToggleESP(s) end)
createHackBtn("AIMBOT (Head - 100m)", function(s) Aimbot_Enabled = s end)
createHackBtn("HITBOX EXPANDER (Size 50)", function(s) ToggleHitbox(s) end)

-- >>>>> 3. SM Content <<<<<
local function setupSM()
	local title = Instance.new("TextLabel")
	title.Text = "SCRIPT MAKER"
	title.Size = UDim2.new(1, 0, 0, 30)
	title.Font = Enum.Font.GothamBlack
	title.TextColor3 = CONFIG.AccentColor
	title.TextSize = 24
	title.BackgroundTransparency = 1
	title.Parent = smPage
	
	local devName = Instance.new("TextLabel")
	devName.Text = "VNDXS"
	devName.Size = UDim2.new(1, 0, 0, 30)
	devName.Font = Enum.Font.Code
	devName.TextColor3 = Color3.fromRGB(200, 200, 200)
	devName.TextSize = 18
	devName.BackgroundTransparency = 1
	devName.Parent = smPage
	
	local box = Instance.new("Frame")
	box.Size = UDim2.new(0.9, 0, 0, 100)
	box.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	box.Parent = smPage
	addCorner(box, 8)
	
	local lbl = Instance.new("TextLabel")
	lbl.Text = "Discord Server:"
	lbl.Size = UDim2.new(1, 0, 0, 30)
	lbl.TextColor3 = Color3.fromRGB(150, 150, 150)
	lbl.Font = Enum.Font.GothamMedium
	lbl.BackgroundTransparency = 1
	lbl.Parent = box
	
	local link = "https://discord.gg/jRC5haR4g4"
	local linkLbl = Instance.new("TextBox")
	linkLbl.Text = link
	linkLbl.Size = UDim2.new(0.9, 0, 0, 30)
	linkLbl.Position = UDim2.new(0.05, 0, 0, 30)
	linkLbl.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
	linkLbl.TextColor3 = Color3.fromRGB(88, 101, 242)
	linkLbl.ClearTextOnFocus = false
	linkLbl.TextEditable = false
	linkLbl.Parent = box
	addCorner(linkLbl, 4)
	
	local copyBtn = Instance.new("TextButton")
	copyBtn.Text = "COPY LINK"
	copyBtn.Size = UDim2.new(0.5, 0, 0, 30)
	copyBtn.Position = UDim2.new(0.25, 0, 0, 65)
	copyBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	copyBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
	copyBtn.Font = Enum.Font.GothamBold
	copyBtn.Parent = box
	addCorner(copyBtn, 4)
	
	copyBtn.MouseButton1Click:Connect(function()
		pcall(function() setclipboard(link) end)
		copyBtn.Text = "COPIED!"
		copyBtn.BackgroundColor3 = Color3.fromRGB(80, 255, 80)
		task.wait(1)
		copyBtn.Text = "COPY LINK"
		copyBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	end)
end
setupSM()

-- ============================================================================
-- 6. أزرار التحكم العلوية (Min, Max, Close)
-- ============================================================================

local btnContainer = Instance.new("Frame")
btnContainer.Size = UDim2.new(0.4, 0, 1, 0) -- مساحة أوسع للأزرار الثلاثة
btnContainer.Position = UDim2.new(0.6, 0, 0, 0)
btnContainer.BackgroundTransparency = 1
btnContainer.ZIndex = 20
btnContainer.Parent = header

local btnLayout = Instance.new("UIListLayout")
btnLayout.FillDirection = Enum.FillDirection.Horizontal
btnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
btnLayout.VerticalAlignment = Enum.VerticalAlignment.Center
btnLayout.Padding = UDim.new(0, 5)
btnLayout.Parent = btnContainer

local function createTopBtn(text, color, callback)
	local btn = Instance.new("TextButton")
	btn.Text = text
	btn.Size = UDim2.new(0, 30, 0, 30)
	btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	btn.BackgroundTransparency = 0.9
	btn.TextColor3 = color
	btn.Font = Enum.Font.GothamBlack
	btn.TextSize = 16
	btn.Parent = btnContainer
	addCorner(btn, 6)
	
	local p = Instance.new("UIPadding")
	p.PaddingRight = UDim.new(0, 10)
	p.Parent = btnContainer
	
	btn.MouseButton1Click:Connect(callback)
end

-- متغيرات الحالة
local isMinimized = false
local isMaximized = false

-- 1. زر التصغير (Minimize)
createTopBtn("_", CONFIG.AccentColor, function()
	if isMinimized then
		-- فتح (استرجاع الحجم بناءً على حالة التكبير)
		isMinimized = false
		container.Visible = true
		local targetSize = isMaximized and UDim2.new(1, 0, 1, 0) or CONFIG.OpenSize
		TweenService:Create(mainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Size = targetSize}):Play()
	else
		-- إغلاق
		isMinimized = true
		container.Visible = false
		-- نحافظ على العرض الحالي (سواء كان كاملاً أو عادياً) ولكن نقلل الارتفاع
		local targetWidth = isMaximized and UDim2.new(1, 0, 0, 55) or CONFIG.ClosedSize
		TweenService:Create(mainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Size = targetWidth}):Play()
	end
end)

-- 2. زر التكبير/الاستعادة (Maximize/Restore) - الزر الجديد
createTopBtn("[ ]", CONFIG.AccentColor, function()
	if isMaximized then
		-- العودة للحجم الطبيعي
		isMaximized = false
		isMinimized = false -- نلغي التصغير إذا كان موجوداً
		container.Visible = true
		
		TweenService:Create(mainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {
			Size = CONFIG.OpenSize,
			Position = UDim2.new(0.5, 0, 0.5, 0) -- نعيده للمنتصف
		}):Play()
	else
		-- ملء الشاشة
		isMaximized = true
		isMinimized = false -- نلغي التصغير إذا كان موجوداً
		container.Visible = true
		
		TweenService:Create(mainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {
			Size = UDim2.new(1, 0, 1, 0), -- ملء الشاشة
			Position = UDim2.new(0.5, 0, 0.5, 0)
		}):Play()
	end
end)

-- 3. زر الإغلاق (Close)
createTopBtn("X", Color3.fromRGB(255, 80, 80), function()
	screenGui:Destroy()
end)

-- ============================================================================
-- 7. بدء التشغيل (Startup & Drag)
-- ============================================================================

TweenService:Create(mainFrame, TweenInfo.new(0.8, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {Size = CONFIG.OpenSize}):Play()

local dragging, dragInput, dragStart, startPos
local function update(input)
	-- إذا كان مكبر (Maximized)، نمنع السحب حتى لا يخرب المنظر، أو يمكنك إزالته إذا أردت السحب في كل الحالات
	if isMaximized then return end
	
	local delta = input.Position - dragStart
	mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

header.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = mainFrame.Position
		input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
	end
end)
header.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end end)
UserInputService.InputChanged:Connect(function(input) if input == dragInput and dragging then update(input) end end)
