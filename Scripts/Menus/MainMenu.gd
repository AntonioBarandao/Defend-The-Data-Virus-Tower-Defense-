extends Control

const SESSION_USERNAME_META := &"logged_in_username"
const WELCOME_PENDING_META := &"login_welcome_pending"

@onready var background: TextureRect = $Background
@onready var scanline: ColorRect = $Scanline
@onready var title_label: Label = $MenuPanel/VBox/Title
@onready var user_game_button: Button = $MenuPanel/VBox/UserGameButton
@onready var admin_game_button: Button = $MenuPanel/VBox/AdminGameButton
@onready var login_button: Button = $MenuPanel/VBox/LoginButton
@onready var options_button: Button = $MenuPanel/VBox/OptionsButton
@onready var quit_button: Button = $MenuPanel/VBox/QuitButton
@onready var status_label: Label = $StatusLabel
@onready var welcome_banner: PanelContainer = $WelcomeBanner
@onready var welcome_label: Label = $WelcomeBanner/Margin/WelcomeLabel
@onready var presentation_button: Button = $PresentationButton
@onready var options_overlay: ColorRect = $OptionsOverlay
@onready var volume_slider: HSlider = $OptionsOverlay/Panel/Margin/VBox/VolumeSlider
@onready var volume_label: Label = $OptionsOverlay/Panel/Margin/VBox/VolumeLabel
@onready var fullscreen_check: CheckButton = $OptionsOverlay/Panel/Margin/VBox/FullscreenCheck
@onready var options_close_button: Button = $OptionsOverlay/Panel/Margin/VBox/CloseButton

var scan_speed := 120.0
var background_zoom_amount := 0.015
var time_passed := 0.0
var _logged_in_username := ""
var _title_click_count := 0
var _last_title_click_msec := 0
var _banner_tween: Tween

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
	title_label.gui_input.connect(_on_title_gui_input)
	fullscreen_check.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	var master_bus := AudioServer.get_bus_index("Master")
	volume_slider.value = db_to_linear(AudioServer.get_bus_volume_db(master_bus)) * 100.0
	_on_volume_changed(volume_slider.value)
	_sync_account_state()
	_show_logged_in_welcome()
	user_game_button.grab_focus()


func _sync_account_state() -> void:
	_logged_in_username = String(get_tree().root.get_meta(SESSION_USERNAME_META, "")).strip_edges()
	if _logged_in_username.is_empty():
		login_button.text = "ACCOUNT"
	else:
		login_button.text = "SIGNED IN: %s" % _logged_in_username


func _show_logged_in_welcome() -> void:
	var welcome_pending := bool(get_tree().root.get_meta(WELCOME_PENDING_META, false))
	if _logged_in_username.is_empty() or not welcome_pending:
		return

	get_tree().root.remove_meta(WELCOME_PENDING_META)
	welcome_label.text = "WELCOME, %s!" % _logged_in_username
	welcome_banner.show()
	welcome_banner.modulate.a = 0.0
	var rest_y := welcome_banner.position.y
	welcome_banner.position.y = rest_y - 45.0

	_banner_tween = create_tween()
	_banner_tween.set_parallel(true)
	_banner_tween.tween_property(welcome_banner, "modulate:a", 1.0, 0.35)
	_banner_tween.tween_property(welcome_banner, "position:y", rest_y, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_banner_tween.set_parallel(false)
	_banner_tween.tween_interval(20.0)
	_banner_tween.set_parallel(true)
	_banner_tween.tween_property(welcome_banner, "modulate:a", 0.0, 3.5)
	_banner_tween.tween_property(welcome_banner, "position:y", rest_y - 30.0, 3.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_banner_tween.set_parallel(false)
	_banner_tween.tween_callback(welcome_banner.hide)


func _on_title_gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	var mouse_event := event as InputEventMouseButton
	if mouse_event.button_index != MOUSE_BUTTON_LEFT or not mouse_event.pressed:
		return

	var now := Time.get_ticks_msec()
	if now - _last_title_click_msec > 1500:
		_title_click_count = 0
	_last_title_click_msec = now
	_title_click_count += 1
	if _title_click_count >= 5:
		_title_click_count = 0
		_activate_easter_egg()


func _activate_easter_egg() -> void:
	if _banner_tween != null:
		_banner_tween.kill()

	welcome_label.text = "SECURITY BREACH DETECTED: IT WAS THE OFFICE PRINTER."
	welcome_banner.show()
	welcome_banner.modulate.a = 0.0
	var rest_y := 42.0
	welcome_banner.position.y = rest_y - 45.0

	_banner_tween = create_tween()
	_banner_tween.set_parallel(true)
	_banner_tween.tween_property(welcome_banner, "modulate:a", 1.0, 0.25)
	_banner_tween.tween_property(welcome_banner, "position:y", rest_y, 0.4).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	_banner_tween.set_parallel(false)
	_banner_tween.tween_interval(6.0)
	_banner_tween.tween_property(welcome_banner, "modulate:a", 0.0, 1.0)
	_banner_tween.tween_callback(welcome_banner.hide)

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
	if not _logged_in_username.is_empty():
		status_label.text = "Signed in as %s." % _logged_in_username
		return

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
