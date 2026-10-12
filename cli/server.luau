--// Modules
const apply = require "./apply"
const fs = require "@std/fs"
const json = require "@std/json"
const server = require "@lute/net/server"

--// Constants
const HOSTNAME = "127.0.0.1"
const DEFAULT_PORT = 34891

--// Functions
const function reply(socket, body: unknown)
	socket:send(json.serialize(body))
end

const function save_edits(script_path: string, message: string)
	const ok, payload = pcall(json.deserialize, message)
	if not ok or type(payload) ~= "table" or type(payload.edits) ~= "table" then return nil end

	const source = fs.readFileToString(script_path)
	const updated, refusals = apply.apply(source, payload.edits)

	if updated ~= source then fs.writeStringToFile(script_path, updated) end
	return refusals
end

const function serve(script_path: string, port: number?)
	return server.serve {
		hostname = HOSTNAME,
		port = port or DEFAULT_PORT,

		handler = function(request, running)
			if running:upgrade(request) then return nil end
			return { status = 426, body = "websocket only" }
		end,

		websocket = {
			message = function(socket, message)
				const refusals = save_edits(script_path, tostring(message))
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
