class_name GameControlsHUD
extends CanvasLayer

const ADD_TEN_VIRUS_COUNT := 10
const ADD_HUNDRED_VIRUS_COUNT := 100
const NORMAL_GAME_SPEED := 1.0

signal reset_pressed
signal start_wave_pressed
signal add_ten_pressed
signal add_hundred_pressed
signal virus_batch_requested(count: int)
signal exit_pressed
signal game_speed_changed(multiplier: float)

@export var show_menu_button := true
@export_range(1.0, 4.0, 0.25) var accelerated_game_speed := 2.0
@export_group("Lives Card")
@export_range(0.0, 2.0, 0.05) var lives_store_slide_multiplier := 1.0
@export_range(1.0, 2.0, 0.05) var lives_stamp_start_scale := 1.55
@export_range(0.1, 1.0, 0.01) var lives_stamp_duration := 0.36
@export_group("")

@onready var _reset_button: Button = $Root/BottomRightControls/ResetTowerButton
@onready var _wave_button: Button = $Root/BottomRightControls/StartWaveButton
@onready var _speed_button: Button = $Root/BottomRightControls/SpeedButton
@onready var _add_ten_button: Button = $Root/VirusBatchControls/AddTenVirusesButton
@onready var _add_hundred_button: Button = $Root/VirusBatchControls/AddHundredVirusesButton
@onready var _menu_button: Button = get_node_or_null(^"Root/MainMenuButton") as Button
@onready var _menu_panel: PanelContainer = get_node_or_null(^"Root/MainMenuPanel") as PanelContainer
@onready var _continue_button: Button = get_node_or_null(^"Root/MainMenuPanel/Margin/Options/ContinueButton") as Button
@onready var _settings_button: Button = get_node_or_null(^"Root/MainMenuPanel/Margin/Options/SettingsButton") as Button
@onready var _exit_button: Button = get_node_or_null(^"Root/MainMenuPanel/Margin/Options/ExitButton") as Button
@onready var _lives_panel: PanelContainer = get_node_or_null(^"Root/LivesPanel") as PanelContainer
@onready var _lives_label: Label = get_node_or_null(^"Root/LivesPanel/Margin/Content/Readout/LivesLabel") as Label

var _was_tree_paused := false
var _lives_store_rest_position := Vector2.ZERO
var _lives_store_position_cached := false
var _lives_rest_scale := Vector2.ONE
var _lives_rest_modulate := Color.WHITE
var _lives_rest_pivot_offset := Vector2.ZERO
var _lives_stamp_tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Engine.time_scale = NORMAL_GAME_SPEED
	_reset_button.pressed.connect(func() -> void: reset_pressed.emit())
	_wave_button.pressed.connect(func() -> void: start_wave_pressed.emit())
	_speed_button.set_pressed_no_signal(false)
	_speed_button.toggled.connect(set_speed_enabled)
	_add_ten_button.pressed.connect(_request_ten_viruses)
	_add_hundred_button.pressed.connect(_request_hundred_viruses)
	if _menu_panel != null:
		_menu_panel.hide()
	if _menu_button != null:
		_menu_button.visible = show_menu_button
		_menu_button.disabled = not show_menu_button
		if show_menu_button:
			_menu_button.pressed.connect(toggle_menu)
	if _continue_button != null:
		_continue_button.pressed.connect(hide_menu)
	if _settings_button != null:
		_settings_button.disabled = true
		_settings_button.tooltip_text = "Settings are coming soon."
	if _exit_button != null:
		_exit_button.pressed.connect(func() -> void: exit_pressed.emit())
	_cache_lives_card_presentation()
	cache_store_companion_ui_position()


func _exit_tree() -> void:
	Engine.time_scale = NORMAL_GAME_SPEED


func set_speed_enabled(enabled: bool) -> void:
	var speed := accelerated_game_speed if enabled else NORMAL_GAME_SPEED
	Engine.time_scale = speed
	if _speed_button != null and _speed_button.button_pressed != enabled:
		_speed_button.set_pressed_no_signal(enabled)
	game_speed_changed.emit(speed)


func set_wave_button(text: String, disabled: bool) -> void:
	_wave_button.text = text
	_wave_button.disabled = disabled


func set_spawn_buttons_disabled(disabled: bool) -> void:
	_add_ten_button.disabled = disabled
	_add_hundred_button.disabled = disabled


func set_lives(current_lives: int, maximum_lives: int) -> void:
	if _lives_label == null:
		return
	_lives_label.text = "%d/%d" % [maxi(0, current_lives), maxi(1, maximum_lives)]


func set_lives_visible(is_visible: bool, animate_stamp := false) -> void:
	if _lives_panel == null:
		return

	_kill_lives_stamp_tween()
	if not is_visible:
		_lives_panel.hide()
		_restore_lives_card_presentation()
		return

	if animate_stamp:
		_play_lives_stamp_reveal()
	else:
		_restore_lives_card_presentation()
		_lives_panel.show()


func cache_store_companion_ui_position() -> void:
	if _lives_panel == null or _lives_store_position_cached:
		return
	_lives_store_rest_position = _lives_panel.global_position
	_lives_store_position_cached = true


func apply_store_companion_slide(slide_offset: float) -> void:
	cache_store_companion_ui_position()
	if _lives_panel == null or not _lives_store_position_cached:
		return
	_lives_panel.global_position = _lives_store_rest_position + Vector2(
		slide_offset * lives_store_slide_multiplier,
		0.0
	)


func _cache_lives_card_presentation() -> void:
	if _lives_panel == null:
		return
	_lives_rest_scale = _lives_panel.scale
	_lives_rest_modulate = _lives_panel.modulate
	_lives_rest_pivot_offset = _lives_panel.pivot_offset


func _play_lives_stamp_reveal() -> void:
	_restore_lives_card_presentation()
	_lives_panel.show()
	_lives_panel.pivot_offset = _lives_panel.size * 0.5
	_lives_panel.scale = _lives_rest_scale * lives_stamp_start_scale
	_lives_panel.modulate = Color(
		minf(1.35, _lives_rest_modulate.r * 1.22),
		minf(1.35, _lives_rest_modulate.g * 1.22),
		minf(1.35, _lives_rest_modulate.b * 1.22),
		0.0
	)

	var impact_duration := lives_stamp_duration * 0.48
	var rebound_duration := lives_stamp_duration * 0.22
	var settle_duration := lives_stamp_duration - impact_duration - rebound_duration
	_lives_stamp_tween = create_tween()
	_lives_stamp_tween.set_parallel(true)
	_lives_stamp_tween.tween_property(_lives_panel, "scale", _lives_rest_scale * 0.92, impact_duration).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
	_lives_stamp_tween.tween_property(_lives_panel, "modulate", _lives_rest_modulate, impact_duration * 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_lives_stamp_tween.set_parallel(false)
	_lives_stamp_tween.tween_property(_lives_panel, "scale", _lives_rest_scale * 1.07, rebound_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_lives_stamp_tween.tween_property(_lives_panel, "scale", _lives_rest_scale, settle_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_lives_stamp_tween.tween_callback(func() -> void:
		_lives_stamp_tween = null
		_restore_lives_card_presentation()
	)


func _restore_lives_card_presentation() -> void:
	if _lives_panel == null:
		return
	_lives_panel.scale = _lives_rest_scale
	_lives_panel.modulate = _lives_rest_modulate
	_lives_panel.pivot_offset = _lives_rest_pivot_offset


func _kill_lives_stamp_tween() -> void:
	if _lives_stamp_tween != null and _lives_stamp_tween.is_valid():
		_lives_stamp_tween.kill()
	_lives_stamp_tween = null


func set_admin_mode(enabled: bool) -> void:
	$Root/VirusBatchControls.visible = enabled
	_reset_button.visible = enabled
	_wave_button.visible = true


func has_gameplay_control_at_screen_position(screen_position: Vector2) -> bool:
	var controls: Array[Control] = [
		_wave_button,
		_reset_button,
		_add_ten_button,
		_add_hundred_button,
		_speed_button,
		_menu_button,
		_menu_panel
	]
	for control in controls:
		if control != null and control.visible and control.get_global_rect().has_point(screen_position):
			return true

	return false


func _request_ten_viruses() -> void:
	add_ten_pressed.emit()
	virus_batch_requested.emit(ADD_TEN_VIRUS_COUNT)


func _request_hundred_viruses() -> void:
	add_hundred_pressed.emit()
	virus_batch_requested.emit(ADD_HUNDRED_VIRUS_COUNT)


func toggle_menu() -> void:
	if _menu_panel == null:
		return

	if _menu_panel.visible:
		hide_menu()
	else:
		show_menu()


func show_menu() -> void:
	if _menu_panel == null or _menu_panel.visible:
		return
	_was_tree_paused = get_tree().paused
	get_tree().paused = true
	_menu_panel.show()


func hide_menu() -> void:
	if _menu_panel == null:
		return
	_menu_panel.hide()
	get_tree().paused = _was_tree_paused


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		toggle_menu()
		get_viewport().set_input_as_handled()
