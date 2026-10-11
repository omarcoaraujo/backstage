--// Packages
const vide = require "../../../../roblox_packages/vide"

--// Utils
const px = require "../../utils/px"
const theme = require "../../utils/theme"

--// Constants
const FOCUS_TRANSPARENCY = 0.4
const PADDING = 4

--// Types
type props = {
	text: () -> string,
	on_commit: (typed: string) -> (),
	alignment: Enum.TextXAlignment?,
}

--// Component
return function(props: props)
	const focused = vide.source(false)
	local box = nil :: TextBox?

	const function capture(instance: Instance)
		box = instance :: TextBox
	end

	const function on_focused()
		focused(true)
	end

	const function on_focus_lost()
		focused(false)
		if not box then return end

		props.on_commit(box.Text)
		box.Text = props.text()
	end

	const function stroke_transparency()
		if focused() then return FOCUS_TRANSPARENCY end
		return 1
	end

	return vide.create "TextBox" {
		Name = "field",
		AnchorPoint = Vector2.new(0, 0.5),

		Position = UDim2.fromScale(0, 0.5),
		Size = px.udim2(1, 0, 0, theme.field_height),

		BackgroundColor3 = theme.field,
		BorderSizePixel = 0,
		ClipsDescendants = true,

		ClearTextOnFocus = false,
		FontFace = theme.font,

		Text = props.text,
		TextColor3 = theme.text,

		TextSize = px(theme.text_size),
		TextXAlignment = props.alignment or Enum.TextXAlignment.Center,

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

		vide.action(capture),
	}
end
