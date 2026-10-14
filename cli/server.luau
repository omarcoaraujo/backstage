--// Modules
const json = require "@std/json"
const save = require "./save"
const scan = require "./scan"
const server = require "@lute/net/server"

--// Constants
const HOSTNAME = "127.0.0.1"
const DEFAULT_PORT = 34891

--// Functions
const function reply(socket, body: unknown)
	socket:send(json.serialize(body))
end

const function serve(root: string, port: number?)
	const state = { index = scan.scan(root) } :: save.state

	return server.serve {
		hostname = HOSTNAME,
		port = port or DEFAULT_PORT,

		handler = function(request, running)
			if running:upgrade(request) then return nil end
			return { status = 426, body = "websocket only" }
		end,

		websocket = {
			message = function(socket, message)
				const refusals = save.save_edits(root, state, tostring(message))

				if not refusals then
					reply(socket, { error = "expected { edits: [...] }" })
					return
				end

				reply(socket, { refused = refusals })
			end,
		},
	}
end

--// End
return { serve = serve, DEFAULT_PORT = DEFAULT_PORT }
