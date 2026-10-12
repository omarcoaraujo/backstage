--// Services
const Players = game:GetService "Players"
const RunService = game:GetService "RunService"
const UserInputService = game:GetService "UserInputService"

--// Modules
const mode = require "./mode"
const sync = require "./sync"

--// Constants
const DEFAULT_KEY = Enum.KeyCode.B
const DISPLAY_ORDER = 1000

--// Types
export type options = {
	key: Enum.KeyCode?,
	ctrl: boolean?,
}

--// Variables
local started = false

--// Functions
const function holding_control()
	return UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)
end

const function start(options: options?)
	if started or not mode.active() then return end
	started = true

	if RunService:IsServer() then
		sync.serve()
		return
	end

	if not RunService:IsClient() then return end
	sync.connect()

	const key = if options and options.key then options.key else DEFAULT_KEY
	const needs_control = not options or options.ctrl ~= false

	const vide = require "../../roblox_packages/vide"
	const app = require "../ui/app"
	const version = require "../version"

	const player_gui = Players.LocalPlayer:WaitForChild "PlayerGui"
	const visible = vide.source(false)

	const function close()
		visible(false)
	end

	const function on_input(input: InputObject)
		if input.KeyCode ~= key then return end
		if needs_control and not holding_control() then return end

		visible(not visible())
	end

	vide.mount(function()
		return vide.create "ScreenGui" {
			Name = "backstage",
			DisplayOrder = DISPLAY_ORDER,

			ResetOnSpawn = false,
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling,

			app {
				title = "backstage",
				footer = `v{version}`,

				visible = visible,
				on_close = close,
			},
		}
	end, player_gui)

	UserInputService.InputBegan:Connect(on_input)
end

--// End
return start
