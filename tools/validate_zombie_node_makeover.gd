extends SceneTree

const WaveManagerScript := preload("res://Scripts/Gameplay/wave_manager.gd")


func _initialize() -> void:
	var scene := load("res://Scenes/Gameplay/Normal_Game.tscn") as PackedScene
	if not _require(scene != null, "Normal Game could not be loaded."):
		return
	var game := scene.instantiate()
	root.add_child(game)
	await process_frame
	await physics_frame

	var zombie := game.get_node_or_null("ZombieNode") as ZombieNode
	var director := game.get_node_or_null("CutsceneDemoDirector") as CutsceneDemoDirector
	var camera := game.get_node_or_null("CutsceneCamera") as Camera2D
	var cutscene := game.get_node_or_null("TextCutsceneHUD") as TextCutsceneHUD
	var wave_manager := WaveManagerScript.new()
	if not _require(zombie != null and director != null and camera != null and cutscene != null, "Zombie Node cutscene nodes are incomplete."):
		return
	if cutscene.is_cutscene_running():
		cutscene.skip_cutscene()
		await process_frame
	if not _require(zombie.global_position.distance_to(Vector2(954.00006, 454.0)) < 0.1, "The Zombie Node moved from its authored boss position."):
		return

	var entrance := zombie.get_node_or_null("EntranceAnimation") as AnimatedSprite2D
	var level_1 := zombie.get_node_or_null(
		"LV1IdleAnimation"
	) as AnimatedSprite2D
	var level_2 := zombie.get_node_or_null(
		"LV2IdleAnimation"
	) as AnimatedSprite2D
	var level_3 := zombie.get_node_or_null(
		"LV3IdleAnimation"
	) as AnimatedSprite2D
	var middle_evolution := zombie.get_node_or_null(
		"LV1ToLV2EvolveAnimation"
	) as AnimatedSprite2D
	var final_evolution := zombie.get_node_or_null(
		"LV2ToLV3EvolveAnimation"
	) as AnimatedSprite2D
	if not _require(
		entrance != null
			and level_1 != null
			and level_2 != null
			and level_3 != null
			and middle_evolution != null
			and final_evolution != null,
		"Zombie Node visual layers are missing."
	):
		return
	if not _require(entrance.sprite_frames != null and entrance.sprite_frames.get_frame_count(&"entrance") == 121, "Zombie Node entrance does not contain 121 frames."):
		return
	if not _require(
		director.zombie_node_first_visible_wave == 11
			and wave_manager.get_progressive_boss_name(11)
				== WaveManagerScript.ZOMBIE_NODE
			and wave_manager.get_progressive_boss_level(11) == 1
			and wave_manager.get_progressive_boss_level(13) == 4
			and wave_manager.get_progressive_boss_level(15) == 5
			and wave_manager.get_progressive_boss_name(21)
				!= WaveManagerScript.ZOMBIE_NODE,
		"Zombie Node progressive boss levels are incorrect."
	):
		return

	director._update_zombie_node_for_wave(10)
	if not _require(not zombie.active and not zombie.visible, "Zombie Node is visible before wave 11."):
		return
	if not _require(director.should_play_zombie_entrance(11), "Wave 11 entrance is not available."):
		return

	director._update_zombie_node_for_wave(11)
	var stationary_position := zombie.global_position
	for _frame in range(30):
		await process_frame
	if not _require(zombie.global_position.is_equal_approx(stationary_position), "The Zombie Node still has subtle scatter movement."):
		return
	director._update_zombie_node_for_wave(10)

	if not _require(
		"progressive virus" in cutscene.wave11_phase_two_lines[0].to_lower()
			and "evolves" in cutscene.wave11_phase_two_lines[0].to_lower(),
		"Wave 11 dialogue does not explain the Zombie Node's progressive evolution."
	):
		return

	cutscene.camera_pan_duration = 0.01
	cutscene.camera_return_duration = 0.01
	cutscene.wave11_reveal_hold_duration = 0.0
	cutscene.entry_duration = 0.01
	cutscene.exit_duration = 0.01
	entrance.speed_scale = 100.0
	var wave11_phases: Array[StringName] = []
	cutscene.phase_started.connect(func(act_number: int, phase_name: StringName) -> void:
		if act_number == TextCutsceneHUD.ACT_WAVE_ELEVEN:
			wave11_phases.append(phase_name)
	)
	game.call("set_current_wave_for_demo", 10)
	var camera_start_position := camera.global_position
	var camera_start_zoom := camera.zoom
	game.call("_start_next_wave")
	var continue_button := cutscene.get_node("Root/DialoguePanel/Margin/Content/Footer/ContinueButton") as Button
	for _frame in range(360):
		await process_frame
		if cutscene.current_act == TextCutsceneHUD.ACT_WAVE_ELEVEN \
				and cutscene.current_phase == TextCutsceneHUD.PHASE_TWO:
			if bool(cutscene.get("_typing")) or continue_button.visible:
				cutscene.call("_advance_dialogue")
		if not director.is_cutscene_running() and int(game.call("get_current_wave")) == 11:
			break
	if not _require(int(game.call("get_current_wave")) == 11, "The wave 11 cutscene did not resume wave startup."):
		return
	if not _require(
		wave11_phases == [
			TextCutsceneHUD.PHASE_ONE,
			TextCutsceneHUD.PHASE_TWO,
			TextCutsceneHUD.PHASE_END,
		],
		"Wave 11 did not run the expected entrance, dialogue, and end phases."
	):
		return
	if not _require(zombie.active and zombie.get_level() == 1 and level_1.visible and not entrance.visible, "Wave 11 did not finish on the LV1 boss sprite."):
		return
	if not _require(zombie.global_position.is_equal_approx(stationary_position), "The Zombie Node moved during its cutscene."):
		return
	if not _require(camera.global_position.is_equal_approx(camera_start_position) and camera.zoom.is_equal_approx(camera_start_zoom), "Cutscene camera did not return to its authored transform."):
		return

	game.call("set_current_wave_for_demo", 12)
	await process_frame
	middle_evolution.speed_scale = 100.0
	var middle_evolution_started := [false]
	var middle_evolution_finished := [false]
	var middle_evolution_sound_started := [false]
	var evolution_sfx := game.get_node_or_null(
		"Sounds/ZombieNodeEvolutionSfx"
	) as AudioStreamPlayer
	zombie.evolution_animation_started.connect(
		func(from_level: int, to_level: int) -> void:
			if from_level == 1 and to_level == 2:
				middle_evolution_started[0] = true
				middle_evolution_sound_started[0] = (
					evolution_sfx != null and evolution_sfx.playing
				)
	)
	zombie.evolution_animation_finished.connect(
		func(to_level: int) -> void:
			if to_level == 2:
				middle_evolution_finished[0] = true
	)
	game.call("_start_next_wave")
	for _frame in range(360):
		await process_frame
		if int(game.call("get_current_wave")) == 13 \
				and not director.is_cutscene_running():
			break
	if not _require(
		int(game.call("get_current_wave")) == 13
			and zombie.get_level() == 4
			and middle_evolution_started[0]
			and middle_evolution_finished[0]
			and middle_evolution_sound_started[0]
			and level_2.visible
			and not level_1.visible
			and level_2.animation == &"idle_lv2"
			and middle_evolution.sprite_frames.get_frame_count(
				&"evolve_lv1_to_lv2"
			) == 73
			and not middle_evolution.sprite_frames.get_animation_loop(
				&"evolve_lv1_to_lv2"
			)
			and not middle_evolution.visible,
		"Wave 13 did not play LV1-to-LV2 evolution before its middle form."
	):
		return
	if not _require(
		final_evolution.sprite_frames.get_frame_count(
			&"evolve_lv2_to_lv3"
		) == 73
			and not final_evolution.sprite_frames.get_animation_loop(
				&"evolve_lv2_to_lv3"
			),
		"The LV2-to-LV3 evolution track is not authored correctly."
	):
		return

	game.free()
	print("Zombie Node validation passed: stationary boss, phased wave 11 entrance/dialogue, camera restore, and wave evolution.")
	quit(0)


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	quit(1)
	return false
