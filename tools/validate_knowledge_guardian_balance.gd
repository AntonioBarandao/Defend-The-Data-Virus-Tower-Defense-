extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var progress_scene := load("res://Scenes/UI/ProgressHUD.tscn") as PackedScene
	_check(progress_scene != null, "Progress HUD scene loads")
	if progress_scene != null:
		var progress_hud := progress_scene.instantiate() as ProgressHUD
		root.add_child(progress_hud)
		await process_frame
		progress_hud.add_knowledge_points(4)
		_check(progress_hud.get_knowledge_level() == 1, "Knowledge LV1 requires 5 KP")
		progress_hud.add_knowledge_points(1)
		_check(progress_hud.get_knowledge_level() == 2, "5 KP advances Knowledge LV1 to LV2")
		progress_hud.add_knowledge_points(7)
		_check(progress_hud.get_knowledge_level() == 3, "7 KP advances Knowledge LV2 to LV3")
		progress_hud.add_knowledge_points(10)
		_check(progress_hud.get_knowledge_level() == 4, "10 KP advances Knowledge LV3 to LV4")
		progress_hud.queue_free()

	var guardian_scene := load("res://Scenes/Towers/CyberGuardian.tscn") as PackedScene
	_check(guardian_scene != null, "Cyber Guardian scene loads")
	if guardian_scene != null:
		var guardian := guardian_scene.instantiate() as CyberGuardianTower
		root.add_child(guardian)
		await process_frame
		var unlocked_modes := guardian.get_unlocked_mode_ids(1)
		for mode_id in [&"defender", &"signal_boost", &"firewall"]:
			_check(mode_id in unlocked_modes, "%s is unlocked at Knowledge LV1" % guardian.get_mode_display_name(mode_id))
			_check(guardian.set_guardian_mode(mode_id), "%s can be selected" % guardian.get_mode_display_name(mode_id))
		guardian.queue_free()

	await process_frame
	_finish()


func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
	else:
		_failures.append(message)
		push_error("FAIL: %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("Knowledge and Guardian balance validation passed.")
		quit(0)
	else:
		quit(1)
