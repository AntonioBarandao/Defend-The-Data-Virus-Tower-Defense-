extends SceneTree

const MENU_SCENES := [
	"res://Scenes/Menus/MainMenu.tscn",
	"res://Scenes/Menus/LoginScene.tscn",
	"res://Scenes/Menus/RegisterScene.tscn",
]

func _initialize() -> void:
	for scene_path in MENU_SCENES:
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
	if account_button.text != "SIGNED IN: ValidationUser":
		push_error("Account button did not reflect the active login session.")
		quit(1)
		return
	account_button.pressed.emit()
	await process_frame
	if status_label.text != "Signed in as ValidationUser.":
		push_error("Signed-in account button attempted to reopen the login screen.")
		quit(1)
		return
	main_menu.call("_activate_easter_egg")
	await process_frame
	if not welcome_banner.visible or welcome_label.text != "SECURITY BREACH DETECTED: IT WAS THE OFFICE PRINTER.":
		push_error("Main menu easter egg did not activate.")
		quit(1)
		return
	main_menu.queue_free()
	root.remove_meta(&"logged_in_username")
	root.remove_meta(&"login_welcome_pending")
	await process_frame
	print("Menu validation passed: %d scenes loaded and initialized." % MENU_SCENES.size())
	quit()
