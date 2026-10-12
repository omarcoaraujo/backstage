--// Services
const Players = game:GetService "Players"
const RunService = game:GetService "RunService"
const UserInputService = game:GetService "UserInputService"

--// Modules
const mode = require "./mode"

--// Constants
const TOGGLE_KEY = Enum.KeyCode.B
const DISPLAY_ORDER = 1000

--// Variables
local started = false

--// Functions
const function holding_control()
	return UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)
end

const function start()
	if started or not mode.active() or not RunService:IsClient() then return end
	started = true

	const vide = require "../../roblox_packages/vide"
	const app = require "../ui/app"
	const version = require "../version"

	const player_gui = Players.LocalPlayer:WaitForChild "PlayerGui"
	const visible = vide.source(false)

	const function close()
		visible(false)
	end

	const function on_input(input: InputObject)
		if input.KeyCode ~= TOGGLE_KEY or not holding_control() then return end
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
