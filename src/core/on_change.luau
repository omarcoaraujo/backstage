--// Modules
const mode = require "./mode"
const registry = require "./registry"
const tracker = require "./tracker"

--// Constants
const USAGE =
	"backstage: on_change takes a config value or a group and a callback, like on_change(config.size, callback)"

--// Functions
const function inert() end

const function belongs_to_call(access: tracker.access, caller: unknown, source: string, line: number)
	if access.caller ~= caller or access.source ~= source then return false end
	if not access.line then return false end
	return access.line >= line
end

const function path_of(target: unknown, caller: unknown, source: string?, line: number?): string?
	const reads = tracker.take()

	if not caller or not source or not line then
		const last = reads[#reads]
		if last and last.value == target then return last.path end
		return nil
	end

	for _, access in reads do
		if not belongs_to_call(access, caller, source, line) then continue end
		if access.value ~= target then return nil end
		return access.path
	end

	return nil
end

--// End
return function<value>(target: value, callback: (value: value, previous: value, path: string) -> ()): () -> ()
	if not mode.active() then return inert end
	const group = registry.group_path(target)

	if group then
		return registry.on_change(function(changed, current, previous)
			if not registry.inside(changed, group) then return end
			callback(current :: any, previous :: any, changed)
		end)
	end

	const caller, source, line = debug.info(2, "fsl")
	const path = path_of(target, caller, source, line)

	if not path then error(USAGE, 2) end
	return registry.on_change(function(changed, current, previous)
		if changed ~= path then return end
		callback(current :: any, previous :: any, changed)
	end)
end
