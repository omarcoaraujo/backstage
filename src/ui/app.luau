--// Packages
const vide = require "../../roblox_packages/vide"

--// Modules
const kinds = require "../core/kinds"
const registry = require "../core/registry"

--// Utils
const px = require "./utils/px"

--// Components
const buttons = require "./components/buttons"
const choice = require "./components/controls/choice"
const color = require "./components/controls/color"
const group = require "./components/group"
const list = require "./components/list"
const number = require "./components/controls/number"
const row = require "./components/row"
const text = require "./components/controls/text"
const toggle = require "./components/controls/toggle"
const vector3 = require "./components/controls/vector3"
const window = require "./components/window"

--// Types
type props = {
	title: string,
	footer: string?,

	visible: () -> boolean,
	on_close: () -> (),
}

type branch = {
	entries: { registry.entry },
	buttons: { registry.button_entry },
	groups: { [string]: branch },
}

--// Functions
const function new_branch(): branch
	return { entries = {}, buttons = {}, groups = {} }
end

const function descend(root: branch, group_path: string): branch
	local current = root

	for segment in string.gmatch(group_path, "[^%.]+") do
		const child = current.groups[segment] or new_branch()
		current.groups[segment] = child
		current = child
	end

	return current
end

const function collect(): branch
	const root = new_branch()

	for _, entry in registry.list() do
		table.insert(descend(root, entry.group).entries, entry)
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

--// Component
return function(props: props)
	px.use_px()

	const appliers = {} :: { [string]: (value: kinds.value) -> () }

	const function bind(path: string, apply: (value: kinds.value) -> ())
		appliers[path] = apply
	end

	const function on_value_changed(path: string, value: kinds.value)
		const apply = appliers[path]
		if apply then apply(value) end
	end

	const function entry_row(entry: registry.entry)
		const path = entry.path
		const kind = entry.descriptor.kind

		const function on_change(value: unknown)
			registry.set(path, value)
		end

		if kind == "number" then
			const value = vide.source(entry.value :: number)

			bind(path, function(next_value)
				value(next_value :: number)
			end)

			return row {
				label = entry.name,
				content = number {
					value = value,
					on_change = on_change,

					min = entry.descriptor.min,
					max = entry.descriptor.max,
					step = entry.descriptor.step,
				},
			}
		end

		if kind == "boolean" then
			const value = vide.source(entry.value :: boolean)

			bind(path, function(next_value)
				value(next_value :: boolean)
			end)

			return row { label = entry.name, content = toggle { value = value, on_change = on_change } }
		end

		if kind == "color" then
			const value = vide.source(entry.value :: Color3)

			bind(path, function(next_value)
				value(next_value :: Color3)
			end)

			return row { label = entry.name, content = color { value = value, on_change = on_change } }
		end

		if kind == "vector3" then
			const value = vide.source(entry.value :: Vector3)

			bind(path, function(next_value)
				value(next_value :: Vector3)
			end)

			return row { label = entry.name, content = vector3 { value = value, on_change = on_change } }
		end

		const value = vide.source(entry.value :: string)

		bind(path, function(next_value)
			value(next_value :: string)
		end)

		if kind == "choice" then
			return row {
				label = entry.name,
				content = choice { value = value, on_change = on_change, choices = entry.descriptor.choices or {} },
			}
		end

		return row { label = entry.name, content = text { value = value, on_change = on_change } }
	end

	const function build_buttons(entries: { registry.button_entry })
		const items = {}

		for _, entry in entries do
			const path = entry.path

			table.insert(items, {
				text = entry.name,
				on_press = function()
					registry.press(path)
				end,
			})
		end

		return buttons { items = items }
	end

	const function build_branch(source: branch, name: string)
		const content = {}

		for _, entry in source.entries do
			table.insert(content, entry_row(entry))
		end

		if #source.buttons > 0 then table.insert(content, build_buttons(source.buttons)) end

		for _, child_name in sorted_names(source.groups) do
			table.insert(content, build_branch(source.groups[child_name], child_name))
		end

		return group { name = name, content = content }
	end

	const function tree()
		const root = collect()
		const content = {} :: { Instance }

		for _, name in sorted_names(root.groups) do
			table.insert(content, build_branch(root.groups[name], name))
		end

		return content
	end

	const frame = list {}
	local destroy_tree = nil :: (() -> ())?

	const function rebuild()
		if destroy_tree then destroy_tree() end
		table.clear(appliers)

		const destroy, content = vide.root(tree)
		destroy_tree = destroy

		for _, item in content do
			item.Parent = frame
		end
	end

	const function on_registered()
		rebuild()
	end

	const function dispose()
		if destroy_tree then destroy_tree() end
	end

	rebuild()

	vide.cleanup(registry.on_change(on_value_changed))
	vide.cleanup(registry.on_register(on_registered))
	vide.cleanup(dispose)

	return window {
		title = props.title,
		footer = props.footer,

		visible = props.visible,
		on_close = props.on_close,
		content = frame,
	}
end
