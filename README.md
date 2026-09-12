# Wyvern UI Lib by Lucsqx

**Version:** v1.0.0

## Quick start (loadstring)

```lua
local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Lucsqxxx/Wyvern-lib/main/dist/Wyvern.lua"))()

local Window = library:CreateWindow({
	Name = "Wyvern",
})

local Tab = Window:CreateTab({
	Name = "Main",
})

local Section = Tab:CreateSection({
	Name = "Demo",
})

Section:CreateToggle({
	Name = "Enabled",
	Default = true,
	Callback = function(value)
		print(value)
	end,
})
```

`dist/Wyvern.lua` is self-contained and returns the library table. No extra loader is required.



A production-quality, reusable Roblox Luau UI framework for polished floating interfaces.

Wyvern is a generic UI library. The included Sakura demo is an application built *on top of* the library and does not hard-code feature logic into the framework core.

## Features

- Modular architecture (Core / Components / Themes / Icons / Demo)
- Floating, draggable, minimizable windows
- Two-column tab content with scrolling
- Reusable sections (cards)
- Components: Button, Toggle, Slider, Keybind, Label, Dropdown, Textbox, ColorPicker, Divider, Indicators
- Centralized theme system with hot-swap
- Generic search (keyword registration + live filtering)
- Centralized input handling (keybinds ignore focused TextBoxes)
- Animation helpers (TweenService)
- Signal + Maid cleanup
- Global UIScale
- Safe client-side parenting (CoreGui when permitted, otherwise PlayerGui)
- Duplicate-load protection
- No executor-specific APIs required
- No remote code loading


## Loading Methods

### 1. ModuleScript (development / Studio)

```lua
local Wyvern = require(path.to.init)
```

### 2. Standalone / loadstring (client runtimes)

A single-file build is published in `dist/Wyvern.lua`.

```lua
-- When you already have the source string:
local Wyvern = loadstring(wyvernSource)()

-- Or when the runtime provides HttpGet (optional):
-- local Wyvern = loadstring(game:HttpGet("https://raw.githubusercontent.com/Lucsqxxx/Wyvern-lib/main/dist/Wyvern.lua"))()

local Window = Wyvern:CreateWindow({
	Name = "My UI",
	Version = "v1.0.0",
})
```

Rebuild the standalone file after changing source:

```bash
python3 tools/build_standalone.py
```

The core library does **not** depend on any specific executor API. HttpGet is only used by *your* loader script if you choose to fetch the file remotely.

### 3. Example demo

```lua
require(path.to.examples.Main)
-- or
require(path.to.examples.Loader)
```


## Installation

1. Place this repository (or the library root) into your place (e.g. under `ReplicatedStorage` or a client folder).
2. From a LocalScript:

```lua
local Wyvern = require(path.to.Wyvern)
```

For the included demo:

```lua
-- From a LocalScript that can see the Demo folder
require(path.to.examples.Loader)
-- or
require(path.to.examples.Main)
```

## Basic Usage

```lua
local Wyvern = require(path.to.Wyvern)

local Window = Wyvern:CreateWindow({
	Name = "Settings",
	Version = "1.0.0",
})

local Tab = Window:CreateTab({
	Name = "Graphics",
	Icon = "settings",
})

local Section = Tab:CreateSection({
	Name = "Quality",
	Column = "Left", -- optional: "Left" | "Right"
})

Section:CreateToggle({
	Name = "Shadows",
	Default = true,
	Callback = function(value)
		print("Shadows:", value)
	end,
})

Section:CreateSlider({
	Name = "Render Distance",
	Min = 1,
	Max = 10,
	Default = 5,
	Increment = 1,
	Callback = function(value)
		print(value)
	end,
})

Section:CreateButton({
	Name = "Apply",
	Callback = function()
		print("Applied")
	end,
})

Section:CreateKeybind({
	Name = "Toggle UI",
	Default = Enum.KeyCode.RightShift,
	Callback = function()
		Window:Toggle()
	end,
})
```

## Public API

### Wyvern

| Method | Description |
|--------|-------------|
| `Wyvern:CreateWindow(config)` | Creates a new window |
| `Wyvern:SetTheme(table)` | Applies theme colors (hot-swap) |
| `Wyvern:GetTheme()` | Returns current Theme object |
| `Wyvern:SetScale(number)` | Global scale (0.5–2) |
| `Wyvern:GetScale()` | Current scale |
| `Wyvern.Icons` | Icon registry |
| `Wyvern.Constants` | Design tokens |
| `Wyvern.Version` | `"1.0.0"` |

### Window

| Method | Description |
|--------|-------------|
| `:CreateTab(config)` | Creates a tab |
| `:Open()` / `:Close()` / `:Toggle()` | Visibility |
| `:Minimize()` / `:Restore()` | Collapse / expand content |
| `:SetVisible(boolean)` | Show / hide |
| `:SetScale(number)` | Per-window scale |
| `:Notify(config)` | Toast notification |
| `:SetTitle(text)` | Change window title |
| `:GetTabs()` / `:GetCurrentTab()` | Tab access |
| `:IsVisible()` / `:IsMinimized()` | State queries |
| `:Destroy()` | Full cleanup |

### Tab

| Method | Description |
|--------|-------------|
| `:CreateSection(config)` | Creates a section card |
| `:Select()` / `:Deselect()` / `:IsSelected()` | Tab state |
| `:SetVisible(boolean)` | Visibility |
| `:Destroy()` | Cleanup |

### Section

| Method | Description |
|--------|-------------|
| `:CreateButton(config)` | Text button |
| `:CreateToggle(config)` | On/off toggle |
| `:CreateSlider(config)` | Numeric slider |
| `:CreateKeybind(config)` | Rebindable key |
| `:CreateLabel(config)` | Description text |
| `:CreateDropdown(config)` | Single-select popup dropdown |
| `:CreateMultiDropdown(config)` | Multi-select dropdown |
| `:CreateInput(config)` | Alias for Textbox |
| `:CreateTextbox(config)` | Text input |
| `:CreateColorPicker(config)` | Color swatch cycle |
| `:CreateDivider()` | Horizontal line |
| `:CreateIndicators(config)` | Status color boxes |
| `:SetVisible(boolean)` | Visibility |
| `:Destroy()` | Cleanup |

### Common Component Methods

- `:Get()`
- `:Set(value)`
- `:SetVisible(boolean)`
- `:SetEnabled(boolean)`
- `:Destroy()`

Additional:
- Button: `:SetText(text)`
- Slider: `:SetRange(min, max)`
- Keybind: uses `Enum.KeyCode`

## Search

Components accept a `Keywords` table. The window search bar filters components by name + keywords (case-insensitive partial match). Search only hides/shows; it never destroys state.

## Themes

```lua
Wyvern:SetTheme({
	Accent = Color3.fromRGB(255, 110, 175),
	Background = Color3.fromRGB(18, 14, 24),
	-- see Themes/Sakura.lua for full key list
})
```

## Scaling

```lua
Wyvern:SetScale(0.9)
-- or
Window:SetScale(1.1)
```

## Cleanup

```lua
Window:Destroy()
```

Destroys all Instances, connections, signals, search registrations, and keybind listeners. Safe to call multiple times. Re-loading the loader also destroys previous `Wyvern_*` ScreenGuis.

## Project Structure

```
/
├── init.lua              # Library entry point
├── README.md
├── CHANGELOG.md
├── Core/
│   ├── Component.lua, Window.lua, Tab.lua, Section.lua
│   ├── Theme.lua, Search.lua, Input.lua, Notification.lua
│   ├── Animation.lua, Signal.lua, Maid.lua, Constants.lua
├── Components/
│   ├── Button, Toggle, Slider, Keybind, Label
│   ├── Dropdown, MultiDropdown, Textbox, ColorPicker, Divider
├── Icons/
│   └── Registry.lua
├── Themes/
│   └── Sakura.lua
└── examples/
    ├── Main.lua          # Sakura + Showcase demo
    └── Loader.lua        # Safe client bootstrap
```

## Compatibility Notes

- Uses only standard Roblox client APIs (`Players`, `TweenService`, `UserInputService`, etc.).
- No `getgenv`, `syn`, `protectgui`, `loadstring(HttpGet)`, or similar required.
- Parents to CoreGui when write access is available; otherwise PlayerGui.
- Duplicate load protection via named ScreenGui cleanup + internal registry.
- Designed for LocalScript / client-side Luau environments.

## License

Free to use and modify. Attribution to Lucsqx appreciated.


## Settings

Bottom-nav **Settings** (last icon) opens a real Settings tab:

- UI Scale
- Accent / Background / Surface colors
- Center window / Reset scale

Theme changes notify subscribed components without recreating the window.


## Icons (GitHub source of truth)

Cropped artwork lives in the repository:

```
assets/icons/*.png
```

Example raw URL:

```
https://raw.githubusercontent.com/Lucsqxxx/Wyvern-lib/main/assets/icons/settings.png
```

**Roblox note:** `ImageLabel.Image` does **not** accept arbitrary HTTPS URLs. The standalone `dist/Wyvern.lua` therefore renders icons with the built-in vector `Icons.Renderer` (matching the sheet style). To use the exact PNG pixels in-game, upload a file from `assets/icons/` to Roblox and register it:

```lua
-- only after you have a real uploaded asset:
library.Icons.SetAsset("Settings", "rbxassetid://YOUR_REAL_ID")
```

Do not invent placeholder asset IDs.


## Public API (VNext)

```lua
local library = (loadstring or load)(game:HttpGet(
  "https://raw.githubusercontent.com/Lucsqxxx/Wyvern-lib/main/dist/Wyvern.lua"
))()

local window = library:CreateWindow({ Name = "Wyvern", Version = "1.0.0" })
-- aliases: window:AddTab, tab:AddSection, section:AddToggle / AddSlider / ...

local tab = window:AddTab({ Name = "Main" })
local section = tab:AddSection({ Name = "Controls" })

section:AddToggle({ Name = "Enabled", Default = true, Callback = function(v) end })
section:AddSlider({ Name = "Opacity", Min = 0, Max = 100, Default = 80, Callback = function(v) end })
section:AddDropdown({ Name = "Mode", Options = {"A","B"}, Default = "A", Callback = function(v) end })
section:AddMultiDropdown({ Name = "Features", Options = {"X","Y"}, Callback = function(v) end })
section:AddTextbox({ Name = "Name", Placeholder = "...", Callback = function(v) end })
section:AddKeybind({ Name = "Key", Callback = function(k) end })
section:AddColorPicker({ Name = "Accent", Callback = function(c) end })
section:AddButton({ Name = "Action", Callback = function() end })
section:AddProgressBar({ Name = "Load", Default = 40 })
section:AddFeature({ Name = "Group", Description = "Nested controls" })

library:Notify({ Title = "Wyvern", Text = "Ready", Duration = 3 })
library:Confirm({ Title = "Sure?", Description = "Demo", Callback = function(ok) end })
library:GetFlag / SetFlag / ResetFlags
```

`Create*` methods remain supported. There is **no** Azure `create_module` API.

Showcase: `examples/Showcase.lua`
