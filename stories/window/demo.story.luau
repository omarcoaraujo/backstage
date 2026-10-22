--// Services
const ReplicatedStorage = game:GetService "ReplicatedStorage"

--// Modules
const backstage = require(ReplicatedStorage.backstage)
const config = require(ReplicatedStorage.stories.window.config)

--// Constants
const BUTTONS = { "respawn", "reset", "heal", "clear", "save" }

--// Story
return function(target: Instance)
	const connections = {}

	for _, name in BUTTONS do
		const function on_press()
			print(name)
		end

		table.insert(connections, config.pets[name]:connect(on_press))
	end

	const stop_panel = backstage.embed(target)

	return function()
		stop_panel()

		for _, connection in connections do
			connection.disconnect()
		end
	end
end
