--// Packages
const vide = require "../../../roblox_packages/vide"

--// Stores
const appearance = require "../stores/appearance"
const notices = require "../stores/notices"

--// Utils
const px = require "../utils/px"
const theme = require "../constants/theme"

--// Constants
const LAYER_Z_INDEX = 100000
const EXIT_DELAY = 0.5

const PERIOD = 0.3
const DAMPING = 1

--// Components
const logo = require "./window/logo"

--// Types
type line_props = {
	name: string,
	text: string,

	position: UDim2,
	size: UDim2,

	font_size: number,
	color: () -> Color3,
	weight: Enum.FontWeight,
}

--// Functions
const function title_color(kind: string)
	return function()
		if kind == "error" then return appearance.danger_text() end
		if kind == "success" then return appearance.success_text() end
		return appearance.text()
	end
end

const function line(props: line_props)
	return vide.create "TextLabel" {
		Name = props.name,
		Position = props.position,
		Size = props.size,

		BackgroundTransparency = 1,
		FontFace = Font.new(theme.font.Family, props.weight),
		Text = props.text,

		TextColor3 = props.color,
		TextSize = props.font_size,

		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
	}
end

const function build(toast: notices.toast, index: () -> number, present: () -> boolean)
	const width = px(theme.toast_width)()
	const padding = px(theme.padding)()
	const gap = px(theme.gap)()
	const stroke = px(1)()

	const logo_size = px(theme.toast_logo)()
	const indent = logo_size + px(theme.logo_gap)()
	const inner_width = width - padding * 2 - indent

	const detail_gap = if toast.detail then px(theme.gap / 2)() else 0
	const text_height = toast.title_height + detail_gap + toast.detail_height

	const body_height = math.max(logo_size, text_height)
	const height = padding * 2 + body_height
	const text_top = padding + math.floor((body_height - text_height) / 2)

	const shown = vide.spring(function()
		return if present() then 1 else 0
	end, PERIOD, DAMPING)

	const function hidden()
		return 1 - shown()
	end

	const function grown()
		return UDim2.fromOffset(math.round(width * shown()), height)
	end

	const function dismiss()
		notices.dismiss(toast)
	end

	const card = vide.create "CanvasGroup" {
		Name = "card",
		AnchorPoint = Vector2.new(1, 0),

		Position = UDim2.fromOffset(width + stroke, stroke),
		Size = grown,

		BackgroundColor3 = appearance.background,
		BorderSizePixel = 0,
		GroupTransparency = hidden,

		vide.create "UICorner" {
			CornerRadius = px.udim(0, theme.radius * 2),
		},

		vide.create "UIStroke" {
			Color = appearance.stroke,
			Transparency = theme.stroke_transparency,

			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			LineJoinMode = Enum.LineJoinMode.Round,
			Thickness = stroke,
		},

		logo {
			size = theme.toast_logo,
			position = px.udim2(0, theme.padding, 0.5, -theme.toast_logo / 2),
		},

		line {
			name = "title",
			text = toast.text,

			position = UDim2.fromOffset(padding + indent, text_top),
			size = UDim2.fromOffset(inner_width, toast.title_height),

			font_size = px(theme.toast_title_size)(),
			color = title_color(toast.kind),
			weight = Enum.FontWeight.SemiBold,
		},

		if toast.detail
			then line {
				name = "detail",
				text = toast.detail,

				position = UDim2.fromOffset(padding + indent, text_top + toast.title_height + detail_gap),
				size = UDim2.fromOffset(inner_width, toast.detail_height),

				font_size = px(theme.toast_detail_size)(),
				color = appearance.text,
				weight = Enum.FontWeight.Regular,
			}
			else nil,

		vide.create "TextButton" {
			Name = "dismiss",
			Size = UDim2.fromScale(1, 1),
			ZIndex = 2,

			BackgroundTransparency = 1,
			AutoButtonColor = false,
			Active = true,
			Text = "",

			Activated = dismiss,
		},
	}

	const frame = vide.create "Frame" {
		Name = "toast",
		LayoutOrder = index,

		Size = UDim2.fromOffset(width + stroke * 2, height + gap),
		BackgroundTransparency = 1,

		card,
	}

	return frame, EXIT_DELAY
end

--// Component
return function()
	const stack = vide.values(notices.toasts, build)

	return vide.create "Frame" {
		Name = "backstage_notifications",
		Size = UDim2.fromScale(1, 1),

		BackgroundTransparency = 1,
		Active = false,
		ZIndex = LAYER_Z_INDEX,

		vide.create "UIListLayout" {
			SortOrder = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			VerticalAlignment = Enum.VerticalAlignment.Bottom,
		},

		vide.create "UIPadding" {
			PaddingTop = px.udim(0, theme.gap),
			PaddingLeft = px.udim(0, theme.gap),
			PaddingRight = px.udim(0, theme.gap),
		},

		stack,
	}
end
