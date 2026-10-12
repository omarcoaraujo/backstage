--// Modules
const kinds = require "../core/kinds"
const tracker = require "../core/tracker"

--// Types
type store = (...kinds.value) -> kinds.value
type lib = { atom: (initial: kinds.value) -> store }

--// Functions
return function(given: unknown): tracker.adapter
	const charm = given :: lib
	const atoms = {} :: { [string]: store }

	const function read(path: string, value: kinds.value)
		local atom = atoms[path]
		if not atom then
			atom = charm.atom(value)
			atoms[path] = atom
		end

		atom()
	end

	const function write(path: string, value: kinds.value)
		const atom = atoms[path]
		if atom then atom(value) end
	end

	const function reset()
		table.clear(atoms)
	end

	return { read = read, write = write, reset = reset }
end
