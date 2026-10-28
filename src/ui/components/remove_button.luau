--// Components
const header_action = require "./header_action"

--// Constants
const ICON = "rbxassetid://118608486657001"

--// Types
type props = {
	position: () -> UDim2,
	shown: () -> boolean,
	on_remove: () -> (),
}

--// Component
return function(props: props)
	return header_action {
		name = "remove",
		image = ICON,
		danger = true,

		position = props.position,
		shown = props.shown,
		on_activated = props.on_remove,
	}
end
