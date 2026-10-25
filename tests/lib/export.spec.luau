--// Services
const ReplicatedStorage = game:GetService "ReplicatedStorage"

--// Modules
const exporter = require(ReplicatedStorage.backstage.core.export)

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

	writes_colors_and_vectors = function()
		const text = exporter.text {
			{ path = "pets.tint", value = Color3.fromRGB(255, 128, 0), default = Color3.new() },
			{ path = "pets.offset", value = Vector3.new(0, 1.5, 0), default = Vector3.zero },
		}

		assert(text == "pets.tint = Color3.fromRGB(255, 128, 0)\npets.offset = Vector3.new(0, 1.5, 0)")
	end,

	is_empty_when_nothing_changed = function()
		assert(exporter.text { { path = "pets.distance", value = 6, default = 6 } } == "")
	end,
}
