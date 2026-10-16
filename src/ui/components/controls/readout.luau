--// Services
const RunService = game:GetService "RunService"

--// Packages
const vide = require "../../../../roblox_packages/vide"

--// Utils
const format = require "../../utils/format"
const px = require "../../utils/px"
const theme = require "../../utils/theme"

--// Constants
const PADDING = 4

--// Types
type props = {
	value: () -> unknown,
}

--// Component
return function(props: props)
	const text = vide.source(format.value(props.value()))
	const function on_step()
		text(format.value(props.value()))
	end

	vide.cleanup(RunService.Heartbeat:Connect(on_step))
	return vide.create "TextLabel" {
		Name = "readout",
		AnchorPoint = Vector2.new(0, 0.5),

		Position = UDim2.fromScale(0, 0.5),
		Size = px.udim2(1, 0, 0, theme.field_height),

		BackgroundTransparency = 1,
		FontFace = theme.font,

		Text = text,
		TextColor3 = theme.text_muted,
		TextSize = px(theme.text_size),

		TextTruncate = Enum.TextTruncate.AtEnd,
		TextXAlignment = Enum.TextXAlignment.Right,

		vide.create "UIPadding" {
			PaddingLeft = px.udim(0, PADDING),
			PaddingRight = px.udim(0, PADDING),
		},
	}
end
