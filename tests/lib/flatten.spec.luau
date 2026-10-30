--// Services
const ReplicatedStorage = game:GetService "ReplicatedStorage"

--// Modules
const button = require(ReplicatedStorage.backstage.core.button)
const kinds = require(ReplicatedStorage.backstage.core.kinds)
const registry = require(ReplicatedStorage.backstage.core.registry)

--// Utils
const branch = require(ReplicatedStorage.backstage.ui.utils.branch)
const flatten = require(ReplicatedStorage.backstage.ui.utils.flatten)

--// Functions
const function declare(path: string, name: string, group: string, default: kinds.value)
	registry.add(path, name, group, kinds.infer(default) :: kinds.descriptor, default)
end

const function inactive(): flatten.search
	return {
		active = false,

		name = function()
			return true
		end,

		text = function()
			return false
		end,
	}
end

const function searching(query: string): flatten.search
	return {
		active = true,

		name = function(name)
			return string.find(string.lower(name), query, 1, true) ~= nil
		end,

		text = function()
			return false
		end,
	}
end

const function state(search: flatten.search, opened: { [string]: boolean }?): flatten.state
	return { opened = opened or {}, closed = {}, adding = {}, search = search }
end

const function rows(current: flatten.state)
	return flatten.flatten(branch.collect(), current)
end

const function paths(list: { flatten.row })
	const result = {}

	for _, row in list do
		table.insert(result, row.path)
	end

	return result
end

const function guides(row: flatten.row)
	return table.concat(row.guides, ",")
end

const function reset()
	registry.reset()
end

--// Specs
return {
	closed_groups_list_only_their_headers = function()
		reset()
		declare("pets.speed", "speed", "pets", 1)
		declare("shop.price", "price", "shop", 1)

		const list = rows(state(inactive()))
		assert(table.concat(paths(list), " ") == "pets shop")
		reset()
	end,

	an_opened_group_lists_its_entries_then_its_child_groups = function()
		reset()
		declare("pets.speed", "speed", "pets", 1)

		declare("pets.trail.length", "length", "pets.trail", 1)
		declare("pets.size", "size", "pets", 1)

		const list = rows(state(inactive(), { pets = true }))
		assert(table.concat(paths(list), " ") == "pets pets.size pets.speed pets.trail")
		reset()
	end,

	rows_carry_their_depth_and_owning_group = function()
		reset()
		declare("pets.trail.length", "length", "pets.trail", 1)

		const list = rows(state(inactive(), { pets = true, ["pets.trail"] = true }))
		assert(list[3].path == "pets.trail.length")
		assert(list[3].depth == 2)

		assert(list[3].owner == "pets.trail")
		reset()
	end,

	the_guide_ends_at_the_last_entry_of_a_group = function()
		reset()
		declare("pets.a", "a", "pets", 1)
		declare("pets.b", "b", "pets", 1)

		const list = rows(state(inactive(), { pets = true }))
		assert(guides(list[2]) == "full")
		assert(guides(list[3]) == "end")
		reset()
	end,

	rows_under_the_last_child_group_have_no_guide_at_that_level = function()
		reset()
		declare("pets.a", "a", "pets", 1)
		declare("pets.trail.length", "length", "pets.trail", 1)

		const list = rows(state(inactive(), { pets = true, ["pets.trail"] = true }))
		assert(guides(list[2]) == "full")

		assert(guides(list[3]) == "end")
		assert(guides(list[4]) == "none,end")
		reset()
	end,

	a_search_lists_only_the_matching_entries_and_opens_their_groups = function()
		reset()
		declare("pets.speed", "speed", "pets", 1)

		declare("pets.size", "size", "pets", 1)
		declare("shop.price", "price", "shop", 1)

		const list = rows(state(searching "spe"))
		assert(table.concat(paths(list), " ") == "pets pets.speed")
		reset()
	end,

	a_group_that_matches_by_name_lists_everything_below_it = function()
		reset()
		declare("pets.speed", "speed", "pets", 1)
		declare("pets.trail.length", "length", "pets.trail", 1)

		const list = rows(state(searching "pet"))
		assert(table.concat(paths(list), " ") == "pets pets.speed pets.trail pets.trail.length")
		reset()
	end,

	a_closed_group_in_a_search_keeps_only_its_header = function()
		reset()
		declare("pets.speed", "speed", "pets", 1)

		const current = state(searching "spe")
		current.closed.pets = true

		const list = rows(current)
		assert(table.concat(paths(list), " ") == "pets")
		assert(not list[1].expanded)
		reset()
	end,

	a_search_with_no_match_lists_nothing = function()
		reset()
		declare("pets.speed", "speed", "pets", 1)

		assert(#rows(state(searching "zzz")) == 0)
		reset()
	end,

	the_adding_panel_comes_first_in_its_group = function()
		reset()
		declare("pets.speed", "speed", "pets", 1)

		const current = state(inactive(), { pets = true })
		current.adding.pets = true

		const list = rows(current)
		assert(list[2].kind == "adding")
		assert(list[3].path == "pets.speed")
		reset()
	end,

	buttons_come_after_the_entries_of_their_group = function()
		reset()
		declare("pets.speed", "speed", "pets", 1)

		registry.add_button("pets.reset", "reset", "pets", button.create())
		const list = rows(state(inactive(), { pets = true }))

		assert(list[2].kind == "entry")
		assert(list[3].kind == "buttons")
		reset()
	end,
}
