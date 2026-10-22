--// Functions
const function place(
	origin: Vector2,
	size: Vector2,
	height: number,
	gap: number,
	bounds: Vector2,
	prefer_above: boolean?
): Vector2
	const below = origin.Y + size.Y + gap
	const above = origin.Y - gap - height

	const fits_below = below + height <= bounds.Y
	const fits_above = above >= 0

	if prefer_above and fits_above then return Vector2.new(origin.X, above) end
	if fits_below then return Vector2.new(origin.X, below) end
	if fits_above then return Vector2.new(origin.X, above) end

	return Vector2.new(origin.X, math.max(0, bounds.Y - height))
end

--// End
return place
