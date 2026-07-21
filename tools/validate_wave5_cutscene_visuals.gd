extends SceneTree

const CUTSCENE_GAME := preload("res://Scenes/Gameplay/Cutscene_Test_Game.tscn")
const MAX_WAIT_FRAMES := 900

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := CUTSCENE_GAME.instantiate()
	var cutscene := game.get_node("TextCutsceneHUD") as TextCutsceneHUD
	cutscene.play_on_ready = false
	cutscene.camera_pan_duration = 0.01
	cutscene.wave5_trojan_hold_duration = 0.01
	cutscene.entry_duration = 0.01
	cutscene.exit_duration = 0.01
	cutscene.camera_return_duration = 0.01
	cutscene.characters_per_second = 100000.0
	root.add_child(game)
	await process_frame

	var cutscene_visuals := game.get_node("Otherground_Cutscene") as CanvasItem
	var trojan_preview := game.get_node("Otherground_Cutscene/CutsceneBack/Wave5CutsceneTrojanHorse") as CanvasItem
	cutscene.start_wave5_cutscene()

	_check(await _wait_for_phase(cutscene, &"phase_2"), "Wave 5 did not reach its first dialogue phase.")
	_check(cutscene_visuals.visible, "Wave 5 visuals disappeared before the first dialogue phase.")
	_check(trojan_preview.visible, "Trojan preview disappeared before the first dialogue phase.")
	_check(await _wait_for_continue(cutscene), "Wave 5 phase 2 dialogue did not become ready.")
	cutscene.call("_advance_dialogue")

	_check(await _wait_for_phase(cutscene, &"phase_4"), "Wave 5 did not reach its final dialogue phase.")
	_check(cutscene_visuals.visible, "Wave 5 visuals disappeared after the cloak transformation.")
	_check(trojan_preview.visible, "Trojan preview disappeared after the cloak transformation.")
	_check(await _wait_for_continue(cutscene), "Wave 5 phase 4 dialogue did not become ready.")
	cutscene.call("_advance_dialogue")

	_check(await _wait_for_cutscene_end(cutscene), "Wave 5 cutscene did not finish.")
	_check(not cutscene_visuals.visible, "Wave 5 visuals remained visible after the cutscene ended.")
	_check(not trojan_preview.visible, "Trojan preview remained visible after the cutscene ended.")

	game.queue_free()
	await process_frame
	if not _failed:
		print("Wave 5 cutscene visual retention validation passed.")
	quit(1 if _failed else 0)


func _wait_for_phase(cutscene: TextCutsceneHUD, phase: StringName) -> bool:
	for _frame in MAX_WAIT_FRAMES:
		if cutscene.current_phase == phase:
			return true
		await process_frame
	return false


func _wait_for_continue(cutscene: TextCutsceneHUD) -> bool:
	var continue_button := cutscene.get_node("Root/DialoguePanel/Margin/Content/Footer/ContinueButton") as Button
	for _frame in MAX_WAIT_FRAMES:
		if continue_button.visible:
			return true
		await process_frame
	return false


func _wait_for_cutscene_end(cutscene: TextCutsceneHUD) -> bool:
	for _frame in MAX_WAIT_FRAMES:
		if not cutscene.is_cutscene_running():
			return true
		await process_frame
	return false


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)
