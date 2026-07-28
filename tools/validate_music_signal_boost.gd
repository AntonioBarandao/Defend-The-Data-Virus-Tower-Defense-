extends SceneTree

const CYBER_GUARDIAN_SCENE := preload("res://Scenes/Towers/CyberGuardian.tscn")
const GAME_SCENE := preload("res://Scenes/Gameplay/Normal_Game.tscn")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var guardian := CYBER_GUARDIAN_SCENE.instantiate() as CyberGuardianTower
	root.add_child(guardian)
	await process_frame
	guardian.set("_placed", true)
	guardian.set_guardian_mode(CyberGuardianTower.MODE_SIGNAL_BOOST)
	guardian.call("_start_signal_boost_active")
	await process_frame

	var active_visual := guardian.get_node("Visuals/SignalBoostActive") as AnimatedSprite2D
	var idle_visual := guardian.get_node("Visuals/SignalBoostIdle") as AnimatedSprite2D
	_check(active_visual.visible, "Signal Boost active visual did not appear.")
	_check(active_visual.is_playing(), "Signal Boost active animation did not play.")
	_check(active_visual.sprite_frames.get_animation_loop(CyberGuardianTower.SHOOT_ANIMATION), "Signal Boost active animation is not looping.")

	guardian.update_attack(0.25, [])
	await process_frame
	_check(active_visual.visible and active_visual.is_playing(), "The no-target combat reset interrupted Signal Boost active.")

	guardian.call("_start_signal_boost_cooldown")
	await process_frame
	_check(idle_visual.visible and idle_visual.is_playing(), "Signal Boost did not return to idle after ending.")
	guardian.queue_free()
	await process_frame

	var game := GAME_SCENE.instantiate()
	var cutscene := game.get_node("TextCutsceneHUD") as TextCutsceneHUD
	cutscene.play_on_ready = false
	root.add_child(game)
	await process_frame
	var music := game.get_node("Music/CyberBusiness") as AudioStreamPlayer
	for _frame in range(10):
		if music.playing:
			break
		await process_frame
	_check(music.playing, "Cyber Business soundtrack did not start when gameplay entered the tree.")
	print("Cyber Business stream: %s, loop mode: %s" % [music.stream.get_class(), music.stream.loop_mode if music.stream is AudioStreamWAV else "n/a"])
	_check(music.stream is AudioStreamWAV and (music.stream as AudioStreamWAV).loop_mode != AudioStreamWAV.LOOP_DISABLED, "Cyber Business soundtrack is not configured to loop.")
	game.queue_free()
	await process_frame

	if _failures.is_empty():
		print("Gameplay music and Signal Boost validation passed.")
	quit(0 if _failures.is_empty() else 1)


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	_failures.append(message)
	push_error(message)
