--// Packages
const vide = require "../../../../roblox_packages/vide"

--// Stores
const appearance = require "../../stores/appearance"

--// Utils
const activity = require "../../utils/activity"
const hex = require "../../utils/hex"
const overlay = require "../../utils/overlay"
const place = require "../../utils/place"
const px = require "../../utils/px"
const theme = require "../../constants/theme"

--// Components
const field = require "./field"
const picker = require "@self/picker"

--// Constants
const SWATCH_STROKE_TRANSPARENCY = 0.8
const FOCUS_TRANSPARENCY = 0.15

--// Types
type props = {
	value: () -> Color3,
	on_change: (value: Color3) -> (),
}

--// Component
return function(props: props)
	const opened = vide.source(false)
	local swatch = nil :: TextButton?
	local destroy_picker = nil :: (() -> ())?

	const function text(): string
		return hex.to_hex(props.value())
	end

	const function on_commit(typed: string)
		const parsed = hex.from_hex(typed)
		if not parsed then return end
		props.on_change(parsed)
	end

	const function capture(instance: Instance)
		swatch = instance :: TextButton
	end

	const function close()
		if not destroy_picker then return end

		destroy_picker()
		destroy_picker = nil

		opened(false)
		overlay.leave()
	end

	const function open()
		if destroy_picker or not swatch then return end

		const layer = swatch:FindFirstAncestorWhichIsA "LayerCollector"
		if not layer then return end

		const origin = swatch.AbsolutePosition - layer.AbsolutePosition
		const left = math.round(origin.X)

		const top = math.round(origin.Y)
		const swatch_size = Vector2.new(
			math.round(origin.X + swatch.AbsoluteSize.X) - left,
			math.round(origin.Y + swatch.AbsoluteSize.Y) - top
		)

		const height = px(picker.height())()
		const width = px(picker.width)()
		const bounds = layer.AbsoluteSize

		const placed = place(Vector2.new(left, top), swatch_size, height, px(1)(), bounds)
		const position = Vector2.new(math.clamp(placed.X, 0, math.max(0, bounds.X - width)), placed.Y)

		destroy_picker = vide.root(function()
			vide.cleanup(picker.component {
				layer = layer,
				value = props.value(),

				position = position,
				on_change = props.on_change,
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

	const function stroke_transparency()
		if opened() then return FOCUS_TRANSPARENCY end
		return SWATCH_STROKE_TRANSPARENCY
	end

	vide.cleanup(close)
	return vide.create "Frame" {
		Name = "color",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,

		vide.create "UIListLayout" {
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,

			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = px.udim(0, theme.gap),
		},

		vide.create "TextButton" {
			Name = "swatch",
			LayoutOrder = 1,
			Size = px.udim2(0, theme.field_height, 0, theme.field_height),

			AutoButtonColor = false,
			BackgroundColor3 = props.value,

			BorderSizePixel = 0,
			Text = "",

			vide.create "UICorner" {
				CornerRadius = px.udim(0, theme.radius),
			},

			vide.create "UIStroke" {
				Color = appearance.stroke,
				Transparency = stroke_transparency,

				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				LineJoinMode = Enum.LineJoinMode.Round,
				Thickness = px(1),
			},

			Activated = on_activated,

			vide.action(capture),
			activity.mark(opened),
		},

		vide.create "Frame" {
			Name = "input_area",
			LayoutOrder = 2,

			Size = px.udim2(0, 0, 1, 0),
			BackgroundTransparency = 1,

			vide.create "UIFlexItem" {
				FlexMode = Enum.UIFlexMode.Fill,
			},

			field { text = text, on_commit = on_commit },
		},
	}
end
