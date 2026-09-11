--[[
	Wyvern UI Lib by Lucsqx — Demo Loader
	Safe client-side bootstrapper for the Sakura demo.

	Compatible with standard Roblox LocalScripts and common
	client-side Luau environments. Does not require executor-specific APIs.

	Behavior on re-run:
	  - Detects existing Wyvern ScreenGui(s)
	  - Destroys them cleanly
	  - Initializes a fresh demo instance
]]

local Players = game:GetService("Players")

local function safePrint(...)
	print("[Wyvern]", ...)
end

local function safeWarn(...)
	warn("[Wyvern]", ...)
end

-- Resolve LocalPlayer safely
local function getLocalPlayer()
	local player = Players.LocalPlayer
	if player then
		return player
	end
	-- Rare race on very early injection
	local ok, result = pcall(function()
		return Players.PlayerAdded:Wait()
	end)
	if ok then
		return result
	end
	return nil
end

local function destroyExistingWyvernGuis()
	local function clean(container)
		if not container then return end
		for _, child in ipairs(container:GetChildren()) do
			if child:IsA("ScreenGui") and string.sub(child.Name, 1, 7) == "Wyvern_" then
				pcall(function()
					child:Destroy()
				end)
			end
		end
	end

	-- PlayerGui
	local player = getLocalPlayer()
	if player then
		local pg = player:FindFirstChild("PlayerGui")
		if pg then
			clean(pg)
		end
	end

	-- CoreGui (if accessible)
	local ok, coreGui = pcall(function()
		return game:GetService("CoreGui")
	end)
	if ok and coreGui then
		clean(coreGui)
	end
end

-- Main load sequence
local function load()
	safePrint("Initializing Wyvern UI Lib by Lucsqx v1.0.0 ...")

	-- Clean previous instances
	destroyExistingWyvernGuis()

	local success, result = pcall(function()
		-- Require the demo (which requires Wyvern)
		-- script.Parent is expected to be the Demo folder
		local Main = require(script.Parent.Main)
		return Main
	end)

	if success then
		safePrint("Sakura demo loaded successfully.")
		return result
	else
		safeWarn("Failed to load demo:", tostring(result))
		return nil
	end
end

return load()
