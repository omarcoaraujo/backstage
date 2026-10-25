--// Services
const Players = game:GetService "Players"
const RunService = game:GetService "RunService"

--// Packages
const vide = require "../../../roblox_packages/vide"

--// Modules
const presence = require "../../core/presence"

--// Utils
const pointer_target = require "../utils/pointer_target"
const px = require "../utils/px"
const theme = require "../constants/theme"

--// Constants
const ARROW_IMAGE = "rbxasset://textures/Cursors/KeyboardMouse/ArrowFarCursor.png"
const ARROW_SIZE = 56

const LABEL_SIZE = 12
const LABEL_OFFSET = 15

const OUTLINE_THICKNESS = 2

const LAYER_Z_INDEX = 200000
const FOLLOW_SPEED = 22
const GOLDEN_RATIO = 0.618

--// Types
type props = {
	anchors: pointer_target.anchors,
}

type shown = {
	root: Frame,
	outline: Frame,
	blocker: Frame,

	destroy: () -> (),
	position: Vector2?,
}

--// Functions
const function color_of(user: number)
	return Color3.fromHSV((user * GOLDEN_RATIO) % 1, 0.65, 0.8)
end

const function build_outline(color: Color3)
	return vide.create "Frame" {
		Name = "outline",
		BackgroundTransparency = 1,
		Visible = false,

		vide.create "UICorner" {},

		vide.create "UIStroke" {
			Color = color,
			Thickness = px(OUTLINE_THICKNESS),

			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			LineJoinMode = Enum.LineJoinMode.Round,
		},
	}
end

const function build_blocker()
	return vide.create "Frame" {
		Name = "blocker",
		BackgroundTransparency = 1,

		Active = true,
		Visible = false,
	}
end

const function fit(target: Frame, element: GuiObject, origin: Vector2)
	const left = math.round(element.AbsolutePosition.X - origin.X)
	const top = math.round(element.AbsolutePosition.Y - origin.Y)

	target.Position = UDim2.fromOffset(left, top)
	target.Size = UDim2.fromOffset(
		math.round(element.AbsolutePosition.X - origin.X + element.AbsoluteSize.X) - left,
		math.round(element.AbsolutePosition.Y - origin.Y + element.AbsoluteSize.Y) - top
	)
end

const function build_cursor(entry: presence.entry, color: Color3)
	return vide.create "Frame" {
		Name = "cursor",
		Size = UDim2.fromOffset(0, 0),

		BackgroundTransparency = 1,
		Visible = false,

		vide.create "ImageLabel" {
			Name = "arrow",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = px.udim2(0, ARROW_SIZE, 0, ARROW_SIZE),

			BackgroundTransparency = 1,
			Image = ARROW_IMAGE,
			ImageColor3 = color,
		},

		vide.create "TextLabel" {
			Name = "name",
			Position = px.udim2(0, LABEL_OFFSET, 0, LABEL_OFFSET),
			AutomaticSize = Enum.AutomaticSize.XY,

			BackgroundColor3 = color,
			BorderSizePixel = 0,

			FontFace = theme.font,
			Text = entry.name,

			TextColor3 = Color3.new(1, 1, 1),
			TextSize = px(LABEL_SIZE),

			vide.create "UICorner" {
				CornerRadius = px.udim(0, theme.radius),
			},

			vide.create "UIPadding" {
				PaddingLeft = px.udim(0, 5),
				PaddingRight = px.udim(0, 5),
				PaddingTop = px.udim(0, 2),
				PaddingBottom = px.udim(0, 2),
			},
		},
	}
end

const function build(entry: presence.entry)
	const color = color_of(entry.user)
	return { cursor = build_cursor(entry, color), outline = build_outline(color), blocker = build_blocker() }
end

--// Component
return function(props: props)
	const shown = {} :: { [number]: shown }
	local layer = nil :: Frame?
	local viewport = nil :: GuiObject?

	const function forget(user: number)
		const current = shown[user]
		if not current then return end

		shown[user] = nil
		current.destroy()

		current.root:Destroy()
		current.outline:Destroy()
		current.blocker:Destroy()
	end

	const function sync_users()
		const present = {} :: { [number]: true }

		for _, entry in presence.list() do
			present[entry.user] = true
			if shown[entry.user] or not layer then continue end

			const destroy, built = vide.root(function()
				return build(entry)
			end)

			built.cursor.Parent = layer
			built.outline.Parent = layer
			built.blocker.Parent = layer

			shown[entry.user] = {
				root = built.cursor,
				outline = built.outline,
				
				blocker = built.blocker,
				destroy = destroy,
			}
		end

		for user in shown do
			if not present[user] then forget(user) end
		end
	end

	const function lift()
		if not layer or viewport then return end

		const collector = layer:FindFirstAncestorWhichIsA "LayerCollector"
		if not collector then return end

		viewport = layer.Parent :: GuiObject?
		layer.Parent = collector
	end

	const function follow_cursor(current: shown, entry: presence.entry, origin: Vector2, view: GuiObject, blend: number)
		const place = if entry.cursor then pointer_target.place(props.anchors, entry.cursor) else nil
		const target = if place and pointer_target.inside(view, place) then place else nil
		current.root.Visible = target ~= nil

		if not target then
			current.position = nil
			return
		end

		const next = if current.position then current.position:Lerp(target, blend) else target
		current.position = next
		current.root.Position = UDim2.fromOffset(next.X - origin.X, next.Y - origin.Y)
	end

	const function follow_outline(current: shown, entry: presence.entry, origin: Vector2, view: GuiObject)
		const element = if entry.hold then pointer_target.resolve(props.anchors, entry.hold) else nil
		const center = if element then element.AbsolutePosition + element.AbsoluteSize / 2 else nil

		if not element or not center or not pointer_target.inside(view, center) then
			current.outline.Visible = false
			return
		end

		const corner = element:FindFirstChildOfClass "UICorner"
		const own_corner = current.outline:FindFirstChildOfClass "UICorner"
		if own_corner then own_corner.CornerRadius = if corner then corner.CornerRadius else UDim.new(0, 0) end

		fit(current.outline, element, origin)
		current.outline.Visible = true
	end

	const function follow_block(current: shown, entry: presence.entry, origin: Vector2, view: GuiObject)
		const own = Players.LocalPlayer
		const element = if entry.hold then pointer_target.resolve(props.anchors, entry.hold) else nil
		const center = if element then element.AbsolutePosition + element.AbsoluteSize / 2 else nil

		if not entry.hold or not element or not center or (own and entry.user == own.UserId) then
			current.blocker.Visible = false
			return
		end

		const row = props.anchors.rows[entry.hold.owner]
		const covered = if row
				and row.frame:IsA "GuiObject"
				and pointer_target.visible(row.frame)
			then row.frame
			else element

		if not pointer_target.inside(view, center) then
			current.blocker.Visible = false
			return
		end

		fit(current.blocker, covered, origin)
		current.blocker.Visible = true
	end

	const function follow(delta: number)
		lift()
		if not layer or not viewport then return end

		const blend = 1 - math.exp(-FOLLOW_SPEED * delta)
		const origin = layer.AbsolutePosition

		for _, entry in presence.list() do
			const current = shown[entry.user]
			if not current then continue end

			follow_cursor(current, entry, origin, viewport, blend)
			follow_outline(current, entry, origin, viewport)
			follow_block(current, entry, origin, viewport)
		end
	end

	const function clear()
		for user in table.clone(shown) do
			forget(user)
		end
	end

	layer = vide.create "Frame" {
		Name = "cursors",
		Size = UDim2.fromScale(1, 1),

		BackgroundTransparency = 1,
		ZIndex = LAYER_Z_INDEX,
	}

	vide.cleanup(presence.on_change(sync_users))
	vide.cleanup(RunService.RenderStepped:Connect(follow))

	vide.cleanup(clear)
	vide.cleanup(function()
		if layer then layer:Destroy() end
	end)

	sync_users()
	return layer
end
