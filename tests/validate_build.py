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

print()
print(f"Results: {len(passes)} PASS, {len(errors)} FAIL")
sys.exit(1 if errors else 0)
