--// Packages
const vide = require "../../../roblox_packages/vide"

--// Stores
const appearance = require "../stores/appearance"
const locks = require "../stores/locks"

--// Utils
const filter = require "../utils/filter"
const px = require "../utils/px"
const theme = require "../constants/theme"

--// Components
const hint = require "./hint"
const remove_button = require "./remove_button"
const reset_button = require "./reset_button"

--// Constants
const LABEL_SHARE = 0.45
const LOCKED_TRANSPARENCY = 0.45

--// Types
type props = {
	label: string,
	content: unknown?,

	hint: string?,
	node: filter.node?,

	dirty: (() -> boolean)?,
	on_reset: (() -> ())?,

	on_remove: (() -> ())?,
	locked: (() -> boolean)?,
}

--// Component
return function(props: props)
	const node = props.node
	local root = nil :: Frame?

	const hovered = vide.source(false)
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

	const function on_enter()
		hovered(true)
		tip.on_enter()
	end

	const function on_leave()
		hovered(false)
		tip.on_leave()
	end

	const function removable()
		return hovered() and not reset_visible()
	end

	const function dimmed()
		return locks.check(props.locked)
	end

	const frame = vide.create "Frame" {
		Name = props.label,
		BackgroundTransparency = 1,

		Visible = if node then node.shown else true,
		Size = px.udim2(1, 0, 0, theme.row_height),

		MouseEnter = on_enter,
		MouseLeave = on_leave,
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

		if props.on_remove
			then remove_button {
				position = px.udim2(1, -theme.padding / 2, 0.5, 0),
				shown = removable,
				on_remove = props.on_remove,
			}
			else nil,

		vide.create "Frame" {
			Name = "locked",
			Size = UDim2.fromScale(1, 1),

			BackgroundColor3 = appearance.background,
			BackgroundTransparency = LOCKED_TRANSPARENCY,
			BorderSizePixel = 0,

			Visible = dimmed,
			ZIndex = 2,
		},
	}

	root = frame
	if node then filter.track(frame, node) end

	return frame
end
