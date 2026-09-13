--[[ Wyvern UI Lib — Phase 2 Showcase (UI only, no game logic) ]]
local loadfn = loadstring or load
assert(type(loadfn) == "function", "loadstring/load required")
local library = loadfn(game:HttpGet(
	"https://raw.githubusercontent.com/Lucsqxxx/Wyvern-lib/main/dist/Wyvern.lua"
))()

library:SetDebug(true)
library:DebugDump()

local window = library:CreateWindow({ Name = "Wyvern Showcase", Version = "1.1.0" })
local main = window:AddTab({ Name = "Main" })
local layout = window:AddTab({ Name = "Layout" })
local data = window:AddTab({ Name = "Data" })

local section = main:AddSection({ Name = "Controls" })
section:AddToggle({
	ID = "main.enabled",
	Name = "Enabled",
	Default = true,
	Tooltip = "Master enable switch",
	Keywords = { "toggle", "power" },
	Callback = function(v) print("[Showcase] Enabled", v) end,
})
section:AddSwitch({
	ID = "main.switch",
	Name = "Switch",
	Default = false,
	Callback = function(v) print("[Showcase] Switch", v) end,
})
section:AddSlider({
	ID = "main.opacity",
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
section:AddRadioGroup({
	Name = "Profile",
	Options = { "Casual", "Normal", "Expert" },
	Default = "Normal",
	Callback = function(v) print("[Showcase] Radio", v) end,
})
section:AddTextbox({
	Name = "Profile Name",
	Placeholder = "Enter name...",
	Callback = function(v) print("[Showcase] Text", v) end,
})
section:AddKeybind({
	Name = "Hotkey",
	Callback = function(k) print("[Showcase] Key", k) end,
})
section:AddColorPicker({
	Name = "Accent",
	Callback = function(c) print("[Showcase] Color", c) end,
})
section:AddProgressBar({ Name = "Load", Default = 55 })
section:AddButton({
	Name = "Notify",
	Tooltip = "Show a notification",
	Callback = function()
		library:Notify({ Title = "Wyvern", Text = "Hello", Duration = 2 })
	end,
})
section:AddButton({
	Name = "Confirm",
	Callback = function()
		library:Confirm({
			Title = "Reset?",
			Description = "Demo confirmation dialog.",
			Callback = function(ok) print("[Showcase] Confirm", ok) end,
		})
	end,
})

local lay = layout:AddSection({ Name = "Primitives" })
local row = lay:AddRow({ Gap = 8 })
row:AddButton({ Name = "One", Callback = function() print("One") end })
row:AddButton({ Name = "Two", Callback = function() print("Two") end })
local card = lay:AddCard({ Padding = 10 })
card:AddLabel({ Name = "Card", Text = "Nested card content" })
card:AddSlider({ Name = "Inner", Min = 0, Max = 10, Default = 3 })

local dataSec = data:AddSection({ Name = "Table" })
local tbl = dataSec:AddTable({
	Name = "Players",
	Columns = { "Name", "Status", "Score" },
	Rows = {
		{ "Alpha", "Ready", "100" },
		{ "Beta", "Waiting", "50" },
		{ "Gamma", "Offline", "0" },
	},
})

print("[Showcase] component", window:GetComponent("main.enabled"))
print("[Showcase] search", window:Search("opacity"))

library:Notify({ Title = "Wyvern", Text = "Phase 2 Showcase loaded", Duration = 3 })
return library
