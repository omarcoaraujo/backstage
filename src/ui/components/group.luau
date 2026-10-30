--// Packages
const vide = require "../../../roblox_packages/vide"

--// Stores
const appearance = require "../stores/appearance"

--// Utils
const arrow = require "../constants/arrow"
const branch_style = require "../constants/branch"
const filter = require "../utils/filter"
const px = require "../utils/px"
const theme = require "../constants/theme"

--// Components
const group_header = require "./group_header"

--// Constants
const BRANCH_TRANSPARENCY = branch_style.transparency
const BRANCH_OFFSET = branch_style.offset
const TICK_GAP = branch_style.tick_gap

--// Types
type props = {
	name: string,
	search: filter.instance,

	open: boolean?,
	content: unknown?,
}

--// Functions
const function tick(child: Instance)
	const header = child:FindFirstChild "header"
	const parent = header or child
	const shift = if header then theme.padding + arrow.size + arrow.gap else 0

	vide.create "Frame" {
		Name = "tick",
		Parent = parent,
		AnchorPoint = Vector2.new(0, 0.5),

		Position = px.udim2(0, BRANCH_OFFSET - theme.indent - shift, 0, theme.row_height / 2),
		Size = px.udim2(0, theme.padding - TICK_GAP - (BRANCH_OFFSET - theme.indent), 0, 1),

		BackgroundColor3 = appearance.divider,
		BackgroundTransparency = BRANCH_TRANSPARENCY,
		BorderSizePixel = 0,
	}
end

--// Component
return function(props: props)
	const node = props.search.branch(props.name, {}, {})

	const open = vide.source(props.open == true)
	const closed_in_search = vide.source(false)
	const last_height = vide.source(0)

	const function branch_size()
		return UDim2.new(0, 1, 1, -(last_height() - px(theme.row_height)() / 2))
	end

	const function expanded()
		if props.search.searching() then return not closed_in_search() end
		return open()
	end

	const function toggle()
		if props.search.searching() then
			closed_in_search(not closed_in_search())
			return
		end

		open(not open())
	end

	const content_frame = vide.create "Frame" {
		Name = "content",
		Size = px.udim2(1, 0, 0, 0),

		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,

		vide.create "UIListLayout" {
			SortOrder = Enum.SortOrder.LayoutOrder,
		},

		vide.create "UIPadding" {
			PaddingLeft = px.udim(0, theme.indent),
		},
	}

	const function attach(children: { Instance })
		local last = nil :: Instance?

		for _, child in children do
			child.Parent = content_frame
			if child.Name == "buttons" then continue end

			tick(child)
			last = child
		end

		if node.adopt then node.adopt(children) end
		if not last or not last:IsA "GuiObject" then return end

		const tail = last :: GuiObject
		const function update()
			last_height(tail.AbsoluteSize.Y)
		end

		update()
		vide.cleanup(tail:GetPropertyChangedSignal("AbsoluteSize"):Connect(update))
	end

	vide.effect(function()
		props.search.query()
		closed_in_search(false)
	end)

	const header = group_header {
		name = props.name,
		expanded = expanded,
		on_toggle = toggle,
	}

	const frame = vide.create "Frame" {
		Name = props.name,
		Visible = node.shown,
		Size = px.udim2(1, 0, 0, 0),

		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,

		vide.create "UIListLayout" {
			SortOrder = Enum.SortOrder.LayoutOrder,
		},

		header,
		vide.create "Frame" {
			Name = "body",
			LayoutOrder = 2,
			Size = px.udim2(1, 0, 0, 0),

			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Visible = expanded,

			vide.create "Frame" {
				Name = "branch",
				Position = px.udim2(0, BRANCH_OFFSET, 0, 0),
				Size = branch_size,

				BackgroundColor3 = appearance.divider,
				BackgroundTransparency = BRANCH_TRANSPARENCY,
				BorderSizePixel = 0,
			},

			content_frame,
		},
	}

	if props.content then attach(props.content :: { Instance }) end

	header.LayoutOrder = 1
	filter.track(frame, node)

	return frame
end
