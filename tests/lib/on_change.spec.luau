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

	return backstage.config("pets", { distance = 6, speed = 8, trail = { length = 1.5 } })
end

--// Specs
return {
	fires_with_the_new_and_the_previous_value = function()
		fresh()

		const seen = {}
		backstage.on_change("pets.distance", function(value: number, previous: number)
			table.insert(seen, `{previous}->{value}`)
		end)

		registry.set("pets.distance", 9)
		assert(#seen == 1)
		assert(seen[1] == "6->9")
	end,

	ignores_other_paths = function()
		fresh()

		local fired = 0
		backstage.on_change("pets.distance", function()
			fired += 1
		end)

		registry.set("pets.speed", 20)
		registry.set("pets.trail.length", 3)
		assert(fired == 0)
	end,

	reaches_nested_paths = function()
		fresh()

		local length = 0
		backstage.on_change("pets.trail.length", function(value: number)
			length = value
		end)

		registry.set("pets.trail.length", 4)
		assert(length == 4)
	end,

	skips_a_write_that_changes_nothing = function()
		fresh()

		local fired = 0
		backstage.on_change("pets.distance", function()
			fired += 1
		end)

		registry.set("pets.distance", 6)
		assert(fired == 0)
	end,

	fires_for_a_restore = function()
		fresh()
		registry.set("pets.distance", 9)

		local last = 0
		backstage.on_change("pets.distance", function(value: number)
			last = value
		end)

		registry.restore "pets.distance"
		assert(last == 6)
	end,

	fires_for_a_value_applied_by_the_other_side = function()
		fresh()

		local last = 0
		backstage.on_change("pets.speed", function(value: number)
			last = value
		end)

		registry.apply("pets.speed", 12)
		assert(last == 12)
	end,

	stop_disconnects = function()
		fresh()

		local fired = 0
		const stop = backstage.on_change("pets.distance", function()
			fired += 1
		end)

		registry.set("pets.distance", 7)
		stop()

		registry.set("pets.distance", 8)
		assert(fired == 1)
	end,

	a_path_declared_later_still_fires = function()
		registry.reset()
		mode.enable()

		local last = 0
		backstage.on_change("pets.distance", function(value: number)
			last = value
		end)

		backstage.config("pets", { distance = 6 })
		registry.set("pets.distance", 11)
		assert(last == 11)
	end,

	production_is_inert = function()
		fresh()
		mode.disable()

		const stop = backstage.on_change("pets.distance", function()
			error "never"
		end)

		mode.enable()
		registry.set("pets.distance", 9)
		stop()
	end,
}
