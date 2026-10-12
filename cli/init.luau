--// Modules
const process = require "@std/process"
const server = require "@self/server"

--// Variables
const script_path = process.args[2]
const port = tonumber(process.args[3])

--// End
if not script_path then
	print "usage: lute run cli <config script> [port]"
	process.exit(1)
end

const running = server.serve(script_path :: string, port)
print(`backstage bridge on http://{running.hostname}:{running.port}`)
