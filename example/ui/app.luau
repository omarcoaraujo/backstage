--// Components
const hud = require "./hud"
const status = require "./status"

--// Functions
const function mount()
	hud.mount()
	status.mount()
end

--// End
return table.freeze {
	mount = mount,
}
