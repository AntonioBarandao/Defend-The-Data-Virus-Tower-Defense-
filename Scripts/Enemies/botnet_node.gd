class_name BotnetNode
extends Node2D

signal level_changed(level: int)
signal minion_spawn_requested(
	spawn_global_position: Vector2,
	batch_index: int
)
signal health_changed(current_health: int, maximum_health: int)
signal defeated(botnet_node: BotnetNode)
signal activation_animation_started(level: int)
signal activation_animation_finished(level: int)
signal evolution_animation_started(from_level: int, to_level: int)
signal evolution_animation_finished(level: int)
signal final_reveal_clip_held(clip_index: int)

const MAX_LEVEL := 3
const IDLE_ANIMATION_NAMES := [
	&"idle_lv1",
	&"idle_lv2",
	&"idle_lv3",
]
const ACTIVATE_ANIMATION_NAMES := [
	&"activate_lv1",
	&"activate_lv2",
	&"activate_lv3",
]
const EVOLUTION_ANIMATION_NAMES := [
	&"evolve_lv1_to_lv2",
	&"evolve_lv2_to_lv3",
]
const FINAL_REVEAL_ANIMATION_NAMES := [
	&"appear_hollow_lv3",
	&"appear_anti_lv3",
]
const DESTROY_ANIMATION_NAME := &"destroy_lv3"

@export var idle_animation_paths: Array[NodePath] = [
	^"LV1IdleAnimation",
	^"LV2IdleAnimation",
	^"LV3IdleAnimation",
]
@export var activate_animation_paths: Array[NodePath] = [
	^"LV1ActivateAnimation",
	^"LV2ActivateAnimation",
	^"LV3ActivateAnimation",
]
@export var evolution_animation_paths: Array[NodePath] = [
	^"LV1ToLV2EvolveAnimation",
	^"LV2ToLV3EvolveAnimation",
]
@export var final_reveal_animation_paths: Array[NodePath] = [
	^"LV3AppearHollowAnimation",
	^"LV3AppearAntiAnimation",
]
@export var anti_guardian_reveal_marker_one_path: NodePath = \
	^"Anti-Guardian-Botnet-1"
@export var anti_guardian_reveal_marker_two_path: NodePath = \
	^"Anti-Guardian-Botnet-2"
@export var destroy_animation_path: NodePath = ^"LV3DestroyAnimation"
@export var spawn_markers_path: NodePath = ^"PossibleSpawnMarkers2"
@export var health_hud_path: NodePath = ^"BotnetHealthHUD"
@export var health_bar_path: NodePath = \
	^"BotnetHealthHUD/Root/BossPanel/Margin/Content/HealthBar"
@export_range(1, 1000, 1) var maximum_health := 25
@export_range(1, MAX_LEVEL, 1) var combat_unlock_level := 3
@export_range(1.0, 120.0, 0.5) var minion_spawn_interval := 20.0
@export var minion_spawn_counts_by_level := PackedInt32Array([1, 2, 3])
@export_range(0.03, 0.6, 0.01) var damage_flash_seconds := 0.14
@export_range(1, MAX_LEVEL, 1) var current_level := 1:
	set(value):
		var next_level := clampi(value, 1, MAX_LEVEL)
		if current_level == next_level:
			return
		current_level = next_level
		_reset_for_new_level()
		if is_inside_tree():
			_sync_visuals()
		level_changed.emit(current_level)

var active := false
var _wave_active := false
var _current_health := 25
var _defeated_level := 0
var _minion_spawn_elapsed := 0.0
var _idle_animations: Array[AnimatedSprite2D] = []
var _activate_animations: Array[AnimatedSprite2D] = []
var _evolution_animations: Array[AnimatedSprite2D] = []
var _final_reveal_animations: Array[AnimatedSprite2D] = []
var _activation_playing := false
var _evolution_playing := false
var _final_reveal_playing := false
var _active_activation_sprite: AnimatedSprite2D
var _active_evolution_sprite: AnimatedSprite2D
var _active_final_reveal_sprite: AnimatedSprite2D
var _final_reveal_serial := 0
var _final_boss_health_suppressed := false
var _anti_guardian_reveal_marker_one: Marker2D
var _anti_guardian_reveal_marker_two: Marker2D
var _destroy_animation: AnimatedSprite2D
var _destroy_playing := false
var _destroy_serial := 0
var _spawn_markers: Array[Marker2D] = []
var _health_hud: BotnetNodeProgressBar
var _health_bar: ProgressBar
var _health_tween: Tween
var _damage_flash_tween: Tween
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	_idle_animations = _resolve_animation_nodes(idle_animation_paths)
	_activate_animations = _resolve_animation_nodes(activate_animation_paths)
	_evolution_animations = _resolve_animation_nodes(evolution_animation_paths)
	_final_reveal_animations = _resolve_animation_nodes(
		final_reveal_animation_paths
	)
	_anti_guardian_reveal_marker_one = get_node_or_null(
		anti_guardian_reveal_marker_one_path
	) as Marker2D
	_anti_guardian_reveal_marker_two = get_node_or_null(
		anti_guardian_reveal_marker_two_path
	) as Marker2D
	_destroy_animation = get_node_or_null(
		destroy_animation_path
	) as AnimatedSprite2D
	var spawn_markers := get_node_or_null(spawn_markers_path)
	if spawn_markers != null:
		for child in spawn_markers.get_children():
			var marker := child as Marker2D
			if marker != null:
				_spawn_markers.append(marker)
	_health_hud = get_node_or_null(
		health_hud_path
	) as BotnetNodeProgressBar
	_health_bar = get_node_or_null(health_bar_path) as ProgressBar
	_current_health = maximum_health
	_configure_health_bar()
	_sync_visuals()


func activate() -> void:
	if _defeated_level == current_level:
		active = false
		_sync_visuals()
		return
	active = true
	_current_health = clampi(_current_health, 1, maximum_health)
	_configure_health_bar()
	_sync_visuals()


func deactivate() -> void:
	active = false
	_wave_active = false
	_minion_spawn_elapsed = 0.0
	_cancel_activation_animation()
	_cancel_evolution_animation()
	_cancel_final_reveal_animation()
	_cancel_destroy_animation()
	_sync_visuals()


func set_level(value: int) -> void:
	current_level = value


func get_level() -> int:
	return current_level


func set_wave_active(value: bool) -> void:
	_wave_active = value and active and not is_defeated()
	_minion_spawn_elapsed = 0.0


func update_boss(delta: float) -> void:
	if not active or not _wave_active or is_defeated():
		return

	_minion_spawn_elapsed += maxf(0.0, delta)
	if _activation_playing or _evolution_playing:
		return

	var activation_duration := _get_activation_duration(current_level)
	var activation_start_time := maxf(
		0.0,
		minion_spawn_interval - activation_duration
	)
	if _minion_spawn_elapsed >= activation_start_time:
		_play_activation_then_spawn()


func play_evolution_to_level(target_level: int) -> void:
	var next_level := clampi(target_level, 1, MAX_LEVEL)
	if next_level != current_level + 1:
		set_level(next_level)
		activate()
		return

	var evolution_index := current_level - 1
	var sprite := _get_animation_at(_evolution_animations, evolution_index)
	if sprite == null:
		set_level(next_level)
		activate()
		return

	_cancel_activation_animation()
	_evolution_playing = true
	_active_evolution_sprite = sprite
	active = true
	_wave_active = false
	evolution_animation_started.emit(current_level, next_level)
	_sync_visuals()
	sprite.frame = 0
	sprite.play(EVOLUTION_ANIMATION_NAMES[evolution_index])
	await sprite.animation_finished

	if not is_instance_valid(sprite) \
			or sprite != _active_evolution_sprite \
			or not _evolution_playing:
		return
	_evolution_playing = false
	_active_evolution_sprite = null
	set_level(next_level)
	activate()
	evolution_animation_finished.emit(current_level)


func finish_evolution_immediately(target_level: int) -> void:
	_cancel_evolution_animation()
	set_level(target_level)
	activate()


func is_evolution_playing() -> bool:
	return _evolution_playing


func set_encounter_maximum_health(value: int, refill: bool = true) -> void:
	maximum_health = maxi(1, value)
	if refill:
		_cancel_destroy_animation()
		_current_health = maximum_health
		_defeated_level = 0
	else:
		_current_health = clampi(_current_health, 0, maximum_health)
	_configure_health_bar()
	health_changed.emit(_current_health, maximum_health)


func play_final_boss_reveal() -> void:
	await play_final_boss_hollow_reveal()
	if not _final_reveal_playing:
		return
	await play_final_boss_anti_reveal()


func play_final_boss_hollow_reveal() -> void:
	_cancel_final_reveal_animation()
	_cancel_activation_animation()
	_cancel_evolution_animation()
	_final_reveal_playing = true
	active = true
	_wave_active = false
	var serial := _final_reveal_serial
	await _play_final_reveal_clip(0, serial, true)


func play_final_boss_anti_reveal() -> void:
	if not _final_reveal_playing:
		_cancel_final_reveal_animation()
		_final_reveal_playing = true
		active = true
		_wave_active = false
	var serial := _final_reveal_serial
	await _play_final_reveal_clip(1, serial, true)


func get_final_boss_anti_reveal_duration() -> float:
	var sprite := _get_animation_at(_final_reveal_animations, 1)
	if sprite == null or FINAL_REVEAL_ANIMATION_NAMES.size() <= 1:
		return 0.0
	return _get_sprite_animation_duration(
		sprite,
		FINAL_REVEAL_ANIMATION_NAMES[1]
	)


func get_anti_guardian_reveal_marker_global_position(
	marker_index: int
) -> Vector2:
	var marker := (
		_anti_guardian_reveal_marker_one
		if marker_index <= 0
		else _anti_guardian_reveal_marker_two
	)
	return marker.global_position if is_instance_valid(marker) else global_position


func set_final_boss_health_suppressed(value: bool) -> void:
	_final_boss_health_suppressed = value
	if is_inside_tree():
		_sync_visuals()


func is_final_boss_health_suppressed() -> bool:
	return _final_boss_health_suppressed


func finish_final_boss_reveal() -> void:
	if not _final_reveal_playing:
		return
	finish_final_boss_reveal_immediately()


func finish_final_boss_reveal_immediately() -> void:
	_cancel_final_reveal_animation()
	set_level(MAX_LEVEL)
	activate()


func is_final_boss_reveal_playing() -> bool:
	return _final_reveal_playing


func take_damage(amount: int) -> bool:
	var damage := maxi(0, amount)
	if not can_be_targeted() or damage <= 0:
		return false

	_current_health = maxi(0, _current_health - damage)
	_tween_health_bar_to(_current_health)
	health_changed.emit(_current_health, maximum_health)
	if _current_health > 0:
		_play_damage_flash()
		return false

	_defeated_level = current_level
	_wave_active = false
	_minion_spawn_elapsed = 0.0
	_start_destroy_animation()
	return true


func can_be_targeted() -> bool:
	return active \
		and current_level >= combat_unlock_level \
		and not is_defeated() \
		and _current_health > 0


func is_defeated() -> bool:
	return _defeated_level == current_level


func is_destroying() -> bool:
	return _destroy_playing


func finish_destroy_immediately() -> void:
	if not _destroy_playing:
		return
	_cancel_destroy_animation()
	active = false
	_sync_visuals()
	defeated.emit(self)


func get_current_health() -> int:
	return _current_health


func get_maximum_health() -> int:
	return maximum_health


func get_minion_spawn_count(level: int = current_level) -> int:
	if minion_spawn_counts_by_level.is_empty():
		return 0
	var index := clampi(level - 1, 0, minion_spawn_counts_by_level.size() - 1)
	return maxi(0, minion_spawn_counts_by_level[index])


func _sync_visuals() -> void:
	var should_show := active and (
		not is_defeated() or _destroy_playing
	)
	visible = should_show
	var visible_level_index := clampi(current_level - 1, 0, MAX_LEVEL - 1)
	for index in range(_idle_animations.size()):
		var idle_sprite := _idle_animations[index]
		if idle_sprite == null:
			continue
		idle_sprite.visible = should_show \
			and not _activation_playing \
			and not _evolution_playing \
			and not _final_reveal_playing \
			and not _destroy_playing \
			and index == visible_level_index
		if idle_sprite.visible:
			_play_animation_if_needed(
				idle_sprite,
				IDLE_ANIMATION_NAMES[index]
			)
	for activate_sprite in _activate_animations:
		if activate_sprite != null:
			activate_sprite.visible = should_show \
				and _activation_playing \
				and not _destroy_playing \
				and activate_sprite == _active_activation_sprite
	for evolution_sprite in _evolution_animations:
		if evolution_sprite != null:
			evolution_sprite.visible = should_show \
				and _evolution_playing \
				and not _destroy_playing \
				and evolution_sprite == _active_evolution_sprite
	for reveal_sprite in _final_reveal_animations:
		if reveal_sprite != null:
			reveal_sprite.visible = should_show \
				and _final_reveal_playing \
				and not _destroy_playing \
				and reveal_sprite == _active_final_reveal_sprite
	if _destroy_animation != null:
		_destroy_animation.visible = should_show and _destroy_playing
	if _health_hud != null:
		_health_hud.set_bar_visible(should_show \
			and not _evolution_playing \
			and not _final_reveal_playing \
			and not _final_boss_health_suppressed \
			and (can_be_targeted() or _destroy_playing))


func _reset_for_new_level() -> void:
	_cancel_activation_animation()
	_cancel_final_reveal_animation()
	_cancel_destroy_animation()
	_defeated_level = 0
	_current_health = maximum_health
	_wave_active = false
	_minion_spawn_elapsed = 0.0
	_configure_health_bar()


func _spawn_minion_batch() -> void:
	var spawn_count := mini(get_minion_spawn_count(), _spawn_markers.size())
	if spawn_count <= 0:
		return

	var markers := _spawn_markers.duplicate()
	markers.shuffle()
	for index in range(spawn_count):
		var marker := markers[index] as Marker2D
		if marker != null:
			minion_spawn_requested.emit(marker.global_position, index)


func _play_activation_then_spawn() -> void:
	if _activation_playing or _evolution_playing:
		return
	var level_index := clampi(current_level - 1, 0, MAX_LEVEL - 1)
	var sprite := _get_animation_at(_activate_animations, level_index)
	if sprite == null:
		_minion_spawn_elapsed = maxf(
			0.0,
			_minion_spawn_elapsed - minion_spawn_interval
		)
		_spawn_minion_batch()
		return

	_activation_playing = true
	_active_activation_sprite = sprite
	var activating_level := current_level
	activation_animation_started.emit(activating_level)
	_sync_visuals()
	sprite.frame = 0
	sprite.play(ACTIVATE_ANIMATION_NAMES[level_index])
	await sprite.animation_finished

	if not is_instance_valid(sprite) \
			or sprite != _active_activation_sprite \
			or not _activation_playing:
		return
	_activation_playing = false
	_active_activation_sprite = null
	_minion_spawn_elapsed = maxf(
		0.0,
		_minion_spawn_elapsed - minion_spawn_interval
	)
	activation_animation_finished.emit(activating_level)
	_sync_visuals()
	if active \
			and _wave_active \
			and not is_defeated() \
			and current_level == activating_level:
		_spawn_minion_batch()


func _get_activation_duration(level: int) -> float:
	var index := clampi(level - 1, 0, MAX_LEVEL - 1)
	var sprite := _get_animation_at(_activate_animations, index)
	if sprite == null or sprite.sprite_frames == null:
		return 0.0
	var animation_name: StringName = ACTIVATE_ANIMATION_NAMES[index]
	if not sprite.sprite_frames.has_animation(animation_name):
		return 0.0
	var speed := sprite.sprite_frames.get_animation_speed(animation_name)
	var frame_count := sprite.sprite_frames.get_frame_count(animation_name)
	if speed <= 0.0 or frame_count <= 0:
		return 0.0
	return float(frame_count) / speed


func _resolve_animation_nodes(
	paths: Array[NodePath]
) -> Array[AnimatedSprite2D]:
	var sprites: Array[AnimatedSprite2D] = []
	for path in paths:
		sprites.append(get_node_or_null(path) as AnimatedSprite2D)
	return sprites


func _get_animation_at(
	sprites: Array[AnimatedSprite2D],
	index: int
) -> AnimatedSprite2D:
	if index < 0 or index >= sprites.size():
		return null
	return sprites[index]


func _play_animation_if_needed(
	sprite: AnimatedSprite2D,
	animation_name: StringName
) -> void:
	if sprite.animation != animation_name or not sprite.is_playing():
		sprite.play(animation_name)


func _cancel_activation_animation() -> void:
	_activation_playing = false
	if is_instance_valid(_active_activation_sprite):
		_active_activation_sprite.stop()
		_active_activation_sprite.visible = false
	_active_activation_sprite = null


func _cancel_evolution_animation() -> void:
	_evolution_playing = false
	if is_instance_valid(_active_evolution_sprite):
		_active_evolution_sprite.stop()
		_active_evolution_sprite.visible = false
	_active_evolution_sprite = null


func _cancel_final_reveal_animation() -> void:
	_final_reveal_serial += 1
	_final_reveal_playing = false
	if is_instance_valid(_active_final_reveal_sprite):
		_active_final_reveal_sprite.stop()
		_active_final_reveal_sprite.hide()
	_active_final_reveal_sprite = null


func _start_destroy_animation() -> void:
	_cancel_activation_animation()
	_cancel_evolution_animation()
	_cancel_final_reveal_animation()
	_destroy_serial += 1
	var serial := _destroy_serial
	_destroy_playing = true
	active = true
	_sync_visuals()
	if _health_hud != null:
		_health_hud.play_defeat_fade()
	if _destroy_animation == null \
			or _destroy_animation.sprite_frames == null \
			or not _destroy_animation.sprite_frames.has_animation(
				DESTROY_ANIMATION_NAME
			):
		_finish_destroy_animation(serial)
		return
	_destroy_animation.frame = 0
	_destroy_animation.frame_progress = 0.0
	_destroy_animation.play(DESTROY_ANIMATION_NAME)
	var duration := _get_sprite_animation_duration(
		_destroy_animation,
		DESTROY_ANIMATION_NAME
	)
	if duration > 0.0:
		await get_tree().create_timer(duration).timeout
	_finish_destroy_animation(serial)


func _finish_destroy_animation(serial: int) -> void:
	if serial != _destroy_serial or not _destroy_playing:
		return
	_destroy_playing = false
	if is_instance_valid(_destroy_animation):
		_destroy_animation.stop()
		_destroy_animation.hide()
	active = false
	_sync_visuals()
	defeated.emit(self)


func _cancel_destroy_animation() -> void:
	_destroy_serial += 1
	_destroy_playing = false
	if is_instance_valid(_destroy_animation):
		_destroy_animation.stop()
		_destroy_animation.hide()


func _play_final_reveal_clip(
	index: int,
	serial: int,
	hold_last_frame: bool
) -> void:
	var sprite := _get_animation_at(_final_reveal_animations, index)
	if sprite == null or index >= FINAL_REVEAL_ANIMATION_NAMES.size():
		return
	if is_instance_valid(_active_final_reveal_sprite) \
			and _active_final_reveal_sprite != sprite:
		_active_final_reveal_sprite.stop()
		_active_final_reveal_sprite.hide()
	_active_final_reveal_sprite = sprite
	_sync_visuals()
	var animation_name: StringName = FINAL_REVEAL_ANIMATION_NAMES[index]
	sprite.frame = 0
	sprite.frame_progress = 0.0
	sprite.play(animation_name)
	var duration := _get_sprite_animation_duration(sprite, animation_name)
	if duration > 0.0:
		await get_tree().create_timer(duration).timeout
	if serial != _final_reveal_serial \
			or not is_instance_valid(sprite):
		return
	sprite.stop()
	if hold_last_frame:
		sprite.frame = maxi(
			0,
			sprite.sprite_frames.get_frame_count(animation_name) - 1
		)
		sprite.frame_progress = 0.0
		sprite.show()
		final_reveal_clip_held.emit(index)
		return
	sprite.hide()
	_active_final_reveal_sprite = null


func _get_sprite_animation_duration(
	sprite: AnimatedSprite2D,
	animation_name: StringName
) -> float:
	if sprite.sprite_frames == null \
			or not sprite.sprite_frames.has_animation(animation_name):
		return 0.0
	var speed := sprite.sprite_frames.get_animation_speed(animation_name)
	speed *= maxf(0.001, absf(sprite.speed_scale))
	if speed <= 0.0:
		return 0.0
	var duration := 0.0
	for frame_index in range(
		sprite.sprite_frames.get_frame_count(animation_name)
	):
		duration += sprite.sprite_frames.get_frame_duration(
			animation_name,
			frame_index
		) / speed
	return duration


func _configure_health_bar() -> void:
	if _health_hud != null:
		_health_hud.set_health(
			_current_health,
			maximum_health,
			false
		)
	if _health_bar == null:
		return
	_health_bar.min_value = 0.0
	_health_bar.max_value = float(maximum_health)
	_health_bar.value = float(_current_health)
	_health_bar.show_percentage = false


func _tween_health_bar_to(value: int) -> void:
	if _health_hud != null:
		_health_hud.set_health(value, maximum_health, true)
		return
	if _health_bar == null:
		return
	if _health_tween != null and _health_tween.is_valid():
		_health_tween.kill()

	_health_tween = create_tween()
	_health_tween.tween_property(
		_health_bar,
		"value",
		float(value),
		0.18
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _play_damage_flash() -> void:
	if _damage_flash_tween != null and _damage_flash_tween.is_valid():
		_damage_flash_tween.kill()
	var visual_sprites := _get_all_animation_nodes()
	for sprite in visual_sprites:
		if sprite != null:
			sprite.self_modulate = Color(1.0, 0.16, 0.16, 1.0)

	_damage_flash_tween = create_tween()
	_damage_flash_tween.set_parallel(true)
	for sprite in visual_sprites:
		if sprite != null:
			_damage_flash_tween.tween_property(
				sprite,
				"self_modulate",
				Color.WHITE,
				damage_flash_seconds
			).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _get_all_animation_nodes() -> Array[AnimatedSprite2D]:
	var sprites: Array[AnimatedSprite2D] = []
	sprites.append_array(_idle_animations)
	sprites.append_array(_activate_animations)
	sprites.append_array(_evolution_animations)
	sprites.append_array(_final_reveal_animations)
	if _destroy_animation != null:
		sprites.append(_destroy_animation)
	return sprites
