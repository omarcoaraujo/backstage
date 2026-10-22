--// Modules
const hud = require "./hud"
const pets = require "./pets"
const status = require "./status"

--// End
hud.mount()
status.mount()
pets.spawn()
