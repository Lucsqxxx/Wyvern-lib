-- Glyphs.lua
-- Self-contained text glyphs for icons (no external asset dependency).
-- Used when Image assets are unavailable or as primary style for consistency.

local Glyphs = {
	Back = "‹",
	Search = "⌕",
	Minimize = "–",
	Close = "×",
	Eye = "◉",
	Checklist = "☰",
	Settings = "⚙",
	User = "☺",
	ChevronDown = "▼",
	ChevronUp = "▲",
	Palette = "◉",
	Scale = "↔",
	Glass = "◇",
	Reset = "↺",
	Center = "＋",
	Info = "i",
	Check = "✓",
	Plus = "+",
	Minus = "−",
	Home = "⌂",
	Play = "▶",
	Layers = "▤",
	Target = "◎",
	Moss = "●",
	Cube = "■",
	Users = "☺",
	Sakura = "❀",
}

function Glyphs.Get(name)
	if type(name) ~= "string" then
		return "•"
	end
	return Glyphs[name] or "•"
end

--- Create a consistent icon TextLabel for use inside buttons.
function Glyphs.CreateLabel(name, theme, size)
	size = size or 14
	local label = Instance.new("TextLabel")
	label.Name = "Glyph_" .. tostring(name)
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBold
	label.TextSize = size
	label.Text = Glyphs.Get(name)
	label.TextColor3 = theme and theme:Get("TextSecondary") or Color3.fromRGB(170, 160, 185)
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.TextYAlignment = Enum.TextYAlignment.Center
	return label
end

return Glyphs
