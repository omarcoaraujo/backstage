--// Modules
const apply = require "./apply"
const fs = require "@std/fs"
const json = require "@std/json"
const scan = require "./scan"
const server = require "@lute/net/server"

--// Constants
const HOSTNAME = "127.0.0.1"
const DEFAULT_PORT = 34891

--// Types
type edit = apply.edit
type refusal = apply.refusal

--// Functions
const function reply(socket, body: unknown)
	socket:send(json.serialize(body))
end

const function config_name(path: string)
	return string.match(path, "^[^%.]+") :: string
end

const function refuse_all(edits: { edit }, reason: string, refusals: { refusal })
	for _, edit in edits do
		table.insert(refusals, { path = edit.path, reason = reason })
	end
end

const function group_by_config(edits: { edit })
	const groups = {} :: { [string]: { edit } }

	for _, edit in edits do
		const name = config_name(edit.path)
		const group = groups[name] or {}

		table.insert(group, edit)
		groups[name] = group
	end

	return groups
end

const function save_edits(root: string, state: { index: scan.index }, message: string)
	const ok, payload = pcall(json.deserialize, message)
	if not ok or type(payload) ~= "table" or type(payload.edits) ~= "table" then return nil end

	local scanned_again = false
	const refusals = {} :: { refusal }
	const by_file = {} :: { [string]: { edit } }

	for name, edits in group_by_config(payload.edits) do
		if not state.index[name] and not scanned_again then
			state.index = scan.scan(root)
			scanned_again = true
		end

		const files = state.index[name]
		if not files then
			refuse_all(edits, `config "{name}" is not in the project`, refusals)
			continue
		end

		if #files > 1 then
			refuse_all(edits, `config "{name}" is declared in {#files} files: {table.concat(files, ", ")}`, refusals)
			continue
		end

		const file_edits = by_file[files[1]] or {}
		table.move(edits, 1, #edits, #file_edits + 1, file_edits)
		by_file[files[1]] = file_edits
	end

	for file, edits in by_file do
		const source = fs.readFileToString(file)
		const updated, refused = apply.apply(source, edits)

		if updated ~= source then fs.writeStringToFile(file, updated) end
		table.move(refused, 1, #refused, #refusals + 1, refusals)
	end

	return refusals
end

const function serve(root: string, port: number?)
	const state = { index = scan.scan(root) }

	return server.serve {
		hostname = HOSTNAME,
		port = port or DEFAULT_PORT,

		handler = function(request, running)
			if running:upgrade(request) then return nil end
			return { status = 426, body = "websocket only" }
		end,

		websocket = {
			message = function(socket, message)
				const refusals = save_edits(root, state, tostring(message))
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
