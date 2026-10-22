--// Services
const ReplicatedStorage = game:GetService "ReplicatedStorage"
const RunService = game:GetService "RunService"

--// Modules
const backstage = require(ReplicatedStorage.backstage)
const config = require(ReplicatedStorage.shared.pets_config)

--// Constants
const CAMERA_POSITION = Vector3.new(0, 14, 22)
const OWNER_RADIUS = 8
const OWNER_SPEED = 0.6

const ORBIT_SPEED = 1.5
const SWAY_SPEED = 3

--// Functions
const function build_part(shape: Enum.PartType, parent: Instance): Part
	const part = Instance.new "Part"
	part.Shape = shape
	part.Anchored = true

	part.CanCollide = false
	part.Material = Enum.Material.Neon
	part.Parent = parent

	return part
end

const function resolve_stance()
	if config.mode == "orbit" then return config.stances.orbit end
	return config.stances.follow
end

const function resolve_goal(position: Vector3, forward: Vector3, angle: number): Vector3
	const stance = resolve_stance()
	const sway = Vector3.yAxis * math.sin(os.clock() * SWAY_SPEED) * stance.sway

	if config.mode == "orbit" then
		return position
			+ Vector3.new(math.cos(angle), 0, math.sin(angle)) * stance.distance
			+ Vector3.yAxis * stance.height
			+ sway
	end

	return position - forward * stance.distance + Vector3.yAxis * stance.height + sway
end

const function build_world(target: Instance): (ViewportFrame, Part, Part)
	const world = Instance.new "ViewportFrame"
	world.Size = UDim2.fromScale(1, 1)
	world.BackgroundColor3 = Color3.fromRGB(24, 26, 32)

	const camera = Instance.new "Camera"
	camera.CFrame = CFrame.lookAt(CAMERA_POSITION, Vector3.zero)
	camera.Parent = world

	world.CurrentCamera = camera
	world.Parent = target

	const owner = build_part(Enum.PartType.Block, world)
	owner.Size = Vector3.new(2, 4, 2)
	owner.Color = Color3.fromRGB(120, 130, 150)

	return world, owner, build_part(Enum.PartType.Ball, world)
end

--// Story
return function(target: Instance)
	const world, owner, pet = build_world(target)

	local time = 0
	local angle = 0

	const function apply_size(size: number)
		pet.Size = Vector3.one * size
	end

	const function apply_tint(tint: Color3)
		pet.Color = tint
	end

	const function respawn()
		pet.Position = owner.Position
	end

	const function step(dt: number)
		time += dt
		angle += dt * ORBIT_SPEED

		const around = time * OWNER_SPEED
		const position = Vector3.new(math.cos(around), 0, math.sin(around)) * OWNER_RADIUS
		const forward = Vector3.new(-math.sin(around), 0, math.cos(around))

		owner.CFrame = CFrame.lookAt(position, position + forward)
		pet.Position =
			pet.Position:Lerp(resolve_goal(position, forward, angle), math.min(resolve_stance().speed * dt, 1))
	end

	apply_size(config.size)
	apply_tint(config.tint)
	respawn()

	const heartbeat = RunService.Heartbeat:Connect(step)
	const respawn_button = config.respawn:connect(respawn)

	const stop_size = backstage.on_change(config.size, apply_size)
	const stop_tint = backstage.on_change(config.tint, apply_tint)
	const stop_panel = backstage.embed(target)

	return function()
		stop_panel()
		stop_tint()
		stop_size()

		respawn_button.disconnect()
		heartbeat:Disconnect()
		world:Destroy()
	end
end
