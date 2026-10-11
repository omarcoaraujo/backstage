--// Packages
const vide = require "../../../roblox_packages/vide"

--// Utils
const px = require "../utils/px"
const theme = require "../utils/theme"

--// Components
const button = require "./button"

--// Constants
const MAX_PER_ROW = 4

--// Types
export type item = { text: string, on_press: () -> () }
type props = { items: { item } }

--// Component
return function(props: props)
	const size = vide.source(Vector2.zero)
	const content = vide.source(Vector2.zero)
	const items = {} :: { Instance }

	const function container_size(): UDim2
		return UDim2.new(1, 0, 0, content().Y + px(theme.row_height - theme.field_height)())
	end

	const function inner_width(): number
		return size().X - px(theme.padding)() * 2
	end

	const function min_width(): number
		const gaps = px(theme.gap)() * (MAX_PER_ROW - 1)
		return math.max(0, math.floor((inner_width() - gaps) / MAX_PER_ROW))
	end

	const function max_width(): number
		return math.max(0, inner_width())
	end

	for _, current in props.items do
		table.insert(
			items,
			button {
				text = current.text,
				on_press = current.on_press,

				min_width = min_width,
				max_width = max_width,
			}
		)
	end

	return vide.create "Frame" {
		Name = "buttons",
		Size = container_size,
		BackgroundTransparency = 1,

		vide.create "UIListLayout" {
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,

			Wraps = true,
			Padding = px.udim(0, theme.gap),
			vide.changed("AbsoluteContentSize", content),
		},

		vide.create "UIPadding" {
			PaddingLeft = px.udim(0, theme.padding),
			PaddingRight = px.udim(0, theme.padding),

			PaddingTop = px.udim(0, (theme.row_height - theme.field_height) / 2),
			PaddingBottom = px.udim(0, (theme.row_height - theme.field_height) / 2),
		},

		items,
		vide.changed("AbsoluteSize", size),
	}
end
