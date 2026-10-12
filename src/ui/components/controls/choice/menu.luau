--// Services
const UserInputService = game:GetService "UserInputService"

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
	local scroller = nil :: ScrollingFrame?
	local pressed = false

	const active = vide.source(table.find(props.choices, props.value))

	const function reveal()
		const index = active()
		if not index or not scroller then return end

		const row_height = px(theme.field_height)()
		const top = (index - 1) * row_height

		const bottom = top + row_height
		const view = scroller.AbsoluteSize.Y
		const offset = scroller.CanvasPosition.Y

		if top < offset then
			scroller.CanvasPosition = Vector2.new(0, top)
		elseif bottom > offset + view then
			scroller.CanvasPosition = Vector2.new(0, bottom - view)
		end
	end

	const function capture(instance: Instance)
		scroller = instance :: ScrollingFrame
		reveal()
	end

	const function move(step: number)
		const count = #props.choices
		if count == 0 then return end

		const current = active()
		if not current then
			active(if step > 0 then 1 else count)
			return
		end

		active(math.clamp(current + step, 1, count))
	end

	const function pick_active()
		const index = active()
		if not index then return end
		props.on_pick(props.choices[index])
	end

	const function on_key(input: InputObject)
		if input.UserInputType ~= Enum.UserInputType.Keyboard then return end

		const code = input.KeyCode
		if code == Enum.KeyCode.Escape then
			props.on_dismiss()
		elseif code == Enum.KeyCode.Down then
			move(1)
		elseif code == Enum.KeyCode.Up then
			move(-1)
		elseif code == Enum.KeyCode.Return or code == Enum.KeyCode.KeypadEnter then
			pick_active()
		end
	end

	const function build(index: number, choice: string)
		const function highlighted()
			return active() == index
		end

		const function on_hover()
			active(index)
		end

		return option {
			text = choice,
			selected = choice == props.value,
			highlighted = highlighted,

			on_press = props.on_pick,
			on_hover = on_hover,
		}
	end

	for index, choice in props.choices do
		table.insert(options, build(index, choice))
	end

	const function on_backdrop_press(input: InputObject)
		if pointer.is_press(input) then pressed = true end
	end

	const function on_backdrop_release(input: InputObject)
		if not pressed or not pointer.is_press(input) then return end
		props.on_dismiss()
	end

	vide.effect(reveal)
	vide.cleanup(UserInputService.InputBegan:Connect(on_key))

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
			vide.action(capture),
		},
	}
end
