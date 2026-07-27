extends SceneTree

const ADMIN_SANDBOX := preload("res://Scenes/Gameplay/Admin_Sandbox.tscn")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := ADMIN_SANDBOX.instantiate()
	root.add_child(game)
	await process_frame

	var menu := game.get_node_or_null("CutsceneDemoMenuHUD") as CutsceneDemoMenuHUD
	var wave_input := game.get_node_or_null(
		"CutsceneDemoMenuHUD/Root/WaveSetPanel/Margin/Content/WaveInput"
	) as LineEdit
	var botnet := game.get_node_or_null("BotnetNode") as BotnetNode
	var zombie := game.get_node_or_null("ZombieNode") as ZombieNode
	var clearance := game.get_node_or_null(
		"Wave20ClearanceHUD"
	) as Wave20ClearanceHUD
	if menu == null \
			or wave_input == null \
			or zombie == null \
			or botnet == null \
			or clearance == null:
		push_error("Admin Sandbox wave manager nodes are incomplete.")
		quit(1)
		return

	wave_input.text = "15"
	menu.call("_apply_wave_set")
	await process_frame
	if int(game.call("get_current_wave")) != 15 \
			or zombie.active \
			or not zombie.is_defeated():
		push_error(
			"Admin Wave 15 did not retire the completed Zombie Node."
		)
		quit(1)
		return

	game.call("_start_next_wave")
	await process_frame
	if int(game.call("get_current_wave")) != 16 or zombie.active:
		push_error(
			"Admin Sandbox restored the Zombie Node after starting Wave 16."
		)
		quit(1)
		return

	wave_input.text = "20"
	menu.call("_apply_wave_set")
	await process_frame
	game.call("_show_wave_20_clearance_cutscene")
	await process_frame
	if int(game.call("get_current_wave")) != 20 \
			or int(game.call("get_wave_max_count")) != 25 \
			or clearance.is_cutscene_running():
		push_error(
			"Admin Wave 20 did not bypass the clearance prompt and unlock /25."
		)
		quit(1)
		return

	game.call("_start_next_wave")
	await process_frame
	if int(game.call("get_current_wave")) != 21 \
			or not botnet.active \
			or botnet.get_level() != 1:
		push_error(
			"Admin Sandbox could not start Wave 21 after manually setting Wave 20."
		)
		quit(1)
		return

	wave_input.text = "25"
	menu.call("_apply_wave_set")
	await process_frame
	if menu.wave_manager_max_wave != 25 \
			or int(game.call("get_current_wave")) != 25 \
			or int(game.call("get_wave_max_count")) != 25 \
			or wave_input.text != "25" \
			or not botnet.active \
			or botnet.get_level() != 3:
		push_error("The Admin Sandbox wave manager did not apply wave 25.")
		quit(1)
		return

	print(
		"Admin wave manager validation passed: completed Wave 15 retires "
		+ "the Zombie Node, Wave 20 bypasses clearance, and Waves 21-25 "
		+ "remain configurable."
	)
	game.queue_free()
	quit(0)
