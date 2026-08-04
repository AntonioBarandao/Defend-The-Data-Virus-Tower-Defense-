extends SceneTree

const ADMIN_SANDBOX := preload("res://Scenes/Gameplay/Admin_Sandbox.tscn")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := ADMIN_SANDBOX.instantiate()
	root.add_child(game)
	await process_frame

	game.call("set_current_wave_for_demo", 0)
	game.call("_start_next_wave")

	if not _require(
		int(game.call("get_current_wave")) == 1,
		"The game did not start wave 1 through WaveManager."
	):
		return
	if not _require(
		int(game.get("_wave_spawns_remaining")) == 20
			and (game.get("_wave_spawn_schedule") as Array).size() == 20,
		"Wave 1 did not receive its 20 configured red-virus spawns."
	):
		return
	if not _require(
		is_zero_approx(
			float(
				(game.get("_wave_spawn_schedule") as Array).front().get(
					"spawn_time_seconds",
					-1.0
				)
			)
		)
			and is_equal_approx(
				float(
					(game.get("_wave_spawn_schedule") as Array).back().get(
						"spawn_time_seconds",
						-1.0
					)
				),
				15.0
			)
			and is_equal_approx(
				float(game.get("_wave_minimum_spawn_time_remaining")),
				15.0
			),
		"Wave 1 did not receive its marker-aware 15-second spawn schedule."
	):
		return

	game.call("_update_wave_spawner", 0.0)
	if not _require(
		int(game.get("_wave_spawns_remaining")) == 19
			and (game.get("_active_viruses") as Array).size() == 1,
		"The gameplay spawner did not consume the first WaveManager queue entry."
	):
		return

	print(
		"Wave manager integration passed: game.gd starts wave 1 with "
		+ "20 spawns distributed over 15 seconds."
	)
	game.queue_free()
	quit(0)


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	quit(1)
	return false
