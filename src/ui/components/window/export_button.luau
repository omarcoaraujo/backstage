--// Packages
const vide = require "../../../../roblox_packages/vide"

--// Stores
const appearance = require "../../stores/appearance"

--// Utils
const motion = require "../../utils/motion"
const overlay = require "../../utils/overlay"
const px = require "../../utils/px"
const theme = require "../../constants/theme"

--// Constants
const ICON_SIZE = 16
const ICON = "rbxassetid://96960130733821"

--// Types
type props = {
	right: number,
	on_export: () -> (),
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
		return appearance.icon()
	end

	return vide.create "TextButton" {
		Name = "export",
		AnchorPoint = Vector2.new(1, 0),

		Position = px.udim2(1, -props.right, 0, theme.title_inset),
		Size = px.udim2(0, theme.title_button, 0, theme.title_button),

		AutoButtonColor = false,
		Active = true,

		BackgroundColor3 = appearance.hover,
		BackgroundTransparency = motion.ease(background_transparency),
		BorderSizePixel = 0,

		Text = "",

		Activated = overlay.guard(props.on_export),
		MouseEnter = on_enter,
		MouseLeave = on_leave,

		vide.create "UICorner" {
			CornerRadius = px.udim(0, theme.radius),
		},

		vide.create "ImageLabel" {
			Name = "icon",
			AnchorPoint = Vector2.new(0.5, 0.5),

			Position = UDim2.fromScale(0.5, 0.5),
			Size = px.udim2(0, ICON_SIZE, 0, ICON_SIZE),

			BackgroundTransparency = 1,
			Image = ICON,

			ImageColor3 = motion.ease(icon_color),
		},
	}
end
