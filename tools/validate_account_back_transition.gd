extends SceneTree

const MAIN_MENU_SCENE := preload("res://Scenes/Menus/MainMenu.tscn")
const MAIN_MENU_PATH := "res://Scenes/Menus/MainMenu.tscn"
const ACCOUNT_SCENE_PATH := "res://Scenes/Menus/AccountScene.tscn"
const LOGIN_SCENE_PATH := "res://Scenes/Menus/LoginScene.tscn"
const SESSION_USERNAME_META := &"logged_in_username"
const ACCOUNT_RETURN_SCENE_META := &"account_return_main_menu_scene"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.set_meta(SESSION_USERNAME_META, "TransitionTest")
	var main_menu := MAIN_MENU_SCENE.instantiate()
	root.add_child(main_menu)
	current_scene = main_menu
	await process_frame
	main_menu.call("_on_login_pressed")
	for _frame in range(10):
		await process_frame
		if current_scene != main_menu:
			break

	var account := current_scene
	if account == null \
			or account.scene_file_path != ACCOUNT_SCENE_PATH \
			or not root.has_meta(ACCOUNT_RETURN_SCENE_META):
		_fail("Main Menu did not open Account with a cached return scene.")
		return
	await process_frame

	var transition_started_at := Time.get_ticks_msec()
	var account_back := account.get_node(
		"AccountPanel/Margin/Content/BackButton"
	) as Button
	await _tap_control(account, account_back)
	for _frame in range(10):
		await process_frame
		if current_scene != account:
			break

	var transition_msec := Time.get_ticks_msec() - transition_started_at
	if current_scene == account \
			or current_scene == null \
			or current_scene.scene_file_path != MAIN_MENU_PATH:
		_fail("Account screen did not transition to the preloaded Main Menu.")
		return

	root.remove_meta(SESSION_USERNAME_META)
	var login_error := change_scene_to_file(LOGIN_SCENE_PATH)
	if login_error != OK:
		_fail("Unable to open Login screen for mobile touch validation.")
		return
	await scene_changed
	await process_frame

	var login := current_scene
	var login_back := login.get_node("FormPanel/VBox/BackButton") as Button
	await _tap_control(login, login_back)
	for _frame in range(10):
		await process_frame
		if current_scene != login:
			break
	if current_scene == login \
			or current_scene == null \
			or current_scene.scene_file_path != MAIN_MENU_PATH:
		_fail("Login Back button did not accept mobile touch input.")
		return

	print(
		"Mobile menu return passed: account switch=%d ms."
			% transition_msec
	)
	quit(0)


func _tap_control(receiver: Node, control: Control) -> void:
	var tap_position := control.get_global_rect().get_center()
	var press := InputEventScreenTouch.new()
	press.index = 0
	press.position = tap_position
	press.pressed = true
	receiver.call("_input", press)
	await process_frame

	var release := InputEventScreenTouch.new()
	release.index = 0
	release.position = tap_position
	release.pressed = false
	receiver.call("_input", release)
	await process_frame


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
