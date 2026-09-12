-- Button.lua

local Component = require(script.Parent.Parent.Core.Component)
local Animation = require(script.Parent.Parent.Core.Animation)
local Constants = require(script.Parent.Parent.Core.Constants)

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
