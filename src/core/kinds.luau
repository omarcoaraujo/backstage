--// Modules
const precision = require "./precision"

--// Constants
const PRECISION = 10

--// Types
export type value = number | boolean | string | Color3 | Vector3

export type limit = {
	min: number?,
	max: number?,

	step: number?,
	choices: { string }?,
}

export type descriptor = {
	kind: "number" | "boolean" | "string" | "color" | "vector3" | "choice",

	min: number?,
	max: number?,

	step: number?,
	choices: { string }?,
}

--// Functions
const function infer(default: unknown, limit: limit?): descriptor?
	if limit and limit.choices then return { kind = "choice", choices = limit.choices } end
	const kind = typeof(default)

	if kind == "number" then
		return {
			kind = "number",
			min = if limit then limit.min else nil,

			max = if limit then limit.max else nil,
			step = if limit then limit.step else nil,
		}
	end

	if kind == "boolean" then return { kind = "boolean" } end
	if kind == "string" then return { kind = "string" } end
	if kind == "Color3" then return { kind = "color" } end
	if kind == "Vector3" then return { kind = "vector3" } end

	return nil
end

const function snap(value: number, descriptor: descriptor)
	const base = descriptor.min or 0
	local result = value

	if descriptor.step and descriptor.step > 0 then
		result = math.round((result - base) / descriptor.step) * descriptor.step + base
		result = tonumber(string.format(`%.{PRECISION}g`, result)) :: number
	end

	return math.clamp(precision.round(result), descriptor.min or -math.huge, descriptor.max or math.huge)
end

const function coerce(descriptor: descriptor, value: unknown): value?
	const kind = descriptor.kind

	if kind == "number" then
		if type(value) ~= "number" or value ~= value or math.abs(value) == math.huge then return nil end
		return snap(value, descriptor)
	end

	if kind == "boolean" then
		if type(value) ~= "boolean" then return nil end
		return value
	end

	if kind == "string" then
		if type(value) ~= "string" then return nil end
		return value
	end

	if kind == "color" then
		if typeof(value) ~= "Color3" then return nil end
		return value :: Color3
	end

	if kind == "vector3" then
		if typeof(value) ~= "Vector3" then return nil end
		const vector = value :: Vector3
		return Vector3.new(precision.round(vector.X), precision.round(vector.Y), precision.round(vector.Z))
	end

	if kind == "choice" then
		if type(value) ~= "string" or not descriptor.choices or not table.find(descriptor.choices, value) then
			return nil
		end

		return value
	end

	return nil
end

--// End
return table.freeze {
	infer = infer,
	coerce = coerce,
}
