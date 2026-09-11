-- Constants.lua
-- Centralized design tokens for consistent spacing, sizing and animation.

local Constants = {
	-- Window
	WindowWidth = 660,
	WindowHeight = 510,
	WindowCornerRadius = 12,
	HeaderHeight = 42,
	SearchHeight = 34,
	ContentPadding = 12,
	SectionSpacing = 10,
	ComponentSpacing = 8,

	-- Controls
	ControlHeight = 28,
	ButtonHeight = 28,
	ToggleSize = 22,
	SliderHeight = 6,
	SliderHandleSize = 14,
	KeybindWidth = 36,

	-- Typography
	TitleSize = 15,
	SectionTitleSize = 13,
	LabelSize = 12,
	ValueSize = 12,
	DescriptionSize = 11,
	VersionSize = 11,

	-- Borders & corners
	BorderThickness = 1,
	SmallCornerRadius = 6,
	MediumCornerRadius = 8,
	LargeCornerRadius = 12,
	PillRadius = 18,

	-- Animation
	HoverDuration = 0.12,
	PressDuration = 0.08,
	ToggleDuration = 0.15,
	PanelDuration = 0.2,

	-- ZIndex layers
	ZIndex = {
		Background = 1,
		Window = 10,
		Content = 20,
		Controls = 30,
		Navigation = 40,
		Tooltip = 100,
		Notification = 200,
	},
}

return Constants
