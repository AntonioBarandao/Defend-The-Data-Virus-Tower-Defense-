extends SceneTree

const NORMAL_GAME := preload("res://Scenes/Gameplay/Normal_Game.tscn")
const ADMIN_SANDBOX := preload("res://Scenes/Gameplay/Admin_Sandbox.tscn")
const CYBER_GUARDIAN := preload("res://Scenes/Towers/CyberGuardian.tscn")
const EDR_HUNTER := preload("res://Scenes/Towers/EDR_Hunter.tscn")
const WaveManagerScript := preload("res://Scripts/Gameplay/wave_manager.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var wave_manager := WaveManagerScript.new()
	if not _require(
		wave_manager.get_progressive_boss_name(15)
			== WaveManagerScript.ZOMBIE_NODE
			and wave_manager.get_progressive_boss_name(20)
				== WaveManagerScript.WORM_BOSS
			and wave_manager.get_progressive_boss_level(20) == 1,
		"Wave 20 is not assigned exclusively to the Cyber Worm boss."
	):
		return

	var game := NORMAL_GAME.instantiate()
	root.add_child(game)
	await process_frame
	await physics_frame

	var worm := game.get_node_or_null("WormBoss") as WormBoss
	var cutscene := game.get_node_or_null(
		"TextCutsceneHUD"
	) as TextCutsceneHUD
	var director := game.get_node_or_null(
		"CutsceneDemoDirector"
	) as CutsceneDemoDirector
	var alternate_map := game.get_node_or_null(
		"Otherground_Cutscene"
	) as Control
	var alternate_map_virus := game.get_node_or_null(
		"Otherground_Cutscene/CutsceneBack/CutsceneVirus1"
	) as CanvasItem
	if not _require(
		worm != null
			and cutscene != null
			and director != null
			and alternate_map != null
			and alternate_map_virus != null,
		"Normal Game is missing the Cyber Worm cutscene nodes."
	):
		return
	if cutscene.is_cutscene_running():
		cutscene.skip_cutscene()
		await process_frame

	var head := worm.get_node_or_null("HeadAnimation") as AnimatedSprite2D
	var body_first := worm.get_node_or_null("Body_First") as Sprite2D
	var body_fifth := worm.get_node_or_null("Body_Fifth") as Sprite2D
	var tail := worm.get_node_or_null("Tail") as Sprite2D
	var destroy_visuals: Array[AnimatedSprite2D] = []
	for destroy_path in [
		"Head_Destroy",
		"Body_First_Destroy",
		"Body_Second_Destroy",
		"Body_Third_Destroy",
		"Body_Fourth_Destroy",
		"Body_Fifth_Destroy",
		"Tail_Destroy",
	]:
		var destroy_visual := worm.get_node_or_null(
			destroy_path
		) as AnimatedSprite2D
		if destroy_visual != null:
			destroy_visuals.append(destroy_visual)
	var health_hud := worm.get_node_or_null(
		"BossHealthHUD"
	) as WormBossProgressBar
	if not _require(
		head != null
			and body_first != null
			and body_fifth != null
			and tail != null
			and health_hud != null
			and destroy_visuals.size() == 7
			and body_first.position.is_equal_approx(Vector2(31, 0))
			and body_fifth.position.is_equal_approx(Vector2(-385, 0))
			and tail.position.is_equal_approx(Vector2(-507, 4))
			and alternate_map.get_global_rect().has_point(
				worm.get_authored_cutscene_position()
			)
			and alternate_map.z_index < worm.z_index,
		"The authored Worm Boss arrangement was not preserved."
	):
		return
	for index in range(destroy_visuals.size()):
		var animation_name: StringName = (
			&"head_destroy" if index == 0
			else &"tail_destroy" if index == 6
			else &"body_destroy"
		)
		if not _require(
			destroy_visuals[index].sprite_frames != null
				and destroy_visuals[index].sprite_frames.has_animation(
					animation_name
				)
				and not destroy_visuals[index].sprite_frames.get_animation_loop(
					animation_name
				),
			"Cyber Worm destroy visual %d is missing its non-looping track."
				% index
		):
			return
	if not _require(
		worm.max_health == 950
			and worm.current_health == 950
			and is_equal_approx(worm.path_speed, 25.0),
		"The Cyber Worm does not use 950 health and Trojan Horse speed."
	):
		return

	cutscene.wave20_focus_duration = 0.01
	cutscene.camera_return_duration = 0.01
	cutscene.entry_duration = 0.01
	cutscene.exit_duration = 0.01
	cutscene.characters_per_second = 10000.0
	worm.body_flash_duration = 0.01
	worm.shield_flash_duration = 0.01
	var phases: Array[StringName] = []
	var alternate_map_visible_during_focus := [false]
	var alternate_map_actors_hidden_during_focus := [false]
	cutscene.phase_started.connect(
		func(act_number: int, phase_name: StringName) -> void:
			if act_number == TextCutsceneHUD.ACT_WAVE_TWENTY:
				phases.append(phase_name)
				if phase_name == TextCutsceneHUD.PHASE_ONE:
					alternate_map_visible_during_focus[0] = (
						alternate_map.is_visible_in_tree()
					)
					alternate_map_actors_hidden_during_focus[0] = (
						not alternate_map_virus.is_visible_in_tree()
					)
	)

	game.call("set_current_wave_for_demo", 19)
	game.call("_start_next_wave")
	var continue_button := cutscene.get_node_or_null(
		"Root/DialoguePanel/Margin/Content/Footer/ContinueButton"
	) as Button
	for _frame in range(900):
		await process_frame
		if cutscene.current_act == TextCutsceneHUD.ACT_WAVE_TWENTY \
				and cutscene.current_phase == TextCutsceneHUD.PHASE_TWO:
			if bool(cutscene.get("_typing")) \
					or (continue_button != null and continue_button.visible):
				cutscene.call("_advance_dialogue")
		if not director.is_cutscene_running() \
				and int(game.call("get_current_wave")) == 20:
			break

	if not _require(
		int(game.call("get_current_wave")) == 20
			and bool(alternate_map_visible_during_focus[0])
			and bool(alternate_map_actors_hidden_during_focus[0])
			and not alternate_map.is_visible_in_tree()
			and phases == [
				TextCutsceneHUD.PHASE_ONE,
				TextCutsceneHUD.PHASE_TWO,
				TextCutsceneHUD.PHASE_END,
			],
		"The Wave 20 Worm introduction did not complete all cutscene phases."
	):
		return
	if not _require(
		worm.is_active()
			and worm.is_wave_active()
			and head.visible
			and not body_first.visible
			and not tail.visible
			and worm.get_attack_targets().size() == 1,
		"The tunnel entrance did not begin with only the Worm head exposed."
	):
		return

	worm.set_wave_active(false)
	var offsets: Array = worm.get("_part_offsets")
	if not _require(
		offsets.size() == 7
			and float(offsets[1]) > 90.0
			and float(offsets[6]) > float(offsets[5]),
		"The authored segment spacing did not produce a head-to-tail emergence order."
	):
		return
	worm.set_wave_active(true)
	worm.call("_process", (float(offsets[1]) + 1.0) / worm.path_speed)
	var emerged_targets := worm.get_attack_targets()
	if not _require(
		body_first.visible
			and not body_fifth.visible
			and emerged_targets.size() == 2,
		"The first body segment did not emerge after the head cleared the tunnel."
	):
		return

	var head_target := emerged_targets[0]
	var body_target := emerged_targets[1]
	var health_before_shield := worm.current_health
	if not _require(
		not bool(game.call("_damage_virus", head_target, 25, false))
			and worm.current_health == health_before_shield
			and (worm.get("_part_flash_tweens") as Dictionary).has(0),
		"The armored head did not deflect damage with a shield flash."
	):
		return
	if not _require(
		not bool(game.call("_damage_virus", body_target, 10, false))
			and worm.current_health == 940
			and (worm.get("_part_flash_tweens") as Dictionary).has(1),
		"A body hit did not reduce shared health and flash only that segment."
	):
		return

	var guardian := CYBER_GUARDIAN.instantiate() as CyberGuardianTower
	game.add_child(guardian)
	guardian.set("_placed", true)
	guardian.global_position = body_target.global_position + Vector2(8, 0)
	var normal_target := PathFollow2D.new()
	normal_target.name = "CloserNormalVirusTarget"
	game.add_child(normal_target)
	normal_target.global_position = guardian.global_position + Vector2(1, 0)
	var priority_targets: Array[PathFollow2D] = [
		normal_target,
		head_target,
		body_target,
	]
	if not _require(
		guardian.call(
			"_find_nearest_virus_in_range",
			priority_targets
		) == body_target,
		"A closer normal virus overrode the nearest in-range Worm segment."
	):
		return

	var edr := EDR_HUNTER.instantiate() as EDRHunterTower
	game.add_child(edr)
	edr.set("_placed", true)
	edr.level = 4
	await process_frame
	if not _require(
		edr.call(
			"_find_nearest_drone_target",
			priority_targets,
			0
		) == body_target,
		"An EDR drone did not bypass the shield and select a body segment."
	):
		return

	worm.call(
		"_process",
		(float(offsets[6]) - float(offsets[1]) + 1.0)
			/ worm.path_speed
	)
	var all_targets := worm.get_attack_targets()
	if not _require(
		all_targets.size() == 7
			and body_fifth.visible
			and tail.visible
			and worm.get_emerged_segment_count() == 7,
		"The five body segments and tail did not emerge in sequence."
	):
		return
	var tail_target := all_targets[6]
	if not _require(
		not bool(game.call("_damage_virus", tail_target, 25, false))
			and worm.current_health == 940
			and (worm.get("_part_flash_tweens") as Dictionary).has(6),
		"The armored tail did not deflect damage with a shield flash."
	):
		return

	var defeat_phases: Array[StringName] = []
	cutscene.phase_started.connect(
		func(act_number: int, phase_name: StringName) -> void:
			if act_number == TextCutsceneHUD.ACT_WORM_BOSS_DEFEAT:
				defeat_phases.append(phase_name)
	)
	worm.destroy_fade_duration = 0.01
	for destroy_visual in destroy_visuals:
		destroy_visual.speed_scale = 100.0
	if not _require(
		bool(game.call("_damage_virus", all_targets[3], 940, false))
			and worm.is_destroying()
			and worm.current_health == 0
			and worm.get_attack_targets().is_empty(),
		"Body damage did not deplete the shared 950-point boss health pool."
	):
		return
	await process_frame
	var visible_destroy_count := 0
	for destroy_visual in destroy_visuals:
		if destroy_visual.visible and destroy_visual.is_playing():
			visible_destroy_count += 1
	if not _require(
		visible_destroy_count == 7,
		"All seven Cyber Worm destroy tracks did not start together."
	):
		return

	for _frame in range(900):
		await process_frame
		if cutscene.current_act == TextCutsceneHUD.ACT_WORM_BOSS_DEFEAT \
				and cutscene.current_phase == TextCutsceneHUD.PHASE_TWO:
			if bool(cutscene.get("_typing")) \
					or (continue_button != null and continue_button.visible):
				cutscene.call("_advance_dialogue")
		if worm.is_defeated() and not director.is_cutscene_running():
			break
	if not _require(
		worm.is_defeated()
			and not worm.visible
			and defeat_phases == [
				TextCutsceneHUD.PHASE_TWO,
				TextCutsceneHUD.PHASE_END,
			],
		"The Cyber Worm did not fade, despawn, and complete its defeat dialogue."
	):
		return

	guardian.queue_free()
	edr.queue_free()
	normal_target.queue_free()
	game.queue_free()
	await process_frame

	var admin := ADMIN_SANDBOX.instantiate()
	root.add_child(admin)
	await process_frame
	if not _require(
		admin.get_node_or_null("WormBoss") is WormBoss
			and admin.get_node_or_null(
				"Otherground_Cutscene"
			) is Control
			and (
				admin.get_node_or_null(
					"TextCutsceneHUD"
				) as TextCutsceneHUD
			).wave20_alternate_map_path == ^"../Otherground_Cutscene",
		"Admin Sandbox did not inherit the Worm Boss alternate-map cutscene."
	):
		return
	admin.queue_free()

	print(
		"Cyber Worm validation passed: Wave 20 cutscene, tunnel emergence, "
		+ "segment priority, shared health, synchronized destroy tracks, fade, "
		+ "and Guardian defeat dialogue."
	)
	quit(0)


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	quit(1)
	return false
