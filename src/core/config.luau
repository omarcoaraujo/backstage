--// Modules
const button = require "./button"
const each = require "./each"
const kinds = require "./kinds"
const mode = require "./mode"
const registry = require "./registry"
const tracker = require "./tracker"

--// Types
type tree = { [string]: unknown }
export type options<limits, hints = { [string]: any }> = { limits: limits?, hints: hints? }
type node = { [string]: kinds.value | button.button | node }

type member =
	{ kind: "group", proxy: node }
	| { kind: "entry", path: string }
	| { kind: "button", button: button.button }
	| { kind: "plain", value: unknown }

--// Variables
const declared = {} :: { [string]: tree }

--// Functions
const function read_only()
	error("attempt to modify a read-only table", 3)
end

const function sorted_keys(source: { [string]: member })
	const keys = {}

	for key in source do
		table.insert(keys, key)
	end

	table.sort(keys, function(left: unknown, right: unknown)
		if type(left) == "number" and type(right) == "number" then return left < right end
		if type(left) == "number" then return true end
		if type(right) == "number" then return false end

		return (left :: string) < (right :: string)
	end)

	return keys
end

const function resolve(
	members: { [string]: member },
	key: string,

	source: string?,
	line: number?,
	caller: unknown
): unknown
	const found = members[key]
	if not found then return nil end

	if found.kind == "group" then return found.proxy end
	if found.kind == "button" then return found.button end
	if found.kind == "plain" then return found.value end

	const value = registry.get(found.path)
	if value == nil then return nil end

	tracker.read(found.path, value, source, line, caller)
	return value
end

const function signature(value: unknown): string
	if type(value) ~= "table" then return typeof(value) end
	if button.is_button(value) then return "button" end

	const parts = {}
	for key, child in value :: node do
		table.insert(parts, `{key}:{signature(child)}`)
	end

	table.sort(parts)
	return `\{{table.concat(parts, ",")}\}`
end

const function template_of(source: node): string?
	local template = nil :: string?
	local expected = nil :: string?
	local count = 0

	for key, value in source do
		if type(value) ~= "table" and type(key) ~= "number" then return nil end

		const current = signature(value)
		if expected ~= nil and current ~= expected then return nil end

		template = key
		expected = current
		count += 1
	end

	if count < 2 then return nil end
	return template
end

const function clone_defaults(value: unknown): unknown
	if type(value) ~= "table" then return value end
	if button.is_button(value) then return button.create() end

	const copy = {}
	for key, child in value :: node do
		copy[key] = clone_defaults(child)
	end

	return copy
end

const function push_leaves(prefix: string, value: unknown)
	if type(value) ~= "table" then
		registry.push(prefix, value)
		return
	end

	if button.is_button(value) then return end
	for key, child in value :: node do
		push_leaves(`{prefix}.{key}`, child)
	end
end

const function current_values(prefix: string): unknown
	const exact = registry.get(prefix)
	if exact ~= nil then return exact end
	const tree = {} :: { [string]: any }

	for _, entry in registry.list() do
		if not registry.inside(entry.path, prefix) then continue end

		const segments = string.split(string.sub(entry.path, #prefix + 2), ".")
		local node = tree

		for index = 1, #segments - 1 do
			node[segments[index]] = node[segments[index]] or {}
			node = node[segments[index]]
		end

		node[segments[#segments]] = entry.value
	end

	return tree
end

const function build_group(source: node, limits: tree?, hints: tree?, path: string)
	const members = {} :: { [string]: member }
	const original = {} :: { [unknown]: boolean }

	const committed = {} :: { [unknown]: unknown }
	const template = template_of(source)

	for key in source do
		original[key] = true
	end

	const function add_member(key: string, value: unknown)
		const member_path = `{path}.{key}`
		const limit = each.resolve(limits, key)

		const hint = each.resolve(hints, key)
		const text = if type(hint) == "string" then hint else nil

		if type(value) == "table" and button.is_button(value) then
			const pressable = value :: button.button
			registry.add_button(member_path, key, path, pressable, text)

			members[key] = { kind = "button", button = pressable }
			return
		end

		if type(value) == "table" then
			members[key] = {
				kind = "group",
				proxy = build_group(value :: node, limit :: tree?, hint :: tree?, member_path),
			}

			return
		end

		const descriptor = kinds.infer(value, limit)
		if not descriptor then
			members[key] = { kind = "plain", value = value }
			return
		end

		registry.add(member_path, tostring(key), path, descriptor, value :: kinds.value, text)
		members[key] = { kind = "entry", path = member_path }
	end

	const function insert(name: any): (string?, string?)
		add_member(name, clone_defaults(source[template :: string]))
		return `{path}.{name}`, `{path}.{template}`
	end

	const function populate(key: string)
		const numbered = type(template) == "number"
		const name = if numbered then tonumber(key) :: any else key
		if name == nil or members[name] == nil then return end

		const known = if committed[name] ~= nil then committed[name] else source[name]
		push_leaves(`{path}.{name}`, known)
	end

	const function grow(key: string): (string?, string?)
		const numbered = type(template) == "number"
		const name = if numbered then tonumber(key) :: any else key

		if numbered and not string.match(key, "^%d+$") then return nil, "needs a number" end
		if not numbered and not string.match(key, "^[%a_][%w_]*$") then return nil, "not a valid name" end
		if members[name] ~= nil then return nil, "already exists" end

		return insert(name)
	end

	const function shrink(key: string): string?
		const numbered = type(template) == "number"
		const name = if numbered then tonumber(key) :: any else key
		if name == nil or members[name] == nil then return nil end

		members[name] = nil
		registry.remove(`{path}.{name}`)

		return `{path}.{name}`
	end

	const function bring_back(key: string): string?
		const numbered = type(template) == "number"
		const name = if numbered then tonumber(key) :: any else key

		if name == nil or members[name] ~= nil then return nil end
		return (insert(name))
	end

	const function reinsert(key: string): string?
		const added = bring_back(key)
		if not added then return nil end

		populate(key)
		return added
	end

	const function keys(): { string }
		const result = {}

		for key in members do
			table.insert(result, tostring(key))
		end

		return result
	end

	const function changed()
		for key in members do
			if not original[key] then return true end
		end

		for key in original do
			if members[key :: any] == nil then return true end
		end

		return false
	end

	const function commit()
		table.clear(original)
		table.clear(committed)

		for key in members do
			original[key] = true
			committed[key] = current_values(`{path}.{key}`)
		end
	end

	const function revert(): { registry.change }
		const changes = {} :: { registry.change }

		for _, key in sorted_keys(members) do
			if original[key] then continue end
			const removed = shrink(tostring(key))
			if removed then table.insert(changes, { kind = "remove", path = removed }) end
		end

		for _, key in sorted_keys(original :: any) do
			const added = bring_back(tostring(key))
			if not added then continue end
			table.insert(changes, { kind = "restore", path = added })
		end

		return changes
	end

	const function index(_, key: string)
		const caller, source, line = debug.info(2, "fsl")
		return resolve(members, key, source, line, caller)
	end

	const function iterate()
		const snapshot = {}

		for _, key in sorted_keys(members) do
			const current = resolve(members, key)
			if current ~= nil then snapshot[key] = current end
		end

		return next, snapshot
	end

	const function length()
		local count = 0

		for key in members do
			if type(key) ~= "number" then return 0 end
			count += 1
		end

		for position = 1, count do
			if members[position :: any] == nil then return 0 end
		end

		return count
	end

	for key, value in source do
		add_member(key, value)
	end

	const proxy = setmetatable({}, { __index = index, __newindex = read_only, __iter = iterate, __len = length })
	registry.add_group(
		proxy,
		path,
		if template ~= nil
			then {
				add = grow,
				remove = shrink,

				reinsert = reinsert,
				populate = populate,

				keys = keys,
				changed = changed,

				commit = commit,
				revert = revert,
			}
			else nil
	)

	return proxy :: any
end

const function freeze_copy<T>(source: T): T
	const tree: unknown = source
	const copy = {} :: node

	for key, value in tree :: node do
		if type(value) ~= "table" then
			copy[key] = value
		elseif button.is_button(value) then
			copy[key] = button.create_inert()
		else
			copy[key] = freeze_copy(value :: node)
		end
	end

	const frozen: unknown = table.freeze(copy)
	return frozen :: T
end

const function shadowed_key(outer: string, outer_defaults: tree, inner: string): string?
	if string.sub(inner, 1, #outer + 1) ~= `{outer}.` then return nil end
	const key = string.match(string.sub(inner, #outer + 2), "^[^%.]+") :: string

	if outer_defaults[key] == nil then return nil end
	return key
end

const function warn_shadowed(name: string, defaults: tree)
	for other, other_defaults in declared do
		if other == name then continue end

		const inside_other = shadowed_key(other, other_defaults, name)
		const inside_name = shadowed_key(name, defaults, other)

		const key = inside_other or inside_name
		if not key then continue end

		const outer = if inside_other then other else name
		warn(
			`[backstage] config "{other}" and "{name}" both define "{outer}.{key}", so edits to it are saved to the longer name`
		)
	end

	declared[name] = defaults
end

const function config<settings, limits, hints>(name: string, defaults: settings, options: options<limits, hints>?): settings
	if not mode.active() then return freeze_copy(defaults) end
	warn_shadowed(name, defaults :: any)

	const given_limits = if options then options.limits else nil :: any
	const given_hints = if options then options.hints else nil :: any

	const group = build_group(defaults :: any, given_limits :: tree?, given_hints :: tree?, name)
	registry.announce()

	return group :: any
end

--// End
return config
