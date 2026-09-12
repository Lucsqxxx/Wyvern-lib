-- Icons/Registry.lua
-- Image-first icon system. GitHub PNGs are source of truth (assets/icons/).
-- Runtime resolves via Icons/AssetProvider when custom-asset APIs exist.

local AssetProvider = require(script.Parent.AssetProvider)
-- Vector renderer kept ONLY as explicit offline fallback (disabled by default)
local Renderer = require(script.Parent.Renderer)

local Icons = {
	AssetProvider = AssetProvider,
	Renderer = Renderer,
	-- AllowVectorFallback = false by default
	AllowVectorFallback = false,
	RepoRawBase = AssetProvider.RepoRaw,
	Files = AssetProvider.FileMap,
	AssetIds = {}, -- optional verified rbxassetid overrides only
}

function Icons.GetGitHubUrl(name)
	return AssetProvider.GetGitHubUrl(name)
end

function Icons.Get(name)
	if Icons.AssetIds[name] then
		return Icons.AssetIds[name]
	end
	return AssetProvider.Resolve(name)
end

function Icons.SetAsset(name, assetId)
	if type(name) ~= "string" or type(assetId) ~= "string" then
		return
	end
	if not string.match(assetId, "^rbxassetid://%d+$") then
		warn("[Wyvern Icons] refusing non-rbxassetid for", name)
		return
	end
	Icons.AssetIds[name] = assetId
end

function Icons.Create(parent, name, options)
	options = options or {}
	local size = options.Size or 16
	local color = options.Color or Color3.fromRGB(180, 175, 195)
	local z = options.ZIndex or 5

	local holder = Instance.new("Frame")
	holder.Name = "Icon_" .. tostring(name)
	holder.BackgroundTransparency = 1
	holder.Size = options.FullSize or UDim2.fromScale(1, 1)
	holder.ZIndex = z
	holder.Parent = parent
	holder:SetAttribute("IconName", name)

	local img = Instance.new("ImageLabel")
	img.Name = "Image"
	img.BackgroundTransparency = 1
	img.Size = UDim2.fromOffset(size, size)
	img.Position = UDim2.fromScale(0.5, 0.5)
	img.AnchorPoint = Vector2.new(0.5, 0.5)
	img.ScaleType = Enum.ScaleType.Fit
	img.ImageColor3 = color
	img.ZIndex = z + 1
	img.Parent = holder

	local source = Icons.AssetIds[name]
	if type(source) ~= "string" or source == "" then
		local ok, resolved = pcall(AssetProvider.Resolve, name)
		if ok and type(resolved) == "string" and resolved ~= "" then
			source = resolved
		else
			source = nil
		end
	end
	if type(source) == "string" and source ~= "" then
		img.Image = source
	else
		-- Never assign nil to Image (ContentId expected)
		img.Image = ""
		img.Visible = false
		if Icons.AllowVectorFallback then
			img.Visible = false
			local vectorHolder = Renderer.Create(holder, name, options)
			vectorHolder.Size = UDim2.fromScale(1, 1)
		end
	end

	return holder
end

function Icons.SetColor(holder, color)
	if not holder then
		return
	end
	local img = holder:FindFirstChild("Image")
	if img and img:IsA("ImageLabel") then
		img.ImageColor3 = color
		return
	end
	-- vector fallback children if any
	local root = holder:FindFirstChild("IconRoot")
	if root then
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
end

function Icons.Has(name)
	return AssetProvider.FileMap[name] ~= nil
end

function Icons.Preload(names)
	AssetProvider.Preload(names)
end

return Icons
