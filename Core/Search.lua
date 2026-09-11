-- Search.lua
-- Generic search registration and filtering.

local Signal = require(script.Parent.Signal)

local Search = {}
Search.__index = Search

function Search.new()
	local self = setmetatable({
		_entries = {}, -- {component, section, keywords}
		_query = "",
		QueryChanged = Signal.new(),
	}, Search)
	return self
end

function Search:Register(component, section)
	table.insert(self._entries, {
		Component = component,
		Section = section,
		Keywords = component:GetSearchKeywords(),
	})
end

function Search:Unregister(component)
	for i = #self._entries, 1, -1 do
		if self._entries[i].Component == component then
			table.remove(self._entries, i)
		end
	end
end

function Search:SetQuery(query)
	self._query = string.lower(query or "")
	self.QueryChanged:Fire(self._query)

	-- Apply visibility
	for _, entry in ipairs(self._entries) do
		local matches = entry.Component:MatchesSearch(self._query)
		entry.Component:SetVisible(matches)
		-- Optionally hide empty sections – handled by section itself if needed
	end
end

function Search:GetQuery()
	return self._query
end

function Search:Clear()
	self:SetQuery("")
end

function Search:Destroy()
	self.QueryChanged:Destroy()
	table.clear(self._entries)
	setmetatable(self, nil)
end

return Search
