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

	a_hint_travels_in_the_snapshot = function()
		fresh()
		registry.add("pets.speed", "speed", "pets", kinds.infer(1) :: kinds.descriptor, 1, "How fast")

		const snapshot = registry.snapshot()
		assert(snapshot.entries[1].hint == "How fast")

		fresh()
		registry.import(snapshot)
		assert(registry.list()[1].hint == "How fast")
	end,

	a_button_hint_travels_in_the_snapshot = function()
		fresh()
		registry.add_button(
			"pets.respawn",
			"respawn",
			"pets",
			require(ReplicatedStorage.backstage.core.button).create(),
			"Brings it back"
		)

		const snapshot = registry.snapshot()
		assert(snapshot.buttons[1].hint == "Brings it back")

		fresh()
		registry.import(snapshot)

		assert(registry.list_buttons()[1].hint == "Brings it back")
	end,

	dirty_looks_only_inside_the_group = function()
		fresh()
		declare_speed(1)

		registry.add("world.gravity", "gravity", "world", kinds.infer(1) :: kinds.descriptor, 1)
		registry.set("pets.speed", 5)

		assert(registry.dirty())
		assert(registry.dirty "pets")
		assert(not registry.dirty "world")
		assert(not registry.dirty "pet")
	end,

	restore_group_restores_only_that_group = function()
		fresh()
		declare_speed(1)
		registry.add("world.gravity", "gravity", "world", kinds.infer(1) :: kinds.descriptor, 1)

		registry.set("pets.speed", 5)
		registry.set("world.gravity", 9)

		registry.restore_group "pets"
		assert(registry.get "pets.speed" == 1)
		assert(registry.get "world.gravity" == 9)

		registry.restore_group()
		assert(registry.get "world.gravity" == 1)
		assert(not registry.dirty())
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

	local_snapshot_leaves_out_what_the_server_already_has = function()
		fresh()

		registry.import(incoming(1))
		registry.add("pets.size", "size", "pets", kinds.infer(2) :: kinds.descriptor, 2)

		const shot = registry.snapshot(true)
		assert(#shot.entries == 1 and shot.entries[1].path == "pets.size")
		assert(#shot.buttons == 0)
	end,

	adopt_takes_only_what_is_missing = function()
		const edits = fresh()
		declare_speed(1)

		registry.adopt(incoming(9))
		assert(registry.get "pets.speed" == 1)
		assert(registry.press "pets.respawn")

		assert(registry.set("pets.speed", 4))
		assert(#edits == 0)
	end,

	adopt_fires_register_only_when_something_is_new = function()
		fresh()
		declare_speed(1)

		local announced = 0
		registry.on_register(function()
			announced += 1
		end)

		registry.adopt(incoming(9))
		assert(announced == 1)

		registry.adopt(incoming(9))
		assert(announced == 1)
	end,
}
