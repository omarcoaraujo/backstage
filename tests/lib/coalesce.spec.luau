--// Services
const ReplicatedStorage = game:GetService "ReplicatedStorage"

--// Modules
const coalesce = require(ReplicatedStorage.backstage.core.coalesce)

--// Specs
return {
	runs_once_for_many_calls_in_the_same_frame = function()
		local runs = 0
		const schedule = coalesce(function()
			runs += 1
		end)

		for _ = 1, 50 do
			schedule()
		end

		assert(runs == 0)
		task.wait()
		assert(runs == 1)
	end,

	runs_again_for_a_call_after_it_ran = function()
		local runs = 0
		const schedule = coalesce(function()
			runs += 1
		end)

		schedule()
		task.wait()

		schedule()
		task.wait()
		assert(runs == 2)
	end,
}
