class_name BotnetMinion
extends RedVirus

const DestroyEffect := preload(
	"res://Scripts/Effects/anti_charged_destroy_effect.gd"
)
const ANTI_CHARGED_ANIMATION := &"anti_charged"

@export_range(120.0, 600.0, 5.0) var path_entry_speed := 285.0
@export_range(12.0, 220.0, 1.0) var path_entry_arc_height := 86.0
@export_range(8.0, 140.0, 1.0) var anti_charge_contact_radius := 54.0
@export var scanner_hover_offset := Vector2(0.0, -50.0)
@export var scan_spotlight_path: NodePath = ^"ScanSpotlight"
@export_range(0.05, 2.0, 0.05) var scan_conversion_cooldown := 0.35
@export_range(0.2, 4.0, 0.05) var spotlight_pulse_seconds := 1.1

var _entering_path := false
var _settled_on_path := false
var _entry_elapsed := 0.0
var _entry_duration := 0.8
var _entry_start := Vector2.ZERO
var _entry_control := Vector2.ZERO
var _entry_end := Vector2.ZERO
var _path_anchor_global_position := Vector2.ZERO
var _anti_charged := false
var _scan_cooldown_remaining := 0.0
var _spotlight_pulse_elapsed := 0.0
var _scan_spotlight: Node2D


func _ready() -> void:
	super._ready()
	_scan_spotlight = get_node_or_null(scan_spotlight_path) as Node2D
	if _scan_spotlight != null:
		_scan_spotlight.top_level = true
		_scan_spotlight.hide()


func _process(delta: float) -> void:
	_scan_cooldown_remaining = maxf(
		0.0,
		_scan_cooldown_remaining - maxf(0.0, delta)
	)
	if _entering_path:
		_update_path_entry(delta)
		return
	if not _settled_on_path:
		return

	var follow := get_parent() as PathFollow2D
	if follow != null:
		_path_anchor_global_position = follow.global_position
	global_position = _path_anchor_global_position + scanner_hover_offset
	_update_scan_spotlight(delta)


func reset_for_spawn() -> void:
	_entering_path = false
	_settled_on_path = false
	_anti_charged = false
	_scan_cooldown_remaining = 0.0
	_spotlight_pulse_elapsed = 0.0
	super.reset_for_spawn()
	if _scan_spotlight != null:
		_scan_spotlight.hide()


func play_idle() -> void:
	var selected_animation := (
		ANTI_CHARGED_ANIMATION if _anti_charged else IDLE_ANIMATION
	)
	if sprite_frames == null or not sprite_frames.has_animation(selected_animation):
		return
	animation = selected_animation
	frame = 0
	frame_progress = 0.0
	play()
	show()


func start_path_entry(
	start_global_position: Vector2,
	target_global_position: Vector2
) -> void:
	_path_anchor_global_position = target_global_position
	_entry_start = start_global_position
	_entry_end = target_global_position + scanner_hover_offset
	var travel_vector := _entry_end - _entry_start
	var perpendicular := Vector2(-travel_vector.y, travel_vector.x).normalized()
	if perpendicular.y > 0.0:
		perpendicular = -perpendicular
	_entry_control = (
		_entry_start.lerp(_entry_end, 0.5)
		+ perpendicular * path_entry_arc_height
	)
	_entry_duration = clampf(
		travel_vector.length() / maxf(1.0, path_entry_speed),
		0.45,
		2.2
	)
	_entry_elapsed = 0.0
	_entering_path = true
	_settled_on_path = false
	top_level = true
	global_position = _entry_start
	if _scan_spotlight != null:
		_scan_spotlight.global_position = _path_anchor_global_position
		_scan_spotlight.hide()


func uses_path_movement() -> bool:
	return false


func is_entering_path() -> bool:
	return _entering_path


func has_reached_path() -> bool:
	return _settled_on_path


func can_be_targeted() -> bool:
	return _settled_on_path and not is_destroying()


func can_be_targeted_by(attacker: Node) -> bool:
	return can_be_targeted() and super.can_be_targeted_by(attacker)


func can_apply_anti_charge() -> bool:
	return (
		_settled_on_path
		and _scan_cooldown_remaining <= 0.0
		and not is_destroying()
	)


func get_anti_charge_contact_radius() -> float:
	return anti_charge_contact_radius


func mark_anti_charge_applied() -> void:
	_scan_cooldown_remaining = scan_conversion_cooldown
	_anti_charged = true
	play_idle()


func is_anti_charged() -> bool:
	return _anti_charged


func get_scan_spotlight() -> Node2D:
	return _scan_spotlight


func get_scan_origin_global_position() -> Vector2:
	if _scan_spotlight != null:
		return _scan_spotlight.global_position
	return _path_anchor_global_position


func play_destroy_and_queue_owner(owner: Node) -> void:
	var scene_root := get_tree().current_scene
	if scene_root == null and owner != null:
		scene_root = owner
		while scene_root.get_parent() != null \
				and scene_root.get_parent() != get_tree().root:
			scene_root = scene_root.get_parent()
	if scene_root != null:
		var effect := DestroyEffect.new() as AntiChargedDestroyEffect
		effect.name = "BotnetMinionDestroyEffect"
		scene_root.add_child(effect)
		effect.global_position = global_position
		effect.z_index = z_index + 2

	if _scan_spotlight != null:
		_scan_spotlight.hide()
	hide()
	var cleanup_tween := create_tween()
	cleanup_tween.tween_interval(0.7)
	if owner != null:
		cleanup_tween.tween_callback(Callable(owner, "queue_free"))
	else:
		cleanup_tween.tween_callback(queue_free)


func _update_path_entry(delta: float) -> void:
	_entry_elapsed = minf(_entry_duration, _entry_elapsed + delta)
	var weight := clampf(
		_entry_elapsed / maxf(0.001, _entry_duration),
		0.0,
		1.0
	)
	var eased_weight := weight * weight * (3.0 - 2.0 * weight)
	global_position = _quadratic_bezier(
		_entry_start,
		_entry_control,
		_entry_end,
		eased_weight
	)
	if weight < 1.0:
		return

	_entering_path = false
	_settled_on_path = true
	global_position = _entry_end
	if _scan_spotlight != null:
		_scan_spotlight.global_position = _path_anchor_global_position
		_scan_spotlight.scale = Vector2.ONE
		_scan_spotlight.modulate.a = 0.5
		_scan_spotlight.show()


func _update_scan_spotlight(delta: float) -> void:
	if _scan_spotlight == null:
		return

	_spotlight_pulse_elapsed = fmod(
		_spotlight_pulse_elapsed + maxf(0.0, delta),
		maxf(0.2, spotlight_pulse_seconds)
	)
	var pulse_weight := (
		sin(
			_spotlight_pulse_elapsed
				/ maxf(0.2, spotlight_pulse_seconds)
				* TAU
		)
		+ 1.0
	) * 0.5
	var pulse_scale := lerpf(0.92, 1.08, pulse_weight)
	_scan_spotlight.global_position = _path_anchor_global_position
	_scan_spotlight.scale = Vector2.ONE * pulse_scale
	_scan_spotlight.modulate.a = 0.5


func _quadratic_bezier(
	start: Vector2,
	control: Vector2,
	finish: Vector2,
	weight: float
) -> Vector2:
	var inverse := 1.0 - weight
	return (
		inverse * inverse * start
		+ 2.0 * inverse * weight * control
		+ weight * weight * finish
	)
