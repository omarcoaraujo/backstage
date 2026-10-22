--// Modules
const apply = require "../../cli/apply"

--// Constants
const SOURCE = [[
backstage.config("pets", {
	speed = 16, -- keep
	enabled = true,
	trail = { length = 8, width = 2 },
})
]]

--// Specs
return {
	rewrites_one_value_and_keeps_the_rest = function()
		const result, refused = apply.apply(SOURCE, { { path = "pets.speed", kind = "number", value = 20 } })

		assert(#refused == 0)
		assert(result == string.gsub(SOURCE, "speed = 16", "speed = 20"))
	end,

	rewrites_several_values_on_the_same_line = function()
		const result, refused = apply.apply(SOURCE, {
			{ path = "pets.trail.length", kind = "number", value = 1234.5 },
			{ path = "pets.trail.width", kind = "number", value = 7 },
		})

		assert(#refused == 0)
		assert(string.find(result, "{ length = 1234.5, width = 7 }", 1, true))
	end,

	order_of_the_edits_does_not_matter = function()
		const speed = { path = "pets.speed", kind = "number", value = 99999 }
		const length = { path = "pets.trail.length", kind = "number", value = 1 }

		const first = apply.apply(SOURCE, { speed, length })
		const second = apply.apply(SOURCE, { length, speed })
		assert(first == second)
	end,

	rewrites_a_boolean = function()
		const result = apply.apply(SOURCE, { { path = "pets.enabled", kind = "boolean", value = false } })
		assert(string.find(result, "enabled = false", 1, true))
	end,

	writes_a_shared_literal_once_when_two_paths_reach_it = function()
		const source =
			'const function item(price)\n\treturn { stock = 10, price = price }\nend\nbackstage.config("shop", { items = { item(1), item(2) } })'

		const result, refused = apply.apply(source, {
			{ path = "shop.items.1.stock", kind = "number", value = 20 },
			{ path = "shop.items.2.stock", kind = "number", value = 30 },
			{ path = "shop.items.2.price", kind = "number", value = 9 },
		})

		assert(#refused == 0)
		assert(string.find(result, "stock = 30", 1, true))
		assert(string.find(result, "item(1), item(9)", 1, true))
	end,

	refuses_what_it_cannot_place_and_applies_the_rest = function()
		const result, refused = apply.apply(SOURCE, {
			{ path = "pets.missing", kind = "number", value = 1 },
			{ path = "pets.speed", kind = "number", value = 3 },
		})

		assert(#refused == 1 and refused[1].path == "pets.missing")
		assert(string.find(result, "speed = 3", 1, true))
	end,

	leaves_the_source_alone_when_everything_is_refused = function()
		const result, refused = apply.apply(SOURCE, { { path = "nope.x", kind = "number", value = 1 } })
		assert(result == SOURCE and #refused == 1)
	end,
}
