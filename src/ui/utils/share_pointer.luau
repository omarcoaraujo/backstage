--// Services
const GuiService = game:GetService "GuiService"
const RunService = game:GetService "RunService"
const UserInputService = game:GetService "UserInputService"

--// Modules
const presence = require "../../core/presence"

--// Utils
const activity = require "./activity"
const pointer_target = require "./pointer_target"

--// Constants
const INTERVAL = 0.1
const MIN_X_STEP = 0.005
const MIN_Y_STEP = 1

--// Types
type reader = () -> presence.state?

--// Variables
const readers = {} :: { reader }
local connection = nil :: RBXScriptConnection?

local last = nil :: presence.state?
local elapsed = 0

--// Functions
const function same_cursor(left: presence.cursor?, right: presence.cursor?)
	if left == nil or right == nil then return left == right end
	if left.group ~= right.group or left.row ~= right.row then return false end
	return math.abs(left.x - right.x) < MIN_X_STEP and math.abs(left.y - right.y) < MIN_Y_STEP
end

const function same_hold(left: presence.hold?, right: presence.hold?)
	if left == nil or right == nil then return left == right end
	return left.owner == right.owner and table.concat(left.part, "/") == table.concat(right.part, "/")
end

const function same(left: presence.state?, right: presence.state?)
	if left == nil or right == nil then return left == right end
	return same_cursor(left.cursor, right.cursor) and same_hold(left.hold, right.hold)
end

const function combined(): presence.state?
	local cursor = nil :: presence.cursor?
	local hold = nil :: presence.hold?

	for _, read in readers do
		const state = read()
		if not state then continue end

		cursor = cursor or state.cursor
		hold = hold or state.hold
	end

	if not cursor and not hold then return nil end
	return { cursor = cursor, hold = hold }
end

const function poll(delta: number)
	elapsed += delta
	if elapsed < INTERVAL then return end
	elapsed = 0

	const current = combined()
	if same(current, last) then return end

	last = current
	presence.publish(current)
end

const function stop()
	if connection then connection:Disconnect() end
	connection = nil

	if last then presence.publish(nil) end
	last = nil
end

const function share_pointer(anchors: pointer_target.anchors, viewport: GuiObject, open: () -> boolean): () -> ()
	const function read(): presence.state?
		if not open() then return nil end

		const point = UserInputService:GetMouseLocation() - GuiService:GetGuiInset()
		const cursor = pointer_target.locate(anchors, viewport, point)

		const element = activity.current()
		const inside = element ~= nil and element:IsDescendantOf(viewport)
		const hold = if element and inside then pointer_target.describe(element) else nil

		if not cursor and not hold then return nil end
		return { cursor = cursor, hold = hold }
	end

	table.insert(readers, read)
	if not connection then connection = RunService.RenderStepped:Connect(poll) end

	return function()
		const position = table.find(readers, read)
		if position then table.remove(readers, position) end
		if #readers == 0 then stop() end
	end
end

--// End
return share_pointer
