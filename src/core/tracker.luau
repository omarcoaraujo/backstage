--// Modules
const kinds = require "./kinds"

--// Types
export type adapter = {
	read: (path: string, value: kinds.value) -> (),
	write: (path: string, value: kinds.value) -> (),
	reset: () -> (),
}

--// Variables
const adapters = {} :: { adapter }

--// Functions
const function add(adapter: adapter)
	table.insert(adapters, adapter)

	return function()
		const index = table.find(adapters, adapter)
		if index then table.remove(adapters, index) end
	end
end

const function read(path: string, value: kinds.value)
	for _, adapter in adapters do
		adapter.read(path, value)
	end
end

const function write(path: string, value: kinds.value)
	for _, adapter in table.clone(adapters) do
		adapter.write(path, value)
	end
end

const function reset()
	for _, adapter in adapters do
		adapter.reset()
	end
end

--// End
return table.freeze {
	add = add,
	read = read,

	write = write,
	reset = reset,
}
