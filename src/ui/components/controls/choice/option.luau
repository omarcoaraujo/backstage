--// Packages
const vide = require "../../../../../roblox_packages/vide"

--// Utils
const px = require "../../../utils/px"
const theme = require "../../../utils/theme"

--// Constants
const PADDING = 4

--// Types
type props = {
	text: string,
	selected: boolean,
	on_press: (text: string) -> (),
}

--// Component
return function(props: props)
	const hovered = vide.source(false)

	const function on_activated()
		props.on_press(props.text)
	end

	const function on_enter()
		hovered(true)
	end

	const function on_leave()
		hovered(false)
	end

	const function background_transparency()
		if hovered() then return 0 end
		return 1
	end

	const function text_color()
		if hovered() or props.selected then return theme.text end
		return theme.text_muted
	end

	return vide.create "TextButton" {
		Name = props.text,
		Size = px.udim2(1, 0, 0, theme.field_height),

		AutoButtonColor = false,
		BackgroundColor3 = theme.hover,

		BackgroundTransparency = background_transparency,
		BorderSizePixel = 0,

		FontFace = theme.font,
		Text = props.text,
		TextColor3 = text_color,

		TextSize = px(theme.text_size),
		TextXAlignment = Enum.TextXAlignment.Left,

		Activated = on_activated,
		MouseEnter = on_enter,
		MouseLeave = on_leave,

		vide.create "UIPadding" {
			PaddingLeft = px.udim(0, PADDING),
		},
	}
end
