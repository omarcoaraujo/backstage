--// Services
const ReplicatedStorage = game:GetService "ReplicatedStorage"

--// Modules
const registry = require "./registry"

--// Constants
const REMOTE_NAME = "backstage_sync"
const REMOTE_TIMEOUT = 10

--// Types
type signal<callback> = { Connect: (self: any, callback: callback) -> () }

export type server_remote = {
	FireClient: (self: any, player: Player, ...any) -> (),
	FireAllClients: (self: any, ...any) -> (),
	OnServerEvent: signal<(player: Player, ...any) -> ()>,
}

export type client_remote = {
	FireServer: (self: any, ...any) -> (),
	OnClientEvent: signal<(...any) -> ()>,
}

--// Functions
const function create_remote(): server_remote
	const created = Instance.new "RemoteEvent"
	created.Name = REMOTE_NAME

	created.Parent = ReplicatedStorage
	return created :: any
end

const function find_remote(): client_remote?
	return ReplicatedStorage:WaitForChild(REMOTE_NAME, REMOTE_TIMEOUT) :: any
end

const function serve(given: server_remote?)
	const remote = given or create_remote()

	const function send_snapshot(player: Player)
		remote:FireClient(player, "snapshot", registry.snapshot())
	end

	const function on_event(player: Player, kind: unknown, path: unknown, value: unknown)
		if kind == "ready" then
			send_snapshot(player)
			return
		end

		if kind == "declare" then
			if type(path) == "table" then registry.adopt(path :: registry.snapshot) end
			return
		end

		if type(path) ~= "string" then return end
		if kind == "press" then
			registry.press(path)
			return
		end

		if kind ~= "edit" then return end
		if registry.set(path, value) then return end

		const current = registry.get(path)
		if current ~= nil then remote:FireClient(player, "changed", path, current) end
	end

	const function on_changed(path: string, value: unknown)
		remote:FireAllClients("changed", path, value)
	end

	const function on_registered()
		remote:FireAllClients("snapshot", registry.snapshot())
	end

	remote.OnServerEvent:Connect(on_event)
	registry.on_change(on_changed)
	registry.on_register(on_registered)
end

const function connect(given: client_remote?)
	const remote = given or find_remote()
	if not remote then return false end

	const function on_event(kind: unknown, path: unknown, value: unknown)
		if kind == "snapshot" then
			registry.import(path :: registry.snapshot)
			return
		end

		if kind == "changed" then registry.apply(path :: string, value) end
	end

	const function edit(path: string, value: unknown)
		remote:FireServer("edit", path, value)
	end

	const function press(path: string)
		remote:FireServer("press", path)
	end

	const function declare()
		const local_only = registry.snapshot(true)
		if #local_only.entries == 0 and #local_only.buttons == 0 then return end
		remote:FireServer("declare", local_only)
	end

	remote.OnClientEvent:Connect(on_event)
	registry.connect_remote { edit = edit, press = press }

	registry.on_register(declare)
	remote:FireServer "ready"

	declare()
	return true
end

--// End
return table.freeze {
	serve = serve,
	connect = connect,
}
