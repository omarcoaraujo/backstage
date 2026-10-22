--// Services
const TextService = game:GetService "TextService"

--// Packages
const vide = require "../../../roblox_packages/vide"

--// Stores
const appearance = require "../stores/appearance"

--// Utils
const place = require "../utils/place"
const px = require "../utils/px"
const theme = require "../constants/theme"

--// Constants
const LAYER_Z_INDEX = 100000
const STROKE_TRANSPARENCY = 0.8

const MAX_WIDTH = 240
const PADDING = 6

const GAP = 8
const ARROW_SIZE = 8

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

const function text_label(anchor: GuiObject): (TextLabel | TextButton)?
	if anchor:IsA "TextButton" then return anchor end

	const label = anchor:FindFirstChild "label"
	if label and label:IsA "TextLabel" then return label end

	return nil
end

const function text_center(anchor: GuiObject): number
	const label = text_label(anchor)
	if not label then return anchor.AbsolutePosition.X + anchor.AbsoluteSize.X / 2 end

	const text_width = math.min(label.TextBounds.X, label.AbsoluteSize.X)
	if label.TextXAlignment == Enum.TextXAlignment.Left then return label.AbsolutePosition.X + text_width / 2 end
	return label.AbsolutePosition.X + label.AbsoluteSize.X / 2
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

	const spot = place(origin, props.anchor.AbsoluteSize, size.Y, px(GAP)(), bounds, true)
	const left = math.clamp(spot.X, 0, math.max(bounds.X - size.X, 0))

	const below = spot.Y >= origin.Y + props.anchor.AbsoluteSize.Y
	const above = spot.Y + size.Y <= origin.Y

	const arrow_size = px(ARROW_SIZE)()
	const outline = appearance.field():Lerp(appearance.stroke(), 1 - STROKE_TRANSPARENCY)

	const focus = text_center(props.anchor) - layer.AbsolutePosition.X - left
	const arrow_x = math.clamp(focus, arrow_size, size.X - arrow_size)
	const arrow_y = if below then 0 else size.Y

	const body = vide.create "Frame" {
		Name = "body",
		Size = UDim2.fromScale(1, 1),

		BackgroundColor3 = appearance.field(),
		BorderSizePixel = 0,
		ZIndex = 2,

		vide.create "UICorner" {
			CornerRadius = UDim.new(0, px(theme.radius)()),
		},

		vide.create "UIStroke" {
			Color = outline,

			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			LineJoinMode = Enum.LineJoinMode.Round,
			Thickness = px(1)(),
		},

		vide.create "TextLabel" {
			Name = "text",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,

			FontFace = theme.font,
			Text = props.text,

			TextColor3 = appearance.text(),
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

	const arrow = vide.create "Frame" {
		Name = "arrow",
		AnchorPoint = Vector2.new(0.5, 0.5),

		Position = UDim2.fromOffset(arrow_x, arrow_y),
		Size = UDim2.fromOffset(arrow_size, arrow_size),
		Rotation = 45,

		BackgroundColor3 = appearance.field(),
		BorderSizePixel = 0,
		Visible = below or above,
		ZIndex = 1,

		vide.create "UICorner" {
			CornerRadius = UDim.new(0, px(1)()),
		},

		vide.create "UIStroke" {
			Color = outline,

			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			LineJoinMode = Enum.LineJoinMode.Round,
			Thickness = px(1)(),
		},
	}

	const seam = vide.create "Frame" {
		Name = "seam",
		AnchorPoint = Vector2.new(0.5, 0.5),

		Position = UDim2.fromOffset(arrow_x, arrow_y),
		Size = UDim2.fromOffset(math.round(arrow_size * math.sqrt(2)), px(2)()),

		BackgroundColor3 = appearance.field(),
		BorderSizePixel = 0,
		Visible = below or above,
		ZIndex = 3,
	}

	return vide.create "Frame" {
		Name = "backstage_tooltip",
		Parent = layer,

		Position = UDim2.fromOffset(left, spot.Y),
		Size = UDim2.fromOffset(size.X, size.Y),

		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = LAYER_Z_INDEX,

		arrow,
		body,
		seam,
	}
end
