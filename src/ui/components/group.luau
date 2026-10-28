--// Packages
const vide = require "../../../roblox_packages/vide"

--// Stores
const appearance = require "../stores/appearance"

--// Utils
const arrow = require "../constants/arrow"
const filter = require "../utils/filter"
const motion = require "../utils/motion"
const overlay = require "../utils/overlay"
const px = require "../utils/px"
const theme = require "../constants/theme"

--// Components
const confirm_button = require "./confirm_button"
const header_action = require "./header_action"
const new_entry = require "./new_entry"
const remove_button = require "./remove_button"
const reset_button = require "./reset_button"

--// Constants
const ADD_ICON = "rbxassetid://78158808810563"
const BRANCH_TRANSPARENCY = 0.5

const BRANCH_OFFSET = theme.padding + arrow.size / 2
const TICK_GAP = 2

--// Types
type props = {
	name: string,
	open: boolean?,

	on_toggle: ((open: boolean) -> ())?,
	content: unknown?,

	build: (() -> { Instance })?,
	descendants: { string }?,
	text_paths: { string }?,

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
	const node = filter.branch(props.name, props.descendants or {}, props.text_paths or {})
	const built = vide.source(false)

	const addable = props.on_add ~= nil or props.on_append ~= nil
	const actions = (if addable then 1 else 0) + (if props.on_remove then 1 else 0)
	local destroy_built = nil :: (() -> ())?

	const open = vide.source(props.open == true)
	const closed_in_search = vide.source(false)

	const hovered = vide.source(false)
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

	const function on_enter()
		hovered(true)
	end

	const function on_leave()
		hovered(false)
	end

	const function reset_visible()
		return hovered() and props.dirty ~= nil and props.dirty()
	end

	const function on_reset()
		if props.on_reset then props.on_reset() end
	end

	const function on_confirm()
		if props.on_confirm then props.on_confirm() end
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

	const function arrow_frame()
		return if expanded() then arrow.down else arrow.right
	end

	const function header_transparency()
		if overlay.active() then return 1 end
		if hovered() then return 0.4 end
		return 1
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

	const header = vide.create "TextButton" {
		Name = "header",
		LayoutOrder = 1,

		Size = px.udim2(1, 0, 0, theme.row_height),
		AutoButtonColor = false,

		BackgroundColor3 = appearance.hover,
		BackgroundTransparency = motion.ease(header_transparency),
		BorderSizePixel = 0,

		FontFace = theme.font,
		Text = props.name,
		TextColor3 = appearance.text,

		TextSize = px(theme.text_size),
		TextXAlignment = Enum.TextXAlignment.Left,

		Activated = overlay.guard(toggle),
		MouseEnter = on_enter,
		MouseLeave = on_leave,

		vide.create "UICorner" {
			CornerRadius = px.udim(0, theme.radius),
		},

		vide.create "UIPadding" {
			PaddingLeft = px.udim(0, theme.padding + arrow.size + arrow.gap),
		},

		vide.create "ImageLabel" {
			Name = "arrow",
			AnchorPoint = Vector2.new(0, 0.5),

			Position = px.udim2(0, -(arrow.size + arrow.gap), 0.5, 0),
			Size = px.udim2(0, arrow.size, 0, arrow.size),

			BackgroundTransparency = 1,
			Image = arrow.image,

			ImageColor3 = appearance.text,
			ImageRectSize = arrow.frame,
			ImageRectOffset = arrow_frame,
		},

		reset_button {
			right = theme.padding / 2 + theme.action_width * actions,
			visible = reset_visible,
			on_reset = on_reset,
		},

		confirm_button {
			right = theme.padding / 2 + theme.action_width * (actions + 1),
			visible = reset_visible,
			on_confirm = on_confirm,
		},

		if addable
			then header_action {
				name = "add",
				image = ADD_ICON,

				position = px.udim2(1, -theme.padding / 2, 0.5, 0),
				on_activated = on_add_pressed,

				highlighted = adding,
				shown = hovered,
			}
			else nil,

		if props.on_remove
			then remove_button {
				position = px.udim2(1, -(theme.padding / 2 + (if addable then theme.action_width else 0)), 0.5, 0),
				shown = hovered,
				on_remove = props.on_remove,
			}
			else nil,
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

	filter.track(frame, node)
	return frame
end
