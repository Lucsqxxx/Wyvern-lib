-- Components/Layout.lua — Row / Column / Card / Group / Container
local Maid = require(script.Parent.Parent.Core.Maid)
local Constants = require(script.Parent.Parent.Core.Constants)

local Layout = {}
Layout.__index = Layout

local function makeContainer(kind, config, parent, theme)
	config = config or {}
	theme = theme or {
		Get = function(_, key)
			local d = {
				Surface = Color3.fromRGB(30, 28, 40),
				SurfaceSecondary = Color3.fromRGB(36, 34, 48),
				Border = Color3.fromRGB(60, 55, 75),
				Text = Color3.fromRGB(230, 225, 240),
			}
			return d[key] or Color3.new(1, 1, 1)
		end,
	}
	local self = setmetatable({
		_maid = Maid.new(),
		_theme = theme,
		_kind = kind,
		_components = {},
		_destroyed = false,
	}, Layout)

	local frame = Instance.new("Frame")
	frame.Name = kind
	frame.BackgroundTransparency = (kind == "Card" or kind == "Group") and 0 or 1
	if kind == "Card" or kind == "Group" then
		frame.BackgroundColor3 = theme:Get("SurfaceSecondary") or theme:Get("Surface")
	end
	frame.BorderSizePixel = 0
	frame.Size = UDim2.new(1, 0, 0, 0)
	frame.AutomaticSize = Enum.AutomaticSize.Y
	frame.ClipsDescendants = true
	frame.Parent = parent
	self._instance = frame

	if kind == "Card" or kind == "Group" then
		Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
		local stroke = Instance.new("UIStroke")
		stroke.Color = theme:Get("Border")
		stroke.Transparency = 0.55
		stroke.Parent = frame
		local pad = Instance.new("UIPadding")
		pad.PaddingTop = UDim.new(0, config.Padding or 8)
		pad.PaddingBottom = UDim.new(0, config.Padding or 8)
		pad.PaddingLeft = UDim.new(0, config.Padding or 10)
		pad.PaddingRight = UDim.new(0, config.Padding or 10)
		pad.Parent = frame
	end

	local list = Instance.new("UIListLayout")
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, config.Gap or (Constants.ComponentSpacing or 6))
	if kind == "Row" then
		list.FillDirection = Enum.FillDirection.Horizontal
		list.VerticalAlignment = Enum.VerticalAlignment.Center
	else
		list.FillDirection = Enum.FillDirection.Vertical
	end
	list.Parent = frame

	self._maid:Give(frame)
	return self
end

function Layout.Row(config, parent, theme)
	return makeContainer("Row", config, parent, theme)
end
function Layout.Column(config, parent, theme)
	return makeContainer("Column", config, parent, theme)
end
function Layout.Card(config, parent, theme)
	return makeContainer("Card", config, parent, theme)
end
function Layout.Group(config, parent, theme)
	return makeContainer("Group", config, parent, theme)
end
function Layout.Container(config, parent, theme)
	return makeContainer("Container", config, parent, theme)
end

function Layout:_host()
	return self._instance
end

function Layout:GetInstance()
	return self._instance
end

-- Forward component factories by requiring Section's modules lazily via shared loaders
local function factories(self)
	local parent = self._instance
	local theme = self._theme
	local Button = require(script.Parent.Button)
	local Toggle = require(script.Parent.Toggle)
	local Slider = require(script.Parent.Slider)
	local Label = require(script.Parent.Label)
	local Dropdown = require(script.Parent.Dropdown)
	local Textbox = require(script.Parent.Textbox)
	local function wrap(ctor, config)
		if self._destroyed then return nil end
		local c = ctor(config or {}, parent, theme, nil, nil)
		if c and c._instance and self._kind == "Row" then
			-- equal share in row
			c._instance.Size = UDim2.new(0, 0, 0, c._instance.Size.Y.Offset)
			c._instance.Size = UDim2.new(1, 0, 0, c._instance.Size.Y.Offset)
			-- for horizontal, use flexible width
			pcall(function()
				c._instance.Size = UDim2.new(0.5, -4, 0, math.max(28, c._instance.Size.Y.Offset))
			end)
		end
		table.insert(self._components, c)
		return c
	end
	return {
		AddButton = function(_, c) return wrap(Button.new, c) end,
		AddToggle = function(_, c) return wrap(Toggle.new, c) end,
		AddSlider = function(_, c) return wrap(Slider.new, c) end,
		AddLabel = function(_, c) return wrap(Label.new, c) end,
		AddDropdown = function(_, c) return wrap(Dropdown.new, c) end,
		AddTextbox = function(_, c) return wrap(Textbox.new, c) end,
	}
end

function Layout:AddButton(c) return factories(self).AddButton(self, c) end
function Layout:AddToggle(c) return factories(self).AddToggle(self, c) end
function Layout:AddSlider(c) return factories(self).AddSlider(self, c) end
function Layout:AddLabel(c) return factories(self).AddLabel(self, c) end
function Layout:AddDropdown(c) return factories(self).AddDropdown(self, c) end
function Layout:AddTextbox(c) return factories(self).AddTextbox(self, c) end

function Layout:Destroy()
	if self._destroyed then return end
	self._destroyed = true
	for _, c in ipairs(self._components) do
		pcall(function() c:Destroy() end)
	end
	self._maid:Destroy()
end

return Layout
