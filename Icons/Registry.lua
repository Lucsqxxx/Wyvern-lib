-- Icons/Registry.lua
-- Central icon entry: primitive Renderer (preferred).

local Renderer = require(script.Parent.Renderer)

local Icons = {
	Renderer = Renderer,
}

function Icons.Create(parent, name, options)
	return Renderer.Create(parent, name, options)
end

function Icons.Get(name)
	-- legacy image id API kept for compatibility; returns empty asset
	return "rbxassetid://0"
end

function Icons.SetColor(holder, color)
	if not holder then return end
	local root = holder:FindFirstChild("IconRoot")
	if not root then return end
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

return Icons
