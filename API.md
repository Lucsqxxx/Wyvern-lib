# Wyvern UI Lib — Public API Reference

**Version:** v1.0.0

## Entry

```lua
local Wyvern = require(path.to.init) -- or the ModuleScript at repository root
```

## Wyvern

| Method | Description |
|--------|-------------|
| `CreateWindow(config)` | Create a floating window |
| `SetTheme(table)` | Apply theme colors |
| `GetTheme()` | Current theme object |
| `SetScale(number)` | Global UI scale (0.5–2) |
| `GetScale()` | Current scale |
| `Notify(config)` | Toast via last window |
| `Icons` | Icon registry |
| `Constants` | Design tokens |
| `Version` | `"1.0.0"` |

## Window

`CreateTab` · `Open` · `Close` · `Toggle` · `Minimize` · `Restore` · `SetVisible` · `SetScale` · `SetTitle` · `SetVersion` · `Notify` · `GetTabs` · `GetCurrentTab` · `IsVisible` · `IsMinimized` · `Destroy`

## Tab

`CreateSection` · `Select` · `Deselect` · `IsSelected` · `SetVisible` · `Destroy`

## Section

`CreateButton` · `CreateToggle` · `CreateSlider` · `CreateDropdown` · `CreateMultiDropdown` · `CreateKeybind` · `CreateTextbox` / `CreateInput` · `CreateColorPicker` · `CreateLabel` · `CreateDivider` · `CreateIndicators` · `SetVisible` · `Destroy`

## Common Component Methods

`Get` · `Set` · `SetVisible` · `SetEnabled` · `Destroy`

### Dropdown / MultiDropdown extras
`Open` · `Close` · `Add` · `Remove` · `Clear` · `Refresh` · (`Select` / `Deselect` for multi)

### Toggle extras
`Toggle` · `Reset`

### Slider extras
`SetRange` · `SetMin` · `SetMax` · `SetIncrement` · `Reset`

See README.md for usage examples.
