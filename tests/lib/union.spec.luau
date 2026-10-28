--// Services
const ReplicatedStorage = game:GetService "ReplicatedStorage"

--// Modules
const backstage = require(ReplicatedStorage.backstage)
const mode = require(ReplicatedStorage.backstage.core.mode)
const registry = require(ReplicatedStorage.backstage.core.registry)

--// Functions
const function fresh()
	registry.reset()
	mode.enable()
end

const function declare()
	return backstage.config("pets", {
		pick = backstage.union(
			"kind",
			{ kind = "coin" :: "coin", amount = 3 },
			{ kind = "skin" :: "skin", skin_id = "" }
		),
	})
end

const function loose(pets: unknown): { pick: any }
	return pets :: any
end

const function paths()
	const found = {}

	for _, entry in registry.list() do
		table.insert(found, entry.path)
	end

	return found
end

--// Specs
return {
	starts_on_the_first_variant = function()
		fresh()
		const pets = loose(declare())

		assert(pets.pick.kind == "coin")
		assert(pets.pick.amount == 3)
		assert(pets.pick.skin_id == nil)

		const entry = registry.list()[1]
		assert(entry.path == "pets.pick.amount")
	end,

	the_discriminant_is_a_choice_of_the_variants = function()
		fresh()
		declare()

		for _, entry in registry.list() do
			if entry.path ~= "pets.pick.kind" then continue end

			assert(entry.descriptor.kind == "choice")
			assert(table.concat(entry.descriptor.choices :: { string }, ",") == "coin,skin")
			return
		end

		error "discriminant not registered"
	end,

	switching_the_discriminant_swaps_the_fields = function()
		fresh()
		const pets = loose(declare())

		assert(registry.set("pets.pick.kind", "skin"))
		assert(pets.pick.kind == "skin")

		assert(pets.pick.skin_id == "")
		assert(pets.pick.amount == nil)
		assert(table.concat(paths(), ",") == "pets.pick.kind,pets.pick.skin_id")
	end,

	switching_back_keeps_what_was_edited = function()
		fresh()
		const pets = loose(declare())

		registry.set("pets.pick.amount", 9)
		registry.set("pets.pick.kind", "skin")

		registry.set("pets.pick.skin_id", "gold")
		registry.set("pets.pick.kind", "coin")

		assert(pets.pick.amount == 9)
		registry.set("pets.pick.kind", "skin")
		assert(pets.pick.skin_id == "gold")
	end,

	switching_announces_the_new_shape = function()
		fresh()
		declare()

		local announced = 0
		registry.on_register(function()
			announced += 1
		end)

		registry.set("pets.pick.kind", "skin")
		assert(announced == 1)
	end,

	an_unlisted_variant_is_refused = function()
		fresh()
		const pets = loose(declare())

		assert(not registry.set("pets.pick.kind", "gem"))
		assert(pets.pick.kind == "coin")
	end,

	changing_the_variant_makes_the_group_dirty = function()
		fresh()
		declare()

		assert(not registry.dirty "pets")
		registry.set("pets.pick.kind", "skin")
		assert(registry.dirty "pets")
	end,

	restoring_the_group_brings_the_variant_back = function()
		fresh()
		const pets = loose(declare())

		registry.set("pets.pick.amount", 9)
		registry.set("pets.pick.kind", "skin")
		registry.restore_group "pets"

		assert(pets.pick.kind == "coin")
		assert(pets.pick.amount == 3)
		assert(not registry.dirty "pets")
	end,

	committing_keeps_the_new_variant = function()
		fresh()
		const pets = loose(declare())

		registry.set("pets.pick.kind", "skin")
		registry.apply_commit "pets"

		assert(not registry.dirty "pets")
		registry.restore_group "pets"
		assert(pets.pick.kind == "skin")
	end,

	listeners_hear_the_discriminant_change = function()
		fresh()
		declare()

		local heard = nil :: string?
		registry.on_change(function(path, value)
			if path == "pets.pick.kind" then heard = value :: string end
		end)

		registry.set("pets.pick.kind", "skin")
		assert(heard == "skin")
	end,

	the_snapshot_lists_the_unions_and_the_import_drops_old_fields = function()
		fresh()
		declare()

		const before = registry.snapshot()
		assert(table.concat(before.unions :: { string }, ",") == "pets.pick")

		registry.set("pets.pick.kind", "skin")
		const after = registry.snapshot()

		registry.reset()
		registry.import(before)
		assert(table.concat(paths(), ",") == "pets.pick.amount,pets.pick.kind")

		registry.import(after)
		assert(table.concat(paths(), ",") == "pets.pick.kind,pets.pick.skin_id")
	end,

	a_union_needs_two_variants_with_distinct_names = function()
		fresh()

		const raw = backstage.union :: any
		assert(not pcall(raw, "kind", { kind = "coin" }))

		assert(not pcall(raw, "kind", { kind = "coin" }, { kind = "coin" }))
		assert(not pcall(raw, "kind", { kind = "coin" }, { amount = 1 }))
	end,

	production_reads_the_first_variant = function()
		registry.reset()
		mode.disable()

		const pets = loose(declare())
		mode.enable()

		assert(pets.pick.kind == "coin" and pets.pick.amount == 3)
		assert(table.isfrozen(pets.pick))
		assert(#registry.list() == 0)
	end,
}
