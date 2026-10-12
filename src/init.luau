--// Modules
const button = require "@self/core/button"
const config = require "@self/core/config"
const kinds = require "@self/core/kinds"
const mode = require "@self/core/mode"

--// Types
export type limit = kinds.limit
export type options<limits> = config.options<limits>

--// Functions
const function create_button()
	if not mode.active() then return button.create_inert() end
	return button.create()
end

--// End
return table.freeze {
	config = config,
	button = create_button,

	enable = mode.enable,
	disable = mode.disable,
}
