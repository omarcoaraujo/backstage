--// Modules
const tracker = require "../core/tracker"
const create_charm = require "./charm"
const create_vide = require "./vide"

--// Types
export type options = {
	vide: unknown?,
	charm: unknown?,
}

type slot = {
	lib: unknown?,
	stop: (() -> ())?,
	tracked: boolean?,
}

--// Variables
const vide_slot = {} :: slot
const charm_slot = {} :: slot

--// Functions
const function bundled_vide(): unknown
	return require "../../roblox_packages/vide"
end

const function bind(slot: slot, name: string, lib: unknown?, create: (lib: unknown) -> tracker.adapter)
	if lib == nil or slot.lib == lib then return end
	if slot.lib ~= nil and slot.tracked then
		warn(
			`backstage: start replaced the {name} that already tracked config reads, so those reads will not update. Pass {name} to backstage.start before the first config is read`
		)
	end

	if slot.stop then slot.stop() end
	const adapter = create(lib)
	const read = adapter.read

	adapter.read = function(path, value)
		slot.tracked = true
		read(path, value)
	end

	slot.lib = lib
	slot.tracked = false
	slot.stop = tracker.add(adapter)
end

const function install(options: options?)
	const vide = if options then options.vide else nil
	bind(vide_slot, "vide", vide or vide_slot.lib or bundled_vide(), create_vide)

	const charm = if options then options.charm else nil
	bind(charm_slot, "charm", charm, create_charm)
end

--// End
return install
