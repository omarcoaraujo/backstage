--// Packages
const vide = require "../../../roblox_packages/vide"

--// Constants
const theme = require "../constants/theme"

--// Variables
const light = vide.source(false)

--// Functions
const function current()
	return if light() then theme.palettes.light else theme.palettes.dark
end

const function toggle()
	light(not light())
end

--// End
return table.freeze {
	light = light,
	toggle = toggle,

	background = function()
		return current().background
	end,

	field = function()
		return current().field
	end,

	hover = function()
		return current().hover
	end,

	divider = function()
		return current().divider
	end,

	accent = function()
		return current().accent
	end,

	danger = function()
		return current().danger
	end,

	danger_text = function()
		return current().danger_text
	end,

	danger_muted = function()
		return current().danger_muted
	end,

	success_text = function()
		return current().success_text
	end,

	stroke = function()
		return current().stroke
	end,

	text = function()
		return current().text
	end,

	text_muted = function()
		return current().text_muted
	end,
}
