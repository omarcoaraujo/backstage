--// Services
const Players = game:GetService "Players"
const RunService = game:GetService "RunService"

--// Modules
const bridge = require "./bridge"
const mode = require "./mode"
const shortcut = require "./shortcut"
const sync = require "./sync"

--// Types
export type options = {
	key: Enum.KeyCode?,

	ctrl: boolean?,
	port: number?,

	theme: ("dark" | "light")?,
	places: { number }?,

	vide: unknown?,
	charm: unknown?,
}

--// Variables
local started = false

--// Functions
const function start(options: options?)
	if options and options.places then mode.allow(options.places) end
	if started or not mode.active() then return end
	started = true

	const install = require "../reactive/install"
	install(options)

	if RunService:IsServer() then
		sync.serve()
		if mode.studio() then bridge.serve(if options then options.port else nil, { keep = true }) end
		return
	end

	if not RunService:IsClient() then return end
	if not sync.connect() then return end

	const windows = require "../ui/windows"
	const appearance = require "../ui/stores/appearance"
	if options and options.theme then appearance.light(options.theme == "light") end

	const player_gui = Players.LocalPlayer:WaitForChild "PlayerGui"
	const handle = windows.create(player_gui)

	shortcut.listen(options, handle.toggle, handle.open_another)
end

--// End
return start
