--// Packages
const vide = require "../../../roblox_packages/vide"

--// Stores
const appearance = require "../stores/appearance"

--// Utils
const motion = require "../utils/motion"
const overlay = require "../utils/overlay"
const px = require "../utils/px"
const theme = require "../constants/theme"

--// Constants
const ICON_MARGIN = 4
const ICON = "rbxassetid://127550923848951"

--// Types
type props = {
	right: number,
	visible: () -> boolean,

	on_reset: () -> (),
	size: number?,
}

--// Component
return function(props: props)
	const hovered = vide.source(false)
	const icon_size = (props.size or theme.reset_width) - ICON_MARGIN

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
		if hovered() and not overlay.active() then return appearance.text() end
		return appearance.icon()
	end

	const function background_transparency()
		if hovered() and not overlay.active() then return 0 end
		return 1
	end

	return vide.create "TextButton" {
		Name = "reset",
		AnchorPoint = Vector2.new(1, 0.5),

		Position = px.udim2(1, -props.right, 0.5, 0),
		Size = px.udim2(0, props.size or theme.reset_width, 0, props.size or theme.reset_width),

		BackgroundColor3 = appearance.raised,
		BackgroundTransparency = motion.ease(background_transparency),
		BorderSizePixel = 0,

		AutoButtonColor = false,
		Active = true,

		Text = "",
		Visible = props.visible,

		Activated = overlay.guard(on_activated),
		MouseEnter = on_enter,
		MouseLeave = on_leave,

		vide.create "UICorner" {
			CornerRadius = px.udim(0, theme.radius),
		},

		vide.create "ImageLabel" {
			Name = "icon",
			AnchorPoint = Vector2.new(0.5, 0.5),

			Position = UDim2.fromScale(0.5, 0.5),
			Size = px.udim2(0, icon_size, 0, icon_size),

			BackgroundTransparency = 1,
			Image = ICON,
			ImageColor3 = motion.ease(color),
		},
	}
end
