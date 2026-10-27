--// Packages
const vide = require "../../../roblox_packages/vide"

--// Stores
const appearance = require "../stores/appearance"

--// Utils
const activity = require "../utils/activity"
const px = require "../utils/px"
const theme = require "../constants/theme"

--// Constants
const FALLBACK_HINT = "name"

--// Types
type props = {
	visible: () -> boolean,
	suggestion: () -> string,

	on_add: (key: string) -> boolean,
	on_close: () -> (),
}

--// Component
return function(props: props)
	local box = nil :: TextBox?
	const focused = vide.source(false)

	const function capture(instance: Instance)
		box = instance :: TextBox
	end

	const function placeholder()
		const suggestion = props.suggestion()
		return if suggestion == "" then FALLBACK_HINT else suggestion
	end

	const function on_focused()
		focused(true)
	end

	const function on_focus_lost(entered: boolean)
		focused(false)
		if not box then return end

		const typed = box.Text
		const key = if typed ~= "" then typed else props.suggestion()
		if entered and key ~= "" and not props.on_add(key) then return end

		box.Text = ""
		props.on_close()
	end

	vide.effect(function()
		if not props.visible() then return end

		task.defer(function()
			if box then box:CaptureFocus() end
		end)
	end)

	return vide.create "Frame" {
		Name = "new_entry",
		LayoutOrder = -1,

		Size = px.udim2(1, 0, 0, theme.row_height),
		BackgroundTransparency = 1,
		Visible = props.visible,

		vide.create "TextBox" {
			Name = "field",
			Position = px.udim2(0, theme.padding, 0, 0),
			Size = px.udim2(1, -theme.padding * 2, 1, 0),

			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ClipsDescendants = true,

			ClearTextOnFocus = false,
			FontFace = theme.font,
			Text = "",

			PlaceholderText = placeholder,
			PlaceholderColor3 = appearance.text_muted,
			TextColor3 = appearance.text,

			TextSize = px(theme.text_size),
			TextXAlignment = Enum.TextXAlignment.Left,

			Focused = on_focused,
			FocusLost = on_focus_lost,

			vide.action(capture),
			activity.mark(focused),
		},
	}
end
