--// Services
const ReplicatedStorage = game:GetService "ReplicatedStorage"

--// Modules
const backstage = require(ReplicatedStorage.backstage)

--// End
return backstage.config("pets", {
	distance = 6,
	height = 3,

	speed = 8,
	size = 2,

	tint = Color3.fromRGB(255, 200, 80),
	mode = "follow",

	respawn = backstage.button(),
	trail = { enabled = true, length = 1.5 },
}, {
	limits = {
		distance = { min = 0, max = 30, step = 0.1 },
		height = { min = 0, max = 15, step = 0.1 },

		speed = { min = 0.5, max = 40 },
		size = { min = 0.5, max = 8, step = 0.1 },

		mode = { choices = { "follow", "orbit" } },
		trail = {
			length = { min = 0.1, max = 6, step = 0.1 },
		},
	},

	hints = {
		_ = "Settings of the pet that follows the player",

		distance = "How far behind the player the pet stays",
		speed = "Higher snaps to the target, lower drifts",

		mode = "Follow trails the player, orbit circles around",
		respawn = "Puts the pet back next to the player",
		trail = { _ = "The line the pet leaves behind", length = "Seconds the trail takes to fade" },
	},
})
