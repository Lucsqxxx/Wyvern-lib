-- Toggle.lua
-- Square-ish toggle matching the reference (pink + check when on)

local Component = require(script.Parent.Parent.Core.Component)
local Animation = require(script.Parent.Parent.Core.Animation)
local Constants = require(script.Parent.Parent.Core.Constants)

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
	self._enabled = enabled
	self._label.TextColor3 = enabled and self._theme:Get("Text") or self._theme:Get("TextDisabled")
	self._switch.BackgroundTransparency = enabled and 0 or 0.45
end

return Toggle
