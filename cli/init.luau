--// Modules
const process = require "@std/process"
const scan = require "@self/scan"
const server = require "@self/server"

--// Constants
const USAGE = "usage: lute run cli <project folder> [--port <number>]"

--// Types
type options = { root: string?, port: number? }

--// Functions
const function parse(args: { string }): options
	const options = {} :: options
	local index = 2

	while index <= #args do
		const argument = args[index]

		if argument == "--port" then
			options.port = tonumber(args[index + 1])
			index += 2
			continue
		end

		options.root = argument
		index += 1
	end

	return options
end

const function describe(root: string)
	local count = 0

	for name, files in scan.scan(root) do
		count += 1
		if #files > 1 then print(`warning: config "{name}" is declared in {#files} files, edits to it are refused`) end
	end

	return count
end

--// End
const options = parse(process.args)
if not options.root or (table.find(process.args, "--port") and not options.port) then
	print(USAGE)
	process.exit(1)
end

const running = server.serve(options.root, options.port)
print(`backstage bridge on ws://{running.hostname}:{running.port}, {describe(options.root)} configs in {options.root}`)
