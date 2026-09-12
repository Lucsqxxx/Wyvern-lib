#!/usr/bin/env python3
"""
Build a standalone, loadstring-compatible Wyvern UI Lib.
Produces: dist/Wyvern.lua
"""
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parent.parent
DIST = ROOT / "dist"
DIST.mkdir(exist_ok=True)

# Dependency order (leaves first)
ORDER = [
    ("Core/Maid.lua", "Core.Maid"),
    ("Core/Signal.lua", "Core.Signal"),
    ("Core/Constants.lua", "Core.Constants"),
    ("Core/Animation.lua", "Core.Animation"),
    ("Core/Theme.lua", "Core.Theme"),
    ("Icons/AssetIds.lua", "Icons.AssetIds"),
    ("Icons/AssetProvider.lua", "Icons.AssetProvider"),
    ("Icons/Renderer.lua", "Icons.Renderer"),
    ("Icons/Glyphs.lua", "Icons.Glyphs"),
    ("Icons/Registry.lua", "Icons.Registry"),
    ("Themes/Sakura.lua", "Themes.Sakura"),
    ("Core/Component.lua", "Core.Component"),
    ("Core/Input.lua", "Core.Input"),
    ("Core/Search.lua", "Core.Search"),
    ("Core/Notification.lua", "Core.Notification"),
    ("Core/PopupManager.lua", "Core.PopupManager"),
    ("Components/Button.lua", "Components.Button"),
    ("Components/Toggle.lua", "Components.Toggle"),
    ("Components/Slider.lua", "Components.Slider"),
    ("Components/Keybind.lua", "Components.Keybind"),
    ("Components/Label.lua", "Components.Label"),
    ("Components/Dropdown.lua", "Components.Dropdown"),
    ("Components/MultiDropdown.lua", "Components.MultiDropdown"),
    ("Components/Textbox.lua", "Components.Textbox"),
    ("Components/ColorPicker.lua", "Components.ColorPicker"),
    ("Components/Divider.lua", "Components.Divider"),
    ("Core/Section.lua", "Core.Section"),
    ("Core/Tab.lua", "Core.Tab"),
    ("Core/Window.lua", "Core.Window"),
    ("init.lua", "init"),
]

REQUIRE_RE = re.compile(
    r"""require\(\s*script(?:\.Parent)*\.([A-Za-z0-9_.]+)(?:\.([A-Za-z0-9_]+))?\s*\)"""
)

def map_require(match, current_key):
    """Map relative script requires to module registry keys."""
    # This is approximate; we rewrite known patterns below more carefully
    return match.group(0)

def rewrite_requires(src: str, module_key: str) -> str:
    """
    Replace Roblox ModuleScript requires with __wyvern_require("Module.Key").
    """
    # Patterns used in the codebase:
    # require(script.Parent.Maid)                    -> Core.Maid (when in Core)
    # require(script.Parent.Parent.Core.Component)   -> Core.Component
    # require(script.Parent.Parent.Components.Button)-> Components.Button
    # require(script.Core.Theme)                     -> Core.Theme (from init)
    # require(script.Icons.Registry)
    # require(script.Themes.Sakura)

    lines = []
    for line in src.splitlines():
        original = line
        # init.lua style
        line = re.sub(
            r'require\(script\.Core\.(\w+)\)',
            r'__wyvern_require("Core.\1")',
            line,
        )
        line = re.sub(
            r'require\(script\.Icons\.(\w+)\)',
            r'__wyvern_require("Icons.\1")',
            line,
        )
        line = re.sub(
            r'require\(script\.Themes\.(\w+)\)',
            r'__wyvern_require("Themes.\1")',
            line,
        )
        # Core sibling: script.Parent.X
        line = re.sub(
            r'require\(script\.Parent\.AssetIds\)',
            r'__wyvern_require("Icons.AssetIds")',
            line,
        )
        line = re.sub(
            r'require\(script\.Parent\.AssetProvider\)',
            r'__wyvern_require("Icons.AssetProvider")',
            line,
        )
        line = re.sub(
            r'require\(script\.Parent\.AssetIds\)',
            r'__wyvern_require("Icons.AssetIds")',
            line,
        )
        line = re.sub(
            r'require\(script\.Parent\.AssetProvider\)',
            r'__wyvern_require("Icons.AssetProvider")',
            line,
        )
        line = re.sub(
            r'require\(script\.Parent\.Renderer\)',
            r'__wyvern_require("Icons.Renderer")',
            line,
        )
        line = re.sub(
            r'require\(script\.Parent\.Glyphs\)',
            r'__wyvern_require("Icons.Glyphs")',
            line,
        )
        line = re.sub(
            r'require\(script\.Parent\.(\w+)\)',
            r'__wyvern_require("Core.\1")',
            line,
        )
        # Components / Core from Components: script.Parent.Parent.Core.X
        line = re.sub(
            r'require\(script\.Parent\.Parent\.Core\.(\w+)\)',
            r'__wyvern_require("Core.\1")',
            line,
        )
        line = re.sub(
            r'require\(script\.Parent\.Parent\.Components\.(\w+)\)',
            r'__wyvern_require("Components.\1")',
            line,
        )
        line = re.sub(
            r'require\(script\.Parent\.Parent\.Icons\.(\w+)\)',
            r'__wyvern_require("Icons.\1")',
            line,
        )
        # Window Icons path: script.Parent.Parent.Icons.Registry
        line = re.sub(
            r'require\(script\.Parent\.Parent\.Icons\.Registry\)',
            r'__wyvern_require("Icons.Registry")',
            line,
        )
        lines.append(line)
    return "\n".join(lines)

def strip_return_module(src: str) -> str:
    """Keep the module body; we'll capture return value via wrapper."""
    return src

HEADER = r'''--[[
	Wyvern UI Lib by Lucsqx
	Standalone distribution for loadstring / client environments.
	Version: 1.0.0

	Usage:
		local Wyvern = loadstring(source)()
		local Window = Wyvern:CreateWindow({ Name = "UI", Version = "v1.0.0" })

	Or from HttpGet (when available in the runtime):
		local Wyvern = loadstring(game:HttpGet("RAW_URL_TO_dist/Wyvern.lua"))()
]]

local __wyvern_modules = {}
local __wyvern_cache = {}
local __wyvern_loading = {}

local function __wyvern_define(name, factory)
	__wyvern_modules[name] = factory
end

local function __wyvern_require(name)
	if __wyvern_cache[name] ~= nil then
		return __wyvern_cache[name]
	end
	if __wyvern_loading[name] then
		error("[Wyvern] Circular require: " .. tostring(name), 2)
	end
	local factory = __wyvern_modules[name]
	if not factory then
		error("[Wyvern] Module not found: " .. tostring(name), 2)
	end
	__wyvern_loading[name] = true
	local result = factory()
	__wyvern_loading[name] = nil
	__wyvern_cache[name] = result
	return result
end

'''

FOOTER = r'''
-- Bootstrap public API
local Wyvern = __wyvern_require("init")

-- Repeated-execution guard (optional shared marker)
local ok, ss = pcall(function()
	return game:GetService("Players")
end)
if ok then
	-- soft marker only; Window still has ActiveWindows registry
	if type(getfenv) == "function" then
		local env = getfenv(0)
		if type(env) == "table" then
			env.__WYVERN_LOADED = true
			env.__WYVERN_VERSION = Wyvern.Version or "1.0.0"
		end
	end
end

return Wyvern
'''

def wrap_module(key: str, body: str) -> str:
    # Themes/Sakura returns a table literal directly
    # Most modules end with `return X`
    return f'''
__wyvern_define("{key}", function()
{body}
end)
'''

def main():
    parts = [HEADER]
    missing = []
    for rel, key in ORDER:
        path = ROOT / rel
        if not path.exists():
            missing.append(rel)
            continue
        src = path.read_text(encoding="utf-8")
        # Remove leading shebang-style comments only if needed; keep file header comments
        src = rewrite_requires(src, key)
        parts.append(f"-- ===== BEGIN {key} ({rel}) =====")
        parts.append(wrap_module(key, src))
        parts.append(f"-- ===== END {key} =====\n")

    if missing:
        print("MISSING:", missing, file=sys.stderr)
        sys.exit(1)

    parts.append(FOOTER)
    out = DIST / "Wyvern.lua"
    out.write_text("\n".join(parts), encoding="utf-8")
    print(f"Wrote {out} ({out.stat().st_size} bytes)")

if __name__ == "__main__":
    main()
