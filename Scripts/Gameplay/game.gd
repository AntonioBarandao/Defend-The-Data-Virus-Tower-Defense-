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
const AdwareScene := preload("res://Scenes/Enemies/Adware.tscn")
const CyberQuestionHUDScript := preload("res://Scripts/UI/cyber_question_hud.gd")
const PerformanceHUDScript := preload("res://Scripts/UI/performance_hud.gd")
const GameControlsHUDScript := preload("res://Scripts/UI/game_controls_hud.gd")
const TowerUpgradeHUDScript := preload("res://Scripts/UI/tower_upgrade_hud.gd")
const ProgressHUDScript := preload("res://Scripts/UI/progress_hud.gd")
const UtilityOverlayHUDScript := preload("res://Scripts/UI/utility_overlay_hud.gd")
const CyberGuardianScene := preload("res://Scenes/Towers/CyberGuardian.tscn")
const LaserTurretScene := preload("res://Scenes/Towers/LaserTurret.tscn")
const IDSScannerScene := preload("res://Scenes/Towers/IDS_Scanner.tscn")
const EDRHunterScene := preload("res://Scenes/Towers/EDR_Hunter.tscn")
const SIEMHawkScene := preload("res://Scenes/Towers/SIEM_Hawk.tscn")
const IPSIntrusionScene := preload("res://Scenes/Towers/IPS_Intrusion.tscn")
const HoneypotProductionScene := preload("res://Scenes/Towers/Honeypot_Production.tscn")
const TARGET_FPS := 60
const FPS_UPDATE_INTERVAL := 0.25
const VIRUS_BATCH_SPACING := 10.0
const WAVE_BASE_VIRUS_COUNT := 5
const WAVE_VIRUS_COUNT_STEP := 2
const WAVE_SPAWN_INTERVAL := 0.6
const WAVE_MAX_COUNT := 20
const WAVE_FIVE_CUTSCENE_WAVE := 5
const ADWARE_WAVE := 11
const ADWARE_POPUP_COUNT := 20
const ADWARE_VARIATION_COUNT := 10
const ADWARE_POPUP_INTERVAL := 0.5
const LASER_DURATION := 0.24
const GUARDIAN_CYBERBUCK_REWARD := 5
const LASER_TURRET_CYBERBUCK_REWARD := 5
const GUARDIAN_MODE_SIGNAL_BOOST := &"signal_boost"
const DEFAULT_VIRUS_SPAWN_SCALE := Vector2(0.2, 0.2)
const DEFAULT_TROJAN_HORSE_SPAWN_SCALE := Vector2(0.4, 0.4)
const STORE_TOGGLE_SIZE := Vector2(132, 46)
const STORE_PANEL_PADDING := Vector2(28, 28)
const STORE_PANEL_EXTRA_BOTTOM := 34.0
const STORE_PANEL_MIN_WIDTH := 376.0
const STORE_PANEL_SLIDE_DISTANCE := 360.0
const STORE_PANEL_ANIM_SECONDS := 0.22
const STORE_TOWER_ICON_X_OFFSET := 92.0
const STORE_TOWER_LABEL_X_OFFSET := 258.0
const STORE_TOWER_LABEL_SIZE := Vector2(190, 54)
const STORE_TOWER_ROW_GAP := 126.0

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
@export var tower_store_panel_path: NodePath = ^"TestDrag"
@export var tower_store_background_path: NodePath = ^"TestDrag/TowerTrayBackground"
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
var _guardian_store: CyberGuardianTowerScript
var _laser_turret_store: LaserTurretScript
var _ids_scanner_store: IDSScannerTowerScript
var _edr_hunter_store: EDRHunterTowerScript
var _siem_hawk_store: SIEMHawkTowerScript
var _ips_intrusion_store: IPSIntrusionTowerScript
var _honeypot_production_store: HoneypotProductionTowerScript
var _guardians: Array[CyberGuardianTowerScript] = []
var _laser_turrets: Array[LaserTurretScript] = []
var _ids_scanners: Array[IDSScannerTowerScript] = []
var _edr_hunters: Array[EDRHunterTowerScript] = []
var _siem_hawks: Array[SIEMHawkTowerScript] = []
var _ips_intrusions: Array[IPSIntrusionTowerScript] = []
var _honeypot_productions: Array[HoneypotProductionTowerScript] = []
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
var _tower_store_panel: Control
var _tower_store_background: ColorRect
var _tower_store_toggle_button: Button
var _tower_store_canvas: CanvasLayer
var _tower_store_title_label: Label
var _tower_store_hint_label: Label
var _tower_store_item_labels: Dictionary = {}
var _tower_store_home_positions: Dictionary = {}
var _tower_store_base_rect := Rect2()
var _tower_store_open := true
var _tower_store_tween: Tween
var _active_viruses: Array[PathFollow2D] = []
var _current_wave := 0
var _wave_in_progress := false
var _wave_question_pending := false
var _wave_spawns_remaining := 0
var _wave_spawn_cooldown_remaining := 0.0
var _wave_five_cutscene_played := false
var _wave_five_cutscene_running := false
var _adware_spawns_remaining := 0
var _adware_spawn_cooldown_remaining := 0.0
var _adware_spawned_count := 0
var _adware_rng := RandomNumberGenerator.new()
var _adware_variation_deck: Array[int] = []
var _active_adware_popups: Array[Node2D] = []

func _ready() -> void:
	Engine.max_fps = TARGET_FPS
	_adware_rng.randomize()
	_show_canvas_layers_for_runtime()
	_guardian = get_node_or_null(guardian_path) as CyberGuardianTowerScript
	_laser_turret = get_node_or_null(laser_turret_path) as LaserTurretScript
	_ids_scanner = get_node_or_null(ids_scanner_path) as IDSScannerTowerScript
	_edr_hunter = get_node_or_null(edr_hunter_path) as EDRHunterTowerScript
	_siem_hawk = get_node_or_null(siem_hawk_path) as SIEMHawkTowerScript
	_ips_intrusion = get_node_or_null(ips_intrusion_path) as IPSIntrusionTowerScript
	_honeypot_production = get_node_or_null(honeypot_production_path) as HoneypotProductionTowerScript
	_guardian_store = _guardian
	_laser_turret_store = _laser_turret
	_ids_scanner_store = _ids_scanner
	_edr_hunter_store = _edr_hunter
	_siem_hawk_store = _siem_hawk
	_ips_intrusion_store = _ips_intrusion
	_honeypot_production_store = _honeypot_production
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
	_tower_store_panel = get_node_or_null(tower_store_panel_path) as Control
	_tower_store_background = get_node_or_null(tower_store_background_path) as ColorRect
	if _virus_spawn == null:
		_virus_spawn = get_node_or_null(^"VirusElements/Spawn2D") as Node2D

	_setup_tower_store()

	if _guardian_store == null:
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
		_tower_upgrade_hud.guardian_mode_pressed.connect(Callable(self, "_set_guardian_mode"))
		_tower_upgrade_hud.laser_upgrade_pressed.connect(Callable(self, "_upgrade_laser_turret"))
		_tower_upgrade_hud.scanner_upgrade_pressed.connect(Callable(self, "_upgrade_ids_scanner"))
		_tower_upgrade_hud.scanner_mode_pressed.connect(Callable(self, "_set_ids_scanner_mode"))
		_tower_upgrade_hud.edr_upgrade_pressed.connect(Callable(self, "_upgrade_edr_hunter"))
		_tower_upgrade_hud.siem_upgrade_pressed.connect(Callable(self, "_upgrade_siem_hawk"))
		_tower_upgrade_hud.siem_dispatch_pressed.connect(Callable(self, "_toggle_siem_hawk_dispatch"))
		_tower_upgrade_hud.siem_land_pressed.connect(Callable(self, "_land_siem_hawk_to_headquarters"))
		_tower_upgrade_hud.ips_upgrade_pressed.connect(Callable(self, "_upgrade_ips_intrusion"))
		_tower_upgrade_hud.honeypot_upgrade_pressed.connect(Callable(self, "_upgrade_honeypot_production"))
	if _guardian != null:
		_guardian.mode_changed.connect(Callable(self, "_on_guardian_mode_changed"))
	if _siem_hawk != null:
		_siem_hawk.dispatch_mode_changed.connect(Callable(self, "_on_siem_hawk_dispatch_mode_changed"))
		_siem_hawk.knowledge_extracted.connect(Callable(self, "_on_siem_hawk_knowledge_extracted"))
		_siem_hawk.knowledge_bank_changed.connect(Callable(self, "_on_siem_hawk_knowledge_bank_changed"))
	if _ids_scanner != null:
		_ids_scanner.virus_damage_requested.connect(Callable(self, "_on_scanner_virus_damage_requested"))
		_ids_scanner.bounty_awarded.connect(Callable(self, "_on_scanner_bounty_awarded"))
	if _ips_intrusion != null:
		_ips_intrusion.spike_damage_requested.connect(Callable(self, "_on_ips_spike_damage_requested"))
	_connect_store_prototypes()
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
	_apply_guardian_signal_boost_state()
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

			if _find_tower_at_point(_guardians, pointer_position) != null:
				_handle_placed_tower_press(pointer_position, mouse_button.position)
				return

			if _tower_store_open and _ips_intrusion_store != null and not _ips_intrusion_store.is_placed() and _ips_intrusion_store.try_start_drag(pointer_position):
				return

			if _tower_store_open and _honeypot_production_store != null and not _honeypot_production_store.is_placed() and _honeypot_production_store.try_start_drag(pointer_position):
				return

			if _tower_store_open and _edr_hunter_store != null and not _edr_hunter_store.is_placed() and _edr_hunter_store.try_start_drag(pointer_position):
				return

			if _tower_store_open and _siem_hawk_store != null and not _siem_hawk_store.is_placed() and _siem_hawk_store.try_start_drag(pointer_position):
				return

			if _guardian_store == null:
				return

			if _guardian_store.is_placed():
				_handle_placed_tower_press(pointer_position, mouse_button.position)
			elif _tower_store_open:
				_guardian_store.try_start_drag(pointer_position)
		elif _demo_upgrade_button_has_point(mouse_button.position):
			return
		elif _siem_hawk_store != null and _siem_hawk_store.is_dragging():
			_siem_hawk_store.finish_drag()
		elif _honeypot_production_store != null and _honeypot_production_store.is_dragging():
			_honeypot_production_store.finish_drag()
		elif _ips_intrusion_store != null and _ips_intrusion_store.is_dragging():
			_ips_intrusion_store.finish_drag()
		elif _edr_hunter_store != null and _edr_hunter_store.is_dragging():
			_edr_hunter_store.finish_drag()
		elif _guardian_store != null and _guardian_store.is_dragging():
			_guardian_store.finish_drag()
		return

	if _edr_hunter_store != null and not _edr_hunter_store.is_placed() and event is InputEventMouseMotion and _edr_hunter_store.is_dragging():
		var edr_mouse_motion := event as InputEventMouseMotion
		_edr_hunter_store.update_drag(_screen_to_canvas_position(edr_mouse_motion.position))
		return

	if _siem_hawk_store != null and not _siem_hawk_store.is_placed() and event is InputEventMouseMotion and _siem_hawk_store.is_dragging():
		var siem_mouse_motion := event as InputEventMouseMotion
		_siem_hawk_store.update_drag(_screen_to_canvas_position(siem_mouse_motion.position))
		return

	if _ips_intrusion_store != null and not _ips_intrusion_store.is_placed() and event is InputEventMouseMotion and _ips_intrusion_store.is_dragging():
		var ips_mouse_motion := event as InputEventMouseMotion
		_ips_intrusion_store.update_drag(_screen_to_canvas_position(ips_mouse_motion.position))
		return

	if _honeypot_production_store != null and not _honeypot_production_store.is_placed() and event is InputEventMouseMotion and _honeypot_production_store.is_dragging():
		var honeypot_mouse_motion := event as InputEventMouseMotion
		_honeypot_production_store.update_drag(_screen_to_canvas_position(honeypot_mouse_motion.position))
		return

	if _guardian_store != null and not _guardian_store.is_placed() and event is InputEventMouseMotion and _guardian_store.is_dragging():
		var mouse_motion := event as InputEventMouseMotion
		_guardian_store.update_drag(_screen_to_canvas_position(mouse_motion.position))
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

			if _find_tower_at_point(_guardians, pointer_position) != null:
				_handle_placed_tower_press(pointer_position, screen_touch.position)
				return

			if _tower_store_open and _ips_intrusion_store != null and not _ips_intrusion_store.is_placed() and _ips_intrusion_store.try_start_drag(pointer_position):
				return

			if _tower_store_open and _honeypot_production_store != null and not _honeypot_production_store.is_placed() and _honeypot_production_store.try_start_drag(pointer_position):
				return

			if _tower_store_open and _edr_hunter_store != null and not _edr_hunter_store.is_placed() and _edr_hunter_store.try_start_drag(pointer_position):
				return

			if _tower_store_open and _siem_hawk_store != null and not _siem_hawk_store.is_placed() and _siem_hawk_store.try_start_drag(pointer_position):
				return

			if _guardian_store == null:
				return

			if _guardian_store.is_placed():
				_handle_placed_tower_press(pointer_position, screen_touch.position)
			elif _tower_store_open:
				_guardian_store.try_start_drag(pointer_position)
		elif _demo_upgrade_button_has_point(screen_touch.position):
			return
		elif _siem_hawk_store != null and _siem_hawk_store.is_dragging():
			_siem_hawk_store.finish_drag()
		elif _honeypot_production_store != null and _honeypot_production_store.is_dragging():
			_honeypot_production_store.finish_drag()
		elif _ips_intrusion_store != null and _ips_intrusion_store.is_dragging():
			_ips_intrusion_store.finish_drag()
		elif _edr_hunter_store != null and _edr_hunter_store.is_dragging():
			_edr_hunter_store.finish_drag()
		elif _guardian_store != null and _guardian_store.is_dragging():
			_guardian_store.finish_drag()
		return

	if _edr_hunter_store != null and not _edr_hunter_store.is_placed() and event is InputEventScreenDrag and _edr_hunter_store.is_dragging():
		var edr_screen_drag := event as InputEventScreenDrag
		_edr_hunter_store.update_drag(_screen_to_canvas_position(edr_screen_drag.position))
		return

	if _siem_hawk_store != null and not _siem_hawk_store.is_placed() and event is InputEventScreenDrag and _siem_hawk_store.is_dragging():
		var siem_screen_drag := event as InputEventScreenDrag
		_siem_hawk_store.update_drag(_screen_to_canvas_position(siem_screen_drag.position))
		return

	if _ips_intrusion_store != null and not _ips_intrusion_store.is_placed() and event is InputEventScreenDrag and _ips_intrusion_store.is_dragging():
		var ips_screen_drag := event as InputEventScreenDrag
		_ips_intrusion_store.update_drag(_screen_to_canvas_position(ips_screen_drag.position))
		return

	if _honeypot_production_store != null and not _honeypot_production_store.is_placed() and event is InputEventScreenDrag and _honeypot_production_store.is_dragging():
		var honeypot_screen_drag := event as InputEventScreenDrag
		_honeypot_production_store.update_drag(_screen_to_canvas_position(honeypot_screen_drag.position))
		return

	if _guardian_store != null and not _guardian_store.is_placed() and event is InputEventScreenDrag and _guardian_store.is_dragging():
		var screen_drag := event as InputEventScreenDrag
		_guardian_store.update_drag(_screen_to_canvas_position(screen_drag.position))


func _process(delta: float) -> void:
	if _is_act_input_locked():
		if _tower_store_canvas != null:
			_tower_store_canvas.hide()
		_update_fps_timer(delta)
		return

	if _tower_store_canvas != null:
		_tower_store_canvas.show()
	if _tower_store_tween == null:
		_sync_tower_store_items(false)
	_update_wave_spawner(delta)
	_update_adware_spawner(delta)
	_update_active_viruses(delta)
	_update_support_tower_scans(delta)
	_update_siem_hawk_knowledge(delta)
	_update_ips_intrusion_spikes(delta)
	if _tower_upgrade_hud != null and _tower_upgrade_hud.is_guardian_panel_visible():
		_sync_guardian_upgrade_panel()
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


func _setup_tower_store() -> void:
	var store_items := _get_tower_store_items()
	if store_items.is_empty():
		return

	if _tower_store_panel == null:
		_tower_store_panel = Control.new()
		_tower_store_panel.name = "TowerStorePanel"
		add_child(_tower_store_panel)

	_hide_legacy_store_title()
	_layout_tower_store_items(store_items)
	_style_tower_store_panel(store_items)
	_create_tower_store_labels(store_items)
	_create_tower_store_toggle_button()
	_sync_tower_store_items(true)


func _get_tower_store_items() -> Array[Dictionary]:
	var items: Array[Dictionary] = []
	_add_tower_store_item(items, _guardian_store, "Cyber Guardian")
	_add_tower_store_item(items, _laser_turret_store, "Laser Turret")
	_add_tower_store_item(items, _ids_scanner_store, "IDS Scanner")
	_add_tower_store_item(items, _edr_hunter_store, "EDR Hunter")
	_add_tower_store_item(items, _siem_hawk_store, "SIEM Hawk")
	_add_tower_store_item(items, _ips_intrusion_store, "IPS Spike")
	_add_tower_store_item(items, _honeypot_production_store, "Honeypot")
	return items


func _add_tower_store_item(items: Array[Dictionary], tower: Node2D, label_text: String) -> void:
	if tower == null:
		return

	items.append({
		"tower": tower,
		"label": label_text
	})


func _layout_tower_store_items(store_items: Array[Dictionary]) -> void:
	var store_rect := _get_store_panel_global_rect(store_items)
	var icon_x := store_rect.position.x + STORE_TOWER_ICON_X_OFFSET
	var row_top := store_rect.position.y + 144.0
	var row_gap := STORE_TOWER_ROW_GAP

	for index in range(store_items.size()):
		var tower := store_items[index]["tower"] as Node2D
		var home_position := Vector2(icon_x, row_top + row_gap * float(index))
		tower.global_position = home_position
		_set_tower_store_home_position(tower, home_position)
		_tower_store_home_positions[tower] = home_position


func _style_tower_store_panel(store_items: Array[Dictionary]) -> void:
	var store_rect := _get_store_panel_global_rect(store_items)
	_tower_store_base_rect = store_rect
	if _tower_store_background == null:
		_tower_store_background = ColorRect.new()
		_tower_store_background.name = "TowerTrayBackground"
		_tower_store_panel.add_child(_tower_store_background)

	_tower_store_background.global_position = store_rect.position
	_tower_store_background.size = store_rect.size
	_tower_store_background.color = Color(0.012, 0.021, 0.041, 0.86)
	_tower_store_background.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _get_store_panel_global_rect(store_items: Array[Dictionary]) -> Rect2:
	if _tower_store_background != null:
		var existing_rect := _tower_store_background.get_global_rect()
		if existing_rect.size.x > 64.0 and existing_rect.size.y > 64.0:
			var width := maxf(existing_rect.size.x, STORE_PANEL_MIN_WIDTH)
			var height := maxf(existing_rect.size.y, 884.0)
			return Rect2(Vector2(existing_rect.end.x - width, existing_rect.position.y), Vector2(width, height))

	var item_rect := Rect2()
	var found_item := false
	for item in store_items:
		var tower := item["tower"] as Node2D
		if not found_item:
			item_rect = Rect2(tower.global_position, Vector2.ZERO)
			found_item = true
		else:
			item_rect = item_rect.expand(tower.global_position)

	if found_item:
		return item_rect.grow_individual(
			STORE_PANEL_PADDING.x + 80.0,
			STORE_PANEL_PADDING.y + 132.0,
			STORE_PANEL_PADDING.x + 80.0,
			STORE_PANEL_PADDING.y + STORE_PANEL_EXTRA_BOTTOM
		)

	return Rect2(Vector2(1528, 108), Vector2(392, 884))


func _create_tower_store_labels(store_items: Array[Dictionary]) -> void:
	_tower_store_title_label = _make_store_label("TOWER STORE", 28, Color(0.74, 0.93, 1.0, 1.0))
	_tower_store_hint_label = _make_store_label("Drag a tower onto a platform", 18, Color(0.52, 0.68, 0.82, 1.0))
	add_child(_tower_store_title_label)
	add_child(_tower_store_hint_label)

	for item in store_items:
		var tower := item["tower"] as Node2D
		var label := _make_store_label(String(item["label"]), 17, Color(0.86, 0.94, 1.0, 1.0))
		add_child(label)
		_tower_store_item_labels[tower] = label

	_position_tower_store_labels()


func _make_store_label(label_text: String, font_size: int, font_color: Color) -> Label:
	var label := Label.new()
	label.text = label_text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.z_as_relative = false
	label.z_index = 210
	label.add_theme_font_override("font", _get_store_font())
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", font_color)
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.02, 0.05, 0.94))
	label.add_theme_constant_override("outline_size", 3)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label


func _get_store_font() -> Font:
	if _utility_overlay_hud != null:
		var font_value = _utility_overlay_hud.get("naked_power_font")
		if font_value is Font:
			return font_value

	return null


func _position_tower_store_labels(slide_offset := 0.0) -> void:
	if _tower_store_base_rect.size == Vector2.ZERO:
		return

	var store_rect := _tower_store_base_rect
	if _tower_store_title_label != null:
		_position_store_label(_tower_store_title_label, Vector2(store_rect.position.x + store_rect.size.x * 0.5 + slide_offset, store_rect.position.y + 28.0), Vector2(store_rect.size.x - 34.0, 34.0))
	if _tower_store_hint_label != null:
		_position_store_label(_tower_store_hint_label, Vector2(store_rect.position.x + store_rect.size.x * 0.5 + slide_offset, store_rect.position.y + 66.0), Vector2(store_rect.size.x - 34.0, 34.0))

	for tower in _tower_store_item_labels.keys():
		var tower_node := tower as Node2D
		var label := _tower_store_item_labels[tower] as Label
		if tower_node == null or label == null:
			continue

		var label_center := Vector2(store_rect.position.x + STORE_TOWER_LABEL_X_OFFSET + slide_offset, tower_node.global_position.y - STORE_TOWER_LABEL_SIZE.y * 0.5)
		_position_store_label(label, label_center, STORE_TOWER_LABEL_SIZE)


func _position_store_label(label: Label, center_position: Vector2, size: Vector2) -> void:
	label.size = size
	label.global_position = center_position - Vector2(size.x * 0.5, 0)


func _create_tower_store_toggle_button() -> void:
	_tower_store_canvas = CanvasLayer.new()
	_tower_store_canvas.name = "TowerStoreControls"
	_tower_store_canvas.layer = 160
	add_child(_tower_store_canvas)

	_tower_store_toggle_button = Button.new()
	_tower_store_toggle_button.name = "TowerStoreToggleButton"
	_tower_store_toggle_button.custom_minimum_size = STORE_TOGGLE_SIZE
	_tower_store_toggle_button.focus_mode = Control.FOCUS_NONE
	_tower_store_toggle_button.text = "Hide Store"
	_tower_store_toggle_button.tooltip_text = "Show or hide the tower store."
	_tower_store_toggle_button.add_theme_font_override("font", _get_store_font())
	_tower_store_toggle_button.add_theme_font_size_override("font_size", 18)
	_tower_store_toggle_button.add_theme_stylebox_override("normal", _make_store_button_style(Color(0.035, 0.075, 0.145, 0.94), Color(0.34, 0.74, 1.0, 0.95)))
	_tower_store_toggle_button.add_theme_stylebox_override("hover", _make_store_button_style(Color(0.07, 0.14, 0.24, 0.98), Color(0.64, 0.92, 1.0, 1.0)))
	_tower_store_toggle_button.add_theme_stylebox_override("pressed", _make_store_button_style(Color(0.02, 0.045, 0.09, 1.0), Color(0.96, 0.82, 0.24, 1.0)))
	_tower_store_toggle_button.pressed.connect(_toggle_tower_store)
	_tower_store_canvas.add_child(_tower_store_toggle_button)
	_position_tower_store_toggle_button()


func _make_store_button_style(bg_color: Color, border_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = border_color
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	style.shadow_color = Color(0, 0, 0, 0.38)
	style.shadow_size = 8
	return style


func _position_tower_store_toggle_button() -> void:
	if _tower_store_toggle_button == null or _tower_store_base_rect.size == Vector2.ZERO:
		return

	var store_rect := _tower_store_base_rect
	var screen_position := _world_to_screen_position(Vector2(store_rect.end.x - STORE_TOGGLE_SIZE.x - 24.0, store_rect.position.y + 18.0))
	_tower_store_toggle_button.position = screen_position
	_tower_store_toggle_button.size = STORE_TOGGLE_SIZE


func _toggle_tower_store() -> void:
	_set_tower_store_open(not _tower_store_open)


func _set_tower_store_open(is_open: bool) -> void:
	if _tower_store_open == is_open:
		return

	_tower_store_open = is_open
	if _tower_store_toggle_button != null:
		_tower_store_toggle_button.text = "Hide Store" if _tower_store_open else "Show Store"

	if _tower_store_tween != null:
		_tower_store_tween.kill()

	var start_offset := STORE_PANEL_SLIDE_DISTANCE if _tower_store_open else 0.0
	var end_offset := 0.0 if _tower_store_open else STORE_PANEL_SLIDE_DISTANCE
	_prepare_tower_store_animation(start_offset)
	_tower_store_tween = create_tween()
	_tower_store_tween.set_parallel(true)
	_tower_store_tween.tween_method(_apply_tower_store_slide, start_offset, end_offset, STORE_PANEL_ANIM_SECONDS).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tower_store_tween.set_parallel(false)
	_tower_store_tween.tween_callback(func() -> void:
		_tower_store_tween = null
		_sync_tower_store_items(true)
	)


func _prepare_tower_store_animation(slide_offset: float) -> void:
	if _tower_store_background != null:
		_tower_store_background.show()
	for node in _get_store_visual_nodes():
		if node != null:
			node.show()
	_apply_tower_store_slide(slide_offset)


func _apply_tower_store_slide(slide_offset: float) -> void:
	if _tower_store_background != null:
		_tower_store_background.global_position = _tower_store_base_rect.position + Vector2(slide_offset, 0)
	if _tower_store_title_label != null:
		_tower_store_title_label.modulate.a = 1.0 - clampf(slide_offset / STORE_PANEL_SLIDE_DISTANCE, 0.0, 1.0)
	if _tower_store_hint_label != null:
		_tower_store_hint_label.modulate.a = 1.0 - clampf(slide_offset / STORE_PANEL_SLIDE_DISTANCE, 0.0, 1.0)

	for tower in _tower_store_home_positions.keys():
		var tower_node := tower as Node2D
		if tower_node == null or not _is_tower_available_in_store(tower_node):
			continue

		tower_node.global_position = _tower_store_home_positions[tower] + Vector2(slide_offset, 0)
		tower_node.modulate.a = 1.0 - clampf(slide_offset / STORE_PANEL_SLIDE_DISTANCE, 0.0, 1.0)

		var label := _tower_store_item_labels.get(tower_node) as Label
		if label != null:
			label.modulate.a = tower_node.modulate.a

	_position_tower_store_labels(slide_offset)


func _sync_tower_store_items(force_positions: bool) -> void:
	for tower in _tower_store_home_positions.keys():
		var tower_node := tower as Node2D
		if tower_node == null:
			continue

		var in_store := _is_tower_available_in_store(tower_node)
		var visible_in_store := _tower_store_open and in_store
		tower_node.visible = visible_in_store or not in_store
		tower_node.set_process_input(visible_in_store or not in_store)
		if visible_in_store and force_positions:
			tower_node.global_position = _tower_store_home_positions[tower_node]
			tower_node.modulate.a = 1.0

		var label := _tower_store_item_labels.get(tower_node) as Label
		if label != null:
			label.visible = visible_in_store
			label.modulate.a = 1.0

	if _tower_store_background != null:
		_tower_store_background.visible = _tower_store_open
		if _tower_store_open and force_positions:
			_tower_store_background.global_position = _tower_store_base_rect.position

	if _tower_store_title_label != null:
		_tower_store_title_label.visible = _tower_store_open
	if _tower_store_hint_label != null:
		_tower_store_hint_label.visible = _tower_store_open

	if _tower_store_open and force_positions:
		_position_tower_store_labels()
		_position_tower_store_toggle_button()


func _is_tower_available_in_store(tower: Node) -> bool:
	if tower == _ids_scanner_store and tower.has_method("is_deployed"):
		return not bool(tower.call("is_deployed"))
	if tower.has_method("is_placed"):
		return not bool(tower.call("is_placed"))

	return tower.visible


func _get_store_visual_nodes() -> Array[CanvasItem]:
	var visual_nodes: Array[CanvasItem] = []
	if _tower_store_background != null:
		visual_nodes.append(_tower_store_background)
	if _tower_store_title_label != null:
		visual_nodes.append(_tower_store_title_label)
	if _tower_store_hint_label != null:
		visual_nodes.append(_tower_store_hint_label)
	for label in _tower_store_item_labels.values():
		if label is CanvasItem:
			visual_nodes.append(label)
	for tower in _tower_store_home_positions.keys():
		if tower is CanvasItem:
			visual_nodes.append(tower)
	return visual_nodes


func _set_tower_store_home_position(tower: Node2D, home_position: Vector2) -> void:
	tower.set("_home_position", home_position)
	tower.set("_drag_start_position", home_position)
	if tower.has_method("_sync_base_sprite"):
		tower.call_deferred("_sync_base_sprite")


func _hide_legacy_store_title() -> void:
	var legacy_title := get_node_or_null(^"Blue Towers") as CanvasItem
	if legacy_title != null:
		legacy_title.hide()


func _connect_store_prototypes() -> void:
	_connect_guardian_store_prototype(_guardian_store)
	_connect_laser_store_prototype(_laser_turret_store)
	_connect_scanner_store_prototype(_ids_scanner_store)
	_connect_edr_store_prototype(_edr_hunter_store)
	_connect_siem_store_prototype(_siem_hawk_store)
	_connect_ips_store_prototype(_ips_intrusion_store)
	_connect_honeypot_store_prototype(_honeypot_production_store)


func _connect_guardian_store_prototype(tower: CyberGuardianTowerScript) -> void:
	if tower == null:
		return
	if not tower.placed.is_connected(_on_guardian_store_tower_placed):
		tower.placed.connect(_on_guardian_store_tower_placed)


func _connect_laser_store_prototype(tower: LaserTurretScript) -> void:
	if tower == null:
		return
	if not tower.placed.is_connected(_on_laser_store_tower_placed):
		tower.placed.connect(_on_laser_store_tower_placed)


func _connect_scanner_store_prototype(tower: IDSScannerTowerScript) -> void:
	if tower == null:
		return
	if not tower.placed.is_connected(_on_scanner_store_tower_placed):
		tower.placed.connect(_on_scanner_store_tower_placed)


func _connect_edr_store_prototype(tower: EDRHunterTowerScript) -> void:
	if tower == null:
		return
	if not tower.placed.is_connected(_on_edr_store_tower_placed):
		tower.placed.connect(_on_edr_store_tower_placed)


func _connect_siem_store_prototype(tower: SIEMHawkTowerScript) -> void:
	if tower == null:
		return
	if not tower.placed.is_connected(_on_siem_store_tower_placed):
		tower.placed.connect(_on_siem_store_tower_placed)


func _connect_ips_store_prototype(tower: IPSIntrusionTowerScript) -> void:
	if tower == null:
		return
	if not tower.placed.is_connected(_on_ips_store_tower_placed):
		tower.placed.connect(_on_ips_store_tower_placed)


func _connect_honeypot_store_prototype(tower: HoneypotProductionTowerScript) -> void:
	if tower == null:
		return
	if not tower.placed.is_connected(_on_honeypot_store_tower_placed):
		tower.placed.connect(_on_honeypot_store_tower_placed)


func _on_guardian_store_tower_placed(tower: CyberGuardianTowerScript) -> void:
	_guardians.append(tower)
	_guardian = tower
	_spawn_replacement_guardian()
	_update_demo_upgrade_buttons()


func _on_laser_store_tower_placed(tower: LaserTurretScript) -> void:
	_laser_turrets.append(tower)
	_laser_turret = tower
	_spawn_replacement_laser()
	_update_demo_upgrade_buttons()


func _on_scanner_store_tower_placed(tower: IDSScannerTowerScript) -> void:
	_ids_scanners.append(tower)
	_ids_scanner = tower
	_connect_placed_scanner(tower)
	_spawn_replacement_scanner()
	_update_demo_upgrade_buttons()


func _on_edr_store_tower_placed(tower: EDRHunterTowerScript) -> void:
	_edr_hunters.append(tower)
	_edr_hunter = tower
	_spawn_replacement_edr()
	_update_demo_upgrade_buttons()


func _on_siem_store_tower_placed(tower: SIEMHawkTowerScript) -> void:
	_siem_hawks.append(tower)
	_siem_hawk = tower
	_connect_placed_siem(tower)
	_spawn_replacement_siem()
	_update_demo_upgrade_buttons()


func _on_ips_store_tower_placed(tower: IPSIntrusionTowerScript) -> void:
	_ips_intrusions.append(tower)
	_ips_intrusion = tower
	_connect_placed_ips(tower)
	_spawn_replacement_ips()
	_update_demo_upgrade_buttons()


func _on_honeypot_store_tower_placed(tower: HoneypotProductionTowerScript) -> void:
	_honeypot_productions.append(tower)
	_honeypot_production = tower
	_spawn_replacement_honeypot()
	_update_demo_upgrade_buttons()


func _spawn_replacement_guardian() -> void:
	_guardian_store = _spawn_store_replacement(CyberGuardianScene, _guardian_store, "Cybersec Guardian") as CyberGuardianTowerScript
	_connect_guardian_store_prototype(_guardian_store)


func _spawn_replacement_laser() -> void:
	_laser_turret_store = _spawn_store_replacement(LaserTurretScene, _laser_turret_store, "Laser Turret") as LaserTurretScript
	_connect_laser_store_prototype(_laser_turret_store)


func _spawn_replacement_scanner() -> void:
	_ids_scanner_store = _spawn_store_replacement(IDSScannerScene, _ids_scanner_store, "IDS_Scanner") as IDSScannerTowerScript
	_connect_scanner_store_prototype(_ids_scanner_store)


func _spawn_replacement_edr() -> void:
	_edr_hunter_store = _spawn_store_replacement(EDRHunterScene, _edr_hunter_store, "EDR_Hunter") as EDRHunterTowerScript
	_connect_edr_store_prototype(_edr_hunter_store)


func _spawn_replacement_siem() -> void:
	_siem_hawk_store = _spawn_store_replacement(SIEMHawkScene, _siem_hawk_store, "SIEM_Hawk") as SIEMHawkTowerScript
	_connect_siem_store_prototype(_siem_hawk_store)


func _spawn_replacement_ips() -> void:
	_ips_intrusion_store = _spawn_store_replacement(IPSIntrusionScene, _ips_intrusion_store, "IPS_Intrusion") as IPSIntrusionTowerScript
	_connect_ips_store_prototype(_ips_intrusion_store)


func _spawn_replacement_honeypot() -> void:
	_honeypot_production_store = _spawn_store_replacement(HoneypotProductionScene, _honeypot_production_store, "Honeypot_Production") as HoneypotProductionTowerScript
	_connect_honeypot_store_prototype(_honeypot_production_store)


func _spawn_store_replacement(scene: PackedScene, placed_tower: Node2D, node_name: String) -> Node2D:
	if scene == null or placed_tower == null:
		return null

	var home_position: Vector2 = _tower_store_home_positions.get(placed_tower, placed_tower.global_position)
	var parent := placed_tower.get_parent()
	var replacement := scene.instantiate() as Node2D
	if replacement == null:
		return null

	replacement.name = node_name
	parent.add_child(replacement)
	replacement.global_position = home_position
	_set_tower_store_home_position(replacement, home_position)
	_tower_store_home_positions.erase(placed_tower)
	_tower_store_home_positions[replacement] = home_position

	var label := _tower_store_item_labels.get(placed_tower) as Label
	if label != null:
		_tower_store_item_labels.erase(placed_tower)
		_tower_store_item_labels[replacement] = label
	_sync_tower_store_items(true)
	return replacement


func _connect_placed_scanner(tower: IDSScannerTowerScript) -> void:
	if tower == null:
		return
	if not tower.virus_damage_requested.is_connected(_on_scanner_virus_damage_requested):
		tower.virus_damage_requested.connect(_on_scanner_virus_damage_requested)
	if not tower.bounty_awarded.is_connected(_on_scanner_bounty_awarded):
		tower.bounty_awarded.connect(_on_scanner_bounty_awarded)


func _connect_placed_siem(tower: SIEMHawkTowerScript) -> void:
	if tower == null:
		return
	if not tower.dispatch_mode_changed.is_connected(_on_siem_hawk_dispatch_mode_changed):
		tower.dispatch_mode_changed.connect(_on_siem_hawk_dispatch_mode_changed)
	if not tower.knowledge_extracted.is_connected(_on_siem_hawk_knowledge_extracted):
		tower.knowledge_extracted.connect(_on_siem_hawk_knowledge_extracted)
	if not tower.knowledge_bank_changed.is_connected(_on_siem_hawk_knowledge_bank_changed):
		tower.knowledge_bank_changed.connect(_on_siem_hawk_knowledge_bank_changed)


func _connect_placed_ips(tower: IPSIntrusionTowerScript) -> void:
	if tower == null:
		return
	if not tower.spike_damage_requested.is_connected(_on_ips_spike_damage_requested):
		tower.spike_damage_requested.connect(_on_ips_spike_damage_requested)


func _handle_placed_tower_press(pointer_position: Vector2, screen_position: Vector2) -> void:
	if _tower_upgrade_hud != null and _tower_upgrade_hud.guardian_panel_has_point(screen_position):
		return

	var guardian := _find_tower_at_point(_guardians, pointer_position) as CyberGuardianTowerScript
	if guardian != null:
		_guardian = guardian
		_show_upgrade_panel()
		get_viewport().set_input_as_handled()
	elif _tower_upgrade_hud != null and _tower_upgrade_hud.is_guardian_panel_visible():
		_hide_upgrade_panel()


func _handle_laser_turret_press(pointer_position: Vector2, screen_position: Vector2) -> bool:
	if _tower_upgrade_hud != null and _tower_upgrade_hud.laser_panel_has_point(screen_position):
		return true

	var laser_turret := _find_tower_at_point(_laser_turrets, pointer_position) as LaserTurretScript
	if laser_turret != null:
		_laser_turret = laser_turret
		_show_laser_upgrade_panel()
		get_viewport().set_input_as_handled()
		return true

	if _tower_upgrade_hud != null and _tower_upgrade_hud.is_laser_panel_visible():
		_hide_laser_upgrade_panel()

	return false


func _handle_ids_scanner_press(pointer_position: Vector2, screen_position: Vector2) -> bool:
	if _tower_upgrade_hud != null and _tower_upgrade_hud.scanner_panel_has_point(screen_position):
		return true

	var ids_scanner := _find_tower_at_point(_ids_scanners, pointer_position) as IDSScannerTowerScript
	if ids_scanner != null:
		_ids_scanner = ids_scanner
		_show_scanner_upgrade_panel()
		get_viewport().set_input_as_handled()
		return true

	if _tower_upgrade_hud != null and _tower_upgrade_hud.is_scanner_panel_visible():
		_hide_scanner_upgrade_panel()

	return false


func _handle_edr_hunter_press(pointer_position: Vector2, screen_position: Vector2) -> bool:
	if _tower_upgrade_hud != null and _tower_upgrade_hud.edr_panel_has_point(screen_position):
		return true

	var edr_hunter := _find_tower_at_point(_edr_hunters, pointer_position) as EDRHunterTowerScript
	if edr_hunter != null:
		_edr_hunter = edr_hunter
		_show_edr_upgrade_panel()
		get_viewport().set_input_as_handled()
		return true

	if _tower_upgrade_hud != null and _tower_upgrade_hud.is_edr_panel_visible():
		_hide_edr_upgrade_panel()

	return false


func _handle_siem_hawk_press(pointer_position: Vector2, screen_position: Vector2) -> bool:
	if _tower_upgrade_hud != null and _tower_upgrade_hud.siem_panel_has_point(screen_position):
		return true

	var siem_hawk := _find_tower_at_point(_siem_hawks, pointer_position) as SIEMHawkTowerScript
	if siem_hawk != null:
		_siem_hawk = siem_hawk
		_show_siem_upgrade_panel()
		get_viewport().set_input_as_handled()
		return true

	if _tower_upgrade_hud != null and _tower_upgrade_hud.is_siem_panel_visible():
		_hide_siem_upgrade_panel()

	return false


func _handle_ips_intrusion_press(pointer_position: Vector2, screen_position: Vector2) -> bool:
	if _tower_upgrade_hud != null and _tower_upgrade_hud.ips_panel_has_point(screen_position):
		return true

	var ips_intrusion := _find_tower_at_point(_ips_intrusions, pointer_position) as IPSIntrusionTowerScript
	if ips_intrusion != null:
		_ips_intrusion = ips_intrusion
		_show_ips_upgrade_panel()
		get_viewport().set_input_as_handled()
		return true

	if _tower_upgrade_hud != null and _tower_upgrade_hud.is_ips_panel_visible():
		_hide_ips_upgrade_panel()

	return false


func _handle_honeypot_production_press(pointer_position: Vector2, screen_position: Vector2) -> bool:
	if _tower_upgrade_hud != null and _tower_upgrade_hud.honeypot_panel_has_point(screen_position):
		return true

	var honeypot_production := _find_tower_at_point(_honeypot_productions, pointer_position) as HoneypotProductionTowerScript
	if honeypot_production == null:
		if _tower_upgrade_hud != null and _tower_upgrade_hud.is_honeypot_panel_visible():
			_hide_honeypot_upgrade_panel()
		return false

	_honeypot_production = honeypot_production
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


func _find_tower_at_point(towers: Array, pointer_position: Vector2) -> Node:
	for index in range(towers.size() - 1, -1, -1):
		var tower := towers[index] as Node
		if not is_instance_valid(tower):
			towers.remove_at(index)
			continue
		if tower.has_method("contains_global_point") and bool(tower.call("contains_global_point", pointer_position)):
			return tower

	return null


func _reset_tower() -> void:
	if _is_act_input_locked():
		return

	if _guardian_store != null:
		_guardian_store.reset_tower()
	if _laser_turret_store != null:
		_laser_turret_store.reset_tower()
	if _ids_scanner_store != null:
		_ids_scanner_store.reset_tower()
	if _edr_hunter_store != null:
		_edr_hunter_store.reset_tower()
	if _siem_hawk_store != null:
		_siem_hawk_store.reset_tower()
	if _ips_intrusion_store != null:
		_ips_intrusion_store.reset_tower()
	if _honeypot_production_store != null:
		_honeypot_production_store.reset_tower()
	_clear_adware_popups()
	for node in get_tree().get_nodes_in_group("Defender"):
		if _is_store_prototype(node) or not is_instance_valid(node):
			continue
		node.queue_free()
	_guardians.clear()
	_laser_turrets.clear()
	_ids_scanners.clear()
	_edr_hunters.clear()
	_siem_hawks.clear()
	_ips_intrusions.clear()
	_honeypot_productions.clear()
	_guardian = _guardian_store
	_laser_turret = _laser_turret_store
	_ids_scanner = _ids_scanner_store
	_edr_hunter = _edr_hunter_store
	_siem_hawk = _siem_hawk_store
	_ips_intrusion = _ips_intrusion_store
	_honeypot_production = _honeypot_production_store
	if _tower_upgrade_hud != null:
		_tower_upgrade_hud.hide_all()
	if _progress_hud != null:
		_progress_hud.reset_knowledge()
	_apply_guardian_signal_boost_state()
	_set_tower_menu_radius_previews(false, false, false, false, false)
	_update_demo_upgrade_buttons()


func _is_store_prototype(node: Node) -> bool:
	return node == _guardian_store \
		or node == _laser_turret_store \
		or node == _ids_scanner_store \
		or node == _edr_hunter_store \
		or node == _siem_hawk_store \
		or node == _ips_intrusion_store \
		or node == _honeypot_production_store


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


func _set_guardian_mode(mode_id: StringName) -> void:
	if _is_act_input_locked():
		return
	if _guardian == null:
		return

	var knowledge_level := _get_current_knowledge_level()
	if not _guardian.is_mode_unlocked(mode_id, knowledge_level):
		_sync_guardian_upgrade_panel()
		return

	_guardian.set_guardian_mode(mode_id)
	_apply_guardian_signal_boost_state()
	_sync_all_tower_upgrade_panels()
	_update_demo_upgrade_buttons()


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
	_sync_guardian_upgrade_panel()


func _on_guardian_mode_changed(_mode_id: StringName) -> void:
	_apply_guardian_signal_boost_state()
	_sync_guardian_upgrade_panel()


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


func _get_current_knowledge_level() -> int:
	return _progress_hud.get_knowledge_level() if _progress_hud != null else 1


func _apply_guardian_signal_boost_state() -> void:
	var boost_active := _guardian != null \
		and _guardian.is_placed() \
		and _guardian.get_current_mode_id() == GUARDIAN_MODE_SIGNAL_BOOST

	for node in get_tree().get_nodes_in_group("Defender"):
		if not is_instance_valid(node) or not is_ancestor_of(node):
			continue
		if node.has_method("set_signal_boost_active"):
			node.call("set_signal_boost_active", boost_active)


func _sync_all_tower_upgrade_panels() -> void:
	_sync_guardian_upgrade_panel()
	_sync_laser_upgrade_panel()
	_sync_scanner_upgrade_panel()
	_sync_edr_upgrade_panel()
	_sync_siem_upgrade_panel()
	_sync_ips_upgrade_panel()
	_sync_honeypot_upgrade_panel()


func _sync_guardian_upgrade_panel() -> void:
	if _guardian == null or _tower_upgrade_hud == null:
		return

	var knowledge_level := _get_current_knowledge_level()
	_tower_upgrade_hud.set_guardian_modes(
		_guardian.get_current_mode_id(),
		_guardian.get_unlocked_mode_ids(knowledge_level),
		knowledge_level,
		_guardian.get_mode_unlock_levels()
	)


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
	if _current_wave == ADWARE_WAVE:
		_begin_adware_wave_spawn()


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
	_clear_adware_popups()
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


func _begin_adware_wave_spawn() -> void:
	_adware_spawns_remaining = ADWARE_POPUP_COUNT
	_adware_spawn_cooldown_remaining = 0.0
	_adware_spawned_count = 0
	_rebuild_adware_variation_deck()


func _update_adware_spawner(delta: float) -> void:
	_prune_adware_popups()
	if _adware_spawns_remaining <= 0:
		return

	_adware_spawn_cooldown_remaining -= delta
	if _adware_spawn_cooldown_remaining > 0.0:
		return

	_spawn_adware_popup()
	_adware_spawns_remaining -= 1
	_adware_spawned_count += 1
	_adware_spawn_cooldown_remaining = ADWARE_POPUP_INTERVAL


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


func _spawn_adware_popup() -> void:
	var adware := AdwareScene.instantiate() as Adware
	if adware == null:
		push_warning("Cannot spawn adware because the configured scene is invalid.")
		return

	adware.setup(_get_next_adware_variation_index())

	add_child(adware)
	adware.global_position = _screen_to_canvas_position(
		adware.get_spawn_screen_position(_adware_spawned_count, get_viewport_rect().size, _adware_rng)
	)
	adware.z_index = 95 + (_adware_spawned_count % ADWARE_POPUP_COUNT)
	_active_adware_popups.append(adware)


func _clear_adware_popups() -> void:
	_adware_spawns_remaining = 0
	_adware_spawn_cooldown_remaining = 0.0
	_adware_spawned_count = 0
	_adware_variation_deck.clear()
	for popup in _active_adware_popups:
		if is_instance_valid(popup):
			popup.queue_free()
	_active_adware_popups.clear()


func _prune_adware_popups() -> void:
	for index in range(_active_adware_popups.size() - 1, -1, -1):
		if not is_instance_valid(_active_adware_popups[index]):
			_active_adware_popups.remove_at(index)


func _rebuild_adware_variation_deck() -> void:
	_adware_variation_deck.clear()
	while _adware_variation_deck.size() < ADWARE_POPUP_COUNT:
		for variation_index in range(ADWARE_VARIATION_COUNT):
			_adware_variation_deck.append(variation_index)
			if _adware_variation_deck.size() >= ADWARE_POPUP_COUNT:
				break

	for index in range(_adware_variation_deck.size() - 1, 0, -1):
		var swap_index := _adware_rng.randi_range(0, index)
		var current_value := _adware_variation_deck[index]
		_adware_variation_deck[index] = _adware_variation_deck[swap_index]
		_adware_variation_deck[swap_index] = current_value


func _get_next_adware_variation_index() -> int:
	if _adware_variation_deck.is_empty():
		return _adware_rng.randi_range(0, ADWARE_VARIATION_COUNT - 1)

	return int(_adware_variation_deck.pop_back())


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
	for guardian in _guardians:
		if not is_instance_valid(guardian):
			continue
		var target := guardian.update_attack(delta, _active_viruses)
		if target != null:
			_shoot_virus(guardian, target)


func _update_laser_turret_attack(delta: float) -> void:
	for laser_turret in _laser_turrets:
		if not is_instance_valid(laser_turret):
			continue
		var targets := laser_turret.update_attack(delta, _active_viruses)
		if not targets.is_empty():
			_shoot_laser_turret_targets(laser_turret, targets)


func _update_siem_hawk_knowledge(delta: float) -> void:
	var mouse_world_position := _screen_to_canvas_position(get_viewport().get_mouse_position())
	for siem_hawk in _siem_hawks:
		if is_instance_valid(siem_hawk):
			siem_hawk.update_knowledge_scan(delta, mouse_world_position, _active_viruses)


func _update_ips_intrusion_spikes(delta: float) -> void:
	for ips_intrusion in _ips_intrusions:
		if is_instance_valid(ips_intrusion):
			ips_intrusion.update_spike_factory(delta, _active_viruses)


func _update_edr_hunter_attack(delta: float) -> void:
	for edr_hunter in _edr_hunters:
		if not is_instance_valid(edr_hunter):
			continue
		var target := edr_hunter.update_attack(delta, _active_viruses)
		if target != null:
			_shoot_edr_hunter_target(edr_hunter, target)


func _update_siem_hawk_attack(delta: float) -> void:
	for siem_hawk in _siem_hawks:
		if not is_instance_valid(siem_hawk):
			continue
		var target := siem_hawk.update_attack(delta, _active_viruses)
		if target != null:
			_shoot_siem_hawk_target(siem_hawk, target)


func _update_support_tower_scans(delta: float) -> void:
	for node in get_tree().get_nodes_in_group("SUPPORT_TOWER"):
		if not is_instance_valid(node) or not is_ancestor_of(node):
			continue
		if not node.has_method("update_support_scan"):
			continue

		node.call("update_support_scan", _active_viruses, delta)


func _shoot_virus(guardian: CyberGuardianTowerScript, target: PathFollow2D) -> void:
	if not is_instance_valid(target):
		return

	var target_position := _get_target_center(target)
	guardian.aim_at(target_position)
	guardian.play_shoot()
	_spawn_colored_laser(guardian.global_position, target_position, Color(0.1, 0.55, 1.0, 1.0), guardian.get_laser_width())
	var destroyed := _damage_virus(target, guardian.get_shot_power())
	if destroyed and _utility_overlay_hud != null:
		_utility_overlay_hud.show_guardian_destroy_popup(
			_world_to_screen_position(guardian.global_position),
			guardian.get_shot_power(),
			guardian.get_shot_cooldown()
		)
		if _question_hud != null:
			_question_hud.add_cyberbucks(GUARDIAN_CYBERBUCK_REWARD)
			_sync_laser_upgrade_panel()
			_sync_scanner_upgrade_panel()
			_sync_edr_upgrade_panel()
			_sync_siem_upgrade_panel()


func _shoot_edr_hunter_target(edr_hunter: EDRHunterTowerScript, target: PathFollow2D) -> void:
	if edr_hunter == null or not is_instance_valid(target):
		return

	var target_position := _get_target_center(target)
	edr_hunter.aim_at(target_position)
	edr_hunter.play_shoot()
	_spawn_colored_laser(edr_hunter.global_position, target_position, Color(0.12, 0.95, 1.0, 1.0), edr_hunter.get_laser_width())
	_damage_virus(target, edr_hunter.get_shot_power())


func _shoot_siem_hawk_target(siem_hawk: SIEMHawkTowerScript, target: PathFollow2D) -> void:
	if siem_hawk == null or not is_instance_valid(target):
		return

	var target_position := _get_target_center(target)
	siem_hawk.aim_at(target_position)
	siem_hawk.play_shoot()
	_spawn_colored_laser(siem_hawk.global_position, target_position, Color(0.2, 0.74, 1.0, 1.0), siem_hawk.get_laser_width())
	_damage_virus(target, siem_hawk.get_shot_power())


func _shoot_laser_turret_targets(laser_turret: LaserTurretScript, targets: Array[PathFollow2D]) -> void:
	if laser_turret == null:
		return

	var origin_position := laser_turret.global_position
	var laser_width := laser_turret.get_laser_width()
	var laser_color := laser_turret.get_laser_color()
	var destroyed_count := 0
	for target in targets:
		if not is_instance_valid(target):
			continue

		var target_position := _get_target_center(target)
		laser_turret.aim_at(target_position)
		if _should_use_demo_laser_turret_beam_fx(laser_turret):
			if not laser_turret.spawn_beam_fx(target_position, self):
				_spawn_colored_laser(origin_position, target_position, laser_color, laser_width)
		else:
			_spawn_colored_laser(origin_position, target_position, laser_color, laser_width)
		if _damage_virus(target, _laser_turret.get_shot_power(), false):
			destroyed_count += 1

	if destroyed_count > 0:
		if _utility_overlay_hud != null:
			var reward := destroyed_count * LASER_TURRET_CYBERBUCK_REWARD
			_utility_overlay_hud.show_tower_destroy_popup(
				_world_to_screen_position(laser_turret.global_position),
				reward,
				laser_turret.get_shot_power(),
				laser_turret.get_shot_cooldown()
			)
			if _question_hud != null:
				_question_hud.add_cyberbucks(reward)
				_sync_laser_upgrade_panel()
				_sync_scanner_upgrade_panel()
				_sync_edr_upgrade_panel()
				_sync_siem_upgrade_panel()
		laser_turret.mark_shot_fired()
		_update_virus_count_label()


func _should_use_demo_laser_turret_beam_fx(laser_turret: LaserTurretScript) -> bool:
	return _utility_overlay_hud != null \
		and laser_turret != null \
		and laser_turret.has_beam_fx()


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
	_sync_guardian_upgrade_panel()


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
