--// Modules
const fs = require "@std/fs"

--// Specs
return {
	version_module_matches_the_pesde_manifest = function()
		const manifest = string.match(fs.readFileToString "pesde.toml", 'version = "([^"]+)"')
		const module = string.match(fs.readFileToString "src/version.luau", 'return "([^"]+)"')
		assert(manifest ~= nil and manifest == module)
	end,
}
