--// Services
const ReplicatedStorage = game:GetService "ReplicatedStorage"

--// Modules
const registry = require(ReplicatedStorage.backstage.core.registry)

--// Functions
const function created()
	if not workspace.CurrentCamera then workspace.CurrentCamera = Instance.new "Camera" end
	registry.reset()

	const windows = require(ReplicatedStorage.backstage.ui.windows)
	const host = Instance.new "Folder"
	host.Parent = workspace

	const handle = windows.create(host)
	const gui = host:FindFirstChildOfClass "ScreenGui" :: ScreenGui

	return handle, gui, host
end

--// End
return {
	opening_stops_at_four_windows = function()
		const handle, gui, host = created()

		for _ = 1, 6 do
			handle.open_another()
		end

		assert(handle.count() == 4)
		assert(#gui:GetChildren() == 4)
		host:Destroy()
	end,

	closing_removes_the_instance_and_frees_a_slot = function()
		const handle, gui, host = created()

		handle.open_another()
		handle.open_another()
		handle.open_another()

		handle.close_another(2)
		assert(handle.count() == 3)
		assert(#gui:GetChildren() == 3)

		handle.open_another()
		assert(handle.count() == 4)
		assert(#gui:GetChildren() == 4)

		host:Destroy()
	end,

	closing_every_extra_leaves_only_the_main_window = function()
		const handle, gui, host = created()
		const baseline = #gui:GetDescendants()

		handle.open_another()
		handle.open_another()

		handle.close_another(1)
		handle.close_another(1)

		assert(handle.count() == 1)
		assert(#gui:GetChildren() == 1)
		assert(#gui:GetDescendants() == baseline)

		handle.open_another()
		assert(handle.count() == 2)
		host:Destroy()
	end,

	closing_an_extra_that_is_not_open_changes_nothing = function()
		const handle, gui, host = created()
		handle.close_another(1)

		assert(handle.count() == 1 and #gui:GetChildren() == 1)
		host:Destroy()
	end,
}
