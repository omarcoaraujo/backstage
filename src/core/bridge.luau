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

--// Variables
const pending = {} :: { [string]: unknown }
local socket = nil :: WebStreamClient?
local url = `{HOST}:{DEFAULT_PORT}`

local connected = false
local scheduled = false

local reconnecting = false
local warned = false

--// Functions
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
	task.delay(DEBOUNCE, flush)
end

const function report(message: string)
	const ok, reply = pcall(HttpService.JSONDecode, HttpService, message)
	if not ok or type(reply) ~= "table" or type(reply.refused) ~= "table" then return end

	for _, refusal in reply.refused do
		warn(`[backstage] could not save {refusal.path} to the script: {refusal.reason}`)
	end
end

const function connect()
	const client = HttpService:CreateWebStreamClient(Enum.WebStreamClientType.WebSocket, { Url = url })
	socket = client

	const function lost(reason: string)
		if socket ~= client then return end
		socket = nil

		connected = false
		warn_once(reason)

		if reconnecting then return end
		reconnecting = true

		task.delay(RECONNECT, function()
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

const function serve(port: number?)
	url = `{HOST}:{port or DEFAULT_PORT}`
	registry.on_change(on_change)
	connect()
end

--// End
return table.freeze { serve = serve }
