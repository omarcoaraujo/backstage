--// Packages
const vide = require "../../../roblox_packages/vide"

--// Modules
const registry = require "../../core/registry"

--// Utils
const filter = require "./filter"

--// Types
export type index = {
	update: (path: string, value: unknown) -> (),
	reset: () -> (),
}

--// Functions
const function create(): index
	const texts = {} :: { [string]: boolean }
	local indexed = false

	const function index_texts()
		const values = {} :: { [string]: string }
		table.clear(texts)

		for _, entry in registry.list() do
			if entry.descriptor.kind ~= "string" then continue end
			texts[entry.path] = true
			values[entry.path] = entry.value :: string
		end

		filter.replace_texts(values)
		indexed = true
	end

	const function drop_texts()
		filter.clear_texts()
		table.clear(texts)
		indexed = false
	end

	const function update(path: string, value: unknown)
		if texts[path] and type(value) == "string" then filter.set_text(path, value) end
	end

	const function reset()
		drop_texts()
		if filter.searching() then index_texts() end
	end

	vide.effect(function()
		if not filter.searching() or indexed then return end
		index_texts()
	end)

	return { update = update, reset = reset }
end

--// End
return table.freeze {
	create = create,
}
