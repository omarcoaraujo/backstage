--// Services
const UserInputService = game:GetService "UserInputService"

--// Constants
const DEFAULT_KEY = Enum.KeyCode.B

--// Types
export type options = {
	key: Enum.KeyCode?,
	ctrl: boolean?,
}

--// Functions
const function holding_control()
	return UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)
end

const function listen(options: options?, on_press: () -> ()): RBXScriptConnection
	const key = if options and options.key then options.key else DEFAULT_KEY
	const needs_control = not options or options.ctrl ~= false

	return UserInputService.InputBegan:Connect(function(input: InputObject)
		if input.KeyCode ~= key then return end
		if needs_control and not holding_control() then return end
		on_press()
	end)
end

--// End
return table.freeze { listen = listen }
