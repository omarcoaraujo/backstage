--// Packages
const vide = require "../../../../../roblox_packages/vide"

--// Stores
const appearance = require "../../../stores/appearance"

--// Utils
const px = require "../../../utils/px"
const theme = require "../../../constants/theme"

--// Constants
const PADDING = 4

--// Types
type props = {
	text: string,
	selected: boolean,
	highlighted: () -> boolean,

	on_press: (text: string) -> (),
	on_hover: () -> (),
}

--// Component
return function(props: props)
	const function on_activated()
		props.on_press(props.text)
	end

	const function background_transparency()
		if props.highlighted() then return 0 end
		return 1
	end

	const function text_color()
		if props.highlighted() or props.selected then return appearance.text() end
		return appearance.text_muted()
	end

	return vide.create "TextButton" {
		Name = props.text,
		Size = px.udim2(1, 0, 0, theme.field_height),

		AutoButtonColor = false,
		BackgroundColor3 = appearance.hover,

		BackgroundTransparency = background_transparency,
		BorderSizePixel = 0,

		FontFace = theme.font,
		Text = props.text,
		TextColor3 = text_color,

		TextSize = px(theme.text_size),
		TextXAlignment = Enum.TextXAlignment.Left,

		Activated = on_activated,
		MouseEnter = props.on_hover,

		vide.create "UICorner" {
			CornerRadius = px.udim(0, theme.radius),
		},

		vide.create "UIPadding" {
			PaddingLeft = px.udim(0, PADDING),
		},
	}
end
