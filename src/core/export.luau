--// Modules
const kinds = require "./kinds"
const precision = require "./precision"

--// Types
type entry = { path: string, value: kinds.value, default: kinds.value, decimals: number? }

--// Functions
const function number(value: number, decimals: number?)
	return precision.text(value, decimals)
end

const function channel(value: number)
	return tostring(math.round(value * 255))
end

const function quoted(value: string)
	const escaped = string.gsub(string.gsub(string.gsub(value, "\\", "\\\\"), '"', '\\"'), "\n", "\\n")
	return `"{escaped}"`
end

const function literal(value: kinds.value, decimals: number?)
	if type(value) == "number" then return number(value, decimals) end
	if type(value) == "boolean" then return tostring(value) end
	if type(value) == "string" then return quoted(value) end

	if typeof(value) == "Color3" then
		const color = value :: Color3
		return `Color3.fromRGB({channel(color.R)}, {channel(color.G)}, {channel(color.B)})`
	end

	const vector = value :: Vector3
	return `Vector3.new({number(vector.X)}, {number(vector.Y)}, {number(vector.Z)})`
end

const function text(entries: { entry }): string
	const lines = {}

	for _, entry in entries do
		if entry.value == entry.default then continue end
		table.insert(lines, `{entry.path} = {literal(entry.value, entry.decimals)}`)
	end

	return table.concat(lines, "\n")
end

--// End
return table.freeze {
	text = text,
}
