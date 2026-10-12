--// Packages
const vide = require "../../../roblox_packages/vide"

--// Utils
const filter = require "../utils/filter"
const overlay = require "../utils/overlay"
const px = require "../utils/px"
const theme = require "../utils/theme"

--// Constants
const LABEL_SHARE = 0.45
const RESET_WIDTH = 18

--// Types
type props = {
	label: string,
	content: unknown?,

	dirty: (() -> boolean)?,
	on_reset: (() -> ())?,
}

--// Component
return function(props: props)
	const node = filter.leaf { props.label }
	const hovered = vide.source(false)

	const function on_enter()
		hovered(true)
	end

	const function on_leave()
		hovered(false)
	end

	const function on_activated()
		hovered(false)
		if props.on_reset then props.on_reset() end
	end

	const function reset_color()
		if hovered() and not overlay.active() then return theme.text end
		return theme.text_muted
	end

	const function reset_visible()
		return props.dirty ~= nil and props.dirty()
	end

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
			Size = px.udim2(1 - LABEL_SHARE, -theme.padding - RESET_WIDTH, 1, 0),

			BackgroundTransparency = 1,
			props.content,
		},

		vide.create "TextButton" {
			Name = "reset",
			AnchorPoint = Vector2.new(1, 0),

			Position = px.udim2(1, -theme.padding / 2, 0, 0),
			Size = px.udim2(0, RESET_WIDTH, 1, 0),

			BackgroundTransparency = 1,
			AutoButtonColor = false,
			Active = true,

			FontFace = theme.font,
			Text = "↺",

			TextColor3 = reset_color,
			TextSize = px(theme.text_size),
			Visible = reset_visible,

			Activated = overlay.guard(on_activated),
			MouseEnter = on_enter,
			MouseLeave = on_leave,
		},
	}

	filter.track(frame, node)
	return frame
end
