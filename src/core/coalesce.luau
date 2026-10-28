--// Functions
const function coalesce(callback: () -> ()): () -> ()
	local scheduled = false

	return function()
		if scheduled then return end
		scheduled = true

		task.defer(function()
			scheduled = false
			callback()
		end)
	end
end

--// End
return coalesce
