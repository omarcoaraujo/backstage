--// Modules
const apply = require "./apply"
const guard = require "./guard"
const json = require "@std/json"
const output = require "./output"
const save = require "./save"
const scan = require "./scan"
const server = require "@lute/net/server"
const watch = require "./watch"

--// Constants
const HOSTNAME = "127.0.0.1"
const DEFAULT_PORT = 34891

--// Functions
const function reply(socket, body: unknown)
	socket:send(json.serialize(body))
end

const function serve(root: string, port: number?)
	const listening = port or DEFAULT_PORT
	const state = { index = scan.scan(root), literals = {}, saving = 0 } :: save.state
	const sockets = {}

	const function push(edits: { apply.edit }, added: { apply.edit }, removed: { string })
		const paths = {}

		for _, edit in edits do
			table.insert(paths, edit.path)
		end

		for _, edit in added do
			table.insert(paths, edit.path)
		end

		table.move(removed, 1, #removed, #paths + 1, paths)

		for socket in sockets do
			reply(socket, { pushed = edits, added = added, removed = removed })
		end

		output.pushed(paths)
	end

	const started = server.serve {
		hostname = HOSTNAME,
		port = listening,

		handler = function(request, running)
			if not guard.allows(request.headers, listening) then return { status = 403, body = "forbidden" } end
			if running:upgrade(request) then return nil end
			return { status = 426, body = "websocket only" }
		end,

		websocket = {
			open = function(socket)
				sockets[socket] = true
			end,

			close = function(socket)
				sockets[socket] = nil
			end,

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

	const watching, reason = pcall(watch.start, root, state, push)
	if not watching then output.warning(`edits made by hand in the scripts will not reach the game: {reason}`) end

	return started
end

--// End
return {
	serve = serve,
	DEFAULT_PORT = DEFAULT_PORT,
}
