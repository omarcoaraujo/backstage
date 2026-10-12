--// Modules
const button = require "@self/core/button"
const config = require "@self/core/config"
const kinds = require "@self/core/kinds"
const mode = require "@self/core/mode"
const start = require "@self/core/start"

--// Types
export type limit = kinds.limit
export type config_options<limits> = config.options<limits>
export type start_options = start.options

--// Functions
const function create_button()
	if not mode.active() then return button.create_inert() end
	return button.create()
end

--// End
return table.freeze {
	config = config,
	button = create_button,
	start = start,

	enable = mode.enable,
	disable = mode.disable,
}
