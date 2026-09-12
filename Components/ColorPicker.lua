-- ColorPicker.lua
-- Real HSV popup color picker (OverlayLayer + PopupManager).

local UserInputService = game:GetService("UserInputService")
local Component = require(script.Parent.Parent.Core.Component)
local Constants = require(script.Parent.Parent.Core.Constants)
local PopupManager = require(script.Parent.Parent.Core.PopupManager)

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
