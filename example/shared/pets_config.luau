--// Services
const ReplicatedStorage = game:GetService "ReplicatedStorage"

--// Modules
const backstage = require(ReplicatedStorage.backstage)

--// Constants
const STANCE_LIMITS = {
	distance = { min = 0, max = 30, step = 0.1 },
	height = { min = 0, max = 15, step = 0.1 },

	speed = { min = 0.5, max = 40 },
	sway = { min = 0, max = 2, step = 0.05 },
}

const STANCE_HINTS = {
	distance = "How far from the player the pet stays",
	speed = "Higher snaps to the target, lower drifts",
	sway = "How much the pet bobs up and down, shared by every stance",
}

--// Functions
const function stance(distance: number, height: number, speed: number)
	return { distance = distance, height = height, speed = speed, sway = 0.4 }
end

--// End
return backstage.config("pets", {
	size = 2,
	tint = Color3.fromRGB(255, 200, 80),

	mode = "follow",
	respawn = backstage.button(),

	stances = {
		follow = stance(6, 3, 8),
		orbit = stance(10, 4, 5),
	},

	trail = { enabled = true, length = 1.5 },
}, {
	limits = {
		size = { min = 0.5, max = 8, step = 0.1 },
		mode = { "follow", "orbit" },
		stances = { follow = STANCE_LIMITS, orbit = STANCE_LIMITS },

		trail = {
			length = { min = 0.1, max = 6, step = 0.1 },
		},
	},

	hints = {
		mode = "Follow trails the player, orbit circles around",
		respawn = "Puts the pet back next to the player",

		stances = { follow = STANCE_HINTS, orbit = STANCE_HINTS },
		trail = { length = "Seconds the trail takes to fade" },
	},
})
