extends SceneTree

const OUTPUT_PATH := "res://assets/UI/Victory/DefendedTheDataFrames.tres"
const FRAME_SIZE := Vector2(512, 512)
const ANIMATION_SPEED := 24.0
const VICTORY_ANIMATION := &"victory"

const ATLAS_PAGES := [
	{
		"path": "res://assets/UI/Victory/DefendedTheData_Atlas_01.png",
		"frames": 64,
		"columns": 8
	},
	{
		"path": "res://assets/UI/Victory/DefendedTheData_Atlas_02.png",
		"frames": 9,
		"columns": 3
	}
]


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var sprite_frames := SpriteFrames.new()
	if sprite_frames.has_animation(&"default"):
		sprite_frames.remove_animation(&"default")

	sprite_frames.add_animation(VICTORY_ANIMATION)
	sprite_frames.set_animation_loop(VICTORY_ANIMATION, false)
	sprite_frames.set_animation_speed(VICTORY_ANIMATION, ANIMATION_SPEED)

	for page_value in ATLAS_PAGES:
		var page := page_value as Dictionary
		var texture := load(String(page["path"])) as Texture2D
		if texture == null:
			push_error("Unable to load victory atlas page: %s" % page["path"])
			quit(1)
			return

		var frame_count := int(page["frames"])
		var columns := int(page["columns"])
		for frame_index in range(frame_count):
			var atlas_texture := AtlasTexture.new()
			atlas_texture.atlas = texture
			atlas_texture.filter_clip = true
			atlas_texture.region = Rect2(
				Vector2(frame_index % columns, frame_index / columns) * FRAME_SIZE,
				FRAME_SIZE
			)
			sprite_frames.add_frame(VICTORY_ANIMATION, atlas_texture)

	var save_error := ResourceSaver.save(sprite_frames, OUTPUT_PATH)
	if save_error != OK:
		push_error("Failed to save victory SpriteFrames: %s" % error_string(save_error))
		quit(1)
		return

	print("Generated victory SpriteFrames at %s" % OUTPUT_PATH)
	quit(0)
