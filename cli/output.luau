--// Modules
const tint = require "./luau_packages/tint"

--// Constants
const USAGE =
	"backstage serve [project folder] [--port <number>]\n       backstage apply [project folder] [--file <export>]"

--// Functions
const function failure(message: string, hint: string?)
	print(`{tint.red.bold "error:"} {message}`)
	if hint then print(`       {tint.dim(hint)}`) end
end

const function warning(message: string)
	print(`{tint.yellow.bold "warning:"} {message}`)
end

const function pushed(paths: { string })
	for _, path in paths do
		print(`{tint.cyan.bold "backstage"} {tint.bold(path)} changed in the script, sent to the game`)
	end
end

const function applied(count: number, root: string)
	const noun = if count == 1 then "value" else "values"
	print(`{tint.cyan.bold "backstage"} wrote {tint.bold(tostring(count))} {noun} to the scripts in {tint.bold(root)}`)
end

const function usage()
	print(`{tint.dim "usage:"} {USAGE}`)
end

const function serving(count: number, root: string, address: string)
	const noun = if count == 1 then "config" else "configs"

	print(`{tint.cyan.bold "backstage"} serving {tint.bold(tostring(count))} {noun} in {tint.bold(root)}`)
	print(`{tint.dim "listening on"} {tint.underline(address)}{tint.dim ", leave it running next to Studio"}`)
end

--// End
return {
	failure = failure,
	warning = warning,

	pushed = pushed,
	applied = applied,
	
	usage = usage,
	serving = serving,
}
