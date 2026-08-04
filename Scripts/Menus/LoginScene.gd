extends Control

const MAIN_MENU_SCENE := "res://Scenes/Menus/MainMenu.tscn"
const SESSION_USERNAME_META := &"logged_in_username"
const WELCOME_PENDING_META := &"login_welcome_pending"
var auth: Object = null
var _back_touch_index := -1
var _returning_to_menu := false

func _ready():
	if ClassDB.class_exists(&"AuthWrapper"):
		auth = ClassDB.instantiate(&"AuthWrapper")
	$FormPanel/VBox/LoginButton.pressed.connect(_on_login_pressed)
	$FormPanel/VBox/BackButton.pressed.connect(_on_back_pressed)
	$FormPanel/VBox/RegisterButton.pressed.connect(_on_register_pressed)
	$FormPanel/VBox/UsernameInput.text_submitted.connect(_focus_password)
	$FormPanel/VBox/PasswordInput.text_submitted.connect(_submit_login)
	$FormPanel/VBox/UsernameInput.grab_focus()


func _on_login_pressed(): 
	var username = $FormPanel/VBox/UsernameInput.text.strip_edges()
	var password = $FormPanel/VBox/PasswordInput.text

	if username.is_empty() or password.is_empty():
		$FormPanel/VBox/StatusLabel.text = "Enter your username and password."
		return

	if auth == null or not auth.has_method(&"login"):
		$FormPanel/VBox/StatusLabel.text = "Account login is unavailable on this platform."
		return

	if auth.login(username, password):
		get_tree().root.set_meta(SESSION_USERNAME_META, username)
		get_tree().root.set_meta(WELCOME_PENDING_META, true)

		var err := get_tree().change_scene_to_file(MAIN_MENU_SCENE)
		if err != OK:
			get_tree().root.remove_meta(SESSION_USERNAME_META)
			get_tree().root.remove_meta(WELCOME_PENDING_META)
			$FormPanel/VBox/StatusLabel.text = "Unable to return to the main menu."
	else:
		$FormPanel/VBox/StatusLabel.text = "Invalid username or password."

func _on_back_pressed():
	if _returning_to_menu:
		return
	_returning_to_menu = true
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)

func _on_register_pressed():
	get_tree().change_scene_to_file(
		"res://Scenes/Menus/RegisterScene.tscn"
	)

func _focus_password(_text: String) -> void:
	$FormPanel/VBox/PasswordInput.grab_focus()

func _submit_login(_text: String) -> void:
	_on_login_pressed()


func _input(event: InputEvent) -> void:
	if not event is InputEventScreenTouch or _returning_to_menu:
		return

	var touch := event as InputEventScreenTouch
	var back_button := $FormPanel/VBox/BackButton as Button
	if touch.pressed:
		if back_button.get_global_rect().has_point(touch.position):
			_back_touch_index = touch.index
			get_viewport().set_input_as_handled()
		return

	if touch.index != _back_touch_index:
		return

	_back_touch_index = -1
	get_viewport().set_input_as_handled()
	if back_button.get_global_rect().has_point(touch.position):
		_on_back_pressed()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
