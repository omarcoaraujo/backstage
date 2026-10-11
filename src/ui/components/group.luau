--// Packages
const vide = require "../../../roblox_packages/vide"

--// Utils
const px = require "../utils/px"
const theme = require "../utils/theme"

--// Types
type props = {
	name: string,
	open: boolean?,
	content: unknown?,
}

--// Component
return function(props: props)
	const open = vide.source(props.open ~= false)
	const hovered = vide.source(false)

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
		return `{if open() then "[-]" else "[+]"} {props.name}`
	end

	const function header_color()
		return if hovered() then theme.hover else theme.title_background
	end

	return vide.create "Frame" {
		Name = props.name,
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

			Activated = toggle,
			MouseEnter = on_enter,
			MouseLeave = on_leave,

			vide.create "UIPadding" {
				PaddingLeft = px.udim(0, theme.padding),
			},
		},

		vide.create "Frame" {
			Name = "content",
			LayoutOrder = 2,
			Size = px.udim2(1, 0, 0, 0),

			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Visible = open,

			vide.create "UIListLayout" {
				SortOrder = Enum.SortOrder.LayoutOrder,
			},

			vide.create "UIPadding" {
				PaddingLeft = px.udim(0, theme.indent),
			},

			props.content,
		},
	}
end
