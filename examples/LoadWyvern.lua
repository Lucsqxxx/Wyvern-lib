--[[
	Wyvern UI Lib — executor-safe loader
	Usage:
	  loadstring(game:HttpGet(".../examples/LoadWyvern.lua"))()
	  -- or if loadstring is nil:
	  load(game:HttpGet(".../examples/LoadWyvern.lua"))()
]]

local DIST_URL = "https://raw.githubusercontent.com/Lucsqxxx/Wyvern-lib/main/dist/Wyvern.lua"

local function httpGet(url)
	-- game:HttpGet
	local ok, body = pcall(function()
		return game:HttpGet(url)
	end)
	if ok and type(body) == "string" and #body > 200 then
		return body
	end
	-- game.HttpGet(game, url) style
	ok, body = pcall(function()
		return game.HttpGet(game, url)
	end)
	if ok and type(body) == "string" and #body > 200 then
		return body
	end
	-- request APIs
	local req = rawget(getfenv and getfenv() or _G, "request")
		or rawget(_G, "http_request")
		or (syn and syn.request)
		or (http and http.request)
	if type(req) == "function" then
		local ok2, res = pcall(req, { Url = url, Method = "GET" })
		if ok2 and type(res) == "table" then
			local b = res.Body or res.body
			if type(b) == "string" and #b > 200 then
				return b
			end
		end
	end
	error("[Wyvern] failed to download: " .. tostring(url) .. " (HttpGet/request unavailable or empty)")
end

local function compile(src)
	local fn, err
	-- Prefer loadstring when present; many executors alias it to load
	local ls = rawget(_G, "loadstring") or loadstring
	local ld = rawget(_G, "load") or load
	if type(ls) == "function" then
		fn, err = ls(src)
	elseif type(ld) == "function" then
		fn, err = ld(src, "Wyvern")
	else
		error("[Wyvern] neither loadstring nor load exists in this environment")
	end
	if type(fn) ~= "function" then
		error("[Wyvern] compile error: " .. tostring(err))
	end
	return fn
end

local src = httpGet(DIST_URL)
local chunk = compile(src)
local ok, library = pcall(chunk)
if not ok then
	error("[Wyvern] init error: " .. tostring(library))
end
if type(library) ~= "table" or type(library.CreateWindow) ~= "function" then
	error("[Wyvern] library did not return CreateWindow API (got " .. type(library) .. ")")
end

return library
