--// Packages
const vide = require "../../../../roblox_packages/vide"

--// Utils
const overlay = require "../../utils/overlay"
const px = require "../../utils/px"
const theme = require "../../utils/theme"

--// Types
type props = {
	title: string,
	on_press: (input: InputObject) -> (),

	on_release: (input: InputObject) -> (),
	on_close: () -> (),
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

	const function close_transparency()
		if overlay.active() then return 1 end
		if close_hovered() then return 0 end
		return 1
	end

	return vide.create "Frame" {
		Name = "title_bar",
		BackgroundColor3 = theme.title_background,

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
			TextColor3 = theme.text,

			TextXAlignment = Enum.TextXAlignment.Left,
			TextSize = px(theme.text_size),
		},

		vide.create "Frame" {
			Name = "divider",
			Position = UDim2.new(0, 0, 1, -1),

			Size = UDim2.new(1, 0, 0, 1),
			BackgroundColor3 = theme.divider,
			BorderSizePixel = 0,
		},

		vide.create "TextButton" {
			Name = "close",
			AnchorPoint = Vector2.new(1, 0),

			Position = UDim2.fromScale(1, 0),
			Size = px.udim2(0, theme.title_height, 0, theme.title_height),

			AutoButtonColor = false,
			BackgroundColor3 = theme.hover,

			BorderSizePixel = 0,
			BackgroundTransparency = close_transparency,

			FontFace = theme.font,
			Text = "x",
			TextColor3 = theme.text,

			TextSize = px(theme.text_size),
			Activated = overlay.guard(props.on_close),

			MouseEnter = on_close_enter,
			MouseLeave = on_close_leave,
		},
	}
end
