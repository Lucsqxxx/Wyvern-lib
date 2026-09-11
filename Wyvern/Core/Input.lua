-- Input.lua
-- Centralized input management for keybinds.
-- Ignores keybinds while a TextBox is focused.

local UserInputService = game:GetService("UserInputService")
local Maid = require(script.Parent.Maid)

local Input = {}
Input.__index = Input

function Input.new()
	local self = setmetatable({
		_maid = Maid.new(),
		_keybinds = {}, -- [KeyCode] = {callback, ...}
		_listeningForKeybind = nil,
		_destroyed = false,
	}, Input)

	self._maid:Give(UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if self._destroyed then return end
		if gameProcessed then return end

		-- Rebind listening takes priority
		if self._listeningForKeybind then
			if input.UserInputType == Enum.UserInputType.Keyboard then
				local comp = self._listeningForKeybind
				self._listeningForKeybind = nil
				if comp and not comp._destroyed then
					comp:Set(input.KeyCode)
				end
			end
			return
		end

		-- Do not fire keybinds while typing in a TextBox
		local focused = UserInputService:GetFocusedTextBox()
		if focused then
			return
		end

		if input.UserInputType == Enum.UserInputType.Keyboard then
			local binds = self._keybinds[input.KeyCode]
			if binds then
				for _, cb in ipairs(binds) do
					task.spawn(cb)
				end
			end
		end
	end))

	return self
end

function Input:RegisterKeybind(keyCode, callback)
	if self._destroyed or type(callback) ~= "function" then
		return function() end
	end
	if not self._keybinds[keyCode] then
		self._keybinds[keyCode] = {}
	end
	table.insert(self._keybinds[keyCode], callback)

	return function()
		local list = self._keybinds[keyCode]
		if list then
			local idx = table.find(list, callback)
			if idx then
				table.remove(list, idx)
			end
		end
	end
end

function Input:StartListening(component)
	if self._destroyed then return end
	self._listeningForKeybind = component
end

function Input:StopListening()
	self._listeningForKeybind = nil
end

function Input:Destroy()
	if self._destroyed then return end
	self._destroyed = true
	self._listeningForKeybind = nil
	table.clear(self._keybinds)
	self._maid:Destroy()
	setmetatable(self, nil)
end

return Input
