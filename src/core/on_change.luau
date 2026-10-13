--// Modules
const mode = require "./mode"
const registry = require "./registry"

--// Functions
const function inert() end

--// End
return function<value>(path: string, callback: (value: value, previous: value) -> ()): () -> ()
	if not mode.active() then return inert end
	return registry.on_change(function(changed, current, previous)
		if changed ~= path then return end
		callback(current :: any, previous :: any)
	end)
end
