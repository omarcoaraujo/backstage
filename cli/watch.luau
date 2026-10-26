--// Modules
const apply = require "./apply"
const fs = require "@std/fs"
const lute_fs = require "@lute/fs"
const output = require "./output"
const save = require "./save"
const scan = require "./scan"
const task = require "@lute/task"
const values = require "./values"

--// Constants
const SETTLE = 0.15

--// Types
export type notify = (edits: { apply.edit }, added: { apply.edit }, removed: { string }) -> ()

--// Functions
const function remember_all(state: save.state)
	for _, files in state.index do
		for _, file in files do
			if state.literals[file] then continue end

			const ok, source = pcall(fs.readFileToString, file)
			if not ok then continue end

			const parsed, snapshot = pcall(values.read, source)
			if parsed then state.literals[file] = snapshot end
		end
	end
end

const function refresh(state: save.state, file: string): ({ apply.edit }, { apply.edit }, { string })
	const readable, source = pcall(fs.readFileToString, file)
	if not readable then return {}, {}, {} end

	const parsed, current = pcall(values.read, source)
	if not parsed then return {}, {}, {} end

	const previous = state.literals[file]
	state.literals[file] = current

	if not previous then return {}, {}, {} end
	const added, removed = values.structure(previous, current)
	return values.changes(previous, current), added, removed
end

const function start(root: string, state: save.state, notify: notify)
	const handles = {} :: { [string]: unknown }
	const pending = {} :: { [string]: boolean }
	local rescan = false

	const function watch_directory(directory: string)
		if handles[directory] then return end

		handles[directory] = lute_fs.watch(directory, function(name, event)
			pending[`{directory}/{name}`] = true
			if event.rename then rescan = true end
		end)
	end

	const function watch_all()
		for _, directory in scan.directories(root) do
			watch_directory(directory)
		end
	end

	const function flush()
		const edits = {} :: { apply.edit }
		const added = {} :: { apply.edit }

		const removed = {} :: { string }
		const files = table.clone(pending)
		table.clear(pending)

		if rescan then
			rescan = false
			watch_all()
		end

		for file in files do
			if not scan.has_extension(file) then continue end
			const changed, appeared, vanished = refresh(state, file)

			table.move(changed, 1, #changed, #edits + 1, edits)
			table.move(appeared, 1, #appeared, #added + 1, added)
			table.move(vanished, 1, #vanished, #removed + 1, removed)
		end

		if #edits == 0 and #added == 0 and #removed == 0 then return end
		notify(edits, added, removed)
	end

	const function settle()
		while true do
			task.wait(SETTLE)
			if next(pending) == nil or state.saving > 0 then continue end

			const ok, reason = pcall(flush)
			if not ok then output.warning(`could not read the scripts that changed: {reason}`) end
		end
	end

	remember_all(state)
	watch_all()
	task.spawn(settle)
end

--// End
return {
	start = start,
}
