-- Window.lua
-- Main floating window with header, search, content, navigation.
-- Safe client-side parenting with CoreGui fallback.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local Maid = require(script.Parent.Maid)
local Tab = require(script.Parent.Tab)
local Search = require(script.Parent.Search)
local Input = require(script.Parent.Input)
local Animation = require(script.Parent.Animation)
local Constants = require(script.Parent.Constants)
local Icons = require(script.Parent.Parent.Icons.Registry)

local Window = {}
Window.__index = Window

-- Global registry for duplicate protection
local ActiveWindows = {}

local function getGuiParent()
	-- Prefer CoreGui when possible (executor / elevated environments)
	local ok, coreGui = pcall(function()
		return game:GetService("CoreGui")
	end)
	if ok and coreGui then
		-- Test write access safely
		local test = Instance.new("Folder")
		test.Name = "WyvernParentTest"
		local parentOk = pcall(function()
			test.Parent = coreGui
		end)
		if parentOk then
			test:Destroy()
			return coreGui
		end
		test:Destroy()
	end

	-- Fallback to PlayerGui
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

function Window.new(config, theme, scale)
	config = config or {}
	local name = config.Name or "Wyvern"

	-- Duplicate protection: destroy previous window with same name
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
		_startPos = nil,
		_destroyed = false,
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

	-- Root ScreenGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "Wyvern_" .. self._name
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.DisplayOrder = 100
	screenGui.IgnoreGuiInset = true
	screenGui.Parent = parent
	self._screenGui = screenGui
	self._maid:Give(screenGui)

	-- Global scale
	local uiScale = Instance.new("UIScale")
	uiScale.Scale = self._scale
	uiScale.Parent = screenGui
	self._uiScale = uiScale

	-- Main window frame
	local main = Instance.new("Frame")
	main.Name = "MainWindow"
	main.Size = UDim2.new(0, Constants.WindowWidth, 0, Constants.WindowHeight)
	main.Position = UDim2.new(0.5, -Constants.WindowWidth / 2, 0.5, -Constants.WindowHeight / 2)
	main.BackgroundColor3 = theme:Get("Background")
	main.BorderSizePixel = 0
	main.Parent = screenGui
	self._main = main

	local mainCorner = Instance.new("UICorner")
	mainCorner.CornerRadius = UDim.new(0, Constants.WindowCornerRadius)
	mainCorner.Parent = main

	local mainStroke = Instance.new("UIStroke")
	mainStroke.Color = theme:Get("Border")
	mainStroke.Thickness = 1
	mainStroke.Transparency = 0.4
	mainStroke.Parent = main

	-- Subtle shadow
	local shadow = Instance.new("Frame")
	shadow.Name = "Shadow"
	shadow.Size = UDim2.new(1, 12, 1, 12)
	shadow.Position = UDim2.new(0, -6, 0, -4)
	shadow.BackgroundColor3 = theme:Get("Shadow")
	shadow.BackgroundTransparency = 0.7
	shadow.BorderSizePixel = 0
	shadow.ZIndex = 0
	shadow.Parent = main

	local shadowCorner = Instance.new("UICorner")
	shadowCorner.CornerRadius = UDim.new(0, Constants.WindowCornerRadius + 4)
	shadowCorner.Parent = shadow

	-- Header
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, Constants.HeaderHeight)
	header.BackgroundTransparency = 1
	header.Parent = main
	self._header = header

	-- Logo
	local logo = Instance.new("ImageLabel")
	logo.Name = "Logo"
	logo.Size = UDim2.new(0, 18, 0, 18)
	logo.Position = UDim2.new(0, 12, 0.5, -9)
	logo.BackgroundTransparency = 1
	logo.Image = Icons.Get("Sakura")
	logo.ImageColor3 = theme:Get("Accent")
	logo.Parent = header

	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(0, 80, 1, 0)
	title.Position = UDim2.new(0, 36, 0, 0)
	title.Font = Enum.Font.GothamBold
	title.TextSize = Constants.TitleSize
	title.TextColor3 = theme:Get("Text")
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = self._name
	title.Parent = header

	-- Version
	local version = Instance.new("TextLabel")
	version.Name = "Version"
	version.BackgroundTransparency = 1
	version.Size = UDim2.new(0, 50, 1, 0)
	version.Position = UDim2.new(0, 100, 0, 0)
	version.Font = Enum.Font.Gotham
	version.TextSize = Constants.VersionSize
	version.TextColor3 = theme:Get("TextSecondary")
	version.TextXAlignment = Enum.TextXAlignment.Left
	version.Text = self._version
	version.Parent = header

	-- Window controls
	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "Close"
	closeBtn.Size = UDim2.new(0, 28, 0, 28)
	closeBtn.Position = UDim2.new(1, -34, 0.5, -14)
	closeBtn.BackgroundTransparency = 1
	closeBtn.Text = "×"
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextSize = 18
	closeBtn.TextColor3 = theme:Get("TextSecondary")
	closeBtn.Parent = header

	local minBtn = Instance.new("TextButton")
	minBtn.Name = "Minimize"
	minBtn.Size = UDim2.new(0, 28, 0, 28)
	minBtn.Position = UDim2.new(1, -62, 0.5, -14)
	minBtn.BackgroundTransparency = 1
	minBtn.Text = "–"
	minBtn.Font = Enum.Font.GothamBold
	minBtn.TextSize = 18
	minBtn.TextColor3 = theme:Get("TextSecondary")
	minBtn.Parent = header

	self._maid:Give(closeBtn.MouseButton1Click:Connect(function()
		if self._destroyed then return end
		self:Close()
	end))
	self._maid:Give(minBtn.MouseButton1Click:Connect(function()
		if self._destroyed then return end
		if self._minimized then
			self:Restore()
		else
			self:Minimize()
		end
	end))

	-- Drag region (header except buttons)
	local dragHandle = Instance.new("TextButton")
	dragHandle.Name = "DragHandle"
	dragHandle.Size = UDim2.new(1, -90, 1, 0)
	dragHandle.BackgroundTransparency = 1
	dragHandle.Text = ""
	dragHandle.Parent = header

	self._maid:Give(dragHandle.InputBegan:Connect(function(input)
		if self._destroyed then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			self._dragging = true
			self._dragStart = input.Position
			self._startPos = main.Position
		end
	end))

	self._maid:Give(UserInputService.InputChanged:Connect(function(input)
		if not self._dragging or self._destroyed then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			local delta = input.Position - self._dragStart
			local newX = self._startPos.X.Offset + delta.X
			local newY = self._startPos.Y.Offset + delta.Y

			local cam = workspace.CurrentCamera
			if cam then
				local vp = cam.ViewportSize
				local s = self._uiScale.Scale
				local w = Constants.WindowWidth * s
				local h = Constants.WindowHeight * s
				newX = math.clamp(newX, 0, math.max(0, vp.X - w))
				newY = math.clamp(newY, 0, math.max(0, vp.Y - h))
			end
			main.Position = UDim2.new(0, newX, 0, newY)
		end
	end))

	self._maid:Give(UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			self._dragging = false
		end
	end))

	-- Search bar
	local searchFrame = Instance.new("Frame")
	searchFrame.Name = "SearchBar"
	searchFrame.Size = UDim2.new(1, -24, 0, Constants.SearchHeight)
	searchFrame.Position = UDim2.new(0, 12, 0, Constants.HeaderHeight + 4)
	searchFrame.BackgroundColor3 = theme:Get("SurfaceSecondary")
	searchFrame.BorderSizePixel = 0
	searchFrame.Parent = main

	local searchCorner = Instance.new("UICorner")
	searchCorner.CornerRadius = UDim.new(0, Constants.SmallCornerRadius)
	searchCorner.Parent = searchFrame

	local searchIcon = Instance.new("ImageLabel")
	searchIcon.Name = "Icon"
	searchIcon.Size = UDim2.new(0, 14, 0, 14)
	searchIcon.Position = UDim2.new(0, 10, 0.5, -7)
	searchIcon.BackgroundTransparency = 1
	searchIcon.Image = Icons.Get("Search")
	searchIcon.ImageColor3 = theme:Get("TextSecondary")
	searchIcon.Parent = searchFrame

	local searchBox = Instance.new("TextBox")
	searchBox.Name = "Input"
	searchBox.Size = UDim2.new(1, -36, 1, 0)
	searchBox.Position = UDim2.new(0, 30, 0, 0)
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
		if self._destroyed or not self._search then return end
		self._search:SetQuery(searchBox.Text)
	end))

	-- Content container
	local contentContainer = Instance.new("Frame")
	contentContainer.Name = "ContentContainer"
	contentContainer.Size = UDim2.new(1, 0, 1, -(Constants.HeaderHeight + Constants.SearchHeight + 50))
	contentContainer.Position = UDim2.new(0, 0, 0, Constants.HeaderHeight + Constants.SearchHeight + 10)
	contentContainer.BackgroundTransparency = 1
	contentContainer.ClipsDescendants = true
	contentContainer.Parent = main
	self._contentContainer = contentContainer

	-- Bottom navigation (inside window)
	local bottomNav = Instance.new("Frame")
	bottomNav.Name = "BottomNav"
	bottomNav.Size = UDim2.new(0, 220, 0, 36)
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

	-- Secondary floating bar (outside window)
	local secondary = Instance.new("Frame")
	secondary.Name = "SecondaryBar"
	secondary.Size = UDim2.new(0, 200, 0, 34)
	secondary.Position = UDim2.new(0.5, -100, 0.5, Constants.WindowHeight / 2 + 20)
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

	local function createNavIcon(parent, iconName, selected)
		local btn = Instance.new("ImageButton")
		btn.Size = UDim2.new(0, 22, 0, 22)
		btn.BackgroundTransparency = 1
		btn.Image = Icons.Get(iconName)
		btn.ImageColor3 = selected and theme:Get("Accent") or theme:Get("TextSecondary")
		btn.Parent = parent
		return btn
	end

	self._navIcons = {
		createNavIcon(bottomNav, "Moss", true),
		createNavIcon(bottomNav, "Eye", false),
		createNavIcon(bottomNav, "Layers", false),
		createNavIcon(bottomNav, "Target", false),
		createNavIcon(bottomNav, "Settings", false),
	}

	self._secIcons = {
		createNavIcon(secondary, "Play", true),
		createNavIcon(secondary, "Cube", false),
		createNavIcon(secondary, "Users", false),
		createNavIcon(secondary, "Layers", false),
		createNavIcon(secondary, "Settings", false),
	}

	self._maid:Give(main)
	ActiveWindows[self._name] = self
	return self
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
	end

	return tab
end

function Window:_onTabSelected(tab)
	for _, t in ipairs(self._tabs) do
		if t ~= tab then
			t:Deselect()
		end
	end
	self._currentTab = tab
end

function Window:Open()
	if self._destroyed then return end
	if self._main then
		self._main.Visible = true
	end
	if self._secondary then
		self._secondary.Visible = true
	end
	if self._screenGui then
		self._screenGui.Enabled = true
	end
	self._visible = true
end

function Window:Close()
	if self._destroyed then return end
	self._visible = false
	if self._screenGui then
		self._screenGui.Enabled = false
	end
end

function Window:Toggle()
	if self._destroyed then return end
	if self._visible then
		self:Close()
	else
		self:Open()
	end
end

function Window:Minimize()
	if self._destroyed or self._minimized then return end
	self._minimized = true
	if self._contentContainer then
		self._contentContainer.Visible = false
	end
	if self._bottomNav then
		self._bottomNav.Visible = false
	end
	if self._main then
		self._main.Size = UDim2.new(0, Constants.WindowWidth, 0, Constants.HeaderHeight + 10)
	end
end

function Window:Restore()
	if self._destroyed or not self._minimized then return end
	self._minimized = false
	if self._contentContainer then
		self._contentContainer.Visible = true
	end
	if self._bottomNav then
		self._bottomNav.Visible = true
	end
	if self._main then
		self._main.Size = UDim2.new(0, Constants.WindowWidth, 0, Constants.WindowHeight)
	end
end

function Window:SetVisible(visible)
	if self._destroyed then return end
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
	if self._destroyed then return end
	self._scale = math.clamp(tonumber(scale) or 1, 0.5, 2)
	if self._uiScale then
		self._uiScale.Scale = self._scale
	end
end

function Window:Destroy()
	if self._destroyed then
		return
	end
	self._destroyed = true
	self._dragging = false

	-- Destroy tabs first
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
	self._searchBox = nil
	setmetatable(self, nil)
end

return Window
