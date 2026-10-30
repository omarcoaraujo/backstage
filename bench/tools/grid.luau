--// Modules
const parse = require "./parse"
const tint = require "../../cli/luau_packages/tint"

--// Types
export type line = { label: string, cells: { [number]: parse.row } }
export type area = { name: string, lines: { line } }

--// Constants
const GAP = "  "
const MISSING = "-"

--// Functions
const function area_of(name: string)
	return string.match(name, "^([^/]+)/") or name
end

const function label_of(name: string)
	return string.sub(name, #area_of(name) + 2)
end

const function areas_of(report: parse.report)
	const areas = {} :: { area }
	local current = nil :: area?
	local line = nil :: line?

	for _, row in report.rows do
		const name = area_of(row.name)
		const label = label_of(row.name)

		if not current or current.name ~= name then
			current = { name = name, lines = {} }
			line = nil
			table.insert(areas, current)
		end

		if not line or line.label ~= label then
			line = { label = label, cells = {} }
			table.insert(assert(current).lines, line)
		end

		assert(line).cells[row.size] = row
	end

	return areas
end

const function sizes_of(report: parse.report)
	const seen = {} :: { [number]: boolean }
	const sizes = {}

	for _, row in report.rows do
		if seen[row.size] then continue end
		seen[row.size] = true
		table.insert(sizes, row.size)
	end

	table.sort(sizes)
	return sizes
end

const function widest(areas: { area })
	local width = 0

	for _, area in areas do
		for _, line in area.lines do
			width = math.max(width, #line.label)
		end
	end

	return width
end

const function render(report: parse.report, width: number, cell_of: (row: parse.row) -> string)
	const areas = areas_of(report)
	const sizes = sizes_of(report)

	const label_width = widest(areas)
	const wall = tint.gray "│"
	const missing = tint.dim(string.format(`%{width}s`, MISSING))

	for _, area in areas do
		print ""
		const heads = {}

		for _, size in sizes do
			table.insert(heads, tint.dim(string.format(`%{width}d`, size)))
		end

		print(`{tint.cyan.bold(string.format(`%-{label_width}s`, area.name))} {wall} {table.concat(heads, GAP)}`)

		for _, line in area.lines do
			const cells = {}

			for _, size in sizes do
				const row = line.cells[size]
				table.insert(cells, if row then cell_of(row) else missing)
			end

			print(`{tint.bold(string.format(`%-{label_width}s`, line.label))} {wall} {table.concat(cells, GAP)}`)
		end
	end
end

--// End
return table.freeze {
	render = render,
}
