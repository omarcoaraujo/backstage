--// Constants
const MAX_PART_DEPTH = 16

--// Types
export type cursor = {
	group: string,
	row: string?,

	x: number,
	y: number,
}

export type hold = {
	owner: string,
	part: { string },
}

export type state = {
	cursor: cursor?,
	hold: hold?,
}

export type entry = {
	user: number,
	name: string,

	cursor: cursor?,
	hold: hold?,
}

type echo = {
	user: number,
	name: string,
	delay: number,
}

--// Variables
const entries = {} :: { [number]: entry }
const listeners = {} :: { () -> () }

local publisher = nil :: ((state: state?) -> ())?
local echo = nil :: echo?

--// Functions
const function finite(value: unknown)
	return type(value) == "number" and value == value and math.abs(value) < math.huge
end

const function valid_cursor(input: unknown): cursor?
	if type(input) ~= "table" then return nil end
	const candidate = input :: { [string]: unknown }

	if type(candidate.group) ~= "string" then return nil end
	if candidate.row ~= nil and type(candidate.row) ~= "string" then return nil end
	if not finite(candidate.x) or not finite(candidate.y) then return nil end

	return {
		group = candidate.group :: string,
		row = candidate.row :: string?,

		x = candidate.x :: number,
		y = candidate.y :: number,
	}
end

const function valid_hold(input: unknown): hold?
	if type(input) ~= "table" then return nil end
	const candidate = input :: { [string]: unknown }

	if type(candidate.owner) ~= "string" or type(candidate.part) ~= "table" then return nil end
	const names = candidate.part :: { unknown }

	if #names > MAX_PART_DEPTH then return nil end
	const part = {}

	for _, name in names do
		if type(name) ~= "string" then return nil end
		table.insert(part, name)
	end

	return { owner = candidate.owner :: string, part = part }
end

const function valid(input: unknown): state?
	if type(input) ~= "table" then return nil end
	const candidate = input :: { [string]: unknown }

	const cursor = valid_cursor(candidate.cursor)
	const hold = valid_hold(candidate.hold)

	if not cursor and not hold then return nil end
	return { cursor = cursor, hold = hold }
end

const function announce()
	for _, listener in table.clone(listeners) do
		listener()
	end
end

const function set(user: number, name: string, next_state: state?)
	if next_state then
		entries[user] = { user = user, name = name, cursor = next_state.cursor, hold = next_state.hold }
	else
		entries[user] = nil
	end

	announce()
end

const function publish(next_state: state?)
	if publisher then publisher(next_state) end
	const current = echo

	if not current then return end

	task.delay(current.delay, function()
		set(current.user, current.name, next_state)
	end)
end

const function connect_remote(handler: ((state: state?) -> ())?)
	publisher = handler
end

const function show_own(user: number, name: string, delay: number)
	echo = { user = user, name = name, delay = delay }
end

const function list()
	const result = {}

	for _, entry in entries do
		table.insert(result, entry)
	end

	table.sort(result, function(left, right)
		return left.user < right.user
	end)

	return result
end

const function on_change(listener: () -> ())
	table.insert(listeners, listener)

	return function()
		const index = table.find(listeners, listener)
		if index then table.remove(listeners, index) end
	end
end

const function reset()
	table.clear(entries)
	table.clear(listeners)

	publisher = nil
	echo = nil
end

--// End
return table.freeze {
	valid = valid,
	set = set,
	publish = publish,

	connect_remote = connect_remote,
	show_own = show_own,

	list = list,
	on_change = on_change,
	reset = reset,
}
