--// Functions
const function place(origin: Vector2, size: Vector2, height: number, gap: number, bounds: Vector2): Vector2
	const below = origin.Y + size.Y + gap
	if below + height <= bounds.Y then return Vector2.new(origin.X, below) end

	const above = origin.Y - gap - height
	if above >= 0 then return Vector2.new(origin.X, above) end

	return Vector2.new(origin.X, math.max(0, bounds.Y - height))
end

--// End
return place
