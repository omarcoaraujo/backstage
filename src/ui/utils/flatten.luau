--// Modules
const registry = require "../../core/registry"

--// Utils
const branch = require "./branch"

--// Types
export type guide = "full" | "end" | "none"
export type kind = "group" | "entry" | "buttons" | "adding"

export type row = {
	kind: kind,
	path: string,
	name: string,

	depth: number,
	guides: { guide },

	owner: string,
	expanded: boolean,

	entry: registry.entry?,
	buttons: { registry.button_entry }?,
	source: branch.branch?,
}

export type search = {
	active: boolean,
	name: (name: string) -> boolean,
	text: (path: string) -> boolean,
}

export type state = {
	opened: { [string]: boolean },
	closed: { [string]: boolean },

	adding: { [string]: boolean },
	search: search,
}

type node = {
	row: row,
	children: { node },
}

--// Functions
const function leaf(row: row): node
	return { row = row, children = {} }
end

const function buttons_match(state: state, entries: { registry.button_entry }, forced: boolean)
	if forced then return true end

	for _, entry in entries do
		if state.search.name(entry.name) then return true end
	end

	return false
end

const function build_group(
	source: branch.branch,
	name: string,
	path: string,

	depth: number,
	forced: boolean,
	state: state
): node?
	const search = state.search
	const passes = forced or search.name(name)

	const expanded = if search.active then not state.closed[path] else state.opened[path] == true
	const group = leaf {
		kind = "group",
		path = path,
		name = name,

		depth = depth,
		guides = {},

		owner = path,
		expanded = expanded,
		source = source,
	}

	if not search.active and not expanded then return group end
	if expanded and state.adding[path] then
		table.insert(
			group.children,
			leaf {
				kind = "adding",
				path = path,
				name = name,

				depth = depth + 1,
				guides = {},

				owner = path,
				expanded = false,
				source = source,
			}
		)
	end

	local shown = not search.active
	for _, entry in source.entries do
		if search.active and not (passes or search.name(entry.name) or search.text(entry.path)) then continue end

		shown = true
		table.insert(
			group.children,
			leaf {
				kind = "entry",
				path = entry.path,
				name = entry.name,

				depth = depth + 1,
				guides = {},

				owner = path,
				expanded = false,
				entry = entry,
			}
		)
	end

	if #source.buttons > 0 and (not search.active or buttons_match(state, source.buttons, passes)) then
		shown = true
		table.insert(
			group.children,
			leaf {
				kind = "buttons",
				path = `{path}#buttons`,
				name = "buttons",

				depth = depth + 1,
				guides = {},

				owner = path,
				expanded = false,
				buttons = source.buttons,
			}
		)
	end

	for _, child_name in branch.sorted_names(source.groups) do
		const child =
			build_group(source.groups[child_name], child_name, `{path}.{child_name}`, depth + 1, passes, state)
		if not child then continue end

		shown = true
		table.insert(group.children, child)
	end

	if not shown and not passes then return nil end
	if not expanded then table.clear(group.children) end

	return group
end

const function tail_of(children: { node }): number
	local tail = 0

	for index, child in children do
		if child.row.kind == "group" or child.row.kind == "entry" then tail = index end
	end

	return tail
end

const function softened(current: guide): guide
	if current == "end" then return "none" end
	return current
end

const function descend(guides: { guide }): { guide }
	const result = {} :: { guide }

	for index = 1, #guides do
		result[index] = softened(guides[index])
	end

	return result
end

const function piece_of(index: number, tail: number): guide
	if index < tail then return "full" end
	if index == tail then return "end" end
	return "none"
end

const function emit(current: node, guides: { guide }, out: { row })
	current.row.guides = guides
	table.insert(out, current.row)

	const tail = tail_of(current.children)
	const inherited = descend(guides)

	for index, child in current.children do
		const piece = piece_of(index, tail)
		const own = table.clone(inherited)

		table.insert(own, piece)
		emit(child, own, out)
	end
end

const function flatten(root: branch.branch, state: state): { row }
	const rows = {}

	for _, name in branch.sorted_names(root.groups) do
		const group = build_group(root.groups[name], name, name, 0, false, state)
		if group then emit(group, {}, rows) end
	end

	return rows
end

--// End
return table.freeze {
	flatten = flatten,
}
