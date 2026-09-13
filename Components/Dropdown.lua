-- Dropdown.lua
-- First-class single-select dropdown with popup list.

local UserInputService = game:GetService("UserInputService")
local Component = require(script.Parent.Parent.Core.Component)
local Icons = require(script.Parent.Parent.Icons.Registry)
local Animation = require(script.Parent.Parent.Core.Animation)
local Constants = require(script.Parent.Parent.Core.Constants)
local Responsive = require(script.Parent.Parent.Core.Responsive)
local PopupManager = require(script.Parent.Parent.Core.PopupManager)

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
			w = math.clamp(math.floor(aw + 0.5), 96, Responsive.MaxPopupWidth())
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
	local rowH = 26
	local desiredH = math.min(#self._options, 8) * rowH + 10
	desiredH = math.min(desiredH, Responsive.MaxPopupHeight(absPos, absSize))
	local desiredW = math.clamp(math.floor(absSize.X + 0.5), 96, Responsive.MaxPopupWidth())

	local parent = overlay or box
	if popup.Parent ~= parent then
		popup.Parent = parent
	end

	if overlay and parent == overlay then
		local oAbs = overlay.AbsolutePosition
		local x, y, w, h = Responsive.FitPopup(absPos, absSize, desiredW, desiredH, oAbs)
		self._popupWidth = w
		popup.Position = UDim2.fromOffset(x, y)
		popup.Size = UDim2.fromOffset(w, h)
		-- Enable scroll if many options
		if popup:IsA("ScrollingFrame") then
			popup.CanvasSize = UDim2.fromOffset(0, #self._options * rowH + 10)
		end
	else
		local h = math.min(desiredH, 200)
		self._popupWidth = desiredW
		popup.Position = UDim2.new(0, 0, 1, 4)
		popup.Size = UDim2.fromOffset(desiredW, h)
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
