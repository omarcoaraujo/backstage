--// Modules
const button = require "./button"
const kinds = require "./kinds"
const tracker = require "./tracker"

--// Types
export type entry = {
	path: string,
	name: string,
	group: string,

	descriptor: kinds.descriptor,
	default: kinds.value,

	hint: string?,
	value: kinds.value,
	remote: boolean,
}

export type button_entry = {
	path: string,
	name: string,

	group: string,
	button: button.button,

	hint: string?,
	remote: boolean,
}

export type snapshot_entry = {
	path: string,
	name: string,

	group: string,
	descriptor: kinds.descriptor,

	default: kinds.value,
	hint: string?,
	value: kinds.value,
}

export type snapshot = {
	entries: { snapshot_entry },
	buttons: { { path: string, name: string, group: string, hint: string? } },
	groups: { [string]: string }?,
}

export type remote = {
	edit: (path: string, value: kinds.value) -> (),
	press: (path: string) -> (),
}

type listener = (path: string, value: kinds.value, previous: kinds.value) -> ()

--// Variables
const entries = {} :: { [string]: entry }
const buttons = {} :: { [string]: button_entry }

const group_hints = {} :: { [string]: string }
const listeners = {} :: { listener }

const register_listeners = {} :: { () -> () }
local remote = nil :: remote?

--// Functions
const function announce()
	for _, listener in table.clone(register_listeners) do
		listener()
	end
end

const function add(
	path: string,
	name: string,

	group: string,
	descriptor: kinds.descriptor,

	default: kinds.value,
	hint: string?
)
	const existing = entries[path]
	const synced = existing ~= nil and existing.remote

	entries[path] = {
		path = path,
		name = name,

		group = group,
		descriptor = descriptor,
		default = default,

		hint = hint,
		value = if synced then existing.value else default,
		remote = synced,
	}
end

const function rebase(path: string, default: kinds.value)
	const found = entries[path]
	if not found then return end
	found.default = default
end

const function add_button(path: string, name: string, group: string, source: button.button, hint: string?)
	const existing = buttons[path]

	buttons[path] = {
		path = path,
		name = name,
		group = group,

		button = source,
		hint = hint,
		remote = existing ~= nil and existing.remote,
	}
end

const function add_group_hint(path: string, hint: string)
	group_hints[path] = hint
end

const function group_hint(path: string): string?
	return group_hints[path]
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
	tracker.write(path, coerced)

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

const function inside(path: string, prefix: string?)
	if not prefix then return true end
	return string.sub(path, 1, #prefix + 1) == `{prefix}.`
end

const function dirty(prefix: string?)
	for path, found in entries do
		if inside(path, prefix) and found.value ~= found.default then return true end
	end

	return false
end

const function restore_group(prefix: string?)
	for _, path in sorted_paths(entries) do
		if inside(path, prefix) then restore(path) end
	end
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

const function snapshot(only_local: boolean?)
	const result = { entries = {}, buttons = {}, groups = table.clone(group_hints) }

	for _, path in sorted_paths(entries) do
		const found = entries[path]
		if only_local and found.remote then continue end
		table.insert(result.entries, {
			path = found.path,
			name = found.name,

			group = found.group,
			descriptor = found.descriptor,

			default = found.default,
			hint = found.hint,
			value = found.value,
		})
	end

	for _, path in sorted_paths(buttons) do
		const found = buttons[path]
		if only_local and found.remote then continue end
		table.insert(result.buttons, { path = found.path, name = found.name, group = found.group, hint = found.hint })
	end

	return result
end

const function import(source: snapshot)
	for _, incoming in source.entries do
		const existing = entries[incoming.path]

		if not existing then
			add(incoming.path, incoming.name, incoming.group, incoming.descriptor, incoming.default, incoming.hint)
			entries[incoming.path].value = incoming.value

			entries[incoming.path].remote = true
			continue
		end

		existing.remote = true
		existing.default = incoming.default

		existing.hint = incoming.hint
		apply(incoming.path, incoming.value)
	end

	for _, incoming in source.buttons do
		const existing = buttons[incoming.path]

		if not existing then
			add_button(incoming.path, incoming.name, incoming.group, button.create(), incoming.hint)
			buttons[incoming.path].remote = true
			continue
		end

		existing.remote = true
		existing.hint = incoming.hint
	end

	if source.groups then
		for path, text in source.groups do
			group_hints[path] = text
		end
	end

	announce()
end

const function adopt(source: snapshot)
	const missing = { entries = {}, buttons = {}, groups = source.groups } :: snapshot

	for _, incoming in source.entries do
		if not entries[incoming.path] then table.insert(missing.entries, incoming) end
	end

	for _, incoming in source.buttons do
		if not buttons[incoming.path] then table.insert(missing.buttons, incoming) end
	end

	if #missing.entries == 0 and #missing.buttons == 0 then return end
	import(missing)
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
	table.clear(group_hints)

	table.clear(listeners)
	table.clear(register_listeners)

	tracker.reset()
	remote = nil
end

--// End
return table.freeze {
	add = add,
	add_button = add_button,
	add_group_hint = add_group_hint,
	rebase = rebase,

	get = get,
	set = set,
	group_hint = group_hint,

	apply = apply,
	restore = restore,
	restore_group = restore_group,

	dirty = dirty,
	press = press,

	snapshot = snapshot,
	import = import,

	adopt = adopt,
	connect_remote = connect_remote,

	announce = announce,
	on_change = on_change,

	on_register = on_register,
	list = list,

	list_buttons = list_buttons,
	reset = reset,
}
