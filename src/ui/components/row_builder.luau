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
const pool_key = require "../utils/pool_key"

--// Components
const buttons = require "./buttons"
const entry_control = require "./controls/entry_control"
const group_header = require "./group_header"
const new_entry = require "./new_entry"
const row = require "./row"
const tree_row = require "./tree_row"

--// Types
type current = () -> flatten.row
type active = () -> boolean
type props = { outline: outline.outline, live: live_values.live, anchors: pointer_target.anchors }

export type builder = {
	build: (current: current, active: active) -> Frame,
	pool_key: (current: flatten.row) -> string?,
}

--// Component
return function(props: props): builder
	const anchors = props.anchors

	const function build_entry(current: current, active: active)
		const function entry()
			return assert(current().entry)
		end

		const function locked()
			return locks.blocked(entry().path)
		end

		const control = entry_control {
			entry = entry,
			active = active,
			bind = props.live.bind,

			on_change = function(value: unknown)
				registry.set(entry().path, value)
			end,

			locked = locked,
		}

		const first = entry()
		const frame = row {
			label = function()
				return tostring(entry().name)
			end,

			hint = function()
				return entry().hint
			end,

			active = active,
			locked = locked,
			content = control.content,

			dirty = function()
				props.live.revision()
				return control.value() ~= entry().default
			end,

			on_reset = function()
				registry.restore(entry().path)
			end,

			on_remove = if catalog.remover(first.group, tostring(first.name))
				then function()
					const now = entry()
					const remove = catalog.remover(now.group, tostring(now.name))
					if remove then remove() end
				end
				else nil,
		}

		vide.effect(function()
			if not active() then return end

			const now = entry()
			const path = now.path

			frame:SetAttribute(pointer_target.owner_attribute, path)
			anchors.rows[path] = { frame = frame, group = now.group }

			vide.cleanup(function()
				if anchors.rows[path] and anchors.rows[path].frame == frame then anchors.rows[path] = nil end
			end)
		end)

		return tree_row { row = current, ticked = true, content = frame }
	end

	const function build_group(current: current, active: active)
		const first = current()
		const addable = registry.is_catalog(first.path)

		const function actions()
			const now = current()
			return catalog.actions(now.path, assert(now.source))
		end

		const header = group_header {
			name = function()
				return current().name
			end,

			active = active,
			expanded = function()
				return props.outline.is_expanded(current().path)
			end,

			on_toggle = function()
				props.outline.toggle(current().path)
			end,

			dirty = function()
				props.live.revision()
				return registry.dirty(current().path)
			end,

			on_reset = function()
				registry.restore_group(current().path)
			end,

			on_confirm = function()
				registry.commit(current().path)
			end,

			on_add = if addable
				then function()
					props.outline.press_add(current().path, actions())
				end
				else nil,

			adding = function()
				return props.outline.is_adding(current().path)
			end,

			on_remove = if first.depth > 0
				then function()
					const now = current()
					const parent = string.match(now.path, "^(.*)%.[^%.]+$")
					if not parent then return end

					const remove = catalog.remover(parent, now.name)
					if remove then remove() end
				end
				else nil,
		}

		return tree_row {
			row = current,
			ticked = first.depth > 0,
			content = header,

			owner = function()
				return current().path
			end,

			on_body = function(body)
				vide.effect(function()
					if not active() then return end
					const path = current().path

					anchors.groups[path] = body
					vide.cleanup(function()
						if anchors.groups[path] == body then anchors.groups[path] = nil end
					end)
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
			suggestion = actions.suggest,

			visible = function()
				return true
			end,

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

	const function build(current: current, active: active)
		const kind = current().kind

		if kind == "entry" then return build_entry(current, active) end
		if kind == "group" then return build_group(current, active) end
		if kind == "buttons" then return build_buttons(current) end

		return build_adding(current)
	end

	return { build = build, pool_key = pool_key.of_row }
end
