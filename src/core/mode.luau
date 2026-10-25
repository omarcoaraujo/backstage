--// Services
const ReplicatedStorage = game:GetService "ReplicatedStorage"
const RunService = game:GetService "RunService"

--// Constants
const REMOTE_NAME = "backstage_sync"

--// Variables
local override = nil :: boolean?
local places = {} :: { number }
local decided = nil :: boolean?

--// Functions
const function server_decision()
	return RunService:IsStudio() or table.find(places, game.PlaceId) ~= nil
end

const function client_decision()
	if not game:IsLoaded() then game.Loaded:Wait() end
	return ReplicatedStorage:FindFirstChild(REMOTE_NAME) ~= nil
end

const function active()
	if override ~= nil then return override end
	if not RunService:IsRunning() then return RunService:IsStudio() end
	if RunService:IsServer() then return server_decision() end

	if decided == nil then decided = client_decision() end
	return decided :: boolean
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
	decided = nil
	table.clear(places)
end

--// End
return table.freeze {
	active = active,
	studio = studio,
	remote_name = REMOTE_NAME,

	enable = enable,
	disable = disable,

	allow = allow,
	restore = restore,
}
