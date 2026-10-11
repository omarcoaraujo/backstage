--// Packages
const vide = require "../../../roblox_packages/vide"

--// Constants
const BASE_HEIGHT = 1080
const MAX_SCALE = 3

--// Variables
const camera = workspace.CurrentCamera :: Camera
const current_scale = vide.source(1)

--// Functions
const function use_px()
	const function on_viewport_changed()
		current_scale(math.clamp(camera.ViewportSize.Y / BASE_HEIGHT, 1, MAX_SCALE))
	end

	vide.cleanup(camera:GetPropertyChangedSignal("ViewportSize"):Connect(on_viewport_changed))
	on_viewport_changed()
end

const function px(value: number)
	return function()
		return math.round(value * current_scale())
	end
end

const function udim(scale: number, offset: number)
	return function()
		return UDim.new(scale, px(offset)())
	end
end

const function udim2(x_scale: number, x_offset: number, y_scale: number, y_offset: number)
	return function()
		return UDim2.new(x_scale, px(x_offset)(), y_scale, px(y_offset)())
	end
end

const function call(_: unknown, value: number)
	return px(value)
end

--// End
return setmetatable({
	use_px = use_px,
	scale = current_scale,

	udim = udim,
	udim2 = udim2,
}, {
	__call = call,
})
