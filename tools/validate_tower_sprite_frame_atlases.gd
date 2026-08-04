extends SceneTree

const SPRITE_FRAME_PATHS := [
	"res://assets/Towers/CyberGuardian/CyberGuardianSpriteFrames.res",
	"res://assets/Towers/CyberGuardian/Modes/SignalBoost/CyberGuardianSignalBoostSpriteFrames.tres",
	"res://assets/Towers/CyberGuardian/Modes/Firewall/CyberGuardianFirewallSpriteFrames.tres",
	"res://assets/Towers/Laser-Turret/LaserTurretSpriteFrames.res",
	"res://assets/Towers/Laser-Turret/LaserFX/LaserTurretBeamFxSpriteFrames.tres",
]

const MAX_ATLAS_DIMENSION := 4096.0
const BOUNDS_TOLERANCE := 0.01

var _failed := false


func _init() -> void:
	for resource_path in SPRITE_FRAME_PATHS:
		_validate_sprite_frames(resource_path)

	if _failed:
		quit(1)
		return
	print("Tower SpriteFrames atlas validation passed.")
	quit(0)


func _validate_sprite_frames(resource_path: String) -> void:
	var sprite_frames := load(resource_path) as SpriteFrames
	_check(sprite_frames != null, "Unable to load %s." % resource_path)
	if sprite_frames == null:
		return

	for animation_name in sprite_frames.get_animation_names():
		var frame_count := sprite_frames.get_frame_count(animation_name)
		for frame_index in range(frame_count):
			var frame_texture := sprite_frames.get_frame_texture(
				animation_name,
				frame_index
			)
			_check(
				frame_texture is AtlasTexture,
				"%s:%s frame %d is not an AtlasTexture." % [
					resource_path,
					animation_name,
					frame_index
				]
			)
			if not frame_texture is AtlasTexture:
				continue
			_validate_atlas_frame(
				frame_texture as AtlasTexture,
				resource_path,
				animation_name,
				frame_index
			)


func _validate_atlas_frame(
	frame_texture: AtlasTexture,
	resource_path: String,
	animation_name: StringName,
	frame_index: int
) -> void:
	var atlas := frame_texture.atlas
	_check(
		atlas != null,
		"%s:%s frame %d has no atlas." % [
			resource_path,
			animation_name,
			frame_index
		]
	)
	if atlas == null:
		return

	var atlas_size := atlas.get_size()
	var region_end := frame_texture.region.end
	var frame_label := "%s:%s frame %d" % [
		resource_path,
		animation_name,
		frame_index
	]
	_check(
		atlas_size.x <= MAX_ATLAS_DIMENSION \
			and atlas_size.y <= MAX_ATLAS_DIMENSION,
		"%s uses an atlas larger than %d: %s." % [
			frame_label,
			int(MAX_ATLAS_DIMENSION),
			atlas_size
		]
	)
	_check(
		frame_texture.region.position.x >= -BOUNDS_TOLERANCE \
			and frame_texture.region.position.y >= -BOUNDS_TOLERANCE \
			and region_end.x <= atlas_size.x + BOUNDS_TOLERANCE \
			and region_end.y <= atlas_size.y + BOUNDS_TOLERANCE,
		"%s region %s exceeds atlas size %s." % [
			frame_label,
			frame_texture.region,
			atlas_size
		]
	)


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)
