--// Packages
const vide = require "../../../../roblox_packages/vide"

--// Stores
const appearance = require "../../stores/appearance"

--// Utils
const motion = require "../../utils/motion"
const px = require "../../utils/px"
const theme = require "../../constants/theme"

--// Constants
const PADDING = 4

--// Types
type props = { query: vide.Source<string> }

--// Component
return function(props: props)
	const focused = vide.source(false)

	const function on_focused()
		focused(true)
	end

	const function on_focus_lost()
		focused(false)
	end

	const function stroke_color()
		if focused() then return appearance.accent() end
		return appearance.stroke()
	end

	const function stroke_transparency()
		if focused() then return theme.stroke_focus_transparency end
		return theme.stroke_transparency
	end

	return vide.create "Frame" {
		Name = "search",
		Position = px.udim2(0, 0, 0, theme.title_height),

		Size = px.udim2(1, 0, 0, theme.search_height),
		BackgroundTransparency = 1,

		vide.create "TextBox" {
			Name = "field",
			Position = px.udim2(0, theme.padding, 0, theme.padding),
			Size = px.udim2(1, -theme.padding * 2, 0, theme.field_height),

			BackgroundColor3 = appearance.field,
			BorderSizePixel = 0,
			ClipsDescendants = true,

			ClearTextOnFocus = false,
			FontFace = theme.font,

			PlaceholderText = "search",
			PlaceholderColor3 = appearance.text_muted,

			Text = "",
			TextColor3 = appearance.text,

			TextSize = px(theme.text_size),
			TextXAlignment = Enum.TextXAlignment.Left,

			Focused = on_focused,
			FocusLost = on_focus_lost,

			vide.create "UIPadding" {
				PaddingLeft = px.udim(0, PADDING),
				PaddingRight = px.udim(0, PADDING),
			},

			vide.create "UICorner" {
				CornerRadius = px.udim(0, theme.radius),
			},

			vide.create "UIStroke" {
				Color = motion.ease(stroke_color),
				Transparency = motion.ease(stroke_transparency),

				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				LineJoinMode = Enum.LineJoinMode.Round,
				Thickness = px(1),
			},

			vide.changed("Text", props.query),
		},
	}
end
