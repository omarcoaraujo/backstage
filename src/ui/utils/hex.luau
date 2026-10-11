--// Constants
const SHORT_LENGTH = 3
const FULL_LENGTH = 6

--// Functions
const function to_hex(color: Color3): string
	return string.format(
		"#%02X%02X%02X",
		math.round(color.R * 255),
		math.round(color.G * 255),
		math.round(color.B * 255)
	)
end

const function expand(digits: string): string
	if #digits ~= SHORT_LENGTH then return digits end
	return (string.gsub(digits, ".", "%0%0"))
end

const function from_hex(text: string): Color3?
	const stripped = string.gsub(text, "^%s*#?(%x+)%s*$", "%1")
	const digits = expand(stripped)
	if #digits ~= FULL_LENGTH or not string.match(digits, "^%x+$") then return nil end

	const red = tonumber(string.sub(digits, 1, 2), 16)
	const green = tonumber(string.sub(digits, 3, 4), 16)
	const blue = tonumber(string.sub(digits, 5, 6), 16)
	
	if not red or not green or not blue then return nil end
	return Color3.fromRGB(red, green, blue)
end

--// End
return table.freeze {
	to_hex = to_hex,
	from_hex = from_hex,
}
