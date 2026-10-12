--// Services
const ReplicatedStorage = game:GetService "ReplicatedStorage"

--// Packages
const charm = require(ReplicatedStorage.roblox_packages.charm)
const vide = require(ReplicatedStorage.roblox_packages.vide)

--// Modules
const backstage = require(ReplicatedStorage.backstage)
const mode = require(ReplicatedStorage.backstage.core.mode)
const registry = require(ReplicatedStorage.backstage.core.registry)
const tracker = require(ReplicatedStorage.backstage.core.tracker)
const install = require(ReplicatedStorage.backstage.reactive.install)

--// Variables
install { vide = vide, charm = charm }

--// Functions
const function fresh()
	registry.reset()
	mode.enable()
end

const function defaults()
	return {
		distance = 6,
		speed = 2,
		trail = { length = 1.5 },
	}
end

const function spy()
	const log = {} :: { string }

	const stop = tracker.add {
		read = function(path, value)
			table.insert(log, `read {path}={value}`)
		end,

		write = function(path, value)
			table.insert(log, `write {path}={value}`)
		end,

		reset = function() end,
	}

	return log, stop
end

--// Specs
return {
	a_read_reports_the_path_and_the_value = function()
		fresh()
		const pets = backstage.config("pets", defaults())
		const log, stop = spy()

		local _ = pets.distance
		_ = pets.trail.length

		stop()
		assert(table.concat(log, ",") == "read pets.distance=6,read pets.trail.length=1.5")
	end,

	reading_a_group_reports_nothing = function()
		fresh()
		const pets = backstage.config("pets", defaults())
		const log, stop = spy()

		local _ = pets.trail

		stop()
		assert(#log == 0)
	end,

	iterating_a_group_reports_every_value = function()
		fresh()
		const pets = backstage.config("pets", defaults())
		const log, stop = spy()

		for _ in pets.trail do
		end

		stop()
		assert(table.concat(log, ",") == "read pets.trail.length=1.5")
	end,

	a_write_reports_the_new_value_once = function()
		fresh()
		backstage.config("pets", defaults())
		const log, stop = spy()

		registry.set("pets.distance", 12)
		registry.set("pets.distance", 12)

		stop()
		assert(table.concat(log, ",") == "write pets.distance=12")
	end,

	a_stopped_adapter_hears_nothing = function()
		fresh()
		const pets = backstage.config("pets", defaults())
		const log, stop = spy()

		stop()
		local _ = pets.distance

		registry.set("pets.distance", 12)
		assert(#log == 0)
	end,

	production_reports_nothing = function()
		fresh()
		mode.disable()

		const pets = backstage.config("pets", defaults())
		const log, stop = spy()

		local _ = pets.distance
		stop()

		assert(#log == 0)
	end,

	a_vide_effect_runs_again_when_the_window_writes = function()
		fresh()

		const pets = backstage.config("pets", defaults())
		const seen = {} :: { number }

		const destroy = vide.root(function()
			vide.effect(function()
				table.insert(seen, pets.distance)
			end)
		end)

		registry.set("pets.distance", 12)
		destroy()
		assert(table.concat(seen, ",") == "6,12")
	end,

	a_vide_effect_ignores_other_values = function()
		fresh()

		const pets = backstage.config("pets", defaults())
		local runs = 0

		const destroy = vide.root(function()
			vide.effect(function()
				local _ = pets.distance
				runs += 1
			end)
		end)

		registry.set("pets.speed", 9)
		destroy()
		assert(runs == 1)
	end,

	a_vide_property_function_follows_the_window = function()
		fresh()

		const pets = backstage.config("pets", defaults())
		const destroy, part = vide.root(function()
			return vide.create "Part" {
				Size = function()
					return Vector3.one * pets.distance
				end,
			}
		end)

		assert(part.Size == Vector3.one * 6)
		registry.set("pets.distance", 12)

		assert(part.Size == Vector3.one * 12)
		destroy()
	end,

	a_copy_given_later_replaces_the_first = function()
		fresh()
		const pets = backstage.config("pets", defaults())
		local created = 0
		const copy = {
			source = function(value: unknown)
				created += 1

				return function()
					return value
				end
			end,
		}

		install { vide = copy }
		local _ = pets.distance
		install { vide = vide }

		_ = pets.distance
		assert(created == 1)
	end,

	a_charm_effect_runs_again_when_the_window_writes = function()
		fresh()
		const pets = backstage.config("pets", defaults())
		const seen = {} :: { number }

		const stop = charm.effect(function()
			table.insert(seen, pets.distance)
		end)

		registry.set("pets.distance", 12)
		stop()
		assert(table.concat(seen, ",") == "6,12")
	end,
}
