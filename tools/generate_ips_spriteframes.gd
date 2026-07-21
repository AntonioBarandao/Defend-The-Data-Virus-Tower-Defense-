extends SceneTree

const FRAME_SIZE := Vector2(480, 480)
const ATLAS_COLUMNS := 7
const TOTAL_FRAMES := 145
const ANIMATION_FPS := 24.0

const FACTORY_PAGE_PATHS := [
	"res://assets/Towers/IPS_Intrusion/Animations/Factory/IPS_Intrusion_Factory_LV1_atlas_24fps_p01.png",
	"res://assets/Towers/IPS_Intrusion/Animations/Factory/IPS_Intrusion_Factory_LV1_atlas_24fps_p02.png",
	"res://assets/Towers/IPS_Intrusion/Animations/Factory/IPS_Intrusion_Factory_LV1_atlas_24fps_p03.png",
]
const SPIKE_PAGE_PATHS := [
	"res://assets/Towers/IPS_Intrusion/Animations/Spikes/Animated_Spikes_atlas_24fps_p01.png",
	"res://assets/Towers/IPS_Intrusion/Animations/Spikes/Animated_Spikes_atlas_24fps_p02.png",
	"res://assets/Towers/IPS_Intrusion/Animations/Spikes/Animated_Spikes_atlas_24fps_p03.png",
]


func _initialize() -> void:
	var factory_pages := _load_pages(FACTORY_PAGE_PATHS)
	var spike_pages := _load_pages(SPIKE_PAGE_PATHS)
	if factory_pages.size() != FACTORY_PAGE_PATHS.size() or spike_pages.size() != SPIKE_PAGE_PATHS.size():
		quit(1)
		return

	var factory_frames := SpriteFrames.new()
	factory_frames.remove_animation(&"default")
	_add_static_animation(factory_frames, &"idle", factory_pages, true)
	_add_static_animation(factory_frames, &"SummonAnim", factory_pages, false)
	_add_static_animation(factory_frames, &"ShootAnim", factory_pages, false)
	_add_atlas_animation(factory_frames, &"IPS_Intrusion_Factory_LV1", factory_pages)

	var spike_frames := SpriteFrames.new()
	spike_frames.remove_animation(&"default")
	_add_atlas_animation(spike_frames, &"Animated_Spikes", spike_pages)

	var factory_error := ResourceSaver.save(
		factory_frames,
		"res://assets/Towers/IPS_Intrusion/IPSIntrusionSpriteFrames.tres"
	)
	var spike_error := ResourceSaver.save(
		spike_frames,
		"res://assets/Towers/IPS_Intrusion/IPSIntrusionSpikeSpriteFrames.tres"
	)
	if factory_error != OK or spike_error != OK:
		push_error("Failed to save IPS SpriteFrames resources: factory=%d spike=%d" % [factory_error, spike_error])
		quit(1)
		return

	print("Generated IPS factory and spike SpriteFrames resources.")
	quit(0)


func _load_pages(paths: Array) -> Array[Texture2D]:
	var pages: Array[Texture2D] = []
	for path_value in paths:
		var texture := load(String(path_value)) as Texture2D
		if texture == null:
			push_error("Unable to load IPS atlas page: %s" % String(path_value))
			return []
		pages.append(texture)
	return pages


func _add_static_animation(
	frames: SpriteFrames,
	animation_name: StringName,
	pages: Array[Texture2D],
	loop_animation: bool
) -> void:
	frames.add_animation(animation_name)
	frames.set_animation_loop(animation_name, loop_animation)
	frames.set_animation_speed(animation_name, 1.0)
	frames.add_frame(animation_name, _atlas_frame(pages, 0))


func _add_atlas_animation(frames: SpriteFrames, animation_name: StringName, pages: Array[Texture2D]) -> void:
	frames.add_animation(animation_name)
	frames.set_animation_loop(animation_name, true)
	frames.set_animation_speed(animation_name, ANIMATION_FPS)
	for frame_index in range(TOTAL_FRAMES):
		frames.add_frame(animation_name, _atlas_frame(pages, frame_index))


func _atlas_frame(pages: Array[Texture2D], frame_index: int) -> AtlasTexture:
	var frames_per_page := ATLAS_COLUMNS * ATLAS_COLUMNS
	var page_index := frame_index / frames_per_page
	var local_index := frame_index % frames_per_page
	var atlas_frame := AtlasTexture.new()
	atlas_frame.atlas = pages[page_index]
	atlas_frame.region = Rect2(
		float(local_index % ATLAS_COLUMNS) * FRAME_SIZE.x,
		float(local_index / ATLAS_COLUMNS) * FRAME_SIZE.y,
		FRAME_SIZE.x,
		FRAME_SIZE.y
	)
	return atlas_frame
