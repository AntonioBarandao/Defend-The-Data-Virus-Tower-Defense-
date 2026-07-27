class_name WormBoss
extends Node2D

const CentralAudioResolver := preload("res://Scripts/Audio/audio_player_resolver.gd")
const WormBossPartTargetScript := preload(
	"res://Scripts/Enemies/worm_boss_part_target.gd"
)

signal health_changed(current_health: int, max_health: int)
signal defeated
signal escaped

const STATE_INACTIVE := &"inactive"
const STATE_PREVIEW := &"preview"
const STATE_ACTIVE := &"active"
const STATE_DESTROYING := &"destroying"
const STATE_DEFEATED := &"defeated"
const STATE_ESCAPED := &"escaped"
const PART_HEAD := &"head"
const PART_BODY := &"body"
const PART_TAIL := &"tail"

@export var max_health := 950
@export_range(1.0, 200.0, 1.0) var path_speed := 25.0
@export_range(0.25, 2.0, 0.01) var segment_spacing_multiplier := 1.0
@export_range(1.0, 64.0, 1.0) var path_rotation_sample_distance := 12.0
@export_group("Visual Parts")
@export var head_path: NodePath = ^"HeadAnimation"
@export var body_part_paths: Array[NodePath] = [
	^"Body_First",
	^"Body_Second",
	^"Body_Third",
	^"Body_Fourth",
	^"Body_Fifth",
]
@export var tail_path: NodePath = ^"Tail"
@export_group("Destroy Visuals")
@export var head_destroy_path: NodePath = ^"Head_Destroy"
@export var body_destroy_paths: Array[NodePath] = [
	^"Body_First_Destroy",
	^"Body_Second_Destroy",
	^"Body_Third_Destroy",
	^"Body_Fourth_Destroy",
	^"Body_Fifth_Destroy",
]
@export var tail_destroy_path: NodePath = ^"Tail_Destroy"
@export_range(0.1, 2.0, 0.05) var destroy_fade_duration := 0.65
@export_group("Health HUD")
@export var health_hud_path: NodePath = ^"BossHealthHUD"
@export_group("Hit Reactions")
@export var body_damage_flash_color := Color(1.0, 0.08, 0.06, 1.0)
@export var shield_flash_color := Color(2.2, 2.2, 2.2, 1.0)
@export var nullifier_highlight_color := Color(0.72, 0.26, 1.0, 1.0)
@export_range(0.05, 1.0, 0.01) var body_flash_duration := 0.16
@export_range(0.05, 1.0, 0.01) var shield_flash_duration := 0.22
@export_range(1.0, 1.25, 0.01) var shield_flash_scale := 1.06
@export_group("")
@export_group("Audio")
@export var entrance_sfx_path: NodePath = ^"Sounds/CyberWormEntranceSfx"
@export var destroy_sfx_path: NodePath = ^"Sounds/CyberWormDestroySfx"
@export_group("")

var current_health := 950
var _state := STATE_INACTIVE
var _wave_active := false
var _path: Path2D
var _head_progress := 0.0
var _path_length := 0.0
var _part_visuals: Array[Node2D] = []
var _part_kinds: Array[StringName] = []
var _part_offsets: Array[float] = []
var _part_authored_transforms: Array[Transform2D] = []
var _part_authored_global_scales: Array[Vector2] = []
var _destroy_visuals: Array[AnimatedSprite2D] = []
var _destroy_animation_names: Array[StringName] = []
var _destroy_authored_transforms: Array[Transform2D] = []
var _destroy_relative_transforms: Array[Transform2D] = []
var _part_targets: Array[PathFollow2D] = []
var _part_flash_tweens: Dictionary = {}
var _nullifier_suppressed_parts: Dictionary = {}
var _health_hud: WormBossProgressBar
var _emerged_segment_count := 0
var _authored_cutscene_global_transform := Transform2D.IDENTITY
var _defeat_fade_tween: Tween
var _lifecycle_serial := 0
var _defeat_part_indices: Array[int] = []
var _entrance_sfx: AudioStreamPlayer
var _destroy_sfx: AudioStreamPlayer


func _ready() -> void:
	_authored_cutscene_global_transform = global_transform
	_cache_parts()
	_cache_destroy_visuals()
	_capture_authored_part_transforms()
	_capture_authored_destroy_transforms()
	_build_part_offsets()
	_health_hud = get_node_or_null(health_hud_path) as WormBossProgressBar
	_entrance_sfx = CentralAudioResolver.resolve(self, entrance_sfx_path)
	_destroy_sfx = CentralAudioResolver.resolve(self, destroy_sfx_path)
	current_health = maxi(1, max_health)
	_sync_health(false)
	deactivate()


func _process(delta: float) -> void:
	if _state != STATE_ACTIVE or not _wave_active:
		return
	if _path == null or _path.curve == null or _path_length <= 0.0:
		return

	_head_progress += maxf(0.0, path_speed) * delta
	_sync_parts_to_path()
	if _tail_has_exited():
		_finish_escape()


func prepare_cutscene_preview(anchor_global_position: Vector2) -> void:
	_play_audio_player(_entrance_sfx)
	_lifecycle_serial += 1
	_defeat_part_indices.clear()
	_clear_nullifier_suppression()
	_cleanup_targets()
	_stop_part_flash_tweens()
	_stop_defeat_fade()
	_state = STATE_PREVIEW
	_wave_active = false
	current_health = maxi(1, max_health)
	global_transform = _authored_cutscene_global_transform
	global_position = anchor_global_position
	_restore_authored_part_transforms()
	_restore_authored_destroy_transforms()
	show()
	for visual in _part_visuals:
		visual.show()
		visual.modulate = Color.WHITE
	_emerged_segment_count = _part_visuals.size()
	_sync_health(false)
	_set_health_hud_visible(true)
	_sync_emerged_segment_count()


func play_cutscene_part_showcase() -> void:
	if _state != STATE_PREVIEW:
		return

	_play_part_flash(0, true)
	await get_tree().create_timer(shield_flash_duration).timeout
	for part_index in range(1, _part_visuals.size() - 1):
		if _state != STATE_PREVIEW:
			return
		_play_part_flash(part_index, false)
		await get_tree().create_timer(body_flash_duration).timeout
	if _state != STATE_PREVIEW:
		return
	_play_part_flash(_part_visuals.size() - 1, true)
	await get_tree().create_timer(shield_flash_duration).timeout


func begin_path_spawn(path: Path2D, start_progress: float = 0.0) -> void:
	if path == null or path.curve == null:
		deactivate()
		return

	_lifecycle_serial += 1
	_defeat_part_indices.clear()
	_clear_nullifier_suppression()
	_stop_part_flash_tweens()
	_stop_defeat_fade()
	_restore_authored_destroy_transforms()
	_path = path
	_path_length = _path.curve.get_baked_length()
	_head_progress = clampf(start_progress, 0.0, _path_length)
	_state = STATE_ACTIVE
	_wave_active = false
	current_health = maxi(1, max_health)
	show()
	_prepare_parts_for_path()
	_create_targets()
	_sync_parts_to_path()
	_sync_health(false)
	_set_health_hud_visible(true)


func deactivate() -> void:
	_lifecycle_serial += 1
	_defeat_part_indices.clear()
	_clear_nullifier_suppression()
	_wave_active = false
	_state = STATE_INACTIVE
	_path = null
	_path_length = 0.0
	_cleanup_targets()
	_stop_part_flash_tweens()
	_stop_defeat_fade()
	for visual in _part_visuals:
		visual.hide()
	_restore_authored_destroy_transforms()
	hide()
	_set_health_hud_visible(false)


func set_wave_active(value: bool) -> void:
	_wave_active = value and _state == STATE_ACTIVE
	_sync_targetable_states()


func is_wave_active() -> bool:
	return _wave_active


func is_active() -> bool:
	return _state == STATE_ACTIVE or _state == STATE_DESTROYING


func is_destroying() -> bool:
	return _state == STATE_DESTROYING


func is_defeated() -> bool:
	return _state == STATE_DEFEATED


func is_escaped() -> bool:
	return _state == STATE_ESCAPED


func can_target_part(part_index: int, _attacker: Node = null) -> bool:
	if _state != STATE_ACTIVE or not _wave_active:
		return false
	if part_index < 0 or part_index >= _part_visuals.size():
		return false
	var visual := _part_visuals[part_index]
	return is_instance_valid(visual) and visual.visible


func take_part_damage(part_index: int, amount: int) -> bool:
	if not can_target_part(part_index) or amount <= 0:
		return false

	if _part_kinds[part_index] != PART_BODY \
			and not is_part_nullifier_suppressed(part_index):
		_play_part_flash(part_index, true)
		return false

	_play_part_flash(part_index, false)
	current_health = maxi(0, current_health - amount)
	_sync_health(true)
	health_changed.emit(current_health, maxi(1, max_health))
	if current_health > 0:
		return false

	_begin_defeat()
	return true


func set_part_nullifier_suppressed(part_index: int, active: bool) -> void:
	if part_index < 0 or part_index >= _part_visuals.size():
		return
	if active:
		_nullifier_suppressed_parts[part_index] = true
	else:
		_nullifier_suppressed_parts.erase(part_index)
	var existing := _part_flash_tweens.get(part_index) as Tween
	if existing != null:
		existing.kill()
		_part_flash_tweens.erase(part_index)
	_reset_part_flash_visual(part_index)


func is_part_nullifier_suppressed(part_index: int) -> bool:
	return bool(_nullifier_suppressed_parts.get(part_index, false))


func get_attack_targets(body_only: bool = false) -> Array[PathFollow2D]:
	var result: Array[PathFollow2D] = []
	if _state != STATE_ACTIVE or not _wave_active:
		return result
	for index in range(_part_targets.size()):
		var target := _part_targets[index]
		if not is_instance_valid(target):
			continue
		if body_only and _part_kinds[index] != PART_BODY:
			continue
		if target.has_method("is_targetable") \
				and bool(target.call("is_targetable")):
			result.append(target)
	return result


func get_preview_center() -> Vector2:
	var bounds := _get_visible_visual_bounds()
	return bounds.get_center() if bounds.size != Vector2.ZERO else global_position


func get_emerged_segment_count() -> int:
	return _emerged_segment_count


func get_authored_cutscene_position() -> Vector2:
	return _authored_cutscene_global_transform.origin


func _cache_parts() -> void:
	_part_visuals.clear()
	_part_kinds.clear()
	var head := get_node_or_null(head_path) as Node2D
	if head != null:
		_part_visuals.append(head)
		_part_kinds.append(PART_HEAD)
	for body_path in body_part_paths:
		var body := get_node_or_null(body_path) as Node2D
		if body != null:
			_part_visuals.append(body)
			_part_kinds.append(PART_BODY)
	var tail := get_node_or_null(tail_path) as Node2D
	if tail != null:
		_part_visuals.append(tail)
		_part_kinds.append(PART_TAIL)


func _cache_destroy_visuals() -> void:
	_destroy_visuals.clear()
	_destroy_animation_names.clear()
	var head := get_node_or_null(head_destroy_path) as AnimatedSprite2D
	if head != null:
		_destroy_visuals.append(head)
		_destroy_animation_names.append(&"head_destroy")
	for body_path in body_destroy_paths:
		var body := get_node_or_null(body_path) as AnimatedSprite2D
		if body != null:
			_destroy_visuals.append(body)
			_destroy_animation_names.append(&"body_destroy")
	var tail := get_node_or_null(tail_destroy_path) as AnimatedSprite2D
	if tail != null:
		_destroy_visuals.append(tail)
		_destroy_animation_names.append(&"tail_destroy")


func _capture_authored_part_transforms() -> void:
	_part_authored_transforms.clear()
	_part_authored_global_scales.clear()
	for visual in _part_visuals:
		_part_authored_transforms.append(visual.transform)
		_part_authored_global_scales.append(visual.global_scale)


func _capture_authored_destroy_transforms() -> void:
	_destroy_authored_transforms.clear()
	_destroy_relative_transforms.clear()
	for index in range(_destroy_visuals.size()):
		var authored_transform := _destroy_visuals[index].transform
		_destroy_authored_transforms.append(authored_transform)
		if index < _part_authored_transforms.size():
			_destroy_relative_transforms.append(
				_part_authored_transforms[index].affine_inverse() \
					* authored_transform
			)
		else:
			_destroy_relative_transforms.append(Transform2D.IDENTITY)


func _build_part_offsets() -> void:
	_part_offsets.clear()
	if _part_authored_transforms.is_empty():
		return
	_part_offsets.append(0.0)
	var cumulative_distance := 0.0
	for index in range(1, _part_authored_transforms.size()):
		cumulative_distance += _part_authored_transforms[
			index - 1
		].origin.distance_to(_part_authored_transforms[index].origin)
		_part_offsets.append(
			cumulative_distance * maxf(0.01, segment_spacing_multiplier)
		)


func _restore_authored_part_transforms() -> void:
	for index in range(_part_visuals.size()):
		var visual := _part_visuals[index]
		visual.top_level = false
		if index < _part_authored_transforms.size():
			visual.transform = _part_authored_transforms[index]


func _restore_authored_destroy_transforms() -> void:
	for index in range(_destroy_visuals.size()):
		var visual := _destroy_visuals[index]
		visual.stop()
		visual.frame = 0
		visual.frame_progress = 0.0
		visual.top_level = false
		visual.modulate = Color.WHITE
		if index < _destroy_authored_transforms.size():
			visual.transform = _destroy_authored_transforms[index]
		visual.hide()


func _prepare_parts_for_path() -> void:
	for index in range(_part_visuals.size()):
		var visual := _part_visuals[index]
		visual.top_level = true
		if index < _part_authored_global_scales.size():
			visual.global_scale = _part_authored_global_scales[index]
		visual.modulate = Color.WHITE
		visual.hide()


func _create_targets() -> void:
	_cleanup_targets()
	var target_parent := get_parent()
	if target_parent == null:
		return
	for index in range(_part_visuals.size()):
		var target := WormBossPartTargetScript.new() as PathFollow2D
		target.name = "WormBoss%sTarget" % _part_name(index)
		target_parent.add_child(target)
		target.call(
			"configure",
			self,
			_part_visuals[index],
			_part_kinds[index],
			index
		)
		_part_targets.append(target)


func _cleanup_targets() -> void:
	for target in _part_targets:
		if is_instance_valid(target):
			if target.has_method("invalidate"):
				target.call("invalidate")
			elif target.has_method("clear_nullifier_suppression"):
				target.call("clear_nullifier_suppression")
			target.queue_free()
	_part_targets.clear()


func _sync_parts_to_path() -> void:
	if _state != STATE_ACTIVE \
			or _path == null \
			or _path.curve == null:
		return

	var emerged_count := 0
	for index in range(_part_visuals.size()):
		var visual := _part_visuals[index]
		if not is_instance_valid(visual):
			continue
		var offset := _part_offsets[index] if index < _part_offsets.size() else 0.0
		var part_progress := _head_progress - offset
		var emerged := part_progress >= 0.0 and part_progress <= _path_length
		visual.visible = emerged
		if emerged:
			emerged_count += 1
			var clamped_progress := clampf(part_progress, 0.0, _path_length)
			visual.global_position = _sample_path_global(clamped_progress)
			visual.global_rotation = _sample_path_rotation(clamped_progress) \
				+ _part_authored_transforms[index].get_rotation()
			if index < _part_authored_global_scales.size():
				visual.global_scale = _part_authored_global_scales[index]
		if index < _part_targets.size():
			var target := _part_targets[index]
			if is_instance_valid(target):
				target.call("sync_to_visual")
				target.call(
					"set_targetable",
					emerged and _wave_active
				)

	if emerged_count != _emerged_segment_count:
		_emerged_segment_count = emerged_count
		_sync_emerged_segment_count()


func _sync_targetable_states() -> void:
	for index in range(_part_targets.size()):
		var target := _part_targets[index]
		if not is_instance_valid(target):
			continue
		target.call(
			"set_targetable",
			_state == STATE_ACTIVE \
				and _wave_active \
				and index < _part_visuals.size() \
				and is_instance_valid(_part_visuals[index]) \
				and _part_visuals[index].visible
		)


func _sample_path_global(progress: float) -> Vector2:
	return _path.to_global(_path.curve.sample_baked(progress))


func _sample_path_rotation(progress: float) -> float:
	var before_progress := maxf(
		0.0,
		progress - path_rotation_sample_distance
	)
	var after_progress := minf(
		_path_length,
		progress + path_rotation_sample_distance
	)
	var direction := _sample_path_global(after_progress) \
		- _sample_path_global(before_progress)
	return direction.angle() if direction.length_squared() > 0.001 else 0.0


func _tail_has_exited() -> bool:
	if _part_offsets.is_empty():
		return false
	return _head_progress - _part_offsets.back() >= _path_length


func _finish_escape() -> void:
	if _state != STATE_ACTIVE:
		return
	_state = STATE_ESCAPED
	_defeat_part_indices.clear()
	_wave_active = false
	_clear_nullifier_suppression()
	_sync_targetable_states()
	_cleanup_targets()
	for visual in _part_visuals:
		visual.hide()
	_set_health_hud_visible(false)
	hide()
	escaped.emit()


func _begin_defeat() -> void:
	if _state != STATE_ACTIVE:
		return
	_state = STATE_DESTROYING
	_wave_active = false
	_lifecycle_serial += 1
	var sequence_serial := _lifecycle_serial
	_capture_defeat_part_indices()
	_play_audio_player(_destroy_sfx)
	_clear_nullifier_suppression()
	_sync_targetable_states()
	_cleanup_targets()
	if _health_hud != null:
		_health_hud.play_defeat_fade()

	_stop_part_flash_tweens()
	call_deferred("_play_defeat_sequence", sequence_serial)


func _play_audio_player(player: AudioStreamPlayer) -> void:
	if player == null:
		return
	player.stop()
	player.play()


func _play_defeat_sequence(sequence_serial: int) -> void:
	if not _is_current_defeat_sequence(sequence_serial):
		return

	var active_part_indices: Array[int] = _defeat_part_indices.duplicate()
	var longest_animation_duration := 0.0
	for index in range(_part_visuals.size()):
		var source_visual := _part_visuals[index]
		if not is_instance_valid(source_visual):
			continue
		if index >= _destroy_visuals.size() \
				or not active_part_indices.has(index):
			source_visual.hide()
			if index < _destroy_visuals.size() \
					and is_instance_valid(_destroy_visuals[index]):
				_destroy_visuals[index].stop()
				_destroy_visuals[index].hide()
			continue

		var destroy_visual := _destroy_visuals[index]
		if not is_instance_valid(destroy_visual):
			source_visual.hide()
			continue

		destroy_visual.top_level = true
		destroy_visual.global_transform = source_visual.global_transform
		if index < _destroy_relative_transforms.size():
			destroy_visual.global_transform *= _destroy_relative_transforms[index]
		destroy_visual.modulate = Color.WHITE
		destroy_visual.show()
		source_visual.hide()

		if index >= _destroy_animation_names.size():
			destroy_visual.hide()
			continue
		var animation_name := _destroy_animation_names[index]
		destroy_visual.play(animation_name)
		longest_animation_duration = maxf(
			longest_animation_duration,
			_get_animation_duration(destroy_visual, animation_name)
		)

	if longest_animation_duration > 0.0:
		await get_tree().create_timer(longest_animation_duration).timeout
	if not _is_current_defeat_sequence(sequence_serial):
		return

	_stop_defeat_fade()
	_defeat_fade_tween = create_tween()
	_defeat_fade_tween.set_parallel(true)
	for part_index in active_part_indices:
		if part_index < 0 or part_index >= _destroy_visuals.size():
			continue
		var visual := _destroy_visuals[part_index]
		if is_instance_valid(visual) and visual.visible:
			_defeat_fade_tween.tween_property(
				visual,
				"modulate",
				Color(1.0, 1.0, 1.0, 0.0),
				destroy_fade_duration
			).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await get_tree().create_timer(destroy_fade_duration).timeout
	_defeat_fade_tween = null
	if not _is_current_defeat_sequence(sequence_serial):
		return

	_state = STATE_DEFEATED
	_hide_all_parts()
	_defeat_part_indices.clear()
	_set_health_hud_visible(false)
	defeated.emit()


func _capture_defeat_part_indices() -> void:
	_defeat_part_indices.clear()
	for index in range(_part_visuals.size()):
		var visual := _part_visuals[index]
		if is_instance_valid(visual) and visual.visible:
			_defeat_part_indices.append(index)


func _is_current_defeat_sequence(sequence_serial: int) -> bool:
	return is_inside_tree() \
		and sequence_serial == _lifecycle_serial \
		and _state == STATE_DESTROYING \
		and current_health <= 0


func _get_animation_duration(
	visual: AnimatedSprite2D,
	animation_name: StringName
) -> float:
	if visual.sprite_frames == null \
			or not visual.sprite_frames.has_animation(animation_name):
		return 0.0
	var speed := visual.sprite_frames.get_animation_speed(animation_name)
	if speed <= 0.0:
		return 0.0
	speed *= maxf(0.001, absf(visual.speed_scale))
	var duration := 0.0
	var frame_count := visual.sprite_frames.get_frame_count(animation_name)
	for frame_index in range(frame_count):
		duration += visual.sprite_frames.get_frame_duration(
			animation_name,
			frame_index
		) / speed
	return duration


func _hide_all_parts() -> void:
	for visual in _part_visuals:
		if is_instance_valid(visual):
			visual.hide()
	for visual in _destroy_visuals:
		if is_instance_valid(visual):
			visual.stop()
			visual.hide()
	hide()


func _stop_defeat_fade() -> void:
	if _defeat_fade_tween != null:
		_defeat_fade_tween.kill()
		_defeat_fade_tween = null


func _play_part_flash(part_index: int, shielded: bool) -> void:
	if part_index < 0 or part_index >= _part_visuals.size():
		return
	var visual := _part_visuals[part_index]
	if not is_instance_valid(visual) or not visual.visible:
		return

	var existing := _part_flash_tweens.get(part_index) as Tween
	if existing != null:
		existing.kill()
	_part_flash_tweens.erase(part_index)
	_reset_part_flash_visual(part_index)
	var base_scale := visual.scale
	var duration := shield_flash_duration if shielded else body_flash_duration
	var flash_color := shield_flash_color if shielded else body_damage_flash_color
	var tween := create_tween()
	_part_flash_tweens[part_index] = tween
	tween.tween_property(
		visual,
		"modulate",
		flash_color,
		duration * 0.38
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if shielded:
		tween.parallel().tween_property(
			visual,
			"scale",
			base_scale * shield_flash_scale,
			duration * 0.38
		).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(
		visual,
		"modulate",
		_get_part_base_modulate(part_index),
		duration * 0.62
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	if shielded:
		tween.parallel().tween_property(
			visual,
			"scale",
			base_scale,
			duration * 0.62
		).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(
		Callable(self, "_finish_part_flash").bind(part_index, tween)
	)


func _finish_part_flash(part_index: int, tween: Tween) -> void:
	if _part_flash_tweens.get(part_index) == tween:
		_part_flash_tweens.erase(part_index)
		_reset_part_flash_visual(part_index)


func _stop_part_flash_tweens() -> void:
	for tween_value in _part_flash_tweens.values():
		var tween := tween_value as Tween
		if tween != null:
			tween.kill()
	_part_flash_tweens.clear()
	for index in range(_part_visuals.size()):
		_reset_part_flash_visual(index)


func _reset_part_flash_visual(part_index: int) -> void:
	if part_index < 0 or part_index >= _part_visuals.size():
		return
	var visual := _part_visuals[part_index]
	if not is_instance_valid(visual):
		return
	visual.modulate = _get_part_base_modulate(part_index)
	if part_index < _part_authored_global_scales.size() and visual.top_level:
		visual.global_scale = _part_authored_global_scales[part_index]
	elif part_index < _part_authored_transforms.size():
		visual.scale = _part_authored_transforms[part_index].get_scale()


func _get_part_base_modulate(part_index: int) -> Color:
	return (
		nullifier_highlight_color
		if is_part_nullifier_suppressed(part_index)
		else Color.WHITE
	)


func _clear_nullifier_suppression() -> void:
	_nullifier_suppressed_parts.clear()
	for index in range(_part_visuals.size()):
		if not _part_flash_tweens.has(index):
			_reset_part_flash_visual(index)


func _sync_health(animate: bool) -> void:
	if _health_hud != null:
		_health_hud.set_health(
			current_health,
			maxi(1, max_health),
			animate
		)


func _set_health_hud_visible(value: bool) -> void:
	if _health_hud != null:
		_health_hud.set_bar_visible(value)


func _sync_emerged_segment_count() -> void:
	if _health_hud != null:
		_health_hud.set_emerged_segments(
			_emerged_segment_count,
			_part_visuals.size()
		)


func _get_visible_visual_bounds() -> Rect2:
	var bounds := Rect2()
	var found := false
	for visual in _part_visuals:
		if not visual.visible:
			continue
		var visual_rect := _get_visual_global_rect(visual)
		if not found:
			bounds = visual_rect
			found = true
		else:
			bounds = bounds.merge(visual_rect)
	return bounds


func _get_visual_global_rect(visual: Node2D) -> Rect2:
	var texture: Texture2D
	if visual is Sprite2D:
		texture = (visual as Sprite2D).texture
	elif visual is AnimatedSprite2D:
		var animated := visual as AnimatedSprite2D
		if animated.sprite_frames != null \
				and animated.sprite_frames.has_animation(animated.animation):
			texture = animated.sprite_frames.get_frame_texture(
				animated.animation,
				animated.frame
			)
	if texture == null:
		return Rect2(visual.global_position, Vector2.ZERO)
	var size := texture.get_size() * visual.global_scale.abs()
	return Rect2(visual.global_position - size * 0.5, size)


func _part_name(index: int) -> String:
	if index == 0:
		return "Head"
	if index == _part_visuals.size() - 1:
		return "Tail"
	return "Body%d" % index
