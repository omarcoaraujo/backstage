--// Packages
const vide = require "../../../roblox_packages/vide"

--// Stores
const appearance = require "../stores/appearance"

--// Utils
const activity = require "../utils/activity"
const overlay = require "../utils/overlay"
const px = require "../utils/px"
const theme = require "../constants/theme"

--// Components
const hint = require "./hint"

--// Constants
const PADDING = 8

--// Types
type props = {
	text: string,
	on_press: () -> (),
	hint: string?,

	min_width: (() -> number)?,
	max_width: (() -> number)?,
}

--// Component
return function(props: props)
	const hovered = vide.source(false)
	const pressed = vide.source(false)

	local root = nil :: TextButton?
	const tip = hint {
		text = props.hint,
		anchor = function()
			return root
		end,
	}

	const function on_enter()
		hovered(true)
		tip.on_enter()
	end

	const function on_leave()
		hovered(false)
		pressed(false)
		tip.on_leave()
	end

	const function on_down()
		if overlay.active() then return end
		pressed(true)
	end

	const function on_up()
		pressed(false)
	end

	const function background()
		if pressed() then return appearance.divider() end
		if hovered() and not overlay.active() then return appearance.hover() end
		return appearance.field()
	end

	const function stroke_color()
		if pressed() then return appearance.accent() end
		return appearance.stroke()
	end

	const function stroke_transparency()
		if pressed() then return theme.stroke_focus_transparency end
		if hovered() and not overlay.active() then return theme.stroke_hover_transparency end
		return theme.stroke_transparency
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
		return Vector2.new(props.max_width(), math.huge)
	end

	const content = vide.create "TextButton" {
		Name = props.text,
		Size = px.udim2(0, 0, 0, theme.field_height),
		AutomaticSize = Enum.AutomaticSize.X,

		AutoButtonColor = false,
		BackgroundColor3 = background,
		BorderSizePixel = 0,

		FontFace = theme.font,
		Text = props.text,

		TextColor3 = appearance.text,
		TextSize = px(theme.text_size),
		TextTruncate = Enum.TextTruncate.AtEnd,

		Activated = overlay.guard(props.on_press),
		MouseEnter = on_enter,
		MouseLeave = on_leave,

		MouseButton1Down = on_down,
		MouseButton1Up = on_up,
		InputBegan = tip.on_input,

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

		activity.mark(pressed),
	}

	root = content
	return content
end
