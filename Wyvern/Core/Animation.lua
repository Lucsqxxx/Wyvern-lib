-- Animation.lua
-- Centralized TweenService wrappers with sensible defaults.

local TweenService = game:GetService("TweenService")

local Animation = {}

local DEFAULT_INFO = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

function Animation.Tween(instance, properties, duration, easingStyle, easingDirection)
	if not instance or not properties then
		return nil
	end

	local info = TweenInfo.new(
		duration or 0.15,
		easingStyle or Enum.EasingStyle.Quad,
		easingDirection or Enum.EasingDirection.Out
	)

	local tween = TweenService:Create(instance, info, properties)
	tween:Play()
	return tween
end

function Animation.Hover(instance, properties)
	return Animation.Tween(instance, properties, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
end

function Animation.Press(instance, properties)
	return Animation.Tween(instance, properties, 0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
end

function Animation.Toggle(instance, properties)
	return Animation.Tween(instance, properties, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
end

function Animation.Panel(instance, properties)
	return Animation.Tween(instance, properties, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
end

return Animation
