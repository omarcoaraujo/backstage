--// Modules
const apply = require "./apply"
const fs = require "@std/fs"
const json = require "@std/json"
const server = require "@lute/net/server"

--// Constants
const HOSTNAME = "127.0.0.1"
const DEFAULT_PORT = 34891

--// Functions
const function respond(status: number, body: unknown)
	return {
		status = status,
		body = json.serialize(body),
		headers = { ["content-type"] = "application/json" },
	}
end

const function serve(script_path: string, port: number?)
	return server.serve {
		hostname = HOSTNAME,
		port = port or DEFAULT_PORT,
		handler = function(request)
			if request.method ~= "POST" or request.path ~= "/edits" then
				return respond(404, { error = "not found" })
			end

			const ok, payload = pcall(json.deserialize, request.body)
			if not ok or type(payload) ~= "table" or type(payload.edits) ~= "table" then
				return respond(400, { error = "expected { edits: [...] }" })
			end

			const source = fs.readFileToString(script_path)
			const updated, refusals = apply.apply(source, payload.edits)

			if updated ~= source then fs.writeStringToFile(script_path, updated) end
			return respond(200, { refused = refusals })
		end,
	}
end

--// End
return { serve = serve, DEFAULT_PORT = DEFAULT_PORT }
