--// Services
const ReplicatedStorage = game:GetService "ReplicatedStorage"

--// Modules
const registry = require(ReplicatedStorage.backstage.core.registry)

--// Utils
const branch = require(ReplicatedStorage.backstage.ui.utils.branch)

--// Functions
const function with_children(entry_names: { string }, group_names: { string })
	const source = branch.create()

	for _, name in entry_names do
		table.insert(source.entries, { name = name } :: any)
	end

	for _, name in group_names do
		source.groups[name] = branch.create()
	end

	return source
end

--// Specs
return {
	next_key_follows_the_highest_numeric_child = function()
		assert(branch.next_key(with_children({}, { "1", "8", "10" })) == "11")
		assert(branch.next_key(with_children({ "1", "2" }, {})) == "3")
		assert(branch.next_key(with_children({ "1" }, { "7" })) == "8")
	end,

	next_key_is_empty_when_the_children_are_named = function()
		assert(branch.next_key(with_children({}, { "follow", "orbit" })) == "")
		assert(branch.next_key(with_children({}, {})) == "")
	end,

	a_dense_numbered_branch_is_a_list = function()
		assert(branch.is_list(with_children({ "1", "2", "3" }, {})))
		assert(branch.is_list(with_children({}, { "1", "2", "3" })))
		assert(branch.is_list(with_children({ "1" }, { "2" })))
	end,

	a_branch_with_gaps_or_names_is_not_a_list = function()
		assert(not branch.is_list(with_children({}, { "1", "8", "10" })))
		assert(not branch.is_list(with_children({}, { "follow", "orbit" })))
		assert(not branch.is_list(with_children({}, {})))
	end,

	collect_groups_entries_by_their_group_path = function()
		registry.reset()
		registry.add("shop.skins.1.price", "price", "shop.skins.1", { kind = "number" } :: any, 100, nil)

		const root = branch.collect()
		assert(#root.groups.shop.groups.skins.groups["1"].entries == 1)
		registry.reset()
	end,

	collect_puts_the_leading_entry_first_and_keeps_the_rest_alphabetical = function()
		registry.reset()
		registry.add("fx.intensity", "intensity", "fx", { kind = "number" } :: any, 1, nil)

		registry.add("fx.kind", "kind", "fx", { kind = "string" } :: any, "glow", nil)
		registry.add("fx.radius", "radius", "fx", { kind = "number" } :: any, 1, nil)
		registry.lead "fx.kind"

		const names = {}
		for _, entry in branch.collect().groups.fx.entries do
			table.insert(names, entry.name)
		end

		assert(table.concat(names, ",") == "kind,intensity,radius")
		registry.reset()
	end,

	the_snapshot_keeps_the_leading_entry = function()
		registry.reset()
		registry.add("fx.kind", "kind", "fx", { kind = "string" } :: any, "glow", nil)
		registry.lead "fx.kind"

		const sent = registry.snapshot()
		registry.reset()
		registry.import(sent)

		assert(registry.list()[1].leading == true)
		registry.reset()
	end,
}
