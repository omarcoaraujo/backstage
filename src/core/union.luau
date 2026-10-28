--// Modules
const mode = require "./mode"

--// Constants
const MARK = table.freeze {}

--// Types
type tree = { [any]: unknown }
export type marker = { discriminant: string, variants: { tree } }

export type create =
	(<A, B>(discriminant: string, first: A, second: B) -> A | B)
	& (<A, B, C>(discriminant: string, first: A, second: B, third: C) -> A | B | C)
	& (<A, B, C, D>(discriminant: string, first: A, second: B, third: C, fourth: D) -> A | B | C | D)
	& (<A, B, C, D, E>(discriminant: string, first: A, second: B, third: C, fourth: D, fifth: E) -> A | B | C | D | E)
	& (<A, B, C, D, E, F>(
		discriminant: string,
		first: A,
		second: B,
		third: C,
		fourth: D,
		fifth: E,
		sixth: F
	) -> A | B | C | D | E | F)

--// Functions
const function is_union(value: unknown): boolean
	return type(value) == "table" and rawget(value :: tree, MARK) == true
end

const function names(source: marker): { string }
	const result = {}

	for _, variant in source.variants do
		table.insert(result, variant[source.discriminant] :: string)
	end

	return result
end

const function find(source: marker, name: string): tree?
	for _, variant in source.variants do
		if variant[source.discriminant] == name then return variant end
	end

	return nil
end

const function validate(discriminant: unknown, variants: { unknown })
	if type(discriminant) ~= "string" then error("union expects the name of the discriminant field first", 3) end
	if #variants < 2 then error("union needs at least two variants", 3) end

	const seen = {} :: { [string]: boolean }
	for _, variant in variants do
		if type(variant) ~= "table" then error("every union variant must be a table", 3) end
		const name = (variant :: tree)[discriminant]

		if type(name) ~= "string" then error(`every union variant needs a string "{discriminant}" field`, 3) end
		if seen[name] then error(`union has two variants named "{name}"`, 3) end

		seen[name] = true
	end
end

const function create_union(discriminant: string, ...: any): any
	const variants = { ... }
	if not mode.active() then return variants[1] end
	validate(discriminant, variants)

	const marker = { [MARK] = true, discriminant = discriminant, variants = variants }
	return marker
end

--// End
const create: create = create_union :: any
return table.freeze {
	create = create,
	is_union = is_union,

	names = names,
	find = find,
}
