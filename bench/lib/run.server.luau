--// Services
const ReplicatedStorage = game:GetService "ReplicatedStorage"

--// Modules
const harness = require(ReplicatedStorage.bench.harness)

--// Variables
local failures = 0

--// Functions
const function suites()
	const found = {}

	for _, module in ReplicatedStorage.bench.cases:GetChildren() do
		if not module:IsA "ModuleScript" or not string.match(module.Name, "%.bench$") then continue end
		table.insert(found, module)
	end

	table.sort(found, function(first, second)
		return first.Name < second.Name
	end)

	return found
end

--// End
for _, module in suites() do
	const area = string.gsub(module.Name, "%.bench$", "")
	const suite = require(module) :: harness.suite
	print(`SECTION\t{area}`)

	harness.run(suite, function(result)
		print(
			string.format(
				"BENCH\t%s/%s\t%d\t%.3f\t%.3f\t%.3f",
				area,
				string.gsub(result.name, "_", " "),
				result.size,
				result.median,
				result.fastest,
				result.slowest
			)
		)
	end, function(name, size, reason)
		failures += 1
		print(`FAILED\t{area}/{string.gsub(name, "_", " ")}\t{size}\t{reason}`)
	end)
end

if failures > 0 then error(`{failures} bench cases failed`) end
