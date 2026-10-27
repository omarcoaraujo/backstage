--// Types
export type kind = "error" | "success" | "info"
type listener = (text: string, kind: kind, detail: string?) -> ()

--// Variables
const listeners = {} :: { listener }
local publisher = nil :: listener?

--// Functions
const function receive(text: string, sent: unknown?, detail: unknown?)
	const kind: kind = if sent == "error" then "error" elseif sent == "success" then "success" else "info"
	const extra = if type(detail) == "string" then detail else nil

	for _, notify in table.clone(listeners) do
		notify(text, kind, extra)
	end
end

const function show(text: string, kind: kind, detail: string?)
	receive(text, kind, detail)
	if not publisher then return end
	publisher(text, kind, detail)
end

const function connect_remote(handler: listener?)
	publisher = handler
end

const function on_notice(listener: listener)
	table.insert(listeners, listener)

	return function()
		const index = table.find(listeners, listener)
		if index then table.remove(listeners, index) end
	end
end

const function reset()
	table.clear(listeners)
	publisher = nil
end

--// End
return table.freeze {
	show = show,
	receive = receive,

	connect_remote = connect_remote,
	on_notice = on_notice,
	reset = reset,
}
