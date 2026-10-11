--// Packages
const vide = require "../../../../roblox_packages/vide"

--// Utils
const hex = require "../../utils/hex"
const px = require "../../utils/px"
const theme = require "../../utils/theme"

--// Components
const field = require "./field"

--// Constants
const SWATCH_STROKE_TRANSPARENCY = 0.6

--// Types
type props = {
	value: () -> Color3,
	on_change: (value: Color3) -> (),
}

--// Component
return function(props: props)
	const function text(): string
		return hex.to_hex(props.value())
	end

	const function on_commit(typed: string)
		const parsed = hex.from_hex(typed)
		if not parsed then return end
		props.on_change(parsed)
	end

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

		vide.create "Frame" {
			Name = "swatch",
			LayoutOrder = 1,
			Size = px.udim2(0, theme.field_height, 0, theme.field_height),

			BackgroundColor3 = props.value,
			BorderSizePixel = 0,

			vide.create "UIStroke" {
				Color = theme.stroke,
				Transparency = SWATCH_STROKE_TRANSPARENCY,

				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				LineJoinMode = Enum.LineJoinMode.Miter,
				Thickness = px(1),
			},
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
