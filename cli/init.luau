--// Modules
const process = require "@std/process"
const server = require "@self/server"

--// Constants
const USAGE = "usage: lute run cli <config script> [--port <number>]"

--// Types
type options = { script_path: string?, port: number? }

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

		options.script_path = argument
		index += 1
	end

	return options
end

--// End
const options = parse(process.args)

if not options.script_path or (table.find(process.args, "--port") and not options.port) then
	print(USAGE)
	process.exit(1)
end

const running = server.serve(options.script_path, options.port)
print(`backstage bridge on ws://{running.hostname}:{running.port}`)
