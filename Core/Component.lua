-- Component.lua
-- Base abstraction for all UI components.

local Maid = require(script.Parent.Maid)
local Signal = require(script.Parent.Signal)

local Component = {}
Component.__index = Component

function Component.new(config)
	config = config or {}
	local self = setmetatable({
		_maid = Maid.new(),
		_visible = true,
		_enabled = true,
		_destroyed = false,
		_name = config.Name or "Component",
		_value = config.Default,
		_callbacks = {},
		_searchKeywords = config.Keywords or {},
		ValueChanged = Signal.new(),
		Activated = Signal.new(),
	}, Component)

	if type(config.Callback) == "function" then
		self:OnChanged(config.Callback)
	end

	return self
end

function Component:Get()
	return self._value
end

function Component:Set(value)
	if self._destroyed then return end
	if self._value == value then
		return
	end
	self._value = value
	self.ValueChanged:Fire(value)
	for _, cb in ipairs(self._callbacks) do
		task.spawn(cb, value)
	end
end

function Component:OnChanged(callback)
	if type(callback) ~= "function" then
		return function() end
	end
	table.insert(self._callbacks, callback)
	return function()
		local idx = table.find(self._callbacks, callback)
		if idx then
			table.remove(self._callbacks, idx)
		end
	end
end

-- Subscribe to Theme:OnChanged. Component should implement :ApplyTheme(theme).
function Component:BindTheme(theme)
	if not theme or type(theme.OnChanged) ~= "function" then
		return
	end
	self._theme = theme
	local unsub = theme:OnChanged(function()
		if self._destroyed then
			return
		end
		if type(self.ApplyTheme) == "function" then
			self:ApplyTheme(theme)
		end
	end)
	self._maid:Give(function()
		if type(unsub) == "function" then
			unsub()
		end
	end)
end

function Component:SetVisible(visible)
	if self._destroyed then return end
	self._visible = visible and true or false
	if self._instance and self._instance.Parent then
		self._instance.Visible = self._visible
	end
end

function Component:IsVisible()
	return self._visible
end

function Component:SetEnabled(enabled)
	if self._destroyed then return end
	self._enabled = enabled and true or false
end

function Component:IsEnabled()
	return self._enabled
end

function Component:GetName()
	return self._name
end

function Component:GetSearchKeywords()
	local keywords = { string.lower(tostring(self._name)) }
	for _, k in ipairs(self._searchKeywords) do
		table.insert(keywords, string.lower(tostring(k)))
	end
	return keywords
end

function Component:MatchesSearch(query)
	if not query or query == "" then
		return true
	end
	query = string.lower(tostring(query))
	for _, keyword in ipairs(self:GetSearchKeywords()) do
		if string.find(keyword, query, 1, true) then
			return true
		end
	end
	return false
end

function Component:Destroy()
	if self._destroyed then return end
	self._destroyed = true
	if self.ValueChanged then
		self.ValueChanged:Destroy()
	end
	if self.Activated then
		self.Activated:Destroy()
	end
	self._maid:Destroy()
	if self._instance then
		pcall(function()
			self._instance:Destroy()
		end)
		self._instance = nil
	end
	table.clear(self._callbacks)
	setmetatable(self, nil)
end

function Component:GetValue(...)
	if self.Get then return self:Get(...) end
	return self._value
end

function Component:SetValue(...)
	if self.Set then return self:Set(...) end
end

function Component:GetState(...)
	return self:GetValue(...)
end

function Component:SetState(...)
	return self:SetValue(...)
end

return Component
