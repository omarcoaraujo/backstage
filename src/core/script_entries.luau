--// Modules
const registry = require "./registry"

--// Types
type target = { catalog: string, key: string }

--// Functions
const function chain_of(path: string)
	const chain = {} :: { string }
	local current = ""

	for segment in string.gmatch(path, "[^%.]+") do
		current = if current == "" then segment else `{current}.{segment}`
		table.insert(chain, current)
	end

	return chain
end

const function target_of(path: string): (string?, target?)
	const chain = chain_of(path)

	for index = 1, #chain - 1 do
		if not registry.is_catalog(chain[index]) then continue end

		const root = chain[index + 1]
		return root, { catalog = chain[index], key = string.match(root, "[^%.]+$") :: string }
	end

	return nil, nil
end

const function paths_inside(root: string)
	const found = {} :: { string }

	for _, entry in registry.list() do
		if entry.path == root or registry.inside(entry.path, root) then table.insert(found, entry.path) end
	end

	return found
end

const function add(paths: { string })
	for _, path in paths do
		const root, target = target_of(path)
		if not root or not target or #paths_inside(root) > 0 then continue end
		registry.add_item(target.catalog, target.key)
	end
end

const function remove(paths: { string })
	const gone = {} :: { [string]: boolean }
	const targets = {} :: { [string]: target }

	for _, path in paths do
		gone[path] = true

		const root, target = target_of(path)
		if root and target then targets[root] = target end
	end

	for root, target in targets do
		const remaining = paths_inside(root)
		local complete = #remaining > 0

		for _, path in remaining do
			if not gone[path] then complete = false end
		end

		if complete then registry.remove_item(target.catalog, target.key) end
	end
end

--// End
return table.freeze {
	add = add,
	remove = remove,
}
