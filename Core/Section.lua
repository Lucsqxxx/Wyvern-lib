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
local MultiDropdown = require(script.Parent.Parent.Components.MultiDropdown)
local Textbox = require(script.Parent.Parent.Components.Textbox)
local ColorPicker = require(script.Parent.Parent.Components.ColorPicker)
local Divider = require(script.Parent.Parent.Components.Divider)
local Feature = require(script.Parent.Parent.Components.Feature)
local ProgressBar = require(script.Parent.Parent.Components.ProgressBar)
local TableComp = require(script.Parent.Parent.Components.Table)
local RadioGroup = require(script.Parent.Parent.Components.RadioGroup)
local Switch = require(script.Parent.Parent.Components.Switch)
local TooltipManager = require(script.Parent.TooltipManager)
local Flags = require(script.Parent.Flags)

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
		_registry = config.Registry,
		_searchIndex = config.SearchIndex,
	}, Section)

	local card = Instance.new("Frame")
	card.Name = "Section_" .. self._name
	card.BackgroundColor3 = theme:Get("Surface")
	card.BorderSizePixel = 0
	card.Size = UDim2.new(1, 0, 0, 0)
	card.AutomaticSize = Enum.AutomaticSize.Y
	card.ClipsDescendants = true
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
	title.TextTruncate = Enum.TextTruncate.AtEnd
	title.Text = self._name
	title.LayoutOrder = 0
	title.Parent = card
	self._title = title

	self._maid:Give(card)
	return self
end


function Section:_finalize(comp, config)
	config = config or {}
	if not comp then return end
	table.insert(self._components, comp)
	if config.Tooltip and comp._instance then
		local unbind = TooltipManager.Bind(comp._instance, config.Tooltip)
		if comp._maid and unbind then
			comp._maid:Give(unbind)
		end
	end
	if config.ID and self._registry then
		self._registry:Register(config.ID, comp)
		if comp._maid then
			comp._maid:Give(function()
				self._registry:Unregister(config.ID)
			end)
		end
	end
	if self._searchIndex and config.ID then
		self._searchIndex:Register({
			Id = config.ID,
			Title = config.Name or config.Title or config.ID,
			Description = config.Description or "",
			Category = self._name,
			Keywords = config.Keywords or {},
			Target = comp,
		})
		if comp._maid then
			comp._maid:Give(function()
				self._searchIndex:Unregister(config.ID)
			end)
		end
	end
	return comp
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

function Section:CreateMultiDropdown(config)
	local comp = MultiDropdown.new(config, self._instance, self._theme)
	comp._instance.LayoutOrder = #self._components + 1
	return self:_addComponent(comp)
end

function Section:CreateTextbox(config)
	local comp = Textbox.new(config, self._instance, self._theme)
	comp._instance.LayoutOrder = #self._components + 1
	return self:_addComponent(comp)
end

-- Alias for developer expectation
function Section:CreateInput(config)
	return self:CreateTextbox(config)
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


function Section:CreateCheckbox(config)
	return self:CreateToggle(config)
end

function Section:CreateParagraph(config)
	return self:CreateLabel(config)
end

function Section:CreateSpacer(config)
	return self:CreateDivider(config)
end

function Section:CreateNotification(config)
	-- Notifications are window-level; no-op section helper would be misleading
	warn("[Wyvern] Use Window:Notify(...) for notifications")
	return nil
end

function Section:CreateProgressBar(config)
	local c = ProgressBar.new(config or {}, self._instance, self._theme, self._search, self._input)
	table.insert(self._components, c)
	return c
end

function Section:AddProgressBar(config)
	return self:CreateProgressBar(config)
end


function Section:CreateTable(config)
	local c = TableComp.new(config or {}, self._instance, self._theme)
	return self:_finalize(c, config)
end
function Section:AddTable(c) return self:CreateTable(c) end

function Section:CreateRadioGroup(config)
	local c = RadioGroup.new(config or {}, self._instance, self._theme)
	return self:_finalize(c, config)
end
function Section:AddRadioGroup(c) return self:CreateRadioGroup(c) end

function Section:CreateSwitch(config)
	local c = Switch.new(config or {}, self._instance, self._theme, self._search, self._input)
	return self:_finalize(c, config)
end
function Section:AddSwitch(c) return self:CreateSwitch(c) end

function Section:CreateRow(config)
	local c = Layout.Row(config or {}, self._instance, self._theme)
	table.insert(self._components, c)
	return c
end
function Section:AddRow(c) return self:CreateRow(c) end

function Section:CreateColumn(config)
	local c = Layout.Column(config or {}, self._instance, self._theme)
	table.insert(self._components, c)
	return c
end
function Section:AddColumn(c) return self:CreateColumn(c) end

function Section:CreateCard(config)
	local c = Layout.Card(config or {}, self._instance, self._theme)
	table.insert(self._components, c)
	return c
end
function Section:AddCard(c) return self:CreateCard(c) end

function Section:CreateGroup(config)
	local c = Layout.Group(config or {}, self._instance, self._theme)
	table.insert(self._components, c)
	return c
end
function Section:AddGroup(c) return self:CreateGroup(c) end

function Section:CreateContainer(config)
	local c = Layout.Container(config or {}, self._instance, self._theme)
	table.insert(self._components, c)
	return c
end
function Section:AddContainer(c) return self:CreateContainer(c) end

function Section:CreateFeature(config)
	config = config or {}
	local feature = Feature.new(config, self._instance, self._theme, self._search, self._input)
	table.insert(self._components, feature)
	return feature
end

function Section:SetVisible(visible)
	self._instance.Visible = visible
end

function Section:Destroy()
	for _, comp in ipairs(self._components) do
		if comp and type(comp.Destroy) == "function" then
			pcall(function()
				comp:Destroy()
			end)
		end
	end
	self._components = {}
	self._maid:Destroy()
	setmetatable(self, nil)
end

-- Preferred Add* aliases (Create* retained for compatibility)
function Section:AddButton(c) return self:CreateButton(c) end
function Section:AddToggle(c) return self:CreateToggle(c) end
function Section:AddCheckbox(c) return self:CreateCheckbox(c) end
function Section:AddSlider(c) return self:CreateSlider(c) end
function Section:AddDropdown(c) return self:CreateDropdown(c) end
function Section:AddMultiDropdown(c) return self:CreateMultiDropdown(c) end
function Section:AddTextbox(c) return self:CreateTextbox(c) end
function Section:AddInput(c) return self:CreateInput(c) end
function Section:AddKeybind(c) return self:CreateKeybind(c) end
function Section:AddColorPicker(c) return self:CreateColorPicker(c) end
function Section:AddLabel(c) return self:CreateLabel(c) end
function Section:AddParagraph(c) return self:CreateParagraph(c) end
function Section:AddDivider(c) return self:CreateDivider(c) end
function Section:AddSpacer(c) return self:CreateSpacer(c) end
function Section:AddFeature(c) return self:CreateFeature(c) end
return Section
