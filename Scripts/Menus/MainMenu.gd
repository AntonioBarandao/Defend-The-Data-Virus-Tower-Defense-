extends Control

@onready var background: TextureRect = $Background
@onready var scanline: ColorRect = $Scanline
@onready var user_game_button: Button = $MenuPanel/VBox/UserGameButton
@onready var admin_game_button: Button = $MenuPanel/VBox/AdminGameButton
@onready var login_button: Button = $MenuPanel/VBox/LoginButton
@onready var options_button: Button = $MenuPanel/VBox/OptionsButton
@onready var quit_button: Button = $MenuPanel/VBox/QuitButton
@onready var status_label: Label = $StatusLabel
@onready var presentation_button: Button = $PresentationButton
@onready var options_overlay: ColorRect = $OptionsOverlay
@onready var volume_slider: HSlider = $OptionsOverlay/Panel/Margin/VBox/VolumeSlider
@onready var volume_label: Label = $OptionsOverlay/Panel/Margin/VBox/VolumeLabel
@onready var fullscreen_check: CheckButton = $OptionsOverlay/Panel/Margin/VBox/FullscreenCheck
@onready var options_close_button: Button = $OptionsOverlay/Panel/Margin/VBox/CloseButton

var scan_speed := 120.0
var background_zoom_amount := 0.015
var time_passed := 0.0

func _ready() -> void:
	user_game_button.pressed.connect(_on_user_game_pressed)
	admin_game_button.pressed.connect(_on_admin_game_pressed)
	login_button.pressed.connect(_on_login_pressed)
	options_button.pressed.connect(_on_options_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	presentation_button.pressed.connect(_on_presentation_pressed)
	volume_slider.value_changed.connect(_on_volume_changed)
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	options_close_button.pressed.connect(_close_options)
	fullscreen_check.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	var master_bus := AudioServer.get_bus_index("Master")
	volume_slider.value = db_to_linear(AudioServer.get_bus_volume_db(master_bus)) * 100.0
	_on_volume_changed(volume_slider.value)
	user_game_button.grab_focus()

func _process(delta: float) -> void:
	time_passed += delta


func _on_user_game_pressed() -> void:
	status_label.text = "Starting normal game..."
	_open_game_scene("res://Scenes/Gameplay/Normal_Game.tscn")


func _on_admin_game_pressed() -> void:
	status_label.text = "Opening admin sandbox..."
	_open_game_scene("res://Scenes/Gameplay/Admin_Sandbox.tscn")

func _on_presentation_pressed() -> void:
	status_label.text = "Opening presentation..."
	_open_game_scene("res://Scenes/Gameplay/DEMO_SCENE.tscn")

func _open_game_scene(scene_path: String) -> void:
	var load_error := LoadingScreen.open_game_scene(get_tree(), scene_path)
	if load_error != OK:
		status_label.text = "Unable to open game scene."

func _on_login_pressed() -> void:
	status_label.text = "Opening login..."
	get_tree().change_scene_to_file("res://Scenes/Menus/LoginScene.tscn")

func _on_options_pressed() -> void:
	options_overlay.show()
	options_close_button.grab_focus()

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_volume_changed(value: float) -> void:
	volume_label.text = "Master volume: %d%%" % roundi(value)
	var master_bus := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(master_bus, linear_to_db(maxf(value / 100.0, 0.001)))
	AudioServer.set_bus_mute(master_bus, value <= 0.0)

func _on_fullscreen_toggled(enabled: bool) -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if enabled else DisplayServer.WINDOW_MODE_WINDOWED)

func _close_options() -> void:
	options_overlay.hide()
	options_button.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and options_overlay.visible:
		_close_options()
		get_viewport().set_input_as_handled()
