-- Components/ProgressBar.lua
local Component = require(script.Parent.Parent.Core.Component)
local Constants = require(script.Parent.Parent.Core.Constants)

local ProgressBar = setmetatable({}, { __index = Component })
ProgressBar.__index = ProgressBar

function ProgressBar.new(config, parent, theme, search, inputManager)
	config = config or {}
	local self = setmetatable(Component.new(config), ProgressBar)
	self._theme = theme
	self._value = tonumber(config.Default) or tonumber(config.Value) or 0
	self._min = tonumber(config.Min) or 0
	self._max = tonumber(config.Max) or 100
	if self._max <= self._min then self._max = self._min + 1 end

	local row = Instance.new("Frame")
	row.Name = "ProgressBar"
	row.BackgroundTransparency = 1
	row.Size = UDim2.new(1, 0, 0, 28)
	row.ClipsDescendants = true
	row.Parent = parent
	self._instance = row

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, -40, 0, 14)
	label.Font = Enum.Font.Gotham
	label.TextSize = 12
	label.TextColor3 = theme:Get("Text")
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextTruncate = Enum.TextTruncate.AtEnd
	label.Text = config.Name or config.Title or "Progress"
	label.Parent = row
	self._label = label

	local pct = Instance.new("TextLabel")
	pct.BackgroundTransparency = 1
	pct.Size = UDim2.new(0, 36, 0, 14)
	pct.Position = UDim2.new(1, -36, 0, 0)
	pct.Font = Enum.Font.GothamMedium
	pct.TextSize = 11
	pct.TextColor3 = theme:Get("TextSecondary") or theme:Get("Text")
	pct.TextXAlignment = Enum.TextXAlignment.Right
	pct.Parent = row
	self._pct = pct

	local track = Instance.new("Frame")
	track.Name = "Track"
	track.BackgroundColor3 = theme:Get("SurfaceSecondary") or theme:Get("Surface")
	track.BorderSizePixel = 0
	track.Size = UDim2.new(1, 0, 0, 6)
	track.Position = UDim2.new(0, 0, 0, 18)
	track.Parent = row
	Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)
	self._track = track

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.BackgroundColor3 = theme:Get("Accent")
	fill.BorderSizePixel = 0
	fill.Size = UDim2.new(0, 0, 1, 0)
	fill.Parent = track
	Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
	self._fill = fill

	self:Set(self._value)
	self._maid:Give(row)
	return self
end

function ProgressBar:Set(value)
	value = math.clamp(tonumber(value) or 0, self._min, self._max)
	self._value = value
	local alpha = (value - self._min) / (self._max - self._min)
	if self._fill then
		self._fill.Size = UDim2.new(alpha, 0, 1, 0)
	end
	if self._pct then
		self._pct.Text = tostring(math.floor(alpha * 100 + 0.5)) .. "%"
	end
	Component.Set(self, value)
end

function ProgressBar:SetProgress(v)
	self:Set(v)
end

function ProgressBar:ApplyTheme(theme)
	self._theme = theme
	if self._label then self._label.TextColor3 = theme:Get("Text") end
	if self._track then self._track.BackgroundColor3 = theme:Get("SurfaceSecondary") or theme:Get("Surface") end
	if self._fill then self._fill.BackgroundColor3 = theme:Get("Accent") end
end

return ProgressBar
