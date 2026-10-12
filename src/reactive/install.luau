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
}

--// Variables
const vide_slot = {} :: slot
const charm_slot = {} :: slot

--// Functions
const function bundled_vide(): unknown
	return require "../../roblox_packages/vide"
end

const function bind(slot: slot, lib: unknown?, create: (lib: unknown) -> tracker.adapter)
	if lib == nil or slot.lib == lib then return end
	if slot.stop then slot.stop() end

	slot.lib = lib
	slot.stop = tracker.add(create(lib))
end

const function install(options: options?)
	const vide = if options then options.vide else nil
	bind(vide_slot, vide or vide_slot.lib or bundled_vide(), create_vide)

	const charm = if options then options.charm else nil
	bind(charm_slot, charm, create_charm)
end

--// End
return install
