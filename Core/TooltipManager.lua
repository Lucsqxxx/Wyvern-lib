-- Core/TooltipManager.lua — single shared tooltip overlay
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local TooltipManager = {
	_label = nil,
	_holder = nil,
	_parent = nil,
	_delay = 0.35,
	_pending = nil,
	_target = nil,
}

function TooltipManager.SetParent(parent)
	TooltipManager._parent = parent
	if TooltipManager._holder then
		TooltipManager._holder.Parent = parent
	end
end

function TooltipManager._ensure()
	if TooltipManager._holder and TooltipManager._holder.Parent then
		return
	end
	local parent = TooltipManager._parent
	if not parent then
		return
	end
	local holder = Instance.new("Frame")
	holder.Name = "WyvernTooltip"
	holder.BackgroundColor3 = Color3.fromRGB(22, 20, 30)
	holder.BackgroundTransparency = 0.05
	holder.BorderSizePixel = 0
	holder.Visible = false
	holder.ZIndex = 300
	holder.Size = UDim2.fromOffset(0, 0)
	holder.AutomaticSize = Enum.AutomaticSize.XY
	holder.Parent = parent
	Instance.new("UICorner", holder).CornerRadius = UDim.new(0, 6)
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(70, 65, 90)
	stroke.Transparency = 0.35
	stroke.Parent = holder
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 6)
	pad.PaddingBottom = UDim.new(0, 6)
	pad.PaddingLeft = UDim.new(0, 8)
	pad.PaddingRight = UDim.new(0, 8)
	pad.Parent = holder
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.AutomaticSize = Enum.AutomaticSize.XY
	label.Font = Enum.Font.Gotham
	label.TextSize = 12
	label.TextColor3 = Color3.fromRGB(230, 225, 240)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextWrapped = true
	label.ZIndex = 301
	label.Parent = holder
	local constraint = Instance.new("UISizeConstraint")
	constraint.MaxSize = Vector2.new(260, 120)
	constraint.Parent = label
	TooltipManager._holder = holder
	TooltipManager._label = label
end

function TooltipManager.Show(text, anchor)
	if type(text) ~= "string" or text == "" then
		return
	end
	TooltipManager._ensure()
	if not TooltipManager._holder then
		return
	end
	if TooltipManager._pending then
		task.cancel(TooltipManager._pending)
		TooltipManager._pending = nil
	end
	TooltipManager._target = anchor
	TooltipManager._pending = task.delay(TooltipManager._delay, function()
		TooltipManager._pending = nil
		if not TooltipManager._holder or TooltipManager._target ~= anchor then
			return
		end
		TooltipManager._label.Text = text
		TooltipManager._holder.Visible = true
		TooltipManager._reposition(anchor)
	end)
end

function TooltipManager._reposition(anchor)
	local holder = TooltipManager._holder
	if not holder or not anchor then
		return
	end
	local ap = anchor.AbsolutePosition
	local as = anchor.AbsoluteSize
	local parent = holder.Parent
	local oAbs = parent and parent.AbsolutePosition or Vector2.zero
	local cam = workspace.CurrentCamera
	local vp = cam and cam.ViewportSize or Vector2.new(1920, 1080)
	task.defer(function()
		if not holder.Parent then
			return
		end
		local hs = holder.AbsoluteSize
		local x = ap.X - oAbs.X
		local y = ap.Y - oAbs.Y - hs.Y - 6
		if y < 4 then
			y = ap.Y - oAbs.Y + as.Y + 6
		end
		if x + hs.X > vp.X - 8 then
			x = math.max(4, vp.X - hs.X - 8) - oAbs.X
		end
		if x < 4 then
			x = 4
		end
		holder.Position = UDim2.fromOffset(math.floor(x), math.floor(y))
	end)
end

function TooltipManager.Hide(anchor)
	if anchor and TooltipManager._target ~= anchor then
		return
	end
	if TooltipManager._pending then
		task.cancel(TooltipManager._pending)
		TooltipManager._pending = nil
	end
	TooltipManager._target = nil
	if TooltipManager._holder then
		TooltipManager._holder.Visible = false
	end
end

function TooltipManager.HideAll()
	TooltipManager.Hide(nil)
	TooltipManager._target = nil
end

function TooltipManager.Destroy()
	TooltipManager.HideAll()
	if TooltipManager._holder then
		pcall(function()
			TooltipManager._holder:Destroy()
		end)
		TooltipManager._holder = nil
		TooltipManager._label = nil
	end
end

function TooltipManager.Bind(gui, text)
	if not gui or type(text) ~= "string" then
		return function() end
	end
	local c1 = gui.MouseEnter:Connect(function()
		TooltipManager.Show(text, gui)
	end)
	local c2 = gui.MouseLeave:Connect(function()
		TooltipManager.Hide(gui)
	end)
	return function()
		c1:Disconnect()
		c2:Disconnect()
		TooltipManager.Hide(gui)
	end
end

return TooltipManager
