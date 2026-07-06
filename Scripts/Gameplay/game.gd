extends Node2D

signal wave_started(wave_number: int)
signal current_wave_changed(wave_number: int)

const CyberGuardianTowerScript := preload("res://Scripts/Towers/cyber_guardian_idle_sprite.gd")
const LaserTurretScript := preload("res://Scripts/Towers/laser_turret.gd")
const IDSScannerTowerScript := preload("res://Scripts/Towers/ids_scanner.gd")
const EDRHunterTowerScript := preload("res://Scripts/Towers/edr_hunter.gd")
const SIEMHawkTowerScript := preload("res://Scripts/Towers/siem_hawk.gd")
const IPSIntrusionTowerScript := preload("res://Scripts/Towers/ips_intrusion.gd")
const HoneypotProductionTowerScript := preload("res://Scripts/Towers/honeypot_production.gd")
const RedVirusScript := preload("res://Scripts/Enemies/red_virus.gd")
const RedVirusScene := preload("res://Scenes/Enemies/RedVirus.tscn")
const TrojanHorseScene := preload("res://Scenes/Enemies/TrojanHorse.tscn")
const CyberQuestionHUDScript := preload("res://Scripts/UI/cyber_question_hud.gd")
const PerformanceHUDScript := preload("res://Scripts/UI/performance_hud.gd")
const GameControlsHUDScript := preload("res://Scripts/UI/game_controls_hud.gd")
const TowerUpgradeHUDScript := preload("res://Scripts/UI/tower_upgrade_hud.gd")
const ProgressHUDScript := preload("res://Scripts/UI/progress_hud.gd")
const UtilityOverlayHUDScript := preload("res://Scripts/UI/utility_overlay_hud.gd")
const TARGET_FPS := 60
const FPS_UPDATE_INTERVAL := 0.25
const VIRUS_BATCH_SPACING := 10.0
const WAVE_BASE_VIRUS_COUNT := 5
const WAVE_VIRUS_COUNT_STEP := 2
const WAVE_SPAWN_INTERVAL := 0.6
const WAVE_MAX_COUNT := 20
const WAVE_FIVE_CUTSCENE_WAVE := 5
const LASER_DURATION := 0.24
const GUARDIAN_CYBERBUCK_REWARD := 5
const LASER_TURRET_CYBERBUCK_REWARD := 5
const DEFAULT_VIRUS_SPAWN_SCALE := Vector2(0.2, 0.2)
const DEFAULT_TROJAN_HORSE_SPAWN_SCALE := Vector2(0.4, 0.4)

@export var guardian_path: NodePath = ^"Sprites/Cybersec Guardian"
@export var laser_turret_path: NodePath = ^"Sprites/Laser Turret"
@export var ids_scanner_path: NodePath = ^"Sprites/IDS_Scanner"
@export var edr_hunter_path: NodePath = ^"Sprites/EDR_Hunter"
@export var siem_hawk_path: NodePath = ^"Sprites/SIEM_Hawk"
@export var ips_intrusion_path: NodePath = ^"Sprites/IPS_Intrusion"
@export var honeypot_production_path: NodePath = ^"Sprites/Honeypot_Production"
@export var virus_template_path: NodePath = ^"Sprites/BasicVirus"
@export var virus_scene: PackedScene = RedVirusScene
@export var virus_path_path: NodePath = ^"VirusElements/Path2D"
@export var virus_spawn_path: NodePath = ^"VirusElements/Marker2D"
@export var question_hud_path: NodePath = ^"CyberQuestionHUD"
@export var performance_hud_path: NodePath = ^"PerformanceHUD"
@export var game_controls_hud_path: NodePath = ^"GameControlsHUD"
@export var tower_upgrade_hud_path: NodePath = ^"TowerUpgradeHUD"
@export var progress_hud_path: NodePath = ^"ProgressHUD"
@export var utility_overlay_hud_path: NodePath = ^"UtilityOverlayHUD"
@export var wave_label_path: NodePath = ^"WavesLabel"
@export var text_cutscene_hud_path: NodePath = ^"TextCutsceneHUD"
@export var cutscene_skip_hud_path: NodePath = ^"CutsceneSkipHUD"
@export var demo_spawn_buttons_ignore_question_lock := false
@export_group("Path Guide")
@export var show_path_guide := true
@export_range(4.0, 64.0, 1.0) var path_guide_sample_spacing := 16.0
@export_range(20.0, 240.0, 1.0) var path_guide_arrow_spacing := 90.0
@export_range(4.0, 64.0, 1.0) var path_guide_arrow_size := 10.0
@export_range(1.0, 24.0, 0.5) var path_guide_width := 0.5
@export var path_guide_color := Color(0.477, 0.813, 0.521, 0.95)
@export_group("")

var _fps_update_elapsed := 0.0
var _guardian: CyberGuardianTowerScript
var _laser_turret: LaserTurretScript
var _ids_scanner: IDSScannerTowerScript
var _edr_hunter: EDRHunterTowerScript
var _siem_hawk: SIEMHawkTowerScript
var _ips_intrusion: IPSIntrusionTowerScript
var _honeypot_production: HoneypotProductionTowerScript
var _virus_template: RedVirusScript
var _virus_templates: Array[RedVirusScript] = []
var _virus_path: Path2D
var _virus_spawn: Node2D
var _question_hud: CyberQuestionHUDScript
var _performance_hud: PerformanceHUDScript
var _game_controls_hud: GameControlsHUDScript
var _tower_upgrade_hud: TowerUpgradeHUDScript
var _progress_hud: ProgressHUDScript
var _utility_overlay_hud: UtilityOverlayHUDScript
var _wave_label: Label
var _text_cutscene_hud: Node
var _cutscene_skip_hud: Node
var _path_guide_container: Node2D
var _active_viruses: Array[PathFollow2D] = []
var _current_wave := 0
var _wave_in_progress := false
var _wave_question_pending := false
var _wave_spawns_remaining := 0
var _wave_spawn_cooldown_remaining := 0.0
var _wave_five_cutscene_played := false
var _wave_five_cutscene_running := false

func _ready() -> void:
	Engine.max_fps = TARGET_FPS
	_show_canvas_layers_for_runtime()
	_guardian = get_node_or_null(guardian_path) as CyberGuardianTowerScript
	_laser_turret = get_node_or_null(laser_turret_path) as LaserTurretScript
	_ids_scanner = get_node_or_null(ids_scanner_path) as IDSScannerTowerScript
	_edr_hunter = get_node_or_null(edr_hunter_path) as EDRHunterTowerScript
	_siem_hawk = get_node_or_null(siem_hawk_path) as SIEMHawkTowerScript
	_ips_intrusion = get_node_or_null(ips_intrusion_path) as IPSIntrusionTowerScript
	_honeypot_production = get_node_or_null(honeypot_production_path) as HoneypotProductionTowerScript
	_virus_template = get_node_or_null(virus_template_path) as RedVirusScript
	_collect_virus_templates()
	_virus_path = get_node_or_null(virus_path_path) as Path2D
	_virus_spawn = get_node_or_null(virus_spawn_path) as Node2D
	_question_hud = get_node_or_null(question_hud_path) as CyberQuestionHUDScript
	_performance_hud = get_node_or_null(performance_hud_path) as PerformanceHUDScript
	_game_controls_hud = get_node_or_null(game_controls_hud_path) as GameControlsHUDScript
	_tower_upgrade_hud = get_node_or_null(tower_upgrade_hud_path) as TowerUpgradeHUDScript
	_progress_hud = get_node_or_null(progress_hud_path) as ProgressHUDScript
	_utility_overlay_hud = get_node_or_null(utility_overlay_hud_path) as UtilityOverlayHUDScript
	_wave_label = get_node_or_null(wave_label_path) as Label
	_text_cutscene_hud = get_node_or_null(text_cutscene_hud_path)
	_cutscene_skip_hud = get_node_or_null(cutscene_skip_hud_path)
	if _virus_spawn == null:
		_virus_spawn = get_node_or_null(^"VirusElements/Spawn2D") as Node2D

	if _guardian == null:
		push_warning("Cybersec Guardian drag target was not found.")
	if _laser_turret == null:
		push_warning("Laser Turret drag target was not found.")
	if _edr_hunter == null:
		push_warning("EDR Hunter drag target was not found.")
	if _siem_hawk == null:
		push_warning("SIEM Hawk drag target was not found.")
	if _ips_intrusion == null:
		push_warning("IPS Intrusion drag target was not found.")
	if _honeypot_production == null:
		push_warning("Honeypot Production drag target was not found.")
	if _virus_template == null and not String(virus_template_path).is_empty():
		push_warning("Basic virus spawn button was not found.")
	if _virus_path == null:
		push_warning("Virus Path2D was not found.")
	if _virus_spawn == null:
		push_warning("Virus spawn marker was not found.")
	if _question_hud == null:
		push_warning("CyberQuestionHUD was not found.")
	else:
		_question_hud.cyberbucks_changed.connect(Callable(self, "_on_cyberbucks_changed"))
		_on_cyberbucks_changed(_question_hud.get_cyberbucks())
		_question_hud.question_solved.connect(Callable(self, "_on_wave_question_solved"))
	if _performance_hud == null:
		push_warning("PerformanceHUD was not found.")
	if _game_controls_hud == null:
		push_warning("GameControlsHUD was not found.")
	else:
		_game_controls_hud.reset_pressed.connect(Callable(self, "_reset_tower"))
		_game_controls_hud.start_wave_pressed.connect(Callable(self, "_start_next_wave"))
		_game_controls_hud.virus_batch_requested.connect(Callable(self, "spawn_virus_batch"))
		_game_controls_hud.exit_pressed.connect(Callable(self, "_exit_game"))
	if _tower_upgrade_hud == null:
		push_warning("TowerUpgradeHUD was not found.")
	else:
		_tower_upgrade_hud.laser_upgrade_pressed.connect(Callable(self, "_upgrade_laser_turret"))
		_tower_upgrade_hud.scanner_upgrade_pressed.connect(Callable(self, "_upgrade_ids_scanner"))
		_tower_upgrade_hud.scanner_mode_pressed.connect(Callable(self, "_set_ids_scanner_mode"))
		_tower_upgrade_hud.edr_upgrade_pressed.connect(Callable(self, "_upgrade_edr_hunter"))
		_tower_upgrade_hud.siem_upgrade_pressed.connect(Callable(self, "_upgrade_siem_hawk"))
		_tower_upgrade_hud.siem_dispatch_pressed.connect(Callable(self, "_toggle_siem_hawk_dispatch"))
		_tower_upgrade_hud.siem_land_pressed.connect(Callable(self, "_land_siem_hawk_to_headquarters"))
		_tower_upgrade_hud.ips_upgrade_pressed.connect(Callable(self, "_upgrade_ips_intrusion"))
		_tower_upgrade_hud.honeypot_upgrade_pressed.connect(Callable(self, "_upgrade_honeypot_production"))
	if _siem_hawk != null:
		_siem_hawk.dispatch_mode_changed.connect(Callable(self, "_on_siem_hawk_dispatch_mode_changed"))
		_siem_hawk.knowledge_extracted.connect(Callable(self, "_on_siem_hawk_knowledge_extracted"))
		_siem_hawk.knowledge_bank_changed.connect(Callable(self, "_on_siem_hawk_knowledge_bank_changed"))
	if _ids_scanner != null:
		_ids_scanner.virus_damage_requested.connect(Callable(self, "_on_scanner_virus_damage_requested"))
		_ids_scanner.bounty_awarded.connect(Callable(self, "_on_scanner_bounty_awarded"))
	if _ips_intrusion != null:
		_ips_intrusion.spike_damage_requested.connect(Callable(self, "_on_ips_spike_damage_requested"))
	_create_path_guide()
	if _utility_overlay_hud != null:
		_utility_overlay_hud.guardian_upgrade_requested.connect(Callable(self, "_upgrade_guardian"))
		_utility_overlay_hud.laser_upgrade_requested.connect(Callable(self, "_upgrade_laser_turret"))
		_utility_overlay_hud.scanner_upgrade_requested.connect(Callable(self, "_upgrade_ids_scanner"))
		_utility_overlay_hud.edr_upgrade_requested.connect(Callable(self, "_upgrade_edr_hunter"))
		_utility_overlay_hud.siem_upgrade_requested.connect(Callable(self, "_upgrade_siem_hawk"))
		_utility_overlay_hud.ips_upgrade_requested.connect(Callable(self, "_upgrade_ips_intrusion"))
		_utility_overlay_hud.honeypot_upgrade_requested.connect(Callable(self, "_upgrade_honeypot_production"))

	_update_fps_label()
	_update_virus_count_label()
	_update_wave_button()
	_update_wave_label()
	_update_demo_upgrade_buttons()


func _show_canvas_layers_for_runtime() -> void:
	for child in get_children():
		_show_canvas_layers_for_runtime_recursive(child)


func _show_canvas_layers_for_runtime_recursive(node: Node) -> void:
	if node is CanvasLayer:
		(node as CanvasLayer).visible = true

	for child in node.get_children():
		_show_canvas_layers_for_runtime_recursive(child)


func _collect_virus_templates() -> void:
	_virus_templates.clear()
	_add_virus_template(_virus_template)

	var template_parent: Node = _virus_template.get_parent() if _virus_template != null else get_node_or_null(^"Sprites")
	if template_parent == null:
		return

	for child in template_parent.get_children():
		var virus_template := child as RedVirusScript
		if virus_template != null:
			_add_virus_template(virus_template)


func _add_virus_template(template: RedVirusScript) -> void:
	if template == null or _virus_templates.find(template) != -1:
		return

	_virus_templates.append(template)


func _input(event: InputEvent) -> void:
	if _is_act_input_locked():
		if _cutscene_skip_hud != null \
				and _cutscene_skip_hud.has_method("handle_cutscene_skip_input") \
				and bool(_cutscene_skip_hud.call("handle_cutscene_skip_input", event)):
			get_viewport().set_input_as_handled()
			return
		if _text_cutscene_hud != null and _text_cutscene_hud.has_method("handle_cutscene_advance_input"):
			_text_cutscene_hud.call("handle_cutscene_advance_input", event)
		get_viewport().set_input_as_handled()
		return

	if event is InputEventMouseButton:
		var mouse_button := event as InputEventMouseButton
		if mouse_button.button_index != MOUSE_BUTTON_LEFT:
			return

		var pointer_position := _screen_to_canvas_position(mouse_button.position)
		if mouse_button.pressed:
			if _demo_upgrade_button_has_point(mouse_button.position):
				return

			if _try_spawn_virus_from_press(pointer_position):
				get_viewport().set_input_as_handled()
				return

			if _handle_laser_turret_press(pointer_position, mouse_button.position):
				return

			if _handle_ids_scanner_press(pointer_position, mouse_button.position):
				return

			if _handle_edr_hunter_press(pointer_position, mouse_button.position):
				return

			if _handle_siem_hawk_press(pointer_position, mouse_button.position):
				return

			if _handle_ips_intrusion_press(pointer_position, mouse_button.position):
				return

			if _handle_honeypot_production_press(pointer_position, mouse_button.position):
				return

			if _ips_intrusion != null and not _ips_intrusion.is_placed() and _ips_intrusion.try_start_drag(pointer_position):
				return

			if _honeypot_production != null and not _honeypot_production.is_placed() and _honeypot_production.try_start_drag(pointer_position):
				return

			if _edr_hunter != null and not _edr_hunter.is_placed() and _edr_hunter.try_start_drag(pointer_position):
				return

			if _siem_hawk != null and not _siem_hawk.is_placed() and _siem_hawk.try_start_drag(pointer_position):
				return

			if _guardian == null:
				return

			if _guardian.is_placed():
				_handle_placed_tower_press(pointer_position, mouse_button.position)
			else:
				_guardian.try_start_drag(pointer_position)
		elif _demo_upgrade_button_has_point(mouse_button.position):
			return
		elif _siem_hawk != null and _siem_hawk.is_dragging():
			_siem_hawk.finish_drag()
		elif _honeypot_production != null and _honeypot_production.is_dragging():
			_honeypot_production.finish_drag()
		elif _ips_intrusion != null and _ips_intrusion.is_dragging():
			_ips_intrusion.finish_drag()
		elif _edr_hunter != null and _edr_hunter.is_dragging():
			_edr_hunter.finish_drag()
		elif _guardian != null and _guardian.is_dragging():
			_guardian.finish_drag()
		return

	if _edr_hunter != null and not _edr_hunter.is_placed() and event is InputEventMouseMotion and _edr_hunter.is_dragging():
		var edr_mouse_motion := event as InputEventMouseMotion
		_edr_hunter.update_drag(_screen_to_canvas_position(edr_mouse_motion.position))
		return

	if _siem_hawk != null and not _siem_hawk.is_placed() and event is InputEventMouseMotion and _siem_hawk.is_dragging():
		var siem_mouse_motion := event as InputEventMouseMotion
		_siem_hawk.update_drag(_screen_to_canvas_position(siem_mouse_motion.position))
		return

	if _ips_intrusion != null and not _ips_intrusion.is_placed() and event is InputEventMouseMotion and _ips_intrusion.is_dragging():
		var ips_mouse_motion := event as InputEventMouseMotion
		_ips_intrusion.update_drag(_screen_to_canvas_position(ips_mouse_motion.position))
		return

	if _honeypot_production != null and not _honeypot_production.is_placed() and event is InputEventMouseMotion and _honeypot_production.is_dragging():
		var honeypot_mouse_motion := event as InputEventMouseMotion
		_honeypot_production.update_drag(_screen_to_canvas_position(honeypot_mouse_motion.position))
		return

	if _guardian != null and not _guardian.is_placed() and event is InputEventMouseMotion and _guardian.is_dragging():
		var mouse_motion := event as InputEventMouseMotion
		_guardian.update_drag(_screen_to_canvas_position(mouse_motion.position))
		return

	if event is InputEventScreenTouch:
		var screen_touch := event as InputEventScreenTouch
		var pointer_position := _screen_to_canvas_position(screen_touch.position)
		if screen_touch.pressed:
			if _demo_upgrade_button_has_point(screen_touch.position):
				return

			if _try_spawn_virus_from_press(pointer_position):
				get_viewport().set_input_as_handled()
				return

			if _handle_laser_turret_press(pointer_position, screen_touch.position):
				return

			if _handle_ids_scanner_press(pointer_position, screen_touch.position):
				return

			if _handle_edr_hunter_press(pointer_position, screen_touch.position):
				return

			if _handle_siem_hawk_press(pointer_position, screen_touch.position):
				return

			if _handle_ips_intrusion_press(pointer_position, screen_touch.position):
				return

			if _handle_honeypot_production_press(pointer_position, screen_touch.position):
				return

			if _ips_intrusion != null and not _ips_intrusion.is_placed() and _ips_intrusion.try_start_drag(pointer_position):
				return

			if _honeypot_production != null and not _honeypot_production.is_placed() and _honeypot_production.try_start_drag(pointer_position):
				return

			if _edr_hunter != null and not _edr_hunter.is_placed() and _edr_hunter.try_start_drag(pointer_position):
				return

			if _siem_hawk != null and not _siem_hawk.is_placed() and _siem_hawk.try_start_drag(pointer_position):
				return

			if _guardian == null:
				return

			if _guardian.is_placed():
				_handle_placed_tower_press(pointer_position, screen_touch.position)
			else:
				_guardian.try_start_drag(pointer_position)
		elif _demo_upgrade_button_has_point(screen_touch.position):
			return
		elif _siem_hawk != null and _siem_hawk.is_dragging():
			_siem_hawk.finish_drag()
		elif _honeypot_production != null and _honeypot_production.is_dragging():
			_honeypot_production.finish_drag()
		elif _ips_intrusion != null and _ips_intrusion.is_dragging():
			_ips_intrusion.finish_drag()
		elif _edr_hunter != null and _edr_hunter.is_dragging():
			_edr_hunter.finish_drag()
		elif _guardian != null and _guardian.is_dragging():
			_guardian.finish_drag()
		return

	if _edr_hunter != null and not _edr_hunter.is_placed() and event is InputEventScreenDrag and _edr_hunter.is_dragging():
		var edr_screen_drag := event as InputEventScreenDrag
		_edr_hunter.update_drag(_screen_to_canvas_position(edr_screen_drag.position))
		return

	if _siem_hawk != null and not _siem_hawk.is_placed() and event is InputEventScreenDrag and _siem_hawk.is_dragging():
		var siem_screen_drag := event as InputEventScreenDrag
		_siem_hawk.update_drag(_screen_to_canvas_position(siem_screen_drag.position))
		return

	if _ips_intrusion != null and not _ips_intrusion.is_placed() and event is InputEventScreenDrag and _ips_intrusion.is_dragging():
		var ips_screen_drag := event as InputEventScreenDrag
		_ips_intrusion.update_drag(_screen_to_canvas_position(ips_screen_drag.position))
		return

	if _honeypot_production != null and not _honeypot_production.is_placed() and event is InputEventScreenDrag and _honeypot_production.is_dragging():
		var honeypot_screen_drag := event as InputEventScreenDrag
		_honeypot_production.update_drag(_screen_to_canvas_position(honeypot_screen_drag.position))
		return

	if _guardian != null and not _guardian.is_placed() and event is InputEventScreenDrag and _guardian.is_dragging():
		var screen_drag := event as InputEventScreenDrag
		_guardian.update_drag(_screen_to_canvas_position(screen_drag.position))


func _process(delta: float) -> void:
	if _is_act_input_locked():
		_update_fps_timer(delta)
		return

	_update_wave_spawner(delta)
	_update_active_viruses(delta)
	_update_support_tower_scans(delta)
	_update_siem_hawk_knowledge(delta)
	_update_ips_intrusion_spikes(delta)
	if _tower_upgrade_hud != null and _tower_upgrade_hud.is_scanner_panel_visible():
		_sync_scanner_upgrade_panel()
	if _tower_upgrade_hud != null and _tower_upgrade_hud.is_edr_panel_visible():
		_sync_edr_upgrade_panel()
	if _tower_upgrade_hud != null and _tower_upgrade_hud.is_siem_panel_visible():
		_sync_siem_upgrade_panel()
	if _tower_upgrade_hud != null and _tower_upgrade_hud.is_ips_panel_visible():
		_sync_ips_upgrade_panel()
	if _tower_upgrade_hud != null and _tower_upgrade_hud.is_honeypot_panel_visible():
		_sync_honeypot_upgrade_panel()
	_update_tower_attack(delta)
	_update_laser_turret_attack(delta)
	_update_edr_hunter_attack(delta)
	_update_siem_hawk_attack(delta)
	_update_demo_upgrade_buttons()

	_update_fps_timer(delta)


func _update_fps_timer(delta: float) -> void:
	_fps_update_elapsed += delta
	if _fps_update_elapsed < FPS_UPDATE_INTERVAL:
		return

	_fps_update_elapsed = 0.0
	_update_fps_label()


func _update_fps_label() -> void:
	if _performance_hud == null:
		return

	var current_fps := roundi(Performance.get_monitor(Performance.TIME_FPS))
	_performance_hud.set_fps(current_fps, TARGET_FPS)


func _handle_placed_tower_press(pointer_position: Vector2, screen_position: Vector2) -> void:
	if _tower_upgrade_hud != null and _tower_upgrade_hud.guardian_panel_has_point(screen_position):
		return

	if _guardian != null and _guardian.contains_global_point(pointer_position):
		_show_upgrade_panel()
		get_viewport().set_input_as_handled()
	elif _tower_upgrade_hud != null and _tower_upgrade_hud.is_guardian_panel_visible():
		_hide_upgrade_panel()


func _handle_laser_turret_press(pointer_position: Vector2, screen_position: Vector2) -> bool:
	if _tower_upgrade_hud != null and _tower_upgrade_hud.laser_panel_has_point(screen_position):
		return true

	if _laser_turret != null and _laser_turret.is_placed() and _laser_turret.contains_global_point(pointer_position):
		_show_laser_upgrade_panel()
		get_viewport().set_input_as_handled()
		return true

	if _tower_upgrade_hud != null and _tower_upgrade_hud.is_laser_panel_visible():
		_hide_laser_upgrade_panel()

	return false


func _handle_ids_scanner_press(pointer_position: Vector2, screen_position: Vector2) -> bool:
	if _tower_upgrade_hud != null and _tower_upgrade_hud.scanner_panel_has_point(screen_position):
		return true

	if _ids_scanner != null and _ids_scanner.is_deployed() and _ids_scanner.contains_global_point(pointer_position):
		_show_scanner_upgrade_panel()
		get_viewport().set_input_as_handled()
		return true

	if _tower_upgrade_hud != null and _tower_upgrade_hud.is_scanner_panel_visible():
		_hide_scanner_upgrade_panel()

	return false


func _handle_edr_hunter_press(pointer_position: Vector2, screen_position: Vector2) -> bool:
	if _tower_upgrade_hud != null and _tower_upgrade_hud.edr_panel_has_point(screen_position):
		return true

	if _edr_hunter != null and _edr_hunter.is_placed() and _edr_hunter.contains_global_point(pointer_position):
		_show_edr_upgrade_panel()
		get_viewport().set_input_as_handled()
		return true

	if _tower_upgrade_hud != null and _tower_upgrade_hud.is_edr_panel_visible():
		_hide_edr_upgrade_panel()

	return false


func _handle_siem_hawk_press(pointer_position: Vector2, screen_position: Vector2) -> bool:
	if _tower_upgrade_hud != null and _tower_upgrade_hud.siem_panel_has_point(screen_position):
		return true

	if _siem_hawk != null and _siem_hawk.is_placed() and _siem_hawk.contains_global_point(pointer_position):
		_show_siem_upgrade_panel()
		get_viewport().set_input_as_handled()
		return true

	if _tower_upgrade_hud != null and _tower_upgrade_hud.is_siem_panel_visible():
		_hide_siem_upgrade_panel()

	return false


func _handle_ips_intrusion_press(pointer_position: Vector2, screen_position: Vector2) -> bool:
	if _tower_upgrade_hud != null and _tower_upgrade_hud.ips_panel_has_point(screen_position):
		return true

	if _ips_intrusion != null and _ips_intrusion.is_placed() and _ips_intrusion.contains_global_point(pointer_position):
		_show_ips_upgrade_panel()
		get_viewport().set_input_as_handled()
		return true

	if _tower_upgrade_hud != null and _tower_upgrade_hud.is_ips_panel_visible():
		_hide_ips_upgrade_panel()

	return false


func _handle_honeypot_production_press(pointer_position: Vector2, screen_position: Vector2) -> bool:
	if _tower_upgrade_hud != null and _tower_upgrade_hud.honeypot_panel_has_point(screen_position):
		return true

	if _honeypot_production == null or not _honeypot_production.is_placed():
		if _tower_upgrade_hud != null and _tower_upgrade_hud.is_honeypot_panel_visible():
			_hide_honeypot_upgrade_panel()
		return false
	if not _honeypot_production.contains_global_point(pointer_position):
		if _tower_upgrade_hud != null and _tower_upgrade_hud.is_honeypot_panel_visible():
			_hide_honeypot_upgrade_panel()
		return false

	var collected := _honeypot_production.collect_production()
	if collected > 0 and _question_hud != null:
		_question_hud.add_cyberbucks(collected)
		_sync_laser_upgrade_panel()
		_sync_scanner_upgrade_panel()
		_sync_edr_upgrade_panel()
		_sync_siem_upgrade_panel()
		_sync_ips_upgrade_panel()
		_sync_honeypot_upgrade_panel()
		_update_demo_upgrade_buttons()

	_show_honeypot_upgrade_panel()
	get_viewport().set_input_as_handled()
	return true


func _reset_tower() -> void:
	if _is_act_input_locked():
		return

	if _guardian != null:
		_guardian.reset_tower()
	if _laser_turret != null:
		_laser_turret.reset_tower()
	if _edr_hunter != null:
		_edr_hunter.reset_tower()
	if _siem_hawk != null:
		_siem_hawk.reset_tower()
	if _ips_intrusion != null:
		_ips_intrusion.reset_tower()
	if _honeypot_production != null:
		_honeypot_production.reset_tower()
	for node in get_tree().get_nodes_in_group("Defender"):
		if node == _guardian or node == _laser_turret or node == _edr_hunter or node == _siem_hawk or node == _ips_intrusion or node == _honeypot_production or not is_instance_valid(node):
			continue
		if node.has_method("reset_tower"):
			node.call("reset_tower")
	if _tower_upgrade_hud != null:
		_tower_upgrade_hud.hide_all()
	if _progress_hud != null:
		_progress_hud.reset_knowledge()
	_set_tower_menu_radius_previews(false, false, false, false, false)
	_update_demo_upgrade_buttons()


func _upgrade_guardian() -> void:
	if _is_act_input_locked():
		return

	if _guardian == null or not _guardian.can_upgrade():
		return

	var cost := _guardian.get_upgrade_cost()
	if not _spend_upgrade_cost(cost):
		_sync_laser_upgrade_panel()
		_sync_scanner_upgrade_panel()
		_sync_edr_upgrade_panel()
		_sync_siem_upgrade_panel()
		_update_demo_upgrade_buttons()
		return

	var upgraded := _guardian.upgrade()
	_sync_laser_upgrade_panel()
	_sync_scanner_upgrade_panel()
	_sync_edr_upgrade_panel()
	_sync_siem_upgrade_panel()
	_update_demo_upgrade_buttons()
	if upgraded and _utility_overlay_hud != null:
		_utility_overlay_hud.show_tower_upgrade_fx(_world_to_screen_position(_guardian.global_position))


func _upgrade_laser_turret() -> void:
	if _is_act_input_locked():
		return

	if _laser_turret == null or not _laser_turret.can_upgrade():
		return

	var cost := _laser_turret.get_upgrade_cost()
	if not _spend_upgrade_cost(cost):
		_sync_laser_upgrade_panel()
		_sync_scanner_upgrade_panel()
		_sync_edr_upgrade_panel()
		_sync_siem_upgrade_panel()
		_update_demo_upgrade_buttons()
		return

	var upgraded := _laser_turret.upgrade()
	_sync_laser_upgrade_panel()
	_sync_scanner_upgrade_panel()
	_sync_edr_upgrade_panel()
	_sync_siem_upgrade_panel()
	_update_demo_upgrade_buttons()
	if upgraded and _utility_overlay_hud != null:
		_laser_turret.preview_attack_range()
		_utility_overlay_hud.show_tower_upgrade_fx(_world_to_screen_position(_laser_turret.global_position))


func _upgrade_ids_scanner() -> void:
	if _is_act_input_locked():
		return

	if _ids_scanner == null or not _ids_scanner.can_upgrade():
		return

	var cost := _ids_scanner.get_upgrade_cost()
	if not _spend_upgrade_cost(cost):
		_sync_laser_upgrade_panel()
		_sync_scanner_upgrade_panel()
		_sync_edr_upgrade_panel()
		_sync_siem_upgrade_panel()
		_update_demo_upgrade_buttons()
		return

	var upgraded := _ids_scanner.upgrade()
	_sync_laser_upgrade_panel()
	_sync_scanner_upgrade_panel()
	_sync_edr_upgrade_panel()
	_sync_siem_upgrade_panel()
	_update_demo_upgrade_buttons()
	if upgraded and _utility_overlay_hud != null:
		_utility_overlay_hud.show_tower_upgrade_fx(_world_to_screen_position(_ids_scanner.global_position))


func _upgrade_edr_hunter() -> void:
	if _is_act_input_locked():
		return

	if _edr_hunter == null or not _edr_hunter.can_upgrade():
		return

	var cost := _edr_hunter.get_upgrade_cost()
	if not _spend_upgrade_cost(cost):
		_sync_laser_upgrade_panel()
		_sync_scanner_upgrade_panel()
		_sync_edr_upgrade_panel()
		_sync_siem_upgrade_panel()
		_update_demo_upgrade_buttons()
		return

	var upgraded := _edr_hunter.upgrade()
	_sync_laser_upgrade_panel()
	_sync_scanner_upgrade_panel()
	_sync_edr_upgrade_panel()
	_sync_siem_upgrade_panel()
	_update_demo_upgrade_buttons()
	if upgraded and _utility_overlay_hud != null:
		_utility_overlay_hud.show_tower_upgrade_fx(_world_to_screen_position(_edr_hunter.global_position))


func _upgrade_siem_hawk() -> void:
	if _is_act_input_locked():
		return

	if _siem_hawk == null or not _siem_hawk.can_upgrade():
		return

	var cost := _siem_hawk.get_upgrade_cost()
	if not _spend_upgrade_cost(cost):
		_sync_laser_upgrade_panel()
		_sync_scanner_upgrade_panel()
		_sync_edr_upgrade_panel()
		_sync_siem_upgrade_panel()
		_update_demo_upgrade_buttons()
		return

	var upgraded := _siem_hawk.upgrade()
	_sync_laser_upgrade_panel()
	_sync_scanner_upgrade_panel()
	_sync_edr_upgrade_panel()
	_sync_siem_upgrade_panel()
	_update_demo_upgrade_buttons()
	if upgraded and _utility_overlay_hud != null:
		_utility_overlay_hud.show_tower_upgrade_fx(_world_to_screen_position(_siem_hawk.global_position))


func _upgrade_ips_intrusion() -> void:
	if _is_act_input_locked():
		return

	if _ips_intrusion == null or not _ips_intrusion.can_upgrade():
		return

	var cost := _ips_intrusion.get_upgrade_cost()
	if not _spend_upgrade_cost(cost):
		_sync_ips_upgrade_panel()
		_update_demo_upgrade_buttons()
		return

	var upgraded := _ips_intrusion.upgrade()
	_sync_ips_upgrade_panel()
	_update_demo_upgrade_buttons()
	if upgraded and _utility_overlay_hud != null:
		_utility_overlay_hud.show_tower_upgrade_fx(_world_to_screen_position(_ips_intrusion.global_position))


func _upgrade_honeypot_production() -> void:
	if _is_act_input_locked():
		return

	if _honeypot_production == null or not _honeypot_production.can_upgrade():
		return

	var cost := _honeypot_production.get_upgrade_cost()
	if not _spend_upgrade_cost(cost):
		_sync_honeypot_upgrade_panel()
		_update_demo_upgrade_buttons()
		return

	var upgraded := _honeypot_production.upgrade()
	_sync_honeypot_upgrade_panel()
	_update_demo_upgrade_buttons()
	if upgraded and _utility_overlay_hud != null:
		_utility_overlay_hud.show_tower_upgrade_fx(_world_to_screen_position(_honeypot_production.global_position))


func _toggle_siem_hawk_dispatch() -> void:
	if _is_act_input_locked():
		return
	if _siem_hawk == null:
		return

	_siem_hawk.toggle_dispatch()
	_sync_siem_upgrade_panel()


func _land_siem_hawk_to_headquarters() -> void:
	if _is_act_input_locked():
		return
	if _siem_hawk == null:
		return

	_siem_hawk.land_to_headquarters()
	_sync_siem_upgrade_panel()


func _set_ids_scanner_mode(mode_id: StringName) -> void:
	if _is_act_input_locked():
		return
	if _ids_scanner == null:
		return

	if not _ids_scanner_can_change_mode_now():
		if _tower_upgrade_hud != null:
			_tower_upgrade_hud.show_scanner_mode_notice("Cannot change mode while a virus is in the IDS scan.")
		_sync_scanner_upgrade_panel()
		return

	_ids_scanner.set_scanner_mode(mode_id)
	_sync_scanner_upgrade_panel()


func _on_scanner_virus_damage_requested(follow: PathFollow2D, amount: int) -> void:
	_damage_virus(follow, amount)


func _on_ips_spike_damage_requested(follow: PathFollow2D, amount: int) -> void:
	_damage_virus(follow, amount)


func _on_scanner_bounty_awarded(amount: int) -> void:
	if _question_hud == null:
		return

	_question_hud.add_cyberbucks(amount)
	_sync_laser_upgrade_panel()
	_sync_scanner_upgrade_panel()
	_sync_edr_upgrade_panel()
	_sync_siem_upgrade_panel()
	_update_demo_upgrade_buttons()


func _on_cyberbucks_changed(amount: int) -> void:
	if _progress_hud != null:
		_progress_hud.set_cyberbucks(amount)


func _on_siem_hawk_knowledge_extracted(amount: int) -> void:
	if _progress_hud == null:
		return

	_progress_hud.add_knowledge_points(amount)


func _on_siem_hawk_dispatch_mode_changed(_dispatched: bool) -> void:
	_sync_siem_upgrade_panel()


func _on_siem_hawk_knowledge_bank_changed(_banked_points: int) -> void:
	_sync_siem_upgrade_panel()


func _update_demo_upgrade_buttons() -> void:
	if _utility_overlay_hud == null:
		return

	var guardian_cost := _guardian.get_upgrade_cost() if _guardian != null else 0
	_utility_overlay_hud.set_guardian_upgrade_button_state(
		_world_to_screen_position(_guardian.global_position) if _guardian != null else Vector2.ZERO,
		_guardian != null and _guardian.is_placed(),
		_guardian != null and _guardian.can_upgrade(),
		_is_demo_guardian_upgrade_hovered(),
		guardian_cost,
		_can_afford_upgrade(guardian_cost)
	)

	var laser_cost := _laser_turret.get_upgrade_cost() if _laser_turret != null else 0
	_utility_overlay_hud.set_laser_upgrade_button_state(
		_world_to_screen_position(_laser_turret.global_position) if _laser_turret != null else Vector2.ZERO,
		_laser_turret != null and _laser_turret.is_placed(),
		_laser_turret != null and _laser_turret.can_upgrade(),
		_is_demo_laser_upgrade_hovered(),
		laser_cost,
		_can_afford_upgrade(laser_cost)
	)

	var scanner_cost := _ids_scanner.get_upgrade_cost() if _ids_scanner != null else 0
	_utility_overlay_hud.set_scanner_upgrade_button_state(
		_world_to_screen_position(_ids_scanner.global_position) if _ids_scanner != null else Vector2.ZERO,
		_ids_scanner != null and _ids_scanner.is_deployed(),
		_ids_scanner != null and _ids_scanner.can_upgrade(),
		_is_demo_scanner_upgrade_hovered(),
		scanner_cost,
		_can_afford_upgrade(scanner_cost)
	)

	var edr_cost := _edr_hunter.get_upgrade_cost() if _edr_hunter != null else 0
	_utility_overlay_hud.set_edr_upgrade_button_state(
		_world_to_screen_position(_edr_hunter.global_position) if _edr_hunter != null else Vector2.ZERO,
		_edr_hunter != null and _edr_hunter.is_placed(),
		_edr_hunter != null and _edr_hunter.can_upgrade(),
		_is_demo_edr_upgrade_hovered(),
		edr_cost,
		_can_afford_upgrade(edr_cost)
	)

	var siem_cost := _siem_hawk.get_upgrade_cost() if _siem_hawk != null else 0
	_utility_overlay_hud.set_siem_upgrade_button_state(
		_world_to_screen_position(_siem_hawk.global_position) if _siem_hawk != null else Vector2.ZERO,
		_siem_hawk != null and _siem_hawk.is_placed(),
		_siem_hawk != null and _siem_hawk.can_upgrade(),
		_is_demo_siem_upgrade_hovered(),
		siem_cost,
		_can_afford_upgrade(siem_cost)
	)

	var ips_cost := _ips_intrusion.get_upgrade_cost() if _ips_intrusion != null else 0
	_utility_overlay_hud.set_ips_upgrade_button_state(
		_world_to_screen_position(_ips_intrusion.global_position) if _ips_intrusion != null else Vector2.ZERO,
		_ips_intrusion != null and _ips_intrusion.is_placed(),
		_ips_intrusion != null and _ips_intrusion.can_upgrade(),
		_is_demo_ips_upgrade_hovered(),
		ips_cost,
		_can_afford_upgrade(ips_cost)
	)

	var honeypot_cost := _honeypot_production.get_upgrade_cost() if _honeypot_production != null else 0
	_utility_overlay_hud.set_honeypot_upgrade_button_state(
		_world_to_screen_position(_honeypot_production.global_position) if _honeypot_production != null else Vector2.ZERO,
		_honeypot_production != null and _honeypot_production.is_placed(),
		_honeypot_production != null and _honeypot_production.can_upgrade(),
		_is_demo_honeypot_upgrade_hovered(),
		honeypot_cost,
		_can_afford_upgrade(honeypot_cost)
	)


func _can_afford_upgrade(cost: int) -> bool:
	if cost <= 0:
		return true

	return _question_hud != null and _question_hud.can_spend_cyberbucks(cost)


func _spend_upgrade_cost(cost: int) -> bool:
	if cost <= 0:
		return true
	if _question_hud == null:
		return false

	return _question_hud.spend_cyberbucks(cost)


func _sync_laser_upgrade_panel() -> void:
	if _laser_turret == null or _tower_upgrade_hud == null:
		return

	var level := _laser_turret.get_level()
	var max_level := _laser_turret.get_max_level()
	var power := _laser_turret.get_shot_power()
	var range := _laser_turret.get_attack_range()
	var upgrade_cost := _laser_turret.get_upgrade_cost()
	var can_afford_next_level := _can_afford_upgrade(upgrade_cost)
	_tower_upgrade_hud.set_laser_stats(level, max_level, power, range, _laser_turret.can_upgrade() and can_afford_next_level, upgrade_cost)


func _sync_scanner_upgrade_panel() -> void:
	if _ids_scanner == null or _tower_upgrade_hud == null:
		return

	var level := _ids_scanner.get_level()
	var max_level := _ids_scanner.get_max_level()
	var scan_radius := _ids_scanner.get_scan_radius()
	var upgrade_cost := _ids_scanner.get_upgrade_cost()
	var can_afford_next_level := _can_afford_upgrade(upgrade_cost)
	var can_change_mode := _ids_scanner_can_change_mode_now()
	_tower_upgrade_hud.set_scanner_stats(
		level,
		max_level,
		scan_radius,
		_ids_scanner.can_upgrade() and can_afford_next_level,
		upgrade_cost,
		_ids_scanner.get_current_mode_id(),
		_ids_scanner.get_unlocked_mode_ids(),
		can_change_mode
	)


func _sync_edr_upgrade_panel() -> void:
	if _edr_hunter == null or _tower_upgrade_hud == null:
		return
	if not _tower_upgrade_hud.is_edr_panel_visible():
		return

	var level := _edr_hunter.get_level()
	var max_level := _edr_hunter.get_max_level()
	var power := _edr_hunter.get_shot_power()
	var range := _edr_hunter.get_attack_range()
	var cooldown := _edr_hunter.get_shot_cooldown()
	var upgrade_cost := _edr_hunter.get_upgrade_cost()
	var can_afford_next_level := _can_afford_upgrade(upgrade_cost)
	_tower_upgrade_hud.set_edr_stats(
		level,
		max_level,
		power,
		range,
		cooldown,
		_edr_hunter.can_upgrade() and can_afford_next_level,
		upgrade_cost
	)


func _sync_siem_upgrade_panel() -> void:
	if _siem_hawk == null or _tower_upgrade_hud == null:
		return
	if not _tower_upgrade_hud.is_siem_panel_visible():
		return

	var level := _siem_hawk.get_level()
	var max_level := _siem_hawk.get_max_level()
	var power := _siem_hawk.get_shot_power()
	var range := _siem_hawk.get_attack_range()
	var cooldown := _siem_hawk.get_shot_cooldown()
	var upgrade_cost := _siem_hawk.get_upgrade_cost()
	var can_afford_next_level := _can_afford_upgrade(upgrade_cost)
	_tower_upgrade_hud.set_siem_stats(
		level,
		max_level,
		power,
		range,
		cooldown,
		_siem_hawk.can_upgrade() and can_afford_next_level,
		upgrade_cost
	)
	_tower_upgrade_hud.set_siem_dispatch_state(
		_siem_hawk.is_dispatched(),
		_siem_hawk.get_banked_knowledge_points(),
		_siem_hawk.is_landing_to_headquarters(),
		_siem_hawk.can_land_to_headquarters()
	)


func _sync_ips_upgrade_panel() -> void:
	if _ips_intrusion == null or _tower_upgrade_hud == null:
		return
	if not _tower_upgrade_hud.is_ips_panel_visible():
		return

	var level := _ips_intrusion.get_level()
	var max_level := _ips_intrusion.get_max_level()
	var damage := _ips_intrusion.get_shot_power()
	var range := _ips_intrusion.get_attack_range()
	var max_spikes := _ips_intrusion.get_max_spikes()
	var cooldown := _ips_intrusion.get_shot_cooldown()
	var upgrade_cost := _ips_intrusion.get_upgrade_cost()
	var can_afford_next_level := _can_afford_upgrade(upgrade_cost)
	_tower_upgrade_hud.set_ips_stats(
		level,
		max_level,
		damage,
		range,
		max_spikes,
		cooldown,
		_ips_intrusion.can_upgrade() and can_afford_next_level,
		upgrade_cost
	)


func _sync_honeypot_upgrade_panel() -> void:
	if _honeypot_production == null or _tower_upgrade_hud == null:
		return
	if not _tower_upgrade_hud.is_honeypot_panel_visible():
		return

	var level := _honeypot_production.get_level()
	var max_level := _honeypot_production.get_max_level()
	var pot_amount := _honeypot_production.get_production_pot()
	var pot_capacity := _honeypot_production.get_pot_capacity()
	var rate := _honeypot_production.get_production_rate()
	var range := _honeypot_production.get_attack_range()
	var status := _honeypot_production.get_status_text()
	var upgrade_cost := _honeypot_production.get_upgrade_cost()
	var can_afford_next_level := _can_afford_upgrade(upgrade_cost)
	_tower_upgrade_hud.set_honeypot_stats(
		level,
		max_level,
		pot_amount,
		pot_capacity,
		rate,
		range,
		status,
		_honeypot_production.can_upgrade() and can_afford_next_level,
		upgrade_cost
	)


func _ids_scanner_can_change_mode_now() -> bool:
	if _ids_scanner == null:
		return false

	return _ids_scanner.refresh_mode_lock(_active_viruses)


func _start_next_wave() -> void:
	if _is_act_input_locked():
		return

	if _wave_in_progress or _wave_question_pending:
		return
	if _current_wave >= WAVE_MAX_COUNT:
		_update_wave_button()
		_update_wave_label()
		return
	if _should_play_wave_five_cutscene():
		_play_wave_five_cutscene_then_start_wave()
		return

	_current_wave += 1
	_wave_in_progress = true
	_wave_spawns_remaining = WAVE_BASE_VIRUS_COUNT + ((_current_wave - 1) * WAVE_VIRUS_COUNT_STEP)
	_wave_spawn_cooldown_remaining = 0.0
	_update_wave_button()
	_update_wave_label()
	current_wave_changed.emit(_current_wave)
	wave_started.emit(_current_wave)
	if _current_wave == WAVE_FIVE_CUTSCENE_WAVE:
		_spawn_cloaked_trojan_horse()


func _should_play_wave_five_cutscene() -> bool:
	return not _wave_five_cutscene_played \
		and not _wave_five_cutscene_running \
		and _current_wave + 1 == WAVE_FIVE_CUTSCENE_WAVE \
		and _text_cutscene_hud != null \
		and _text_cutscene_hud.has_method("start_wave5_cutscene")


func _play_wave_five_cutscene_then_start_wave() -> void:
	_wave_five_cutscene_running = true
	_wave_five_cutscene_played = true
	_update_wave_button()
	_text_cutscene_hud.call("start_wave5_cutscene")
	if _text_cutscene_hud.has_signal("cutscene_finished"):
		await _text_cutscene_hud.cutscene_finished
	_wave_five_cutscene_running = false
	_update_wave_button()
	if _is_act_input_locked():
		return

	_start_next_wave()


func get_current_wave() -> int:
	return _current_wave


func set_current_wave_for_demo(wave_number: int) -> void:
	_current_wave = clampi(wave_number, 0, WAVE_MAX_COUNT)
	_wave_in_progress = false
	_wave_question_pending = false
	_wave_spawns_remaining = 0
	_wave_spawn_cooldown_remaining = 0.0
	_wave_five_cutscene_running = false
	_wave_five_cutscene_played = _current_wave >= WAVE_FIVE_CUTSCENE_WAVE
	_update_wave_button()
	_update_wave_label()
	current_wave_changed.emit(_current_wave)


func _update_wave_spawner(delta: float) -> void:
	if not _wave_in_progress:
		return

	if _wave_spawns_remaining > 0:
		_wave_spawn_cooldown_remaining -= delta
		if _wave_spawn_cooldown_remaining <= 0.0:
			_spawn_virus()
			_wave_spawns_remaining -= 1
			_wave_spawn_cooldown_remaining = WAVE_SPAWN_INTERVAL

	if _wave_spawns_remaining <= 0 and _active_viruses.is_empty():
		_wave_in_progress = false
		_show_wave_question()
		_update_wave_button()
		_update_wave_label()


func _update_wave_button() -> void:
	if _game_controls_hud == null:
		return

	if _wave_question_pending:
		_game_controls_hud.set_wave_button("Answer Question", true)
		_set_spawn_buttons_disabled(not demo_spawn_buttons_ignore_question_lock)
		return

	if _wave_five_cutscene_running:
		_game_controls_hud.set_wave_button("Wave 5 Intel", true)
		_set_spawn_buttons_disabled(false)
		return

	if _wave_in_progress:
		_game_controls_hud.set_wave_button("Wave %d Running" % _current_wave, true)
		_set_spawn_buttons_disabled(false)
		return

	if _current_wave >= WAVE_MAX_COUNT:
		_game_controls_hud.set_wave_button("Waves Complete", true)
		_set_spawn_buttons_disabled(false)
		return

	_game_controls_hud.set_wave_button("Start Wave %d" % (_current_wave + 1), false)
	_set_spawn_buttons_disabled(false)


func _update_wave_label() -> void:
	if _wave_label == null:
		return

	_wave_label.text = "Wave %d/%d" % [clampi(_current_wave, 0, WAVE_MAX_COUNT), WAVE_MAX_COUNT]


func _set_spawn_buttons_disabled(disabled: bool) -> void:
	if _game_controls_hud != null:
		_game_controls_hud.set_spawn_buttons_disabled(disabled)


func _show_wave_question() -> void:
	if _question_hud == null:
		return

	_wave_question_pending = true
	_question_hud.show_wave_question(_current_wave)


func _on_wave_question_solved(_reward: int) -> void:
	_wave_question_pending = false
	_update_wave_button()
	_update_wave_label()
	_sync_laser_upgrade_panel()
	_sync_scanner_upgrade_panel()
	_sync_edr_upgrade_panel()
	_sync_siem_upgrade_panel()


func _exit_game() -> void:
	get_tree().quit()


func _try_spawn_virus_from_press(pointer_position: Vector2) -> bool:
	if _virus_templates.is_empty():
		return false

	for template in _virus_templates:
		if not is_instance_valid(template):
			continue
		if not template.contains_global_point(pointer_position):
			continue

		_spawn_virus(-1.0, true, template)
		return true

	return false


func _spawn_virus(start_progress: float = -1.0, update_count: bool = true, template: RedVirusScript = null) -> void:
	if _virus_path == null or _virus_path.curve == null:
		push_warning("Cannot spawn virus because VirusElements/Path2D is missing a curve.")
		return
	var spawn_template: RedVirusScript = template
	if spawn_template == null:
		spawn_template = _virus_template

	if spawn_template == null and virus_scene == null:
		push_warning("Cannot spawn virus because no virus template or virus scene was found.")
		return

	var virus := _create_virus_instance(spawn_template)
	if virus == null:
		push_warning("Cannot spawn virus because the configured virus scene is invalid.")
		return

	var spawn_scale := _get_spawn_scale(spawn_template, virus)
	var follow := PathFollow2D.new()
	follow.name = "SpawnedVirusFollow"
	follow.loop = false
	follow.progress = _get_virus_spawn_progress() if start_progress < 0.0 else start_progress
	_virus_path.add_child(follow)

	virus.name = "SpawnedVirus"
	virus.position = Vector2.ZERO
	follow.add_child(virus)
	virus.global_scale = spawn_scale
	virus.reset_for_spawn()

	_active_viruses.append(follow)
	if update_count:
		_update_virus_count_label()


func _spawn_cloaked_trojan_horse() -> void:
	if _virus_path == null or _virus_path.curve == null:
		push_warning("Cannot spawn Trojan horse because VirusElements/Path2D is missing a curve.")
		return

	var trojan := TrojanHorseScene.instantiate() as TrojanHorse
	if trojan == null:
		push_warning("Cannot spawn Trojan horse because the configured scene is invalid.")
		return

	var follow := PathFollow2D.new()
	follow.name = "SpawnedTrojanHorseFollow"
	follow.loop = false
	follow.progress = _get_virus_spawn_progress()
	_virus_path.add_child(follow)

	trojan.name = "SpawnedTrojanHorse"
	trojan.position = Vector2.ZERO
	follow.add_child(trojan)
	trojan.global_scale = DEFAULT_TROJAN_HORSE_SPAWN_SCALE
	trojan.reset_for_spawn()
	trojan.spawn_as_cloaked()

	_active_viruses.append(follow)
	_update_virus_count_label()


func _create_virus_instance(template: RedVirusScript = null) -> RedVirusScript:
	if template != null and not template.scene_file_path.is_empty():
		var template_scene := load(template.scene_file_path) as PackedScene
		if template_scene != null:
			var template_instance := template_scene.instantiate() as RedVirusScript
			if template_instance != null:
				return template_instance

	if template == _virus_template and virus_scene != null:
		var scene_instance := virus_scene.instantiate() as RedVirusScript
		if scene_instance != null:
			return scene_instance

	if template != null:
		return template.duplicate() as RedVirusScript

	return null


func _get_spawn_scale(template: RedVirusScript, virus: RedVirusScript) -> Vector2:
	if template != null:
		return template.global_scale
	if virus is TrojanHorse:
		return DEFAULT_TROJAN_HORSE_SPAWN_SCALE

	return DEFAULT_VIRUS_SPAWN_SCALE


func spawn_virus_batch(count: int) -> void:
	if _is_act_input_locked():
		return

	if count <= 0:
		return
	if _virus_path == null or _virus_path.curve == null:
		push_warning("Cannot spawn virus batch because VirusElements/Path2D is missing a curve.")
		return

	var spawn_progress := _get_virus_spawn_progress()
	var path_length := _virus_path.curve.get_baked_length()
	var available_path_distance := maxf(0.0, path_length - spawn_progress)
	var rightmost_offset := minf(float(count - 1) * VIRUS_BATCH_SPACING, available_path_distance)
	var rightmost_progress := spawn_progress + rightmost_offset
	for index in range(count):
		var progress := maxf(spawn_progress, rightmost_progress - float(index) * VIRUS_BATCH_SPACING)
		_spawn_virus(progress, false)

	_update_virus_count_label()


func _update_active_viruses(delta: float) -> void:
	if _virus_path == null or _virus_path.curve == null:
		return

	var path_length := _virus_path.curve.get_baked_length()
	if path_length <= 0.0:
		return

	var count_changed := false
	for index in range(_active_viruses.size() - 1, -1, -1):
		var follow := _active_viruses[index]
		if not is_instance_valid(follow):
			_active_viruses.remove_at(index)
			count_changed = true
			continue

		follow.progress += _get_virus_speed(follow) * delta
		if follow.progress >= path_length:
			_despawn_virus(follow, false)
			count_changed = true

	if count_changed:
		_update_virus_count_label()


func _update_tower_attack(delta: float) -> void:
	if _guardian == null:
		return

	var target := _guardian.update_attack(delta, _active_viruses)
	if target == null:
		return

	_shoot_virus(target)


func _update_laser_turret_attack(delta: float) -> void:
	if _laser_turret == null:
		return

	var targets := _laser_turret.update_attack(delta, _active_viruses)
	if targets.is_empty():
		return

	_shoot_laser_turret_targets(targets)


func _update_siem_hawk_knowledge(delta: float) -> void:
	if _siem_hawk == null:
		return

	var mouse_world_position := _screen_to_canvas_position(get_viewport().get_mouse_position())
	_siem_hawk.update_knowledge_scan(delta, mouse_world_position, _active_viruses)


func _update_ips_intrusion_spikes(delta: float) -> void:
	if _ips_intrusion == null:
		return

	_ips_intrusion.update_spike_factory(delta, _active_viruses)


func _update_edr_hunter_attack(delta: float) -> void:
	if _edr_hunter == null:
		return

	var target := _edr_hunter.update_attack(delta, _active_viruses)
	if target == null:
		return

	_shoot_edr_hunter_target(target)


func _update_siem_hawk_attack(delta: float) -> void:
	if _siem_hawk == null:
		return

	var target := _siem_hawk.update_attack(delta, _active_viruses)
	if target == null:
		return

	_shoot_siem_hawk_target(target)


func _update_support_tower_scans(delta: float) -> void:
	for node in get_tree().get_nodes_in_group("SUPPORT_TOWER"):
		if not is_instance_valid(node) or not is_ancestor_of(node):
			continue
		if not node.has_method("update_support_scan"):
			continue

		node.call("update_support_scan", _active_viruses, delta)


func _shoot_virus(target: PathFollow2D) -> void:
	if not is_instance_valid(target):
		return

	var target_position := _get_target_center(target)
	_guardian.aim_at(target_position)
	_guardian.play_shoot()
	_spawn_colored_laser(_guardian.global_position, target_position, Color(0.1, 0.55, 1.0, 1.0), _guardian.get_laser_width())
	var destroyed := _damage_virus(target, _guardian.get_shot_power())
	if destroyed and _utility_overlay_hud != null:
		_utility_overlay_hud.show_guardian_destroy_popup(
			_world_to_screen_position(_guardian.global_position),
			_guardian.get_shot_power(),
			_guardian.get_shot_cooldown()
		)
		if _question_hud != null:
			_question_hud.add_cyberbucks(GUARDIAN_CYBERBUCK_REWARD)
			_sync_laser_upgrade_panel()
			_sync_scanner_upgrade_panel()
			_sync_edr_upgrade_panel()
			_sync_siem_upgrade_panel()


func _shoot_edr_hunter_target(target: PathFollow2D) -> void:
	if _edr_hunter == null or not is_instance_valid(target):
		return

	var target_position := _get_target_center(target)
	_edr_hunter.aim_at(target_position)
	_edr_hunter.play_shoot()
	_spawn_colored_laser(_edr_hunter.global_position, target_position, Color(0.12, 0.95, 1.0, 1.0), _edr_hunter.get_laser_width())
	_damage_virus(target, _edr_hunter.get_shot_power())


func _shoot_siem_hawk_target(target: PathFollow2D) -> void:
	if _siem_hawk == null or not is_instance_valid(target):
		return

	var target_position := _get_target_center(target)
	_siem_hawk.aim_at(target_position)
	_siem_hawk.play_shoot()
	_spawn_colored_laser(_siem_hawk.global_position, target_position, Color(0.2, 0.74, 1.0, 1.0), _siem_hawk.get_laser_width())
	_damage_virus(target, _siem_hawk.get_shot_power())


func _shoot_laser_turret_targets(targets: Array[PathFollow2D]) -> void:
	if _laser_turret == null:
		return

	var origin_position := _laser_turret.global_position
	var laser_width := _laser_turret.get_laser_width()
	var laser_color := _laser_turret.get_laser_color()
	var destroyed_count := 0
	for target in targets:
		if not is_instance_valid(target):
			continue

		var target_position := _get_target_center(target)
		_laser_turret.aim_at(target_position)
		if _should_use_demo_laser_turret_beam_fx():
			if not _laser_turret.spawn_beam_fx(target_position, self):
				_spawn_colored_laser(origin_position, target_position, laser_color, laser_width)
		else:
			_spawn_colored_laser(origin_position, target_position, laser_color, laser_width)
		if _damage_virus(target, _laser_turret.get_shot_power(), false):
			destroyed_count += 1

	if destroyed_count > 0:
		if _utility_overlay_hud != null:
			var reward := destroyed_count * LASER_TURRET_CYBERBUCK_REWARD
			_utility_overlay_hud.show_tower_destroy_popup(
				_world_to_screen_position(_laser_turret.global_position),
				reward,
				_laser_turret.get_shot_power(),
				_laser_turret.get_shot_cooldown()
			)
			if _question_hud != null:
				_question_hud.add_cyberbucks(reward)
				_sync_laser_upgrade_panel()
				_sync_scanner_upgrade_panel()
				_sync_edr_upgrade_panel()
				_sync_siem_upgrade_panel()
		_laser_turret.mark_shot_fired()
		_update_virus_count_label()


func _should_use_demo_laser_turret_beam_fx() -> bool:
	return _utility_overlay_hud != null \
		and _laser_turret != null \
		and _laser_turret.has_beam_fx()


func _spawn_colored_laser(start_position: Vector2, end_position: Vector2, color: Color, width: float) -> void:
	var glow := Line2D.new()
	glow.name = "TowerLaserGlow"
	glow.width = width * 2.25
	glow.default_color = Color(color.r, color.g, color.b, 0.35)
	glow.z_index = 99
	glow.points = PackedVector2Array([
		to_local(start_position),
		to_local(end_position)
	])
	add_child(glow)

	var laser := Line2D.new()
	laser.name = "TowerLaser"
	laser.width = width
	laser.default_color = color
	laser.z_index = 100
	laser.points = PackedVector2Array([
		to_local(start_position),
		to_local(end_position)
	])
	add_child(laser)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(glow, "modulate", Color(1, 1, 1, 0), LASER_DURATION)
	tween.tween_property(laser, "modulate", Color(1, 1, 1, 0), LASER_DURATION)
	tween.set_parallel(false)
	tween.tween_callback(Callable(glow, "queue_free"))
	tween.tween_callback(Callable(laser, "queue_free"))


func _damage_virus(follow: PathFollow2D, amount: int, update_count: bool = true) -> bool:
	if not is_instance_valid(follow):
		return false

	var virus := _get_red_virus(follow)
	if virus == null:
		_despawn_virus(follow, update_count)
		return true

	if not virus.take_damage(amount):
		return false

	_begin_virus_destroy(follow, update_count)
	return true


func _begin_virus_destroy(follow: PathFollow2D, update_count: bool = true) -> void:
	if not is_instance_valid(follow):
		return

	var virus := _get_red_virus(follow)
	var keep_active := virus != null and virus.should_remain_active_during_destroy()
	if not keep_active:
		var index := _active_viruses.find(follow)
		if index != -1:
			_active_viruses.remove_at(index)

	if virus != null:
		virus.play_destroy_and_queue_owner(follow)
	else:
		follow.queue_free()

	if update_count and not keep_active:
		_update_virus_count_label()


func _despawn_virus(follow: PathFollow2D, update_count: bool = true) -> void:
	var index := _active_viruses.find(follow)
	if index != -1:
		_active_viruses.remove_at(index)

	if is_instance_valid(follow):
		var virus := _get_red_virus(follow)
		if virus != null and not virus.is_destroying():
			virus.play_destroy_and_queue_owner(follow)
		else:
			follow.queue_free()

	if update_count:
		_update_virus_count_label()


func _get_red_virus(follow: PathFollow2D) -> RedVirusScript:
	for child in follow.get_children():
		var virus := child as RedVirusScript
		if virus != null:
			return virus

	return null


func _get_target_center(follow: PathFollow2D) -> Vector2:
	var virus := _get_red_virus(follow)
	if virus != null:
		return virus.global_position

	return follow.global_position


func _get_virus_speed(follow: PathFollow2D) -> float:
	var virus := _get_red_virus(follow)
	if virus != null:
		return virus.get_path_speed()
	if _virus_template != null:
		return _virus_template.get_path_speed()

	return 0.0


func _update_virus_count_label() -> void:
	if _performance_hud == null:
		return

	_performance_hud.set_virus_count(_active_viruses.size())


func _get_virus_spawn_progress() -> float:
	if _virus_path == null or _virus_path.curve == null or _virus_spawn == null:
		return 0.0

	var spawn_position := _virus_path.to_local(_virus_spawn.global_position)
	return _virus_path.curve.get_closest_offset(spawn_position)


func _create_path_guide() -> void:
	if _virus_path == null or _virus_path.curve == null:
		return

	var old_dot_container := _virus_path.get_node_or_null(^"RuntimePathDots") as Node2D
	if old_dot_container != null:
		old_dot_container.queue_free()

	_path_guide_container = _virus_path.get_node_or_null(^"RuntimePathGuide") as Node2D
	if _path_guide_container == null:
		_path_guide_container = Node2D.new()
		_path_guide_container.name = "RuntimePathGuide"
		_virus_path.add_child(_path_guide_container)

	for child in _path_guide_container.get_children():
		child.queue_free()

	if not show_path_guide:
		return

	var path_length := _virus_path.curve.get_baked_length()
	if path_length <= 0.0:
		return

	var path_line := Line2D.new()
	path_line.name = "PathGuideLine"
	path_line.width = path_guide_width
	path_line.default_color = path_guide_color
	path_line.joint_mode = Line2D.LINE_JOINT_ROUND
	path_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	path_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	path_line.antialiased = true
	path_line.z_index = 40
	path_line.points = _build_path_guide_points(path_length)
	_path_guide_container.add_child(path_line)

	var arrow_distance := minf(path_guide_arrow_spacing * 0.5, path_length * 0.5)
	while arrow_distance < path_length:
		_add_path_guide_arrow(arrow_distance, path_length)
		arrow_distance += path_guide_arrow_spacing


func _build_path_guide_points(path_length: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var distance := 0.0
	while distance < path_length:
		points.append(_virus_path.curve.sample_baked(distance))
		distance += path_guide_sample_spacing

	points.append(_virus_path.curve.sample_baked(path_length))
	return points


func _add_path_guide_arrow(distance: float, path_length: float) -> void:
	var center := _virus_path.curve.sample_baked(distance)
	var before := _virus_path.curve.sample_baked(maxf(0.0, distance - 6.0))
	var after := _virus_path.curve.sample_baked(minf(path_length, distance + 6.0))
	var direction := (after - before).normalized()
	if direction == Vector2.ZERO:
		return

	var half_size := path_guide_arrow_size * 0.5
	var side := Vector2(-direction.y, direction.x)
	var arrow := Polygon2D.new()
	arrow.name = "PathGuideArrow"
	arrow.position = center
	arrow.polygon = PackedVector2Array([
		direction * half_size,
		-direction * half_size + side * half_size * 0.75,
		-direction * half_size - side * half_size * 0.75
	])
	arrow.color = path_guide_color
	arrow.z_index = 41
	_path_guide_container.add_child(arrow)


func _screen_to_canvas_position(screen_position: Vector2) -> Vector2:
	return get_canvas_transform().affine_inverse() * screen_position


func _world_to_screen_position(world_position: Vector2) -> Vector2:
	return get_canvas_transform() * world_position


func _is_act_input_locked() -> bool:
	return _text_cutscene_hud != null \
		and _text_cutscene_hud.has_method("is_cutscene_running") \
		and bool(_text_cutscene_hud.call("is_cutscene_running"))


func _demo_upgrade_button_has_point(screen_position: Vector2) -> bool:
	return _utility_overlay_hud != null \
		and _utility_overlay_hud.upgrade_button_has_point(screen_position)


func _demo_guardian_upgrade_button_has_point(screen_position: Vector2) -> bool:
	return _utility_overlay_hud != null \
		and _utility_overlay_hud.guardian_upgrade_button_has_point(screen_position)


func _demo_laser_upgrade_button_has_point(screen_position: Vector2) -> bool:
	return _utility_overlay_hud != null \
		and _utility_overlay_hud.laser_upgrade_button_has_point(screen_position)


func _demo_scanner_upgrade_button_has_point(screen_position: Vector2) -> bool:
	return _utility_overlay_hud != null \
		and _utility_overlay_hud.scanner_upgrade_button_has_point(screen_position)


func _demo_edr_upgrade_button_has_point(screen_position: Vector2) -> bool:
	return _utility_overlay_hud != null \
		and _utility_overlay_hud.edr_upgrade_button_has_point(screen_position)


func _demo_siem_upgrade_button_has_point(screen_position: Vector2) -> bool:
	return _utility_overlay_hud != null \
		and _utility_overlay_hud.siem_upgrade_button_has_point(screen_position)


func _demo_ips_upgrade_button_has_point(screen_position: Vector2) -> bool:
	return _utility_overlay_hud != null \
		and _utility_overlay_hud.ips_upgrade_button_has_point(screen_position)


func _demo_honeypot_upgrade_button_has_point(screen_position: Vector2) -> bool:
	return _utility_overlay_hud != null \
		and _utility_overlay_hud.honeypot_upgrade_button_has_point(screen_position)


func _is_demo_guardian_upgrade_hovered() -> bool:
	if _guardian == null or not _guardian.is_placed():
		return false

	var mouse_screen_position := get_viewport().get_mouse_position()
	var mouse_world_position := _screen_to_canvas_position(mouse_screen_position)
	return _guardian.contains_global_point(mouse_world_position) \
		or _demo_guardian_upgrade_button_has_point(mouse_screen_position)


func _is_demo_laser_upgrade_hovered() -> bool:
	if _laser_turret == null or not _laser_turret.is_placed():
		return false

	var mouse_screen_position := get_viewport().get_mouse_position()
	var mouse_world_position := _screen_to_canvas_position(mouse_screen_position)
	return _laser_turret.contains_global_point(mouse_world_position) \
		or _demo_laser_upgrade_button_has_point(mouse_screen_position)


func _is_demo_scanner_upgrade_hovered() -> bool:
	if _ids_scanner == null or not _ids_scanner.is_deployed():
		return false

	var mouse_screen_position := get_viewport().get_mouse_position()
	var mouse_world_position := _screen_to_canvas_position(mouse_screen_position)
	return _ids_scanner.contains_global_point(mouse_world_position) \
		or _demo_scanner_upgrade_button_has_point(mouse_screen_position)


func _is_demo_edr_upgrade_hovered() -> bool:
	if _edr_hunter == null or not _edr_hunter.is_placed():
		return false

	var mouse_screen_position := get_viewport().get_mouse_position()
	var mouse_world_position := _screen_to_canvas_position(mouse_screen_position)
	return _edr_hunter.contains_global_point(mouse_world_position) \
		or _demo_edr_upgrade_button_has_point(mouse_screen_position)


func _is_demo_siem_upgrade_hovered() -> bool:
	if _siem_hawk == null or not _siem_hawk.is_placed():
		return false

	var mouse_screen_position := get_viewport().get_mouse_position()
	var mouse_world_position := _screen_to_canvas_position(mouse_screen_position)
	return _siem_hawk.contains_global_point(mouse_world_position) \
		or _demo_siem_upgrade_button_has_point(mouse_screen_position)


func _is_demo_ips_upgrade_hovered() -> bool:
	if _ips_intrusion == null or not _ips_intrusion.is_placed():
		return false

	var mouse_screen_position := get_viewport().get_mouse_position()
	var mouse_world_position := _screen_to_canvas_position(mouse_screen_position)
	return _ips_intrusion.contains_global_point(mouse_world_position) \
		or _demo_ips_upgrade_button_has_point(mouse_screen_position)


func _is_demo_honeypot_upgrade_hovered() -> bool:
	if _honeypot_production == null or not _honeypot_production.is_placed():
		return false

	var mouse_screen_position := get_viewport().get_mouse_position()
	var mouse_world_position := _screen_to_canvas_position(mouse_screen_position)
	return _honeypot_production.contains_global_point(mouse_world_position) \
		or _demo_honeypot_upgrade_button_has_point(mouse_screen_position)


func _show_upgrade_panel() -> void:
	if _tower_upgrade_hud == null:
		return

	_set_tower_menu_radius_previews(true, false, false, false, false)
	_tower_upgrade_hud.show_guardian_panel()


func _hide_upgrade_panel() -> void:
	if _tower_upgrade_hud == null:
		return

	_tower_upgrade_hud.hide_guardian_panel()
	if not _tower_upgrade_hud.is_guardian_panel_visible():
		_set_tower_menu_radius_previews(false, _tower_upgrade_hud.is_laser_panel_visible(), _tower_upgrade_hud.is_scanner_panel_visible(), _tower_upgrade_hud.is_edr_panel_visible(), _tower_upgrade_hud.is_siem_panel_visible())


func _show_laser_upgrade_panel() -> void:
	if _tower_upgrade_hud == null or _laser_turret == null:
		return

	_sync_laser_upgrade_panel()
	_set_tower_menu_radius_previews(false, true, false, false, false)
	_tower_upgrade_hud.show_laser_panel()


func _hide_laser_upgrade_panel() -> void:
	if _tower_upgrade_hud == null:
		return

	_tower_upgrade_hud.hide_laser_panel()
	if not _tower_upgrade_hud.is_laser_panel_visible():
		_set_tower_menu_radius_previews(_tower_upgrade_hud.is_guardian_panel_visible(), false, _tower_upgrade_hud.is_scanner_panel_visible(), _tower_upgrade_hud.is_edr_panel_visible(), _tower_upgrade_hud.is_siem_panel_visible())


func _show_scanner_upgrade_panel() -> void:
	if _tower_upgrade_hud == null or _ids_scanner == null:
		return

	_sync_scanner_upgrade_panel()
	_set_tower_menu_radius_previews(false, false, true, false, false)
	_tower_upgrade_hud.show_scanner_panel()


func _hide_scanner_upgrade_panel() -> void:
	if _tower_upgrade_hud == null:
		return

	_tower_upgrade_hud.hide_scanner_panel()
	if not _tower_upgrade_hud.is_scanner_panel_visible():
		_set_tower_menu_radius_previews(_tower_upgrade_hud.is_guardian_panel_visible(), _tower_upgrade_hud.is_laser_panel_visible(), false, _tower_upgrade_hud.is_edr_panel_visible(), _tower_upgrade_hud.is_siem_panel_visible())


func _show_edr_upgrade_panel() -> void:
	if _tower_upgrade_hud == null or _edr_hunter == null:
		return

	_set_tower_menu_radius_previews(false, false, false, true, false)
	_tower_upgrade_hud.show_edr_panel()
	_sync_edr_upgrade_panel()


func _hide_edr_upgrade_panel() -> void:
	if _tower_upgrade_hud == null:
		return

	_tower_upgrade_hud.hide_edr_panel()
	if not _tower_upgrade_hud.is_edr_panel_visible():
		_set_tower_menu_radius_previews(_tower_upgrade_hud.is_guardian_panel_visible(), _tower_upgrade_hud.is_laser_panel_visible(), _tower_upgrade_hud.is_scanner_panel_visible(), false, _tower_upgrade_hud.is_siem_panel_visible())


func _show_siem_upgrade_panel() -> void:
	if _tower_upgrade_hud == null or _siem_hawk == null:
		return

	_set_tower_menu_radius_previews(false, false, false, false, true)
	_tower_upgrade_hud.show_siem_panel()
	_sync_siem_upgrade_panel()


func _hide_siem_upgrade_panel() -> void:
	if _tower_upgrade_hud == null:
		return

	_tower_upgrade_hud.hide_siem_panel()
	if not _tower_upgrade_hud.is_siem_panel_visible():
		_set_tower_menu_radius_previews(_tower_upgrade_hud.is_guardian_panel_visible(), _tower_upgrade_hud.is_laser_panel_visible(), _tower_upgrade_hud.is_scanner_panel_visible(), _tower_upgrade_hud.is_edr_panel_visible(), false)


func _show_ips_upgrade_panel() -> void:
	if _tower_upgrade_hud == null or _ips_intrusion == null:
		return

	_set_tower_menu_radius_previews(false, false, false, false, false, true, false)
	_tower_upgrade_hud.show_ips_panel()
	_sync_ips_upgrade_panel()


func _hide_ips_upgrade_panel() -> void:
	if _tower_upgrade_hud == null:
		return

	_tower_upgrade_hud.hide_ips_panel()
	if not _tower_upgrade_hud.is_ips_panel_visible():
		_set_tower_menu_radius_previews(
			_tower_upgrade_hud.is_guardian_panel_visible(),
			_tower_upgrade_hud.is_laser_panel_visible(),
			_tower_upgrade_hud.is_scanner_panel_visible(),
			_tower_upgrade_hud.is_edr_panel_visible(),
			_tower_upgrade_hud.is_siem_panel_visible(),
			false,
			_tower_upgrade_hud.is_honeypot_panel_visible()
		)


func _show_honeypot_upgrade_panel() -> void:
	if _tower_upgrade_hud == null or _honeypot_production == null:
		return

	_set_tower_menu_radius_previews(false, false, false, false, false, false, true)
	_tower_upgrade_hud.show_honeypot_panel()
	_sync_honeypot_upgrade_panel()


func _hide_honeypot_upgrade_panel() -> void:
	if _tower_upgrade_hud == null:
		return

	_tower_upgrade_hud.hide_honeypot_panel()
	if not _tower_upgrade_hud.is_honeypot_panel_visible():
		_set_tower_menu_radius_previews(
			_tower_upgrade_hud.is_guardian_panel_visible(),
			_tower_upgrade_hud.is_laser_panel_visible(),
			_tower_upgrade_hud.is_scanner_panel_visible(),
			_tower_upgrade_hud.is_edr_panel_visible(),
			_tower_upgrade_hud.is_siem_panel_visible(),
			_tower_upgrade_hud.is_ips_panel_visible(),
			false
		)


func _set_tower_menu_radius_previews(
	guardian_active: bool,
	laser_active: bool,
	scanner_active: bool,
	edr_active: bool,
	siem_active: bool,
	ips_active := false,
	honeypot_active := false
) -> void:
	if _guardian != null and _guardian.has_method("set_menu_range_preview_active"):
		_guardian.call("set_menu_range_preview_active", guardian_active)
	if _laser_turret != null and _laser_turret.has_method("set_menu_range_preview_active"):
		_laser_turret.call("set_menu_range_preview_active", laser_active)
	if _ids_scanner != null and _ids_scanner.has_method("set_menu_range_preview_active"):
		_ids_scanner.call("set_menu_range_preview_active", scanner_active)
	if _edr_hunter != null and _edr_hunter.has_method("set_menu_range_preview_active"):
		_edr_hunter.call("set_menu_range_preview_active", edr_active)
	if _siem_hawk != null and _siem_hawk.has_method("set_menu_range_preview_active"):
		_siem_hawk.call("set_menu_range_preview_active", siem_active)
	if _ips_intrusion != null and _ips_intrusion.has_method("set_menu_range_preview_active"):
		_ips_intrusion.call("set_menu_range_preview_active", ips_active)
	if _honeypot_production != null and _honeypot_production.has_method("set_menu_range_preview_active"):
		_honeypot_production.call("set_menu_range_preview_active", honeypot_active)
