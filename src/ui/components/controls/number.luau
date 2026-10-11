--// Packages
const vide = require "../../../../roblox_packages/vide"

--// Utils
const px = require "../../utils/px"
const theme = require "../../utils/theme"

--// Components
const number_input = require "./number_input"
const slider = require "./slider"

--// Types
type props = {
	value: () -> number,
	on_change: (value: number) -> (),

	min: number?,
	max: number?,
	step: number?,
}

--// Component
return function(props: props)
	const min = props.min
	const max = props.max

	return vide.create "Frame" {
		Name = "number",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,

		(min and max) and vide.create "Frame" {
			Name = "slider_area",
			Size = px.udim2(1, -(theme.input_width + theme.gap), 1, 0),
			BackgroundTransparency = 1,

			slider {
				value = props.value,
				on_change = props.on_change,

				min = min,
				max = max,
				step = props.step,
			},
		} or nil,

		vide.create "Frame" {
			Name = "input_area",
			AnchorPoint = Vector2.new(1, 0),

			Position = UDim2.fromScale(1, 0),
			Size = px.udim2(0, theme.input_width, 1, 0),

			BackgroundTransparency = 1,
			number_input { value = props.value, on_change = props.on_change },
		},
	}
end
