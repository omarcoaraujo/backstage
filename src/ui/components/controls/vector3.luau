--// Packages
const vide = require "../../../../roblox_packages/vide"

--// Stores
const appearance = require "../../stores/appearance"

--// Utils
const px = require "../../utils/px"
const theme = require "../../constants/theme"

--// Components
const number_input = require "./number_input"

--// Constants
const AXIS_WIDTH = 14
const AXIS_TRANSPARENCY = 0.3

--// Types
type props = {
	value: () -> Vector3,
	on_change: (value: Vector3) -> (),
}

--// Functions
const function read_x(vector: Vector3): number
	return vector.X
end

const function read_y(vector: Vector3): number
	return vector.Y
end

const function read_z(vector: Vector3): number
	return vector.Z
end

const function write_x(vector: Vector3, value: number): Vector3
	return Vector3.new(value, vector.Y, vector.Z)
end

const function write_y(vector: Vector3, value: number): Vector3
	return Vector3.new(vector.X, value, vector.Z)
end

const function write_z(vector: Vector3, value: number): Vector3
	return Vector3.new(vector.X, vector.Y, value)
end

--// Component
return function(props: props)
	const function cell(
		axis: string,
		read: (vector: Vector3) -> number,
		write: (vector: Vector3, value: number) -> Vector3
	)
		const function value(): number
			return read(props.value())
		end

		const function on_change(next_value: number)
			props.on_change(write(props.value(), next_value))
		end

		return vide.create "Frame" {
			Name = axis,
			Size = px.udim2(0, 0, 1, 0),
			BackgroundTransparency = 1,

			vide.create "UIFlexItem" {
				FlexMode = Enum.UIFlexMode.Fill,
			},

			vide.create "UIListLayout" {
				FillDirection = Enum.FillDirection.Horizontal,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
			},

			vide.create "TextLabel" {
				Name = "axis",
				LayoutOrder = 1,
				Size = px.udim2(0, AXIS_WIDTH, 0, theme.field_height),

				BackgroundTransparency = 1,
				FontFace = theme.font,

				Text = axis,
				TextColor3 = appearance.text_muted,
				TextSize = px(theme.text_size),

				TextTransparency = AXIS_TRANSPARENCY,
				TextXAlignment = Enum.TextXAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Center,
			},

			vide.create "Frame" {
				Name = "input_area",
				LayoutOrder = 2,

				Size = px.udim2(0, 0, 1, 0),
				BackgroundTransparency = 1,

				vide.create "UIFlexItem" {
					FlexMode = Enum.UIFlexMode.Fill,
				},

				number_input { value = value, on_change = on_change },
			},
		}
	end

	return vide.create "Frame" {
		Name = "vector3",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,

		vide.create "UIListLayout" {
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = px.udim(0, theme.gap),
		},

		cell("x", read_x, write_x),
		cell("y", read_y, write_y),
		cell("z", read_z, write_z),
	}
end
