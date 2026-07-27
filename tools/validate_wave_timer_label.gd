extends SceneTree

const NORMAL_GAME := preload("res://Scenes/Gameplay/Normal_Game.tscn")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := NORMAL_GAME.instantiate()
	root.add_child(game)
	await process_frame

	var cutscene := game.get_node_or_null("TextCutsceneHUD") as TextCutsceneHUD
	if cutscene != null and cutscene.is_cutscene_running():
		cutscene.skip_cutscene()
		await process_frame

	var timer_label := game.get_node_or_null("WaveTimerLabel") as Label
	if not _require(
		timer_label != null and timer_label.text == "00:00",
		"The authored Normal Game wave timer is missing or has the wrong idle text."
	):
		return

	game.call("set_current_wave_for_demo", 0)
	game.call("_start_next_wave")
	if not _require(
		timer_label.text == "00:15",
		"Wave 1 did not begin at 00:15."
	):
		return

	game.call("_update_wave_spawner", 1.0)
	if not _require(
		timer_label.text == "00:14",
		"Wave 1 did not count down to 00:14 after one second."
	):
		return

	game.call("_update_wave_spawner", 13.0)
	if not _require(
		timer_label.text == "00:01",
		"Wave 1 did not retain its final displayed second."
	):
		return

	game.call("_update_wave_spawner", 1.0)
	if not _require(
		timer_label.text == "00:00",
		"Wave 1 did not finish its timed phase at 00:00."
	):
		return

	if not _require(
		String(game.call("_format_wave_time", 60.0)) == "01:00"
			and String(game.call("_format_wave_time", 120.0)) == "02:00"
			and String(game.call("_format_wave_time", 180.0)) == "03:00",
		"The MM:SS formatter does not handle later wave durations."
	):
		return

	print(
		"Wave timer validation passed: the authored label counts wave 1 "
		+ "from 00:15 to 00:00 using MM:SS only."
	)
	game.queue_free()
	quit(0)


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	quit(1)
	return false
