--// Services
const Players = game:GetService "Players"
const ReplicatedStorage = game:GetService "ReplicatedStorage"

--// Packages
const vide = require(ReplicatedStorage.roblox_packages.vide)

--// Modules
const data = require(ReplicatedStorage.data)

--// Constants
const CARD_WIDTH = 190
const MARGIN = 16

const PADDING = 12
const ROW_HEIGHT = 20
const SWATCH_SIZE = 16

const CARD_COLOR = Color3.fromRGB(24, 24, 28)
const TEXT_COLOR = Color3.fromRGB(220, 220, 225)
const FONT = Font.fromEnum(Enum.Font.GothamMedium)

const CORNERS = {
	top_left = { anchor = Vector2.new(0, 0), position = UDim2.new(0, MARGIN, 0, MARGIN) },
	top_right = { anchor = Vector2.new(1, 0), position = UDim2.new(1, -MARGIN, 0, MARGIN) },

	bottom_left = { anchor = Vector2.new(0, 1), position = UDim2.new(0, MARGIN, 1, -MARGIN) },
	bottom_right = { anchor = Vector2.new(1, 1), position = UDim2.new(1, -MARGIN, 1, -MARGIN) },
} :: { [string]: { anchor: Vector2, position: UDim2 } }

--// Variables
const pets = data.pets
const hud = data.hud

--// Functions
const function trail_text()
	if not pets.trail.enabled then return "off" end
	return string.format("%.1fs", pets.trail.length)
end

const function row(label: string, order: number, value: () -> string)
	return vide.create "TextLabel" {
		Name = label,
		LayoutOrder = order,
		Size = UDim2.new(1, 0, 0, ROW_HEIGHT),

		BackgroundTransparency = 1,
		FontFace = FONT,

		Text = function()
			return `{label}  {value()}`
		end,

		TextColor3 = TEXT_COLOR,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
	}
end

const function header()
	return vide.create "Frame" {
		Name = "header",
		LayoutOrder = 1,

		Size = UDim2.new(1, 0, 0, ROW_HEIGHT),
		BackgroundTransparency = 1,

		vide.create "UIListLayout" {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 8),
			VerticalAlignment = Enum.VerticalAlignment.Center,
		},

		vide.create "Frame" {
			Name = "swatch",
			Size = UDim2.fromOffset(SWATCH_SIZE, SWATCH_SIZE),

			BackgroundColor3 = function()
				return pets.tint
			end,

			vide.create "UICorner" {
				CornerRadius = UDim.new(1, 0),
			},
		},

		vide.create "TextLabel" {
			Name = "title",
			Size = UDim2.fromOffset(0, ROW_HEIGHT),

			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundTransparency = 1,
			FontFace = FONT,

			Text = function()
				return hud.title
			end,

			TextColor3 = function()
				return hud.accent
			end,

			TextSize = 16,
		},
	}
end

const function stats()
	return vide.create "Frame" {
		Name = "stats",
		LayoutOrder = 2,

		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,

		Visible = function()
			return hud.show_stats
		end,

		vide.create "UIListLayout" {
			SortOrder = Enum.SortOrder.LayoutOrder,
		},

		row("mode", 1, function()
			return pets.mode
		end),

		row("size", 2, function()
			return string.format("%.1f", pets.size)
		end),

		row("trail", 3, trail_text),
	}
end

const function card()
	return vide.create "Frame" {
		Name = "card",

		AnchorPoint = function()
			return CORNERS[hud.corner].anchor
		end,

		Position = function()
			return CORNERS[hud.corner].position
		end,

		Size = UDim2.fromOffset(CARD_WIDTH, 0),
		AutomaticSize = Enum.AutomaticSize.Y,

		BackgroundColor3 = CARD_COLOR,
		BackgroundTransparency = function()
			return hud.fade
		end,

		Visible = function()
			return hud.enabled
		end,

		vide.create "UICorner" {
			CornerRadius = UDim.new(0, 8),
		},

		vide.create "UIStroke" {
			Thickness = 2,

			Color = function()
				return hud.accent
			end,
		},

		vide.create "UIScale" {
			Scale = function()
				return hud.scale
			end,
		},

		vide.create "UIPadding" {
			PaddingTop = UDim.new(0, PADDING),
			PaddingBottom = UDim.new(0, PADDING),

			PaddingLeft = UDim.new(0, PADDING),
			PaddingRight = UDim.new(0, PADDING),
		},

		vide.create "UIListLayout" {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 4),
		},

		header(),
		stats(),
	}
end

const function mount()
	return vide.mount(function()
		return vide.create "ScreenGui" {
			Name = "pet_hud",
			ResetOnSpawn = false,
			card(),
		}
	end, Players.LocalPlayer:WaitForChild "PlayerGui")
end

--// End
return table.freeze {
	mount = mount,
}
