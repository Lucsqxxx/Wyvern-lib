-- Divider.lua

local Component = require(script.Parent.Parent.Core.Component)

local Divider = setmetatable({}, { __index = Component })
Divider.__index = Divider

function Divider.new(config, parent, theme)
	local self = setmetatable(Component.new(config or {}), Divider)

	local frame = Instance.new("Frame")
	frame.Name = "Divider"
	frame.BackgroundColor3 = theme:Get("Border")
	frame.BackgroundTransparency = 0.4
	frame.BorderSizePixel = 0
	frame.Size = UDim2.new(1, 0, 0, 1)
	frame.Parent = parent
	self._instance = frame
	self._maid:Give(frame)
	return self
end

return Divider
