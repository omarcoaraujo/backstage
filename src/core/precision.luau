--// Constants
const DECIMALS = 3
const DECIMAL_SCALE = 10 ^ DECIMALS

--// Functions
const function round(value: number)
	return math.round(value * DECIMAL_SCALE) / DECIMAL_SCALE
end

--// End
return table.freeze {
	decimals = DECIMALS,
	round = round,
}
