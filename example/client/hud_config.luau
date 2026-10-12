--// Services
const ReplicatedStorage = game:GetService "ReplicatedStorage"

--// Modules
const backstage = require(ReplicatedStorage.backstage)

--// End
return backstage.config("hud", {
	enabled = true,
	show_stats = true,

	title = "Pet",
	accent = Color3.fromRGB(255, 200, 80),

	corner = "bottom_left",
	scale = 1,
	fade = 0.15,
}, {
	limits = {
		corner = { choices = { "top_left", "top_right", "bottom_left", "bottom_right" } },
		scale = { min = 0.5, max = 2, step = 0.05 },
		fade = { min = 0, max = 1, step = 0.05 },
	},
})
