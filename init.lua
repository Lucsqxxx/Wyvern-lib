--[[
	Wyvern UI Lib by Lucsqx
	A production-quality, reusable Roblox Luau UI framework.

	Version: 1.0.0

	Usage:
		local Wyvern = require(path.To.Wyvern)
		local Window = Wyvern:CreateWindow({
			Name = "My UI",
			Version = "1.0.0",
		})
]]

local Theme = require(script.Core.Theme)
local Window = require(script.Core.Window)
local Constants = require(script.Core.Constants)
local Icons = require(script.Icons.Registry)
local SakuraTheme = require(script.Themes.Sakura)
local Flags = require(script.Core.Flags)
local Notification = require(script.Core.Notification)

local Wyvern = {
	_version = "1.0.0",
	_theme = nil,
	_scale = 1,
	Icons = Icons,
	Constants = Constants,
	Version = "1.0.0",
	Flags = Flags,
}

function Wyvern:CreateWindow(config)
	config = config or {}
	if type(config) ~= "table" then
		error("[Wyvern] CreateWindow expects a table config", 2)
	end
	if not self._theme then
		self._theme = Theme.new(SakuraTheme)
	end
	return Window.new(config, self._theme, self._scale)
end

function Wyvern:SetTheme(themeTable)
	if type(themeTable) ~= "table" then
		warn("[Wyvern] SetTheme expects a table of Color3 values")
		return
	end
	if not self._theme then
		self._theme = Theme.new(themeTable)
	else
		self._theme:Apply(themeTable)
	end
end

function Wyvern:GetTheme()
	return self._theme
end

function Wyvern:SetScale(scale)
	self._scale = math.clamp(tonumber(scale) or 1, 0.5, 2)
end

function Wyvern:GetScale()
	return self._scale
end

-- Convenience export
Wyvern.Theme = Theme

-- Convenience: notify through the most recently created window if available
local _lastWindow = nil
local _origCreate = Wyvern.CreateWindow
function Wyvern:CreateWindow(config)
	local win = _origCreate(self, config)
	_lastWindow = win
	return win
end

function Wyvern:Notify(config)
	if _lastWindow and not _lastWindow._destroyed then
		return _lastWindow:Notify(config)
	end
	warn("[Wyvern] Notify: no active window")
end

return Wyvern


function Wyvern:GetFlag(name)
	return Flags.Get(name)
end

function Wyvern:SetFlag(name, value)
	Flags.Set(name, value)
end

function Wyvern:ResetFlags()
	Flags.Reset()
end

function Wyvern:GetFlags()
	return Flags.GetAll()
end

function Wyvern:Notify(config)
	config = config or {}
	return Notification.Show(config, self._theme)
end

function Wyvern.SendNotification(config)
	return Wyvern:Notify(config)
end
