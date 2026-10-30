--// Modules
const presence = require "../../core/presence"

--// Utils
const px = require "./px"
const row_space = require "./row_space"

--// Constants
const OWNER_ATTRIBUTE = "backstage_owner"

--// Types
type row = {
	frame: GuiObject,
	group: string,
}

export type canvas = {
	space: row_space.space,
	position: Vector2,
	width: number,
}

export type anchors = {
	rows: { [string]: row },
	groups: { [string]: GuiObject },
	canvas: () -> canvas?,
}

--// Functions
const function visible(frame: GuiObject)
	local current = frame :: Instance?

	while current and not current:IsA "ScreenGui" do
		if current:IsA "GuiObject" and not current.Visible then return false end
		current = current.Parent
	end

	return current ~= nil
end

const function inside(frame: GuiObject, point: Vector2)
	const position, size = frame.AbsolutePosition, frame.AbsoluteSize
	return point.X >= position.X
		and point.Y >= position.Y
		and point.X < position.X + size.X
		and point.Y < position.Y + size.Y
end

const function locate(anchors: anchors, viewport: GuiObject, point: Vector2): presence.cursor?
	if not inside(viewport, point) then return nil end

	const canvas = anchors.canvas()
	if not canvas then return nil end

	const hit = canvas.space.hit(point.Y - canvas.position.Y)
	if not hit then return nil end

	return {
		group = hit.group,
		row = hit.row,

		x = (point.X - canvas.position.X) / math.max(canvas.width, 1),
		y = (point.Y - canvas.position.Y - hit.top) / px.scale(),
	}
end

const function nearest_group(anchors: anchors, path: string): GuiObject?
	local current = path :: string?

	while current do
		const frame = anchors.groups[current]
		if frame and visible(frame) then return frame end
		current = string.match(current, "^(.*)%.[^%.]+$")
	end

	return nil
end

const function place(anchors: anchors, cursor: presence.cursor): Vector2?
	const canvas = anchors.canvas()
	if not canvas then return nil end

	const row_top = if cursor.row then canvas.space.top_of_row(cursor.row) else nil
	const top = row_top or canvas.space.nearest_group_top(cursor.group)

	if not top then return nil end
	return Vector2.new(canvas.position.X + cursor.x * canvas.width, canvas.position.Y + top + cursor.y * px.scale())
end

const function describe(element: GuiObject): presence.hold?
	const names = {}
	local current = element :: Instance?

	while current do
		const owner = current:GetAttribute(OWNER_ATTRIBUTE)

		if type(owner) == "string" then
			const part = {}

			for index = #names, 1, -1 do
				table.insert(part, names[index])
			end

			return { owner = owner, part = part }
		end

		table.insert(names, current.Name)
		current = current.Parent
	end

	return nil
end

const function resolve(anchors: anchors, hold: presence.hold): GuiObject?
	const row = anchors.rows[hold.owner]
	if not row and not anchors.groups[hold.owner] then return nearest_group(anchors, hold.owner) end
	local current = (if row then row.frame else anchors.groups[hold.owner]) :: Instance?

	for _, name in hold.part do
		if not current then return nil end
		current = current:FindFirstChild(name)
	end

	if not current or not current:IsA "GuiObject" or not visible(current) then return nil end
	return current
end

--// End
return table.freeze {
	locate = locate,
	place = place,

	describe = describe,
	resolve = resolve,

	inside = inside,
	visible = visible,
	owner_attribute = OWNER_ATTRIBUTE,
}
