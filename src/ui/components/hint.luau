--// Packages
const vide = require "../../../roblox_packages/vide"

--// Utils
const overlay = require "../utils/overlay"
const pointer = require "../utils/pointer"

--// Components
const tooltip = require "./tooltip"

--// Constants
const HINT_DELAY = 0.5

--// Types
type props = {
	text: string?,
	anchor: () -> GuiObject?,
}

--// Component
return function(props: props)
	local pending = nil :: thread?
	local shown = nil :: Frame?

	local following = nil :: RBXScriptConnection?
	local visit = 0

	const function hide()
		visit += 1

		if following then
			following:Disconnect()
			following = nil
		end

		if pending then
			task.cancel(pending)
			pending = nil
		end

		if not shown then return end
		shown:Destroy()
		shown = nil
	end

	const function reveal(mine: number)
		pending = nil
		const anchor = props.anchor()

		if not anchor or not props.text or overlay.active() then return end
		const created = tooltip { anchor = anchor, text = props.text }

		if not created then return end
		if mine ~= visit then
			created:Destroy()
			return
		end

		shown = created
	end

	const function on_enter()
		const anchor = props.anchor()
		if not props.text or not anchor then return end
		hide()

		following = anchor:GetPropertyChangedSignal("AbsolutePosition"):Connect(hide)
		const mine = visit

		pending = task.delay(HINT_DELAY, function()
			reveal(mine)
		end)
	end

	const function on_input(input: InputObject)
		if pointer.is_press(input) then hide() end
	end

	vide.effect(function()
		if overlay.active() then hide() end
	end)

	vide.cleanup(hide)
	return { on_enter = on_enter, on_leave = hide, on_input = on_input }
end
