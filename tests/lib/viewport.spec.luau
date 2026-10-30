--// Services
const ReplicatedStorage = game:GetService "ReplicatedStorage"

--// Utils
const viewport = require(ReplicatedStorage.backstage.ui.utils.viewport)

--// Functions
const function uniform(count: number, height: number)
	const heights = {}

	for _ = 1, count do
		table.insert(heights, height)
	end

	return viewport.measure(heights)
end

--// Specs
return {
	measure_stacks_the_rows_and_sums_the_total = function()
		const layout = viewport.measure { 10, 20, 30 }
		assert(layout.tops[1] == 0)
		assert(layout.tops[2] == 10)

		assert(layout.tops[3] == 30)
		assert(layout.total == 60)
	end,

	index_at_finds_the_row_under_a_height = function()
		const layout = viewport.measure { 10, 20, 30 }
		assert(viewport.index_at(layout, 0) == 1)
		assert(viewport.index_at(layout, 9.9) == 1)

		assert(viewport.index_at(layout, 10) == 2)
		assert(viewport.index_at(layout, 59) == 3)
		assert(viewport.index_at(layout, 500) == 3)
	end,

	visible_covers_the_viewport_and_the_overscan = function()
		const layout = uniform(100, 10)
		const range = viewport.visible(layout, 200, 50, 20)

		assert(range.first == 19)
		assert(range.last == 28)
	end,

	visible_never_goes_before_the_first_row = function()
		const layout = uniform(100, 10)
		const range = viewport.visible(layout, 0, 50, 30)

		assert(range.first == 1)
		assert(range.last == 9)
	end,

	visible_stops_at_the_last_row = function()
		const layout = uniform(5, 10)
		const range = viewport.visible(layout, 0, 1000, 0)

		assert(range.first == 1)
		assert(range.last == 5)
	end,

	visible_of_nothing_is_an_empty_range = function()
		const range = viewport.visible(viewport.measure {}, 0, 100, 10)
		assert(range.last < range.first)
	end,

	top_of_a_missing_row_is_the_total = function()
		const layout = viewport.measure { 10, 10 }
		assert(viewport.top_of(layout, 2) == 10)
		assert(viewport.top_of(layout, 3) == 20)
	end,
}
