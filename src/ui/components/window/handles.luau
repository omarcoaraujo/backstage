--// Services
const RunService = game:GetService "RunService"

--// Packages
const vide = require "../../../../roblox_packages/vide"

--// Stores
const appearance = require "../../stores/appearance"

--// Utils
const overlay = require "../../utils/overlay"
const px = require "../../utils/px"

--// Constants
const EDGE_HIT = 5
const CORNER_HIT = 10
const LINE_THICKNESS = 2

const EDGE_Z_INDEX = 3
const CORNER_Z_INDEX = 4
const LINE_Z_INDEX = 5

const BRIGHT_TRANSPARENCY = 0.05
const DIM_TRANSPARENCY = 0.75
const BLINK_SPEED = 9

const SIDES = {
	{ horizontal = -1, vertical = 0 },
	{ horizontal = 1, vertical = 0 },
	{ horizontal = 0, vertical = 1 },
	{ horizontal = -1, vertical = 1 },
	{ horizontal = 1, vertical = 1 },
} :: { side }

--// Types
export type side = { horizontal: number, vertical: number }
type props = {
	dragging: () -> side?,
	on_press: (side: side, input: InputObject) -> (),
	on_release: (input: InputObject) -> (),
}

--// Functions
const function anchor_of(side: side): Vector2
	return Vector2.new(if side.horizontal == -1 then 1 else 0, if side.vertical == -1 then 1 else 0)
end

const function position_of(side: side): UDim2
	return UDim2.fromScale(if side.horizontal == 1 then 1 else 0, if side.vertical == 1 then 1 else 0)
end

const function touches(active: side, edge: side): boolean
	if edge.horizontal ~= 0 then return active.horizontal == edge.horizontal end
	return active.vertical == edge.vertical
end

const function hit_size_of(side: side)
	const hit = if side.horizontal ~= 0 and side.vertical ~= 0 then CORNER_HIT else EDGE_HIT

	return function()
		const width = if side.horizontal == 0 then UDim.new(1, 0) else UDim.new(0, px(hit)())
		const height = if side.vertical == 0 then UDim.new(1, 0) else UDim.new(0, px(hit)())
		return UDim2.new(width, height)
	end
end

const function line_size_of(edge: side)
	return function()
		const thickness = px(LINE_THICKNESS)()
		if edge.horizontal ~= 0 then return UDim2.new(0, thickness, 1, 0) end
		return UDim2.new(1, 0, 0, thickness)
	end
end

--// Components
const function hit(side: side, hovered: vide.Source<side?>, props: props)
	const function on_press(input: InputObject)
		if overlay.active() then return end
		props.on_press(side, input)
	end

	const function on_enter()
		hovered(side)
	end

	const function on_leave()
		if hovered() == side then hovered(nil) end
	end

	return vide.create "Frame" {
		Name = "hit",
		AnchorPoint = anchor_of(side),
		Position = position_of(side),

		Size = hit_size_of(side),
		BackgroundTransparency = 1,
		Active = true,
		ZIndex = if side.horizontal ~= 0 and side.vertical ~= 0 then CORNER_Z_INDEX else EDGE_Z_INDEX,

		InputBegan = on_press,
		InputEnded = props.on_release,

		MouseEnter = on_enter,
		MouseLeave = on_leave,
	}
end

const function line(edge: side, current: () -> side?)
	const phase = vide.source(0)

	const function is_active()
		const active = current()
		return active ~= nil and touches(active, edge)
	end

	const function transparency()
		if not is_active() then return 1 end
		return math.lerp(BRIGHT_TRANSPARENCY, DIM_TRANSPARENCY, phase())
	end

	vide.effect(function()
		if not is_active() then return end
		const started = os.clock()

		const function on_step()
			phase(0.5 - 0.5 * math.cos((os.clock() - started) * BLINK_SPEED))
		end

		vide.cleanup(RunService.Heartbeat:Connect(on_step))
	end)

	return vide.create "Frame" {
		Name = "line",
		AnchorPoint = anchor_of(edge),
		Position = position_of(edge),

		Size = line_size_of(edge),
		BackgroundColor3 = appearance.accent,

		BackgroundTransparency = transparency,
		BorderSizePixel = 0,
		ZIndex = LINE_Z_INDEX,
	}
end

--// Component
return function(props: props)
	const children = {} :: { unknown }
	const hovered = vide.source(nil :: side?)

	const function current(): side?
		if overlay.active() then return props.dragging() end
		return props.dragging() or hovered()
	end

	for _, side in SIDES do
		table.insert(children, hit(side, hovered, props))
		if side.horizontal == 0 or side.vertical == 0 then table.insert(children, line(side, current)) end
	end

	return children
end
