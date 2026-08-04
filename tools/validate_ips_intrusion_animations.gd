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

	var factory_visual_paths := [
		^"FactoryVisual",
		^"LV2FactoryVisual",
		^"LV3FactoryVisual",
		^"LV4FactoryVisual",
		^"LV5FactoryVisual",
	]
	var factory_visuals: Array[AnimatedSprite2D] = []
	for visual_path in factory_visual_paths:
		factory_visuals.append(
			tower.get_node_or_null(visual_path) as AnimatedSprite2D
		)
	var factory_visual := factory_visuals[0]
	_check(factory_visual != null, "factory visual is an editable AnimatedSprite2D child")
	_check(
		factory_visual != null
			and factory_visual.sprite_frames.has_animation(
				&"IPS_Intrusion_Factory_LV1"
			),
		"factory production track is available"
	)
	_check(
		factory_visual != null
			and factory_visual.sprite_frames.get_frame_count(
				&"IPS_Intrusion_Factory_LV1"
			) == 73
			and is_equal_approx(
				factory_visual.sprite_frames.get_animation_speed(
					&"IPS_Intrusion_Factory_LV1"
				),
				12.0
			),
		"factory production track uses the optimized 73-frame 12 FPS loop"
	)
	_validate_upgrade_switch_speed(tower, factory_visuals)
	_validate_level_balance(tower)
	tower.max_spikes = 1
	var no_viruses: Array[PathFollow2D] = []
	tower.update_spike_factory(0.0, no_viruses)
	_check(
		factory_visual.animation == &"IPS_Intrusion_Factory_LV1"
			and factory_visual.is_playing(),
		"factory animation plays while producing below capacity"
	)

	tower.update_spike_factory(tower.get_shot_cooldown(), no_viruses)
	await process_frame
	var spikes := get_nodes_in_group("IPS_SPIKE")
	_check(spikes.size() == 1, "factory spawns one spike at its configured limit")
	if not spikes.is_empty():
		var spike := spikes[0] as IPSIntrusionSpike
		var spike_visual := spike.get_node_or_null(^"AnimatedSprite2D") as AnimatedSprite2D
		_check(spike_visual != null, "spawned spike uses AnimatedSprite2D")
		_check(spike_visual != null and spike_visual.sprite_frames.get_frame_count(&"Animated_Spikes") == 73, "spike animation uses the optimized 73-frame loop")
		_check(spike_visual != null and spike_visual.animation == &"Animated_Spikes" and spike_visual.is_playing(), "spawned spike animation is playing")

	tower.update_spike_factory(0.0, no_viruses)
	_check(
		factory_visual.animation == &"IPS_Intrusion_Factory_LV1"
			and factory_visual.is_playing(),
		"factory level animation keeps playing at the spike limit"
	)

	game_root.queue_free()
	await process_frame
	_finish()


func _validate_level_balance(tower: IPSIntrusionTower) -> void:
	var expected_limits := [5, 7, 9, 11, 13]
	var expected_ranges := [360.0, 432.0, 504.0, 576.0, 648.0]
	var expected_speed_multipliers := [1.0, 1.45, 1.60, 1.85, 2.60]
	var expected_durability := [1, 2, 3, 4, 5]
	for level_index in range(5):
		tower.level = level_index + 1
		_check(tower.get_max_spikes() == expected_limits[level_index], "IPS LV%d supports %d spikes" % [level_index + 1, expected_limits[level_index]])
		_check(is_equal_approx(tower.get_attack_range(), expected_ranges[level_index]), "IPS LV%d range is %.0f px" % [level_index + 1, expected_ranges[level_index]])
		var expected_cooldown := tower.spike_production_seconds / float(expected_speed_multipliers[level_index])
		_check(is_equal_approx(tower.get_shot_cooldown(), expected_cooldown), "IPS LV%d production speed is %.0f%%" % [level_index + 1, float(expected_speed_multipliers[level_index]) * 100.0])
		_check(
			tower.get_spike_durability() == expected_durability[level_index],
			"IPS LV%d spikes have %d durability"
			% [level_index + 1, expected_durability[level_index]]
		)
	tower.level = 1


func _validate_upgrade_switch_speed(
	tower: IPSIntrusionTower,
	factory_visuals: Array[AnimatedSprite2D]
) -> void:
	var started_usec := Time.get_ticks_usec()
	for tower_level in range(2, 6):
		tower.level = tower_level
		tower.call("_sync_factory_level_animation")
		var active_visual := factory_visuals[tower_level - 1]
		_check(
			tower.get_active_factory_visual() == active_visual
				and active_visual.visible
				and active_visual.animation
					== StringName(
						"IPS_Intrusion_Factory_LV%d" % tower_level
					),
			"IPS LV%d switches to its authored factory sibling."
				% tower_level
		)
	var elapsed_msec := float(Time.get_ticks_usec() - started_usec) / 1000.0
	_check(
		elapsed_msec < 100.0,
		"all IPS upgrade visuals switch without synchronous loading (%.2f ms)"
		% elapsed_msec
	)
	_check(
		factory_visuals[4].animation == &"IPS_Intrusion_Factory_LV5"
			and factory_visuals[4].visible,
		"IPS upgrade visual reaches level 5"
	)
	tower.level = 1
	tower.call("_sync_factory_level_animation")


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
