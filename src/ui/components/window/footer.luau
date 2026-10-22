--// Packages
const vide = require "../../../../roblox_packages/vide"

--// Stores
const appearance = require "../../stores/appearance"

--// Utils
const px = require "../../utils/px"
const theme = require "../../constants/theme"

--// Constants
const TEXT_TRANSPARENCY = 0.45

--// Types
type props = {
	text: string,
	visible: boolean,
}

--// Component
return function(props: props)
	return vide.create "Frame" {
		Name = "footer",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),

		Size = px.udim2(1, 0, 0, theme.footer_height),
		BackgroundTransparency = 1,
		Visible = props.visible,

		vide.create "Frame" {
			Name = "divider",
			Size = UDim2.new(1, 0, 0, 1),

			BackgroundColor3 = appearance.divider,
			BackgroundTransparency = 0.5,
			BorderSizePixel = 0,
		},

		vide.create "TextLabel" {
			Name = "text",
			Size = UDim2.fromScale(1, 1),

			BackgroundTransparency = 1,
			FontFace = theme.font,

			Text = props.text,
			TextColor3 = appearance.text_muted,
			TextSize = px(theme.footer_text_size),

			TextTransparency = TEXT_TRANSPARENCY,
			TextXAlignment = Enum.TextXAlignment.Center,
		},
	}
end
