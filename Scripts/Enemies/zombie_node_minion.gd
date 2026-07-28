class_name ZombieNodeMinion
extends RedVirus

const DestroyEffect := preload("res://Scripts/Effects/zombie_minion_destroy_effect.gd")
const VARIANT_ANIMATIONS: Array[StringName] = [
	&"angry",
	&"dizzy",
	&"jealous",
	&"look",
	&"rampage",
	&"rip",
	&"sad",
	&"skull",
	&"surprised",
]

@export_range(120.0, 600.0, 5.0) var path_entry_speed := 260.0
@export_range(12.0, 180.0, 1.0) var path_entry_arc_height := 72.0
@export_range(8.0, 120.0, 1.0) var red_virus_contact_radius := 42.0
@export_range(0, 8, 1) var variant_index := 0

var _entering_path := false
var _entry_elapsed := 0.0
var _entry_duration := 0.8
var _entry_start := Vector2.ZERO
var _entry_control := Vector2.ZERO
var _entry_end := Vector2.ZERO


func _process(delta: float) -> void:
	if _entering_path:
		_update_path_entry(delta)
		return
	super._process(delta)


func reset_for_spawn() -> void:
	_entering_path = false
	super.reset_for_spawn()
	play_idle()


func configure_variant(index: int) -> void:
	variant_index = posmod(index, VARIANT_ANIMATIONS.size())
	play_idle()


func play_idle() -> void:
	if sprite_frames == null or VARIANT_ANIMATIONS.is_empty():
		return

	var selected_animation := VARIANT_ANIMATIONS[posmod(variant_index, VARIANT_ANIMATIONS.size())]
	if not sprite_frames.has_animation(selected_animation):
		return

	animation = selected_animation
	frame = 0
	frame_progress = 0.0
	play()


func start_path_entry(start_global_position: Vector2, target_global_position: Vector2) -> void:
	_entry_start = start_global_position
	_entry_end = target_global_position
	var travel_vector := _entry_end - _entry_start
	var perpendicular := Vector2(-travel_vector.y, travel_vector.x).normalized()
	if perpendicular.y > 0.0:
		perpendicular = -perpendicular
	_entry_control = _entry_start.lerp(_entry_end, 0.5) + perpendicular * path_entry_arc_height
	_entry_duration = clampf(travel_vector.length() / maxf(1.0, path_entry_speed), 0.45, 1.8)
	_entry_elapsed = 0.0
	_entering_path = true
	top_level = true
	global_position = _entry_start


func uses_path_movement() -> bool:
	return not _entering_path and super.uses_path_movement()


func is_entering_path() -> bool:
	return _entering_path


func get_mutation_contact_radius() -> float:
	return red_virus_contact_radius


func play_destroy_and_queue_owner(owner: Node) -> void:
	var scene_root := get_tree().current_scene
	if scene_root == null and owner != null:
		scene_root = owner
		while scene_root.get_parent() != null and scene_root.get_parent() != get_tree().root:
			scene_root = scene_root.get_parent()
	if scene_root != null:
		var effect := DestroyEffect.new() as ZombieMinionDestroyEffect
		effect.name = "ZombieMinionDestroyEffect"
		scene_root.add_child(effect)
		effect.global_position = global_position
		effect.z_index = z_index + 1

	hide()
	var cleanup_tween := create_tween()
	cleanup_tween.tween_interval(0.6)
	if owner != null:
		cleanup_tween.tween_callback(Callable(owner, "queue_free"))
	else:
		cleanup_tween.tween_callback(queue_free)


func _update_path_entry(delta: float) -> void:
	_entry_elapsed = minf(_entry_duration, _entry_elapsed + delta)
	var weight := clampf(_entry_elapsed / maxf(0.001, _entry_duration), 0.0, 1.0)
	var eased_weight := weight * weight * (3.0 - 2.0 * weight)
	global_position = _quadratic_bezier(_entry_start, _entry_control, _entry_end, eased_weight)
	if weight < 1.0:
		return

	_entering_path = false
	global_position = _entry_end


func _quadratic_bezier(start: Vector2, control: Vector2, finish: Vector2, weight: float) -> Vector2:
	var inverse := 1.0 - weight
	return inverse * inverse * start + 2.0 * inverse * weight * control + weight * weight * finish
