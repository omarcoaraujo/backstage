--// Packages
const vide = require "../../../../roblox_packages/vide"

--// Utils
const filter = require "../../utils/filter"
const px = require "../../utils/px"
const theme = require "../../utils/theme"

--// Constants
const PADDING = 4
const FOCUS_TRANSPARENCY = 0.4

--// Component
return function()
	const focused = vide.source(false)

	const function on_focused()
		focused(true)
	end

	const function on_focus_lost()
		focused(false)
	end

	const function stroke_transparency()
		if focused() then return FOCUS_TRANSPARENCY end
		return 1
	end

	return vide.create "Frame" {
		Name = "search",
		Position = px.udim2(0, 0, 0, theme.title_height),

		Size = px.udim2(1, 0, 0, theme.row_height),
		BackgroundTransparency = 1,

		vide.create "TextBox" {
			Name = "field",
			AnchorPoint = Vector2.new(0, 0.5),

			Position = px.udim2(0, theme.padding, 0.5, 0),
			Size = px.udim2(1, -theme.padding * 2, 0, theme.field_height),

			BackgroundColor3 = theme.field,
			BorderSizePixel = 0,
			ClipsDescendants = true,

			ClearTextOnFocus = false,
			FontFace = theme.font,

			PlaceholderText = "search",
			PlaceholderColor3 = theme.text_muted,

			Text = "",
			TextColor3 = theme.text,

			TextSize = px(theme.text_size),
			TextXAlignment = Enum.TextXAlignment.Left,

			Focused = on_focused,
			FocusLost = on_focus_lost,

			vide.create "UIPadding" {
				PaddingLeft = px.udim(0, PADDING),
				PaddingRight = px.udim(0, PADDING),
			},

			vide.create "UIStroke" {
				Color = theme.stroke,
				Transparency = stroke_transparency,

				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				LineJoinMode = Enum.LineJoinMode.Miter,
				Thickness = px(1),
			},

			vide.changed("Text", filter.query),
		},
	}
end
