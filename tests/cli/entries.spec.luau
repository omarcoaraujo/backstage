--// Modules
const entries = require "../../cli/entries"

--// Constants
const CATALOG = [[
backstage.config("shop", {
	[1] = { rarity = "common", price = 100 },
	[2] = { rarity = "rare", price = 500 }, -- keep
})
]]

const WITHOUT_TRAILING_COMMA = [[
backstage.config("shop", {
	[1] = { price = 100 },
	[2] = { price = 500 } -- keep
})
]]

const INLINE = [[
backstage.config("pets", {
	trail = { a = 1, b = 2, c = 3 },
})
]]

const LIST = [[
backstage.config("shop", {
	prices = {
		10,
		20,
	},
})
]]

const NAMED = [[
backstage.config("shop", {
	cheap = { price = 1 },
	dear = { price = 9 },
})
]]

const GAP = [[
backstage.config("shop", {
	[1] = { scale = 1 },
	[10] = { scale = 3 }, -- keep
})
]]

const GAP_INLINE = [[
backstage.config("shop", { [1] = 1, [9] = 9 })
]]

const UNSORTED = [[
backstage.config("shop", {
	dear = { price = 9 },
	cheap = { price = 1 },
})
]]

const EMPTY = [[
backstage.config("shop", {})
]]

const EMPTY_MULTILINE = [[
backstage.config("shop", {
})
]]

const SINGLE = [[
backstage.config("shop", {
	[1] = { price = 100 },
})
]]

const SINGLE_INLINE = [[
backstage.config("pets", {
	trail = { a = 1 },
})
]]

--// Functions
const function mentions(reason: string?, text: string)
	return reason ~= nil and string.find(reason, text, 1, true) ~= nil
end

--// Specs
return {
	add_copies_the_sibling_below_the_last_entry = function()
		const result, reason = entries.add(CATALOG, "shop.3", "shop.2")

		assert(reason == nil)
		assert(result == [[
backstage.config("shop", {
	[1] = { rarity = "common", price = 100 },
	[2] = { rarity = "rare", price = 500 }, -- keep
	[3] = { rarity = "rare", price = 500 },
})
]])
	end,

	remove_hands_back_what_it_cut_and_what_followed_it = function()
		const _, _, removed = entries.remove(NAMED, "shop.cheap")
		assert(removed ~= nil)

		assert(removed.text == "cheap = { price = 1 }")
		assert(removed.following == "dear")
	end,

	restore_puts_an_entry_back_where_it_was = function()
		const first, _, removed_first = entries.remove(NAMED, "shop.cheap")
		const restored_first = entries.restore(first :: string, "shop.cheap", removed_first :: entries.removed)
		assert(restored_first == NAMED)

		const last, _, removed_last = entries.remove(NAMED, "shop.dear")
		const restored_last = entries.restore(last :: string, "shop.dear", removed_last :: entries.removed)
		assert(restored_last == NAMED)
	end,

	restore_puts_an_entry_back_in_a_table_left_empty = function()
		const emptied, _, removed = entries.remove(SINGLE, "shop.1")
		assert(emptied == EMPTY_MULTILINE)

		const restored = entries.restore(emptied :: string, "shop.1", removed :: entries.removed)
		assert(restored == SINGLE)
	end,

	restore_puts_an_entry_back_in_a_table_left_empty_on_one_line = function()
		const emptied, _, removed = entries.remove(SINGLE_INLINE, "pets.trail.a")
		const restored = entries.restore(emptied :: string, "pets.trail.a", removed :: entries.removed)
		assert(restored == SINGLE_INLINE)
	end,

	restore_refuses_an_entry_that_is_already_there = function()
		const _, _, removed = entries.remove(NAMED, "shop.cheap")
		const result, reason = entries.restore(NAMED, "shop.cheap", removed :: entries.removed)

		assert(result == nil)
		assert(mentions(reason, "already exists"))
	end,

	add_keeps_numeric_keys_in_order = function()
		const result, reason = entries.add(GAP, "shop.8", "shop.10")

		assert(reason == nil)
		assert(result == [[
backstage.config("shop", {
	[1] = { scale = 1 },
	[8] = { scale = 3 },
	[10] = { scale = 3 }, -- keep
})
]])
	end,

	add_keeps_numeric_keys_in_order_on_one_line = function()
		const result = entries.add(GAP_INLINE, "shop.5", "shop.9")
		assert(result == [[
backstage.config("shop", { [1] = 1, [5] = 9, [9] = 9 })
]])
	end,

	add_keeps_the_order_of_a_table_that_is_not_sorted = function()
		const result = entries.add(UNSORTED, "shop.mid", "shop.dear")
		assert(result == [[
backstage.config("shop", {
	dear = { price = 9 },
	cheap = { price = 1 },
	mid = { price = 9 },
})
]])
	end,

	add_copies_the_template_that_was_asked_for = function()
		const result = entries.add(CATALOG, "shop.7", "shop.1")

		assert(result ~= nil)
		assert(string.find(result :: string, '[7] = { rarity = "common", price = 100 },', 1, true))
	end,

	add_puts_a_comma_after_a_last_entry_that_had_none = function()
		const result = entries.add(WITHOUT_TRAILING_COMMA, "shop.3", "shop.2")

		assert(result == [[
backstage.config("shop", {
	[1] = { price = 100 },
	[2] = { price = 500 }, -- keep
	[3] = { price = 500 },
})
]])
	end,

	add_inside_a_table_on_one_line = function()
		const result = entries.add(INLINE, "pets.trail.d", "pets.trail.c")
		assert(string.find(result :: string, "{ a = 1, b = 2, c = 3, d = 3 }", 1, true))
	end,

	add_names_a_new_key_like_the_template = function()
		const result = entries.add(NAMED, "shop.average", "shop.dear")
		assert(string.find(result :: string, "\taverage = { price = 9 },", 1, true))
	end,

	add_writes_a_key_with_symbols_between_brackets = function()
		const result = entries.add(NAMED, "shop.extra-large", "shop.dear")
		assert(string.find(result :: string, '\t["extra-large"] = { price = 9 },', 1, true))
	end,

	add_appends_to_a_list_without_keys = function()
		const result = entries.add(LIST, "shop.prices.3", "shop.prices.2")
		assert(result == [[
backstage.config("shop", {
	prices = {
		10,
		20,
		20,
	},
})
]])
	end,

	add_refuses_to_skip_a_position_in_a_list_without_keys = function()
		const result, reason = entries.add(LIST, "shop.prices.5", "shop.prices.2")
		assert(result == nil)
		assert(mentions(reason, "next position"))
	end,

	add_keeps_the_line_endings_of_the_file = function()
		const crlf = string.gsub(CATALOG, "\n", "\r\n")
		const result = entries.add(crlf, "shop.3", "shop.2")
		assert(
			string.find(result :: string, '500 }, -- keep\r\n\t[3] = { rarity = "rare", price = 500 },\r\n})', 1, true)
		)
	end,

	add_refuses_an_entry_that_already_exists = function()
		const result, reason = entries.add(CATALOG, "shop.2", "shop.1")
		assert(result == nil)
		assert(mentions(reason, "already exists"))
	end,

	add_refuses_a_template_that_is_not_a_sibling = function()
		const result, reason = entries.add(CATALOG, "shop.3", "shop.2.price")
		assert(result == nil)
		assert(mentions(reason, "is not next to"))
	end,

	add_copies_the_first_entry_when_the_template_is_no_longer_in_the_script = function()
		const result, reason = entries.add(CATALOG, "shop.3", "shop.9")
		assert(reason == nil)
		assert(string.find(result :: string, '[3] = { rarity = "common", price = 100 },', 1, true))
	end,

	add_refuses_a_config_that_is_not_in_the_script = function()
		const result, reason = entries.add(CATALOG, "other.3", "other.2")
		assert(result == nil)
		assert(mentions(reason, "not found"))
	end,

	remove_takes_the_whole_line_with_its_comment = function()
		const result, reason = entries.remove(CATALOG, "shop.2")
		assert(reason == nil)
		assert(result == [[
backstage.config("shop", {
	[1] = { rarity = "common", price = 100 },
})
]])
	end,

	remove_takes_one_entry_of_a_table_on_one_line = function()
		const result = entries.remove(INLINE, "pets.trail.b")
		assert(string.find(result :: string, "{ a = 1, c = 3 }", 1, true))
	end,

	remove_takes_the_last_entry_of_a_table_on_one_line = function()
		const result = entries.remove(INLINE, "pets.trail.c")
		assert(string.find(result :: string, "{ a = 1, b = 2 }", 1, true))
	end,

	remove_takes_the_last_item_of_a_list_without_keys = function()
		const result = entries.remove(LIST, "shop.prices.2")
		assert(result == [[
backstage.config("shop", {
	prices = {
		10,
	},
})
]])
	end,

	remove_refuses_an_item_that_would_renumber_a_list = function()
		const result, reason = entries.remove(LIST, "shop.prices.1")
		assert(result == nil)
		assert(mentions(reason, "renumber"))
	end,

	remove_refuses_an_entry_that_is_not_in_the_script = function()
		const result, reason = entries.remove(CATALOG, "shop.9")
		assert(result == nil)
		assert(mentions(reason, "not found"))
	end,

	add_refuses_an_empty_table_because_there_is_no_template = function()
		const result, reason = entries.add(EMPTY, "shop.1", "shop.2")
		assert(result == nil)
		assert(mentions(reason, "not found"))
	end,

	add_refuses_an_empty_table_over_several_lines = function()
		const result, reason = entries.add(EMPTY_MULTILINE, "shop.1", "shop.2")
		assert(result == nil)
		assert(mentions(reason, "not found"))
	end,

	remove_refuses_from_an_empty_table = function()
		const result, reason = entries.remove(EMPTY, "shop.1")
		assert(result == nil)
		assert(mentions(reason, "not found"))
	end,

	remove_leaves_an_empty_table_when_the_only_entry_goes = function()
		const result = entries.remove(SINGLE, "shop.1")
		assert(result == EMPTY_MULTILINE)
	end,

	remove_leaves_an_empty_table_on_one_line_when_the_only_entry_goes = function()
		const result = entries.remove(SINGLE_INLINE, "pets.trail.a")
		assert(string.find(result :: string, "trail = {  },", 1, true))
	end,
}
