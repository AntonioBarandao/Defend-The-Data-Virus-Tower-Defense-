extends SceneTree

const NORMAL_GAME := preload("res://Scenes/Gameplay/Normal_Game.tscn")
const STORE_SLIDE_DISTANCE := 360.0
const TOLERANCE := 0.01

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := NORMAL_GAME.instantiate()
	var cutscene := game.get_node("TextCutsceneHUD") as TextCutsceneHUD
	cutscene.play_on_ready = false
	root.add_child(game)
	await process_frame

	var wave_label := game.get_node("GameControlsHUD/Root/WavesLabel") as Label
	var wave_timer := game.get_node("GameControlsHUD/Root/WaveTimerLabel") as Label
	var controls := game.get_node("GameControlsHUD") as GameControlsHUD
	var lives_panel := controls.get_node("Root/LivesPanel") as PanelContainer
	var wave_rest := wave_label.global_position
	var wave_timer_rest := wave_timer.global_position
	var lives_rest := lives_panel.global_position
	_check(is_equal_approx(controls.lives_store_slide_multiplier, 1.0), "Normal Game does not inherit the full tower-store slide distance for lives.")

	game.call("_apply_store_companion_ui_slide", STORE_SLIDE_DISTANCE)
	_check(wave_label.global_position.distance_to(wave_rest + Vector2(STORE_SLIDE_DISTANCE, 0.0)) <= TOLERANCE, "Wave label did not move to the closed-store corner.")
	_check(wave_timer.global_position.distance_to(wave_timer_rest + Vector2(STORE_SLIDE_DISTANCE, 0.0)) <= TOLERANCE, "Wave timer did not move with the wave label.")
	_check(lives_panel.global_position.distance_to(lives_rest + Vector2(STORE_SLIDE_DISTANCE, 0.0)) <= TOLERANCE, "Lives card did not move with the wave label.")

	game.call("_apply_store_companion_ui_slide", 0.0)
	_check(wave_label.global_position.distance_to(wave_rest) <= TOLERANCE, "Wave label did not return to its authored position.")
	_check(wave_timer.global_position.distance_to(wave_timer_rest) <= TOLERANCE, "Wave timer did not return to its authored position.")
	_check(lives_panel.global_position.distance_to(lives_rest) <= TOLERANCE, "Lives card did not return to its authored position.")

	game.queue_free()
	await process_frame
	if not _failed:
		print("Lives and wave responsive HUD validation passed.")
	quit(1 if _failed else 0)


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)
