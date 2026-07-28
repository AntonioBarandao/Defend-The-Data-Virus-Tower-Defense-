class_name RedVirus
extends AnimatedSprite2D

const CentralAudioResolver := preload("res://Scripts/Audio/audio_player_resolver.gd")

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
@export_group("Visual Tracks")
@export var idle_sprite_path: NodePath = ^"IdleAnimation"
@export var destroy_sprite_path: NodePath = ^"DestroyAnimation"
@export_group("")
@export_group("Audio")
@export var destroy_sfx_path: NodePath = ^"Sounds/VirusDestroySfx"
@export_group("")
@export_group("Nullifier")
@export var nullifier_highlight_color := Color(0.72, 0.26, 1.0, 1.0)
@export_group("")

var current_health := 1
var _destroying := false
var _destroy_sfx: AudioStreamPlayer
var _base_global_rotation := 0.0
var _base_global_scale := Vector2.ONE
var _speed_modifier_multiplier := 1.0
var _speed_modifier_expires_msec := 0
var _abilities_nullified := false
var _nullifier_suppression_sources: Dictionary = {}
var _external_transformation_active := false
var _idle_sprite: AnimatedSprite2D
var _destroy_sprite: AnimatedSprite2D


func _ready() -> void:
	_cache_visual_tracks()
	current_health = maxi(1, max_health)
	_destroy_sfx = CentralAudioResolver.resolve(self, destroy_sfx_path)
	_capture_base_visual_transform()
	if _visual_has_animation(_get_idle_sprite(), IDLE_ANIMATION):
		play_idle()


func _process(_delta: float) -> void:
	_preserve_visual_transform_on_path()


func reset_for_spawn() -> void:
	current_health = maxi(1, max_health)
	_destroying = false
	_external_transformation_active = false
	modulate = Color.WHITE
	self_modulate = Color.WHITE
	set_visual_self_modulate(Color.WHITE)
	reset_status_effects()
	_capture_base_visual_transform()
	_preserve_visual_transform_on_path()
	play_idle()
	show()


func play_idle() -> void:
	var idle_sprite := _get_idle_sprite()
	if not _visual_has_animation(idle_sprite, IDLE_ANIMATION):
		return

	_set_active_visual(idle_sprite)
	_play_visual_animation(idle_sprite, IDLE_ANIMATION)


func play_destroy_and_queue_owner(owner: Node) -> void:
	_destroying = true
	var final_duration := destroy_duration
	var destroy_sprite := play_destroy_track(DESTROY_ANIMATION)
	var has_destroy_animation := destroy_sprite != null
	if has_destroy_animation:
		final_duration = _get_visual_animation_duration(
			destroy_sprite,
			DESTROY_ANIMATION,
			destroy_duration
		)

	var tween := create_tween()
	if has_destroy_animation:
		tween.tween_interval(final_duration)
	else:
		var fallback_visual := _get_active_visual()
		tween.set_parallel(true)
		tween.tween_property(
			fallback_visual,
			"scale",
			fallback_visual.scale * destroy_scale_multiplier,
			final_duration
		)
		tween.tween_property(
			fallback_visual,
			"modulate",
			Color(1, 1, 1, 0),
			final_duration
		)
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
	return not _destroying and not _external_transformation_active


func is_destroying() -> bool:
	return _destroying


func should_remain_active_during_destroy() -> bool:
	return false


func uses_path_movement() -> bool:
	return not _external_transformation_active


func begin_external_transformation() -> bool:
	if _destroying or _external_transformation_active:
		return false

	_external_transformation_active = true
	_stop_all_visual_tracks()
	hide()
	return true


func is_external_transformation_active() -> bool:
	return _external_transformation_active


func cancel_external_transformation() -> void:
	_external_transformation_active = false
	show()
	play_idle()


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
	return _abilities_nullified or is_nullifier_suppressed()


func set_nullifier_suppressed(source: Node, active: bool) -> void:
	if source == null:
		return

	_prune_nullifier_suppression_sources()
	var was_suppressed := not _nullifier_suppression_sources.is_empty()
	var source_id := source.get_instance_id()
	if active:
		_nullifier_suppression_sources[source_id] = weakref(source)
	else:
		_nullifier_suppression_sources.erase(source_id)
	if was_suppressed != is_nullifier_suppressed():
		_sync_nullifier_highlight()


func is_nullifier_suppressed() -> bool:
	_prune_nullifier_suppression_sources()
	return not _nullifier_suppression_sources.is_empty()


func reset_status_effects() -> void:
	_speed_modifier_multiplier = 1.0
	_speed_modifier_expires_msec = 0
	_abilities_nullified = false
	_nullifier_suppression_sources.clear()
	_sync_nullifier_highlight()


func contains_global_point(pointer_position: Vector2) -> bool:
	return get_grab_rect().has_point(pointer_position)


func get_grab_rect() -> Rect2:
	var size := GRAB_SIZE
	var visual := _get_active_visual()
	if visual.sprite_frames != null \
			and visual.sprite_frames.has_animation(visual.animation):
		var texture := visual.sprite_frames.get_frame_texture(
			visual.animation,
			visual.frame
		)
		if texture != null:
			var current_scale := visual.global_scale
			size = texture.get_size() * Vector2(abs(current_scale.x), abs(current_scale.y))

	size.x = max(size.x, GRAB_SIZE.x)
	size.y = max(size.y, GRAB_SIZE.y)

	var top_left := global_position - size * 0.5
	if not visual.centered:
		top_left = visual.global_position

	return Rect2(top_left, size)


func play_destroy_track(animation_name: StringName) -> AnimatedSprite2D:
	var destroy_sprite := _get_destroy_sprite()
	if not _visual_has_animation(destroy_sprite, animation_name):
		return null

	_set_active_visual(destroy_sprite)
	_play_visual_animation(destroy_sprite, animation_name)
	return destroy_sprite


func set_visual_self_modulate(color: Color) -> void:
	for visual in _get_visual_tracks():
		visual.self_modulate = color


func _sync_nullifier_highlight() -> void:
	set_visual_self_modulate(
		nullifier_highlight_color
		if is_nullifier_suppressed()
		else Color.WHITE
	)


func _prune_nullifier_suppression_sources() -> void:
	for source_id in _nullifier_suppression_sources.keys():
		var source_ref := _nullifier_suppression_sources[source_id] as WeakRef
		if source_ref == null or not is_instance_valid(source_ref.get_ref()):
			_nullifier_suppression_sources.erase(source_id)


func _cache_visual_tracks() -> void:
	_idle_sprite = get_node_or_null(idle_sprite_path) as AnimatedSprite2D
	_destroy_sprite = get_node_or_null(destroy_sprite_path) as AnimatedSprite2D


func _get_idle_sprite() -> AnimatedSprite2D:
	return _idle_sprite if is_instance_valid(_idle_sprite) else self


func _get_destroy_sprite() -> AnimatedSprite2D:
	return _destroy_sprite if is_instance_valid(_destroy_sprite) else self


func _get_active_visual() -> AnimatedSprite2D:
	var destroy_sprite := _get_destroy_sprite()
	if destroy_sprite != self and destroy_sprite.visible:
		return destroy_sprite
	return _get_idle_sprite()


func _get_visual_tracks() -> Array[AnimatedSprite2D]:
	var tracks: Array[AnimatedSprite2D] = []
	var idle_sprite := _get_idle_sprite()
	var destroy_sprite := _get_destroy_sprite()
	tracks.append(idle_sprite)
	if destroy_sprite != idle_sprite:
		tracks.append(destroy_sprite)
	return tracks


func _set_active_visual(active_visual: AnimatedSprite2D) -> void:
	show()
	for visual in _get_visual_tracks():
		if visual == self:
			visual.visible = true
			if visual != active_visual:
				visual.stop()
			continue

		visual.visible = visual == active_visual
		if visual != active_visual:
			visual.stop()


func _stop_all_visual_tracks() -> void:
	for visual in _get_visual_tracks():
		visual.stop()


func _visual_has_animation(
	visual: AnimatedSprite2D,
	animation_name: StringName
) -> bool:
	return visual != null \
		and visual.sprite_frames != null \
		and visual.sprite_frames.has_animation(animation_name)


func _play_visual_animation(
	visual: AnimatedSprite2D,
	animation_name: StringName
) -> void:
	visual.animation = animation_name
	visual.frame = 0
	visual.frame_progress = 0.0
	visual.play()


func _get_visual_animation_duration(
	visual: AnimatedSprite2D,
	animation_name: StringName,
	fallback_duration: float
) -> float:
	if not _visual_has_animation(visual, animation_name):
		return fallback_duration

	var animation_speed := visual.sprite_frames.get_animation_speed(animation_name)
	var playback_speed := animation_speed * absf(visual.speed_scale)
	var frame_count := visual.sprite_frames.get_frame_count(animation_name)
	if playback_speed <= 0.0 or frame_count <= 0:
		return fallback_duration

	var duration_units := 0.0
	for frame_index in range(frame_count):
		duration_units += visual.sprite_frames.get_frame_duration(
			animation_name,
			frame_index
		)
	return duration_units / playback_speed


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
