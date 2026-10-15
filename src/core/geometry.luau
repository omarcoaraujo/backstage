--// Constants
const SHARED_KEY = "backstage_geometry"

--// Types
export type saved = {
	position: Vector2?,
	size: Vector2,
}

--// Functions
const function slot(): { [string]: saved }
	const slots = shared :: any
	const found = slots[SHARED_KEY]
	if found then return found end

	const created = {}
	slots[SHARED_KEY] = created
	return created
end

const function get(key: string): saved?
	return slot()[key]
end

const function save(key: string, position: Vector2?, size: Vector2)
	slot()[key] = { position = position, size = size }
end

const function reset()
	const slots = shared :: any
	slots[SHARED_KEY] = nil
end

--// End
return table.freeze { get = get, save = save, reset = reset }
