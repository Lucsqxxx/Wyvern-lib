-- Icons/Registry.lua
-- Centralized icon asset registry.
-- Placeholder IDs are used; replace with your own assets for production.
-- Invalid or missing icons fall back gracefully.

local FALLBACK = "rbxassetid://0"

local Icons = {
	Search = "rbxassetid://6031154871",
	Close = "rbxassetid://6031094670",
	Minimize = "rbxassetid://6031094678",
	Settings = "rbxassetid://6031280882",
	Eye = "rbxassetid://6031075931",
	Layers = "rbxassetid://6031075938",
	Target = "rbxassetid://6031094681",
	Play = "rbxassetid://6031229358",
	Cube = "rbxassetid://6031094667",
	Users = "rbxassetid://6034287594",
	Moss = "rbxassetid://6031094670",
	Sakura = "rbxassetid://6031094670",
	Check = "rbxassetid://6031094667",
	Lock = "rbxassetid://6031094678",
	Home = "rbxassetid://6031094670",
	Chevron = "rbxassetid://6031094678",
	Palette = "rbxassetid://6031280882",
	Reset = "rbxassetid://6031094678",
	Center = "rbxassetid://6031094667",
	Glass = "rbxassetid://6031075931",
	Back = "rbxassetid://6031094670",
}

function Icons.Get(name)
	if type(name) ~= "string" then
		return FALLBACK
	end
	local id = Icons[name]
	if type(id) == "string" and id ~= "" then
		return id
	end
	return FALLBACK
end

function Icons.Set(name, assetId)
	if type(name) == "string" and type(assetId) == "string" then
		Icons[name] = assetId
	end
end

return Icons
