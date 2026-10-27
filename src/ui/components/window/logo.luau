--// Packages
const vide = require "../../../../roblox_packages/vide"

--// Utils
const px = require "../../utils/px"
const theme = require "../../constants/theme"

--// Constants
const ICON = "rbxassetid://99132688182977"

--// Types
type props = {
	position: (() -> UDim2)?,
	size: number?,
}

--// Component
return function(props: props?)
	const position = if props and props.position
		then props.position
		else px.udim2(0, theme.padding, 0, (theme.title_height - theme.logo_size) / 2)

	const size = if props and props.size then props.size else theme.logo_size

	return vide.create "ImageLabel" {
		Name = "logo",
		Position = position,

		Size = px.udim2(0, size, 0, size),
		BackgroundTransparency = 1,
		Image = ICON,
	}
end
