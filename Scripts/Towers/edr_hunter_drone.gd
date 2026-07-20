class_name EDRHunterDrone
extends Node2D

const IDLE_ANIMATION := &"idle"
const AIM_ANIMATION := &"aim"
const SHOOT_ANIMATION := &"shoot"

@export var visual_pivot_path: NodePath = ^"VisualPivot"
@export var animated_sprite_path: NodePath = ^"VisualPivot/AnimatedSprite2D"
@export var forward_rotation_offset := PI * 0.5
@export_range(0.0, 80.0, 0.5) var hover_amplitude := 16.0
@export_range(0.1, 8.0, 0.1) var hover_speed := 2.2
@export_range(1.0, 6.0, 0.1) var shoot_playback_speed := 3.0

var _visual_pivot: Node2D
var _animated_sprite: AnimatedSprite2D
var _base_visual_position := Vector2.ZERO
var _hover_elapsed := 0.0
var _deployed_active := false


func _ready() -> void:
	_visual_pivot = get_node_or_null(visual_pivot_path) as Node2D
	_animated_sprite = get_node_or_null(animated_sprite_path) as AnimatedSprite2D
	if _visual_pivot != null:
		_base_visual_position = _visual_pivot.position
	if _animated_sprite != null and not _animated_sprite.animation_finished.is_connected(_on_animation_finished):
		_animated_sprite.animation_finished.connect(_on_animation_finished)
	visible = false
	set_process(false)


func _process(delta: float) -> void:
	if not visible or _visual_pivot == null:
		return

	_hover_elapsed += delta * hover_speed
	_visual_pivot.position = _base_visual_position + Vector2(
		cos(_hover_elapsed * 0.73) * hover_amplitude * 0.28,
		sin(_hover_elapsed) * hover_amplitude
	)


func set_deployed_active(active: bool) -> void:
	if _deployed_active == active:
		return

	_deployed_active = active
	visible = active
	set_process(active)
	if _animated_sprite == null:
		return
	if active:
		play_idle()
	else:
		_animated_sprite.stop()


func aim_at(target_position: Vector2) -> void:
	if _visual_pivot == null:
		return

	var direction := target_position - global_position
	if direction.length_squared() > 0.0:
		_visual_pivot.global_rotation = direction.angle() - forward_rotation_offset


func play_idle() -> void:
	_play_animation(IDLE_ANIMATION, 1.0)


func play_aim() -> void:
	if _animated_sprite != null and _animated_sprite.animation == SHOOT_ANIMATION and _animated_sprite.is_playing():
		return
	_play_animation(AIM_ANIMATION, 1.0)


func play_shoot() -> void:
	_play_animation(SHOOT_ANIMATION, shoot_playback_speed, true)


func _play_animation(animation_name: StringName, playback_speed: float, restart := false) -> void:
	if _animated_sprite == null \
			or _animated_sprite.sprite_frames == null \
			or not _animated_sprite.sprite_frames.has_animation(animation_name):
		return

	_animated_sprite.speed_scale = playback_speed
	if restart:
		_animated_sprite.stop()
	_animated_sprite.play(animation_name)


func _on_animation_finished() -> void:
	if _animated_sprite != null and _animated_sprite.animation == SHOOT_ANIMATION:
		play_aim()
