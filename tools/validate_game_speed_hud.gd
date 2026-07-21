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
	var lives_rest_position := lives_panel.global_position
	var lives_rest_scale := lives_panel.scale
	hud.apply_store_companion_slide(360.0)
	_check(lives_panel.global_position.distance_to(lives_rest_position + Vector2(360.0, 0.0)) <= TOLERANCE, "Lives should follow the tower-store slide offset.")
	hud.apply_store_companion_slide(0.0)
	_check(lives_panel.global_position.distance_to(lives_rest_position) <= TOLERANCE, "Lives should return to its authored position with the tower store.")
	hud.set_lives_visible(false)
	_check(not lives_panel.visible, "The lives panel should be hideable during a cutscene.")
	hud.set_lives_visible(true, true)
	_check(lives_panel.visible, "The lives panel should return after a cutscene.")
	_check(lives_panel.scale.x > lives_rest_scale.x, "The lives panel should begin with a stamped reveal scale.")
	await create_timer(hud.lives_stamp_duration + 0.1).timeout
	_check(lives_panel.scale.distance_to(lives_rest_scale) <= TOLERANCE, "The lives stamp should settle at its authored scale.")

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
