--// Modules
const apply = require "./apply"
const fs = require "@std/fs"
const json = require "@std/json"
const scan = require "./scan"

--// Types
type edit = apply.edit
type refusal = apply.refusal
export type state = { index: scan.index }

--// Functions
const function config_name(path: string)
	return string.match(path, "^[^%.]+") :: string
end

const function refuse_all(edits: { edit }, reason: string, refusals: { refusal })
	for _, edit in edits do
		table.insert(refusals, { path = edit.path, reason = reason })
	end
end

const function group_by_config(edits: { edit })
	const groups = {} :: { [string]: { edit } }

	for _, edit in edits do
		const name = config_name(edit.path)
		const group = groups[name] or {}

		table.insert(group, edit)
		groups[name] = group
	end

	return groups
end

const function save_edits(root: string, state: state, message: string)
	const ok, payload = pcall(json.deserialize, message)
	if not ok or type(payload) ~= "table" or type(payload.edits) ~= "table" then return nil end

	local scanned_again = false
	const refusals = {} :: { refusal }
	const by_file = {} :: { [string]: { edit } }

	for name, edits in group_by_config(payload.edits) do
		if not state.index[name] and not scanned_again then
			state.index = scan.scan(root)
			scanned_again = true
		end

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
