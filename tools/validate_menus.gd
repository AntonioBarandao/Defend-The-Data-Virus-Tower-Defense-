extends SceneTree

const MENU_SCENES := [
	"res://Scenes/Menus/MainMenu.tscn",
	"res://Scenes/Menus/LoginScene.tscn",
	"res://Scenes/Menus/RegisterScene.tscn",
	"res://Scenes/Menus/AccountScene.tscn",
]

func _initialize() -> void:
	for scene_path in MENU_SCENES:
		if scene_path.ends_with("AccountScene.tscn"):
			root.set_meta(&"logged_in_username", "ValidationUser")
		var packed := load(scene_path) as PackedScene
		if packed == null:
			push_error("Unable to load %s" % scene_path)
			quit(1)
			return
		var instance := packed.instantiate()
		if instance.get_script() == null:
			push_error("Root script did not load for %s" % scene_path)
			quit(1)
			return
		root.add_child(instance)
		await process_frame
		instance.queue_free()
		await process_frame
	root.remove_meta(&"logged_in_username")

	root.set_meta(&"logged_in_username", "ValidationUser")
	root.set_meta(&"login_welcome_pending", true)
	var main_menu := (load("res://Scenes/Menus/MainMenu.tscn") as PackedScene).instantiate()
	root.add_child(main_menu)
	await process_frame
	var status_label := main_menu.get_node(^"StatusLabel") as Label
	var account_button := main_menu.get_node(^"MenuPanel/VBox/LoginButton") as Button
	var welcome_banner := main_menu.get_node(^"WelcomeBanner") as PanelContainer
	var welcome_label := main_menu.get_node(^"WelcomeBanner/Margin/WelcomeLabel") as Label
	if status_label.text != "Secure your knowledge. Protect the system.":
		push_error("Welcome banner replaced the main menu status message.")
		quit(1)
		return
	if not welcome_banner.visible or welcome_label.text != "WELCOME, ValidationUser!":
		push_error("Main menu did not display the logged-in username banner.")
		quit(1)
		return
	if account_button.text != "ACCOUNT":
		push_error("Main menu account button has an incorrect label.")
		quit(1)
		return

	var account_scene := (load("res://Scenes/Menus/AccountScene.tscn") as PackedScene).instantiate()
	root.add_child(account_scene)
	await process_frame
	var username_value := account_scene.get_node(^"AccountPanel/Margin/Content/UsernameValue") as Label
	if username_value.text != "ValidationUser":
		push_error("Account scene did not display the active username.")
		quit(1)
		return
	account_scene.call("_clear_session")
	if root.has_meta(&"logged_in_username"):
		push_error("Account logout did not clear the active session.")
		quit(1)
		return
	account_scene.queue_free()
	root.set_meta(&"logged_in_username", "ValidationUser")
	main_menu.call("_activate_easter_egg")
	await process_frame
	var jumpscare_overlay := main_menu.get_node(^"JumpscareOverlay") as ColorRect
	var jumpscare_icon := main_menu.get_node(^"JumpscareOverlay/Icon") as TextureRect
	if not jumpscare_overlay.visible or jumpscare_icon.texture == null:
		push_error("Main menu easter egg did not activate.")
		quit(1)
		return
	main_menu.queue_free()
	root.remove_meta(&"logged_in_username")
	root.remove_meta(&"login_welcome_pending")
	await process_frame
	print("Menu validation passed: %d scenes loaded and initialized." % MENU_SCENES.size())
	quit()
