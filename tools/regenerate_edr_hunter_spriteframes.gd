extends SceneTree

const HUNTER_OUTPUT := "res://assets/Towers/EDR_Hunter/EDRHunterSpriteFrames.tres"
const DRONE_OUTPUT := "res://assets/Towers/EDR_Hunter/EDRHunterDroneSpriteFrames.tres"
const FRAME_SIZE := Vector2i(360, 360)
const PAGE_COLUMNS := 10
const PAGE_CAPACITY := 100
const ANIMATION_FPS := 24.0
const TRACK_FRAME_COUNTS := {
	"Idle": [145, 145, 145, 145],
	"Aim": [73, 73, 145, 73],
	"Shoot": [73, 73, 73, 73]
}


func _init() -> void:
	_build_hunter_frames()
	_build_drone_frames()
	quit()


func _build_hunter_frames() -> void:
	var sprite_frames := _new_empty_sprite_frames()
	for level in range(1, 5):
		for source_track in ["Idle", "Aim", "Shoot"]:
			var animation_name := StringName("%s_lv%d" % [source_track.to_lower(), level])
			var frame_count: int = TRACK_FRAME_COUNTS[source_track][level - 1]
			_add_paged_animation(
				sprite_frames,
				animation_name,
				"res://assets/Towers/EDR_Hunter/Animations/LV%d/EDR_Hunter_LV%d_%s_atlas_24fps_p%%02d.png" % [level, level, source_track],
				frame_count,
				source_track != "Shoot"
			)

	var level_five_texture := load(
		"res://assets/Towers/EDR_Hunter/Animations/LV5/EDR_Hunter_LV5_test.png"
	) as Texture2D
	for track_name in ["idle", "aim", "shoot"]:
		_add_static_animation(
			sprite_frames,
			StringName("%s_lv5" % track_name),
			level_five_texture,
			track_name != "shoot"
		)

	var level_one_atlas := load(
		"res://assets/Towers/EDR_Hunter/Animations/LV1/EDR_Hunter_LV1_Idle_atlas_24fps_p01.png"
	) as Texture2D
	_add_static_animation(sprite_frames, &"idle", level_one_atlas, true, true)
	_add_static_animation(sprite_frames, &"SummonAnim", level_one_atlas, false, true)
	_add_static_animation(sprite_frames, &"ShootAnim", level_one_atlas, false, true)
	_save_frames(sprite_frames, HUNTER_OUTPUT)


func _build_drone_frames() -> void:
	var sprite_frames := _new_empty_sprite_frames()
	var idle_pattern := (
		"res://assets/Towers/EDR_Hunter/Animations/Drone/"
		+ "EDR_Hunter_Drone_Idle_atlas_24fps_p%02d.png"
	)
	var shoot_pattern := (
		"res://assets/Towers/EDR_Hunter/Animations/Drone/"
		+ "EDR_Hunter_Drone_Shoot_atlas_24fps_p%02d.png"
	)
	_add_paged_animation(sprite_frames, &"idle", idle_pattern, 73, true)
	_add_paged_animation(sprite_frames, &"aim", idle_pattern, 73, true)
	_add_paged_animation(sprite_frames, &"shoot", shoot_pattern, 73, false)
	_save_frames(sprite_frames, DRONE_OUTPUT)


func _new_empty_sprite_frames() -> SpriteFrames:
	var sprite_frames := SpriteFrames.new()
	for animation_name in sprite_frames.get_animation_names():
		sprite_frames.remove_animation(animation_name)
	return sprite_frames


func _add_paged_animation(
	sprite_frames: SpriteFrames,
	animation_name: StringName,
	atlas_pattern: String,
	frame_count: int,
	loop: bool
) -> void:
	sprite_frames.add_animation(animation_name)
	sprite_frames.set_animation_loop(animation_name, loop)
	sprite_frames.set_animation_speed(animation_name, ANIMATION_FPS)

	var remaining := frame_count
	var page_number := 1
	while remaining > 0:
		var page_frame_count := mini(PAGE_CAPACITY, remaining)
		var atlas_path := atlas_pattern % page_number
		var atlas := load(atlas_path) as Texture2D
		if atlas == null:
			push_error("Could not load EDR atlas: %s" % atlas_path)
			return
		for frame_index in range(page_frame_count):
			sprite_frames.add_frame(animation_name, _make_atlas_frame(atlas, frame_index))
		remaining -= page_frame_count
		page_number += 1


func _add_static_animation(
	sprite_frames: SpriteFrames,
	animation_name: StringName,
	texture: Texture2D,
	loop: bool,
	use_atlas_region := false
) -> void:
	if texture == null:
		push_error("Static texture is missing for animation %s." % animation_name)
		return
	sprite_frames.add_animation(animation_name)
	sprite_frames.set_animation_loop(animation_name, loop)
	sprite_frames.set_animation_speed(animation_name, 1.0)
	var frame_texture: Texture2D = _make_atlas_frame(texture, 0) if use_atlas_region else texture
	sprite_frames.add_frame(animation_name, frame_texture)


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


func _save_frames(sprite_frames: SpriteFrames, output_path: String) -> void:
	var error := ResourceSaver.save(sprite_frames, output_path)
	if error != OK:
		push_error("Failed to save %s. Error: %s" % [output_path, error])
		return
	print("Saved EDR SpriteFrames to %s" % output_path)
