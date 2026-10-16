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

const function defaults()
	return {
		distance = 6,
		mode = "follow",
		respawn = backstage.button(),
		trail = { enabled = true, length = 1.5 },
	}
end

const function options()
	return {
		limits = {
			distance = { min = 0, max = 30, step = 0.1 },
			mode = { choices = { "follow", "orbit" } },
			trail = { length = { min = 0.1, max = 6 } },
		},

		hints = {},
	}
end

--// Specs
return {
	studio_reads_current_values = function()
		fresh()
		const pets = backstage.config("pets", defaults(), options())

		assert(pets.distance == 6)
		assert(pets.trail.length == 1.5)

		registry.set("pets.distance", 12)
		registry.set("pets.trail.length", 3)

		assert(pets.distance == 12)
		assert(pets.trail.length == 3)
	end,

	studio_rejects_writes_from_game_code = function()
		fresh()
		const pets = backstage.config("pets", defaults(), options())

		assert(not pcall(function()
			(pets :: any).distance = 1
		end))

		assert(pets.distance == 6)
	end,

	studio_registers_every_value_by_path = function()
		fresh()

		backstage.config("pets", defaults(), options())
		const paths = {}

		for _, entry in registry.list() do
			table.insert(paths, entry.path)
		end

		assert(table.concat(paths, ",") == "pets.distance,pets.mode,pets.trail.enabled,pets.trail.length")
		assert(#registry.list_buttons() == 1)
	end,

	studio_keeps_hints_by_path = function()
		fresh()

		backstage.config("pets", defaults(), {
			hints = {
				distance = "How far behind",
				trail = { length = "Seconds to fade" },
			},
		})

		const hints = {}

		for _, entry in registry.list() do
			hints[entry.path] = entry.hint
		end

		assert(hints["pets.distance"] == "How far behind")
		assert(hints["pets.trail.length"] == "Seconds to fade")
		assert(hints["pets.mode"] == nil)
	end,

	studio_keeps_the_hint_of_a_button = function()
		fresh()
		backstage.config("pets", defaults(), { hints = { respawn = "Brings the pet back" } })

		assert(registry.list_buttons()[1].hint == "Brings the pet back")
	end,

	studio_ignores_a_hint_that_is_not_text = function()
		fresh()
		backstage.config("pets", defaults(), { hints = { distance = 5 } })

		for _, entry in registry.list() do
			assert(entry.hint == nil)
		end
	end,

	studio_applies_limits = function()
		fresh()

		backstage.config("pets", defaults(), options())
		assert(registry.set("pets.distance", 99))
		assert(registry.get "pets.distance" == 30)

		assert(not registry.set("pets.mode", "teleport"))
		assert(registry.get "pets.mode" == "follow")
	end,

	studio_iterates_in_key_order = function()
		fresh()

		const pets = backstage.config("pets", defaults(), options())
		const keys = {}

		for key in pets do
			table.insert(keys, key)
		end

		table.sort(keys)
		assert(table.concat(keys, ",") == "distance,mode,respawn,trail")
	end,

	button_fires_its_listeners = function()
		fresh()

		const pets = backstage.config("pets", defaults(), options())
		local fired = 0

		const connection = pets.respawn:connect(function()
			fired += 1
		end)

		registry.press "pets.respawn"
		assert(fired == 1)

		connection.disconnect()
		registry.press "pets.respawn"
		assert(fired == 1)
	end,

	change_listeners_get_old_and_new_value = function()
		fresh()
		backstage.config("pets", defaults(), options())

		local seen = nil :: string?
		const stop = registry.on_change(function(path, value, previous)
			seen = `{path} {previous}->{value}`
		end)

		registry.set("pets.distance", 8)
		assert(seen == "pets.distance 6->8")

		stop()
		registry.set("pets.distance", 9)
		assert(seen == "pets.distance 6->8")
	end,

	production_returns_a_frozen_copy = function()
		fresh()

		mode.disable()
		const pets = backstage.config("pets", defaults(), options())

		assert(pets.distance == 6)
		assert(pets.trail.length == 1.5)
		assert(table.isfrozen(pets))

		assert(table.isfrozen(pets.trail))
		assert(#registry.list() == 0)
		assert(not pcall(function()
			(pets :: any).distance = 1
		end))
	end,

	production_buttons_are_inert = function()
		fresh()

		mode.disable()
		const pets = backstage.config("pets", defaults(), options())

		pets.respawn:connect(function()
			error "never"
		end)

		pets.respawn:fire()
	end,
}
