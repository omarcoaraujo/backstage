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

const function raises(run: () -> ...unknown)
	const ok, failure = pcall(run)

	assert(not ok)
	assert(string.find(tostring(failure), "on_change", 1, true) ~= nil)
end

const function counting(_: number, callback: () -> ())
	return callback
end

const helpers = {} :: { read_speed: () -> unknown, register: () -> () }

--// Specs
return {
	fires_with_the_new_and_the_previous_value = function()
		const pets = fresh()
		const seen = {}

		backstage.on_change(pets.distance, function(value: number, previous: number)
			table.insert(seen, `{previous}->{value}`)
		end)

		registry.set("pets.distance", 9)
		assert(#seen == 1)
		assert(seen[1] == "6->9")
	end,

	ignores_other_paths = function()
		const pets = fresh()
		local fired = 0

		backstage.on_change(pets.distance, function()
			fired += 1
		end)

		registry.set("pets.speed", 20)
		registry.set("pets.trail.length", 3)
		assert(fired == 0)
	end,

	reaches_nested_paths = function()
		const pets = fresh()
		local length = 0

		backstage.on_change(pets.trail.length, function(value: number)
			length = value
		end)

		registry.set("pets.trail.length", 4)
		assert(length == 4)
	end,

	skips_a_write_that_changes_nothing = function()
		const pets = fresh()
		local fired = 0

		backstage.on_change(pets.distance, function()
			fired += 1
		end)

		registry.set("pets.distance", 6)
		assert(fired == 0)
	end,

	fires_for_a_restore = function()
		const pets = fresh()
		registry.set("pets.distance", 9)

		local last = 0
		backstage.on_change(pets.distance, function(value: number)
			last = value
		end)

		registry.restore "pets.distance"
		assert(last == 6)
	end,

	fires_for_a_value_applied_by_the_other_side = function()
		const pets = fresh()
		local last = 0

		backstage.on_change(pets.speed, function(value: number)
			last = value
		end)

		registry.apply("pets.speed", 12)
		assert(last == 12)
	end,

	stop_disconnects = function()
		const pets = fresh()
		local fired = 0

		const stop = backstage.on_change(pets.distance, function()
			fired += 1
		end)

		registry.set("pets.distance", 7)
		stop()

		registry.set("pets.distance", 8)
		assert(fired == 1)
	end,

	two_equal_values_keep_their_own_paths = function()
		fresh()

		const flags = backstage.config("flags", { first = true, second = true })
		local first = 0
		local second = 0

		backstage.on_change(flags.first, function()
			first += 1
		end)

		backstage.on_change(flags.second, function()
			second += 1
		end)

		registry.set("flags.first", false)
		assert(first == 1)
		assert(second == 0)

		registry.set("flags.second", false)
		assert(first == 1)
		assert(second == 1)
	end,

	a_string_value_is_read_as_a_value = function()
		fresh()

		const profile = backstage.config("profile", { name = "Rex", title = "Pets" })
		local named = ""

		backstage.on_change(profile.name, function(value: string)
			named = value
		end)

		registry.set("profile.name", "Max")
		registry.set("profile.title", "Zoo")
		assert(named == "Max")
	end,

	a_color_and_a_vector_are_read = function()
		fresh()

		const look = backstage.config("look", { tint = Color3.new(1, 0, 0), offset = Vector3.new(1, 2, 3) })
		local tint = Color3.new()
		local offset = Vector3.zero

		backstage.on_change(look.tint, function(value: Color3)
			tint = value
		end)

		backstage.on_change(look.offset, function(value: Vector3)
			offset = value
		end)

		registry.set("look.tint", Color3.new(0, 1, 0))
		registry.set("look.offset", Vector3.new(4, 5, 6))

		assert(tint == Color3.new(0, 1, 0))
		assert(offset == Vector3.new(4, 5, 6))
	end,

	a_call_split_across_lines_finds_the_path = function()
		const pets = fresh()
		local last = 0

		backstage.on_change(pets.speed, function(value: number)
			last = value
		end)

		registry.set("pets.speed", 12)
		assert(last == 12)
	end,

	a_callback_much_longer_than_the_call_finds_the_path = function()
		const pets = fresh()
		local last = 0

		backstage.on_change(pets.speed, function(value: number)
			local a = value
			local b = a
			local c = b
			local d = c
			local e = d
			last = e
		end)

		registry.set("pets.speed", 12)
		assert(last == 12)
	end,

	a_read_in_another_argument_does_not_steal_the_path = function()
		const pets = fresh()
		registry.set("pets.speed", 6)

		local fired = 0
		backstage.on_change(
			pets.distance,
			counting(pets.speed, function()
				fired += 1
			end)
		)

		registry.set("pets.distance", 9)
		assert(fired == 1)
	end,

	the_path_does_not_depend_on_the_values = function()
		const pets = fresh()

		for _, speed in { 6, 8, 20 } do
			registry.set("pets.speed", speed)
			registry.set("pets.distance", 6)

			local fired = 0
			const stop = backstage.on_change(
				pets.distance,
				counting(pets.speed, function()
					fired += 1
				end)
			)

			registry.set("pets.speed", speed + 1)
			registry.set("pets.distance", 7)
			stop()

			assert(fired == 1)
		end
	end,

	a_literal_raises = function()
		fresh()
		raises(function()
			backstage.on_change(5, function() end)
		end)
	end,

	a_table_raises = function()
		fresh()
		raises(function()
			backstage.on_change({}, function() end)
		end)
	end,

	a_string_path_raises = function()
		fresh()
		raises(function()
			backstage.on_change("pets.distance", function() end)
		end)
	end,

	a_function_raises = function()
		const pets = fresh()
		raises(function()
			backstage.on_change(function()
				return pets.distance
			end, function() end)
		end)
	end,

	a_value_read_on_an_earlier_line_raises = function()
		const pets = fresh()
		raises(function()
			local early = pets.distance
			backstage.on_change(early, function() end)
		end)
	end,

	a_value_changed_after_the_read_raises = function()
		const pets = fresh()
		raises(function()
			backstage.on_change(pets.distance + 1, function() end)
		end)
	end,

	a_read_is_used_by_one_call_only = function()
		const pets = fresh()
		backstage.on_change(pets.distance, function() end)

		raises(function()
			backstage.on_change(6, function() end)
		end)
	end,

	a_read_made_by_another_function_raises = function()
		const pets = fresh()

		helpers.register = function()
			backstage.on_change(8, function() end)
		end

		helpers.read_speed = function()
			return pets.speed
		end

		helpers.read_speed()
		raises(helpers.register)
	end,

	a_failed_call_connects_nothing = function()
		const pets = fresh()
		local fired = 0

		pcall(function()
			backstage.on_change(pets.distance + 1, function()
				fired += 1
			end)
		end)

		registry.set("pets.distance", 9)
		assert(fired == 0)
	end,

	production_is_inert = function()
		fresh()
		mode.disable()

		const pets = backstage.config("pets", { distance = 6 })
		const stop = backstage.on_change(pets.distance, function()
			error "never"
		end)

		mode.enable()
		registry.set("pets.distance", 9)

		stop()
	end,

	production_never_raises = function()
		fresh()
		mode.disable()

		const stop = backstage.on_change(5, function() end)
		mode.enable()

		stop()
	end,
}
