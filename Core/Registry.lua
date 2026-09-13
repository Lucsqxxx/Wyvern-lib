-- Core/Registry.lua — component ID registry per Window
local Registry = {}
Registry.__index = Registry

function Registry.new()
	return setmetatable({ _map = {}, _count = 0 }, Registry)
end

function Registry:Register(id, component)
	if type(id) ~= "string" or id == "" then
		return false
	end
	if self._map[id] and self._map[id] ~= component then
		warn("[Wyvern] duplicate component ID:", id)
		return false
	end
	if not self._map[id] then
		self._count = self._count + 1
	end
	self._map[id] = component
	return true
end

function Registry:Unregister(id)
	if self._map[id] then
		self._map[id] = nil
		self._count = math.max(0, self._count - 1)
	end
end

function Registry:Get(id)
	return self._map[id]
end

function Registry:Count()
	return self._count
end

function Registry:Clear()
	table.clear(self._map)
	self._count = 0
end

function Registry:Destroy()
	self:Clear()
end

return Registry
