--// Modules
const fs = require "@std/fs"
const grid = require "./grid"
const parse = require "./parse"
const process = require "@std/process"
const tint = require "../../cli/luau_packages/tint"

--// Constants
const CELL_WIDTH = 25
const REGRESSION_RATIO = 1.25

const WARNING_RATIO = 1.1
const IMPROVEMENT_RATIO = 0.8
const MINIMUM_DIFFERENCE = 0.5

--// Functions
const function read(file: string)
	if not fs.exists(file) then
		print(tint.red.bold "error:", `{file} does not exist`)
		process.exit(1)
	end

	return parse(fs.readFileToString(file))
end

--// End
const before = read(process.args[2] or "bench/baseline.txt")
const after = read(process.args[3] or "bench/results/latest.txt")

const baseline = {}
local regressions = 0

for _, row in before.rows do
	baseline[row.key] = row
end

const function cell(row: parse.row)
	const old = baseline[row.key]
	if not old then return tint.yellow(string.format(`%{CELL_WIDTH}s`, `new {string.format("%.3f", row.median)}`)) end

	const ratio = if old.median == 0 then 1 else row.median / old.median
	const difference = row.median - old.median

	const was = string.format("%8.3f", old.median)
	const now = string.format("%8.3f", row.median)
	const times = string.format("%5.2fx", ratio)

	if ratio > REGRESSION_RATIO and difference >= MINIMUM_DIFFERENCE then
		regressions += 1
		return `{tint.dim(was)} {tint.red.bold(now)} {tint.red.bold(times)}`
	end

	if ratio > WARNING_RATIO and difference >= MINIMUM_DIFFERENCE then
		return `{tint.dim(was)} {tint.yellow(now)} {tint.yellow(times)}`
	end

	if ratio < IMPROVEMENT_RATIO and -difference >= MINIMUM_DIFFERENCE then
		return `{tint.dim(was)} {tint.green(now)} {tint.green(times)}`
	end

	return tint.dim(`{was} {now} {times}`)
end

grid.render(after, CELL_WIDTH, cell)
print ""
print(tint.dim "before, after and the ratio. red is a regression, yellow slower, green faster")

if regressions > 0 then
	print(tint.red.bold(`{regressions} cases got slower`))
	process.exit(1)
end
