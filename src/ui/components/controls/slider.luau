--// Services
const UserInputService = game:GetService "UserInputService"

--// Packages
const vide = require "../../../../roblox_packages/vide"

--// Stores
const appearance = require "../../stores/appearance"

--// Utils
const activity = require "../../utils/activity"
const overlay = require "../../utils/overlay"
const pointer = require "../../utils/pointer"
const px = require "../../utils/px"

--// Constants
const TRACK_HEIGHT = 3
const KNOB_WIDTH = 10
const KNOB_HEIGHT = 10

const CAPTURE_SPAN = 20000
const CAPTURE_Z_INDEX = 100000

--// Types
type props = {
	value: () -> number,
	on_change: (value: number) -> (),

	min: number,
	max: number,
	step: number?,
}

--// Functions
const function snap(raw: number, min: number, max: number, step: number?): number
	const clamped = math.clamp(raw, min, max)
	if not step or step <= 0 then return clamped end
	return math.clamp(min + math.round((clamped - min) / step) * step, min, max)
end

--// Component
return function(props: props)
	const dragging = vide.source(false)
	local track = nil :: Frame?

	const function share(): number
		const span = props.max - props.min
		if span <= 0 then return 0 end
		return math.clamp((props.value() - props.min) / span, 0, 1)
	end

	const function seek(input: InputObject)
		if not track or track.AbsoluteSize.X <= 0 then return end
		const ratio = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
		props.on_change(snap(props.min + ratio * (props.max - props.min), props.min, props.max, props.step))
	end

	const function on_press(input: InputObject)
		if overlay.active() or not pointer.is_press(input) then return end
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

	const function fill_size()
		return UDim2.fromScale(share(), 1)
	end

	const function knob_position()
		return UDim2.fromScale(share(), 0.5)
	end

	return vide.create "Frame" {
		Name = "slider",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Active = true,

		InputBegan = on_press,
		InputEnded = on_release,

		vide.create "UIPadding" {
			PaddingLeft = px.udim(0, KNOB_WIDTH / 2),
			PaddingRight = px.udim(0, KNOB_WIDTH / 2),
		},

		vide.create "Frame" {
			Name = "track",
			AnchorPoint = Vector2.new(0, 0.5),

			Position = UDim2.fromScale(0, 0.5),
			Size = px.udim2(1, 0, 0, TRACK_HEIGHT),

			BackgroundColor3 = appearance.divider,
			BorderSizePixel = 0,

			vide.create "UICorner" {
				CornerRadius = UDim.new(1, 0),
			},

			vide.create "Frame" {
				Name = "fill",
				Size = fill_size,

				BackgroundColor3 = appearance.accent,
				BorderSizePixel = 0,

				vide.create "UICorner" {
					CornerRadius = UDim.new(1, 0),
				},
			},

			vide.create "Frame" {
				Name = "knob",
				AnchorPoint = Vector2.new(0.5, 0.5),

				Position = knob_position,
				Size = px.udim2(0, KNOB_WIDTH, 0, KNOB_HEIGHT),

				BackgroundColor3 = appearance.text,
				BorderSizePixel = 0,

				vide.create "UICorner" {
					CornerRadius = UDim.new(1, 0),
				},

				activity.mark(dragging),
			},

			vide.action(function(instance)
				track = instance :: Frame
			end),
		},

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
	}
end
