--// Services
const Players = game:GetService "Players"
const RunService = game:GetService "RunService"

--// Modules
const bridge = require "./bridge"
const mode = require "./mode"
const shortcut = require "./shortcut"
const sync = require "./sync"

--// Constants
const DISPLAY_ORDER = 1000

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

	const vide = require "../../roblox_packages/vide"
	const app = require "../ui/app"

	const appearance = require "../ui/stores/appearance"
	const version = require "../version"
	if options and options.theme then appearance.light(options.theme == "light") end

	const player_gui = Players.LocalPlayer:WaitForChild "PlayerGui"
	const visible = vide.source(false)

	const function close()
		visible(false)
	end

	const function toggle()
		visible(not visible())
	end

	vide.mount(function()
		return vide.create "ScreenGui" {
			Name = "backstage",
			DisplayOrder = DISPLAY_ORDER,

			ResetOnSpawn = false,
			IgnoreGuiInset = true,
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling,

			app {
				title = "backstage",
				footer = `v{version}`,

				visible = visible,
				on_close = close,
			},
		}
	end, player_gui)

	shortcut.listen(options, toggle)
end

--// End
return start
