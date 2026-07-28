class_name ZombieNode
extends Node2D

const CentralAudioResolver := preload("res://Scripts/Audio/audio_player_resolver.gd")
const ZombieNodeProgressBarScript := preload(
	"res://Scripts/UI/zombie_node_progress_bar.gd"
)

signal entrance_finished
signal level_changed(level: int)
signal minion_spawn_requested(spawn_global_position: Vector2, variant_index: int)
signal minion_activation_started
signal minion_activation_finished
signal evolution_animation_started(from_visual_level: int, to_visual_level: int)
signal evolution_animation_finished(to_visual_level: int)
signal destroy_animation_started
signal destroy_animation_finished
signal damage_taken(current_health: int, max_health: int)
signal defeated

const ENTRANCE_ANIMATION := &"entrance"
const DESTROY_ANIMATION := &"destroy_lv3"
const IDLE_ANIMATION_NAMES := [
	&"idle_lv1",
	&"idle_lv2",
	&"idle_lv3"
]
const ACTIVATION_ANIMATION_NAMES := [
	&"activate_lv1",
	&"activate_lv2",
	&"activate_lv3"
]
const EVOLUTION_ANIMATION_NAMES := [
	&"evolve_lv1_to_lv2",
	&"evolve_lv2_to_lv3"
]
const MAX_LEVEL := 5
const MINION_VARIANT_COUNT := 9

@export var max_health := 500
@export_group("Minion Spawning")
@export var spawn_markers_path: NodePath = ^"PossibleSpawnMarkers"
@export_range(1.0, 120.0, 0.5) var minion_spawn_interval := 20.0
@export_range(1.0, 120.0, 0.5) var final_form_spawn_interval := 10.0
@export_range(1.0, 120.0, 0.5) var critical_spawn_interval := 5.0
@export_range(0.1, 10.0, 0.1) var ability_activation_lead_seconds := 2.0
@export_range(0.05, 0.95, 0.01) var critical_health_ratio := 1.0 / 3.0
@export var minion_spawn_counts_by_level := PackedInt32Array([5, 5, 5, 8, 17])
@export_group("Visual Levels")
@export var entrance_sprite_path: NodePath = ^"EntranceAnimation"
@export var level_idle_sprite_paths: Array[NodePath] = [
	^"LV1IdleAnimation",
	^"LV2IdleAnimation",
	^"LV3IdleAnimation"
]
@export var level_activation_sprite_paths: Array[NodePath] = [
	^"LV1ActivateAnimation",
	^"LV2ActivateAnimation",
	^"LV3ActivateAnimation"
]
@export var level_evolution_sprite_paths: Array[NodePath] = [
	^"LV1ToLV2EvolveAnimation",
	^"LV2ToLV3EvolveAnimation"
]
@export var destroy_sprite_path: NodePath = ^"LV3DestroyAnimation"
@export_range(1, MAX_LEVEL, 1) var current_level := 1:
	set(value):
		var next_level := clampi(value, 1, MAX_LEVEL)
		if current_level == next_level:
			return
		var previous_level := current_level
		current_level = next_level
		if is_inside_tree():
			_sync_visuals()
			if active and current_level > previous_level \
					and not _evolution_playing:
				_play_audio_player(_evolution_sfx)
		level_changed.emit(current_level)
@export_group("Health Bar")
@export var health_bar_root_path: NodePath = ^"MinibossHealthBar"
@export var health_bar_follow_sprite_bounds := true
@export var health_bar_offset := Vector2.ZERO
@export_range(0.0, 220.0, 1.0) var health_bar_vertical_gap := 26.0
@export_group("")
@export_group("Audio")
@export var entrance_sfx_path: NodePath = ^"Sounds/ZombieNodeEntranceSfx"
@export var activate_sfx_path: NodePath = ^"Sounds/ZombieNodeActivateSfx"
@export var destroy_sfx_path: NodePath = ^"Sounds/ZombieNodeDestroySfx"
@export var evolution_sfx_path: NodePath = ^"Sounds/ZombieNodeEvolutionSfx"
@export_group("")
@export var active := false:
	set(value):
		active = value
		visible = active
		set_process(active)
		_set_health_bar_visible(active and _combat_unlocked and not _defeated)
		_sync_visuals()

var current_health := 500
var _wave_active := false
var _minion_spawn_elapsed := 0.0
var _anchor_global_position := Vector2.ZERO
var _health_bar: ZombieNodeProgressBarScript
var _entrance_playing := false
var _minion_activation_playing := false
var _evolution_playing := false
var _destroy_animation_playing := false
var _combat_unlocked := false
var _defeated := false
var _damage_flash_tween: Tween
var _entrance_sprite: AnimatedSprite2D
var _level_idle_sprites: Array[AnimatedSprite2D] = []
var _level_activation_sprites: Array[AnimatedSprite2D] = []
var _level_evolution_sprites: Array[AnimatedSprite2D] = []
var _active_activation_sprite: AnimatedSprite2D
var _active_evolution_sprite: AnimatedSprite2D
var _destroy_sprite: AnimatedSprite2D
var _spawn_rng := RandomNumberGenerator.new()
var _entrance_sfx: AudioStreamPlayer
var _activate_sfx: AudioStreamPlayer
var _destroy_sfx: AudioStreamPlayer
var _evolution_sfx: AudioStreamPlayer


func _ready() -> void:
	_spawn_rng.randomize()
	_resolve_audio_players()
	_cache_visuals()
	_anchor_global_position = global_position
	current_health = maxi(1, max_health)
	_ensure_health_bar()
	_set_health_bar_health(current_health, max_health, false)
	visible = active
	_set_health_bar_visible(active and _combat_unlocked and not _defeated)
	set_process(active)
	_sync_visuals()


func _process(delta: float) -> void:
	if not active:
		return

	_position_health_bar()
	if not _wave_active \
			or _entrance_playing \
			or _minion_activation_playing \
			or _evolution_playing:
		return

	_minion_spawn_elapsed += delta
	var spawn_trigger_delay := get_minion_spawn_trigger_delay()
	if _minion_spawn_elapsed >= spawn_trigger_delay:
		_minion_spawn_elapsed = 0.0
		_begin_timed_minion_spawn()


func activate() -> void:
	_stop_destroy_animation()
	_anchor_global_position = global_position
	_minion_spawn_elapsed = 0.0
	current_health = maxi(1, max_health)
	_defeated = false
	_ensure_health_bar()
	_set_health_bar_health(current_health, max_health, false)
	active = true
	_position_health_bar()


func deactivate() -> void:
	set_wave_active(false)
	_entrance_playing = false
	_cancel_evolution()
	_stop_destroy_animation()
	if _entrance_sprite != null:
		_entrance_sprite.stop()
	active = false
	global_position = _anchor_global_position


func set_combat_unlocked(value: bool) -> void:
	_combat_unlocked = value and not _defeated
	_set_health_bar_visible(active and _combat_unlocked)
	if _health_bar != null:
		_health_bar.set_critical_state(is_below_critical_health())


func is_combat_unlocked() -> bool:
	return _combat_unlocked


func can_be_targeted() -> bool:
	return active \
		and _combat_unlocked \
		and not _defeated \
		and current_health > 0


func take_damage(amount: int) -> bool:
	if amount <= 0 or not can_be_targeted():
		return false

	current_health = maxi(0, current_health - amount)
	_set_health_bar_health(current_health, max_health, true)
	if _health_bar != null:
		_health_bar.set_critical_state(is_below_critical_health())
	_play_damage_flash()
	damage_taken.emit(current_health, max_health)
	if current_health > 0:
		return false

	_defeated = true
	_combat_unlocked = false
	set_wave_active(false)
	if _health_bar != null:
		_health_bar.play_defeat_fade()
	defeated.emit()
	return true


func is_defeated() -> bool:
	return _defeated


func is_below_critical_health() -> bool:
	if max_health <= 0:
		return false
	return float(current_health) / float(max_health) <= critical_health_ratio


func complete_defeat() -> void:
	set_wave_active(false)
	_stop_destroy_animation()
	active = false
	hide()
	_set_health_bar_visible(false)


func retire_after_final_wave() -> void:
	_defeated = true
	_combat_unlocked = false
	current_health = 0
	complete_defeat()


func prepare_final_form_for_cutscene() -> void:
	prepare_evolution_for_cutscene()
	finish_evolution_immediately(MAX_LEVEL)


func prepare_evolution_for_cutscene() -> void:
	_cancel_minion_activation()
	_stop_destroy_animation()
	_combat_unlocked = false
	_defeated = false
	current_health = maxi(1, max_health)
	active = true
	_set_health_bar_health(current_health, max_health, false)
	_set_health_bar_visible(false)


func play_evolution_to_level(target_level: int) -> void:
	var clamped_target := clampi(target_level, 1, MAX_LEVEL)
	var from_visual_index := _get_visual_level_index_for_level(current_level)
	var to_visual_index := _get_visual_level_index_for_level(clamped_target)
	if clamped_target <= current_level or to_visual_index <= from_visual_index:
		set_level(clamped_target)
		return
	if to_visual_index != from_visual_index + 1:
		set_level(clamped_target)
		return

	var transition_index := from_visual_index
	var evolution_sprite := (
		_level_evolution_sprites[transition_index]
			if transition_index >= 0 \
				and transition_index < _level_evolution_sprites.size()
			else null
	)
	var animation_name: StringName = (
		EVOLUTION_ANIMATION_NAMES[transition_index]
			if transition_index >= 0 \
				and transition_index < EVOLUTION_ANIMATION_NAMES.size()
			else &""
	)
	if not _sprite_has_animation(evolution_sprite, animation_name):
		set_level(clamped_target)
		return

	_cancel_minion_activation()
	_evolution_playing = true
	_active_evolution_sprite = evolution_sprite
	active = true
	_sync_visuals()
	evolution_sprite.animation = animation_name
	evolution_sprite.frame = 0
	evolution_sprite.frame_progress = 0.0
	_play_audio_player(_evolution_sfx)
	evolution_animation_started.emit(
		from_visual_index + 1,
		to_visual_index + 1
	)
	evolution_sprite.play()
	while _evolution_playing \
			and active \
			and is_instance_valid(evolution_sprite) \
			and evolution_sprite.is_playing():
		await get_tree().process_frame

	if not _evolution_playing:
		return
	_finish_evolution(clamped_target)


func finish_evolution_immediately(target_level: int = MAX_LEVEL) -> void:
	var clamped_target := clampi(target_level, 1, MAX_LEVEL)
	if _evolution_playing:
		_finish_evolution(clamped_target)
	else:
		set_level(clamped_target)


func is_evolution_playing() -> bool:
	return _evolution_playing


func prepare_entrance() -> void:
	_cancel_minion_activation()
	_cancel_evolution()
	_stop_destroy_animation()
	active = false
	_entrance_playing = true
	visible = true
	_set_health_bar_visible(false)
	if _entrance_sprite != null:
		_entrance_sprite.stop()
		_entrance_sprite.animation = ENTRANCE_ANIMATION
		_entrance_sprite.frame = 0
		_entrance_sprite.frame_progress = 0.0
	_sync_visuals()


func play_entrance() -> void:
	if not _entrance_playing:
		prepare_entrance()
	if _entrance_sprite == null or _entrance_sprite.sprite_frames == null:
		_finish_entrance()
		return
	if not _entrance_sprite.sprite_frames.has_animation(ENTRANCE_ANIMATION):
		_finish_entrance()
		return

	_play_audio_player(_entrance_sfx)
	_entrance_sprite.play(ENTRANCE_ANIMATION)
	while _entrance_playing and _entrance_sprite.is_playing():
		await get_tree().process_frame
	if _entrance_playing:
		_finish_entrance()


func finish_entrance_immediately() -> void:
	if _entrance_sprite != null:
		_entrance_sprite.stop()
		if _entrance_sprite.sprite_frames != null \
				and _entrance_sprite.sprite_frames.has_animation(ENTRANCE_ANIMATION):
			var frame_count := _entrance_sprite.sprite_frames.get_frame_count(ENTRANCE_ANIMATION)
			if frame_count > 0:
				_entrance_sprite.frame = frame_count - 1
				_entrance_sprite.frame_progress = 1.0
	if _entrance_playing:
		_finish_entrance()
	elif not active:
		current_level = 1
		active = true


func set_level(value: int) -> void:
	current_level = value


func get_level() -> int:
	return current_level


func set_wave_active(value: bool) -> void:
	if _wave_active == value:
		return

	_wave_active = value
	_minion_spawn_elapsed = 0.0
	if not _wave_active:
		_cancel_minion_activation()


func is_wave_active() -> bool:
	return _wave_active


func is_minion_spawn_pending() -> bool:
	return _minion_activation_playing


func get_minion_spawn_count(level: int = current_level) -> int:
	if minion_spawn_counts_by_level.is_empty():
		return 0

	var index := clampi(level - 1, 0, minion_spawn_counts_by_level.size() - 1)
	return maxi(0, minion_spawn_counts_by_level[index])


func get_minion_activation_duration() -> float:
	var activation_sprite := _get_current_activation_sprite()
	var animation_name := _get_current_activation_animation_name()
	if not _sprite_has_animation(activation_sprite, animation_name):
		return 0.0

	return maxf(0.0, ability_activation_lead_seconds)


func get_minion_spawn_trigger_delay() -> float:
	return maxf(
		0.0,
		get_current_minion_spawn_interval() - get_minion_activation_duration()
	)


func get_current_minion_spawn_interval() -> float:
	if current_level < MAX_LEVEL:
		return minion_spawn_interval
	if is_below_critical_health():
		return critical_spawn_interval
	return final_form_spawn_interval


func request_minion_batch() -> int:
	if not active or not _wave_active or _entrance_playing:
		return 0

	var markers := _get_unique_spawn_markers()
	var spawn_count := mini(get_minion_spawn_count(), markers.size())
	if spawn_count <= 0:
		return 0

	for index in range(markers.size() - 1, 0, -1):
		var swap_index := _spawn_rng.randi_range(0, index)
		var marker := markers[index]
		markers[index] = markers[swap_index]
		markers[swap_index] = marker

	for index in range(spawn_count):
		minion_spawn_requested.emit(
			markers[index].global_position,
			_spawn_rng.randi_range(0, MINION_VARIANT_COUNT - 1)
		)

	return spawn_count


func _begin_timed_minion_spawn() -> void:
	_play_audio_player(_activate_sfx)
	var activation_sprite := _get_current_activation_sprite()
	var animation_name := _get_current_activation_animation_name()
	if not _sprite_has_animation(activation_sprite, animation_name):
		request_minion_batch()
		return

	_play_minion_activation_then_spawn(activation_sprite, animation_name)


func _play_minion_activation_then_spawn(
	activation_sprite: AnimatedSprite2D,
	animation_name: StringName
) -> void:
	if _minion_activation_playing or not active or not _wave_active:
		return

	_minion_activation_playing = true
	_active_activation_sprite = activation_sprite
	_sync_visuals()
	activation_sprite.animation = animation_name
	activation_sprite.frame = 0
	activation_sprite.frame_progress = 0.0
	activation_sprite.speed_scale = _get_activation_playback_speed(
		activation_sprite,
		animation_name
	)
	activation_sprite.play()
	minion_activation_started.emit()
	while _minion_activation_playing \
			and _wave_active \
			and active \
			and is_instance_valid(activation_sprite) \
			and activation_sprite.is_playing():
		await get_tree().process_frame

	if not _minion_activation_playing:
		return

	var should_spawn := _wave_active and active
	_minion_activation_playing = false
	activation_sprite.stop()
	activation_sprite.speed_scale = 1.0
	_active_activation_sprite = null
	_sync_visuals()
	minion_activation_finished.emit()
	if should_spawn:
		request_minion_batch()


func _cancel_minion_activation() -> void:
	if not _minion_activation_playing:
		return

	_minion_activation_playing = false
	if is_instance_valid(_active_activation_sprite):
		_active_activation_sprite.stop()
		_active_activation_sprite.speed_scale = 1.0
	_active_activation_sprite = null
	_sync_visuals()


func is_entrance_playing() -> bool:
	return _entrance_playing


func is_destroy_animation_playing() -> bool:
	return _destroy_animation_playing


func play_destroy_animation() -> void:
	if not active:
		complete_defeat()
		return
	_play_audio_player(_destroy_sfx)
	if not _sprite_has_animation(_destroy_sprite, DESTROY_ANIMATION):
		complete_defeat()
		return

	_cancel_minion_activation()
	_destroy_animation_playing = true
	_sync_visuals()
	_destroy_sprite.animation = DESTROY_ANIMATION
	_destroy_sprite.frame = 0
	_destroy_sprite.frame_progress = 0.0
	_destroy_sprite.play()
	destroy_animation_started.emit()
	while _destroy_animation_playing \
			and active \
			and is_instance_valid(_destroy_sprite) \
			and _destroy_sprite.is_playing():
		await get_tree().process_frame

	if not _destroy_animation_playing:
		return

	_destroy_animation_playing = false
	_destroy_sprite.stop()
	complete_defeat()
	destroy_animation_finished.emit()


func _resolve_audio_players() -> void:
	_entrance_sfx = CentralAudioResolver.resolve(self, entrance_sfx_path)
	_activate_sfx = CentralAudioResolver.resolve(self, activate_sfx_path)
	_destroy_sfx = CentralAudioResolver.resolve(self, destroy_sfx_path)
	_evolution_sfx = CentralAudioResolver.resolve(self, evolution_sfx_path)


func _play_audio_player(player: AudioStreamPlayer) -> void:
	if player == null:
		return
	player.stop()
	player.play()


func _finish_entrance() -> void:
	_entrance_playing = false
	current_level = 1
	active = true
	_sync_visuals()
	entrance_finished.emit()


func _cache_visuals() -> void:
	_entrance_sprite = get_node_or_null(entrance_sprite_path) as AnimatedSprite2D
	_destroy_sprite = get_node_or_null(
		destroy_sprite_path
	) as AnimatedSprite2D
	_level_idle_sprites.clear()
	for sprite_path in level_idle_sprite_paths:
		_level_idle_sprites.append(
			get_node_or_null(sprite_path) as AnimatedSprite2D
		)
	_level_activation_sprites.clear()
	for sprite_path in level_activation_sprite_paths:
		_level_activation_sprites.append(
			get_node_or_null(sprite_path) as AnimatedSprite2D
		)
	_level_evolution_sprites.clear()
	for sprite_path in level_evolution_sprite_paths:
		_level_evolution_sprites.append(
			get_node_or_null(sprite_path) as AnimatedSprite2D
		)


func _sync_visuals() -> void:
	if _entrance_sprite != null:
		_entrance_sprite.visible = _entrance_playing
	var visible_level_index := _get_visual_level_index()
	for index in range(_level_idle_sprites.size()):
		var idle_sprite := _level_idle_sprites[index]
		if idle_sprite != null:
			var should_show_idle := active \
				and not _entrance_playing \
				and not _minion_activation_playing \
				and not _evolution_playing \
				and not _destroy_animation_playing \
				and index == visible_level_index
			idle_sprite.visible = should_show_idle
			if should_show_idle:
				var idle_animation := _get_idle_animation_name(index)
				if idle_sprite.animation != idle_animation \
						or not idle_sprite.is_playing():
					idle_sprite.play(idle_animation)
			else:
				idle_sprite.stop()
	for activation_sprite in _level_activation_sprites:
		if activation_sprite == null:
			continue
		var should_show_activation := active \
			and not _entrance_playing \
			and _minion_activation_playing \
			and not _destroy_animation_playing \
			and activation_sprite == _active_activation_sprite
		activation_sprite.visible = should_show_activation
		if not should_show_activation:
			activation_sprite.stop()
	for evolution_sprite in _level_evolution_sprites:
		if evolution_sprite == null:
			continue
		var should_show_evolution := active \
			and not _entrance_playing \
			and _evolution_playing \
			and not _destroy_animation_playing \
			and evolution_sprite == _active_evolution_sprite
		evolution_sprite.visible = should_show_evolution
		if not should_show_evolution:
			evolution_sprite.stop()
	if _destroy_sprite != null:
		_destroy_sprite.visible = active \
			and not _entrance_playing \
			and not _evolution_playing \
			and _destroy_animation_playing
		if not _destroy_animation_playing:
			_destroy_sprite.stop()
	visible = active or _entrance_playing


func _finish_evolution(target_level: int) -> void:
	var completed_visual_level := _get_visual_level_index_for_level(
		target_level
	) + 1
	if is_instance_valid(_active_evolution_sprite):
		_active_evolution_sprite.stop()
	_evolution_playing = true
	current_level = target_level
	_evolution_playing = false
	_active_evolution_sprite = null
	_sync_visuals()
	evolution_animation_finished.emit(completed_visual_level)


func _cancel_evolution() -> void:
	if is_instance_valid(_active_evolution_sprite):
		_active_evolution_sprite.stop()
		_active_evolution_sprite.visible = false
	_evolution_playing = false
	_active_evolution_sprite = null


func _stop_destroy_animation() -> void:
	_destroy_animation_playing = false
	if is_instance_valid(_destroy_sprite):
		_destroy_sprite.stop()
		_destroy_sprite.visible = false


func _get_unique_spawn_markers() -> Array[Marker2D]:
	var result: Array[Marker2D] = []
	var marker_root := get_node_or_null(spawn_markers_path)
	if marker_root == null:
		return result

	var occupied_positions := {}
	for child in marker_root.get_children():
		var marker := child as Marker2D
		if marker == null:
			continue

		var position_key := Vector2i(
			roundi(marker.global_position.x * 10.0),
			roundi(marker.global_position.y * 10.0)
		)
		if occupied_positions.has(position_key):
			continue

		occupied_positions[position_key] = true
		result.append(marker)

	return result


func _ensure_health_bar() -> void:
	if is_instance_valid(_health_bar):
		return

	_health_bar = get_node_or_null(
		health_bar_root_path
	) as ZombieNodeProgressBarScript
	if not is_instance_valid(_health_bar):
		return

	_health_bar.top_level = true
	_health_bar.z_index = maxi(_health_bar.z_index, 700)
	_health_bar.modulate = Color.WHITE


func _set_health_bar_visible(value: bool) -> void:
	_ensure_health_bar()
	if not is_instance_valid(_health_bar):
		return

	_health_bar.set_bar_visible(value)


func _set_health_bar_health(current: int, maximum: int, animate: bool) -> void:
	_ensure_health_bar()
	if not is_instance_valid(_health_bar):
		return

	_health_bar.set_health(current, maxi(1, maximum), animate)


func _play_damage_flash() -> void:
	var sprite := _get_current_level_sprite()
	if sprite == null:
		return

	if _damage_flash_tween != null:
		_damage_flash_tween.kill()
	sprite.modulate = Color.WHITE
	_damage_flash_tween = create_tween()
	_damage_flash_tween.tween_property(
		sprite,
		"modulate",
		Color(1.0, 0.16, 0.12, 1.0),
		0.09
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_damage_flash_tween.tween_property(
		sprite,
		"modulate",
		Color.WHITE,
		0.16
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)


func _position_health_bar() -> void:
	if not is_instance_valid(_health_bar):
		return

	var target_position := global_position
	if health_bar_follow_sprite_bounds:
		target_position = _get_health_bar_follow_position()

	_health_bar.global_position = target_position + health_bar_offset
	_health_bar.global_rotation = 0.0


func _get_health_bar_follow_position() -> Vector2:
	var sprite_bounds := _get_sprite_global_bounds()
	return Vector2(
		sprite_bounds.position.x + sprite_bounds.size.x * 0.5,
		sprite_bounds.position.y - health_bar_vertical_gap
	)


func _get_sprite_global_bounds() -> Rect2:
	var _sprite := _get_current_level_sprite()
	var texture := _get_current_visual_texture(_sprite)
	if _sprite == null or texture == null:
		var fallback_size := Vector2(128, 128) * global_scale.abs()
		return Rect2(global_position - fallback_size * 0.5, fallback_size)

	var texture_size: Vector2 = texture.get_size()
	var local_top_left: Vector2 = (
		-texture_size * 0.5
			if _sprite.centered
			else Vector2.ZERO
	)
	local_top_left += _sprite.offset
	var corners := [
		local_top_left,
		local_top_left + Vector2(texture_size.x, 0.0),
		local_top_left + texture_size,
		local_top_left + Vector2(0.0, texture_size.y)
	]
	var bounds := Rect2(_sprite.global_transform * corners[0], Vector2.ZERO)
	for corner in corners:
		bounds = bounds.expand(_sprite.global_transform * corner)

	return bounds


func _get_current_visual_texture(
	sprite: AnimatedSprite2D
) -> Texture2D:
	if sprite == null \
			or sprite.sprite_frames == null \
			or not sprite.sprite_frames.has_animation(sprite.animation):
		return null
	var frame_count := sprite.sprite_frames.get_frame_count(
		sprite.animation
	)
	if frame_count <= 0:
		return null
	return sprite.sprite_frames.get_frame_texture(
		sprite.animation,
		clampi(sprite.frame, 0, frame_count - 1)
	)


func _get_current_level_sprite() -> AnimatedSprite2D:
	if _destroy_animation_playing and is_instance_valid(_destroy_sprite):
		return _destroy_sprite
	if _evolution_playing and is_instance_valid(_active_evolution_sprite):
		return _active_evolution_sprite
	if _minion_activation_playing \
			and is_instance_valid(_active_activation_sprite):
		return _active_activation_sprite
	var index := _get_visual_level_index()
	return (
		_level_idle_sprites[index]
			if index >= 0 and index < _level_idle_sprites.size()
			else null
	)


func _get_visual_level_index() -> int:
	return _get_visual_level_index_for_level(current_level)


func _get_visual_level_index_for_level(level: int) -> int:
	if level <= 1:
		return 0
	if level < MAX_LEVEL:
		return mini(1, _level_idle_sprites.size() - 1)
	return mini(2, _level_idle_sprites.size() - 1)


func _get_current_activation_sprite() -> AnimatedSprite2D:
	var index := _get_visual_level_index()
	return (
		_level_activation_sprites[index]
			if index >= 0 and index < _level_activation_sprites.size()
			else null
	)


func _get_idle_animation_name(index: int) -> StringName:
	return (
		IDLE_ANIMATION_NAMES[index]
			if index >= 0 and index < IDLE_ANIMATION_NAMES.size()
			else &""
	)


func _get_current_activation_animation_name() -> StringName:
	var index := _get_visual_level_index()
	return (
		ACTIVATION_ANIMATION_NAMES[index]
			if index >= 0 and index < ACTIVATION_ANIMATION_NAMES.size()
			else &""
	)


func _sprite_has_animation(
	sprite: AnimatedSprite2D,
	animation_name: StringName
) -> bool:
	return sprite != null \
		and sprite.sprite_frames != null \
		and not animation_name.is_empty() \
		and sprite.sprite_frames.has_animation(animation_name)


func _get_activation_playback_speed(
	sprite: AnimatedSprite2D,
	animation_name: StringName
) -> float:
	var native_duration := _get_animation_duration(sprite, animation_name)
	var target_duration := maxf(0.01, ability_activation_lead_seconds)
	return maxf(0.01, native_duration / target_duration)


func _get_animation_duration(
	sprite: AnimatedSprite2D,
	animation_name: StringName
) -> float:
	if not _sprite_has_animation(sprite, animation_name):
		return 0.0

	var frames := sprite.sprite_frames
	var frame_count := frames.get_frame_count(animation_name)
	var animation_speed := frames.get_animation_speed(animation_name)
	if frame_count <= 0 or animation_speed <= 0.0:
		return 0.0

	var duration_units := 0.0
	for frame_index in range(frame_count):
		duration_units += frames.get_frame_duration(
			animation_name,
			frame_index
		)
	return duration_units / animation_speed
