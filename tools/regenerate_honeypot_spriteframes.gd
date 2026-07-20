extends SceneTree

const OUTPUT_PATH := "res://assets/Towers/Honeypot_Production/HoneypotProductionSpriteFrames.tres"
const FRAME_SIZE := Vector2i(480, 480)
const PAGE_COLUMNS := 8
const PAGE_FRAME_COUNTS := [64, 64, 17]
const ANIMATION_FPS := 24.0


func _init() -> void:
	var sprite_frames := SpriteFrames.new()
	for animation_name in sprite_frames.get_animation_names():
		sprite_frames.remove_animation(animation_name)

	for level in range(1, 6):
		_add_level_animation(sprite_frames, level)

	# The shared tower base expects these tracks. Honeypot maps them to its
	# currently active level visual, so one compatibility frame is sufficient.
	for animation_name in [&"idle", &"SummonAnim", &"ShootAnim"]:
		_add_compatibility_animation(sprite_frames, animation_name)

	var error := ResourceSaver.save(sprite_frames, OUTPUT_PATH)
	if error != OK:
		push_error("Failed to save %s. Error: %s" % [OUTPUT_PATH, error])
		quit(1)
		return

	print("Saved Honeypot SpriteFrames to %s" % OUTPUT_PATH)
	quit()


func _add_level_animation(sprite_frames: SpriteFrames, level: int) -> void:
	var animation_name := StringName("idle_lv%d" % level)
	sprite_frames.add_animation(animation_name)
	sprite_frames.set_animation_loop(animation_name, true)
	sprite_frames.set_animation_speed(animation_name, ANIMATION_FPS)

	for page_index in range(PAGE_FRAME_COUNTS.size()):
		var atlas_path := (
			"res://assets/Towers/Honeypot_Production/Idle/"
			+ "Honeypot_Production_LV%d_Idle_atlas_24fps_p%02d.png"
			% [level, page_index + 1]
		)
		_add_page_frames(
			sprite_frames,
			animation_name,
			atlas_path,
			PAGE_FRAME_COUNTS[page_index]
		)


func _add_compatibility_animation(sprite_frames: SpriteFrames, animation_name: StringName) -> void:
	var atlas_path := (
		"res://assets/Towers/Honeypot_Production/Idle/"
		+ "Honeypot_Production_LV1_Idle_atlas_24fps_p01.png"
	)
	var atlas := load(atlas_path) as Texture2D
	if atlas == null:
		push_error("Could not load atlas: %s" % atlas_path)
		return

	sprite_frames.add_animation(animation_name)
	sprite_frames.set_animation_loop(animation_name, animation_name == &"idle")
	sprite_frames.set_animation_speed(animation_name, 1.0)
	sprite_frames.add_frame(animation_name, _make_atlas_frame(atlas, 0))


func _add_page_frames(
	sprite_frames: SpriteFrames,
	animation_name: StringName,
	atlas_path: String,
	frame_count: int
) -> void:
	var atlas := load(atlas_path) as Texture2D
	if atlas == null:
		push_error("Could not load atlas: %s" % atlas_path)
		return

	for frame_index in range(frame_count):
		sprite_frames.add_frame(animation_name, _make_atlas_frame(atlas, frame_index))


func _make_atlas_frame(atlas: Texture2D, frame_index: int) -> AtlasTexture:
	var atlas_texture := AtlasTexture.new()
	atlas_texture.atlas = atlas
	atlas_texture.region = Rect2(
		(frame_index % PAGE_COLUMNS) * FRAME_SIZE.x,
		int(frame_index / PAGE_COLUMNS) * FRAME_SIZE.y,
		FRAME_SIZE.x,
		FRAME_SIZE.y
	)
	return atlas_texture
