extends Control

const MAIN_MENU_SCENE := "res://Scenes/Menus/MainMenu.tscn"
const LOGIN_SCENE := "res://Scenes/Menus/LoginScene.tscn"
const SESSION_USERNAME_META := &"logged_in_username"
const WELCOME_PENDING_META := &"login_welcome_pending"
const ACCOUNT_RETURN_SCENE_META := &"account_return_main_menu_scene"

@onready var username_value: Label = $AccountPanel/Margin/Content/UsernameValue
@onready var logout_button: Button = $AccountPanel/Margin/Content/LogoutButton
@onready var back_button: Button = $AccountPanel/Margin/Content/BackButton
@onready var status_label: Label = $AccountPanel/Margin/Content/Status

var _main_menu_load_requested := false
var _returning_to_menu := false
var _cached_main_menu: PackedScene
var _back_touch_index := -1


func _ready() -> void:
	var username := String(get_tree().root.get_meta(SESSION_USERNAME_META, "")).strip_edges()
	if username.is_empty():
		get_tree().change_scene_to_file(LOGIN_SCENE)
		return

	username_value.text = username
	logout_button.pressed.connect(_on_logout_pressed)
	back_button.pressed.connect(_on_back_pressed)
	back_button.grab_focus()
	_cached_main_menu = get_tree().root.get_meta(
		ACCOUNT_RETURN_SCENE_META,
		null
	) as PackedScene
	if _cached_main_menu == null:
		_request_main_menu_load()


func _process(_delta: float) -> void:
	if _returning_to_menu:
		_finish_main_menu_transition_if_ready()


func _on_logout_pressed() -> void:
	_clear_session()
	_return_to_main_menu()


func _clear_session() -> void:
	get_tree().root.remove_meta(SESSION_USERNAME_META)
	get_tree().root.remove_meta(WELCOME_PENDING_META)


func _on_back_pressed() -> void:
	_return_to_main_menu()


func _input(event: InputEvent) -> void:
	if not event is InputEventScreenTouch or _returning_to_menu:
		return

	var touch := event as InputEventScreenTouch
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
		_return_to_main_menu()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
		get_viewport().set_input_as_handled()


func _request_main_menu_load() -> void:
	if _main_menu_load_requested:
		return

	var request_error := ResourceLoader.load_threaded_request(
		MAIN_MENU_SCENE,
		"PackedScene",
		false,
		ResourceLoader.CACHE_MODE_REUSE
	)
	if request_error == OK:
		_main_menu_load_requested = true
		return

	push_warning(
		"Unable to preload the Main Menu: %s" % error_string(request_error)
	)


func _return_to_main_menu() -> void:
	if _returning_to_menu:
		return

	_returning_to_menu = true
	back_button.disabled = true
	logout_button.disabled = true
	status_label.text = "RETURNING TO MENU..."
	if _cached_main_menu != null:
		_change_to_main_menu(_cached_main_menu)
		return
	_request_main_menu_load()
	_finish_main_menu_transition_if_ready()


func _finish_main_menu_transition_if_ready() -> void:
	if not _main_menu_load_requested:
		_fallback_to_main_menu()
		return

	match ResourceLoader.load_threaded_get_status(MAIN_MENU_SCENE):
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			return
		ResourceLoader.THREAD_LOAD_LOADED:
			var main_menu := ResourceLoader.load_threaded_get(
				MAIN_MENU_SCENE
			) as PackedScene
			if main_menu != null:
				_change_to_main_menu(main_menu)
				return
			_fallback_to_main_menu()
		ResourceLoader.THREAD_LOAD_FAILED, \
		ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			_fallback_to_main_menu()


func _change_to_main_menu(main_menu: PackedScene) -> void:
	get_tree().root.remove_meta(ACCOUNT_RETURN_SCENE_META)
	var change_error := get_tree().change_scene_to_packed(main_menu)
	if change_error == OK:
		return

	push_warning(
		"Unable to open the cached Main Menu: %s"
			% error_string(change_error)
	)
	_fallback_to_main_menu()


func _fallback_to_main_menu() -> void:
	set_process(false)
	get_tree().root.remove_meta(ACCOUNT_RETURN_SCENE_META)
	var change_error := get_tree().change_scene_to_file(MAIN_MENU_SCENE)
	if change_error != OK:
		_returning_to_menu = false
		back_button.disabled = false
		logout_button.disabled = false
		status_label.text = "UNABLE TO RETURN TO MENU"
		push_error(
			"Unable to open the Main Menu: %s" % error_string(change_error)
		)
