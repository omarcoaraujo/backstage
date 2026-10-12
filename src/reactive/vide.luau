--// Modules
const kinds = require "../core/kinds"
const tracker = require "../core/tracker"

--// Types
type store = (...kinds.value) -> kinds.value
type lib = { source: (initial: kinds.value) -> store }

--// Functions
return function(given: unknown): tracker.adapter
	const vide = given :: lib
	const sources = {} :: { [string]: store }

	const function read(path: string, value: kinds.value)
		local source = sources[path]
		if not source then
			source = vide.source(value)
			sources[path] = source
		end

		source()
	end

	const function write(path: string, value: kinds.value)
		const source = sources[path]
		if source then source(value) end
	end

	const function reset()
		table.clear(sources)
	end

	return { read = read, write = write, reset = reset }
end
