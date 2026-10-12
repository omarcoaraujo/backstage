--// Packages
const vide = require "../../../../../roblox_packages/vide"

--// Utils
const pointer = require "../../../utils/pointer"
const px = require "../../../utils/px"
const theme = require "../../../utils/theme"

--// Components
const surface = require "./surface"

--// Constants
const LAYER_Z_INDEX = 100000
const STROKE_TRANSPARENCY = 0.4

const PANEL_WIDTH = 160
const PANEL_PADDING = 6
const FIELD_HEIGHT = 100

const HUE_HEIGHT = 12
const CURSOR_SIZE = 8

const MARKER_WIDTH = 4
const HUE_STOPS = 6

--// Types
type props = {
	layer: Instance,
	value: Color3,

	position: Vector2,
	on_change: (value: Color3) -> (),
	on_dismiss: () -> (),
}

--// Functions
const function panel_height(): number
	return PANEL_PADDING * 2 + FIELD_HEIGHT + theme.gap + HUE_HEIGHT
end

const function hue_sequence(): ColorSequence
	const keypoints = {}

	for stop = 0, HUE_STOPS do
		table.insert(keypoints, ColorSequenceKeypoint.new(stop / HUE_STOPS, Color3.fromHSV(stop / HUE_STOPS, 1, 1)))
	end

	return ColorSequence.new(keypoints)
end

--// Component
const function component(props: props)
	const hue, saturation, brightness = props.value:ToHSV()
	const hue_source = vide.source(hue)

	const saturation_source = vide.source(saturation)
	const brightness_source = vide.source(brightness)

	local pressed = false
	local panel = nil :: Frame?

	const function emit()
		props.on_change(Color3.fromHSV(hue_source(), saturation_source(), brightness_source()))
	end

	const function on_field_drag(x: number, y: number)
		saturation_source(x)
		brightness_source(1 - y)
		emit()
	end

	const function on_hue_drag(x: number)
		hue_source(x)
		emit()
	end

	const function inside_panel(input: InputObject): boolean
		if not panel then return false end
		const offset = Vector2.new(input.Position.X, input.Position.Y) - panel.AbsolutePosition
		return offset.X >= 0 and offset.Y >= 0 and offset.X <= panel.AbsoluteSize.X and offset.Y <= panel.AbsoluteSize.Y
	end

	const function on_backdrop_press(input: InputObject)
		if not pointer.is_press(input) then return end
		pressed = not inside_panel(input)
	end

	const function on_backdrop_release(input: InputObject)
		if not pressed or not pointer.is_press(input) then return end
		pressed = false
		props.on_dismiss()
	end

	const function field_gradient()
		return ColorSequence.new(Color3.new(1, 1, 1), Color3.fromHSV(hue_source(), 1, 1))
	end

	const function cursor_position()
		return UDim2.fromScale(saturation_source(), 1 - brightness_source())
	end

	const function marker_position()
		return UDim2.fromScale(hue_source(), 0.5)
	end

	const function panel_position()
		return UDim2.fromOffset(props.position.X, props.position.Y)
	end

	return vide.create "Frame" {
		Name = "backstage_color_picker",
		Parent = props.layer,
		Size = UDim2.fromScale(1, 1),

		BackgroundTransparency = 1,
		Active = true,
		ZIndex = LAYER_Z_INDEX,

		InputBegan = on_backdrop_press,
		InputEnded = on_backdrop_release,

		vide.create "Frame" {
			Name = "panel",
			Position = panel_position,
			Size = px.udim2(0, PANEL_WIDTH, 0, panel_height()),

			BackgroundColor3 = theme.field,
			BorderSizePixel = 0,
			Active = true,

			vide.action(function(instance)
				panel = instance :: Frame
			end),

			vide.create "UIStroke" {
				Color = theme.stroke,
				Transparency = STROKE_TRANSPARENCY,

				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				LineJoinMode = Enum.LineJoinMode.Miter,
				Thickness = px(1),
			},

			vide.create "UIPadding" {
				PaddingLeft = px.udim(0, PANEL_PADDING),
				PaddingRight = px.udim(0, PANEL_PADDING),

				PaddingTop = px.udim(0, PANEL_PADDING),
				PaddingBottom = px.udim(0, PANEL_PADDING),
			},

			vide.create "UIListLayout" {
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = px.udim(0, theme.gap),
			},

			surface {
				name = "field",
				size = px.udim2(1, 0, 0, FIELD_HEIGHT),
				on_drag = on_field_drag,

				vide.create "UIGradient" {
					Color = field_gradient,
				},

				vide.create "Frame" {
					Name = "shade",
					Size = UDim2.fromScale(1, 1),

					BackgroundColor3 = Color3.new(0, 0, 0),
					BorderSizePixel = 0,

					vide.create "UIGradient" {
						Rotation = 90,
						Transparency = NumberSequence.new(1, 0),
					},
				},

				vide.create "Frame" {
					Name = "cursor",
					AnchorPoint = Vector2.new(0.5, 0.5),

					Position = cursor_position,
					Size = px.udim2(0, CURSOR_SIZE, 0, CURSOR_SIZE),

					BackgroundTransparency = 1,
					BorderSizePixel = 0,

					vide.create "UIStroke" {
						Color = theme.stroke,
						Transparency = 0,

						ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
						LineJoinMode = Enum.LineJoinMode.Miter,
						Thickness = px(1),
					},
				},
			},

			surface {
				name = "hue",
				size = px.udim2(1, 0, 0, HUE_HEIGHT),
				on_drag = on_hue_drag,

				vide.create "UIGradient" {
					Color = hue_sequence(),
				},

				vide.create "Frame" {
					Name = "marker",
					AnchorPoint = Vector2.new(0.5, 0.5),

					Position = marker_position,
					Size = px.udim2(0, MARKER_WIDTH, 1, 0),

					BackgroundTransparency = 1,
					BorderSizePixel = 0,

					vide.create "UIStroke" {
						Color = theme.stroke,
						Transparency = 0,

						ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
						LineJoinMode = Enum.LineJoinMode.Miter,
						Thickness = px(1),
					},
				},
			},
		},
	}
end

--// End
return table.freeze {
	component = component,
	height = panel_height,
	width = PANEL_WIDTH,
}
