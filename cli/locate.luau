--// Modules
const parser = require "@std/syntax/parser"

--// Constants
const LITERAL_TAGS = { number = true, string = true, boolean = true }
const CONSTRUCTOR_TYPES = { Color3 = true, Vector3 = true }

--// Types
export type range = {
	begin_line: number,
	begin_column: number,

	end_line: number,
	end_column: number,
}

export type found = { tag: string, range: range }

--// Functions
const function to_range(location)
	return {
		begin_line = location.beginLine,
		begin_column = location.beginColumn,

		end_line = location.endLine,
		end_column = location.endColumn,
	}
end

const function string_text(node): string?
	if node.tag ~= "string" then return nil end
	return node.token.text
end

const function is_config_call(node, name: string)
	if node.tag ~= "call" then return false end
	if node.func.tag ~= "indexname" or node.func.index.text ~= "config" then return false end

	const first = node.arguments[1]
	if not first then return false end
	return string_text(first.node) == name
end

const function find_config_call(node, name: string)
	if type(node) ~= "table" then return nil end
	if is_config_call(node, name) then return node end

	for key, child in node do
		if key == "location" or key == "leadingTrivia" or key == "trailingTrivia" then continue end
		const found = find_config_call(child, name)
		if found then return found end
	end

	return nil
end

const function collect_config_names(node, names: { string }, dynamic: { number })
	if type(node) ~= "table" then return end

	if node.tag == "call" and node.func.tag == "indexname" and node.func.index.text == "config" then
		const first = node.arguments[1]
		const name = if first then string_text(first.node) else nil

		if name then
			table.insert(names, name)
		elseif first then
			table.insert(dynamic, node.location.beginLine)
		end
	end

	for key, child in node do
		if key == "location" or key == "leadingTrivia" or key == "trailingTrivia" then continue end
		collect_config_names(child, names, dynamic)
	end
end

const function config_names(source: string): ({ string }, { number })
	const names = {}
	const dynamic = {}

	collect_config_names(parser.parse(source).root, names, dynamic)
	return names, dynamic
end

const function find_function(node, name: string)
	if type(node) ~= "table" then return nil end
	if node.tag == "localfunction" and node.name.name.text == name then return node.func end

	for key, child in node do
		if key == "location" or key == "leadingTrivia" or key == "trailingTrivia" then continue end
		const found = find_function(child, name)
		if found then return found end
	end

	return nil
end

const function returned_table(func)
	for _, statement in func.body.statements do
		if statement.tag ~= "return" then continue end

		const first = statement.expressions[1]
		if first and first.node.tag == "table" then return first.node end
	end

	return nil
end

const function parameter_index(func, name: string): number?
	for index, parameter in func.parameters do
		if parameter.node.name.text == name then return index end
	end

	return nil
end

const function enter_call(root, call)
	if call.func.tag ~= "local" then return nil end
	const func = find_function(root, call.func.token.text)

	if not func then return nil end
	const returned = returned_table(func)

	if not returned then return nil end
	return { call = call, func = func, returned = returned }
end

const function find_entry(table_node, key: string)
	const position = tonumber(key)
	local items = 0

	for _, entry in table_node.entries do
		if entry.kind == "list" then
			items += 1
			if items == position then return entry end
			continue
		end

		if entry.key and entry.key.text == key then return entry end
	end

	return nil
end

const function is_negative_number(node)
	return node.tag == "unary" and node.operand.tag == "number"
end

const function is_constructor(node)
	if node.tag ~= "call" or node.func.tag ~= "indexname" then return false end
	const target = node.func.expression
	return target.tag == "global" and CONSTRUCTOR_TYPES[target.name.text] == true
end

const function is_literal(node)
	return LITERAL_TAGS[node.tag] == true or is_negative_number(node) or is_constructor(node)
end

const function owning_name(names: { string }, path: string): string?
	local owner = nil :: string?

	for _, name in names do
		if string.sub(path, 1, #name + 1) ~= `{name}.` then continue end
		if owner and #owner >= #name then continue end
		owner = name
	end

	return owner
end

const function collect_calls(node, calls: { any })
	if type(node) ~= "table" then return end

	if node.tag == "call" and node.func.tag == "indexname" and node.func.index.text == "config" then
		table.insert(calls, node)
	end

	for key, child in node do
		if key == "location" or key == "leadingTrivia" or key == "trailingTrivia" then continue end
		collect_calls(child, calls)
	end
end

const function argument_for(entered, node)
	if not entered or node.tag ~= "local" then return node end

	const index = parameter_index(entered.func, node.token.text)
	const argument = if index then entered.call.arguments[index] else nil

	if not argument then return node end
	return argument.node
end

const function collect_literals(root, table_node, prefix: string, found: { [string]: found }, entered)
	local items = 0

	for _, entry in table_node.entries do
		local key = nil :: string?

		if entry.kind == "list" then
			items += 1
			key = tostring(items)
		elseif entry.key then
			key = entry.key.text
		end

		if not key then continue end
		const path = `{prefix}.{key}`

		if entry.value.tag == "table" then
			collect_literals(root, entry.value, path, found, entered)
			continue
		end

		if entry.value.tag == "call" and not is_constructor(entry.value) then
			const inside = enter_call(root, entry.value)
			if inside then collect_literals(root, inside.returned, path, found, inside) end
			continue
		end

		const value = argument_for(entered, entry.value)
		if is_literal(value) then found[path] = { tag = value.tag, range = to_range(value.location) } end
	end
end

const function literals(source: string): { [string]: found }
	const found = {} :: { [string]: found }
	const calls = {}

	const root = parser.parse(source).root
	collect_calls(root, calls)

	for _, call in calls do
		const first = call.arguments[1]
		const name = if first then string_text(first.node) else nil
		const defaults = call.arguments[2]

		if not name or not defaults or defaults.node.tag ~= "table" then continue end
		collect_literals(root, defaults.node, name, found, nil)
	end

	return found
end

const function locate(source: string, path: string): (found?, string?)
	const names = config_names(source)
	const name = owning_name(names, path)
	if not name then return nil, `config "{string.match(path, "^[^%.]+")}" not found` end

	const segments = string.split(string.sub(path, #name + 2), ".")
	const root = parser.parse(source).root

	const call = find_config_call(root, name)
	if not call then return nil, `config "{name}" not found` end

	const defaults = call.arguments[2]
	if not defaults or defaults.node.tag ~= "table" then return nil, `config "{name}" has no defaults table` end

	local current = defaults.node
	local entered = nil

	for _, segment in segments do
		if current.tag == "call" then
			entered = enter_call(root, current)
			if not entered then return nil, `"{segment}" is inside a call that does not return a table literal` end
			current = entered.returned
		end

		if current.tag ~= "table" then return nil, `"{segment}" is inside a value that is not a table` end
		const entry = find_entry(current, segment)

		if not entry then return nil, `"{segment}" not found in the defaults` end
		current = entry.value
	end

	if entered and current.tag == "local" then
		const index = parameter_index(entered.func, current.token.text)
		const argument = if index then entered.call.arguments[index] else nil
		if argument then current = argument.node end
	end

	if not is_literal(current) then return nil, `"{path}" is not a literal` end
	return { tag = current.tag, range = to_range(current.location) }
end

--// End
return {
	locate = locate,
	literals = literals,

	config_names = config_names,
	owning_name = owning_name,
}
