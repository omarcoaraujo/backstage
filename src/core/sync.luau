--// Services
const Players = game:GetService "Players"
const ReplicatedStorage = game:GetService "ReplicatedStorage"

--// Modules
const holders = require "./holders"
const mode = require "./mode"
const presence = require "./presence"
const registry = require "./registry"

--// Constants
const REMOTE_NAME = mode.remote_name
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
	holders.reset()

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

		if kind == "cursor" then
			const state = presence.valid(path)
			const owner = if state and state.hold then state.hold.owner else nil

			if holders.claim(player.UserId, owner) then
				remote:FireAllClients("cursor", player.UserId, player.DisplayName, state)
				return
			end

			const pointer = if state and state.cursor then { cursor = state.cursor } else nil
			remote:FireAllClients("cursor", player.UserId, player.DisplayName, pointer)
			return
		end

		if type(path) ~= "string" then return end

		if kind == "add_item" or kind == "remove_item" then
			if type(value) ~= "string" then return end
			const done = if kind == "add_item"
				then registry.add_item(path, value)
				else registry.remove_item(path, value)

			if not done then send_snapshot(player) end
			return
		end

		if kind == "press" then
			registry.press(path)
			return
		end

		if kind ~= "edit" then return end

		const holder = holders.holder(path)
		const refused = holder ~= nil and holder ~= player.UserId

		if not refused and registry.set(path, value) then return end
		const current = registry.get(path)
		if current ~= nil then remote:FireClient(player, "changed", path, current) end
	end

	const function on_changed(path: string, value: unknown)
		remote:FireAllClients("changed", path, value)
	end

	const function on_registered()
		remote:FireAllClients("snapshot", registry.snapshot())
	end

	const function on_leaving(player: Player)
		holders.release(player.UserId)
		remote:FireAllClients("cursor", player.UserId, player.DisplayName, nil)
	end

	remote.OnServerEvent:Connect(on_event)
	Players.PlayerRemoving:Connect(on_leaving)

	registry.on_change(on_changed)
	registry.on_register(on_registered)
end

const function connect(given: client_remote?)
	const remote = given or find_remote()
	if not remote then return false end

	const function on_event(kind: unknown, path: unknown, value: unknown, extra: unknown)
		if kind == "snapshot" then
			registry.import(path :: registry.snapshot)
			return
		end

		if kind == "cursor" then
			const own = Players.LocalPlayer
			if own and path == own.UserId then return end

			presence.set(path :: number, value :: string, presence.valid(extra))
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

	const function share_cursor(state: presence.state?)
		remote:FireServer("cursor", state)
	end

	const function forward(change: registry.change)
		const parent, key = string.match(change.path, "^(.*)%.([^%.]+)$")
		if not parent or not key then return end
		remote:FireServer(if change.kind == "add" then "add_item" else "remove_item", parent, key)
	end

	remote.OnClientEvent:Connect(on_event)
	registry.on_structure(forward)

	registry.connect_remote { edit = edit, press = press }
	presence.connect_remote(share_cursor)

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
