--// Services
const ReplicatedStorage = game:GetService "ReplicatedStorage"

--// Modules
const exporter = require(ReplicatedStorage.backstage.core.export)
const kinds = require(ReplicatedStorage.backstage.core.kinds)

--// Specs
return {
	writes_only_changed_values = function()
		const text = exporter.text {
			{ path = "pets.distance", value = 8, default = 6 },
			{ path = "pets.mode", value = "follow", default = "follow" },
		}

		assert(text == "pets.distance = 8")
	end,

	writes_one_line_per_value = function()
		const text = exporter.text {
			{ path = "pets.distance", value = 8.5, default = 6 },
			{ path = "pets.trail.enabled", value = false, default = true },
		}

		assert(text == "pets.distance = 8.5\npets.trail.enabled = false")
	end,

	quotes_strings = function()
		const text = exporter.text { { path = "pets.mode", value = "orbit", default = "follow" } }
		assert(text == 'pets.mode = "orbit"')
	end,

	escapes_quotes_and_new_lines = function()
		const text = exporter.text { { path = "pets.name", value = 'say "hi"\nbye', default = "" } }
		assert(text == 'pets.name = "say \\"hi\\"\\nbye"')
	end,

	writes_colors_and_vectors = function()
		const text = exporter.text {
			{ path = "pets.tint", value = Color3.fromRGB(255, 128, 0), default = Color3.new() },
			{ path = "pets.offset", value = Vector3.new(0, 1.5, 0), default = Vector3.zero },
		}

		assert(text == "pets.tint = Color3.fromRGB(255, 128, 0)\npets.offset = Vector3.new(0, 1.5, 0)")
	end,

	keeps_the_decimals_of_a_fine_step = function()
		const descriptor = kinds.infer(0.0025, { min = 0.0005, max = 0.02, step = 0.0001 }) :: kinds.descriptor
		const decimals = kinds.decimals(descriptor)

		const min_turn_speed = kinds.coerce(descriptor, 0.0025) :: number
		const max_turn_speed = kinds.coerce(descriptor, 0.0075) :: number

		assert(min_turn_speed == 0.0025)
		assert(max_turn_speed == 0.0075)

		const unchanged = exporter.text {
			{ path = "pets.min_turn_speed", value = min_turn_speed, default = 0.0025, decimals = decimals },
			{ path = "pets.max_turn_speed", value = max_turn_speed, default = 0.0075, decimals = decimals },
		}

		assert(unchanged == "")
		const edited = exporter.text {
			{ path = "pets.min_turn_speed", value = 0.0025, default = 0.001, decimals = decimals },
			{ path = "pets.max_turn_speed", value = 0.0075, default = 0.001, decimals = decimals },
		}

		assert(edited == "pets.min_turn_speed = 0.0025\npets.max_turn_speed = 0.0075")
	end,

	is_empty_when_nothing_changed = function()
		assert(exporter.text { { path = "pets.distance", value = 6, default = 6 } } == "")
	end,
}
