--[[
	Sakura Demo
	Recreates the reference screenshot using the public Wyvern UI Lib API.
	This file contains ONLY application-specific configuration.
	No framework internals are modified here.
]]

local Wyvern = require(script.Parent.Parent)

-- Apply Sakura theme (already default, but explicit)
local SakuraTheme = require(script.Parent.Parent.Themes.Sakura)
Wyvern:SetTheme(SakuraTheme)
Wyvern:SetScale(1)

local Window = Wyvern:CreateWindow({
	Name = "Sakura",
	Version = "v1.0.0",
})

-- Main Play tab (matches the reference layout)
local Play = Window:CreateTab({
	Name = "Play",
	Icon = "play",
})

------------------------------------------------------------
-- LEFT COLUMN
------------------------------------------------------------

-- Header Hitbox section
local HeaderHitbox = Play:CreateSection({
	Name = "Header Hitbox",
	Column = "Left",
})

HeaderHitbox:CreateSlider({
	Name = "Header Size",
	Min = 1,
	Max = 10,
	Default = 3,
	Increment = 1,
	Keywords = { "header", "size", "hitbox" },
	Callback = function(value)
		print("[Sakura] Header Size:", value)
	end,
})

HeaderHitbox:CreateButton({
	Name = "Customization",
	Callback = function()
		print("[Sakura] Header Customization clicked")
	end,
})

HeaderHitbox:CreateIndicators({
	Name = "Header Preview",
	Colors = {
		Color3.fromRGB(70, 220, 120), -- active green
		Color3.fromRGB(55, 45, 70),   -- inactive
	},
})

-- Better React section
local BetterReact = Play:CreateSection({
	Name = "Better React",
	Column = "Left",
})

BetterReact:CreateToggle({
	Name = "Better React",
	Default = false,
	Keywords = { "react", "better" },
	Callback = function(value)
		print("[Sakura] Better React:", value)
	end,
})

BetterReact:CreateSlider({
	Name = "React Power",
	Min = 1,
	Max = 10,
	Default = 2,
	Increment = 1,
	Keywords = { "react", "power" },
	Callback = function(value)
		print("[Sakura] React Power:", value)
	end,
})

BetterReact:CreateLabel({
	Name = "Dont be too rage use at mid.",
})

------------------------------------------------------------
-- RIGHT COLUMN
------------------------------------------------------------

local ManualHeader = Play:CreateSection({
	Name = "Manual Header",
	Column = "Right",
})

ManualHeader:CreateToggle({
	Name = "Manual Header Feature",
	Default = false,
	Keywords = { "manual", "header", "feature" },
	Callback = function(value)
		print("[Sakura] Manual Header Feature:", value)
	end,
})

ManualHeader:CreateKeybind({
	Name = "Header Key",
	Default = Enum.KeyCode.H,
	Keywords = { "header", "key" },
	Callback = function()
		print("[Sakura] Header Key pressed")
	end,
})

ManualHeader:CreateButton({
	Name = "Customization",
	Callback = function()
		print("[Sakura] Manual Header Customization")
	end,
})

ManualHeader:CreateToggle({
	Name = "Manual Head Shot",
	Default = false,
	Keywords = { "manual", "head", "shot" },
	Callback = function(value)
		print("[Sakura] Manual Head Shot:", value)
	end,
})

ManualHeader:CreateToggle({
	Name = "Play Head Animation",
	Default = true,
	Keywords = { "play", "head", "animation" },
	Callback = function(value)
		print("[Sakura] Play Head Animation:", value)
	end,
})

ManualHeader:CreateKeybind({
	Name = "Head Shot Key",
	Default = Enum.KeyCode.T,
	Keywords = { "head", "shot", "key" },
	Callback = function()
		print("[Sakura] Head Shot Key pressed")
	end,
})

ManualHeader:CreateButton({
	Name = "Customization",
	Callback = function()
		print("[Sakura] Head Shot Customization")
	end,
})

-- Head Carry section
local HeadCarry = Play:CreateSection({
	Name = "Head Carry",
	Column = "Right",
})

HeadCarry:CreateToggle({
	Name = "Head Carry",
	Default = false,
	Keywords = { "head", "carry" },
	Callback = function(value)
		print("[Sakura] Head Carry:", value)
	end,
})

HeadCarry:CreateSlider({
	Name = "Carry Padding",
	Min = 0,
	Max = 5,
	Default = 1.5,
	Increment = 0.1,
	Keywords = { "carry", "padding" },
	Callback = function(value)
		print("[Sakura] Carry Padding:", value)
	end,
})

print("[Wyvern] Sakura demo loaded successfully.")
print("Search for 'header' or 'react' to test the search system.")

return Window
