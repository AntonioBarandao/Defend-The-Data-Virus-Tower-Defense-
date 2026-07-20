class_name EDRHunterTower
extends "res://Scripts/Towers/cyber_guardian_idle_sprite.gd"

const AIM_ANIMATION := &"AimAnim"
const EDR_MAX_LEVEL := 5
const EDR_DAMAGE := 10
const EDR_ATTACK_RANGE := 100000.0
const EDR_COOLDOWN := 3.0
const EDR_LASER_WIDTH := 12.0
const EDR_UPGRADE_COSTS := [85, 125, 175, 235, 0]
const HUNTER_AIM_SECONDS := 0.35
const DRONE_UNLOCK_LEVEL := 4
const SECOND_DRONE_UNLOCK_LEVEL := 5
const DRONE_DAMAGE := 1
const DRONE_COOLDOWN := 1.0

@export_group("Level Visuals")
@export var rotating_visual_path: NodePath = ^"RotatingVisual"
@export var level_visual_paths: Array[NodePath] = [
	^"RotatingVisual/LevelVisuals/LV1Visual",
	^"RotatingVisual/LevelVisuals/LV2Visual",
	^"RotatingVisual/LevelVisuals/LV3Visual",
	^"RotatingVisual/LevelVisuals/LV4Visual",
	^"RotatingVisual/LevelVisuals/LV5Visual"
]
@export_group("Drone")
@export var drone_path_follow_path: NodePath = ^"DronePath/DronePathFollow"
@export var drone_path: NodePath = ^"DronePath/DronePathFollow/EDR_Hunter_Drone"
@export var second_drone_path_follow_path: NodePath = ^"DronePath/DronePathFollow2"
@export var second_drone_path: NodePath = ^"DronePath/DronePathFollow2/EDR_Hunter_Drone2"
@export_range(0.0, 2000.0, 1.0) var drone_path_speed := 420.0
@export_range(0.1, 10.0, 0.1) var drone_shot_cooldown := DRONE_COOLDOWN
@export_group("")

var _rotating_visual: Node2D
var _level_visuals: Array[AnimatedSprite2D] = []
var _drone_path_follows: Array[PathFollow2D] = []
var _drones: Array[EDRHunterDrone] = []
var _drone_rest_progress_ratios: Array[float] = []
var _rest_visual_rotation := 0.0
var _hunter_is_aiming := false
var _hunter_aim_remaining := 0.0
var _drone_cooldown_remaining: Array[float] = []


func _ready() -> void:
	_cache_edr_nodes()
	show_attack_range_preview = false
	super._ready()
	if _rotating_visual != null:
		_rest_visual_rotation = _rotating_visual.rotation
	_sync_level_visual()
	_sync_drone_state()


func _process(delta: float) -> void:
	super._process(delta)
	var active_drone_count := get_active_drone_count()
	for index in mini(active_drone_count, _drone_path_follows.size()):
		var path_follow := _drone_path_follows[index]
		if path_follow != null:
			path_follow.progress += drone_path_speed * delta


func finish_drag() -> bool:
	var placed_now := super.finish_drag()
	_sync_drone_state()
	return placed_now


func reset_tower() -> void:
	super.reset_tower()
	_hunter_is_aiming = false
	_hunter_aim_remaining = 0.0
	for index in _drone_cooldown_remaining.size():
		_drone_cooldown_remaining[index] = 0.0
	if _rotating_visual != null:
		_rotating_visual.rotation = _rest_visual_rotation
	for index in _drone_path_follows.size():
		var path_follow := _drone_path_follows[index]
		if path_follow != null and index < _drone_rest_progress_ratios.size():
			path_follow.progress_ratio = _drone_rest_progress_ratios[index]
	_sync_level_visual()
	_sync_drone_state()


func set_menu_range_preview_active(_active: bool) -> void:
	super.set_menu_range_preview_active(false)


func get_shot_power() -> int:
	return EDR_DAMAGE


func get_attack_range() -> float:
	return EDR_ATTACK_RANGE * _get_signal_boost_range_multiplier()


func get_shot_cooldown() -> float:
	return EDR_COOLDOWN * _get_signal_boost_cooldown_multiplier()


func get_laser_width() -> float:
	return EDR_LASER_WIDTH


func get_max_level() -> int:
	return EDR_MAX_LEVEL


func can_upgrade() -> bool:
	return level < EDR_MAX_LEVEL


func get_upgrade_cost() -> int:
	if not can_upgrade():
		return 0

	return int(EDR_UPGRADE_COSTS[level])


func upgrade() -> bool:
	if not can_upgrade():
		return false

	level += 1
	_sync_level_visual()
	_sync_drone_state()
	return true


func can_scan_cloaked_viruses() -> bool:
	return true


func aim_at(target_position: Vector2) -> void:
	if _rotating_visual == null:
		return

	var direction := target_position - global_position
	if direction.length_squared() > 0.0:
		_rotating_visual.global_rotation = direction.angle() - forward_rotation_offset


func play_animation(animation_name: StringName) -> void:
	if _level_visuals.is_empty():
		_cache_edr_nodes()

	var level_index := clampi(level - 1, 0, EDR_MAX_LEVEL - 1)
	if level_index >= _level_visuals.size():
		return

	var visual := _level_visuals[level_index]
	if visual == null or visual.sprite_frames == null:
		return

	var track_prefix := "idle"
	if animation_name == SHOOT_ANIMATION:
		track_prefix = "shoot"
	elif animation_name == AIM_ANIMATION:
		track_prefix = "aim"
	var level_animation := StringName("%s_lv%d" % [track_prefix, level_index + 1])
	if not visual.sprite_frames.has_animation(level_animation):
		return

	_active_visual = visual
	_current_animation = IDLE_ANIMATION if track_prefix == "idle" else animation_name
	for candidate in _level_visuals:
		if candidate == null:
			continue
		candidate.visible = candidate == visual
		if candidate != visual:
			candidate.stop()

	visual.animation = level_animation
	visual.frame = 0
	visual.frame_progress = 0.0
	visual.play()


func play_aim() -> void:
	play_animation(AIM_ANIMATION)


func update_attack(delta: float, active_viruses: Array[PathFollow2D]) -> PathFollow2D:
	if not is_placed():
		_cancel_hunter_aim()
		_return_to_rest_state_if_not_shooting()
		return null

	_shot_cooldown_remaining = maxf(0.0, _shot_cooldown_remaining - delta)
	var target := _find_nearest_virus_in_range(active_viruses)
	if target == null:
		_cancel_hunter_aim()
		_return_to_rest_state_if_not_shooting()
		return null

	aim_at(_get_follow_target_position(target))
	if _shot_cooldown_remaining > 0.0 or _current_animation == SHOOT_ANIMATION:
		return null

	if not _hunter_is_aiming:
		_hunter_is_aiming = true
		_hunter_aim_remaining = HUNTER_AIM_SECONDS
		play_aim()

	_hunter_aim_remaining = maxf(0.0, _hunter_aim_remaining - delta)
	if _hunter_aim_remaining > 0.0:
		return null

	_hunter_is_aiming = false
	_shot_cooldown_remaining = get_shot_cooldown()
	return target


func update_drone_attack(delta: float, active_viruses: Array[PathFollow2D]) -> PathFollow2D:
	var attacks := update_drone_attacks(delta, active_viruses)
	if attacks.is_empty():
		return null

	return attacks[0].get("target") as PathFollow2D


func update_drone_attacks(delta: float, active_viruses: Array[PathFollow2D]) -> Array[Dictionary]:
	_sync_drone_state()
	var attacks: Array[Dictionary] = []
	var active_drone_count := get_active_drone_count()
	for index in _drones.size():
		if index >= active_drone_count:
			_drone_cooldown_remaining[index] = 0.0
			continue

		var drone := _drones[index]
		if drone == null:
			continue
		_drone_cooldown_remaining[index] = maxf(0.0, _drone_cooldown_remaining[index] - delta)
		var target := _find_nearest_drone_target(active_viruses, index)
		if target == null:
			drone.play_idle()
			continue

		drone.aim_at(_get_follow_target_position(target))
		if _drone_cooldown_remaining[index] > 0.0:
			drone.play_aim()
			continue

		_drone_cooldown_remaining[index] = drone_shot_cooldown * _get_signal_boost_cooldown_multiplier()
		attacks.append({"drone_index": index, "target": target})

	return attacks


func get_drone_shot_power() -> int:
	return DRONE_DAMAGE


func get_drone_attack_origin(drone_index: int = 0) -> Vector2:
	if drone_index >= 0 and drone_index < _drones.size() and _drones[drone_index] != null:
		return _drones[drone_index].global_position

	return global_position


func fire_drone_at(target_position: Vector2, drone_index: int = 0) -> void:
	if drone_index < 0 or drone_index >= _drones.size():
		return

	var drone := _drones[drone_index]
	if drone == null:
		return
	drone.aim_at(target_position)
	drone.play_shoot()


func is_drone_unlocked() -> bool:
	return level >= DRONE_UNLOCK_LEVEL


func get_active_drone_count() -> int:
	if not is_placed() or not is_drone_unlocked():
		return 0
	if level >= SECOND_DRONE_UNLOCK_LEVEL:
		return mini(2, _drones.size())

	return mini(1, _drones.size())


func _cache_edr_nodes() -> void:
	_rotating_visual = get_node_or_null(rotating_visual_path) as Node2D
	_drone_path_follows = [
		get_node_or_null(drone_path_follow_path) as PathFollow2D,
		get_node_or_null(second_drone_path_follow_path) as PathFollow2D,
	]
	_drones = [
		get_node_or_null(drone_path) as EDRHunterDrone,
		get_node_or_null(second_drone_path) as EDRHunterDrone,
	]
	_drone_rest_progress_ratios.clear()
	_drone_cooldown_remaining.clear()
	for path_follow in _drone_path_follows:
		_drone_rest_progress_ratios.append(path_follow.progress_ratio if path_follow != null else 0.0)
		_drone_cooldown_remaining.append(0.0)
	_level_visuals.clear()
	for visual_path in level_visual_paths:
		var visual := get_node_or_null(visual_path) as AnimatedSprite2D
		_level_visuals.append(visual)
		if visual == null:
			continue
		var callback := Callable(self, "_on_level_animation_finished").bind(visual)
		if not visual.animation_finished.is_connected(callback):
			visual.animation_finished.connect(callback)


func _sync_level_visual() -> void:
	play_animation(IDLE_ANIMATION)


func _sync_drone_state() -> void:
	var active_drone_count := get_active_drone_count()
	for index in _drones.size():
		var drone := _drones[index]
		if drone != null:
			drone.set_deployed_active(index < active_drone_count)


func _is_drone_active() -> bool:
	return get_active_drone_count() > 0


func _find_nearest_drone_target(active_viruses: Array[PathFollow2D], drone_index: int = 0) -> PathFollow2D:
	var origin := get_drone_attack_origin(drone_index)
	var nearest_target: PathFollow2D
	var nearest_distance_squared := INF
	for follow in active_viruses:
		if not is_instance_valid(follow) or not _can_target_follow(follow):
			continue

		var distance_squared := origin.distance_squared_to(_get_follow_target_position(follow))
		if distance_squared >= nearest_distance_squared:
			continue
		nearest_target = follow
		nearest_distance_squared = distance_squared

	return nearest_target


func _cancel_hunter_aim() -> void:
	_hunter_is_aiming = false
	_hunter_aim_remaining = 0.0
	if _current_animation == AIM_ANIMATION:
		play_idle()


func _return_to_rest_state() -> void:
	_shot_pose_active = false
	if _rotating_visual != null:
		_rotating_visual.rotation = _rest_visual_rotation
	if _current_animation == SHOOT_ANIMATION or _current_animation == AIM_ANIMATION:
		play_idle()


func _on_level_animation_finished(visual: AnimatedSprite2D) -> void:
	if visual == _active_visual and _current_animation == SHOOT_ANIMATION:
		play_idle()
