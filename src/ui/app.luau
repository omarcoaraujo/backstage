--// Packages
const vide = require "../../roblox_packages/vide"

--// Modules
const exporter = require "../core/export"
const kinds = require "../core/kinds"
const registry = require "../core/registry"

--// Stores
const locks = require "./stores/locks"

--// Utils
const pointer_target = require "./utils/pointer_target"
const px = require "./utils/px"
const share_pointer = require "./utils/share_pointer"

--// Components
const buttons = require "./components/buttons"
const choice = require "./components/controls/choice"
const color = require "./components/controls/color"
const cursors = require "./components/cursors"
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
	cursors: boolean?,

	position: Vector2?,
	size: Vector2?,
	on_geometry: ((position: Vector2, size: Vector2) -> ())?,
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
	const opened = {} :: { [string]: boolean }
	const anchors = { rows = {}, groups = {} } :: pointer_target.anchors

	const frame = list {}
	const revision = vide.source(0)

	local destroy_tree = nil :: (() -> ())?
	local items = {} :: { Instance }

	const function bind(path: string, apply: (value: kinds.value) -> ())
		appliers[path] = apply
	end

	const function on_value_changed(path: string, value: kinds.value)
		revision(revision() + 1)
		const apply = appliers[path]
		if apply then apply(value) end
	end

	const function any_dirty()
		revision()
		return registry.dirty()
	end

	const function restore_all()
		registry.restore_group()
	end

	const function export_text()
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

	const function restorable(entry: registry.entry, value: () -> unknown, content: unknown)
		const frame = row {
			label = entry.name,
			locked = locks.of_path(entry.path),
			content = content,
			hint = entry.hint,

			dirty = function()
				return value() ~= entry.default
			end,

			on_reset = function()
				registry.restore(entry.path)
			end,
		}

		frame:SetAttribute(pointer_target.owner_attribute, entry.path)
		anchors.rows[entry.path] = { frame = frame, group = entry.group }
		return frame
	end

	const function entry_row(entry: registry.entry)
		const path = entry.path
		const kind = entry.descriptor.kind

		const text_value = vide.source(entry.value :: string)
		const locked = locks.of_path(path)

		const function on_change(value: unknown)
			registry.set(path, value)
		end

		if kind == "number" then
			const value = vide.source(entry.value :: number)

			bind(path, function(next_value)
				value(next_value :: number)
			end)

			return restorable(
				entry,
				value,
				number {
					value = value,
					on_change = on_change,
					locked = locked,

					min = entry.descriptor.min,
					max = entry.descriptor.max,

					step = entry.descriptor.step,
					decimals = kinds.decimals(entry.descriptor),
				}
			)
		end

		if kind == "boolean" then
			const value = vide.source(entry.value :: boolean)

			bind(path, function(next_value)
				value(next_value :: boolean)
			end)

			return restorable(entry, value, toggle { value = value, on_change = on_change, locked = locked })
		end

		if kind == "color" then
			const value = vide.source(entry.value :: Color3)

			bind(path, function(next_value)
				value(next_value :: Color3)
			end)

			return restorable(entry, value, color { value = value, on_change = on_change, locked = locked })
		end

		if kind == "vector3" then
			const value = vide.source(entry.value :: Vector3)

			bind(path, function(next_value)
				value(next_value :: Vector3)
			end)

			return restorable(entry, value, vector3 { value = value, on_change = on_change, locked = locked })
		end

		bind(path, function(next_value)
			text_value(next_value :: string)
		end)

		if kind == "choice" then
			return restorable(
				entry,
				text_value,
				choice {
					value = text_value,
					on_change = on_change,

					choices = entry.descriptor.choices or {},
					locked = locked,
				}
			)
		end

		return restorable(entry, text_value, text { value = text_value, on_change = on_change, locked = locked })
	end

	const function build_buttons(entries: { registry.button_entry })
		const items = {}

		for _, entry in entries do
			const path = entry.path

			table.insert(items, {
				text = entry.name,
				hint = entry.hint,

				on_press = function()
					registry.press(path)
				end,
			})
		end

		return buttons { items = items }
	end

	const function build_branch(source: branch, name: string, path: string)
		const content = {}

		const function dirty()
			revision()
			return registry.dirty(path)
		end

		const function on_reset()
			registry.restore_group(path)
		end

		const function on_toggle(open: boolean)
			opened[path] = open
		end

		for _, entry in source.entries do
			table.insert(content, entry_row(entry))
		end

		if #source.buttons > 0 then table.insert(content, build_buttons(source.buttons)) end

		for _, child_name in sorted_names(source.groups) do
			table.insert(content, build_branch(source.groups[child_name], child_name, `{path}.{child_name}`))
		end

		const frame = group {
			name = name,
			open = opened[path],
			content = content,

			on_toggle = on_toggle,
			dirty = dirty,
			on_reset = on_reset,
		}

		frame:SetAttribute(pointer_target.owner_attribute, path)
		anchors.groups[path] = frame
		return frame
	end

	const function tree()
		const root = collect()
		const content = {} :: { Instance }

		for _, name in sorted_names(root.groups) do
			table.insert(content, build_branch(root.groups[name], name, name))
		end

		return content
	end

	const function clear()
		if destroy_tree then destroy_tree() end

		for _, item in items do
			item:Destroy()
		end

		table.clear(items)
	end

	const function rebuild()
		revision(revision() + 1)
		clear()

		table.clear(appliers)
		table.clear(anchors.rows)

		table.clear(anchors.groups)
		const destroy, content = vide.root(tree)

		destroy_tree = destroy
		items = content

		for _, item in content do
			item.Parent = frame
		end
	end

	vide.cleanup(registry.on_change(on_value_changed))
	vide.cleanup(registry.on_register(rebuild))
	vide.cleanup(clear)

	rebuild()

	const viewport = vide.create "Frame" {
		Name = "viewport",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,

		frame,
		if props.cursors then cursors { anchors = anchors } else nil,
	}

	if props.cursors then vide.cleanup(share_pointer(anchors, viewport, props.visible)) end
	return window {
		title = props.title,
		footer = props.footer,

		visible = props.visible,
		on_close = props.on_close,

		position = props.position,
		size = props.size,

		on_geometry = props.on_geometry,
		content = viewport,

		dirty = any_dirty,
		on_reset = restore_all,
		export_text = export_text,
	}
end
