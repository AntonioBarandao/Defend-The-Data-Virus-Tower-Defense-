class_name XDRMechTower
extends Node2D

const GameplaySafeArea := preload("res://Scripts/Gameplay/gameplay_safe_area.gd")

const CentralAudioResolver := preload("res://Scripts/Audio/audio_player_resolver.gd")

signal placed(tower: XDRMechTower)
signal dispatch_mode_changed(dispatched: bool)
signal destination_changed(has_destination: bool, destination: Vector2)
signal claw_damage_requested(target: PathFollow2D, damage: int)
signal cannon_damage_requested(target: PathFollow2D, damage: int)

const TowerSummonEffectScript := preload("res://Scripts/Effects/tower_summon_effect.gd")

const IDLE_ANIMATION := &"idle"
const WALK_ANIMATION := &"walk"
const HIT_ANIMATION_NAMES := [
	&"hit_lv1",
	&"hit_lv2",
	&"hit_lv3",
	&"hit_lv4",
	&"hit_lv5",
]
const MAX_LEVEL := 5
const DESTINATION_EPSILON := 2.0
const DESTINATION_MARKER_SEGMENTS := 48
const PLACEMENT_SLOT_PREFIX := "placementslot"
const SUMMON_EFFECT_Z_OFFSET := -1
const DRAG_VALID_MODULATE := Color(0.42, 1.0, 0.46, 0.86)
const DRAG_INVALID_MODULATE := Color(1.0, 0.22, 0.2, 0.86)
const XDR_PATH_BLOCKER_COLLISION_LAYER := 1 << 20

@export var platform_highlight_path: NodePath = ^"../../PlatformHighlight"
@export_range(1, MAX_LEVEL, 1) var level := 1:
	set(value):
		var next_level := clampi(value, 1, MAX_LEVEL)
		var level_changed := level != next_level
		level = next_level
		if is_inside_tree():
			if level_changed and _claw_attack_active:
				_cancel_claw_attack(false)
			if level_changed:
				if _jetpack_active and level < MAX_LEVEL:
					_cancel_lv5_jetpack()
				_cancel_level_2_cannon_projectile()
				_cancel_level_4_minigun_muzzle_vfx()
				_cancel_level_5_minigun_muzzle_vfx()
				_passive_cannon_cooldown_remaining = \
					_get_passive_cannon_cooldown()
				_level_4_cannon_cooldown_remaining = \
					maxf(0.1, level_4_cannon_cooldown_seconds)
				_level_4_minigun_pattern_index = 0
				_level_5_minigun_pattern_index = 0
			_sync_level_visuals()
			if level_changed and level <= 2:
				_ensure_continuous_claw_animation()
@export_group("Editable Visual Layers")
@export var level_1_head_path: NodePath = ^"Visuals/XDRHead"
@export var level_2_head_path: NodePath = ^"Visuals/LV2Head"
@export var level_3_head_path: NodePath = ^"Visuals/LV3Head"
@export var level_4_head_path: NodePath = ^"Visuals/LV4Head"
@export var level_1_leg_path: NodePath = ^"Visuals/XDRLeg"
@export var level_5_head_path: NodePath = ^"Visuals/LV5Head"
@export var level_5_leg_path: NodePath = ^"Visuals/LV5Leg"
@export var hit_animation_paths: Array[NodePath] = [
	^"Visuals/LV1HitAnimation",
	^"Visuals/LV2HitAnimation",
	^"Visuals/LV3HitAnimation",
	^"Visuals/LV4HitAnimation",
	^"Visuals/LV5HitAnimation",
]
@export_group("LV1 Claw Attack")
@export var right_arm_hitbox_path: NodePath = ^"RightArmHitbox"
@export var left_arm_hitbox_path: NodePath = ^"LeftArmHitbox"
@export_range(1, 100, 1) var level_1_claw_damage := 1
@export_range(0.1, 4.0, 0.1) var level_1_hit_speed_scale := 2.0
@export_range(0, 72, 1) var left_arm_impact_frame := 12
@export_range(0, 72, 1) var right_arm_impact_frame := 42
@export_range(0.0, 10.0, 0.05) var level_1_attack_recovery_seconds := 0.0
@export_group("LV2 Hybrid Attack")
@export_range(0.1, 4.0, 0.1) var level_2_hit_speed_scale := 2.0
@export_range(0, 72, 1) var level_2_claw_impact_frame := 42
@export_range(1, 100, 1) var level_2_claw_damage := 1
@export_range(1, 100, 1) var level_2_cannon_damage := 2
@export_range(0.1, 10.0, 0.1) var level_2_cannon_cooldown_seconds := 1.0
@export var level_2_cannon_travels_to_viewport_edge := true
@export_range(1.0, 500.0, 1.0) var level_2_cannon_max_distance := 100.0
@export_range(1.0, 1200.0, 1.0) var level_2_cannon_projectile_speed := 400.0
@export_range(0.0, 10.0, 0.05) var level_2_attack_recovery_seconds := 0.0
@export var level_2_cannon_origin_path: NodePath = ^"Level2CannonOrigin"
@export var level_2_cannon_projectile_path: NodePath = ^"Level2CannonProjectile"
@export_group("LV3 Dual Cannon Attack")
@export_range(0.1, 4.0, 0.1) var level_3_hit_speed_scale := 2.0
@export_range(1, 100, 1) var level_3_cannon_damage := 2
@export_range(0.1, 10.0, 0.1) var level_3_cannon_cooldown_seconds := 1.0
@export var level_3_cannons_travel_to_viewport_edge := true
@export_range(1.0, 500.0, 1.0) var level_3_cannon_max_distance := 100.0
@export_range(1.0, 1200.0, 1.0) var level_3_cannon_projectile_speed := 400.0
@export var level_3_left_cannon_origin_path: NodePath = ^"Level3LeftCannonOrigin"
@export var level_3_right_cannon_origin_path: NodePath = ^"Level3RightCannonOrigin"
@export_group("LV4 Minigun Attack")
@export_range(0.1, 10.0, 0.1) var level_4_hit_speed_scale := 7.0
@export_range(1, 100, 1) var level_4_minigun_damage := 2
@export_range(0.05, 10.0, 0.05) var level_4_minigun_cooldown_seconds := 0.15
@export var level_4_minigun_travels_to_viewport_edge := true
@export_range(1.0, 500.0, 1.0) var level_4_minigun_max_distance := 100.0
@export_range(1.0, 1600.0, 1.0) var level_4_minigun_projectile_speed := 620.0
@export_range(1.0, 40.0, 1.0) var level_4_minigun_round_spacing := 12.0
@export_range(0.05, 1.0, 0.05) var level_4_minigun_max_flight_seconds := 0.14
@export var level_4_minigun_origin_path: NodePath = ^"Level4MinigunOrigin"
@export var level_4_minigun_projectile_path: NodePath = ^"Level4MinigunProjectile"
@export var minigun_collision_shape_path: NodePath = \
	^"Level4MinigunProjectile/CollisionShape2D"
@export var level_4_minigun_muzzle_vfx_path: NodePath = ^"Level4MinigunMuzzleVFX"
@export_group("LV4 Other-Arm Cannon")
@export_range(1, 100, 1) var level_4_cannon_damage := 2
@export_range(0.1, 10.0, 0.1) var level_4_cannon_cooldown_seconds := 1.0
@export var level_4_cannon_travels_to_viewport_edge := true
@export_range(1.0, 500.0, 1.0) var level_4_cannon_max_distance := 100.0
@export_range(1.0, 1200.0, 1.0) var level_4_cannon_projectile_speed := 400.0
@export var level_4_cannon_origin_path: NodePath = ^"Level4CannonOrigin"
@export_group("LV5 Dual Miniguns")
@export_range(0.1, 30.0, 0.1) var level_5_hit_speed_scale := 21.0
@export_range(1, 100, 1) var level_5_minigun_damage := 2
@export_range(0.05, 10.0, 0.05) var level_5_minigun_cooldown_seconds := 0.15
@export var level_5_miniguns_travel_to_viewport_edge := true
@export_range(1.0, 500.0, 1.0) var level_5_minigun_max_distance := 100.0
@export_range(1.0, 2400.0, 1.0) var level_5_minigun_projectile_speed := 900.0
@export_range(1.0, 40.0, 1.0) var level_5_minigun_round_spacing := 12.0
@export_range(0.05, 1.0, 0.05) var level_5_minigun_max_flight_seconds := 0.14
@export var level_5_left_minigun_origin_path: NodePath = ^"Level5LeftMinigunOrigin"
@export var level_5_right_minigun_origin_path: NodePath = ^"Level5RightMinigunOrigin"
@export var level_5_left_minigun_muzzle_vfx_path: NodePath = ^"Level5LeftMinigunMuzzleVFX"
@export var level_5_right_minigun_muzzle_vfx_path: NodePath = ^"Level5RightMinigunMuzzleVFX"
@export_group("")
@export_group("Walking Motion")
@export_range(0.0, 24.0, 0.5) var head_bob_distance := 5.0
@export_range(0.1, 8.0, 0.1) var head_bob_cycles_per_second := 2.2
@export_range(1.0, 80.0, 1.0) var head_bob_return_speed := 24.0
@export_group("Dispatch")
@export_range(1.0, 800.0, 1.0) var dispatch_speed := 100.0
@export_range(0.0, 2.0, 0.05) var destination_turn_seconds := 0.5
@export var forward_rotation_offset := PI * 0.5
@export var destination_marker_path: NodePath = ^"DestinationMarker"
@export var destination_marker_fill_path: NodePath = ^"DestinationMarker/Fill"
@export var destination_marker_outline_path: NodePath = ^"DestinationMarker/Outline"
@export_range(8.0, 120.0, 1.0) var destination_marker_radius := 32.0
@export var destination_marker_fill_color := Color(0.12, 0.58, 1.0, 0.18)
@export var destination_marker_outline_color := Color(0.35, 0.84, 1.0, 0.92)
@export_range(0.0, 12.0, 0.1) var destination_marker_pulse_speed := 2.4
@export_group("Interaction")
@export var interaction_size := Vector2(360.0, 360.0)
@export var constrain_dispatch_to_viewport := true
@export_range(0.0, 256.0, 1.0) var viewport_border_padding := 18.0
@export_group("Virus Path Collision")
@export_flags_2d_physics var path_collision_mask := XDR_PATH_BLOCKER_COLLISION_LAYER
@export var movement_collision_shape_path: NodePath = ^"MovementCollision/CollisionShape2D"
@export_range(0.25, 10.0, 0.25) var blocked_destination_timeout := 3.0
@export_group("LV5 Jetpack Traversal")
@export var jetpack_visuals_path: NodePath = ^"Visuals"
@export var jetpack_vfx_path: NodePath = ^"Visuals/JetpackVFX"
@export_range(0.5, 10.0, 0.25) var jetpack_activation_seconds := 2.0
@export_range(0.0, 2.0, 0.05) var jetpack_pause_seconds := 0.5
@export_range(4.0, 160.0, 1.0) var jetpack_lift_distance := 42.0
@export_range(0.05, 2.0, 0.05) var jetpack_lift_seconds := 0.25
@export_range(0.05, 3.0, 0.05) var jetpack_cross_seconds := 0.55
@export_range(0.05, 2.0, 0.05) var jetpack_land_seconds := 0.3
@export_range(2.0, 40.0, 1.0) var jetpack_scan_step := 8.0
@export_range(0.0, 120.0, 1.0) var jetpack_landing_clearance := 20.0
@export_range(80.0, 600.0, 10.0) var jetpack_max_cross_distance := 240.0
@export_group("")
@export_group("Audio")
@export var deploy_sfx_path: NodePath = ^"Sounds/XDRMechDeploySfx"
@export var claw_sfx_path: NodePath = ^"Sounds/XDRMechClawSfx"
@export var cannon_sfx_path: NodePath = ^"Sounds/XDRMechCannonSfx"
@export var minigun_sfx_path: NodePath = ^"Sounds/XDRMechMinigunSfx"
@export_group("")

var _level_1_head: Sprite2D
var _level_2_head: Sprite2D
var _level_3_head: Sprite2D
var _level_4_head: Sprite2D
var _level_1_leg: AnimatedSprite2D
var _level_5_head: Sprite2D
var _level_5_leg: AnimatedSprite2D
var _head_visuals: Array[Sprite2D] = []
var _hit_animations: Array[AnimatedSprite2D] = []
var _head_rest_positions := {}
var _right_arm_hitbox: CollisionShape2D
var _left_arm_hitbox: CollisionShape2D
var _active_hit_animation: AnimatedSprite2D
var _claw_attack_active := false
var _active_attack_level := 0
var _last_hit_animation_frame := -1
var _claw_recovery_remaining := 0.0
var _targets_hit_this_attack := {}
var _level_2_cannon_origin: Marker2D
var _level_2_cannon_projectile: Node2D
var _level_3_left_cannon_origin: Marker2D
var _level_3_right_cannon_origin: Marker2D
var _level_4_minigun_origin: Marker2D
var _level_4_cannon_origin: Marker2D
var _level_4_minigun_projectile: Node2D
var _minigun_collision_shape: CollisionShape2D
var _level_4_minigun_muzzle_vfx: Node2D
var _level_4_minigun_muzzle_vfx_base_scale := Vector2.ONE
var _level_4_minigun_muzzle_tween: Tween
var _level_5_left_minigun_origin: Marker2D
var _level_5_right_minigun_origin: Marker2D
var _level_5_left_minigun_muzzle_vfx: Node2D
var _level_5_right_minigun_muzzle_vfx: Node2D
var _level_5_left_minigun_muzzle_vfx_base_scale := Vector2.ONE
var _level_5_right_minigun_muzzle_vfx_base_scale := Vector2.ONE
var _level_5_left_minigun_muzzle_tween: Tween
var _level_5_right_minigun_muzzle_tween: Tween
var _level_2_cannon_projectiles: Array[Node2D] = []
var _passive_cannon_cooldown_remaining := 1.0
var _level_4_cannon_cooldown_remaining := 1.0
var _level_4_minigun_pattern_index := 0
var _level_5_minigun_pattern_index := 0
var _cannon_shot_sequence := 0
var _destination_marker: Node2D
var _destination_marker_fill: Polygon2D
var _destination_marker_outline: Line2D
var _platform_highlight: ColorRect

var _home_position := Vector2.ZERO
var _home_rotation := 0.0
var _base_modulate := Color.WHITE
var _dragging := false
var _placed := false
var _drag_start_position := Vector2.ZERO
var _drag_offset := Vector2.ZERO
var _drag_is_valid := false
var _current_placement_shape: CollisionShape2D
var _dispatch_enabled := false
var _dispatch_destination := Vector2.ZERO
var _has_dispatch_destination := false
var _destination_turn_tween: Tween
var _turning_to_destination := false
var _destination_marker_phase := 0.0
var _walking := false
var _head_bob_phase := 0.0
var _movement_collision_node: CollisionShape2D
var _movement_collision_shape: Shape2D
var _path_blocked_elapsed := 0.0
var _jetpack_visuals: Node2D
var _jetpack_visuals_rest_position := Vector2.ZERO
var _jetpack_vfx: Node2D
var _jetpack_vfx_base_scale := Vector2.ONE
var _jetpack_tween: Tween
var _jetpack_active := false
var _jetpack_takeoff_position := Vector2.ZERO
var _jetpack_landing_position := Vector2.ZERO
var _deploy_sfx: AudioStreamPlayer
var _claw_sfx: AudioStreamPlayer
var _cannon_sfx: AudioStreamPlayer
var _minigun_sfx: AudioStreamPlayer


func _ready() -> void:
	add_to_group("Defender")
	add_to_group("OFFENSE_TOWER")
	_home_position = global_position
	_home_rotation = global_rotation
	_drag_start_position = _home_position
	_base_modulate = modulate
	_jetpack_visuals = get_node_or_null(jetpack_visuals_path) as Node2D
	if _jetpack_visuals != null:
		_jetpack_visuals_rest_position = _jetpack_visuals.position
	_jetpack_vfx = get_node_or_null(jetpack_vfx_path) as Node2D
	if _jetpack_vfx != null:
		_jetpack_vfx_base_scale = _jetpack_vfx.scale
		_jetpack_vfx.hide()
	_level_1_head = get_node_or_null(level_1_head_path) as Sprite2D
	_level_2_head = get_node_or_null(level_2_head_path) as Sprite2D
	_level_3_head = get_node_or_null(level_3_head_path) as Sprite2D
	_level_4_head = get_node_or_null(level_4_head_path) as Sprite2D
	_level_1_leg = get_node_or_null(level_1_leg_path) as AnimatedSprite2D
	_level_5_head = get_node_or_null(level_5_head_path) as Sprite2D
	_level_5_leg = get_node_or_null(level_5_leg_path) as AnimatedSprite2D
	_hit_animations = _resolve_hit_animations()
	var level_one_hit_animation := get_hit_animation(1)
	if level_one_hit_animation != null:
		level_one_hit_animation.speed_scale = level_1_hit_speed_scale
	var level_two_hit_animation := get_hit_animation(2)
	if level_two_hit_animation != null:
		level_two_hit_animation.speed_scale = level_2_hit_speed_scale
	var level_three_hit_animation := get_hit_animation(3)
	if level_three_hit_animation != null:
		level_three_hit_animation.speed_scale = level_3_hit_speed_scale
	var level_four_hit_animation := get_hit_animation(4)
	if level_four_hit_animation != null:
		level_four_hit_animation.speed_scale = level_4_hit_speed_scale
	var level_five_hit_animation := get_hit_animation(5)
	if level_five_hit_animation != null:
		level_five_hit_animation.speed_scale = level_5_hit_speed_scale
	_right_arm_hitbox = get_node_or_null(
		right_arm_hitbox_path
	) as CollisionShape2D
	_left_arm_hitbox = get_node_or_null(
		left_arm_hitbox_path
	) as CollisionShape2D
	_level_2_cannon_origin = get_node_or_null(
		level_2_cannon_origin_path
	) as Marker2D
	_level_2_cannon_projectile = get_node_or_null(
		level_2_cannon_projectile_path
	) as Node2D
	_level_3_left_cannon_origin = get_node_or_null(
		level_3_left_cannon_origin_path
	) as Marker2D
	_level_3_right_cannon_origin = get_node_or_null(
		level_3_right_cannon_origin_path
	) as Marker2D
	_level_4_minigun_origin = get_node_or_null(
		level_4_minigun_origin_path
	) as Marker2D
	_level_4_cannon_origin = get_node_or_null(
		level_4_cannon_origin_path
	) as Marker2D
	_level_4_minigun_projectile = get_node_or_null(
		level_4_minigun_projectile_path
	) as Node2D
	_minigun_collision_shape = get_node_or_null(
		minigun_collision_shape_path
	) as CollisionShape2D
	_level_4_minigun_muzzle_vfx = get_node_or_null(
		level_4_minigun_muzzle_vfx_path
	) as Node2D
	_level_5_left_minigun_origin = get_node_or_null(
		level_5_left_minigun_origin_path
	) as Marker2D
	_level_5_right_minigun_origin = get_node_or_null(
		level_5_right_minigun_origin_path
	) as Marker2D
	_level_5_left_minigun_muzzle_vfx = get_node_or_null(
		level_5_left_minigun_muzzle_vfx_path
	) as Node2D
	_level_5_right_minigun_muzzle_vfx = get_node_or_null(
		level_5_right_minigun_muzzle_vfx_path
	) as Node2D
	if _level_2_cannon_projectile != null:
		_level_2_cannon_projectile.hide()
	if _level_4_minigun_projectile != null:
		_level_4_minigun_projectile.hide()
	if _level_4_minigun_muzzle_vfx != null:
		_level_4_minigun_muzzle_vfx_base_scale = \
			_level_4_minigun_muzzle_vfx.scale
		_level_4_minigun_muzzle_vfx.hide()
	if _level_5_left_minigun_muzzle_vfx != null:
		_level_5_left_minigun_muzzle_vfx_base_scale = \
			_level_5_left_minigun_muzzle_vfx.scale
		_level_5_left_minigun_muzzle_vfx.hide()
	if _level_5_right_minigun_muzzle_vfx != null:
		_level_5_right_minigun_muzzle_vfx_base_scale = \
			_level_5_right_minigun_muzzle_vfx.scale
		_level_5_right_minigun_muzzle_vfx.hide()
	_passive_cannon_cooldown_remaining = _get_passive_cannon_cooldown()
	_level_4_cannon_cooldown_remaining = level_4_cannon_cooldown_seconds
	_head_visuals = [_level_1_head, _level_2_head, _level_3_head, _level_4_head, _level_5_head]
	for head in _head_visuals:
		if head != null:
			_head_rest_positions[head] = head.position
	for hit_animation in _hit_animations:
		if hit_animation == null:
			continue
		var finished_callback := Callable(
			self,
			"_on_hit_animation_finished"
		).bind(hit_animation)
		if not hit_animation.animation_finished.is_connected(
			finished_callback
		):
			hit_animation.animation_finished.connect(finished_callback)
	_destination_marker = get_node_or_null(destination_marker_path) as Node2D
	_destination_marker_fill = get_node_or_null(destination_marker_fill_path) as Polygon2D
	_destination_marker_outline = get_node_or_null(destination_marker_outline_path) as Line2D
	_platform_highlight = get_node_or_null(platform_highlight_path) as ColorRect
	_deploy_sfx = CentralAudioResolver.resolve(self, deploy_sfx_path)
	_claw_sfx = CentralAudioResolver.resolve(self, claw_sfx_path)
	_cannon_sfx = CentralAudioResolver.resolve(self, cannon_sfx_path)
	_minigun_sfx = CentralAudioResolver.resolve(self, minigun_sfx_path)
	_sync_movement_collision_shape()
	if _platform_highlight != null:
		_platform_highlight.hide()
	_configure_destination_marker()
	_sync_level_visuals()
	_set_walking(false)
	_ensure_continuous_claw_animation()


func _process(delta: float) -> void:
	if not _placed:
		_set_walking(false)
		_update_head_bob(delta)
		_update_destination_marker(delta)
		return

	_update_dispatch_movement(delta)
	_update_head_bob(delta)
	_update_destination_marker(delta)


func is_placed() -> bool:
	return _placed


func is_dragging() -> bool:
	return _dragging


func get_occupied_placement_shape() -> CollisionShape2D:
	return _current_placement_shape if _placed else null


func try_start_drag(pointer_position: Vector2) -> bool:
	if _placed or not visible or not contains_global_point(pointer_position):
		return false

	_dragging = true
	_drag_start_position = global_position
	_drag_offset = global_position - pointer_position
	if _platform_highlight != null:
		_platform_highlight.hide()
	update_drag(pointer_position)
	get_viewport().set_input_as_handled()
	return true


func update_drag(pointer_position: Vector2) -> void:
	if not _dragging:
		return

	global_position = pointer_position + _drag_offset
	_update_placement_state()
	get_viewport().set_input_as_handled()


func finish_drag() -> bool:
	if not _dragging:
		return false

	var was_placed := false
	if _drag_is_valid:
		global_position = _get_placement_area_center()
		_placed = true
		_ensure_continuous_claw_animation()
		was_placed = true
		_clear_drag_feedback()
		_spawn_summon_effect()
		_play_deploy_sfx()
		placed.emit(self)
	else:
		global_position = _drag_start_position
		_clear_drag_feedback()

	_dragging = false
	if _platform_highlight != null:
		_platform_highlight.hide()
	get_viewport().set_input_as_handled()
	return was_placed


func reset_tower() -> void:
	_cancel_destination_turn()
	_cancel_lv5_jetpack()
	_cancel_claw_attack(false)
	_cancel_level_2_cannon_projectile()
	_stop_attack_sfx()
	level = 1
	global_position = _home_position
	global_rotation = _home_rotation
	_dragging = false
	_placed = false
	_drag_is_valid = false
	_drag_offset = Vector2.ZERO
	_drag_start_position = _home_position
	_current_placement_shape = null
	_dispatch_enabled = false
	_has_dispatch_destination = false
	_path_blocked_elapsed = 0.0
	_claw_recovery_remaining = 0.0
	_clear_drag_feedback()
	_set_walking(false)
	_reset_head_bob()
	if _destination_marker != null:
		_destination_marker.hide()
	if _platform_highlight != null:
		_platform_highlight.hide()
	dispatch_mode_changed.emit(false)
	_ensure_continuous_claw_animation()


func _play_deploy_sfx() -> void:
	if _deploy_sfx == null:
		_deploy_sfx = CentralAudioResolver.resolve(self, deploy_sfx_path)
	if _deploy_sfx == null:
		return
	_deploy_sfx.stop()
	_deploy_sfx.play()


func _play_claw_sfx() -> void:
	if _claw_sfx == null:
		_claw_sfx = CentralAudioResolver.resolve(self, claw_sfx_path)
	_restart_audio_player(_claw_sfx)


func _play_cannon_sfx() -> void:
	if _cannon_sfx == null:
		_cannon_sfx = CentralAudioResolver.resolve(self, cannon_sfx_path)
	_restart_audio_player(_cannon_sfx)


func _play_minigun_sfx() -> void:
	if _minigun_sfx == null:
		_minigun_sfx = CentralAudioResolver.resolve(self, minigun_sfx_path)
	if _minigun_sfx == null or _minigun_sfx.playing:
		return
	_minigun_sfx.play()


func _restart_audio_player(player: AudioStreamPlayer) -> void:
	if player == null:
		return
	player.stop()
	player.play()


func _stop_attack_sfx() -> void:
	for player in [_claw_sfx, _cannon_sfx, _minigun_sfx]:
		if player != null:
			player.stop()


func set_dispatched(value: bool) -> void:
	if value and not _placed:
		return
	if _dispatch_enabled == value:
		return

	_dispatch_enabled = value
	if not value:
		_clear_dispatch_destination()
		_set_walking(false)
	dispatch_mode_changed.emit(_dispatch_enabled)


func toggle_dispatch() -> void:
	set_dispatched(not _dispatch_enabled)


func is_dispatched() -> bool:
	return _dispatch_enabled


func can_accept_dispatch_destination() -> bool:
	return _placed and _dispatch_enabled


func set_dispatch_destination(destination: Vector2) -> bool:
	if not can_accept_dispatch_destination():
		return false

	_cancel_lv5_jetpack()
	_dispatch_destination = _clamp_dispatch_position_to_viewport(destination)
	_has_dispatch_destination = true
	_path_blocked_elapsed = 0.0
	_set_walking(false)
	_begin_destination_turn()
	_sync_destination_marker_position()
	_update_destination_marker(0.0)
	destination_changed.emit(true, _dispatch_destination)
	return true


func has_dispatch_destination() -> bool:
	return _has_dispatch_destination


func get_dispatch_destination() -> Vector2:
	return _dispatch_destination


func get_path_blocked_elapsed() -> float:
	return _path_blocked_elapsed


func is_jetpacking() -> bool:
	return _jetpack_active


func get_level() -> int:
	return level


func get_max_level() -> int:
	return MAX_LEVEL


func can_upgrade() -> bool:
	return level < MAX_LEVEL


func get_upgrade_cost() -> int:
	return 0


func upgrade() -> bool:
	if not can_upgrade():
		return false
	level += 1
	return true


func set_level(value: int) -> void:
	level = value


func update_claw_attack(
	delta: float,
	active_viruses: Array[PathFollow2D]
) -> void:
	_update_level_2_cannon_projectile(active_viruses)
	_update_level_2_passive_cannon(delta)
	_claw_recovery_remaining = maxf(
		0.0,
		_claw_recovery_remaining - maxf(0.0, delta)
	)
	if not _placed:
		_ensure_continuous_claw_animation()
		return
	if level > 5:
		if _claw_attack_active:
			_cancel_claw_attack()
		return
	if level <= 2:
		_ensure_continuous_claw_animation()
		if _claw_attack_active:
			_process_claw_impact_frames(active_viruses)
	return


func _ensure_continuous_claw_animation() -> void:
	if level < 1 or level > 2:
		return
	if _claw_attack_active \
			and is_instance_valid(_active_hit_animation) \
			and _active_hit_animation.is_playing():
		return
	if _claw_attack_active:
		_cancel_claw_attack(false)
	_start_attack_for_current_level()


func is_claw_attack_active() -> bool:
	return _claw_attack_active


func get_hit_animation(level_to_get: int) -> AnimatedSprite2D:
	var index := level_to_get - 1
	if index < 0 or index >= _hit_animations.size():
		return null
	return _hit_animations[index]


func contains_global_point(pointer_position: Vector2) -> bool:
	return get_tower_rect().has_point(pointer_position)


func get_tower_rect() -> Rect2:
	var size := interaction_size * Vector2(absf(global_scale.x), absf(global_scale.y))
	# interaction_size is authored in unscaled scene pixels; keep a practical minimum in world space.
	size.x = maxf(size.x, 72.0)
	size.y = maxf(size.y, 72.0)
	return Rect2(global_position - size * 0.5, size)


func _sync_level_visuals() -> void:
	var use_level_5 := level >= MAX_LEVEL
	for index in range(_head_visuals.size()):
		var head := _head_visuals[index]
		if head != null:
			if _claw_attack_active:
				head.hide()
			else:
				head.visible = index == level - 1
	if _level_1_leg != null:
		_level_1_leg.visible = not use_level_5
	if _level_5_leg != null:
		_level_5_leg.visible = use_level_5
	for hit_animation in _hit_animations:
		if hit_animation != null:
			hit_animation.visible = _claw_attack_active \
				and hit_animation == _active_hit_animation
	_set_walking(_walking, true)


func _start_attack_for_current_level() -> void:
	if level < 1 or level > 5:
		return
	var hit_animation := get_hit_animation(level)
	if hit_animation == null or hit_animation.sprite_frames == null:
		return
	var animation_name: StringName = HIT_ANIMATION_NAMES[level - 1]
	if not hit_animation.sprite_frames.has_animation(animation_name):
		return

	_claw_attack_active = true
	_active_attack_level = level
	_active_hit_animation = hit_animation
	_last_hit_animation_frame = -1
	_targets_hit_this_attack.clear()
	_sync_level_visuals()
	match level:
		1:
			hit_animation.speed_scale = level_1_hit_speed_scale
		2:
			hit_animation.speed_scale = level_2_hit_speed_scale
		3:
			hit_animation.speed_scale = level_3_hit_speed_scale
		4:
			hit_animation.speed_scale = level_4_hit_speed_scale
		5:
			hit_animation.speed_scale = level_5_hit_speed_scale
	hit_animation.animation = animation_name
	hit_animation.frame = 0
	hit_animation.frame_progress = 0.0
	hit_animation.play()


func _process_claw_impact_frames(
	active_viruses: Array[PathFollow2D]
) -> void:
	if not is_instance_valid(_active_hit_animation):
		_cancel_claw_attack()
		return

	var current_frame := _active_hit_animation.frame
	if _active_attack_level <= 2 \
			and current_frame < _last_hit_animation_frame:
		_last_hit_animation_frame = -1
		_targets_hit_this_attack.clear()
	if _active_attack_level == 1:
		if _frame_was_reached(
			_last_hit_animation_frame,
			current_frame,
			left_arm_impact_frame
		):
			_play_claw_sfx()
			_emit_claw_hits(
				active_viruses,
				_left_arm_hitbox,
				level_1_claw_damage
			)
		if _frame_was_reached(
			_last_hit_animation_frame,
			current_frame,
			right_arm_impact_frame
		):
			_play_claw_sfx()
			_emit_claw_hits(
				active_viruses,
				_right_arm_hitbox,
				level_1_claw_damage
			)
	elif _active_attack_level == 2:
		if _frame_was_reached(
			_last_hit_animation_frame,
			current_frame,
			level_2_claw_impact_frame
		):
			_play_claw_sfx()
			_emit_claw_hits(
				active_viruses,
				_left_arm_hitbox,
				level_2_claw_damage
			)
	_last_hit_animation_frame = current_frame


func _frame_was_reached(
	previous_frame: int,
	current_frame: int,
	impact_frame: int
) -> bool:
	return previous_frame < impact_frame and current_frame >= impact_frame


func _emit_claw_hits(
	active_viruses: Array[PathFollow2D],
	hitbox: CollisionShape2D,
	damage: int
) -> void:
	if hitbox == null or hitbox.disabled or hitbox.shape == null:
		return
	for follow in active_viruses:
		if not is_instance_valid(follow) \
				or follow.is_queued_for_deletion() \
				or not _can_target_follow(follow):
			continue
		var target_id := follow.get_instance_id()
		if _targets_hit_this_attack.has(target_id):
			continue
		if not _hitbox_contains_target(hitbox, follow):
			continue
		_targets_hit_this_attack[target_id] = true
		claw_damage_requested.emit(follow, damage)


func _update_level_2_passive_cannon(delta: float) -> void:
	if not _placed or level < 2 or level > 5:
		return
	if level == 4:
		_update_level_4_passive_weapons(delta)
		return
	if level == 5:
		_update_level_5_passive_miniguns(delta)
		return
	_passive_cannon_cooldown_remaining -= maxf(0.0, delta)
	if _passive_cannon_cooldown_remaining > 0.0:
		return
	if level == 2:
		_fire_level_2_cannon()
	elif level == 3:
		_start_attack_for_current_level()
		_fire_level_3_dual_cannons()
	_passive_cannon_cooldown_remaining = _get_passive_cannon_cooldown()


func _update_level_4_passive_weapons(delta: float) -> void:
	var elapsed := maxf(0.0, delta)
	_passive_cannon_cooldown_remaining -= elapsed
	_level_4_cannon_cooldown_remaining -= elapsed
	if _passive_cannon_cooldown_remaining <= 0.0:
		_start_attack_for_current_level()
		var line_index := _fire_level_4_minigun_line()
		_play_level_4_minigun_muzzle_vfx(line_index)
		_passive_cannon_cooldown_remaining = maxf(
			0.1,
			level_4_minigun_cooldown_seconds
		)
	if _level_4_cannon_cooldown_remaining <= 0.0:
		_fire_level_4_other_arm_cannon()
		_level_4_cannon_cooldown_remaining = maxf(
			0.1,
			level_4_cannon_cooldown_seconds
		)


func _update_level_5_passive_miniguns(delta: float) -> void:
	_passive_cannon_cooldown_remaining -= maxf(0.0, delta)
	if _passive_cannon_cooldown_remaining > 0.0:
		return
	_start_attack_for_current_level()
	var line_index := _fire_level_5_dual_minigun_lines()
	_play_level_5_minigun_muzzle_vfx(line_index)
	_passive_cannon_cooldown_remaining = maxf(
		0.05,
		level_5_minigun_cooldown_seconds
	)


func _get_passive_cannon_cooldown() -> float:
	if level == 5:
		return maxf(0.05, level_5_minigun_cooldown_seconds)
	if level == 4:
		return maxf(0.1, level_4_minigun_cooldown_seconds)
	return maxf(
		0.1,
		level_3_cannon_cooldown_seconds
			if level == 3
			else level_2_cannon_cooldown_seconds
	)


func _fire_level_2_cannon() -> void:
	if _level_2_cannon_origin == null \
			or _level_2_cannon_projectile == null:
		return
	_spawn_cannon_projectile(
		_level_2_cannon_projectile,
		_level_2_cannon_origin,
		_get_cannon_hitbox_global_size(_right_arm_hitbox),
		level_2_cannon_damage,
		level_2_cannon_travels_to_viewport_edge,
		level_2_cannon_max_distance,
		level_2_cannon_projectile_speed,
		"Level2CannonShot"
	)
	_play_cannon_sfx()


func _fire_level_3_dual_cannons() -> void:
	_spawn_cannon_projectile(
		_level_2_cannon_projectile,
		_level_3_left_cannon_origin,
		_get_cannon_hitbox_global_size(_right_arm_hitbox),
		level_3_cannon_damage,
		level_3_cannons_travel_to_viewport_edge,
		level_3_cannon_max_distance,
		level_3_cannon_projectile_speed,
		"Level3LeftCannonShot"
	)
	_spawn_cannon_projectile(
		_level_2_cannon_projectile,
		_level_3_right_cannon_origin,
		_get_cannon_hitbox_global_size(_left_arm_hitbox),
		level_3_cannon_damage,
		level_3_cannons_travel_to_viewport_edge,
		level_3_cannon_max_distance,
		level_3_cannon_projectile_speed,
		"Level3RightCannonShot"
	)
	_play_cannon_sfx()


func _fire_level_4_minigun_line() -> int:
	if _level_4_minigun_origin == null \
			or _level_4_minigun_projectile == null:
		return -1
	var direction := get_facing_direction()
	var lateral := Vector2(-direction.y, direction.x)
	var spacing := maxf(1.0, level_4_minigun_round_spacing)
	var line_offsets: Array[Vector2] = [
		lateral * -1.4 * spacing,
		direction * spacing * 0.55 + lateral * 0.45 * spacing,
		direction * spacing * 1.1 + lateral * -0.45 * spacing,
		direction * spacing * 1.65 + lateral * 1.4 * spacing,
	]
	var line_index := _level_4_minigun_pattern_index \
		% line_offsets.size()
	_level_4_minigun_pattern_index = (
		_level_4_minigun_pattern_index + 1
	) % line_offsets.size()
	_remove_active_level_4_minigun_lines()
	_spawn_cannon_projectile(
		_level_4_minigun_projectile,
		_level_4_minigun_origin,
		get_minigun_collision_size(),
		level_4_minigun_damage,
		level_4_minigun_travels_to_viewport_edge,
		level_4_minigun_max_distance,
		level_4_minigun_projectile_speed,
		"Level4MinigunLine",
		line_offsets[line_index],
		&"level4_minigun",
		level_4_minigun_max_flight_seconds
	)
	_play_minigun_sfx()
	return line_index


func _fire_level_5_dual_minigun_lines() -> int:
	if _level_5_left_minigun_origin == null \
			or _level_5_right_minigun_origin == null \
			or _level_4_minigun_projectile == null:
		return -1
	var direction := get_facing_direction()
	var lateral := Vector2(-direction.y, direction.x)
	var spacing := maxf(1.0, level_5_minigun_round_spacing)
	var pattern_offsets: Array[Vector2] = [
		Vector2(0.0, -1.4),
		Vector2(0.55, 0.45),
		Vector2(1.1, -0.45),
		Vector2(1.65, 1.4),
	]
	var line_index := _level_5_minigun_pattern_index \
		% pattern_offsets.size()
	_level_5_minigun_pattern_index = (
		_level_5_minigun_pattern_index + 1
	) % pattern_offsets.size()
	var pattern_offset := pattern_offsets[line_index]
	var left_offset := (
		direction * pattern_offset.x
		+ lateral * pattern_offset.y
	) * spacing
	var right_offset := (
		direction * pattern_offset.x
		- lateral * pattern_offset.y
	) * spacing
	_remove_active_projectiles_of_kind(&"level5_left_minigun")
	_remove_active_projectiles_of_kind(&"level5_right_minigun")
	_spawn_cannon_projectile(
		_level_4_minigun_projectile,
		_level_5_left_minigun_origin,
		get_minigun_collision_size(),
		level_5_minigun_damage,
		level_5_miniguns_travel_to_viewport_edge,
		level_5_minigun_max_distance,
		level_5_minigun_projectile_speed,
		"Level5LeftMinigunLine",
		left_offset,
		&"level5_left_minigun",
		level_5_minigun_max_flight_seconds
	)
	_spawn_cannon_projectile(
		_level_4_minigun_projectile,
		_level_5_right_minigun_origin,
		get_minigun_collision_size(),
		level_5_minigun_damage,
		level_5_miniguns_travel_to_viewport_edge,
		level_5_minigun_max_distance,
		level_5_minigun_projectile_speed,
		"Level5RightMinigunLine",
		right_offset,
		&"level5_right_minigun",
		level_5_minigun_max_flight_seconds
	)
	_play_minigun_sfx()
	return line_index


func _fire_level_4_other_arm_cannon() -> void:
	_spawn_cannon_projectile(
		_level_2_cannon_projectile,
		_level_4_cannon_origin,
		_get_cannon_hitbox_global_size(_left_arm_hitbox),
		level_4_cannon_damage,
		level_4_cannon_travels_to_viewport_edge,
		level_4_cannon_max_distance,
		level_4_cannon_projectile_speed,
		"Level4OtherArmCannonShot",
		Vector2.ZERO,
		&"level4_cannon"
	)
	_play_cannon_sfx()


func _play_level_4_minigun_muzzle_vfx(line_index: int) -> void:
	if _level_4_minigun_muzzle_vfx == null or line_index < 0:
		return
	if _level_4_minigun_muzzle_tween != null:
		_level_4_minigun_muzzle_tween.kill()
	for index in range(_level_4_minigun_muzzle_vfx.get_child_count()):
		_level_4_minigun_muzzle_vfx.get_child(index).visible = \
			index == line_index
	_level_4_minigun_muzzle_vfx.scale = \
		_level_4_minigun_muzzle_vfx_base_scale * 0.76
	_level_4_minigun_muzzle_vfx.modulate = Color.WHITE
	_level_4_minigun_muzzle_vfx.show()
	_level_4_minigun_muzzle_tween = create_tween()
	_level_4_minigun_muzzle_tween.set_parallel(true)
	_level_4_minigun_muzzle_tween.tween_property(
		_level_4_minigun_muzzle_vfx,
		"scale",
		_level_4_minigun_muzzle_vfx_base_scale * 1.18,
		0.24
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_level_4_minigun_muzzle_tween.tween_property(
		_level_4_minigun_muzzle_vfx,
		"modulate:a",
		0.0,
		0.24
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_level_4_minigun_muzzle_tween.chain().tween_callback(
		_finish_level_4_minigun_muzzle_vfx
	)


func _finish_level_4_minigun_muzzle_vfx() -> void:
	_level_4_minigun_muzzle_tween = null
	if _level_4_minigun_muzzle_vfx == null:
		return
	_level_4_minigun_muzzle_vfx.hide()
	_level_4_minigun_muzzle_vfx.modulate = Color.WHITE
	_level_4_minigun_muzzle_vfx.scale = \
		_level_4_minigun_muzzle_vfx_base_scale


func _cancel_level_4_minigun_muzzle_vfx() -> void:
	if _level_4_minigun_muzzle_tween != null:
		_level_4_minigun_muzzle_tween.kill()
		_level_4_minigun_muzzle_tween = null
	_finish_level_4_minigun_muzzle_vfx()


func _play_level_5_minigun_muzzle_vfx(line_index: int) -> void:
	if line_index < 0:
		return
	_level_5_left_minigun_muzzle_tween = _start_minigun_muzzle_vfx(
		_level_5_left_minigun_muzzle_vfx,
		_level_5_left_minigun_muzzle_vfx_base_scale,
		line_index,
		_level_5_left_minigun_muzzle_tween,
		_finish_level_5_left_minigun_muzzle_vfx
	)
	_level_5_right_minigun_muzzle_tween = _start_minigun_muzzle_vfx(
		_level_5_right_minigun_muzzle_vfx,
		_level_5_right_minigun_muzzle_vfx_base_scale,
		line_index,
		_level_5_right_minigun_muzzle_tween,
		_finish_level_5_right_minigun_muzzle_vfx
	)


func _start_minigun_muzzle_vfx(
	muzzle_vfx: Node2D,
	base_scale: Vector2,
	line_index: int,
	active_tween: Tween,
	finished_callback: Callable
) -> Tween:
	if muzzle_vfx == null:
		return null
	if active_tween != null:
		active_tween.kill()
	for index in range(muzzle_vfx.get_child_count()):
		muzzle_vfx.get_child(index).visible = index == line_index
	muzzle_vfx.scale = base_scale * 0.76
	muzzle_vfx.modulate = Color.WHITE
	muzzle_vfx.show()
	var muzzle_tween := create_tween()
	muzzle_tween.set_parallel(true)
	muzzle_tween.tween_property(
		muzzle_vfx,
		"scale",
		base_scale * 1.18,
		0.14
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	muzzle_tween.tween_property(
		muzzle_vfx,
		"modulate:a",
		0.0,
		0.14
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	muzzle_tween.chain().tween_callback(finished_callback)
	return muzzle_tween


func _finish_level_5_left_minigun_muzzle_vfx() -> void:
	_level_5_left_minigun_muzzle_tween = null
	_reset_minigun_muzzle_vfx(
		_level_5_left_minigun_muzzle_vfx,
		_level_5_left_minigun_muzzle_vfx_base_scale
	)


func _finish_level_5_right_minigun_muzzle_vfx() -> void:
	_level_5_right_minigun_muzzle_tween = null
	_reset_minigun_muzzle_vfx(
		_level_5_right_minigun_muzzle_vfx,
		_level_5_right_minigun_muzzle_vfx_base_scale
	)


func _reset_minigun_muzzle_vfx(
	muzzle_vfx: Node2D,
	base_scale: Vector2
) -> void:
	if muzzle_vfx == null:
		return
	muzzle_vfx.hide()
	muzzle_vfx.modulate = Color.WHITE
	muzzle_vfx.scale = base_scale


func _cancel_level_5_minigun_muzzle_vfx() -> void:
	if _level_5_left_minigun_muzzle_tween != null:
		_level_5_left_minigun_muzzle_tween.kill()
		_level_5_left_minigun_muzzle_tween = null
	if _level_5_right_minigun_muzzle_tween != null:
		_level_5_right_minigun_muzzle_tween.kill()
		_level_5_right_minigun_muzzle_tween = null
	_finish_level_5_left_minigun_muzzle_vfx()
	_finish_level_5_right_minigun_muzzle_vfx()


func _spawn_cannon_projectile(
	projectile_template: Node2D,
	origin_marker: Marker2D,
	collision_size: Vector2,
	damage: int,
	travels_to_viewport_edge: bool,
	max_distance: float,
	projectile_speed: float,
	projectile_name_prefix: String,
	origin_offset: Vector2 = Vector2.ZERO,
	projectile_kind: StringName = &"cannon",
	max_flight_seconds: float = 0.0
) -> void:
	if origin_marker == null or projectile_template == null:
		return
	var origin := origin_marker.global_position + origin_offset
	var direction := get_facing_direction()
	if direction.is_zero_approx():
		return
	var is_minigun_projectile := projectile_kind in [
		&"level4_minigun",
		&"level5_left_minigun",
		&"level5_right_minigun",
	]
	var authored_minigun_scale := projectile_template.global_scale
	var projectile := projectile_template.duplicate() as Node2D
	if projectile == null:
		return
	_cannon_shot_sequence += 1
	projectile.name = "%s%d" % [
		projectile_name_prefix,
		_cannon_shot_sequence,
	]
	add_child(projectile)
	projectile.top_level = true
	projectile.global_position = origin
	projectile.global_rotation = direction.angle()
	projectile.scale = (
		authored_minigun_scale
		if is_minigun_projectile
		else Vector2(0.72, 0.72)
	)
	projectile.modulate = Color.WHITE
	projectile.show()
	projectile.set_meta("collision_active", true)
	projectile.set_meta("last_position", origin)
	projectile.set_meta("collision_size", collision_size)
	projectile.set_meta("damage", damage)
	projectile.set_meta("projectile_kind", projectile_kind)
	_level_2_cannon_projectiles.append(projectile)

	var travel_distance := _get_cannon_travel_distance(
		origin,
		direction,
		travels_to_viewport_edge,
		max_distance,
		collision_size
	)
	var duration := travel_distance \
		/ maxf(1.0, projectile_speed)
	if max_flight_seconds > 0.0:
		duration = minf(duration, max_flight_seconds)
	var destination := origin + direction * travel_distance
	var projectile_tween := create_tween()
	projectile.set_meta("travel_tween", projectile_tween)
	projectile_tween.set_parallel(true)
	projectile_tween.tween_property(
		projectile,
		"global_position",
		destination,
		duration
	).set_trans(Tween.TRANS_LINEAR)
	if not is_minigun_projectile:
		projectile_tween.tween_property(
			projectile,
			"scale",
			Vector2(1.08, 1.08),
			duration
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	projectile_tween.tween_property(
		projectile,
		"modulate",
		Color(0.72, 0.94, 1.0, 0.35),
		duration
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	projectile_tween.chain().tween_callback(
		Callable(
			self,
			"_finish_level_2_cannon_projectile"
		).bind(projectile)
	)


func get_facing_direction() -> Vector2:
	return Vector2.RIGHT.rotated(
		global_rotation + forward_rotation_offset
	).normalized()


func _get_level_2_cannon_travel_distance(
	origin: Vector2,
	direction: Vector2
) -> float:
	return _get_cannon_travel_distance(
		origin,
		direction,
		level_2_cannon_travels_to_viewport_edge,
		level_2_cannon_max_distance,
		get_level_2_cannon_collision_size()
	)


func _get_cannon_travel_distance(
	origin: Vector2,
	direction: Vector2,
	travels_to_viewport_edge: bool,
	max_distance: float,
	collision_size: Vector2
) -> float:
	if not travels_to_viewport_edge:
		return maxf(1.0, max_distance)
	var viewport_rect := _get_world_viewport_rect()
	var distances: Array[float] = []
	if absf(direction.x) > 0.0001:
		for edge_x in [viewport_rect.position.x, viewport_rect.end.x]:
			var distance_to_x: float = (edge_x - origin.x) / direction.x
			var crossing_y := origin.y + direction.y * distance_to_x
			if distance_to_x > 0.0 \
					and crossing_y >= viewport_rect.position.y \
					and crossing_y <= viewport_rect.end.y:
				distances.append(distance_to_x)
	if absf(direction.y) > 0.0001:
		for edge_y in [viewport_rect.position.y, viewport_rect.end.y]:
			var distance_to_y: float = (edge_y - origin.y) / direction.y
			var crossing_x := origin.x + direction.x * distance_to_y
			if distance_to_y > 0.0 \
					and crossing_x >= viewport_rect.position.x \
					and crossing_x <= viewport_rect.end.x:
				distances.append(distance_to_y)
	if distances.is_empty():
		return maxf(1.0, max_distance)
	var distance_to_edge: float = distances.min()
	return maxf(
		1.0,
		distance_to_edge + collision_size.length() * 0.5
	)


func _get_world_viewport_rect() -> Rect2:
	var screen_rect := get_viewport().get_visible_rect()
	if screen_rect.size.x < 320.0 or screen_rect.size.y < 180.0:
		screen_rect = Rect2(
			Vector2.ZERO,
			Vector2(
				float(ProjectSettings.get_setting(
					"display/window/size/viewport_width",
					1920
				)),
				float(ProjectSettings.get_setting(
					"display/window/size/viewport_height",
					1080
				))
			)
		)
	var inverse_canvas := get_viewport().get_canvas_transform().affine_inverse()
	var top_left := inverse_canvas * screen_rect.position
	var bottom_right := inverse_canvas * screen_rect.end
	return Rect2(
		Vector2(
			minf(top_left.x, bottom_right.x),
			minf(top_left.y, bottom_right.y)
		),
		Vector2(
			absf(bottom_right.x - top_left.x),
			absf(bottom_right.y - top_left.y)
		)
	)


func _update_level_2_cannon_projectile(
	active_viruses: Array[PathFollow2D]
) -> void:
	var projectiles_snapshot: Array[Node2D] = \
		_level_2_cannon_projectiles.duplicate()
	for projectile in projectiles_snapshot:
		if not is_instance_valid(projectile):
			_level_2_cannon_projectiles.erase(projectile)
			continue
		if not bool(projectile.get_meta("collision_active", false)):
			continue
		var collision_size: Vector2 = projectile.get_meta(
			"collision_size",
			get_level_2_cannon_collision_size()
		)
		var last_position: Vector2 = projectile.get_meta(
			"last_position",
			projectile.global_position
		)
		var current_position := projectile.global_position
		var best_target: PathFollow2D
		var best_distance_squared := INF
		for follow in active_viruses:
			if not is_instance_valid(follow) \
					or follow.is_queued_for_deletion() \
					or not _can_target_follow(follow):
				continue
			var target_position := _get_follow_target_position(follow)
			if not _swept_cannon_collision_contains_target(
				last_position,
				current_position,
				target_position,
				collision_size
			):
				continue
			var travel_distance_squared := \
				_get_cannon_target_travel_distance_squared(
					last_position,
					current_position,
					target_position
				)
			if travel_distance_squared >= best_distance_squared:
				continue
			best_target = follow
			best_distance_squared = travel_distance_squared

		if best_target != null:
			cannon_damage_requested.emit(
				best_target,
				int(projectile.get_meta(
					"damage",
					level_2_cannon_damage
				))
			)
			var projectile_kind := StringName(projectile.get_meta(
				"projectile_kind",
				&""
			))
			if projectile_kind in [
				&"level4_minigun",
				&"level5_left_minigun",
				&"level5_right_minigun",
			]:
				_cancel_single_cannon_projectile(projectile)
			else:
				_play_level_2_cannon_impact(projectile)
			continue
		projectile.set_meta("last_position", current_position)


func get_minigun_collision_size() -> Vector2:
	return _get_cannon_hitbox_global_size(_minigun_collision_shape)


func get_level_2_cannon_collision_size() -> Vector2:
	return _get_cannon_hitbox_global_size(_right_arm_hitbox)


func _get_cannon_hitbox_global_size(
	hitbox: CollisionShape2D
) -> Vector2:
	if hitbox == null or hitbox.shape == null:
		return Vector2(28.0, 28.0)
	var shape_size := Vector2.ZERO
	if hitbox.shape is RectangleShape2D:
		shape_size = (
			hitbox.shape as RectangleShape2D
		).size
	elif hitbox.shape is CircleShape2D:
		var diameter := (
			hitbox.shape as CircleShape2D
		).radius * 2.0
		shape_size = Vector2(diameter, diameter)
	if shape_size.is_zero_approx():
		return Vector2(28.0, 28.0)
	var hitbox_transform := hitbox.global_transform
	return Vector2(
		shape_size.x * hitbox_transform.x.length(),
		shape_size.y * hitbox_transform.y.length()
	)


func _swept_cannon_collision_contains_target(
	segment_start: Vector2,
	segment_end: Vector2,
	target_position: Vector2,
	collision_size: Vector2
) -> bool:
	var segment := segment_end - segment_start
	var segment_length := segment.length()
	if segment_length <= 0.0001:
		return Rect2(
			-collision_size * 0.5,
			collision_size
		).has_point(target_position - segment_start)
	var direction := segment / segment_length
	var perpendicular := Vector2(-direction.y, direction.x)
	var target_offset := target_position - segment_start
	var longitudinal_distance := target_offset.dot(direction)
	var lateral_distance := absf(target_offset.dot(perpendicular))
	var half_size := collision_size * 0.5
	return longitudinal_distance >= -half_size.x \
		and longitudinal_distance <= segment_length + half_size.x \
		and lateral_distance <= half_size.y


func _get_cannon_target_travel_distance_squared(
	segment_start: Vector2,
	segment_end: Vector2,
	target_position: Vector2
) -> float:
	var segment := segment_end - segment_start
	var segment_length := segment.length()
	if segment_length <= 0.0001:
		return 0.0
	var projected_distance := clampf(
		(target_position - segment_start).dot(segment / segment_length),
		0.0,
		segment_length
	)
	return projected_distance * projected_distance


func _play_level_2_cannon_impact(projectile: Node2D) -> void:
	if not is_instance_valid(projectile):
		return
	projectile.set_meta("collision_active", false)
	var travel_tween: Tween
	if projectile.has_meta("travel_tween"):
		travel_tween = projectile.get_meta("travel_tween") as Tween
	if travel_tween != null:
		travel_tween.kill()
	projectile.modulate = Color(0.82, 0.97, 1.0, 1.0)
	var impact_tween := create_tween()
	projectile.set_meta("impact_tween", impact_tween)
	impact_tween.set_parallel(true)
	impact_tween.tween_property(
		projectile,
		"scale",
		Vector2(1.65, 1.65),
		0.1
	).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	impact_tween.tween_property(
		projectile,
		"modulate:a",
		0.0,
		0.1
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	impact_tween.chain().tween_callback(
		Callable(
			self,
			"_finish_level_2_cannon_projectile"
		).bind(projectile)
	)


func _finish_level_2_cannon_projectile(projectile: Node2D) -> void:
	_level_2_cannon_projectiles.erase(projectile)
	if is_instance_valid(projectile):
		projectile.queue_free()


func _remove_active_level_4_minigun_lines() -> void:
	_remove_active_projectiles_of_kind(&"level4_minigun")


func _remove_active_projectiles_of_kind(
	projectile_kind: StringName
) -> void:
	var projectiles_snapshot: Array[Node2D] = \
		_level_2_cannon_projectiles.duplicate()
	for projectile in projectiles_snapshot:
		if not is_instance_valid(projectile):
			continue
		if StringName(projectile.get_meta(
			"projectile_kind",
			&""
		)) != projectile_kind:
			continue
		_cancel_single_cannon_projectile(projectile)


func _cancel_single_cannon_projectile(projectile: Node2D) -> void:
	if not is_instance_valid(projectile):
		_level_2_cannon_projectiles.erase(projectile)
		return
	var travel_tween: Tween
	if projectile.has_meta("travel_tween"):
		travel_tween = projectile.get_meta("travel_tween") as Tween
	if travel_tween != null:
		travel_tween.kill()
	var impact_tween: Tween
	if projectile.has_meta("impact_tween"):
		impact_tween = projectile.get_meta("impact_tween") as Tween
	if impact_tween != null:
		impact_tween.kill()
	_level_2_cannon_projectiles.erase(projectile)
	projectile.queue_free()


func _cancel_level_2_cannon_projectile() -> void:
	var projectiles_snapshot: Array[Node2D] = \
		_level_2_cannon_projectiles.duplicate()
	for projectile in projectiles_snapshot:
		_cancel_single_cannon_projectile(projectile)
	_level_2_cannon_projectiles.clear()


func is_level_2_cannon_projectile_active() -> bool:
	return not _level_2_cannon_projectiles.is_empty()


func get_latest_level_2_cannon_projectile() -> Node2D:
	for index in range(
		_level_2_cannon_projectiles.size() - 1,
		-1,
		-1
	):
		var projectile := _level_2_cannon_projectiles[index]
		if is_instance_valid(projectile):
			return projectile
	return null


func get_active_cannon_projectiles() -> Array[Node2D]:
	var active_projectiles: Array[Node2D] = []
	for projectile in _level_2_cannon_projectiles:
		if is_instance_valid(projectile):
			active_projectiles.append(projectile)
	return active_projectiles


func _hitbox_contains_target(
	hitbox: CollisionShape2D,
	follow: PathFollow2D
) -> bool:
	if hitbox == null \
			or hitbox.disabled \
			or hitbox.shape == null \
			or not is_instance_valid(follow):
		return false
	var local_position := hitbox.global_transform.affine_inverse() \
		* _get_follow_target_position(follow)
	if hitbox.shape is RectangleShape2D:
		var rectangle := hitbox.shape as RectangleShape2D
		return Rect2(
			-rectangle.size * 0.5,
			rectangle.size
		).has_point(local_position)
	if hitbox.shape is CircleShape2D:
		var circle := hitbox.shape as CircleShape2D
		return local_position.length_squared() <= circle.radius * circle.radius
	return false


func _can_target_follow(follow: PathFollow2D) -> bool:
	var virus := _get_follow_virus(follow)
	return virus == null or virus.can_be_targeted_by(self)


func _get_follow_virus(follow: PathFollow2D) -> RedVirus:
	for child in follow.get_children():
		var virus := child as RedVirus
		if virus != null:
			return virus
	return null


func _get_follow_target_position(follow: PathFollow2D) -> Vector2:
	var virus := _get_follow_virus(follow)
	return virus.global_position if virus != null else follow.global_position


func _resolve_hit_animations() -> Array[AnimatedSprite2D]:
	var animations: Array[AnimatedSprite2D] = []
	for path in hit_animation_paths:
		animations.append(get_node_or_null(path) as AnimatedSprite2D)
	return animations


func _on_hit_animation_finished(
	finished_animation: AnimatedSprite2D
) -> void:
	if finished_animation != _active_hit_animation:
		return
	var finished_attack_level := _active_attack_level
	if finished_attack_level <= 2 and level == finished_attack_level:
		_last_hit_animation_frame = -1
		_targets_hit_this_attack.clear()
		finished_animation.frame = 0
		finished_animation.frame_progress = 0.0
		finished_animation.play()
		return
	_claw_attack_active = false
	_active_attack_level = 0
	_active_hit_animation = null
	_last_hit_animation_frame = -1
	_targets_hit_this_attack.clear()
	_claw_recovery_remaining = (
		level_2_attack_recovery_seconds
		if finished_attack_level == 2
		else level_1_attack_recovery_seconds
	)
	_sync_level_visuals()


func _cancel_claw_attack(refresh_visuals: bool = true) -> void:
	_claw_attack_active = false
	_active_attack_level = 0
	if is_instance_valid(_active_hit_animation):
		_active_hit_animation.stop()
		_active_hit_animation.frame = 0
		_active_hit_animation.visible = false
	_active_hit_animation = null
	_last_hit_animation_frame = -1
	_targets_hit_this_attack.clear()
	if refresh_visuals:
		_sync_level_visuals()


func _set_walking(value: bool, force: bool = false) -> void:
	if _walking == value and not force:
		return
	if value and not _walking:
		_head_bob_phase = 0.0
	_walking = value
	for visual in [_level_1_leg, _level_5_leg]:
		var sprite := visual as AnimatedSprite2D
		if sprite == null or sprite.sprite_frames == null:
			continue
		var animation_name := WALK_ANIMATION if value else IDLE_ANIMATION
		if not sprite.sprite_frames.has_animation(animation_name):
			continue
		sprite.animation = animation_name
		sprite.frame = 0
		sprite.frame_progress = 0.0
		if value:
			sprite.play()
		else:
			sprite.stop()
func _update_head_bob(delta: float) -> void:
	if _walking and head_bob_distance > 0.0:
		_head_bob_phase = fmod(_head_bob_phase + delta * head_bob_cycles_per_second, 1.0)
		var bob_offset := Vector2(0.0, sin(_head_bob_phase * TAU) * head_bob_distance)
		_set_head_offset(bob_offset)
		return

	for head in _head_visuals:
		if head == null:
			continue
		var rest_position: Vector2 = _head_rest_positions.get(head, head.position)
		head.position = head.position.move_toward(rest_position, head_bob_return_speed * delta)


func _set_head_offset(offset: Vector2) -> void:
	for head in _head_visuals:
		if head != null:
			var rest_position: Vector2 = _head_rest_positions.get(head, head.position)
			head.position = rest_position + offset


func _reset_head_bob() -> void:
	_head_bob_phase = 0.0
	_set_head_offset(Vector2.ZERO)


func _update_dispatch_movement(delta: float) -> void:
	if _jetpack_active:
		return
	if not _has_dispatch_destination:
		_path_blocked_elapsed = 0.0
		_set_walking(false)
		return

	_dispatch_destination = _clamp_dispatch_position_to_viewport(_dispatch_destination)
	_sync_destination_marker_position()
	var direction := _dispatch_destination - global_position
	if direction.length_squared() <= DESTINATION_EPSILON * DESTINATION_EPSILON:
		global_position = _dispatch_destination
		_clear_dispatch_destination()
		return
	if _turning_to_destination:
		_path_blocked_elapsed = 0.0
		_set_walking(false)
		return

	_set_walking(true)
	var next_position := global_position.move_toward(_dispatch_destination, dispatch_speed * delta)
	if _would_collide_with_virus_path(next_position):
		_path_blocked_elapsed += delta
		if level == MAX_LEVEL \
			and _path_blocked_elapsed >= jetpack_activation_seconds \
			and _prepare_lv5_jetpack_landing():
			_begin_lv5_jetpack()
			return
		if _path_blocked_elapsed >= blocked_destination_timeout:
			_clear_dispatch_destination()
		return

	_path_blocked_elapsed = 0.0
	global_position = next_position
	global_position = _clamp_dispatch_position_to_viewport(global_position)
	if global_position.distance_squared_to(_dispatch_destination) <= DESTINATION_EPSILON * DESTINATION_EPSILON:
		global_position = _dispatch_destination
		_clear_dispatch_destination()


func _begin_destination_turn() -> void:
	_cancel_destination_turn()
	var direction := _dispatch_destination - global_position
	if direction.length_squared() <= DESTINATION_EPSILON * DESTINATION_EPSILON:
		return

	var desired_rotation := direction.angle() - forward_rotation_offset
	var target_rotation := global_rotation + angle_difference(global_rotation, desired_rotation)
	if destination_turn_seconds <= 0.0 or is_equal_approx(global_rotation, target_rotation):
		global_rotation = target_rotation
		return

	_turning_to_destination = true
	_destination_turn_tween = create_tween()
	_destination_turn_tween.set_trans(Tween.TRANS_SINE)
	_destination_turn_tween.set_ease(Tween.EASE_IN_OUT)
	_destination_turn_tween.tween_property(self, "global_rotation", target_rotation, destination_turn_seconds)
	_destination_turn_tween.tween_callback(Callable(self, "_finish_destination_turn"))


func _finish_destination_turn() -> void:
	_turning_to_destination = false
	_destination_turn_tween = null


func _cancel_destination_turn() -> void:
	if _destination_turn_tween != null:
		_destination_turn_tween.kill()
		_destination_turn_tween = null
	_turning_to_destination = false


func _clear_dispatch_destination() -> void:
	_cancel_destination_turn()
	_cancel_lv5_jetpack()
	var had_destination := _has_dispatch_destination
	_has_dispatch_destination = false
	_path_blocked_elapsed = 0.0
	_set_walking(false)
	if _destination_marker != null:
		_destination_marker.hide()
	if had_destination:
		destination_changed.emit(false, global_position)


func _prepare_lv5_jetpack_landing() -> bool:
	var destination_offset := _dispatch_destination - global_position
	var destination_distance := destination_offset.length()
	if destination_distance <= DESTINATION_EPSILON:
		return false

	var direction := destination_offset / destination_distance
	var maximum_distance := minf(destination_distance, jetpack_max_cross_distance)
	var step_distance := maxf(2.0, jetpack_scan_step)
	var scan_distance := step_distance
	var crossed_blocker := false
	var last_blocked_distance := 0.0
	while scan_distance <= maximum_distance:
		var candidate := global_position + direction * scan_distance
		candidate = _clamp_dispatch_position_to_viewport(candidate)
		if _would_collide_with_virus_path(candidate):
			crossed_blocker = true
			last_blocked_distance = scan_distance
		elif crossed_blocker \
			and scan_distance - last_blocked_distance >= jetpack_landing_clearance:
			_jetpack_landing_position = candidate
			return true
		scan_distance += step_distance

	var clamped_destination := _clamp_dispatch_position_to_viewport(_dispatch_destination)
	if crossed_blocker and not _would_collide_with_virus_path(clamped_destination):
		_jetpack_landing_position = clamped_destination
		return true
	return false


func _begin_lv5_jetpack() -> void:
	if _jetpack_active or level != MAX_LEVEL:
		return

	_jetpack_active = true
	_jetpack_takeoff_position = global_position
	_path_blocked_elapsed = 0.0
	_set_walking(false)
	_reset_head_bob()
	if _jetpack_vfx != null:
		_jetpack_vfx.hide()
	if _jetpack_tween != null:
		_jetpack_tween.kill()

	var lifted_visual_position := _jetpack_visuals_rest_position
	if _jetpack_visuals != null:
		var local_origin := to_local(global_position)
		var local_lifted := to_local(global_position + Vector2.UP * jetpack_lift_distance)
		lifted_visual_position += local_lifted - local_origin

	_jetpack_tween = create_tween()
	_jetpack_tween.tween_interval(jetpack_pause_seconds)
	_jetpack_tween.tween_callback(Callable(self, "_activate_lv5_jetpack_vfx"))
	if _jetpack_visuals != null:
		_jetpack_tween.tween_property(
			_jetpack_visuals,
			"position",
			lifted_visual_position,
			jetpack_lift_seconds
		).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	else:
		_jetpack_tween.tween_interval(jetpack_lift_seconds)
	_jetpack_tween.tween_property(
		self,
		"global_position",
		_jetpack_landing_position,
		jetpack_cross_seconds
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if _jetpack_visuals != null:
		_jetpack_tween.tween_property(
			_jetpack_visuals,
			"position",
			_jetpack_visuals_rest_position,
			jetpack_land_seconds
		).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	else:
		_jetpack_tween.tween_interval(jetpack_land_seconds)
	_jetpack_tween.tween_callback(Callable(self, "_finish_lv5_jetpack"))


func _activate_lv5_jetpack_vfx() -> void:
	if not _jetpack_active or _jetpack_vfx == null:
		return
	_jetpack_vfx.scale = _jetpack_vfx_base_scale
	_jetpack_vfx.show()


func _finish_lv5_jetpack() -> void:
	_jetpack_tween = null
	_jetpack_active = false
	_path_blocked_elapsed = 0.0
	if _jetpack_visuals != null:
		_jetpack_visuals.position = _jetpack_visuals_rest_position
	if _jetpack_vfx != null:
		_jetpack_vfx.hide()
	if _has_dispatch_destination:
		_set_walking(true)


func _cancel_lv5_jetpack(restore_safe_position: bool = true) -> void:
	var was_active := _jetpack_active
	if _jetpack_tween != null:
		_jetpack_tween.kill()
		_jetpack_tween = null
	_jetpack_active = false
	if restore_safe_position and was_active and _would_collide_with_virus_path(global_position):
		global_position = _jetpack_takeoff_position
	if _jetpack_visuals != null:
		_jetpack_visuals.position = _jetpack_visuals_rest_position
	if _jetpack_vfx != null:
		_jetpack_vfx.scale = _jetpack_vfx_base_scale
		_jetpack_vfx.hide()


func _would_collide_with_virus_path(world_position: Vector2) -> bool:
	if path_collision_mask == 0 or not is_inside_tree() or get_world_2d() == null:
		return false
	if _movement_collision_node == null or _movement_collision_shape == null:
		_sync_movement_collision_shape()
	if _movement_collision_node == null or _movement_collision_shape == null or _movement_collision_node.disabled:
		return false

	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = _movement_collision_shape
	query.transform = _movement_collision_node.global_transform
	query.transform.origin += world_position - global_position
	query.collision_mask = path_collision_mask
	query.collide_with_bodies = true
	query.collide_with_areas = false
	return not get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty()


func _sync_movement_collision_shape() -> void:
	_movement_collision_node = get_node_or_null(movement_collision_shape_path) as CollisionShape2D
	_movement_collision_shape = _movement_collision_node.shape if _movement_collision_node != null else null


func _configure_destination_marker() -> void:
	if _destination_marker != null:
		_destination_marker.top_level = true
		_destination_marker.hide()
	if _destination_marker_fill != null:
		_destination_marker_fill.polygon = _build_destination_marker_points(false)
		_destination_marker_fill.color = destination_marker_fill_color
	if _destination_marker_outline != null:
		_destination_marker_outline.points = _build_destination_marker_points(true)
		_destination_marker_outline.default_color = destination_marker_outline_color


func _update_destination_marker(delta: float) -> void:
	if _destination_marker == null:
		return
	var should_show := visible and _placed and _dispatch_enabled and _has_dispatch_destination
	_destination_marker.visible = should_show
	if not should_show:
		return

	_destination_marker_phase += delta * destination_marker_pulse_speed
	_sync_destination_marker_position()
	var pulse := 0.82 + sin(_destination_marker_phase * TAU) * 0.18
	if _destination_marker_fill != null:
		var fill_color := destination_marker_fill_color
		fill_color.a *= pulse
		_destination_marker_fill.color = fill_color
	if _destination_marker_outline != null:
		var outline_color := destination_marker_outline_color
		outline_color.a *= pulse
		_destination_marker_outline.default_color = outline_color


func _sync_destination_marker_position() -> void:
	if _destination_marker == null or not _has_dispatch_destination:
		return
	_destination_marker.global_position = _dispatch_destination
	_destination_marker.global_rotation = 0.0
	_destination_marker.global_scale = Vector2.ONE


func _build_destination_marker_points(close_loop: bool) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(DESTINATION_MARKER_SEGMENTS):
		var angle := TAU * float(index) / float(DESTINATION_MARKER_SEGMENTS)
		points.append(Vector2(cos(angle), sin(angle)) * destination_marker_radius)
	if close_loop and not points.is_empty():
		points.append(points[0])
	return points


func _clamp_dispatch_position_to_viewport(world_position: Vector2) -> Vector2:
	if not constrain_dispatch_to_viewport or not is_inside_tree():
		return world_position
	var canvas_transform := get_canvas_transform()
	if is_zero_approx(canvas_transform.determinant()):
		return world_position

	var screen_position := canvas_transform * world_position
	var viewport_rect := GameplaySafeArea.get_centered_screen_rect(get_viewport())
	var world_size := interaction_size * Vector2(absf(global_scale.x), absf(global_scale.y))
	var radius := maxf(world_size.x, world_size.y) * 0.5 + viewport_border_padding
	var minimum := viewport_rect.position + Vector2.ONE * radius
	var maximum := viewport_rect.end - Vector2.ONE * radius
	if minimum.x > maximum.x:
		minimum.x = viewport_rect.get_center().x
		maximum.x = minimum.x
	if minimum.y > maximum.y:
		minimum.y = viewport_rect.get_center().y
		maximum.y = minimum.y
	var clamped_screen := Vector2(
		clampf(screen_position.x, minimum.x, maximum.x),
		clampf(screen_position.y, minimum.y, maximum.y)
	)
	return canvas_transform.affine_inverse() * clamped_screen


func _update_placement_state() -> void:
	_current_placement_shape = _find_placement_shape_at_position(global_position)
	_drag_is_valid = _current_placement_shape != null and not _is_placement_shape_occupied(_current_placement_shape)
	modulate = DRAG_VALID_MODULATE if _drag_is_valid else DRAG_INVALID_MODULATE
	if _platform_highlight != null:
		_platform_highlight.hide()


func _clear_drag_feedback() -> void:
	modulate = _base_modulate


func _find_placement_shape_at_position(position_to_test: Vector2) -> CollisionShape2D:
	var game_root := _get_game_root()
	if game_root == null:
		return null
	return _find_placement_slot_at_position(game_root, position_to_test)


func _find_placement_slot_at_position(node: Node, position_to_test: Vector2) -> CollisionShape2D:
	if node != self:
		var collision_shape := node as CollisionShape2D
		if _is_placement_slot_shape(collision_shape) and _placement_shape_contains_point(collision_shape, position_to_test):
			return collision_shape
	for child in node.get_children():
		var found_shape := _find_placement_slot_at_position(child, position_to_test)
		if found_shape != null:
			return found_shape
	return null


func _is_placement_slot_shape(collision_shape: CollisionShape2D) -> bool:
	if collision_shape == null or collision_shape.disabled or not collision_shape.shape is RectangleShape2D:
		return false
	var lower_name := String(collision_shape.name).to_lower()
	if not lower_name.begins_with(PLACEMENT_SLOT_PREFIX):
		return false
	var suffix := lower_name.substr(PLACEMENT_SLOT_PREFIX.length())
	return not suffix.is_empty() and suffix.is_valid_int() and int(suffix) > 0


func _placement_shape_contains_point(collision_shape: CollisionShape2D, position_to_test: Vector2) -> bool:
	var rectangle_shape := collision_shape.shape as RectangleShape2D
	if rectangle_shape == null:
		return false
	var local_position := collision_shape.global_transform.affine_inverse() * position_to_test
	return Rect2(-rectangle_shape.size * 0.5, rectangle_shape.size).has_point(local_position)


func _get_placement_area_center() -> Vector2:
	return _current_placement_shape.global_position if _current_placement_shape != null else global_position


func _is_placement_shape_occupied(placement_shape: CollisionShape2D) -> bool:
	if placement_shape == null or not is_inside_tree():
		return false
	for node in get_tree().get_nodes_in_group("Defender"):
		if node == self or not is_instance_valid(node) or not node.has_method("get_occupied_placement_shape"):
			continue
		if node.call("get_occupied_placement_shape") as CollisionShape2D == placement_shape:
			return true
	return false


func _spawn_summon_effect() -> void:
	var game_root := _get_game_root()
	if game_root == null:
		return
	var effect := TowerSummonEffectScript.new() as Node2D
	effect.name = "%sSummonEffect" % name
	game_root.add_child(effect)
	effect.global_position = global_position
	effect.z_index = z_index + SUMMON_EFFECT_Z_OFFSET
	effect.z_as_relative = false


func _get_game_root() -> Node:
	if not is_inside_tree():
		return null
	return get_tree().current_scene
