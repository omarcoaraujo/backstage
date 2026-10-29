--// Services
const ReplicatedStorage = game:GetService "ReplicatedStorage"

--// Modules
const backstage = require(ReplicatedStorage.backstage)
const mode = require(ReplicatedStorage.backstage.core.mode)
const registry = require(ReplicatedStorage.backstage.core.registry)

--// Utils
const fixtures = require(ReplicatedStorage.bench.fixtures)
const harness = require(ReplicatedStorage.bench.harness)

--// Constants
const GROUP_SIZE = 10
const CATALOG_CHURN = 20

--// Functions
const function flat(size: number)
	const defaults = {} :: { [string]: number }

	for index = 1, size do
		defaults[`f{index}`] = index
	end

	return defaults
end

const function nested(size: number)
	const defaults = {} :: { [string]: { [string]: number } }

	for index = 1, size do
		const group = `g{math.ceil(index / GROUP_SIZE)}`
		defaults[group] = defaults[group] or {}
		defaults[group][`f{index}`] = index
	end

	return defaults
end

const function catalog(size: number)
	const items = {} :: { [number]: { price: number, weight: number } }

	for index = 1, size do
		items[index] = { price = index, weight = 1 }
	end

	return items
end

const function declare_union(size: number)
	fixtures.fresh()

	return backstage.config("pets", {
		pick = backstage.union("kind", fixtures.variant("a", size), fixtures.variant("b", size)),
	})
end

const function declare_catalog(size: number)
	fixtures.fresh()
	backstage.config("skins", catalog(size), {
		limits = backstage.each { price = { min = 0, max = 500 } },
	})
end

--// End
return {
	flat_fields = function(size)
		fixtures.fresh()
		const defaults = flat(size)

		return function()
			backstage.config("pets", defaults)
		end
	end,

	nested_groups = function(size)
		fixtures.fresh()
		const defaults = nested(size)

		return function()
			backstage.config("pets", defaults)
		end
	end,

	production_copy = function(size)
		fixtures.fresh()
		mode.disable()
		const defaults = nested(size)

		return function()
			backstage.config("pets", defaults)
		end, function()
			mode.restore()
		end
	end,

	catalog_with_limits = function(size)
		fixtures.fresh()
		const items = catalog(size)

		return function()
			backstage.config("skins", items, {
				limits = backstage.each { price = { min = 0, max = 500 } },
			})
		end
	end,

	catalog_adds_and_removes_items = function(size)
		declare_catalog(size)

		return function()
			for index = 1, CATALOG_CHURN do
				registry.add_item("skins", tostring(size + index))
			end

			for index = 1, CATALOG_CHURN do
				registry.remove_item("skins", tostring(size + index))
			end
		end
	end,

	union_declare = function(size)
		fixtures.fresh()

		return function()
			declare_union(size)
		end
	end,

	union_switches_variant = function(size)
		declare_union(size)

		return function()
			registry.set("pets.pick.kind", "b")
		end
	end,
} :: harness.suite
