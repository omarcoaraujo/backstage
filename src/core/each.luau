--// Modules
const mode = require "./mode"

--// Types
type tree = { [any]: unknown }

--// Constants
const EVERY_ENTRY = table.freeze {}

--// Functions
const function merge(common: unknown, explicit: unknown): unknown
	if explicit == nil then return common end
	if type(common) ~= "table" or type(explicit) ~= "table" then return explicit end
	if (explicit :: tree)[1] ~= nil then return explicit end

	const merged = table.clone(common :: tree)
	for key, value in explicit :: tree do
		merged[key] = merge((common :: tree)[key], value)
	end

	return merged
end

const function resolve(source: unknown, key: unknown): unknown
	if type(source) ~= "table" then return nil end
	const entries = source :: tree
	return merge(entries[EVERY_ENTRY], entries[key])
end

const function create<common>(common: common, overrides: unknown?): common
	if not mode.active() then return common end

	const tagged = if overrides == nil then {} :: tree else table.clone(overrides :: tree)
	tagged[EVERY_ENTRY] = common

	const result: unknown = tagged
	return result :: common
end

--// End
return table.freeze {
	create = create,
	resolve = resolve,
}
