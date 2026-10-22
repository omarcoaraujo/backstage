--// Packages
const vide = require "../../../../roblox_packages/vide"

--// Stores
const appearance = require "../../stores/appearance"

--// Utils
const overlay = require "../../utils/overlay"
const px = require "../../utils/px"
const theme = require "../../constants/theme"

--// Components
const reset_button = require "../reset_button"
const theme_button = require "./theme_button"

--// Constants
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

	const function close_transparency()
		if overlay.active() then return 1 end
		if close_hovered() then return 0 end
		return 1
	end

	const function cross_color()
		if close_hovered() and not overlay.active() then return appearance.text() end
		return appearance.text_muted()
	end

	const function cross_stroke(rotation: number)
		return vide.create "Frame" {
			Name = "cross",
			AnchorPoint = Vector2.new(0.5, 0.5),

			Position = UDim2.fromScale(0.5, 0.5),
			Size = px.udim2(0, CROSS_LENGTH, 0, CROSS_THICKNESS),

			BackgroundColor3 = cross_color,
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

		vide.create "TextLabel" {
			Name = "title",
			Position = px.udim2(0, theme.padding, 0, 0),
			Size = px.udim2(1, -theme.title_height - theme.padding, 1, 0),

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
			right = theme.title_inset * 2 + theme.title_button * 2,
			visible = reset_visible,
			on_reset = on_reset,
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
			BackgroundTransparency = close_transparency,

			Text = "",
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
