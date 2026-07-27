extends SceneTree

const NORMAL_GAME := preload("res://Scenes/Gameplay/Normal_Game.tscn")
const CYBER_GUARDIAN := preload("res://Scenes/Towers/CyberGuardian.tscn")
const EDR_HUNTER := preload("res://Scenes/Towers/EDR_Hunter.tscn")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := NORMAL_GAME.instantiate()
	root.add_child(game)
	await process_frame

	var cutscene := game.get_node_or_null("TextCutsceneHUD") as TextCutsceneHUD
	var director := game.get_node_or_null(
		"CutsceneDemoDirector"
	) as CutsceneDemoDirector
	var zombie := game.get_node_or_null("ZombieNode") as ZombieNode
	var target := game.get_node_or_null(
		"ZombieNodeCombatTarget"
	) as PathFollow2D
	if not _require(
		cutscene != null
			and director != null
			and zombie != null
			and target != null,
		"Wave 15 Zombie Node runtime nodes are incomplete."
	):
		return

	if cutscene.is_cutscene_running():
		cutscene.skip_cutscene()
		await process_frame

	cutscene.wave15_focus_duration = 0.02
	cutscene.zombie_defeat_focus_duration = 0.02
	cutscene.camera_return_duration = 0.02
	cutscene.entry_duration = 0.02
	cutscene.exit_duration = 0.02
	cutscene.characters_per_second = 10000.0

	game.call("set_current_wave_for_demo", 14)
	await process_frame
	var final_evolution := zombie.get_node_or_null(
		"LV2ToLV3EvolveAnimation"
	) as AnimatedSprite2D
	if not _require(
		zombie.get_level() == 4
			and not zombie.is_combat_unlocked()
			and final_evolution != null,
		"The Zombie Node became damageable before its Wave 15 final form."
	):
		return

	final_evolution.speed_scale = 100.0
	var final_evolution_started := [false]
	var final_evolution_finished := [false]
	var final_evolution_sound_started := [false]
	var evolution_sfx := game.get_node_or_null(
		"Sounds/ZombieNodeEvolutionSfx"
	) as AudioStreamPlayer
	zombie.evolution_animation_started.connect(
		func(from_level: int, to_level: int) -> void:
			if from_level == 2 and to_level == 3:
				final_evolution_started[0] = true
				final_evolution_sound_started[0] = (
					evolution_sfx != null and evolution_sfx.playing
				)
	)
	zombie.evolution_animation_finished.connect(
		func(to_level: int) -> void:
			if to_level == 3:
				final_evolution_finished[0] = true
	)
	game.call("_start_next_wave")
	if not await _advance_cutscene_until(
		game,
		cutscene,
		director,
		15
	):
		return

	var level_2_sprite := zombie.get_node_or_null(
		"LV2IdleAnimation"
	) as AnimatedSprite2D
	var level_3_sprite := zombie.get_node_or_null(
		"LV3IdleAnimation"
	) as AnimatedSprite2D
	var destroy_sprite := zombie.get_node_or_null(
		"LV3DestroyAnimation"
	) as AnimatedSprite2D
	var health_bar := zombie.get_node_or_null(
		"MinibossHealthBar"
	) as Node2D
	if not _require(
		zombie.max_health == 500
			and zombie.current_health == 500
			and zombie.get_level() == 5
			and final_evolution_started[0]
			and final_evolution_finished[0]
			and final_evolution_sound_started[0]
			and final_evolution.sprite_frames.get_frame_count(
				&"evolve_lv2_to_lv3"
			) == 73
			and not final_evolution.sprite_frames.get_animation_loop(
				&"evolve_lv2_to_lv3"
			)
			and not final_evolution.visible
			and level_2_sprite != null
			and level_3_sprite != null
			and destroy_sprite != null
			and not level_2_sprite.visible
			and level_3_sprite.visible
			and level_3_sprite.animation == &"idle_lv3"
			and level_3_sprite.sprite_frames.get_frame_count(
				&"idle_lv3"
			) == 73
			and destroy_sprite.get_parent() == zombie
			and destroy_sprite.sprite_frames.get_frame_count(
				&"destroy_lv3"
			) == 73
			and not destroy_sprite.sprite_frames.get_animation_loop(
				&"destroy_lv3"
			)
			and zombie.is_combat_unlocked()
			and health_bar != null
			and health_bar.visible,
		"Wave 15 did not expose the LV3 visuals and 500-health miniboss bar."
	):
		return

	var attack_targets: Array = game.call("_get_offensive_attack_targets")
	if not _require(
		attack_targets.has(target)
			and target.global_position.is_equal_approx(
				zombie.global_position
			),
		"The stationary Zombie Node target was not added to tower combat."
	):
		return

	var guardian := CYBER_GUARDIAN.instantiate() as CyberGuardianTower
	game.add_child(guardian)
	guardian.set("_placed", true)
	guardian.global_position = zombie.global_position + Vector2(
		guardian.get_attack_range() + 20.0,
		0.0
	)
	if not _require(
		guardian.update_attack(10.0, attack_targets) == null,
		"A finite-range tower targeted the Zombie Node from outside its radius."
	):
		return
	guardian.global_position = zombie.global_position + Vector2(
		guardian.get_attack_range() - 20.0,
		0.0
	)
	if not _require(
		guardian.update_attack(10.0, attack_targets) == target,
		"A finite-range tower could not target the Zombie Node inside its radius."
	):
		return

	var edr_hunter := EDR_HUNTER.instantiate() as EDRHunterTower
	game.add_child(edr_hunter)
	edr_hunter.set("_placed", true)
	edr_hunter.global_position = Vector2(-20000.0, -20000.0)
	if not _require(
		edr_hunter.update_attack(1.0, attack_targets) == target,
		"The EDR Hunter's infinite range did not reach the Zombie Node."
	):
		return
	guardian.queue_free()
	edr_hunter.queue_free()

	if not _require(
		is_equal_approx(
			zombie.get_current_minion_spawn_interval(),
			10.0
		),
		"The final-form Zombie Node does not begin at a 10-second spawn interval."
	):
		return

	var defeated_early := bool(game.call(
		"_damage_virus",
		target,
		334,
		false
	))
	if not _require(
		not defeated_early
			and zombie.current_health == 166
			and zombie.is_below_critical_health()
			and is_equal_approx(
				zombie.get_current_minion_spawn_interval(),
				5.0
			),
		"The one-third health marker did not activate the 5-second spawn interval."
	):
		return

	var destroy_started := [false]
	var destroy_finished := [false]
	zombie.destroy_animation_started.connect(
		func() -> void: destroy_started[0] = true
	)
	zombie.destroy_animation_finished.connect(
		func() -> void: destroy_finished[0] = true
	)
	destroy_sprite.speed_scale = 20.0
	if not _require(
		bool(game.call("_damage_virus", target, 166, false)),
		"The Zombie Node did not enter defeat at zero health."
	):
		return
	for _frame in range(30):
		await process_frame
		if destroy_started[0]:
			break
	if not _require(
		director.is_cutscene_running()
			and zombie.visible
			and destroy_started[0]
			and destroy_sprite.visible,
		"The defeat focus did not play the visible LV3 destroy animation."
	):
		return

	if not await _advance_cutscene_until(
		game,
		cutscene,
		director,
		15
	):
		return
	if not _require(
		zombie.is_defeated()
			and not zombie.visible
			and destroy_finished[0]
			and not destroy_sprite.visible
			and not health_bar.visible
			and not game.call("_get_offensive_attack_targets").has(target),
		"The LV3 destroy animation did not finish before the boss disappeared."
	):
		return

	print(
		"Zombie Node final-form validation passed: Wave 15 focus, "
		+ "500 health, range targeting, adaptive spawning, destroy animation, "
		+ "and defeat dialogue."
	)
	game.queue_free()
	quit(0)


func _advance_cutscene_until(
	game: Node,
	cutscene: TextCutsceneHUD,
	director: CutsceneDemoDirector,
	expected_wave: int
) -> bool:
	var continue_button := cutscene.get_node_or_null(
		"Root/DialoguePanel/Margin/Content/Footer/ContinueButton"
	) as Button
	for _frame in range(1200):
		await process_frame
		if continue_button != null and continue_button.visible:
			continue_button.emit_signal("pressed")
		if not director.is_cutscene_running() \
				and int(game.call("get_current_wave")) == expected_wave:
			return true

	push_error("The Zombie Node cutscene did not finish in time.")
	quit(1)
	return false


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	quit(1)
	return false
