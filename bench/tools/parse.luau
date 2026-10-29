--// Types
export type row = {
	key: string,
	name: string,
	size: number,

	median: number,
	fastest: number,
	slowest: number,
}

export type report = {
	sections: { string },
	rows: { row },
	failures: { string },
}

--// Functions
const function parse(text: string): report
	const report = { sections = {}, rows = {}, failures = {} } :: report

	for line in string.gmatch(text, "[^\r\n]+") do
		const fields = string.split(line, "\t")
		const kind = fields[1]

		if kind == "SECTION" then
			table.insert(report.sections, fields[2])
			continue
		end

		if kind == "FAILED" then
			table.insert(report.failures, `{fields[2]} at {fields[3]}: {fields[4]}`)
			continue
		end

		if kind ~= "BENCH" then continue end
		const size = tonumber(fields[3])

		const median, fastest, slowest = tonumber(fields[4]), tonumber(fields[5]), tonumber(fields[6])
		if not size or not median or not fastest or not slowest then continue end

		table.insert(report.rows, {
			key = `{fields[2]}@{size}`,
			name = fields[2],
			size = size,

			median = median,
			fastest = fastest,
			slowest = slowest,
		})
	end

	return report
end

--// End
return parse
