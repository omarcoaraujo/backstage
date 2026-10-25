--// Utils
const format = require "../../utils/format"

--// Components
const field = require "./field"

--// Types
type props = {
	value: () -> number,
	on_change: (value: number) -> (),

	decimals: number?,
	locked: (() -> boolean)?,
}

--// Component
return function(props: props)
	const function text()
		return format.number(props.value(), props.decimals)
	end

	const function on_commit(typed: string)
		const parsed = tonumber(typed)
		if not parsed then return end
		props.on_change(parsed)
	end

	return field { text = text, on_commit = on_commit, locked = props.locked }
end
