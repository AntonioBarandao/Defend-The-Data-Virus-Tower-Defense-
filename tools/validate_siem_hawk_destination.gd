extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var hawk_scene := load("res://Scenes/Towers/SIEM_Hawk.tscn") as PackedScene
	_check(hawk_scene != null, "SIEM Hawk scene loads")
	if hawk_scene == null:
		_finish()
		return

	var hawk := hawk_scene.instantiate() as SIEMHawkTower
	root.add_child(hawk)
	await process_frame
	hawk.global_position = Vector2(960, 540)
	hawk.set("_station_position", hawk.global_position)
	hawk.set("_placed", true)
	_validate_level_balance(hawk)
	hawk.set_dispatched(true)
	var no_viruses: Array[PathFollow2D] = []

	var marker := hawk.get_node_or_null(^"DestinationMarker") as Node2D
	_check(marker != null, "destination marker is authored in the Hawk scene")
	_check(hawk.z_index >= 180, "SIEM Hawk renders above standard tower sprites")
	var turn_start_position := hawk.global_position
	var turn_start_rotation := hawk.global_rotation
	_check(hawk.set_dispatch_destination(Vector2(1200, 540)), "dispatched Hawk accepts a map destination")
	_check(hawk.has_dispatch_destination(), "destination remains active while the Hawk is traveling")
	_check(marker != null and marker.visible, "destination marker is visible while traveling")
	_check(hawk.is_turning_to_destination(), "destination begins a smooth turn phase")
	_check(is_equal_approx(hawk.global_rotation, turn_start_rotation), "destination selection does not snap rotation")
	hawk.update_knowledge_scan(1.0, Vector2.ZERO, no_viruses)
	_check(hawk.global_position.is_equal_approx(turn_start_position), "Hawk waits for the turn before moving")
	await create_timer(0.25).timeout
	_check(not is_equal_approx(hawk.global_rotation, turn_start_rotation), "Hawk rotates progressively during the turn")
	await create_timer(0.35).timeout
	_check(not hawk.is_turning_to_destination(), "destination turn completes in 0.5 seconds")

	var first_destination := hawk.get_dispatch_destination()
	_check(hawk.set_dispatch_destination(Vector2(900, 360)), "a second map press retargets the Hawk")
	_check(not hawk.get_dispatch_destination().is_equal_approx(first_destination), "new destination replaces the previous destination")
	_check(hawk.is_turning_to_destination(), "retargeting restarts the smooth turn")
	await create_timer(0.55).timeout

	hawk.update_knowledge_scan(20.0, Vector2.ZERO, no_viruses)
	_check(not hawk.has_dispatch_destination(), "destination clears when the Hawk arrives")
	_check(marker != null and not marker.visible, "destination marker disappears on arrival")

	hawk.set_dispatch_destination(Vector2(-10000, -10000))
	var clamped_screen := hawk.get_canvas_transform() * hawk.get_dispatch_destination()
	var hawk_radius := float(hawk.call("_get_hawk_screen_radius")) + hawk.viewport_border_padding
	var viewport_rect := hawk.get_viewport().get_visible_rect()
	_check(clamped_screen.x >= viewport_rect.position.x + hawk_radius - 0.5, "destination respects the left screen border")
	_check(clamped_screen.y >= viewport_rect.position.y + hawk_radius - 0.5, "destination respects the top screen border")
	hawk.set_dispatch_destination(Vector2(10000, 10000))
	clamped_screen = hawk.get_canvas_transform() * hawk.get_dispatch_destination()
	_check(clamped_screen.x <= viewport_rect.end.x - hawk_radius + 0.5, "destination respects the right screen border")
	_check(clamped_screen.y <= viewport_rect.end.y - hawk_radius + 0.5, "destination respects the bottom screen border")
	hawk.set_dispatched(false)
	_check(not hawk.has_dispatch_destination(), "freezing clears the active destination")
	_check(not hawk.set_dispatch_destination(Vector2(960, 540)), "frozen Hawk ignores map destinations")

	var overlay_scene := load("res://Scenes/UI/UtilityOverlayHUD.tscn") as PackedScene
	var overlay := overlay_scene.instantiate() as UtilityOverlayHUD
	root.add_child(overlay)
	await process_frame
	overlay.set_siem_hawk_action_state(Vector2(900, 500), true, true, true, false, true)
	var action_panel := overlay.get_node_or_null(^"Root/SIEMHawkActionPanel") as PanelContainer
	_check(action_panel != null and action_panel.visible, "Hawk hover action panel is visible and interactive")
	_check(action_panel != null and action_panel.mouse_filter == Control.MOUSE_FILTER_STOP, "Hawk hover action panel owns pointer input")

	hawk.queue_free()
	overlay.queue_free()
	await process_frame
	_finish()


func _validate_level_balance(hawk: SIEMHawkTower) -> void:
	var expected_speed_multipliers := [1.0, 1.35, 1.70, 2.10, 2.50]
	var expected_extraction_multipliers := [1.0, 2.0, 3.0, 4.0, 5.0]
	hawk.set_signal_boost_active(false)
	for level_index in range(expected_speed_multipliers.size()):
		hawk.level = level_index + 1
		var expected_speed := hawk.dispatch_speed * float(expected_speed_multipliers[level_index])
		_check(
			is_equal_approx(hawk.get_dispatch_speed(), expected_speed),
			"SIEM Hawk LV%d dispatch speed is %.0f%% of LV1" % [level_index + 1, float(expected_speed_multipliers[level_index]) * 100.0]
		)
		_check(
			is_equal_approx(hawk.get_knowledge_extraction_multiplier(), float(expected_extraction_multipliers[level_index])),
			"SIEM Hawk LV%d extracts knowledge at %.0fx speed" % [level_index + 1, float(expected_extraction_multipliers[level_index])]
		)
	hawk.level = 5
	hawk.set("_banked_knowledge_points", 2)
	hawk.set("_extraction_elapsed", 0.0)
	hawk.call("_extract_banked_knowledge", 0.59)
	_check(hawk.get_banked_knowledge_points() == 2, "LV5 extraction waits for its 0.6 second interval")
	hawk.call("_extract_banked_knowledge", 0.01)
	_check(hawk.get_banked_knowledge_points() == 1, "LV5 extracts one point every 0.6 seconds")
	hawk.set("_banked_knowledge_points", 0)
	hawk.set("_extraction_elapsed", 0.0)
	hawk.level = 1


func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
	else:
		_failures.append(message)
		push_error("FAIL: %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("SIEM Hawk destination validation passed.")
		quit(0)
	else:
		quit(1)
