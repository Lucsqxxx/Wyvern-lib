# Uploading Wyvern icons to Roblox

GitHub PNGs under `assets/icons/` are the **source of truth**.
Roblox image assets are the **runtime delivery format** for `ImageLabel` / `ImageButton`.

## Why this step is required

Roblox does **not** accept GitHub raw URLs as `ImageLabel.Image`.
A valid ContentId looks like: `rbxassetid://YOUR_REAL_ID`.

## Creator workflow

1. Open [Roblox Creator Dashboard](https://create.roblox.com/dashboard/creations) → **Development Items** → **Images** (or Decals depending on current UI).
2. For each file in `assets/icons/*.png` (except `_sheet.png` and `manifest.json`):
   - Upload the PNG
   - Wait until moderation/processing completes
   - Copy the numeric **Asset ID**
3. Update `assets/icons/manifest.json`: set `assetId` to `"rbxassetid://<id>"` and `verified` to `true`.
4. Update `Icons/AssetIds.lua` (or the `Icons.AssetIds` table) with the same IDs.
5. Rebuild `dist/Wyvern.lua`.

## Never

- Invent `rbxassetid://` numbers
- Commit cookies / API keys / `.ROBLOSECURITY`
- Point ImageLabel at `https://raw.githubusercontent.com/...`

## After upload

```lua
-- Example only — replace with YOUR real IDs
library.Icons.SetAsset("Settings", "rbxassetid://YOUR_REAL_ID")
```

Or ship IDs inside the library once verified.
