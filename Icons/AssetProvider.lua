-- Icons/AssetProvider.lua
-- Downloads GitHub PNG artwork and resolves to a Roblox Image source when the
-- runtime supports custom/local assets (e.g. writefile + getcustomasset).
-- Does NOT invent APIs. Does NOT use Unicode. Does NOT use fake rbxassetids.

local HttpService = game:GetService("HttpService")

local REPO_RAW = "https://raw.githubusercontent.com/Lucsqxxx/Wyvern-lib/main/assets/icons"
local CACHE_VERSION = "v1"
local CACHE_ROOT = "Wyvern/icons/" .. CACHE_VERSION

local FILE_MAP = {
	Back = "back.png",
	Center = "center.png",
	Check = "check.png",
	CheckboxChecked = "checkbox_checked.png",
	CheckboxEmpty = "checkbox_empty.png",
	Checklist = "checklist.png",
	ChevronDown = "chevron_down.png",
	ChevronLeft = "chevron_left.png",
	ChevronRight = "chevron_right.png",
	ChevronUp = "chevron_up.png",
	Close = "close.png",
	Delete = "delete.png",
	DockAbout = "dock_about.png",
	DockHome = "dock_home.png",
	DockSettings = "dock_settings.png",
	DockTab1 = "dock_tab1.png",
	DockTab2 = "dock_tab2.png",
	DropdownDown = "dropdown_down.png",
	DropdownUp = "dropdown_up.png",
	Eye = "eye.png",
	Favorite = "favorite.png",
	Forward = "forward.png",
	Fullscreen = "fullscreen.png",
	Glass = "glass.png",
	Home = "home.png",
	Info = "info.png",
	Input = "input.png",
	Keybind = "keybind.png",
	Link = "link.png",
	Lock = "lock.png",
	Maximize = "maximize.png",
	Minimize = "minimize.png",
	Minimized = "minimized.png",
	Minus = "minus.png",
	Notification = "notification.png",
	Palette = "palette.png",
	Plus = "plus.png",
	Reset = "reset.png",
	Restored = "restored.png",
	Scale = "scale.png",
	Search = "search.png",
	Settings = "settings.png",
	Textbox = "textbox.png",
	User = "user.png",
}

local AssetProvider = {
	_cache = {}, -- name -> image source string
	_failed = {},
	_capability = nil, -- "customasset" | "none"
	_warned = false,
}

local function envHas(name)
	local ok, fn = pcall(function()
		return rawget(getfenv and getfenv(0) or _G, name) or rawget(_G, name)
	end)
	return ok and type(fn) == "function"
end

local function detectCapability()
	if AssetProvider._capability then
		return AssetProvider._capability
	end
	-- Prefer getcustomasset / getsynasset + writefile (common executor pattern)
	local writefile = envHas("writefile") and (writefile or _G.writefile)
	local isfolder = envHas("isfolder") and (isfolder or _G.isfolder)
	local makefolder = envHas("makefolder") and (makefolder or _G.makefolder)
	local getcustom = (envHas("getcustomasset") and (getcustomasset or _G.getcustomasset))
		or (envHas("getsynasset") and (getsynasset or _G.getsynasset))
	if type(writefile) == "function" and type(getcustom) == "function" then
		AssetProvider._capability = "customasset"
		AssetProvider._writefile = writefile
		AssetProvider._getcustom = getcustom
		AssetProvider._isfolder = type(isfolder) == "function" and isfolder or nil
		AssetProvider._makefolder = type(makefolder) == "function" and makefolder or nil
		AssetProvider._isfile = envHas("isfile") and (isfile or _G.isfile) or nil
		return "customasset"
	end
	AssetProvider._capability = "none"
	return "none"
end

local function ensureFolders()
	local make = AssetProvider._makefolder
	local isf = AssetProvider._isfolder
	if not make then
		return
	end
	local parts = { "Wyvern", "Wyvern/icons", CACHE_ROOT }
	for _, path in ipairs(parts) do
		local exists = false
		if isf then
			local ok, res = pcall(isf, path)
			exists = ok and res
		end
		if not exists then
			pcall(make, path)
		end
	end
end

local function httpGetBinary(url)
	-- Prefer game:HttpGet (string) which works for binary PNG in many executors
	local ok, data = pcall(function()
		return game:HttpGet(url)
	end)
	if ok and type(data) == "string" and #data > 32 then
		return data
	end
	-- syn.request / http_request fallbacks
	local req = (envHas("syn") and syn and syn.request)
		or (envHas("http_request") and http_request)
		or (envHas("request") and request)
	if type(req) == "function" then
		local ok2, res = pcall(req, { Url = url, Method = "GET" })
		if ok2 and type(res) == "table" and type(res.Body) == "string" and #res.Body > 32 then
			return res.Body
		end
	end
	return nil
end

function AssetProvider.GetCapability()
	return detectCapability()
end

function AssetProvider.GetGitHubUrl(name)
	local file = FILE_MAP[name]
	if not file then
		return nil
	end
	return REPO_RAW .. "/" .. file
end

--- Resolve icon name to an ImageLabel.Image string, or nil if unavailable.
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
	if not FILE_MAP[name] then
		return nil
	end

	local cap = detectCapability()
	if cap ~= "customasset" then
		if not AssetProvider._warned then
			AssetProvider._warned = true
			warn("[Wyvern] Image asset provider unavailable.")
			warn("[Wyvern] GitHub PNGs exist under assets/icons/ but this runtime cannot resolve custom images (need writefile + getcustomasset/getsynasset).")
			warn("[Wyvern] Icons will not render as images in this environment.")
		end
		AssetProvider._failed[name] = true
		return nil
	end

	ensureFolders()
	local path = CACHE_ROOT .. "/" .. FILE_MAP[name]
	local writefile = AssetProvider._writefile
	local getcustom = AssetProvider._getcustom
	local isfile = AssetProvider._isfile

	local needDownload = true
	if isfile then
		local ok, exists = pcall(isfile, path)
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
		local body = httpGetBinary(url)
		if not body then
			warn("[Wyvern] Failed to download icon:", name)
			AssetProvider._failed[name] = true
			return nil
		end
		local okWrite = pcall(writefile, path, body)
		if not okWrite then
			warn("[Wyvern] Failed to cache icon:", name)
			AssetProvider._failed[name] = true
			return nil
		end
	end

	local ok, asset = pcall(getcustom, path)
	if ok and type(asset) == "string" and asset ~= "" then
		AssetProvider._cache[name] = asset
		return asset
	end

	warn("[Wyvern] getcustomasset failed for icon:", name)
	AssetProvider._failed[name] = true
	return nil
end

function AssetProvider.Preload(names)
	if type(names) ~= "table" then
		return
	end
	for _, name in ipairs(names) do
		pcall(AssetProvider.Resolve, name)
	end
end

AssetProvider.FileMap = FILE_MAP
AssetProvider.RepoRaw = REPO_RAW
AssetProvider.CacheVersion = CACHE_VERSION

return AssetProvider
