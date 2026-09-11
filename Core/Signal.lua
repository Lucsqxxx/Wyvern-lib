-- Signal.lua
-- Lightweight signal implementation for event-driven communication.

local Signal = {}
Signal.__index = Signal

function Signal.new()
	local self = setmetatable({
		_connections = {},
		_id = 0,
	}, Signal)
	return self
end

function Signal:Connect(callback)
	assert(typeof(callback) == "function", "Signal:Connect expects a function")
	self._id += 1
	local id = self._id
	self._connections[id] = callback

	local connection = {
		Disconnect = function()
			self._connections[id] = nil
		end,
	}
	return connection
end

function Signal:Fire(...)
	for _, callback in pairs(self._connections) do
		task.spawn(callback, ...)
	end
end

function Signal:Wait()
	local thread = coroutine.running()
	local connection
	connection = self:Connect(function(...)
		connection:Disconnect()
		task.spawn(thread, ...)
	end)
	return coroutine.yield()
end

function Signal:Destroy()
	table.clear(self._connections)
	setmetatable(self, nil)
end

return Signal
