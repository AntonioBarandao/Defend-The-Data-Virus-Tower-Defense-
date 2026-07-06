class_name TextCutscene
extends CanvasLayer

signal act_started(act_number: int)
signal phase_started(act_number: int, phase_name: StringName)
signal phase_finished(act_number: int, phase_name: StringName)
signal cutscene_finished

const ACT_ONE := 1
const ACT_WAVE_FIVE := 5
const PHASE_ONE := &"phase_1"
const PHASE_TWO := &"phase_2"
const PHASE_THREE := &"phase_3"
const PHASE_FOUR := &"phase_4"
const PHASE_END := &"phase_end"
const PHASE_ONE_DESTROY_SFX := preload("res://assets/sfx/virus_destroy.wav")

@export var play_on_ready := true
@export var dialogue_lines: PackedStringArray = [
	"Our hardware is being under attack! Help us defeat the viruses and save our cpu!",
	"Deploy cybersecurity towers onto safe platforms and stop the viruses before they breach the system.",
	"After each wave, answer the security challenge to earn more Cyber Bucks. I will guide you through the first defense."
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
	"A Trojan horse has entered the network. It hides inside normal traffic, then turns invisible so most towers cannot target it."
]
@export var wave5_phase_four_lines: PackedStringArray = [
	"Use the IDS Scanner to reveal the camouflaged Trojan horse. Once it is detected, your defenses can lock on and destroy it."
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
var _camera_start_global_position := Vector2.ZERO
var _camera_start_zoom := Vector2.ONE
var _camera_tween: Tween
var _phase_one_attack_tween: Tween
var _phase_two_intro_tween: Tween
var _phase_end_tween: Tween
var _phase_one_hover_tweens: Array[Tween] = []
var _phase_one_sequence_tweens: Array[Tween] = []
var _phase_one_hover_start_positions := {}
var _phase_one_initial_positions := {}
var _phase_one_initial_modulates := {}
var _phase_one_destroy_sfx_players: Array[AudioStreamPlayer] = []
var _wave5_preview_trojan: TrojanHorse
var _last_handled_cutscene_input_event_id := 0
var _skip_requested := false
var _cutscene_finished_emitted := false


func _ready() -> void:
	visible = true
	_continue_button.pressed.connect(_advance_dialogue)
	_root.gui_input.connect(_on_root_gui_input)
	_ensure_continue_button_styles()
	_speaker_label.text = "CYBER GUARDIAN"
	_cutscene_camera = get_node_or_null(cutscene_camera_path) as Camera2D
	_capture_cutscene_camera_start()
	_root.visible = false
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if play_on_ready:
		call_deferred("start_cutscene")


func start_cutscene() -> void:
	if _running:
		return

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

	_running = true
	_skip_requested = false
	_cutscene_finished_emitted = false
	visible = true
	current_act = ACT_WAVE_FIVE
	current_phase = &""
	_current_phase_finished = false
	act_started.emit(current_act)
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


func _run_act_one_phase_one() -> void:
	_start_phase(PHASE_ONE)
	_prepare_phase_one_camera()
	_dim_overlay.hide()
	_dialogue_panel.hide()
	_mascot.hide()
	_continue_button.hide()
	_alert_overlay.show()
	_alert_overlay.color = Color(red_alert_color.r, red_alert_color.g, red_alert_color.b, 0.0)

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
	if handle_cutscene_advance_input(event):
		_root.accept_event()


func _is_enter_press(event: InputEvent) -> bool:
	if event is InputEventKey:
		var key_event := event as InputEventKey
		return key_event.pressed \
			and not key_event.echo \
			and (key_event.keycode == KEY_ENTER or key_event.keycode == KEY_KP_ENTER)

	return false


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
	_cleanup_wave5_preview_trojan()
	_restore_cutscene_camera_to_start()
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
	_cleanup_wave5_preview_trojan()
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


func _pan_camera_to_target(target_position: Vector2, camera_padding: Vector2) -> void:
	if _cutscene_camera == null:
		await get_tree().create_timer(camera_pan_duration).timeout
		return

	_kill_tween(_camera_tween)
	_camera_tween = create_tween()
	_camera_tween.set_parallel(true)
	_camera_tween.tween_property(_cutscene_camera, "global_position", target_position + camera_padding, camera_pan_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_camera_tween.tween_property(_cutscene_camera, "zoom", Vector2.ONE * phase_one_camera_zoom, camera_pan_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
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


func _play_phase_one_virus_destroy_sfx(delay: float) -> void:
	var player := AudioStreamPlayer.new()
	player.name = "PhaseOneVirusDestroySfx"
	player.stream = PHASE_ONE_DESTROY_SFX
	add_child(player)
	_phase_one_destroy_sfx_players.append(player)
	player.finished.connect(func() -> void:
		_phase_one_destroy_sfx_players.erase(player)
		player.queue_free()
	)

	if delay <= 0.0:
		player.play()
		return

	var sound_tween := create_tween()
	sound_tween.tween_interval(delay)
	sound_tween.tween_callback(func() -> void:
		if is_instance_valid(player):
			player.play()
	)


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
