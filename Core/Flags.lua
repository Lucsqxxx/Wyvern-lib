-- Core/Flags.lua — simple in-memory config flags for components

local Flags = {
	_store = {},
}

function Flags.Get(name)
	if type(name) ~= "string" then
		return nil
	end
	return Flags._store[name]
end

function Flags.Set(name, value)
	if type(name) ~= "string" then
		return
	end
	Flags._store[name] = value
end

function Flags.Has(name)
	return type(name) == "string" and Flags._store[name] ~= nil
end

function Flags.Reset()
	table.clear(Flags._store)
end

function Flags.GetAll()
	local copy = {}
	for k, v in pairs(Flags._store) do
		copy[k] = v
	end
	return copy
end

function Flags.Bind(name, default)
	if type(name) ~= "string" then
		return default
	end
	if Flags._store[name] == nil and default ~= nil then
		Flags._store[name] = default
	end
	return Flags._store[name]
end

return Flags
