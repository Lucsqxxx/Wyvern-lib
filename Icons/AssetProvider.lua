-- Icons/AssetProvider.lua
-- Pipeline: GitHub PNG → HttpGet → writefile → getcustomasset → ContentId
-- Matches executor custom-asset loading (Wyvern Spy style).

local REPO_RAW = "https://raw.githubusercontent.com/Lucsqxxx/Wyvern-lib/main/assets/icons"
local CACHE_DIR = "Wyvern UI Lib/assets/icons"

local FILE_MAP = {
	Back = "back.png",
	Forward = "forward.png",
	ChevronLeft = "chevron_left.png",
	ChevronRight = "chevron_right.png",
	ChevronDown = "chevron_down.png",
	ChevronUp = "chevron_up.png",
	Minimize = "minimize.png",
	Maximize = "maximize.png",
	Fullscreen = "fullscreen.png",
	Close = "close.png",
	Search = "search.png",
	Eye = "eye.png",
	Check = "check.png",
	CheckboxEmpty = "checkbox_empty.png",
	CheckboxChecked = "checkbox_checked.png",
	Reset = "reset.png",
	Center = "center.png",
	Info = "info.png",
	User = "user.png",
	Settings = "settings.png",
	Home = "home.png",
	Palette = "palette.png",
	Scale = "scale.png",
	Glass = "glass.png",
	Checklist = "checklist.png",
	Plus = "plus.png",
	Minus = "minus.png",
	Input = "input.png",
	Textbox = "textbox.png",
	Keybind = "keybind.png",
	DropdownDown = "dropdown_down.png",
	DropdownUp = "dropdown_up.png",
	Minimized = "minimized.png",
	Restored = "restored.png",
	DockHome = "dock_home.png",
	DockTab1 = "dock_tab1.png",
	DockTab2 = "dock_tab2.png",
	DockAbout = "dock_about.png",
	DockSettings = "dock_settings.png",
	Lock = "lock.png",
	Notification = "notification.png",
	Favorite = "favorite.png",
	Link = "link.png",
	Delete = "delete.png",
}

local AssetProvider = {
	_cache = {},
	_failed = {},
	_caps = nil,
	_warned = false,
}

local function pickFn(...)
	for i = 1, select("#", ...) do
		local name = select(i, ...)
		local fn = rawget(_G, name)
		if type(fn) == "function" then
			return fn
		end
		-- some executors put APIs in getgenv()
		local ok, genv = pcall(function()
			return getgenv and getgenv()
		end)
		if ok and type(genv) == "table" and type(genv[name]) == "function" then
			return genv[name]
		end
	end
	return nil
end

local function detect()
	if AssetProvider._caps then
		return AssetProvider._caps
	end
	local caps = {
		httpGet = nil,
		writefile = pickFn("writefile"),
		isfile = pickFn("isfile"),
		isfolder = pickFn("isfolder"),
		makefolder = pickFn("makefolder"),
		getcustomasset = pickFn("getcustomasset", "getsynasset"),
	}
	-- HttpGet: game:HttpGet or request-style
	caps.httpGet = function(url)
		local ok, body = pcall(function()
			return game:HttpGet(url)
		end)
		if ok and type(body) == "string" and #body > 64 then
			return body
		end
		local req = pickFn("http_request", "request")
		if not req then
			local okS, syn = pcall(function()
				return syn
			end)
			if okS and type(syn) == "table" and type(syn.request) == "function" then
				req = syn.request
			end
		end
		if type(req) == "function" then
			local ok2, res = pcall(req, { Url = url, Method = "GET" })
			if ok2 and type(res) == "table" and type(res.Body) == "string" and #res.Body > 64 then
				return res.Body
			end
		end
		return nil
	end
	caps.supported = (type(caps.writefile) == "function") and (type(caps.getcustomasset) == "function")
	AssetProvider._caps = caps
	return caps
end

local function ensureDir()
	local caps = detect()
	if not caps.makefolder then
		return
	end
	local parts = { "Wyvern UI Lib", "Wyvern UI Lib/assets", CACHE_DIR }
	for _, path in ipairs(parts) do
		local exists = false
		if caps.isfolder then
			local ok, res = pcall(caps.isfolder, path)
			exists = ok and res
		end
		if not exists then
			pcall(caps.makefolder, path)
		end
	end
end

function AssetProvider.GetCapability()
	local c = detect()
	return c.supported and "customasset" or "none"
end

function AssetProvider.GetGitHubUrl(name)
	local file = FILE_MAP[name]
	if not file then
		return nil
	end
	return REPO_RAW .. "/" .. file
end

function AssetProvider.Resolve(name)
	if type(name) ~= "string" then
		return nil
	end
	if AssetProvider._cache[name] then
		return AssetProvider._cache[name]
	end
	if AssetProvider._failed[name] then
		return nil
	end
	local file = FILE_MAP[name]
	if not file then
		return nil
	end

	local caps = detect()
	if not caps.supported then
		if not AssetProvider._warned then
			AssetProvider._warned = true
			warn("[Wyvern] PNG icon pipeline requires writefile + getcustomasset/getsynasset.")
			warn("[Wyvern] GitHub icons: " .. REPO_RAW)
		end
		AssetProvider._failed[name] = true
		return nil
	end

	ensureDir()
	local path = CACHE_DIR .. "/" .. file
	local needDownload = true
	if caps.isfile then
		local ok, exists = pcall(caps.isfile, path)
		if ok and exists then
			needDownload = false
		end
	end

	if needDownload then
		local url = AssetProvider.GetGitHubUrl(name)
		if not url or not string.find(url, "raw.githubusercontent.com/Lucsqxxx/Wyvern-lib/", 1, true) then
			AssetProvider._failed[name] = true
			return nil
		end
		local body = caps.httpGet(url)
		if type(body) ~= "string" or #body < 64 then
			warn("[Wyvern] icon download failed:", name)
			AssetProvider._failed[name] = true
			return nil
		end
		-- PNG magic check
		if string.sub(body, 1, 8) ~= "\137PNG\r\n\26\n" then
			warn("[Wyvern] icon download not PNG:", name)
			AssetProvider._failed[name] = true
			return nil
		end
		local okW = pcall(caps.writefile, path, body)
		if not okW then
			warn("[Wyvern] writefile failed:", name)
			AssetProvider._failed[name] = true
			return nil
		end
	end

	local okA, asset = pcall(caps.getcustomasset, path)
	if okA and type(asset) == "string" and asset ~= "" and asset ~= "nil" then
		AssetProvider._cache[name] = asset
		return asset
	end
	-- corrupt cache? delete and retry once
	if not needDownload then
		pcall(function()
			local delfile = pickFn("delfile")
			if delfile then
				delfile(path)
			end
		end)
		AssetProvider._failed[name] = nil
		-- force redownload next call only once
		local body = caps.httpGet(AssetProvider.GetGitHubUrl(name))
		if type(body) == "string" and #body > 64 then
			pcall(caps.writefile, path, body)
			local ok2, asset2 = pcall(caps.getcustomasset, path)
			if ok2 and type(asset2) == "string" and asset2 ~= "" then
				AssetProvider._cache[name] = asset2
				return asset2
			end
		end
	end
	warn("[Wyvern] getcustomasset failed:", name)
	AssetProvider._failed[name] = true
	return nil
end

function AssetProvider.Preload(names)
	if type(names) ~= "table" then
		return
	end
	for _, n in ipairs(names) do
		pcall(AssetProvider.Resolve, n)
	end
end

AssetProvider.FileMap = FILE_MAP
AssetProvider.RepoRaw = REPO_RAW
AssetProvider.CacheDir = CACHE_DIR

return AssetProvider
