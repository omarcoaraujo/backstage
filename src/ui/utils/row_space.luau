--// Utils
const flatten = require "./flatten"
const viewport = require "./viewport"

--// Types
export type hit = {
	group: string,
	row: string?,
	top: number,
}

export type space = {
	hit: (y: number) -> hit?,
	top_of_row: (path: string) -> number?,
	nearest_group_top: (path: string) -> number?,
}

--// Functions
const function parent_of(path: string): string?
	return string.match(path, "^(.*)%.[^%.]+$")
end

const function new(rows: { flatten.row }, layout: viewport.layout): space
	const groups = {} :: { [string]: number }
	const entries = {} :: { [string]: number }

	for index, row in rows do
		if row.kind == "group" then groups[row.path] = index end
		if row.kind == "entry" then entries[row.path] = index end
	end

	const function last_entry_before(index: number, owner: string): number?
		const header = groups[owner] or 1

		for current = index - 1, header, -1 do
			const candidate = rows[current]
			if candidate.kind == "entry" and candidate.owner == owner then return current end
		end

		return nil
	end

	const function hit(y: number): hit?
		const index = viewport.index_at(layout, y)
		const row = rows[index]
		if not row then return nil end

		if row.kind == "group" then return { group = row.path, row = nil, top = layout.tops[index] } end
		if row.kind == "entry" then return { group = row.owner, row = row.path, top = layout.tops[index] } end

		const previous = last_entry_before(index, row.owner)
		if previous then return { group = row.owner, row = rows[previous].path, top = layout.tops[previous] } end
		return { group = row.owner, row = nil, top = layout.tops[groups[row.owner] or index] }
	end

	const function top_of_row(path: string): number?
		const index = entries[path]
		return if index then layout.tops[index] else nil
	end

	const function nearest_group_top(path: string): number?
		local current = path :: string?

		while current do
			const index = groups[current]
			if index then return layout.tops[index] end
			current = parent_of(current)
		end

		return nil
	end

	return {
		hit = hit,
		top_of_row = top_of_row,
		nearest_group_top = nearest_group_top,
	}
end

--// End
return table.freeze {
	new = new,
}
