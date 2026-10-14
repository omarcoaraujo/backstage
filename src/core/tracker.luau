--// Modules
const kinds = require "./kinds"

--// Types
export type adapter = {
	read: (path: string, value: kinds.value) -> (),
	write: (path: string, value: kinds.value) -> (),
	reset: () -> (),
}

export type access = {
	path: string,
	value: kinds.value,

	source: string?,
	line: number?,
	caller: unknown,
}

--// Constants
const MAX_PENDING = 16

--// Variables
const adapters = {} :: { adapter }
local pending = {} :: { access }
local expiring = false

--// Functions
const function expire_pending()
	if expiring then return end
	expiring = true

	task.defer(function()
		pending = {}
		expiring = false
	end)
end

const function add(adapter: adapter)
	table.insert(adapters, adapter)

	return function()
		const index = table.find(adapters, adapter)
		if index then table.remove(adapters, index) end
	end
end

const function read(path: string, value: kinds.value, source: string?, line: number?, caller: unknown)
	table.insert(pending, { path = path, value = value, source = source, line = line, caller = caller } :: access)
	if #pending > MAX_PENDING then table.remove(pending, 1) end

	expire_pending()
	for _, adapter in adapters do
		adapter.read(path, value)
	end
end

const function take()
	const found = pending
	pending = {}
	return found
end

const function write(path: string, value: kinds.value)
	for _, adapter in table.clone(adapters) do
		adapter.write(path, value)
	end
end

const function reset()
	pending = {}

	for _, adapter in adapters do
		adapter.reset()
	end
end

--// End
return table.freeze {
	add = add,
	read = read,

	take = take,
	write = write,
	reset = reset,
}
