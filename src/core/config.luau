--// Modules
const button = require "./button"
const kinds = require "./kinds"
const mode = require "./mode"
const registry = require "./registry"
const tracker = require "./tracker"

--// Types
type tree = { [string]: unknown }
export type options<limits> = { limits: limits?, hints: { [string]: any }? }
type node = { [string]: kinds.value | button.button | node }

type member =
	{ kind: "group", proxy: node }
	| { kind: "entry", path: string }
	| { kind: "button", button: button.button }

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

	table.sort(keys)
	return keys
end

const function resolve(
	members: { [string]: member },
	key: string,

	source: string?,
	line: number?,
	caller: unknown
): (kinds.value | button.button | node)?
	const found = members[key]
	if not found then return nil end

	if found.kind == "group" then return found.proxy end
	if found.kind == "button" then return found.button end

	const value = registry.get(found.path)
	if value == nil then return nil end

	tracker.read(found.path, value, source, line, caller)
	return value
end

const function build_group(source: node, limits: tree?, hints: tree?, path: string)
	const members = {} :: { [string]: member }

	for key, value in source do
		const member_path = `{path}.{key}`
		const limit = if limits then limits[key] else nil

		const hint = if hints then hints[key] else nil
		const text = if type(hint) == "string" then hint else nil

		if type(value) == "table" and button.is_button(value) then
			const pressable = value :: button.button
			registry.add_button(member_path, key, path, pressable, text)

			members[key] = { kind = "button", button = pressable }
			continue
		end

		if type(value) == "table" then
			members[key] = {
				kind = "group",
				proxy = build_group(value :: node, limit :: tree?, hint :: tree?, member_path),
			}

			continue
		end

		const descriptor = kinds.infer(value, limit)
		if not descriptor then error(`backstage: unsupported value for {member_path}`, 0) end

		registry.add(member_path, key, path, descriptor, value :: kinds.value, text)
		members[key] = { kind = "entry", path = member_path }
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

	const proxy = setmetatable({}, { __index = index, __newindex = read_only, __iter = iterate, __len = length })
	registry.add_group(proxy, path)

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

const function config<settings, limits>(name: string, defaults: settings, options: options<limits>?): settings
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
