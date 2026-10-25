--// Services
const RunService = game:GetService "RunService"

--// Variables
local override = nil :: boolean?
local places = {} :: { number }

--// Functions
const function allowed()
	return table.find(places, game.PlaceId) ~= nil
end

const function active()
	if override ~= nil then return override end
	return RunService:IsStudio() or allowed()
end

const function studio()
	return RunService:IsStudio()
end

const function enable()
	override = true
end

const function disable()
	override = false
end

const function allow(ids: { number })
	places = table.clone(ids)
end

const function restore()
	override = nil
	table.clear(places)
end

--// End
return table.freeze {
	active = active,
	studio = studio,

	enable = enable,
	disable = disable,

	allow = allow,
	restore = restore,
}
