--// Services
const TextService = game:GetService "TextService"

--// Packages
const vide = require "../../../roblox_packages/vide"

--// Utils
const place = require "../utils/place"
const px = require "../utils/px"
const theme = require "../utils/theme"

--// Constants
const LAYER_Z_INDEX = 100000
const STROKE_TRANSPARENCY = 0.4

const MAX_WIDTH = 240
const PADDING = 6
const GAP = 4

--// Types
type props = {
	anchor: GuiObject,
	text: string,
}

--// Functions
const function measure(text: string, width: number): Vector2?
	const params = Instance.new "GetTextBoundsParams"
	params.Text = text

	params.Font = theme.font
	params.Size = px(theme.text_size)()
	params.Width = width

	const ok, bounds = pcall(TextService.GetTextBoundsAsync, TextService, params)
	if not ok then return nil end
	return bounds
end

--// Component
return function(props: props): Frame?
	const layer = props.anchor:FindFirstAncestorWhichIsA "LayerCollector"
	if not layer then return nil end

	const padding = px(PADDING)()
	const bounds = layer.AbsoluteSize

	const text_size = measure(props.text, px(MAX_WIDTH)() - padding * 2)
	if not text_size then return nil end

	const size = Vector2.new(math.ceil(text_size.X) + padding * 2, math.ceil(text_size.Y) + padding * 2)
	const origin = props.anchor.AbsolutePosition - layer.AbsolutePosition

	const spot = place(origin, props.anchor.AbsoluteSize, size.Y, px(GAP)(), bounds)
	const left = math.clamp(spot.X, 0, math.max(bounds.X - size.X, 0))

	return vide.create "Frame" {
		Name = "backstage_tooltip",
		Parent = layer,

		Position = UDim2.fromOffset(left, spot.Y),
		Size = UDim2.fromOffset(size.X, size.Y),

		BackgroundColor3 = theme.field,
		BorderSizePixel = 0,
		ZIndex = LAYER_Z_INDEX,

		vide.create "UIStroke" {
			Color = theme.stroke,
			Transparency = STROKE_TRANSPARENCY,

			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			LineJoinMode = Enum.LineJoinMode.Miter,
			Thickness = px(1)(),
		},

		vide.create "TextLabel" {
			Name = "text",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,

			FontFace = theme.font,
			Text = props.text,

			TextColor3 = theme.text,
			TextSize = px(theme.text_size)(),

			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,

			vide.create "UIPadding" {
				PaddingTop = UDim.new(0, padding),
				PaddingBottom = UDim.new(0, padding),

				PaddingLeft = UDim.new(0, padding),
				PaddingRight = UDim.new(0, padding),
			},
		},
	}
end
