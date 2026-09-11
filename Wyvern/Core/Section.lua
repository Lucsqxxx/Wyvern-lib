-- Section.lua
-- Reusable card/section that hosts components.

local Maid = require(script.Parent.Maid)
local Constants = require(script.Parent.Constants)

local Button = require(script.Parent.Parent.Components.Button)
local Toggle = require(script.Parent.Parent.Components.Toggle)
local Slider = require(script.Parent.Parent.Components.Slider)
local Keybind = require(script.Parent.Parent.Components.Keybind)
local Label = require(script.Parent.Parent.Components.Label)
local Dropdown = require(script.Parent.Parent.Components.Dropdown)
local Textbox = require(script.Parent.Parent.Components.Textbox)
local ColorPicker = require(script.Parent.Parent.Components.ColorPicker)
local Divider = require(script.Parent.Parent.Components.Divider)

local Section = {}
Section.__index = Section

function Section.new(config, parent, theme, search, inputManager)
	local self = setmetatable({
		_maid = Maid.new(),
		_theme = theme,
		_search = search,
		_input = inputManager,
		_name = config.Name or "Section",
		_components = {},
	}, Section)

	local card = Instance.new("Frame")
	card.Name = "Section_" .. self._name
	card.BackgroundColor3 = theme:Get("Surface")
	card.BorderSizePixel = 0
	card.Size = UDim2.new(1, 0, 0, 0) -- auto size later
	card.AutomaticSize = Enum.AutomaticSize.Y
	card.Parent = parent
	self._instance = card

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, Constants.MediumCornerRadius)
	corner.Parent = card

	local stroke = Instance.new("UIStroke")
	stroke.Color = theme:Get("Border")
	stroke.Thickness = 1
	stroke.Transparency = 0.55
	stroke.Parent = card

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 10)
	padding.PaddingBottom = UDim.new(0, 10)
	padding.PaddingLeft = UDim.new(0, 12)
	padding.PaddingRight = UDim.new(0, 12)
	padding.Parent = card

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, Constants.ComponentSpacing)
	layout.Parent = card

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, 0, 0, 18)
	title.Font = Enum.Font.GothamMedium
	title.TextSize = Constants.SectionTitleSize
	title.TextColor3 = theme:Get("Text")
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = self._name
	title.LayoutOrder = 0
	title.Parent = card
	self._title = title

	self._maid:Give(card)
	return self
end

function Section:_addComponent(comp)
	table.insert(self._components, comp)
	if self._search then
		self._search:Register(comp, self)
	end
	return comp
end

function Section:CreateButton(config)
	local comp = Button.new(config, self._instance, self._theme)
	comp._instance.LayoutOrder = #self._components + 1
	return self:_addComponent(comp)
end

function Section:CreateToggle(config)
	local comp = Toggle.new(config, self._instance, self._theme)
	comp._instance.LayoutOrder = #self._components + 1
	return self:_addComponent(comp)
end

function Section:CreateSlider(config)
	local comp = Slider.new(config, self._instance, self._theme)
	comp._instance.LayoutOrder = #self._components + 1
	return self:_addComponent(comp)
end

function Section:CreateKeybind(config)
	local comp = Keybind.new(config, self._instance, self._theme, self._input)
	comp._instance.LayoutOrder = #self._components + 1
	return self:_addComponent(comp)
end

function Section:CreateLabel(config)
	local comp = Label.new(config, self._instance, self._theme)
	comp._instance.LayoutOrder = #self._components + 1
	return self:_addComponent(comp)
end

function Section:CreateDropdown(config)
	local comp = Dropdown.new(config, self._instance, self._theme)
	comp._instance.LayoutOrder = #self._components + 1
	return self:_addComponent(comp)
end

function Section:CreateTextbox(config)
	local comp = Textbox.new(config, self._instance, self._theme)
	comp._instance.LayoutOrder = #self._components + 1
	return self:_addComponent(comp)
end

function Section:CreateColorPicker(config)
	local comp = ColorPicker.new(config, self._instance, self._theme)
	comp._instance.LayoutOrder = #self._components + 1
	return self:_addComponent(comp)
end

function Section:CreateDivider(config)
	local comp = Divider.new(config, self._instance, self._theme)
	comp._instance.LayoutOrder = #self._components + 1
	return self:_addComponent(comp)
end

-- Simple status indicators row (Header Preview style)
function Section:CreateIndicators(config)
	config = config or {}
	local container = Instance.new("Frame")
	container.Name = "Indicators"
	container.BackgroundTransparency = 1
	container.Size = UDim2.new(1, 0, 0, 22)
	container.LayoutOrder = #self._components + 1
	container.Parent = self._instance

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, -60, 1, 0)
	label.Font = Enum.Font.Gotham
	label.TextSize = 12
	label.TextColor3 = self._theme:Get("Text")
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = config.Name or "Preview"
	label.Parent = container

	local colors = config.Colors or {
		Color3.fromRGB(70, 220, 120),
		Color3.fromRGB(55, 45, 70),
	}

	for i, color in ipairs(colors) do
		local box = Instance.new("Frame")
		box.Size = UDim2.new(0, 16, 0, 16)
		box.Position = UDim2.new(1, -20 - (i - 1) * 22, 0.5, -8)
		box.BackgroundColor3 = color
		box.BorderSizePixel = 0
		box.Parent = container

		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 4)
		c.Parent = box
	end

	self._maid:Give(container)
	return container
end

function Section:SetVisible(visible)
	self._instance.Visible = visible
end

function Section:Destroy()
	for _, comp in ipairs(self._components) do
		comp:Destroy()
	end
	self._maid:Destroy()
	setmetatable(self, nil)
end

return Section
