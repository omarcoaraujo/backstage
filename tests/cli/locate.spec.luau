--// Modules
const locate = require "../../cli/locate"

--// Constants
const SOURCE = [[
const pets = backstage.config("pets", {
	speed = 16,
	enabled = true,
	label = "rex",
	offset = -2.5,
	color = Color3.fromRGB(1, 2, 3),
	trail = { length = 8 },
	dynamic = compute(),
	waves = { 10, 20, 30 },
	mixed = { 1, label = true, "two" },
})
]]

const NESTED = [[
backstage.config("pet.drops", {
	rate = 1,
})
backstage.config("pet", {
	rate = 2,
})
]]

const BUILT = [[
const function item(price: number, weight: number)
	return {
		stock = 10,
		price = price,
		weight = weight,
	}
end

backstage.config("shop", {
	items = {
		item(10, 2),
		item(25, 5),
	},
})
]]

const KEYED = [[
backstage.config("skin", {
	{ rarity = "common" },
	[10] = {
		rarity = "legendary",
	},
	[8] = { rarity = "rare" },
	["wide key"] = { size = 3 },
})
]]

const CAST = [[
backstage.config("skin", {
	one = {
		rarity = "legendary" :: rarity_data.name,
		size = 2 :: number,
	},
})
]]

const CONFIGS = [[
backstage.config("pets", {})
backstage.config("world", {})
backstage.button("jump")
]]

--// Specs
return {
	finds_a_top_level_number = function()
		const found = locate.locate(SOURCE, "pets.speed")
		assert(found and found.tag == "number")
		assert(found.range.begin_line == 2)
	end,

	finds_a_nested_value = function()
		const found = locate.locate(SOURCE, "pets.trail.length")
		assert(found and found.tag == "number")
		assert(found.range.begin_line == 7)
	end,

	accepts_boolean_string_and_call = function()
		const flag = locate.locate(SOURCE, "pets.enabled")
		const label = locate.locate(SOURCE, "pets.label")
		const color = locate.locate(SOURCE, "pets.color")

		assert(flag and flag.tag == "boolean")
		assert(label and label.tag == "string")
		assert(color and color.tag == "call")
	end,

	accepts_a_negative_number = function()
		const found = locate.locate(SOURCE, "pets.offset")
		assert(found and found.tag == "unary")
	end,

	finds_an_item_of_a_list_by_position = function()
		const found = locate.locate(SOURCE, "pets.waves.2")
		assert(found and found.tag == "number")
		assert(found.range.begin_line == 9)
	end,

	counts_only_list_items_by_position = function()
		const found = locate.locate(SOURCE, "pets.mixed.2")
		assert(found and found.tag == "string")
	end,

	finds_a_value_by_a_key_in_brackets = function()
		const found = locate.locate(KEYED, "skin.10.rarity")
		assert(found and found.tag == "string")
		assert(found.range.begin_line == 4)
	end,

	keeps_list_items_working_next_to_keys_in_brackets = function()
		const first = locate.locate(KEYED, "skin.1.rarity")
		const bracket = locate.locate(KEYED, "skin.8.rarity")

		assert(first and first.range.begin_line == 2)
		assert(bracket and bracket.range.begin_line == 6)
	end,

	finds_a_value_by_a_string_key_in_brackets = function()
		const found = locate.locate(KEYED, "skin.wide key.size")
		assert(found and found.tag == "number")
	end,

	treats_a_value_with_a_cast_as_a_literal = function()
		const found = locate.locate(CAST, "skin.one.rarity")
		assert(found and found.tag == "string")
		assert(found.range.begin_line == 3)
	end,

	points_the_range_at_the_value_and_not_at_the_cast = function()
		const found = locate.locate(CAST, "skin.one.rarity")
		assert(found)
		assert(
			string.sub(string.split(CAST, "\n")[3], found.range.begin_column, found.range.end_column - 1)
				== '"legendary"'
		)
	end,

	finds_a_cast_value_by_the_scan = function()
		const found = locate.literals(CAST)
		assert(found["skin.one.rarity"] and found["skin.one.rarity"].tag == "string")
		assert(found["skin.one.size"] and found["skin.one.size"].tag == "number")
	end,

	refuses_a_position_past_the_list = function()
		const found = locate.locate(SOURCE, "pets.waves.4")
		assert(found == nil)
	end,

	refuses_a_value_that_is_not_a_literal = function()
		const found, reason = locate.locate(SOURCE, "pets.dynamic")
		assert(found == nil)
		assert(reason == '"pets.dynamic" is not a literal')
	end,

	refuses_an_unknown_config = function()
		const found, reason = locate.locate(SOURCE, "cats.speed")
		assert(found == nil)
		assert(reason == 'config "cats" not found')
	end,

	refuses_an_unknown_key = function()
		const found, reason = locate.locate(SOURCE, "pets.missing")
		assert(found == nil)
		assert(reason == '"missing" not found in the defaults')
	end,

	refuses_a_path_through_a_value = function()
		const found = locate.locate(SOURCE, "pets.speed.deeper")
		assert(found == nil)
	end,

	finds_a_value_of_a_config_named_with_dots = function()
		const found = locate.locate(NESTED, "pet.drops.rate")
		assert(found and found.tag == "number")
		assert(found.range.begin_line == 2)
	end,

	prefers_the_longest_config_name = function()
		const found = locate.locate(NESTED, "pet.rate")
		assert(found and found.range.begin_line == 5)
	end,

	owning_name_matches_whole_segments_only = function()
		assert(locate.owning_name({ "pet" }, "pets.speed") == nil)
		assert(locate.owning_name({ "pet", "pet.drops" }, "pet.drops.rate") == "pet.drops")
	end,

	follows_a_parameter_to_the_argument_of_the_call = function()
		const found = locate.locate(BUILT, "shop.items.2.price")
		assert(found and found.tag == "number")
		assert(found.range.begin_line == 12)
	end,

	finds_a_literal_inside_the_function_body = function()
		const first = locate.locate(BUILT, "shop.items.1.stock")
		const second = locate.locate(BUILT, "shop.items.2.stock")

		assert(first and second and first.range.begin_line == 3)
		assert(first.range.begin_column == second.range.begin_column)
	end,

	follows_the_key_to_the_argument_even_when_the_parameter_has_another_name = function()
		const source = [[
local function item(another_thing)
	return { price = another_thing }
end

backstage.config("shop", { sword = item(10) })
]]

		const found = locate.locate(source, "shop.sword.price")
		assert(found and found.tag == "number")
		assert(found.range.begin_line == 5)
		assert(locate.locate(source, "shop.sword.another_thing") == nil)
	end,

	refuses_a_call_to_something_that_is_not_a_local_function = function()
		const found, reason = locate.locate('backstage.config("a", { b = make(1) })', "a.b.c")
		assert(found == nil)
		assert(reason == '"c" is inside a call that does not return a table literal')
	end,

	config_names_lists_every_config_call = function()
		const names = locate.config_names(CONFIGS)
		table.sort(names)
		assert(#names == 2 and names[1] == "pets" and names[2] == "world")
	end,

	config_names_skips_a_name_that_is_not_a_string = function()
		assert(#locate.config_names "backstage.config(name, {})" == 0)
	end,

	config_names_reports_the_line_of_a_name_that_is_not_a_string = function()
		const names, dynamic = locate.config_names "local a = 1\nbackstage.config(name, {})"
		assert(#names == 0)
		assert(#dynamic == 1 and dynamic[1] == 2)
	end,
}
