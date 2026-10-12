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

const function collect_config_names(node, names: { string })
	if type(node) ~= "table" then return end

	if node.tag == "call" and node.func.tag == "indexname" and node.func.index.text == "config" then
		const first = node.arguments[1]
		const name = if first then string_text(first.node) else nil
		if name then table.insert(names, name) end
	end

	for key, child in node do
		if key == "location" or key == "leadingTrivia" or key == "trailingTrivia" then continue end
		collect_config_names(child, names)
	end
end

const function config_names(source: string): { string }
	const names = {}
	collect_config_names(parser.parse(source).root, names)
	return names
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

const function locate(source: string, path: string): (found?, string?)
	const segments = string.split(path, ".")
	const name = table.remove(segments, 1) :: string

	const call = find_config_call(parser.parse(source).root, name)
	if not call then return nil, `config "{name}" not found` end

	const defaults = call.arguments[2]
	if not defaults or defaults.node.tag ~= "table" then return nil, `config "{name}" has no defaults table` end

	local current = defaults.node
	for _, segment in segments do
		if current.tag ~= "table" then return nil, `"{segment}" is inside a value that is not a table` end
		const entry = find_entry(current, segment)

		if not entry then return nil, `"{segment}" not found in the defaults` end
		current = entry.value
	end

	if not is_literal(current) then return nil, `"{path}" is not a literal` end

	return { tag = current.tag, range = to_range(current.location) }
end

--// End
return { locate = locate, config_names = config_names }
