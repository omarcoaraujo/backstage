--// Services
const Players = game:GetService "Players"
const ReplicatedStorage = game:GetService "ReplicatedStorage"

--// Packages
const charm = require(ReplicatedStorage.roblox_packages.charm)

--// Modules
const backstage = require(ReplicatedStorage.backstage)
const pets = require(ReplicatedStorage.shared.pets_config)

--// Constants
const TOP_MARGIN = 16
const LINE_HEIGHT = 20
const WIDTH = 320

const TEXT_COLOR = Color3.fromRGB(220, 220, 225)
const MUTED_COLOR = Color3.fromRGB(150, 150, 160)
const FONT = Font.fromEnum(Enum.Font.GothamMedium)

--// Functions
const function line(name: string, order: number, color: Color3)
	const label = Instance.new "TextLabel"
	label.Name = name
	label.LayoutOrder = order

	label.Size = UDim2.new(1, 0, 0, LINE_HEIGHT)
	label.BackgroundTransparency = 1
	label.FontFace = FONT

	label.TextColor3 = color
	label.TextSize = 14

	return label
end

const function describe(value: unknown)
	if type(value) == "number" then return string.format("%.2f", value) end
	return tostring(value)
end

const function mount()
	const gui = Instance.new "ScreenGui"
	gui.Name = "pet_status"
	gui.ResetOnSpawn = false

	const holder = Instance.new "Frame"
	holder.Name = "holder"
	holder.AnchorPoint = Vector2.new(0.5, 0)

	holder.Position = UDim2.new(0.5, 0, 0, TOP_MARGIN)
	holder.Size = UDim2.fromOffset(WIDTH, LINE_HEIGHT * 2)
	holder.BackgroundTransparency = 1

	const layout = Instance.new "UIListLayout"
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = holder

	const current = line("current", 1, TEXT_COLOR)
	const last = line("last", 2, MUTED_COLOR)

	last.Text = "nothing changed yet"
	current.Parent = holder
	last.Parent = holder

	holder.Parent = gui
	gui.Parent = Players.LocalPlayer:WaitForChild "PlayerGui"

	charm.effect(function()
		current.Text = `{pets.mode}  size {describe(pets.size)}  trail {describe(pets.trail.length)}`
	end)

	backstage.on_any_change(function(path, value, previous)
		last.Text = `{path}  {describe(previous)} -> {describe(value)}`
	end)
end

--// End
return table.freeze {
	mount = mount,
}
