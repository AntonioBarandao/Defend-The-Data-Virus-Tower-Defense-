class_name AntiCyberguardian
extends Node2D

signal partial_defeat_animation_started(animation_name: StringName)
signal botnet_reveal_appearance_held(world_position: Vector2)
signal botnet_reveal_move_finished(world_position: Vector2)
signal botnet_reveal_departure_started(world_position: Vector2)

const ABILITY_ACTIVATE := &"ability_activate"
const ABILITY_IDLE := &"ability_idle"
const APPEAR := &"appear"
const CLOAK_DISAPPEAR := &"cloak_disappear"
const COLLAPSE := &"collapse"
const DISAPPEAR_DEFEAT := &"disappear_defeat"
const PANTING := &"panting"
const STRUGGLE_PANTING := &"struggle_panting"

@export_group("Animation Nodes")
@export var ability_activate_path: NodePath = ^"AbilityActivateAnimation"
@export var ability_idle_path: NodePath = ^"AbilityIdleAnimation"
@export var appear_path: NodePath = ^"AppearAnimation"
@export var cloak_disappear_path: NodePath = ^"CloakDisappearAnimation"
@export var collapse_path: NodePath = ^"CollapseAnimation"
@export var disappear_defeat_path: NodePath = ^"DisappearDefeatAnimation"
@export var panting_path: NodePath = ^"PantingAnimation"
@export var struggle_panting_path: NodePath = ^"StrugglePantingAnimation"
@export_group("Mounted Pose")
@export var mounted_local_position := Vector2.ZERO
@export_range(-360.0, 360.0, 0.5) var mounted_rotation_degrees := -90.0
@export_group("Editor Preview")
@export var editor_preview_only := false
@export_group("")

var _animation_nodes: Dictionary = {}
var _alive := false
var _ability_active := false
var _mounted := false
var _defeat_sequence_playing := false
var _sequence_serial := 0
var _reveal_position_tween: Tween
var _mounted_parent: Node
var _mounted_local_scale := Vector2.ONE


func _ready() -> void:
	if editor_preview_only and not Engine.is_editor_hint():
		for group_name in get_groups():
			remove_from_group(group_name)
		hide()
		set_process(false)
		set_physics_process(false)
		queue_free()
		return
	_mounted_parent = get_parent()
	_mounted_local_scale = scale
	_animation_nodes = {
		ABILITY_ACTIVATE: get_node_or_null(ability_activate_path),
		ABILITY_IDLE: get_node_or_null(ability_idle_path),
		APPEAR: get_node_or_null(appear_path),
		CLOAK_DISAPPEAR: get_node_or_null(cloak_disappear_path),
		COLLAPSE: get_node_or_null(collapse_path),
		DISAPPEAR_DEFEAT: get_node_or_null(disappear_defeat_path),
		PANTING: get_node_or_null(panting_path),
		STRUGGLE_PANTING: get_node_or_null(struggle_panting_path),
	}
	reset_for_final_boss_cutscene()


func reset_for_final_boss_cutscene() -> void:
	_sequence_serial += 1
	_kill_reveal_position_tween()
	_restore_mounted_parent()
	_alive = false
	_ability_active = false
	_mounted = false
	_defeat_sequence_playing = false
	top_level = false
	position = mounted_local_position
	rotation_degrees = mounted_rotation_degrees
	scale = _mounted_local_scale
	_hide_all_animations()
	hide()


func play_botnet_reveal_appearance_at(world_position: Vector2) -> void:
	_sequence_serial += 1
	_kill_reveal_position_tween()
	var serial := _sequence_serial
	_alive = true
	_ability_active = false
	_mounted = false
	_defeat_sequence_playing = false
	_detach_to_world_parent()
	top_level = false
	global_position = world_position
	global_rotation = 0.0
	show()
	await _play_exclusive_animation_held(APPEAR, serial)
	if serial == _sequence_serial:
		botnet_reveal_appearance_held.emit(global_position)


func move_botnet_reveal_to(
	world_position: Vector2,
	duration: float
) -> void:
	if not _alive or _mounted:
		return
	_kill_reveal_position_tween()
	var serial := _sequence_serial
	if duration <= 0.0:
		global_position = world_position
		return
	_reveal_position_tween = create_tween()
	_reveal_position_tween.tween_property(
		self,
		"global_position",
		world_position,
		duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_reveal_position_tween.tween_callback(
		_finish_botnet_reveal_move.bind(
			serial,
			world_position
		)
	)


func play_cloak_departure_at(world_position: Vector2) -> void:
	_sequence_serial += 1
	_kill_reveal_position_tween()
	var serial := _sequence_serial
	botnet_reveal_departure_started.emit(world_position)
	_alive = true
	_ability_active = false
	_mounted = false
	_defeat_sequence_playing = false
	top_level = true
	global_position = world_position
	global_rotation = 0.0
	show()
	await _play_exclusive_animation(CLOAK_DISAPPEAR, serial)
	if serial == _sequence_serial and not _mounted:
		hide()


func mount_on_worm() -> void:
	_sequence_serial += 1
	_kill_reveal_position_tween()
	_mounted = true
	_restore_mounted_parent()
	top_level = false
	position = mounted_local_position
	rotation_degrees = mounted_rotation_degrees
	scale = _mounted_local_scale
	_hide_all_animations()
	show()


func play_mounted_entrance_and_activate() -> void:
	if not _mounted:
		mount_on_worm()
	var serial := _sequence_serial
	_alive = true
	_ability_active = false
	_defeat_sequence_playing = false
	await _play_exclusive_animation(APPEAR, serial)
	if serial != _sequence_serial:
		return
	await _play_exclusive_animation(ABILITY_ACTIVATE, serial)
	if serial != _sequence_serial:
		return
	_ability_active = true
	_play_looping_animation(ABILITY_IDLE)


func finish_final_boss_intro_immediately() -> void:
	_sequence_serial += 1
	_kill_reveal_position_tween()
	_mounted = true
	_alive = true
	_ability_active = true
	_defeat_sequence_playing = false
	top_level = false
	position = mounted_local_position
	rotation_degrees = mounted_rotation_degrees
	show()
	_play_looping_animation(ABILITY_IDLE)


func deactivate() -> void:
	_sequence_serial += 1
	_kill_reveal_position_tween()
	_alive = false
	_ability_active = false
	_mounted = false
	_defeat_sequence_playing = false
	_hide_all_animations()
	hide()


func play_partial_defeat_sequence_at(world_position: Vector2) -> void:
	_sequence_serial += 1
	_kill_reveal_position_tween()
	var serial := _sequence_serial
	_alive = true
	_ability_active = false
	_mounted = false
	_defeat_sequence_playing = true
	top_level = true
	global_position = world_position
	global_rotation = 0.0
	show()
	for animation_name in [
		APPEAR,
		COLLAPSE,
		STRUGGLE_PANTING,
		PANTING,
		DISAPPEAR_DEFEAT,
	]:
		partial_defeat_animation_started.emit(animation_name)
		await _play_exclusive_animation(animation_name, serial)
		if serial != _sequence_serial:
			return
	_defeat_sequence_playing = false
	_alive = false
	hide()


func finish_partial_defeat_sequence_immediately() -> void:
	_sequence_serial += 1
	_kill_reveal_position_tween()
	_defeat_sequence_playing = false
	_alive = false
	_ability_active = false
	_mounted = false
	_hide_all_animations()
	hide()


func is_alive() -> bool:
	return _alive


func is_ability_active() -> bool:
	return _alive and _ability_active


func is_mounted() -> bool:
	return _mounted


func is_defeat_sequence_playing() -> bool:
	return _defeat_sequence_playing


func _play_exclusive_animation(
	animation_name: StringName,
	serial: int
) -> void:
	var sprite := _get_animation_node(animation_name)
	_hide_all_animations()
	if sprite == null:
		return
	sprite.show()
	sprite.frame = 0
	sprite.frame_progress = 0.0
	sprite.play(animation_name)
	var duration := _get_animation_duration(sprite, animation_name)
	if duration > 0.0:
		await get_tree().create_timer(duration).timeout
	if serial == _sequence_serial and is_instance_valid(sprite):
		sprite.stop()
		sprite.hide()


func _play_looping_animation(animation_name: StringName) -> void:
	var sprite := _get_animation_node(animation_name)
	_hide_all_animations()
	if sprite == null:
		return
	sprite.show()
	sprite.play(animation_name)


func _play_exclusive_animation_held(
	animation_name: StringName,
	serial: int
) -> void:
	var sprite := _get_animation_node(animation_name)
	_hide_all_animations()
	if sprite == null:
		return
	sprite.show()
	sprite.frame = 0
	sprite.frame_progress = 0.0
	sprite.play(animation_name)
	var duration := _get_animation_duration(sprite, animation_name)
	if duration > 0.0:
		await get_tree().create_timer(duration).timeout
	if serial != _sequence_serial or not is_instance_valid(sprite):
		return
	sprite.stop()
	sprite.frame = maxi(
		0,
		sprite.sprite_frames.get_frame_count(animation_name) - 1
	)
	sprite.frame_progress = 0.0
	sprite.show()


func _hide_all_animations() -> void:
	for value in _animation_nodes.values():
		var sprite := value as AnimatedSprite2D
		if sprite == null:
			continue
		sprite.stop()
		sprite.hide()


func _kill_reveal_position_tween() -> void:
	if _reveal_position_tween != null \
			and _reveal_position_tween.is_valid():
		_reveal_position_tween.kill()
	_reveal_position_tween = null


func _finish_botnet_reveal_move(
	serial: int,
	world_position: Vector2
) -> void:
	_reveal_position_tween = null
	if serial == _sequence_serial and not _mounted:
		global_position = world_position
		botnet_reveal_move_finished.emit(global_position)


func _detach_to_world_parent() -> void:
	if not is_instance_valid(_mounted_parent):
		return
	var mounted_root := _mounted_parent
	while mounted_root.get_parent() != null \
			and not (mounted_root is WormBoss):
		mounted_root = mounted_root.get_parent()
	if not (mounted_root is WormBoss):
		return
	var world_parent := mounted_root.get_parent()
	if world_parent != null and get_parent() != world_parent:
		reparent(world_parent, true)


func _restore_mounted_parent() -> void:
	if is_instance_valid(_mounted_parent) \
			and get_parent() != _mounted_parent:
		reparent(_mounted_parent, false)


func _get_animation_node(animation_name: StringName) -> AnimatedSprite2D:
	return _animation_nodes.get(animation_name) as AnimatedSprite2D


func _get_animation_duration(
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
