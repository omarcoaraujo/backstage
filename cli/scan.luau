--// Modules
const fs = require "@std/fs"
const locate = require "./locate"

--// Constants
const SKIPPED = { [".git"] = true, roblox_packages = true, node_modules = true, build = true, Packages = true }
const EXTENSIONS = { [".luau"] = true, [".lua"] = true }

--// Types
export type index = { [string]: { string } }

--// Functions
const function has_extension(name: string)
	const dot = string.match(name, "%.%w+$")
	return dot ~= nil and EXTENSIONS[dot] == true
end

const function mentions_config(source: string)
	return string.find(source, "config", 1, true) ~= nil
end

const function visit(directory: string, found: index)
	for _, entry in fs.listDirectory(directory) do
		const path = `{directory}/{entry.name}`
		if entry.type == "dir" then
			if not SKIPPED[entry.name] then visit(path, found) end
			continue
		end

		if entry.type ~= "file" or not has_extension(entry.name) then continue end
		const source = fs.readFileToString(path)
		if not mentions_config(source) then continue end

		const ok, names = pcall(locate.config_names, source)
		if not ok then continue end

		for _, name in names do
			const files = found[name] or {}
			table.insert(files, path)
			found[name] = files
		end
	end
end

const function scan(root: string)
	const found = {} :: index
	visit(root, found)
	return found
end

--// End
return { scan = scan }
