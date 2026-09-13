-- Components/Table.lua
local Component = require(script.Parent.Parent.Core.Component)

local Table = setmetatable({}, { __index = Component })
Table.__index = Table

function Table.new(config, parent, theme)
	config = config or {}
	local self = setmetatable(Component.new(config), Table)
	self._theme = theme
	self._columns = config.Columns or {}
	self._rows = config.Rows or {}
	self._sortCol = nil
	self._sortAsc = true

	local root = Instance.new("Frame")
	root.Name = "Table"
	root.BackgroundTransparency = 1
	root.Size = UDim2.new(1, 0, 0, 0)
	root.AutomaticSize = Enum.AutomaticSize.Y
	root.ClipsDescendants = true
	root.Parent = parent
	self._instance = root

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, 0, 0, 16)
	title.Font = Enum.Font.GothamMedium
	title.TextSize = 12
	title.TextColor3 = theme:Get("Text")
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextTruncate = Enum.TextTruncate.AtEnd
	title.Text = config.Name or config.Title or "Table"
	title.Parent = root

	local scroll = Instance.new("ScrollingFrame")
	scroll.BackgroundColor3 = theme:Get("SurfaceSecondary") or theme:Get("Surface")
	scroll.BackgroundTransparency = 0.3
	scroll.BorderSizePixel = 0
	scroll.Size = UDim2.new(1, 0, 0, config.Height or 140)
	scroll.Position = UDim2.new(0, 0, 0, 20)
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.ScrollBarThickness = 4
	scroll.ClipsDescendants = true
	scroll.Parent = root
	Instance.new("UICorner", scroll).CornerRadius = UDim.new(0, 6)
	self._scroll = scroll

	local list = Instance.new("UIListLayout")
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = scroll

	self:_rebuild()
	self._maid:Give(root)
	return self
end

function Table:_rebuild()
	if not self._scroll then return end
	for _, ch in ipairs(self._scroll:GetChildren()) do
		if ch:IsA("Frame") or ch:IsA("TextLabel") then
			ch:Destroy()
		end
	end
	local theme = self._theme
	local colCount = math.max(1, #self._columns)
	-- header
	local header = Instance.new("Frame")
	header.BackgroundTransparency = 1
	header.Size = UDim2.new(1, 0, 0, 22)
	header.LayoutOrder = 0
	header.Parent = self._scroll
	for i, col in ipairs(self._columns) do
		local cell = Instance.new("TextButton")
		cell.BackgroundTransparency = 1
		cell.Size = UDim2.new(1 / colCount, -2, 1, 0)
		cell.Position = UDim2.new((i - 1) / colCount, 0, 0, 0)
		cell.Font = Enum.Font.GothamMedium
		cell.TextSize = 11
		cell.TextColor3 = theme:Get("TextSecondary") or theme:Get("Text")
		cell.TextXAlignment = Enum.TextXAlignment.Left
		cell.TextTruncate = Enum.TextTruncate.AtEnd
		cell.Text = tostring(col)
		cell.Parent = header
		local idx = i
		cell.MouseButton1Click:Connect(function()
			if self._sortCol == idx then
				self._sortAsc = not self._sortAsc
			else
				self._sortCol = idx
				self._sortAsc = true
			end
			self:_sort()
			self:_rebuild()
		end)
	end
	if #self._rows == 0 then
		local empty = Instance.new("TextLabel")
		empty.BackgroundTransparency = 1
		empty.Size = UDim2.new(1, 0, 0, 28)
		empty.Font = Enum.Font.Gotham
		empty.TextSize = 12
		empty.TextColor3 = theme:Get("TextMuted") or theme:Get("TextSecondary") or theme:Get("Text")
		empty.Text = "No rows"
		empty.LayoutOrder = 1
		empty.Parent = self._scroll
		return
	end
	for r, row in ipairs(self._rows) do
		local line = Instance.new("Frame")
		line.BackgroundTransparency = 1
		line.Size = UDim2.new(1, 0, 0, 22)
		line.LayoutOrder = r
		line.Parent = self._scroll
		for i = 1, colCount do
			local cell = Instance.new("TextLabel")
			cell.BackgroundTransparency = 1
			cell.Size = UDim2.new(1 / colCount, -2, 1, 0)
			cell.Position = UDim2.new((i - 1) / colCount, 0, 0, 0)
			cell.Font = Enum.Font.Gotham
			cell.TextSize = 11
			cell.TextColor3 = theme:Get("Text")
			cell.TextXAlignment = Enum.TextXAlignment.Left
			cell.TextTruncate = Enum.TextTruncate.AtEnd
			cell.Text = tostring(row[i] or "")
			cell.Parent = line
		end
	end
end

function Table:_sort()
	if not self._sortCol then return end
	local col = self._sortCol
	local asc = self._sortAsc
	table.sort(self._rows, function(a, b)
		local av, bv = tostring(a[col] or ""), tostring(b[col] or "")
		if asc then return av < bv else return av > bv end
	end)
end

function Table:SetRows(rows)
	self._rows = rows or {}
	self:_rebuild()
end
function Table:GetRows()
	return self._rows
end
function Table:AddRow(row)
	table.insert(self._rows, row)
	self:_rebuild()
end
function Table:RemoveRow(index)
	if self._rows[index] then
		table.remove(self._rows, index)
		self:_rebuild()
	end
end
function Table:Clear()
	table.clear(self._rows)
	self:_rebuild()
end
function Table:Refresh()
	self:_rebuild()
end

return Table
