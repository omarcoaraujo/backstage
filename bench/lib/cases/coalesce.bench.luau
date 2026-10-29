--// Services
const ReplicatedStorage = game:GetService "ReplicatedStorage"

--// Modules
const coalesce = require(ReplicatedStorage.backstage.core.coalesce)

--// Utils
const harness = require(ReplicatedStorage.bench.harness)

--// End
return {
	calls_in_one_frame = harness.deferred(function(size)
		const schedule = coalesce(function() end)
		return function()
			for _ = 1, size do
				schedule()
			end
		end
	end),
} :: harness.suite
