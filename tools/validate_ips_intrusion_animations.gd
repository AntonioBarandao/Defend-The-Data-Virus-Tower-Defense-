extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_root := Node2D.new()
	game_root.name = "IPSAnimationValidation"
	root.add_child(game_root)
	current_scene = game_root

	var virus_elements := Node2D.new()
	virus_elements.name = "VirusElements"
	game_root.add_child(virus_elements)
	var virus_path := Path2D.new()
	virus_path.name = "Path2D"
	var curve := Curve2D.new()
	curve.add_point(Vector2(0, 100))
	curve.add_point(Vector2(600, 100))
	virus_path.curve = curve
	virus_elements.add_child(virus_path)

	var tower_scene := load("res://Scenes/Towers/IPS_Intrusion.tscn") as PackedScene
	_check(tower_scene != null, "IPS Intrusion scene loads")
	if tower_scene == null:
		_finish()
		return

	var tower := tower_scene.instantiate() as IPSIntrusionTower
	game_root.add_child(tower)
	tower.global_position = Vector2(220, 220)
	tower.set("_home_position", tower.global_position)
	tower.set("_placed", true)
	await process_frame

	_check(tower.sprite_frames.has_animation(&"IPS_Intrusion_Factory_LV1"), "factory production track is available")
	_check(tower.sprite_frames.get_frame_count(&"IPS_Intrusion_Factory_LV1") >= 1, "factory production visual is available")
	_validate_level_balance(tower)
	tower.max_spikes = 1
	var no_viruses: Array[PathFollow2D] = []
	tower.update_spike_factory(0.0, no_viruses)
	_check(tower.animation == &"IPS_Intrusion_Factory_LV1" and tower.is_playing(), "factory animation plays while producing below capacity")

	tower.update_spike_factory(tower.get_shot_cooldown(), no_viruses)
	await process_frame
	var spikes := get_nodes_in_group("IPS_SPIKE")
	_check(spikes.size() == 1, "factory spawns one spike at its configured limit")
	if not spikes.is_empty():
		var spike := spikes[0] as IPSIntrusionSpike
		var spike_visual := spike.get_node_or_null(^"Sprite2D") as Sprite2D
		_check(spike_visual != null, "spawned spike uses the dedicated spike visual")
		_check(spike_visual != null and spike_visual.texture != null, "spawned spike texture is available")

	tower.update_spike_factory(0.0, no_viruses)
	_check(tower.animation == &"idle", "factory returns to idle at the spike limit")

	game_root.queue_free()
	await process_frame
	_finish()


func _validate_level_balance(tower: IPSIntrusionTower) -> void:
	var expected_limits := [5, 7, 9, 11, 13]
	var expected_ranges := [360.0, 432.0, 504.0, 576.0, 648.0]
	var expected_speed_multipliers := [1.0, 1.15, 1.30, 1.45, 1.60]
	for level_index in range(5):
		tower.level = level_index + 1
		_check(tower.get_max_spikes() == expected_limits[level_index], "IPS LV%d supports %d spikes" % [level_index + 1, expected_limits[level_index]])
		_check(is_equal_approx(tower.get_attack_range(), expected_ranges[level_index]), "IPS LV%d range is %.0f px" % [level_index + 1, expected_ranges[level_index]])
		var expected_cooldown := tower.spike_production_seconds / float(expected_speed_multipliers[level_index])
		_check(is_equal_approx(tower.get_shot_cooldown(), expected_cooldown), "IPS LV%d production speed is %.0f%%" % [level_index + 1, float(expected_speed_multipliers[level_index]) * 100.0])
	tower.level = 1


func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
	else:
		_failures.append(message)
		push_error("FAIL: %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("IPS Intrusion animation validation passed.")
		quit(0)
	else:
		quit(1)
