--// Packages
const vide = require "../../../roblox_packages/vide"

--// Modules
const kinds = require "../../core/kinds"
const registry = require "../../core/registry"

--// Types
export type bind = (path: string, apply: (value: kinds.value) -> ()) -> ()

export type props = {
	on_change: (path: string, value: kinds.value) -> (),
}

export type live = {
	revision: () -> number,
	bind: bind,

	dirty: () -> boolean,
	restore: () -> (),
	confirm: () -> (),
}

--// Functions
const function create(props: props): live
	const appliers = {} :: { [string]: (value: kinds.value) -> () }
	const revision = vide.source(0)

	const function bind(path: string, apply: (value: kinds.value) -> ())
		appliers[path] = apply
		vide.cleanup(function()
			if appliers[path] == apply then appliers[path] = nil end
		end)
	end

	const function on_value_changed(path: string, value: kinds.value)
		revision(revision() + 1)
		props.on_change(path, value)

		const apply = appliers[path]
		if apply then apply(value) end
	end

	const function dirty()
		revision()
		return registry.dirty()
	end

	const function restore()
		registry.restore_group()
	end

	const function confirm()
		registry.commit()
	end

	vide.cleanup(registry.on_change(on_value_changed))
	vide.cleanup(registry.on_commit(function()
		revision(revision() + 1)
	end))

	return {
		revision = revision,
		bind = bind,
		dirty = dirty,

		restore = restore,
		confirm = confirm,
	}
end

--// End
return table.freeze {
	create = create,
}
