--// Modules
const locate = require "./locate"
const write = require "./write"

--// Types
export type edit = write.input & { path: string }
type placed = { edit: edit, range: locate.range }
export type refusal = { path: string, reason: string }

--// Functions
const function starts_later(left: placed, right: placed)
	if left.range.begin_line ~= right.range.begin_line then return left.range.begin_line > right.range.begin_line end
	return left.range.begin_column > right.range.begin_column
end

const function apply(source: string, edits: { edit }): (string, { refusal })
	const placements = {} :: { placed }
	const placed_at = {} :: { [string]: placed }
	const refusals = {} :: { refusal }

	for _, edit in edits do
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

	return result, refusals
end

--// End
return { apply = apply }
