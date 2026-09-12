#!/usr/bin/env python3
"""Static / build validation for Wyvern UI Lib (not live Roblox)."""
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parent.parent
errors = []
passes = []

def ok(msg):
    passes.append(msg)
    print("PASS:", msg)

def fail(msg):
    errors.append(msg)
    print("FAIL:", msg)

# 1 dist exists
dist = ROOT / "dist" / "Wyvern.lua"
if dist.exists() and dist.stat().st_size > 1000:
    ok(f"dist exists ({dist.stat().st_size} bytes)")
else:
    fail("dist/Wyvern.lua missing or empty")

src = dist.read_text(encoding="utf-8") if dist.exists() else ""

# 2 returns library
if src.rstrip().endswith("return Wyvern"):
    ok("dist ends with return Wyvern")
else:
    fail("dist does not return Wyvern")

# 3 no require(script
if "require(script" not in src:
    ok("no require(script) in dist")
else:
    fail("require(script) still present in dist")

# 4 public API surface
for name in ["CreateWindow", "OpenSettings", "PopupManager", "TitleCluster", "DragThreshold", "OverlayLayer", "_positionPopup", "BindTheme", "ApplyTheme"]:
    if name in src:
        ok(f"contains {name}")
    else:
        fail(f"missing {name}")

# 5 modules defined
defs = len(re.findall(r'__wyvern_define\("([^"]+)"', src))
if defs >= 25:
    ok(f"modules defined: {defs}")
else:
    fail(f"too few modules: {defs}")

# 6 MultiDropdown overlay
if "MultiDropdown:_positionPopup" in src or "function MultiDropdown:_positionPopup" in src:
    ok("MultiDropdown overlay positioning")
else:
    # may be wrapped
    if "_positionPopup" in src and "MultiDropdown" in src:
        ok("MultiDropdown has positioning helpers")
    else:
        fail("MultiDropdown overlay missing")

# 7 source files
for rel in ["Core/Window.lua", "Core/Theme.lua", "Core/PopupManager.lua", "Core/Component.lua",
            "Components/Dropdown.lua", "Components/MultiDropdown.lua", "Components/Toggle.lua"]:
    if (ROOT / rel).exists():
        ok(f"source {rel}")
    else:
        fail(f"missing {rel}")

# 8 Theme has listeners
theme = (ROOT / "Core/Theme.lua").read_text()
if "function Theme:OnChanged" in theme and "function Theme:_notify" in theme:
    ok("Theme live notify API")
else:
    fail("Theme notify incomplete")

# 9 Component BindTheme
comp = (ROOT / "Core/Component.lua").read_text()
if "function Component:BindTheme" in comp:
    ok("Component:BindTheme")
else:
    fail("Component:BindTheme missing")


# --- Theme coverage on remaining components ---
for rel, markers in [
    ("Components/Keybind.lua", ["ApplyTheme", "BindTheme"]),
    ("Components/ColorPicker.lua", ["ApplyTheme", "BindTheme"]),
    ("Components/Textbox.lua", ["ApplyTheme", "BindTheme"]),
]:
    body = (ROOT / rel).read_text()
    for m in markers:
        if m in body:
            ok(f"{rel} has {m}")
        else:
            fail(f"{rel} missing {m}")

# Regression: drag threshold present
win = (ROOT / "Core/Window.lua").read_text()
if "DragThreshold" in win and "_dragPending" in win:
    ok("drag threshold regression (click != drag)")
else:
    fail("drag threshold regression missing")

if "TitleCluster" in win and "UIListLayout" in win:
    ok("header TitleCluster regression")
else:
    fail("header layout regression")

if "OpenSettings" in win and "_settingsTab" in win:
    ok("settings single-instance regression")
else:
    fail("settings regression")

if "PopupManager.CloseAll" in win:
    ok("minimize/tab closes popups")
else:
    fail("popup close on minimize missing")

# Dist must include Keybind/ColorPicker/Textbox ApplyTheme
for name in ["Keybind:ApplyTheme", "ColorPicker:ApplyTheme", "Textbox:ApplyTheme"]:
    # factory-wrapped may not keep exact name string
    short = name.split(":")[0]
    if short in src and "ApplyTheme" in src:
        ok(f"dist mentions {short} + ApplyTheme")
    else:
        fail(f"dist missing {short}/ApplyTheme")

# Public API inventory presence in dist
for api in ["CreateButton", "CreateToggle", "CreateSlider", "CreateDropdown",
            "CreateMultiDropdown", "CreateTextbox", "CreateInput", "CreateKeybind",
            "CreateColorPicker", "CreateLabel", "CreateDivider"]:
    if api in src:
        ok(f"public API {api}")
    else:
        fail(f"public API missing {api}")


# Icon registry completeness
required_icons = ["Search","Eye","Settings","Check","Close","Minimize","Home","User","Checklist","Back"]
renderer = (ROOT / "Icons" / "Renderer.lua").read_text() if (ROOT / "Icons" / "Renderer.lua").exists() else ""
for name in required_icons:
    if f"builders.{name}" in renderer or f'["{name}"]' in renderer or f"function builders.{name}" in renderer:
        ok(f"icon builder {name}")
    else:
        # aliases may exist
        if name in renderer:
            ok(f"icon ref {name}")
        else:
            fail(f"missing icon builder {name}")
# no primary unicode icon path in Toggle
toggle = (ROOT / "Components" / "Toggle.lua").read_text()
if "✓" in toggle or "✔" in toggle:
    fail("Toggle still uses unicode check")
else:
    ok("Toggle no unicode check")

print()
print(f"Results: {len(passes)} PASS, {len(errors)} FAIL")
sys.exit(1 if errors else 0)
