--// Packages
const vide = require "../../../roblox_packages/vide"

--// Types
export type node = {
	forced: vide.Source<boolean>,
	shown: () -> boolean,
	adopt: ((content: { Instance }) -> ())?,
}

--// Variables
const query = vide.source ""
const nodes = setmetatable({} :: { [Instance]: node }, { __mode = "k" })

const texts = {} :: { [string]: string }
const text_version = vide.source(0)

--// Functions
const function searching(): boolean
	return query() ~= ""
end

const function set_text(path: string, value: string)
	texts[path] = string.lower(value)
	if searching() then text_version(text_version() + 1) end
end

const function clear_texts()
	table.clear(texts)
end

const function text_hit(path: string): boolean
	text_version()
	if not searching() then return false end

	const found = texts[path]
	return found ~= nil and string.find(found, string.lower(query()), 1, true) ~= nil
end

const function text_hit_any(paths: { string }): boolean
	for _, path in paths do
		if text_hit(path) then return true end
	end

	return false
end

const function matches(name: string): boolean
	if not searching() then return true end
	return string.find(string.lower(name), string.lower(query()), 1, true) ~= nil
end

const function matches_any(names: { string }): boolean
	for _, name in names do
		if matches(name) then return true end
	end

	return false
end

const function leaf(names: { string }, text_path: string?): node
	const forced = vide.source(false)

	const function shown(): boolean
		if forced() or matches_any(names) then return true end
		return text_path ~= nil and text_hit(text_path)
	end

	return { forced = forced, shown = shown }
end

const function branch(name: string, descendants: { string }, text_paths: { string }): node
	const forced = vide.source(false)
	const children = {} :: { node }

	const function passes_down(): boolean
		return forced() or matches(name)
	end

	const function shown(): boolean
		if passes_down() then return true end
		if matches_any(descendants) or text_hit_any(text_paths) then return true end

		for _, child in children do
			if child.shown() then return true end
		end

		return false
	end

	const function adopt(content: { Instance })
		for _, child in content do
			const child_node = nodes[child]
			if not child_node then continue end

			table.insert(children, child_node)
			vide.effect(function()
				child_node.forced(passes_down())
			end)
		end
	end

	return { forced = forced, shown = shown, adopt = adopt }
end

const function track(target: Instance, node: node)
	nodes[target] = node
end

--// End
return table.freeze {
	query = query,
	set_text = set_text,

	clear_texts = clear_texts,
	searching = searching,

	leaf = leaf,
	branch = branch,
	track = track,
}
