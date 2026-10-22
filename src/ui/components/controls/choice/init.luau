--// Packages
const vide = require "../../../../roblox_packages/vide"

--// Stores
const appearance = require "../../stores/appearance"

--// Utils
const overlay = require "../../utils/overlay"
const place = require "../../utils/place"
const px = require "../../utils/px"
const theme = require "../../constants/theme"

--// Components
const menu = require "@self/menu"

--// Constants
const MAX_VISIBLE = 8
const PADDING = 4

--// Types
type props = {
	value: () -> string,
	on_change: (value: string) -> (),
	choices: { string },
}

--// Component
return function(props: props)
	const opened = vide.source(false)
	local field = nil :: TextButton?
	local destroy_menu = nil :: (() -> ())?

	const function capture(instance: Instance)
		field = instance :: TextButton
	end

	const function close()
		if not destroy_menu then return end

		destroy_menu()
		destroy_menu = nil

		opened(false)
		overlay.leave()
	end

	const function on_pick(choice: string)
		props.on_change(choice)
		close()
	end

	const function open()
		if destroy_menu or not field then return end

		const layer = field:FindFirstAncestorWhichIsA "LayerCollector"
		if not layer then return end

		const height = math.min(#props.choices, MAX_VISIBLE) * px(theme.field_height)()
		const origin = field.AbsolutePosition - layer.AbsolutePosition

		const left = math.round(origin.X)
		const top = math.round(origin.Y)

		const width = math.round(origin.X + field.AbsoluteSize.X) - left
		const field_height = math.round(origin.Y + field.AbsoluteSize.Y) - top
		const position =
			place(Vector2.new(left, top), Vector2.new(width, field_height), height, px(1)(), layer.AbsoluteSize)

		destroy_menu = vide.root(function()
			vide.cleanup(menu {
				layer = layer,
				choices = props.choices,
				value = props.value(),

				position = position,
				width = width,
				height = height,

				on_pick = on_pick,
				on_dismiss = close,
			})
		end)

		opened(true)
		overlay.enter()
	end

	const function on_activated()
		if overlay.active() and not opened() then return end

		if opened() then
			close()
			return
		end

		open()
	end

	const function caret()
		if opened() then return "^" end
		return "v"
	end

	const function text_color()
		if table.find(props.choices, props.value()) then return appearance.text() end
		return appearance.text_muted()
	end

	const function stroke_color()
		if opened() then return appearance.accent() end
		return appearance.stroke()
	end

	const function stroke_transparency()
		if opened() then return theme.stroke_focus_transparency end
		return theme.stroke_transparency
	end

	vide.cleanup(close)
	return vide.create "TextButton" {
		Name = "choice",
		AnchorPoint = Vector2.new(0, 0.5),

		Position = UDim2.fromScale(0, 0.5),
		Size = px.udim2(1, 0, 0, theme.field_height),

		AutoButtonColor = false,
		BackgroundColor3 = appearance.field,

		BorderSizePixel = 0,
		ClipsDescendants = true,

		FontFace = theme.font,
		Text = props.value,
		TextColor3 = text_color,

		TextSize = px(theme.text_size),
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextXAlignment = Enum.TextXAlignment.Left,

		vide.create "UIPadding" {
			PaddingLeft = px.udim(0, PADDING),
			PaddingRight = px.udim(0, theme.field_height),
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

		vide.create "TextLabel" {
			Name = "caret",
			AnchorPoint = Vector2.new(1, 0),

			Position = px.udim2(1, theme.field_height, 0, 0),
			Size = px.udim2(0, theme.field_height, 1, 0),

			BackgroundTransparency = 1,
			FontFace = theme.font,
			Text = caret,

			TextColor3 = appearance.text_muted,
			TextSize = px(theme.text_size),
		},

		Activated = on_activated,
		vide.action(capture),
	}
end
