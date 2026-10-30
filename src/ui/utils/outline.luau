--// Packages
const vide = require "../../../roblox_packages/vide"

--// Utils
const branch = require "./branch"
const catalog = require "./catalog"
const filter = require "./filter"
const flatten = require "./flatten"
const px = require "./px"
const theme = require "../constants/theme"
const viewport = require "./viewport"

--// Types
export type props = {
	hold: (path: string) -> (),
	search: filter.instance,
}

export type outline = {
	rows: () -> { flatten.row },
	layout: () -> viewport.layout,
	key: (current: flatten.row) -> string,

	is_expanded: (path: string) -> boolean,
	is_adding: (path: string) -> boolean,

	toggle: (path: string) -> (),
	press_add: (path: string, actions: catalog.actions) -> (),

	close_adding: (path: string) -> (),
	report_height: (path: string, height: number) -> (),
	rebuild: () -> (),
}

--// Functions
const function create(props: props): outline
	const opened = {} :: { [string]: boolean }
	const closed = {} :: { [string]: boolean }
	const adding = {} :: { [string]: boolean }

	const measured = {} :: { [string]: number }
	local closed_for = ""

	const structure = vide.source(0)
	const generation = vide.source(0)
	const measures = vide.source(0)
	const tree = vide.source(branch.collect())

	const function bump()
		structure(structure() + 1)
	end

	const function flatten_state(): flatten.state
		const query = props.search.query()

		if query ~= closed_for then
			table.clear(closed)
			closed_for = query
		end

		return {
			opened = opened,
			closed = closed,
			adding = adding,

			search = {
				active = props.search.searching(),
				name = props.search.matches,
				text = props.search.text_hit,
			},
		}
	end

	const rows = vide.derive(function()
		structure()
		return flatten.flatten(tree(), flatten_state())
	end)

	const layout = vide.derive(function()
		measures()

		const unit = px(theme.row_height)()
		const heights = {}

		for _, current in rows() do
			table.insert(heights, if current.kind == "buttons" then measured[current.path] or unit else unit)
		end

		return viewport.measure(heights)
	end)

	const function key(current: flatten.row)
		return `{generation()}:{current.kind}:{current.path}`
	end

	const function is_expanded(path: string)
		structure()
		if props.search.searching() then return not closed[path] end
		return opened[path] == true
	end

	const function is_adding(path: string)
		structure()
		return adding[path] == true
	end

	const function toggle(path: string)
		props.hold(path)

		if props.search.searching() then
			closed[path] = not closed[path]
		else
			opened[path] = not opened[path]
		end

		bump()
	end

	const function press_add(path: string, actions: catalog.actions)
		opened[path] = true

		if actions.on_append then
			actions.on_append()
			bump()
			return
		end

		adding[path] = not adding[path]
		bump()
	end

	const function close_adding(path: string)
		if not adding[path] then return end
		adding[path] = nil
		bump()
	end

	const function report_height(path: string, height: number)
		task.defer(function()
			if measured[path] == height then return end
			measured[path] = height
			measures(measures() + 1)
		end)
	end

	const function rebuild()
		generation(generation() + 1)
		tree(branch.collect())
	end

	return {
		rows = rows,
		layout = layout,
		key = key,

		is_expanded = is_expanded,
		is_adding = is_adding,

		toggle = toggle,
		press_add = press_add,

		close_adding = close_adding,
		report_height = report_height,
		rebuild = rebuild,
	}
end

--// End
return table.freeze {
	create = create,
}
