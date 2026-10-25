--// Modules
const presence = require "../../core/presence"

--// Utils
const px = require "./px"

--// Constants
const OWNER_ATTRIBUTE = "backstage_owner"

--// Types
type row = { frame: GuiObject, group: string }

export type anchors = {
	rows: { [string]: row },
	groups: { [string]: GuiObject },
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

const function depth(path: string)
	return #string.gsub(path, "[^%.]", "")
end

const function innermost_group(anchors: anchors, point: Vector2): string?
	local found = nil :: string?

	for path, frame in anchors.groups do
		if not visible(frame) or not inside(frame, point) then continue end
		if found and depth(found) >= depth(path) then continue end
		found = path
	end

	return found
end

const function row_above(anchors: anchors, group: string, point: Vector2): string?
	local found = nil :: string?
	local found_y = -math.huge

	for path, row in anchors.rows do
		if row.group ~= group or not visible(row.frame) then continue end

		const top = row.frame.AbsolutePosition.Y
		if top > point.Y or top <= found_y then continue end

		found = path
		found_y = top
	end

	return found
end

const function locate(anchors: anchors, viewport: GuiObject, point: Vector2): presence.cursor?
	if not inside(viewport, point) then return nil end

	const group = innermost_group(anchors, point)
	if not group then return nil end

	const row = row_above(anchors, group, point)
	const frame = if row then anchors.rows[row].frame else anchors.groups[group]

	return {
		group = group,
		row = row,

		x = (point.X - frame.AbsolutePosition.X) / math.max(frame.AbsoluteSize.X, 1),
		y = (point.Y - frame.AbsolutePosition.Y) / px.scale(),
	}
end

const function anchor_of(anchors: anchors, cursor: presence.cursor): GuiObject?
	const frame = if cursor.row
		then anchors.rows[cursor.row] and anchors.rows[cursor.row].frame
		else anchors.groups[cursor.group]
	if not frame or not visible(frame) then return nil end
	return frame
end

const function place(anchors: anchors, cursor: presence.cursor): Vector2?
	const frame = anchor_of(anchors, cursor)
	if not frame then return nil end
	return frame.AbsolutePosition + Vector2.new(cursor.x * frame.AbsoluteSize.X, cursor.y * px.scale())
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
	anchor_of = anchor_of,
	owner_attribute = OWNER_ATTRIBUTE,
}
