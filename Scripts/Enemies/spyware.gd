class_name Spyware
extends RedVirus

const SpywareAudioResolver := preload("res://Scripts/Audio/audio_player_resolver.gd")

signal knowledge_steal_requested(spyware: Spyware, amount: int)
signal hijack_started(spyware: Spyware, target: Node2D)
signal hijack_released(spyware: Spyware, target: Node2D)

const SIEM_KNOWLEDGE_VALUE := 3
const WALKING_ANIMATION := &"walking"
const APPEAR_ANIMATION := &"vfx_appear"
const ACTIVE_ANIMATION := &"vfx_active"
const DISAPPEAR_ANIMATION := &"vfx_disappear"
const DRAIN_LABEL_COLOR := Color(0.78, 0.68, 1.0, 1.0)
const HIJACK_VFX_Z_OFFSET := 2
const META_SPYWARE_LOCKED := &"spyware_locked"
const META_SPYWARE_OWNER := &"spyware_owner"
const META_SPYWARE_RESERVED_BY := &"spyware_reserved_by"
const META_PREVIOUS_PROCESS := &"spyware_previous_process"
const META_PREVIOUS_PHYSICS_PROCESS := &"spyware_previous_physics_process"

@export_group("Knowledge Hijack")
@export_range(0.0, 1.0, 0.01) var activation_progress_ratio := 0.0
@export_range(0.1, 10.0, 0.1) var steal_interval_seconds := 1.0
@export_range(1, 20, 1) var steal_amount := 1
@export_group("Tower Invasion")
@export_range(10.0, 500.0, 1.0) var invasion_walk_speed := 100.0
@export var invasion_front_offset := Vector2(0.0, 78.0)
@export_range(1.0, 40.0, 1.0) var invasion_arrival_distance := 5.0
@export_range(0.0, 120.0, 1.0) var path_exit_margin := 24.0
@export_range(0.0, 20.0, 0.5) var path_departure_tolerance := 2.0
@export_range(1.0, 64.0, 1.0) var path_facing_sample_distance := 8.0
@export_range(-180.0, 180.0, 1.0) var south_facing_rotation_degrees := 0.0
@export var invasion_z_index := 180
@export_group("Editable Visual Nodes")
@export var walking_visual_path: NodePath = ^"WalkingVisual"
@export var appear_vfx_path: NodePath = ^"AppearVFX"
@export var active_vfx_path: NodePath = ^"ActiveVFX"
@export var disappear_vfx_path: NodePath = ^"DisappearVFX"
@export var health_bar_path: NodePath = ^"MinibossHealthBar"
@export var drain_label_path: NodePath = ^"DrainLabel"
@export_group("")
@export_group("Audio")
@export var hijack_sfx_path: NodePath = ^"Sounds/SpywareHijackSfx"
@export var spyware_destroy_sfx_path: NodePath = ^"Sounds/SpywareDestroySfx"
@export_group("")

var _steal_elapsed := 0.0
var _invasion_target: Node2D
var _invasion_active := false
var _path_departure_progress := -1.0
var _arrived_at_target := false
var _tower_lock_active := false
var _target_was_processing := false
var _target_was_physics_processing := false
var _path_z_index := 0
var _path_z_as_relative := true
var _appear_remaining := 0.0
var _rng := RandomNumberGenerator.new()
var _walking_visual: AnimatedSprite2D
var _appear_vfx: AnimatedSprite2D
var _active_vfx: AnimatedSprite2D
var _disappear_vfx: AnimatedSprite2D
var _health_bar: SpywareProgressBar
var _drain_label: Label
var _drain_pulse_tween: Tween
var _hijack_vfx_defaults := {}
var _hijack_sfx: AudioStreamPlayer
var _spyware_destroy_sfx: AudioStreamPlayer


func _ready() -> void:
	_resolve_editable_nodes()
	_hijack_sfx = SpywareAudioResolver.resolve(self, hijack_sfx_path)
	_spyware_destroy_sfx = SpywareAudioResolver.resolve(
		self,
		spyware_destroy_sfx_path
	)
	_capture_hijack_vfx_defaults()
	_path_z_index = z_index
	_path_z_as_relative = z_as_relative
	_rng.randomize()
	super._ready()
	if not health_changed.is_connected(_on_health_changed):
		health_changed.connect(_on_health_changed)
	_reset_visual_state()
	_sync_health_bar(false)


func _process(_delta: float) -> void:
	if _invasion_active:
		return

	var follow := get_parent() as PathFollow2D
	if follow == null:
		return
	_preserve_visual_transform_on_path()
	_face_path_direction(follow)


func reset_for_spawn() -> void:
	_release_tower_hijack()
	_clear_target_reservation()
	_steal_elapsed = 0.0
	_invasion_target = null
	_invasion_active = false
	_path_departure_progress = -1.0
	_arrived_at_target = false
	_appear_remaining = 0.0
	_restore_path_parenting()
	_clear_drain_pulse()
	super.reset_for_spawn()
	_reset_visual_state()
	_sync_health_bar(false)


func take_damage(amount: int) -> bool:
	var destroyed := super.take_damage(amount)
	if destroyed:
		_play_audio_player(_spyware_destroy_sfx)
		_release_tower_hijack()
		_clear_target_reservation()
	return destroyed


func play_destroy_and_queue_owner(owner: Node) -> void:
	_release_tower_hijack()
	_clear_target_reservation()
	_hide_non_destroy_visuals()

	var duration := destroy_duration
	if _has_animation(_disappear_vfx, DISAPPEAR_ANIMATION):
		_disappear_vfx.show()
		_play_animation(_disappear_vfx, DISAPPEAR_ANIMATION)
		duration = _get_visual_animation_duration(
			_disappear_vfx,
			DISAPPEAR_ANIMATION,
			destroy_duration
		)

	var tween := create_tween()
	tween.tween_interval(duration)
	tween.set_parallel(true)
	if _disappear_vfx != null:
		tween.tween_property(_disappear_vfx, "modulate:a", 0.0, 0.2)
	if _walking_visual != null:
		tween.tween_property(_walking_visual, "modulate:a", 0.0, 0.2)
	if _health_bar != null:
		tween.tween_property(_health_bar, "modulate:a", 0.0, 0.2)
	tween.set_parallel(false)
	if owner != null:
		tween.tween_callback(Callable(owner, "queue_free"))
	else:
		tween.tween_callback(Callable(self, "queue_free"))


func on_path_escaped() -> void:
	_release_tower_hijack()
	_clear_target_reservation()


func report_knowledge_stolen(amount: int) -> void:
	if amount > 0:
		_play_drain_pulse()


func get_siem_knowledge_value() -> int:
	return SIEM_KNOWLEDGE_VALUE


func uses_path_movement() -> bool:
	return not _invasion_active


func is_invading_tower() -> bool:
	return is_instance_valid(_invasion_target)


func is_waiting_for_path_departure() -> bool:
	return is_instance_valid(_invasion_target) and not _invasion_active


func get_path_departure_progress() -> float:
	return _path_departure_progress


func has_reached_invasion_target() -> bool:
	return _arrived_at_target and _tower_lock_active


func is_high_priority_target() -> bool:
	return has_reached_invasion_target() and not is_destroying()


func is_low_priority_target() -> bool:
	return not has_reached_invasion_target() and not is_destroying()


func get_invasion_target() -> Node2D:
	return _invasion_target


func update_invasion(delta: float, eligible_towers: Array[Node2D]) -> void:
	if is_destroying():
		return

	var follow := get_parent() as PathFollow2D
	if not is_instance_valid(_invasion_target):
		if follow == null or follow.progress_ratio < activation_progress_ratio:
			return
		var random_tower := _pick_random_eligible_tower(eligible_towers)
		if random_tower == null:
			return
		_plan_tower_invasion(random_tower, follow)
	elif not _is_current_target_available():
		_release_tower_hijack()
		_clear_target_reservation()
		var replacement_target := _pick_random_eligible_tower(eligible_towers)
		if replacement_target == null:
			_abandon_tower_invasion()
			return
		if _invasion_active:
			_reserve_target(replacement_target)
			_invasion_target = replacement_target
			_arrived_at_target = false
			_steal_elapsed = 0.0
		else:
			_plan_tower_invasion(replacement_target, follow)

	if not _invasion_active:
		if follow == null \
				or follow.progress + path_departure_tolerance \
					>= _path_departure_progress:
			_detach_from_path()
		else:
			return

	var target_position := _get_invasion_anchor_position(_invasion_target)
	if not _arrived_at_target:
		var direction := global_position.direction_to(target_position)
		global_position = global_position.move_toward(
			target_position,
			maxf(0.0, invasion_walk_speed) * delta
		)
		_face_movement_direction(direction)
		if global_position.distance_squared_to(target_position) \
				<= invasion_arrival_distance * invasion_arrival_distance:
			global_position = target_position
			_activate_tower_hijack()
	else:
		global_position = target_position

	if _arrived_at_target:
		_sync_hijack_vfx_position()
		_update_appear_transition(delta)
		_update_knowledge_theft(delta)


func get_grab_rect() -> Rect2:
	if _walking_visual == null \
			or _walking_visual.sprite_frames == null \
			or not _walking_visual.sprite_frames.has_animation(_walking_visual.animation):
		return super.get_grab_rect()

	var texture := _walking_visual.sprite_frames.get_frame_texture(
		_walking_visual.animation,
		_walking_visual.frame
	)
	if texture == null:
		return super.get_grab_rect()
	var size := texture.get_size() * Vector2(
		abs(_walking_visual.global_scale.x),
		abs(_walking_visual.global_scale.y)
	)
	return Rect2(_walking_visual.global_position - size * 0.5, size)


func _update_knowledge_theft(delta: float) -> void:
	if not _tower_lock_active or are_abilities_nullified():
		return

	_steal_elapsed += delta
	while _steal_elapsed >= steal_interval_seconds:
		_steal_elapsed -= steal_interval_seconds
		knowledge_steal_requested.emit(self, steal_amount)


func _pick_random_eligible_tower(eligible_towers: Array[Node2D]) -> Node2D:
	var candidates: Array[Node2D] = []
	for tower in eligible_towers:
		if _is_tower_available(tower):
			candidates.append(tower)
	if candidates.is_empty():
		return null
	return candidates[_rng.randi_range(0, candidates.size() - 1)]


func _is_tower_available(tower: Node2D) -> bool:
	if not is_instance_valid(tower) \
			or not tower.has_method("is_placed") \
			or not bool(tower.call("is_placed")):
		return false
	if tower.has_method("is_spyware_knowledge_source") \
			and not bool(tower.call("is_spyware_knowledge_source")):
		return false
	if bool(tower.get_meta("ransom_locked", false)):
		return false

	_clear_stale_tower_hijack(tower)
	var reserved_owner: Node
	if tower.has_meta(META_SPYWARE_RESERVED_BY):
		reserved_owner = tower.get_meta(META_SPYWARE_RESERVED_BY) as Node
	if is_instance_valid(reserved_owner) and reserved_owner != self:
		return false
	var lock_owner: Node
	if tower.has_meta(META_SPYWARE_OWNER):
		lock_owner = tower.get_meta(META_SPYWARE_OWNER) as Node
	return not is_instance_valid(lock_owner) or lock_owner == self


func _is_current_target_available() -> bool:
	return _is_tower_available(_invasion_target)


func _clear_stale_tower_hijack(tower: Node2D) -> void:
	if not is_instance_valid(tower):
		return

	if tower.has_meta(META_SPYWARE_RESERVED_BY):
		var reservation_owner := tower.get_meta(
			META_SPYWARE_RESERVED_BY
		) as Node
		if not is_instance_valid(reservation_owner):
			tower.remove_meta(META_SPYWARE_RESERVED_BY)

	var lock_owner: Node
	if tower.has_meta(META_SPYWARE_OWNER):
		lock_owner = tower.get_meta(META_SPYWARE_OWNER) as Node
	if is_instance_valid(lock_owner):
		return
	if not tower.has_meta(META_SPYWARE_LOCKED) \
			and not tower.has_meta(META_SPYWARE_OWNER):
		return

	_restore_tower_process_state(tower)
	tower.remove_meta(META_SPYWARE_OWNER)
	tower.remove_meta(META_SPYWARE_LOCKED)


func _restore_tower_process_state(tower: Node2D) -> void:
	if not is_instance_valid(tower):
		return
	var restore_process := bool(
		tower.get_meta(META_PREVIOUS_PROCESS, true)
	)
	var restore_physics_process := bool(
		tower.get_meta(META_PREVIOUS_PHYSICS_PROCESS, true)
	)
	tower.set_process(restore_process)
	tower.set_physics_process(restore_physics_process)
	if tower.has_meta(META_PREVIOUS_PROCESS):
		tower.remove_meta(META_PREVIOUS_PROCESS)
	if tower.has_meta(META_PREVIOUS_PHYSICS_PROCESS):
		tower.remove_meta(META_PREVIOUS_PHYSICS_PROCESS)


func _get_invasion_anchor_position(tower: Node2D) -> Vector2:
	if tower == null:
		return global_position
	return _get_tower_anchor_position(tower) + invasion_front_offset


func _get_tower_anchor_position(tower: Node2D) -> Vector2:
	if tower == null:
		return global_position
	var tower_position := tower.global_position
	if tower.has_method("get_headquarters_position"):
		tower_position = tower.call("get_headquarters_position") as Vector2
	return tower_position


func _plan_tower_invasion(
	tower: Node2D,
	follow: PathFollow2D
) -> void:
	_reserve_target(tower)
	_invasion_target = tower
	_invasion_active = false
	_arrived_at_target = false
	_steal_elapsed = 0.0
	_path_departure_progress = _calculate_path_departure_progress(
		follow,
		tower
	)


func _calculate_path_departure_progress(
	follow: PathFollow2D,
	tower: Node2D
) -> float:
	if follow == null:
		return 0.0
	var path := follow.get_parent() as Path2D
	if path == null or path.curve == null:
		return follow.progress

	var path_length := path.curve.get_baked_length()
	if path_length <= 0.0:
		return follow.progress
	var target_local_position := path.to_local(
		_get_invasion_anchor_position(tower)
	)
	var closest_progress := path.curve.get_closest_offset(
		target_local_position
	)
	var safe_path_end := maxf(
		0.0,
		path_length - maxf(0.0, path_exit_margin)
	)
	closest_progress = minf(closest_progress, safe_path_end)
	return maxf(follow.progress, closest_progress)


func _detach_from_path() -> void:
	var preserved_transform := global_transform
	top_level = true
	global_transform = preserved_transform
	_invasion_active = true
	_path_departure_progress = -1.0
	_arrived_at_target = false
	_steal_elapsed = 0.0
	z_as_relative = false
	z_index = invasion_z_index


func _activate_tower_hijack() -> void:
	if not is_instance_valid(_invasion_target):
		return
	_arrived_at_target = true
	_tower_lock_active = true
	_steal_elapsed = 0.0
	_target_was_processing = _invasion_target.is_processing()
	_target_was_physics_processing = _invasion_target.is_physics_processing()
	_invasion_target.set_meta(META_SPYWARE_LOCKED, true)
	_invasion_target.set_meta(META_SPYWARE_OWNER, self)
	_invasion_target.set_meta(
		META_PREVIOUS_PROCESS,
		_target_was_processing
	)
	_invasion_target.set_meta(
		META_PREVIOUS_PHYSICS_PROCESS,
		_target_was_physics_processing
	)
	_invasion_target.set_process(false)
	_invasion_target.set_physics_process(false)
	if _invasion_target.has_meta(META_SPYWARE_RESERVED_BY) \
			and _invasion_target.get_meta(META_SPYWARE_RESERVED_BY) == self:
		_invasion_target.remove_meta(META_SPYWARE_RESERVED_BY)
	if _walking_visual != null:
		_walking_visual.rotation = deg_to_rad(
			south_facing_rotation_degrees
		)
	_attach_hijack_vfx_to_target()
	_start_appear_vfx()
	_play_audio_player(_hijack_sfx)
	if _drain_label != null:
		_drain_label.show()
	hijack_started.emit(self, _invasion_target)


func _play_audio_player(player: AudioStreamPlayer) -> void:
	if player == null:
		return
	player.stop()
	player.play()


func _release_tower_hijack() -> void:
	if not _tower_lock_active:
		_restore_hijack_vfx_parenting()
		return
	var released_target := _invasion_target
	_tower_lock_active = false
	if is_instance_valid(released_target):
		if released_target.has_meta(META_SPYWARE_OWNER) \
				and released_target.get_meta(META_SPYWARE_OWNER) == self:
			_restore_tower_process_state(released_target)
			released_target.remove_meta(META_SPYWARE_OWNER)
			released_target.remove_meta(META_SPYWARE_LOCKED)
			hijack_released.emit(self, released_target)
		if released_target.has_meta(META_SPYWARE_RESERVED_BY) \
				and released_target.get_meta(META_SPYWARE_RESERVED_BY) == self:
			released_target.remove_meta(META_SPYWARE_RESERVED_BY)
	_restore_hijack_vfx_parenting()


func _reserve_target(tower: Node2D) -> void:
	if is_instance_valid(tower):
		_clear_stale_tower_hijack(tower)
		tower.set_meta(META_SPYWARE_RESERVED_BY, self)


func _clear_target_reservation() -> void:
	if is_instance_valid(_invasion_target) \
			and _invasion_target.has_meta(META_SPYWARE_RESERVED_BY) \
			and _invasion_target.get_meta(META_SPYWARE_RESERVED_BY) == self:
		_invasion_target.remove_meta(META_SPYWARE_RESERVED_BY)


func _abandon_tower_invasion() -> void:
	_release_tower_hijack()
	_clear_target_reservation()
	_invasion_target = null
	_invasion_active = false
	_path_departure_progress = -1.0
	_arrived_at_target = false
	_steal_elapsed = 0.0
	_restore_path_parenting()


func _restore_path_parenting() -> void:
	if top_level:
		top_level = false
	position = Vector2.ZERO
	_path_departure_progress = -1.0
	z_index = _path_z_index
	z_as_relative = _path_z_as_relative


func _face_path_direction(follow: PathFollow2D) -> void:
	var path := follow.get_parent() as Path2D
	if path == null or path.curve == null:
		return
	var path_length := path.curve.get_baked_length()
	if path_length <= 0.0:
		return

	var sample_distance := maxf(1.0, path_facing_sample_distance)
	var current_progress := clampf(follow.progress, 0.0, path_length)
	var before_progress := maxf(0.0, current_progress - sample_distance)
	var after_progress := minf(path_length, current_progress + sample_distance)
	if is_equal_approx(before_progress, after_progress):
		return

	var before_position := path.to_global(
		path.curve.sample_baked(before_progress)
	)
	var after_position := path.to_global(
		path.curve.sample_baked(after_progress)
	)
	_face_movement_direction(before_position.direction_to(after_position))


func _face_movement_direction(direction: Vector2) -> void:
	if _walking_visual == null or direction.length_squared() <= 0.001:
		return
	_walking_visual.rotation = (
		deg_to_rad(south_facing_rotation_degrees)
		+ direction.angle()
		- PI * 0.5
	)


func _capture_hijack_vfx_defaults() -> void:
	if not _hijack_vfx_defaults.is_empty():
		return
	for vfx in [_appear_vfx, _active_vfx]:
		if vfx == null:
			continue
		_hijack_vfx_defaults[vfx] = {
			"parent": vfx.get_parent(),
			"transform": vfx.transform,
			"z_index": vfx.z_index,
			"z_as_relative": vfx.z_as_relative,
		}


func _attach_hijack_vfx_to_target() -> void:
	if not is_instance_valid(_invasion_target):
		return
	_capture_hijack_vfx_defaults()
	for vfx in [_appear_vfx, _active_vfx]:
		if not is_instance_valid(vfx):
			continue
		if vfx.get_parent() != _invasion_target:
			vfx.reparent(_invasion_target, true)
		vfx.z_as_relative = false
		vfx.z_index = invasion_z_index + HIJACK_VFX_Z_OFFSET
	_sync_hijack_vfx_position()


func _sync_hijack_vfx_position() -> void:
	if not is_instance_valid(_invasion_target):
		return
	var target_position := _get_tower_anchor_position(_invasion_target)
	for vfx in [_appear_vfx, _active_vfx]:
		if not is_instance_valid(vfx) or vfx.get_parent() != _invasion_target:
			continue
		vfx.global_position = target_position
		vfx.global_rotation = 0.0


func _restore_hijack_vfx_parenting() -> void:
	for vfx in [_appear_vfx, _active_vfx]:
		if not is_instance_valid(vfx):
			continue
		vfx.hide()
		vfx.stop()
		if not _hijack_vfx_defaults.has(vfx):
			continue
		var defaults: Dictionary = _hijack_vfx_defaults[vfx]
		var home_parent := defaults.get("parent") as Node
		if not is_instance_valid(home_parent):
			home_parent = self
		if vfx.get_parent() != home_parent:
			vfx.reparent(home_parent, false)
		vfx.transform = defaults.get(
			"transform",
			Transform2D.IDENTITY
		) as Transform2D
		vfx.z_index = int(defaults.get("z_index", 0))
		vfx.z_as_relative = bool(
			defaults.get("z_as_relative", true)
		)


func _start_appear_vfx() -> void:
	if _active_vfx != null:
		_active_vfx.hide()
		_active_vfx.stop()
	if not _has_animation(_appear_vfx, APPEAR_ANIMATION):
		_start_active_vfx()
		return
	_appear_vfx.show()
	_play_animation(_appear_vfx, APPEAR_ANIMATION)
	_appear_remaining = _get_visual_animation_duration(
		_appear_vfx,
		APPEAR_ANIMATION,
		0.1
	)


func _update_appear_transition(delta: float) -> void:
	if _appear_remaining <= 0.0:
		return
	_appear_remaining = maxf(0.0, _appear_remaining - delta)
	if _appear_remaining <= 0.0:
		if _appear_vfx != null:
			_appear_vfx.hide()
			_appear_vfx.stop()
		_start_active_vfx()


func _start_active_vfx() -> void:
	if _has_animation(_active_vfx, ACTIVE_ANIMATION):
		_active_vfx.show()
		_play_animation(_active_vfx, ACTIVE_ANIMATION)


func _reset_visual_state() -> void:
	_resolve_editable_nodes()
	if _walking_visual != null:
		_walking_visual.show()
		_walking_visual.rotation = deg_to_rad(
			south_facing_rotation_degrees
		)
		_walking_visual.modulate = Color.WHITE
		_play_animation(_walking_visual, WALKING_ANIMATION)
	for vfx in [_appear_vfx, _active_vfx, _disappear_vfx]:
		if vfx != null:
			vfx.hide()
			vfx.stop()
			vfx.modulate = Color.WHITE
	if _health_bar != null:
		_health_bar.set_bar_visible(true)
	if _drain_label != null:
		_drain_label.hide()
		_drain_label.add_theme_color_override("font_color", DRAIN_LABEL_COLOR)


func _hide_non_destroy_visuals() -> void:
	if _walking_visual != null:
		_walking_visual.stop()
		_walking_visual.show()
	for vfx in [_appear_vfx, _active_vfx]:
		if vfx != null:
			vfx.hide()
			vfx.stop()
	if _drain_label != null:
		_drain_label.hide()


func _resolve_editable_nodes() -> void:
	_walking_visual = get_node_or_null(walking_visual_path) as AnimatedSprite2D
	_appear_vfx = get_node_or_null(appear_vfx_path) as AnimatedSprite2D
	_active_vfx = get_node_or_null(active_vfx_path) as AnimatedSprite2D
	_disappear_vfx = get_node_or_null(disappear_vfx_path) as AnimatedSprite2D
	_health_bar = get_node_or_null(health_bar_path) as SpywareProgressBar
	_drain_label = get_node_or_null(drain_label_path) as Label


func _on_health_changed(_current_health: int, _max_health: int) -> void:
	_sync_health_bar(true)


func _sync_health_bar(animate: bool) -> void:
	if _health_bar != null:
		_health_bar.set_health(current_health, maxi(1, max_health), animate)


func _play_drain_pulse() -> void:
	if _drain_label == null:
		return
	if _drain_pulse_tween != null:
		_drain_pulse_tween.kill()
	_drain_label.scale = Vector2.ONE
	_drain_label.modulate = Color.WHITE
	_drain_pulse_tween = create_tween()
	_drain_pulse_tween.tween_property(
		_drain_label,
		"scale",
		Vector2(1.1, 1.1),
		0.1
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_drain_pulse_tween.tween_property(
		_drain_label,
		"scale",
		Vector2.ONE,
		0.18
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_drain_pulse_tween.tween_callback(func() -> void:
		_drain_pulse_tween = null
	)


func _clear_drain_pulse() -> void:
	if _drain_pulse_tween != null:
		_drain_pulse_tween.kill()
		_drain_pulse_tween = null
	if _drain_label != null:
		_drain_label.scale = Vector2.ONE
		_drain_label.modulate = Color.WHITE


func _has_animation(sprite: AnimatedSprite2D, animation_name: StringName) -> bool:
	return sprite != null \
		and sprite.sprite_frames != null \
		and sprite.sprite_frames.has_animation(animation_name)


func _play_animation(sprite: AnimatedSprite2D, animation_name: StringName) -> void:
	if not _has_animation(sprite, animation_name):
		return
	sprite.animation = animation_name
	sprite.frame = 0
	sprite.frame_progress = 0.0
	sprite.play()


func _exit_tree() -> void:
	_release_tower_hijack()
	_clear_target_reservation()
