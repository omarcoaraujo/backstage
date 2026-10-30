--// Services
const ReplicatedStorage = game:GetService "ReplicatedStorage"

--// Modules
const button = require(ReplicatedStorage.backstage.core.button)
const kinds = require(ReplicatedStorage.backstage.core.kinds)
const registry = require(ReplicatedStorage.backstage.core.registry)

--// Utils
const branch = require(ReplicatedStorage.backstage.ui.utils.branch)
const flatten = require(ReplicatedStorage.backstage.ui.utils.flatten)
const row_space = require(ReplicatedStorage.backstage.ui.utils.row_space)
const viewport = require(ReplicatedStorage.backstage.ui.utils.viewport)

--// Constants
const HEIGHT = 10

--// Functions
const function declare(path: string, name: string, group: string)
	registry.add(path, name, group, kinds.infer(1) :: kinds.descriptor, 1)
end

const function built()
	const opened = { pets = true, ["pets.trail"] = true }

	const rows = flatten.flatten(branch.collect(), {
		opened = opened,
		closed = {},
		adding = {},

		search = {
			active = false,
			name = function()
				return true
			end,
			text = function()
				return false
			end,
		},
	})

	const heights = {}
	for _ = 1, #rows do
		table.insert(heights, HEIGHT)
	end

	return row_space.new(rows, viewport.measure(heights))
end

const function setup()
	registry.reset()
	declare("pets.a", "a", "pets")

	declare("pets.trail.length", "length", "pets.trail")
	registry.add_button("pets.go", "go", "pets", button.create())
end

--// Specs
return {
	a_height_over_an_entry_hits_that_entry_and_its_group = function()
		setup()

		const space = built()
		const found = space.hit(HEIGHT * 1 + 3)

		assert(found and found.group == "pets" and found.row == "pets.a" and found.top == HEIGHT)
		registry.reset()
	end,

	a_height_over_a_header_hits_the_group_without_a_row = function()
		setup()

		const space = built()
		const found = space.hit(2)

		assert(found and found.group == "pets" and found.row == nil and found.top == 0)
		registry.reset()
	end,

	a_height_over_the_buttons_hits_the_entry_above = function()
		setup()

		const space = built()
		const found = space.hit(HEIGHT * 2 + 1)

		assert(found and found.group == "pets" and found.row == "pets.a")
		registry.reset()
	end,

	a_height_over_a_child_group_hits_the_child = function()
		setup()

		const space = built()
		const found = space.hit(HEIGHT * 3 + 1)

		assert(found and found.group == "pets.trail" and found.row == nil)
		registry.reset()
	end,

	a_height_below_the_last_row_hits_the_last_row = function()
		setup()

		const space = built()
		const found = space.hit(HEIGHT * 50)

		assert(found and found.group == "pets.trail" and found.row == "pets.trail.length")
		registry.reset()
	end,

	the_top_of_a_row_comes_from_its_place_in_the_list = function()
		setup()

		const space = built()
		assert(space.top_of_row "pets.a" == HEIGHT)

		assert(space.top_of_row "pets.trail.length" == HEIGHT * 4)
		assert(space.top_of_row "missing" == nil)
		registry.reset()
	end,

	a_hidden_group_falls_back_to_the_nearest_shown_parent = function()
		setup()

		const space = built()
		assert(space.nearest_group_top "pets.trail" == HEIGHT * 3)

		assert(space.nearest_group_top "pets.trail.deep.more" == HEIGHT * 3)
		assert(space.nearest_group_top "shop" == nil)
		registry.reset()
	end,
}
