-- Core/SearchIndex.lua — framework-wide search index (Search V2)
local SearchIndex = {}
SearchIndex.__index = SearchIndex

function SearchIndex.new()
	return setmetatable({ _items = {}, _byId = {} }, SearchIndex)
end

function SearchIndex:Register(entry)
	if type(entry) ~= "table" or type(entry.Id) ~= "string" then
		return false
	end
	if self._byId[entry.Id] then
		self._byId[entry.Id] = entry
		return true
	end
	table.insert(self._items, entry)
	self._byId[entry.Id] = entry
	return true
end

function SearchIndex:Unregister(id)
	if not id then
		return
	end
	self._byId[id] = nil
	for i = #self._items, 1, -1 do
		if self._items[i].Id == id then
			table.remove(self._items, i)
		end
	end
end

function SearchIndex:Search(query)
	query = string.lower(tostring(query or ""))
	if query == "" then
		return {}
	end
	local out = {}
	for _, e in ipairs(self._items) do
		local hay = string.lower(table.concat({
			tostring(e.Title or ""),
			tostring(e.Description or ""),
			tostring(e.Category or ""),
			table.concat(e.Keywords or {}, " "),
		}, " "))
		if string.find(hay, query, 1, true) then
			table.insert(out, e)
		end
	end
	return out
end

function SearchIndex:Count()
	return #self._items
end

function SearchIndex:Clear()
	table.clear(self._items)
	table.clear(self._byId)
end

function SearchIndex:Destroy()
	self:Clear()
end

return SearchIndex
