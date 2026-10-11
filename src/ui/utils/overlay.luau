--// Packages
const vide = require "../../../roblox_packages/vide"

--// Variables
const depth = vide.source(0)

--// Functions
const function active(): boolean
	return depth() > 0
end

const function enter()
	depth(depth() + 1)
end

const function leave()
	depth(math.max(depth() - 1, 0))
end

--// End
return table.freeze {
	active = active,
	enter = enter,
	leave = leave,
}
