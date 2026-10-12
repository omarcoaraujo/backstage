--// Utils
const hex = require "./hex"

--// Constants
const DECIMALS = 3
const DECIMAL_SCALE = 10 ^ DECIMALS

--// Functions
const function number(value: number): string
	const rounded = math.round(value * DECIMAL_SCALE) / DECIMAL_SCALE
	if rounded == 0 then return "0" end
	return (string.gsub(string.format(`%.{DECIMALS}f`, rounded), "%.?0+$", ""))
end

const function vector3(value: Vector3): string
	return `{number(value.X)}, {number(value.Y)}, {number(value.Z)}`
end

const function value(input: unknown): string
	const kind = typeof(input)

	if kind == "number" then return number(input :: number) end
	if kind == "string" then return `"{input}"` end
	if kind == "Color3" then return hex.to_hex(input :: Color3) end
	if kind == "Vector3" then return vector3(input :: Vector3) end
	if kind == "Instance" then return (input :: Instance):GetFullName() end
	if kind == "function" then return "function" end
	if kind == "table" then return "{...}" end

	return tostring(input)
end

--// End
return table.freeze {
	number = number,
	value = value,
}
