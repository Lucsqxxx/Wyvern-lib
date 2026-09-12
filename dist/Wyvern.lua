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
		Overlay = 80,
		Dropdown = 90,
		Tooltip = 100,
		Modal = 150,
		Notification = 200,
	},
	DragThreshold = 4, -- pixels before a press becomes a drag

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

-- ===== BEGIN Icons.AssetIds (Icons/AssetIds.lua) =====

__wyvern_define("Icons.AssetIds", function()
-- Icons/AssetIds.lua
-- Verified Roblox image ContentIds only.
-- Leave empty until each PNG in assets/icons/ is uploaded to Roblox Creator
-- and the real asset ID is confirmed. NEVER invent placeholder IDs.

-- Format: Name = "rbxassetid://YOUR_REAL_ID"
return {
	-- Search = "rbxassetid://...",
	-- Back = "rbxassetid://...",
	-- Minimize = "rbxassetid://...",
	-- Close = "rbxassetid://...",
	-- Check = "rbxassetid://...",
	-- Settings = "rbxassetid://...",
}
end)

-- ===== END Icons.AssetIds =====

-- ===== BEGIN Icons.AssetProvider (Icons/AssetProvider.lua) =====

__wyvern_define("Icons.AssetProvider", function()
-- Icons/AssetProvider.lua
-- Pipeline: GitHub PNG → HttpGet → writefile → getcustomasset → ContentId
-- Matches executor custom-asset loading (Wyvern Spy style).

local REPO_RAW = "https://raw.githubusercontent.com/Lucsqxxx/Wyvern-lib/main/assets/icons"
local CACHE_DIR = "Wyvern UI Lib/assets/icons"

local FILE_MAP = {
	Back = "back.png",
	Forward = "forward.png",
	ChevronLeft = "chevron_left.png",
	ChevronRight = "chevron_right.png",
	ChevronDown = "chevron_down.png",
	ChevronUp = "chevron_up.png",
	Minimize = "minimize.png",
	Maximize = "maximize.png",
	Fullscreen = "fullscreen.png",
	Close = "close.png",
	Search = "search.png",
	Eye = "eye.png",
	Check = "check.png",
	CheckboxEmpty = "checkbox_empty.png",
	CheckboxChecked = "checkbox_checked.png",
	Reset = "reset.png",
	Center = "center.png",
	Info = "info.png",
	User = "user.png",
	Settings = "settings.png",
	Home = "home.png",
	Palette = "palette.png",
	Scale = "scale.png",
	Glass = "glass.png",
	Checklist = "checklist.png",
	Plus = "plus.png",
	Minus = "minus.png",
	Input = "input.png",
	Textbox = "textbox.png",
	Keybind = "keybind.png",
	DropdownDown = "dropdown_down.png",
	DropdownUp = "dropdown_up.png",
	Minimized = "minimized.png",
	Restored = "restored.png",
	DockHome = "dock_home.png",
	DockTab1 = "dock_tab1.png",
	DockTab2 = "dock_tab2.png",
	DockAbout = "dock_about.png",
	DockSettings = "dock_settings.png",
	Lock = "lock.png",
	Notification = "notification.png",
	Favorite = "favorite.png",
	Link = "link.png",
	Delete = "delete.png",
}

local AssetProvider = {
	_cache = {},
	_failed = {},
	_caps = nil,
	_warned = false,
}

local function pickFn(...)
	for i = 1, select("#", ...) do
		local name = select(i, ...)
		local fn = rawget(_G, name)
		if type(fn) == "function" then
			return fn
		end
		-- some executors put APIs in getgenv()
		local ok, genv = pcall(function()
			return getgenv and getgenv()
		end)
		if ok and type(genv) == "table" and type(genv[name]) == "function" then
			return genv[name]
		end
	end
	return nil
end

local function detect()
	if AssetProvider._caps then
		return AssetProvider._caps
	end
	local caps = {
		httpGet = nil,
		writefile = pickFn("writefile"),
		isfile = pickFn("isfile"),
		isfolder = pickFn("isfolder"),
		makefolder = pickFn("makefolder"),
		getcustomasset = pickFn("getcustomasset", "getsynasset"),
	}
	-- HttpGet: game:HttpGet or request-style
	caps.httpGet = function(url)
		local ok, body = pcall(function()
			return game:HttpGet(url)
		end)
		if ok and type(body) == "string" and #body > 64 then
			return body
		end
		local req = pickFn("http_request", "request")
		if not req then
			local okS, syn = pcall(function()
				return syn
			end)
			if okS and type(syn) == "table" and type(syn.request) == "function" then
				req = syn.request
			end
		end
		if type(req) == "function" then
			local ok2, res = pcall(req, { Url = url, Method = "GET" })
			if ok2 and type(res) == "table" and type(res.Body) == "string" and #res.Body > 64 then
				return res.Body
			end
		end
		return nil
	end
	caps.supported = (type(caps.writefile) == "function") and (type(caps.getcustomasset) == "function")
	AssetProvider._caps = caps
	return caps
end

local function ensureDir()
	local caps = detect()
	if not caps.makefolder then
		return
	end
	local parts = { "Wyvern UI Lib", "Wyvern UI Lib/assets", CACHE_DIR }
	for _, path in ipairs(parts) do
		local exists = false
		if caps.isfolder then
			local ok, res = pcall(caps.isfolder, path)
			exists = ok and res
		end
		if not exists then
			pcall(caps.makefolder, path)
		end
	end
end

function AssetProvider.GetCapability()
	local c = detect()
	return c.supported and "customasset" or "none"
end

function AssetProvider.GetGitHubUrl(name)
	local file = FILE_MAP[name]
	if not file then
		return nil
	end
	return REPO_RAW .. "/" .. file
end

function AssetProvider.Resolve(name)
	if type(name) ~= "string" then
		return nil
	end
	if AssetProvider._cache[name] then
		return AssetProvider._cache[name]
	end
	if AssetProvider._failed[name] then
		return nil
	end
	local file = FILE_MAP[name]
	if not file then
		return nil
	end

	local caps = detect()
	if not caps.supported then
		if not AssetProvider._warned then
			AssetProvider._warned = true
			warn("[Wyvern] PNG icon pipeline requires writefile + getcustomasset/getsynasset.")
			warn("[Wyvern] GitHub icons: " .. REPO_RAW)
		end
		AssetProvider._failed[name] = true
		return nil
	end

	ensureDir()
	local path = CACHE_DIR .. "/" .. file
	local needDownload = true
	if caps.isfile then
		local ok, exists = pcall(caps.isfile, path)
		if ok and exists then
			needDownload = false
		end
	end

	if needDownload then
		local url = AssetProvider.GetGitHubUrl(name)
		if not url or not string.find(url, "raw.githubusercontent.com/Lucsqxxx/Wyvern-lib/", 1, true) then
			AssetProvider._failed[name] = true
			return nil
		end
		local body = caps.httpGet(url)
		if type(body) ~= "string" or #body < 64 then
			warn("[Wyvern] icon download failed:", name)
			AssetProvider._failed[name] = true
			return nil
		end
		-- PNG magic check
		if string.sub(body, 1, 8) ~= "\137PNG\r\n\26\n" then
			warn("[Wyvern] icon download not PNG:", name)
			AssetProvider._failed[name] = true
			return nil
		end
		local okW = pcall(caps.writefile, path, body)
		if not okW then
			warn("[Wyvern] writefile failed:", name)
			AssetProvider._failed[name] = true
			return nil
		end
	end

	local okA, asset = pcall(caps.getcustomasset, path)
	if okA and type(asset) == "string" and asset ~= "" and asset ~= "nil" then
		AssetProvider._cache[name] = asset
		return asset
	end
	-- corrupt cache? delete and retry once
	if not needDownload then
		pcall(function()
			local delfile = pickFn("delfile")
			if delfile then
				delfile(path)
			end
		end)
		AssetProvider._failed[name] = nil
		-- force redownload next call only once
		local body = caps.httpGet(AssetProvider.GetGitHubUrl(name))
		if type(body) == "string" and #body > 64 then
			pcall(caps.writefile, path, body)
			local ok2, asset2 = pcall(caps.getcustomasset, path)
			if ok2 and type(asset2) == "string" and asset2 ~= "" then
				AssetProvider._cache[name] = asset2
				return asset2
			end
		end
	end
	warn("[Wyvern] getcustomasset failed:", name)
	AssetProvider._failed[name] = true
	return nil
end

function AssetProvider.Preload(names)
	if type(names) ~= "table" then
		return
	end
	for _, n in ipairs(names) do
		pcall(AssetProvider.Resolve, n)
	end
end

AssetProvider.FileMap = FILE_MAP
AssetProvider.RepoRaw = REPO_RAW
AssetProvider.CacheDir = CACHE_DIR

return AssetProvider
end)

-- ===== END Icons.AssetProvider =====

-- ===== BEGIN Icons.Renderer (Icons/Renderer.lua) =====

__wyvern_define("Icons.Renderer", function()
-- Icons/Renderer.lua
-- Vector-like icons built from Roblox GUI primitives (no Unicode, no external assets).

local Renderer = {}

local DEFAULT_SIZE = 16
local STROKE = 1.5

local function themeColor(theme, key, fallback)
	if theme and theme.Get then
		local c = theme:Get(key)
		if c then return c end
	end
	return fallback or Color3.fromRGB(170, 160, 185)
end

local function frame(parent, props)
	local f = Instance.new("Frame")
	f.BorderSizePixel = 0
	f.BackgroundColor3 = props.Color or Color3.new(1, 1, 1)
	f.BackgroundTransparency = props.Transparency or 0
	f.Size = props.Size or UDim2.fromOffset(2, 2)
	f.Position = props.Position or UDim2.fromOffset(0, 0)
	f.AnchorPoint = props.AnchorPoint or Vector2.new(0, 0)
	f.Rotation = props.Rotation or 0
	f.ZIndex = props.ZIndex or 2
	f.Parent = parent
	if props.Corner then
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(props.Corner == true and 1 or 0, typeof(props.Corner) == "number" and props.Corner or 0)
		c.Parent = f
	end
	if props.Stroke then
		local s = Instance.new("UIStroke")
		s.Color = props.Stroke
		s.Thickness = props.StrokeThickness or STROKE
		s.Parent = f
	end
	return f
end

--- Root container for an icon
local function root(parent, size, z)
	local r = Instance.new("Frame")
	r.Name = "IconRoot"
	r.BackgroundTransparency = 1
	r.Size = UDim2.fromOffset(size, size)
	r.Position = UDim2.fromScale(0.5, 0.5)
	r.AnchorPoint = Vector2.new(0.5, 0.5)
	r.ZIndex = z or 2
	r.Parent = parent
	return r
end

local builders = {}

function builders.Close(r, color, size)
	local t = math.max(1, size * 0.1)
	local len = size * 0.55
	local c1 = frame(r, {
		Size = UDim2.fromOffset(len, t),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Rotation = 45,
		Color = color,
		Corner = 1,
	})
	frame(r, {
		Size = UDim2.fromOffset(len, t),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Rotation = -45,
		Color = color,
		Corner = 1,
	})
end

function builders.Minimize(r, color, size)
	local t = math.max(1, size * 0.1)
	frame(r, {
		Size = UDim2.fromOffset(size * 0.55, t),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Color = color,
		Corner = 1,
	})
end

function builders.Back(r, color, size)
	-- chevron left from two strokes
	local t = math.max(1, size * 0.09)
	local len = size * 0.32
	frame(r, {
		Size = UDim2.fromOffset(len, t),
		Position = UDim2.fromScale(0.55, 0.35),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Rotation = 40,
		Color = color,
		Corner = 1,
	})
	frame(r, {
		Size = UDim2.fromOffset(len, t),
		Position = UDim2.fromScale(0.55, 0.65),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Rotation = -40,
		Color = color,
		Corner = 1,
	})
end

function builders.Search(r, color, size)
	local d = size * 0.45
	frame(r, {
		Size = UDim2.fromOffset(d, d),
		Position = UDim2.fromScale(0.38, 0.38),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Color = color,
		Transparency = 1,
		Stroke = color,
		StrokeThickness = math.max(1, size * 0.1),
		Corner = true,
	})
	local t = math.max(1, size * 0.1)
	frame(r, {
		Size = UDim2.fromOffset(size * 0.28, t),
		Position = UDim2.fromScale(0.68, 0.68),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Rotation = 45,
		Color = color,
		Corner = 1,
	})
end

function builders.Eye(r, color, size)
	-- almond via wide oval stroke + pupil
	local w, h = size * 0.7, size * 0.42
	frame(r, {
		Size = UDim2.fromOffset(w, h),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Color = color,
		Transparency = 1,
		Stroke = color,
		StrokeThickness = math.max(1, size * 0.1),
		Corner = true,
	})
	local p = size * 0.22
	frame(r, {
		Size = UDim2.fromOffset(p, p),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Color = color,
		Corner = true,
	})
end

function builders.Settings(r, color, size)
	-- gear: ring + 6 teeth
	local ring = size * 0.42
	frame(r, {
		Size = UDim2.fromOffset(ring, ring),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Color = color,
		Transparency = 1,
		Stroke = color,
		StrokeThickness = math.max(1, size * 0.1),
		Corner = true,
	})
	local hub = size * 0.16
	frame(r, {
		Size = UDim2.fromOffset(hub, hub),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Color = color,
		Corner = true,
	})
	local toothW = size * 0.12
	local toothH = size * 0.22
	for i = 0, 5 do
		local ang = i * 60
		frame(r, {
			Size = UDim2.fromOffset(toothW, toothH),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Rotation = ang,
			Color = color,
			Corner = 1,
		})
	end
end

function builders.User(r, color, size)
	local head = size * 0.28
	frame(r, {
		Size = UDim2.fromOffset(head, head),
		Position = UDim2.fromScale(0.5, 0.32),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Color = color,
		Corner = true,
	})
	frame(r, {
		Size = UDim2.fromOffset(size * 0.55, size * 0.32),
		Position = UDim2.fromScale(0.5, 0.72),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Color = color,
		Corner = size * 0.2,
	})
end

function builders.Checklist(r, color, size)
	-- list card
	frame(r, {
		Size = UDim2.fromOffset(size * 0.55, size * 0.7),
		Position = UDim2.fromScale(0.52, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Color = color,
		Transparency = 1,
		Stroke = color,
		StrokeThickness = math.max(1, size * 0.09),
		Corner = 2,
	})
	local t = math.max(1, size * 0.08)
	for i = 1, 3 do
		frame(r, {
			Size = UDim2.fromOffset(size * 0.28, t),
			Position = UDim2.fromScale(0.58, 0.28 + (i - 1) * 0.2),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Color = color,
			Corner = 1,
		})
	end
	-- small check marks left
	for i = 1, 3 do
		frame(r, {
			Size = UDim2.fromOffset(size * 0.1, t),
			Position = UDim2.fromScale(0.32, 0.28 + (i - 1) * 0.2),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Color = color,
			Corner = 1,
		})
	end
end

function builders.Layers(r, color, size)
	local t = math.max(1, size * 0.08)
	for i = 0, 2 do
		frame(r, {
			Size = UDim2.fromOffset(size * 0.55, t),
			Position = UDim2.fromScale(0.5, 0.3 + i * 0.2),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Color = color,
			Corner = 1,
		})
	end
end

function builders.Target(r, color, size)
	frame(r, {
		Size = UDim2.fromOffset(size * 0.65, size * 0.65),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Color = color,
		Transparency = 1,
		Stroke = color,
		StrokeThickness = math.max(1, size * 0.09),
		Corner = true,
	})
	frame(r, {
		Size = UDim2.fromOffset(size * 0.35, size * 0.35),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Color = color,
		Transparency = 1,
		Stroke = color,
		StrokeThickness = math.max(1, size * 0.09),
		Corner = true,
	})
	frame(r, {
		Size = UDim2.fromOffset(size * 0.12, size * 0.12),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Color = color,
		Corner = true,
	})
end

function builders.Play(r, color, size)
	-- triangle approx with rotated rects is hard; use small filled chevron
	local t = math.max(1, size * 0.12)
	frame(r, {
		Size = UDim2.fromOffset(size * 0.35, t),
		Position = UDim2.fromScale(0.55, 0.35),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Rotation = 35,
		Color = color,
		Corner = 1,
	})
	frame(r, {
		Size = UDim2.fromOffset(size * 0.35, t),
		Position = UDim2.fromScale(0.55, 0.65),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Rotation = -35,
		Color = color,
		Corner = 1,
	})
	frame(r, {
		Size = UDim2.fromOffset(t, size * 0.4),
		Position = UDim2.fromScale(0.38, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Color = color,
		Corner = 1,
	})
end

function builders.Cube(r, color, size)
	frame(r, {
		Size = UDim2.fromOffset(size * 0.5, size * 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Color = color,
		Transparency = 1,
		Stroke = color,
		StrokeThickness = math.max(1, size * 0.1),
		Corner = 2,
	})
end

function builders.Users(r, color, size)
	builders.User(r, color, size * 0.85)
end

function builders.Home(r, color, size)
	-- roof + body
	local t = math.max(1, size * 0.1)
	frame(r, {
		Size = UDim2.fromOffset(size * 0.55, t),
		Position = UDim2.fromScale(0.5, 0.38),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Rotation = 35,
		Color = color,
		Corner = 1,
	})
	frame(r, {
		Size = UDim2.fromOffset(size * 0.55, t),
		Position = UDim2.fromScale(0.5, 0.38),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Rotation = -35,
		Color = color,
		Corner = 1,
	})
	frame(r, {
		Size = UDim2.fromOffset(size * 0.45, size * 0.35),
		Position = UDim2.fromScale(0.5, 0.68),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Color = color,
		Transparency = 1,
		Stroke = color,
		StrokeThickness = t,
		Corner = 2,
	})
end

function builders.Check(r, color, size)
	local t = math.max(1, size * 0.1)
	frame(r, {
		Size = UDim2.fromOffset(size * 0.25, t),
		Position = UDim2.fromScale(0.35, 0.55),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Rotation = 45,
		Color = color,
		Corner = 1,
	})
	frame(r, {
		Size = UDim2.fromOffset(size * 0.45, t),
		Position = UDim2.fromScale(0.58, 0.45),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Rotation = -45,
		Color = color,
		Corner = 1,
	})
end

function builders.ChevronDown(r, color, size)
	local t = math.max(1, size * 0.09)
	frame(r, {
		Size = UDim2.fromOffset(size * 0.32, t),
		Position = UDim2.fromScale(0.35, 0.45),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Rotation = 40,
		Color = color,
		Corner = 1,
	})
	frame(r, {
		Size = UDim2.fromOffset(size * 0.32, t),
		Position = UDim2.fromScale(0.65, 0.45),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Rotation = -40,
		Color = color,
		Corner = 1,
	})
end

function builders.ChevronUp(r, color, size)
	local t = math.max(1, size * 0.09)
	frame(r, {
		Size = UDim2.fromOffset(size * 0.32, t),
		Position = UDim2.fromScale(0.35, 0.55),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Rotation = -40,
		Color = color,
		Corner = 1,
	})
	frame(r, {
		Size = UDim2.fromOffset(size * 0.32, t),
		Position = UDim2.fromScale(0.65, 0.55),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Rotation = 40,
		Color = color,
		Corner = 1,
	})
end

function builders.Info(r, color, size)
	frame(r, {
		Size = UDim2.fromOffset(size * 0.55, size * 0.55),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Color = color,
		Transparency = 1,
		Stroke = color,
		StrokeThickness = math.max(1, size * 0.1),
		Corner = true,
	})
	frame(r, {
		Size = UDim2.fromOffset(size * 0.1, size * 0.1),
		Position = UDim2.fromScale(0.5, 0.32),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Color = color,
		Corner = true,
	})
	frame(r, {
		Size = UDim2.fromOffset(size * 0.1, size * 0.22),
		Position = UDim2.fromScale(0.5, 0.58),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Color = color,
		Corner = 1,
	})
end

function builders.Moss(r, color, size)
	frame(r, {
		Size = UDim2.fromOffset(size * 0.45, size * 0.45),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Color = color,
		Corner = true,
	})
end

function builders.Sakura(r, color, size)
	builders.Moss(r, color, size)
end

function builders.Palette(r, color, size)
	frame(r, {
		Size = UDim2.fromOffset(size * 0.6, size * 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Color = color,
		Transparency = 1,
		Stroke = color,
		StrokeThickness = math.max(1, size * 0.09),
		Corner = true,
	})
	for i = 0, 2 do
		frame(r, {
			Size = UDim2.fromOffset(size * 0.12, size * 0.12),
			Position = UDim2.fromScale(0.35 + i * 0.15, 0.45),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Color = color,
			Corner = true,
		})
	end
end

function builders.Reset(r, color, size)
	frame(r, {
		Size = UDim2.fromOffset(size * 0.5, size * 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Color = color,
		Transparency = 1,
		Stroke = color,
		StrokeThickness = math.max(1, size * 0.1),
		Corner = true,
	})
	frame(r, {
		Size = UDim2.fromOffset(size * 0.18, math.max(1, size * 0.1)),
		Position = UDim2.fromScale(0.72, 0.28),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Color = color,
		Corner = 1,
	})
end

-- Aliases
builders.ChevronLeft = builders.Back
builders.ChevronRight = builders.Play
builders.Maximize = builders.Cube
builders.Fullscreen = builders.Cube
builders.Plus = builders.Check
builders.Minus = builders.Minimize
builders.Scale = builders.Layers
builders.Glass = builders.Cube
builders.Center = builders.Target
builders.Lock = builders.Cube

--- Create an icon inside parent. Returns root Frame and SetColor(color) helper.
function Renderer.Create(parent, name, options)
	options = options or {}
	local size = options.Size or DEFAULT_SIZE
	local theme = options.Theme
	local color = options.Color or themeColor(theme, "TextSecondary")
	local z = options.ZIndex or 5

	local holder = Instance.new("Frame")
	holder.Name = "Icon_" .. tostring(name)
	holder.BackgroundTransparency = 1
	holder.Size = options.FullSize or UDim2.fromScale(1, 1)
	holder.ZIndex = z
	holder.Parent = parent

	local r = root(holder, size, z + 1)
	local builder = builders[name] or builders.Moss
	builder(r, color, size)

	local api = {}
	function api:SetColor(c)
		for _, d in ipairs(r:GetDescendants()) do
			if d:IsA("Frame") then
				if d.BackgroundTransparency < 1 then
					d.BackgroundColor3 = c
				end
				local stroke = d:FindFirstChildOfClass("UIStroke")
				if stroke then
					stroke.Color = c
				end
			end
		end
	end
	function api:GetRoot()
		return holder
	end
	holder:SetAttribute("IconName", name)
	return holder, api
end

Renderer.Builders = builders
Renderer.DefaultSize = DEFAULT_SIZE

return Renderer
end)

-- ===== END Icons.Renderer =====

-- ===== BEGIN Icons.Glyphs (Icons/Glyphs.lua) =====

__wyvern_define("Icons.Glyphs", function()
-- Glyphs.lua
-- Self-contained text glyphs for icons (no external asset dependency).
-- Used when Image assets are unavailable or as primary style for consistency.

local Glyphs = {
	Back = "‹",
	Search = "⌕",
	Minimize = "–",
	Close = "×",
	Eye = "◉",
	Checklist = "☰",
	Settings = "⚙",
	User = "☺",
	ChevronDown = "▼",
	ChevronUp = "▲",
	Palette = "◉",
	Scale = "↔",
	Glass = "◇",
	Reset = "↺",
	Center = "＋",
	Info = "i",
	Check = "✓",
	Plus = "+",
	Minus = "−",
	Home = "⌂",
	Play = "▶",
	Layers = "▤",
	Target = "◎",
	Moss = "●",
	Cube = "■",
	Users = "☺",
	Sakura = "❀",
}

function Glyphs.Get(name)
	if type(name) ~= "string" then
		return "•"
	end
	return Glyphs[name] or "•"
end

--- Create a consistent icon TextLabel for use inside buttons.
function Glyphs.CreateLabel(name, theme, size)
	size = size or 14
	local label = Instance.new("TextLabel")
	label.Name = "Glyph_" .. tostring(name)
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBold
	label.TextSize = size
	label.Text = Glyphs.Get(name)
	label.TextColor3 = theme and theme:Get("TextSecondary") or Color3.fromRGB(170, 160, 185)
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.TextYAlignment = Enum.TextYAlignment.Center
	return label
end

return Glyphs
end)

-- ===== END Icons.Glyphs =====

-- ===== BEGIN Icons.Registry (Icons/Registry.lua) =====

__wyvern_define("Icons.Registry", function()
-- Icons/Registry.lua — image-first via AssetProvider (HttpGet→writefile→getcustomasset)

local AssetProvider = __wyvern_require("Icons.AssetProvider")
local Renderer = __wyvern_require("Icons.Renderer")

local verifiedIds = {}
pcall(function()
	verifiedIds = __wyvern_require("Icons.AssetIds") or {}
end)

local Icons = {
	AssetProvider = AssetProvider,
	Renderer = Renderer,
	AllowVectorFallback = true, -- only if PNG pipeline fails (keeps UI usable)
	RepoRawBase = AssetProvider.RepoRaw,
	Files = AssetProvider.FileMap,
	AssetIds = verifiedIds,
}

local function isValidContentId(s)
	return type(s) == "string" and s ~= "" and s ~= "nil"
end

function Icons.GetGitHubUrl(name)
	return AssetProvider.GetGitHubUrl(name)
end

function Icons.Get(name)
	if isValidContentId(Icons.AssetIds[name]) then
		return Icons.AssetIds[name]
	end
	local ok, resolved = pcall(AssetProvider.Resolve, name)
	if ok and isValidContentId(resolved) then
		return resolved
	end
	return nil
end

function Icons.SetAsset(name, assetId)
	if type(name) ~= "string" or not isValidContentId(assetId) then
		return
	end
	if not string.match(assetId, "^rbxassetid://%d+$") then
		warn("[Wyvern Icons] refusing non-rbxassetid for", name)
		return
	end
	Icons.AssetIds[name] = assetId
end

function Icons.Create(parent, name, options)
	options = options or {}
	local size = options.Size or 16
	local color = options.Color or Color3.fromRGB(180, 175, 195)
	local z = options.ZIndex or 5

	local holder = Instance.new("Frame")
	holder.Name = "Icon_" .. tostring(name)
	holder.BackgroundTransparency = 1
	holder.Size = options.FullSize or UDim2.fromScale(1, 1)
	holder.ZIndex = z
	holder.Parent = parent
	holder:SetAttribute("IconName", name)

	local source = Icons.Get(name)
	if isValidContentId(source) then
		local img = Instance.new("ImageLabel")
		img.Name = "Image"
		img.BackgroundTransparency = 1
		img.Size = UDim2.fromOffset(size, size)
		img.Position = UDim2.fromScale(0.5, 0.5)
		img.AnchorPoint = Vector2.new(0.5, 0.5)
		img.ScaleType = Enum.ScaleType.Fit
		img.ImageColor3 = color
		img.ZIndex = z + 1
		img.Parent = holder
		local ok = pcall(function()
			img.Image = source
		end)
		if not ok then
			img:Destroy()
			if Icons.AllowVectorFallback then
				Renderer.Create(holder, name, { Size = size, Color = color, Theme = options.Theme, ZIndex = z + 1 })
			end
		end
	elseif Icons.AllowVectorFallback then
		Renderer.Create(holder, name, { Size = size, Color = color, Theme = options.Theme, ZIndex = z + 1 })
	end

	return holder
end

function Icons.SetColor(holder, color)
	if not holder then
		return
	end
	local img = holder:FindFirstChild("Image")
	if img and img:IsA("ImageLabel") then
		img.ImageColor3 = color
		return
	end
	local root = holder:FindFirstChild("IconRoot")
	if root then
		for _, d in ipairs(root:GetDescendants()) do
			if d:IsA("Frame") then
				if d.BackgroundTransparency < 1 then
					d.BackgroundColor3 = color
				end
				local stroke = d:FindFirstChildOfClass("UIStroke")
				if stroke then
					stroke.Color = color
				end
			end
		end
	end
end

function Icons.Has(name)
	return AssetProvider.FileMap[name] ~= nil
end

function Icons.Preload(names)
	AssetProvider.Preload(names)
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

-- Subscribe to Theme:OnChanged. Component should implement :ApplyTheme(theme).
function Component:BindTheme(theme)
	if not theme or type(theme.OnChanged) ~= "function" then
		return
	end
	self._theme = theme
	local unsub = theme:OnChanged(function()
		if self._destroyed then
			return
		end
		if type(self.ApplyTheme) == "function" then
			self:ApplyTheme(theme)
		end
	end)
	self._maid:Give(function()
		if type(unsub) == "function" then
			unsub()
		end
	end)
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

function Component:GetValue(...)
	if self.Get then return self:Get(...) end
	return self._value
end

function Component:SetValue(...)
	if self.Set then return self:Set(...) end
end

function Component:GetState(...)
	return self:GetValue(...)
end

function Component:SetState(...)
	return self:SetValue(...)
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


-- Library-level helper: creates a temporary ScreenGui toast stack if needed
function Notification.Show(config, theme)
	config = config or {}
	local playerGui = nil
	pcall(function()
		local lp = game:GetService("Players").LocalPlayer
		playerGui = lp and (lp:FindFirstChildOfClass("PlayerGui") or lp:WaitForChild("PlayerGui", 2))
	end)
	local parent = playerGui
	if not parent then
		pcall(function()
			parent = game:GetService("CoreGui")
		end)
	end
	if not parent then
		warn("[Wyvern] Notify: no ParentGui available")
		return
	end
	local holderName = "WyvernLibNotifications"
	local holder = parent:FindFirstChild(holderName)
	if not holder then
		local sg = Instance.new("ScreenGui")
		sg.Name = holderName
		sg.ResetOnSpawn = false
		sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		sg.DisplayOrder = 1000
		pcall(function()
			sg.Parent = parent
		end)
		holder = sg
	end
	local mgr = Notification.new(holder, theme or {
		Get = function(_, k)
			local defaults = {
				Surface = Color3.fromRGB(30, 28, 40),
				Border = Color3.fromRGB(60, 55, 75),
				Text = Color3.fromRGB(230, 225, 240),
				TextSecondary = Color3.fromRGB(160, 155, 175),
				Accent = Color3.fromRGB(180, 120, 255),
			}
			return defaults[k] or Color3.new(1, 1, 1)
		end,
	})
	-- adapt config keys
	local adapted = {
		Title = config.Title or config.title,
		Content = config.Text or config.text or config.Content or config.Message,
		Duration = config.Duration or config.duration,
	}
	return mgr:Notify(adapted)
end
end)

-- ===== END Core.Notification =====

-- ===== BEGIN Core.Flags (Core/Flags.lua) =====

__wyvern_define("Core.Flags", function()
-- Core/Flags.lua — simple in-memory config flags for components

local Flags = {
	_store = {},
}

function Flags.Get(name)
	if type(name) ~= "string" then
		return nil
	end
	return Flags._store[name]
end

function Flags.Set(name, value)
	if type(name) ~= "string" then
		return
	end
	Flags._store[name] = value
end

function Flags.Has(name)
	return type(name) == "string" and Flags._store[name] ~= nil
end

function Flags.Reset()
	table.clear(Flags._store)
end

function Flags.GetAll()
	local copy = {}
	for k, v in pairs(Flags._store) do
		copy[k] = v
	end
	return copy
end

function Flags.Bind(name, default)
	if type(name) ~= "string" then
		return default
	end
	if Flags._store[name] == nil and default ~= nil then
		Flags._store[name] = default
	end
	return Flags._store[name]
end

return Flags
end)

-- ===== END Core.Flags =====

-- ===== BEGIN Core.Modal (Core/Modal.lua) =====

__wyvern_define("Core.Modal", function()
-- Core/Modal.lua — simple confirm dialog on OverlayLayer
local TweenService = game:GetService("TweenService")
local Maid = __wyvern_require("Core.Maid")
local PopupManager = __wyvern_require("Core.PopupManager")

local Modal = {}

function Modal.Confirm(config, theme, parentGui)
	config = config or {}
	local title = config.Title or "Confirm"
	local desc = config.Description or config.Text or ""
	local confirmText = config.ConfirmText or "Confirm"
	local cancelText = config.CancelText or "Cancel"
	local themeGet = theme and function(k) return theme:Get(k) end or function(k)
		local d = {
			Surface = Color3.fromRGB(28, 26, 36),
			Border = Color3.fromRGB(60, 55, 75),
			Text = Color3.fromRGB(235, 230, 245),
			TextSecondary = Color3.fromRGB(160, 155, 175),
			Accent = Color3.fromRGB(180, 120, 255),
		}
		return d[k] or Color3.new(1,1,1)
	end

	local done = false
	local result = false
	local maid = Maid.new()

	local overlay = Instance.new("Frame")
	overlay.Name = "WyvernModalOverlay"
	overlay.BackgroundColor3 = Color3.new(0, 0, 0)
	overlay.BackgroundTransparency = 0.45
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.ZIndex = 200
	overlay.Parent = parentGui or PopupManager.GetOverlay()

	local card = Instance.new("Frame")
	card.Size = UDim2.fromOffset(320, 0)
	card.AutomaticSize = Enum.AutomaticSize.Y
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Position = UDim2.fromScale(0.5, 0.5)
	card.BackgroundColor3 = themeGet("Surface")
	card.BorderSizePixel = 0
	card.ZIndex = 201
	card.Parent = overlay

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = card

	local stroke = Instance.new("UIStroke")
	stroke.Color = themeGet("Border")
	stroke.Transparency = 0.4
	stroke.Parent = card

	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 16)
	pad.PaddingBottom = UDim.new(0, 16)
	pad.PaddingLeft = UDim.new(0, 16)
	pad.PaddingRight = UDim.new(0, 16)
	pad.Parent = card

	local list = Instance.new("UIListLayout")
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, 10)
	list.Parent = card

	local tLabel = Instance.new("TextLabel")
	tLabel.BackgroundTransparency = 1
	tLabel.Size = UDim2.new(1, 0, 0, 20)
	tLabel.Font = Enum.Font.GothamBold
	tLabel.TextSize = 15
	tLabel.TextColor3 = themeGet("Text")
	tLabel.TextXAlignment = Enum.TextXAlignment.Left
	tLabel.Text = title
	tLabel.ZIndex = 202
	tLabel.Parent = card

	if desc ~= "" then
		local dLabel = Instance.new("TextLabel")
		dLabel.BackgroundTransparency = 1
		dLabel.Size = UDim2.new(1, 0, 0, 0)
		dLabel.AutomaticSize = Enum.AutomaticSize.Y
		dLabel.Font = Enum.Font.Gotham
		dLabel.TextSize = 13
		dLabel.TextColor3 = themeGet("TextSecondary")
		dLabel.TextXAlignment = Enum.TextXAlignment.Left
		dLabel.TextWrapped = true
		dLabel.Text = desc
		dLabel.ZIndex = 202
		dLabel.Parent = card
	end

	local row = Instance.new("Frame")
	row.BackgroundTransparency = 1
	row.Size = UDim2.new(1, 0, 0, 32)
	row.ZIndex = 202
	row.Parent = card

	local rowLayout = Instance.new("UIListLayout")
	rowLayout.FillDirection = Enum.FillDirection.Horizontal
	rowLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	rowLayout.Padding = UDim.new(0, 8)
	rowLayout.Parent = row

	local function finish(v)
		if done then return end
		done = true
		result = v
		maid:Destroy()
		pcall(function() overlay:Destroy() end)
	end

	local cancel = Instance.new("TextButton")
	cancel.Size = UDim2.fromOffset(90, 30)
	cancel.BackgroundColor3 = themeGet("Surface")
	cancel.Text = cancelText
	cancel.TextColor3 = themeGet("Text")
	cancel.Font = Enum.Font.GothamMedium
	cancel.TextSize = 13
	cancel.ZIndex = 203
	cancel.Parent = row
	Instance.new("UICorner", cancel).CornerRadius = UDim.new(0, 6)
	cancel.MouseButton1Click:Connect(function() finish(false) end)

	local confirm = Instance.new("TextButton")
	confirm.Size = UDim2.fromOffset(90, 30)
	confirm.BackgroundColor3 = themeGet("Accent")
	confirm.Text = confirmText
	confirm.TextColor3 = Color3.new(1, 1, 1)
	confirm.Font = Enum.Font.GothamMedium
	confirm.TextSize = 13
	confirm.ZIndex = 203
	confirm.Parent = row
	Instance.new("UICorner", confirm).CornerRadius = UDim.new(0, 6)
	confirm.MouseButton1Click:Connect(function() finish(true) end)

	maid:Give(overlay)

	if config.Callback then
		task.spawn(function()
			while not done do task.wait(0.05) end
			pcall(config.Callback, result)
		end)
		return
	end

	while not done do
		task.wait(0.05)
	end
	return result
end

return Modal
end)

-- ===== END Core.Modal =====

-- ===== BEGIN Core.PopupManager (Core/PopupManager.lua) =====

__wyvern_define("Core.PopupManager", function()
-- PopupManager.lua
-- Centralized exclusive popup/dropdown open state + outside-click handling.
-- Popups should parent to an overlay layer (screen space), not clipped content.

local UserInputService = game:GetService("UserInputService")

local PopupManager = {
	_open = nil,
	_conn = nil,
	_overlay = nil, -- Frame parent for screen-space popups
}

function PopupManager.SetOverlay(overlay)
	PopupManager._overlay = overlay
end

function PopupManager.GetOverlay()
	return PopupManager._overlay
end

function PopupManager.RegisterOpen(component)
	if PopupManager._open and PopupManager._open ~= component then
		pcall(function()
			PopupManager._open:Close()
		end)
	end
	PopupManager._open = component
	PopupManager._ensureListener()
end

function PopupManager.RegisterClose(component)
	if PopupManager._open == component then
		PopupManager._open = nil
	end
end

function PopupManager.CloseAll()
	if PopupManager._open then
		local current = PopupManager._open
		PopupManager._open = nil
		pcall(function()
			current:Close()
		end)
	end
end

function PopupManager.GetOpen()
	return PopupManager._open
end

function PopupManager._ensureListener()
	if PopupManager._conn then
		return
	end
	PopupManager._conn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		local open = PopupManager._open
		if not open or open._destroyed then
			PopupManager._open = nil
			return
		end
		task.defer(function()
			local current = PopupManager._open
			if not current or current._destroyed or not current._open then
				return
			end
			local pos = input.Position
			local inside = false
			if typeof(current.IsPointInside) == "function" then
				inside = current:IsPointInside(pos)
			elseif current._box and current._popup then
				local function hit(gui)
					if not gui or not gui.Visible then
						return false
					end
					local ap = gui.AbsolutePosition
					local as = gui.AbsoluteSize
					return pos.X >= ap.X and pos.X <= ap.X + as.X and pos.Y >= ap.Y and pos.Y <= ap.Y + as.Y
				end
				inside = hit(current._box) or hit(current._popup)
			end
			if not inside then
				pcall(function()
					current:Close()
				end)
			end
		end)
	end)
end

return PopupManager
end)

-- ===== END Core.PopupManager =====

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

function Button:ApplyTheme(theme)
	theme = theme or self._theme
	if not theme or self._destroyed then return end
	self._theme = theme
	if self._button then
		self._button.BackgroundColor3 = theme:Get("Button")
		self._button.TextColor3 = theme:Get("Text")
	end
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

	local check = Instance.new("Frame")
	check.Name = "Check"
	check.BackgroundTransparency = 1
	check.Size = UDim2.new(1, 0, 1, 0)
	check.Visible = self._value == true
	check.Parent = switch
	self._check = check
	local IconsMod = nil
	pcall(function()
		IconsMod = __wyvern_require("Icons.Registry")
	end)
	if IconsMod and IconsMod.Create then
		IconsMod.Create(check, "Check", {
			Size = 10,
			Theme = theme,
			Color = Color3.fromRGB(255, 255, 255),
			ZIndex = 6,
		})
	end

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
	if theme and theme.OnChanged then
		self:BindTheme(theme)
	end
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
	self._check.Visible = value and true or false
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

function Toggle:ApplyTheme(theme)
	theme = theme or self._theme
	if not theme or self._destroyed then return end
	self._theme = theme
	if self._label then
		self._label.TextColor3 = self._enabled and theme:Get("Text") or theme:Get("TextDisabled")
	end
	if self._switch then
		self._switch.BackgroundColor3 = self._value and theme:Get("ToggleOn") or theme:Get("ToggleOff")
	end
	if self._stroke then
		self._stroke.Color = theme:Get("Border")
	end
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
	if theme and theme.OnChanged then self:BindTheme(theme) end
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

function Slider:ApplyTheme(theme)
	theme = theme or self._theme
	if not theme or self._destroyed then return end
	self._theme = theme
	if self._label then self._label.TextColor3 = theme:Get("Text") end
	if self._valueLabel then self._valueLabel.TextColor3 = theme:Get("TextSecondary") end
	if self._track then self._track.BackgroundColor3 = theme:Get("SliderTrack") end
	if self._fill then self._fill.BackgroundColor3 = theme:Get("SliderFill") end
	if self._knob then self._knob.BackgroundColor3 = theme:Get("Accent") end
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
	keyText.TextTruncate = Enum.TextTruncate.AtEnd
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
	if theme and theme.OnChanged then self:BindTheme(theme) end
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

function Keybind:ApplyTheme(theme)
	theme = theme or self._theme
	if not theme or self._destroyed then return end
	self._theme = theme
	if self._label then
		self._label.TextColor3 = self._enabled and theme:Get("Text") or theme:Get("TextDisabled")
	end
	if self._keyBox then
		self._keyBox.BackgroundColor3 = theme:Get("SurfaceSecondary")
		local stroke = self._keyBox:FindFirstChildOfClass("UIStroke")
		if stroke then stroke.Color = theme:Get("Border") end
	end
	if self._keyText then
		if self._listening then
			self._keyText.TextColor3 = theme:Get("Accent")
		else
			self._keyText.TextColor3 = theme:Get("Text")
		end
	end
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
	if theme and theme.OnChanged then self:BindTheme(theme) end
	return self
end

function Label:SetText(text)
	self._text.Text = text or ""
end

function Label:ApplyTheme(theme)
	theme = theme or self._theme
	if not theme or self._destroyed then return end
	self._theme = theme
	if self._label then self._label.TextColor3 = theme:Get("TextSecondary") end
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
local Icons = __wyvern_require("Icons.Registry")
local Animation = __wyvern_require("Core.Animation")
local Constants = __wyvern_require("Core.Constants")
local PopupManager = __wyvern_require("Core.PopupManager")

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
	label.TextTruncate = Enum.TextTruncate.AtEnd
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

	local arrowHolder = Instance.new("Frame")
	arrowHolder.Name = "Arrow"
	arrowHolder.BackgroundTransparency = 1
	arrowHolder.Size = UDim2.new(0, 16, 0, 16)
	arrowHolder.Position = UDim2.new(1, -18, 0.5, -8)
	arrowHolder.Parent = box
	self._arrow = arrowHolder
	Icons.Create(arrowHolder, "DropdownDown", {
		Size = 12,
		Color = theme:Get("TextSecondary"),
		ZIndex = (box.ZIndex or 1) + 1,
	})

	-- Popup list (parented to box so it follows)
	local popup = Instance.new("Frame")
	popup.Name = "Popup"
	popup.BackgroundColor3 = theme:Get("Surface")
	popup.BorderSizePixel = 0
	popup.Size = UDim2.fromOffset(160, 0)
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

	self._maid:Give(container)
	if theme and theme.OnChanged then self:BindTheme(theme) end
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
	self:_applyPopupSize(maxVisible * (itemH + 2) + 10)

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

function Dropdown:IsPointInside(pos)
	local function hit(gui)
		if not gui or not gui.Visible then
			return false
		end
		local ap = gui.AbsolutePosition
		local as = gui.AbsoluteSize
		return pos.X >= ap.X and pos.X <= ap.X + as.X and pos.Y >= ap.Y and pos.Y <= ap.Y + as.Y
	end
	return hit(self._box) or hit(self._popup)
end


function Dropdown:_applyPopupSize(height)
	if not self._popup then return end
	local w = 160
	if self._box then
		local aw = self._box.AbsoluteSize.X
		if aw and aw > 1 then
			w = math.clamp(math.floor(aw + 0.5), 96, 280)
		end
	end
	local h = height
	if not h then
		local maxVisible = math.min(#self._options, 6)
		h = maxVisible * 26 + 10
	end
	-- ALWAYS offset size — never Scale X (overlay is full-screen)
	self._popup.Size = UDim2.fromOffset(w, h)
	self._popupWidth = w
end

function Dropdown:_positionPopup()
	if not self._popup or not self._box then
		return
	end
	local overlay = PopupManager.GetOverlay()
	local box = self._box
	local popup = self._popup
	local absPos = box.AbsolutePosition
	local absSize = box.AbsoluteSize
	local popupH = math.min(#self._options, 6) * 26 + 10
	self:_applyPopupSize(popupH)
	local w = self._popupWidth or math.clamp(math.floor(absSize.X + 0.5), 96, 280)

	local parent = overlay or box
	if popup.Parent ~= parent then
		popup.Parent = parent
	end

	if overlay and parent == overlay then
		local oAbs = overlay.AbsolutePosition
		local x = absPos.X - oAbs.X
		local y = absPos.Y - oAbs.Y + absSize.Y + 4
		local cam = workspace.CurrentCamera
		local vp = cam and cam.ViewportSize or Vector2.new(1920, 1080)
		if absPos.Y + absSize.Y + 4 + popupH > vp.Y - 8 then
			y = absPos.Y - oAbs.Y - popupH - 4
		end
		-- clamp horizontal inside viewport
		if x + w > vp.X - 8 then
			x = math.max(8, vp.X - w - 8) - oAbs.X
		end
		if x < 8 - oAbs.X then
			x = 8 - oAbs.X
		end
		popup.Position = UDim2.fromOffset(math.floor(x), math.floor(y))
		popup.Size = UDim2.fromOffset(w, popupH)
	else
		popup.Position = UDim2.new(0, 0, 1, 4)
		popup.Size = UDim2.fromOffset(w, popupH)
	end
end

function Dropdown:Open()
	if self._destroyed or self._open or not self._enabled then return end
	PopupManager.RegisterOpen(self)
	self._open = true
	self:_rebuildOptions()
	self:_positionPopup()
	if self._popup then
		self._popup.Visible = true
		self._popup.ZIndex = Constants.ZIndex.Dropdown or 90
	end
	if self._arrow then
		-- open state: keep image
	end
end

function Dropdown:Close()
	if not self._open then return end
	self._open = false
	PopupManager.RegisterClose(self)
	if self._popup then
		self._popup.Visible = false
		-- Reparent back under box so cleanup stays with component
		if self._box then
			self._popup.Parent = self._box
			self._popup.Position = UDim2.new(0, 0, 1, 4)
			self._popup.Size = UDim2.fromOffset(self._popupWidth or 160, 0)
		end
	end
	if self._arrow then
		-- closed state: keep image
	end
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

function Dropdown:ApplyTheme(theme)
	theme = theme or self._theme
	if not theme or self._destroyed then return end
	self._theme = theme
	if self._label then self._label.TextColor3 = theme:Get("Text") end
	if self._box then self._box.BackgroundColor3 = theme:Get("SurfaceSecondary") end
	if self._text then self._text.TextColor3 = theme:Get("Text") end
	if self._arrow then self._arrow.TextColor3 = theme:Get("TextSecondary") end
	if self._popup then self._popup.BackgroundColor3 = theme:Get("Surface") end
end

function Dropdown:Destroy()
	self:Close()
	PopupManager.RegisterClose(self)
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
local Icons = __wyvern_require("Icons.Registry")
local Constants = __wyvern_require("Core.Constants")
local PopupManager = __wyvern_require("Core.PopupManager")
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
	container.ClipsDescendants = true
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

	local arrowHolder = Instance.new("Frame")
	arrowHolder.Name = "Arrow"
	arrowHolder.BackgroundTransparency = 1
	arrowHolder.Size = UDim2.new(0, 16, 0, 16)
	arrowHolder.Position = UDim2.new(1, -18, 0.5, -8)
	arrowHolder.Parent = box
	self._arrow = arrowHolder
	Icons.Create(arrowHolder, "DropdownDown", {
		Size = 12,
		Color = theme:Get("TextSecondary"),
		ZIndex = (box.ZIndex or 1) + 1,
	})

	local popup = Instance.new("Frame")
	popup.Name = "Popup"
	popup.BackgroundColor3 = theme:Get("Surface")
	popup.BorderSizePixel = 0
	popup.Size = UDim2.fromOffset(160, 0)
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
	if theme and theme.OnChanged then self:BindTheme(theme) end
	return self
end

function MultiDropdown:_displayText()
	local list = setToList(self._selected)
	if #list == 0 then return "None" end
	if #list == 1 then return tostring(list[1]) end
	if #list == 2 then return tostring(list[1]) .. ", " .. tostring(list[2]) end
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
	self:_applyPopupSize()

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
		t.Text = (selected and "+ " or "  ") .. tostring(opt)
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

function MultiDropdown:IsPointInside(pos)
	local function hit(gui)
		if not gui or not gui.Visible then return false end
		local ap, as = gui.AbsolutePosition, gui.AbsoluteSize
		return pos.X >= ap.X and pos.X <= ap.X + as.X and pos.Y >= ap.Y and pos.Y <= ap.Y + as.Y
	end
	return hit(self._box) or hit(self._popup)
end


function MultiDropdown:_applyPopupSize(height)
	if not self._popup then return end
	local w = 160
	if self._box then
		local aw = self._box.AbsoluteSize.X
		if aw and aw > 1 then
			w = math.clamp(math.floor(aw + 0.5), 96, 280)
		end
	end
	local h = height or (math.min(#self._options, 6) * 26 + 10)
	self._popup.Size = UDim2.fromOffset(w, h)
	self._popupWidth = w
end

function MultiDropdown:_positionPopup()
	if not self._popup or not self._box then return end
	local overlay = PopupManager.GetOverlay()
	local box = self._box
	local popup = self._popup
	local absPos = box.AbsolutePosition
	local absSize = box.AbsoluteSize
	local popupH = math.min(#self._options, 6) * 26 + 10
	self:_applyPopupSize(popupH)
	local w = self._popupWidth or 160
	local parent = overlay or box
	if popup.Parent ~= parent then
		popup.Parent = parent
	end
	if overlay and parent == overlay then
		local oAbs = overlay.AbsolutePosition
		local x = absPos.X - oAbs.X
		local y = absPos.Y - oAbs.Y + absSize.Y + 4
		local cam = workspace.CurrentCamera
		local vp = cam and cam.ViewportSize or Vector2.new(1920, 1080)
		if absPos.Y + absSize.Y + 4 + popupH > vp.Y - 8 then
			y = absPos.Y - oAbs.Y - popupH - 4
		end
		if x + w > vp.X - 8 then
			x = math.max(8, vp.X - w - 8) - oAbs.X
		end
		popup.Position = UDim2.fromOffset(math.floor(x), math.floor(y))
		popup.Size = UDim2.fromOffset(w, popupH)
	else
		popup.Position = UDim2.new(0, 0, 1, 4)
		popup.Size = UDim2.fromOffset(w, popupH)
	end
end

function MultiDropdown:Open()
	if self._destroyed or self._open or not self._enabled then return end
	PopupManager.RegisterOpen(self)
	self._open = true
	self:_rebuildOptions()
	self:_positionPopup()
	if self._popup then
		self._popup.Visible = true
		self._popup.ZIndex = (Constants and Constants.ZIndex and Constants.ZIndex.Dropdown) or 90
	end
	-- open
end

function MultiDropdown:Close()
	if not self._open then return end
	self._open = false
	PopupManager.RegisterClose(self)
	if self._popup then
		self._popup.Visible = false
		if self._box then
			self._popup.Parent = self._box
			self._popup.Position = UDim2.new(0, 0, 1, 4)
			self:_applyPopupSize()
		end
	end
	-- closed
end

function MultiDropdown:ApplyTheme(theme)
	theme = theme or self._theme
	if not theme or self._destroyed then return end
	self._theme = theme
	if self._label then self._label.TextColor3 = theme:Get("Text") end
	if self._box then self._box.BackgroundColor3 = theme:Get("SurfaceSecondary") end
	if self._text then self._text.TextColor3 = theme:Get("Text") end
	if self._arrow then self._arrow.TextColor3 = theme:Get("TextSecondary") end
	if self._popup then self._popup.BackgroundColor3 = theme:Get("Surface") end
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
	PopupManager.RegisterClose(self)
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
	if theme and theme.OnChanged then self:BindTheme(theme) end
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

function Textbox:ApplyTheme(theme)
	theme = theme or self._theme
	if not theme or self._destroyed then return end
	self._theme = theme
	local label = self._instance and self._instance:FindFirstChildOfClass("TextLabel")
	if label then label.TextColor3 = theme:Get("Text") end
	if self._box then
		self._box.BackgroundColor3 = theme:Get("SurfaceSecondary")
		self._box.TextColor3 = theme:Get("Text")
		self._box.PlaceholderColor3 = theme:Get("TextDisabled")
	end
end

function Textbox:Get()
	return self._value
end

return Textbox
end)

-- ===== END Components.Textbox =====

-- ===== BEGIN Components.ColorPicker (Components/ColorPicker.lua) =====

__wyvern_define("Components.ColorPicker", function()
-- ColorPicker.lua
-- Real HSV popup color picker (OverlayLayer + PopupManager).

local UserInputService = game:GetService("UserInputService")
local Component = __wyvern_require("Core.Component")
local Constants = __wyvern_require("Core.Constants")
local PopupManager = __wyvern_require("Core.PopupManager")

local ColorPicker = setmetatable({}, { __index = Component })
ColorPicker.__index = ColorPicker

local function clamp01(n)
	return math.clamp(n, 0, 1)
end

function ColorPicker.new(config, parent, theme)
	local self = setmetatable(Component.new(config), ColorPicker)
	self._theme = theme
	self._value = config.Default or Color3.fromRGB(255, 110, 175)
	self._open = false
	self._hue, self._sat, self._val = self._value:ToHSV()

	local container = Instance.new("Frame")
	container.Name = "ColorPicker_" .. (config.Name or "Color")
	container.BackgroundTransparency = 1
	container.Size = UDim2.new(1, 0, 0, Constants.ControlHeight)
	container.Parent = parent
	self._instance = container

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, -36, 1, 0)
	label.Font = Enum.Font.Gotham
	label.TextSize = Constants.LabelSize
	label.TextColor3 = theme:Get("Text")
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = config.Name or "Color"
	label.Parent = container
	self._label = label

	local swatch = Instance.new("TextButton")
	swatch.Name = "Swatch"
	swatch.Size = UDim2.fromOffset(28, 20)
	swatch.Position = UDim2.new(1, -28, 0.5, -10)
	swatch.BackgroundColor3 = self._value
	swatch.BorderSizePixel = 0
	swatch.Text = ""
	swatch.AutoButtonColor = false
	swatch.ZIndex = 5
	swatch.Parent = container
	self._swatch = swatch

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = swatch

	local stroke = Instance.new("UIStroke")
	stroke.Color = theme:Get("Border")
	stroke.Thickness = 1
	stroke.Transparency = 0.3
	stroke.Parent = swatch
	self._swatchStroke = stroke

	local popup = Instance.new("Frame")
	popup.Name = "PickerPopup"
	popup.Size = UDim2.fromOffset(180, 150)
	popup.BackgroundColor3 = theme:Get("Surface")
	popup.BorderSizePixel = 0
	popup.Visible = false
	popup.ZIndex = Constants.ZIndex.Dropdown or 90
	popup.Parent = swatch
	self._popup = popup

	local pCorner = Instance.new("UICorner")
	pCorner.CornerRadius = UDim.new(0, 8)
	pCorner.Parent = popup

	local pStroke = Instance.new("UIStroke")
	pStroke.Color = theme:Get("Border")
	pStroke.Thickness = 1
	pStroke.Parent = popup

	local sv = Instance.new("ImageButton")
	sv.Name = "SV"
	sv.Size = UDim2.fromOffset(140, 100)
	sv.Position = UDim2.fromOffset(8, 8)
	sv.BorderSizePixel = 0
	sv.AutoButtonColor = false
	sv.BackgroundColor3 = Color3.fromHSV(self._hue, 1, 1)
	sv.ZIndex = popup.ZIndex + 1
	sv.Parent = popup
	self._sv = sv

	local svCorner = Instance.new("UICorner")
	svCorner.CornerRadius = UDim.new(0, 4)
	svCorner.Parent = sv

	local white = Instance.new("Frame")
	white.Size = UDim2.fromScale(1, 1)
	white.BackgroundColor3 = Color3.new(1, 1, 1)
	white.BorderSizePixel = 0
	white.ZIndex = sv.ZIndex + 1
	white.Parent = sv
	local wg = Instance.new("UIGradient")
	wg.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	wg.Parent = white

	local black = Instance.new("Frame")
	black.Size = UDim2.fromScale(1, 1)
	black.BackgroundColor3 = Color3.new(0, 0, 0)
	black.BorderSizePixel = 0
	black.ZIndex = sv.ZIndex + 2
	black.Parent = sv
	local bg = Instance.new("UIGradient")
	bg.Rotation = 90
	bg.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(1, 0),
	})
	bg.Parent = black

	local cursor = Instance.new("Frame")
	cursor.Name = "Cursor"
	cursor.Size = UDim2.fromOffset(10, 10)
	cursor.AnchorPoint = Vector2.new(0.5, 0.5)
	cursor.BackgroundColor3 = Color3.new(1, 1, 1)
	cursor.BorderSizePixel = 0
	cursor.ZIndex = sv.ZIndex + 3
	cursor.Parent = sv
	self._cursor = cursor
	local cc = Instance.new("UICorner")
	cc.CornerRadius = UDim.new(1, 0)
	cc.Parent = cursor
	local cs = Instance.new("UIStroke")
	cs.Color = Color3.new(0, 0, 0)
	cs.Thickness = 1
	cs.Parent = cursor

	local hueBar = Instance.new("TextButton")
	hueBar.Name = "Hue"
	hueBar.Size = UDim2.fromOffset(16, 100)
	hueBar.Position = UDim2.fromOffset(156, 8)
	hueBar.BorderSizePixel = 0
	hueBar.Text = ""
	hueBar.AutoButtonColor = false
	hueBar.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
	hueBar.ZIndex = popup.ZIndex + 1
	hueBar.Parent = popup
	self._hueBar = hueBar

	local hc = Instance.new("UICorner")
	hc.CornerRadius = UDim.new(0, 4)
	hc.Parent = hueBar

	local hueGrad = Instance.new("UIGradient")
	hueGrad.Rotation = 90
	hueGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 1, 1)),
		ColorSequenceKeypoint.new(0.16, Color3.fromHSV(0.16, 1, 1)),
		ColorSequenceKeypoint.new(0.33, Color3.fromHSV(0.33, 1, 1)),
		ColorSequenceKeypoint.new(0.5, Color3.fromHSV(0.5, 1, 1)),
		ColorSequenceKeypoint.new(0.66, Color3.fromHSV(0.66, 1, 1)),
		ColorSequenceKeypoint.new(0.83, Color3.fromHSV(0.83, 1, 1)),
		ColorSequenceKeypoint.new(1, Color3.fromHSV(1, 1, 1)),
	})
	hueGrad.Parent = hueBar

	local hueCursor = Instance.new("Frame")
	hueCursor.Size = UDim2.new(1, 4, 0, 4)
	hueCursor.Position = UDim2.new(0, -2, self._hue, 0)
	hueCursor.BackgroundColor3 = Color3.new(1, 1, 1)
	hueCursor.BorderSizePixel = 0
	hueCursor.ZIndex = hueBar.ZIndex + 2
	hueCursor.Parent = hueBar
	self._hueCursor = hueCursor

	local preview = Instance.new("Frame")
	preview.Size = UDim2.fromOffset(164, 18)
	preview.Position = UDim2.fromOffset(8, 116)
	preview.BackgroundColor3 = self._value
	preview.BorderSizePixel = 0
	preview.ZIndex = popup.ZIndex + 1
	preview.Parent = popup
	self._preview = preview
	local pc = Instance.new("UICorner")
	pc.CornerRadius = UDim.new(0, 4)
	pc.Parent = preview

	local function updateFromHSV()
		self._value = Color3.fromHSV(self._hue, self._sat, self._val)
		self._swatch.BackgroundColor3 = self._value
		if self._preview then self._preview.BackgroundColor3 = self._value end
		if self._sv then self._sv.BackgroundColor3 = Color3.fromHSV(self._hue, 1, 1) end
		if self._cursor then self._cursor.Position = UDim2.fromScale(self._sat, 1 - self._val) end
		if self._hueCursor then self._hueCursor.Position = UDim2.new(0, -2, self._hue, 0) end
		self.ValueChanged:Fire(self._value)
		for _, cb in ipairs(self._callbacks) do
			task.spawn(cb, self._value)
		end
	end

	local function sampleSV(input)
		local abs = sv.AbsolutePosition
		local size = sv.AbsoluteSize
		if size.X < 1 or size.Y < 1 then return end
		self._sat = clamp01((input.Position.X - abs.X) / size.X)
		self._val = 1 - clamp01((input.Position.Y - abs.Y) / size.Y)
		updateFromHSV()
	end

	local function sampleHue(input)
		local abs = hueBar.AbsolutePosition
		local size = hueBar.AbsoluteSize
		if size.Y < 1 then return end
		self._hue = clamp01((input.Position.Y - abs.Y) / size.Y)
		updateFromHSV()
	end

	local draggingSV, draggingHue = false, false
	self._maid:Give(sv.InputBegan:Connect(function(input)
		if not self._enabled or self._destroyed then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			draggingSV = true
			sampleSV(input)
		end
	end))
	self._maid:Give(hueBar.InputBegan:Connect(function(input)
		if not self._enabled or self._destroyed then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			draggingHue = true
			sampleHue(input)
		end
	end))
	self._maid:Give(UserInputService.InputChanged:Connect(function(input)
		if self._destroyed then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			if draggingSV then sampleSV(input)
			elseif draggingHue then sampleHue(input) end
		end
	end))
	self._maid:Give(UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			draggingSV = false
			draggingHue = false
		end
	end))

	self._maid:Give(swatch.MouseButton1Click:Connect(function()
		if not self._enabled or self._destroyed then return end
		if self._open then self:Close() else self:Open() end
	end))

	updateFromHSV()
	self._maid:Give(container)
	if theme and theme.OnChanged then self:BindTheme(theme) end
	return self
end

function ColorPicker:IsPointInside(pos)
	local function hit(gui)
		if not gui or not gui.Visible then return false end
		local ap, as = gui.AbsolutePosition, gui.AbsoluteSize
		return pos.X >= ap.X and pos.X <= ap.X + as.X and pos.Y >= ap.Y and pos.Y <= ap.Y + as.Y
	end
	return hit(self._swatch) or hit(self._popup)
end

function ColorPicker:_positionPopup()
	if not self._popup or not self._swatch then return end
	local overlay = PopupManager.GetOverlay()
	local parent = overlay or self._swatch
	if self._popup.Parent ~= parent then self._popup.Parent = parent end
	if overlay and parent == overlay then
		local oAbs = overlay.AbsolutePosition
		local abs = self._swatch.AbsolutePosition
		local size = self._swatch.AbsoluteSize
		local x = abs.X - oAbs.X
		local y = abs.Y - oAbs.Y + size.Y + 4
		local cam = workspace.CurrentCamera
		local vp = cam and cam.ViewportSize or Vector2.new(1920, 1080)
		if abs.Y + size.Y + 154 > vp.Y - 8 then
			y = abs.Y - oAbs.Y - 154
		end
		self._popup.Position = UDim2.fromOffset(x, y)
		self._popup.Size = UDim2.fromOffset(180, 150)
	else
		self._popup.Position = UDim2.new(1, -180, 1, 4)
	end
end

function ColorPicker:Open()
	if self._destroyed or self._open or not self._enabled then return end
	PopupManager.RegisterOpen(self)
	self._open = true
	self:_positionPopup()
	if self._popup then
		self._popup.Visible = true
		self._popup.ZIndex = Constants.ZIndex.Dropdown or 90
	end
end

function ColorPicker:Close()
	if not self._open then return end
	self._open = false
	PopupManager.RegisterClose(self)
	if self._popup then
		self._popup.Visible = false
		if self._swatch then self._popup.Parent = self._swatch end
	end
end

function ColorPicker:Set(color)
	if self._destroyed or typeof(color) ~= "Color3" then return end
	self._value = color
	self._hue, self._sat, self._val = color:ToHSV()
	if self._swatch then self._swatch.BackgroundColor3 = color end
	if self._preview then self._preview.BackgroundColor3 = color end
	if self._sv then self._sv.BackgroundColor3 = Color3.fromHSV(self._hue, 1, 1) end
	if self._cursor then self._cursor.Position = UDim2.fromScale(self._sat, 1 - self._val) end
	if self._hueCursor then self._hueCursor.Position = UDim2.new(0, -2, self._hue, 0) end
	self.ValueChanged:Fire(color)
	for _, cb in ipairs(self._callbacks) do task.spawn(cb, color) end
end

function ColorPicker:Get()
	return self._value
end

function ColorPicker:ApplyTheme(theme)
	theme = theme or self._theme
	if not theme or self._destroyed then return end
	self._theme = theme
	if self._label then self._label.TextColor3 = theme:Get("Text") end
	if self._swatchStroke then self._swatchStroke.Color = theme:Get("Border") end
	if self._popup then self._popup.BackgroundColor3 = theme:Get("Surface") end
end

function ColorPicker:Destroy()
	self:Close()
	PopupManager.RegisterClose(self)
	Component.Destroy(self)
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

-- ===== BEGIN Components.Feature (Components/Feature.lua) =====

__wyvern_define("Components.Feature", function()
-- Components/Feature.lua
-- Nested feature/module card: title, description, optional enable toggle, child controls.
-- Width is always 100% of parent section; only height auto-sizes.

local Maid = __wyvern_require("Core.Maid")
local Constants = __wyvern_require("Core.Constants")
local Flags = __wyvern_require("Core.Flags")

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

local Feature = {}
Feature.__index = Feature

local function wireFlag(comp, flag, getFn, setFn)
	if type(flag) ~= "string" or not comp then
		return
	end
	local existing = Flags.Get(flag)
	if existing ~= nil and setFn then
		pcall(setFn, existing)
	elseif getFn then
		local ok, v = pcall(getFn)
		if ok then
			Flags.Set(flag, v)
		end
	end
	if comp.ValueChanged and comp.ValueChanged.Connect then
		comp.ValueChanged:Connect(function(v)
			Flags.Set(flag, v)
		end)
	end
end

function Feature.new(config, parent, theme, search, inputManager)
	config = config or {}
	local self = setmetatable({
		_maid = Maid.new(),
		_theme = theme,
		_search = search,
		_input = inputManager,
		_name = config.Name or config.title or "Feature",
		_description = config.Description or config.description or "",
		_components = {},
		_enabled = config.Enabled ~= false and config.Default ~= false,
		_callback = config.Callback or config.callback,
		_flag = config.Flag or config.flag,
	}, Feature)

	if self._flag then
		local stored = Flags.Get(self._flag)
		if stored ~= nil then
			self._enabled = stored and true or false
		else
			Flags.Set(self._flag, self._enabled)
		end
	end

	local card = Instance.new("Frame")
	card.Name = "Feature_" .. self._name
	card.BackgroundColor3 = theme:Get("SurfaceSecondary") or theme:Get("Surface")
	card.BorderSizePixel = 0
	card.Size = UDim2.new(1, 0, 0, 0)
	card.AutomaticSize = Enum.AutomaticSize.Y
	card.ClipsDescendants = true
	card.Parent = parent
	self._instance = card

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = card

	local stroke = Instance.new("UIStroke")
	stroke.Color = theme:Get("Border")
	stroke.Thickness = 1
	stroke.Transparency = 0.6
	stroke.Parent = card

	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 8)
	pad.PaddingBottom = UDim.new(0, 8)
	pad.PaddingLeft = UDim.new(0, 10)
	pad.PaddingRight = UDim.new(0, 10)
	pad.Parent = card

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 6)
	layout.Parent = card

	local header = Instance.new("Frame")
	header.Name = "Header"
	header.BackgroundTransparency = 1
	header.Size = UDim2.new(1, 0, 0, 0)
	header.AutomaticSize = Enum.AutomaticSize.Y
	header.LayoutOrder = 0
	header.Parent = card

	local headerLayout = Instance.new("UIListLayout")
	headerLayout.SortOrder = Enum.SortOrder.LayoutOrder
	headerLayout.Padding = UDim.new(0, 2)
	headerLayout.Parent = header

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, -40, 0, 16)
	title.Font = Enum.Font.GothamMedium
	title.TextSize = 13
	title.TextColor3 = theme:Get("Text")
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextTruncate = Enum.TextTruncate.AtEnd
	title.Text = self._name
	title.LayoutOrder = 1
	title.Parent = header
	self._title = title

	if self._description ~= "" then
		local desc = Instance.new("TextLabel")
		desc.Name = "Description"
		desc.BackgroundTransparency = 1
		desc.Size = UDim2.new(1, 0, 0, 0)
		desc.AutomaticSize = Enum.AutomaticSize.Y
		desc.Font = Enum.Font.Gotham
		desc.TextSize = 11
		desc.TextColor3 = theme:Get("TextSecondary") or theme:Get("TextMuted") or theme:Get("Text")
		desc.TextXAlignment = Enum.TextXAlignment.Left
		desc.TextWrapped = true
		desc.Text = self._description
		desc.LayoutOrder = 2
		desc.Parent = header
		self._desc = desc
	end

	-- Optional enable switch row
	if config.ShowEnable ~= false and (config.Enabled ~= nil or config.Callback or config.callback or self._flag) then
		local toggle = Toggle.new({
			Name = "Enabled",
			Default = self._enabled,
			Callback = function(v)
				self._enabled = v
				if self._flag then
					Flags.Set(self._flag, v)
				end
				if self._callback then
					task.spawn(function()
						local ok, err = pcall(self._callback, v)
						if not ok then
							warn("[Wyvern Feature] callback error:", err)
						end
					end)
				end
			end,
		}, card, theme, search, inputManager)
		toggle._instance.LayoutOrder = 1
		self._enableToggle = toggle
		table.insert(self._components, toggle)
	end

	local body = Instance.new("Frame")
	body.Name = "Body"
	body.BackgroundTransparency = 1
	body.Size = UDim2.new(1, 0, 0, 0)
	body.AutomaticSize = Enum.AutomaticSize.Y
	body.ClipsDescendants = true
	body.LayoutOrder = 10
	body.Parent = card
	self._body = body

	local bodyLayout = Instance.new("UIListLayout")
	bodyLayout.SortOrder = Enum.SortOrder.LayoutOrder
	bodyLayout.Padding = UDim.new(0, Constants.ComponentSpacing or 6)
	bodyLayout.Parent = body

	self._maid:Give(card)
	return self
end

function Feature:_add(comp)
	if not comp then
		return
	end
	table.insert(self._components, comp)
	if comp._instance then
		comp._instance.Parent = self._body
		comp._instance.Size = UDim2.new(1, 0, 0, comp._instance.Size.Y.Offset)
	end
	return comp
end

local function normalize(config)
	config = config or {}
	if config.title and not config.Name then
		config.Name = config.title
	end
	if config.flag and not config.Flag then
		config.Flag = config.flag
	end
	if config.callback and not config.Callback then
		config.Callback = config.callback
	end
	if config.minimum_value and not config.Min then
		config.Min = config.minimum_value
	end
	if config.maximum_value and not config.Max then
		config.Max = config.maximum_value
	end
	if config.value ~= nil and config.Default == nil then
		config.Default = config.value
	end
	if config.placeholder and not config.Placeholder then
		config.Placeholder = config.placeholder
	end
	if config.options and not config.Options then
		config.Options = config.options
	end
	return config
end

function Feature:CreateButton(config)
	config = normalize(config)
	local c = Button.new(config, self._body, self._theme, self._search, self._input)
	return self:_add(c)
end

function Feature:CreateToggle(config)
	config = normalize(config)
	local c = Toggle.new(config, self._body, self._theme, self._search, self._input)
	wireFlag(c, config.Flag, function()
		return c:Get()
	end, function(v)
		c:Set(v)
	end)
	return self:_add(c)
end

function Feature:CreateCheckbox(config)
	return self:CreateToggle(config)
end

function Feature:CreateSlider(config)
	config = normalize(config)
	local c = Slider.new(config, self._body, self._theme, self._search, self._input)
	wireFlag(c, config.Flag, function()
		return c:Get()
	end, function(v)
		c:Set(v)
	end)
	return self:_add(c)
end

function Feature:CreateDropdown(config)
	config = normalize(config)
	local c
	if config.multi_dropdown or config.Multi then
		c = MultiDropdown.new(config, self._body, self._theme, self._search, self._input)
	else
		c = Dropdown.new(config, self._body, self._theme, self._search, self._input)
	end
	wireFlag(c, config.Flag, function()
		return c:Get()
	end, function(v)
		c:Set(v)
	end)
	return self:_add(c)
end

function Feature:CreateMultiDropdown(config)
	config = normalize(config)
	config.Multi = true
	return self:CreateDropdown(config)
end

function Feature:CreateTextbox(config)
	config = normalize(config)
	local c = Textbox.new(config, self._body, self._theme, self._search, self._input)
	wireFlag(c, config.Flag, function()
		return c:Get()
	end, function(v)
		c:Set(v)
	end)
	return self:_add(c)
end

function Feature:CreateInput(config)
	return self:CreateTextbox(config)
end

function Feature:CreateKeybind(config)
	config = normalize(config)
	local c = Keybind.new(config, self._body, self._theme, self._search, self._input)
	return self:_add(c)
end

function Feature:CreateColorPicker(config)
	config = normalize(config)
	local c = ColorPicker.new(config, self._body, self._theme, self._search, self._input)
	return self:_add(c)
end

function Feature:CreateLabel(config)
	config = normalize(config)
	return self:_add(Label.new(config, self._body, self._theme, self._search, self._input))
end

function Feature:CreateParagraph(config)
	return self:CreateLabel(config)
end

function Feature:CreateDivider(config)
	return self:_add(Divider.new(config or {}, self._body, self._theme, self._search, self._input))
end

function Feature:GetEnabled()
	return self._enabled
end

function Feature:SetEnabled(v)
	self._enabled = v and true or false
	if self._enableToggle then
		self._enableToggle:Set(self._enabled)
	end
	if self._flag then
		Flags.Set(self._flag, self._enabled)
	end
end

function Feature:Destroy()
	for _, c in ipairs(self._components) do
		pcall(function()
			c:Destroy()
		end)
	end
	self._maid:Destroy()
	setmetatable(self, nil)
end

return Feature
end)

-- ===== END Components.Feature =====

-- ===== BEGIN Components.ProgressBar (Components/ProgressBar.lua) =====

__wyvern_define("Components.ProgressBar", function()
-- Components/ProgressBar.lua
local Component = __wyvern_require("Core.Component")
local Constants = __wyvern_require("Core.Constants")

local ProgressBar = setmetatable({}, { __index = Component })
ProgressBar.__index = ProgressBar

function ProgressBar.new(config, parent, theme, search, inputManager)
	config = config or {}
	local self = setmetatable(Component.new(config), ProgressBar)
	self._theme = theme
	self._value = tonumber(config.Default) or tonumber(config.Value) or 0
	self._min = tonumber(config.Min) or 0
	self._max = tonumber(config.Max) or 100
	if self._max <= self._min then self._max = self._min + 1 end

	local row = Instance.new("Frame")
	row.Name = "ProgressBar"
	row.BackgroundTransparency = 1
	row.Size = UDim2.new(1, 0, 0, 28)
	row.ClipsDescendants = true
	row.Parent = parent
	self._instance = row

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, -40, 0, 14)
	label.Font = Enum.Font.Gotham
	label.TextSize = 12
	label.TextColor3 = theme:Get("Text")
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextTruncate = Enum.TextTruncate.AtEnd
	label.Text = config.Name or config.Title or "Progress"
	label.Parent = row
	self._label = label

	local pct = Instance.new("TextLabel")
	pct.BackgroundTransparency = 1
	pct.Size = UDim2.new(0, 36, 0, 14)
	pct.Position = UDim2.new(1, -36, 0, 0)
	pct.Font = Enum.Font.GothamMedium
	pct.TextSize = 11
	pct.TextColor3 = theme:Get("TextSecondary") or theme:Get("Text")
	pct.TextXAlignment = Enum.TextXAlignment.Right
	pct.Parent = row
	self._pct = pct

	local track = Instance.new("Frame")
	track.Name = "Track"
	track.BackgroundColor3 = theme:Get("SurfaceSecondary") or theme:Get("Surface")
	track.BorderSizePixel = 0
	track.Size = UDim2.new(1, 0, 0, 6)
	track.Position = UDim2.new(0, 0, 0, 18)
	track.Parent = row
	Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)
	self._track = track

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.BackgroundColor3 = theme:Get("Accent")
	fill.BorderSizePixel = 0
	fill.Size = UDim2.new(0, 0, 1, 0)
	fill.Parent = track
	Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
	self._fill = fill

	self:Set(self._value)
	self._maid:Give(row)
	return self
end

function ProgressBar:Set(value)
	value = math.clamp(tonumber(value) or 0, self._min, self._max)
	self._value = value
	local alpha = (value - self._min) / (self._max - self._min)
	if self._fill then
		self._fill.Size = UDim2.new(alpha, 0, 1, 0)
	end
	if self._pct then
		self._pct.Text = tostring(math.floor(alpha * 100 + 0.5)) .. "%"
	end
	Component.Set(self, value)
end

function ProgressBar:SetProgress(v)
	self:Set(v)
end

function ProgressBar:ApplyTheme(theme)
	self._theme = theme
	if self._label then self._label.TextColor3 = theme:Get("Text") end
	if self._track then self._track.BackgroundColor3 = theme:Get("SurfaceSecondary") or theme:Get("Surface") end
	if self._fill then self._fill.BackgroundColor3 = theme:Get("Accent") end
end

return ProgressBar
end)

-- ===== END Components.ProgressBar =====

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
local Feature = __wyvern_require("Components.Feature")
local ProgressBar = __wyvern_require("Components.ProgressBar")
local Flags = __wyvern_require("Core.Flags")

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
	card.Size = UDim2.new(1, 0, 0, 0)
	card.AutomaticSize = Enum.AutomaticSize.Y
	card.ClipsDescendants = true
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
	title.TextTruncate = Enum.TextTruncate.AtEnd
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


function Section:CreateCheckbox(config)
	return self:CreateToggle(config)
end

function Section:CreateParagraph(config)
	return self:CreateLabel(config)
end

function Section:CreateSpacer(config)
	return self:CreateDivider(config)
end

function Section:CreateNotification(config)
	-- Notifications are window-level; no-op section helper would be misleading
	warn("[Wyvern] Use Window:Notify(...) for notifications")
	return nil
end

function Section:CreateProgressBar(config)
	local c = ProgressBar.new(config or {}, self._instance, self._theme, self._search, self._input)
	table.insert(self._components, c)
	return c
end

function Section:AddProgressBar(config)
	return self:CreateProgressBar(config)
end

function Section:CreateFeature(config)
	config = config or {}
	local feature = Feature.new(config, self._instance, self._theme, self._search, self._input)
	table.insert(self._components, feature)
	return feature
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

-- Preferred Add* aliases (Create* retained for compatibility)
function Section:AddButton(c) return self:CreateButton(c) end
function Section:AddToggle(c) return self:CreateToggle(c) end
function Section:AddCheckbox(c) return self:CreateCheckbox(c) end
function Section:AddSlider(c) return self:CreateSlider(c) end
function Section:AddDropdown(c) return self:CreateDropdown(c) end
function Section:AddMultiDropdown(c) return self:CreateMultiDropdown(c) end
function Section:AddTextbox(c) return self:CreateTextbox(c) end
function Section:AddInput(c) return self:CreateInput(c) end
function Section:AddKeybind(c) return self:CreateKeybind(c) end
function Section:AddColorPicker(c) return self:CreateColorPicker(c) end
function Section:AddLabel(c) return self:CreateLabel(c) end
function Section:AddParagraph(c) return self:CreateParagraph(c) end
function Section:AddDivider(c) return self:CreateDivider(c) end
function Section:AddSpacer(c) return self:CreateSpacer(c) end
function Section:AddFeature(c) return self:CreateFeature(c) end
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
	content.ClipsDescendants = true
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
	-- Fill scroll width only; never grow past content viewport
	columns.Size = UDim2.new(1, 0, 0, 0)
	columns.AutomaticSize = Enum.AutomaticSize.Y
	columns.ClipsDescendants = true
	columns.Parent = content
	self._columns = columns

	local left = Instance.new("Frame")
	left.Name = "LeftColumn"
	left.BackgroundTransparency = 1
	left.Size = UDim2.new(0.5, -6, 0, 0)
	left.AutomaticSize = Enum.AutomaticSize.Y
	left.ClipsDescendants = true
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
	right.ClipsDescendants = true
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

function Tab:AddSection(config)
	return self:CreateSection(config)
end
return Tab
end)

-- ===== END Core.Tab =====

-- ===== BEGIN Core.Window (Core/Window.lua) =====

__wyvern_define("Core.Window", function()
-- Window.lua
-- Main floating window with stable positioning, drag, minimize, and navigation.
-- Safe client-side parenting with CoreGui fallback.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local Maid = __wyvern_require("Core.Maid")
local Tab = __wyvern_require("Core.Tab")
local Search = __wyvern_require("Core.Search")
local Input = __wyvern_require("Core.Input")
local Constants = __wyvern_require("Core.Constants")
local Icons = __wyvern_require("Icons.Registry")
local Notification = __wyvern_require("Core.Notification")
local PopupManager = __wyvern_require("Core.PopupManager")

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
		_opacity = 1,
		_glass = false,
		_animationsEnabled = true,
		_autoClosePopups = true,
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

	-- UIScale is parented to the Window main frame (not ScreenGui) so scaling
	-- originates at the window top-left and does NOT rewrite logical Position.
	local uiScale = Instance.new("UIScale")
	uiScale.Scale = self._scale
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
	if self._uiScale then
		self._uiScale.Parent = main
	end
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
	logo.ImageColor3 = theme:Get("Accent")
	pcall(function()
		local src = Icons.Get("Home") or Icons.Get("Settings")
		if type(src) == "string" and src ~= "" then
			logo.Image = src
		end
	end)
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
	closeBtn.Text = ""
	closeBtn.ZIndex = 5
	closeBtn.Parent = header
	Icons.Create(closeBtn, "Close", { Size = 12, Theme = theme, Color = theme:Get("TextSecondary"), ZIndex = 6 })

	local minBtn = Instance.new("TextButton")
	minBtn.Name = "Minimize"
	minBtn.Size = UDim2.fromOffset(28, 28)
	minBtn.Position = UDim2.new(1, -62, 0.5, -14)
	minBtn.BackgroundTransparency = 1
	minBtn.Text = ""
	minBtn.ZIndex = 5
	minBtn.Parent = header
	Icons.Create(minBtn, "Minimize", { Size = 12, Theme = theme, Color = theme:Get("TextSecondary"), ZIndex = 6 })

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
	searchIcon.ImageColor3 = theme:Get("TextSecondary")
	pcall(function()
		local src = Icons.Get("Search")
		if type(src) == "string" and src ~= "" then
			searchIcon.Image = src
		end
	end)
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
	secondary.Size = UDim2.fromOffset(220, 40)
	secondary.BackgroundColor3 = theme:Get("NavBackground")
	secondary.BorderSizePixel = 0
	secondary.Active = false
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
		local btn = Instance.new("TextButton")
		btn.Name = "Nav_" .. iconName
		btn.Size = UDim2.fromOffset(32, 32)
		btn.BackgroundTransparency = 1
		btn.Text = ""
		btn.AutoButtonColor = false
		btn.Parent = parentFrame
		local color = selected and theme:Get("Accent") or theme:Get("TextSecondary")
		local holder = Icons.Create(btn, iconName, { Size = 16, Theme = theme, Color = color, ZIndex = 6 })
		btn:SetAttribute("Selected", selected == true)
		self._maid:Give(btn.MouseEnter:Connect(function()
			if btn:GetAttribute("Selected") then return end
			Icons.SetColor(holder, theme:Get("Text"))
		end))
		self._maid:Give(btn.MouseLeave:Connect(function()
			local c = btn:GetAttribute("Selected") and theme:Get("Accent") or theme:Get("TextSecondary")
			Icons.SetColor(holder, c)
		end))
		return btn
	end

	-- Bottom nav icons — wired to tab selection by index when possible
	local navNames = { "Home", "Eye", "Checklist", "Target", "Settings" }
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

	local secNames = { "Home", "Checklist", "User", "Info", "Settings" }
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

	pcall(function()
		Icons.Preload({ "Home", "Eye", "Checklist", "Settings", "User", "Info", "Close", "Minimize", "Search", "Check", "Back", "Fullscreen", "DropdownDown", "DockHome", "DockSettings", "Palette", "Glass", "Reset", "Center" })
	end)

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
	local x = pos.X.Offset + (Constants.WindowWidth - 220) / 2
	local y = pos.Y.Offset + Constants.WindowHeight + 12
	if self._minimized then
		y = pos.Y.Offset + Constants.HeaderHeight + 22
	end
	self._secondary.Position = UDim2.fromOffset(x, y)
end

function Window:_setIconSelected(btn, selected)
	if not btn then return end
	local theme = self._theme
	btn:SetAttribute("Selected", selected == true)
	local c = selected and theme:Get("Accent") or theme:Get("TextSecondary")
	local holder = btn:FindFirstChild("Icon_" .. (btn.Name:gsub("^Nav_", "") or ""))
	if not holder then
		for _, ch in ipairs(btn:GetChildren()) do
			if ch.Name:match("^Icon_") then
				holder = ch
				break
			end
		end
	end
	if holder then
		Icons.SetColor(holder, c)
	end
end

function Window:_selectNav(index)
	local navCount = #(self._navIcons or {})
	for i, btn in ipairs(self._navIcons or {}) do
		self:_setIconSelected(btn, i == index)
	end
	if index == navCount then
		self:OpenSettings()
		return
	end
	local tab = self._tabs[index]
	if tab and not tab._destroyed then
		tab:Select()
	end
end

function Window:_selectSecondary(index)
	for i, btn in ipairs(self._secIcons or {}) do
		self:_setIconSelected(btn, i == index)
	end
	-- Semantic actions for external bar (not draggable)
	if index == 1 then
		if self._minimized then self:Restore() end
		self:Open()
	elseif index == 2 then
		if self._tabs[1] then self._tabs[1]:Select() end
	elseif index == 3 then
		if self._tabs[2] then self._tabs[2]:Select() end
	elseif index == 4 then
		self:Notify({ Title = "Wyvern", Content = "Wyvern UI Lib " .. tostring(self._version), Duration = 2 })
	elseif index == #(self._secIcons or {}) then
		self:OpenSettings()
	end
end

function Window:SetOpacity(opacity)
	if self._destroyed then return end
	-- Opacity 1.0 = fully opaque, 0.4 = highly translucent (world visible behind).
	self._opacity = math.clamp(tonumber(opacity) or 1, 0.4, 1)
	local glass = self._glass == true
	-- Glass amplifies translucency; solid mode keeps higher opacity floor
	local base = 1 - self._opacity
	local windowT = glass and math.clamp(base * 0.85 + 0.15, 0, 0.75) or math.clamp(base * 0.35, 0, 0.35)
	local surfaceT = glass and math.clamp(base * 0.55, 0, 0.55) or math.clamp(base * 0.15, 0, 0.2)
	local navT = glass and math.clamp(base * 0.5, 0, 0.5) or math.clamp(base * 0.1, 0, 0.15)
	if self._main then
		self._main.BackgroundTransparency = windowT
	end
	if self._searchFrame then
		self._searchFrame.BackgroundTransparency = surfaceT
	end
	if self._bottomNav then
		self._bottomNav.BackgroundTransparency = navT
	end
	if self._secondary then
		self._secondary.BackgroundTransparency = navT
	end
	if self._header then
		self._header.BackgroundTransparency = 1 -- header stays clear of extra fill
	end
end

function Window:GetOpacity()
	return self._opacity or 1
end

function Window:ResetAppearance()
	if self._destroyed or not self._theme then return end
	local Sakura = {
		Background = Color3.fromRGB(18, 14, 24),
		Surface = Color3.fromRGB(30, 24, 38),
		SurfaceSecondary = Color3.fromRGB(38, 30, 48),
		SurfaceHover = Color3.fromRGB(48, 38, 60),
		Accent = Color3.fromRGB(255, 110, 175),
		AccentHover = Color3.fromRGB(255, 135, 190),
		AccentPressed = Color3.fromRGB(220, 85, 150),
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
	self._theme:Apply(Sakura)
	self:_applyChromeTheme()
	self:SetOpacity(1)
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
	if self._settingsTab and not self._settingsTab._destroyed then
		self._settingsTab:Select()
		return
	end
	local tab = self:CreateTab({ Name = "Settings", Icon = "Settings" })
	self._settingsTab = tab
	local appearance = tab:CreateSection({ Name = "Appearance", Column = "Left" })
	local behavior = tab:CreateSection({ Name = "Behavior", Column = "Right" })
	local windowSec = tab:CreateSection({ Name = "Window", Column = "Left" })

	appearance:CreateSlider({
		Name = "UI Scale",
		Min = 0.7,
		Max = 1.4,
		Default = self._scale or 1,
		Increment = 0.05,
		Callback = function(v)
			-- Scale only — does not rewrite Position
			self:SetScale(v)
		end,
	})

	appearance:CreateSlider({
		Name = "UI Opacity",
		Min = 0.4,
		Max = 1,
		Default = self._opacity or 1,
		Increment = 0.05,
		Callback = function(v)
			self:SetOpacity(v)
		end,
	})

	-- Accent only affects accent tokens (NOT Background)
	appearance:CreateColorPicker({
		Name = "Accent",
		Default = self._theme and self._theme:Get("Accent") or Color3.fromRGB(255, 110, 175),
		Callback = function(c)
			if self._theme then
				self._theme:Set("Accent", c)
				self._theme:Set("AccentHover", c)
				self._theme:Set("ToggleOn", c)
				self._theme:Set("SliderFill", c)
			end
			local logo = self._header and self._header:FindFirstChild("Logo")
			if logo then logo.ImageColor3 = c end
		end,
	})

	appearance:CreateColorPicker({
		Name = "Background",
		Default = self._theme and self._theme:Get("Background") or Color3.fromRGB(18, 14, 24),
		Callback = function(c)
			if self._theme then self._theme:Set("Background", c) end
			if self._main then self._main.BackgroundColor3 = c end
		end,
	})

	appearance:CreateColorPicker({
		Name = "Surface",
		Default = self._theme and self._theme:Get("Surface") or Color3.fromRGB(30, 24, 38),
		Callback = function(c)
			if self._theme then
				self._theme:Set("Surface", c)
				self._theme:Set("SurfaceSecondary", c)
			end
		end,
	})

	behavior:CreateToggle({
		Name = "Auto-close Popups",
		Default = self._autoClosePopups ~= false,
		Callback = function(v)
			self._autoClosePopups = v
		end,
	})

	behavior:CreateToggle({
		Name = "Glass Effect",
		Default = false,
		Callback = function(v)
			self._glass = v
			if v then
				self:SetOpacity(math.min(self:GetOpacity(), 0.85))
			else
				self:SetOpacity(1)
			end
		end,
	})

	behavior:CreateToggle({
		Name = "Animations",
		Default = true,
		Callback = function(v)
			self._animationsEnabled = v
		end,
	})

	behavior:CreateDropdown({
		Name = "Animation Speed",
		Options = { "Slow", "Normal", "Fast", "Instant" },
		Default = "Normal",
		Callback = function(v)
			local map = { Slow = 0.6, Normal = 1, Fast = 1.6, Instant = 0 }
			self._animSpeed = map[v] or 1
		end,
	})

	windowSec:CreateButton({
		Name = "Center Window",
		Callback = function()
			if self._main then
				local cam = workspace.CurrentCamera
				local vp = cam and cam.ViewportSize or Vector2.new(1920, 1080)
				local scale = self._scale or 1
				local w = Constants.WindowWidth * scale
				local h = Constants.WindowHeight * scale
				local pos = UDim2.fromOffset(math.max(0, (vp.X - w) / 2), math.max(0, (vp.Y - h) / 2))
				self._main.Position = pos
				self._savedPosition = pos
				self:_syncSecondary()
			end
		end,
	})

	windowSec:CreateButton({
		Name = "Reset Scale",
		Callback = function()
			self:SetScale(1)
		end,
	})

	windowSec:CreateButton({
		Name = "Reset Appearance",
		Callback = function()
			self:ResetAppearance()
		end,
	})

	windowSec:CreateButton({
		Name = "Close Settings",
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

function Window:_animDuration(base)
	if self._animationsEnabled == false then
		return 0
	end
	local speed = self._animSpeed or 1
	if speed <= 0 then
		return 0
	end
	return (base or Constants.PanelDuration or 0.2) / speed
end

function Window:_cancelMinTween()
	if self._minTween then
		pcall(function()
			self._minTween:Cancel()
		end)
		self._minTween = nil
	end
end

function Window:Minimize()
	if self._destroyed then
		return
	end
	if self._windowState == "Minimized" or self._windowState == "Minimizing" then
		return
	end
	pcall(function()
		PopupManager.CloseAll()
	end)
	self._windowState = "Minimizing"
	self._minimized = true
	self._dragging = false
	self._dragPending = false
	self._dragStart = nil
	self._startAbs = nil

	if self._main then
		self._savedPosition = self._main.Position
	end
	if self._searchFrame then self._searchFrame.Visible = false end
	if self._contentContainer then self._contentContainer.Visible = false end
	if self._bottomNav then self._bottomNav.Visible = false end

	self:_cancelMinTween()
	local target = UDim2.fromOffset(Constants.WindowWidth, Constants.HeaderHeight + 10)
	local dur = self:_animDuration(0.18)
	if dur <= 0 or not self._main then
		if self._main then self._main.Size = target end
		self._windowState = "Minimized"
		self:_syncSecondary()
		return
	end
	local tw = TweenService:Create(self._main, TweenInfo.new(dur, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = target,
	})
	self._minTween = tw
	tw.Completed:Connect(function()
		if self._destroyed then return end
		if self._windowState == "Minimizing" then
			self._windowState = "Minimized"
		end
		self._minTween = nil
		self:_syncSecondary()
	end)
	tw:Play()
end

function Window:Restore()
	if self._destroyed then
		return
	end
	if self._windowState == "Visible" or self._windowState == "Restoring" then
		if not self._minimized then return end
	end
	self._windowState = "Restoring"
	self._minimized = false

	self:_cancelMinTween()
	local target = UDim2.fromOffset(Constants.WindowWidth, Constants.WindowHeight)
	local dur = self:_animDuration(0.18)
	if self._main and self._savedPosition then
		self._main.Position = self._savedPosition
	end
	local function finish()
		if self._destroyed then return end
		if self._searchFrame then self._searchFrame.Visible = true end
		if self._contentContainer then self._contentContainer.Visible = true end
		if self._bottomNav then self._bottomNav.Visible = true end
		self._windowState = "Visible"
		self:_syncSecondary()
	end
	if dur <= 0 or not self._main then
		if self._main then self._main.Size = target end
		finish()
		return
	end
	local tw = TweenService:Create(self._main, TweenInfo.new(dur, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = target,
	})
	self._minTween = tw
	tw.Completed:Connect(function()
		if self._destroyed then return end
		self._minTween = nil
		if self._windowState == "Restoring" then
			finish()
		end
	end)
	tw:Play()
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
	-- Authoritative scale only. Does NOT rewrite Position (prevents jump feedback loops).
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

function Window:AddTab(config)
	return self:CreateTab(config)
end

function Window:Show()
	return self:SetVisible(true)
end

function Window:Hide()
	return self:SetVisible(false)
end

function Window:IsVisible()
	return self._instance and self._instance.Visible
end

function Window:IsMinimized()
	return self._minimized == true
end

function Window:GetScale()
	return self._scale or 1
end

function Window:Center()
	if not self._frame then return end
	local cam = workspace.CurrentCamera
	local vp = cam and cam.ViewportSize or Vector2.new(1920, 1080)
	local size = self._frame.AbsoluteSize
	self._frame.Position = UDim2.fromOffset(
		math.floor((vp.X - size.X) / 2),
		math.floor((vp.Y - size.Y) / 2)
	)
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
local Flags = __wyvern_require("Core.Flags")
local Notification = __wyvern_require("Core.Notification")
local Modal = __wyvern_require("Core.Modal")

local Wyvern = {
	_version = "1.0.0",
	_theme = nil,
	_scale = 1,
	Icons = Icons,
	Constants = Constants,
	Version = "1.0.0",
	Flags = Flags,
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

function Wyvern:GetFlag(name)
	return Flags.Get(name)
end

function Wyvern:SetFlag(name, value)
	Flags.Set(name, value)
end

function Wyvern:ResetFlags()
	Flags.Reset()
end

function Wyvern:GetFlags()
	return Flags.GetAll()
end

function Wyvern:Notify(config)
	config = config or {}
	return Notification.Show(config, self._theme)
end

function Wyvern.SendNotification(config)
	return Wyvern:Notify(config)
end


function Wyvern:Confirm(config)
	config = config or {}
	return Modal.Confirm(config, self._theme, nil)
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
