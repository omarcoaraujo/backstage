--// Modules
const apply = require "./apply"
const entries = require "./entries"
const fs = require "@std/fs"
const json = require "@std/json"
const locate = require "./locate"
const scan = require "./scan"
const values = require "./values"

--// Constants
const MAX_READS = 3

--// Types
type edit = apply.edit
type refusal = apply.refusal

export type change = { kind: string, path: string, from: string? }
export type state = {
	index: scan.index,
	literals: { [string]: values.snapshot },

	removed: { [string]: entries.removed },
	saving: number,
}

--// Functions
const function index_names(index: scan.index)
	const names = {}

	for name in index do
		table.insert(names, name)
	end

	return names
end

const function config_name(names: { string }, path: string)
	return locate.owning_name(names, path) or string.match(path, "^[^%.]+") :: string
end

const function refuse_all(edits: { edit }, reason: string, refusals: { refusal })
	for _, edit in edits do
		table.insert(refusals, { path = edit.path, reason = reason })
	end
end

const function group_by_config(edits: { edit }, names: { string })
	const groups = {} :: { [string]: { edit } }

	for _, edit in edits do
		const name = config_name(names, edit.path)
		const group = groups[name] or {}

		table.insert(group, edit)
		groups[name] = group
	end

	return groups
end

const function rewrite_file(state: state, file: string, edits: { edit })
	local source = fs.readFileToString(file)
	local updated, refused = apply.apply(source, edits)

	for _ = 1, MAX_READS do
		const current = fs.readFileToString(file)
		if current == source then break end

		source = current
		updated, refused = apply.apply(source, edits)
	end

	if updated ~= source then
		fs.writeStringToFile(file, updated)
		state.literals[file] = values.read(updated)
	end

	return refused
end

const function rewrite(state: state, file: string, edits: { edit })
	state.saving += 1
	const ok, result = pcall(rewrite_file, state, file, edits)
	state.saving -= 1

	if not ok then error(result, 0) end
	return result :: { refusal }
end

const function save(root: string, state: state, edits: { edit })
	local names = index_names(state.index)
	const refusals = {} :: { refusal }
	const by_file = {} :: { [string]: { edit } }

	for _, edit in edits do
		if locate.owning_name(names, edit.path) then continue end

		state.index = scan.scan(root)
		names = index_names(state.index)
		break
	end

	for name, group in group_by_config(edits, names) do
		const files = state.index[name]
		if not files then
			refuse_all(group, `config "{name}" is not in the project`, refusals)
			continue
		end

		if #files > 1 then
			refuse_all(group, `config "{name}" is declared in {#files} files: {table.concat(files, ", ")}`, refusals)
			continue
		end

		const file_edits = by_file[files[1]] or {}
		table.move(group, 1, #group, #file_edits + 1, file_edits)
		by_file[files[1]] = file_edits
	end

	for file, file_edits in by_file do
		const refused = rewrite(state, file, file_edits)
		table.move(refused, 1, #refused, #refusals + 1, refusals)
	end

	return refusals
end

const function restructure_file(state: state, file: string, change: change): string?
	const source = fs.readFileToString(file)
	local updated, reason = nil :: string?, nil :: string?
	local removed = nil :: entries.removed?

	if change.kind == "add" and change.from then
		updated, reason = entries.add(source, change.path, change.from)
	elseif change.kind == "remove" then
		updated, reason, removed = entries.remove(source, change.path)
	elseif change.kind == "restore" then
		const taken = state.removed[change.path]
		if not taken then return `"{change.path}" was not removed from the window, so there is nothing to restore` end
		updated, reason = entries.restore(source, change.path, taken)
	else
		return "expected an add with a sibling to copy, a remove, or a restore"
	end

	if not updated then return reason end
	fs.writeStringToFile(file, updated)

	state.removed[change.path] = removed
	state.literals[file] = values.read(updated)

	return nil
end

const function restructure_safely(state: state, file: string, change: change)
	state.saving += 1
	const ok, result = pcall(restructure_file, state, file, change)
	state.saving -= 1

	if not ok then error(result, 0) end
	return result :: string?
end

const function restructure(root: string, state: state, changes: { change })
	local names = index_names(state.index)
	const refusals = {} :: { refusal }

	for _, change in changes do
		if locate.owning_name(names, change.path) then continue end

		state.index = scan.scan(root)
		names = index_names(state.index)
		break
	end

	for _, change in changes do
		const name = config_name(names, change.path)
		const files = state.index[name]

		if not files then
			table.insert(refusals, {
				path = change.path,
				reason = `config "{name}" is not in the project`,
				kind = change.kind,
			})

			continue
		end

		if #files > 1 then
			table.insert(refusals, {
				path = change.path,
				reason = `config "{name}" is declared in {#files} files: {table.concat(files, ", ")}`,
				kind = change.kind,
			})

			continue
		end

		const reason = restructure_safely(state, files[1], change)
		if reason then table.insert(refusals, { path = change.path, reason = reason, kind = change.kind }) end
	end

	return refusals
end

const function save_edits(root: string, state: state, message: string)
	const ok, payload = pcall(json.deserialize, message)
	if not ok or type(payload) ~= "table" then return nil end

	if type(payload.edits) ~= "table" and type(payload.changes) ~= "table" then return nil end
	const refusals = if type(payload.changes) == "table" then restructure(root, state, payload.changes) else {}

	if type(payload.edits) ~= "table" then return refusals end
	const refused = save(root, state, payload.edits)

	table.move(refused, 1, #refused, #refusals + 1, refusals)
	return refusals
end

--// End
return {
	save = save,
	save_edits = save_edits,
	restructure = restructure,
}
