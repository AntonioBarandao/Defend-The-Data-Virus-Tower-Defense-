extends SceneTree

const NORMAL_GAME := preload("res://Scenes/Gameplay/Normal_Game.tscn")
const ADMIN_SANDBOX := preload("res://Scenes/Gameplay/Admin_Sandbox.tscn")
const ANTI_SCENE := preload("res://Scenes/Enemies/AntiCyberguardian.tscn")
const BOTNET_SCENE := preload("res://Scenes/Enemies/BotnetNode.tscn")

const ANTI_ANIMATIONS := {
	"AbilityActivateAnimation": [&"ability_activate", false],
	"AbilityIdleAnimation": [&"ability_idle", true],
	"AppearAnimation": [&"appear", false],
	"CloakDisappearAnimation": [&"cloak_disappear", false],
	"CollapseAnimation": [&"collapse", false],
	"DisappearDefeatAnimation": [&"disappear_defeat", false],
	"PantingAnimation": [&"panting", true],
	"StrugglePantingAnimation": [&"struggle_panting", true],
}

const BOTNET_REVEALS := {
	"LV3AppearHollowAnimation": &"appear_hollow_lv3",
	"LV3AppearAntiAnimation": &"appear_anti_lv3",
}
const BOTNET_DESTROY_NODE := "LV3DestroyAnimation"
const BOTNET_DESTROY_TRACK := &"destroy_lv3"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if not await _validate_anti_scene():
		return
	if not await _validate_botnet_viewport_preview():
		return
	if not await _validate_game_scene(NORMAL_GAME, "Normal_Game", true):
		return
	if not await _validate_game_scene(
		ADMIN_SANDBOX,
		"Admin_Sandbox",
		false
	):
		return
	print(
		"Anti-Cyberguardian final boss validation passed: editable tracks, "
		+ "Botnet destroy/HUD, 500-health gate, 2000-health Worm, partial "
		+ "Anti-Cyberguardian defeat act, and shared Normal/Admin behavior."
	)
	quit(0)


func _validate_anti_scene() -> bool:
	var anti := ANTI_SCENE.instantiate() as AntiCyberguardian
	root.add_child(anti)
	await process_frame
	if not _require(
		anti != null and anti.get_child_count() == 8,
		"Anti-Cyberguardian does not have eight editable sibling tracks."
	):
		return false
	for node_name in ANTI_ANIMATIONS:
		var expected: Array = ANTI_ANIMATIONS[node_name]
		var sprite := anti.get_node_or_null(node_name) as AnimatedSprite2D
		var animation_name: StringName = expected[0]
		if not _require(
			sprite != null
				and sprite.sprite_frames != null
				and sprite.sprite_frames.has_animation(animation_name)
				and sprite.sprite_frames.get_frame_count(animation_name) == 73
				and sprite.sprite_frames.get_animation_loop(animation_name)
					== bool(expected[1]),
			"%s is missing its 73-frame editable track." % node_name
		):
			return false
	anti.finish_final_boss_intro_immediately()
	if not _require(
		anti.is_alive()
			and anti.is_ability_active()
			and anti.is_mounted()
			and is_equal_approx(anti.rotation_degrees, -90.0)
			and anti.get_node("AbilityIdleAnimation").visible,
		"Mounted Anti-Cyberguardian does not face right and loop Ability Idle."
	):
		return false
	anti.queue_free()
	await process_frame
	return true


func _validate_botnet_viewport_preview() -> bool:
	var botnet := BOTNET_SCENE.instantiate() as BotnetNode
	var preview := botnet.get_node_or_null(
		"Anti-Guardian-Botnet-1/AntiGuardianViewportPreview"
	) as AntiCyberguardian
	var preview_appear := (
		preview.get_node_or_null("AppearAnimation") as AnimatedSprite2D
		if preview != null
		else null
	)
	if not _require(
		preview != null
			and preview.editor_preview_only
			and preview.visible
			and preview.z_index > botnet.z_index
			and preview_appear != null
			and preview_appear.visible
			and preview_appear.frame
				== preview_appear.sprite_frames.get_frame_count(
					AntiCyberguardian.APPEAR
				) - 1,
		"Botnet scene does not expose the posed Anti-Guardian viewport preview."
	):
		return false

	root.add_child(botnet)
	await process_frame
	await process_frame
	if not _require(
		not is_instance_valid(preview)
			and botnet.get_node_or_null(
				"Anti-Guardian-Botnet-1/AntiGuardianViewportPreview"
			) == null,
		"Botnet Anti-Guardian viewport preview leaked into runtime."
	):
		return false
	botnet.queue_free()
	await process_frame
	return true


func _validate_game_scene(
	scene: PackedScene,
	scene_label: String,
	run_full_intro: bool
) -> bool:
	var game := scene.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame

	var cutscene := game.get_node_or_null(
		"TextCutsceneHUD"
	) as TextCutsceneHUD
	if cutscene != null and cutscene.is_cutscene_running():
		cutscene.skip_cutscene()
		await process_frame

	var botnet := game.get_node_or_null("BotnetNode") as BotnetNode
	var worm := game.get_node_or_null("WormBoss") as WormBoss
	var director := game.get_node_or_null(
		"CutsceneDemoDirector"
	) as CutsceneDemoDirector
	var anti := (
		worm.get_anti_cyberguardian()
		if worm != null
		else null
	)
	if not _require(
		botnet != null
			and worm != null
			and director != null
			and cutscene != null
			and anti != null
			and anti.z_index > botnet.z_index
			and not anti.z_as_relative,
		"%s is missing final-boss scene dependencies." % scene_label
	):
		return false

	if not _require(
		cutscene.wave25_warning_lines == PackedStringArray([
			"Oh no, something is happening!-"
		]),
		"%s does not use the requested Cyber Guardian warning."
			% scene_label
	):
		return false

	for node_name in BOTNET_REVEALS:
		var sprite := botnet.get_node_or_null(node_name) as AnimatedSprite2D
		var animation_name: StringName = BOTNET_REVEALS[node_name]
		if not _require(
			sprite != null
				and sprite.sprite_frames != null
				and sprite.sprite_frames.has_animation(animation_name)
				and sprite.sprite_frames.get_frame_count(animation_name) == 73
				and not sprite.sprite_frames.get_animation_loop(animation_name),
			"%s is missing Botnet final reveal track %s."
				% [scene_label, node_name]
		):
			return false
	var botnet_destroy := botnet.get_node_or_null(
		BOTNET_DESTROY_NODE
	) as AnimatedSprite2D
	var botnet_health_hud := botnet.get_node_or_null(
		"BotnetHealthHUD"
	) as BotnetNodeProgressBar
	var worm_health_hud := worm.get_node_or_null(
		"BossHealthHUD"
	) as WormBossProgressBar
	var reveal_marker_one := botnet.get_node_or_null(
		"Anti-Guardian-Botnet-1"
	) as Marker2D
	var reveal_marker_two := botnet.get_node_or_null(
		"Anti-Guardian-Botnet-2"
	) as Marker2D
	if not _require(
		botnet_destroy != null
			and botnet_destroy.sprite_frames != null
			and botnet_destroy.sprite_frames.has_animation(
				BOTNET_DESTROY_TRACK
			)
			and botnet_destroy.sprite_frames.get_frame_count(
				BOTNET_DESTROY_TRACK
			) == 73
			and not botnet_destroy.sprite_frames.get_animation_loop(
				BOTNET_DESTROY_TRACK
			)
			and botnet_health_hud != null
			and worm_health_hud != null
			and reveal_marker_one != null
			and reveal_marker_two != null
			and not reveal_marker_one.position.is_equal_approx(
				reveal_marker_two.position
			)
			and botnet
				.get_anti_guardian_reveal_marker_global_position(0)
				.is_equal_approx(reveal_marker_one.global_position)
			and botnet
				.get_anti_guardian_reveal_marker_global_position(1)
				.is_equal_approx(reveal_marker_two.global_position),
		"%s is missing Botnet final reveal markers, destroy track, or HUDs."
			% scene_label
	):
		return false

	var mount := worm.get_node_or_null(
		"HeadAnimation/AntiCyberGuardianSpot"
	) as Marker2D
	if not _require(
		mount != null
			and anti.get_parent() == mount
			and mount.get_parent() == worm.get_node("HeadAnimation"),
		"%s does not mount the Anti-Cyberguardian under the Worm head."
			% scene_label
	):
		return false

	game.call("set_current_wave_for_demo", 24)
	await process_frame
	botnet_destroy.speed_scale = 120.0
	for node_name in ANTI_ANIMATIONS:
		(anti.get_node(node_name) as AnimatedSprite2D).speed_scale = 120.0
	var final_boss_phases: Array[StringName] = []
	var final_reveal_events: Array[StringName] = []
	var guardian_reveal_positions: Array[Vector2] = []
	var guardian_reveal_detached := [false]
	var held_phase_health_hidden := [false]
	if run_full_intro:
		cutscene.wave25_botnet_pan_duration = 0.01
		cutscene.wave25_worm_pan_duration = 0.01
		cutscene.wave25_reveal_zoom_duration = 0.05
		if not _require(
			is_equal_approx(
				cutscene.wave25_anti_departure_hold_duration,
				1.0
			),
			"%s does not use the requested one-second Anti-Guardian hold."
				% scene_label
		):
			return false
		cutscene.wave25_anti_departure_hold_duration = 0.01
		cutscene.camera_return_duration = 0.01
		cutscene.entry_duration = 0.01
		cutscene.exit_duration = 0.01
		cutscene.characters_per_second = 10000.0
		for node_name in [
			"LV2ToLV3EvolveAnimation",
			"LV3AppearHollowAnimation",
			"LV3AppearAntiAnimation",
		]:
			(botnet.get_node(node_name) as AnimatedSprite2D).speed_scale = 120.0
		cutscene.phase_started.connect(
			func(act_number: int, phase_name: StringName) -> void:
				if act_number == TextCutsceneHUD.ACT_WAVE_TWENTY_FIVE:
					final_boss_phases.append(phase_name)
		)
		cutscene.phase_finished.connect(
			func(act_number: int, phase_name: StringName) -> void:
				if act_number != TextCutsceneHUD.ACT_WAVE_TWENTY_FIVE \
						or phase_name != TextCutsceneHUD.PHASE_THREE:
					return
				var anti_reveal_sprite := botnet.get_node(
					"LV3AppearAntiAnimation"
				) as AnimatedSprite2D
				held_phase_health_hidden[0] = (
					anti_reveal_sprite.visible
					and anti_reveal_sprite.frame
						== anti_reveal_sprite.sprite_frames.get_frame_count(
							&"appear_anti_lv3"
						) - 1
					and not botnet_health_hud.visible
					and not worm_health_hud.visible
					and botnet.is_final_boss_health_suppressed()
					and worm.is_health_hud_suppressed()
				)
		)
		botnet.final_reveal_clip_held.connect(
			func(clip_index: int) -> void:
				final_reveal_events.append(
					&"hollow_held"
					if clip_index == 0
					else &"anti_held"
				)
		)
		anti.botnet_reveal_appearance_held.connect(
			func(world_position: Vector2) -> void:
				final_reveal_events.append(&"guardian_appear_held")
				guardian_reveal_positions.append(world_position)
				guardian_reveal_detached[0] = anti.get_parent() == game
		)
		anti.botnet_reveal_move_finished.connect(
			func(world_position: Vector2) -> void:
				final_reveal_events.append(&"guardian_move_finished")
				guardian_reveal_positions.append(world_position)
		)
		anti.botnet_reveal_departure_started.connect(
			func(world_position: Vector2) -> void:
				final_reveal_events.append(&"guardian_departure")
				guardian_reveal_positions.append(world_position)
		)
	game.call("_start_next_wave")
	var continue_button := cutscene.get_node_or_null(
		"Root/DialoguePanel/Margin/Content/Footer/ContinueButton"
	) as Button
	for _frame in range(600):
		await process_frame
		if cutscene.is_cutscene_running() \
				and cutscene.current_act \
					== TextCutsceneHUD.ACT_WAVE_TWENTY_FIVE:
			if run_full_intro:
				if cutscene.current_phase in [
					TextCutsceneHUD.PHASE_TWO,
					TextCutsceneHUD.PHASE_FOUR,
				] and (
					bool(cutscene.get("_typing"))
					or (
						continue_button != null
						and continue_button.visible
					)
				):
					cutscene.call("_advance_dialogue")
			else:
				cutscene.skip_cutscene()
		if int(game.call("get_current_wave")) == 25:
			break

	if run_full_intro and not _require(
		final_boss_phases == [
			TextCutsceneHUD.PHASE_ONE,
			TextCutsceneHUD.PHASE_TWO,
			TextCutsceneHUD.PHASE_THREE,
			TextCutsceneHUD.PHASE_FOUR,
			TextCutsceneHUD.PHASE_END,
		],
		"%s did not complete the full five-phase wave-25 intro."
			% scene_label
	):
		return false

	if run_full_intro:
		var hollow_index := final_reveal_events.find(&"hollow_held")
		var guardian_appear_index := final_reveal_events.find(
			&"guardian_appear_held"
		)
		var anti_index := final_reveal_events.find(&"anti_held")
		var guardian_move_index := final_reveal_events.find(
			&"guardian_move_finished"
		)
		var guardian_departure_index := final_reveal_events.find(
			&"guardian_departure"
		)
		if not _require(
			hollow_index == 0
				and guardian_appear_index == 1
				and anti_index > guardian_appear_index
				and guardian_move_index > guardian_appear_index
				and guardian_departure_index > anti_index
				and guardian_departure_index > guardian_move_index
				and guardian_reveal_positions.size() == 3
				and guardian_reveal_positions[0].is_equal_approx(
					reveal_marker_one.global_position
				)
				and guardian_reveal_positions[1].is_equal_approx(
					reveal_marker_two.global_position
				)
				and guardian_reveal_positions[2].is_equal_approx(
					reveal_marker_two.global_position
				)
				and bool(guardian_reveal_detached[0])
				and bool(held_phase_health_hidden[0]),
			"%s did not hold and align the authored Botnet reveal sequence."
				% scene_label
		):
			return false

	if not _require(
		int(game.call("get_current_wave")) == 25
			and botnet.get_level() == 3
			and botnet.get_maximum_health() == 500
			and botnet.get_current_health() == 500
			and botnet.can_be_targeted()
			and worm.max_health == 2000
			and worm.current_health == 2000
			and worm.is_active()
			and worm.is_wave_active()
			and worm.is_externally_invulnerable()
			and anti.is_ability_active()
			and botnet_health_hud.visible
			and worm_health_hud.visible
			and not botnet.is_final_boss_health_suppressed()
			and not worm.is_health_hud_suppressed()
			and anti.get_parent() == mount
			and (
				botnet_health_hud.get_node(
					"Root/BossPanel/Margin/Content/Header/HealthLabel"
				) as Label
			).text == "500 / 500",
		"%s did not enter the configured wave-25 final boss state."
			% scene_label
	):
		return false

	var botnet_targets: Array = game.call(
		"_get_final_boss_priority_targets"
	)
	var blocked_worm_targets: Array = game.call(
		"_get_worm_boss_attack_targets"
	)
	if not _require(
		botnet_targets.size() == 1 and blocked_worm_targets.is_empty(),
		"%s does not prioritize Botnet while suppressing Worm targets."
			% scene_label
	):
		return false

	game.call("_damage_botnet_node", 500)
	await process_frame
	if not _require(
		botnet.is_defeated()
			and botnet.is_destroying()
			and botnet_destroy.visible
			and worm.is_externally_invulnerable(),
		"%s did not hold the Worm link during Botnet destruction."
			% scene_label
	):
		return false
	for _frame in range(90):
		await process_frame
		if not botnet.is_destroying():
			break
	if not _require(
		not botnet.is_destroying()
			and not worm.is_externally_invulnerable()
			and (
				game.call("_get_final_boss_priority_targets") as Array
			).is_empty()
			and not (
				game.call("_get_worm_boss_attack_targets") as Array
			).is_empty(),
		"%s did not release the Worm when the Botnet was destroyed."
			% scene_label
	):
		return false

	for destroy_path in [
		"Head_Destroy",
		"Body_First_Destroy",
		"Body_Second_Destroy",
		"Body_Third_Destroy",
		"Body_Fourth_Destroy",
		"Body_Fifth_Destroy",
		"Tail_Destroy",
	]:
		(
			worm.get_node(destroy_path) as AnimatedSprite2D
		).speed_scale = 120.0
	worm.destroy_fade_duration = 0.01
	cutscene.wave25_defeat_pan_duration = 0.01
	cutscene.camera_return_duration = 0.01
	var defeat_phases: Array[StringName] = []
	var anti_defeat_tracks: Array[StringName] = []
	cutscene.phase_started.connect(
		func(act_number: int, phase_name: StringName) -> void:
			if act_number \
					== TextCutsceneHUD.ACT_WAVE_TWENTY_FIVE_DEFEAT:
				defeat_phases.append(phase_name)
	)
	anti.partial_defeat_animation_started.connect(
		func(animation_name: StringName) -> void:
			anti_defeat_tracks.append(animation_name)
	)

	var offsets: Array = worm.get("_part_offsets")
	worm.call(
		"_process",
		(float(offsets[1]) + 1.0) / worm.path_speed
	)
	var worm_targets: Array = worm.get_attack_targets()
	if not _require(
		worm_targets.size() >= 2,
		"%s did not expose a Worm body target for defeat testing."
			% scene_label
	):
		return false
	game.call("_damage_virus", worm_targets[1], 2000, false)
	await process_frame
	if not _require(
		anti.get_parent() == game and not anti.is_mounted(),
		"%s did not detach and cloak the Anti-Cyberguardian at zero health."
			% scene_label
	):
		return false

	for _frame in range(300):
		await process_frame
		if cutscene.is_cutscene_running() \
				and cutscene.current_act \
					== TextCutsceneHUD.ACT_WAVE_TWENTY_FIVE_DEFEAT \
				and not run_full_intro:
			cutscene.skip_cutscene()
		if not bool(game.get("_worm_defeat_sequence_running")) \
				and worm.is_defeated():
			break

	if run_full_intro and not _require(
		defeat_phases == [
			TextCutsceneHUD.PHASE_ONE,
			TextCutsceneHUD.PHASE_END,
		]
			and anti_defeat_tracks == [
				AntiCyberguardian.APPEAR,
				AntiCyberguardian.COLLAPSE,
				AntiCyberguardian.STRUGGLE_PANTING,
				AntiCyberguardian.PANTING,
				AntiCyberguardian.DISAPPEAR_DEFEAT,
			],
		"%s did not complete the requested partial defeat sequence."
			% scene_label
	):
		return false
	if not _require(
		worm.is_defeated()
			and not bool(game.get("_worm_defeat_sequence_running"))
			and not director.is_cutscene_running()
			and not anti.is_alive()
			and not anti.visible
			and (
				not run_full_intro
				or anti.global_position.is_equal_approx(
					botnet.global_position
				)
			),
		"%s did not cleanly finish the partial final-boss defeat act."
			% scene_label
	):
		return false

	game.queue_free()
	await process_frame
	return true


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	quit(1)
	return false
