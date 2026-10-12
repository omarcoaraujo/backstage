--// Types
export type connection = {
	disconnect: () -> (),
}

export type button = {
	connect: (self: button, callback: () -> ()) -> connection,
	fire: (self: button) -> (),
}

--// Variables
const buttons = setmetatable({} :: { [unknown]: true }, { __mode = "k" })

--// Functions
const function create()
	const callbacks = {} :: { () -> () }

	const function connect(_: button, callback: () -> ()): connection
		table.insert(callbacks, callback)

		const function disconnect()
			const index = table.find(callbacks, callback)
			if index then table.remove(callbacks, index) end
		end

		return { disconnect = disconnect }
	end

	const function fire()
		for _, callback in table.clone(callbacks) do
			task.spawn(callback)
		end
	end

	const instance = { connect = connect, fire = fire }
	buttons[instance] = true

	return instance
end

const function create_inert(): button
	const function connect(_: button, _callback: () -> ())
		return { disconnect = function() end }
	end

	const function fire() end

	return { connect = connect, fire = fire }
end

const function is_button(value: unknown)
	return buttons[value] == true
end

--// End
return table.freeze {
	create = create,
	create_inert = create_inert,
	is_button = is_button,
}
