-- Slider.lua

local UserInputService = game:GetService("UserInputService")
local Component = require(script.Parent.Parent.Core.Component)
local Animation = require(script.Parent.Parent.Core.Animation)
local Constants = require(script.Parent.Parent.Core.Constants)
local Maid = require(script.Parent.Parent.Core.Maid)

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

return Slider
