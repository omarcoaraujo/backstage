--// Packages
const vide = require "../../roblox_packages/vide"

--// Modules
const kinds = require "../core/kinds"
const registry = require "../core/registry"

--// Stores
const locks = require "./stores/locks"

--// Utils
const branch = require "./utils/branch"
const catalog = require "./utils/catalog"
const export_text = require "./utils/export_text"
const pointer_target = require "./utils/pointer_target"
const px = require "./utils/px"
const share_pointer = require "./utils/share_pointer"

--// Components
const buttons = require "./components/buttons"
const cursors = require "./components/cursors"
const entry_control = require "./components/controls/entry_control"
const group = require "./components/group"
const list = require "./components/list"
const notifications = require "./components/notifications"
const row = require "./components/row"
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

	const function entry_row(entry: registry.entry)
		const path = entry.path

		const function on_change(value: unknown)
			registry.set(path, value)
		end

		const control = entry_control {
			entry = entry,
			bind = bind,

			on_change = on_change,
			locked = locks.of_path(path),
		}

		const frame = row {
			label = entry.name,
			locked = locks.of_path(path),
			content = control.content,
			hint = entry.hint,

			dirty = function()
				return control.value() ~= entry.default
			end,

			on_reset = function()
				registry.restore(path)
			end,

			on_remove = catalog.remover(entry.group, tostring(entry.name)),
		}

		frame:SetAttribute(pointer_target.owner_attribute, path)
		anchors.rows[path] = { frame = frame, group = entry.group }
		return frame
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

	const function build_branch(source: branch.branch, name: string, path: string)
		const content = {}
		const parent = string.match(path, "^(.*)%.[^%.]+$")
		const actions = catalog.actions(path, source)

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

		for _, child_name in branch.sorted_names(source.groups) do
			table.insert(content, build_branch(source.groups[child_name], child_name, `{path}.{child_name}`))
		end

		const frame = group {
			name = name,
			open = opened[path],
			content = content,

			on_toggle = on_toggle,
			dirty = dirty,

			on_reset = on_reset,
			suggest = actions.suggest,

			on_add = actions.on_add,
			on_append = actions.on_append,
			on_remove = if parent then catalog.remover(parent, name) else nil,
		}

		frame:SetAttribute(pointer_target.owner_attribute, path)
		anchors.groups[path] = frame
		return frame
	end

	const function tree()
		const root = branch.collect()
		const content = {} :: { Instance }

		for _, name in branch.sorted_names(root.groups) do
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

	return vide.create "Frame" {
		Name = "backstage",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,

		window {
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
		},

		notifications(),
	}
end
