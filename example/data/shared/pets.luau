--// Services
const ReplicatedStorage = game:GetService "ReplicatedStorage"

--// Modules
const backstage = require(ReplicatedStorage.backstage)

--// Types
type rarity = "common" | "rare" | "legendary"

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

	effect = backstage.union(
		"kind",
		{ kind = "glow" :: "glow", radius = 8, intensity = 2 },
		{ kind = "pulse" :: "pulse", speed = 3 }
	),

	skins = {
		[1] = { rarity = "common" :: rarity, scale = 1 },
		[8] = { rarity = "rare" :: rarity, scale = 1.2 },
		[10] = { rarity = "legendary" :: rarity, scale = 1.5 },
	},
}, {
	limits = {
		size = { min = 0.5, max = 8, step = 0.1 },
		mode = { "follow", "orbit" },

		stances = backstage.each {
			distance = { min = 0, max = 30, step = 0.1 },
			height = { min = 0, max = 15, step = 0.1 },

			speed = { min = 0.5, max = 40 },
			sway = { min = 0, max = 2, step = 0.05 },
		},

		skins = backstage.each {
			rarity = { "common", "rare", "legendary" },
			scale = { min = 0.5, max = 3, step = 0.1 },
		},

		trail = {
			length = { min = 0.1, max = 6, step = 0.1 },
		},

		effect = {
			radius = { min = 0, max = 30, step = 0.5 },
			intensity = { min = 0, max = 10, step = 0.1 },
			speed = { min = 0, max = 10, step = 0.1 },
		},
	},

	hints = {
		mode = "Follow trails the player, orbit circles around",
		respawn = "Puts the pet back next to the player",

		stances = backstage.each {
			distance = "How far from the player the pet stays",
			speed = "Higher snaps to the target, lower drifts",
			sway = "How much the pet bobs up and down, shared by every stance",
		},

		trail = { length = "Seconds the trail takes to fade" },

		effect = {
			kind = "Glow lights up around the pet, pulse makes it fade in and out",
			radius = "How far the glow reaches",

			intensity = "How bright the glow is",
			speed = "How fast the pet fades in and out",
		},
	},
})
