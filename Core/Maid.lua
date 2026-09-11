-- Maid.lua
-- Lightweight cleanup utility for connections, instances, and custom cleanup functions.

local Maid = {}
Maid.__index = Maid

function Maid.new()
	local self = setmetatable({
		_tasks = {},
		_id = 0,
	}, Maid)
	return self
end

function Maid:Give(task)
	if task == nil then
		return nil
	end

	self._id += 1
	local id = self._id
	self._tasks[id] = task
	return id
end

function Maid:Remove(id)
	local task = self._tasks[id]
	if not task then
		return
	end
	self._tasks[id] = nil
	self:_cleanupTask(task)
end

function Maid:_cleanupTask(task)
	local t = typeof(task)
	if t == "RBXScriptConnection" then
		task:Disconnect()
	elseif t == "Instance" then
		task:Destroy()
	elseif t == "function" then
		task()
	elseif t == "table" then
		if typeof(task.Destroy) == "function" then
			task:Destroy()
		elseif typeof(task.Disconnect) == "function" then
			task:Disconnect()
		end
	end
end

function Maid:DoCleaning()
	for id, task in pairs(self._tasks) do
		self._tasks[id] = nil
		self:_cleanupTask(task)
	end
end

function Maid:Destroy()
	self:DoCleaning()
	setmetatable(self, nil)
end

return Maid
