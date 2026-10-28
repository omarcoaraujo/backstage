--// Modules
const locate = require "./locate"
const write = require "./write"

--// Types
export type edit = write.input & { path: string }
type placed = { edit: edit, range: locate.range }
export type refusal = { path: string, reason: string, kind: string? }

--// Functions
const function starts_later(left: placed, right: placed)
	if left.range.begin_line ~= right.range.begin_line then return left.range.begin_line > right.range.begin_line end
	return left.range.begin_column > right.range.begin_column
end

const function select_variant(source: string, edit: edit, refusals: { refusal }): string
	const variants = locate.union_of(source, edit.path)
	if not variants then return source end

	local target = nil
	for index, variant in variants do
		if variant.name == edit.value then target = index end
	end

	if not target then
		table.insert(refusals, { path = edit.path, reason = `"{edit.value}" is not a variant written in the script` })
		return source
	end

	if target == 1 then return source end
	const first = variants[1].range

	const chosen = variants[target].range
	const first_text = write.slice(source, first)

	const chosen_text = write.slice(source, chosen)
	return write.replace(write.replace(source, chosen, first_text), first, chosen_text)
end

const function apply(source: string, edits: { edit }): (string, { refusal })
	const placements = {} :: { placed }
	const placed_at = {} :: { [string]: placed }

	const refusals = {} :: { refusal }
	const selections = {} :: { edit }

	for _, edit in edits do
		if edit.kind == "string" and locate.union_of(source, edit.path) then
			table.insert(selections, edit)
			continue
		end

		const found, reason = locate.locate(source, edit.path)
		if not found then
			table.insert(refusals, { path = edit.path, reason = reason or "not found" })
			continue
		end

		placed_at[`{found.range.begin_line}:{found.range.begin_column}`] = { edit = edit, range = found.range }
	end

	for _, placement in placed_at do
		table.insert(placements, placement)
	end

	table.sort(placements, starts_later)
	local result = source

	for _, placement in placements do
		result = write.replace(result, placement.range, write.literal(placement.edit))
	end

	for _, selection in selections do
		result = select_variant(result, selection, refusals)
	end

	return result, refusals
end

--// End
return { apply = apply }
