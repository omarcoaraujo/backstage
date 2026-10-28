--// Modules
const registry = require "../../core/registry"

--// Types
export type branch = {
	entries: { registry.entry },
	buttons: { registry.button_entry },
	groups: { [string]: branch },
}

--// Functions
const function create(): branch
	return { entries = {}, buttons = {}, groups = {} }
end

const function descend(root: branch, group_path: string): branch
	local current = root

	for segment in string.gmatch(group_path, "[^%.]+") do
		const child = current.groups[segment] or create()
		current.groups[segment] = child
		current = child
	end

	return current
end

const function collect(): branch
	const root = create()

	for _, entry in registry.list() do
		const entries = descend(root, entry.group).entries
		table.insert(entries, if entry.leading then 1 else #entries + 1, entry)
	end

	for _, entry in registry.list_buttons() do
		table.insert(descend(root, entry.group).buttons, entry)
	end

	return root
end

const function sorted_names(groups: { [string]: branch })
	const names = {}

	for name in groups do
		table.insert(names, name)
	end

	table.sort(names)
	return names
end

const function child_names(source: branch)
	const names = {}

	for name in source.groups do
		table.insert(names, name)
	end

	for _, entry in source.entries do
		table.insert(names, entry.name)
	end

	return names
end

const function next_key(source: branch)
	local highest = 0
	local numbered = false

	for _, name in child_names(source) do
		const position = tonumber(name)
		if not position then continue end

		numbered = true
		highest = math.max(highest, position)
	end

	return if numbered then tostring(highest + 1) else ""
end

const function is_list(source: branch)
	const names = child_names(source)
	const present = {}

	for _, name in names do
		present[name] = true
	end

	for position = 1, #names do
		if not present[tostring(position)] then return false end
	end

	return #names > 0
end

--// End
return table.freeze {
	create = create,
	collect = collect,
	sorted_names = sorted_names,

	next_key = next_key,
	is_list = is_list,
}
