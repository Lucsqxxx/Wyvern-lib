-- Icons/Registry.lua
-- Central icon provider.
-- Runtime rendering uses Icons.Renderer (vector primitives matching the Wyvern icon sheet).
-- Cropped sheet artwork is stored under assets/icons/*.png for documentation and
-- optional Roblox asset upload (ImageLabel requires rbxassetid — not embeddable in loadstring).

local Renderer = require(script.Parent.Renderer)

local Icons = {
	Renderer = Renderer,
	-- Optional: after uploading assets/icons/*.png to Roblox, set IDs here.
	AssetIds = {
		-- Search = "rbxassetid://123",
	},
	SheetNames = {
		"Back", "Forward", "ChevronLeft", "ChevronRight", "ChevronDown", "ChevronUp",
		"Minimize", "Maximize", "Fullscreen", "Close", "Search", "Eye",
		"Check", "CheckboxEmpty", "CheckboxChecked", "Reset", "Center", "Info",
		"User", "Settings", "Home", "Palette", "Scale", "Glass",
		"Checklist", "Plus", "Minus", "Input", "Textbox", "Keybind",
		"DropdownDown", "DropdownUp", "Lock", "Notification", "Favorite", "Link", "Delete",
	},
}

function Icons.Create(parent, name, options)
	options = options or {}
	-- Prefer vector renderer (self-contained in dist/loadstring).
	-- If AssetIds[name] is set, ImageLabel path can be used by host apps.
	local assetId = Icons.AssetIds[name]
	if type(assetId) == "string" and assetId ~= "" and assetId ~= "rbxassetid://0" then
		local holder = Instance.new("Frame")
		holder.Name = "Icon_" .. tostring(name)
		holder.BackgroundTransparency = 1
		holder.Size = options.FullSize or UDim2.fromScale(1, 1)
		holder.ZIndex = options.ZIndex or 5
		holder.Parent = parent
		local img = Instance.new("ImageLabel")
		img.BackgroundTransparency = 1
		img.Size = UDim2.fromOffset(options.Size or 16, options.Size or 16)
		img.Position = UDim2.fromScale(0.5, 0.5)
		img.AnchorPoint = Vector2.new(0.5, 0.5)
		img.Image = assetId
		img.ImageColor3 = options.Color or Color3.fromRGB(170, 160, 185)
		img.ZIndex = (options.ZIndex or 5) + 1
		img.Parent = holder
		holder:SetAttribute("IconName", name)
		return holder
	end
	return Renderer.Create(parent, name, options)
end

function Icons.Get(name)
	return Icons.AssetIds[name] or "rbxassetid://0"
end

function Icons.SetAsset(name, assetId)
	if type(name) == "string" and type(assetId) == "string" then
		Icons.AssetIds[name] = assetId
	end
end

function Icons.SetColor(holder, color)
	if not holder then return end
	local img = holder:FindFirstChildWhichIsA("ImageLabel", true)
	if img then
		img.ImageColor3 = color
		return
	end
	local root = holder:FindFirstChild("IconRoot")
	if not root then return end
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("Frame") then
			if d.BackgroundTransparency < 1 then
				d.BackgroundColor3 = color
			end
			local stroke = d:FindFirstChildOfClass("UIStroke")
			if stroke then stroke.Color = color end
		end
	end
end

function Icons.Has(name)
	return Renderer.Builders[name] ~= nil or Icons.AssetIds[name] ~= nil
end

return Icons
