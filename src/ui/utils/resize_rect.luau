--// Types
export type side = { horizontal: number, vertical: number }

--// Functions
const function resize_axis(
	start: number,
	length: number,

	direction: number,
	delta: number,

	minimum: number,
	limit: number
)
	if direction == 0 then return start, length end
	if direction == 1 then return start, math.clamp(length + delta, minimum, math.max(minimum, limit - start)) end

	const grown = math.clamp(length - delta, minimum, math.max(minimum, start + length))
	return start + length - grown, grown
end

const function resize_rect(
	side: side,
	delta: Vector2,

	start_position: Vector2,
	start_size: Vector2,

	min_size: Vector2,
	bounds: Vector2
)
	const x, width = resize_axis(start_position.X, start_size.X, side.horizontal, delta.X, min_size.X, bounds.X)
	const y, height = resize_axis(start_position.Y, start_size.Y, side.vertical, delta.Y, min_size.Y, bounds.Y)
	return Vector2.new(x, y), Vector2.new(width, height)
end

--// End
return resize_rect
