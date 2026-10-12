--// Services
const ReplicatedStorage = game:GetService "ReplicatedStorage"

--// Modules
const format = require(ReplicatedStorage.backstage.ui.utils.format)

--// Specs
return {
	number_keeps_up_to_three_decimals = function()
		assert(format.number(0.123456) == "0.123")
		assert(format.number(1.5) == "1.5")
	end,

	number_drops_trailing_zeros = function()
		assert(format.number(2) == "2")
		assert(format.number(2.1) == "2.1")
	end,

	number_never_writes_negative_zero = function()
		assert(format.number(-0.0001) == "0")
		assert(format.number(0) == "0")
	end,

	value_formats_each_type = function()
		assert(format.value(1.25) == "1.25")
		assert(format.value "a" == `"a"`)

		assert(format.value(Color3.fromRGB(255, 0, 0)) == "#FF0000")
		assert(format.value(Vector3.new(1, 2.5, 3)) == "1, 2.5, 3")

		assert(format.value {} == "{...}")
		assert(format.value(true) == "true")
	end,
}
