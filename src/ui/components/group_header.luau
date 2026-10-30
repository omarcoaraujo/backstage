--// Packages
const vide = require "../../../roblox_packages/vide"

--// Stores
const appearance = require "../stores/appearance"

--// Utils
const arrow = require "../constants/arrow"
const motion = require "../utils/motion"
const overlay = require "../utils/overlay"
const px = require "../utils/px"
const theme = require "../constants/theme"

--// Components
const confirm_button = require "./confirm_button"
const header_action = require "./header_action"
const remove_button = require "./remove_button"
const reset_button = require "./reset_button"

--// Constants
const ADD_ICON = "rbxassetid://78158808810563"

--// Types
type props = {
	name: string | () -> string,
	active: (() -> boolean)?,

	expanded: () -> boolean,
	on_toggle: () -> (),

	dirty: (() -> boolean)?,
	on_reset: (() -> ())?,
	on_confirm: (() -> ())?,

	on_add: (() -> ())?,
	adding: (() -> boolean)?,
	on_remove: (() -> ())?,
}

--// Component
return function(props: props)
	const addable = props.on_add ~= nil
	const actions = (if addable then 1 else 0) + (if props.on_remove then 1 else 0)
	const hovered = vide.source(false)

	const function on_enter()
		hovered(true)
	end

	const function on_leave()
		hovered(false)
	end

	vide.effect(function()
		if props.active and not props.active() then on_leave() end
	end)

	const function reset_visible()
		return hovered() and props.dirty ~= nil and props.dirty()
	end

	const function on_reset()
		if props.on_reset then props.on_reset() end
	end

	const function on_confirm()
		if props.on_confirm then props.on_confirm() end
	end

	const function arrow_frame()
		return if props.expanded() then arrow.down else arrow.right
	end

	const function header_transparency()
		if overlay.active() then return 1 end
		if hovered() then return 0.4 end
		return 1
	end

	const function highlighted()
		return props.adding ~= nil and props.adding()
	end

	return vide.create "TextButton" {
		Name = "header",
		Size = px.udim2(1, 0, 0, theme.row_height),
		AutoButtonColor = false,

		BackgroundColor3 = appearance.hover,
		BackgroundTransparency = motion.ease(header_transparency),
		BorderSizePixel = 0,

		FontFace = theme.font,
		Text = props.name,
		TextColor3 = appearance.text,

		TextSize = px(theme.text_size),
		TextXAlignment = Enum.TextXAlignment.Left,

		Activated = overlay.guard(props.on_toggle),
		MouseEnter = on_enter,
		MouseLeave = on_leave,

		vide.create "UICorner" {
			CornerRadius = px.udim(0, theme.radius),
		},

		vide.create "UIPadding" {
			PaddingLeft = px.udim(0, theme.padding + arrow.size + arrow.gap),
		},

		vide.create "ImageLabel" {
			Name = "arrow",
			AnchorPoint = Vector2.new(0, 0.5),

			Position = px.udim2(0, -(arrow.size + arrow.gap), 0.5, 0),
			Size = px.udim2(0, arrow.size, 0, arrow.size),

			BackgroundTransparency = 1,
			Image = arrow.image,

			ImageColor3 = appearance.text,
			ImageRectSize = arrow.frame,
			ImageRectOffset = arrow_frame,
		},

		reset_button {
			right = theme.padding / 2 + theme.action_width * actions,
			visible = reset_visible,
			on_reset = on_reset,
		},

		confirm_button {
			right = theme.padding / 2 + theme.action_width * (actions + 1),
			visible = reset_visible,
			on_confirm = on_confirm,
		},

		if props.on_add
			then header_action {
				name = "add",
				image = ADD_ICON,

				position = px.udim2(1, -theme.padding / 2, 0.5, 0),
				on_activated = props.on_add,

				highlighted = highlighted,
				shown = hovered,
			}
			else nil,

		if props.on_remove
			then remove_button {
				position = px.udim2(1, -(theme.padding / 2 + (if addable then theme.action_width else 0)), 0.5, 0),
				shown = hovered,
				on_remove = props.on_remove,
			}
			else nil,
	}
end
