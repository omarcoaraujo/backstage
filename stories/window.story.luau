--// Services
const ReplicatedStorage = game:GetService "ReplicatedStorage"

--// Packages
const vide = require(ReplicatedStorage.roblox_packages.vide)

--// Utils
const px = require(ReplicatedStorage.backstage.ui.utils.px)
const theme = require(ReplicatedStorage.backstage.ui.utils.theme)

--// Modules
const version = require(ReplicatedStorage.backstage.version)

--// Components
const group = require(ReplicatedStorage.backstage.ui.components.group)
const list = require(ReplicatedStorage.backstage.ui.components.list)
const row = require(ReplicatedStorage.backstage.ui.components.row)
const window = require(ReplicatedStorage.backstage.ui.components.window)

--// Functions
const function value_text(text: string)
	return vide.create "TextLabel" {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,

		FontFace = theme.font,
		Text = text,

		TextColor3 = theme.text,
		TextSize = px(theme.text_size),
		TextXAlignment = Enum.TextXAlignment.Right,
	}
end

const function value_row(label: string, text: string)
	return row {
		label = label,
		content = value_text(text),
	}
end

--// Story
return function(target: Instance)
	return vide.mount(function()
		px.use_px()
		const visible = vide.source(true)

		const function close()
			visible(false)
		end

		return window {
			title = "backstage",
			footer = `v{version}`,

			visible = visible,
			on_close = close,

			content = list {
				content = {
					group {
						name = "pets",
						content = {
							value_row("distance", "6"),
							value_row("height", "3"),
							value_row("speed", "8"),
							value_row("mode", "follow"),
							group {
								name = "trail",
								content = {
									value_row("enabled", "true"),
									value_row("length", "1.5"),
								},
							},
						},
					},
					group {
						name = "stores",
						content = {
							group {
								name = "inventory",
								content = {
									value_row("slots", "3"),
									value_row("open", "false"),
								},
							},
						},
					},
				},
			},
		}
	end, target)
end
