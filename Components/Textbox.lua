-- Textbox.lua

local Component = require(script.Parent.Parent.Core.Component)
local Constants = require(script.Parent.Parent.Core.Constants)

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
