--// Modules
const fs = require "@std/fs"
const locate = require "./locate"

--// Constants
const EXTENSIONS = { [".luau"] = true, [".lua"] = true }
const SKIPPED = {
	[".git"] = true,
	roblox_packages = true,

	luau_packages = true,
	node_modules = true,

	build = true,
	Packages = true,
}

--// Types
export type index = { [string]: { string } }
type ignored = { names: { [string]: boolean }, paths: { [string]: boolean } }

--// Functions
const function has_extension(name: string)
	const dot = string.match(name, "%.%w+$")
	return dot ~= nil and EXTENSIONS[dot] == true
end

const function mentions_config(source: string)
	return string.find(source, "config", 1, true) ~= nil
end

const function read_ignored(root: string): ignored
	const ignored = { names = {}, paths = {} } :: ignored
	const file = `{root}/.gitignore`
	if not fs.exists(file) then return ignored end

	for line in string.gmatch(fs.readFileToString(file), "[^\r\n]+") do
		if string.find(line, "^[#!]") or string.find(line, "[%*%?%[%s]") then continue end

		const anchored = string.sub(line, 1, 1) == "/"
		const trimmed = string.gsub(string.gsub(line, "^/", ""), "/$", "")

		if trimmed == "" then continue end
		if anchored or string.find(trimmed, "/", 1, true) then
			ignored.paths[trimmed] = true
			continue
		end

		ignored.names[trimmed] = true
	end

	return ignored
end

const function is_skipped(name: string, relative: string, ignored: ignored)
	return SKIPPED[name] == true or ignored.names[name] == true or ignored.paths[relative] == true
end

const function visit(directory: string, relative: string, found: index, dynamic: { string }, ignored: ignored)
	for _, entry in fs.listDirectory(directory) do
		const path = `{directory}/{entry.name}`
		const relative_path = if relative == "" then entry.name else `{relative}/{entry.name}`

		if entry.type == "dir" then
			if not is_skipped(entry.name, relative_path, ignored) then
				visit(path, relative_path, found, dynamic, ignored)
			end

			continue
		end

		if entry.type ~= "file" or not has_extension(entry.name) then continue end
		const source = fs.readFileToString(path)
		if not mentions_config(source) then continue end

		const ok, names, lines = pcall(locate.config_names, source)
		if not ok then continue end

		for _, name in names do
			const files = found[name] or {}
			table.insert(files, path)
			found[name] = files
		end

		for _, line in lines do
			table.insert(dynamic, `{path}:{line}`)
		end
	end
end

const function scan(root: string)
	const found = {} :: index
	const dynamic = {} :: { string }

	visit(root, "", found, dynamic, read_ignored(root))
	return found, dynamic
end

--// End
return { scan = scan }
