--// Packages
const vide = require "../../../../roblox_packages/vide"

--// Utils
const px = require "../../utils/px"
const theme = require "../../utils/theme"

--// Constants
const FOCUS_TRANSPARENCY = 0.4

--// Types
type props = {
	value: () -> number,
	on_change: (value: number) -> (),
}

--// Functions
const function format(value: number): string
	return string.format("%.4g", value)
end

--// Component
return function(props: props)
	const focused = vide.source(false)
	local box = nil :: TextBox?

	const function text()
		return format(props.value())
	end

	const function on_focused()
		focused(true)
	end

	const function on_focus_lost()
		focused(false)

		if not box then return end
		const typed = tonumber(box.Text)

		if typed then props.on_change(typed) end
		box.Text = text()
	end

	const function stroke_transparency()
		return if focused() then FOCUS_TRANSPARENCY else 1
	end

	box = vide.create "TextBox" {
		Name = "input",
		AnchorPoint = Vector2.new(0, 0.5),

		Position = UDim2.fromScale(0, 0.5),
		Size = px.udim2(1, 0, 0, theme.field_height),

		BackgroundColor3 = theme.field,
		BorderSizePixel = 0,

		ClearTextOnFocus = false,
		FontFace = theme.font,

		Text = text,
		TextColor3 = theme.text,

		TextSize = px(theme.text_size),
		Focused = on_focused,
		FocusLost = on_focus_lost,

		vide.create "UIStroke" {
			Color = theme.stroke,
			Transparency = stroke_transparency,

			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			LineJoinMode = Enum.LineJoinMode.Miter,
			Thickness = px(1),
		},
	}

	return box
end
