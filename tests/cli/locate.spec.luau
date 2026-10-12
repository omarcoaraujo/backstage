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

	config_names_lists_every_config_call = function()
		const names = locate.config_names(CONFIGS)
		table.sort(names)
		assert(#names == 2 and names[1] == "pets" and names[2] == "world")
	end,

	config_names_skips_a_name_that_is_not_a_string = function()
		assert(#locate.config_names "backstage.config(name, {})" == 0)
	end,
}
