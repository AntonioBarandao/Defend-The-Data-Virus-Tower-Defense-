class_name CyberGuardianTower
extends AnimatedSprite2D

signal placed(tower: CyberGuardianTower)
signal mode_changed(mode_id: StringName)

const TowerSummonEffectScript := preload("res://Scripts/Effects/tower_summon_effect.gd")
const SIGNAL_BOOST_TEXTURE := preload("res://assets/Towers/CyberGuardian/Modes/Cyber_Guardian_SignalBoost_Sprite.png")
const FIREWALL_TEXTURE := preload("res://assets/Towers/CyberGuardian/Modes/Cyber_Guardian_Firewall_Sprite.png")
const IDLE_ANIMATION := &"idle"
const SUMMON_ANIMATION := &"SummonAnim"
const SHOOT_ANIMATION := &"ShootAnim"
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
const LEVEL_UPGRADE_COSTS := [0, 0, 0, 0, 0]
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
@export_group("Mode Sprites")
@export var signal_boost_sprite_path: NodePath = ^"ModeSprites/SignalBoostSprite"
@export var firewall_sprite_path: NodePath = ^"ModeSprites/FirewallSprite"
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
var _current_mode: StringName = MODE_DEFENDER
var _signal_boost_sprite: Sprite2D
var _firewall_sprite: Sprite2D
var _defender_sprite_frames: SpriteFrames
var _static_mode_sprite_frames := {}
var _signal_boost_active := false


func _ready() -> void:
	add_to_group("Defender")
	add_to_group("OFFENSE_TOWER")
	_home_position = global_position
	_drag_start_position = _home_position
	_rest_rotation = rotation
	_base_modulate = modulate
	z_index = maxi(z_index, TOWER_VISUAL_Z_INDEX)
	z_as_relative = false
	_platform_highlight = get_node_or_null(platform_highlight_path) as ColorRect
	_signal_boost_sprite = get_node_or_null(signal_boost_sprite_path) as Sprite2D
	_firewall_sprite = get_node_or_null(firewall_sprite_path) as Sprite2D
	_summon_sfx = get_node_or_null(summon_sfx_path) as AudioStreamPlayer
	_hide_mode_sprite_source_nodes()
	if _platform_highlight != null:
		_platform_highlight.hide()

	if not animation_finished.is_connected(_return_to_idle):
		animation_finished.connect(_return_to_idle)

	if _has_required_animations(sprite_frames):
		_capture_defender_sprite_frames(sprite_frames)
		_prepare_static_mode_sprite_frames()
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
	if _signal_boost_active == active:
		return

	_signal_boost_active = active
	_range_preview_radius = -1.0
	_update_attack_range_preview()


func is_signal_boost_active() -> bool:
	return _signal_boost_active


func get_signal_boost_range_multiplier() -> float:
	return SIGNAL_BOOST_RANGE_MULTIPLIER if _signal_boost_active else 1.0


func get_signal_boost_cooldown_multiplier() -> float:
	return SIGNAL_BOOST_COOLDOWN_MULTIPLIER if _signal_boost_active else 1.0


func get_signal_boost_hawk_speed_multiplier() -> float:
	return SIGNAL_BOOST_HAWK_SPEED_MULTIPLIER if _signal_boost_active else 1.0


func update_attack(delta: float, active_viruses: Array[PathFollow2D]) -> PathFollow2D:
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
	return get_tower_rect().has_point(pointer_position)


func get_tower_rect() -> Rect2:
	var size := PLACEMENT_HIGHLIGHT_SIZE
	if sprite_frames != null and sprite_frames.has_animation(animation):
		var texture := sprite_frames.get_frame_texture(animation, frame)
		if texture != null:
			var current_scale := global_scale
			size = texture.get_size() * Vector2(abs(current_scale.x), abs(current_scale.y))

	size.x = max(size.x, GRAB_SIZE.x)
	size.y = max(size.y, GRAB_SIZE.y)

	var top_left := global_position - size * 0.5
	if not centered:
		top_left = global_position

	return Rect2(top_left, size)


func aim_at(target_position: Vector2) -> void:
	var direction := target_position - global_position
	if direction.length_squared() > 0.0:
		rotation = direction.angle() - forward_rotation_offset


func play_animation(animation_name: StringName) -> void:
	if sprite_frames == null or not sprite_frames.has_animation(animation_name):
		return

	animation = animation_name
	frame = 0
	frame_progress = 0.0
	play()


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


func _get_game_root() -> Node:
	var current_scene := get_tree().current_scene
	return current_scene if current_scene != null else get_tree().root


func _apply_sprite_frames(frames: SpriteFrames) -> void:
	_capture_defender_sprite_frames(frames)
	_prepare_static_mode_sprite_frames()
	sprite_frames = frames
	play_animation(IDLE_ANIMATION)


func _has_required_animations(frames: SpriteFrames) -> bool:
	return frames != null \
		and frames.has_animation(IDLE_ANIMATION) \
		and frames.has_animation(SUMMON_ANIMATION) \
		and frames.has_animation(SHOOT_ANIMATION)


func _capture_defender_sprite_frames(frames: SpriteFrames) -> void:
	if frames != null:
		_defender_sprite_frames = frames


func _prepare_static_mode_sprite_frames() -> void:
	if _static_mode_sprite_frames.is_empty():
		_static_mode_sprite_frames[MODE_SIGNAL_BOOST] = _build_static_mode_sprite_frames(_get_signal_boost_texture())
		_static_mode_sprite_frames[MODE_FIREWALL] = _build_static_mode_sprite_frames(_get_firewall_texture())


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
	_prepare_static_mode_sprite_frames()
	if _current_mode == MODE_DEFENDER:
		if _defender_sprite_frames != null:
			sprite_frames = _defender_sprite_frames
	else:
		var mode_frames := _static_mode_sprite_frames.get(_current_mode) as SpriteFrames
		if mode_frames != null:
			sprite_frames = mode_frames

	if _has_required_animations(sprite_frames):
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
	if animation != IDLE_ANIMATION:
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
	if animation == SHOOT_ANIMATION:
		play_idle()
