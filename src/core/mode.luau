--// Services
const RunService = game:GetService "RunService"

--// Variables
local override = nil :: boolean?

--// Functions
const function active()
	if override ~= nil then return override end
	return RunService:IsStudio()
end

const function enable()
	override = true
end

const function disable()
	override = false
end

const function restore()
	override = nil
end

--// End
return table.freeze {
	active = active,
	enable = enable,

	disable = disable,
	restore = restore,
}
