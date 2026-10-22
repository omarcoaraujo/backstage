--// Services
const ReplicatedStorage = game:GetService "ReplicatedStorage"

--// Modules
const backstage = require(ReplicatedStorage.backstage)

--// End
return backstage.config("demo", {
	pets = {
		distance = 6,
		height = 3,
		speed = 8,

		mode = "follow",
		nickname = "Bacon",

		offset = Vector3.new(0, 2, -1.5),
		tint = Color3.fromRGB(255, 200, 80),

		respawn = backstage.button(),
		reset = backstage.button(),
		heal = backstage.button(),
		clear = backstage.button(),
		save = backstage.button(),

		trail = {
			enabled = true,
			length = 1.5,

			fade = {
				curve = { smoothing = 0.5 },
			},
		},
	},

	stores = {
		inventory = {
			slots = 3,
			open = false,
		},
	},
}, {
	limits = {
		pets = {
			distance = { min = 0, max = 30, step = 0.1 },
			height = { min = 0, max = 15, step = 0.1 },
			speed = { min = 0.5, max = 40 },

			mode = { "follow", "orbit", "cloud" },
			trail = {
				length = { min = 0.1, max = 6, step = 0.1 },
				fade = {
					curve = { smoothing = { min = 0, max = 1, step = 0.05 } },
				},
			},
		},
	},

	hints = {
		pets = {
			distance = "How far behind the player the pet stays.",
			speed = "Studs per second the pet catches up at.",
			respawn = "Puts the pet back next to the player.",

			trail = {
				fade = {
					curve = { smoothing = "How softly the trail fades out near its end." },
				},
			},
		},
	},
})
