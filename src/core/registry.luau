--// Modules
const button = require "./button"
const kinds = require "./kinds"

--// Types
export type entry = {
	path: string,
	name: string,
	group: string,

	descriptor: kinds.descriptor,
	default: kinds.value,
	value: kinds.value,
}

export type button_entry = {
	path: string,
	name: string,

	group: string,
	button: button.button,
}

type listener = (path: string, value: kinds.value, previous: kinds.value) -> ()

--// Variables
const entries = {} :: { [string]: entry }
const buttons = {} :: { [string]: button_entry }
const listeners = {} :: { listener }

--// Functions
const function add(path: string, name: string, group: string, descriptor: kinds.descriptor, default: kinds.value)
	entries[path] = {
		path = path,
		name = name,

		group = group,
		descriptor = descriptor,

		default = default,
		value = default,
	}
end

const function add_button(path: string, name: string, group: string, source: button.button)
	buttons[path] = { path = path, name = name, group = group, button = source }
end

const function get(path: string): kinds.value?
	const found = entries[path]
	if not found then return nil end
	return found.value
end

const function set(path: string, value: unknown)
	const found = entries[path]
	if not found then return false end

	const coerced = kinds.coerce(found.descriptor, value)
	if coerced == nil then return false end

	const previous = found.value
	if coerced == previous then return true end
	found.value = coerced

	for _, listener in table.clone(listeners) do
		listener(path, coerced, previous)
	end

	return true
end

const function press(path: string)
	const found = buttons[path]
	if not found then return false end

	found.button:fire()
	return true
end

const function on_change(listener: listener)
	table.insert(listeners, listener)

	return function()
		const index = table.find(listeners, listener)
		if index then table.remove(listeners, index) end
	end
end

const function sorted_paths(source: { [string]: unknown })
	const paths = {}

	for path in source do
		table.insert(paths, path)
	end

	table.sort(paths)
	return paths
end

const function list()
	const result = {}

	for _, path in sorted_paths(entries) do
		table.insert(result, entries[path])
	end

	return result
end

const function list_buttons()
	const result = {}

	for _, path in sorted_paths(buttons) do
		table.insert(result, buttons[path])
	end

	return result
end

const function reset()
	table.clear(entries)
	table.clear(buttons)
	table.clear(listeners)
end

--// End
return table.freeze {
	add = add,
	add_button = add_button,

	get = get,
	set = set,
	press = press,

	on_change = on_change,
	list = list,

	list_buttons = list_buttons,
	reset = reset,
}
