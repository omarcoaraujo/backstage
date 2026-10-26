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

	reads_the_arguments_of_a_helper_function = function()
		const snapshot = read [[
			local function item(price, weight)
				return { price = price, weight = weight, stack = 4 }
			end

			backstage.config("shop", { sword = item(10, 2) })
		]]

		assert(snapshot["shop.sword.price"].value == 10)
		assert(snapshot["shop.sword.weight"].value == 2)
		assert(snapshot["shop.sword.stack"].value == 4)
	end,

	names_the_value_by_its_key_and_not_by_the_parameter = function()
		const snapshot = read [[
			local function item(another_thing)
				return { price = another_thing }
			end

			backstage.config("shop", { sword = item(10) })
		]]

		assert(snapshot["shop.sword.price"].value == 10)
		assert(snapshot["shop.sword.another_thing"] == nil)
	end,

	reads_helper_calls_inside_a_list = function()
		const snapshot = read [[
			local function item(price)
				return { price = price }
			end

			backstage.config("shop", { items = { item(10), item(25) } })
		]]

		assert(snapshot["shop.items.1.price"].value == 10)
		assert(snapshot["shop.items.2.price"].value == 25)
	end,

	skips_a_helper_argument_that_is_not_a_literal = function()
		const snapshot = read [[
			local function item(price)
				return { price = price }
			end

			backstage.config("shop", { sword = item(base * 2) })
		]]

		assert(snapshot["shop.sword.price"] == nil)
	end,

	reports_the_change_of_a_helper_argument = function()
		const helper = "local function item(price) return { price = price } end\n"
		const before = read(helper .. 'backstage.config("shop", { sword = item(10) })')
		const after = read(helper .. 'backstage.config("shop", { sword = item(12) })')
		const changes = values.changes(before, after)

		assert(#changes == 1)
		assert(changes[1].path == "shop.sword.price" and changes[1].value == 12)
	end,

	reports_every_call_when_the_helper_body_changes = function()
		const before = read [[
			local function item(price) return { price = price, stack = 4 } end
			backstage.config("shop", { sword = item(10), bow = item(20) })
		]]

		const after = read [[
			local function item(price) return { price = price, stack = 8 } end
			backstage.config("shop", { sword = item(10), bow = item(20) })
		]]

		const changes = values.changes(before, after)
		assert(#changes == 2)
		assert(changes[1].path == "shop.bow.stack" and changes[2].path == "shop.sword.stack")
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

	structure_reports_the_values_that_appeared_with_their_literals = function()
		const before = read 'backstage.config("pets", { speed = 1 })'
		const after = read 'backstage.config("pets", { speed = 1, size = 2, name = "Rex" })'

		const added, removed = values.structure(before, after)
		assert(#removed == 0 and #added == 2)

		assert(added[1].path == "pets.name" and added[1].kind == "string" and added[1].value == "Rex")
		assert(added[2].path == "pets.size" and added[2].kind == "number" and added[2].value == 2)
	end,

	structure_reports_the_values_that_disappeared = function()
		const before = read 'backstage.config("pets", { speed = 1, size = 2, age = 3 })'
		const after = read 'backstage.config("pets", { speed = 1 })'

		const added, removed = values.structure(before, after)
		assert(#added == 0)
		assert(#removed == 2 and removed[1] == "pets.age" and removed[2] == "pets.size")
	end,

	structure_reports_nothing_when_only_a_value_changed = function()
		const before = read 'backstage.config("pets", { speed = 1 })'
		const after = read 'backstage.config("pets", { speed = 9 })'

		const added, removed = values.structure(before, after)
		assert(#added == 0 and #removed == 0)
	end,
}
