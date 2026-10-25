--// Packages
const vide = require "../../../../roblox_packages/vide"

--// Stores
const appearance = require "../../stores/appearance"
const locks = require "../../stores/locks"

--// Utils
const activity = require "../../utils/activity"
const px = require "../../utils/px"
const theme = require "../../constants/theme"

--// Constants
const PADDING = 4

--// Types
type props = {
	text: () -> string,
	on_commit: (typed: string) -> (),
	alignment: Enum.TextXAlignment?,
	locked: (() -> boolean)?,
}

--// Component
return function(props: props)
	local box = nil :: TextBox?
	const focused = vide.source(false)

	const size = vide.source(Vector2.zero)
	const bounds = vide.source(Vector2.zero)

	const function capture(instance: Instance)
		box = instance :: TextBox
	end

	const function on_focused()
		if locks.check(props.locked) and box then
			box:ReleaseFocus()
			return
		end

		focused(true)
	end

	const function editable()
		return not locks.check(props.locked)
	end

	const function on_focus_lost()
		focused(false)
		if not box then return end

		props.on_commit(box.Text)
		box.Text = props.text()
	end

	const function stroke_color()
		if focused() then return appearance.accent() end
		return appearance.stroke()
	end

	const function stroke_transparency()
		if focused() then return theme.stroke_focus_transparency end
		return theme.stroke_transparency
	end

	const function alignment()
		const available = size().X - px(PADDING)() * 2
		if bounds().X > available then return Enum.TextXAlignment.Left end
		return props.alignment or Enum.TextXAlignment.Right
	end

	return vide.create "TextBox" {
		Name = "field",
		AnchorPoint = Vector2.new(0, 0.5),

		Position = UDim2.fromScale(0, 0.5),
		Size = px.udim2(1, 0, 0, theme.field_height),

		BackgroundColor3 = appearance.field,
		BorderSizePixel = 0,
		ClipsDescendants = true,

		ClearTextOnFocus = false,
		TextEditable = editable,
		FontFace = theme.font,

		Text = props.text,
		TextColor3 = appearance.text,

		TextSize = px(theme.text_size),
		TextXAlignment = alignment,

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
			Color = stroke_color,
			Transparency = stroke_transparency,

			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			LineJoinMode = Enum.LineJoinMode.Round,
			Thickness = px(1),
		},

		vide.changed("AbsoluteSize", size),
		vide.changed("TextBounds", bounds),

		vide.action(capture),
		activity.mark(focused),
	}
end
