--[[
	Wyvern UI Lib by Lucsqx
	A production-quality, reusable Roblox Luau UI framework.
	Version: 1.1.0
]]

local Theme = require(script.Core.Theme)
local Window = require(script.Core.Window)
local Constants = require(script.Core.Constants)
local Icons = require(script.Icons.Registry)
local SakuraTheme = require(script.Themes.Sakura)
local Flags = require(script.Core.Flags)
local Notification = require(script.Core.Notification)
local Modal = require(script.Core.Modal)
local ThemeRegistry = require(script.Core.ThemeRegistry)
local SearchIndex = require(script.Core.SearchIndex)

local Wyvern = {
	_version = "1.1.0",
	_theme = nil,
	_scale = 1,
	_scaleLocked = false,
	_debug = false,
	Icons = Icons,
	Constants = Constants,
	Version = "1.1.0",
	Flags = Flags,
	Theme = Theme,
}

-- Register default theme
pcall(function()
	ThemeRegistry.Register("Sakura", SakuraTheme)
	ThemeRegistry.Register("Default", SakuraTheme)
end)

function Wyvern:CreateWindow(config)
	config = config or {}
	if type(config) ~= "table" then
		error("[Wyvern] CreateWindow expects a table config", 2)
	end
	if not self._theme then
		self._theme = Theme.new(SakuraTheme)
		ThemeRegistry.BindActive(self._theme)
	end
	-- Only lock scale when user explicitly set library scale or config.Scale
	if self._scaleLocked and config.Scale == nil then
		config.Scale = self._scale
	end
	return Window.new(config, self._theme)
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
	ThemeRegistry.BindActive(self._theme)
end

function Wyvern:GetTheme()
	return self._theme
end

function Wyvern:SetScale(scale)
	self._scale = tonumber(scale) or 1
	self._scaleLocked = true
end

function Wyvern:GetScale()
	return self._scale or 1
end

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

function Wyvern:Confirm(config)
	config = config or {}
	return Modal.Confirm(config, self._theme, nil)
end

function Wyvern:RegisterTheme(name, themeTable)
	return ThemeRegistry.Register(name, themeTable)
end

function Wyvern:SetThemeByName(name)
	local ok = ThemeRegistry.Set(name)
	if ok and ThemeRegistry.GetActive() then
		self._theme = ThemeRegistry.GetActive()
	end
	return ok
end

function Wyvern:GetThemeNames()
	return ThemeRegistry.GetNames()
end

function Wyvern:SetDebug(enabled)
	self._debug = enabled and true or false
end

function Wyvern:IsDebug()
	return self._debug == true
end

function Wyvern:DebugDump()
	local lines = {
		"Wyvern Debug",
		"Version: " .. tostring(self.Version),
		"Debug: " .. tostring(self._debug),
		"Themes: " .. table.concat(ThemeRegistry.GetNames(), ", "),
	}
	print(table.concat(lines, "\n"))
	return lines
end

function Wyvern:RegisterSearchItem(entry)
	self._globalSearch = self._globalSearch or SearchIndex.new()
	return self._globalSearch:Register(entry)
end

function Wyvern:Search(query)
	if self._globalSearch then
		return self._globalSearch:Search(query)
	end
	return {}
end

return Wyvern
