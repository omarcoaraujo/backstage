--// Services
const ReplicatedStorage = game:GetService "ReplicatedStorage"

--// Packages
const vide = require(ReplicatedStorage.roblox_packages.vide)

--// Utils
const px = require(ReplicatedStorage.backstage.ui.utils.px)

--// Modules
const version = require(ReplicatedStorage.backstage.version)

--// Components
const buttons = require(ReplicatedStorage.backstage.ui.components.buttons)
const choice = require(ReplicatedStorage.backstage.ui.components.controls.choice)
const color = require(ReplicatedStorage.backstage.ui.components.controls.color)
const group = require(ReplicatedStorage.backstage.ui.components.group)
const list = require(ReplicatedStorage.backstage.ui.components.list)
const number = require(ReplicatedStorage.backstage.ui.components.controls.number)
const row = require(ReplicatedStorage.backstage.ui.components.row)
const text = require(ReplicatedStorage.backstage.ui.components.controls.text)
const toggle = require(ReplicatedStorage.backstage.ui.components.controls.toggle)
const vector3 = require(ReplicatedStorage.backstage.ui.components.controls.vector3)
const window = require(ReplicatedStorage.backstage.ui.components.window)

--// Functions
const function action(text: string): buttons.item
	const function on_press()
		print(text)
	end

	return { text = text, on_press = on_press }
end

const function number_row(label: string, value: vide.Source<number>, min: number?, max: number?, step: number?)
	const function on_change(next_value: number)
		value(math.clamp(next_value, min or -math.huge, max or math.huge))
	end

	return row {
		label = label,
		content = number {
			value = value,
			on_change = on_change,
			min = min,
			max = max,
			step = step,
		},
	}
end

const function toggle_row(label: string, value: vide.Source<boolean>)
	const function on_change(next_value: boolean)
		value(next_value)
	end

	return row {
		label = label,
		content = toggle { value = value, on_change = on_change },
	}
end

const function choice_row(label: string, value: vide.Source<string>, choices: { string })
	const function on_change(next_value: string)
		value(next_value)
	end

	return row {
		label = label,
		content = choice { value = value, on_change = on_change, choices = choices },
	}
end

const function color_row(label: string, value: vide.Source<Color3>)
	const function on_change(next_value: Color3)
		value(next_value)
	end

	return row {
		label = label,
		content = color { value = value, on_change = on_change },
	}
end

const function vector3_row(label: string, value: vide.Source<Vector3>)
	const function on_change(next_value: Vector3)
		value(next_value)
	end

	return row {
		label = label,
		content = vector3 { value = value, on_change = on_change },
	}
end

const function text_row(label: string, value: vide.Source<string>)
	const function on_change(next_value: string)
		value(next_value)
	end

	return row {
		label = label,
		content = text { value = value, on_change = on_change },
	}
end

--// Story
return function(target: Instance)
	return vide.mount(function()
		px.use_px()
		const visible = vide.source(true)

		const distance = vide.source(6)
		const height = vide.source(3)
		const speed = vide.source(8)
		const length = vide.source(1.5)
		const slots = vide.source(3)
		const nickname = vide.source "Bacon"
		const mode = vide.source "follow"
		const offset = vide.source(Vector3.new(0, 2, -1.5))
		const tint = vide.source(Color3.fromRGB(255, 200, 80))
		const trail_enabled = vide.source(true)
		const inventory_open = vide.source(false)

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
							number_row("distance", distance, 0, 30, 0.1),
							number_row("height", height, 0, 15, 0.1),
							number_row("speed", speed, 0.5, 40),
							choice_row("mode", mode, { "follow", "orbit", "cloud" }),
							text_row("nickname", nickname),
							vector3_row("offset", offset),
							color_row("tint", tint),
							buttons {
								items = {
									action "respawn",
									action "reset",
									action "heal",
									action "clear",
									action "save",
								},
							},

							group {
								name = "trail",
								content = {
									toggle_row("enabled", trail_enabled),
									number_row("length", length, 0.1, 6, 0.1),
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
									number_row("slots", slots),
									toggle_row("open", inventory_open),
								},
							},
						},
					},
				},
			},
		}
	end, target)
end
