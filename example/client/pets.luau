--// Services
const Players = game:GetService "Players"
const ReplicatedStorage = game:GetService "ReplicatedStorage"
const RunService = game:GetService "RunService"

--// Modules
const config = require(ReplicatedStorage.shared.pets_config)

--// Constants
const ORBIT_SPEED = 1.5

--// Variables
local pet = nil :: Part?
local trail = nil :: Trail?
local angle = 0

--// Functions
const function get_root(): BasePart?
	const character = Players.LocalPlayer.Character
	return character and character:FindFirstChild "HumanoidRootPart" :: BasePart?
end

const function resolve_target(root: BasePart, dt: number): Vector3
	if config.mode == "orbit" then
		angle += dt * ORBIT_SPEED
		return root.Position
			+ Vector3.new(math.cos(angle), 0, math.sin(angle)) * config.distance
			+ Vector3.yAxis * config.height
	end

	return root.Position - root.CFrame.LookVector * config.distance + Vector3.yAxis * config.height
end

const function build_pet(): Part
	const part = Instance.new "Part"
	part.Name = "pet"
	part.Shape = Enum.PartType.Ball
	part.Anchored = true
	part.CanCollide = false
	part.Material = Enum.Material.Neon
	part.Parent = workspace

	const first = Instance.new "Attachment"
	first.Position = Vector3.new(0, 0.5, 0)
	first.Parent = part

	const second = Instance.new "Attachment"
	second.Position = Vector3.new(0, -0.5, 0)
	second.Parent = part

	const created = Instance.new "Trail"
	created.Attachment0 = first
	created.Attachment1 = second
	created.Parent = part

	trail = created

	return part
end

const function destroy()
	if pet then pet:Destroy() end

	pet = nil
	trail = nil
end

const function spawn_pet()
	destroy()
	pet = build_pet()
end

const function step(dt: number)
	const root = get_root()
	if not pet or not trail or not root then return end

	const alpha = math.min(config.speed * dt, 1)

	pet.Size = Vector3.one * config.size
	pet.Color = config.tint
	pet.Position = pet.Position:Lerp(resolve_target(root, dt), alpha)
	trail.Enabled = config.trail.enabled
	trail.Lifetime = config.trail.length
	trail.Color = ColorSequence.new(config.tint)
end

--// Listeners
RunService.Heartbeat:Connect(step)
config.respawn:connect(spawn_pet)

--// End
return table.freeze {
	spawn = spawn_pet,
}
