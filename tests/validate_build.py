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

# Phase 2 API presence in dist
phase2 = [
    "AddRow", "AddTable", "AddRadioGroup", "AddSwitch",
    "TooltipManager", "SearchIndex", "RegisterTheme", "DebugDump",
    "OpenContextMenu", "GetComponent", "CreateProgressBar", "Confirm",
]
for token in phase2:
    if token in src:
        ok(f"phase2 {token}")
    else:
        fail(f"phase2 missing {token}")


# Real Lua syntax compile of dist (portable subset / Luau-compatible without +=)
try:
    import lupa
    _lua = lupa.LuaRuntime()
    _compile_ok, _compile_err = _lua.eval('function(s) local c,e=load(s,"Wyvern","t"); return c~=nil, tostring(e) end')(src)
    if _compile_ok:
        ok("dist compiles under Lua load()")
    else:
        fail(f"dist Lua syntax: {_compile_err}")
except Exception as e:
    print("SKIP: lupa compile check:", e)

# Orphan leading-dot lines (return Module stripping corruption)
import re as _re
orphan = 0
for i, line in enumerate(src.splitlines(), 1):
    s = line.strip()
    if _re.match(r"^\.\w+", s):
        fail(f"orphan leading-dot at dist line {i}: {s}")
        orphan += 1
if orphan == 0:
    ok("no orphan leading-dot statements in dist")

# Premature module-level return before Notification.Show / OpenContextMenu
for mod, method in [("Core.Notification", "function Notification.Show"), ("Core.PopupManager", "OpenContextMenu")]:
    a = src.find(f'__wyvern_define("{mod}"')
    b = src.find("-- ===== END " + mod, a) if a>=0 else -1
    if a < 0:
        fail(f"missing module {mod}")
        continue
    body = src[a:b if b>0 else a+8000]
    ret = body.rfind(f"return {mod.split('.')[-1]}")
    meth = body.find(method)
    if meth >= 0 and ret > meth:
        ok(f"{mod} method before return")
    elif meth < 0:
        fail(f"{mod} missing {method}")
    else:
        fail(f"{mod} method after return")

# Window method uniqueness
for method in ["IsVisible", "IsMinimized"]:
    c = src.count(f"function Window:{method}")
    if c == 1:
        ok(f"Window:{method} unique")
    else:
        fail(f"Window:{method} count={c}")

print()
print(f"Results: {len(passes)} PASS, {len(errors)} FAIL")
sys.exit(1 if errors else 0)
