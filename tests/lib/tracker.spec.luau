--// Services
const ReplicatedStorage = game:GetService "ReplicatedStorage"

--// Modules
const registry = require(ReplicatedStorage.backstage.core.registry)
const tracker = require(ReplicatedStorage.backstage.core.tracker)

--// Specs
return {
	take_returns_the_reads_in_order_and_clears_them = function()
		registry.reset()
		tracker.read("pets.distance", 6, "script", 10, "caller")
		tracker.read("pets.speed", 8, "script", 11, "caller")

		const found = tracker.take()
		assert(#found == 2)

		assert(found[1].path == "pets.distance")
		assert(found[1].value == 6)
		assert(found[1].source == "script")

		assert(found[1].line == 10)
		assert(found[1].caller == "caller")

		assert(found[2].path == "pets.speed")
		assert(#tracker.take() == 0)
	end,

	the_reads_expire_after_the_frame = function()
		registry.reset()
		tracker.read("pets.distance", 6)

		task.wait()
		assert(#tracker.take() == 0)
	end,

	a_read_after_an_expired_one_is_kept = function()
		registry.reset()
		tracker.read("pets.distance", 6)

		task.wait()
		tracker.read("pets.speed", 8)

		const found = tracker.take()
		assert(#found == 1)
		assert(found[1].path == "pets.speed")
	end,

	only_the_most_recent_reads_are_kept = function()
		registry.reset()

		for index = 1, 40 do
			tracker.read(`pets.value_{index}`, index)
		end

		const found = tracker.take()
		assert(#found < 40)
		assert(found[#found].path == "pets.value_40")
	end,

	reset_drops_the_reads = function()
		tracker.read("pets.distance", 6)
		registry.reset()
		assert(#tracker.take() == 0)
	end,
}
