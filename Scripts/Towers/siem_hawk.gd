class_name SIEMHawkTower
extends Node2D

signal placed(tower: SIEMHawkTower)
signal dispatch_mode_changed(dispatched: bool)
signal knowledge_bank_changed(banked_points: int)
signal knowledge_extracted(amount: int)

const TowerSummonEffectScript := preload("res://Scripts/Effects/tower_summon_effect.gd")
const IDLE_ANIMATION := &"idle"
const SUMMON_ANIMATION := &"SummonAnim"
const SHOOT_ANIMATION := &"ShootAnim"
const SIEM_MAX_LEVEL := 5
const SIEM_DAMAGE := 10
const SIEM_ATTACK_RANGE := 360.0
const SIEM_COOLDOWN := 3.0
const SIEM_LASER_WIDTH := 12.0
const SIEM_UPGRADE_COSTS := [0, 0, 0, 0, 0]
const RED_VIRUS_KNOWLEDGE_POINTS := 1
const TROJAN_HORSE_KNOWLEDGE_POINTS := 5
const KNOWLEDGE_EXTRACTION_SECONDS := 3.0
const DISPATCH_SPEED_MULTIPLIERS_BY_LEVEL := [1.0, 1.35, 1.70, 2.10, 2.50]
const KNOWLEDGE_EXTRACTION_MULTIPLIERS_BY_LEVEL := [1.0, 2.0, 3.0, 4.0, 5.0]
const ARC_SEGMENTS := 36
const LANDING_DISTANCE_EPSILON := 2.0
const DESTINATION_DISTANCE_EPSILON := 2.0
const DESTINATION_MARKER_SEGMENTS := 48
const GRAB_SIZE := Vector2(220, 220)
const PLACEMENT_HIGHLIGHT_SIZE := Vector2(180, 120)
const PLACEMENT_SLOT_PREFIX := "placementslot"
const SIGNAL_BOOST_RANGE_MULTIPLIER := 1.1
const SIGNAL_BOOST_COOLDOWN_MULTIPLIER := 0.9
const SIGNAL_BOOST_HAWK_SPEED_MULTIPLIER := 1.2
const SHOT_RETURN_DELAY := 3.0
const RANGE_PREVIEW_SEGMENTS := 96
const RANGE_PREVIEW_FILL_COLOR := Color(0.27, 0.55, 1.0, 0.16)
const RANGE_PREVIEW_OUTLINE_COLOR := Color(0.48, 0.83, 1.0, 0.78)
const SIEM_HAWK_VISUAL_Z_INDEX := 180
const SUMMON_EFFECT_Z_OFFSET := -1
const DRAG_VALID_MODULATE := Color(0.42, 1.0, 0.46, 0.84)
const DRAG_INVALID_MODULATE := Color(1.0, 0.22, 0.2, 0.84)

@export var platform_highlight_path: NodePath = ^"../../PlatformHighlight"
@export var forward_rotation_offset := PI * 0.5
@export_range(1, SIEM_MAX_LEVEL, 1) var level := 1
@export var show_attack_range_preview := true
@export var range_preview_fill_color := RANGE_PREVIEW_FILL_COLOR
@export var range_preview_outline_color := RANGE_PREVIEW_OUTLINE_COLOR
@export_group("Rendering")
@export var tower_visual_z_index := SIEM_HAWK_VISUAL_Z_INDEX
@export_group("Level Visuals")
@export var level_1_visual_path: NodePath = ^"LevelVisuals/LV1Visual"
@export var level_2_visual_path: NodePath = ^"LevelVisuals/LV2Visual"
@export var level_3_visual_path: NodePath = ^"LevelVisuals/LV3Visual"
@export var level_4_visual_path: NodePath = ^"LevelVisuals/LV4Visual"
@export var level_5_visual_path: NodePath = ^"LevelVisuals/LV5Visual"
@export_group("Base")
@export var base_sprite_path: NodePath = ^"BaseSprite"
@export var base_global_rotation := 0.0
@export var base_z_index := 59
@export_group("Dispatch")
@export_range(1.0, 400.0, 1.0) var dispatch_speed := 100.0
@export_range(0.0, 2.0, 0.05) var destination_turn_seconds := 0.5
@export var destination_marker_path: NodePath = ^"DestinationMarker"
@export var destination_marker_fill_path: NodePath = ^"DestinationMarker/Fill"
@export var destination_marker_outline_path: NodePath = ^"DestinationMarker/Outline"
@export_range(8.0, 120.0, 1.0) var destination_marker_radius := 36.0
@export var destination_marker_fill_color := Color(0.12, 0.58, 1.0, 0.18)
@export var destination_marker_outline_color := Color(0.35, 0.84, 1.0, 0.92)
@export_range(0.0, 12.0, 0.1) var destination_marker_pulse_speed := 2.4
@export_group("Screen Border")
@export var constrain_dispatch_to_viewport := true
@export_range(0.0, 256.0, 1.0) var viewport_border_padding := 18.0
@export_group("Knowledge Scanner")
@export var scan_arc_fill_path: NodePath = ^"ScanArcFill"
@export var scan_arc_outline_path: NodePath = ^"ScanArcOutline"
@export var knowledge_label_path: NodePath = ^"KnowledgeHoverLabel"
@export var scan_arc_origin_offset := Vector2(0.0, 820.0)
@export_range(32.0, 1200.0, 1.0) var scan_arc_radius := 360.0
@export_range(5.0, 180.0, 1.0) var scan_arc_degrees := 70.0
@export var scan_arc_fill_color := Color(0.12, 0.56, 1.0, 0.16)
@export var scan_arc_outline_color := Color(0.34, 0.84, 1.0, 0.78)
@export var knowledge_label_offset := Vector2(-76.0, -96.0)
@export_range(0.0, 12.0, 0.1) var scan_arc_pulse_speed := 2.2
@export_group("Audio")
@export var summon_sfx_path: NodePath = ^"Audio/SummonSfx"
@export_group("")

var _level_visuals: Array[AnimatedSprite2D] = []
var _base_sprite: Sprite2D
var _scan_arc_fill: Polygon2D
var _scan_arc_outline: Line2D
var _knowledge_label: Label
var _summon_sfx: AudioStreamPlayer
var _platform_highlight: ColorRect
var _home_position := Vector2.ZERO
var _dragging := false
var _placed := false
var _drag_start_position := Vector2.ZERO
var _drag_offset := Vector2.ZERO
var _drag_is_valid := false
var _current_placement_shape: CollisionShape2D
var _shot_cooldown_remaining := 0.0
var _rest_rotation := 0.0
var _shot_pose_active := false
var _shot_return_tween: Tween
var _range_preview_fill: Polygon2D
var _range_preview_outline: Line2D
var _range_preview_radius := -1.0
var _menu_range_preview_active := false
var _base_modulate := Color.WHITE
var _signal_boost_active := false
var _station_position := Vector2.ZERO
var _dispatched := false
var _landing_to_headquarters := false
var _dispatch_destination := Vector2.ZERO
var _has_dispatch_destination := false
var _destination_turn_tween: Tween
var _turning_to_destination := false
var _destination_marker: Node2D
var _destination_marker_fill: Polygon2D
var _destination_marker_outline: Line2D
var _destination_marker_phase := 0.0
var _banked_knowledge_points := 0
var _scanned_virus_ids := {}
var _extraction_elapsed := 0.0
var _scan_arc_phase := 0.0
var _signal_boost_range_multiplier := SIGNAL_BOOST_RANGE_MULTIPLIER
var _signal_boost_cooldown_multiplier := SIGNAL_BOOST_COOLDOWN_MULTIPLIER
var _signal_boost_hawk_speed_multiplier := SIGNAL_BOOST_HAWK_SPEED_MULTIPLIER
var _last_visible_state := true


func _ready() -> void:
	add_to_group("Defender")
	add_to_group("OFFENSE_TOWER")
	_home_position = global_position
	_drag_start_position = _home_position
	_station_position = global_position
	_rest_rotation = rotation
	_base_modulate = modulate
	z_index = tower_visual_z_index
	z_as_relative = false
	_platform_highlight = get_node_or_null(platform_highlight_path) as ColorRect
	_summon_sfx = get_node_or_null(summon_sfx_path) as AudioStreamPlayer
	_base_sprite = get_node_or_null(base_sprite_path) as Sprite2D
	if _base_sprite != null:
		_base_sprite.top_level = true
		_base_sprite.z_as_relative = false
		_base_sprite.z_index = base_z_index
	_scan_arc_fill = get_node_or_null(scan_arc_fill_path) as Polygon2D
	_scan_arc_outline = get_node_or_null(scan_arc_outline_path) as Line2D
	_knowledge_label = get_node_or_null(knowledge_label_path) as Label
	_destination_marker = get_node_or_null(destination_marker_path) as Node2D
	_destination_marker_fill = get_node_or_null(destination_marker_fill_path) as Polygon2D
	_destination_marker_outline = get_node_or_null(destination_marker_outline_path) as Line2D
	if _platform_highlight != null:
		_platform_highlight.hide()
	_collect_level_visuals()
	_configure_top_level_scanner_nodes()
	_configure_destination_marker()
	_sync_level_visuals(true)
	play_idle()
	_last_visible_state = visible
	_sync_base_sprite()
	_update_scan_arc_visual(0.0)
	_sync_knowledge_label()


func _process(delta: float) -> void:
	if visible != _last_visible_state:
		_last_visible_state = visible
		_sync_level_visuals()
	_update_attack_range_preview()
	_sync_base_sprite()
	_update_scan_arc_visual(delta)
	_update_destination_marker(delta)
	_sync_knowledge_label()


func is_placed() -> bool:
	return _placed


func is_dragging() -> bool:
	return _dragging


func get_occupied_placement_shape() -> CollisionShape2D:
	return _current_placement_shape if _placed else null


func try_start_drag(pointer_position: Vector2) -> bool:
	if _placed or not contains_global_point(pointer_position):
		return false

	_dragging = true
	_drag_start_position = global_position
	_drag_offset = global_position - pointer_position
	_sync_level_visuals()
	if _platform_highlight != null:
		_platform_highlight.hide()
	update_drag(pointer_position)
	get_viewport().set_input_as_handled()
	return true


func update_drag(pointer_position: Vector2) -> void:
	if not _dragging:
		return

	global_position = pointer_position + _drag_offset
	_update_platform_highlight()
	_sync_base_sprite()
	get_viewport().set_input_as_handled()


func finish_drag() -> bool:
	if not _dragging:
		return false

	var was_placed := false
	if _drag_is_valid:
		global_position = _get_placement_area_center()
		_station_position = global_position
		_placed = true
		was_placed = true
		_clear_drag_feedback()
		play_summon()
		_spawn_summon_effect()
		placed.emit(self)
	else:
		global_position = _drag_start_position
		_clear_drag_feedback()

	if _platform_highlight != null:
		_platform_highlight.hide()
	_dragging = false
	_sync_base_sprite()
	get_viewport().set_input_as_handled()
	return was_placed


func reset_tower() -> void:
	level = 1
	set_signal_boost_active(false)
	global_position = _home_position
	rotation = _rest_rotation
	_station_position = global_position
	_dragging = false
	_placed = false
	_drag_is_valid = false
	_drag_offset = Vector2.ZERO
	_drag_start_position = _home_position
	_current_placement_shape = null
	_clear_drag_feedback()
	_shot_cooldown_remaining = 0.0
	_shot_pose_active = false
	if _shot_return_tween != null:
		_shot_return_tween.kill()
		_shot_return_tween = null
	_dispatched = false
	_landing_to_headquarters = false
	_clear_dispatch_destination()
	_banked_knowledge_points = 0
	_scanned_virus_ids.clear()
	_extraction_elapsed = 0.0
	if _platform_highlight != null:
		_platform_highlight.hide()
	_set_range_preview_visible(false)
	_sync_level_visuals(true)
	play_idle()
	dispatch_mode_changed.emit(_dispatched)
	knowledge_bank_changed.emit(_banked_knowledge_points)
	_sync_base_sprite()
	_update_scan_arc_visual(0.0)
	_sync_knowledge_label()


func set_dispatched(value: bool) -> void:
	if value and not is_placed():
		return
	if _dispatched == value and not _landing_to_headquarters:
		return

	_dispatched = value
	_landing_to_headquarters = false
	_clear_dispatch_destination()
	_extraction_elapsed = 0.0
	dispatch_mode_changed.emit(_dispatched)
	_sync_knowledge_label()


func toggle_dispatch() -> void:
	set_dispatched(not _dispatched)


func is_dispatched() -> bool:
	return _dispatched


func can_accept_dispatch_destination() -> bool:
	return is_placed() and _dispatched and not _landing_to_headquarters


func set_dispatch_destination(destination: Vector2) -> bool:
	if not can_accept_dispatch_destination():
		return false

	_dispatch_destination = _clamp_dispatch_position_to_viewport(destination)
	_has_dispatch_destination = true
	_begin_destination_turn()
	_sync_destination_marker_position()
	_update_destination_marker(0.0)
	return true


func has_dispatch_destination() -> bool:
	return _has_dispatch_destination


func get_dispatch_destination() -> Vector2:
	return _dispatch_destination


func is_turning_to_destination() -> bool:
	return _turning_to_destination


func is_landing_to_headquarters() -> bool:
	return _landing_to_headquarters


func is_at_headquarters() -> bool:
	return _is_at_headquarters()


func is_airborne_control_available() -> bool:
	return is_placed() and (_dispatched or _landing_to_headquarters or not _is_at_headquarters())


func get_headquarters_position() -> Vector2:
	return _station_position if is_placed() else global_position


func can_land_to_headquarters() -> bool:
	if not is_placed() or _landing_to_headquarters:
		return false

	return global_position.distance_squared_to(_station_position) > LANDING_DISTANCE_EPSILON * LANDING_DISTANCE_EPSILON


func land_to_headquarters() -> void:
	if not is_placed():
		return
	if not can_land_to_headquarters():
		_complete_landing_to_headquarters()
		return

	_landing_to_headquarters = true
	_dispatched = true
	_clear_dispatch_destination()
	_extraction_elapsed = 0.0
	dispatch_mode_changed.emit(_dispatched)
	_sync_knowledge_label()


func get_banked_knowledge_points() -> int:
	return _banked_knowledge_points


func update_knowledge_scan(delta: float, _mouse_global_position: Vector2, active_viruses: Array[PathFollow2D]) -> void:
	if not is_placed():
		return

	if _landing_to_headquarters:
		_update_landing_movement(delta)
		_extraction_elapsed = 0.0
	elif _dispatched:
		_update_dispatch_movement(delta)
		_scan_viruses_in_arc(active_viruses)
		_extraction_elapsed = 0.0
	elif not _is_at_headquarters():
		_scan_viruses_in_arc(active_viruses)
		_extraction_elapsed = 0.0
	else:
		_extract_banked_knowledge(delta)

	_sync_base_sprite()
	_update_scan_arc_visual(delta)
	_sync_knowledge_label()


func get_tower_scale() -> float:
	return scale.x


func get_level() -> int:
	return level


func get_shot_power() -> int:
	if level <= 1:
		return 0

	return SIEM_DAMAGE


func get_attack_range() -> float:
	if level <= 1:
		return 0.0

	return SIEM_ATTACK_RANGE * _get_signal_boost_range_multiplier()


func set_menu_range_preview_active(active: bool) -> void:
	_menu_range_preview_active = active
	_update_attack_range_preview()


func clear_range_preview() -> void:
	_menu_range_preview_active = false
	_set_range_preview_visible(false)
	if is_instance_valid(_range_preview_fill):
		_range_preview_fill.queue_free()
	if is_instance_valid(_range_preview_outline):
		_range_preview_outline.queue_free()
	_range_preview_fill = null
	_range_preview_outline = null
	_range_preview_radius = -1.0


func _exit_tree() -> void:
	clear_range_preview()


func get_shot_cooldown() -> float:
	return SIEM_COOLDOWN * _get_signal_boost_cooldown_multiplier()


func get_laser_width() -> float:
	return SIEM_LASER_WIDTH


func get_dispatch_speed() -> float:
	var signal_boost_multiplier := get_signal_boost_hawk_speed_multiplier() if is_signal_boost_active() else 1.0
	return dispatch_speed * get_level_dispatch_speed_multiplier() * signal_boost_multiplier


func get_level_dispatch_speed_multiplier() -> float:
	var level_index := clampi(level - 1, 0, DISPATCH_SPEED_MULTIPLIERS_BY_LEVEL.size() - 1)
	return float(DISPATCH_SPEED_MULTIPLIERS_BY_LEVEL[level_index])


func get_knowledge_extraction_multiplier() -> float:
	var level_index := clampi(level - 1, 0, KNOWLEDGE_EXTRACTION_MULTIPLIERS_BY_LEVEL.size() - 1)
	return float(KNOWLEDGE_EXTRACTION_MULTIPLIERS_BY_LEVEL[level_index])


func get_knowledge_extraction_seconds() -> float:
	return KNOWLEDGE_EXTRACTION_SECONDS / maxf(1.0, get_knowledge_extraction_multiplier())


func get_max_level() -> int:
	return SIEM_MAX_LEVEL


func can_upgrade() -> bool:
	return level < SIEM_MAX_LEVEL


func get_upgrade_cost() -> int:
	if not can_upgrade():
		return 0

	return int(SIEM_UPGRADE_COSTS[level])


func upgrade() -> bool:
	if not can_upgrade():
		return false

	level += 1
	_sync_level_visuals(true)
	play_idle()
	return true


func can_scan_cloaked_viruses() -> bool:
	return true


func set_signal_boost_active(active: bool) -> void:
	set_signal_boost_profile(
		active,
		SIGNAL_BOOST_RANGE_MULTIPLIER,
		SIGNAL_BOOST_COOLDOWN_MULTIPLIER,
		SIGNAL_BOOST_HAWK_SPEED_MULTIPLIER
	)


func set_signal_boost_profile(
	active: bool,
	range_multiplier: float,
	cooldown_multiplier: float,
	hawk_speed_multiplier: float = SIGNAL_BOOST_HAWK_SPEED_MULTIPLIER
) -> void:
	if _signal_boost_active == active:
		_signal_boost_range_multiplier = maxf(0.0, range_multiplier)
		_signal_boost_cooldown_multiplier = maxf(0.01, cooldown_multiplier)
		_signal_boost_hawk_speed_multiplier = maxf(0.0, hawk_speed_multiplier)
		_range_preview_radius = -1.0
		_update_attack_range_preview()
		return

	_signal_boost_active = active
	_signal_boost_range_multiplier = maxf(0.0, range_multiplier)
	_signal_boost_cooldown_multiplier = maxf(0.01, cooldown_multiplier)
	_signal_boost_hawk_speed_multiplier = maxf(0.0, hawk_speed_multiplier)
	_range_preview_radius = -1.0
	_update_attack_range_preview()


func is_signal_boost_active() -> bool:
	return _signal_boost_active


func get_signal_boost_range_multiplier() -> float:
	return _signal_boost_range_multiplier if _signal_boost_active else 1.0


func get_signal_boost_cooldown_multiplier() -> float:
	return _signal_boost_cooldown_multiplier if _signal_boost_active else 1.0


func get_signal_boost_hawk_speed_multiplier() -> float:
	return _signal_boost_hawk_speed_multiplier if _signal_boost_active else 1.0


func update_attack(delta: float, active_viruses: Array[PathFollow2D]) -> PathFollow2D:
	if level <= 1 or not _dispatched or _landing_to_headquarters or _has_dispatch_destination:
		if not _should_preserve_hawk_rotation():
			_return_to_rest_state_if_not_shooting()
		return null
	if not _placed:
		_return_to_rest_state_if_not_shooting()
		return null

	_shot_cooldown_remaining = maxf(0.0, _shot_cooldown_remaining - delta)
	if _shot_cooldown_remaining > 0.0:
		_return_to_rest_state_if_not_shooting()
		return null

	var target := _find_nearest_virus_in_range(active_viruses)
	if target == null:
		_return_to_rest_state_if_not_shooting()
		return null

	_shot_cooldown_remaining = get_shot_cooldown()
	return target


func contains_global_point(pointer_position: Vector2) -> bool:
	return contains_hawk_point(pointer_position) or contains_headquarters_point(pointer_position)


func contains_hawk_point(pointer_position: Vector2) -> bool:
	return get_tower_rect().has_point(pointer_position)


func contains_headquarters_point(pointer_position: Vector2) -> bool:
	return get_headquarters_rect().has_point(pointer_position)


func get_tower_rect() -> Rect2:
	var visual := _get_active_visual()
	var size := GRAB_SIZE
	var rect_position := global_position
	if visual != null and visual.sprite_frames != null and visual.sprite_frames.has_animation(visual.animation):
		var texture := visual.sprite_frames.get_frame_texture(visual.animation, visual.frame)
		if texture != null:
			var current_scale := visual.global_scale
			size = texture.get_size() * Vector2(abs(current_scale.x), abs(current_scale.y))
			rect_position = visual.global_position

	size.x = max(size.x, GRAB_SIZE.x)
	size.y = max(size.y, GRAB_SIZE.y)
	var top_left := rect_position - size * 0.5
	if visual != null and not visual.centered:
		top_left = rect_position

	return Rect2(top_left, size)


func get_headquarters_rect() -> Rect2:
	var size := PLACEMENT_HIGHLIGHT_SIZE
	var rect_position := get_headquarters_position()
	if _base_sprite != null and _base_sprite.texture != null:
		size = _base_sprite.texture.get_size() * Vector2(abs(global_scale.x), abs(global_scale.y))
		size.x = maxf(size.x, PLACEMENT_HIGHLIGHT_SIZE.x)
		size.y = maxf(size.y, PLACEMENT_HIGHLIGHT_SIZE.y)
		rect_position = get_headquarters_position()

	return Rect2(rect_position - size * 0.5, size)


func aim_at(target_position: Vector2) -> void:
	var direction := target_position - global_position
	if direction.length_squared() > 0.0:
		global_rotation = direction.angle() - forward_rotation_offset


func play_animation(animation_name: StringName) -> void:
	var visual := _get_active_visual()
	if visual == null or visual.sprite_frames == null:
		return

	var level_animation_name := _get_level_animation_name(animation_name)
	if not visual.sprite_frames.has_animation(level_animation_name):
		return

	visual.animation = level_animation_name
	visual.frame = 0
	visual.frame_progress = 0.0
	visual.play()


func play_summon() -> void:
	_play_audio_player(_summon_sfx)
	play_animation(SUMMON_ANIMATION)


func play_idle() -> void:
	play_animation(IDLE_ANIMATION)


func play_shoot() -> void:
	play_animation(SHOOT_ANIMATION)
	_schedule_return_to_rest_state()


func _collect_level_visuals() -> void:
	_level_visuals = [
		get_node_or_null(level_1_visual_path) as AnimatedSprite2D,
		get_node_or_null(level_2_visual_path) as AnimatedSprite2D,
		get_node_or_null(level_3_visual_path) as AnimatedSprite2D,
		get_node_or_null(level_4_visual_path) as AnimatedSprite2D,
		get_node_or_null(level_5_visual_path) as AnimatedSprite2D
	]
	for visual in _level_visuals:
		if visual == null:
			continue
		visual.z_index = maxi(visual.z_index, 0)
		visual.animation_finished.connect(_on_level_visual_animation_finished.bind(visual))


func _sync_level_visuals(force_idle := false) -> void:
	for index in range(_level_visuals.size()):
		var visual := _level_visuals[index]
		if visual == null:
			continue

		var visual_level := index + 1
		visual.visible = visible and visual_level == level
		if visual.visible:
			var idle_animation := _get_level_animation_name(IDLE_ANIMATION)
			if force_idle and visual.sprite_frames != null and visual.sprite_frames.has_animation(idle_animation):
				visual.animation = idle_animation
			if visual.sprite_frames != null and visual.sprite_frames.has_animation(visual.animation) and not visual.is_playing():
				visual.play()
		else:
			visual.stop()


func _get_active_visual() -> AnimatedSprite2D:
	var index := clampi(level - 1, 0, _level_visuals.size() - 1)
	if index >= 0 and index < _level_visuals.size():
		return _level_visuals[index]

	return null


func _get_level_animation_name(animation_name: StringName) -> StringName:
	var level_animation_name := StringName("%s_lv%d" % [String(animation_name), level])
	var visual := _get_active_visual()
	if visual != null and visual.sprite_frames != null and visual.sprite_frames.has_animation(level_animation_name):
		return level_animation_name

	return animation_name


func _is_current_level_animation(animation_name: StringName) -> bool:
	var visual := _get_active_visual()
	return visual != null and (visual.animation == animation_name or visual.animation == _get_level_animation_name(animation_name))


func _on_level_visual_animation_finished(visual: AnimatedSprite2D) -> void:
	if visual != _get_active_visual():
		return
	if not _is_current_level_animation(IDLE_ANIMATION):
		play_idle()


func _find_nearest_virus_in_range(active_viruses: Array[PathFollow2D]) -> PathFollow2D:
	var best_target: PathFollow2D
	var best_distance_squared := INF
	var attack_range := get_attack_range()
	var range_squared := attack_range * attack_range

	for follow in active_viruses:
		if not is_instance_valid(follow):
			continue
		if not _can_target_follow(follow):
			continue

		var target_position := _get_follow_target_position(follow)
		var distance_squared := global_position.distance_squared_to(target_position)
		if distance_squared > range_squared or distance_squared >= best_distance_squared:
			continue

		best_target = follow
		best_distance_squared = distance_squared

	return best_target


func _can_target_follow(follow: PathFollow2D) -> bool:
	var virus := _get_follow_virus(follow)
	return virus == null or virus.can_be_targeted_by(self)


func _get_follow_target_position(follow: PathFollow2D) -> Vector2:
	var virus := _get_follow_virus(follow)
	if virus != null:
		return virus.global_position

	return follow.global_position


func _should_preserve_hawk_rotation() -> bool:
	return is_placed() and (_dispatched or _landing_to_headquarters or not _is_at_headquarters())


func _update_dispatch_movement(delta: float) -> void:
	if not _has_dispatch_destination:
		global_position = _clamp_dispatch_position_to_viewport(global_position)
		return

	_dispatch_destination = _clamp_dispatch_position_to_viewport(_dispatch_destination)
	_sync_destination_marker_position()
	var direction := _dispatch_destination - global_position
	if direction.length_squared() <= DESTINATION_DISTANCE_EPSILON * DESTINATION_DISTANCE_EPSILON:
		global_position = _dispatch_destination
		_clear_dispatch_destination()
		return

	if _turning_to_destination:
		return

	global_position = global_position.move_toward(
		_dispatch_destination,
		maxf(0.0, get_dispatch_speed()) * delta
	)
	global_position = _clamp_dispatch_position_to_viewport(global_position)
	if global_position.distance_squared_to(_dispatch_destination) <= DESTINATION_DISTANCE_EPSILON * DESTINATION_DISTANCE_EPSILON:
		global_position = _dispatch_destination
		_clear_dispatch_destination()


func _update_landing_movement(delta: float) -> void:
	var direction := _station_position - global_position
	if direction.length_squared() <= LANDING_DISTANCE_EPSILON * LANDING_DISTANCE_EPSILON:
		_complete_landing_to_headquarters()
		return

	global_rotation = direction.angle() - forward_rotation_offset
	global_position = global_position.move_toward(_station_position, maxf(0.0, get_dispatch_speed()) * delta)
	if global_position.distance_squared_to(_station_position) <= LANDING_DISTANCE_EPSILON * LANDING_DISTANCE_EPSILON:
		_complete_landing_to_headquarters()


func _complete_landing_to_headquarters() -> void:
	global_position = _station_position
	_landing_to_headquarters = false
	_dispatched = false
	_clear_dispatch_destination()
	_extraction_elapsed = 0.0
	dispatch_mode_changed.emit(_dispatched)
	_sync_knowledge_label()


func _is_at_headquarters() -> bool:
	return global_position.distance_squared_to(_station_position) <= LANDING_DISTANCE_EPSILON * LANDING_DISTANCE_EPSILON


func _scan_viruses_in_arc(active_viruses: Array[PathFollow2D]) -> void:
	for follow in active_viruses:
		if not is_instance_valid(follow):
			continue

		var virus := _get_follow_virus(follow)
		if virus == null or virus.is_destroying():
			continue

		var virus_id := virus.get_instance_id()
		if _scanned_virus_ids.has(virus_id):
			continue
		if not _is_virus_in_scan_arc(virus):
			continue

		_scanned_virus_ids[virus_id] = true
		var knowledge_value := _get_virus_knowledge_value(virus)
		_banked_knowledge_points += knowledge_value
		knowledge_bank_changed.emit(_banked_knowledge_points)


func _extract_banked_knowledge(delta: float) -> void:
	if _banked_knowledge_points <= 0:
		_extraction_elapsed = 0.0
		return

	_extraction_elapsed += delta
	var extraction_seconds := get_knowledge_extraction_seconds()
	while _banked_knowledge_points > 0 and _extraction_elapsed >= extraction_seconds:
		_extraction_elapsed -= extraction_seconds
		_banked_knowledge_points -= 1
		knowledge_extracted.emit(1)
		knowledge_bank_changed.emit(_banked_knowledge_points)


func _get_follow_virus(follow: PathFollow2D) -> RedVirus:
	for child in follow.get_children():
		var virus := child as RedVirus
		if virus != null:
			return virus

	return null


func _get_virus_knowledge_value(virus: RedVirus) -> int:
	if virus.has_method("get_siem_knowledge_value"):
		return maxi(0, int(virus.call("get_siem_knowledge_value")))
	if virus is TrojanHorse:
		return TROJAN_HORSE_KNOWLEDGE_POINTS

	return RED_VIRUS_KNOWLEDGE_POINTS


func _is_virus_in_scan_arc(virus: RedVirus) -> bool:
	var scan_origin := _get_scan_origin_global_position()
	var offset := virus.global_position - scan_origin
	var distance_squared := offset.length_squared()
	if distance_squared <= 0.0:
		return true
	if distance_squared > scan_arc_radius * scan_arc_radius:
		return false

	var forward_angle := global_rotation + forward_rotation_offset
	var half_angle := deg_to_rad(scan_arc_degrees) * 0.5
	return absf(angle_difference(forward_angle, offset.angle())) <= half_angle


func _configure_top_level_scanner_nodes() -> void:
	if _scan_arc_fill != null:
		_scan_arc_fill.top_level = true
		_scan_arc_fill.z_as_relative = false
		_scan_arc_fill.z_index = 64
	if _scan_arc_outline != null:
		_scan_arc_outline.top_level = true
		_scan_arc_outline.z_as_relative = false
		_scan_arc_outline.z_index = 65
	if _knowledge_label != null:
		_knowledge_label.top_level = true
		_knowledge_label.z_as_relative = false
		_knowledge_label.z_index = 90


func _configure_destination_marker() -> void:
	if _destination_marker == null:
		return

	_destination_marker.top_level = true
	_destination_marker.z_as_relative = false
	_destination_marker.z_index = tower_visual_z_index - 2
	_destination_marker.visible = false
	var fill_points := _build_destination_marker_points(false)
	var outline_points := _build_destination_marker_points(true)
	if _destination_marker_fill != null:
		_destination_marker_fill.polygon = fill_points
		_destination_marker_fill.color = destination_marker_fill_color
	if _destination_marker_outline != null:
		_destination_marker_outline.points = outline_points
		_destination_marker_outline.default_color = destination_marker_outline_color


func _update_destination_marker(delta: float) -> void:
	if _destination_marker == null:
		return

	var should_show := visible and can_accept_dispatch_destination() and _has_dispatch_destination
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


func _clear_dispatch_destination() -> void:
	_cancel_destination_turn()
	_has_dispatch_destination = false
	if _destination_marker != null:
		_destination_marker.visible = false


func _begin_destination_turn() -> void:
	_cancel_destination_turn()
	var direction := _dispatch_destination - global_position
	if direction.length_squared() <= DESTINATION_DISTANCE_EPSILON * DESTINATION_DISTANCE_EPSILON:
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
	_destination_turn_tween.tween_property(
		self,
		"global_rotation",
		target_rotation,
		destination_turn_seconds
	)
	_destination_turn_tween.tween_callback(Callable(self, "_finish_destination_turn"))


func _finish_destination_turn() -> void:
	_turning_to_destination = false
	_destination_turn_tween = null


func _cancel_destination_turn() -> void:
	if _destination_turn_tween != null:
		_destination_turn_tween.kill()
		_destination_turn_tween = null
	_turning_to_destination = false


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
	var viewport_rect := get_viewport().get_visible_rect()
	var hawk_radius := _get_hawk_screen_radius() + viewport_border_padding
	var minimum := viewport_rect.position + Vector2.ONE * hawk_radius
	var maximum := viewport_rect.end - Vector2.ONE * hawk_radius
	if minimum.x > maximum.x:
		minimum.x = viewport_rect.get_center().x
		maximum.x = minimum.x
	if minimum.y > maximum.y:
		minimum.y = viewport_rect.get_center().y
		maximum.y = minimum.y

	var clamped_screen_position := Vector2(
		clampf(screen_position.x, minimum.x, maximum.x),
		clampf(screen_position.y, minimum.y, maximum.y)
	)
	return canvas_transform.affine_inverse() * clamped_screen_position


func _get_hawk_screen_radius() -> float:
	var visual := _get_active_visual()
	var center_screen := get_global_transform_with_canvas().origin
	var visual_rect := Rect2(-GRAB_SIZE * 0.5, GRAB_SIZE)
	var visual_transform := get_global_transform_with_canvas()
	if visual != null and visual.sprite_frames != null \
			and visual.sprite_frames.has_animation(visual.animation):
		var frame_texture := visual.sprite_frames.get_frame_texture(visual.animation, visual.frame)
		if frame_texture != null:
			var frame_size := frame_texture.get_size()
			var frame_position := visual.offset
			if visual.centered:
				frame_position -= frame_size * 0.5
			visual_rect = Rect2(frame_position, frame_size)
		visual_transform = visual.get_global_transform_with_canvas()

	var radius := 0.0
	for corner in [
		visual_rect.position,
		Vector2(visual_rect.end.x, visual_rect.position.y),
		visual_rect.end,
		Vector2(visual_rect.position.x, visual_rect.end.y),
	]:
		radius = maxf(radius, center_screen.distance_to(visual_transform * corner))
	return maxf(1.0, radius)


func _update_scan_arc_visual(delta: float) -> void:
	if _scan_arc_fill == null or _scan_arc_outline == null:
		return

	var should_show := is_placed() and not _landing_to_headquarters and (_dispatched or not _is_at_headquarters())
	_scan_arc_fill.visible = should_show
	_scan_arc_outline.visible = should_show
	if not should_show:
		return

	_scan_arc_phase += delta * scan_arc_pulse_speed
	var pulse_alpha := 0.72 + (sin(_scan_arc_phase * TAU) * 0.16)
	var fill_color := scan_arc_fill_color
	var outline_color := scan_arc_outline_color
	fill_color.a *= pulse_alpha
	outline_color.a *= pulse_alpha

	var points := _build_arc_points()
	var scan_origin := _get_scan_origin_global_position()
	_scan_arc_fill.global_position = scan_origin
	_scan_arc_fill.global_rotation = global_rotation
	_scan_arc_fill.color = fill_color
	_scan_arc_fill.polygon = points

	var outline_points := PackedVector2Array()
	outline_points.append(Vector2.ZERO)
	for index in range(1, points.size()):
		outline_points.append(points[index])
	outline_points.append(Vector2.ZERO)
	_scan_arc_outline.global_position = scan_origin
	_scan_arc_outline.global_rotation = global_rotation
	_scan_arc_outline.default_color = outline_color
	_scan_arc_outline.points = outline_points


func _get_scan_origin_global_position() -> Vector2:
	return to_global(scan_arc_origin_offset)


func _build_arc_points() -> PackedVector2Array:
	var points := PackedVector2Array()
	points.append(Vector2.ZERO)
	var half_angle := deg_to_rad(scan_arc_degrees) * 0.5
	for index in range(ARC_SEGMENTS + 1):
		var t := float(index) / float(ARC_SEGMENTS)
		var angle := forward_rotation_offset - half_angle + (half_angle * 2.0 * t)
		points.append(Vector2(cos(angle), sin(angle)) * scan_arc_radius)

	return points


func _sync_knowledge_label() -> void:
	if _knowledge_label == null:
		return

	_knowledge_label.visible = is_placed() and _banked_knowledge_points > 0
	if not _knowledge_label.visible:
		return

	_knowledge_label.text = "Temporary KP: %d" % _banked_knowledge_points
	_knowledge_label.global_position = global_position + knowledge_label_offset
	_knowledge_label.rotation = 0.0
	_knowledge_label.scale = Vector2.ONE


func _sync_base_sprite() -> void:
	if _base_sprite == null or not is_inside_tree():
		return

	if is_placed():
		_base_sprite.global_position = _station_position
	else:
		_base_sprite.global_position = global_position
	_base_sprite.global_rotation = base_global_rotation
	_base_sprite.global_scale = global_scale
	_base_sprite.visible = visible
	_base_sprite.modulate = modulate


func _update_platform_highlight() -> void:
	_current_placement_shape = _find_placement_shape_at_position(global_position)
	_drag_is_valid = _current_placement_shape != null and not _is_placement_shape_occupied(_current_placement_shape)
	_set_drag_feedback(_drag_is_valid)
	if _platform_highlight == null:
		return
	_platform_highlight.hide()


func _update_attack_range_preview() -> void:
	if not show_attack_range_preview:
		return

	var should_show := _dragging or _menu_range_preview_active
	if not should_show:
		_set_range_preview_visible(false)
		return

	_ensure_range_preview()
	if _range_preview_fill == null or _range_preview_outline == null:
		return

	var attack_range := get_attack_range()
	if not is_equal_approx(_range_preview_radius, attack_range):
		_range_preview_radius = attack_range
		_range_preview_fill.polygon = _build_range_preview_points(attack_range, false)
		_range_preview_outline.points = _build_range_preview_points(attack_range, true)

	_range_preview_fill.global_position = global_position
	_range_preview_outline.global_position = global_position
	_set_range_preview_visible(attack_range > 0.0)


func _ensure_range_preview() -> void:
	if is_instance_valid(_range_preview_fill) and is_instance_valid(_range_preview_outline):
		return

	var game_root := _get_game_root()
	if game_root == null:
		return

	_range_preview_fill = Polygon2D.new()
	_range_preview_fill.name = "%sRangePreviewFill" % name
	_range_preview_fill.color = range_preview_fill_color
	_range_preview_fill.z_index = 42
	game_root.add_child(_range_preview_fill)

	_range_preview_outline = Line2D.new()
	_range_preview_outline.name = "%sRangePreviewOutline" % name
	_range_preview_outline.width = 3.0
	_range_preview_outline.default_color = range_preview_outline_color
	_range_preview_outline.joint_mode = Line2D.LINE_JOINT_ROUND
	_range_preview_outline.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_range_preview_outline.end_cap_mode = Line2D.LINE_CAP_ROUND
	_range_preview_outline.antialiased = true
	_range_preview_outline.z_index = 43
	game_root.add_child(_range_preview_outline)

	_range_preview_radius = -1.0
	_set_range_preview_visible(false)


func _build_range_preview_points(radius: float, close_loop: bool) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(RANGE_PREVIEW_SEGMENTS):
		var angle := TAU * float(index) / float(RANGE_PREVIEW_SEGMENTS)
		points.append(Vector2(cos(angle), sin(angle)) * radius)

	if close_loop and not points.is_empty():
		points.append(points[0])

	return points


func _set_range_preview_visible(value: bool) -> void:
	if is_instance_valid(_range_preview_fill):
		_range_preview_fill.visible = value
	if is_instance_valid(_range_preview_outline):
		_range_preview_outline.visible = value


func _find_placement_shape_at_position(global_position_to_test: Vector2) -> CollisionShape2D:
	var game_root := _get_game_root()
	if game_root == null:
		return null

	return _find_placement_slot_at_position(game_root, global_position_to_test)


func _find_placement_slot_at_position(node: Node, global_position_to_test: Vector2) -> CollisionShape2D:
	if node != self:
		var collision_shape := node as CollisionShape2D
		if _is_placement_slot_shape(collision_shape) and _placement_shape_contains_point(collision_shape, global_position_to_test):
			return collision_shape

	for child in node.get_children():
		var found_shape := _find_placement_slot_at_position(child, global_position_to_test)
		if found_shape != null:
			return found_shape

	return null


func _is_placement_slot_shape(collision_shape: CollisionShape2D) -> bool:
	return collision_shape != null \
		and not collision_shape.disabled \
		and collision_shape.shape is RectangleShape2D \
		and _is_placement_slot_name(String(collision_shape.name))


func _is_placement_slot_name(node_name: String) -> bool:
	var lower_name := node_name.to_lower()
	if not lower_name.begins_with(PLACEMENT_SLOT_PREFIX):
		return false

	var suffix := lower_name.substr(PLACEMENT_SLOT_PREFIX.length())
	return not suffix.is_empty() and suffix.is_valid_int() and int(suffix) > 0


func _placement_shape_contains_point(collision_shape: CollisionShape2D, global_position_to_test: Vector2) -> bool:
	var rectangle_shape := collision_shape.shape as RectangleShape2D
	if rectangle_shape == null:
		return false

	var local_position := collision_shape.global_transform.affine_inverse() * global_position_to_test
	var rectangle := Rect2(-rectangle_shape.size * 0.5, rectangle_shape.size)
	return rectangle.has_point(local_position)


func _get_placement_area_center() -> Vector2:
	if _current_placement_shape != null:
		return _current_placement_shape.global_position

	return global_position


func _is_placement_shape_occupied(placement_shape: CollisionShape2D) -> bool:
	if placement_shape == null:
		return false

	for node in get_tree().get_nodes_in_group("Defender"):
		if node == self or not is_instance_valid(node):
			continue
		if not node.has_method("get_occupied_placement_shape"):
			continue

		var occupied_shape := node.call("get_occupied_placement_shape") as CollisionShape2D
		if occupied_shape == placement_shape:
			return true

	return false


func _set_drag_feedback(valid: bool) -> void:
	modulate = DRAG_VALID_MODULATE if valid else DRAG_INVALID_MODULATE
	_sync_base_sprite()


func _clear_drag_feedback() -> void:
	modulate = _base_modulate
	_sync_base_sprite()


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


func _play_audio_player(player: AudioStreamPlayer) -> void:
	if player == null:
		return

	player.stop()
	player.play()


func _schedule_return_to_rest_state() -> void:
	if _shot_return_tween != null:
		_shot_return_tween.kill()

	_shot_pose_active = true
	_shot_return_tween = create_tween()
	_shot_return_tween.tween_interval(SHOT_RETURN_DELAY)
	_shot_return_tween.tween_callback(Callable(self, "_return_to_rest_state"))


func _return_to_rest_state_if_not_shooting() -> void:
	if _shot_pose_active:
		return

	_return_to_rest_state()


func _return_to_rest_state() -> void:
	if _should_preserve_hawk_rotation():
		_shot_pose_active = false
		if _is_current_level_animation(SHOOT_ANIMATION):
			play_idle()
		return

	_shot_pose_active = false
	rotation = _rest_rotation
	if _is_current_level_animation(SHOOT_ANIMATION):
		play_idle()


func _get_signal_boost_range_multiplier() -> float:
	return get_signal_boost_range_multiplier()


func _get_signal_boost_cooldown_multiplier() -> float:
	return get_signal_boost_cooldown_multiplier()


func _get_game_root() -> Node:
	var current_scene := get_tree().current_scene
	return current_scene if current_scene != null else get_tree().root
