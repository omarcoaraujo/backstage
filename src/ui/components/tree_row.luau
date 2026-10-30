--// Packages
const vide = require "../../../roblox_packages/vide"

--// Stores
const appearance = require "../stores/appearance"

--// Utils
const branch_style = require "../constants/branch"
const flatten = require "../utils/flatten"
const pointer_target = require "../utils/pointer_target"
const px = require "../utils/px"
const theme = require "../constants/theme"

--// Types
type props = {
	row: () -> flatten.row,
	ticked: boolean,

	owner: string?,
	on_body: ((body: Frame) -> ())?,
	content: Instance,
}

--// Functions
const function trunk_x(level: number)
	return (level - 1) * theme.indent + branch_style.offset
end

const function trunk(row: () -> flatten.row, level: number)
	const function guide()
		return row().guides[level]
	end

	const function size()
		if guide() == "end" then return UDim2.new(0, 1, 0, px(theme.row_height / 2)()) end
		return UDim2.new(0, 1, 1, 0)
	end

	return vide.create "Frame" {
		Name = "trunk",
		Position = px.udim2(0, trunk_x(level), 0, 0),

		Size = size,
		BackgroundColor3 = appearance.divider,

		BackgroundTransparency = branch_style.transparency,
		BorderSizePixel = 0,

		Visible = function()
			return guide() ~= "none"
		end,
	}
end

const function tick(depth: number)
	return vide.create "Frame" {
		Name = "tick",
		AnchorPoint = Vector2.new(0, 0.5),

		Position = px.udim2(0, trunk_x(depth), 0, theme.row_height / 2),
		Size = px.udim2(0, theme.padding - branch_style.tick_gap - (branch_style.offset - theme.indent), 0, 1),
		BackgroundColor3 = appearance.divider,

		BackgroundTransparency = branch_style.transparency,
		BorderSizePixel = 0,
	}
end

--// Component
return function(props: props)
	const depth = props.row().depth
	const marks = {} :: { Instance }

	for level = 1, depth do
		table.insert(marks, trunk(props.row, level))
	end

	if props.ticked and depth > 0 then table.insert(marks, tick(depth)) end

	const body = vide.create "Frame" {
		Name = "body",
		Position = px.udim2(0, depth * theme.indent, 0, 0),
		Size = function()
			return UDim2.new(1, -px(depth * theme.indent)(), 1, 0)
		end,

		BackgroundTransparency = 1,
		props.content,
	}

	if props.owner then body:SetAttribute(pointer_target.owner_attribute, props.owner) end
	if props.on_body then props.on_body(body :: Frame) end

	return vide.create "Frame" {
		Name = "tree_row",
		BackgroundTransparency = 1,

		marks,
		body,
	}
end
