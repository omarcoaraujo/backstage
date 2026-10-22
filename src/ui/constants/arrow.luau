--// Constants
const FRAME = 12

--// End
return table.freeze {
	image = "rbxasset://textures/StudioSharedUI/arrowSpritesheet.png",
	frame = Vector2.new(FRAME, FRAME),

	right = Vector2.new(FRAME, 0),
	down = Vector2.new(FRAME * 2, 0),

	size = 6,
	gap = 6,
}
