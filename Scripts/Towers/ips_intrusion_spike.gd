class_name IPSIntrusionSpike
extends Area2D

const DEFAULT_SPIKE_ANIMATION := &"Animated_Spikes"
const LEVEL_FIVE_SPIKE_ANIMATION := &"Animated_Spikes_LV5"
const LEVEL_FIVE_SPIKE_FRAMES_PATH := \
	"res://assets/Towers/IPS_Intrusion/IPSIntrusionSpikeLV5SpriteFrames.tres"

@export var damage := 1
@export var max_hits := 1
@export_range(4.0, 160.0, 1.0) var hurt_radius := 42.0

var path_offset := 0.0
var landed := false
var tower_level := 1

var _remaining_hits := 1
var _hit_follows := {}
var _target_position := Vector2.ZERO
var _target_rotation := 0.0
var _base_scale := Vector2.ONE
var _deploy_tween: Tween
<<<<<<< HEAD
=======
var _animated_sprite: AnimatedSprite2D
var _default_sprite_frames: SpriteFrames
var _level_five_sprite_frames: SpriteFrames
>>>>>>> 4c8daaffc01673569e6d46a60df2b56eb54c60d5


func _ready() -> void:
	_base_scale = scale
	_remaining_hits = maxi(1, max_hits)
<<<<<<< HEAD
=======
	_animated_sprite = get_node_or_null(animated_sprite_path) as AnimatedSprite2D
	if _animated_sprite != null:
		_default_sprite_frames = _animated_sprite.sprite_frames
	_play_spike_animation()
>>>>>>> 4c8daaffc01673569e6d46a60df2b56eb54c60d5


func reset_spike() -> void:
	_remaining_hits = maxi(1, max_hits)
	_hit_follows.clear()
	landed = false
	modulate = Color.WHITE
	scale = _base_scale
	show()


func configure_for_level(new_level: int, restore_health: bool = true) -> void:
	tower_level = clampi(new_level, 1, 5)
	max_hits = tower_level
	if restore_health:
		_remaining_hits = max_hits
	else:
		_remaining_hits = mini(_remaining_hits, max_hits)
	_play_spike_animation()


func get_remaining_hits() -> int:
	return maxi(0, _remaining_hits)


func is_landed() -> bool:
	return landed and _remaining_hits > 0


func start_deploy(start_position: Vector2, end_position: Vector2, end_rotation: float, travel_seconds: float) -> void:
	if _deploy_tween != null:
		_deploy_tween.kill()

	reset_spike()
	_target_position = end_position
	_target_rotation = end_rotation
	global_position = start_position
	global_rotation = end_rotation
	scale = _base_scale * 0.45
	modulate = Color(1.0, 1.0, 1.0, 0.62)

	_deploy_tween = create_tween()
	_deploy_tween.set_parallel(true)
	_deploy_tween.tween_property(self, "global_position", end_position, maxf(0.01, travel_seconds)).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_deploy_tween.tween_property(self, "scale", _base_scale, maxf(0.01, travel_seconds)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_deploy_tween.tween_property(self, "modulate", Color.WHITE, maxf(0.01, travel_seconds))
	_deploy_tween.set_parallel(false)
	_deploy_tween.tween_callback(Callable(self, "_finish_deploy"))


func sync_landed_transform(target_position: Vector2, target_rotation: float) -> void:
	_target_position = target_position
	_target_rotation = target_rotation
	if not landed:
		return

	global_position = target_position
	global_rotation = target_rotation


func can_hit_follow(follow: PathFollow2D) -> bool:
	if not landed or _remaining_hits <= 0 or not is_instance_valid(follow):
		return false
	if _hit_follows.has(follow.get_instance_id()):
		return false

	return global_position.distance_squared_to(_get_follow_target_position(follow)) <= hurt_radius * hurt_radius


func mark_follow_hit(follow: PathFollow2D) -> bool:
	if not can_hit_follow(follow):
		return false

	_hit_follows[follow.get_instance_id()] = true
	_remaining_hits -= 1
	if _remaining_hits <= 0:
		_deplete()
	return true


func _finish_deploy() -> void:
	landed = true
	global_position = _target_position
	global_rotation = _target_rotation
	scale = _base_scale
	modulate = Color.WHITE


func _deplete() -> void:
	landed = false
	if _deploy_tween != null:
		_deploy_tween.kill()

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", _base_scale * 0.72, 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.18)
	tween.set_parallel(false)
	tween.tween_callback(Callable(self, "queue_free"))


func _get_follow_target_position(follow: PathFollow2D) -> Vector2:
	for child in follow.get_children():
		var virus := child as RedVirus
		if virus != null:
			return virus.global_position

	return follow.global_position
<<<<<<< HEAD
=======


func _play_spike_animation() -> void:
	if _animated_sprite == null or _animated_sprite.sprite_frames == null:
		return
	var animation_name := (
		LEVEL_FIVE_SPIKE_ANIMATION
		if tower_level >= 5
		else DEFAULT_SPIKE_ANIMATION
	)
	if tower_level >= 5:
		if _level_five_sprite_frames == null:
			_level_five_sprite_frames = load(
				LEVEL_FIVE_SPIKE_FRAMES_PATH
			) as SpriteFrames
		if _level_five_sprite_frames != null:
			_animated_sprite.sprite_frames = _level_five_sprite_frames
	elif _default_sprite_frames != null:
		_animated_sprite.sprite_frames = _default_sprite_frames
	if not _animated_sprite.sprite_frames.has_animation(animation_name):
		return

	_animated_sprite.play(animation_name)
>>>>>>> 4c8daaffc01673569e6d46a60df2b56eb54c60d5
