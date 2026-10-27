--// Packages
const vide = require "../../../roblox_packages/vide"

--// Constants
const PERIOD = 0.12
const DAMPING = 1

--// Functions
const function ease<T>(target: () -> T): () -> T
	const value = vide.spring(target, PERIOD, DAMPING)
	return value
end

const function fade(shown: () -> boolean)
	return ease(function()
		return if shown() then 0 else 1
	end)
end

--// End
return table.freeze {
	ease = ease,
	fade = fade,
}
