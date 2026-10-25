--// Packages
const vide = require "../../../../roblox_packages/vide"

--// Stores
const appearance = require "../../stores/appearance"

--// Utils
const activity = require "../../utils/activity"
const overlay = require "../../utils/overlay"
const px = require "../../utils/px"
const theme = require "../../constants/theme"

--// Constants
const BOX_SIZE = 14
const MARK_SIZE = 8

--// Types
type props = {
	value: () -> boolean,
	on_change: (value: boolean) -> (),
}

--// Component
return function(props: props)
	const hovered = vide.source(false)
	const pressed = vide.source(false)

	const function on_activated()
		props.on_change(not props.value())
	end

	const function on_enter()
		hovered(true)
	end

	const function on_leave()
		hovered(false)
		pressed(false)
	end

	const function on_down()
		if overlay.active() then return end
		pressed(true)
	end

	const function on_up()
		pressed(false)
	end

	const function stroke_color()
		if props.value() then return appearance.accent() end
		return appearance.stroke()
	end

	const function stroke_transparency()
		if props.value() then return theme.stroke_focus_transparency end
		if overlay.active() then return theme.stroke_transparency end
		if hovered() then return theme.stroke_hover_transparency end

		return theme.stroke_transparency
	end

	return vide.create "TextButton" {
		Name = "toggle",
		Size = UDim2.fromScale(1, 1),

		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "",

		Activated = overlay.guard(on_activated),
		MouseEnter = on_enter,
		MouseLeave = on_leave,

		MouseButton1Down = on_down,
		MouseButton1Up = on_up,

		vide.create "Frame" {
			Name = "box",
			AnchorPoint = Vector2.new(1, 0.5),

			Position = UDim2.fromScale(1, 0.5),
			Size = px.udim2(0, BOX_SIZE, 0, BOX_SIZE),
			activity.mark(pressed),

			BackgroundColor3 = appearance.field,
			BorderSizePixel = 0,

			vide.create "UICorner" {
				CornerRadius = px.udim(0, theme.radius),
			},

			vide.create "UIStroke" {
				Color = stroke_color,
				Transparency = stroke_transparency,

				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				LineJoinMode = Enum.LineJoinMode.Round,
				Thickness = px(1),
			},

			vide.create "Frame" {
				Name = "mark",
				AnchorPoint = Vector2.new(0.5, 0.5),

				Position = UDim2.fromScale(0.5, 0.5),
				Size = px.udim2(0, MARK_SIZE, 0, MARK_SIZE),

				BackgroundColor3 = appearance.accent,
				BorderSizePixel = 0,
				Visible = props.value,

				vide.create "UICorner" {
					CornerRadius = px.udim(0, theme.radius / 2),
				},
			},
		},
	}
end
