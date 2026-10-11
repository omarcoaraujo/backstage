--// Functions
const function is_press(input: InputObject): boolean
	return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end

const function is_motion(input: InputObject): boolean
	return input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch
end

const function position(input: InputObject): Vector2
	return Vector2.new(input.Position.X, input.Position.Y)
end

--// End
return table.freeze {
	is_press = is_press,
	is_motion = is_motion,
	position = position,
}
