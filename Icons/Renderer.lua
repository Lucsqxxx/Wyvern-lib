-- Icons/Renderer.lua
-- Vector-like icons built from Roblox GUI primitives (no Unicode, no external assets).

local Renderer = {}

local DEFAULT_SIZE = 16
local STROKE = 1.5

local function themeColor(theme, key, fallback)
	if theme and theme.Get then
		local c = theme:Get(key)
		if c then return c end
	end
	return fallback or Color3.fromRGB(170, 160, 185)
end

local function frame(parent, props)
	local f = Instance.new("Frame")
	f.BorderSizePixel = 0
	f.BackgroundColor3 = props.Color or Color3.new(1, 1, 1)
	f.BackgroundTransparency = props.Transparency or 0
	f.Size = props.Size or UDim2.fromOffset(2, 2)
	f.Position = props.Position or UDim2.fromOffset(0, 0)
	f.AnchorPoint = props.AnchorPoint or Vector2.new(0, 0)
	f.Rotation = props.Rotation or 0
	f.ZIndex = props.ZIndex or 2
	f.Parent = parent
	if props.Corner then
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(props.Corner == true and 1 or 0, typeof(props.Corner) == "number" and props.Corner or 0)
		c.Parent = f
	end
	if props.Stroke then
		local s = Instance.new("UIStroke")
		s.Color = props.Stroke
		s.Thickness = props.StrokeThickness or STROKE
		s.Parent = f
	end
	return f
end

--- Root container for an icon
local function root(parent, size, z)
	local r = Instance.new("Frame")
	r.Name = "IconRoot"
	r.BackgroundTransparency = 1
	r.Size = UDim2.fromOffset(size, size)
	r.Position = UDim2.fromScale(0.5, 0.5)
	r.AnchorPoint = Vector2.new(0.5, 0.5)
	r.ZIndex = z or 2
	r.Parent = parent
	return r
end

local builders = {}

function builders.Close(r, color, size)
	local t = math.max(1, size * 0.1)
	local len = size * 0.55
	local c1 = frame(r, {
		Size = UDim2.fromOffset(len, t),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Rotation = 45,
		Color = color,
		Corner = 1,
	})
	frame(r, {
		Size = UDim2.fromOffset(len, t),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Rotation = -45,
		Color = color,
		Corner = 1,
	})
end

function builders.Minimize(r, color, size)
	local t = math.max(1, size * 0.1)
	frame(r, {
		Size = UDim2.fromOffset(size * 0.55, t),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Color = color,
		Corner = 1,
	})
end

function builders.Back(r, color, size)
	-- chevron left from two strokes
	local t = math.max(1, size * 0.09)
	local len = size * 0.32
	frame(r, {
		Size = UDim2.fromOffset(len, t),
		Position = UDim2.fromScale(0.55, 0.35),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Rotation = 40,
		Color = color,
		Corner = 1,
	})
	frame(r, {
		Size = UDim2.fromOffset(len, t),
		Position = UDim2.fromScale(0.55, 0.65),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Rotation = -40,
		Color = color,
		Corner = 1,
	})
end

function builders.Search(r, color, size)
	local d = size * 0.45
	frame(r, {
		Size = UDim2.fromOffset(d, d),
		Position = UDim2.fromScale(0.38, 0.38),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Color = color,
		Transparency = 1,
		Stroke = color,
		StrokeThickness = math.max(1, size * 0.1),
		Corner = true,
	})
	local t = math.max(1, size * 0.1)
	frame(r, {
		Size = UDim2.fromOffset(size * 0.28, t),
		Position = UDim2.fromScale(0.68, 0.68),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Rotation = 45,
		Color = color,
		Corner = 1,
	})
end

function builders.Eye(r, color, size)
	-- almond via wide oval stroke + pupil
	local w, h = size * 0.7, size * 0.42
	frame(r, {
		Size = UDim2.fromOffset(w, h),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Color = color,
		Transparency = 1,
		Stroke = color,
		StrokeThickness = math.max(1, size * 0.1),
		Corner = true,
	})
	local p = size * 0.22
	frame(r, {
		Size = UDim2.fromOffset(p, p),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Color = color,
		Corner = true,
	})
end

function builders.Settings(r, color, size)
	-- gear: ring + 6 teeth
	local ring = size * 0.42
	frame(r, {
		Size = UDim2.fromOffset(ring, ring),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Color = color,
		Transparency = 1,
		Stroke = color,
		StrokeThickness = math.max(1, size * 0.1),
		Corner = true,
	})
	local hub = size * 0.16
	frame(r, {
		Size = UDim2.fromOffset(hub, hub),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Color = color,
		Corner = true,
	})
	local toothW = size * 0.12
	local toothH = size * 0.22
	for i = 0, 5 do
		local ang = i * 60
		frame(r, {
			Size = UDim2.fromOffset(toothW, toothH),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Rotation = ang,
			Color = color,
			Corner = 1,
		})
	end
end

function builders.User(r, color, size)
	local head = size * 0.28
	frame(r, {
		Size = UDim2.fromOffset(head, head),
		Position = UDim2.fromScale(0.5, 0.32),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Color = color,
		Corner = true,
	})
	frame(r, {
		Size = UDim2.fromOffset(size * 0.55, size * 0.32),
		Position = UDim2.fromScale(0.5, 0.72),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Color = color,
		Corner = size * 0.2,
	})
end

function builders.Checklist(r, color, size)
	-- list card
	frame(r, {
		Size = UDim2.fromOffset(size * 0.55, size * 0.7),
		Position = UDim2.fromScale(0.52, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Color = color,
		Transparency = 1,
		Stroke = color,
		StrokeThickness = math.max(1, size * 0.09),
		Corner = 2,
	})
	local t = math.max(1, size * 0.08)
	for i = 1, 3 do
		frame(r, {
			Size = UDim2.fromOffset(size * 0.28, t),
			Position = UDim2.fromScale(0.58, 0.28 + (i - 1) * 0.2),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Color = color,
			Corner = 1,
		})
	end
	-- small check marks left
	for i = 1, 3 do
		frame(r, {
			Size = UDim2.fromOffset(size * 0.1, t),
			Position = UDim2.fromScale(0.32, 0.28 + (i - 1) * 0.2),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Color = color,
			Corner = 1,
		})
	end
end

function builders.Layers(r, color, size)
	local t = math.max(1, size * 0.08)
	for i = 0, 2 do
		frame(r, {
			Size = UDim2.fromOffset(size * 0.55, t),
			Position = UDim2.fromScale(0.5, 0.3 + i * 0.2),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Color = color,
			Corner = 1,
		})
	end
end

function builders.Target(r, color, size)
	frame(r, {
		Size = UDim2.fromOffset(size * 0.65, size * 0.65),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Color = color,
		Transparency = 1,
		Stroke = color,
		StrokeThickness = math.max(1, size * 0.09),
		Corner = true,
	})
	frame(r, {
		Size = UDim2.fromOffset(size * 0.35, size * 0.35),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Color = color,
		Transparency = 1,
		Stroke = color,
		StrokeThickness = math.max(1, size * 0.09),
		Corner = true,
	})
	frame(r, {
		Size = UDim2.fromOffset(size * 0.12, size * 0.12),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Color = color,
		Corner = true,
	})
end

function builders.Play(r, color, size)
	-- triangle approx with rotated rects is hard; use small filled chevron
	local t = math.max(1, size * 0.12)
	frame(r, {
		Size = UDim2.fromOffset(size * 0.35, t),
		Position = UDim2.fromScale(0.55, 0.35),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Rotation = 35,
		Color = color,
		Corner = 1,
	})
	frame(r, {
		Size = UDim2.fromOffset(size * 0.35, t),
		Position = UDim2.fromScale(0.55, 0.65),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Rotation = -35,
		Color = color,
		Corner = 1,
	})
	frame(r, {
		Size = UDim2.fromOffset(t, size * 0.4),
		Position = UDim2.fromScale(0.38, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Color = color,
		Corner = 1,
	})
end

function builders.Cube(r, color, size)
	frame(r, {
		Size = UDim2.fromOffset(size * 0.5, size * 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Color = color,
		Transparency = 1,
		Stroke = color,
		StrokeThickness = math.max(1, size * 0.1),
		Corner = 2,
	})
end

function builders.Users(r, color, size)
	builders.User(r, color, size * 0.85)
end

function builders.Home(r, color, size)
	-- roof + body
	local t = math.max(1, size * 0.1)
	frame(r, {
		Size = UDim2.fromOffset(size * 0.55, t),
		Position = UDim2.fromScale(0.5, 0.38),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Rotation = 35,
		Color = color,
		Corner = 1,
	})
	frame(r, {
		Size = UDim2.fromOffset(size * 0.55, t),
		Position = UDim2.fromScale(0.5, 0.38),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Rotation = -35,
		Color = color,
		Corner = 1,
	})
	frame(r, {
		Size = UDim2.fromOffset(size * 0.45, size * 0.35),
		Position = UDim2.fromScale(0.5, 0.68),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Color = color,
		Transparency = 1,
		Stroke = color,
		StrokeThickness = t,
		Corner = 2,
	})
end

function builders.Check(r, color, size)
	local t = math.max(1, size * 0.1)
	frame(r, {
		Size = UDim2.fromOffset(size * 0.25, t),
		Position = UDim2.fromScale(0.35, 0.55),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Rotation = 45,
		Color = color,
		Corner = 1,
	})
	frame(r, {
		Size = UDim2.fromOffset(size * 0.45, t),
		Position = UDim2.fromScale(0.58, 0.45),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Rotation = -45,
		Color = color,
		Corner = 1,
	})
end

function builders.ChevronDown(r, color, size)
	local t = math.max(1, size * 0.09)
	frame(r, {
		Size = UDim2.fromOffset(size * 0.32, t),
		Position = UDim2.fromScale(0.35, 0.45),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Rotation = 40,
		Color = color,
		Corner = 1,
	})
	frame(r, {
		Size = UDim2.fromOffset(size * 0.32, t),
		Position = UDim2.fromScale(0.65, 0.45),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Rotation = -40,
		Color = color,
		Corner = 1,
	})
end

function builders.ChevronUp(r, color, size)
	local t = math.max(1, size * 0.09)
	frame(r, {
		Size = UDim2.fromOffset(size * 0.32, t),
		Position = UDim2.fromScale(0.35, 0.55),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Rotation = -40,
		Color = color,
		Corner = 1,
	})
	frame(r, {
		Size = UDim2.fromOffset(size * 0.32, t),
		Position = UDim2.fromScale(0.65, 0.55),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Rotation = 40,
		Color = color,
		Corner = 1,
	})
end

function builders.Info(r, color, size)
	frame(r, {
		Size = UDim2.fromOffset(size * 0.55, size * 0.55),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Color = color,
		Transparency = 1,
		Stroke = color,
		StrokeThickness = math.max(1, size * 0.1),
		Corner = true,
	})
	frame(r, {
		Size = UDim2.fromOffset(size * 0.1, size * 0.1),
		Position = UDim2.fromScale(0.5, 0.32),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Color = color,
		Corner = true,
	})
	frame(r, {
		Size = UDim2.fromOffset(size * 0.1, size * 0.22),
		Position = UDim2.fromScale(0.5, 0.58),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Color = color,
		Corner = 1,
	})
end

function builders.Moss(r, color, size)
	frame(r, {
		Size = UDim2.fromOffset(size * 0.45, size * 0.45),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Color = color,
		Corner = true,
	})
end

function builders.Sakura(r, color, size)
	builders.Moss(r, color, size)
end

function builders.Palette(r, color, size)
	frame(r, {
		Size = UDim2.fromOffset(size * 0.6, size * 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Color = color,
		Transparency = 1,
		Stroke = color,
		StrokeThickness = math.max(1, size * 0.09),
		Corner = true,
	})
	for i = 0, 2 do
		frame(r, {
			Size = UDim2.fromOffset(size * 0.12, size * 0.12),
			Position = UDim2.fromScale(0.35 + i * 0.15, 0.45),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Color = color,
			Corner = true,
		})
	end
end

function builders.Reset(r, color, size)
	frame(r, {
		Size = UDim2.fromOffset(size * 0.5, size * 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Color = color,
		Transparency = 1,
		Stroke = color,
		StrokeThickness = math.max(1, size * 0.1),
		Corner = true,
	})
	frame(r, {
		Size = UDim2.fromOffset(size * 0.18, math.max(1, size * 0.1)),
		Position = UDim2.fromScale(0.72, 0.28),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Color = color,
		Corner = 1,
	})
end

-- Aliases
builders.ChevronLeft = builders.Back
builders.ChevronRight = builders.Play
builders.Maximize = builders.Cube
builders.Fullscreen = builders.Cube
builders.Plus = builders.Check
builders.Minus = builders.Minimize
builders.Scale = builders.Layers
builders.Glass = builders.Cube
builders.Center = builders.Target
builders.Lock = builders.Cube

--- Create an icon inside parent. Returns root Frame and SetColor(color) helper.
function Renderer.Create(parent, name, options)
	options = options or {}
	local size = options.Size or DEFAULT_SIZE
	local theme = options.Theme
	local color = options.Color or themeColor(theme, "TextSecondary")
	local z = options.ZIndex or 5

	local holder = Instance.new("Frame")
	holder.Name = "Icon_" .. tostring(name)
	holder.BackgroundTransparency = 1
	holder.Size = options.FullSize or UDim2.fromScale(1, 1)
	holder.ZIndex = z
	holder.Parent = parent

	local r = root(holder, size, z + 1)
	local builder = builders[name] or builders.Moss
	builder(r, color, size)

	local api = {}
	function api:SetColor(c)
		for _, d in ipairs(r:GetDescendants()) do
			if d:IsA("Frame") then
				if d.BackgroundTransparency < 1 then
					d.BackgroundColor3 = c
				end
				local stroke = d:FindFirstChildOfClass("UIStroke")
				if stroke then
					stroke.Color = c
				end
			end
		end
	end
	function api:GetRoot()
		return holder
	end
	holder:SetAttribute("IconName", name)
	return holder, api
end

Renderer.Builders = builders
Renderer.DefaultSize = DEFAULT_SIZE

return Renderer
