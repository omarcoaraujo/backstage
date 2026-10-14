--// Modules
const fs = require "@std/fs"
const output = require "@self/output"
const process = require "@std/process"
const scan = require "@self/scan"
const server = require "@self/server"

--// Constants
const COMMAND = "serve"
const DEFAULT_ROOT = "."

const MIN_PORT = 1
const MAX_PORT = 65535

--// Types
type options = { root: string, port: number?, problem: string? }

--// Functions
const function valid_port(port: number?)
	if not port then return false end
	return port == math.floor(port) and port >= MIN_PORT and port <= MAX_PORT
end

const function parse(args: { string }): options
	const options = { root = DEFAULT_ROOT } :: options
	local chose_root = false
	local index = 3

	while index <= #args do
		const argument = args[index]

		if argument == "--port" then
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

--// End
if process.args[2] == nil then
	output.usage()
	process.exit(1)
end

if process.args[2] ~= COMMAND then reject(`unknown command "{process.args[2]}"`) end
const options = parse(process.args)

if options.problem then reject(options.problem) end
if not fs.exists(options.root) then
	fail(`"{options.root}" does not exist`, "give the folder that holds your Roblox project, like backstage serve .")
end

if fs.type(options.root) ~= "dir" then
	fail(`"{options.root}" is not a folder`, "give the folder that holds your Roblox project, like backstage serve .")
end

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
