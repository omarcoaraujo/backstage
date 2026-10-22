--// Modules
const apply = require "./apply"
const locate = require "./locate"
const write = require "./write"

--// Constants
const TOLERANCE = 0.000001
const ESCAPES = { n = "\n", t = "\t", r = "\r" }

--// Types
export type snapshot = { [string]: write.input }

--// Functions
const function unescape(text: string)
	return (string.gsub(text, "\\(.)", function(character)
		return ESCAPES[character] or character
	end))
end

const function parse_string(text: string): string?
	const quote = string.sub(text, 1, 1)
	if quote ~= '"' and quote ~= "'" then return nil end

	if string.sub(text, -1) ~= quote or #text < 2 then return nil end
	return unescape(string.sub(text, 2, -2))
end

const function parse_numbers(text: string, constructor: string, count: number): { number }?
	const pattern = `^{constructor}%(([^%)]*)%)$`
	const inside = string.match(text, pattern)

	if not inside then return nil end
	const numbers = {}

	for part in string.gmatch(inside, "[^,]+") do
		const number = tonumber(part)
		if not number then return nil end
		table.insert(numbers, number)
	end

	if #numbers ~= count then return nil end
	return numbers
end

const function parse_color(text: string): write.input?
	const rgb = parse_numbers(text, "Color3%.fromRGB", 3)
	if rgb then return { kind = "color", value = { r = rgb[1], g = rgb[2], b = rgb[3] } } end

	const unit = parse_numbers(text, "Color3%.new", 3)
	if not unit then return nil end

	return { kind = "color", value = { r = unit[1] * 255, g = unit[2] * 255, b = unit[3] * 255 } }
end

const function parse_vector(text: string): write.input?
	const axes = parse_numbers(text, "Vector3%.new", 3)
	if not axes then return nil end
	return { kind = "vector3", value = { x = axes[1], y = axes[2], z = axes[3] } }
end

const function parse(text: string): write.input?
	const compact = string.gsub(text, "%s", "")

	if compact == "true" then return { kind = "boolean", value = true } end
	if compact == "false" then return { kind = "boolean", value = false } end

	const number = tonumber(compact)
	if number then return { kind = "number", value = number } end

	const quoted = parse_string(text)
	if quoted then return { kind = "string", value = quoted } end

	return parse_color(compact) or parse_vector(compact)
end

const function close(first: number, second: number)
	return math.abs(first - second) < TOLERANCE
end

const function same(first: write.input, second: write.input)
	if first.kind ~= second.kind then return false end

	if first.kind == "number" and second.kind == "number" then return close(first.value, second.value) end

	if first.kind == "color" and second.kind == "color" then
		return close(first.value.r, second.value.r)
			and close(first.value.g, second.value.g)
			and close(first.value.b, second.value.b)
	end

	if first.kind == "vector3" and second.kind == "vector3" then
		return close(first.value.x, second.value.x)
			and close(first.value.y, second.value.y)
			and close(first.value.z, second.value.z)
	end

	return first.value == second.value
end

const function read(source: string): snapshot
	const snapshot = {} :: snapshot

	for path, found in locate.literals(source) do
		const value = parse(write.slice(source, found.range))
		if value then snapshot[path] = value end
	end

	return snapshot
end

const function changes(previous: snapshot, current: snapshot): { apply.edit }
	const changed = {} :: { apply.edit }

	for path, before in previous do
		const after = current[path]
		if not after or same(before, after) then continue end

		const copy: unknown = table.clone(after)
		const edit = copy :: apply.edit

		edit.path = path
		table.insert(changed, edit)
	end

	table.sort(changed, function(left, right)
		return left.path < right.path
	end)

	return changed
end

--// End
return {
	read = read,
	changes = changes,
	same = same,
}
