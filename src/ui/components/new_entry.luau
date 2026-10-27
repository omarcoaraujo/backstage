--// Packages
const vide = require "../../../roblox_packages/vide"

--// Stores
const appearance = require "../stores/appearance"

--// Utils
const activity = require "../utils/activity"
const motion = require "../utils/motion"
const px = require "../utils/px"
const theme = require "../constants/theme"

--// Constants
const FALLBACK_HINT = "name"
const REFOCUS_DELAY = 0.1
const REASON_GAP = 12

--// Types
type props = {
	visible: () -> boolean,
	suggestion: () -> string,

	on_add: (key: string) -> (boolean, string?),
	on_close: () -> (),
}

--// Component
return function(props: props)
	local box = nil :: TextBox?
	const focused = vide.source(false)
	const reason = vide.source ""
	const typed_width = vide.source(0)

	const function capture(instance: Instance)
		box = instance :: TextBox
	end

	const function focus()
		task.delay(REFOCUS_DELAY, function()
			if box then box:CaptureFocus() end
		end)
	end

	const function clear_reason()
		reason ""
	end

	const function on_bounds(bounds: Vector2)
		typed_width(bounds.X)
	end

	const function refused()
		return reason() ~= ""
	end

	const function reason_position()
		return UDim2.fromOffset(typed_width() + px(REASON_GAP)(), 0)
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

		const typed = string.gsub(box.Text, "%s", "")
		const key = if typed ~= "" then typed else props.suggestion()
		const adding = entered and key ~= ""

		local added = true
		local message = nil :: string?

		if adding then
			added, message = props.on_add(key)
		end

		if not added then
			reason(message or "")
			focus()

			return
		end

		box.Text = ""
		props.on_close()
	end

	vide.effect(function()
		if props.visible() then focus() end
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
			vide.changed("Text", clear_reason),
			vide.changed("TextBounds", on_bounds),
			activity.mark(focused),

			vide.create "TextLabel" {
				Name = "reason",
				Position = reason_position,
				Size = UDim2.fromScale(1, 1),

				BackgroundTransparency = 1,
				FontFace = theme.font,
				Text = reason,

				TextColor3 = appearance.danger_text,
				TextTransparency = motion.fade(refused),
				TextSize = px(theme.text_size),

				TextXAlignment = Enum.TextXAlignment.Left,
				Visible = refused,
			},
		},
	}
end
