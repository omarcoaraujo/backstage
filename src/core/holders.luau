--// Variables
const holder_of = {} :: { [string]: number }
const owned = {} :: { [number]: string }

--// Functions
const function release(user: number)
	const previous = owned[user]
	if not previous then return end

	owned[user] = nil
	if holder_of[previous] == user then holder_of[previous] = nil end
end

const function claim(user: number, owner: string?): boolean
	release(user)
	if not owner then return true end

	const current = holder_of[owner]
	if current and current ~= user then return false end

	holder_of[owner] = user
	owned[user] = owner

	return true
end

const function holder(owner: string): number?
	return holder_of[owner]
end

const function reset()
	table.clear(holder_of)
	table.clear(owned)
end

--// End
return table.freeze {
	claim = claim,
	release = release,

	holder = holder,
	reset = reset,
}
