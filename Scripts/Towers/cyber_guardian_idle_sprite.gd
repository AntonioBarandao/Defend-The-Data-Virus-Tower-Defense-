class_name CyberGuardianTower
extends Node2D

signal placed(tower: CyberGuardianTower)
signal mode_changed(mode_id: StringName)
signal firewall_damage_requested(follow: PathFollow2D, amount: int)

const TowerSummonEffectScript := preload("res://Scripts/Effects/tower_summon_effect.gd")
const SIGNAL_BOOST_TEXTURE := preload("res://assets/Towers/CyberGuardian/Modes/Cyber_Guardian_SignalBoost_Sprite.png")
const FIREWALL_TEXTURE := preload("res://assets/Towers/CyberGuardian/Modes/Cyber_Guardian_Firewall_Sprite.png")
const IDLE_ANIMATION := &"idle"
const SUMMON_ANIMATION := &"SummonAnim"
const SHOOT_ANIMATION := &"ShootAnim"
const TRACK_ANIMATIONS := [
	IDLE_ANIMATION,
	SUMMON_ANIMATION,
	SHOOT_ANIMATION
]
const MODE_DEFENDER := &"defender"
const MODE_SIGNAL_BOOST := &"signal_boost"
const MODE_FIREWALL := &"firewall"
const MODE_SEQUENCE := [
	MODE_DEFENDER,
	MODE_SIGNAL_BOOST,
	MODE_FIREWALL
]
const MODE_DISPLAY_NAMES := {
	MODE_DEFENDER: "Defender Mode",
	MODE_SIGNAL_BOOST: "Signal Boost Mode",
	MODE_FIREWALL: "Firewall Mode"
}
const SIGNAL_BOOST_UNLOCK_KNOWLEDGE_LEVEL := 1
const FIREWALL_UNLOCK_KNOWLEDGE_LEVEL := 1
const MODE_UNLOCK_LEVELS := {
	MODE_DEFENDER: 1,
	MODE_SIGNAL_BOOST: SIGNAL_BOOST_UNLOCK_KNOWLEDGE_LEVEL,
	MODE_FIREWALL: FIREWALL_UNLOCK_KNOWLEDGE_LEVEL
}
const SIGNAL_BOOST_RANGE_MULTIPLIER := 1.1
const SIGNAL_BOOST_COOLDOWN_MULTIPLIER := 0.9
const SIGNAL_BOOST_HAWK_SPEED_MULTIPLIER := 1.2
const GROUP_OFFENSE_TOWER := "OFFENSE_TOWER"
const GROUP_SUPPORT_TOWER := "SUPPORT_TOWER"
const FIREWALL_FIELD_NAME := "GuardianFirewallField"
const FIREWALL_SAMPLE_DISTANCE := 16.0
const GRAB_SIZE := Vector2(240, 180)
const PLACEMENT_HIGHLIGHT_SIZE := Vector2(180, 120)
const PLACEMENT_SLOT_PREFIX := "placementslot"
const PLATFORM_VALID_COLOR := Color(0.1, 0.9, 0.25, 0.45)
const PLATFORM_INVALID_COLOR := Color(1.0, 0.1, 0.08, 0.45)
const MAX_LEVEL := 1
const LEVEL_DAMAGE_POINTS := [1, 2, 3, 4, 5]
const LEVEL_ATTACK_RANGES := [250.0, 310.0, 390.0, 500.0, 640.0]
const LEVEL_COOLDOWNS := [0.5, 0.42, 0.34, 0.28, 0.22]
const LEVEL_LASER_WIDTHS := [10.0, 11.0, 12.0, 13.0, 14.0]
const LEVEL_UPGRADE_COSTS := [60, 90, 130, 180, 0]
const SHOT_RETURN_DELAY := 3.0
const RANGE_PREVIEW_SEGMENTS := 96
const RANGE_PREVIEW_FILL_COLOR := Color(0.27, 0.55, 1.0, 0.16)
const RANGE_PREVIEW_OUTLINE_COLOR := Color(0.48, 0.83, 1.0, 0.78)
const TOWER_VISUAL_Z_INDEX := 60
const SUMMON_EFFECT_Z_OFFSET := -1
const DRAG_VALID_MODULATE := Color(0.42, 1.0, 0.46, 0.84)
const DRAG_INVALID_MODULATE := Color(1.0, 0.22, 0.2, 0.84)

@export var platform_highlight_path: NodePath = ^"../../PlatformHighlight"
@export var forward_rotation_offset := PI * 0.5
@export_range(1, MAX_LEVEL, 1) var level := 1
@export var has_scanner_ability := false
@export var show_attack_range_preview := true
@export var range_preview_fill_color := RANGE_PREVIEW_FILL_COLOR
@export var range_preview_outline_color := RANGE_PREVIEW_OUTLINE_COLOR
@export_group("Track Visuals")
@export var defender_idle_visual_path: NodePath = ^"Visuals/DefenderIdle"
@export var defender_summon_visual_path: NodePath = ^"Visuals/DefenderSummon"
@export var defender_shoot_visual_path: NodePath = ^"Visuals/DefenderShoot"
@export var signal_boost_idle_visual_path: NodePath = ^"Visuals/SignalBoostIdle"
@export var signal_boost_summon_visual_path: NodePath = ^"Visuals/SignalBoostSummon"
@export var signal_boost_shoot_visual_path: NodePath = ^"Visuals/SignalBoostShoot"
@export var firewall_idle_visual_path: NodePath = ^"Visuals/FirewallIdle"
@export var firewall_summon_visual_path: NodePath = ^"Visuals/FirewallSummon"
@export var firewall_shoot_visual_path: NodePath = ^"Visuals/FirewallShoot"
@export_group("Mode Sprites")
@export var signal_boost_sprite_path: NodePath = ^"ModeSprites/SignalBoostSprite"
@export var firewall_sprite_path: NodePath = ^"ModeSprites/FirewallSprite"
@export_group("Firewall")
@export var virus_path_path: NodePath = ^"../../VirusElements/Path2D"
@export var firewall_size := Vector2(240.0, 54.0)
@export var firewall_color := Color(1.0, 0.08, 0.04, 0.42)
@export var firewall_outline_color := Color(1.0, 0.38, 0.26, 0.86)
@export var firewall_z_index := 58
@export_group("Audio")
@export var summon_sfx_path: NodePath = ^"Audio/SummonSfx"
@export_group("")

var _asset_cache: Node
var _home_position := Vector2.ZERO
var _dragging := false
var _placed := false
var _drag_start_position := Vector2.ZERO
var _drag_offset := Vector2.ZERO
var _drag_is_valid := false
var _current_placement_shape: CollisionShape2D
var _platform_highlight: ColorRect
var _shot_cooldown_remaining := 0.0
var _rest_rotation := 0.0
var _shot_pose_active := false
var _shot_return_tween: Tween
var _range_preview_fill: Polygon2D
var _range_preview_outline: Line2D
var _range_preview_radius := -1.0
var _menu_range_preview_active := false
var _summon_sfx: AudioStreamPlayer
var _base_modulate := Color.WHITE
var _base_self_modulate := Color.WHITE
var _current_mode: StringName = MODE_DEFENDER
var _signal_boost_sprite: Sprite2D
var _firewall_sprite: Sprite2D
var _defender_sprite_frames: SpriteFrames
var _static_mode_sprite_frames := {}
var _signal_boost_active := false
var _signal_boost_range_multiplier := SIGNAL_BOOST_RANGE_MULTIPLIER
var _signal_boost_cooldown_multiplier := SIGNAL_BOOST_COOLDOWN_MULTIPLIER
var _signal_boost_hawk_speed_multiplier := SIGNAL_BOOST_HAWK_SPEED_MULTIPLIER
var _virus_path: Path2D
var _firewall_area: Area2D
var _firewall_collision_shape: CollisionShape2D
var _firewall_visual: Polygon2D
var _firewall_outline: Line2D
var _firewall_contact_ids := {}
var _firewall_burn_states := {}
var _firewall_hit_damage := 1
var _firewall_burn_damage := 1
var _firewall_burn_tick_seconds := 1.0
var _firewall_burn_duration := 5.0
var _root_visual: AnimatedSprite2D
var _active_visual: AnimatedSprite2D
var _current_animation: StringName = IDLE_ANIMATION
var _visuals_by_mode_animation := {}


func _ready() -> void:
	add_to_group("Defender")
	add_to_group("OFFENSE_TOWER")
	_home_position = global_position
	_drag_start_position = _home_position
	_rest_rotation = rotation
	_base_modulate = modulate
	_base_self_modulate = self_modulate
	z_index = maxi(z_index, TOWER_VISUAL_Z_INDEX)
	z_as_relative = false
	_resolve_virus_path()
	_configure_animation_visuals()
	_platform_highlight = get_node_or_null(platform_highlight_path) as ColorRect
	_signal_boost_sprite = get_node_or_null(signal_boost_sprite_path) as Sprite2D
	_firewall_sprite = get_node_or_null(firewall_sprite_path) as Sprite2D
	_summon_sfx = get_node_or_null(summon_sfx_path) as AudioStreamPlayer
	_hide_mode_sprite_source_nodes()
	if _platform_highlight != null:
		_platform_highlight.hide()
	_sync_mode_groups()
	_sync_firewall_field()

	var available_frames := _get_defender_sprite_frames()
	if _has_required_animations(available_frames):
		_capture_defender_sprite_frames(available_frames)
		_prepare_static_mode_sprite_frames()
		_assign_sprite_frames_to_mode(MODE_DEFENDER, available_frames, true)
		play_animation(IDLE_ANIMATION)
		return

	_asset_cache = get_node_or_null("/root/AssetCache")
	if _asset_cache == null:
		push_error("AssetCache autoload was not found.")
		return

	if _asset_cache.has_cyber_guardian_animations():
		_apply_sprite_frames(_asset_cache.cyber_guardian_sprite_frames)
		return

	_asset_cache.cyber_guardian_animations_ready.connect(_apply_sprite_frames, CONNECT_ONE_SHOT)
	_asset_cache.load_startup_resources()


func _process(_delta: float) -> void:
	_update_attack_range_preview()


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
	get_viewport().set_input_as_handled()


func finish_drag() -> bool:
	if not _dragging:
		return false

	var was_placed := false
	if _drag_is_valid:
		global_position = _get_placement_area_center()
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
	get_viewport().set_input_as_handled()
	return was_placed


func reset_tower() -> void:
	level = 1
	set_guardian_mode(MODE_DEFENDER)
	set_signal_boost_active(false)
	global_position = _home_position
	rotation = _rest_rotation
	_dragging = false
	_placed = false
	_drag_is_valid = false
	_drag_offset = Vector2.ZERO
	_drag_start_position = _home_position
	_current_placement_shape = null
	_clear_firewall_effects()
	_sync_firewall_field()
	_clear_drag_feedback()
	_shot_cooldown_remaining = 0.0
	_shot_pose_active = false
	if _shot_return_tween != null:
		_shot_return_tween.kill()
		_shot_return_tween = null
	if _platform_highlight != null:
		_platform_highlight.hide()
	_set_range_preview_visible(false)
	play_animation(IDLE_ANIMATION)


func get_tower_scale() -> float:
	return scale.x


func get_laser_width() -> float:
	return LEVEL_LASER_WIDTHS[level - 1]


func get_attack_range() -> float:
	return LEVEL_ATTACK_RANGES[level - 1] * _get_signal_boost_range_multiplier()


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
	return LEVEL_COOLDOWNS[level - 1] * _get_signal_boost_cooldown_multiplier()


func get_shot_power() -> int:
	return LEVEL_DAMAGE_POINTS[level - 1]


func get_level() -> int:
	return level


func get_max_level() -> int:
	return MAX_LEVEL


func can_upgrade() -> bool:
	return false


func can_scan_cloaked_viruses() -> bool:
	return has_scanner_ability


func get_upgrade_cost() -> int:
	if not can_upgrade():
		return 0

	return int(LEVEL_UPGRADE_COSTS[level])


func upgrade() -> bool:
	return false


func set_guardian_mode(mode_id: StringName) -> bool:
	var normalized_mode := _normalize_mode(mode_id)
	if normalized_mode == _current_mode:
		return true

	_current_mode = normalized_mode
	_apply_guardian_mode_visual()
	_sync_mode_groups()
	_sync_firewall_field()
	mode_changed.emit(_current_mode)
	return true


func get_current_mode_id() -> StringName:
	return _current_mode


func get_mode_display_name(mode_id: StringName = &"") -> String:
	var normalized_mode := _current_mode if String(mode_id).is_empty() else _normalize_mode(mode_id)
	return String(MODE_DISPLAY_NAMES.get(normalized_mode, "Defender Mode"))


func get_mode_unlock_level(mode_id: StringName) -> int:
	return int(MODE_UNLOCK_LEVELS.get(_normalize_mode(mode_id), 1))


func get_mode_unlock_levels() -> Dictionary:
	return MODE_UNLOCK_LEVELS.duplicate()


func is_mode_unlocked(mode_id: StringName, knowledge_level: int) -> bool:
	return knowledge_level >= get_mode_unlock_level(mode_id)


func get_unlocked_mode_ids(knowledge_level: int) -> Array[StringName]:
	var unlocked_modes: Array[StringName] = []
	for mode_id in MODE_SEQUENCE:
		if is_mode_unlocked(mode_id, knowledge_level):
			unlocked_modes.append(mode_id)

	return unlocked_modes


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


func set_firewall_profile(hit_damage: int, burn_damage: int, burn_tick_seconds: float, burn_duration: float) -> void:
	_firewall_hit_damage = maxi(0, hit_damage)
	_firewall_burn_damage = maxi(0, burn_damage)
	_firewall_burn_tick_seconds = maxf(0.05, burn_tick_seconds)
	_firewall_burn_duration = maxf(0.0, burn_duration)


func update_attack(delta: float, active_viruses: Array[PathFollow2D]) -> PathFollow2D:
	if not _placed:
		_return_to_rest_state_if_not_shooting()
		return null
	if _current_mode != MODE_DEFENDER:
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


func update_firewall(delta: float, active_viruses: Array[PathFollow2D]) -> void:
	_update_firewall_burns(delta)
	if not _placed or _current_mode != MODE_FIREWALL:
		_sync_firewall_field()
		return

	_sync_firewall_field()
	if _firewall_area == null:
		return

	for follow in active_viruses:
		if not _is_firewall_follow_damageable(follow):
			continue

		var follow_id := follow.get_instance_id()
		var inside_firewall := _firewall_contains_follow(follow)
		if not inside_firewall:
			_firewall_contact_ids.erase(follow_id)
			continue
		if _firewall_contact_ids.has(follow_id):
			continue

		_firewall_contact_ids[follow_id] = true
		_apply_firewall_burn(follow)
		if _firewall_hit_damage > 0:
			firewall_damage_requested.emit(follow, _firewall_hit_damage)


func _configure_animation_visuals() -> void:
	var root_node: Node = self
	_root_visual = root_node as AnimatedSprite2D
	_visuals_by_mode_animation.clear()
	_register_track_visual(MODE_DEFENDER, IDLE_ANIMATION, defender_idle_visual_path)
	_register_track_visual(MODE_DEFENDER, SUMMON_ANIMATION, defender_summon_visual_path)
	_register_track_visual(MODE_DEFENDER, SHOOT_ANIMATION, defender_shoot_visual_path)
	_register_track_visual(MODE_SIGNAL_BOOST, IDLE_ANIMATION, signal_boost_idle_visual_path)
	_register_track_visual(MODE_SIGNAL_BOOST, SUMMON_ANIMATION, signal_boost_summon_visual_path)
	_register_track_visual(MODE_SIGNAL_BOOST, SHOOT_ANIMATION, signal_boost_shoot_visual_path)
	_register_track_visual(MODE_FIREWALL, IDLE_ANIMATION, firewall_idle_visual_path)
	_register_track_visual(MODE_FIREWALL, SUMMON_ANIMATION, firewall_summon_visual_path)
	_register_track_visual(MODE_FIREWALL, SHOOT_ANIMATION, firewall_shoot_visual_path)

	if _visuals_by_mode_animation.is_empty() and _root_visual != null:
		for animation_name in TRACK_ANIMATIONS:
			_visuals_by_mode_animation[_visual_key(MODE_DEFENDER, animation_name)] = _root_visual

	for visual in _get_unique_animation_visuals():
		if visual == null:
			continue
		var callback := Callable(self, "_on_track_visual_animation_finished").bind(visual)
		if not visual.animation_finished.is_connected(callback):
			visual.animation_finished.connect(callback)
		if visual != _root_visual:
			visual.hide()

	_active_visual = _get_visual_for_animation(IDLE_ANIMATION)
	_show_only_visual(_active_visual)


func _register_track_visual(mode_id: StringName, animation_name: StringName, visual_path: NodePath) -> void:
	var visual := get_node_or_null(visual_path) as AnimatedSprite2D
	if visual == null:
		return

	_visuals_by_mode_animation[_visual_key(mode_id, animation_name)] = visual


func _visual_key(mode_id: StringName, animation_name: StringName) -> String:
	return "%s/%s" % [String(mode_id), String(animation_name)]


func _get_visual_for_animation(animation_name: StringName) -> AnimatedSprite2D:
	var visual := _visuals_by_mode_animation.get(_visual_key(_current_mode, animation_name)) as AnimatedSprite2D
	if visual != null:
		return visual

	visual = _visuals_by_mode_animation.get(_visual_key(MODE_DEFENDER, animation_name)) as AnimatedSprite2D
	if visual != null:
		return visual

	return _root_visual


func _get_unique_animation_visuals() -> Array[AnimatedSprite2D]:
	var visuals: Array[AnimatedSprite2D] = []
	for visual_value in _visuals_by_mode_animation.values():
		var visual := visual_value as AnimatedSprite2D
		if visual != null and not visuals.has(visual):
			visuals.append(visual)

	if _root_visual != null and not visuals.has(_root_visual):
		visuals.append(_root_visual)

	return visuals


func _show_only_visual(visual_to_show: AnimatedSprite2D) -> void:
	for visual in _get_unique_animation_visuals():
		if visual == null:
			continue
		visual.visible = visual == visual_to_show


func _on_track_visual_animation_finished(visual: AnimatedSprite2D) -> void:
	if visual == _active_visual:
		_return_to_idle()


func contains_global_point(pointer_position: Vector2) -> bool:
	return get_tower_rect().has_point(pointer_position)


func get_tower_rect() -> Rect2:
	var size := PLACEMENT_HIGHLIGHT_SIZE
	var visual := _active_visual if _active_visual != null else _get_visual_for_animation(IDLE_ANIMATION)
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


func aim_at(target_position: Vector2) -> void:
	var direction := target_position - global_position
	if direction.length_squared() > 0.0:
		rotation = direction.angle() - forward_rotation_offset


func play_animation(animation_name: StringName) -> void:
	var visual := _get_visual_for_animation(animation_name)
	if visual == null or visual.sprite_frames == null or not visual.sprite_frames.has_animation(animation_name):
		return

	_active_visual = visual
	_current_animation = animation_name
	_show_only_visual(visual)
	visual.animation = animation_name
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


func _get_follow_virus(follow: PathFollow2D) -> RedVirus:
	for child in follow.get_children():
		var virus := child as RedVirus
		if virus != null:
			return virus

	return null


func _get_follow_target_position(follow: PathFollow2D) -> Vector2:
	var virus := _get_follow_virus(follow)
	if virus != null:
		return virus.global_position

	return follow.global_position


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
	_set_range_preview_visible(true)


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


func _set_range_preview_visible(visible: bool) -> void:
	if is_instance_valid(_range_preview_fill):
		_range_preview_fill.visible = visible
	if is_instance_valid(_range_preview_outline):
		_range_preview_outline.visible = visible


func _play_audio_player(player: AudioStreamPlayer) -> void:
	if player == null:
		return

	player.stop()
	player.play()


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


func _find_first_placement_slot(node: Node) -> CollisionShape2D:
	if node != self:
		var collision_shape := node as CollisionShape2D
		if _is_placement_slot_shape(collision_shape):
			return collision_shape

	for child in node.get_children():
		var found_shape := _find_first_placement_slot(child)
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


func _get_platform_highlight_rect(placement_shape: CollisionShape2D) -> Rect2:
	if placement_shape != null:
		return _get_placement_shape_global_rect(placement_shape)

	var fallback_size := _get_default_placement_highlight_size()
	return Rect2(global_position - fallback_size * 0.5, fallback_size)


func _get_default_placement_highlight_size() -> Vector2:
	var game_root := _get_game_root()
	if game_root == null:
		return PLACEMENT_HIGHLIGHT_SIZE

	var first_slot := _find_first_placement_slot(game_root)
	if first_slot != null:
		return _get_placement_shape_global_rect(first_slot).size

	return PLACEMENT_HIGHLIGHT_SIZE


func _get_placement_shape_global_rect(placement_shape: CollisionShape2D) -> Rect2:
	var rectangle_shape := placement_shape.shape as RectangleShape2D
	if rectangle_shape == null:
		return Rect2(placement_shape.global_position - PLACEMENT_HIGHLIGHT_SIZE * 0.5, PLACEMENT_HIGHLIGHT_SIZE)

	var half_size := rectangle_shape.size * 0.5
	var corners := [
		placement_shape.global_transform * Vector2(-half_size.x, -half_size.y),
		placement_shape.global_transform * Vector2(half_size.x, -half_size.y),
		placement_shape.global_transform * Vector2(half_size.x, half_size.y),
		placement_shape.global_transform * Vector2(-half_size.x, half_size.y),
	]
	var rect := Rect2(corners[0], Vector2.ZERO)
	for corner in corners:
		rect = rect.expand(corner)

	return rect


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


func _clear_drag_feedback() -> void:
	modulate = _base_modulate


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


func _sync_mode_groups() -> void:
	if _current_mode == MODE_SIGNAL_BOOST:
		remove_from_group(GROUP_OFFENSE_TOWER)
		add_to_group(GROUP_SUPPORT_TOWER)
	else:
		add_to_group(GROUP_OFFENSE_TOWER)
		remove_from_group(GROUP_SUPPORT_TOWER)


func _sync_firewall_field() -> void:
	var active := _placed and _current_mode == MODE_FIREWALL
	if not active:
		_set_firewall_field_visible(false)
		_firewall_contact_ids.clear()
		return

	_ensure_firewall_field()
	if _firewall_area == null:
		return

	var placement := _get_firewall_path_placement()
	if not bool(placement["valid"]):
		_set_firewall_field_visible(false)
		return

	_firewall_area.global_position = placement["position"]
	_firewall_area.global_rotation = float(placement["rotation"])
	_set_firewall_field_visible(true)


func _ensure_firewall_field() -> void:
	if is_instance_valid(_firewall_area) \
			and is_instance_valid(_firewall_collision_shape) \
			and is_instance_valid(_firewall_visual) \
			and is_instance_valid(_firewall_outline):
		return

	var game_root := _get_game_root()
	if game_root == null:
		return

	_firewall_area = Area2D.new()
	_firewall_area.name = FIREWALL_FIELD_NAME
	_firewall_area.collision_layer = 0
	_firewall_area.collision_mask = 0
	_firewall_area.monitoring = false
	_firewall_area.monitorable = false
	_firewall_area.z_index = firewall_z_index
	_firewall_area.z_as_relative = false
	game_root.add_child(_firewall_area)

	_firewall_visual = Polygon2D.new()
	_firewall_visual.name = "FirewallVisual"
	_firewall_visual.color = firewall_color
	_firewall_visual.z_index = firewall_z_index
	_firewall_visual.z_as_relative = false
	_firewall_area.add_child(_firewall_visual)

	_firewall_outline = Line2D.new()
	_firewall_outline.name = "FirewallOutline"
	_firewall_outline.width = 4.0
	_firewall_outline.default_color = firewall_outline_color
	_firewall_outline.joint_mode = Line2D.LINE_JOINT_ROUND
	_firewall_outline.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_firewall_outline.end_cap_mode = Line2D.LINE_CAP_ROUND
	_firewall_outline.z_index = firewall_z_index + 1
	_firewall_outline.z_as_relative = false
	_firewall_area.add_child(_firewall_outline)

	_firewall_collision_shape = CollisionShape2D.new()
	_firewall_collision_shape.name = "FirewallCollisionShape"
	_firewall_collision_shape.debug_color = firewall_outline_color
	var shape := RectangleShape2D.new()
	shape.size = firewall_size
	_firewall_collision_shape.shape = shape
	_firewall_area.add_child(_firewall_collision_shape)

	_rebuild_firewall_geometry()
	_set_firewall_field_visible(false)


func _rebuild_firewall_geometry() -> void:
	if _firewall_visual != null:
		var half_size := firewall_size * 0.5
		_firewall_visual.polygon = PackedVector2Array([
			Vector2(-half_size.x, -half_size.y),
			Vector2(half_size.x, -half_size.y),
			Vector2(half_size.x, half_size.y),
			Vector2(-half_size.x, half_size.y)
		])

	if _firewall_outline != null:
		var half_size := firewall_size * 0.5
		_firewall_outline.points = PackedVector2Array([
			Vector2(-half_size.x, -half_size.y),
			Vector2(half_size.x, -half_size.y),
			Vector2(half_size.x, half_size.y),
			Vector2(-half_size.x, half_size.y),
			Vector2(-half_size.x, -half_size.y)
		])

	if _firewall_collision_shape != null:
		var shape := _firewall_collision_shape.shape as RectangleShape2D
		if shape != null:
			shape.size = firewall_size
		_firewall_collision_shape.debug_color = firewall_outline_color


func _set_firewall_field_visible(value: bool) -> void:
	if _firewall_area != null:
		_firewall_area.visible = value
	if _firewall_collision_shape != null:
		_firewall_collision_shape.disabled = not value


func _clear_firewall_effects() -> void:
	_firewall_contact_ids.clear()
	_firewall_burn_states.clear()
	_set_firewall_field_visible(false)


func _resolve_virus_path() -> void:
	_virus_path = get_node_or_null(virus_path_path) as Path2D
	if _virus_path != null:
		return

	var game_root := _get_game_root()
	if game_root != null:
		_virus_path = game_root.get_node_or_null(^"VirusElements/Path2D") as Path2D


func _get_firewall_path_placement() -> Dictionary:
	var empty_result := {
		"valid": false,
		"position": global_position,
		"rotation": rotation
	}
	if _virus_path == null or _virus_path.curve == null:
		_resolve_virus_path()
	if _virus_path == null or _virus_path.curve == null:
		return empty_result

	var path_length := _virus_path.curve.get_baked_length()
	if path_length <= 0.0:
		return empty_result

	var local_position := _virus_path.to_local(global_position)
	var offset := _virus_path.curve.get_closest_offset(local_position)
	var path_position := _virus_path.to_global(_virus_path.curve.sample_baked(offset))
	var previous_offset := maxf(0.0, offset - FIREWALL_SAMPLE_DISTANCE)
	var next_offset := minf(path_length, offset + FIREWALL_SAMPLE_DISTANCE)
	var previous_position := _virus_path.to_global(_virus_path.curve.sample_baked(previous_offset))
	var next_position := _virus_path.to_global(_virus_path.curve.sample_baked(next_offset))
	var tangent := next_position - previous_position
	if tangent.length_squared() <= 0.001:
		tangent = Vector2.RIGHT

	return {
		"valid": true,
		"position": path_position,
		"rotation": tangent.angle() + PI * 0.5
	}


func _firewall_contains_follow(follow: PathFollow2D) -> bool:
	if _firewall_area == null or not _firewall_area.visible:
		return false

	var target_position := _get_follow_target_position(follow)
	var local_position := _firewall_area.global_transform.affine_inverse() * target_position
	return Rect2(-firewall_size * 0.5, firewall_size).has_point(local_position)


func _apply_firewall_burn(follow: PathFollow2D) -> void:
	if follow == null or _firewall_burn_duration <= 0.0 or _firewall_burn_damage <= 0:
		return

	_firewall_burn_states[follow.get_instance_id()] = {
		"follow": follow,
		"remaining": _firewall_burn_duration,
		"tick_elapsed": 0.0
	}


func _update_firewall_burns(delta: float) -> void:
	for follow_id in _firewall_burn_states.keys().duplicate():
		var state := _firewall_burn_states[follow_id] as Dictionary
		var follow := state.get("follow") as PathFollow2D
		if not _is_firewall_follow_damageable(follow):
			_firewall_burn_states.erase(follow_id)
			_firewall_contact_ids.erase(follow_id)
			continue

		var remaining := maxf(0.0, float(state.get("remaining", 0.0)) - delta)
		var tick_elapsed := float(state.get("tick_elapsed", 0.0)) + delta
		while tick_elapsed >= _firewall_burn_tick_seconds and _firewall_burn_damage > 0:
			tick_elapsed -= _firewall_burn_tick_seconds
			firewall_damage_requested.emit(follow, _firewall_burn_damage)
			if not _is_firewall_follow_damageable(follow):
				break

		if remaining <= 0.0 or not _is_firewall_follow_damageable(follow):
			_firewall_burn_states.erase(follow_id)
			continue

		state["remaining"] = remaining
		state["tick_elapsed"] = tick_elapsed
		_firewall_burn_states[follow_id] = state


func _is_firewall_follow_damageable(follow: PathFollow2D) -> bool:
	if not is_instance_valid(follow):
		return false

	var virus := _get_follow_virus(follow)
	return virus == null or not virus.is_destroying()


func _get_game_root() -> Node:
	var current_scene := get_tree().current_scene
	return current_scene if current_scene != null else get_tree().root


func _apply_sprite_frames(frames: SpriteFrames) -> void:
	_capture_defender_sprite_frames(frames)
	_prepare_static_mode_sprite_frames()
	_assign_sprite_frames_to_mode(MODE_DEFENDER, frames, true)
	play_animation(IDLE_ANIMATION)


func _has_required_animations(frames: SpriteFrames) -> bool:
	return frames != null \
		and frames.has_animation(IDLE_ANIMATION) \
		and frames.has_animation(SUMMON_ANIMATION) \
		and frames.has_animation(SHOOT_ANIMATION)


func _capture_defender_sprite_frames(frames: SpriteFrames) -> void:
	if frames != null:
		_defender_sprite_frames = frames


func _get_defender_sprite_frames() -> SpriteFrames:
	if _defender_sprite_frames != null:
		return _defender_sprite_frames

	var defender_idle := _visuals_by_mode_animation.get(_visual_key(MODE_DEFENDER, IDLE_ANIMATION)) as AnimatedSprite2D
	if defender_idle != null and defender_idle.sprite_frames != null:
		return defender_idle.sprite_frames
	if _root_visual != null:
		return _root_visual.sprite_frames

	return null


func _assign_sprite_frames_to_mode(mode_id: StringName, frames: SpriteFrames, overwrite := false) -> void:
	if frames == null:
		return

	for animation_name in TRACK_ANIMATIONS:
		var visual := _visuals_by_mode_animation.get(_visual_key(mode_id, animation_name)) as AnimatedSprite2D
		if visual == null:
			continue
		if overwrite or visual.sprite_frames == null:
			visual.sprite_frames = frames


func _prepare_static_mode_sprite_frames() -> void:
	if _static_mode_sprite_frames.is_empty():
		_static_mode_sprite_frames[MODE_SIGNAL_BOOST] = _build_static_mode_sprite_frames(_get_signal_boost_texture())
		_static_mode_sprite_frames[MODE_FIREWALL] = _build_static_mode_sprite_frames(_get_firewall_texture())
	_assign_sprite_frames_to_mode(MODE_SIGNAL_BOOST, _static_mode_sprite_frames.get(MODE_SIGNAL_BOOST) as SpriteFrames)
	_assign_sprite_frames_to_mode(MODE_FIREWALL, _static_mode_sprite_frames.get(MODE_FIREWALL) as SpriteFrames)


func _build_static_mode_sprite_frames(texture: Texture2D) -> SpriteFrames:
	var frames := SpriteFrames.new()
	for animation_name in [IDLE_ANIMATION, SUMMON_ANIMATION, SHOOT_ANIMATION]:
		if not frames.has_animation(animation_name):
			frames.add_animation(animation_name)
		frames.set_animation_loop(animation_name, animation_name == IDLE_ANIMATION)
		frames.set_animation_speed(animation_name, 1.0)
		frames.add_frame(animation_name, texture)

	if frames.has_animation(&"default"):
		frames.remove_animation(&"default")

	return frames


func _get_signal_boost_texture() -> Texture2D:
	if _signal_boost_sprite != null and _signal_boost_sprite.texture != null:
		return _signal_boost_sprite.texture

	return SIGNAL_BOOST_TEXTURE


func _get_firewall_texture() -> Texture2D:
	if _firewall_sprite != null and _firewall_sprite.texture != null:
		return _firewall_sprite.texture

	return FIREWALL_TEXTURE


func _hide_mode_sprite_source_nodes() -> void:
	if _signal_boost_sprite != null:
		_signal_boost_sprite.hide()
	if _firewall_sprite != null:
		_firewall_sprite.hide()


func _apply_guardian_mode_visual() -> void:
	_hide_mode_sprite_source_nodes()
	if _current_mode == MODE_DEFENDER:
		self_modulate = _base_self_modulate
		if _defender_sprite_frames != null:
			_assign_sprite_frames_to_mode(MODE_DEFENDER, _defender_sprite_frames, true)
	else:
		var mode_frames := _static_mode_sprite_frames.get(_current_mode) as SpriteFrames
		if mode_frames != null:
			_assign_sprite_frames_to_mode(_current_mode, mode_frames)

	var visual := _get_visual_for_animation(IDLE_ANIMATION)
	if visual != null and _has_required_animations(visual.sprite_frames):
		play_animation(IDLE_ANIMATION)


func _normalize_mode(mode_id: StringName) -> StringName:
	if MODE_SEQUENCE.has(mode_id):
		return mode_id

	return MODE_DEFENDER


func _get_signal_boost_range_multiplier() -> float:
	return get_signal_boost_range_multiplier()


func _get_signal_boost_cooldown_multiplier() -> float:
	return get_signal_boost_cooldown_multiplier()


func _return_to_idle() -> void:
	if _current_animation != IDLE_ANIMATION:
		play_animation(IDLE_ANIMATION)


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
	_shot_pose_active = false
	rotation = _rest_rotation
	if _current_animation == SHOOT_ANIMATION:
		play_idle()
