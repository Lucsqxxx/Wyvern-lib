-- Icons/Registry.lua
-- Image-first when AssetProvider can resolve a ContentId.
-- Safe: never assigns nil/non-string to ImageLabel.Image.

local AssetProvider = require(script.Parent.AssetProvider)
local Renderer = require(script.Parent.Renderer)

local Icons = {
	AssetProvider = AssetProvider,
	Renderer = Renderer,
	-- When image ContentId cannot be resolved, use vector geometry so UI still works.
	AllowVectorFallback = true,
	RepoRawBase = AssetProvider.RepoRaw,
	Files = AssetProvider.FileMap,
	AssetIds = {},
}

local function isValidContentId(s)
	return type(s) == "string" and s ~= "" and s ~= "nil"
end

local function safeSetImage(img, source)
	if not img then
		return false
	end
	if not isValidContentId(source) then
		return false
	end
	local ok = pcall(function()
		img.Image = source
	end)
	return ok
end

function Icons.GetGitHubUrl(name)
	return AssetProvider.GetGitHubUrl(name)
end

function Icons.Get(name)
	if isValidContentId(Icons.AssetIds[name]) then
		return Icons.AssetIds[name]
	end
	local ok, resolved = pcall(AssetProvider.Resolve, name)
	if ok and isValidContentId(resolved) then
		return resolved
	end
	return nil
end

function Icons.SetAsset(name, assetId)
	if type(name) ~= "string" or not isValidContentId(assetId) then
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

	local source = Icons.Get(name)
	if isValidContentId(source) then
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
		if not safeSetImage(img, source) then
			img:Destroy()
			if Icons.AllowVectorFallback then
				Renderer.Create(holder, name, {
					Size = size,
					Color = color,
					Theme = options.Theme,
					ZIndex = z + 1,
				})
			end
		end
	elseif Icons.AllowVectorFallback then
		Renderer.Create(holder, name, {
			Size = size,
			Color = color,
			Theme = options.Theme,
			ZIndex = z + 1,
		})
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
