--// Packages
const vide = require "../../../roblox_packages/vide"

--// Utils
const outline = require "../utils/outline"
const pointer_target = require "../utils/pointer_target"
const px = require "../utils/px"
const share_pointer = require "../utils/share_pointer"
const theme = require "../constants/theme"

--// Components
const cursors = require "./cursors"
const row_builder = require "./row_builder"
const virtual_list = require "./virtual_list"

--// Constants
const OVERSCAN_ROWS = 4

--// Types
type props = {
	outline: outline.outline,
	anchors: pointer_target.anchors,

	builder: row_builder.builder,
	on_list: (handle: virtual_list.handle) -> (),

	cursors: boolean?,
	visible: () -> boolean,
}

--// Component
return function(props: props)
	const function overscan()
		return px(theme.row_height)() * OVERSCAN_ROWS
	end

	const scroller = virtual_list {
		rows = props.outline.rows,
		layout = props.outline.layout,

		key = props.outline.key,
		build = props.builder.build,

		pool_key = props.builder.pool_key,
		overscan = overscan,
	}

	props.on_list(scroller)

	const layers = { scroller.frame }
	const overlay = if props.cursors then cursors { anchors = props.anchors } else nil

	if overlay then table.insert(layers, overlay) end
	const frame = vide.create "Frame" {
		Name = "viewport",
		Size = UDim2.fromScale(1, 1),

		BackgroundTransparency = 1,
		layers,
	}

	if props.cursors then vide.cleanup(share_pointer(props.anchors, frame, props.visible)) end
	return frame
end
