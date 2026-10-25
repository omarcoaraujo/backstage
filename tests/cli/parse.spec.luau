--// Modules
const parse = require "../../cli/parse"

--// Specs
return {
	reads_numbers_and_booleans = function()
		const edits, problems = parse.parse "pets.distance = 8.5\npets.trail.enabled = false"

		assert(#problems == 0)
		assert(#edits == 2)

		assert(edits[1].path == "pets.distance" and edits[1].kind == "number" and edits[1].value == 8.5)
		assert(edits[2].path == "pets.trail.enabled" and edits[2].kind == "boolean" and edits[2].value == false)
	end,

	reads_strings_with_escapes = function()
		const edits = parse.parse 'pets.mode = "say \\"hi\\"\\nbye"'
		assert(edits[1].kind == "string" and edits[1].value == 'say "hi"\nbye')
	end,

	reads_colors_and_vectors = function()
		const edits, problems =
			parse.parse "pets.tint = Color3.fromRGB(255, 128, 0)\npets.offset = Vector3.new(0, 1.5, -2)"
		assert(#problems == 0)

		const color = edits[1].value :: any
		assert(edits[1].kind == "color" and color.r == 255 and color.g == 128 and color.b == 0)

		const vector = edits[2].value :: any
		assert(edits[2].kind == "vector3" and vector.x == 0 and vector.y == 1.5 and vector.z == -2)
	end,

	skips_blank_lines_and_windows_line_endings = function()
		const edits, problems = parse.parse "\npets.distance = 8\r\n\r\npets.speed = 2\r\n"

		assert(#problems == 0)
		assert(#edits == 2)
	end,

	reports_the_line_it_could_not_read = function()
		const edits, problems = parse.parse "pets.distance = 8\nnot a value\npets.speed = Vector3.new(1, 2)"

		assert(#edits == 1)
		assert(#problems == 2)

		assert(string.find(problems[1], "line 2", 1, true) ~= nil)
		assert(string.find(problems[2], "line 3", 1, true) ~= nil)
	end,
}
