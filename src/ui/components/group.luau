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
const new_entry = require "./new_entry"

--// Constants
const BRANCH_TRANSPARENCY = branch_style.transparency
const BRANCH_OFFSET = branch_style.offset
const TICK_GAP = branch_style.tick_gap

--// Types
type props = {
	name: string,
	open: boolean?,

	on_toggle: ((open: boolean) -> ())?,
	content: unknown?,

	build: (() -> { Instance })?,

	dirty: (() -> boolean)?,
	on_reset: (() -> ())?,
	on_confirm: (() -> ())?,

	suggest: (() -> string)?,
	on_add: ((key: string) -> (boolean, string?))?,

	on_append: (() -> ())?,
	on_remove: (() -> ())?,
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
	const node = filter.branch(props.name, {}, {})
	const built = vide.source(false)

	const addable = props.on_add ~= nil or props.on_append ~= nil
	local destroy_built = nil :: (() -> ())?

	const open = vide.source(props.open == true)
	const closed_in_search = vide.source(false)

	const last_height = vide.source(0)
	const adding = vide.source(false)

	const function branch_size()
		return UDim2.new(0, 1, 1, -(last_height() - px(theme.row_height)() / 2))
	end

	const function expanded()
		if filter.searching() then return not closed_in_search() end
		return open()
	end

	const function toggle()
		if filter.searching() then
			closed_in_search(not closed_in_search())
			return
		end

		open(not open())
		if props.on_toggle then props.on_toggle(open()) end
	end

	const function on_add_pressed()
		open(true)

		if props.on_toggle then props.on_toggle(true) end
		if props.on_append then
			props.on_append()
			return
		end

		adding(not adding())
	end

	const function suggestion()
		if props.suggest then return props.suggest() end
		return ""
	end

	const function close_adding()
		adding(false)
	end

	const function add_entry(key: string)
		if not props.on_add then return false end
		return props.on_add(key)
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

		if props.on_add
			then new_entry {
				visible = adding,
				suggestion = suggestion,

				on_add = add_entry,
				on_close = close_adding,
			}
			else nil,
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
		filter.query()
		closed_in_search(false)
	end)

	vide.effect(function()
		const build = props.build
		if built() or not build or not expanded() or not node.shown() then return end

		built(true)
		destroy_built = vide.root(function()
			attach(build())
		end)
	end)

	const header = group_header {
		name = props.name,
		expanded = expanded,
		on_toggle = toggle,

		dirty = props.dirty,
		on_reset = props.on_reset,
		on_confirm = props.on_confirm,

		on_add = if addable then on_add_pressed else nil,
		adding = adding,
		on_remove = props.on_remove,
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

	vide.cleanup(function()
		if destroy_built then destroy_built() end
	end)

	header.LayoutOrder = 1
	filter.track(frame, node)

	return frame
end
