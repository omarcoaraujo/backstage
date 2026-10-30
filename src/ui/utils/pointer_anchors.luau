--// Utils
const flatten = require "./flatten"
const pointer_target = require "./pointer_target"
const row_space = require "./row_space"
const viewport = require "./viewport"

--// Types
export type geometry = {
	position: Vector2,
	width: number,
}

export type props = {
	rows: () -> { flatten.row },
	layout: () -> viewport.layout,
	geometry: () -> geometry?,
}

--// Functions
const function create(props: props): pointer_target.anchors
	local space = nil :: row_space.space?
	local space_layout = nil :: viewport.layout?

	const function canvas(): pointer_target.canvas?
		const geometry = props.geometry()
		if not geometry then return nil end

		const current_layout = props.layout()
		if current_layout ~= space_layout then
			space = row_space.new(props.rows(), current_layout)
			space_layout = current_layout
		end

		if not space then return nil end
		return {
			space = space,
			position = geometry.position,
			width = geometry.width,
		}
	end

	return { rows = {}, groups = {}, canvas = canvas }
end

--// End
return table.freeze {
	create = create,
}
