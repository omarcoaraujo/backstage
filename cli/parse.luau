--// Modules
const apply = require "./apply"

--// Types
type edit = apply.edit

--// Functions
const function unescape(inner: string)
	return (
		string.gsub(inner, "\\(.)", function(character)
			if character == "n" then return "\n" end
			return character
		end)
	)
end

const function numbers(text: string, count: number): { number }?
	const found = {}

	for part in string.gmatch(text, "[^,]+") do
		const value = tonumber((string.match(part, "^%s*(.-)%s*$")))
		if not value or value ~= value then return nil end
		table.insert(found, value)
	end

	if #found ~= count then return nil end
	return found
end

const function literal(path: string, text: string): edit?
	const value = tonumber(text)
	if value and value == value then return { path = path, kind = "number", value = value } end

	if text == "true" then return { path = path, kind = "boolean", value = true } end
	if text == "false" then return { path = path, kind = "boolean", value = false } end

	const quoted = string.match(text, '^"(.*)"$')
	if quoted then return { path = path, kind = "string", value = unescape(quoted) } end

	const color = string.match(text, "^Color3%.fromRGB%((.*)%)$")
	const channels = if color then numbers(color, 3) else nil
	if channels then
		return { path = path, kind = "color", value = { r = channels[1], g = channels[2], b = channels[3] } }
	end

	const vector = string.match(text, "^Vector3%.new%((.*)%)$")
	const axes = if vector then numbers(vector, 3) else nil
	if axes then return { path = path, kind = "vector3", value = { x = axes[1], y = axes[2], z = axes[3] } } end

	return nil
end

const function parse(text: string): ({ edit }, { string })
	const edits = {} :: { edit }
	const problems = {} :: { string }
	local number = 0

	for line in string.gmatch(text .. "\n", "([^\n]*)\n") do
		number += 1

		const trimmed = string.gsub(line, "\r$", "")
		if string.match(trimmed, "^%s*$") then continue end

		const path, value = string.match(trimmed, "^%s*([^%s=]+)%s*=%s*(.-)%s*$")
		const edit = if path and value then literal(path, value) else nil

		if not edit then
			table.insert(problems, `line {number}: could not read "{trimmed}"`)
			continue
		end

		table.insert(edits, edit)
	end

	return edits, problems
end

--// End
return { parse = parse }
