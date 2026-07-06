class_name SIEMHawkTower
extends CyberGuardianTower

signal dispatch_mode_changed(dispatched: bool)
signal knowledge_bank_changed(banked_points: int)
signal knowledge_extracted(amount: int)

const SIEM_MAX_LEVEL := 5
const SIEM_DAMAGE := 10
const SIEM_ATTACK_RANGE := 360.0
const SIEM_COOLDOWN := 3.0
const SIEM_LASER_WIDTH := 12.0
const SIEM_UPGRADE_COSTS := [0, 0, 0, 0, 0]
const RED_VIRUS_KNOWLEDGE_POINTS := 1
const TROJAN_HORSE_KNOWLEDGE_POINTS := 5
const KNOWLEDGE_EXTRACTION_SECONDS := 3.0
const ARC_SEGMENTS := 36
const LANDING_DISTANCE_EPSILON := 2.0

@export var base_sprite_path: NodePath = ^"BaseSprite"
@export var base_global_rotation := 0.0
@export var base_z_index := 59
@export_group("Dispatch")
@export_range(1.0, 400.0, 1.0) var dispatch_speed := 100.0
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
@export_group("")

var _base_sprite: Sprite2D
var _scan_arc_fill: Polygon2D
var _scan_arc_outline: Line2D
var _knowledge_label: Label
var _station_position := Vector2.ZERO
var _dispatched := false
var _landing_to_headquarters := false
var _banked_knowledge_points := 0
var _scanned_virus_ids := {}
var _extraction_elapsed := 0.0
var _scan_arc_phase := 0.0


func _ready() -> void:
	super._ready()
	_station_position = global_position
	_base_sprite = get_node_or_null(base_sprite_path) as Sprite2D
	if _base_sprite != null:
		_base_sprite.top_level = true
		_base_sprite.z_as_relative = false
		_base_sprite.z_index = base_z_index
	_scan_arc_fill = get_node_or_null(scan_arc_fill_path) as Polygon2D
	_scan_arc_outline = get_node_or_null(scan_arc_outline_path) as Line2D
	_knowledge_label = get_node_or_null(knowledge_label_path) as Label
	_configure_top_level_scanner_nodes()
	_sync_base_sprite()
	_update_scan_arc_visual(0.0)
	_sync_knowledge_label()


func _process(delta: float) -> void:
	super._process(delta)
	_sync_base_sprite()
	_update_scan_arc_visual(delta)
	_sync_knowledge_label()


func try_start_drag(pointer_position: Vector2) -> bool:
	var started := super.try_start_drag(pointer_position)
	_sync_base_sprite()
	return started


func update_drag(pointer_position: Vector2) -> void:
	super.update_drag(pointer_position)
	_sync_base_sprite()


func finish_drag() -> bool:
	var was_placed := super.finish_drag()
	if was_placed:
		_station_position = global_position
	_sync_base_sprite()
	return was_placed


func reset_tower() -> void:
	super.reset_tower()
	_station_position = global_position
	_dispatched = false
	_landing_to_headquarters = false
	_banked_knowledge_points = 0
	_scanned_virus_ids.clear()
	_extraction_elapsed = 0.0
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
	_extraction_elapsed = 0.0
	dispatch_mode_changed.emit(_dispatched)
	_sync_knowledge_label()


func toggle_dispatch() -> void:
	set_dispatched(not _dispatched)


func is_dispatched() -> bool:
	return _dispatched


func is_landing_to_headquarters() -> bool:
	return _landing_to_headquarters


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
	_extraction_elapsed = 0.0
	dispatch_mode_changed.emit(_dispatched)
	_sync_knowledge_label()


func get_banked_knowledge_points() -> int:
	return _banked_knowledge_points


func update_knowledge_scan(delta: float, mouse_global_position: Vector2, active_viruses: Array[PathFollow2D]) -> void:
	if not is_placed():
		return

	if _landing_to_headquarters:
		_update_landing_movement(delta)
		_extraction_elapsed = 0.0
	elif _dispatched:
		_update_dispatch_movement(delta, mouse_global_position)
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


func get_shot_power() -> int:
	if level <= 1:
		return 0

	return SIEM_DAMAGE


func get_attack_range() -> float:
	if level <= 1:
		return 0.0

	return SIEM_ATTACK_RANGE


func get_shot_cooldown() -> float:
	return SIEM_COOLDOWN


func get_laser_width() -> float:
	return SIEM_LASER_WIDTH


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
	play_idle()
	return true


func can_scan_cloaked_viruses() -> bool:
	return true


func play_animation(animation_name: StringName) -> void:
	var level_animation_name := _get_level_animation_name(animation_name)
	if sprite_frames == null or not sprite_frames.has_animation(level_animation_name):
		super.play_animation(animation_name)
		return

	animation = level_animation_name
	frame = 0
	frame_progress = 0.0
	play()


func update_attack(delta: float, active_viruses: Array[PathFollow2D]) -> PathFollow2D:
	if level <= 1 or not _dispatched or _landing_to_headquarters:
		if not _should_preserve_hawk_rotation():
			_return_to_rest_state_if_not_shooting()
		return null

	return super.update_attack(delta, active_viruses)


func _return_to_rest_state() -> void:
	if _should_preserve_hawk_rotation():
		_shot_pose_active = false
		if animation == SHOOT_ANIMATION:
			play_idle()
		return

	super._return_to_rest_state()


func _should_preserve_hawk_rotation() -> bool:
	return is_placed() and (_dispatched or _landing_to_headquarters or not _is_at_headquarters())


func _update_dispatch_movement(delta: float, mouse_global_position: Vector2) -> void:
	var direction := mouse_global_position - global_position
	if direction.length_squared() > 0.0001:
		global_rotation = direction.angle() - forward_rotation_offset
	global_position = global_position.move_toward(mouse_global_position, maxf(0.0, dispatch_speed) * delta)


func _update_landing_movement(delta: float) -> void:
	var direction := _station_position - global_position
	if direction.length_squared() <= LANDING_DISTANCE_EPSILON * LANDING_DISTANCE_EPSILON:
		_complete_landing_to_headquarters()
		return

	global_rotation = direction.angle() - forward_rotation_offset
	global_position = global_position.move_toward(_station_position, maxf(0.0, dispatch_speed) * delta)
	if global_position.distance_squared_to(_station_position) <= LANDING_DISTANCE_EPSILON * LANDING_DISTANCE_EPSILON:
		_complete_landing_to_headquarters()


func _complete_landing_to_headquarters() -> void:
	global_position = _station_position
	_landing_to_headquarters = false
	_dispatched = false
	_extraction_elapsed = 0.0
	dispatch_mode_changed.emit(_dispatched)
	_sync_knowledge_label()


func _is_at_headquarters() -> bool:
	return global_position.distance_squared_to(_station_position) <= LANDING_DISTANCE_EPSILON * LANDING_DISTANCE_EPSILON


func _get_level_animation_name(animation_name: StringName) -> StringName:
	if level <= 1:
		return animation_name

	return StringName("%s_lv%d" % [String(animation_name), level])


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
	while _banked_knowledge_points > 0 and _extraction_elapsed >= KNOWLEDGE_EXTRACTION_SECONDS:
		_extraction_elapsed -= KNOWLEDGE_EXTRACTION_SECONDS
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
