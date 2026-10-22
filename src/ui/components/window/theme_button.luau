--// Packages
const vide = require "../../../../roblox_packages/vide"

--// Stores
const appearance = require "../../stores/appearance"

--// Utils
const overlay = require "../../utils/overlay"
const px = require "../../utils/px"
const theme = require "../../constants/theme"

--// Constants
const ICON_SIZE = 12

--// Types
type props = {
	right: number,
}

--// Component
return function(props: props)
	const hovered = vide.source(false)

	const function on_enter()
		hovered(true)
	end

	const function on_leave()
		hovered(false)
	end

	const function background_transparency()
		if overlay.active() then return 1 end
		if hovered() then return 0 end
		return 1
	end

	const function icon_color()
		if hovered() and not overlay.active() then return appearance.text() end
		return appearance.text_muted()
	end

	const function rotation()
		return if appearance.light() then 180 else 0
	end

	return vide.create "TextButton" {
		Name = "theme",
		AnchorPoint = Vector2.new(1, 0),

		Position = px.udim2(1, -props.right, 0, theme.title_inset),
		Size = px.udim2(0, theme.title_button, 0, theme.title_button),

		AutoButtonColor = false,
		Active = true,

		BackgroundColor3 = appearance.hover,
		BackgroundTransparency = background_transparency,
		BorderSizePixel = 0,
		Text = "",

		Activated = overlay.guard(appearance.toggle),
		MouseEnter = on_enter,
		MouseLeave = on_leave,

		vide.create "UICorner" {
			CornerRadius = px.udim(0, theme.radius),
		},

		vide.create "Frame" {
			Name = "icon",
			AnchorPoint = Vector2.new(0.5, 0.5),

			Position = UDim2.fromScale(0.5, 0.5),
			Size = px.udim2(0, ICON_SIZE, 0, ICON_SIZE),

			BackgroundColor3 = icon_color,
			BorderSizePixel = 0,
			Rotation = rotation,

			vide.create "UICorner" {
				CornerRadius = UDim.new(1, 0),
			},

			vide.create "UIGradient" {
				Transparency = NumberSequence.new {
					NumberSequenceKeypoint.new(0, 1),
					NumberSequenceKeypoint.new(0.499, 1),
					NumberSequenceKeypoint.new(0.5, 0),
					NumberSequenceKeypoint.new(1, 0),
				},
				Rotation = 90,
			},

			vide.create "UIStroke" {
				Color = icon_color,

				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				LineJoinMode = Enum.LineJoinMode.Round,
				Thickness = px(1),
			},
		},
	}
end
