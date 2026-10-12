--// Modules
const write = require "../../cli/write"

--// Specs
return {
	number_trims_trailing_zeros = function()
		assert(write.literal { kind = "number", value = 1.5 } == "1.5")
		assert(write.literal { kind = "number", value = 12 } == "12")
		assert(write.literal { kind = "number", value = 0.25 } == "0.25")
	end,

	number_keeps_six_decimals = function()
		assert(write.literal { kind = "number", value = 0.1234567 } == "0.123457")
	end,

	number_never_writes_negative_zero = function()
		assert(write.literal { kind = "number", value = -0 } == "0")
		assert(write.literal { kind = "number", value = -0.0000001 } == "0")
	end,

	number_keeps_the_sign = function()
		assert(write.literal { kind = "number", value = -3.5 } == "-3.5")
	end,

	boolean_writes_the_keyword = function()
		assert(write.literal { kind = "boolean", value = true } == "true")
		assert(write.literal { kind = "boolean", value = false } == "false")
	end,

	string_uses_double_quotes_and_escapes = function()
		assert(write.literal { kind = "string", value = "hi" } == '"hi"')
		assert(write.literal { kind = "string", value = 'say "x"' } == '"say \\"x\\""')
		assert(write.literal { kind = "string", value = "a\\b" } == '"a\\\\b"')
	end,

	color_writes_from_rgb = function()
		const text = write.literal { kind = "color", value = { r = 255, g = 128, b = 0 } }
		assert(text == "Color3.fromRGB(255, 128, 0)")
	end,

	vector3_writes_the_three_axes = function()
		const text = write.literal { kind = "vector3", value = { x = 1, y = -2.5, z = 0 } }
		assert(text == "Vector3.new(1, -2.5, 0)")
	end,

	replace_swaps_only_the_range = function()
		const range = { begin_line = 1, begin_column = 9, end_line = 1, end_column = 10 }
		assert(write.replace("local x=1 -- keep", range, "42") == "local x=42 -- keep")
	end,

	replace_reaches_later_lines = function()
		const source = "a = 1\nb = 2\nc = 3"
		const range = { begin_line = 2, begin_column = 5, end_line = 2, end_column = 6 }
		assert(write.replace(source, range, "99") == "a = 1\nb = 99\nc = 3")
	end,
}
