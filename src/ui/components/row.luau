--// Packages
const vide = require "../../../roblox_packages/vide"

--// Stores
const appearance = require "../stores/appearance"

--// Utils
const filter = require "../utils/filter"
const px = require "../utils/px"
const theme = require "../constants/theme"

--// Components
const hint = require "./hint"
const reset_button = require "./reset_button"

--// Constants
const LABEL_SHARE = 0.45

--// Types
type props = {
	label: string,
	content: unknown?,
	hint: string?,

	dirty: (() -> boolean)?,
	on_reset: (() -> ())?,
}

--// Component
return function(props: props)
	const node = filter.leaf { props.label }
	local root = nil :: Frame?
	const tip = hint {
		text = props.hint,
		anchor = function()
			return root
		end,
	}

	const function reset_visible()
		return props.dirty ~= nil and props.dirty()
	end

	const function on_reset()
		if props.on_reset then props.on_reset() end
	end

	const frame = vide.create "Frame" {
		Name = props.label,
		BackgroundTransparency = 1,

		Visible = node.shown,
		Size = px.udim2(1, 0, 0, theme.row_height),

		MouseEnter = tip.on_enter,
		MouseLeave = tip.on_leave,
		InputBegan = tip.on_input,

		vide.create "TextLabel" {
			Name = "label",
			Position = px.udim2(0, theme.padding, 0, 0),

			Size = px.udim2(LABEL_SHARE, -theme.padding, 1, 0),
			BackgroundTransparency = 1,

			FontFace = theme.font,
			Text = props.label,

			TextColor3 = appearance.text_muted,
			TextSize = px(theme.text_size),

			TextTruncate = Enum.TextTruncate.AtEnd,
			TextXAlignment = Enum.TextXAlignment.Left,
		},

		vide.create "Frame" {
			Name = "control",
			Position = UDim2.fromScale(LABEL_SHARE, 0),
			Size = px.udim2(1 - LABEL_SHARE, -theme.padding - theme.reset_width, 1, 0),

			BackgroundTransparency = 1,
			props.content,
		},

		reset_button {
			right = theme.padding / 2,
			visible = reset_visible,
			on_reset = on_reset,
		},
	}

	root = frame
	filter.track(frame, node)

	return frame
end
