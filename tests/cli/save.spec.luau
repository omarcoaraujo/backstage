--// Modules
const fs = require "@std/fs"
const json = require "@std/json"
const process = require "@std/process"
const save = require "../../cli/save"
const scan = require "../../cli/scan"

--// Functions
const function make_project()
	const root = `{process.homedir()}/.backstage_save_spec`
	if fs.exists(root) then fs.removeDirectory(root, { recursive = true }) end

	fs.createDirectory(root)
	fs.writeStringToFile(`{root}/pets.luau`, 'backstage.config("pets", { speed = 1 })')
	fs.writeStringToFile(`{root}/world.luau`, 'backstage.config("world", { gravity = 2 })')
	fs.writeStringToFile(`{root}/world_copy.luau`, 'backstage.config("world", { gravity = 3 })')

	return root
end

const function with_project(check: (root: string, state: save.state) -> ())
	const root = make_project()
	const ok, err = pcall(function()
		check(root, { index = scan.scan(root) })
	end)

	fs.removeDirectory(root, { recursive = true })
	if not ok then error(err, 0) end
end

const function message(edits)
	return json.serialize { edits = edits }
end

const function number_edit(path: string, value: number)
	return { path = path, kind = "number", value = value }
end

--// Specs
return {
	routes_an_edit_to_the_file_of_its_config = function()
		with_project(function(root, state)
			const refusals = save.save_edits(root, state, message { number_edit("pets.speed", 5) })
			assert(refusals and #refusals == 0)
			assert(fs.readFileToString(`{root}/pets.luau`) == 'backstage.config("pets", { speed = 5 })')
		end)
	end,

	refuses_a_config_declared_in_two_files = function()
		with_project(function(root, state)
			const refusals = save.save_edits(root, state, message { number_edit("world.gravity", 9) })
			assert(refusals and #refusals == 1 and refusals[1].path == "world.gravity")
			assert(fs.readFileToString(`{root}/world.luau`) == 'backstage.config("world", { gravity = 2 })')
		end)
	end,

	refuses_a_config_that_is_not_in_the_project = function()
		with_project(function(root, state)
			const refusals = save.save_edits(root, state, message { number_edit("cats.speed", 5) })
			assert(refusals and #refusals == 1 and refusals[1].reason == 'config "cats" is not in the project')
		end)
	end,

	scans_again_for_a_config_created_after_the_start = function()
		with_project(function(root, state)
			fs.writeStringToFile(`{root}/cats.luau`, 'backstage.config("cats", { speed = 1 })')
			const refusals = save.save_edits(root, state, message { number_edit("cats.speed", 4) })

			assert(refusals and #refusals == 0)
			assert(fs.readFileToString(`{root}/cats.luau`) == 'backstage.config("cats", { speed = 4 })')
		end)
	end,

	saves_the_edits_of_each_config_in_its_own_file = function()
		with_project(function(root, state)
			const refusals =
				save.save_edits(root, state, message { number_edit("pets.speed", 6), number_edit("world.gravity", 1) })

			assert(refusals and #refusals == 1)
			assert(fs.readFileToString(`{root}/pets.luau`) == 'backstage.config("pets", { speed = 6 })')
		end)
	end,

	answers_nothing_to_a_message_without_edits = function()
		with_project(function(root, state)
			assert(save.save_edits(root, state, "not json") == nil)
			assert(save.save_edits(root, state, "{}") == nil)
		end)
	end,
}
