--// Services
const ReplicatedStorage = game:GetService "ReplicatedStorage"

--// Functions
const function run(folder: Instance): (number, number)
	local total, failed = 0, 0

	for _, module in folder:GetChildren() do
		if not module:IsA "ModuleScript" or not string.match(module.Name, "%.spec$") then continue end

		const names = {} :: { string }
		const suite = require(module) :: { [string]: () -> () }

		for name in suite do
			table.insert(names, name)
		end

		table.sort(names)

		for _, name in names do
			total += 1
			const ok, err = pcall(suite[name])
			if ok then continue end

			failed += 1
			print(`  x {module.Name}/{name} {err}`)
		end
	end

	return total, failed
end

--// End
const total, failed = run(ReplicatedStorage.tests)

if failed > 0 then error(`{failed}/{total} specs failed`) end
print(`ok {total}/{total} specs passed`)
