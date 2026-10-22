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

	return backstage.config("pets", {
		distance = 6,
		speed = 8,
		trail = { length = 1.5 },
	})
end

--// Specs
return {
	a_group_hears_every_value_inside_it = function()
		const pets = fresh()
		const seen = {}

		backstage.on_change(pets.trail, function(value: unknown, previous: unknown, path: string)
			table.insert(seen, `{path}:{previous}->{value}`)
		end)

		registry.set("pets.trail.length", 3)
		registry.set("pets.speed", 20)

		assert(#seen == 1)
		assert(seen[1] == "pets.trail.length:1.5->3")
	end,

	a_config_hears_the_values_of_its_groups = function()
		const pets = fresh()
		local fired = 0

		backstage.on_change(pets, function()
			fired += 1
		end)

		registry.set("pets.distance", 9)
		registry.set("pets.trail.length", 3)
		assert(fired == 2)
	end,

	a_group_stops_hearing_once_disconnected = function()
		const pets = fresh()
		local fired = 0

		const stop = backstage.on_change(pets, function()
			fired += 1
		end)

		stop()
		registry.set("pets.distance", 9)
		assert(fired == 0)
	end,

	a_single_value_also_gets_its_path = function()
		const pets = fresh()
		local seen = ""

		backstage.on_change(pets.distance, function(_: number, _2: number, path: string)
			seen = path
		end)

		registry.set("pets.distance", 9)
		assert(seen == "pets.distance")
	end,

	any_change_hears_every_config = function()
		const pets = fresh()
		backstage.config("world", { gravity = 2 })

		const seen = {}
		backstage.on_any_change(function(path: string)
			table.insert(seen, path)
		end)

		registry.set("pets.distance", 9)
		registry.set("world.gravity", 5)

		assert(#seen == 2 and seen[1] == "pets.distance" and seen[2] == "world.gravity")
		assert(pets.distance == 9)
	end,

	both_do_nothing_in_production = function()
		registry.reset()
		mode.disable()

		const pets = backstage.config("pets", { distance = 6 })
		local fired = 0

		backstage.on_change(pets, function()
			fired += 1
		end)

		backstage.on_any_change(function()
			fired += 1
		end)

		registry.set("pets.distance", 9)
		assert(fired == 0)
		mode.enable()
	end,
}
