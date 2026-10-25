--// Packages
const vide = require "../../../roblox_packages/vide"

--// Variables
const active = {} :: { [GuiObject]: true }

--// Functions
const function mark(is_active: () -> boolean)
	return vide.action(function(instance)
		const element = instance :: GuiObject

		vide.effect(function()
			if is_active() then
				active[element] = true
			else
				active[element] = nil
			end
		end)

		vide.cleanup(function()
			active[element] = nil
		end)
	end)
end

const function current(): GuiObject?
	for element in active do
		if element.Parent then return element end
	end

	return nil
end

--// End
return table.freeze {
	mark = mark,
	current = current,
}
