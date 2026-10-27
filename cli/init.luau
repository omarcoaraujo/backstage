--// Modules
const fs = require "@std/fs"
const io = require "@std/io"
const output = require "@self/output"
const parse_export = require "@self/parse"
const process = require "@std/process"
const save = require "@self/save"
const scan = require "@self/scan"
const server = require "@self/server"

--// Constants
const SERVE = "serve"
const APPLY = "apply"
const DEFAULT_ROOT = "."

const MIN_PORT = 1
const MAX_PORT = 65535

--// Types
type options = { root: string, port: number?, file: string?, problem: string? }

--// Functions
const function valid_port(port: number?)
	if not port then return false end
	return port == math.floor(port) and port >= MIN_PORT and port <= MAX_PORT
end

const function parse(args: { string }): options
	const options = { root = DEFAULT_ROOT } :: options
	const command = args[2]

	local chose_root = false
	local index = 3

	while index <= #args do
		const argument = args[index]

		if argument == "--file" and command == APPLY then
			const file = args[index + 1]
			if not file or string.sub(file, 1, 2) == "--" then
				options.problem = "--file needs the path of a file with the exported values"
				return options
			end

			options.file = file
			index += 2
			continue
		end

		if argument == "--port" and command == SERVE then
			const port = tonumber(args[index + 1])
			if not valid_port(port) then
				options.problem =
					`--port needs a number from {MIN_PORT} to {MAX_PORT}, like --port {server.DEFAULT_PORT}`
				return options
			end

			options.port = port
			index += 2
			continue
		end

		if string.sub(argument, 1, 2) == "--" then
			options.problem = `unknown option {argument}`
			return options
		end

		if chose_root then
			options.problem = "only one project folder is accepted"
			return options
		end

		options.root = argument
		chose_root = true
		index += 1
	end

	return options
end

const function describe(root: string)
	local count = 0
	const index, dynamic = scan.scan(root)

	for name, files in index do
		count += 1
		if #files > 1 then output.warning(`config "{name}" is declared in {#files} files, edits to it are refused`) end
	end

	for _, place in dynamic do
		output.warning(`config at {place} has a name that is not a string, edits to it are refused`)
	end

	return count
end

const function fail(message: string, hint: string?)
	output.failure(message, hint)
	process.exit(1)
end

const function reject(message: string)
	output.failure(message)
	output.usage()
	process.exit(1)
end

const function readable(message: unknown)
	const first = string.match(tostring(message), "[^\n]+") or ""
	return (string.gsub(first, "^%S+:%d+: ", ""))
end

const function read_pasted()
	const lines = {}

	while true do
		const ok, chunk = pcall(io.input)
		if not ok or chunk == nil then break end

		const blank = string.match(chunk, "^%s*$") ~= nil
		if blank and #lines > 0 then break end
		if not blank then table.insert(lines, chunk) end
	end

	return table.concat(lines, "\n")
end

const function read_export(file: string?)
	if not file then
		output.waiting()
		return read_pasted()
	end

	if not fs.exists(file) then fail(`"{file}" does not exist`) end
	return fs.readFileToString(file)
end

const function apply_export(options: options)
	const edits, problems = parse_export.parse(read_export(options.file))

	for _, problem in problems do
		output.warning(problem)
	end

	const state = { index = scan.scan(options.root), literals = {}, removed = {}, saving = 0 } :: save.state
	const refusals = save.save(options.root, state, edits)

	for _, refusal in refusals do
		output.warning(`{refusal.path} was not written: {refusal.reason}`)
	end

	output.applied(#edits - #refusals, options.root)
	process.exit(if #problems + #refusals > 0 then 1 else 0)
end

--// End
if process.args[2] == nil then
	output.usage()
	process.exit(1)
end

const command = process.args[2]
if command ~= SERVE and command ~= APPLY then reject(`unknown command "{command}"`) end
const options = parse(process.args)

if options.problem then reject(options.problem) end
if not fs.exists(options.root) then
	fail(`"{options.root}" does not exist`, "give the folder that holds your Roblox project, like backstage serve .")
end

if fs.type(options.root) ~= "dir" then
	fail(`"{options.root}" is not a folder`, "give the folder that holds your Roblox project, like backstage serve .")
end

if command == APPLY then apply_export(options) end
const port = options.port or server.DEFAULT_PORT
const started, running = pcall(server.serve, options.root, port)

if not started then
	const reason = readable(running)
	if string.find(reason, "failed to listen", 1, true) then
		fail(
			`port {port} is already in use`,
			"stop the other backstage or pick another port with --port, and pass the same one to backstage.start { port = ... }"
		)
	end

	fail(reason)
end

output.serving(describe(options.root), options.root, `ws://{running.hostname}:{running.port}`)
