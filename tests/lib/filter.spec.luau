--// Services
const ReplicatedStorage = game:GetService "ReplicatedStorage"

--// Utils
const filter = require(ReplicatedStorage.backstage.ui.utils.filter)

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

	without_a_search_everything_shows = function()
		reset()

		const row = filter.leaf({ "name" }, "petals.1.name")
		const group = filter.branch("1", {}, {})
		assert(row.shown() and group.shown())
	end,
}
