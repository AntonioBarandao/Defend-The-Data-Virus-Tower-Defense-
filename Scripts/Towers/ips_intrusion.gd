class_name IPSIntrusionTower
extends "res://Scripts/Towers/cyber_guardian_idle_sprite.gd"

signal spike_damage_requested(follow: PathFollow2D, amount: int)

const IPS_ATTACK_RANGE := 360.0
const IPS_MAX_LEVEL := 5
const IPS_UPGRADE_COSTS := [65, 95, 140, 190, 0]

@export var spike_scene: PackedScene = preload("res://Scenes/Towers/IPS_Intrusion_Spike.tscn")
@export_range(1, 12, 1) var max_spikes := 5
@export_range(0.2, 10.0, 0.1) var spike_production_seconds := 2.0
@export_range(1, 100, 1) var spike_damage := 1
@export_range(16.0, 180.0, 1.0) var spike_spacing := 66.0
@export_range(0.05, 2.0, 0.05) var spike_move_seconds := 0.45

var _production_elapsed := 0.0
var _spikes: Array[IPSIntrusionSpike] = []
var _factory_pulse_tween: Tween


func _ready() -> void:
	super._ready()
	range_preview_fill_color = Color(0.12, 0.68, 1.0, 0.14)
	range_preview_outline_color = Color(0.34, 0.86, 1.0, 0.82)


func reset_tower() -> void:
	super.reset_tower()
	_production_elapsed = 0.0
	_clear_spikes()


func finish_drag() -> bool:
	var was_placed := super.finish_drag()
	if was_placed:
		_production_elapsed = 0.0
	return was_placed


func update_attack(_delta: float, _active_viruses: Array[PathFollow2D]) -> PathFollow2D:
	return null


func update_spike_factory(delta: float, active_viruses: Array[PathFollow2D]) -> void:
	if not is_placed():
		return

	_resolve_virus_path()
	_prune_spikes()
	_sync_spike_positions()
	_damage_viruses_with_spikes(active_viruses)

	if _spikes.size() >= max_spikes or not _has_path_target_in_range():
		_production_elapsed = 0.0
		return

	_production_elapsed += delta
	if _production_elapsed < get_shot_cooldown():
		return

	_production_elapsed = 0.0
	_spawn_next_spike()


func get_attack_range() -> float:
	return IPS_ATTACK_RANGE * _get_signal_boost_range_multiplier()


func get_max_level() -> int:
	return IPS_MAX_LEVEL


func can_upgrade() -> bool:
	return level < IPS_MAX_LEVEL


func get_upgrade_cost() -> int:
	if not can_upgrade():
		return 0

	return int(IPS_UPGRADE_COSTS[level])


func get_shot_power() -> int:
	return spike_damage


func get_shot_cooldown() -> float:
	return spike_production_seconds * _get_signal_boost_cooldown_multiplier()


func get_max_spikes() -> int:
	return max_spikes


func upgrade() -> bool:
	if not can_upgrade():
		return false

	level += 1
	_range_preview_radius = -1.0
	if is_placed():
		_spawn_summon_effect()
	return true


func _spawn_next_spike() -> void:
	if spike_scene == null:
		return

	var target := _find_spike_target(_spikes.size())
	if not bool(target["valid"]):
		return

	var spike := spike_scene.instantiate() as IPSIntrusionSpike
	if spike == null:
		return

	var game_root := _get_game_root()
	if game_root == null:
		return

	game_root.add_child(spike)
	spike.damage = spike_damage
	spike.path_offset = float(target["offset"])
	spike.z_index = z_index + 1
	spike.z_as_relative = false
	_spikes.append(spike)

	var target_position: Vector2 = target["position"]
	_play_factory_pulse()
	spike.start_deploy(global_position, target_position, float(target["rotation"]), spike_move_seconds)


func _sync_spike_positions() -> void:
	if _virus_path == null or _virus_path.curve == null:
		return

	var assigned_offsets: Array[float] = []
	for index in range(_spikes.size()):
		var spike := _spikes[index]
		if not is_instance_valid(spike):
			continue

		var target := _find_spike_target(index, assigned_offsets)
		if not bool(target["valid"]):
			continue

		var target_offset := float(target["offset"])
		var target_position: Vector2 = target["position"]
		assigned_offsets.append(target_offset)
		spike.path_offset = target_offset
		spike.sync_landed_transform(target_position, float(target["rotation"]))


func _damage_viruses_with_spikes(active_viruses: Array[PathFollow2D]) -> void:
	for spike in _spikes:
		if not is_instance_valid(spike):
			continue

		for follow in active_viruses:
			if not is_instance_valid(follow):
				continue
			if not _can_spike_target_follow(follow):
				continue
			if spike.mark_follow_hit(follow):
				spike_damage_requested.emit(follow, spike.damage)
				break


func _can_spike_target_follow(follow: PathFollow2D) -> bool:
	var virus := _get_follow_virus(follow)
	return virus == null or not virus.is_destroying()


func _get_follow_virus(follow: PathFollow2D) -> RedVirus:
	for child in follow.get_children():
		var virus := child as RedVirus
		if virus != null:
			return virus

	return null


func _find_spike_target(slot_index: int, occupied_offsets: Array[float] = []) -> Dictionary:
	var empty_result := {
		"valid": false,
		"offset": 0.0,
		"position": Vector2.ZERO,
		"rotation": 0.0
	}
	if _virus_path == null or _virus_path.curve == null:
		return empty_result

	var path_length := _virus_path.curve.get_baked_length()
	if path_length <= 0.0:
		return empty_result

	var center_offset := _get_nearest_path_offset()
	var candidate_deltas := _build_candidate_deltas(slot_index)
	for delta in candidate_deltas:
		var candidate_offset := clampf(center_offset + delta, 0.0, path_length)
		if _offset_overlaps_existing(candidate_offset, occupied_offsets):
			continue

		var candidate_position := _get_path_global_position(candidate_offset)
		if global_position.distance_squared_to(candidate_position) > get_attack_range() * get_attack_range():
			continue

		return {
			"valid": true,
			"offset": candidate_offset,
			"position": candidate_position,
			"rotation": _get_path_global_rotation(candidate_offset)
		}

	return empty_result


func _build_candidate_deltas(slot_index: int) -> Array[float]:
	var preferred := _get_slot_delta(slot_index)
	var candidates: Array[float] = [preferred]
	for index in range(max_spikes + 2):
		var distance := float(index) * spike_spacing
		for sign in [1.0, -1.0]:
			var value: float = distance * float(sign)
			if not candidates.has(value):
				candidates.append(value)

	return candidates


func _get_slot_delta(slot_index: int) -> float:
	if slot_index <= 0:
		return 0.0

	var step := int(ceil(float(slot_index) / 2.0))
	var direction := 1.0 if slot_index % 2 == 1 else -1.0
	return float(step) * spike_spacing * direction


func _offset_overlaps_existing(candidate_offset: float, occupied_offsets: Array[float]) -> bool:
	for offset in occupied_offsets:
		if absf(candidate_offset - offset) < spike_spacing * 0.82:
			return true

	return false


func _has_path_target_in_range() -> bool:
	if _virus_path == null or _virus_path.curve == null:
		return false

	var nearest_position := _get_path_global_position(_get_nearest_path_offset())
	return global_position.distance_squared_to(nearest_position) <= get_attack_range() * get_attack_range()


func _get_nearest_path_offset() -> float:
	var local_position := _virus_path.to_local(global_position)
	return _virus_path.curve.get_closest_offset(local_position)


func _get_path_global_position(offset: float) -> Vector2:
	return _virus_path.to_global(_virus_path.curve.sample_baked(offset, true))


func _get_path_global_rotation(offset: float) -> float:
	var path_length := _virus_path.curve.get_baked_length()
	var previous_offset := clampf(offset - 4.0, 0.0, path_length)
	var next_offset := clampf(offset + 4.0, 0.0, path_length)
	var previous_position := _get_path_global_position(previous_offset)
	var next_position := _get_path_global_position(next_offset)
	var direction := next_position - previous_position
	if direction.length_squared() <= 0.0001:
		return 0.0

	return direction.angle()


func _resolve_virus_path() -> void:
	if is_instance_valid(_virus_path):
		return

	_virus_path = get_node_or_null(virus_path_path) as Path2D
	if _virus_path != null:
		return

	var game_root := _get_game_root()
	if game_root != null:
		_virus_path = game_root.get_node_or_null(^"VirusElements/Path2D") as Path2D


func _prune_spikes() -> void:
	for index in range(_spikes.size() - 1, -1, -1):
		if not is_instance_valid(_spikes[index]):
			_spikes.remove_at(index)


func _clear_spikes() -> void:
	for spike in _spikes:
		if is_instance_valid(spike):
			spike.queue_free()
	_spikes.clear()


func _play_factory_pulse() -> void:
	if _factory_pulse_tween != null:
		_factory_pulse_tween.kill()

	_factory_pulse_tween = create_tween()
	_factory_pulse_tween.tween_property(self, "modulate", Color(0.72, 0.95, 1.0, 1.0), 0.12)
	_factory_pulse_tween.tween_property(self, "modulate", Color.WHITE, 0.22)
