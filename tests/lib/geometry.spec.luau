--// Services
const ReplicatedStorage = game:GetService "ReplicatedStorage"

--// Modules
const geometry = require(ReplicatedStorage.backstage.core.geometry)

--// Specs
return {
	finds_a_saved_geometry_by_its_key = function()
		geometry.reset()
		geometry.save("tuning", Vector2.new(10, 20), Vector2.new(300, 400))

		const found = geometry.get "tuning"
		assert(found and found.position == Vector2.new(10, 20) and found.size == Vector2.new(300, 400))

		assert(geometry.get "other" == nil)
		geometry.reset()
	end,

	the_latest_save_wins = function()
		geometry.reset()
		geometry.save("tuning", Vector2.new(1, 1), Vector2.new(300, 400))
		geometry.save("tuning", Vector2.new(2, 2), Vector2.new(320, 420))

		const found = geometry.get "tuning"
		assert(found and found.position == Vector2.new(2, 2) and found.size == Vector2.new(320, 420))
		geometry.reset()
	end,
}
