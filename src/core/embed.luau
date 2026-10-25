--// Modules
const baseline = require "./baseline"
const bridge = require "./bridge"
const geometry = require "./geometry"
const kinds = require "./kinds"
const mode = require "./mode"
const registry = require "./registry"
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
	const vide = require "../../roblox_packages/vide"
	const app = require "../ui/app"
	const version = require "../version"

	const title = if options and options.title then options.title else DEFAULT_TITLE
	const footer = if options and options.footer then options.footer else `v{version}`
	const saved = geometry.get(title)

	const visible = vide.source(not options or options.open ~= false)
	const settled = {} :: { [string]: true }

	const function close()
		visible(false)
	end

	const function toggle()
		visible(not visible())
	end

	const function on_geometry(position: Vector2, size: Vector2)
		geometry.save(title, position, size)
	end

	const function keep_baseline()
		for _, entry in registry.list() do
			if settled[entry.path] then continue end
			settled[entry.path] = true
			registry.rebase(entry.path, baseline.resolve(entry.path, entry.default, kinds.decimals(entry.descriptor)))
		end
	end

	const function remember_edit(path: string, value: kinds.value)
		if registry.get_default(path) == value then
			baseline.forget(path)
			return
		end

		baseline.remember(path, value)
	end

	install(options)
	keep_baseline()

	const stop_rebasing = registry.on_register(keep_baseline)
	const stop_remembering = registry.on_change(remember_edit)

	bridge.serve(if options then options.port else nil, { hold = true, keep = true })
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
		stop_remembering()
		stop_rebasing()

		destroy()
		bridge.finish()
	end
end

--// End
return embed
