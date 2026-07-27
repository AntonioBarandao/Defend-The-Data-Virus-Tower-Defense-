extends SceneTree

const RANSOMWARE_SCENE := preload("res://Scenes/Enemies/Ransomware.tscn")
const TOWER_UPGRADE_HUD_SCENE := preload("res://Scenes/UI/TowerUpgradeHud.tscn")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await _validate_synchronized_appearance()
	await _validate_ransomware_lifecycle()
	await _validate_ransomware_timeout()
	await _validate_result_announcements()
	await _validate_sidebar_lock()
	await _validate_game_timeout_integration()
	await _validate_wave_ten_scene_trigger(
		"res://Scenes/Gameplay/Normal_Game.tscn",
		"Normal Game",
		false
	)
	await _validate_wave_ten_scene_trigger(
		"res://Scenes/Gameplay/Admin_Sandbox.tscn",
		"Admin Sandbox",
		true
	)
	_validate_integrated_resources()

	if _failures.is_empty():
		print("Ransomware validation passed.")
		quit(0)
		return

	for failure in _failures:
		push_error(failure)
	quit(1)


func _validate_synchronized_appearance() -> void:
	var host := Node2D.new()
	root.add_child(host)
	var target := Node2D.new()
	host.add_child(target)
	var ransomware := RANSOMWARE_SCENE.instantiate() as Ransomware
	host.add_child(ransomware)
	await process_frame

	var body_appear := ransomware.get_node_or_null(
		"AppearAnimation"
	) as AnimatedSprite2D
	var head_appear := ransomware.get_node_or_null(
		"HeadAppearAnimation"
	) as AnimatedSprite2D
	_expect(
		body_appear != null
			and head_appear != null
			and head_appear.sprite_frames != null
			and head_appear.sprite_frames.has_animation(&"head_appear")
			and head_appear.sprite_frames.get_frame_count(&"head_appear") == 73,
		"Ransomware head appearance track is incomplete."
	)

	ransomware.configure(target, 20.0, 2000)
	ransomware.play_appear()
	await process_frame
	_expect(
		body_appear.visible
			and head_appear.visible
			and body_appear.is_playing()
			and head_appear.is_playing()
			and absi(body_appear.frame - head_appear.frame) <= 1,
		"Ransomware body and head appearance animations did not start together."
	)

	ransomware.finish_appear_immediately()
	_expect(
		not body_appear.visible
			and not head_appear.visible
			and ransomware.can_be_targeted(),
		"Ransomware synchronized appearance did not transition to idle cleanly."
	)
	host.queue_free()
	await process_frame


func _validate_ransomware_lifecycle() -> void:
	var host := Node2D.new()
	root.add_child(host)
	var target := Node2D.new()
	target.name = "TestTower"
	target.set_process(true)
	host.add_child(target)
	var ransomware := RANSOMWARE_SCENE.instantiate() as Ransomware
	host.add_child(ransomware)
	await process_frame

	ransomware.configure(target, 20.0, 2000)
	_expect(target.get_meta("ransom_locked", false), "Ransomware did not lock its target.")
	_expect(not target.is_processing(), "Ransomware did not stop target processing.")
	_expect(ransomware.get_formatted_time() == "00:20", "Ransomware timer format is incorrect.")
	ransomware.set("_time_remaining", 61.0)
	_expect(ransomware.get_formatted_time() == "01:01", "Ransomware minute formatting is incorrect.")
	ransomware.set("_time_remaining", 100000.0)
	_expect(ransomware.get_formatted_time() == "99:99", "Ransomware timer did not cap at 99:99.")
	ransomware.set("_time_remaining", 20.0)
	ransomware.finish_appear_immediately()
	_expect(ransomware.can_be_targeted(), "Ransomware did not become targetable after appearing.")
	_expect(not ransomware.take_damage(149), "Ransomware was destroyed before health reached zero.")
	_expect(ransomware.get_current_health() == 1, "Ransomware health did not decrease to one.")
	_expect(ransomware.take_damage(1), "Ransomware did not report destruction at zero health.")
	_expect(not target.get_meta("ransom_locked", false), "Destroyed Ransomware did not unlock its target.")
	host.queue_free()
	await process_frame


func _validate_ransomware_timeout() -> void:
	var host := Node2D.new()
	root.add_child(host)
	var target := Node2D.new()
	target.name = "TimeoutTower"
	host.add_child(target)
	var ransomware := RANSOMWARE_SCENE.instantiate() as Ransomware
	host.add_child(ransomware)
	await process_frame

	var timed_out := [false]
	ransomware.timed_out.connect(func(_source: Ransomware, _target: Node2D) -> void:
		timed_out[0] = true
	)
	ransomware.configure(target, 0.1, 1250)
	ransomware.finish_appear_immediately()
	ransomware.update_interruption(0.2)
	await process_frame
	_expect(bool(timed_out[0]), "Ransomware timeout signal was not emitted.")
	_expect(not target.get_meta("ransom_locked", false), "Timed-out Ransomware did not release target metadata.")
	host.queue_free()
	await process_frame


func _validate_result_announcements() -> void:
	var host := Node2D.new()
	root.add_child(host)

	var paid_target := Node2D.new()
	host.add_child(paid_target)
	var paid_ransomware := RANSOMWARE_SCENE.instantiate() as Ransomware
	host.add_child(paid_ransomware)
	await process_frame
	paid_ransomware.configure(paid_target, 20.0, 500)
	paid_ransomware.finish_appear_immediately()
	paid_ransomware.release_from_payment()
	await process_frame
	await process_frame
	var paid_root := paid_ransomware.get_node(
		"ResultAnnouncementHUD/Root"
	) as Control
	var paid_label := paid_ransomware.get_node(
		"ResultAnnouncementHUD/Root/Center/ResultPanel/Margin/ResultLabel"
	) as Label
	_expect(paid_root.visible, "Paid result announcement did not become visible.")
	_expect(
		paid_label.text == "RANSOMWARE PAID",
		"Paid result announcement has the wrong text."
	)
	_expect(
		paid_label.get_theme_color("font_color").g > paid_label.get_theme_color("font_color").r,
		"Paid result announcement is not green."
	)

	var deleted_target := Node2D.new()
	host.add_child(deleted_target)
	var deleted_ransomware := RANSOMWARE_SCENE.instantiate() as Ransomware
	host.add_child(deleted_ransomware)
	await process_frame
	deleted_ransomware.configure(deleted_target, 0.1, 500)
	deleted_ransomware.finish_appear_immediately()
	deleted_ransomware.update_interruption(0.2)
	await process_frame
	await process_frame
	var deleted_root := deleted_ransomware.get_node(
		"ResultAnnouncementHUD/Root"
	) as Control
	var deleted_label := deleted_ransomware.get_node(
		"ResultAnnouncementHUD/Root/Center/ResultPanel/Margin/ResultLabel"
	) as Label
	_expect(deleted_root.visible, "Deleted result announcement did not become visible.")
	_expect(
		deleted_label.text == "DELETED",
		"Deleted result announcement has the wrong text."
	)
	_expect(
		deleted_label.get_theme_color("font_color").r > deleted_label.get_theme_color("font_color").g,
		"Deleted result announcement is not red."
	)

	host.queue_free()
	await process_frame


func _validate_sidebar_lock() -> void:
	var hud := TOWER_UPGRADE_HUD_SCENE.instantiate() as TowerUpgradeHUD
	root.add_child(hud)
	await process_frame
	hud.show_laser_panel()
	hud.set_ransomware_lock(true, "00:13", 1250, false)

	var ransom_section := hud.get_node(
		"Root/MenuPanel/Margin/Content/RansomwareSection"
	) as Control
	var upgrade_section := hud.get_node(
		"Root/MenuPanel/Margin/Content/VBoxContainer2"
	) as Control
	var sell_button := hud.get_node(
		"Root/MenuPanel/Margin/Content/SellButton"
	) as Button
	var pay_button := hud.get_node(
		"Root/MenuPanel/Margin/Content/RansomwareSection/PayRansomButton"
	) as Button
	_expect(ransom_section.visible, "Ransomware sidebar section did not become visible.")
	_expect(not upgrade_section.visible, "Upgrade controls remained visible while ransom locked.")
	_expect(not sell_button.visible, "Sell remained visible while ransom locked.")
	_expect(pay_button.disabled, "Unaffordable ransom payment was not disabled.")
	hud.show_laser_panel()
	_expect(
		hud.is_ransomware_locked(),
		"Reopening the selected tower cleared the sidebar lock prematurely."
	)

	hud.set_ransomware_lock(false)
	_expect(not ransom_section.visible, "Ransomware sidebar section did not hide after release.")
	_expect(upgrade_section.visible, "Upgrade controls did not return after release.")
	_expect(sell_button.visible, "Sell did not return after release.")
	var upgrade_pressed := [false]
	var sell_pressed := [false]
	hud.laser_upgrade_pressed.connect(func() -> void:
		upgrade_pressed[0] = true
	)
	hud.sell_pressed.connect(func() -> void:
		sell_pressed[0] = true
	)
	hud.call("_on_upgrade_button_pressed")
	hud.call("_on_sell_button_pressed")
	_expect(bool(upgrade_pressed[0]), "Upgrade input remained blocked after Ransomware release.")
	_expect(bool(sell_pressed[0]), "Sell input remained blocked after Ransomware release.")
	hud.set_ransomware_lock(false)
	_expect(
		hud.is_sell_available(),
		"Repeated Ransomware cleanup disabled an already-unlocked Sell button."
	)
	hud.queue_free()
	await process_frame


func _validate_game_timeout_integration() -> void:
	var game_scene := load(
		"res://Scenes/Gameplay/Admin_Sandbox.tscn"
	) as PackedScene
	if game_scene == null:
		_failures.append("Admin Sandbox could not be loaded for timeout integration.")
		return

	var game := game_scene.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	var guardian := game.get_node_or_null(
		"Sprites/Cybersec Guardian"
	) as CyberGuardianTower
	var laser_turret := game.get_node_or_null(
		"Sprites/Laser Turret"
	) as LaserTurret
	var question_hud := game.get_node_or_null(
		"CyberQuestionHUD"
	) as CyberQuestionHUD
	if guardian == null or laser_turret == null or question_hud == null:
		_failures.append(
			"Timeout integration could not resolve its towers or economy HUD."
		)
		game.queue_free()
		await process_frame
		return

	guardian.set("_placed", true)
	game.call("_on_guardian_store_tower_placed", guardian)
	var upgrade_hud := game.get_node_or_null(
		"TowerUpgradeHUD"
	) as TowerUpgradeHUD
	var signal_boost_hud := game.get_node_or_null(
		"SignalBoostHUD"
	) as SignalBoostHUD
	var paid_ransomware := game.call(
		"_begin_ransomware_without_cutscene",
		guardian,
		true
	) as Ransomware
	_expect(paid_ransomware != null, "Game controller did not create payable Guardian Ransomware.")
	if paid_ransomware != null and upgrade_hud != null:
		paid_ransomware.finish_appear_immediately()
		upgrade_hud.show_guardian_panel()
		game.call("_sync_selected_tower_ransomware_panel")
		game.call("_pay_selected_tower_ransomware")
		_expect(
			question_hud.get_cyberbucks() == 0,
			"Guardian ransom payment did not spend 500 Cyber Bucks."
		)
		_expect(
			not guardian.get_meta("ransom_locked", false),
			"Guardian remained locked after ransom payment."
		)
		_expect(
			not upgrade_hud.is_ransomware_locked(),
			"Tower sidebar remained locked after ransom payment."
		)
		if signal_boost_hud != null:
			_expect(
				not signal_boost_hud.is_interaction_locked(),
				"Guardian ability HUD remained locked after ransom payment."
			)
		paid_ransomware.queue_free()
		await process_frame

	question_hud.add_cyberbucks(5000)
	laser_turret.set("_placed", true)
	game.call("_on_laser_store_tower_placed", laser_turret)
	var laser_was_processing := laser_turret.is_processing()
	var laser_ransomware := game.call(
		"_begin_ransomware_without_cutscene",
		laser_turret,
		false
	) as Ransomware
	_expect(
		laser_ransomware != null,
		"Game controller did not create Ransomware for a sellable tower."
	)
	if laser_ransomware != null and upgrade_hud != null:
		laser_ransomware.finish_appear_immediately()
		upgrade_hud.show_laser_panel()
		game.call("_sync_selected_tower_ransomware_panel")
		_expect(
			upgrade_hud.is_ransomware_locked(),
			"Sellable tower sidebar was not locked by Ransomware."
		)
		game.call("_pay_selected_tower_ransomware")
		_expect(
			not laser_turret.get_meta("ransom_locked", false)
				and laser_turret.is_processing() == laser_was_processing,
			"Sellable tower processing did not recover after ransom payment."
		)
		_expect(
			not upgrade_hud.is_ransomware_locked()
				and upgrade_hud.is_sell_available(),
			"Sellable tower controls did not recover after ransom payment."
		)
		var level_before := laser_turret.get_level()
		upgrade_hud.call("_on_upgrade_button_pressed")
		_expect(
			laser_turret.get_level() == level_before + 1,
			"Tower action button remained blocked after ransom payment."
		)
		upgrade_hud.call("_on_sell_button_pressed")
		await process_frame
		_expect(
			not is_instance_valid(laser_turret),
			"Sell remained blocked after ransom payment."
		)

	var remaining_cyberbucks := question_hud.get_cyberbucks()
	if remaining_cyberbucks > 0:
		question_hud.spend_cyberbucks(remaining_cyberbucks)
	question_hud.add_cyberbucks(500)
	var ransomware := game.call(
		"_begin_ransomware_without_cutscene",
		guardian,
		true
	) as Ransomware
	_expect(ransomware != null, "Game controller did not create Guardian Ransomware.")
	if ransomware != null:
		ransomware.finish_appear_immediately()
		ransomware.update_interruption(31.0)
		await process_frame
		await process_frame
		_expect(
			question_hud.get_cyberbucks() == 0,
			"Ransomware timeout did not deduct the 500 Cyber Buck penalty."
		)
		_expect(
			not is_instance_valid(guardian),
			"Ransomware timeout did not delete the encrypted Guardian."
		)
		var replacement := game.get("_guardian_store") as CyberGuardianTower
		_expect(
			is_instance_valid(replacement) and replacement != guardian,
			"Guardian timeout did not restore a free shop replacement."
		)

	game.queue_free()
	await process_frame


func _validate_wave_ten_scene_trigger(
	scene_path: String,
	scene_label: String,
	use_direct_wave_set: bool
) -> void:
	var game_scene := load(scene_path) as PackedScene
	if game_scene == null:
		_failures.append("%s could not be loaded for its wave 10 trigger test." % scene_label)
		return

	var game := game_scene.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	var cutscene_hud := game.get_node_or_null("TextCutsceneHUD")
	if cutscene_hud != null \
			and cutscene_hud.has_method("is_cutscene_running") \
			and bool(cutscene_hud.call("is_cutscene_running")):
		cutscene_hud.call("skip_cutscene")
		await process_frame

	var guardian := game.get_node_or_null(
		"Sprites/Cybersec Guardian"
	) as CyberGuardianTower
	if guardian == null:
		_failures.append("%s could not resolve its Guardian for wave 10." % scene_label)
		game.queue_free()
		await process_frame
		return

	guardian.set("_placed", true)
	game.call("_on_guardian_store_tower_placed", guardian)
	if use_direct_wave_set:
		game.call("set_current_wave_for_demo", 10)
	else:
		game.call("set_current_wave_for_demo", 9)
		game.call("_start_next_wave")
	await process_frame
	await process_frame

	var active_ransomware: Array = game.get("_active_ransomware")
	_expect(
		active_ransomware.size() == 1,
		"%s did not create Ransomware at wave 10." % scene_label
	)
	_expect(
		guardian.get_meta("ransom_locked", false),
		"%s did not ransom-lock the Guardian at wave 10." % scene_label
	)
	_expect(
		bool(game.get("_wave_ten_ransomware_triggered")),
		"%s did not mark the wave 10 Ransomware event as triggered." % scene_label
	)

	if cutscene_hud != null \
			and cutscene_hud.has_method("is_cutscene_running") \
			and bool(cutscene_hud.call("is_cutscene_running")):
		cutscene_hud.call("skip_cutscene")
		await process_frame
		await process_frame

	_expect(
		int(game.call("get_current_wave")) == 10,
		"%s did not remain on or advance into wave 10." % scene_label
	)
	game.queue_free()
	await process_frame


func _validate_integrated_resources() -> void:
	var normal_game := load("res://Scenes/Gameplay/Normal_Game.tscn") as PackedScene
	var admin_sandbox := load("res://Scenes/Gameplay/Admin_Sandbox.tscn") as PackedScene
	var text_cutscene := load("res://Scenes/UI/TextCutsceneHUD.tscn") as PackedScene
	_expect(normal_game != null, "Normal Game no longer loads after Ransomware integration.")
	_expect(admin_sandbox != null, "Admin Sandbox no longer loads after Ransomware integration.")
	_expect(text_cutscene != null, "Text Cutscene HUD no longer loads after Ransomware integration.")
	if text_cutscene != null:
		var hud := text_cutscene.instantiate()
		_expect(
			hud.has_method("start_wave10_ransomware_cutscene"),
			"Wave 10 Ransomware cutscene entry point is missing."
		)
		hud.free()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
