--[[
	AzureCompat.lua — UI-ONLY compatibility layer
	Maps Azure-style create_module / create_* APIs onto Wyvern.
	Does NOT execute game/exploit logic. Callbacks are optional and
	should be replaced with benign handlers by the host demo.
]]

local AzureCompat = {}
AzureCompat.__index = AzureCompat

local function safeCb(label, userCb)
	return function(...)
		local args = { ... }
		print("[Wyvern Demo]", label, table.unpack(args))
		if type(userCb) == "function" then
			-- Host may pass a benign callback; never required
			pcall(userCb, table.unpack(args))
		end
	end
end

local function mapConfig(settings)
	settings = settings or {}
	return {
		Name = settings.title or settings.Name or "Control",
		Description = settings.description or settings.Description,
		Flag = settings.flag or settings.Flag,
		Default = settings.value ~= nil and settings.value or settings.Default,
		Min = settings.minimum_value or settings.Min,
		Max = settings.maximum_value or settings.Max,
		Options = settings.options or settings.Options,
		Placeholder = settings.placeholder or settings.Placeholder,
		Callback = settings.callback or settings.Callback,
		Multi = settings.multi_dropdown == true or settings.Multi == true,
		Round = settings.round_number,
	}
end

function AzureCompat.wrapFeature(feature)
	local proxy = {}

	function proxy:create_checkbox(settings)
		local c = mapConfig(settings)
		c.Callback = safeCb(c.Name, c.Callback)
		return feature:CreateCheckbox(c)
	end

	function proxy:create_slider(settings)
		local c = mapConfig(settings)
		c.Callback = safeCb(c.Name, c.Callback)
		return feature:CreateSlider(c)
	end

	function proxy:create_dropdown(settings)
		local c = mapConfig(settings)
		c.Callback = safeCb(c.Name, c.Callback)
		if c.Multi then
			return feature:CreateMultiDropdown(c)
		end
		return feature:CreateDropdown(c)
	end

	function proxy:create_textbox(settings)
		local c = mapConfig(settings)
		c.Callback = safeCb(c.Name, c.Callback)
		return feature:CreateTextbox(c)
	end

	function proxy:create_button(settings)
		local c = mapConfig(settings)
		c.Callback = safeCb(c.Name, c.Callback)
		return feature:CreateButton(c)
	end

	-- PascalCase pass-through
	proxy.CreateCheckbox = proxy.create_checkbox
	proxy.CreateSlider = proxy.create_slider
	proxy.CreateDropdown = proxy.create_dropdown
	proxy.CreateTextbox = proxy.create_textbox
	proxy.CreateButton = proxy.create_button

	return proxy
end

function AzureCompat.wrapSection(section)
	local proxy = {}
	function proxy:create_module(settings)
		settings = settings or {}
		local feature = section:CreateFeature({
			Name = settings.title or settings.Name or "Feature",
			Description = settings.description or settings.Description or "",
			Flag = settings.flag or settings.Flag,
			Callback = safeCb(settings.title or "Feature", settings.callback or settings.Callback),
		})
		return AzureCompat.wrapFeature(feature)
	end
	proxy.CreateFeature = function(_, s)
		return proxy:create_module(s)
	end
	return proxy
end

return AzureCompat
