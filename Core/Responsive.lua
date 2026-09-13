-- Core/Responsive.lua — viewport breakpoints and sizing helpers
-- Desktop / Tablet / Mobile modes from CurrentCamera.ViewportSize

local Responsive = {}

Responsive.Breakpoints = {
	Mobile = 520, -- width < Mobile -> Mobile
	Tablet = 900, -- width < Tablet -> Tablet, else Desktop
}

Responsive.Margins = {
	Mobile = Vector2.new(10, 12),
	Tablet = Vector2.new(24, 28),
	Desktop = Vector2.new(40, 40),
}

Responsive.Preferred = {
	Desktop = Vector2.new(660, 510),
	Tablet = Vector2.new(560, 480),
	Mobile = Vector2.new(400, 640), -- capped by viewport - margins
}

Responsive.DefaultScale = {
	Desktop = 1,
	Tablet = 0.95,
	Mobile = 0.9,
}

function Responsive.GetViewportSize()
	local cam = workspace.CurrentCamera
	if cam then
		return cam.ViewportSize
	end
	return Vector2.new(1920, 1080)
end

function Responsive.GetMode(vp)
	vp = vp or Responsive.GetViewportSize()
	local w = vp.X
	if w < Responsive.Breakpoints.Mobile then
		return "Mobile"
	elseif w < Responsive.Breakpoints.Tablet then
		return "Tablet"
	end
	return "Desktop"
end

function Responsive.IsNarrow(vp)
	return Responsive.GetMode(vp) == "Mobile"
end

function Responsive.GetPreferredSize(mode, vp)
	mode = mode or Responsive.GetMode(vp)
	vp = vp or Responsive.GetViewportSize()
	local pref = Responsive.Preferred[mode] or Responsive.Preferred.Desktop
	local margin = Responsive.Margins[mode] or Responsive.Margins.Desktop
	local maxW = math.max(280, vp.X - margin.X * 2)
	local maxH = math.max(320, vp.Y - margin.Y * 2)
	local w = math.min(pref.X, maxW)
	local h = math.min(pref.Y, maxH)
	-- On mobile portrait, prefer near-full height
	if mode == "Mobile" then
		w = maxW
		h = maxH
	end
	return math.floor(w), math.floor(h)
end

function Responsive.GetDefaultScale(mode)
	mode = mode or Responsive.GetMode()
	return Responsive.DefaultScale[mode] or 1
end

function Responsive.ClampPosition(x, y, width, height, scale)
	scale = scale or 1
	local vp = Responsive.GetViewportSize()
	local w = width * scale
	local h = height * scale
	x = math.clamp(x, 0, math.max(0, vp.X - w))
	y = math.clamp(y, 0, math.max(0, vp.Y - h))
	return x, y
end

function Responsive.CenterPosition(width, height, scale)
	scale = scale or 1
	local vp = Responsive.GetViewportSize()
	local w = width * scale
	local h = height * scale
	local x = math.max(0, (vp.X - w) / 2)
	local y = math.max(0, (vp.Y - h) / 2)
	return UDim2.fromOffset(math.floor(x), math.floor(y))
end

return Responsive
