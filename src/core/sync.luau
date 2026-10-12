--// Services
const ReplicatedStorage = game:GetService "ReplicatedStorage"

--// Modules
const registry = require "./registry"

--// Constants
const REMOTE_NAME = "backstage_sync"

--// Functions
const function serve()
	const remote = Instance.new "RemoteEvent"
	remote.Name = REMOTE_NAME
	remote.Parent = ReplicatedStorage

	const function send_snapshot(player: Player)
		remote:FireClient(player, "snapshot", registry.snapshot())
	end

	const function on_event(player: Player, kind: unknown, path: unknown, value: unknown)
		if kind == "ready" then
			send_snapshot(player)
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

const function connect()
	const remote = ReplicatedStorage:WaitForChild(REMOTE_NAME) :: RemoteEvent

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

	remote.OnClientEvent:Connect(on_event)
	registry.connect_remote { edit = edit, press = press }
	remote:FireServer "ready"
end

--// End
return table.freeze {
	serve = serve,
	connect = connect,
}
