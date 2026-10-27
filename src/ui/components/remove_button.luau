--// Components
const header_action = require "./header_action"

--// Types
type props = {
	position: () -> UDim2,
	shown: () -> boolean,
	on_remove: () -> (),
}

--// Component
return function(props: props)
	const function text()
		return "×"
	end

	return header_action {
		name = "remove",
		danger = true,

		position = props.position,
		shown = props.shown,

		text = text,
		on_activated = props.on_remove,
	}
end
