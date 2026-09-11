-- ColorPicker.lua (basic hue cycle for demonstration)

local Component = require(script.Parent.Parent.Core.Component)
local Constants = require(script.Parent.Parent.Core.Constants)

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
