class_name TextCutsceneHUD
extends CanvasLayer

const CentralAudioResolver := preload("res://Scripts/Audio/audio_player_resolver.gd")
const CYBER_BUSINESS_SOUNDTRACK := preload("res://assets/soundtrack/Cyber-Business-Soundtrack.wav")

signal act_started(act_number: int)
signal phase_started(act_number: int, phase_name: StringName)
signal phase_finished(act_number: int, phase_name: StringName)
signal cutscene_finished

const ACT_ONE := 1
const ACT_WAVE_FIVE := 5
const ACT_WAVE_TEN := 10
const ACT_WAVE_ELEVEN := 11
const ACT_WAVE_FIFTEEN := 15
const ACT_WAVE_TWENTY := 20
const ACT_WAVE_TWENTY_FIVE := 25
const ACT_WAVE_TWENTY_FIVE_DEFEAT := 251
const ACT_ZOMBIE_NODE_DEFEAT := 150
const ACT_WORM_BOSS_DEFEAT := 200
const PHASE_ONE := &"phase_1"
const PHASE_TWO := &"phase_2"
const PHASE_THREE := &"phase_3"
const PHASE_FOUR := &"phase_4"
const PHASE_END := &"phase_end"

@export var play_on_ready := true
@export var cutscene_skip_hud_path: NodePath = ^"../CutsceneSkipHUD"
@export var game_controls_hud_path: NodePath = ^"../GameControlsHUD"
@export var gameplay_soundtrack_path: NodePath = ^"../Music/CyberBusiness"
@export var dialogue_lines: PackedStringArray = [
	"Our hardware is under attack! Help me defeat the viruses and save our CPU!",
	"Deploy cybersecurity towers onto safe platforms and stop the viruses before they breach the system!",
	"After each wave, answer the security challenge to earn more Cyber Bucks! I will guide you through the first defense!"
]
@export_group("Act 1 Phase 1")
@export var cutscene_camera_path: NodePath = ^"../CutsceneCamera"
@export var phase_one_target_path: NodePath = ^"../Otherground_Cutscene"
@export var phase_one_attack_target_path: NodePath = ^"../VirusElements/SpawnVirus"
@export_range(0.2, 8.0, 0.05) var red_alert_duration := 3.0
@export_range(0.2, 5.0, 0.05) var camera_pan_duration := 1.35
@export_range(0.5, 8.0, 0.05) var enemy_hold_duration := 3.0
@export_range(0.3, 6.0, 0.05) var enemy_attack_duration := 2.4
@export_range(0.1, 2.0, 0.05) var enemy_disappear_duration := 0.35
@export_range(0.2, 5.0, 0.05) var camera_return_duration := 1.2
@export_range(0.25, 4.0, 0.05) var phase_one_camera_zoom := 2.0
@export_range(2.0, 80.0, 1.0) var phase_one_virus_hover_distance := 18.0
@export_range(0.1, 2.0, 0.05) var phase_one_virus_hover_half_duration := 0.48
@export_range(0.0, 80.0, 1.0) var phase_one_virus_drift_distance := 26.0
@export_range(0.0, 1.0, 0.01) var second_virus_destroy_sfx_delay := 0.2
@export var enemy_camera_padding := Vector2(0, -40)
@export var entrance_camera_padding := Vector2(260, -40)
@export var red_alert_color := Color(1.0, 0.025, 0.025, 0.48)
@export_group("Act 1 Phase 2")
@export_range(8.0, 120.0, 1.0) var characters_per_second := 80.0
@export_range(0.1, 2.0, 0.01) var entry_duration := 0.72
@export_range(0.1, 2.0, 0.01) var exit_duration := 0.52
@export_range(40.0, 1400.0, 1.0) var text_box_slide_distance := 620.0
@export_range(40.0, 1400.0, 1.0) var mascot_slide_distance := 720.0
@export_range(2.0, 60.0, 1.0) var mascot_bob_distance := 18.0
@export_range(0.05, 0.8, 0.01) var mascot_bob_half_duration := 0.18
@export var dim_color := Color(0.055, 0.06, 0.075, 0.76)
@export_group("Wave 5 Cutscene")
@export var wave5_trojan_preview_path: NodePath = ^"../Otherground_Cutscene/CutsceneBack/Wave5CutsceneTrojanHorse"
@export_range(0.2, 6.0, 0.05) var wave5_trojan_hold_duration := 1.4
@export_range(0.2, 5.0, 0.05) var wave5_invisible_hold_duration := 1.0
@export var wave5_phase_two_lines: PackedStringArray = [
	"Watch out! A Trojan horse has entered the network! It hides inside normal traffic, then turns invisible so most towers cannot target it."
]
@export var wave5_phase_four_lines: PackedStringArray = [
	"Use the IDS Scanner to reveal the camouflaged Trojan horse! Once it is detected, your defenses can lock on and destroy it!"
]
@export_group("Wave 10 Ransomware Cutscene")
@export_range(0.0, 3.0, 0.05) var wave10_reveal_hold_duration := 0.75
@export_range(1.0, 4.0, 0.05) var wave10_camera_zoom := 2.25
@export var wave10_phase_two_lines: PackedStringArray = [
	"I have been hit with ransomware! My systems are encrypted, and my deletion timer is already running!",
	"Destroy the Ransomware before the countdown ends, or open my sidebar and pay the ransom! If the lock completes, I will be deleted and we will lose 500 Cyber Bucks!"
]
@export_group("Wave 11 Zombie Node Cutscene")
@export var wave11_zombie_node_path: NodePath = ^"../ZombieNode"
@export_range(0.0, 3.0, 0.05) var wave11_reveal_hold_duration := 0.65
@export var wave11_phase_two_lines: PackedStringArray = [
	"Warning! The Zombie Node is a progressive virus! It evolves as the waves advance, becoming a stronger threat at each new stage.",
	"Track its evolution carefully! The longer it remains in the network, the more dangerous its next form will become!"
]
@export_group("Wave 15 Zombie Node Cutscene")
@export_range(1.0, 8.0, 0.1) var wave15_focus_duration := 3.0
@export_range(1.0, 4.0, 0.05) var wave15_camera_zoom := 2.25
@export var wave15_phase_two_lines: PackedStringArray = [
	"The Zombie Node has fully transformed! Its pipes are loose from the CPU, exposing the core to direct fire!",
	"Only towers whose range reaches the core can damage it! Bring down the Zombie Node before its minion output overwhelms the network!"
]
@export_group("Zombie Node Defeat Cutscene")
@export_range(1.0, 10.0, 0.1) var zombie_defeat_focus_duration := 5.0
@export_range(1.0, 4.0, 0.05) var zombie_defeat_camera_zoom := 2.5
@export var zombie_defeat_phase_two_lines: PackedStringArray = [
	"We defeated the Zombie Node! But there is more work to be done to defend the data!"
]
@export_group("Wave 20 Cyber Worm Cutscene")
@export var wave20_worm_boss_path: NodePath = ^"../WormBoss"
@export var wave20_alternate_map_path: NodePath = ^"../Otherground_Cutscene"
@export_range(0.2, 6.0, 0.05) var wave20_focus_duration := 1.6
@export_range(0.5, 3.0, 0.05) var wave20_camera_zoom := 1.25
@export var wave20_phase_two_lines: PackedStringArray = [
	"That is the Cyber Worm! Its armored head and tail deflect every hit, but its five body segments share a vulnerable core!",
	"Every offensive tower will prioritize the closest Worm segment inside its range! Keep firing until a body segment moves closer than its shields!",
	"The Cyber Worm has 950 integrity and moves as slowly as a Trojan horse, but it is built to absorb sustained fire!"
]
@export_group("Wave 25 Final Boss Cutscene")
@export var wave25_botnet_node_path: NodePath = ^"../BotnetNode"
@export var wave25_worm_boss_path: NodePath = ^"../WormBoss"
@export_range(0.2, 6.0, 0.05) var wave25_botnet_pan_duration := 1.5
@export_range(1.0, 4.0, 0.05) var wave25_botnet_camera_zoom := 1.85
@export_range(1.0, 5.0, 0.05) var wave25_deep_camera_zoom := 2.65
@export_range(2.0, 24.0, 0.25) var wave25_reveal_zoom_duration := 12.0
@export_range(0.0, 4.0, 0.05) var wave25_anti_departure_hold_duration := 1.0
@export_range(0.2, 6.0, 0.05) var wave25_worm_pan_duration := 1.65
@export_range(0.5, 3.0, 0.05) var wave25_worm_camera_zoom := 1.3
@export var wave25_warning_lines: PackedStringArray = [
	"Oh no, something is happening!-"
]
@export var wave25_strategy_lines: PackedStringArray = [
	"The Anti-Cyberguardian linked the Botnet to the Cyber Worm! Destroy the 500-integrity Botnet first!",
	"The Worm has 2,000 integrity, and every body segment is completely invincible until the Botnet falls! Focus all available fire on the Botnet!"
]
@export_group("Wave 25 Anti-Cyberguardian Defeat")
@export var wave25_defeat_focus_target_path: NodePath = ^"../BotnetNode"
@export_range(0.2, 6.0, 0.05) var wave25_defeat_pan_duration := 1.4
@export_range(1.0, 5.0, 0.05) var wave25_defeat_camera_zoom := 2.4
@export_group("Cyber Worm Defeat Cutscene")
@export var worm_defeat_phase_two_lines: PackedStringArray = [
	"We did it! The CPU is safe! We destroyed the Cyber Worm before it could consume our data!",
	"The core is secure again, but we must stay ready for whatever threat comes next!"
]
@export_group("")

@onready var _root: Control = $Root
@onready var _dim_overlay: ColorRect = $Root/DimOverlay
@onready var _alert_overlay: ColorRect = $Root/AlertOverlay
@onready var _dialogue_panel: Control = $Root/DialoguePanel
@onready var _mascot: Control = $Root/Mascot
@onready var _speaker_label: Label = $Root/DialoguePanel/Margin/Content/SpeakerLabel
@onready var _dialogue_label: Label = $Root/DialoguePanel/Margin/Content/DialogueLabel
@onready var _continue_button: Button = $Root/DialoguePanel/Margin/Content/Footer/ContinueButton
var _alarm_cutscene_fx: AudioStreamPlayer
var _virus_destroy_sfx_1: AudioStreamPlayer
var _virus_destroy_sfx_2: AudioStreamPlayer
var _gameplay_soundtrack: AudioStreamPlayer

var current_act := 0
var current_phase: StringName = &""
var _current_phase_finished := false
var _line_index := 0
var _active_dialogue_lines: PackedStringArray = []
var _dialogue_completes_cutscene := true
var _dialogue_phase_done := false
var _typing := false
var _skip_typing := false
var _running := false
var _panel_final_global_position := Vector2.ZERO
var _mascot_final_global_position := Vector2.ZERO
var _mascot_bob_tween: Tween
var _cutscene_camera: Camera2D
var _game_controls_hud: GameControlsHUD
var _camera_start_global_position := Vector2.ZERO
var _camera_start_zoom := Vector2.ONE
var _camera_tween: Tween
var _cutscene_skip_hud: Node
var _phase_one_attack_tween: Tween
var _phase_two_intro_tween: Tween
var _phase_end_tween: Tween
var _phase_one_hover_tweens: Array[Tween] = []
var _phase_one_sequence_tweens: Array[Tween] = []
var _phase_one_hover_start_positions := {}
var _phase_one_initial_positions := {}
var _phase_one_initial_modulates := {}
var _wave5_preview_trojan: TrojanHorse
var _wave10_ransomware: Ransomware
var _wave10_target: Node2D
var _wave11_zombie_node: ZombieNode
var _focused_zombie_node: ZombieNode
var _focused_worm_boss: WormBoss
var _focused_botnet_node: BotnetNode
var _focused_anti_cyberguardian: AntiCyberguardian
var _phase_one_target_visible_before_cutscene := false
var _wave20_alternate_map: CanvasItem
var _wave20_alternate_map_was_visible := false
var _wave20_alternate_map_active := false
var _wave20_map_actor_visibility: Dictionary = {}
var _last_handled_cutscene_input_event_id := 0
var _skip_requested := false
var _cutscene_finished_emitted := false
var _wave25_zoom_tween: Tween


func _ready() -> void:
	_alarm_cutscene_fx = CentralAudioResolver.resolve(self, ^"Sounds/AlarmCutsceneSfx")
	_virus_destroy_sfx_1 = CentralAudioResolver.resolve(self, ^"Sounds/CutsceneVirusDestroySfx1")
	_virus_destroy_sfx_2 = CentralAudioResolver.resolve(self, ^"Sounds/CutsceneVirusDestroySfx2")
	_gameplay_soundtrack = get_node_or_null(gameplay_soundtrack_path) as AudioStreamPlayer
	visible = true
	_continue_button.pressed.connect(_advance_dialogue)
	_root.gui_input.connect(_on_root_gui_input)
	_ensure_continue_button_styles()
	_speaker_label.text = "CYBER GUARDIAN"
	_cutscene_skip_hud = get_node_or_null(cutscene_skip_hud_path)
	_game_controls_hud = get_node_or_null(game_controls_hud_path) as GameControlsHUD
	act_started.connect(_on_act_started)
	cutscene_finished.connect(_on_cutscene_finished)
	_cutscene_camera = get_node_or_null(cutscene_camera_path) as Camera2D
	_capture_cutscene_camera_start()
	_hide_wave5_preview_until_cutscene()
	_set_phase_one_target_visible(false, false)
	_root.visible = false
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if play_on_ready:
		call_deferred("start_cutscene")


func _on_act_started(_act_number: int) -> void:
	if _game_controls_hud != null:
		_game_controls_hud.set_lives_visible(false)


func _on_cutscene_finished() -> void:
	if _game_controls_hud != null:
		_game_controls_hud.set_lives_visible(true, true)


func _hide_wave5_preview_until_cutscene() -> void:
	var preview := get_node_or_null(wave5_trojan_preview_path) as CanvasItem
	if preview != null:
		preview.hide()


func start_cutscene() -> void:
	if _running:
		return

	_ensure_gameplay_soundtrack_playing(true)
	_running = true
	_skip_requested = false
	_cutscene_finished_emitted = false
	visible = true
	current_act = ACT_ONE
	current_phase = &""
	_current_phase_finished = false
	_active_dialogue_lines = dialogue_lines
	_dialogue_completes_cutscene = true
	_dialogue_phase_done = false
	act_started.emit(current_act)
	_set_phase_one_target_visible(true)
	_root.visible = true
	_root.modulate = Color.WHITE
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	await get_tree().process_frame
	_capture_ui_final_positions()
	_capture_phase_one_initial_positions()
	_restore_phase_one_initial_positions()
	_prepare_all_overlays_hidden()

	await _run_act_one_phase_one()
	if _skip_requested or not _running:
		return
	await _run_act_one_phase_two()


func start_wave5_cutscene() -> void:
	if _running:
		return

	_ensure_gameplay_soundtrack_playing()
	_running = true
	_skip_requested = false
	_cutscene_finished_emitted = false
	visible = true
	current_act = ACT_WAVE_FIVE
	current_phase = &""
	_current_phase_finished = false
	act_started.emit(current_act)
	_set_phase_one_target_visible(true)
	_root.visible = true
	_root.modulate = Color.WHITE
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	await get_tree().process_frame
	_capture_ui_final_positions()
	_prepare_all_overlays_hidden()

	await _run_wave5_phase_one()
	if _skip_requested or not _running:
		return
	await _run_dialogue_phase(PHASE_TWO, wave5_phase_two_lines, false)
	if _skip_requested or not _running:
		return
	await _run_wave5_phase_three()
	if _skip_requested or not _running:
		return
	await _run_dialogue_phase(PHASE_FOUR, wave5_phase_four_lines, false)
	if _skip_requested or not _running:
		return
	await _finish_cutscene()


func start_wave11_cutscene() -> void:
	if _running:
		return

	_ensure_gameplay_soundtrack_playing()
	_running = true
	_skip_requested = false
	_cutscene_finished_emitted = false
	visible = true
	current_act = ACT_WAVE_ELEVEN
	current_phase = &""
	_current_phase_finished = false
	act_started.emit(current_act)
	_root.visible = true
	_root.modulate = Color.WHITE
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	await get_tree().process_frame
	_capture_ui_final_positions()
	_prepare_all_overlays_hidden()

	await _run_wave11_phase_one()
	if _skip_requested or not _running:
		return
	await _run_dialogue_phase(PHASE_TWO, wave11_phase_two_lines, false)
	if _skip_requested or not _running:
		return
	await _finish_cutscene()
	_wave11_zombie_node = null


func start_wave10_ransomware_cutscene(
	ransomware: Ransomware,
	target: Node2D
) -> void:
	if _running or not is_instance_valid(ransomware) or not is_instance_valid(target):
		return

	_ensure_gameplay_soundtrack_playing()
	_running = true
	_skip_requested = false
	_cutscene_finished_emitted = false
	visible = true
	current_act = ACT_WAVE_TEN
	current_phase = &""
	_current_phase_finished = false
	_wave10_ransomware = ransomware
	_wave10_target = target
	act_started.emit(current_act)
	_root.visible = true
	_root.modulate = Color.WHITE
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	await get_tree().process_frame
	_capture_ui_final_positions()
	_prepare_all_overlays_hidden()

	await _run_wave10_ransomware_phase_one()
	if _skip_requested or not _running:
		return
	await _run_dialogue_phase(PHASE_TWO, wave10_phase_two_lines, false)
	if _skip_requested or not _running:
		return
	await _finish_cutscene()
	_wave10_ransomware = null
	_wave10_target = null


func start_wave15_zombie_transform_cutscene() -> void:
	if _running:
		return

	await _prepare_special_zombie_cutscene(ACT_WAVE_FIFTEEN)
	if _skip_requested or not _running:
		return
	await _run_zombie_focus_phase(
		wave15_focus_duration,
		wave15_camera_zoom,
		true,
		false
	)
	if _skip_requested or not _running:
		return
	await _run_dialogue_phase(PHASE_TWO, wave15_phase_two_lines, false)
	if _skip_requested or not _running:
		return
	await _finish_cutscene()
	_focused_zombie_node = null


func start_zombie_node_defeat_cutscene() -> void:
	if _running:
		return

	await _prepare_special_zombie_cutscene(ACT_ZOMBIE_NODE_DEFEAT)
	if _skip_requested or not _running:
		return
	await _run_zombie_focus_phase(
		zombie_defeat_focus_duration,
		zombie_defeat_camera_zoom,
		false,
		true
	)
	if _skip_requested or not _running:
		return
	await _run_dialogue_phase(
		PHASE_TWO,
		zombie_defeat_phase_two_lines,
		false
	)
	if _skip_requested or not _running:
		return
	await _finish_cutscene()
	_focused_zombie_node = null


func start_wave20_worm_boss_cutscene() -> void:
	if _running:
		return

	await _prepare_special_zombie_cutscene(ACT_WAVE_TWENTY)
	if _skip_requested or not _running:
		return
	await _run_wave20_worm_focus_phase()
	if _skip_requested or not _running:
		return
	await _run_dialogue_phase(
		PHASE_TWO,
		wave20_phase_two_lines,
		false
	)
	if _skip_requested or not _running:
		return
	await _finish_cutscene()
	_focused_worm_boss = null


func start_worm_boss_defeat_cutscene() -> void:
	if _running:
		return

	await _prepare_special_zombie_cutscene(ACT_WORM_BOSS_DEFEAT)
	if _skip_requested or not _running:
		return
	await _run_dialogue_phase(
		PHASE_TWO,
		worm_defeat_phase_two_lines,
		false
	)
	if _skip_requested or not _running:
		return
	await _finish_cutscene()


func start_wave25_final_boss_cutscene() -> void:
	if _running:
		return

	await _prepare_special_zombie_cutscene(ACT_WAVE_TWENTY_FIVE)
	if _skip_requested or not _running:
		return
	await _run_wave25_botnet_focus_phase()
	if _skip_requested or not _running:
		return
	await _run_dialogue_phase(
		PHASE_TWO,
		wave25_warning_lines,
		false
	)
	if _skip_requested or not _running:
		return
	await _run_wave25_reveal_and_mount_phase()
	if _skip_requested or not _running:
		return
	await _run_dialogue_phase(
		PHASE_FOUR,
		wave25_strategy_lines,
		false
	)
	if _skip_requested or not _running:
		return
	await _finish_cutscene()
	_focused_botnet_node = null
	_focused_worm_boss = null
	_focused_anti_cyberguardian = null


func start_wave25_partial_defeat_cutscene(
	anti_guardian: AntiCyberguardian
) -> void:
	if _running or not is_instance_valid(anti_guardian):
		return

	_focused_anti_cyberguardian = anti_guardian
	await _prepare_special_zombie_cutscene(
		ACT_WAVE_TWENTY_FIVE_DEFEAT
	)
	if _skip_requested or not _running:
		return
	await _run_wave25_partial_defeat_phase()
	if _skip_requested or not _running:
		return
	await _finish_cutscene()
	_focused_anti_cyberguardian = null


func _prepare_special_zombie_cutscene(act_number: int) -> void:
	_ensure_gameplay_soundtrack_playing()
	_running = true
	_skip_requested = false
	_cutscene_finished_emitted = false
	visible = true
	current_act = act_number
	current_phase = &""
	_current_phase_finished = false
	act_started.emit(current_act)
	_root.visible = true
	_root.modulate = Color.WHITE
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	await get_tree().process_frame
	_capture_ui_final_positions()
	_prepare_all_overlays_hidden()


func _run_zombie_focus_phase(
	focus_duration: float,
	focus_zoom: float,
	prepare_final_form: bool,
	play_destroy_animation: bool
) -> void:
	_start_phase(PHASE_ONE)
	_prepare_phase_one_camera()
	_prepare_all_overlays_hidden()
	_focused_zombie_node = get_node_or_null(
		wave11_zombie_node_path
	) as ZombieNode
	if not is_instance_valid(_focused_zombie_node):
		await get_tree().create_timer(focus_duration).timeout
		if _skip_requested or not _running:
			return
		_finish_phase(PHASE_ONE)
		return

	if prepare_final_form:
		_focused_zombie_node.prepare_evolution_for_cutscene()
	await get_tree().process_frame
	await _pan_camera_to_target(
		_focused_zombie_node.global_position,
		Vector2.ZERO,
		focus_duration,
		focus_zoom
	)
	if _skip_requested or not _running:
		return
	if prepare_final_form:
		await _focused_zombie_node.play_evolution_to_level(
			ZombieNode.MAX_LEVEL
		)
		if _skip_requested or not _running:
			return
	if play_destroy_animation:
		await _focused_zombie_node.play_destroy_animation()
		if _skip_requested or not _running:
			return
	await _return_camera_to_start()
	if _skip_requested or not _running:
		return
	_finish_phase(PHASE_ONE)


func _run_wave20_worm_focus_phase() -> void:
	_show_wave20_alternate_map()
	_start_phase(PHASE_ONE)
	_prepare_phase_one_camera()
	_prepare_all_overlays_hidden()
	_focused_worm_boss = get_node_or_null(
		wave20_worm_boss_path
	) as WormBoss
	if not is_instance_valid(_focused_worm_boss):
		await get_tree().create_timer(wave20_focus_duration).timeout
		if _skip_requested or not _running:
			return
		_restore_wave20_alternate_map()
		_finish_phase(PHASE_ONE)
		return

	await get_tree().process_frame
	await _pan_camera_to_target(
		_focused_worm_boss.get_preview_center(),
		Vector2.ZERO,
		wave20_focus_duration,
		wave20_camera_zoom
	)
	if _skip_requested or not _running:
		return
	await _focused_worm_boss.play_cutscene_part_showcase()
	if _skip_requested or not _running:
		return
	await _return_camera_to_start()
	if _skip_requested or not _running:
		return
	_restore_wave20_alternate_map()
	_finish_phase(PHASE_ONE)


func _run_wave25_botnet_focus_phase() -> void:
	_start_phase(PHASE_ONE)
	_prepare_phase_one_camera()
	_prepare_all_overlays_hidden()
	_focused_botnet_node = get_node_or_null(
		wave25_botnet_node_path
	) as BotnetNode
	_focused_worm_boss = get_node_or_null(
		wave25_worm_boss_path
	) as WormBoss
	if is_instance_valid(_focused_worm_boss):
		_focused_anti_cyberguardian = (
			_focused_worm_boss.get_anti_cyberguardian()
		)

	if not is_instance_valid(_focused_botnet_node):
		await get_tree().process_frame
		_finish_phase(PHASE_ONE)
		return
	_focused_botnet_node.activate()
	await _pan_camera_to_target(
		_focused_botnet_node.global_position,
		Vector2.ZERO,
		wave25_botnet_pan_duration,
		wave25_botnet_camera_zoom
	)
	if _skip_requested or not _running:
		return
	_finish_phase(PHASE_ONE)


func _run_wave25_reveal_and_mount_phase() -> void:
	_start_phase(PHASE_THREE)
	_prepare_all_overlays_hidden()
	if not is_instance_valid(_focused_botnet_node):
		_finish_phase(PHASE_THREE)
		return

	if _cutscene_camera != null:
		_kill_tween(_wave25_zoom_tween)
		_wave25_zoom_tween = create_tween()
		_wave25_zoom_tween.tween_property(
			_cutscene_camera,
			"zoom",
			Vector2.ONE * wave25_deep_camera_zoom,
			wave25_reveal_zoom_duration
		).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

	if _focused_botnet_node.get_level() < BotnetNode.MAX_LEVEL:
		await _focused_botnet_node.play_evolution_to_level(
			BotnetNode.MAX_LEVEL
		)
		if _skip_requested or not _running:
			return
	await _focused_botnet_node.play_final_boss_hollow_reveal()
	if _skip_requested or not _running:
		return

	if is_instance_valid(_focused_anti_cyberguardian):
		var marker_one_position := (
			_focused_botnet_node
				.get_anti_guardian_reveal_marker_global_position(0)
		)
		var marker_two_position := (
			_focused_botnet_node
				.get_anti_guardian_reveal_marker_global_position(1)
		)
		await _focused_anti_cyberguardian \
			.play_botnet_reveal_appearance_at(marker_one_position)
		if _skip_requested or not _running:
			return
		_focused_anti_cyberguardian.move_botnet_reveal_to(
			marker_two_position,
			_focused_botnet_node
				.get_final_boss_anti_reveal_duration()
		)
		await _focused_botnet_node.play_final_boss_anti_reveal()
		if _skip_requested or not _running:
			return
		if wave25_anti_departure_hold_duration > 0.0:
			await get_tree().create_timer(
				wave25_anti_departure_hold_duration
			).timeout
			if _skip_requested or not _running:
				return
		await _focused_anti_cyberguardian.play_cloak_departure_at(
			marker_two_position
		)
		if _skip_requested or not _running:
			return
	else:
		await _focused_botnet_node.play_final_boss_anti_reveal()
		if _skip_requested or not _running:
			return

	_kill_tween(_wave25_zoom_tween)
	_wave25_zoom_tween = null
	_show_wave20_alternate_map()
	if not is_instance_valid(_focused_worm_boss):
		_finish_phase(PHASE_THREE)
		return
	_focused_worm_boss.prepare_cutscene_preview(
		_focused_worm_boss.get_authored_cutscene_position()
	)
	await get_tree().process_frame
	await _pan_camera_to_target(
		_focused_worm_boss.get_preview_center(),
		Vector2.ZERO,
		wave25_worm_pan_duration,
		wave25_worm_camera_zoom
	)
	if _skip_requested or not _running:
		return
	if is_instance_valid(_focused_anti_cyberguardian):
		_focused_anti_cyberguardian.mount_on_worm()
		await _focused_anti_cyberguardian.play_mounted_entrance_and_activate()
		if _skip_requested or not _running:
			return
	_finish_phase(PHASE_THREE)


func _run_wave25_partial_defeat_phase() -> void:
	_start_phase(PHASE_ONE)
	_prepare_phase_one_camera()
	_prepare_all_overlays_hidden()
	var focus_target := get_node_or_null(
		wave25_defeat_focus_target_path
	) as Node2D
	var focus_position := (
		focus_target.global_position
		if is_instance_valid(focus_target)
		else _camera_start_global_position
	)
	await _pan_camera_to_target(
		focus_position,
		Vector2.ZERO,
		wave25_defeat_pan_duration,
		wave25_defeat_camera_zoom
	)
	if _skip_requested or not _running:
		return
	if is_instance_valid(_focused_anti_cyberguardian):
		await _focused_anti_cyberguardian.play_partial_defeat_sequence_at(
			focus_position
		)
		if _skip_requested or not _running:
			return
	_finish_phase(PHASE_ONE)


func _run_act_one_phase_one() -> void:
	_start_phase(PHASE_ONE)
	_ensure_gameplay_soundtrack_playing()
	_prepare_phase_one_camera()
	_dim_overlay.hide()
	_dialogue_panel.hide()
	_mascot.hide()
	_continue_button.hide()
	_alert_overlay.show()
	_alert_overlay.color = Color(red_alert_color.r, red_alert_color.g, red_alert_color.b, 0.0)

	_play_audio_player(_alarm_cutscene_fx)
	await _play_red_alert()
	if _skip_requested or not _running:
		return
	await _pan_camera_to_phase_one_target()
	if _skip_requested or not _running:
		return
	_start_phase_one_virus_hover()
	await get_tree().create_timer(enemy_hold_duration).timeout
	if _skip_requested or not _running:
		return
	_stop_phase_one_virus_hover(false)
	await _move_phase_one_viruses_to_entrance()
	if _skip_requested or not _running:
		return
	await _return_camera_to_start()
	if _skip_requested or not _running:
		return

	_set_phase_one_target_visible(false)
	_alert_overlay.hide()
	_finish_phase(PHASE_ONE)


func _run_act_one_phase_two() -> void:
	await _run_dialogue_phase(PHASE_TWO, dialogue_lines, true)


func _run_dialogue_phase(phase_name: StringName, lines: PackedStringArray, completes_cutscene: bool) -> void:
	_start_phase(phase_name)
	_active_dialogue_lines = lines
	_dialogue_completes_cutscene = completes_cutscene
	_dialogue_phase_done = false
	_line_index = 0
	_dialogue_label.text = ""
	_continue_button.hide()
	_dim_overlay.show()
	_dialogue_panel.show()
	_mascot.show()

	_dim_overlay.color = Color(dim_color.r, dim_color.g, dim_color.b, 0.0)
	_dialogue_panel.global_position = _panel_final_global_position + Vector2(-text_box_slide_distance, 0.0)
	_dialogue_panel.modulate = Color(1, 1, 1, 0)
	_mascot.global_position = _mascot_final_global_position + Vector2(mascot_slide_distance, 0.0)
	_mascot.modulate = Color(1, 1, 1, 0)

	_kill_tween(_phase_two_intro_tween)
	_phase_two_intro_tween = create_tween()
	_phase_two_intro_tween.set_parallel(true)
	_phase_two_intro_tween.tween_property(_dim_overlay, "color", dim_color, entry_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_phase_two_intro_tween.tween_property(_dialogue_panel, "global_position", _panel_final_global_position, entry_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_phase_two_intro_tween.tween_property(_dialogue_panel, "modulate", Color.WHITE, entry_duration * 0.8)
	_phase_two_intro_tween.tween_property(_mascot, "global_position", _mascot_final_global_position, entry_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_phase_two_intro_tween.tween_property(_mascot, "modulate", Color.WHITE, entry_duration * 0.75)
	await _phase_two_intro_tween.finished
	_phase_two_intro_tween = null
	if _skip_requested or not _running:
		return

	if _active_dialogue_lines.is_empty():
		if completes_cutscene:
			await _finish_cutscene()
		else:
			_finish_current_dialogue_phase()
		return

	_play_current_line()
	if not completes_cutscene:
		while _running and not _skip_requested and not _dialogue_phase_done:
			await get_tree().process_frame


func _advance_dialogue() -> void:
	if not _running or not _is_dialogue_phase():
		return

	if _typing:
		_skip_typing = true
		return

	_line_index += 1
	if _line_index >= _active_dialogue_lines.size():
		if _dialogue_completes_cutscene:
			_finish_cutscene()
		else:
			_finish_current_dialogue_phase()
		return

	_play_current_line()


func _input(event: InputEvent) -> void:
	if handle_cutscene_advance_input(event):
		get_viewport().set_input_as_handled()


func handle_cutscene_advance_input(event: InputEvent) -> bool:
	if not _running or not _is_dialogue_phase():
		return false
	if _event_targets_skip_hud(event):
		return false
	if not _is_enter_press(event) and not _is_primary_press(event):
		return false
	var event_id := event.get_instance_id()
	if event_id == _last_handled_cutscene_input_event_id:
		return true

	_last_handled_cutscene_input_event_id = event_id
	if _typing:
		_skip_typing = true
		return true
	if not _continue_button.visible:
		return true

	_advance_dialogue()
	return true


func _on_root_gui_input(event: InputEvent) -> void:
	if _event_targets_skip_hud(event):
		return
	if handle_cutscene_advance_input(event):
		_root.accept_event()


func _is_enter_press(event: InputEvent) -> bool:
	if event is InputEventKey:
		var key_event := event as InputEventKey
		return key_event.pressed \
			and not key_event.echo \
			and (key_event.keycode == KEY_ENTER or key_event.keycode == KEY_KP_ENTER)

	return false


func _event_targets_skip_hud(event: InputEvent) -> bool:
	if _cutscene_skip_hud == null:
		_cutscene_skip_hud = get_node_or_null(cutscene_skip_hud_path)
	if _cutscene_skip_hud == null or not _cutscene_skip_hud.has_method("event_targets_skip_button"):
		return false

	return bool(_cutscene_skip_hud.call("event_targets_skip_button", event))


func _is_primary_press(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		var mouse_button := event as InputEventMouseButton
		return mouse_button.pressed and mouse_button.button_index == MOUSE_BUTTON_LEFT

	if event is InputEventScreenTouch:
		var screen_touch := event as InputEventScreenTouch
		return screen_touch.pressed

	return false


func _play_current_line() -> void:
	_typing = true
	_skip_typing = false
	_continue_button.hide()
	_dialogue_label.text = ""
	_start_mascot_bob()

	var line := String(_active_dialogue_lines[_line_index])
	var delay := 1.0 / maxf(1.0, characters_per_second)
	for index in range(line.length()):
		if _skip_typing:
			break

		_dialogue_label.text = line.substr(0, index + 1)
		await get_tree().create_timer(delay).timeout
		if _skip_requested or not _running:
			return

	_dialogue_label.text = line
	_typing = false
	_skip_typing = false
	_stop_mascot_bob()
	_continue_button.text = "Begin" if _line_index >= _active_dialogue_lines.size() - 1 and _dialogue_completes_cutscene else "Continue"
	_continue_button.show()
	_animate_continue_button()


func is_cutscene_running() -> bool:
	return _running


func skip_cutscene() -> void:
	if not _running:
		return

	var skipped_phase := current_phase
	_skip_requested = true
	_typing = false
	_skip_typing = false
	_stop_active_cutscene_tweens()
	_stop_mascot_bob()
	_stop_phase_one_sequence_tweens()
	_stop_phase_one_virus_hover()
	_stop_cutscene_sfx()
	_cleanup_wave5_preview_trojan()
	_finish_wave10_ransomware_visual()
	_finish_wave11_zombie_visual()
	if current_act == ACT_WAVE_FIFTEEN \
			and is_instance_valid(_focused_zombie_node):
		_focused_zombie_node.finish_evolution_immediately()
	if current_act == ACT_WAVE_TWENTY_FIVE:
		_finish_wave25_final_boss_visual()
	if current_act == ACT_WAVE_TWENTY_FIVE_DEFEAT \
			and is_instance_valid(_focused_anti_cyberguardian):
		_focused_anti_cyberguardian \
			.finish_partial_defeat_sequence_immediately()
	_restore_wave20_alternate_map()
	_restore_cutscene_camera_to_start()
	_set_phase_one_target_visible(false)
	_dialogue_panel.global_position = _panel_final_global_position
	_mascot.global_position = _mascot_final_global_position
	_prepare_all_overlays_hidden()
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.hide()

	if skipped_phase != &"" and skipped_phase != PHASE_END:
		_finish_phase(skipped_phase)
	if current_phase != PHASE_END:
		_start_phase(PHASE_END)

	_running = false
	_finish_phase(PHASE_END)
	_emit_cutscene_finished_once()


func _ensure_continue_button_styles() -> void:
	var normal_style := _continue_button.get_theme_stylebox("normal")
	if normal_style == null:
		return

	var hover_style := normal_style.duplicate() as StyleBoxFlat
	if hover_style != null:
		hover_style.border_color = Color(1.0, 0.82, 0.08, 1.0)
		hover_style.bg_color = Color(0.055, 0.1, 0.16, 0.96)
		_continue_button.add_theme_stylebox_override("hover", hover_style)
		_continue_button.add_theme_stylebox_override("pressed", hover_style)
		_continue_button.add_theme_stylebox_override("focus", hover_style)


func _finish_cutscene() -> void:
	if not _running:
		return

	if current_phase != &"" and current_phase != PHASE_END:
		_finish_phase(current_phase)
	_start_phase(PHASE_END)
	_stop_mascot_bob()
	_continue_button.hide()
	await _return_camera_to_start()
	if _skip_requested or not _running:
		return

	_kill_tween(_phase_end_tween)
	_phase_end_tween = create_tween()
	_phase_end_tween.set_parallel(true)
	_phase_end_tween.tween_property(_dim_overlay, "color", Color(dim_color.r, dim_color.g, dim_color.b, 0.0), exit_duration)
	_phase_end_tween.tween_property(_dialogue_panel, "global_position", _panel_final_global_position + Vector2(-text_box_slide_distance, 0.0), exit_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_phase_end_tween.tween_property(_dialogue_panel, "modulate", Color(1, 1, 1, 0), exit_duration * 0.75)
	_phase_end_tween.tween_property(_mascot, "global_position", _mascot_final_global_position + Vector2(mascot_slide_distance, 0.0), exit_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_phase_end_tween.tween_property(_mascot, "modulate", Color(1, 1, 1, 0), exit_duration * 0.75)
	await _phase_end_tween.finished
	_phase_end_tween = null
	if _skip_requested or not _running:
		return

	_dialogue_panel.global_position = _panel_final_global_position
	_mascot.global_position = _mascot_final_global_position
	_prepare_all_overlays_hidden()
	_cleanup_wave5_preview_trojan()
	_restore_wave20_alternate_map()
	_set_phase_one_target_visible(false)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.hide()
	_running = false
	_finish_phase(PHASE_END)
	_emit_cutscene_finished_once()


func _finish_current_dialogue_phase() -> void:
	_stop_mascot_bob()
	_continue_button.hide()
	_dialogue_phase_done = true
	_finish_phase(current_phase)


func _is_dialogue_phase() -> bool:
	return current_phase == PHASE_TWO or current_phase == PHASE_FOUR


func _run_wave5_phase_one() -> void:
	_start_phase(PHASE_ONE)
	_prepare_phase_one_camera()
	_prepare_all_overlays_hidden()
	_prepare_wave5_preview_trojan()
	await _pan_camera_to_target(_get_wave5_trojan_camera_center(), Vector2.ZERO)
	if _skip_requested or not _running:
		return

	await get_tree().create_timer(wave5_trojan_hold_duration).timeout
	if _skip_requested or not _running:
		return

	_finish_phase(PHASE_ONE)


func _run_wave11_phase_one() -> void:
	_start_phase(PHASE_ONE)
	_prepare_phase_one_camera()
	_prepare_all_overlays_hidden()
	_wave11_zombie_node = get_node_or_null(wave11_zombie_node_path) as ZombieNode
	if not is_instance_valid(_wave11_zombie_node):
		await get_tree().create_timer(wave11_reveal_hold_duration).timeout
		if _skip_requested or not _running:
			return
		_finish_phase(PHASE_ONE)
		return

	_wave11_zombie_node.set_level(1)
	_wave11_zombie_node.prepare_entrance()
	await get_tree().process_frame
	await _pan_camera_to_target(_wave11_zombie_node.global_position, Vector2.ZERO)
	if _skip_requested or not _running:
		return
	await _wave11_zombie_node.play_entrance()
	if _skip_requested or not _running:
		return
	if wave11_reveal_hold_duration > 0.0:
		await get_tree().create_timer(wave11_reveal_hold_duration).timeout
	if _skip_requested or not _running:
		return

	_finish_phase(PHASE_ONE)


func _run_wave10_ransomware_phase_one() -> void:
	_start_phase(PHASE_ONE)
	_prepare_phase_one_camera()
	_prepare_all_overlays_hidden()
	if not is_instance_valid(_wave10_ransomware) \
			or not is_instance_valid(_wave10_target):
		_finish_phase(PHASE_ONE)
		return

	await _pan_camera_to_target(
		_wave10_target.global_position,
		Vector2.ZERO,
		camera_pan_duration,
		wave10_camera_zoom
	)
	if _skip_requested or not _running:
		return
	await _wave10_ransomware.play_appear()
	if _skip_requested or not _running:
		return
	if wave10_reveal_hold_duration > 0.0:
		await get_tree().create_timer(wave10_reveal_hold_duration).timeout
	if _skip_requested or not _running:
		return
	_finish_phase(PHASE_ONE)


func _finish_wave10_ransomware_visual() -> void:
	if is_instance_valid(_wave10_ransomware):
		_wave10_ransomware.finish_appear_immediately()
	_wave10_ransomware = null
	_wave10_target = null


func _finish_wave11_zombie_visual() -> void:
	if is_instance_valid(_wave11_zombie_node):
		_wave11_zombie_node.finish_entrance_immediately()
	_wave11_zombie_node = null


func _run_wave5_phase_three() -> void:
	_start_phase(PHASE_THREE)
	_dialogue_panel.hide()
	_mascot.hide()
	_dim_overlay.hide()
	if is_instance_valid(_wave5_preview_trojan):
		await _wave5_preview_trojan.play_cutscene_cloak_transform()
	else:
		await get_tree().create_timer(wave5_invisible_hold_duration).timeout
	if _skip_requested or not _running:
		return

	_finish_phase(PHASE_THREE)


func _prepare_wave5_preview_trojan() -> void:
	_cleanup_wave5_preview_trojan()
	_wave5_preview_trojan = get_node_or_null(wave5_trojan_preview_path) as TrojanHorse
	if not is_instance_valid(_wave5_preview_trojan):
		return

	_wave5_preview_trojan.prepare_cutscene_preview()


func _cleanup_wave5_preview_trojan() -> void:
	if is_instance_valid(_wave5_preview_trojan):
		_wave5_preview_trojan.hide()
	_wave5_preview_trojan = null


func _get_wave5_trojan_camera_center() -> Vector2:
	if is_instance_valid(_wave5_preview_trojan):
		return _wave5_preview_trojan.global_position

	return _get_phase_one_target_center()


func _play_red_alert() -> void:
	var alert_tween := create_tween()
	_phase_one_sequence_tweens.append(alert_tween)
	var half_pulse_duration := red_alert_duration / 4.0
	for _index in range(2):
		alert_tween.tween_property(_alert_overlay, "color", red_alert_color, half_pulse_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		alert_tween.tween_property(_alert_overlay, "color", Color(red_alert_color.r, red_alert_color.g, red_alert_color.b, 0.0), half_pulse_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await alert_tween.finished
	_phase_one_sequence_tweens.erase(alert_tween)


func _prepare_phase_one_camera() -> void:
	if _cutscene_camera == null:
		return

	_cutscene_camera.make_current()
	_capture_cutscene_camera_start()


func _capture_cutscene_camera_start() -> void:
	if _cutscene_camera == null:
		return

	_camera_start_global_position = _cutscene_camera.global_position
	_camera_start_zoom = _cutscene_camera.zoom


func _pan_camera_to_phase_one_target() -> void:
	await _pan_camera_to_target(_get_phase_one_target_center(), enemy_camera_padding)


func _pan_camera_to_target(
	target_position: Vector2,
	camera_padding: Vector2,
	duration: float = -1.0,
	zoom_scale: float = -1.0
) -> void:
	var tween_duration := camera_pan_duration if duration <= 0.0 else duration
	var target_zoom := (
		phase_one_camera_zoom
			if zoom_scale <= 0.0
			else zoom_scale
	)
	if _cutscene_camera == null:
		await get_tree().create_timer(tween_duration).timeout
		return

	_kill_tween(_camera_tween)
	_camera_tween = create_tween()
	_camera_tween.set_parallel(true)
	_camera_tween.tween_property(
		_cutscene_camera,
		"global_position",
		target_position + camera_padding,
		tween_duration
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_camera_tween.tween_property(
		_cutscene_camera,
		"zoom",
		Vector2.ONE * target_zoom,
		tween_duration
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	await _camera_tween.finished
	_camera_tween = null


func _return_camera_to_start() -> void:
	if _cutscene_camera == null:
		await get_tree().create_timer(camera_return_duration).timeout
		return

	_kill_tween(_camera_tween)
	_camera_tween = create_tween()
	_camera_tween.set_parallel(true)
	_camera_tween.tween_property(_cutscene_camera, "global_position", _camera_start_global_position, camera_return_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_camera_tween.tween_property(_cutscene_camera, "zoom", _camera_start_zoom, camera_return_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	await _camera_tween.finished
	_camera_tween = null


func _get_phase_one_target_center() -> Vector2:
	var target := get_node_or_null(phase_one_target_path)
	if target == null:
		return _camera_start_global_position

	var target_rect := Rect2()
	var found_visual := false
	for canvas_item in _get_phase_one_visual_children():
		var child_position = canvas_item.global_position
		if not found_visual:
			target_rect = Rect2(child_position, Vector2.ZERO)
			found_visual = true
		else:
			target_rect = target_rect.expand(child_position)

	if found_visual:
		return target_rect.get_center()

	if target is CanvasItem:
		return (target as CanvasItem).global_position

	return _camera_start_global_position


func _set_phase_one_target_visible(is_visible: bool, remember_current := true) -> void:
	var target := get_node_or_null(phase_one_target_path) as CanvasItem
	if target == null:
		return

	if remember_current and is_visible:
		_phase_one_target_visible_before_cutscene = target.visible

	if is_visible:
		target.visible = true
	elif remember_current:
		target.visible = _phase_one_target_visible_before_cutscene
	else:
		target.visible = false


func _show_wave20_alternate_map() -> void:
	_restore_wave20_alternate_map()
	_wave20_alternate_map = get_node_or_null(
		wave20_alternate_map_path
	) as CanvasItem
	if _wave20_alternate_map == null:
		return

	_wave20_alternate_map_was_visible = _wave20_alternate_map.visible
	_wave20_alternate_map_active = true
	_wave20_map_actor_visibility.clear()
	_capture_and_hide_wave20_map_actors(_wave20_alternate_map)
	_wave20_alternate_map.show()


func _restore_wave20_alternate_map() -> void:
	if not _wave20_alternate_map_active:
		return

	if is_instance_valid(_wave20_alternate_map):
		_wave20_alternate_map.visible = _wave20_alternate_map_was_visible
	for actor_variant in _wave20_map_actor_visibility:
		var actor := actor_variant as CanvasItem
		if is_instance_valid(actor):
			actor.visible = bool(_wave20_map_actor_visibility[actor_variant])

	_wave20_map_actor_visibility.clear()
	_wave20_alternate_map = null
	_wave20_alternate_map_active = false


func _capture_and_hide_wave20_map_actors(node: Node) -> void:
	for child in node.get_children():
		var canvas_item := child as CanvasItem
		if canvas_item != null and (
			child.name.begins_with("CutsceneVirus")
			or child.name == &"Wave5CutsceneTrojanHorse"
		):
			_wave20_map_actor_visibility[canvas_item] = canvas_item.visible
			canvas_item.hide()
			continue

		_capture_and_hide_wave20_map_actors(child)


func _get_phase_one_visual_children() -> Array[CanvasItem]:
	var visuals: Array[CanvasItem] = []
	var target := get_node_or_null(phase_one_target_path)
	if target == null:
		return visuals

	_collect_cutscene_virus_visuals(target, visuals)
	if not visuals.is_empty():
		return visuals

	for child in target.get_children():
		var canvas_item := child as CanvasItem
		if canvas_item == null or not canvas_item.visible:
			continue

		visuals.append(canvas_item)

	return visuals


func _collect_cutscene_virus_visuals(node: Node, visuals: Array[CanvasItem]) -> void:
	for child in node.get_children():
		var canvas_item := child as CanvasItem
		if canvas_item != null and canvas_item.visible and child.name.begins_with("CutsceneVirus"):
			visuals.append(canvas_item)

		_collect_cutscene_virus_visuals(child, visuals)


func _capture_phase_one_initial_positions() -> void:
	if not _phase_one_initial_positions.is_empty():
		return

	for canvas_item in _get_phase_one_visual_children():
		_phase_one_initial_positions[canvas_item] = canvas_item.global_position
		_phase_one_initial_modulates[canvas_item] = canvas_item.modulate


func _restore_phase_one_initial_positions() -> void:
	for key in _phase_one_initial_positions.keys():
		var canvas_item := key as CanvasItem
		if is_instance_valid(canvas_item):
			canvas_item.global_position = _phase_one_initial_positions[key]
			canvas_item.modulate = _phase_one_initial_modulates.get(canvas_item, Color.WHITE)


func _start_phase_one_virus_hover() -> void:
	_stop_phase_one_virus_hover(false)

	var visuals := _get_phase_one_visual_children()
	if visuals.is_empty():
		return

	_play_phase_one_virus_movement_sfx()
	for index in range(visuals.size()):
		var canvas_item := visuals[index]
		var start_position = canvas_item.global_position
		_phase_one_hover_start_positions[canvas_item] = start_position

		var hover_tween := create_tween()
		hover_tween.set_loops()
		hover_tween.tween_interval(float(index) * 0.08)
		var drift_direction := -1.0 if index % 2 == 0 else 1.0
		hover_tween.tween_property(
			canvas_item,
			"global_position",
			start_position + Vector2(phase_one_virus_drift_distance * drift_direction, -phase_one_virus_hover_distance),
			phase_one_virus_hover_half_duration
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		hover_tween.tween_property(
			canvas_item,
			"global_position",
			start_position + Vector2(phase_one_virus_drift_distance * -0.65 * drift_direction, phase_one_virus_hover_distance * 0.45),
			phase_one_virus_hover_half_duration
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		hover_tween.tween_property(
			canvas_item,
			"global_position",
			start_position,
			phase_one_virus_hover_half_duration
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		_phase_one_hover_tweens.append(hover_tween)


func _move_phase_one_viruses_to_entrance() -> void:
	var visuals := _get_phase_one_visual_children()
	if visuals.is_empty():
		await get_tree().create_timer(enemy_attack_duration).timeout
		return

	var attack_target := _get_phase_one_attack_target_position()
	_kill_tween(_phase_one_attack_tween)
	_phase_one_attack_tween = create_tween()
	_phase_one_attack_tween.set_parallel(true)

	for index in range(visuals.size()):
		var canvas_item := visuals[index]
		var destination := attack_target + _get_phase_one_attack_offset(index)
		_phase_one_attack_tween.tween_property(
			canvas_item,
			"global_position",
			destination,
			enemy_attack_duration
		).set_delay(float(index) * 0.08).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

	if _cutscene_camera != null:
		_phase_one_attack_tween.tween_property(
			_cutscene_camera,
			"global_position",
			attack_target + entrance_camera_padding,
			enemy_attack_duration
		).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

	await _phase_one_attack_tween.finished
	_phase_one_attack_tween = null

	var disappear_tween := create_tween()
	_phase_one_sequence_tweens.append(disappear_tween)
	disappear_tween.set_parallel(true)
	for canvas_item in visuals:
		disappear_tween.tween_property(
			canvas_item,
			"modulate:a",
			0.0,
			enemy_disappear_duration
		).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	await disappear_tween.finished
	_phase_one_sequence_tweens.erase(disappear_tween)


func _get_phase_one_attack_target_position() -> Vector2:
	var target := get_node_or_null(phase_one_attack_target_path)
	if target is Node2D:
		return (target as Node2D).global_position
	if target is Control:
		return (target as Control).global_position

	return _camera_start_global_position


func _get_phase_one_attack_offset(index: int) -> Vector2:
	var offsets := [
		Vector2(-48, -28),
		Vector2(-20, 18),
		Vector2(18, -18),
		Vector2(48, 22),
		Vector2(-72, 30)
	]
	return offsets[index % offsets.size()]


func _stop_phase_one_virus_hover(restore_positions := true) -> void:
	for hover_tween in _phase_one_hover_tweens:
		if hover_tween != null:
			hover_tween.kill()
	_phase_one_hover_tweens.clear()

	if restore_positions:
		for key in _phase_one_hover_start_positions.keys():
			var canvas_item := key as CanvasItem
			if is_instance_valid(canvas_item):
				canvas_item.global_position = _phase_one_hover_start_positions[key]
	_phase_one_hover_start_positions.clear()


func _stop_phase_one_sequence_tweens() -> void:
	for sequence_tween in _phase_one_sequence_tweens:
		if sequence_tween != null and sequence_tween.is_valid():
			sequence_tween.kill()
	_phase_one_sequence_tweens.clear()


func _play_phase_one_virus_movement_sfx() -> void:
	_play_audio_player(_virus_destroy_sfx_1)

	var sound_tween := create_tween()
	_phase_one_sequence_tweens.append(sound_tween)
	sound_tween.tween_interval(second_virus_destroy_sfx_delay)
	sound_tween.tween_callback(func() -> void:
		_play_audio_player(_virus_destroy_sfx_2)
	)
	sound_tween.finished.connect(func() -> void:
		_phase_one_sequence_tweens.erase(sound_tween)
	)


func _play_audio_player(player: AudioStreamPlayer) -> void:
	if player == null:
		return

	player.stop()
	player.play()


func _ensure_gameplay_soundtrack_playing(restart_from_beginning: bool = false) -> void:
	if _gameplay_soundtrack == null:
		_gameplay_soundtrack = get_node_or_null(gameplay_soundtrack_path) as AudioStreamPlayer
	if _gameplay_soundtrack == null:
		_gameplay_soundtrack = _create_cutscene_soundtrack_player()
	if _gameplay_soundtrack == null:
		return

	if _gameplay_soundtrack.stream == null:
		_gameplay_soundtrack.stream = CYBER_BUSINESS_SOUNDTRACK
	_gameplay_soundtrack.process_mode = Node.PROCESS_MODE_ALWAYS
	_gameplay_soundtrack.stream_paused = false
	_gameplay_soundtrack.bus = &"Music"
	if _gameplay_soundtrack.stream is AudioStreamWAV:
		(_gameplay_soundtrack.stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
	if restart_from_beginning:
		_gameplay_soundtrack.stop()
		_gameplay_soundtrack.play(0.0)
	elif not _gameplay_soundtrack.playing:
		_gameplay_soundtrack.play()


func _create_cutscene_soundtrack_player() -> AudioStreamPlayer:
	var game_root := get_parent()
	if game_root == null:
		return null

	var music_container := game_root.get_node_or_null("Music")
	if music_container == null:
		music_container = Node.new()
		music_container.name = "Music"
		game_root.add_child(music_container)

	var existing_player := music_container.get_node_or_null("CyberBusiness") as AudioStreamPlayer
	if existing_player != null:
		return existing_player

	var player := AudioStreamPlayer.new()
	player.name = "CyberBusiness"
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	player.stream = CYBER_BUSINESS_SOUNDTRACK
	player.volume_db = -6.0
	player.bus = &"Music"
	music_container.add_child(player)
	player.add_to_group(&"Music")
	return player


func _stop_cutscene_sfx() -> void:
	for player in [_alarm_cutscene_fx, _virus_destroy_sfx_1, _virus_destroy_sfx_2]:
		if player != null:
			player.stop()


func _capture_ui_final_positions() -> void:
	_dialogue_panel.show()
	_mascot.show()
	_panel_final_global_position = _dialogue_panel.global_position
	_mascot_final_global_position = _mascot.global_position


func _prepare_all_overlays_hidden() -> void:
	_stop_phase_one_virus_hover()
	_alert_overlay.hide()
	_dim_overlay.hide()
	_dialogue_panel.hide()
	_mascot.hide()
	_dialogue_panel.modulate = Color.WHITE
	_mascot.modulate = Color.WHITE
	_dim_overlay.color = Color(dim_color.r, dim_color.g, dim_color.b, 0.0)
	_alert_overlay.color = Color(red_alert_color.r, red_alert_color.g, red_alert_color.b, 0.0)


func _stop_active_cutscene_tweens() -> void:
	_kill_tween(_camera_tween)
	_camera_tween = null
	_kill_tween(_phase_one_attack_tween)
	_phase_one_attack_tween = null
	_kill_tween(_phase_two_intro_tween)
	_phase_two_intro_tween = null
	_kill_tween(_phase_end_tween)
	_phase_end_tween = null
	_kill_tween(_wave25_zoom_tween)
	_wave25_zoom_tween = null


func _finish_wave25_final_boss_visual() -> void:
	if not is_instance_valid(_focused_botnet_node):
		_focused_botnet_node = get_node_or_null(
			wave25_botnet_node_path
		) as BotnetNode
	if is_instance_valid(_focused_botnet_node):
		_focused_botnet_node.finish_evolution_immediately(
			BotnetNode.MAX_LEVEL
		)
		_focused_botnet_node.finish_final_boss_reveal_immediately()

	if not is_instance_valid(_focused_worm_boss):
		_focused_worm_boss = get_node_or_null(
			wave25_worm_boss_path
		) as WormBoss
	if not is_instance_valid(_focused_worm_boss):
		return
	_focused_worm_boss.prepare_cutscene_preview(
		_focused_worm_boss.get_authored_cutscene_position()
	)
	_focused_anti_cyberguardian = (
		_focused_worm_boss.get_anti_cyberguardian()
	)
	if is_instance_valid(_focused_anti_cyberguardian):
		_focused_anti_cyberguardian.finish_final_boss_intro_immediately()


func _kill_tween(tween: Tween) -> void:
	if tween != null and tween.is_valid():
		tween.kill()


func _restore_cutscene_camera_to_start() -> void:
	if _cutscene_camera == null:
		return

	_cutscene_camera.make_current()
	_cutscene_camera.global_position = _camera_start_global_position
	_cutscene_camera.zoom = _camera_start_zoom


func _emit_cutscene_finished_once() -> void:
	if _cutscene_finished_emitted:
		return

	_cutscene_finished_emitted = true
	cutscene_finished.emit()


func _start_phase(phase_name: StringName) -> void:
	current_phase = phase_name
	_current_phase_finished = false
	phase_started.emit(current_act, current_phase)


func _finish_phase(phase_name: StringName) -> void:
	if current_phase == phase_name:
		if _current_phase_finished:
			return
		_current_phase_finished = true

	phase_finished.emit(current_act, phase_name)


func _start_mascot_bob() -> void:
	_stop_mascot_bob()
	_mascot.global_position = _mascot_final_global_position
	_mascot_bob_tween = create_tween()
	_mascot_bob_tween.set_loops()
	_mascot_bob_tween.tween_property(_mascot, "global_position:y", _mascot_final_global_position.y - mascot_bob_distance, mascot_bob_half_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_mascot_bob_tween.tween_property(_mascot, "global_position:y", _mascot_final_global_position.y + mascot_bob_distance * 0.35, mascot_bob_half_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_mascot_bob_tween.tween_property(_mascot, "global_position:y", _mascot_final_global_position.y, mascot_bob_half_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _stop_mascot_bob() -> void:
	if _mascot_bob_tween != null:
		_mascot_bob_tween.kill()
		_mascot_bob_tween = null
	if is_instance_valid(_mascot):
		_mascot.global_position = _mascot_final_global_position


func _animate_continue_button() -> void:
	_continue_button.pivot_offset = _continue_button.size * 0.5
	_continue_button.scale = Vector2.ONE * 0.94
	var button_tween := create_tween()
	button_tween.tween_property(_continue_button, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
