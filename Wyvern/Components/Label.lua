-- Label.lua
-- Simple text label / description component.

local Component = require(script.Parent.Parent.Core.Component)
local Constants = require(script.Parent.Parent.Core.Constants)

local Label = setmetatable({}, { __index = Component })
Label.__index = Label

function Label.new(config, parent, theme)
	local self = setmetatable(Component.new(config), Label)
	self._theme = theme

	local frame = Instance.new("Frame")
	frame.Name = "Label_" .. (config.Name or "Label")
	frame.BackgroundTransparency = 1
	frame.Size = UDim2.new(1, 0, 0, 18)
	frame.Parent = parent
	self._instance = frame

	local text = Instance.new("TextLabel")
	text.Name = "Text"
	text.BackgroundTransparency = 1
	text.Size = UDim2.new(1, 0, 1, 0)
	text.Font = Enum.Font.Gotham
	text.TextSize = Constants.DescriptionSize
	text.TextColor3 = theme:Get("TextSecondary")
	text.TextXAlignment = Enum.TextXAlignment.Left
	text.TextYAlignment = Enum.TextYAlignment.Center
	text.Text = config.Name or config.Text or ""
	text.TextWrapped = true
	text.Parent = frame
	self._text = text

	self._maid:Give(frame)
	return self
end

function Label:SetText(text)
	self._text.Text = text or ""
end

return Label
