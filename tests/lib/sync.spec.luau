--// Services
const ReplicatedStorage = game:GetService "ReplicatedStorage"

--// Modules
const backstage = require(ReplicatedStorage.backstage)
const kinds = require(ReplicatedStorage.backstage.core.kinds)
const mode = require(ReplicatedStorage.backstage.core.mode)
const registry = require(ReplicatedStorage.backstage.core.registry)
const sync = require(ReplicatedStorage.backstage.core.sync)

--// Constants
const PLAYER = { UserId = 1, DisplayName = "one" } :: any
const OTHER = { UserId = 2, DisplayName = "two" } :: any

--// Types
type sent = { kind: string, args: { any } }

--// Functions
const function snapshot_of(value: number, path: string?): registry.snapshot
	return {
		entries = {
			{
				path = path or "pets.speed",
				name = "speed",
				group = "pets",

				descriptor = kinds.infer(value) :: kinds.descriptor,
				default = value,
				value = value,
			},
		},

		buttons = {},
	}
end

const function declare_speed(default: number, path: string?)
	registry.add(path or "pets.speed", "speed", "pets", kinds.infer(default) :: kinds.descriptor, default)
end

const function server_remote()
	local handler = nil :: ((player: Player, ...any) -> ())?
	const log = {} :: { sent }

	const remote: sync.server_remote = {
		FireClient = function(_, _, ...)
			table.insert(log, { kind = "client", args = { ... } })
		end,

		FireAllClients = function(_, ...)
			table.insert(log, { kind = "all", args = { ... } })
		end,

		OnServerEvent = {
			Connect = function(_, callback)
				handler = callback
			end,
		},
	}

	const function fire(...)
		assert(handler)(PLAYER, ...)
	end

	const function fire_as(player: any, ...)
		assert(handler)(player, ...)
	end

	registry.reset()
	sync.serve(remote)

	return log, fire, fire_as
end

const function client_remote()
	local handler = nil :: ((...any) -> ())?
	const log = {} :: { { any } }

	const remote: sync.client_remote = {
		FireServer = function(_, ...)
			table.insert(log, { ... })
		end,

		OnClientEvent = {
			Connect = function(_, callback)
				handler = callback
			end,
		},
	}

	const function receive(...)
		assert(handler)(...)
	end

	registry.reset()
	return remote, log, receive
end

--// Specs
return {
	server_adopts_the_entries_a_client_declares = function()
		const log, fire = server_remote()
		fire("declare", snapshot_of(4))

		assert(registry.get "pets.speed" == 4)
		assert(#log == 1 and log[1].kind == "all" and log[1].args[1] == "snapshot")
	end,

	server_keeps_the_value_it_already_has_over_a_declaration = function()
		const log, fire = server_remote()
		declare_speed(1)

		fire("declare", snapshot_of(9))
		assert(registry.get "pets.speed" == 1)
		assert(#log == 0)
	end,

	server_adds_a_catalog_entry_a_client_asks_for_and_tells_everyone = function()
		const log, fire = server_remote()
		mode.enable()
		backstage.config("shop", { skins = { [1] = { price = 100 }, [5] = { price = 500 } } })

		fire("add_item", "shop.skins", "9")
		assert(registry.get "shop.skins.9.price" ~= nil)

		const last = log[#log]
		assert(last.kind == "all" and last.args[1] == "snapshot")
		assert(table.find(last.args[2].catalogs["shop.skins"], "9") ~= nil)
	end,

	server_removes_a_catalog_entry_a_client_asks_for = function()
		const log, fire = server_remote()
		mode.enable()
		backstage.config("shop", { skins = { [1] = { price = 100 }, [5] = { price = 500 } } })

		fire("remove_item", "shop.skins", "5")
		assert(registry.get "shop.skins.5.price" == nil)

		const last = log[#log]
		assert(last.kind == "all" and table.find(last.args[2].catalogs["shop.skins"], "5") == nil)
	end,

	server_sends_the_snapshot_back_when_it_refuses_a_catalog_change = function()
		const log, fire = server_remote()
		mode.enable()
		backstage.config("shop", { skins = { [1] = { price = 100 }, [5] = { price = 500 } } })

		const before = #log
		fire("add_item", "shop.skins", "5")

		assert(#log == before + 1)
		assert(log[#log].kind == "client" and log[#log].args[1] == "snapshot")
	end,

	server_answers_ready_with_its_snapshot = function()
		const log, fire = server_remote()
		declare_speed(2)

		fire "ready"
		assert(#log == 1 and log[1].kind == "client" and log[1].args[1] == "snapshot")
		assert(log[1].args[2].entries[1].value == 2)
	end,

	server_applies_an_edit_and_broadcasts_it = function()
		const log, fire = server_remote()
		declare_speed(1)

		fire("edit", "pets.speed", 7)
		assert(registry.get "pets.speed" == 7)
		assert(#log == 1 and log[1].kind == "all" and log[1].args[1] == "changed")
	end,

	server_refuses_an_edit_on_a_value_another_player_holds = function()
		const log, _, fire_as = server_remote()
		declare_speed(1)

		fire_as(PLAYER, "cursor", { hold = { owner = "pets.speed", part = { "control", "slider" } } })
		fire_as(OTHER, "edit", "pets.speed", 7)

		assert(registry.get "pets.speed" == 1)
		assert(log[#log].kind == "client" and log[#log].args[1] == "changed" and log[#log].args[3] == 1)
	end,

	server_lets_the_holder_edit = function()
		const _, _, fire_as = server_remote()
		declare_speed(1)

		fire_as(PLAYER, "cursor", { hold = { owner = "pets.speed", part = {} } })
		fire_as(PLAYER, "edit", "pets.speed", 7)

		assert(registry.get "pets.speed" == 7)
	end,

	server_frees_the_value_when_the_holder_lets_go = function()
		const _, _, fire_as = server_remote()
		declare_speed(1)

		fire_as(PLAYER, "cursor", { hold = { owner = "pets.speed", part = {} } })
		fire_as(PLAYER, "cursor", nil)

		fire_as(OTHER, "edit", "pets.speed", 7)
		assert(registry.get "pets.speed" == 7)
	end,

	server_does_not_show_the_hold_of_a_player_that_lost_the_claim = function()
		const log, _, fire_as = server_remote()
		fire_as(PLAYER, "cursor", { hold = { owner = "pets.speed", part = {} } })

		fire_as(OTHER, "cursor", { hold = { owner = "pets.speed", part = {} } })
		assert(log[#log].args[2] == 2 and log[#log].args[4] == nil)
	end,

	server_sends_back_the_current_value_of_a_refused_edit = function()
		const log, fire = server_remote()
		declare_speed(1)

		fire("edit", "pets.speed", "fast")
		assert(registry.get "pets.speed" == 1)
		assert(#log == 1 and log[1].kind == "client" and log[1].args[3] == 1)
	end,

	client_announces_ready_and_declares_what_it_registered = function()
		const remote, log = client_remote()
		declare_speed(3)

		assert(sync.connect(remote))
		assert(#log == 2 and log[1][1] == "ready")
		assert(log[2][1] == "declare" and log[2][2].entries[1].path == "pets.speed")
	end,

	client_asks_the_server_for_a_catalog_entry_the_window_adds = function()
		const remote, log = client_remote()
		mode.enable()

		backstage.config("shop", { skins = { [1] = { price = 100 }, [5] = { price = 500 } } })
		assert(sync.connect(remote))

		assert(registry.add_item("shop.skins", "9"))
		registry.remove_item("shop.skins", "1")

		const asked = {}

		for _, sent in log do
			if sent[1] == "add_item" or sent[1] == "remove_item" then table.insert(asked, sent) end
		end

		assert(#asked == 2)
		assert(asked[1][1] == "add_item" and asked[1][2] == "shop.skins" and asked[1][3] == "9")
		assert(asked[2][1] == "remove_item" and asked[2][2] == "shop.skins" and asked[2][3] == "1")
	end,

	client_follows_the_catalog_entries_the_server_lists = function()
		const remote, _, receive = client_remote()
		mode.enable()

		backstage.config("shop", { skins = { [1] = { price = 100 }, [5] = { price = 500 } } })
		assert(sync.connect(remote))

		receive("snapshot", {
			entries = {},
			buttons = {},
			catalogs = { ["shop.skins"] = { "1", "9" } },
		})

		assert(registry.get "shop.skins.9.price" ~= nil)
		assert(registry.get "shop.skins.5.price" == nil)
		assert(registry.get "shop.skins.1.price" == 100)
	end,

	client_declares_nothing_when_everything_came_from_the_server = function()
		const remote, log = client_remote()
		assert(sync.connect(remote))
		assert(#log == 1 and log[1][1] == "ready")
	end,

	client_declares_a_config_registered_after_the_connection = function()
		const remote, log = client_remote()
		assert(sync.connect(remote))

		declare_speed(5, "world.gravity")
		registry.announce()

		assert(#log == 2 and log[2][1] == "declare")
		assert(#log[2][2].entries == 1 and log[2][2].entries[1].path == "world.gravity")
	end,

	client_does_not_declare_again_after_importing_the_server_snapshot = function()
		const remote, log, receive = client_remote()
		declare_speed(3)

		assert(sync.connect(remote))
		receive("snapshot", snapshot_of(8))

		assert(#log == 2)
		assert(registry.get "pets.speed" == 8)
	end,

	client_forwards_an_edit_once_the_server_knows_the_entry = function()
		const remote, log, receive = client_remote()
		declare_speed(3)

		assert(sync.connect(remote))
		assert(registry.set("pets.speed", 4))
		assert(#log == 2)

		receive("snapshot", snapshot_of(3))
		assert(registry.set("pets.speed", 6))
		assert(#log == 3 and log[3][1] == "edit" and log[3][3] == 6)
	end,
}
