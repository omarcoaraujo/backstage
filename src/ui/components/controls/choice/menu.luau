--// Packages
const vide = require "../../../../../roblox_packages/vide"

--// Utils
const pointer = require "../../../utils/pointer"
const px = require "../../../utils/px"
const theme = require "../../../utils/theme"

--// Components
const option = require "./option"

--// Constants
const LAYER_Z_INDEX = 100000
const SCROLLBAR_THICKNESS = 4
const STROKE_TRANSPARENCY = 0.4

--// Types
type props = {
	layer: Instance,
	choices: { string },
	value: string,

	position: Vector2,
	width: number,
	height: number,

	on_pick: (choice: string) -> (),
	on_dismiss: () -> (),
}

--// Component
return function(props: props)
	const options = {} :: { unknown }
	local pressed = false

	for _, choice in props.choices do
		table.insert(options, option { text = choice, selected = choice == props.value, on_press = props.on_pick })
	end

	const function on_backdrop_press(input: InputObject)
		if pointer.is_press(input) then pressed = true end
	end

	const function on_backdrop_release(input: InputObject)
		if not pressed or not pointer.is_press(input) then return end
		props.on_dismiss()
	end

	return vide.create "Frame" {
		Name = "backstage_dropdown",
		Parent = props.layer,
		Size = UDim2.fromScale(1, 1),

		BackgroundTransparency = 1,
		Active = true,
		ZIndex = LAYER_Z_INDEX,

		InputBegan = on_backdrop_press,
		InputEnded = on_backdrop_release,

		vide.create "ScrollingFrame" {
			Name = "menu",
			Position = UDim2.fromOffset(props.position.X, props.position.Y),
			Size = UDim2.fromOffset(props.width, props.height),

			BackgroundColor3 = theme.field,
			BorderSizePixel = 0,
			Active = true,

			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			CanvasSize = UDim2.fromScale(0, 0),

			ScrollBarImageColor3 = theme.divider,
			ScrollBarThickness = px(SCROLLBAR_THICKNESS),
			VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar,

			vide.create "UIStroke" {
				Color = theme.stroke,
				Transparency = STROKE_TRANSPARENCY,

				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				LineJoinMode = Enum.LineJoinMode.Miter,
				Thickness = px(1),
			},

			vide.create "UIListLayout" {
				SortOrder = Enum.SortOrder.LayoutOrder,
			},

			options,
		},
	}
end
