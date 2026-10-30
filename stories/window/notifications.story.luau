--// Services
const ReplicatedStorage = game:GetService "ReplicatedStorage"

--// Packages
const vide = require(ReplicatedStorage.roblox_packages.vide)

--// Modules
const notice = require(ReplicatedStorage.backstage.core.notice)
const version = require(ReplicatedStorage.backstage.version)

--// Utils
const filter = require(ReplicatedStorage.backstage.ui.utils.filter)
const px = require(ReplicatedStorage.backstage.ui.utils.px)

--// Components
const buttons = require(ReplicatedStorage.backstage.ui.components.buttons)
const list = require(ReplicatedStorage.backstage.ui.components.list)
const notifications = require(ReplicatedStorage.backstage.ui.components.notifications)
const window = require(ReplicatedStorage.backstage.ui.components.window)

--// Constants
const TITLE = "Not saved to the script"

--// Functions
const function not_a_literal()
	notice.show(TITLE, "error", '"pets.stances.follow.speed" is not a literal')
end

const function without_room()
	notice.show(
		"Entry not added to the script",
		"error",
		`"shop" closes on the same line as its last entry, so the script cannot grow it`
	)
end

const function only_a_title()
	notice.show("Saved", "info")
end

const function with_a_detail()
	notice.show("Bridge connected", "success", "Edits are written to the script again")
end

const function flood()
	for index = 1, 6 do
		notice.show(`Notice {index}`, if index % 2 == 0 then "error" else "info", "Sent together")
	end
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

		return vide.create "Frame" {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,

			window {
				title = "backstage",
				query = search.query,
				footer = `v{version}`,

				visible = visible,
				on_close = close,

				content = list {
					content = {
						buttons {
							items = {
								{ text = "not a literal", on_press = not_a_literal },
								{ text = "no room", on_press = without_room },
								{ text = "only a title", on_press = only_a_title },
								{ text = "with a detail", on_press = with_a_detail },
								{ text = "flood", on_press = flood },
							},
						},
					},
				},
			},

			notifications(),
		}
	end, target)
end
