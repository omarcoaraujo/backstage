--// Packages
const vide = require "../../../roblox_packages/vide"

--// Utils
const px = require "../utils/px"
const theme = require "../utils/theme"

--// Constants
const SCROLLBAR_THICKNESS = 4

--// Types
type props = {
	content: unknown?,
}

--// Component
return function(props: props)
	return vide.create "ScrollingFrame" {
		Name = "list",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,

		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.fromScale(0, 0),
		ScrollingDirection = Enum.ScrollingDirection.Y,

		ScrollBarImageColor3 = theme.divider,
		ScrollBarThickness = px(SCROLLBAR_THICKNESS),
		VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar,

		vide.create "UIListLayout" {
			SortOrder = Enum.SortOrder.LayoutOrder,
		},

		props.content,
	}
end
