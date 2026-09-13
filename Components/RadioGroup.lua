-- Components/RadioGroup.lua
local Component = require(script.Parent.Parent.Core.Component)

local RadioGroup = setmetatable({}, { __index = Component })
RadioGroup.__index = RadioGroup

function RadioGroup.new(config, parent, theme)
	config = config or {}
	local self = setmetatable(Component.new(config), RadioGroup)
	self._theme = theme
	self._options = config.Options or {}
	self._value = config.Default or self._options[1]
	self._buttons = {}

	local root = Instance.new("Frame")
	root.Name = "RadioGroup"
	root.BackgroundTransparency = 1
	root.Size = UDim2.new(1, 0, 0, 0)
	root.AutomaticSize = Enum.AutomaticSize.Y
	root.ClipsDescendants = true
	root.Parent = parent
	self._instance = root

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, 0, 0, 16)
	title.Font = Enum.Font.Gotham
	title.TextSize = 12
	title.TextColor3 = theme:Get("Text")
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextTruncate = Enum.TextTruncate.AtEnd
	title.Text = config.Name or config.Title or "Options"
	title.Parent = root

	local list = Instance.new("UIListLayout")
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, 4)
	list.Parent = root

	for i, opt in ipairs(self._options) do
		local row = Instance.new("TextButton")
		row.Name = "Opt_" .. i
		row.BackgroundTransparency = 1
		row.Size = UDim2.new(1, 0, 0, 22)
		row.LayoutOrder = i
		row.Text = ""
		row.Parent = root

		local dot = Instance.new("Frame")
		dot.Size = UDim2.fromOffset(14, 14)
		dot.Position = UDim2.new(0, 0, 0.5, -7)
		dot.BackgroundColor3 = theme:Get("Surface")
		dot.BorderSizePixel = 0
		dot.Parent = row
		Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
		local stroke = Instance.new("UIStroke")
		stroke.Color = theme:Get("Border")
		stroke.Parent = dot
		local inner = Instance.new("Frame")
		inner.Name = "Inner"
		inner.AnchorPoint = Vector2.new(0.5, 0.5)
		inner.Position = UDim2.fromScale(0.5, 0.5)
		inner.Size = UDim2.fromOffset(8, 8)
		inner.BackgroundColor3 = theme:Get("Accent")
		inner.BorderSizePixel = 0
		inner.Visible = (opt == self._value)
		inner.Parent = dot
		Instance.new("UICorner", inner).CornerRadius = UDim.new(1, 0)

		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Position = UDim2.new(0, 22, 0, 0)
		label.Size = UDim2.new(1, -22, 1, 0)
		label.Font = Enum.Font.Gotham
		label.TextSize = 12
		label.TextColor3 = theme:Get("Text")
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.TextTruncate = Enum.TextTruncate.AtEnd
		label.Text = tostring(opt)
		label.Parent = row

		row.MouseButton1Click:Connect(function()
			if not self:GetEnabled() then return end
			self:Set(opt)
		end)
		self._buttons[opt] = inner
	end

	self._maid:Give(root)
	return self
end

function RadioGroup:Set(value)
	if self._destroyed then return end
	self._value = value
	for opt, inner in pairs(self._buttons) do
		inner.Visible = (opt == value)
	end
	Component.Set(self, value)
end

function RadioGroup:GetValue()
	return self:Get()
end
function RadioGroup:SetValue(v)
	self:Set(v)
end

return RadioGroup
