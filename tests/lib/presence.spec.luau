--// Services
const ReplicatedStorage = game:GetService "ReplicatedStorage"

--// Modules
const presence = require(ReplicatedStorage.backstage.core.presence)

--// Functions
const function pointer(x: number): presence.state
	return { cursor = { group = "pets", row = "pets.speed", x = x, y = 3 } }
end

--// Specs
return {
	validates_a_cursor = function()
		const state = presence.valid(pointer(0.5))
		const cursor = if state then state.cursor else nil

		assert(cursor and cursor.group == "pets" and cursor.row == "pets.speed")
		assert(cursor.x == 0.5 and cursor.y == 3)
	end,

	accepts_a_cursor_without_a_row = function()
		const state = presence.valid { cursor = { group = "pets", x = 0, y = 0 } }
		assert(state and state.cursor and state.cursor.row == nil)
	end,

	validates_a_hold = function()
		const state = presence.valid { hold = { owner = "pets.speed", part = { "control", "slider" } } }
		assert(state and state.hold and state.hold.owner == "pets.speed")
		assert(state.cursor == nil and #state.hold.part == 2)
	end,

	rejects_what_is_not_a_state = function()
		assert(presence.valid(nil) == nil)
		assert(presence.valid {} == nil)
		assert(presence.valid { cursor = { group = 1, x = 0, y = 0 } } == nil)

		assert(presence.valid { cursor = { group = "pets", x = "0", y = 0 } } == nil)
		assert(presence.valid { cursor = { group = "pets", x = 0 / 0, y = 0 } } == nil)
		assert(presence.valid { cursor = { group = "pets", x = math.huge, y = 0 } } == nil)

		assert(presence.valid { hold = { owner = "pets", part = { 1 } } } == nil)
		assert(presence.valid { hold = { owner = "pets" } } == nil)
	end,

	rejects_a_hold_that_is_too_deep = function()
		const part = {}

		for _ = 1, 40 do
			table.insert(part, "x")
		end

		assert(presence.valid { hold = { owner = "pets", part = part } } == nil)
	end,

	lists_users_in_order = function()
		presence.reset()

		presence.set(7, "seven", pointer(0))
		presence.set(3, "three", pointer(0))

		const users = presence.list()
		assert(#users == 2 and users[1].user == 3 and users[2].user == 7)
		presence.reset()
	end,

	clearing_a_user_removes_it = function()
		presence.reset()
		presence.set(3, "three", pointer(0))

		presence.set(3, "three", nil)
		assert(#presence.list() == 0)
	end,

	announces_every_change = function()
		presence.reset()

		local count = 0
		const stop = presence.on_change(function()
			count += 1
		end)

		presence.set(3, "three", pointer(0))
		presence.set(3, "three", nil)
		assert(count == 2)

		stop()
		presence.set(3, "three", nil)
		assert(count == 2)
	end,

	publishes_to_the_remote = function()
		presence.reset()

		local sent = nil :: presence.state?
		presence.connect_remote(function(state)
			sent = state
		end)

		presence.publish(pointer(0.25))
		assert(sent and sent.cursor and sent.cursor.x == 0.25)
		presence.reset()
	end,
}
