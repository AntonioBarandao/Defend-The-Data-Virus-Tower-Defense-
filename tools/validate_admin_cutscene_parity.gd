extends SceneTree


func _initialize() -> void:
	var admin_scene := load("res://Scenes/Gameplay/Admin_Sandbox.tscn") as PackedScene
	if not _require(admin_scene != null, "Admin Sandbox could not be loaded."):
		return

	var admin := admin_scene.instantiate()
	root.add_child(admin)
	await process_frame
	await physics_frame

	var cutscene := admin.get_node_or_null("TextCutsceneHUD") as TextCutsceneHUD
	var director := admin.get_node_or_null("CutsceneDemoDirector") as CutsceneDemoDirector
	var zombie := admin.get_node_or_null("ZombieNode") as ZombieNode
	var camera := admin.get_node_or_null("CutsceneCamera") as Camera2D
	var trojan_preview := admin.get_node_or_null("Otherground_Cutscene/CutsceneBack/Wave5CutsceneTrojanHorse") as TrojanHorse
	if not _require(
		cutscene != null
			and director != null
			and zombie != null
			and camera != null
			and trojan_preview != null,
		"Admin Sandbox is missing inherited non-starting cutscene dependencies."
	):
		return

	if not _require(not cutscene.play_on_ready, "Admin Sandbox still enables the opening cutscene."):
		return
	if not _require(not cutscene.is_cutscene_running(), "The opening cutscene started in Admin Sandbox."):
		return

	admin.call("set_current_wave_for_demo", 4)
	await process_frame
	if not _require(
		bool(admin.call("_should_play_wave_five_cutscene")),
		"Admin Sandbox does not allow the inherited wave 5 Trojan cutscene."
	):
		return

	admin.call("set_current_wave_for_demo", 10)
	await process_frame
	if not _require(
		bool(admin.call("_should_play_zombie_node_entrance")),
		"Admin Sandbox does not allow the inherited wave 11 Zombie Node cutscene."
	):
		return

	admin.free()
	print("Admin cutscene parity validation passed: opening disabled, wave 5 and wave 11 enabled.")
	quit(0)


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	quit(1)
	return false
