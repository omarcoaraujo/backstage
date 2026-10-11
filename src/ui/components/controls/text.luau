--// Components
const field = require "./field"

--// Types
type props = {
	value: () -> string,
	on_change: (value: string) -> (),
}

--// Component
return function(props: props)
	return field {
		text = props.value,
		on_commit = props.on_change,
		alignment = Enum.TextXAlignment.Left,
	}
end
