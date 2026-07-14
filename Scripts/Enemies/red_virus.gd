class_name RedVirus
extends AnimatedSprite2D

signal health_changed(current_health: int, max_health: int)
signal defeated(virus: RedVirus)

const IDLE_ANIMATION := &"idle"
const DESTROY_ANIMATION := &"destroy"
const GRAB_SIZE := Vector2(128, 128)
const DESTROY_SFX_STACK_LIMIT := 3
const DESTROY_SFX_STACK_WINDOW_MSEC := 1000

static var _destroy_sfx_window_started_msec := 0
static var _destroy_sfx_plays_in_window := 0

@export var path_speed := 150.0
@export var max_health := 1
@export var cyberbuck_reward := 5
@export var destroy_duration := 0.5
@export var destroy_scale_multiplier := 1.35
@export var preserve_path_visual_transform := true
@export_group("Audio")
@export var destroy_sfx_path: NodePath = ^"Audio/DestroySfx"
@export_group("")

var current_health := 1
var _destroying := false
var _destroy_sfx: AudioStreamPlayer
var _base_global_rotation := 0.0
var _base_global_scale := Vector2.ONE
var _speed_modifier_multiplier := 1.0
var _speed_modifier_expires_msec := 0
var _abilities_nullified := false


func _ready() -> void:
	current_health = maxi(1, max_health)
	_destroy_sfx = get_node_or_null(destroy_sfx_path) as AudioStreamPlayer
	_capture_base_visual_transform()
	if sprite_frames != null and sprite_frames.has_animation(IDLE_ANIMATION):
		play_idle()


func _process(_delta: float) -> void:
	_preserve_visual_transform_on_path()


func reset_for_spawn() -> void:
	current_health = maxi(1, max_health)
	_destroying = false
	modulate = Color.WHITE
	self_modulate = Color.WHITE
	reset_status_effects()
	_capture_base_visual_transform()
	_preserve_visual_transform_on_path()
	play_idle()
	show()


func play_idle() -> void:
	if sprite_frames == null or not sprite_frames.has_animation(IDLE_ANIMATION):
		return

	animation = IDLE_ANIMATION
	frame = 0
	frame_progress = 0.0
	play()


func play_destroy_and_queue_owner(owner: Node) -> void:
	_destroying = true
	var final_duration := destroy_duration
	var has_destroy_animation := false
	if sprite_frames != null and sprite_frames.has_animation(DESTROY_ANIMATION):
		has_destroy_animation = true
		var animation_speed := sprite_frames.get_animation_speed(DESTROY_ANIMATION)
		var frame_count := sprite_frames.get_frame_count(DESTROY_ANIMATION)
		if animation_speed > 0.0 and frame_count > 0:
			final_duration = float(frame_count) / animation_speed
		animation = DESTROY_ANIMATION
		frame = 0
		frame_progress = 0.0
		play()

	var tween := create_tween()
	if has_destroy_animation:
		tween.tween_interval(final_duration)
	else:
		tween.set_parallel(true)
		tween.tween_property(self, "scale", scale * destroy_scale_multiplier, final_duration)
		tween.tween_property(self, "modulate", Color(1, 1, 1, 0), final_duration)
		tween.set_parallel(false)

	if owner != null:
		tween.tween_callback(Callable(owner, "queue_free"))
	else:
		tween.tween_callback(Callable(self, "queue_free"))


func take_damage(amount: int) -> bool:
	var damage := maxi(0, amount)
	if _destroying or damage <= 0:
		return false

	current_health = maxi(0, current_health - damage)
	health_changed.emit(current_health, maxi(1, max_health))
	if current_health > 0:
		return false

	_destroying = true
	_play_destroy_sfx()
	defeated.emit(self)
	return true


func can_be_targeted_by(_attacker: Node) -> bool:
	return not _destroying


func is_destroying() -> bool:
	return _destroying


func should_remain_active_during_destroy() -> bool:
	return false


func get_path_speed() -> float:
	return path_speed * _get_active_speed_multiplier()


func get_cyberbuck_reward() -> int:
	return maxi(0, cyberbuck_reward)


func apply_scanner_speed_multiplier(multiplier: float, duration_seconds: float = 0.25) -> void:
	if _destroying:
		return

	var now_msec := Time.get_ticks_msec()
	if now_msec > _speed_modifier_expires_msec:
		_speed_modifier_multiplier = 1.0

	_speed_modifier_multiplier = minf(_speed_modifier_multiplier, clampf(multiplier, 0.0, 1.0))
	_speed_modifier_expires_msec = max(_speed_modifier_expires_msec, now_msec + roundi(maxf(0.0, duration_seconds) * 1000.0))


func nullify_abilities(_source: Node = null) -> void:
	_abilities_nullified = true


func are_abilities_nullified() -> bool:
	return _abilities_nullified


func reset_status_effects() -> void:
	_speed_modifier_multiplier = 1.0
	_speed_modifier_expires_msec = 0
	_abilities_nullified = false


func contains_global_point(pointer_position: Vector2) -> bool:
	return get_grab_rect().has_point(pointer_position)


func get_grab_rect() -> Rect2:
	var size := GRAB_SIZE
	if sprite_frames != null and sprite_frames.has_animation(animation):
		var texture := sprite_frames.get_frame_texture(animation, frame)
		if texture != null:
			var current_scale := global_scale
			size = texture.get_size() * Vector2(abs(current_scale.x), abs(current_scale.y))

	size.x = max(size.x, GRAB_SIZE.x)
	size.y = max(size.y, GRAB_SIZE.y)

	var top_left := global_position - size * 0.5
	if not centered:
		top_left = global_position

	return Rect2(top_left, size)


func _play_audio_player(player: AudioStreamPlayer) -> void:
	if player == null:
		return

	player.stop()
	player.play()


func _play_destroy_sfx() -> void:
	if not _can_play_destroy_sfx_now():
		return

	_play_audio_player(_destroy_sfx)


static func _can_play_destroy_sfx_now() -> bool:
	var now_msec := Time.get_ticks_msec()
	if now_msec - _destroy_sfx_window_started_msec >= DESTROY_SFX_STACK_WINDOW_MSEC:
		_destroy_sfx_window_started_msec = now_msec
		_destroy_sfx_plays_in_window = 0

	if _destroy_sfx_plays_in_window >= DESTROY_SFX_STACK_LIMIT:
		return false

	_destroy_sfx_plays_in_window += 1
	return true


func _get_active_speed_multiplier() -> float:
	if Time.get_ticks_msec() <= _speed_modifier_expires_msec:
		return _speed_modifier_multiplier

	_speed_modifier_multiplier = 1.0
	return 1.0


func _capture_base_visual_transform() -> void:
	_base_global_rotation = rotation if get_parent() is PathFollow2D else global_rotation
	_base_global_scale = global_scale


func _preserve_visual_transform_on_path() -> void:
	if not preserve_path_visual_transform:
		return

	var follow := get_parent() as PathFollow2D
	if follow == null:
		return

	top_level = true
	global_position = follow.global_position
	global_rotation = _base_global_rotation
	global_scale = _base_global_scale
