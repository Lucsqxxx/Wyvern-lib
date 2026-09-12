-- Components/Feature.lua
-- Nested feature/module card: title, description, optional enable toggle, child controls.
-- Width is always 100% of parent section; only height auto-sizes.

local Maid = require(script.Parent.Parent.Core.Maid)
local Constants = require(script.Parent.Parent.Core.Constants)
local Flags = require(script.Parent.Parent.Core.Flags)

local Button = require(script.Parent.Button)
local Toggle = require(script.Parent.Toggle)
local Slider = require(script.Parent.Slider)
local Keybind = require(script.Parent.Keybind)
local Label = require(script.Parent.Label)
local Dropdown = require(script.Parent.Dropdown)
local MultiDropdown = require(script.Parent.MultiDropdown)
local Textbox = require(script.Parent.Textbox)
local ColorPicker = require(script.Parent.ColorPicker)
local Divider = require(script.Parent.Divider)

local Feature = {}
Feature.__index = Feature

local function wireFlag(comp, flag, getFn, setFn)
	if type(flag) ~= "string" or not comp then
		return
	end
	local existing = Flags.Get(flag)
	if existing ~= nil and setFn then
		pcall(setFn, existing)
	elseif getFn then
		local ok, v = pcall(getFn)
		if ok then
			Flags.Set(flag, v)
		end
	end
	if comp.ValueChanged and comp.ValueChanged.Connect then
		comp.ValueChanged:Connect(function(v)
			Flags.Set(flag, v)
		end)
	end
end

function Feature.new(config, parent, theme, search, inputManager)
	config = config or {}
	local self = setmetatable({
		_maid = Maid.new(),
		_theme = theme,
		_search = search,
		_input = inputManager,
		_name = config.Name or config.title or "Feature",
		_description = config.Description or config.description or "",
		_components = {},
		_enabled = config.Enabled ~= false and config.Default ~= false,
		_callback = config.Callback or config.callback,
		_flag = config.Flag or config.flag,
	}, Feature)

	if self._flag then
		local stored = Flags.Get(self._flag)
		if stored ~= nil then
			self._enabled = stored and true or false
		else
			Flags.Set(self._flag, self._enabled)
		end
	end

	local card = Instance.new("Frame")
	card.Name = "Feature_" .. self._name
	card.BackgroundColor3 = theme:Get("SurfaceSecondary") or theme:Get("Surface")
	card.BorderSizePixel = 0
	card.Size = UDim2.new(1, 0, 0, 0)
	card.AutomaticSize = Enum.AutomaticSize.Y
	card.ClipsDescendants = true
	card.Parent = parent
	self._instance = card

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = card

	local stroke = Instance.new("UIStroke")
	stroke.Color = theme:Get("Border")
	stroke.Thickness = 1
	stroke.Transparency = 0.6
	stroke.Parent = card

	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 8)
	pad.PaddingBottom = UDim.new(0, 8)
	pad.PaddingLeft = UDim.new(0, 10)
	pad.PaddingRight = UDim.new(0, 10)
	pad.Parent = card

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 6)
	layout.Parent = card

	local header = Instance.new("Frame")
	header.Name = "Header"
	header.BackgroundTransparency = 1
	header.Size = UDim2.new(1, 0, 0, 0)
	header.AutomaticSize = Enum.AutomaticSize.Y
	header.LayoutOrder = 0
	header.Parent = card

	local headerLayout = Instance.new("UIListLayout")
	headerLayout.SortOrder = Enum.SortOrder.LayoutOrder
	headerLayout.Padding = UDim.new(0, 2)
	headerLayout.Parent = header

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, -40, 0, 16)
	title.Font = Enum.Font.GothamMedium
	title.TextSize = 13
	title.TextColor3 = theme:Get("Text")
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextTruncate = Enum.TextTruncate.AtEnd
	title.Text = self._name
	title.LayoutOrder = 1
	title.Parent = header
	self._title = title

	if self._description ~= "" then
		local desc = Instance.new("TextLabel")
		desc.Name = "Description"
		desc.BackgroundTransparency = 1
		desc.Size = UDim2.new(1, 0, 0, 0)
		desc.AutomaticSize = Enum.AutomaticSize.Y
		desc.Font = Enum.Font.Gotham
		desc.TextSize = 11
		desc.TextColor3 = theme:Get("TextSecondary") or theme:Get("TextMuted") or theme:Get("Text")
		desc.TextXAlignment = Enum.TextXAlignment.Left
		desc.TextWrapped = true
		desc.Text = self._description
		desc.LayoutOrder = 2
		desc.Parent = header
		self._desc = desc
	end

	-- Optional enable switch row
	if config.ShowEnable ~= false and (config.Enabled ~= nil or config.Callback or config.callback or self._flag) then
		local toggle = Toggle.new({
			Name = "Enabled",
			Default = self._enabled,
			Callback = function(v)
				self._enabled = v
				if self._flag then
					Flags.Set(self._flag, v)
				end
				if self._callback then
					task.spawn(function()
						local ok, err = pcall(self._callback, v)
						if not ok then
							warn("[Wyvern Feature] callback error:", err)
						end
					end)
				end
			end,
		}, card, theme, search, inputManager)
		toggle._instance.LayoutOrder = 1
		self._enableToggle = toggle
		table.insert(self._components, toggle)
	end

	local body = Instance.new("Frame")
	body.Name = "Body"
	body.BackgroundTransparency = 1
	body.Size = UDim2.new(1, 0, 0, 0)
	body.AutomaticSize = Enum.AutomaticSize.Y
	body.ClipsDescendants = true
	body.LayoutOrder = 10
	body.Parent = card
	self._body = body

	local bodyLayout = Instance.new("UIListLayout")
	bodyLayout.SortOrder = Enum.SortOrder.LayoutOrder
	bodyLayout.Padding = UDim.new(0, Constants.ComponentSpacing or 6)
	bodyLayout.Parent = body

	self._maid:Give(card)
	return self
end

function Feature:_add(comp)
	if not comp then
		return
	end
	table.insert(self._components, comp)
	if comp._instance then
		comp._instance.Parent = self._body
		comp._instance.Size = UDim2.new(1, 0, 0, comp._instance.Size.Y.Offset)
	end
	return comp
end

local function normalize(config)
	config = config or {}
	if config.title and not config.Name then
		config.Name = config.title
	end
	if config.flag and not config.Flag then
		config.Flag = config.flag
	end
	if config.callback and not config.Callback then
		config.Callback = config.callback
	end
	if config.minimum_value and not config.Min then
		config.Min = config.minimum_value
	end
	if config.maximum_value and not config.Max then
		config.Max = config.maximum_value
	end
	if config.value ~= nil and config.Default == nil then
		config.Default = config.value
	end
	if config.placeholder and not config.Placeholder then
		config.Placeholder = config.placeholder
	end
	if config.options and not config.Options then
		config.Options = config.options
	end
	return config
end

function Feature:CreateButton(config)
	config = normalize(config)
	local c = Button.new(config, self._body, self._theme, self._search, self._input)
	return self:_add(c)
end

function Feature:CreateToggle(config)
	config = normalize(config)
	local c = Toggle.new(config, self._body, self._theme, self._search, self._input)
	wireFlag(c, config.Flag, function()
		return c:Get()
	end, function(v)
		c:Set(v)
	end)
	return self:_add(c)
end

function Feature:CreateCheckbox(config)
	return self:CreateToggle(config)
end

function Feature:CreateSlider(config)
	config = normalize(config)
	local c = Slider.new(config, self._body, self._theme, self._search, self._input)
	wireFlag(c, config.Flag, function()
		return c:Get()
	end, function(v)
		c:Set(v)
	end)
	return self:_add(c)
end

function Feature:CreateDropdown(config)
	config = normalize(config)
	local c
	if config.multi_dropdown or config.Multi then
		c = MultiDropdown.new(config, self._body, self._theme, self._search, self._input)
	else
		c = Dropdown.new(config, self._body, self._theme, self._search, self._input)
	end
	wireFlag(c, config.Flag, function()
		return c:Get()
	end, function(v)
		c:Set(v)
	end)
	return self:_add(c)
end

function Feature:CreateMultiDropdown(config)
	config = normalize(config)
	config.Multi = true
	return self:CreateDropdown(config)
end

function Feature:CreateTextbox(config)
	config = normalize(config)
	local c = Textbox.new(config, self._body, self._theme, self._search, self._input)
	wireFlag(c, config.Flag, function()
		return c:Get()
	end, function(v)
		c:Set(v)
	end)
	return self:_add(c)
end

function Feature:CreateInput(config)
	return self:CreateTextbox(config)
end

function Feature:CreateKeybind(config)
	config = normalize(config)
	local c = Keybind.new(config, self._body, self._theme, self._search, self._input)
	return self:_add(c)
end

function Feature:CreateColorPicker(config)
	config = normalize(config)
	local c = ColorPicker.new(config, self._body, self._theme, self._search, self._input)
	return self:_add(c)
end

function Feature:CreateLabel(config)
	config = normalize(config)
	return self:_add(Label.new(config, self._body, self._theme, self._search, self._input))
end

function Feature:CreateParagraph(config)
	return self:CreateLabel(config)
end

function Feature:CreateDivider(config)
	return self:_add(Divider.new(config or {}, self._body, self._theme, self._search, self._input))
end

-- snake_case aliases matching reference style
function Feature:create_checkbox(c)
	return self:CreateCheckbox(c)
end
function Feature:create_slider(c)
	return self:CreateSlider(c)
end
function Feature:create_dropdown(c)
	return self:CreateDropdown(c)
end
function Feature:create_textbox(c)
	return self:CreateTextbox(c)
end
function Feature:create_button(c)
	return self:CreateButton(c)
end

function Feature:GetEnabled()
	return self._enabled
end

function Feature:SetEnabled(v)
	self._enabled = v and true or false
	if self._enableToggle then
		self._enableToggle:Set(self._enabled)
	end
	if self._flag then
		Flags.Set(self._flag, self._enabled)
	end
end

function Feature:Destroy()
	for _, c in ipairs(self._components) do
		pcall(function()
			c:Destroy()
		end)
	end
	self._maid:Destroy()
	setmetatable(self, nil)
end

return Feature
