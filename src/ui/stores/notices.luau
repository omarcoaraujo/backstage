--// Packages
const vide = require "../../../roblox_packages/vide"

--// Modules
const notice = require "../../core/notice"

--// Utils
const measure_text = require "../utils/measure_text"
const px = require "../utils/px"
const theme = require "../constants/theme"

--// Constants
const DURATION = 8

--// Types
export type toast = {
	text: string,
	kind: notice.kind,
	detail: string?,

	title_height: number,
	detail_height: number,
}

--// Variables
const toasts = vide.source({} :: { toast })

--// Functions
const function dismiss(toast: toast)
	const index = table.find(toasts(), toast)
	if not index then return end

	const remaining = table.clone(toasts())
	table.remove(remaining, index)
	toasts(remaining)
end

const function text_width()
	return px(theme.toast_width - theme.padding * 2 - theme.toast_logo - theme.logo_gap)()
end

const function add(text: string, kind: notice.kind, detail: string?)
	for _, shown in toasts() do
		if shown.text == text and shown.kind == kind and shown.detail == detail then return end
	end

	const width = text_width()

	const toast = {
		text = text,
		kind = kind,
		detail = detail,

		title_height = measure_text(text, Enum.FontWeight.SemiBold, px(theme.toast_title_size)(), width),
		detail_height = if detail
			then measure_text(detail, Enum.FontWeight.Regular, px(theme.toast_detail_size)(), width)
			else 0,
	}

	const next = table.clone(toasts())
	table.insert(next, toast)
	toasts(next)

	task.delay(DURATION, function()
		dismiss(toast)
	end)
end

--// End
notice.on_notice(add)
return table.freeze {
	toasts = toasts,
	dismiss = dismiss,
}
