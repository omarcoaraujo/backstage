--// Utils
const filter = require "../utils/filter"

--// Components
const group = require "./group"
const readout = require "./controls/readout"
const row = require "./row"

--// Constants
const MAX_DEPTH = 8

--// Types
type props = {
	name: string,
	value: () -> { [unknown]: unknown },

	open: boolean?,
	depth: number?,
}

--// Functions
const function sorted_keys(source: { [unknown]: unknown }): { unknown }
	const keys = {}

	for key in source do
		table.insert(keys, key)
	end

	table.sort(keys, function(left, right)
		const left_text = tostring(left)
		const right_text = tostring(right)

		if left_text == right_text then return false end
		return left_text < right_text
	end)

	return keys
end

--// Component
const function tree(props: props)
	const depth = props.depth or 1
	const content = {}

	for _, key in sorted_keys(props.value()) do
		const label = tostring(key)

		const function child_value()
			return props.value()[key]
		end

		if type(child_value()) == "table" and depth < MAX_DEPTH then
			const function child_table()
				const current = child_value()
				if type(current) == "table" then return current :: { [unknown]: unknown } end
				return {}
			end

			table.insert(
				content,
				tree {
					name = label,
					value = child_table,
					depth = depth + 1,
				}
			)

			continue
		end

		table.insert(
			content,
			row {
				label = label,
				node = filter.leaf { label },
				content = readout { value = child_value },
			}
		)
	end

	return group { name = props.name, open = props.open, content = content }
end

--// End
return tree
