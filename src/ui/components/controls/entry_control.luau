--// Packages
const vide = require "../../../../roblox_packages/vide"

--// Modules
const kinds = require "../../../core/kinds"
const registry = require "../../../core/registry"

--// Components
const choice = require "./choice"
const color = require "./color"
const number = require "./number"
const text = require "./text"
const toggle = require "./toggle"
const vector3 = require "./vector3"

--// Types
export type bind = (path: string, apply: (value: kinds.value) -> ()) -> ()
type built = { content: unknown, value: () -> unknown }

type props = {
	entry: () -> registry.entry,
	active: () -> boolean,
	bind: bind,

	on_change: (value: unknown) -> (),
	locked: () -> boolean,
}

--// Functions
const function follow<T>(props: props, initial: T)
	const value = vide.source(initial)

	vide.effect(function()
		if not props.active() then return end
		const entry = props.entry()

		value(entry.value :: any)
		props.bind(entry.path, function(next_value)
			value(next_value :: any)
		end)
	end)

	return value
end

const function number_control(props: props): built
	const entry = props.entry()
	const value = follow(props, entry.value :: number)

	return {
		value = value,
		content = number {
			value = value,
			on_change = props.on_change,
			locked = props.locked,

			min = entry.descriptor.min,
			max = entry.descriptor.max,

			step = entry.descriptor.step,
			decimals = kinds.decimals(entry.descriptor),
		},
	}
end

const function toggle_control(props: props): built
	const value = follow(props, props.entry().value :: boolean)
	return { value = value, content = toggle { value = value, on_change = props.on_change, locked = props.locked } }
end

const function color_control(props: props): built
	const value = follow(props, props.entry().value :: Color3)
	return { value = value, content = color { value = value, on_change = props.on_change, locked = props.locked } }
end

const function vector3_control(props: props): built
	const value = follow(props, props.entry().value :: Vector3)
	return { value = value, content = vector3 { value = value, on_change = props.on_change, locked = props.locked } }
end

const function choice_control(props: props): built
	const value = follow(props, props.entry().value :: string)

	return {
		value = value,
		content = choice {
			value = value,
			on_change = props.on_change,

			choices = props.entry().descriptor.choices or {},
			locked = props.locked,
		},
	}
end

const function text_control(props: props): built
	const value = follow(props, props.entry().value :: string)
	return { value = value, content = text { value = value, on_change = props.on_change, locked = props.locked } }
end

--// Component
return function(props: props): built
	const kind = props.entry().descriptor.kind

	if kind == "number" then return number_control(props) end
	if kind == "boolean" then return toggle_control(props) end
	if kind == "color" then return color_control(props) end
	if kind == "vector3" then return vector3_control(props) end
	if kind == "choice" then return choice_control(props) end

	return text_control(props)
end
