class_name Spyware
extends RedVirus

signal knowledge_steal_requested(spyware: Spyware, amount: int)
signal knowledge_recovery_requested(spyware: Spyware, amount: int)
signal knowledge_exfiltrated(spyware: Spyware, amount: int)
signal stolen_knowledge_changed(amount: int)

const SIEM_KNOWLEDGE_VALUE := 3
const CARRIED_LABEL_COLOR := Color(0.86, 0.7, 1.0, 1.0)
const RECOVERED_LABEL_COLOR := Color(0.38, 1.0, 0.58, 1.0)
const EXFILTRATED_LABEL_COLOR := Color(1.0, 0.28, 0.34, 1.0)

@export_group("Knowledge Theft")
@export_range(0.0, 1.0, 0.01) var activation_progress_ratio := 0.4
@export_range(0.1, 10.0, 0.1) var steal_interval_seconds := 2.0
@export_range(1, 20, 1) var steal_amount := 1
@export_range(1, 100, 1) var stolen_knowledge_capacity := 10
@export_group("Tower Invasion")
@export_range(10.0, 500.0, 1.0) var invasion_walk_speed := 100.0
@export var invasion_front_offset := Vector2(0.0, 110.0)
@export_range(1.0, 40.0, 1.0) var invasion_arrival_distance := 4.0
@export var invasion_z_index := 95
@export_group("Editable Nodes")
@export var visual_path: NodePath = ^"SpywareVisual"
@export var stolen_knowledge_label_path: NodePath = ^"StolenKnowledgeLabel"
@export_group("")

var _stolen_knowledge := 0
var _steal_elapsed := 0.0
var _theft_active := false
var _escape_resolved := false
var _knowledge_resolved := false
var _visual: AnimatedSprite2D
var _stolen_knowledge_label: Label
var _steal_pulse_tween: Tween
var _invasion_target: Node2D
var _invasion_active := false
var _arrived_at_target := false
var _path_z_index := 0
var _path_z_as_relative := true


func _ready() -> void:
	_visual = get_node_or_null(visual_path) as AnimatedSprite2D
	_stolen_knowledge_label = get_node_or_null(stolen_knowledge_label_path) as Label
	_path_z_index = z_index
	_path_z_as_relative = z_as_relative
	super._ready()
	_play_visual_idle()
	_sync_stolen_knowledge_label()


func _process(delta: float) -> void:
	super._process(delta)


func reset_for_spawn() -> void:
	_stolen_knowledge = 0
	_steal_elapsed = 0.0
	_theft_active = false
	_escape_resolved = false
	_knowledge_resolved = false
	_invasion_target = null
	_invasion_active = false
	_arrived_at_target = false
	_restore_path_parenting()
	_clear_steal_pulse()
	super.reset_for_spawn()
	_play_visual_idle()
	_sync_stolen_knowledge_label()


func take_damage(amount: int) -> bool:
	var destroyed := super.take_damage(amount)
	if destroyed:
		_recover_stolen_knowledge()
	return destroyed


func play_destroy_and_queue_owner(owner: Node) -> void:
	if not _escape_resolved:
		_recover_stolen_knowledge()
	super.play_destroy_and_queue_owner(owner)


func on_path_escaped() -> void:
	if _escape_resolved:
		return

	_escape_resolved = true
	_knowledge_resolved = true
	var exfiltrated_amount := _stolen_knowledge
	_stolen_knowledge = 0
	_sync_stolen_knowledge_label()
	if exfiltrated_amount > 0:
		_show_resolution_label("Exfiltrated %d KP" % exfiltrated_amount, EXFILTRATED_LABEL_COLOR)
		knowledge_exfiltrated.emit(self, exfiltrated_amount)


func accept_stolen_knowledge(amount: int) -> void:
	if is_destroying() or _escape_resolved or _knowledge_resolved:
		return

	var available_capacity := maxi(0, stolen_knowledge_capacity - _stolen_knowledge)
	var accepted_amount := mini(maxi(0, amount), available_capacity)
	if accepted_amount <= 0:
		return

	_stolen_knowledge += accepted_amount
	stolen_knowledge_changed.emit(_stolen_knowledge)
	_sync_stolen_knowledge_label()
	_play_steal_pulse()


func get_stolen_knowledge() -> int:
	return _stolen_knowledge


func get_siem_knowledge_value() -> int:
	return SIEM_KNOWLEDGE_VALUE


func uses_path_movement() -> bool:
	return not _invasion_active


func is_invading_tower() -> bool:
	return _invasion_active


func has_reached_invasion_target() -> bool:
	return _arrived_at_target


func get_invasion_target() -> Node2D:
	return _invasion_target


func update_invasion(delta: float, eligible_towers: Array[Node2D]) -> void:
	if is_destroying() or _escape_resolved or _knowledge_resolved:
		return

	if not _invasion_active:
		var follow := get_parent() as PathFollow2D
		if follow == null or follow.progress_ratio < activation_progress_ratio:
			return
		var closest_tower := _find_closest_eligible_tower(eligible_towers)
		if closest_tower == null:
			return
		_begin_tower_invasion(closest_tower)
	elif not _is_tower_available(_invasion_target):
		var replacement_target := _find_closest_eligible_tower(eligible_towers)
		if replacement_target == null:
			_abandon_tower_invasion()
			return
		_invasion_target = replacement_target
		_arrived_at_target = false
		_theft_active = false
		_steal_elapsed = 0.0

	var was_at_target := _arrived_at_target
	var target_position := _get_invasion_anchor_position(_invasion_target)
	if not _arrived_at_target:
		global_position = global_position.move_toward(target_position, maxf(0.0, invasion_walk_speed) * delta)
		if global_position.distance_squared_to(target_position) <= invasion_arrival_distance * invasion_arrival_distance:
			global_position = target_position
			_arrived_at_target = true
			_theft_active = true
			_steal_elapsed = 0.0
	else:
		global_position = target_position

	_update_knowledge_theft(delta if was_at_target else 0.0)


func get_grab_rect() -> Rect2:
	if _visual == null or _visual.sprite_frames == null:
		return super.get_grab_rect()
	if not _visual.sprite_frames.has_animation(_visual.animation):
		return super.get_grab_rect()

	var texture := _visual.sprite_frames.get_frame_texture(_visual.animation, _visual.frame)
	if texture == null:
		return super.get_grab_rect()

	var size := texture.get_size() * Vector2(abs(_visual.global_scale.x), abs(_visual.global_scale.y))
	return Rect2(_visual.global_position - size * 0.5, size)


func _update_knowledge_theft(delta: float) -> void:
	if is_destroying() or _escape_resolved or _knowledge_resolved or are_abilities_nullified():
		return
	if not _theft_active or not _arrived_at_target:
		return
	if _stolen_knowledge >= stolen_knowledge_capacity:
		return

	_steal_elapsed += delta
	while _steal_elapsed >= steal_interval_seconds and _stolen_knowledge < stolen_knowledge_capacity:
		_steal_elapsed -= steal_interval_seconds
		var requested_amount := mini(steal_amount, stolen_knowledge_capacity - _stolen_knowledge)
		knowledge_steal_requested.emit(self, requested_amount)


func _find_closest_eligible_tower(eligible_towers: Array[Node2D]) -> Node2D:
	var closest_tower: Node2D
	var closest_distance_squared := INF
	for tower in eligible_towers:
		if not _is_tower_available(tower):
			continue
		var anchor_position := _get_invasion_anchor_position(tower)
		var distance_squared := global_position.distance_squared_to(anchor_position)
		if distance_squared >= closest_distance_squared:
			continue
		closest_distance_squared = distance_squared
		closest_tower = tower
	return closest_tower


func _is_tower_available(tower: Node2D) -> bool:
	return is_instance_valid(tower) \
		and tower.has_method("is_placed") \
		and bool(tower.call("is_placed"))


func _get_invasion_anchor_position(tower: Node2D) -> Vector2:
	if tower == null:
		return global_position

	var tower_position := tower.global_position
	if tower.has_method("get_headquarters_position"):
		tower_position = tower.call("get_headquarters_position") as Vector2
	return tower_position + invasion_front_offset


func _begin_tower_invasion(tower: Node2D) -> void:
	var preserved_transform := global_transform
	top_level = true
	global_transform = preserved_transform
	_invasion_target = tower
	_invasion_active = true
	_arrived_at_target = false
	_theft_active = false
	_steal_elapsed = 0.0
	z_as_relative = false
	z_index = invasion_z_index


func _abandon_tower_invasion() -> void:
	_invasion_target = null
	_invasion_active = false
	_arrived_at_target = false
	_theft_active = false
	_steal_elapsed = 0.0
	_restore_path_parenting()


func _restore_path_parenting() -> void:
	if top_level:
		top_level = false
	position = Vector2.ZERO
	z_index = _path_z_index
	z_as_relative = _path_z_as_relative


func _recover_stolen_knowledge() -> void:
	if _knowledge_resolved:
		return

	_knowledge_resolved = true
	var recovered_amount := _stolen_knowledge
	_stolen_knowledge = 0
	_sync_stolen_knowledge_label()
	if recovered_amount > 0:
		_show_resolution_label("Recovered +%d KP" % recovered_amount, RECOVERED_LABEL_COLOR)
		knowledge_recovery_requested.emit(self, recovered_amount)


func _play_visual_idle() -> void:
	if _visual == null or _visual.sprite_frames == null:
		return
	if not _visual.sprite_frames.has_animation(&"idle"):
		return

	_visual.animation = &"idle"
	_visual.frame = 0
	_visual.frame_progress = 0.0
	_visual.play()


func _sync_stolen_knowledge_label() -> void:
	if _stolen_knowledge_label == null:
		return

	_stolen_knowledge_label.visible = _stolen_knowledge > 0
	_stolen_knowledge_label.text = "Stolen KP: %d" % _stolen_knowledge
	_stolen_knowledge_label.add_theme_color_override("font_color", CARRIED_LABEL_COLOR)


func _show_resolution_label(message: String, color: Color) -> void:
	if _stolen_knowledge_label == null:
		return

	_stolen_knowledge_label.text = message
	_stolen_knowledge_label.add_theme_color_override("font_color", color)
	_stolen_knowledge_label.show()


func _play_steal_pulse() -> void:
	if _visual == null:
		return
	if _steal_pulse_tween != null:
		_steal_pulse_tween.kill()

	_visual.self_modulate = Color(0.75, 0.42, 1.0, 1.0)
	_steal_pulse_tween = create_tween()
	_steal_pulse_tween.tween_property(_visual, "self_modulate", Color.WHITE, 0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_steal_pulse_tween.tween_callback(func() -> void:
		_steal_pulse_tween = null
	)


func _clear_steal_pulse() -> void:
	if _steal_pulse_tween != null:
		_steal_pulse_tween.kill()
		_steal_pulse_tween = null
	if _visual != null:
		_visual.self_modulate = Color.WHITE
