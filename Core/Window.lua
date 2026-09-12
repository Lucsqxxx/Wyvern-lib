-- Window.lua
-- Main floating window with stable positioning, drag, minimize, and navigation.
-- Safe client-side parenting with CoreGui fallback.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local Maid = require(script.Parent.Maid)
local Tab = require(script.Parent.Tab)
local Search = require(script.Parent.Search)
local Input = require(script.Parent.Input)
local Constants = require(script.Parent.Constants)
local Icons = require(script.Parent.Parent.Icons.Registry)
local Notification = require(script.Parent.Notification)
local PopupManager = require(script.Parent.PopupManager)

local Window = {}
Window.__index = Window

-- Global registry for duplicate protection
local ActiveWindows = {}

local function getGuiParent()
	local ok, coreGui = pcall(function()
		return game:GetService("CoreGui")
	end)
	if ok and coreGui then
		local test = Instance.new("Folder")
		test.Name = "WyvernParentTest"
		local parentOk = pcall(function()
			test.Parent = coreGui
		end)
		if parentOk then
			test:Destroy()
			return coreGui
		end
		pcall(function()
			test:Destroy()
		end)
	end

	local player = Players.LocalPlayer
	if not player then
		player = Players.PlayerAdded:Wait()
	end
	local playerGui = player:WaitForChild("PlayerGui", 10)
	if playerGui then
		return playerGui
	end
	error("[Wyvern] Unable to find a valid GUI parent (CoreGui or PlayerGui)")
end

local function getViewportSize()
	local cam = workspace.CurrentCamera
	if cam then
		return cam.ViewportSize
	end
	return Vector2.new(1920, 1080)
end

-- Always use offset-only positions so drag/minimize never mix Scale and Offset.
local function centerPosition(width, height, scale)
	scale = scale or 1
	local vp = getViewportSize()
	local w = width * scale
	local h = height * scale
	local x = math.max(0, (vp.X - w) / 2)
	local y = math.max(0, (vp.Y - h) / 2)
	return UDim2.fromOffset(x, y)
end

local function clampPosition(x, y, width, height, scale)
	scale = scale or 1
	local vp = getViewportSize()
	local w = width * scale
	local h = height * scale
	x = math.clamp(x, 0, math.max(0, vp.X - w))
	y = math.clamp(y, 0, math.max(0, vp.Y - h))
	return x, y
end

function Window.new(config, theme, scale)
	config = config or {}
	local name = config.Name or "Wyvern"

	if ActiveWindows[name] then
		pcall(function()
			ActiveWindows[name]:Destroy()
		end)
		ActiveWindows[name] = nil
	end

	local self = setmetatable({
		_maid = Maid.new(),
		_theme = theme,
		_scale = scale or 1,
		_name = name,
		_version = config.Version or "v1.0.0",
		_tabs = {},
		_currentTab = nil,
		_minimized = false,
		_visible = true,
		_dragging = false,
		_dragStart = nil,
		_startAbs = nil, -- AbsolutePosition at drag start
		_destroyed = false,
		_savedPosition = nil, -- UDim2 offset-only while normal
	}, Window)

	self._search = Search.new()
	self._input = Input.new()
	self._maid:Give(function()
		if self._search then
			self._search:Destroy()
			self._search = nil
		end
		if self._input then
			self._input:Destroy()
			self._input = nil
		end
	end)

	local parent = getGuiParent()

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "Wyvern_" .. self._name
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.DisplayOrder = 100
	screenGui.IgnoreGuiInset = true
	screenGui.Parent = parent
	self._screenGui = screenGui
	self._maid:Give(screenGui)

	local uiScale = Instance.new("UIScale")
	uiScale.Scale = self._scale
	uiScale.Parent = screenGui
	self._uiScale = uiScale

	-- Screen-space overlay for dropdowns/popups (above window, not clipped by content)
	local overlay = Instance.new("Frame")
	overlay.Name = "OverlayLayer"
	overlay.BackgroundTransparency = 1
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.Position = UDim2.fromOffset(0, 0)
	overlay.ZIndex = Constants.ZIndex.Overlay
	overlay.Active = false
	overlay.Parent = screenGui
	self._overlay = overlay
	PopupManager.SetOverlay(overlay)

	-- Main window: offset-only position from the start
	local main = Instance.new("Frame")
	main.Name = "MainWindow"
	main.Size = UDim2.fromOffset(Constants.WindowWidth, Constants.WindowHeight)
	main.Position = centerPosition(Constants.WindowWidth, Constants.WindowHeight, self._scale)
	main.BackgroundColor3 = theme:Get("Background")
	main.BorderSizePixel = 0
	main.Active = true -- receives input so children work; drag is only on handle
	main.Parent = screenGui
	self._main = main
	self._savedPosition = main.Position

	local mainCorner = Instance.new("UICorner")
	mainCorner.CornerRadius = UDim.new(0, Constants.WindowCornerRadius)
	mainCorner.Parent = main

	local mainStroke = Instance.new("UIStroke")
	mainStroke.Color = theme:Get("Border")
	mainStroke.Thickness = 1
	mainStroke.Transparency = 0.4
	mainStroke.Parent = main

	-- Shadow (non-interactive)
	local shadow = Instance.new("Frame")
	shadow.Name = "Shadow"
	shadow.Size = UDim2.new(1, 12, 1, 12)
	shadow.Position = UDim2.fromOffset(-6, -4)
	shadow.BackgroundColor3 = theme:Get("Shadow")
	shadow.BackgroundTransparency = 0.7
	shadow.BorderSizePixel = 0
	shadow.ZIndex = 0
	shadow.Active = false
	shadow.Parent = main

	local shadowCorner = Instance.new("UICorner")
	shadowCorner.CornerRadius = UDim.new(0, Constants.WindowCornerRadius + 4)
	shadowCorner.Parent = shadow

	-- Header
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, Constants.HeaderHeight)
	header.BackgroundTransparency = 1
	header.BorderSizePixel = 0
	header.Parent = main
	self._header = header

	local logo = Instance.new("ImageLabel")
	logo.Name = "Logo"
	logo.Size = UDim2.fromOffset(18, 18)
	logo.Position = UDim2.new(0, 12, 0.5, -9)
	logo.BackgroundTransparency = 1
	logo.Image = Icons.Get("Sakura")
	logo.ImageColor3 = theme:Get("Accent")
	logo.Parent = header

	-- Left title cluster: Title + Version via layout (no overlap)
	local titleCluster = Instance.new("Frame")
	titleCluster.Name = "TitleCluster"
	titleCluster.BackgroundTransparency = 1
	titleCluster.Position = UDim2.fromOffset(36, 0)
	titleCluster.Size = UDim2.new(1, -120, 1, 0)
	titleCluster.ClipsDescendants = true
	titleCluster.Parent = header

	local titleLayout = Instance.new("UIListLayout")
	titleLayout.FillDirection = Enum.FillDirection.Horizontal
	titleLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	titleLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	titleLayout.Padding = UDim.new(0, 8)
	titleLayout.SortOrder = Enum.SortOrder.LayoutOrder
	titleLayout.Parent = titleCluster

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.AutomaticSize = Enum.AutomaticSize.X
	title.Size = UDim2.fromOffset(0, Constants.HeaderHeight)
	title.Font = Enum.Font.GothamBold
	title.TextSize = Constants.TitleSize
	title.TextColor3 = theme:Get("Text")
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextTruncate = Enum.TextTruncate.AtEnd
	title.Text = self._name
	title.LayoutOrder = 1
	title.Parent = titleCluster
	self._titleLabel = title

	local version = Instance.new("TextLabel")
	version.Name = "Version"
	version.BackgroundTransparency = 1
	version.AutomaticSize = Enum.AutomaticSize.X
	version.Size = UDim2.fromOffset(0, Constants.HeaderHeight)
	version.Font = Enum.Font.Gotham
	version.TextSize = Constants.VersionSize
	version.TextColor3 = theme:Get("TextSecondary")
	version.TextXAlignment = Enum.TextXAlignment.Left
	version.Text = self._version
	version.LayoutOrder = 2
	version.Parent = titleCluster
	self._versionLabel = version

	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "Close"
	closeBtn.Size = UDim2.fromOffset(28, 28)
	closeBtn.Position = UDim2.new(1, -34, 0.5, -14)
	closeBtn.BackgroundTransparency = 1
	closeBtn.Text = "×"
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextSize = 18
	closeBtn.TextColor3 = theme:Get("TextSecondary")
	closeBtn.ZIndex = 5
	closeBtn.Parent = header

	local minBtn = Instance.new("TextButton")
	minBtn.Name = "Minimize"
	minBtn.Size = UDim2.fromOffset(28, 28)
	minBtn.Position = UDim2.new(1, -62, 0.5, -14)
	minBtn.BackgroundTransparency = 1
	minBtn.Text = "–"
	minBtn.Font = Enum.Font.GothamBold
	minBtn.TextSize = 18
	minBtn.TextColor3 = theme:Get("TextSecondary")
	minBtn.ZIndex = 5
	minBtn.Parent = header

	self._maid:Give(closeBtn.MouseButton1Click:Connect(function()
		if self._destroyed then
			return
		end
		self:Close()
	end))
	self._maid:Give(minBtn.MouseButton1Click:Connect(function()
		if self._destroyed then
			return
		end
		if self._minimized then
			self:Restore()
		else
			self:Minimize()
		end
	end))

	-- Drag region: only header strip, excludes control buttons
	local dragHandle = Instance.new("TextButton")
	dragHandle.Name = "DragHandle"
	dragHandle.Size = UDim2.new(1, -90, 1, 0)
	dragHandle.BackgroundTransparency = 1
	dragHandle.Text = ""
	dragHandle.AutoButtonColor = false
	dragHandle.ZIndex = 2
	dragHandle.Parent = header

	-- Drag: press tracks pointer; movement only applies after DragThreshold px
	-- so clicks / double-clicks never teleport the window.
	self._dragPending = false
	self._maid:Give(dragHandle.InputBegan:Connect(function(input)
		if self._destroyed then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			self._dragPending = true
			self._dragging = false
			self._dragStart = Vector2.new(input.Position.X, input.Position.Y)
			local abs = main.AbsolutePosition
			self._startAbs = Vector2.new(abs.X, abs.Y)
		end
	end))

	self._maid:Give(UserInputService.InputChanged:Connect(function(input)
		if self._destroyed or not self._dragStart or not self._startAbs then
			return
		end
		if not (self._dragPending or self._dragging) then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			local delta = Vector2.new(input.Position.X, input.Position.Y) - self._dragStart
			if not self._dragging then
				local thresh = Constants.DragThreshold or 4
				if delta.Magnitude < thresh then
					return -- still a click, not a drag
				end
				self._dragging = true
				self._dragPending = false
			end
			local newX = self._startAbs.X + delta.X
			local newY = self._startAbs.Y + delta.Y
			local h = self._minimized and (Constants.HeaderHeight + 10) or Constants.WindowHeight
			newX, newY = clampPosition(newX, newY, Constants.WindowWidth, h, self._scale)
			main.Position = UDim2.fromOffset(newX, newY)
			if not self._minimized then
				self._savedPosition = main.Position
				self:_syncSecondary()
			end
		end
	end))

	self._maid:Give(UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			self._dragging = false
			self._dragPending = false
			self._dragStart = nil
			self._startAbs = nil
			if not self._minimized and main then
				self._savedPosition = main.Position
			end
		end
	end))

	-- Search bar
	local searchFrame = Instance.new("Frame")
	searchFrame.Name = "SearchBar"
	searchFrame.Size = UDim2.new(1, -24, 0, Constants.SearchHeight)
	searchFrame.Position = UDim2.fromOffset(12, Constants.HeaderHeight + 4)
	searchFrame.BackgroundColor3 = theme:Get("SurfaceSecondary")
	searchFrame.BorderSizePixel = 0
	searchFrame.Parent = main
	self._searchFrame = searchFrame

	local searchCorner = Instance.new("UICorner")
	searchCorner.CornerRadius = UDim.new(0, Constants.SmallCornerRadius)
	searchCorner.Parent = searchFrame

	local searchIcon = Instance.new("ImageLabel")
	searchIcon.Name = "Icon"
	searchIcon.Size = UDim2.fromOffset(14, 14)
	searchIcon.Position = UDim2.new(0, 10, 0.5, -7)
	searchIcon.BackgroundTransparency = 1
	searchIcon.Image = Icons.Get("Search")
	searchIcon.ImageColor3 = theme:Get("TextSecondary")
	searchIcon.Parent = searchFrame

	local searchBox = Instance.new("TextBox")
	searchBox.Name = "Input"
	searchBox.Size = UDim2.new(1, -36, 1, 0)
	searchBox.Position = UDim2.fromOffset(30, 0)
	searchBox.BackgroundTransparency = 1
	searchBox.Font = Enum.Font.Gotham
	searchBox.TextSize = 13
	searchBox.TextColor3 = theme:Get("Text")
	searchBox.PlaceholderText = "search"
	searchBox.PlaceholderColor3 = theme:Get("TextDisabled")
	searchBox.Text = ""
	searchBox.ClearTextOnFocus = false
	searchBox.Parent = searchFrame
	self._searchBox = searchBox

	self._maid:Give(searchBox:GetPropertyChangedSignal("Text"):Connect(function()
		if self._destroyed or not self._search then
			return
		end
		self._search:SetQuery(searchBox.Text)
	end))

	-- Content
	local contentContainer = Instance.new("Frame")
	contentContainer.Name = "ContentContainer"
	contentContainer.Size = UDim2.new(1, 0, 1, -(Constants.HeaderHeight + Constants.SearchHeight + 50))
	contentContainer.Position = UDim2.fromOffset(0, Constants.HeaderHeight + Constants.SearchHeight + 10)
	contentContainer.BackgroundTransparency = 1
	contentContainer.ClipsDescendants = true
	contentContainer.Parent = main
	self._contentContainer = contentContainer

	-- Bottom navigation
	local bottomNav = Instance.new("Frame")
	bottomNav.Name = "BottomNav"
	bottomNav.Size = UDim2.fromOffset(220, 36)
	bottomNav.Position = UDim2.new(0.5, -110, 1, -48)
	bottomNav.BackgroundColor3 = theme:Get("NavBackground")
	bottomNav.BorderSizePixel = 0
	bottomNav.Parent = main
	self._bottomNav = bottomNav

	local navCorner = Instance.new("UICorner")
	navCorner.CornerRadius = UDim.new(1, 0)
	navCorner.Parent = bottomNav

	local navStroke = Instance.new("UIStroke")
	navStroke.Color = theme:Get("Border")
	navStroke.Thickness = 1
	navStroke.Transparency = 0.5
	navStroke.Parent = bottomNav

	local navLayout = Instance.new("UIListLayout")
	navLayout.FillDirection = Enum.FillDirection.Horizontal
	navLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	navLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	navLayout.Padding = UDim.new(0, 8)
	navLayout.Parent = bottomNav

	local navPadding = Instance.new("UIPadding")
	navPadding.PaddingLeft = UDim.new(0, 12)
	navPadding.PaddingRight = UDim.new(0, 12)
	navPadding.Parent = bottomNav

	-- Secondary floating bar (follows main window)
	local secondary = Instance.new("Frame")
	secondary.Name = "SecondaryBar"
	secondary.Size = UDim2.fromOffset(200, 34)
	secondary.BackgroundColor3 = theme:Get("NavBackground")
	secondary.BorderSizePixel = 0
	secondary.Parent = screenGui
	self._secondary = secondary

	local secCorner = Instance.new("UICorner")
	secCorner.CornerRadius = UDim.new(1, 0)
	secCorner.Parent = secondary

	local secStroke = Instance.new("UIStroke")
	secStroke.Color = theme:Get("Border")
	secStroke.Thickness = 1
	secStroke.Transparency = 0.5
	secStroke.Parent = secondary

	local secLayout = Instance.new("UIListLayout")
	secLayout.FillDirection = Enum.FillDirection.Horizontal
	secLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	secLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	secLayout.Padding = UDim.new(0, 10)
	secLayout.Parent = secondary

	local secPad = Instance.new("UIPadding")
	secPad.PaddingLeft = UDim.new(0, 14)
	secPad.PaddingRight = UDim.new(0, 14)
	secPad.Parent = secondary

	self:_syncSecondary()

	local function createNavIcon(parentFrame, iconName, selected)
		local btn = Instance.new("ImageButton")
		btn.Name = "Nav_" .. iconName
		btn.Size = UDim2.fromOffset(22, 22)
		btn.BackgroundTransparency = 1
		btn.Image = Icons.Get(iconName)
		btn.ImageColor3 = selected and theme:Get("Accent") or theme:Get("TextSecondary")
		btn.AutoButtonColor = false
		btn.Parent = parentFrame
		return btn
	end

	-- Bottom nav icons — wired to tab selection by index when possible
	local navNames = { "Moss", "Eye", "Layers", "Target", "Settings" }
	self._navIcons = {}
	for i, iconName in ipairs(navNames) do
		local btn = createNavIcon(bottomNav, iconName, i == 1)
		self._navIcons[i] = btn
		local index = i
		self._maid:Give(btn.MouseButton1Click:Connect(function()
			if self._destroyed or self._minimized then
				return
			end
			self:_selectNav(index)
		end))
	end

	local secNames = { "Play", "Cube", "Users", "Layers", "Settings" }
	self._secIcons = {}
	for i, iconName in ipairs(secNames) do
		local btn = createNavIcon(secondary, iconName, i == 1)
		self._secIcons[i] = btn
		local index = i
		self._maid:Give(btn.MouseButton1Click:Connect(function()
			if self._destroyed then
				return
			end
			self:_selectSecondary(index)
		end))
	end

	self._maid:Give(main)

	self._notifications = Notification.new(screenGui, theme)
	self._maid:Give(function()
		if self._notifications then
			self._notifications:Destroy()
			self._notifications = nil
		end
	end)

	local cam = workspace.CurrentCamera
	if cam then
		self._maid:Give(cam:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			if self._destroyed or not self._main then return end
			local pos = self._main.Position
			local h = self._minimized and (Constants.HeaderHeight + 10) or Constants.WindowHeight
			local x, y = clampPosition(pos.X.Offset, pos.Y.Offset, Constants.WindowWidth, h, self._scale)
			self._main.Position = UDim2.fromOffset(x, y)
			if not self._minimized then
				self._savedPosition = self._main.Position
			end
			self:_syncSecondary()
		end))
	end

	if theme and theme.OnChanged then
		local unsub = theme:OnChanged(function()
			if self._destroyed then return end
			self:_applyChromeTheme()
		end)
		self._maid:Give(function()
			if type(unsub) == "function" then unsub() end
		end)
	end

	ActiveWindows[self._name] = self
	return self
end


function Window:_applyChromeTheme()
	if self._destroyed or not self._theme then return end
	local theme = self._theme
	if self._main then
		self._main.BackgroundColor3 = theme:Get("Background")
	end
	local stroke = self._main and self._main:FindFirstChildOfClass("UIStroke")
	if stroke then stroke.Color = theme:Get("Border") end
	if self._titleLabel then self._titleLabel.TextColor3 = theme:Get("Text") end
	if self._versionLabel then self._versionLabel.TextColor3 = theme:Get("TextSecondary") end
	local logo = self._header and self._header:FindFirstChild("Logo")
	if logo then logo.ImageColor3 = theme:Get("Accent") end
	if self._searchFrame then self._searchFrame.BackgroundColor3 = theme:Get("SurfaceSecondary") end
	if self._searchBox then
		self._searchBox.TextColor3 = theme:Get("Text")
		self._searchBox.PlaceholderColor3 = theme:Get("TextDisabled")
	end
	if self._bottomNav then self._bottomNav.BackgroundColor3 = theme:Get("NavBackground") end
	if self._secondary then self._secondary.BackgroundColor3 = theme:Get("NavBackground") end
end

function Window:_syncSecondary()
	if not self._secondary or not self._main or self._destroyed then
		return
	end
	local pos = self._main.Position
	local x = pos.X.Offset + (Constants.WindowWidth - 200) / 2
	local y = pos.Y.Offset + Constants.WindowHeight + 12
	if self._minimized then
		y = pos.Y.Offset + Constants.HeaderHeight + 22
	end
	self._secondary.Position = UDim2.fromOffset(x, y)
end

function Window:_selectNav(index)
	local theme = self._theme
	local navCount = #(self._navIcons or {})
	-- Last icon is always Settings
	if index == navCount then
		for i, btn in ipairs(self._navIcons or {}) do
			if btn then
				btn.ImageColor3 = (i == index) and theme:Get("Accent") or theme:Get("TextSecondary")
			end
		end
		self:OpenSettings()
		return
	end
	for i, btn in ipairs(self._navIcons or {}) do
		if btn then
			btn.ImageColor3 = (i == index) and theme:Get("Accent") or theme:Get("TextSecondary")
		end
	end
	local tab = self._tabs[index]
	if tab and not tab._destroyed then
		tab:Select()
	end
end

function Window:_selectSecondary(index)
	local theme = self._theme
	for i, btn in ipairs(self._secIcons or {}) do
		if btn then
			btn.ImageColor3 = (i == index) and theme:Get("Accent") or theme:Get("TextSecondary")
		end
	end
	if index == 1 then
		if self._minimized then
			self:Restore()
		end
		self:Open()
	elseif index == #(self._secIcons or {}) then
		self:OpenSettings()
	end
end

function Window:OpenSettings()
	if self._destroyed then
		return
	end
	if self._minimized then
		self:Restore()
	end
	pcall(function()
		PopupManager.CloseAll()
	end)
	-- Create settings tab once
	if self._settingsTab and not self._settingsTab._destroyed then
		self._settingsTab:Select()
		return
	end
	local tab = self:CreateTab({ Name = "Settings", Icon = "Settings" })
	self._settingsTab = tab
	local section = tab:CreateSection({ Name = "Appearance", Column = "Left" })
	local section2 = tab:CreateSection({ Name = "Behavior", Column = "Right" })

	section:CreateSlider({
		Name = "UI Scale",
		Min = 0.7,
		Max = 1.4,
		Default = self._scale or 1,
		Increment = 0.05,
		Callback = function(v)
			self:SetScale(v)
		end,
	})

	section:CreateColorPicker({
		Name = "Accent",
		Default = self._theme and self._theme:Get("Accent") or Color3.fromRGB(255, 110, 175),
		Callback = function(c)
			if self._theme then
				self._theme:Set("Accent", c)
				self._theme:Set("ToggleOn", c)
				self._theme:Set("SliderFill", c)
			end
			-- Update header logo accent if present
			local logo = self._header and self._header:FindFirstChild("Logo")
			if logo then
				logo.ImageColor3 = c
			end
		end,
	})

	section:CreateColorPicker({
		Name = "Background",
		Default = self._theme and self._theme:Get("Background") or Color3.fromRGB(18, 14, 24),
		Callback = function(c)
			if self._theme then
				self._theme:Set("Background", c)
			end
			if self._main then
				self._main.BackgroundColor3 = c
			end
		end,
	})

	section:CreateColorPicker({
		Name = "Surface",
		Default = self._theme and self._theme:Get("Surface") or Color3.fromRGB(30, 24, 38),
		Callback = function(c)
			if self._theme then
				self._theme:Set("Surface", c)
			end
		end,
	})

	section2:CreateToggle({
		Name = "Auto-close Popups",
		Default = true,
		Callback = function(v)
			self._autoClosePopups = v
		end,
	})

	section2:CreateButton({
		Name = "Reset Scale",
		Callback = function()
			self:SetScale(1)
		end,
	})

	section2:CreateButton({
		Name = "Center Window",
		Callback = function()
			if self._main then
				local pos = centerPosition(Constants.WindowWidth, Constants.WindowHeight, self._scale)
				self._main.Position = pos
				self._savedPosition = pos
				self:_syncSecondary()
			end
		end,
	})

	section2:CreateButton({
		Name = "Close Settings Tab",
		Callback = function()
			if self._tabs[1] then
				self._tabs[1]:Select()
			end
		end,
	})

	tab:Select()
end

function Window:CreateTab(config)
	if self._destroyed then
		return nil
	end
	local tab = Tab.new(config, self, self._theme, self._search, self._input)
	table.insert(self._tabs, tab)

	if #self._tabs == 1 then
		tab:Select()
		self._currentTab = tab
		self:_selectNav(1)
	end

	return tab
end

function Window:_onTabSelected(tab)
	pcall(function()
		PopupManager.CloseAll()
	end)
	for _, t in ipairs(self._tabs) do
		if t ~= tab then
			t:Deselect()
		end
	end
	self._currentTab = tab
	local idx = table.find(self._tabs, tab)
	if idx then
		self:_selectNav(idx)
	end
end

function Window:Open()
	if self._destroyed then
		return
	end
	self._visible = true
	if self._screenGui then
		self._screenGui.Enabled = true
	end
	if self._main then
		self._main.Visible = true
	end
	if self._secondary then
		self._secondary.Visible = true
	end
end

function Window:Close()
	if self._destroyed then
		return
	end
	self._visible = false
	if self._screenGui then
		self._screenGui.Enabled = false
	end
end

function Window:Toggle()
	if self._destroyed then
		return
	end
	if self._visible then
		self:Close()
	else
		self:Open()
	end
end

function Window:Minimize()
	if self._destroyed or self._minimized then
		return
	end
	-- Close any open dropdowns/popups so they don't float after chrome hides
	pcall(function()
		PopupManager.CloseAll()
	end)
	self._minimized = true
	self._dragging = false
	self._dragStart = nil
	self._startAbs = nil

	if self._main then
		self._savedPosition = self._main.Position
	end

	-- Hide all expanded-window chrome (including search)
	if self._searchFrame then
		self._searchFrame.Visible = false
	end
	if self._contentContainer then
		self._contentContainer.Visible = false
	end
	if self._bottomNav then
		self._bottomNav.Visible = false
	end
	if self._main then
		self._main.Size = UDim2.fromOffset(Constants.WindowWidth, Constants.HeaderHeight + 10)
	end
	self:_syncSecondary()
end

function Window:Restore()
	if self._destroyed or not self._minimized then
		return
	end
	self._minimized = false

	if self._searchFrame then
		self._searchFrame.Visible = true
	end
	if self._contentContainer then
		self._contentContainer.Visible = true
	end
	if self._bottomNav then
		self._bottomNav.Visible = true
	end
	if self._main then
		self._main.Size = UDim2.fromOffset(Constants.WindowWidth, Constants.WindowHeight)
		if self._savedPosition then
			self._main.Position = self._savedPosition
		end
	end
	self:_syncSecondary()
end

function Window:SetVisible(visible)
	if self._destroyed then
		return
	end
	self._visible = visible and true or false
	if self._main then
		self._main.Visible = self._visible
	end
	if self._secondary then
		self._secondary.Visible = self._visible
	end
	if self._screenGui then
		self._screenGui.Enabled = self._visible
	end
end

function Window:SetScale(scale)
	if self._destroyed then
		return
	end
	self._scale = math.clamp(tonumber(scale) or 1, 0.5, 2)
	if self._uiScale then
		self._uiScale.Scale = self._scale
	end
end

function Window:Notify(config)
	if self._destroyed or not self._notifications then
		return
	end
	return self._notifications:Notify(config)
end

function Window:SetTitle(title)
	if self._destroyed then
		return
	end
	self._name = tostring(title or self._name)
	if self._titleLabel then
		self._titleLabel.Text = self._name
	end
end

function Window:SetVersion(version)
	if self._destroyed then
		return
	end
	self._version = tostring(version or self._version)
	if self._versionLabel then
		self._versionLabel.Text = self._version
	end
end

function Window:GetTabs()
	return self._tabs
end

function Window:GetCurrentTab()
	return self._currentTab
end

function Window:IsVisible()
	return self._visible
end

function Window:IsMinimized()
	return self._minimized
end

function Window:Destroy()
	if self._destroyed then
		return
	end
	self._destroyed = true
	self._dragging = false
	self._dragStart = nil
	self._startAbs = nil

	for _, tab in ipairs(self._tabs) do
		pcall(function()
			tab:Destroy()
		end)
	end
	self._tabs = {}
	self._currentTab = nil

	if ActiveWindows[self._name] == self then
		ActiveWindows[self._name] = nil
	end

	self._maid:Destroy()
	self._main = nil
	self._secondary = nil
	self._screenGui = nil
	self._uiScale = nil
	self._contentContainer = nil
	self._bottomNav = nil
	self._searchFrame = nil
	self._searchBox = nil
	self._header = nil
	self._navIcons = nil
	self._secIcons = nil
	setmetatable(self, nil)
end

return Window
