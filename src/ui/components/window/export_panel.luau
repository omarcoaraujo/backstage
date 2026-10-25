--// Packages
const vide = require "../../../../roblox_packages/vide"

--// Stores
const appearance = require "../../stores/appearance"

--// Utils
const px = require "../../utils/px"
const theme = require "../../constants/theme"

--// Constants
const EMPTY_TEXT = "nothing changed"

--// Types
type props = {
	visible: () -> boolean,
	text: () -> string,
	footer_height: number,
}

--// Component
return function(props: props)
	const function shown_text()
		const text = props.text()
		if text == "" then return EMPTY_TEXT end
		return text
	end

	const function select_all(box: TextBox)
		box.SelectionStart = 1
		box.CursorPosition = #box.Text + 1
	end

	return vide.create "Frame" {
		Name = "export_panel",
		Visible = props.visible,

		BackgroundColor3 = appearance.background,
		BorderSizePixel = 0,
		Active = true,

		Position = px.udim2(0, 0, 0, theme.title_height),
		Size = px.udim2(1, 0, 1, -theme.title_height - props.footer_height),

		vide.create "UIPadding" {
			PaddingLeft = px.udim(0, theme.padding),
			PaddingRight = px.udim(0, theme.padding),
			PaddingTop = px.udim(0, theme.padding),
			PaddingBottom = px.udim(0, theme.padding),
		},

		vide.create "TextBox" {
			Name = "text",
			Size = UDim2.fromScale(1, 1),

			BackgroundTransparency = 1,
			FontFace = theme.font,

			Text = shown_text,
			TextColor3 = appearance.text,
			TextSize = px(theme.text_size),

			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,

			MultiLine = true,
			TextEditable = false,
			ClearTextOnFocus = false,

			TextWrapped = false,
			Focused = select_all,
		},
	}
end
