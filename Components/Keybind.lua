-- Keybind.lua

local Component = require(script.Parent.Parent.Core.Component)
local Animation = require(script.Parent.Parent.Core.Animation)
local Constants = require(script.Parent.Parent.Core.Constants)

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
