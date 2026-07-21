extends Control

const MAIN_MENU_SCENE := "res://Scenes/Menus/MainMenu.tscn"
const SESSION_USERNAME_META := &"logged_in_username"
const WELCOME_PENDING_META := &"login_welcome_pending"


func _ready():
	$FormPanel/VBox/LoginButton.pressed.connect(_on_login_pressed)
	$FormPanel/VBox/BackButton.pressed.connect(_on_back_pressed)
	$FormPanel/VBox/RegisterButton.pressed.connect(_on_register_pressed)
	$FormPanel/VBox/UsernameInput.text_submitted.connect(_focus_password)
	$FormPanel/VBox/PasswordInput.text_submitted.connect(_submit_login)
	$FormPanel/VBox/UsernameInput.grab_focus()

func _on_login_pressed():
	var username: String = $FormPanel/VBox/UsernameInput.text.strip_edges()
	var password: String = $FormPanel/VBox/PasswordInput.text
	if username.is_empty() or password.is_empty():
		$FormPanel/VBox/StatusLabel.text = "Enter your username and password."
		return

	get_tree().root.set_meta(SESSION_USERNAME_META, username)
	get_tree().root.set_meta(WELCOME_PENDING_META, true)
	var change_error := get_tree().change_scene_to_file(MAIN_MENU_SCENE)
	if change_error != OK:
		get_tree().root.remove_meta(SESSION_USERNAME_META)
		get_tree().root.remove_meta(WELCOME_PENDING_META)
		$FormPanel/VBox/StatusLabel.text = "Unable to return to the main menu."

func _on_back_pressed():
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)

func _on_register_pressed():
	get_tree().change_scene_to_file(
		"res://Scenes/Menus/RegisterScene.tscn"
	)

func _focus_password(_text: String) -> void:
	$FormPanel/VBox/PasswordInput.grab_focus()

func _submit_login(_text: String) -> void:
	_on_login_pressed()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
