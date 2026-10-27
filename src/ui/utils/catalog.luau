--// Modules
const registry = require "../../core/registry"

--// Utils
const branch = require "./branch"

--// Types
export type actions = {
	suggest: () -> string,
	on_add: ((key: string) -> boolean)?,
	on_append: (() -> ())?,
}

--// Functions
const function remover(parent: string, key: string): (() -> ())?
	if not registry.is_catalog(parent) then return nil end
	return function()
		registry.remove_item(parent, key)
	end
end

const function actions(path: string, source: branch.branch): actions
	const result = {
		suggest = function()
			return branch.next_key(source)
		end,
	} :: actions

	if not registry.is_catalog(path) then return result end
	if branch.is_list(source) then
		result.on_append = function()
			registry.add_item(path, branch.next_key(source))
		end

		return result
	end

	result.on_add = function(key: string)
		return registry.add_item(path, key)
	end

	return result
end

--// End
return table.freeze {
	remover = remover,
	actions = actions,
}
