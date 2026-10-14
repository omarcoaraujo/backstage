--// Services
const HttpService = game:GetService "HttpService"

--// Modules
const registry = require "./registry"

--// Constants
const HOST = "ws://127.0.0.1"
const DEFAULT_PORT = 34891
const DEBOUNCE = 0.5
const RECONNECT = 3

--// Types
type edit = { path: string, kind: string, value: unknown }
type signal<callback> = { Connect: (self: any, callback: callback) -> () }

export type client = {
	Send: (self: any, message: string) -> (),
	Opened: signal<() -> ()>,

	MessageReceived: signal<(message: string) -> ()>,
	Error: signal<(status: unknown, message: string) -> ()>,
	Closed: signal<() -> ()>,
}

export type deps = {
	create_client: ((url: string) -> client)?,
	debounce: number?,
	reconnect: number?,
}

--// Variables
const pending = {} :: { [string]: unknown }
local socket = nil :: client?
local url = `{HOST}:{DEFAULT_PORT}`

local connected = false
local scheduled = false

local reconnecting = false
local warned = false

local generation = 0
local debounce = DEBOUNCE
local reconnect = RECONNECT
local create_client = nil :: ((url: string) -> client)?

--// Functions
const function create_web_client(address: string): client
	const created = HttpService:CreateWebStreamClient(Enum.WebStreamClientType.WebSocket, { Url = address })
	return created :: any
end

const function warn_once(reason: string)
	if warned then return end
	warned = true
	warn(`[backstage] bridge is not reachable, edits will not be saved to the script: {reason}`)
end

const function to_edit(path: string, value: unknown): edit?
	if type(value) == "number" then return { path = path, kind = "number", value = value } end
	if type(value) == "boolean" then return { path = path, kind = "boolean", value = value } end
	if type(value) == "string" then return { path = path, kind = "string", value = value } end

	if typeof(value) == "Color3" then
		const color = value :: Color3
		const rgb = { r = math.round(color.R * 255), g = math.round(color.G * 255), b = math.round(color.B * 255) }
		return { path = path, kind = "color", value = rgb }
	end

	if typeof(value) == "Vector3" then
		const vector = value :: Vector3
		return { path = path, kind = "vector3", value = { x = vector.X, y = vector.Y, z = vector.Z } }
	end

	return nil
end

const function flush()
	scheduled = false

	if not connected or not socket then return end
	const edits = {} :: { edit }

	for path, value in pending do
		const edit = to_edit(path, value)
		if edit then table.insert(edits, edit) end
	end

	table.clear(pending)
	if #edits == 0 then return end
	socket:Send(HttpService:JSONEncode { edits = edits })
end

const function schedule_flush()
	if scheduled then return end
	scheduled = true

	const current = generation
	task.delay(debounce, function()
		if current ~= generation then return end
		flush()
	end)
end

const function report(message: string)
	const ok, reply = pcall(HttpService.JSONDecode, HttpService, message)
	if not ok or type(reply) ~= "table" or type(reply.refused) ~= "table" then return end

	for _, refusal in reply.refused do
		warn(`[backstage] could not save {refusal.path} to the script: {refusal.reason}`)
	end
end

const function connect()
	const client = (create_client or create_web_client)(url)
	const current = generation
	socket = client

	const function lost(reason: string)
		if socket ~= client then return end
		socket = nil

		connected = false
		warn_once(reason)

		if reconnecting then return end
		reconnecting = true

		task.delay(reconnect, function()
			if current ~= generation then return end
			reconnecting = false
			connect()
		end)
	end

	client.Opened:Connect(function()
		connected = true
		warned = false
		schedule_flush()
	end)

	client.MessageReceived:Connect(report)
	client.Error:Connect(function(_, message: string)
		lost(message)
	end)

	client.Closed:Connect(function()
		lost "connection closed"
	end)
end

const function on_change(path: string, value: unknown)
	pending[path] = value
	schedule_flush()
end

const function serve(port: number?, given: deps?)
	url = `{HOST}:{port or DEFAULT_PORT}`

	create_client = if given then given.create_client else nil
	debounce = if given and given.debounce then given.debounce else DEBOUNCE
	reconnect = if given and given.reconnect then given.reconnect else RECONNECT

	registry.on_change(on_change)
	connect()
end

const function reset()
	generation += 1
	table.clear(pending)

	socket = nil
	connected = false

	scheduled = false
	reconnecting = false
	warned = false
end

--// End
return table.freeze { serve = serve, reset = reset }
