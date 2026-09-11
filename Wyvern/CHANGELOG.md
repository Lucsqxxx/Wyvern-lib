# Changelog

## v1.0.0 — 2026-09-11

### Added
- Proper single-select Dropdown with Open/Close/Add/Remove/Refresh
- MultiDropdown with multi-select, Select/Deselect
- Notification / toast system (`Window:Notify` / `Wyvern:Notify`)
- Window:SetTitle, SetVersion, GetTabs, GetCurrentTab, IsVisible, IsMinimized
- Toggle:Toggle / Reset; Slider:SetMin / SetMax / SetIncrement / Reset
- Section:CreateInput alias, CreateMultiDropdown
- Expanded Showcase demo tab
- Modular Wyvern UI Lib architecture (Core, Components, Themes, Icons, Demo)
- Window with drag, minimize/restore, close, search bar, bottom + secondary navigation
- Tab system with two-column layout and scrolling
- Section cards with automatic sizing
- Components: Button, Toggle, Slider, Keybind, Label, Dropdown, Textbox, ColorPicker, Divider, Indicators
- Theme manager with hot-swap support
- Generic search registration and live filtering
- Centralized Input manager (keybinds skip focused TextBoxes)
- Animation helpers, Signal, Maid cleanup
- Design tokens (Constants)
- Icon registry with safe fallbacks
- Sakura theme tuned to reference screenshot
- Sakura demo built exclusively on public API
- Safe client-side GUI parenting (CoreGui → PlayerGui fallback)
- Duplicate-load protection
- Global and per-window UIScale

### Compatibility
- No executor-specific APIs required
- No remote source loading
- Safe re-initialization

### Notes
- Placeholder icon asset IDs should be replaced for production
- Visual language follows the provided Sakura reference
