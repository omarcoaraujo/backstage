--// Modules
const kinds = require "./kinds"
const mode = require "./mode"
const registry = require "./registry"

--// Types
export type listener = (path: string, value: kinds.value, previous: kinds.value) -> ()

--// Functions
const function inert() end

const function any(callback: listener): () -> ()
	if not mode.active() then return inert end
	return registry.on_change(callback)
end

--// End
return table.freeze {
	any = any,
}
