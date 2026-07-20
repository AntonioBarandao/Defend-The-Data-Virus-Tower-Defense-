extends SceneTree

const GAME_CONTROLS_HUD := preload("res://Scenes/UI/GameControlsHud.tscn")
const TOLERANCE := 0.001

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var hud := GAME_CONTROLS_HUD.instantiate() as GameControlsHUD
	root.add_child(hud)
	await process_frame

	var speed_button := hud.get_node("Root/BottomRightControls/SpeedButton") as Button
	var lives_panel := hud.get_node("Root/LivesPanel") as PanelContainer
	_check(speed_button.toggle_mode, "The speed control should be an authored toggle button.")
	_check(not speed_button.button_pressed, "The speed control should start at normal speed.")
	_check(lives_panel.position.distance_to(Vector2(1297.0, 104.0)) <= TOLERANCE, "Lives should be authored beneath the wave counter.")
	hud.set_lives_visible(false)
	_check(not lives_panel.visible, "The lives panel should be hideable during a cutscene.")
	hud.set_lives_visible(true)
	_check(lives_panel.visible, "The lives panel should return after a cutscene.")

	hud.set_speed_enabled(true)
	_check(is_equal_approx(Engine.time_scale, 2.0), "Enabling the speed control should set 2x gameplay speed.")
	_check(speed_button.button_pressed, "The speed button should remain highlighted while 2x is active.")

	hud.set_speed_enabled(false)
	_check(is_equal_approx(Engine.time_scale, 1.0), "Disabling the speed control should restore normal speed.")
	_check(not speed_button.button_pressed, "The speed button highlight should clear at normal speed.")

	hud.set_speed_enabled(true)
	hud.queue_free()
	await process_frame
	_check(is_equal_approx(Engine.time_scale, 1.0), "Leaving gameplay should not leak 2x speed into another scene.")

	if not _failed:
		print("Game speed HUD validation passed.")
	quit(1 if _failed else 0)


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)
