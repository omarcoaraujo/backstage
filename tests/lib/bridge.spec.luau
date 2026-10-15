--// Services
const HttpService = game:GetService "HttpService"
const ReplicatedStorage = game:GetService "ReplicatedStorage"

--// Modules
const bridge = require(ReplicatedStorage.backstage.core.bridge)
const kinds = require(ReplicatedStorage.backstage.core.kinds)
const registry = require(ReplicatedStorage.backstage.core.registry)

--// Constants
const DEBOUNCE = 0.02
const RECONNECT = 0.05
const SETTLE = 0.12
const IDLE = 5

--// Types
type fake = {
	client: bridge.client,
	sent: { string },
	closes: () -> number,

	open: () -> (),
	drop: () -> (),
	fail: () -> (),
}

--// Functions
const function signal()
	const callbacks = {} :: { (...any) -> () }

	const function fire(...)
		for _, callback in callbacks do
			callback(...)
		end
	end

	return {
		Connect = function(_, callback)
			table.insert(callbacks, callback)
		end,
	}, fire
end

const function fake_client(): fake
	const opened, fire_opened = signal()
	const received = signal()

	const failed, fire_failed = signal()
	const closed, fire_closed = signal()

	const sent = {} :: { string }
	local closed_count = 0

	const client = {
		Send = function(_, message: string)
			table.insert(sent, message)
		end,

		Close = function()
			closed_count += 1
		end,

		Opened = opened,
		MessageReceived = received,

		Error = failed,
		Closed = closed,
	}

	return {
		client = client :: any,
		sent = sent,

		closes = function()
			return closed_count
		end,

		open = fire_opened,
		drop = fire_closed,

		fail = function()
			fire_failed(nil, "refused")
		end,
	}
end

const function serve(clients: { fake }, idle: number?)
	bridge.serve(nil, {
		debounce = DEBOUNCE,
		reconnect = RECONNECT,
		idle = idle or IDLE,

		create_client = function()
			const created = fake_client()
			table.insert(clients, created)
			return created.client
		end,
	})
end

const function start(idle: number?)
	bridge.reset()
	registry.reset()

	registry.add("pets.speed", "speed", "pets", kinds.infer(1) :: kinds.descriptor, 1)
	const clients = {} :: { fake }

	serve(clients, idle)
	return clients
end

const function edits_of(message: string)
	return HttpService:JSONDecode(message).edits
end

--// Specs
return {
	sends_the_edits_of_a_burst_as_one_message = function()
		const clients = start()
		clients[1].open()

		registry.set("pets.speed", 2)
		registry.set("pets.speed", 3)
		task.wait(SETTLE)

		assert(#clients[1].sent == 1)
		assert(edits_of(clients[1].sent[1])[1].value == 3)
		bridge.reset()
	end,

	holds_the_edits_until_the_connection_opens = function()
		const clients = start()
		registry.set("pets.speed", 4)

		task.wait(SETTLE)
		assert(#clients[1].sent == 0)

		clients[1].open()
		task.wait(SETTLE)

		assert(#clients[1].sent == 1 and edits_of(clients[1].sent[1])[1].value == 4)
		bridge.reset()
	end,

	connects_again_after_the_connection_closes = function()
		const clients = start()
		clients[1].open()
		clients[1].drop()

		assert(#clients == 1)
		task.wait(SETTLE)

		assert(#clients == 2)
		bridge.reset()
	end,

	connects_again_after_an_error = function()
		const clients = start()
		clients[1].fail()

		task.wait(SETTLE)
		assert(#clients == 2)
		bridge.reset()
	end,

	an_error_and_a_close_together_reconnect_once = function()
		const clients = start()
		clients[1].fail()
		clients[1].drop()

		task.wait(SETTLE)
		assert(#clients == 2)
		bridge.reset()
	end,

	keeps_trying_while_the_tool_is_down = function()
		const clients = start()
		clients[1].fail()
		task.wait(SETTLE)

		clients[2].fail()
		task.wait(SETTLE)

		assert(#clients == 3)
		bridge.reset()
	end,

	sends_the_edits_made_while_down_once_it_is_back = function()
		const clients = start()
		clients[1].open()
		clients[1].drop()

		registry.set("pets.speed", 9)
		task.wait(SETTLE)

		assert(#clients == 2 and #clients[1].sent == 0)
		clients[2].open()
		task.wait(SETTLE)

		assert(#clients[2].sent == 1 and edits_of(clients[2].sent[1])[1].value == 9)
		bridge.reset()
	end,

	a_reset_stops_a_pending_reconnect = function()
		const clients = start()

		clients[1].fail()
		bridge.reset()

		task.wait(SETTLE)
		assert(#clients == 1)
	end,

	tries_again_when_the_client_cannot_be_created = function()
		bridge.reset()
		registry.reset()

		local attempts = 0
		const clients = {} :: { fake }

		bridge.serve(nil, {
			debounce = DEBOUNCE,
			reconnect = RECONNECT,
			idle = IDLE,

			create_client = function()
				attempts += 1
				if attempts == 1 then error "Too many WebStreamClients active" end

				const created = fake_client()
				table.insert(clients, created)
				return created.client
			end,
		})

		assert(attempts == 1)
		task.wait(SETTLE)

		assert(attempts == 2 and #clients == 1)
		bridge.reset()
	end,

	serving_again_keeps_one_connection = function()
		const clients = start()
		serve(clients)
		serve(clients)

		assert(#clients == 1)
		bridge.reset()
	end,

	a_reset_closes_the_connection = function()
		const clients = start()
		clients[1].open()

		bridge.reset()
		assert(clients[1].closes() == 1)
	end,

	a_reset_does_not_reconnect_when_the_connection_closes = function()
		const clients = start()
		clients[1].open()

		bridge.reset()
		clients[1].drop()

		task.wait(SETTLE)
		assert(#clients == 1)
	end,

	serving_closes_the_bridge_of_a_previous_module = function()
		bridge.reset()
		registry.reset()

		local released = false
		const slots = shared :: any
		slots.backstage_bridge = function()
			released = true
		end

		serve {}
		assert(released)
		bridge.reset()
	end,

	closes_the_connection_when_it_stays_idle = function()
		const clients = start(0.05)
		clients[1].open()

		task.wait(SETTLE)
		assert(clients[1].closes() == 1)

		assert(#clients == 1)
		bridge.reset()
	end,

	connects_again_on_an_edit_after_it_went_idle = function()
		const clients = start(0.05)
		clients[1].open()
		task.wait(SETTLE)

		registry.set("pets.speed", 7)
		assert(#clients == 2)

		clients[2].open()
		task.wait(DEBOUNCE * 3)

		assert(#clients[2].sent == 1 and edits_of(clients[2].sent[1])[1].value == 7)
		bridge.reset()
	end,
}
