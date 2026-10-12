--// Services
const ReplicatedStorage = game:GetService "ReplicatedStorage"

--// Modules
const kinds = require(ReplicatedStorage.backstage.core.kinds)

--// Functions
const function number(limit: kinds.limit?)
	return kinds.infer(1, limit) :: kinds.descriptor
end

--// Specs
return {
	infer_reads_the_kind_from_the_default = function()
		assert((kinds.infer(1) :: kinds.descriptor).kind == "number")
		assert((kinds.infer(true) :: kinds.descriptor).kind == "boolean")

		assert((kinds.infer "a" :: kinds.descriptor).kind == "string")
		assert((kinds.infer(Color3.new()) :: kinds.descriptor).kind == "color")
		assert((kinds.infer(Vector3.zero) :: kinds.descriptor).kind == "vector3")
	end,

	infer_prefers_choices_over_the_default_type = function()
		const descriptor = kinds.infer("a", { choices = { "a", "b" } }) :: kinds.descriptor
		assert(descriptor.kind == "choice")
	end,

	infer_rejects_unsupported_values = function()
		assert(kinds.infer(nil) == nil)
		assert(kinds.infer(function() end) == nil)
	end,

	number_is_clamped = function()
		const descriptor = number { min = 0, max = 10 }
		assert(kinds.coerce(descriptor, 15) == 10)

		assert(kinds.coerce(descriptor, -3) == 0)
		assert(kinds.coerce(descriptor, 4) == 4)
	end,

	number_snaps_to_step_from_min = function()
		const descriptor = number { min = 1, max = 10, step = 2 }
		assert(kinds.coerce(descriptor, 4.2) == 5)
		assert(kinds.coerce(descriptor, 2.4) == 3)
	end,

	number_step_has_no_float_noise = function()
		const descriptor = number { min = 0, max = 30, step = 0.1 }
		assert(kinds.coerce(descriptor, 0.30000000000000004) == 0.3)
	end,

	number_rejects_nan_inf_and_other_types = function()
		const descriptor = number()
		assert(kinds.coerce(descriptor, 0 / 0) == nil)

		assert(kinds.coerce(descriptor, math.huge) == nil)
		assert(kinds.coerce(descriptor, "3") == nil)
	end,

	choice_only_accepts_listed_values = function()
		const descriptor = kinds.infer("a", { choices = { "a", "b" } }) :: kinds.descriptor
		assert(kinds.coerce(descriptor, "b") == "b")

		assert(kinds.coerce(descriptor, "c") == nil)
		assert(kinds.coerce(descriptor, 1) == nil)
	end,

	other_kinds_reject_the_wrong_type = function()
		assert(kinds.coerce({ kind = "boolean" }, "x") == nil)
		assert(kinds.coerce({ kind = "string" }, 1) == nil)

		assert(kinds.coerce({ kind = "color" }, Vector3.zero) == nil)
		assert(kinds.coerce({ kind = "vector3" }, Color3.new()) == nil)
	end,
}
