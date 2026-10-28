--// Services
const UserInputService = game:GetService "UserInputService"

--// Packages
const vide = require "../../../roblox_packages/vide"

--// Stores
const appearance = require "../stores/appearance"

--// Utils
const pointer = require "../utils/pointer"
const px = require "../utils/px"
const resize_rect = require "../utils/resize_rect"
const theme = require "../constants/theme"

--// Components
const export_panel = require "@self/export_panel"
const footer = require "@self/footer"
const handles = require "@self/handles"
const search = require "@self/search"
const title_bar = require "@self/title_bar"

--// Constants
const DEFAULT_SIZE = Vector2.new(365, 480)
const DEFAULT_MIN_SIZE = Vector2.new(365, 160)

const KEEP_VISIBLE = 48
const CAPTURE_SPAN = 20000
const CAPTURE_Z_INDEX = 100000

--// Types
type drag = {
	kind: "move" | "resize",
	side: handles.side?,
	origin: Vector2,

	position: Vector2,
	size: Vector2,
}

type props = {
	title: string,
	on_close: () -> (),
	visible: (() -> boolean)?,

	position: Vector2?,
	size: Vector2?,
	on_geometry: ((position: Vector2, size: Vector2) -> ())?,

	min_size: Vector2?,
	footer: string?,
	content: unknown?,

	dirty: (() -> boolean)?,
	on_reset: (() -> ())?,

	on_confirm: (() -> ())?,
	export_text: (() -> string)?,
}

--// Functions
const function clamp_position(position: Vector2, size: Vector2, bounds: Vector2): Vector2
	const x = math.clamp(position.X, KEEP_VISIBLE - size.X, bounds.X - KEEP_VISIBLE)
	const y = math.clamp(position.Y, 0, bounds.Y - px(theme.title_height)())
	return Vector2.new(x, y)
end

const function fit_position(position: Vector2, size: Vector2, bounds: Vector2): Vector2
	const x = math.clamp(position.X, 0, math.max(bounds.X - size.X, 0))
	const y = math.clamp(position.Y, 0, math.max(bounds.Y - size.Y, 0))
	return Vector2.new(x, y)
end

--// Component
return function(props: props)
	local root = nil :: Frame?
	local watching = nil :: RBXScriptConnection?

	const min_size = props.min_size or DEFAULT_MIN_SIZE * px.scale()
	const footer_height = if props.footer then theme.footer_height else 0

	const position = vide.source(props.position)
	const size = vide.source(props.size or DEFAULT_SIZE * px.scale())
	const drag = vide.source(nil :: drag?)

	const exporting = vide.source(false)
	const exported = vide.source ""

	const function bounds()
		const parent = if root then root.Parent :: GuiBase2d? else nil
		return if parent then parent.AbsoluteSize else Vector2.new(math.huge, math.huge)
	end

	const function settled_position(): Vector2
		const placed = position()
		if placed then return placed end

		const free = bounds() - size()
		return Vector2.new(math.floor(free.X / 2), math.floor(free.Y / 2))
	end

	const function is_dragging()
		return drag() ~= nil
	end

	const function resizing(): handles.side?
		const current = drag()
		return if current and current.kind == "resize" then current.side else nil
	end

	const function root_position()
		const placed = position()
		if not placed then return UDim2.new(0.5, -size().X / 2, 0.5, -size().Y / 2) end
		return UDim2.fromOffset(placed.X, placed.Y)
	end

	const function root_size()
		return UDim2.fromOffset(size().X, size().Y)
	end

	const function keep_inside()
		const placed = position()
		if not placed then return end
		position(fit_position(placed, size(), bounds()))
	end

	const function stop_watching()
		if not watching then return end
		watching:Disconnect()
		watching = nil
	end

	const function on_parent_changed()
		stop_watching()

		const parent = if root then root.Parent :: GuiBase2d? else nil
		if not parent then return end

		watching = parent:GetPropertyChangedSignal("AbsoluteSize"):Connect(keep_inside)
		keep_inside()
	end

	const function begin_move(input: InputObject)
		if not pointer.is_press(input) then return end
		drag { kind = "move", origin = pointer.position(input), position = settled_position(), size = size() }
	end

	const function begin_resize(side: handles.side, input: InputObject)
		if not pointer.is_press(input) then return end

		drag {
			kind = "resize",
			side = side,

			origin = pointer.position(input),
			position = settled_position(),
			size = size(),
		}
	end

	const function finish()
		const finished = drag()
		drag(nil)

		const placed = position()
		if not finished or not placed or not props.on_geometry then return end
		props.on_geometry(placed, size())
	end

	const function release(input: InputObject)
		if pointer.is_press(input) then finish() end
	end

	const function follow(current: drag, delta: Vector2)
		if current.kind == "move" then
			position(clamp_position(current.position + delta, size(), bounds()))
			return
		end

		if not current.side then return end
		const next_position, next_size =
			resize_rect(current.side, delta, current.position, current.size, min_size, bounds())

		position(next_position)
		size(next_size)
	end

	const function on_capture_changed(input: InputObject)
		const current = drag()
		if not current or not pointer.is_motion(input) then return end

		if
			input.UserInputType == Enum.UserInputType.MouseMovement
			and not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
		then
			finish()
			return
		end

		follow(current, pointer.position(input) - current.origin)
	end

	const function close()
		position(props.position)
		exporting(false)
		props.on_close()
	end

	const function toggle_export()
		if exporting() then
			exporting(false)
			return
		end

		if props.export_text then exported(props.export_text()) end
		exporting(true)
	end

	root = vide.create "Frame" {
		Name = "backstage_window",
		Visible = props.visible,
		BackgroundColor3 = appearance.background,

		BorderSizePixel = 0,
		Active = true,

		Position = root_position,
		Size = root_size,

		vide.create "UICorner" {
			CornerRadius = px.udim(0, theme.radius * 2),
		},

		vide.create "UIStroke" {
			Color = appearance.stroke,
			Transparency = theme.stroke_transparency,

			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			LineJoinMode = Enum.LineJoinMode.Round,
			Thickness = px(1),
		},

		vide.create "Frame" {
			Name = "content",
			BackgroundTransparency = 1,
			ClipsDescendants = true,

			Position = px.udim2(0, 0, 0, theme.title_height + theme.search_height),
			Size = px.udim2(1, 0, 1, -theme.title_height - theme.search_height - footer_height),

			props.content,
		},

		search(),

		export_panel {
			visible = exporting,
			text = exported,
			footer_height = footer_height,
		},

		footer {
			text = props.footer or "",
			visible = props.footer ~= nil,
		},

		title_bar {
			title = props.title,
			on_press = begin_move,

			on_release = release,
			on_close = close,

			dirty = props.dirty,
			on_reset = props.on_reset,
			
			on_confirm = props.on_confirm,
			on_export = if props.export_text then toggle_export else nil,
		},

		handles {
			dragging = resizing,
			on_press = begin_resize,
			on_release = release,
		},

		vide.create "Frame" {
			Name = "capture",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(CAPTURE_SPAN, CAPTURE_SPAN),

			BackgroundTransparency = 1,
			Active = true,
			ZIndex = CAPTURE_Z_INDEX,

			Visible = is_dragging,
			InputChanged = on_capture_changed,
			InputEnded = release,
		},

		vide.changed("Parent", on_parent_changed),
	}

	vide.cleanup(stop_watching)
	return root
end
