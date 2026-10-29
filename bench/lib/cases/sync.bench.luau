--// Services
const ReplicatedStorage = game:GetService "ReplicatedStorage"

--// Modules
const registry = require(ReplicatedStorage.backstage.core.registry)
const sync = require(ReplicatedStorage.backstage.core.sync)

--// Utils
const fixtures = require(ReplicatedStorage.bench.fixtures)
const harness = require(ReplicatedStorage.bench.harness)

--// Constants
const PLAYER = { UserId = 1, DisplayName = "one" } :: any

--// Functions
const function server_remote()
	local handler = nil :: ((player: Player, ...any) -> ())?

	const remote: sync.server_remote = {
		FireClient = function() end,
		FireAllClients = function() end,

		OnServerEvent = {
			Connect = function(_, callback)
				handler = callback
			end,
		},
	}

	registry.reset()
	sync.serve(remote)

	return function(...)
		assert(handler)(PLAYER, ...)
	end
end

const function client_remote()
	local handler = nil :: ((...any) -> ())?

	const remote: sync.client_remote = {
		FireServer = function() end,

		OnClientEvent = {
			Connect = function(_, callback)
				handler = callback
			end,
		},
	}

	registry.reset()
	assert(sync.connect(remote))

	return function(...)
		assert(handler)(...)
	end
end

--// End
return {
	server_adopts_a_declaration = harness.deferred(function(size)
		const fire = server_remote()
		const declaration = fixtures.snapshot(size)

		return function()
			fire("declare", declaration)
		end
	end),

	server_applies_an_edit_per_value = function(size)
		const fire = server_remote()
		fixtures.declare(size, false)

		return function()
			for index = 1, size do
				fire("edit", fixtures.path_of(index), index + 0.5)
			end
		end
	end,

	client_receives_a_snapshot = function(size)
		const receive = client_remote()
		const incoming = fixtures.snapshot(size)

		return function()
			receive("snapshot", incoming)
		end
	end,

	client_receives_a_confirm = function(size)
		const receive = client_remote()
		fixtures.declare(size, false)
		fixtures.edit_all(size)
		
		return function()
			receive("committed", "")
		end
	end,
} :: harness.suite
