class_name HoneypotProductionTower
extends "res://Scripts/Towers/cyber_guardian_idle_sprite.gd"

signal production_collected(amount: int)
signal knowledge_production_collected(amount: int)

const BASE_POT_CAPACITY := 100
const PRODUCTION_AMOUNT := 1
const PRODUCTION_TICK_SECONDS_BY_LEVEL := [0.1, 0.05, 0.025, 0.01, 0.005]
const PRODUCTION_CYCLE_SECONDS := 4.0
const OVERLOAD_VIRUS_COUNT := 10
const OVERLOAD_SECONDS := 10.0
const HONEYPOT_MAX_LEVEL := 5
const HONEYPOT_UPGRADE_COSTS := [0, 0, 0, 0, 0]
const POT_CAPACITY_MULTIPLIERS := [1, 2, 4, 8, 16]
const KNOWLEDGE_PRODUCTION_UNLOCK_LEVEL := 3
const KNOWLEDGE_POT_CAPACITY := 10
const KNOWLEDGE_PRODUCTION_AMOUNT := 1
const KNOWLEDGE_PRODUCTION_TICK_SECONDS := 3.0

@export_range(32.0, 1200.0, 1.0) var production_radius := 250.0
@export var production_label_path: NodePath = ^"ProductionPotLabel"
@export var knowledge_label_path: NodePath = ^"KnowledgePotLabel"
@export var production_effect_path: NodePath = ^"ProductionEffect"
@export var production_effect_fill_path: NodePath = ^"ProductionEffect/EffectFill"
@export var production_effect_ring_path: NodePath = ^"ProductionEffect/EffectRing"
@export_group("Level Visuals")
@export var level_visual_paths: Array[NodePath] = [
	^"LevelVisuals/LV1Visual",
	^"LevelVisuals/LV2Visual",
	^"LevelVisuals/LV3Visual",
	^"LevelVisuals/LV4Visual",
	^"LevelVisuals/LV5Visual"
]
@export_group("")
@export var label_offset := Vector2(-112.0, -158.0)
@export var knowledge_label_offset := Vector2(-112.0, -67.0)
@export_range(24.0, 220.0, 1.0) var production_effect_radius := 108.0
@export_range(0.0, 8.0, 0.1) var production_effect_pulse_speed := 1.7

var _production_label: Label
var _knowledge_label: Label
var _production_effect: Node2D
var _production_effect_fill: Polygon2D
var _production_effect_ring: Line2D
var _production_pot := 0
var _knowledge_pot := 0
var _producing := false
var _production_remaining := 0.0
var _production_tick_elapsed := 0.0
var _knowledge_tick_elapsed := 0.0
var _shutdown_remaining := 0.0
var _effect_phase := 0.0
var _collect_tween: Tween
var _level_visuals: Array[AnimatedSprite2D] = []


func _ready() -> void:
	_cache_level_visuals()
	super._ready()
	remove_from_group("OFFENSE_TOWER")
	add_to_group("SUPPORT_TOWER")
	range_preview_fill_color = Color(0.04, 1.0, 0.72, 0.13)
	range_preview_outline_color = Color(0.42, 1.0, 0.78, 0.78)
	_production_label = get_node_or_null(production_label_path) as Label
	_knowledge_label = get_node_or_null(knowledge_label_path) as Label
	_production_effect = get_node_or_null(production_effect_path) as Node2D
	_production_effect_fill = get_node_or_null(production_effect_fill_path) as Polygon2D
	_production_effect_ring = get_node_or_null(production_effect_ring_path) as Line2D
	_configure_status_nodes()
	_rebuild_production_effect_geometry()
	_sync_level_visual()
	_sync_status_visuals(0.0)


func _process(delta: float) -> void:
	super._process(delta)
	_sync_status_visuals(delta)


func reset_tower() -> void:
	super.reset_tower()
	_sync_level_visual()
	_production_pot = 0
	_knowledge_pot = 0
	_producing = false
	_production_remaining = 0.0
	_production_tick_elapsed = 0.0
	_knowledge_tick_elapsed = 0.0
	_shutdown_remaining = 0.0
	_effect_phase = 0.0
	_sync_status_visuals(0.0)


func get_attack_range() -> float:
	return production_radius * _get_signal_boost_range_multiplier()


func get_max_level() -> int:
	return HONEYPOT_MAX_LEVEL


func can_upgrade() -> bool:
	return level < HONEYPOT_MAX_LEVEL


func get_upgrade_cost() -> int:
	if not can_upgrade():
		return 0

	return int(HONEYPOT_UPGRADE_COSTS[level])


func upgrade() -> bool:
	if not can_upgrade():
		return false

	level += 1
	_range_preview_radius = -1.0
	_sync_level_visual()
	if is_placed():
		_spawn_summon_effect()
	return true


func play_animation(_animation_name: StringName) -> void:
	if _level_visuals.is_empty():
		_cache_level_visuals()

	var level_index := _get_level_index()
	if level_index >= _level_visuals.size():
		return

	var visual := _level_visuals[level_index]
	if visual == null or visual.sprite_frames == null:
		return

	var level_animation := StringName("idle_lv%d" % (level_index + 1))
	if not visual.sprite_frames.has_animation(level_animation):
		return

	_active_visual = visual
	_current_animation = level_animation
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


func _cache_level_visuals() -> void:
	_level_visuals.clear()
	for visual_path in level_visual_paths:
		_level_visuals.append(get_node_or_null(visual_path) as AnimatedSprite2D)


func _sync_level_visual() -> void:
	play_animation(IDLE_ANIMATION)


func get_production_rate() -> float:
	return float(PRODUCTION_AMOUNT) / get_production_tick_seconds()


func get_production_tick_seconds() -> float:
	return float(PRODUCTION_TICK_SECONDS_BY_LEVEL[_get_level_index()])


func get_pot_capacity() -> int:
	return BASE_POT_CAPACITY * int(POT_CAPACITY_MULTIPLIERS[_get_level_index()])


func is_knowledge_production_unlocked() -> bool:
	return level >= KNOWLEDGE_PRODUCTION_UNLOCK_LEVEL


func get_knowledge_pot() -> int:
	return _knowledge_pot


func get_knowledge_pot_capacity() -> int:
	return KNOWLEDGE_POT_CAPACITY


func get_overload_threshold() -> int:
	return OVERLOAD_VIRUS_COUNT


func get_status_text() -> String:
	if _shutdown_remaining > 0.0:
		return "Overloaded %.0fs" % ceilf(_shutdown_remaining)
	if _production_pot >= get_pot_capacity():
		return "Ready to collect"
	if _producing:
		return "Producing"

	return "Waiting for virus"


func update_attack(_delta: float, _active_viruses: Array[PathFollow2D]) -> PathFollow2D:
	return null


func update_support_scan(active_viruses: Array[PathFollow2D], delta: float) -> void:
	if not is_placed():
		_stop_production()
		_shutdown_remaining = 0.0
		_knowledge_tick_elapsed = 0.0
		return
	if _shutdown_remaining > 0.0:
		_stop_production()
		_shutdown_remaining = maxf(0.0, _shutdown_remaining - delta)
		return

	var virus_count := _count_viruses_in_radius(active_viruses)
	if virus_count >= OVERLOAD_VIRUS_COUNT:
		_start_shutdown()
		return
	if _production_pot >= get_pot_capacity():
		_stop_production()
		return
	if _producing:
		_update_production_cycle(active_viruses, delta)
		return

	_try_start_production_cycle(virus_count)


func collect_production() -> int:
	if not is_placed() or _production_pot <= 0:
		return 0

	var collected := _production_pot
	_production_pot = 0
	_play_collect_feedback()
	_sync_status_visuals(0.0)
	production_collected.emit(collected)
	return collected


func collect_knowledge_production() -> int:
	if not is_placed() or _knowledge_pot <= 0:
		return 0

	var collected := _knowledge_pot
	_knowledge_pot = 0
	_play_collect_feedback()
	_sync_status_visuals(0.0)
	knowledge_production_collected.emit(collected)
	return collected


func get_production_pot() -> int:
	return _production_pot


func is_overloaded() -> bool:
	return _shutdown_remaining > 0.0


func is_producing() -> bool:
	return _producing


func _update_production_cycle(active_viruses: Array[PathFollow2D], delta: float) -> void:
	_production_remaining = maxf(0.0, _production_remaining - delta)
	_production_tick_elapsed += delta
	var production_tick_seconds := get_production_tick_seconds()
	var pot_capacity := get_pot_capacity()
	while _production_tick_elapsed >= production_tick_seconds and _production_pot < pot_capacity:
		_production_tick_elapsed -= production_tick_seconds
		_production_pot = mini(pot_capacity, _production_pot + PRODUCTION_AMOUNT)

	_update_knowledge_production(delta)

	if _production_pot >= pot_capacity:
		_stop_production()
		return
	if _production_remaining > 0.0:
		return

	_stop_production()
	_try_start_production_cycle(_count_viruses_in_radius(active_viruses))


func _try_start_production_cycle(virus_count: int) -> void:
	if virus_count >= OVERLOAD_VIRUS_COUNT:
		_start_shutdown()
		return
	if virus_count <= 0:
		_knowledge_tick_elapsed = 0.0
		return

	_producing = true
	_production_remaining = PRODUCTION_CYCLE_SECONDS
	_production_tick_elapsed = 0.0
	_effect_phase = 0.0


func _start_shutdown() -> void:
	_stop_production()
	_knowledge_tick_elapsed = 0.0
	_shutdown_remaining = OVERLOAD_SECONDS


func _update_knowledge_production(delta: float) -> void:
	if not is_knowledge_production_unlocked() or _knowledge_pot >= KNOWLEDGE_POT_CAPACITY:
		return

	_knowledge_tick_elapsed += delta
	while _knowledge_tick_elapsed >= KNOWLEDGE_PRODUCTION_TICK_SECONDS and _knowledge_pot < KNOWLEDGE_POT_CAPACITY:
		_knowledge_tick_elapsed -= KNOWLEDGE_PRODUCTION_TICK_SECONDS
		_knowledge_pot = mini(KNOWLEDGE_POT_CAPACITY, _knowledge_pot + KNOWLEDGE_PRODUCTION_AMOUNT)


func _stop_production() -> void:
	_producing = false
	_production_remaining = 0.0
	_production_tick_elapsed = 0.0


func _count_viruses_in_radius(active_viruses: Array[PathFollow2D]) -> int:
	var attack_range := get_attack_range()
	var radius_squared := attack_range * attack_range
	var count := 0
	for follow in active_viruses:
		if not is_instance_valid(follow):
			continue

		var virus := _get_follow_virus(follow)
		if virus != null:
			if virus.is_destroying():
				continue
			if global_position.distance_squared_to(virus.global_position) <= radius_squared:
				count += 1
		elif global_position.distance_squared_to(follow.global_position) <= radius_squared:
			count += 1

	return count


func _configure_status_nodes() -> void:
	if _production_label != null:
		_production_label.top_level = true
		_production_label.z_as_relative = false
		_production_label.z_index = z_index + 30
	if _knowledge_label != null:
		_knowledge_label.top_level = true
		_knowledge_label.z_as_relative = false
		_knowledge_label.z_index = z_index + 30
	if _production_effect != null:
		_production_effect.top_level = true
		_production_effect.z_as_relative = false
		_production_effect.z_index = z_index - 1
	if _production_effect_ring != null:
		_production_effect_ring.antialiased = true
		_production_effect_ring.joint_mode = Line2D.LINE_JOINT_ROUND
		_production_effect_ring.begin_cap_mode = Line2D.LINE_CAP_ROUND
		_production_effect_ring.end_cap_mode = Line2D.LINE_CAP_ROUND


func _rebuild_production_effect_geometry() -> void:
	if _production_effect_fill != null:
		_production_effect_fill.polygon = _build_circle_points(production_effect_radius, false)
	if _production_effect_ring != null:
		_production_effect_ring.points = _build_circle_points(production_effect_radius, true)


func _sync_status_visuals(delta: float) -> void:
	_sync_production_label()
	_sync_knowledge_label()
	_sync_production_effect(delta)
	_sync_shutdown_modulate()


func _sync_production_label() -> void:
	if _production_label == null:
		return

	_production_label.visible = is_placed()
	if not _production_label.visible:
		return

	_production_label.global_position = global_position + label_offset
	_production_label.scale = Vector2.ONE
	var pot_capacity := get_pot_capacity()
	if _shutdown_remaining > 0.0:
		_production_label.text = "Production Pot\n%d/%d\nOVERLOAD %.0fs" % [_production_pot, pot_capacity, ceilf(_shutdown_remaining)]
		_production_label.add_theme_color_override("font_color", Color(1.0, 0.32, 0.24, 1.0))
	elif _production_pot >= pot_capacity:
		_production_label.text = "Production Pot\n%d/%d\nCOLLECT" % [_production_pot, pot_capacity]
		_production_label.add_theme_color_override("font_color", Color(0.38, 1.0, 0.44, 1.0))
	elif _producing:
		_production_label.text = "Production Pot\n%d/%d\n+%.1f/s" % [_production_pot, pot_capacity, get_production_rate()]
		_production_label.add_theme_color_override("font_color", Color(0.55, 1.0, 0.82, 1.0))
	else:
		_production_label.text = "Production Pot\n%d/%d" % [_production_pot, pot_capacity]
		_production_label.add_theme_color_override("font_color", Color(0.64, 0.9, 1.0, 1.0))


func _sync_knowledge_label() -> void:
	if _knowledge_label == null:
		return

	_knowledge_label.visible = is_placed() and is_knowledge_production_unlocked()
	if not _knowledge_label.visible:
		return

	_knowledge_label.global_position = global_position + knowledge_label_offset
	_knowledge_label.scale = Vector2.ONE
	if _knowledge_pot >= KNOWLEDGE_POT_CAPACITY:
		_knowledge_label.text = "Knowledge Pot  %d/%d  COLLECT" % [_knowledge_pot, KNOWLEDGE_POT_CAPACITY]
		_knowledge_label.add_theme_color_override("font_color", Color(0.9, 0.64, 1.0, 1.0))
	elif _producing:
		_knowledge_label.text = "Knowledge Pot  %d/%d  +1/3s" % [_knowledge_pot, KNOWLEDGE_POT_CAPACITY]
		_knowledge_label.add_theme_color_override("font_color", Color(0.76, 0.46, 1.0, 1.0))
	else:
		_knowledge_label.text = "Knowledge Pot  %d/%d" % [_knowledge_pot, KNOWLEDGE_POT_CAPACITY]
		_knowledge_label.add_theme_color_override("font_color", Color(0.76, 0.46, 1.0, 1.0))


func _get_level_index() -> int:
	return clampi(level - 1, 0, HONEYPOT_MAX_LEVEL - 1)


func _sync_production_effect(delta: float) -> void:
	if _production_effect == null:
		return

	var should_show := is_placed() and _producing
	_production_effect.visible = should_show
	if not should_show:
		return

	_effect_phase += delta * production_effect_pulse_speed
	var pulse := 1.0 + sin(_effect_phase * TAU) * 0.08
	var alpha := 0.7 + sin(_effect_phase * TAU) * 0.18
	_production_effect.global_position = global_position
	_production_effect.global_rotation = 0.0
	_production_effect.global_scale = Vector2.ONE * pulse
	if _production_effect_fill != null:
		_production_effect_fill.color = Color(0.0, 0.95, 0.62, 0.13 * alpha)
	if _production_effect_ring != null:
		_production_effect_ring.default_color = Color(0.5, 1.0, 0.78, 0.9 * alpha)


func _sync_shutdown_modulate() -> void:
	if is_dragging():
		return

	if _shutdown_remaining > 0.0:
		modulate = Color(0.58, 0.66, 0.76, 0.82)
	else:
		modulate = Color.WHITE


func _play_collect_feedback() -> void:
	if _production_label == null:
		return
	if _collect_tween != null:
		_collect_tween.kill()

	_collect_tween = create_tween()
	_collect_tween.set_parallel(true)
	_collect_tween.tween_property(_production_label, "scale", Vector2(1.12, 1.12), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_collect_tween.tween_property(self, "modulate", Color(0.7, 1.0, 0.88, 1.0), 0.12)
	_collect_tween.set_parallel(false)
	_collect_tween.tween_property(_production_label, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_collect_tween.tween_property(self, "modulate", Color.WHITE, 0.2)


func _build_circle_points(radius: float, close_loop: bool) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(RANGE_PREVIEW_SEGMENTS):
		var angle := TAU * float(index) / float(RANGE_PREVIEW_SEGMENTS)
		points.append(Vector2(cos(angle), sin(angle)) * radius)

	if close_loop and not points.is_empty():
		points.append(points[0])

	return points
