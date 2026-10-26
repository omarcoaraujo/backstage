--// Modules
const locate = require "./locate"
const write = require "./write"

--// Constants
const IDENTIFIER = "^[%a_][%w_]*$"
const FORBIDDEN_IN_KEY = '["\\\n\r]'

--// Functions
const function parent_of(path: string)
	return string.match(path, "^(.*)%.[^%.]+$")
end

const function key_of(path: string)
	return string.match(path, "([^%.]+)$") :: string
end

const function key_prefix(template, key: string): string?
	if string.find(key, FORBIDDEN_IN_KEY) then return nil end
	if tonumber(key) then return `[{key}] = ` end
	if template.kind == "general" or not string.match(key, IDENTIFIER) then return `["{key}"] = ` end

	return `{key} = `
end

const function count_items(owner)
	local items = 0

	for _, entry in owner.entries do
		if entry.kind ~= "list" then continue end
		items += 1
	end

	return items
end

const function end_of(entry)
	const separator = entry.separator
	if separator then return separator.location.endLine, separator.location.endColumn end
	return entry.location.endLine, entry.location.endColumn
end

const function line_end(source: string, from: number)
	const found = string.find(source, "\n", from, true)
	if not found then return #source + 1, "\n" end

	if string.sub(source, found - 1, found - 1) == "\r" then return found - 1, "\r\n" end
	return found, "\n"
end

const function indent_of(source: string, entry)
	const begin = write.offset(source, entry.location.beginLine, 1)
	const before =
		string.sub(source, begin, write.offset(source, entry.location.beginLine, entry.location.beginColumn) - 1)

	if string.match(before, "^%s*$") then return before end
	return "\t"
end

const function insert_at(source: string, position: number, text: string)
	return string.sub(source, 1, position - 1) .. text .. string.sub(source, position)
end

const function add(source: string, path: string, from: string): (string?, string?)
	const parent = parent_of(path)
	if not parent or parent ~= parent_of(from) then return nil, `"{from}" is not next to "{path}"` end

	const target, reason = locate.entry(source, path)
	if not target then return nil, reason end

	if target.entry then return nil, `"{path}" already exists` end
	if target.entered then return nil, `"{parent}" is built by a function, so the script cannot grow it` end

	const origin = locate.entry(source, from)
	if not origin or not origin.entry then return nil, `"{from}" not found in the defaults` end

	const owner = target.owner
	const template = origin.entry

	const key = key_of(path)
	local prefix = ""

	if template.kind == "list" then
		if tonumber(key) ~= count_items(owner) + 1 then
			return nil, `"{key}" is not the next position, and a list without keys cannot skip one`
		end
	else
		const written = key_prefix(template, key)
		if not written then return nil, `"{key}" cannot be written as a key` end
		prefix = written
	end

	const created = prefix .. write.slice(source, locate.to_range(template.value.location))
	const last = owner.entries[#owner.entries]

	if owner.openBrace.location.beginLine == owner.closeBrace.location.beginLine then
		const position = write.offset(source, last.location.endLine, last.location.endColumn)
		return insert_at(source, position, `, {created}`)
	end

	const end_line, end_column = end_of(last)
	if end_line == owner.closeBrace.location.beginLine then
		return nil, `"{parent}" closes on the same line as its last entry, so the script cannot grow it`
	end

	const position, newline = line_end(source, write.offset(source, end_line, end_column))
	local result = insert_at(source, position, `{newline}{indent_of(source, last)}{created},`)

	if not last.separator then
		result = insert_at(result, write.offset(source, last.location.endLine, last.location.endColumn), ",")
	end

	return result, nil
end

const function remove(source: string, path: string): (string?, string?)
	const target, reason = locate.entry(source, path)
	if not target then return nil, reason end

	const entry = target.entry
	if not entry then return nil, `"{path}" not found in the defaults` end
	if target.entered then return nil, `"{key_of(path)}" is built by a function, so the script cannot shrink it` end

	const entries = target.owner.entries
	local position = 0

	for index, candidate in entries do
		if candidate == entry then position = index end
	end

	if entry.kind == "list" then
		for index = position + 1, #entries do
			if entries[index].kind ~= "list" then continue end
			return nil,
				`"{key_of(path)}" is not the last item of a list without keys, so removing it would renumber the rest`
		end
	end

	const begin_line = entry.location.beginLine
	const end_line, end_column = end_of(entry)

	const begin_offset = write.offset(source, begin_line, entry.location.beginColumn)
	const end_offset = write.offset(source, end_line, end_column)

	const line_begin = write.offset(source, begin_line, 1)
	const stop = line_end(source, end_offset)

	const alone_before = string.match(string.sub(source, line_begin, begin_offset - 1), "^%s*$") ~= nil
	const rest = string.sub(source, end_offset, stop - 1)
	const alone_after = string.match(rest, "^%s*$") ~= nil or string.match(rest, "^%s*%-%-") ~= nil

	if alone_before and alone_after then
		const newline_end = (string.find(source, "\n", end_offset, true) or #source)
		return string.sub(source, 1, line_begin - 1) .. string.sub(source, newline_end + 1), nil
	end

	if entry.separator then
		const spaces = string.match(string.sub(source, end_offset), "^[ \t]*") :: string
		return string.sub(source, 1, begin_offset - 1) .. string.sub(source, end_offset + #spaces), nil
	end

	const previous = entries[position - 1]
	if not previous then return string.sub(source, 1, begin_offset - 1) .. string.sub(source, end_offset), nil end

	const previous_end = write.offset(source, previous.location.endLine, previous.location.endColumn)
	return string.sub(source, 1, previous_end - 1) .. string.sub(source, end_offset), nil
end

--// End
return {
	add = add,
	remove = remove,
}
