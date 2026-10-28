--// Packages
const vide = require "../../../../roblox_packages/vide"

--// Stores
const appearance = require "../../stores/appearance"

--// Utils
const motion = require "../../utils/motion"
const overlay = require "../../utils/overlay"
const px = require "../../utils/px"
const theme = require "../../constants/theme"

--// Components
const confirm_button = require "../confirm_button"
const export_button = require "./export_button"
const logo = require "./logo"
const reset_button = require "../reset_button"
const theme_button = require "./theme_button"

--// Constants
const TITLE_INSET = theme.padding + theme.logo_size + theme.logo_gap
const CROSS_LENGTH = 11
const CROSS_THICKNESS = 1.5

--// Types
type props = {
	title: string,
	on_press: (input: InputObject) -> (),

	on_release: (input: InputObject) -> (),
	on_close: () -> (),

	dirty: (() -> boolean)?,
	on_reset: (() -> ())?,

	on_confirm: (() -> ())?,
	on_export: (() -> ())?,
}

--// Component
return function(props: props)
	const close_hovered = vide.source(false)

	const function on_close_enter()
		close_hovered(true)
	end

	const function on_close_leave()
		close_hovered(false)
	end

	const function reset_visible()
		return props.dirty ~= nil and props.dirty()
	end

	const function on_reset()
		if props.on_reset then props.on_reset() end
	end

	const function on_confirm()
		if props.on_confirm then props.on_confirm() end
	end

	const function on_export()
		if props.on_export then props.on_export() end
	end

	const function close_transparency()
		if overlay.active() then return 1 end
		if close_hovered() then return 0 end
		return 1
	end

	const function cross_color()
		if close_hovered() and not overlay.active() then return appearance.text() end
		return appearance.icon()
	end

	const function cross_stroke(rotation: number)
		return vide.create "Frame" {
			Name = "cross",
			AnchorPoint = Vector2.new(0.5, 0.5),

			Position = UDim2.fromScale(0.5, 0.5),
			Size = px.udim2(0, CROSS_LENGTH, 0, CROSS_THICKNESS),

			BackgroundColor3 = motion.ease(cross_color),
			BorderSizePixel = 0,
			Rotation = rotation,

			vide.create "UICorner" {
				CornerRadius = UDim.new(1, 0),
			},
		}
	end

	return vide.create "Frame" {
		Name = "title_bar",
		BackgroundTransparency = 1,

		BorderSizePixel = 0,
		Active = true,

		Size = px.udim2(1, 0, 0, theme.title_height),
		InputBegan = overlay.guard(props.on_press),
		InputEnded = props.on_release,

		logo(),

		vide.create "TextLabel" {
			Name = "title",
			Position = px.udim2(0, TITLE_INSET, 0, 0),
			Size = px.udim2(1, -theme.title_height - TITLE_INSET, 1, 0),

			BackgroundTransparency = 1,
			FontFace = theme.font,

			Text = props.title,
			TextColor3 = appearance.text,

			TextXAlignment = Enum.TextXAlignment.Left,
			TextSize = px(theme.text_size),
		},

		vide.create "Frame" {
			Name = "divider",
			Position = UDim2.new(0, 0, 1, -1),

			Size = UDim2.new(1, 0, 0, 1),
			BackgroundColor3 = appearance.stroke,
			BackgroundTransparency = theme.stroke_transparency,
			BorderSizePixel = 0,
		},

		reset_button {
			right = theme.title_inset * 2.5 + theme.title_button * 3,
			size = theme.title_button,

			visible = reset_visible,
			on_reset = on_reset,
		},

		confirm_button {
			right = theme.title_inset * 3 + theme.title_button * 4,
			size = theme.title_button,

			visible = reset_visible,
			on_confirm = on_confirm,
		},

		export_button {
			right = theme.title_inset * 2 + theme.title_button * 2,
			on_export = on_export,
		},

		theme_button {
			right = theme.title_inset * 1.5 + theme.title_button,
		},

		vide.create "TextButton" {
			Name = "close",
			AnchorPoint = Vector2.new(1, 0),

			Position = px.udim2(1, -theme.title_inset, 0, theme.title_inset),
			Size = px.udim2(0, theme.title_button, 0, theme.title_button),

			AutoButtonColor = false,
			BackgroundColor3 = appearance.hover,

			BorderSizePixel = 0,
			BackgroundTransparency = motion.ease(close_transparency),

			Text = "",
			Modal = true,

			Activated = overlay.guard(props.on_close),
			MouseEnter = on_close_enter,
			MouseLeave = on_close_leave,

			vide.create "UICorner" {
				CornerRadius = px.udim(0, theme.radius),
			},

			cross_stroke(45),
			cross_stroke(-45),
		},
	}
end
