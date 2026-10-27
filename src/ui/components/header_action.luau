--// Packages
const vide = require "../../../roblox_packages/vide"

--// Stores
const appearance = require "../stores/appearance"

--// Utils
const overlay = require "../utils/overlay"
const px = require "../utils/px"
const theme = require "../constants/theme"

--// Constants
const GLYPH_SIZE = 18
const LABEL_PADDING = 6

--// Types
type props = {
	name: string,
	text: () -> string,
	position: () -> UDim2,

	on_activated: () -> (),
	highlighted: (() -> boolean)?,

	shown: (() -> boolean)?,
	danger: boolean?,
}

--// Component
return function(props: props)
	const hovered = vide.source(false)

	const function on_enter()
		hovered(true)
	end

	const function on_leave()
		hovered(false)
	end

	const function on_activated()
		hovered(false)
		props.on_activated()
	end

	const function lit()
		return props.highlighted ~= nil and props.highlighted()
	end

	const function visible()
		if props.shown == nil then return true end
		return props.shown() or hovered() or lit()
	end

	const function background_transparency()
		if overlay.active() then return 1 end
		if hovered() or lit() then return 0 end
		return 1
	end

	const function color()
		const active = (hovered() or lit()) and not overlay.active()

		if props.danger and active then return appearance.danger() end
		if props.danger then return appearance.danger_muted() end
		if active then return appearance.text() end
		return appearance.text_muted()
	end

	return vide.create "TextButton" {
		Name = props.name,
		AnchorPoint = Vector2.new(1, 0.5),

		Position = props.position,
		Size = px.udim2(0, theme.title_button, 0, theme.title_button),
		AutomaticSize = Enum.AutomaticSize.X,

		BackgroundColor3 = appearance.hover,
		BackgroundTransparency = background_transparency,
		BorderSizePixel = 0,

		AutoButtonColor = false,
		Active = true,
		Visible = visible,

		FontFace = theme.font,
		Text = props.text,

		TextColor3 = color,
		TextSize = px(GLYPH_SIZE),

		Activated = overlay.guard(on_activated),
		MouseEnter = on_enter,
		MouseLeave = on_leave,

		vide.create "UICorner" {
			CornerRadius = px.udim(0, theme.radius),
		},

		vide.create "UIPadding" {
			PaddingLeft = px.udim(0, LABEL_PADDING),
			PaddingRight = px.udim(0, LABEL_PADDING),
		},
	}
end
