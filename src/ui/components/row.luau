--// Packages
const vide = require "../../../roblox_packages/vide"

--// Utils
const filter = require "../utils/filter"
const overlay = require "../utils/overlay"
const pointer = require "../utils/pointer"
const px = require "../utils/px"
const theme = require "../utils/theme"

--// Components
const tooltip = require "./tooltip"

--// Constants
const HINT_DELAY = 0.5
const LABEL_SHARE = 0.45
const RESET_WIDTH = 18

const RESET_ICON_SIZE = 12
const RESET_ICON = "rbxasset://textures/StudioSharedUI/Undo.png"

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
	const hovered = vide.source(false)

	local root = nil :: Frame?
	local pending = nil :: thread?

	local shown = nil :: Frame?
	local visit = 0

	const function hide_hint()
		visit += 1

		if pending then
			task.cancel(pending)
			pending = nil
		end

		if shown then
			shown:Destroy()
			shown = nil
		end
	end

	const function reveal_hint(mine: number)
		pending = nil

		if not root or not props.hint or overlay.active() then return end
		const created = tooltip { anchor = root, text = props.hint }

		if not created then return end
		if mine ~= visit then
			created:Destroy()
			return
		end

		shown = created
	end

	const function on_row_enter()
		if not props.hint then return end
		hide_hint()

		const mine = visit
		pending = task.delay(HINT_DELAY, function()
			reveal_hint(mine)
		end)
	end

	const function on_row_input(input: InputObject)
		if pointer.is_press(input) then hide_hint() end
	end

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

	vide.effect(function()
		if overlay.active() then hide_hint() end
	end)

	vide.cleanup(hide_hint)

	const frame = vide.create "Frame" {
		Name = props.label,
		BackgroundTransparency = 1,

		Visible = node.shown,
		Size = px.udim2(1, 0, 0, theme.row_height),

		MouseEnter = on_row_enter,
		MouseLeave = hide_hint,
		InputBegan = on_row_input,

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

			Text = "",
			Visible = reset_visible,

			Activated = overlay.guard(on_activated),
			MouseEnter = on_enter,
			MouseLeave = on_leave,

			vide.create "ImageLabel" {
				Name = "icon",
				AnchorPoint = Vector2.new(0.5, 0.5),

				Position = UDim2.fromScale(0.5, 0.5),
				Size = px.udim2(0, RESET_ICON_SIZE, 1, 0),

				BackgroundTransparency = 1,
				Image = RESET_ICON,
				ImageColor3 = reset_color,

				vide.create "UIAspectRatioConstraint" {
					AspectRatio = 1,
					DominantAxis = Enum.DominantAxis.Width,
				},
			},
		},
	}

	root = frame
	filter.track(frame, node)

	return frame
end
