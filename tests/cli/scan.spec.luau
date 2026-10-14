--// Modules
const fs = require "@std/fs"
const process = require "@std/process"
const scan = require "../../cli/scan"

--// Functions
const function make_project()
	const root = `{process.homedir()}/.backstage_scan_spec`
	if fs.exists(root) then fs.removeDirectory(root, { recursive = true }) end

	fs.createDirectory(root)
	fs.createDirectory(`{root}/nested`)
	fs.createDirectory(`{root}/roblox_packages`)

	fs.writeStringToFile(`{root}/pets.luau`, 'backstage.config("pets", { speed = 1 })')
	fs.writeStringToFile(`{root}/nested/world.luau`, 'backstage.config("world", { gravity = 2 })')
	fs.writeStringToFile(`{root}/nested/world_copy.luau`, 'backstage.config("world", { gravity = 3 })')

	fs.writeStringToFile(`{root}/roblox_packages/vendor.luau`, 'backstage.config("vendor", {})')
	fs.createDirectory(`{root}/generated`)
	fs.createDirectory(`{root}/nested/cache`)
	fs.createDirectory(`{root}/nested/generated`)

	fs.writeStringToFile(`{root}/.gitignore`, "# output\n/generated/\ncache\n*.log\n")
	fs.writeStringToFile(`{root}/generated/made.luau`, 'backstage.config("made", {})')
	fs.writeStringToFile(`{root}/nested/cache/stored.luau`, 'backstage.config("stored", {})')
	fs.writeStringToFile(`{root}/nested/generated/kept.luau`, 'backstage.config("kept", {})')

	fs.writeStringToFile(`{root}/nested/named.luau`, "backstage.config(name, {})")
	fs.writeStringToFile(`{root}/plain.luau`, "return 1")
	fs.writeStringToFile(`{root}/notes.txt`, 'backstage.config("text", {})')
	fs.writeStringToFile(`{root}/broken.luau`, "config = = (")

	return root
end

const function with_project(check: (index: scan.index, root: string, dynamic: { string }) -> ())
	const root = make_project()
	const ok, err = pcall(function()
		const index, dynamic = scan.scan(root)
		check(index, root, dynamic)
	end)

	fs.removeDirectory(root, { recursive = true })
	if not ok then error(err, 0) end
end

--// Specs
return {
	indexes_each_config_by_name = function()
		with_project(function(index, root)
			assert(index.pets and #index.pets == 1)
			assert(index.pets[1] == `{root}/pets.luau`)
		end)
	end,

	lists_every_file_that_declares_the_same_name = function()
		with_project(function(index)
			assert(index.world and #index.world == 2)
		end)
	end,

	lists_the_place_of_a_config_whose_name_is_not_a_string = function()
		with_project(function(_, root, dynamic)
			assert(#dynamic == 1 and dynamic[1] == `{root}/nested/named.luau:1`)
		end)
	end,

	skips_the_folders_the_gitignore_names = function()
		with_project(function(index)
			assert(index.made == nil)
			assert(index.stored == nil)
		end)
	end,

	keeps_a_folder_the_gitignore_anchors_elsewhere = function()
		with_project(function(index)
			assert(index.kept and #index.kept == 1)
		end)
	end,

	skips_packages_other_extensions_and_broken_files = function()
		with_project(function(index)
			assert(index.vendor == nil)
			assert(index.text == nil)
		end)
	end,
}
