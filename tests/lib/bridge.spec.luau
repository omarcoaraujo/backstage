--// Services
const HttpService = game:GetService "HttpService"
const ReplicatedStorage = game:GetService "ReplicatedStorage"

--// Modules
const bridge = require(ReplicatedStorage.backstage.core.bridge)
const kinds = require(ReplicatedStorage.backstage.core.kinds)
const notice = require(ReplicatedStorage.backstage.core.notice)
const registry = require(ReplicatedStorage.backstage.core.registry)

--// Constants
const DEBOUNCE = 0.02
const RECONNECT = 0.05
const SETTLE = 0.12
const IDLE = 5
const GRACE = 0.05

--// Types
type fake = {
	client: bridge.client,
	sent: { string },
	closes: () -> number,

	open: () -> (),
	drop: () -> (),
	fail: () -> (),
	receive: (message: string) -> (),
}

--// Functions
const function fake_catalog(parts: {
	add: (key: string) -> (string?, string?),
	remove: (key: string) -> string?,
	reinsert: ((key: string) -> string?)?,
}): registry.catalog
	return {
		add = parts.add,
		remove = parts.remove,

		reinsert = parts.reinsert or function()
			return nil
		end,

		populate = function() end,

		keys = function()
			return {}
		end,

		changed = function()
			return false
		end,

		commit = function() end,

		revert = function()
			return {}
		end,
	}
end

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
	const received, fire_received = signal()

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
		receive = fire_received,

		fail = function()
			fire_failed(nil, "refused")
		end,
	}
end

const function serve(clients: { fake }, idle: number?, reconnect: number?, hold: boolean?)
	bridge.serve(nil, {
		debounce = DEBOUNCE,
		reconnect = reconnect or RECONNECT,

		idle = idle or IDLE,
		grace = GRACE,
		hold = hold,

		create_client = function()
			const created = fake_client()
			table.insert(clients, created)
			return created.client
		end,
	})
end

const function start(idle: number?, reconnect: number?, hold: boolean?)
	bridge.reset()
	registry.reset()

	registry.add("pets.speed", "speed", "pets", kinds.infer(1) :: kinds.descriptor, 1)
	const clients = {} :: { fake }

	serve(clients, idle, reconnect, hold)
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

	sends_a_new_catalog_entry_with_the_entry_it_was_copied_from = function()
		const clients = start()
		registry.add_group(
			{},
			"shop",
			fake_catalog {
				add = function(key: string)
					return `shop.{key}`, "shop.1"
				end,

				remove = function(key: string)
					return `shop.{key}`
				end,
			}
		)

		clients[1].open()
		registry.add_item("shop", "3")
		task.wait(SETTLE)

		const changes = HttpService:JSONDecode(clients[1].sent[1]).changes
		assert(#changes == 1)

		assert(changes[1].kind == "add" and changes[1].path == "shop.3" and changes[1].from == "shop.1")
		bridge.reset()
	end,

	takes_back_a_new_entry_when_the_script_refuses_it_without_sending_it_again = function()
		const clients = start()
		const removed = {} :: { string }
		const heard = {} :: { string }

		notice.on_notice(function(_, _, detail)
			table.insert(heard, detail or "")
		end)

		registry.add_group(
			{},
			"shop",
			fake_catalog {
				add = function(key: string)
					return `shop.{key}`, "shop.1"
				end,

				remove = function(key: string)
					table.insert(removed, key)
					return `shop.{key}`
				end,
			}
		)

		clients[1].open()
		registry.add_item("shop", "3")
		task.wait(SETTLE)

		clients[1].receive(HttpService:JSONEncode {
			refused = { { path = "shop.3", reason = "no room", kind = "add" } },
		})

		task.wait(SETTLE)
		assert(#removed == 1 and removed[1] == "3")

		assert(#clients[1].sent == 1)
		assert(heard[1] and string.find(heard[1], "shop.3", 1, true))

		bridge.reset()
		notice.reset()
	end,

	takes_back_a_new_entry_even_with_an_edit_waiting_elsewhere = function()
		const clients = start()
		const removed = {} :: { string }

		registry.add_group(
			{},
			"shop",
			fake_catalog {
				add = function(key: string)
					return `shop.{key}`, "shop.1"
				end,

				remove = function(key: string)
					table.insert(removed, key)
					return `shop.{key}`
				end,
			}
		)

		clients[1].open()
		registry.add_item("shop", "3")
		task.wait(SETTLE)

		registry.set("pets.speed", 2)
		clients[1].receive(HttpService:JSONEncode {
			refused = { { path = "shop.3", reason = "no room", kind = "add" } },
		})

		assert(#removed == 1 and removed[1] == "3")
		bridge.reset()
	end,

	brings_back_a_removed_entry_when_the_script_refuses_the_removal = function()
		const clients = start()
		const restored = {} :: { string }

		registry.add_group(
			{},
			"shop",
			fake_catalog {
				add = function(key: string)
					return `shop.{key}`, "shop.1"
				end,

				remove = function(key: string)
					return `shop.{key}`
				end,

				reinsert = function(key: string)
					table.insert(restored, key)
					return `shop.{key}`
				end,
			}
		)

		clients[1].open()
		registry.remove_item("shop", "2")
		task.wait(SETTLE)

		clients[1].receive(HttpService:JSONEncode {
			refused = { { path = "shop.2", reason = "not found", kind = "remove" } },
		})
		task.wait(SETTLE)

		assert(#restored == 1 and restored[1] == "2")
		assert(#clients[1].sent == 1)
		bridge.reset()
	end,

	leaves_the_entry_alone_when_the_refusal_is_about_a_value = function()
		const clients = start()
		const removed = {} :: { string }

		registry.add_group(
			{},
			"shop",
			fake_catalog {
				add = function(key: string)
					return `shop.{key}`, "shop.1"
				end,

				remove = function(key: string)
					table.insert(removed, key)
					return `shop.{key}`
				end,
			}
		)

		clients[1].open()
		clients[1].receive(HttpService:JSONEncode {
			refused = { { path = "shop.3", reason = "not a literal" } },
		})

		task.wait(SETTLE)
		assert(#removed == 0)
		bridge.reset()
	end,

	creates_the_entry_that_appeared_in_the_script_without_sending_it_back = function()
		const clients = start()
		const created = {} :: { string }

		registry.add_group(
			{},
			"shop",
			fake_catalog {
				add = function(key: string)
					table.insert(created, key)
					registry.add(`shop.{key}.price`, "price", `shop.{key}`, kinds.infer(1) :: kinds.descriptor, 1)

					return `shop.{key}`, "shop.1"
				end,

				remove = function(key: string)
					return `shop.{key}`
				end,
			}
		)

		clients[1].open()
		clients[1].receive(HttpService:JSONEncode {
			pushed = {},
			added = { { path = "shop.3.price", kind = "number", value = 7 } },
			removed = {},
		})

		task.wait(SETTLE)
		assert(#created == 1 and created[1] == "3")

		assert(registry.get "shop.3.price" == 7)
		assert(#clients[1].sent == 0)
		bridge.reset()
	end,

	removes_the_entry_that_disappeared_from_the_script_without_sending_it_back = function()
		const clients = start()
		const removed = {} :: { string }

		registry.add("shop.2.price", "price", "shop.2", kinds.infer(1) :: kinds.descriptor, 1)
		registry.add_group(
			{},
			"shop",
			fake_catalog {
				add = function(key: string)
					return `shop.{key}`, "shop.1"
				end,

				remove = function(key: string)
					table.insert(removed, key)
					registry.remove(`shop.{key}`)

					return `shop.{key}`
				end,
			}
		)

		clients[1].open()
		clients[1].receive(HttpService:JSONEncode { pushed = {}, added = {}, removed = { "shop.2.price" } })
		task.wait(SETTLE)

		assert(#removed == 1 and removed[1] == "2")
		assert(registry.get "shop.2.price" == nil)

		assert(#clients[1].sent == 0)
		bridge.reset()
	end,

	keeps_an_entry_that_still_has_values_in_the_script = function()
		const clients = start()
		const removed = {} :: { string }

		registry.add("shop.2.price", "price", "shop.2", kinds.infer(1) :: kinds.descriptor, 1)
		registry.add("shop.2.rarity", "rarity", "shop.2", kinds.infer "a" :: kinds.descriptor, "a")
		registry.add_group(
			{},
			"shop",
			fake_catalog {
				add = function(key: string)
					return `shop.{key}`, "shop.1"
				end,

				remove = function(key: string)
					table.insert(removed, key)
					return `shop.{key}`
				end,
			}
		)

		clients[1].open()
		clients[1].receive(HttpService:JSONEncode { pushed = {}, added = {}, removed = { "shop.2.price" } })
		task.wait(SETTLE)

		assert(#removed == 0)
		bridge.reset()
	end,

	drops_the_pending_edits_of_an_entry_that_was_removed = function()
		const clients = start()
		registry.add("shop.3.price", "price", "shop.3", kinds.infer(1) :: kinds.descriptor, 1)
		registry.add_group(
			{},
			"shop",
			fake_catalog {
				add = function(key: string)
					return `shop.{key}`, "shop.1"
				end,

				remove = function(key: string)
					return `shop.{key}`
				end,
			}
		)

		clients[1].open()
		registry.set("shop.3.price", 9)

		registry.remove_item("shop", "3")
		task.wait(SETTLE)

		const message = HttpService:JSONDecode(clients[1].sent[1])
		assert(#message.edits == 0)

		assert(#message.changes == 1 and message.changes[1].kind == "remove")
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

	holds_the_edits_until_it_finishes = function()
		const clients = start(nil, nil, true)
		clients[1].open()

		registry.set("pets.speed", 6)
		task.wait(SETTLE)
		assert(#clients[1].sent == 0)

		bridge.finish()
		task.wait(SETTLE)

		assert(#clients[1].sent == 1 and edits_of(clients[1].sent[1])[1].value == 6)
		bridge.reset()
	end,

	closes_the_connection_after_sending_what_it_held = function()
		const clients = start(nil, nil, true)
		clients[1].open()

		registry.set("pets.speed", 6)
		bridge.finish()
		task.wait(GRACE + SETTLE)

		assert(#clients[1].sent == 1)
		assert(clients[1].closes() == 1)
	end,

	finishing_with_nothing_held_closes_at_once = function()
		const clients = start(nil, nil, true)
		clients[1].open()

		bridge.finish()
		assert(clients[1].closes() == 1)
	end,

	finishing_connects_again_to_send_what_it_held_after_going_idle = function()
		const clients = start(0.05, nil, true)
		clients[1].open()
		task.wait(SETTLE)

		registry.set("pets.speed", 6)
		assert(#clients == 1)

		bridge.finish()
		assert(#clients == 2)

		clients[2].open()
		task.wait(SETTLE)

		assert(#clients[2].sent == 1 and edits_of(clients[2].sent[1])[1].value == 6)
		bridge.reset()
	end,

	closes_a_client_that_failed = function()
		const clients = start()
		clients[1].fail()

		assert(clients[1].closes() == 1)
		bridge.reset()
	end,

	an_edit_waking_the_bridge_does_not_open_a_second_connection_on_the_retry = function()
		const clients = start(0.2, 0.3)
		clients[1].fail()

		task.wait(0.22)
		registry.set("pets.speed", 5)
		assert(#clients == 2)

		task.wait(0.14)
		assert(#clients == 2)
		bridge.reset()
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

	applies_a_change_pushed_from_the_script_without_sending_it_back = function()
		const clients = start()
		clients[1].open()

		clients[1].receive(HttpService:JSONEncode { pushed = { { path = "pets.speed", kind = "number", value = 9 } } })
		task.wait(SETTLE)

		assert(registry.get "pets.speed" == 9)
		assert(not registry.dirty())

		assert(#clients[1].sent == 0)
		bridge.reset()
	end,

	ignores_a_pushed_change_it_cannot_apply = function()
		const clients = start()
		clients[1].open()

		clients[1].receive(
			HttpService:JSONEncode { pushed = { { path = "pets.speed", kind = "string", value = "fast" } } }
		)
		clients[1].receive(HttpService:JSONEncode { pushed = { { path = "cats.speed", kind = "number", value = 9 } } })

		assert(registry.get "pets.speed" == 1)
		bridge.reset()
	end,

	keeps_the_connection_open_to_hear_the_script = function()
		bridge.reset()
		registry.reset()

		const clients = {} :: { fake }
		bridge.serve(nil, {
			idle = 0.05,
			keep = true,

			create_client = function()
				const created = fake_client()
				table.insert(clients, created)
				return created.client
			end,
		})

		clients[1].open()
		task.wait(SETTLE)

		assert(clients[1].closes() == 0)
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
