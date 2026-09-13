-- Notification.lua
-- Centralized toast/notification manager.

local TweenService = game:GetService("TweenService")
local Maid = require(script.Parent.Maid)
local Constants = require(script.Parent.Constants)

local Notification = {}
Notification.__index = Notification

local Active = {}
local MAX_STACK = 5

function Notification.new(parentGui, theme)
	local self = setmetatable({
		_maid = Maid.new(),
		_theme = theme,
		_parent = parentGui,
		_stack = {},
		_destroyed = false,
	}, Notification)

	local holder = Instance.new("Frame")
	holder.Name = "WyvernNotifications"
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.new(0, 300, 1, 0)
	holder.Position = UDim2.new(1, -320, 0, 20)
	holder.AnchorPoint = Vector2.new(0, 0)
	holder.Parent = parentGui
	self._holder = holder

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 8)
	layout.VerticalAlignment = Enum.VerticalAlignment.Top
	layout.Parent = holder

	self._maid:Give(holder)
	return self
end

function Notification:Notify(config)
	if self._destroyed then return end
	config = config or {}
	local title = config.Title or "Wyvern"
	local content = config.Content or config.Message or ""
	local duration = tonumber(config.Duration) or 3
	local theme = self._theme

	-- Limit stack
	while #self._stack >= MAX_STACK do
		local oldest = table.remove(self._stack, 1)
		if oldest and oldest.Destroy then
			pcall(function() oldest:Destroy() end)
		end
	end

	local card = Instance.new("Frame")
	card.Name = "Toast"
	card.BackgroundColor3 = theme:Get("Surface")
	card.BorderSizePixel = 0
	card.Size = UDim2.new(1, 0, 0, 0)
	card.AutomaticSize = Enum.AutomaticSize.Y
	card.BackgroundTransparency = 1
	card.Parent = self._holder

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = card

	local stroke = Instance.new("UIStroke")
	stroke.Color = theme:Get("Border")
	stroke.Thickness = 1
	stroke.Transparency = 0.4
	stroke.Parent = card

	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 10)
	pad.PaddingBottom = UDim.new(0, 10)
	pad.PaddingLeft = UDim.new(0, 12)
	pad.PaddingRight = UDim.new(0, 12)
	pad.Parent = card

	local titleLabel = Instance.new("TextLabel")
	titleLabel.BackgroundTransparency = 1
	titleLabel.Size = UDim2.new(1, -20, 0, 16)
	titleLabel.Font = Enum.Font.GothamMedium
	titleLabel.TextSize = 13
	titleLabel.TextColor3 = theme:Get("Text")
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Text = title
	titleLabel.Parent = card

	local body = Instance.new("TextLabel")
	body.BackgroundTransparency = 1
	body.Size = UDim2.new(1, 0, 0, 0)
	body.AutomaticSize = Enum.AutomaticSize.Y
	body.Position = UDim2.new(0, 0, 0, 18)
	body.Font = Enum.Font.Gotham
	body.TextSize = 12
	body.TextColor3 = theme:Get("TextSecondary")
	body.TextXAlignment = Enum.TextXAlignment.Left
	body.TextWrapped = true
	body.Text = content
	body.Parent = card

	local close = Instance.new("TextButton")
	close.Size = UDim2.new(0, 18, 0, 18)
	close.Position = UDim2.new(1, -18, 0, 0)
	close.BackgroundTransparency = 1
	close.Text = "×"
	close.Font = Enum.Font.GothamBold
	close.TextSize = 14
	close.TextColor3 = theme:Get("TextSecondary")
	close.Parent = card

	-- Fade in
	TweenService:Create(card, TweenInfo.new(0.2), { BackgroundTransparency = 0 }):Play()

	local function dismiss()
		local idx = table.find(self._stack, card)
		if idx then table.remove(self._stack, idx) end
		local tw = TweenService:Create(card, TweenInfo.new(0.18), { BackgroundTransparency = 1 })
		tw:Play()
		tw.Completed:Connect(function()
			pcall(function() card:Destroy() end)
		end)
	end

	close.MouseButton1Click:Connect(dismiss)

	table.insert(self._stack, card)

	if duration > 0 then
		task.delay(duration, function()
			if card and card.Parent then
				dismiss()
			end
		end)
	end

	return {
		Destroy = dismiss,
	}
end

function Notification:Destroy()
	if self._destroyed then return end
	self._destroyed = true
	for _, c in ipairs(self._stack) do
		pcall(function() c:Destroy() end)
	end
	table.clear(self._stack)
	self._maid:Destroy()
	setmetatable(self, nil)
end

-- Library-level helper: creates a temporary ScreenGui toast stack if needed
function Notification.Show(config, theme)
	config = config or {}
	local playerGui = nil
	pcall(function()
		local lp = game:GetService("Players").LocalPlayer
		playerGui = lp and (lp:FindFirstChildOfClass("PlayerGui") or lp:WaitForChild("PlayerGui", 2))
	end)
	local parent = playerGui
	if not parent then
		pcall(function()
			parent = game:GetService("CoreGui")
		end)
	end
	if not parent then
		warn("[Wyvern] Notify: no ParentGui available")
		return
	end
	local holderName = "WyvernLibNotifications"
	local holder = parent:FindFirstChild(holderName)
	if not holder then
		local sg = Instance.new("ScreenGui")
		sg.Name = holderName
		sg.ResetOnSpawn = false
		sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		sg.DisplayOrder = 1000
		pcall(function()
			sg.Parent = parent
		end)
		holder = sg
	end
	local mgr = Notification.new(holder, theme or {
		Get = function(_, k)
			local defaults = {
				Surface = Color3.fromRGB(30, 28, 40),
				Border = Color3.fromRGB(60, 55, 75),
				Text = Color3.fromRGB(230, 225, 240),
				TextSecondary = Color3.fromRGB(160, 155, 175),
				Accent = Color3.fromRGB(180, 120, 255),
			}
			return defaults[k] or Color3.new(1, 1, 1)
		end,
	})
	-- adapt config keys
	local adapted = {
		Title = config.Title or config.title,
		Content = config.Text or config.text or config.Content or config.Message,
		Duration = config.Duration or config.duration,
	}
	return mgr:Notify(adapted)
end

return Notification
