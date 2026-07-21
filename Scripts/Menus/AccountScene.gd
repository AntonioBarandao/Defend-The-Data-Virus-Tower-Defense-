extends Control

const MAIN_MENU_SCENE := "res://Scenes/Menus/MainMenu.tscn"
const LOGIN_SCENE := "res://Scenes/Menus/LoginScene.tscn"
const SESSION_USERNAME_META := &"logged_in_username"
const WELCOME_PENDING_META := &"login_welcome_pending"

@onready var username_value: Label = $AccountPanel/Margin/Content/UsernameValue
@onready var logout_button: Button = $AccountPanel/Margin/Content/LogoutButton
@onready var back_button: Button = $AccountPanel/Margin/Content/BackButton


func _ready() -> void:
	var username := String(get_tree().root.get_meta(SESSION_USERNAME_META, "")).strip_edges()
	if username.is_empty():
		get_tree().change_scene_to_file(LOGIN_SCENE)
		return

	username_value.text = username
	logout_button.pressed.connect(_on_logout_pressed)
	back_button.pressed.connect(_on_back_pressed)
	back_button.grab_focus()


func _on_logout_pressed() -> void:
	_clear_session()
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


func _clear_session() -> void:
	get_tree().root.remove_meta(SESSION_USERNAME_META)
	get_tree().root.remove_meta(WELCOME_PENDING_META)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
