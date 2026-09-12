-- Tab.lua

local Maid = require(script.Parent.Maid)
local Section = require(script.Parent.Section)
local Constants = require(script.Parent.Constants)
local Icons = require(script.Parent.Parent.Icons.Registry)

local Tab = {}
Tab.__index = Tab

function Tab.new(config, window, theme, search, inputManager)
	local self = setmetatable({
		_maid = Maid.new(),
		_window = window,
		_theme = theme,
		_search = search,
		_input = inputManager,
		_name = config.Name or "Tab",
		_icon = config.Icon or "Settings",
		_selected = false,
		_sections = {},
	}, Tab)

	-- Content frame (two-column capable)
	local content = Instance.new("ScrollingFrame")
	content.Name = "TabContent_" .. self._name
	content.BackgroundTransparency = 1
	content.BorderSizePixel = 0
	content.Size = UDim2.new(1, 0, 1, 0)
	content.CanvasSize = UDim2.new(0, 0, 0, 0)
	content.AutomaticCanvasSize = Enum.AutomaticSize.Y
	content.ScrollBarThickness = 3
	content.ScrollBarImageColor3 = theme:Get("Border")
	content.ClipsDescendants = true
	content.Visible = false
	content.Parent = window._contentContainer
	self._content = content

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 8)
	padding.PaddingBottom = UDim.new(0, 60) -- space for bottom nav
	padding.PaddingLeft = UDim.new(0, 10)
	padding.PaddingRight = UDim.new(0, 10)
	padding.Parent = content

	-- Two column layout
	local columns = Instance.new("Frame")
	columns.Name = "Columns"
	columns.BackgroundTransparency = 1
	-- Fill scroll width only; never grow past content viewport
	columns.Size = UDim2.new(1, 0, 0, 0)
	columns.AutomaticSize = Enum.AutomaticSize.Y
	columns.ClipsDescendants = true
	columns.Parent = content
	self._columns = columns

	local left = Instance.new("Frame")
	left.Name = "LeftColumn"
	left.BackgroundTransparency = 1
	left.Size = UDim2.new(0.5, -6, 0, 0)
	left.AutomaticSize = Enum.AutomaticSize.Y
	left.ClipsDescendants = true
	left.Parent = columns
	self._left = left

	local leftLayout = Instance.new("UIListLayout")
	leftLayout.SortOrder = Enum.SortOrder.LayoutOrder
	leftLayout.Padding = UDim.new(0, Constants.SectionSpacing)
	leftLayout.Parent = left

	local right = Instance.new("Frame")
	right.Name = "RightColumn"
	right.BackgroundTransparency = 1
	right.Size = UDim2.new(0.5, -6, 0, 0)
	right.Position = UDim2.new(0.5, 6, 0, 0)
	right.AutomaticSize = Enum.AutomaticSize.Y
	right.ClipsDescendants = true
	right.Parent = columns
	self._right = right

	local rightLayout = Instance.new("UIListLayout")
	rightLayout.SortOrder = Enum.SortOrder.LayoutOrder
	rightLayout.Padding = UDim.new(0, Constants.SectionSpacing)
	rightLayout.Parent = right

	self._maid:Give(content)
	return self
end

function Tab:CreateSection(config)
	-- Alternate columns for visual balance if not specified
	local target = self._left
	if config.Column == "Right" or (#self._sections % 2 == 1 and config.Column ~= "Left") then
		target = self._right
	end
	if config.Column == "Left" then
		target = self._left
	end

	local section = Section.new(config, target, self._theme, self._search, self._input)
	section._instance.LayoutOrder = #self._sections + 1
	table.insert(self._sections, section)
	return section
end

function Tab:Select()
	if self._selected then return end
	self._selected = true
	self._content.Visible = true
	if self._window then
		self._window:_onTabSelected(self)
	end
end

function Tab:Deselect()
	self._selected = false
	self._content.Visible = false
end

function Tab:IsSelected()
	return self._selected
end

function Tab:SetVisible(visible)
	self._content.Visible = visible and self._selected
end

function Tab:Destroy()
	for _, section in ipairs(self._sections) do
		section:Destroy()
	end
	self._maid:Destroy()
	setmetatable(self, nil)
end

return Tab

function Tab:AddSection(config)
	return self:CreateSection(config)
end
