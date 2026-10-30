--// Services
const ReplicatedStorage = game:GetService "ReplicatedStorage"

--// Packages
const vide = require(ReplicatedStorage.roblox_packages.vide)

--// Utils
const filter = require(ReplicatedStorage.backstage.ui.utils.filter)
const px = require(ReplicatedStorage.backstage.ui.utils.px)

--// Modules
const version = require(ReplicatedStorage.backstage.version)

--// Components
const list = require(ReplicatedStorage.backstage.ui.components.list)
const readout = require(ReplicatedStorage.backstage.ui.components.controls.readout)
const row = require(ReplicatedStorage.backstage.ui.components.row)
const tree = require(ReplicatedStorage.backstage.ui.components.tree)
const window = require(ReplicatedStorage.backstage.ui.components.window)

--// Constants
const SLOTS = 3

const PROFILE = {
	level = 12,
	name = "Bacon",

	position = Vector3.new(4, 0.5, -12),
	tint = Color3.fromRGB(255, 200, 80),

	inventory = {
		sword = { damage = 10, durability = 80.5 },
		potions = 3,
		equipped = true,
	},

	spawn = workspace,
}

--// Functions
const function profile_value()
	return PROFILE
end

const function slots_left()
	return SLOTS - PROFILE.inventory.potions
end

--// Story
return function(target: Instance)
	return vide.mount(function()
		px.use_px()

		const visible = vide.source(true)
		const search = filter.create()

		const function close()
			visible(false)
		end

		return window {
			title = "backstage",
			footer = `v{version}`,

			query = search.query,
			visible = visible,
			on_close = close,

			content = list {
				content = {
					row { label = "slots left", content = readout { value = slots_left } },
					tree { name = "profile", search = search, value = profile_value, open = false },
				},
			},
		}
	end, target)
end
