--// Modules
const fs = require "@std/fs"
const grid = require "./grid"
const parse = require "./parse"
const process = require "@std/process"
const tint = require "../../cli/luau_packages/tint"

--// Constants
const CELL_WIDTH = 24
const FAST = 1
const FRAME = 16

--// Functions
const function paint(median: number, text: string)
	if median < FAST then return tint.green(text) end
	if median < FRAME then return tint.yellow(text) end
	return tint.red(text)
end

const function cell(row: parse.row)
	const median = string.format("%8.3f", row.median)
	const range = string.format("%7.2f %7.2f", row.fastest, row.slowest)
	return `{paint(row.median, median)} {tint.dim(range)}`
end

--// End
const file = process.args[2]
if not file or not fs.exists(file) then
	print(tint.red.bold "error:", "pass the result file, like bench/results/latest.txt")
	process.exit(1)
end

const report = parse(fs.readFileToString(file))
grid.render(report, CELL_WIDTH, cell)

print ""
print(tint.dim "median in ms, then fastest and slowest. green under 1 ms, yellow under a frame (16 ms)")

for _, failure in report.failures do
	print(`{tint.red.bold "failed:"} {failure}`)
end

if #report.failures > 0 then process.exit(1) end
