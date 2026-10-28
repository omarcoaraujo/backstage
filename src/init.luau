--// Modules
const button = require "@self/core/button"
const changes = require "@self/core/changes"
const config = require "@self/core/config"
const each = require "@self/core/each"
const embed = require "@self/core/embed"
const kinds = require "@self/core/kinds"
const mode = require "@self/core/mode"
const on_change = require "@self/core/on_change"
const start = require "@self/core/start"
const union = require "@self/core/union"

--// Types
export type value = kinds.value
export type limit = kinds.limit
export type change = changes.listener
export type config_options<limits, hints = { [string]: any }> = config.options<limits, hints>

export type start_options = start.options
export type embed_options = embed.options

--// Functions
const function create_config<settings, limits, hints>(name: string, defaults: settings, options: config_options<limits, hints>?): settings
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
	union = union.create,

	button = create_button,
	each = each.create,

	on_change = on_change,
	on_any_change = changes.any,

	start = start,
	embed = embed,

	enable = mode.enable,
	disable = mode.disable,
}
