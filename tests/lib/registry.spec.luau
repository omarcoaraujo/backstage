--// Services
const ReplicatedStorage = game:GetService "ReplicatedStorage"

--// Modules
const kinds = require(ReplicatedStorage.backstage.core.kinds)
const registry = require(ReplicatedStorage.backstage.core.registry)

--// Functions
const function fresh()
	registry.reset()

	const edits = {}
	const presses = {}

	registry.connect_remote {
		edit = function(path, value)
			table.insert(edits, { path = path, value = value })
		end,
		press = function(path)
			table.insert(presses, path)
		end,
	}

	return edits, presses
end

const function declare_speed(default: number)
	registry.add("pets.speed", "speed", "pets", kinds.infer(default) :: kinds.descriptor, default)
end

const function incoming(value: number, default: number?): registry.snapshot
	return {
		entries = {
			{
				path = "pets.speed",
				name = "speed",
				group = "pets",

				descriptor = kinds.infer(value) :: kinds.descriptor,
				default = default or value,
				value = value,
			},
		},

		buttons = { { path = "pets.respawn", name = "respawn", group = "pets" } },
	}
end

--// Specs
return {
	local_entries_never_forward = function()
		const edits = fresh()
		declare_speed(1)

		assert(registry.set("pets.speed", 5))
		assert(#edits == 0)
	end,

	imported_entries_forward_user_edits = function()
		const edits = fresh()
		registry.import(incoming(1))

		assert(registry.set("pets.speed", 5))
		assert(#edits == 1 and edits[1].path == "pets.speed" and edits[1].value == 5)
	end,

	apply_does_not_forward = function()
		const edits = fresh()
		registry.import(incoming(1))

		assert(registry.apply("pets.speed", 7))
		assert(registry.get "pets.speed" == 7)
		assert(#edits == 0)
	end,

	import_takes_the_server_value_over_the_local_default = function()
		fresh()
		declare_speed(1)

		registry.import(incoming(9))
		assert(registry.get "pets.speed" == 9)
	end,

	declaring_after_import_keeps_the_server_value = function()
		const edits = fresh()
		registry.import(incoming(9))

		declare_speed(1)
		assert(registry.get "pets.speed" == 9)

		assert(registry.set("pets.speed", 3))
		assert(#edits == 1)
	end,

	restore_goes_back_to_the_declared_default = function()
		fresh()
		declare_speed(1)

		assert(registry.set("pets.speed", 5))
		assert(registry.restore "pets.speed")
		assert(registry.get "pets.speed" == 1)
	end,

	restore_forwards_to_the_server_with_the_server_default = function()
		const edits = fresh()
		registry.import(incoming(9, 4))

		assert(registry.restore "pets.speed")
		assert(registry.get "pets.speed" == 4)
		assert(#edits == 1 and edits[1].value == 4)
	end,

	imported_buttons_forward_presses = function()
		const _, presses = fresh()
		registry.import(incoming(1))

		assert(registry.press "pets.respawn")
		assert(#presses == 1 and presses[1] == "pets.respawn")
	end,

	snapshot_lists_entries_and_buttons = function()
		fresh()
		declare_speed(2)
		registry.add_button(
			"pets.respawn",
			"respawn",
			"pets",
			{ connect = function() end, fire = function() end } :: any
		)

		const shot = registry.snapshot()
		assert(#shot.entries == 1 and shot.entries[1].value == 2)
		assert(#shot.buttons == 1 and shot.buttons[1].path == "pets.respawn")
	end,
}
