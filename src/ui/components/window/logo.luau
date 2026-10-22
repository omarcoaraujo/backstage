--// Packages
const vide = require "../../../../roblox_packages/vide"

--// Utils
const px = require "../../utils/px"
const theme = require "../../constants/theme"

--// Constants
const ICON = "rbxassetid://99132688182977"

--// Component
return function()
	return vide.create "ImageLabel" {
		Name = "logo",
		Position = px.udim2(0, theme.padding, 0, (theme.title_height - theme.logo_size) / 2),

		Size = px.udim2(0, theme.logo_size, 0, theme.logo_size),
		BackgroundTransparency = 1,
		Image = ICON,
	}
end
