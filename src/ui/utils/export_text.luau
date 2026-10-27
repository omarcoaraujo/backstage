--// Modules
const exporter = require "../../core/export"
const kinds = require "../../core/kinds"
const registry = require "../../core/registry"

--// Component
return function()
	const changed = {}

	for _, entry in registry.list() do
		table.insert(changed, {
			path = entry.path,
			value = entry.value,

			default = entry.default,
			decimals = kinds.decimals(entry.descriptor),
		})
	end

	return exporter.text(changed)
end
