-- Core/ThemeRegistry.lua
local Theme = require(script.Parent.Theme)

local REQUIRED = {
	"Background", "Surface", "Border", "Accent", "Text",
}

local ThemeRegistry = {
	_themes = {},
	_currentName = "Default",
	_active = nil,
}

local function validate(themeTable)
	if type(themeTable) ~= "table" then
		return false, "theme must be a table"
	end
	for _, k in ipairs(REQUIRED) do
		local v = themeTable[k]
		if typeof(v) ~= "Color3" then
			return false, "missing/invalid Color3 token: " .. k
		end
	end
	return true
end

function ThemeRegistry.Register(name, themeTable)
	if type(name) ~= "string" or name == "" then
		warn("[Wyvern] RegisterTheme: invalid name")
		return false
	end
	local ok, err = validate(themeTable)
	if not ok then
		warn("[Wyvern] RegisterTheme:", err)
		return false
	end
	ThemeRegistry._themes[name] = themeTable
	return true
end

function ThemeRegistry.Set(name)
	local data = ThemeRegistry._themes[name]
	if not data then
		warn("[Wyvern] unknown theme:", name)
		return false
	end
	ThemeRegistry._currentName = name
	if ThemeRegistry._active then
		ThemeRegistry._active:Apply(data)
	else
		ThemeRegistry._active = Theme.new(data)
	end
	return true
end

function ThemeRegistry.GetActive()
	return ThemeRegistry._active
end

function ThemeRegistry.GetName()
	return ThemeRegistry._currentName
end

function ThemeRegistry.GetNames()
	local names = {}
	for k in pairs(ThemeRegistry._themes) do
		table.insert(names, k)
	end
	table.sort(names)
	return names
end

function ThemeRegistry.BindActive(themeObj)
	ThemeRegistry._active = themeObj
end

return ThemeRegistry
