extends SceneTree

const GAME_CONTROLS_HUD := preload("res://Scenes/UI/GameControlsHud.tscn")
const TEXT_CUTSCENE_HUD := preload("res://Scenes/UI/TextCutsceneHUD.tscn")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var host := Node.new()
	root.add_child(host)

	var controls := GAME_CONTROLS_HUD.instantiate() as GameControlsHUD
	controls.name = "GameControlsHUD"
	host.add_child(controls)

	var cutscene := TEXT_CUTSCENE_HUD.instantiate() as TextCutsceneHUD
	cutscene.name = "TextCutsceneHUD"
	cutscene.play_on_ready = false
	host.add_child(cutscene)
	await process_frame

	var lives_panel := controls.get_node("Root/LivesPanel") as PanelContainer
	_check(lives_panel.visible, "Lives should be visible outside a cutscene.")
	cutscene.act_started.emit(1)
	_check(not lives_panel.visible, "Starting a cutscene should hide the lives panel.")
	cutscene.cutscene_finished.emit()
	_check(lives_panel.visible, "Finishing or skipping a cutscene should restore the lives panel.")

	host.queue_free()
	await process_frame
	if not _failed:
		print("Cutscene lives visibility validation passed.")
	quit(1 if _failed else 0)


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)
