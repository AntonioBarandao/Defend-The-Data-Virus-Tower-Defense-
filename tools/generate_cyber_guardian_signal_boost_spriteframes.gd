extends SceneTree

const OUTPUT_PATH := "res://assets/Towers/CyberGuardian/Modes/SignalBoost/CyberGuardianSignalBoostSpriteFrames.tres"
const FRAME_SIZE := Vector2(720, 720)
const ANIMATION_SPEED := 24.0

const ANIMATIONS := [
	{
		"name": &"idle",
		"loop": true,
		"pages": [
			{
				"path": "res://assets/Towers/CyberGuardian/Modes/SignalBoost/Idle/Cyberguardian_Signal_Boost_Idle_atlas_24fps_page1.png",
				"frames": 100,
				"columns": 10
			},
			{
				"path": "res://assets/Towers/CyberGuardian/Modes/SignalBoost/Idle/Cyberguardian_Signal_Boost_Idle_atlas_24fps_page2.png",
				"frames": 45,
				"columns": 10
			}
		]
	},
	{
		"name": &"SummonAnim",
		"loop": false,
		"pages": [
			{
				"path": "res://assets/Towers/CyberGuardian/Modes/SignalBoost/Declare/Cyberguardian_Signal_Boost_Declare_atlas_24fps.png",
				"frames": 73,
				"columns": 10
			}
		]
	},
	{
		"name": &"ShootAnim",
		"loop": true,
		"pages": [
			{
				"path": "res://assets/Towers/CyberGuardian/Modes/SignalBoost/Active/Cyberguardian_Signal_Boost_Active_atlas_24fps.png",
				"frames": 73,
				"columns": 10
			}
		]
	}
]


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var sprite_frames := SpriteFrames.new()
	if sprite_frames.has_animation(&"default"):
		sprite_frames.remove_animation(&"default")

	for animation_definition in ANIMATIONS:
		_add_animation(sprite_frames, animation_definition)

	var save_error := ResourceSaver.save(sprite_frames, OUTPUT_PATH)
	if save_error != OK:
		push_error("Failed to save Signal Boost SpriteFrames: %s" % error_string(save_error))
		quit(1)
		return

	print("Generated Signal Boost SpriteFrames at %s" % OUTPUT_PATH)
	quit(0)


func _add_animation(sprite_frames: SpriteFrames, definition: Dictionary) -> void:
	var animation_name := definition["name"] as StringName
	sprite_frames.add_animation(animation_name)
	sprite_frames.set_animation_loop(animation_name, bool(definition["loop"]))
	sprite_frames.set_animation_speed(animation_name, ANIMATION_SPEED)

	for page_value in definition["pages"] as Array:
		var page := page_value as Dictionary
		var texture := load(String(page["path"])) as Texture2D
		if texture == null:
			push_error("Unable to load Signal Boost atlas page: %s" % page["path"])
			quit(1)
			return

		var frame_count := int(page["frames"])
		var columns := int(page["columns"])
		for frame_index in range(frame_count):
			var atlas_texture := AtlasTexture.new()
			atlas_texture.atlas = texture
			atlas_texture.region = Rect2(
				Vector2(frame_index % columns, frame_index / columns) * FRAME_SIZE,
				FRAME_SIZE
			)
			sprite_frames.add_frame(animation_name, atlas_texture)
