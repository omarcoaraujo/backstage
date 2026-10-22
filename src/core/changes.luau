--// Modules
const kinds = require "./kinds"
const mode = require "./mode"
const registry = require "./registry"

--// Types
export type listener = (value: kinds.value, previous: kinds.value, path: string) -> ()

--// Functions
const function inert() end

const function any(callback: listener): () -> ()
	if not mode.active() then return inert end

	const function on_change(path: string, value: kinds.value, previous: kinds.value)
		callback(value, previous, path)
	end

	return registry.on_change(on_change)
end

--// End
return table.freeze {
	any = any,
}
