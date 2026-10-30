--// Packages
const vide = require "../../../roblox_packages/vide"

--// Utils
const flatten = require "../utils/flatten"
const outline = require "../utils/outline"
const pointer_target = require "../utils/pointer_target"
const px = require "../utils/px"
const share_pointer = require "../utils/share_pointer"
const theme = require "../constants/theme"

--// Components
const cursors = require "./cursors"
const virtual_list = require "./virtual_list"

--// Constants
const OVERSCAN_ROWS = 4

--// Types
type props = {
	outline: outline.outline,
	anchors: pointer_target.anchors,

	build: (current: () -> flatten.row) -> Frame,
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
		build = props.build,
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
