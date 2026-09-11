-- Dropdown.lua (simplified functional version)

local Component = require(script.Parent.Parent.Core.Component)
local Animation = require(script.Parent.Parent.Core.Animation)
local Constants = require(script.Parent.Parent.Core.Constants)

local Dropdown = setmetatable({}, { __index = Component })
Dropdown.__index = Dropdown

function Dropdown.new(config, parent, theme)
	local self = setmetatable(Component.new(config), Dropdown)
	self._theme = theme
	self._options = config.Options or {}
	self._value = config.Default or (self._options[1] or "")

	local container = Instance.new("Frame")
	container.Name = "Dropdown_" .. (config.Name or "Dropdown")
	container.BackgroundTransparency = 1
	container.Size = UDim2.new(1, 0, 0, Constants.ControlHeight)
	container.Parent = parent
	self._instance = container

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(0.45, 0, 1, 0)
	label.Font = Enum.Font.Gotham
	label.TextSize = Constants.LabelSize
	label.TextColor3 = theme:Get("Text")
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = config.Name or "Dropdown"
	label.Parent = container

	local box = Instance.new("TextButton")
	box.Name = "Box"
	box.Size = UDim2.new(0.5, 0, 0, 24)
	box.Position = UDim2.new(0.5, 0, 0.5, -12)
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
	text.Size = UDim2.new(1, -8, 1, 0)
	text.Position = UDim2.new(0, 4, 0, 0)
	text.Font = Enum.Font.Gotham
	text.TextSize = 11
	text.TextColor3 = theme:Get("Text")
	text.TextXAlignment = Enum.TextXAlignment.Left
	text.Text = tostring(self._value)
	text.Parent = box
	self._text = text

	-- Simple cycle on click for demo purposes
	local idx = table.find(self._options, self._value) or 1
	self._maid:Give(box.MouseButton1Click:Connect(function()
		if not self._enabled then return end
		idx = (idx % #self._options) + 1
		self:Set(self._options[idx])
	end))

	self._maid:Give(container)
	return self
end

function Dropdown:Set(value)
	self._value = value
	self._text.Text = tostring(value)
	self.ValueChanged:Fire(value)
	for _, cb in ipairs(self._callbacks) do
		task.spawn(cb, value)
	end
end

return Dropdown
