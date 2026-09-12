--[[
	Paste this entire script if your executor has no loadstring.
	It only uses `load` + HttpGet/request.
]]
local url = "https://raw.githubusercontent.com/Lucsqxxx/Wyvern-lib/main/dist/Wyvern.lua"
local function get(u)
	local ok, b = pcall(function() return game:HttpGet(u) end)
	if ok and type(b) == "string" and #b > 200 then return b end
	local r = (syn and syn.request) or http_request or request
	if r then
		local ok2, res = pcall(r, {Url=u, Method="GET"})
		if ok2 and res and type(res.Body)=="string" then return res.Body end
	end
	error("HttpGet failed")
end
local src = get(url)
local chunk, err = (loadstring or load)(src)
if not chunk then error("compile: "..tostring(err)) end
local library = chunk()
assert(library and library.CreateWindow, "bad library")
local Window = library:CreateWindow({ Name = "Wyvern", Version = "1.0.0" })
local Tab = Window:CreateTab({ Name = "Main" })
local Sec = Tab:CreateSection({ Name = "Demo" })
Sec:CreateToggle({ Name = "Enabled", Default = true, Callback = function(v) print("Enabled", v) end })
print("[Wyvern] OK", library.Version)
return library
