extends SceneTree

const FACTORY_ANIMATIONS := [
	{
		"name": &"IPS_Intrusion_Factory_LV1",
		"frame_count": 73,
		"frame_size": Vector2(256, 256),
		"columns": 10,
		"fps": 12.0,
		"resource_path": "res://assets/Towers/IPS_Intrusion/IPSIntrusionSpriteFrames.tres",
		"atlas_path": "res://assets/Towers/IPS_Intrusion/Animations/Factory/IPS_Intrusion_Factory_LV1_atlas_12fps.png",
	},
	{
		"name": &"IPS_Intrusion_Factory_LV2",
		"frame_count": 73,
		"frame_size": Vector2(256, 256),
		"columns": 10,
		"fps": 12.0,
		"resource_path": "res://assets/Towers/IPS_Intrusion/IPSIntrusionFactoryLV2SpriteFrames.tres",
		"atlas_path": "res://assets/Towers/IPS_Intrusion/Animations/Factory/IPS_Intrusion_Factory_LV2_atlas_12fps.png",
	},
	{
		"name": &"IPS_Intrusion_Factory_LV3",
		"frame_count": 73,
		"frame_size": Vector2(256, 256),
		"columns": 10,
		"fps": 12.0,
		"resource_path": "res://assets/Towers/IPS_Intrusion/IPSIntrusionFactoryLV3SpriteFrames.tres",
		"atlas_path": "res://assets/Towers/IPS_Intrusion/Animations/Factory/IPS_Intrusion_Factory_LV3_atlas_12fps.png",
	},
	{
		"name": &"IPS_Intrusion_Factory_LV4",
		"frame_count": 73,
		"frame_size": Vector2(256, 256),
		"columns": 10,
		"fps": 12.0,
		"resource_path": "res://assets/Towers/IPS_Intrusion/IPSIntrusionFactoryLV4SpriteFrames.tres",
		"atlas_path": "res://assets/Towers/IPS_Intrusion/Animations/Factory/IPS_Intrusion_Factory_LV4_atlas_12fps.png",
	},
	{
		"name": &"IPS_Intrusion_Factory_LV5",
		"frame_count": 73,
		"frame_size": Vector2(256, 256),
		"columns": 10,
		"fps": 12.0,
		"resource_path": "res://assets/Towers/IPS_Intrusion/IPSIntrusionFactoryLV5SpriteFrames.tres",
		"atlas_path": "res://assets/Towers/IPS_Intrusion/Animations/Factory/IPS_Intrusion_Factory_LV5_atlas_12fps.png",
	},
]
const SPIKE_ANIMATIONS := [
	{
		"name": &"Animated_Spikes",
		"frame_count": 73,
		"frame_size": Vector2(320, 320),
		"columns": 10,
		"fps": 12.0,
		"resource_path": "res://assets/Towers/IPS_Intrusion/IPSIntrusionSpikeSpriteFrames.tres",
		"atlas_path": "res://assets/Towers/IPS_Intrusion/Animations/Spikes/Animated_Spikes_atlas_12fps.png",
	},
	{
		"name": &"Animated_Spikes_LV5",
		"frame_count": 37,
		"frame_size": Vector2(320, 320),
		"columns": 10,
		"fps": 12.0,
		"resource_path": "res://assets/Towers/IPS_Intrusion/IPSIntrusionSpikeLV5SpriteFrames.tres",
		"atlas_path": "res://assets/Towers/IPS_Intrusion/Animations/Spikes/Animated_Spikes_LV5_atlas_12fps.png",
	},
]
const ELECTRICITY_ANIMATION := {
	"name": &"Animated_Electricity",
	"frame_count": 37,
	"frame_size": Vector2(320, 320),
	"columns": 10,
	"fps": 12.0,
	"resource_path": "res://assets/Towers/IPS_Intrusion/IPSElectricitySpriteFrames.tres",
	"atlas_path": "res://assets/Towers/IPS_Intrusion/Animations/Electricity/Animated_Electricity_atlas_12fps.png",
}


func _initialize() -> void:
	for definition in FACTORY_ANIMATIONS:
		var atlas := _load_atlas(definition)
		if atlas == null:
			quit(1)
			return
		var factory_frames := SpriteFrames.new()
		factory_frames.remove_animation(&"default")
		_add_atlas_animation(factory_frames, definition, atlas)
		_add_static_animation(factory_frames, &"idle", definition, atlas, true)
		_add_static_animation(factory_frames, &"SummonAnim", definition, atlas, false)
		_add_static_animation(factory_frames, &"ShootAnim", definition, atlas, false)
		if ResourceSaver.save(
			factory_frames,
			String(definition["resource_path"])
		) != OK:
			push_error(
				"Failed to save IPS factory SpriteFrames: %s"
				% String(definition["resource_path"])
			)
			quit(1)
			return

	for definition in SPIKE_ANIMATIONS:
		var atlas := _load_atlas(definition)
		if atlas == null:
			quit(1)
			return
		var spike_frames := SpriteFrames.new()
		spike_frames.remove_animation(&"default")
		_add_atlas_animation(spike_frames, definition, atlas)
		if ResourceSaver.save(
			spike_frames,
			String(definition["resource_path"])
		) != OK:
			push_error(
				"Failed to save IPS spike SpriteFrames: %s"
				% String(definition["resource_path"])
			)
			quit(1)
			return

	var electricity_atlas := _load_atlas(ELECTRICITY_ANIMATION)
	if electricity_atlas == null:
		quit(1)
		return
	var electricity_frames := SpriteFrames.new()
	electricity_frames.remove_animation(&"default")
	_add_atlas_animation(
		electricity_frames,
		ELECTRICITY_ANIMATION,
		electricity_atlas
	)
	if ResourceSaver.save(
		electricity_frames,
		String(ELECTRICITY_ANIMATION["resource_path"])
	) != OK:
		push_error("Failed to save IPS electricity SpriteFrames resource.")
		quit(1)
		return

	print("Generated optimized IPS factory, spike, and electricity SpriteFrames.")
	quit(0)


func _load_atlas(definition: Dictionary) -> Texture2D:
	var atlas_path := String(definition["atlas_path"])
	var texture := load(atlas_path) as Texture2D
	if texture == null:
		push_error("Unable to load IPS atlas: %s" % atlas_path)
	return texture


func _add_static_animation(
	frames: SpriteFrames,
	animation_name: StringName,
	definition: Dictionary,
	atlas: Texture2D,
	loop_animation: bool
) -> void:
	frames.add_animation(animation_name)
	frames.set_animation_loop(animation_name, loop_animation)
	frames.set_animation_speed(animation_name, 1.0)
	frames.add_frame(animation_name, _atlas_frame(definition, atlas, 0))


func _add_atlas_animation(
	frames: SpriteFrames,
	definition: Dictionary,
	atlas: Texture2D
) -> void:
	var animation_name := StringName(definition["name"])
	frames.add_animation(animation_name)
	frames.set_animation_loop(animation_name, true)
	frames.set_animation_speed(animation_name, float(definition["fps"]))
	for frame_index in range(int(definition["frame_count"])):
		frames.add_frame(
			animation_name,
			_atlas_frame(definition, atlas, frame_index)
		)


func _atlas_frame(
	definition: Dictionary,
	atlas: Texture2D,
	frame_index: int
) -> AtlasTexture:
	var columns := int(definition["columns"])
	var frame_size := definition["frame_size"] as Vector2
	var atlas_frame := AtlasTexture.new()
	atlas_frame.atlas = atlas
	atlas_frame.region = Rect2(
		float(frame_index % columns) * frame_size.x,
		float(frame_index / columns) * frame_size.y,
		frame_size.x,
		frame_size.y
	)
	return atlas_frame
