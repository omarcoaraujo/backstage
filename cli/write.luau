--// Constants
const DECIMALS = 6

--// Types
type vector = { x: number, y: number, z: number }
type color = { r: number, g: number, b: number }

export type input =
	{ kind: "number", value: number }
	| { kind: "boolean", value: boolean }
	| { kind: "string", value: string }
	| { kind: "color", value: color }
	| { kind: "vector3", value: vector }

--// Functions
const function number_literal(value: number)
	const text = string.format(`%.{DECIMALS}f`, value)
	const trimmed = string.gsub(string.gsub(text, "0+$", ""), "%.$", "")

	if trimmed == "-0" or trimmed == "" then return "0" end
	return trimmed
end

const function string_literal(value: string)
	const escaped = string.gsub(string.gsub(value, "\\", "\\\\"), '"', '\\"')
	return `"{escaped}"`
end

const function literal(input: input): string
	if input.kind == "number" then return number_literal(input.value) end
	if input.kind == "boolean" then return tostring(input.value) end
	if input.kind == "string" then return string_literal(input.value) end

	if input.kind == "color" then
		const value = input.value
		return `Color3.fromRGB({number_literal(value.r)}, {number_literal(value.g)}, {number_literal(value.b)})`
	end

	const value = input.value
	return `Vector3.new({number_literal(value.x)}, {number_literal(value.y)}, {number_literal(value.z)})`
end

const function line_start(source: string, line: number)
	local start = 1

	for _ = 2, line do
		start = (string.find(source, "\n", start, true) :: number) + 1
	end

	return start
end

const function offset(source: string, line: number, column: number)
	return line_start(source, line) + column - 1
end

const function slice(source: string, range)
	const first = line_start(source, range.begin_line) + range.begin_column - 1
	const last = line_start(source, range.end_line) + range.end_column - 1
	return string.sub(source, first, last - 1)
end

const function replace(source: string, range, text: string)
	const first = line_start(source, range.begin_line) + range.begin_column - 1
	const last = line_start(source, range.end_line) + range.end_column - 1
	return string.sub(source, 1, first - 1) .. text .. string.sub(source, last)
end

--// End
return {
	literal = literal,
	replace = replace,

	offset = offset,
	slice = slice,
}
