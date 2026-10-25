--// Services
const Players = game:GetService "Players"

--// Packages
const vide = require "../../../roblox_packages/vide"

--// Modules
const presence = require "../../core/presence"

--// Variables
const revision = vide.source(0)

--// Functions
const function blocked(owner: string): boolean
	revision()
	const own = Players.LocalPlayer

	for _, entry in presence.list() do
		if own and entry.user == own.UserId then continue end
		if entry.hold and entry.hold.owner == owner then return true end
	end

	return false
end

const function of_path(path: string)
	return function()
		return blocked(path)
	end
end

const function check(source: (() -> boolean)?): boolean
	return source ~= nil and source()
end

const function refresh()
	revision(revision() + 1)
end

--// End
presence.on_change(refresh)
return table.freeze {
	blocked = blocked,
	of_path = of_path,
	check = check,
}
