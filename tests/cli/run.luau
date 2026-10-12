--// Modules
const process = require "@std/process"

--// Specs
const suites = {
	apply = require "./apply.spec",
	locate = require "./locate.spec",
	scan = require "./scan.spec",
	write = require "./write.spec",
}

--// Functions
const function sorted_names(suite: { [string]: () -> () })
	const names = {}

	for name in suite do
		table.insert(names, name)
	end

	table.sort(names)
	return names
end

--// End
local total, failed = 0, 0

for suite_name, suite in suites do
	for _, name in sorted_names(suite) do
		total += 1
		const ok, err = pcall(suite[name])
		if ok then continue end

		failed += 1
		print(`  x {suite_name}/{name} {err}`)
	end
end

if failed > 0 then
	print(`{failed}/{total} cli specs failed`)
	process.exit(1)
end

print(`ok {total}/{total} cli specs passed`)
