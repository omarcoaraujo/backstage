--// Packages
const vide = require "../../../roblox_packages/vide"

--// Utils
const overlay = require "../utils/overlay"
const px = require "../utils/px"
const theme = require "../utils/theme"

--// Constants
const PRESS_TRANSPARENCY = 0.3
const PADDING = 8

--// Types
type props = {
	text: string,
	on_press: () -> (),

	min_width: (() -> number)?,
	max_width: (() -> number)?,
}

--// Component
return function(props: props)
	const hovered = vide.source(false)
	const pressed = vide.source(false)

	const function on_enter()
		hovered(true)
	end

	const function on_leave()
		hovered(false)
		pressed(false)
	end

	const function on_down()
		pressed(true)
	end

	const function on_up()
		pressed(false)
	end

	const function background()
		if pressed() then return theme.divider end
		if hovered() and not overlay.active() then return theme.hover end

		return theme.field
	end

	const function stroke_transparency()
		if pressed() then return PRESS_TRANSPARENCY end
		return 1
	end

	const function content_width(width: number): number
		return math.max(0, width - px(PADDING)() * 2)
	end

	const function min_size()
		if not props.min_width then return Vector2.zero end
		return Vector2.new(content_width(props.min_width()), 0)
	end

	const function max_size()
		if not props.max_width then return Vector2.new(math.huge, math.huge) end
		return Vector2.new(content_width(props.max_width()), math.huge)
	end

	return vide.create "TextButton" {
		Name = props.text,
		Size = px.udim2(0, 0, 0, theme.field_height),
		AutomaticSize = Enum.AutomaticSize.X,

		AutoButtonColor = false,
		BackgroundColor3 = background,
		BorderSizePixel = 0,

		FontFace = theme.font,
		Text = props.text,

		TextColor3 = theme.text,
		TextSize = px(theme.text_size),
		TextTruncate = Enum.TextTruncate.AtEnd,

		Activated = props.on_press,
		MouseEnter = on_enter,
		MouseLeave = on_leave,

		MouseButton1Down = on_down,
		MouseButton1Up = on_up,

		vide.create "UIPadding" {
			PaddingLeft = px.udim(0, PADDING),
			PaddingRight = px.udim(0, PADDING),
		},

		vide.create "UISizeConstraint" {
			MinSize = min_size,
			MaxSize = max_size,
		},

		vide.create "UIFlexItem" {
			FlexMode = Enum.UIFlexMode.Grow,
		},

		vide.create "UIStroke" {
			Color = theme.stroke,
			Transparency = stroke_transparency,

			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			LineJoinMode = Enum.LineJoinMode.Miter,
			Thickness = px(1),
		},
	}
end
