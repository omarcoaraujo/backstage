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

const function share_pointer(anchors: pointer_target.anchors, viewport: GuiObject, open: () -> boolean)
	local last = nil :: presence.state?
	local elapsed = 0

	const function read(): presence.state?
		if not open() then return nil end

		const point = UserInputService:GetMouseLocation() - GuiService:GetGuiInset()
		const cursor = pointer_target.locate(anchors, viewport, point)

		const element = activity.current()
		const hold = if element then pointer_target.describe(element) else nil

		if not cursor and not hold then return nil end
		return { cursor = cursor, hold = hold }
	end

	const function same(left: presence.state?, right: presence.state?)
		if left == nil or right == nil then return left == right end
		return same_cursor(left.cursor, right.cursor) and same_hold(left.hold, right.hold)
	end

	const function poll(delta: number)
		elapsed += delta
		if elapsed < INTERVAL then return end
		elapsed = 0

		const current = read()
		if same(current, last) then return end
		last = current

		presence.publish(current)
	end

	return RunService.RenderStepped:Connect(poll)
end

--// End
return share_pointer
