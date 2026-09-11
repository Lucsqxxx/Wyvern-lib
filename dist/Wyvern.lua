--[[
	Wyvern UI Lib by Lucsqx
	Standalone distribution for loadstring / client environments.
	Version: 1.0.0

	Usage:
		local Wyvern = loadstring(source)()
		local Window = Wyvern:CreateWindow({ Name = "UI", Version = "v1.0.0" })

	Or from HttpGet (when available in the runtime):
		local Wyvern = loadstring(game:HttpGet("RAW_URL_TO_dist/Wyvern.lua"))()
]]

local __wyvern_modules = {}
local __wyvern_cache = {}
local __wyvern_loading = {}

local function __wyvern_define(name, factory)
	__wyvern_modules[name] = factory
end

local function __wyvern_require(name)
	if __wyvern_cache[name] ~= nil then
		return __wyvern_cache[name]
	end
	if __wyvern_loading[name] then
		error("[Wyvern] Circular require: " .. tostring(name), 2)
	end
	local factory = __wyvern_modules[name]
	if not factory then
		error("[Wyvern] Module not found: " .. tostring(name), 2)
	end
	__wyvern_loading[name] = true
	local result = factory()
	__wyvern_loading[name] = nil
	__wyvern_cache[name] = result
	return result
end


-- ===== BEGIN Core.Maid (Core/Maid.lua) =====

__wyvern_define("Core.Maid", function()
-- Maid.lua
-- Lightweight cleanup utility for connections, instances, and custom cleanup functions.

local Maid = {}
Maid.__index = Maid

function Maid.new()
	local self = setmetatable({
		_tasks = {},
		_id = 0,
	}, Maid)
	return self
end

function Maid:Give(task)
	if task == nil then
		return nil
	end

	self._id += 1
	local id = self._id
	self._tasks[id] = task
	return id
end

function Maid:Remove(id)
	local task = self._tasks[id]
	if not task then
		return
	end
	self._tasks[id] = nil
	self:_cleanupTask(task)
end

function Maid:_cleanupTask(task)
	local t = typeof(task)
	if t == "RBXScriptConnection" then
		task:Disconnect()
	elseif t == "Instance" then
		task:Destroy()
	elseif t == "function" then
		task()
	elseif t == "table" then
		if typeof(task.Destroy) == "function" then
			task:Destroy()
		elseif typeof(task.Disconnect) == "function" then
			task:Disconnect()
		end
	end
end

function Maid:DoCleaning()
	for id, task in pairs(self._tasks) do
		self._tasks[id] = nil
		self:_cleanupTask(task)
	end
end

function Maid:Destroy()
	self:DoCleaning()
	setmetatable(self, nil)
end

return Maid
end)

-- ===== END Core.Maid =====

-- ===== BEGIN Core.Signal (Core/Signal.lua) =====

__wyvern_define("Core.Signal", function()
-- Signal.lua
-- Lightweight signal implementation for event-driven communication.

local Signal = {}
Signal.__index = Signal

function Signal.new()
	local self = setmetatable({
		_connections = {},
		_id = 0,
	}, Signal)
	return self
end

function Signal:Connect(callback)
	assert(typeof(callback) == "function", "Signal:Connect expects a function")
	self._id += 1
	local id = self._id
	self._connections[id] = callback

	local connection = {
		Disconnect = function()
			self._connections[id] = nil
		end,
	}
	return connection
end

function Signal:Fire(...)
	for _, callback in pairs(self._connections) do
		task.spawn(callback, ...)
	end
end

function Signal:Wait()
	local thread = coroutine.running()
	local connection
	connection = self:Connect(function(...)
		connection:Disconnect()
		task.spawn(thread, ...)
	end)
	return coroutine.yield()
end

function Signal:Destroy()
	table.clear(self._connections)
	setmetatable(self, nil)
end

return Signal
end)

-- ===== END Core.Signal =====

-- ===== BEGIN Core.Constants (Core/Constants.lua) =====

__wyvern_define("Core.Constants", function()
-- Constants.lua
-- Centralized design tokens for consistent spacing, sizing and animation.

local Constants = {
	-- Window
	WindowWidth = 660,
	WindowHeight = 510,
	WindowCornerRadius = 12,
	HeaderHeight = 42,
	SearchHeight = 34,
	ContentPadding = 12,
	SectionSpacing = 10,
	ComponentSpacing = 8,

	-- Controls
	ControlHeight = 28,
	ButtonHeight = 28,
	ToggleSize = 22,
	SliderHeight = 6,
	SliderHandleSize = 14,
	KeybindWidth = 36,

	-- Typography
	TitleSize = 15,
	SectionTitleSize = 13,
	LabelSize = 12,
	ValueSize = 12,
	DescriptionSize = 11,
	VersionSize = 11,

	-- Borders & corners
	BorderThickness = 1,
	SmallCornerRadius = 6,
	MediumCornerRadius = 8,
	LargeCornerRadius = 12,
	PillRadius = 18,

	-- Animation
	HoverDuration = 0.12,
	PressDuration = 0.08,
	ToggleDuration = 0.15,
	PanelDuration = 0.2,

	-- ZIndex layers
	ZIndex = {
		Background = 1,
		Window = 10,
		Content = 20,
		Controls = 30,
		Navigation = 40,
		Tooltip = 100,
		Notification = 200,
	},
}

return Constants
end)

-- ===== END Core.Constants =====

-- ===== BEGIN Core.Animation (Core/Animation.lua) =====

__wyvern_define("Core.Animation", function()
-- Animation.lua
-- Centralized TweenService wrappers with sensible defaults.

local TweenService = game:GetService("TweenService")

local Animation = {}

local DEFAULT_INFO = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

function Animation.Tween(instance, properties, duration, easingStyle, easingDirection)
	if not instance or not properties then
		return nil
	end

	local info = TweenInfo.new(
		duration or 0.15,
		easingStyle or Enum.EasingStyle.Quad,
		easingDirection or Enum.EasingDirection.Out
	)

	local tween = TweenService:Create(instance, info, properties)
	tween:Play()
	return tween
end

function Animation.Hover(instance, properties)
	return Animation.Tween(instance, properties, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
end

function Animation.Press(instance, properties)
	return Animation.Tween(instance, properties, 0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
end

function Animation.Toggle(instance, properties)
	return Animation.Tween(instance, properties, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
end

function Animation.Panel(instance, properties)
	return Animation.Tween(instance, properties, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
end

return Animation
end)

-- ===== END Core.Animation =====

-- ===== BEGIN Core.Theme (Core/Theme.lua) =====

__wyvern_define("Core.Theme", function()
-- Theme.lua
-- Centralized theme management with hot-swap support.

local Theme = {}
Theme.__index = Theme

local DEFAULT_THEME = {
	Background = Color3.fromRGB(22, 18, 28),
	Surface = Color3.fromRGB(32, 26, 40),
	SurfaceSecondary = Color3.fromRGB(40, 32, 52),
	SurfaceHover = Color3.fromRGB(48, 38, 62),
	Accent = Color3.fromRGB(255, 105, 180),
	AccentHover = Color3.fromRGB(255, 130, 190),
	AccentPressed = Color3.fromRGB(220, 80, 150),
	Success = Color3.fromRGB(80, 220, 120),
	Text = Color3.fromRGB(240, 235, 245),
	TextSecondary = Color3.fromRGB(170, 160, 185),
	TextDisabled = Color3.fromRGB(110, 100, 125),
	Border = Color3.fromRGB(55, 45, 70),
	SliderTrack = Color3.fromRGB(45, 36, 58),
	SliderFill = Color3.fromRGB(255, 105, 180),
	ToggleOff = Color3.fromRGB(55, 45, 70),
	ToggleOn = Color3.fromRGB(255, 105, 180),
	Button = Color3.fromRGB(45, 36, 58),
	ButtonHover = Color3.fromRGB(58, 46, 75),
	NavBackground = Color3.fromRGB(28, 22, 36),
	Shadow = Color3.fromRGB(0, 0, 0),
}

function Theme.new(overrides)
	local self = setmetatable({
		_values = {},
		_listeners = {},
	}, Theme)

	for key, value in pairs(DEFAULT_THEME) do
		self._values[key] = value
	end

	if type(overrides) == "table" then
		for key, value in pairs(overrides) do
			if self._values[key] ~= nil and typeof(value) == "Color3" then
				self._values[key] = value
			end
		end
	end

	return self
end

function Theme:Get(key)
	return self._values[key]
end

function Theme:GetAll()
	local copy = {}
	for k, v in pairs(self._values) do
		copy[k] = v
	end
	return copy
end

function Theme:Set(key, value)
	if self._values[key] == nil then
		warn("[Wyvern Theme] Unknown theme key:", tostring(key))
		return
	end
	if typeof(value) ~= "Color3" then
		warn("[Wyvern Theme] Theme values must be Color3")
		return
	end
	self._values[key] = value
	self:_notify()
end

function Theme:Apply(overrides)
	if type(overrides) ~= "table" then
		return
	end
	for key, value in pairs(overrides) do
		if self._values[key] ~= nil and typeof(value) == "Color3" then
			self._values[key] = value
		end
	end
	self:_notify()
end

function Theme:OnChanged(callback)
	if type(callback) ~= "function" then
		return function() end
	end
	table.insert(self._listeners, callback)
	return function()
		local idx = table.find(self._listeners, callback)
		if idx then
			table.remove(self._listeners, idx)
		end
	end
end

function Theme:_notify()
	for _, callback in ipairs(self._listeners) do
		task.spawn(callback, self)
	end
end

function Theme:Destroy()
	table.clear(self._listeners)
	table.clear(self._values)
	setmetatable(self, nil)
end

return Theme
end)

-- ===== END Core.Theme =====

-- ===== BEGIN Icons.Registry (Icons/Registry.lua) =====

__wyvern_define("Icons.Registry", function()
-- Icons/Registry.lua
-- Centralized icon asset registry.
-- Placeholder IDs are used; replace with your own assets for production.
-- Invalid or missing icons fall back gracefully.

local FALLBACK = "rbxassetid://0"

local Icons = {
	Search = "rbxassetid://6031154871",
	Close = "rbxassetid://6031094670",
	Minimize = "rbxassetid://6031094678",
	Settings = "rbxassetid://6031280882",
	Eye = "rbxassetid://6031075931",
	Layers = "rbxassetid://6031075938",
	Target = "rbxassetid://6031094681",
	Play = "rbxassetid://6031229358",
	Cube = "rbxassetid://6031094667",
	Users = "rbxassetid://6034287594",
	Moss = "rbxassetid://6031094670",
	Sakura = "rbxassetid://6031094670",
	Check = "rbxassetid://6031094667",
	Lock = "rbxassetid://6031094678",
}

function Icons.Get(name)
	if type(name) ~= "string" then
		return FALLBACK
	end
	local id = Icons[name]
	if type(id) == "string" and id ~= "" then
		return id
	end
	return FALLBACK
end

function Icons.Set(name, assetId)
	if type(name) == "string" and type(assetId) == "string" then
		Icons[name] = assetId
	end
end

return Icons
end)

-- ===== END Icons.Registry =====

-- ===== BEGIN Themes.Sakura (Themes/Sakura.lua) =====

__wyvern_define("Themes.Sakura", function()
-- Themes/Sakura.lua
-- Color palette tuned to the reference screenshot.

return {
	Background = Color3.fromRGB(18, 14, 24),
	Surface = Color3.fromRGB(30, 24, 38),
	SurfaceSecondary = Color3.fromRGB(38, 30, 48),
	SurfaceHover = Color3.fromRGB(48, 38, 60),
	Accent = Color3.fromRGB(255, 110, 175),
	AccentHover = Color3.fromRGB(255, 135, 190),
	AccentPressed = Color3.fromRGB(220, 85, 150),
	Success = Color3.fromRGB(70, 220, 120),
	Text = Color3.fromRGB(235, 230, 245),
	TextSecondary = Color3.fromRGB(165, 155, 180),
	TextDisabled = Color3.fromRGB(100, 90, 115),
	Border = Color3.fromRGB(50, 40, 65),
	SliderTrack = Color3.fromRGB(40, 32, 52),
	SliderFill = Color3.fromRGB(255, 110, 175),
	ToggleOff = Color3.fromRGB(55, 45, 70),
	ToggleOn = Color3.fromRGB(255, 110, 175),
	Button = Color3.fromRGB(42, 34, 55),
	ButtonHover = Color3.fromRGB(55, 44, 70),
	NavBackground = Color3.fromRGB(25, 20, 32),
	Shadow = Color3.fromRGB(0, 0, 0),
}
end)

-- ===== END Themes.Sakura =====

-- ===== BEGIN Core.Component (Core/Component.lua) =====

__wyvern_define("Core.Component", function()
-- Component.lua
-- Base abstraction for all UI components.

local Maid = __wyvern_require("Core.Maid")
local Signal = __wyvern_require("Core.Signal")

local Component = {}
Component.__index = Component

function Component.new(config)
	config = config or {}
	local self = setmetatable({
		_maid = Maid.new(),
		_visible = true,
		_enabled = true,
		_destroyed = false,
		_name = config.Name or "Component",
		_value = config.Default,
		_callbacks = {},
		_searchKeywords = config.Keywords or {},
		ValueChanged = Signal.new(),
		Activated = Signal.new(),
	}, Component)

	if type(config.Callback) == "function" then
		self:OnChanged(config.Callback)
	end

	return self
end

function Component:Get()
	return self._value
end

function Component:Set(value)
	if self._destroyed then return end
	if self._value == value then
		return
	end
	self._value = value
	self.ValueChanged:Fire(value)
	for _, cb in ipairs(self._callbacks) do
		task.spawn(cb, value)
	end
end

function Component:OnChanged(callback)
	if type(callback) ~= "function" then
		return function() end
	end
	table.insert(self._callbacks, callback)
	return function()
		local idx = table.find(self._callbacks, callback)
		if idx then
			table.remove(self._callbacks, idx)
		end
	end
end

function Component:SetVisible(visible)
	if self._destroyed then return end
	self._visible = visible and true or false
	if self._instance and self._instance.Parent then
		self._instance.Visible = self._visible
	end
end

function Component:IsVisible()
	return self._visible
end

function Component:SetEnabled(enabled)
	if self._destroyed then return end
	self._enabled = enabled and true or false
end

function Component:IsEnabled()
	return self._enabled
end

function Component:GetName()
	return self._name
end

function Component:GetSearchKeywords()
	local keywords = { string.lower(tostring(self._name)) }
	for _, k in ipairs(self._searchKeywords) do
		table.insert(keywords, string.lower(tostring(k)))
	end
	return keywords
end

function Component:MatchesSearch(query)
	if not query or query == "" then
		return true
	end
	query = string.lower(tostring(query))
	for _, keyword in ipairs(self:GetSearchKeywords()) do
		if string.find(keyword, query, 1, true) then
			return true
		end
	end
	return false
end

function Component:Destroy()
	if self._destroyed then return end
	self._destroyed = true
	if self.ValueChanged then
		self.ValueChanged:Destroy()
	end
	if self.Activated then
		self.Activated:Destroy()
	end
	self._maid:Destroy()
	if self._instance then
		pcall(function()
			self._instance:Destroy()
		end)
		self._instance = nil
	end
	table.clear(self._callbacks)
	setmetatable(self, nil)
end

return Component
end)

-- ===== END Core.Component =====

-- ===== BEGIN Core.Input (Core/Input.lua) =====

__wyvern_define("Core.Input", function()
-- Input.lua
-- Centralized input management for keybinds.
-- Ignores keybinds while a TextBox is focused.

local UserInputService = game:GetService("UserInputService")
local Maid = __wyvern_require("Core.Maid")

local Input = {}
Input.__index = Input

function Input.new()
	local self = setmetatable({
		_maid = Maid.new(),
		_keybinds = {}, -- [KeyCode] = {callback, ...}
		_listeningForKeybind = nil,
		_destroyed = false,
	}, Input)

	self._maid:Give(UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if self._destroyed then return end
		if gameProcessed then return end

		-- Rebind listening takes priority
		if self._listeningForKeybind then
			if input.UserInputType == Enum.UserInputType.Keyboard then
				local comp = self._listeningForKeybind
				self._listeningForKeybind = nil
				if comp and not comp._destroyed then
					comp:Set(input.KeyCode)
				end
			end
			return
		end

		-- Do not fire keybinds while typing in a TextBox
		local focused = UserInputService:GetFocusedTextBox()
		if focused then
			return
		end

		if input.UserInputType == Enum.UserInputType.Keyboard then
			local binds = self._keybinds[input.KeyCode]
			if binds then
				for _, cb in ipairs(binds) do
					task.spawn(cb)
				end
			end
		end
	end))

	return self
end

function Input:RegisterKeybind(keyCode, callback)
	if self._destroyed or type(callback) ~= "function" then
		return function() end
	end
	if not self._keybinds[keyCode] then
		self._keybinds[keyCode] = {}
	end
	table.insert(self._keybinds[keyCode], callback)

	return function()
		local list = self._keybinds[keyCode]
		if list then
			local idx = table.find(list, callback)
			if idx then
				table.remove(list, idx)
			end
		end
	end
end

function Input:StartListening(component)
	if self._destroyed then return end
	self._listeningForKeybind = component
end

function Input:StopListening()
	self._listeningForKeybind = nil
end

function Input:Destroy()
	if self._destroyed then return end
	self._destroyed = true
	self._listeningForKeybind = nil
	table.clear(self._keybinds)
	self._maid:Destroy()
	setmetatable(self, nil)
end

return Input
end)

-- ===== END Core.Input =====

-- ===== BEGIN Core.Search (Core/Search.lua) =====

__wyvern_define("Core.Search", function()
-- Search.lua
-- Generic search registration and filtering.

local Signal = __wyvern_require("Core.Signal")

local Search = {}
Search.__index = Search

function Search.new()
	local self = setmetatable({
		_entries = {}, -- {component, section, keywords}
		_query = "",
		QueryChanged = Signal.new(),
	}, Search)
	return self
end

function Search:Register(component, section)
	table.insert(self._entries, {
		Component = component,
		Section = section,
		Keywords = component:GetSearchKeywords(),
	})
end

function Search:Unregister(component)
	for i = #self._entries, 1, -1 do
		if self._entries[i].Component == component then
			table.remove(self._entries, i)
		end
	end
end

function Search:SetQuery(query)
	self._query = string.lower(query or "")
	self.QueryChanged:Fire(self._query)

	-- Apply visibility
	for _, entry in ipairs(self._entries) do
		local matches = entry.Component:MatchesSearch(self._query)
		entry.Component:SetVisible(matches)
		-- Optionally hide empty sections – handled by section itself if needed
	end
end

function Search:GetQuery()
	return self._query
end

function Search:Clear()
	self:SetQuery("")
end

function Search:Destroy()
	self.QueryChanged:Destroy()
	table.clear(self._entries)
	setmetatable(self, nil)
end

return Search
end)

-- ===== END Core.Search =====

-- ===== BEGIN Core.Notification (Core/Notification.lua) =====

__wyvern_define("Core.Notification", function()
-- Notification.lua
-- Centralized toast/notification manager.

local TweenService = game:GetService("TweenService")
local Maid = __wyvern_require("Core.Maid")
local Constants = __wyvern_require("Core.Constants")

local Notification = {}
Notification.__index = Notification

local Active = {}
local MAX_STACK = 5

function Notification.new(parentGui, theme)
	local self = setmetatable({
		_maid = Maid.new(),
		_theme = theme,
		_parent = parentGui,
		_stack = {},
		_destroyed = false,
	}, Notification)

	local holder = Instance.new("Frame")
	holder.Name = "WyvernNotifications"
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.new(0, 300, 1, 0)
	holder.Position = UDim2.new(1, -320, 0, 20)
	holder.AnchorPoint = Vector2.new(0, 0)
	holder.Parent = parentGui
	self._holder = holder

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 8)
	layout.VerticalAlignment = Enum.VerticalAlignment.Top
	layout.Parent = holder

	self._maid:Give(holder)
	return self
end

function Notification:Notify(config)
	if self._destroyed then return end
	config = config or {}
	local title = config.Title or "Wyvern"
	local content = config.Content or config.Message or ""
	local duration = tonumber(config.Duration) or 3
	local theme = self._theme

	-- Limit stack
	while #self._stack >= MAX_STACK do
		local oldest = table.remove(self._stack, 1)
		if oldest and oldest.Destroy then
			pcall(function() oldest:Destroy() end)
		end
	end

	local card = Instance.new("Frame")
	card.Name = "Toast"
	card.BackgroundColor3 = theme:Get("Surface")
	card.BorderSizePixel = 0
	card.Size = UDim2.new(1, 0, 0, 0)
	card.AutomaticSize = Enum.AutomaticSize.Y
	card.BackgroundTransparency = 1
	card.Parent = self._holder

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = card

	local stroke = Instance.new("UIStroke")
	stroke.Color = theme:Get("Border")
	stroke.Thickness = 1
	stroke.Transparency = 0.4
	stroke.Parent = card

	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 10)
	pad.PaddingBottom = UDim.new(0, 10)
	pad.PaddingLeft = UDim.new(0, 12)
	pad.PaddingRight = UDim.new(0, 12)
	pad.Parent = card

	local titleLabel = Instance.new("TextLabel")
	titleLabel.BackgroundTransparency = 1
	titleLabel.Size = UDim2.new(1, -20, 0, 16)
	titleLabel.Font = Enum.Font.GothamMedium
	titleLabel.TextSize = 13
	titleLabel.TextColor3 = theme:Get("Text")
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Text = title
	titleLabel.Parent = card

	local body = Instance.new("TextLabel")
	body.BackgroundTransparency = 1
	body.Size = UDim2.new(1, 0, 0, 0)
	body.AutomaticSize = Enum.AutomaticSize.Y
	body.Position = UDim2.new(0, 0, 0, 18)
	body.Font = Enum.Font.Gotham
	body.TextSize = 12
	body.TextColor3 = theme:Get("TextSecondary")
	body.TextXAlignment = Enum.TextXAlignment.Left
	body.TextWrapped = true
	body.Text = content
	body.Parent = card

	local close = Instance.new("TextButton")
	close.Size = UDim2.new(0, 18, 0, 18)
	close.Position = UDim2.new(1, -18, 0, 0)
	close.BackgroundTransparency = 1
	close.Text = "×"
	close.Font = Enum.Font.GothamBold
	close.TextSize = 14
	close.TextColor3 = theme:Get("TextSecondary")
	close.Parent = card

	-- Fade in
	TweenService:Create(card, TweenInfo.new(0.2), { BackgroundTransparency = 0 }):Play()

	local function dismiss()
		local idx = table.find(self._stack, card)
		if idx then table.remove(self._stack, idx) end
		local tw = TweenService:Create(card, TweenInfo.new(0.18), { BackgroundTransparency = 1 })
		tw:Play()
		tw.Completed:Connect(function()
			pcall(function() card:Destroy() end)
		end)
	end

	close.MouseButton1Click:Connect(dismiss)

	table.insert(self._stack, card)

	if duration > 0 then
		task.delay(duration, function()
			if card and card.Parent then
				dismiss()
			end
		end)
	end

	return {
		Destroy = dismiss,
	}
end

function Notification:Destroy()
	if self._destroyed then return end
	self._destroyed = true
	for _, c in ipairs(self._stack) do
		pcall(function() c:Destroy() end)
	end
	table.clear(self._stack)
	self._maid:Destroy()
	setmetatable(self, nil)
end

return Notification
end)

-- ===== END Core.Notification =====

-- ===== BEGIN Components.Button (Components/Button.lua) =====

__wyvern_define("Components.Button", function()
-- Button.lua

local Component = __wyvern_require("Core.Component")
local Animation = __wyvern_require("Core.Animation")
local Constants = __wyvern_require("Core.Constants")

local Button = setmetatable({}, { __index = Component })
Button.__index = Button

function Button.new(config, parent, theme)
	local self = setmetatable(Component.new(config), Button)
	self._theme = theme

	local frame = Instance.new("TextButton")
	frame.Name = "Button_" .. (config.Name or "Button")
	frame.BackgroundColor3 = theme:Get("Button")
	frame.BorderSizePixel = 0
	frame.Size = UDim2.new(1, 0, 0, Constants.ButtonHeight)
	frame.AutoButtonColor = false
	frame.Text = ""
	frame.Parent = parent
	self._instance = frame

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, Constants.SmallCornerRadius)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color = theme:Get("Border")
	stroke.Thickness = Constants.BorderThickness
	stroke.Transparency = 0.5
	stroke.Parent = frame

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, 0, 1, 0)
	label.Font = Enum.Font.GothamMedium
	label.TextSize = Constants.LabelSize
	label.TextColor3 = theme:Get("Text")
	label.Text = config.Name or "Button"
	label.Parent = frame
	self._label = label

	self._maid:Give(frame.MouseEnter:Connect(function()
		if not self._enabled then return end
		Animation.Hover(frame, { BackgroundColor3 = theme:Get("ButtonHover") })
	end))

	self._maid:Give(frame.MouseLeave:Connect(function()
		if not self._enabled then return end
		Animation.Hover(frame, { BackgroundColor3 = theme:Get("Button") })
	end))

	self._maid:Give(frame.MouseButton1Down:Connect(function()
		if not self._enabled then return end
		Animation.Press(frame, { BackgroundColor3 = theme:Get("AccentPressed") })
	end))

	self._maid:Give(frame.MouseButton1Up:Connect(function()
		if not self._enabled then return end
		Animation.Hover(frame, { BackgroundColor3 = theme:Get("ButtonHover") })
	end))

	self._maid:Give(frame.MouseButton1Click:Connect(function()
		if not self._enabled then return end
		self.Activated:Fire()
		if config.Callback then
			task.spawn(config.Callback)
		end
	end))

	self._maid:Give(frame)
	return self
end

function Button:SetText(text)
	self._label.Text = text or ""
end

function Button:SetEnabled(enabled)
	self._enabled = enabled
	self._label.TextColor3 = enabled and self._theme:Get("Text") or self._theme:Get("TextDisabled")
	self._instance.BackgroundColor3 = enabled and self._theme:Get("Button") or self._theme:Get("SurfaceSecondary")
end

return Button
end)

-- ===== END Components.Button =====

-- ===== BEGIN Components.Toggle (Components/Toggle.lua) =====

__wyvern_define("Components.Toggle", function()
-- Toggle.lua
-- Square-ish toggle matching the reference (pink + check when on)

local Component = __wyvern_require("Core.Component")
local Animation = __wyvern_require("Core.Animation")
local Constants = __wyvern_require("Core.Constants")

local Toggle = setmetatable({}, { __index = Component })
Toggle.__index = Toggle

function Toggle.new(config, parent, theme)
	local self = setmetatable(Component.new(config), Toggle)
	self._theme = theme
	self._value = config.Default == true

	local container = Instance.new("Frame")
	container.Name = "Toggle_" .. (config.Name or "Toggle")
	container.BackgroundTransparency = 1
	container.Size = UDim2.new(1, 0, 0, Constants.ControlHeight)
	container.Parent = parent
	self._instance = container

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, -30, 1, 0)
	label.Position = UDim2.new(0, 0, 0, 0)
	label.Font = Enum.Font.Gotham
	label.TextSize = Constants.LabelSize
	label.TextColor3 = theme:Get("Text")
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = config.Name or "Toggle"
	label.Parent = container
	self._label = label

	-- Rounded square toggle (matches screenshot style)
	local switch = Instance.new("Frame")
	switch.Name = "Switch"
	switch.Size = UDim2.new(0, 22, 0, 22)
	switch.Position = UDim2.new(1, -22, 0.5, -11)
	switch.BackgroundColor3 = self._value and theme:Get("ToggleOn") or theme:Get("ToggleOff")
	switch.BorderSizePixel = 0
	switch.Parent = container
	self._switch = switch

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 5)
	corner.Parent = switch

	local stroke = Instance.new("UIStroke")
	stroke.Color = theme:Get("Border")
	stroke.Thickness = 1
	stroke.Transparency = self._value and 1 or 0.4
	stroke.Parent = switch
	self._stroke = stroke

	local check = Instance.new("TextLabel")
	check.Name = "Check"
	check.BackgroundTransparency = 1
	check.Size = UDim2.new(1, 0, 1, 0)
	check.Font = Enum.Font.GothamBold
	check.TextSize = 14
	check.TextColor3 = Color3.fromRGB(255, 255, 255)
	check.Text = self._value and "✓" or ""
	check.Parent = switch
	self._check = check

	local button = Instance.new("TextButton")
	button.Name = "Hitbox"
	button.BackgroundTransparency = 1
	button.Size = UDim2.new(1, 0, 1, 0)
	button.Text = ""
	button.Parent = container

	self._maid:Give(button.MouseButton1Click:Connect(function()
		if not self._enabled then return end
		self:Set(not self._value)
	end))

	self._maid:Give(container)
	return self
end

function Toggle:Set(value)
	value = value == true
	if self._value == value then return end
	self._value = value

	local theme = self._theme
	Animation.Toggle(self._switch, {
		BackgroundColor3 = value and theme:Get("ToggleOn") or theme:Get("ToggleOff"),
	})
	self._check.Text = value and "✓" or ""
	self._stroke.Transparency = value and 1 or 0.4

	self.ValueChanged:Fire(value)
	for _, cb in ipairs(self._callbacks) do
		task.spawn(cb, value)
	end
end

function Toggle:SetEnabled(enabled)
	self._enabled = enabled and true or false
	if self._label then
		self._label.TextColor3 = self._enabled and self._theme:Get("Text") or self._theme:Get("TextDisabled")
	end
	if self._switch then
		self._switch.BackgroundTransparency = self._enabled and 0 or 0.45
	end
end

function Toggle:Toggle()
	self:Set(not self._value)
end

function Toggle:Reset()
	self:Set(false)
end

return Toggle
end)

-- ===== END Components.Toggle =====

-- ===== BEGIN Components.Slider (Components/Slider.lua) =====

__wyvern_define("Components.Slider", function()
-- Slider.lua

local UserInputService = game:GetService("UserInputService")
local Component = __wyvern_require("Core.Component")
local Animation = __wyvern_require("Core.Animation")
local Constants = __wyvern_require("Core.Constants")
local Maid = __wyvern_require("Core.Maid")

local Slider = setmetatable({}, { __index = Component })
Slider.__index = Slider

function Slider.new(config, parent, theme)
	local self = setmetatable(Component.new(config), Slider)
	self._theme = theme
	self._min = config.Min or 0
	self._max = config.Max or 100
	self._increment = config.Increment or 1
	self._value = config.Default or self._min
	self._dragging = false

	local container = Instance.new("Frame")
	container.Name = "Slider_" .. (config.Name or "Slider")
	container.BackgroundTransparency = 1
	container.Size = UDim2.new(1, 0, 0, 40)
	container.Parent = parent
	self._instance = container

	local topRow = Instance.new("Frame")
	topRow.Name = "TopRow"
	topRow.BackgroundTransparency = 1
	topRow.Size = UDim2.new(1, 0, 0, 18)
	topRow.Parent = container

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, -40, 1, 0)
	label.Font = Enum.Font.Gotham
	label.TextSize = Constants.LabelSize
	label.TextColor3 = theme:Get("Text")
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = config.Name or "Slider"
	label.Parent = topRow
	self._label = label

	local valueLabel = Instance.new("TextLabel")
	valueLabel.Name = "Value"
	valueLabel.BackgroundTransparency = 1
	valueLabel.Size = UDim2.new(0, 36, 1, 0)
	valueLabel.Position = UDim2.new(1, -36, 0, 0)
	valueLabel.Font = Enum.Font.GothamMedium
	valueLabel.TextSize = Constants.ValueSize
	valueLabel.TextColor3 = theme:Get("TextSecondary")
	valueLabel.TextXAlignment = Enum.TextXAlignment.Right
	valueLabel.Text = tostring(self._value)
	valueLabel.Parent = topRow
	self._valueLabel = valueLabel

	local track = Instance.new("Frame")
	track.Name = "Track"
	track.Size = UDim2.new(1, 0, 0, Constants.SliderHeight)
	track.Position = UDim2.new(0, 0, 0, 26)
	track.BackgroundColor3 = theme:Get("SliderTrack")
	track.BorderSizePixel = 0
	track.Parent = container
	self._track = track

	local trackCorner = Instance.new("UICorner")
	trackCorner.CornerRadius = UDim.new(1, 0)
	trackCorner.Parent = track

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.new(0, 0, 1, 0)
	fill.BackgroundColor3 = theme:Get("SliderFill")
	fill.BorderSizePixel = 0
	fill.Parent = track
	self._fill = fill

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(1, 0)
	fillCorner.Parent = fill

	local handle = Instance.new("Frame")
	handle.Name = "Handle"
	handle.Size = UDim2.new(0, Constants.SliderHandleSize, 0, Constants.SliderHandleSize)
	handle.Position = UDim2.new(0, 0, 0.5, -Constants.SliderHandleSize / 2)
	handle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	handle.BorderSizePixel = 0
	handle.ZIndex = 2
	handle.Parent = track
	self._handle = handle

	local handleCorner = Instance.new("UICorner")
	handleCorner.CornerRadius = UDim.new(1, 0)
	handleCorner.Parent = handle

	local handleStroke = Instance.new("UIStroke")
	handleStroke.Color = theme:Get("Accent")
	handleStroke.Thickness = 1.5
	handleStroke.Parent = handle

	-- Hit area
	local hit = Instance.new("TextButton")
	hit.Name = "Hit"
	hit.BackgroundTransparency = 1
	hit.Size = UDim2.new(1, 0, 0, 20)
	hit.Position = UDim2.new(0, 0, 0, 18)
	hit.Text = ""
	hit.Parent = container

	local function updateVisual(value)
		local alpha = 0
		if self._max > self._min then
			alpha = math.clamp((value - self._min) / (self._max - self._min), 0, 1)
		end
		self._fill.Size = UDim2.new(alpha, 0, 1, 0)
		self._handle.Position = UDim2.new(alpha, -Constants.SliderHandleSize / 2, 0.5, -Constants.SliderHandleSize / 2)
		self._valueLabel.Text = tostring(value)
	end

	local function setFromAlpha(alpha)
		if self._destroyed then return end
		alpha = math.clamp(alpha, 0, 1)
		local range = self._max - self._min
		if range <= 0 then
			self:Set(self._min)
			return
		end
		local raw = self._min + range * alpha
		local stepped = math.floor(raw / self._increment + 0.5) * self._increment
		stepped = math.clamp(stepped, self._min, self._max)
		if self._increment >= 1 then
			stepped = math.floor(stepped + 0.5)
		else
			stepped = math.floor(stepped * 100 + 0.5) / 100
		end
		self:Set(stepped)
	end

	updateVisual(self._value)

	self._maid:Give(hit.MouseButton1Down:Connect(function()
		if not self._enabled or self._destroyed then return end
		self._dragging = true

		local conn
		conn = UserInputService.InputChanged:Connect(function(input)
			if not self._dragging or self._destroyed then return end
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				local absPos = track.AbsolutePosition
				local absSize = track.AbsoluteSize
				if absSize.X <= 0 then return end
				local rel = (input.Position.X - absPos.X) / absSize.X
				setFromAlpha(rel)
			end
		end)
		self._maid:Give(conn)

		local endConn
		endConn = UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				self._dragging = false
				if conn then pcall(function() conn:Disconnect() end) end
				if endConn then pcall(function() endConn:Disconnect() end) end
			end
		end)
		self._maid:Give(endConn)

		-- Immediate update on click
		local absPos = track.AbsolutePosition
		local absSize = track.AbsoluteSize
		if absSize.X > 0 then
			local mouse = UserInputService:GetMouseLocation()
			local rel = (mouse.X - absPos.X) / absSize.X
			setFromAlpha(rel)
		end
	end))

	self._maid:Give(container)
	return self
end

function Slider:Set(value)
	value = math.clamp(value, self._min, self._max)
	if self._value == value then return end
	self._value = value

	local alpha = 0
	if self._max > self._min then
		alpha = (value - self._min) / (self._max - self._min)
	end
	self._fill.Size = UDim2.new(alpha, 0, 1, 0)
	self._handle.Position = UDim2.new(alpha, -Constants.SliderHandleSize / 2, 0.5, -Constants.SliderHandleSize / 2)
	self._valueLabel.Text = tostring(value)

	self.ValueChanged:Fire(value)
	for _, cb in ipairs(self._callbacks) do
		task.spawn(cb, value)
	end
end

function Slider:SetRange(min, max)
	self._min = min
	self._max = max
	self:Set(math.clamp(self._value, min, max))
end

function Slider:SetEnabled(enabled)
	self._enabled = enabled
	self._label.TextColor3 = enabled and self._theme:Get("Text") or self._theme:Get("TextDisabled")
end


function Slider:SetMin(min)
	self:SetRange(min, self._max)
end

function Slider:SetMax(max)
	self:SetRange(self._min, max)
end

function Slider:SetIncrement(inc)
	self._increment = tonumber(inc) or 1
	self:Set(self._value)
end

function Slider:Reset()
	self:Set(self._min)
end

return Slider
end)

-- ===== END Components.Slider =====

-- ===== BEGIN Components.Keybind (Components/Keybind.lua) =====

__wyvern_define("Components.Keybind", function()
-- Keybind.lua

local Component = __wyvern_require("Core.Component")
local Animation = __wyvern_require("Core.Animation")
local Constants = __wyvern_require("Core.Constants")

local Keybind = setmetatable({}, { __index = Component })
Keybind.__index = Keybind

local function keyCodeToString(keyCode)
	if not keyCode then return "None" end
	local name = string.gsub(tostring(keyCode), "Enum.KeyCode.", "")
	return name
end

function Keybind.new(config, parent, theme, inputManager)
	local self = setmetatable(Component.new(config), Keybind)
	self._theme = theme
	self._input = inputManager
	self._value = config.Default or Enum.KeyCode.Unknown
	self._listening = false

	local container = Instance.new("Frame")
	container.Name = "Keybind_" .. (config.Name or "Keybind")
	container.BackgroundTransparency = 1
	container.Size = UDim2.new(1, 0, 0, Constants.ControlHeight)
	container.Parent = parent
	self._instance = container

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, -50, 1, 0)
	label.Font = Enum.Font.Gotham
	label.TextSize = Constants.LabelSize
	label.TextColor3 = theme:Get("Text")
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = config.Name or "Keybind"
	label.Parent = container
	self._label = label

	local keyBox = Instance.new("TextButton")
	keyBox.Name = "KeyBox"
	keyBox.Size = UDim2.new(0, 42, 0, 22)
	keyBox.Position = UDim2.new(1, -42, 0.5, -11)
	keyBox.BackgroundColor3 = theme:Get("SurfaceSecondary")
	keyBox.BorderSizePixel = 0
	keyBox.AutoButtonColor = false
	keyBox.Text = ""
	keyBox.Parent = container
	self._keyBox = keyBox

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 5)
	corner.Parent = keyBox

	local stroke = Instance.new("UIStroke")
	stroke.Color = theme:Get("Border")
	stroke.Thickness = 1
	stroke.Transparency = 0.4
	stroke.Parent = keyBox

	local keyText = Instance.new("TextLabel")
	keyText.Name = "KeyText"
	keyText.BackgroundTransparency = 1
	keyText.Size = UDim2.new(1, 0, 1, 0)
	keyText.Font = Enum.Font.GothamMedium
	keyText.TextSize = 11
	keyText.TextColor3 = theme:Get("Text")
	keyText.Text = keyCodeToString(self._value)
	keyText.Parent = keyBox
	self._keyText = keyText

	self._maid:Give(keyBox.MouseButton1Click:Connect(function()
		if not self._enabled then return end
		self._listening = true
		self._keyText.Text = "..."
		self._keyText.TextColor3 = theme:Get("Accent")
		if self._input then
			self._input:StartListening(self)
		end
	end))

	-- Register the actual keybind callback
	if self._input and self._value ~= Enum.KeyCode.Unknown then
		self._unbind = self._input:RegisterKeybind(self._value, function()
			if config.Callback then
				task.spawn(config.Callback)
			end
			self.Activated:Fire()
		end)
		self._maid:Give(self._unbind)
	end

	self._maid:Give(container)
	return self
end

function Keybind:Set(keyCode)
	if self._destroyed then return end
	if self._unbind then
		pcall(self._unbind)
		self._unbind = nil
	end

	self._value = keyCode
	self._listening = false
	if self._keyText then
		self._keyText.Text = keyCodeToString(keyCode)
		self._keyText.TextColor3 = self._theme:Get("Text")
	end

	if self._input and keyCode and keyCode ~= Enum.KeyCode.Unknown then
		self._unbind = self._input:RegisterKeybind(keyCode, function()
			if self._destroyed then return end
			for _, cb in ipairs(self._callbacks) do
				task.spawn(cb)
			end
			if self.Activated then
				self.Activated:Fire()
			end
		end)
		self._maid:Give(self._unbind)
	end

	if self.ValueChanged then
		self.ValueChanged:Fire(keyCode)
	end
end

function Keybind:SetEnabled(enabled)
	self._enabled = enabled
	self._label.TextColor3 = enabled and self._theme:Get("Text") or self._theme:Get("TextDisabled")
end

return Keybind
end)

-- ===== END Components.Keybind =====

-- ===== BEGIN Components.Label (Components/Label.lua) =====

__wyvern_define("Components.Label", function()
-- Label.lua
-- Simple text label / description component.

local Component = __wyvern_require("Core.Component")
local Constants = __wyvern_require("Core.Constants")

local Label = setmetatable({}, { __index = Component })
Label.__index = Label

function Label.new(config, parent, theme)
	local self = setmetatable(Component.new(config), Label)
	self._theme = theme

	local frame = Instance.new("Frame")
	frame.Name = "Label_" .. (config.Name or "Label")
	frame.BackgroundTransparency = 1
	frame.Size = UDim2.new(1, 0, 0, 18)
	frame.Parent = parent
	self._instance = frame

	local text = Instance.new("TextLabel")
	text.Name = "Text"
	text.BackgroundTransparency = 1
	text.Size = UDim2.new(1, 0, 1, 0)
	text.Font = Enum.Font.Gotham
	text.TextSize = Constants.DescriptionSize
	text.TextColor3 = theme:Get("TextSecondary")
	text.TextXAlignment = Enum.TextXAlignment.Left
	text.TextYAlignment = Enum.TextYAlignment.Center
	text.Text = config.Name or config.Text or ""
	text.TextWrapped = true
	text.Parent = frame
	self._text = text

	self._maid:Give(frame)
	return self
end

function Label:SetText(text)
	self._text.Text = text or ""
end

return Label
end)

-- ===== END Components.Label =====

-- ===== BEGIN Components.Dropdown (Components/Dropdown.lua) =====

__wyvern_define("Components.Dropdown", function()
-- Dropdown.lua
-- First-class single-select dropdown with popup list.

local UserInputService = game:GetService("UserInputService")
local Component = __wyvern_require("Core.Component")
local Animation = __wyvern_require("Core.Animation")
local Constants = __wyvern_require("Core.Constants")

local Dropdown = setmetatable({}, { __index = Component })
Dropdown.__index = Dropdown

local function deepCopy(t)
	local n = {}
	for i, v in ipairs(t) do
		n[i] = v
	end
	return n
end

function Dropdown.new(config, parent, theme)
	config = config or {}
	local self = setmetatable(Component.new(config), Dropdown)
	self._theme = theme
	self._options = deepCopy(config.Options or {})
	self._value = config.Default
	if self._value == nil and #self._options > 0 then
		self._value = self._options[1]
	end
	self._open = false
	self._optionButtons = {}

	local container = Instance.new("Frame")
	container.Name = "Dropdown_" .. (config.Name or "Dropdown")
	container.BackgroundTransparency = 1
	container.Size = UDim2.new(1, 0, 0, Constants.ControlHeight)
	container.ClipsDescendants = false
	container.Parent = parent
	self._instance = container

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(0.42, 0, 1, 0)
	label.Font = Enum.Font.Gotham
	label.TextSize = Constants.LabelSize
	label.TextColor3 = theme:Get("Text")
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = config.Name or "Dropdown"
	label.Parent = container
	self._label = label

	local box = Instance.new("TextButton")
	box.Name = "Box"
	box.Size = UDim2.new(0.55, 0, 0, 24)
	box.Position = UDim2.new(0.45, 0, 0.5, -12)
	box.BackgroundColor3 = theme:Get("SurfaceSecondary")
	box.BorderSizePixel = 0
	box.AutoButtonColor = false
	box.Text = ""
	box.Parent = container
	self._box = box

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 5)
	corner.Parent = box

	local stroke = Instance.new("UIStroke")
	stroke.Color = theme:Get("Border")
	stroke.Thickness = 1
	stroke.Transparency = 0.45
	stroke.Parent = box

	local text = Instance.new("TextLabel")
	text.Name = "Value"
	text.BackgroundTransparency = 1
	text.Size = UDim2.new(1, -22, 1, 0)
	text.Position = UDim2.new(0, 6, 0, 0)
	text.Font = Enum.Font.Gotham
	text.TextSize = 11
	text.TextColor3 = theme:Get("Text")
	text.TextXAlignment = Enum.TextXAlignment.Left
	text.TextTruncate = Enum.TextTruncate.AtEnd
	text.Text = tostring(self._value or "")
	text.Parent = box
	self._text = text

	local arrow = Instance.new("TextLabel")
	arrow.Name = "Arrow"
	arrow.BackgroundTransparency = 1
	arrow.Size = UDim2.new(0, 16, 1, 0)
	arrow.Position = UDim2.new(1, -18, 0, 0)
	arrow.Font = Enum.Font.GothamBold
	arrow.TextSize = 10
	arrow.TextColor3 = theme:Get("TextSecondary")
	arrow.Text = "▼"
	arrow.Parent = box
	self._arrow = arrow

	-- Popup list (parented to box so it follows)
	local popup = Instance.new("Frame")
	popup.Name = "Popup"
	popup.BackgroundColor3 = theme:Get("Surface")
	popup.BorderSizePixel = 0
	popup.Size = UDim2.new(1, 0, 0, 0)
	popup.Position = UDim2.new(0, 0, 1, 4)
	popup.Visible = false
	popup.ZIndex = 50
	popup.ClipsDescendants = true
	popup.Parent = box
	self._popup = popup

	local popupCorner = Instance.new("UICorner")
	popupCorner.CornerRadius = UDim.new(0, 6)
	popupCorner.Parent = popup

	local popupStroke = Instance.new("UIStroke")
	popupStroke.Color = theme:Get("Border")
	popupStroke.Thickness = 1
	popupStroke.Transparency = 0.3
	popupStroke.Parent = popup

	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "List"
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.Size = UDim2.new(1, 0, 1, 0)
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.ScrollBarThickness = 3
	scroll.ScrollBarImageColor3 = theme:Get("Border")
	scroll.ZIndex = 51
	scroll.Parent = popup
	self._scroll = scroll

	local listLayout = Instance.new("UIListLayout")
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, 2)
	listLayout.Parent = scroll

	local listPad = Instance.new("UIPadding")
	listPad.PaddingTop = UDim.new(0, 4)
	listPad.PaddingBottom = UDim.new(0, 4)
	listPad.PaddingLeft = UDim.new(0, 4)
	listPad.PaddingRight = UDim.new(0, 4)
	listPad.Parent = scroll

	self:_rebuildOptions()

	self._maid:Give(box.MouseButton1Click:Connect(function()
		if not self._enabled or self._destroyed then return end
		if self._open then
			self:Close()
		else
			self:Open()
		end
	end))

	-- Close when clicking elsewhere
	self._maid:Give(UserInputService.InputBegan:Connect(function(input)
		if not self._open or self._destroyed then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			-- simple close; more precise hit-test can be added later
			task.defer(function()
				if self._open and not self._destroyed then
					-- keep open only if still interacting with popup; for simplicity close after short delay is handled by option click
				end
			end)
		end
	end))

	self._maid:Give(container)
	return self
end

function Dropdown:_rebuildOptions()
	for _, btn in ipairs(self._optionButtons) do
		pcall(function() btn:Destroy() end)
	end
	table.clear(self._optionButtons)

	local theme = self._theme
	local maxVisible = math.min(#self._options, 6)
	local itemH = 24
	self._popup.Size = UDim2.new(1, 0, 0, maxVisible * (itemH + 2) + 10)

	for i, opt in ipairs(self._options) do
		local btn = Instance.new("TextButton")
		btn.Name = "Opt_" .. i
		btn.Size = UDim2.new(1, 0, 0, itemH)
		btn.BackgroundColor3 = (opt == self._value) and theme:Get("Accent") or theme:Get("SurfaceSecondary")
		btn.BackgroundTransparency = (opt == self._value) and 0.15 or 0.3
		btn.BorderSizePixel = 0
		btn.AutoButtonColor = false
		btn.Text = ""
		btn.LayoutOrder = i
		btn.ZIndex = 52
		btn.Parent = self._scroll

		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 4)
		c.Parent = btn

		local t = Instance.new("TextLabel")
		t.BackgroundTransparency = 1
		t.Size = UDim2.new(1, -8, 1, 0)
		t.Position = UDim2.new(0, 4, 0, 0)
		t.Font = Enum.Font.Gotham
		t.TextSize = 11
		t.TextColor3 = theme:Get("Text")
		t.TextXAlignment = Enum.TextXAlignment.Left
		t.Text = tostring(opt)
		t.ZIndex = 53
		t.Parent = btn

		self._maid:Give(btn.MouseButton1Click:Connect(function()
			if self._destroyed then return end
			self:Set(opt)
			self:Close()
		end))

		table.insert(self._optionButtons, btn)
	end
end

function Dropdown:Open()
	if self._destroyed or self._open or not self._enabled then return end
	self._open = true
	self._popup.Visible = true
	self._arrow.Text = "▲"
	self:_rebuildOptions()
end

function Dropdown:Close()
	if not self._open then return end
	self._open = false
	self._popup.Visible = false
	self._arrow.Text = "▼"
end

function Dropdown:Get()
	return self._value
end

function Dropdown:Set(value)
	if self._destroyed then return end
	self._value = value
	if self._text then
		self._text.Text = tostring(value or "")
	end
	self:_rebuildOptions()
	self.ValueChanged:Fire(value)
	for _, cb in ipairs(self._callbacks) do
		task.spawn(cb, value)
	end
end

function Dropdown:Select(value)
	self:Set(value)
end

function Dropdown:Add(option)
	if type(option) ~= "string" and type(option) ~= "number" then return end
	table.insert(self._options, option)
	if self._open then
		self:_rebuildOptions()
	end
end

function Dropdown:Remove(option)
	local idx = table.find(self._options, option)
	if idx then
		table.remove(self._options, idx)
		if self._value == option then
			self:Set(self._options[1])
		elseif self._open then
			self:_rebuildOptions()
		end
	end
end

function Dropdown:Clear()
	table.clear(self._options)
	self:Set(nil)
	self:Close()
end

function Dropdown:Refresh(options)
	if type(options) ~= "table" then return end
	self._options = deepCopy(options)
	if not table.find(self._options, self._value) then
		self._value = self._options[1]
	end
	if self._text then
		self._text.Text = tostring(self._value or "")
	end
	if self._open then
		self:_rebuildOptions()
	end
end

function Dropdown:SetEnabled(enabled)
	self._enabled = enabled and true or false
	if self._label then
		self._label.TextColor3 = self._enabled and self._theme:Get("Text") or self._theme:Get("TextDisabled")
	end
	if not self._enabled then
		self:Close()
	end
end

function Dropdown:Destroy()
	self:Close()
	Component.Destroy(self)
end

return Dropdown
end)

-- ===== END Components.Dropdown =====

-- ===== BEGIN Components.MultiDropdown (Components/MultiDropdown.lua) =====

__wyvern_define("Components.MultiDropdown", function()
-- MultiDropdown.lua
-- Multi-select dropdown.

local Component = __wyvern_require("Core.Component")
local Constants = __wyvern_require("Core.Constants")

local MultiDropdown = setmetatable({}, { __index = Component })
MultiDropdown.__index = MultiDropdown

local function deepCopy(t)
	local n = {}
	for i, v in ipairs(t) do
		n[i] = v
	end
	return n
end

local function copySet(t)
	local n = {}
	for _, v in ipairs(t or {}) do
		n[v] = true
	end
	return n
end

local function setToList(s)
	local n = {}
	for k in pairs(s) do
		table.insert(n, k)
	end
	table.sort(n, function(a, b) return tostring(a) < tostring(b) end)
	return n
end

function MultiDropdown.new(config, parent, theme)
	config = config or {}
	local self = setmetatable(Component.new(config), MultiDropdown)
	self._theme = theme
	self._options = deepCopy(config.Options or {})
	self._selected = copySet(config.Default or {})
	self._open = false
	self._optionButtons = {}

	local container = Instance.new("Frame")
	container.Name = "MultiDropdown_" .. (config.Name or "Multi")
	container.BackgroundTransparency = 1
	container.Size = UDim2.new(1, 0, 0, Constants.ControlHeight)
	container.Parent = parent
	self._instance = container

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(0.42, 0, 1, 0)
	label.Font = Enum.Font.Gotham
	label.TextSize = Constants.LabelSize
	label.TextColor3 = theme:Get("Text")
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = config.Name or "Multi"
	label.Parent = container
	self._label = label

	local box = Instance.new("TextButton")
	box.Name = "Box"
	box.Size = UDim2.new(0.55, 0, 0, 24)
	box.Position = UDim2.new(0.45, 0, 0.5, -12)
	box.BackgroundColor3 = theme:Get("SurfaceSecondary")
	box.BorderSizePixel = 0
	box.AutoButtonColor = false
	box.Text = ""
	box.Parent = container
	self._box = box

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 5)
	corner.Parent = box

	local text = Instance.new("TextLabel")
	text.BackgroundTransparency = 1
	text.Size = UDim2.new(1, -22, 1, 0)
	text.Position = UDim2.new(0, 6, 0, 0)
	text.Font = Enum.Font.Gotham
	text.TextSize = 11
	text.TextColor3 = theme:Get("Text")
	text.TextXAlignment = Enum.TextXAlignment.Left
	text.TextTruncate = Enum.TextTruncate.AtEnd
	text.Text = self:_displayText()
	text.Parent = box
	self._text = text

	local arrow = Instance.new("TextLabel")
	arrow.BackgroundTransparency = 1
	arrow.Size = UDim2.new(0, 16, 1, 0)
	arrow.Position = UDim2.new(1, -18, 0, 0)
	arrow.Font = Enum.Font.GothamBold
	arrow.TextSize = 10
	arrow.TextColor3 = theme:Get("TextSecondary")
	arrow.Text = "▼"
	arrow.Parent = box
	self._arrow = arrow

	local popup = Instance.new("Frame")
	popup.Name = "Popup"
	popup.BackgroundColor3 = theme:Get("Surface")
	popup.BorderSizePixel = 0
	popup.Size = UDim2.new(1, 0, 0, 0)
	popup.Position = UDim2.new(0, 0, 1, 4)
	popup.Visible = false
	popup.ZIndex = 50
	popup.ClipsDescendants = true
	popup.Parent = box
	self._popup = popup

	local popupCorner = Instance.new("UICorner")
	popupCorner.CornerRadius = UDim.new(0, 6)
	popupCorner.Parent = popup

	local scroll = Instance.new("ScrollingFrame")
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.Size = UDim2.new(1, 0, 1, 0)
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.ScrollBarThickness = 3
	scroll.ZIndex = 51
	scroll.Parent = popup
	self._scroll = scroll

	local listLayout = Instance.new("UIListLayout")
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, 2)
	listLayout.Parent = scroll

	local listPad = Instance.new("UIPadding")
	listPad.PaddingTop = UDim.new(0, 4)
	listPad.PaddingBottom = UDim.new(0, 4)
	listPad.PaddingLeft = UDim.new(0, 4)
	listPad.PaddingRight = UDim.new(0, 4)
	listPad.Parent = scroll

	self:_rebuildOptions()

	self._maid:Give(box.MouseButton1Click:Connect(function()
		if not self._enabled or self._destroyed then return end
		if self._open then self:Close() else self:Open() end
	end))

	self._maid:Give(container)
	return self
end

function MultiDropdown:_displayText()
	local list = setToList(self._selected)
	if #list == 0 then return "None" end
	if #list <= 2 then return table.concat(list, ", ") end
	return tostring(#list) .. " selected"
end

function MultiDropdown:_rebuildOptions()
	for _, btn in ipairs(self._optionButtons) do
		pcall(function() btn:Destroy() end)
	end
	table.clear(self._optionButtons)

	local theme = self._theme
	local maxVisible = math.min(#self._options, 6)
	local itemH = 24
	self._popup.Size = UDim2.new(1, 0, 0, maxVisible * (itemH + 2) + 10)

	for i, opt in ipairs(self._options) do
		local selected = self._selected[opt] == true
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, 0, 0, itemH)
		btn.BackgroundColor3 = selected and theme:Get("Accent") or theme:Get("SurfaceSecondary")
		btn.BackgroundTransparency = selected and 0.15 or 0.3
		btn.BorderSizePixel = 0
		btn.AutoButtonColor = false
		btn.Text = ""
		btn.LayoutOrder = i
		btn.ZIndex = 52
		btn.Parent = self._scroll

		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 4)
		c.Parent = btn

		local t = Instance.new("TextLabel")
		t.BackgroundTransparency = 1
		t.Size = UDim2.new(1, -8, 1, 0)
		t.Position = UDim2.new(0, 4, 0, 0)
		t.Font = Enum.Font.Gotham
		t.TextSize = 11
		t.TextColor3 = theme:Get("Text")
		t.TextXAlignment = Enum.TextXAlignment.Left
		t.Text = (selected and "✓ " or "   ") .. tostring(opt)
		t.ZIndex = 53
		t.Parent = btn

		self._maid:Give(btn.MouseButton1Click:Connect(function()
			if self._destroyed then return end
			if self._selected[opt] then
				self._selected[opt] = nil
			else
				self._selected[opt] = true
			end
			self._text.Text = self:_displayText()
			self:_rebuildOptions()
			local values = setToList(self._selected)
			self.ValueChanged:Fire(values)
			for _, cb in ipairs(self._callbacks) do
				task.spawn(cb, values)
			end
		end))

		table.insert(self._optionButtons, btn)
	end
end

function MultiDropdown:Open()
	if self._destroyed or self._open or not self._enabled then return end
	self._open = true
	self._popup.Visible = true
	self._arrow.Text = "▲"
	self:_rebuildOptions()
end

function MultiDropdown:Close()
	if not self._open then return end
	self._open = false
	self._popup.Visible = false
	self._arrow.Text = "▼"
end

function MultiDropdown:Get()
	return setToList(self._selected)
end

function MultiDropdown:Set(values)
	if self._destroyed then return end
	self._selected = copySet(values or {})
	if self._text then
		self._text.Text = self:_displayText()
	end
	if self._open then
		self:_rebuildOptions()
	end
	local list = setToList(self._selected)
	self.ValueChanged:Fire(list)
	for _, cb in ipairs(self._callbacks) do
		task.spawn(cb, list)
	end
end

function MultiDropdown:Select(option)
	self._selected[option] = true
	self:Set(setToList(self._selected))
end

function MultiDropdown:Deselect(option)
	self._selected[option] = nil
	self:Set(setToList(self._selected))
end

function MultiDropdown:Add(option)
	table.insert(self._options, option)
	if self._open then self:_rebuildOptions() end
end

function MultiDropdown:Remove(option)
	local idx = table.find(self._options, option)
	if idx then table.remove(self._options, idx) end
	self._selected[option] = nil
	if self._text then self._text.Text = self:_displayText() end
	if self._open then self:_rebuildOptions() end
end

function MultiDropdown:Clear()
	table.clear(self._selected)
	self:Set({})
	self:Close()
end

function MultiDropdown:Refresh(options)
	if type(options) ~= "table" then return end
	self._options = deepCopy(options)
	-- keep only still-valid selections
	local nextSel = {}
	for _, o in ipairs(self._options) do
		if self._selected[o] then nextSel[o] = true end
	end
	self._selected = nextSel
	if self._text then self._text.Text = self:_displayText() end
	if self._open then self:_rebuildOptions() end
end

function MultiDropdown:SetEnabled(enabled)
	self._enabled = enabled and true or false
	if not self._enabled then self:Close() end
end

function MultiDropdown:Destroy()
	self:Close()
	Component.Destroy(self)
end

return MultiDropdown
end)

-- ===== END Components.MultiDropdown =====

-- ===== BEGIN Components.Textbox (Components/Textbox.lua) =====

__wyvern_define("Components.Textbox", function()
-- Textbox.lua

local Component = __wyvern_require("Core.Component")
local Constants = __wyvern_require("Core.Constants")

local Textbox = setmetatable({}, { __index = Component })
Textbox.__index = Textbox

function Textbox.new(config, parent, theme)
	local self = setmetatable(Component.new(config), Textbox)
	self._theme = theme
	self._value = config.Default or ""

	local container = Instance.new("Frame")
	container.Name = "Textbox_" .. (config.Name or "Textbox")
	container.BackgroundTransparency = 1
	container.Size = UDim2.new(1, 0, 0, Constants.ControlHeight + 4)
	container.Parent = parent
	self._instance = container

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, 0, 0, 16)
	label.Font = Enum.Font.Gotham
	label.TextSize = Constants.LabelSize
	label.TextColor3 = theme:Get("Text")
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = config.Name or "Textbox"
	label.Parent = container

	local box = Instance.new("TextBox")
	box.Name = "Input"
	box.Size = UDim2.new(1, 0, 0, 24)
	box.Position = UDim2.new(0, 0, 0, 18)
	box.BackgroundColor3 = theme:Get("SurfaceSecondary")
	box.BorderSizePixel = 0
	box.Font = Enum.Font.Gotham
	box.TextSize = 12
	box.TextColor3 = theme:Get("Text")
	box.PlaceholderText = config.Placeholder or ""
	box.PlaceholderColor3 = theme:Get("TextDisabled")
	box.Text = self._value
	box.ClearTextOnFocus = false
	box.Parent = container
	self._box = box

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 5)
	corner.Parent = box

	self._maid:Give(box.FocusLost:Connect(function()
		self:Set(box.Text)
	end))

	self._maid:Give(container)
	return self
end

function Textbox:Set(value)
	self._value = value or ""
	self._box.Text = self._value
	self.ValueChanged:Fire(self._value)
	for _, cb in ipairs(self._callbacks) do
		task.spawn(cb, self._value)
	end
end

return Textbox
end)

-- ===== END Components.Textbox =====

-- ===== BEGIN Components.ColorPicker (Components/ColorPicker.lua) =====

__wyvern_define("Components.ColorPicker", function()
-- ColorPicker.lua (basic hue cycle for demonstration)

local Component = __wyvern_require("Core.Component")
local Constants = __wyvern_require("Core.Constants")

local ColorPicker = setmetatable({}, { __index = Component })
ColorPicker.__index = ColorPicker

function ColorPicker.new(config, parent, theme)
	local self = setmetatable(Component.new(config), ColorPicker)
	self._theme = theme
	self._value = config.Default or Color3.fromRGB(255, 110, 175)

	local container = Instance.new("Frame")
	container.Name = "ColorPicker_" .. (config.Name or "Color")
	container.BackgroundTransparency = 1
	container.Size = UDim2.new(1, 0, 0, Constants.ControlHeight)
	container.Parent = parent
	self._instance = container

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, -36, 1, 0)
	label.Font = Enum.Font.Gotham
	label.TextSize = Constants.LabelSize
	label.TextColor3 = theme:Get("Text")
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = config.Name or "Color"
	label.Parent = container

	local swatch = Instance.new("TextButton")
	swatch.Name = "Swatch"
	swatch.Size = UDim2.new(0, 28, 0, 20)
	swatch.Position = UDim2.new(1, -28, 0.5, -10)
	swatch.BackgroundColor3 = self._value
	swatch.BorderSizePixel = 0
	swatch.Text = ""
	swatch.AutoButtonColor = false
	swatch.Parent = container
	self._swatch = swatch

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = swatch

	local hues = {
		Color3.fromRGB(255, 110, 175),
		Color3.fromRGB(80, 180, 255),
		Color3.fromRGB(80, 220, 120),
		Color3.fromRGB(255, 180, 60),
		Color3.fromRGB(180, 100, 255),
		Color3.fromRGB(255, 80, 80),
	}
	local idx = 1

	self._maid:Give(swatch.MouseButton1Click:Connect(function()
		if not self._enabled then return end
		idx = (idx % #hues) + 1
		self:Set(hues[idx])
	end))

	self._maid:Give(container)
	return self
end

function ColorPicker:Set(color)
	self._value = color
	self._swatch.BackgroundColor3 = color
	self.ValueChanged:Fire(color)
	for _, cb in ipairs(self._callbacks) do
		task.spawn(cb, color)
	end
end

return ColorPicker
end)

-- ===== END Components.ColorPicker =====

-- ===== BEGIN Components.Divider (Components/Divider.lua) =====

__wyvern_define("Components.Divider", function()
-- Divider.lua

local Component = __wyvern_require("Core.Component")

local Divider = setmetatable({}, { __index = Component })
Divider.__index = Divider

function Divider.new(config, parent, theme)
	local self = setmetatable(Component.new(config or {}), Divider)

	local frame = Instance.new("Frame")
	frame.Name = "Divider"
	frame.BackgroundColor3 = theme:Get("Border")
	frame.BackgroundTransparency = 0.4
	frame.BorderSizePixel = 0
	frame.Size = UDim2.new(1, 0, 0, 1)
	frame.Parent = parent
	self._instance = frame
	self._maid:Give(frame)
	return self
end

return Divider
end)

-- ===== END Components.Divider =====

-- ===== BEGIN Core.Section (Core/Section.lua) =====

__wyvern_define("Core.Section", function()
-- Section.lua
-- Reusable card/section that hosts components.

local Maid = __wyvern_require("Core.Maid")
local Constants = __wyvern_require("Core.Constants")

local Button = __wyvern_require("Components.Button")
local Toggle = __wyvern_require("Components.Toggle")
local Slider = __wyvern_require("Components.Slider")
local Keybind = __wyvern_require("Components.Keybind")
local Label = __wyvern_require("Components.Label")
local Dropdown = __wyvern_require("Components.Dropdown")
local MultiDropdown = __wyvern_require("Components.MultiDropdown")
local Textbox = __wyvern_require("Components.Textbox")
local ColorPicker = __wyvern_require("Components.ColorPicker")
local Divider = __wyvern_require("Components.Divider")

local Section = {}
Section.__index = Section

function Section.new(config, parent, theme, search, inputManager)
	local self = setmetatable({
		_maid = Maid.new(),
		_theme = theme,
		_search = search,
		_input = inputManager,
		_name = config.Name or "Section",
		_components = {},
	}, Section)

	local card = Instance.new("Frame")
	card.Name = "Section_" .. self._name
	card.BackgroundColor3 = theme:Get("Surface")
	card.BorderSizePixel = 0
	card.Size = UDim2.new(1, 0, 0, 0) -- auto size later
	card.AutomaticSize = Enum.AutomaticSize.Y
	card.Parent = parent
	self._instance = card

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, Constants.MediumCornerRadius)
	corner.Parent = card

	local stroke = Instance.new("UIStroke")
	stroke.Color = theme:Get("Border")
	stroke.Thickness = 1
	stroke.Transparency = 0.55
	stroke.Parent = card

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 10)
	padding.PaddingBottom = UDim.new(0, 10)
	padding.PaddingLeft = UDim.new(0, 12)
	padding.PaddingRight = UDim.new(0, 12)
	padding.Parent = card

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, Constants.ComponentSpacing)
	layout.Parent = card

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, 0, 0, 18)
	title.Font = Enum.Font.GothamMedium
	title.TextSize = Constants.SectionTitleSize
	title.TextColor3 = theme:Get("Text")
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = self._name
	title.LayoutOrder = 0
	title.Parent = card
	self._title = title

	self._maid:Give(card)
	return self
end

function Section:_addComponent(comp)
	table.insert(self._components, comp)
	if self._search then
		self._search:Register(comp, self)
	end
	return comp
end

function Section:CreateButton(config)
	local comp = Button.new(config, self._instance, self._theme)
	comp._instance.LayoutOrder = #self._components + 1
	return self:_addComponent(comp)
end

function Section:CreateToggle(config)
	local comp = Toggle.new(config, self._instance, self._theme)
	comp._instance.LayoutOrder = #self._components + 1
	return self:_addComponent(comp)
end

function Section:CreateSlider(config)
	local comp = Slider.new(config, self._instance, self._theme)
	comp._instance.LayoutOrder = #self._components + 1
	return self:_addComponent(comp)
end

function Section:CreateKeybind(config)
	local comp = Keybind.new(config, self._instance, self._theme, self._input)
	comp._instance.LayoutOrder = #self._components + 1
	return self:_addComponent(comp)
end

function Section:CreateLabel(config)
	local comp = Label.new(config, self._instance, self._theme)
	comp._instance.LayoutOrder = #self._components + 1
	return self:_addComponent(comp)
end

function Section:CreateDropdown(config)
	local comp = Dropdown.new(config, self._instance, self._theme)
	comp._instance.LayoutOrder = #self._components + 1
	return self:_addComponent(comp)
end

function Section:CreateMultiDropdown(config)
	local comp = MultiDropdown.new(config, self._instance, self._theme)
	comp._instance.LayoutOrder = #self._components + 1
	return self:_addComponent(comp)
end

function Section:CreateTextbox(config)
	local comp = Textbox.new(config, self._instance, self._theme)
	comp._instance.LayoutOrder = #self._components + 1
	return self:_addComponent(comp)
end

-- Alias for developer expectation
function Section:CreateInput(config)
	return self:CreateTextbox(config)
end

function Section:CreateColorPicker(config)
	local comp = ColorPicker.new(config, self._instance, self._theme)
	comp._instance.LayoutOrder = #self._components + 1
	return self:_addComponent(comp)
end

function Section:CreateDivider(config)
	local comp = Divider.new(config, self._instance, self._theme)
	comp._instance.LayoutOrder = #self._components + 1
	return self:_addComponent(comp)
end

-- Simple status indicators row (Header Preview style)
function Section:CreateIndicators(config)
	config = config or {}
	local container = Instance.new("Frame")
	container.Name = "Indicators"
	container.BackgroundTransparency = 1
	container.Size = UDim2.new(1, 0, 0, 22)
	container.LayoutOrder = #self._components + 1
	container.Parent = self._instance

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, -60, 1, 0)
	label.Font = Enum.Font.Gotham
	label.TextSize = 12
	label.TextColor3 = self._theme:Get("Text")
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = config.Name or "Preview"
	label.Parent = container

	local colors = config.Colors or {
		Color3.fromRGB(70, 220, 120),
		Color3.fromRGB(55, 45, 70),
	}

	for i, color in ipairs(colors) do
		local box = Instance.new("Frame")
		box.Size = UDim2.new(0, 16, 0, 16)
		box.Position = UDim2.new(1, -20 - (i - 1) * 22, 0.5, -8)
		box.BackgroundColor3 = color
		box.BorderSizePixel = 0
		box.Parent = container

		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 4)
		c.Parent = box
	end

	self._maid:Give(container)
	return container
end

function Section:SetVisible(visible)
	self._instance.Visible = visible
end

function Section:Destroy()
	for _, comp in ipairs(self._components) do
		comp:Destroy()
	end
	self._maid:Destroy()
	setmetatable(self, nil)
end

return Section
end)

-- ===== END Core.Section =====

-- ===== BEGIN Core.Tab (Core/Tab.lua) =====

__wyvern_define("Core.Tab", function()
-- Tab.lua

local Maid = __wyvern_require("Core.Maid")
local Section = __wyvern_require("Core.Section")
local Constants = __wyvern_require("Core.Constants")
local Icons = __wyvern_require("Icons.Registry")

local Tab = {}
Tab.__index = Tab

function Tab.new(config, window, theme, search, inputManager)
	local self = setmetatable({
		_maid = Maid.new(),
		_window = window,
		_theme = theme,
		_search = search,
		_input = inputManager,
		_name = config.Name or "Tab",
		_icon = config.Icon or "Settings",
		_selected = false,
		_sections = {},
	}, Tab)

	-- Content frame (two-column capable)
	local content = Instance.new("ScrollingFrame")
	content.Name = "TabContent_" .. self._name
	content.BackgroundTransparency = 1
	content.BorderSizePixel = 0
	content.Size = UDim2.new(1, 0, 1, 0)
	content.CanvasSize = UDim2.new(0, 0, 0, 0)
	content.AutomaticCanvasSize = Enum.AutomaticSize.Y
	content.ScrollBarThickness = 3
	content.ScrollBarImageColor3 = theme:Get("Border")
	content.Visible = false
	content.Parent = window._contentContainer
	self._content = content

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 8)
	padding.PaddingBottom = UDim.new(0, 60) -- space for bottom nav
	padding.PaddingLeft = UDim.new(0, 10)
	padding.PaddingRight = UDim.new(0, 10)
	padding.Parent = content

	-- Two column layout
	local columns = Instance.new("Frame")
	columns.Name = "Columns"
	columns.BackgroundTransparency = 1
	columns.Size = UDim2.new(1, 0, 0, 0)
	columns.AutomaticSize = Enum.AutomaticSize.Y
	columns.Parent = content
	self._columns = columns

	local left = Instance.new("Frame")
	left.Name = "LeftColumn"
	left.BackgroundTransparency = 1
	left.Size = UDim2.new(0.5, -6, 0, 0)
	left.AutomaticSize = Enum.AutomaticSize.Y
	left.Parent = columns
	self._left = left

	local leftLayout = Instance.new("UIListLayout")
	leftLayout.SortOrder = Enum.SortOrder.LayoutOrder
	leftLayout.Padding = UDim.new(0, Constants.SectionSpacing)
	leftLayout.Parent = left

	local right = Instance.new("Frame")
	right.Name = "RightColumn"
	right.BackgroundTransparency = 1
	right.Size = UDim2.new(0.5, -6, 0, 0)
	right.Position = UDim2.new(0.5, 6, 0, 0)
	right.AutomaticSize = Enum.AutomaticSize.Y
	right.Parent = columns
	self._right = right

	local rightLayout = Instance.new("UIListLayout")
	rightLayout.SortOrder = Enum.SortOrder.LayoutOrder
	rightLayout.Padding = UDim.new(0, Constants.SectionSpacing)
	rightLayout.Parent = right

	self._maid:Give(content)
	return self
end

function Tab:CreateSection(config)
	-- Alternate columns for visual balance if not specified
	local target = self._left
	if config.Column == "Right" or (#self._sections % 2 == 1 and config.Column ~= "Left") then
		target = self._right
	end
	if config.Column == "Left" then
		target = self._left
	end

	local section = Section.new(config, target, self._theme, self._search, self._input)
	section._instance.LayoutOrder = #self._sections + 1
	table.insert(self._sections, section)
	return section
end

function Tab:Select()
	if self._selected then return end
	self._selected = true
	self._content.Visible = true
	if self._window then
		self._window:_onTabSelected(self)
	end
end

function Tab:Deselect()
	self._selected = false
	self._content.Visible = false
end

function Tab:IsSelected()
	return self._selected
end

function Tab:SetVisible(visible)
	self._content.Visible = visible and self._selected
end

function Tab:Destroy()
	for _, section in ipairs(self._sections) do
		section:Destroy()
	end
	self._maid:Destroy()
	setmetatable(self, nil)
end

return Tab
end)

-- ===== END Core.Tab =====

-- ===== BEGIN Core.Window (Core/Window.lua) =====

__wyvern_define("Core.Window", function()
-- Window.lua
-- Main floating window with header, search, content, navigation.
-- Safe client-side parenting with CoreGui fallback.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local Maid = __wyvern_require("Core.Maid")
local Tab = __wyvern_require("Core.Tab")
local Search = __wyvern_require("Core.Search")
local Input = __wyvern_require("Core.Input")
local Animation = __wyvern_require("Core.Animation")
local Constants = __wyvern_require("Core.Constants")
local Icons = __wyvern_require("Icons.Registry")
local Notification = __wyvern_require("Core.Notification")

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

	-- Notification manager
	self._notifications = Notification.new(screenGui, theme)
	self._maid:Give(function()
		if self._notifications then
			self._notifications:Destroy()
			self._notifications = nil
		end
	end)

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


function Window:Notify(config)
	if self._destroyed or not self._notifications then return end
	return self._notifications:Notify(config)
end

function Window:SetTitle(title)
	if self._destroyed then return end
	self._name = tostring(title or self._name)
	local titleLabel = self._header and self._header:FindFirstChild("Title")
	if titleLabel then
		titleLabel.Text = self._name
	end
end

function Window:SetVersion(version)
	if self._destroyed then return end
	self._version = tostring(version or self._version)
	local ver = self._header and self._header:FindFirstChild("Version")
	if ver then
		ver.Text = self._version
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
end)

-- ===== END Core.Window =====

-- ===== BEGIN init (init.lua) =====

__wyvern_define("init", function()
--[[
	Wyvern UI Lib by Lucsqx
	A production-quality, reusable Roblox Luau UI framework.

	Version: 1.0.0

	Usage:
		local Wyvern = require(path.To.Wyvern)
		local Window = Wyvern:CreateWindow({
			Name = "My UI",
			Version = "1.0.0",
		})
]]

local Theme = __wyvern_require("Core.Theme")
local Window = __wyvern_require("Core.Window")
local Constants = __wyvern_require("Core.Constants")
local Icons = __wyvern_require("Icons.Registry")
local SakuraTheme = __wyvern_require("Themes.Sakura")

local Wyvern = {
	_version = "1.0.0",
	_theme = nil,
	_scale = 1,
	Icons = Icons,
	Constants = Constants,
	Version = "1.0.0",
}

function Wyvern:CreateWindow(config)
	config = config or {}
	if type(config) ~= "table" then
		error("[Wyvern] CreateWindow expects a table config", 2)
	end
	if not self._theme then
		self._theme = Theme.new(SakuraTheme)
	end
	return Window.new(config, self._theme, self._scale)
end

function Wyvern:SetTheme(themeTable)
	if type(themeTable) ~= "table" then
		warn("[Wyvern] SetTheme expects a table of Color3 values")
		return
	end
	if not self._theme then
		self._theme = Theme.new(themeTable)
	else
		self._theme:Apply(themeTable)
	end
end

function Wyvern:GetTheme()
	return self._theme
end

function Wyvern:SetScale(scale)
	self._scale = math.clamp(tonumber(scale) or 1, 0.5, 2)
end

function Wyvern:GetScale()
	return self._scale
end

-- Convenience export
Wyvern.Theme = Theme

-- Convenience: notify through the most recently created window if available
local _lastWindow = nil
local _origCreate = Wyvern.CreateWindow
function Wyvern:CreateWindow(config)
	local win = _origCreate(self, config)
	_lastWindow = win
	return win
end

function Wyvern:Notify(config)
	if _lastWindow and not _lastWindow._destroyed then
		return _lastWindow:Notify(config)
	end
	warn("[Wyvern] Notify: no active window")
end

return Wyvern
end)

-- ===== END init =====


-- Bootstrap public API
local Wyvern = __wyvern_require("init")

-- Repeated-execution guard (optional shared marker)
local ok, ss = pcall(function()
	return game:GetService("Players")
end)
if ok then
	-- soft marker only; Window still has ActiveWindows registry
	if type(getfenv) == "function" then
		local env = getfenv(0)
		if type(env) == "table" then
			env.__WYVERN_LOADED = true
			env.__WYVERN_VERSION = Wyvern.Version or "1.0.0"
		end
	end
end

return Wyvern
