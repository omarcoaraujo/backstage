--// Services
const ReplicatedStorage = game:GetService "ReplicatedStorage"

--// Packages
const vide = require(ReplicatedStorage.roblox_packages.vide)

--// Utils
const filters = require(ReplicatedStorage.backstage.ui.utils.filter)

--// Variables
const filter = filters.create()

--// Functions
const function search(text: string)
	filter.query(text)
end

const function reset()
	filter.query ""
	filter.clear_texts()
end

--// Specs
return {
	a_text_row_is_found_by_its_value = function()
		reset()
		filter.set_text("petals.1.name", "Dew Petal")

		const row = filter.leaf({ "name" }, "petals.1.name")
		search "dew petal"

		assert(row.shown())
		reset()
	end,

	a_text_row_is_not_found_by_another_value = function()
		reset()
		filter.set_text("petals.1.name", "Dew Petal")

		const row = filter.leaf({ "name" }, "petals.1.name")
		search "sun"

		assert(not row.shown())
		reset()
	end,

	a_group_is_found_by_the_text_below_it = function()
		reset()
		filter.set_text("petals.1.name", "Dew Petal")

		const group = filter.branch("1", { "name", "boost" }, { "petals.1.name" })
		search "DEW"

		assert(group.shown())
		search "sun"
		assert(not group.shown())
		reset()
	end,

	editing_the_text_changes_what_the_search_finds = function()
		reset()
		filter.set_text("petals.1.name", "Dew Petal")

		const group = filter.branch("1", {}, { "petals.1.name" })
		search "sun"
		assert(not group.shown())

		filter.set_text("petals.1.name", "Sun Petal")
		assert(group.shown())
		reset()
	end,

	replacing_the_texts_updates_the_search_once = function()
		reset()
		search "sun"

		const group = filter.branch("1", {}, { "petals.1.name", "petals.2.name" })
		local runs = 0

		const destroy = vide.root(function()
			vide.effect(function()
				group.shown()
				runs += 1
			end)
		end)

		const before = runs
		filter.replace_texts { ["petals.1.name"] = "Dew", ["petals.2.name"] = "Sun" }

		assert(runs == before + 1)
		assert(group.shown())

		destroy()
		reset()
	end,

	replacing_the_texts_without_a_search_does_not_update = function()
		reset()

		const group = filter.branch("1", {}, { "petals.1.name" })
		local runs = 0

		const destroy = vide.root(function()
			vide.effect(function()
				group.shown()
				runs += 1
			end)
		end)

		const before = runs
		filter.replace_texts { ["petals.1.name"] = "Dew" }
		assert(runs == before)

		destroy()
		reset()
	end,

	without_a_search_everything_shows = function()
		reset()

		const row = filter.leaf({ "name" }, "petals.1.name")
		const group = filter.branch("1", {}, {})
		assert(row.shown() and group.shown())
	end,

	two_searches_keep_their_own_query_and_texts = function()
		reset()
		const other = filters.create()

		filter.set_text("petals.1.name", "Dew Petal")
		other.set_text("petals.1.name", "Sun Petal")

		const mine = filter.leaf({ "name" }, "petals.1.name")
		const theirs = other.leaf({ "name" }, "petals.1.name")

		search "sun"
		assert(not mine.shown() and theirs.shown())
		assert(filter.searching() and not other.searching())

		other.query "dew"
		assert(not mine.shown() and not theirs.shown())

		assert(filter.query() == "sun" and other.query() == "dew")
		reset()
	end,
}
