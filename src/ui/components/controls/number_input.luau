--// Components
const field = require "./field"

--// Constants
const DECIMALS = 3
const DECIMAL_SCALE = 10 ^ DECIMALS

--// Types
type props = {
	value: () -> number,
	on_change: (value: number) -> (),
}

--// Functions
const function format(value: number): string
	const rounded = math.round(value * DECIMAL_SCALE) / DECIMAL_SCALE
	if rounded == 0 then return "0" end
	return (string.gsub(string.format(`%.{DECIMALS}f`, rounded), "%.?0+$", ""))
end

--// Component
return function(props: props)
	const function text()
		return format(props.value())
	end

	const function on_commit(typed: string)
		const parsed = tonumber(typed)
		if not parsed then return end
		props.on_change(parsed)
	end

	return field { text = text, on_commit = on_commit }
end
