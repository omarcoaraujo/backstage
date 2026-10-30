--// Packages
const vide = require "../../roblox_packages/vide"

--// Modules
const version = require "../version"

--// Components
const app = require "./app"

--// Constants
const DISPLAY_ORDER = 1000
const TITLE = "backstage"
const MAX_WINDOWS = 4

const CASCADE = Vector2.new(28, 28)
const FIRST_POSITION = Vector2.new(96, 96)

--// Types
export type handle = {
	toggle: () -> (),
	open_another: () -> (),

	count: () -> number,
	close_another: (index: number) -> (),
}

type extra = {
	destroy: () -> (),
	frame: Instance,
	position: Vector2,
}

--// Functions
const function create(player_gui: Instance): handle
	const visible = vide.source(false)
	const extras = {} :: { extra }

	local gui = nil :: ScreenGui?
	local top = 1

	const function layered(): (() -> number, () -> ())
		const layer = vide.source(top)

		const function focus()
			if layer() == top then return end

			top += 1
			layer(top)
		end

		return layer, focus
	end

	const function close()
		visible(false)
	end

	const function toggle()
		visible(not visible())
	end

	const function release(extra: extra)
		const position = table.find(extras, extra)
		if not position then return end

		table.remove(extras, position)
		extra.destroy()
		extra.frame:Destroy()
	end

	const function close_another(index: number)
		const extra = extras[index]
		if extra then release(extra) end
	end

	const function open_another()
		const parent = gui
		if not parent or #extras + 1 >= MAX_WINDOWS then return end

		const last = extras[#extras]
		const position = (if last then last.position else FIRST_POSITION) + CASCADE
		const layer, focus = layered()

		local extra = nil :: extra?
		local frame = nil :: Instance?

		const function close_extra()
			task.defer(function()
				if extra then release(extra) end
			end)
		end

		const destroy = vide.mount(function()
			const built = app {
				title = TITLE,
				visible = function()
					return true
				end,

				on_close = close_extra,
				cursors = true,
				toasts = false,

				position = position,
				layer = layer,
				on_focus = focus,
			}

			frame = built
			return built
		end, parent)

		const entry = { destroy = destroy, frame = assert(frame), position = position } :: extra
		extra = entry
		table.insert(extras, entry)
	end

	const function count()
		return 1 + #extras
	end

	const layer, focus = layered()
	vide.mount(function()
		const screen = vide.create "ScreenGui" {
			Name = "backstage",
			DisplayOrder = DISPLAY_ORDER,

			ResetOnSpawn = false,
			IgnoreGuiInset = true,
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling,

			app {
				title = TITLE,
				footer = `v{version}`,
				cursors = true,

				visible = visible,
				on_close = close,

				layer = layer,
				on_focus = focus,
			},
		}

		gui = screen :: ScreenGui
		return screen
	end, player_gui)

	return {
		toggle = toggle,
		open_another = open_another,

		count = count,
		close_another = close_another,
	}
end

--// End
return table.freeze {
	create = create,
}
