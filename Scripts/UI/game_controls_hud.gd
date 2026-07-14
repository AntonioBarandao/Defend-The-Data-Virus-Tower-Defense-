class_name GameControlsHUD
extends CanvasLayer

const ADD_TEN_VIRUS_COUNT := 10
const ADD_HUNDRED_VIRUS_COUNT := 100

signal reset_pressed
signal start_wave_pressed
signal add_ten_pressed
signal add_hundred_pressed
signal virus_batch_requested(count: int)
signal exit_pressed

@onready var _reset_button: Button = $Root/BottomRightControls/ResetTowerButton
@onready var _wave_button: Button = $Root/BottomRightControls/StartWaveButton
@onready var _add_ten_button: Button = $Root/VirusBatchControls/AddTenVirusesButton
@onready var _add_hundred_button: Button = $Root/VirusBatchControls/AddHundredVirusesButton
@onready var _menu_button: Button = get_node_or_null(^"Root/MainMenuButton") as Button
@onready var _menu_panel: PanelContainer = get_node_or_null(^"Root/MainMenuPanel") as PanelContainer
@onready var _continue_button: Button = get_node_or_null(^"Root/MainMenuPanel/Margin/Options/ContinueButton") as Button
@onready var _settings_button: Button = get_node_or_null(^"Root/MainMenuPanel/Margin/Options/SettingsButton") as Button
@onready var _exit_button: Button = get_node_or_null(^"Root/MainMenuPanel/Margin/Options/ExitButton") as Button


func _ready() -> void:
	_reset_button.pressed.connect(func() -> void: reset_pressed.emit())
	_wave_button.pressed.connect(func() -> void: start_wave_pressed.emit())
	_add_ten_button.pressed.connect(_request_ten_viruses)
	_add_hundred_button.pressed.connect(_request_hundred_viruses)
	if _menu_panel != null:
		_menu_panel.hide()
	if _menu_button != null:
		_menu_button.hide()
		_menu_button.disabled = true
	if _continue_button != null:
		_continue_button.pressed.connect(hide_menu)
	if _settings_button != null:
		_settings_button.pressed.connect(hide_menu)
	if _exit_button != null:
		_exit_button.pressed.connect(func() -> void: exit_pressed.emit())


func set_wave_button(text: String, disabled: bool) -> void:
	_wave_button.text = text
	_wave_button.disabled = disabled


func set_spawn_buttons_disabled(disabled: bool) -> void:
	_add_ten_button.disabled = disabled
	_add_hundred_button.disabled = disabled


func has_gameplay_control_at_screen_position(screen_position: Vector2) -> bool:
	var controls: Array[Control] = [
		_wave_button,
		_reset_button,
		_add_ten_button,
		_add_hundred_button
	]
	for control in controls:
		if control != null \
				and control.visible \
				and not control.disabled \
				and control.get_global_rect().has_point(screen_position):
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
	if _menu_panel != null:
		_menu_panel.show()


func hide_menu() -> void:
	if _menu_panel != null:
		_menu_panel.hide()
