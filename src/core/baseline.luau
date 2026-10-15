--// Modules
const kinds = require "./kinds"

--// Constants
const SHARED_KEY = "backstage_baseline"
const NUMBER_TOLERANCE = 0.00001
const COLOR_TOLERANCE = 0.004

--// Types
type slot = {
	original: { [string]: kinds.value },
	saved: { [string]: kinds.value },
}

--// Functions
const function slot(): slot
	const slots = shared :: any
	const found = slots[SHARED_KEY]

	if found then return found end
	const created = { original = {}, saved = {} }

	slots[SHARED_KEY] = created
	return created
end

const function same(first: kinds.value?, second: kinds.value?): boolean
	if first == second then return true end
	if type(first) == "number" and type(second) == "number" then return math.abs(first - second) < NUMBER_TOLERANCE end

	if typeof(first) == "Vector3" and typeof(second) == "Vector3" then
		return ((first :: any) - (second :: any)).Magnitude < NUMBER_TOLERANCE
	end

	if typeof(first) == "Color3" and typeof(second) == "Color3" then
		const a = first :: Color3
		const b = second :: Color3
		return math.abs(a.R - b.R) < COLOR_TOLERANCE
			and math.abs(a.G - b.G) < COLOR_TOLERANCE
			and math.abs(a.B - b.B) < COLOR_TOLERANCE
	end

	return false
end

const function remember(path: string, value: kinds.value)
	slot().saved[path] = value
end

const function resolve(path: string, default: kinds.value): kinds.value
	const state = slot()
	const original = state.original[path]
	if original ~= nil and same(state.saved[path], default) then return original end

	state.original[path] = default
	state.saved[path] = nil
	return default
end

const function reset()
	const slots = shared :: any
	slots[SHARED_KEY] = nil
end

--// End
return table.freeze {
	remember = remember,
	resolve = resolve,
	reset = reset,
}
