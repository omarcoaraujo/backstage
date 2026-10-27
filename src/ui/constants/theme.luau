--// End
return table.freeze {
	palettes = table.freeze {
		dark = table.freeze {
			background = Color3.fromRGB(17, 17, 19),
			field = Color3.fromRGB(26, 26, 30),
			hover = Color3.fromRGB(36, 36, 41),
			divider = Color3.fromRGB(44, 44, 50),

			accent = Color3.fromRGB(96, 165, 250),
			danger = Color3.fromRGB(248, 113, 113),
			danger_text = Color3.fromRGB(248, 113, 113),

			danger_muted = Color3.fromRGB(160, 84, 88),
			success_text = Color3.fromRGB(74, 222, 128),
			stroke = Color3.fromRGB(255, 255, 255),

			text = Color3.fromRGB(232, 232, 236),
			text_muted = Color3.fromRGB(128, 128, 138),
		},

		light = table.freeze {
			background = Color3.fromRGB(250, 250, 251),
			field = Color3.fromRGB(240, 240, 243),
			hover = Color3.fromRGB(229, 229, 234),
			divider = Color3.fromRGB(216, 216, 223),

			accent = Color3.fromRGB(37, 99, 235),
			danger = Color3.fromRGB(220, 38, 38),
			danger_text = Color3.fromRGB(190, 60, 60),

			danger_muted = Color3.fromRGB(200, 120, 120),
			success_text = Color3.fromRGB(22, 128, 61),
			stroke = Color3.fromRGB(0, 0, 0),

			text = Color3.fromRGB(24, 24, 27),
			text_muted = Color3.fromRGB(113, 113, 122),
		},
	},

	stroke_transparency = 0.9,
	stroke_hover_transparency = 0.8,
	stroke_focus_transparency = 0.15,

	font = Font.fromEnum(Enum.Font.RobotoMono),
	text_size = 14,

	title_height = 30,
	title_button = 20,
	title_inset = 5,

	logo_size = 16,
	logo_gap = 5,

	row_height = 26,
	search_height = 36,

	footer_height = 18,
	footer_text_size = 11,

	toast_width = 300,
	toast_logo = 16,

	toast_header_size = 13,
	toast_header_gap = 10,
	toast_title_size = 16,

	toast_detail_size = 13,
	toast_detail_mix = 0.6,

	field_height = 20,
	input_width = 56,

	reset_width = 18,
	action_width = 24,

	radius = 4,
	padding = 10,
	indent = 12,
	gap = 6,
}
