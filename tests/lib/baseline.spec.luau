--// Services
const ReplicatedStorage = game:GetService "ReplicatedStorage"

--// Modules
const baseline = require(ReplicatedStorage.backstage.core.baseline)

--// Specs
return {
	the_first_default_seen_is_the_baseline = function()
		baseline.reset()
		assert(baseline.resolve("pets.speed", 8) == 8)
		baseline.reset()
	end,

	keeps_the_original_after_a_reload_that_carries_the_saved_edit = function()
		baseline.reset()
		baseline.resolve("pets.speed", 8)
		baseline.remember("pets.speed", 12)

		assert(baseline.resolve("pets.speed", 12) == 8)
		baseline.reset()
	end,

	keeps_the_original_across_several_edits_and_reloads = function()
		baseline.reset()
		baseline.resolve("pets.speed", 8)

		baseline.remember("pets.speed", 12)
		baseline.resolve("pets.speed", 12)

		baseline.remember("pets.speed", 20)
		assert(baseline.resolve("pets.speed", 20) == 8)
		baseline.reset()
	end,

	forgets_the_original_when_the_edit_is_forgotten = function()
		baseline.reset()
		baseline.resolve("pets.speed", 8)

		baseline.remember("pets.speed", 12)
		baseline.forget "pets.speed"

		assert(baseline.resolve("pets.speed", 12) == 12)
		baseline.reset()
	end,

	takes_a_new_baseline_when_the_script_changed_by_hand = function()
		baseline.reset()
		baseline.resolve("pets.speed", 8)

		baseline.remember("pets.speed", 12)
		assert(baseline.resolve("pets.speed", 30) == 30)
		baseline.reset()
	end,

	takes_a_new_baseline_when_the_tool_did_not_save = function()
		baseline.reset()
		baseline.resolve("pets.speed", 8)

		baseline.remember("pets.speed", 12)
		assert(baseline.resolve("pets.speed", 8) == 8)
		baseline.reset()
	end,

	matches_a_saved_value_rounded_by_the_tool = function()
		baseline.reset()
		baseline.resolve("pets.speed", 8)

		baseline.remember("pets.speed", 2.3456789)
		assert(baseline.resolve("pets.speed", 2.345679) == 8)
		baseline.reset()
	end,

	matches_a_saved_color_rounded_to_a_byte = function()
		baseline.reset()
		const original = Color3.fromRGB(255, 200, 80)
		baseline.resolve("pets.tint", original)

		baseline.remember("pets.tint", Color3.new(0.5, 0.6, 0.7))
		assert(baseline.resolve("pets.tint", Color3.fromRGB(128, 153, 179)) == original)
		baseline.reset()
	end,
}
