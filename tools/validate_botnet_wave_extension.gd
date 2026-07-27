extends SceneTree

const NORMAL_GAME := preload("res://Scenes/Gameplay/Normal_Game.tscn")
const WaveManagerScript := preload("res://Scripts/Gameplay/wave_manager.gd")
const BOTNET_ANIMATIONS := {
	"LV1IdleAnimation": [&"idle_lv1", 73, true],
	"LV1ActivateAnimation": [&"activate_lv1", 145, false],
	"LV1ToLV2EvolveAnimation": [&"evolve_lv1_to_lv2", 73, false],
	"LV2IdleAnimation": [&"idle_lv2", 73, true],
	"LV2ActivateAnimation": [&"activate_lv2", 145, false],
	"LV2ToLV3EvolveAnimation": [&"evolve_lv2_to_lv3", 73, false],
	"LV3IdleAnimation": [&"idle_lv3", 145, true],
	"LV3ActivateAnimation": [&"activate_lv3", 145, false],
}

var _failed := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := NORMAL_GAME.instantiate()
	root.add_child(game)
	await process_frame

	var text_cutscene := game.get_node_or_null("TextCutsceneHUD") as TextCutsceneHUD
	if text_cutscene != null and text_cutscene.is_cutscene_running():
		text_cutscene.skip_cutscene()
		await process_frame

	var zombie := game.get_node_or_null("ZombieNode") as ZombieNode
	var botnet := game.get_node_or_null("BotnetNode") as BotnetNode
	var worm := game.get_node_or_null("WormBoss") as WormBoss
	var director := game.get_node_or_null("CutsceneDemoDirector") as CutsceneDemoDirector
	var clearance := game.get_node_or_null("Wave20ClearanceHUD") as Wave20ClearanceHUD
	var wave_label := game.get_node_or_null("WavesLabel") as Label
	var wave_manager := WaveManagerScript.new()
	if not _require(
		zombie != null
			and botnet != null
			and worm != null
			and director != null
			and clearance != null
			and wave_label != null,
		"The Botnet wave extension scene nodes are incomplete."
	):
		return

	if not _require(
		wave_manager.get_progressive_boss_name(20)
				== WaveManagerScript.WORM_BOSS
			and wave_manager.get_progressive_boss_level(20) == 1
			and wave_manager.get_progressive_boss_name(21)
				== WaveManagerScript.BOTNET_NODE
			and wave_manager.get_progressive_boss_level(21) == 1
			and wave_manager.get_progressive_boss_level(23) == 2
			and wave_manager.get_progressive_boss_level(25) == 3,
		"The progressive boss database is incorrect for waves 20-25."
	):
		return

	game.call("set_current_wave_for_demo", 20)
	await process_frame
	if not _require(
		int(game.call("get_wave_max_count")) == 20
			and not zombie.active
			and not botnet.active
			and not worm.is_active(),
		"Completed Wave 20 should clear its bosses and retain the /20 clearance cap."
	):
		return

	clearance.appear_duration = 0.01
	clearance.disappear_duration = 0.01
	var choices: Array[bool] = []
	clearance.choice_made.connect(func(selected: bool) -> void: choices.append(selected))
	game.call("_show_wave_20_clearance_cutscene")
	await process_frame
	if not _require(
		clearance.is_cutscene_running()
			and clearance.get_node("Root").visible,
		"The post-wave-20 clearance cutscene did not open."
	):
		return

	var clearance_panel := clearance.get_node(
		"Root/ClearancePanel"
	) as PanelContainer
	var panel_style := clearance_panel.get_theme_stylebox("panel") as StyleBoxFlat
	if not _require(
		panel_style != null
			and panel_style.border_color.is_equal_approx(Color(1, 0.82, 0.08, 1)),
		"The clearance message does not use the authored yellow border."
	):
		return

	var no_button := clearance.get_node(
		"Root/ClearancePanel/Margin/Content/Choices/NoButton"
	) as Button
	no_button.pressed.emit()
	for _frame in range(8):
		await process_frame
	if not _require(
		choices == [false]
			and int(game.call("get_wave_max_count")) == 25
			and wave_label.text == "Wave 20/25",
		"Either clearance response must unlock waves 21 through 25."
	):
		return

	game.call("set_current_wave_for_demo", 21)
	await process_frame
	if not _require(
		not zombie.active and botnet.active and botnet.get_level() == 1,
		"Botnet Node LV1 did not replace the Zombie Node on wave 21."
	):
		return
	if not _require(_has_only_visible_level(botnet, 1), "Botnet LV1 visual selection is incorrect."):
		return

	game.call("set_current_wave_for_demo", 23)
	await process_frame
	if not _require(
		botnet.active and botnet.get_level() == 2 and _has_only_visible_level(botnet, 2),
		"Botnet Node did not evolve to LV2 on wave 23."
	):
		return

	game.call("set_current_wave_for_demo", 25)
	await process_frame
	if not _require(
		botnet.active and botnet.get_level() == 3 and _has_only_visible_level(botnet, 3),
		"Botnet Node did not evolve to LV3 on wave 25."
	):
		return

	for node_name in BOTNET_ANIMATIONS:
		var expected: Array = BOTNET_ANIMATIONS[node_name]
		var sprite := botnet.get_node_or_null(node_name) as AnimatedSprite2D
		var animation_name: StringName = expected[0]
		if not _require(
			sprite != null
				and sprite.sprite_frames != null
				and sprite.sprite_frames.has_animation(animation_name)
				and sprite.sprite_frames.get_frame_count(animation_name)
					== int(expected[1])
				and sprite.sprite_frames.get_animation_loop(animation_name)
					== bool(expected[2]),
			"%s does not have the expected editable animation track." % node_name
		):
			return

	for atlas_name in [
		"BotnetNodeLV1IdleAtlas.png",
		"BotnetNodeLV1ActivateAtlas.png",
		"BotnetNodeLV1ToLV2EvolveAtlas.png",
		"BotnetNodeLV2IdleAtlas.png",
		"BotnetNodeLV2ActivateAtlas.png",
		"BotnetNodeLV2ToLV3EvolveAtlas.png",
		"BotnetNodeLV3IdleAtlas.png",
		"BotnetNodeLV3ActivateAtlas.png",
	]:
		var texture := load(
			"res://assets/Enemies/BotnetNode/Levels/Animations/%s" % atlas_name
		) as Texture2D
		var image := texture.get_image() if texture != null else null
		if not _require(
			image != null
				and image.detect_alpha() != Image.ALPHA_NONE
				and image.get_pixel(0, 0).a < 0.05
				and not _first_frame_has_green_shadow(image),
			"%s does not contain the transparent edge-keyed background."
				% atlas_name
		):
			return

	for evolution_name in [
		"LV1ToLV2EvolveAnimation",
		"LV2ToLV3EvolveAnimation",
	]:
		var evolution := botnet.get_node(evolution_name) as AnimatedSprite2D
		evolution.speed_scale = 120.0

	game.call("set_current_wave_for_demo", 22)
	await process_frame
	game.call("_start_next_wave")
	if not await _wait_for_wave(game, 23):
		return
	if not _require(
		botnet.get_level() == 2 and _has_only_visible_level(botnet, 2),
		"The LV1-to-LV2 animation did not complete before wave 23."
	):
		return

	game.call("set_current_wave_for_demo", 24)
	await process_frame
	game.call("_start_next_wave")
	if not await _wait_for_wave(game, 25):
		return
	if not _require(
		botnet.get_level() == 3 and _has_only_visible_level(botnet, 3),
		"The LV2-to-LV3 animation did not complete before wave 25."
	):
		return

	print(
		"Botnet wave extension validation passed: transparent sibling tracks, "
		+ "/25 unlock, and animated wave 23/25 transitions."
	)
	game.queue_free()
	quit(0)


func _has_only_visible_level(botnet: BotnetNode, expected_level: int) -> bool:
	for level in range(1, 4):
		var sprite := botnet.get_node(
			"LV%dIdleAnimation" % level
		) as AnimatedSprite2D
		if sprite.visible != (level == expected_level):
			return false
	return true


func _first_frame_has_green_shadow(image: Image) -> bool:
	for y in range(mini(315, image.get_height())):
		for x in range(mini(315, image.get_width())):
			var color := image.get_pixel(x, y)
			if color.a <= 0.0:
				continue
			var green_excess := color.g - maxf(color.r, color.b)
			if green_excess > 0.001:
				return true
	return false


func _wait_for_wave(game: Node, expected_wave: int) -> bool:
	for _frame in range(120):
		await process_frame
		if int(game.call("get_current_wave")) == expected_wave:
			return true
	return _require(
		false,
		"Timed out waiting for animated transition into wave %d." % expected_wave
	)


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true

	_failed = true
	push_error(message)
	quit(1)
	return false
