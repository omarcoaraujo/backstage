--// Packages
const vide = require "../../roblox_packages/vide"

--// Modules
const coalesce = require "../core/coalesce"
const registry = require "../core/registry"

--// Utils
const export_text = require "./utils/export_text"
const live_values = require "./utils/live_values"
const outline = require "./utils/outline"
const pointer_anchors = require "./utils/pointer_anchors"
const px = require "./utils/px"
const search_index = require "./utils/search_index"

--// Components
const notifications = require "./components/notifications"
const outline_view = require "./components/outline_view"
const row_builder = require "./components/row_builder"
const virtual_list = require "./components/virtual_list"
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

	local list = nil :: virtual_list.handle?

	const function hold(path: string)
		if list then list.hold(path) end
	end

	const function geometry(): pointer_anchors.geometry?
		if not list then return nil end
		return list.geometry()
	end

	const function on_list(handle: virtual_list.handle)
		list = handle
	end

	const index = search_index.create()
	const live = live_values.create { on_change = index.update }

	const tree = outline.create { hold = hold }
	const anchors = pointer_anchors.create { rows = tree.rows, layout = tree.layout, geometry = geometry }

	const function rebuild()
		vide.batch(function()
			index.reset()
			tree.rebuild()
		end)
	end

	vide.cleanup(registry.on_register(coalesce(rebuild)))

	const content = outline_view {
		outline = tree,
		anchors = anchors,

		builder = row_builder { outline = tree, live = live, anchors = anchors },
		on_list = on_list,

		cursors = props.cursors,
		visible = props.visible,
	}

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
			content = content,

			dirty = live.dirty,
			on_reset = live.restore,

			on_confirm = live.confirm,
			export_text = export_text,
		},

		notifications(),
	}
end
