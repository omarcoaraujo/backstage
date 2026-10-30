--// Packages
const vide = require "../../../roblox_packages/vide"

--// Stores
const locks = require "../stores/locks"

--// Modules
const registry = require "../../core/registry"

--// Utils
const catalog = require "../utils/catalog"
const flatten = require "../utils/flatten"
const live_values = require "../utils/live_values"
const outline = require "../utils/outline"
const pointer_target = require "../utils/pointer_target"

--// Components
const buttons = require "./buttons"
const entry_control = require "./controls/entry_control"
const group_header = require "./group_header"
const new_entry = require "./new_entry"
const row = require "./row"
const tree_row = require "./tree_row"

--// Types
type current = () -> flatten.row
type props = { outline: outline.outline, live: live_values.live, anchors: pointer_target.anchors }

--// Component
return function(props: props): (current: current) -> Frame
	const anchors = props.anchors

	const function build_entry(current: current)
		const entry = assert(current().entry)
		const path = entry.path

		const function on_change(value: unknown)
			registry.set(path, value)
		end

		const control = entry_control {
			entry = entry,
			bind = props.live.bind,

			on_change = on_change,
			locked = locks.of_path(path),
		}

		const frame = row {
			label = entry.name,
			hint = entry.hint,

			locked = locks.of_path(path),
			content = control.content,

			dirty = function()
				props.live.revision()
				return control.value() ~= entry.default
			end,

			on_reset = function()
				registry.restore(path)
			end,

			on_remove = catalog.remover(entry.group, tostring(entry.name)),
		}

		frame:SetAttribute(pointer_target.owner_attribute, path)
		anchors.rows[path] = { frame = frame, group = entry.group }

		vide.cleanup(function()
			if anchors.rows[path] and anchors.rows[path].frame == frame then anchors.rows[path] = nil end
		end)

		return tree_row { row = current, ticked = true, content = frame }
	end

	const function build_group(current: current)
		const first = current()
		const path = first.path
		const name = first.name

		const parent = string.match(path, "^(.*)%.[^%.]+$")
		const actions = catalog.actions(path, assert(first.source))
		const addable = actions.on_add ~= nil or actions.on_append ~= nil

		const header = group_header {
			name = name,
			expanded = function()
				return props.outline.is_expanded(path)
			end,

			on_toggle = function()
				props.outline.toggle(path)
			end,

			dirty = function()
				props.live.revision()
				return registry.dirty(path)
			end,

			on_reset = function()
				registry.restore_group(path)
			end,

			on_confirm = function()
				registry.commit(path)
			end,

			on_add = if addable
				then function()
					props.outline.press_add(path, actions)
				end
				else nil,

			adding = function()
				return props.outline.is_adding(path)
			end,

			on_remove = if parent then catalog.remover(parent, name) else nil,
		}

		return tree_row {
			row = current,
			ticked = first.depth > 0,

			owner = path,
			content = header,

			on_body = function(body)
				anchors.groups[path] = body

				vide.cleanup(function()
					if anchors.groups[path] == body then anchors.groups[path] = nil end
				end)
			end,
		}
	end

	const function build_buttons(current: current)
		const first = current()
		const items = {}

		for _, entry in assert(first.buttons) do
			const path = entry.path

			table.insert(items, {
				text = entry.name,
				hint = entry.hint,

				on_press = function()
					registry.press(path)
				end,
			})
		end

		const content = buttons {
			items = items,
			on_height = function(height)
				props.outline.report_height(first.path, height)
			end,
		}

		return tree_row { row = current, ticked = false, content = content }
	end

	const function build_adding(current: current)
		const first = current()
		const path = first.path
		const actions = catalog.actions(path, assert(first.source))

		const panel = new_entry {
			visible = function()
				return true
			end,

			suggestion = actions.suggest,
			on_add = function(key)
				if not actions.on_add then return false end
				return actions.on_add(key)
			end,

			on_close = function()
				props.outline.close_adding(path)
			end,
		}

		return tree_row { row = current, ticked = false, content = panel }
	end

	return function(current: current)
		const kind = current().kind

		if kind == "entry" then return build_entry(current) end
		if kind == "group" then return build_group(current) end
		if kind == "buttons" then return build_buttons(current) end

		return build_adding(current)
	end
end
