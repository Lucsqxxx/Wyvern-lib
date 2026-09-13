-- PopupManager.lua
-- Centralized exclusive popup/dropdown open state + outside-click handling.
-- Popups should parent to an overlay layer (screen space), not clipped content.

local UserInputService = game:GetService("UserInputService")

local PopupManager = {
	_open = nil,
	_conn = nil,
	_overlay = nil, -- Frame parent for screen-space popups
}

function PopupManager.SetOverlay(overlay)
	PopupManager._overlay = overlay
end

function PopupManager.GetOverlay()
	return PopupManager._overlay
end

function PopupManager.RegisterOpen(component)
	if PopupManager._open and PopupManager._open ~= component then
		pcall(function()
			PopupManager._open:Close()
		end)
	end
	PopupManager._open = component
	PopupManager._ensureListener()
end

function PopupManager.RegisterClose(component)
	if PopupManager._open == component then
		PopupManager._open = nil
	end
end

function PopupManager.CloseAll()
	if PopupManager._open then
		local current = PopupManager._open
		PopupManager._open = nil
		pcall(function()
			current:Close()
		end)
	end
end

function PopupManager.GetOpen()
	return PopupManager._open
end

function PopupManager._ensureListener()
	if PopupManager._conn then
		return
	end
	PopupManager._conn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		local open = PopupManager._open
		if not open or open._destroyed then
			PopupManager._open = nil
			return
		end
		task.defer(function()
			local current = PopupManager._open
			if not current or current._destroyed or not current._open then
				return
			end
			local pos = input.Position
			local inside = false
			if typeof(current.IsPointInside) == "function" then
				inside = current:IsPointInside(pos)
			elseif current._box and current._popup then
				local function hit(gui)
					if not gui or not gui.Visible then
						return false
					end
					local ap = gui.AbsolutePosition
					local as = gui.AbsoluteSize
					return pos.X >= ap.X and pos.X <= ap.X + as.X and pos.Y >= ap.Y and pos.Y <= ap.Y + as.Y
				end
				inside = hit(current._box) or hit(current._popup)
			end
			if not inside then
				pcall(function()
					current:Close()
				end)
			end
		end)
	end)
end

return PopupManager

function PopupManager.OpenContextMenu(items, position, theme)
	PopupManager.CloseAll()
	local overlay = PopupManager.GetOverlay()
	if not overlay or type(items) ~= "table" then
		return
	end
	local menu = Instance.new("Frame")
	menu.Name = "ContextMenu"
	menu.BackgroundColor3 = theme and theme:Get("Surface") or Color3.fromRGB(30, 28, 40)
	menu.BorderSizePixel = 0
	menu.Size = UDim2.fromOffset(160, 0)
	menu.AutomaticSize = Enum.AutomaticSize.Y
	menu.ZIndex = 120
	menu.ClipsDescendants = true
	menu.Parent = overlay
	Instance.new("UICorner", menu).CornerRadius = UDim.new(0, 8)
	local stroke = Instance.new("UIStroke")
	stroke.Color = theme and theme:Get("Border") or Color3.fromRGB(60, 55, 75)
	stroke.Parent = menu
	local list = Instance.new("UIListLayout")
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = menu
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 4)
	pad.PaddingBottom = UDim.new(0, 4)
	pad.Parent = menu
	local x = position and position.X or 0
	local y = position and position.Y or 0
	local oAbs = overlay.AbsolutePosition
	menu.Position = UDim2.fromOffset(x - oAbs.X, y - oAbs.Y)
	for i, item in ipairs(items) do
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, 0, 0, 28)
		btn.BackgroundTransparency = 1
		btn.Text = "  " .. tostring(item.Title or item.Name or "Item")
		btn.TextColor3 = item.Destructive and Color3.fromRGB(255, 100, 100) or (theme and theme:Get("Text") or Color3.new(1,1,1))
		btn.Font = Enum.Font.Gotham
		btn.TextSize = 12
		btn.TextXAlignment = Enum.TextXAlignment.Left
		btn.ZIndex = 121
		btn.LayoutOrder = i
		btn.Parent = menu
		btn.MouseButton1Click:Connect(function()
			PopupManager.CloseAll()
			if menu then menu:Destroy() end
			if type(item.Callback) == "function" then
				task.spawn(item.Callback)
			end
		end)
	end
	local proxy = {
		_popup = menu,
		_open = true,
		Close = function(self)
			self._open = false
			if menu then pcall(function() menu:Destroy() end) end
			PopupManager.RegisterClose(self)
		end,
		IsPointInside = function(_, pos)
			if not menu then return false end
			local ap, as = menu.AbsolutePosition, menu.AbsoluteSize
			return pos.X >= ap.X and pos.X <= ap.X + as.X and pos.Y >= ap.Y and pos.Y <= ap.Y + as.Y
		end,
	}
	PopupManager.RegisterOpen(proxy)
	return proxy
end
