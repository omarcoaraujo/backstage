--// Constants
const DEFAULT_DECIMALS = 3
const MAX_DECIMALS = 10
const STEP_TOLERANCE = 1e-6

--// Functions
const function decimals_of(value: number)
	for places = 0, MAX_DECIMALS do
		const scaled = math.abs(value) * 10 ^ places
		if math.abs(scaled - math.round(scaled)) < STEP_TOLERANCE then return places end
	end

	return MAX_DECIMALS
end

const function of_limits(step: number?, min: number?)
	if not step or step <= 0 then return DEFAULT_DECIMALS end
	return math.max(decimals_of(step), if min then decimals_of(min) else 0)
end

const function round(value: number, decimals: number?)
	const scale = 10 ^ (decimals or DEFAULT_DECIMALS)
	return math.round(value * scale) / scale
end

const function text(value: number, decimals: number?)
	const places = decimals or DEFAULT_DECIMALS
	const rounded = round(value, places)

	if rounded == 0 then return "0" end
	const formatted = string.format(`%.{places}f`, rounded)

	if places == 0 then return formatted end
	return (string.gsub(string.gsub(formatted, "0+$", ""), "%.$", ""))
end

--// End
return table.freeze {
	decimals = DEFAULT_DECIMALS,
	of_limits = of_limits,

	round = round,
	text = text,
}
