--// Services
const UserInputService = game:GetService "UserInputService"

--// Packages
const vide = require "../../../roblox_packages/vide"

--// Stores
const appearance = require "../stores/appearance"

--// Utils
const flatten = require "../utils/flatten"
const pointer_target = require "../utils/pointer_target"
const px = require "../utils/px"
const viewport = require "../utils/viewport"

--// Constants
const SCROLLBAR_THICKNESS = 4
const UNMEASURED_EXTENT = 800
const POOL_LIMIT = 64

--// Types
type mounted = {
	frame: Frame,
	destroy: () -> (),

	source: vide.Source<flatten.row>,
	parked: vide.Source<boolean>,

	path: string,
	index: number,
	pool_key: string?,
}

type held = {
	path: string,
	offset: number,
}

type props = {
	rows: () -> { flatten.row },
	layout: () -> viewport.layout,

	key: (row: flatten.row) -> string,
	build: (row: () -> flatten.row, active: () -> boolean) -> Frame,

	pool_key: (row: flatten.row) -> string?,
	overscan: () -> number,
}

export type geometry = {
	position: Vector2,
	width: number,
}

export type handle = {
	frame: Instance,
	hold: (path: string) -> (),
	geometry: () -> geometry?,
}

--// Functions
const function focused_inside(frame: Frame): boolean
	const box = UserInputService:GetFocusedTextBox()
	return box ~= nil and box:IsDescendantOf(frame)
end

const function index_of(rows: { flatten.row }, path: string): number?
	for index, row in rows do
		if row.path == path then return index end
	end

	return nil
end

--// Component
return function(props: props): handle
	const mounted = {} :: { [string]: mounted }
	const pool = {} :: { [string]: { mounted } }
	const parked_order = {} :: { mounted }

	local placed = nil :: viewport.layout?
	local held = nil :: held?

	const canvas_position = vide.source(Vector2.zero)
	const absolute_size = vide.source(Vector2.zero)

	const frame = vide.create "ScrollingFrame" {
		Name = "list",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,

		CanvasSize = UDim2.fromScale(0, 0),
		ScrollingDirection = Enum.ScrollingDirection.Y,

		ScrollBarImageColor3 = appearance.divider,
		ScrollBarThickness = px(SCROLLBAR_THICKNESS),
		VerticalScrollBarInset = Enum.ScrollBarInset.None,

		vide.changed("CanvasPosition", canvas_position),
		vide.changed("AbsoluteSize", absolute_size),
	} :: ScrollingFrame

	const function extent()
		const measured = absolute_size().Y
		return if measured > 0 then measured else UNMEASURED_EXTENT
	end

	const function place(current: mounted, layout: viewport.layout)
		current.frame.Position = UDim2.fromOffset(0, layout.tops[current.index])
		current.frame.Size = UDim2.new(1, 0, 0, layout.heights[current.index])
	end

	const function destroy_mounted(current: mounted)
		current.destroy()
		current.frame:Destroy()
	end

	const function unpool(current: mounted)
		const bucket = assert(pool[current.pool_key :: string])
		table.remove(bucket, table.find(bucket, current))
		table.remove(parked_order, table.find(parked_order, current))
	end

	const function park(current: mounted)
		const pool_key = current.pool_key :: string

		if #parked_order >= POOL_LIMIT then
			const oldest = parked_order[1]
			unpool(oldest)
			destroy_mounted(oldest)
		end

		current.parked(true)
		current.frame.Parent = nil

		pool[pool_key] = pool[pool_key] or {}
		table.insert(pool[pool_key], current)
		table.insert(parked_order, current)
	end

	const function release(key: string)
		const current = mounted[key]
		if not current then return end

		mounted[key] = nil
		if current.pool_key then
			park(current)
			return
		end

		destroy_mounted(current)
	end

	const function reuse(row: flatten.row, pool_key: string): mounted?
		const bucket = pool[pool_key]
		if not bucket or #bucket == 0 then return nil end

		const current = bucket[#bucket]
		unpool(current)

		vide.batch(function()
			current.source(row)
			current.parked(false)
		end)

		current.path = row.path
		return current
	end

	const function build_new(row: flatten.row, pool_key: string?): mounted
		const source = vide.source(row)
		const parked = vide.source(false)

		const function active()
			return not parked()
		end

		const destroy, built = vide.root(function()
			return vide.untrack(function()
				return props.build(source, active)
			end)
		end)

		return {
			frame = built,
			path = row.path,

			destroy = destroy,
			source = source,
			parked = parked,

			index = 0,
			pool_key = pool_key,
		}
	end

	const function mount(row: flatten.row, key: string, index: number, layout: viewport.layout)
		const pool_key = props.pool_key(row)
		const current = (pool_key and reuse(row, pool_key)) or build_new(row, pool_key)

		current.index = index
		current.frame.Parent = frame

		mounted[key] = current
		place(current, layout)
	end

	const function keep_pinned(key: string, current: mounted, rows: { flatten.row })
		const index = if focused_inside(current.frame) then index_of(rows, current.path) else nil

		if not index then
			release(key)
			return
		end

		current.index = index
		current.source(rows[index])
	end

	const function restore_hold(rows: { flatten.row }, layout: viewport.layout): number?
		const anchor = held
		if not anchor then return nil end

		held = nil
		const index = index_of(rows, anchor.path)
		if not index then return nil end

		frame.CanvasPosition = Vector2.new(0, math.max(layout.tops[index] - anchor.offset, 0))
		return frame.CanvasPosition.Y
	end

	const function reconcile()
		const rows = props.rows()
		const layout = props.layout()
		const changed_layout = layout ~= placed

		local top = canvas_position().Y
		const size = extent()

		if changed_layout then
			frame.CanvasSize = UDim2.fromOffset(0, layout.total)
			top = restore_hold(rows, layout) or top
		end

		const range = viewport.visible(layout, top, size, props.overscan())
		const wanted = {} :: { [string]: number }

		for index = range.first, range.last do
			wanted[props.key(rows[index])] = index
		end

		for key, current in table.clone(mounted) do
			if wanted[key] then continue end
			keep_pinned(key, current, rows)
		end

		for key, index in wanted do
			const current = mounted[key]

			if current then
				current.index = index
				current.source(rows[index])
				continue
			end

			mount(rows[index], key, index, layout)
		end

		if not changed_layout then return end
		placed = layout

		for _, current in mounted do
			place(current, layout)
		end
	end

	const function hold(path: string)
		const rows = vide.untrack(props.rows)
		const layout = vide.untrack(props.layout)
		const index = index_of(rows, path)

		if not index then return end
		held = { path = path, offset = layout.tops[index] - frame.CanvasPosition.Y }
	end

	const function geometry(): geometry?
		if not pointer_target.visible(frame) then return nil end
		return { position = frame.AbsolutePosition - frame.CanvasPosition, width = frame.AbsoluteSize.X }
	end

	vide.effect(reconcile)
	vide.cleanup(function()
		for key, current in table.clone(mounted) do
			mounted[key] = nil
			destroy_mounted(current)
		end

		for _, current in parked_order do
			destroy_mounted(current)
		end
	end)

	return {
		frame = frame,
		hold = hold,
		geometry = geometry,
	}
end
