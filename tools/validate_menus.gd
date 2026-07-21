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
	print("Menu validation passed: %d scenes loaded and initialized." % MENU_SCENES.size())
	quit()
