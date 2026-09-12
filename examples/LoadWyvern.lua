-- Minimal safe loader for Wyvern UI Lib (executor-friendly)
local url = "https://raw.githubusercontent.com/Lucsqxxx/Wyvern-lib/main/dist/Wyvern.lua"

local function httpGet(u)
	local ok, body = pcall(function()
		return game:HttpGet(u)
	end)
	if ok and type(body) == "string" and #body > 100 then
		return body
	end
	local req = (syn and syn.request) or http_request or request
	if type(req) == "function" then
		local ok2, res = pcall(req, { Url = u, Method = "GET" })
		if ok2 and type(res) == "table" and type(res.Body) == "string" then
			return res.Body
		end
	end
	error("[Wyvern] HttpGet failed")
end

local src = httpGet(url)
local chunk, err = (loadstring or load)(src)
if not chunk then
	error("[Wyvern] compile error: " .. tostring(err))
end
local library = chunk()
assert(type(library) == "table" and library.CreateWindow, "bad library return")
return library
