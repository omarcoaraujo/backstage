--// Modules
const values = require "../../cli/values"

--// Functions
const function read(source: string)
	return values.read(source)
end

--// Specs
return {
	reads_every_kind_of_literal = function()
		const snapshot = read [[backstage.config("pets", {
			speed = -2.5,
			on = true,
			name = "rex",
			tint = Color3.fromRGB(10, 20, 30),
			offset = Vector3.new(1, 2, 3),
		})]]

		assert(snapshot["pets.speed"].value == -2.5)
		assert(snapshot["pets.on"].value == true)
		assert(snapshot["pets.name"].value == "rex")
		assert(snapshot["pets.tint"].kind == "color" and snapshot["pets.tint"].value.g == 20)
		assert(snapshot["pets.offset"].kind == "vector3" and snapshot["pets.offset"].value.z == 3)
	end,

	reads_nested_tables_with_their_path = function()
		const snapshot = read 'backstage.config("pets", { trail = { length = 4 } })'
		assert(snapshot["pets.trail.length"].value == 4)
	end,

	skips_what_is_not_a_literal = function()
		const snapshot = read 'backstage.config("pets", { speed = base * 2, size = 3 })'
		assert(snapshot["pets.speed"] == nil)
		assert(snapshot["pets.size"].value == 3)
	end,

	reports_only_the_values_that_changed = function()
		const before = read 'backstage.config("pets", { speed = 1, size = 2 })'
		const after = read 'backstage.config("pets", { speed = 5, size = 2 })'
		const changes = values.changes(before, after)

		assert(#changes == 1)
		assert(changes[1].path == "pets.speed" and changes[1].value == 5)
	end,

	ignores_a_different_way_of_writing_the_same_value = function()
		const before = read 'backstage.config("pets", { speed = 1 })'
		const after = read 'backstage.config("pets", { speed = 1.0 })'
		assert(#values.changes(before, after) == 0)
	end,

	ignores_a_value_that_was_not_there_before = function()
		const before = read 'backstage.config("pets", { speed = 1 })'
		const after = read 'backstage.config("pets", { speed = 1, size = 2 })'
		assert(#values.changes(before, after) == 0)
	end,
}
