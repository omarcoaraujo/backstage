--// Services
const TextService = game:GetService "TextService"

--// Utils
const theme = require "../constants/theme"

--// Constants
const FALLBACK_LINE_HEIGHT = 1.3

--// Functions
const function measure_text(text: string, weight: Enum.FontWeight, size: number, width: number, rich: boolean?): number
	const params = Instance.new "GetTextBoundsParams"
	params.Text = text
	params.RichText = rich == true

	params.Font = Font.new(theme.font.Family, weight)
	params.Size = size
	params.Width = width

	const ok, bounds = pcall(TextService.GetTextBoundsAsync, TextService, params)
	if not ok then return math.ceil(size * FALLBACK_LINE_HEIGHT) end
	return math.ceil(bounds.Y)
end

--// End
return measure_text
