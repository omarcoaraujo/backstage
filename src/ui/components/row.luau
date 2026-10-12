--// Packages
const vide = require "../../../roblox_packages/vide"

--// Utils
const filter = require "../utils/filter"
const px = require "../utils/px"
const theme = require "../utils/theme"

--// Constants
const LABEL_SHARE = 0.45

--// Types
type props = {
	label: string,
	content: unknown?,
}

--// Component
return function(props: props)
	const node = filter.leaf { props.label }

	const frame = vide.create "Frame" {
		Name = props.label,
		BackgroundTransparency = 1,

		Visible = node.shown,
		Size = px.udim2(1, 0, 0, theme.row_height),

		vide.create "TextLabel" {
			Name = "label",
			Position = px.udim2(0, theme.padding, 0, 0),

			Size = px.udim2(LABEL_SHARE, -theme.padding, 1, 0),
			BackgroundTransparency = 1,

			FontFace = theme.font,
			Text = props.label,

			TextColor3 = theme.text_muted,
			TextSize = px(theme.text_size),

			TextTruncate = Enum.TextTruncate.AtEnd,
			TextXAlignment = Enum.TextXAlignment.Left,
		},

		vide.create "Frame" {
			Name = "control",
			Position = UDim2.fromScale(LABEL_SHARE, 0),
			Size = px.udim2(1 - LABEL_SHARE, -theme.padding, 1, 0),

			BackgroundTransparency = 1,
			props.content,
		},
	}

	filter.track(frame, node)
	return frame
end
