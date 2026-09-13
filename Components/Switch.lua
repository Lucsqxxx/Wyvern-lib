-- Components/Switch.lua — alias of Toggle with Name defaults for switch semantics
local Toggle = require(script.Parent.Toggle)
local Switch = {}
function Switch.new(config, parent, theme, search, input)
	config = config or {}
	config.Name = config.Name or config.Title or "Switch"
	return Toggle.new(config, parent, theme, search, input)
end
return Switch
