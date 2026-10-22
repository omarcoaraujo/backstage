--// Services
const HttpService = game:GetService "HttpService"

--// Modules
const kinds = require "./kinds"
const registry = require "./registry"

--// Constants
const HOST = "ws://127.0.0.1"
const DEFAULT_PORT = 34891
const DEBOUNCE = 0.5
const RECONNECT = 3

const IDLE = 10
const GRACE = 0.5
const FINISH_TIMEOUT = 5
const SHARED_KEY = "backstage_bridge"

--// Types
type edit = { path: string, kind: string, value: unknown }
type signal<callback> = { Connect: (self: any, callback: callback) -> () }

export type client = {
	Send: (self: any, message: string) -> (),
	Close: (self: any) -> (),
	Opened: signal<() -> ()>,

	MessageReceived: signal<(message: string) -> ()>,
	Error: signal<(status: unknown, message: string) -> ()>,
	Closed: signal<() -> ()>,
}

export type deps = {
	create_client: ((url: string) -> client)?,
	debounce: number?,
	reconnect: number?,

	idle: number?,
	grace: number?,

	hold: boolean?,
	keep: boolean?,
}

--// Variables
const pending = {} :: { [string]: unknown }
local socket = nil :: client?
local url = `{HOST}:{DEFAULT_PORT}`

local serving = false
local connected = false
local scheduled = false

local holding = false
local keeping = false
local pushing = false

local finishing = false
local on_flushed = nil :: (() -> ())?

local reconnecting = false
local warned = false

local dormant = false
local idle_armed = false

local last_activity = 0
local stop_listening = nil :: (() -> ())?

local generation = 0
local debounce = DEBOUNCE
local reconnect = RECONNECT

local idle = IDLE
local grace = GRACE
local create_client = nil :: ((url: string) -> client)?

--// Functions
const function close_socket()
	const current = socket
	socket = nil
	connected = false

	if not current then return end
	pcall(current.Close, current)
end

const function go_dormant()
	dormant = true
	close_socket()
end

const function arm_idle()
	if idle_armed or keeping then return end
	idle_armed = true

	const current = generation
	const function check()
		if current ~= generation then return end
		const remaining = idle - (os.clock() - last_activity)

		if remaining > 0 then
			task.delay(remaining, check)
			return
		end

		idle_armed = false
		go_dormant()
	end

	task.delay(idle, check)
end

const function touch()
	last_activity = os.clock()
	arm_idle()
end

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

	if #edits > 0 then
		touch()
		socket:Send(HttpService:JSONEncode { edits = edits })
	end

	const done = on_flushed
	on_flushed = nil

	if not done then return end
	done()
end

const function schedule_flush()
	if scheduled or holding then return end
	scheduled = true

	const current = generation
	task.delay(debounce, function()
		if current ~= generation then return end
		flush()
	end)
end

const function to_value(edit: { kind: unknown, value: unknown }): kinds.value?
	const kind, value = edit.kind, edit.value

	if kind == "number" and type(value) == "number" then return value end
	if kind == "boolean" and type(value) == "boolean" then return value end
	if kind == "string" and type(value) == "string" then return value end

	if kind == "color" and type(value) == "table" then
		const rgb = value :: { [string]: number }
		return Color3.new(rgb.r / 255, rgb.g / 255, rgb.b / 255)
	end

	if kind == "vector3" and type(value) == "table" then
		const axes = value :: { [string]: number }
		return Vector3.new(axes.x, axes.y, axes.z)
	end

	return nil
end

const function push_edits(edits: { unknown })
	for _, item in edits do
		if type(item) ~= "table" then continue end

		const edit = item :: { path: unknown, kind: unknown, value: unknown }
		const value = to_value(edit)

		if type(edit.path) ~= "string" or value == nil then continue end
		registry.push(edit.path, value)
	end

	return true
end

const function apply_pushed(edits: { unknown })
	pushing = true
	const ok, reason = pcall(push_edits, edits)
	pushing = false

	if not ok then warn(`[backstage] could not apply the change made in the script: {reason}`) end
	registry.announce()
end

const function report(message: string)
	const ok, reply = pcall(HttpService.JSONDecode, HttpService, message)
	if not ok or type(reply) ~= "table" then return end

	if type(reply.pushed) == "table" then apply_pushed(reply.pushed) end
	if type(reply.refused) ~= "table" then return end

	for _, refusal in reply.refused do
		warn(`[backstage] could not save {refusal.path} to the script: {refusal.reason}`)
	end
end

const function connect()
	dormant = false
	touch()

	if socket then return end
	const current = generation

	const function retry_later()
		if reconnecting then return end
		reconnecting = true

		task.delay(reconnect, function()
			if current ~= generation then return end
			reconnecting = false

			if dormant then return end
			connect()
		end)
	end

	const function lost(source: client, reason: string)
		if socket ~= source then return end
		close_socket()

		warn_once(reason)
		retry_later()
	end

	const created, client = pcall(create_client or create_web_client, url)
	if not created then
		warn_once(tostring(client))
		retry_later()
		return
	end

	socket = client

	client.Opened:Connect(function()
		connected = true
		warned = false
		schedule_flush()
	end)

	client.MessageReceived:Connect(report)
	client.Error:Connect(function(_, message: string)
		lost(client, message)
	end)

	client.Closed:Connect(function()
		lost(client, "connection closed")
	end)
end

const function on_change(path: string, value: unknown)
	if pushing then return end

	pending[path] = value
	touch()

	if dormant and not holding then connect() end
	schedule_flush()
end

const function reset()
	generation += 1
	table.clear(pending)
	close_socket()

	if stop_listening then stop_listening() end
	stop_listening = nil

	const slots = shared :: any
	if slots[SHARED_KEY] == reset then slots[SHARED_KEY] = nil end

	serving = false
	scheduled = false

	holding = false
	keeping = false
	pushing = false

	finishing = false
	on_flushed = nil

	reconnecting = false
	warned = false

	dormant = false
	idle_armed = false
end

const function finish()
	if not serving or finishing then return end
	if next(pending) == nil then
		reset()
		return
	end

	const slots = shared :: any
	const current = generation

	const function conclude()
		if current ~= generation then return end
		reset()
	end

	holding = false
	finishing = true
	debounce = 0

	if stop_listening then stop_listening() end
	stop_listening = nil

	if slots[SHARED_KEY] == reset then slots[SHARED_KEY] = nil end
	on_flushed = function()
		task.delay(grace, conclude)
	end

	task.delay(FINISH_TIMEOUT, conclude)
	connect()

	if not connected then return end
	schedule_flush()
end

const function release_previous()
	const slots = shared :: any
	const previous = slots[SHARED_KEY]

	if type(previous) == "function" and previous ~= reset then previous() end
	slots[SHARED_KEY] = reset
end

const function serve(port: number?, given: deps?)
	const address = `{HOST}:{port or DEFAULT_PORT}`
	if serving and not finishing and address == url then return end
	if serving then reset() end

	release_previous()
	url = address

	create_client = if given then given.create_client else nil
	debounce = if given and given.debounce then given.debounce else DEBOUNCE

	reconnect = if given and given.reconnect then given.reconnect else RECONNECT
	idle = if given and given.idle then given.idle else IDLE

	grace = if given and given.grace then given.grace else GRACE
	holding = given ~= nil and given.hold == true
	keeping = given ~= nil and given.keep == true

	stop_listening = registry.on_change(on_change)
	serving = true
	connect()
end

--// End
return table.freeze {
	serve = serve,
	finish = finish,
	reset = reset,
}
