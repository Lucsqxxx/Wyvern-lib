-- examples/AzureUIShell.lua
-- SAFE UI-ONLY shell reproducing Azure-style tab/module structure on Wyvern.
-- All callbacks are benign print/Notify stubs. No game/exploit logic.

local function wyvernHttpGet(url)
	local ok, body = pcall(function()
		return game:HttpGet(url)
	end)
	if ok and type(body) == "string" and #body > 100 then
		return body
	end
	local req = (syn and syn.request) or http_request or request
	if type(req) == "function" then
		local ok2, res = pcall(req, { Url = url, Method = "GET" })
		if ok2 and type(res) == "table" and type(res.Body) == "string" and #res.Body > 100 then
			return res.Body
		end
	end
	error("[Wyvern Shell] failed to download library: " .. tostring(url))
end

local function wyvernLoad(src)
	local chunk, err
	if type(loadstring) == "function" then
		chunk, err = loadstring(src)
	elseif type(load) == "function" then
		chunk, err = load(src)
	else
		error("[Wyvern Shell] loadstring/load unavailable")
	end
	if not chunk then
		error("[Wyvern Shell] compile failed: " .. tostring(err))
	end
	local ok, lib = pcall(chunk)
	if not ok then
		error("[Wyvern Shell] runtime init failed: " .. tostring(lib))
	end
	if type(lib) ~= "table" or type(lib.CreateWindow) ~= "function" then
		error("[Wyvern Shell] library did not return CreateWindow API")
	end
	return lib
end

local library = wyvernLoad(wyvernHttpGet(
	"https://raw.githubusercontent.com/Lucsqxxx/Wyvern-lib/main/dist/Wyvern.lua"
))

local Window = library:CreateWindow({ Name = "Wyvern UI Shell", Version = "1.0.0" })
if not Window then
	error("[Wyvern Shell] CreateWindow returned nil")
end

local function stub(name)
  return function(...)
    local a = {...}
    print("[Wyvern Demo]", name, table.unpack(a))
  end
end

local function notify(text)
  library:Notify({ Title = "Wyvern Demo", Text = tostring(text), Duration = 2 })
end

local MainTab = Window:CreateTab({ Name = "Main" })
local MainTab_L = MainTab:CreateSection({ Name = "Left" })
local MainTab_R = MainTab:CreateSection({ Name = "Right" })

local F = MainTab_L:CreateFeature({
  Name = "Auto Parry",
  Description = "Auto Parry Settings",
  Flag = "AutoParryModule",
  Callback = stub("Auto Parry"),
})
F:CreateToggle({ Name = "Enabled", Default = false, Flag = "AutoParryModule_en", Callback = stub("Auto Parry Enabled") })
F:CreateSlider({ Name = "Intensity", Min = 0, Max = 100, Default = 50, Flag = "AutoParryModule_int", Callback = stub("Auto Parry Intensity") })

local F = MainTab_R:CreateFeature({
  Name = "Mobile Curve Selector",
  Description = "Curve Mode Selector in Mobile",
  Flag = "SetCurveModule",
  Callback = stub("Mobile Curve Selector"),
})
F:CreateToggle({ Name = "Enabled", Default = false, Flag = "SetCurveModule_en", Callback = stub("Mobile Curve Selector Enabled") })
F:CreateSlider({ Name = "Intensity", Min = 0, Max = 100, Default = 50, Flag = "SetCurveModule_int", Callback = stub("Mobile Curve Selector Intensity") })

local F = MainTab_R:CreateFeature({
  Name = "Humanizer",
  Description = "Choose a random parry accuracy range.",
  Flag = "HumanizerModule",
  Callback = stub("Humanizer"),
})
F:CreateToggle({ Name = "Enabled", Default = false, Flag = "HumanizerModule_en", Callback = stub("Humanizer Enabled") })
F:CreateSlider({ Name = "Intensity", Min = 0, Max = 100, Default = 50, Flag = "HumanizerModule_int", Callback = stub("Humanizer Intensity") })

local F = MainTab_R:CreateFeature({
  Name = "Singularity Detection",
  Description = "Blocks parry when Singularity Cape is active",
  Flag = "ZX_SingularityDetection",
  Callback = stub("Singularity Detection"),
})
F:CreateToggle({ Name = "Enabled", Default = false, Flag = "ZX_SingularityDetection_en", Callback = stub("Singularity Detection Enabled") })
F:CreateSlider({ Name = "Intensity", Min = 0, Max = 100, Default = 50, Flag = "ZX_SingularityDetection_int", Callback = stub("Singularity Detection Intensity") })

local BlatantTab = Window:CreateTab({ Name = "Blatant" })
local BlatantTab_L = BlatantTab:CreateSection({ Name = "Left" })
local BlatantTab_R = BlatantTab:CreateSection({ Name = "Right" })

local F = BlatantTab_R:CreateFeature({
  Name = "Ability Exploit",
  Description = "Ability Exploit",
  Flag = "AbilityExploit",
  Callback = stub("Ability Exploit"),
})
F:CreateToggle({ Name = "Enabled", Default = false, Flag = "AbilityExploit_en", Callback = stub("Ability Exploit Enabled") })
F:CreateSlider({ Name = "Intensity", Min = 0, Max = 100, Default = 50, Flag = "AbilityExploit_int", Callback = stub("Ability Exploit Intensity") })

local F = BlatantTab_L:CreateFeature({
  Name = "Semi Immortality",
  Description = "Click to show the floating ON/OFF panel",
  Flag = "ZX_SemiImmortalMod",
  Callback = stub("Semi Immortality"),
})
F:CreateToggle({ Name = "Enabled", Default = false, Flag = "ZX_SemiImmortalMod_en", Callback = stub("Semi Immortality Enabled") })
F:CreateSlider({ Name = "Intensity", Min = 0, Max = 100, Default = 50, Flag = "ZX_SemiImmortalMod_int", Callback = stub("Semi Immortality Intensity") })

local SpamTab = Window:CreateTab({ Name = "Spam" })
local SpamTab_L = SpamTab:CreateSection({ Name = "Left" })
local SpamTab_R = SpamTab:CreateSection({ Name = "Right" })

local F = SpamTab_L:CreateFeature({
  Name = "Manual Spam",
  Description = "Manually Spams Parry",
  Flag = "Manual_Spam_Parry",
  Callback = stub("Manual Spam"),
})
F:CreateToggle({ Name = "Enabled", Default = false, Flag = "Manual_Spam_Parry_en", Callback = stub("Manual Spam Enabled") })
F:CreateSlider({ Name = "Intensity", Min = 0, Max = 100, Default = 50, Flag = "Manual_Spam_Parry_int", Callback = stub("Manual Spam Intensity") })

local F = SpamTab_R:CreateFeature({
  Name = "Auto Spam",
  Description = "Automatically spam parries ball",
  Flag = "AutoSpamModule",
  Callback = stub("Auto Spam"),
})
F:CreateToggle({ Name = "Enabled", Default = false, Flag = "AutoSpamModule_en", Callback = stub("Auto Spam Enabled") })
F:CreateSlider({ Name = "Intensity", Min = 0, Max = 100, Default = 50, Flag = "AutoSpamModule_int", Callback = stub("Auto Spam Intensity") })

local DetectionTab = Window:CreateTab({ Name = "Detection" })
local DetectionTab_L = DetectionTab:CreateSection({ Name = "Left" })
local DetectionTab_R = DetectionTab:CreateSection({ Name = "Right" })

local F = DetectionTab_L:CreateFeature({
  Name = "Staff Detection",
  Description = "Detect Bladeball Mod in the server",
  Callback = stub("Staff Detection"),
})
F:CreateToggle({ Name = "Enabled", Default = false, Flag = "_en", Callback = stub("Staff Detection Enabled") })
F:CreateSlider({ Name = "Intensity", Min = 0, Max = 100, Default = 50, Flag = "_int", Callback = stub("Staff Detection Intensity") })

local F = DetectionTab_L:CreateFeature({
  Name = "Infinity Detection",
  Description = "Detect infinity balls",
  Flag = "InfinityModule",
  Callback = stub("Infinity Detection"),
})
F:CreateToggle({ Name = "Enabled", Default = false, Flag = "InfinityModule_en", Callback = stub("Infinity Detection Enabled") })
F:CreateSlider({ Name = "Intensity", Min = 0, Max = 100, Default = 50, Flag = "InfinityModule_int", Callback = stub("Infinity Detection Intensity") })

local F = DetectionTab_R:CreateFeature({
  Name = "Death Slash Detection",
  Description = "Detect death slash",
  Flag = "DeathSlashModule",
  Callback = stub("Death Slash Detection"),
})
F:CreateToggle({ Name = "Enabled", Default = false, Flag = "DeathSlashModule_en", Callback = stub("Death Slash Detection Enabled") })
F:CreateSlider({ Name = "Intensity", Min = 0, Max = 100, Default = 50, Flag = "DeathSlashModule_int", Callback = stub("Death Slash Detection Intensity") })

local F = DetectionTab_L:CreateFeature({
  Name = "Time Hole Detection",
  Description = "Detect time hole",
  Flag = "TimeHoleModule",
  Callback = stub("Time Hole Detection"),
})
F:CreateToggle({ Name = "Enabled", Default = false, Flag = "TimeHoleModule_en", Callback = stub("Time Hole Detection Enabled") })
F:CreateSlider({ Name = "Intensity", Min = 0, Max = 100, Default = 50, Flag = "TimeHoleModule_int", Callback = stub("Time Hole Detection Intensity") })

local F = DetectionTab_R:CreateFeature({
  Name = "Slashes Of Fury Detection",
  Description = "Detect slashes of fury",
  Flag = "SlashesModule",
  Callback = stub("Slashes Of Fury Detection"),
})
F:CreateToggle({ Name = "Enabled", Default = false, Flag = "SlashesModule_en", Callback = stub("Slashes Of Fury Detection Enabled") })
F:CreateSlider({ Name = "Intensity", Min = 0, Max = 100, Default = 50, Flag = "SlashesModule_int", Callback = stub("Slashes Of Fury Detection Intensity") })

local F = DetectionTab_R:CreateFeature({
  Name = "Dribble Detection",
  Description = "Toggle Dribble Ball detection",
  Flag = "DribbleDetectionModule",
  Callback = stub("Dribble Detection"),
})
F:CreateToggle({ Name = "Enabled", Default = false, Flag = "DribbleDetectionModule_en", Callback = stub("Dribble Detection Enabled") })
F:CreateSlider({ Name = "Intensity", Min = 0, Max = 100, Default = 50, Flag = "DribbleDetectionModule_int", Callback = stub("Dribble Detection Intensity") })

local F = DetectionTab_L:CreateFeature({
  Name = "Anti-Phantom",
  Description = "Anti-phantom detection",
  Flag = "PhantomModule",
  Callback = stub("Anti-Phantom"),
})
F:CreateToggle({ Name = "Enabled", Default = false, Flag = "PhantomModule_en", Callback = stub("Anti-Phantom Enabled") })
F:CreateSlider({ Name = "Intensity", Min = 0, Max = 100, Default = 50, Flag = "PhantomModule_int", Callback = stub("Anti-Phantom Intensity") })

local PlayerTab = Window:CreateTab({ Name = "Player" })
local PlayerTab_L = PlayerTab:CreateSection({ Name = "Left" })
local PlayerTab_R = PlayerTab:CreateSection({ Name = "Right" })

local F = PlayerTab_L:CreateFeature({
  Name = "Infinite Jump",
  Description = "Character Infinite Jump",
  Flag = "infinitejump",
  Callback = stub("Infinite Jump"),
})
F:CreateToggle({ Name = "Enabled", Default = false, Flag = "infinitejump_en", Callback = stub("Infinite Jump Enabled") })
F:CreateSlider({ Name = "Intensity", Min = 0, Max = 100, Default = 50, Flag = "infinitejump_int", Callback = stub("Infinite Jump Intensity") })

local F = PlayerTab_L:CreateFeature({
  Name = "Player Cosmetics",
  Description = "Apply Headless and Korblox",
  Flag = "Player_Cosmetics",
  Callback = stub("Player Cosmetics"),
})
F:CreateToggle({ Name = "Enabled", Default = false, Flag = "Player_Cosmetics_en", Callback = stub("Player Cosmetics Enabled") })
F:CreateSlider({ Name = "Intensity", Min = 0, Max = 100, Default = 50, Flag = "Player_Cosmetics_int", Callback = stub("Player Cosmetics Intensity") })

local F = PlayerTab_R:CreateFeature({
  Name = "Ability ESP",
  Description = "Displays equipped abilities above players",
  Flag = "AbilityESPModule",
  Callback = stub("Ability ESP"),
})
F:CreateToggle({ Name = "Enabled", Default = false, Flag = "AbilityESPModule_en", Callback = stub("Ability ESP Enabled") })
F:CreateSlider({ Name = "Intensity", Min = 0, Max = 100, Default = 50, Flag = "AbilityESPModule_int", Callback = stub("Ability ESP Intensity") })

local F = PlayerTab_L:CreateFeature({
  Name = "Look at Ball",
  Description = "Camera always faces the closest ball",
  Flag = "ZX_LookAtBall",
  Callback = stub("Look at Ball"),
})
F:CreateToggle({ Name = "Enabled", Default = false, Flag = "ZX_LookAtBall_en", Callback = stub("Look at Ball Enabled") })
F:CreateSlider({ Name = "Intensity", Min = 0, Max = 100, Default = 50, Flag = "ZX_LookAtBall_int", Callback = stub("Look at Ball Intensity") })

local F = PlayerTab_R:CreateFeature({
  Name = "Orbit Ball",
  Description = "Travel to ball then orbit around it",
  Flag = "ZX_OrbitBall",
  Callback = stub("Orbit Ball"),
})
F:CreateToggle({ Name = "Enabled", Default = false, Flag = "ZX_OrbitBall_en", Callback = stub("Orbit Ball Enabled") })
F:CreateSlider({ Name = "Intensity", Min = 0, Max = 100, Default = 50, Flag = "ZX_OrbitBall_int", Callback = stub("Orbit Ball Intensity") })

local F = PlayerTab_L:CreateFeature({
  Name = "Name Spoof",
  Description = "Spoof your display name with verified badge",
  Flag = "ZX_NameSpoof",
  Callback = stub("Name Spoof"),
})
F:CreateToggle({ Name = "Enabled", Default = false, Flag = "ZX_NameSpoof_en", Callback = stub("Name Spoof Enabled") })
F:CreateSlider({ Name = "Intensity", Min = 0, Max = 100, Default = 50, Flag = "ZX_NameSpoof_int", Callback = stub("Name Spoof Intensity") })

local VisualTab = Window:CreateTab({ Name = "Visual" })
local VisualTab_L = VisualTab:CreateSection({ Name = "Left" })
local VisualTab_R = VisualTab:CreateSection({ Name = "Right" })

local F = VisualTab_L:CreateFeature({
  Name = "Ball Trail",
  Description = "Toggles ball trail effects",
  Flag = "Ball_Trail",
  Callback = stub("Ball Trail"),
})
F:CreateToggle({ Name = "Enabled", Default = false, Flag = "Ball_Trail_en", Callback = stub("Ball Trail Enabled") })
F:CreateSlider({ Name = "Intensity", Min = 0, Max = 100, Default = 50, Flag = "Ball_Trail_int", Callback = stub("Ball Trail Intensity") })

local F = VisualTab_L:CreateFeature({
  Name = "Ball Stats",
  Description = "Toggle ball speed stats display",
  Flag = "Ball_Stats",
  Callback = stub("Ball Stats"),
})
F:CreateToggle({ Name = "Enabled", Default = false, Flag = "Ball_Stats_en", Callback = stub("Ball Stats Enabled") })
F:CreateSlider({ Name = "Intensity", Min = 0, Max = 100, Default = 50, Flag = "Ball_Stats_int", Callback = stub("Ball Stats Intensity") })

local F = VisualTab_R:CreateFeature({
  Name = "Hit Sounds",
  Description = "Toggles hit sounds",
  Flag = "Hit_Sounds",
  Callback = stub("Hit Sounds"),
})
F:CreateToggle({ Name = "Enabled", Default = false, Flag = "Hit_Sounds_en", Callback = stub("Hit Sounds Enabled") })
F:CreateSlider({ Name = "Intensity", Min = 0, Max = 100, Default = 50, Flag = "Hit_Sounds_int", Callback = stub("Hit Sounds Intensity") })

local MiscTab = Window:CreateTab({ Name = "Misc" })
local MiscTab_L = MiscTab:CreateSection({ Name = "Left" })
local MiscTab_R = MiscTab:CreateSection({ Name = "Right" })

local F = MiscTab_R:CreateFeature({
  Name = "Low Graphics",
  Description = "Reduce Rendering quality and shadows",
  Flag = "LowGraphics",
  Callback = stub("Low Graphics"),
})
F:CreateToggle({ Name = "Enabled", Default = false, Flag = "LowGraphics_en", Callback = stub("Low Graphics Enabled") })
F:CreateSlider({ Name = "Intensity", Min = 0, Max = 100, Default = 50, Flag = "LowGraphics_int", Callback = stub("Low Graphics Intensity") })

local F = MiscTab_R:CreateFeature({
  Name = "Auto Play",
  Description = "Automatically Plays Game",
  Flag = "AutoPlay",
  Callback = stub("Auto Play"),
})
F:CreateToggle({ Name = "Enabled", Default = false, Flag = "AutoPlay_en", Callback = stub("Auto Play Enabled") })
F:CreateSlider({ Name = "Intensity", Min = 0, Max = 100, Default = 50, Flag = "AutoPlay_int", Callback = stub("Auto Play Intensity") })

local F = MiscTab_L:CreateFeature({
  Name = "Feature",
  Description = "Control background music and sounds",
  Flag = "sound_controller",
  Callback = stub("Feature"),
})
F:CreateToggle({ Name = "Enabled", Default = false, Flag = "sound_controller_en", Callback = stub("Feature Enabled") })
F:CreateSlider({ Name = "Intensity", Min = 0, Max = 100, Default = 50, Flag = "sound_controller_int", Callback = stub("Feature Intensity") })

local F = MiscTab_L:CreateFeature({
  Name = "FOV",
  Description = "Changes Camera POV",
  Flag = "FOVModule",
  Callback = stub("FOV"),
})
F:CreateToggle({ Name = "Enabled", Default = false, Flag = "FOVModule_en", Callback = stub("FOV Enabled") })
F:CreateSlider({ Name = "Intensity", Min = 0, Max = 100, Default = 50, Flag = "FOVModule_int", Callback = stub("FOV Intensity") })

local F = MiscTab_L:CreateFeature({
  Name = "Character Speed",
  Description = "Changes Character Speed",
  Callback = stub("Character Speed"),
})
F:CreateToggle({ Name = "Enabled", Default = false, Flag = "_en", Callback = stub("Character Speed Enabled") })
F:CreateSlider({ Name = "Intensity", Min = 0, Max = 100, Default = 50, Flag = "_int", Callback = stub("Character Speed Intensity") })

local F = MiscTab_L:CreateFeature({
  Name = "Custom Announcer",
  Description = "Customize the Game Announcements",
  Flag = "Custom_Announcer",
  Callback = stub("Custom Announcer"),
})
F:CreateToggle({ Name = "Enabled", Default = false, Flag = "Custom_Announcer_en", Callback = stub("Custom Announcer Enabled") })
F:CreateSlider({ Name = "Intensity", Min = 0, Max = 100, Default = 50, Flag = "Custom_Announcer_int", Callback = stub("Custom Announcer Intensity") })

local F = MiscTab_L:CreateFeature({
  Name = "No Render",
  Description = "Disables Rendering of Effects",
  Flag = "No_Render",
  Callback = stub("No Render"),
})
F:CreateToggle({ Name = "Enabled", Default = false, Flag = "No_Render_en", Callback = stub("No Render Enabled") })
F:CreateSlider({ Name = "Intensity", Min = 0, Max = 100, Default = 50, Flag = "No_Render_int", Callback = stub("No Render Intensity") })

local WorldTab = Window:CreateTab({ Name = "World" })
local WorldTab_L = WorldTab:CreateSection({ Name = "Left" })
local WorldTab_R = WorldTab:CreateSection({ Name = "Right" })

local F = WorldTab_R:CreateFeature({
  Name = "FPS and Ping",
  Description = "Show your FPS and Ping",
  Flag = "StatsOverlayModule",
  Callback = stub("FPS and Ping"),
})
F:CreateToggle({ Name = "Enabled", Default = false, Flag = "StatsOverlayModule_en", Callback = stub("FPS and Ping Enabled") })
F:CreateSlider({ Name = "Intensity", Min = 0, Max = 100, Default = 50, Flag = "StatsOverlayModule_int", Callback = stub("FPS and Ping Intensity") })

local F = WorldTab_R:CreateFeature({
  Name = "FPS Booster",
  Description = "Lower your Graphics to improve FPS",
  Flag = "FPSBooster",
  Callback = stub("FPS Booster"),
})
F:CreateToggle({ Name = "Enabled", Default = false, Flag = "FPSBooster_en", Callback = stub("FPS Booster Enabled") })
F:CreateSlider({ Name = "Intensity", Min = 0, Max = 100, Default = 50, Flag = "FPSBooster_int", Callback = stub("FPS Booster Intensity") })

local F = WorldTab_L:CreateFeature({
  Name = "Feature",
  Description = "Toggles custom world filter effects",
  Callback = stub("Feature"),
})
F:CreateToggle({ Name = "Enabled", Default = false, Flag = "_en", Callback = stub("Feature Enabled") })
F:CreateSlider({ Name = "Intensity", Min = 0, Max = 100, Default = 50, Flag = "_int", Callback = stub("Feature Intensity") })

local F = WorldTab_L:CreateFeature({
  Name = "Atmosphere",
  Description = "Control atmosphere",
  Flag = "ZX_WorldAtmo",
  Callback = stub("Atmosphere"),
})
F:CreateToggle({ Name = "Enabled", Default = false, Flag = "ZX_WorldAtmo_en", Callback = stub("Atmosphere Enabled") })
F:CreateSlider({ Name = "Intensity", Min = 0, Max = 100, Default = 50, Flag = "ZX_WorldAtmo_int", Callback = stub("Atmosphere Intensity") })

local F = WorldTab_R:CreateFeature({
  Name = "Color Correction",
  Description = "Adjust colors",
  Flag = "ZX_WorldCC",
  Callback = stub("Color Correction"),
})
F:CreateToggle({ Name = "Enabled", Default = false, Flag = "ZX_WorldCC_en", Callback = stub("Color Correction Enabled") })
F:CreateSlider({ Name = "Intensity", Min = 0, Max = 100, Default = 50, Flag = "ZX_WorldCC_int", Callback = stub("Color Correction Intensity") })

local F = WorldTab_R:CreateFeature({
  Name = "Lighting",
  Description = "Control lighting",
  Flag = "ZX_WorldLight",
  Callback = stub("Lighting"),
})
F:CreateToggle({ Name = "Enabled", Default = false, Flag = "ZX_WorldLight_en", Callback = stub("Lighting Enabled") })
F:CreateSlider({ Name = "Intensity", Min = 0, Max = 100, Default = 50, Flag = "ZX_WorldLight_int", Callback = stub("Lighting Intensity") })

local F = WorldTab_L:CreateFeature({
  Name = "Sky Color Override",
  Description = "Override sky color",
  Flag = "ZX_SkyColor",
  Callback = stub("Sky Color Override"),
})
F:CreateToggle({ Name = "Enabled", Default = false, Flag = "ZX_SkyColor_en", Callback = stub("Sky Color Override Enabled") })
F:CreateSlider({ Name = "Intensity", Min = 0, Max = 100, Default = 50, Flag = "ZX_SkyColor_int", Callback = stub("Sky Color Override Intensity") })

local GUITab = Window:CreateTab({ Name = "GUI" })
local GUITab_L = GUITab:CreateSection({ Name = "Left" })
local GUITab_R = GUITab:CreateSection({ Name = "Right" })

local F = GUITab_R:CreateFeature({
  Name = "Theme Editor",
  Description = "Customize the interface theme",
  Flag = "ThemeEditor",
  Callback = stub("Theme Editor"),
})
F:CreateToggle({ Name = "Enabled", Default = false, Flag = "ThemeEditor_en", Callback = stub("Theme Editor Enabled") })
F:CreateSlider({ Name = "Intensity", Min = 0, Max = 100, Default = 50, Flag = "ThemeEditor_int", Callback = stub("Theme Editor Intensity") })

local F = GUITab_L:CreateFeature({
  Name = "GUI Visible",
  Description = "Visibility of GUI Library",
  Flag = "guilibraryvisible",
  Callback = stub("GUI Visible"),
})
F:CreateToggle({ Name = "Enabled", Default = false, Flag = "guilibraryvisible_en", Callback = stub("GUI Visible Enabled") })
F:CreateSlider({ Name = "Intensity", Min = 0, Max = 100, Default = 50, Flag = "guilibraryvisible_int", Callback = stub("GUI Visible Intensity") })

local UnlockTab = Window:CreateTab({ Name = "Unlock" })
local UnlockTab_L = UnlockTab:CreateSection({ Name = "Left" })
local UnlockTab_R = UnlockTab:CreateSection({ Name = "Right" })

local F = UnlockTab_L:CreateFeature({
  Name = "Unlock All",
  Description = "Unlock all Swords, Explosions and Emotes",
  Flag = "UnlockAll",
  Callback = stub("Unlock All"),
})
F:CreateToggle({ Name = "Enabled", Default = false, Flag = "UnlockAll_en", Callback = stub("Unlock All Enabled") })
F:CreateSlider({ Name = "Intensity", Min = 0, Max = 100, Default = 50, Flag = "UnlockAll_int", Callback = stub("Unlock All Intensity") })

-- Theme / UI settings demo on GUI tab
local ThemeF = GUITab_R:CreateFeature({ Name = "Theme Editor", Description = "Customize interface", Flag = "ThemeEditor", Callback = stub("Theme Editor") })
ThemeF:CreateSlider({ Name = "UI Scale", Min = 70, Max = 140, Default = 100, Callback = function(v) if Window.SetScale then Window:SetScale(v/100) end end })
ThemeF:CreateToggle({ Name = "Glass", Default = false, Callback = stub("Glass") })
ThemeF:CreateButton({ Name = "Notify Test", Callback = function() notify("Hello from Wyvern") end })
ThemeF:CreateDropdown({ Name = "Accent Preset", Options = {"Purple", "Blue", "Pink", "Green"}, Default = "Purple", Callback = stub("Accent") })
ThemeF:CreateMultiDropdown({ Name = "Visible Tabs", Options = {"Main", "Player", "World", "GUI"}, Callback = stub("Visible Tabs") })
ThemeF:CreateTextbox({ Name = "Profile Name", Placeholder = "Enter name...", Flag = "ProfileName", Callback = stub("Profile") })

library:Notify({ Title = "Wyvern", Text = "Safe UI shell loaded (no game logic)", Duration = 3 })
return library
