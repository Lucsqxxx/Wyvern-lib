-- Core/Modal.lua — simple confirm dialog on OverlayLayer
local TweenService = game:GetService("TweenService")
local Maid = require(script.Parent.Maid)
local PopupManager = require(script.Parent.PopupManager)

local Modal = {}

function Modal.Confirm(config, theme, parentGui)
	config = config or {}
	local title = config.Title or "Confirm"
	local desc = config.Description or config.Text or ""
	local confirmText = config.ConfirmText or "Confirm"
	local cancelText = config.CancelText or "Cancel"
	local themeGet = theme and function(k) return theme:Get(k) end or function(k)
		local d = {
			Surface = Color3.fromRGB(28, 26, 36),
			Border = Color3.fromRGB(60, 55, 75),
			Text = Color3.fromRGB(235, 230, 245),
			TextSecondary = Color3.fromRGB(160, 155, 175),
			Accent = Color3.fromRGB(180, 120, 255),
		}
		return d[k] or Color3.new(1,1,1)
	end

	local done = false
	local result = false
	local maid = Maid.new()

	local overlay = Instance.new("Frame")
	overlay.Name = "WyvernModalOverlay"
	overlay.BackgroundColor3 = Color3.new(0, 0, 0)
	overlay.BackgroundTransparency = 0.45
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.ZIndex = 200
	overlay.Parent = parentGui or PopupManager.GetOverlay()

	local card = Instance.new("Frame")
	card.Size = UDim2.fromOffset(320, 0)
	card.AutomaticSize = Enum.AutomaticSize.Y
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Position = UDim2.fromScale(0.5, 0.5)
	card.BackgroundColor3 = themeGet("Surface")
	card.BorderSizePixel = 0
	card.ZIndex = 201
	card.Parent = overlay

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = card

	local stroke = Instance.new("UIStroke")
	stroke.Color = themeGet("Border")
	stroke.Transparency = 0.4
	stroke.Parent = card

	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 16)
	pad.PaddingBottom = UDim.new(0, 16)
	pad.PaddingLeft = UDim.new(0, 16)
	pad.PaddingRight = UDim.new(0, 16)
	pad.Parent = card

	local list = Instance.new("UIListLayout")
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, 10)
	list.Parent = card

	local tLabel = Instance.new("TextLabel")
	tLabel.BackgroundTransparency = 1
	tLabel.Size = UDim2.new(1, 0, 0, 20)
	tLabel.Font = Enum.Font.GothamBold
	tLabel.TextSize = 15
	tLabel.TextColor3 = themeGet("Text")
	tLabel.TextXAlignment = Enum.TextXAlignment.Left
	tLabel.Text = title
	tLabel.ZIndex = 202
	tLabel.Parent = card

	if desc ~= "" then
		local dLabel = Instance.new("TextLabel")
		dLabel.BackgroundTransparency = 1
		dLabel.Size = UDim2.new(1, 0, 0, 0)
		dLabel.AutomaticSize = Enum.AutomaticSize.Y
		dLabel.Font = Enum.Font.Gotham
		dLabel.TextSize = 13
		dLabel.TextColor3 = themeGet("TextSecondary")
		dLabel.TextXAlignment = Enum.TextXAlignment.Left
		dLabel.TextWrapped = true
		dLabel.Text = desc
		dLabel.ZIndex = 202
		dLabel.Parent = card
	end

	local row = Instance.new("Frame")
	row.BackgroundTransparency = 1
	row.Size = UDim2.new(1, 0, 0, 32)
	row.ZIndex = 202
	row.Parent = card

	local rowLayout = Instance.new("UIListLayout")
	rowLayout.FillDirection = Enum.FillDirection.Horizontal
	rowLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	rowLayout.Padding = UDim.new(0, 8)
	rowLayout.Parent = row

	local function finish(v)
		if done then return end
		done = true
		result = v
		maid:Destroy()
		pcall(function() overlay:Destroy() end)
	end

	local cancel = Instance.new("TextButton")
	cancel.Size = UDim2.fromOffset(90, 30)
	cancel.BackgroundColor3 = themeGet("Surface")
	cancel.Text = cancelText
	cancel.TextColor3 = themeGet("Text")
	cancel.Font = Enum.Font.GothamMedium
	cancel.TextSize = 13
	cancel.ZIndex = 203
	cancel.Parent = row
	Instance.new("UICorner", cancel).CornerRadius = UDim.new(0, 6)
	cancel.MouseButton1Click:Connect(function() finish(false) end)

	local confirm = Instance.new("TextButton")
	confirm.Size = UDim2.fromOffset(90, 30)
	confirm.BackgroundColor3 = themeGet("Accent")
	confirm.Text = confirmText
	confirm.TextColor3 = Color3.new(1, 1, 1)
	confirm.Font = Enum.Font.GothamMedium
	confirm.TextSize = 13
	confirm.ZIndex = 203
	confirm.Parent = row
	Instance.new("UICorner", confirm).CornerRadius = UDim.new(0, 6)
	confirm.MouseButton1Click:Connect(function() finish(true) end)

	maid:Give(overlay)

	if config.Callback then
		task.spawn(function()
			while not done do task.wait(0.05) end
			pcall(config.Callback, result)
		end)
		return
	end

	while not done do
		task.wait(0.05)
	end
	return result
end

return Modal
