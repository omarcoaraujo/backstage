--// Services
const Players = game:GetService "Players"
const ReplicatedStorage = game:GetService "ReplicatedStorage"
const RunService = game:GetService "RunService"

--// Modules
const backstage = require(ReplicatedStorage.backstage)
const data = require(ReplicatedStorage.data)

--// Constants
const ORBIT_SPEED = 1.5
const SWAY_SPEED = 3

--// Variables
const config = data.pets
local angle = 0

local pet = nil :: Part?
local trail = nil :: Trail?

--// Functions
const function get_root(): BasePart?
	const character = Players.LocalPlayer.Character
	return character and character:FindFirstChild "HumanoidRootPart"
end

const function resolve_stance()
	if config.mode == "orbit" then return config.stances.orbit end
	return config.stances.follow
end

const function resolve_target(root: BasePart, dt: number)
	const stance = resolve_stance()
	const sway = Vector3.yAxis * math.sin(os.clock() * SWAY_SPEED) * stance.sway

	if config.mode == "orbit" then
		angle += dt * ORBIT_SPEED
		return root.Position
			+ Vector3.new(math.cos(angle), 0, math.sin(angle)) * stance.distance
			+ Vector3.yAxis * stance.height
			+ sway
	end

	return root.Position - root.CFrame.LookVector * stance.distance + Vector3.yAxis * stance.height + sway
end

const function build_pet()
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

const function apply_size(size: number)
	if not pet then return end
	pet.Size = Vector3.one * size
end

const function apply_tint(tint: Color3)
	if not pet or not trail then return end
	pet.Color = tint
	trail.Color = ColorSequence.new(tint)
end

const function destroy()
	if pet then pet:Destroy() end
	pet = nil
	trail = nil
end

const function spawn_pet()
	destroy()
	pet = build_pet()

	apply_size(config.size)
	apply_tint(config.tint)
end

const function step(dt: number)
	const root = get_root()
	if not pet or not trail or not root then return end

	const alpha = math.min(resolve_stance().speed * dt, 1)
	pet.Position = pet.Position:Lerp(resolve_target(root, dt), alpha)

	trail.Enabled = config.trail.enabled
	trail.Lifetime = config.trail.length
end

--// Listeners
RunService.Heartbeat:Connect(step)
config.respawn:connect(spawn_pet)

backstage.on_change(config.size, apply_size)
backstage.on_change(config.tint, apply_tint)

--// End
return table.freeze {
	spawn = spawn_pet,
}
