--// Services
const ReplicatedStorage = game:GetService "ReplicatedStorage"

--// Modules
const resize_rect = require(ReplicatedStorage.backstage.ui.utils.resize_rect)

--// Constants
const POSITION = Vector2.new(100, 100)
const SIZE = Vector2.new(300, 200)
const MIN_SIZE = Vector2.new(200, 100)
const BOUNDS = Vector2.new(800, 600)

--// Functions
const function resize(horizontal: number, vertical: number, delta: Vector2)
	return resize_rect({ horizontal = horizontal, vertical = vertical }, delta, POSITION, SIZE, MIN_SIZE, BOUNDS)
end

--// Specs
return {
	right_edge_grows_the_width = function()
		const position, size = resize(1, 0, Vector2.new(50, 30))
		assert(position == POSITION)
		assert(size == Vector2.new(350, 200))
	end,

	left_edge_moves_the_origin = function()
		const position, size = resize(-1, 0, Vector2.new(-50, 0))
		assert(position == Vector2.new(50, 100))
		assert(size == Vector2.new(350, 200))
	end,

	bottom_right_corner_grows_both_axes = function()
		const position, size = resize(1, 1, Vector2.new(20, 40))
		assert(position == POSITION)
		assert(size == Vector2.new(320, 240))
	end,

	size_stops_at_the_minimum = function()
		const _, size = resize(1, 1, Vector2.new(-500, -500))
		assert(size == MIN_SIZE)
	end,

	left_edge_keeps_the_right_side_fixed_at_the_minimum = function()
		const position, size = resize(-1, 0, Vector2.new(500, 0))
		assert(size.X == MIN_SIZE.X)
		assert(position.X + size.X == POSITION.X + SIZE.X)
	end,

	size_stops_at_the_bounds = function()
		const _, size = resize(1, 1, Vector2.new(5000, 5000))
		assert(POSITION.X + size.X == BOUNDS.X)
		assert(POSITION.Y + size.Y == BOUNDS.Y)
	end,
}
