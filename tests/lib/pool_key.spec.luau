--// Services
const ReplicatedStorage = game:GetService "ReplicatedStorage"

--// Modules
const kinds = require(ReplicatedStorage.backstage.core.kinds)
const registry = require(ReplicatedStorage.backstage.core.registry)

--// Utils
const flatten = require(ReplicatedStorage.backstage.ui.utils.flatten)
const pool_key = require(ReplicatedStorage.backstage.ui.utils.pool_key)

--// Functions
const function entry_row(path: string, group: string, default: kinds.value, depth: number): flatten.row
	const descriptor = kinds.infer(default) :: kinds.descriptor

	return {
		kind = "entry",
		path = path,
		name = path,

		depth = depth,
		guides = {},

		owner = group,
		expanded = false,
		entry = {
			path = path,
			name = path,
			group = group,

			descriptor = descriptor,
			default = default,

			value = default,
			remote = false,
		},
	}
end

const function group_row(path: string, depth: number): flatten.row
	return {
		kind = "group",
		path = path,
		name = path,

		depth = depth,
		guides = {},

		owner = path,
		expanded = false,
	}
end

--// End
return {
	entries_of_the_same_shape_share_a_key_whatever_the_path_and_value = function()
		registry.reset()
		assert(pool_key.of_row(entry_row("a.x", "a", 1, 1)) == pool_key.of_row(entry_row("b.y", "b", 7, 1)))
	end,

	entries_of_other_kinds_or_depths_get_other_keys = function()
		registry.reset()
		const number = pool_key.of_row(entry_row("a.x", "a", 1, 1))

		assert(number ~= pool_key.of_row(entry_row("a.x", "a", "text", 1)))
		assert(number ~= pool_key.of_row(entry_row("a.x", "a", 1, 2)))
	end,

	entries_with_other_limits_get_other_keys = function()
		registry.reset()
		const first = entry_row("a.x", "a", 1, 1)
		const second = entry_row("a.y", "a", 1, 1)

		assert(first.entry and second.entry)
		first.entry.descriptor = { kind = "number", min = 0, max = 10 }

		second.entry.descriptor = { kind = "number", min = 0, max = 20 }
		assert(pool_key.of_row(first) ~= pool_key.of_row(second))
	end,

	groups_are_pooled_by_depth = function()
		registry.reset()
		assert(pool_key.of_row(group_row("a", 0)) == pool_key.of_row(group_row("b", 0)))
		assert(pool_key.of_row(group_row("a", 0)) ~= pool_key.of_row(group_row("a.b", 1)))
	end,

	buttons_and_new_entry_rows_are_not_pooled = function()
		assert(pool_key.of_row {
			kind = "buttons",
			path = "a#buttons",
			name = "buttons",

			depth = 1,
			guides = {},

			owner = "a",
			expanded = false,
		} == nil)

		assert(pool_key.of_row {
			kind = "adding",
			path = "a",
			name = "a",

			depth = 1,
			guides = {},

			owner = "a",
			expanded = false,
		} == nil)
	end,
}
