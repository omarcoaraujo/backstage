--// Modules
const bridge = require "./bridge"
const geometry = require "./geometry"
const mode = require "./mode"
const shortcut = require "./shortcut"

--// Constants
const DEFAULT_TITLE = "backstage"

--// Types
export type options = {
	title: string?,
	footer: string?,
	port: number?,

	key: Enum.KeyCode?,
	ctrl: boolean?,
	open: boolean?,

	vide: unknown?,
	charm: unknown?,
}

--// Functions
const function ignore() end

const function embed(parent: Instance, options: options?): () -> ()
	if not mode.active() then return ignore end

	const install = require "../reactive/install"
	install(options)

	const vide = require "../../roblox_packages/vide"
	const app = require "../ui/app"
	const version = require "../version"

	const title = if options and options.title then options.title else DEFAULT_TITLE
	const footer = if options and options.footer then options.footer else `v{version}`

	const saved = geometry.get(title)
	const visible = vide.source(not options or options.open ~= false)

	const function close()
		visible(false)
	end

	const function toggle()
		visible(not visible())
	end

	const function on_geometry(position: Vector2, size: Vector2)
		geometry.save(title, position, size)
	end

	bridge.serve(if options then options.port else nil)
	const listening = shortcut.listen(options, toggle)

	const destroy = vide.mount(function()
		return app {
			title = title,
			footer = footer,

			visible = visible,
			on_close = close,

			position = if saved then saved.position else nil,
			size = if saved then saved.size else nil,
			on_geometry = on_geometry,
		}
	end, parent)

	return function()
		listening:Disconnect()
		destroy()
		bridge.reset()
	end
end

--// End
return embed
