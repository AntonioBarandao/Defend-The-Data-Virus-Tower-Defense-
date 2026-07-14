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
const SpywareScript := preload("res://Scripts/Enemies/spyware.gd")
const SpywareScene := preload("res://Scenes/Enemies/Spyware.tscn")
const ArmoredVirusScene := preload("res://Scenes/Enemies/ArmoredVirus.tscn")
const MutantVirusScene := preload("res://Scenes/Enemies/MutantVirus.tscn")
const CyberQuestionHUDScript := preload("res://Scripts/UI/cyber_question_hud.gd")
const PerformanceHUDScript := preload("res://Scripts/UI/performance_hud.gd")
const GameControlsHUDScript := preload("res://Scripts/UI/game_controls_hud.gd")
const TowerUpgradeHUDScript := preload("res://Scripts/UI/tower_upgrade_hud.gd")
const ProgressHUDScript := preload("res://Scripts/UI/progress_hud.gd")
const UtilityOverlayHUDScript := preload("res://Scripts/UI/utility_overlay_hud.gd")
const TowerShopCardScene := preload("res://Scenes/UI/TowerShopCard.tscn")
const CyberGuardianCardResource := preload("res://Resources/TowerShopCards/CyberGuardianCard.tres")
const LaserTurretCardResource := preload("res://Resources/TowerShopCards/LaserTurretCard.tres")
const IDSScannerCardResource := preload("res://Resources/TowerShopCards/IDSScannerCard.tres")
const EDRHunterCardResource := preload("res://Resources/TowerShopCards/EDRHunterCard.tres")
const SIEMHawkCardResource := preload("res://Resources/TowerShopCards/SIEMHawkCard.tres")
const IPSIntrusionCardResource := preload("res://Resources/TowerShopCards/IPSIntrusionCard.tres")
const HoneypotProductionCardResource := preload("res://Resources/TowerShopCards/HoneypotProductionCard.tres")
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
const SPYWARE_TEST_WAVE := 8
const SPYWARE_MAX_ACTIVE := 2
const ARMORED_VIRUS_TEST_WAVE := 7
const MUTANT_VIRUS_TEST_WAVE := 13
const ADWARE_POPUP_COUNT := 5
const ADWARE_VARIATION_COUNT := 25
const ADWARE_POPUP_INTERVAL := 0.5
const LASER_DURATION := 0.24
const GUARDIAN_CYBERBUCK_REWARD := 5
const LASER_TURRET_CYBERBUCK_REWARD := 5
const ADMIN_CYBERBUCK_GRANT := 500
const TOWER_SELL_REFUND_RATE := 0.6
const CYBER_GUARDIAN_DEPLOY_COST := 100
const LASER_TURRET_DEPLOY_COST := 125
const IDS_SCANNER_DEPLOY_COST := 150
const EDR_HUNTER_DEPLOY_COST := 175
const HONEYPOT_PRODUCTION_DEPLOY_COST := 250
const IPS_INTRUSION_DEPLOY_COST := 200
const SIEM_HAWK_DEPLOY_COST := 225
const TOWER_ID_CYBER_GUARDIAN := &"cyber_guardian"
const TOWER_ID_LASER_TURRET := &"laser_turret"
const TOWER_ID_IDS_SCANNER := &"ids_scanner"
const TOWER_ID_EDR_HUNTER := &"edr_hunter"
const TOWER_ID_SIEM_HAWK := &"siem_hawk"
const TOWER_ID_IPS_INTRUSION := &"ips_intrusion"
const TOWER_ID_HONEYPOT_PRODUCTION := &"honeypot_production"
const DEFAULT_TOWER_CARD_RESOURCES := {
	TOWER_ID_CYBER_GUARDIAN: CyberGuardianCardResource,
	TOWER_ID_LASER_TURRET: LaserTurretCardResource,
	TOWER_ID_IDS_SCANNER: IDSScannerCardResource,
	TOWER_ID_EDR_HUNTER: EDRHunterCardResource,
	TOWER_ID_SIEM_HAWK: SIEMHawkCardResource,
	TOWER_ID_IPS_INTRUSION: IPSIntrusionCardResource,
	TOWER_ID_HONEYPOT_PRODUCTION: HoneypotProductionCardResource
}
const GUARDIAN_MODE_DEFENDER := &"defender"
const GUARDIAN_MODE_SIGNAL_BOOST := &"signal_boost"
const GUARDIAN_MODE_FIREWALL := &"firewall"
const SIGNAL_BOOST_UNLOCK_KNOWLEDGE_LEVEL := 3
const SIGNAL_BOOST_RANGE_BASE_BONUS := 0.10
const SIGNAL_BOOST_COOLDOWN_BASE_REDUCTION := 0.10
const SIGNAL_BOOST_HAWK_SPEED_BASE_BONUS := 0.20
const SIGNAL_BOOST_STEP_BONUS := 0.05
const SIGNAL_BOOST_STEP_LEVELS := [4, 6, 7, 9, 10]
const FIREWALL_UNLOCK_KNOWLEDGE_LEVEL := 5
const FIREWALL_BURN_DURATION_SECONDS := 5.0
const FIREWALL_BALANCE_BY_MIN_KNOWLEDGE_LEVEL := [
	{
		"level": 5,
		"hit_damage": 1,
		"burn_damage": 1,
		"burn_tick_seconds": 1.0
	},
	{
		"level": 6,
		"hit_damage": 2,
		"burn_damage": 1,
		"burn_tick_seconds": 0.5
	},
	{
		"level": 8,
		"hit_damage": 4,
		"burn_damage": 5,
		"burn_tick_seconds": 1.0
	},
	{
		"level": 10,
		"hit_damage": 20,
		"burn_damage": 10,
		"burn_tick_seconds": 1.0
	}
]
const DEFAULT_VIRUS_SPAWN_SCALE := Vector2(0.2, 0.2)
const DEFAULT_EVOLVED_VIRUS_SPAWN_SCALE := Vector2(0.11, 0.11)
const DEFAULT_TROJAN_HORSE_SPAWN_SCALE := Vector2(0.4, 0.4)
const DEFAULT_ADWARE_SPAWN_SCALE := Vector2(0.18, 0.18)
const STORE_TOGGLE_ICON := preload("res://assets/UI/TowerStoreArrowHex.svg")
const STORE_TOGGLE_SIZE := Vector2(64, 80)
const STORE_TOGGLE_SCREEN_INSET := 8.0
const STORE_PANEL_PADDING := Vector2(28, 28)
const STORE_PANEL_EXTRA_BOTTOM := 34.0
const STORE_PANEL_MIN_WIDTH := 430.0
const STORE_PANEL_SLIDE_DISTANCE := 360.0
const STORE_PANEL_ANIM_SECONDS := 0.22
const STORE_CARD_COLUMNS := 2
const STORE_CARD_SIZE := Vector2(158, 166)
const STORE_CARD_GAP := Vector2(18, 18)
const STORE_CARD_GRID_TOP_OFFSET := 122.0
const STORE_TOWER_DISPLAY_SCALE_MULTIPLIER := 0.72
const STORE_PANEL_Z_INDEX := 205
const STORE_LABEL_Z_INDEX := 210
const STORE_DRAG_START_THRESHOLD := 12.0

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
@export var cutscene_demo_menu_hud_path: NodePath = ^"CutsceneDemoMenuHUD"
@export var tower_store_panel_path: NodePath = ^"TestDrag"
@export var tower_store_background_path: NodePath = ^"TestDrag/TowerTrayBackground"
@export var tower_store_title_label_path: NodePath = ^"TestDrag/TowerShopTitle"
@export var tower_store_hint_label_path: NodePath = ^"TestDrag/TowerShopHint"
@export var tower_store_toggle_button_path: NodePath = ^"TestDrag/TowerStoreToggleButton"
@export_group("Tower Store Cards")
@export var cyber_guardian_card_resource: TowerShopCardResource = CyberGuardianCardResource
@export var laser_turret_card_resource: TowerShopCardResource = LaserTurretCardResource
@export var ids_scanner_card_resource: TowerShopCardResource = IDSScannerCardResource
@export var edr_hunter_card_resource: TowerShopCardResource = EDRHunterCardResource
@export var siem_hawk_card_resource: TowerShopCardResource = SIEMHawkCardResource
@export var ips_intrusion_card_resource: TowerShopCardResource = IPSIntrusionCardResource
@export var honeypot_production_card_resource: TowerShopCardResource = HoneypotProductionCardResource
@export var tower_store_card_resources: Array[Resource] = []
@export_group("")
@export var demo_spawn_buttons_ignore_question_lock := false
@export_range(1, 999, 1) var starting_lives := 20
@export var admin_mode := false
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
var _cutscene_demo_menu_hud: Node
var _path_guide_container: Node2D
var _tower_store_panel: Control
var _tower_store_background: ColorRect
var _tower_store_toggle_button: Button
var _tower_store_canvas: CanvasLayer
var _tower_store_title_label: Label
var _tower_store_hint_label: Label
var _tower_store_item_cards: Dictionary = {}
var _tower_store_card_base_rects: Dictionary = {}
var _tower_store_use_authored_card_layout := false
var _tower_store_background_authored := false
var _tower_store_title_label_authored := false
var _tower_store_hint_label_authored := false
var _tower_store_toggle_button_authored := false
var _tower_store_toggle_open_position := Vector2.ZERO
var _tower_store_toggle_open_position_cached := false
var _tower_store_home_positions: Dictionary = {}
var _tower_store_placed_scales: Dictionary = {}
var _tower_store_base_rect := Rect2()
var _tower_store_open := true
var _tower_store_tween: Tween
var _wave_label_store_rest_position := Vector2.ZERO
var _wave_label_store_position_cached := false
var _pending_store_drag_tower: Node2D
var _pending_store_drag_start_position := Vector2.ZERO
var _restore_tower_store_after_upgrade_panel := false
var _tower_store_restore_after_upgrade_waiting := false
var _admin_add_bucks_button: Button
var _active_viruses: Array[PathFollow2D] = []
var _lives := 0
var _game_over := false
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
	_cutscene_demo_menu_hud = get_node_or_null(cutscene_demo_menu_hud_path)
	_tower_store_panel = get_node_or_null(tower_store_panel_path) as Control
	_tower_store_background = get_node_or_null(tower_store_background_path) as ColorRect
	_tower_store_title_label = get_node_or_null(tower_store_title_label_path) as Label
	_tower_store_hint_label = get_node_or_null(tower_store_hint_label_path) as Label
	_tower_store_toggle_button = get_node_or_null(tower_store_toggle_button_path) as Button
	_tower_store_background_authored = _tower_store_background != null
	_tower_store_title_label_authored = _tower_store_title_label != null
	_tower_store_hint_label_authored = _tower_store_hint_label != null
	_tower_store_toggle_button_authored = _tower_store_toggle_button != null
	if _virus_spawn == null:
		_virus_spawn = get_node_or_null(^"VirusElements/Spawn2D") as Node2D

	_setup_tower_store()
	_cache_store_companion_ui_positions()
	_setup_admin_currency_button()

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
		_question_hud.phishing_decoy_selected.connect(Callable(self, "_on_phishing_decoy_selected"))
	if _performance_hud == null:
		push_warning("PerformanceHUD was not found.")
	if _game_controls_hud == null:
		push_warning("GameControlsHUD was not found.")
	else:
		_game_controls_hud.reset_pressed.connect(Callable(self, "_reset_tower"))
		_game_controls_hud.start_wave_pressed.connect(Callable(self, "_start_next_wave"))
		_game_controls_hud.virus_batch_requested.connect(Callable(self, "spawn_virus_batch"))
		_game_controls_hud.exit_pressed.connect(Callable(self, "_exit_game"))
		_game_controls_hud.set_admin_mode(_is_admin_scene())
	_lives = maxi(1, starting_lives)
	_update_lives_display()
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
		_tower_upgrade_hud.sell_pressed.connect(Callable(self, "_sell_selected_tower"))
	if _guardian != null:
		_connect_placed_guardian(_guardian)
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
		_utility_overlay_hud.siem_hawk_freeze_requested.connect(Callable(self, "_toggle_siem_hawk_dispatch"))
		_utility_overlay_hud.siem_hawk_land_requested.connect(Callable(self, "_land_siem_hawk_to_headquarters"))
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
			if _handle_tower_upgrade_sidebar_modal_press(mouse_button.position):
				return

			if _tower_store_toggle_has_point(mouse_button.position):
				return

			if _game_controls_have_point(mouse_button.position):
				return

			if _try_handle_store_card_information_press(pointer_position):
				get_viewport().set_input_as_handled()
				return

			if _try_begin_any_store_tower_drag(pointer_position):
				get_viewport().set_input_as_handled()
				return

			if _tower_store_blocks_point(pointer_position):
				get_viewport().set_input_as_handled()
				return

			if _demo_upgrade_button_has_point(mouse_button.position):
				return

			if _handle_adware_popup_press(pointer_position):
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
		elif _pending_store_drag_tower != null:
			_clear_pending_store_tower_drag()
			get_viewport().set_input_as_handled()
			return
		elif _demo_upgrade_button_has_point(mouse_button.position):
			return
		elif _is_store_tower_dragging(_siem_hawk_store):
			_finish_store_tower_drag(_siem_hawk_store)
		elif _is_store_tower_dragging(_honeypot_production_store):
			_finish_store_tower_drag(_honeypot_production_store)
		elif _is_store_tower_dragging(_ips_intrusion_store):
			_finish_store_tower_drag(_ips_intrusion_store)
		elif _is_store_tower_dragging(_edr_hunter_store):
			_finish_store_tower_drag(_edr_hunter_store)
		elif _is_store_tower_dragging(_ids_scanner_store):
			_finish_store_tower_drag(_ids_scanner_store)
		elif _is_store_tower_dragging(_laser_turret_store):
			_finish_store_tower_drag(_laser_turret_store)
		elif _is_store_tower_dragging(_guardian_store):
			if _finish_store_tower_drag(_guardian_store):
				_apply_guardian_signal_boost_state()
				_sync_guardian_upgrade_panel()
		return

	if event is InputEventMouseMotion:
		var pending_mouse_motion := event as InputEventMouseMotion
		if _update_pending_store_tower_drag(_screen_to_canvas_position(pending_mouse_motion.position)):
			get_viewport().set_input_as_handled()
			return

	if _is_store_tower_dragging(_edr_hunter_store) and event is InputEventMouseMotion:
		var edr_mouse_motion := event as InputEventMouseMotion
		_update_store_tower_drag(_edr_hunter_store, _screen_to_canvas_position(edr_mouse_motion.position))
		return

	if _is_store_tower_dragging(_siem_hawk_store) and event is InputEventMouseMotion:
		var siem_mouse_motion := event as InputEventMouseMotion
		_update_store_tower_drag(_siem_hawk_store, _screen_to_canvas_position(siem_mouse_motion.position))
		return

	if _is_store_tower_dragging(_ips_intrusion_store) and event is InputEventMouseMotion:
		var ips_mouse_motion := event as InputEventMouseMotion
		_update_store_tower_drag(_ips_intrusion_store, _screen_to_canvas_position(ips_mouse_motion.position))
		return

	if _is_store_tower_dragging(_honeypot_production_store) and event is InputEventMouseMotion:
		var honeypot_mouse_motion := event as InputEventMouseMotion
		_update_store_tower_drag(_honeypot_production_store, _screen_to_canvas_position(honeypot_mouse_motion.position))
		return

	if _is_store_tower_dragging(_ids_scanner_store) and event is InputEventMouseMotion:
		var ids_mouse_motion := event as InputEventMouseMotion
		_update_store_tower_drag(_ids_scanner_store, _screen_to_canvas_position(ids_mouse_motion.position))
		return

	if _is_store_tower_dragging(_laser_turret_store) and event is InputEventMouseMotion:
		var laser_mouse_motion := event as InputEventMouseMotion
		_update_store_tower_drag(_laser_turret_store, _screen_to_canvas_position(laser_mouse_motion.position))
		return

	if _is_store_tower_dragging(_guardian_store) and event is InputEventMouseMotion:
		var mouse_motion := event as InputEventMouseMotion
		_update_store_tower_drag(_guardian_store, _screen_to_canvas_position(mouse_motion.position))
		return

	if event is InputEventScreenTouch:
		var screen_touch := event as InputEventScreenTouch
		var pointer_position := _screen_to_canvas_position(screen_touch.position)
		if screen_touch.pressed:
			if _handle_tower_upgrade_sidebar_modal_press(screen_touch.position):
				return

			if _tower_store_toggle_has_point(screen_touch.position):
				return

			if _game_controls_have_point(screen_touch.position):
				return

			if _try_handle_store_card_information_press(pointer_position):
				get_viewport().set_input_as_handled()
				return

			if _try_begin_any_store_tower_drag(pointer_position):
				get_viewport().set_input_as_handled()
				return

			if _tower_store_blocks_point(pointer_position):
				get_viewport().set_input_as_handled()
				return

			if _demo_upgrade_button_has_point(screen_touch.position):
				return

			if _handle_adware_popup_press(pointer_position):
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
		elif _pending_store_drag_tower != null:
			_clear_pending_store_tower_drag()
			get_viewport().set_input_as_handled()
			return
		elif _demo_upgrade_button_has_point(screen_touch.position):
			return
		elif _is_store_tower_dragging(_siem_hawk_store):
			_finish_store_tower_drag(_siem_hawk_store)
		elif _is_store_tower_dragging(_honeypot_production_store):
			_finish_store_tower_drag(_honeypot_production_store)
		elif _is_store_tower_dragging(_ips_intrusion_store):
			_finish_store_tower_drag(_ips_intrusion_store)
		elif _is_store_tower_dragging(_edr_hunter_store):
			_finish_store_tower_drag(_edr_hunter_store)
		elif _is_store_tower_dragging(_ids_scanner_store):
			_finish_store_tower_drag(_ids_scanner_store)
		elif _is_store_tower_dragging(_laser_turret_store):
			_finish_store_tower_drag(_laser_turret_store)
		elif _is_store_tower_dragging(_guardian_store):
			if _finish_store_tower_drag(_guardian_store):
				_apply_guardian_signal_boost_state()
				_sync_guardian_upgrade_panel()
		return

	if event is InputEventScreenDrag:
		var pending_screen_drag := event as InputEventScreenDrag
		if _update_pending_store_tower_drag(_screen_to_canvas_position(pending_screen_drag.position)):
			get_viewport().set_input_as_handled()
			return

	if _is_store_tower_dragging(_edr_hunter_store) and event is InputEventScreenDrag:
		var edr_screen_drag := event as InputEventScreenDrag
		_update_store_tower_drag(_edr_hunter_store, _screen_to_canvas_position(edr_screen_drag.position))
		return

	if _is_store_tower_dragging(_siem_hawk_store) and event is InputEventScreenDrag:
		var siem_screen_drag := event as InputEventScreenDrag
		_update_store_tower_drag(_siem_hawk_store, _screen_to_canvas_position(siem_screen_drag.position))
		return

	if _is_store_tower_dragging(_ips_intrusion_store) and event is InputEventScreenDrag:
		var ips_screen_drag := event as InputEventScreenDrag
		_update_store_tower_drag(_ips_intrusion_store, _screen_to_canvas_position(ips_screen_drag.position))
		return

	if _is_store_tower_dragging(_honeypot_production_store) and event is InputEventScreenDrag:
		var honeypot_screen_drag := event as InputEventScreenDrag
		_update_store_tower_drag(_honeypot_production_store, _screen_to_canvas_position(honeypot_screen_drag.position))
		return

	if _is_store_tower_dragging(_ids_scanner_store) and event is InputEventScreenDrag:
		var ids_screen_drag := event as InputEventScreenDrag
		_update_store_tower_drag(_ids_scanner_store, _screen_to_canvas_position(ids_screen_drag.position))
		return

	if _is_store_tower_dragging(_laser_turret_store) and event is InputEventScreenDrag:
		var laser_screen_drag := event as InputEventScreenDrag
		_update_store_tower_drag(_laser_turret_store, _screen_to_canvas_position(laser_screen_drag.position))
		return

	if _is_store_tower_dragging(_guardian_store) and event is InputEventScreenDrag:
		var screen_drag := event as InputEventScreenDrag
		_update_store_tower_drag(_guardian_store, _screen_to_canvas_position(screen_drag.position))


func _process(delta: float) -> void:
	if _game_over:
		return
	if _is_act_input_locked():
		if _tower_store_canvas != null:
			_tower_store_canvas.hide()
		if _tower_store_toggle_button_authored and _tower_store_toggle_button != null:
			_tower_store_toggle_button.hide()
		_update_fps_timer(delta)
		return

	if _tower_store_canvas != null:
		_tower_store_canvas.show()
	if _tower_store_toggle_button_authored and _tower_store_toggle_button != null:
		_tower_store_toggle_button.show()
	if _tower_store_tween == null:
		_sync_tower_store_items(false)
		_position_tower_store_toggle_button(0.0 if _tower_store_open else STORE_PANEL_SLIDE_DISTANCE)
	_update_wave_spawner(delta)
	_update_adware_spawner(delta)
	_update_active_viruses(delta)
	if _game_over:
		return
	_update_spyware_invasions(delta)
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
	_style_tower_store_panel(store_items)
	_create_tower_store_cards(store_items)
	_layout_tower_store_items(store_items)
	_create_tower_store_toggle_button()
	_sync_tower_store_items(true)


func _get_tower_store_items() -> Array[Dictionary]:
	var items: Array[Dictionary] = []
	_add_tower_store_item(items, _guardian_store, TOWER_ID_CYBER_GUARDIAN, "Cyber Guardian")
	_add_tower_store_item(items, _laser_turret_store, TOWER_ID_LASER_TURRET, "Laser Turret")
	_add_tower_store_item(items, _ids_scanner_store, TOWER_ID_IDS_SCANNER, "IDS Scanner")
	_add_tower_store_item(items, _edr_hunter_store, TOWER_ID_EDR_HUNTER, "EDR Hunter")
	_add_tower_store_item(items, _siem_hawk_store, TOWER_ID_SIEM_HAWK, "SIEM Hawk")
	_add_tower_store_item(items, _ips_intrusion_store, TOWER_ID_IPS_INTRUSION, "IPS Spike")
	_add_tower_store_item(items, _honeypot_production_store, TOWER_ID_HONEYPOT_PRODUCTION, "Honeypot")
	return items


func _add_tower_store_item(items: Array[Dictionary], tower: Node2D, tower_id: StringName, label_text: String) -> void:
	if tower == null:
		return

	var card_resource := _get_tower_card_resource_for_id(tower_id)
	items.append({
		"tower": tower,
		"tower_id": tower_id,
		"label": card_resource.display_name if card_resource != null else label_text,
		"resource": card_resource
	})


func _get_tower_card_resource_for_id(tower_id: StringName) -> TowerShopCardResource:
	var configured_resource := _get_configured_tower_card_resource_for_id(tower_id)
	if configured_resource != null:
		return configured_resource

	for resource in tower_store_card_resources:
		var card_resource := resource as TowerShopCardResource
		if card_resource != null and card_resource.tower_id == tower_id:
			return card_resource

	return DEFAULT_TOWER_CARD_RESOURCES.get(tower_id) as TowerShopCardResource


func _get_configured_tower_card_resource_for_id(tower_id: StringName) -> TowerShopCardResource:
	match tower_id:
		TOWER_ID_CYBER_GUARDIAN:
			return cyber_guardian_card_resource
		TOWER_ID_LASER_TURRET:
			return laser_turret_card_resource
		TOWER_ID_IDS_SCANNER:
			return ids_scanner_card_resource
		TOWER_ID_EDR_HUNTER:
			return edr_hunter_card_resource
		TOWER_ID_SIEM_HAWK:
			return siem_hawk_card_resource
		TOWER_ID_IPS_INTRUSION:
			return ips_intrusion_card_resource
		TOWER_ID_HONEYPOT_PRODUCTION:
			return honeypot_production_card_resource
		_:
			return null


func _layout_tower_store_items(store_items: Array[Dictionary]) -> void:
	var store_rect := _get_store_panel_global_rect(store_items)
	var grid_width := STORE_CARD_SIZE.x * float(STORE_CARD_COLUMNS) + STORE_CARD_GAP.x * float(STORE_CARD_COLUMNS - 1)
	var grid_left := store_rect.position.x + (store_rect.size.x - grid_width) * 0.5
	var grid_top := store_rect.position.y + STORE_CARD_GRID_TOP_OFFSET

	for index in range(store_items.size()):
		var tower := store_items[index]["tower"] as Node2D
		var card := _tower_store_item_cards.get(tower) as Control
		var home_position := Vector2.ZERO
		if card != null:
			home_position = card.get_global_rect().get_center()
		else:
			var column := index % STORE_CARD_COLUMNS
			var row := index / STORE_CARD_COLUMNS
			var card_top_left := Vector2(
				grid_left + float(column) * (STORE_CARD_SIZE.x + STORE_CARD_GAP.x),
				grid_top + float(row) * (STORE_CARD_SIZE.y + STORE_CARD_GAP.y)
			)
			home_position = card_top_left + STORE_CARD_SIZE * 0.5

		_cache_tower_placed_scale(tower)
		_apply_store_display_scale(tower)
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
		_tower_store_background.z_as_relative = false
		_tower_store_background.z_index = STORE_PANEL_Z_INDEX
		return

	if not _tower_store_background_authored:
		_tower_store_background.global_position = store_rect.position
		_tower_store_background.size = store_rect.size
		_tower_store_background.color = Color(0.012, 0.021, 0.041, 0.86)
		_tower_store_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_tower_store_background.z_as_relative = false
		_tower_store_background.z_index = STORE_PANEL_Z_INDEX


func _get_store_panel_global_rect(store_items: Array[Dictionary]) -> Rect2:
	if _tower_store_background != null:
		var existing_rect := _tower_store_background.get_global_rect()
		if existing_rect.size.x > 64.0 and existing_rect.size.y > 64.0:
			return existing_rect

	var authored_card_rect := Rect2()
	var found_authored_card := false
	if _tower_store_panel != null:
		for child in _tower_store_panel.get_children():
			var card := child as TowerShopCard
			if card == null:
				continue

			var card_rect := card.get_global_rect()
			if card_rect.size == Vector2.ZERO:
				continue
			if not found_authored_card:
				authored_card_rect = card_rect
				found_authored_card = true
			else:
				authored_card_rect = authored_card_rect.merge(card_rect)

	if found_authored_card:
		return authored_card_rect.grow_individual(
			STORE_PANEL_PADDING.x,
			STORE_PANEL_PADDING.y,
			STORE_PANEL_PADDING.x,
			STORE_PANEL_PADDING.y
		)

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


func _create_tower_store_cards(store_items: Array[Dictionary]) -> void:
	if _tower_store_title_label == null:
		_tower_store_title_label = _make_store_label("TOWER SHOP", 28, Color(0.74, 0.93, 1.0, 1.0))
		add_child(_tower_store_title_label)
	if _tower_store_hint_label == null:
		_tower_store_hint_label = _make_store_label("Drag a tower onto a platform", 18, Color(0.52, 0.68, 0.82, 1.0))
		add_child(_tower_store_hint_label)

	for item in store_items:
		var tower := item["tower"] as Node2D
		var tower_id := item["tower_id"] as StringName
		var card_resource := item.get("resource") as TowerShopCardResource
		var card := _get_or_create_tower_store_card(tower, tower_id, String(item["label"]))
		if card_resource != null:
			card.card_resource = card_resource
		card.configure(String(item["label"]), _get_default_tower_deploy_cost(tower))
		_cache_tower_store_card_layout(card)
		_tower_store_item_cards[tower] = card

	_position_tower_store_cards()


func _get_or_create_tower_store_card(tower: Node2D, tower_id: StringName, label_text: String) -> TowerShopCard:
	var resource_matched_card := _find_authored_tower_store_card_for_id(tower_id)
	if resource_matched_card != null:
		_prepare_authored_tower_store_card(resource_matched_card)
		return resource_matched_card

	var card_name := _get_tower_store_card_name(tower, label_text)
	var existing_card := _tower_store_panel.get_node_or_null(NodePath(card_name)) as TowerShopCard
	if existing_card != null:
		_prepare_authored_tower_store_card(existing_card)
		return existing_card

	var card := TowerShopCardScene.instantiate() as TowerShopCard
	card.name = card_name
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.z_as_relative = false
	card.z_index = STORE_LABEL_Z_INDEX
	card.set_meta("authored_store_card", false)
	_tower_store_panel.add_child(card)
	return card


func _find_authored_tower_store_card_for_id(tower_id: StringName) -> TowerShopCard:
	if _tower_store_panel == null:
		return null
	for child in _tower_store_panel.get_children():
		var card := child as TowerShopCard
		if card != null and card.card_resource != null and card.card_resource.tower_id == tower_id:
			return card
	return null


func _prepare_authored_tower_store_card(card: TowerShopCard) -> void:
	card.set_meta("authored_store_card", true)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.z_as_relative = false
	card.z_index = STORE_LABEL_Z_INDEX
	card.use_default_information_popup_paths()


func _cache_tower_store_card_layout(card: TowerShopCard) -> void:
	if card == null:
		return
	if bool(card.get_meta("authored_store_card", false)):
		_tower_store_use_authored_card_layout = true
	_tower_store_card_base_rects[card] = card.get_global_rect()


func _get_tower_store_card_name(tower: Node2D, fallback_name: String) -> String:
	if tower == _guardian_store:
		return "CyberGuardianCard"
	if tower == _laser_turret_store:
		return "LaserTurretCard"
	if tower == _ids_scanner_store:
		return "IDSScannerCard"
	if tower == _edr_hunter_store:
		return "EDRHunterCard"
	if tower == _siem_hawk_store:
		return "SIEMHawkCard"
	if tower == _ips_intrusion_store:
		return "IPSIntrusionCard"
	if tower == _honeypot_production_store:
		return "HoneypotProductionCard"
	return fallback_name.replace(" ", "") + "Card"


func _make_store_label(label_text: String, font_size: int, font_color: Color) -> Label:
	var label := Label.new()
	label.text = label_text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.z_as_relative = false
	label.z_index = STORE_LABEL_Z_INDEX
	var store_font := _get_store_font()
	if store_font != null:
		label.add_theme_font_override("font", store_font)
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


func _position_tower_store_cards(slide_offset := 0.0) -> void:
	if _tower_store_base_rect.size == Vector2.ZERO:
		return

	var store_rect := _tower_store_base_rect
	if _tower_store_title_label != null and not _tower_store_title_label_authored:
		_position_store_label(_tower_store_title_label, Vector2(store_rect.position.x + store_rect.size.x * 0.5 + slide_offset, store_rect.position.y + 16.0), Vector2(store_rect.size.x - 34.0, 40.0))
	if _tower_store_hint_label != null and not _tower_store_hint_label_authored:
		_position_store_label(_tower_store_hint_label, Vector2(store_rect.position.x + store_rect.size.x * 0.5 + slide_offset, store_rect.position.y + 58.0), Vector2(store_rect.size.x - 34.0, 30.0))

	var grid_width := STORE_CARD_SIZE.x * float(STORE_CARD_COLUMNS) + STORE_CARD_GAP.x * float(STORE_CARD_COLUMNS - 1)
	var grid_left := store_rect.position.x + (store_rect.size.x - grid_width) * 0.5 + slide_offset
	var grid_top := store_rect.position.y + STORE_CARD_GRID_TOP_OFFSET
	var index := 0
	for item in _get_tower_store_items():
		var tower_node := item["tower"] as Node2D
		var card := _tower_store_item_cards.get(tower_node) as TowerShopCard
		if tower_node == null or card == null:
			continue

		if _tower_store_use_authored_card_layout and _tower_store_card_base_rects.has(card):
			var authored_rect := _tower_store_card_base_rects[card] as Rect2
			_position_store_card(card, authored_rect.position + Vector2(slide_offset, 0), authored_rect.size)
			index += 1
			continue

		var column := index % STORE_CARD_COLUMNS
		var row := index / STORE_CARD_COLUMNS
		var card_top_left := Vector2(
			grid_left + float(column) * (STORE_CARD_SIZE.x + STORE_CARD_GAP.x),
			grid_top + float(row) * (STORE_CARD_SIZE.y + STORE_CARD_GAP.y)
		)
		_position_store_card(card, card_top_left, STORE_CARD_SIZE)
		index += 1


func _position_store_label(label: Label, center_position: Vector2, size: Vector2) -> void:
	label.size = size
	label.global_position = center_position - size * 0.5


func _position_store_label_top_left(label: Label, top_left: Vector2, size: Vector2) -> void:
	label.size = size
	label.global_position = top_left


func _position_store_card(card: Control, top_left: Vector2, size: Vector2) -> void:
	card.size = size
	card.global_position = top_left


func _create_tower_store_toggle_button() -> void:
	if _tower_store_toggle_button != null:
		_configure_tower_store_toggle_button()
		_cache_tower_store_toggle_open_position()
		if not _tower_store_toggle_button.pressed.is_connected(_toggle_tower_store):
			_tower_store_toggle_button.pressed.connect(_toggle_tower_store)
		_position_tower_store_toggle_button(0.0 if _tower_store_open else STORE_PANEL_SLIDE_DISTANCE)
		return

	_tower_store_canvas = CanvasLayer.new()
	_tower_store_canvas.name = "TowerStoreControls"
	_tower_store_canvas.layer = 160
	add_child(_tower_store_canvas)

	_tower_store_toggle_button = Button.new()
	_tower_store_toggle_button.name = "TowerStoreToggleButton"
	_configure_tower_store_toggle_button()
	_tower_store_toggle_button.pressed.connect(_toggle_tower_store)
	_tower_store_canvas.add_child(_tower_store_toggle_button)
	_cache_tower_store_toggle_open_position()
	_position_tower_store_toggle_button(0.0 if _tower_store_open else STORE_PANEL_SLIDE_DISTANCE)


func _configure_tower_store_toggle_button() -> void:
	if _tower_store_toggle_button == null:
		return

	_tower_store_toggle_button.custom_minimum_size = STORE_TOGGLE_SIZE
	_tower_store_toggle_button.size = STORE_TOGGLE_SIZE
	_tower_store_toggle_button.focus_mode = Control.FOCUS_NONE
	_tower_store_toggle_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_tower_store_toggle_button.text = ""
	_tower_store_toggle_button.icon = STORE_TOGGLE_ICON
	_tower_store_toggle_button.expand_icon = true
	_tower_store_toggle_button.add_theme_color_override("icon_normal_color", Color(0.35, 0.8, 1.0, 1.0))
	_tower_store_toggle_button.add_theme_color_override("icon_hover_color", Color(1.0, 0.84, 0.22, 1.0))
	_tower_store_toggle_button.add_theme_color_override("icon_pressed_color", Color(0.98, 0.95, 0.76, 1.0))
	_tower_store_toggle_button.add_theme_color_override("icon_focus_color", Color(0.35, 0.8, 1.0, 1.0))
	var empty_style := StyleBoxEmpty.new()
	_tower_store_toggle_button.add_theme_stylebox_override("normal", empty_style)
	_tower_store_toggle_button.add_theme_stylebox_override("hover", empty_style)
	_tower_store_toggle_button.add_theme_stylebox_override("pressed", empty_style)
	_tower_store_toggle_button.add_theme_stylebox_override("focus", empty_style)
	_update_tower_store_toggle_visual()


func _update_tower_store_toggle_visual() -> void:
	if _tower_store_toggle_button == null:
		return

	_tower_store_toggle_button.tooltip_text = \
		"Hide tower shop" if _tower_store_open else "Show tower shop"


func _cache_tower_store_toggle_open_position() -> void:
	if _tower_store_toggle_button == null or _tower_store_toggle_open_position_cached:
		return

	if _tower_store_toggle_button_authored:
		_tower_store_toggle_open_position = _tower_store_toggle_button.global_position
	else:
		var open_world_position := Vector2(
			_tower_store_base_rect.position.x - STORE_TOGGLE_SIZE.x * 0.5,
			_tower_store_base_rect.get_center().y - STORE_TOGGLE_SIZE.y * 0.5
		)
		_tower_store_toggle_open_position = _world_to_screen_position(open_world_position)
	_tower_store_toggle_open_position_cached = true


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


func _position_tower_store_toggle_button(slide_offset := -1.0) -> void:
	if _tower_store_toggle_button == null or _tower_store_base_rect.size == Vector2.ZERO:
		return
	_cache_tower_store_toggle_open_position()
	if not _tower_store_toggle_open_position_cached:
		return

	var resolved_offset := slide_offset
	if resolved_offset < 0.0:
		resolved_offset = 0.0 if _tower_store_open else STORE_PANEL_SLIDE_DISTANCE
	var slide_ratio := clampf(resolved_offset / STORE_PANEL_SLIDE_DISTANCE, 0.0, 1.0)
	var closed_position := _get_tower_store_toggle_closed_position()
	_tower_store_toggle_button.global_position = _tower_store_toggle_open_position.lerp(closed_position, slide_ratio)
	_tower_store_toggle_button.size = STORE_TOGGLE_SIZE


func _get_tower_store_toggle_closed_position() -> Vector2:
	var viewport_size := get_viewport().get_visible_rect().size
	var closed_screen_position := Vector2(
		viewport_size.x - STORE_TOGGLE_SIZE.x - STORE_TOGGLE_SCREEN_INSET,
		_tower_store_toggle_open_position.y
	)
	if not _tower_store_toggle_button_authored:
		return closed_screen_position

	var open_screen_position := _world_to_screen_position(_tower_store_toggle_open_position)
	closed_screen_position.y = open_screen_position.y
	return _screen_to_canvas_position(closed_screen_position)


func _toggle_tower_store() -> void:
	_set_tower_store_open(not _tower_store_open)


func _set_tower_store_open(is_open: bool) -> void:
	if _tower_store_open == is_open:
		return

	_tower_store_open = is_open
	_update_tower_store_toggle_visual()
	if not _tower_store_open:
		_hide_all_store_card_information()

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


func _cache_store_companion_ui_positions() -> void:
	if not _wave_label_store_position_cached and _wave_label != null:
		_wave_label_store_rest_position = _wave_label.global_position
		_wave_label_store_position_cached = true

	if _cutscene_demo_menu_hud != null and _cutscene_demo_menu_hud.has_method("cache_store_companion_ui_positions"):
		_cutscene_demo_menu_hud.call("cache_store_companion_ui_positions")


func _apply_store_companion_ui_slide(slide_offset: float) -> void:
	_cache_store_companion_ui_positions()
	if _wave_label != null and _wave_label_store_position_cached:
		_wave_label.global_position = _wave_label_store_rest_position + Vector2(slide_offset, 0.0)

	if _cutscene_demo_menu_hud != null and _cutscene_demo_menu_hud.has_method("apply_store_companion_slide"):
		_cutscene_demo_menu_hud.call("apply_store_companion_slide", slide_offset)


func _apply_tower_store_slide(slide_offset: float) -> void:
	if _tower_store_background != null:
		_tower_store_background.global_position = _tower_store_base_rect.position + Vector2(slide_offset, 0)
	if _tower_store_title_label != null:
		_tower_store_title_label.modulate.a = 1.0 - clampf(slide_offset / STORE_PANEL_SLIDE_DISTANCE, 0.0, 1.0)
	if _tower_store_hint_label != null:
		_tower_store_hint_label.modulate.a = 1.0 - clampf(slide_offset / STORE_PANEL_SLIDE_DISTANCE, 0.0, 1.0)

	for tower in _tower_store_home_positions.keys():
		var tower_node := tower as Node2D
		if tower_node == null:
			continue

		var in_store := _is_tower_available_in_store(tower_node)
		var deployed_card := _is_store_card_deployed(tower_node)
		if not in_store and not deployed_card:
			continue

		var alpha := 1.0 - clampf(slide_offset / STORE_PANEL_SLIDE_DISTANCE, 0.0, 1.0)
		if in_store and not _is_store_tower_dragging(tower_node):
			tower_node.global_position = _tower_store_home_positions[tower] + Vector2(slide_offset, 0)
			tower_node.modulate.a = alpha

		var card := _tower_store_item_cards.get(tower_node) as Control
		if card != null:
			card.modulate.a = alpha

	_position_tower_store_cards(slide_offset)
	_position_tower_store_toggle_button(slide_offset)
	_apply_store_companion_ui_slide(slide_offset)


func _sync_tower_store_items(force_positions: bool) -> void:
	for tower in _tower_store_home_positions.keys():
		var tower_node := tower as Node2D
		if tower_node == null:
			continue

		var in_store := _is_tower_available_in_store(tower_node)
		var is_dragging := _is_store_tower_dragging(tower_node)
		var deployed_card := _is_store_card_deployed(tower_node)
		var visible_label := _tower_store_open and (in_store or deployed_card)
		tower_node.visible = is_dragging or not in_store
		tower_node.set_process_input(tower_node.visible)
		if in_store and not is_dragging and force_positions:
			tower_node.global_position = _tower_store_home_positions[tower_node]
			tower_node.modulate.a = 1.0

		var card := _tower_store_item_cards.get(tower_node) as TowerShopCard
		if card != null:
			card.visible = visible_label
			card.modulate.a = 1.0
			card.set_store_state(_can_afford_store_tower(tower_node), deployed_card)

	if _tower_store_background != null:
		_tower_store_background.visible = _tower_store_open
		if _tower_store_open and force_positions:
			_tower_store_background.global_position = _tower_store_base_rect.position

	if _tower_store_title_label != null:
		_tower_store_title_label.visible = _tower_store_open
	if _tower_store_hint_label != null:
		_tower_store_hint_label.visible = _tower_store_open

	if _tower_store_open and force_positions:
		_position_tower_store_cards()

	if force_positions:
		_position_tower_store_toggle_button(0.0 if _tower_store_open else STORE_PANEL_SLIDE_DISTANCE)
		_apply_store_companion_ui_slide(0.0 if _tower_store_open else STORE_PANEL_SLIDE_DISTANCE)


func _hide_available_store_tower_previews() -> void:
	for tower in _tower_store_home_positions.keys():
		var tower_node := tower as Node2D
		if tower_node == null:
			continue
		if not _is_tower_available_in_store(tower_node):
			continue
		if _is_store_tower_dragging(tower_node):
			continue

		tower_node.visible = false
		tower_node.modulate.a = 0.0


func _is_tower_available_in_store(tower: Node) -> bool:
	if tower == _ids_scanner_store and tower.has_method("is_deployed"):
		return not bool(tower.call("is_deployed"))
	if tower.has_method("is_placed"):
		return not bool(tower.call("is_placed"))

	return tower.visible


func _is_store_card_deployed(tower: Node2D) -> bool:
	return tower == _guardian_store \
		and tower != null \
		and tower.has_method("is_placed") \
		and bool(tower.call("is_placed"))


func _can_afford_store_tower(tower: Node2D) -> bool:
	var deploy_cost := _get_tower_deploy_cost(tower)
	if deploy_cost <= 0:
		return true

	return _question_hud != null and _question_hud.can_spend_cyberbucks(deploy_cost)


func _sync_tower_store_card_states() -> void:
	for tower in _tower_store_item_cards.keys():
		var tower_node := tower as Node2D
		var card := _tower_store_item_cards.get(tower_node) as TowerShopCard
		if tower_node == null or card == null:
			continue

		card.set_store_state(_can_afford_store_tower(tower_node), _is_store_card_deployed(tower_node))


func _get_store_visual_nodes() -> Array[CanvasItem]:
	var visual_nodes: Array[CanvasItem] = []
	if _tower_store_background != null:
		visual_nodes.append(_tower_store_background)
	if _tower_store_title_label != null:
		visual_nodes.append(_tower_store_title_label)
	if _tower_store_hint_label != null:
		visual_nodes.append(_tower_store_hint_label)
	for card in _tower_store_item_cards.values():
		if card is CanvasItem:
			visual_nodes.append(card)
	return visual_nodes


func _set_tower_store_home_position(tower: Node2D, home_position: Vector2) -> void:
	tower.set("_home_position", home_position)
	tower.set("_drag_start_position", home_position)
	_sync_tower_scale_dependent_visuals(tower)


func _cache_tower_placed_scale(tower: Node2D) -> void:
	if tower == null or _tower_store_placed_scales.has(tower):
		return

	_tower_store_placed_scales[tower] = tower.scale


func _apply_store_display_scale(tower: Node2D) -> void:
	if tower == null:
		return

	var placed_scale: Vector2 = _tower_store_placed_scales.get(tower, tower.scale)
	tower.scale = placed_scale * STORE_TOWER_DISPLAY_SCALE_MULTIPLIER
	_sync_tower_scale_dependent_visuals(tower)


func _restore_placed_tower_scale(tower: Node2D) -> void:
	if tower == null:
		return

	var placed_scale: Vector2 = _tower_store_placed_scales.get(tower, tower.scale)
	tower.scale = placed_scale
	_sync_tower_scale_dependent_visuals(tower)


func _try_handle_store_card_information_press(pointer_position: Vector2) -> bool:
	if not _tower_store_open:
		return false

	for tower in _get_store_drag_order():
		var tower_node := tower as Node2D
		var card := _tower_store_item_cards.get(tower_node) as TowerShopCard
		if card == null or not card.visible:
			continue
		if not card.information_button_has_point(pointer_position):
			continue

		card.toggle_information_popup()
		_hide_other_store_card_information(card)
		return true

	for tower in _get_store_drag_order():
		var tower_node := tower as Node2D
		var card := _tower_store_item_cards.get(tower_node) as TowerShopCard
		if card != null and card.visible and card.information_popup_has_point(pointer_position):
			return true

	return false


func _try_begin_any_store_tower_drag(pointer_position: Vector2) -> bool:
	for tower in _get_store_drag_order():
		if _try_begin_store_tower_drag(tower as Node2D, pointer_position):
			return true

	return false


func _try_begin_store_tower_drag(tower: Node2D, pointer_position: Vector2) -> bool:
	if not _tower_store_open or tower == null:
		return false

	var card := _tower_store_item_cards.get(tower) as TowerShopCard
	if card == null or not card.visible:
		return false
	if not card.get_global_rect().grow(8.0).has_point(pointer_position):
		return false

	_hide_all_store_card_information()
	if not _is_tower_available_in_store(tower):
		return true
	if not tower.has_method("try_start_drag"):
		return true
	if not _can_afford_store_tower(tower):
		_sync_tower_store_card_states()
		return true

	_pending_store_drag_tower = tower
	_pending_store_drag_start_position = pointer_position
	return true


func _update_pending_store_tower_drag(pointer_position: Vector2) -> bool:
	if _pending_store_drag_tower == null:
		return false
	if pointer_position.distance_to(_pending_store_drag_start_position) < STORE_DRAG_START_THRESHOLD:
		return true

	var tower := _pending_store_drag_tower
	_clear_pending_store_tower_drag()
	if _try_start_store_tower_drag(tower, pointer_position):
		_set_store_card_drag_highlight(tower, true)
	return true


func _clear_pending_store_tower_drag() -> void:
	_pending_store_drag_tower = null
	_pending_store_drag_start_position = Vector2.ZERO


func _get_store_drag_order() -> Array:
	return [
		_ips_intrusion_store,
		_honeypot_production_store,
		_edr_hunter_store,
		_siem_hawk_store,
		_ids_scanner_store,
		_laser_turret_store,
		_guardian_store
	]


func _set_store_card_drag_highlight(tower: Node2D, active: bool) -> void:
	var card := _tower_store_item_cards.get(tower) as TowerShopCard
	if card != null:
		card.set_drag_highlight(active)


func _clear_all_store_card_drag_highlights() -> void:
	for card_value in _tower_store_item_cards.values():
		var card := card_value as TowerShopCard
		if card != null:
			card.set_drag_highlight(false)


func _hide_all_store_card_information() -> void:
	for card_value in _tower_store_item_cards.values():
		var card := card_value as TowerShopCard
		if card != null:
			card.set_information_popup_visible(false)


func _hide_other_store_card_information(active_card: TowerShopCard) -> void:
	for card_value in _tower_store_item_cards.values():
		var card := card_value as TowerShopCard
		if card != null and card != active_card:
			card.set_information_popup_visible(false)


func _tower_store_blocks_point(pointer_position: Vector2) -> bool:
	if not _tower_store_open:
		return false
	if _tower_store_background != null \
			and _tower_store_background.visible \
			and _tower_store_background.get_global_rect().has_point(pointer_position):
		return true

	return _tower_store_base_rect.has_point(pointer_position)


func _game_controls_have_point(screen_position: Vector2) -> bool:
	return _game_controls_hud != null \
		and _game_controls_hud.visible \
		and _game_controls_hud.has_method("has_gameplay_control_at_screen_position") \
		and bool(_game_controls_hud.call("has_gameplay_control_at_screen_position", screen_position))


func _handle_tower_upgrade_sidebar_modal_press(screen_position: Vector2) -> bool:
	if not _tower_upgrade_sidebar_visible():
		return false
	if _tower_upgrade_hud.menu_panel_has_point(screen_position):
		return true

	_close_tower_upgrade_sidebar()
	get_viewport().set_input_as_handled()
	return true


func _tower_upgrade_sidebar_visible() -> bool:
	return _tower_upgrade_hud != null \
		and _tower_upgrade_hud.has_method("is_any_panel_visible") \
		and bool(_tower_upgrade_hud.call("is_any_panel_visible"))


func _prepare_tower_upgrade_sidebar_open() -> void:
	if _tower_upgrade_sidebar_visible():
		if _tower_store_open or _tower_store_tween != null:
			_restore_tower_store_after_upgrade_panel = _restore_tower_store_after_upgrade_panel or _tower_store_open
			_hide_tower_store_for_upgrade_sidebar()
		return

	_restore_tower_store_after_upgrade_panel = _tower_store_open
	if _tower_store_open or _tower_store_tween != null:
		_hide_tower_store_for_upgrade_sidebar()
	else:
		_hide_available_store_tower_previews()


func _hide_tower_store_for_upgrade_sidebar() -> void:
	_tower_store_open = false
	_update_tower_store_toggle_visual()
	_hide_all_store_card_information()
	if _tower_store_tween != null:
		_tower_store_tween.kill()
		_tower_store_tween = null

	_apply_tower_store_slide(STORE_PANEL_SLIDE_DISTANCE)
	_sync_tower_store_items(true)
	_hide_available_store_tower_previews()


func _restore_tower_store_after_upgrade_sidebar_closed() -> void:
	if _tower_upgrade_sidebar_visible():
		return

	if not _restore_tower_store_after_upgrade_panel:
		return

	if _tower_upgrade_sidebar_drawer_visible():
		if _tower_store_restore_after_upgrade_waiting:
			return

		_tower_store_restore_after_upgrade_waiting = true
		await get_tree().create_timer(_get_tower_upgrade_sidebar_restore_delay(), true).timeout
		_tower_store_restore_after_upgrade_waiting = false
		if _tower_upgrade_sidebar_visible():
			return

	if _restore_tower_store_after_upgrade_panel:
		_set_tower_store_open(true)
	_restore_tower_store_after_upgrade_panel = false


func _tower_upgrade_sidebar_drawer_visible() -> bool:
	if _tower_upgrade_hud == null:
		return false

	var menu_panel := _tower_upgrade_hud.get_node_or_null(^"Root/MenuPanel") as Control
	return menu_panel != null and menu_panel.visible


func _get_tower_upgrade_sidebar_restore_delay() -> float:
	if _tower_upgrade_hud == null:
		return 0.24

	var slide_seconds = _tower_upgrade_hud.get("slide_seconds")
	if typeof(slide_seconds) == TYPE_FLOAT or typeof(slide_seconds) == TYPE_INT:
		return maxf(0.01, float(slide_seconds) * 0.86 + 0.03)

	return 0.24


func _close_tower_upgrade_sidebar() -> void:
	if _tower_upgrade_hud == null:
		return

	_tower_upgrade_hud.hide_all()
	_set_tower_menu_radius_previews(false, false, false, false, false, false, false)
	_restore_tower_store_after_upgrade_sidebar_closed()


func _tower_store_toggle_has_point(screen_position: Vector2) -> bool:
	var test_position := _screen_to_canvas_position(screen_position) if _tower_store_toggle_button_authored else screen_position
	return _tower_store_toggle_button != null \
		and _tower_store_toggle_button.visible \
		and _tower_store_toggle_button.get_global_rect().has_point(test_position)


func _try_start_store_tower_drag(tower: Node2D, pointer_position: Vector2) -> bool:
	if not _tower_store_open or tower == null:
		return false
	if not _is_tower_available_in_store(tower):
		return false
	if not tower.has_method("try_start_drag"):
		return false
	if not _can_afford_store_tower(tower):
		_sync_tower_store_card_states()
		return false

	var home_position: Vector2 = _tower_store_home_positions.get(tower, tower.global_position)
	_restore_placed_tower_scale(tower)
	tower.global_position = pointer_position
	tower.visible = true
	tower.modulate.a = 1.0
	_sync_tower_scale_dependent_visuals(tower)
	if not bool(tower.call("try_start_drag", pointer_position)):
		_restore_store_tower_preview(tower)
		_set_store_card_drag_highlight(tower, false)
		return false

	tower.set("_drag_start_position", home_position)
	_set_store_card_drag_highlight(tower, true)
	_update_store_tower_drag(tower, pointer_position)
	return true


func _store_tower_card_has_point(tower: Node2D, pointer_position: Vector2) -> bool:
	var card := _tower_store_item_cards.get(tower) as Control
	return card != null \
		and card.visible \
		and card.get_global_rect().grow(8.0).has_point(pointer_position)


func _restore_store_tower_preview(tower: Node2D) -> void:
	if tower == null:
		return

	if _tower_store_home_positions.has(tower):
		tower.global_position = _tower_store_home_positions[tower]
	_apply_store_display_scale(tower)
	if _is_tower_available_in_store(tower):
		tower.visible = false


func _is_store_tower_dragging(tower: Node2D) -> bool:
	return tower != null \
		and tower.has_method("is_dragging") \
		and bool(tower.call("is_dragging"))


func _update_store_tower_drag(tower: Node2D, pointer_position: Vector2) -> void:
	if tower == null or not tower.has_method("update_drag"):
		return

	_restore_placed_tower_scale(tower)
	tower.call("update_drag", pointer_position)
	if _tower_store_open and not _tower_store_base_rect.has_point(pointer_position):
		_set_tower_store_open(false)


func _finish_store_tower_drag(tower: Node2D) -> bool:
	if tower == null or not tower.has_method("finish_drag"):
		return false

	var deploy_cost := _get_tower_deploy_cost(tower)
	var drop_was_valid := bool(tower.get("_drag_is_valid"))
	var deploy_cost_spent := false
	if drop_was_valid:
		if _spend_deploy_cost(deploy_cost):
			deploy_cost_spent = deploy_cost > 0
		else:
			tower.set("_drag_is_valid", false)

	var was_placed := bool(tower.call("finish_drag"))
	if deploy_cost_spent and not was_placed and _question_hud != null:
		_question_hud.add_cyberbucks(deploy_cost)
	if was_placed:
		_restore_placed_tower_scale(tower)
	else:
		_restore_store_tower_preview(tower)
	_set_store_card_drag_highlight(tower, false)

	return was_placed


func _get_tower_deploy_cost(tower: Node2D) -> int:
	var card := _tower_store_item_cards.get(tower) as TowerShopCard
	if card != null and card.has_card_resource():
		return card.get_deploy_cost()

	return _get_default_tower_deploy_cost(tower)


func _get_default_tower_deploy_cost(tower: Node2D) -> int:
	if tower is LaserTurretScript:
		return LASER_TURRET_DEPLOY_COST
	if tower is IDSScannerTowerScript:
		return IDS_SCANNER_DEPLOY_COST
	if tower is EDRHunterTowerScript:
		return EDR_HUNTER_DEPLOY_COST
	if tower is HoneypotProductionTowerScript:
		return HONEYPOT_PRODUCTION_DEPLOY_COST
	if tower is IPSIntrusionTowerScript:
		return IPS_INTRUSION_DEPLOY_COST
	if tower is SIEMHawkTowerScript:
		return SIEM_HAWK_DEPLOY_COST

	return CYBER_GUARDIAN_DEPLOY_COST


func _spend_deploy_cost(cost: int) -> bool:
	if cost <= 0:
		return true
	if _question_hud == null:
		return false

	return _question_hud.spend_cyberbucks(cost)


func _sync_tower_scale_dependent_visuals(tower: Node2D) -> void:
	if tower.has_method("_sync_base_sprite"):
		tower.call_deferred("_sync_base_sprite")
	if tower.has_method("_sync_level_plates_transform"):
		tower.call_deferred("_sync_level_plates_transform")
	if tower.has_method("_sync_deployed_state"):
		tower.call_deferred("_sync_deployed_state")


func _hide_legacy_store_title() -> void:
	var legacy_title := get_node_or_null(^"Blue Towers") as CanvasItem
	if legacy_title != null:
		legacy_title.hide()

	for child in get_children():
		var label := child as Label
		if label == null:
			continue
		if label.text == "Blue Towers" or label.text == "Blue Guardian Towers":
			label.hide()


func _get_tower_id(tower: Node) -> StringName:
	if tower is HoneypotProductionTowerScript:
		return &"honeypot"
	if tower is IPSIntrusionTowerScript:
		return &"ips"
	if tower is SIEMHawkTowerScript:
		return &"siem"
	if tower is EDRHunterTowerScript:
		return &"edr"
	if tower is IDSScannerTowerScript:
		return &"scanner"
	if tower is LaserTurretScript:
		return &"laser"
	if tower is CyberGuardianTowerScript:
		return &"guardian"
	return &""


func _setup_admin_currency_button() -> void:
	if not _is_admin_scene() or _question_hud == null:
		return

	var canvas := CanvasLayer.new()
	canvas.name = "AdminCurrencyControls"
	canvas.layer = 170
	add_child(canvas)
	_admin_add_bucks_button = Button.new()
	_admin_add_bucks_button.name = "AddCyberBucksButton"
	_admin_add_bucks_button.text = "+%d Cyber Bucks" % ADMIN_CYBERBUCK_GRANT
	_admin_add_bucks_button.tooltip_text = "Admin test control: add Cyber Bucks."
	# Keep this admin-only control below the shared lives counter.
	_admin_add_bucks_button.position = Vector2(24, 224)
	_admin_add_bucks_button.size = Vector2(220, 52)
	_admin_add_bucks_button.focus_mode = Control.FOCUS_NONE
	var store_font := _get_store_font()
	if store_font != null:
		_admin_add_bucks_button.add_theme_font_override("font", store_font)
	_admin_add_bucks_button.add_theme_font_size_override("font_size", 18)
	_admin_add_bucks_button.add_theme_stylebox_override("normal", _make_store_button_style(Color(0.04, 0.14, 0.08, 0.96), Color(0.2, 1.0, 0.48, 1.0)))
	_admin_add_bucks_button.add_theme_stylebox_override("hover", _make_store_button_style(Color(0.07, 0.22, 0.12, 1.0), Color(0.55, 1.0, 0.7, 1.0)))
	_admin_add_bucks_button.pressed.connect(_add_admin_cyberbucks)
	canvas.add_child(_admin_add_bucks_button)


func _add_admin_cyberbucks() -> void:
	if _question_hud != null:
		_question_hud.add_cyberbucks(ADMIN_CYBERBUCK_GRANT)


func _is_admin_scene() -> bool:
	return admin_mode or scene_file_path.ends_with("Admin_Sandbox.tscn")


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
	_connect_placed_guardian(tower)


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
	_restore_placed_tower_scale(tower)
	_guardians.append(tower)
	_guardian = tower
	_connect_placed_guardian(tower)
	_apply_guardian_signal_boost_state()
	_sync_tower_store_items(true)
	_update_demo_upgrade_buttons()


func _on_laser_store_tower_placed(tower: LaserTurretScript) -> void:
	_restore_placed_tower_scale(tower)
	_laser_turrets.append(tower)
	_laser_turret = tower
	_spawn_replacement_laser()
	_update_demo_upgrade_buttons()


func _on_scanner_store_tower_placed(tower: IDSScannerTowerScript) -> void:
	_restore_placed_tower_scale(tower)
	_ids_scanners.append(tower)
	_ids_scanner = tower
	_connect_placed_scanner(tower)
	_spawn_replacement_scanner()
	_update_demo_upgrade_buttons()


func _on_edr_store_tower_placed(tower: EDRHunterTowerScript) -> void:
	_restore_placed_tower_scale(tower)
	_edr_hunters.append(tower)
	_edr_hunter = tower
	_spawn_replacement_edr()
	_update_demo_upgrade_buttons()


func _on_siem_store_tower_placed(tower: SIEMHawkTowerScript) -> void:
	_restore_placed_tower_scale(tower)
	_siem_hawks.append(tower)
	_siem_hawk = tower
	_connect_placed_siem(tower)
	_spawn_replacement_siem()
	_update_demo_upgrade_buttons()


func _on_ips_store_tower_placed(tower: IPSIntrusionTowerScript) -> void:
	_restore_placed_tower_scale(tower)
	_ips_intrusions.append(tower)
	_ips_intrusion = tower
	_connect_placed_ips(tower)
	_spawn_replacement_ips()
	_update_demo_upgrade_buttons()


func _on_honeypot_store_tower_placed(tower: HoneypotProductionTowerScript) -> void:
	_restore_placed_tower_scale(tower)
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
	replacement.visible = false
	parent.add_child(replacement)
	var placed_scale: Vector2 = _tower_store_placed_scales.get(placed_tower, placed_tower.scale)
	replacement.scale = placed_scale
	replacement.global_position = home_position
	_tower_store_placed_scales.erase(placed_tower)
	_tower_store_placed_scales[replacement] = placed_scale
	_apply_store_display_scale(replacement)
	_set_tower_store_home_position(replacement, home_position)
	_tower_store_home_positions.erase(placed_tower)
	_tower_store_home_positions[replacement] = home_position

	var card := _tower_store_item_cards.get(placed_tower) as Control
	if card != null:
		_tower_store_item_cards.erase(placed_tower)
		_tower_store_item_cards[replacement] = card
	_sync_tower_store_items(true)
	return replacement


func _connect_placed_scanner(tower: IDSScannerTowerScript) -> void:
	if tower == null:
		return
	if not tower.virus_damage_requested.is_connected(_on_scanner_virus_damage_requested):
		tower.virus_damage_requested.connect(_on_scanner_virus_damage_requested)
	if not tower.bounty_awarded.is_connected(_on_scanner_bounty_awarded):
		tower.bounty_awarded.connect(_on_scanner_bounty_awarded)


func _connect_placed_guardian(tower: CyberGuardianTowerScript) -> void:
	if tower == null:
		return
	if not tower.mode_changed.is_connected(_on_guardian_mode_changed):
		tower.mode_changed.connect(_on_guardian_mode_changed)
	if tower.has_signal("firewall_damage_requested") \
			and not tower.firewall_damage_requested.is_connected(_on_guardian_firewall_damage_requested):
		tower.firewall_damage_requested.connect(_on_guardian_firewall_damage_requested)


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

	var siem_hawk := _find_siem_headquarters_at_point(pointer_position)
	if siem_hawk != null:
		_siem_hawk = siem_hawk
		_show_siem_upgrade_panel()
		get_viewport().set_input_as_handled()
		return true

	siem_hawk = _find_siem_hawk_body_at_point(pointer_position)
	if siem_hawk != null:
		_siem_hawk = siem_hawk
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


func _find_siem_headquarters_at_point(pointer_position: Vector2) -> SIEMHawkTowerScript:
	for index in range(_siem_hawks.size() - 1, -1, -1):
		var tower := _siem_hawks[index]
		if not is_instance_valid(tower):
			_siem_hawks.remove_at(index)
			continue
		if tower.has_method("contains_headquarters_point") \
				and bool(tower.call("contains_headquarters_point", pointer_position)):
			return tower

	return null


func _find_siem_hawk_body_at_point(pointer_position: Vector2) -> SIEMHawkTowerScript:
	for index in range(_siem_hawks.size() - 1, -1, -1):
		var tower := _siem_hawks[index]
		if not is_instance_valid(tower):
			_siem_hawks.remove_at(index)
			continue
		if tower.has_method("contains_hawk_point") \
				and bool(tower.call("contains_hawk_point", pointer_position)):
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
	if _question_hud != null:
		_question_hud.reset_cyberbucks()
	_apply_guardian_signal_boost_state()
	_set_tower_menu_radius_previews(false, false, false, false, false)
	_clear_pending_store_tower_drag()
	_clear_all_store_card_drag_highlights()
	_sync_tower_store_items(true)
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


func _sell_selected_tower() -> void:
	if _tower_upgrade_hud == null or _question_hud == null:
		return

	var tower := _get_selected_tower() as Node2D
	if tower == null or not is_instance_valid(tower):
		return

	var tower_id := _get_tower_id(tower)
	var refund := roundi(float(_get_default_tower_deploy_cost(tower)) * TOWER_SELL_REFUND_RATE)
	_remove_sold_tower_from_tracking(tower, tower_id)
	_tower_upgrade_hud.hide_all()
	tower.queue_free()
	_question_hud.add_cyberbucks(refund)
	_apply_guardian_signal_boost_state()
	_update_demo_upgrade_buttons()


func _get_selected_tower() -> Node2D:
	if _tower_upgrade_hud.is_guardian_panel_visible():
		return _guardian
	if _tower_upgrade_hud.is_laser_panel_visible():
		return _laser_turret
	if _tower_upgrade_hud.is_scanner_panel_visible():
		return _ids_scanner
	if _tower_upgrade_hud.is_edr_panel_visible():
		return _edr_hunter
	if _tower_upgrade_hud.is_siem_panel_visible():
		return _siem_hawk
	if _tower_upgrade_hud.is_ips_panel_visible():
		return _ips_intrusion
	if _tower_upgrade_hud.is_honeypot_panel_visible():
		return _honeypot_production
	return null


func _remove_sold_tower_from_tracking(tower: Node2D, tower_id: StringName) -> void:
	match tower_id:
		&"guardian":
			_guardians.erase(tower)
			if _guardian == tower:
				_guardian = null
		&"laser":
			_laser_turrets.erase(tower)
			if _laser_turret == tower:
				_laser_turret = null
		&"scanner":
			_ids_scanners.erase(tower)
			if _ids_scanner == tower:
				_ids_scanner = null
		&"edr":
			_edr_hunters.erase(tower)
			if _edr_hunter == tower:
				_edr_hunter = null
		&"siem":
			_siem_hawks.erase(tower)
			if _siem_hawk == tower:
				_siem_hawk = null
		&"ips":
			_ips_intrusions.erase(tower)
			if _ips_intrusion == tower:
				_ips_intrusion = null
		&"honeypot":
			_honeypot_productions.erase(tower)
			if _honeypot_production == tower:
				_honeypot_production = null


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


func _on_guardian_firewall_damage_requested(follow: PathFollow2D, amount: int) -> void:
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
	_sync_tower_store_card_states()


func _on_siem_hawk_knowledge_extracted(amount: int) -> void:
	if _progress_hud == null:
		return

	_progress_hud.add_knowledge_points(amount)
	_apply_guardian_signal_boost_state()
	_sync_all_tower_upgrade_panels()


func _on_guardian_mode_changed(_mode_id: StringName) -> void:
	_apply_guardian_signal_boost_state()
	_sync_all_tower_upgrade_panels()


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

	var siem_action_target := _get_demo_siem_hawk_action_target()
	if siem_action_target != null:
		_siem_hawk = siem_action_target

	var siem_cost := _siem_hawk.get_upgrade_cost() if _siem_hawk != null else 0
	_utility_overlay_hud.set_siem_upgrade_button_state(
		_get_siem_headquarters_screen_position(_siem_hawk),
		_siem_hawk != null and _siem_hawk.is_placed(),
		_siem_hawk != null and _siem_hawk.can_upgrade(),
		_is_demo_siem_upgrade_hovered(),
		siem_cost,
		_can_afford_upgrade(siem_cost)
	)
	if _utility_overlay_hud.has_method("set_siem_hawk_action_state"):
		_utility_overlay_hud.call(
			"set_siem_hawk_action_state",
			_world_to_screen_position(_siem_hawk.global_position) if _siem_hawk != null else Vector2.ZERO,
			_siem_hawk != null and _siem_hawk.is_placed(),
			siem_action_target != null,
			_siem_hawk != null and _siem_hawk.is_dispatched(),
			_siem_hawk != null and _siem_hawk.is_landing_to_headquarters(),
			_siem_hawk != null and _siem_hawk.can_land_to_headquarters()
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
	var knowledge_level := _get_current_knowledge_level()
	var signal_boost_profile := _get_signal_boost_profile(knowledge_level)
	var firewall_profile := _get_firewall_profile(knowledge_level)
	var boost_active := _guardian != null \
		and _guardian.is_placed() \
		and _guardian.get_current_mode_id() == GUARDIAN_MODE_SIGNAL_BOOST \
		and knowledge_level >= SIGNAL_BOOST_UNLOCK_KNOWLEDGE_LEVEL

	for node in get_tree().get_nodes_in_group("Defender"):
		if not is_instance_valid(node) or not is_ancestor_of(node):
			continue
		if node.has_method("set_signal_boost_profile"):
			node.call(
				"set_signal_boost_profile",
				boost_active,
				float(signal_boost_profile["range_multiplier"]),
				float(signal_boost_profile["cooldown_multiplier"]),
				float(signal_boost_profile["hawk_speed_multiplier"])
			)
		elif node.has_method("set_signal_boost_active"):
			node.call("set_signal_boost_active", boost_active)
		if node.has_method("set_firewall_profile"):
			node.call(
				"set_firewall_profile",
				int(firewall_profile["hit_damage"]),
				int(firewall_profile["burn_damage"]),
				float(firewall_profile["burn_tick_seconds"]),
				float(firewall_profile["burn_duration"])
			)


func _get_signal_boost_profile(knowledge_level: int) -> Dictionary:
	var step_count := 0
	for threshold in SIGNAL_BOOST_STEP_LEVELS:
		if knowledge_level >= int(threshold):
			step_count += 1

	var range_bonus := SIGNAL_BOOST_RANGE_BASE_BONUS + float(step_count) * SIGNAL_BOOST_STEP_BONUS
	var cooldown_reduction := SIGNAL_BOOST_COOLDOWN_BASE_REDUCTION + float(step_count) * SIGNAL_BOOST_STEP_BONUS
	var hawk_speed_bonus := SIGNAL_BOOST_HAWK_SPEED_BASE_BONUS + float(step_count) * SIGNAL_BOOST_STEP_BONUS
	return {
		"range_bonus": range_bonus,
		"cooldown_reduction": cooldown_reduction,
		"hawk_speed_bonus": hawk_speed_bonus,
		"range_multiplier": 1.0 + range_bonus,
		"cooldown_multiplier": maxf(0.05, 1.0 - cooldown_reduction),
		"hawk_speed_multiplier": 1.0 + hawk_speed_bonus
	}


func _get_firewall_profile(knowledge_level: int) -> Dictionary:
	var selected_profile: Dictionary = FIREWALL_BALANCE_BY_MIN_KNOWLEDGE_LEVEL[0]
	for profile_value in FIREWALL_BALANCE_BY_MIN_KNOWLEDGE_LEVEL:
		var profile := profile_value as Dictionary
		if knowledge_level >= int(profile["level"]):
			selected_profile = profile

	return {
		"hit_damage": int(selected_profile["hit_damage"]),
		"burn_damage": int(selected_profile["burn_damage"]),
		"burn_tick_seconds": float(selected_profile["burn_tick_seconds"]),
		"burn_duration": FIREWALL_BURN_DURATION_SECONDS
	}


func _get_guardian_sidebar_status_text(knowledge_level: int) -> String:
	if _guardian == null:
		return ""

	var mode_id := _guardian.get_current_mode_id()
	if mode_id == GUARDIAN_MODE_SIGNAL_BOOST:
		var profile := _get_signal_boost_profile(knowledge_level)
		return "Signal Boost Active\nKnowledge LV %d\nAll tower range: +%s\nAll tower cooldown: -%s\nSIEM Hawk speed: +%s" % [
			knowledge_level,
			_format_percent(float(profile["range_bonus"])),
			_format_percent(float(profile["cooldown_reduction"])),
			_format_percent(float(profile["hawk_speed_bonus"]))
		]
	if mode_id == GUARDIAN_MODE_FIREWALL:
		var firewall_profile := _get_firewall_profile(knowledge_level)
		return "Firewall Active\nKnowledge LV %d\nFirewall hit: %d damage\nBurn: %d damage every %.1fs for %.0fs" % [
			knowledge_level,
			int(firewall_profile["hit_damage"]),
			int(firewall_profile["burn_damage"]),
			float(firewall_profile["burn_tick_seconds"]),
			float(firewall_profile["burn_duration"])
		]

	return "Defender Mode\nOffensive guardian fire is active.\nSignal Boost unlocks at Knowledge LV%d.\nFirewall unlocks at Knowledge LV%d." % [
		SIGNAL_BOOST_UNLOCK_KNOWLEDGE_LEVEL,
		FIREWALL_UNLOCK_KNOWLEDGE_LEVEL
	]


func _format_percent(value: float) -> String:
	return "%d%%" % roundi(value * 100.0)


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
		_guardian.get_mode_unlock_levels(),
		_get_guardian_sidebar_status_text(knowledge_level)
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
	if _current_wave == ARMORED_VIRUS_TEST_WAVE:
		_spawn_evolved_virus(ArmoredVirusScene, "ArmoredVirus", DEFAULT_EVOLVED_VIRUS_SPAWN_SCALE)
	if _current_wave == SPYWARE_TEST_WAVE:
		_spawn_spyware()
	if _current_wave == ADWARE_WAVE:
		_begin_adware_wave_spawn()
	if _current_wave == MUTANT_VIRUS_TEST_WAVE:
		_spawn_evolved_virus(MutantVirusScene, "MutantVirus", DEFAULT_EVOLVED_VIRUS_SPAWN_SCALE)


func _should_play_wave_five_cutscene() -> bool:
	return not _is_admin_scene() \
		and not _wave_five_cutscene_played \
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
	_adware_spawns_remaining = 0
	_adware_spawn_cooldown_remaining = 0.0
	_adware_spawned_count = 0
	_rebuild_adware_variation_deck()
	_spawn_adware_miniboss()


func _update_adware_spawner(delta: float) -> void:
	_prune_adware_popups()
	if _adware_spawns_remaining <= 0:
		return

	_adware_spawn_cooldown_remaining -= delta
	if _adware_spawn_cooldown_remaining > 0.0:
		return

	_spawn_adware_miniboss()
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


func _on_phishing_decoy_selected() -> void:
	spawn_virus_batch(100)


func _exit_game() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/Menus/MainMenu.tscn")


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


func _spawn_evolved_virus(scene: PackedScene, virus_name: String, spawn_scale: Vector2) -> void:
	if _virus_path == null or _virus_path.curve == null:
		push_warning("Cannot spawn %s because VirusElements/Path2D is missing a curve." % virus_name)
		return
	if scene == null:
		push_warning("Cannot spawn %s because the configured scene is missing." % virus_name)
		return

	var virus := scene.instantiate() as RedVirusScript
	if virus == null:
		push_warning("Cannot spawn %s because the configured scene is invalid." % virus_name)
		return

	var follow := PathFollow2D.new()
	follow.name = "Spawned%sFollow" % virus_name
	follow.loop = false
	follow.progress = _get_virus_spawn_progress()
	_virus_path.add_child(follow)

	virus.name = "Spawned%s" % virus_name
	virus.position = Vector2.ZERO
	follow.add_child(virus)
	virus.global_scale = spawn_scale
	virus.reset_for_spawn()

	_active_viruses.append(follow)
	_update_virus_count_label()


func _spawn_adware_miniboss() -> void:
	if _virus_path == null or _virus_path.curve == null:
		push_warning("Cannot spawn Adware because VirusElements/Path2D is missing a curve.")
		return

	var adware := AdwareScene.instantiate() as Adware
	if adware == null:
		push_warning("Cannot spawn adware because the configured scene is invalid.")
		return

	var follow := PathFollow2D.new()
	follow.name = "SpawnedAdwareFollow"
	follow.loop = false
	follow.progress = _get_virus_spawn_progress()
	_virus_path.add_child(follow)

	adware.name = "SpawnedAdware"
	adware.position = Vector2.ZERO
	follow.add_child(adware)
	adware.global_scale = DEFAULT_ADWARE_SPAWN_SCALE
	adware.reset_for_spawn()
	adware.start_popup_burst(
		_adware_variation_deck.duplicate(),
		ADWARE_POPUP_COUNT,
		ADWARE_POPUP_INTERVAL,
		_get_adware_popup_anchor_candidates()
	)

	_active_viruses.append(follow)
	_update_virus_count_label()


func _spawn_spyware() -> void:
	if _virus_path == null or _virus_path.curve == null:
		push_warning("Cannot spawn Spyware because VirusElements/Path2D is missing a curve.")
		return
	if _get_active_spyware_count() >= SPYWARE_MAX_ACTIVE:
		return

	var spyware := SpywareScene.instantiate() as SpywareScript
	if spyware == null:
		push_warning("Cannot spawn Spyware because the configured scene is invalid.")
		return

	var follow := PathFollow2D.new()
	follow.name = "SpawnedSpywareFollow"
	follow.loop = false
	follow.progress = _get_virus_spawn_progress()
	_virus_path.add_child(follow)

	spyware.name = "SpawnedSpyware"
	spyware.position = Vector2.ZERO
	follow.add_child(spyware)
	spyware.reset_for_spawn()
	_connect_spyware(spyware)

	_active_viruses.append(follow)
	_update_virus_count_label()


func _get_active_spyware_count() -> int:
	var active_count := 0
	for follow in _active_viruses:
		if not is_instance_valid(follow):
			continue
		if _get_red_virus(follow) is SpywareScript:
			active_count += 1
	return active_count


func _connect_spyware(spyware: SpywareScript) -> void:
	if spyware == null:
		return
	if not spyware.knowledge_steal_requested.is_connected(_on_spyware_knowledge_steal_requested):
		spyware.knowledge_steal_requested.connect(_on_spyware_knowledge_steal_requested)
	if not spyware.knowledge_recovery_requested.is_connected(_on_spyware_knowledge_recovery_requested):
		spyware.knowledge_recovery_requested.connect(_on_spyware_knowledge_recovery_requested)
	if not spyware.knowledge_exfiltrated.is_connected(_on_spyware_knowledge_exfiltrated):
		spyware.knowledge_exfiltrated.connect(_on_spyware_knowledge_exfiltrated)


func _on_spyware_knowledge_steal_requested(spyware: SpywareScript, amount: int) -> void:
	if not is_instance_valid(spyware) or _progress_hud == null:
		return

	var stolen_amount := _progress_hud.steal_knowledge_points(amount)
	spyware.accept_stolen_knowledge(stolen_amount)


func _on_spyware_knowledge_recovery_requested(_spyware: SpywareScript, amount: int) -> void:
	if _progress_hud == null or amount <= 0:
		return

	_progress_hud.restore_knowledge_points(amount)
	_apply_guardian_signal_boost_state()
	_sync_all_tower_upgrade_panels()


func _on_spyware_knowledge_exfiltrated(_spyware: SpywareScript, amount: int) -> void:
	if amount > 0:
		print("Spyware exfiltrated %d Knowledge Points." % amount)


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


func _handle_adware_popup_press(pointer_position: Vector2) -> bool:
	for index in range(_active_viruses.size() - 1, -1, -1):
		var follow := _active_viruses[index]
		if not is_instance_valid(follow):
			continue

		var adware := _get_red_virus(follow) as Adware
		if adware == null:
			continue
		if not adware.try_press_popup_close_at(pointer_position):
			continue

		get_viewport().set_input_as_handled()
		return true

	return false


func _get_adware_popup_anchor_candidates() -> Array[Node2D]:
	var candidates: Array[Node2D] = []
	_append_adware_popup_anchor_candidates(candidates, _guardians)
	_append_adware_popup_anchor_candidates(candidates, _laser_turrets)
	_append_adware_popup_anchor_candidates(candidates, _ids_scanners)
	_append_adware_popup_anchor_candidates(candidates, _edr_hunters)
	_append_adware_popup_anchor_candidates(candidates, _siem_hawks)
	_append_adware_popup_anchor_candidates(candidates, _ips_intrusions)
	_append_adware_popup_anchor_candidates(candidates, _honeypot_productions)
	return candidates


func _append_adware_popup_anchor_candidates(candidates: Array[Node2D], towers: Array) -> void:
	for tower_value in towers:
		var tower := tower_value as Node2D
		if not is_instance_valid(tower):
			continue
		if tower.has_method("is_placed") and not bool(tower.call("is_placed")):
			continue
		if tower.has_method("is_deployed") and not bool(tower.call("is_deployed")):
			continue

		candidates.append(tower)


func _rebuild_adware_variation_deck() -> void:
	_adware_variation_deck.clear()
	var target_deck_size := maxi(ADWARE_POPUP_COUNT, ADWARE_VARIATION_COUNT)
	while _adware_variation_deck.size() < target_deck_size:
		for variation_index in range(ADWARE_VARIATION_COUNT):
			_adware_variation_deck.append(variation_index)
			if _adware_variation_deck.size() >= target_deck_size:
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

		var virus := _get_red_virus(follow)
		if virus != null \
				and virus.has_method("uses_path_movement") \
				and not bool(virus.call("uses_path_movement")):
			continue

		follow.progress += _get_virus_speed(follow) * delta
		if follow.progress >= path_length:
			var escaping_virus := _get_red_virus(follow)
			if escaping_virus != null and escaping_virus.has_method("on_path_escaped"):
				escaping_virus.call("on_path_escaped")
			_despawn_virus(follow, false)
			_lose_life()
			count_changed = true

	if count_changed:
		_update_virus_count_label()


func _lose_life(amount: int = 1) -> void:
	if _game_over or amount <= 0:
		return
	_lives = maxi(0, _lives - amount)
	_update_lives_display()
	if _lives <= 0:
		_game_over = true
		call_deferred("_return_to_main_menu_after_defeat")


func _update_lives_display() -> void:
	if _game_controls_hud != null:
		_game_controls_hud.set_lives(_lives, maxi(1, starting_lives))


func _return_to_main_menu_after_defeat() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/Menus/MainMenu.tscn")


func _update_spyware_invasions(delta: float) -> void:
	var eligible_towers := _get_spyware_invasion_targets()
	for follow in _active_viruses:
		if not is_instance_valid(follow):
			continue
		var spyware := _get_red_virus(follow) as SpywareScript
		if spyware != null:
			spyware.update_invasion(delta, eligible_towers)


func _get_spyware_invasion_targets() -> Array[Node2D]:
	var eligible_towers: Array[Node2D] = []
	_append_placed_spyware_targets(eligible_towers, _laser_turrets)
	_append_placed_spyware_targets(eligible_towers, _siem_hawks)
	_append_placed_spyware_targets(eligible_towers, _ips_intrusions)
	_append_placed_spyware_targets(eligible_towers, _honeypot_productions)
	return eligible_towers


func _append_placed_spyware_targets(targets: Array[Node2D], towers: Array) -> void:
	for tower_value in towers:
		var tower := tower_value as Node2D
		if not is_instance_valid(tower):
			continue
		if not tower.has_method("is_placed") or not bool(tower.call("is_placed")):
			continue
		targets.append(tower)


func _update_tower_attack(delta: float) -> void:
	for guardian in _guardians:
		if not is_instance_valid(guardian):
			continue
		if guardian.has_method("update_firewall"):
			guardian.call("update_firewall", delta, _active_viruses)
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
	var destroyed_reward := 0
	for target in targets:
		if not is_instance_valid(target):
			continue

		var target_position := _get_target_center(target)
		var target_reward := _get_virus_destroy_reward(_get_red_virus(target))
		laser_turret.aim_at(target_position)
		if _should_use_demo_laser_turret_beam_fx(laser_turret):
			if not laser_turret.spawn_beam_fx(target_position, self):
				_spawn_colored_laser(origin_position, target_position, laser_color, laser_width)
		else:
			_spawn_colored_laser(origin_position, target_position, laser_color, laser_width)
		if _damage_virus(target, _laser_turret.get_shot_power(), false):
			destroyed_count += 1
			destroyed_reward += target_reward

	if destroyed_count > 0:
		if _utility_overlay_hud != null:
			_utility_overlay_hud.show_tower_destroy_popup(
				_world_to_screen_position(laser_turret.global_position),
				destroyed_reward,
				laser_turret.get_shot_power(),
				laser_turret.get_shot_cooldown()
			)
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


func _get_virus_destroy_reward(virus: RedVirusScript) -> int:
	if virus == null:
		return 0
	if virus.has_method("get_cyberbuck_reward"):
		return int(virus.call("get_cyberbuck_reward"))

	return maxi(0, virus.cyberbuck_reward)


func _award_virus_destroy_reward(virus: RedVirusScript) -> int:
	var reward := _get_virus_destroy_reward(virus)
	if reward <= 0 or _question_hud == null:
		return 0

	_question_hud.add_cyberbucks(reward)
	_sync_economy_upgrade_panels()
	return reward


func _sync_economy_upgrade_panels() -> void:
	_sync_laser_upgrade_panel()
	_sync_scanner_upgrade_panel()
	_sync_edr_upgrade_panel()
	_sync_siem_upgrade_panel()
	_sync_ips_upgrade_panel()
	_sync_honeypot_upgrade_panel()


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
		_award_virus_destroy_reward(virus)
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


func _get_siem_headquarters_screen_position(siem_hawk: SIEMHawkTowerScript) -> Vector2:
	if siem_hawk == null:
		return Vector2.ZERO
	if siem_hawk.has_method("get_headquarters_position"):
		return _world_to_screen_position(siem_hawk.call("get_headquarters_position") as Vector2)

	return _world_to_screen_position(siem_hawk.global_position)


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


func _demo_siem_hawk_action_buttons_has_point(screen_position: Vector2) -> bool:
	return _utility_overlay_hud != null \
		and _utility_overlay_hud.has_method("siem_hawk_action_buttons_has_point") \
		and bool(_utility_overlay_hud.call("siem_hawk_action_buttons_has_point", screen_position))


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
	return _siem_hawk.contains_headquarters_point(mouse_world_position) \
		or _demo_siem_upgrade_button_has_point(mouse_screen_position)


func _get_demo_siem_hawk_action_target() -> SIEMHawkTowerScript:
	var mouse_screen_position := get_viewport().get_mouse_position()
	if _siem_hawk != null \
			and _siem_hawk.is_placed() \
			and _siem_hawk.is_airborne_control_available() \
			and _demo_siem_hawk_action_buttons_has_point(mouse_screen_position):
		return _siem_hawk

	var mouse_world_position := _screen_to_canvas_position(mouse_screen_position)
	var hovered_hawk := _find_siem_hawk_body_at_point(mouse_world_position)
	if hovered_hawk != null and hovered_hawk.is_airborne_control_available():
		return hovered_hawk

	return null


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

	_prepare_tower_upgrade_sidebar_open()
	_set_tower_menu_radius_previews(true, false, false, false, false)
	_tower_upgrade_hud.show_guardian_panel()
	_sync_guardian_upgrade_panel()


func _hide_upgrade_panel() -> void:
	if _tower_upgrade_hud == null:
		return

	_tower_upgrade_hud.hide_guardian_panel()
	if not _tower_upgrade_hud.is_guardian_panel_visible():
		_set_tower_menu_radius_previews(false, _tower_upgrade_hud.is_laser_panel_visible(), _tower_upgrade_hud.is_scanner_panel_visible(), _tower_upgrade_hud.is_edr_panel_visible(), _tower_upgrade_hud.is_siem_panel_visible())
	_restore_tower_store_after_upgrade_sidebar_closed()


func _show_laser_upgrade_panel() -> void:
	if _tower_upgrade_hud == null or _laser_turret == null:
		return

	_prepare_tower_upgrade_sidebar_open()
	_sync_laser_upgrade_panel()
	_set_tower_menu_radius_previews(false, true, false, false, false)
	_tower_upgrade_hud.show_laser_panel()


func _hide_laser_upgrade_panel() -> void:
	if _tower_upgrade_hud == null:
		return

	_tower_upgrade_hud.hide_laser_panel()
	if not _tower_upgrade_hud.is_laser_panel_visible():
		_set_tower_menu_radius_previews(_tower_upgrade_hud.is_guardian_panel_visible(), false, _tower_upgrade_hud.is_scanner_panel_visible(), _tower_upgrade_hud.is_edr_panel_visible(), _tower_upgrade_hud.is_siem_panel_visible())
	_restore_tower_store_after_upgrade_sidebar_closed()


func _show_scanner_upgrade_panel() -> void:
	if _tower_upgrade_hud == null or _ids_scanner == null:
		return

	_prepare_tower_upgrade_sidebar_open()
	_sync_scanner_upgrade_panel()
	_set_tower_menu_radius_previews(false, false, true, false, false)
	_tower_upgrade_hud.show_scanner_panel()


func _hide_scanner_upgrade_panel() -> void:
	if _tower_upgrade_hud == null:
		return

	_tower_upgrade_hud.hide_scanner_panel()
	if not _tower_upgrade_hud.is_scanner_panel_visible():
		_set_tower_menu_radius_previews(_tower_upgrade_hud.is_guardian_panel_visible(), _tower_upgrade_hud.is_laser_panel_visible(), false, _tower_upgrade_hud.is_edr_panel_visible(), _tower_upgrade_hud.is_siem_panel_visible())
	_restore_tower_store_after_upgrade_sidebar_closed()


func _show_edr_upgrade_panel() -> void:
	if _tower_upgrade_hud == null or _edr_hunter == null:
		return

	_prepare_tower_upgrade_sidebar_open()
	_set_tower_menu_radius_previews(false, false, false, true, false)
	_tower_upgrade_hud.show_edr_panel()
	_sync_edr_upgrade_panel()


func _hide_edr_upgrade_panel() -> void:
	if _tower_upgrade_hud == null:
		return

	_tower_upgrade_hud.hide_edr_panel()
	if not _tower_upgrade_hud.is_edr_panel_visible():
		_set_tower_menu_radius_previews(_tower_upgrade_hud.is_guardian_panel_visible(), _tower_upgrade_hud.is_laser_panel_visible(), _tower_upgrade_hud.is_scanner_panel_visible(), false, _tower_upgrade_hud.is_siem_panel_visible())
	_restore_tower_store_after_upgrade_sidebar_closed()


func _show_siem_upgrade_panel() -> void:
	if _tower_upgrade_hud == null or _siem_hawk == null:
		return

	_prepare_tower_upgrade_sidebar_open()
	_set_tower_menu_radius_previews(false, false, false, false, true)
	_tower_upgrade_hud.show_siem_panel()
	_sync_siem_upgrade_panel()


func _hide_siem_upgrade_panel() -> void:
	if _tower_upgrade_hud == null:
		return

	_tower_upgrade_hud.hide_siem_panel()
	if not _tower_upgrade_hud.is_siem_panel_visible():
		_set_tower_menu_radius_previews(_tower_upgrade_hud.is_guardian_panel_visible(), _tower_upgrade_hud.is_laser_panel_visible(), _tower_upgrade_hud.is_scanner_panel_visible(), _tower_upgrade_hud.is_edr_panel_visible(), false)
	_restore_tower_store_after_upgrade_sidebar_closed()


func _show_ips_upgrade_panel() -> void:
	if _tower_upgrade_hud == null or _ips_intrusion == null:
		return

	_prepare_tower_upgrade_sidebar_open()
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
	_restore_tower_store_after_upgrade_sidebar_closed()


func _show_honeypot_upgrade_panel() -> void:
	if _tower_upgrade_hud == null or _honeypot_production == null:
		return

	_prepare_tower_upgrade_sidebar_open()
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
	_restore_tower_store_after_upgrade_sidebar_closed()


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
