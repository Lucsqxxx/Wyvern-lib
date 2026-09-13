-- Core/Responsive.lua — viewport breakpoints, safe area, touch targets, popup fit

local GuiService = game:GetService("GuiService")

local Responsive = {}

Responsive.Breakpoints = {
	Mobile = 520,
	Tablet = 900,
}

Responsive.Margins = {
	Mobile = Vector2.new(10, 12),
	Tablet = Vector2.new(24, 28),
	Desktop = Vector2.new(40, 40),
}

Responsive.Preferred = {
	Desktop = Vector2.new(660, 510),
	Tablet = Vector2.new(560, 480),
	Mobile = Vector2.new(400, 640),
}

Responsive.DefaultScale = {
	Desktop = 1,
	Tablet = 0.95,
	Mobile = 0.9,
}

-- Visual control height vs minimum touch target (interaction)
Responsive.ControlHeight = {
	Desktop = 28,
	Tablet = 30,
	Mobile = 34,
}

Responsive.TouchTarget = {
	Desktop = 28,
	Tablet = 36,
	Mobile = 44,
}

Responsive.NavIconSize = {
	Desktop = 32,
	Tablet = 36,
	Mobile = 40,
}

function Responsive.GetViewportSize()
	local cam = workspace.CurrentCamera
	if cam then
		return cam.ViewportSize
	end
	return Vector2.new(1920, 1080)
end

function Responsive.GetSafeInsets()
	-- GuiService insets: top/bottom may include notch / home indicator
	local ok, inset = pcall(function()
		return GuiService:GetGuiInset()
	end)
	if ok and typeof(inset) == "Vector2" then
		return inset -- typically top-left inset magnitude as Vector2
	end
	return Vector2.new(0, 0)
end

function Responsive.GetSafeArea()
	local vp = Responsive.GetViewportSize()
	local inset = Responsive.GetSafeInsets()
	-- Usable rectangle in screen space (IgnoreGuiInset true: still keep soft margins)
	local mode = Responsive.GetMode(vp)
	local margin = Responsive.Margins[mode] or Responsive.Margins.Desktop
	local top = math.max(margin.Y, inset.Y > 0 and (inset.Y * 0.25) or 0)
	local bottom = margin.Y
	local left = margin.X
	local right = margin.X
	return {
		X = left,
		Y = top,
		Width = math.max(1, vp.X - left - right),
		Height = math.max(1, vp.Y - top - bottom),
		Viewport = vp,
		Mode = mode,
	}
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
	local safe = Responsive.GetSafeArea()
	local maxW = math.max(280, safe.Width)
	local maxH = math.max(320, safe.Height)
	local w = math.min(pref.X, maxW)
	local h = math.min(pref.Y, maxH)
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

function Responsive.GetControlHeight(mode)
	mode = mode or Responsive.GetMode()
	return Responsive.ControlHeight[mode] or 28
end

function Responsive.GetTouchTarget(mode)
	mode = mode or Responsive.GetMode()
	return Responsive.TouchTarget[mode] or 28
end

function Responsive.GetNavIconSize(mode)
	mode = mode or Responsive.GetMode()
	return Responsive.NavIconSize[mode] or 32
end

function Responsive.ClampPosition(x, y, width, height, scale)
	scale = scale or 1
	local safe = Responsive.GetSafeArea()
	local w = width * scale
	local h = height * scale
	local minX = safe.X
	local minY = safe.Y
	local maxX = math.max(minX, safe.X + safe.Width - w)
	local maxY = math.max(minY, safe.Y + safe.Height - h)
	x = math.clamp(x, minX, maxX)
	y = math.clamp(y, minY, maxY)
	return x, y
end

function Responsive.CenterPosition(width, height, scale)
	scale = scale or 1
	local safe = Responsive.GetSafeArea()
	local w = width * scale
	local h = height * scale
	local x = safe.X + math.max(0, (safe.Width - w) / 2)
	local y = safe.Y + math.max(0, (safe.Height - h) / 2)
	return UDim2.fromOffset(math.floor(x), math.floor(y))
end

-- Fit a popup under/above a trigger in overlay space.
-- Returns x, y, width, height (all offset, relative to overlay AbsolutePosition origin).
function Responsive.FitPopup(triggerAbsPos, triggerAbsSize, desiredW, desiredH, overlayAbsPos)
	overlayAbsPos = overlayAbsPos or Vector2.zero
	local safe = Responsive.GetSafeArea()
	local margin = 8
	local maxW = math.max(120, safe.Width - margin * 2)
	local w = math.clamp(math.floor(desiredW or 160), 96, maxW)

	local spaceBelow = (safe.Y + safe.Height) - (triggerAbsPos.Y + triggerAbsSize.Y) - margin
	local spaceAbove = triggerAbsPos.Y - safe.Y - margin
	local maxH = math.max(80, math.max(spaceBelow, spaceAbove))
	local h = math.clamp(math.floor(desiredH or 160), 40, maxH)

	local openDown = spaceBelow >= spaceAbove or spaceBelow >= h
	if spaceBelow < h and spaceAbove >= h then
		openDown = false
	elseif spaceAbove < h and spaceBelow >= h then
		openDown = true
	end

	local x = triggerAbsPos.X - overlayAbsPos.X
	local y
	if openDown then
		y = triggerAbsPos.Y - overlayAbsPos.Y + triggerAbsSize.Y + 4
	else
		y = triggerAbsPos.Y - overlayAbsPos.Y - h - 4
	end

	-- Horizontal clamp in screen space then convert to overlay-local
	local screenX = overlayAbsPos.X + x
	screenX = math.clamp(screenX, safe.X + margin, math.max(safe.X + margin, safe.X + safe.Width - w - margin))
	x = screenX - overlayAbsPos.X

	local screenY = overlayAbsPos.Y + y
	screenY = math.clamp(screenY, safe.Y + margin, math.max(safe.Y + margin, safe.Y + safe.Height - h - margin))
	y = screenY - overlayAbsPos.Y

	return math.floor(x), math.floor(y), w, math.floor(h), openDown
end

function Responsive.MaxPopupWidth()
	local safe = Responsive.GetSafeArea()
	return math.max(120, safe.Width - 16)
end

function Responsive.MaxPopupHeight(triggerAbsPos, triggerAbsSize)
	local safe = Responsive.GetSafeArea()
	local margin = 8
	local below = (safe.Y + safe.Height) - (triggerAbsPos.Y + triggerAbsSize.Y) - margin
	local above = triggerAbsPos.Y - safe.Y - margin
	return math.max(80, math.max(below, above))
end

return Responsive
