--// Packages
const vide = require "../../../roblox_packages/vide"

--// Utils
const overlay = require "../utils/overlay"
const px = require "../utils/px"
const theme = require "../utils/theme"

--// Constants
const ICON_SIZE = 12
const ICON = "rbxasset://textures/StudioSharedUI/Undo.png"

--// Types
type props = {
	right: number,
	visible: () -> boolean,
	on_reset: () -> (),
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

	const function on_activated()
		hovered(false)
		props.on_reset()
	end

	const function color()
		if hovered() and not overlay.active() then return theme.text end
		return theme.text_muted
	end

	return vide.create "TextButton" {
		Name = "reset",
		AnchorPoint = Vector2.new(1, 0),

		Position = px.udim2(1, -props.right, 0, 0),
		Size = px.udim2(0, theme.reset_width, 1, 0),

		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Active = true,

		Text = "",
		Visible = props.visible,

		Activated = overlay.guard(on_activated),
		MouseEnter = on_enter,
		MouseLeave = on_leave,

		vide.create "ImageLabel" {
			Name = "icon",
			AnchorPoint = Vector2.new(0.5, 0.5),

			Position = UDim2.fromScale(0.5, 0.5),
			Size = px.udim2(0, ICON_SIZE, 1, 0),

			BackgroundTransparency = 1,
			Image = ICON,
			ImageColor3 = color,

			vide.create "UIAspectRatioConstraint" {
				AspectRatio = 1,
				DominantAxis = Enum.DominantAxis.Width,
			},
		},
	}
end
