--[[
	Wyvern UI Lib — public API showcase (no game logic)
]]
local loadfn = loadstring or load
assert(type(loadfn) == "function", "loadstring/load required")

local src = game:HttpGet("https://raw.githubusercontent.com/Lucsqxxx/Wyvern-lib/main/dist/Wyvern.lua")
local library = loadfn(src)()

local window = library:CreateWindow({ Name = "Wyvern Showcase", Version = "1.0.0" })
local main = window:AddTab({ Name = "Main" })
local more = window:AddTab({ Name = "More" })

local section = main:AddSection({ Name = "Controls" })
section:AddToggle({
	Name = "Enabled",
	Default = true,
	Callback = function(v) print("[Showcase] Enabled", v) end,
})
section:AddSlider({
	Name = "Opacity",
	Min = 0, Max = 100, Default = 80,
	Callback = function(v) print("[Showcase] Opacity", v) end,
})
section:AddDropdown({
	Name = "Mode",
	Options = { "Default", "Fast", "Advanced" },
	Default = "Default",
	Callback = function(v) print("[Showcase] Mode", v) end,
})
section:AddMultiDropdown({
	Name = "Features",
	Options = { "A", "B", "C", "VeryLongOptionNameThatShouldTruncate" },
	Callback = function(v) print("[Showcase] Features", v) end,
})
section:AddTextbox({
	Name = "Profile",
	Placeholder = "Enter name...",
	Callback = function(v) print("[Showcase] Profile", v) end,
})
section:AddKeybind({
	Name = "Toggle Key",
	Callback = function(k) print("[Showcase] Key", k) end,
})
section:AddColorPicker({
	Name = "Accent",
	Callback = function(c) print("[Showcase] Color", c) end,
})
section:AddButton({
	Name = "Notify",
	Callback = function()
		library:Notify({ Title = "Wyvern", Text = "Hello from Showcase", Duration = 2 })
	end,
})
section:AddButton({
	Name = "Confirm",
	Callback = function()
		library:Confirm({
			Title = "Reset?",
			Description = "This is a demo confirmation.",
			Callback = function(ok) print("[Showcase] Confirm", ok) end,
		})
	end,
})
section:AddProgressBar({ Name = "Load", Default = 42 })

local visual = more:AddSection({ Name = "Display" })
visual:AddLabel({ Name = "Status", Text = "All systems nominal" })
visual:AddParagraph({ Name = "About", Text = "Wyvern UI Lib showcase — public API only." })
visual:AddDivider({})

library:Notify({ Title = "Wyvern", Text = "Showcase loaded", Duration = 3 })
return library
