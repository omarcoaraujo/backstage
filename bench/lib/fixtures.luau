--// Services
const ReplicatedStorage = game:GetService "ReplicatedStorage"

--// Modules
const button = require(ReplicatedStorage.backstage.core.button)
const kinds = require(ReplicatedStorage.backstage.core.kinds)
const mode = require(ReplicatedStorage.backstage.core.mode)
const registry = require(ReplicatedStorage.backstage.core.registry)

--// Constants
const GROUP_SIZE = 10

--// Functions
const function fresh()
	registry.reset()
	mode.enable()

	registry.connect_remote {
		edit = function() end,
		press = function() end,
		commit = function() end,
	}
end

const function group_of(index: number)
	return `g{math.ceil(index / GROUP_SIZE)}`
end

const function path_of(index: number)
	return `{group_of(index)}.e{index}`
end

const function default_of(index: number, texts: boolean): kinds.value
	if texts and index % 2 == 0 then return `Value {index}` end
	return index
end

const function declare(count: number, texts: boolean)
	for index = 1, count do
		const default = default_of(index, texts)
		registry.add(path_of(index), `e{index}`, group_of(index), kinds.infer(default) :: kinds.descriptor, default)
	end
end

const function snapshot(count: number): registry.snapshot
	const entries = {}

	for index = 1, count do
		const default = default_of(index, true)

		table.insert(entries, {
			path = path_of(index),
			name = `e{index}`,
			group = group_of(index),

			descriptor = kinds.infer(default) :: kinds.descriptor,
			default = default,
			value = default,
		})
	end

	return { entries = entries, buttons = {} }
end

const function variant(kind: string, size: number)
	const fields = { kind = kind } :: { [string]: string | number }

	for index = 1, size do
		fields[`{kind}_{index}`] = index
	end

	return fields
end

const function declare_buttons(count: number)
	for index = 1, math.ceil(count / GROUP_SIZE) do
		registry.add_button(`g{index}.go`, "go", `g{index}`, button.create())
	end
end

const function add_extra()
	registry.add("extra.e1", "e1", "extra", kinds.infer(1) :: kinds.descriptor, 1)
	registry.announce()
end

const function edit_all(count: number)
	for index = 1, count do
		if index % 2 == 0 then continue end
		registry.set(path_of(index), index + 0.5)
	end
end

--// End
return table.freeze {
	fresh = fresh,
	declare = declare,

	snapshot = snapshot,
	variant = variant,

	declare_buttons = declare_buttons,
	add_extra = add_extra,
	edit_all = edit_all,

	path_of = path_of,
	group_of = group_of,
}
