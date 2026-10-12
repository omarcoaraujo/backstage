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
	remote: boolean,
}

export type button_entry = {
	path: string,
	name: string,

	group: string,
	button: button.button,

	remote: boolean,
}

export type snapshot_entry = {
	path: string,
	name: string,

	group: string,
	descriptor: kinds.descriptor,

	default: kinds.value,
	value: kinds.value,
}

export type snapshot = {
	entries: { snapshot_entry },
	buttons: { { path: string, name: string, group: string } },
}

export type remote = {
	edit: (path: string, value: kinds.value) -> (),
	press: (path: string) -> (),
}

type listener = (path: string, value: kinds.value, previous: kinds.value) -> ()

--// Variables
const entries = {} :: { [string]: entry }
const buttons = {} :: { [string]: button_entry }
const listeners = {} :: { listener }

const register_listeners = {} :: { () -> () }
local remote = nil :: remote?

--// Functions
const function announce()
	for _, listener in table.clone(register_listeners) do
		listener()
	end
end

const function add(path: string, name: string, group: string, descriptor: kinds.descriptor, default: kinds.value)
	const existing = entries[path]
	const synced = existing ~= nil and existing.remote

	entries[path] = {
		path = path,
		name = name,

		group = group,
		descriptor = descriptor,
		default = default,

		value = if synced then existing.value else default,
		remote = synced,
	}
end

const function add_button(path: string, name: string, group: string, source: button.button)
	const existing = buttons[path]

	buttons[path] = {
		path = path,
		name = name,
		group = group,

		button = source,
		remote = existing ~= nil and existing.remote,
	}
end

const function get(path: string): kinds.value?
	const found = entries[path]
	if not found then return nil end
	return found.value
end

const function sorted_paths(source: { [string]: unknown })
	const paths = {}

	for path in source do
		table.insert(paths, path)
	end

	table.sort(paths)
	return paths
end

const function write(path: string, value: unknown, forward: boolean)
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

	if forward and found.remote and remote then remote.edit(path, coerced) end
	return true
end

const function set(path: string, value: unknown)
	return write(path, value, true)
end

const function apply(path: string, value: unknown)
	return write(path, value, false)
end

const function restore(path: string)
	const found = entries[path]
	if not found then return false end
	return write(path, found.default, true)
end

const function press(path: string)
	const found = buttons[path]
	if not found then return false end

	found.button:fire()
	if found.remote and remote then remote.press(path) end

	return true
end

const function connect_remote(handler: remote?)
	remote = handler
end

const function snapshot(): snapshot
	const result = { entries = {}, buttons = {} } :: snapshot

	for _, path in sorted_paths(entries) do
		const found = entries[path]

		table.insert(result.entries, {
			path = found.path,
			name = found.name,

			group = found.group,
			descriptor = found.descriptor,

			default = found.default,
			value = found.value,
		})
	end

	for _, path in sorted_paths(buttons) do
		const found = buttons[path]
		table.insert(result.buttons, { path = found.path, name = found.name, group = found.group })
	end

	return result
end

const function import(source: snapshot)
	for _, incoming in source.entries do
		const existing = entries[incoming.path]

		if not existing then
			add(incoming.path, incoming.name, incoming.group, incoming.descriptor, incoming.default)
			entries[incoming.path].value = incoming.value

			entries[incoming.path].remote = true
			continue
		end

		existing.remote = true
		existing.default = incoming.default
		apply(incoming.path, incoming.value)
	end

	for _, incoming in source.buttons do
		const existing = buttons[incoming.path]

		if not existing then
			add_button(incoming.path, incoming.name, incoming.group, button.create())
			buttons[incoming.path].remote = true
			continue
		end

		existing.remote = true
	end

	announce()
end

const function on_change(listener: listener)
	table.insert(listeners, listener)

	return function()
		const index = table.find(listeners, listener)
		if index then table.remove(listeners, index) end
	end
end

const function on_register(listener: () -> ())
	table.insert(register_listeners, listener)

	return function()
		const index = table.find(register_listeners, listener)
		if index then table.remove(register_listeners, index) end
	end
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

	table.clear(register_listeners)
	remote = nil
end

--// End
return table.freeze {
	add = add,
	add_button = add_button,

	get = get,
	set = set,

	apply = apply,
	restore = restore,
	press = press,

	snapshot = snapshot,
	import = import,
	connect_remote = connect_remote,

	announce = announce,
	on_change = on_change,

	on_register = on_register,
	list = list,

	list_buttons = list_buttons,
	reset = reset,
}
