--// Modules
const registry = require "../../core/registry"

--// Utils
const flatten = require "./flatten"

--// Functions
const function signature(entry: registry.entry): string
	const descriptor = entry.descriptor
	const choices = if descriptor.choices then table.concat(descriptor.choices, "\0") else ""
	return `{descriptor.kind}|{descriptor.min or ""}|{descriptor.max or ""}|{descriptor.step or ""}|{choices}`
end

const function of_row(current: flatten.row): string?
	if current.kind == "entry" then
		const entry = assert(current.entry)
		return `entry:{current.depth}:{registry.is_catalog(entry.group)}:{signature(entry)}`
	end

	if current.kind == "group" then return `group:{current.depth}:{registry.is_catalog(current.path)}` end
	return nil
end

--// End
return table.freeze {
	of_row = of_row,
}
