--// Services
const ReplicatedStorage = game:GetService "ReplicatedStorage"

--// Modules
const hex = require(ReplicatedStorage.backstage.ui.utils.hex)

--// Specs
return {
	to_hex_writes_uppercase_with_hash = function()
		assert(hex.to_hex(Color3.fromRGB(255, 128, 0)) == "#FF8000")
		assert(hex.to_hex(Color3.new()) == "#000000")
	end,

	from_hex_reads_six_digits = function()
		assert(hex.from_hex "#FF8000" == Color3.fromRGB(255, 128, 0))
		assert(hex.from_hex "ff8000" == Color3.fromRGB(255, 128, 0))
	end,

	from_hex_expands_three_digits = function()
		assert(hex.from_hex "#F80" == Color3.fromRGB(255, 136, 0))
	end,

	from_hex_ignores_surrounding_spaces = function()
		assert(hex.from_hex "  #00FF00 " == Color3.fromRGB(0, 255, 0))
	end,

	from_hex_rejects_invalid_text = function()
		assert(hex.from_hex "" == nil)
		assert(hex.from_hex "#12" == nil)

		assert(hex.from_hex "#GGGGGG" == nil)
		assert(hex.from_hex "#1234567" == nil)
	end,

	round_trip_keeps_the_color = function()
		const color = Color3.fromRGB(12, 200, 99)
		assert(hex.from_hex(hex.to_hex(color)) == color)
	end,
}
