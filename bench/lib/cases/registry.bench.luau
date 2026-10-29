--// Services
const ReplicatedStorage = game:GetService "ReplicatedStorage"

--// Modules
const registry = require(ReplicatedStorage.backstage.core.registry)

--// Utils
const fixtures = require(ReplicatedStorage.bench.fixtures)
const harness = require(ReplicatedStorage.bench.harness)

--// Functions
const function declared(size: number)
	fixtures.fresh()
	fixtures.declare(size, true)
end

const function edited(size: number)
	declared(size)
	fixtures.edit_all(size)
end

--// End
return {
	declare = function(size)
		fixtures.fresh()

		return function()
			fixtures.declare(size, true)
		end
	end,

	list = function(size)
		declared(size)

		return function()
			registry.list()
		end
	end,

	snapshot = function(size)
		declared(size)

		return function()
			registry.snapshot()
		end
	end,

	import = function(size)
		const incoming = fixtures.snapshot(size)
		fixtures.fresh()

		return function()
			registry.import(incoming)
		end
	end,

	set_every_value = function(size)
		declared(size)

		return function()
			fixtures.edit_all(size)
		end
	end,

	confirm_all = function(size)
		edited(size)

		return function()
			registry.commit()
		end
	end,

	restore_all = function(size)
		edited(size)

		return function()
			registry.restore_group()
		end
	end,

	dirty = function(size)
		edited(size)

		return function()
			registry.dirty()
		end
	end,
} :: harness.suite
