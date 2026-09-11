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
