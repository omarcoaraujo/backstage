--// Modules
const button = require "@self/core/button"
const changes = require "@self/core/changes"
const config = require "@self/core/config"
const kinds = require "@self/core/kinds"
const mode = require "@self/core/mode"
const embed = require "@self/core/embed"
const on_change = require "@self/core/on_change"
const start = require "@self/core/start"

--// Types
export type value = kinds.value
export type limit = kinds.limit
export type change = changes.listener
export type config_options<limits> = config.options<limits>

export type start_options = start.options
export type embed_options = embed.options

--// Functions
const function create_config<settings, limits>(name: string, defaults: settings, options: config_options<limits>?): settings
	if mode.active() then
		const install = require "@self/reactive/install"
		install()
	end

	return config(name, defaults, options)
end

const function create_button()
	if not mode.active() then return button.create_inert() end
	return button.create()
end

--// End
return table.freeze {
	config = create_config,
	button = create_button,

	on_change = on_change,
	on_any_change = changes.any,

	start = start,
	embed = embed,

	enable = mode.enable,
	disable = mode.disable,
	allow = mode.allow,
}
