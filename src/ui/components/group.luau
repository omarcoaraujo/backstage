--// Packages
const vide = require "../../../roblox_packages/vide"

--// Utils
const filter = require "../utils/filter"
const overlay = require "../utils/overlay"
const px = require "../utils/px"
const theme = require "../utils/theme"

--// Constants
const BRANCH_TRANSPARENCY = 0.5
const BRANCH_OFFSET = 4
const TICK_REACH = 4

--// Types
type props = {
	name: string,
	open: boolean?,
	content: unknown?,
}

--// Functions
const function tick(child: Instance)
	const header = child:FindFirstChild "header"
	const parent = header or child
	const shift = if header then theme.padding else 0

	vide.create "Frame" {
		Name = "tick",
		Parent = parent,
		AnchorPoint = Vector2.new(0, 0.5),

		Position = px.udim2(0, BRANCH_OFFSET - theme.indent - shift, 0, theme.row_height / 2),
		Size = px.udim2(0, theme.indent - BRANCH_OFFSET + TICK_REACH, 0, 1),

		BackgroundColor3 = theme.divider,
		BackgroundTransparency = BRANCH_TRANSPARENCY,
		BorderSizePixel = 0,
	}
end

--// Component
return function(props: props)
	const node = filter.branch(props.name, props.content :: { Instance }?)
	const children = (props.content or {}) :: { Instance }
	local last = nil :: Instance?

	const open = vide.source(props.open ~= false)
	const hovered = vide.source(false)
	const last_height = vide.source(0)

	for _, child in children do
		if child.Name == "buttons" then continue end

		tick(child)
		last = child
	end

	if last and last:IsA "GuiObject" then
		const function update()
			last_height(last.AbsoluteSize.Y)
		end

		update()
		vide.cleanup(last:GetPropertyChangedSignal("AbsoluteSize"):Connect(update))
	end

	const function branch_size()
		return UDim2.new(0, 1, 1, -(last_height() - px(theme.row_height)() / 2))
	end

	const function expanded()
		return open() or filter.searching()
	end

	const function toggle()
		open(not open())
	end

	const function on_enter()
		hovered(true)
	end

	const function on_leave()
		hovered(false)
	end

	const function header_text()
		return `{if expanded() then "[-]" else "[+]"} {props.name}`
	end

	const function header_color()
		if overlay.active() then return theme.title_background end
		if hovered() then return theme.hover end
		return theme.title_background
	end

	const frame = vide.create "Frame" {
		Name = props.name,
		Visible = node.shown,
		Size = px.udim2(1, 0, 0, 0),

		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,

		vide.create "UIListLayout" {
			SortOrder = Enum.SortOrder.LayoutOrder,
		},

		vide.create "TextButton" {
			Name = "header",
			LayoutOrder = 1,

			Size = px.udim2(1, 0, 0, theme.row_height),
			AutoButtonColor = false,

			BackgroundColor3 = header_color,
			BorderSizePixel = 0,

			FontFace = theme.font,
			Text = header_text,
			TextColor3 = theme.text,

			TextSize = px(theme.text_size),
			TextXAlignment = Enum.TextXAlignment.Left,

			Activated = overlay.guard(toggle),
			MouseEnter = on_enter,
			MouseLeave = on_leave,

			vide.create "UIPadding" {
				PaddingLeft = px.udim(0, theme.padding),
			},
		},

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

				BackgroundColor3 = theme.divider,
				BackgroundTransparency = BRANCH_TRANSPARENCY,
				BorderSizePixel = 0,
			},

			vide.create "Frame" {
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

				props.content,
			},
		},
	}

	filter.track(frame, node)
	return frame
end
