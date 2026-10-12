--// Packages
const vide = require "../../../../roblox_packages/vide"

--// Utils
const overlay = require "../../utils/overlay"
const px = require "../../utils/px"
const theme = require "../../utils/theme"

--// Constants
const BOX_SIZE = 14
const MARK_SIZE = 8

const IDLE_TRANSPARENCY = 0.6
const HOVER_TRANSPARENCY = 0.2

--// Types
type props = {
	value: () -> boolean,
	on_change: (value: boolean) -> (),
}

--// Component
return function(props: props)
	const hovered = vide.source(false)

	const function on_activated()
		props.on_change(not props.value())
	end

	const function on_enter()
		hovered(true)
	end

	const function on_leave()
		hovered(false)
	end

	const function stroke_transparency()
		if overlay.active() then return IDLE_TRANSPARENCY end
		if hovered() then return HOVER_TRANSPARENCY end
		return IDLE_TRANSPARENCY
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

		vide.create "Frame" {
			Name = "box",
			AnchorPoint = Vector2.new(1, 0.5),

			Position = UDim2.fromScale(1, 0.5),
			Size = px.udim2(0, BOX_SIZE, 0, BOX_SIZE),

			BackgroundColor3 = theme.field,
			BorderSizePixel = 0,

			vide.create "UIStroke" {
				Color = theme.stroke,
				Transparency = stroke_transparency,

				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				LineJoinMode = Enum.LineJoinMode.Miter,
				Thickness = px(1),
			},

			vide.create "Frame" {
				Name = "mark",
				AnchorPoint = Vector2.new(0.5, 0.5),

				Position = UDim2.fromScale(0.5, 0.5),
				Size = px.udim2(0, MARK_SIZE, 0, MARK_SIZE),

				BackgroundColor3 = theme.text,
				BorderSizePixel = 0,
				Visible = props.value,
			},
		},
	}
end
