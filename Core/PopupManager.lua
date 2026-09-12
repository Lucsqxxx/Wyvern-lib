-- PopupManager.lua
-- Centralized exclusive popup/dropdown open state + outside-click handling.

local UserInputService = game:GetService("UserInputService")

local PopupManager = {
	_open = nil, -- currently open popup component (must implement :Close())
	_conn = nil,
}

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
		-- Defer so the same click that opens/selects can process first
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
