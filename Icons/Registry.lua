-- Icons/Registry.lua
-- Canonical icon artwork lives in the GitHub repository:
--   assets/icons/<name>.png
-- Raw URL pattern:
--   https://raw.githubusercontent.com/Lucsqxxx/Wyvern-lib/main/assets/icons/<name>.png
--
-- Roblox ImageLabel/ImageButton cannot load arbitrary HTTPS URLs as Image.
-- Runtime therefore uses Icons.Renderer (vector primitives matching the sheet).
-- Optional: after uploading a PNG to Roblox Creator, set AssetIds[Name] = "rbxassetid://...".
-- Never invent placeholder asset IDs.

local Renderer = require(script.Parent.Renderer)

local REPO_RAW = "https://raw.githubusercontent.com/Lucsqxxx/Wyvern-lib/main/assets/icons"

local FILE_MAP = {
	Back = "back.png",
	Forward = "forward.png",
	ChevronLeft = "chevron_left.png",
	ChevronRight = "chevron_right.png",
	ChevronDown = "chevron_down.png",
	ChevronUp = "chevron_up.png",
	Minimize = "minimize.png",
	Maximize = "maximize.png",
	Fullscreen = "fullscreen.png",
	Close = "close.png",
	Search = "search.png",
	Eye = "eye.png",
	Check = "check.png",
	CheckboxEmpty = "checkbox_empty.png",
	CheckboxChecked = "checkbox_checked.png",
	Reset = "reset.png",
	Center = "center.png",
	Info = "info.png",
	User = "user.png",
	Settings = "settings.png",
	Home = "home.png",
	Palette = "palette.png",
	Scale = "scale.png",
	Glass = "glass.png",
	Checklist = "checklist.png",
	Plus = "plus.png",
	Minus = "minus.png",
	Input = "input.png",
	Textbox = "textbox.png",
	Keybind = "keybind.png",
	DropdownDown = "dropdown_down.png",
	DropdownUp = "dropdown_up.png",
	DockHome = "dock_home.png",
	DockTab1 = "dock_tab1.png",
	DockTab2 = "dock_tab2.png",
	DockAbout = "dock_about.png",
	DockSettings = "dock_settings.png",
}

local Icons = {
	Renderer = Renderer,
	RepoRawBase = REPO_RAW,
	Files = FILE_MAP,
	-- Only verified Roblox asset IDs (empty by default — no fakes)
	AssetIds = {},
}

function Icons.GetGitHubUrl(name)
	local file = FILE_MAP[name]
	if not file then
		return nil
	end
	return REPO_RAW .. "/" .. file
end

function Icons.Get(name)
	local id = Icons.AssetIds[name]
	if type(id) == "string" and id ~= "" then
		return id
	end
	return nil
end

function Icons.SetAsset(name, assetId)
	if type(name) ~= "string" or type(assetId) ~= "string" then
		return
	end
	if not string.match(assetId, "^rbxassetid://%d+$") then
		warn("[Wyvern Icons] refusing non-rbxassetid value for", name)
		return
	end
	Icons.AssetIds[name] = assetId
end

function Icons.Create(parent, name, options)
	options = options or {}
	local assetId = Icons.Get(name)
	if assetId then
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
	-- Self-contained runtime path (loadstring dist): vector matching the sheet language
	return Renderer.Create(parent, name, options)
end

function Icons.SetColor(holder, color)
	if not holder then
		return
	end
	local img = holder:FindFirstChildWhichIsA("ImageLabel", true)
	if img then
		img.ImageColor3 = color
		return
	end
	local root = holder:FindFirstChild("IconRoot")
	if not root then
		return
	end
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("Frame") then
			if d.BackgroundTransparency < 1 then
				d.BackgroundColor3 = color
			end
			local stroke = d:FindFirstChildOfClass("UIStroke")
			if stroke then
				stroke.Color = color
			end
		end
	end
end

function Icons.Has(name)
	return FILE_MAP[name] ~= nil or Renderer.Builders[name] ~= nil
end

return Icons
