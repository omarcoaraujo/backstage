--// Modules
const apply = require "./apply"
const fs = require "@std/fs"
const json = require "@std/json"
const locate = require "./locate"
const scan = require "./scan"

--// Types
type edit = apply.edit
type refusal = apply.refusal
export type state = { index: scan.index }

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

const function save_edits(root: string, state: state, message: string)
	const ok, payload = pcall(json.deserialize, message)
	if not ok or type(payload) ~= "table" or type(payload.edits) ~= "table" then return nil end

	local names = index_names(state.index)
	const refusals = {} :: { refusal }
	const by_file = {} :: { [string]: { edit } }

	for _, edit in payload.edits do
		if locate.owning_name(names, edit.path) then continue end

		state.index = scan.scan(root)
		names = index_names(state.index)
		break
	end

	for name, edits in group_by_config(payload.edits, names) do
		const files = state.index[name]
		if not files then
			refuse_all(edits, `config "{name}" is not in the project`, refusals)
			continue
		end

		if #files > 1 then
			refuse_all(edits, `config "{name}" is declared in {#files} files: {table.concat(files, ", ")}`, refusals)
			continue
		end

		const file_edits = by_file[files[1]] or {}
		table.move(edits, 1, #edits, #file_edits + 1, file_edits)
		by_file[files[1]] = file_edits
	end

	for file, edits in by_file do
		const source = fs.readFileToString(file)
		const updated, refused = apply.apply(source, edits)

		if updated ~= source then fs.writeStringToFile(file, updated) end
		table.move(refused, 1, #refused, #refusals + 1, refusals)
	end

	return refusals
end

--// End
return { save_edits = save_edits }
