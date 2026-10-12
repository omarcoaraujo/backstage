--// Services
const UserInputService = game:GetService "UserInputService"

--// Packages
const vide = require "../../../../../roblox_packages/vide"

--// Utils
const pointer = require "../../../utils/pointer"

--// Constants
const CAPTURE_SPAN = 20000
const CAPTURE_Z_INDEX = 100000

--// Types
type props = {
	name: string,
	size: () -> UDim2,
	on_drag: (x: number, y: number) -> (),
	[number]: unknown,
}

--// Component
return function(props: props)
	const dragging = vide.source(false)
	local area = nil :: Frame?

	const function seek(input: InputObject)
		if not area or area.AbsoluteSize.X <= 0 or area.AbsoluteSize.Y <= 0 then return end
		const x = math.clamp((input.Position.X - area.AbsolutePosition.X) / area.AbsoluteSize.X, 0, 1)

		const y = math.clamp((input.Position.Y - area.AbsolutePosition.Y) / area.AbsoluteSize.Y, 0, 1)
		props.on_drag(x, y)
	end

	const function on_press(input: InputObject)
		if not pointer.is_press(input) then return end
		dragging(true)
		seek(input)
	end

	const function on_release(input: InputObject)
		if pointer.is_press(input) then dragging(false) end
	end

	const function on_capture_changed(input: InputObject)
		if not dragging() or not pointer.is_motion(input) then return end

		if
			input.UserInputType == Enum.UserInputType.MouseMovement
			and not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
		then
			dragging(false)
			return
		end

		seek(input)
	end

	const function z_index()
		if dragging() then return 2 end
		return 1
	end

	return vide.create "Frame" {
		Name = props.name,
		Size = props.size,

		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		Active = true,
		ZIndex = z_index,

		InputBegan = on_press,
		InputEnded = on_release,

		vide.create "Frame" {
			Name = "capture",
			AnchorPoint = Vector2.new(0.5, 0.5),

			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(CAPTURE_SPAN, CAPTURE_SPAN),

			BackgroundTransparency = 1,
			Active = true,
			ZIndex = CAPTURE_Z_INDEX,

			Visible = dragging,
			InputChanged = on_capture_changed,
			InputEnded = on_release,
		},

		vide.action(function(instance)
			area = instance :: Frame
		end),

		table.unpack(props),
	}
end
